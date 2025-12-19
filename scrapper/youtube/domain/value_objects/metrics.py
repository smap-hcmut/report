"""
Metrics Value Object - Domain Layer
Immutable value object representing engagement metrics
"""
from pydantic import BaseModel, Field


class Metrics(BaseModel):
    """
    Metrics value object

    Represents engagement metrics for YouTube content (videos, comments, etc.).
    This is a value object - immutable and defined by its values, not identity.

    Following Clean Architecture and DDD principles:
    - Immutable (use copy with updates instead of mutation)
    - No identity (two Metrics with same values are equal)
    - Self-validating (Pydantic validation)
    """

    view_count: int = Field(0, ge=0, description="View count (videos only)")
    like_count: int = Field(0, ge=0, description="Like count")
    comment_count: int = Field(0, ge=0, description="Comment count (videos only)")
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
            self.reply_count
        )

    def engagement_rate(self) -> float:
        """
        Calculate engagement rate: (likes + comments) / views

        Returns:
            Engagement rate as a decimal (0.0 to 1.0+)
            Returns 0.0 if no views
        """
        if self.view_count == 0:
            return 0.0

        engagement = self.like_count + self.comment_count
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

    def is_viral(
        self,
        min_views: int = 1000000,
        min_engagement_rate: float = 0.02
    ) -> bool:
        """
        Determine if content is viral based on thresholds

        Args:
            min_views: Minimum view count to be considered viral (default: 1M)
            min_engagement_rate: Minimum engagement rate (default: 2%)

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
            score = (views * 0.1) + (likes * 1.0) + (comments * 2.0)

        Weights reflect importance:
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
            (self.reply_count * 1.5)  # For comments
        )

    @classmethod
    def from_video(
        cls,
        view_count: int = 0,
        like_count: int = 0,
        comment_count: int = 0
    ) -> "Metrics":
        """
        Create Metrics value object from video metrics

        Args:
            view_count: Video view count
            like_count: Video like count
            comment_count: Video comment count

        Returns:
            Metrics value object
        """
        return cls(
            view_count=view_count,
            like_count=like_count,
            comment_count=comment_count,
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
            reply_count=reply_count
        )

    class Config:
        """Pydantic configuration"""
        frozen = True  # Make immutable
        json_schema_extra = {
            "example": {
                "view_count": 1500000,
                "like_count": 45000,
                "comment_count": 3200,
                "reply_count": 0
            }
        }
