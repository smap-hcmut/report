"""
Browser Stealth Setup
Configure Playwright browser to avoid detection
"""
from playwright.async_api import Page


async def setup_stealth_page(page: Page):
    """
    Setup stealth configurations for Playwright page to avoid bot detection

    Args:
        page: Playwright Page object
    """
    # Set realistic viewport
    await page.set_viewport_size({"width": 1920, "height": 1080})

    # Override navigator properties to hide automation
    await page.add_init_script("""
        // 1. Remove navigator.webdriver property (Standard method)
        delete Object.getPrototypeOf(navigator).webdriver;

        // 2. Mock window.chrome (Minimal)
        window.chrome = {
            runtime: {},
            loadTimes: function() {},
            csi: function() {},
            app: {},
        };

        // 3. Mock Permissions Query (Minimal & Safe)
        // Only mock if it doesn't exist or if we strictly need to bypass notification checks
        // Keeping it simple to avoid prototype mismatches
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
                Promise.resolve({ state: Notification.permission }) :
                originalQuery(parameters)
        );
    """)
