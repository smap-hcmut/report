// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.3 Thiết kế chi tiết các dịch vụ

Mục 5.2 đã trình bày kiến trúc tổng thể của hệ thống SMAP ở cấp độ Container hay C4 Level 2, mô tả các services như các hộp đen với trách nhiệm và công nghệ của chúng. Mục này đi sâu vào cấp độ Component hay C4 Level 3, mở hộp từng service để làm rõ cấu trúc nội bộ, các components bên trong, cách chúng tương tác và các design patterns được áp dụng.

Mục đích của mục này là:

- Làm rõ cấu trúc nội bộ của từng service: Các components, layers, và cách tổ chức code theo Clean Architecture.

- Mô tả trách nhiệm của từng component: Input, output, và technology category.

- Giải thích các design patterns được áp dụng: Lý do chọn pattern và lợi ích mang lại.

- Cung cấp traceability đến requirements: Liên kết với NFRs và Acceptance Criteria ở Chapter 4.


Mục này được tổ chức theo thứ tự ưu tiên, bắt đầu với các services phức tạp và quan trọng nhất là Collector Service và Analytics Service, sau đó đến các services hỗ trợ gồm Project, Identity, WebSocket và Web UI.

=== 5.3.1 Collector Service

Collector Service là service trung tâm trong hệ thống SMAP data collection, đóng vai trò Master node trong mô hình Master-Worker pattern. Service này nhận các crawl requests từ Project Service qua message queue, validate và phân phối các task chi tiết đến các platform-specific workers.

Vai trò của Collector Service trong kiến trúc tổng thể:

- Orchestrator: Điều phối quy trình crawl dữ liệu từ nhiều platforms đồng thời.
- Task Dispatcher: Phân phối jobs đến các workers dựa trên platform và task type.
- State Manager: Quản lý trạng thái thực thi project trong distributed cache với Hybrid State tracking.
- Progress Tracker: Theo dõi và cập nhật tiến độ thông qua webhook callbacks.

Service này đáp ứng FR-2 về Thực thi và Giám sát Project và liên quan trực tiếp đến UC-02 về Dry-run và UC-03 về Execution.

==== 5.3.1.1 Component Diagram - C4 Level 3

Collector Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/collector-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Component Diagram - Collector Service_])
  #image_counter.step()
]

==== 5.3.1.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Collector Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectEvent \ Consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Consume project events từ message queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Queue event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Trigger event handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AMQP Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Dispatcher \ UseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Transform project events thành crawl tasks, dispatch đến platform queues],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectCreated \ Event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CollectorTask[] published],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[State \ UseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Quản lý trạng thái project trong distributed cache với Hybrid State],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, state updates],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache operations],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Webhook \ UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gửi progress callbacks đến Project Service qua HTTP webhook],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, UserID, State],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP POST request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Results \ UseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Xử lý kết quả từ crawler workers, route đến Analytics Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CrawlerResult],
    table.cell(align: center + horizon, inset: (y: 0.8em))[State updates, event routing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[State \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Data access layer cho project state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache commands],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],
  )
]

==== 5.3.1.3 Data Flow

Luồng xử lý chính của Collector Service được chia thành 3 flows: Project Event Processing, Task Dispatching, và Result Handling.

===== a. Project Event Processing Flow

Luồng này được kích hoạt khi Project Service publish project event:

#align(center)[
  #image("../images/data-flow/project_created_dispatching.png", width: 95%)
  #context (
    align(center)[_Hình #image_counter.display(): Luồng xử lý ProjectEvent → Dispatching trong Collector Service_]
  )
  #image_counter.step()
]

===== b. Task Dispatching Flow

Luồng này mô tả chi tiết cách một CrawlRequest được dispatch đến workers:

#align(center)[
  #image("../images/data-flow/dispatcher_usecase_dispatch_logic.png", width: 95%)
  #context (
    align(center)[_Hình #image_counter.display(): Luồng logic Dispatcher trong Collector Service_]
  )
  #image_counter.step()
]

===== c. Result Handling Flow

Luồng này xử lý kết quả từ crawler workers:

#align(center)[
  #image("../images/data-flow/crawler_results_processing.png", width: 95%)
  #context (
    align(center)[_Hình #image_counter.display(): Luồng xử lý kết quả từ crawler workers trong Collector Service_]
  )
  #image_counter.step()
]

==== 5.3.1.4 Design Patterns áp dụng

Collector Service áp dụng các design patterns sau:

- Master-Worker Pattern: DispatcherUseCase đóng vai trò Master, Scrapper Services đóng vai trò Workers. Master nhận high-level requests, chia nhỏ thành tasks, và phân phối đến workers qua message queues. Cho phép scale workers độc lập, fault tolerance khi worker crash không ảnh hưởng master.

- Event-Driven Architecture: Services giao tiếp qua message queue events thay vì direct HTTP calls. Decoupling giữa services, async processing, và resilience.

- Strategy Pattern: Payload mapping function chọn strategy dựa trên Platform và TaskType. Dễ mở rộng cho platforms mới.

- Repository Pattern: StateRepository abstract cache operations qua interface, business logic không phụ thuộc vào cache implementation cụ thể. Dễ test và có thể thay đổi storage backend.

- Clean Architecture: 4 layers Delivery → UseCase → Domain → Infrastructure với dependency inversion. Testability cao, maintainability tốt.

==== 5.3.1.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Collector Service_])
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Event Processing Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Task Dispatch Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 1,000 tasks/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache State Update Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Concurrent Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 20 projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
  )
]

==== 5.3.1.6 Key Decisions

- Config-Driven Limits: Sử dụng environment variables để configure crawl limits thay vì hardcode values. Cho phép điều chỉnh limits mà không cần rebuild service.

- Hybrid State Tracking: Track cả task-level và item-level trong cùng cache entry. Task-level cho completion check, item-level cho progress display chi tiết hơn.

- Two-Phase Progress: Tách progress thành 2 phases: Crawl phase và Analyze phase. Phản ánh đúng workflow thực tế.

- Event Transformation: Transform project event thành multiple CrawlRequests. Cho phép parallel processing và dễ track progress cho từng keyword.

==== 5.3.1.7 Dependencies

Internal Dependencies:

- StateUseCase: Quản lý project state trong distributed cache.
- WebhookUseCase: Gửi progress callbacks đến Project Service.
- DispatcherProducer: Publish tasks đến platform queues.

External Dependencies:

- Message Queue (RabbitMQ): Event consumption và task publishing.
- Distributed Cache (Redis): Project state management với TTL.
- Project Service: Progress webhook callbacks.
- Scrapper Services: Workers consume tasks và publish results.



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



=== 5.3.3 Project Service

Project Service là service quản lý vòng đời của các dự án phân tích thương hiệu và đối thủ cạnh tranh trong hệ thống SMAP. Service này đóng vai trò Aggregator trong kiến trúc tổng thể, quản lý project metadata, orchestrate execution flow, và publish events để trigger các services khác.

Vai trò của Project Service trong kiến trúc tổng thể:

- Project Management: CRUD operations cho projects, competitors, và keywords.
- Execution Orchestrator: Khởi tạo và điều phối quá trình crawl dữ liệu cho UC-03.
- State Coordinator: Quản lý project state trong distributed cache (initialization, không update trực tiếp).
- Event Publisher: Publish project events để trigger Collector Service.
- Webhook Receiver: Nhận progress callbacks từ Collector Service và publish đến Pub/Sub.

Service này đáp ứng FR-1 về Cấu hình Project và FR-2 về Thực thi và Giám sát Project, liên quan trực tiếp đến UC-01 về Cấu hình Project và UC-03 về Execution.

==== 5.3.3.1 Component Diagram - C4 Level 3

Project Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/project-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ thành phần của Project Service_])
  #image_counter.step()
]

==== 5.3.3.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Project Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectHandler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request handlers cho project CRUD và execution],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP requests],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Framework (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectUseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Business logic cho project management và execution orchestration],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CreateInput, ExecuteInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectOutput, status],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[StateUseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý project state trong distributed cache],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, state updates],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectState],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Webhook \ UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transform progress callbacks → Pub/Sub messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress Callback],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub publish],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub Client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ \ Producer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Publish project events đến message queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectCreated Event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message published],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AMQP Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database data access layer cho projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[State \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache data access layer cho project state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache commands],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],
  )
]

==== 5.3.3.3 Data Flow

Luồng xử lý chính của Project Service được chia thành 3 flows: Project Creation, Project Execution, và Progress Callback Handling.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới theo UC-01:

#align(center)[
  #image("../images/data-flow/project_create.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Creation Flow - UC-01_])
  #image_counter.step()
]

===== b. Project Execution Flow

Luồng này được kích hoạt khi user execute project theo UC-03:

#align(center)[
  #image("../images/data-flow/execute_project.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Execution Flow - UC-03_])
  #image_counter.step()
]

===== c. Progress Callback Flow

Luồng này xử lý progress callbacks từ Collector Service:

#align(center)[
  #image("../images/data-flow/webhook_callback.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Progress Callback Flow_])
  #image_counter.step()
]

==== 5.3.3.4 Design Patterns áp dụng

Project Service áp dụng các design patterns sau:

- Clean Architecture: 4 layers Delivery → UseCase → Domain → Infrastructure với dependency inversion. Testability cao, maintainability tốt.

- Repository Pattern: ProjectRepository cho database, StateRepository cho cache. Abstract data access qua interfaces, business logic không phụ thuộc vào storage cụ thể.

- Event-Driven Architecture: Producer publish project events. Decoupling giữa services, async processing, và resilience.

- Distributed State Management: StateUseCase quản lý project state trong distributed cache. Single Source of Truth cho project progress, real-time updates qua Pub/Sub.

- Explicit Execution Pattern: Project được tạo với status="draft", chỉ execute khi user explicitly call Execute(). User có thể review và edit configuration trước khi execute.

==== 5.3.3.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Project Service_])
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Creation Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Execution Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress Callback Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Concurrent Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 50 projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
  )
]

==== 5.3.3.6 Key Decisions

- Draft Status Pattern: Project được tạo với status="draft", không kích hoạt bất kỳ processing nào. Cho phép user review và edit configuration trước khi execute.

- Explicit Execution: Tách biệt "configuration" và "execution" thành 2 operations riêng biệt. User có thể tạo nhiều projects và execute sau.

- Duplicate Execution Prevention: Check cache state trước khi execute, return error nếu project đang executing. Tránh duplicate processing và inconsistent state.

- Rollback Logic: Nếu message queue publish fails sau khi đã update database và init cache, rollback cả hai. Đảm bảo consistency.

==== 5.3.3.7 Dependencies

Internal Dependencies:

- StateUseCase: Quản lý project state trong distributed cache.
- RabbitMQProducer: Publish project events.
- SamplingUseCase: Dry-run functionality.

External Dependencies:

- Relational Database (PostgreSQL): Project metadata persistence.
- Distributed Cache (Redis): State management và Pub/Sub.
- Message Queue (RabbitMQ): Event publishing.
- Identity Service: User authentication (JWT validation).


=== 5.3.4 Identity Service

Identity Service là service quản lý authentication và authorization trong hệ thống SMAP, cung cấp JWT-based authentication, role-based access control, và user management. Service này đóng vai trò Utility service trong kiến trúc tổng thể, được sử dụng bởi tất cả các services khác để verify user identity và permissions.

Vai trò của Identity Service trong kiến trúc tổng thể:

- Authentication Provider: Cung cấp login, registration, và JWT token generation.
- Authorization Provider: Role-based access control (USER, ADMIN) và permission checking.
- User Management: CRUD operations cho user accounts và profiles.
- Session Management: HttpOnly cookie-based session management với refresh tokens.

Service này đáp ứng các NFRs về Security (Authentication & Authorization) và liên quan đến tất cả Use Cases (user phải authenticated để sử dụng hệ thống).

==== 5.3.4.1 Component Diagram - C4 Level 3

Identity Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/identity-component-diagram.png", width: 100%)
  #context (
    align(
      center,
    )[_Hình #image_counter.display(): Biểu đồ thành phần của Identity Service - Clean Architecture 4 layers_]
  )
  #image_counter.step()
]

==== 5.3.4.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Identity Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AuthHandler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request handlers cho authentication operations],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP requests (POST)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Framework (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth \ Middleware],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT validation từ HttpOnly cookie, set scope trong context],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request với cookie],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Context với scope],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Authentication \ UseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Business logic cho authentication: login, register, OTP verification],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LoginInput, RegisterInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LoginOutput với JWT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User \ UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business logic cho user management: CRUD, password change],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CreateInput, UpdateInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UserOutput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Password \ Encrypter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Password hashing và verification],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Plain password],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hashed password],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hashing Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT \ Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT token generation và validation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User claims],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT token string],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database data access layer cho users],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM (Go)],
  )
]

==== 5.3.4.3 Data Flow

Luồng xử lý chính của Identity Service được chia thành 3 flows: User Registration, User Login, và JWT Validation.

===== a. User Registration Flow

Luồng này được kích hoạt khi user đăng ký tài khoản mới:

#align(center)[
  #image("../images/data-flow/user_registration_flow.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng User Registration Flow_])
  #image_counter.step()
]

===== b. User Login Flow

Luồng này được kích hoạt khi user đăng nhập:

#align(center)[
  #image("../images/data-flow/user_login.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng User Login Flow_])
  #image_counter.step()
]

===== c. JWT Validation Flow

Luồng này được kích hoạt cho mỗi authenticated request:

#align(center)[
  #image("../images/data-flow/auth_middleware.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng JWT Validation - Auth Middleware_])
  #image_counter.step()
]

==== 5.3.4.4 Design Patterns áp dụng

Identity Service áp dụng các design patterns sau:

- Clean Architecture: 4 layers Delivery → UseCase → Domain → Infrastructure với dependency inversion. Testability cao, maintainability tốt.

- Repository Pattern: UserRepository cho database. Abstract data access qua interfaces, business logic không phụ thuộc vào database cụ thể.

- Strategy Pattern: PasswordEncrypter có thể switch hashing algorithm. Encrypter interface với HashPassword() và CheckPasswordHash() methods.

- HttpOnly Cookie Pattern: JWT token được set trong HttpOnly cookie thay vì localStorage. Bảo vệ khỏi XSS attacks.

- Role-Based Access Control: User model có Role field, JWT token chứa role claim. Middleware check role từ JWT payload, enforce permissions.

==== 5.3.4.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Identity Service_])
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth Check Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Login Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Registration Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
  )
]

==== 5.3.4.6 Key Decisions

- Secure Password Hashing: Sử dụng industry-standard hashing algorithm. Balance giữa security và performance, đủ mạnh để resist brute-force attacks.

- HttpOnly Cookie cho JWT: Set JWT token trong HttpOnly cookie thay vì localStorage. Bảo vệ khỏi XSS attacks và CSRF protection.

- OTP-based Email Verification: Sử dụng OTP cho email verification thay vì magic links. OTP đơn giản hơn, không cần email template phức tạp.

- Async Email Sending: Publish email events đến message queue thay vì gửi email trực tiếp. Không block request handler, improve response time.

- Role-Based Access Control: JWT token chứa role claim, middleware enforce permissions dựa trên role. Fine-grained access control.

==== 5.3.4.7 Dependencies

Internal Dependencies:

- UserUseCase: Quản lý user accounts và profiles.
- PasswordEncrypter: Hash và verify passwords.
- JWTManager: Generate và validate JWT tokens.
- RabbitMQProducer: Publish email events.

External Dependencies:

- Relational Database (PostgreSQL): User data persistence.
- Message Queue (RabbitMQ): Email event publishing (async email sending).
- Consumer Service: Process email events (OTP sending via SMTP).


=== 5.3.5 WebSocket Service

WebSocket Service là service cung cấp real-time communication giữa hệ thống và clients (Web UI), cho phép push progress updates, notifications, và system status đến users mà không cần polling. Service này consume messages từ Pub/Sub và deliver đến WebSocket clients.

Vai trò của WebSocket Service trong kiến trúc tổng thể:

- Real-time Communication Hub: Cung cấp WebSocket connections cho clients.
- Message Router: Route messages từ Pub/Sub topics đến đúng WebSocket connections.
- Connection Manager: Quản lý lifecycle của WebSocket connections (connect, disconnect, heartbeat).
- Progress Delivery: Deliver progress updates từ Collector Service đến Web UI clients.

Service này đáp ứng FR-2 (Real-time progress tracking) và liên quan trực tiếp đến UC-06 (Progress updates).

==== 5.3.5.1 Component Diagram - C4 Level 3

WebSocket Service được tổ chức theo Clean Architecture với 3 layers chính:

#align(center)[
  #image("../images/component/websocket-component-diagram.png", width: 100%)
  #context (
    align(
      center,
    )[_Hình #image_counter.display(): Biểu đồ thành phần của WebSocket Service - Clean Architecture 3 layers_]
  )
  #image_counter.step()
]

==== 5.3.5.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket \ Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Handle WebSocket connections, upgrade HTTP → WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP upgrade request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Library (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection \ Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý WebSocket connections với topic mapping],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection, topic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection registry],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Message \ Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route messages từ Pub/Sub → WebSocket connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub \ Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Subscribe to topics, receive messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Topic pattern],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub Client (Go)],
  )
]

==== 5.3.5.3 Data Flow

Luồng xử lý chính của WebSocket Service được chia thành 2 flows: Connection Establishment và Message Delivery.

===== a. Connection Establishment Flow

Luồng này được kích hoạt khi client connect WebSocket:

#align(center)[
  #image("../images/data-flow/webSocket_connection.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Connection Establishment Flow của WebSocket Service_])
  #image_counter.step()
]

===== b. Message Delivery Flow

#align(center)[
  #image("../images/data-flow/real-time.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Message Delivery Flow của WebSocket Service_])
  #image_counter.step()
]

==== 5.3.5.4 Design Patterns áp dụng

WebSocket Service áp dụng các design patterns sau:

- Observer Pattern: Pub/Sub subscribe to topics, receive messages khi có updates. Decoupling giữa publishers và subscribers, scalability với multiple WebSocket instances.

- Connection Pooling: ConnectionManager quản lý multiple WebSocket connections. In-memory registry của connections với topic mapping, efficient lookup và broadcast.

- Graceful Shutdown: Close WebSocket connections gracefully, unsubscribe từ topics, và wait for in-flight messages. Không mất messages trong quá trình shutdown.

- Health Check Pattern: Shallow và Deep health checks. Shallow check cho HTTP server và connection, Deep check cho Pub/Sub working và message delivery.

==== 5.3.5.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Latency (p95)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection Establishment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 50ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Concurrent Connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 1,000],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 5,000 msg/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
  )
]

==== 5.3.5.6 Key Decisions

- Pub/Sub cho Message Routing: Sử dụng Pub/Sub thay vì direct WebSocket-to-WebSocket communication. Decoupling giữa publishers và WebSocket Service, scalability với multiple instances.

- Topic-Based Routing: Sử dụng topic pattern để route messages đến đúng connections. Mỗi user chỉ nhận messages cho projects của họ.

- Connection Registry: In-memory registry của WebSocket connections với topic mapping. Fast lookup và efficient broadcast.

- Graceful Shutdown: Close connections gracefully, unsubscribe từ topics, và wait for in-flight messages. Không mất messages trong quá trình shutdown.

==== 5.3.5.7 Dependencies

Internal Dependencies:

- ConnectionManager: Quản lý WebSocket connections.
- MessageHandler: Route messages từ Pub/Sub đến WebSocket connections.

External Dependencies:

- Distributed Cache (Redis) Pub/Sub: Message consumption.
- Project Service: Publish messages to Pub/Sub (progress callbacks).
- Web UI: WebSocket clients connect và receive messages.

=== 5.3.6 Web UI

Web UI là frontend application cung cấp dashboard quản trị, project management interface, và real-time progress visualization. Service này tương tác với tất cả backend services qua REST APIs và WebSocket connections.

Vai trò của Web UI trong kiến trúc tổng thể:

- User Interface: Cung cấp UI cho tất cả Use Cases từ UC-01 đến UC-08.
- Real-time Visualization: Hiển thị progress updates qua WebSocket connections.
- API Client: Gọi REST APIs từ các backend services (Identity, Project, Analytics).
- State Management: Quản lý client-side state.

Service này đáp ứng tất cả Use Cases từ phía user interface và liên quan đến NFRs về Usability (UX requirements).

==== 5.3.6.1 Component Diagram - C4 Level 3

Web UI được tổ chức theo Component-based Architecture:

#align(center)[
  #image("../images/component/webui-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Component Diagram Web UI_])
  #image_counter.step()
]

==== 5.3.6.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Web UI_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project \ Wizard],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Multi-step form để tạo project cho UC-01],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User input (form data)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[POST /projects API call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React components],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress \ Tracker],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Real-time progress visualization cho UC-06],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UI updates],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React + WebSocket],

    table.cell(align: center + horizon, inset: (y: 0.8em))[useWebSocket \ Hook],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection management với auto-reconnect],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, UserID],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React hooks],

    table.cell(align: center + horizon, inset: (y: 0.8em))[API \ Clients],
    table.cell(align: center + horizon, inset: (y: 0.8em))[REST API calls đến backend services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API requests],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Client],
  )
]

==== 5.3.6.3 Data Flow

Luồng xử lý chính của Web UI được chia thành 2 flows: Project Creation và Real-time Progress Updates.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới theo UC-01:

#align(center)[
  #image("../images/data-flow/authen.png", width: 90%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Creation Flow_])
  #image_counter.step()
]

===== b. Real-time Progress Updates Flow

Luồng này được kích hoạt khi project đang executing theo UC-06:

#context (
  align(center)[
    // #image("../images/data-flow/progress.png", width: 90%)
  ]
)
#context (align(center)[_Hình #image_counter.display(): Luồng Real-time Progress Updates Flow_])
#image_counter.step()


==== 5.3.6.4 Design Patterns áp dụng

Web UI áp dụng các design patterns sau:

- Component-based Architecture: React components như ProjectWizard, ProgressTracker, Dashboard. Mỗi component là một reusable unit với props và state. Reusability cao, maintainability tốt.

- Custom Hooks Pattern: useWebSocket(), useProjectProgress(), useAuth(). Encapsulate logic trong custom hooks, components consume hooks. Logic reuse và separation of concerns.

- Context API Pattern: AuthContext, ProjectContext. React Context để share state across components. Avoid prop drilling và centralized state management.

- Server-Side Rendering: Pages được render trên server, send HTML to client. SEO tốt hơn và initial load nhanh hơn.

==== 5.3.6.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Web UI_])
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dashboard Loading],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 3s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-UX-1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[First Contentful Paint],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 2s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-UX-1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Update Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
  )
]

==== 5.3.6.6 Thiết kế giao diện

Phần này trình bày thiết kế giao diện người dùng của hệ thống SMAP, bao gồm các màn hình chính phục vụ cho các Use Cases đã định nghĩa trong Chương 4. Giao diện được thiết kế theo nguyên tắc đơn giản, trực quan và tập trung vào trải nghiệm người dùng.

===== a. Màn hình Landing Page

Màn hình Landing Page là điểm tiếp xúc đầu tiên của người dùng với hệ thống SMAP. Giao diện được thiết kế với phong cách hiện đại, tối giản và chuyên nghiệp nhằm tạo ấn tượng ban đầu tích cực cho Marketing Analyst.

#align(center)[
  #image("../images/UI/landing.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Landing Page của hệ thống SMAP_])
  #image_counter.step()
]

Màn hình Landing Page bao gồm các thành phần chính sau:

- Header Navigation: Thanh điều hướng phía trên với logo SMAP, các liên kết đến trang Features, Pricing, About và nút đăng nhập hoặc đăng ký.

- Hero Section: Khu vực giới thiệu chính với tiêu đề nổi bật, mô tả ngắn gọn về giá trị của hệ thống và nút Call-to-Action để bắt đầu sử dụng.

- Feature Highlights: Phần trình bày các tính năng nổi bật của hệ thống như phân tích sentiment, theo dõi đối thủ cạnh tranh và phát hiện xu hướng.

===== b. Màn hình Quản lý danh sách Projects

Màn hình này phục vụ cho UC-05 về Quản lý danh sách Projects, cho phép Marketing Analyst xem, lọc, tìm kiếm và điều hướng đến các chức năng tương ứng với trạng thái của từng project.

#align(center)[
  #image("../images/UI/cacprojects.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Quản lý danh sách Projects_])
  #image_counter.step()
]

Giao diện màn hình Quản lý danh sách Projects được tổ chức với các thành phần sau:

- Thanh công cụ phía trên: Bao gồm ô tìm kiếm theo tên project, bộ lọc theo trạng thái và nút tạo project mới.

- Danh sách Projects: Hiển thị dưới dạng bảng hoặc lưới với các thông tin tên project, trạng thái hiển thị bằng badge màu sắc khác nhau, ngày tạo, lần cập nhật cuối và preview từ khóa thương hiệu.

- Actions theo trạng thái: Mỗi project hiển thị các hành động phù hợp với trạng thái hiện tại. Project ở trạng thái Draft cho phép Khởi chạy hoặc Xóa. Project đang Running cho phép Xem tiến độ. Project Completed cho phép Xem kết quả, Xuất báo cáo hoặc Xóa. Project Failed cho phép Thử lại hoặc Xóa.

- Phân trang: Hỗ trợ infinite scroll hoặc pagination khi số lượng projects vượt quá 20 items mỗi trang.

===== c. Màn hình Dry-run kiểm tra từ khóa

Màn hình này phục vụ cho UC-02 về Kiểm tra từ khóa, cho phép Marketing Analyst xác thực chất lượng từ khóa trước khi lưu project bằng cách xem mẫu kết quả thu thập được.

#align(center)[
  #image("../images/UI/dryrun.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Dry-run kiểm tra từ khóa_])
  #image_counter.step()
]

Giao diện màn hình Dry-run bao gồm các thành phần chính:

- Thông tin từ khóa: Hiển thị danh sách các từ khóa đang được kiểm tra cùng với platform tương ứng.

- Kết quả mẫu: Hiển thị tối đa 3 posts mỗi từ khóa với các thông tin tiêu đề, preview nội dung, platform nguồn, số lượt xem, lượt thích, bình luận và chia sẻ.

- Trạng thái loading: Hiển thị indicator khi đang thu thập mẫu với thông báo tiến độ.

- Nút điều hướng: Cho phép người dùng quay lại chỉnh sửa từ khóa hoặc tiếp tục lưu project.

===== d. Màn hình Dashboard phân tích

Màn hình Dashboard phục vụ cho UC-04 về Xem kết quả phân tích, cung cấp cái nhìn tổng quan về sentiment trends, aspect analysis và competitor comparison cho Marketing Analyst.

#align(center)[
  #image("../images/UI/char1.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Dashboard phân tích tổng quan_])
  #image_counter.step()
]

Giao diện Dashboard được chia thành 4 phần chính theo đặc tả UC-04:

- Biểu đồ Line hoặc Area Chart: Hiển thị số lượng mentions theo thời gian với hỗ trợ radio button chọn khoảng thời gian và tooltip hiển thị chi tiết khi hover.

- Biểu đồ Bar Chart so sánh: Thể hiện share of voice giữa thương hiệu và các đối thủ cạnh tranh, giúp Marketing Analyst đánh giá vị thế thương hiệu trên thị trường.

- Keyword Cloud: Hiển thị top 20 từ khóa được nhắc đến nhiều nhất với kích thước font tỷ lệ thuận với tần suất xuất hiện. Vị trí từ khóa của thương hiệu được highlight để dễ nhận biết.

#align(center)[
  #image("../images/UI/char2.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ so sánh Share of Voice giữa thương hiệu và đối thủ_])
  #image_counter.step()
]

#align(center)[
  #image("../images/UI/char3.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Hiển thị chi tiết một từ khoá_])
  #image_counter.step()
]


#align(center)[
  #image("../images/UI/char4.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Bảng dữ liệu về bài viết thịnh hành_])
  #image_counter.step()
]

Dashboard hỗ trợ các tính năng tương tác sau:

- Bộ lọc: Cho phép lọc theo platform, sentiment, khoảng thời gian và aspect.

- Drilldown: Nhấn vào aspect để xem danh sách posts liên quan, nhấn vào post để xem chi tiết đầy đủ bao gồm cả comments.

- Xuất báo cáo: Nút điều hướng đến UC-06 để tạo và tải file báo cáo.

===== e. Màn hình Trend Dashboard

Màn hình này phục vụ cho UC-07 về Phát hiện trend tự động, hiển thị danh sách các xu hướng nổi bật được hệ thống thu thập và xếp hạng từ các nền tảng mạng xã hội.

#align(center)[
  #image("../images/UI/trend.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Trend Dashboard_])
  #image_counter.step()
]

Giao diện Trend Dashboard bao gồm các thành phần:

- Trends Grid: Hiển thị lưới các xu hướng với thông tin tiêu đề, nền tảng nguồn, điểm xu hướng và chỉ số tăng trưởng.

- Bộ lọc: Cho phép lọc theo nền tảng, loại nội dung và khoảng thời gian.

- Thông tin chi tiết: Mỗi trend card hiển thị preview nội dung, số liệu engagement và velocity score.

- Cảnh báo trạng thái: Hiển thị thông báo khi dữ liệu từ một nền tảng gặp sự cố hoặc chưa được cập nhật.

===== f. Nguyên tắc thiết kế giao diện

Giao diện hệ thống SMAP được thiết kế tuân theo các nguyên tắc sau:

- Consistency: Sử dụng hệ thống design tokens thống nhất cho màu sắc, typography, spacing và components trên toàn bộ ứng dụng.

- Responsive Design: Giao diện tương thích với nhiều kích thước màn hình từ desktop đến tablet, đảm bảo trải nghiệm nhất quán.

- Accessibility: Tuân thủ các tiêu chuẩn WCAG về contrast ratio, keyboard navigation và screen reader support.

- Performance: Tối ưu hóa loading time với lazy loading cho images và code splitting cho các components lớn.

- Feedback: Cung cấp phản hồi trực quan cho mọi hành động của người dùng thông qua loading states, success messages và error notifications.

