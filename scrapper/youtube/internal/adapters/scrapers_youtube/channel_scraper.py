"""
YouTube Channel Scraper - Adapter Layer
Implements IAuthorScraper and IChannelScraper using yt-dlp
"""
import asyncio
import yt_dlp
from typing import Optional, Dict, Any, List
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

from application.interfaces import IAuthorScraper, IChannelScraper


class YouTubeChannelScraper(IAuthorScraper, IChannelScraper):
    """
    YouTube Channel Scraper Implementation

    Uses yt-dlp to extract channel metadata and video listings from YouTube.
    Wraps synchronous yt-dlp calls in asyncio executor for pure async operation.
    """

    def __init__(
        self,
        executor: Optional[ThreadPoolExecutor] = None,
        quiet: bool = True,
        no_warnings: bool = True
    ):
        """
        Initialize channel scraper

        Args:
            executor: Thread pool executor for async operations
            quiet: Suppress yt-dlp output
            no_warnings: Suppress warnings
        """
        self.executor = executor or ThreadPoolExecutor(max_workers=4)
        self.ydl_opts = {
            'quiet': quiet,
            'no_warnings': no_warnings,
            'extract_flat': True,  # Fast extraction for channel
            'skip_download': True,
        }

    async def scrape(self, channel_url: str) -> Optional[Dict[str, Any]]:
        """
        Scrape channel information from YouTube

        Args:
            channel_url: Full YouTube channel URL or channel ID

        Returns:
            Channel data dict or None if failed
        """
        try:
            # Normalize URL
            if not channel_url.startswith('http'):
                channel_url = f"https://www.youtube.com/channel/{channel_url}"

            # Run yt-dlp in executor
            loop = asyncio.get_event_loop()
            info = await loop.run_in_executor(
                self.executor,
                self._extract_info_sync,
                channel_url
            )

            if not info:
                return None

            # Parse to domain-compatible dict
            channel_data = self._parse_channel_data(info, channel_url)
            return channel_data

        except Exception:
            return None

    async def get_channel_video_urls(
        self,
        channel_url: str,
        limit: int = 0
    ) -> List[str]:
        """
        Fetch all video URLs from a channel (standard videos only).
        
        Args:
            channel_url: YouTube channel URL (e.g., https://www.youtube.com/@username)
            limit: Maximum number of videos to fetch (0 = all)
            
        Returns:
            List of video URLs
        """
        try:
            # Normalize channel URL to /videos tab
            videos_url = self._normalize_to_videos_tab(channel_url)
            
            # Run yt-dlp in executor
            loop = asyncio.get_event_loop()
            info = await loop.run_in_executor(
                self.executor,
                self._extract_playlist_sync,
                videos_url,
                limit
            )
            
            if not info:
                return []
            
            # Extract video URLs from entries
            video_urls = []
            entries = info.get('entries', [])
            
            for entry in entries:
                if not entry:
                    continue
                    
                # Get video ID
                video_id = entry.get('id')
                if video_id:
                    video_url = f"https://www.youtube.com/watch?v={video_id}"
                    video_urls.append(video_url)
                    
                    if limit and len(video_urls) >= limit:
                        break
            
            return video_urls
            
        except Exception as e:
            # Log error if logger available
            return []

    def _normalize_to_videos_tab(self, channel_url: str) -> str:
        """
        Normalize channel URL to the /videos tab.
        
        Args:
            channel_url: Original channel URL
            
        Returns:
            URL pointing to /videos tab
        """
        # Remove trailing slash
        channel_url = channel_url.rstrip('/')
        
        # If already has /videos, return as is
        if '/videos' in channel_url:
            return channel_url
        
        # If has other tab, replace it
        for tab in ['/shorts', '/streams', '/live', '/playlists', '/community', '/about']:
            if tab in channel_url:
                return channel_url.replace(tab, '/videos')
        
        # Otherwise append /videos
        return f"{channel_url}/videos"

    def _extract_playlist_sync(self, playlist_url: str, limit: int) -> Optional[dict]:
        """
        Synchronous yt-dlp playlist extraction (runs in thread pool).
        
        Args:
            playlist_url: YouTube playlist/channel URL
            limit: Maximum number of entries to extract
            
        Returns:
            Raw info dict from yt-dlp
        """
        try:
            opts = self.ydl_opts.copy()
            if limit > 0:
                opts['playlistend'] = limit
            
            with yt_dlp.YoutubeDL(opts) as ydl:
                info = ydl.extract_info(playlist_url, download=False)
                return info
        except Exception:
            return None

    def _extract_info_sync(self, channel_url: str) -> Optional[dict]:
        """
        Synchronous yt-dlp extraction (runs in thread pool)

        Args:
            channel_url: YouTube channel URL

        Returns:
            Raw info dict from yt-dlp
        """
        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                info = ydl.extract_info(channel_url, download=False)
                return info
        except Exception:
            return None

    def _parse_channel_data(self, info: dict, channel_url: str) -> Dict[str, Any]:
        """
        Parse yt-dlp info dict to Channel entity-compatible dict

        Args:
            info: Raw yt-dlp info dict
            channel_url: Original channel URL

        Returns:
            Parsed channel data dict
        """
        channel_id = info.get('channel_id') or info.get('id', '')

        # Clean text fields
        channel_title = self._clean_text(info.get('channel', '') or info.get('uploader', ''))
        description = self._clean_text(info.get('description', ''))

        # Build channel data dict matching Channel entity structure
        channel_data = {
            'channel_id': channel_id,
            'url': channel_url if 'youtube.com' in channel_url else f"https://www.youtube.com/channel/{channel_id}",
            'channel_title': channel_title if channel_title else None,
            'description': description if description else None,
            'subscriber_count': info.get('subscriber_count', 0) or 0,
            'video_count': info.get('video_count', 0) or 0,
            'view_count': info.get('view_count', 0) or 0,
            'custom_url': info.get('uploader_id'),
            'country': info.get('country'),
            'crawled_at': datetime.now().isoformat()
        }

        return channel_data

    @staticmethod
    def _clean_text(text: str) -> str:
        """Clean text by removing extra whitespace"""
        if not text:
            return ''
        return ' '.join(text.split())

    async def close(self) -> None:
        """Close the executor"""
        self.executor.shutdown(wait=False)
