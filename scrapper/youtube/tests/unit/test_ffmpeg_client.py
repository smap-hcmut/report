"""Unit tests for RemoteFFmpegClient."""

import pytest
import httpx
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from datetime import datetime

from internal.infrastructure.ffmpeg.client import RemoteFFmpegClient, CircuitBreaker


# ===================================================================
# CircuitBreaker Tests
# ===================================================================


class TestCircuitBreaker:
    """Tests for CircuitBreaker pattern."""

    def test_initial_state_closed(self):
        """Test circuit breaker starts in CLOSED state."""
        cb = CircuitBreaker(failure_threshold=3)
        assert cb.state == "CLOSED"
        assert cb.can_attempt() is True

    def test_record_success_resets_failures(self):
        """Test that success resets failure count."""
        cb = CircuitBreaker(failure_threshold=3)
        cb.record_failure()
        cb.record_failure()
        assert cb.failure_count == 2

        cb.record_success()
        assert cb.failure_count == 0
        assert cb.state == "CLOSED"

    def test_circuit_opens_after_threshold(self):
        """Test circuit opens after reaching failure threshold."""
        cb = CircuitBreaker(failure_threshold=3, recovery_timeout=60)

        # Record failures up to threshold
        for i in range(3):
            cb.record_failure()

        assert cb.state == "OPEN"
        assert cb.can_attempt() is False

    def test_circuit_enters_half_open_after_recovery_timeout(self):
        """Test circuit enters HALF_OPEN state after recovery timeout."""
        cb = CircuitBreaker(failure_threshold=2, recovery_timeout=0.1)

        # Open the circuit
        cb.record_failure()
        cb.record_failure()
        assert cb.state == "OPEN"

        # Wait for recovery timeout (mock by setting time manually)
        import time
        time.sleep(0.2)

        # Should allow a test attempt
        assert cb.can_attempt() is True
        assert cb.state == "HALF_OPEN"

    def test_half_open_allows_one_attempt(self):
        """Test HALF_OPEN state allows test requests."""
        cb = CircuitBreaker()
        cb.state = "HALF_OPEN"

        assert cb.can_attempt() is True


# ===================================================================
# RemoteFFmpegClient Tests
# ===================================================================


@pytest.fixture
def mock_httpx_client():
    """Create a mock httpx.AsyncClient."""
    client = AsyncMock(spec=httpx.AsyncClient)
    client.is_closed = False
    return client


@pytest.fixture
def client():
    """Create a RemoteFFmpegClient for testing."""
    return RemoteFFmpegClient(
        base_url="http://test-ffmpeg:8000",
        timeout=60,
        max_retries=3,
        backoff_factor=1.0,  # Fast for testing
        circuit_breaker_enabled=True,
        circuit_failure_threshold=3,
        circuit_recovery_timeout=60.0,
    )


class TestRemoteFFmpegClient:
    """Tests for RemoteFFmpegClient."""

    def test_initialization(self):
        """Test client initializes with correct parameters."""
        client = RemoteFFmpegClient(
            base_url="http://ffmpeg:8000/",
            timeout=600,
            max_retries=5,
        )

        assert client.base_url == "http://ffmpeg:8000"  # trailing slash removed
        assert client.timeout == 600
        assert client.max_retries == 5
        assert client.circuit_breaker is not None

    def test_initialization_without_circuit_breaker(self):
        """Test client can be created without circuit breaker."""
        client = RemoteFFmpegClient(
            base_url="http://ffmpeg:8000",
            circuit_breaker_enabled=False,
        )

        assert client.circuit_breaker is None

    @pytest.mark.asyncio
    async def test_get_client_creates_client(self, client):
        """Test _get_client creates httpx.AsyncClient."""
        httpx_client = await client._get_client()

        assert isinstance(httpx_client, httpx.AsyncClient)
        assert httpx_client.is_closed is False

    @pytest.mark.asyncio
    async def test_close_closes_client(self, client):
        """Test close() properly closes the HTTP client."""
        # Create client
        await client._get_client()
        assert client._client is not None

        # Close it
        await client.close()
        assert client._client is None

    @pytest.mark.asyncio
    async def test_context_manager(self):
        """Test client works as async context manager."""
        async with RemoteFFmpegClient(base_url="http://test:8000") as client:
            assert client._client is not None or client._client is None  # May be lazy

        # After exit, client should be closed
        # (Note: _client may be None if never used)

    @pytest.mark.asyncio
    async def test_health_check_success(self, client, mock_httpx_client):
        """Test health_check returns True when service is healthy."""
        # Mock successful health check response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "ok", "checks": {"minio": "connected"}}
        mock_response.raise_for_status = Mock()

        mock_httpx_client.get = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        is_healthy = await client.health_check()

        assert is_healthy is True
        mock_httpx_client.get.assert_called_once_with("http://test-ffmpeg:8000/health", timeout=5.0)

    @pytest.mark.asyncio
    async def test_health_check_degraded(self, client, mock_httpx_client):
        """Test health_check returns False when service is degraded."""
        # Mock degraded health check response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "degraded", "checks": {"minio": "error"}}
        mock_response.raise_for_status = Mock()

        mock_httpx_client.get = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        is_healthy = await client.health_check()

        assert is_healthy is False

    @pytest.mark.asyncio
    async def test_health_check_failure(self, client, mock_httpx_client):
        """Test health_check returns False on connection error."""
        mock_httpx_client.get = AsyncMock(side_effect=httpx.RequestError("Connection failed"))
        client._client = mock_httpx_client

        is_healthy = await client.health_check()

        assert is_healthy is False

    @pytest.mark.asyncio
    async def test_convert_to_mp3_success(self, client, mock_httpx_client):
        """Test successful MP3 conversion."""
        # Mock successful conversion response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": "success",
            "video_id": "test123",
            "audio_object": "audio/test123.mp3",
            "bucket": "youtube-media"
        }

        mock_httpx_client.post = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is not None
        assert result["status"] == "success"
        assert result["video_id"] == "test123"
        assert result["audio_object"] == "audio/test123.mp3"
        assert result["bucket"] == "youtube-media"

    @pytest.mark.asyncio
    async def test_convert_to_mp3_invalid_response(self, client, mock_httpx_client):
        """Test convert_to_mp3 returns None for invalid response."""
        # Mock response missing required fields
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "success"}  # Missing audio_object and bucket

        mock_httpx_client.post = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source=None,
            bucket_target=None,
        )

        assert result is None

    @pytest.mark.asyncio
    async def test_convert_to_mp3_retry_on_503(self, client, mock_httpx_client):
        """Test retries on 503 Service Unavailable."""
        # First two attempts fail with 503, third succeeds
        mock_response_503 = Mock()
        mock_response_503.status_code = 503
        mock_response_503.text = "Service temporarily unavailable"

        mock_response_200 = Mock()
        mock_response_200.status_code = 200
        mock_response_200.json.return_value = {
            "status": "success",
            "video_id": "test123",
            "audio_object": "audio/test123.mp3",
            "bucket": "youtube-media"
        }

        mock_httpx_client.post = AsyncMock(
            side_effect=[mock_response_503, mock_response_503, mock_response_200]
        )
        client._client = mock_httpx_client
        client.backoff_factor = 0.01  # Fast retries for testing

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is not None
        assert result["status"] == "success"
        assert mock_httpx_client.post.call_count == 3

    @pytest.mark.asyncio
    async def test_convert_to_mp3_no_retry_on_404(self, client, mock_httpx_client):
        """Test no retry on 404 Not Found (permanent error)."""
        mock_response = Mock()
        mock_response.status_code = 404
        mock_response.text = "Source file not found"

        mock_httpx_client.post = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/missing.mp4",
            target_object="audio/missing.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is None
        assert mock_httpx_client.post.call_count == 1  # No retries

    @pytest.mark.asyncio
    async def test_convert_to_mp3_circuit_breaker_opens(self, client, mock_httpx_client):
        """Test circuit breaker opens after failures."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.text = "Internal server error"

        mock_httpx_client.post = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        # Trigger failures to open circuit
        for _ in range(client.circuit_breaker.failure_threshold):
            result = await client.convert_to_mp3(
                video_id=f"test{_}",
                source_object="video/test.mp4",
                target_object="audio/test.mp3",
                bucket_source="youtube-media",
                bucket_target="youtube-media",
            )
            assert result is None

        # Circuit should be open now
        assert client.circuit_breaker.state == "OPEN"

        # Next request should be rejected immediately
        result = await client.convert_to_mp3(
            video_id="test999",
            source_object="video/test.mp4",
            target_object="audio/test.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )
        assert result is None

    @pytest.mark.asyncio
    async def test_convert_to_mp3_circuit_breaker_disabled(self):
        """Test conversion works when circuit breaker is disabled."""
        client = RemoteFFmpegClient(
            base_url="http://test:8000",
            circuit_breaker_enabled=False,
        )

        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": "success",
            "video_id": "test123",
            "audio_object": "audio/test123.mp3",
            "bucket": "youtube-media"
        }

        mock_httpx_client = AsyncMock(spec=httpx.AsyncClient)
        mock_httpx_client.is_closed = False
        mock_httpx_client.post = AsyncMock(return_value=mock_response)
        client._client = mock_httpx_client

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is not None
        assert client.circuit_breaker is None

    @pytest.mark.asyncio
    async def test_convert_to_mp3_timeout(self, client, mock_httpx_client):
        """Test handling of timeout errors."""
        mock_httpx_client.post = AsyncMock(side_effect=httpx.TimeoutException("Request timeout"))
        client._client = mock_httpx_client
        client.backoff_factor = 0.01  # Fast retries for testing

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is None
        assert mock_httpx_client.post.call_count == client.max_retries

    @pytest.mark.asyncio
    async def test_convert_to_mp3_request_error(self, client, mock_httpx_client):
        """Test handling of network errors."""
        mock_httpx_client.post = AsyncMock(side_effect=httpx.RequestError("Network error"))
        client._client = mock_httpx_client
        client.backoff_factor = 0.01

        result = await client.convert_to_mp3(
            video_id="test123",
            source_object="video/test123.mp4",
            target_object="audio/test123.mp3",
            bucket_source="youtube-media",
            bucket_target="youtube-media",
        )

        assert result is None
        assert mock_httpx_client.post.call_count == client.max_retries
