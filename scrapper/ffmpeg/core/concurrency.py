import asyncio

from .config import get_settings


_settings = get_settings()
semaphore = asyncio.Semaphore(_settings.max_concurrent_jobs)


async def with_semaphore():
    async with semaphore:
        yield
