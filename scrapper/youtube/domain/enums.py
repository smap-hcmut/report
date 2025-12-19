"""
Enums for YouTube scraper database schema.
Matches the specification in refactor_modelDB.md
Copied from TikTok implementation for consistency across platforms
"""

from enum import Enum


class SourcePlatform(str, Enum):
    """Source platform enum for multi-platform support"""
    TIKTOK = "TIKTOK"
    YOUTUBE = "YOUTUBE"
    FACEBOOK = "FACEBOOK"


class MediaType(str, Enum):
    """Media type classification"""
    VIDEO = "VIDEO"
    IMAGE = "IMAGE"
    AUDIO = "AUDIO"
    POST = "POST"


class ParentType(str, Enum):
    """Parent type for comments (can be attached to content or other comments)"""
    CONTENT = "CONTENT"
    COMMENT = "COMMENT"


class SearchSortBy(str, Enum):
    """Search result sorting options"""
    RELEVANCE = "RELEVANCE"
    LIKE = "LIKE"
    VIEW = "VIEW"
    DATE = "DATE"


class JobStatus(str, Enum):
    """Job execution status"""
    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    RETRYING = "RETRYING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELED = "CANCELED"


class JobType(str, Enum):
    """Job task types"""
    # Current queue task names (lowercase)
    RESEARCH_KEYWORD = "research_keyword"
    CRAWL_LINKS = "crawl_links"
    RESEARCH_AND_CRAWL = "research_and_crawl"
    FETCH_CHANNEL_CONTENT = "fetch_channel_content"
    DRYRUN_KEYWORD = "dryrun_keyword"

    # Legacy/alternate task names (uppercase, kept for backward compatibility)
    SEARCH_BY_KEYWORD = "SEARCH_BY_KEYWORD"
    FETCH_CONTENT_DETAIL = "FETCH_CONTENT_DETAIL"
    FETCH_COMMENTS = "FETCH_COMMENTS"
    FETCH_AUTHOR = "FETCH_AUTHOR"
    REFRESH_METRICS_SNAPSHOT = "REFRESH_METRICS_SNAPSHOT"


class ErrorCode(str, Enum):
    """
    Standardized error codes for crawler operations.
    Used for structured error reporting to downstream services.
    """
    # Rate limiting and access errors
    RATE_LIMITED = "RATE_LIMITED"  # Too many requests, need to slow down
    AUTH_FAILED = "AUTH_FAILED"  # Authentication/authorization failed
    ACCESS_DENIED = "ACCESS_DENIED"  # Content access denied (private, geo-blocked)

    # Content errors
    CONTENT_REMOVED = "CONTENT_REMOVED"  # Content was deleted or removed
    CONTENT_NOT_FOUND = "CONTENT_NOT_FOUND"  # Content doesn't exist
    CONTENT_UNAVAILABLE = "CONTENT_UNAVAILABLE"  # Content temporarily unavailable

    # Network and infrastructure errors
    NETWORK_ERROR = "NETWORK_ERROR"  # General network connectivity issue
    TIMEOUT = "TIMEOUT"  # Request timed out
    CONNECTION_REFUSED = "CONNECTION_REFUSED"  # Server refused connection
    DNS_ERROR = "DNS_ERROR"  # DNS resolution failed

    # Parsing and data errors
    PARSE_ERROR = "PARSE_ERROR"  # Failed to parse response data
    INVALID_URL = "INVALID_URL"  # URL format is invalid
    INVALID_RESPONSE = "INVALID_RESPONSE"  # Response format unexpected

    # Media errors
    MEDIA_DOWNLOAD_FAILED = "MEDIA_DOWNLOAD_FAILED"  # Failed to download media
    MEDIA_TOO_LARGE = "MEDIA_TOO_LARGE"  # Media file exceeds size limit
    MEDIA_FORMAT_ERROR = "MEDIA_FORMAT_ERROR"  # Unsupported media format

    # Storage errors
    STORAGE_ERROR = "STORAGE_ERROR"  # MinIO/storage operation failed
    UPLOAD_FAILED = "UPLOAD_FAILED"  # Failed to upload to storage

    # Database errors
    DATABASE_ERROR = "DATABASE_ERROR"  # MongoDB operation failed

    # Generic errors
    UNKNOWN_ERROR = "UNKNOWN_ERROR"  # Unclassified error
    INTERNAL_ERROR = "INTERNAL_ERROR"  # Internal service error

