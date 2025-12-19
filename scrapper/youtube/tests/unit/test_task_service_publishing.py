"""
Unit tests for YouTube TaskService result publishing functionality.

Tests the _publish_research_and_crawl_result method to ensure proper message formatting
and error handling per CrawlerResultMessage contract.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock

from application.task_service import TaskService


class TestResearchAndCrawlPublishing:
    """Test suite for TaskService research_and_crawl result publishing."""

    @pytest.fixture
    def mock_publisher(self):
        """Create a mock RabbitMQ publisher."""
        publisher = AsyncMock()
        publisher.publish_result = AsyncMock()
        return publisher

    @pytest.fixture
    def task_service(self, mock_publisher):
        """Create TaskService instance with mocked dependencies."""
        crawler_service = MagicMock()
        job_repo = AsyncMock()
        content_repo = AsyncMock()

        return TaskService(
            crawler_service=crawler_service,
            job_repo=job_repo,
            content_repo=content_repo,
            result_publisher=mock_publisher,
        )

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_success(
        self, task_service, mock_publisher
    ):
        """Test publishing a successful research_and_crawl result with flat message format."""
        job_id = "proj123-brand-0"
        result = {
            "task_type": "research_and_crawl",
            "keywords": ["iphone", "samsung"],
            "total_videos": 80,
            "total_successful": 75,
            "total_failed": 3,
            "total_skipped": 2,
            "results_by_keyword": {},
        }
        requested_limit = 100  # 50 per keyword * 2 keywords

        await task_service._publish_research_and_crawl_result(
            job_id=job_id, result=result, success=True, requested_limit=requested_limit
        )

        # Verify publish_result was called
        mock_publisher.publish_result.assert_called_once()

        # Verify the call arguments
        call_args = mock_publisher.publish_result.call_args
        assert call_args.kwargs["job_id"] == job_id
        assert call_args.kwargs["task_type"] == "research_and_crawl"

        result_data = call_args.kwargs["result_data"]

        # Verify flat message format per CrawlerResultMessage contract
        assert result_data["success"] is True
        assert result_data["task_type"] == "research_and_crawl"
        assert result_data["job_id"] == job_id
        assert result_data["platform"] == "youtube"  # YouTube platform
        assert result_data["requested_limit"] == 100
        assert result_data["applied_limit"] == 100
        assert result_data["total_found"] == 80
        assert result_data["platform_limited"] is True  # 80 < 100
        assert result_data["successful"] == 75
        assert result_data["failed"] == 3
        assert result_data["skipped"] == 2
        assert result_data["error_code"] is None
        assert result_data["error_message"] is None

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_platform_not_limited(
        self, task_service, mock_publisher
    ):
        """Test platform_limited is False when total_found >= requested_limit."""
        job_id = "proj123-brand-1"
        result = {
            "total_videos": 50,
            "total_successful": 48,
            "total_failed": 2,
            "total_skipped": 0,
        }
        requested_limit = 50

        await task_service._publish_research_and_crawl_result(
            job_id=job_id, result=result, success=True, requested_limit=requested_limit
        )

        call_args = mock_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # platform_limited should be False when total_found >= requested_limit
        assert result_data["platform_limited"] is False
        assert result_data["total_found"] == 50
        assert result_data["requested_limit"] == 50

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_error(
        self, task_service, mock_publisher
    ):
        """Test publishing a failed research_and_crawl result with error details."""
        job_id = "proj123-brand-2"
        error = Exception("YouTube API rate limited")
        result = {
            "error": str(error),
            "error_type": "rate_limit",
            "total_videos": 0,
            "total_successful": 0,
            "total_failed": 0,
            "total_skipped": 0,
        }
        requested_limit = 100

        await task_service._publish_research_and_crawl_result(
            job_id=job_id,
            result=result,
            success=False,
            requested_limit=requested_limit,
            error=error,
        )

        call_args = mock_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Verify error fields are populated
        assert result_data["success"] is False
        assert result_data["error_code"] == "RATE_LIMITED"
        assert result_data["error_message"] == "YouTube API rate limited"

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_no_publisher(self, task_service):
        """Test that publishing gracefully handles missing publisher."""
        task_service_no_pub = TaskService(
            crawler_service=MagicMock(),
            job_repo=AsyncMock(),
            content_repo=AsyncMock(),
            result_publisher=None,
        )

        job_id = "proj123-brand-3"
        result = {
            "total_videos": 10,
            "total_successful": 10,
            "total_failed": 0,
            "total_skipped": 0,
        }

        # Should not raise an exception
        await task_service_no_pub._publish_research_and_crawl_result(
            job_id=job_id, result=result, success=True, requested_limit=50
        )

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_publisher_failure(
        self, task_service, mock_publisher
    ):
        """Test that publishing handles publisher failures gracefully."""
        mock_publisher.publish_result.side_effect = Exception(
            "RabbitMQ connection failed"
        )

        job_id = "proj123-brand-4"
        result = {
            "total_videos": 10,
            "total_successful": 10,
            "total_failed": 0,
            "total_skipped": 0,
        }

        # Should not raise an exception (error is logged but not propagated)
        await task_service._publish_research_and_crawl_result(
            job_id=job_id, result=result, success=True, requested_limit=50
        )

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_error_code_mapping(
        self, task_service, mock_publisher
    ):
        """Test error code mapping for different error types."""
        test_cases = [
            ("infrastructure", None, "SEARCH_FAILED"),
            ("scraping", None, "SEARCH_FAILED"),
            ("rate_limit", None, "RATE_LIMITED"),
            ("auth", None, "AUTH_FAILED"),
            ("invalid_input", None, "INVALID_KEYWORD"),
            ("timeout", None, "TIMEOUT"),
            ("unknown", None, "UNKNOWN"),
        ]

        for error_type, exception, expected_code in test_cases:
            mock_publisher.publish_result.reset_mock()

            job_id = f"proj123-test-{error_type}"
            result = {
                "error": f"{error_type} error",
                "error_type": error_type,
                "total_videos": 0,
                "total_successful": 0,
                "total_failed": 0,
                "total_skipped": 0,
            }

            await task_service._publish_research_and_crawl_result(
                job_id=job_id,
                result=result,
                success=False,
                requested_limit=50,
                error=exception,
            )

            call_args = mock_publisher.publish_result.call_args
            result_data = call_args.kwargs["result_data"]

            assert (
                result_data["error_code"] == expected_code
            ), f"Expected {expected_code} for error_type={error_type}, got {result_data['error_code']}"

    @pytest.mark.asyncio
    async def test_publish_research_and_crawl_result_no_results(
        self, task_service, mock_publisher
    ):
        """Test publishing when no results found (keyword has no videos)."""
        job_id = "proj123-brand-5"
        result = {
            "total_videos": 0,
            "total_successful": 0,
            "total_failed": 0,
            "total_skipped": 0,
        }
        requested_limit = 50

        await task_service._publish_research_and_crawl_result(
            job_id=job_id,
            result=result,
            success=True,  # Task succeeded, just no results
            requested_limit=requested_limit,
        )

        call_args = mock_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Verify success is True (task completed, just no results)
        assert result_data["success"] is True
        assert result_data["total_found"] == 0
        assert result_data["platform_limited"] is True  # 0 < 50
        assert result_data["successful"] == 0
        assert result_data["error_code"] is None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
