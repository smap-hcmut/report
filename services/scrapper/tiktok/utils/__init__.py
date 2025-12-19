"""
Utility Functions
Helper functions for file I/O, sanitization, logging, and other common operations
"""
from .io_utils import (
    sanitize_filename,
    ensure_dir_exists,
    get_file_size_mb,
    is_valid_file_path,
    read_file_async,
    write_file_async,
    get_file_extension,
    join_paths,
    get_absolute_path,
    create_unique_filename
)
from .logger import logger
from .helpers import extract_video_id, clean_text
from .browser_stealth import setup_stealth_page

__all__ = [
    # I/O utils
    "sanitize_filename",
    "ensure_dir_exists",
    "get_file_size_mb",
    "is_valid_file_path",
    "read_file_async",
    "write_file_async",
    "get_file_extension",
    "join_paths",
    "get_absolute_path",
    "create_unique_filename",
    # Logger
    "logger",
    # Helpers
    "extract_video_id",
    "clean_text",
    # Browser stealth
    "setup_stealth_page",
]
