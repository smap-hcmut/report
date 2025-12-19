"""HTTP client for interacting with the remote FFmpeg conversion service."""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional

import httpx


class CircuitBreaker:
    """
    Simple circuit breaker pattern to prevent cascading failures.

    States:
    - CLOSED: Normal operation, requests go through
    - OPEN: Failures threshold exceeded, reject requests immediately
    - HALF_OPEN: After recovery timeout, allow one test request
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
    ) -> None:
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        self.logger = logging.getLogger(__name__)

    def record_success(self) -> None:
        """Record a successful request."""
        self.failure_count = 0
        self.state = "CLOSED"

    def record_failure(self) -> None:
        """Record a failed request."""
        self.failure_count += 1
        self.last_failure_time = datetime.utcnow()

        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"
            self.logger.warning(
                f"Circuit breaker opened after {self.failure_count} failures. "
                f"Will retry after {self.recovery_timeout}s"
            )

    def can_attempt(self) -> bool:
        """Check if a request can be attempted."""
        if self.state == "CLOSED":
            return True

        if self.state == "OPEN":
            # Check if recovery timeout has passed
            if self.last_failure_time:
                elapsed = (datetime.utcnow() - self.last_failure_time).total_seconds()
                if elapsed >= self.recovery_timeout:
                    self.state = "HALF_OPEN"
                    self.logger.info("Circuit breaker entering HALF_OPEN state for test request")
                    return True
            return False

        # HALF_OPEN: allow one test request
        return True


class RemoteFFmpegClient:
    """
    HTTP client for interacting with the remote FFmpeg conversion service.

    Features:
    - Connection pooling for efficient HTTP reuse
    - Retry logic with exponential backoff for transient failures
    - Circuit breaker to prevent cascading failures
    - Separate connect and read timeouts
    - Health check endpoint
    """

    def __init__(
        self,
        base_url: str,
        timeout: int = 600,
        max_retries: int = 3,
        backoff_factor: float = 2.0,
        circuit_breaker_enabled: bool = True,
        circuit_failure_threshold: int = 5,
        circuit_recovery_timeout: float = 60.0,
        max_connections: int = 100,
        max_keepalive_connections: int = 20,
    ) -> None:
        """
        Initialize the RemoteFFmpegClient.

        Args:
            base_url: Base URL of the FFmpeg service (e.g., http://ffmpeg-service:8000)
            timeout: Read timeout in seconds for conversion requests
            max_retries: Maximum number of retry attempts for transient failures
            backoff_factor: Exponential backoff multiplier (delay = backoff_factor ** retry_count)
            circuit_breaker_enabled: Enable circuit breaker pattern
            circuit_failure_threshold: Number of failures before opening circuit
            circuit_recovery_timeout: Seconds to wait before attempting recovery
            max_connections: Maximum total connections in pool
            max_keepalive_connections: Maximum idle connections to keep alive
        """
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
        self.logger = logging.getLogger(__name__)

        # Circuit breaker
        self.circuit_breaker_enabled = circuit_breaker_enabled
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=circuit_failure_threshold,
            recovery_timeout=circuit_recovery_timeout,
        ) if circuit_breaker_enabled else None

        # Persistent HTTP client with connection pooling
        # Separate connect timeout (10s) from read timeout (from param)
        timeout_config = httpx.Timeout(
            connect=10.0,
            read=float(timeout),
            write=30.0,
            pool=5.0,
        )

        limits = httpx.Limits(
            max_connections=max_connections,
            max_keepalive_connections=max_keepalive_connections,
            keepalive_expiry=30.0,
        )

        self._client: Optional[httpx.AsyncClient] = None
        self._timeout_config = timeout_config
        self._limits = limits

    async def _get_client(self) -> httpx.AsyncClient:
        """Get or create the persistent HTTP client."""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=self._timeout_config,
                limits=self._limits,
                follow_redirects=True,
            )
        return self._client

    async def close(self) -> None:
        """Close the HTTP client and release connections."""
        if self._client is not None and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    async def health_check(self) -> bool:
        """
        Check if the FFmpeg service is healthy.

        Returns:
            True if service is responding, False otherwise
        """
        try:
            client = await self._get_client()
            response = await client.get(
                f"{self.base_url}/health",
                timeout=5.0,  # Quick health check
            )
            response.raise_for_status()
            data = response.json()

            # Check if service reports healthy status
            status = data.get("status", "").lower()
            is_healthy = status in ("ok", "healthy")

            if not is_healthy:
                self.logger.warning(f"FFmpeg service reports degraded status: {data}")

            return is_healthy

        except Exception as exc:
            self.logger.error(f"FFmpeg service health check failed: {exc}")
            return False

    async def convert_to_mp3(
        self,
        *,
        video_id: str,
        source_object: str,
        target_object: str,
        bucket_source: Optional[str],
        bucket_target: Optional[str],
    ) -> Optional[dict]:
        """
        Invoke remote FFmpeg service to convert a MinIO object to MP3.

        This method includes:
        - Retry logic for transient failures (503 Service Unavailable)
        - Circuit breaker to prevent overwhelming a failing service
        - Detailed error logging with correlation

        Args:
            video_id: YouTube video ID for tracking
            source_object: MinIO object key of source video (e.g., "video/xyz.mp4")
            target_object: MinIO object key for output MP3 (e.g., "video/xyz.mp3")
            bucket_source: Source MinIO bucket name
            bucket_target: Target MinIO bucket name

        Returns:
            Dict with conversion result if successful:
            {
                "status": "success",
                "video_id": "...",
                "audio_object": "...",
                "bucket": "..."
            }
            None if conversion failed after all retries
        """
        # Check circuit breaker
        if self.circuit_breaker_enabled and self.circuit_breaker:
            if not self.circuit_breaker.can_attempt():
                self.logger.warning(
                    f"Circuit breaker is OPEN, skipping FFmpeg conversion for video {video_id}"
                )
                return None

        # Build request payload
        payload = {
            "video_id": video_id,
            "source_object": source_object,
            "target_object": target_object,
        }
        if bucket_source:
            payload["bucket_source"] = bucket_source
        if bucket_target:
            payload["bucket_target"] = bucket_target

        # Retry loop with exponential backoff
        last_exception: Optional[Exception] = None

        for attempt in range(self.max_retries):
            try:
                client = await self._get_client()

                self.logger.info(
                    f"Requesting FFmpeg conversion for video {video_id} "
                    f"(attempt {attempt + 1}/{self.max_retries})"
                )

                response = await client.post(
                    f"{self.base_url}/convert",
                    json=payload,
                )

                # Handle different HTTP status codes
                if response.status_code == 200:
                    result = response.json()

                    # Validate response
                    if "audio_object" not in result or "bucket" not in result:
                        self.logger.error(
                            f"Invalid response from FFmpeg service for video {video_id}: {result}"
                        )
                        return None

                    self.logger.info(
                        f"FFmpeg conversion successful for video {video_id}: "
                        f"{result['bucket']}/{result['audio_object']}"
                    )

                    # Record success for circuit breaker
                    if self.circuit_breaker:
                        self.circuit_breaker.record_success()

                    return result

                elif response.status_code == 503:
                    # Service unavailable - retry with backoff
                    detail = response.text
                    self.logger.warning(
                        f"FFmpeg service temporarily unavailable for video {video_id} "
                        f"(attempt {attempt + 1}/{self.max_retries}): {detail}"
                    )
                    last_exception = httpx.HTTPStatusError(
                        f"Service unavailable: {detail}",
                        request=response.request,
                        response=response,
                    )

                    # Exponential backoff before retry
                    if attempt < self.max_retries - 1:
                        delay = self.backoff_factor ** attempt
                        self.logger.info(f"Retrying in {delay}s...")
                        await asyncio.sleep(delay)
                    continue

                elif response.status_code in (400, 404, 500):
                    # Permanent errors - don't retry
                    detail = response.text
                    self.logger.error(
                        f"FFmpeg service error {response.status_code} for video {video_id}: {detail}"
                    )

                    if self.circuit_breaker:
                        self.circuit_breaker.record_failure()

                    return None

                else:
                    # Unexpected status code
                    response.raise_for_status()

            except httpx.TimeoutException as exc:
                self.logger.error(
                    f"Timeout calling FFmpeg service for video {video_id} "
                    f"(attempt {attempt + 1}/{self.max_retries}): {exc}"
                )
                last_exception = exc

                # Timeout might be transient, retry
                if attempt < self.max_retries - 1:
                    delay = self.backoff_factor ** attempt
                    await asyncio.sleep(delay)
                continue

            except httpx.RequestError as exc:
                self.logger.error(
                    f"Error contacting FFmpeg service for video {video_id} "
                    f"(attempt {attempt + 1}/{self.max_retries}): {exc}"
                )
                last_exception = exc

                # Network errors might be transient, retry
                if attempt < self.max_retries - 1:
                    delay = self.backoff_factor ** attempt
                    await asyncio.sleep(delay)
                continue

            except Exception as exc:
                self.logger.exception(
                    f"Unexpected error calling FFmpeg service for video {video_id}: {exc}"
                )
                last_exception = exc
                break

        # All retries exhausted
        if self.circuit_breaker:
            self.circuit_breaker.record_failure()

        self.logger.error(
            f"FFmpeg conversion failed for video {video_id} after {self.max_retries} attempts. "
            f"Last error: {last_exception}"
        )
        return None

    async def __aenter__(self):
        """Context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - cleanup resources."""
        await self.close()
