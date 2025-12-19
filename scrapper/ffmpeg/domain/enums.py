"""Domain enums for FFmpeg service."""

from enum import Enum


class ConversionStatus(str, Enum):
    """Status of a conversion job."""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class AudioFormat(str, Enum):
    """Supported audio formats."""

    MP3 = "mp3"
    WAV = "wav"
    AAC = "aac"
    FLAC = "flac"


class AudioQuality(str, Enum):
    """Audio quality presets."""

    LOW = "128k"      # 128 kbps
    MEDIUM = "192k"   # 192 kbps
    HIGH = "256k"     # 256 kbps
    VERY_HIGH = "320k"  # 320 kbps
