#import "../counters.typ": image_counter, table_counter

=== 5.3.2 Analytics Service

Analytics Service là service phức tạp nhất trong hệ thống SMAP về mặt AI/ML, chịu trách nhiệm xử lý NLP pipeline để phân tích sentiment, intent, keywords, và impact của social media content. Service này consume events từ Crawler Services, fetch raw data từ object storage, chạy qua pipeline 5 bước, và persist kết quả vào database.

Vai trò của Analytics Service trong kiến trúc tổng thể:

- NLP Pipeline Orchestrator: Điều phối 5 bước xử lý: Preprocessing → Intent → Keyword → Sentiment → Impact.
- Batch Processor: Xử lý batches từ object storage để tối ưu throughput.
- Event Consumer: Consume data collection events và publish analysis completion events.
- Result Persister: Lưu kết quả phân tích vào relational database với schema linh hoạt.

Service này đáp ứng FR-2 (Analyzing phase) và liên quan trực tiếp đến UC-03 (Analytics Pipeline execution).

==== 5.3.2.1 Component Diagram - C4 Level 3

Analytics Service được tổ chức theo Clean Architecture với 5 layers chính:

#context (
  align(center)[
    #image("../images/component/analytic-component-diagram.png", width: 94%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Biểu đồ thành phần của Analytics Service_]
)
#image_counter.step()

==== 5.3.2.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.30fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[EventConsumer],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Consume data collection events, download batches, process items],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Queue event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Trigger orchestrator],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AMQP Consumer (Python)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics \ Orchestrator],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Coordinate 5-step NLP pipeline, apply skip logic, aggregate results],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Atomic JSON post],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostAnalytics payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python async],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Text \ Preprocessor],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Merge content sources, normalize Vietnamese text, detect spam],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Raw text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PreprocessingResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Text Processing],

    table.cell(align: center + horizon, inset: (y: 0.8em))[IntentClassifier],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Classify intent (7 categories), gatekeeper cho skip logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[IntentResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pattern-based],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Keyword \ Extractor],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Extract keywords với aspect mapping (hybrid approach)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[KeywordResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NLP Framework],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Sentiment \ Analyzer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Overall + aspect-based sentiment với context windowing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean text, keywords],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SentimentResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transformer Model],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Impact \ Calculator],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Calculate ImpactScore (0-100), RiskLevel, engagement scores],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Interaction, sentiment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ImpactResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Python logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Persist PostAnalytics vào database],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostAnalytics payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database INSERT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM (Python)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Storage \ Adapter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Download batch files từ object storage, decompress, parse],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Object key],
    table.cell(align: center + horizon, inset: (y: 0.8em))[List of items],
    table.cell(align: center + horizon, inset: (y: 0.8em))[S3 Client],
  )
]

==== 5.3.2.3 Data Flow

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

==== 5.3.2.4 Design Patterns áp dụng

Analytics Service áp dụng các design patterns sau:

- Pipeline Pattern: AnalyticsOrchestrator điều phối 5 steps tuần tự: Preprocessing → Intent → Keyword → Sentiment → Impact. Mỗi step là một module độc lập với interface rõ ràng. Dễ test từng step độc lập, dễ thay đổi implementation của một step mà không ảnh hưởng steps khác.

- Strategy Pattern: KeywordExtractor sử dụng hybrid strategy kết hợp dictionary-based và statistical methods. Flexibility trong keyword extraction, có thể thêm strategies mới mà không thay đổi orchestrator.

- Skip Logic Pattern: IntentClassifier và TextPreprocessor kết hợp để skip spam/seeding/noise posts. Early return bypass expensive AI steps. Tiết kiệm compute resources và improve throughput.

- Port and Adapter Pattern: Interfaces định nghĩa contracts, implementations trong infrastructure layer. Orchestrator depends on repository interface, không phụ thuộc database cụ thể.

- Batch Processing Pattern: EventConsumer download batches từ object storage và process parallel. Tối ưu throughput, giảm overhead của multiple storage calls.

==== 5.3.2.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NLP Pipeline Latency (p95)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 700ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Throughput (per worker)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 70 items/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Batch Processing Time],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10s/batch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Memory Usage],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 4GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-R1],
  )
]

==== 5.3.2.6 Key Decisions

- Model Optimization: Sử dụng optimized model runtime thay vì native framework. Inference nhanh hơn trên CPU, memory footprint nhỏ hơn.

- Skip Logic: Skip expensive AI steps cho spam/seeding/noise posts. Tiết kiệm thời gian xử lý, improve throughput.

- Batch Processing: Process batches từ object storage thay vì từng item riêng lẻ. Giảm overhead, tối ưu network bandwidth.

- Hybrid Keyword Extraction: Kết hợp dictionary-based và statistical extraction. Dictionary cho domain-specific keywords, statistical cho general keywords.

- Context Windowing: Sử dụng context windowing technique cho aspect-based sentiment analysis. Model cần context xung quanh keyword để predict sentiment chính xác.

==== 5.3.2.7 Dependencies

Internal Dependencies:

- TextPreprocessor: Text normalization và spam detection.
- IntentClassifier: Skip logic và intent classification.
- KeywordExtractor: Keyword extraction và aspect mapping.
- SentimentAnalyzer: Sentiment analysis (overall + aspect-based).
- ImpactCalculator: Impact score và risk level calculation.
- AnalyticsRepository: Result persistence.

External Dependencies:

- Message Queue (RabbitMQ): Event consumption.
- Object Storage (MinIO): Raw data storage (batches, compressed).
- Relational Database (PostgreSQL): Result persistence.
- AI Model: Pre-trained Vietnamese sentiment model.
