"""
Unit tests for new response format in _publish_dryrun_result().

Tests:
- Success case with all fields (task_type, limit_info, stats, payload)
- Failure case with error object
- No results case (platform_limited)
"""

import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from dataclasses import dataclass
from typing import Optional


@dataclass
class MockContent:
    """Mock content object for testing."""

    external_id: str = "test_video_123"
    keyword: Optional[str] = "test keyword"


@dataclass
class MockCrawlResult:
    """Mock crawl result for testing."""

    success: bool = True
    content: Optional[MockContent] = None
    minio_key: Optional[str] = None
    skipped: bool = False

    def __post_init__(self):
        if self.content is None:
            self.content = MockContent()


class TestPublishDryrunResultFormat:
    """Test suite for _publish_dryrun_result() response format."""

    @pytest.fixture
    def task_service(self):
        """Create a TaskService instance with mocked dependencies."""
        from application.task_service import TaskService

        crawler_service = MagicMock()
        job_repo = MagicMock()
        content_repo = MagicMock()
        result_publisher = AsyncMock()

        return TaskService(
            crawler_service=crawler_service,
            job_repo=job_repo,
            content_repo=content_repo,
            result_publisher=result_publisher,
        )

    @pytest.mark.asyncio
    async def test_success_response_has_all_required_fields(self, task_service):
        """Test that success response includes task_type, limit_info, stats, payload."""
        # Arrange
        job_id = "test_job_123"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["test keyword"],
            "crawl_results": [],  # Empty to avoid map_to_new_format call
            "total_videos": 10,
            "total_successful": 8,
            "total_failed": 1,
            "total_skipped": 1,
            "limit": 50,
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check root level fields
        assert result_data["success"] is True
        assert result_data["task_type"] == "dryrun_keyword"

        # Check limit_info object
        assert "limit_info" in result_data
        limit_info = result_data["limit_info"]
        assert "requested_limit" in limit_info
        assert "applied_limit" in limit_info
        assert "total_found" in limit_info
        assert "platform_limited" in limit_info

        # Check stats object
        assert "stats" in result_data
        stats = result_data["stats"]
        assert "successful" in stats
        assert "failed" in stats
        assert "skipped" in stats
        assert "completion_rate" in stats

        # Check payload
        assert "payload" in result_data
        assert isinstance(result_data["payload"], list)

    @pytest.mark.asyncio
    async def test_failure_response_has_error_object(self, task_service):
        """Test that failure response includes error object with code and message."""
        # Arrange
        job_id = "test_job_456"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["test keyword"],
            "crawl_results": [],
            "total_videos": 0,
            "total_successful": 0,
            "total_failed": 0,
            "total_skipped": 0,
            "limit": 50,
            "error_type": "rate_limit",
            "error": "Rate limit exceeded",
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=False
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check success is False
        assert result_data["success"] is False

        # Check error object
        assert "error" in result_data
        error = result_data["error"]
        assert "code" in error
        assert "message" in error
        assert error["code"] == "RATE_LIMITED"
        assert error["message"] == "Rate limit exceeded"

        # Check payload is empty
        assert result_data["payload"] == []

    @pytest.mark.asyncio
    async def test_platform_limited_when_results_less_than_limit(self, task_service):
        """Test platform_limited is True when total_found < requested_limit."""
        # Arrange
        job_id = "test_job_789"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["rare keyword"],
            "crawl_results": [],
            "total_videos": 5,  # Less than limit
            "total_successful": 5,
            "total_failed": 0,
            "total_skipped": 0,
            "limit": 50,  # Requested 50 but only got 5
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check platform_limited is True
        assert result_data["limit_info"]["platform_limited"] is True
        assert result_data["limit_info"]["total_found"] == 5
        assert result_data["limit_info"]["requested_limit"] == 50

    @pytest.mark.asyncio
    async def test_platform_not_limited_when_results_equal_limit(self, task_service):
        """Test platform_limited is False when total_found >= requested_limit."""
        # Arrange
        job_id = "test_job_101"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["popular keyword"],
            "crawl_results": [],
            "total_videos": 50,  # Equal to limit
            "total_successful": 48,
            "total_failed": 2,
            "total_skipped": 0,
            "limit": 50,
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check platform_limited is False
        assert result_data["limit_info"]["platform_limited"] is False

    @pytest.mark.asyncio
    async def test_completion_rate_calculation(self, task_service):
        """Test completion_rate is calculated correctly."""
        # Arrange
        job_id = "test_job_102"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["test"],
            "crawl_results": [],
            "total_videos": 100,
            "total_successful": 93,
            "total_failed": 5,
            "total_skipped": 2,
            "limit": 100,
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check completion_rate = 93/100 = 0.93
        assert result_data["stats"]["completion_rate"] == 0.93

    @pytest.mark.asyncio
    async def test_completion_rate_zero_when_no_videos(self, task_service):
        """Test completion_rate is 0 when total_videos is 0."""
        # Arrange
        job_id = "test_job_103"
        result = {
            "task_type": "dryrun_keyword",
            "keywords": ["nonexistent keyword"],
            "crawl_results": [],
            "total_videos": 0,
            "total_successful": 0,
            "total_failed": 0,
            "total_skipped": 0,
            "limit": 50,
        }

        # Act
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # Assert
        call_args = task_service.result_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Check completion_rate is 0.0 (not division by zero)
        assert result_data["stats"]["completion_rate"] == 0.0

    @pytest.mark.asyncio
    async def test_no_publisher_logs_warning(self, task_service):
        """Test that missing publisher logs warning and doesn't fail."""
        # Arrange
        task_service.result_publisher = None
        job_id = "test_job_104"
        result = {"total_videos": 10, "limit": 50}

        # Act - should not raise
        await task_service._publish_dryrun_result(
            job_id=job_id, result=result, success=True
        )

        # No assertion needed - just verify no exception


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
