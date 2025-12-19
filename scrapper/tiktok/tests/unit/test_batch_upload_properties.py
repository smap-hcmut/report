"""
Property-based tests for TikTok batch upload functionality.

**Feature: fix-batch-upload-event**

Tests:
- Property 1: Successful results are batched
- Property 5: Helper returns all batch paths
"""

import pytest
from unittest.mock import AsyncMock, MagicMock
from hypothesis import given, settings, strategies as st, HealthCheck
from typing import List


# Strategy to generate CrawlResult-like objects with mixed success values
@st.composite
def crawl_result_strategy(draw):
    """Generate a mock CrawlResult with random success value."""
    success = draw(st.booleans())

    result = MagicMock()
    result.success = success

    if success:
        content = MagicMock()
        content.external_id = draw(
            st.text(
                min_size=1,
                max_size=20,
                alphabet=st.characters(whitelist_categories=("L", "N")),
            )
        )
        content.source = "tiktok"
        content.url = f"https://tiktok.com/@user/video/{content.external_id}"
        content.description = draw(st.text(max_size=100))
        content.view_count = draw(st.integers(min_value=0, max_value=1000000))
        content.like_count = draw(st.integers(min_value=0, max_value=100000))
        content.comment_count = draw(st.integers(min_value=0, max_value=10000))
        content.share_count = draw(st.integers(min_value=0, max_value=10000))
        content.save_count = draw(st.integers(min_value=0, max_value=10000))
        content.duration_seconds = draw(st.integers(min_value=1, max_value=600))
        content.tags = []
        content.sound_name = None
        content.category = None
        content.media_type = None
        content.media_path = None
        content.media_downloaded_at = None
        content.transcription = None
        content.transcription_status = None
        content.transcription_error = None
        content.crawled_at = None
        content.published_at = None
        content.updated_at = None
        content.keyword = "test"
        content.author_username = "testuser"
        result.content = content
    else:
        result.content = None

    result.author = None
    result.comments = []
    result.error_message = None if success else "Test error"

    return result


@st.composite
def crawl_results_list_strategy(draw, min_size=0, max_size=20):
    """Generate a list of CrawlResults with mixed success values."""
    size = draw(st.integers(min_value=min_size, max_value=max_size))
    return [draw(crawl_result_strategy()) for _ in range(size)]


def create_mock_crawler_service():
    """Create a mock CrawlerService with batch methods."""
    service = AsyncMock()
    service.add_to_batch = AsyncMock(return_value=None)
    service.flush_batch = AsyncMock(return_value=None)
    service.clear_batch_state = MagicMock()
    return service


def create_task_service(mock_crawler_service):
    """Create a TaskService with mocked dependencies."""
    from application.task_service import TaskService

    service = TaskService(
        crawler_service=mock_crawler_service,
        job_repo=AsyncMock(),
        content_repo=AsyncMock(),
        search_session_repo=None,
        result_publisher=None,
    )
    return service


def create_mock_crawler_service_with_paths():
    """Create a mock CrawlerService that returns paths."""
    service = AsyncMock()
    service._call_count = 0

    async def add_to_batch_side_effect(*args, **kwargs):
        service._call_count += 1
        batch_size = kwargs.get("batch_size", 50)
        # Return a path every batch_size calls
        if service._call_count % batch_size == 0:
            return f"path/batch_{service._call_count // batch_size}.json"
        return None

    service.add_to_batch = AsyncMock(side_effect=add_to_batch_side_effect)
    service.flush_batch = AsyncMock(return_value="path/final_batch.json")
    service.clear_batch_state = MagicMock()
    return service


class TestProperty1SuccessfulResultsAreBatched:
    """
    **Feature: fix-batch-upload-event, Property 1: Successful results are batched**

    *For any* list of CrawlResults, all results with `success=True` SHALL be
    added to batch, and all results with `success=False` SHALL be skipped.

    **Validates: Requirements 1.1, 2.4**
    """

    @pytest.mark.asyncio
    @settings(
        max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture]
    )
    @given(crawl_results=crawl_results_list_strategy(min_size=1, max_size=20))
    async def test_only_successful_results_trigger_add_to_batch(
        self, crawl_results: List
    ):
        """
        **Feature: fix-batch-upload-event, Property 1: Successful results are batched**

        Verify that only successful CrawlResults trigger add_to_batch calls.

        **Validates: Requirements 1.1, 2.4**
        """
        # Create fresh mocks for each test run
        mock_crawler_service = create_mock_crawler_service()
        task_service = create_task_service(mock_crawler_service)

        # Process results
        await task_service._process_crawl_results_with_batch(
            crawl_results=crawl_results,
            job_id="test-job-123",
            keyword="test",
            task_type="research_and_crawl",
            batch_size=50,
        )

        # Count expected add_to_batch calls (only for successful results)
        expected_calls = sum(1 for r in crawl_results if r.success)
        actual_calls = mock_crawler_service.add_to_batch.call_count

        assert actual_calls == expected_calls, (
            f"Expected {expected_calls} add_to_batch calls for successful results, "
            f"but got {actual_calls}"
        )


class TestProperty5HelperReturnsAllPaths:
    """
    **Feature: fix-batch-upload-event, Property 5: Helper returns all batch paths**

    *For any* set of crawl results processed through `_process_crawl_results_with_batch()`,
    the returned list SHALL contain paths for all uploaded batches
    (both threshold-triggered and flush-triggered).

    **Validates: Requirements 2.3**
    """

    @pytest.mark.asyncio
    @settings(
        max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture]
    )
    @given(
        batch_size=st.integers(min_value=1, max_value=10),
        num_successful=st.integers(min_value=0, max_value=50),
    )
    async def test_helper_returns_all_batch_paths(
        self, batch_size: int, num_successful: int
    ):
        """
        **Feature: fix-batch-upload-event, Property 5: Helper returns all batch paths**

        Verify that the helper returns all paths from both threshold-triggered
        and flush-triggered uploads.

        **Validates: Requirements 2.3**
        """
        # Create fresh mocks for each test run
        mock_crawler_service = create_mock_crawler_service_with_paths()
        task_service = create_task_service(mock_crawler_service)

        # Create successful results
        crawl_results = []
        for i in range(num_successful):
            result = MagicMock()
            result.success = True
            content = MagicMock()
            content.external_id = f"video{i}"
            result.content = content
            crawl_results.append(result)

        # Process results
        paths = await task_service._process_crawl_results_with_batch(
            crawl_results=crawl_results,
            job_id="test-job-123",
            keyword="test",
            task_type="research_and_crawl",
            batch_size=batch_size,
        )

        # Calculate expected paths
        # - One path for each full batch (num_successful // batch_size)
        # - One path from flush_batch (always called, returns path if there are remaining items)
        expected_batch_uploads = (
            num_successful // batch_size if num_successful > 0 else 0
        )
        # flush_batch always returns a path in our mock
        expected_flush_path = 1
        expected_total_paths = expected_batch_uploads + expected_flush_path

        assert len(paths) == expected_total_paths, (
            f"Expected {expected_total_paths} paths "
            f"({expected_batch_uploads} from batches + {expected_flush_path} from flush), "
            f"but got {len(paths)}"
        )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])


class TestProperty6ErrorResilience:
    """
    **Feature: fix-batch-upload-event, Property 6: Error resilience**

    *For any* batch upload failure, the system SHALL log the error and
    continue processing without failing the entire task.

    **Validates: Requirements 5.3**
    """

    @pytest.mark.asyncio
    @settings(
        max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture]
    )
    @given(
        num_results=st.integers(min_value=1, max_value=20),
        fail_at_index=st.integers(min_value=0, max_value=19),
    )
    async def test_task_continues_when_add_to_batch_fails(
        self, num_results: int, fail_at_index: int
    ):
        """
        **Feature: fix-batch-upload-event, Property 6: Error resilience**

        Verify that when add_to_batch raises an exception, the task continues
        processing remaining results without failing.

        **Validates: Requirements 5.3**
        """
        # Adjust fail_at_index to be within bounds
        fail_at_index = fail_at_index % num_results if num_results > 0 else 0

        # Create mock crawler service that fails at specific index
        mock_crawler_service = AsyncMock()
        call_count = [0]

        async def add_to_batch_with_failure(*args, **kwargs):
            current_call = call_count[0]
            call_count[0] += 1
            if current_call == fail_at_index:
                raise Exception("Simulated batch upload failure")
            return None

        mock_crawler_service.add_to_batch = AsyncMock(
            side_effect=add_to_batch_with_failure
        )
        mock_crawler_service.flush_batch = AsyncMock(return_value="path/final.json")
        mock_crawler_service.clear_batch_state = MagicMock()

        task_service = create_task_service(mock_crawler_service)

        # Create successful results
        crawl_results = []
        for i in range(num_results):
            result = MagicMock()
            result.success = True
            content = MagicMock()
            content.external_id = f"video{i}"
            result.content = content
            crawl_results.append(result)

        # Process results - should NOT raise exception
        paths = await task_service._process_crawl_results_with_batch(
            crawl_results=crawl_results,
            job_id="test-job-error",
            keyword="test",
            task_type="research_and_crawl",
            batch_size=50,
        )

        # Verify task completed (didn't raise)
        # All results should have been attempted
        assert mock_crawler_service.add_to_batch.call_count == num_results
        # flush_batch should still be called
        mock_crawler_service.flush_batch.assert_called_once()
        # clear_batch_state should always be called (in finally block)
        mock_crawler_service.clear_batch_state.assert_called_once_with("test-job-error")

    @pytest.mark.asyncio
    @settings(
        max_examples=50, suppress_health_check=[HealthCheck.function_scoped_fixture]
    )
    @given(num_results=st.integers(min_value=1, max_value=10))
    async def test_task_continues_when_flush_batch_fails(self, num_results: int):
        """
        **Feature: fix-batch-upload-event, Property 6: Error resilience**

        Verify that when flush_batch raises an exception, the task still
        completes and cleans up batch state.

        **Validates: Requirements 5.3**
        """
        # Create mock crawler service where flush_batch fails
        mock_crawler_service = AsyncMock()
        mock_crawler_service.add_to_batch = AsyncMock(return_value=None)
        mock_crawler_service.flush_batch = AsyncMock(
            side_effect=Exception("Simulated flush failure")
        )
        mock_crawler_service.clear_batch_state = MagicMock()

        task_service = create_task_service(mock_crawler_service)

        # Create successful results
        crawl_results = []
        for i in range(num_results):
            result = MagicMock()
            result.success = True
            content = MagicMock()
            content.external_id = f"video{i}"
            result.content = content
            crawl_results.append(result)

        # Process results - should NOT raise exception
        paths = await task_service._process_crawl_results_with_batch(
            crawl_results=crawl_results,
            job_id="test-job-flush-error",
            keyword="test",
            task_type="research_and_crawl",
            batch_size=50,
        )

        # Verify task completed
        assert mock_crawler_service.add_to_batch.call_count == num_results
        mock_crawler_service.flush_batch.assert_called_once()
        # clear_batch_state should ALWAYS be called (in finally block)
        mock_crawler_service.clear_batch_state.assert_called_once_with(
            "test-job-flush-error"
        )
        # Paths should be empty since flush failed
        assert len(paths) == 0
