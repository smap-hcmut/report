# TikTok Worker - Implementation Plan: Payload-Based Configuration

## Overview

Move configuration options from settings to payload parameters, allowing per-message control of:
- `media_download_enabled` - Enable/disable media downloads
- `save_to_db_enabled` - Enable/disable MongoDB persistence

## Goals

1. Allow clients to control behavior per-message instead of globally
2. Maintain backward compatibility with existing code
3. Follow existing code conventions and architecture
4. Keep settings as defaults, allow payload to override

## Architecture

```
RabbitMQ Message (payload)
    ↓
TaskService._handle_*() - Extract payload options
    ↓
CrawlerService.fetch_*() - Pass options down
    ↓
ContentArchiver - Use options for storage decisions
```

## Implementation Tasks

### Phase 1: Update Domain & Interfaces

#### 1.1 Update CrawlResult Domain Model
**File**: `scrapper/tiktok/domain/entities/crawl_result.py`

**Changes**:
- Add optional fields to track what was enabled for this crawl

```python
@dataclass
class CrawlResult:
    # ... existing fields ...
    
    # NEW: Track what was enabled for this specific crawl
    media_downloaded: bool = False  # Was media actually downloaded
    saved_to_db: bool = False  # Was data saved to MongoDB
```

**Rationale**: Track per-result what operations were performed.

---

#### 1.2 Update IContentArchiver Interface
**File**: `scrapper/tiktok/application/interfaces.py`

**Changes**:
- Add optional parameters to `archive_content()` method

```python
class IContentArchiver(ABC):
    """Interface for content archival operations"""
    
    @abstractmethod
    async def archive_content(
        self,
        content: Content,
        author: Optional[Author] = None,
        comments: Optional[List[Comment]] = None,
        job_id: Optional[str] = None,
        keyword: Optional[str] = None,
        # NEW: Per-operation toggles
        save_to_minio: bool = True,
        save_to_db: bool = False,
    ) -> str:
        """
        Archive content to storage backends
        
        Args:
            content: Content entity to archive
            author: Optional author entity
            comments: Optional list of comments
            job_id: Optional job ID for tracking
            keyword: Optional keyword for categorization
            save_to_minio: Whether to save to MinIO (default: True)
            save_to_db: Whether to save to MongoDB (default: False)
            
        Returns:
            MinIO key where content was archived
        """
        pass
```

**Rationale**: Interface defines contract for storage operations.

---

### Phase 2: Update Application Layer

#### 2.1 Update TaskService - Extract Payload Options
**File**: `scrapper/tiktok/application/task_service.py`

**Changes**:

**2.1.1** Add helper method to extract common options:

```python
class TaskService:
    # ... existing code ...
    
    def _extract_storage_options(self, payload: Dict[str, Any]) -> Dict[str, bool]:
        """
        Extract storage-related options from payload.
        
        Args:
            payload: Task payload
            
        Returns:
            Dict with storage options
        """
        return {
            'media_download_enabled': payload.get(
                'media_download_enabled',
                self.default_download_media
            ),
            'save_to_db_enabled': payload.get(
                'save_to_db_enabled',
                settings.enable_db_persistence
            )
        }
```

**2.1.2** Update `_handle_crawl_links()` method:

```python
async def _handle_crawl_links(
    self,
    payload: Dict[str, Any],
    job_id: str,
    time_range_days: Optional[int] = None,
    since_date: Optional[datetime] = None,
    until_date: Optional[datetime] = None
) -> Dict[str, Any]:
    """Handle crawl_links task"""
    
    video_urls = payload.get('video_urls', [])
    include_comments = payload.get('include_comments', True)
    include_creator = payload.get('include_creator', True)
    max_comments = payload.get('max_comments', 0)
    keyword = payload.get('keyword')

    # Media download parameters
    download_media = payload.get('download_media', self.default_download_media)
    media_type = payload.get('media_type', self.default_media_type)
    media_save_dir = payload.get('media_save_dir', self.default_media_dir)
    
    # NEW: Extract storage options
    storage_options = self._extract_storage_options(payload)

    if not video_urls:
        raise ValueError("Missing required field: video_urls")

    # Fetch videos - pass storage options
    crawl_results = await self.crawler_service.fetch_videos_batch(
        urls=video_urls,
        download_media=download_media,
        media_type=media_type,
        media_save_dir=media_save_dir,
        include_creator=include_creator,
        include_comments=include_comments,
        max_comments=max_comments,
        job_id=job_id,
        keyword=keyword,
        time_range_days=time_range_days,
        since_date=since_date,
        until_date=until_date,
        # NEW: Pass storage options
        media_download_enabled=storage_options['media_download_enabled'],
        save_to_db_enabled=storage_options['save_to_db_enabled'],
    )

    successful = sum(1 for r in crawl_results if r.success)
    skipped = sum(1 for r in crawl_results if getattr(r, "skipped", False))
    failed = max(len(video_urls) - successful - skipped, 0)

    return {
        'task_type': 'crawl_links',
        'total': len(video_urls),
        'successful': successful,
        'failed': failed,
        'skipped': skipped,
        'download_media': download_media,
        'media_type': media_type if download_media else None,
        'crawl_results': crawl_results,
        # NEW: Include storage options in response
        'media_download_enabled': storage_options['media_download_enabled'],
        'save_to_db_enabled': storage_options['save_to_db_enabled'],
    }
```

**2.1.3** Update `_handle_research_and_crawl()` method:

```python
async def _handle_research_and_crawl(
    self,
    payload: Dict[str, Any],
    job_id: str,
    time_range_days: Optional[int] = None,
    since_date: Optional[datetime] = None,
    until_date: Optional[datetime] = None
) -> Dict[str, Any]:
    """Handle research_and_crawl task"""
    
    keywords = payload.get('keywords', [])
    limit_per_keyword = payload.get('limit_per_keyword', 50)
    sort_by = payload.get('sort_by', 'relevance')
    include_comments = payload.get('include_comments', True)
    include_creator = payload.get('include_creator', True)
    max_comments = payload.get('max_comments', 0)

    # Media download parameters
    download_media = payload.get('download_media', self.default_download_media)
    media_type = payload.get('media_type', self.default_media_type)
    media_save_dir = payload.get('media_save_dir', self.default_media_dir)
    
    # NEW: Extract storage options
    storage_options = self._extract_storage_options(payload)

    if not keywords:
        raise ValueError("Missing required field: keywords")

    results_by_keyword = {}
    total_videos = 0
    total_successful = 0

    # Process each keyword
    for keyword in keywords:
        result = await self.crawler_service.search_and_fetch(
            keyword=keyword,
            limit=limit_per_keyword,
            sort_by=sort_by,
            download_media=download_media,
            media_type=media_type,
            media_save_dir=media_save_dir,
            include_creator=include_creator,
            include_comments=include_comments,
            max_comments=max_comments,
            job_id=job_id,
            time_range_days=time_range_days,
            since_date=since_date,
            until_date=until_date,
            # NEW: Pass storage options
            media_download_enabled=storage_options['media_download_enabled'],
            save_to_db_enabled=storage_options['save_to_db_enabled'],
        )

        results_by_keyword[keyword] = result
        await self._record_search_session(
            keyword=keyword,
            video_urls=result.get('video_urls', []),
            sort_by=sort_by,
            job_id=job_id
        )
        total_videos += result.get('total', 0)
        total_successful += result.get('successful', 0)

    total_skipped = sum(
        kw_result.get('skipped', 0)
        for kw_result in results_by_keyword.values()
    )
    total_failed = max(total_videos - total_successful - total_skipped, 0)

    return {
        'task_type': 'research_and_crawl',
        'keywords': keywords,
        'results_by_keyword': results_by_keyword,
        'total_videos': total_videos,
        'total_successful': total_successful,
        'total_failed': total_failed,
        'total_skipped': total_skipped,
        'download_media': download_media,
        'media_type': media_type if download_media else None,
        # NEW: Include storage options in response
        'media_download_enabled': storage_options['media_download_enabled'],
        'save_to_db_enabled': storage_options['save_to_db_enabled'],
    }
```

**2.1.4** Update `_handle_fetch_profile_content()` method:

Apply same pattern as above - extract storage options and pass to crawler service.

---

#### 2.2 Update CrawlerService
**File**: `scrapper/tiktok/application/crawler_service.py`

**Changes**:

**2.2.1** Update `fetch_videos_batch()` method signature:

```python
async def fetch_videos_batch(
    self,
    urls: List[str],
    download_media: bool = False,
    media_type: str = "audio",
    media_save_dir: str = "./downloads",
    include_creator: bool = True,
    include_comments: bool = True,
    max_comments: int = 0,
    job_id: Optional[str] = None,
    keyword: Optional[str] = None,
    time_range_days: Optional[int] = None,
    since_date: Optional[datetime] = None,
    until_date: Optional[datetime] = None,
    # NEW: Storage options
    media_download_enabled: bool = True,
    save_to_db_enabled: bool = False,
) -> List[CrawlResult]:
    """
    Fetch multiple videos in batch
    
    Args:
        urls: List of video URLs
        download_media: Whether to download media files
        media_type: Type of media ('audio' or 'video')
        media_save_dir: Directory/prefix for media storage
        include_creator: Whether to fetch creator info
        include_comments: Whether to fetch comments
        max_comments: Maximum comments to fetch (0 = unlimited)
        job_id: Job ID for tracking
        keyword: Associated keyword
        time_range_days: Filter by recent days
        since_date: Filter by start date
        until_date: Filter by end date
        media_download_enabled: Global toggle for media downloads
        save_to_db_enabled: Whether to save to MongoDB
        
    Returns:
        List of CrawlResult objects
    """
    # ... existing implementation ...
    
    # When calling _fetch_single_video, pass the options:
    result = await self._fetch_single_video(
        url=url,
        download_media=download_media and media_download_enabled,  # Combine flags
        media_type=media_type,
        media_save_dir=media_save_dir,
        include_creator=include_creator,
        include_comments=include_comments,
        max_comments=max_comments,
        job_id=job_id,
        keyword=keyword,
        save_to_db_enabled=save_to_db_enabled,
    )
```

**2.2.2** Update `_fetch_single_video()` method:

```python
async def _fetch_single_video(
    self,
    url: str,
    download_media: bool,
    media_type: str,
    media_save_dir: str,
    include_creator: bool,
    include_comments: bool,
    max_comments: int,
    job_id: Optional[str],
    keyword: Optional[str],
    # NEW: Storage option
    save_to_db_enabled: bool = False,
) -> CrawlResult:
    """Fetch a single video with all details"""
    
    try:
        # ... existing scraping logic ...
        
        # Archive content - pass storage options
        minio_key = await self.content_archiver.archive_content(
            content=content,
            author=author if include_creator else None,
            comments=comments if include_comments else None,
            job_id=job_id,
            keyword=keyword,
            # NEW: Pass storage options
            save_to_minio=True,  # Always save to MinIO
            save_to_db=save_to_db_enabled,
        )
        
        return CrawlResult(
            url=url,
            success=True,
            minio_key=minio_key,
            content_id=content.content_id,
            # NEW: Track what was done
            media_downloaded=download_media,
            saved_to_db=save_to_db_enabled,
        )
        
    except Exception as e:
        logger.error(f"Failed to fetch video {url}: {e}")
        return CrawlResult(
            url=url,
            success=False,
            error=str(e),
            media_downloaded=False,
            saved_to_db=False,
        )
```

**2.2.3** Update `search_and_fetch()` method:

Add same parameters and pass them through to `fetch_videos_batch()`.

**2.2.4** Update `fetch_profile_videos()` method:

Add same parameters and pass them through to `fetch_videos_batch()`.

---

### Phase 3: Update Infrastructure Layer

#### 3.1 Update ContentArchiver Implementation
**File**: `scrapper/tiktok/internal/adapters/content_archiver.py`

**Changes**:

```python
class ContentArchiver(IContentArchiver):
    """Content archival implementation"""
    
    def __init__(
        self,
        minio_client: MinioClient,
        content_repo: Optional[IContentRepository] = None,
        author_repo: Optional[IAuthorRepository] = None,
        comment_repo: Optional[ICommentRepository] = None,
    ):
        self.minio_client = minio_client
        self.content_repo = content_repo
        self.author_repo = author_repo
        self.comment_repo = comment_repo
    
    async def archive_content(
        self,
        content: Content,
        author: Optional[Author] = None,
        comments: Optional[List[Comment]] = None,
        job_id: Optional[str] = None,
        keyword: Optional[str] = None,
        # NEW: Per-operation toggles
        save_to_minio: bool = True,
        save_to_db: bool = False,
    ) -> str:
        """Archive content to storage backends"""
        
        minio_key = None
        
        # Save to MinIO if enabled
        if save_to_minio:
            # Build archive data
            archive_data = {
                'content': content.to_dict(),
                'author': author.to_dict() if author else None,
                'comments': [c.to_dict() for c in comments] if comments else [],
                'metadata': {
                    'job_id': job_id,
                    'keyword': keyword,
                    'archived_at': datetime.utcnow().isoformat(),
                }
            }
            
            # Upload to MinIO
            minio_key = await self.minio_client.upload_json(
                bucket=settings.minio_archive_bucket,
                key=f"{content.content_id}.json",
                data=archive_data,
                compress=settings.compression_enabled,
            )
            
            logger.info(f"Archived content to MinIO: {minio_key}")
        
        # Save to MongoDB if enabled
        if save_to_db:
            if not self.content_repo:
                logger.warning("MongoDB save requested but content_repo not available")
            else:
                # Save content
                await self.content_repo.save_content(content)
                
                # Save author if provided
                if author and self.author_repo:
                    await self.author_repo.save_author(author)
                
                # Save comments if provided
                if comments and self.comment_repo:
                    for comment in comments:
                        await self.comment_repo.save_comment(comment)
                
                logger.info(f"Saved content to MongoDB: {content.content_id}")
        
        return minio_key or f"no-minio-{content.content_id}"
```

**Rationale**: Implement conditional storage based on flags.

---

### Phase 4: Update Configuration

#### 4.1 Update Settings Documentation
**File**: `scrapper/tiktok/config/settings.py`

**Changes**:
- Add comments explaining that these are defaults

```python
class Settings(BaseSettings):
    # ... existing code ...
    
    # ========== Archival Settings ==========
    enable_json_archive: bool = True  # Enable flat file archival of scraped data
    minio_archive_bucket: str = "tiktok-archive"  # MinIO bucket for archived JSON data
    enable_db_persistence: bool = False  # DEFAULT: Enable MongoDB persistence (can be overridden per-message)
    
    # ========== Media Download Settings ==========
    media_download_dir: str = "./downloads"  # Storage prefix (MinIO)
    media_download_enabled: bool = True  # DEFAULT: Enable media downloads (can be overridden per-message)
    media_default_type: str = "audio"  # Default media type: "audio" or "video"
```

---

### Phase 5: Testing

#### 5.1 Unit Tests
**File**: `scrapper/tiktok/tests/unit/test_task_service_payload_options.py`

**Create new test file**:

```python
"""
Unit tests for payload-based configuration options
"""
import pytest
from unittest.mock import AsyncMock, MagicMock
from application.task_service import TaskService


@pytest.mark.asyncio
async def test_crawl_links_with_media_disabled():
    """Test crawl_links with media_download_enabled=False"""
    # Setup mocks
    crawler_service = AsyncMock()
    job_repo = AsyncMock()
    content_repo = AsyncMock()
    
    task_service = TaskService(
        crawler_service=crawler_service,
        job_repo=job_repo,
        content_repo=content_repo,
    )
    
    # Prepare payload
    payload = {
        'video_urls': ['https://tiktok.com/@user/video/123'],
        'media_download_enabled': False,  # Disable media
        'save_to_db_enabled': False,
    }
    
    # Mock responses
    job_repo.create_job.return_value = True
    job_repo.update_job_status.return_value = True
    crawler_service.fetch_videos_batch.return_value = []
    
    # Execute
    result = await task_service.handle_task(
        task_type='crawl_links',
        payload=payload,
        job_id='test-job-1'
    )
    
    # Verify crawler_service was called with correct options
    crawler_service.fetch_videos_batch.assert_called_once()
    call_kwargs = crawler_service.fetch_videos_batch.call_args.kwargs
    assert call_kwargs['media_download_enabled'] == False
    assert call_kwargs['save_to_db_enabled'] == False


@pytest.mark.asyncio
async def test_crawl_links_with_db_enabled():
    """Test crawl_links with save_to_db_enabled=True"""
    # Setup mocks
    crawler_service = AsyncMock()
    job_repo = AsyncMock()
    content_repo = AsyncMock()
    
    task_service = TaskService(
        crawler_service=crawler_service,
        job_repo=job_repo,
        content_repo=content_repo,
    )
    
    # Prepare payload
    payload = {
        'video_urls': ['https://tiktok.com/@user/video/123'],
        'media_download_enabled': True,
        'save_to_db_enabled': True,  # Enable DB
    }
    
    # Mock responses
    job_repo.create_job.return_value = True
    job_repo.update_job_status.return_value = True
    crawler_service.fetch_videos_batch.return_value = []
    
    # Execute
    result = await task_service.handle_task(
        task_type='crawl_links',
        payload=payload,
        job_id='test-job-2'
    )
    
    # Verify
    call_kwargs = crawler_service.fetch_videos_batch.call_args.kwargs
    assert call_kwargs['save_to_db_enabled'] == True


@pytest.mark.asyncio
async def test_default_values_used_when_not_in_payload():
    """Test that defaults from settings are used when not in payload"""
    # Setup mocks
    crawler_service = AsyncMock()
    job_repo = AsyncMock()
    content_repo = AsyncMock()
    
    task_service = TaskService(
        crawler_service=crawler_service,
        job_repo=job_repo,
        content_repo=content_repo,
        default_download_media=True,
    )
    
    # Prepare payload WITHOUT options
    payload = {
        'video_urls': ['https://tiktok.com/@user/video/123'],
        # No media_download_enabled or save_to_db_enabled
    }
    
    # Mock responses
    job_repo.create_job.return_value = True
    job_repo.update_job_status.return_value = True
    crawler_service.fetch_videos_batch.return_value = []
    
    # Execute
    result = await task_service.handle_task(
        task_type='crawl_links',
        payload=payload,
        job_id='test-job-3'
    )
    
    # Verify defaults were used
    call_kwargs = crawler_service.fetch_videos_batch.call_args.kwargs
    assert 'media_download_enabled' in call_kwargs
    assert 'save_to_db_enabled' in call_kwargs
```

#### 5.2 Integration Tests
**File**: `scrapper/tiktok/tests/integration/test_payload_options_integration.py`

**Create new test file**:

```python
"""
Integration tests for payload-based configuration
"""
import pytest
from application.task_service import TaskService
from application.crawler_service import CrawlerService
# ... other imports ...


@pytest.mark.integration
@pytest.mark.asyncio
async def test_end_to_end_with_db_disabled(test_db, test_minio):
    """Test full flow with MongoDB disabled"""
    # Setup real services
    task_service = create_task_service(
        db=test_db,
        minio=test_minio,
    )
    
    # Execute with DB disabled
    result = await task_service.handle_task(
        task_type='crawl_links',
        payload={
            'video_urls': ['https://tiktok.com/@test/video/123'],
            'save_to_db_enabled': False,
        },
        job_id='integration-test-1'
    )
    
    # Verify: MinIO has data, MongoDB does not
    assert result['success'] == True
    
    # Check MinIO
    minio_keys = await test_minio.list_objects('tiktok-archive')
    assert len(minio_keys) > 0
    
    # Check MongoDB (should be empty)
    content_count = await test_db.content.count_documents({})
    assert content_count == 0
```

---

### Phase 6: Documentation Updates

#### 6.1 Update README
**File**: `scrapper/tiktok/README.md`

Add section explaining payload options:

```markdown
## Payload Configuration Options

You can control worker behavior per-message using payload options:

### media_download_enabled
- **Type**: boolean
- **Default**: true
- **Description**: Enable/disable media file downloads for this task

### save_to_db_enabled
- **Type**: boolean
- **Default**: false
- **Description**: Enable/disable MongoDB persistence for this task

### Example

```json
{
  "task_type": "crawl_links",
  "payload": {
    "video_urls": ["https://tiktok.com/@user/video/123"],
    "media_download_enabled": false,
    "save_to_db_enabled": true
  }
}
```
```

---

## Code Conventions to Follow

1. **Type Hints**: Always use type hints for function parameters and return values
2. **Docstrings**: Use Google-style docstrings with Args, Returns, Raises sections
3. **Logging**: Use structured logging with appropriate levels (DEBUG, INFO, ERROR)
4. **Error Handling**: Catch specific exceptions, log with context
5. **Async/Await**: Use async/await consistently, don't mix with sync code
6. **Naming**: 
   - Classes: PascalCase
   - Functions/methods: snake_case
   - Constants: UPPER_SNAKE_CASE
   - Private methods: _leading_underscore
7. **Imports**: Group by standard library, third-party, local (separated by blank lines)
8. **Comments**: Use `# NEW:` prefix for new code during implementation

## Testing Strategy

1. **Unit Tests**: Test each method in isolation with mocks
2. **Integration Tests**: Test full flow with real dependencies
3. **Coverage**: Aim for >80% code coverage
4. **Test Data**: Use fixtures for reusable test data

## Rollout Plan

1. **Phase 1**: Implement domain changes (low risk)
2. **Phase 2**: Update application layer (medium risk)
3. **Phase 3**: Update infrastructure (medium risk)
4. **Phase 4**: Update configuration (low risk)
5. **Phase 5**: Add tests (validation)
6. **Phase 6**: Update documentation (communication)

## Backward Compatibility

- Settings remain as defaults
- Existing messages without new fields will use defaults
- No breaking changes to existing API

## Estimated Effort

- Development: 4-6 hours
- Testing: 2-3 hours
- Documentation: 1 hour
- **Total**: 7-10 hours
