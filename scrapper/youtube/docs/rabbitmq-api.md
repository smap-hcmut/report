# YouTube Worker - RabbitMQ API Documentation

## Overview

This document describes the RabbitMQ message contract for the YouTube scraper worker. External services can publish messages to trigger crawling tasks.

## Connection Configuration

- **Exchange**: `youtube_exchange` (durable)
- **Queue**: `youtube_crawl_queue` (durable)
- **Routing Key**: `youtube.crawl`
- **Configuration**: Can be overridden via environment variables (see `scrapper/youtube/config/settings.py`)

## Message Envelope

All messages must be JSON UTF-8 encoded with the following structure:

```json
{
  "task_type": "<task_name>",
  "payload": {
    // Task-specific parameters
  },
  "job_id": "<optional_job_id>"
}
```

### Envelope Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_type` | string | Yes | Type of task to execute (see Task Types below) |
| `payload` | object | Yes | Task-specific parameters |
| `job_id` | string | No | Custom job ID (auto-generated UUID if not provided) |

## Common Payload Fields

These fields are available for all task types:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `time_range` | integer | No | - | Number of recent days to filter content (must be >= 1) |
| `since_date` | string | No | - | ISO 8601 date string (e.g., "2024-01-01T00:00:00Z") |
| `until_date` | string | No | - | ISO 8601 date string (e.g., "2024-12-31T23:59:59Z") |
| `media_download_enabled` | boolean | No | true | Enable/disable media file downloads |
| `save_to_db_enabled` | boolean | No | true | Enable/disable MongoDB persistence |
| `archive_storage_enabled` | boolean | No | true | Enable/disable MinIO archive storage |

**Note**: Invalid date formats are automatically ignored. `time_range` takes precedence over date range if both are provided.

## Task Types

### 1. research_keyword

Search for YouTube videos by keyword and return video URLs.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keyword` | string | **Yes** | - | Search keyword |
| `limit` | integer | No | 50 | Maximum number of videos to find |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "view", "date", "rating" |

**Example:**

```json
{
  "task_type": "research_keyword",
  "payload": {
    "keyword": "python tutorial",
    "limit": 100,
    "sort_by": "view",
    "time_range": 7
  },
  "job_id": "search-001"
}
```

**Response**: Returns list of video URLs found.

---

### 2. crawl_links

Crawl detailed information from specific YouTube video URLs.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `video_urls` | array[string] | **Yes** | - | List of YouTube video URLs to crawl |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_channel` | boolean | No | true | Fetch channel/author information |
| `max_comments` | integer | No | 0 | Maximum comments per video (0 = unlimited) |
| `keyword` | string | No | - | Associated keyword (for tracking) |
| `download_media` | boolean | No | false | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./YOUTUBE" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | true | Save to MongoDB |

**Example:**

```json
{
  "task_type": "crawl_links",
  "payload": {
    "video_urls": [
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "https://www.youtube.com/watch?v=9bZkp7q19f0"
    ],
    "include_comments": true,
    "max_comments": 100,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": true,
    "time_range": 30
  }
}
```

**Response**: Returns crawl statistics and MinIO keys for archived data.

---

### 3. research_and_crawl

Combined operation: search for videos by keywords and immediately crawl them.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keywords` | array[string] | **Yes** | - | List of search keywords |
| `limit_per_keyword` | integer | No | 50 | Max videos per keyword |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "view", "date", "rating" |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_channel` | boolean | No | true | Fetch channel information |
| `max_comments` | integer | No | 0 | Max comments per video (0 = unlimited) |
| `download_media` | boolean | No | false | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./YOUTUBE" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | true | Save to MongoDB |

**Example:**

```json
{
  "task_type": "research_and_crawl",
  "payload": {
    "keywords": ["python tutorial", "django tutorial", "fastapi tutorial"],
    "limit_per_keyword": 20,
    "sort_by": "view",
    "include_comments": true,
    "max_comments": 50,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": true,
    "since_date": "2024-01-01T00:00:00Z",
    "until_date": "2024-12-31T23:59:59Z"
  }
}
```

**Response**: Returns aggregated results for all keywords with crawl statistics.

---

### 4. dryrun_keyword

Search and scrape YouTube videos by keywords without persisting data to storage systems. This lightweight operation is ideal for testing search queries, validating parameters, and estimating result volumes before committing to full crawls. Results are published to a separate collector exchange for downstream processing.

**Key Characteristics:**
- No data saved to MongoDB
- No media files downloaded
- No MinIO archive uploads
- Results published to `collector.youtube` exchange
- 2-3x faster than equivalent full crawl tasks
- Supports multiple keywords in a single task

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keywords` | array[string] | **Yes*** | - | List of search keywords to process |
| `keyword` | string | **Yes*** | - | Single search keyword (backward compatibility) |
| `limit` | integer | No | 50 | Maximum number of videos per keyword |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "view", "date", "rating" |
| `include_comments` | boolean | No | true | Scrape video comments |
| `include_channel` | boolean | No | true | Scrape channel/author information |
| `max_comments` | integer | No | 0 | Maximum comments per video (0 = unlimited) |
| `time_range` | integer | No | - | Number of recent days to filter content |
| `since_date` | string | No | - | ISO 8601 date string for start date |
| `until_date` | string | No | - | ISO 8601 date string for end date |

**Note**: Either `keywords` (array) or `keyword` (string) must be provided. Use `keywords` for processing multiple search terms in a single task.

**Storage Flags** (automatically set to false, cannot be overridden):
- `media_download_enabled`: false
- `save_to_db_enabled`: false
- `archive_storage_enabled`: false

**Example - Single Keyword:**

```json
{
  "task_type": "dryrun_keyword",
  "payload": {
    "keyword": "python tutorial",
    "limit": 100,
    "sort_by": "view",
    "include_comments": true,
    "max_comments": 50,
    "time_range": 7
  },
  "job_id": "dryrun-001"
}
```

**Example - Multiple Keywords:**

```json
{
  "task_type": "dryrun_keyword",
  "payload": {
    "keywords": ["python tutorial", "django tutorial", "fastapi tutorial"],
    "limit": 50,
    "sort_by": "relevance",
    "include_comments": true,
    "include_channel": true,
    "max_comments": 100,
    "since_date": "2024-01-01T00:00:00Z",
    "until_date": "2024-12-31T23:59:59Z"
  },
  "job_id": "dryrun-multi-001"
}
```

**Result Message Format:**

Results are published to the collector exchange with the following configuration:
- **Exchange**: `collector.youtube` (durable, direct)
- **Routing Key**: `youtube.res`
- **Queue**: `youtube.collector.queue` (durable)

**Success Response:**

```json
{
  "success": true,
  "payload": [
    {
      "meta": {
        "id": "dQw4w9WgXcQ",
        "platform": "youtube",
        "job_id": "dryrun-001",
        "crawled_at": "2024-12-02T10:30:00.123456Z",
        "published_at": "2009-10-25T06:57:33.000000Z",
        "permalink": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "keyword_source": "python tutorial",
        "lang": "vi",
        "region": "VN",
        "pipeline_version": "crawler_v2.3.1",
        "fetch_status": "success",
        "fetch_error": null
      },
      "content": {
        "text": "Learn Python programming from scratch. This comprehensive tutorial covers...",
        "duration": 3600,
        "hashtags": ["python", "tutorial", "programming", "coding"],
        "sound_name": null,
        "category": "Education",
        "title": "Complete Python Tutorial for Beginners 2024",
        "media": null,
        "transcription": "Welcome to this Python tutorial. In this video we will cover..."
      },
      "interaction": {
        "views": 1500000,
        "likes": 85000,
        "comments_count": 1200,
        "shares": null,
        "saves": null,
        "engagement_rate": 0.0575,
        "updated_at": "2024-12-02T10:30:00.123456Z"
      },
      "author": {
        "id": "UCxxxxxxxxxxxxxx",
        "name": "Python Tutorials",
        "username": "pythontutorials",
        "followers": 500000,
        "following": null,
        "likes": null,
        "videos": 250,
        "is_verified": true,
        "bio": "Learn Python programming with easy-to-follow tutorials",
        "avatar_url": null,
        "profile_url": "https://www.youtube.com/@pythontutorials",
        "country": "US",
        "total_view_count": 50000000
      },
      "comments": [
        {
          "id": "UgxKREhKU0hLRWhBRVhF",
          "parent_id": null,
          "post_id": "dQw4w9WgXcQ",
          "user": {
            "id": "UCyyyyyyyyyyyyyy",
            "name": "John Doe",
            "avatar_url": "https://yt3.ggpht.com/..."
          },
          "text": "Great tutorial! Very helpful for beginners.",
          "likes": 150,
          "replies_count": 5,
          "published_at": "2024-11-20T15:00:00.000000Z",
          "is_author": false,
          "media": null
        },
        {
          "id": "UgxABCDEFGHIJKLMNOP",
          "parent_id": null,
          "post_id": "dQw4w9WgXcQ",
          "user": {
            "id": "UCzzzzzzzzzzzzzz",
            "name": "Jane Smith",
            "avatar_url": "https://yt3.ggpht.com/..."
          },
          "text": "Thanks for explaining this so clearly!",
          "likes": 89,
          "replies_count": 2,
          "published_at": "2024-11-21T09:30:00.000000Z",
          "is_author": false,
          "media": null
        }
      ]
    }
  ]
}
```

**Error Response:**

```json
{
  "success": false,
  "payload": []
}
```

**YouTube-Specific Fields:**

The result format includes YouTube-specific fields not present in other platforms:

| Field | Location | Description |
|-------|----------|-------------|
| `content.title` | content | Video title (YouTube has explicit titles) |
| `content.category` | content | YouTube video category (e.g., "Education", "Entertainment") |
| `content.transcription` | content | Video transcript (if available) |
| `author.country` | author | Channel's country code |
| `author.total_view_count` | author | Total views across all channel videos |
| `comments[].user.id` | comments | Commenter's channel ID |
| `interaction.shares` | interaction | Always null (YouTube doesn't expose share counts) |
| `interaction.saves` | interaction | Always null (YouTube doesn't expose save counts) |

**Collector Exchange Configuration:**

Before using dry-run tasks, ensure the collector exchange and queue are configured:

```bash
# Declare exchange
rabbitmqadmin declare exchange name=collector.youtube type=direct durable=true

# Declare queue
rabbitmqadmin declare queue name=youtube.collector.queue durable=true

# Bind queue to exchange
rabbitmqadmin declare binding source=collector.youtube \
  destination=youtube.collector.queue routing_key=youtube.res
```

**Environment Variables:**

```bash
# Result Publisher Settings
RESULT_PUBLISHER_ENABLED=true
RESULT_EXCHANGE_NAME=collector.youtube
RESULT_ROUTING_KEY=youtube.res
RESULT_QUEUE_NAME=youtube.collector.queue
```

**Use Cases:**

1. **Query Validation**: Test search keywords before running expensive full crawls
2. **Volume Estimation**: Determine how many videos match search criteria
3. **Parameter Tuning**: Experiment with sort_by, time_range, and limit settings
4. **Pipeline Testing**: Validate downstream processing without storage overhead
5. **Quick Sampling**: Get sample data for analysis without full persistence

**Performance:**

Dry-run tasks execute 2-3x faster than equivalent full crawl tasks due to:
- No media downloads (saves bandwidth and time)
- No database writes (reduces I/O)
- No MinIO uploads (reduces network overhead)
- No compression operations (reduces CPU usage)
- No STT API calls (saves processing time)

---

### 5. fetch_channel_content

Crawl all videos from a YouTube channel.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `channel_url` | string | **Yes** | - | YouTube channel URL (e.g., https://www.youtube.com/@channelname) |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_channel` | boolean | No | true | Fetch channel information |
| `max_comments` | integer | No | 0 | Max comments per video (0 = unlimited) |
| `limit` | integer | No | 0 | Max videos to fetch (0 = unlimited) |
| `download_media` | boolean | No | false | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./YOUTUBE" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | true | Save to MongoDB |

**Example:**

```json
{
  "task_type": "fetch_channel_content",
  "payload": {
    "channel_url": "https://www.youtube.com/@codingtrain",
    "include_comments": true,
    "max_comments": 50,
    "limit": 100,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": true,
    "time_range": 90
  }
}
```

**Response**: Returns channel crawl statistics and MinIO keys.

---

## Response Format

All tasks return a response with the following structure:

```json
{
  "job_id": "uuid-or-custom-id",
  "success": true,
  "task_type": "crawl_links",
  "total": 10,
  "successful": 8,
  "failed": 1,
  "skipped": 1,
  "download_media": true,
  "media_type": "audio"
}
```

### Error Response

```json
{
  "job_id": "uuid-or-custom-id",
  "success": false,
  "error": "Error message with full traceback",
  "error_type": "scraping"
}
```

**Error Types:**
- `scraping`: Application-level errors (invalid data, rate limits, content unavailable)
- `infrastructure`: System-level errors (database connection, MinIO connection, network issues)

## Data Storage

### MinIO Archive
- **Bucket**: `youtube-archive`
- **Format**: Compressed JSON (Zstd)
- **Path**: `{media_save_dir}/{video_id}.json.zst`
- **Content**: Full video metadata, comments, channel info, transcripts, AI summaries

### MongoDB
- **Database**: `youtube_crawl`
- **Collections**: `crawl_jobs`, `search_sessions`, `content`, `authors`, `comments`
- **Note**: Controlled by `save_to_db_enabled` in payload (default: true)

### Media Files
- **Bucket**: `smap-stt-audio-files`
- **Format**: MP3 (audio) or MP4 (video)
- **Path**: `{media_save_dir}/{video_id}.{ext}`
- **Note**: Audio files are converted via FFmpeg service if needed

## Special Features

### Speech-to-Text (STT)
- Automatically transcribes audio files when `stt_api_enabled: true` in settings
- Generates presigned URLs for STT service access
- Transcripts stored in video metadata

### AI Summaries (Gemini)
- Optional AI-generated summaries when `gemini_enabled: true` in settings
- Requires `GEMINI_API_KEY` environment variable
- Summaries stored in video metadata

### FFmpeg Service Integration
- Remote FFmpeg service for audio extraction
- Circuit breaker pattern for resilience
- Automatic retry with exponential backoff

## Best Practices

1. **Batch Processing**: Use `crawl_links` with multiple URLs for better performance
2. **Rate Limiting**: Worker respects YouTube rate limits automatically
3. **Error Handling**: Always check `success` field in response
4. **Job Tracking**: Provide custom `job_id` for easier tracking
5. **Media Downloads**: Set `media_download_enabled: false` if you only need metadata
6. **Database Persistence**: Set `save_to_db_enabled: false` if you only need MinIO archive
7. **Channel Crawling**: Use `limit` parameter to avoid crawling entire large channels

## Environment Variables

Key settings that can be overridden:

```bash
# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_QUEUE_NAME=youtube_crawl_queue
RABBITMQ_EXCHANGE=youtube_exchange
RABBITMQ_ROUTING_KEY=youtube.crawl

# MinIO
MINIO_ENDPOINT=localhost:9000
MINIO_BUCKET=smap-stt-audio-files
MINIO_ARCHIVE_BUCKET=youtube-archive

# MongoDB
MONGODB_HOST=localhost
MONGODB_DATABASE=youtube_crawl

# Defaults (can be overridden per-message)
MEDIA_DOWNLOAD_ENABLED=true
ENABLE_DB_PERSISTENCE=true

# Optional Services
STT_API_ENABLED=true
STT_API_URL=http://172.16.21.230/transcribe
GEMINI_ENABLED=false
MEDIA_FFMPEG_SERVICE_URL=http://ffmpeg-service:8000
```

## Support

For issues or questions, check:
- Worker logs: `scrapper/youtube/logs/`
- Configuration: `scrapper/youtube/config/settings.py`
- Task service: `scrapper/youtube/application/task_service.py`
