// Đây là ví dụ simplified version của Section 5.3.2 Analytics Service
// So sánh với version hiện tại ở report/chapter_5/section_5_3.typ (lines 228-446)

=== 5.3.2 Analytics Service - Component Diagram

Analytics Service là service chịu trách nhiệm xử lý NLP pipeline để phân tích sentiment, intent, keywords, và impact của social media content. Service này consume data collection events, fetch raw data từ object storage, chạy qua pipeline 5 bước, và persist kết quả vào database.

Vai trò của Analytics Service trong kiến trúc tổng thể:

- NLP Pipeline Orchestrator: Điều phối 5 bước xử lý tuần tự với skip logic optimization.
- Batch Processor: Xử lý batches từ object storage để tối ưu throughput.
- Event Consumer: Consume data collection events và publish analysis completion events.
- Result Persister: Lưu kết quả phân tích vào relational database với flexible schema.

Service này đáp ứng FR-2 (Analyzing phase) và liên quan trực tiếp đến UC-03 (Analytics Pipeline execution).

==== Component Diagram - C4 Level 3

Analytics Service được tổ chức theo Clean Architecture với 5 layers chính:

#align(center)[
  #image("../images/component/analytic-component-diagram.png", width: 94%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ thành phần của Analytics Service_])
  #image_counter.step()
]

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.30fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    // THAY ĐỔI: "Technology" → "Technology Category"
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology Category*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[EventConsumer],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Consume data collection events, download batches from object storage, process items],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Data collection event payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Trigger analytics orchestration],
    // BEFORE: pika (AMQP)
    // AFTER: Generic category
    table.cell(align: center + horizon, inset: (y: 0.8em))[AMQP Consumer \ (Python)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics \ Orchestrator],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Coordinate 5-step NLP pipeline, apply optimization logic, aggregate results],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Social media post data],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Structured analytics payload],
    // BEFORE: Python async
    // AFTER: More descriptive
    table.cell(align: center + horizon, inset: (y: 0.8em))[Async \ Orchestration \ Layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Text \ Preprocessor],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Merge content sources, normalize text, detect spam and low-quality content],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Raw text (caption, transcription, comments)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Preprocessing result (clean text, quality metrics)],
    // BEFORE: unicodedata, re
    // AFTER: Generic category
    table.cell(align: center + horizon, inset: (y: 0.8em))[Text Processing \ (Built-in)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[IntentClassifier],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Classify intent into predefined categories, gatekeeper for skip logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Intent result (category, confidence)],
    // BEFORE: Pattern-based (YAML config)
    // AFTER: Generic pattern
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pattern-based \ Classifier],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Keyword \ Extractor],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Extract keywords with aspect mapping using hybrid strategy],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Keyword result (keywords, aspect mappings)],
    // BEFORE: SpaCy, YAKE
    // AFTER: Generic approach
    table.cell(align: center + horizon, inset: (y: 0.8em))[NLP Framework \ (Statistical)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Sentiment \ Analyzer],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Overall and aspect-based sentiment analysis using transformer model with context windowing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text, keywords],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Sentiment result (overall, aspects, probabilities)],
    // BEFORE: PhoBERT ONNX, PyTorch
    // AFTER: Generic model type
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transformer \ Model (ONNX)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Impact \ Calculator],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Calculate impact score, risk level, engagement and reach metrics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Interaction, author, sentiment, platform metadata],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Impact result (score, risk level, breakdown)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business Logic \ Layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Persist analytics results to relational database with flexible schema],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database write operation],
    // BEFORE: SQLAlchemy
    // AFTER: Generic ORM
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM \ (Python)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Object \ Storage \ Adapter],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Download batch files from object storage, decompress and deserialize data],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Object storage key],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Deserialized data items (batch)],
    // BEFORE: boto3 (S3 client)
    // AFTER: Generic client
    table.cell(align: center + horizon, inset: (y: 0.8em))[S3-compatible \ Client],
  )
]

==== Data Flow

Luồng xử lý chính của Analytics Service được chia thành 2 flows: Event Consumption và NLP Pipeline Execution.

===== a. Event Consumption Flow

Luồng này được kích hoạt khi Crawler Services publish data collection events:

#align(center)[
  #image("../images/data-flow/analytics_ingestion.png", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng xử lý Event → Batch Ingestion trong Analytics Service_])
  #image_counter.step()
]

===== b. NLP Pipeline Execution Flow

#align(center)[
  #image("../images/data-flow/analytics-pipeline.png", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng NLP Pipeline cho từng post trong Analytics Service_])
  #image_counter.step()
]

==== Design Patterns Applied

Analytics Service áp dụng các design patterns sau:

- Pipeline Pattern: AnalyticsOrchestrator điều phối 5 steps tuần tự: Preprocessing → Intent → Keyword → Sentiment → Impact. Mỗi step là một module độc lập với interface rõ ràng. Dễ test từng step độc lập, dễ thay đổi implementation của một step mà không ảnh hưởng steps khác.

- Strategy Pattern: KeywordExtractor sử dụng hybrid strategy kết hợp Dictionary-based và Statistical extraction. Flexibility trong keyword extraction, có thể thêm strategies mới mà không thay đổi orchestrator.

- Skip Logic Pattern: IntentClassifier kết hợp với TextPreprocessor để skip spam và low-quality posts. Early return nếu content không đạt quality threshold, bypass expensive AI steps. Tiết kiệm compute resources và improve throughput.

- Port and Adapter Pattern: Interfaces định nghĩa contracts, implementations trong infrastructure layer. AnalyticsOrchestrator depends on AnalyticsRepositoryProtocol interface, không phụ thuộc ORM implementation cụ thể.

- Batch Processing Pattern: EventConsumer download batches từ object storage và process parallel. Tối ưu throughput, giảm overhead của multiple storage calls.

==== Performance Characteristics

// THAY ĐỔI LỚN: Bỏ cột "Value" (measured), chỉ giữ "Target" từ NFRs
#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    // BỎ CỘT "Value" - không có measured values
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NLP Pipeline Latency (p95)],
    // BEFORE: ~650ms | < 700ms | PhoBERT inference time, AC-3
    // AFTER: Only target
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 700ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P2: NLP Processing Performance],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Throughput (Items/min/worker)],
    // BEFORE: ~70 items/min | ~70 items/min | AC-2 target met
    // AFTER: Only target
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 70 items/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P3: Analytics Throughput],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Batch Processing Time],
    // BEFORE: ~3-8s/batch | < 10s/batch | 50 items/batch, includes download
    // AFTER: Only target
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10s/batch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P4: Batch Processing Efficiency],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Memory Usage per Worker],
    // BEFORE: ~2.8GB | < 4GB | PhoBERT model + batch processing
    // AFTER: Only target
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 4GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-R2: Resource Constraints],
  )
]

// THÊM FOOTNOTE
#par(justify: false)[
  _Lưu ý: Performance targets trên được derive từ Non-Functional Requirements trong Chapter 4. Implementation benchmark results với measured values được documented trong Chapter 7: Implementation Details._
]

==== Key Decisions

// THAY ĐỔI: Chỉ giữ architectural decisions, bỏ implementation choices

- Pipeline Architecture: Chia NLP processing thành 5 independent steps cho phép parallel development, independent testing, và easy replacement của individual components. Mỗi step có clear input/output contract.

- Batch Processing Strategy: Process data in batches thay vì individual items để optimize network bandwidth và reduce storage access overhead. Batch size configurable dựa trên memory constraints và throughput requirements.

- Skip Logic Optimization: Implement early return mechanism cho low-quality content để avoid expensive AI processing. Quality assessment dựa trên intent classification và preprocessing metrics.

- Hybrid Extraction Strategy: Kết hợp Dictionary-based lookup cho domain-specific terms với Statistical extraction cho general keywords. Two-tier approach provides both precision và recall.

- Aspect-Based Sentiment: Extend overall sentiment analysis với aspect-level granularity using context windowing technique. Provides richer insights cho brand monitoring.

// BỎ CÁC IMPLEMENTATION CHOICES:
// - ONNX Optimization (too specific to library choice)
// - Specific library names (SpaCy, YAKE, PhoBERT)
// - Context windowing implementation details

==== Dependencies

Internal Dependencies:

- TextPreprocessor: Cần thiết cho text normalization và quality assessment.
- IntentClassifier: Cần thiết cho content classification và skip logic.
- KeywordExtractor: Cần thiết cho keyword extraction và aspect mapping.
- SentimentAnalyzer: Cần thiết cho sentiment analysis (overall và aspect-based).
- ImpactCalculator: Cần thiết cho impact score và risk level calculation.
- AnalyticsRepository: Cần thiết cho result persistence.

External Dependencies:

// THAY ĐỔI: Abstract away specific config details

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

// BỎ SPECIFIC DETAILS:
// - RabbitMQ event names (`data.collected`)
// - MinIO batch sizes (20-50 items), compression (Zstd), format (Protobuf)
// - PostgreSQL table names (`post_analytics`, `post_comments`), JSONB columns
// - PhoBERT model size (~500MB), download location, ONNX quantization

==== Summary

Analytics Service là service phức tạp nhất về AI/ML trong hệ thống SMAP. Service được tổ chức theo Clean Architecture với 5 layers và 5 NLP modules: Preprocessing, Intent, Keyword, Sentiment, Impact. Các design patterns chính bao gồm Pipeline Pattern, Strategy Pattern, Skip Logic Pattern và Port and Adapter Pattern. Service đáp ứng FR-2 về Analyzing phase và UC-03 về Analytics Pipeline.

// COMPARISON SUMMARY:
// =====================
// REMOVED:
// - Specific library names: pika, SpaCy, YAKE, PhoBERT, SQLAlchemy, boto3
// - Measured performance values: ~650ms, ~70 items/min, ~2.8GB, ~15-20%
// - Implementation choices: ONNX vs PyTorch, specific batch sizes, compression formats
// - Configuration details: Event names, table names, model sizes, key patterns
// - Function references: No specific method/function names
//
// KEPT:
// - Component responsibilities (what they do)
// - Architectural patterns (Pipeline, Strategy, Skip Logic)
// - Performance targets (from NFRs)
// - High-level technology choices (Transformer Model, SQL ORM)
// - Design rationale (why patterns chosen)
//
// RESULT:
// - Pure C4 Level 3 design
// - Independent of implementation details
// - Reviewable without running code
// - Still provides complete architectural picture
