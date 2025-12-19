"""
Integration tests for TikTok batch upload functionality.

Tests:
- Batch accumulation logic
- MinIO upload path format
- data.collected event schema
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json
from datetime import datetime, timezone


class TestBatchAccumulation:
    """Test suite for batch accumulation in CrawlerService."""

    @pytest.fixture
    def mock_storage(self):
        """Create a mock storage service."""
        storage = AsyncMock()
        storage.upload_bytes = AsyncMock(
            return_value="crawl-results/tiktok/proj123/brand/batch_000.json"
        )
        return storage

    @pytest.fixture
    def mock_event_publisher(self):
        """Create a mock event publisher."""
        publisher = AsyncMock()
        publisher.is_connected = True
        publisher.publish_data_collected = AsyncMock()
        return publisher

    @pytest.fixture
    def mock_crawl_result(self):
        """Create a mock CrawlResult."""
        content = MagicMock()
        content.external_id = "video123"
        content.source = "tiktok"
        content.url = "https://tiktok.com/@user/video/123"
        content.description = "Test video"
        content.view_count = 1000
        content.like_count = 100
        content.comment_count = 10
        content.share_count = 5
        content.save_count = 2
        content.duration_seconds = 30
        content.tags = ["test"]
        content.sound_name = "Sound"
        content.category = "Entertainment"
        content.media_type = None
        content.media_path = None
        content.media_downloaded_at = None
        content.transcription = None
        content.transcription_status = None
        content.transcription_error = None
        content.crawled_at = datetime.now(timezone.utc)
        content.published_at = datetime.now(timezone.utc)
        content.updated_at = datetime.now(timezone.utc)
        content.keyword = "test"
        content.author_username = "testuser"

        result = MagicMock()
        result.success = True
        result.content = content
        result.author = None
        result.comments = []
        result.error_message = None
        return result

    @pytest.fixture
    def crawler_service(self, mock_storage, mock_event_publisher):
        """Create a CrawlerService with mocked dependencies."""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)
        return service

    @pytest.mark.asyncio
    async def test_batch_accumulates_items(self, crawler_service, mock_crawl_result):
        """Test that items are accumulated in batch buffer."""
        job_id = "proj123-brand-0"

        # Add items but don't reach batch size
        for i in range(3):
            await crawler_service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=50,  # TikTok default
            )

        # Verify items are in buffer
        assert job_id in crawler_service._batch_buffer
        assert len(crawler_service._batch_buffer[job_id]) == 3

    @pytest.mark.asyncio
    async def test_batch_uploads_when_full(
        self, crawler_service, mock_crawl_result, mock_storage
    ):
        """Test that batch uploads when reaching batch_size."""
        job_id = "proj123-brand-0"
        batch_size = 5  # Small batch for testing

        # Add items to fill batch
        for i in range(batch_size):
            await crawler_service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=batch_size,
            )

        # Verify upload was called
        mock_storage.upload_bytes.assert_called_once()

        # Verify buffer is cleared after upload
        assert len(crawler_service._batch_buffer.get(job_id, [])) == 0

    @pytest.mark.asyncio
    async def test_flush_batch_uploads_remaining(
        self, crawler_service, mock_crawl_result, mock_storage
    ):
        """Test that flush_batch uploads remaining items."""
        job_id = "proj123-brand-0"

        # Add some items (less than batch_size)
        for i in range(3):
            await crawler_service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=50,
            )

        # Flush remaining items
        await crawler_service.flush_batch(
            job_id, keyword="test", task_type="research_and_crawl"
        )

        # Verify upload was called
        mock_storage.upload_bytes.assert_called_once()

    @pytest.mark.asyncio
    async def test_clear_batch_state(self, crawler_service, mock_crawl_result):
        """Test that clear_batch_state removes job from buffers."""
        job_id = "proj123-brand-0"

        # Add some items
        await crawler_service.add_to_batch(
            job_id=job_id,
            result=mock_crawl_result,
            keyword="test",
            task_type="research_and_crawl",
            batch_size=50,
        )

        # Clear state
        crawler_service.clear_batch_state(job_id)

        # Verify job is removed
        assert job_id not in crawler_service._batch_buffer
        assert job_id not in crawler_service._batch_index


class TestMinIOUploadPath:
    """Test suite for MinIO upload path format."""

    @pytest.fixture
    def mock_storage(self):
        """Create a mock storage service that captures upload path."""
        storage = AsyncMock()
        storage.upload_bytes = AsyncMock(return_value="mocked-path")
        return storage

    @pytest.fixture
    def mock_event_publisher(self):
        """Create a mock event publisher."""
        publisher = AsyncMock()
        publisher.is_connected = True
        publisher.publish_data_collected = AsyncMock()
        return publisher

    @pytest.fixture
    def mock_crawl_result(self):
        """Create a mock CrawlResult."""
        content = MagicMock()
        content.external_id = "video123"
        content.source = "tiktok"
        content.url = "https://tiktok.com/@user/video/123"
        content.description = "Test"
        content.view_count = 1000
        content.like_count = 100
        content.comment_count = 10
        content.share_count = 5
        content.save_count = 2
        content.duration_seconds = 30
        content.tags = []
        content.sound_name = None
        content.category = None
        content.media_type = None
        content.media_path = None
        content.media_downloaded_at = None
        content.transcription = None
        content.transcription_status = None
        content.transcription_error = None
        content.crawled_at = datetime.now(timezone.utc)
        content.published_at = datetime.now(timezone.utc)
        content.updated_at = datetime.now(timezone.utc)
        content.keyword = "test"
        content.author_username = "user"

        result = MagicMock()
        result.success = True
        result.content = content
        result.author = None
        result.comments = []
        result.error_message = None
        return result

    @pytest.mark.asyncio
    async def test_upload_path_format_brand(
        self, mock_storage, mock_event_publisher, mock_crawl_result
    ):
        """Test MinIO path format for brand jobs: {project_id}/brand/batch_{index:03d}.json"""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)

        job_id = "proj_abc123-brand-0"

        # Fill batch to trigger upload
        for i in range(5):
            await service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=5,
            )

        # Get the upload call arguments
        call_args = mock_storage.upload_bytes.call_args
        object_name = call_args.kwargs.get("object_name")

        # Verify path format
        assert "proj_abc123" in object_name
        assert "brand" in object_name
        assert "batch_000.json" in object_name

    @pytest.mark.asyncio
    async def test_upload_path_format_competitor(
        self, mock_storage, mock_event_publisher, mock_crawl_result
    ):
        """Test MinIO path format for competitor jobs."""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)

        job_id = "proj_abc123-competitor_name-0"

        # Fill batch to trigger upload
        for i in range(5):
            await service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=5,
            )

        # Get the upload call arguments
        call_args = mock_storage.upload_bytes.call_args
        object_name = call_args.kwargs.get("object_name")

        # Verify path contains competitor subfolder
        assert "competitor" in object_name


class TestDataCollectedEvent:
    """Test suite for data.collected event schema."""

    @pytest.fixture
    def mock_storage(self):
        """Create a mock storage service."""
        storage = AsyncMock()
        storage.upload_bytes = AsyncMock(
            return_value="crawl-results/tiktok/proj123/brand/batch_000.json"
        )
        return storage

    @pytest.fixture
    def mock_event_publisher(self):
        """Create a mock event publisher."""
        publisher = AsyncMock()
        publisher.is_connected = True
        publisher.publish_data_collected = AsyncMock()
        return publisher

    @pytest.fixture
    def mock_crawl_result(self):
        """Create a mock CrawlResult."""
        content = MagicMock()
        content.external_id = "video123"
        content.source = "tiktok"
        content.url = "https://tiktok.com/@user/video/123"
        content.description = "Test"
        content.view_count = 1000
        content.like_count = 100
        content.comment_count = 10
        content.share_count = 5
        content.save_count = 2
        content.duration_seconds = 30
        content.tags = []
        content.sound_name = None
        content.category = None
        content.media_type = None
        content.media_path = None
        content.media_downloaded_at = None
        content.transcription = None
        content.transcription_status = None
        content.transcription_error = None
        content.crawled_at = datetime.now(timezone.utc)
        content.published_at = datetime.now(timezone.utc)
        content.updated_at = datetime.now(timezone.utc)
        content.keyword = "test"
        content.author_username = "user"

        result = MagicMock()
        result.success = True
        result.content = content
        result.author = None
        result.comments = []
        result.error_message = None
        return result

    @pytest.mark.asyncio
    async def test_event_published_after_batch_upload(
        self, mock_storage, mock_event_publisher, mock_crawl_result
    ):
        """Test that data.collected event is published after batch upload."""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)

        job_id = "proj_abc123-brand-0"

        # Fill batch to trigger upload
        for i in range(5):
            await service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=5,
            )

        # Verify event was published
        mock_event_publisher.publish_data_collected.assert_called_once()

    @pytest.mark.asyncio
    async def test_event_contains_required_fields(
        self, mock_storage, mock_event_publisher, mock_crawl_result
    ):
        """Test that data.collected event contains all required fields."""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)

        # Use valid UUID format for project_id extraction
        project_id = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
        job_id = f"{project_id}-brand-0"

        # Fill batch to trigger upload
        for i in range(5):
            await service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test",
                task_type="research_and_crawl",
                batch_size=5,
            )

        # Get the event call arguments
        call_args = mock_event_publisher.publish_data_collected.call_args

        # Verify required fields
        assert "project_id" in call_args.kwargs
        assert "job_id" in call_args.kwargs
        assert "platform" in call_args.kwargs
        assert "minio_path" in call_args.kwargs
        assert "content_count" in call_args.kwargs
        assert "batch_index" in call_args.kwargs

        # Verify values
        assert call_args.kwargs["project_id"] == project_id
        assert call_args.kwargs["job_id"] == job_id
        assert call_args.kwargs["platform"] == "tiktok"
        assert call_args.kwargs["content_count"] == 5
        assert call_args.kwargs["batch_index"] == 1  # 1-based for external consumers

    @pytest.mark.asyncio
    async def test_event_contains_contract_v2_fields(
        self, mock_storage, mock_event_publisher, mock_crawl_result
    ):
        """Test that data.collected event contains Contract v2.0 fields: task_type, brand_name, keyword."""
        from application.crawler_service import CrawlerService

        service = CrawlerService(
            content_repo=AsyncMock(),
            author_repo=AsyncMock(),
            comment_repo=AsyncMock(),
            video_scraper=AsyncMock(),
            creator_scraper=AsyncMock(),
            comment_scraper=AsyncMock(),
            search_scraper=AsyncMock(),
            profile_scraper=AsyncMock(),
            media_downloader=AsyncMock(),
            event_publisher=mock_event_publisher,
        )
        service.set_batch_storage(mock_storage)

        job_id = "proj_abc123-brand-0"

        # Fill batch to trigger upload
        for i in range(5):
            await service.add_to_batch(
                job_id=job_id,
                result=mock_crawl_result,
                keyword="test_keyword",
                task_type="research_and_crawl",
                brand_name="TestBrand",
                batch_size=5,
            )

        # Get the event call arguments
        call_args = mock_event_publisher.publish_data_collected.call_args

        # Verify Contract v2.0 fields
        assert "task_type" in call_args.kwargs
        assert "brand_name" in call_args.kwargs
        assert "keyword" in call_args.kwargs

        # Verify values
        assert call_args.kwargs["task_type"] == "research_and_crawl"
        assert call_args.kwargs["brand_name"] == "TestBrand"
        assert call_args.kwargs["keyword"] == "test_keyword"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
