# Notification Service — Status Document

> Generated from code review: `services/notification/`
> Date: 2026-03-06

---

## 1. Tổng quan

Notification Service là push-only real-time service của SMAP. Được viết bằng Go, dùng Gin + Gorilla WebSocket, Redis Pub/Sub, không có database riêng.

**Hai domain:**
- `websocket` — WebSocket connection management, message routing
- `alert` — Discord webhook dispatch

---

## 2. WebSocket Domain

### 2.1 Flow tổng thể

```text
Backend service
  → Redis PSubscribe channels:
      project:*:user:*
      campaign:*:user:*
      alert:*:user:*
      system:*

Redis Subscriber (subscriber.go)
  → handleMessage(msg)
  → uc.ProcessMessage(channel, payload)

ProcessMessage:
  1. parseChannel(channel)  → extract userID, entityID, channelType
  2. detectMessageType(payload) → heuristic field-sniffing
  3. transformMessage(msgType, payload) → NotificationOutput
  4. hub.SendToUser(userID, json)
  5. If CRISIS_ALERT → alertUC.DispatchCrisisAlert() (Discord)
```

### 2.2 Message Type Detection (quan trọng)

Không có field `type` trong Redis payload. Service dùng **heuristic field-sniffing**:

| Điều kiện | MessageType |
|-----------|-------------|
| `source_id` + `total_records` | `ANALYTICS_PIPELINE` |
| `source_id` + `record_count` | `DATA_ONBOARDING` |
| `alert_type` | `CRISIS_ALERT` |
| `campaign_id` | `CAMPAIGN_EVENT` |
| `system_event` | `SYSTEM` |
| Không match | `ErrUnknownMessageType` |

**Rủi ro:** Nếu publisher gửi payload thiếu các unique fields trên, message sẽ bị drop với `ErrUnknownMessageType`.

### 2.3 Hub Architecture

```go
type Hub struct {
    clients map[*Connection]bool
    users   map[string]map[*Connection]bool  // userID → set of connections
    broadcast chan []byte
    register  chan *Connection
    unregister chan *Connection
    mu sync.RWMutex
}
```

- `run()` goroutine: xử lý register/unregister/broadcast events
- `SendToUser()`: dùng `mu.RLock()`, có thể gọi từ nhiều goroutine song song
- 1 user có thể có nhiều connections (multi-tab)
- Buffer per connection: channel `send` (unbuffered trong code, chú ý)

### 2.4 Connection Lifecycle

- `readPump()`: đọc messages từ client (hiện tại bỏ qua, push-only), xử lý Pong
- `writePump()`: gửi messages từ hub xuống client, Ping ticker (54s interval)
- Timeouts: pongWait=60s, writeWait=10s, maxMessageSize=512 bytes
- Graceful disconnect: readPump defer → `hub.unregister ← conn`

### 2.5 API Endpoints

```text
GET /ws       → WebSocket upgrade (JWT required)
GET /health   → Health check (public)
```

JWT auth: shared secret (HS256), đọc từ Cookie `smap_auth_token` hoặc query param `?token=`.

### 2.6 Message Payload Types (từ types.go)

| Type | Key Fields |
|------|-----------|
| `DATA_ONBOARDING` | `project_id`, `source_id`, `source_name`, `status`, `progress`, `record_count` |
| `ANALYTICS_PIPELINE` | `project_id`, `source_id`, `total_records`, `processed_count`, `progress`, `current_phase` |
| `CRISIS_ALERT` | `project_id`, `severity`, `alert_type`, `current_value`, `threshold`, `affected_aspects` |
| `CAMPAIGN_EVENT` | `campaign_id`, `campaign_name`, `event_type`, `resource_id`, `message` |
| `SYSTEM` | generic map |

---

## 3. Alert Domain

Alert UseCase gửi Discord webhook cho **3 event types** (không chỉ crisis):

| Method | Discord Format |
|--------|---------------|
| `DispatchCrisisAlert` | Rich embed, severity → color (CRITICAL=red, WARNING=orange, INFO=blue) |
| `DispatchDataOnboarding` | Embed với status, progress, record count |
| `DispatchCampaignEvent` | Embed với campaign lifecycle info |

**Lưu ý:** Report cũ mô tả chỉ `CRISIS_ALERT` mới kích hoạt Discord. Code thực tế có 3 dispatch methods. Tuy nhiên cần xem `ProcessMessage` trong usecase để confirm khi nào `DispatchDataOnboarding` và `DispatchCampaignEvent` được gọi — có thể chỉ crisis được forward tự động, 2 cái kia phải gọi thủ công từ caller.

---

## 4. Issues Phát Hiện Từ Code

### 4.1 [CODE QUALITY] Planning Notes Trong Production File

File: [websocket/delivery/redis/subscriber.go](../services/notification/websocket/delivery/redis/subscriber.go#L19-L45)

Lines 19–45 là toàn bộ comment planning notes của developer ("I cannot easily add fields...", "Let's rewrite new.go..."). Cần xóa trước khi merge.

### 4.2 [DESIGN] Message Type Detection Dễ Vỡ

`detectMessageType()` dùng field presence heuristics. Không có explicit `type` field trong Redis message contract. Nếu:
- `DataOnboarding` gửi payload thiếu `record_count` → không match
- `AnalyticsPipeline` thiếu `total_records` → có thể match nhầm sang DataOnboarding

Nên thêm explicit `type` field vào Redis message format.

### 4.3 [MINOR] `subscriberImpl` Struct Không Dùng Đến

`subscriber.go` định nghĩa `type subscriberImpl struct { *subscriber; pubsub *redis.PubSub; ... }` nhưng các methods được định nghĩa trên `*subscriber`. `subscriberImpl` là dấu tích của lần refactor chưa hoàn thiện.

---

## 5. So Sánh Report Cũ vs Code Thực Tế

| Mục | Report Cũ (notification-srv-report.md) | Code Thực Tế |
|-----|----------------------------------------|--------------|
| JWT algorithm | HS256 | HS256 (đúng) |
| Redis channels | project/campaign/alert:crisis/system | project/campaign/alert (all subtypes)/system (đúng nhưng không chỉ crisis) |
| Alert → Discord | Chỉ CRISIS_ALERT | 3 methods: Crisis + DataOnboarding + CampaignEvent |
| Message type detection | Không mô tả | Heuristic field-sniffing, không có explicit `type` field |
| Hub concurrency | "Single goroutine routing" | `run()` goroutine + `sync.RWMutex` cho SendToUser |
| Connection buffer | "256 messages per connection" | Channel `send` không thấy buffer size config (unbuffered trong code) |
| No database | Correct | Correct |

---

## 6. Tình Trạng Tổng Thể

**Implemented và hoạt động:**
- WebSocket connection management (gorilla, readPump/writePump, ping/pong)
- Hub-based routing (user-scoped, multi-connection per user)
- Redis PSubscribe (4 channel patterns)
- Message transformation (5 types)
- Discord alert dispatch (3 types)
- JWT authentication (HS256, cookie hoặc query param)
- Health check endpoint

**Cần fix trước production:**
- Xóa planning comments trong `subscriber.go` (lines 19–45)
- Thêm explicit `type` field vào Redis message contract (tránh heuristic detection fail silently)
- Làm rõ khi nào `DispatchDataOnboarding` và `DispatchCampaignEvent` được trigger (document hoặc wire vào ProcessMessage)
- Xác nhận buffer size cho `send` channel (hiện không thấy buffer config)
