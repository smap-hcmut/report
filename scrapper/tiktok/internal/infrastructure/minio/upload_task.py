"""
Upload task models and status tracking.

Defines data structures for async upload tasks and their lifecycle.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, Any


class UploadState(str, Enum):
    """Upload task state."""
    QUEUED = "QUEUED"
    COMPRESSING = "COMPRESSING"
    UPLOADING = "UPLOADING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELED = "CANCELED"


@dataclass
class UploadTask:
    """
    Upload task definition.

    Contains all information needed to compress and upload data to MinIO.
    """

    task_id: str
    bucket_name: str
    object_name: str
    data: bytes
    content_type: Optional[str] = None
    enable_compression: bool = True
    compression_level: int = 2
    metadata: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    def get_size(self) -> int:
        """Get size of data in bytes."""
        return len(self.data)

    def get_size_mb(self) -> float:
        """Get size of data in MB."""
        return self.get_size() / (1024 * 1024)


@dataclass
class UploadStatus:
    """
    Upload task status and progress.

    Tracks the current state and progress of an upload operation.
    """

    task_id: str
    status: UploadState
    percentage: float = 0.0
    bytes_uploaded: int = 0
    total_bytes: int = 0
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    def update_progress(self, bytes_uploaded: int, total_bytes: int) -> None:
        """
        Update upload progress.

        Args:
            bytes_uploaded: Number of bytes uploaded so far
            total_bytes: Total bytes to upload
        """
        self.bytes_uploaded = bytes_uploaded
        self.total_bytes = total_bytes
        if total_bytes > 0:
            self.percentage = (bytes_uploaded / total_bytes) * 100

    def mark_started(self) -> None:
        """Mark upload as started."""
        self.started_at = datetime.now()

    def mark_completed(self) -> None:
        """Mark upload as completed."""
        self.status = UploadState.COMPLETED
        self.completed_at = datetime.now()
        self.percentage = 100.0

    def mark_failed(self, error: str) -> None:
        """
        Mark upload as failed.

        Args:
            error: Error message
        """
        self.status = UploadState.FAILED
        self.error = error
        self.completed_at = datetime.now()

    def mark_canceled(self) -> None:
        """Mark upload as canceled."""
        self.status = UploadState.CANCELED
        self.completed_at = datetime.now()

    def is_terminal(self) -> bool:
        """
        Check if status is in a terminal state.

        Returns:
            True if completed, failed, or canceled
        """
        return self.status in (
            UploadState.COMPLETED,
            UploadState.FAILED,
            UploadState.CANCELED
        )

    def get_duration_seconds(self) -> Optional[float]:
        """
        Get duration of upload in seconds.

        Returns:
            Duration in seconds, or None if not yet completed
        """
        if not self.started_at or not self.completed_at:
            return None
        return (self.completed_at - self.started_at).total_seconds()


@dataclass
class UploadResult:
    """
    Upload operation result.

    Contains the final result of an upload, including storage location
    and compression statistics.
    """

    task_id: str
    success: bool
    object_key: Optional[str] = None
    error: Optional[str] = None
    duration: Optional[float] = None

    # Compression stats
    original_size: Optional[int] = None
    compressed_size: Optional[int] = None
    compression_ratio: Optional[float] = None
    compression_algorithm: Optional[str] = None

    def get_storage_uri(self, bucket: str) -> Optional[str]:
        """
        Get full storage URI.

        Args:
            bucket: Bucket name

        Returns:
            Storage URI (e.g., "minio://bucket/path/to/file")
        """
        if not self.object_key:
            return None
        return f"minio://{bucket}/{self.object_key}"

    def get_compression_savings_percentage(self) -> Optional[float]:
        """
        Get percentage of space saved by compression.

        Returns:
            Percentage saved (e.g., 94.5 means 94.5% reduction)
        """
        if self.compression_ratio is None:
            return None
        return (1 - self.compression_ratio) * 100
