# Section 5.3 Detail Level Analysis

## Executive Summary

Section 5.3 hiện tại đang ở mức **C4 Level 3.5-4** (giữa Component và Code level) thay vì **C4 Level 3** (Component level) thuần túy. Nhiều chi tiết implementation-specific làm cho section này:

1. **Yêu cầu có implementation thực tế** để viết chính xác (measured metrics, specific libraries)
2. **Dễ bị ảnh hưởng bởi thay đổi** (library upgrades, refactoring, performance tuning)
3. **Dễ bị chất vấn** trong report thiết kế (tại sao dùng library này, metrics này đúng không?)

## Chi tiết Các Vấn đề

### 1. Component Catalog - Technology Column

**Vấn đề:** Liệt kê tên library cụ thể thay vì technology category

**Ví dụ từ Collector Service (lines 47-106):**

| Component | Technology (HIỆN TẠI) | Vấn đề |
|-----------|----------------------|---------|
| ProjectEvent Consumer | `amqp091-go` | Specific Go library name - requires knowing exact library choice |
| State UseCase | `go-redis/v9` | Version number - changes with upgrades |
| Webhook UseCase | `net/http` | Built-in library - not architectural decision |

**Ví dụ từ Analytics Service (lines 256-339):**

| Component | Technology (HIỆN TẠI) | Vấn đề |
|-----------|----------------------|---------|
| EventConsumer | `pika (AMQP)` | Specific Python library |
| Text Preprocessor | `unicodedata, re` | Built-in modules - not design decision |
| Keyword Extractor | `SpaCy, YAKE` | Specific NLP libraries |
| Sentiment Analyzer | `PhoBERT ONNX, PyTorch` | Specific model format and framework |
| Analytics Repository | `SQLAlchemy` | Specific ORM library |

**ĐỀ XUẤT ABSTRACT:**

| Component | Technology (ABSTRACT) | Benefit |
|-----------|----------------------|---------|
| ProjectEvent Consumer | Message Queue Client | Independent of library choice |
| State UseCase | Cache Client (Redis) | Shows technology type, not version |
| Webhook UseCase | HTTP Client | Architectural decision only |
| EventConsumer | AMQP Consumer (Python) | Shows protocol and language |
| Text Preprocessor | Text Processing (Built-in) | Indicates no external dependency |
| Keyword Extractor | NLP Framework (Statistical) | Shows approach, not library |
| Sentiment Analyzer | Transformer Model (ONNX) | Shows model type and optimization |
| Analytics Repository | SQL ORM | Generic ORM concept |

---

### 2. Performance Characteristics - Measured Values

**Vấn đề:** Hiển thị measured values từ production - yêu cầu có implementation thực tế

**Ví dụ từ Collector Service (lines 162-197):**

| Metric | Value (MEASURED) | Target | Vấn đề |
|--------|------------------|--------|---------|
| Event Processing Latency | **~200ms** | < 500ms | Measured value - requires actual implementation |
| Task Dispatch Latency | **~50ms/task** | < 100ms | Requires production measurement |
| Throughput (Tasks/min) | **1,200 tasks/min** | 1,000 tasks/min | Requires load testing |
| Redis State Update | **< 5ms** | < 10ms | Requires Redis benchmark |
| Concurrent Projects | **50+ projects** | 20+ projects | Requires production data |

**Ví dụ từ Analytics Service (lines 377-412):**

| Metric | Value (MEASURED) | Target | Vấn đề |
|--------|------------------|--------|---------|
| NLP Pipeline Latency (p95) | **~650ms** | < 700ms | Requires profiling actual PhoBERT inference |
| Throughput (Items/min/worker) | **~70 items/min** | ~70 items/min | Requires worker benchmarking |
| Batch Processing Time | **~3-8s/batch** | < 10s/batch | Requires actual batch processing test |
| Memory Usage | **~2.8GB** | < 4GB | Requires memory profiling of PhoBERT model |
| Skip Rate (Spam/Noise) | **~15-20%** | N/A | Requires production data analysis |

**ĐỀ XUẤT SIMPLIFICATION:**

Option 1: **Chỉ hiển thị Targets (từ NFRs)**

| Metric | Target (from NFRs) | Traceability |
|--------|-------------------|--------------|
| API Response Time | P95 < 200ms | NFR-P1 |
| NLP Pipeline Latency | < 700ms | NFR-P2 |
| Throughput | 1,000 tasks/min | NFR-P3 |
| Memory per Worker | < 4GB | NFR-P4 |

Option 2: **Footnote cho Measured Values**

"Performance metrics listed are targets derived from NFRs. Actual measured values during implementation are documented in Appendix B: Implementation Benchmarks."

---

### 3. Dependencies - Implementation Details

**Vấn đề:** Liệt kê specific configuration thay vì architectural relationships

**Ví dụ từ Collector Service (lines 209-223):**

**HIỆN TẠI (quá chi tiết):**
```
External Dependencies:
- RabbitMQ: Event ingestion với project.created, task publishing đến platform queues,
  result consumption từ results.inbound.data.
- Redis: Distributed state management (key: `smap:proj:{projectID}`, TTL: 7 days).
- Project Service: Progress webhook callbacks (HTTP POST `/projects/{id}/progress`).
```

**Specific Implementation Details:**
- RabbitMQ routing keys: `project.created`, `results.inbound.data`
- Redis key pattern: `smap:proj:{projectID}`
- Redis TTL: `7 days`
- HTTP endpoint: `POST /projects/{id}/progress`

**ĐỀ XUẤT ABSTRACT:**

```
External Dependencies:
- Message Queue (RabbitMQ): Event consumption and task publishing with topic-based routing
- Distributed Cache (Redis): Project state management with TTL-based expiration
- Project Service: Progress notification via HTTP webhook callbacks
```

**Ví dụ từ Analytics Service (lines 426-443):**

**HIỆN TẠI (quá chi tiết):**
```
External Dependencies:
- RabbitMQ: Event ingestion (`data.collected` events).
- MinIO: Raw data storage (batches 20-50 items, Zstd compressed, Protobuf format).
- PostgreSQL: Result persistence (`post_analytics` table với JSONB columns, `post_comments` table).
- PhoBERT Model: ONNX quantized model (~500MB, downloaded từ MinIO, cached locally).
```

**ĐỀ XUẤT ABSTRACT:**

```
External Dependencies:
- Message Queue (RabbitMQ): Consumes data collection events
- Object Storage (MinIO): Batch data retrieval with compression and binary serialization
- Relational Database (PostgreSQL): Structured result persistence with flexible schema (JSONB)
- NLP Model (PhoBERT): Vietnamese sentiment analysis model with ONNX optimization
```

---

### 4. Key Decisions - Implementation Choices vs. Architectural Decisions

**Vấn đề:** Mix architectural decisions với implementation choices

**Ví dụ từ Analytics Service (lines 414-425):**

**Implementation Choices (CHI TIẾT QUÁ):**
1. **ONNX Optimization**: "Sử dụng PhoBERT ONNX quantized model thay vì PyTorch native model. ONNX runtime nhanh hơn trên CPU, memory footprint nhỏ hơn, và dễ deploy."
   - Vấn đề: Specific library choice (ONNX vs PyTorch)
   - Yêu cầu: Benchmarking actual model formats

2. **Skip Logic**: "Skip expensive AI steps cho spam/seeding/noise posts dựa trên IntentClassifier và Preprocessing stats. Tiết kiệm thời gian xử lý, improve throughput."
   - Vấn đề: Specific implementation detail (IntentClassifier logic)
   - Yêu cầu: Implementation code to validate approach

3. **Batch Processing**: "Process batches từ MinIO thay vì process từng item riêng lẻ. Giảm overhead của multiple MinIO calls, tối ưu network bandwidth."
   - OK: This is architectural (batch vs stream processing)

4. **Hybrid Keyword Extraction**: "Kết hợp Dictionary-based lookup và SpaCy-YAKE statistical extraction. Dictionary cho domain-specific keywords, YAKE cho general keywords."
   - Vấn đề: Specific library names (SpaCy, YAKE)

5. **Context Windowing cho ABSA**: "Sử dụng context windowing technique cho aspect-based sentiment analysis. PhoBERT cần context xung quanh keyword để predict sentiment chính xác."
   - Vấn đề: Very implementation-specific (windowing technique)

**ĐỀ XUẤT PHÂN LOẠI:**

**Keep in Section 5.3 (Architectural Decisions):**
- Batch Processing Pattern
- Pipeline Pattern (5-step NLP flow)
- Skip Logic Pattern (early return for low-value items)
- Hybrid Strategy Pattern (combine multiple approaches)

**Move to Implementation Chapter (Implementation Choices):**
- ONNX vs PyTorch model format comparison
- SpaCy + YAKE library integration
- Context windowing implementation details
- Specific performance benchmarks

---

### 5. Data Flow Diagrams - Function Names

**Vấn đề:** Reference specific function/method names

**Ví dụ từ Collector Service Data Flow (lines 108-146):**

- "Call `HandleProjectCreatedEvent()`" (line 67)
- "`MapPayload()` function" (line 156)
- "`DispatcherUseCase.Dispatch`" (line 129-134 reference)
- "HMSet/HGetAll operations" (line 191)

**ĐỀ XUẤT:**

Thay function names bằng action descriptions:
- "Call `HandleProjectCreatedEvent()`" → "Handle project creation event"
- "`MapPayload()` function chọn strategy" → "Select payload mapping strategy"
- "`DispatcherUseCase.Dispatch`" → "Dispatch tasks to workers"
- "HMSet/HGetAll operations" → "Redis hash operations"

---

## Tổng kết: Implementation-Specific Content

| Category | Số lượng Chi tiết Implementation | Examples |
|----------|--------------------------------|----------|
| **Specific Library Names** | ~35 instances | amqp091-go, go-redis/v9, SQLAlchemy, SpaCy, YAKE, PhoBERT, etc. |
| **Measured Performance Metrics** | ~25 metrics | ~200ms, ~650ms, ~2.8GB, 1,200 tasks/min, etc. |
| **Configuration Details** | ~15 details | Redis TTL: 7 days, bcrypt cost 10, batch size: 20-50, etc. |
| **Function/Method Names** | ~10 references | HandleProjectCreatedEvent(), MapPayload(), HMSet/HGetAll, etc. |
| **Specific Endpoints/Keys** | ~12 details | POST /projects/{id}/progress, smap:proj:{projectID}, project.created, etc. |

**Total Implementation-Specific Details:** ~97 instances across 7 services

---

## Đề xuất Giải pháp

### Option A: Simplify Section 5.3 (Recommended for Quick Fix)

**Thay đổi:**

1. **Component Catalog - Technology Column:**
   - Before: `amqp091-go`, `go-redis/v9`, `SQLAlchemy`
   - After: `Message Queue Client`, `Cache Client (Redis)`, `SQL ORM`

2. **Performance Characteristics:**
   - Before: Table with "Value" column showing measured metrics
   - After: Table with only "Target" column from NFRs + footnote
   - Footnote: "Measured values documented in implementation benchmarks (Appendix B)"

3. **Dependencies:**
   - Before: Specific routing keys, Redis key patterns, endpoint URLs
   - After: High-level dependency descriptions without configuration details

4. **Key Decisions:**
   - Keep only architectural patterns (Pipeline, Strategy, Repository)
   - Remove library-specific choices (ONNX vs PyTorch, SpaCy vs others)

5. **Data Flow Diagrams:**
   - Replace function names with action descriptions
   - Remove specific Redis commands (HMSet → "hash operations")

**Effort:** ~4-6 hours to revise all 7 services

**Benefit:**
- Section 5.3 becomes pure design (C4 Level 3)
- Independent of implementation changes
- Less questionable in report review

**Drawback:**
- Lose detailed technical information
- Need appendix or separate doc for implementation details

---

### Option B: Create New Implementation Chapter (Recommended for Comprehensive Documentation)

**Structure:**

```
Chapter 5: Thiết kế Hệ thống (CURRENT - KEEP AS DESIGN ONLY)
├── 5.1 Design Principles
├── 5.2 Architecture Overview (C4 Level 2)
├── 5.3 Service Components (C4 Level 3 - SIMPLIFIED)
│   ├── 5.3.1 Collector Service - Component Diagram (DESIGN ONLY)
│   │   - Component responsibilities (what, not how)
│   │   - Component interfaces (contracts)
│   │   - Design patterns (architecture-level)
│   │   - Performance targets (from NFRs, not measured)
│   ├── 5.3.2 Analytics Service - Component Diagram (DESIGN ONLY)
│   └── ... (other services)
├── 5.4 Data Model Design (ERD)
├── 5.5 Sequence Diagrams (Use Cases)
├── 5.6 Communication Patterns
└── 5.7 Traceability & Validation

Chapter 7: Chi tiết Hiện thực (NEW - IMPLEMENTATION DETAILS)
├── 7.1 Technology Stack Justification
│   ├── 7.1.1 Language Choices (Go vs Python)
│   ├── 7.1.2 Framework Selection (Echo, FastAPI, Next.js)
│   ├── 7.1.3 Library Decisions (amqp091-go, SQLAlchemy, PhoBERT)
│   └── 7.1.4 Alternatives Considered and Trade-offs
├── 7.2 Performance Benchmarks
│   ├── 7.2.1 Collector Service Metrics (~200ms, 1,200 tasks/min)
│   ├── 7.2.2 Analytics Service Metrics (~650ms, ~70 items/min)
│   ├── 7.2.3 Benchmark Methodology and Test Environments
│   └── 7.2.4 Performance Optimization Results
├── 7.3 Configuration Details
│   ├── 7.3.1 RabbitMQ Setup (exchanges, routing keys, queues)
│   ├── 7.3.2 Redis Configuration (key patterns, TTL policies)
│   ├── 7.3.3 Database Schema Details (JSONB columns, indexes)
│   └── 7.3.4 MinIO Configuration (buckets, compression, retention)
├── 7.4 Implementation Patterns
│   ├── 7.4.1 ONNX Model Optimization (PhoBERT quantization)
│   ├── 7.4.2 Skip Logic Implementation (IntentClassifier details)
│   ├── 7.4.3 Context Windowing for ABSA
│   └── 7.4.4 Hybrid Keyword Extraction (SpaCy + YAKE)
└── 7.5 Code Organization
    ├── 7.5.1 Clean Architecture Layer Mapping
    ├── 7.5.2 Dependency Injection Setup
    └── 7.5.3 Testing Strategy
```

**Effort:** ~8-12 hours to create new chapter and revise Section 5.3

**Benefit:**
- Clear separation: Design (Chapter 5) vs Implementation (Chapter 7)
- Section 5.3 becomes reviewable without implementation
- Chapter 7 provides full technical depth for developers
- Easy to maintain: design changes → update Chapter 5, implementation changes → update Chapter 7

**Drawback:**
- More work upfront
- Longer report overall

---

## So sánh Cụ thể: Before vs After

### Example 1: Collector Service - Component Catalog

**BEFORE (Current - 1310 lines):**

```typst
table.cell(...)[*Technology*],
table.cell(...)[ProjectEvent \ Consumer],
table.cell(...)[Consume `project.created` events từ RabbitMQ exchange `smap.events`],
table.cell(...)[RabbitMQ message: ProjectCreated \ Event],
table.cell(...)[Call HandleProject \ CreatedEvent()],
table.cell(...)[amqp091-go],  ← SPECIFIC LIBRARY

table.cell(...)[Dispatcher \ UseCase],
table.cell(...)[Transform project events thành crawl tasks, dispatch đến platform queues],
table.cell(...)[ProjectCreated \ Event],
table.cell(...)[CollectorTask[] published to RabbitMQ],
table.cell(...)[Pure Go logic],

table.cell(...)[State \ UseCase],
table.cell(...)[Quản lý trạng thái project trong Redis với Hybrid State gồm tasks và items],
table.cell(...)[ProjectID, state updates],
table.cell(...)[Redis HASH operations],
table.cell(...)[go-redis/v9],  ← SPECIFIC LIBRARY + VERSION
```

**AFTER (Option A - Simplified):**

```typst
table.cell(...)[*Technology Category*],
table.cell(...)[ProjectEvent \ Consumer],
table.cell(...)[Consume project lifecycle events from message queue],
table.cell(...)[Project creation event payload],
table.cell(...)[Trigger task orchestration],
table.cell(...)[Message Queue Client],  ← GENERIC CATEGORY

table.cell(...)[Dispatcher \ UseCase],
table.cell(...)[Transform project events into crawl tasks and dispatch to worker queues],
table.cell(...)[Project lifecycle events],
table.cell(...)[Worker task payloads],
table.cell(...)[Business Logic Layer],

table.cell(...)[State \ UseCase],
table.cell(...)[Manage distributed project state with task and item tracking],
table.cell(...)[Project identifier, state updates],
table.cell(...)[State persistence operations],
table.cell(...)[Cache Client (Redis)],  ← TECHNOLOGY TYPE + IMPL CHOICE
```

---

### Example 2: Analytics Service - Performance Characteristics

**BEFORE (Current):**

```typst
table.cell(...)[NLP Pipeline Latency (p95)],
table.cell(...)[~650ms],  ← MEASURED VALUE
table.cell(...)[< 700ms],
table.cell(...)[PhoBERT inference time, AC-3],

table.cell(...)[Throughput (Items/min/worker)],
table.cell(...)[~70 items/min],  ← MEASURED VALUE
table.cell(...)[~70 items/min],
table.cell(...)[AC-2 target met],

table.cell(...)[Memory Usage],
table.cell(...)[~2.8GB],  ← MEASURED VALUE
table.cell(...)[< 4GB],
table.cell(...)[PhoBERT model + batch processing],
```

**AFTER (Option A - Simplified):**

```typst
table.cell(...)[NLP Pipeline Latency (p95)],
table.cell(...)[< 700ms],
table.cell(...)[NFR-P2: NLP Processing Performance],

table.cell(...)[Throughput (Items/min/worker)],
table.cell(...)[≥ 70 items/min],
table.cell(...)[NFR-P3: Analytics Throughput],

table.cell(...)[Memory Usage per Worker],
table.cell(...)[< 4GB],
table.cell(...)[NFR-R2: Resource Constraints],
```

**Footnote:**
"Performance targets are derived from NFRs in Section 4.3. Implementation benchmark results are documented in Chapter 7: Implementation Details."

---

### Example 3: Dependencies Section

**BEFORE (Current - Collector Service):**

```typst
External Dependencies:

- RabbitMQ: Event ingestion với project.created, task publishing đến platform queues,
  result consumption từ results.inbound.data.  ← SPECIFIC ROUTING KEYS
- Redis: Distributed state management (key: `smap:proj:{projectID}`, TTL: 7 days).  ← KEY PATTERN + TTL
- Project Service: Progress webhook callbacks (HTTP POST `/projects/{id}/progress`).  ← ENDPOINT URL
- Scrapper Services: Workers consume tasks từ platform queues và publish results.
```

**AFTER (Option A - Simplified):**

```typst
External Dependencies:

- Message Queue (RabbitMQ):
  - Consumes project lifecycle events
  - Publishes worker tasks to platform-specific queues
  - Receives processing results from workers

- Distributed Cache (Redis):
  - Project state persistence with TTL-based expiration
  - Supports concurrent read/write for progress tracking

- Project Service:
  - Receives progress notifications via HTTP webhooks
  - Provides project configuration data

- Platform Workers (Scrapper Services):
  - Consume crawling tasks from queues
  - Publish collected data back to pipeline
```

---

## Recommended Action Plan

### Phase 1: Quick Win (Option A) - 4-6 hours

**Cho tất cả 7 services (5.3.1 - 5.3.7):**

1. **Component Catalog:**
   - Replace Technology column với Technology Category
   - Remove version numbers
   - Use generic terms (Message Queue Client, Cache Client, SQL ORM, etc.)

2. **Performance Characteristics:**
   - Remove "Value" column
   - Keep only "Target" column với references to NFRs
   - Add footnote về implementation benchmarks

3. **Dependencies:**
   - Abstract away routing keys, Redis patterns, endpoint URLs
   - Focus on architectural relationships

4. **Key Decisions:**
   - Keep only architectural patterns
   - Remove library-specific justifications

**Result:** Section 5.3 becomes pure C4 Level 3 design, không phụ thuộc implementation

---

### Phase 2: Comprehensive (Option B) - 8-12 hours

**If user wants full documentation:**

1. **Revise Section 5.3** theo Option A (4-6 hours)

2. **Create Chapter 7: Implementation Details** (4-6 hours)
   - 7.1 Technology Stack Justification (library choices với benchmarks)
   - 7.2 Performance Benchmarks (measured values từ production)
   - 7.3 Configuration Details (RabbitMQ routing, Redis keys, endpoints)
   - 7.4 Implementation Patterns (ONNX optimization, skip logic, etc.)

**Result:**
- Chapter 5 = Pure design (reviewable without code)
- Chapter 7 = Full technical depth (for implementation team)

---

## Recommendation

**For immediate fix:** Choose **Option A** (Simplify Section 5.3)
- Faster (4-6 hours)
- Addresses user's concern directly
- Makes Section 5.3 independent of implementation

**For comprehensive documentation:** Choose **Option B** (New Implementation Chapter)
- Better structure (design vs implementation separation)
- Preserves all technical details
- More maintainable long-term

**User should decide based on:**
1. Report deadline (Option A if tight deadline)
2. Review audience (Option A if academic reviewers, Option B if also for dev team)
3. Documentation goals (Option A if design-only, Option B if full technical doc)
