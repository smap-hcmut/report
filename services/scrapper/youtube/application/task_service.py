"""
Task Service - Application Layer
Handles different task types from message queue
"""

from typing import Dict, Any, Optional, List
from datetime import datetime
import uuid
import traceback

from .crawler_service import CrawlerService, CrawlResult
from .interfaces import IJobRepository, IContentRepository, ISearchSessionRepository
from domain import SearchSession
from domain.enums import SourcePlatform, SearchSortBy
from utils.logger import logger
from config.settings import settings


class TaskService:
    """
    Task Service - Task Handling

    Processes tasks from message queue and delegates to appropriate services.
    Supports 4 task types:
    1. research_keyword - Search for videos and save links
    2. crawl_links - Crawl videos from provided URLs
    3. research_and_crawl - Search and crawl in one operation
    4. fetch_channel_content - Crawl all videos from a YouTube channel
    """

    def __init__(
        self,
        crawler_service: CrawlerService,
        job_repo: IJobRepository,
        content_repo: IContentRepository,
        search_session_repo: Optional[ISearchSessionRepository] = None,
        result_publisher: Optional[Any] = None,
        default_download_media: bool = False,
        default_media_type: str = "audio",
        default_media_dir: str = "./YOUTUBE",
    ):
        """
        Initialize task service

        Args:
            crawler_service: Crawler service for orchestrating scrapes
            job_repo: Job repository for tracking task status
            content_repo: Content repository for saving search session metadata
            search_session_repo: Repository for search session persistence
            result_publisher: RabbitMQ publisher for dry-run result messages
            default_download_media: Default value for download_media
            default_media_type: Default media type ('audio' or 'video')
            default_media_dir: Default directory for downloads
        """
        self.crawler_service = crawler_service
        self.job_repo = job_repo
        self.content_repo = content_repo
        self.search_session_repo = search_session_repo
        self.result_publisher = result_publisher
        self.default_download_media = default_download_media
        self.default_media_type = default_media_type
        self.default_media_dir = default_media_dir

    async def handle_task(
        self, task_type: str, payload: Dict[str, Any], job_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Handle a task from the queue

        Args:
            task_type: Type of task (research_keyword, crawl_links, research_and_crawl)
            payload: Task payload with parameters
            job_id: Job ID (generated if not provided)

        Returns:
            Task result dict
        """
        # Generate job ID if not provided
        if not job_id:
            job_id = "err_job_id"

        time_range_days = self._normalize_time_range(payload.get("time_range"))
        if time_range_days is not None:
            payload["time_range"] = time_range_days
        elif "time_range" in payload:
            payload.pop("time_range")

        # Parse date range
        since_date = self._parse_iso_date(payload.get("since_date"))
        until_date = self._parse_iso_date(payload.get("until_date"))

        # Create job record
        job_created = await self.job_repo.create_job(
            job_id=job_id,
            task_type=task_type,
            payload=payload,
            time_range=time_range_days,
            since_date=since_date,
            until_date=until_date,
        )
        if not job_created:
            raise RuntimeError(f"Failed to create job record for {job_id}")

        # Update job status to processing
        processing_updated = await self.job_repo.update_job_status(job_id, "processing")
        if not processing_updated:
            raise RuntimeError(f"Failed to mark job {job_id} as processing")

        try:
            # Route to appropriate handler
            minio_keys = []

            if task_type == "research_keyword":
                result = await self._handle_research_keyword(payload, job_id)
            elif task_type == "crawl_links":
                result = await self._handle_crawl_links(
                    payload, job_id, time_range_days, since_date, until_date
                )
                # Collect MinIO keys
                if "crawl_results" in result:
                    minio_keys = [
                        r.minio_key for r in result["crawl_results"] if r.minio_key
                    ]
            elif task_type == "research_and_crawl":
                # Calculate requested_limit for result publishing
                keywords = payload.get("keywords", [])
                limit_per_keyword = self._get_limit(
                    payload,
                    "limit_per_keyword",
                    settings.default_limit_per_keyword,
                    settings.max_search_limit,
                )
                requested_limit = limit_per_keyword * len(keywords)

                result = await self._handle_research_and_crawl(
                    payload, job_id, time_range_days, since_date, until_date
                )
                # Collect from all keywords
                if "results_by_keyword" in result:
                    for kw_result in result["results_by_keyword"].values():
                        if "crawl_results" in kw_result:
                            minio_keys.extend(
                                [
                                    r.minio_key
                                    for r in kw_result["crawl_results"]
                                    if r.minio_key
                                ]
                            )

                # NEW: Publish result to Collector
                await self._publish_research_and_crawl_result(
                    job_id=job_id,
                    result=result,
                    success=True,
                    requested_limit=requested_limit,
                )
            elif task_type == "fetch_channel_content":
                result = await self._handle_fetch_channel_content(
                    payload, job_id, time_range_days, since_date, until_date
                )
                # Collect MinIO keys from crawl results
                if "crawl_results" in result:
                    minio_keys = [
                        r.minio_key for r in result["crawl_results"] if r.minio_key
                    ]
            elif task_type == "dryrun_keyword":
                result = await self._handle_dryrun_keyword(
                    payload, job_id, time_range_days, since_date, until_date
                )
                # Publish result message after task completion
                await self._publish_dryrun_result(
                    job_id=job_id, result=result, success=True
                )
            else:
                raise ValueError(f"Unknown task type: {task_type}")

            # Save MinIO keys to crawl_jobs
            if minio_keys:
                await self.job_repo.update_job_results(job_id, minio_keys)

            # Update job status to completed
            await self.job_repo.update_job_status(job_id, "completed")

            return {**result, "job_id": job_id, "success": True}

        except Exception as e:
            # Get full error traceback
            error_traceback = traceback.format_exc()
            error_message = f"{str(e)}\n\nTraceback:\n{error_traceback}"

            # Log the error with full details
            logger.error("=" * 70)
            logger.error("TASK EXECUTION FAILED")
            logger.error("Job ID: %s", job_id)
            logger.error("Task Type: %s", task_type)
            logger.error("Error: %s", str(e))
            logger.error("Full Traceback:\n%s", error_traceback)
            logger.error("=" * 70)

            # Classify error type for ACK decision
            error_type = self._classify_error(e)
            logger.info("Error classified as: %s", error_type)

            # Try to update job status to failed with full error details
            try:
                await self.job_repo.update_job_status(
                    job_id, "failed", error_message=error_message
                )
                logger.info("Job %s marked as failed in database", job_id)
            except Exception as db_error:
                # Database update failed - this is an infrastructure error
                error_type = "infrastructure"
                logger.critical(
                    "Failed to update job status for %s: %s",
                    job_id,
                    db_error,
                    exc_info=True,
                )

            # Publish error result message for dryrun_keyword tasks
            if task_type == "dryrun_keyword":
                await self._publish_dryrun_result(
                    job_id=job_id, result={}, success=False
                )

            # Publish error result message for research_and_crawl tasks
            if task_type == "research_and_crawl":
                keywords = payload.get("keywords", [])
                limit_per_keyword = self._get_limit(
                    payload,
                    "limit_per_keyword",
                    settings.default_limit_per_keyword,
                    settings.max_search_limit,
                )
                requested_limit = limit_per_keyword * len(keywords)
                error_result = {
                    "error": str(e),
                    "error_type": error_type,
                    "total_videos": 0,
                    "total_successful": 0,
                    "total_failed": 0,
                    "total_skipped": 0,
                }
                await self._publish_research_and_crawl_result(
                    job_id=job_id,
                    result=error_result,
                    success=False,
                    requested_limit=requested_limit,
                    error=e,
                )

            return {
                "job_id": job_id,
                "success": False,
                "error": error_message,
                "error_type": error_type,
            }

    async def _handle_research_keyword(
        self, payload: Dict[str, Any], job_id: str
    ) -> Dict[str, Any]:
        """
        Handle research_keyword task

        Payload:
            - keyword: str
            - limit: int (default: from settings)
            - sort_by: str (default: 'relevance')

        Returns:
            Dict with search results
        """
        keyword = payload.get("keyword")
        # Use _get_limit() for validated limit with config defaults
        limit = self._get_limit(
            payload,
            "limit",
            settings.default_search_limit,
            settings.max_search_limit,
        )
        sort_by = payload.get("sort_by", "relevance")

        if not keyword:
            raise ValueError("Missing required field: keyword")

        # Search for videos via crawler service abstraction
        video_urls = await self.crawler_service.search_videos(
            keyword=keyword, limit=limit, sort_by=sort_by
        )

        await self._record_search_session(
            keyword=keyword, video_urls=video_urls, sort_by=sort_by, job_id=job_id
        )

        return {
            "task_type": "research_keyword",
            "keyword": keyword,
            "video_urls": video_urls,
            "total_found": len(video_urls),
            "sort_by": sort_by,
        }

    async def _handle_crawl_links(
        self,
        payload: Dict[str, Any],
        job_id: str,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        """
        Handle crawl_links task

        Payload:
            - video_urls: List[str]
            - include_comments: bool (default: True)
            - include_channel: bool (default: True)
            - max_comments: int (default: 0)
            - download_media: bool (default: False)
            - media_type: str (default: 'audio')
            - media_save_dir: str (default: './downloads')

        Returns:
            Dict with crawl results
        """
        video_urls = payload.get("video_urls", [])
        include_comments = payload.get("include_comments", True)
        include_channel = payload.get("include_channel", True)
        max_comments = payload.get("max_comments", 0)
        keyword = payload.get("keyword")
        # Media download parameters
        download_media = payload.get("download_media", self.default_download_media)
        media_type = payload.get("media_type", self.default_media_type)
        media_save_dir = payload.get("media_save_dir", self.default_media_dir)

        # NEW: Extract storage options
        storage_options = self._extract_storage_options(payload)

        if not video_urls:
            raise ValueError("Missing required field: video_urls")

        # NEW: Apply limit to video_urls to prevent resource exhaustion
        limit = self._get_limit(
            payload,
            "limit",
            settings.default_crawl_links_limit,
            settings.max_crawl_links_limit,
        )
        original_count = len(video_urls)
        if original_count > limit:
            logger.warning(
                f"crawl_links: Truncating video_urls from {original_count} to {limit} (limit enforcement)"
            )
            video_urls = video_urls[:limit]

        # Fetch videos - pass storage options
        crawl_results = await self.crawler_service.fetch_videos_batch(
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
            media_download_enabled=storage_options["media_download_enabled"],
            save_to_db_enabled=storage_options["save_to_db_enabled"],
            archive_storage_enabled=storage_options["archive_storage_enabled"],
            task_type="crawl_links",  # NEW: Pass task type for Collector routing
        )

        successful = sum(1 for r in crawl_results if r.success)
        skipped = sum(1 for r in crawl_results if getattr(r, "skipped", False))
        failed = max(len(video_urls) - successful - skipped, 0)

        # NEW: Process crawl results through batch upload
        if crawl_results:
            batch_paths = await self._process_crawl_results_with_batch(
                crawl_results=crawl_results,
                job_id=job_id,
                keyword=keyword,
                task_type="crawl_links",
                batch_size=settings.batch_size,
            )
            logger.info(
                f"Batch upload completed for crawl_links: {len(batch_paths)} batches"
            )

        return {
            "task_type": "crawl_links",
            "crawl_results": crawl_results,  # Return objects for key extraction
            "total": len(video_urls),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "download_media": download_media,
            "media_type": media_type if download_media else None,
            # NEW: Include storage options in response
            "media_download_enabled": storage_options["media_download_enabled"],
            "save_to_db_enabled": storage_options["save_to_db_enabled"],
            "archive_storage_enabled": storage_options["archive_storage_enabled"],
        }

    async def _handle_research_and_crawl(
        self,
        payload: Dict[str, Any],
        job_id: str,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        """
        Handle research_and_crawl task

        Combines research and crawl in one operation.

        Payload:
            - keywords: List[str]
            - limit_per_keyword: int (default: 50)
            - sort_by: str (default: 'relevance')
            - include_comments: bool (default: True)
            - include_channel: bool (default: True)
            - max_comments: int (default: 0)
            - download_media: bool (default: False)
            - media_type: str (default: 'audio')
            - media_save_dir: str (default: './downloads')

        Returns:
            Dict with combined results
        """
        keywords = payload.get("keywords", [])
        # Use _get_limit() for validated limit with config defaults
        limit_per_keyword = self._get_limit(
            payload,
            "limit_per_keyword",
            settings.default_limit_per_keyword,
            settings.max_search_limit,
        )
        sort_by = payload.get("sort_by", "relevance")
        include_comments = payload.get("include_comments", True)
        include_channel = payload.get("include_channel", True)
        max_comments = payload.get("max_comments", 0)

        # Media download parameters
        download_media = payload.get("download_media", self.default_download_media)
        media_type = payload.get("media_type", self.default_media_type)
        media_save_dir = payload.get("media_save_dir", self.default_media_dir)

        # NEW: Extract storage options
        storage_options = self._extract_storage_options(payload)

        if not keywords:
            raise ValueError("Missing required field: keywords")

        results_by_keyword = {}
        total_videos = 0
        total_successful = 0
        total_failed = 0

        # Process each keyword
        for keyword in keywords:
            result = await self.crawler_service.search_and_fetch(
                keyword=keyword,
                limit=limit_per_keyword,
                sort_by=sort_by,
                download_media=download_media,
                media_type=media_type,
                media_save_dir=media_save_dir,
                include_channel=include_channel,
                include_comments=include_comments,
                max_comments=max_comments,
                job_id=job_id,
                time_range_days=time_range_days,
                since_date=since_date,
                until_date=until_date,
                # NEW: Pass storage options
                media_download_enabled=storage_options["media_download_enabled"],
                save_to_db_enabled=storage_options["save_to_db_enabled"],
                archive_storage_enabled=storage_options["archive_storage_enabled"],
                task_type="research_and_crawl",  # NEW: Pass task type for Collector routing
            )

            results_by_keyword[keyword] = result
            await self._record_search_session(
                keyword=keyword,
                video_urls=result.get("video_urls", []),
                sort_by=sort_by,
                job_id=job_id,
            )
            total_videos += result.get("total", 0)
            total_successful += result.get("successful", 0)
            total_failed += result.get("failed", 0)

            # NEW: Process crawl results through batch upload
            crawl_results = result.get("crawl_results", [])
            if crawl_results:
                batch_paths = await self._process_crawl_results_with_batch(
                    crawl_results=crawl_results,
                    job_id=job_id,
                    keyword=keyword,
                    task_type="research_and_crawl",
                    batch_size=settings.batch_size,
                )
                logger.info(
                    f"Batch upload completed for keyword '{keyword}': {len(batch_paths)} batches"
                )

        total_skipped = sum(
            kw_result.get("skipped", 0) for kw_result in results_by_keyword.values()
        )
        total_failed = max(total_videos - total_successful - total_skipped, 0)

        return {
            "task_type": "research_and_crawl",
            "keywords": keywords,
            "results_by_keyword": results_by_keyword,
            "total_videos": total_videos,
            "total_successful": total_successful,
            "total_failed": total_failed,
            "total_skipped": total_skipped,
            "download_media": download_media,
            "media_type": media_type if download_media else None,
            # NEW: Include storage options in response
            "media_download_enabled": storage_options["media_download_enabled"],
            "save_to_db_enabled": storage_options["save_to_db_enabled"],
            "archive_storage_enabled": storage_options["archive_storage_enabled"],
        }

    async def _handle_fetch_channel_content(
        self,
        payload: Dict[str, Any],
        job_id: str,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        """
        Handle fetch_channel_content task

        Payload:
            - channel_url: str (YouTube channel URL)
            - include_comments: bool (default: True)
            - include_channel: bool (default: True)
            - max_comments: int (default: 0)
            - download_media: bool (default: False)
            - media_type: str (default: 'audio')
            - media_save_dir: str (default: './YOUTUBE')

        Returns:
            Dict with channel crawl results
        """
        channel_url = payload.get("channel_url")
        include_comments = payload.get("include_comments", True)
        include_channel = payload.get("include_channel", True)
        max_comments = payload.get("max_comments", 0)
        # FIX: Use _get_limit() instead of hardcoded default 0 (unlimited)
        limit = self._get_limit(
            payload,
            "limit",
            settings.default_channel_limit,
            settings.max_channel_limit,
        )

        # Media download parameters
        download_media = payload.get("download_media", self.default_download_media)
        media_type = payload.get("media_type", self.default_media_type)
        media_save_dir = payload.get("media_save_dir", self.default_media_dir)

        # NEW: Extract storage options
        storage_options = self._extract_storage_options(payload)

        if not channel_url:
            raise ValueError("Missing required field: channel_url")

        # Fetch channel videos
        result = await self.crawler_service.fetch_channel_videos(
            channel_url=channel_url,
            download_media=download_media,
            media_type=media_type,
            media_save_dir=media_save_dir,
            include_channel=include_channel,
            include_comments=include_comments,
            max_comments=max_comments,
            limit=limit,
            job_id=job_id,
            time_range_days=time_range_days,
            since_date=since_date,
            until_date=until_date,
            # NEW: Pass storage options
            media_download_enabled=storage_options["media_download_enabled"],
            save_to_db_enabled=storage_options["save_to_db_enabled"],
            archive_storage_enabled=storage_options["archive_storage_enabled"],
            task_type="fetch_channel_content",  # NEW: Pass task type for Collector routing
        )

        # Record session for channel crawl
        await self._record_search_session(
            keyword=channel_url,
            video_urls=result.get("video_urls", []),
            sort_by="DATE",  # Channel videos are usually chronological
            job_id=job_id,
        )

        crawl_results = result.get("crawl_results", [])
        successful = sum(1 for r in crawl_results if r.success)
        skipped = sum(1 for r in crawl_results if getattr(r, "skipped", False))
        failed = max(result.get("total", 0) - successful - skipped, 0)

        # NEW: Process crawl results through batch upload
        if crawl_results:
            batch_paths = await self._process_crawl_results_with_batch(
                crawl_results=crawl_results,
                job_id=job_id,
                keyword=channel_url,  # Use channel_url as keyword context
                task_type="fetch_channel_content",
                batch_size=settings.batch_size,
            )
            logger.info(
                f"Batch upload completed for fetch_channel_content: {len(batch_paths)} batches"
            )

        return {
            "task_type": "fetch_channel_content",
            "channel_url": channel_url,
            "video_urls": result.get("video_urls", []),
            "total": result.get("total", 0),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "download_media": download_media,
            "media_type": media_type if download_media else None,
            "crawl_results": crawl_results,  # Return crawl results for MinIO key collection
            # NEW: Include storage options in response
            "media_download_enabled": storage_options["media_download_enabled"],
            "save_to_db_enabled": storage_options["save_to_db_enabled"],
            "archive_storage_enabled": storage_options["archive_storage_enabled"],
        }

    async def _handle_dryrun_keyword(
        self,
        payload: Dict[str, Any],
        job_id: str,
        time_range_days: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        """
        Handle dryrun_keyword task

        Performs search and scrape without persistence.
        Supports multiple keywords.

        Payload:
            - keywords: List[str] (required, or use 'keyword' for backward compatibility)
            - keyword: str (backward compatibility)
            - limit: int (default: 50)
            - sort_by: str (default: 'relevance')
            - include_comments: bool (default: True)
            - include_channel: bool (default: True)
            - max_comments: int (default: 0)

        Returns:
            Dict with search results and all crawl results
        """
        # Support both 'keywords' (array) and 'keyword' (string) for backward compatibility
        keywords = payload.get("keywords")
        if not keywords:
            keyword = payload.get("keyword")
            if keyword:
                keywords = [keyword]
            else:
                raise ValueError("Missing required field: keywords or keyword")

        # Ensure keywords is a list
        if not isinstance(keywords, list):
            keywords = [keywords]

        # Extract optional parameters
        # Support both 'limit_per_keyword' and 'limit' for backward compatibility
        # Use _get_limit() for validated limit with config defaults
        limit_key = "limit_per_keyword" if "limit_per_keyword" in payload else "limit"
        limit = self._get_limit(
            payload,
            limit_key,
            settings.default_search_limit,
            settings.max_search_limit,
        )
        sort_by = payload.get("sort_by", "relevance")
        include_comments = payload.get("include_comments", True)
        include_channel = payload.get("include_channel", True)
        max_comments = payload.get("max_comments", 0)

        # Set all storage flags to False for dry-run mode
        storage_options = {
            "media_download_enabled": False,
            "save_to_db_enabled": False,
            "archive_storage_enabled": False,
        }

        # Aggregate results from all keywords
        all_crawl_results = []
        results_by_keyword = {}
        total_videos = 0
        total_successful = 0
        total_failed = 0
        total_skipped = 0

        # Process each keyword sequentially
        for keyword in keywords:
            try:
                result = await self.crawler_service.search_and_fetch(
                    keyword=keyword,
                    limit=limit,
                    sort_by=sort_by,
                    download_media=False,  # No media download in dry-run
                    media_type="audio",
                    media_save_dir=self.default_media_dir,
                    include_channel=include_channel,
                    include_comments=include_comments,
                    max_comments=max_comments,
                    job_id=job_id,
                    time_range_days=time_range_days,
                    since_date=since_date,
                    until_date=until_date,
                    # Pass storage flags (all False)
                    media_download_enabled=storage_options["media_download_enabled"],
                    save_to_db_enabled=storage_options["save_to_db_enabled"],
                    archive_storage_enabled=storage_options["archive_storage_enabled"],
                    task_type="dryrun_keyword",  # NEW: Pass task type for Collector routing
                )

                # Collect per-keyword statistics
                results_by_keyword[keyword] = {
                    "video_urls": result.get("video_urls", []),
                    "total": result.get("total", 0),
                    "successful": result.get("successful", 0),
                    "failed": result.get("failed", 0),
                    "skipped": result.get("skipped", 0),
                }

                # Aggregate results
                all_crawl_results.extend(result.get("crawl_results", []))
                total_videos += result.get("total", 0)
                total_successful += result.get("successful", 0)
                total_failed += result.get("failed", 0)
                total_skipped += result.get("skipped", 0)

            except Exception as e:
                # Log error but continue processing remaining keywords
                logger.error(f"Error processing keyword '{keyword}': {e}")
                results_by_keyword[keyword] = {
                    "video_urls": [],
                    "total": 0,
                    "successful": 0,
                    "failed": 0,
                    "skipped": 0,
                    "error": str(e),
                }

        # Return result dictionary with all crawl results
        return {
            "task_type": "dryrun_keyword",
            "keywords": keywords,
            "results_by_keyword": results_by_keyword,
            "crawl_results": all_crawl_results,
            "total_videos": total_videos,
            "total_successful": total_successful,
            "total_failed": total_failed,
            "total_skipped": total_skipped,
            "limit": limit,
            "sort_by": sort_by,
            "include_comments": include_comments,
            "include_channel": include_channel,
            "max_comments": max_comments,
            # Include storage options in response
            "media_download_enabled": storage_options["media_download_enabled"],
            "save_to_db_enabled": storage_options["save_to_db_enabled"],
            "archive_storage_enabled": storage_options["archive_storage_enabled"],
        }

    async def _publish_dryrun_result(
        self,
        job_id: str,
        result: Dict[str, Any],
        success: bool,
        error: Optional[Exception] = None,
    ) -> None:
        """
        Publish dry-run result message to RabbitMQ collector exchange.

        Maps crawl results to new format before publishing.
        NEW: Includes task_type, limit_info, stats, and error objects per contract.
        Handles publisher connection failures gracefully without failing the task.
        Only publishes once after all keywords are processed.

        Args:
            job_id: Unique job identifier
            result: Result dictionary from _handle_dryrun_keyword
            success: Whether the task completed successfully
            error: Optional exception for error details
        """
        if not self.result_publisher:
            logger.warning(
                "Result publisher not configured - skipping result publication for job %s",
                job_id,
            )
            return

        try:
            from utils.helpers import map_to_new_format

            # Extract statistics from result
            total_videos = result.get("total_videos", 0)
            total_successful = result.get("total_successful", 0)
            total_failed = result.get("total_failed", 0)
            total_skipped = result.get("total_skipped", 0)
            requested_limit = result.get("limit", settings.default_search_limit)

            # Calculate completion rate
            completion_rate = (
                round(total_successful / total_videos, 2) if total_videos > 0 else 0.0
            )

            # Determine if platform limited the results
            platform_limited = total_videos < requested_limit

            # NEW: Build response with task_type, limit_info, stats at root level
            result_message = {
                "success": success,
                "task_type": "dryrun_keyword",
                "limit_info": {
                    "requested_limit": requested_limit,
                    "applied_limit": requested_limit,
                    "total_found": total_videos,
                    "platform_limited": platform_limited,
                },
                "stats": {
                    "successful": total_successful,
                    "failed": total_failed,
                    "skipped": total_skipped,
                    "completion_rate": completion_rate,
                },
            }

            if success:
                # Success case: map crawl results to new format
                keywords = result.get("keywords", [])
                crawl_results = result.get("crawl_results", [])
                mapped_results = []

                for crawl_result in crawl_results:
                    if crawl_result.success:
                        try:
                            # Use the keyword from the crawl result's content if available
                            keyword = getattr(crawl_result.content, "keyword", None)
                            if not keyword and keywords:
                                # Fallback to first keyword if not set on content
                                keyword = keywords[0]

                            mapped_data = map_to_new_format(
                                result=crawl_result,
                                job_id=job_id,
                                keyword=keyword,
                                task_type="dryrun_keyword",  # Pass task type for Collector routing
                            )
                            mapped_results.append(mapped_data)
                        except Exception as map_error:
                            logger.error(
                                "Failed to map crawl result for video %s: %s",
                                getattr(crawl_result.content, "external_id", "unknown"),
                                map_error,
                            )

                # Add mapped results to payload
                result_message["payload"] = mapped_results

                logger.info(
                    "Mapped %d/%d crawl results to new format for job %s (keywords: %s)",
                    len(mapped_results),
                    len(crawl_results),
                    job_id,
                    ", ".join(keywords),
                )

            else:
                # Error case: empty payload and add error object
                result_message["payload"] = []
                error_type = result.get("error_type", "scraping")
                error_message = result.get("error", "Unknown error")
                result_message["error"] = {
                    "code": self._map_error_code(error_type, error),
                    "message": str(error_message),
                }

            # Publish to RabbitMQ - only once after all keywords are processed
            await self.result_publisher.publish_result(
                job_id=job_id, task_type="dryrun_keyword", result_data=result_message
            )

            logger.info(
                "Published dry-run result for job %s - Success: %s, Payload items: %d, Stats: %s",
                job_id,
                success,
                len(result_message.get("payload", [])),
                result_message.get("stats"),
            )

        except Exception as exc:
            # Log error but don't fail the task
            # The task itself succeeded/failed independently of result publication
            logger.error(
                "Failed to publish dry-run result for job %s: %s",
                job_id,
                exc,
                exc_info=True,
            )

    async def _publish_research_and_crawl_result(
        self,
        job_id: str,
        result: Dict[str, Any],
        success: bool,
        requested_limit: int,
        error: Optional[Exception] = None,
    ) -> None:
        """
        Publish research_and_crawl result message to RabbitMQ collector exchange.

        Sends flat message format per CrawlerResultMessage contract (no payload).
        Content is already uploaded to MinIO and notified via data.collected event.
        This message is for Collector to update Redis state counters.

        Args:
            job_id: Unique job identifier
            result: Result dictionary from _handle_research_and_crawl
            success: Whether the task completed successfully
            requested_limit: Total requested limit (limit_per_keyword * len(keywords))
            error: Optional exception for error details
        """
        if not self.result_publisher:
            logger.warning(
                "Result publisher not configured - skipping result publication for job %s",
                job_id,
            )
            return

        try:
            # Extract statistics from result
            total_found = result.get("total_videos", 0)
            total_successful = result.get("total_successful", 0)
            total_failed = result.get("total_failed", 0)
            total_skipped = result.get("total_skipped", 0)

            # Calculate platform_limited flag
            # Platform limited when total_found < requested_limit
            platform_limited = total_found < requested_limit

            # Build flat message per CrawlerResultMessage contract
            result_message = {
                "success": success,
                "task_type": "research_and_crawl",
                "job_id": job_id,
                "platform": "youtube",
                "requested_limit": requested_limit,
                "applied_limit": requested_limit,
                "total_found": total_found,
                "platform_limited": platform_limited,
                "successful": total_successful,
                "failed": total_failed,
                "skipped": total_skipped,
                "error_code": None,
                "error_message": None,
            }

            # Add error details if task failed
            if not success:
                error_type = result.get("error_type", "scraping")
                error_message = result.get(
                    "error", str(error) if error else "Unknown error"
                )
                result_message["error_code"] = self._map_error_code(error_type, error)
                result_message["error_message"] = str(error_message)

            # Publish to RabbitMQ
            await self.result_publisher.publish_result(
                job_id=job_id,
                task_type="research_and_crawl",
                result_data=result_message,
            )

            logger.info(
                "Published research_and_crawl result for job %s - Success: %s, "
                "Found: %d, Successful: %d, Failed: %d, Skipped: %d, Platform Limited: %s",
                job_id,
                success,
                total_found,
                total_successful,
                total_failed,
                total_skipped,
                platform_limited,
            )

        except Exception as exc:
            # Log error but don't fail the task
            # The task itself succeeded/failed independently of result publication
            logger.error(
                "Failed to publish research_and_crawl result for job %s: %s",
                job_id,
                exc,
                exc_info=True,
            )

    async def get_task_status(self, job_id: str) -> Optional[Dict[str, Any]]:
        """
        Get task status

        Args:
            job_id: Job ID

        Returns:
            Job status dict or None if not found
        """
        return await self.job_repo.get_job(job_id)

    def _extract_storage_options(self, payload: Dict[str, Any]) -> Dict[str, bool]:
        """
        Extract storage-related options from payload.

        NEW: Helper method to extract per-message storage configuration.
        Falls back to settings defaults if not specified in payload.

        Args:
            payload: Task payload

        Returns:
            Dict with storage options
        """
        return {
            "media_download_enabled": payload.get(
                "media_download_enabled", settings.media_download_enabled
            ),
            "save_to_db_enabled": payload.get(
                "save_to_db_enabled", settings.enable_db_persistence
            ),
            "archive_storage_enabled": payload.get(
                "archive_storage_enabled", settings.enable_json_archive
            ),
        }

    def _get_limit(
        self,
        payload: Dict[str, Any],
        key: str,
        default: int,
        max_limit: int,
    ) -> int:
        """
        Validate and cap limit from payload.

        Extracts limit value from payload, applies default if not provided or invalid,
        and caps at max_limit to prevent resource exhaustion.

        Args:
            payload: Task payload dictionary
            key: Key to extract from payload (e.g., 'limit', 'limit_per_keyword')
            default: Default value if not provided or invalid
            max_limit: Maximum allowed value (safety cap)

        Returns:
            Validated and capped limit value
        """
        limit = payload.get(key)

        # Apply default if not provided or invalid
        if limit is None or (isinstance(limit, int) and limit <= 0):
            limit = default
            logger.debug(f"Using default {key}={limit}")

        # Ensure it's an integer
        try:
            limit = int(limit)
        except (TypeError, ValueError):
            logger.warning(
                f"Invalid {key} value: {payload.get(key)}, using default={default}"
            )
            limit = default

        # Cap at max_limit
        if limit > max_limit:
            logger.warning(
                f"{key}={limit} exceeds max_limit={max_limit}, capping to {max_limit}"
            )
            limit = max_limit

        return limit

    def _map_error_code(
        self, error_type: str, exception: Optional[Exception] = None
    ) -> str:
        """
        Map internal error type to standard error code for Collector.

        Standard error codes:
        - SEARCH_FAILED: Search API failed (retryable)
        - RATE_LIMITED: Platform rate limit (retryable)
        - AUTH_FAILED: Authentication failed (not retryable)
        - INVALID_KEYWORD: Invalid keyword (not retryable)
        - TIMEOUT: Request timeout (retryable)
        - UNKNOWN: Unknown error (retryable)

        Args:
            error_type: Internal error type from _classify_error()
            exception: Optional exception for additional context

        Returns:
            Standard error code string
        """
        # Map internal error types to standard codes
        error_mapping = {
            "infrastructure": "SEARCH_FAILED",
            "scraping": "SEARCH_FAILED",
            "rate_limit": "RATE_LIMITED",
            "auth": "AUTH_FAILED",
            "invalid_input": "INVALID_KEYWORD",
            "timeout": "TIMEOUT",
        }

        # Check exception message for more specific error codes
        if exception:
            error_message = str(exception).lower()

            if any(
                term in error_message
                for term in ["rate limit", "too many requests", "429"]
            ):
                return "RATE_LIMITED"
            if any(
                term in error_message
                for term in ["auth", "unauthorized", "forbidden", "401", "403"]
            ):
                return "AUTH_FAILED"
            if any(
                term in error_message
                for term in ["invalid keyword", "invalid query", "bad request"]
            ):
                return "INVALID_KEYWORD"
            if any(term in error_message for term in ["timeout", "timed out"]):
                return "TIMEOUT"

        return error_mapping.get(error_type, "UNKNOWN")

    async def _process_crawl_results_with_batch(
        self,
        crawl_results: List[CrawlResult],
        job_id: str,
        keyword: Optional[str],
        task_type: str,
        batch_size: int = 50,
    ) -> List[str]:
        """
        Process crawl results through batch upload system.

        Loops through results, adds successful ones to batch via CrawlerService,
        flushes remaining items at the end, and cleans up batch state.

        Args:
            crawl_results: List of CrawlResult from crawler
            job_id: Job identifier
            keyword: Search keyword context
            task_type: Task type for routing
            batch_size: Items per batch (default: 50)

        Returns:
            List of MinIO paths for uploaded batches
        """
        minio_paths: List[str] = []

        try:
            for result in crawl_results:
                if result.success:
                    try:
                        path = await self.crawler_service.add_to_batch(
                            job_id=job_id,
                            result=result,
                            keyword=keyword,
                            task_type=task_type,
                            batch_size=batch_size,
                        )
                        if path:
                            minio_paths.append(path)
                    except Exception as e:
                        logger.error(f"Failed to add to batch for job {job_id}: {e}")
                        # Continue processing other results

            # Flush remaining items in batch
            try:
                final_path = await self.crawler_service.flush_batch(
                    job_id=job_id,
                    keyword=keyword,
                    task_type=task_type,
                )
                if final_path:
                    minio_paths.append(final_path)
            except Exception as e:
                logger.error(f"Failed to flush batch for job {job_id}: {e}")

        finally:
            # Always cleanup batch state
            self.crawler_service.clear_batch_state(job_id)

        return minio_paths

    def _normalize_time_range(self, value: Any) -> Optional[int]:
        """Validate and normalize time_range payload field."""
        if value is None:
            return None

        if isinstance(value, bool):
            raise ValueError("time_range must be a positive integer (days)")

        if isinstance(value, str):
            value = value.strip()
            if not value:
                return None

        try:
            normalized = int(value)
        except (TypeError, ValueError):
            raise ValueError("time_range must be a positive integer (days)")

        if normalized < 1:
            raise ValueError("time_range must be >= 1 day")

        return normalized

    def _parse_iso_date(self, value: Any) -> Optional[datetime]:
        """Parse ISO 8601 date string to datetime object (UTC)."""
        if not value:
            return None

        if isinstance(value, datetime):
            return (
                value
                if value.tzinfo
                else value.replace(
                    tzinfo=(
                        datetime.timezone.utc if hasattr(datetime, "timezone") else None
                    )
                )
            )

        if isinstance(value, str):
            try:
                # Replace Z with +00:00 for fromisoformat
                val = value.replace("Z", "+00:00")
                dt = datetime.fromisoformat(val)
                # Ensure UTC awareness
                if dt.tzinfo is None:
                    # Assume UTC if no timezone
                    from datetime import timezone

                    dt = dt.replace(tzinfo=timezone.utc)
                return dt
            except ValueError:
                logger.warning(f"Invalid date format: {value}")
                return None
        return None

    async def _record_search_session(
        self, keyword: str, video_urls: List[str], sort_by: str, job_id: Optional[str]
    ) -> None:
        """Persist search session metadata if repository available."""
        if not self.search_session_repo:
            return

        session = SearchSession(
            search_id=f"search-{uuid.uuid4()}",
            source=SourcePlatform.YOUTUBE,
            keyword=keyword,
            sort_by=SearchSortBy(sort_by.upper()) if sort_by else None,
            searched_at=datetime.utcnow(),
            total_found=len(video_urls),
            urls=video_urls,
            job_id=job_id,
            params_raw=None,
        )
        await self.search_session_repo.save_search_session(session)

    def _classify_error(self, exception: Exception) -> str:
        """
        Classify error as infrastructure or scraping error.

        Infrastructure errors:
        - MongoDB/Database connection/operation errors
        - MinIO/S3 connection errors
        - Network connection errors
        - System resource errors

        Scraping errors:
        - Invalid data, parsing errors
        - YouTube API errors, rate limits
        - Video not found, unavailable content
        - Other application-level errors

        Returns:
            'infrastructure' or 'scraping'
        """
        exception_name = type(exception).__name__
        error_message = str(exception).lower()

        # Check exception type for known infrastructure errors
        infrastructure_patterns = [
            # MongoDB/PyMongo errors
            "pymongo",
            "mongo",
            "connectionfailure",
            "serverselectiontimeout",
            "networktimeout",
            "autoreconnect",
            "configurationerror",
            # MinIO/Boto3/S3 errors
            "boto",
            "s3",
            "minio",
            "endpointconnectionerror",
            "connecttimeout",
            # General network/connection errors
            "connectionerror",
            "timeout",
            "gaierror",
            "refused",
            "unreachable",
            "socket",
            "ssl",
            # System errors
            "memoryerror",
            "oserror",
            "ioerror",
        ]

        # Check exception name and message for infrastructure patterns
        for pattern in infrastructure_patterns:
            if pattern in exception_name.lower() or pattern in error_message:
                return "infrastructure"

        # Check for specific error messages
        if any(
            msg in error_message
            for msg in [
                "connection refused",
                "connection reset",
                "connection timeout",
                "cannot connect",
                "database",
                "no such host",
                "network is unreachable",
                "broken pipe",
            ]
        ):
            return "infrastructure"

        # Default to scraping error (will be ACKed)
        return "scraping"
