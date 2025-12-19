# Project Context

## Purpose

SMAP AI Internal là hệ thống **Social Media Analytics Platform** được thiết kế để:

- **Thu thập dữ liệu** từ các nền tảng mạng xã hội (TikTok, YouTube, Instagram)
- **Phân tích ngôn ngữ tự nhiên** với các mô hình LLM và NLP
- **Trích xuất từ khóa** và insights từ nội dung tiếng Việt
- **Phân tích cảm xúc** (sentiment analysis) từ bình luận và nội dung
- **Cung cấp API** để tích hợp với các hệ thống khác

### Tính năng nổi bật

- **Scalable Architecture**: Hỗ trợ horizontal scaling với RabbitMQ và multiple workers
- **Real-time Processing**: Xử lý bất đồng bộ với message queue
- **Fault Tolerance**: Resume từ checkpoint khi worker crash
- **Smart Data Management**: MongoDB với upsert thông minh (static vs dynamic fields)
- **Vietnamese Language Support**: Hỗ trợ đặc biệt cho tiếng Việt với VnCoreNLP
- **No API Key Required**: Không giới hạn quota từ các platform APIs

---

## Tech Stack

### Backend & Runtime

- **Python 3.12+**: Async/await, type hints (all services)
- **FastAPI**: Modern web framework cho API services (FFmpeg, Playwright)
- **Pydantic 2.x**: Data validation và settings management
- **Motor**: Async MongoDB driver
- **aio-pika**: Async RabbitMQ client
- **Uvicorn**: ASGI server for FastAPI services

### Crawling & Automation

- **Playwright 1.55.0**: Browser automation (TikTok via remote Playwright service)
- **yt-dlp**: YouTube extraction (không cần browser)
- **youtube-comment-downloader**: Full comment pagination for YouTube
- **httpx/aiohttp**: HTTP clients cho API scraping

### Media Processing

- **FFmpeg**: Audio/video conversion (MP4 → MP3 via FFmpeg service)
- **Zstandard (zstd)**: Compression cho data archival (JSON archives to MinIO)

### Infrastructure

- **MongoDB 6.x**: Document database cho metadata
- **RabbitMQ 3.x**: Message broker cho task queue
- **MinIO**: S3-compatible object storage cho media files
- **Docker & Docker Compose**: Containerization

### Package Management

- **uv**: Fast Python package manager (preferred)
- **pip**: Fallback package manager

---

## Project Structure

```
smap-ai-internal/
├── openspec/                    # OpenSpec configuration
│   ├── AGENTS.md               # AI assistant instructions
│   ├── project.md              # This file
│   ├── specs/                  # Current specifications
│   └── changes/                # Change proposals
│
└── scrapper/                    # Social Media Scraper Services
    ├── docker-compose.yml      # Service orchestration
    ├── README.MD               # Main documentation
    │
    ├── tiktok/                 # TikTok Scraper Worker
    │   ├── app/                # Entry points & DI
    │   │   ├── main.py         # Entry point → worker_service.py
    │   │   ├── bootstrap.py   # Dependency injection container
    │   │   └── worker_service.py  # Worker orchestration
    │   ├── application/        # Use cases & interfaces
    │   │   ├── interfaces.py  # Abstract interfaces (ports)
    │   │   ├── crawler_service.py  # Crawling orchestration
    │   │   └── task_service.py     # Task handling & job tracking
    │   ├── domain/             # Business entities
    │   │   ├── entities/       # Content, Author, Comment, CrawlJob, SearchSession
    │   │   ├── value_objects/  # Metrics
    │   │   └── enums.py        # SourcePlatform, MediaType, JobType, etc.
    │   ├── internal/           # Infrastructure adapters
    │   │   ├── adapters/       # Scrapers & repositories
    │   │   └── infrastructure/ # MongoDB, RabbitMQ, MinIO, Playwright clients
    │   ├── config/             # Configuration
    │   ├── utils/              # Utilities
    │   └── tests/              # Test suite
    │
    ├── youtube/                # YouTube Scraper Worker (similar structure)
    │   ├── app/                # Entry points & DI (same as TikTok)
    │   ├── application/        # Use cases & interfaces
    │   ├── domain/             # Business entities (unified schema)
    │   ├── internal/           # Infrastructure adapters
    │   ├── config/             # Configuration
    │   ├── utils/              # Utilities
    │   └── tests/              # Test suite
    │
    ├── ffmpeg/                 # FFmpeg Conversion Service
    │   ├── cmd/api/            # FastAPI application
    │   │   ├── main.py         # FastAPI app entry point
    │   │   ├── routes.py      # API routes (/health, /convert)
    │   │   └── Dockerfile     # Service container
    │   ├── core/               # Config, DI, concurrency
    │   │   ├── config.py      # Settings management
    │   │   ├── container.py   # Dependency injection
    │   │   ├── concurrency.py  # Semaphore for job limits
    │   │   └── logging.py     # Logging configuration
    │   ├── services/           # Media converter
    │   │   └── converter.py   # MediaConverter orchestration
    │   ├── domain/             # Entities & enums
    │   │   ├── entities/      # ConversionJob, MediaFile, ConversionResult
    │   │   └── enums.py       # ConversionStatus, AudioFormat, AudioQuality
    │   └── models/             # Payloads & exceptions
    │       ├── payloads.py    # ConversionRequest, ConversionResponse
    │       └── exceptions.py  # Error taxonomy
    │
    ├── playwight/              # Playwright Remote Service
    │   ├── cmd/api/            # FastAPI application
    │   │   ├── main.py         # FastAPI app entry point
    │   │   ├── routes.py      # API routes
    │   │   └── Dockerfile     # Service container
    │   ├── core/               # Configuration
    │   │   └── config.py      # Settings (user agent, etc.)
    │   ├── services/           # TikTok service
    │   │   └── tiktok_service.py  # TikTok-specific browser automation
    │   └── models/            # Payloads
    │       └── payloads.py    # Request/response models
    │
    └── document/               # Architecture documentation
        ├── SERVICES_INTEGRATION_DOCUMENTATION.md
        ├── event-drivent.md
        └── collector-service-behavior.md
```

---

## Project Conventions

### Code Style

- **PEP 8**: Python style guide compliance
- **Type Hints**: Required cho tất cả function signatures
- **Docstrings**: Google style docstrings cho public APIs
- **Line Length**: 88 characters (Black formatter)
- **Import Order**: stdlib → third-party → local (isort)

### Naming Conventions

| Type             | Convention  | Example                |
| ---------------- | ----------- | ---------------------- |
| Files            | snake_case  | `video_api.py`         |
| Classes          | PascalCase  | `CrawlerService`       |
| Functions        | snake_case  | `fetch_videos_batch()` |
| Constants        | UPPER_SNAKE | `MAX_CONCURRENT`       |
| Environment vars | UPPER_SNAKE | `RABBITMQ_HOST`        |

### Architecture Patterns

#### Clean Architecture (All Services)

```
┌─────────────────────────────────────────┐
│              app/                       │  Entry points & DI container
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│          application/                   │  Use cases & interfaces
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│            domain/                      │  Business entities (NO dependencies)
└─────────────────────────────────────────┘
                ▲
                │
┌───────────────┴─────────────────────────┐
│          internal/                      │  Adapters & infrastructure
└─────────────────────────────────────────┘
```

#### Key Principles

- **Dependency Inversion**: High-level modules không depend on low-level modules
- **Interface-Based Design**: Sử dụng abstract interfaces (ports) cho external dependencies
- **Repository Pattern**: Data access abstraction
- **Producer-Consumer Pattern**: RabbitMQ message handling

### Testing Strategy

#### Test Categories

- **Unit Tests**: `tests/unit/` - Pure business logic, no external dependencies
- **Integration Tests**: `tests/integration/` - Database và queue interactions
- **E2E Tests**: `tests/e2e/` - Complete workflow validation

#### Test Conventions

- Test files: `test_*.py`
- Test functions: `test_*` hoặc `async def test_*`
- Use pytest fixtures cho setup/teardown
- Separate test databases và queues

#### Running Tests

```bash
# Unit tests
pytest tests/unit/

# Integration tests (requires MongoDB, RabbitMQ)
pytest tests/integration/

# All tests
pytest
```

### Git Workflow

- **Main branch**: `main` - Production-ready code
- **Feature branches**: `feature/{feature-name}`
- **Bugfix branches**: `fix/{bug-description}`
- **Commit messages**: Conventional commits format
  - `feat:` New feature
  - `fix:` Bug fix
  - `docs:` Documentation
  - `refactor:` Code refactoring
  - `test:` Adding tests

---

## Domain Context

### Unified Domain Schema

Tất cả scrapers (TikTok, YouTube) sử dụng **unified domain schema** để đảm bảo consistency. Schema được định nghĩa trong `refactor_modelDB.md` và được implement trong `domain/entities/` của mỗi service.

**Key Entities:**
- `Content`: Unified content entity (replaces platform-specific Video/Post)
- `Author`: Unified author entity (replaces Creator/Channel)
- `Comment`: Unified comment entity
- `SearchSession`: Search session metadata
- `CrawlJob`: Job tracking và orchestration

**Smart Upsert Logic:**
- **Static fields**: Never change after creation (source, external_id, url, keyword, job_id, created_at)
- **Dynamic fields**: Updated on every re-crawl (metrics, metadata, author info, media paths)

#### Content Entity (Video/Post)

```python
class Content:
    # Core identifiers
    source: SourcePlatform      # TIKTOK, YOUTUBE, FACEBOOK
    external_id: str            # Platform-specific ID
    url: str
    job_id: Optional[str]

    # Author reference
    author_id: Optional[str]              # MongoDB ObjectId reference
    author_external_id: Optional[str]     # Platform-specific author ID
    author_username: Optional[str]        # Username/handle
    author_display_name: Optional[str]    # Display name

    # Content metadata
    title: Optional[str]                 # YouTube, Facebook; null for TikTok
    description: Optional[str]            # Normalized caption/description
    duration_seconds: Optional[int]
    sound_name: Optional[str]             # TikTok sound/music name
    category: Optional[str]               # YouTube category
    tags: List[str]                       # Normalized hashtags/tags

    # Media information
    media_type: Optional[MediaType]       # VIDEO, IMAGE, AUDIO, POST
    media_path: Optional[str]             # Storage path (S3/MinIO/local)
    media_downloaded_at: Optional[datetime]

    # Metrics (dynamic - updated on every crawl)
    view_count: Optional[int]
    like_count: Optional[int]
    comment_count: Optional[int]
    share_count: Optional[int]            # TikTok; null for YouTube
    save_count: Optional[int]             # TikTok; null for YouTube

    # Timestamps
    published_at: Optional[datetime]
    crawled_at: Optional[datetime]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    # Search metadata
    keyword: Optional[str]                # Search keyword (if from search)

    # Platform-specific data
    extra_json: Optional[dict]            # Platform-specific fields as JSON

    # Speech-to-Text (TikTok)
    transcription: Optional[str]
    transcription_status: Optional[str]   # SUCCESS, ERROR, TIMEOUT, PENDING
    transcription_error: Optional[str]

    # AI Summary (YouTube)
    content_detail: Optional[str]         # AI-generated content summary (Gemini)
```

#### Author Entity (Creator/Channel)

```python
class Author:
    # Core identifiers
    source: SourcePlatform
    external_id: str                      # Platform-specific author ID
    profile_url: Optional[str]            # Author profile/channel URL
    username: Optional[str]               # Unique handle/username
    display_name: Optional[str]           # Display name
    verified: Optional[bool]              # Verification badge status

    # Statistics (dynamic - change frequently)
    follower_count: Optional[int]          # Follower/subscriber count
    following_count: Optional[int]        # Following count (TikTok)
    like_count: Optional[int]             # Total likes (TikTok); null for YouTube
    video_count: Optional[int]            # Total videos/posts published

    # Timestamps
    crawled_at: Optional[datetime]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    # Platform-specific data
    extra_json: Optional[dict]           # Platform-specific fields (bio, description, etc.)
```

#### Comment Entity

```python
class Comment:
    # Core identifiers
    source: SourcePlatform
    external_id: str                      # Platform-specific comment ID
    parent_type: ParentType              # CONTENT or COMMENT
    parent_id: str                       # ID of parent (content or comment)

    # Comment content
    comment_text: Optional[str]           # Comment text content
    commenter_name: Optional[str]         # Commenter display name/username

    # Engagement metrics
    like_count: Optional[int]             # Comment likes
    reply_count: Optional[int]            # Number of replies

    # Timestamps
    published_at: Optional[datetime]      # Comment publish timestamp
    crawled_at: Optional[datetime]        # Crawl timestamp
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    # Platform-specific data
    extra_json: Optional[dict]           # Platform-specific fields
```

#### SearchSession Entity

```python
class SearchSession:
    # Core identifiers
    search_id: str                       # Unique search session ID
    source: SourcePlatform
    keyword: str                         # Search keyword used
    sort_by: Optional[SearchSortBy]     # RELEVANCE, LIKE, VIEW, DATE

    # Search results
    searched_at: datetime                # Search timestamp
    total_found: Optional[int]          # Total number of results found
    urls: List[str]                     # List of content URLs discovered

    # Job tracking
    job_id: Optional[str]                # External service job ID
    params_raw: Optional[str]            # JSON string of original search parameters
```

#### CrawlJob Entity

```python
class CrawlJob:
    # Identifiers
    task_type: JobType                   # Job task type
    status: JobStatus                    # QUEUED, RUNNING, RETRYING, COMPLETED, FAILED, CANCELED
    job_id: Optional[str]                # External service job ID

    # Job configuration
    payload_json: dict                   # Job payload for worker
    time_range: Optional[int]            # Publish window in days
    since_date: Optional[datetime]       # Filter content published after
    until_date: Optional[datetime]       # Filter content published before
    max_retry: int                       # Maximum retry attempts
    retry_count: int                     # Current retry attempt count
    error_msg: Optional[str]             # Error message if failed

    # Timestamps
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
```

### Task Types

Tất cả scrapers hỗ trợ các task types sau:

| Task Type                | Description                             | TikTok | YouTube |
| ------------------------ | --------------------------------------- | ------ | ------- |
| `research_keyword`       | Search by keyword, save URLs            | ✅     | ✅      |
| `crawl_links`            | Crawl specific URLs with full metadata  | ✅     | ✅      |
| `research_and_crawl`     | Search then crawl all found content     | ✅     | ✅      |
| `fetch_profile_content`  | Crawl all videos from a profile         | ✅     | ❌      |
| `fetch_channel_content`  | Crawl all videos from a channel         | ❌     | ✅      |
| `dryrun_keyword`         | Search and scrape without persistence   | ✅     | ✅      |

### Storage Control Flags

Mỗi task có thể control storage behavior:

| Flag                      | Default | Description           |
| ------------------------- | ------- | --------------------- |
| `save_to_db_enabled`      | `false` | Save to MongoDB       |
| `media_download_enabled`  | `true`  | Download media files  |
| `archive_storage_enabled` | `true`  | Archive JSON to MinIO |

---

## Important Constraints

### Technical Constraints

- **Python Version**: 3.12+ required
- **Async-First**: Sử dụng async/await cho I/O operations
- **Memory Limits**: ~200MB per TikTok worker, ~50MB per YouTube worker
- **Concurrent Limits**: Default 8 concurrent tasks per worker

### Platform Constraints

- **TikTok**: Requires Playwright for browser automation
- **YouTube**: Uses yt-dlp (no browser required)
- **Instagram**: Currently blocked by anti-bot (limited functionality)

### Rate Limiting

- **TikTok**: 20 requests/minute, 2-5s delay between requests
- **YouTube**: No explicit limits (yt-dlp handles internally)

### Data Retention

- **MongoDB**: Permanent storage (collections: `content`, `authors`, `comments`, `search_sessions`, `crawl_jobs`)
- **MinIO Archives**: Permanent storage (compressed JSON with zstd)
- **MinIO Media**: Permanent storage (audio/video files)

---

## External Dependencies

### Infrastructure Services

| Service  | Purpose           | Default Port                    |
| -------- | ----------------- | ------------------------------- |
| RabbitMQ | Message broker    | 5672 (AMQP), 15672 (Management) |
| MongoDB  | Document database | 27017                           |
| MinIO    | Object storage    | 9000 (API), 9001 (Console)      |

### Internal Services

| Service            | Purpose                   | Default Port           | Entry Point           |
| ------------------ | ------------------------- | ---------------------- | --------------------- |
| Playwright Service | Remote browser automation | 4444 (WS), 8001 (REST) | `cmd/api/main.py`     |
| FFmpeg Service     | Media conversion          | 8000                   | `cmd/api/main.py`     |
| Speech-to-Text API | Audio transcription       | External               | External service      |

### Message Queue Configuration

```yaml
# TikTok Worker
Exchange: tiktok_exchange
Queue: tiktok_crawl_queue
Routing Key: tiktok.crawl

# YouTube Worker
Exchange: youtube_exchange
Queue: youtube_crawl_queue
Routing Key: youtube.crawl

# Event-Driven (Project Integration)
Exchange: smap.events (topic)
Routing Keys:
  - project.created
  - data.collected
  - analysis.finished
  - job.completed
```

### MongoDB Collections

| Collection        | Description            |
| ----------------- | ---------------------- |
| `content`         | Video/content metadata |
| `authors`         | Creator/channel info   |
| `comments`        | Video comments         |
| `search_sessions` | Keyword search results |
| `crawl_jobs`      | Job tracking           |

### MinIO Buckets

| Bucket            | Description                                    |
| ----------------- | ---------------------------------------------- |
| `tiktok-media`    | TikTok audio/video files                       |
| `youtube-media`   | YouTube audio/video files (temporary storage)  |
| `tiktok-archive`  | TikTok JSON archives (compressed with zstd)     |
| `youtube-archive` | YouTube JSON archives (compressed with zstd)  |

**Note**: FFmpeg service streams media directly between MinIO buckets without local disk storage.

---

## Service Comparison

| Feature          | TikTok                | YouTube                |
| ---------------- | --------------------- | ---------------------- |
| Scraping Engine  | Playwright + HTTP API | yt-dlp                 |
| Browser Required | Yes (remote service)  | No                     |
| Comment Coverage | 60-70% (top comments) | 100% (full pagination) |
| Speed per video  | ~5s                   | ~15-30s                |
| RAM per worker   | ~200MB                | ~50MB                  |
| Media Processing | Direct download       | FFmpeg service (HTTP)  |
| AI Summary       | No                    | Yes (Gemini)            |
| Entry Point      | `app/main.py`         | `app/main.py`           |
| Task Type        | `fetch_profile_content` | `fetch_channel_content` |

---

## Environment Variables

### Common Settings

```env
# Application
APP_ENV=development
LOG_LEVEL=INFO

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/

# MongoDB
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=tiktok_crawl

# MinIO
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=tiktok-media
```

### Service-Specific Settings

See individual service `.env.example` files:

- `scrapper/tiktok/.env.example`
- `scrapper/youtube/.env.example`
- `scrapper/ffmpeg/.env.example`

---

## Quick Start

### 1. Start Infrastructure

```bash
cd scrapper
docker compose up -d rabbitmq mongodb minio
```

### 2. Start Services

```bash
# Option 1: Docker Compose (recommended)
docker compose up

# Option 2: Local development
# TikTok Worker
cd tiktok
cp .env.example .env
uv sync
python -m app.main

# YouTube Worker
cd youtube
cp .env.example .env
uv sync
python -m app.main

# FFmpeg Service
cd ffmpeg
cp .env.example .env
uv sync
uvicorn cmd.api.main:app --host 0.0.0.0 --port 8000

# Playwright Service
cd playwight
cp .env.example .env
uv sync
uvicorn cmd.api.main:app --host 0.0.0.0 --port 8001
```

### 3. Publish Test Job

```python
import asyncio
from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

async def main():
    publisher = RabbitMQPublisher()
    await publisher.connect()
    await publisher.publish({
        "task_type": "dryrun_keyword",
        "job_id": "test-123",
        "payload": {
            "keywords": ["python tutorial"],
            "limit": 5
        }
    })

asyncio.run(main())
```

---

## Documentation References

- [Main README](scrapper/README.MD) - Overview và quick start
- [TikTok README](scrapper/tiktok/README.md) - TikTok scraper details
- [YouTube README](scrapper/youtube/README.md) - YouTube scraper details
- [FFmpeg README](scrapper/ffmpeg/README.md) - Media conversion service
- [Services Integration](scrapper/document/SERVICES_INTEGRATION_DOCUMENTATION.md) - Full integration guide
- [Event-Driven Architecture](scrapper/document/event-drivent.md) - Event flow documentation
