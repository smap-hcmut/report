"""
TikTok Comment Scraper - Level 3 Data
Crawl comment data: text, commenter info, timestamp, likes, reply threads
Uses API interception or direct HTTP requests
"""
import asyncio
import json
import httpx
from typing import List, Dict, Optional
from playwright.async_api import Page, Browser
from datetime import datetime

from config import SELECTORS, settings
from utils.logger import logger
from utils.helpers import parse_count, clean_text, try_get_text, smart_delay, extract_video_id
from utils.browser_stealth import setup_stealth_page


class CommentScraper:
    """Scraper for TikTok video comments using API interception"""

    def __init__(self, browser: Browser):
        self.browser = browser
        self.selectors = SELECTORS['comment']
        self.comment_api_data = None  # Store intercepted API data

    async def scrape(self, video_url: str, max_comments: int = 0, full_mode: bool = False) -> List[Dict]:
        """
        Scrape comments from TikTok video

        Args:
            video_url: Full TikTok video URL
            max_comments: Maximum number of comments to scrape (0 = all, default: all)
            full_mode: If True, use browser scroll to get 100% comments (slower but complete)

        Returns:
            List of comment dictionaries
        """
        logger.info(f"Scraping comments from: {video_url} (full_mode: {full_mode})")

        try:
            # Extract video ID
            video_id = extract_video_id(video_url)
            if not video_id:
                logger.error(f"Could not extract video ID from URL: {video_url}")
                return []

            if full_mode:
                # Use browser scroll method for 100% comments
                logger.info("Using FULL MODE: Browser scroll to get 100% comments (slower)")
                comments = await self._fetch_comments_browser_scroll(video_url, max_comments)
            else:
                # Use fast HTTP API method (60-70% comments)
                logger.info("Using FAST MODE: HTTP API for top comments (60-70% coverage)")
                comments = await self._fetch_comments_http(video_id, max_comments)

            logger.info(f"Successfully scraped {len(comments)} comments")
            return comments

        except Exception as e:
            logger.error(f"Error scraping comments: {e}")
            return []

    async def scrape_from_page(self, page: Page, max_comments: int = 100) -> List[Dict]:
        """
        Scrape comments from an already loaded video page using API interception

        Args:
            page: Playwright Page object already on video page
            max_comments: Maximum number of comments to scrape

        Returns:
            List of comment dictionaries
        """
        try:
            # Reset API data
            self.comment_api_data = None

            # Set up API response interceptor
            async def handle_comment_api(response):
                if '/api/comment/list/' in response.url:
                    try:
                        data = await response.json()
                        if data and 'comments' in data:
                            self.comment_api_data = data
                            logger.debug(f"Intercepted comment API with {len(data['comments'])} comments")
                    except Exception as e:
                        logger.debug(f"Error parsing comment API response: {e}")

            page.on('response', handle_comment_api)

            # Scroll to trigger comment API call
            await page.evaluate('window.scrollTo(0, 800)')
            await asyncio.sleep(5)

            # Extract comments from API data
            comments = await self._extract_comments_from_api(max_comments)

            logger.info(f"Extracted {len(comments)} comments from page via API")
            return comments

        except Exception as e:
            logger.error(f"Error scraping comments from page: {e}")
            return []

    async def _extract_comments_from_api(self, max_comments: int, video_id: str = None) -> List[Dict]:
        """
        Extract comment data from intercepted API response

        Args:
            max_comments: Maximum comments to extract (0 = all)
            video_id: Video ID to associate with comments

        Returns:
            List of comment dictionaries
        """
        comments = []

        if not self.comment_api_data:
            logger.warning("No comment API data intercepted")
            return comments

        try:
            api_comments = self.comment_api_data.get('comments', [])

            # Limit comments if needed
            if max_comments > 0:
                api_comments = api_comments[:max_comments]

            for idx, comment_data in enumerate(api_comments):
                try:
                    # Extract user info
                    user = comment_data.get('user', {})
                    commenter_name = user.get('nickname', '') or user.get('unique_id', '')

                    # Extract comment text
                    comment_text = comment_data.get('text', '')

                    # Extract timestamp (create_time is Unix timestamp)
                    create_time = comment_data.get('create_time', 0)
                    timestamp = datetime.fromtimestamp(create_time).isoformat() if create_time else ''

                    # Extract metrics
                    like_count = comment_data.get('digg_count', 0)
                    reply_count = comment_data.get('reply_comment_total', 0)

                    # Generate comment ID
                    comment_id = comment_data.get('cid', f'comment_{idx}')

                    comment = {
                        'comment_id': str(comment_id),
                        'video_id': video_id,  # Add video_id
                        'comment_text': clean_text(comment_text),
                        'commenter_name': clean_text(commenter_name),
                        'timestamp': timestamp,
                        'like_count': like_count,
                        'reply_count': reply_count,
                        'crawled_at': datetime.now().isoformat()
                    }

                    comments.append(comment)

                except Exception as e:
                    logger.debug(f"Error parsing comment {idx}: {e}")
                    continue

            logger.info(f"Extracted {len(comments)} comments from API data")

        except Exception as e:
            logger.error(f"Error extracting comments from API: {e}")

        return comments

    async def _fetch_comments_http(self, video_id: str, max_comments: int = 0) -> List[Dict]:
        """
        Fetch comments directly via HTTP request with pagination (fallback method)

        Args:
            video_id: TikTok video ID
            max_comments: Maximum comments to fetch (0 = all available, default: all)

        Returns:
            List of comment dictionaries
        """
        all_comments = []
        cursor = 0
        has_more = 1
        page_count = 0
        max_pages = 200  # Safety limit to prevent infinite loop (200 pages x 20 = 4000 comments max)

        try:
            url = "https://www.tiktok.com/api/comment/list/"

            logger.debug(f"Fetching comments via HTTP with pagination (max: {max_comments if max_comments > 0 else 'all'})")

            async with httpx.AsyncClient(timeout=30.0) as client:
                while has_more and page_count < max_pages:
                    # Check if we've reached max_comments
                    if max_comments > 0 and len(all_comments) >= max_comments:
                        logger.info(f"Reached max_comments limit: {max_comments}")
                        break

                    params = {
                        'aid': '1988',
                        'aweme_id': video_id,
                        'count': 20,  # TikTok API default page size
                        'cursor': str(cursor)
                    }

                    logger.debug(f"Fetching page {page_count + 1} (cursor: {cursor})")

                    try:
                        response = await client.get(url, params=params)

                        if response.status_code != 200:
                            logger.warning(f"HTTP request failed with status {response.status_code}")
                            break

                        data = response.json()

                        if not data or 'comments' not in data:
                            logger.warning(f"No comments in response")
                            break

                        # Extract comments from this page
                        self.comment_api_data = data
                        page_comments = await self._extract_comments_from_api(0, video_id)  # Pass video_id

                        if not page_comments:
                            logger.debug("No comments extracted from this page, stopping")
                            break

                        all_comments.extend(page_comments)
                        page_count += 1

                        logger.info(f"Page {page_count}: fetched {len(page_comments)} comments (total: {len(all_comments)})")

                        # Check pagination
                        has_more = data.get('has_more', 0)
                        cursor = data.get('cursor', cursor + 20)

                        if not has_more:
                            logger.info("No more comments available")
                            break

                        # Small delay to avoid rate limiting
                        await asyncio.sleep(0.5)

                    except Exception as e:
                        logger.error(f"Error fetching page {page_count + 1}: {e}")
                        break

                # Limit results if max_comments specified
                if max_comments > 0 and len(all_comments) > max_comments:
                    all_comments = all_comments[:max_comments]

                logger.info(f"Fetched total {len(all_comments)} comments via HTTP request ({page_count} pages)")
                return all_comments

        except Exception as e:
            logger.error(f"Error fetching comments via HTTP: {e}")

        return all_comments

    async def _fetch_comments_browser_scroll(self, video_url: str, max_comments: int = 0) -> List[Dict]:
        """
        Fetch ALL comments using browser scroll method (slower but gets 100%)

        Args:
            video_url: TikTok video URL
            max_comments: Maximum comments to fetch (0 = all available)

        Returns:
            List of comment dictionaries
        """
        page = None
        all_comments = []

        try:
            # Create new page
            page = await self.browser.new_page()
            await setup_stealth_page(page)

            logger.info(f"Loading page for full comment crawl: {video_url}")

            # Navigate to video
            await page.goto(video_url, wait_until='domcontentloaded', timeout=60000)
            await asyncio.sleep(3)

            # Scroll to load all comments
            await self._scroll_to_load_comments(page, max_comments)

            # Extract all comments from page
            all_comments = await self._extract_comments(page)

            # Limit if needed
            if max_comments > 0 and len(all_comments) > max_comments:
                all_comments = all_comments[:max_comments]

            logger.info(f"Full mode: Extracted {len(all_comments)} comments via browser scroll")

        except Exception as e:
            logger.error(f"Error in browser scroll method: {e}")

        finally:
            if page:
                await page.close()

        return all_comments

    async def _scroll_to_load_comments(self, page: Page, max_comments: int):
        """
        Scroll comment section to trigger lazy loading of comments

        Args:
            page: Playwright Page object
            max_comments: Maximum comments to load (0 = all)
        """
        logger.debug("Scrolling to load comments...")

        try:
            # Scroll to comment area first
            await page.evaluate('window.scrollTo(0, 800)')
            await asyncio.sleep(3)

            # Wait for skeleton loaders to be replaced with real comments
            logger.debug("Waiting for skeleton loaders to be replaced...")
            await asyncio.sleep(5)  # Additional wait for comments to fully load

            # Find comment section
            comment_section = await page.query_selector('[class*="DivCommentListContainer"]')
            if not comment_section:
                # Alternative selectors
                comment_section = await page.query_selector('[id*="comment"]')

            if not comment_section:
                logger.warning("Could not find comment section")
                return

            previous_count = 0
            no_change_count = 0
            max_attempts = settings.crawler_max_scroll_attempts

            # Try multiple selectors for comment items
            comment_selectors = [
                '[class*="CommentItem"]',
                'div[data-e2e="comment-item"]',
                'div[class*="DivCommentItemContainer"]',
            ]

            for attempt in range(max_attempts):
                # Get current comment count using multiple selectors
                current_count = 0
                for selector in comment_selectors:
                    current_comments = await page.query_selector_all(selector)
                    if len(current_comments) > current_count:
                        current_count = len(current_comments)

                logger.debug(f"Scroll attempt {attempt + 1}/{max_attempts}: {current_count} comments loaded")

                # Check if we've loaded enough comments
                if max_comments > 0 and current_count >= max_comments:
                    logger.debug(f"Reached target of {max_comments} comments")
                    break

                # Check if no new comments loaded
                if current_count == previous_count:
                    no_change_count += 1
                    if no_change_count >= 3:
                        logger.debug("No new comments loaded after 3 attempts, stopping")
                        break
                else:
                    no_change_count = 0

                previous_count = current_count

                # Scroll down in comment section
                await page.evaluate('''
                    () => {
                        const commentSection = document.querySelector('[class*="DivCommentListContainer"]')
                                            || document.querySelector('[id*="comment"]');
                        if (commentSection) {
                            commentSection.scrollTop = commentSection.scrollHeight;
                        } else {
                            window.scrollTo(0, document.body.scrollHeight);
                        }
                    }
                ''')

                # Wait for new comments to load
                await asyncio.sleep(settings.crawler_scroll_delay / 1000)

                # Click "View more comments" button if exists
                try:
                    view_more_button = await page.query_selector(self.selectors['view_more_button'][0])
                    if view_more_button:
                        await view_more_button.click()
                        await asyncio.sleep(1)
                except Exception:
                    pass

        except Exception as e:
            logger.warning(f"Error during comment scrolling: {e}")

    async def _extract_comments(self, page: Page) -> List[Dict]:
        """Extract all comment data from page"""
        comments = []

        try:
            # Find all comment containers
            # Try multiple selectors
            selectors_to_try = [
                '[class*="CommentItem"]',  # New selector found in debug
                'div[data-e2e="comment-item"]',
                'div[class*="DivCommentItemContainer"]',
            ]

            comment_elements = []
            for selector in selectors_to_try:
                comment_elements = await page.query_selector_all(selector)
                if comment_elements:
                    logger.debug(f"Found {len(comment_elements)} comments with selector: {selector}")
                    break

            logger.debug(f"Found {len(comment_elements)} comment elements")

            for idx, comment_element in enumerate(comment_elements):
                try:
                    comment_data = await self._extract_single_comment(comment_element, idx)
                    if comment_data:
                        comments.append(comment_data)
                except Exception as e:
                    logger.debug(f"Error extracting comment {idx}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Error extracting comments: {e}")

        return comments

    async def _extract_single_comment(self, comment_element, index: int) -> Optional[Dict]:
        """Extract data from a single comment element"""

        # Check if this is a skeleton loader
        try:
            html = await comment_element.inner_html()
            if 'Skeleton' in html:
                logger.debug(f"Comment {index} is still a skeleton loader, skipping")
                return None
        except Exception:
            pass

        # Comment text - try multiple approaches
        comment_text = await self._get_element_text(
            comment_element,
            self.selectors['text']
        )

        # Fallback: try p, span tags directly
        if not comment_text:
            for tag in ['p', 'span']:
                try:
                    el = await comment_element.query_selector(tag)
                    if el:
                        text = await el.text_content()
                        if text and len(text) > 5:
                            comment_text = clean_text(text)
                            break
                except Exception:
                    pass

        # Commenter name
        commenter_name = await self._get_element_text(
            comment_element,
            self.selectors['commenter_name']
        )

        # Timestamp
        timestamp = await self._get_element_text(
            comment_element,
            self.selectors['timestamp']
        )

        # Like count
        like_count_text = await self._get_element_text(
            comment_element,
            self.selectors['like_count']
        )

        # Generate comment ID (simple approach)
        comment_id = f"comment_{index}_{hash(comment_text) if comment_text else 0}"

        comment_data = {
            'comment_id': comment_id,
            'comment_text': comment_text,
            'commenter_name': commenter_name,
            'timestamp': timestamp,
            'like_count': parse_count(like_count_text),
            'crawled_at': datetime.now().isoformat()
        }

        return comment_data

    async def _get_element_text(self, parent_element, selectors: List[str]) -> str:
        """Get text from element using multiple selector fallbacks"""
        # Try provided selectors
        for selector in selectors:
            try:
                element = await parent_element.query_selector(selector)
                if element:
                    text = await element.text_content()
                    if text:
                        return clean_text(text)
            except Exception:
                continue

        # Fallback: try to get any text from parent
        try:
            text = await parent_element.text_content()
            if text:
                return clean_text(text[:200])  # Limit length
        except Exception:
            pass

        return ""
