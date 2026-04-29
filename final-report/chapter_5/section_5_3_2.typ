#import "../counters.typ": image_counter, table_counter

=== 5.3.2 Analytics Service

Analytics Service là dịch vụ chịu trách nhiệm cho analytics pipeline của hệ thống SMAP. Dịch vụ này vận hành như một consumer runtime bất đồng bộ, tiếp nhận dữ liệu đã được chuẩn hóa từ analytics data plane, thực thi các bước xử lý NLP, lưu kết quả phân tích có cấu trúc và phát hành các đầu ra downstream để các lớp khác tiếp tục tiêu thụ.

Vai trò của Analytics Service trong kiến trúc tổng thể:

- Kafka Consumer Runtime: Tiêu thụ dữ liệu đầu vào từ analytics data plane.
- Pipeline Orchestrator: Điều phối các bước normalization, enrichment và NLP processing.
- Result Persister: Lưu các thực thể phân tích có cấu trúc vào persistence layer.
- Downstream Publisher: Phát hành các topic analytics phục vụ knowledge indexing và các lớp tiêu thụ phía sau.

Service này đáp ứng trực tiếp FR-09 về Analytics Processing và liên quan trực tiếp đến UC-05 về Execute Analytics and Build Knowledge.

==== 5.3.2.1 Component Diagram - C4 Level 3

Analytics Service được tổ chức quanh consumer runtime và pipeline processing layer. Ở đây, trọng tâm không nằm ở một HTTP request path truyền thống, mà ở khả năng intake message, thực thi pipeline và phát hành kết quả downstream.

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
    columns: (0.22fr, 0.34fr, 0.22fr, 0.22fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input / Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ConsumerServer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tiếp nhận message từ Kafka, parse dữ liệu và điều phối intake flow],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka message / parsed input bundle],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python async + Kafka consumer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Ingestion Adapter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Chuyển UAP hoặc ingest flat payload sang `IngestedBatchBundle` dùng cho pipeline],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Parsed record / pipeline-ready bundle],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Adapter layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[PipelineUseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Wrapper điều phối `run_pipeline()` với `RunContext` và cấu hình runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Batch bundle / pipeline result],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python usecase layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NLP Pipeline Stages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thực thi các bước normalization, dedup, spam, thread topology và NLP enrichment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MentionRecord / NLPFact / analytics outputs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pipeline modules],

    table.cell(align: center + horizon, inset: (y: 0.8em))[PostInsight UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu các kết quả phân tích có cấu trúc vào PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NLPFact / persisted insight rows],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Persistence layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Contract Publisher],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Phát hành `analytics.*` topics cho downstream consumers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Insight outputs / Kafka topics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka producer],
  )
]

==== 5.3.2.3 Data Flow

Luồng xử lý chính của Analytics Service có thể chia thành hai flow: Kafka intake flow và pipeline execution flow.

===== a. Kafka Intake Flow

Luồng này bắt đầu khi dữ liệu chuẩn hóa được publish vào analytics data plane:

#align(center)[
  #image("../images/data-flow/analytics_ingestion.png", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Kafka intake trong Analytics Service_])
  #image_counter.step()
]

Ở flow này, `ConsumerServer` thực hiện các bước chính sau:

1. nhận Kafka message từ topic đầu vào;
2. decode và parse dữ liệu theo định dạng UAP hoặc ingest flat payload;
3. route domain bằng `domain_type_code` và tạo `RunContext`;
4. chuyển dữ liệu sang `IngestedBatchBundle` để sẵn sàng cho pipeline.

===== b. Pipeline Execution Flow

Sau khi intake hoàn tất, service chuyển sang pipeline execution flow:

#align(center)[
  #image("../images/data-flow/analytics-pipeline.png", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng analytics pipeline trong Analytics Service_])
  #image_counter.step()
]

Ở flow này, pipeline được chạy theo kiểu consumer-based processing:

1. `PipelineUseCase` gọi `run_pipeline()` với `asyncio.to_thread` để tránh block event loop;
2. các stage xử lý tạo ra `NLPFact` và các analytics outputs;
3. kết quả được persist vào PostgreSQL thông qua `post_insight` layer;
4. các contract outputs được publish ra các topic downstream;
5. `knowledge-srv` tiêu thụ các topic này để tiếp tục indexing.

==== 5.3.2.4 Design Patterns áp dụng

Analytics Service áp dụng các design patterns sau:

- Consumer-Based Processing: Dịch vụ vận hành như một consumer runtime tách khỏi request-response path.
- Pipeline Pattern: Các bước xử lý được tổ chức thành một pipeline nhiều stage có thứ tự rõ ràng.
- Thread Offloading Pattern: Phần xử lý nặng được đẩy qua `asyncio.to_thread` để giảm nguy cơ block event loop.
- Port and Adapter Pattern: Intake, persistence và publishing được tách qua các adapter hoặc usecase tương ứng.
- Downstream Contract Publishing: Kết quả phân tích không kết thúc trong service mà được phát hành tiếp cho các lane downstream.

==== 5.3.2.5 Key Decisions

- Chọn Kafka làm đầu vào chính cho analytics data plane thay vì RabbitMQ task queue.
- Tách pipeline processing khỏi HTTP path để phù hợp với workload NLP nặng.
- Giữ `PipelineUseCase` như một wrapper mỏng quanh `run_pipeline()` để đơn giản hóa orchestration layer.
- Persist `post_insight` và publish `analytics.*` outputs như hai trách nhiệm liên tiếp nhưng tách biệt.

==== 5.3.2.6 Dependencies

Internal Dependencies:

- ConsumerRegistry: wiring các dependency runtime cho consumer server.
- PipelineUseCase: điều phối chạy pipeline.
- IngestionUseCase: chuyển dữ liệu intake sang bundle xử lý.
- PostInsight UseCase: lưu kết quả phân tích.
- Contract Publisher: phát hành các topic downstream.

External Dependencies:

- Kafka: analytics data plane đầu vào và các topic downstream đầu ra.
- PostgreSQL: persistence cho các thực thể phân tích.
- Knowledge Service: downstream consumer của các analytics topics.
- Runtime config và domain registry: định tuyến ontology theo `domain_type_code`.
