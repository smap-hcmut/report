"""Integration tests for FFmpeg service integration."""

import os
import pytest
from pathlib import Path

from internal.infrastructure.ffmpeg.client import RemoteFFmpegClient
from config.settings import settings


# Skip integration tests if FFmpeg service URL not configured
pytestmark = pytest.mark.skipif(
    not settings.media_ffmpeg_service_url,
    reason="FFmpeg service URL not configured"
)


@pytest.fixture
async def ffmpeg_client():
    """Create a real FFmpeg client for integration testing."""
    if not settings.media_ffmpeg_service_url:
        pytest.skip("FFmpeg service URL not configured")

    client = RemoteFFmpegClient(
        base_url=settings.media_ffmpeg_service_url,
        timeout=settings.media_ffmpeg_timeout,
        max_retries=settings.media_ffmpeg_max_retries,
        backoff_factor=settings.media_ffmpeg_backoff_factor,
        circuit_breaker_enabled=settings.media_ffmpeg_circuit_breaker,
        circuit_failure_threshold=settings.media_ffmpeg_circuit_threshold,
        circuit_recovery_timeout=settings.media_ffmpeg_circuit_recovery,
    )
    yield client

    # Cleanup - use await instead of asyncio.run
    await client.close()


class TestFFmpegServiceIntegration:
    """Integration tests with actual FFmpeg service."""

    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_health_check(self, ffmpeg_client):
        """Test health check endpoint."""
        is_healthy = await ffmpeg_client.health_check()

        assert is_healthy is True, "FFmpeg service should be healthy"

    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_convert_missing_file(self, ffmpeg_client):
        """Test conversion of non-existent file returns appropriate error."""
        result = await ffmpeg_client.convert_to_mp3(
            video_id="test_missing",
            source_object="nonexistent/video.mp4",
            target_object="nonexistent/audio.mp3",
            bucket_source=settings.minio_bucket,
            bucket_target=settings.minio_bucket,
        )

        # Should return None for 404
        assert result is None

    @pytest.mark.asyncio
    @pytest.mark.integration
    @pytest.mark.skipif(
        not os.getenv("TEST_WITH_REAL_FILES"),
        reason="Requires real test files in MinIO"
    )
    async def test_convert_real_video(self, ffmpeg_client):
        """
        Test actual video conversion (requires test video in MinIO).

        Set TEST_WITH_REAL_FILES=1 and ensure test video exists in MinIO.
        """
        # This test requires a test video to be uploaded to MinIO first
        test_video_id = "test_video_sample"
        source_key = f"test/{test_video_id}.mp4"
        target_key = f"test/{test_video_id}.mp3"

        result = await ffmpeg_client.convert_to_mp3(
            video_id=test_video_id,
            source_object=source_key,
            target_object=target_key,
            bucket_source=settings.minio_bucket,
            bucket_target=settings.minio_bucket,
        )

        assert result is not None
        assert result["status"] == "success"
        assert result["video_id"] == test_video_id
        assert result["audio_object"] == target_key
        assert result["bucket"] == settings.minio_bucket


class TestFFmpegServiceResilience:
    """Test resilience features of the FFmpeg client."""

    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_timeout_handling(self):
        """Test client handles timeouts gracefully."""
        # Create client with very short timeout
        client = RemoteFFmpegClient(
            base_url=settings.media_ffmpeg_service_url or "http://ffmpeg-service:8000",
            timeout=0.001,  # 1ms timeout - will definitely timeout
            max_retries=2,
            backoff_factor=0.1,
        )

        result = await client.convert_to_mp3(
            video_id="test_timeout",
            source_object="test/video.mp4",
            target_object="test/audio.mp3",
            bucket_source="test-bucket",
            bucket_target="test-bucket",
        )

        # Should return None after all retries
        assert result is None

        await client.close()

    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_invalid_url(self):
        """Test client handles invalid service URLs."""
        client = RemoteFFmpegClient(
            base_url="http://nonexistent-service:9999",
            timeout=5,
            max_retries=2,
            backoff_factor=0.1,
        )

        result = await client.convert_to_mp3(
            video_id="test_invalid_url",
            source_object="test/video.mp4",
            target_object="test/audio.mp3",
            bucket_source="test-bucket",
            bucket_target="test-bucket",
        )

        # Should return None after connection failures
        assert result is None

        await client.close()
