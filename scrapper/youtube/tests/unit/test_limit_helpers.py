"""
Unit tests for TaskService limit helper methods.

Tests:
- _get_limit() - Validate and cap limit from payload
- _map_error_code() - Map internal error types to standard codes
"""

import pytest
from unittest.mock import MagicMock, patch


class TestGetLimit:
    """Test suite for _get_limit() helper method."""

    @pytest.fixture
    def task_service(self):
        """Create a TaskService instance with mocked dependencies."""
        from application.task_service import TaskService

        # Mock all dependencies
        crawler_service = MagicMock()
        job_repo = MagicMock()
        content_repo = MagicMock()

        return TaskService(
            crawler_service=crawler_service,
            job_repo=job_repo,
            content_repo=content_repo,
        )

    def test_returns_payload_value_when_valid(self, task_service):
        """Test that valid limit from payload is returned."""
        payload = {"limit": 100}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 100

    def test_returns_default_when_not_provided(self, task_service):
        """Test that default is returned when limit not in payload."""
        payload = {}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 50

    def test_returns_default_when_none(self, task_service):
        """Test that default is returned when limit is None."""
        payload = {"limit": None}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 50

    def test_returns_default_when_zero(self, task_service):
        """Test that default is returned when limit is 0."""
        payload = {"limit": 0}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 50

    def test_returns_default_when_negative(self, task_service):
        """Test that default is returned when limit is negative."""
        payload = {"limit": -10}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 50

    def test_caps_at_max_limit(self, task_service):
        """Test that limit is capped at max_limit."""
        payload = {"limit": 1000}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 500

    def test_returns_max_when_exactly_at_max(self, task_service):
        """Test that max_limit is returned when limit equals max."""
        payload = {"limit": 500}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 500

    def test_handles_string_value(self, task_service):
        """Test that string values are converted to int."""
        payload = {"limit": "100"}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 100

    def test_handles_invalid_string_value(self, task_service):
        """Test that invalid string values return default."""
        payload = {"limit": "invalid"}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 50

    def test_different_key_names(self, task_service):
        """Test with different key names like limit_per_keyword."""
        payload = {"limit_per_keyword": 75}
        result = task_service._get_limit(
            payload, "limit_per_keyword", default=50, max_limit=500
        )
        assert result == 75

    def test_boundary_value_one(self, task_service):
        """Test boundary value of 1 (minimum valid)."""
        payload = {"limit": 1}
        result = task_service._get_limit(payload, "limit", default=50, max_limit=500)
        assert result == 1


class TestMapErrorCode:
    """Test suite for _map_error_code() helper method."""

    @pytest.fixture
    def task_service(self):
        """Create a TaskService instance with mocked dependencies."""
        from application.task_service import TaskService

        crawler_service = MagicMock()
        job_repo = MagicMock()
        content_repo = MagicMock()

        return TaskService(
            crawler_service=crawler_service,
            job_repo=job_repo,
            content_repo=content_repo,
        )

    def test_infrastructure_maps_to_search_failed(self, task_service):
        """Test that infrastructure error type maps to SEARCH_FAILED."""
        result = task_service._map_error_code("infrastructure")
        assert result == "SEARCH_FAILED"

    def test_scraping_maps_to_search_failed(self, task_service):
        """Test that scraping error type maps to SEARCH_FAILED."""
        result = task_service._map_error_code("scraping")
        assert result == "SEARCH_FAILED"

    def test_rate_limit_maps_to_rate_limited(self, task_service):
        """Test that rate_limit error type maps to RATE_LIMITED."""
        result = task_service._map_error_code("rate_limit")
        assert result == "RATE_LIMITED"

    def test_auth_maps_to_auth_failed(self, task_service):
        """Test that auth error type maps to AUTH_FAILED."""
        result = task_service._map_error_code("auth")
        assert result == "AUTH_FAILED"

    def test_invalid_input_maps_to_invalid_keyword(self, task_service):
        """Test that invalid_input error type maps to INVALID_KEYWORD."""
        result = task_service._map_error_code("invalid_input")
        assert result == "INVALID_KEYWORD"

    def test_timeout_maps_to_timeout(self, task_service):
        """Test that timeout error type maps to TIMEOUT."""
        result = task_service._map_error_code("timeout")
        assert result == "TIMEOUT"

    def test_unknown_type_maps_to_unknown(self, task_service):
        """Test that unknown error type maps to UNKNOWN."""
        result = task_service._map_error_code("some_unknown_type")
        assert result == "UNKNOWN"

    def test_exception_with_rate_limit_message(self, task_service):
        """Test that exception with rate limit message returns RATE_LIMITED."""
        exception = Exception("Rate limit exceeded, please try again later")
        result = task_service._map_error_code("scraping", exception)
        assert result == "RATE_LIMITED"

    def test_exception_with_429_status(self, task_service):
        """Test that exception with 429 status returns RATE_LIMITED."""
        exception = Exception("HTTP 429 Too Many Requests")
        result = task_service._map_error_code("scraping", exception)
        assert result == "RATE_LIMITED"

    def test_exception_with_auth_message(self, task_service):
        """Test that exception with auth message returns AUTH_FAILED."""
        exception = Exception("Unauthorized access denied")
        result = task_service._map_error_code("scraping", exception)
        assert result == "AUTH_FAILED"

    def test_exception_with_401_status(self, task_service):
        """Test that exception with 401 status returns AUTH_FAILED."""
        exception = Exception("HTTP 401 Unauthorized")
        result = task_service._map_error_code("scraping", exception)
        assert result == "AUTH_FAILED"

    def test_exception_with_403_status(self, task_service):
        """Test that exception with 403 status returns AUTH_FAILED."""
        exception = Exception("HTTP 403 Forbidden")
        result = task_service._map_error_code("scraping", exception)
        assert result == "AUTH_FAILED"

    def test_exception_with_timeout_message(self, task_service):
        """Test that exception with timeout message returns TIMEOUT."""
        exception = Exception("Request timed out after 30 seconds")
        result = task_service._map_error_code("scraping", exception)
        assert result == "TIMEOUT"

    def test_exception_with_invalid_keyword_message(self, task_service):
        """Test that exception with invalid keyword message returns INVALID_KEYWORD."""
        exception = Exception("Invalid keyword provided")
        result = task_service._map_error_code("scraping", exception)
        assert result == "INVALID_KEYWORD"

    def test_none_exception_uses_error_type(self, task_service):
        """Test that None exception falls back to error_type mapping."""
        result = task_service._map_error_code("infrastructure", None)
        assert result == "SEARCH_FAILED"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
