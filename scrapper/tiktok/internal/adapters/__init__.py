"""
Internal Adapters
Implementations of application interfaces for external dependencies
"""
from .repository_mongo import (
    MongoRepository,
    MongoContentRepository,
    MongoAuthorRepository,
    MongoCommentRepository,
    MongoSearchSessionRepository,
    MongoCrawlJobRepository,
)

__all__ = [
    "MongoRepository",
    "MongoContentRepository",
    "MongoAuthorRepository",
    "MongoCommentRepository",
    "MongoSearchSessionRepository",
    "MongoCrawlJobRepository",
]
