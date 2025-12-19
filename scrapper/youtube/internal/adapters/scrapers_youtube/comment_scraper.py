"""
YouTube Comment Scraper - Adapter Layer
Implements ICommentScraper using youtube-comment-downloader
"""
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta
import re
from concurrent.futures import ThreadPoolExecutor
from youtube_comment_downloader import YoutubeCommentDownloader, SORT_BY_POPULAR

from application.interfaces import ICommentScraper
from utils.logger import logger


class YouTubeCommentScraper(ICommentScraper):
    """
    YouTube Comment Scraper Implementation

    Uses youtube-comment-downloader for reliable comment extraction.
    Wraps synchronous operations in asyncio executor for pure async operation.
    """

    def __init__(
        self,
        executor: Optional[ThreadPoolExecutor] = None,
        default_max_comments: int = 200
    ):
        """
        Initialize comment scraper

        Args:
            executor: Thread pool executor for async operations
            default_max_comments: Default max comments if not specified
        """
        self.executor = executor or ThreadPoolExecutor(max_workers=4)
        self.downloader = YoutubeCommentDownloader()
        self.default_max_comments = default_max_comments

    async def scrape(
        self,
        video_id: str,
        max_comments: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Scrape comments from a YouTube video

        Args:
            video_id: YouTube video ID
            max_comments: Maximum comments to scrape (0 = default)

        Returns:
            List of comment data dicts
        """
        try:
            # Use default if max_comments is 0
            limit = max_comments if max_comments > 0 else self.default_max_comments

            logger.info(f"Extracting comments for video {video_id} (limit: {limit})")

            # Construct URL
            video_url = f"https://www.youtube.com/watch?v={video_id}"

            # Run scraping in executor
            loop = asyncio.get_event_loop()
            comments = await loop.run_in_executor(
                self.executor,
                self._scrape_comments_sync,
                video_url,
                limit
            )

            logger.info(f"Extracted {len(comments)} comments for video {video_id}")
            return comments

        except Exception as e:
            logger.error(f"Failed to extract comments for video {video_id}: {e}")
            return []

    def _scrape_comments_sync(
        self,
        video_url: str,
        max_comments: int
    ) -> List[Dict[str, Any]]:
        """
        Synchronous comment scraping (runs in thread pool)

        Args:
            video_url: YouTube video URL
            max_comments: Maximum comments to fetch

        Returns:
            List of parsed comment dicts
        """
        try:
            comments = []
            count = 0

            # Download comments sorted by popularity
            for comment in self.downloader.get_comments_from_url(
                video_url,
                sort_by=SORT_BY_POPULAR
            ):
                parsed = self._parse_comment(comment, count)
                if parsed:
                    comments.append(parsed)
                    count += 1

                # Stop when max reached
                if count >= max_comments:
                    break

            return comments

        except Exception:
            return []

    def _parse_comment(self, comment: Dict, index: int) -> Optional[Dict[str, Any]]:
        """
        Parse a single comment to Comment entity-compatible dict

        Args:
            comment: Raw comment dict from youtube-comment-downloader
            index: Comment index for fallback ID

        Returns:
            Parsed comment dict or None if parsing fails
        """
        try:
            comment_id = comment.get('cid', f'comment_{index}')
            text = comment.get('text', '')
            author = comment.get('author', '')
            channel_id = comment.get('channel', '')

            # Parse timestamp
            time_parsed = comment.get('time_parsed', 0)
            time_text = comment.get('time') or comment.get('time_text')
            published_at = self._format_timestamp(time_parsed, time_text)

            # Like count
            like_count = comment.get('votes', 0)
            if isinstance(like_count, str):
                like_count = self._parse_count(like_count)

            # Reply info
            is_reply = comment.get('is_reply', False)
            parent_id = comment.get('parent', '')
            reply_count = comment.get('reply_count', 0)

            # Build comment data dict matching Comment entity structure
            parsed = {
                'comment_id': str(comment_id),
                'comment_text': self._clean_text(text),
                'author_name': self._clean_text(author),
                'author_channel_id': channel_id if channel_id else None,
                'published_at': published_at,
                'like_count': like_count,
                'reply_count': reply_count,
                'is_favorited': False,  # Not available from this source
                'parent_id': parent_id if is_reply and parent_id else None,
                'crawled_at': datetime.now(timezone.utc).isoformat()
            }

            return parsed

        except Exception:
            return None

    @staticmethod
    def _parse_count(count_str: str) -> int:
        """
        Parse count string like '1.2K' to integer

        Args:
            count_str: Count string (e.g., '1.2K', '3M')

        Returns:
            Integer count
        """
        if not count_str or not isinstance(count_str, str):
            return 0

        count_str = count_str.strip().replace(',', '')

        try:
            if 'K' in count_str:
                return int(float(count_str.replace('K', '')) * 1000)
            elif 'M' in count_str:
                return int(float(count_str.replace('M', '')) * 1000000)
            elif 'B' in count_str:
                return int(float(count_str.replace('B', '')) * 1000000000)
            else:
                return int(count_str)
        except (ValueError, TypeError):
            return 0

    @staticmethod
    def _format_timestamp(time_parsed: Optional[float], time_text: Optional[str]) -> Optional[str]:
        """Return ISO8601 timestamp with timezone info."""
        if time_parsed:
            try:
                return datetime.fromtimestamp(float(time_parsed), tz=timezone.utc).isoformat()
            except (ValueError, TypeError, OSError):
                pass

        if time_text:
            relative = YouTubeCommentScraper._parse_relative_time(time_text)
            if relative:
                return relative.isoformat()

        return None

    @staticmethod
    def _parse_relative_time(text: str) -> Optional[datetime]:
        """Parse strings like '3 weeks ago' or '1 hour ago'."""
        text = text.strip().lower()
        if not text.endswith("ago"):
            return None
        text = text[:-3].strip()

        match = re.match(r"(?P<value>\d+)\s*(?P<unit>year|years|month|months|week|weeks|day|days|hour|hours|minute|minutes|second|seconds)", text)
        if not match:
            return None

        value = int(match.group("value"))
        unit = match.group("unit")
        seconds_per_unit = {
            "second": 1,
            "seconds": 1,
            "minute": 60,
            "minutes": 60,
            "hour": 3600,
            "hours": 3600,
            "day": 86400,
            "days": 86400,
            "week": 604800,
            "weeks": 604800,
            "month": 2592000,
            "months": 2592000,
            "year": 31536000,
            "years": 31536000,
        }
        seconds = seconds_per_unit.get(unit)
        if not seconds:
            return None
        return datetime.now(timezone.utc) - timedelta(seconds=value * seconds)

    @staticmethod
    def _clean_text(text: str) -> str:
        """Clean text by removing extra whitespace"""
        if not text:
            return ''
        return ' '.join(text.split())

    async def close(self) -> None:
        """Close the executor"""
        self.executor.shutdown(wait=False)
