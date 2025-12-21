# Section 5.3 - Đề xuất Sửa đổi

## Tóm tắt Vấn đề

Section 5.3 hiện tại có **~97 implementation-specific details** làm cho nội dung:

1. ✗ Yêu cầu có implementation thực tế mới viết được (measured metrics, specific libraries)
2. ✗ Dễ bị ảnh hưởng khi có thay đổi (library upgrades, refactoring, performance tuning)
3. ✗ Dễ bị chất vấn trong report review (tại sao dùng library này? metrics này đúng không?)

**Chi tiết phân tích:** Xem file `SECTION_5_3_DETAIL_ANALYSIS.md`

**Ví dụ cụ thể:** Xem file `SECTION_5_3_2_SIMPLIFIED_EXAMPLE.typ` (Analytics Service simplified)

---

## Hai Lựa chọn

### Option A: Simplify Section 5.3 (Recommended - Quick Fix)

**Thay đổi:**

1. **Component Catalog - Technology Column:**
   - ❌ BEFORE: `amqp091-go`, `go-redis/v9`, `SQLAlchemy`, `SpaCy`, `PhoBERT ONNX`
   - ✅ AFTER: `Message Queue Client`, `Cache Client (Redis)`, `SQL ORM`, `NLP Framework`, `Transformer Model (ONNX)`

2. **Performance Characteristics:**
   - ❌ BEFORE: Table có cột "Value" với measured metrics (~200ms, ~650ms, ~2.8GB)
   - ✅ AFTER: Table chỉ có cột "Target" từ NFRs + footnote reference đến implementation benchmarks

3. **Dependencies - External:**
   - ❌ BEFORE: `RabbitMQ: Event ingestion với project.created, task publishing đến platform queues, result consumption từ results.inbound.data`
   - ✅ AFTER: `Message Queue (RabbitMQ): Event consumption and task publishing with topic-based routing`

4. **Key Decisions:**
   - ✅ KEEP: Architectural patterns (Pipeline, Strategy, Repository)
   - ❌ REMOVE: Library-specific choices (ONNX vs PyTorch, SpaCy+YAKE integration details)

5. **Data Flow:**
   - ❌ BEFORE: Function names (`HandleProjectCreatedEvent()`, `MapPayload()`, `HMSet/HGetAll`)
   - ✅ AFTER: Action descriptions ("Handle project event", "Select mapping strategy", "Redis hash operations")

**Effort:** 4-6 hours cho tất cả 7 services

**Kết quả:**
- ✅ Section 5.3 trở thành pure design (C4 Level 3)
- ✅ Không phụ thuộc vào implementation changes
- ✅ Ít bị chất vấn trong report review
- ✅ Vẫn giữ đầy đủ architectural information
- ❌ Mất detailed technical information (có thể add footnote hoặc appendix)

---

### Option B: Create New Implementation Chapter (Comprehensive)

**Structure:**

```
Chapter 5: Thiết kế Hệ thống (DESIGN ONLY - SIMPLIFIED)
├── 5.1 Design Principles
├── 5.2 Architecture Overview (C4 Level 2)
├── 5.3 Service Components (C4 Level 3 - PURE DESIGN)
│   └── No implementation details
├── 5.4 Data Model Design
├── 5.5 Sequence Diagrams
├── 5.6 Communication Patterns
└── 5.7 Traceability & Validation

Chapter 7: Chi tiết Hiện thực (NEW - IMPLEMENTATION DETAILS)
├── 7.1 Technology Stack Justification
│   ├── Language Choices (Go vs Python benchmarks)
│   ├── Framework Selection (Echo vs Gin, FastAPI vs Flask)
│   └── Library Decisions (amqp091-go, SQLAlchemy, PhoBERT with comparisons)
├── 7.2 Performance Benchmarks
│   ├── Measured values từ production (~200ms, ~650ms, etc.)
│   └── Benchmark methodology and test environments
├── 7.3 Configuration Details
│   ├── RabbitMQ setup (exchanges, routing keys, DLQ)
│   ├── Redis configuration (key patterns, TTL policies)
│   └── Database schemas (tables, indexes, JSONB columns)
└── 7.4 Implementation Patterns
    ├── ONNX Model Optimization (PhoBERT quantization)
    ├── Skip Logic Implementation (IntentClassifier details)
    └── Context Windowing for ABSA
```

**Effort:** 8-12 hours (4-6h revise Section 5.3 + 4-6h create Chapter 7)

**Kết quả:**
- ✅ Clear separation: Design (Chapter 5) vs Implementation (Chapter 7)
- ✅ Section 5.3 reviewable without implementation knowledge
- ✅ Chapter 7 provides full technical depth for implementation team
- ✅ Easy to maintain: design changes → Chapter 5, implementation changes → Chapter 7
- ❌ More work upfront (8-12 hours)
- ❌ Longer report overall

---

## So sánh Chi tiết

### Analytics Service - Component Catalog

| Aspect | BEFORE (Current) | AFTER (Option A) |
|--------|------------------|------------------|
| EventConsumer Technology | `pika (AMQP)` | `AMQP Consumer (Python)` |
| Text Preprocessor Technology | `unicodedata, re` | `Text Processing (Built-in)` |
| Keyword Extractor Technology | `SpaCy, YAKE` | `NLP Framework (Statistical)` |
| Sentiment Analyzer Technology | `PhoBERT ONNX, PyTorch` | `Transformer Model (ONNX)` |
| Analytics Repository Technology | `SQLAlchemy` | `SQL ORM (Python)` |
| MinioAdapter Technology | `boto3 (S3 client)` | `S3-compatible Client` |

**Benefit:** Technology choices không bị "lock-in" vào specific libraries, easier to review

---

### Analytics Service - Performance Characteristics

| Metric | BEFORE (Current) | AFTER (Option A) |
|--------|------------------|------------------|
| NLP Pipeline Latency (p95) | Value: ~650ms<br>Target: < 700ms<br>Evidence: PhoBERT inference, AC-3 | Target: < 700ms<br>NFR: NFR-P2 |
| Throughput | Value: ~70 items/min<br>Target: ~70 items/min<br>Evidence: AC-2 target met | Target: ≥ 70 items/min<br>NFR: NFR-P3 |
| Memory Usage | Value: ~2.8GB<br>Target: < 4GB<br>Evidence: PhoBERT + batch | Target: < 4GB<br>NFR: NFR-R2 |

**+ Footnote:** _"Performance targets derived from NFRs in Chapter 4. Implementation benchmark results documented in Chapter 7 (or Appendix B)."_

**Benefit:** Không claim measured values khi chưa có production deployment

---

### Analytics Service - Dependencies

**BEFORE (Current - Too Detailed):**

```
External Dependencies:

- RabbitMQ: Event ingestion (`data.collected` events).
- MinIO: Raw data storage (batches 20-50 items, Zstd compressed, Protobuf format).
- PostgreSQL: Result persistence (`post_analytics` table với JSONB columns, `post_comments` table).
- PhoBERT Model: ONNX quantized model (~500MB, downloaded từ MinIO, cached locally).
```

**Issues:**
- ❌ Event names (`data.collected`)
- ❌ Batch sizes (20-50 items)
- ❌ Compression format (Zstd)
- ❌ Serialization (Protobuf)
- ❌ Table names (`post_analytics`, `post_comments`)
- ❌ Column types (JSONB)
- ❌ Model size (~500MB)
- ❌ Download location (MinIO)

**AFTER (Option A - Abstract):**

```
External Dependencies:

- Message Queue (RabbitMQ):
  - Consumes data collection events
  - Event-driven processing trigger

- Object Storage (MinIO):
  - Batch data retrieval with compression
  - Binary serialization format support

- Relational Database (PostgreSQL):
  - Analytics result persistence
  - Flexible schema with JSON support

- NLP Model (Transformer-based):
  - Vietnamese sentiment analysis capability
  - Optimized for CPU inference
  - Model artifacts cached locally
```

**Benefit:** Focus on architectural relationships, not configuration details

---

### Analytics Service - Key Decisions

**BEFORE (Current - Mix of Architectural + Implementation):**

1. ❌ **ONNX Optimization**: "Sử dụng PhoBERT ONNX quantized model thay vì PyTorch native model. ONNX runtime nhanh hơn trên CPU, memory footprint nhỏ hơn."
   - **Issue:** Library-specific choice (ONNX vs PyTorch)
   - **Requires:** Benchmarking both options

2. ✅ **Skip Logic**: "Skip expensive AI steps cho spam/seeding/noise posts. Tiết kiệm thời gian xử lý, improve throughput."
   - **OK:** Architectural optimization pattern

3. ✅ **Batch Processing**: "Process batches từ MinIO thay vì process từng item riêng lẻ. Giảm overhead, tối ưu network bandwidth."
   - **OK:** Architectural choice (batch vs stream)

4. ❌ **Hybrid Keyword Extraction**: "Kết hợp Dictionary-based lookup và SpaCy-YAKE statistical extraction."
   - **Issue:** Library names (SpaCy, YAKE)

5. ❌ **Context Windowing cho ABSA**: "Sử dụng context windowing technique. PhoBERT cần context xung quanh keyword để predict sentiment."
   - **Issue:** Very implementation-specific

**AFTER (Option A - Architectural Only):**

1. ✅ **Pipeline Architecture**: 5 independent steps cho parallel development, independent testing, easy component replacement.

2. ✅ **Batch Processing Strategy**: Process data in batches để optimize network bandwidth và reduce storage overhead.

3. ✅ **Skip Logic Optimization**: Early return mechanism cho low-quality content để avoid expensive AI processing.

4. ✅ **Hybrid Extraction Strategy**: Kết hợp Dictionary-based lookup cho domain-specific terms với Statistical extraction cho general keywords.

5. ✅ **Aspect-Based Sentiment**: Extend overall sentiment analysis với aspect-level granularity using context windowing. Provides richer insights.

**Implementation choices → Move to Chapter 7:**
- ONNX vs PyTorch comparison with benchmarks
- SpaCy + YAKE library integration details
- Context windowing implementation with code examples

---

## Implementation Plan

### Plan A: Quick Fix (4-6 hours)

**Day 1: Revise All Services (4-6 hours)**

1. **Hour 1-2: Component Catalogs (2 hours)**
   - Tất cả 7 services
   - Replace Technology column với Technology Category
   - Remove version numbers
   - Test: Read through each table, ensure no library versions visible

2. **Hour 3-4: Performance Characteristics (1.5 hours)**
   - Tất cả 7 services
   - Remove "Value" column
   - Keep only "Target" column with NFR references
   - Add footnote về implementation benchmarks
   - Test: Ensure no measured values visible

3. **Hour 5-6: Dependencies & Key Decisions (1.5 hours)**
   - Tất cả 7 services
   - Abstract Dependencies: Remove routing keys, Redis patterns, endpoints
   - Simplify Key Decisions: Keep only architectural patterns
   - Test: Search for specific config values (7 days, bcrypt cost 10, etc.)

**Deliverable:**
- Updated `section_5_3.typ` với simplified content
- Section 5.3 is now pure C4 Level 3 design

---

### Plan B: Comprehensive (8-12 hours)

**Day 1: Revise Section 5.3 (4-6 hours)**
- Same as Plan A

**Day 2-3: Create Chapter 7 (4-6 hours)**

1. **Hour 1-2: Chapter 7.1 - Technology Stack Justification (2 hours)**
   - Go vs Python comparison
   - Framework selections (Echo, FastAPI, Next.js)
   - Library decisions với alternatives considered
   - Consolidate all specific library names từ Section 5.3

2. **Hour 3-4: Chapter 7.2 - Performance Benchmarks (1.5 hours)**
   - Consolidate all measured values từ Section 5.3
   - Add benchmark methodology
   - Test environments and configurations
   - Performance optimization results

3. **Hour 5-6: Chapter 7.3-7.4 - Config & Patterns (1.5 hours)**
   - RabbitMQ: exchanges, routing keys, DLQ config
   - Redis: key patterns, TTL policies
   - PostgreSQL: table schemas, indexes
   - Implementation patterns: ONNX optimization, Skip Logic code, Context Windowing

**Deliverable:**
- Updated `section_5_3.typ` (pure design)
- New `chapter_7/index.typ` (implementation details)
- Clear separation of concerns

---

## Recommendation

### Cho user có deadline gấp:

**→ Choose Option A (4-6 hours)**

Lý do:
- Nhanh, giải quyết được vấn đề ngay
- Section 5.3 trở thành pure design, không bị chất vấn
- Có thể add Chapter 7 sau nếu cần

### Cho user muốn documentation hoàn chỉnh:

**→ Choose Option B (8-12 hours)**

Lý do:
- Structure tốt hơn (design vs implementation separated)
- Giữ được all technical details cho dev team
- Maintainable hơn long-term
- Professional documentation structure

---

## Decision Criteria

| Criterion | Choose A if... | Choose B if... |
|-----------|---------------|---------------|
| **Deadline** | < 1 week | ≥ 2 weeks |
| **Audience** | Academic reviewers only | Academic + Dev team |
| **Report Type** | Design document | Full technical specification |
| **Implementation Status** | Not yet implemented | Already implemented (có measured values thật) |
| **Maintenance** | One-time report | Living documentation |
| **Scope** | Graduation thesis | Product documentation |

---

## Next Steps

**User cần quyết định:**

1. **Option A hay Option B?**
   - Based on deadline, audience, và documentation goals

2. **Nếu chọn Option A:**
   - Tôi sẽ revise tất cả 7 services trong Section 5.3 (4-6 hours)
   - Apply simplification như example trong `SECTION_5_3_2_SIMPLIFIED_EXAMPLE.typ`

3. **Nếu chọn Option B:**
   - Tôi sẽ revise Section 5.3 (4-6 hours)
   - Tạo Chapter 7: Implementation Details (4-6 hours)
   - Total: 8-12 hours

**Tôi recommend Option A** vì:
- Faster (4-6h vs 8-12h)
- Solves immediate problem (Section 5.3 too detailed)
- Can add Chapter 7 later if needed
- Good enough for graduation thesis review

**User confirm để tôi proceed?**
