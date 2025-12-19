"""
TikTok Search Scraper
Search for videos by keyword and extract video URLs
"""
import asyncio
from typing import List, Optional
from playwright.async_api import Browser, Page
import re

from config import settings
from utils.logger import logger
from utils.helpers import smart_delay, extract_video_id
from utils.browser_stealth import setup_stealth_page


class SearchScraper:
    """Scraper for TikTok search functionality"""

    def __init__(self, browser: Browser):
        self.browser = browser

    async def search_videos(self, keyword: str, limit: int = 10, sort_by: str = 'relevance') -> List[str]:
        """
        Search for videos by keyword and return video URLs

        Args:
            keyword: Search keyword
            limit: Maximum number of video URLs to return
            sort_by: Sort method - 'relevance', 'liked', or 'recent'

        Returns:
            List of TikTok video URLs
        """
        logger.info(f"Searching TikTok for keyword: '{keyword}' (limit: {limit}, sort: {sort_by})")

        page = await self.browser.new_page(
            viewport={'width': 1920, 'height': 1080},
            user_agent=settings.crawler_user_agent
        )

        # Apply stealth
        await setup_stealth_page(page)

        all_video_urls = []

        try:
            # Use 'top' search which works reliably
            # Note: TikTok's video tab with sorting often returns empty results
            # Top search provides best mix of relevant and popular content
            strategies = [
                ('top', 'relevance'),    # Top results (most reliable)
            ]

            for tab, sort_method in strategies:
                logger.info(f"Trying search strategy: tab={tab}, sort={sort_method}")

                # Build search URL with tab and sort
                search_url = self._build_search_url(keyword, tab, sort_method)

                await page.goto(search_url, wait_until='domcontentloaded', timeout=settings.crawler_timeout)

                # Wait for search results to load
                await asyncio.sleep(settings.crawler_wait_after_load / 1000)

                # Scroll to load more results (increased scrolls)
                await self._scroll_search_results(page, limit)

                # Extract video URLs
                video_urls = await self._extract_video_urls(page, limit * 2)  # Get more than needed

                logger.info(f"Strategy '{tab}/{sort_method}' found {len(video_urls)} videos")

                # Merge results
                for url in video_urls:
                    if url not in all_video_urls:
                        all_video_urls.append(url)

                # Stop if we have enough
                if len(all_video_urls) >= limit:
                    break

                # Wait before next strategy
                await asyncio.sleep(2)

            # Limit final results
            final_urls = all_video_urls[:limit]

            # Summary message
            if len(final_urls) < limit:
                logger.info(f"Found {len(final_urls)} video URLs for keyword '{keyword}' (requested: {limit})")
                logger.info(f"Note: TikTok search returned fewer results than requested - this is normal for some keywords")
            else:
                logger.info(f"Found total {len(final_urls)} video URLs for keyword '{keyword}'")

        except Exception as e:
            logger.error(f"Error searching for keyword '{keyword}': {e}")

        finally:
            await page.close()
            await smart_delay()

        return final_urls

    def _build_search_url(self, keyword: str, tab: str = 'video', sort_by: str = 'relevance') -> str:
        """
        Build TikTok search URL with filters

        Args:
            keyword: Search keyword
            tab: 'video', 'top', 'user', 'hashtag'
            sort_by: 'relevance', 'liked', 'recent'

        Returns:
            Complete search URL
        """
        import urllib.parse

        # URL encode keyword
        encoded_keyword = urllib.parse.quote(keyword)

        # Base URL
        if tab == 'video':
            base = f"https://www.tiktok.com/search/video?q={encoded_keyword}"
        elif tab == 'top':
            base = f"https://www.tiktok.com/search?q={encoded_keyword}"
        elif tab == 'user':
            base = f"https://www.tiktok.com/search/user?q={encoded_keyword}"
        elif tab == 'hashtag':
            base = f"https://www.tiktok.com/search/hashtag?q={encoded_keyword}"
        else:
            base = f"https://www.tiktok.com/search?q={encoded_keyword}"

        # Add sort parameter for video tab
        if tab == 'video':
            if sort_by == 'liked':
                base += "&sort_type=1"  # Most liked
            elif sort_by == 'recent':
                base += "&sort_type=0"  # Most recent
            # relevance doesn't need parameter (default)

        logger.debug(f"Built search URL: {base}")
        return base

    async def _scroll_search_results(self, page: Page, target_count: int):
        """Scroll search results to load more videos"""
        logger.debug(f"Scrolling search results to load at least {target_count} unique videos...")

        # Calculate scrolls needed (more videos = more scrolls)
        # Each scroll loads ~6-10 videos typically, but account for duplicates
        estimated_scrolls = max(10, (target_count // 5) + 10)  # More conservative estimate
        max_scrolls = min(estimated_scrolls, 50)  # Increase cap to 50 for larger limits

        previous_unique_count = 0
        no_change_count = 0

        for i in range(max_scrolls):
            # Scroll down
            await page.evaluate('window.scrollTo(0, document.body.scrollHeight)')

            # Wait for new content to load
            await asyncio.sleep(settings.crawler_scroll_delay / 1000)

            # Check current UNIQUE video count (not just elements)
            content = await page.content()
            pattern = r'/@([\w.-]+)/video/(\d+)'
            matches = re.findall(pattern, content)

            # Count unique URLs
            unique_urls = set()
            for username, video_id in matches:
                unique_urls.add(f"https://www.tiktok.com/@{username}/video/{video_id}")

            current_unique_count = len(unique_urls)

            logger.debug(f"Scroll {i+1}/{max_scrolls}: found {current_unique_count} unique videos")

            # Check if we have enough unique results
            if current_unique_count >= target_count:
                logger.info(f"Reached target: {current_unique_count} unique videos after {i+1} scrolls")
                break

            # Check if no new content loaded (stuck)
            if current_unique_count == previous_unique_count:
                no_change_count += 1
                if no_change_count >= 5:  # Increase patience to 5 scrolls
                    logger.info(f"No new unique videos after 5 scrolls, stopping at {current_unique_count} unique videos")
                    if current_unique_count < target_count:
                        logger.warning(f"TikTok search limit reached: found {current_unique_count}/{target_count} videos")
                        logger.warning(f"This is a TikTok platform limitation - no more results available for this keyword")
                    break
            else:
                no_change_count = 0

            previous_unique_count = current_unique_count

    async def _extract_video_urls(self, page: Page, limit: int) -> List[str]:
        """Extract video URLs from search results page"""
        video_urls = []
        seen_urls = set()

        try:
            # Get page content
            content = await page.content()

            # Primary method: Extract from page HTML using regex
            # This is more reliable than DOM selectors for TikTok search
            logger.debug("Extracting video URLs from page HTML...")

            # Pattern to match TikTok video URLs
            pattern = r'/@([\w.-]+)/video/(\d+)'
            matches = re.findall(pattern, content)

            for username, video_id in matches:
                full_url = f"https://www.tiktok.com/@{username}/video/{video_id}"

                # Deduplicate
                if full_url not in seen_urls:
                    video_urls.append(full_url)
                    seen_urls.add(full_url)
                    logger.debug(f"Found video: {full_url}")

                    if len(video_urls) >= limit:
                        break

            # Fallback method: Try DOM selectors
            if not video_urls:
                logger.debug("Regex method found no URLs, trying DOM selectors...")

                selectors = [
                    'a[href*="/video/"]',
                    'div[class*="DivItemContainer"] a',
                ]

                for selector in selectors:
                    try:
                        links = await page.query_selector_all(selector)

                        for link in links:
                            href = await link.get_attribute('href')
                            if href and '/video/' in href:
                                # Ensure full URL
                                if href.startswith('/'):
                                    full_url = f"https://www.tiktok.com{href}"
                                elif href.startswith('http'):
                                    full_url = href
                                else:
                                    continue

                                # Clean URL (remove query params)
                                clean_url = full_url.split('?')[0]

                                # Validate and deduplicate
                                if extract_video_id(clean_url) and clean_url not in seen_urls:
                                    video_urls.append(clean_url)
                                    seen_urls.add(clean_url)

                                    if len(video_urls) >= limit:
                                        break
                    except Exception as e:
                        logger.debug(f"Error with selector {selector}: {e}")
                        continue

                    if len(video_urls) >= limit:
                        break

        except Exception as e:
            logger.error(f"Error extracting video URLs: {e}")

        logger.info(f"Extracted {len(video_urls)} video URLs")
        return video_urls[:limit]

    async def search_and_get_top_video(self, keyword: str) -> Optional[str]:
        """
        Search for keyword and return the first/top video URL

        Args:
            keyword: Search keyword

        Returns:
            URL of the top video, or None if not found
        """
        videos = await self.search_videos(keyword, limit=1)

        if videos:
            logger.info(f"Found top video for '{keyword}': {videos[0]}")
            return videos[0]
        else:
            logger.warning(f"No videos found for keyword '{keyword}'")
            return None
