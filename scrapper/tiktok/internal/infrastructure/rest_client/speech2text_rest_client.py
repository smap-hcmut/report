"""
HTTP Client for Speech-to-Text REST API
Provides interface to call the STT service for audio transcription
"""

import httpx
from typing import Optional
from application.interfaces import ISpeech2TextClient, STTResult
from domain.entities.content import Content
from utils.logger import logger


def generate_request_id(content: Content) -> str:
    """
    Generate deterministic request_id from content external_id
    
    This function creates a unique, deterministic identifier for STT transcription jobs
    based on the content's external_id. The same content will always generate the same
    request_id, enabling idempotent job submission.
    
    Args:
        content: Content entity with external_id field
        
    Returns:
        String request_id derived from content.external_id
        
    Example:
        >>> content = Content(external_id="7552532436060523784", ...)
        >>> generate_request_id(content)
        '7552532436060523784'
    """
    return str(content.external_id)


class Speech2TextRestClient(ISpeech2TextClient):
    """Client for interacting with Speech-to-Text REST API service"""

    def __init__(
        self,
        base_url: str,
        api_key: str,
        timeout: int = 300,
        max_retries: int = 60,
        wait_interval: int = 3,
    ):
        """
        Initialize Speech-to-Text REST API client with async HTTP client

        Args:
            base_url: Base URL of the STT API (e.g., http://172.16.21.230)
            api_key: API key for authentication
            timeout: HTTP request timeout in seconds for individual requests (default: 300s)
                    Note: This is NOT the polling timeout. Total polling timeout is
                    calculated as max_retries * wait_interval
            max_retries: Maximum number of polling attempts (default: 60)
            wait_interval: Seconds to wait between polling attempts (default: 3)
        """
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.timeout = timeout
        self.max_retries = max_retries
        self.wait_interval = wait_interval
        
        # Initialize httpx.AsyncClient with timeout configuration
        # This client will be reused for all HTTP requests
        self.client = httpx.AsyncClient(timeout=self.timeout)

    async def aclose(self):
        """
        Close the HTTP client and cleanup resources
        
        This method should be called when the client is no longer needed
        to properly cleanup the underlying HTTP connection pool.
        """
        await self.client.aclose()

    async def transcribe(
        self, 
        audio_url: str, 
        language: str = "vi",
        request_id: Optional[str] = None
    ) -> STTResult:
        """
        Transcribe audio from URL to text using async polling pattern

        This method submits a transcription job to the STT service and polls
        for completion. It maintains backward compatibility with the synchronous
        implementation while using the new async API internally.

        Args:
            audio_url: URL of the audio file (minio:// or http(s)://)
            language: Language code (default: "vi")
            request_id: Optional unique identifier for the job. If not provided,
                       a deterministic ID will be generated from the audio_url

        Returns:
            STTResult with transcription and status info
        """
        import hashlib
        
        # Generate request_id if not provided
        # Use a hash of the audio_url to ensure deterministic, unique IDs
        if request_id is None:
            # Create a deterministic request_id from audio_url
            url_hash = hashlib.md5(audio_url.encode()).hexdigest()[:16]
            request_id = f"stt_{url_hash}"
        
        logger.info(
            f"[STT] Starting transcription: request_id={request_id}, "
            f"audio_url={audio_url[:80]}..., language={language}"
        )
        
        # Step 1: Submit the transcription job
        try:
            submit_response = await self._submit_job(
                request_id=request_id,
                media_url=audio_url,
                language=language
            )
            
            logger.info(
                f"[STT] Job submitted successfully: request_id={request_id}"
            )
            logger.debug(f"[STT] Submit response: {submit_response}")
            
        except httpx.HTTPStatusError as e:
            # Handle submission errors
            logger.error(
                f"[STT] Job submission failed: request_id={request_id}, "
                f"status_code={e.response.status_code}, error={str(e)}"
            )
            return self._map_error_to_stt_result(e, request_id, "submit")
            
        except httpx.TimeoutException as e:
            # Handle submission timeout
            logger.error(
                f"[STT] Job submission timeout: request_id={request_id}, error={str(e)}"
            )
            return STTResult(
                success=False,
                transcription="",
                status="TIMEOUT",
                error_message=f"Job submission timeout: {str(e)}",
                error_code=408,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )
            
        except Exception as e:
            # Handle unexpected submission errors
            logger.error(
                f"[STT] Unexpected error during job submission: request_id={request_id}, "
                f"error={str(e)}",
                exc_info=True
            )
            return STTResult(
                success=False,
                transcription="",
                status="EXCEPTION",
                error_message=f"Unexpected error during submission: {str(e)}",
                error_code=-1,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )
        
        # Step 2: Poll for job completion
        try:
            result = await self._poll_status(request_id)
            
            # Log final result
            if result.success:
                logger.info(
                    f"[STT] Transcription completed successfully: request_id={request_id}, "
                    f"transcription_length={len(result.transcription or '')}, "
                    f"duration={result.duration}s, "
                    f"processing_time={result.processing_time}s, "
                    f"confidence={result.confidence}"
                )
            elif result.status == "TIMEOUT":
                total_wait = self.max_retries * self.wait_interval
                logger.warning(
                    f"[STT] Transcription polling timeout: request_id={request_id}, "
                    f"max_retries={self.max_retries}, "
                    f"total_wait_time={total_wait}s, "
                    f"status={result.status}"
                )
            else:
                logger.error(
                    f"[STT] Transcription failed: request_id={request_id}, "
                    f"status={result.status}, "
                    f"error_code={result.error_code}, "
                    f"error_message={result.error_message}"
                )
            
            return result
            
        except Exception as e:
            # Handle unexpected polling errors (should be rare as _poll_status handles most errors)
            logger.error(
                f"[STT] Unexpected error during polling: request_id={request_id}, "
                f"error={str(e)}",
                exc_info=True
            )
            return STTResult(
                success=False,
                transcription="",
                status="EXCEPTION",
                error_message=f"Unexpected error during polling: {str(e)}",
                error_code=-1,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )

    async def _submit_job(
        self, request_id: str, media_url: str, language: str
    ) -> dict:
        """
        Submit a transcription job to the STT service

        Args:
            request_id: Unique identifier for the transcription job
            media_url: URL of the audio file (presigned MinIO URL)
            language: Language code (e.g., "vi", "en")

        Returns:
            API response dictionary with job status

        Raises:
            httpx.HTTPError: If the HTTP request fails
        """
        endpoint = f"{self.base_url}/api/transcribe"
        payload = {
            "request_id": request_id,
            "media_url": media_url,
            "language": language,
        }
        headers = {"X-API-Key": self.api_key}

        logger.info(
            f"[STT] Submitting job: request_id={request_id}, media_url={media_url[:80]}..."
        )
        logger.debug(f"[STT] Submit payload: {payload}")

        response = await self.client.post(endpoint, json=payload, headers=headers)
        response.raise_for_status()  # Raise exception for 4xx/5xx status codes

        data = response.json()
        logger.info(
            f"[STT] Job submitted successfully: request_id={request_id}, "
            f"status_code={response.status_code}"
        )
        logger.debug(f"[STT] Submit response: {data}")

        return data

    async def _get_job_status(self, request_id: str) -> dict:
        """
        Get current status of a transcription job

        Args:
            request_id: Unique identifier for the transcription job

        Returns:
            API response dictionary with current job status

        Raises:
            httpx.HTTPStatusError: If the HTTP request returns 4xx/5xx status
                - 404: Job not found
                - 401: Unauthorized (invalid API key)
        """
        endpoint = f"{self.base_url}/api/transcribe/{request_id}"
        headers = {"X-API-Key": self.api_key}

        logger.debug(f"[STT] Getting job status: request_id={request_id}")

        response = await self.client.get(endpoint, headers=headers)
        
        # Handle 404 - Job not found
        if response.status_code == 404:
            logger.warning(f"[STT] Job not found: request_id={request_id}")
            response.raise_for_status()
        
        # Handle 401 - Unauthorized
        if response.status_code == 401:
            logger.error(f"[STT] Unauthorized: Invalid API key for request_id={request_id}")
            response.raise_for_status()
        
        # Raise for any other error status codes
        response.raise_for_status()

        data = response.json()
        logger.debug(f"[STT] Job status response: {data}")

        return data

    def _map_error_to_stt_result(
        self,
        error: Exception,
        request_id: str,
        context: str = "polling"
    ) -> STTResult:
        """
        Map exceptions to STTResult objects with appropriate status and error information
        
        This helper method centralizes error handling logic for network failures during
        the async polling process. It handles:
        - httpx.TimeoutException: Network timeouts (transient, should retry)
        - httpx.HTTPStatusError: HTTP error responses (401, 404, 5xx)
        - Generic exceptions: Unexpected errors
        
        Args:
            error: The exception that occurred
            request_id: Unique identifier for the transcription job
            context: Context where the error occurred (e.g., "polling", "submit")
        
        Returns:
            STTResult with appropriate status and error information
        """
        # Handle network timeout exceptions
        if isinstance(error, httpx.TimeoutException):
            logger.warning(
                f"[STT] Request timeout during {context} for request_id={request_id}: {str(error)}"
            )
            # Note: This is a transient error - caller should continue polling
            # We don't return a final result here, but this method can be used
            # to log and handle the error appropriately
            return STTResult(
                success=False,
                transcription="",
                status="TIMEOUT",
                error_message=f"Request timeout during {context}",
                error_code=408,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )
        
        # Handle HTTP status errors
        if isinstance(error, httpx.HTTPStatusError):
            status_code = error.response.status_code
            
            # 401 Unauthorized - Invalid API key (fail immediately)
            if status_code == 401:
                logger.error(
                    f"[STT] Unauthorized (401) during {context} for request_id={request_id}: Invalid API key"
                )
                return STTResult(
                    success=False,
                    transcription="",
                    status="UNAUTHORIZED",
                    error_message="Invalid API key",
                    error_code=401,
                    duration=0.0,
                    confidence=0.0,
                    processing_time=0.0,
                )
            
            # 404 Not Found - Job not found or expired (fail immediately)
            if status_code == 404:
                logger.error(
                    f"[STT] Job not found (404) during {context} for request_id={request_id}"
                )
                return STTResult(
                    success=False,
                    transcription="",
                    status="NOT_FOUND",
                    error_message=f"Job {request_id} not found or expired",
                    error_code=404,
                    duration=0.0,
                    confidence=0.0,
                    processing_time=0.0,
                )
            
            # 5xx Server errors - Transient errors (should continue polling)
            if 500 <= status_code < 600:
                logger.warning(
                    f"[STT] Server error ({status_code}) during {context} for request_id={request_id}, "
                    f"this is a transient error"
                )
                # Note: Caller should continue polling for 5xx errors
                return STTResult(
                    success=False,
                    transcription="",
                    status="SERVER_ERROR",
                    error_message=f"Server error ({status_code}): {str(error)}",
                    error_code=status_code,
                    duration=0.0,
                    confidence=0.0,
                    processing_time=0.0,
                )
            
            # Other HTTP errors
            logger.warning(
                f"[STT] HTTP error ({status_code}) during {context} for request_id={request_id}: {str(error)}"
            )
            return STTResult(
                success=False,
                transcription="",
                status="HTTP_ERROR",
                error_message=f"HTTP error ({status_code}): {str(error)}",
                error_code=status_code,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )
        
        # Handle unexpected exceptions
        logger.error(
            f"[STT] Unexpected exception during {context} for request_id={request_id}: {str(error)}",
            exc_info=True
        )
        return STTResult(
            success=False,
            transcription="",
            status="EXCEPTION",
            error_message=f"Unexpected error during {context}: {str(error)}",
            error_code=-1,
            duration=0.0,
            confidence=0.0,
            processing_time=0.0,
        )

    def _parse_completed_response(self, response: dict, request_id: str) -> STTResult:
        """
        Parse COMPLETED response and extract transcription data
        
        Args:
            response: API response dictionary
            request_id: Unique identifier for the transcription job
            
        Returns:
            STTResult with success=True and transcription data
        """
        data = response.get("data", {})
        transcription = data.get("transcription", "")
        duration = data.get("duration", 0.0)
        confidence = data.get("confidence", 0.0)
        processing_time = data.get("processing_time", 0.0)
        
        logger.info(
            f"[STT] Job completed: request_id={request_id}, "
            f"transcription_length={len(transcription)}, "
            f"duration={duration}s, processing_time={processing_time}s"
        )
        
        return STTResult(
            success=True,
            transcription=transcription,
            status="COMPLETED",
            error_message="",
            error_code=0,
            duration=duration,
            confidence=confidence,
            processing_time=processing_time,
        )
    
    def _parse_failed_response(self, response: dict, request_id: str) -> STTResult:
        """
        Parse FAILED response and extract error information
        
        Args:
            response: API response dictionary
            request_id: Unique identifier for the transcription job
            
        Returns:
            STTResult with success=False and error information
        """
        data = response.get("data", {})
        error_message = data.get("error", "Transcription failed")
        error_code = response.get("error_code", -1)
        
        logger.error(
            f"[STT] Job failed: request_id={request_id}, "
            f"error={error_message}, error_code={error_code}"
        )
        
        return STTResult(
            success=False,
            transcription="",
            status="FAILED",
            error_message=error_message,
            error_code=error_code,
            duration=0.0,
            confidence=0.0,
            processing_time=0.0,
        )
    
    def _parse_processing_response(self, response: dict, request_id: str) -> None:
        """
        Handle PROCESSING response (job still in progress)
        
        This method logs the processing status. The caller should continue polling.
        
        Args:
            response: API response dictionary
            request_id: Unique identifier for the transcription job
        """
        logger.debug(
            f"[STT] Job still processing: request_id={request_id}, "
            f"waiting {self.wait_interval}s before next poll"
        )

    async def _poll_status(self, request_id: str) -> STTResult:
        """
        Poll job status until completion, failure, or timeout

        This method implements a retry loop that polls the job status up to max_retries times,
        waiting wait_interval seconds between each attempt. It handles various job states:
        - PROCESSING: Continue polling
        - COMPLETED: Parse and return success result
        - FAILED: Parse and return failure result
        - NOT_FOUND (404): Return NOT_FOUND result
        - TIMEOUT: Return TIMEOUT result when max_retries exceeded

        Network error handling:
        - httpx.TimeoutException: Log and continue to next retry
        - httpx.HTTPStatusError (5xx): Log and continue polling
        - httpx.HTTPStatusError (401): Return UNAUTHORIZED immediately
        - httpx.HTTPStatusError (404): Return NOT_FOUND immediately
        - Unexpected exceptions: Log and continue polling

        Args:
            request_id: Unique identifier for the transcription job

        Returns:
            STTResult with final status and data
        """
        import asyncio
        
        logger.info(
            f"[STT] Starting polling for request_id={request_id}, "
            f"max_retries={self.max_retries}, wait_interval={self.wait_interval}s"
        )
        
        for attempt in range(1, self.max_retries + 1):
            try:
                logger.info(
                    f"[STT] Polling attempt {attempt}/{self.max_retries} for request_id={request_id}"
                )
                
                # Get current job status
                response = await self._get_job_status(request_id)
                
                # Extract status from response
                data = response.get("data", {})
                status = data.get("status", "UNKNOWN")
                
                logger.debug(
                    f"[STT] Polling response for request_id={request_id}: status={status}"
                )
                
                # Handle COMPLETED status
                if status == "COMPLETED":
                    return self._parse_completed_response(response, request_id)
                
                # Handle FAILED status
                if status == "FAILED":
                    return self._parse_failed_response(response, request_id)
                
                # Handle PROCESSING status - continue polling
                if status == "PROCESSING":
                    self._parse_processing_response(response, request_id)
                    
                    # Wait before next polling attempt (unless this is the last attempt)
                    if attempt < self.max_retries:
                        await asyncio.sleep(self.wait_interval)
                    continue
                
                # Handle unexpected status
                logger.warning(
                    f"[STT] Unexpected status '{status}' for request_id={request_id}, "
                    f"treating as PROCESSING"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < self.max_retries:
                    await asyncio.sleep(self.wait_interval)
                
            except httpx.HTTPStatusError as e:
                # Use helper method to map error to result
                result = self._map_error_to_stt_result(e, request_id, "polling")
                
                # For 401 and 404, fail immediately (terminal errors)
                if result.status in ["UNAUTHORIZED", "NOT_FOUND"]:
                    return result
                
                # For 5xx and other errors, log and continue polling (transient errors)
                logger.warning(
                    f"[STT] Transient error on attempt {attempt}/{self.max_retries} "
                    f"for request_id={request_id}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < self.max_retries:
                    await asyncio.sleep(self.wait_interval)
                continue
            
            except httpx.TimeoutException as e:
                # Use helper method to log timeout
                self._map_error_to_stt_result(e, request_id, "polling")
                
                logger.warning(
                    f"[STT] Request timeout on attempt {attempt}/{self.max_retries} "
                    f"for request_id={request_id}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < self.max_retries:
                    await asyncio.sleep(self.wait_interval)
                continue
            
            except Exception as e:
                # Use helper method to log unexpected error
                self._map_error_to_stt_result(e, request_id, "polling")
                
                logger.warning(
                    f"[STT] Unexpected error on attempt {attempt}/{self.max_retries} "
                    f"for request_id={request_id}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < self.max_retries:
                    await asyncio.sleep(self.wait_interval)
                continue
        
        # Max retries exceeded - return TIMEOUT
        total_elapsed = self.max_retries * self.wait_interval
        logger.warning(
            f"[STT] Polling timeout: request_id={request_id}, "
            f"exceeded max_retries={self.max_retries}, "
            f"total_elapsed={total_elapsed}s"
        )
        
        return STTResult(
            success=False,
            transcription="",
            status="TIMEOUT",
            error_message=f"Polling timeout after {self.max_retries} attempts ({total_elapsed}s)",
            error_code=-1,
            duration=0.0,
            confidence=0.0,
            processing_time=0.0,
        )
