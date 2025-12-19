"""Main FastAPI application for FFmpeg conversion service."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from core.config import get_settings
from core.container import close_container, init_container
from core.logging import configure_logging
from cmd.api.routes import router

settings = get_settings()
configure_logging(settings.log_level)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for application startup and shutdown.

    Handles:
    - Dependency container initialization
    - Resource cleanup on shutdown
    """
    # Startup
    logger.info("Initializing FFmpeg conversion service...")
    init_container(settings)
    logger.info("Service initialized successfully")

    yield

    # Shutdown
    logger.info("Shutting down FFmpeg conversion service...")
    await close_container()
    logger.info("Service shut down successfully")


app = FastAPI(
    title="FFmpeg Conversion Service",
    version="1.0.0",
    description="Microservice for converting MP4 videos to MP3 audio using FFmpeg",
    lifespan=lifespan,
)

app.include_router(router)
