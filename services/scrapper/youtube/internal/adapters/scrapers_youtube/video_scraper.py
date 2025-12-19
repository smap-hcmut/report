"""
YouTube Video Scraper - Adapter Layer
Implements IVideoScraper using yt-dlp
"""
import asyncio
import yt_dlp
from typing import Optional, Dict, Any
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

from application.interfaces import IVideoScraper
from utils.logger import logger


class YouTubeVideoScraper(IVideoScraper):
    """
    YouTube Video Scraper Implementation

    Uses yt-dlp to extract video metadata from YouTube.
    Wraps synchronous yt-dlp calls in asyncio executor for pure async operation.
    """

    def __init__(
        self,
        executor: Optional[ThreadPoolExecutor] = None,
        quiet: bool = True,
        no_warnings: bool = True
    ):
        """
        Initialize video scraper

        Args:
            executor: Thread pool executor for async operations
            quiet: Suppress yt-dlp output
            no_warnings: Suppress warnings
        """
        self.executor = executor or ThreadPoolExecutor(max_workers=4)
        self.ydl_opts = {
            'quiet': quiet,
            'no_warnings': no_warnings,
            'extract_flat': False,
            'getcomments': False,
            'skip_download': True,
        }

    async def scrape(self, video_url: str) -> Optional[Dict[str, Any]]:
        """
        Scrape video metadata from YouTube

        Args:
            video_url: Full YouTube video URL or video ID

        Returns:
            Video data dict or None if failed
        """
        try:
            # Normalize URL
            if not video_url.startswith('http'):
                video_url = f"https://www.youtube.com/watch?v={video_url}"

            logger.info(f"Scraping video: {video_url}")

            # Run yt-dlp in executor (async wrapper for sync code)
            loop = asyncio.get_event_loop()
            info = await loop.run_in_executor(
                self.executor,
                self._extract_info_sync,
                video_url
            )

            if not info:
                logger.error(f"Failed to extract video info: {video_url}")
                return None

            # Parse to domain-compatible dict
            video_data = self._parse_video_data(info, video_url)
            logger.info(f"Successfully scraped video: {info.get('title', 'Unknown')}")
            return video_data

        except Exception as e:
            logger.error(f"Error scraping video {video_url}: {e}")
            return None

    def _extract_info_sync(self, video_url: str) -> Optional[dict]:
        """
        Synchronous yt-dlp extraction (runs in thread pool)

        Args:
            video_url: YouTube video URL

        Returns:
            Raw info dict from yt-dlp
        """
        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                info = ydl.extract_info(video_url, download=False)
                return info
        except Exception:
            return None

    def _parse_video_data(self, info: dict, video_url: str) -> Dict[str, Any]:
        """
        Parse yt-dlp info dict to Video entity-compatible dict

        Args:
            info: Raw yt-dlp info dict
            video_url: Original video URL

        Returns:
            Parsed video data dict
        """
        video_id = info.get('id', '')

        # Parse upload date (YYYYMMDD) to ISO format
        upload_date = info.get('upload_date', '')
        published_at = None
        if upload_date and len(upload_date) == 8:
            try:
                year = upload_date[0:4]
                month = upload_date[4:6]
                day = upload_date[6:8]
                published_at = f"{year}-{month}-{day}T00:00:00Z"
            except Exception:
                published_at = None

        # Extract category
        categories = info.get('categories', [])
        category = categories[0] if categories else None

        # Clean text fields
        title = self._clean_text(info.get('title', ''))
        description = self._clean_text(info.get('description', ''))

        # Extract channel metadata
        channel_title = self._clean_text(info.get('channel', '') or info.get('uploader', ''))
        channel_custom_url = info.get('channel_handle') or info.get('uploader_id')

        # Extract download URLs (for media downloader)
        video_download_url = None
        audio_url = None

        # Get best video format URL
        if 'formats' in info:
            # Find best video format
            video_formats = [f for f in info['formats'] if f.get('vcodec') != 'none']
            if video_formats:
                best_video = max(video_formats, key=lambda f: f.get('height', 0) or 0)
                video_download_url = best_video.get('url')

            # Find best audio format
            audio_formats = [f for f in info['formats'] if f.get('acodec') != 'none' and f.get('vcodec') == 'none']
            if audio_formats:
                best_audio = max(audio_formats, key=lambda f: f.get('abr', 0) or 0)
                audio_url = best_audio.get('url')

        # Build video data dict matching Video entity structure
        video_data = {
            'video_id': video_id,
            'url': video_url if 'youtube.com' in video_url else f"https://www.youtube.com/watch?v={video_id}",
            'title': title if title else None,
            'description': description if description else None,
            'published_at': published_at,
            'duration': info.get('duration', 0) or 0,
            'view_count': info.get('view_count', 0) or 0,
            'like_count': info.get('like_count', 0) or 0,
            'comment_count': info.get('comment_count', 0) or 0,
            'tags': info.get('tags', []) or [],
            'category': category,
            'channel_id': info.get('channel_id'),
            'channel_title': channel_title if channel_title else None,
            'channel_custom_url': channel_custom_url,
            'video_download_url': video_download_url,
            'audio_url': audio_url,
            'crawled_at': datetime.now().isoformat()
        }

        return video_data

    @staticmethod
    def _clean_text(text: str) -> str:
        """Clean text by removing extra whitespace"""
        if not text:
            return ''
        return ' '.join(text.split())

    async def close(self) -> None:
        """Close the executor"""
        self.executor.shutdown(wait=False)
