"""Integration tests for API endpoints."""

from unittest.mock import Mock, patch
import pytest
from fastapi.testclient import TestClient

from cmd.api.main import app
from core.container import init_container
from core.config import Settings


@pytest.fixture
def test_settings():
    """Create test settings."""
    return Settings(
        minio_endpoint="localhost:9000",
        minio_access_key="test",
        minio_secret_key="test",
        minio_bucket_source="test-source",
        minio_bucket_target="test-target",
        minio_secure=False,
    )


@pytest.fixture
def client():
    """Create test client."""
    with TestClient(app) as client:
        yield client


class TestHealthEndpoint:
    """Tests for /health endpoint."""

    @patch("cmd.api.routes.get_minio_client")
    def test_health_check_success(self, mock_get_client, client):
        """Test health check with successful MinIO connection."""
        mock_minio = Mock()
        mock_minio.list_buckets.return_value = []
        mock_get_client.return_value = mock_minio

        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["checks"]["minio"] == "connected"

    @patch("cmd.api.routes.get_minio_client")
    def test_health_check_minio_error(self, mock_get_client, client):
        """Test health check with MinIO connection error."""
        mock_minio = Mock()
        mock_minio.list_buckets.side_effect = Exception("Connection failed")
        mock_get_client.return_value = mock_minio

        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "degraded"
        assert "error" in data["checks"]["minio"]


class TestConvertEndpoint:
    """Tests for /convert endpoint."""

    @patch("cmd.api.routes.get_converter")
    def test_convert_success(self, mock_get_converter, client):
        """Test successful conversion."""
        mock_converter = Mock()
        mock_converter.convert_to_mp3.return_value = ("output-bucket", "output/key.mp3")
        mock_get_converter.return_value = mock_converter

        payload = {
            "video_id": "test123",
            "source_object": "input/video.mp4",
        }

        response = client.post("/convert", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["video_id"] == "test123"
        assert data["bucket"] == "output-bucket"
        assert data["audio_object"] == "output/key.mp3"

    @patch("cmd.api.routes.get_converter")
    def test_convert_not_found(self, mock_get_converter, client):
        """Test conversion with source file not found."""
        from models.exceptions import StorageNotFoundError

        mock_converter = Mock()
        mock_converter.convert_to_mp3.side_effect = StorageNotFoundError(
            "File not found",
            bucket="source",
            object_key="video.mp4",
        )
        mock_get_converter.return_value = mock_converter

        payload = {
            "video_id": "test123",
            "source_object": "missing.mp4",
        }

        response = client.post("/convert", json=payload)

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @patch("cmd.api.routes.get_converter")
    def test_convert_invalid_media(self, mock_get_converter, client):
        """Test conversion with invalid media file."""
        from models.exceptions import InvalidMediaError

        mock_converter = Mock()
        mock_converter.convert_to_mp3.side_effect = InvalidMediaError(
            "Invalid media",
            video_id="test123",
        )
        mock_get_converter.return_value = mock_converter

        payload = {
            "video_id": "test123",
            "source_object": "corrupt.mp4",
        }

        response = client.post("/convert", json=payload)

        assert response.status_code == 400
        assert "invalid" in response.json()["detail"].lower()

    @patch("cmd.api.routes.get_converter")
    def test_convert_transient_error(self, mock_get_converter, client):
        """Test conversion with transient error."""
        from models.exceptions import TransientConversionError

        mock_converter = Mock()
        mock_converter.convert_to_mp3.side_effect = TransientConversionError(
            "Timeout",
            video_id="test123",
        )
        mock_get_converter.return_value = mock_converter

        payload = {
            "video_id": "test123",
            "source_object": "video.mp4",
        }

        response = client.post("/convert", json=payload)

        assert response.status_code == 503
        assert "retry" in response.json()["detail"].lower()
