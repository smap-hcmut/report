# Knowledge Service: Current Status (Từ Code)

**Ngày review:** 06/03/2026
**Nguồn:** Đọc trực tiếp từ code `knowledge-srv/`
**Trạng thái tổng:** Implementation complete, đang testing

---

## 1. Các domain và trạng thái

### 1.1 Indexing Domain — COMPLETE

**Kafka input:**

```text
Topic:    analytics.batch.completed
GroupID:  knowledge-indexing-batch
Message:  { batch_id, project_id, file_url, record_count, completed_at }
```

**Pipeline thực tế (`indexing/usecase/index.go`):**

```text
MinIO download (JSONL, format: s3://bucket/path)
  → validate (id, project_id, source_id, content length)
  → pre-filter (is_spam || is_bot || content_quality_score < 0.3 → skip)
  → dedup (content hash SHA-256 via indexed_documents table)
  → embed (Voyage AI model: voyage-multilingual-2, Redis cache 7 ngày)
  → upsert Qdrant (payload: sentiment, aspects, keywords, engagement, risk...)
  → update indexed_documents status = INDEXED
  → nếu lỗi embedding/qdrant: ghi vào indexing_dlq
```

**JSONL fields bắt buộc** (Knowledge validate khi đọc file):

- Core: `id`, `project_id`, `source_id`, `content`
- Filter: `is_spam`, `is_bot`, `content_quality_score` (threshold: **0.3**)
- Enriched: `overall_sentiment`, `aspects`, `keywords`, `engagement_score`, `risk_level`, `language`

**UseCase interface:**

- `Index` — xử lý 1 batch từ file JSONL trên MinIO
- `RetryFailed` — retry các bản ghi trong DLQ
- `Reconcile` — đồng bộ Qdrant vs PostgreSQL
- `GetStatistics` — lấy stats theo project

**Database tables:**

- `indexed_documents` — tracking từng document đã index
- `indexing_dlq` — dead letter queue (trigger: EMBEDDING_ERROR, QDRANT_ERROR)
- Views: `indexing_error_summary`, `indexing_health_check`, `indexing_stats_by_batch`, `indexing_stats_by_project`

**HTTP internal endpoints:**

- `POST /internal/index` — trigger manual index
- `POST /internal/index/retry` — retry DLQ
- `GET /internal/index/statistics/:id` — stats theo project

---

### 1.2 Search Domain — COMPLETE

**Flow thực tế (`search/usecase/search.go`):**

```text
Tier 3 cache check (Redis, key: search:{campaign}:{params_hash})
  → cache hit → return
  → cache miss → tiếp tục

Tier 2: resolve campaign_id → project_ids
  → Redis cache (10 min)
  → cache miss → HTTP GET Project Service /campaigns/:id

Embed query (Voyage AI, Tier 1 cache 7 ngày)
  → Search Qdrant (filter: project_id IN [...] + sentiment/aspect/platform/date)
  → Post-filter: score >= 0.65 (MinScore constant — search/types.go:4)
  → Aggregate: by_sentiment, by_platform, by_aspect
  → Save Tier 3 cache (5 min)
  → Return results + aggregations + no_relevant_context flag
```

**Lưu ý:** MinScore = **0.65** cho cả search lẫn chat (cùng constant). Không có mode 0.3.

**Dependency ngoài:** HTTP call đến Project Service `/campaigns/:id` (với Auth middleware — không có /internal endpoint riêng).

---

### 1.3 Chat Domain — COMPLETE (thiếu 1 feature nhỏ)

**Flow thực tế (`chat/usecase/chat.go`):**

```text
validate (campaign_id required, message length 3–2000 chars)
  → create/load conversation
  → load history (max 20 messages, order ASC)
  → Search (minScore=0.65, top 10 docs)
  → buildPrompt (system + context + history + question)
  → token check: len(prompt)/4 > MaxTokenWindow (28000)
      → nếu vượt: buildReducedPrompt (top 5 docs, last 10 history)
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

- Token counting dùng `len(prompt) / 4` (`chat/usecase/prompt.go:41`) — Go `len()` tính bytes, không phải runes. Tiếng Việt UTF-8 = 3 bytes/char, nên estimate sai ~3x.
- MaxTokenWindow = **28000** (`chat/types.go:11`)

---

### 1.4 Report Domain — COMPLETE MVP (thiếu PDF, progress)

**Flow thực tế (`report/usecase/generator.go`):**

```text
Generate():
  validate report_type + campaign_id
  → hash(campaign_id + report_type + filters) → check dedup
  → existing PROCESSING → return existing report_id
  → existing COMPLETED trong 1 giờ → reuse
  → INSERT reports (status=PROCESSING)
  → go generateInBackground()   ← goroutine không có panic recovery

generateInBackground():
  Phase 1: aggregateDocs (search, minScore=0.3, lấy rộng)
  → Phase 2: sampleDocs (lấy đều theo step)
  → Phase 3: Generate sections (LLM per section template)
  → Phase 4: compileMarkdown
  → Upload to MinIO: reports/{report_id}.md
  → UPDATE reports (status=COMPLETED, file_url, ...)
```

**UseCase interface:**

- `Generate` — tạo mới hoặc trả về existing
- `GetReport` — lấy status + metadata
- `DownloadReport` — presigned URL (30 min expiry)

**Report types:** SUMMARY | COMPARISON | TREND | ASPECT_DEEP_DIVE

**Thiếu:**

- PDF output: code chỉ upload `.md`, không có PDF conversion
- Progress % trong quá trình generate: chỉ có PROCESSING/COMPLETED/FAILED
- Inline edit report: không có trong codebase

---

## 2. Mapping: Doc cũ vs Code thực tế

| Điểm | `knowledge-report.md` (17/02/2026) | Code thực tế | Đúng/Sai |
| --- | --- | --- | --- |
| Kafka topic | `analytics.batch.completed` | `analytics.batch.completed` | ✅ Đúng |
| DLQ | Không nhắc tới | Implemented (`indexing_dlq`) | Doc thiếu |
| Retry/Reconcile | Không nhắc tới | Implemented | Doc thiếu |
| Report output | "PDF/Markdown" | **Chỉ Markdown** | ❌ Sai |
| Token counting | Không đề cập | `len/4` thô, MaxWindow=28000 | Doc thiếu |
| Conversation export | Không đề cập | Không có trong interface | N/A |
| 3-tier cache | Mô tả đúng | Implemented | ✅ Đúng |
| MinScore | Không đề cập | 0.65 cho cả search và chat | Doc thiếu |

| Điểm | `dataflow-detailed.md` (20/02/2026) | Code thực tế | Đúng/Sai |
| --- | --- | --- | --- |
| Kafka topic | `knowledge.index` | `analytics.batch.completed` | ❌ **Sai** |
| Inline edit report | Đề cập | Không có trong code | ❌ Feature chưa tồn tại |

---

## 3. Các vấn đề thực sự cần chú ý

### High

- **Analytics → Knowledge bridge chưa có**: Analytics publish JSON array lên `smap.analytics.output`, Knowledge đọc JSONL từ MinIO qua `analytics.batch.completed`. Không có component nào bridge 2 format này.

### Medium

- **Token counting thô** (`len/4` tại `prompt.go:41`): Go `len()` tính bytes. Tiếng Việt = 3 bytes/char → underestimate ~3x thực tế.
- **Report goroutine trần** (`go generateInBackground()` tại `report.go:95`): Nếu service restart giữa chừng, report stuck PROCESSING vĩnh viễn. Cần startup reconcile.
- **Không có rate limit** cho Voyage AI (`voyage-multilingual-2`) và Gemini calls.

### Low

- **PDF không có**: doc cũ nói "PDF/Markdown", code chỉ có Markdown.
- **Conversation export**: feature được nhắc trong planning nhưng chưa có.

---

## 4. Quick reference

```text
Service: knowledge-srv
Kafka input: analytics.batch.completed (consumer group: knowledge-indexing-batch)
HTTP: :8080
Auth: JWT cookie / Bearer + X-Service-Key cho internal

Embedding: Voyage AI (voyage-multilingual-2)
LLM: Gemini 1.5-pro
Vector DB: Qdrant
MinScore: 0.65 (search + chat), 0.3 (report aggregation)
MaxTokenWindow: 28000

External dependencies:
  - Voyage AI (embedding, cached 7 ngày)
  - Gemini 1.5-pro (LLM)
  - Qdrant (vector store)
  - PostgreSQL (metadata, conversations, reports, DLQ)
  - Redis (3-tier cache: embedding 7d, campaign 10m, search 5m)
  - MinIO (report files, raw indexed JSONL)
  - Project Service HTTP (read-only: /campaigns/:id → project_ids)
```
