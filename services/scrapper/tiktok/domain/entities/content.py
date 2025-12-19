"""
Content Entity - Domain Layer
Business entity representing multi-platform content (video, post, etc.)
Replaces the old Video entity with exact schema from refactor_modelDB.md
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from ..enums import SourcePlatform, MediaType


class Content(BaseModel):
    """
    Content domain entity

    Represents content from multiple platforms (TikTok, YouTube, Facebook)
    with normalized fields. Exact schema from refactor_modelDB.md.
    """

    # Core identifiers
    source: SourcePlatform = Field(
        ..., description="Source platform (TIKTOK, YOUTUBE, FACEBOOK)"
    )
    external_id: str = Field(
        ..., description="Platform-specific ID (e.g., TikTok video_id)"
    )
    url: str = Field(..., description="Public content URL")
    job_id: Optional[str] = Field(
        None, description="External service job ID for tracking"
    )

    # Author reference
    author_id: Optional[str] = Field(
        None, description="Reference to authors._id (MongoDB ObjectId)"
    )
    author_external_id: Optional[str] = Field(
        None, description="Platform-specific author ID"
    )
    author_username: Optional[str] = Field(None, description="Author username/handle")
    author_display_name: Optional[str] = Field(None, description="Author display name")

    # Content metadata
    title: Optional[str] = Field(
        None, description="Title (YouTube); null for other platforms"
    )
    description: Optional[str] = Field(
        None, description="Normalized caption/description"
    )
    duration_seconds: Optional[int] = Field(
        None, description="Duration in seconds; null if not applicable"
    )
    sound_name: Optional[str] = Field(None, description="Sound/music name (TikTok)")
    category: Optional[str] = Field(
        None, description="Optional category classification"
    )
    tags: List[str] = Field(
        default_factory=list, description="Normalized hashtags/tags"
    )

    # Media information
    media_type: Optional[MediaType] = Field(
        None, description="Media type: VIDEO, IMAGE, AUDIO, POST"
    )
    media_path: Optional[str] = Field(None, description="Storage path (S3/MinIO/local)")
    media_downloaded_at: Optional[datetime] = Field(
        None, description="Media download timestamp"
    )
    video_download_url: Optional[str] = Field(
        None, description="Ephemeral download URL for the raw video file", exclude=True
    )
    audio_url: Optional[str] = Field(
        None, description="Ephemeral download URL for the audio track", exclude=True
    )

    # Engagement metrics (dynamic - change frequently)
    view_count: Optional[int] = Field(None, description="Total views")
    like_count: Optional[int] = Field(None, description="Total likes")
    comment_count: Optional[int] = Field(None, description="Total comments")
    share_count: Optional[int] = Field(None, description="Total shares")
    save_count: Optional[int] = Field(
        None, description="Total saves (TikTok); null for other platforms"
    )

    # Timestamps
    published_at: Optional[datetime] = Field(
        None, description="Public publish timestamp"
    )
    crawled_at: Optional[datetime] = Field(
        None, description="Most recent crawl/refresh timestamp"
    )
    created_at: Optional[datetime] = Field(None, description="First insert into system")
    updated_at: Optional[datetime] = Field(None, description="Last update timestamp")

    # Search metadata
    keyword: Optional[str] = Field(None, description="Search keyword (if from search)")

    # Platform-specific data
    extra_json: Optional[dict] = Field(
        default_factory=dict, description="Platform-specific fields as JSON"
    )

    # Speech-to-Text
    transcription: Optional[str] = Field(
        None, description="Speech-to-text transcription"
    )
    transcription_status: Optional[str] = Field(
        None, description="STT status: SUCCESS, ERROR, TIMEOUT, PENDING"
    )
    transcription_error: Optional[str] = Field(
        None, description="STT error message if failed"
    )

    @staticmethod
    def get_static_fields() -> set:
        """
        Static fields - never change after creation
        These are immutable identifiers and metadata
        """
        return {"source", "external_id", "url", "keyword", "job_id", "created_at"}

    @staticmethod
    def get_dynamic_fields() -> set:
        """
        Dynamic fields - updated on every re-crawl

        These include:
        - Engagement metrics (views, likes, etc.) - change frequently
        - Content metadata (description, tags) - user can edit
        - Author info - user can rename
        - Media download info - can be downloaded later
        """
        return {
            # Author info
            "author_id",
            "author_external_id",
            "author_username",
            "author_display_name",
            # Content metadata
            "title",
            "description",
            "duration_seconds",
            "sound_name",
            "category",
            "tags",
            # Media
            "media_type",
            "media_path",
            "media_downloaded_at",
            # Metrics
            "view_count",
            "like_count",
            "comment_count",
            "share_count",
            "save_count",
            # Timestamps
            "published_at",
            "crawled_at",
            "updated_at",
            # Extra
            "extra_json",
            # Speech-to-Text
            "transcription",
            "transcription_status",
            "transcription_error",
        }

    def has_media_downloaded(self) -> bool:
        """Check if media has been downloaded"""
        return self.media_path is not None and self.media_type is not None

    def is_from_tiktok(self) -> bool:
        """Check if content is from TikTok"""
        return self.source == SourcePlatform.TIKTOK

    def is_from_youtube(self) -> bool:
        """Check if content is from YouTube"""
        return self.source == SourcePlatform.YOUTUBE

    def mark_media_downloaded(self, file_path: str, media_type: MediaType) -> None:
        """Mark media as downloaded with storage path and type"""
        self.media_path = file_path
        self.media_type = media_type
        self.media_downloaded_at = datetime.now()

    class Config:
        """Pydantic configuration"""

        populate_by_name = True
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "source": "TIKTOK",
                "external_id": "7552532436060523784",
                "url": "https://www.tiktok.com/@user/video/7552532436060523784",
                "job_id": "job-uuid-123",
                "author_external_id": "user123",
                "author_username": "username123",
                "author_display_name": "Cool Creator",
                "title": None,
                "description": "Amazing video content #fyp",
                "duration_seconds": 30,
                "sound_name": "Original Sound",
                "category": None,
                "tags": ["#fyp", "#viral"],
                "media_type": "VIDEO",
                "media_path": "/storage/7552532436060523784.mp4",
                "media_downloaded_at": "2025-11-10T12:00:00",
                "view_count": 125000,
                "like_count": 3210,
                "comment_count": 270,
                "share_count": 150,
                "save_count": 89,
                "published_at": "2025-11-08T10:00:00",
                "crawled_at": "2025-11-10T10:00:00",
                "created_at": "2025-11-10T10:00:00",
                "updated_at": "2025-11-10T10:00:00",
                "keyword": "gaming highlights",
                "extra_json": {},
            }
        }
