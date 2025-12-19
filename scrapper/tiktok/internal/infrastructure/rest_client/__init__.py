"""
REST Client Package
Contains HTTP clients for external REST API services
"""
from .playwright_rest_client import PlaywrightRestClient
from .speech2text_rest_client import Speech2TextRestClient

__all__ = [
    "PlaywrightRestClient",
    "Speech2TextRestClient",
]
