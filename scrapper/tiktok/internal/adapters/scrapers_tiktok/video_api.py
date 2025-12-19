"""
TikTok Video Scraper - HTML Parsing Approach
Parse video metadata from embedded JSON in HTML page
No API signature required!
"""
import httpx
import re
import json
from typing import Optional, Dict
from datetime import datetime, timezone

from utils.logger import logger
from utils.helpers import extract_video_id, clean_text
from config import settings


class VideoAPI:
    """Fast video scraper using HTML parsing (no signature needed)"""

    def __init__(self):
        self.headers = {
            'User-Agent': settings.crawler_user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': 'https://www.tiktok.com/',
        }
        self.timeout = settings.crawler_timeout / 1000  # Convert ms to seconds

    async def scrape(self, video_url: str) -> Optional[Dict]:
        """
        Scrape video data by parsing HTML page

        Args:
            video_url: Full TikTok video URL

        Returns:
            Dictionary containing video data or None if failed
        """
        video_id = extract_video_id(video_url)
        if not video_id:
            logger.error(f"Could not extract video ID from URL: {video_url}")
            return None

        logger.info(f"Scraping video via HTML parsing: {video_id}")

        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                # Request HTML page
                response = await client.get(video_url, headers=self.headers)

                if response.status_code != 200:
                    logger.warning(f"HTTP returned status {response.status_code}")
                    return None

                html = response.text

                # Parse video data from HTML
                video_data = self._parse_html(html, video_id, video_url)

                if video_data:
                    logger.info(f"Successfully scraped video {video_id} via HTML parsing")
                    return video_data
                else:
                    logger.warning(f"Failed to extract video data from HTML")
                    return None

        except Exception as e:
            logger.error(f"Error scraping video {video_id}: {e}")
            return None

    def _parse_html(self, html: str, video_id: str, video_url: str) -> Optional[Dict]:
        """
        Parse video metadata from HTML page
        Extracts JSON from embedded script tags
        """
        try:
            # Try __UNIVERSAL_DATA_FOR_REHYDRATION__ (current TikTok structure)
            universal_pattern = r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__"[^>]*>(.*?)</script>'
            match = re.search(universal_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Navigate to itemInfo.itemStruct
                try:
                    # Structure: {"__DEFAULT_SCOPE__": {"webapp.video-detail": {"itemInfo": {"itemStruct": {...}}}}}
                    default_scope = data.get('__DEFAULT_SCOPE__', {})

                    # Look for itemInfo in any key
                    for key, value in default_scope.items():
                        if isinstance(value, dict) and 'itemInfo' in value:
                            item_info = value['itemInfo']
                            if 'itemStruct' in item_info:
                                item_struct = item_info['itemStruct']
                                return self._parse_item_struct(item_struct, video_id, video_url)
                except (KeyError, AttributeError) as e:
                    logger.debug(f"KeyError in __UNIVERSAL_DATA_FOR_REHYDRATION__: {e}")

            # Try __NEXT_DATA__ (older TikTok pages)
            next_data_pattern = r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>'
            match = re.search(next_data_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Extract video data from __NEXT_DATA__
                try:
                    item_struct = data['props']['pageProps']['itemInfo']['itemStruct']
                    return self._parse_item_struct(item_struct, video_id, video_url)
                except KeyError as e:
                    logger.debug(f"KeyError in __NEXT_DATA__: {e}")

            # Try SIGI_STATE (oldest TikTok pages)
            sigi_pattern = r'<script id="SIGI_STATE"[^>]*>(.*?)</script>'
            match = re.search(sigi_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Extract video data from SIGI_STATE
                # ItemModule contains video data keyed by video ID
                if 'ItemModule' in data:
                    item_module = data['ItemModule']
                    # Get first video (usually the one we want)
                    for key, item_struct in item_module.items():
                        return self._parse_item_struct(item_struct, video_id, video_url)

            logger.warning("No video data found in HTML (tried __UNIVERSAL_DATA_FOR_REHYDRATION__, __NEXT_DATA__, SIGI_STATE)")
            return None

        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return None
        except Exception as e:
            logger.error(f"Error parsing HTML: {e}")
            return None

    def _parse_item_struct(self, item_struct: dict, video_id: str, video_url: str) -> Dict:
        """Parse itemStruct (video data structure from TikTok)"""

        # Basic info
        desc = item_struct.get('desc', '')

        # Stats
        stats = item_struct.get('stats', {})
        view_count = stats.get('playCount', 0)
        like_count = stats.get('diggCount', 0)
        comment_count = stats.get('commentCount', 0)
        share_count = stats.get('shareCount', 0)
        collect_count = stats.get('collectCount', 0)

        # Timestamp
        create_time = item_struct.get('createTime', 0)
        upload_time = self._format_timestamp(create_time)

        # Music/Sound
        music = item_struct.get('music', {})
        sound_name = music.get('title', '')

        # Hashtags
        challenges = item_struct.get('challenges', [])
        hashtags = [f"#{c.get('title', '')}" for c in challenges if c.get('title')]

        # Duration
        video_info = item_struct.get('video', {})
        duration = video_info.get('duration', 0)

        # Creator
        author = item_struct.get('author', {})
        creator_username = author.get('uniqueId', '')
        creator_display_name = author.get('nickname')
        creator_id = author.get('id') or author.get('secUid')

        # NEW: Extract download URLs for media downloader
        # Video URL: try downloadAddr first, fallback to playAddr
        video_download_url = video_info.get('downloadAddr') or video_info.get('playAddr')
        # Audio URL: direct MP3 from music.playUrl
        audio_url = music.get('playUrl')

        video_data = {
            'video_id': video_id,
            'url': video_url,
            'description': clean_text(desc),
            'upload_time': upload_time,
            'creator_id': creator_id,
            'view_count': view_count,
            'like_count': like_count,
            'comment_count': comment_count,
            'share_count': share_count,
            'save_count': collect_count,
            'sound_name': clean_text(sound_name),
            'hashtags': hashtags,
            'duration': duration,
            'creator_username': creator_username,
            'creator_display_name': clean_text(creator_display_name) if creator_display_name else None,
            'crawled_at': datetime.now().isoformat(),
            # NEW: Download URLs (transient fields for media downloader)
            'video_download_url': video_download_url,
            'audio_url': audio_url
        }

        return video_data

    def _format_timestamp(self, timestamp: int) -> Optional[str]:
        """Convert Unix timestamp to ISO 8601 string (UTC)"""
        if not timestamp:
            return None

        try:
            if isinstance(timestamp, str):
                timestamp = int(timestamp)
            dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
            return dt.isoformat().replace("+00:00", "Z")
        except Exception:
            return None
