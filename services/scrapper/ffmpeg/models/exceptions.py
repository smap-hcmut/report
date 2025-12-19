"""Exception hierarchy for FFmpeg service."""

from typing import Optional


class ConversionError(Exception):
    """Base exception for all conversion-related errors."""

    def __init__(
        self,
        message: str,
        video_id: Optional[str] = None,
        details: Optional[dict] = None,
    ) -> None:
        super().__init__(message)
        self.message = message
        self.video_id = video_id
        self.details = details or {}

    def __str__(self) -> str:
        if self.video_id:
            return f"[{self.video_id}] {self.message}"
        return self.message


class TransientConversionError(ConversionError):
    """
    Transient errors that may succeed if retried.

    Examples:
    - Network timeouts
    - MinIO connection failures
    - Temporary resource unavailability
    """

    pass


class PermanentConversionError(ConversionError):
    """
    Permanent errors that will not succeed if retried.

    Examples:
    - Invalid video format
    - Corrupted media file
    - Unsupported codec
    - FFmpeg execution errors
    """

    pass


class StorageError(ConversionError):
    """Errors related to object storage operations (MinIO)."""

    def __init__(
        self,
        message: str,
        bucket: Optional[str] = None,
        object_key: Optional[str] = None,
        operation: Optional[str] = None,
        **kwargs,
    ) -> None:
        super().__init__(message, **kwargs)
        self.bucket = bucket
        self.object_key = object_key
        self.operation = operation

    def __str__(self) -> str:
        parts = [self.message]
        if self.operation:
            parts.append(f"operation={self.operation}")
        if self.bucket and self.object_key:
            parts.append(f"path={self.bucket}/{self.object_key}")
        return " | ".join(parts)


class StorageNotFoundError(StorageError):
    """Raised when a file is not found in object storage."""

    pass


class StorageAccessError(StorageError, TransientConversionError):
    """Raised when storage is temporarily inaccessible."""

    pass


class FFmpegExecutionError(PermanentConversionError):
    """Raised when FFmpeg execution fails."""

    def __init__(
        self,
        message: str,
        return_code: Optional[int] = None,
        stderr: Optional[str] = None,
        **kwargs,
    ) -> None:
        super().__init__(message, **kwargs)
        self.return_code = return_code
        self.stderr = stderr

    def __str__(self) -> str:
        parts = [self.message]
        if self.return_code is not None:
            parts.append(f"exit_code={self.return_code}")
        if self.stderr:
            stderr_preview = self.stderr[:200] + "..." if len(self.stderr) > 200 else self.stderr
            parts.append(f"stderr={stderr_preview}")
        return " | ".join(parts)


class InvalidMediaError(PermanentConversionError):
    """Raised when media file is invalid or corrupted."""

    pass


class ConfigurationError(ConversionError):
    """Raised when service configuration is invalid."""

    pass
