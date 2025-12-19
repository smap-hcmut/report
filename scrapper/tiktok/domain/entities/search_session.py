"""
Search Session Entity - Domain Layer
Represents metadata from a keyword search session
Replaces the old SearchResult entity with exact schema from refactor_modelDB.md
"""
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field
from ..enums import SourcePlatform, SearchSortBy


class SearchSession(BaseModel):
    """
    Search session entity

    Represents a search session with metadata about the keyword search
    performed on a platform. Exact schema from refactor_modelDB.md.
    """

    # Core identifiers
    search_id: str = Field(..., description="Unique search session ID")
    source: SourcePlatform = Field(..., description="Source platform (TIKTOK, YOUTUBE, FACEBOOK)")
    keyword: str = Field(..., description="Search keyword used")
    sort_by: Optional[SearchSortBy] = Field(None, description="Sort method: RELEVANCE, LIKE, VIEW, DATE")

    # Search results
    searched_at: datetime = Field(..., description="Search timestamp")
    total_found: Optional[int] = Field(None, description="Total number of results found")
    urls: List[str] = Field(default_factory=list, description="List of content URLs discovered")

    # Job tracking
    job_id: Optional[str] = Field(None, description="External service job ID for tracking")

    # Raw search parameters
    params_raw: Optional[str] = Field(None, description="JSON string of original search parameters")

    def is_from_tiktok(self) -> bool:
        """Check if search was performed on TikTok"""
        return self.source == SourcePlatform.TIKTOK

    def is_from_youtube(self) -> bool:
        """Check if search was performed on YouTube"""
        return self.source == SourcePlatform.YOUTUBE

    def has_results(self) -> bool:
        """Check if search found any results"""
        return len(self.urls) > 0

    def get_result_count(self) -> int:
        """Get the actual number of URLs returned"""
        return len(self.urls)

    class Config:
        """Pydantic configuration"""
        populate_by_name = True
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "search_id": "search-uuid-123",
                "source": "TIKTOK",
                "keyword": "gaming highlights",
                "sort_by": "LIKE",
                "searched_at": "2025-11-10T10:00:00",
                "total_found": 50,
                "urls": [
                    "https://www.tiktok.com/@user1/video/123",
                    "https://www.tiktok.com/@user2/video/456"
                ],
                "job_id": "job-uuid-123",
                "params_raw": "{\"count\": 50, \"offset\": 0}"
            }
        }
