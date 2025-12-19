"""
Bootstrap - Dependency Injection Container
Wires up all dependencies following Clean Architecture principles
Updated to match refactor_modelDB.md schema

This is the "composition root" where we:
1. Create all infrastructure implementations (adapters)
2. Inject them into application services
3. Return fully wired-up services ready to use
"""

import logging
from motor.motor_asyncio import AsyncIOMotorClient
from playwright.async_api import async_playwright, Browser, BrowserContext
from typing import Optional
from minio import Minio

from config import settings
from utils.logger import logger

# Domain (no dependencies)
# (Domain entities are imported as needed)

# Application layer (interfaces)
from application.crawler_service import CrawlerService
from application.task_service import TaskService

# Infrastructure adapters (implementations)
from internal.adapters.repository_mongo import (
    MongoRepository,
    MongoContentRepository,  # Changed from MongoVideoRepository
    MongoAuthorRepository,  # Changed from MongoCreatorRepository
    MongoCommentRepository,
)
from internal.adapters.scrapers_tiktok import (
    MediaDownloader,
    VideoAPI,
    CreatorAPI,
    CommentScraper,
    SearchScraper,
    ProfileScraper,
)
from internal.infrastructure.minio.storage import MinioMediaStorage, MinioStorageConfig
from internal.infrastructure.compression import ZstdCompressor
from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher
from internal.infrastructure.rabbitmq.event_publisher import DataCollectedEventPublisher


class Bootstrap:
    """
    Dependency Injection Container
    Creates and wires up all dependencies for the application
    """

    def __init__(self):
        self.logger = logger

        # Database
        self.db_client: Optional[AsyncIOMotorClient] = None
        self.db = None
        self.mongo_repo: Optional[MongoRepository] = None

        # Repositories
        self.content_repo = None  # Changed from video_repo
        self.author_repo = None  # Changed from creator_repo
        self.comment_repo = None

        # Browser (for scrapers that need it)
        self.playwright = None
        self.browser: Optional[Browser] = None
        self.persistent_context: Optional[BrowserContext] = None

        # Scrapers
        self.video_scraper = None
        self.creator_scraper = None
        self.comment_scraper = None
        self.search_scraper = None
        self.profile_scraper = None
        self.media_downloader = None
        self.minio_client: Optional[Minio] = None
        self.media_storage: Optional[MinioMediaStorage] = None
        self.archive_storage: Optional[MinioMediaStorage] = None
        self.batch_storage: Optional[MinioMediaStorage] = None  # For batch uploads
        self.speech2text_client = None  # STT client

        # Result Publisher
        self.result_publisher: Optional[RabbitMQPublisher] = None

        # Event Publisher (for data.collected events)
        self.event_publisher: Optional[DataCollectedEventPublisher] = None

        # Services
        self.crawler_service = None
        self.task_service = None

    async def init_infrastructure(self):
        """
        Initialize infrastructure layer (adapters)
        This includes database, scrapers, and other external dependencies
        """
        self.logger.info("=" * 70)
        self.logger.info("INITIALIZING INFRASTRUCTURE")
        self.logger.info("=" * 70)

        # 1. Initialize Database
        await self._init_database()

        # 2. Initialize Browser (for scrapers that need it)
        await self._init_browser()

        # 3. Initialize Scrapers
        await self._init_scrapers()

        # 4. Initialize Media Downloader
        self._init_media_downloader()

        # 5. Initialize Result Publisher
        await self._init_result_publisher()

        # 6. Initialize Event Publisher (for data.collected events)
        await self._init_event_publisher()

        self.logger.info("Infrastructure initialization complete")

    async def _init_database(self):
        """Initialize MongoDB connection and repositories"""
        try:
            self.logger.info("Connecting to MongoDB...")

            # Create MongoDB repository
            self.mongo_repo = MongoRepository(
                default_max_retries=settings.worker_max_retries
            )
            await self.mongo_repo.connect(
                mongodb_url=settings.mongodb_url,
                mongodb_database=settings.mongodb_database,
            )

            # Get repository instances
            self.content_repo = self.mongo_repo.content_repo  # Changed from video_repo
            self.author_repo = self.mongo_repo.author_repo  # Changed from creator_repo
            self.comment_repo = self.mongo_repo.comment_repo

            # Get and log stats
            stats = await self.mongo_repo.get_stats()
            self.logger.info(f"MongoDB Stats: {stats}")

        except Exception as e:
            self.logger.error(f"Failed to initialize database: {e}")
            raise

    async def _init_browser(self):
        """Initialize Playwright browser for scrapers that need it"""
        try:
            self.logger.info("Initializing Playwright browser...")

            # Start playwright
            self.playwright = await async_playwright().start()

            # Check if remote Playwright service is configured
            if settings.playwright_ws_endpoint:
                # Connect to remote Playwright service
                self.logger.info(
                    f"Connecting to remote Playwright service at {settings.playwright_ws_endpoint}"
                )
                self.browser = await self.playwright.chromium.connect(
                    ws_endpoint=settings.playwright_ws_endpoint
                )
                self.logger.info("Connected to remote Playwright service successfully")
            else:
                # Launch browser locally (fallback for development)
                self.logger.info("Launching local Playwright browser...")
                self.browser = await self.playwright.chromium.launch(
                    headless=settings.crawler_headless,
                    args=[
                        "--disable-blink-features=AutomationControlled",
                        "--disable-dev-shm-usage",
                        "--no-sandbox",
                    ],
                )
                self.logger.info("Local Playwright browser launched successfully")

            # Initialize Context for ProfileScraper
            # We use a dedicated context on the remote browser to allow custom settings
            # and potential session persistence (via storage_state if needed)
            self.logger.info("Initializing Context for ProfileScraper...")

            if self.browser:
                # Check if there are existing contexts (Persistent Context from Server)
                if self.browser.contexts:
                    self.logger.info(
                        f"Using existing Persistent Context (count: {len(self.browser.contexts)})"
                    )
                    self.persistent_context = self.browser.contexts[0]
                else:
                    self.logger.warning(
                        "No existing context found. Creating NEW Incognito Context (No Persistence!)"
                    )
                    self.persistent_context = await self.browser.new_context(
                        viewport={"width": 1920, "height": 1080},
                        user_agent=settings.crawler_user_agent,
                        locale="en-US",
                        timezone_id="America/New_York",
                    )
                self.logger.info("ProfileScraper Context initialized")
            else:
                self.logger.error(
                    "Browser not initialized, cannot create ProfileScraper context"
                )
                raise RuntimeError("Browser not initialized")

        except Exception as e:
            self.logger.error(f"Failed to initialize browser: {e}")
            raise

    async def _init_scrapers(self):
        """Initialize scraper implementations"""
        try:
            self.logger.info("Initializing scrapers...")

            # Create scraper instances
            # VideoAPI and CreatorAPI don't need browser (they use HTTP)
            self.video_scraper = VideoAPI()
            self.creator_scraper = CreatorAPI()

            # CommentScraper, SearchScraper, and ProfileScraper need browser for Playwright
            self.comment_scraper = CommentScraper(browser=self.browser)
            self.search_scraper = SearchScraper(browser=self.browser)

            # Initialize ProfileScraper with optional REST API client
            playwright_rest_client = None
            use_rest_api = False

            if (
                settings.playwright_rest_api_enabled
                and settings.playwright_rest_api_url
            ):
                self.logger.info(
                    f"Playwright REST API enabled, initializing client for {settings.playwright_rest_api_url}"
                )
                from internal.infrastructure.rest_client import PlaywrightRestClient

                playwright_rest_client = PlaywrightRestClient(
                    base_url=settings.playwright_rest_api_url,
                    timeout=3000,  # 50 minutes timeout for long scrapes
                )
                use_rest_api = True
                self.logger.info("Playwright REST API client initialized successfully")

            self.profile_scraper = ProfileScraper(
                browser=self.persistent_context,
                playwright_rest_client=playwright_rest_client,
                use_rest_api=use_rest_api,
            )

            # Initialize Speech-to-Text client (if enabled)
            if settings.stt_api_enabled and settings.stt_api_url:
                self.logger.info(
                    f"STT API enabled, initializing client for {settings.stt_api_url}"
                )
                from internal.infrastructure.rest_client import Speech2TextRestClient

                self.speech2text_client = Speech2TextRestClient(
                    base_url=settings.stt_api_url,
                    api_key=settings.stt_api_key,
                    timeout=settings.stt_timeout,
                    max_retries=settings.stt_polling_max_retries,
                    wait_interval=settings.stt_polling_wait_interval,
                )
                self.logger.info("STT client initialized successfully")
            else:
                self.logger.info("STT API disabled or not configured")

            self.logger.info("Scrapers initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize scrapers: {e}")
            raise

    def _init_media_downloader(self):
        """Initialize media downloader"""
        try:
            self.logger.info("Initializing media downloader...")

            missing = [
                name
                for name, value in [
                    ("MINIO_ENDPOINT", settings.minio_endpoint),
                    ("MINIO_ACCESS_KEY", settings.minio_access_key),
                    ("MINIO_SECRET_KEY", settings.minio_secret_key),
                    ("MINIO_BUCKET", settings.minio_bucket),
                ]
                if not value
            ]
            if missing:
                raise RuntimeError(
                    f"Missing required MinIO configuration values: {', '.join(missing)}"
                )

            self.logger.info(
                "Configuring MinIO media storage (bucket=%s, secure=%s, compression=%s)",
                settings.minio_bucket,
                settings.minio_use_ssl,
                settings.compression_enabled,
            )
            self.minio_client = Minio(
                endpoint=settings.minio_endpoint,
                access_key=settings.minio_access_key,
                secret_key=settings.minio_secret_key,
                secure=settings.minio_use_ssl,
            )
            storage_config = MinioStorageConfig(
                bucket=settings.minio_bucket,
                base_path=None,
                enable_compression=settings.compression_enabled,
                compression_level=settings.compression_default_level,
                enable_async_upload=settings.minio_async_upload_enabled,
                async_upload_workers=settings.minio_async_upload_workers,
            )
            compressor = ZstdCompressor()
            self.media_storage = MinioMediaStorage(
                client=self.minio_client, config=storage_config, compressor=compressor
            )
            storage = self.media_storage

            # Initialize Archive Storage (if enabled)
            if settings.enable_json_archive and settings.minio_archive_bucket:
                self.logger.info(
                    f"Configuring Archive Storage (bucket={settings.minio_archive_bucket})"
                )
                archive_config = MinioStorageConfig(
                    bucket=settings.minio_archive_bucket,
                    base_path=None,
                    enable_compression=settings.compression_enabled,
                    compression_level=settings.compression_default_level,
                    enable_async_upload=False,  # Synchronous upload for metadata safety
                    async_upload_workers=1,
                )
                self.archive_storage = MinioMediaStorage(
                    client=self.minio_client,
                    config=archive_config,
                    compressor=compressor,
                )

            # Initialize Batch Storage (for batch uploads to crawl-results bucket)
            if settings.minio_crawl_results_bucket:
                self.logger.info(
                    f"Configuring Batch Storage (bucket={settings.minio_crawl_results_bucket})"
                )
                batch_config = MinioStorageConfig(
                    bucket=settings.minio_crawl_results_bucket,
                    base_path=None,
                    enable_compression=settings.compression_enabled,
                    compression_level=settings.compression_default_level,
                    enable_async_upload=False,  # Synchronous for data integrity
                    async_upload_workers=1,
                )
                self.batch_storage = MinioMediaStorage(
                    client=self.minio_client,
                    config=batch_config,
                    compressor=compressor,
                )

            self.media_downloader = MediaDownloader(
                enable_ffmpeg=settings.media_enable_ffmpeg,
                ffmpeg_path=settings.media_ffmpeg_path,
                max_file_size_mb=settings.media_max_file_size_mb,
                download_timeout=settings.media_download_timeout,
                chunk_size=settings.media_chunk_size,
                storage=storage,
            )

            self.logger.info("Media downloader initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize media downloader: {e}")
            raise

    async def _init_result_publisher(self):
        """Initialize RabbitMQ result publisher"""
        try:
            if not settings.result_publisher_enabled:
                self.logger.info("Result publisher disabled in settings")
                return

            self.logger.info("Initializing RabbitMQ result publisher...")

            # Create publisher instance
            self.result_publisher = RabbitMQPublisher(
                connection_url=settings.rabbitmq_url,
                exchange_name=settings.result_exchange_name,
                routing_key=settings.result_routing_key,
            )

            # Connect to RabbitMQ
            await self.result_publisher.connect()

            self.logger.info(
                "Result publisher initialized successfully - Exchange: %s, Routing Key: %s",
                settings.result_exchange_name,
                settings.result_routing_key,
            )

        except Exception as e:
            self.logger.error(f"Failed to initialize result publisher: {e}")
            # Don't raise - allow application to continue without publisher
            # This makes the publisher optional for backward compatibility
            self.result_publisher = None
            self.logger.warning("Application will continue without result publisher")

    async def _init_event_publisher(self):
        """Initialize RabbitMQ event publisher for data.collected events"""
        try:
            if not settings.event_publisher_enabled:
                self.logger.info("Event publisher disabled in settings")
                return

            self.logger.info("Initializing RabbitMQ event publisher...")

            # Create event publisher instance
            self.event_publisher = DataCollectedEventPublisher(
                connection_url=settings.rabbitmq_url,
                exchange_name=settings.event_exchange_name,
                routing_key=settings.event_routing_key,
            )

            # Connect to RabbitMQ
            await self.event_publisher.connect()

            self.logger.info(
                "Event publisher initialized successfully - Exchange: %s, Routing Key: %s",
                settings.event_exchange_name,
                settings.event_routing_key,
            )

        except Exception as e:
            self.logger.error(f"Failed to initialize event publisher: {e}")
            # Don't raise - allow application to continue without event publisher
            self.event_publisher = None
            self.logger.warning("Application will continue without event publisher")

    def init_application_services(self):
        """
        Initialize application layer services
        Inject infrastructure dependencies into application services
        """
        self.logger.info("=" * 70)
        self.logger.info("INITIALIZING APPLICATION SERVICES")
        self.logger.info("=" * 70)

        # 1. Initialize CrawlerService with dependencies
        self.crawler_service = CrawlerService(
            video_scraper=self.video_scraper,
            creator_scraper=self.creator_scraper,
            comment_scraper=self.comment_scraper,
            search_scraper=self.search_scraper,
            profile_scraper=self.profile_scraper,
            content_repo=self.content_repo,  # Changed from video_repo
            author_repo=self.author_repo,  # Changed from creator_repo
            comment_repo=self.comment_repo,
            media_downloader=self.media_downloader,
            max_concurrency=settings.crawler_max_concurrent,
            archive_storage=self.archive_storage,
            enable_db_persistence=settings.enable_db_persistence,
            speech2text_client=self.speech2text_client,  # Inject STT client
            event_publisher=self.event_publisher,  # Inject event publisher for data.collected events
        )

        # Set batch storage for batch upload functionality
        if self.batch_storage:
            self.crawler_service.set_batch_storage(self.batch_storage)
            self.logger.info("Batch storage configured for CrawlerService")

        # 2. Initialize TaskService with dependencies
        self.task_service = TaskService(
            crawler_service=self.crawler_service,
            job_repo=self.mongo_repo,
            content_repo=self.content_repo,  # Changed from video_repo
            search_session_repo=self.mongo_repo.search_session_repo,  # Changed from search_result_repo
            result_publisher=self.result_publisher,  # Pass result publisher
            default_download_media=settings.media_download_enabled,
            default_media_type=settings.media_default_type,
            default_media_dir=settings.media_download_dir,
        )

        self.logger.info("Application services initialized successfully")

    async def startup(self):
        """
        Complete startup sequence
        1. Initialize infrastructure (adapters)
        2. Initialize application services
        """
        try:
            self.logger.info("=" * 70)
            self.logger.info("BOOTSTRAP: STARTING UP")
            self.logger.info("=" * 70)

            # Step 1: Infrastructure
            await self.init_infrastructure()

            # Step 2: Application services
            self.init_application_services()

            self.logger.info("=" * 70)
            self.logger.info("BOOTSTRAP: STARTUP COMPLETE")
            self.logger.info("=" * 70)

        except Exception as e:
            self.logger.error(f"Bootstrap startup failed: {e}")
            raise

    async def shutdown(self):
        """
        Cleanup all resources
        Close database connections, browser, async upload manager, etc.
        """
        try:
            self.logger.info("=" * 70)
            self.logger.info("BOOTSTRAP: SHUTTING DOWN")
            self.logger.info("=" * 70)

            # Close result publisher
            if self.result_publisher:
                self.logger.info("Closing result publisher...")
                await self.result_publisher.close()

            # Close event publisher
            if self.event_publisher:
                self.logger.info("Closing event publisher...")
                await self.event_publisher.close()

            # Stop async upload manager if enabled
            if self.media_storage:
                self.logger.info("Stopping async upload manager...")
                await self.media_storage.stop_async_upload()

            # Close browser
            if self.browser:
                self.logger.info("Closing browser...")
                await self.browser.close()

            # Close persistent context
            if self.persistent_context:
                self.logger.info("Closing persistent context...")
                await self.persistent_context.close()

            # Stop playwright
            if self.playwright:
                self.logger.info("Stopping playwright...")
                await self.playwright.stop()

            # Close database connection
            if self.mongo_repo:
                await self.mongo_repo.close()

            self.logger.info("Bootstrap shutdown complete")

        except Exception as e:
            self.logger.error(f"Error during bootstrap shutdown: {e}")

    def get_task_service(self) -> TaskService:
        """Get the task service (main entry point for queue consumers)"""
        if not self.task_service:
            raise RuntimeError("Bootstrap not initialized. Call startup() first.")
        return self.task_service

    def get_crawler_service(self) -> CrawlerService:
        """Get the crawler service"""
        if not self.crawler_service:
            raise RuntimeError("Bootstrap not initialized. Call startup() first.")
        return self.crawler_service
