"""
Test backward compatibility of STTResult with existing code
Ensures that existing usage patterns still work after adding async API status support
"""

import pytest
from application.interfaces import STTResult


class TestSTTResultBackwardCompatibility:
    """Test that existing code patterns still work with updated STTResult"""

    def test_existing_success_pattern(self):
        """Test the existing success pattern used in speech2text_rest_client.py"""
        # This is how the existing code creates a success result
        result = STTResult(
            success=True,
            transcription="Test transcription text",
            status="SUCCESS",
            error_message="",
            error_code=0,
            duration=10.5,
            confidence=0.95,
            processing_time=2.3
        )
        
        # Verify the pattern used in crawler_service.py works
        assert result.success is True
        assert result.transcription == "Test transcription text"
        assert result.status == "SUCCESS"
        
    def test_existing_error_pattern(self):
        """Test the existing error pattern used in speech2text_rest_client.py"""
        # This is how the existing code creates an error result
        result = STTResult(
            success=False,
            transcription="",
            status="ERROR",
            error_message="Transcription failed",
            error_code=500,
            duration=0.0,
            confidence=0.0,
            processing_time=0.0
        )
        
        # Verify the pattern used in crawler_service.py works
        assert result.success is False
        assert result.error_message == "Transcription failed"
        assert result.status == "ERROR"
        
    def test_existing_timeout_pattern(self):
        """Test the existing timeout pattern used in speech2text_rest_client.py"""
        result = STTResult(
            success=False,
            status="TIMEOUT",
            error_message="HTTP request timeout after 300s",
            error_code=-1
        )
        
        assert result.success is False
        assert result.status == "TIMEOUT"
        assert "timeout" in result.error_message.lower()
        
    def test_existing_http_error_pattern(self):
        """Test the existing HTTP error pattern used in speech2text_rest_client.py"""
        result = STTResult(
            success=False,
            status="HTTP_ERROR",
            error_message="Invalid JSON response",
            error_code=-1
        )
        
        assert result.success is False
        assert result.status == "HTTP_ERROR"
        
    def test_existing_exception_pattern(self):
        """Test the existing exception pattern used in speech2text_rest_client.py"""
        result = STTResult(
            success=False,
            status="EXCEPTION",
            error_message="Unexpected error occurred",
            error_code=-1
        )
        
        assert result.success is False
        assert result.status == "EXCEPTION"
        
    def test_crawler_service_success_check(self):
        """Test the pattern used in crawler_service.py for checking success"""
        # Simulate successful transcription
        stt_result = STTResult(
            success=True,
            transcription="Transcribed text",
            status="SUCCESS"
        )
        
        # This is the pattern used in crawler_service.py
        if stt_result.success:
            transcription = stt_result.transcription
            transcription_error = None
        else:
            transcription = None
            transcription_error = stt_result.error_message
            
        assert transcription == "Transcribed text"
        assert transcription_error is None
        
    def test_crawler_service_failure_check(self):
        """Test the pattern used in crawler_service.py for checking failure"""
        # Simulate failed transcription
        stt_result = STTResult(
            success=False,
            status="ERROR",
            error_message="API error occurred"
        )
        
        # This is the pattern used in crawler_service.py
        if stt_result.success:
            transcription = stt_result.transcription
            transcription_error = None
        else:
            transcription = None
            transcription_error = stt_result.error_message
            
        assert transcription is None
        assert transcription_error == "API error occurred"
        
    def test_status_field_access(self):
        """Test that status field can be accessed as used in crawler_service.py"""
        result = STTResult(
            success=True,
            status="COMPLETED"
        )
        
        # This is used in crawler_service.py: content.transcription_status = stt_result.status
        transcription_status = result.status
        assert transcription_status == "COMPLETED"
