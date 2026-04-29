#import "../counters.typ": image_counter, table_counter

=== 5.3.8 Scapper Worker Service

Scapper Worker Service là runtime lane chịu trách nhiệm thực thi các crawl task bất đồng bộ trong execution plane của hệ thống SMAP. Service này tiếp nhận platform-specific task từ RabbitMQ, gọi TinLikeSub SDK để thực hiện các action crawl tương ứng, materialize raw artifact theo storage contract của runtime, rồi phát hành completion envelope trở lại ingest runtime để lane ingest tiếp tục xử lý downstream.

Khác với một worker thuần túy, service còn cung cấp một lớp FastAPI mỏng để submit task, kiểm tra kết quả và giám sát health của runtime khi cần cho local hoặc dev workflow.

Vai trò của Scapper Worker Service trong kiến trúc tổng thể:

- RabbitMQ Crawl Consumer: Tiêu thụ các queue `tiktok_tasks`, `facebook_tasks` và `youtube_tasks`.
- Platform Action Dispatcher: Định tuyến `action` sang handler phù hợp theo queue và platform.
- SDK-Based Crawl Executor: Thực thi các action đơn lẻ hoặc composite flows như `full_flow` thông qua TinLikeSub SDK.
- Raw Artifact Materializer: Ghi raw output xuống local storage hoặc MinIO theo runtime mode và storage contract của runtime.
- Completion Publisher: Publish completion envelope về ingest completion queue tương ứng để giữ correlation giữa crawl lane và ingest lane.
- Auxiliary Task API Surface: Cung cấp các route submit hoặc kiểm tra kết quả để hỗ trợ local hoặc debug workflow.

Service này đáp ứng trực tiếp FR-08 về Crawl Runtime Orchestration và liên quan trực tiếp đến UC-03 về Configure Datasource and Run Dry Run.

==== 5.3.8.1 Thành phần chính

#context (align(center)[_Bảng #table_counter.display(): Thành phần chính của Scapper Worker Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.40fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thành phần*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trách nhiệm chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input / Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI App / Lifespan Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Khởi động worker trong app lifespan, công bố router và health surface của runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Startup or HTTP request / running runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI + lifespan],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Task Router / Submit API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Map platform sang queue, validate action và publish task payload cho local hoặc dev trigger, hoặc trả kết quả debug khi được yêu cầu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP payload / RabbitMQ message or debug response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI route layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Worker Runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giữ kết nối RabbitMQ, cấp một channel cho mỗi queue, consume message và điều phối vòng đời xử lý],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ message / task result],
    table.cell(align: center + horizon, inset: (y: 0.8em))[aio-pika + async Python],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Queue Registry / Dispatch Map],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Duy trì mapping queue -> platform và action -> handler để route đúng crawl flow],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Queue name + action / handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[In-process registry],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Platform Handlers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thực thi các action như `search`, `post_detail`, `comments`, `video_detail` hoặc `full_flow` qua TinLikeSub SDK],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Task params / crawl result],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TinLikeSub SDK adapters],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Storage Adapter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Materialize raw output xuống `output/` ở dev mode hoặc MinIO ở production mode, đồng thời sinh `batch_id` và `checksum`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Task result / storage metadata],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Filesystem or MinIO],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Completion Publisher],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Đóng gói completion envelope và route sang queue completion phù hợp cho execution hoặc dryrun lane],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Storage metadata / completion message],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ publisher],
  )
]

==== 5.3.8.2 Data Flow

Scapper Worker Service có ba luồng đáng chú ý: auxiliary task submission flow, canonical crawl execution and completion flow, và local result inspection flow.

===== a. Auxiliary Task Submission Flow

Luồng này phản ánh surface submit hiện có của service, hữu ích cho local hoặc dev workflow và một số trigger ngoài worker runtime. Đây không phải canonical ingest -> scapper contract của production lane, vì contract chuẩn yêu cầu request envelope với `task_id` do `ingest-srv` cấp.

1. Client gọi `POST /api/v1/tasks/{platform}` với `action` và `params` tương ứng.
2. Router map `platform` sang queue name, validate action hợp lệ theo registry của queue đó.
3. Service tạo `TaskPayload` với `task_id` và `created_at`, rồi publish message sang RabbitMQ queue tương ứng như một convenience flow cho local hoặc dev usage.
4. Message trở thành đầu vào cho worker runtime hoặc cho một worker instance khác đang consume cùng queue.

===== b. Canonical Crawl Execution and Completion Flow

Đây là luồng cốt lõi của service trong execution plane.

#align(center)[
  #image("../images/chapter_5/seq-scapper-runtime-flow.svg", width: 97%)
  #context (align(center)[_Hình #image_counter.display(): Luồng canonical crawl execution và completion trong Scapper Worker Service_])
  #image_counter.step()
]

1. Worker runtime consume message từ queue platform-specific như `tiktok_tasks`, `facebook_tasks` hoặc `youtube_tasks`; ở production lane, message này tương ứng với request envelope chuẩn từ `ingest-srv`.
2. Registry xác định handler phù hợp theo `queue` và `action`; handler sau đó gọi TinLikeSub SDK để thực thi crawl action tương ứng.
3. Nếu action là composite như `full_flow`, handler sẽ tự điều phối nhiều bước crawl liên tiếp và gom kết quả về một raw result bundle.
4. Sau khi crawl xong, service materialize raw result xuống local output hoặc MinIO theo runtime mode, đồng thời sinh `storage_path`, `batch_id` và `checksum` theo contract.
5. Service đóng gói `CompletionEnvelope` và publish sang `ingest_task_completions` hoặc `ingest_dryrun_completions` dựa trên `runtime_kind`, để ingest lane tiếp tục correlation và downstream processing.

===== c. Local Result Inspection Flow

Luồng này chỉ đóng vai trò phụ trợ cho debug hoặc local verification.

1. Client gọi `GET /api/v1/tasks/{task_id}/result` hoặc `GET /api/v1/tasks`.
2. Router đọc các JSON artifacts trong `output/` và trả về payload hoặc danh sách recent tasks tìm thấy.
3. Kết quả này hữu ích cho kiểm tra cục bộ, nhưng không thay thế production handoff contract vốn dựa trên raw artifact storage và completion envelope.

==== 5.3.8.3 Design Patterns áp dụng

Scapper Worker Service áp dụng các design patterns sau:

- Hybrid API and Worker Runtime Pattern: cùng một service cung cấp cả HTTP surface mỏng và RabbitMQ worker runtime.
- Queue-per-Platform Dispatch Pattern: mỗi platform được gắn với queue và action registry riêng để tránh lẫn semantics giữa các nguồn crawl.
- Handler Registry Pattern: việc map `action` sang handler cụ thể được giữ trong một dispatch map tập trung thay vì rải khắp worker code.
- Materialize-then-Notify Pattern: raw artifact phải được lưu trước khi completion envelope được phát hành cho ingest lane.
- Mode-Switched Storage Pattern: dev mode ưu tiên local file output, còn production mode dùng MinIO theo storage contract chung.
- Completion Routing Pattern: completion queue được chọn theo `runtime_kind` để tách execution flow và dryrun flow.

==== 5.3.8.4 Key Decisions

- Dùng RabbitMQ queue tách theo platform để đơn giản hóa dispatch và cho phép tuning concurrency theo từng lane.
- Giữ một channel riêng cho mỗi queue để `prefetch_count` hoạt động độc lập giữa các platform runtimes.
- Giữ `task_id` làm correlation key xuyên suốt request, storage artifact và completion envelope.
- Chỉ publish completion sau khi storage metadata đã sẵn sàng để ingest lane không phải tiêu thụ raw payload trực tiếp từ message body.
- Duy trì submit API, local result API và `output/` artifacts như một debug surface, nhưng không xem đó là authoritative production handoff hay canonical ingest contract.

==== 5.3.8.5 Dependencies

Internal Dependencies:

- FastAPI app, router và lifespan wiring.
- Worker runtime và dispatch registry theo queue hoặc platform.
- Platform handlers cho TikTok, Facebook và YouTube.
- Storage adapter cho local filesystem và MinIO.
- Completion publisher cho execution hoặc dryrun completion queues.

External Dependencies:

- RabbitMQ cho request queues và completion queues.
- TinLikeSub SDK hoặc upstream crawl API runtime.
- MinIO trong production mode để lưu raw artifact.
- Local filesystem `output/` trong dev mode.
- `ingest-srv` như producer của crawl tasks và consumer của completion envelopes.
