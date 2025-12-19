"""
Structured Error Response Builder for YouTube Crawler

Provides standardized error responses for downstream services (Collector, Analytics).
Maps exceptions to error codes and builds consistent error payloads.
"""

from typing import Optional, Dict, Any, Type
from datetime import datetime, timezone

from domain.enums import ErrorCode


class CrawlerError(Exception):
    """Base exception for crawler errors with error code support."""

    def __init__(
        self,
        message: str,
        code: ErrorCode = ErrorCode.UNKNOWN_ERROR,
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}


class RateLimitError(CrawlerError):
    """Raised when rate limited by the platform."""

    def __init__(
        self,
        message: str = "Rate limited by platform",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.RATE_LIMITED, details)


class ContentNotFoundError(CrawlerError):
    """Raised when content is not found or removed."""

    def __init__(
        self,
        message: str = "Content not found",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.CONTENT_NOT_FOUND, details)


class ContentRemovedError(CrawlerError):
    """Raised when content has been removed."""

    def __init__(
        self,
        message: str = "Content has been removed",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.CONTENT_REMOVED, details)


class NetworkError(CrawlerError):
    """Raised for network connectivity issues."""

    def __init__(
        self, message: str = "Network error", details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(message, ErrorCode.NETWORK_ERROR, details)


class TimeoutError(CrawlerError):
    """Raised when request times out."""

    def __init__(
        self,
        message: str = "Request timed out",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.TIMEOUT, details)


class ParseError(CrawlerError):
    """Raised when response parsing fails."""

    def __init__(
        self,
        message: str = "Failed to parse response",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.PARSE_ERROR, details)


class MediaDownloadError(CrawlerError):
    """Raised when media download fails."""

    def __init__(
        self,
        message: str = "Media download failed",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.MEDIA_DOWNLOAD_FAILED, details)


class StorageError(CrawlerError):
    """Raised when storage operation fails."""

    def __init__(
        self,
        message: str = "Storage operation failed",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(message, ErrorCode.STORAGE_ERROR, details)


def build_error_response(
    code: ErrorCode,
    message: str,
    details: Optional[Dict[str, Any]] = None,
    url: Optional[str] = None,
    job_id: Optional[str] = None,
    content_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Build a structured error response for downstream services.

    Args:
        code: ErrorCode enum value
        message: Human-readable error message
        details: Additional error details (stack trace, raw error, etc.)
        url: URL that caused the error
        job_id: Job ID for tracking
        content_id: Content external ID if available

    Returns:
        Structured error response dict with:
        - error_code: String error code
        - error_message: Human-readable message
        - error_details: Additional context
        - timestamp: ISO timestamp
        - context: URL, job_id, content_id
    """
    response = {
        "error_code": code.value,
        "error_message": message,
        "error_details": details or {},
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "context": {},
    }

    if url:
        response["context"]["url"] = url
    if job_id:
        response["context"]["job_id"] = job_id
    if content_id:
        response["context"]["content_id"] = content_id

    return response


def map_exception_to_error_code(exc: Exception) -> ErrorCode:
    """
    Map a Python exception to an ErrorCode.

    Args:
        exc: Exception instance

    Returns:
        Appropriate ErrorCode for the exception type
    """
    import asyncio
    import socket

    # Check for our custom exceptions first
    if isinstance(exc, CrawlerError):
        return exc.code

    # Network errors
    if isinstance(exc, asyncio.TimeoutError):
        return ErrorCode.TIMEOUT
    if isinstance(exc, socket.timeout):
        return ErrorCode.TIMEOUT
    if isinstance(exc, ConnectionRefusedError):
        return ErrorCode.CONNECTION_REFUSED
    if isinstance(exc, socket.gaierror):
        return ErrorCode.DNS_ERROR

    # Try to import aiohttp (optional dependency)
    try:
        import aiohttp

        if isinstance(exc, aiohttp.ClientError):
            return ErrorCode.NETWORK_ERROR
    except ImportError:
        pass

    # Try to import httpx (optional dependency for yt-dlp)
    try:
        import httpx

        if isinstance(exc, httpx.HTTPError):
            return ErrorCode.NETWORK_ERROR
        if isinstance(exc, httpx.TimeoutException):
            return ErrorCode.TIMEOUT
    except ImportError:
        pass

    # HTTP errors (if using aiohttp or similar)
    if hasattr(exc, "status"):
        status = getattr(exc, "status", 0)
        if status == 429:
            return ErrorCode.RATE_LIMITED
        if status == 401 or status == 403:
            return ErrorCode.AUTH_FAILED
        if status == 404:
            return ErrorCode.CONTENT_NOT_FOUND
        if status >= 500:
            return ErrorCode.INTERNAL_ERROR

    # yt-dlp specific errors
    exc_name = exc.__class__.__name__
    if "DownloadError" in exc_name:
        error_str = str(exc).lower()
        if "private" in error_str or "unavailable" in error_str:
            return ErrorCode.CONTENT_UNAVAILABLE
        if "removed" in error_str or "deleted" in error_str:
            return ErrorCode.CONTENT_REMOVED
        if "not found" in error_str or "404" in error_str:
            return ErrorCode.CONTENT_NOT_FOUND
        return ErrorCode.MEDIA_DOWNLOAD_FAILED

    # JSON/parsing errors
    if isinstance(exc, (ValueError, KeyError)) and "json" in str(exc).lower():
        return ErrorCode.PARSE_ERROR

    # File/IO errors
    if isinstance(exc, (IOError, OSError)):
        return ErrorCode.STORAGE_ERROR

    # Default
    return ErrorCode.UNKNOWN_ERROR


def build_error_from_exception(
    exc: Exception,
    url: Optional[str] = None,
    job_id: Optional[str] = None,
    content_id: Optional[str] = None,
    include_traceback: bool = False,
) -> Dict[str, Any]:
    """
    Build a structured error response from an exception.

    Args:
        exc: Exception instance
        url: URL that caused the error
        job_id: Job ID for tracking
        content_id: Content external ID if available
        include_traceback: Whether to include stack trace in details

    Returns:
        Structured error response dict
    """
    import traceback

    code = map_exception_to_error_code(exc)
    message = str(exc) or exc.__class__.__name__

    details: Dict[str, Any] = {
        "exception_type": exc.__class__.__name__,
    }

    # Include original error details if it's a CrawlerError
    if isinstance(exc, CrawlerError) and exc.details:
        details.update(exc.details)

    # Include traceback if requested
    if include_traceback:
        details["traceback"] = traceback.format_exc()

    return build_error_response(
        code=code,
        message=message,
        details=details,
        url=url,
        job_id=job_id,
        content_id=content_id,
    )
