"""
HTTP Client for Speech-to-Text REST API
Provides interface to call the STT service for audio transcription
"""
import httpx
from typing import Optional
from application.interfaces import ISpeech2TextClient
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
        >>> content = Content(external_id="dQw4w9WgXcQ", source="YOUTUBE", url="https://youtube.com/watch?v=dQw4w9WgXcQ")
        >>> generate_request_id(content)
        'dQw4w9WgXcQ'
    """
    return str(content.external_id)


class Speech2TextRestClient(ISpeech2TextClient):
    """Client for interacting with Speech-to-Text REST API service"""
    
    def __init__(
        self,
        base_url: str,
        api_key: str,
        timeout: int = 30,
        max_retries: int = 60,
        wait_interval: int = 3
    ):
        """
        Initialize Speech-to-Text REST API client
        
        Args:
            base_url: Base URL of the STT API (e.g., http://172.16.21.230/transcribe)
            api_key: API key for authentication
            timeout: HTTP request timeout in seconds for individual submit/poll requests (default: 30s)
                    Note: This is the timeout for each HTTP request, not the total transcription time.
                    Total wait time is determined by max_retries * wait_interval.
            max_retries: Maximum number of polling attempts before timeout (default: 60)
            wait_interval: Seconds to wait between polling attempts (default: 3)
        """
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.timeout = timeout
        self.max_retries = max_retries
        self.wait_interval = wait_interval
    
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

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(endpoint, json=payload, headers=headers)
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

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(endpoint, headers=headers)
            
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

    def _parse_completed_response(self, response: dict, request_id: str) -> "STTResult":
        """
        Parse COMPLETED response and extract transcription data
        
        Args:
            response: API response dictionary
            request_id: Unique identifier for the transcription job
            
        Returns:
            STTResult with success=True and transcription data
        """
        from application.interfaces import STTResult
        
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
    
    def _parse_failed_response(self, response: dict, request_id: str) -> "STTResult":
        """
        Parse FAILED response and extract error information
        
        Args:
            response: API response dictionary
            request_id: Unique identifier for the transcription job
            
        Returns:
            STTResult with success=False and error information
        """
        from application.interfaces import STTResult
        
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
            f"[STT] Job still processing: request_id={request_id}"
        )
    
    def _map_error_to_stt_result(
        self, error: Exception, request_id: str, context: str
    ) -> "STTResult":
        """
        Map exceptions to STTResult objects with appropriate status and error information.
        
        This helper method centralizes error handling logic, converting various exception
        types into structured STTResult objects. It handles:
        - httpx.TimeoutException: Network timeout errors
        - httpx.HTTPStatusError: HTTP error responses (401, 404, 5xx, etc.)
        - Generic exceptions: Unexpected errors
        
        Args:
            error: The exception that occurred
            request_id: Unique identifier for the transcription job
            context: Description of where the error occurred (e.g., "submit", "poll")
            
        Returns:
            STTResult with success=False and appropriate error details
        """
        from application.interfaces import STTResult
        
        # Handle timeout exceptions
        if isinstance(error, httpx.TimeoutException):
            logger.warning(
                f"[STT] Request timeout during {context} for request_id={request_id}"
            )
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
            
            # 401 Unauthorized - Invalid API key (terminal error)
            if status_code == 401:
                logger.error(
                    f"[STT] Unauthorized (401) during {context} for request_id={request_id}: "
                    f"Invalid API key"
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
            
            # 404 Not Found - Job not found or expired (terminal error)
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
            
            # 5xx Server errors (transient, should continue polling)
            if 500 <= status_code < 600:
                logger.warning(
                    f"[STT] Server error ({status_code}) during {context} "
                    f"for request_id={request_id}"
                )
                return STTResult(
                    success=False,
                    transcription="",
                    status="SERVER_ERROR",
                    error_message=f"Server error ({status_code}) during {context}",
                    error_code=status_code,
                    duration=0.0,
                    confidence=0.0,
                    processing_time=0.0,
                )
            
            # Other HTTP errors
            logger.warning(
                f"[STT] HTTP error ({status_code}) during {context} "
                f"for request_id={request_id}"
            )
            return STTResult(
                success=False,
                transcription="",
                status="HTTP_ERROR",
                error_message=f"HTTP error ({status_code}) during {context}",
                error_code=status_code,
                duration=0.0,
                confidence=0.0,
                processing_time=0.0,
            )
        
        # Handle unexpected exceptions
        logger.error(
            f"[STT] Unexpected exception during {context} for request_id={request_id}: "
            f"{type(error).__name__}: {str(error)}",
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

    async def _poll_status(self, request_id: str) -> "STTResult":
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
        from application.interfaces import STTResult
        
        # Use instance configuration values
        max_retries = self.max_retries
        wait_interval = self.wait_interval
        
        logger.info(
            f"[STT] Starting polling for request_id={request_id}, "
            f"max_retries={max_retries}, wait_interval={wait_interval}s"
        )
        
        for attempt in range(1, max_retries + 1):
            try:
                logger.info(
                    f"[STT] Polling attempt {attempt}/{max_retries} for request_id={request_id}"
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
                    if attempt < max_retries:
                        await asyncio.sleep(wait_interval)
                    continue
                
                # Handle unexpected status
                logger.warning(
                    f"[STT] Unexpected status '{status}' for request_id={request_id}, "
                    f"treating as PROCESSING"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < max_retries:
                    await asyncio.sleep(wait_interval)
                
            except httpx.HTTPStatusError as e:
                status_code = e.response.status_code
                
                # Handle 404 - Job not found (terminal error)
                if status_code == 404:
                    return self._map_error_to_stt_result(e, request_id, "poll")
                
                # Handle 401 - Unauthorized (terminal error)
                if status_code == 401:
                    return self._map_error_to_stt_result(e, request_id, "poll")
                
                # Handle 5xx - Server errors (transient, continue polling)
                if 500 <= status_code < 600:
                    logger.warning(
                        f"[STT] Server error ({status_code}) on attempt {attempt}/{max_retries} "
                        f"for request_id={request_id}, continuing polling"
                    )
                    
                    # Wait before next polling attempt (unless this is the last attempt)
                    if attempt < max_retries:
                        await asyncio.sleep(wait_interval)
                    continue
                
                # Handle other HTTP errors (transient, continue polling)
                logger.warning(
                    f"[STT] HTTP error ({status_code}) on attempt {attempt}/{max_retries} "
                    f"for request_id={request_id}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < max_retries:
                    await asyncio.sleep(wait_interval)
                continue
            
            except httpx.TimeoutException as e:
                # Log and continue polling (transient error)
                logger.warning(
                    f"[STT] Request timeout on attempt {attempt}/{max_retries} "
                    f"for request_id={request_id}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < max_retries:
                    await asyncio.sleep(wait_interval)
                continue
            
            except Exception as e:
                # Log and continue polling (unexpected error, treat as transient)
                logger.warning(
                    f"[STT] Unexpected error on attempt {attempt}/{max_retries} "
                    f"for request_id={request_id}: {str(e)}, continuing polling"
                )
                
                # Wait before next polling attempt (unless this is the last attempt)
                if attempt < max_retries:
                    await asyncio.sleep(wait_interval)
                continue
        
        # Max retries exceeded - return TIMEOUT
        total_elapsed = max_retries * wait_interval
        logger.warning(
            f"[STT] Polling timeout: request_id={request_id}, "
            f"exceeded max_retries={max_retries}, "
            f"total_elapsed={total_elapsed}s"
        )
        
        return STTResult(
            success=False,
            transcription="",
            status="TIMEOUT",
            error_message=f"Polling timeout after {max_retries} attempts ({total_elapsed}s)",
            error_code=-1,
            duration=0.0,
            confidence=0.0,
            processing_time=0.0,
        )
        
    async def transcribe(
        self,
        audio_url: str,
        language: str = "vi",
        request_id: Optional[str] = None
    ) -> "STTResult":
        """
        Submit transcription job and poll until completion.
        
        This method implements the async polling pattern for STT transcription:
        1. Generate a request_id (if not provided)
        2. Submit the transcription job to the STT service
        3. Poll the job status until completion, failure, or timeout
        4. Return structured STTResult with all fields populated
        
        The method replaces the old synchronous string-based return with STTResult,
        providing better error handling and status tracking.
        
        Args:
            audio_url: Presigned URL of the audio file
            language: Language code (default: "vi")
            request_id: Unique job identifier (if None, uses a generated ID)
            
        Returns:
            STTResult with transcription or error information
        """
        from application.interfaces import STTResult
        import time
        
        # Generate request_id if not provided
        # Note: In practice, this should be derived from content.external_id
        # but for backward compatibility, we generate one if not provided
        if request_id is None:
            import uuid
            request_id = str(uuid.uuid4())
            logger.warning(
                f"[STT] No request_id provided, generated: {request_id}. "
                f"For idempotent submission, pass content.external_id as request_id."
            )
        
        start_time = time.time()
        
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
            
        except httpx.HTTPStatusError as e:
            # Handle submission errors (401, 400, etc.)
            logger.error(
                f"[STT] Job submission failed with HTTP error: request_id={request_id}, "
                f"status_code={e.response.status_code}"
            )
            return self._map_error_to_stt_result(e, request_id, "submit")
            
        except httpx.TimeoutException as e:
            # Handle submission timeout
            logger.error(
                f"[STT] Job submission timed out: request_id={request_id}"
            )
            return self._map_error_to_stt_result(e, request_id, "submit")
            
        except Exception as e:
            # Handle unexpected submission errors
            logger.error(
                f"[STT] Job submission failed with unexpected error: request_id={request_id}, "
                f"error={str(e)}",
                exc_info=True
            )
            return self._map_error_to_stt_result(e, request_id, "submit")
        
        # Step 2: Poll for job completion
        try:
            result = await self._poll_status(request_id)
            
            # Calculate total elapsed time
            elapsed_time = time.time() - start_time
            
            # Log final result
            if result.success:
                logger.info(
                    f"[STT] Transcription completed successfully: request_id={request_id}, "
                    f"total_elapsed={elapsed_time:.2f}s, "
                    f"transcription_length={len(result.transcription) if result.transcription else 0}"
                )
            else:
                logger.error(
                    f"[STT] Transcription failed: request_id={request_id}, "
                    f"status={result.status}, error={result.error_message}, "
                    f"total_elapsed={elapsed_time:.2f}s"
                )
            
            return result
            
        except Exception as e:
            # Handle unexpected polling errors (should be rare, as _poll_status handles most errors)
            logger.error(
                f"[STT] Polling failed with unexpected error: request_id={request_id}, "
                f"error={str(e)}",
                exc_info=True
            )
            return self._map_error_to_stt_result(e, request_id, "poll")
