# Phân tích tổng thể SMAP — Thực tế vs Kế hoạch

## TÓM TẮT NHANH

| Service      | Trạng thái CRUD     | Kafka/Events                                  | Tích hợp liên service                        | Production Ready?             |
| ------------ | ------------------- | --------------------------------------------- | -------------------------------------------- | ----------------------------- |
| Identity     | ✅ Done             | ✅ audit.events                               | ✅ Internal validate API                     | ⚠️ 90% (2 bug nhỏ)            |
| Notification | ✅ Done (push-only) | ❌ Không dùng Kafka                           | ✅ Redis Pub/Sub đúng                        | ⚠️ 85% (message type fragile) |
| Analysis     | ✅ Pipeline done    | ✅ Consume UAP, Publish smap.analytics.output | ❌ GAP với Knowledge                         | ⚠️ 70%                        |
| Knowledge    | ✅ Done (4 domains) | ✅ Consume analytics.batch.completed          | ❌ Không nhận được data từ Analysis          | ⚠️ 75%                        |
| Project      | ✅ CRUD done        | ❌ Consumer là TODO hoàn toàn                 | ❌ Adaptive Crawl trống                      | ❌ 40%                        |
| Ingest       | ✅ Done đầy đủ      | ✅ RabbitMQ + Kafka UAP                       | ⚠️ Endpoint crawl-mode exist, chưa có caller | ⚠️ 80%                        |

## PHẦN 1: NHỮNG GÌ ĐANG ĐÚNG VÀ HOẠT ĐỘNG

### 1.1 Identity Service — Production Ready

- **Plan nói:** HS256 shared secret, Google Groups role mapping
- **Code thực tế:** HS256 (đúng như plan), role mapping qua email config (bỏ Google Groups)

Điểm đáng khen:

- 10-step OAuth flow đầy đủ (`pkg/jwt/jwt.go` — `SigningMethodHS256`, TTL 8h / rememberMe 7d)
- Audit log end-to-end: produce → Kafka `audit.events` → consumer → PostgreSQL
- Token blacklist Redis với TTL tự động (không cần cron cleanup)
- `mw.ServiceAuth()` đã implement đầy đủ, chỉ cần uncomment để enable

**Lưu ý:** Bảng `jwt_keys` tồn tại trong sqlboiler nhưng không được dùng trong JWT logic — artifact từ refactor cũ.

### 1.2 Notification Service — Thiết kế đúng

Service này có boundary đúng nhất: pure delivery layer, không có database, không có business logic. Redis Pub/Sub + WebSocket + Discord. Không service nào cần gọi ngược lại nó. Đây là mẫu thiết kế đúng.

### 1.3 Analysis Pipeline — Core hoạt động

5-stage pipeline (Preprocessing → Intent → Keyword → Sentiment → Impact) chạy đúng. PhoBERT ONNX không cần GPU — đây là quyết định đúng cho on-premise. Error handling per-stage đủ tốt: một stage lỗi không crash toàn pipeline.

### 1.4 Knowledge Service — 4 domains đều có code

- **Indexing:** DLQ + RetryFailed + Reconcile — nhiều hơn plan mô tả
- **Search:** 3-tier caching (embedding 7 ngày, campaign 10 phút, search result 5 phút)
- **Chat:** RAG multi-turn với Gemini, citation
- **Report:** Async map-reduce, upload MinIO

### 1.5 Ingest Service — Core production-ready

DataSource lifecycle với state guards đầy đủ (7 states: PENDING→READY→ACTIVE/PAUSED→ARCHIVED, có thêm FAILED và COMPLETED cho one-shot passive source), CrawlTarget CRUD (3 types: KEYWORD, PROFILE, POST_URL), DryRun domain (6 statuses), RabbitMQ execution pipeline, UAP → Kafka publish. Đây là service có code chặt nhất.

## PHẦN 2: NHỮNG VẤN ĐỀ THỰC SỰ — PHÂN LOẠI THEO MỨC ĐỘ

### 🔴 CRITICAL — Hệ thống không thể chạy end-to-end

#### Issue C1: Analytics → Knowledge — Không có bridge

Đây là vấn đề lớn nhất của toàn hệ thống:

```
Analytics OUTPUT:
  Kafka topic: smap.analytics.output
  Format: JSON array of InsightMessage (batch = 10, in-memory)

Knowledge INPUT:
  Kafka topic: analytics.batch.completed
  Format: { batch_id, project_id, file_url }
  file_url: điểm tới JSONL file trên MinIO
```

Không có component nào làm cầu nối. Ngay cả khi cả 2 service chạy hoàn hảo, Knowledge không bao giờ nhận được data từ Analytics.

Để fix, cần chọn một trong:

- **Option A (khuyến nghị):** Analysis viết JSONL ra MinIO sau mỗi batch flush → publish `analytics.batch.completed`
- **Option B:** Knowledge subscribe trực tiếp `smap.analytics.output`, bỏ `analytics.batch.completed`

Option A ít thay đổi code Knowledge hơn, nhưng tăng I/O MinIO. Option B đơn giản hơn nhưng phải sửa Knowledge consumer.

#### Issue C2: `analytics.metrics.aggregated` — Topic ma

`dataflow-detailed.md` Section 6 vẽ flow:

```
Analytics → Kafka analytics.metrics.aggregated → Project Scheduler → đánh giá crisis
```

Topic này không tồn tại trong code Analysis. Không có producer, không có cron job aggregator, không có gì. Toàn bộ Adaptive Crawl decision loop trong kế hoạch không có data source để chạy.

#### Issue C3: Project Service Kafka Consumer — 100% TODO

```go
// services/project/consumer/handler.go
func (srv *ConsumerServer) setupDomains(ctx context.Context) (*domainConsumers, error) {
    // TODO: Initialize domain consumers here
    return &domainConsumers{}, nil
}
```

Infrastructure có (Kafka client, Redis, Postgres đã wire), nhưng không subscribe topic nào. Project service hiện tại không biết khi nào có `project.activated`, `project.paused`, không publish `project.crisis.started`. Đây là service có khoảng cách lớn nhất giữa thiết kế và thực tế.

### 🟠 HIGH — Cần fix trước integration test

#### Issue H1: Adaptive Crawl — 0% implemented (toàn hệ thống)

Theo plan, Adaptive Crawl là một trong những tính năng core. Thực tế:

| Component                                         | Trạng thái                               |
| ------------------------------------------------- | ---------------------------------------- |
| `services/project/adaptive/`                      | Thư mục rỗng                             |
| `analytics.metrics.aggregated` topic              | Không tồn tại                            |
| Project scheduler đánh giá crisis                 | Không có code                            |
| Ingest `PUT /internal/datasources/:id/crawl-mode` | ✅ Implement đúng, nhưng không ai gọi nó |

Ingest đã chuẩn bị endpoint đúng. Vấn đề là phía project service chưa có logic để gọi nó.

#### Issue H2: Identity — `/internal` Routes Không Có Auth

```go
// services/identity/authentication/delivery/http/routes.go
internal := r.Group("/internal") //, mw.ServiceAuth())
```

`mw.ServiceAuth()` bị comment. Ai cũng có thể gọi:

- `POST /authentication/internal/validate` → probe token validity
- `GET /authentication/internal/users/:id` → lấy user info

`ServiceAuth()` đã implement đầy đủ (decrypt `X-Service-Key` header), chỉ cần uncomment. Đây là security bug thực sự.

### 🟡 MEDIUM — Tech debt, cần fix nhưng không block

#### Issue M1: Notification — Message Type Detection Dễ Vỡ

Không có field `type` trong Redis payload. Service dùng heuristic:

```
if hasField(source_id) && hasField(total_records) → ANALYTICS_PIPELINE
if hasField(alert_type) → CRISIS_ALERT
...
```

Nếu một publisher gửi payload thiếu unique field, message bị drop silently với `ErrUnknownMessageType`. Không có log warning nào cho user biết. Cần thêm explicit `"type"` field vào Redis message contract.

#### Issue M2: Knowledge — Report Goroutine Trần

```go
go generateInBackground()  // không có recovery, không có restart
```

Nếu service restart giữa lúc generate report, report bị stuck `PROCESSING` vĩnh viễn. Không có cron reconcile hay recovery mechanism. Cần thêm background job kiểm tra reports stuck `PROCESSING` > N phút → mark `FAILED` để user biết retry.

#### Issue M3: Knowledge — Token Counting Sai Với Tiếng Việt

```go
len(prompt) / 4  // len() tính bytes, không phải runes
```

Tiếng Việt UTF-8: 1 ký tự = 3 bytes. `len("xin chào") / 4` sẽ cho con số sai. Context có thể bị cắt sớm hơn cần thiết, hoặc vượt giới hạn token thực tế của Gemini.

#### Issue M4: Analysis — In-memory Buffer Mất Data Khi Crash

```python
self._buffer: list[InsightMessage] = []  # flush khi >= 10
```

Nếu service crash khi buffer có 1–9 items, toàn bộ bị mất vĩnh viễn. Kafka offset đã commit, không có way retry.

#### Issue M5: `dataflow-detailed.md` — Topic Names Sai

| Điểm sai             | Plan cũ                        | Thực tế (từ code)           |
| -------------------- | ------------------------------ | --------------------------- |
| Ingest → Analysis    | `analytics.uap.received`       | `smap.collector.output`     |
| Analysis → Knowledge | `knowledge.index`              | `analytics.batch.completed` |
| Analytics là Go      | "Go orchestrator + py-workers" | Pure Python single process  |
| Adaptive crawl loop  | Đầy đủ flow diagram            | 0% implemented              |

### 🟢 LOW — Nice to have, không blocking

- **Identity:** xóa `fmt.Println("DEBUG: ValidateToken Handler Reached")`
- **Notification:** xóa planning notes trong production file (`subscriber.go` lines 19–45)
- **Knowledge:** PDF export (chỉ có Markdown hiện tại)
- **Knowledge:** Conversation export
- **Analysis:** Xóa legacy constants (`FIELD_MINIO_PATH`, `EVENT_DATA_COLLECTED`, v.v.)

## PHẦN 3: KIẾN TRÚC — ĐÚNG VS SAI

### Đúng với thiết kế

- **Ingest → Analysis:** `smap.collector.output` (Kafka, UAP v1.0) — hoạt động
- **Analysis pipeline:** 5-stage single-process Python — đúng intent, sai diagram
- **Knowledge 3-tier cache:** Implemented đúng
- **Notification push-only:** Đúng thiết kế, không có database
- **Identity JWT:** Đúng plan (HS256 shared secret) — `pkg/jwt/jwt.go` dùng `SigningMethodHS256`. Bảng `jwt_keys` trong sqlboiler là artifact từ refactor cũ, không được sử dụng trong runtime.
- **Ingest state guards:** Implement đúng lifecycle, có audit trail cho crawl mode change

### Sai hoàn toàn so với thiết kế

- **Plan:** Go orchestrator (`analytics-consumer`) gọi HTTP sang `py-worker-sentiment`, `py-worker-aspect`, `py-worker-keyword`
  **Reality:** Single Python process, tất cả stages là function call trong cùng process

- **Plan:** `analytics.metrics.aggregated` → `project-scheduler` → đánh giá crisis → adaptive crawl
  **Reality:** Topic không tồn tại. Project scheduler không tồn tại. Adaptive crawl = 0%.

- **Plan:** `knowledge.index` topic nhận từ `analytics-consumer`
  **Reality:** `analytics.batch.completed` (MinIO JSONL), analytics publish JSON array lên Kafka
  → Không ai bridge 2 format này.

## PHẦN 4: HƯỚNG ĐI TIẾP THEO

Chia theo sprint priority:

### Sprint hiện tại — Unblock end-to-end data flow

**P0: Fix Analytics → Knowledge bridge (C1)**

Option nhanh nhất: Sửa Analysis service để sau mỗi batch flush lên `smap.analytics.output`, đồng thời:

- Gom InsightMessages thành JSONL
- Upload lên MinIO
- Publish `analytics.batch.completed` với `file_url`
- Không cần thay đổi Knowledge service.

**P1: Fix Identity security bug (H2)**

1 dòng: uncomment `mw.ServiceAuth()` trong `routes.go`

**P2: Fix Notification message contract (M1)**

Thêm explicit `"type"` field vào tất cả Redis publish payloads trong các service → Notification dùng type field thay vì heuristic.

### Sprint tiếp theo — Implement missing features

**P3: Project Service Kafka Consumer**

Implement `setupDomains()`:

- Subscribe `analytics.metrics.aggregated` (khi topic tồn tại) hoặc `smap.analytics.output`
- Evaluate crisis thresholds vs CrisisConfig
- Publish `project.crisis.started` → Notification Redis
- Call Ingest `PUT /internal/datasources/:id/crawl-mode` (hoặc publish Kafka event)

**P4: Analytics Metrics Aggregator (C2)**

Thêm aggregation logic vào Analysis service:

- Mỗi 5 phút: aggregate sentiment scores, volume metrics theo `project_id`
- Publish `analytics.metrics.aggregated` → Project consumer đọc

**P5: Knowledge Report Recovery (M2)**

Thêm startup reconcile: query reports `WHERE status=PROCESSING AND updated_at < NOW() - 10min` → mark `FAILED`

### Sau đó — Polish

- Fix token counting trong Knowledge (dùng `utf8.RuneCountInString` hoặc tiktoken)
- Xóa debug artifacts (`fmt.Println`, planning notes, legacy constants)
- Fix `dataflow-detailed.md` topic names
- Rate limiting cho Voyage AI + Gemini calls

## PHẦN 5: ĐIỂM MẤU CHỐT CHO TEAM

Ingest service là chuẩn nhất — state machine rõ, error handling đầy đủ, audit trail. Đây là model để viết các service còn lại.

2 missing pieces làm chết toàn bộ flow thông minh của hệ thống:

- Analytics không ghi ra MinIO (Knowledge không nhận được gì)
- `analytics.metrics.aggregated` không có (Adaptive Crawl không có data)

Project service cần nhiều effort nhất so với kỳ vọng — hiện tại chỉ là CRUD thuần. Toàn bộ "brain" của hệ thống (crisis detection, adaptive crawl decisions) cần implement từ đầu.

Identity và Notification có thể ship sau khi fix các bug nhỏ đã liệt kê.

---

# Roadmap To Full Pipeline — Task Breakdown

**Trạng thái hiện tại:** 6 services có code, nhưng data không chảy end-to-end vì 2 link bị đứt giữa Analysis→Knowledge và toàn bộ Adaptive Crawl chưa tồn tại.

- **Mục tiêu Milestone 1:** UAP từ Ingest chảy qua Analysis → Knowledge → User có thể Search/Chat.
- **Mục tiêu Milestone 2:** User thấy real-time alerts, hệ thống tự điều chỉnh crawl mode khi crisis.

## PHASE 0 — Quick Fixes (Làm song song, không phụ thuộc nhau)

Tất cả task dưới đây không có dependency, assign cho bất kỳ người nào, làm cùng lúc.

### [Identity] Task 0.1 — Enable ServiceAuth trên /internal routes

**File:** `services/identity/authentication/delivery/http/routes.go`

**Việc làm:** Uncomment 1 dòng:

```go
// Trước:
internal := r.Group("/internal") //, mw.ServiceAuth())

// Sau:
internal := r.Group("/internal", mw.ServiceAuth())
```

**Verify:** Gọi `POST /authentication/internal/validate` không có `X-Service-Key` header → phải trả 401. Gọi với đúng key → trả 200.

**Lý do cần làm ngay:** Hiện tại bất kỳ ai biết URL đều có thể validate/probe token, lấy user info mà không cần xác thực.

### [Identity] Task 0.2 — Xóa debug println

**File:** `services/identity/authentication/delivery/http/internal.go`

```go
// Xóa dòng này:
fmt.Println("DEBUG: ValidateToken Handler Reached")
```

### [Notification] Task 0.3 — Xóa planning notes khỏi production file

**File:** `services/notification/websocket/delivery/redis/subscriber.go` — lines 19–45

Xóa toàn bộ comment block planning notes. Code vẫn chạy, chỉ cleanup.

### [Analysis] Task 0.4 — Xóa legacy constants

**File:** `services/analysis/delivery/constant.py`

Xóa các constants không dùng từ kiến trúc cũ: `FIELD_MINIO_PATH`, `FIELD_JOB_ID`, `FIELD_BATCH_INDEX`, `EVENT_DATA_COLLECTED`, `FIELD_BRAND_NAME`, `FIELD_KEYWORD`. Chạy grep để confirm không có file nào dùng chúng.

### [Docs] Task 0.5 — Fix `dataflow-detailed.md`

**File:** `documents/dataflow-detailed.md`

Sửa các điểm sai:

| Section                    | Sai                                             | Đúng                                                      |
| -------------------------- | ----------------------------------------------- | --------------------------------------------------------- |
| Section 4.1, 4.2, 4.3      | `analytics.uap.received`                        | `smap.collector.output`                                   |
| Section 7.1                | `knowledge.index`                               | `analytics.batch.completed`                               |
| Section 5 header           | "Go orchestrator"                               | "Python async process"                                    |
| Section 8 topic table      | Xóa `analytics.uap.received`, `knowledge.index` | Thêm `smap.collector.output`, `analytics.batch.completed` |
| Section 6 (adaptive crawl) |                                                 | Đánh dấu rõ "NOT YET IMPLEMENTED"                         |

## PHASE 1 — Fix Core Pipeline Break (Blocking tất cả)

**Dependency:** Phải xong trước Phase 2. Trong Phase 1, Task 1.1+1.2+1.3 chạy song song với Task 1.4.

### Tại sao Phase 1 là blocking?

```
Ingest → smap.collector.output (Kafka) ✅
Analysis consumes smap.collector.output ✅
Analysis publishes smap.analytics.output (Kafka JSON array) ✅

Knowledge consumes analytics.batch.completed (MinIO JSONL) ✅
... nhưng KHÔNG AI viết analytics.batch.completed ❌
```

**Kết quả:** Knowledge service đang chạy, đang lắng nghe, nhưng không bao giờ nhận message.

### [Analysis] Task 1.1 — MinIO Batch Writer

**Ai làm:** Dev của Analysis service.

**Mục tiêu:** Sau mỗi lần flush buffer (mỗi 10 InsightMessages), ghi chúng ra MinIO dưới dạng JSONL file.

**Tạo file mới:** `services/analysis/delivery/minio/batch_writer.py`

Interface cần implement:

```python
class BatchWriter:
    def __init__(self, minio_client, bucket: str):
        ...

    async def write_batch(
        self,
        project_id: str,
        batch_id: str,
        messages: list[InsightMessage]
    ) -> str:
        """
        Serialize messages → JSONL
        Upload to MinIO: batches/{project_id}/{date}/{batch_id}.jsonl
        Return: file_url (s3://bucket/path)
        """
```

Format JSONL output (mỗi dòng là 1 JSON object, bắt buộc có các fields này vì Knowledge cần):

```json
{"id": "...", "project_id": "...", "source_id": "...", "content": "...", "is_spam": false, "is_bot": false, "content_quality_score": 0.8, "sentiment": "negative", "aspects": [...], "keywords": [...], "engagement_score": 0.5}
```

**Lưu ý:** Đối chiếu với Knowledge indexing usecase — nó validate: `id`, `project_id`, `source_id`, `content` length, sau đó pre-filter bằng `is_spam`, `is_bot`, `content_quality_score`. Tất cả fields này phải có trong JSONL.

**Error handling:**

- MinIO upload fail → retry 3 lần với exponential backoff
- Nếu vẫn fail → log error với `batch_id`, KHÔNG publish Kafka event (tránh Knowledge nhận batch không có file)
- Metric: counter `analysis_minio_upload_failed_total`

### [Analysis] Task 1.2 — Publish `analytics.batch.completed`

**Phụ thuộc:** Task 1.1 xong.

**File sửa:** `services/analysis/delivery/kafka/producer.py` (hoặc tương đương)

Sau khi Task 1.1 `write_batch()` thành công và có `file_url`, publish:

```python
# Thêm constant
TOPIC_BATCH_COMPLETED = "analytics.batch.completed"

# Message format
{
    "batch_id": "uuid-v4",
    "project_id": "proj_xxx",
    "file_url": "s3://analytics-batches/proj_xxx/2026-03-08/batch-uuid.jsonl",
    "record_count": 10,
    "completed_at": "2026-03-08T10:00:00Z",
    "should_index_count": 8  # optional: số records có should_index=True
}
```

Wire vào `publisher.py`:

```python
# publisher.py - trong method _flush():
# Trước: chỉ publish lên smap.analytics.output
# Sau:
async def _flush(self):
    if not self._buffer:
        return

    batch = self._buffer.copy()
    self._buffer.clear()

    batch_id = str(uuid4())

    # Step 1: Publish to smap.analytics.output (giữ nguyên)
    await self._kafka_producer.publish(TOPIC_ANALYTICS_OUTPUT, batch)

    # Step 2: Write to MinIO (mới)
    try:
        file_url = await self._batch_writer.write_batch(
            project_id=batch[0].project.project_id,  # lấy từ item đầu
            batch_id=batch_id,
            messages=batch
        )

        # Step 3: Publish analytics.batch.completed (mới)
        await self._kafka_producer.publish(TOPIC_BATCH_COMPLETED, {
            "batch_id": batch_id,
            "project_id": batch[0].project.project_id,
            "file_url": file_url,
            "record_count": len(batch),
            "completed_at": datetime.utcnow().isoformat() + "Z"
        })
    except Exception as e:
        logger.error(f"Failed to write batch {batch_id} to MinIO: {e}")
        # Không raise — analytics output đã publish thành công
```

### [Analysis] Task 1.3 — Verify và document input topic config

**Việc làm:**

- Tìm file config của Analysis service (yaml/env) — xác định key name của consumer topics
- Verify value là `smap.collector.output`
- Viết vào README hoặc `.env.example`:

```
KAFKA_CONSUMER_TOPICS=smap.collector.output
KAFKA_CONSUMER_GROUP=analysis-consumer-group
```

**Lý do:** Topic input là config-driven, không hardcode. Nếu config sai, service khởi động bình thường nhưng không nhận message nào — không có error log nào để debug.

### [Knowledge] Task 1.4 — Verify JSONL schema compatibility (song song với 1.1–1.3)

**Ai làm:** Dev của Knowledge service, làm song song khi Analysis dev đang làm Task 1.1.

**Việc làm:** Đọc `services/knowledge/indexing/usecase/index.go` và liệt kê chính xác các fields Knowledge expect từ JSONL file:

Expected inputs cho pipeline:

```
validate: id, project_id, source_id, content (min_length check)
pre-filter: is_spam, is_bot, content_quality_score
dedup: dùng content hash (chỉ cần content)
embed: dùng content
upsert Qdrant payload: sentiment, aspects, keywords, engagement_score, ...
```

**Output của task này:** 1 file `documents/jsonl-schema-contract.md` liệt kê:

- Fields bắt buộc (validation sẽ skip nếu thiếu)
- Fields optional (filter/upsert)
- Type của mỗi field

Dùng document này để verify Task 1.1 output JSONL có đủ fields.

### [Integration] Task 1.5 — End-to-end smoke test

**Phụ thuộc:** Task 1.1 + 1.2 + 1.3 + 1.4 xong.

Test script thủ công (có thể script hóa):

```bash
# Step 1: Push 1 UAP message vào smap.collector.output
kafka-console-producer --topic smap.collector.output --message '{
  "uap_version": "1.0",
  "event_id": "test-001",
  "ingest": {"source_id": "src-test", "doc_id": "doc-001"},
  "content": {"text": "Sản phẩm này rất tệ, tôi thất vọng hoàn toàn"},
  "signals": {},
  "context": {"project_id": "proj-test", "platform": "tiktok"}
}'

# Step 2: Chờ ~30 giây (analysis pipeline + MinIO write)

# Step 3: Verify MinIO có file
mc ls minio/analytics-batches/proj-test/

# Step 4: Verify Kafka có message
kafka-console-consumer --topic analytics.batch.completed --from-beginning

# Step 5: Chờ ~10 giây (knowledge indexing)

# Step 6: Search via Knowledge API
curl -X POST http://localhost:8080/search \
  -H "Authorization: Bearer $JWT" \
  -d '{"campaign_id": "...", "query": "thất vọng"}'
```

**Pass criteria:** Search trả về document có nội dung "thất vọng".

## PHASE 2 — Notification Contract Fix

**Dependency:** Có thể làm song song với Phase 1. Không block nhau.
**Ai cần coordinate:** Tất cả services publish vào Redis + Notification service.

### Context

Hiện tại Notification detect message type bằng heuristic field-sniffing. Nếu publisher gửi payload thiếu unique fields, message bị drop silently.

### [Contract] Task 2.1 — Define Redis message contract

**Output:** `documents/redis-message-contract.md` với schema:

```json
// Tất cả messages publish lên Redis PHẢI có field "type"
{
  "type": "CRISIS_ALERT | DATA_ONBOARDING | ANALYTICS_PIPELINE | CAMPAIGN_EVENT | SYSTEM",
  "project_id": "..." // optional, tùy type
  // ... type-specific fields
}
```

**CRISIS_ALERT:**

```json
{
  "type": "CRISIS_ALERT",
  "project_id": "...",
  "severity": "CRITICAL | WARNING | INFO",
  "alert_type": "sentiment | volume | keywords | influencer",
  "current_value": 0.45,
  "threshold": 0.3,
  "affected_aspects": ["pin", "chất lượng"],
  "triggered_at": "2026-03-08T10:00:00Z"
}
```

**ANALYTICS_PIPELINE:**

```json
{
  "type": "ANALYTICS_PIPELINE",
  "project_id": "...",
  "source_id": "...",
  "total_records": 150,
  "processed_count": 148,
  "progress": 98.7,
  "current_phase": "sentiment"
}
```

### [Notification] Task 2.2 — Update ProcessMessage để dùng type field

**File:** `services/notification/websocket/usecase/` (ProcessMessage method)

```go
// Thay thế detectMessageType() heuristic bằng:
func (uc *useCase) ProcessMessage(channel string, payload []byte) error {
    var base struct {
        Type string `json:"type"`
    }
    if err := json.Unmarshal(payload, &base); err != nil || base.Type == "" {
        // Fallback to heuristic nếu không có type field (backward compat)
        msgType = uc.detectMessageType(payload)
    } else {
        msgType = MessageType(base.Type)
    }
    // ... tiếp tục như cũ
}
```

Giữ heuristic fallback trong 1 sprint để không break publishers cũ, sau đó xóa.

### [Each Publisher] Task 2.3 — Thêm type field vào Redis publish calls

Cần identify tất cả services publish vào Redis. Dựa vào Notification status doc, các channels là:

- `project:*:user:*` → thường từ Analysis hoặc Project service
- `alert:*:user:*` → từ Project service (crisis)
- `campaign:*:user:*` → từ Project service
- `system:*` → từ bất kỳ service nào

Cần grep trong codebase:

```bash
grep -r "redis.Publish\|RedisPublish\|pubsub.Publish" services/ --include="*.go"
```

Với mỗi call tìm được, thêm `"type"` field vào payload.

## PHASE 3 — Project Lifecycle Events (Kafka)

**Dependency:** Không phụ thuộc Phase 1 hay 2. Có thể làm song song.
**Mục tiêu:** Ingest service biết khi nào project thay đổi trạng thái.

### [Project] Task 3.1 — Implement Kafka Producer trong Project Service

**Context:** Project service có infrastructure Kafka producer đã wire (xem `consumer/handler.go`), nhưng chưa dùng ở đâu.

**Việc làm:** Trong các project usecase, sau mỗi state change, publish event.

Cụ thể trong project usecase:

```go
// Khi ActivateProject():
if err := uc.repo.UpdateStatus(ctx, projectID, StatusActive); err != nil {
    return err
}
// Thêm:
uc.producer.Publish(ctx, "project.activated", ProjectEvent{
    ProjectID: projectID,
    CampaignID: project.CampaignID,
    EventType: "activated",
    Timestamp: time.Now().UTC(),
})

// Tương tự cho PauseProject() → "project.paused"
// Tương tự cho ArchiveProject() → "project.archived"
```

Kafka topic format:

```go
// Topic: project.lifecycle
{
  "event_type": "activated | paused | archived",
  "project_id": "...",
  "campaign_id": "...",
  "timestamp": "..."
}
```

**Note:** Dùng 1 topic `project.lifecycle` thay vì 3 topic riêng — filter bằng `event_type`. Đơn giản hơn.

### [Ingest] Task 3.2 — Subscribe `project.lifecycle` events

**Context:** Ingest service có scheduler + consumer infrastructure. Cần thêm 1 consumer mới.

**Việc làm:** Trong Ingest consumer server (hoặc tạo consumer mới), subscribe `project.lifecycle`:

```go
// Khi nhận "activated":
// SELECT * FROM datasources WHERE project_id = ? AND status IN ('PAUSED', 'READY')
// Với mỗi source: call resumeUC.Resume(ctx, sourceID)

// Khi nhận "paused":
// SELECT * FROM datasources WHERE project_id = ? AND status = 'ACTIVE'
// Với mỗi source: call pauseUC.Pause(ctx, sourceID)

// Khi nhận "archived":
// SELECT * FROM datasources WHERE project_id = ?
// Với mỗi source: call archiveUC.Archive(ctx, sourceID) (soft delete)
```

**Lưu ý quan trọng:** Ingest đã có các usecase Pause, Resume, Archive trong `datasource/usecase/lifecycle.go`. Task này chỉ là wire consumer vào các usecase đã có, không cần viết logic mới.

## PHASE 4 — ProjectConfigStatus Wizard Transitions

**Dependency:** Phase 3 xong.
**Mục tiêu:** `config_status` của Project di chuyển đúng theo wizard, ingest dẫn dắt transition.

### Context

Project model có 9 wizard states nhưng không có usecase nào transition chúng. State hiện chỉ được set externally (hoặc thủ công).

### [Project] Task 4.1 — Implement config_status transitions

Wizard flow theo kế hoạch:

```
DRAFT → CONFIGURING → ONBOARDING → ONBOARDING_DONE → DRYRUN_RUNNING → DRYRUN_SUCCESS/FAILED → ACTIVE/ERROR
```

Cần thêm internal API để Ingest service gọi khi:

```go
// services/project/project/delivery/http/routes.go

// Thêm internal routes (với mw.InternalAuth()):
PUT /internal/projects/:id/config-status
Body: { "status": "DRYRUN_SUCCESS" | "DRYRUN_FAILED" | ... }
```

### [Ingest] Task 4.2 — Gọi project service khi DryRun hoàn thành

**File:** `services/ingest/dryrun/usecase/` — sau khi DryRun complete

```go
// Khi dryrun SUCCESS:
// 1. Update datasource.dryrun_status = SUCCESS (đã làm)
// 2. Gọi project service internal API:
projectClient.UpdateConfigStatus(ctx, projectID, "DRYRUN_SUCCESS")

// Khi dryrun FAILED:
projectClient.UpdateConfigStatus(ctx, projectID, "DRYRUN_FAILED")
```

**Lưu ý:** Đây là HTTP call đồng bộ. Nếu project service down, dryrun vẫn ghi thành công vào ingest DB, chỉ là project `config_status` không được update. Acceptable risk vì không critical path.

## PHASE 5 — Adaptive Crawl (Milestone 2)

**Dependency:** Phase 1 phải xong (data phải chảy qua Analysis). Task 5.1 và 5.2 có thể làm song song.
Đây là phần công việc lớn nhất còn lại.

### [Analysis] Task 5.1 — Metrics Aggregator

**Mục tiêu:** Publish `analytics.metrics.aggregated` mỗi 5 phút cho Project service đọc.

**Tạo file:** `services/analysis/aggregator/metrics_aggregator.py`

```python
class MetricsAggregator:
    """
    Chạy như background task, mỗi 5 phút:
    1. Query post_insight trong 5 phút vừa rồi, group by project_id
    2. Calculate: negative_ratio, total_posts, avg_sentiment_score, volume_spike_ratio
    3. Publish analytics.metrics.aggregated
    """

    async def run_forever(self):
        while True:
            await asyncio.sleep(300)  # 5 minutes
            await self.aggregate_and_publish()

    async def aggregate_and_publish(self):
        # Query PostgreSQL:
        # SELECT project_id,
        #   COUNT(*) as total_posts,
        #   AVG(overall_sentiment_score) as avg_sentiment,
        #   COUNT(*) FILTER(WHERE overall_sentiment='negative') * 1.0 / COUNT(*) as negative_ratio,
        #   SUM(engagement_score) as total_engagement
        # FROM schema_analysis.post_insight
        # WHERE processed_at >= NOW() - INTERVAL '5 minutes'
        # GROUP BY project_id

        for row in rows:
            await self.kafka_producer.publish("analytics.metrics.aggregated", {
                "project_id": row.project_id,
                "window_minutes": 5,
                "aggregated_at": now.isoformat() + "Z",
                "metrics": {
                    "negative_ratio": row.negative_ratio,
                    "total_posts": row.total_posts,
                    "avg_sentiment_score": row.avg_sentiment,
                    "total_engagement": row.total_engagement,
                    "volume_spike_ratio": self._calc_spike(row)  # vs 7-day avg
                }
            })
```

Volume spike calculation:

```python
def _calc_spike(self, current_row) -> float:
    # Query avg posts per 5-min window in last 7 days for this project
    # spike = current / avg_baseline
    # Nếu không có baseline (project mới) → return 1.0
```

Wire vào main:

```python
# Khởi động cùng lúc với Kafka consumer
asyncio.gather(
    consumer.run(),
    MetricsAggregator(db, kafka_producer).run_forever()
)
```

### [Project] Task 5.2 — Implement Crisis Detection Consumer (song song với 5.1)

**File:** `services/project/consumer/handler.go` — cần implement `setupDomains()`

Implement 3 phần:

#### 5.2a: Kafka Consumer cho `analytics.metrics.aggregated`

```go
// services/project/adaptive/crisis_consumer.go

type CrisisConsumer struct {
    kafkaConsumer kafka.Consumer
    crisisUC      CrisisEvaluator
}

func (c *CrisisConsumer) Consume(ctx context.Context) error {
    return c.kafkaConsumer.Subscribe(ctx, "analytics.metrics.aggregated",
        "project-crisis-detector-group",
        c.handleMetrics)
}

func (c *CrisisConsumer) handleMetrics(ctx context.Context, msg MetricsMessage) error {
    return c.crisisUC.Evaluate(ctx, msg)
}
```

#### 5.2b: Crisis Evaluator Usecase

```go
// services/project/adaptive/crisis_evaluator.go

type CrisisEvaluator interface {
    Evaluate(ctx context.Context, metrics MetricsMessage) error
}

func (uc *crisisEvaluatorUC) Evaluate(ctx context.Context, metrics MetricsMessage) error {
    // 1. Load CrisisConfig for this project_id
    config, err := uc.crisisRepo.GetByProjectID(ctx, metrics.ProjectID)
    if err != nil || config == nil {
        return nil  // project không có crisis config → bỏ qua
    }

    // 2. Evaluate each trigger type
    level := NORMAL

    if config.SentimentTrigger != nil {
        if metrics.NegativeRatio >= config.SentimentTrigger.Threshold &&
           metrics.TotalPosts >= config.SentimentTrigger.MinSampleSize {
            level = max(level, WARNING)
            if metrics.NegativeRatio >= config.SentimentTrigger.CriticalThreshold {
                level = CRITICAL
            }
        }
    }

    if config.VolumeTrigger != nil {
        if metrics.VolumeSpikeRatio >= config.VolumeTrigger.SpikeThreshold {
            level = max(level, WARNING)
        }
    }

    // 3. Check if level changed from last known
    lastLevel := uc.cache.Get(metrics.ProjectID)  // Redis cache
    if level == lastLevel {
        return nil  // Không thay đổi → không cần action
    }

    // 4. Update cache
    uc.cache.Set(metrics.ProjectID, level, 10*time.Minute)

    // 5. Take action based on new level
    return uc.handleLevelChange(ctx, metrics.ProjectID, level, metrics)
}

func (uc *crisisEvaluatorUC) handleLevelChange(
    ctx context.Context,
    projectID string,
    level CrisisLevel,
    metrics MetricsMessage,
) error {
    // Action 1: Update CrisisConfig status in DB
    uc.crisisRepo.UpdateStatus(ctx, projectID, level.String())

    // Action 2: Publish project.crawl_mode.requested (Kafka → Ingest consumes)
    crawlMode := levelToCrawlMode(level)  // CRITICAL→CRISIS, WARNING→NORMAL, NORMAL→SLEEP
    uc.kafkaProducer.Publish(ctx, "project.crawl_mode.requested", CrawlModeEvent{
        ProjectID: projectID,
        Mode:      crawlMode,
        Reason:    fmt.Sprintf("crisis_level=%s, negative_ratio=%.2f", level, metrics.NegativeRatio),
        TriggeredAt: time.Now().UTC(),
    })

    // Action 3: Nếu CRITICAL/WARNING, notify user
    if level >= WARNING {
        uc.redisClient.Publish(
            fmt.Sprintf("alert:%s:user:*", projectID),  // broadcast to all project users
            CrisisAlertPayload{
                Type:         "CRISIS_ALERT",
                ProjectID:    projectID,
                Severity:     level.String(),
                AlertType:    "sentiment",  // hoặc detect từ trigger nào fired
                CurrentValue: metrics.NegativeRatio,
            },
        )
    }

    return nil
}
```

#### 5.2c: Wire vào `setupDomains()`

```go
// services/project/consumer/handler.go
func (srv *ConsumerServer) setupDomains(ctx context.Context) (*domainConsumers, error) {
    crisisRepo := crisisRepo.New(srv.db)
    crisisEvaluator := adaptive.NewCrisisEvaluator(crisisRepo, srv.kafkaProducer, srv.redis)
    crisisConsumer := adaptive.NewCrisisConsumer(srv.kafkaConsumer, crisisEvaluator)

    return &domainConsumers{
        crisis: crisisConsumer,
    }, nil
}
```

### [Ingest] Task 5.3 — Subscribe `project.crawl_mode.requested`

**Context:** Ingest đã có `UpdateCrawlMode` usecase và endpoint. Cần thêm consumer nhận event từ Project.

Tạo consumer mới:

```go
// services/ingest/execution/delivery/consumer/crawl_mode_consumer.go

func (c *CrawlModeConsumer) handle(ctx context.Context, event CrawlModeEvent) error {
    // 1. List tất cả datasources của project này (CRAWL type, status ACTIVE/READY/PAUSED)
    sources, err := c.dsRepo.ListByProjectID(ctx, event.ProjectID, CategoryCRAWL)

    // 2. Apply mode to each source
    for _, src := range sources {
        c.dsUC.UpdateCrawlMode(ctx, UpdateCrawlModeInput{
            SourceID:    src.ID,
            Mode:        CrawlMode(event.Mode),
            Reason:      event.Reason,
            TriggerType: "ADAPTIVE_CRAWL_DECISION",
            EventRef:    event.EventID,
        })
    }
    return nil
}
```

**Lưu ý:** `UpdateCrawlMode` đã có audit trail ghi `crawl_mode_changes` table. Không cần logic mới, chỉ wire.

### [Notification] Task 5.4 — Verify Crisis Alert reach Discord

**Việc làm (test thủ công):**

Publish thủ công vào Redis channel `alert:proj-test:user:user-001` với payload:

```json
{
  "type": "CRISIS_ALERT",
  "project_id": "proj-test",
  "severity": "CRITICAL",
  "alert_type": "sentiment",
  "current_value": 0.55,
  "threshold": 0.3
}
```

- **Verify:** WebSocket client nhận message
- **Verify:** Discord channel nhận Rich Embed với màu đỏ (CRITICAL)

## PHASE 6 — Knowledge Bug Fixes (Song song với Phase 5)

### [Knowledge] Task 6.1 — Fix Report Goroutine Recovery

**File:** `services/knowledge/report/usecase/generator.go`

Thêm startup reconcile:

```go
// Gọi trong Server.Start() hoặc New() của report usecase:
func (uc *reportUC) ReconcileStuckReports(ctx context.Context) error {
    // UPDATE reports
    // SET status = 'FAILED', error_message = 'Interrupted by service restart'
    // WHERE status = 'PROCESSING'
    //   AND updated_at < NOW() - INTERVAL '15 minutes'
    return uc.repo.MarkStuckAsFailed(ctx, 15*time.Minute)
}
```

Gọi khi service start up, trước khi nhận request.

### [Knowledge] Task 6.2 — Fix Token Counting Tiếng Việt

**File:** Chat usecase (nơi có `len(prompt)/4`)

```go
// Trước:
tokenEstimate := len(prompt) / 4

// Sau:
import "unicode/utf8"
runeCount := utf8.RuneCountInString(prompt)
// Tiếng Việt: trung bình ~1.3 chars/token (thực nghiệm với Gemini tokenizer)
tokenEstimate := int(float64(runeCount) * 1.3)
```

## TÓM TẮT PARALLEL EXECUTION

```
Week 1:
├── [ALL]    Phase 0 (Quick Fixes) — tất cả làm song song
├── [AN dev] Task 1.1 MinIO Batch Writer
├── [AN dev] Task 1.2 Publish analytics.batch.completed
├── [AN dev] Task 1.3 Document input topic config
└── [KN dev] Task 1.4 Verify JSONL schema compat (song song với 1.1-1.3)

Week 1-2:
├── [ID dev] Task 0.1, 0.2 (30 phút total)
├── [NO dev] Task 2.1, 2.2, 2.3 (Notification contract)
└── [PR+IN dev] Task 3.1, 3.2 (Project lifecycle events)

Week 2:
├── [AN dev] Task 5.1 Metrics Aggregator
├── [PR dev] Task 5.2a, 5.2b, 5.2c (Crisis Detection Consumer) — song song với 5.1
└── [KN dev] Task 6.1, 6.2

Week 2-3:
├── [IN dev] Task 5.3 Crawl Mode Consumer
├── [Integration] Task 1.5 End-to-end smoke test
└── [Integration] Task 5.4 Crisis alert verify

Week 3:
└── Full integration test: UAP → Analysis → Knowledge → Search/Chat
                         + Crisis path: Metrics → Project → Ingest crawl mode change → Notification
```

## Điểm quan trọng cần lưu ý

- **Task 1.1 + 1.2** là unlocker của toàn bộ hệ thống. Ưu tiên số 1, assign người giỏi nhất của Analysis team.

- **Project service** cần nhiều effort nhất — Task 5.2 phức tạp nhất (crisis evaluator, multi-trigger logic, cache, Kafka publish). Cần estimate và assign sớm.

- **Ingest service** hầu như không cần thay đổi logic — chỉ wire consumer vào usecases đã có (Task 3.2 và 5.3). Ingest đã được implement tốt nhất.

- Không cần đợi Phase 5 xong mới ship — Phase 1 hoàn thành là hệ thống đã có giá trị thực (user có thể Search và Chat với data real). Adaptive Crawl là enhancement, không phải core.
