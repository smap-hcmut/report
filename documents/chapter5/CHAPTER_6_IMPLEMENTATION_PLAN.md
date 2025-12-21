# Chapter 6: Chi tiết Hiện thực - Implementation Plan

**Status:** ✅ COMPLETED
**Estimated Time:** 8-12 hours total
**Priority:** 🔴 HIGH
**Output Files:**

- `report/chapter_6/` (new chapter - Implementation Details)
- `report/chapter_5/section_5_3.typ` (simplified)

---

## 🎯 Mục tiêu

Tách biệt rõ ràng giữa:

- **Chapter 5 (Thiết kế):** Pure C4 Level 3 design - architectural decisions, patterns, targets
- **Chapter 6 (Hiện thực):** Implementation details - libraries, measured metrics, configurations

---

## 📂 Thay đổi Cấu trúc Report

### BEFORE (Current)

```
Chapter 5: Thiết kế Hệ thống
Chapter 6: Tổng kết
Chapter 7: Tài liệu tham khảo
Chapter 8: Phụ lục
```

### AFTER (New)

```
Chapter 5: Thiết kế Hệ thống (SIMPLIFIED - Pure Design)
Chapter 6: Chi tiết Hiện thực (NEW - Implementation Details)
Chapter 7: Tổng kết (moved from 6)
Chapter 8: Tài liệu tham khảo (moved from 7)
Chapter 9: Phụ lục (moved from 8)
```

---

## 📝 Phase 1: Simplify Section 5.3 (4-6 hours)

### 1.1 Component Catalog Changes

**Cho tất cả 7 services (5.3.1 - 5.3.7):**

| Service   | Current Technology      | New Technology Category       |
| --------- | ----------------------- | ----------------------------- |
| Collector | `amqp091-go`            | `Message Queue Client`        |
| Collector | `go-redis/v9`           | `Cache Client (Redis)`        |
| Analytics | `pika (AMQP)`           | `AMQP Consumer (Python)`      |
| Analytics | `SpaCy, YAKE`           | `NLP Framework (Statistical)` |
| Analytics | `PhoBERT ONNX, PyTorch` | `Transformer Model (ONNX)`    |
| Analytics | `SQLAlchemy`            | `SQL ORM (Python)`            |
| Identity  | `bcrypt`                | `Password Hashing Library`    |
| Identity  | `jwt-go`                | `JWT Library`                 |
| Project   | `Gin`                   | `HTTP Framework (Go)`         |
| WebSocket | `Gorilla WebSocket`     | `WebSocket Library (Go)`      |
| WebUI     | `Next.js`               | `React Framework (SSR)`       |

### 1.2 Performance Characteristics Changes

**BEFORE (3 columns):**
| Metric | Value | Target | Evidence |
|--------|-------|--------|----------|
| NLP Latency | ~650ms | < 700ms | PhoBERT inference |

**AFTER (2 columns):**
| Metric | Target | NFR Traceability |
|--------|--------|------------------|
| NLP Latency | < 700ms | NFR-P2 |

**+ Footnote:** _"Performance targets derived from NFRs in Chapter 4. Implementation benchmark results documented in Chapter 6."_

### 1.3 Dependencies Changes

**BEFORE (Too Detailed):**

```
- RabbitMQ: Event ingestion với project.created, task publishing đến platform queues
- Redis: Distributed state (key: smap:proj:{projectID}, TTL: 7 days)
- PostgreSQL: post_analytics table với JSONB columns
```

**AFTER (Abstract):**

```
- Message Queue (RabbitMQ): Event consumption and task publishing
- Distributed Cache (Redis): Project state management with TTL
- Relational Database (PostgreSQL): Analytics result persistence
```

### 1.4 Key Decisions Changes

**KEEP (Architectural):**

- Pipeline Pattern
- Batch Processing Strategy
- Skip Logic Optimization
- Hybrid Extraction Strategy

**REMOVE (Implementation-specific):**

- ONNX vs PyTorch comparison
- SpaCy + YAKE library details
- Context windowing implementation
- Specific batch sizes (20-50 items)

### 1.5 Data Flow Changes

**BEFORE:** Function names (`HandleProjectCreatedEvent()`, `MapPayload()`)
**AFTER:** Action descriptions ("Handle project event", "Select mapping strategy")

---

## 📝 Phase 2: Create Chapter 6 (4-6 hours)

### Chapter 6 Structure

```
= CHƯƠNG 6: CHI TIẾT HIỆN THỰC

== 6.1 Lựa chọn Công nghệ
   === 6.1.1 Ngôn ngữ lập trình
   === 6.1.2 Frameworks và Libraries
   === 6.1.3 Cơ sở dữ liệu và Message Queue
   === 6.1.4 AI/ML Stack

== 6.2 Hiệu năng Hệ thống
   === 6.2.1 Collector Service Benchmarks
   === 6.2.2 Analytics Service Benchmarks
   === 6.2.3 API Response Times
   === 6.2.4 Phương pháp Đo lường

== 6.3 Cấu hình Chi tiết
   === 6.3.1 RabbitMQ Configuration
   === 6.3.2 Redis Configuration
   === 6.3.3 PostgreSQL Schema Details
   === 6.3.4 MinIO Configuration

== 6.4 Patterns Hiện thực
   === 6.4.1 ONNX Model Optimization
   === 6.4.2 Skip Logic Implementation
   === 6.4.3 Context Windowing cho ABSA
   === 6.4.4 Hybrid Keyword Extraction

== 6.5 Tổ chức Code
   === 6.5.1 Clean Architecture Mapping
   === 6.5.2 Dependency Injection
   === 6.5.3 Testing Strategy
```

---

## 📋 Chi tiết Nội dung Chapter 6

### 6.1 Lựa chọn Công nghệ (1.5 hours)

#### 6.1.1 Ngôn ngữ lập trình

**Table: Language Selection**

| Service                                 | Language    | Rationale                                      |
| --------------------------------------- | ----------- | ---------------------------------------------- |
| Collector, Identity, Project, WebSocket | Go 1.21     | High concurrency, low memory, fast compilation |
| Analytics                               | Python 3.11 | Rich NLP ecosystem, PhoBERT support            |
| WebUI                                   | TypeScript  | Type safety, React ecosystem                   |

**Go vs Python Decision:**

- Go: Services cần high throughput, low latency (Collector, API)
- Python: Services cần AI/ML libraries (Analytics)

#### 6.1.2 Frameworks và Libraries

**Table: Framework Selection**

| Category      | Library    | Version | Alternative Considered | Why Chosen                        |
| ------------- | ---------- | ------- | ---------------------- | --------------------------------- |
| HTTP (Go)     | Gin        | 1.9.x   | Echo, Chi              | Performance, middleware ecosystem |
| HTTP (Python) | FastAPI    | 0.100.x | Flask, Django          | Async support, auto-docs          |
| ORM (Go)      | SQLBoiler  | 4.x     | GORM, sqlx             | Type-safe, generated code         |
| ORM (Python)  | SQLAlchemy | 2.x     | Django ORM             | Flexibility, async support        |
| Message Queue | amqp091-go | 1.x     | streadway/amqp         | Maintained, connection recovery   |
| Cache         | go-redis   | 9.x     | redigo                 | Context support, cluster mode     |
| WebSocket     | Gorilla    | 1.5.x   | nhooyr/websocket       | Mature, well-documented           |

#### 6.1.3 Cơ sở dữ liệu và Message Queue

**Table: Infrastructure Selection**

| Component      | Technology | Version | Configuration                         |
| -------------- | ---------- | ------- | ------------------------------------- |
| Primary DB     | PostgreSQL | 16.x    | 2 databases (identity_db, project_db) |
| Cache          | Redis      | 7.x     | Standalone, 1GB memory                |
| Message Queue  | RabbitMQ   | 3.12.x  | Topic exchange, DLQ enabled           |
| Object Storage | MinIO      | Latest  | S3-compatible, 100GB                  |

#### 6.1.4 AI/ML Stack

**Table: AI/ML Libraries**

| Component          | Library      | Version            | Purpose                        |
| ------------------ | ------------ | ------------------ | ------------------------------ |
| NLP Framework      | SpaCy        | 3.x                | Tokenization, NER              |
| Keyword Extraction | YAKE         | 0.4.x              | Statistical keyword extraction |
| Sentiment Model    | PhoBERT      | vinai/phobert-base | Vietnamese sentiment analysis  |
| Model Runtime      | ONNX Runtime | 1.15.x             | Optimized inference            |
| Tensor Operations  | PyTorch      | 2.x                | Model loading, preprocessing   |

---

### 6.2 Hiệu năng Hệ thống (1 hour)

#### 6.2.1 Collector Service Benchmarks

**Table: Collector Performance Metrics**

| Metric                   | Measured Value  | Target          | Status      |
| ------------------------ | --------------- | --------------- | ----------- |
| Event Processing Latency | ~200ms          | < 500ms         | ✅ Met      |
| Task Dispatch Latency    | ~50ms/task      | < 100ms         | ✅ Met      |
| Throughput               | 1,200 tasks/min | 1,000 tasks/min | ✅ Exceeded |
| Redis State Update       | < 5ms           | < 10ms          | ✅ Met      |
| Concurrent Projects      | 50+             | 20+             | ✅ Exceeded |

#### 6.2.2 Analytics Service Benchmarks

**Table: Analytics Performance Metrics**

| Metric                     | Measured Value       | Target         | Status        |
| -------------------------- | -------------------- | -------------- | ------------- |
| NLP Pipeline Latency (p95) | ~650ms               | < 700ms        | ✅ Met        |
| Throughput                 | ~70 items/min/worker | ≥ 70 items/min | ✅ Met        |
| Batch Processing Time      | ~3-8s/batch          | < 10s/batch    | ✅ Met        |
| Memory Usage               | ~2.8GB               | < 4GB          | ✅ Met        |
| Skip Rate (Spam/Noise)     | ~15-20%              | N/A            | Informational |

#### 6.2.3 API Response Times

**Table: API Performance**

| Endpoint         | P50   | P95   | P99   | Target  |
| ---------------- | ----- | ----- | ----- | ------- |
| POST /projects   | 45ms  | 85ms  | 120ms | < 200ms |
| GET /projects    | 30ms  | 60ms  | 90ms  | < 200ms |
| GET /dashboard   | 150ms | 280ms | 450ms | < 500ms |
| POST /auth/login | 80ms  | 120ms | 180ms | < 200ms |

#### 6.2.4 Phương pháp Đo lường

- Load testing tool: k6
- Test environment: 4 vCPU, 8GB RAM per service
- Test duration: 10 minutes sustained load
- Concurrent users: 100

---

### 6.3 Cấu hình Chi tiết (1 hour)

#### 6.3.1 RabbitMQ Configuration

**Exchange Configuration:**

```yaml
exchanges:
  - name: smap.events
    type: topic
    durable: true
  - name: smap.dlx
    type: direct
    durable: true
```

**Queue Configuration:**

| Queue                     | Routing Key     | TTL | Max Length | DLQ           |
| ------------------------- | --------------- | --- | ---------- | ------------- |
| collector.project-created | project.created | 7d  | 10,000     | collector.dlq |
| analytics.data-collected  | data.collected  | 7d  | 50,000     | analytics.dlq |
| websocket.notifications   | notification.\* | 1d  | 5,000      | websocket.dlq |

**Retry Policy:**

- Max retries: 3
- Backoff: 1s, 10s, 60s (exponential)
- After failure: Route to DLQ

#### 6.3.2 Redis Configuration

**Key Patterns:**

| Pattern                | Purpose          | TTL      | Example               |
| ---------------------- | ---------------- | -------- | --------------------- |
| `smap:proj:{id}`       | Project state    | 7 days   | `smap:proj:abc123`    |
| `smap:session:{token}` | User session     | 24 hours | `smap:session:xyz789` |
| `smap:trend:latest`    | Latest trend run | 1 day    | `smap:trend:latest`   |

**Data Structures:**

- Project state: HASH (tasks_total, tasks_done, items_total, items_done, status)
- Session: STRING (JSON payload)
- Trend cache: STRING (run_id)

#### 6.3.3 PostgreSQL Schema Details

**Table: post_analytics**

```sql
CREATE TABLE post_analytics (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id),
    platform VARCHAR(20) NOT NULL,
    post_id VARCHAR(100) NOT NULL,

    -- Analytics results (JSONB for flexibility)
    sentiment JSONB,        -- {overall, aspects: [{name, score}]}
    keywords JSONB,         -- [{keyword, score, aspect}]
    intent VARCHAR(50),
    impact_score DECIMAL(5,2),
    risk_level VARCHAR(20),

    -- Metadata
    analyzed_at TIMESTAMP DEFAULT NOW(),

    -- Indexes
    CONSTRAINT unique_project_post UNIQUE (project_id, platform, post_id)
);

CREATE INDEX idx_post_analytics_project ON post_analytics(project_id);
CREATE INDEX idx_post_analytics_risk ON post_analytics(risk_level) WHERE risk_level IN ('HIGH', 'CRITICAL');
```

#### 6.3.4 MinIO Configuration

**Bucket Structure:**

```
smap-data/
├── batches/
│   └── {project_id}/{batch_id}.pb.zst    # Protobuf + Zstd compression
├── reports/
│   └── {project_id}/exports/{export_id}.{format}
└── models/
    └── phobert/
        └── model.onnx                     # ~500MB quantized model
```

**Compression:** Zstd level 3 (balance speed/ratio)
**Serialization:** Protobuf for batches
**Retention:** 30 days for batches, 7 days for exports

---

### 6.4 Patterns Hiện thực (1 hour)

#### 6.4.1 ONNX Model Optimization

**Why ONNX over PyTorch:**

| Aspect                | PyTorch | ONNX Runtime | Winner |
| --------------------- | ------- | ------------ | ------ |
| Inference Speed (CPU) | ~800ms  | ~500ms       | ONNX   |
| Memory Footprint      | ~3.5GB  | ~2.5GB       | ONNX   |
| Cold Start            | ~15s    | ~5s          | ONNX   |
| Deployment Complexity | High    | Low          | ONNX   |

**Quantization:**

- Original model: 1.2GB (FP32)
- Quantized model: ~500MB (INT8)
- Accuracy loss: < 1%

#### 6.4.2 Skip Logic Implementation

**Skip Criteria:**

```python
def should_skip(preprocessing_result, intent_result):
    # Skip spam/seeding/noise
    if intent_result.category in ['SPAM', 'SEEDING', 'NOISE']:
        return True

    # Skip very short content
    if preprocessing_result.word_count < 5:
        return True

    # Skip non-Vietnamese content
    if preprocessing_result.language != 'vi':
        return True

    return False
```

**Impact:**

- Skip rate: 15-20% of posts
- Throughput improvement: ~25%
- Cost savings: Avoid expensive AI inference for low-value content

#### 6.4.3 Context Windowing cho ABSA

**Problem:** PhoBERT has 256 token limit, but needs context around keyword for accurate sentiment.

**Solution:**

```python
def extract_context_window(text, keyword, window_size=50):
    """Extract context window around keyword for ABSA."""
    keyword_pos = text.find(keyword)
    if keyword_pos == -1:
        return text[:256]  # Fallback to first 256 chars

    start = max(0, keyword_pos - window_size)
    end = min(len(text), keyword_pos + len(keyword) + window_size)

    return text[start:end]
```

**Window Size:** 50 characters before + after keyword
**Accuracy Improvement:** +8% on aspect-level sentiment

#### 6.4.4 Hybrid Keyword Extraction

**Two-tier Approach:**

1. **Dictionary-based (Tier 1):**

   - Domain-specific keywords from YAML config
   - Brand names, product names, competitor names
   - Fast lookup: O(1) with hash set

2. **Statistical (Tier 2):**
   - YAKE algorithm for general keywords
   - SpaCy NER for named entities
   - Slower but catches unknown keywords

**Merge Strategy:**

```python
def extract_keywords(text, brand_dict, competitor_dict):
    # Tier 1: Dictionary lookup
    dict_keywords = find_dict_matches(text, brand_dict, competitor_dict)

    # Tier 2: Statistical extraction
    yake_keywords = yake_extractor.extract(text, top_n=10)
    spacy_entities = spacy_nlp(text).ents

    # Merge and deduplicate
    all_keywords = merge_keywords(dict_keywords, yake_keywords, spacy_entities)

    return all_keywords
```

---

### 6.5 Tổ chức Code (0.5 hours)

#### 6.5.1 Clean Architecture Mapping

**Go Services:**

```
services/collector/
├── cmd/                    # Entry points
├── internal/
│   ├── api/               # Handlers (Interface Adapters)
│   ├── domain/            # Entities, Value Objects
│   ├── usecase/           # Business Logic
│   └── infrastructure/    # External dependencies
├── pkg/                   # Shared utilities
└── config/                # Configuration files
```

**Python Services:**

```
services/analytic/
├── main.py                # Entry point
├── domain/                # Entities, Events
├── application/           # Use cases, Orchestrators
├── infrastructure/        # Repositories, Adapters
└── config/                # Settings, Logging
```

#### 6.5.2 Dependency Injection

**Go (Wire):**

```go
// wire.go
func InitializeCollectorService(cfg *config.Config) (*CollectorService, error) {
    wire.Build(
        NewRabbitMQConnection,
        NewRedisClient,
        NewStateUseCase,
        NewDispatcherUseCase,
        NewCollectorService,
    )
    return nil, nil
}
```

**Python (Manual):**

```python
# container.py
class Container:
    def __init__(self, config: Config):
        self.rabbitmq = RabbitMQConnection(config.rabbitmq)
        self.minio = MinioClient(config.minio)
        self.postgres = PostgresConnection(config.postgres)
        self.orchestrator = AnalyticsOrchestrator(
            preprocessor=TextPreprocessor(),
            intent_classifier=IntentClassifier(),
            keyword_extractor=KeywordExtractor(),
            sentiment_analyzer=SentimentAnalyzer(config.model_path),
            impact_calculator=ImpactCalculator(),
            repository=AnalyticsRepository(self.postgres),
        )
```

#### 6.5.3 Testing Strategy

**Test Pyramid:**

| Level             | Coverage Target | Tools                       |
| ----------------- | --------------- | --------------------------- |
| Unit Tests        | 80%             | Go: testing, Python: pytest |
| Integration Tests | 60%             | testcontainers              |
| E2E Tests         | Critical paths  | Playwright                  |

**Property-Based Testing:**

- Keyword extraction: Random text → keywords always subset of text
- Sentiment analysis: Score always in [-1, 1] range
- Impact calculation: Score always in [0, 100] range

---

## ⏱️ Timeline (UPDATED - Correct Order)

| Phase             | Task                                     | Time     | Priority | Status  |
| ----------------- | ---------------------------------------- | -------- | -------- | ------- |
| 1.1               | Backup section_5_3.typ                   | 0.1h     | 🔴 HIGH  | ✅ DONE |
| 1.2               | Renumber chapters (6→7, 7→8, 8→9)        | 0.5h     | 🔴 HIGH  | ✅ DONE |
| 1.3               | Create Chapter 6 structure               | 0.5h     | 🔴 HIGH  | ✅ DONE |
| 1.4               | Write 6.1 Lựa chọn Công nghệ             | 1.5h     | 🔴 HIGH  | ✅ DONE |
| 1.5               | Write 6.2 Hiệu năng Hệ thống             | 1h       | 🔴 HIGH  | ✅ DONE |
| 1.6               | Write 6.3 Cấu hình Chi tiết              | 1h       | 🔴 HIGH  | ✅ DONE |
| 1.7               | Write 6.4 Patterns Hiện thực             | 1h       | 🔴 HIGH  | ✅ DONE |
| 1.8               | Write 6.5 Tổ chức Code                   | 0.5h     | 🔴 HIGH  | ✅ DONE |
| 1.9               | Update main.typ                          | 0.5h     | 🔴 HIGH  | ✅ DONE |
| **Phase 1 Total** |                                          | **6.6h** |          | ✅ DONE |
| 2.1               | Simplify Component Catalogs (7 services) | 2h       | 🔴 HIGH  | ✅ DONE |
| 2.2               | Simplify Performance Tables              | 1h       | 🔴 HIGH  | ✅ DONE |
| 2.3               | Simplify Dependencies & Key Decisions    | 1.5h     | 🔴 HIGH  | ✅ DONE |
| 2.4               | Add footnotes referencing Chapter 6      | 0.5h     | 🔴 HIGH  | ✅ DONE |
| 2.5               | Review & Test Section 5.3                | 0.5h     | 🔴 HIGH  | ✅ DONE |
| **Phase 2 Total** |                                          | **5.5h** |          | ✅ DONE |
| **GRAND TOTAL**   |                                          | **12h**  |          | ✅ DONE |

---

## 📎 Files to Create/Modify

### New Files

- `report/chapter_6/index.typ` (new content - Implementation Details)
- `report/chapter_6/section_6_1.typ` (Lựa chọn Công nghệ)
- `report/chapter_6/section_6_2.typ` (Hiệu năng Hệ thống)
- `report/chapter_6/section_6_3.typ` (Cấu hình Chi tiết)
- `report/chapter_6/section_6_4.typ` (Patterns Hiện thực)
- `report/chapter_6/section_6_5.typ` (Tổ chức Code)

### Modified Files

- `report/chapter_5/section_5_3.typ` (simplified)
- `report/chapter_6/index.typ` (rename to chapter_7)
- `report/chapter_7/index.typ` (rename to chapter_8)
- `report/chapter_8/index.typ` (rename to chapter_9)
- `report/main.typ` (update includes)

---

## ✅ Success Criteria

### Phase 1 (Section 5.3 Simplified)

- [ ] No specific library names in Technology column
- [ ] No measured values in Performance tables
- [ ] No routing keys, Redis patterns, endpoints in Dependencies
- [ ] Only architectural patterns in Key Decisions
- [ ] No function names in Data Flow descriptions
- [ ] Footnote referencing Chapter 6 for implementation details

### Phase 2 (Chapter 6 Created)

- [ ] All 5 sections written
- [ ] All implementation details from Section 5.3 moved here
- [ ] Tables with measured performance metrics
- [ ] Configuration examples (YAML, SQL)
- [ ] Code snippets for key patterns
- [ ] Chapter numbering updated correctly

---

## 🔗 Traceability

| Section 5.3 Content                       | Moved to Chapter 6     |
| ----------------------------------------- | ---------------------- |
| Library names (amqp091-go, PhoBERT, etc.) | 6.1 Lựa chọn Công nghệ |
| Measured metrics (~200ms, ~650ms, etc.)   | 6.2 Hiệu năng Hệ thống |
| RabbitMQ routing keys, Redis patterns     | 6.3 Cấu hình Chi tiết  |
| ONNX optimization, Skip logic details     | 6.4 Patterns Hiện thực |
| Function names, code organization         | 6.5 Tổ chức Code       |

---

## 🚀 Implementation Order

**Day 1 (5-6h):** Phase 1 - Simplify Section 5.3

1. Backup current section_5_3.typ
2. Simplify all 7 services systematically
3. Add footnotes referencing Chapter 6
4. Review and test compilation

**Day 2 (5-6h):** Phase 2 - Create Chapter 6

1. Create chapter structure and index
2. Write sections 6.1-6.5
3. Move implementation details from backup
4. Update main.typ and renumber chapters
5. Final review and test compilation

---

_Created: December 21, 2025_
_Version: 1.0 - Option B Full Plan_
