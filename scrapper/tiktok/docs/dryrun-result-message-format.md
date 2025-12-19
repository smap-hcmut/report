# Dry-Run Result Message Format

## Overview

This document describes the message format published by the `_publish_dryrun_result` method in the TikTok scraper service. These messages are published to RabbitMQ for consumption by downstream services.

## RabbitMQ Configuration

### Exchange Details
- **Exchange Name**: `collector.tiktok`
- **Exchange Type**: `direct`
- **Routing Key**: `tiktok.res`
- **Queue Name**: `tiktok.collector.queue`
- **Message Durability**: Persistent (delivery_mode=2)
- **Content Type**: `application/json`
- **Content Encoding**: `utf-8`

### Connection Settings
Configure these environment variables in your consuming service:
```bash
RESULT_EXCHANGE_NAME=collector.tiktok
RESULT_ROUTING_KEY=tiktok.res
RESULT_QUEUE_NAME=tiktok.collector.queue
```

## Message Structure

### Simplified Format

All messages contain only two top-level fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `success` | boolean | Yes | `true` if task completed successfully, `false` if error occurred |
| `payload` | array | Yes | Array of video data objects (empty array on error) |

## Success Message Schema

When `success: true`, the message contains:

### Complete Message Example

```json
{
  "success": true,
  "payload": [
    {
      "meta": { ... },
      "content": { ... },
      "interaction": { ... },
      "author": { ... },
      "comments": [ ... ]
    }
  ]
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful tasks |
| `payload` | array | Array of video data objects in new format (see below) |

## Payload Structure

Each item in the `payload` array represents a successfully scraped video and follows this nested structure:

### Complete Payload Item Example

```json
{
  "meta": {
    "id": "7403599512956112146",
    "platform": "tiktok",
    "job_id": "dryrun-001",
    "crawled_at": "2024-12-02T10:30:00Z",
    "published_at": "2024-11-15T08:20:00Z",
    "permalink": "https://www.tiktok.com/@username/video/7403599512956112146",
    "keyword_source": "cooking tutorial",
    "lang": "vi",
    "region": "VN",
    "pipeline_version": "crawler_tiktok_v3",
    "fetch_status": "success",
    "fetch_error": null
  },
  "content": {
    "text": "Easy cooking tutorial for beginners! #cooking #tutorial",
    "duration": 45,
    "hashtags": ["cooking", "tutorial", "food"],
    "sound_name": "Original Sound - username",
    "category": "Food & Drink",
    "media": null,
    "transcription": null
  },
  "interaction": {
    "views": 125000,
    "likes": 8500,
    "comments_count": 234,
    "shares": 450,
    "saves": 1200,
    "engagement_rate": 0.0731,
    "updated_at": "2024-12-02T10:30:00Z"
  },
  "author": {
    "id": "MS4wLjABAAAA...",
    "name": "Chef John",
    "username": "chefjohn123",
    "followers": 45000,
    "following": 120,
    "likes": 2500000,
    "videos": 350,
    "is_verified": true,
    "bio": "Professional chef sharing easy recipes",
    "avatar_url": null,
    "profile_url": "https://www.tiktok.com/@chefjohn123"
  },
  "comments": [
    {
      "id": "7403600000000000001",
      "parent_id": null,
      "post_id": "7403599512956112146",
      "user": {
        "id": null,
        "name": "foodlover99",
        "avatar_url": null
      },
      "text": "This looks amazing! Will try it tonight",
      "likes": 45,
      "replies_count": 3,
      "published_at": "2024-11-15T09:30:00Z",
      "is_author": false,
      "media": null
    }
  ]
}
```

### Payload Field Descriptions

#### Meta Section
| Field | Type | Description |
|-------|------|-------------|
| `meta.id` | string | TikTok video ID (external_id) |
| `meta.platform` | string | Always `"tiktok"` |
| `meta.job_id` | string | Job identifier for tracking |
| `meta.crawled_at` | string/null | ISO 8601 timestamp when video was scraped |
| `meta.published_at` | string/null | ISO 8601 timestamp when video was published |
| `meta.permalink` | string | Full URL to the TikTok video |
| `meta.keyword_source` | string | Search keyword that found this video |
| `meta.lang` | string | Language code (currently hardcoded to `"vi"`) |
| `meta.region` | string | Region code (currently hardcoded to `"VN"`) |
| `meta.pipeline_version` | string | Crawler version identifier |
| `meta.fetch_status` | string | `"success"` or `"error"` |
| `meta.fetch_error` | string/null | Error message if fetch failed |

#### Content Section
| Field | Type | Description |
|-------|------|-------------|
| `content.text` | string | Video description/caption |
| `content.duration` | integer/null | Video duration in seconds |
| `content.hashtags` | array | List of hashtag strings (without #) |
| `content.sound_name` | string/null | Name of the audio track used |
| `content.category` | string/null | Video category |
| `content.media` | object/null | **Always `null` in dry-run mode** (no media downloaded) |
| `content.transcription` | string/null | Audio transcription if available |

#### Interaction Section
| Field | Type | Description |
|-------|------|-------------|
| `interaction.views` | integer/null | View count |
| `interaction.likes` | integer/null | Like count |
| `interaction.comments_count` | integer/null | Comment count |
| `interaction.shares` | integer/null | Share count |
| `interaction.saves` | integer/null | Save/bookmark count |
| `interaction.engagement_rate` | float | Calculated as (likes + comments + shares) / views |
| `interaction.updated_at` | string/null | ISO 8601 timestamp of last metric update |

#### Author Section
| Field | Type | Description |
|-------|------|-------------|
| `author.id` | string | TikTok user ID |
| `author.name` | string | Display name |
| `author.username` | string | Username (without @) |
| `author.followers` | integer/null | Follower count |
| `author.following` | integer/null | Following count |
| `author.likes` | integer/null | Total likes received |
| `author.videos` | integer/null | Total video count |
| `author.is_verified` | boolean | Verification status |
| `author.bio` | string/null | Profile biography |
| `author.avatar_url` | null | Avatar URL (not currently scraped) |
| `author.profile_url` | string | Full profile URL |

#### Comments Section
Each comment object contains:

| Field | Type | Description |
|-------|------|-------------|
| `comments[].id` | string | Comment ID |
| `comments[].parent_id` | string/null | Parent comment ID (null for top-level comments) |
| `comments[].post_id` | string | Video ID this comment belongs to |
| `comments[].user.id` | null | Commenter ID (not currently scraped) |
| `comments[].user.name` | string | Commenter username |
| `comments[].user.avatar_url` | null | Commenter avatar (not currently scraped) |
| `comments[].text` | string | Comment text content |
| `comments[].likes` | integer/null | Comment like count |
| `comments[].replies_count` | integer/null | Number of replies |
| `comments[].published_at` | string/null | ISO 8601 timestamp |
| `comments[].is_author` | boolean | True if commenter is the video author |
| `comments[].media` | null | Comment media (not currently supported) |

## Error Message Schema

When `success: false`, the message contains:

```json
{
  "success": false,
  "payload": []
}
```

### Error Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `false` for failed tasks |
| `payload` | array | Always empty array on error |

### Error Handling

When a task fails, the message will have `success: false` and an empty `payload` array. Error details are logged internally but not included in the published message. Consumers should handle empty payloads gracefully.

## Consuming the Messages

### Python Example (aio-pika)

```python
import json
from aio_pika import connect_robust, ExchangeType

async def consume_dryrun_results():
    # Connect to RabbitMQ
    connection = await connect_robust("amqp://guest:guest@localhost/")
    channel = await connection.channel()
    
    # Declare exchange and queue
    exchange = await channel.declare_exchange(
        "collector.tiktok",
        ExchangeType.DIRECT,
        durable=True
    )
    
    queue = await channel.declare_queue(
        "tiktok.collector.queue",
        durable=True
    )
    
    # Bind queue to exchange
    await queue.bind(exchange, routing_key="tiktok.res")
    
    # Consume messages
    async with queue.iterator() as queue_iter:
        async for message in queue_iter:
            async with message.process():
                # Parse JSON message
                data = json.loads(message.body.decode('utf-8'))
                
                # Process based on success status
                if data['success']:
                    print(f"Task succeeded with {len(data['payload'])} videos")
                    
                    # Process each video
                    for video in data['payload']:
                        video_id = video['meta']['id']
                        views = video['interaction']['views']
                        keyword = video['meta']['keyword_source']
                        print(f"  - Video {video_id}: {views} views (keyword: {keyword})")
                else:
                    print("Task failed - empty payload")
```

### Node.js Example (amqplib)

```javascript
const amqp = require('amqplib');

async function consumeDryrunResults() {
  // Connect to RabbitMQ
  const connection = await amqp.connect('amqp://localhost');
  const channel = await connection.createChannel();
  
  // Assert exchange and queue
  await channel.assertExchange('collector.tiktok', 'direct', { durable: true });
  await channel.assertQueue('tiktok.collector.queue', { durable: true });
  await channel.bindQueue('tiktok.collector.queue', 'collector.tiktok', 'tiktok.res');
  
  // Consume messages
  channel.consume('tiktok.collector.queue', (msg) => {
    if (msg !== null) {
      const data = JSON.parse(msg.content.toString('utf-8'));
      
      if (data.success) {
        console.log(`Task succeeded with ${data.payload.length} videos`);
        
        // Process each video
        data.payload.forEach(video => {
          const keyword = video.meta.keyword_source;
          console.log(`  - Video ${video.meta.id}: ${video.interaction.views} views (keyword: ${keyword})`);
        });
      } else {
        console.log('Task failed - empty payload');
      }
      
      channel.ack(msg);
    }
  });
}
```

## Important Notes

### Dry-Run Specific Behavior

1. **No Media Downloads**: The `content.media` field is always `null` in dry-run mode
2. **No Database Persistence**: Videos are scraped but not saved to MongoDB
3. **No MinIO Uploads**: No data is uploaded to object storage
4. **Lightweight Results**: Only metadata and statistics are collected

### Data Availability

Some fields may be `null` depending on:
- TikTok's API response
- Privacy settings of the video/user
- Scraping configuration (e.g., `include_comments`, `include_creator`)

### Timestamp Format

All timestamps use ISO 8601 format with 'Z' suffix indicating UTC:
- Format: `YYYY-MM-DDTHH:MM:SSZ`
- Example: `2024-12-02T10:30:00Z`

### Character Encoding

All text fields are UTF-8 encoded to support international characters, emojis, and special symbols.

## Validation

### Required Field Validation

Consuming services should validate:
1. `success` field is present and is a boolean
2. `payload` field is present and is an array

### Success Message Validation

When `success: true`:
1. `payload` is an array (may be empty if no videos found)
2. Each payload item has required nested structure (`meta`, `content`, `interaction`, `author`, `comments`)

### Error Message Validation

When `success: false`:
1. `payload` is an empty array

## Troubleshooting

### Message Not Received

1. Verify RabbitMQ connection settings
2. Check exchange and queue are properly declared
3. Verify routing key binding: `tiktok.res`
4. Check RabbitMQ logs for connection errors

### Invalid JSON

1. Ensure UTF-8 decoding
2. Check for truncated messages
3. Verify message content_type is `application/json`

### Missing Payload Data

1. Check if videos were successfully scraped (`statistics.successful`)
2. Verify `include_comments` and `include_creator` settings
3. Check scraper logs for individual video failures

## Version History

- **v1.0** (2024-12-02): Initial implementation with nested payload format
  - Added `meta`, `content`, `interaction`, `author`, `comments` sections
  - Implemented `map_to_new_format` transformation
  - Added engagement_rate calculation
