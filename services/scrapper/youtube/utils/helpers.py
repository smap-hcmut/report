"""
Helper functions for YouTube scraper
"""

import json
import re
from typing import Optional, Dict, Any, TYPE_CHECKING
from datetime import datetime
from pathlib import Path

if TYPE_CHECKING:
    from application.crawler_service import CrawlResult


def extract_project_id(job_id: str) -> Optional[str]:
    """
    Extract project_id (UUID) from job_id.

    Job ID formats:
    - Brand: {uuid}-brand-{index}
    - Competitor (simple): {uuid}-competitor-{index}
    - Competitor (with name): {uuid}-competitor-{name}-{index}
    - Dry-run: {uuid} (returns None)

    Args:
        job_id: Job identifier string

    Returns:
        Project ID (UUID) if found, None for dry-run jobs or invalid formats

    Examples:
        >>> extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0")
        'fc5d5ffb-36cc-4c8d-a288-f5215af7fb80'
        >>> extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0")
        'fc5d5ffb-36cc-4c8d-a288-f5215af7fb80'
        >>> extract_project_id("550e8400-e29b-41d4-a716-446655440000")
        None  # UUID format = dry-run
    """
    if not job_id:
        return None

    # Extract UUID from the beginning of job_id
    uuid_pattern = r"^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"
    match = re.match(uuid_pattern, job_id.lower())

    if not match:
        return None

    uuid = match.group(1)

    # If job_id IS exactly a UUID (dry-run), return None
    if uuid == job_id.lower():
        return None

    return uuid


def extract_brand_info(job_id: str) -> tuple[Optional[str], str]:
    """
    Extract brand_name and type from job_id.

    Job ID formats:
    - Brand: {uuid}-brand-{index} → brand_name from task payload, type="brand"
    - Competitor: {uuid}-competitor-{name}-{index} → brand_name={name}, type="competitor"
    - Dry-run: {uuid} → brand_name=None, type="unknown"

    Args:
        job_id: Job identifier string

    Returns:
        tuple: (brand_name, brand_type)
        - brand_name: Extracted brand name or None
        - brand_type: "brand", "competitor", or "unknown"

    Examples:
        >>> extract_brand_info("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Toyota-0")
        ('Toyota', 'competitor')
        >>> extract_brand_info("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0")
        (None, 'brand')
        >>> extract_brand_info("550e8400-e29b-41d4-a716-446655440000")
        (None, 'unknown')
    """
    if not job_id:
        return None, "unknown"

    job_id_lower = job_id.lower()

    if "-competitor-" in job_id_lower:
        # Format: {uuid}-competitor-{name}-{index}
        parts = job_id.split("-competitor-")
        if len(parts) > 1:
            # name-index → extract name
            name_part = parts[1]
            # Remove trailing index (e.g., "Toyota-0" → "Toyota")
            name_parts = name_part.rsplit("-", 1)
            if len(name_parts) > 1 and name_parts[1].isdigit():
                return name_parts[0], "competitor"
            return name_part, "competitor"
        return None, "competitor"

    if "-brand-" in job_id_lower:
        # Format: {uuid}-brand-{index}
        # brand_name needs to be provided from task payload
        return None, "brand"

    return None, "unknown"


def extract_video_id(url: str) -> Optional[str]:
    """
    Extract video ID from YouTube URL

    Supports formats:
    - https://www.youtube.com/watch?v=VIDEO_ID
    - https://youtu.be/VIDEO_ID
    - https://www.youtube.com/embed/VIDEO_ID
    - https://www.youtube.com/v/VIDEO_ID

    Args:
        url: YouTube video URL or video ID

    Returns:
        Video ID or None
    """
    patterns = [
        r"(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)([a-zA-Z0-9_-]{11})",
        r"youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})",
    ]

    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)

    # If URL is already just an ID
    if re.match(r"^[a-zA-Z0-9_-]{11}$", url):
        return url

    return None


def extract_channel_id(url: str) -> Optional[str]:
    """
    Extract channel ID from YouTube URL

    Supports formats:
    - https://www.youtube.com/channel/CHANNEL_ID
    - https://www.youtube.com/@username

    Args:
        url: YouTube channel URL

    Returns:
        Channel ID or username
    """
    patterns = [
        r"youtube\.com\/channel\/([a-zA-Z0-9_-]+)",
        r"youtube\.com\/@([a-zA-Z0-9_-]+)",
    ]

    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)

    return None


def clean_text(text: str) -> str:
    """
    Clean text by removing extra whitespace

    Args:
        text: Input text

    Returns:
        Cleaned text
    """
    if not text:
        return ""

    # Replace multiple whitespaces with single space
    text = re.sub(r"\s+", " ", text)

    # Strip leading/trailing whitespace
    text = text.strip()

    return text


def parse_duration(duration: str) -> int:
    """
    Parse ISO 8601 duration to seconds

    Args:
        duration: ISO 8601 duration string (e.g., PT1H2M10S)

    Returns:
        Duration in seconds
    """
    if not duration:
        return 0

    # Parse PT1H2M10S format
    pattern = r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"
    match = re.match(pattern, duration)

    if not match:
        return 0

    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = int(match.group(3) or 0)

    return hours * 3600 + minutes * 60 + seconds


def format_duration(seconds: int) -> str:
    """
    Format seconds to HH:MM:SS or MM:SS

    Args:
        seconds: Duration in seconds

    Returns:
        Formatted duration string
    """
    if seconds < 0:
        return "0:00"

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60

    if hours > 0:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    else:
        return f"{minutes}:{secs:02d}"


def save_json(data: dict, filepath: str):
    """
    Save data to JSON file

    Args:
        data: Data to save
        filepath: Output file path
    """
    try:
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        raise RuntimeError(f"Error saving JSON to {filepath}: {e}")


def load_json(filepath: str) -> dict:
    """
    Load data from JSON file

    Args:
        filepath: Input file path

    Returns:
        Loaded data
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data
    except Exception as e:
        raise RuntimeError(f"Error loading JSON from {filepath}: {e}")


def format_timestamp(timestamp: str) -> str:
    """
    Format ISO 8601 timestamp to readable format

    Args:
        timestamp: ISO 8601 timestamp

    Returns:
        Formatted timestamp
    """
    try:
        dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return timestamp


def map_to_new_format(
    result: "CrawlResult",
    job_id: str,
    keyword: Optional[str],
    task_type: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Map YouTube CrawlResult to new object format for MinIO upload

    Transforms flat structure to nested format with:
    - meta: job metadata and crawl info (includes task_type for Collector routing)
    - content: text, duration, hashtags, media (nested), title, content_detail
    - interaction: engagement metrics (no shares/saves for YouTube)
    - author: creator info with country and total_view_count
    - comments: comments with nested user objects (includes user.id and is_favorited)

    YouTube-specific fields:
    - content.title: Video title
    - content.content_detail: AI-generated summary
    - author.country: Channel country
    - author.total_view_count: Total channel views
    - comments[].user.id: Commenter channel ID
    - comments[].is_favorited: Comment favorited status

    Args:
        result: CrawlResult with content, author, comments
        job_id: Job ID for tracking
        keyword: Search keyword context
        task_type: Task type for Collector routing (e.g., 'dryrun_keyword', 'research_and_crawl')

    Returns:
        Dictionary in new format ready for JSON serialization
    """
    from domain.enums import ParentType

    content = result.content
    author = result.author
    comments = result.comments or []

    # Calculate engagement rate (YouTube: only likes + comments, no shares/saves)
    engagement_rate = 0.0
    if content.view_count and content.view_count > 0:
        total_engagement = (
            (content.like_count or 0)
            + (content.comment_count or 0)
            # YouTube doesn't have shares or saves
        )
        engagement_rate = round(total_engagement / content.view_count, 4)

    # Import settings for configurable metadata
    from config.settings import settings

    # Build meta section (Contract v2.0 compliant)
    meta = {
        "id": content.external_id,
        "platform": "YOUTUBE",  # UPPERCASE per contract
        "job_id": job_id,
        "task_type": task_type,  # For Collector routing (dryrun_keyword, research_and_crawl, etc.)
        "crawled_at": content.crawled_at.isoformat() if content.crawled_at else None,
        "published_at": (
            content.published_at.isoformat() if content.published_at else None
        ),
        "permalink": content.url,
        "keyword_source": keyword or content.keyword,
        "lang": settings.default_lang,  # Configurable language code
        "region": settings.default_region,  # Configurable region code
        "pipeline_version": settings.pipeline_version,  # Configurable pipeline version
        "fetch_status": "success" if result.success else "error",
        # Error fields (Contract v2.0)
        "error_code": result.error_code if not result.success else None,
        "error_message": result.error_message if not result.success else None,
        "error_details": result.error_response if not result.success else None,
    }

    # Build media object (nested structure)
    media = None
    if content.media_type and content.media_path:
        media_type_lower = content.media_type.lower()
        media = {
            "type": media_type_lower,
            "video_path": content.media_path if media_type_lower == "video" else None,
            "audio_path": content.media_path if media_type_lower == "audio" else None,
            # "thumbnail": None,  # TODO: Add thumbnail support
            # "resolution": None,  # TODO: Add resolution detection
            # "fps": None,  # TODO: Add FPS detection
            # "bitrate": None,  # TODO: Add bitrate detection
            "downloaded_at": (
                content.media_downloaded_at.isoformat()
                if content.media_downloaded_at
                else None
            ),
        }

    # Build content section
    content_obj = {
        "text": content.description,
        "duration": content.duration_seconds,
        "hashtags": content.tags or [],
        "sound_name": None,  # TikTok-only: Sound/music name
        "category": content.category,
        "title": content.title,  # YouTube-only: Video title
        "media": media,
        "transcription": content.transcription,
    }

    # Build interaction section
    interaction = {
        "views": content.view_count,
        "likes": content.like_count,
        "comments_count": content.comment_count,
        "shares": None,  # TikTok-only: Share count
        "saves": None,  # TikTok-only: Save/bookmark count
        "engagement_rate": engagement_rate,
        "updated_at": content.updated_at.isoformat() if content.updated_at else None,
    }

    # Build author section
    author_obj = None
    if author:
        author_obj = {
            "id": author.external_id,
            "name": author.display_name,
            "username": author.username,
            "followers": author.follower_count,  # YouTube: subscriber count
            "following": None,  # TikTok-only: Following count
            "likes": None,  # TikTok-only: Total creator likes
            "videos": author.video_count,
            "is_verified": author.verified or False,
            "bio": author.extra_json.get("description") if author.extra_json else None,
            "avatar_url": None,  # TODO: Add from scraper
            "profile_url": author.profile_url,
            "country": (
                author.extra_json.get("country") if author.extra_json else None
            ),  # YouTube-only: Channel country
            "total_view_count": (
                author.extra_json.get("total_view_count") if author.extra_json else None
            ),  # YouTube-only: Total channel views
        }

    # Build comments section (YouTube-specific: includes user.id and is_favorited)
    comments_list = []
    for comment in comments:
        # Determine parent_id and post_id based on parent_type
        parent_id = None
        post_id = content.external_id

        if hasattr(comment, "parent_type"):
            if comment.parent_type == ParentType.COMMENT:
                parent_id = comment.parent_id
            # post_id is always the content external_id

        # Check if commenter is the content author
        is_author = False
        if comment.commenter_name and content.author_username:
            is_author = (
                comment.commenter_name.lower() == content.author_username.lower()
            )

        # YouTube-specific: extract commenter channel ID from extra_json
        commenter_channel_id = None
        is_favorited = False
        if comment.extra_json:
            commenter_channel_id = comment.extra_json.get("author_channel_id")
            is_favorited = comment.extra_json.get("is_favorited", False)

        comment_obj = {
            "id": comment.external_id,
            "text": comment.comment_text,
            "author_name": comment.commenter_name,  # Flat field per Contract v2.0
            "likes": comment.like_count,
            "created_at": (
                comment.published_at.isoformat() if comment.published_at else None
            ),
            # Extra fields for backward compatibility
            "parent_id": parent_id,
            "post_id": post_id,
            "user": {
                "id": commenter_channel_id,  # YouTube: commenter channel ID | TikTok: None
                "name": comment.commenter_name,
                "avatar_url": None,  # TODO: Add from scraper
            },
            "replies_count": comment.reply_count,
            "published_at": (
                comment.published_at.isoformat() if comment.published_at else None
            ),
            "is_author": is_author,
            "media": None,  # TODO: Add comment media support
            "is_favorited": is_favorited,  # YouTube-only: Comment favorited status
        }
        comments_list.append(comment_obj)

    # Assemble final structure
    new_format = {
        "meta": meta,
        "content": content_obj,
        "interaction": interaction,
        "author": author_obj,
        "comments": comments_list,
    }

    return new_format
