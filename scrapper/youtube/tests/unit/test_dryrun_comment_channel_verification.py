"""
Unit tests to verify comment and channel scraping support in dryrun_keyword task

This test verifies:
- include_comments parameter is passed to crawler service
- include_channel parameter is passed to crawler service
- max_comments parameter is passed to crawler service
- Scraped data is not persisted to MongoDB
- Comments and channel data are included in mapped results

Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 8.5
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch, call
from datetime import datetime
from typing import Dict, Any, List

from application.task_service import TaskService
from application.crawler_service import CrawlerService
from domain.entities.content import Content
from domain.entities.author import Author
from domain.entities.comment import Comment
from domain.enums import SourcePlatform, ParentType


class MockCrawlResult:
    """Mock CrawlResult for testing"""
    def __init__(self, success=True, content=None, author=None, comments=None):
        self.success = success
        self.content = content
        self.author = author
        self.comments = comments or []
        self.error_message = None
        self.skipped = False
        self.minio_key = None


@pytest.fixture
def mock_crawler_service():
    """Create mock crawler service"""
    service = AsyncMock(spec=CrawlerService)
    return service


@pytest.fixture
def mock_job_repo():
    """Create mock job repository"""
    repo = AsyncMock()
    repo.create_job = AsyncMock(return_value=True)
    repo.update_job_status = AsyncMock(return_value=True)
    repo.update_job_results = AsyncMock(return_value=True)
    return repo


@pytest.fixture
def mock_content_repo():
    """Create mock content repository"""
    return AsyncMock()


@pytest.fixture
def mock_result_publisher():
    """Create mock result publisher"""
    publisher = AsyncMock()
    publisher.publish_result = AsyncMock()
    return publisher


@pytest.fixture
def task_service(mock_crawler_service, mock_job_repo, mock_content_repo, mock_result_publisher):
    """Create TaskService with mocked dependencies"""
    return TaskService(
        crawler_service=mock_crawler_service,
        job_repo=mock_job_repo,
        content_repo=mock_content_repo,
        search_session_repo=None,
        result_publisher=mock_result_publisher,
        default_download_media=False,
        default_media_type="audio",
        default_media_dir="./YOUTUBE"
    )


def create_mock_content(external_id="test_video_123", keyword="test keyword"):
    """Create mock Content entity"""
    content = Content(
        external_id=external_id,
        source=SourcePlatform.YOUTUBE,
        url=f"https://www.youtube.com/watch?v={external_id}",
        title="Test Video Title",
        description="Test video description",
        author_external_id="channel_123",
        author_username="testchannel",
        author_display_name="Test Channel",
        published_at=datetime(2024, 1, 1, 12, 0, 0),
        crawled_at=datetime.utcnow(),
        view_count=1000,
        like_count=100,
        comment_count=50,
        duration_seconds=300,
        category="Education",
        keyword=keyword
    )
    return content


def create_mock_author():
    """Create mock Author entity"""
    author = Author(
        external_id="channel_123",
        source=SourcePlatform.YOUTUBE,
        username="testchannel",
        display_name="Test Channel",
        profile_url="https://www.youtube.com/@testchannel",
        follower_count=50000,
        video_count=250,
        verified=True,
        extra_json={
            "country": "US",
            "total_view_count": 5000000,
            "description": "Test channel bio"
        }
    )
    return author


def create_mock_comments(count=3):
    """Create mock Comment entities"""
    comments = []
    for i in range(count):
        comment = Comment(
            external_id=f"comment_{i}",
            source=SourcePlatform.YOUTUBE,
            parent_type=ParentType.CONTENT,
            parent_id="test_video_123",
            commenter_name=f"User{i}",
            comment_text=f"Test comment {i}",
            like_count=10 + i,
            reply_count=2,
            published_at=datetime(2024, 1, 2, 12, i, 0),
            extra_json={
                "author_channel_id": f"UC_user_{i}",
                "is_favorited": i == 0
            }
        )
        comments.append(comment)
    return comments


@pytest.mark.asyncio
async def test_include_comments_parameter_passed_to_crawler(task_service, mock_crawler_service):
    """
    Verify include_comments parameter is passed to crawler service
    Requirements: 7.1
    """
    # Setup mock response
    mock_content = create_mock_content()
    mock_author = create_mock_author()
    mock_comments = create_mock_comments(5)
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=mock_author,
        comments=mock_comments
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task with include_comments=True
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_comments': True,
        'max_comments': 50
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify include_comments was passed to crawler service
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args[1]
    
    assert call_kwargs['include_comments'] is True, "include_comments should be True"
    assert call_kwargs['max_comments'] == 50, "max_comments should be 50"


@pytest.mark.asyncio
async def test_include_channel_parameter_passed_to_crawler(task_service, mock_crawler_service):
    """
    Verify include_channel parameter is passed to crawler service
    Requirements: 8.1
    """
    # Setup mock response
    mock_content = create_mock_content()
    mock_author = create_mock_author()
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=mock_author,
        comments=[]
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task with include_channel=True
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_channel': True
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify include_channel was passed to crawler service
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args[1]
    
    assert call_kwargs['include_channel'] is True, "include_channel should be True"


@pytest.mark.asyncio
async def test_max_comments_parameter_passed_to_crawler(task_service, mock_crawler_service):
    """
    Verify max_comments parameter is passed to crawler service
    Requirements: 7.2
    """
    # Setup mock response
    mock_content = create_mock_content()
    mock_comments = create_mock_comments(20)
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=None,
        comments=mock_comments
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task with max_comments=20
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_comments': True,
        'max_comments': 20
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify max_comments was passed to crawler service
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args[1]
    
    assert call_kwargs['max_comments'] == 20, "max_comments should be 20"


@pytest.mark.asyncio
async def test_data_not_persisted_to_mongodb(task_service, mock_crawler_service):
    """
    Verify scraped data is not persisted to MongoDB in dry-run mode
    Requirements: 7.3, 8.2
    """
    # Setup mock response
    mock_content = create_mock_content()
    mock_author = create_mock_author()
    mock_comments = create_mock_comments(5)
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=mock_author,
        comments=mock_comments
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_comments': True,
        'include_channel': True,
        'max_comments': 50
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify storage flags are set to False
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args[1]
    
    assert call_kwargs['save_to_db_enabled'] is False, "save_to_db_enabled should be False"
    assert call_kwargs['archive_storage_enabled'] is False, "archive_storage_enabled should be False"
    assert call_kwargs['media_download_enabled'] is False, "media_download_enabled should be False"


@pytest.mark.asyncio
async def test_comments_included_in_mapped_results(task_service, mock_crawler_service, mock_result_publisher):
    """
    Verify comments are included in mapped results
    Requirements: 7.4
    """
    # Setup mock response with comments
    mock_content = create_mock_content()
    mock_author = create_mock_author()
    mock_comments = create_mock_comments(3)
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=mock_author,
        comments=mock_comments
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_comments': True,
        'max_comments': 50
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify result was published
    mock_result_publisher.publish_result.assert_called_once()
    
    # Get the published result
    call_args = mock_result_publisher.publish_result.call_args
    result_data = call_args[1]['result_data']
    
    # Verify comments are in the payload
    assert result_data['success'] is True
    assert len(result_data['payload']) == 1
    
    mapped_item = result_data['payload'][0]
    assert 'comments' in mapped_item
    assert len(mapped_item['comments']) == 3
    
    # Verify comment structure
    first_comment = mapped_item['comments'][0]
    assert 'id' in first_comment
    assert 'text' in first_comment
    assert 'user' in first_comment
    assert 'id' in first_comment['user']  # YouTube-specific: commenter channel ID
    assert first_comment['user']['id'] == 'UC_user_0'


@pytest.mark.asyncio
async def test_channel_data_included_in_mapped_results(task_service, mock_crawler_service, mock_result_publisher):
    """
    Verify channel data is included in mapped results
    Requirements: 8.3
    """
    # Setup mock response with channel data
    mock_content = create_mock_content()
    mock_author = create_mock_author()
    
    mock_result = MockCrawlResult(
        success=True,
        content=mock_content,
        author=mock_author,
        comments=[]
    )
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task
    payload = {
        'keywords': ['test keyword'],
        'limit': 10,
        'include_channel': True
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify result was published
    mock_result_publisher.publish_result.assert_called_once()
    
    # Get the published result
    call_args = mock_result_publisher.publish_result.call_args
    result_data = call_args[1]['result_data']
    
    # Verify channel data is in the payload
    assert result_data['success'] is True
    assert len(result_data['payload']) == 1
    
    mapped_item = result_data['payload'][0]
    assert 'author' in mapped_item
    assert mapped_item['author'] is not None
    
    # Verify YouTube-specific channel fields
    author = mapped_item['author']
    assert author['id'] == 'channel_123'
    assert author['name'] == 'Test Channel'
    assert author['username'] == 'testchannel'
    assert author['followers'] == 50000
    assert author['videos'] == 250
    assert author['is_verified'] is True
    assert author['country'] == 'US'  # YouTube-specific
    assert author['total_view_count'] == 5000000  # YouTube-specific
    assert author['bio'] == 'Test channel bio'


@pytest.mark.asyncio
async def test_default_values_for_comment_and_channel_parameters(task_service, mock_crawler_service):
    """
    Verify default values are used when parameters are omitted
    Requirements: 7.5, 8.4
    """
    # Setup mock response
    mock_content = create_mock_content()
    mock_result = MockCrawlResult(success=True, content=mock_content)
    
    mock_crawler_service.search_and_fetch = AsyncMock(return_value={
        'keyword': 'test keyword',
        'video_urls': ['https://youtube.com/watch?v=test_video_123'],
        'crawl_results': [mock_result],
        'total': 1,
        'successful': 1,
        'failed': 0,
        'skipped': 0,
        'success': True
    })
    
    # Execute task without specifying include_comments, include_channel, or max_comments
    payload = {
        'keywords': ['test keyword'],
        'limit': 10
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify default values were used
    mock_crawler_service.search_and_fetch.assert_called_once()
    call_kwargs = mock_crawler_service.search_and_fetch.call_args[1]
    
    # Default values per requirements
    assert call_kwargs['include_comments'] is True, "include_comments should default to True"
    assert call_kwargs['include_channel'] is True, "include_channel should default to True"
    assert call_kwargs['max_comments'] == 0, "max_comments should default to 0"


@pytest.mark.asyncio
async def test_multiple_keywords_with_comments_and_channel(task_service, mock_crawler_service, mock_result_publisher):
    """
    Verify comments and channel data are included for multiple keywords
    Requirements: 7.1, 7.4, 8.1, 8.3
    """
    # Setup mock responses for two keywords
    keywords = ['keyword1', 'keyword2']
    mock_results = []
    
    for i, keyword in enumerate(keywords):
        mock_content = create_mock_content(external_id=f"video_{i}", keyword=keyword)
        mock_author = create_mock_author()
        mock_comments = create_mock_comments(2)
        
        mock_result = MockCrawlResult(
            success=True,
            content=mock_content,
            author=mock_author,
            comments=mock_comments
        )
        mock_results.append(mock_result)
    
    # Mock search_and_fetch to return different results for each keyword
    call_count = 0
    async def mock_search_and_fetch(*args, **kwargs):
        nonlocal call_count
        result = {
            'keyword': keywords[call_count],
            'video_urls': [f'https://youtube.com/watch?v=video_{call_count}'],
            'crawl_results': [mock_results[call_count]],
            'total': 1,
            'successful': 1,
            'failed': 0,
            'skipped': 0,
            'success': True
        }
        call_count += 1
        return result
    
    mock_crawler_service.search_and_fetch = mock_search_and_fetch
    
    # Execute task with multiple keywords
    payload = {
        'keywords': keywords,
        'limit': 10,
        'include_comments': True,
        'include_channel': True,
        'max_comments': 50
    }
    
    await task_service.handle_task(
        task_type='dryrun_keyword',
        payload=payload,
        job_id='test_job_123'
    )
    
    # Verify result was published
    mock_result_publisher.publish_result.assert_called_once()
    
    # Get the published result
    call_args = mock_result_publisher.publish_result.call_args
    result_data = call_args[1]['result_data']
    
    # Verify both videos are in the payload with comments and channel data
    assert result_data['success'] is True
    assert len(result_data['payload']) == 2
    
    for i, mapped_item in enumerate(result_data['payload']):
        # Verify comments are included
        assert 'comments' in mapped_item
        assert len(mapped_item['comments']) == 2
        
        # Verify channel data is included
        assert 'author' in mapped_item
        assert mapped_item['author'] is not None
        assert mapped_item['author']['id'] == 'channel_123'
        assert mapped_item['author']['country'] == 'US'
        assert mapped_item['author']['total_view_count'] == 5000000
