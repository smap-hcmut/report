from pydantic import BaseModel
from typing import List, Optional


class ProfileScrapeRequest(BaseModel):
    url: str
    limit: Optional[int] = None


class ProfileScrapeResponse(BaseModel):
    videos: List[str]
