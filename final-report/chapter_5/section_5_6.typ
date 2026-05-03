// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.6 Mẫu giao tiếp và tích hợp

Mục 5.3 đã trình bày chi tiết cấu trúc nội bộ của từng service, còn mục 5.5 đã mô tả các tương tác giữa services theo thời gian qua Sequence Diagrams. Mục này tập trung vào các mẫu giao tiếp và cơ chế tích hợp được sử dụng trong hệ thống SMAP, giải thích tại sao chọn từng pattern và cách chúng hoạt động.

=== 5.6.1 Mẫu giao tiếp

Hệ thống SMAP không sử dụng một cơ chế giao tiếp duy nhất cho toàn bộ kiến trúc. Thay vào đó, các thành phần được kết nối bằng nhiều communication patterns khác nhau tùy theo tính chất của từng lane xử lý: tương tác người dùng cần phản hồi nhanh, control plane nội bộ cần đồng bộ, execution plane cần dispatch bất đồng bộ, analytics downstream cần fanout theo stream, còn notification cần khả năng phát thông báo kịp thời tới các phiên theo dõi phù hợp.

==== 5.6.1.1 Tổng quan các mẫu giao tiếp

==== 5.6.1.1 Tổng quan các mẫu giao tiếp

#context (align(center)[_Bảng #table_counter.display(): Tổng quan các mẫu giao tiếp trong hệ thống SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.19fr, 0.24fr, 0.23fr, 0.16fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Pattern*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại tương tác*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Khi sử dụng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ví dụ trong hệ thống*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Request-response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện hoặc service gọi trực tiếp và chờ kết quả],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP, route handlers, internal HTTP],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CRUD, readiness check, search hoặc chat],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện gọi project API; project-srv gọi ingest-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Async task dispatch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Execution plane publish task và nhận completion bất đồng bộ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Crawl runtime, dry run runtime, completion correlation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv → scapper-srv → ingest completion queues],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Event streaming],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Downstream fanout và stream processing giữa analytics với knowledge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics intake, insights published, batch completed, report digest],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv → knowledge-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Realtime notification delivery],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Notification ingress và route message tới phiên theo dõi phù hợp],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis Pub/Sub + WebSocket hub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo trạng thái, campaign event, crisis alert],
    table.cell(align: center + horizon, inset: (y: 0.8em))[backend publisher → notification-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Artifact reference],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Payload lớn được materialize ra object storage, chỉ trao đổi metadata hoặc reference],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIO + metadata or event reference],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Raw crawl artifacts, report artifacts, batch file inputs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[raw batch lineage, report file_url],
  )
]

#block(inset: (left: 1em, top: 0.5em, bottom: 0.5em))[
  _Lưu ý: Cột "Công nghệ chính" phản ánh transport hoặc integration mechanism giữ vai trò trung tâm trong current architecture. Một pattern có thể đi kèm thêm cache, object storage hoặc route handler hỗ trợ, nhưng bảng chỉ liệt kê lớp giao tiếp chính._
]

==== 5.6.1.2 Synchronous Request-Response Pattern

Synchronous request-response được sử dụng ở những nơi hệ thống cần trả kết quả ngay sau khi kiểm tra quyền truy cập, tính hợp lệ của input hoặc trạng thái hiện tại của đối tượng nghiệp vụ. Pattern này xuất hiện ở cả hai cấp: giữa giao diện với backend và giữa các service trong control plane nội bộ.

Các interaction tiêu biểu:

#context (align(center)[_Bảng #table_counter.display(): Các interaction đồng bộ tiêu biểu_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.26fr, 0.18fr, 0.18fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Pattern con*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Bên tham gia chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Transport*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Vai trò*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ví dụ*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User-facing API call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện → identity, project, ingest, knowledge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP qua same-origin proxy hoặc route handlers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CRUD, truy vấn, search và chat],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tạo project, tạo datasource, gửi câu hỏi chat],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal control call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project-srv ↔ ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal HTTP],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Readiness check và lifecycle control],
    table.cell(align: center + horizon, inset: (y: 0.8em))[activation-readiness, activate, pause, resume],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Knowledge retrieval request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện → knowledge-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP API đã xác thực],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tra cứu và hỏi đáp theo ngữ cảnh],
    table.cell(align: center + horizon, inset: (y: 0.8em))[search, chat, conversation detail],
  )
]

Ở phía người dùng, giao diện chủ yếu gọi backend thông qua lớp proxy hoặc route handlers để giữ same-origin behavior cho cookie và giảm CORS complexity. Ở phía nội bộ, internal HTTP được dùng khi business control plane cần phản hồi đồng bộ trước khi thay đổi trạng thái nghiệp vụ, chẳng hạn readiness check và activate hoặc resume ở project-srv.

==== 5.6.1.3 Asynchronous Messaging Pattern

Asynchronous messaging được sử dụng ở các lane mà xử lý không nên nằm trên synchronous request path. Trong current architecture, hai nhóm bất đồng bộ quan trọng nhất không dùng cùng một transport: RabbitMQ phục vụ execution plane của crawl runtime, còn Kafka phục vụ analytics data plane và downstream fanout sang knowledge lane.

Ở execution plane, RabbitMQ phù hợp với task dispatch và completion correlation:

- ingest-srv publish crawl hoặc dry run task theo queue platform-specific;
- scapper-srv consume task, thực thi runtime và publish completion envelope trở lại;
- ingest-srv correlate completion bằng task_id, object metadata và raw batch lineage.

Ở analytics downstream, Kafka phù hợp với stream fanout và retrieval preparation:

- analysis-srv consume dữ liệu đầu vào đã chuẩn hóa từ analytics data plane;
- analysis-srv publish các outputs downstream như batch completed, insight hoặc digest;
- knowledge-srv consume các topic này để tiếp tục indexing, retrieval và materialization liên quan.

Điểm cốt lõi của pattern bất đồng bộ ở đây là tách control plane khỏi processing plane. Người dùng không chờ trực tiếp quá trình crawl, analytics hay indexing kết thúc trong một HTTP request duy nhất; thay vào đó, trạng thái và kết quả được materialize dần qua các lane runtime tương ứng.

==== 5.6.1.4 Realtime Notification Delivery Pattern

Realtime notification delivery được sử dụng khi hệ thống cần phát thông báo hoặc cảnh báo kịp thời cho user trong phạm vi được phép theo dõi. Ở current architecture, pattern này được tổ chức thành hai lớp: Redis Pub/Sub làm notification ingress và Notification Service làm delivery boundary.

Luồng delivery chính:

- backend publisher phát message vào Redis channel theo user scope, project scope, campaign scope hoặc system scope;
- notification-srv subscribe các channel phù hợp, parse message type và route theo recipient hoặc broadcast scope;
- nếu có active compatible connection, message được đẩy vào WebSocket hub để giao diện hoặc client tương thích nhận và hiển thị.

Vì connection là stateful, Redis Pub/Sub giúp nhiều notification instances nhìn thấy cùng một notification ingress stream. Tuy nhiên, pattern này chỉ mô tả delivery capability ở phía hệ thống; nó không mặc định khẳng định mọi loại giao diện hiện tại đều đang tiêu thụ trực tiếp cùng một kênh realtime ở mọi tình huống.

Trong frontend hiện tại, notification presentation vẫn có lớp state riêng. Vì vậy, phần này nên được đọc như mô tả delivery semantics của notification boundary hơn là như mô tả bắt buộc về mọi client implementation.

==== 5.6.1.5 Artifact Reference Pattern

Artifact reference pattern được dùng khi payload hoặc output không phù hợp để truyền trực tiếp qua message body hoặc lưu hoàn toàn trong relational row. Thay vì truyền nguyên dữ liệu lớn qua queue, hệ thống materialize artifact ra object storage và chỉ trao đổi metadata hoặc reference cần thiết giữa các lane xử lý.

Trong SMAP, pattern này xuất hiện ở hai nơi chính:

- scapper runtime materialize raw output vào local filesystem ở development mode hoặc MinIO ở production mode; ingest-srv chỉ nhận storage bucket, storage path, checksum, batch_id và completion metadata để tiếp tục xử lý;
- knowledge-side report generation lưu artifact báo cáo ở object storage, còn PostgreSQL chỉ giữ report metadata, status và file URL.

Lợi ích của cách làm này là giữ queue message và relational metadata ở kích thước hợp lý, đồng thời vẫn bảo toàn được lineage giữa task, artifact và kết quả downstream. Pattern này đồng bộ với cách mục 5.4 mô tả storage stack và artifact lineage, nên không cần giả định benchmark cứng hay contract dữ liệu nén nếu chưa có evidence tương ứng trong report chính.


=== 5.6.2 Kiến trúc hướng sự kiện

Hệ thống SMAP sử dụng RabbitMQ làm message broker trung tâm cho event-driven communication giữa các services. Section này mô tả topology, event catalog, và cơ chế xử lý lỗi.

==== 5.6.2.1 RabbitMQ Topology

RabbitMQ được cấu hình với Topic Exchange để routing messages linh hoạt dựa trên routing keys.

#context (align(center)[_Bảng #table_counter.display(): Cấu hình Exchange trong RabbitMQ_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.20fr, 0.55fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Exchange*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Type*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[smap.events],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Topic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Main event bus cho tất cả business events],

    table.cell(align: center + horizon, inset: (y: 0.8em))[smap.dlx],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Direct],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dead Letter Exchange cho failed messages],
  )
]

==== 5.6.2.2 Dead Letter Queue và Retry Policy

Khi message processing fail, hệ thống sử dụng Dead Letter Queue để lưu trữ failed messages và retry mechanism để xử lý lại.

Retry Policy với Exponential Backoff:

#context (align(center)[_Bảng #table_counter.display(): Retry Policy cho failed messages_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.20fr, 0.60fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Attempt*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Delay*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Action*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Ngay lập tức],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Process message lần đầu],

    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1 giây],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Retry lần 1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[10 giây],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Retry lần 2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[60 giây],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Retry lần 3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Failed],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route message đến Dead Letter Queue],
  )
]

Dead Letter Queue Configuration:

- Retention: 7 ngày, sau đó messages bị xóa tự động.

- Replay: Có thể phát lại thủ công qua admin tool khi cần xử lý lại failed messages.

- Monitoring: Prometheus metric theo dõi DLQ depth, alert khi vượt ngưỡng cấu hình.

#block(inset: (left: 1em, top: 0.5em, bottom: 0.5em))[
  _Lưu ý: Các giá trị cấu hình (retry delays, TTL, timeouts) được trình bày ở mức thiết kế, thể hiện các quyết định kiến trúc nhằm cân bằng giữa fault tolerance và resource utilization. Các giá trị cụ thể có thể điều chỉnh trong quá trình triển khai dựa trên kết quả benchmark và môi trường production._
]

=== 5.6.3 Giao tiếp thời gian thực

Hệ thống SMAP sử dụng WebSocket kết hợp Redis Pub/Sub để cung cấp cập nhật thời gian thực cho người dùng. Section này giải thích cách giải quyết vấn đề horizontal scaling của stateful WebSocket connections.

==== 5.6.3.1 Kiến trúc WebSocket với Redis Pub/Sub

Vấn đề chính khi scale WebSocket Service là connections stateful. Mỗi client connection gắn với một server instance cụ thể. Khi có nhiều instances, hệ thống cần cơ chế để đảm bảo message từ Analytics Service đến đúng client.

Giải pháp: Redis Pub/Sub làm message bus giữa các WebSocket instances.

Luồng hoạt động:

- Analytics Service phát hiện crisis post và gửi message vào Redis channel theo user_id.

- Tất cả WebSocket Service instances đăng ký channel đó.

- Instance nào có connection với user đó sẽ chuyển tiếp message đến client.

- Các instances khác nhận message nhưng không có connection nên bỏ qua.

Channel Structure:

- Channel theo user: Messages dành riêng cho một user cụ thể như cảnh báo khủng hoảng, thông báo export hoàn thành.

- Channel theo project: Messages liên quan đến một project như cập nhật tiến độ.

- Channel phát sóng: Messages gửi đến tất cả users như thông báo hệ thống.

==== 5.6.3.2 Message Types

#context (align(center)[_Bảng #table_counter.display(): Các loại WebSocket messages_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.22fr, 0.60fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hướng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[auth],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Client → Server],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xác thực connection với JWT token],

    table.cell(align: center + horizon, inset: (y: 0.8em))[progress_update],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cập nhật tiến độ crawling và analytics với phase và percent],

    table.cell(align: center + horizon, inset: (y: 0.8em))[crisis_alert],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo phát hiện bài viết khủng hoảng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[completion],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo project hoàn thành],

    table.cell(align: center + horizon, inset: (y: 0.8em))[export_ready],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo file export đã sẵn sàng download],
  )
]

==== 5.6.3.3 Connection Lifecycle

Connection lifecycle của WebSocket trong hệ thống:

- Connect: Client mở WebSocket connection đến WebSocket Service.

- Authenticate: Client gửi auth message với JWT token, server verify và associate connection với user_id.

- Subscribe: Server đăng ký Redis Pub/Sub channels liên quan đến user.

- Heartbeat: Ping/pong định kỳ để detect stale connections.

- Disconnect: Khi user navigate away hoặc close browser, connection được cleanup và hủy đăng ký channels.

Chiến lược kết nối lại: Client sử dụng exponential backoff khi connection bị mất, tối đa 60 giây giữa các lần thử lại.

=== 5.6.4 Giám sát hệ thống

Hệ thống SMAP implement observability theo nguyên tắc đã đề ra ở mục 5.1, bao gồm structured logging, metrics, và health checks. Section này mô tả cách hệ thống được monitor để đảm bảo availability và performance.

==== 5.6.4.1 Structured Logging

Tất cả services sử dụng structured logging với JSON format để dễ dàng parse và query.

#context (align(center)[_Bảng #table_counter.display(): Logging configuration theo ngôn ngữ_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.20fr, 0.20fr, 0.35fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service Type*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Library*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Format*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Go Services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Zap],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JSON],
    table.cell(align: center + horizon, inset: (y: 0.8em))[stdout],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Python Services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Loguru],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JSON],
    table.cell(align: center + horizon, inset: (y: 0.8em))[stdout],
  )
]

Log Levels Policy:

- DEBUG: Chỉ dùng trong development, retention ngắn.

- INFO: Normal operations như request received, task completed.

- WARN: Recoverable errors như retry attempts, rate limit hit.

- ERROR: Service errors cần attention như database connection failed.

Standard Log Fields: Mỗi log entry bao gồm các fields level, timestamp, service, trace_id, message, và context-specific fields.

==== 5.6.4.2 Prometheus Metrics

Mỗi service expose /metrics endpoint cho Prometheus scraping.

#context (align(center)[_Bảng #table_counter.display(): Prometheus Metrics theo service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.38fr, 0.15fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nhãn*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector],
    table.cell(align: center + horizon, inset: (y: 0.8em))[collector_jobs_dispatched_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[platform],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector],
    table.cell(align: center + horizon, inset: (y: 0.8em))[collector_jobs_active],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gauge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[platform],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analytics_pipeline \ \_duration_seconds],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Histogram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[phase],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analytics_crisis_detected_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[severity],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[http_requests_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[method, path, status],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[http_request_duration_seconds],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Histogram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[method, path],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[websocket_connections_active],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gauge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[websocket_messages_sent_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[type],
  )
]

==== 5.6.4.3 Health Checks

Mỗi service expose 2 health check endpoints phục vụ mục đích khác nhau:

#context (align(center)[_Bảng #table_counter.display(): Health Check Endpoints_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.15fr, 0.20fr, 0.35fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Endpoint*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thời gian phản hồi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Kubernetes Probe*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[/health],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Process alive, basic memory check],
    table.cell(align: center + horizon, inset: (y: 0.8em))[livenessProbe],

    table.cell(align: center + horizon, inset: (y: 0.8em))[/ready],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostgreSQL, RabbitMQ, Redis, MinIO connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[readinessProbe],
  )
]

Kiểm tra nông tại /health: Kiểm tra process còn sống hay không. Nếu fail, Kubernetes sẽ restart pod. Response nhanh vì không check external dependencies.

Kiểm tra sâu tại /ready: Kiểm tra tất cả external dependencies như database, message queue, cache. Nếu fail, Kubernetes sẽ remove pod khỏi service endpoints, không route traffic đến pod đó cho đến khi ready lại.

Hành vi khi lỗi:

- Khi /health fail: Pod bị restart bởi Kubernetes.

- Khi /ready fail: Pod không nhận traffic mới nhưng không bị restart, cho phép service tự phục hồi khi dependencies available lại.

==== 5.6.4.4 Distributed Tracing

Hệ thống implement basic distributed tracing thông qua trace_id propagation:

- Trace ID Generation: UUID được generate tại entry point.

- Propagation: Trace ID được truyền qua HTTP header X-Trace-ID và RabbitMQ message properties.

- Logging: Tất cả services log trace_id trong mỗi log entry.

- Debugging: Khi cần debug một request, có thể tìm kiếm trace_id trong logs của tất cả services để theo dõi luồng xử lý.

Hạn chế hiện tại: Chưa có công cụ trực quan hóa như Jaeger. Debugging vẫn dựa vào tìm kiếm log thủ công. Đây là cải tiến có thể thực hiện trong tương lai với OpenTelemetry instrumentation.

=== 5.6.5 Tổng kết

- Hệ thống sử dụng 4 patterns là REST API cho tác vụ đồng bộ dưới 30 giây, Event-Driven cho tác vụ bất đồng bộ trên 30 giây, WebSocket cho cập nhật thời gian thực, và Claim Check cho dữ liệu lớn. Mỗi pattern được chọn dựa trên đặc điểm của tác vụ để tối ưu hiệu năng và khả năng mở rộng.

- RabbitMQ với Topic Exchange làm message broker trung tâm. 6 events chính điều phối luồng xử lý giữa các services. Dead Letter Queue với exponential backoff retry policy đảm bảo fault tolerance.

- WebSocket kết hợp Redis Pub/Sub cho phép horizontal scaling. Khi có nhiều WebSocket instances, Redis Pub/Sub phân phối messages đến tất cả instances, instance nào có connection với user sẽ chuyển tiếp message. Channel-based routing đảm bảo messages đến đúng recipients.

- Structured logging với Zap và Loguru output JSON format. Prometheus metrics cho monitoring. Health checks với kiểm tra nông cho liveness và kiểm tra sâu cho readiness. Basic distributed tracing qua trace_id propagation.
