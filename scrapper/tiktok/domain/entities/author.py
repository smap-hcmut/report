"""
Author Entity - Domain Layer
Business entity representing multi-platform authors/creators
Replaces the old Creator entity with exact schema from refactor_modelDB.md
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from ..enums import SourcePlatform


class Author(BaseModel):
    """
    Author domain entity

    Represents content creators from multiple platforms (TikTok, YouTube, Facebook)
    with normalized profile information. Exact schema from refactor_modelDB.md.

    Note: NO job_id field as per schema specification.
    """

    # Core identifiers
    source: SourcePlatform = Field(..., description="Source platform (TIKTOK, YOUTUBE, FACEBOOK)")
    external_id: str = Field(..., description="Platform-specific author ID")
    profile_url: Optional[str] = Field(None, description="Author profile/channel URL")
    username: Optional[str] = Field(None, description="Unique handle/username")
    display_name: Optional[str] = Field(None, description="Display name")
    verified: Optional[bool] = Field(None, description="Verification badge status")

    # Statistics (dynamic - change frequently)
    follower_count: Optional[int] = Field(None, description="Follower/subscriber count")
    following_count: Optional[int] = Field(None, description="Following count")
    like_count: Optional[int] = Field(None, description="Total likes across all content (TikTok) or equivalent")
    video_count: Optional[int] = Field(None, description="Total videos/posts published")

    # Timestamps
    crawled_at: Optional[datetime] = Field(None, description="Most recent crawl timestamp")
    created_at: Optional[datetime] = Field(None, description="First insert into system")
    updated_at: Optional[datetime] = Field(None, description="Last update timestamp")

    # Platform-specific data
    extra_json: Optional[dict] = Field(default_factory=dict, description="Platform-specific fields as JSON (bio, partial_data, etc.)")

    @staticmethod
    def get_static_fields() -> set:
        """
        Static fields - never change after creation
        These are immutable identifiers
        """
        return {
            "source",
            "external_id",
            "profile_url",
            "created_at"
        }

    @staticmethod
    def get_dynamic_fields() -> set:
        """
        Dynamic fields - updated on every re-crawl

        These include:
        - Statistics (followers, likes, etc.) - change frequently
        - Profile info (username, display_name) - user can edit
        - Verified status - can change
        """
        return {
            # Profile info
            "username",
            "display_name",
            "verified",

            # Statistics
            "follower_count",
            "following_count",
            "like_count",
            "video_count",

            # Timestamps
            "crawled_at",
            "updated_at",

            # Extra
            "extra_json"
        }

    def is_verified(self) -> bool:
        """Check if author is verified"""
        return self.verified is True

    def is_from_tiktok(self) -> bool:
        """Check if author is from TikTok"""
        return self.source == SourcePlatform.TIKTOK

    def is_from_youtube(self) -> bool:
        """Check if author is from YouTube"""
        return self.source == SourcePlatform.YOUTUBE

    def has_complete_data(self) -> bool:
        """Check if all data was successfully crawled (check partial_data in extra_json)"""
        return not self.extra_json.get("partial_data", False)

    def get_follower_engagement_rate(self) -> float:
        """
        Calculate engagement rate: like_count / follower_count
        Returns 0.0 if no followers or no like data
        """
        if not self.follower_count or not self.like_count or self.follower_count == 0:
            return 0.0
        return self.like_count / self.follower_count

    def get_average_likes_per_video(self) -> float:
        """
        Calculate average likes per video
        Returns 0.0 if no videos or no like data
        """
        if not self.video_count or not self.like_count or self.video_count == 0:
            return 0.0
        return self.like_count / self.video_count

    class Config:
        """Pydantic configuration"""
        populate_by_name = True
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "source": "TIKTOK",
                "external_id": "user123",
                "profile_url": "https://www.tiktok.com/@username123",
                "username": "username123",
                "display_name": "Cool Creator",
                "verified": False,
                "follower_count": 24200,
                "following_count": 350,
                "like_count": 341500,
                "video_count": 189,
                "crawled_at": "2025-11-10T10:00:00",
                "created_at": "2025-11-10T10:00:00",
                "updated_at": "2025-11-10T10:00:00",
                "extra_json": {
                    "bio": "Content creator | Gaming enthusiast",
                    "partial_data": False
                }
            }
        }
