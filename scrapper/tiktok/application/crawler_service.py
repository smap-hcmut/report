"""
Crawler Service - Application Layer
Main orchestration service for crawling TikTok content
Updated to match refactor_modelDB.md schema
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
    ICreatorScraper,
    ICommentScraper,
    ISearchScraper,
    IProfileScraper,
    IMediaDownloader,
    IArchiveStorage,
)


class CrawlResult:
    """Result of a crawl operation"""

    def __init__(
        self,
        content: Optional[Content] = None,  # Changed from video
        author: Optional[Author] = None,  # Changed from creator
        comments: Optional[List[Comment]] = None,
        url: str = "",
        success: bool = False,
        error_message: Optional[str] = None,
        skipped: bool = False,
        skip_reason: Optional[str] = None,
    ):
        self.content = content  # Changed from video
        self.author = author  # Changed from creator
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
    """
    Crawler Service - Main Orchestration

    Coordinates scraping, media download, and data persistence.
    This is the primary use case service for TikTok crawling.
    Updated to use new Content/Author entities with source="TIKTOK"
    """

    def __init__(
        self,
        content_repo: IContentRepository,  # Changed from video_repo
        author_repo: IAuthorRepository,  # Changed from creator_repo
        comment_repo: ICommentRepository,
        video_scraper: IVideoScraper,
        creator_scraper: ICreatorScraper,
        comment_scraper: ICommentScraper,
        search_scraper: ISearchScraper,
        profile_scraper: IProfileScraper,
        media_downloader: IMediaDownloader,
        max_concurrency: int = 8,
        archive_storage: Optional[IArchiveStorage] = None,
        enable_db_persistence: bool = False,
        speech2text_client: Optional["ISpeech2TextClient"] = None,  # STT client
        event_publisher: Optional[
            Any
        ] = None,  # DataCollectedEventPublisher for batch events
    ):
        """
        Initialize crawler service with dependencies

        Args:
            content_repo: Content repository implementation
            author_repo: Author repository implementation
            comment_repo: Comment repository implementation
            video_scraper: Video scraper implementation
            creator_scraper: Creator scraper implementation
            comment_scraper: Comment scraper implementation
            search_scraper: Search scraper implementation
            media_downloader: Media downloader implementation
            max_concurrency: Maximum concurrent crawl workers
            archive_storage: Optional storage for archiving JSON data
            speech2text_client: Optional STT client for audio transcription
            event_publisher: Optional event publisher for data.collected events
        """
        self.content_repo = content_repo  # Changed from video_repo
        self.author_repo = author_repo  # Changed from creator_repo
        self.comment_repo = comment_repo
        self.video_scraper = video_scraper
        self.creator_scraper = creator_scraper
        self.comment_scraper = comment_scraper
        self.search_scraper = search_scraper
        self.profile_scraper = profile_scraper
        self.media_downloader = media_downloader
        self.max_concurrency = max(1, max_concurrency)
        self.archive_storage = archive_storage
        self.enable_db_persistence = enable_db_persistence
        self.speech2text_client = speech2text_client  # Store STT client
        self.event_publisher = (
            event_publisher  # Store event publisher for data.collected events
        )
        # Batch upload state
        self._batch_buffer: Dict[str, List[Dict[str, Any]]] = (
            {}
        )  # job_id -> list of items
        self._batch_index: Dict[str, int] = {}  # job_id -> current batch index
        self._batch_storage = None  # Will be set from bootstrap if batch upload enabled

    def _map_video_to_content(
        self,
        video_data: Dict[str, Any],
        job_id: Optional[str] = None,
        job_keyword: Optional[str] = None,
    ) -> Content:
        """
        Map scraped video data to Content entity

        Maps old field names to new schema:
        - video_id → external_id
        - creator_username → author_username
        - hashtags → tags
        - upload_time → published_at (converted to datetime)
        - duration → duration_seconds
        Adds: source="TIKTOK", media_type=VIDEO
        """
        # Map old fields to new fields
        author_username = video_data.get("creator_username")
        author_external_id = author_username or video_data.get("creator_id")

        content_data = {
            "source": SourcePlatform.TIKTOK,
            "external_id": video_data.get("video_id"),
            "url": video_data.get("url"),
            "job_id": job_id,
            # Author info
            "author_id": author_external_id,
            "author_external_id": author_external_id,
            "author_username": author_username or author_external_id,
            "author_display_name": video_data.get("creator_display_name"),
            # Content metadata
            "description": video_data.get("description"),
            "duration_seconds": video_data.get("duration", 0),
            "sound_name": video_data.get("sound_name"),
            "tags": video_data.get("hashtags", []),  # hashtags → tags
            # Media
            "media_type": MediaType.VIDEO,
            "media_path": video_data.get("media_path"),
            "media_downloaded_at": video_data.get("media_downloaded_at"),
            "video_download_url": video_data.get("video_download_url"),
            "audio_url": video_data.get("audio_url"),
            # Metrics
            "view_count": video_data.get("view_count", 0),
            "like_count": video_data.get("like_count", 0),
            "comment_count": video_data.get("comment_count", 0),
            "share_count": video_data.get("share_count", 0),
            "save_count": video_data.get("save_count", 0),
            # Timestamps
            "published_at": self._parse_upload_time(video_data.get("upload_time")),
            "crawled_at": datetime.now(),
            # Search metadata
            "keyword": video_data.get("keyword") or job_keyword,
        }

        return Content(**content_data)

    def _parse_upload_time(self, upload_time: Optional[Any]) -> Optional[datetime]:
        """
        Parse upload_time to datetime (UTC). Supports ISO-8601 strings,
        Unix timestamps, and relative strings like '2d ago'.
        """
        if not upload_time:
            return None

        if isinstance(upload_time, datetime):
            return (
                upload_time
                if upload_time.tzinfo
                else upload_time.replace(tzinfo=timezone.utc)
            )

        if isinstance(upload_time, (int, float)):
            try:
                return datetime.fromtimestamp(upload_time, tz=timezone.utc)
            except (ValueError, OSError):
                return None

        if isinstance(upload_time, str):
            normalized = upload_time.strip()
            # ISO 8601
            try:
                iso_input = normalized.replace("Z", "+00:00")
                return datetime.fromisoformat(iso_input)
            except ValueError:
                pass

            # Relative formats like '2d ago'
            match = re.match(r"(?P<value>\d+)(?P<unit>[smhd])", normalized)
            if match:
                value = int(match.group("value"))
                unit = match.group("unit")
                delta_seconds = {
                    "s": value,
                    "m": value * 60,
                    "h": value * 3600,
                    "d": value * 86400,
                }.get(unit, 0)
                if delta_seconds:
                    return datetime.now(timezone.utc) - timedelta(seconds=delta_seconds)

        return None

    def _map_creator_to_author(
        self, creator_data: Dict[str, Any], job_id: Optional[str] = None
    ) -> Author:
        """
        Map scraped creator data to Author entity

        Maps old fields to new schema:
        - username → external_id + username
        - total_likes → like_count
        - total_videos → video_count
        - bio → extra_json.bio
        - partial_data → extra_json.partial_data
        Adds: source="TIKTOK"
        Note: job_id NOT included in Author (per schema)
        """
        extra_json = {}
        if "bio" in creator_data:
            extra_json["bio"] = creator_data["bio"]
        if "partial_data" in creator_data:
            extra_json["partial_data"] = creator_data["partial_data"]

        author_data = {
            "source": SourcePlatform.TIKTOK,
            "external_id": creator_data.get("username"),
            "username": creator_data.get("username"),
            "profile_url": creator_data.get("profile_url"),
            "display_name": creator_data.get("display_name"),
            "verified": creator_data.get("verified", False),
            # Stats
            "follower_count": creator_data.get("follower_count", 0),
            "following_count": creator_data.get("following_count", 0),
            "like_count": creator_data.get(
                "total_likes", 0
            ),  # total_likes → like_count
            "video_count": creator_data.get(
                "total_videos", 0
            ),  # total_videos → video_count
            # Timestamps
            "crawled_at": datetime.now(),
            # Extra
            "extra_json": extra_json,
        }

        return Author(**author_data)

    def _map_comment_to_comment(
        self,
        comment_data: Dict[str, Any],
        parent_id: str,  # MongoDB ObjectId of content | external_id of content
        job_id: Optional[str] = None,
    ) -> Comment:
        """
        Map scraped comment data to Comment entity

        Maps old fields to new schema:
        - comment_id → external_id
        - video_id → parent_id (MongoDB ObjectId)
        - timestamp → published_at
        Adds: source="TIKTOK", parent_type="CONTENT"
        """
        comment_entity_data = {
            "source": SourcePlatform.TIKTOK,
            "external_id": comment_data.get("comment_id"),
            "parent_type": ParentType.CONTENT,
            "parent_id": parent_id,  # Reference to content._id
            "job_id": job_id,
            # Content
            "comment_text": comment_data.get("comment_text"),
            "commenter_name": comment_data.get("commenter_name"),
            # Metrics
            "like_count": comment_data.get("like_count", 0),
            "reply_count": comment_data.get("reply_count", 0),
            # Timestamps
            "published_at": self._parse_comment_timestamp(
                comment_data.get("timestamp")
            ),
            "crawled_at": datetime.now(),
        }

        return Comment(**comment_entity_data)

    def _parse_comment_timestamp(self, timestamp: Optional[str]) -> Optional[datetime]:
        """
        Parse comment timestamp text or numeric value into an aware datetime (UTC).
        Supports ISO strings, Unix timestamps, "MM-DD", and relative strings like "2d ago".
        """
        if not timestamp:
            return None

        now = datetime.now(timezone.utc)

        if isinstance(timestamp, datetime):
            return (
                timestamp
                if timestamp.tzinfo
                else timestamp.replace(tzinfo=timezone.utc)
            )

        if isinstance(timestamp, (int, float)):
            try:
                return datetime.fromtimestamp(timestamp, tz=timezone.utc)
            except (ValueError, OSError):
                return None

        if isinstance(timestamp, str):
            normalized = timestamp.strip()
            if not normalized:
                return None

            iso_candidate = normalized.replace("Z", "+00:00")
            try:
                parsed = datetime.fromisoformat(iso_candidate)
                return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
            except ValueError:
                pass

            date_formats = [
                "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%d %H:%M",
                "%Y-%m-%d",
            ]
            for fmt in date_formats:
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

            relative_match = re.match(r"(?P<value>\d+)\s*(?P<unit>[smhdwy])", lower)
            if relative_match:
                value = int(relative_match.group("value"))
                unit = relative_match.group("unit")
                seconds_map = {
                    "s": 1,
                    "m": 60,
                    "h": 3600,
                    "d": 86400,
                    "w": 604800,
                    "y": 31536000,
                }
                multiplier = seconds_map.get(unit)
                if multiplier:
                    return now - timedelta(seconds=value * multiplier)

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
        If time range is specified, include it in the filename for traceability

        Args:
            job_id: Job ID
            keyword: Search keyword (optional)
            content_external_id: Content external ID
            time_range_days: Time range in days (optional)
            since_date: Since date (optional)
            until_date: Until date (optional)

        Returns:
            Unique filename string
        """
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

        # Sanitize keyword for filename (remove special characters)
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

        timestamp = published_at
        if timestamp.tzinfo is None:
            timestamp = timestamp.replace(tzinfo=timezone.utc)

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

    async def save_job_results(self, job_id: str, minio_keys: List[str]) -> bool:
        """
        Save MinIO object keys to crawl_jobs collection

        Args:
            job_id: Job ID
            minio_keys: List of MinIO object keys for uploaded content items

        Returns:
            True if successful, False otherwise
        """
        if not minio_keys:
            from utils.logger import logger

            logger.warning(f"No MinIO keys to save for job {job_id}")
            return True

        try:
            from utils.logger import logger

            logger.info(f"Saving {len(minio_keys)} MinIO keys for job {job_id}")

            # This will be called from TaskService which has access to job_repo
            # For now, just log - the actual DB update happens in TaskService
            return True

        except Exception as e:
            from utils.logger import logger

            logger.error(f"Failed to save job results for {job_id}: {e}")
            return False

    # ========== Batch Upload Methods ==========

    def set_batch_storage(self, storage: Optional[IArchiveStorage]) -> None:
        """Set the storage service for batch uploads."""
        self._batch_storage = storage

    async def add_to_batch(
        self,
        job_id: str,
        result: "CrawlResult",
        keyword: Optional[str] = None,
        task_type: Optional[str] = None,
        brand_name: Optional[str] = None,
        batch_size: int = 50,
    ) -> Optional[str]:
        """
        Add a crawl result to the batch buffer. Upload when batch is full.

        Args:
            job_id: Job identifier
            result: CrawlResult to add
            keyword: Search keyword context
            task_type: Task type for Collector routing
            brand_name: Brand name for event payload
            batch_size: Number of items per batch (default: 50)

        Returns:
            MinIO path if batch was uploaded, None otherwise
        """
        from utils.logger import logger
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

        Path format: crawl-results/{project_id}/{brand|competitor}/batch_{index:03d}.json

        Args:
            job_id: Job identifier
            keyword: Search keyword context
            task_type: Task type for path determination
            brand_name: Brand name for event payload

        Returns:
            MinIO path if successful, None otherwise
        """
        from utils.logger import logger
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

            # Build MinIO path: crawl-results/{project_id}/{brand|competitor}/batch_{index:03d}.json
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
                prefix="tiktok",  # Will be: crawl-results/tiktok/{project_id}/...
                content_type="application/json",
            )

            logger.info(f"Successfully uploaded batch {batch_index} to {minio_path}")

            # Publish data.collected event (Contract v2.0 compliant)
            if self.event_publisher and self.event_publisher.is_connected:
                try:
                    await self.event_publisher.publish_data_collected(
                        project_id=project_id,
                        job_id=job_id,
                        platform="tiktok",
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
        from utils.logger import logger

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
        download_media: bool = True,
        media_type: Literal["video", "audio"] = "audio",
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
        save_to_db_enabled: bool = False,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> CrawlResult:
        """
        Fetch video with optional media download

        This is the main orchestration method that:
        1. Scrapes video metadata
        2. Optionally downloads media (audio/video)
        3. Scrapes creator info
        4. Scrapes comments
        5. Saves everything to repositories

        Args:
            url: TikTok video URL
            download_media: Whether to download media
            media_type: Type of media to download ("audio" or "video")
            media_save_dir: Storage prefix for media uploads
            include_creator: Whether to scrape creator info
            include_comments: Whether to scrape comments
            max_comments: Maximum comments to scrape (0 = all)
            job_id: Optional job ID for tracking
            keyword: Optional keyword context from the job
            time_range_days: Only persist content published within this many days
            since_date: Filter content published on or after this date
            until_date: Filter content published on or before this date
            task_type: Task type for Collector routing (e.g., 'dryrun_keyword', 'research_and_crawl')

        Returns:
            CrawlResult with content, author, comments, and success status
        """
        result = CrawlResult(url=url)
        media_task: Optional[asyncio.Task[Optional[str]]] = None

        try:
            # Step 1: Scrape video metadata
            video_data = await self.video_scraper.scrape(url)
            if not video_data:
                result.error_message = "Failed to scrape video"
                return result

            # Convert to Content entity (with field mapping)
            content = self._map_video_to_content(video_data, job_id, keyword)

            content_within_range = self._is_within_time_range(
                content.published_at, time_range_days, since_date, until_date
            )

            filtered_comments_data: List[Dict[str, Any]] = []
            if include_comments:
                comments_data = await self.comment_scraper.scrape(
                    video_url=url, max_comments=max_comments, full_mode=False
                )

                if comments_data:
                    # Filter comments by date if range specified
                    # If content date is missing, we rely on comment dates
                    should_filter_comments = (
                        time_range_days is not None
                        or since_date is not None
                        or until_date is not None
                    )

                    if not should_filter_comments:
                        filtered_comments_data = list(comments_data)
                    else:
                        for comment_data in comments_data:
                            comment_timestamp = self._parse_comment_timestamp(
                                comment_data.get("timestamp")
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

            # Step 2: Download media if requested without blocking
            if download_media:
                # Note: media URLs are transient, stored in video_data but not persisted
                video_download_url = video_data.get("video_download_url")
                audio_url = video_data.get("audio_url")

                if video_download_url or audio_url:
                    from utils.logger import logger

                    logger.info(
                        f"Starting media download for {content.external_id}: type={media_type}, video_url={bool(video_download_url)}, audio_url={bool(audio_url)}"
                    )
                    media_task = asyncio.create_task(
                        self.media_downloader.download_media(
                            content=content,
                            media_type=media_type,
                            save_dir=media_save_dir,
                        )
                    )
                else:
                    from utils.logger import logger

                    logger.warning(
                        f"No media URLs available for {content.external_id} - skipping download"
                    )

            # Step 3: Save content to repository (if enabled)
            # NEW: Use save_to_db_enabled from payload instead of self.enable_db_persistence
            if save_to_db_enabled:
                await self.content_repo.upsert_content(content)
            result.content = content

            # Step 4: Scrape and save author info (if requested)
            if include_creator and content.author_username:
                creator_url = f"https://www.tiktok.com/@{content.author_username}"
                creator_data = await self.creator_scraper.scrape(creator_url)

                if creator_data:
                    # Note: job_id NOT passed to author (per schema)
                    author = self._map_creator_to_author(creator_data)
                    # NEW: Use save_to_db_enabled from payload
                    if save_to_db_enabled:
                        await self.author_repo.upsert_author(author)
                    result.author = author

            # Step 5: Save filtered comments (if requested and available)
            if include_comments and filtered_comments_data:
                comments = []
                parent_id = None

                # NEW: Use save_to_db_enabled from payload
                if save_to_db_enabled:
                    saved_content = await self.content_repo.get_content(
                        source=SourcePlatform.TIKTOK, external_id=content.external_id
                    )
                    if saved_content and "_id" in saved_content:
                        parent_id = str(saved_content["_id"])
                else:
                    parent_id = content.external_id

                for comment_data in filtered_comments_data:
                    comment = self._map_comment_to_comment(
                        comment_data, parent_id=parent_id, job_id=job_id
                    )
                    comments.append(comment)

                # NEW: Use save_to_db_enabled from payload
                if comments and save_to_db_enabled:
                    await self.comment_repo.upsert_comments(comments)

                # Always set result.comments (even if empty) for archiving
                result.comments = comments

            # Step 6: Finalize media download (always await to capture media_path)
            if media_task:
                try:
                    media_location = await media_task
                    if media_location:
                        content.mark_media_downloaded(
                            media_location, MediaType(media_type.upper())
                        )

                        # Step 6.5: Speech-to-Text transcription (if STT client is available)
                        if self.speech2text_client:
                            try:
                                from utils.logger import logger

                                logger.info(
                                    f"[STT] Processing {content.external_id}, media_location={media_location}"
                                )

                                if media_location:
                                    logger.info(
                                        f"[STT] Calling API for {content.external_id}"
                                    )
                                    # Call STT API - returns STTResult object
                                    stt_result = (
                                        await self.speech2text_client.transcribe(
                                            audio_url=media_location, language="vi"
                                        )
                                    )

                                    # Store STT result in content
                                    content.transcription_status = stt_result.status

                                    if stt_result.success:
                                        # Success: store transcription
                                        content.transcription = stt_result.transcription
                                        content.transcription_error = None
                                        logger.info(
                                            f"[STT] SUCCESS for {content.external_id}: {len(stt_result.transcription)} chars"
                                        )
                                    else:
                                        # Error: don't fill transcription, store error message
                                        content.transcription = None
                                        content.transcription_error = (
                                            stt_result.error_message
                                        )

                                        # Handle specific error status types
                                        if stt_result.status == "TIMEOUT":
                                            logger.warning(
                                                f"[STT] TIMEOUT for {content.external_id}: Polling exceeded max retries. "
                                                f"Error: {stt_result.error_message}"
                                            )
                                        elif stt_result.status == "NOT_FOUND":
                                            logger.warning(
                                                f"[STT] NOT_FOUND for {content.external_id}: Job not found or expired. "
                                                f"Error: {stt_result.error_message}"
                                            )
                                        elif stt_result.status == "UNAUTHORIZED":
                                            logger.error(
                                                f"[STT] UNAUTHORIZED for {content.external_id}: Invalid API key or authentication failed. "
                                                f"Error: {stt_result.error_message}"
                                            )
                                        elif stt_result.status == "FAILED":
                                            logger.warning(
                                                f"[STT] FAILED for {content.external_id}: Transcription failed during processing. "
                                                f"Error: {stt_result.error_message}"
                                            )
                                        else:
                                            # Generic failure logging for other status types
                                            logger.warning(
                                                f"[STT] FAILED for {content.external_id}: status={stt_result.status}, error={stt_result.error_message}"
                                            )
                                else:
                                    logger.warning(
                                        f"[STT] No media_location for {content.external_id}"
                                    )
                                    content.transcription_status = "NO_MEDIA"
                                    content.transcription = None
                                    content.transcription_error = (
                                        "No media location available"
                                    )

                            except Exception as stt_error:
                                from utils.logger import logger

                                logger.error(
                                    f"[STT] Exception for {content.external_id}: {stt_error}",
                                    exc_info=True,
                                )
                                content.transcription_status = "EXCEPTION"
                                content.transcription = None
                                content.transcription_error = str(stt_error)

                        # Save to DB AFTER STT completes (if persistence is enabled)
                        # This ensures the transcription field is included
                        # NEW: Use save_to_db_enabled from payload
                        if save_to_db_enabled:
                            await self.content_repo.upsert_content(content)

                except Exception as media_error:
                    from utils.logger import logger

                    logger.error(
                        "Media download failed for %s: %s",
                        content.external_id,
                        media_error,
                    )

            result.success = True
            # NEW: Track what was actually done
            result.media_downloaded = download_media and (
                content.media_path is not None
            )
            result.saved_to_db = save_to_db_enabled
            result.archived_to_minio = archive_storage_enabled and (
                result.minio_key is not None
            )

        except Exception as e:
            from utils.errors import (
                build_error_from_exception,
                map_exception_to_error_code,
            )
            from utils.logger import logger

            # Build structured error response
            error_response = build_error_from_exception(
                exc=e,
                url=url,
                job_id=job_id,
                content_id=result.content.external_id if result.content else None,
            )

            # Log with error code for easier debugging
            error_code = map_exception_to_error_code(e)
            logger.error(
                f"Crawl failed for {url}: [{error_code.value}] {str(e)}",
                extra={"error_response": error_response},
            )

            result.error_message = str(e)
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

        # Upload individual item to MinIO (after media download to capture URLs)
        # NEW: Only upload if archive_storage_enabled is True
        if (
            archive_storage_enabled
            and self.archive_storage
            and job_id
            and result.content
            and result.success
        ):
            try:
                from utils.logger import logger

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
                    result=result, job_id=job_id, keyword=keyword, task_type=task_type
                )

                # Serialize to JSON
                json_bytes = json.dumps(item_data, default=str, indent=2).encode(
                    "utf-8"
                )

                # Upload to MinIO
                logger.info(
                    f"Uploading content {result.content.external_id} to MinIO: tiktok/{object_name}"
                )

                minio_key = await self.archive_storage.upload_bytes(
                    data=json_bytes,
                    object_name=object_name,
                    prefix="tiktok",
                    content_type="application/json",
                )

                # Store MinIO key in result
                result.minio_key = minio_key
                logger.info(
                    f"Successfully uploaded content {result.content.external_id} to {minio_key}"
                )

            except Exception as upload_error:
                logger.error(
                    f"Failed to upload content {result.content.external_id} to MinIO: {upload_error}"
                )
                # Don't fail the entire crawl if upload fails
                result.minio_key = None
        elif not archive_storage_enabled:
            from utils.logger import logger

            logger.info(
                f"Archive storage disabled for {result.content.external_id if result.content else url} - skipping MinIO upload"
            )

        return result

    async def fetch_videos_batch(
        self,
        urls: List[str],
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
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
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> List[CrawlResult]:
        """
        Fetch multiple videos concurrently

        Args:
            urls: List of TikTok video URLs
            download_media: Whether to download media
            media_type: Type of media to download
            media_save_dir: Storage prefix for media
            include_creator: Whether to scrape creator info
            include_comments: Whether to scrape comments
            max_comments: Maximum comments per video
            job_id: Optional job ID
            keyword: Optional keyword context (from job payload)
            time_range_days: Only persist content within this many days
            since_date: Filter content published on or after this date
            until_date: Filter content published on or before this date
            media_download_enabled: Global toggle for media downloads
            save_to_db_enabled: Whether to save to MongoDB
            archive_storage_enabled: Whether to save to MinIO archive
            task_type: Task type for Collector routing (e.g., 'dryrun_keyword', 'research_and_crawl')

        Returns:
            List of CrawlResults
        """
        if not urls:
            return []

        semaphore = asyncio.Semaphore(self.max_concurrency)

        async def _run(url: str) -> CrawlResult:
            async with semaphore:
                return await self.fetch_video_and_media(
                    url=url,
                    download_media=download_media
                    and media_download_enabled,  # NEW: Combine flags
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
                    save_to_db_enabled=save_to_db_enabled,  # NEW: Pass storage option
                    archive_storage_enabled=archive_storage_enabled,  # NEW: Pass archive option
                    task_type=task_type,  # NEW: Pass task type for Collector routing
                )

        tasks = [asyncio.create_task(_run(url)) for url in urls]
        return await asyncio.gather(*tasks)

    async def search_videos(
        self, keyword: str, limit: int = 50, sort_by: str = "relevance"
    ) -> List[str]:
        """Search TikTok for video URLs via the configured search scraper."""
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
        media_save_dir: str = "./downloads",
        include_creator: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        job_id: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        media_download_enabled: bool = True,
        save_to_db_enabled: bool = False,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Search for videos and fetch them

        Args:
            keyword: Search keyword
            limit: Maximum number of videos to fetch
            sort_by: Sort method ('relevance', 'liked', 'recent')
            download_media: Whether to download media
            media_type: Type of media to download
            media_save_dir: Storage prefix for media
            include_creator: Whether to scrape creator info
            include_comments: Whether to scrape comments
            max_comments: Maximum comments per video
            job_id: Optional job ID
            time_range_days: Only persist content within this many days
            since_date: Filter content published on or after this date
            until_date: Filter content published on or before this date
            task_type: Task type for Collector routing (e.g., 'dryrun_keyword', 'research_and_crawl')

        Returns:
            Dict with search results and crawl results
        """
        video_urls = await self.search_videos(
            keyword=keyword, limit=limit, sort_by=sort_by
        )

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
            include_creator=include_creator,
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

    async def fetch_profile_videos(
        self,
        profile_url: str,
        download_media: bool = False,
        media_type: Literal["video", "audio"] = "audio",
        media_save_dir: str = "./downloads",
        include_creator: bool = True,
        include_comments: bool = True,
        max_comments: int = 0,
        limit: int = 100,  # NEW: Limit parameter for video count
        job_id: Optional[str] = None,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
        # NEW: Storage options
        media_download_enabled: bool = True,
        save_to_db_enabled: bool = False,
        archive_storage_enabled: bool = True,
        # NEW: Task type for Collector routing
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Fetch all videos from a TikTok profile within specified time range

        This method:
        1. Scrapes video URLs from the profile page
        2. Delegates to fetch_videos_batch for processing
        3. Returns results with MinIO keys for tracking

        Args:
            profile_url: TikTok profile URL (e.g., https://www.tiktok.com/@username)
            download_media: Whether to download media
            media_type: Type of media to download
            media_save_dir: Storage prefix for media
            include_creator: Whether to scrape creator info
            include_comments: Whether to scrape comments
            max_comments: Maximum comments per video
            limit: Maximum number of videos to fetch from profile
            job_id: Optional job ID
            time_range_days: Only persist content within this many days
            since_date: Filter content published on or after this date
            until_date: Filter content published on or before this date
            task_type: Task type for Collector routing (e.g., 'dryrun_keyword', 'research_and_crawl')

        Returns:
            Dict with profile URL, video URLs, and crawl results
        """
        from utils.logger import logger

        logger.info(f"Fetching profile videos from: {profile_url} (limit={limit})")

        # Step 1: Extract video URLs from profile page
        video_urls = await self.profile_scraper.get_profile_videos(
            profile_url=profile_url,
            limit=limit,  # NEW: Use limit parameter instead of max_comments
        )

        # NEW: Enforce limit on video URLs
        if video_urls and len(video_urls) > limit:
            logger.warning(
                f"fetch_profile_videos: Truncating video_urls from {len(video_urls)} to {limit}"
            )
            video_urls = video_urls[:limit]

        if not video_urls:
            return {
                "profile_url": profile_url,
                "video_urls": [],
                "crawl_results": [],
                "success": False,
                "error": "No videos found on profile",
            }

        logger.info(f"Found {len(video_urls)} videos on profile, starting crawl...")

        # Step 2: Process videos using existing batch logic
        # This handles time filtering, media download, and MinIO upload
        crawl_results = await self.fetch_videos_batch(
            urls=video_urls,
            download_media=download_media,
            media_type=media_type,
            media_save_dir=media_save_dir,
            include_creator=include_creator,
            include_comments=include_comments,
            max_comments=max_comments,
            job_id=job_id,
            keyword=None,  # No keyword for profile crawls
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
            f"Profile crawl complete: {successful} successful, {skipped} skipped, {failed} failed"
        )

        return {
            "profile_url": profile_url,
            "video_urls": video_urls,
            "crawl_results": crawl_results,
            "total": len(video_urls),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "success": successful > 0,
        }

    async def get_content_stats(
        self, source: str, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get content statistics

        Args:
            source: Source platform (e.g., "TIKTOK")
            external_id: Platform-specific content ID

        Returns:
            Content stats dict or None if not found
        """
        return await self.content_repo.get_content(source, external_id)

    async def get_author_stats(
        self, source: str, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get author statistics

        Args:
            source: Source platform (e.g., "TIKTOK")
            external_id: Platform-specific author ID

        Returns:
            Author stats dict or None if not found
        """
        return await self.author_repo.get_author(source, external_id)

    async def get_content_comments(
        self, parent_id: str, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Get comments for content

        Args:
            parent_id: Content MongoDB ObjectId
            limit: Maximum number of comments

        Returns:
            List of comments
        """
        return await self.comment_repo.get_comments_by_parent(parent_id, limit)
