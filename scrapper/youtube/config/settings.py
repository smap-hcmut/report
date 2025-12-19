"""
Application Settings with Pydantic
Environment-based configuration for RabbitMQ, MongoDB, Crawler, and MinIO
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
    rabbitmq_exchange: str = "youtube_exchange"
    rabbitmq_queue_name: str = "youtube_crawl_queue"
    rabbitmq_routing_key: str = "youtube.crawl"
    rabbitmq_prefetch_count: int = 1  # Max concurrent messages per worker

    # ========== Result Publisher Settings ==========
    result_publisher_enabled: bool = True
    result_exchange_name: str = "youtube_exchange"
    result_queue_name: str = "youtube_result_queue"
    result_routing_key: str = "youtube.res"

    # ========== Event Publisher Settings ==========
    event_publisher_enabled: bool = True
    event_exchange_name: str = "smap.events"
    event_routing_key: str = "data.collected"

    @property
    def rabbitmq_url(self) -> str:
        """Construct RabbitMQ connection URL"""
        return f"amqp://{self.rabbitmq_user}:{self.rabbitmq_password}@{self.rabbitmq_host}:{self.rabbitmq_port}/{self.rabbitmq_vhost}"

    # ========== MongoDB Settings ==========
    mongodb_host: str = "localhost"
    mongodb_port: int = 27017
    mongodb_user: Optional[str] = None
    mongodb_password: Optional[str] = None
    mongodb_database: str = "youtube_crawl"
    mongodb_auth_source: str = "admin"

    @property
    def mongodb_url(self) -> str:
        """Construct MongoDB connection URL"""
        if self.mongodb_user and self.mongodb_password:
            return f"mongodb://{self.mongodb_user}:{self.mongodb_password}@{self.mongodb_host}:{self.mongodb_port}/{self.mongodb_database}?authSource={self.mongodb_auth_source}"
        return (
            f"mongodb://{self.mongodb_host}:{self.mongodb_port}/{self.mongodb_database}"
        )

    # ========== Persistence Settings ==========
    enable_db_persistence: bool = (
        True  # DEFAULT: Save Content/Author/Comment to MongoDB (can be overridden per-message via save_to_db_enabled)
    )

    # ========== Speech-to-Text Settings ==========
    stt_api_enabled: bool = True  # Enable STT transcription
    stt_api_url: str = "http://172.16.21.230/transcribe"  # STT API endpoint
    stt_api_key: str = "smap-internal-key-changeme"  # STT API authentication key
    stt_timeout: int = 300  # STT request timeout in seconds (5 minutes)
    stt_presigned_url_expires_hours: int = 168  # Presigned URL expiration (7 days)

    # STT Async API Configuration
    stt_polling_max_retries: int = 60  # Maximum polling attempts for async STT jobs
    stt_polling_wait_interval: int = 3  # Seconds to wait between polling attempts

    # ========== Crawler Settings ==========
    # yt-dlp settings
    crawler_quiet: bool = True  # Suppress yt-dlp output
    crawler_no_warnings: bool = True  # Suppress warnings
    crawler_max_concurrent: int = 8  # Max concurrent crawl tasks

    # Comment scraper
    crawler_max_comments: int = 200  # Default max comments per video

    # ========== Limit Settings ==========
    # Default limits (applied when payload doesn't specify)
    default_search_limit: int = 50  # research_keyword, dryrun_keyword
    default_limit_per_keyword: int = 50  # research_and_crawl
    default_channel_limit: int = 100  # fetch_channel_content
    default_crawl_links_limit: int = 200  # crawl_links max URLs

    # Hard limits (safety caps to prevent resource exhaustion)
    max_search_limit: int = 500  # Maximum for search-based tasks
    max_crawl_links_limit: int = 1000  # Maximum for crawl_links
    max_channel_limit: int = 500  # Maximum for fetch_channel_content

    # ========== Media Download Settings ==========
    media_download_dir: str = "./YOUTUBE"  # Local directory or MinIO prefix
    media_download_enabled: bool = (
        True  # DEFAULT: Enable media downloads (can be overridden per-message via media_download_enabled)
    )
    media_default_type: str = "audio"  # Default media type: "audio" or "video"
    media_ffmpeg_service_url: Optional[str] = None  # Remote ffmpeg service endpoint
    media_ffmpeg_timeout: int = 600  # Timeout for ffmpeg conversion requests (seconds)
    media_ffmpeg_max_retries: int = 3  # Maximum retry attempts for transient failures
    media_ffmpeg_backoff_factor: float = (
        2.0  # Exponential backoff multiplier for retries
    )
    media_ffmpeg_circuit_breaker: bool = True  # Enable circuit breaker pattern
    media_ffmpeg_circuit_threshold: int = 5  # Failures before opening circuit
    media_ffmpeg_circuit_recovery: float = 60.0  # Seconds before attempting recovery
    media_ffmpeg_max_connections: int = 100  # Max HTTP connections in pool
    media_ffmpeg_keepalive_connections: int = 20  # Max idle connections to keep alive
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
    minio_async_upload_enabled: bool = True  # Enable async upload (non-blocking)
    minio_async_upload_workers: int = 4  # Number of concurrent upload workers
    minio_async_upload_queue_size: int = 100  # Maximum upload queue size
    minio_upload_chunk_size: int = 5242880  # 5MB upload chunk size
    minio_progress_update_interval: float = 0.5  # Progress update interval in seconds

    # ========== Archival Settings ==========
    enable_json_archive: bool = (
        True  # DEFAULT: Enable flat file archival of scraped data (can be overridden per-message via archive_storage_enabled)
    )
    minio_archive_bucket: str = "youtube-archive"  # MinIO bucket for archived JSON data

    # ========== Batch Upload Settings ==========
    batch_size: int = (
        20  # Number of items per batch for MinIO upload (YouTube: smaller batches due to larger content)
    )
    batch_upload_enabled: bool = True  # Enable batch upload to MinIO
    minio_crawl_results_bucket: str = (
        "crawl-results"  # MinIO bucket for batch crawl results
    )

    # ========== Metadata Settings (for multi-region support) ==========
    default_lang: str = "vi"  # Default language code for crawled content
    default_region: str = "VN"  # Default region code for crawled content
    pipeline_version: str = "crawler_youtube_v3"  # Pipeline version identifier

    # ========== Gemini AI Summary Settings ==========
    gemini_enabled: bool = False  # Enable AI summary generation
    gemini_api_key: Optional[str] = None  # Gemini API key (required if enabled)
    gemini_model: str = "gemini-2.5-flash"  # Gemini model to use
    gemini_timeout: int = 120  # Gemini API timeout in seconds
    gemini_transcript_languages: str = (
        "en,vi,en-US,en-GB,vi-VN"  # Comma-separated language codes
    )

    @property
    def gemini_transcript_languages_list(self) -> list[str]:
        """Get transcript languages as a list"""
        return [
            lang.strip()
            for lang in self.gemini_transcript_languages.split(",")
            if lang.strip()
        ]

    @model_validator(mode="after")
    def validate_stt_polling_config(self) -> "Settings":
        """Validate STT polling configuration parameters"""
        if self.stt_polling_max_retries <= 0:
            logger.warning(
                f"Invalid STT_POLLING_MAX_RETRIES value: {self.stt_polling_max_retries}. "
                f"Using default value: 60"
            )
            self.stt_polling_max_retries = 60

        if self.stt_polling_wait_interval <= 0:
            logger.warning(
                f"Invalid STT_POLLING_WAIT_INTERVAL value: {self.stt_polling_wait_interval}. "
                f"Using default value: 3"
            )
            self.stt_polling_wait_interval = 3

        return self

    # ========== MinIO Storage Settings ==========
    minio_endpoint: str = "localhost:9000"
    minio_access_key: Optional[str] = None
    minio_secret_key: Optional[str] = None
    minio_bucket: str = "smap-stt-audio-files"  # Must match FFmpeg service bucket
    minio_use_ssl: bool = False
    minio_base_path: Optional[str] = None  # Base path prefix in bucket

    # ========== Application Settings ==========
    app_env: str = "development"  # development, production
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR

    # Worker settings
    worker_name: str = "youtube-worker-1"
    worker_max_retries: int = 3  # Max retries for failed tasks
    worker_retry_delay: int = 5  # seconds between retries
    worker_graceful_shutdown_timeout: int = 30  # seconds


# Global settings instance
settings = Settings()
