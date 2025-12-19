"""
Unit tests for STTResult dataclass
Tests the updated STTResult with async API status support
"""

import pytest
from application.interfaces import STTResult


class TestSTTResultDataclass:
    """Test STTResult dataclass structure and fields"""

    def test_stt_result_all_fields_present(self):
        """Test that STTResult has all required fields"""
        result = STTResult(
            success=True,
            transcription="Test transcription",
            status="COMPLETED",
            error_message="",
            error_code=0,
            duration=10.5,
            confidence=0.95,
            processing_time=2.3
        )
        
        assert result.success is True
        assert result.transcription == "Test transcription"
        assert result.status == "COMPLETED"
        assert result.error_message == ""
        assert result.error_code == 0
        assert result.duration == 10.5
        assert result.confidence == 0.95
        assert result.processing_time == 2.3

    def test_stt_result_default_values(self):
        """Test that STTResult has correct default values"""
        result = STTResult(success=False)
        
        assert result.success is False
        assert result.transcription == ""
        assert result.status == "PENDING"
        assert result.error_message == ""
        assert result.error_code == 0
        assert result.duration == 0.0
        assert result.confidence == 0.0
        assert result.processing_time == 0.0

    def test_stt_result_processing_status(self):
        """Test STTResult with PROCESSING status"""
        result = STTResult(
            success=False,
            status="PROCESSING"
        )
        
        assert result.success is False
        assert result.status == "PROCESSING"

    def test_stt_result_completed_status(self):
        """Test STTResult with COMPLETED status"""
        result = STTResult(
            success=True,
            transcription="Completed transcription",
            status="COMPLETED"
        )
        
        assert result.success is True
        assert result.status == "COMPLETED"
        assert result.transcription == "Completed transcription"

    def test_stt_result_failed_status(self):
        """Test STTResult with FAILED status"""
        result = STTResult(
            success=False,
            status="FAILED",
            error_message="Transcription failed"
        )
        
        assert result.success is False
        assert result.status == "FAILED"
        assert result.error_message == "Transcription failed"

    def test_stt_result_not_found_status(self):
        """Test STTResult with NOT_FOUND status"""
        result = STTResult(
            success=False,
            status="NOT_FOUND",
            error_message="Job not found",
            error_code=404
        )
        
        assert result.success is False
        assert result.status == "NOT_FOUND"
        assert result.error_code == 404

    def test_stt_result_timeout_status(self):
        """Test STTResult with TIMEOUT status"""
        result = STTResult(
            success=False,
            status="TIMEOUT",
            error_message="Polling timeout"
        )
        
        assert result.success is False
        assert result.status == "TIMEOUT"

    def test_stt_result_unauthorized_status(self):
        """Test STTResult with UNAUTHORIZED status"""
        result = STTResult(
            success=False,
            status="UNAUTHORIZED",
            error_message="Invalid API key",
            error_code=401
        )
        
        assert result.success is False
        assert result.status == "UNAUTHORIZED"
        assert result.error_code == 401

    def test_stt_result_exception_status(self):
        """Test STTResult with EXCEPTION status"""
        result = STTResult(
            success=False,
            status="EXCEPTION",
            error_message="Unexpected error occurred"
        )
        
        assert result.success is False
        assert result.status == "EXCEPTION"

    def test_stt_result_backward_compatibility_success(self):
        """Test backward compatibility with legacy SUCCESS status"""
        result = STTResult(
            success=True,
            transcription="Legacy transcription",
            status="SUCCESS"
        )
        
        assert result.success is True
        assert result.status == "SUCCESS"
        assert result.transcription == "Legacy transcription"

    def test_stt_result_backward_compatibility_error(self):
        """Test backward compatibility with legacy ERROR status"""
        result = STTResult(
            success=False,
            status="ERROR",
            error_message="Legacy error"
        )
        
        assert result.success is False
        assert result.status == "ERROR"
        assert result.error_message == "Legacy error"

    def test_stt_result_optional_fields_none(self):
        """Test that optional fields can be None"""
        result = STTResult(
            success=False,
            transcription=None,
            status=None,
            error_message=None,
            error_code=None,
            duration=None,
            confidence=None,
            processing_time=None
        )
        
        assert result.success is False
        assert result.transcription is None
        assert result.status is None
        assert result.error_message is None
        assert result.error_code is None
        assert result.duration is None
        assert result.confidence is None
        assert result.processing_time is None
