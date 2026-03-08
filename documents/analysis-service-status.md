# Analysis Service: Current Status (Từ Code)

**Ngày review:** 06/03/2026
**Nguồn:** Đọc trực tiếp từ code `services/analysis/`
**Trạng thái tổng:** Pipeline hoạt động, nhưng có integration gap nghiêm trọng với Knowledge Service

---

## 1. Architecture thực tế

**Quan trọng — khác hoàn toàn với `dataflow-detailed.md`:**

| Điểm | `dataflow-detailed.md` nói | Code thực tế |
|---|---|---|
| Ngôn ngữ | Go orchestrator + Python micro-workers | **Pure Python async** |
| Kiến trúc | `analytics-consumer (Go)` gọi HTTP sang `py-worker-*` | **Single Python process, in-process stages** |
| Giao tiếp AI | HTTP REST giữa các service | **Direct function call trong cùng process** |

Không có Go component. Không có HTTP giữa các stage. Toàn bộ pipeline là 1 Python process.

---

## 2. Pipeline thực tế (5 stages trong 1 process)

**Kafka input:** Topic đọc từ config (không hardcode trong code Python).
**UAP version:** Bắt buộc `uap_version: "1.0"`. Tin nhắn không có field này → silently skip.

```text
Kafka message (UAP v1.0)
  → parse + validate (doc_id, project_id required)
  → Stage 1: Text Preprocessing (spam detection, text cleaning)
  → Stage 2: Intent Classification (patterns-based)
      └── intent = SPAM/SEEDING → early exit, skip stages 3-5
  → Stage 3: Keyword Extraction (SpacyYake + aspect dictionary)
  → Stage 4: Sentiment Analysis (PhoBERT ONNX, ABSA)
  → Stage 5: Impact Calculation (engagement, virality, risk, KOL)
  → Persist to PostgreSQL schema_analysis.post_insight
  → Build InsightMessage (UAP + analytics result)
  → Publish to Kafka: smap.analytics.output (batch JSON array, size=10)
```

**Error handling per stage:** Mỗi stage có `try/except`, lỗi bị log và skip — pipeline tiếp tục với giá trị default. Stage lỗi không làm dừng pipeline.

**Exception routing ở Kafka handler:**

- JSON parse error → log + skip (commit offset)
- UAP validation error → log + skip (commit offset)
- Business error → raise (KHÔNG commit offset → retry on next poll)

---

## 3. Kafka contracts

**Input:**

```text
Topic: config-driven (đọc từ kafka_consumer_config.topics)
Format: UAP v1.0 JSON { uap_version, event_id, ingest, content, signals, context }
```

**Output:**

```text
Topic: smap.analytics.output (hardcoded)
Format: JSON array of InsightMessage (batch = 10 items default)
Message: [{
  message_version, event_id,
  project: { project_id, entity_type, entity_name, brand, campaign_id },
  identity: { source_type, source_id, doc_id, doc_type, published_at, author },
  content: { text, clean_text },
  nlp: { sentiment, aspects, entities },
  business: { impact, alerts },
  rag: { index: { should_index, quality_gate }, citation, vector_ref },
  provenance: { raw_ref, pipeline }
}]
```

**`rag.index.should_index`:** Flag trong InsightMessage để đánh dấu document có nên index vào Qdrant không. Logic: `min_length_ok AND not_spam`. Tuy nhiên — xem Issue #1 bên dưới.

---

## 4. Database

**Schema:** `schema_analysis`
**Table:** `post_insight` — lưu full analytics result per document

Các field chính:

- Sentiment: `overall_sentiment`, `overall_sentiment_score`, `sentiment_confidence`, `aspects` (JSONB)
- Impact: `engagement_score`, `virality_score`, `influence_score`, `impact_score`
- Risk: `risk_level`, `risk_factors`, `requires_attention`, `alert_triggered`
- Quality: `is_spam`, `is_bot`, `toxicity_score`, `content_quality_score`
- Processing: `primary_intent`, `model_version`, `processing_status`, `processing_time_ms`

---

## 5. Vấn đề nghiêm trọng

### Issue #1 — CRITICAL: Integration gap giữa Analytics và Knowledge

**Vấn đề:** Analytics và Knowledge service đang dùng 2 contract khác nhau, không có bridge.

```text
Analytics OUTPUT:
  Topic: smap.analytics.output
  Format: JSON array of InsightMessage (in-memory batch)
  Routing: Kafka partition by project_id

Knowledge INPUT:
  Topic: analytics.batch.completed
  Format: { batch_id, project_id, file_url, record_count, completed_at }
  file_url: s3://bucket/path/to/batch.jsonl  ← file trên MinIO
```

Analytics publish trực tiếp lên Kafka dạng JSON. Knowledge đọc JSONL file từ MinIO. **Không có component nào convert giữa 2 format này.**

Kết quả: Ngay cả khi cả 2 service đều chạy đúng, Knowledge service sẽ không nhận được data từ Analytics.

**Cần thêm một trong hai:**

- Option A: Analytics viết JSONL batch ra MinIO sau mỗi flush, rồi publish `analytics.batch.completed`
- Option B: Knowledge subscribe trực tiếp `smap.analytics.output` và bỏ `analytics.batch.completed`
- Option C: Thêm một batch writer service giữa 2 service (overkill)

### Issue #2 — HIGH: `analytics.metrics.aggregated` không tồn tại

Doc (`dataflow-detailed.md`) nói Analytics publish `analytics.metrics.aggregated` mỗi 5 phút cho project-scheduler để detect crisis.

Trong code: **Topic này không có**. Producer/constant.py chỉ có `smap.analytics.output`. Không có cron job hay metrics aggregator nào trong service.

Kết quả: Toàn bộ Adaptive Crawl flow trong `dataflow-detailed.md` Section 6 không có nền tảng để chạy. Project-scheduler không có data để ra quyết định crisis.

### Issue #3 — MEDIUM: Legacy code trong `delivery/constant.py`

```python
# Còn trong file nhưng không được dùng ở đâu
FIELD_MINIO_PATH = "minio_path"
FIELD_JOB_ID = "job_id"
FIELD_BATCH_INDEX = "batch_index"
EVENT_DATA_COLLECTED = "data.collected"
FIELD_BRAND_NAME = "brand_name"
FIELD_KEYWORD = "keyword"
```

Đây là constants từ kiến trúc cũ (trước UAP). Không ảnh hưởng runtime, nhưng gây nhầm lẫn khi đọc code.

### Issue #4 — MEDIUM: In-memory batch buffer có thể mất data

```python
# publisher.py
self._buffer: list[InsightMessage] = []
# flush khi buffer >= 10
```

Nếu service crash khi buffer chứa 1-9 items chưa flush, toàn bộ bị mất. Không có persistence, không có retry từ phía analytics (offset đã commit).

### Issue #5 — LOW: Input topic không hardcode

Topic input đọc từ config. Nếu config sai, service khởi động không lỗi nhưng không nhận message nào. Cần document rõ expected config value.

---

## 6. Mapping: Doc cũ vs Code thực tế

| Điểm | `analysis-report.md` / `dataflow-detailed.md` | Code thực tế | Đúng/Sai |
|---|---|---|---|
| Ngôn ngữ | Go orchestrator | Python async | ❌ Sai hoàn toàn |
| Pipeline kiến trúc | Go gọi HTTP sang py-workers | Single Python process | ❌ Sai |
| Output topic | `smap.analytics.output` | `smap.analytics.output` | ✅ Đúng |
| 5-stage pipeline | Mô tả đúng thứ tự | ✅ Match | ✅ Đúng |
| `analytics.metrics.aggregated` | Có, publish mỗi 5 phút | **Không tồn tại** | ❌ Sai |
| Analytics → Knowledge | qua `knowledge.index` topic | Qua `smap.analytics.output` nhưng Knowledge đọc `analytics.batch.completed` | ❌ Broken |
| Early exit SPAM/SEEDING | Đề cập | Implemented | ✅ Đúng |
| PhoBERT ONNX | Đúng | Có file `model/phobert/phobert.onnx` | ✅ Đúng |

---

## 7. Quick reference

```text
Service: analysis-srv (Python)
Runtime: asyncio
Input: Kafka topic (config-driven), UAP v1.0 format
Output: smap.analytics.output, JSON array of InsightMessage, batch=10
DB: PostgreSQL schema_analysis.post_insight
Model: PhoBERT ONNX (local file), SpacyYake

Pipeline stages (in-process):
  1. Text Preprocessing (spam filter)
  2. Intent Classification (pattern-based, early exit)
  3. Keyword Extraction (SpacyYake + aspect dictionary)
  4. Sentiment (PhoBERT ONNX + ABSA)
  5. Impact Calculation (engagement, virality, risk)

Missing pieces:
  - Bridge: smap.analytics.output → analytics.batch.completed (for knowledge)
  - Missing: analytics.metrics.aggregated (for project-scheduler / adaptive crawl)
```
