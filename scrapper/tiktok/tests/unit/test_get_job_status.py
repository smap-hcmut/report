"""
Unit tests for Speech2TextRestClient._get_job_status method
Tests the status polling method implementation
"""

import pytest
import httpx
from unittest.mock import AsyncMock, patch, MagicMock
from internal.infrastructure.rest_client.speech2text_rest_client import Speech2TextRestClient


class TestGetJobStatus:
    """Test _get_job_status method"""

    @pytest.fixture
    def stt_client(self):
        """Create STT client for testing"""
        return Speech2TextRestClient(
            base_url="http://test-stt:8000",
            api_key="test-api-key",
            timeout=30,
            max_retries=5,
            wait_interval=1
        )

    @pytest.mark.asyncio
    async def test_get_job_status_success(self, stt_client):
        """Test successful job status retrieval"""
        mock_response = {
            "error_code": 0,
            "message": "Transcription in progress",
            "data": {
                "request_id": "test-request-123",
                "status": "PROCESSING"
            }
        }
        
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 200
        mock_response_obj.json.return_value = mock_response
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        result = await stt_client._get_job_status("test-request-123")
        
        assert result == mock_response
        assert result["data"]["status"] == "PROCESSING"
        mock_client.get.assert_called_once_with(
            "http://test-stt:8000/api/transcribe/test-request-123",
            headers={"X-API-Key": "test-api-key"}
        )

    @pytest.mark.asyncio
    async def test_get_job_status_completed(self, stt_client):
        """Test job status retrieval for completed job"""
        mock_response = {
            "error_code": 0,
            "message": "Transcription completed",
            "data": {
                "request_id": "test-request-123",
                "status": "COMPLETED",
                "transcription": "Test transcription text",
                "duration": 10.5,
                "confidence": 0.95,
                "processing_time": 2.3
            }
        }
        
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 200
        mock_response_obj.json.return_value = mock_response
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        result = await stt_client._get_job_status("test-request-123")
        
        assert result["data"]["status"] == "COMPLETED"
        assert result["data"]["transcription"] == "Test transcription text"

    @pytest.mark.asyncio
    async def test_get_job_status_404_not_found(self, stt_client):
        """Test job status retrieval when job not found (404)"""
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 404
        mock_response_obj.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Not Found", request=MagicMock(), response=mock_response_obj
        )
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        with pytest.raises(httpx.HTTPStatusError):
            await stt_client._get_job_status("nonexistent-request")

    @pytest.mark.asyncio
    async def test_get_job_status_401_unauthorized(self, stt_client):
        """Test job status retrieval with invalid API key (401)"""
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 401
        mock_response_obj.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Unauthorized", request=MagicMock(), response=mock_response_obj
        )
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        with pytest.raises(httpx.HTTPStatusError):
            await stt_client._get_job_status("test-request-123")

    @pytest.mark.asyncio
    async def test_get_job_status_endpoint_construction(self, stt_client):
        """Test that endpoint URL is correctly constructed"""
        mock_response = {
            "error_code": 0,
            "message": "OK",
            "data": {"request_id": "test-123", "status": "PROCESSING"}
        }
        
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 200
        mock_response_obj.json.return_value = mock_response
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        await stt_client._get_job_status("test-123")
        
        # Verify the endpoint was constructed correctly
        call_args = mock_client.get.call_args
        assert call_args[0][0] == "http://test-stt:8000/api/transcribe/test-123"
        assert call_args[1]["headers"]["X-API-Key"] == "test-api-key"

    @pytest.mark.asyncio
    async def test_get_job_status_failed_job(self, stt_client):
        """Test job status retrieval for failed job"""
        mock_response = {
            "error_code": 0,
            "message": "Transcription failed",
            "data": {
                "request_id": "test-request-123",
                "status": "FAILED",
                "error": "Audio file corrupted"
            }
        }
        
        mock_client = AsyncMock()
        mock_response_obj = MagicMock()
        mock_response_obj.status_code = 200
        mock_response_obj.json.return_value = mock_response
        mock_client.get.return_value = mock_response_obj
        
        # Replace the client instance
        stt_client.client = mock_client
        
        result = await stt_client._get_job_status("test-request-123")
        
        assert result["data"]["status"] == "FAILED"
        assert result["data"]["error"] == "Audio file corrupted"
