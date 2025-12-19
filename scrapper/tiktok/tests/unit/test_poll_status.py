"""
Unit tests for Speech2TextRestClient._poll_status() method
Tests the polling loop logic for async STT API
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from application.interfaces import STTResult
from internal.infrastructure.rest_client.speech2text_rest_client import Speech2TextRestClient


class TestPollStatus:
    """Test _poll_status() method polling logic"""

    @pytest.fixture
    def stt_client(self):
        """Create STT client with test configuration"""
        return Speech2TextRestClient(
            base_url="http://test-stt:8000",
            api_key="test-key",
            timeout=30,
            max_retries=5,
            wait_interval=1
        )

    @pytest.mark.asyncio
    async def test_poll_status_completed_immediately(self, stt_client):
        """Test polling when job completes immediately"""
        # Mock _get_job_status to return COMPLETED
        mock_response = {
            "error_code": 0,
            "message": "Transcription completed",
            "data": {
                "request_id": "test-123",
                "status": "COMPLETED",
                "transcription": "Test transcription",
                "duration": 10.5,
                "confidence": 0.95,
                "processing_time": 2.3
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.return_value = mock_response
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is True
            assert result.status == "COMPLETED"
            assert result.transcription == "Test transcription"
            assert result.duration == 10.5
            assert result.confidence == 0.95
            assert result.processing_time == 2.3
            assert mock_get_status.call_count == 1

    @pytest.mark.asyncio
    async def test_poll_status_failed_immediately(self, stt_client):
        """Test polling when job fails immediately"""
        # Mock _get_job_status to return FAILED
        mock_response = {
            "error_code": 1,
            "message": "Transcription failed",
            "data": {
                "request_id": "test-123",
                "status": "FAILED",
                "error": "Audio file corrupted"
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.return_value = mock_response
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is False
            assert result.status == "FAILED"
            assert result.error_message == "Audio file corrupted"
            assert mock_get_status.call_count == 1

    @pytest.mark.asyncio
    async def test_poll_status_processing_then_completed(self, stt_client):
        """Test polling when job is processing then completes"""
        # Mock _get_job_status to return PROCESSING twice, then COMPLETED
        processing_response = {
            "error_code": 0,
            "message": "Transcription in progress",
            "data": {
                "request_id": "test-123",
                "status": "PROCESSING"
            }
        }
        
        completed_response = {
            "error_code": 0,
            "message": "Transcription completed",
            "data": {
                "request_id": "test-123",
                "status": "COMPLETED",
                "transcription": "Test transcription",
                "duration": 10.5,
                "confidence": 0.95,
                "processing_time": 2.3
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.side_effect = [
                processing_response,
                processing_response,
                completed_response
            ]
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is True
            assert result.status == "COMPLETED"
            assert result.transcription == "Test transcription"
            assert mock_get_status.call_count == 3

    @pytest.mark.asyncio
    async def test_poll_status_timeout(self, stt_client):
        """Test polling timeout when max_retries exceeded"""
        # Mock _get_job_status to always return PROCESSING
        processing_response = {
            "error_code": 0,
            "message": "Transcription in progress",
            "data": {
                "request_id": "test-123",
                "status": "PROCESSING"
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.return_value = processing_response
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is False
            assert result.status == "TIMEOUT"
            assert "timeout" in result.error_message.lower()
            assert mock_get_status.call_count == stt_client.max_retries

    @pytest.mark.asyncio
    async def test_poll_status_not_found(self, stt_client):
        """Test polling when job not found (404)"""
        import httpx
        
        # Mock _get_job_status to raise 404 HTTPStatusError
        mock_response = MagicMock()
        mock_response.status_code = 404
        error = httpx.HTTPStatusError("Not found", request=MagicMock(), response=mock_response)
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.side_effect = error
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is False
            assert result.status == "NOT_FOUND"
            assert result.error_code == 404
            assert mock_get_status.call_count == 1

    @pytest.mark.asyncio
    async def test_poll_status_unauthorized(self, stt_client):
        """Test polling when unauthorized (401)"""
        import httpx
        
        # Mock _get_job_status to raise 401 HTTPStatusError
        mock_response = MagicMock()
        mock_response.status_code = 401
        error = httpx.HTTPStatusError("Unauthorized", request=MagicMock(), response=mock_response)
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.side_effect = error
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is False
            assert result.status == "UNAUTHORIZED"
            assert result.error_code == 401
            assert mock_get_status.call_count == 1

    @pytest.mark.asyncio
    async def test_poll_status_server_error_then_success(self, stt_client):
        """Test polling continues after 5xx server error"""
        import httpx
        
        # Mock _get_job_status to raise 500 error, then return COMPLETED
        mock_response = MagicMock()
        mock_response.status_code = 500
        error = httpx.HTTPStatusError("Server error", request=MagicMock(), response=mock_response)
        
        completed_response = {
            "error_code": 0,
            "message": "Transcription completed",
            "data": {
                "request_id": "test-123",
                "status": "COMPLETED",
                "transcription": "Test transcription",
                "duration": 10.5,
                "confidence": 0.95,
                "processing_time": 2.3
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.side_effect = [error, completed_response]
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is True
            assert result.status == "COMPLETED"
            assert mock_get_status.call_count == 2

    @pytest.mark.asyncio
    async def test_poll_status_network_timeout_then_success(self, stt_client):
        """Test polling continues after network timeout"""
        import httpx
        
        # Mock _get_job_status to raise TimeoutException, then return COMPLETED
        timeout_error = httpx.TimeoutException("Request timeout")
        
        completed_response = {
            "error_code": 0,
            "message": "Transcription completed",
            "data": {
                "request_id": "test-123",
                "status": "COMPLETED",
                "transcription": "Test transcription",
                "duration": 10.5,
                "confidence": 0.95,
                "processing_time": 2.3
            }
        }
        
        with patch.object(stt_client, '_get_job_status', new_callable=AsyncMock) as mock_get_status:
            mock_get_status.side_effect = [timeout_error, completed_response]
            
            result = await stt_client._poll_status("test-123")
            
            assert result.success is True
            assert result.status == "COMPLETED"
            assert mock_get_status.call_count == 2
