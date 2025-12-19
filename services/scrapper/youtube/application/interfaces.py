"""
Application Interfaces (Ports) - YouTube
Defines abstract interfaces for repositories, scrapers, media downloaders, storage,
and infrastructure concerns. Mirrors the TikTok refactor so both platforms share
the same domain contracts while allowing YouTube-specific implementations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any, Literal
from datetime import datetime
from dataclasses import dataclass

from domain import Content, Author, Comment, SearchSession


# ==================== Repository Interfaces ====================

class IContentRepository(ABC):
    """Interface for content data persistence (replaces IVideoRepository)."""

    @abstractmethod
    async def upsert_content(self, content: Content) -> bool:
        """Insert or update content."""
        pass

    @abstractmethod
    async def get_content(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get content by source and external_id."""
        pass

    @abstractmethod
    async def get_content_by_keyword(self, keyword: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get content documents matching a search keyword."""
        pass


class IAuthorRepository(ABC):
    """Interface for author (channel) data persistence."""

    @abstractmethod
    async def upsert_author(self, author: Author) -> bool:
        """Insert or update an author."""
        pass

    @abstractmethod
    async def get_author(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get author by source and external_id."""
        pass


class ICommentRepository(ABC):
    """Interface for comment data persistence."""

    @abstractmethod
    async def upsert_comments(self, comments: List[Comment]) -> bool:
        """Insert or update multiple comments."""
        pass

    @abstractmethod
    async def get_comments_by_parent(self, parent_id: str, limit: int = 1000) -> List[Dict[str, Any]]:
        """Get comments for a parent content/comment document."""
        pass


class ISearchSessionRepository(ABC):
    """Interface for search session persistence (replaces ISearchResultRepository)."""

    @abstractmethod
    async def save_search_session(self, session: SearchSession) -> bool:
        """Insert or update a search session entry."""
        pass

    @abstractmethod
    async def get_search_sessions_by_keyword(self, keyword: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Retrieve search sessions for a keyword."""
        pass


# ==================== Scraper Interfaces ====================

class IVideoScraper(ABC):
    """Interface for video scraping."""

    @abstractmethod
    async def scrape(self, video_url: str) -> Optional[Dict[str, Any]]:
        """Scrape video metadata from YouTube."""
        pass


class IAuthorScraper(ABC):
    """Interface for author (channel) scraping."""

    @abstractmethod
    async def scrape(self, channel_identifier: str) -> Optional[Dict[str, Any]]:
        """Scrape channel information from YouTube."""
        pass


class ICommentScraper(ABC):
    """Interface for comment scraping."""

    @abstractmethod
    async def scrape(
        self,
        video_id: str,
        max_comments: int = 0
    ) -> List[Dict[str, Any]]:
        """Scrape comments from a YouTube video."""
        pass


class ISearchScraper(ABC):
    """Interface for search functionality."""

    @abstractmethod
    async def search_videos(
        self,
        keyword: str,
        limit: int = 50,
        sort_by: str = 'relevance'
    ) -> List[str]:
        """Search for videos by keyword."""
        pass


class IChannelScraper(ABC):
    """Interface for channel video listing."""

    @abstractmethod
    async def get_channel_video_urls(
        self,
        channel_url: str,
        limit: int = 0
    ) -> List[str]:
        """
        Fetch all video URLs from a channel (standard videos only).
        
        Args:
            channel_url: YouTube channel URL (e.g., https://www.youtube.com/@username)
            limit: Maximum number of videos to fetch (0 = all)
            
        Returns:
            List of video URLs
        """
        pass


# ==================== Media Download Interface ====================

class IMediaDownloader(ABC):
    """Interface for media download functionality."""

    @abstractmethod
    async def download_media(
        self,
        content: Content,
        media_type: Literal["video", "audio"],
        save_dir: str
    ) -> Optional[str]:
        """
        Download media from YouTube and return storage URI/local path.
        """
        pass


# ==================== Storage Interface ====================

class IStorageService(ABC):
    """Interface for object storage (MinIO)."""

    @abstractmethod
    async def upload_file(
        self,
        file_path: str,
        object_name: str,
        bucket_name: Optional[str] = None
    ) -> Optional[str]:
        """Upload a file to object storage."""
        pass

    @abstractmethod
    async def download_file(
        self,
        object_name: str,
        file_path: str,
        bucket_name: Optional[str] = None
    ) -> bool:
        """Download a file from object storage."""
        pass

    @abstractmethod
    async def file_exists(
        self,
        object_name: str,
        bucket_name: Optional[str] = None
    ) -> bool:
        """Check if a file exists in object storage."""
        pass

    @abstractmethod
    async def upload_bytes(
        self,
        data: bytes,
        object_name: str,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        """Upload bytes to object storage."""
        pass


# ==================== Task Queue Interface ====================

class ITaskQueue(ABC):
    """Interface for message queue functionality."""

    @abstractmethod
    async def connect(self) -> None:
        pass

    @abstractmethod
    async def close(self) -> None:
        pass

    @abstractmethod
    async def publish_task(
        self,
        task_type: str,
        payload: Dict[str, Any],
        job_id: Optional[str] = None
    ) -> str:
        """Publish a task to the queue."""
        pass

    @abstractmethod
    async def start_consuming(self) -> None:
        pass

    @abstractmethod
    async def stop_consuming(self) -> None:
        pass


# ==================== Job Tracking Interface ====================

class IJobRepository(ABC):
    """Interface for job tracking."""

    @abstractmethod
    async def create_job(
        self,
        job_id: str,
        task_type: str,
        payload: Dict[str, Any],
        time_range: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None
    ) -> bool:
        pass

    @abstractmethod
    async def update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> bool:
        pass

    @abstractmethod
    async def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job by ID."""
        pass


# ==================== Speech-to-Text Interface ====================

@dataclass
class STTResult:
    """
    Result of a Speech-to-Text transcription request.
    
    This dataclass encapsulates all information about a transcription job,
    including success status, transcription text, error details, and metadata.
    
    Attributes:
        success: Whether the transcription completed successfully
        transcription: The transcribed text (None if failed)
        error_message: Error description if transcription failed (None if successful)
        status: Current job status (PROCESSING, COMPLETED, FAILED, NOT_FOUND, TIMEOUT, UNAUTHORIZED, EXCEPTION)
        error_code: HTTP error code or custom error code (None if successful)
        duration: Duration of the audio file in seconds (None if not available)
        confidence: Transcription confidence score 0-1 (None if not available)
        processing_time: Time taken to process the transcription in seconds (None if not available)
    """
    success: bool
    transcription: Optional[str] = None
    error_message: Optional[str] = None
    status: Optional[str] = None
    error_code: Optional[int] = None
    duration: Optional[float] = None
    confidence: Optional[float] = None
    processing_time: Optional[float] = None


class ISpeech2TextClient(ABC):
    """Interface for Speech-to-Text service"""

    @abstractmethod
    async def transcribe(
        self, 
        audio_url: str, 
        language: str = "vi",
        request_id: Optional[str] = None
    ) -> STTResult:
        """
        Transcribe audio from URL to text using async polling pattern
        
        Args:
            audio_url: Presigned URL of the audio file
            language: Language code (default: "vi")
            request_id: Optional unique identifier for idempotent submission
            
        Returns:
            STTResult with transcription and status info
        """
        pass
