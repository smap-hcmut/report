"""
TikTok Creator API Scraper
Uses HTML parsing to extract creator data
"""
import httpx
import re
import json
from typing import Optional, Dict
from datetime import datetime

from utils.logger import logger
from utils.helpers import extract_username, clean_text
from config import settings


class CreatorAPI:
    """Fast creator scraper using HTML parsing"""

    def __init__(self):
        self.headers = {
            'User-Agent': settings.crawler_user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': 'https://www.tiktok.com/',
        }
        self.timeout = settings.crawler_timeout / 1000  # Convert ms to seconds
        self.cache = {}  # Cache to avoid re-crawling same creator

    async def scrape(self, creator_url: str) -> Optional[Dict]:
        """
        Scrape creator data by parsing HTML page

        Args:
            creator_url: TikTok profile URL

        Returns:
            Dictionary containing creator data or None if failed
        """
        username = extract_username(creator_url)
        if not username:
            logger.error(f"Could not extract username from URL: {creator_url}")
            return None

        # Check cache
        if username in self.cache:
            logger.info(f"Using cached data for creator: {username}")
            return self.cache[username]

        logger.info(f"Scraping creator via HTML parsing: {username}")

        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                # Request HTML page
                response = await client.get(creator_url, headers=self.headers)

                if response.status_code != 200:
                    logger.warning(f"HTTP returned status {response.status_code}")
                    return None

                html = response.text

                # Parse creator data from HTML
                creator_data = self._parse_html(html, username, creator_url)

                if creator_data:
                    # Cache result
                    self.cache[username] = creator_data
                    logger.info(f"Successfully scraped creator {username} via HTML parsing")
                    return creator_data
                else:
                    logger.warning(f"Failed to extract creator data from HTML")
                    return None

        except Exception as e:
            logger.error(f"Error scraping creator {username}: {e}")
            return None

    def _parse_html(self, html: str, username: str, profile_url: str) -> Optional[Dict]:
        """
        Parse creator metadata from HTML page
        Extracts JSON from embedded script tags
        """
        try:
            # Try __UNIVERSAL_DATA_FOR_REHYDRATION__ (current TikTok structure)
            universal_pattern = r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__"[^>]*>(.*?)</script>'
            match = re.search(universal_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Navigate to userInfo
                try:
                    # Structure: {"__DEFAULT_SCOPE__": {"webapp.user-detail": {"userInfo": {...}}}}
                    default_scope = data.get('__DEFAULT_SCOPE__', {})

                    # Look for userInfo in any key
                    for key, value in default_scope.items():
                        if isinstance(value, dict) and 'userInfo' in value:
                            user_info = value['userInfo']
                            return self._parse_user_info(user_info, username, profile_url)
                except (KeyError, AttributeError) as e:
                    logger.debug(f"KeyError in __UNIVERSAL_DATA_FOR_REHYDRATION__: {e}")

            # Try __NEXT_DATA__ (older TikTok pages)
            next_data_pattern = r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>'
            match = re.search(next_data_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Extract creator data from __NEXT_DATA__
                try:
                    user_info = data['props']['pageProps']['userInfo']
                    return self._parse_user_info(user_info, username, profile_url)
                except KeyError as e:
                    logger.debug(f"KeyError in __NEXT_DATA__: {e}")

            # Try SIGI_STATE (oldest TikTok pages)
            sigi_pattern = r'<script id="SIGI_STATE"[^>]*>(.*?)</script>'
            match = re.search(sigi_pattern, html, re.DOTALL)

            if match:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Extract creator data from SIGI_STATE
                if 'UserModule' in data and 'users' in data['UserModule']:
                    users = data['UserModule']['users']
                    for user_id, user_info in users.items():
                        return self._parse_user_info({'user': user_info, 'stats': user_info.get('stats', {})}, username, profile_url)

            logger.warning("No creator data found in HTML (tried __UNIVERSAL_DATA_FOR_REHYDRATION__, __NEXT_DATA__, SIGI_STATE)")
            return None

        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return None
        except Exception as e:
            logger.error(f"Error parsing HTML: {e}")
            return None

    def _parse_user_info(self, user_info: dict, username: str, profile_url: str) -> Dict:
        """Parse userInfo structure from TikTok"""

        user = user_info.get('user', {})
        stats = user_info.get('stats', {})

        # Basic info
        display_name = user.get('nickname', '')
        bio = user.get('signature', '')
        verified = user.get('verified', False)

        # Stats
        follower_count = stats.get('followerCount', 0)
        following_count = stats.get('followingCount', 0)
        total_likes = stats.get('heartCount', 0)  # Total likes across all videos
        video_count = stats.get('videoCount', 0)

        creator_data = {
            'username': username,
            'display_name': clean_text(display_name),
            'bio': clean_text(bio),
            'follower_count': follower_count,
            'following_count': following_count,
            'total_likes': total_likes,
            'total_videos': video_count,
            'verified': verified,
            'profile_url': profile_url,
            'crawled_at': datetime.now().isoformat(),
            'partial_data': False
        }

        return creator_data
