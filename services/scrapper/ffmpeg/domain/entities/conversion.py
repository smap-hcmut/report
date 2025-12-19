"""Conversion domain entities."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional

from ..enums import AudioFormat, AudioQuality, ConversionStatus


@dataclass
class MediaFile:
    """Represents a media file in object storage."""

    bucket: str
    object_key: str
    format: AudioFormat | str
    size_bytes: Optional[int] = None
    duration_seconds: Optional[float] = None

    @property
    def storage_path(self) -> str:
        """Get the full storage path."""
        return f"{self.bucket}/{self.object_key}"


@dataclass
class ConversionJob:
    """Represents a media conversion job."""

    video_id: str
    source: MediaFile
    target_bucket: str
    target_key: str
    audio_format: AudioFormat = AudioFormat.MP3
    audio_quality: AudioQuality = AudioQuality.MEDIUM
    status: ConversionStatus = ConversionStatus.PENDING
    created_at: datetime = field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None

    def start(self) -> None:
        """Mark job as started."""
        self.status = ConversionStatus.PROCESSING
        self.started_at = datetime.utcnow()

    def complete(self, result: "ConversionResult") -> None:
        """Mark job as completed."""
        self.status = ConversionStatus.COMPLETED
        self.completed_at = datetime.utcnow()

    def fail(self, error: str) -> None:
        """Mark job as failed."""
        self.status = ConversionStatus.FAILED
        self.completed_at = datetime.utcnow()
        self.error_message = error

    @property
    def duration_seconds(self) -> Optional[float]:
        """Get job duration in seconds."""
        if self.started_at and self.completed_at:
            return (self.completed_at - self.started_at).total_seconds()
        return None


@dataclass
class ConversionResult:
    """Result of a conversion operation."""

    output_file: MediaFile
    duration_seconds: float
    bitrate: str
    success: bool = True
    error_message: Optional[str] = None
    ffmpeg_stderr: Optional[str] = None

    @classmethod
    def success_result(
        cls,
        output_file: MediaFile,
        duration: float,
        bitrate: str,
    ) -> "ConversionResult":
        """Create a successful conversion result."""
        return cls(
            output_file=output_file,
            duration_seconds=duration,
            bitrate=bitrate,
            success=True,
        )

    @classmethod
    def failure_result(
        cls,
        error: str,
        ffmpeg_stderr: Optional[str] = None,
    ) -> "ConversionResult":
        """Create a failed conversion result."""
        return cls(
            output_file=MediaFile(bucket="", object_key="", format=""),
            duration_seconds=0.0,
            bitrate="",
            success=False,
            error_message=error,
            ffmpeg_stderr=ffmpeg_stderr,
        )
