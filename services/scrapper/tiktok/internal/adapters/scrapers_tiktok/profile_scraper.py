"""
TikTok Profile Scraper
Scrapes all videos from a TikTok user profile.
Strategy:
1. Primary: Direct profile page scraping (Scroll & Extract DOM) - Best for getting ALL videos.
2. Fallback: Search with 'from:@username' (via SearchScraper) - Used if primary fails.
"""
import asyncio
import re
import random
from typing import List, Optional, Set, Union
from playwright.async_api import Browser, BrowserContext, Page

from config import settings
from utils.logger import logger
from utils.helpers import extract_username, extract_video_id, smart_delay
from utils.browser_stealth import setup_stealth_page
from .search_scraper import SearchScraper


class ProfileScraper:
    """
    Scraper for TikTok profile pages.
    Implements a hybrid approach: DOM scraping first, then Search fallback.
    Supports optional Playwright REST API mode for remote scraping.
    """

    def __init__(self, browser: Browser, playwright_rest_client=None, use_rest_api: bool = False):
        """
        Initialize ProfileScraper
        
        Args:
            browser: Playwright Browser instance (used for local scraping)
            playwright_rest_client: Optional PlaywrightRestClient for REST API mode
            use_rest_api: Whether to use REST API instead of local browser
        """
        self.browser = browser
        self.search_scraper = SearchScraper(browser)
        self.playwright_rest_client = playwright_rest_client
        self.use_rest_api = use_rest_api

    async def get_profile_videos(
        self,
        profile_url: str,
        limit: Optional[int] = None
    ) -> List[str]:
        """
        Get video URLs from a TikTok profile.
        
        Args:
            profile_url: Full TikTok profile URL (e.g., https://www.tiktok.com/@username)
            limit: Maximum number of video URLs to return (None = all available)

        Returns:
            List of video URLs in chronological order (newest first)
        """
        if limit == 0:
            limit = None

        username = extract_username(profile_url)
        if not username:
            logger.error(f"Could not extract username from URL: {profile_url}")
            return []

        logger.info(f"Scraping profile @{username} (limit: {limit or 'all'})")
        
        # Check if REST API mode is enabled
        if self.use_rest_api and self.playwright_rest_client:
            try:
                logger.info("Using Playwright REST API for profile scraping")
                videos = await self.playwright_rest_client.get_profile_videos(
                    profile_url=profile_url,
                    limit=limit
                )
                if videos:
                    logger.info(f"REST API scraping successful: found {len(videos)} videos")
                    return videos
                else:
                    logger.warning("REST API scraping found 0 videos")
            except Exception as e:
                logger.error(f"REST API scraping failed: {e}")
                logger.warning("Falling back to local browser scraping...")
                # Fall through to local scraping

        # 1. Try Primary Method: DOM Scraping (existing code)
        try:
            videos = await self._scrape_via_dom(profile_url, limit)
            if videos:
                logger.info(f"DOM scraping successful: found {len(videos)} videos")
                return videos
            else:
                logger.warning("DOM scraping found 0 videos, switching to fallback...")
        except Exception as e:
            logger.error(f"DOM scraping failed: {e}")
            logger.warning("Switching to fallback method...")

        # 2. Try Fallback Method: Search
        # logger.warning("DOM scraping failed or found 0 videos. Fallback search is DISABLED by request.")
        return []
        # return await self._scrape_via_search(username, limit)

    async def _scrape_via_dom(self, profile_url: str, limit: Optional[int]) -> List[str]:
        """
        Primary method: Scroll profile page and extract videos from DOM.
        """
        logger.info("Attempting Primary Method: DOM Scraping...")
        
        # Create page based on browser type
        if isinstance(self.browser, BrowserContext):
            # Context already configured
            page = await self.browser.new_page()
        else:
            # Configure new page for Browser
            page = await self.browser.new_page(
                viewport={'width': 1920, 'height': 1080},
                user_agent=settings.crawler_user_agent,
                locale='en-US',
                timezone_id='America/New_York'
            )
        
        # Apply stealth
        await setup_stealth_page(page)
        
        video_urls: List[str] = []
        seen_urls: Set[str] = set()
        
        try:
            # --- Human-like Behavior Start ---
            # 1. Go to Home first to establish session/cookies
            # logger.info("Navigating to TikTok Home first (Human-like behavior)...")
            # await page.goto("https://www.tiktok.com/", wait_until='domcontentloaded', timeout=settings.crawler_timeout)
            # await asyncio.sleep(random.uniform(1, 2))
            
            # # 2. Simulate some interaction (scroll/mouse)
            # # Just a small scroll to trigger events
            # await page.evaluate("window.scrollBy(0, 100)")
            # await asyncio.sleep(random.uniform(1, 2))
            
            # 3. Now navigate to Profile
            logger.info(f"Navigating to Profile: {profile_url}")
            await page.goto(profile_url, wait_until='domcontentloaded', timeout=settings.crawler_timeout)
            await asyncio.sleep(settings.crawler_wait_after_load / 1000)
            # --- Human-like Behavior End ---
            
            # Wait for content to load
            try:
                logger.debug("Waiting for video selectors...")
                # Try multiple selectors
                await page.wait_for_selector(
                    '[data-e2e="user-post-item"], [class*="DivItemContainer"], [data-e2e="user-profile-post"]', 
                    timeout=10000
                )
                logger.info("Found video selector")
            except Exception as e:
                logger.warning(f"Timeout waiting for selectors: {e}")

            # Check if profile exists/loaded
            content = await page.content()
            current_url = page.url
            title = await page.title()
            
            logger.debug(f"Current Page URL: {current_url}")
            logger.debug(f"Page title: {title}")
            logger.debug(f"Content length: {len(content)}")
            
            if "TikTok - Make Your Day" in title and "@" not in title:
                logger.warning("Redirected to Homepage or Login page (Title mismatch)")
            
            has_post_item = "user-post-item" in content
            has_div_container = "DivItemContainer" in content
            logger.debug(f"Has 'user-post-item': {has_post_item}")
            logger.debug(f"Has 'DivItemContainer': {has_div_container}")
            
            if not has_post_item and not has_div_container:
                logger.warning("Profile page might be empty or blocked (no video containers found)")
                # Dump HTML for debugging
                # with open("debug_dom_fail.html", "w", encoding="utf-8") as f:
                #     f.write(content)
                # logger.info("Dumped failed page content to debug_dom_fail.html")

            # Scroll and extract
            max_scrolls = 200 if not limit else max(20, (limit // 10) + 5)
            no_change_count = 0
            
            for i in range(max_scrolls):
                # Extract current visible videos
                new_urls = await self._extract_urls_from_page(page)
                
                added_count = 0
                for url in new_urls:
                    if url not in seen_urls:
                        # Double check it belongs to user (sometimes recommendations appear)
                        if f"/@{extract_username(profile_url)}/" in url:
                            seen_urls.add(url)
                            video_urls.append(url)
                            added_count += 1
                
                if added_count > 0:
                    logger.debug(f"Scroll {i+1}: Found {added_count} new videos (Total: {len(video_urls)})")
                    no_change_count = 0
                else:
                    no_change_count += 1
                
                if limit and len(video_urls) >= limit:
                    logger.info(f"Reached limit of {limit} videos")
                    break
                    
                if no_change_count >= 5:
                    logger.info(f"No new videos after 5 scrolls. Stopping.")
                    break
                
                # Scroll down
                await page.evaluate('window.scrollTo(0, document.body.scrollHeight)')
                
                # Randomize wait time to mimic human behavior and allow content load
                # User requested longer wait time for better consistency
                delay = random.uniform(2, 3)
                logger.debug(f"Waiting {delay:.2f}s after scroll...")
                await asyncio.sleep(delay)
                
        except Exception as e:
            logger.error(f"Error in DOM scraping: {e}")
            raise e
        finally:
            await page.close()
            
        return video_urls[:limit] if limit else video_urls

    async def _extract_urls_from_page(self, page: Page) -> List[str]:
        """Extract video URLs from current page state using Regex + Selectors"""
        urls = []
        
        try:
            # 1. Regex (Fastest & Most reliable for text content)
            content = await page.content()
            # Matches /@user/video/id and /@user/photo/id
            pattern = r'https://www\.tiktok\.com/@[\w.-]+/(?:video|photo)/\d+'
            matches = re.findall(pattern, content)
            urls.extend(matches)
            
            # 2. Selectors (For dynamically loaded elements that might not be in initial HTML snapshot)
            # Common selectors for TikTok video links
            selectors = [
                'a[href*="/video/"]',
                'a[href*="/photo/"]',
                '[data-e2e="user-post-item"] a',
            ]
            
            for selector in selectors:
                elements = await page.query_selector_all(selector)
                for el in elements:
                    href = await el.get_attribute('href')
                    if href:
                        if href.startswith('/'):
                            href = f"https://www.tiktok.com{href}"
                        
                        if '/video/' in href or '/photo/' in href:
                             urls.append(href.split('?')[0]) # Remove query params

        except Exception as e:
            logger.debug(f"Extraction error: {e}")
            
        return list(set(urls)) # Deduplicate local batch

    async def _scrape_via_search(self, username: str, limit: Optional[int]) -> List[str]:
        """
        Fallback method: Use SearchScraper to find videos.
        """
        logger.info("Attempting Fallback Method: Search Scraping...")
        
        search_query = f"@{username}"
        # Request more to account for filtering
        search_limit = (limit * 3) if limit else 100
        
        video_urls = await self.search_scraper.search_videos(
            keyword=search_query,
            limit=search_limit,
            sort_by='recent'
        )
        
        # Filter
        filtered_urls = []
        target_pattern = f"/@{username}/"
        
        for url in video_urls:
            if target_pattern in url:
                filtered_urls.append(url)
                if limit and len(filtered_urls) >= limit:
                    break
                    
        logger.info(f"Fallback search found {len(filtered_urls)} videos")
        return filtered_urls