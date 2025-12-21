# Section 5.6: Mẫu giao tiếp & tích hợp - Implementation Plan (REDUCED SCOPE)

**Status:** ⚠️ TODO
**Estimated Time:** 8-10 hours (Reduced from 12-16 hours)
**Priority:** 🟡 MEDIUM
**Output File:** `report/chapter_5/section_5_6.typ`
**Dependencies:** Sections 5.1-5.5 completed ✅

**Scope Reduction Strategy:**
- Focus on implemented features only
- Reduce diagram count: 5 → 3
- Simplify event schemas: Full JSON → Table format
- Prometheus metrics: Detailed catalog → Summary table
- Distributed Tracing: Mark as "Future Work" with brief description

---

## 🎯 Câu hỏi mà Section này trả lời

| # | Câu hỏi | Sub-section | Traceability |
|---|---------|-------------|--------------|
| 1 | Các dịch vụ giao tiếp với nhau bằng cách nào? Tại sao? | 5.6.1 | AC-2, AC-5 |
| 2 | Events nào trong hệ thống? Routing và DLQ? | 5.6.2 | FR-2, NFR-R1 |
| 3 | Real-time updates hoạt động ra sao? | 5.6.3 | UC-03, UC-08 |
| 4 | Hệ thống được monitor như thế nào? | 5.6.4 | Section 5.1, NFR-A1 |

---

## 📂 Cấu trúc Section

```
== 5.6 Mẫu giao tiếp & tích hợp

Introduction (1 paragraph)

=== 5.6.1 Mẫu giao tiếp
    - REST API Pattern: Use cases, technology, performance
    - Event-Driven Pattern: Async processing, benefits
    - WebSocket Pattern: Real-time communication
    - Claim Check Pattern: Large payload handling
    - Table: Pattern comparison

=== 5.6.2 Kiến trúc hướng sự kiện
    - RabbitMQ Topology: Exchanges, queues, bindings
    - Event Catalog: Table với 6 events chính
    - Dead Letter Queue: Configuration, retry policy
    - Diagram: RabbitMQ topology với DLQ

=== 5.6.3 Giao tiếp thời gian thực
    - WebSocket + Redis Pub/Sub architecture
    - Horizontal scaling strategy
    - Message types và flow
    - Diagram: WebSocket flow

=== 5.6.4 Giám sát hệ thống
    - Structured Logging: Zap, Loguru, JSON format
    - Prometheus Metrics: Summary table by service
    - Health Checks: Shallow vs Deep probes
    - Distributed Tracing: Brief overview (Future Work)

=== Tổng kết
```

---

## 📝 Nội dung chi tiết

### 5.6.1 Mẫu giao tiếp (2 hours) 🔴 HIGH

**Nội dung:**

**1. Introduction paragraph** (5 mins)
- Hệ thống SMAP sử dụng 3 patterns chính: REST, Event-Driven, WebSocket
- Tại sao cần multiple patterns thay vì single pattern

**2. Pattern Comparison Table** (30 mins)

| Pattern | Use Cases | Technology | When to Use | Example |
|---------|-----------|------------|-------------|---------|
| REST API | CRUD, Query | Echo (Go), FastAPI (Python) | User-facing sync ops, < 30s | GET /projects |
| Event-Driven | Long tasks, Decoupling | RabbitMQ + amqp091-go | Async processing, > 30s | project.created |
| WebSocket | Real-time updates | Gorilla WS + Redis Pub/Sub | Push notifications, progress | Crisis alerts |

**3. REST API Pattern** (30 mins)
- Table: Key endpoints (5-7 examples from Project, Analytics, Identity APIs)
- Performance: Target P95 < 200ms
- Authentication: JWT Bearer tokens
- Code reference: `services/*/api/handlers/*.go`

**4. Event-Driven Pattern** (30 mins)
- Why async: UC-03 crawling takes 5-30 mins (user would timeout)
- Benefits: Scalability, resilience, temporal decoupling
- Technology: RabbitMQ Topic exchange
- Code reference: `services/collector/pkg/messaging/`

**5. WebSocket Pattern** (15 mins)
- Use cases: Progress tracking (UC-03), Crisis alerts (UC-08)
- Technology: Gorilla WebSocket + Redis Pub/Sub
- Scalability: Multi-instance via Redis broadcast
- Code reference: `services/websocket/internal/`

**6. Claim Check Pattern** (15 mins)
- Problem: Crawl batches 2-5MB (too large for RabbitMQ)
- Solution: Upload to MinIO, send reference via RabbitMQ
- Benefits: RabbitMQ message 1KB instead of 5MB
- Code reference: `services/collector/pkg/storage/minio.go`

**Diagram: SKIP** (save time)

---

### 5.6.2 Kiến trúc hướng sự kiện (3-4 hours) 🔴 HIGH

**Nội dung:**

**1. RabbitMQ Topology** (1.5 hours)

**Table: Exchange Configuration**

| Exchange | Type | Purpose |
|----------|------|---------|
| `smap.events` | Topic | Main event bus |
| `smap.dlx` | Direct | Dead letter exchange |

**Table: Queue Configuration**

| Queue | Routing Key | Consumer | Max Length | TTL | DLQ |
|-------|-------------|----------|------------|-----|-----|
| `collector.project-created` | `project.created` | Collector | 10000 | 7d | `collector.dlq` |
| `analytics.data-collected` | `data.collected` | Analytics | 50000 | 7d | `analytics.dlq` |
| `websocket.notifications` | `notification.*` | WebSocket | 5000 | 1d | `websocket.dlq` |

**Binding rules:**
- Topic exchange: Flexible routing với patterns
- Wildcard support: `notification.*` matches `notification.sent`, etc.

**Code reference:** `services/collector/config/rabbitmq.yaml`

**2. Event Catalog** (1 hour)

**Table: Events với Schema Summary**

| Event | Publisher | Consumer | Trigger | Payload Key Fields |
|-------|-----------|----------|---------|-------------------|
| `project.created` | Project API | Collector | User clicks "Khởi chạy" | project_id, user_id, keywords, date_range, platforms |
| `data.collected` | Collector | Analytics | Crawler finishes batch | project_id, batch_id, storage_reference (MinIO key), metadata |
| `analytics.completed` | Analytics | Collector | Analytics finishes batch | project_id, batch_id, results_count |
| `crisis.detected` | Analytics | WebSocket | Triple-check met | project_id, post_id, severity, risk_score, sentiment |
| `trend.detected` | Trend Service | WebSocket | Daily cron | trend_id, platform, hashtag, score |
| `export.completed` | Export Worker | WebSocket | Report generated | project_id, export_id, download_url |

**Note:** Full JSON schemas có thể reference từ code
- `services/collector/pkg/events/types.go`
- `services/analytic/domain/events.py`

**Versioning:** `version` field trong event, backward compatibility

**3. Dead Letter Queue** (1 hour)

**DLQ Configuration:**
- Retry policy: Exponential backoff (1s, 10s, 60s)
- Max retries: 3
- After 3 failures → Route to DLQ
- Retention: 7 days
- Replay: Manual via admin tool

**Table: Retry Behavior**

| Attempt | Delay | Action |
|---------|-------|--------|
| 1 | Immediate | Process |
| 2 | 1s | Retry |
| 3 | 10s | Retry |
| 4 | 60s | Retry |
| Failed | - | → DLQ |

**Monitoring:**
- Prometheus metric: `rabbitmq_queue_messages{queue="*.dlq"}`
- Alert: DLQ depth > 10 → Page on-call

**Code reference:** `services/collector/pkg/messaging/retry.go`

**Diagram: RabbitMQ Topology with DLQ** (1 diagram - ESSENTIAL)
- Show: Exchanges, Queues, Bindings, DLQ flow

---

### 5.6.3 Giao tiếp thời gian thực (1.5-2 hours) 🟡 MEDIUM

**Nội dung:**

**1. WebSocket + Redis Pub/Sub Architecture** (45 mins)

**Problem:** WebSocket connections stateful → How to scale?

**Solution:**
```
[Analytics] → Redis Pub/Sub channel "user:123"
                    ↓ Broadcast
    [WS Instance 1] - Has user:123 → Send
    [WS Instance 2] - No user:123 → Ignore
    [WS Instance 3] - No user:123 → Ignore
```

**Channel Structure:**
- `user:{user_id}` - User-specific
- `project:{project_id}` - Project-specific
- `broadcast` - System-wide

**Scalability:** 1 instance = 1000 connections, horizontal scaling via Redis

**2. Message Types** (30 mins)

**Table: WebSocket Message Types**

| Type | Direction | Example Payload | Frequency |
|------|-----------|-----------------|-----------|
| `auth` | Client → Server | `{type: "auth", token: "jwt"}` | Once |
| `progress_update` | Server → Client | `{type: "progress", project_id, phase, percent}` | 1-5s |
| `crisis_alert` | Server → Client | `{type: "crisis", post_id, severity, ...}` | Ad-hoc |
| `completion` | Server → Client | `{type: "completion", project_id}` | Once |

**3. Connection Lifecycle** (15 mins)
- Connect → Auth (JWT) → Subscribe channel → Heartbeat (30s ping/pong) → Disconnect
- Reconnection: Exponential backoff (1s, 2s, 4s, max 60s)

**Code reference:**
- `services/websocket/internal/handlers/connection.go`
- `services/websocket/pkg/pubsub/redis.go`

**Diagram: WebSocket Flow** (1 diagram - SIMPLIFIED)
- Show: Client → WS Service → Redis Pub/Sub → Multi-instance broadcast

---

### 5.6.4 Giám sát hệ thống (2-3 hours) 🔴 CRITICAL

**Nội dung:**

**1. Structured Logging** (30 mins)

**Log Levels Policy:**

| Level | Use Case | Retention |
|-------|----------|-----------|
| DEBUG | Development only | 1 day |
| INFO | Normal operations | 7 days |
| WARN | Recoverable errors | 30 days |
| ERROR | Service errors | 90 days |

**JSON Format:**
- Go (Zap): `{"level":"info", "timestamp":"...", "service":"collector", "trace_id":"...", "message":"..."}`
- Python (Loguru): Same format

**Code reference:**
- `services/collector/pkg/logger/zap.go`
- `services/analytic/config/logging.py`

**2. Prometheus Metrics** (1 hour)

**Metrics Summary by Service:**

**Collector Service:**
- `collector_jobs_dispatched_total{platform}` (Counter)
- `collector_jobs_completed_total{platform}` (Counter)
- `collector_jobs_failed_total{platform, reason}` (Counter)
- `collector_jobs_active{platform}` (Gauge)

**Analytics Service:**
- `analytics_pipeline_executions_total{status}` (Counter)
- `analytics_pipeline_duration_seconds{phase}` (Histogram)
- `analytics_crisis_detected_total{severity}` (Counter)

**Project API:**
- `http_requests_total{method, path, status}` (Counter)
- `http_request_duration_seconds{method, path}` (Histogram)
- `db_connections_active` (Gauge)

**WebSocket Service:**
- `websocket_connections_active` (Gauge)
- `websocket_messages_sent_total{type}` (Counter)

**Scrape config:** Prometheus scrapes `/metrics` every 15s

**Code reference:** `services/*/pkg/metrics/prometheus.go`

**3. Health Checks** (45 mins)

**Two Types:**

**Shallow Probe: `/health`**
- Check: Process alive
- Response time: < 100ms
- Used by: Load balancer
- Kubernetes: `livenessProbe`
- Response: `{"status": "healthy", "uptime": 3600}`

**Deep Probe: `/ready`**
- Check: PostgreSQL, RabbitMQ, Redis, MinIO connections
- Response time: < 500ms
- Used by: Kubernetes `readinessProbe`
- Response: `{"status": "ready", "checks": {"database": "ok", "rabbitmq": "ok", ...}}`

**Failure behavior:**
- `/health` fail → Restart pod
- `/ready` fail → Remove from service endpoints (no traffic)

**Kubernetes probe config:**
```yaml
livenessProbe:
  httpGet: /health
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet: /ready
  periodSeconds: 5
  failureThreshold: 2
```

**Code reference:**
- `services/collector/internal/api/health.go`
- `services/project/k8s/deployment.yaml`

**4. Distributed Tracing** (30 mins - BRIEF)

**Current Implementation:**
- Trace ID generation: UUID at entry point (Web UI)
- Propagation: HTTP header `X-Trace-ID`, RabbitMQ message properties
- Logging: All services log trace_id
- Debugging: Manual `grep "trace-abc123"` across logs

**Future Work:**
- OpenTelemetry instrumentation
- Jaeger backend for visualization
- Auto-span creation at service boundaries

**Code reference:** `services/project/pkg/middleware/tracing.go`

---

## ⏱️ Timeline

| Sub-section | Thời gian | Độ ưu tiên | Deliverables |
|-------------|-----------|------------|--------------|
| 5.6.1 Mẫu giao tiếp | 2 hours | 🔴 HIGH | 4 patterns + 2 tables |
| 5.6.2 Event-Driven | 3-4 hours | 🔴 HIGH | Topology + Event catalog + DLQ + 1 diagram |
| 5.6.3 Real-time | 1.5-2 hours | 🟡 MEDIUM | Architecture + Message types + 1 diagram |
| 5.6.4 Monitoring | 2-3 hours | 🔴 CRITICAL | Logging + Metrics summary + Health checks |
| **Tổng** | **8-10 hours** | - | **2 diagrams, 10+ tables** |

**Scope Reduction vs Detailed Plan:**
- Diagrams: 5 → **2** (save ~1.5h)
- Event schemas: Full JSON → **Summary table** (save ~1h)
- Metrics: Detailed catalog → **Summary** (save ~0.5h)
- Tracing: Full section → **Brief overview** (save ~0.5h)
- Communication patterns: Separate subsections → **Unified table** (save ~1h)

**Total saved:** ~4.5 hours → 12-16h becomes 8-10h

---

## 📎 Diagrams cần vẽ

| # | Diagram | Tool | Time | Section |
|---|---------|------|------|---------|
| 1 | RabbitMQ Topology with DLQ | PlantUML | 1h | 5.6.2 |
| 2 | WebSocket + Redis Pub/Sub Flow | PlantUML | 30m | 5.6.3 |

**Total diagram time:** 1.5 hours

**Diagrams SKIPPED to save time:**
- Communication Patterns Overview (can describe in text + table)
- WebSocket Connection Lifecycle (can describe in text)
- Crisis Alert Flow (covered in UC-08 already)

---

## ✅ Format Checklist

- [ ] Không bold text ngoài header bảng
- [ ] Figures: `#align(center)[]` + `#context` + `#image_counter`
- [ ] Tables: `#context` + `#table_counter`
- [ ] List items dùng `-`
- [ ] Không cloud terminology
- [ ] Có section Tổng kết
- [ ] Cross-references đến Chapter 4
- [ ] Code evidence: File paths trong backticks

---

## 🔗 Traceability Matrix

| Sub-section | Requirements | Evidence |
|-------------|--------------|----------|
| 5.6.1 REST | FR-1, FR-3, FR-4, FR-5 | `services/*/api/*.go` |
| 5.6.1 Event-Driven | FR-2, FR-6, FR-7 | `services/*/messaging/*.go` |
| 5.6.2 DLQ | NFR-R1 (Fault tolerance) | `config/rabbitmq.yaml` |
| 5.6.3 WebSocket | UC-03, UC-08 | `services/websocket/` |
| 5.6.4 Metrics | Section 5.1 (Observability) | `/metrics` endpoints |
| 5.6.4 Health | NFR-A1 (99.5% availability) | `/health` `/ready` |

---

## 📚 Source Code References

- REST: `services/project/internal/api/handlers/`
- Events: `services/collector/pkg/messaging/`
- WebSocket: `services/websocket/internal/`
- Logging: `services/*/pkg/logger/`
- Metrics: `services/*/pkg/metrics/`
- Health: `services/*/internal/api/health.go`
- Config: `services/*/config/rabbitmq.yaml`
- K8s: `services/*/k8s/deployment.yaml`

---

## 🎯 Success Criteria

- [ ] 4 main subsections hoàn thành
- [ ] 2 diagrams vẽ xong và embedded
- [ ] Event catalog với 6 events chính
- [ ] DLQ configuration documented
- [ ] Prometheus metrics summary cho 4 services
- [ ] Health check types explained (shallow vs deep)
- [ ] Code references: Minimum 10 file paths
- [ ] Traceability links đến Chapter 4
- [ ] Format: Pass all checklist
- [ ] Length: 1,200-1,500 lines (vs 1,800-2,200 in detailed plan)

---

## 🚀 Implementation Order

**Day 1 (3-4h):** 5.6.1 + 5.6.2 (no diagram yet)
- Communication patterns với tables
- RabbitMQ topology tables
- Event catalog
- DLQ configuration

**Day 2 (3-4h):** 5.6.2 diagram + 5.6.3 + 5.6.4 logging/metrics
- Vẽ RabbitMQ topology diagram
- WebSocket architecture
- Vẽ WebSocket flow diagram
- Structured logging
- Prometheus metrics summary

**Day 3 (2-3h):** 5.6.4 health checks + tracing + Tổng kết
- Health check implementation
- Distributed tracing brief
- Write Tổng kết
- Review and polish

---

_Created: December 21, 2025_
_Version: REDUCED SCOPE (8-10h target)_
