"""
Application Layer
Use cases and business workflows

This layer contains the application-specific business rules.
It orchestrates the flow of data to and from the domain entities,
and directs those entities to use their enterprise wide business rules.
"""
from .interfaces import (
    # Repository interfaces
    IContentRepository,
    IAuthorRepository,
    ICommentRepository,
    IJobRepository,
    ISearchSessionRepository,

    # Scraper interfaces
    IVideoScraper,
    ICreatorScraper,
    ICommentScraper,
    ISearchScraper,

    # Media download interface
    IMediaDownloader,

    # Queue interface
    ITaskQueue,
)

from .crawler_service import CrawlerService, CrawlResult
from .task_service import TaskService

__all__ = [
    # Interfaces
    "IContentRepository",
    "IAuthorRepository",
    "ICommentRepository",
    "IJobRepository",
    "ISearchSessionRepository",
    "IVideoScraper",
    "ICreatorScraper",
    "ICommentScraper",
    "ISearchScraper",
    "IMediaDownloader",
    "ITaskQueue",

    # Services
    "CrawlerService",
    "CrawlResult",
    "TaskService",
]
