// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.6 Mẫu giao tiếp và tích hợp

Mục 5.3 đã trình bày chi tiết cấu trúc nội bộ của từng service, còn mục 5.5 đã mô tả các tương tác giữa services theo thời gian qua Sequence Diagrams. Mục này tập trung vào các mẫu giao tiếp và cơ chế tích hợp được sử dụng trong hệ thống SMAP, giải thích tại sao chọn từng pattern và cách chúng hoạt động.

=== 5.6.1 Mẫu giao tiếp

Hệ thống SMAP sử dụng 4 mẫu giao tiếp chính, mỗi pattern phục vụ một mục đích khác nhau dựa trên đặc điểm của tác vụ.

==== 5.6.1.1 Tổng quan các mẫu giao tiếp

#context (align(center)[_Bảng #table_counter.display(): Tổng quan các mẫu giao tiếp trong hệ thống SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.25fr, 0.22fr, 0.35fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Pattern*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Khi nào sử dụng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ví dụ trong hệ thống*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[REST API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tác vụ đồng bộ, thời gian xử lý ngắn dưới 30 giây],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin, FastAPI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[GET /projects, POST /projects, GET /dashboard],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Event-Driven],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tác vụ bất đồng bộ, thời gian xử lý dài trên 30 giây],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project.created, data.collected, crisis.detected],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cập nhật thời gian thực, thông báo đẩy],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gorilla WebSocket, Redis Pub/Sub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cập nhật tiến độ, cảnh báo khủng hoảng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Claim Check],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dữ liệu lớn không phù hợp đưa vào message queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIO, RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Crawl batches 2-5MB lưu MinIO, gửi tham chiếu qua RabbitMQ],
  )
]

#block(inset: (left: 1em, top: 0.5em, bottom: 0.5em))[
  _Lưu ý: Cột "Công nghệ" liệt kê các công nghệ được chọn trong giai đoạn thiết kế dựa trên yêu cầu phi chức năng. Việc lựa chọn cụ thể được trình bày trong các Architecture Decision Records tại mục 5.7.2._
]

==== 5.6.1.2 REST API Pattern

REST API được sử dụng cho các tác vụ đồng bộ với thời gian xử lý ngắn, chủ yếu là các thao tác CRUD và truy vấn dữ liệu từ người dùng. Pattern này phù hợp khi client cần response ngay lập tức và thời gian xử lý dưới 30 giây.

Các endpoints chính trong hệ thống:

#context (align(center)[_Bảng #table_counter.display(): Các REST API endpoints chính_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.12fr, 0.28fr, 0.20fr, 0.20fr, 0.20fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Method*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Endpoint*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thời gian phản hồi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[POST],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/api/v1/projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tạo project mới],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],

    table.cell(align: center + horizon, inset: (y: 0.8em))[GET],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/api/v1/projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Danh sách projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 200ms],

    table.cell(align: center + horizon, inset: (y: 0.8em))[GET],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/api/v1/projects/:id/dashboard],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dashboard analytics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 2s],

    table.cell(align: center + horizon, inset: (y: 0.8em))[POST],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/api/v1/auth/login],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Đăng nhập],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 150ms],

    table.cell(align: center + horizon, inset: (y: 0.8em))[GET],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/api/v1/trends],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Danh sách trends],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 300ms],
  )
]

Tất cả REST APIs sử dụng JWT HttpOnly Cookie để xác thực. Response format chuẩn JSON với error codes và messages rõ ràng.

==== 5.6.1.3 Event-Driven Pattern

Event-Driven Architecture được sử dụng cho các tác vụ xử lý dài như crawling và analytics. Khi user khởi chạy project theo UC-03, thời gian xử lý có thể từ 5-30 phút, nếu sử dụng REST synchronous thì connection sẽ timeout.

Lợi ích của Event-Driven trong hệ thống SMAP:

- Giảm phụ thuộc giữa các service: Project Service không cần biết Collector Service đang chạy hay không, chỉ cần gửi event vào message queue.

- Khả năng phục hồi: Nếu Collector Service restart, messages vẫn được lưu trong RabbitMQ queue và xử lý khi service khởi động lại.

- Khả năng mở rộng: Có thể scale Collector workers độc lập mà không ảnh hưởng Project Service.

- Tách biệt thời gian: Publisher và consumer không cần online cùng lúc.

==== 5.6.1.4 WebSocket Pattern

WebSocket được sử dụng để đẩy cập nhật thời gian thực đến client mà không cần client polling liên tục. Hai use cases chính:

- Theo dõi tiến độ theo UC-03: Hiển thị tiến độ crawling và analytics theo thời gian thực.

- Cảnh báo khủng hoảng theo UC-08: Thông báo ngay lập tức khi phát hiện bài viết khủng hoảng.

Vấn đề horizontal scaling: WebSocket connections là stateful, mỗi connection gắn với một server instance cụ thể. Khi có nhiều WebSocket Service instances, hệ thống cần cơ chế để phân phối message đến đúng client.

Giải pháp: Sử dụng Redis Pub/Sub làm message bus giữa các instances. Khi Analytics Service gửi cảnh báo khủng hoảng, message được gửi đến Redis channel, tất cả WebSocket instances đăng ký channel đó sẽ nhận được và chuyển tiếp đến các client đang kết nối.

==== 5.6.1.5 Claim Check Pattern

Claim Check Pattern giải quyết vấn đề dữ liệu lớn trong message queue. Mỗi batch crawl data có kích thước 2-5MB, nếu đưa trực tiếp vào RabbitMQ message sẽ gây:

- Áp lực bộ nhớ trên RabbitMQ broker.

- Băng thông mạng cao khi truyền messages.

- Consumer xử lý chậm do kích thước message lớn.

Giải pháp: Crawler Services upload batch data lên MinIO, sau đó gửi event với tham chiếu thay vì dữ liệu thực. Analytics Service nhận event, dùng tham chiếu để download data từ MinIO.

Kết quả: RabbitMQ message chỉ còn khoảng 1KB thay vì 5MB, giảm 5000 lần kích thước message.


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
