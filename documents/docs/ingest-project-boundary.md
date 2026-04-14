# SMAP Service Review & Ingest–Project Boundary Analysis

**Ngày:** 06/03/2026
**Tác giả:** Nguyễn Tấn Tài
**Trạng thái:** Draft - Cần review

---

## Phần 1: Đánh giá 4 service đã hoàn thành

### 1.1 Identity Service (auth-srv)

**Trạng thái:** Production Ready

**Làm được gì:**

- OAuth2 login qua Google, JWT HS256, RBAC 3 cấp (ADMIN / ANALYST / VIEWER)
- Token blacklist qua Redis cho instant revocation
- Internal API `POST /internal/validate` cho service-to-service auth
- Audit log async qua Kafka topic `audit.events`

**Đánh giá kiến trúc:**
Service này có boundary rõ nhất trong toàn hệ thống. Nó không phụ thuộc vào bất kỳ service business nào, chỉ expose JWT token và validate. Mọi service khác là consumer của Identity, không có chiều ngược lại.

**Vấn đề hiện tại:**

| # | Vấn đề | Mức độ | Ghi chú |
| --- | --- | --- | --- |
| 1 | HS256 dùng shared secret — nếu lộ, toàn bộ hệ thống bị compromise | Medium | Workaround: secret lưu trong K8s Secret. Nâng lên RS256 trong sprint 2 |
| 2 | Audit log query chậm khi data vượt 1M rows | Low | Cần thêm index theo `user_id + created_at` |
| 3 | OAuth state param không được cleanup khi flow thất bại | Low | Redis TTL tự cleanup sau 5 phút |

**Nhận xét tổng quan:** Ổn. Không có rủi ro blocking. Chỉ cần migrate sang RS256 trước khi production thật sự.

---

### 1.2 Notification Service (notification-srv)

**Trạng thái:** Production Ready

**Làm được gì:**

- WebSocket connection manager, JWT auth, routing theo `user_id` và `project_id`
- Subscribe Redis Pub/Sub, nhận event từ mọi service backend
- Discord Rich Embed cho crisis alert
- Graceful shutdown, ping/pong keepalive, ~10k concurrent connections

**Đánh giá kiến trúc:**
Service này là pure delivery layer — nhận từ Redis, đẩy ra WebSocket hoặc Discord. Không có database riêng, không có business logic. Đây là thiết kế đúng nhất trong hệ thống: stateless, push-only, không service nào cần gọi ngược lại nó.

**Vấn đề hiện tại:**

| # | Vấn đề | Mức độ | Ghi chú |
| --- | --- | --- | --- |
| 1 | Connection leak khi client ngắt đột ngột | Medium | Workaround: ping/pong timeout cleanup sau 60s |
| 2 | Message bị mất nếu client disconnect (không có persistence) | Medium | Frontend cần poll REST API để sync khi reconnect |
| 3 | Không có rate limiting per user — DoS risk | Medium | Workaround: K8s resource limits |
| 4 | Hub single goroutine — bottleneck nếu vượt 50k connections | Low | Cần sharded hub nếu scale lớn hơn |

**Nhận xét tổng quan:** Đủ dùng cho on-premise enterprise với quy mô vừa. Vấn đề message loss là trade-off chấp nhận được ở giai đoạn này. Bug connection leak cần fix trước deploy thật.

---

### 1.3 Analytics Service (analytics-consumer + py-workers)

**Trạng thái:** Refactored (production-ready về pipeline, chưa cleanup legacy)

**Làm được gì:**

- 5-stage AI pipeline: Text Preprocessing → Intent Classification → Keyword Extraction → Sentiment (PhoBERT ONNX) → Impact Calculation
- Consume `smap.collector.output` (UAP), output sang `smap.analytics.output`
- Phân loại intent: CRISIS / SPAM / COMPLAINT / LEAD / SUPPORT / DISCUSSION
- ABSA (Aspect-Based Sentiment Analysis) cho tiếng Việt, không cần GPU
- Publish `analytics.metrics.aggregated` mỗi 5 phút cho project-scheduler

**Đánh giá kiến trúc:**
Pipeline đơn hướng rõ ràng: nhận UAP → xử lý → publish enriched output. Không có coupling ngược lại với upstream. Việc tách Go orchestrator (`analytics-consumer`) và Python micro-workers là quyết định đúng: Go xử lý batching/concurrency, Python giữ model inference.

**Vấn đề hiện tại:**

| # | Vấn đề | Mức độ | Ghi chú |
| --- | --- | --- | --- |
| 1 | Phase 6 Legacy Cleanup chưa bắt đầu — code cũ vẫn còn | Medium | Không blocking nhưng tạo tech debt |
| 2 | PhoBERT trên CPU chậm hơn GPU khoảng 5-10x | Low | ONNX runtime giảm thiểu, đủ cho on-premise |
| 3 | Kafka producer buffer flush delay khi shutdown | Medium | Workaround: graceful shutdown với SIGTERM |
| 4 | Không có dead letter queue cho failed messages | Medium | Nếu parsing lỗi, message bị bỏ qua hoàn toàn |

**Nhận xét tổng quan:** Pipeline hoạt động đúng. Rủi ro chính là không có dead letter queue — nếu một batch UAP lỗi schema, nó bị drop im lặng, không có cách debug sau. Cần thêm error topic.

---

### 1.4 Knowledge Service (knowledge-srv)

**Trạng thái:** Phase 1 Done, đang test

**Làm được gì:**

- Vector indexing: consume analytics output → embedding via Voyage AI → upsert Qdrant
- Semantic search với filter (sentiment, aspect, platform, date range)
- RAG Chat multi-turn với Gemini 1.5-pro, citation, suggestions
- Report generation async (Map-Reduce pattern, output Markdown/PDF vào MinIO)
- 3-tier caching: embedding cache (7 ngày), campaign resolution (10 phút), search result (5 phút)
- Gọi Project Service để resolve `campaign_id → project_ids` (read-only query)

**Đánh giá kiến trúc:**
Dependency duy nhất với service khác là read query sang Project để biết campaign gồm những project nào. Đây là dependency read-only, không có event loop. Caching 10 phút cho campaign resolution là hợp lý.

**Vấn đề hiện tại (xác nhận từ code — xem `documents/knowledge-service-status.md`):**

| # | Vấn đề | Mức độ | Ghi chú |
| --- | --- | --- | --- |
| 1 | Report stuck PROCESSING nếu service restart giữa chừng | HIGH | `go generateInBackground()` trần, không có recovery |
| 2 | Token counting dùng `len(prompt)/4` — sai với UTF-8 tiếng Việt | Medium | `len()` tính bytes, không phải runes, undercount thực tế |
| 3 | Rate limiting chưa có cho Voyage AI + Gemini | Medium | Uncontrolled API cost, có thể hit rate limit khi nhiều user |
| 4 | PDF output chưa implement | Low | Code chỉ tạo `.md`, doc cũ nói "PDF/Markdown" |
| 5 | Conversation Export chưa có trong interface | Low | Feature được plan nhưng chưa tồn tại trong code |

**Nhận xét tổng quan:** Service có nhiều feature hơn doc cũ mô tả. Indexing có DLQ, RetryFailed, Reconcile đầy đủ. Report Generation đã implement xong (Markdown). Vấn đề thực sự là goroutine trần cho report generation (stuck nếu restart), token counting thô, và thiếu rate limit. Xem `documents/knowledge-service-status.md` để biết chi tiết từng domain.

---

### 1.5 Tổng hợp đánh giá

| Service | Boundary | Tech Debt | Blocking Issue | Sẵn sàng integrate? |
| --- | --- | --- | --- | --- |
| Identity | Tốt | Thấp | Không | Có |
| Notification | Tốt | Trung bình | Không | Có (cần fix leak) |
| Analytics | Tốt | Trung bình | Không | Có (cần dead letter queue) |
| Knowledge | Tốt | Cao | Report Gen chưa xong | Một phần (search/chat OK, report chưa) |

**Pattern chung của 4 service này:** Mỗi service có **một hướng dependency chính** — hoặc consume event, hoặc trả lời read query. Không có service nào vừa nhận command từ B vừa command lại B. Đây là điểm khác biệt so với Ingest và Project.

---

## Phần 2: Vấn đề giữa Ingest và Project

### 2.1 Dependency hiện tại là 2 chiều

```text
Ingest lắng nghe Project (Kafka):
  project.activated  → resume crawling
  project.paused     → pause all sources
  project.archived   → archive all sources

Project ra lệnh Ingest (HTTP):
  PUT /ingest/sources/:id/crawl-mode  (SLEEP / NORMAL / CRISIS)
```

Đây là vấn đề: Ingest phụ thuộc Project, đồng thời Project cũng phụ thuộc Ingest. Không service nào trong 4 service trên có pattern này.

### 2.2 Root causes

#### Cause 1: project-scheduler phải biết `source_id`

Để gọi `PUT /ingest/sources/:id/crawl-mode`, project-scheduler cần traverse `project_id → [source_id_1, source_id_2]`. Nhưng `data_sources` nằm trong `schema_ingest`, không phải `schema_project`. Điều này buộc project-scheduler phải:

- Hoặc query ingest để lấy source_ids (thêm HTTP call, thêm dependency)
- Hoặc lưu duplicate mapping trong project schema (sync problem)
- Hoặc loop HTTP call cho từng source (không scale)

#### Cause 2: Adaptive crawl là direct synchronous HTTP

```text
project-scheduler → HTTP PUT /ingest/sources/:id/crawl-mode
```

Nếu ingest-api down tại thời điểm crisis, lệnh tăng tần suất crawl bị mất. Không có retry, không có audit trail về "ai ra lệnh vì lý do gì".

#### Cause 3: Wizard flow chưa được ghi rõ là UI orchestrates

`dataflow-detailed.md` Section 3.2 đã vẽ đúng (UI gọi project-api rồi gọi ingest-api độc lập), nhưng không có nơi nào ghi rõ rule: project-api không được proxy ingest-api. Dễ bị implement sai.

#### Cause 4: Kafka topic naming không đồng nhất

| Nguồn | Topic |
| --- | --- |
| `dataflow-detailed.md` | `analytics.uap.received` |
| `repost_ingest.md` | `smap.collector.output` |
| `analysis-report.md` | `smap.collector.output` |

`dataflow-detailed.md` đang lỗi thời. Canonical topic là `smap.collector.output`.

---

## Phần 3: Đề xuất làm rõ boundary

### 3.1 Principle

```text
Project Service: "what to do"
  - Quản lý Campaign / Project / Crisis Config
  - Đánh giá ngưỡng khủng hoảng từ analytics metrics
  - Ra quyết định cấp độ project
  - KHÔNG biết source_id, không schedule crawl

Ingest Service: "how to do it"
  - Quản lý data_sources, crawl scheduling, raw data
  - Nhận event và tự map project_id → sources nội bộ
  - KHÔNG đánh giá crisis, KHÔNG quyết định crawl mode
```

### 3.2 Sửa adaptive crawl: bỏ per-source HTTP, dùng per-project

#### Lựa chọn A — Kafka event (khuyến nghị)

```text
project-scheduler  →  Kafka [project.crawl_mode.requested]
                       { project_id, mode: CRISIS|NORMAL|SLEEP }
                   →  ingest-cron consumes
                   →  SELECT sources WHERE project_id=? AND category=CRAWL
                   →  apply crawl_mode to each source
                   →  publish [ingest.crawl_mode.changed] for audit
```

#### Lựa chọn B — HTTP nhưng per-project (nếu muốn đơn giản hơn)

```text
PUT /ingest/internal/projects/:project_id/crawl-mode
Body: { "mode": "CRISIS|NORMAL|SLEEP", "reason": "..." }
Auth: internal service key
```

Ingest tự resolve project_id → sources, project-srv không bao giờ cần biết source_id.

Cả hai đều fix được root cause 1 và 2. Khuyến nghị Lựa chọn A vì Kafka đã có sẵn trong hệ thống và consistent với cách các service khác giao tiếp.

### 3.3 Làm rõ wizard flow (chỉ cần ghi vào doc, không cần code mới)

```text
Step 1: POST /projects          → project-api   (tạo project, status=DRAFT)
Step 2: POST /sources           → ingest-api    (tạo source, lưu project_id làm FK)
Step 3: POST /sources/:id/dryrun hoặc /mapping/preview → ingest-api
Step 4: PUT  /sources/:id/mapping → ingest-api
Step 5: PUT  /projects/:id      → project-api   (status=ACTIVE)
         ↓ publish [project.activated]
         ↓ ingest-srv consumes → bắt đầu scheduling
```

Rule cần ghi rõ: UI là orchestrator trong wizard. project-api và ingest-api là 2 independent API calls. project-api không proxy và không gọi ingest-api.

### 3.4 Giữ nguyên lifecycle sync qua Kafka (đã đúng, chỉ cần implement)

```text
project-api publishes:
  project.activated  → ingest resume scheduling
  project.paused     → ingest pause scheduling
  project.archived   → ingest soft-delete sources
```

Đây đã được spec trong `repost_ingest.md`. Chỉ cần đảm bảo project-api thực sự publish khi implement.

---

## Phần 4: Checklist trước khi implement Project Service

### Kafka events project-srv PHẢI publish

| Event | Trigger | Ingest phản ứng |
| --- | --- | --- |
| `project.activated` | User activate | Resume scheduling tất cả sources |
| `project.paused` | User pause | Pause scheduling, giữ sources |
| `project.archived` | User archive | Soft-delete sources |
| `project.crawl_mode.requested` | Crisis detection | Apply mode theo project_id |

### Điều cần sửa ngay trong tài liệu

1. **`dataflow-detailed.md` Section 6** — đổi `PUT /sources/{id}/crawl-mode` sang Kafka event hoặc per-project HTTP endpoint
2. **`dataflow-detailed.md` Section 8** — xóa topic `analytics.uap.received`, thống nhất thành `smap.collector.output`
3. Ghi rõ rule UI orchestrates vào dataflow-detailed.md Section 3

---

## Tham khảo

- `documents/dataflow-detailed.md` — System data flow (cần update)
- `presentation/weekly-03:02:26/repost_ingest.md` — Ingest service spec v1.0
- `presentation/weekly-03:02:26/analysis-report.md` — Analytics service spec
- `presentation/weekly-03:02:26/knowledge-report.md` — Knowledge service spec
- `presentation/weekly-03:02:26/identity-report.md` — Identity service spec
- `presentation/weekly-03:02:26/notification-srv-report.md` — Notification service spec
- `presentation/weekly-03:02:26/weekly-progress-03-03-2026.md` — Migration plan overview
