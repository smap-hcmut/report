"""
Unit tests for dry-run keyword task comment and creator scraping support
Tests Requirements 7.1-7.5 and 8.1-8.5
"""
import pytest
from unittest.mock import AsyncMock, MagicMock
from datetime import datetime
from application.task_service import TaskService
from application.crawler_service import CrawlResult
from domain import Content, Author, Comment
from domain.enums import SourcePlatform, ParentType


@pytest.fixture
def mock_crawler_service():
    """Mock crawler service"""
    service = AsyncMock()
    return service


@pytest.fixture
def mock_job_repo():
    """Mock job repository"""
    repo = AsyncMock()
    repo.create_job = AsyncMock(return_value=True)
    repo.update_job_status = AsyncMock(return_value=True)
    repo.update_job_results = AsyncMock(return_value=True)
    return repo


@pytest.fixture
def mock_content_repo():
    """Mock content repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def task_service(mock_crawler_service, mock_job_repo, mock_content_repo):
    """Create task service with mocked dependencies"""
    return TaskService(
        crawler_service=mock_crawler_service,
        job_repo=mock_job_repo,
        content_repo=mock_content_repo,
        result_publisher=None
    )


@pytest.mark.asyncio
async def test_dryrun_passes_include_comments_parameter(task_service, mock_crawler_service):
    """
    Test that include_comments parameter is passed to crawler service
    Validates: Requirements 7.1
    """
    # Arrange
    payload = {
        'keyword': 'test',
        'include_comments': True,
        'max_comments': 10
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    assert call_kwargs['include_comments'] is True
    assert call_kwargs['max_comments'] == 10


@pytest.mark.asyncio
async def test_dryrun_passes_include_creator_parameter(task_service, mock_crawler_service):
    """
    Test that include_creator parameter is passed to crawler service
    Validates: Requirements 8.1
    """
    # Arrange
    payload = {
        'keyword': 'test',
        'include_creator': True
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    assert call_kwargs['include_creator'] is True


@pytest.mark.asyncio
async def test_dryrun_passes_max_comments_parameter(task_service, mock_crawler_service):
    """
    Test that max_comments parameter is passed to crawler service
    Validates: Requirements 7.2
    """
    # Arrange
    payload = {
        'keyword': 'test',
        'max_comments': 50
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    assert call_kwargs['max_comments'] == 50


@pytest.mark.asyncio
async def test_dryrun_collects_comment_counts(task_service, mock_crawler_service):
    """
    Test that comment counts are collected from crawl results
    Validates: Requirements 7.4
    """
    # Arrange
    payload = {
        'keyword': 'test',
        'include_comments': True
    }
    
    # Create mock crawl results with comments
    content1 = Content(
        source=SourcePlatform.TIKTOK,
        external_id='video1',
        url='https://tiktok.com/@user/video/1'
    )
    content2 = Content(
        source=SourcePlatform.TIKTOK,
        external_id='video2',
        url='https://tiktok.com/@user/video/2'
    )
    
    comments1 = [
        Comment(
            source=SourcePlatform.TIKTOK,
            external_id='comment1',
            parent_type=ParentType.CONTENT,
            parent_id='video1',
            comment_text='Great video!'
        ),
        Comment(
            source=SourcePlatform.TIKTOK,
            external_id='comment2',
            parent_type=ParentType.CONTENT,
            parent_id='video1',
            comment_text='Love it!'
        )
    ]
    
    comments2 = [
        Comment(
            source=SourcePlatform.TIKTOK,
            external_id='comment3',
            parent_type=ParentType.CONTENT,
            parent_id='video2',
            comment_text='Amazing!'
        )
    ]
    
    result1 = CrawlResult(content=content1, success=True)
    result1.comments = comments1
    
    result2 = CrawlResult(content=content2, success=True)
    result2.comments = comments2
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [result1, result2],
        'total': 2,
        'successful': 2,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    result = await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    assert result['statistics']['total_comments'] == 3  # 2 + 1 comments


@pytest.mark.asyncio
async def test_dryrun_disables_storage(task_service, mock_crawler_service):
    """
    Test that storage flags are disabled in dry-run mode
    Validates: Requirements 7.3, 8.2
    """
    # Arrange
    payload = {
        'keyword': 'test',
        'include_comments': True,
        'include_creator': True
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    
    # Verify all storage flags are disabled
    assert call_kwargs['media_download_enabled'] is False
    assert call_kwargs['save_to_db_enabled'] is False
    assert call_kwargs['archive_storage_enabled'] is False


@pytest.mark.asyncio
async def test_dryrun_defaults_include_comments_to_true(task_service, mock_crawler_service):
    """
    Test that include_comments defaults to True when omitted
    Validates: Requirements 7.5
    """
    # Arrange
    payload = {
        'keyword': 'test'
        # include_comments omitted
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    assert call_kwargs['include_comments'] is True


@pytest.mark.asyncio
async def test_dryrun_defaults_include_creator_to_true(task_service, mock_crawler_service):
    """
    Test that include_creator defaults to True when omitted
    Validates: Requirements 8.4
    """
    # Arrange
    payload = {
        'keyword': 'test'
        # include_creator omitted
    }
    
    # Mock crawler service response
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'crawl_results': [],
        'total': 0,
        'successful': 0,
        'failed': 0,
        'skipped': 0
    })
    
    # Act
    await task_service._handle_dryrun_keyword(payload, 'test-job-id')
    
    # Assert
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args.kwargs
    assert call_kwargs['include_creator'] is True
