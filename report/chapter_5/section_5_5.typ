// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.5 Sơ đồ tuần tự

Sơ đồ tuần tự cụ thể hóa các tương tác động giữa các thành phần hệ thống theo trình tự thời gian cho các Use Case đã được đặc tả ở mục 4.4. Các sơ đồ này làm rõ cơ chế giao tiếp giữa Web UI, các dịch vụ nghiệp vụ, hệ thống lưu trữ (PostgreSQL, MongoDB, Redis, MinIO) và hàng đợi thông điệp (RabbitMQ).

Các sơ đồ tuần tự được chia thành 3 nhóm chức năng chính:

- Nhóm Quản lý Project (UC-01, UC-05): Cấu hình và quản lý danh sách Projects, bao gồm tạo mới, xem danh sách, lọc và điều hướng theo trạng thái.

- Nhóm Thực thi và Phân tích (UC-02, UC-03, UC-04): Quy trình dry-run kiểm tra keywords, khởi chạy và giám sát Project với tiến độ real-time, và truy vấn kết quả phân tích trên dashboard.

- Nhóm Báo cáo và Cảnh báo (UC-06, UC-07, UC-08): Xuất báo cáo ở nhiều định dạng, phát hiện trend tự động theo cron job, và cảnh báo khủng hoảng thương hiệu.

=== 5.5.1 UC-01: Cấu hình Project

UC-01 mô tả quy trình tạo mới một Project phân tích. Marketing Analyst định nghĩa scope phân tích thông qua việc cấu hình các từ khóa thương hiệu và từ khóa đối thủ, cùng với khoảng thời gian phân tích.

Project được lưu với trạng thái draft và không kích hoạt bất kỳ xử lý nào. Thiết kế này tuân thủ nguyên tắc explicit execution, tránh việc hệ thống tự động crawl dữ liệu khi người dùng chưa sẵn sàng.

#align(center)[
  #image("../images/sequence/uc1_cau_hinh_project.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01: Cấu hình Project_])
#image_counter.step()

Luồng xử lý chính:

- User điền thông tin Project qua wizard 4 bước: thông tin cơ bản, cấu hình thương hiệu, cấu hình đối thủ, và xác nhận.

- Web UI gửi POST request đến Project Service với JWT authentication.

- Project Service validate date range và lưu Project vào PostgreSQL với status draft.

- Trả về HTTP 201 Created với project_id để sử dụng cho các bước tiếp theo.

Điểm quan trọng: Việc tạo Project không trigger bất kỳ background processing nào. Không có Redis state initialization hay RabbitMQ event publishing ở bước này.

=== 5.5.2 UC-02: Dry-run (Kiểm tra keywords)

UC-02 cung cấp cơ chế thử nghiệm keywords trước khi chạy Project thật. Hệ thống sử dụng sampling strategy để giảm chi phí: chỉ lấy 1-2 items mẫu cho mỗi keyword trên mỗi platform.

Sequence diagram được chia thành 2 phần: Setup và crawling, Analytics và hiển thị kết quả.

==== 5.5.2.1 Setup và Crawling

#align(center)[
  #image("../images/sequence/uc2_dryryn_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 1: Dry-run Setup và Crawling_])
#image_counter.step()

Luồng xử lý:

- User nhập keywords và chọn platform để test.

- Project Service publish dryrun.created event vào RabbitMQ.

- API trả về HTTP 202 Accepted với task_id, Web UI bắt đầu polling status.

- Collector Service dispatch jobs đến Crawler Services với sample size giới hạn.

- Crawler fetch metadata từ platform APIs và upload batch vào MinIO.

==== 5.5.2.2 Analytics và Results

#align(center)[
  #image("../images/sequence/uc2_dryryn_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 2: Analytics Pipeline và Results_])
#image_counter.step()

Luồng xử lý:

- Collector publish data.collected event để trigger Analytics Service.

- Analytics Service download batch từ MinIO và chạy full 5-step pipeline.

- Kết quả được lưu vào PostgreSQL với project_id = NULL để phân biệt với production data.

- Web UI polling detect completion và fetch summarized results để hiển thị preview dashboard.

=== 5.5.3 UC-03: Khởi chạy và Giám sát Project

UC-03 là luồng xử lý phức tạp nhất trong hệ thống, bao gồm 4 giai đoạn: Execute và Initialize, Collector Dispatches Jobs, Analytics Pipeline, và Completion.

==== 5.5.3.1 Execute và Initialize

#align(center)[
  #image("../images/sequence/uc3_execute_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 1: Execute và Initialize Project_])
#image_counter.step()

Luồng xử lý:

- User click Khởi chạy, Web UI gửi POST request đến Project Service.

- Project Service verify ownership và kiểm tra duplicate execution qua Redis state.

- Update PostgreSQL status từ draft thành process.

- Initialize Redis state với status INITIALIZING và TTL 7 days.

- Publish project.created event vào RabbitMQ.

- Trả về 200 OK, Web UI navigate đến Project Processing page.

Rollback mechanism: Nếu Redis init fail thì rollback PostgreSQL status. Nếu RabbitMQ publish fail thì rollback cả Redis state và PostgreSQL status.

==== 5.5.3.2 Collector Dispatches Jobs

#align(center)[
  #image("../images/sequence/uc3_execute_part_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 2: Collector Dispatches Crawl Jobs_]
)
#image_counter.step()

Luồng xử lý:

- Collector Service consume project.created event từ RabbitMQ.

- Parse keywords và generate job matrix: total_jobs = num_keywords × num_platforms × num_days.

- Update Redis state với status CRAWLING và total jobs count.

- Dispatch jobs đến Crawler Services, mỗi job crawl 1 keyword trên 1 platform trong 1 ngày.

- Crawler upload batch 20-50 items vào MinIO và Collector publish data.collected event.

- Sau mỗi job hoàn thành, increment Redis counter để track progress.

==== 5.5.3.3 Analytics Pipeline

#align(center)[
  #image("../images/sequence/uc3_execute_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 3: Analytics Pipeline Processing_])
#image_counter.step()

Luồng xử lý:

- Analytics Service consume data.collected events từ RabbitMQ.

- Download batch từ MinIO và chạy 5-step pipeline: Preprocessing, Intent Classification, Keyword Extraction, Sentiment Analysis, Impact Calculation.

- Batch INSERT kết quả vào PostgreSQL.

- Sau khi save, check triple-check criteria để detect crisis posts. Nếu phát hiện crisis thì publish crisis.detected event.

==== 5.5.3.4 Completion và Notification

#align(center)[
  #image("../images/sequence/uc3_execute_part_4.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 4: Project Completion và Notification_]
)
#image_counter.step()

Luồng xử lý:

- Collector periodically check Redis state, khi done >= total thì update status DONE.

- Gọi webhook đến Project Service để báo completion.

- Project Service update PostgreSQL status thành completed.

- Publish notification qua Redis Pub/Sub đến WebSocket Service.

- Web UI polling detect completion và redirect đến Dashboard.

=== 5.5.4 UC-04: Xem kết quả phân tích

UC-04 mô tả quy trình truy vấn và hiển thị kết quả phân tích sau khi Project hoàn tất.

==== 5.5.4.1 Overview Dashboard

#align(center)[
  #image("../images/sequence/uc4_result_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 1: Overview Dashboard_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Dashboard page.

- Web UI request overview statistics từ Project API.

- Project API query PostgreSQL để lấy: project metadata, overall KPIs, sentiment distribution, aspect breakdown, competitor comparison, time-series trend.

- Web UI render dashboard với KPI cards, pie chart, bar chart, comparison table, và line chart.

==== 5.5.4.2 Drilldown Details

#align(center)[
  #image("../images/sequence/uc4_result_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 2: Drilldown vào chi tiết posts_])
#image_counter.step()

Luồng xử lý:

- User click vào aspect hoặc competitor để filter posts.

- Web UI request posts list với filters từ Project API.

- User click vào post cụ thể để xem full details.

- Project API query post data và comments từ PostgreSQL.

- Web UI hiển thị modal với full content, aspect-level sentiment, keywords, impact breakdown, và top comments.

=== 5.5.5 UC-05: Quản lý danh sách Projects

UC-05 mô tả quy trình quản lý danh sách Projects của Marketing Analyst, bao gồm xem, lọc, tìm kiếm, và điều hướng đến các chức năng khác tùy theo trạng thái Project. Đây là entry point chính của hệ thống sau khi user đăng nhập.

==== 5.5.5.1 List View và Filtering

#align(center)[
  #image("../images/sequence/uc5_list_part_1_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 1-1: Projects List View và Filtering_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc5_list_part_1_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 1-2: Projects List View và Filtering_]
)
#image_counter.step()

Luồng xử lý:

- User navigate đến Projects page từ navigation menu hoặc sau login.

- Web UI gửi GET request đến Project Service với JWT authentication.

- Project Service query PostgreSQL với filters: created_by = user_id AND deleted_at IS NULL.

- Trả về danh sách Projects với metadata: tên, status badge, ngày tạo, last_updated, preview brand keywords (3 keywords đầu).

- Web UI render Projects list với filters UI: status dropdown, search box, sort options.

- User áp dụng filters và hệ thống query lại với WHERE clause tương ứng.

- Nếu có > 50 projects thì apply pagination với 20 items/page và infinite scroll.

==== 5.5.5.2 Navigation và Actions

#align(center)[
  #image("../images/sequence/uc5_list_part_2_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 2-1: Status-based Navigation và Actions_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc5_list_part_2_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 2-2: Status-based Navigation và Actions_]
)
#image_counter.step()

Luồng xử lý:

- User click vào Project card hoặc action button.

- Web UI check status và navigate accordingly:
  - Draft → UC-01 (Edit configuration) hoặc UC-03 (Execute)
  - Running → UC-03 (Monitor progress page)
  - Completed → UC-04 (View dashboard)
  - Failed → UC-03 (Retry with same config)

- User có thể click "Xuất báo cáo" button (chỉ hiện với Completed status) → Navigate to UC-06.

- User có thể click "Xóa" button → Hiển thị confirmation dialog.

- Nếu confirm delete: Project Service soft delete (set deleted_at = NOW()), Project biến mất khỏi list, hiển thị toast "Đã xóa Project".

- Running projects không có nút "Xóa" (button disabled theo business rule).

=== 5.5.6 UC-06: Xuất báo cáo

UC-06 mô tả quy trình xuất báo cáo phân tích ở nhiều định dạng (PDF, Excel, CSV). Marketing Analyst có thể tùy chỉnh nội dung báo cáo, chọn khoảng thời gian dữ liệu, và tải file về máy. Hệ thống xử lý export request bất đồng bộ để không block UI, sau đó thông báo cho user khi file sẵn sàng.

==== 5.5.6.1 Export Configuration và Request

#align(center)[
  #image("../images/sequence/uc6_export_part_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 1: Export Configuration và Submission_]
)
#image_counter.step()

Luồng xử lý:

- User đang xem Dashboard (UC-04) và click nút Xuất báo cáo.

- Web UI hiển thị Export Configuration Dialog với các options: định dạng file (PDF, Excel, CSV), khoảng thời gian dữ liệu (toàn bộ hoặc tùy chỉnh), sections cần export (Overview, Sentiment Analysis, Competitor Comparison, Crisis Posts).

- User chọn options và click Xuất báo cáo.

- Web UI validate input và gửi POST request đến Project Service endpoint POST /api/v1/projects/:id/export.

- Project Service verify ownership (project.created_by = user_id) và validate export configuration.

- Project Service tạo export_request record trong PostgreSQL với status pending và enqueue export job.

- Publish export.requested event vào RabbitMQ queue export.jobs.

- Trả về HTTP 202 Accepted với export_request_id, Web UI đóng dialog và hiển thị toast Báo cáo đang được tạo, bạn sẽ nhận thông báo khi hoàn tất.

==== 5.5.6.2 Report Generation và Storage

#align(center)[
  #image("../images/sequence/uc6_export_part_2_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 2-1: Report Generation Pipeline_])
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc6_export_part_2_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 2-2: Report Generation Pipeline_])
#image_counter.step()

Luồng xử lý:

- Export Worker Service consume export.requested event từ RabbitMQ.

- Query analytics data từ PostgreSQL dựa trên project_id và date_range filters.

- Generate report file theo định dạng được chọn:
  - PDF: Sử dụng template engine (e.g., WeasyPrint) để render HTML → PDF với charts và tables.
  - Excel: Sử dụng library (e.g., openpyxl) để tạo spreadsheet với multiple sheets.
  - CSV: Export raw data với comma-separated format.

- Upload generated file lên MinIO bucket reports/ với object key projects/{project_id}/exports/{export_request_id}.{format}.

- Generate pre-signed download URL với 7-day expiry từ MinIO.

- Update export_request record trong PostgreSQL: status = completed, download_url, file_size, completed_at = NOW().

- Publish export.completed event vào RabbitMQ với download_url payload.

==== 5.5.6.3 Notification và Download

#align(center)[
  #image("../images/sequence/uc6_export_part_3_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 3-1: User Notification và File Download_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc6_export_part_3_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 3-2: User Notification và File Download_]
)
#image_counter.step()

Luồng xử lý:

- WebSocket Service consume export.completed event từ RabbitMQ hoặc receive notification qua Redis Pub/Sub.

- Forward notification message đến connected client (nếu user đang online).

- Web UI hiển thị notification banner Báo cáo của bạn đã sẵn sàng với link Download.

- User click Download link hoặc navigate đến Export History page.

- Web UI gửi GET request đến Project Service /api/v1/projects/:id/exports/:export_id.

- Project Service query export_request từ PostgreSQL, verify ownership và download_url chưa expire.

- Trả về download_url (MinIO pre-signed URL).

- Web UI trigger browser download từ MinIO URL, file được tải về máy user với tên {project_name}_report_{date}.{format}.

Exception Handling: Nếu export job fails (timeout > 10 phút, database error, out of memory), Export Worker update status = failed, reason, và publish export.failed event. User nhận notification Tạo báo cáo thất bại, vui lòng thử lại.

=== 5.5.7 UC-07: Phát hiện trend tự động

UC-07 mô tả quy trình tự động phát hiện trending topics thông qua Kubernetes CronJob chạy hàng ngày lúc 2:00 AM.

==== 5.5.7.1 Cron Trigger và Crawling

#align(center)[
  #image("../images/sequence/uc7_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 1: Cron Trigger và Trend Crawling_])
#image_counter.step()

Luồng xử lý:

- Kubernetes CronJob trigger Trend Service.

- Trend Service tạo trend_run record và initialize Redis state.

- Request trending data từ TikTok và YouTube Crawler Services.

- Nếu gặp rate-limit, apply exponential backoff và retry. Nếu vẫn fail thì mark is_partial_result = true và continue với remaining platforms.

==== 5.5.7.2 Scoring và Storage

#align(center)[
  #image("../images/sequence/uc7_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 2: Trend Scoring và Storage_])
#image_counter.step()

Luồng xử lý:

- Normalize metadata từ các platforms thành unified schema.

- Calculate trend score: score = engagement_rate × velocity × 100.

- Rank và filter top 50 per platform, deduplicate cross-platform.

- Batch insert vào PostgreSQL và cache latest run_id trong Redis.

- Broadcast notification đến users.

==== 5.5.7.3 User Views Trends

#align(center)[
  #image("../images/sequence/uc7_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 3: User Views Trend Dashboard_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Trends page.

- Trend Service fetch latest run_id từ Redis cache, query trends từ PostgreSQL.

- Web UI render Trend Dashboard với filters.

- User click vào trend để xem details và related posts từ own projects.

=== 5.5.8 UC-08: Phát hiện khủng hoảng

UC-08 mô tả cơ chế tự động phát hiện và cảnh báo các bài viết có nguy cơ gây khủng hoảng thương hiệu. Hệ thống sử dụng triple-check logic (Intent + Sentiment + Impact) để identify crisis posts.

==== 5.5.8.1 Analytics Pipeline và Crisis Detection

#align(center)[
  #image("../images/sequence/uc8_part_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 1: Analytics Pipeline và Crisis Detection_]
)
#image_counter.step()

Luồng xử lý:

- Analytics Service chạy full pipeline cho mỗi post.

- Sau khi save vào PostgreSQL, check triple-check criteria: Intent = CRISIS, Sentiment = NEGATIVE hoặc VERY_NEGATIVE, Risk Level = HIGH hoặc CRITICAL.

- Nếu thỏa mãn cả 3 điều kiện thì trigger crisis alert.

==== 5.5.8.2 Crisis Alert Publishing

#align(center)[
  #image("../images/sequence/uc8_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 2: Crisis Alert Publishing_])
#image_counter.step()

Luồng xử lý:

- Build alert payload với post details, metrics, và analytics results.

- Publish crisis.detected event vào RabbitMQ với high priority.

- Đồng thời publish vào Redis Pub/Sub để ensure real-time delivery.

==== 5.5.8.3 User Receives Alert

#align(center)[
  #image("../images/sequence/uc8_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 3: User Receives Real-time Alert_])
#image_counter.step()

Luồng xử lý:

- WebSocket Service receive message từ Redis Pub/Sub và forward đến connected client.

- Web UI hiển thị notification banner, play alert sound, show browser notification, và update unread count badge.

==== 5.5.8.4 Crisis Dashboard và Response

#align(center)[
  #image("../images/sequence/uc8_part_4.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 4: Crisis Dashboard và Response_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Crisis Dashboard.

- Project API query crisis posts từ PostgreSQL với filters.

- Web UI render dashboard với crisis posts list sorted by impact score.

- User click vào post để xem details và thực hiện actions như mark as handled, export, hoặc share với team.

=== Tổng kết

Section này đã mô tả các Sequence Diagrams cho 8 Use Cases chính của hệ thống SMAP:

- UC-01 Cấu hình Project: Luồng tạo project với draft status.

- UC-02 Dry-run: Sampling strategy để test keywords.

- UC-03 Khởi chạy và Giám sát: Transaction-like flow với rollback mechanism.

- UC-04 Xem kết quả: Dashboard aggregations và drilldown.

- UC-05 Quản lý danh sách Projects: List view với filtering, sorting, status-based navigation và soft delete.

- UC-06 Xuất báo cáo: Async export workflow với multiple formats (PDF, Excel, CSV) và MinIO storage.

- UC-07 Trend Detection: Cron-based crawling với scoring.

- UC-08 Crisis Detection: Triple-check logic với multi-channel alerting.

Các sequence diagrams thể hiện rõ event-driven architecture, async processing patterns, và real-time communication mechanisms của hệ thống.

