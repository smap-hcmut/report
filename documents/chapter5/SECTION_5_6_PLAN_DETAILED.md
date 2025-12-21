# Section 5.6: Mẫu giao tiếp & tích hợp - DETAILED Implementation Plan

**Status:** ⚠️ TODO
**Estimated Time:** 12-16 hours (REVISED from 8-10 hours)
**Priority:** 🟡 MEDIUM
**Output File:** `report/chapter_5/section_5_6.typ`
**Dependencies:** Sections 5.1-5.5 completed ✅

---

## 🎯 Câu hỏi mà Section này trả lời

Section 5.6 mô tả **cách thức giao tiếp và tích hợp** giữa các services trong hệ thống SMAP, trả lời các câu hỏi:

| # | Câu hỏi chi tiết | Sub-section | Traceability |
|---|------------------|-------------|--------------|
| 1 | Các dịch vụ trong hệ thống giao tiếp với nhau bằng cách nào? Tại sao chọn pattern này? | 5.6.1 | AC-2 (Scalability), AC-5 (Maintainability) |
| 2 | Hệ thống xử lý các tác vụ bất đồng bộ như thế nào? Event flow ra sao? | 5.6.2 | FR-2 (Thực thi Project), NFR-P1 (Response time) |
| 3 | Có những events nào trong hệ thống? Schema của chúng là gì? | 5.6.2 | UC-03, UC-08 (Event-driven flows) |
| 4 | Xử lý lỗi message như thế nào? Dead Letter Queue hoạt động ra sao? | 5.6.2 | NFR-R1 (Fault tolerance) |
| 5 | Làm sao người dùng nhận được cập nhật real-time? Scalability? | 5.6.3 | UC-03 (Monitor), UC-08 (Crisis alert) |
| 6 | Hệ thống được giám sát như thế nào? Metrics, logs, traces? | 5.6.4 | Section 5.1 (Observability-Driven Dev) |
| 7 | Health checks hoạt động ra sao? Shallow vs Deep probe? | 5.6.4 | NFR-A1 (Availability 99.5%) |
| 8 | Distributed tracing cho phép debug cross-service issues thế nào? | 5.6.4 | NFR-M2 (Debuggability) |

---

## 📂 Cấu trúc Section (EXPANDED)

```
== 5.6 Mẫu giao tiếp & tích hợp

Introduction (1 paragraph)
- Overview của 3 patterns chính: REST, Event-Driven, WebSocket
- Tại sao cần nhiều patterns thay vì single pattern
- Forward reference đến subsections

=== 5.6.1 Mẫu giao tiếp
    ==== 5.6.1.1 REST API Pattern
        - Request/Response synchronous
        - Use cases: CRUD operations, query operations
        - Technology: Echo (Go), FastAPI (Python)
        - Evidence: API endpoints catalog

    ==== 5.6.1.2 Event-Driven Pattern
        - Asynchronous processing
        - Use cases: Long-running tasks, decoupling
        - Technology: RabbitMQ
        - Evidence: Event catalog

    ==== 5.6.1.3 WebSocket Pattern
        - Bidirectional real-time
        - Use cases: Progress tracking, alerts
        - Technology: Gorilla WebSocket + Redis Pub/Sub

    ==== 5.6.1.4 Claim Check Pattern
        - Large payload handling
        - Implementation: MinIO + RabbitMQ reference
        - Performance benefits: Reduce queue memory

=== 5.6.2 Kiến trúc hướng sự kiện
    ==== 5.6.2.1 RabbitMQ Topology
        - Exchange types: Topic, Direct
        - Queue configurations
        - Binding rules
        - Diagram: Full topology với all services

    ==== 5.6.2.2 Event Catalog với Schemas
        - project.created schema
        - data.collected schema
        - crisis.detected schema
        - trend.detected schema
        - notification.sent schema
        - Versioning strategy

    ==== 5.6.2.3 Dead Letter Queue Configuration
        - DLQ topology
        - Retry policy: Exponential backoff
        - Retention: 7 days
        - Replay mechanism
        - Monitoring: Dead letter metrics

=== 5.6.3 Giao tiếp thời gian thực
    ==== 5.6.3.1 WebSocket Architecture
        - Connection management
        - Authentication flow (JWT)
        - Heartbeat mechanism
        - Reconnection strategy

    ==== 5.6.3.2 Redis Pub/Sub Integration
        - Channel structure
        - Message routing
        - Fan-out pattern
        - Horizontal scaling (multi-instance)

    ==== 5.6.3.3 Message Types và Flow
        - Progress updates
        - Completion notifications
        - Crisis alerts
        - Diagram: End-to-end message flow

=== 5.6.4 Giám sát hệ thống
    ==== 5.6.4.1 Structured Logging
        - Log levels và policies
        - JSON format standardization
        - Go: Zap configuration
        - Python: Loguru configuration
        - Centralized logging (future: ELK)

    ==== 5.6.4.2 Prometheus Metrics
        - Metrics types: Counters, Histograms, Gauges
        - Service-level metrics catalog:
          * Collector: jobs_dispatched, jobs_completed, jobs_failed
          * Analytics: pipeline_duration, batch_size, crisis_detected_total
          * Project API: http_requests_total, http_request_duration
          * WebSocket: connections_active, messages_sent_total
        - Scrape configuration
        - Retention policy

    ==== 5.6.4.3 Health Checks
        - Shallow probes (/health):
          * Check: Service process alive
          * Response time: < 100ms
          * Used by: Load balancer
        - Deep probes (/ready):
          * Check: Dependencies (DB, RabbitMQ, Redis)
          * Response time: < 500ms
          * Used by: Kubernetes readiness
        - Implementation examples per service

    ==== 5.6.4.4 Distributed Tracing
        - Trace ID generation
        - Propagation: HTTP headers, RabbitMQ message properties
        - Span creation: Service boundaries
        - Implementation: OpenTelemetry (optional/future)
        - Debugging workflow example

=== Tổng kết
    - Recap 3 communication patterns
    - Event-driven architecture benefits
    - Observability stack completeness
    - Traceability đến requirements (AC-2, AC-5, NFR-R1, NFR-A1)
```

---

## 📝 Nội dung chi tiết từng Sub-section

### 5.6.1 Mẫu giao tiếp (3-4 hours) 🔴 HIGH PRIORITY

**Mô tả:** Hệ thống SMAP sử dụng **3 patterns giao tiếp chính**, mỗi pattern phục vụ use case riêng biệt. Section này giải thích **why not a single pattern**, demonstrating architectural maturity.

**Nội dung cần viết:**

#### 5.6.1.1 REST API Pattern (45 mins)

**Table: REST API Use Cases**

| Service | Endpoint Example | Purpose | Synchronous? | Evidence (Code) |
|---------|------------------|---------|--------------|-----------------|
| Project API | `GET /api/v1/projects` | List projects | Yes | `services/project/internal/api/handlers/project.go` |
| Project API | `POST /api/v1/projects` | Create project | Yes | Same |
| Project API | `DELETE /api/v1/projects/:id` | Soft delete | Yes | Same |
| Analytics API | `GET /api/v1/analytics/dashboard` | Query results | Yes | `services/analytic/app/api/v1/analytics.py` |
| Identity API | `POST /api/v1/auth/login` | Authenticate | Yes | `services/identity/internal/api/handlers/auth.go` |

**Khi nào dùng REST:**
- User-facing CRUD operations
- Query operations cần immediate response
- Short-lived requests (< 30s timeout)

**Technology stack:**
- Go services: Echo framework
- Python services: FastAPI
- Authentication: JWT Bearer tokens
- Serialization: JSON

**Performance characteristics:**
- Target latency: P95 < 200ms (NFR-P1)
- Timeout: 30s client-side
- Rate limiting: 100 req/min per user (NFR-S2)

#### 5.6.1.2 Event-Driven Pattern (1 hour)

**Table: Event-Driven Use Cases**

| Event | Publisher | Consumer | Why async? | Response time if sync |
|-------|-----------|----------|------------|-----------------------|
| `project.created` | Project API | Collector | Crawling takes 5-30 mins | User would timeout |
| `data.collected` | Collector | Analytics | NLP pipeline takes 2-10 mins | Blocks crawler |
| `crisis.detected` | Analytics | WebSocket | Fire-and-forget notification | N/A |

**Khi nào dùng Event-Driven:**
- Long-running tasks (> 30s)
- Decoupling: Publisher không cần biết consumer
- Fan-out: 1 event → multiple consumers
- Retry semantics: Built-in với RabbitMQ

**Benefits so với REST:**
- Scalability: Consumers scale independently
- Resilience: Queue buffers peak loads
- Temporal decoupling: Publisher/consumer availability independent

**Technology stack:**
- Message broker: RabbitMQ 3.12+
- Go client: `github.com/rabbitmq/amqp091-go`
- Python client: `pika`
- Exchange type: Topic exchange for routing flexibility

#### 5.6.1.3 WebSocket Pattern (45 mins)

**Table: WebSocket Use Cases**

| Use Case | Message Direction | Frequency | Why not HTTP polling? |
|----------|-------------------|-----------|------------------------|
| Progress tracking | Server → Client | Every 1-5s | Polling wastes bandwidth |
| Crisis alerts | Server → Client | Ad-hoc | Need instant delivery |
| Heartbeat | Bidirectional | Every 30s | Connection keep-alive |

**Khi nào dùng WebSocket:**
- Real-time updates cần push từ server
- High-frequency updates (polling inefficient)
- Bidirectional communication

**Technology stack:**
- Go: `github.com/gorilla/websocket`
- Redis Pub/Sub: Broadcast giữa WebSocket instances
- Message format: JSON

**Scalability:**
- Multiple WebSocket instances: Load balancer sticky sessions
- Redis Pub/Sub: Fan-out messages đến all instances
- Target: 1000 concurrent connections per instance

#### 5.6.1.4 Claim Check Pattern (45 mins)

**Diagram: Claim Check Flow**
```
[Crawler] → Upload 5MB batch → [MinIO]
              ↓
         Get object key
              ↓
    Publish {object_key, metadata} → [RabbitMQ] (only 1KB message)
              ↓
         [Analytics] receives message
              ↓
    Download batch from MinIO using object_key
```

**Problem statement:**
- Crawl batches: 20-50 items × ~100KB each = 2-5MB per batch
- RabbitMQ in-memory queue: Large messages cause OOM risk
- Latency: Network transfer to queue slow

**Solution: Claim Check Pattern**
1. Crawler uploads batch to MinIO (object storage)
2. Crawler publishes lightweight message với object key reference
3. Analytics downloads batch from MinIO when ready

**Benefits:**
- RabbitMQ message size: 1KB instead of 5MB
- Memory efficiency: Queue only holds references
- Decoupling: Storage lifecycle independent of queue

**Implementation evidence:**
- `services/collector/pkg/storage/minio.go` - Upload logic
- `services/analytic/infrastructure/storage.py` - Download logic

**Diagram cần vẽ:** Communication Patterns Overview (1 diagram showing all 4 patterns)

---

### 5.6.2 Kiến trúc hướng sự kiện (4-5 hours) 🔴 HIGH PRIORITY

**Mô tả:** RabbitMQ là **message broker trung tâm** của hệ thống. Section này mô tả topology, event schemas, và error handling mechanisms (DLQ).

**Nội dung cần viết:**

#### 5.6.2.1 RabbitMQ Topology (2 hours)

**Diagram: Full RabbitMQ Topology** (1 comprehensive diagram)
- Exchanges: `smap.events` (topic), `smap.dlx` (dead letter exchange)
- Queues:
  - `collector.project-created`
  - `analytics.data-collected`
  - `websocket.notifications`
  - `*.dlq` (dead letter queues)
- Bindings: Routing key patterns

**Table: Exchange Configuration**

| Exchange Name | Type | Durable | Purpose |
|---------------|------|---------|---------|
| `smap.events` | Topic | Yes | Main event bus |
| `smap.dlx` | Direct | Yes | Dead letter exchange |

**Table: Queue Configuration**

| Queue Name | Bound to Exchange | Routing Key | Consumer | Max Length | TTL | DLQ |
|------------|-------------------|-------------|----------|------------|-----|-----|
| `collector.project-created` | `smap.events` | `project.created` | Collector Service | 10000 | 7d | `collector.dlq` |
| `analytics.data-collected` | `smap.events` | `data.collected` | Analytics Service | 50000 | 7d | `analytics.dlq` |
| `websocket.notifications` | `smap.events` | `notification.*` | WebSocket Service | 5000 | 1d | `websocket.dlq` |

**Binding rules:**
- Topic exchange cho flexibility
- Routing key pattern: `{entity}.{action}` (e.g., `project.created`, `data.collected`)
- Wildcard support: `notification.*` matches `notification.sent`, `notification.failed`

**Configuration evidence:**
- `services/collector/config/rabbitmq.yaml`
- `infrastructure/rabbitmq/definitions.json` (vhost setup)

#### 5.6.2.2 Event Catalog với JSON Schemas (1.5 hours)

**Expanded Event Catalog Table:**

| Event Name | Publisher | Consumer(s) | Routing Key | Trigger Condition | Frequency |
|------------|-----------|-------------|-------------|-------------------|-----------|
| `project.created` | Project Service | Collector | `project.created` | User clicks "Khởi chạy" | ~10/day |
| `data.collected` | Collector | Analytics | `data.collected` | Crawler finishes batch | ~500/project |
| `analytics.completed` | Analytics | Collector | `analytics.completed` | Analytics finishes batch | ~500/project |
| `crisis.detected` | Analytics | WebSocket, Notification | `crisis.detected` | Triple-check criteria met | ~1-5/project |
| `trend.detected` | Trend Service | WebSocket | `trend.detected` | Daily cron job | 1/day |
| `notification.sent` | Notification Service | Audit Log | `notification.sent` | After sending email/push | Ad-hoc |

**JSON Schema Examples:**

**Event: `project.created`**
```json
{
  "event_id": "uuid",
  "event_type": "project.created",
  "timestamp": "2025-12-21T10:30:00Z",
  "version": "1.0",
  "payload": {
    "project_id": "uuid",
    "user_id": "uuid",
    "brand_keywords": ["nike", "just do it"],
    "competitor_keywords": ["adidas", "puma"],
    "date_range": {
      "start": "2025-12-01",
      "end": "2025-12-20"
    },
    "platforms": ["tiktok", "youtube"]
  }
}
```

**Event: `data.collected`**
```json
{
  "event_id": "uuid",
  "event_type": "data.collected",
  "timestamp": "2025-12-21T10:35:00Z",
  "version": "1.0",
  "payload": {
    "project_id": "uuid",
    "batch_id": "uuid",
    "storage_reference": {
      "bucket": "smap-raw-data",
      "object_key": "projects/{project_id}/batches/{batch_id}.json"
    },
    "metadata": {
      "platform": "tiktok",
      "keyword": "nike",
      "item_count": 45,
      "size_bytes": 2485760
    }
  }
}
```
**Note:** `storage_reference` implements Claim Check pattern

**Event: `crisis.detected`**
```json
{
  "event_id": "uuid",
  "event_type": "crisis.detected",
  "timestamp": "2025-12-21T10:40:00Z",
  "version": "1.0",
  "priority": "high",
  "payload": {
    "project_id": "uuid",
    "post_id": "uuid",
    "brand": "nike",
    "severity": "critical",
    "risk_score": 0.92,
    "sentiment": "very_negative",
    "intent": "crisis",
    "excerpt": "Nike shoes caused injury...",
    "url": "https://tiktok.com/@user/video/123"
  }
}
```

**Versioning strategy:**
- `version` field trong mọi event
- Backward compatibility: Consumers ignore unknown fields
- Schema evolution: Add optional fields only
- Breaking changes: Bump version → new routing key

#### 5.6.2.3 Dead Letter Queue Configuration (1.5 hours)

**Problem statement:**
- Message processing failures: Network error, DB timeout, malformed data
- Cần retry mechanism để tăng resilience
- Tránh infinite retry loops (poison messages)

**DLQ Topology Diagram** (1 diagram)
```
[Main Queue] → Consumer fails → [DLX: smap.dlx] → [DLQ: {service}.dlq]
                      ↓
                After 3 retries
                      ↓
              Manual intervention or replay
```

**Table: DLQ Configuration**

| Main Queue | DLQ Name | Max Retries | Retry Delay | Retention | Replay Mechanism |
|------------|----------|-------------|-------------|-----------|------------------|
| `collector.project-created` | `collector.dlq` | 3 | Exponential: 1s, 10s, 60s | 7 days | Manual replay via admin tool |
| `analytics.data-collected` | `analytics.dlq` | 3 | Exponential: 1s, 10s, 60s | 7 days | Same |

**Retry Policy: Exponential Backoff**
- Attempt 1: Immediate
- Attempt 2: After 1s (x-delay header)
- Attempt 3: After 10s
- Attempt 4: After 60s
- After 3 retries → Route to DLQ

**Implementation:**
- RabbitMQ headers: `x-death` count, `x-first-death-reason`
- Consumer logic: Check retry count, apply delay
- Code reference: `services/collector/pkg/messaging/retry.go`

**DLQ Monitoring:**
- Prometheus metric: `rabbitmq_queue_messages{queue="*.dlq"}`
- Alert: If DLQ depth > 10 → Page on-call engineer
- Dashboard: Grafana panel showing DLQ trends

**Replay Mechanism:**
- Admin tool: `tools/rabbitmq-replay.go`
- Steps:
  1. Fetch message from DLQ
  2. Fix root cause (e.g., restore DB)
  3. Re-publish to main queue
  4. Ack DLQ message

**Code evidence:**
- `services/collector/config/rabbitmq.yaml` - DLX binding
- `services/collector/pkg/messaging/consumer.go` - Retry logic

---

### 5.6.3 Giao tiếp thời gian thực (2-3 hours) 🟡 MEDIUM PRIORITY

**Mô tả:** WebSocket + Redis Pub/Sub architecture cho **real-time updates**. Giải quyết vấn đề horizontal scaling của WebSocket stateful connections.

**Nội dung cần viết:**

#### 5.6.3.1 WebSocket Architecture (1 hour)

**Connection Lifecycle Diagram** (1 diagram)
```
[Client] → WS Handshake → [WebSocket Service Instance A]
              ↓
         Auth: JWT validation
              ↓
         Subscribe: Redis channel "user:{user_id}"
              ↓
         Heartbeat: Ping every 30s
              ↓
    Message flow: Backend → Redis Pub/Sub → WS → Client
              ↓
         Disconnect: Unsubscribe Redis channel
```

**Table: WebSocket Message Types**

| Message Type | Direction | JSON Schema | Frequency | Purpose |
|--------------|-----------|-------------|-----------|---------|
| `auth` | Client → Server | `{type: "auth", token: "jwt"}` | Once on connect | Authenticate connection |
| `subscribe` | Client → Server | `{type: "subscribe", channels: ["project:123"]}` | Once/multiple | Subscribe to topics |
| `ping` | Bidirectional | `{type: "ping"}` | Every 30s | Keep-alive |
| `progress_update` | Server → Client | `{type: "progress", project_id, phase, percent}` | Every 1-5s | Progress tracking |
| `crisis_alert` | Server → Client | `{type: "crisis", post_id, severity, ...}` | Ad-hoc | Crisis notification |
| `completion` | Server → Client | `{type: "completion", project_id}` | Once | Project done |

**Authentication Flow:**
1. Client sends `auth` message with JWT token
2. WebSocket Service validates JWT (same logic as REST API)
3. Extract `user_id` from JWT claims
4. Associate connection with `user_id`
5. Subscribe to Redis channel `user:{user_id}`

**Heartbeat Mechanism:**
- Client sends `ping` every 30s
- Server responds `pong` immediately
- If no ping for 90s → Server closes connection (client assumed dead)
- If no pong for 60s → Client reconnects

**Reconnection Strategy:**
- Client detects disconnection
- Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 60s
- Re-authenticate with JWT
- Re-subscribe to channels
- Request missed messages (sequence number tracking)

**Code evidence:**
- `services/websocket/internal/handlers/connection.go` - Connection manager
- `services/websocket/internal/auth/jwt.go` - JWT validation
- `services/web-ui/src/lib/websocket.ts` - Client reconnection

#### 5.6.3.2 Redis Pub/Sub Integration (1 hour)

**Problem: Horizontal Scaling Challenge**
- WebSocket connections are stateful (stick to specific instance)
- User A connects to Instance 1, User B to Instance 2
- Backend service (Analytics) needs to notify User A
- How does Analytics know which instance has User A's connection?

**Solution: Redis Pub/Sub Fan-out**
```
[Analytics Service] → Publish to Redis channel "user:A"
         ↓
   [Redis Pub/Sub] → Broadcast to ALL WebSocket instances
         ↓
   [Instance 1] - Has User A connection → Sends message
   [Instance 2] - No User A connection → Ignores
   [Instance 3] - No User A connection → Ignores
```

**Channel Structure:**

| Channel Pattern | Publisher | Subscriber | Message Content |
|-----------------|-----------|------------|-----------------|
| `user:{user_id}` | Analytics, Collector, Notification | WebSocket instances | User-specific notifications |
| `project:{project_id}` | Collector, Analytics | WebSocket instances | Project-specific updates |
| `broadcast` | Admin Service | WebSocket instances | System-wide announcements |

**Scalability Analysis:**
- 1 WebSocket instance: ~1000 concurrent connections
- 3 instances: ~3000 users supported
- Redis Pub/Sub overhead: ~1KB/message × 10 messages/s = 10KB/s (negligible)

**Code evidence:**
- `services/websocket/pkg/pubsub/redis.go` - Redis Pub/Sub client
- `services/analytic/infrastructure/notification.py` - Publish logic

#### 5.6.3.3 End-to-End Message Flow (1 hour)

**Comprehensive Diagram: Real-time Crisis Alert Flow** (1 diagram)
```
[Analytics] detects crisis
      ↓
Redis.Publish("user:123", crisis_message)
      ↓
[Redis Pub/Sub] broadcasts to subscribers
      ↓
[WS Instance 1] has user:123 connection
      ↓
WS.Send(crisis_message) to client
      ↓
[Web UI] receives message
      ↓
Show notification banner + Play sound + Browser notification
```

**Performance Characteristics:**
- End-to-end latency: P95 < 500ms (Analytics publish → Client receives)
- Message delivery guarantee: At-most-once (Redis Pub/Sub, not persistent)
- Acceptable loss: Crisis alerts also stored in DB for query

**Message Examples:**

**Progress Update:**
```json
{
  "type": "progress_update",
  "project_id": "uuid",
  "phase": "crawling",
  "progress": {
    "done": 45,
    "total": 500,
    "percent": 9
  },
  "eta_seconds": 1200
}
```

**Crisis Alert:**
```json
{
  "type": "crisis_alert",
  "project_id": "uuid",
  "post": {
    "id": "uuid",
    "brand": "nike",
    "platform": "tiktok",
    "severity": "critical",
    "excerpt": "Nike shoes caused injury...",
    "url": "https://..."
  },
  "timestamp": "2025-12-21T10:40:00Z"
}
```

---

### 5.6.4 Giám sát hệ thống (3-4 hours) 🔴 CRITICAL PRIORITY

**Mô tả:** Section này là **implementation của Observability-Driven Development** (Section 5.1 principle). Covers logging, metrics, health checks, và distributed tracing.

**Traceability:**
- Section 5.1.4: Observability-Driven Development principle
- NFR-M1: System monitoring
- NFR-M2: Debuggability
- NFR-A1: 99.5% availability (needs health checks)

**Nội dung cần viết:**

#### 5.6.4.1 Structured Logging (1 hour)

**Log Levels and Policies:**

| Level | When to Use | Example | Retention |
|-------|-------------|---------|-----------|
| DEBUG | Development only | Function entry/exit, variable values | 1 day |
| INFO | Normal operations | Request received, task completed | 7 days |
| WARN | Recoverable errors | Retry after timeout, fallback used | 30 days |
| ERROR | Service errors | DB connection failed, API call failed | 90 days |
| FATAL | Unrecoverable | Cannot start service, critical dependency down | Forever |

**JSON Format Standardization:**

**Go services (Zap):**
```json
{
  "level": "info",
  "timestamp": "2025-12-21T10:30:00Z",
  "service": "collector",
  "trace_id": "abc123",
  "message": "Project created event consumed",
  "project_id": "uuid",
  "user_id": "uuid"
}
```

**Python services (Loguru):**
```json
{
  "level": "INFO",
  "time": "2025-12-21T10:30:00Z",
  "service": "analytics",
  "trace_id": "abc123",
  "message": "NLP pipeline completed",
  "project_id": "uuid",
  "duration_ms": 1234
}
```

**Configuration evidence:**
- `services/collector/pkg/logger/zap.go` - Zap config
- `services/analytic/config/logging.py` - Loguru config

**Future: Centralized Logging (ELK Stack)**
- Filebeat ships logs → Logstash → Elasticsearch
- Kibana dashboards for log analysis
- NOT implemented yet, mentioned as future work

#### 5.6.4.2 Prometheus Metrics (1.5 hours) 🔴 CRITICAL

**Metrics Types Explanation:**

| Type | Purpose | Example | When Resets |
|------|---------|---------|-------------|
| Counter | Monotonic increasing count | `http_requests_total` | Never (only increases) |
| Gauge | Current value (can go up/down) | `connections_active` | N/A |
| Histogram | Distribution of values | `http_request_duration_seconds` | Never |
| Summary | Like histogram, quantiles | `batch_processing_duration` | Never |

**Service-Level Metrics Catalog:**

**Collector Service:**
```
# Jobs dispatched
collector_jobs_dispatched_total{platform="tiktok|youtube"} (Counter)

# Jobs completed successfully
collector_jobs_completed_total{platform="tiktok|youtube"} (Counter)

# Jobs failed
collector_jobs_failed_total{platform="tiktok|youtube", reason="timeout|error"} (Counter)

# Current active jobs
collector_jobs_active{platform="tiktok|youtube"} (Gauge)

# Job processing duration
collector_job_duration_seconds{platform="tiktok|youtube"} (Histogram)
  Buckets: [1, 5, 10, 30, 60, 120, 300]
```

**Analytics Service:**
```
# Pipeline executions
analytics_pipeline_executions_total{status="success|failure"} (Counter)

# Pipeline duration
analytics_pipeline_duration_seconds{phase="preprocessing|nlp|scoring"} (Histogram)
  Buckets: [0.1, 0.5, 1, 5, 10, 30, 60]

# Batch size processed
analytics_batch_size_items (Histogram)
  Buckets: [10, 20, 30, 50, 100]

# Crisis detected
analytics_crisis_detected_total{severity="high|critical"} (Counter)

# Sentiment distribution
analytics_sentiment_total{sentiment="positive|neutral|negative|very_negative"} (Counter)
```

**Project API:**
```
# HTTP requests
http_requests_total{method="GET|POST|DELETE", path="/projects|/analytics", status="200|400|500"} (Counter)

# Request duration
http_request_duration_seconds{method, path} (Histogram)
  Buckets: [0.01, 0.05, 0.1, 0.2, 0.5, 1, 2]

# Active database connections
db_connections_active (Gauge)

# Database query duration
db_query_duration_seconds{query_type="select|insert|update"} (Histogram)
```

**WebSocket Service:**
```
# Active connections
websocket_connections_active (Gauge)

# Messages sent
websocket_messages_sent_total{type="progress|alert|completion"} (Counter)

# Connection duration
websocket_connection_duration_seconds (Histogram)
  Buckets: [10, 60, 300, 600, 1800, 3600]
```

**Scrape Configuration:**
- Prometheus scrapes `/metrics` endpoint every 15s
- All services expose Prometheus-format metrics
- Port: 9090 (standard Prometheus metrics port)

**Retention:**
- Raw metrics: 15 days
- Aggregated (1h): 90 days

**Code evidence:**
- `services/collector/pkg/metrics/prometheus.go` - Metrics registration
- `services/analytic/infrastructure/metrics.py` - Python metrics
- `infrastructure/prometheus/prometheus.yml` - Scrape config

#### 5.6.4.3 Health Checks (1 hour) 🔴 CRITICAL

**Two Types of Probes:**

**Shallow Probe: `/health`**
- **Purpose:** Is the service process alive?
- **Checks:**
  - Service process running
  - HTTP server responding
- **Does NOT check:** Dependencies (DB, RabbitMQ, Redis)
- **Response time:** < 100ms (fast)
- **Used by:** Load balancer to route traffic
- **Kubernetes:** `livenessProbe`
- **Response format:**
  ```json
  {
    "status": "healthy",
    "service": "collector",
    "uptime_seconds": 3600
  }
  ```

**Deep Probe: `/ready`**
- **Purpose:** Is the service ready to handle requests?
- **Checks:**
  - PostgreSQL connection (ping)
  - RabbitMQ connection (ping)
  - Redis connection (ping)
  - MinIO connection (bucket exists)
- **Response time:** < 500ms (slower)
- **Used by:** Kubernetes `readinessProbe`
- **Behavior:** If NOT ready → Remove from service endpoints (no traffic)
- **Response format:**
  ```json
  {
    "status": "ready",
    "checks": {
      "database": "ok",
      "rabbitmq": "ok",
      "redis": "ok",
      "storage": "ok"
    },
    "response_time_ms": 245
  }
  ```

**Failure Scenarios:**

| Scenario | `/health` Response | `/ready` Response | Kubernetes Action |
|----------|-------------------|-------------------|-------------------|
| Service starting up | 200 OK | 503 Not Ready | No traffic yet |
| DB connection lost | 200 OK | 503 Not Ready (db: failed) | Remove from endpoints |
| Service crashed | No response | No response | Restart pod |
| Service deadlocked | 200 OK (but timeout) | 503 (timeout) | Restart pod after liveness fail |

**Implementation per Service:**

**Collector Service:**
```go
// /health - Shallow
func HealthHandler(c echo.Context) error {
    return c.JSON(200, map[string]interface{}{
        "status": "healthy",
        "uptime": time.Since(startTime).Seconds(),
    })
}

// /ready - Deep
func ReadyHandler(c echo.Context) error {
    checks := map[string]string{}

    // Check PostgreSQL
    if err := db.Ping(ctx); err != nil {
        checks["database"] = "failed"
        return c.JSON(503, map[string]interface{}{"status": "not ready", "checks": checks})
    }
    checks["database"] = "ok"

    // Check RabbitMQ
    if !rabbitConn.IsHealthy() {
        checks["rabbitmq"] = "failed"
        return c.JSON(503, ...)
    }
    checks["rabbitmq"] = "ok"

    // ... check Redis, MinIO ...

    return c.JSON(200, map[string]interface{}{"status": "ready", "checks": checks})
}
```

**Kubernetes Configuration Example:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 3  # Restart after 3 failures

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 5
  failureThreshold: 2  # Remove from endpoints after 2 failures
```

**Code evidence:**
- `services/collector/internal/api/health.go`
- `services/project/k8s/deployment.yaml` - Probe configs
- `services/analytic/app/api/health.py`

#### 5.6.4.4 Distributed Tracing (1 hour) 🟡 MEDIUM (Future Work)

**Problem Statement:**
- Microservices: 1 user request → 5-10 service calls
- Example: UC-03 Execute Project
  1. User → Web UI
  2. Web UI → Project API (POST /projects/:id/execute)
  3. Project API → PostgreSQL (UPDATE status)
  4. Project API → Redis (SET state)
  5. Project API → RabbitMQ (PUBLISH project.created)
  6. Collector → RabbitMQ (CONSUME event)
  7. Collector → Redis (UPDATE state)
  8. Collector → RabbitMQ (PUBLISH job)
  9. Crawler → ...
- **Question:** If request fails at step 6, how to trace back?

**Solution: Trace ID Propagation**

**Trace ID Generation:**
- Entry point (Web UI): Generate UUID trace_id
- Format: `trace-{uuid}` (e.g., `trace-abc123`)

**Propagation Mechanisms:**

**HTTP Headers:**
```
X-Trace-ID: trace-abc123
```
- Web UI → Project API: Include in request header
- Project API → Analytics API: Forward header
- All services log with trace_id

**RabbitMQ Message Properties:**
```json
{
  "headers": {
    "trace_id": "trace-abc123"
  },
  "payload": {...}
}
```
- Project API publishes event with trace_id in headers
- Collector extracts trace_id from message properties
- Collector includes trace_id in logs

**Span Creation:**
- Each service creates a span (segment of trace)
- Span includes: service name, operation, start time, end time
- Example spans in UC-03:
  - Span 1: `project-api:execute-project` (200ms)
  - Span 2: `collector:consume-event` (50ms)
  - Span 3: `collector:dispatch-jobs` (500ms)

**Visualization (Future):**
- Tool: Jaeger or Zipkin (NOT implemented yet)
- Trace timeline showing all spans
- Identify bottlenecks: Which span took longest?
- Error attribution: Which service failed?

**Implementation (Current):**
- Trace ID logged in all services (manual correlation)
- Example log query: `grep "trace-abc123" /var/log/*.log`
- Manual debugging workflow

**OpenTelemetry (Future):**
- Standard library for tracing
- Auto-instrumentation for frameworks (Echo, FastAPI)
- Export to Jaeger backend

**Code evidence:**
- `services/project/pkg/middleware/tracing.go` - Trace ID extraction
- `services/collector/pkg/messaging/consumer.go` - Trace ID from RabbitMQ
- Currently only logs trace_id, no distributed tracing backend

**Debugging Workflow Example:**
1. User reports: "Project execution failed"
2. Check Web UI logs for trace_id
3. `grep "trace-abc123"` across all service logs
4. Reconstruct timeline:
   - 10:30:00 - Project API received request
   - 10:30:01 - RabbitMQ publish succeeded
   - 10:30:05 - Collector consumed event
   - 10:30:06 - Redis SET failed (ERROR log)
5. Root cause: Redis connection timeout
6. Fix: Increase Redis timeout config

---

## ⏱️ Revised Timeline

| Sub-section | Thời gian | Độ ưu tiên | Deliverables |
|-------------|-----------|------------|--------------|
| 5.6.1 Mẫu giao tiếp | 3-4 hours | 🔴 HIGH | 4 subsections + 1 diagram |
| 5.6.2 Kiến trúc hướng sự kiện | 4-5 hours | 🔴 HIGH | 3 subsections + 2 diagrams + Event schemas + DLQ config |
| 5.6.3 Giao tiếp thời gian thực | 2-3 hours | 🟡 MEDIUM | 3 subsections + 2 diagrams |
| 5.6.4 Giám sát hệ thống | 3-4 hours | 🔴 CRITICAL | 4 subsections + Metrics catalog + Health check impl |
| **Tổng** | **12-16 hours** | - | **14 subsections + 5 diagrams** |

**Rationale for 12-16 hours (vs 8-10):**
- Added Dead Letter Queue configuration (1.5h)
- Added detailed Prometheus Metrics catalog (1.5h)
- Added Distributed Tracing section (1h)
- Added JSON schemas for all events (1h)
- Expanded Health Checks to distinguish shallow/deep (0.5h)
- More comprehensive diagrams (1h)

---

## 📎 Diagrams cần vẽ (EXPANDED)

| # | Diagram Name | Tool | Estimated Time | Section |
|---|--------------|------|----------------|---------|
| 1 | Communication Patterns Overview | PlantUML Component | 30 mins | 5.6.1 |
| 2 | RabbitMQ Full Topology | PlantUML Deployment | 1 hour | 5.6.2.1 |
| 3 | Dead Letter Queue Flow | PlantUML Sequence | 30 mins | 5.6.2.3 |
| 4 | WebSocket Connection Lifecycle | PlantUML Sequence | 30 mins | 5.6.3.1 |
| 5 | End-to-End Crisis Alert Flow | PlantUML Sequence | 30 mins | 5.6.3.3 |

**Total diagram time:** ~3 hours

---

## ✅ Format Checklist (Same as before)

- [ ] Không bold text ngoài header bảng
- [ ] Figures: `#align(center)[]` + `#context` + `#image_counter`
- [ ] Tables: `#context` + `#table_counter`
- [ ] List items dùng `-`
- [ ] Không cloud terminology (Kubernetes OK, AWS/GCP/Azure NOT OK)
- [ ] Có section Tổng kết
- [ ] Cross-references đến Chapter 4 (FRs, NFRs, UCs)
- [ ] Code evidence: File paths trong backticks

---

## 🔗 Traceability Matrix (NEW)

| Sub-section | Requirements | Architecture Decisions | Evidence |
|-------------|--------------|------------------------|----------|
| 5.6.1 REST | FR-1, FR-3, FR-4, FR-5 | ADR-REST: Synchronous user-facing ops | `services/*/api/*.go` |
| 5.6.1 Event-Driven | FR-2, FR-6, FR-7 | ADR-RabbitMQ: Async long-running tasks | `services/*/messaging/*.go` |
| 5.6.2 RabbitMQ | NFR-R1 (Fault tolerance) | DLQ + Retry policy | `config/rabbitmq.yaml` |
| 5.6.3 WebSocket | UC-03, UC-08 | Redis Pub/Sub for scaling | `services/websocket/` |
| 5.6.4 Metrics | Section 5.1 (Observability) | Prometheus metrics | `/metrics` endpoints |
| 5.6.4 Health | NFR-A1 (99.5% availability) | Shallow + Deep probes | `/health` `/ready` |
| 5.6.4 Tracing | NFR-M2 (Debuggability) | Trace ID propagation | Logs với trace_id |

---

## 📚 Source Code References (EXPANDED)

### REST API:
- `services/project/internal/api/handlers/project.go` - CRUD endpoints
- `services/analytic/app/api/v1/analytics.py` - Analytics queries
- `services/identity/internal/api/handlers/auth.go` - Authentication

### Event-Driven:
- `services/collector/pkg/messaging/consumer.go` - RabbitMQ consumer
- `services/analytic/infrastructure/messaging.py` - Event publishing
- `services/project/pkg/events/publisher.go` - Event publishing

### WebSocket:
- `services/websocket/internal/handlers/connection.go` - Connection management
- `services/websocket/pkg/pubsub/redis.go` - Redis Pub/Sub
- `services/web-ui/src/lib/websocket.ts` - Client-side WebSocket

### Monitoring:
- `services/collector/pkg/logger/zap.go` - Structured logging
- `services/collector/pkg/metrics/prometheus.go` - Metrics
- `services/project/internal/api/health.go` - Health checks
- `services/project/k8s/deployment.yaml` - Kubernetes probes

### Configuration:
- `services/collector/config/rabbitmq.yaml` - RabbitMQ config
- `infrastructure/rabbitmq/definitions.json` - Exchange/Queue definitions
- `infrastructure/prometheus/prometheus.yml` - Scrape config

---

## 🎯 Success Criteria

Section 5.6 is considered DONE when:

- [ ] All 4 main subsections completed với 14 sub-subsections total
- [ ] 5 diagrams vẽ xong và embedded vào Typst
- [ ] Event schemas documented cho 6 events chính
- [ ] Dead Letter Queue configuration chi tiết
- [ ] Prometheus metrics catalog cho 4 services chính
- [ ] Health check implementation examples (shallow + deep)
- [ ] Distributed tracing workflow documented (even if not fully implemented)
- [ ] Code evidence: Minimum 15 file path references
- [ ] Traceability: Links đến Chapter 4 requirements
- [ ] Format: Pass all checklist items
- [ ] Length: 1,800-2,200 lines (comparable to Section 5.3)
- [ ] Quality: Academic tone, technical depth, no fluff

---

## 🚀 Implementation Order (Recommended)

1. **Day 1 (4-5 hours):** 5.6.1 + 5.6.2.1 + 5.6.2.2
   - Write communication patterns overview
   - Create RabbitMQ topology diagram
   - Document event schemas

2. **Day 2 (4-5 hours):** 5.6.2.3 + 5.6.3
   - DLQ configuration
   - WebSocket architecture
   - Redis Pub/Sub integration
   - Create 2 diagrams (DLQ flow, WebSocket lifecycle)

3. **Day 3 (4-6 hours):** 5.6.4 + Tổng kết
   - Structured logging
   - Prometheus metrics catalog (most detailed)
   - Health checks implementation
   - Distributed tracing
   - Write Tổng kết
   - Review and polish

---

_Created: December 21, 2025_
_Revised: December 21, 2025 (from 8-10h to 12-16h, added DLQ, Prometheus, Tracing details)_
