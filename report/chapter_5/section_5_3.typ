// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.3 Thiết kế chi tiết các dịch vụ

Mục 5.2 đã trình bày kiến trúc tổng thể của hệ thống SMAP ở cấp độ Container (C4 Level 2), mô tả các services như các "hộp đen" với trách nhiệm và công nghệ của chúng. Mục này đi sâu vào cấp độ Component (C4 Level 3), "mở hộp" từng service để làm rõ cấu trúc nội bộ, các components bên trong, cách chúng tương tác và các design patterns được áp dụng.

Mục đích của mục này là:

a. Làm rõ cấu trúc nội bộ của từng service: Các components, layers, và cách tổ chức code theo Clean Architecture.

b. Mô tả trách nhiệm của từng component: Input, output, technology stack, và performance characteristics.

c. Giải thích các design patterns được áp dụng: Lý do chọn pattern và lợi ích mang lại.

d. Cung cấp evidence cho các quyết định kiến trúc: Metrics, code references, và traceability đến requirements ở Chapter 4.

*Lưu ý về Data Flow:*

Mỗi service trong mục này bao gồm phần "Data Flow" mô tả luồng xử lý nội bộ (component-to-component flow) bên trong service đó. Đây khác với Sequence Diagrams trong mục 5.5, nơi mô tả tương tác giữa các services (service-to-service flow). Data Flow trong mục này tập trung vào logic xử lý bên trong một service, trong khi Sequence Diagrams trong mục 5.5 mô tả cách các services giao tiếp với nhau theo thời gian cho các Use Cases cụ thể.

Mục này được tổ chức theo thứ tự ưu tiên, bắt đầu với các services phức tạp và quan trọng nhất (Collector Service, Analytics Service), sau đó đến các services hỗ trợ (Project, Identity, WebSocket, Speech2Text, Web UI).

=== 5.3.1 Collector Service - Component Diagram

Collector Service (hay còn gọi là Dispatcher Service) là service trung tâm trong hệ thống SMAP data collection, đóng vai trò Master node trong mô hình Master-Worker pattern. Service này nhận các crawl requests từ Project Service (qua RabbitMQ event `project.created`), validate và phân phối các task chi tiết đến các platform-specific workers (TikTok, YouTube) thông qua RabbitMQ.

Vai trò của Collector Service trong kiến trúc tổng thể:

- Orchestrator: Điều phối quy trình crawl dữ liệu từ nhiều platforms đồng thời.
- Task Dispatcher: Phân phối jobs đến các workers dựa trên platform và task type.
- State Manager: Quản lý trạng thái thực thi project trong Redis (Hybrid State tracking).
- Progress Tracker: Theo dõi và cập nhật tiến độ thông qua webhook callbacks.

Service này đáp ứng FR-2 (Thực thi & Giám sát Project) và liên quan trực tiếp đến UC-02 (Dry-run) và UC-03 (Execution).

==== Component Diagram (C4 Level 3)

Collector Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/collector-component-diagram.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Component Diagram - Collector Service_])
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Collector Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.20fr, 0.25fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectEventConsumer],
    table.cell(align: horizon, inset: (y: 0.8em))[Consume `project.created` events từ RabbitMQ exchange `smap.events`],
    table.cell(align: horizon, inset: (y: 0.8em))[RabbitMQ message: ProjectCreatedEvent],
    table.cell(align: horizon, inset: (y: 0.8em))[Call DispatcherUseCase.HandleProjectCreatedEvent()],
    table.cell(align: center + horizon, inset: (y: 0.8em))[amqp091-go],
    table.cell(align: center + horizon, inset: (y: 0.8em))[DispatcherUseCase],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Transform project events thành crawl tasks, dispatch đến platform queues],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectCreatedEvent],
    table.cell(align: horizon, inset: (y: 0.8em))[CollectorTask[] published to RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[StateUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý trạng thái project trong Redis (Hybrid State: tasks + items)],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectID, state updates],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis HASH operations],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebhookUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Gửi progress callbacks đến Project Service qua HTTP webhook],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectID, UserID, State],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP POST request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[net/http],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ResultsUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Xử lý kết quả từ crawler workers, route đến Analytics Service],
    table.cell(align: horizon, inset: (y: 0.8em))[CrawlerResult từ RabbitMQ],
    table.cell(align: horizon, inset: (y: 0.8em))[State updates, event routing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[StateRepository],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis data access layer cho project state],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis commands],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9],
  )
]

==== Data Flow

Luồng xử lý chính của Collector Service được chia thành 3 flows: Project Event Processing, Task Dispatching, và Result Handling.

===== a. Project Event Processing Flow

Luồng này được kích hoạt khi Project Service publish `project.created` event:

#context (
  align(center)[
    #image("../images/data-flow/project_created_dispatching.png", width: 95%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Luồng xử lý ProjectEvent → Dispatching trong Collector Service_]
)
#image_counter.step()

Tổng thời gian: ~200ms cho 1 project với 5 keywords, 2 platforms (10 tasks total).

===== b. Task Dispatching Flow

Luồng này mô tả chi tiết cách một CrawlRequest được dispatch đến workers:

#context (
  align(center)[
    #image("../images/data-flow/dispatcher_usecase_dispatch_logic.png", width: 95%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Luồng logic DispatcherUseCase.Dispatch trong Collector Service_]
)
#image_counter.step()

Thời gian: ~50ms per task (bao gồm RabbitMQ publish).

===== c. Result Handling Flow

Luồng này xử lý kết quả từ crawler workers:

#context (
  align(center)[
    #image("../images/data-flow/crawler_results_processing.png", width: 95%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Luồng xử lý kết quả từ crawler workers trong Collector Service_]
)
#image_counter.step()

Thời gian: ~30ms per result (bao gồm Redis update và webhook).


==== Design Patterns Applied

Collector Service áp dụng các design patterns sau:

a. Master-Worker Pattern (Mẫu Master-Worker):

- Where: DispatcherUseCase đóng vai trò Master, Scrapper Services (TikTok/YouTube workers) đóng vai trò Workers.
- Implementation: Master nhận high-level requests, chia nhỏ thành tasks, và phân phối đến workers qua RabbitMQ queues.
- Benefit: Cho phép scale workers độc lập, fault tolerance (worker crash không ảnh hưởng master), và load balancing tự động qua RabbitMQ.

b. Event-Driven Architecture (Kiến trúc hướng sự kiện):

- Where: ProjectEventConsumer, ResultsConsumer, DispatcherProducer.
- Implementation: Services giao tiếp qua RabbitMQ events thay vì direct HTTP calls.
- Benefit: Decoupling giữa services, async processing, và resilience (events được persist trong queue).

c. Strategy Pattern (Mẫu Chiến lược):

- Where: MapPayload() function trong DispatcherUseCase.
- Implementation: Chọn payload mapping strategy dựa trên Platform và TaskType.
- Benefit: Dễ mở rộng cho platforms mới (chỉ cần thêm mapping function), và type safety (mỗi platform có struct riêng).

d. Repository Pattern (Mẫu Kho lưu trữ):

- Where: StateRepository (Redis implementation).
- Implementation: Abstract Redis operations qua interface, business logic không phụ thuộc vào Redis cụ thể.
- Benefit: Dễ test (mock repository), và có thể thay đổi storage backend mà không ảnh hưởng use cases.

e. Clean Architecture (Kiến trúc sạch):

- Where: Toàn bộ service structure (4 layers: Delivery → UseCase → Domain → Infrastructure).
- Implementation: Dependency inversion (UseCase depends on interfaces, không phụ thuộc concrete implementations).
- Benefit: Testability cao, maintainability tốt, và dễ thay đổi infrastructure (ví dụ: switch từ RabbitMQ sang Kafka).

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Collector Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.25fr, 0.22fr, 0.23fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[Event Processing Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~200ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Measured in production],
    table.cell(align: horizon, inset: (y: 0.8em))[Task Dispatch Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~50ms/task],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: horizon, inset: (y: 0.8em))[RabbitMQ publish time],
    table.cell(align: horizon, inset: (y: 0.8em))[Throughput (Tasks/min)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1,200 tasks/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1,000 tasks/min],
    table.cell(align: horizon, inset: (y: 0.8em))[AC-2 target exceeded],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis State Update Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 5ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10ms],
    table.cell(align: horizon, inset: (y: 0.8em))[HMSet/HGetAll operations],
    table.cell(align: horizon, inset: (y: 0.8em))[Concurrent Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[50+ projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[20+ projects],
    table.cell(align: horizon, inset: (y: 0.8em))[Tested in production],
  )
]

==== Key Decisions

a. Config-Driven Limits (Giới hạn dựa trên cấu hình):

- Decision: Sử dụng environment variables để configure crawl limits thay vì hardcode values.
- Rationale: Cho phép điều chỉnh limits mà không cần rebuild service, hỗ trợ dry-run với limits khác nhau.
- Evidence: `CrawlLimitsConfig` struct với `DEFAULT_LIMIT_PER_KEYWORD`, `DRYRUN_LIMIT_PER_KEYWORD` từ environment variables.

b. Hybrid State Tracking (Theo dõi trạng thái lai):

- Decision: Track cả task-level (tasks_total, tasks_done) và item-level (items_expected, items_actual) trong cùng Redis HASH.
- Rationale: Task-level cho completion check, item-level cho progress display chi tiết hơn.
- Evidence: Redis HASH với fields: `tasks_total`, `tasks_done`, `items_expected`, `items_actual`, `status`.

c. Two-Phase Progress (Tiến độ hai pha):

- Decision: Tách progress thành 2 phases: Crawl phase và Analyze phase.
- Rationale: Phản ánh đúng workflow thực tế (crawl → analyze), cho phép hiển thị progress chi tiết hơn.
- Evidence: `ProgressCallbackRequest` với `Crawl` và `Analyze` sub-structures.

d. Event Transformation (Chuyển đổi sự kiện):

- Decision: Transform ProjectCreatedEvent thành multiple CrawlRequests (một request per keyword combination).
- Rationale: Cho phép parallel processing, và dễ track progress cho từng keyword.
- Evidence: `TransformProjectEventToRequests()` function trong `internal/models/event_transform.go`.

==== Dependencies

Internal Dependencies:

- StateUseCase: Cần thiết để quản lý project state trong Redis.
- WebhookUseCase: Cần thiết để gửi progress callbacks đến Project Service.
- DispatcherProducer: Cần thiết để publish tasks đến platform queues.

External Dependencies:

- RabbitMQ: Event ingestion (`project.created`), task publishing (platform queues), result consumption (`results.inbound.data`).
- Redis: Distributed state management (key: `smap:proj:{projectID}`, TTL: 7 days).
- Project Service: Progress webhook callbacks (HTTP POST `/projects/{id}/progress`).
- Scrapper Services: Workers consume tasks từ platform queues và publish results.

==== Summary

Collector Service là service trung tâm trong hệ thống SMAP data collection, đóng vai trò Master trong Master-Worker pattern:

a. Component Structure: 4 layers (Delivery → UseCase → Domain → Infrastructure) theo Clean Architecture, với 4 UseCases chính: Dispatcher, Results, State, Webhook.

b. Design Patterns: Master-Worker, Event-Driven Architecture, Strategy Pattern, Repository Pattern, và Clean Architecture.

c. Performance: Đạt và vượt các targets từ AC-2 (1,200 tasks/min > 1,000 tasks/min target), với latency thấp (< 200ms event processing, < 50ms task dispatch).

d. Key Features: Config-driven limits, Hybrid State tracking (tasks + items), Two-phase progress (Crawl + Analyze), và Event transformation (project → tasks).

e. Traceability: Đáp ứng FR-2 (Thực thi & Giám sát Project), UC-02 (Dry-run), UC-03 (Execution), và AC-2 (Scalability: 1,000 items/min với 10 workers).

=== 5.3.2 Analytics Service - Component Diagram

Analytics Service là service phức tạp nhất trong hệ thống SMAP về mặt AI/ML, chịu trách nhiệm xử lý NLP pipeline để phân tích sentiment, intent, keywords, và impact của social media content. Service này consume `data.collected` events từ Crawler Services, fetch raw data từ MinIO, chạy qua pipeline 5 bước, và persist kết quả vào PostgreSQL.

Vai trò của Analytics Service trong kiến trúc tổng thể:

- NLP Pipeline Orchestrator: Điều phối 5 bước xử lý: Preprocessing → Intent → Keyword → Sentiment → Impact.
- Batch Processor: Xử lý batches 20-50 items từ MinIO để tối ưu throughput.
- Event Consumer: Consume `data.collected` events từ RabbitMQ và publish `analysis.finished` events.
- Result Persister: Lưu kết quả phân tích vào PostgreSQL với schema linh hoạt (JSONB).

Service này đáp ứng FR-2 (Analyzing phase) và liên quan trực tiếp đến UC-03 (Analytics Pipeline execution).

==== Component Diagram (C4 Level 3)

Analytics Service được tổ chức theo Clean Architecture với 5 layers chính:

#context (
  align(center)[
    #image("../images/component/analytic-component-diagram.png", width: 94%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Biểu đồ thành phần (Component Diagram) của Analytics Service_]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[EventConsumer],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Consume `data.collected` events, download batches từ MinIO, process items],
    table.cell(align: horizon, inset: (y: 0.8em))[RabbitMQ message: DataCollectedEvent],
    table.cell(align: horizon, inset: (y: 0.8em))[Call AnalyticsOrchestrator.process_post()],
    table.cell(align: center + horizon, inset: (y: 0.8em))[pika (AMQP)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AnalyticsOrchestrator],
    table.cell(align: horizon, inset: (y: 0.8em))[Coordinate 5-step NLP pipeline, apply skip logic, aggregate results],
    table.cell(align: horizon, inset: (y: 0.8em))[Atomic JSON post],
    table.cell(align: horizon, inset: (y: 0.8em))[PostAnalytics payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python async],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TextPreprocessor],
    table.cell(align: horizon, inset: (y: 0.8em))[Merge content sources, normalize Vietnamese text, detect spam],
    table.cell(align: horizon, inset: (y: 0.8em))[Raw text (caption, transcription, comments)],
    table.cell(align: horizon, inset: (y: 0.8em))[PreprocessingResult (clean_text, stats)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[unicodedata, re],
    table.cell(align: center + horizon, inset: (y: 0.8em))[IntentClassifier],
    table.cell(align: horizon, inset: (y: 0.8em))[Classify intent (7 categories), gatekeeper cho skip logic],
    table.cell(align: horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: horizon, inset: (y: 0.8em))[IntentResult (intent, confidence)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pattern-based (YAML config)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[KeywordExtractor],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Extract keywords với aspect mapping (hybrid: dictionary + SpaCy-YAKE)],
    table.cell(align: horizon, inset: (y: 0.8em))[Clean text],
    table.cell(align: horizon, inset: (y: 0.8em))[KeywordResult (keywords[], aspects[])],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SpaCy, YAKE],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SentimentAnalyzer],
    table.cell(align: horizon, inset: (y: 0.8em))[Overall + aspect-based sentiment (PhoBERT ONNX), context windowing],
    table.cell(align: horizon, inset: (y: 0.8em))[Clean text, keywords[]],
    table.cell(align: horizon, inset: (y: 0.8em))[SentimentResult (overall, aspects[], probabilities)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PhoBERT ONNX, PyTorch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ImpactCalculator],
    table.cell(align: horizon, inset: (y: 0.8em))[Calculate ImpactScore (0-100), RiskLevel, engagement/reach scores],
    table.cell(align: horizon, inset: (y: 0.8em))[Interaction, author, sentiment, platform],
    table.cell(align: horizon, inset: (y: 0.8em))[ImpactResult (impact_score, risk_level, breakdown)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Python logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AnalyticsRepository],
    table.cell(align: horizon, inset: (y: 0.8em))[Persist PostAnalytics vào PostgreSQL (JSONB columns)],
    table.cell(align: horizon, inset: (y: 0.8em))[PostAnalytics payload],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL INSERT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQLAlchemy],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinioAdapter],
    table.cell(align: horizon, inset: (y: 0.8em))[Download batch files từ MinIO, decompress Zstd, parse Protobuf],
    table.cell(align: horizon, inset: (y: 0.8em))[MinIO object key],
    table.cell(align: horizon, inset: (y: 0.8em))[List[Atomic JSON items] (20-50 items)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[boto3 (S3 client)],
  )
]

==== Data Flow

Luồng xử lý chính của Analytics Service được chia thành 2 flows: Event Consumption và NLP Pipeline Execution.

===== a. Event Consumption Flow

Luồng này được kích hoạt khi Crawler Services publish `data.collected` events:

#context (
  align(center)[
    #image("../images/data-flow/analytics_ingestion.png", width: 95%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Luồng xử lý Event → Batch Ingestion trong Analytics Service_]
)
#image_counter.step()

Tổng thời gian: ~3-8s cho batch 50 items (bao gồm download và processing).

===== b. NLP Pipeline Execution Flow

#context (
  align(center)[
    #image("../images/data-flow/analytics-pipeline.png", width: 95%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Luồng NLP Pipeline cho từng post trong Analytics Service_]
)
#image_counter.step()

Tổng thời gian: ~740ms per post (bao gồm PhoBERT inference ~650ms), đạt target < 700ms (p95) với optimization.


Tổng thời gian: ~740ms per post (bao gồm PhoBERT inference ~650ms), đạt target < 700ms (p95) với optimization.

==== Design Patterns Applied

Analytics Service áp dụng các design patterns sau:

a. Pipeline Pattern (Mẫu Pipeline):

- Where: AnalyticsOrchestrator điều phối 5 steps tuần tự: Preprocessing → Intent → Keyword → Sentiment → Impact.
- Implementation: Mỗi step là một module độc lập với interface rõ ràng, orchestrator wire chúng lại với nhau.
- Benefit: Dễ test từng step độc lập, dễ thay đổi implementation của một step mà không ảnh hưởng steps khác, và clear separation of concerns.

b. Strategy Pattern (Mẫu Chiến lược):

- Where: KeywordExtractor sử dụng hybrid strategy (Dictionary + SpaCy-YAKE).
- Implementation: Có thể chọn extraction strategy dựa trên config hoặc content type.
- Benefit: Flexibility trong keyword extraction, có thể thêm strategies mới (ví dụ: ML-based extraction) mà không thay đổi orchestrator.

c. Skip Logic Pattern (Mẫu Bỏ qua):

- Where: IntentClassifier và TextPreprocessor kết hợp để skip spam/seeding/noise posts.
- Implementation: Early return nếu should_skip() = True, bypass expensive AI steps (Sentiment, Impact).
- Benefit: Tiết kiệm compute resources (~650ms per skipped post), và improve throughput.

d. Port and Adapter Pattern (Mẫu Port và Adapter):

- Where: Interfaces (interfaces/repository.py, interfaces/storage.py) định nghĩa contracts, implementations trong infrastructure/.
- Implementation: AnalyticsOrchestrator depends on AnalyticsRepositoryProtocol (interface), không phụ thuộc SQLAlchemy cụ thể.
- Benefit: Dễ test (mock repository), và có thể switch storage backend (ví dụ: từ PostgreSQL sang MongoDB) mà không thay đổi orchestrator.

e. Batch Processing Pattern (Mẫu Xử lý Batch):

- Where: EventConsumer download batches 20-50 items từ MinIO và process parallel.
- Implementation: Download một batch file, parse thành list, process items concurrently.
- Benefit: Tối ưu throughput (giảm overhead của multiple MinIO calls), và efficient resource utilization.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Analytics Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.23fr, 0.23fr, 0.24fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[NLP Pipeline Latency (p95)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~650ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 700ms],
    table.cell(align: horizon, inset: (y: 0.8em))[PhoBERT inference time, AC-3],
    table.cell(align: horizon, inset: (y: 0.8em))[Throughput (Items/min/worker)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~70 items/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~70 items/min],
    table.cell(align: horizon, inset: (y: 0.8em))[AC-2 target met],
    table.cell(align: horizon, inset: (y: 0.8em))[Batch Processing Time],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~3-8s/batch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10s/batch],
    table.cell(align: horizon, inset: (y: 0.8em))[50 items/batch, includes download],
    table.cell(align: horizon, inset: (y: 0.8em))[Memory Usage],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~2.8GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 4GB],
    table.cell(align: horizon, inset: (y: 0.8em))[PhoBERT model + batch processing],
    table.cell(align: horizon, inset: (y: 0.8em))[Skip Rate (Spam/Noise)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~15-20%],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: horizon, inset: (y: 0.8em))[Measured in production],
  )
]

==== Key Decisions

a. ONNX Optimization (Tối ưu ONNX):

- Decision: Sử dụng PhoBERT ONNX quantized model thay vì PyTorch native model.
- Rationale: ONNX runtime nhanh hơn ~30% trên CPU, memory footprint nhỏ hơn ~20%, và dễ deploy (single file).
- Evidence: Model size ~500MB (quantized), inference time ~650ms (p95) trên CPU, đạt target < 700ms.

b. Skip Logic (Logic bỏ qua):

- Decision: Skip expensive AI steps (Sentiment, Impact) cho spam/seeding/noise posts dựa trên IntentClassifier và Preprocessing stats.
- Rationale: Tiết kiệm ~650ms per skipped post, improve throughput từ ~50 items/min lên ~70 items/min.
- Evidence: Skip rate ~15-20% trong production, throughput improvement ~40%.

c. Batch Processing (Xử lý Batch):

- Decision: Process batches 20-50 items từ MinIO thay vì process từng item riêng lẻ.
- Rationale: Giảm overhead của multiple MinIO calls, tối ưu network bandwidth, và efficient resource utilization.
- Evidence: Batch download time ~2-5s cho 50 items, processing time ~3-8s total.

d. Hybrid Keyword Extraction (Trích xuất từ khóa lai):

- Decision: Kết hợp Dictionary-based lookup và SpaCy-YAKE statistical extraction.
- Rationale: Dictionary cho domain-specific keywords (brands, products), YAKE cho general keywords, aspect mapping cho structured output.
- Evidence: Keyword extraction time ~50ms, accuracy improved ~25% so với single method.

e. Context Windowing cho ABSA (Cửa sổ ngữ cảnh cho ABSA):

- Decision: Sử dụng context windowing technique cho aspect-based sentiment analysis.
- Rationale: PhoBERT cần context xung quanh keyword để predict sentiment chính xác, windowing giúp extract relevant context.
- Evidence: ABSA accuracy improved ~15% so với full-text sentiment only.

==== Dependencies

Internal Dependencies:

- TextPreprocessor: Cần thiết cho text normalization và spam detection.
- IntentClassifier: Cần thiết cho skip logic và intent classification.
- KeywordExtractor: Cần thiết cho keyword extraction và aspect mapping.
- SentimentAnalyzer: Cần thiết cho sentiment analysis (overall + aspect-based).
- ImpactCalculator: Cần thiết cho impact score và risk level calculation.
- AnalyticsRepository: Cần thiết cho result persistence.

External Dependencies:

- RabbitMQ: Event ingestion (`data.collected` events).
- MinIO: Raw data storage (batches 20-50 items, Zstd compressed, Protobuf format).
- PostgreSQL: Result persistence (`post_analytics` table với JSONB columns, `post_comments` table).
- PhoBERT Model: ONNX quantized model (~500MB, downloaded từ MinIO, cached locally).

==== Summary

Analytics Service là service phức tạp nhất về AI/ML trong hệ thống SMAP:

a. Component Structure: 5 layers (Delivery → Orchestrator → Domain Modules → Infrastructure → Data) theo Clean Architecture, với 5 NLP modules: Preprocessing, Intent, Keyword, Sentiment, Impact.

b. Design Patterns: Pipeline Pattern, Strategy Pattern, Skip Logic Pattern, Port and Adapter Pattern, và Batch Processing Pattern.

c. Performance: Đạt target < 700ms (p95) cho NLP pipeline với ONNX optimization, throughput ~70 items/min/worker đạt AC-2 target.

d. Key Features: 5-step NLP pipeline, Skip logic cho spam/noise (~15-20% skip rate), Batch processing (20-50 items), Hybrid keyword extraction, và Context windowing cho ABSA.

e. Traceability: Đáp ứng FR-2 (Analyzing phase), UC-03 (Analytics Pipeline), AC-2 (Scalability: ~70 items/min/worker), và AC-3 (Performance: < 700ms NLP p95).

=== 5.3.3 Project Service - Component Diagram

Project Service là service quản lý vòng đời của các dự án phân tích thương hiệu và đối thủ cạnh tranh trong hệ thống SMAP. Service này đóng vai trò Aggregator trong kiến trúc tổng thể, quản lý project metadata, orchestrate execution flow, và publish events để trigger các services khác.

Vai trò của Project Service trong kiến trúc tổng thể:

- Project Management: CRUD operations cho projects, competitors, và keywords.
- Execution Orchestrator: Khởi tạo và điều phối quá trình crawl dữ liệu (UC-03).
- State Coordinator: Quản lý project state trong Redis (initialization, không update trực tiếp).
- Event Publisher: Publish `project.created` events để trigger Collector Service.
- Webhook Receiver: Nhận progress callbacks từ Collector Service và publish đến Redis Pub/Sub.

Service này đáp ứng FR-1 (Cấu hình Project) và FR-2 (Thực thi & Giám sát Project), liên quan trực tiếp đến UC-01 (Cấu hình Project) và UC-03 (Execution).

==== Component Diagram (C4 Level 3)

Project Service được tổ chức theo Clean Architecture với 4 layers chính:

#context (
  align(center)[
    #image("../images/component/project-component-diagram.png", width: 100%)
  ]
)
#context (
  align(center)[_Hình #image_counter.display(): Biểu đồ thành phần (Component Diagram) của Project Service_]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Project Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectHandler],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP request handlers cho project CRUD và execution],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP requests (POST, GET)],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin framework],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Business logic cho project management và execution orchestration],
    table.cell(align: horizon, inset: (y: 0.8em))[CreateInput, ExecuteInput],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectOutput, execution status],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[StateUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý project state trong Redis (initialization, retrieval)],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectID, state updates],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectState, completion status],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebhookUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Transform progress callbacks → Redis Pub/Sub messages],
    table.cell(align: horizon, inset: (y: 0.8em))[ProgressCallbackRequest],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis Pub/Sub publish],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9 Pub/Sub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQProducer],
    table.cell(align: horizon, inset: (y: 0.8em))[Publish "project.created" events đến RabbitMQ],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectCreatedEvent],
    table.cell(align: horizon, inset: (y: 0.8em))[RabbitMQ message published],
    table.cell(align: center + horizon, inset: (y: 0.8em))[amqp091-go],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectRepository],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL data access layer cho projects],
    table.cell(align: horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: horizon, inset: (y: 0.8em))[Project entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQLBoiler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[StateRepository],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis data access layer cho project state],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis commands],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9],
  )
]

==== Data Flow

Luồng xử lý chính của Project Service được chia thành 3 flows: Project Creation, Project Execution, và Progress Callback Handling.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới (UC-01):

#context (
  align(center)[
    #image("../images/data-flow/project_create.png", width: 100%)
  ]
)
_Phác họa luồng Project Creation Flow (UC-01)_

Tổng thời gian: ~40ms. Không có Redis state initialization, không có RabbitMQ event publishing.

===== b. Project Execution Flow

Luồng này được kích hoạt khi user execute project (UC-03):

#context (
  align(center)[
    #image("../images/data-flow/execute_project.png", width: 100%)
  ]
)
_Phác họa luồng Project Execution Flow (UC-03)_

Tổng thời gian: ~100ms. Rollback logic: Nếu RabbitMQ publish fails, rollback PostgreSQL status và Redis state.

===== c. Progress Callback Flow

Luồng này xử lý progress callbacks từ Collector Service:

#context (
  align(center)[
    #image("../images/data-flow/webhook_callback.png", width: 100%)
  ]
)
_Phác họa luồng Progress Callback Flow_

Tổng thời gian: ~70ms (bao gồm Redis publish), WebSocket delivery thêm ~50ms.


Tổng thời gian: ~70ms (bao gồm Redis publish), WebSocket delivery thêm ~50ms.

==== Design Patterns Applied

Project Service áp dụng các design patterns sau:

a. Clean Architecture (Kiến trúc sạch):

- Where: Toàn bộ service structure (4 layers: Delivery → UseCase → Domain → Infrastructure).
- Implementation: Dependency inversion (UseCase depends on interfaces, không phụ thuộc concrete implementations).
- Benefit: Testability cao, maintainability tốt, và dễ thay đổi infrastructure (ví dụ: switch từ PostgreSQL sang MongoDB).

b. Repository Pattern (Mẫu Kho lưu trữ):

- Where: ProjectRepository (PostgreSQL), StateRepository (Redis).
- Implementation: Abstract data access qua interfaces, business logic không phụ thuộc vào database cụ thể.
- Benefit: Dễ test (mock repository), và có thể thay đổi storage backend mà không ảnh hưởng use cases.

c. Event-Driven Architecture (Kiến trúc hướng sự kiện):

- Where: RabbitMQProducer publish `project.created` events.
- Implementation: Project Service publish events, Collector Service consume events.
- Benefit: Decoupling giữa services, async processing, và resilience (events được persist trong queue).

d. Distributed State Management (Quản lý trạng thái phân tán):

- Where: StateUseCase quản lý project state trong Redis.
- Implementation: Redis HASH với key `smap:proj:{projectID}`, TTL 24 hours.
- Benefit: Single Source of Truth (SSOT) cho project progress, real-time updates qua Redis Pub/Sub.

e. Explicit Execution Pattern (Mẫu Thực thi rõ ràng):

- Where: Project được tạo với status="draft", chỉ execute khi user explicitly call Execute().
- Implementation: Tách biệt "configuration" (Create) và "execution" (Execute).
- Benefit: User có thể review và edit configuration trước khi execute, tránh lãng phí resources.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Project Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.23fr, 0.23fr, 0.24fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[Project Creation Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~40ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: horizon, inset: (y: 0.8em))[AC-3 target exceeded],
    table.cell(align: horizon, inset: (y: 0.8em))[Project Execution Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Includes Redis + RabbitMQ],
    table.cell(align: horizon, inset: (y: 0.8em))[Progress Callback Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~70ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis Pub/Sub publish],
    table.cell(align: horizon, inset: (y: 0.8em))[Concurrent Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100+ projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[50+ projects],
    table.cell(align: horizon, inset: (y: 0.8em))[Tested in production],
  )
]

==== Key Decisions

a. Draft Status Pattern (Mẫu Trạng thái Draft):

- Decision: Project được tạo với status="draft", không kích hoạt bất kỳ processing nào.
- Rationale: Cho phép user review và edit configuration trước khi execute, tránh lãng phí resources (API calls, compute).
- Evidence: `Create()` function chỉ lưu vào PostgreSQL, không có Redis state initialization, không có RabbitMQ event publishing.

b. Explicit Execution (Thực thi rõ ràng):

- Decision: Tách biệt "configuration" (Create) và "execution" (Execute) thành 2 operations riêng biệt.
- Rationale: User có thể tạo nhiều projects và execute sau, hoặc edit configuration trước khi execute.
- Evidence: `Execute()` function mới khởi tạo Redis state và publish RabbitMQ event.

c. Duplicate Execution Prevention (Ngăn chặn thực thi trùng lặp):

- Decision: Check Redis state trước khi execute, return error nếu project đang executing.
- Rationale: Tránh duplicate processing, waste resources, và inconsistent state.
- Evidence: `Execute()` function check `GetProjectState()` trước khi init state.

d. Rollback Logic (Logic hoàn tác):

- Decision: Nếu RabbitMQ publish fails sau khi đã update PostgreSQL và init Redis, rollback cả hai.
- Rationale: Đảm bảo consistency: nếu event không được publish, state không được init.
- Evidence: Error handling trong `Execute()` function với rollback logic.

e. Two-Phase Progress Format (Định dạng tiến độ hai pha):

- Decision: Support cả old flat format và new phase-based format (Crawl + Analyze phases).
- Rationale: Backward compatibility với legacy callbacks, đồng thời support new format cho detailed progress.
- Evidence: `HandleProgressCallback()` detect format và transform accordingly.

==== Dependencies

Internal Dependencies:

- StateUseCase: Cần thiết để quản lý project state trong Redis.
- RabbitMQProducer: Cần thiết để publish `project.created` events.
- SamplingUseCase: Cần thiết cho dry-run functionality.

External Dependencies:

- PostgreSQL: Project metadata persistence (`projects` table với JSONB columns cho keywords).
- Redis: State management (key: `smap:proj:{projectID}`, TTL: 24 hours), Pub/Sub (topic: `project:{projectID}:{userID}`).
- RabbitMQ: Event publishing (exchange: `smap.events`, routing key: `project.created`).
- Identity Service: User authentication (JWT validation qua middleware).

==== Summary

Project Service là service quản lý vòng đời của projects trong hệ thống SMAP:

a. Component Structure: 4 layers (Delivery → UseCase → Domain → Infrastructure) theo Clean Architecture, với 4 UseCases chính: Project, State, Webhook, Sampling.

b. Design Patterns: Clean Architecture, Repository Pattern, Event-Driven Architecture, Distributed State Management, và Explicit Execution Pattern.

c. Performance: Đạt và vượt các targets từ AC-3 (< 40ms creation, < 100ms execution, < 70ms callback), với high concurrency (100+ projects).

d. Key Features: Draft status pattern, Explicit execution, Duplicate execution prevention, Rollback logic, và Two-phase progress format.

e. Traceability: Đáp ứng FR-1 (Cấu hình Project), FR-2 (Thực thi & Giám sát Project), UC-01 (Cấu hình Project), UC-03 (Execution), và AC-3 (Performance: < 500ms API p95).

=== 5.3.4 Identity Service - Component Diagram

Identity Service là service quản lý authentication và authorization trong hệ thống SMAP, cung cấp JWT-based authentication, role-based access control, và user management. Service này đóng vai trò Utility service trong kiến trúc tổng thể, được sử dụng bởi tất cả các services khác để verify user identity và permissions.

Vai trò của Identity Service trong kiến trúc tổng thể:

- Authentication Provider: Cung cấp login, registration, và JWT token generation.
- Authorization Provider: Role-based access control (USER, ADMIN) và permission checking.
- User Management: CRUD operations cho user accounts và profiles.
- Session Management: HttpOnly cookie-based session management với refresh tokens.

Service này đáp ứng các NFRs về Security (Authentication & Authorization) và liên quan đến tất cả Use Cases (user phải authenticated để sử dụng hệ thống).

==== Component Diagram (C4 Level 3)

Identity Service được tổ chức theo Clean Architecture với 4 layers chính:

#context (
  align(center)[
    #image("../images/component/identity-component-diagram.png", width: 100%)
  ]
)
#context (
  align(
    center,
  )[_Hình #image_counter.display(): Biểu đồ thành phần (Component Diagram) của Identity Service (Clean Architecture 4 layers)_]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Identity Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AuthHandler],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP request handlers cho authentication operations],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP requests (POST)],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin framework],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AuthMiddleware],
    table.cell(align: horizon, inset: (y: 0.8em))[JWT validation từ HttpOnly cookie, set scope trong context],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP request với cookie],
    table.cell(align: horizon, inset: (y: 0.8em))[Context với scope],
    table.cell(align: center + horizon, inset: (y: 0.8em))[golang-jwt/jwt],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AuthenticationUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Business logic cho authentication: login, register, OTP verification],
    table.cell(align: horizon, inset: (y: 0.8em))[LoginInput, RegisterInput],
    table.cell(align: horizon, inset: (y: 0.8em))[LoginOutput với JWT token],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UserUseCase],
    table.cell(align: horizon, inset: (y: 0.8em))[Business logic cho user management: CRUD, password change],
    table.cell(align: horizon, inset: (y: 0.8em))[CreateInput, UpdateInput],
    table.cell(align: horizon, inset: (y: 0.8em))[UserOutput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PasswordEncrypter],
    table.cell(align: horizon, inset: (y: 0.8em))[Password hashing và verification (bcrypt cost 10)],
    table.cell(align: horizon, inset: (y: 0.8em))[Plain password],
    table.cell(align: horizon, inset: (y: 0.8em))[Hashed password],
    table.cell(align: center + horizon, inset: (y: 0.8em))[golang.org/x/crypto/bcrypt],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWTManager],
    table.cell(align: horizon, inset: (y: 0.8em))[JWT token generation và validation],
    table.cell(align: horizon, inset: (y: 0.8em))[User claims (userID, role)],
    table.cell(align: horizon, inset: (y: 0.8em))[JWT token string],
    table.cell(align: center + horizon, inset: (y: 0.8em))[golang-jwt/jwt],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UserRepository],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL data access layer cho users],
    table.cell(align: horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: horizon, inset: (y: 0.8em))[User entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQLBoiler],
  )
]

==== Data Flow

Luồng xử lý chính của Identity Service được chia thành 3 flows: User Registration, User Login, và JWT Validation.

===== a. User Registration Flow

Luồng này được kích hoạt khi user đăng ký tài khoản mới:

#context (
  align(center)[
    #image("../images/data-flow/user_registration_flow.png", width: 80%)
  ]
)
_Phác họa luồng User Registration Flow_

Tổng thời gian: ~80ms. User phải verify email (OTP) trước khi có thể login.

===== b. User Login Flow

Luồng này được kích hoạt khi user đăng nhập:

#context (
  align(center)[
    #image("../images/data-flow/user_login.png", width: 80%)
  ]
)
_Phác họa luồng User Login Flow_

Tổng thời gian: ~45ms. JWT token được set trong HttpOnly cookie để bảo mật.

===== c. JWT Validation Flow (Middleware)

Luồng này được kích hoạt cho mỗi authenticated request:

#context (
  align(center)[
    #image("../images/data-flow/auth_middleware.png", width: 80%)
  ]
)
_Phác họa luồng JWT Validation (Auth Middleware)_

Tổng thời gian: ~10ms per request. Đạt target < 10ms từ AC-3.


Tổng thời gian: ~10ms per request. Đạt target < 10ms từ AC-3.

==== Design Patterns Applied

Identity Service áp dụng các design patterns sau:

a. Clean Architecture (Kiến trúc sạch):

- Where: Toàn bộ service structure (4 layers: Delivery → UseCase → Domain → Infrastructure).
- Implementation: Dependency inversion (UseCase depends on interfaces, không phụ thuộc concrete implementations).
- Benefit: Testability cao, maintainability tốt, và dễ thay đổi infrastructure.

b. Repository Pattern (Mẫu Kho lưu trữ):

- Where: UserRepository (PostgreSQL).
- Implementation: Abstract data access qua interfaces, business logic không phụ thuộc vào database cụ thể.
- Benefit: Dễ test (mock repository), và có thể thay đổi storage backend mà không ảnh hưởng use cases.

c. Strategy Pattern (Mẫu Chiến lược):

- Where: PasswordEncrypter có thể switch hashing algorithm (hiện tại bcrypt, có thể thay bằng argon2).
- Implementation: Encrypter interface với HashPassword() và CheckPasswordHash() methods.
- Benefit: Dễ thay đổi password hashing algorithm mà không ảnh hưởng authentication logic.

d. HttpOnly Cookie Pattern (Mẫu Cookie HttpOnly):

- Where: JWT token được set trong HttpOnly cookie thay vì localStorage hoặc Authorization header.
- Implementation: Cookie với HttpOnly=true, Secure=true, SameSite=Lax.
- Benefit: Bảo vệ khỏi XSS attacks (JavaScript không thể access cookie), và CSRF protection (SameSite=Lax).

e. Role-Based Access Control (RBAC):

- Where: User model có Role field (USER, ADMIN), JWT token chứa role claim.
- Implementation: Middleware check role từ JWT payload, enforce permissions.
- Benefit: Fine-grained access control, và dễ mở rộng roles mới.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Identity Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.28fr, 0.22fr, 0.20fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[Auth Check Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~10ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10ms],
    table.cell(align: horizon, inset: (y: 0.8em))[JWT verification, AC-3],
    table.cell(align: horizon, inset: (y: 0.8em))[Login Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~45ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: horizon, inset: (y: 0.8em))[AC-3 target exceeded],
    table.cell(align: horizon, inset: (y: 0.8em))[Registration Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~80ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Includes password hashing],
    table.cell(align: horizon, inset: (y: 0.8em))[Password Hashing Time],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~50ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: horizon, inset: (y: 0.8em))[bcrypt cost 10],
  )
]

==== Key Decisions

a. Bcrypt với DefaultCost (Bcrypt với chi phí mặc định):

- Decision: Sử dụng bcrypt với DefaultCost (cost 10) cho password hashing.
- Rationale: Balance giữa security và performance. Cost 10 đủ mạnh để resist brute-force attacks, nhưng không quá chậm (~50ms).
- Evidence: `HashPassword()` function sử dụng `bcrypt.DefaultCost` (cost 10), minimum 8 characters validation.

b. HttpOnly Cookie cho JWT (Cookie HttpOnly cho JWT):

- Decision: Set JWT token trong HttpOnly cookie thay vì localStorage hoặc Authorization header.
- Rationale: Bảo vệ khỏi XSS attacks (JavaScript không thể access cookie), và CSRF protection với SameSite=Lax.
- Evidence: Cookie configuration trong middleware với HttpOnly=true, Secure=true, SameSite=Lax.

c. OTP-based Email Verification (Xác thực email qua OTP):

- Decision: Sử dụng OTP (One-Time Password) cho email verification thay vì magic links.
- Rationale: OTP đơn giản hơn, không cần email template phức tạp, và user experience tốt hơn (copy-paste OTP).
- Evidence: `SendOTP()` và `VerifyOTP()` functions với OTP generation và expiration logic.

d. Async Email Sending (Gửi email bất đồng bộ):

- Decision: Publish email events đến RabbitMQ thay vì gửi email trực tiếp trong request handler.
- Rationale: Không block request handler, improve response time, và resilience (email events được persist trong queue).
- Evidence: RabbitMQProducer publish email events, Consumer Service process emails async.

e. Role-Based Access Control (RBAC):

- Decision: JWT token chứa role claim (USER, ADMIN), middleware enforce permissions dựa trên role.
- Rationale: Fine-grained access control, và dễ mở rộng roles mới (ví dụ: MODERATOR, ANALYST).
- Evidence: JWT payload structure với Role field, AdminMiddleware check role từ scope.

==== Dependencies

Internal Dependencies:

- UserUseCase: Cần thiết để quản lý user accounts và profiles.
- PasswordEncrypter: Cần thiết để hash và verify passwords.
- JWTManager: Cần thiết để generate và validate JWT tokens.
- RabbitMQProducer: Cần thiết để publish email events.

External Dependencies:

- PostgreSQL: User data persistence (`users` table với password hash, OTP, roles).
- RabbitMQ: Email event publishing (async email sending via Consumer Service).
- Consumer Service: Process email events (OTP sending via SMTP).

==== Summary

Identity Service là service quản lý authentication và authorization trong hệ thống SMAP:

a. Component Structure: 4 layers (Delivery → UseCase → Domain → Infrastructure) theo Clean Architecture, với 2 UseCases chính: Authentication và User.

b. Design Patterns: Clean Architecture, Repository Pattern, Strategy Pattern, HttpOnly Cookie Pattern, và Role-Based Access Control (RBAC).

c. Performance: Đạt và vượt các targets từ AC-3 (< 10ms auth check, < 45ms login, < 80ms registration), với high security (bcrypt cost 10, HttpOnly cookies).

d. Key Features: Bcrypt password hashing (cost 10, min 8 chars), HttpOnly cookie-based JWT, OTP email verification, Async email sending, và RBAC (USER, ADMIN roles).

e. Traceability: Đáp ứng Security NFRs (Authentication & Authorization), AC-3 (Performance: < 10ms auth check), và tất cả Use Cases (user phải authenticated).

=== 5.3.5 WebSocket Service - Component Diagram

WebSocket Service là service cung cấp real-time communication giữa hệ thống và clients (Web UI), cho phép push progress updates, notifications, và system status đến users mà không cần polling. Service này consume messages từ Redis Pub/Sub và deliver đến WebSocket clients.

Vai trò của WebSocket Service trong kiến trúc tổng thể:

- Real-time Communication Hub: Cung cấp WebSocket connections cho clients.
- Message Router: Route messages từ Redis Pub/Sub topics đến đúng WebSocket connections.
- Connection Manager: Quản lý lifecycle của WebSocket connections (connect, disconnect, heartbeat).
- Progress Delivery: Deliver progress updates từ Collector Service đến Web UI clients.

Service này đáp ứng FR-2 (Real-time progress tracking) và liên quan trực tiếp đến UC-06 (Progress updates).

==== Component Diagram (C4 Level 3)

WebSocket Service được tổ chức theo Clean Architecture với 3 layers chính:

#context (
  align(center)[
    #image("../images/component/websocket-component-diagram.png", width: 100%)
  ]
)
#context (
  align(
    center,
  )[_Hình #image_counter.display(): Biểu đồ thành phần (Component Diagram) của WebSocket Service (Clean Architecture 3 layers)_]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocketHandler],
    table.cell(align: horizon, inset: (y: 0.8em))[Handle WebSocket connections, upgrade HTTP → WebSocket],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP upgrade request],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[gorilla/websocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ConnectionManager],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý WebSocket connections với topic mapping],
    table.cell(align: horizon, inset: (y: 0.8em))[Connection, topic],
    table.cell(align: horizon, inset: (y: 0.8em))[Connection registry],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MessageHandler],
    table.cell(align: horizon, inset: (y: 0.8em))[Route messages từ Redis Pub/Sub → WebSocket connections],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis Pub/Sub messages],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RedisPubSubClient],
    table.cell(align: horizon, inset: (y: 0.8em))[Subscribe to Redis topics, receive messages],
    table.cell(align: horizon, inset: (y: 0.8em))[Topic pattern],
    table.cell(align: horizon, inset: (y: 0.8em))[Messages từ Redis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[go-redis/v9 Pub/Sub],
  )
]

==== Data Flow

Luồng xử lý chính của WebSocket Service được chia thành 2 flows: Connection Establishment và Message Delivery.

===== a. Connection Establishment Flow

Luồng này được kích hoạt khi client connect WebSocket:

#context (
  align(center)[
    #image("../images/data-flow/webSocket_connection.png", width: 100%)
    center[_Hình #image_counter.display(): Connection Establishment Flow của WebSocket Service_]
  ]
)
#image_counter.step()

Tổng thời gian: ~16ms. Connection được maintain cho đến khi client disconnect.

===== b. Message Delivery Flow

#context (
  align(center)[
    #image("../images/data-flow/real-time.png", width: 100%)
    center[_Hình #image_counter.display(): Message Delivery Flow của WebSocket Service_]
  ]
)
#image_counter.step()

Tổng thời gian: ~60ms per message (bao gồm Redis receive + WebSocket delivery). Đạt target < 100ms từ AC-3.


Tổng thời gian: ~60ms per message (bao gồm Redis receive + WebSocket delivery). Đạt target < 100ms từ AC-3.

==== Design Patterns Applied

WebSocket Service áp dụng các design patterns sau:

a. Observer Pattern (Mẫu Quan sát):

- Where: Redis Pub/Sub subscribe to topics, receive messages khi có updates.
- Implementation: Service subscribe to Redis topics, receive messages async, và route đến WebSocket connections.
- Benefit: Decoupling giữa publishers (Project Service) và subscribers (WebSocket Service), và scalability (multiple WebSocket instances có thể subscribe cùng topic).

b. Connection Pooling (Nhóm kết nối):

- Where: ConnectionManager quản lý multiple WebSocket connections.
- Implementation: In-memory registry của connections với topic mapping, efficient lookup và broadcast.
- Benefit: Efficient resource utilization, và dễ scale (1,000+ concurrent connections).

c. Graceful Shutdown (Tắt máy nhẹ nhàng):

- Where: Service shutdown logic.
- Implementation: Close WebSocket connections gracefully, unsubscribe từ Redis topics, và wait for in-flight messages.
- Benefit: Không mất messages trong quá trình shutdown, và clean resource cleanup.

d. Health Check Pattern (Mẫu Kiểm tra sức khỏe):

- Where: Shallow và Deep health checks.
- Implementation: Shallow check (HTTP server + Redis connection), Deep check (Pub/Sub working, message delivery).
- Benefit: Kubernetes liveness/readiness probes, và observability.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.25fr, 0.20fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket Latency (p95)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~60ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis Pub/Sub + WebSocket, AC-3],
    table.cell(align: horizon, inset: (y: 0.8em))[Connection Establishment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~16ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 50ms],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP upgrade + Redis subscribe],
    table.cell(align: horizon, inset: (y: 0.8em))[Concurrent Connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1,000+],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1,000+],
    table.cell(align: horizon, inset: (y: 0.8em))[AC-2 target met],
    table.cell(align: horizon, inset: (y: 0.8em))[Message Throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[10,000+ msg/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5,000+ msg/min],
    table.cell(align: horizon, inset: (y: 0.8em))[Tested in production],
  )
]

==== Key Decisions

a. Redis Pub/Sub cho Message Routing (Pub/Sub Redis cho định tuyến tin nhắn):

- Decision: Sử dụng Redis Pub/Sub thay vì direct WebSocket-to-WebSocket communication.
- Rationale: Decoupling giữa publishers (Project Service) và WebSocket Service, scalability (multiple WebSocket instances), và resilience (messages được persist trong Redis).
- Evidence: Topic pattern `project:{projectID}:{userID}`, Redis Pub/Sub subscribe trong MessageHandler.

b. Topic-Based Routing (Định tuyến dựa trên chủ đề):

- Decision: Sử dụng topic pattern `project:{projectID}:{userID}` để route messages đến đúng connections.
- Rationale: Mỗi user chỉ nhận messages cho projects của họ, và efficient filtering (Redis Pub/Sub pattern matching).
- Evidence: ConnectionManager map connections to topics, MessageHandler route based on topic.

c. Connection Registry (Sổ đăng ký kết nối):

- Decision: In-memory registry của WebSocket connections với topic mapping.
- Rationale: Fast lookup (O(1) per connection), và efficient broadcast (iterate connections per topic).
- Evidence: ConnectionManager với map[connection]topic và map[topic][]connection structures.

d. Graceful Shutdown (Tắt máy nhẹ nhàng):

- Decision: Close connections gracefully, unsubscribe từ Redis, và wait for in-flight messages.
- Rationale: Không mất messages trong quá trình shutdown, và clean resource cleanup.
- Evidence: Shutdown logic trong server với context cancellation và connection cleanup.

==== Dependencies

Internal Dependencies:

- ConnectionManager: Cần thiết để quản lý WebSocket connections.
- MessageHandler: Cần thiết để route messages từ Redis Pub/Sub đến WebSocket connections.

External Dependencies:

- Redis Pub/Sub: Message consumption (topics: `project:{projectID}:{userID}`).
- Project Service: Publish messages to Redis Pub/Sub (progress callbacks).
- Web UI: WebSocket clients connect và receive messages.

==== Summary

WebSocket Service là service cung cấp real-time communication trong hệ thống SMAP:

a. Component Structure: 3 layers (Delivery → UseCase → Infrastructure) theo Clean Architecture, với 2 main components: ConnectionManager và MessageHandler.

b. Design Patterns: Observer Pattern, Connection Pooling, Graceful Shutdown, và Health Check Pattern.

c. Performance: Đạt và vượt các targets từ AC-3 (< 60ms WebSocket latency, < 16ms connection establishment), với high concurrency (1,000+ connections).

d. Key Features: Redis Pub/Sub integration, Topic-based routing, Connection registry, và Graceful shutdown.

e. Traceability: Đáp ứng FR-2 (Real-time progress tracking), UC-06 (Progress updates), AC-2 (Scalability: 1,000+ concurrent connections), và AC-3 (Performance: < 100ms WebSocket p95).

=== 5.3.6 Speech2Text Service - Component Diagram

Speech2Text Service là service chuyển đổi audio/video content sang text transcript sử dụng Whisper model (OpenAI). Service này consume audio files từ MinIO, chạy Whisper inference, và persist transcripts vào database hoặc publish events.

Vai trò của Speech2Text Service trong kiến trúc tổng thể:

- Audio Transcription Provider: Chuyển đổi audio/video sang text transcript.
- Whisper Model Integration: Sử dụng Whisper ONNX model cho Vietnamese và English transcription.
- Media Processing: Download audio từ MinIO, process với Whisper, và store results.

Service này hỗ trợ FR-2 (Video analysis) và liên quan đến UC-03 (Analytics Pipeline - transcription step).

==== Component Diagram (C4 Level 3)

Speech2Text Service được tổ chức theo Clean Architecture với 4 layers chính:

#context (
  align(center)[
    #image("../images/component/speech2text-component-diagram.png", width: 90%)
  ]
)
#context (
  align(
    center,
  )[_Hình #image_counter.display(): Component Diagram của Speech2Text Service_]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Speech2Text Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TranscriptionHandler],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP request handlers cho transcription operations],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP POST /transcribe],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TranscriptionUseCase],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Business logic cho transcription: download audio, run Whisper, return transcript],
    table.cell(align: horizon, inset: (y: 0.8em))[Audio file path (MinIO)],
    table.cell(align: horizon, inset: (y: 0.8em))[TranscriptionResult (text, language, segments)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Python logic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WhisperTranscriber],
    table.cell(align: horizon, inset: (y: 0.8em))[Run Whisper ONNX inference để transcribe audio],
    table.cell(align: horizon, inset: (y: 0.8em))[Audio file (WAV, MP3)],
    table.cell(align: horizon, inset: (y: 0.8em))[Transcript text với timestamps],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Whisper ONNX, PyTorch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIOAdapter],
    table.cell(align: horizon, inset: (y: 0.8em))[Download audio files từ MinIO object storage],
    table.cell(align: horizon, inset: (y: 0.8em))[MinIO object key],
    table.cell(align: horizon, inset: (y: 0.8em))[Audio file (local temp file)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[boto3 (S3 client)],
  )
]

==== Data Flow

Luồng xử lý chính của Speech2Text Service:

#context (
  align(center)[
    #image("../images/data-flow/transcript.png", width: 90%)
    center[_Hình #image_counter.display(): Data Flow của Speech2Text Service_]
  ]
)
#image_counter.step()

Tổng thời gian: ~5-15s cho 1-minute audio (bao gồm download và inference).

==== Design Patterns Applied

Speech2Text Service áp dụng các design patterns sau:

a. Port and Adapter Pattern (Mẫu Port và Adapter):

- Where: ITranscriber interface định nghĩa contract, WhisperTranscriber là concrete implementation.
- Implementation: UseCase depends on ITranscriber interface, không phụ thuộc Whisper cụ thể.
- Benefit: Dễ test (mock transcriber), và có thể switch model (ví dụ: từ Whisper sang Wav2Vec) mà không thay đổi use case.

b. Clean Architecture (Kiến trúc sạch):

- Where: Toàn bộ service structure (4 layers: Delivery → UseCase → Domain → Infrastructure).
- Implementation: Dependency inversion (UseCase depends on interfaces).
- Benefit: Testability cao, maintainability tốt.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Speech2Text Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.28fr, 0.24fr, 0.24fr, 0.24fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[Transcription Latency (1-min audio)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~5-15s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 20s],
    table.cell(align: horizon, inset: (y: 0.8em))[Includes download + inference],
    table.cell(align: horizon, inset: (y: 0.8em))[Whisper Inference Time],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~1s/min audio],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: horizon, inset: (y: 0.8em))[ONNX optimized],
    table.cell(align: horizon, inset: (y: 0.8em))[Memory Usage],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~2GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 4GB],
    table.cell(align: horizon, inset: (y: 0.8em))[Whisper model + audio buffer],
  )
]

==== Key Decisions

a. Whisper ONNX Model (Mô hình Whisper ONNX):

- Decision: Sử dụng Whisper ONNX quantized model thay vì PyTorch native model.
- Rationale: ONNX runtime nhanh hơn ~20% trên CPU, memory footprint nhỏ hơn ~15%, và dễ deploy.
- Evidence: Model size ~1GB (quantized), inference time ~1s per minute of audio.

b. Port and Adapter Pattern (Mẫu Port và Adapter):

- Decision: ITranscriber interface định nghĩa contract, WhisperTranscriber là implementation.
- Rationale: Dễ test (mock transcriber), và có thể switch model mà không thay đổi use case.
- Evidence: `interfaces/transcriber.py` với `ITranscriber` interface, `infrastructure/whisper/` với implementation.

==== Dependencies

Internal Dependencies:

- TranscriptionUseCase: Cần thiết để orchestrate transcription flow.
- WhisperTranscriber: Cần thiết để run Whisper inference.

External Dependencies:

- MinIO: Audio file storage (download audio files).
- Whisper Model: ONNX quantized model (~1GB, downloaded từ MinIO, cached locally).

==== Summary

Speech2Text Service là service chuyển đổi audio/video sang text transcript:

a. Component Structure: 4 layers (Delivery → UseCase → Domain → Infrastructure) theo Clean Architecture, với Port and Adapter Pattern cho transcriber.

b. Design Patterns: Port and Adapter Pattern, Clean Architecture.

c. Performance: Đạt target < 20s cho 1-minute audio transcription, với ONNX optimization (~1s per minute inference time).

d. Key Features: Whisper ONNX model integration, MinIO audio download, và Port and Adapter Pattern cho flexibility.

e. Traceability: Hỗ trợ FR-2 (Video analysis), UC-03 (Analytics Pipeline - transcription), và AC-3 (Performance: < 20s transcription).

=== 5.3.7 Web UI - Component Diagram

Web UI là frontend application được xây dựng với Next.js 15, cung cấp dashboard quản trị, project management interface, và real-time progress visualization. Service này tương tác với tất cả backend services qua REST APIs và WebSocket connections.

Vai trò của Web UI trong kiến trúc tổng thể:

- User Interface: Cung cấp UI cho tất cả Use Cases (UC-01 đến UC-08).
- Real-time Visualization: Hiển thị progress updates qua WebSocket connections.
- API Client: Gọi REST APIs từ các backend services (Identity, Project, Analytics).
- State Management: Quản lý client-side state với Zustand hoặc React Context.

Service này đáp ứng tất cả Use Cases từ phía user interface và liên quan đến NFRs về Usability (UX requirements).

==== Component Diagram (C4 Level 3)

Web UI được tổ chức theo Component-based Architecture với Next.js App Router:
#context (
  align(center)[
    #image("../images/component/webui-component-diagram.png", width: 100%)
    center[_Hình #image_counter.display(): Component Diagram Web UI (Next.js 15 + React 19). Kiến trúc ba lớp (Presentation, Application, Infrastructure), các package chính và integration với backend qua REST API & WebSocket._]
  ]
)
#image_counter.step()

==== Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Web UI_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectWizard],
    table.cell(align: horizon, inset: (y: 0.8em))[Multi-step form để tạo project (UC-01)],
    table.cell(align: horizon, inset: (y: 0.8em))[User input (form data)],
    table.cell(align: horizon, inset: (y: 0.8em))[POST /projects API call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React components],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProgressTracker],
    table.cell(align: horizon, inset: (y: 0.8em))[Real-time progress visualization (UC-06)],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: horizon, inset: (y: 0.8em))[UI updates (progress bars, charts)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React + WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[useWebSocket Hook],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket connection management với auto-reconnect],
    table.cell(align: horizon, inset: (y: 0.8em))[ProjectID, UserID],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket connection, messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React hooks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API Clients],
    table.cell(align: horizon, inset: (y: 0.8em))[REST API calls đến backend services],
    table.cell(align: horizon, inset: (y: 0.8em))[API requests],
    table.cell(align: horizon, inset: (y: 0.8em))[API responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Axios/Fetch],
  )
]

==== Data Flow

Luồng xử lý chính của Web UI được chia thành 2 flows: Project Creation và Real-time Progress Updates.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới (UC-01):

#context (
  align(center)[
    #image("../images/data-flow/authen.png", width: 90%)
    center[_Hình: Luồng Project Creation Flow (Authentication, Project Creation)_]
  ]
)
Tổng thời gian: ~45ms (bao gồm API call và state update).

===== b. Real-time Progress Updates Flow

Luồng này được kích hoạt khi project đang executing (UC-06):

#context (
  align(center)[
    #image("../images/data-flow/Progress.png", width: 90%)
    center[_Hình: Luồng Real-time Progress Updates Flow_]
  ]
)


Tổng thời gian: ~77ms per progress update (bao gồm Redis + WebSocket + React update).

==== Design Patterns Applied

Web UI áp dụng các design patterns sau:

a. Component-based Architecture (Kiến trúc dựa trên component):

- Where: React components (ProjectWizard, ProgressTracker, Dashboard).
- Implementation: Mỗi component là một reusable unit với props và state.
- Benefit: Reusability cao, maintainability tốt, và dễ test.

b. Custom Hooks Pattern (Mẫu Hook tùy chỉnh):

- Where: useWebSocket(), useProjectProgress(), useAuth().
- Implementation: Encapsulate logic trong custom hooks, components consume hooks.
- Benefit: Logic reuse, separation of concerns, và dễ test.

c. Context API Pattern (Mẫu Context API):

- Where: AuthContext, ProjectContext.
- Implementation: React Context để share state across components.
- Benefit: Avoid prop drilling, và centralized state management.

d. Server-Side Rendering (SSR):

- Where: Next.js App Router với Server Components.
- Implementation: Pages được render trên server, send HTML to client.
- Benefit: SEO tốt hơn, initial load nhanh hơn, và better performance.

==== Performance Characteristics

#context (align(center)[_Bảng #table_counter.display(): Performance Metrics - Web UI_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.23fr, 0.23fr, 0.24fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Value*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],
    table.cell(align: horizon, inset: (y: 0.8em))[Dashboard Loading],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~2.1s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 3s],
    table.cell(align: horizon, inset: (y: 0.8em))[NFR-UX-1 target met],
    table.cell(align: horizon, inset: (y: 0.8em))[Initial Load (FCP)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~1.5s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 2s],
    table.cell(align: horizon, inset: (y: 0.8em))[SSR + Server Components],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket Update Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[~77ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis + WebSocket + React],
  )
]

==== Key Decisions

a. Next.js 15 với App Router (Next.js 15 với App Router):

- Decision: Sử dụng Next.js 15 App Router thay vì Pages Router.
- Rationale: Server Components cho better performance, và modern React features (Suspense, Server Actions).
- Evidence: App Router structure với `app/` directory, Server Components cho static content.

b. TypeScript cho Type Safety (TypeScript cho an toàn kiểu):

- Decision: Sử dụng TypeScript thay vì JavaScript.
- Rationale: Type safety giảm runtime errors, better IDE support, và maintainability tốt hơn.
- Evidence: `tsconfig.json` với strict mode, type definitions cho API clients.

c. Tailwind CSS cho Styling (Tailwind CSS cho định kiểu):

- Decision: Sử dụng Tailwind CSS thay vì CSS-in-JS hoặc CSS modules.
- Rationale: Utility-first approach cho fast development, small bundle size (tree-shaking), và design system consistency.
- Evidence: `tailwind.config.js` với custom theme, utility classes trong components.

d. WebSocket với Auto-reconnect (WebSocket với tự động kết nối lại):

- Decision: Custom useWebSocket hook với auto-reconnect logic.
- Rationale: Resilience khi connection drops, và better user experience (seamless reconnection).
- Evidence: useWebSocket hook với exponential backoff retry logic.

==== Dependencies

Internal Dependencies:

- API Clients: Cần thiết để gọi REST APIs từ backend services.
- Custom Hooks: Cần thiết để manage WebSocket connections và state.
- Context Providers: Cần thiết để share state across components.

External Dependencies:

- Identity Service: Authentication APIs (login, register, verify OTP).
- Project Service: Project CRUD APIs, execution APIs, progress APIs.
- Analytics Service: Analytics data APIs, report generation APIs.
- WebSocket Service: Real-time progress updates.

==== Summary

Web UI là frontend application cung cấp user interface cho hệ thống SMAP:

a. Component Structure: Component-based Architecture với Next.js App Router, React components, custom hooks, và Context API.

b. Design Patterns: Component-based Architecture, Custom Hooks Pattern, Context API Pattern, và Server-Side Rendering (SSR).

c. Performance: Đạt và vượt các targets từ NFR-UX-1 (< 2.1s dashboard loading, < 1.5s initial load), với real-time updates (< 77ms WebSocket latency).

d. Key Features: Next.js 15 App Router, TypeScript type safety, Tailwind CSS styling, WebSocket với auto-reconnect, và Server Components cho performance.

e. Traceability: Đáp ứng tất cả Use Cases (UC-01 đến UC-08), NFR-UX-1 (Dashboard loading < 3s), NFR-UX-2 (Initial load < 2s), và AC-3 (WebSocket updates < 100ms).
