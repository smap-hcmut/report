"""
Bootstrap - Dependency Injection Container
Wires up all dependencies following Clean Architecture principles

This is the "composition root" where we:
1. Create all infrastructure implementations (adapters)
2. Inject them into application services
3. Return fully wired-up services ready to use
"""

import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Optional
from minio import Minio

from config.settings import settings
from utils.logger import setup_logger

# Application layer
from application.crawler_service import CrawlerService
from application.task_service import TaskService

# Infrastructure adapters
from internal.adapters.repository_mongo import MongoRepository
from internal.adapters.scrapers_youtube import (
    YouTubeVideoScraper,
    YouTubeChannelScraper,
    YouTubeCommentScraper,
    YouTubeSearchScraper,
    YouTubeMediaDownloader,
)
from internal.infrastructure.minio.storage import MinioMediaStorage
from internal.infrastructure.ffmpeg.client import RemoteFFmpegClient
from internal.infrastructure.compression import ZstdCompressor
from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher
from internal.infrastructure.rabbitmq.event_publisher import DataCollectedEventPublisher


class Bootstrap:
    """
    Dependency Injection Container
    Creates and wires up all dependencies for the application
    """

    def __init__(self):
        # Setup logger
        log_level = getattr(logging, settings.log_level.upper(), logging.INFO)
        self.logger = setup_logger("youtube_crawler", log_level)

        # Repositories / database
        self.mongo_repo: Optional[MongoRepository] = None
        self.content_repo = None
        self.author_repo = None
        self.comment_repo = None
        self.search_session_repo = None
        self.job_repo = None

        # Thread pool executor for async wrappers
        self.executor: Optional[ThreadPoolExecutor] = None

        # Scrapers
        self.video_scraper = None
        self.channel_scraper = None
        self.comment_scraper = None
        self.search_scraper = None
        self.media_downloader = None
        self.ffmpeg_client: Optional[RemoteFFmpegClient] = None

        # MinIO storage (optional)
        self.minio_client: Optional[Minio] = None
        self.storage_service: Optional[MinioMediaStorage] = None
        self.archive_storage: Optional[MinioMediaStorage] = None
        self.batch_storage: Optional[MinioMediaStorage] = None  # For batch uploads

        # Gemini AI (optional)
        self.gemini_summarizer = None

        # Speech-to-Text client (optional)
        self.speech2text_client = None

        # RabbitMQ Publisher (optional)
        self.result_publisher: Optional[RabbitMQPublisher] = None

        # Event Publisher (optional)
        self.event_publisher: Optional[DataCollectedEventPublisher] = None

        # Services
        self.crawler_service = None
        self.task_service = None

    async def startup(self):
        """
        Initialize all infrastructure and application services
        """
        self.logger.info("=" * 70)
        self.logger.info("INITIALIZING YOUTUBE SCRAPER")
        self.logger.info("=" * 70)

        await self.init_infrastructure()
        self.init_application_services()

        self.logger.info("=" * 70)
        self.logger.info("YOUTUBE SCRAPER READY")
        self.logger.info("=" * 70)

    async def init_infrastructure(self):
        """
        Initialize infrastructure layer (adapters)
        """
        self.logger.info("Initializing infrastructure...")

        # 1. Initialize Database
        await self._init_database()

        # 2. Initialize Thread Pool Executor
        self._init_executor()

        # 3. Initialize MinIO (optional)
        self._init_storage()

        # 4. Initialize Scrapers
        self._init_scrapers()

        # 5. Initialize Gemini AI (optional)
        self._init_gemini()

        # 6. Initialize Result Publisher (optional)
        await self._init_result_publisher()

        # 7. Initialize Event Publisher (optional)
        await self._init_event_publisher()

        self.logger.info("Infrastructure initialization complete")

    async def _init_database(self):
        """Initialize MongoDB connection and repositories"""
        try:
            self.logger.info("Connecting to MongoDB (YouTube schema)...")
            max_retries = getattr(settings, "worker_max_retries", 3)
            self.mongo_repo = MongoRepository(default_max_retries=max_retries)
            await self.mongo_repo.connect(
                settings.mongodb_url, settings.mongodb_database
            )

            self.content_repo = self.mongo_repo.content_repo
            self.author_repo = self.mongo_repo.author_repo
            self.comment_repo = self.mongo_repo.comment_repo
            self.search_session_repo = self.mongo_repo.search_session_repo
            self.job_repo = self.mongo_repo

            self.logger.info("MongoDB repositories initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize database: {e}")
            raise

    def _init_executor(self):
        """Initialize thread pool executor for async wrappers"""
        self.executor = ThreadPoolExecutor(max_workers=settings.crawler_max_concurrent)
        self.logger.info(
            f"Thread pool executor initialized (max_workers: {settings.crawler_max_concurrent})"
        )

    def _init_scrapers(self):
        """Initialize all scrapers"""
        try:
            self.logger.info("Initializing scrapers...")

            # Create scrapers with shared executor
            self.video_scraper = YouTubeVideoScraper(
                executor=self.executor,
                quiet=settings.crawler_quiet,
                no_warnings=settings.crawler_no_warnings,
            )

            self.channel_scraper = YouTubeChannelScraper(
                executor=self.executor,
                quiet=settings.crawler_quiet,
                no_warnings=settings.crawler_no_warnings,
            )

            self.comment_scraper = YouTubeCommentScraper(
                executor=self.executor,
                default_max_comments=settings.crawler_max_comments,
            )

            self.search_scraper = YouTubeSearchScraper(
                executor=self.executor,
                quiet=settings.crawler_quiet,
                no_warnings=settings.crawler_no_warnings,
            )

            ffmpeg_client = None
            if settings.media_ffmpeg_service_url:
                if not self.storage_service:
                    self.logger.warning(
                        "FFmpeg service URL configured but MinIO storage is disabled; remote conversion will be skipped."
                    )
                else:
                    ffmpeg_client = RemoteFFmpegClient(
                        base_url=settings.media_ffmpeg_service_url,
                        timeout=settings.media_ffmpeg_timeout,
                        max_retries=settings.media_ffmpeg_max_retries,
                        backoff_factor=settings.media_ffmpeg_backoff_factor,
                        circuit_breaker_enabled=settings.media_ffmpeg_circuit_breaker,
                        circuit_failure_threshold=settings.media_ffmpeg_circuit_threshold,
                        circuit_recovery_timeout=settings.media_ffmpeg_circuit_recovery,
                        max_connections=settings.media_ffmpeg_max_connections,
                        max_keepalive_connections=settings.media_ffmpeg_keepalive_connections,
                    )
                    self.logger.info(
                        "Remote FFmpeg client initialized: %s (retries=%d, circuit_breaker=%s)",
                        settings.media_ffmpeg_service_url,
                        settings.media_ffmpeg_max_retries,
                        settings.media_ffmpeg_circuit_breaker,
                    )
            self.ffmpeg_client = ffmpeg_client
            if (
                not self.ffmpeg_client
                and settings.media_download_enabled
                and settings.media_default_type.lower() == "audio"
            ):
                self.logger.warning(
                    "Remote FFmpeg service URL is not configured. Audio downloads require the external FFmpeg service."
                )

            # Media downloader
            # Initialize STT client if enabled
            speech2text_client = None
            if settings.stt_api_enabled and settings.stt_api_url:
                from internal.infrastructure.rest_client import Speech2TextRestClient

                speech2text_client = Speech2TextRestClient(
                    base_url=settings.stt_api_url,
                    api_key=settings.stt_api_key,
                    timeout=settings.stt_timeout,
                    max_retries=settings.stt_polling_max_retries,
                    wait_interval=settings.stt_polling_wait_interval,
                )
                self.logger.info(
                    "Speech-to-Text client initialized: %s (timeout=%ds, max_retries=%d, wait_interval=%ds)",
                    settings.stt_api_url,
                    settings.stt_timeout,
                    settings.stt_polling_max_retries,
                    settings.stt_polling_wait_interval,
                )
            self.speech2text_client = speech2text_client

            self.media_downloader = YouTubeMediaDownloader(
                max_file_size_mb=settings.media_max_file_size_mb,
                download_timeout=settings.media_download_timeout,
                chunk_size=settings.media_chunk_size,
                storage=self.storage_service,
                ffmpeg_client=self.ffmpeg_client,
                speech2text_client=self.speech2text_client,
            )

            self.logger.info("Scrapers initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize scrapers: {e}")
            raise

    def _init_storage(self):
        """Initialize MinIO storage service (optional)"""
        try:
            self.logger.info("Initializing MinIO storage...")

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
                    f"Missing required MinIO settings: {', '.join(missing)}"
                )

            # Create MinIO client
            self.minio_client = Minio(
                endpoint=settings.minio_endpoint,
                access_key=settings.minio_access_key,
                secret_key=settings.minio_secret_key,
                secure=settings.minio_use_ssl,
            )

            # Create config for media storage
            from internal.infrastructure.minio.storage import MinioStorageConfig

            media_config = MinioStorageConfig(
                bucket=settings.minio_bucket,
                base_path=settings.minio_base_path,
                enable_compression=settings.compression_enabled,
                compression_level=settings.compression_default_level,
                enable_async_upload=settings.minio_async_upload_enabled,
                async_upload_workers=settings.minio_async_upload_workers,
            )

            # Create storage service
            self.storage_service = MinioMediaStorage(
                client=self.minio_client, config=media_config
            )

            # Initialize Archive Storage (if enabled)
            if settings.enable_json_archive and settings.minio_archive_bucket:
                self.logger.info(
                    f"Configuring Archive Storage (bucket={settings.minio_archive_bucket})"
                )

                archive_config = MinioStorageConfig(
                    bucket=settings.minio_archive_bucket,
                    enable_async_upload=True,  # Archive is usually sync
                    enable_compression=True,  # Always compress archives
                )

                self.archive_storage = MinioMediaStorage(
                    client=self.minio_client, config=archive_config
                )

            # Initialize Batch Storage (for batch uploads to crawl-results bucket)
            if settings.minio_crawl_results_bucket:
                self.logger.info(
                    f"Configuring Batch Storage (bucket={settings.minio_crawl_results_bucket})"
                )

                batch_config = MinioStorageConfig(
                    bucket=settings.minio_crawl_results_bucket,
                    enable_async_upload=False,  # Synchronous for data integrity
                    enable_compression=settings.compression_enabled,
                    compression_level=settings.compression_default_level,
                )

                self.batch_storage = MinioMediaStorage(
                    client=self.minio_client, config=batch_config
                )

            self.logger.info("MinIO storage initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize MinIO storage: {e}")
            raise

        if not self.storage_service:
            raise RuntimeError("MinIO storage must be configured for media uploads.")

    def _init_gemini(self):
        """Initialize Gemini AI summarizer (optional)"""
        if not settings.gemini_enabled:
            self.logger.info("Gemini AI summarizer disabled (GEMINI_ENABLED=false)")
            return

        try:
            self.logger.info("Initializing Gemini AI summarizer...")

            if not settings.gemini_api_key:
                self.logger.warning(
                    "Gemini enabled but GEMINI_API_KEY not set. "
                    "AI summarization will be unavailable."
                )
                return

            # Import here to avoid circular imports and allow optional dependency
            from internal.infrastructure.gemini import GeminiSummarizer

            self.gemini_summarizer = GeminiSummarizer(
                api_key=settings.gemini_api_key,
                model_name=settings.gemini_model,
                transcript_languages=settings.gemini_transcript_languages_list,
                timeout=settings.gemini_timeout,
            )

            self.logger.info(
                f"Gemini AI summarizer initialized successfully "
                f"(model: {settings.gemini_model})"
            )

        except Exception as e:
            self.logger.warning(
                f"Failed to initialize Gemini AI summarizer: {e}. "
                f"Will continue without AI summarization."
            )
            self.gemini_summarizer = None

    async def _init_result_publisher(self):
        """Initialize RabbitMQ result publisher (optional)"""
        if not settings.result_publisher_enabled:
            self.logger.info(
                "Result publisher disabled (RESULT_PUBLISHER_ENABLED=false)"
            )
            return

        try:
            self.logger.info("Initializing RabbitMQ result publisher...")

            # Validate required settings
            if not settings.rabbitmq_url:
                self.logger.warning(
                    "Result publisher enabled but RABBITMQ_URL not set. "
                    "Result publishing will be unavailable."
                )
                return

            if not settings.result_exchange_name:
                self.logger.warning(
                    "Result publisher enabled but RESULT_EXCHANGE_NAME not set. "
                    "Result publishing will be unavailable."
                )
                return

            if not settings.result_routing_key:
                self.logger.warning(
                    "Result publisher enabled but RESULT_ROUTING_KEY not set. "
                    "Result publishing will be unavailable."
                )
                return

            # Create publisher instance
            self.result_publisher = RabbitMQPublisher(
                connection_url=settings.rabbitmq_url,
                exchange_name=settings.result_exchange_name,
                routing_key=settings.result_routing_key,
            )

            # Connect to RabbitMQ
            await self.result_publisher.connect()

            self.logger.info(
                "RabbitMQ result publisher initialized successfully "
                "(exchange: %s, routing_key: %s)",
                settings.result_exchange_name,
                settings.result_routing_key,
            )

        except Exception as e:
            self.logger.warning(
                "Failed to initialize RabbitMQ result publisher: %s. "
                "Will continue without result publishing.",
                e,
            )
            self.result_publisher = None

    async def _init_event_publisher(self):
        """Initialize RabbitMQ event publisher for data.collected events (optional)"""
        if not settings.event_publisher_enabled:
            self.logger.info("Event publisher disabled (EVENT_PUBLISHER_ENABLED=false)")
            return

        try:
            self.logger.info("Initializing RabbitMQ event publisher...")

            # Validate required settings
            if not settings.rabbitmq_url:
                self.logger.warning(
                    "Event publisher enabled but RABBITMQ_URL not set. "
                    "Event publishing will be unavailable."
                )
                return

            # Create event publisher instance
            self.event_publisher = DataCollectedEventPublisher(
                connection_url=settings.rabbitmq_url,
                exchange_name=settings.event_exchange_name,
                routing_key=settings.event_routing_key,
            )

            # Connect to RabbitMQ
            await self.event_publisher.connect()

            self.logger.info(
                "RabbitMQ event publisher initialized successfully "
                "(exchange: %s, routing_key: %s)",
                settings.event_exchange_name,
                settings.event_routing_key,
            )

        except Exception as e:
            self.logger.warning(
                "Failed to initialize RabbitMQ event publisher: %s. "
                "Will continue without event publishing.",
                e,
            )
            self.event_publisher = None

    def init_application_services(self):
        """
        Initialize application services with injected dependencies
        """
        self.logger.info("Initializing application services...")

        # Create crawler service (main orchestration)
        self.crawler_service = CrawlerService(
            content_repo=self.content_repo,
            author_repo=self.author_repo,
            comment_repo=self.comment_repo,
            video_scraper=self.video_scraper,
            author_scraper=self.channel_scraper,
            comment_scraper=self.comment_scraper,
            search_scraper=self.search_scraper,
            channel_scraper=self.channel_scraper,
            media_downloader=self.media_downloader,
            max_concurrency=settings.crawler_max_concurrent,
            gemini_summarizer=self.gemini_summarizer,
            gemini_enabled=settings.gemini_enabled,
            archive_storage=self.archive_storage,
            enable_db_persistence=settings.enable_db_persistence,
            event_publisher=self.event_publisher,
        )

        # Set batch storage for batch upload functionality
        if self.batch_storage:
            self.crawler_service.set_batch_storage(self.batch_storage)
            self.logger.info("Batch storage configured for CrawlerService")

        # Create task service (handles queue tasks)
        self.task_service = TaskService(
            crawler_service=self.crawler_service,
            job_repo=self.job_repo,
            content_repo=self.content_repo,
            search_session_repo=self.search_session_repo,
            result_publisher=self.result_publisher,
            default_download_media=settings.media_download_enabled,
            default_media_type=settings.media_default_type,
            default_media_dir=settings.media_download_dir,
        )

        self.logger.info("Application services initialized successfully")

    async def shutdown(self):
        """Gracefully shutdown all services"""
        self.logger.info("Shutting down...")

        # Close scrapers
        if self.video_scraper:
            await self.video_scraper.close()
        if self.channel_scraper:
            await self.channel_scraper.close()
        if self.comment_scraper:
            await self.comment_scraper.close()
        if self.search_scraper:
            await self.search_scraper.close()

        # Close executor
        if self.executor:
            self.executor.shutdown(wait=True)

        # Close FFmpeg client (release HTTP connections)
        if self.ffmpeg_client:
            await self.ffmpeg_client.close()
            self.logger.info("FFmpeg client connections closed")

        # Close result publisher
        if self.result_publisher:
            await self.result_publisher.close()
            self.logger.info("Result publisher connection closed")

        # Close event publisher
        if self.event_publisher:
            await self.event_publisher.close()
            self.logger.info("Event publisher connection closed")

        # Close database
        if self.mongo_repo:
            await self.mongo_repo.close()

        self.logger.info("Shutdown complete")
