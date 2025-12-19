"""
Metrics Value Object - Domain Layer
Immutable value object representing engagement metrics
"""
from pydantic import BaseModel, Field
from typing import Optional


class Metrics(BaseModel):
    """
    Metrics value object

    Represents engagement metrics for TikTok content (videos, comments, etc.).
    This is a value object - immutable and defined by its values, not identity.

    Following Clean Architecture and DDD principles:
    - Immutable (use copy with updates instead of mutation)
    - No identity (two Metrics with same values are equal)
    - Self-validating (Pydantic validation)
    """

    view_count: int = Field(0, ge=0, description="View count (videos only)")
    like_count: int = Field(0, ge=0, description="Like count")
    comment_count: int = Field(0, ge=0, description="Comment count (videos only)")
    share_count: int = Field(0, ge=0, description="Share count (videos only)")
    save_count: int = Field(0, ge=0, description="Save/collect count (videos only)")
    reply_count: int = Field(0, ge=0, description="Reply count (comments only)")

    def total_engagement(self) -> int:
        """
        Calculate total engagement across all metrics

        Returns:
            Sum of all engagement metrics
        """
        return (
            self.view_count +
            self.like_count +
            self.comment_count +
            self.share_count +
            self.save_count +
            self.reply_count
        )

    def engagement_rate(self) -> float:
        """
        Calculate engagement rate: (likes + comments + shares) / views

        Returns:
            Engagement rate as a decimal (0.0 to 1.0+)
            Returns 0.0 if no views
        """
        if self.view_count == 0:
            return 0.0

        engagement = self.like_count + self.comment_count + self.share_count
        return engagement / self.view_count

    def like_rate(self) -> float:
        """
        Calculate like rate: likes / views

        Returns:
            Like rate as a decimal (0.0 to 1.0)
            Returns 0.0 if no views
        """
        if self.view_count == 0:
            return 0.0

        return self.like_count / self.view_count

    def comment_rate(self) -> float:
        """
        Calculate comment rate: comments / views

        Returns:
            Comment rate as a decimal
            Returns 0.0 if no views
        """
        if self.view_count == 0:
            return 0.0

        return self.comment_count / self.view_count

    def share_rate(self) -> float:
        """
        Calculate share rate: shares / views

        Returns:
            Share rate as a decimal
            Returns 0.0 if no views
        """
        if self.view_count == 0:
            return 0.0

        return self.share_count / self.view_count

    def is_viral(
        self,
        min_views: int = 100000,
        min_engagement_rate: float = 0.05
    ) -> bool:
        """
        Determine if content is viral based on thresholds

        Args:
            min_views: Minimum view count to be considered viral (default: 100k)
            min_engagement_rate: Minimum engagement rate (default: 5%)

        Returns:
            True if content meets viral criteria
        """
        return (
            self.view_count >= min_views and
            self.engagement_rate() >= min_engagement_rate
        )

    def popularity_score(self) -> float:
        """
        Calculate popularity score using weighted formula

        Formula:
            score = (views * 0.1) + (likes * 1.0) + (comments * 2.0) +
                    (shares * 3.0) + (saves * 2.5)

        Weights reflect importance:
        - Shares (3.0) - highest value, indicates viral spread
        - Saves (2.5) - high value, indicates quality content
        - Comments (2.0) - strong engagement
        - Likes (1.0) - basic engagement
        - Views (0.1) - base metric

        Returns:
            Popularity score as a float
        """
        return (
            (self.view_count * 0.1) +
            (self.like_count * 1.0) +
            (self.comment_count * 2.0) +
            (self.share_count * 3.0) +
            (self.save_count * 2.5) +
            (self.reply_count * 1.5)  # For comments
        )

    @classmethod
    def from_video(
        cls,
        view_count: int = 0,
        like_count: int = 0,
        comment_count: int = 0,
        share_count: int = 0,
        save_count: int = 0
    ) -> "Metrics":
        """
        Create Metrics value object from video metrics

        Args:
            view_count: Video view count
            like_count: Video like count
            comment_count: Video comment count
            share_count: Video share count
            save_count: Video save count

        Returns:
            Metrics value object
        """
        return cls(
            view_count=view_count,
            like_count=like_count,
            comment_count=comment_count,
            share_count=share_count,
            save_count=save_count,
            reply_count=0
        )

    @classmethod
    def from_comment(
        cls,
        like_count: int = 0,
        reply_count: int = 0
    ) -> "Metrics":
        """
        Create Metrics value object from comment metrics

        Args:
            like_count: Comment like count
            reply_count: Comment reply count

        Returns:
            Metrics value object
        """
        return cls(
            view_count=0,
            like_count=like_count,
            comment_count=0,
            share_count=0,
            save_count=0,
            reply_count=reply_count
        )

    class Config:
        """Pydantic configuration"""
        frozen = True  # Make immutable
        json_schema_extra = {
            "example": {
                "view_count": 125000,
                "like_count": 3210,
                "comment_count": 270,
                "share_count": 150,
                "save_count": 89,
                "reply_count": 0
            }
        }
