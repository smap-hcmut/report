"""
Unit tests for Speech2TextRestClient error mapping functionality

Tests the _map_error_to_stt_result() helper method that maps exceptions
to STTResult objects with appropriate status and error information.
"""

import pytest
import httpx
from unittest.mock import Mock
from internal.infrastructure.rest_client.speech2text_rest_client import Speech2TextRestClient
from application.interfaces import STTResult


class TestErrorMapping:
    """Test suite for _map_error_to_stt_result() helper method"""

    @pytest.fixture
    def stt_client(self):
        """Create a Speech2TextRestClient instance for testing"""
        return Speech2TextRestClient(
            base_url="http://test-stt:8000",
            api_key="test-key",
            timeout=30,
            max_retries=5,
            wait_interval=1
        )

    def test_map_timeout_exception(self, stt_client):
        """Test mapping of httpx.TimeoutException to STTResult"""
        error = httpx.TimeoutException("Request timeout")
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "TIMEOUT"
        assert result.error_code == 408
        assert "timeout" in result.error_message.lower()
        assert result.transcription == ""

    def test_map_401_unauthorized(self, stt_client):
        """Test mapping of 401 Unauthorized to STTResult"""
        # Create mock response
        mock_response = Mock()
        mock_response.status_code = 401
        
        error = httpx.HTTPStatusError(
            "Unauthorized",
            request=Mock(),
            response=mock_response
        )
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "UNAUTHORIZED"
        assert result.error_code == 401
        assert "Invalid API key" in result.error_message
        assert result.transcription == ""

    def test_map_404_not_found(self, stt_client):
        """Test mapping of 404 Not Found to STTResult"""
        # Create mock response
        mock_response = Mock()
        mock_response.status_code = 404
        
        error = httpx.HTTPStatusError(
            "Not Found",
            request=Mock(),
            response=mock_response
        )
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "NOT_FOUND"
        assert result.error_code == 404
        assert request_id in result.error_message
        assert result.transcription == ""

    def test_map_500_server_error(self, stt_client):
        """Test mapping of 500 Server Error to STTResult"""
        # Create mock response
        mock_response = Mock()
        mock_response.status_code = 500
        
        error = httpx.HTTPStatusError(
            "Internal Server Error",
            request=Mock(),
            response=mock_response
        )
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "SERVER_ERROR"
        assert result.error_code == 500
        assert "Server error" in result.error_message
        assert result.transcription == ""

    def test_map_503_service_unavailable(self, stt_client):
        """Test mapping of 503 Service Unavailable to STTResult"""
        # Create mock response
        mock_response = Mock()
        mock_response.status_code = 503
        
        error = httpx.HTTPStatusError(
            "Service Unavailable",
            request=Mock(),
            response=mock_response
        )
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "SERVER_ERROR"
        assert result.error_code == 503
        assert "Server error" in result.error_message
        assert result.transcription == ""

    def test_map_generic_exception(self, stt_client):
        """Test mapping of unexpected exceptions to STTResult"""
        error = ValueError("Unexpected error occurred")
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "polling")
        
        assert result.success is False
        assert result.status == "EXCEPTION"
        assert result.error_code == -1
        assert "Unexpected error" in result.error_message
        assert "ValueError" in result.error_message or "Unexpected error occurred" in result.error_message
        assert result.transcription == ""

    def test_map_error_with_different_context(self, stt_client):
        """Test that context parameter is used in error messages"""
        error = httpx.TimeoutException("Request timeout")
        request_id = "test_request_123"
        
        result = stt_client._map_error_to_stt_result(error, request_id, "submit")
        
        assert result.success is False
        assert result.status == "TIMEOUT"
        assert "submit" in result.error_message.lower()

    def test_all_error_results_have_required_fields(self, stt_client):
        """Test that all error results have all required STTResult fields"""
        errors = [
            httpx.TimeoutException("Timeout"),
            httpx.HTTPStatusError("Unauthorized", request=Mock(), response=Mock(status_code=401)),
            httpx.HTTPStatusError("Not Found", request=Mock(), response=Mock(status_code=404)),
            httpx.HTTPStatusError("Server Error", request=Mock(), response=Mock(status_code=500)),
            ValueError("Generic error")
        ]
        
        for error in errors:
            result = stt_client._map_error_to_stt_result(error, "test_id", "test")
            
            # Verify all required fields are present
            assert hasattr(result, 'success')
            assert hasattr(result, 'transcription')
            assert hasattr(result, 'status')
            assert hasattr(result, 'error_message')
            assert hasattr(result, 'error_code')
            assert hasattr(result, 'duration')
            assert hasattr(result, 'confidence')
            assert hasattr(result, 'processing_time')
            
            # Verify error results have success=False
            assert result.success is False
            assert result.transcription == ""
            assert result.duration == 0.0
            assert result.confidence == 0.0
            assert result.processing_time == 0.0
