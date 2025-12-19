"""
Comment Entity - Domain Layer
Business entity representing comments on content or other comments
Updated to match refactor_modelDB.md schema for multi-platform support
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from ..enums import SourcePlatform, ParentType


class Comment(BaseModel):
    """
    Comment domain entity

    Represents comments on content or other comments across multiple platforms.
    Exact schema from refactor_modelDB.md.
    YouTube-specific: Maps author_name→commenter_name, stores author_channel_id, is_favorited, parent_comment_id in extra_json
    """

    # Core identifiers
    source: SourcePlatform = Field(..., description="Source platform (TIKTOK, YOUTUBE, FACEBOOK)")
    external_id: str = Field(..., description="Platform-specific comment ID (YouTube comment_id)")
    parent_type: ParentType = Field(..., description="Parent type: CONTENT or COMMENT")
    parent_id: str = Field(..., description="Reference to parent (content._id or comments._id)")
    job_id: Optional[str] = Field(None, description="External service job ID for tracking")

    # Content
    comment_text: Optional[str] = Field(None, description="Comment text content")
    commenter_name: Optional[str] = Field(None, description="Commenter username (YouTube author_name)")

    # Engagement metrics (dynamic - change over time)
    like_count: Optional[int] = Field(None, description="Comment like count")
    reply_count: Optional[int] = Field(None, description="Reply count")

    # Timestamps
    published_at: Optional[datetime] = Field(None, description="When comment was posted")
    crawled_at: Optional[datetime] = Field(None, description="Crawl timestamp")
    created_at: Optional[datetime] = Field(None, description="First crawl timestamp (DB)")
    updated_at: Optional[datetime] = Field(None, description="Last update timestamp (DB)")

    # Platform-specific data (YouTube: author_channel_id, is_favorited, parent_comment_id)
    extra_json: Optional[dict] = Field(default_factory=dict, description="Platform-specific fields as JSON")

    @staticmethod
    def get_static_fields() -> set:
        """
        Static fields - never change after creation
        These are immutable identifiers and original content
        """
        return {
            "source",
            "external_id",
            "parent_type",
            "parent_id",
            "published_at",  # When comment was posted (immutable)
            "job_id",
            "created_at"
        }

    @staticmethod
    def get_dynamic_fields() -> set:
        """
        Dynamic fields - updated on every re-crawl

        These include:
        - Engagement metrics (like_count, reply_count) - change frequently
        - Comment text - user can edit or delete comment
        - Commenter name - user can rename account
        """
        return {
            # Content
            "comment_text",
            "commenter_name",

            # Metrics
            "like_count",
            "reply_count",

            # Timestamps
            "crawled_at",
            "updated_at",

            # Extra
            "extra_json"
        }

    def has_replies(self) -> bool:
        """Check if comment has replies"""
        return self.reply_count is not None and self.reply_count > 0

    def is_reply_to_content(self) -> bool:
        """Check if this is a direct reply to content (not a reply to another comment)"""
        return self.parent_type == ParentType.CONTENT

    def is_reply_to_comment(self) -> bool:
        """Check if this is a reply to another comment"""
        return self.parent_type == ParentType.COMMENT

    def is_popular(self, threshold: int = 100) -> bool:
        """
        Check if comment is popular based on like count

        Args:
            threshold: Minimum likes to be considered popular (default: 100)

        Returns:
            True if like_count >= threshold
        """
        return self.like_count is not None and self.like_count >= threshold

    def get_engagement_score(self) -> int:
        """
        Calculate engagement score: likes + (replies * 2)
        Replies weighted higher as they indicate more engagement
        """
        likes = self.like_count or 0
        replies = self.reply_count or 0
        return likes + (replies * 2)

    def is_from_youtube(self) -> bool:
        """Check if comment is from YouTube"""
        return self.source == SourcePlatform.YOUTUBE

    def is_from_tiktok(self) -> bool:
        """Check if comment is from TikTok"""
        return self.source == SourcePlatform.TIKTOK

    class Config:
        """Pydantic configuration"""
        populate_by_name = True
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "source": "YOUTUBE",
                "external_id": "UgwL9QH5T_kZvP0coAEC",
                "parent_type": "CONTENT",
                "parent_id": "507f1f77bcf86cd799439011",
                "job_id": "job-uuid-123",
                "comment_text": "Never gonna give you up!",
                "commenter_name": "John Doe",
                "like_count": 1250,
                "reply_count": 45,
                "published_at": "2023-09-17T11:49:54",
                "crawled_at": "2025-11-10T10:00:00",
                "created_at": "2025-11-10T10:00:00",
                "updated_at": "2025-11-10T10:00:00",
                "extra_json": {
                    "author_channel_id": "UC_x5XG1OV2P6uZZ5FSM9Ttw",
                    "is_favorited": False,
                    "parent_comment_id": None
                }
            }
        }
