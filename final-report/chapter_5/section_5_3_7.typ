#import "../counters.typ": image_counter, table_counter

=== 5.3.7 Knowledge Service

Knowledge Service là dịch vụ chịu trách nhiệm cho knowledge retrieval và knowledge materialization layer của hệ thống SMAP. Khác với các service chỉ thuần HTTP hoặc chỉ thuần consumer runtime, service này kết hợp cả lane indexing downstream lẫn lane consumption đồng bộ để biến analytics outputs thành tri thức có thể tìm kiếm, hỏi đáp và tái sử dụng cho report generation.

Vai trò của Knowledge Service trong kiến trúc tổng thể:

- Downstream Indexing Runtime: Tiêu thụ analytics outputs và chuyển chúng thành vector points cùng tracking metadata.
- Semantic Retrieval Layer: Thực hiện semantic search trên các collection theo project với filtering và caching.
- RAG Chat Orchestrator: Kết hợp search results, LLM generation, citations và conversation history để tạo câu trả lời theo ngữ cảnh.
- Extended Report Materialization Layer: Current source còn có khả năng tổng hợp kết quả truy hồi, sinh các section bằng LLM và materialize artifact báo cáo.
- Knowledge Metadata Manager: Lưu conversations, messages, reports và indexing status phục vụ truy vết và tái sử dụng.

Service này đáp ứng trực tiếp FR-10 về Knowledge Search and Chat, đồng thời tham gia trực tiếp vào UC-05 về Execute Analytics and Build Knowledge và UC-06 về Search and Chat Over Knowledge. Ngoài các capability đã traceable rõ ở Chương 4, current source còn có report generation như một capability mở rộng của knowledge layer.

==== 5.3.7.1 Thành phần chính

#context (align(center)[_Bảng #table_counter.display(): Thành phần chính của Knowledge Service_])
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

    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Server / Domain Router],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Công bố các route đã xác thực cho `search`, `chat`, `reports` và các route nội bộ cho indexing control],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / routed usecase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin + middleware],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ConsumerServer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Điều phối Kafka consumer runtime để intake các topic analytics downstream],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka message / indexing input],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Sarama consumer runtime],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Indexing UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Sinh embedding, ensure collection, upsert vào Qdrant, cập nhật tracking status và hỗ trợ retry hoặc reconcile],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics payload / indexed points + tracking result],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go usecase + Qdrant + PostgreSQL],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Search UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Resolve campaign sang project scope, cache lookup, embed query, search nhiều collection và aggregate kết quả],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Search input / search results],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis + Qdrant + embedding layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Chat UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Phân loại intent, kết hợp retrieval với LLM, sinh citations và persist conversation history],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Chat request / contextual answer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LLM orchestration + conversation store],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Report UseCase (Capability mở rộng)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Deduplicate yêu cầu, chạy background generation, tạo markdown artifact và upload sang object storage],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Report request / report artifact + metadata],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LLM + MinIO + PostgreSQL],
  )
]

==== 5.3.7.2 Data Flow

Knowledge Service có bốn luồng xử lý đáng chú ý: Kafka downstream indexing flow, internal indexing control flow, contextual search and chat flow, và report generation capability flow. Trong đó, hai luồng đầu tiên gắn với indexing runtime, luồng thứ ba bám trực tiếp bộ requirements đã chốt, còn luồng report phản ánh capability mở rộng hiện có trong source.

===== a. Kafka Downstream Indexing Flow

Luồng này bắt đầu khi dữ liệu analytics downstream được phát hành.

1. Consumer runtime nhận message từ các topic như `analytics.batch.completed`, `analytics.insights.published` hoặc `analytics.report.digest`.
2. Handler route message sang usecase indexing phù hợp như `IndexBatch`, `IndexInsight` hoặc `IndexDigest`.
3. Indexing layer sinh embedding, ensure collection như `proj_{project_id}` hoặc `macro_insights`, rồi upsert points vào Qdrant.
4. Tracking metadata và trạng thái `PENDING`, `INDEXED` hoặc `FAILED` được cập nhật trong PostgreSQL; các statistics hoặc retry path tiếp tục dựa trên lớp metadata này.
5. Search cache liên quan bị invalidate sau khi index thành công để các truy vấn sau nhìn thấy dữ liệu mới.

===== b. Internal Indexing Control Flow

Luồng này phản ánh lớp control routes nội bộ của service, tách biệt với Kafka indexing lane.

1. Internal caller gọi các route như `/internal/index`, `/internal/index/retry`, `/internal/index/reconcile` hoặc `/internal/index/statistics/:project_id`.
2. HTTP layer xác thực bằng internal auth middleware và bind request tương ứng.
3. Service thực thi usecase điều khiển như index từ MinIO file URL, retry failed records, reconcile pending records hoặc truy vấn thống kê indexing.
4. Kết quả được trả về như control hoặc monitoring output cho runtime caller, thay vì như search result hướng người dùng cuối.

===== c. Contextual Search and Chat Flow

Luồng này bắt đầu khi client đã xác thực gửi yêu cầu `search` hoặc `chat`.

1. Client gọi route `/search` hoặc `/chat` thông qua HTTP API đã được bảo vệ bởi auth middleware.
2. Search usecase resolve `campaign_id` sang `project_ids` qua `project-srv`, kiểm tra cache và sinh embedding cho truy vấn đã được enrich theo campaign context.
3. Service thực hiện parallel search trên các Qdrant collections phù hợp, lọc theo score, dedupe snapshot lặp và aggregate kết quả.
4. Với chat flow, service phân loại intent, kết hợp search results với conversation history rồi gọi LLM để sinh câu trả lời.
5. Câu trả lời, citations, suggestions và conversation or message history được persist để phục vụ các lượt tương tác tiếp theo.

===== d. Report Generation Capability Flow

Luồng này phản ánh một capability mở rộng hiện có trong current source của knowledge layer.

1. Client gọi route `/reports/generate` với campaign scope và các filter tương ứng.
2. Report usecase validate input, hash tham số để deduplicate, tạo report record và khởi động background generation.
3. Background pipeline gọi search usecase để aggregate tài liệu liên quan, chọn sample đại diện và sinh từng section bằng LLM với concurrency có kiểm soát.
4. Markdown artifact được compile và upload lên MinIO như một object báo cáo.
5. Report status, file metadata và thời gian sinh được cập nhật trong PostgreSQL; client có thể truy vấn trạng thái hoặc lấy presigned download URL sau đó.

==== 5.3.7.3 Design Patterns áp dụng

Knowledge Service áp dụng các design patterns sau:

- Dual Runtime Pattern: cùng một bounded context chứa cả HTTP APIs cho consumption và Kafka consumer lane cho indexing downstream.
- Collection-per-Project Vector Indexing: dữ liệu post được index vào collection theo project, trong khi macro insights và digest dùng collection chia sẻ theo loại tri thức.
- Cache-Aside Retrieval Pattern: kết quả search và campaign-to-project resolution được cache để giảm latency cho các truy vấn lặp lại.
- RAG Orchestration Pattern: chat layer không gọi LLM trực tiếp trên dữ liệu thô mà luôn đi qua retrieval results, citations và conversation history.
- Async Materialization Pattern: report generation được tách khỏi request path và materialize artifact xuống object storage.
- Internal Control Route Pattern: các route nội bộ cho index, retry, reconcile và statistics được tách biệt khỏi public knowledge APIs và khỏi Kafka indexing lane.

==== 5.3.7.4 Key Decisions

- Tách vector store `Qdrant` khỏi metadata store `PostgreSQL` để tối ưu riêng cho retrieval và operational tracking.
- Giữ `Search UseCase` làm capability trung tâm được tái sử dụng bởi chat và report thay vì để từng domain tự truy hồi riêng.
- Scope truy vấn theo `campaign -> project collections` để tránh cross-campaign leakage và giữ knowledge boundary rõ ràng.
- Dùng background generation kết hợp `MinIO` artifact cho report để tránh block request path trong workload LLM.
- Giữ Kafka lane cho downstream indexing, còn retry, reconcile và statistics đi qua internal control routes để không trộn streaming semantics với operational control.
- Giữ indexing retry và reconcile trong cùng service boundary để việc vận hành knowledge lane không phải tách sang một runtime control riêng.

==== 5.3.7.5 Dependencies

Internal Dependencies:

- HTTP server wiring cho các domain indexing, search, chat và report.
- Indexing usecase, point layer, embedding layer và tracking repositories.
- Search usecase được chat và report usecases tái sử dụng như retrieval core.
- Conversation, message, report và indexing repositories trên PostgreSQL.

External Dependencies:

- Kafka topics downstream từ `analysis-srv`.
- Qdrant cho vector indexing và semantic retrieval.
- Redis cho caching.
- PostgreSQL cho conversations, reports và indexed document tracking.
- MinIO cho report artifacts và một số indexing inputs theo file URL.
- `project-srv` cho campaign/project resolution.
- Embedding và LLM providers cho vector generation, answer synthesis và report generation.
