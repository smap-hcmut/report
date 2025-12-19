"""Unit tests for MediaConverter service."""

import subprocess
from unittest.mock import Mock, patch, MagicMock
import pytest

from minio.error import S3Error

from core.config import Settings
from domain.enums import AudioQuality
from models.exceptions import (
    FFmpegExecutionError,
    StorageAccessError,
    StorageNotFoundError,
)
from services.converter import MediaConverter


@pytest.fixture
def mock_settings():
    """Create mock settings."""
    settings = Mock(spec=Settings)
    settings.minio_bucket_source = "test-source"
    settings.minio_bucket_target = "test-target"
    settings.minio_target_prefix = "audio"
    settings.minio_upload_part_size = 10 * 1024 * 1024
    settings.ffmpeg_path = "/usr/bin/ffmpeg"
    settings.ffmpeg_timeout_seconds = 300
    settings.presigned_expiry.return_value = 3600
    return settings


@pytest.fixture
def mock_minio_client():
    """Create mock MinIO client."""
    client = Mock()
    client.presigned_get_object.return_value = "http://minio/presigned-url"
    return client


@pytest.fixture
def converter(mock_minio_client, mock_settings):
    """Create MediaConverter instance with mocked dependencies."""
    return MediaConverter(mock_minio_client, mock_settings)


class TestMediaConverter:
    """Tests for MediaConverter class."""

    def test_build_presigned_url_success(self, converter, mock_minio_client):
        """Test successful presigned URL generation."""
        url = converter._build_presigned_url("bucket", "key")

        assert url == "http://minio/presigned-url"
        mock_minio_client.presigned_get_object.assert_called_once()

    def test_build_presigned_url_not_found(self, converter, mock_minio_client):
        """Test presigned URL generation when object not found."""
        error = S3Error(
            "NoSuchKey",
            "Object not found",
            "resource",
            "request_id",
            "host_id",
            "response",
        )
        mock_minio_client.presigned_get_object.side_effect = error

        with pytest.raises(StorageNotFoundError) as exc_info:
            converter._build_presigned_url("bucket", "key")

        assert "not found" in str(exc_info.value).lower()

    def test_build_presigned_url_access_error(self, converter, mock_minio_client):
        """Test presigned URL generation with access error."""
        error = S3Error(
            "AccessDenied",
            "Access denied",
            "resource",
            "request_id",
            "host_id",
            "response",
        )
        mock_minio_client.presigned_get_object.side_effect = error

        with pytest.raises(StorageAccessError):
            converter._build_presigned_url("bucket", "key")

    def test_build_target_key_with_custom_object(self, converter):
        """Test target key building with custom object name."""
        key = converter._build_target_key("video123", "custom/path.mp3")
        assert key == "custom/path.mp3"

    def test_build_target_key_with_prefix(self, converter):
        """Test target key building with prefix."""
        key = converter._build_target_key("video123", None)
        assert key == "audio/video123.mp3"

    def test_build_ffmpeg_command(self, converter):
        """Test FFmpeg command construction."""
        command = converter._build_ffmpeg_command(
            "http://input-url",
            AudioQuality.HIGH,
        )

        assert command[0] == "/usr/bin/ffmpeg"
        assert "-i" in command
        assert "http://input-url" in command
        assert "-b:a" in command
        assert "256k" in command  # HIGH quality
        assert "-" in command  # stdout

    @patch("services.converter.subprocess.Popen")
    def test_execute_ffmpeg_success(self, mock_popen, converter):
        """Test successful FFmpeg execution."""
        mock_process = Mock()
        mock_process.stdout = Mock()
        mock_process.stderr = Mock()
        mock_popen.return_value = mock_process

        process = converter._execute_ffmpeg(["/usr/bin/ffmpeg", "-version"], "video123")

        assert process == mock_process
        mock_popen.assert_called_once()

    @patch("services.converter.subprocess.Popen")
    def test_execute_ffmpeg_not_found(self, mock_popen, converter):
        """Test FFmpeg execution when binary not found."""
        mock_popen.side_effect = FileNotFoundError("ffmpeg not found")

        with pytest.raises(FFmpegExecutionError) as exc_info:
            converter._execute_ffmpeg(["/usr/bin/ffmpeg"], "video123")

        assert "not found" in str(exc_info.value).lower()

    def test_upload_to_minio_success(self, converter, mock_minio_client):
        """Test successful upload to MinIO."""
        mock_stream = Mock()

        converter._upload_to_minio(
            mock_stream,
            "bucket",
            "key",
            "video123",
        )

        mock_minio_client.put_object.assert_called_once_with(
            "bucket",
            "key",
            data=mock_stream,
            length=-1,
            part_size=10 * 1024 * 1024,
            content_type="audio/mpeg",
        )

    def test_upload_to_minio_error(self, converter, mock_minio_client):
        """Test upload to MinIO with error."""
        error = S3Error(
            "InternalError",
            "Server error",
            "resource",
            "request_id",
            "host_id",
            "response",
        )
        mock_minio_client.put_object.side_effect = error

        with pytest.raises(StorageAccessError):
            converter._upload_to_minio(Mock(), "bucket", "key", "video123")

    def test_wait_for_completion_success(self, converter):
        """Test waiting for FFmpeg completion."""
        mock_process = Mock()
        mock_process.wait.return_value = 0
        mock_process.stderr.read.return_value = b"some stderr output"

        return_code, stderr = converter._wait_for_completion(mock_process, "video123")

        assert return_code == 0
        assert stderr == "some stderr output"

    def test_wait_for_completion_timeout(self, converter):
        """Test FFmpeg timeout."""
        mock_process = Mock()
        mock_process.wait.side_effect = subprocess.TimeoutExpired("ffmpeg", 300)
        mock_process.stderr = Mock()

        with pytest.raises(Exception):  # TransientConversionError
            converter._wait_for_completion(mock_process, "video123")

        mock_process.kill.assert_called_once()
