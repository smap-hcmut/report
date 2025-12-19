"""
Unit tests for YouTube TaskService handler batch upload integration.

**Feature: fix-batch-upload-event**

Tests that each handler calls _process_crawl_results_with_batch() correctly.
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import pytest
from unittest.mock import AsyncMock, MagicMock


class TestHandlerBatchIntegration:
    """Test suite for handler batch upload integration."""

    @pytest.fixture
    def mock_crawler_service(self):
        """Create a mock CrawlerService."""
        service = MagicMock()
        service.search_and_fetch = AsyncMock()
        service.fetch_videos_batch = AsyncMock()
        service.fetch_channel_videos = AsyncMock()
        service.add_to_batch = AsyncMock(return_value=None)
        service.flush_batch = AsyncMock(return_value="path/batch.json")
        service.clear_batch_state = MagicMock()
        return service

    @pytest.fixture
    def mock_job_repo(self):
        """Create a mock job repository."""
        repo = AsyncMock()
        repo.create_job = AsyncMock(return_value=True)
        repo.update_job_status = AsyncMock(return_value=True)
        repo.update_job_results = AsyncMock(return_value=True)
        return repo

    @pytest.fixture
    def mock_crawl_result(self):
        """Create a mock successful CrawlResult."""
        result = MagicMock()
        result.success = True
        result.minio_key = "test/key.json"
        result.skipped = False
        content = MagicMock()
        content.external_id = "dQw4w9WgXcQ"
        result.content = content
        return result

    @pytest.fixture
    def task_service(self, mock_crawler_service, mock_job_repo):
        """Create TaskService with mocked dependencies."""
        from application.task_service import TaskService

        return TaskService(
            crawler_service=mock_crawler_service,
            job_repo=mock_job_repo,
            content_repo=AsyncMock(),
            search_session_repo=AsyncMock(),
            result_publisher=None,
        )

    @pytest.mark.asyncio
    async def test_handle_research_and_crawl_calls_batch_processing(
        self, task_service, mock_crawler_service, mock_crawl_result
    ):
        """
        Test that _handle_research_and_crawl() calls batch processing for each keyword.

        **Validates: Requirements 4.1**
        """
        # Setup mock return value
        mock_crawler_service.search_and_fetch.return_value = {
            "video_urls": ["url1", "url2"],
            "total": 2,
            "successful": 2,
            "failed": 0,
            "skipped": 0,
            "crawl_results": [mock_crawl_result, mock_crawl_result],
        }

        # Call handler
        payload = {"keywords": ["test_keyword"]}
        result = await task_service._handle_research_and_crawl(
            payload=payload, job_id="test-job-123"
        )

        # Verify batch methods were called
        assert mock_crawler_service.add_to_batch.call_count == 2
        mock_crawler_service.flush_batch.assert_called_once()
        mock_crawler_service.clear_batch_state.assert_called_once_with("test-job-123")

    @pytest.mark.asyncio
    async def test_handle_crawl_links_calls_batch_processing(
        self, task_service, mock_crawler_service, mock_crawl_result
    ):
        """
        Test that _handle_crawl_links() calls batch processing.

        **Validates: Requirements 4.2**
        """
        # Setup mock return value
        mock_crawler_service.fetch_videos_batch.return_value = [
            mock_crawl_result,
            mock_crawl_result,
        ]

        # Call handler
        payload = {"video_urls": ["url1", "url2"]}
        result = await task_service._handle_crawl_links(
            payload=payload, job_id="test-job-456"
        )

        # Verify batch methods were called
        assert mock_crawler_service.add_to_batch.call_count == 2
        mock_crawler_service.flush_batch.assert_called_once()
        mock_crawler_service.clear_batch_state.assert_called_once_with("test-job-456")

    @pytest.mark.asyncio
    async def test_handle_fetch_channel_content_calls_batch_processing(
        self, task_service, mock_crawler_service, mock_crawl_result
    ):
        """
        Test that _handle_fetch_channel_content() calls batch processing.

        **Validates: Requirements 4.3**
        """
        # Setup mock return value
        mock_crawler_service.fetch_channel_videos.return_value = {
            "video_urls": ["url1", "url2"],
            "total": 2,
            "crawl_results": [mock_crawl_result, mock_crawl_result],
        }

        # Call handler
        payload = {"channel_url": "https://youtube.com/@testchannel"}
        result = await task_service._handle_fetch_channel_content(
            payload=payload, job_id="test-job-789"
        )

        # Verify batch methods were called
        assert mock_crawler_service.add_to_batch.call_count == 2
        mock_crawler_service.flush_batch.assert_called_once()
        mock_crawler_service.clear_batch_state.assert_called_once_with("test-job-789")

    @pytest.mark.asyncio
    async def test_handler_skips_batch_when_no_results(
        self, task_service, mock_crawler_service
    ):
        """Test that handlers skip batch processing when there are no crawl results."""
        # Setup mock return value with empty results
        mock_crawler_service.search_and_fetch.return_value = {
            "video_urls": [],
            "total": 0,
            "successful": 0,
            "failed": 0,
            "skipped": 0,
            "crawl_results": [],
        }

        # Call handler
        payload = {"keywords": ["test_keyword"]}
        result = await task_service._handle_research_and_crawl(
            payload=payload, job_id="test-job-empty"
        )

        # Verify batch methods were NOT called (no results to process)
        mock_crawler_service.add_to_batch.assert_not_called()
        mock_crawler_service.flush_batch.assert_not_called()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
