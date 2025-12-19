from fastapi import APIRouter, HTTPException
from playwright.async_api import async_playwright, BrowserContext
from typing import Optional
import sys
import asyncio

from models.payloads import ProfileScrapeRequest, ProfileScrapeResponse
from services.tiktok_service import TikTokService
from core.config import settings

import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# Global browser context (initialized at startup)
_playwright = None
_browser_context: Optional[BrowserContext] = None


async def init_browser():
    """Initialize global browser context at startup"""
    global _playwright, _browser_context

    logger.info("Initializing global browser context...")

    _playwright = await async_playwright().start()
    _browser_context = await _playwright.chromium.launch_persistent_context(
        user_data_dir="/srv/playwright_api/tmp",
        headless=settings.PLAYWRIGHT_HEADLESS,
        viewport={"width": 1920, "height": 1080},
        user_agent=settings.CRAWLER_USER_AGENT,
        locale="en-US",
        timezone_id="America/New_York",
        args=[
            "--disable-blink-features=AutomationControlled",
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-setuid-sandbox",
            "--disable-background-timer-throttling",
            "--disable-backgrounding-occluded-windows",
            "--disable-renderer-backgrounding",
            "--disable-features=TranslateUI",
            "--disable-ipc-flooding-protection",
            "--disable-crash-reporter",
            "--disable-breakpad",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-extensions",
            "--disable-plugins",
            "--disable-default-apps",
            "--single-process",
        ],
    )
    logger.info("Browser context initialized successfully")


async def close_browser():
    """Close global browser context at shutdown"""
    global _playwright, _browser_context

    logger.info("Closing browser context...")
    if _browser_context:
        await _browser_context.close()
    if _playwright:
        await _playwright.stop()
    logger.info("Browser context closed")


@router.post("/v1/tiktok/profile/scrape", response_model=ProfileScrapeResponse)
async def scrape_tiktok_profile(request: ProfileScrapeRequest) -> ProfileScrapeResponse:
    """Scrape TikTok profile for video URLs"""
    logger.info(f"Received request to scrape TikTok profile: {request.url}")

    if not _browser_context:
        raise HTTPException(status_code=503, detail="Browser context not initialized")

    try:
        service = TikTokService()
        videos = await service.get_profile_videos(
            browser_context=_browser_context,
            profile_url=request.url,
            limit=request.limit,
        )
        logger.info(f"Successfully scraped {len(videos)} videos from {request.url}")
        return ProfileScrapeResponse(videos=videos)
    except Exception as e:
        logger.error(f"Error scraping TikTok profile {request.url}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
