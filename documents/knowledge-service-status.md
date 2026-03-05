# Knowledge Service: Current Status (Từ Code)

**Ngày review:** 06/03/2026
**Nguồn:** Đọc trực tiếp từ code `services/knowledge/`
**Trạng thái tổng:** Implementation complete, đang testing

---

## 1. Các domain và trạng thái

### 1.1 Indexing Domain — COMPLETE

**Kafka input:**

```
Topic:    analytics.batch.completed
GroupID:  knowledge-indexing-batch
Message:  { batch_id, project_id, file_url, record_count, completed_at }
```

**Pipeline thực tế (từ `indexing/usecase/index.go`):**

```
MinIO download (JSONL)
  → validate (id, project_id, source_id, content length)
  → pre-filter (is_spam || is_bot || content_quality_score < threshold → skip)
  → dedup (content hash SHA-256 → skip nếu trùng)
  → embed (Voyage AI, có Redis cache 7 ngày)
  → upsert Qdrant (với full payload: sentiment, aspects, keywords, engagement...)
  → update indexed_documents status = INDEXED
  → nếu lỗi: ghi vào indexing_dlq
```

**UseCase interface:**

- `Index` — xử lý 1 batch từ file JSONL trên MinIO
- `RetryFailed` — retry các bản ghi trong DLQ
- `Reconcile` — đồng bộ Qdrant vs PostgreSQL
- `GetStatistics` — lấy stats theo project

**Database tables (có trong sqlboiler):**

- `indexed_documents` — tracking từng document đã index
- `indexing_dlq` — dead letter queue cho failed records
- View: `indexing_error_summary`, `indexing_health_check`, `indexing_stats_by_batch`, `indexing_stats_by_project`

**HTTP internal endpoints:**

- `POST /internal/index` — trigger manual index
- `POST /internal/index/retry` — retry DLQ
- `GET /internal/index/statistics/:id` — stats theo project

---

### 1.2 Search Domain — COMPLETE

**Flow thực tế (từ `search/usecase/search.go`):**

```
Tier 3 cache check (Redis, key: search:{campaign}:{params_hash})
  → cache hit → return
  → cache miss → tiếp tục

Tier 2: resolve campaign_id → project_ids
  → Redis cache (10 min)
  → cache miss → HTTP GET Project Service /campaigns/:id
  → lấy campaign.ProjectIDs

Embed query (Voyage AI, Tier 1 cache 7 ngày)
  → Search Qdrant (filter: project_id IN [...] + sentiment/aspect/platform/date)
  → Post-filter: score >= minScore (default 0.3, chat dùng 0.65)
  → Aggregate: by_sentiment, by_platform, by_aspect
  → Save Tier 3 cache (5 min)
  → Return results + aggregations + no_relevant_context flag
```

**Dependency ngoài:** HTTP call đến Project Service để resolve `campaign_id → [project_ids]`. Đây là dependency read-only duy nhất của Knowledge với service khác.

---

### 1.3 Chat Domain — COMPLETE (thiếu 1 feature nhỏ)

**Flow thực tế (từ `chat/usecase/chat.go`):**

```
validate (campaign_id required, message length 3–2000 chars)
  → create/load conversation
  → load history (max N messages, order ASC)
  → Search (dùng search.UseCase, minScore=0.65, top 10 docs)
  → buildPrompt (system + context + history + question)
  → token check: len(prompt)/4 > MaxTokenWindow → buildReducedPrompt (top 5 docs, last 10 history)
  → Gemini Generate
  → extractCitations từ search results
  → generateSuggestions
  → persist user message + assistant message
  → update conversation metadata
```

**UseCase interface:**

- `Chat` — main RAG pipeline
- `GetConversation` — lấy conversation + messages
- `ListConversations` — list by campaign/user
- `GetSuggestions` — gợi ý câu hỏi

**Thiếu:** Export conversation (không có trong interface)

**Vấn đề đã xác nhận:**

- Token counting dùng `len(prompt) / 4` — ước lượng thô. Với tiếng Việt, 1 token thường < 4 chars, nên thực tế context có thể bị cắt sớm hơn hoặc vượt giới hạn.

---

### 1.4 Report Domain — COMPLETE MVP (thiếu PDF, progress)

**Flow thực tế (từ `report/usecase/generator.go`):**

```
Generate():
  validate report_type + campaign_id
  → hash(campaign_id + report_type + filters) → check dedup
  → existing PROCESSING → return existing report_id
  → existing COMPLETED trong 1 giờ → reuse
  → INSERT reports (status=PROCESSING)
  → go generateInBackground()

generateInBackground():
  Phase 1: aggregateDocs (gọi search.UseCase, minScore=0.3, lấy rộng)
  → Phase 2: sampleDocs (lấy đều theo step)
  → Phase 3: Generate sections (LLM per section template theo report_type)
  → Phase 4: compileMarkdown (header + sections + footer)
  → Upload to MinIO: reports/{report_id}.md
  → UPDATE reports (status=COMPLETED, file_url, file_size, sections_count, generation_time_ms)
```

**UseCase interface:**

- `Generate` — tạo mới hoặc trả về existing
- `GetReport` — lấy status + metadata
- `DownloadReport` — presigned URL (30 min expiry)

**Report types:** SUMMARY | COMPARISON | TREND | ASPECT_DEEP_DIVE

**Thiếu:**

- PDF output: code chỉ upload `.md`, không có PDF conversion
- Progress % trong quá trình generate: chỉ có PROCESSING/COMPLETED/FAILED
- Inline edit report: không có trong codebase (chỉ đọc + download)

---

## 2. Mapping: Doc cũ vs Code thực tế

| Điểm | `knowledge-report.md` (17/02/2026) | Code thực tế | Đúng/Sai |
|---|---|---|---|
| Kafka topic | `analytics.batch.completed` | `analytics.batch.completed` | ✅ Đúng |
| DLQ | Không nhắc tới | Implemented (`indexing_dlq`) | Doc thiếu |
| Retry/Reconcile | Không nhắc tới | Implemented | Doc thiếu |
| Report output | "PDF/Markdown" | **Chỉ Markdown** | ❌ Sai |
| Token counting | Không đề cập | `len/4` thô | Doc thiếu |
| Conversation export | Không đề cập | Không có trong interface | N/A |
| 3-tier cache | Mô tả đúng | Implemented | ✅ Đúng |
| API endpoints | Mô tả đúng | Match | ✅ Đúng |

| Điểm | `dataflow-detailed.md` (20/02/2026) | Code thực tế | Đúng/Sai |
|---|---|---|---|
| Kafka topic | `knowledge.index` | `analytics.batch.completed` | ❌ **Sai — cần sửa** |
| Inline edit report | Đề cập | Không có trong code | ❌ Feature chưa tồn tại |

---

## 3. Các vấn đề thực sự cần chú ý

### High

- **`dataflow-detailed.md` dùng sai topic name** (`knowledge.index` → phải là `analytics.batch.completed`). Nếu ai đọc dataflow để implement producer bên analytics, sẽ publish sai topic và knowledge service không nhận được data.

### Medium

- **Token counting thô** (`len/4`): Với tiếng Việt UTF-8, 1 ký tự có thể là 3 bytes. `len()` trong Go tính bytes, không tính runes. Nên `len(prompt)/4` có thể undercount token thực tế.
- **Report generation chạy trong goroutine trần** (`go generateInBackground()`): Nếu service restart giữa chừng, report bị stuck ở PROCESSING vĩnh viễn. Không có recovery mechanism.
- **Không có rate limit** cho Voyage AI và Gemini calls. Nếu nhiều user generate report cùng lúc, có thể hit API rate limit.

### Low

- **PDF không có**: doc cũ nói "PDF/Markdown", code chỉ có Markdown. Nếu UI đang expect PDF download, cần align.
- **Conversation export**: feature được nhắc trong planning nhưng chưa có.

---

## 4. Quick reference

```
Service: knowledge-srv
Kafka input: analytics.batch.completed (consumer group: knowledge-indexing-batch)
HTTP: :8080
Auth: JWT cookie / Bearer + X-Service-Key cho internal

External dependencies:
  - Voyage AI (embedding)
  - Gemini 1.5-pro (LLM)
  - Qdrant (vector store)
  - PostgreSQL (metadata, conversations, reports, DLQ)
  - Redis (3-tier cache)
  - MinIO (report files, raw indexed data)
  - Project Service HTTP (read-only: resolve campaign → project_ids)
```
