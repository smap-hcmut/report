# RabbitMQ - TikTok Tasks

Queue: `tiktok_tasks` | Durable: Yes | Delivery: Persistent

## Payload chung

```json
{
  "task_id": "uuid-v4",
  "action": "<action>",
  "params": { ... },
  "created_at": "ISO-8601"
}
```

## Actions

### 1. `search`


```json
{ "action": "search", "params": { "keywords": ["review", "unbox"] } }
```

### 2. `post_detail`


```json
{ "action": "post_detail", "params": { "url": "https://www.tiktok.com/@user/video/123" } }
```

### 3. `comments`


```json
{ "action": "comments", "params": { "aweme_id": "760405449", "cursor": 0, "count": 50, "threshold": 0.5 } }
```

### 4. `cookie_check`


```json
{ "action": "cookie_check", "params": {} }
```

### 5. `full_flow`


```json
{ "action": "full_flow", "params": { "keyword": "review iphone", "limit": 3, "threshold": 0.5, "comment_count": 200 } }
```

## API Response (tất cả endpoints trả về ngay)

```json
{
  "message": "Task đã được gửi vào queue, worker sẽ xử lý",
  "task_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "action": "full_flow",
  "queue": "tiktok_tasks",
  "payload": { "task_id": "...", "action": "...", "params": { ... }, "created_at": "..." }
}
```

## Worker Output (lưu vào `output/`)

Filename: `{action}_{task_id[:8]}_{timestamp}.json`

```json
{
  "task_id": "a1b2c3d4-...",
  "action": "full_flow",
  "params": { ... },
  "created_at": "2026-02-24T15:00:00",
  "completed_at": "2026-02-24T15:01:30",
  "result": { ... }
}
```

## Config (`.env`)

```env
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
```
