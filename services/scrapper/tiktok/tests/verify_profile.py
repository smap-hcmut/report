import asyncio
import logging
from playwright.async_api import async_playwright
from internal.adapters.scrapers_tiktok.profile_scraper import ProfileScraper
from utils.logger import logger

# Set log level to DEBUG
logger.setLevel(logging.DEBUG)
# Add file handler
# file_handler = logging.FileHandler("verify_log.txt", mode='w', encoding='utf-8')
# file_handler.setLevel(logging.DEBUG)
# formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
# file_handler.setFormatter(formatter)
# logger.addHandler(file_handler)

for handler in logger.handlers:
    handler.setLevel(logging.DEBUG)

async def test_scraper():
    # Ensure tmp directory exists
    import os
    os.makedirs("tmp/tiktok_user_data", exist_ok=True)

    from config import settings

    # Initialize REST API client if enabled
    playwright_rest_client = "http://localhost:8001"
    use_rest_api = True
    
    if True:
        logger.info(f"REST API mode enabled: {settings.playwright_rest_api_url}")
        from internal.infrastructure.rest_client import PlaywrightRestClient
        playwright_rest_client = PlaywrightRestClient(
            base_url="http://localhost:8001",
            timeout=3000
        )
        use_rest_api = True
    if use_rest_api:
        logger.info("Using REST API mode - skipping local browser launch")
        scraper = ProfileScraper(
            browser=None, # Browser not needed for REST API mode
            playwright_rest_client=playwright_rest_client,
            use_rest_api=use_rest_api
        )
        
        # Test with a normal user profile (official accounts might behave differently)
        url = "https://www.tiktok.com/@haykhocnhe860"
        logger.info(f"Testing scraper with {url}")
        
        try:
            # Now test the scraper
            videos = await scraper.get_profile_videos(url, limit=10)
            
            print(f"\n{'='*60}")
            print(f"Found {len(videos)} videos:")
            for i, v in enumerate(videos, 1):
                print(f"{i}. {v}")
            
            if len(videos) > 0:
                print(f"\n✅ Test PASSED! Found {len(videos)} videos")
            else:
                print(f"\n⚠️ Test found 0 videos - check debug files for details")
        except Exception as e:
            print(f"Error during scraping: {e}")
            
    else:
        logger.info("Using local browser mode")
        async with async_playwright() as p:
            # Use persistent context for real-user behavior (cookies, history)
            # Note: headless=False is preferred for TikTok to avoid detection
            browser = await p.chromium.launch_persistent_context(
                user_data_dir="tmp/",
                headless=False,
                viewport={'width': 1920, 'height': 1080},
                user_agent=settings.crawler_user_agent,
                locale='en-US',
                timezone_id='America/New_York',
                args=["--disable-blink-features=AutomationControlled"] # Additional stealth flag
            )
            
            scraper = ProfileScraper(
                browser=browser,
                playwright_rest_client=playwright_rest_client,
                use_rest_api=use_rest_api
            )
            
            # Test with a normal user profile (official accounts might behave differently)
            url = "https://www.tiktok.com/@haykhocnhe860"
            logger.info(f"Testing scraper with {url}")
            
            try:
                # Now test the scraper
                videos = await scraper.get_profile_videos(url, limit=0)
                
                print(f"\n{'='*60}")
                print(f"Found {len(videos)} videos:")
                for i, v in enumerate(videos, 1):
                    print(f"{i}. {v}")
                
                if len(videos) > 0:
                    print(f"\n✅ Test PASSED! Found {len(videos)} videos")
                else:
                    print(f"\n⚠️ Test found 0 videos - check debug files for details")
            finally:
                await browser.close()

if __name__ == "__main__":
    try:
        asyncio.run(test_scraper())
    except Exception as e:
        print(f"Error: {e}")
