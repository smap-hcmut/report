"""
Helper utilities for TikTok crawler
"""

import asyncio
import random
import re
from typing import Optional, List, Dict, Any, TYPE_CHECKING
from datetime import datetime
from utils.logger import logger

if TYPE_CHECKING:
    from application.crawler_service import CrawlResult


def random_delay(min_sec: float = 2, max_sec: float = 5) -> float:
    """Generate random delay in seconds"""
    return random.uniform(min_sec, max_sec)


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


async def smart_delay(min_sec: float = 2, max_sec: float = 5):
    """Async delay with random interval"""
    delay = random_delay(min_sec, max_sec)
    logger.debug(f"Waiting {delay:.2f} seconds...")
    await asyncio.sleep(delay)


def extract_video_id(url: str) -> Optional[str]:
    """Extract video ID from TikTok URL"""
    patterns = [
        r"/video/(\d+)",
        r"/@[\w.-]+/video/(\d+)",
        r"/v/(\d+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def extract_username(url: str) -> Optional[str]:
    """Extract username from TikTok URL"""
    match = re.search(r"/@([\w.-]+)", url)
    return match.group(1) if match else None


def parse_count(text: str) -> int:
    """
    Parse count from text like '1.2M', '45.3K', '123'
    Returns integer value
    """
    if not text:
        return 0

    text = text.strip().upper().replace(",", "")

    multipliers = {
        "K": 1000,
        "M": 1000000,
        "B": 1000000000,
    }

    for suffix, multiplier in multipliers.items():
        if suffix in text:
            try:
                number = float(text.replace(suffix, ""))
                return int(number * multiplier)
            except ValueError:
                return 0

    try:
        return int(float(text))
    except ValueError:
        return 0


def clean_text(text: str) -> str:
    """Clean and normalize text"""
    if not text:
        return ""
    return text.strip().replace("\n", " ").replace("\r", "")


async def try_selectors(page, selectors: List[str], timeout: int = 5000):
    """
    Try multiple selectors and return first matching element
    """
    for selector in selectors:
        try:
            element = await page.wait_for_selector(
                selector, timeout=timeout, state="visible"
            )
            if element:
                return element
        except Exception:
            continue
    return None


async def try_get_text(page, selectors: List[str], default: str = "") -> str:
    """
    Try to get text content from multiple selectors
    """
    element = await try_selectors(page, selectors)
    if element:
        try:
            text = await element.text_content()
            return clean_text(text) if text else default
        except Exception:
            pass
    return default


async def try_get_attribute(
    page, selectors: List[str], attribute: str, default: str = ""
) -> str:
    """
    Try to get attribute from multiple selectors
    """
    element = await try_selectors(page, selectors)
    if element:
        try:
            attr = await element.get_attribute(attribute)
            return attr if attr else default
        except Exception:
            pass
    return default


def save_json(data: dict, filepath: str):
    """Save data to JSON file"""
    import json
    import os
    from config import OUTPUT_CONFIG

    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(
            data,
            f,
            indent=OUTPUT_CONFIG["indent"],
            ensure_ascii=OUTPUT_CONFIG["ensure_ascii"],
        )
    logger.info(f"Saved data to {filepath}")


def generate_filename(prefix: str, identifier: str) -> str:
    """Generate timestamped filename"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return f"{prefix}_{identifier}_{timestamp}.json"


def map_to_new_format(
    result: "CrawlResult",
    job_id: str,
    keyword: Optional[str],
    task_type: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Map current CrawlResult to new object format for MinIO upload

    Transforms flat structure to nested format with:
    - meta: job metadata and crawl info (includes task_type for Collector routing)
    - content: text, duration, hashtags, media (nested)
    - interaction: engagement metrics
    - author: creator info
    - comments: comments with nested user objects

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

    # Calculate engagement rate
    engagement_rate = 0.0
    if content.view_count and content.view_count > 0:
        total_engagement = (
            (content.like_count or 0)
            + (content.comment_count or 0)
            + (content.share_count or 0)
        )
        engagement_rate = round(total_engagement / content.view_count, 4)

    # Import settings for configurable metadata
    from config.settings import settings

    # Build meta section (Contract v2.0 compliant)
    meta = {
        "id": content.external_id,
        "platform": (
            content.source.upper() if content.source else "TIKTOK"
        ),  # UPPERCASE per contract
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
        "sound_name": content.sound_name,  # TikTok-only: Sound/music name
        "category": content.category,
        "title": None,  # YouTube-only: Video title (TikTok doesn't have separate title)
        "media": media,
        "transcription": content.transcription,
        "transcription_status": content.transcription_status,
        "transcription_error": content.transcription_error,
    }

    # Build interaction section
    interaction = {
        "views": content.view_count,
        "likes": content.like_count,
        "comments_count": content.comment_count,
        "shares": content.share_count,
        "saves": content.save_count,
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
            "followers": author.follower_count,
            "following": author.following_count,  # TikTok-only: Following count
            "likes": author.like_count,  # TikTok-only: Total creator likes
            "videos": author.video_count,
            "is_verified": author.verified or False,
            "bio": author.extra_json.get("bio") if author.extra_json else None,
            "avatar_url": None,  # TODO: Add from scraper
            "profile_url": author.profile_url,
            "country": None,  # YouTube-only: Channel country
            "total_view_count": None,  # YouTube-only: Total channel views
        }

    # Build comments section
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
                "id": None,  # TikTok: TODO - Add commenter external_id from scraper
                "name": comment.commenter_name,
                "avatar_url": None,  # TODO: Add from scraper
            },
            "replies_count": comment.reply_count,
            "published_at": (
                comment.published_at.isoformat() if comment.published_at else None
            ),
            "is_author": is_author,
            "media": None,  # TODO: Add comment media support
            "is_favorited": False,  # YouTube-only: Comment favorited status
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
