"""Dependency injection container for FFmpeg service."""

from typing import Optional

from minio import Minio

from core.config import Settings
from services.converter import MediaConverter


class DependencyContainer:
    """Container for managing service dependencies."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self._minio_client: Optional[Minio] = None
        self._converter: Optional[MediaConverter] = None

    def get_minio_client(self) -> Minio:
        """Get or create MinIO client instance."""
        if self._minio_client is None:
            self._minio_client = Minio(
                self.settings.minio_endpoint,
                access_key=self.settings.minio_access_key,
                secret_key=self.settings.minio_secret_key,
                secure=self.settings.minio_secure,
            )
        return self._minio_client

    def get_converter(self) -> MediaConverter:
        """Get or create MediaConverter instance."""
        if self._converter is None:
            self._converter = MediaConverter(
                minio_client=self.get_minio_client(),
                settings=self.settings,
            )
        return self._converter

    async def close(self) -> None:
        """Clean up resources."""
        # MinIO client doesn't require explicit cleanup
        # But we can reset the instances
        self._minio_client = None
        self._converter = None


# Global container instance (initialized in main.py)
_container: Optional[DependencyContainer] = None


def get_container() -> DependencyContainer:
    """Get the global dependency container."""
    if _container is None:
        raise RuntimeError("Dependency container not initialized. Call init_container() first.")
    return _container


def init_container(settings: Settings) -> DependencyContainer:
    """Initialize the global dependency container."""
    global _container
    _container = DependencyContainer(settings)
    return _container


async def close_container() -> None:
    """Close and cleanup the global dependency container."""
    global _container
    if _container is not None:
        await _container.close()
        _container = None
