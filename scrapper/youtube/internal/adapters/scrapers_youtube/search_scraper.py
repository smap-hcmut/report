"""
YouTube Search Scraper - Adapter Layer
Implements ISearchScraper using yt-dlp
"""
import asyncio
import yt_dlp
from typing import List, Optional
from concurrent.futures import ThreadPoolExecutor

from application.interfaces import ISearchScraper
from utils.logger import logger


class YouTubeSearchScraper(ISearchScraper):
    """
    YouTube Search Scraper Implementation

    Uses yt-dlp to search for videos by keyword.
    Wraps synchronous yt-dlp calls in asyncio executor for pure async operation.
    """

    def __init__(
        self,
        executor: Optional[ThreadPoolExecutor] = None,
        quiet: bool = True,
        no_warnings: bool = True
    ):
        """
        Initialize search scraper

        Args:
            executor: Thread pool executor for async operations
            quiet: Suppress yt-dlp output
            no_warnings: Suppress warnings
        """
        self.executor = executor or ThreadPoolExecutor(max_workers=4)
        self.ydl_opts = {
            'quiet': quiet,
            'no_warnings': no_warnings,
            'extract_flat': True,  # Fast search without downloading
            'skip_download': True,
        }

    async def search_videos(
        self,
        keyword: str,
        limit: int = 50,
        sort_by: str = 'relevance'
    ) -> List[str]:
        """
        Search for videos by keyword

        Args:
            keyword: Search keyword
            limit: Maximum number of URLs to return
            sort_by: Sort method (not implemented by yt-dlp search, defaults to relevance)

        Returns:
            List of video URLs
        """
        try:
            logger.info(f"Searching YouTube for: '{keyword}' (limit: {limit})")

            # Run search in executor
            loop = asyncio.get_event_loop()
            video_urls = await loop.run_in_executor(
                self.executor,
                self._search_sync,
                keyword,
                limit
            )

            logger.info(f"Found {len(video_urls)} videos for keyword: '{keyword}'")
            return video_urls

        except Exception as e:
            logger.error(f"Search failed for keyword '{keyword}': {e}")
            return []

    def _search_sync(self, keyword: str, limit: int) -> List[str]:
        """
        Synchronous search using yt-dlp (runs in thread pool)

        Args:
            keyword: Search keyword
            limit: Maximum results

        Returns:
            List of video URLs
        """
        try:
            # yt-dlp search syntax: "ytsearch{limit}:{keyword}"
            search_url = f"ytsearch{limit}:{keyword}"

            video_urls = []

            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                result = ydl.extract_info(search_url, download=False)

                if result and 'entries' in result:
                    for entry in result['entries']:
                        if entry and 'id' in entry:
                            video_id = entry['id']
                            video_url = f"https://www.youtube.com/watch?v={video_id}"
                            video_urls.append(video_url)

                            if len(video_urls) >= limit:
                                break

            return video_urls

        except Exception:
            return []

    async def close(self) -> None:
        """Close the executor"""
        self.executor.shutdown(wait=False)
