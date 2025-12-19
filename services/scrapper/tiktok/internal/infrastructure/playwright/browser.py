"""
Playwright Browser Infrastructure
Shared browser management utilities for Playwright-based scrapers
"""
from playwright.async_api import async_playwright, Browser, BrowserContext, Page
from typing import Optional
from utils.browser_stealth import setup_stealth_page


class BrowserManager:
    """
    Manages Playwright browser instances with stealth mode

    This is a shared utility that all Playwright-based scrapers can use
    to get properly configured browser instances.
    """

    def __init__(self, headless: bool = True):
        self.headless = headless
        self.playwright = None
        self.browser: Optional[Browser] = None

    async def start(self):
        """Start Playwright and launch browser"""
        self.playwright = await async_playwright().start()
        self.browser = await self.playwright.chromium.launch(
            headless=self.headless,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--no-sandbox',
                '--disable-setuid-sandbox',
            ]
        )

    async def create_context(self) -> BrowserContext:
        """Create a new browser context with stealth settings"""
        if not self.browser:
            await self.start()

        context = await self.browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )
        return context

    async def create_stealth_page(self) -> Page:
        """Create a new page with stealth mode enabled"""
        context = await self.create_context()
        page = await context.new_page()
        await setup_stealth_page(page)
        return page

    async def close(self):
        """Close browser and cleanup"""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()


# Async context manager for easy usage
class browser_session:
    """
    Context manager for browser sessions

    Usage:
        async with browser_session(headless=True) as page:
            await page.goto('https://www.tiktok.com')
            # ... do scraping
    """

    def __init__(self, headless: bool = True):
        self.manager = BrowserManager(headless=headless)
        self.page: Optional[Page] = None

    async def __aenter__(self) -> Page:
        self.page = await self.manager.create_stealth_page()
        return self.page

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.page:
            await self.page.close()
        await self.manager.close()
