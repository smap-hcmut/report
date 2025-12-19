"""FFmpeg infrastructure layer - HTTP client for remote FFmpeg service."""

from .client import RemoteFFmpegClient, CircuitBreaker

__all__ = ["RemoteFFmpegClient", "CircuitBreaker"]
