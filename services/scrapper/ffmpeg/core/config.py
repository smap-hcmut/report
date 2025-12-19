from datetime import timedelta
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration for the ffmpeg conversion service."""

    model_config = SettingsConfigDict(case_sensitive=False, extra="ignore")

    app_env: str = "development"
    log_level: str = "INFO"

    ffmpeg_path: str = "ffmpeg"
    ffmpeg_audio_bitrate: str = "192k"
    ffmpeg_timeout_seconds: int = 600
    max_concurrent_jobs: int = 2

    minio_endpoint: str = "localhost:9000"
    minio_access_key: str | None = None
    minio_secret_key: str | None = None
    minio_target_prefix: str = "audios"
    minio_presigned_ttl: int = 600  # seconds
    minio_upload_part_size: int = 5 * 1024 * 1024

    minio_bucket_source: str = Field(default="youtube-media", alias="MINIO_BUCKET")
    minio_bucket_target: str = Field(default="youtube-media", alias="MINIO_BUCKET_MODEL")
    minio_secure: bool = Field(default=False, alias="MINIO_USE_SSL")

    def presigned_expiry(self) -> timedelta:
        return timedelta(seconds=self.minio_presigned_ttl)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
