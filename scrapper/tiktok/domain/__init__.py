"""
Domain Layer
Core business entities and value objects

Updated to expose the new Content/Author-based schema defined in refactor_modelDB.md.
This layer remains framework-agnostic and only contains pure business logic.
"""
from .entities import Content, Author, Comment, SearchSession, CrawlJob
from .value_objects import Metrics

__all__ = [
    # Entities
    "Content",
    "Author",
    "Comment",
    "SearchSession",
    "CrawlJob",

    # Value Objects
    "Metrics",
]
