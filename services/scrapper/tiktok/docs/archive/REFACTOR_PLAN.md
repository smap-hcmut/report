# TikTok Scraper Refactoring Plan

**Last Updated:** 2025-10-31
**Status:** Planning Complete - Ready for Implementation

---

## 📋 Executive Summary

Complete refactoring of TikTok scraper to Clean Architecture + adding MP3/MP4 media download feature.

**Key Decisions Made:**
- ✅ Audio extraction: Try TikTok audio URL first, fallback to ffmpeg
- ✅ Migration: Complete restructure (not gradual)
- ✅ Download mode: Optional flag in existing tasks (`download_media=true`)
- ✅ Reference code: Test and verify TypeScript approach first

---

## 🏗️ Target Architecture

### New Folder Structure
```
scrapper/tiktok/src/
├── app/
│   ├── main.py              # New entry point
│   ├── bootstrap.py         # Dependency injection
│   └── worker_service.py    # Worker orchestration
│
├── application/              # Use cases / orchestration
│   ├── crawler_service.py   # Main crawl orchestration
│   ├── task_service.py      # Task handling
│   └── interfaces.py        # Abstract interfaces
│
├── domain/                   # Entities and business rules
│   ├── entities/
│   │   ├── video.py         # Video entity (with media fields)
│   │   ├── creator.py       # Creator entity
│   │   └── comment.py       # Comment entity
│   └── value_objects/
│       └── metrics.py       # Metrics value object
│
├── internal/
│   ├── adapters/
│   │   ├── repository_mongo.py      # MongoDB adapter
│   │   ├── queue_rabbitmq.py        # RabbitMQ adapter
│   │   └── scrapers_tiktok/
│   │       ├── video_api.py         # Video scraper
│   │       ├── creator_api.py       # Creator scraper
│   │       ├── search_scraper.py    # Search scraper
│   │       ├── comment_scraper.py   # Comment scraper
│   │       └── media_downloader.py  # **NEW** Media download
│   └── infrastructure/
│       ├── mongo/                   # MongoDB helpers
│       ├── rabbitmq/                # RabbitMQ helpers
│       └── playwright/              # Playwright helpers
│
├── config/
│   ├── __init__.py
│   └── settings.py          # Updated with media settings
│
├── utils/
│   ├── logger.py
│   ├── helpers.py
│   ├── browser_stealth.py
│   └── io_utils.py          # **NEW** File I/O utilities
│
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
```

---

## 🔍 Key Findings from Code Analysis

### Current Python Implementation
- **Video scraping:** HTML parsing (fast, no API signature needed)
- **Data source:** Extracts from `__UNIVERSAL_DATA_FOR_REHYDRATION__`, `__NEXT_DATA__`, or `SIGI_STATE`
- **Structure:** itemStruct contains all video metadata
- **Current fields extracted:** video_id, description, stats, hashtags, duration, creator_username
- **NOT extracted yet:** video download URLs (downloadAddr, playAddr)

### TypeScript Reference (src/core/TikTok.ts)
**Important URLs found in TikTok data:**
```typescript
videoUrl: string                  // Video with watermark
videoUrlNoWaterMark?: string      // Video without watermark (older videos only)
musicMeta: {
  playUrl: string                 // **AUDIO URL** - Direct music/audio stream
}
video: {
  downloadAddr: string            // Video download URL
  playAddr: string                // Video play URL (alternative)
}
```

**Download implementation (Downloader.ts):**
- Uses `videoUrlNoWaterMark` if available, else `videoUrl`
- Downloads to buffer with streaming
- Saves as `.mp4` files
- Supports proxy and progress bars

### Audio Extraction Strategy
**Option 1: TikTok Audio URL (PREFERRED)**
- Source: `music.playUrl` from itemStruct
- Format: Usually MP3 or AAC
- Pros: Direct download, fast, no conversion needed
- Cons: May not always be available

**Option 2: FFmpeg Extraction (FALLBACK)**
- Download MP4 → Extract audio with ffmpeg
- Command: `ffmpeg -i video.mp4 -vn -acodec libmp3lame -q:a 2 audio.mp3`
- Pros: Always works if video is downloadable
- Cons: Requires ffmpeg installation, slower

---

## 📝 Implementation Phases

### ✅ Phase 0: Planning (COMPLETED)
- [x] Analyzed current codebase
- [x] Reviewed TypeScript reference
- [x] Asked clarifying questions
- [x] Created detailed plan

### ✅ Phase 1: Verify Reference Implementation (COMPLETED - 30 min)

**Status:** HIGHLY SUCCESSFUL ✅

**Key Findings:**
- ✅ TikTok provides direct video download URLs (`downloadAddr`, `playAddr`)
- ✅ TikTok provides direct audio download URLs (`music.playUrl`)
- ✅ **IMPORTANT:** Audio is already in MP3 format (audio/mpeg)!
- ✅ Both URLs are accessible and working
- ✅ No API signature needed (HTML parsing works)

**Results:**
```
Video URL: https://v16-webapp-prime.tiktok.com/...
  - Content-Type: video/mp4
  - Size: ~4.4 MB
  - Status: HTTP 200 ✅

Audio URL: https://v77.tiktokcdn.com/...
  - Content-Type: audio/mpeg (MP3!)
  - Size: ~294 KB
  - Status: HTTP 200 ✅
```

**See detailed findings:** `PHASE1_FINDINGS.md`

**Implementation Impact:**
- **Simpler than planned:** Audio is already MP3, no ffmpeg needed for primary use case!
- **Ffmpeg is now optional:** Only needed as fallback (rare cases)
- **Ready to proceed:** All assumptions validated

### Phase 2: Create Folder Structure (1 hour) - NEXT
**Goal:** Test if TypeScript download approach still works

**Tasks:**
1. Inspect itemStruct data structure from current Python scraper
2. Check if these fields exist:
   - `video.downloadAddr` or `video.playAddr`
   - `music.playUrl`
3. Test downloading a video using extracted URL
4. Test if audio URL works directly
5. Document findings

**Files to check:**
- `core/video_api.py` - Modify `_parse_item_struct()` to log full video object
- Create test script to verify URL accessibility

### Phase 2: Create Folder Structure (1 hour)
**Goal:** Set up Clean Architecture folders

**Tasks:**
1. Create all new directories as shown in structure above
2. Add `__init__.py` to all packages
3. Move old code to `_old/` backup folder (for reference)
4. Update `.gitignore` if needed

### Phase 3: Domain Layer (1 hour)
**Goal:** Create business entities with proper validation

**Tasks:**
1. **domain/entities/video.py**
   ```python
   from pydantic import BaseModel, Field
   from typing import Optional
   from datetime import datetime

   class Video(BaseModel):
       # Existing fields from VideoModel
       video_id: str
       url: str
       description: Optional[str]
       # ... other fields ...

       # NEW: Media download fields
       media_path: Optional[str] = None
       media_type: Optional[str] = None  # "audio" or "video"
       media_downloaded_at: Optional[datetime] = None

       # URLs for download (not stored in DB)
       video_download_url: Optional[str] = None
       audio_url: Optional[str] = None
   ```

2. **domain/entities/creator.py** - Move from database/models.py
3. **domain/entities/comment.py** - Move from database/models.py
4. **domain/value_objects/metrics.py** - Extract metrics logic

### Phase 4: Application Layer (2 hours)
**Goal:** Define use cases and interfaces

**Tasks:**
1. **application/interfaces.py**
   ```python
   from abc import ABC, abstractmethod
   from typing import List, Optional
   from domain.entities import Video, Creator, Comment

   class IVideoRepository(ABC):
       @abstractmethod
       async def upsert_video(self, video: Video) -> bool: ...

   class IMediaDownloader(ABC):
       @abstractmethod
       async def download_media(
           self,
           video: Video,
           media_type: str,
           save_dir: str
       ) -> Optional[str]: ...
   ```

2. **application/crawler_service.py**
   ```python
   class CrawlerService:
       def __init__(
           self,
           video_repo: IVideoRepository,
           media_downloader: IMediaDownloader,
           # ... other dependencies
       ):
           ...

       async def fetch_video_and_media(
           self,
           url: str,
           download_media: bool = False,
           media_type: str = "audio",
           include_comments: bool = True,
           include_creator: bool = True
       ) -> CrawlResult:
           # 1. Scrape video data
           # 2. Optionally download media
           # 3. Save to repository
           # 4. Return result
   ```

3. **application/task_service.py** - Handle RabbitMQ task types

### Phase 5: Media Downloader Implementation (3 hours)
**Goal:** Core media download functionality

**Create: internal/adapters/scrapers_tiktok/media_downloader.py**

```python
import aiohttp
import aiofiles
import asyncio
from pathlib import Path
from typing import Optional, Literal, Tuple
from utils.logger import logger
from config import settings

class MediaDownloader:
    """
    Download TikTok video/audio media

    Strategy:
    1. For audio: Try music.playUrl first
    2. If no audio URL: Download video → extract with ffmpeg
    3. For video: Use downloadAddr or playAddr
    """

    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None

    async def download_media(
        self,
        video_data: dict,
        media_type: Literal["video", "audio"],
        save_dir: str
    ) -> Tuple[Optional[Path], str]:
        """
        Download media and return (path, actual_type)

        Args:
            video_data: Video data dict with URLs
            media_type: "video" or "audio"
            save_dir: Directory to save file

        Returns:
            (file_path, actual_media_type) or (None, "failed")
        """
        video_id = video_data.get("video_id")

        if media_type == "audio":
            # Try direct audio URL first
            audio_url = self._extract_audio_url(video_data)
            if audio_url:
                path = await self._download_audio_direct(
                    audio_url, video_id, save_dir
                )
                if path:
                    return (path, "audio")

            # Fallback: Download video and extract audio
            if settings.MEDIA_ENABLE_FFMPEG:
                video_url = self._extract_video_url(video_data)
                if video_url:
                    path = await self._download_and_extract_audio(
                        video_url, video_id, save_dir
                    )
                    if path:
                        return (path, "audio")

        elif media_type == "video":
            video_url = self._extract_video_url(video_data)
            if video_url:
                path = await self._download_video(
                    video_url, video_id, save_dir
                )
                if path:
                    return (path, "video")

        return (None, "failed")

    def _extract_audio_url(self, video_data: dict) -> Optional[str]:
        """Extract audio URL from music metadata"""
        # music.playUrl
        return video_data.get("music", {}).get("playUrl")

    def _extract_video_url(self, video_data: dict) -> Optional[str]:
        """Extract video download URL"""
        # Try downloadAddr first, then playAddr
        video_info = video_data.get("video", {})
        return video_info.get("downloadAddr") or video_info.get("playAddr")

    async def _download_audio_direct(
        self, url: str, video_id: str, save_dir: str
    ) -> Optional[Path]:
        """Download audio file directly"""
        # Implementation: async streaming download
        pass

    async def _download_video(
        self, url: str, video_id: str, save_dir: str
    ) -> Optional[Path]:
        """Download video file"""
        # Implementation: async streaming download
        pass

    async def _download_and_extract_audio(
        self, video_url: str, video_id: str, save_dir: str
    ) -> Optional[Path]:
        """Download video and extract audio with ffmpeg"""
        # 1. Download video to temp
        # 2. Run ffmpeg to extract audio
        # 3. Delete temp video
        # 4. Return audio path
        pass
```

**Key implementation details:**
- Use `aiohttp.ClientSession` for async HTTP
- Stream downloads in chunks (don't load entire file to memory)
- Use `aiofiles` for async file writing
- For ffmpeg: Use `asyncio.create_subprocess_exec()`
- Add retry logic (3 attempts with exponential backoff)
- Progress logging for large files

### Phase 6: Infrastructure Adapters (2 hours)
**Goal:** Migrate existing code to new structure

**Tasks:**
1. Migrate `database/repository.py` → `internal/adapters/repository_mongo.py`
   - Implement `IVideoRepository` interface
   - Add media fields to upsert logic
   - Update to use domain entities

2. Migrate `message_queue/` → `internal/adapters/queue_rabbitmq.py`
   - Implement `ITaskQueue` interface
   - Update to use application services

3. Migrate `core/` → `internal/adapters/scrapers_tiktok/`
   - Update `video_api.py` to extract download URLs:
     ```python
     # In _parse_item_struct():
     video_info = item_struct.get('video', {})
     video_download_url = video_info.get('downloadAddr') or video_info.get('playAddr')

     music = item_struct.get('music', {})
     audio_url = music.get('playUrl')

     video_data = {
         # ... existing fields ...
         'video_download_url': video_download_url,
         'audio_url': audio_url,
     }
     ```

### Phase 7: Configuration & Utils (1 hour)
**Goal:** Add new configs and utilities

**Tasks:**
1. **Update config/settings.py:**
   ```python
   class Settings(BaseSettings):
       # ... existing settings ...

       # Media Download Settings
       media_download_dir: str = "./downloads"
       media_default_type: str = "audio"  # "audio" or "video"
       media_enable_ffmpeg: bool = True
       media_ffmpeg_path: str = "ffmpeg"  # or full path
       media_max_file_size_mb: int = 500
       media_download_timeout: int = 300  # seconds
   ```

2. **Create utils/io_utils.py:**
   ```python
   import re
   from pathlib import Path

   def sanitize_filename(video_id: str, extension: str) -> str:
       """Sanitize video ID and create safe filename"""
       safe_id = re.sub(r'[^a-zA-Z0-9_-]', '', video_id)
       return f"{safe_id}.{extension}"

   async def ensure_dir_exists(path: str) -> Path:
       """Ensure directory exists, create if not"""
       dir_path = Path(path)
       dir_path.mkdir(parents=True, exist_ok=True)
       return dir_path
   ```

### Phase 8: Worker Integration (2 hours)
**Goal:** Wire everything together

**Tasks:**
1. **Create app/bootstrap.py:**
   ```python
   # Dependency injection setup
   from internal.adapters.repository_mongo import MongoRepository
   from internal.adapters.scrapers_tiktok.media_downloader import MediaDownloader
   from application.crawler_service import CrawlerService

   async def bootstrap():
       # Initialize all dependencies
       mongo_repo = MongoRepository()
       await mongo_repo.connect()

       media_downloader = MediaDownloader()

       crawler_service = CrawlerService(
           video_repo=mongo_repo,
           media_downloader=media_downloader,
           # ... other deps
       )

       return {
           'crawler_service': crawler_service,
           'mongo_repo': mongo_repo,
           # ...
       }
   ```

2. **Create app/worker_service.py** - Worker orchestration
3. **Create app/main.py** - New entry point

### Phase 9: Message Queue Updates (1 hour)
**Goal:** Add download_media flag support

**Update payload structure for all 3 task types:**

```json
{
  "task_type": "crawl_links",
  "payload": {
    "video_urls": ["https://www.tiktok.com/@user/video/123"],
    "include_comments": true,
    "include_creator": true,
    "max_comments": 0,
    "use_concurrent": true,

    // NEW FIELDS
    "download_media": true,         // Enable media download
    "media_type": "audio"            // "audio" or "video"
  },
  "job_id": "uuid-123"
}
```

### Phase 10: Testing (2 hours)
**Goal:** Comprehensive testing

**Test Plan:**
1. **Unit Tests**
   - `test_media_downloader.py`
     - Test URL extraction
     - Test filename sanitization
     - Mock HTTP downloads
     - Test ffmpeg fallback logic

2. **Integration Tests**
   - Test full crawl flow with download_media=true
   - Verify files saved to correct location
   - Verify MongoDB has media fields populated
   - Test both audio and video downloads

3. **E2E Tests**
   - Test all 3 task types with media download
   - Test error handling (ffmpeg missing, download fails)
   - Test concurrent downloads

### Phase 11: Documentation (1 hour)
**Goal:** Update all docs

**Tasks:**
1. Update `README.md`
2. Create `docs/ARCHITECTURE.md`
3. Create `docs/MEDIA_DOWNLOAD.md`
4. Add examples to message queue docs

---

## 🔧 Dependencies to Add

Add to `requirements.txt`:
```txt
# Existing dependencies
playwright>=1.40.0
httpx>=0.25.0
motor>=3.3.0
aio-pika>=9.3.0
pydantic>=2.5.0
pydantic-settings>=2.1.0

# NEW: For media download
aiohttp>=3.9.0
aiofiles>=23.2.0
ffmpeg-python>=0.2.0  # Optional, for audio extraction
```

Install ffmpeg system-wide:
```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Windows
choco install ffmpeg
```

---

## 📊 Progress Tracking

### Current Status: Phase 1 Complete ✅ - Ready for Phase 2

| Phase | Status | Estimated Time | Notes |
|-------|--------|----------------|-------|
| 0. Planning | ✅ Complete | - | All decisions made |
| 1. Verify Reference | ✅ Complete | 30 min | Audio already MP3! |
| 2. Folder Structure | ⏸️ Pending | 1 hour | Create directories |
| 3. Domain Layer | ⏸️ Pending | 1 hour | Entities & VOs |
| 4. Application Layer | ⏸️ Pending | 2 hours | Services & interfaces |
| 5. Media Downloader | ⏸️ Pending | 3 hours | Core feature |
| 6. Adapters | ⏸️ Pending | 2 hours | Migrate code |
| 7. Config & Utils | ⏸️ Pending | 1 hour | Settings & helpers |
| 8. Worker | ⏸️ Pending | 2 hours | Integration |
| 9. Queue Updates | ⏸️ Pending | 1 hour | Add flags |
| 10. Testing | ⏸️ Pending | 2 hours | Unit + integration |
| 11. Documentation | ⏸️ Pending | 1 hour | Docs & examples |

**Total Estimated Time:** 15-17 hours

---

## 🎯 Success Criteria

- [ ] Clean Architecture structure fully implemented
- [ ] All existing functionality preserved (no regressions)
- [ ] Media download working for both audio and video
- [ ] Audio download tries TikTok URL first, falls back to ffmpeg
- [ ] Optional `download_media` flag in all 3 task types
- [ ] MongoDB stores media_path, media_type, media_downloaded_at
- [ ] All tests passing (unit + integration + E2E)
- [ ] Documentation complete and up-to-date
- [ ] Error handling robust (ffmpeg missing, download fails, etc.)

---

## 🚨 Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| TikTok URL structure changed | High | Test thoroughly, add fallbacks |
| ffmpeg not installed | Medium | Check availability, show clear error |
| Large file downloads fail | Medium | Add retry logic, timeout handling |
| Breaking existing functionality | High | Comprehensive testing, gradual rollout |
| Download URLs expire quickly | Medium | Download immediately after extraction |

---

## 📚 References

### Key Files to Review
- **Current Implementation:**
  - `scrapper/tiktok/core/video_api.py` - Video scraping
  - `scrapper/tiktok/database/models.py` - Current data models
  - `scrapper/tiktok/database/repository.py` - MongoDB operations
  - `scrapper/tiktok/worker.py` - Current worker

- **Reference Implementation:**
  - `src/core/TikTok.ts` - TypeScript scraper
  - `src/core/Downloader.ts` - Download logic reference
  - `src/types/TikTok.ts` - Data structure definitions

### External Documentation
- [TikTok Web API (unofficial)](https://github.com/davidteather/TikTok-Api)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [FFmpeg audio extraction](https://trac.ffmpeg.org/wiki/Encode/MP3)

---

## 💡 Implementation Tips

1. **Start with verification** - Phase 1 is crucial to validate assumptions
2. **Test incrementally** - Don't wait until the end to test
3. **Keep backups** - Move old code to `_old/` folder
4. **Log everything** - Add detailed logging for debugging
5. **Handle errors gracefully** - Media download is optional, don't fail entire crawl
6. **Use dependency injection** - Makes testing much easier
7. **Follow existing patterns** - Maintain consistency with codebase style

---

## 🔄 Next Session Quick Start

**To continue this refactoring in the next session:**

1. Read this plan: `scrapper/tiktok/REFACTOR_PLAN.md`
2. Check progress in TODO list
3. Start with Phase 1 if not yet done:
   - Test URL extraction from itemStruct
   - Verify download URLs work
   - Document findings
4. Proceed to next pending phase

**Commands to run:**
```bash
cd scrapper/tiktok
python worker.py  # Test current implementation
# Then start refactoring based on current phase
```

---

**Plan created:** 2025-10-31
**Expected completion:** 15-17 hours of focused work
**Current phase:** Planning ✅ Complete - Ready for Phase 1
