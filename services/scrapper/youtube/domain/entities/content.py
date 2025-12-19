"""
Content Entity - Domain Layer
Business entity representing multi-platform content (video, post, etc.)
Adapted from TikTok with YouTube-specific fields (title, category)
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
    YouTube-specific: includes title and category fields
    """

    # Core identifiers
    source: SourcePlatform = Field(..., description="Source platform (TIKTOK, YOUTUBE, FACEBOOK)")
    external_id: str = Field(..., description="Platform-specific ID (e.g., YouTube video_id)")
    url: str = Field(..., description="Public content URL")
    job_id: Optional[str] = Field(None, description="External service job ID for tracking")

    # Author reference
    author_id: Optional[str] = Field(None, description="Reference to authors._id (MongoDB ObjectId)")
    author_external_id: Optional[str] = Field(None, description="Platform-specific author ID (channel_id)")
    author_username: Optional[str] = Field(None, description="Author username/handle (custom_url)")
    author_display_name: Optional[str] = Field(None, description="Author display name (channel_title)")

    # Content metadata
    title: Optional[str] = Field(None, description="Title (YouTube, Facebook); null for TikTok")
    description: Optional[str] = Field(None, description="Normalized caption/description")
    duration_seconds: Optional[int] = Field(None, description="Duration in seconds; null if not applicable")
    sound_name: Optional[str] = Field(None, description="Sound/music name (TikTok); null for YouTube")
    category: Optional[str] = Field(None, description="Category (YouTube category system)")
    tags: List[str] = Field(default_factory=list, description="Normalized hashtags/tags")

    # Media information
    media_type: Optional[MediaType] = Field(None, description="Media type: VIDEO, IMAGE, AUDIO, POST")
    media_path: Optional[str] = Field(None, description="Storage path (S3/MinIO/local)")
    media_downloaded_at: Optional[datetime] = Field(None, description="Media download timestamp")
    video_download_url: Optional[str] = Field(
        None,
        description="Ephemeral download URL for the raw video file",
        exclude=True
    )
    audio_url: Optional[str] = Field(
        None,
        description="Ephemeral download URL for the audio track",
        exclude=True
    )

    # Engagement metrics (dynamic - change frequently)
    view_count: Optional[int] = Field(None, description="Total views")
    like_count: Optional[int] = Field(None, description="Total likes")
    comment_count: Optional[int] = Field(None, description="Total comments")
    share_count: Optional[int] = Field(None, description="Total shares (TikTok); null for YouTube")
    save_count: Optional[int] = Field(None, description="Total saves (TikTok); null for YouTube")

    # Timestamps
    published_at: Optional[datetime] = Field(None, description="Public publish timestamp")
    crawled_at: Optional[datetime] = Field(None, description="Most recent crawl/refresh timestamp")
    created_at: Optional[datetime] = Field(None, description="First insert into system")
    updated_at: Optional[datetime] = Field(None, description="Last update timestamp")

    # Search metadata
    keyword: Optional[str] = Field(None, description="Search keyword (if from search)")

    # Platform-specific data
    extra_json: Optional[dict] = Field(default_factory=dict, description="Platform-specific fields as JSON")

    # AI-generated summary
    content_detail: Optional[str] = Field(None, description="AI-generated content summary (overview text)")
    
    # Speech-to-Text transcription
    transcription: Optional[str] = Field(None, description="Audio transcription from STT service")
    transcription_status: Optional[str] = Field(None, description="STT job status (PROCESSING, COMPLETED, FAILED, NOT_FOUND, TIMEOUT, etc.)")

    @staticmethod
    def get_static_fields() -> set:
        """
        Static fields - never change after creation
        These are immutable identifiers and metadata
        """
        return {
            "source",
            "external_id",
            "url",
            "keyword",
            "job_id",
            "created_at"
        }

    @staticmethod
    def get_dynamic_fields() -> set:
        """
        Dynamic fields - updated on every re-crawl

        These include:
        - Engagement metrics (views, likes, etc.) - change frequently
        - Content metadata (description, tags, title) - user can edit
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

            # AI Summary
            "content_detail",
            
            # Speech-to-Text
            "transcription",
            "transcription_status"
        }

    def has_media_downloaded(self) -> bool:
        """Check if media has been downloaded"""
        return self.media_path is not None and self.media_type is not None

    def is_from_youtube(self) -> bool:
        """Check if content is from YouTube"""
        return self.source == SourcePlatform.YOUTUBE

    def is_from_tiktok(self) -> bool:
        """Check if content is from TikTok"""
        return self.source == SourcePlatform.TIKTOK

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
                "source": "YOUTUBE",
                "external_id": "dQw4w9WgXcQ",
                "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                "job_id": "job-uuid-123",
                "author_external_id": "UCuAXFkgsw1L7xaCfnd5JJOw",
                "author_username": "@RickAstleyOfficial",
                "author_display_name": "Rick Astley",
                "title": "Rick Astley - Never Gonna Give You Up (Official Music Video)",
                "description": "The official video for \"Never Gonna Give You Up\"...",
                "duration_seconds": 213,
                "sound_name": None,
                "category": "Music",
                "tags": ["rick", "astley", "music"],
                "media_type": "VIDEO",
                "media_path": "/storage/dQw4w9WgXcQ.mp4",
                "media_downloaded_at": "2025-11-10T12:00:00",
                "view_count": 1400000000,
                "like_count": 15000000,
                "comment_count": 3200000,
                "share_count": None,
                "save_count": None,
                "published_at": "2009-10-25T06:57:33",
                "crawled_at": "2025-11-10T10:00:00",
                "created_at": "2025-11-10T10:00:00",
                "updated_at": "2025-11-10T10:00:00",
                "keyword": "rick astley",
                "extra_json": {}
            }
        }
