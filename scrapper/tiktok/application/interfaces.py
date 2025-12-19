"""
Application Interfaces (Ports)
Abstract interfaces defining contracts for external dependencies

Following the Dependency Inversion Principle and Hexagonal Architecture,
these interfaces define what the application needs without specifying how
it's implemented. Implementations live in the internal/adapters layer.

Updated to match refactor_modelDB.md schema
"""

from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any, Literal
from pathlib import Path
from datetime import datetime

from domain import Content, Author, Comment, SearchSession


# ==================== Repository Interfaces ====================


class IContentRepository(ABC):
    """Interface for content data persistence (replaces IVideoRepository)"""

    @abstractmethod
    async def upsert_content(self, content: Content) -> bool:
        """
        Insert or update content

        Args:
            content: Content entity to persist

        Returns:
            True if successful, False otherwise
        """
        pass

    @abstractmethod
    async def get_content(
        self, source: str, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get content by source and external_id

        Args:
            source: Source platform (e.g., "TIKTOK")
            external_id: Platform-specific content ID

        Returns:
            Content data dict or None if not found
        """
        pass

    @abstractmethod
    async def get_content_by_keyword(
        self, keyword: str, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Get content by search keyword

        Args:
            keyword: Search keyword
            limit: Maximum number of content items to return

        Returns:
            List of content data dicts
        """
        pass


class IAuthorRepository(ABC):
    """Interface for author data persistence (replaces ICreatorRepository)"""

    @abstractmethod
    async def upsert_author(self, author: Author) -> bool:
        """
        Insert or update an author

        Args:
            author: Author entity to persist

        Returns:
            True if successful, False otherwise
        """
        pass

    @abstractmethod
    async def get_author(
        self, source: str, external_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get author by source and external_id

        Args:
            source: Source platform (e.g., "TIKTOK")
            external_id: Platform-specific author ID

        Returns:
            Author data dict or None if not found
        """
        pass


class ICommentRepository(ABC):
    """Interface for comment data persistence"""

    @abstractmethod
    async def upsert_comments(self, comments: List[Comment]) -> bool:
        """
        Insert or update multiple comments

        Args:
            comments: List of Comment entities

        Returns:
            True if successful, False otherwise
        """
        pass

    @abstractmethod
    async def get_comments_by_parent(
        self, parent_id: str, limit: int = 1000
    ) -> List[Dict[str, Any]]:
        """
        Get comments for a parent (content or comment)

        Args:
            parent_id: Parent ID (content._id or comments._id)
            limit: Maximum number of comments

        Returns:
            List of comment data dicts
        """
        pass


class ISearchSessionRepository(ABC):
    """Interface for search session persistence (replaces ISearchResultRepository)"""

    @abstractmethod
    async def save_search_session(self, session: SearchSession) -> bool:
        """
        Insert or update a search session entry

        Args:
            session: SearchSession entity to persist

        Returns:
            True if successful, False otherwise
        """
        pass

    @abstractmethod
    async def get_search_sessions_by_keyword(
        self, keyword: str, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Retrieve search sessions for a keyword

        Args:
            keyword: Search keyword
            limit: Maximum number of results to return

        Returns:
            List of search session dicts
        """
        pass


# ==================== Scraper Interfaces ====================
# Note: Scraper interfaces remain largely unchanged, but they will
# return data that gets mapped to the new Content/Author entities


class IVideoScraper(ABC):
    """Interface for video scraping"""

    @abstractmethod
    async def scrape(self, video_url: str) -> Optional[Dict[str, Any]]:
        """
        Scrape video metadata from TikTok

        Args:
            video_url: Full TikTok video URL

        Returns:
            Video data dict or None if failed
        """
        pass


class ICreatorScraper(ABC):
    """Interface for creator scraping"""

    @abstractmethod
    async def scrape(self, profile_url: str) -> Optional[Dict[str, Any]]:
        """
        Scrape creator profile from TikTok

        Args:
            profile_url: Full TikTok profile URL

        Returns:
            Creator data dict or None if failed
        """
        pass


class ICommentScraper(ABC):
    """Interface for comment scraping"""

    @abstractmethod
    async def scrape(
        self, video_url: str, max_comments: int = 0, full_mode: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Scrape comments from a TikTok video

        Args:
            video_url: Full TikTok video URL
            max_comments: Maximum comments to scrape (0 = all)
            full_mode: Use full browser mode (slower but more accurate)

        Returns:
            List of comment data dicts
        """
        pass


class ISearchScraper(ABC):
    """Interface for search functionality"""

    @abstractmethod
    async def search_videos(
        self, keyword: str, limit: int = 50, sort_by: str = "relevance"
    ) -> List[str]:
        """
        Search for videos by keyword

        Args:
            keyword: Search keyword
            limit: Maximum number of URLs to return
            sort_by: Sort method ('relevance', 'liked', 'recent')

        Returns:
            List of video URLs
        """
        pass


class IProfileScraper(ABC):
    """Interface for profile scraping"""

    @abstractmethod
    async def get_profile_videos(
        self, profile_url: str, limit: Optional[int] = None
    ) -> List[str]:
        """
        Get video URLs from a TikTok profile page

        Args:
            profile_url: Full TikTok profile URL (e.g., https://www.tiktok.com/@username)
            limit: Maximum number of video URLs to return (None = all available)

        Returns:
            List of video URLs
        """
        pass


# ==================== Media Download Interface ====================


class IMediaDownloader(ABC):
    """Interface for media download functionality"""

    @abstractmethod
    async def download_media(
        self,
        content: Content,  # Changed from video: Video
        media_type: Literal["video", "audio"],
        save_dir: str,
    ) -> Optional[str]:
        """
        Download media from TikTok

        Args:
            content: Content entity with download URLs
            media_type: Type of media to download ("video" or "audio")
            save_dir: Storage prefix/pseudo-directory inside object storage

        Returns:
            Storage URI string, or None if failed
        """
        pass

    @abstractmethod
    async def extract_audio_with_ffmpeg(self, video_path: str, audio_path: str) -> bool:
        """
        Extract audio from video file using ffmpeg

        Args:
            video_path: Path to video file
            audio_path: Destination path for audio file

        Returns:
            True if successful, False otherwise
        """
        pass


# ==================== Speech-to-Text Interface ====================

from dataclasses import dataclass


@dataclass
class STTResult:
    """
    Result from Speech-to-Text transcription
    
    Attributes:
        success: Whether the transcription was successful
        transcription: The transcribed text (empty string if failed)
        status: Current status of the transcription job. Supported values:
            - PROCESSING: Job is still being processed
            - COMPLETED: Job completed successfully
            - FAILED: Job failed during processing
            - NOT_FOUND: Job not found (404 response)
            - TIMEOUT: Polling exceeded max_retries
            - UNAUTHORIZED: Authentication failed (401 response)
            - EXCEPTION: Unexpected exception occurred
            - SUCCESS: Legacy status for backward compatibility
            - ERROR: Legacy status for backward compatibility
            - HTTP_ERROR: Legacy status for backward compatibility
            - PENDING: Legacy status for backward compatibility
        error_message: Error description if failed (empty string if successful)
        error_code: Numeric error code (0 for success)
        duration: Duration of the audio in seconds
        confidence: Confidence score of the transcription (0.0-1.0)
        processing_time: Time taken to process the transcription in seconds
    """

    success: bool
    transcription: Optional[str] = ""
    status: Optional[str] = "PENDING"
    error_message: Optional[str] = ""
    error_code: Optional[int] = 0
    duration: Optional[float] = 0.0
    confidence: Optional[float] = 0.0
    processing_time: Optional[float] = 0.0


class ISpeech2TextClient(ABC):
    """Interface for Speech-to-Text service"""

    @abstractmethod
    async def transcribe(self, audio_url: str, language: str = "vi") -> STTResult:
        """
        Transcribe audio from URL to text

        Args:
            audio_url: URL of the audio file (minio:// or http(s)://)
            language: Language code (default: "vi")

        Returns:
            STTResult with transcription and status info
        """
        pass


# ==================== Task Queue Interface ====================


class ITaskQueue(ABC):
    """Interface for message queue functionality"""

    @abstractmethod
    async def connect(self) -> None:
        """Connect to message queue"""
        pass

    @abstractmethod
    async def close(self) -> None:
        """Close message queue connection"""
        pass

    @abstractmethod
    async def publish_task(
        self, task_type: str, payload: Dict[str, Any], job_id: Optional[str] = None
    ) -> str:
        """
        Publish a task to the queue

        Args:
            task_type: Type of task
            payload: Task payload
            job_id: Optional job ID (generated if not provided)

        Returns:
            Job ID
        """
        pass

    @abstractmethod
    async def start_consuming(self) -> None:
        """Start consuming messages from queue"""
        pass

    @abstractmethod
    async def stop_consuming(self) -> None:
        """
        Stop consuming messages from queue
        """
        pass


class IArchiveStorage(ABC):
    """Interface for archival storage (MinIO)"""

    @abstractmethod
    async def upload_bytes(
        self,
        data: bytes,
        object_name: str,
        prefix: Optional[str] = None,
        content_type: Optional[str] = None,
        enable_compression: Optional[bool] = None,
        compression_level: Optional[int] = None,
        metadata: Optional[Dict[str, str]] = None,
    ) -> str:
        """
        Upload bytes data to storage

        Args:
            data: Bytes to upload
            object_name: Target object filename
            prefix: Optional prefix/folder
            content_type: Optional MIME type
            enable_compression: Override compression
            compression_level: Override compression level
            metadata: Custom metadata

        Returns:
            Object key/URI
        """
        pass


# ==================== Job Tracking Interface ====================


class IJobRepository(ABC):
    """Interface for job tracking"""

    @abstractmethod
    async def create_job(
        self,
        job_id: str,
        task_type: str,
        payload: Dict[str, Any],
        time_range: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None,
    ) -> bool:
        """
        Create a new job record

        Args:
            job_id: Unique job ID
            task_type: Type of task
            payload: Task payload
            time_range: Optional publish window in days
            since_date: Optional start date filter
            until_date: Optional end date filter

        Returns:
            True if successful
        """
        pass

    @abstractmethod
    async def update_job_status(
        self, job_id: str, status: str, error_message: Optional[str] = None
    ) -> bool:
        """
        Update job status

        Args:
            job_id: Job ID
            status: New status ('pending', 'processing', 'completed', 'failed')
            error_message: Optional error message

        Returns:
            True if successful
        """
        pass

    @abstractmethod
    async def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        """
        Get job by ID

        Args:
            job_id: Job ID

        Returns:
            Job data dict or None if not found
        """
        pass
