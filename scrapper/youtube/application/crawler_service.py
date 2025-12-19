"""
Crawler Service - Application Layer (YouTube)
Main orchestration service for crawling YouTube content using the unified schema.
"""

import asyncio
import re
import json
from typing import List, Dict, Any, Optional, Literal
from datetime import datetime, timezone, timedelta
from utils.helpers import map_to_new_format
from domain import Content, Author, Comment
from domain.enums import SourcePlatform, MediaType, ParentType
from .interfaces import (
    IContentRepository,
    IAuthorRepository,
    ICommentRepository,
    IVideoScraper,
    IAuthorScraper,
    ICommentScraper,
    ISearchScraper,
    IChannelScraper,
    IMediaDownloader,
    IStorageService,
)
from utils.logger import logger


class CrawlResult:
    """Result of a crawl operation."""

    def __init__(
        self,
        content: Optional[Content] = None,
        author: Optional[Author] = None,
        comments: Optional[List[Comment]] = None,
        url: str = "",
        success: bool = False,
        error_message: Optional[str] = None,
        skipped: bool = False,
        skip_reason: Optional[str] = None,
    ):
        self.content = content
        self.author = author
        self.comments = comments or []
        self.url = url
        self.success = success
        self.error_message = error_message
        self.skipped = skipped
        self.skip_reason = skip_reason
        self.minio_key: Optional[str] = None  # MinIO object key for uploaded content

        # NEW: Track what was enabled for this specific crawl
        self.media_downloaded: bool = False  # Was media actually downloaded
        self.saved_to_db: bool = False  # Was data saved to MongoDB
        self.archived_to_minio: bool = False  # Was data archived to MinIO

        # Enhanced error reporting
        self.error_code: Optional[str] = (
            None  # ErrorCode value for structured reporting
        )
        self.error_response: Optional[Dict[str, Any]] = (
            None  # Full structured error response
        )


class CrawlerService:
    """Coordinates scraping, media download, and data persistence for YouTube."""

    def __init__(
        self,
        content_repo: IContentRepository,
        author_repo: IAuthorRepository,
        comment_repo: ICommentRepository,
        video_scraper: IVideoScraper,
        author_scraper: IAuthorScraper,
        comment_scraper: ICommentScraper,
        search_scraper: ISearchScraper,
        channel_scraper: IChannelScraper,
        media_downloader: IMediaDownloader,
        max_concurrency: int = 8,
        gemini_summarizer: Optional[Any] = None,
        gemini_enabled: bool = False,
        archive_storage: Optional[IStorageService] = None,
        enable_db_persistence: bool = False,
        event_publisher: Optional[Any] = None,
    ):
        self.content_repo = content_repo
        self.author_repo = author_repo
        self.comment_repo = comment_repo
        self.video_scraper = video_scraper
        self.author_scraper = author_scraper
        self.comment_scraper = comment_scraper
        self.search_scraper = search_scraper
        self.channel_scraper = channel_scraper
        self.media_downloader = media_downloader
        self.max_concurrency = max(1, max_concurrency)
        self.gemini_summarizer = gemini_summarizer
        self.gemini_enabled = gemini_enabled
        self.archive_storage = archive_storage
        self.enable_db_persistence = enable_db_persistence
        self.event_publisher = event_publisher
        # Batch upload state
        self._batch_buffer: Dict[str, List[Dict[str, Any]]] = (
            {}
        )  # job_id -> list of items
        self._batch_index: Dict[str, int] = {}  # job_id -> current batch index
        self._batch_storage: Optional[IStorageService] = (
            None  # Will be set from bootstrap
        )

    async def archive_job_data(
        self,
        job_id: str,
        results: List[CrawlResult],
        keywords: Optional[List[str]] = None,
    ) -> Optional[str]:
        """
        Archive all crawled data for a job to MinIO as a single JSON file.
        Path: youtube/{job_id}.json
        """
        if not self.archive_storage:
            return None

        try:
            items = []
            for result in results:
                if not result.success or result.skipped or not result.content:
                    continue

                item = {
                    "content": result.content.dict(),
                    "author": result.author.dict() if result.author else None,
                    "comments": (
                        [c.dict() for c in result.comments] if result.comments else []
                    ),
                }
                items.append(item)

            if not items:
                logger.info(f"No items to archive for job {job_id}")
                return None

            data = {
                "job_id": job_id,
                "keywords": keywords or [],
                "archived_at": datetime.now(timezone.utc).isoformat(),
                "total_items": len(items),
                "items": items,
            }

            # Prepare path
            file_name = f"{job_id}.json"
            prefix = "youtube"
            object_name = f"{prefix}/{file_name}"

            logger.info(
                f"Archiving {len(items)} items for job {job_id} to {object_name}"
            )

            json_bytes = json.dumps(data, default=str).encode("utf-8")
            return await self.archive_storage.upload_bytes(
                data=json_bytes,
                object_name=object_name,
                content_type="application/json",
            )
        except Exception as e:
            logger.error(f"Failed to archive job data for {job_id}: {e}")
            return None

    # ========== Batch Upload Methods ==========

    def set_batch_storage(self, storage: Optional[IStorageService]) -> None:
        """Set the storage service for batch uploads."""
        self._batch_storage = storage

    async def add_to_batch(
        self,
        job_id: str,
        result: "CrawlResult",
        keyword: Optional[str] = None,
        task_type: Optional[str] = None,
        brand_name: Optional[str] = None,
        batch_size: int = 20,
    ) -> Optional[str]:
        """
        Add a crawl result to the batch buffer. Upload when batch is full.

        Args:
            job_id: Job identifier
            result: CrawlResult to add
            keyword: Search keyword context
            task_type: Task type for Collector routing
            brand_name: Brand name for event payload
            batch_size: Number of items per batch (default: 20 for YouTube)

        Returns:
            MinIO path if batch was uploaded, None otherwise
        """
        from utils.helpers import extract_project_id

        if not result.success or not result.content:
            return None

        # Initialize buffer for this job if needed
        if job_id not in self._batch_buffer:
            self._batch_buffer[job_id] = []
            self._batch_index[job_id] = 0

        # Convert result to new format
        item_data = map_to_new_format(
            result=result, job_id=job_id, keyword=keyword, task_type=task_type
        )
        self._batch_buffer[job_id].append(item_data)

        logger.debug(
            f"Added item to batch for job {job_id}: {len(self._batch_buffer[job_id])}/{batch_size}"
        )

        # Check if batch is full
        if len(self._batch_buffer[job_id]) >= batch_size:
            return await self._upload_batch(job_id, keyword, task_type, brand_name)

        return None

    async def _upload_batch(
        self,
        job_id: str,
        keyword: Optional[str] = None,
        task_type: Optional[str] = None,
        brand_name: Optional[str] = None,
    ) -> Optional[str]:
        """
        Upload current batch to MinIO and publish data.collected event.

        Path format: crawl-results/youtube/{project_id}/{brand|competitor}/batch_{index:03d}.json

        Args:
            job_id: Job identifier
            keyword: Search keyword context
            task_type: Task type for path determination
            brand_name: Brand name for event payload

        Returns:
            MinIO path if successful, None otherwise
        """
        from utils.helpers import extract_project_id, extract_brand_info

        if job_id not in self._batch_buffer or not self._batch_buffer[job_id]:
            return None

        if not self._batch_storage:
            logger.warning(
                f"Batch storage not configured, skipping batch upload for job {job_id}"
            )
            return None

        try:
            # Get batch data
            batch_data = self._batch_buffer[job_id]
            batch_index = self._batch_index[job_id]
            content_count = len(batch_data)

            # Extract project_id from job_id
            project_id = extract_project_id(job_id)
            if not project_id:
                logger.warning(
                    f"Could not extract project_id from job_id {job_id}, using job_id as fallback"
                )
                project_id = job_id

            # Extract brand_name from job_id if not provided
            effective_brand_name = brand_name
            if not effective_brand_name:
                extracted_brand, _ = extract_brand_info(job_id)
                effective_brand_name = extracted_brand or ""

            # Determine subfolder based on task_type or job_id pattern
            subfolder = "brand"  # Default
            if "-competitor" in job_id.lower() or (
                task_type and "competitor" in task_type.lower()
            ):
                subfolder = "competitor"

            # Build MinIO path: crawl-results/youtube/{project_id}/{brand|competitor}/batch_{index:03d}.json
            object_name = f"{project_id}/{subfolder}/batch_{batch_index:03d}.json"

            # Serialize batch to JSON
            json_bytes = json.dumps(
                batch_data, default=str, ensure_ascii=False, indent=2
            ).encode("utf-8")

            logger.info(
                f"Uploading batch {batch_index} for job {job_id}: {content_count} items to {object_name}"
            )

            # Upload to MinIO (using crawl-results bucket via prefix)
            minio_path = await self._batch_storage.upload_bytes(
                data=json_bytes,
                object_name=object_name,
                prefix="youtube",  # Will be: crawl-results/youtube/{project_id}/...
                content_type="application/json",
            )

            logger.info(f"Successfully uploaded batch {batch_index} to {minio_path}")

            # Publish data.collected event (Contract v2.0 compliant)
            if self.event_publisher and self.event_publisher.is_connected:
                try:
                    await self.event_publisher.publish_data_collected(
                        project_id=project_id,
                        job_id=job_id,
                        platform="youtube",
                        minio_path=minio_path,
                        content_count=content_count,
                        batch_index=batch_index + 1,  # 1-based for external consumers
                        task_type=task_type,
                        brand_name=effective_brand_name,
                        keyword=keyword,
                    )
                    logger.info(
                        f"Published data.collected event for batch {batch_index}"
                    )
                except Exception as event_error:
                    logger.error(
                        f"Failed to publish data.collected event: {event_error}"
                    )
                    # Don't fail the batch upload if event publishing fails

            # Clear buffer and increment index
            self._batch_buffer[job_id] = []
            self._batch_index[job_id] = batch_index + 1

            return minio_path

        except Exception as e:
            logger.error(f"Failed to upload batch for job {job_id}: {e}")
            return None

    async def flush_batch(
        self,
        job_id: str,
        keyword: Optional[str] = None,
        task_type: Optional[str] = None,
        brand_name: Optional[str] = None,
    ) -> Optional[str]:
        """
        Flush remaining items in batch buffer (for job completion).

        Args:
            job_id: Job identifier
            keyword: Search keyword context
            task_type: Task type for path determination
            brand_name: Brand name for event payload

        Returns:
            MinIO path if batch was uploaded, None otherwise
        """
        if job_id not in self._batch_buffer or not self._batch_buffer[job_id]:
            logger.debug(f"No remaining items to flush for job {job_id}")
            return None

        logger.info(
            f"Flushing {len(self._batch_buffer[job_id])} remaining items for job {job_id}"
        )
        return await self._upload_batch(job_id, keyword, task_type, brand_name)

    def clear_batch_state(self, job_id: str) -> None:
        """
        Clear batch state for a job (cleanup after job completion).

        Args:
            job_id: Job identifier
        """
        if job_id in self._batch_buffer:
            del self._batch_buffer[job_id]
        if job_id in self._batch_index:
            del self._batch_index[job_id]

    async def fetch_video_and_media(
        self,
        url: str,
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
        media_save_dir: str = "./YOUTUBE",
        include_channel: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        job_id: Optional[str] = None,
        keyword: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        save_to_db_enabled: bool = False,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> CrawlResult:
        """
        Fetch a single video/content item with optional media download, author, and comments.
        """
        result = CrawlResult(url=url)
        media_task: Optional[asyncio.Task[Optional[str]]] = None

        try:
            video_data = await self.video_scraper.scrape(url)
            if not video_data:
                result.error_message = "Failed to scrape video"
                return result

            if job_id:
                video_data["job_id"] = job_id

            content = self._map_video_to_content(video_data, job_id, keyword)
            result.content = content

            # Try AI summary generation (fast & cheap)
            ai_summary_success = False
            if self.gemini_enabled and self.gemini_summarizer:
                try:
                    logger.info(f"Attempting AI summary for {content.external_id}")
                    summary_metadata = {
                        "title": content.title,
                        "uploader": content.author_display_name,
                        "duration": content.duration_seconds,
                        "channel": content.author_username,
                        "url": content.url,
                    }
                    summary_text = await self.gemini_summarizer.summarize_video(
                        url=content.url, metadata=summary_metadata
                    )
                    if summary_text:
                        content.content_detail = summary_text
                        ai_summary_success = True
                        logger.info(
                            f"AI summary generated successfully for {content.external_id}: "
                            f"{len(summary_text)} chars"
                        )
                except Exception as exc:
                    logger.warning(
                        f"AI summary failed for {content.external_id}: {exc}. "
                        f"Will try media download if enabled."
                    )

            content_within_range = self._is_within_time_range(
                content.published_at, time_range_days, since_date, until_date
            )

            filtered_comments_data: List[Dict[str, Any]] = []
            if include_comments:
                comments_data = await self.comment_scraper.scrape(
                    video_id=content.external_id, max_comments=max_comments
                )
                if comments_data:
                    should_filter_comments = (
                        time_range_days is not None
                        or since_date is not None
                        or until_date is not None
                    )

                    if not should_filter_comments:
                        filtered_comments_data = list(comments_data)
                    else:
                        for comment_data in comments_data:
                            comment_timestamp = self._parse_timestamp(
                                comment_data.get("published_at")
                            )
                            if comment_timestamp and self._is_within_time_range(
                                comment_timestamp,
                                time_range_days,
                                since_date,
                                until_date,
                            ):
                                filtered_comments_data.append(comment_data)

            should_persist_content = content_within_range or bool(
                filtered_comments_data
            )
            if not should_persist_content:
                reason = "Skipped content outside allowed date range"
                result.skipped = True
                result.skip_reason = reason
                result.error_message = reason
                return result

            video_download_url = video_data.get("video_download_url")
            audio_url = video_data.get("audio_url")

            # Fallback to media download if AI summary failed and download is enabled
            should_download_media = download_media and (video_download_url or audio_url)

            # Smart fallback: only download if AI summary failed
            if should_download_media and not ai_summary_success:
                logger.info(
                    f"AI summary unavailable, falling back to media download "
                    f"for {content.external_id}"
                )
                content.video_download_url = video_download_url
                content.audio_url = audio_url
                media_task = asyncio.create_task(
                    self.media_downloader.download_media(
                        content=content, media_type=media_type, save_dir=media_save_dir
                    )
                )
            elif ai_summary_success:
                logger.info(
                    f"AI summary successful, skipping media download "
                    f"for {content.external_id}"
                )

            # NEW: Use save_to_db_enabled from payload instead of self.enable_db_persistence
            if save_to_db_enabled:
                await self.content_repo.upsert_content(content)

            if include_channel and content.author_external_id:
                channel_data = await self.author_scraper.scrape(
                    content.author_external_id
                )
                if channel_data:
                    author = self._map_channel_to_author(channel_data)
                    # NEW: Use save_to_db_enabled from payload
                    if save_to_db_enabled:
                        await self.author_repo.upsert_author(author)
                    result.author = author

            if include_comments and filtered_comments_data:
                parent_id = await self._get_content_parent_id(content)
                comments = [
                    self._map_comment_to_comment(comment_data, parent_id, job_id)
                    for comment_data in filtered_comments_data
                ]
                comments = [c for c in comments if c]
                if comments:
                    # NEW: Use save_to_db_enabled from payload
                    if save_to_db_enabled:
                        await self.comment_repo.upsert_comments(comments)
                    result.comments = comments

            if media_task:
                try:
                    media_location = await media_task
                except Exception as media_error:
                    logger.error(
                        "Media download failed for %s: %s",
                        content.external_id,
                        media_error,
                    )
                    media_location = None

                if media_location:
                    media_enum = (
                        MediaType.VIDEO if media_type == "video" else MediaType.AUDIO
                    )
                    content.mark_media_downloaded(media_location, media_enum)
                    # NEW: Use save_to_db_enabled from payload
                    if save_to_db_enabled:
                        await self.content_repo.upsert_content(content)

            result.success = True
            # NEW: Track what was actually done
            result.media_downloaded = download_media and (
                content.media_path is not None
            )
            result.saved_to_db = save_to_db_enabled

            # Upload individual item to MinIO (AFTER media download to capture URLs/paths)
            # NEW: Only upload if archive_storage_enabled is True
            if (
                archive_storage_enabled
                and self.archive_storage
                and job_id
                and result.content
                and result.success
            ):
                try:
                    # Generate unique filename
                    object_name = self._generate_unique_filename(
                        job_id=job_id,
                        keyword=keyword,
                        content_external_id=result.content.external_id,
                        time_range_days=time_range_days,
                        since_date=since_date,
                        until_date=until_date,
                    )

                    # Prepare item data in new format
                    item_data = map_to_new_format(
                        result=result,
                        job_id=job_id,
                        keyword=keyword,
                        task_type=task_type,
                    )

                    # Serialize to JSON
                    json_bytes = json.dumps(item_data, default=str, indent=2).encode(
                        "utf-8"
                    )

                    # Upload to MinIO
                    logger.info(
                        f"Uploading content {result.content.external_id} to MinIO: youtube/{object_name}"
                    )

                    minio_key = await self.archive_storage.upload_bytes(
                        data=json_bytes,
                        object_name=object_name,
                        prefix="youtube",
                        content_type="application/json",
                    )

                    # Store MinIO key in result
                    result.minio_key = minio_key
                    result.archived_to_minio = True
                    logger.info(
                        f"Successfully uploaded content {result.content.external_id} to {minio_key}"
                    )

                except Exception as upload_error:
                    logger.error(
                        f"Failed to upload content {result.content.external_id} to MinIO: {upload_error}"
                    )
                    # Don't fail the entire crawl if upload fails
                    result.minio_key = None
                    result.archived_to_minio = False
            elif not archive_storage_enabled:
                logger.info(
                    f"Archive storage disabled for {result.content.external_id if result.content else url} - skipping MinIO upload"
                )
                result.archived_to_minio = False
            else:
                result.archived_to_minio = False

        except Exception as exc:
            from utils.errors import (
                build_error_from_exception,
                map_exception_to_error_code,
            )

            # Build structured error response
            error_response = build_error_from_exception(
                exc=exc,
                url=url,
                job_id=job_id,
                content_id=result.content.external_id if result.content else None,
            )

            # Log with error code for easier debugging
            error_code = map_exception_to_error_code(exc)
            logger.error(
                f"Crawl failed for {url}: [{error_code.value}] {str(exc)}",
                extra={"error_response": error_response},
            )

            result.error_message = str(exc)
            result.error_code = error_code.value  # Store error code in result
            result.error_response = error_response  # Store full error response
            result.success = False
            # Track failures
            result.media_downloaded = False
            result.saved_to_db = False
            result.archived_to_minio = False
            if media_task:
                media_task.cancel()
                try:
                    await media_task
                except asyncio.CancelledError:
                    pass

        return result

    async def fetch_videos_batch(
        self,
        urls: List[str],
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
        media_save_dir: str = "./YOUTUBE",
        include_channel: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        job_id: Optional[str] = None,
        keyword: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        media_download_enabled: bool = True,
        save_to_db_enabled: bool = True,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> List[CrawlResult]:
        """Fetch multiple videos concurrently."""
        if not urls:
            return []

        semaphore = asyncio.Semaphore(self.max_concurrency)

        async def _run(target_url: str) -> CrawlResult:
            async with semaphore:
                return await self.fetch_video_and_media(
                    url=target_url,
                    download_media=download_media
                    and media_download_enabled,  # NEW: Combine flags
                    media_type=media_type,
                    media_save_dir=media_save_dir,
                    include_channel=include_channel,
                    include_comments=include_comments,
                    max_comments=max_comments,
                    job_id=job_id,
                    keyword=keyword,
                    time_range_days=time_range_days,
                    since_date=since_date,
                    until_date=until_date,
                    save_to_db_enabled=save_to_db_enabled,  # NEW: Pass storage option
                    archive_storage_enabled=archive_storage_enabled,  # NEW: Pass archive option
                    task_type=task_type,  # NEW: Pass task type for Collector routing
                )

        tasks = [asyncio.create_task(_run(video_url)) for video_url in urls]
        return await asyncio.gather(*tasks)

    async def search_videos(
        self, keyword: str, limit: int = 50, sort_by: str = "relevance"
    ) -> List[str]:
        """Search YouTube for video URLs via the configured search scraper."""
        return await self.search_scraper.search_videos(
            keyword=keyword, limit=limit, sort_by=sort_by
        )

    async def search_and_fetch(
        self,
        keyword: str,
        limit: int = 50,
        sort_by: str = "relevance",
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
        media_save_dir: str = "./YOUTUBE",
        include_channel: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        job_id: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        media_download_enabled: bool = True,
        save_to_db_enabled: bool = True,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Search for videos and fetch them in sequence."""
        video_urls = await self.search_videos(keyword, limit, sort_by)

        if not video_urls:
            return {
                "keyword": keyword,
                "video_urls": [],
                "crawl_results": [],
                "success": False,
                "error": "No videos found",
            }

        crawl_results = await self.fetch_videos_batch(
            urls=video_urls,
            download_media=download_media,
            media_type=media_type,
            media_save_dir=media_save_dir,
            include_channel=include_channel,
            include_comments=include_comments,
            max_comments=max_comments,
            job_id=job_id,
            keyword=keyword,
            time_range_days=time_range_days,
            since_date=since_date,
            until_date=until_date,
            # NEW: Pass storage options
            media_download_enabled=media_download_enabled,
            save_to_db_enabled=save_to_db_enabled,
            archive_storage_enabled=archive_storage_enabled,
            task_type=task_type,  # NEW: Pass task type for Collector routing
        )

        successful = sum(1 for r in crawl_results if r.success)
        skipped = sum(1 for r in crawl_results if r.skipped)
        failed = max(len(video_urls) - successful - skipped, 0)

        return {
            "keyword": keyword,
            "video_urls": video_urls,
            "crawl_results": crawl_results,
            "total": len(video_urls),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "success": successful > 0,
        }

    async def fetch_channel_videos(
        self,
        channel_url: str,
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
        media_save_dir: str = "./YOUTUBE",
        include_channel: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        limit: int = 0,
        job_id: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        media_download_enabled: bool = True,
        save_to_db_enabled: bool = True,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Fetch all videos from a YouTube channel within specified time range.

        This method:
        1. Scrapes video URLs from the channel page
        2. Delegates to fetch_videos_batch for processing
        3. Returns results with MinIO keys for tracking

        Args:
            channel_url: YouTube channel URL (e.g., https://www.youtube.com/@username)
            download_media: Whether to download media
            media_type: Type of media to download
            media_save_dir: Storage prefix for media
            include_channel: Whether to scrape channel info
            include_comments: Whether to scrape comments
            max_comments: Maximum comments per video
            limit: Maximum number of videos to fetch (0 = unlimited)
            job_id: Optional job ID
            time_range_days: Only persist content within this many days
            since_date: Filter content published on or after this date
            until_date: Filter content published on or before this date

        Returns:
            Dict with channel URL, video URLs, and crawl results
        """
        logger.info(f"Fetching channel videos from: {channel_url} (limit={limit})")

        # Step 1: Extract video URLs from channel page
        video_urls = await self.channel_scraper.get_channel_video_urls(
            channel_url=channel_url,
            limit=limit,  # Get all available videos, filtering happens in fetch_videos_batch
        )

        if not video_urls:
            return {
                "channel_url": channel_url,
                "video_urls": [],
                "crawl_results": [],
                "success": False,
                "error": "No videos found on channel",
            }

        logger.info(f"Found {len(video_urls)} videos on channel, starting crawl...")

        # Step 2: Process videos using existing batch logic
        # This handles time filtering, media download, and MinIO upload
        crawl_results = await self.fetch_videos_batch(
            urls=video_urls,
            download_media=download_media,
            media_type=media_type,
            media_save_dir=media_save_dir,
            include_channel=include_channel,
            include_comments=include_comments,
            max_comments=max_comments,
            job_id=job_id,
            keyword=None,  # No keyword for channel crawls
            time_range_days=time_range_days,
            since_date=since_date,
            until_date=until_date,
            # NEW: Pass storage options
            media_download_enabled=media_download_enabled,
            save_to_db_enabled=save_to_db_enabled,
            archive_storage_enabled=archive_storage_enabled,
            task_type=task_type,  # NEW: Pass task type for Collector routing
        )

        successful = sum(1 for r in crawl_results if r.success)
        skipped = sum(1 for r in crawl_results if r.skipped)
        failed = max(len(video_urls) - successful - skipped, 0)

        logger.info(
            f"Channel crawl complete: {successful} successful, {skipped} skipped, {failed} failed"
        )

        return {
            "channel_url": channel_url,
            "video_urls": video_urls,
            "crawl_results": crawl_results,
            "total": len(video_urls),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "success": successful > 0,
        }

    async def _get_content_parent_id(self, content: Content) -> str:
        """Fetch MongoDB _id for a content document (fallback to external_id)."""
        saved_content = await self.content_repo.get_content(
            SourcePlatform.YOUTUBE.value, content.external_id
        )
        if saved_content and "_id" in saved_content:
            return str(saved_content["_id"])
        return content.external_id

    def _map_video_to_content(
        self,
        video_data: Dict[str, Any],
        job_id: Optional[str] = None,
        job_keyword: Optional[str] = None,
    ) -> Content:
        """Map scraped video data to the Content entity."""
        author_external_id = video_data.get("channel_id")

        content_data = {
            "source": SourcePlatform.YOUTUBE,
            "external_id": video_data.get("video_id"),
            "url": video_data.get("url"),
            "job_id": job_id,
            "author_id": author_external_id,
            "author_external_id": author_external_id,
            "author_username": video_data.get("channel_custom_url"),
            "author_display_name": video_data.get("channel_title"),
            "title": video_data.get("title"),
            "description": video_data.get("description"),
            "duration_seconds": video_data.get("duration", 0),
            "sound_name": None,
            "category": video_data.get("category"),
            "tags": video_data.get("tags", []),
            "media_type": MediaType.VIDEO,
            "media_path": video_data.get("media_path"),
            "media_downloaded_at": video_data.get("media_downloaded_at"),
            "view_count": video_data.get("view_count", 0),
            "like_count": video_data.get("like_count", 0),
            "comment_count": video_data.get("comment_count", 0),
            "share_count": None,
            "save_count": None,
            "published_at": self._parse_timestamp(video_data.get("published_at")),
            "crawled_at": datetime.now(timezone.utc),
            "keyword": video_data.get("keyword") or job_keyword,
            "extra_json": video_data.get("extra_json") or {},
        }

        content = Content(**content_data)
        content.video_download_url = video_data.get("video_download_url")
        content.audio_url = video_data.get("audio_url")
        return content

    def _map_channel_to_author(self, channel_data: Dict[str, Any]) -> Author:
        """Map scraped channel data to the Author entity."""
        author_data = {
            "source": SourcePlatform.YOUTUBE,
            "external_id": channel_data.get("channel_id") or channel_data.get("id"),
            "profile_url": channel_data.get("url"),
            "username": channel_data.get("custom_url"),
            "display_name": channel_data.get("channel_title"),
            "verified": channel_data.get("verified"),
            "follower_count": channel_data.get("subscriber_count", 0),
            "following_count": None,
            "like_count": None,
            "video_count": channel_data.get("video_count", 0),
            "crawled_at": datetime.now(timezone.utc),
            "extra_json": {
                "description": channel_data.get("description"),
                "country": channel_data.get("country"),
                "total_view_count": channel_data.get("view_count"),
            },
        }
        return Author(**author_data)

    def _map_comment_to_comment(
        self, comment_data: Dict[str, Any], parent_id: str, job_id: Optional[str] = None
    ) -> Optional[Comment]:
        """Map comment scraper data to the Comment entity."""
        external_id = comment_data.get("comment_id")
        if not external_id:
            return None

        extra_json = {
            "author_channel_id": comment_data.get("author_channel_id"),
            "parent_comment_external_id": comment_data.get("parent_id"),
            "is_favorited": comment_data.get("is_favorited"),
        }

        comment_entity = {
            "source": SourcePlatform.YOUTUBE,
            "external_id": external_id,
            "parent_type": ParentType.CONTENT,
            "parent_id": parent_id,
            "job_id": job_id,
            "comment_text": comment_data.get("comment_text"),
            "commenter_name": comment_data.get("author_name"),
            "like_count": comment_data.get("like_count"),
            "reply_count": comment_data.get("reply_count"),
            "published_at": self._parse_timestamp(comment_data.get("published_at")),
            "crawled_at": datetime.now(timezone.utc),
            "extra_json": extra_json,
        }
        return Comment(**comment_entity)

    def _parse_timestamp(self, timestamp_value: Optional[Any]) -> Optional[datetime]:
        """Parse timestamps (ISO, unix, relative strings) into timezone-aware datetimes."""
        if timestamp_value is None:
            return None

        now = datetime.now(timezone.utc)

        if isinstance(timestamp_value, datetime):
            return (
                timestamp_value
                if timestamp_value.tzinfo
                else timestamp_value.replace(tzinfo=timezone.utc)
            )

        if isinstance(timestamp_value, (int, float)):
            try:
                return datetime.fromtimestamp(timestamp_value, tz=timezone.utc)
            except (ValueError, OSError):
                return None

        normalized = str(timestamp_value).strip()
        if not normalized:
            return None

        try:
            parsed = datetime.fromisoformat(normalized.replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            pass

        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
            try:
                parsed = datetime.strptime(normalized, fmt)
                return parsed.replace(tzinfo=timezone.utc)
            except ValueError:
                continue

        month_day_match = re.match(
            r"^(?P<month>\d{1,2})[-/](?P<day>\d{1,2})(?:\s+(?P<hour>\d{1,2}):(?P<minute>\d{1,2}))?$",
            normalized,
        )
        if month_day_match:
            month = int(month_day_match.group("month"))
            day = int(month_day_match.group("day"))
            hour = int(month_day_match.group("hour") or 0)
            minute = int(month_day_match.group("minute") or 0)
            try:
                parsed = datetime(
                    now.year, month, day, hour, minute, tzinfo=timezone.utc
                )
            except ValueError:
                return None
            if parsed > now + timedelta(days=1):
                parsed = parsed.replace(year=now.year - 1)
            return parsed

        lower = normalized.lower()
        if lower in {"now", "just now"}:
            return now

        if lower.endswith("ago"):
            lower = lower[:-3].strip()

        relative_match = re.match(r"(?P<value>\d+)\s*(?P<unit>[a-z]+)", lower)
        if relative_match:
            value = int(relative_match.group("value"))
            unit = relative_match.group("unit")
            unit_map = {
                "s": 1,
                "sec": 1,
                "second": 1,
                "seconds": 1,
                "m": 60,
                "min": 60,
                "mins": 60,
                "minute": 60,
                "minutes": 60,
                "h": 3600,
                "hr": 3600,
                "hrs": 3600,
                "hour": 3600,
                "hours": 3600,
                "d": 86400,
                "day": 86400,
                "days": 86400,
                "w": 604800,
                "week": 604800,
                "weeks": 604800,
                "mon": 2592000,
                "month": 2592000,
                "months": 2592000,
                "y": 31536000,
                "yr": 31536000,
                "year": 31536000,
                "years": 31536000,
            }
            seconds = unit_map.get(unit)
            if seconds:
                return now - timedelta(seconds=value * seconds)

        return None

    def _generate_unique_filename(
        self,
        job_id: str,
        keyword: Optional[str],
        content_external_id: str,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> str:
        """
        Generate unique filename for MinIO upload

        Format: {keyword}_{content_id}_{timestamp}.json
        """
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

        # Sanitize keyword
        safe_keyword = "unknown"
        if keyword:
            safe_keyword = (
                re.sub(r"[^\w\s-]", "", keyword).strip().replace(" ", "_")[:50]
            )

        # Build filename components
        filename_parts = [safe_keyword, content_external_id, timestamp]

        # Add time range info if present
        if since_date or until_date:
            if since_date:
                filename_parts.append(f"from{since_date.strftime('%Y%m%d')}")
            if until_date:
                filename_parts.append(f"to{until_date.strftime('%Y%m%d')}")
        elif time_range_days:
            filename_parts.append(f"range{time_range_days}d")

        filename = "_".join(filename_parts) + ".json"

        # Return full object key with job_id prefix
        return f"{job_id}/{filename}"

    def _is_within_time_range(
        self,
        published_at: Optional[datetime],
        time_range_days: Optional[int],
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> bool:
        """
        Check if published_at falls within the specified date range.

        Priority:
        1. explicit since_date / until_date
        2. time_range_days (last N days)
        """
        # If no constraints, everything is allowed
        if time_range_days is None and since_date is None and until_date is None:
            return True

        if published_at is None:
            return False

        timestamp = (
            published_at
            if published_at.tzinfo
            else published_at.replace(tzinfo=timezone.utc)
        )

        # Ensure comparison dates are UTC aware
        if since_date and since_date.tzinfo is None:
            since_date = since_date.replace(tzinfo=timezone.utc)
        if until_date and until_date.tzinfo is None:
            until_date = until_date.replace(tzinfo=timezone.utc)

        # Check Until Date (End Bound)
        if until_date and timestamp > until_date:
            return False

        # Check Since Date (Start Bound)
        if since_date:
            if timestamp < since_date:
                return False
        elif time_range_days is not None:
            # Fallback to time_range if no explicit since_date
            now = datetime.now(timezone.utc)
            lower_bound = now - timedelta(days=time_range_days)
            if timestamp < lower_bound:
                return False

        return True
