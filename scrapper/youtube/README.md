# YouTube Scraper Worker

A high-performance YouTube data scraper built with Clean Architecture principles. The worker uses yt-dlp for video/channel metadata extraction, supports comprehensive comment collection, and integrates with RabbitMQ for task distribution, MongoDB for persistence, and MinIO for media storage.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Worker](#running-the-worker)
- [Task Types](#task-types)
- [Project Structure](#project-structure)
- [Smart Upsert Logic](#smart-upsert-logic)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Architecture Highlights](#architecture-highlights)

## Architecture Overview

```
Producer System → RabbitMQ Queue → Worker (TaskService + CrawlerService)
    → MongoDB (metadata) + MinIO (media files)
```

The scraper follows **Clean Architecture** with clear separation of concerns:

```
app → application → domain
         ↓
    internal (adapters)
```

**Dependency Rule:** Dependencies point inward. The domain layer has NO external dependencies.

### Layer Responsibilities

- **Domain Layer**: Pure business entities (Video, Channel, Comment, SearchResult) with no framework dependencies
- **Application Layer**: Use cases, orchestration, and abstract interfaces (ports)
- **Infrastructure Layer**: External adapters (yt-dlp, MongoDB, RabbitMQ, MinIO)
- **App Layer**: Dependency injection container and application entry point

## Features

- **Video Metadata Extraction**: Complete video information using yt-dlp
- **Channel Information Scraping**: Channel details and statistics
- **100% Comment Coverage**: Comprehensive comment collection using youtube-comment-downloader
- **Search Functionality**: YouTube search with keyword filtering
- **Media Download**: Audio/video download with FFmpeg support
- **MinIO Object Storage**: Scalable media file storage
- **MongoDB Persistence**: Smart upsert logic for efficient data updates
- **RabbitMQ Task Queue**: Distributed task processing support
- **Pure Async/Await**: Full asynchronous architecture with executors for sync libraries
- **Dependency Injection**: Testable design with interface-based programming
- **Three Task Types**: `research_keyword`, `crawl_links`, `research_and_crawl`

## Prerequisites

- **Python 3.10+** (tested with 3.11)
- **MongoDB 6.x** (data persistence)
- **RabbitMQ 3.x** (optional, for queue-based tasks)
- **FFmpeg Conversion Service** (remote microservice required for audio extraction, see `../ffmpeg`)
- **MinIO** (optional, for object storage)

## Installation

### 1. Clone and Navigate

```bash
cd scrapper/youtube
```

### 2. Create Virtual Environment (Recommended)

```bash
python -m venv .venv
# On Windows
.venv\Scripts\activate
# On Linux/macOS
source .venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configure FFmpeg Service

The YouTube worker now delegates audio extraction to the dedicated FFmpeg microservice (`scrapper/ffmpeg`).

1. Build/launch the service (Docker example):
   ```bash
   cd ../ffmpeg
   docker compose up -d
   ```
2. Set `MEDIA_FFMPEG_SERVICE_URL` in `.env` to point to the service (e.g., `http://ffmpeg-service:8000`).
3. Verify the service is healthy:
   ```bash
   curl http://ffmpeg-service:8000/health
   ```

### 5. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your MongoDB, RabbitMQ, and MinIO settings.

### 6. Start Infrastructure Services

Ensure MongoDB (and optionally RabbitMQ, MinIO) are running.

## Configuration

Key environment variables (see `.env.example` for complete list):

### MongoDB Settings

```bash
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=youtube_crawl
MONGODB_USER=
MONGODB_PASSWORD=
MONGODB_AUTH_SOURCE=admin
```

### RabbitMQ Settings

```bash
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_QUEUE_NAME=youtube_tasks
RABBITMQ_PREFETCH_COUNT=10
```

### Crawler Settings

```bash
CRAWLER_MAX_CONCURRENT=8
CRAWLER_TIMEOUT=60
CRAWLER_RETRY_ATTEMPTS=3
```

### Media Download Settings

```bash
MEDIA_DOWNLOAD_ENABLED=true
MEDIA_DEFAULT_TYPE=audio
MEDIA_DOWNLOAD_DIR=./downloads
MEDIA_FFMPEG_SERVICE_URL=http://ffmpeg-service:8000
```

### MinIO Settings (Optional)

```bash
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_SECURE=false
MINIO_BUCKET_NAME=youtube
```

### yt-dlp Settings

```bash
YT_DLP_EXTRACT_FLAT=false
YT_DLP_QUIET=true
YT_DLP_NO_WARNINGS=true
```

## Running the Worker

### Local Development

```bash
python -m app.worker_service
```

The worker will:
1. Bootstrap all dependencies via DI container
2. Connect to RabbitMQ queue (if configured)
3. Wait for and process tasks
4. Gracefully shutdown on `Ctrl+C`

### Programmatic Usage

```python
import asyncio
from app.bootstrap import Bootstrap

async def main():
    # Initialize the application
    bootstrap = Bootstrap()
    await bootstrap.startup()

    try:
        # Crawl a single video
        result = await bootstrap.crawler_service.fetch_video_and_media(
            url="https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            download_media=True,
            media_type="audio",
            include_channel=True,
            include_comments=True,
            max_comments=100
        )

        if result.success:
            print(f"Video: {result.video.title}")
            print(f"Channel: {result.channel.channel_title}")
            print(f"Comments: {len(result.comments)}")

    finally:
        await bootstrap.shutdown()

if __name__ == "__main__":
    asyncio.run(main())
```

### Docker Compose

From the `scrapper/` directory:

```bash
docker compose build youtube-worker
docker compose up youtube-worker
```

## Task Types

All job payloads accept an optional `time_range` (positive integer in days). When provided,
the worker only persists videos published within the `[now - time_range, now]` window. Comments
are filtered using the same window, and videos just outside the range are still stored if they
contain at least one in-range comment (otherwise they are reported as skipped, not failed).

### 1. Research Keyword

Search YouTube by keyword and save results to `search_results` collection.

**Payload:**
```json
{
  "task_type": "research_keyword",
  "job_id": "uuid-123",
  "payload": {
    "keyword": "python tutorial",
    "limit": 50,
    "sort_by": "relevance",
    "time_range": 7
  }
}
```

**Sort Options**: `relevance`, `upload_date`, `view_count`, `rating`

### 2. Crawl Links

Crawl specific video URLs with optional channel info, comments, and media download.

**Payload:**
```json
{
  "task_type": "crawl_links",
  "job_id": "uuid-456",
  "payload": {
    "video_urls": [
      "https://www.youtube.com/watch?v=abc123",
      "https://www.youtube.com/watch?v=def456"
    ],
    "include_channel": true,
    "include_comments": true,
    "max_comments": 100,
    "download_media": true,
    "media_type": "audio",
    "time_range": 14
  }
}
```

**Options:**
- `include_channel`: Fetch channel information (default: true)
- `include_comments`: Fetch video comments (default: true)
- `max_comments`: Maximum comments per video (default: 100, 0 for unlimited)
- `download_media`: Download video/audio (default: false)
- `media_type`: `audio` or `video` (default: audio)
- `time_range`: Only persist videos/comments published within the last N days

### 3. Research and Crawl

Search by keywords then crawl all found videos in a single job.

**Payload:**
```json
{
  "task_type": "research_and_crawl",
  "job_id": "uuid-789",
  "payload": {
    "keywords": ["python programming", "machine learning"],
    "limit_per_keyword": 50,
    "include_comments": true,
    "include_channel": true,
    "max_comments": 50,
    "download_media": false,
    "time_range": 30
  }
}
```

### Result Storage

Data is persisted to MongoDB collections:
- `jobs`: Job tracking with status and timestamps
- `videos`: Video metadata and dynamic metrics
- `channels`: Channel information and statistics
- `comments`: Video comments with author info
- `search_results`: Keyword search results

Media files are uploaded to MinIO (or stored locally) with paths stored in video documents.

## Project Structure

```
youtube/
├── app/                          # Entry points & DI
│   ├── bootstrap.py              # Dependency injection container
│   ├── main.py                   # Programmatic entry point
│   └── worker_service.py         # Worker entry point
├── application/                  # Use cases & interfaces
│   ├── interfaces.py             # Abstract interfaces (ports)
│   ├── crawler_service.py        # Crawling orchestration
│   └── task_service.py           # Task handling service
├── domain/                       # Business entities
│   ├── entities/                 # Video, Channel, Comment, SearchResult
│   │   ├── video.py
│   │   ├── channel.py
│   │   ├── comment.py
│   │   └── search_result.py
│   └── value_objects/            # Metrics
│       └── metrics.py
├── internal/                     # Infrastructure adapters
│   ├── adapters/
│   │   ├── scrapers_youtube/     # yt-dlp implementations
│   │   │   ├── video_scraper.py
│   │   │   ├── channel_scraper.py
│   │   │   ├── comment_scraper.py
│   │   │   ├── search_scraper.py
│   │   │   └── media_downloader.py
│   │   └── repository_mongo.py   # MongoDB repositories
│   └── infrastructure/
│       ├── minio/                # Object storage
│       │   └── storage.py
│       ├── mongo/                # Database helpers
│       │   └── client.py
│       └── rabbitmq/             # Message queue
│           ├── consumer.py
│           └── helpers.py
├── config/                       # Configuration
│   └── settings.py               # Pydantic settings
├── utils/                        # Utilities
│   ├── logger.py
│   └── helpers.py
├── tests/                        # Test suite
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── downloads/                    # Local media storage (gitignored)
├── .env.example                  # Environment template
├── requirements.txt              # Python dependencies
├── Dockerfile                    # Container image
└── README.md                     # This file
```

## Smart Upsert Logic

The scraper implements intelligent upsert logic for efficient re-crawling:

### Static Fields (Set Only on INSERT)
- `video_id`: Unique YouTube video ID
- `url`: Video URL
- `published_at`: Original publication date
- `channel_id`: Channel identifier
- `duration`: Video duration in seconds

### Dynamic Fields (Updated on Every Crawl)
- `title`: Video title (may change)
- `description`: Video description
- `views`: Current view count
- `likes`: Current like count
- `comment_count`: Current comment count
- `thumbnail_url`: Thumbnail URL

### Media Fields (Updated When Media is Downloaded)
- `media_path`: MinIO object path or local file path
- `media_type`: `audio` or `video`
- `media_downloaded_at`: Timestamp of download

### Benefits

- **Efficient Re-crawling**: Only updates what changes
- **Historical Accuracy**: View counts and engagement metrics stay current
- **Data Integrity**: Immutable identifiers never change
- **Storage Optimization**: Avoids redundant updates

## Testing

### Run Unit Tests

```bash
pytest tests/unit
```

### Run Integration Tests

Requires MongoDB and RabbitMQ test instances:

```bash
pytest tests/integration
```

### Run End-to-End Tests

Full workflow tests:

```bash
pytest tests/e2e
```

### Run All Tests

```bash
pytest
```

**Best Practice:** Use separate test database and queue to avoid affecting production data.

## Troubleshooting

### MongoDB Connection Failed

- Verify MongoDB is running: `docker ps` or `systemctl status mongod`
- Check connection string in `.env`
- Verify authentication if enabled
- Check `MONGODB_AUTH_SOURCE` setting

### RabbitMQ Connection Failed

- Ensure RabbitMQ service is running
- Verify credentials match RabbitMQ configuration
- Check port 5672 accessibility
- Verify virtual host (`RABBITMQ_VHOST`)

### yt-dlp Extraction Errors

- Update yt-dlp: `pip install --upgrade yt-dlp`
- Check video availability (age restrictions, region locks)
- Verify video URL format
- Check internet connectivity

### FFmpeg Service Errors

- Ensure the FFmpeg service container is running (`docker ps | grep ffmpeg`)
- Verify `MEDIA_FFMPEG_SERVICE_URL` points to the service host/port
- Check service health: `curl http://ffmpeg-service:8000/health`
- Inspect FFmpeg service logs for conversion failures

### Media Download Issues

- Check disk space: `df -h` (Linux/macOS) or `dir` (Windows)
- Verify `MEDIA_DOWNLOAD_DIR` write permissions
- Check MinIO credentials and bucket existence
- Confirm the FFmpeg service can reach MinIO objects for conversions

### Slow Crawling Performance

- Increase `CRAWLER_MAX_CONCURRENT` for parallel processing
- Check network latency to YouTube servers
- Monitor MongoDB write performance
- Consider rate limiting on YouTube's side

## Architecture Highlights

### 1. Dependency Injection

All dependencies are injected via the `Bootstrap` container:

```python
self.crawler_service = CrawlerService(
    video_scraper=self.video_scraper,
    channel_scraper=self.channel_scraper,
    comment_scraper=self.comment_scraper,
    search_scraper=self.search_scraper,
    media_downloader=self.media_downloader,
    video_repo=self.video_repo,
    channel_repo=self.channel_repo,
    comment_repo=self.comment_repo,
    search_repo=self.search_repo
)
```

### 2. Pure Asyncio

All scrapers wrap synchronous yt-dlp calls in async executors:

```python
loop = asyncio.get_event_loop()
info = await loop.run_in_executor(
    self.executor,
    self._extract_info_sync,
    video_url
)
```

This prevents blocking the event loop while maintaining compatibility with yt-dlp's synchronous API.

### 3. Interface-Based Design

Program to interfaces, not implementations:

```python
class CrawlerService:
    def __init__(
        self,
        video_scraper: IVideoScraper,      # Interface
        video_repo: IVideoRepository,      # Interface
        channel_scraper: IChannelScraper,  # Interface
        # ...
    ):
```

This allows easy mocking for tests and swapping implementations without changing business logic.

### 4. Comparison with Traditional Approach

| Feature        | Traditional      | Clean Architecture |
| -------------- | ---------------- | ------------------ |
| Architecture   | Layered/Mixed    | Clean Architecture |
| DI             | Direct imports   | DI Container       |
| Async          | Mixed/ThreadPool | Pure asyncio       |
| Interfaces     | No               | Yes (ABC)          |
| Media Storage  | Local only       | MinIO + Local      |
| Testability    | Coupled          | Decoupled          |
| Task Queue     | No               | RabbitMQ           |

## Key Entry Points

- `app/worker_service.py:1` - Worker entry point
- `app/bootstrap.py:1` - Dependency injection setup
- `application/task_service.py:1` - Task type routing
- `application/crawler_service.py:1` - Crawling orchestration
- `internal/adapters/scrapers_youtube/video_scraper.py:1` - Video metadata extraction

## Development Guidelines

### Adding New Features

1. **Define entity** in `domain/entities/` (if needed)
2. **Define interface** in `application/interfaces.py`
3. **Implement use case** in `application/` service
4. **Implement adapter** in `internal/adapters/`
5. **Wire dependencies** in `app/bootstrap.py`
6. **Add tests** in `tests/`

### Project Philosophy

- **Domain Layer**: Pure business logic, no framework dependencies
- **Application Layer**: Use cases, orchestration, interfaces
- **Infrastructure Layer**: External dependencies (DB, APIs, queues)
- **App Layer**: Composition root, wiring dependencies

## Observability

### Logging

- Logs written to stdout and `logs/` directory
- Log level: `LOG_LEVEL` (DEBUG/INFO/WARNING/ERROR)
- Structured logging with context

### Job Tracking

Jobs collection tracks:
- Status: `pending`, `processing`, `completed`, `failed`
- Timestamps: `created_at`, `started_at`, `completed_at`
- Error messages and stack traces
- Retry attempts

### Metrics

Monitor key metrics:
- Videos crawled per hour
- Average crawl time per video
- Comment collection rate
- Media download success rate

## Contributing

When contributing to this project:

1. Follow Clean Architecture principles
2. Write tests for new functionality
3. Update documentation
4. Follow Python PEP 8 style guide
5. Use type hints
6. Keep domain layer pure (no external dependencies)

---

**Last Updated:** 2025-11-06
**Version:** 2.0.0
**Python Version:** 3.10+
**Architecture:** Clean Architecture / Hexagonal Architecture
