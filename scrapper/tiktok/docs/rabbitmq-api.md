# TikTok Worker - RabbitMQ API Documentation

## Overview

This document describes the RabbitMQ message contract for the TikTok scraper worker. External services can publish messages to trigger crawling tasks.

## Connection Configuration

- **Exchange**: `tiktok_exchange` (durable)
- **Queue**: `tiktok_crawl_queue` (durable)
- **Routing Key**: `tiktok.crawl`
- **Configuration**: Can be overridden via environment variables (see `scrapper/tiktok/config/settings.py`)

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
| `save_to_db_enabled` | boolean | No | false | Enable/disable MongoDB persistence (debug mode) |
| `archive_storage_enabled` | boolean | No | true | Enable/disable MinIO archive storage |

**Note**: Invalid date formats are automatically ignored. `time_range` takes precedence over date range if both are provided.

## Task Types

### 1. research_keyword

Search for TikTok videos by keyword and return video URLs.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keyword` | string | **Yes** | - | Search keyword |
| `limit` | integer | No | 50 | Maximum number of videos to find |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "like", "view", "date" |

**Example:**

```json
{
  "task_type": "research_keyword",
  "payload": {
    "keyword": "cooking tutorial",
    "limit": 100,
    "sort_by": "view",
    "time_range": 7
  },
  "job_id": "search-001"
}
```

**Response**: Returns list of video URLs found.

---

### 2. dryrun_keyword

Search and scrape TikTok videos by keyword without persisting data to storage systems. This task is designed for testing search queries and estimating result volumes before committing to full crawls. Results are published to a separate collector exchange.

**Key Characteristics:**
- ✅ Searches and scrapes video metadata
- ✅ Scrapes comments and creator information (if enabled)
- ❌ Does NOT save data to MongoDB
- ❌ Does NOT upload data to MinIO archive
- ❌ Does NOT download media files
- ✅ Publishes lightweight result messages to collector exchange

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keywords` | array[string] | **Yes** | - | List of search keywords to crawl |
| `keyword` | string | **Yes** (if keywords not provided) | - | Single search keyword (backward compatibility) |
| `limit` | integer | No | 50 | Maximum number of videos to find per keyword |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "like", "view", "date" |
| `include_comments` | boolean | No | true | Scrape video comments (not persisted) |
| `include_creator` | boolean | No | true | Scrape creator information (not persisted) |
| `max_comments` | integer | No | 0 | Maximum comments per video (0 = unlimited) |
| `time_range` | integer | No | - | Number of recent days to filter content (must be >= 1) |
| `since_date` | string | No | - | ISO 8601 date string (e.g., "2024-01-01T00:00:00Z") |
| `until_date` | string | No | - | ISO 8601 date string (e.g., "2024-12-31T23:59:59Z") |

**Storage Options (Hardcoded for Dry-Run):**

The following common payload fields are **automatically disabled** for `dryrun_keyword` and cannot be overridden:

| Field | Dry-Run Value | Description |
|-------|---------------|-------------|
| `media_download_enabled` | false | Media downloads are always disabled |
| `save_to_db_enabled` | false | MongoDB persistence is always disabled |
| `archive_storage_enabled` | false | MinIO archive storage is always disabled |
| `download_media` | false | Media file downloads are always disabled |

**Note**: 
- Use `keywords` (array) for multiple keywords or `keyword` (string) for a single keyword
- `time_range` takes precedence over date range if both are provided
- Invalid date formats are automatically ignored
- Result message is published once after all keywords are successfully crawled
- Storage and persistence options are hardcoded to false and cannot be changed

**Example (Single Keyword - Complete Payload):**

```json
{
  "task_type": "dryrun_keyword",
  "payload": {
    "keyword": "cooking tutorial",
    "limit": 100,
    "sort_by": "view",
    "include_comments": true,
    "include_creator": true,
    "max_comments": 50,
    "time_range": 7,
    "media_download_enabled": false,
    "save_to_db_enabled": false,
    "archive_storage_enabled": false
  },
  "job_id": "dryrun-001"
}
```

**Example (Multiple Keywords - Complete Payload with Time Range):**

```json
{
  "task_type": "dryrun_keyword",
  "payload": {
    "keywords": ["vinfast", "tesla"],
    "limit": 200,
    "sort_by": "like",
    "include_comments": true,
    "include_creator": true,
    "max_comments": 100,
    "time_range": 30,
    "media_download_enabled": false,
    "save_to_db_enabled": false,
    "archive_storage_enabled": false
  },
  "job_id": "dryrun-002"
}
```

**Example (Multiple Keywords - Complete Payload with Date Range):**

```json
{
  "task_type": "dryrun_keyword",
  "payload": {
    "keywords": ["electric car", "ev technology", "sustainable transport"],
    "limit": 150,
    "sort_by": "date",
    "include_comments": true,
    "include_creator": true,
    "max_comments": 50,
    "since_date": "2024-11-01T00:00:00Z",
    "until_date": "2024-11-30T23:59:59Z",
    "media_download_enabled": false,
    "save_to_db_enabled": false,
    "archive_storage_enabled": false
  },
  "job_id": "dryrun-003"
}
```

**Note**: The storage-related fields (`media_download_enabled`, `save_to_db_enabled`, `archive_storage_enabled`) are shown in examples for completeness, but they are hardcoded to `false` in the implementation and will be ignored even if set to `true`.

**Result Message:**

Unlike other task types, `dryrun_keyword` publishes results to a separate collector exchange instead of returning them directly. The result message is published to:

- **Exchange**: `collector.tiktok` (configurable via `RESULT_EXCHANGE_NAME`)
- **Routing Key**: `tiktok.res` (configurable via `RESULT_ROUTING_KEY`)
- **Queue**: `tiktok.collector.queue` (configurable via `RESULT_QUEUE_NAME`)

**Success Result Schema (Multiple Keywords Example):**

```json
{
  "success": true,
  "payload": [
    {
      "meta": {
        "id": "7567280130284915975",
        "platform": "tiktok",
        "job_id": "dryrun-002",
        "crawled_at": "2024-12-02T10:30:00.123456Z",
        "published_at": "2024-11-15T08:20:00.000000Z",
        "permalink": "https://www.tiktok.com/@vinfast_official/video/7567280130284915975",
        "keyword_source": "vinfast",
        "lang": "vi",
        "region": "VN",
        "pipeline_version": "crawler_tiktok_v3",
        "fetch_status": "success",
        "fetch_error": null
      },
      "content": {
        "text": "VinFast VF8 review - Amazing electric SUV! #vinfast #electriccar #ev",
        "duration": 58,
        "hashtags": ["vinfast", "electriccar", "ev", "vf8"],
        "sound_name": "Original Sound - VinFast Official",
        "category": "Automotive",
        "media": null,
        "transcription": null
      },
      "interaction": {
        "views": 250000,
        "likes": 15000,
        "comments_count": 450,
        "shares": 890,
        "saves": 1200,
        "engagement_rate": 0.0652,
        "updated_at": "2024-12-02T10:30:00.123456Z"
      },
      "author": {
        "id": "vinfast_official_id",
        "name": "VinFast Official",
        "username": "vinfast_official",
        "followers": 500000,
        "following": 50,
        "likes": 5000000,
        "videos": 320,
        "is_verified": true,
        "bio": "Official VinFast TikTok - Electric Vehicles for Everyone",
        "avatar_url": null,
        "profile_url": "https://www.tiktok.com/@vinfast_official"
      },
      "comments": [
        {
          "id": "comment_vf_001",
          "parent_id": null,
          "post_id": "7567280130284915975",
          "user": {
            "id": null,
            "name": "ev_enthusiast",
            "avatar_url": null
          },
          "text": "Love this car! When is it coming to my country?",
          "likes": 120,
          "replies_count": 5,
          "published_at": "2024-11-15T09:30:00.000000Z",
          "is_author": false,
          "media": null
        },
        {
          "id": "comment_vf_002",
          "parent_id": "comment_vf_001",
          "post_id": "7567280130284915975",
          "user": {
            "id": null,
            "name": "vinfast_official",
            "avatar_url": null
          },
          "text": "Coming soon! Stay tuned for updates!",
          "likes": 80,
          "replies_count": 0,
          "published_at": "2024-11-15T10:00:00.000000Z",
          "is_author": true,
          "media": null
        }
      ]
    },
    {
      "meta": {
        "id": "7568134380867308818",
        "platform": "tiktok",
        "job_id": "dryrun-002",
        "crawled_at": "2024-12-02T10:31:15.456789Z",
        "published_at": "2024-11-20T14:30:00.000000Z",
        "permalink": "https://www.tiktok.com/@tesla_fan/video/7568134380867308818",
        "keyword_source": "tesla",
        "lang": "vi",
        "region": "VN",
        "pipeline_version": "crawler_tiktok_v3",
        "fetch_status": "success",
        "fetch_error": null
      },
      "content": {
        "text": "Tesla Model 3 acceleration test 0-100km/h #tesla #model3 #electriccar",
        "duration": 42,
        "hashtags": ["tesla", "model3", "electriccar", "acceleration"],
        "sound_name": "Epic Music - Sound Effects",
        "category": "Automotive",
        "media": null,
        "transcription": null
      },
      "interaction": {
        "views": 180000,
        "likes": 12000,
        "comments_count": 320,
        "shares": 650,
        "saves": 890,
        "engagement_rate": 0.0717,
        "updated_at": "2024-12-02T10:31:15.456789Z"
      },
      "author": {
        "id": "tesla_fan_id",
        "name": "Tesla Fan Vietnam",
        "username": "tesla_fan",
        "followers": 85000,
        "following": 120,
        "likes": 2500000,
        "videos": 450,
        "is_verified": false,
        "bio": "Tesla enthusiast sharing EV content",
        "avatar_url": null,
        "profile_url": "https://www.tiktok.com/@tesla_fan"
      },
      "comments": [
        {
          "id": "comment_tesla_001",
          "parent_id": null,
          "post_id": "7568134380867308818",
          "user": {
            "id": null,
            "name": "speed_lover",
            "avatar_url": null
          },
          "text": "Insane acceleration! 🚀",
          "likes": 95,
          "replies_count": 3,
          "published_at": "2024-11-20T15:00:00.000000Z",
          "is_author": false,
          "media": null
        }
      ]
    }
  ]
}
```

**Note**: The payload array contains all successfully crawled videos from all keywords. In this example, the first video is from the "vinfast" keyword and the second is from the "tesla" keyword. The `keyword_source` field in each video's `meta` object indicates which keyword it was found with.

**Error Result Schema:**

```json
{
  "success": false,
  "payload": []
}
```

**Result Message Structure:**

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `success` | boolean | Yes | Whether task completed successfully |
| `payload` | array | Yes | Array of crawled video objects (empty on failure) |

**Payload Object Structure:**

Each object in the `payload` array contains:

- **meta**: Job metadata and crawl information
  - `id`: Video external ID
  - `platform`: Source platform (always "tiktok")
  - `job_id`: Job identifier
  - `crawled_at`: Timestamp when video was crawled
  - `published_at`: Video publication timestamp
  - `permalink`: Video URL
  - `keyword_source`: Search keyword used
  - `lang`: Language code (e.g., "vi")
  - `region`: Region code (e.g., "VN")
  - `pipeline_version`: Crawler version
  - `fetch_status`: "success" or "error"
  - `fetch_error`: Error message if fetch failed

- **content**: Video content data
  - `text`: Video description/caption
  - `duration`: Video duration in seconds
  - `hashtags`: Array of hashtags
  - `sound_name`: Audio track name
  - `category`: Video category
  - `media`: Media object (null in dry-run mode)
  - `transcription`: Audio transcription (if available)

- **interaction**: Engagement metrics
  - `views`: View count
  - `likes`: Like count
  - `comments_count`: Comment count
  - `shares`: Share count
  - `saves`: Save count
  - `engagement_rate`: Calculated engagement rate
  - `updated_at`: Last update timestamp

- **author**: Creator information
  - `id`: Author external ID
  - `name`: Display name
  - `username`: Username
  - `followers`: Follower count
  - `following`: Following count
  - `likes`: Total likes received
  - `videos`: Total video count
  - `is_verified`: Verification status
  - `bio`: Profile bio
  - `avatar_url`: Avatar URL
  - `profile_url`: Profile URL

- **comments**: Array of comment objects (if `include_comments: true`)
  - `id`: Comment external ID
  - `parent_id`: Parent comment ID (null for top-level)
  - `post_id`: Video ID this comment belongs to
  - `user`: Commenter information (id, name, avatar_url)
  - `text`: Comment text
  - `likes`: Comment like count
  - `replies_count`: Number of replies
  - `published_at`: Comment timestamp
  - `is_author`: Whether commenter is the video author
  - `media`: Comment media (if any)

**Use Cases:**
- Testing search queries before full crawls
- Estimating result volumes and comment counts
- Validating keyword effectiveness
- Quick content discovery without storage overhead

**Performance:**
Dry-run tasks execute 2-3x faster than equivalent full crawls due to skipped media downloads and storage operations.

---

### 3. crawl_links

Crawl detailed information from specific TikTok video URLs.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `video_urls` | array[string] | **Yes** | - | List of TikTok video URLs to crawl |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_creator` | boolean | No | true | Fetch creator/author information |
| `max_comments` | integer | No | 0 | Maximum comments per video (0 = unlimited) |
| `keyword` | string | No | - | Associated keyword (for tracking) |
| `download_media` | boolean | No | true | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./downloads" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | false | Save to MongoDB (debug mode) |
| `archive_storage_enabled` | boolean | No | true | Save to MinIO archive |

**Example:**

```json
{
  "task_type": "crawl_links",
  "payload": {
    "video_urls": [
      "https://www.tiktok.com/@user/video/1234567890",
      "https://www.tiktok.com/@user/video/0987654321"
    ],
    "include_comments": true,
    "max_comments": 50,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": false,
    "archive_storage_enabled": true,
    "time_range": 30
  }
}
```

**Response**: Returns crawl statistics and MinIO keys for archived data.

---

### 4. research_and_crawl

Combined operation: search for videos by keywords and immediately crawl them.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `keywords` | array[string] | **Yes** | - | List of search keywords |
| `limit_per_keyword` | integer | No | 50 | Max videos per keyword |
| `sort_by` | string | No | "relevance" | Sort order: "relevance", "like", "view", "date" |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_creator` | boolean | No | true | Fetch creator information |
| `max_comments` | integer | No | 0 | Max comments per video (0 = unlimited) |
| `download_media` | boolean | No | true | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./downloads" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | false | Save to MongoDB (debug mode) |
| `archive_storage_enabled` | boolean | No | true | Save to MinIO archive |

**Example:**

```json
{
  "task_type": "research_and_crawl",
  "payload": {
    "keywords": ["cooking", "baking", "recipes"],
    "limit_per_keyword": 20,
    "sort_by": "view",
    "include_comments": true,
    "max_comments": 100,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": false,
    "archive_storage_enabled": true,
    "since_date": "2024-01-01T00:00:00Z",
    "until_date": "2024-12-31T23:59:59Z"
  }
}
```

**Response**: Returns aggregated results for all keywords with crawl statistics.

---

### 5. fetch_profile_content

Crawl all videos from a TikTok user profile.

**Payload Parameters:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `profile_url` | string | **Yes** | - | TikTok profile URL (e.g., https://www.tiktok.com/@username) |
| `include_comments` | boolean | No | true | Fetch video comments |
| `include_creator` | boolean | No | true | Fetch creator information |
| `max_comments` | integer | No | 0 | Max comments per video (0 = unlimited) |
| `download_media` | boolean | No | true | Download audio/video files |
| `media_type` | string | No | "audio" | Media type: "audio" or "video" |
| `media_save_dir` | string | No | "./downloads" | MinIO storage prefix |
| `media_download_enabled` | boolean | No | true | Global media download toggle |
| `save_to_db_enabled` | boolean | No | false | Save to MongoDB (debug mode) |
| `archive_storage_enabled` | boolean | No | true | Save to MinIO archive |

**Example:**

```json
{
  "task_type": "fetch_profile_content",
  "payload": {
    "profile_url": "https://www.tiktok.com/@gordonramsay",
    "include_comments": true,
    "max_comments": 50,
    "download_media": true,
    "media_type": "audio",
    "media_download_enabled": true,
    "save_to_db_enabled": false,
    "archive_storage_enabled": true,
    "time_range": 90
  }
}
```

**Response**: Returns profile crawl statistics and MinIO keys.

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
  "minio_keys_count": 8,
  "download_media": true,
  "media_type": "audio"
}
```

### Error Response

```json
{
  "job_id": "uuid-or-custom-id",
  "success": false,
  "error": "Error message with details",
  "error_type": "scraping"
}
```

**Error Types:**
- `scraping`: Application-level errors (invalid data, rate limits, content unavailable)
- `infrastructure`: System-level errors (database connection, MinIO connection, network issues)

## Data Storage

### MinIO Archive
- **Bucket**: `tiktok-archive`
- **Format**: Compressed JSON (Zstd)
- **Path**: `{media_save_dir}/{video_id}.json.zst`
- **Content**: Full video metadata, comments, creator info, media URLs

### MongoDB (Debug Mode)
- **Database**: `tiktok_crawl`
- **Collections**: `crawl_jobs`, `search_sessions`, `content`, `authors`, `comments`
- **Note**: Only enabled when `save_to_db_enabled: true` in payload

### Media Files
- **Bucket**: `tiktok-media`
- **Format**: MP3 (audio) or MP4 (video)
- **Path**: `{media_save_dir}/{video_id}.{ext}`

## Best Practices

1. **Batch Processing**: Use `crawl_links` with multiple URLs for better performance
2. **Rate Limiting**: Worker has built-in rate limiting (20 requests/minute by default)
3. **Error Handling**: Always check `success` field in response
4. **Job Tracking**: Provide custom `job_id` for easier tracking
5. **Media Downloads**: Set `media_download_enabled: false` if you only need metadata
6. **Database Persistence**: Keep `save_to_db_enabled: false` in production (use MinIO archive)

## Environment Variables

Key settings that can be overridden:

```bash
# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_QUEUE_NAME=tiktok_crawl_queue
RABBITMQ_EXCHANGE=tiktok_exchange
RABBITMQ_ROUTING_KEY=tiktok.crawl

# MinIO
MINIO_ENDPOINT=localhost:9000
MINIO_BUCKET=tiktok-media
MINIO_ARCHIVE_BUCKET=tiktok-archive

# MongoDB
MONGODB_HOST=localhost
MONGODB_DATABASE=tiktok_crawl

# Defaults (can be overridden per-message)
MEDIA_DOWNLOAD_ENABLED=true
ENABLE_DB_PERSISTENCE=false

# Result Publisher (for dryrun_keyword tasks)
RESULT_PUBLISHER_ENABLED=true
RESULT_EXCHANGE_NAME=collector.tiktok
RESULT_ROUTING_KEY=tiktok.res
RESULT_QUEUE_NAME=tiktok.collector.queue
```

## Support

For issues or questions, check:
- Worker logs: `scrapper/tiktok/logs/`
- Configuration: `scrapper/tiktok/config/settings.py`
- Task service: `scrapper/tiktok/application/task_service.py`
