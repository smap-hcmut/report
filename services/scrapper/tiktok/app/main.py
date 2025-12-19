"""
Main Entry Point - Clean Architecture Worker
Run this file to start the TikTok crawler worker

Usage:
    cd f:/SMAP/smap-ai-internal/scrapper/tiktok
    python app/main.py
    # or
    python -m app.main
"""
import asyncio
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from app.worker_service import main

if __name__ == "__main__":
    asyncio.run(main())
