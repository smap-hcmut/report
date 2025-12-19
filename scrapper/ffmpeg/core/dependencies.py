"""FastAPI dependency injection functions."""

from typing import Annotated

from fastapi import Depends
from minio import Minio

from core.config import Settings, settings
from core.container import get_container, DependencyContainer
from services.converter import MediaConverter


def get_settings() -> Settings:
    """Get application settings."""
    return settings


def get_dependency_container() -> DependencyContainer:
    """Get the dependency container."""
    return get_container()


def get_minio_client(
    container: Annotated[DependencyContainer, Depends(get_dependency_container)],
) -> Minio:
    """Get MinIO client from container."""
    return container.get_minio_client()


def get_converter(
    container: Annotated[DependencyContainer, Depends(get_dependency_container)],
) -> MediaConverter:
    """Get MediaConverter service from container."""
    return container.get_converter()
