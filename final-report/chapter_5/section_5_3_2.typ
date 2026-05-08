#import "../counters.typ": image_counter, table_counter

=== 5.3.2 Analytics Service

Analytics Service là dịch vụ chịu trách nhiệm cho analytics pipeline và analytics read API của hệ thống SMAP. Dịch vụ này được triển khai thành hai runtime chính: `analysis-consumer` tiếp nhận dữ liệu đã được chuẩn hóa từ analytics data plane để xử lý bất đồng bộ, còn `analysis-api` cung cấp các endpoint đọc dữ liệu phân tích cho dashboard và giao diện người dùng.

Vai trò của Analytics Service trong kiến trúc tổng thể:

- Analytics API Runtime: Expose các endpoint `/api/v1/analytics/*` cho dashboard, KPI, sentiment, keyword, post và heap view.
- Kafka Consumer Runtime: Tiêu thụ dữ liệu đầu vào từ analytics data plane.
- Pipeline Orchestrator: Điều phối các bước normalization, enrichment và NLP processing.
- Result Persister: Lưu các thực thể phân tích có cấu trúc vào persistence layer.
- Downstream Publisher: Phát hành các topic analytics phục vụ knowledge indexing và các lớp tiêu thụ phía sau.

Service này đáp ứng trực tiếp FR-09 về Analytics Processing. Ở mức use case, service hỗ trợ UC-02 về Vận hành chiến dịch theo dõi ở lane xử lý downstream và cung cấp dữ liệu đầu vào cho UC-03 về Tra cứu và hỏi đáp dữ liệu phân tích.

==== 5.3.2.1 Component Diagram - C4 Level 3

Analytics Service được tổ chức quanh hai bề mặt runtime tách biệt: `analysis-api` phục vụ read path đồng bộ cho giao diện, còn `analysis-consumer` xử lý message bất đồng bộ từ Kafka. Cách tách này giúp dashboard đọc dữ liệu đã persist mà không chặn pipeline NLP hoặc consumer runtime.

#context (
  align(center)[
    #image("../images/chapter_5/c4-analytics-component-diagram.svg", width: 96%)
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

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analysis API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Expose FastAPI endpoint cho dashboard và các hook analytics của frontend],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / analytics JSON response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI + async PostgreSQL],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Query Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tổng hợp KPI, platform, sentiment, keyword, post, project stats và heap view từ dữ liệu đã persist],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Query params / normalized dashboard dataset],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQLAlchemy async + query layer],

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

Luồng xử lý chính của Analytics Service có thể chia thành ba flow: HTTP analytics query flow, Kafka intake flow và pipeline execution flow.

===== a. HTTP Analytics Query Flow

Luồng này phục vụ các màn hình dashboard và analytics trong frontend:

1. Frontend gọi route same-origin như `/api/analytics/kpis`, `/api/analytics/sentiment`, `/api/analytics/keywords`, `/api/analytics/posts` hoặc `/api/analytics/heap`.
2. Next.js route handler proxy request sang `analysis-api` qua service nội bộ `analysis-api.smap.svc.cluster.local`.
3. `analysis-api` kiểm tra tham số, gọi analytics query service và đọc dữ liệu đã persist trong PostgreSQL.
4. Kết quả được chuẩn hóa thành JSON phù hợp cho KPI card, chart, post table hoặc heap visualization.
5. Nếu truy vấn vượt thời gian cho phép, API trả lỗi timeout rõ ràng để frontend có thể hiển thị trạng thái retry hoặc giảm phạm vi truy vấn.

===== b. Kafka Intake Flow

Luồng này bắt đầu khi dữ liệu chuẩn hóa được publish vào analytics data plane:

#align(center)[
  #image("../images/chapter_5/seq-analytics-intake-flow.svg", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Kafka intake trong Analytics Service_])
  #image_counter.step()
]

Ở flow này, `ConsumerServer` thực hiện các bước chính sau:

1. nhận Kafka message từ topic đầu vào;
2. decode và parse dữ liệu theo định dạng UAP hoặc ingest flat payload;
3. route domain bằng `domain_type_code` và tạo `RunContext`;
4. chuyển dữ liệu sang `IngestedBatchBundle` để sẵn sàng cho pipeline.

===== c. Pipeline Execution Flow

Sau khi intake hoàn tất, service chuyển sang pipeline execution flow:

#align(center)[
  #image("../images/chapter_5/seq-analytics-pipeline-flow.svg", width: 95%)
  #context (align(center)[_Hình #image_counter.display(): Luồng analytics pipeline trong Analytics Service_])
  #image_counter.step()
]

Ở flow này, pipeline được chạy theo kiểu consumer-based processing:

1. `ConsumerServer` chạy `PipelineUseCase.run()` bên trong `asyncio.to_thread(...)` để tránh block event loop;
2. `run_pipeline()` thực thi các stage normalization, dedup, spam, thread topology và NLP enrichment;
3. mỗi `NLPFact` có `analytics_result` được persist vào PostgreSQL thông qua `post_insight` layer;
4. mỗi `NLPFact` có `insight_message` được đưa vào `publish_one()`, tại đây message được buffer và auto-flush khi đạt `batch_size`;
5. sau khi flush, các topic `analytics.*` được downstream consumers như `knowledge-srv` tiếp tục tiêu thụ;
6. nếu crisis assessment tạo ra trạng thái mới và runtime auto-apply được bật, `analysis-consumer` có thể gọi internal API của `project-srv` để áp dụng crawl mode tương ứng. Đây là runtime bridge riêng, không phải publisher Redis của notification lane.

==== 5.3.2.4 Design Patterns áp dụng

Analytics Service áp dụng các design patterns sau:

- Consumer-Based Processing: Dịch vụ vận hành như một consumer runtime tách khỏi request-response path.
- Query API Pattern: Dữ liệu analytics đã persist được expose qua API đọc riêng cho dashboard thay vì để frontend truy vấn trực tiếp database hoặc consumer runtime.
- Pipeline Pattern: Các bước xử lý được tổ chức thành một pipeline nhiều stage có thứ tự rõ ràng.
- Thread Offloading Pattern: Phần xử lý nặng được đẩy qua `asyncio.to_thread` để giảm nguy cơ block event loop.
- Port and Adapter Pattern: Intake, persistence và publishing được tách qua các adapter hoặc usecase tương ứng.
- Downstream Contract Publishing: Kết quả phân tích không kết thúc trong service mà được phát hành tiếp cho các lane downstream.

==== 5.3.2.5 Key Decisions

- Chọn Kafka làm đầu vào chính cho analytics data plane thay vì RabbitMQ task queue.
- Tách pipeline processing khỏi HTTP path để phù hợp với workload NLP nặng.
- Tách `analysis-api` khỏi `analysis-consumer` để read path của dashboard có lifecycle, probe và scale độc lập với consumer runtime.
- Giữ `PipelineUseCase` như một wrapper mỏng quanh `run_pipeline()` để đơn giản hóa orchestration layer.
- Persist `post_insight` và publish `analytics.*` outputs như hai trách nhiệm liên tiếp nhưng tách biệt.

==== 5.3.2.6 Dependencies

Internal Dependencies:

- ConsumerRegistry: wiring các dependency runtime cho consumer server.
- Analysis API runtime và analytics query service cho read path của dashboard.
- PipelineUseCase: điều phối chạy pipeline.
- IngestionUseCase: chuyển dữ liệu intake sang bundle xử lý.
- PostInsight UseCase: lưu kết quả phân tích.
- Contract Publisher: phát hành các topic downstream.

External Dependencies:

- Kafka: analytics data plane đầu vào và các topic downstream đầu ra.
- PostgreSQL: persistence cho các thực thể phân tích.
- Frontend Application: gọi `analysis-api` thông qua các route `/api/analytics/*` ở BFF layer.
- Project Service: nhận internal runtime apply khi crisis assessment cần đổi crawl mode.
- Knowledge Service: downstream consumer của các analytics topics.
- Runtime config và domain registry: định tuyến ontology theo `domain_type_code`.
