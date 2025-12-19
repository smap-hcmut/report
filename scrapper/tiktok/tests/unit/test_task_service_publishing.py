"""
Unit tests for TaskService result publishing functionality.

Tests the _publish_dryrun_result method to ensure proper message formatting
and error handling.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from application.task_service import TaskService


class TestTaskServicePublishing:
    """Test suite for TaskService result publishing."""

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
    async def test_publish_dryrun_result_success(self, task_service, mock_publisher):
        """Test publishing a successful dry-run result."""
        job_id = "test-job-123"
        result = {
            "keyword": "test keyword",
            "sort_by": "relevance",
            "time_range_days": 7,
            "statistics": {
                "total_found": 100,
                "successful": 95,
                "failed": 3,
                "skipped": 2,
                "total_comments": 4750,
            },
            "crawl_results": [],  # Empty for this test
        }

        await task_service._publish_dryrun_result(job_id, result, success=True)

        # Verify publish_result was called
        mock_publisher.publish_result.assert_called_once()

        # Verify the call arguments
        call_args = mock_publisher.publish_result.call_args
        assert call_args.kwargs["job_id"] == job_id
        assert call_args.kwargs["task_type"] == "dryrun_keyword"

        result_data = call_args.kwargs["result_data"]
        assert result_data["success"] is True
        assert result_data["keyword"] == "test keyword"
        assert result_data["sort_by"] == "relevance"
        assert result_data["time_range_days"] == 7
        assert result_data["statistics"]["total_found"] == 100
        assert "timestamp" in result_data
        assert "payload" in result_data
        assert isinstance(result_data["payload"], list)

    @pytest.mark.asyncio
    async def test_publish_dryrun_result_error(self, task_service, mock_publisher):
        """Test publishing a failed dry-run result."""
        job_id = "test-job-456"
        result = {
            "error": "Connection timeout",
            "error_type": "infrastructure",
            "keyword": "test keyword",
        }

        await task_service._publish_dryrun_result(job_id, result, success=False)

        # Verify publish_result was called
        mock_publisher.publish_result.assert_called_once()

        # Verify the call arguments
        call_args = mock_publisher.publish_result.call_args
        assert call_args.kwargs["job_id"] == job_id
        assert call_args.kwargs["task_type"] == "dryrun_keyword"

        result_data = call_args.kwargs["result_data"]
        assert result_data["success"] is False
        assert result_data["error"] == "Connection timeout"
        assert result_data["error_type"] == "infrastructure"
        assert result_data["keyword"] == "test keyword"
        assert "timestamp" in result_data

    @pytest.mark.asyncio
    async def test_publish_dryrun_result_no_publisher(self, task_service):
        """Test that publishing gracefully handles missing publisher."""
        # Create task service without publisher
        task_service_no_pub = TaskService(
            crawler_service=MagicMock(),
            job_repo=AsyncMock(),
            content_repo=AsyncMock(),
            result_publisher=None,
        )

        job_id = "test-job-789"
        result = {"keyword": "test", "statistics": {}}

        # Should not raise an exception
        await task_service_no_pub._publish_dryrun_result(job_id, result, success=True)

    @pytest.mark.asyncio
    async def test_publish_dryrun_result_publisher_failure(
        self, task_service, mock_publisher
    ):
        """Test that publishing handles publisher failures gracefully."""
        # Make publisher raise an exception
        mock_publisher.publish_result.side_effect = Exception(
            "RabbitMQ connection failed"
        )

        job_id = "test-job-999"
        result = {"keyword": "test", "statistics": {}}

        # Should not raise an exception (error is logged but not propagated)
        await task_service._publish_dryrun_result(job_id, result, success=True)

    @pytest.mark.asyncio
    async def test_publish_dryrun_result_timestamp_format(
        self, task_service, mock_publisher
    ):
        """Test that timestamp is in correct ISO 8601 format."""
        job_id = "test-job-timestamp"
        result = {"keyword": "test", "statistics": {}, "crawl_results": []}

        await task_service._publish_dryrun_result(job_id, result, success=True)

        call_args = mock_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Verify timestamp format (should end with 'Z' for UTC)
        assert "timestamp" in result_data
        assert result_data["timestamp"].endswith("Z")

        # Verify it's a valid ISO 8601 timestamp
        timestamp_str = result_data["timestamp"].rstrip("Z")
        datetime.fromisoformat(timestamp_str)  # Should not raise

    @pytest.mark.asyncio
    async def test_publish_dryrun_result_with_mapped_payload(
        self, task_service, mock_publisher
    ):
        """Test that crawl results are mapped to new format in payload."""
        from unittest.mock import MagicMock
        from domain.entities import Content, Author
        from domain.enums import SourcePlatform
        from application.crawler_service import CrawlResult

        job_id = "test-job-mapping"

        # Create mock crawl result
        mock_content = MagicMock(spec=Content)
        mock_content.external_id = "video123"
        mock_content.source = SourcePlatform.TIKTOK
        mock_content.url = "https://tiktok.com/@user/video/123"
        mock_content.description = "Test video"
        mock_content.view_count = 1000
        mock_content.like_count = 100
        mock_content.comment_count = 10
        mock_content.share_count = 5
        mock_content.save_count = 2
        mock_content.duration_seconds = 30
        mock_content.tags = ["test", "video"]
        mock_content.sound_name = "Test Sound"
        mock_content.category = "Entertainment"
        mock_content.media_type = "video"
        mock_content.media_path = "/path/to/video.mp4"
        mock_content.transcription = None
        mock_content.crawled_at = datetime.utcnow()
        mock_content.published_at = datetime.utcnow()
        mock_content.updated_at = datetime.utcnow()
        mock_content.media_downloaded_at = datetime.utcnow()
        mock_content.keyword = "test keyword"
        mock_content.author_username = "testuser"

        mock_author = MagicMock(spec=Author)
        mock_author.external_id = "user123"
        mock_author.username = "testuser"
        mock_author.display_name = "Test User"
        mock_author.follower_count = 5000
        mock_author.following_count = 100
        mock_author.like_count = 10000
        mock_author.video_count = 50
        mock_author.verified = True
        mock_author.profile_url = "https://tiktok.com/@testuser"
        mock_author.extra_json = {"bio": "Test bio"}

        mock_crawl_result = MagicMock(spec=CrawlResult)
        mock_crawl_result.success = True
        mock_crawl_result.content = mock_content
        mock_crawl_result.author = mock_author
        mock_crawl_result.comments = []
        mock_crawl_result.error_message = None

        result = {
            "keyword": "test keyword",
            "sort_by": "relevance",
            "statistics": {
                "total_found": 1,
                "successful": 1,
                "failed": 0,
                "skipped": 0,
                "total_comments": 0,
            },
            "crawl_results": [mock_crawl_result],
        }

        await task_service._publish_dryrun_result(job_id, result, success=True)

        # Verify publish_result was called
        mock_publisher.publish_result.assert_called_once()

        call_args = mock_publisher.publish_result.call_args
        result_data = call_args.kwargs["result_data"]

        # Verify payload exists and contains mapped data
        assert "payload" in result_data
        assert len(result_data["payload"]) == 1

        mapped_item = result_data["payload"][0]

        # Verify structure of mapped item
        assert "meta" in mapped_item
        assert "content" in mapped_item
        assert "interaction" in mapped_item
        assert "author" in mapped_item
        assert "comments" in mapped_item

        # Verify meta section
        assert mapped_item["meta"]["id"] == "video123"
        assert mapped_item["meta"]["job_id"] == job_id
        assert mapped_item["meta"]["keyword_source"] == "test keyword"

        # Verify content section
        assert mapped_item["content"]["text"] == "Test video"
        assert mapped_item["content"]["hashtags"] == ["test", "video"]

        # Verify author section
        assert mapped_item["author"]["username"] == "testuser"
        assert mapped_item["author"]["followers"] == 5000


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
        assert result_data["platform"] == "tiktok"
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
        error = Exception("TikTok API rate limited")
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
        assert result_data["error_message"] == "TikTok API rate limited"

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
