"""
Domain Layer - YouTube
Exports the normalized entities/value objects used across the YouTube scraper.
Matches the schema defined in refactor_modelDB.md and mirrors the TikTok implementation.
"""
from .entities import Content, Author, Comment, SearchSession, CrawlJob
from .value_objects import Metrics

__all__ = [
    "Content",
    "Author",
    "Comment",
    "SearchSession",
    "CrawlJob",
    "Metrics",
]
