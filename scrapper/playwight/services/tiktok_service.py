import asyncio
import random
import re
from typing import List, Optional, Set
from playwright.async_api import BrowserContext, Page

# Logger setup (using standard logging or custom logger)
import logging
logger = logging.getLogger(__name__)

class TikTokService:
    def __init__(self):
        pass

    async def get_profile_videos(self, browser_context: BrowserContext, profile_url: str, limit: Optional[int] = None) -> List[str]:
        """
        Scrapes video URLs from a TikTok profile using a persistent browser context.
        """
        page = await browser_context.new_page()
        
        # Apply Stealth Settings (Critical for avoiding detection)
        await self._setup_stealth_page(page)
        
        video_urls: List[str] = []
        seen_urls: Set[str] = set()
        
        try:
            # 1. Navigation with Human-like delays
            logger.info(f"Navigating to Profile: {profile_url}")
            await page.goto(profile_url, wait_until='domcontentloaded', timeout=30000)
            await asyncio.sleep(random.uniform(2, 4)) # Random delay after load

            # 2. Wait for Content
            try:
                # Wait for video containers
                await page.wait_for_selector(
                    '[data-e2e="user-post-item"], [class*="DivItemContainer"], [data-e2e="user-profile-post"]', 
                    timeout=20000
                )
            except Exception as e:
                logger.warning(f"Timeout waiting for selectors: {e}")

            # 3. Check for Redirects or Empty Profile (Robustness)
            content = await page.content()
            title = await page.title()
            
            if "TikTok - Make Your Day" in title and "@" not in title:
                logger.warning("Redirected to Homepage or Login page (Title mismatch)")
            
            if "user-post-item" not in content and "DivItemContainer" not in content:
                logger.warning("Profile page might be empty or blocked (no video containers found)")

            # 4. Scroll and Extract Loop
            max_scrolls = 200 if not limit else max(20, (limit // 10) + 5)
            no_change_count = 0
            
            for i in range(max_scrolls):
                # Extract URLs from current view
                new_urls = await self._extract_urls_from_page(page)
                
                added_count = 0
                for url in new_urls:
                    if url not in seen_urls:
                        # Validate URL belongs to user
                        username = self._extract_username(profile_url)
                        if username and f"/@{username}/" in url:
                            seen_urls.add(url)
                            video_urls.append(url)
                            added_count += 1
                
                if added_count > 0:
                    no_change_count = 0
                else:
                    no_change_count += 1
                
                # Check limits
                if limit and len(video_urls) >= limit:
                    break
                
                if no_change_count >= 5:
                    logger.info("No new videos after 5 scrolls. Stopping.")
                    break
                
                # Scroll Down
                await page.evaluate('window.scrollTo(0, document.body.scrollHeight)')
                
                # Random Delay between scrolls
                await asyncio.sleep(random.uniform(3, 4))
                
        except Exception as e:
            logger.error(f"Error in scraping: {e}")
            raise e
        finally:
            await page.close()
            
        return video_urls[:limit] if limit else video_urls

    async def _extract_urls_from_page(self, page: Page) -> List[str]:
        """Extracts video URLs using Regex and DOM Selectors"""
        urls = []
        try:
            # Method A: Regex on HTML content (Fast & Reliable)
            content = await page.content()
            pattern = r'https://www\.tiktok\.com/@[\w.-]+/(?:video|photo)/\d+'
            matches = re.findall(pattern, content)
            urls.extend(matches)
            
            # Method B: DOM Selectors (For dynamic elements)
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
                            urls.append(href.split('?')[0])
                            
        except Exception as e:
            logger.debug(f"Extraction error: {e}")
            
        return list(set(urls))

    async def _setup_stealth_page(self, page: Page):
        """Applies stealth scripts to the page"""
        await page.set_viewport_size({"width": 1920, "height": 1080})
        await page.add_init_script("""
            delete Object.getPrototypeOf(navigator).webdriver;
            window.chrome = { runtime: {}, loadTimes: function() {}, csi: function() {}, app: {} };
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                    Promise.resolve({ state: Notification.permission }) :
                    originalQuery(parameters)
            );
        """)

    def _extract_username(self, url: str) -> Optional[str]:
        match = re.search(r'/@([\w.-]+)', url)
        return match.group(1) if match else None
