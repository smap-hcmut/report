"""
Application Settings with Pydantic
Environment-based configuration for RabbitMQ, MongoDB, and Crawler
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import model_validator
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=False
    )

    # ========== RabbitMQ Settings ==========
    rabbitmq_host: str = "localhost"
    rabbitmq_port: int = 5672
    rabbitmq_user: str = "guest"
    rabbitmq_password: str = "guest"
    rabbitmq_vhost: str = "/"
    rabbitmq_exchange: str = "tiktok_exchange"
    rabbitmq_queue_name: str = "tiktok_crawl_queue"
    rabbitmq_routing_key: str = "tiktok.crawl"
    rabbitmq_prefetch_count: int = 1  # Max concurrent messages per worker

    # ========== Result Publisher Settings ==========
    result_publisher_enabled: bool = True  # Enable result message publishing
    result_exchange_name: str = "tiktok_exchange"  # Exchange for dry-run results
    result_queue_name: str = "tiktok_result_queue"  # Queue for result messages
    result_routing_key: str = "tiktok.res"  # Routing key for result messages

    # ========== Event Publisher Settings (data.collected events) ==========
    event_publisher_enabled: bool = True  # Enable data.collected event publishing
    event_exchange_name: str = "smap.events"  # Exchange for events (topic type)
    event_routing_key: str = "data.collected"  # Routing key for data.collected events

    @property
    def rabbitmq_url(self) -> str:
        """Construct RabbitMQ connection URL"""
        return f"amqp://{self.rabbitmq_user}:{self.rabbitmq_password}@{self.rabbitmq_host}:{self.rabbitmq_port}/{self.rabbitmq_vhost}"

    # ========== MongoDB Settings ==========
    mongodb_host: str = "localhost"
    mongodb_port: int = 27017
    mongodb_user: Optional[str] = None
    mongodb_password: Optional[str] = None
    mongodb_database: str = "tiktok_crawl"
    mongodb_auth_source: str = "admin"

    @property
    def mongodb_url(self) -> str:
        """Construct MongoDB connection URL"""
        if self.mongodb_user and self.mongodb_password:
            return f"mongodb://{self.mongodb_user}:{self.mongodb_password}@{self.mongodb_host}:{self.mongodb_port}/{self.mongodb_database}?authSource={self.mongodb_auth_source}"
        return (
            f"mongodb://{self.mongodb_host}:{self.mongodb_port}/{self.mongodb_database}"
        )

    # ========== Crawler Settings ==========
    crawler_headless: bool = True
    crawler_timeout: int = 30000  # milliseconds
    crawler_wait_after_load: int = 3000  # milliseconds
    crawler_scroll_delay: int = 1500  # milliseconds
    crawler_max_scroll_attempts: int = 10
    crawler_user_agent: str = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )

    # Concurrent crawling
    crawler_max_concurrent: int = 8  # Max concurrent crawl tasks

    # Rate limiting
    crawler_requests_per_minute: int = 20
    crawler_delay_min: int = 2  # seconds
    crawler_delay_max: int = 5  # seconds

    # ========== Limit Settings ==========
    # Default limits (applied when payload doesn't specify)
    default_search_limit: int = 50  # research_keyword, dryrun_keyword
    default_limit_per_keyword: int = 50  # research_and_crawl
    default_profile_limit: int = 100  # fetch_profile_content
    default_crawl_links_limit: int = 200  # crawl_links max URLs

    # Hard limits (safety caps to prevent resource exhaustion)
    max_search_limit: int = 500  # Maximum for search-based tasks
    max_crawl_links_limit: int = 1000  # Maximum for crawl_links
    max_profile_limit: int = 500  # Maximum for fetch_profile_content

    # ========== Media Download Settings ==========
    # NEW: Media download configuration for audio/video files
    media_download_dir: str = "./downloads"  # Storage prefix (MinIO)
    media_download_enabled: bool = (
        True  # DEFAULT: Enable media downloads (can be overridden per-message via media_download_enabled)
    )
    media_default_type: str = "audio"  # Default media type: "audio" or "video"
    media_enable_ffmpeg: bool = True  # Enable ffmpeg fallback for audio extraction
    media_ffmpeg_path: str = "ffmpeg"  # Path to ffmpeg executable
    media_max_file_size_mb: int = 500  # Maximum file size in MB
    media_download_timeout: int = 300  # Download timeout in seconds
    media_chunk_size: int = 8192  # Download chunk size in bytes (8KB)

    # ========== Compression Settings ==========
    compression_enabled: bool = True  # Enable Zstd compression for data
    compression_algorithm: str = (
        "zstd"  # Compression algorithm (currently only zstd supported)
    )
    compression_default_level: int = (
        2  # Default level: 0=none, 1=fast, 2=default, 3=best
    )
    compression_min_size_bytes: int = 1024  # Don't compress files smaller than 1KB

    # ========== Async Upload Settings ==========
    minio_async_upload_enabled: bool = (
        False  # Disabled: sync upload ensures file available immediately
    )
    minio_async_upload_workers: int = 4  # Number of concurrent upload workers
    minio_async_upload_queue_size: int = 100  # Maximum upload queue size
    minio_upload_chunk_size: int = 5242880  # 5MB upload chunk size
    minio_progress_update_interval: float = 0.5  # Progress update interval in seconds

    # ========== MinIO Storage Settings ==========
    minio_endpoint: str = "localhost:9000"
    minio_access_key: Optional[str] = None
    minio_secret_key: Optional[str] = None
    minio_bucket: str = "tiktok-media"
    minio_bucket_model: str = "tiktok-models"
    minio_use_ssl: bool = False

    # ========== Archival Settings ==========
    enable_json_archive: bool = True  # Enable flat file archival of scraped data
    minio_archive_bucket: str = "tiktok-archive"  # MinIO bucket for archived JSON data
    enable_db_persistence: bool = (
        False  # DEFAULT: Enable MongoDB persistence (can be overridden per-message via save_to_db_enabled)
    )

    # ========== Batch Upload Settings ==========
    batch_size: int = 50  # Number of items per batch for MinIO upload
    batch_upload_enabled: bool = True  # Enable batch upload to MinIO
    minio_crawl_results_bucket: str = (
        "crawl-results"  # MinIO bucket for batch crawl results
    )

    # ========== Metadata Settings (for multi-region support) ==========
    default_lang: str = "vi"  # Default language code for crawled content
    default_region: str = "VN"  # Default region code for crawled content
    pipeline_version: str = "crawler_tiktok_v3"  # Pipeline version identifier

    # ========== Playwright Remote Settings ==========
    playwright_ws_endpoint: Optional[str] = None

    # ========== Playwright REST API Settings ==========
    playwright_rest_api_enabled: bool = (
        True  # Enable Playwright REST API for profile scraping
    )
    playwright_rest_api_url: Optional[str] = (
        "http://playwright-service:8001"  # Playwright REST API base URL (e.g., http://localhost:8001)
    )

    # ========== Speech-to-Text Settings ==========
    stt_api_enabled: bool = True  # Enable STT transcription
    stt_api_url: str = "http://172.16.21.230/transcribe"  # STT API endpoint
    stt_api_key: str = "smap-internal-key-changeme"  # API key for authentication
    stt_timeout: int = 300  # Request timeout in seconds
    stt_presigned_url_expires_hours: int = 168  # Presigned URL expiration (7 days)

    # Async STT polling configuration
    stt_polling_max_retries: int = 60  # Maximum number of polling attempts
    stt_polling_wait_interval: int = 3  # Seconds to wait between polling attempts

    # ========== Application Settings ==========
    app_env: str = "development"  # development, production
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR

    # Worker settings
    worker_name: str = "tiktok-worker-1"
    worker_max_retries: int = 3  # Max retries for failed tasks
    worker_retry_delay: int = 5  # seconds between retries

    @model_validator(mode="after")
    def validate_stt_polling_config(self):
        """Validate STT polling configuration parameters"""
        # Validate max_retries
        if self.stt_polling_max_retries <= 0:
            logger.warning(
                f"Invalid STT_POLLING_MAX_RETRIES value: {self.stt_polling_max_retries}. "
                f"Must be positive. Using default value: 60"
            )
            self.stt_polling_max_retries = 60

        # Validate wait_interval
        if self.stt_polling_wait_interval <= 0:
            logger.warning(
                f"Invalid STT_POLLING_WAIT_INTERVAL value: {self.stt_polling_wait_interval}. "
                f"Must be positive. Using default value: 3"
            )
            self.stt_polling_wait_interval = 3

        return self


# Global settings instance
settings = Settings()
