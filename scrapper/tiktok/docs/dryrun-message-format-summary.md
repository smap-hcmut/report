# Dry-Run Message Format - Simplified

## Overview

The dry-run result message has been simplified to contain only two fields: `success` and `payload`.

## Message Format

### Success Case
```json
{
  "success": true,
  "payload": [
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
        "text": "Easy cooking tutorial for beginners!",
        "duration": 45,
        "hashtags": ["cooking", "tutorial"],
        "sound_name": "Original Sound",
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
        "bio": "Professional chef",
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
          "text": "This looks amazing!",
          "likes": 45,
          "replies_count": 3,
          "published_at": "2024-11-15T09:30:00Z",
          "is_author": false,
          "media": null
        }
      ]
    }
  ]
}
```

### Error Case
```json
{
  "success": false,
  "payload": []
}
```

## Key Changes

### Removed Fields (from top level)
- ❌ `job_id` - Removed from message body
- ❌ `task_type` - Removed from message body
- ❌ `timestamp` - Removed from message body
- ❌ `keyword` - Removed from message body (available in `payload[].meta.keyword_source`)
- ❌ `statistics` - Removed from message body (can be calculated from payload)
- ❌ `sort_by` - Removed from message body
- ❌ `time_range_days` - Removed from message body
- ❌ `error` - Removed from message body (errors result in empty payload)
- ❌ `error_type` - Removed from message body

### Kept Fields
- ✅ `success` - Boolean indicating task success/failure
- ✅ `payload` - Array of video objects (empty on error)

## Benefits

1. **Simpler Structure**: Only 2 top-level fields
2. **Self-Contained Data**: All metadata is within each video object
3. **Easier Parsing**: No need to correlate top-level metadata with payload items
4. **Flexible**: Each video carries its own context (keyword, job_id, etc.)

## Consumer Implementation

### Python Example
```python
import json

async def process_message(message):
    data = json.loads(message.body.decode('utf-8'))
    
    if data['success']:
        print(f"Received {len(data['payload'])} videos")
        for video in data['payload']:
            print(f"Video {video['meta']['id']} from keyword: {video['meta']['keyword_source']}")
    else:
        print("Task failed - empty payload")
```

### Node.js Example
```javascript
function processMessage(msg) {
  const data = JSON.parse(msg.content.toString('utf-8'));
  
  if (data.success) {
    console.log(`Received ${data.payload.length} videos`);
    data.payload.forEach(video => {
      console.log(`Video ${video.meta.id} from keyword: ${video.meta.keyword_source}`);
    });
  } else {
    console.log('Task failed - empty payload');
  }
}
```

## RabbitMQ Configuration

- **Exchange**: `collector.tiktok`
- **Routing Key**: `tiktok.res`
- **Queue**: `tiktok.collector.queue`
- **Content Type**: `application/json`
- **Encoding**: `utf-8`
- **Delivery Mode**: Persistent (2)
