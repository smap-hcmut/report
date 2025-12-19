"""
HTTP Client for Playwright REST API
Provides interface to call the Playwright REST service for profile scraping
"""
import httpx
from typing import List, Optional
from utils.logger import logger


class PlaywrightRestClient:
    """Client for interacting with Playwright REST API service"""
    
    def __init__(self, base_url: str, timeout: int = 300):
        """
        Initialize Playwright REST API client
        
        Args:
            base_url: Base URL of the Playwright REST API (e.g., http://localhost:8001)
            timeout: Request timeout in seconds (default: 300s for long-running scrapes)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        
    async def get_profile_videos(
        self, 
        profile_url: str, 
        limit: Optional[int] = None
    ) -> List[str]:
        """
        Get video URLs from a TikTok profile via REST API
        
        Args:
            profile_url: Full TikTok profile URL (e.g., https://www.tiktok.com/@username)
            limit: Maximum number of video URLs to return (None = all available)
            
        Returns:
            List of video URLs
            
        Raises:
            httpx.HTTPError: If the API request fails
        """
        endpoint = f"{self.base_url}/v1/tiktok/profile/scrape"
        
        payload = {
            "url": profile_url,
            "limit": limit
        }
        
        logger.info(f"Calling Playwright REST API: {endpoint} with payload: {payload}")
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                response = await client.post(endpoint, json=payload)
                response.raise_for_status()
                
                data = response.json()
                videos = data.get("videos", [])
                
                logger.info(f"Playwright REST API returned {len(videos)} videos")
                return videos
                
            except httpx.HTTPError as e:
                logger.error(f"Playwright REST API request failed: {e}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error calling Playwright REST API: {e}")
                raise
