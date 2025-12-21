// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.4 Thiết kế cơ sở dữ liệu

Section này mô tả thiết kế cơ sở dữ liệu của hệ thống SMAP, bao gồm chiến lược lựa chọn database, ERD cho từng service, và các patterns quản lý dữ liệu phân tán.

=== 5.4.1 Chiến lược lựa chọn Database

Hệ thống SMAP áp dụng nguyên tắc Polyglot Persistence với Database per Service pattern, trong đó mỗi service sở hữu và quản lý database riêng. Điều này đảm bảo khả năng mở rộng độc lập, tự do lựa chọn công nghệ, và khả năng cô lập lỗi.

==== 5.4.1.1 Tổng quan Database

Kiến trúc lưu trữ dữ liệu của hệ thống được thiết kế theo mô hình polyglot persistence, bao gồm ba thành phần chính:

- PostgreSQL được sử dụng cho các dịch vụ Identity, Project và Analytics, đảm nhiệm lưu trữ dữ liệu nghiệp vụ cốt lõi và dữ liệu phân tích.

- Redis được triển khai như một kho lưu trữ trạng thái tạm thời, phục vụ các chức năng theo dõi tiến trình và trao đổi sự kiện thời gian thực giữa các thành phần hệ thống.

- MinIO đóng vai trò là hệ thống object storage để lưu trữ các tệp dữ liệu theo batch phát sinh trong quá trình xử lý.

==== 5.4.1.2 Lý do lựa chọn

PostgreSQL được sử dụng nhờ khả năng ACID compliance, đáp ứng yêu cầu nghiêm ngặt của các cơ chế authentication và authorization. Hệ thống foreign keys và các constraints hỗ trợ duy trì data consistency giữa các thực thể dữ liệu. Đồng thời, việc hỗ trợ kiểu dữ liệu JSONB cho phép lưu trữ các dữ liệu linh hoạt như competitor_keywords_map và aspects_breakdown mà không làm ảnh hưởng đến cấu trúc schema tổng thể.

Redis được lựa chọn nhờ khả năng sub-millisecond latency, đáp ứng yêu cầu real-time progress tracking và thỏa mãn tiêu chí AC-3 về Performance. Các atomic operations hỗ trợ cập nhật trạng thái phân tán  một cách an toàn, tránh xảy ra race conditions trong môi trường đồng thời. Bên cạnh đó, cơ chế TTL cho phép tự động auto-expire state, giúp quản lý vòng đời dữ liệu tạm thời một cách hiệu quả.

MinIO được sử dụng để lưu trữ các batch files có kích thước từ 50–500KB, vốn không phù hợp để truyền tải trực tiếp qua message queue. Cơ chế lifecycle policy cho phép tự động xóa các tệp sau 7 ngày, góp phần quản lý dung lượng lưu trữ hiệu quả. Đồng thời, việc hỗ trợ S3-compatible API mang lại tính flexibility, cho phép hệ thống dễ dàng mở rộng hoặc thay thế hạ tầng lưu trữ khi cần thiết.

=== 5.4.2 ERD Identity Service

Identity Service quản lý authentication, authorization, và subscription management với 3 tables: users, plans, và subscriptions.

==== 5.4.2.1 ERD Diagram

#align(center)[
  #image("../images/erd/identity-erd.png", width: 60%)
]
#context (align(center)[_Hình #image_counter.display(): ERD - Identity Service_])
#image_counter.step()

==== 5.4.2.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Identity Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.25fr, 0.20fr, 0.3fr, 0.2fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`users`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông tin người dùng, authentication],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `username` (UK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_users_username`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`username` unique],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`plans`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Định nghĩa subscription plans],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `code` (UK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_plans_code`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`code` unique],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`subscriptions`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý subscription của users],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `user_id` (FK), `plan_id` (FK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_subs_user_id`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FK to users, plans],
  )
]

==== 5.4.2.3 Design Decisions

- Soft Delete: Tất cả tables có `deleted_at` timestamp cho audit trail và recovery.
- Password Hashing: bcrypt với cost 10, không lưu plaintext.
- Role Encryption: Role được hash (SHA256) thành `role_hash` để enhance security.
- OTP Storage: OTP 6-digit và `otp_expired_at` lưu trong `users` table, expire sau 10 phút.

=== 5.4.3 ERD Project Service

Project Service quản lý project lifecycle với 1 table: `projects`. Bảng này sử dụng JSONB và array types nhằm hỗ trợ flexible data structure.

==== 5.4.3.1 ERD Diagram

#align(center)[
  #image("../images/erd/project-erd.png", width: 60%)
]
#context (align(center)[_Hình #image_counter.display(): ERD - Project Service_])
#image_counter.step()

==== 5.4.3.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Project Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.15fr, 0.25fr, 0.15fr, 0.30fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`projects`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông tin project theo dõi thương hiệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_projects_created_by`, `idx_projects_status`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`status` enum],
  )
]

==== 5.4.3.3 Cross-Database Relationship

`projects.created_by` tham chiếu đến `users.id` nhưng không có FK constraint vì nằm ở 2 databases khác nhau. Validation qua JWT token ở application layer.

=== 5.4.4 ERD Analytics Service

Analytics Service lưu kết quả phân tích NLP với 3 tables: `post_analytics`, `post_comments`, và `crawl_errors`.

==== 5.4.4.1 ERD Diagram

#align(center)[
  #image("../images/erd/analytic-erd.png", width: 60%)
]
#context (align(center)[_Hình #image_counter.display(): ERD - Analytics Service_])
#image_counter.step()

==== 5.4.4.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Analytics Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.27fr, 0.20fr, 0.35fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`post_analytics`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kết quả phân tích NLP cho mỗi post],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[`idx_job_id`, `idx_project_id`, `idx_platform`, `idx_brand_name`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`post_comments`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Comments với sentiment analysis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `post_id` (FK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_post_id`, `idx_sentiment`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`crawl_errors`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Errors từ crawling process],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_project_id`, `idx_error_code`],
  )
]

==== 5.4.4.3 Relationships

- post_analytics → post_comments: One-to-Many với CASCADE delete.
- post_analytics → project: Many-to-One, external reference không có FK constraint. `project_id` có thể NULL cho dry-run tasks.

==== 5.4.4.4 JSONB Fields

- aspects_breakdown: Aspect-based sentiment breakdown (product_quality, customer_service, price).
- keywords: Extracted keywords với aspects mapping và confidence score.
- impact_breakdown: Chi tiết impact calculation (engagement, reach, velocity).

==== 5.4.4.5 Design Decisions

- Nullable project_id: Support dry-run tasks không thuộc project nào.
- Separate Comments Table: Enable comment-level sentiment analysis và querying.
- Error Tracking: Separate table cho error analytics và monitoring.

=== 5.4.5 Data Management Patterns

==== 5.4.5.1 Distributed State Management (Redis)

Problem: Cần track project progress real-time across multiple services mà không tạo tight coupling.

Solution: Redis Hash với key pattern `smap:proj:{project_id}` làm Single Source of Truth cho project state.

Implementation:
- Redis DB 1 dedicated cho state management (separate from cache DB 0)
- Atomic operations: `HINCRBY`, `HSET`, `HGETALL`
- TTL 7 days, refresh khi có updates

Benefits: Latency < 100ms (p95), atomic updates không race conditions, auto-cleanup với TTL.

==== 5.4.5.2 Claim Check Pattern

Problem: Batch data (50 posts × ~10KB = ~500KB) qua RabbitMQ gây overload.

Solution: Lưu payload lớn vào MinIO, chỉ gửi reference (object key) qua RabbitMQ.

Flow:
- Producer upload batch file (Protobuf + Zstd) lên MinIO
- Publish RabbitMQ event với metadata (bucket, object_key, item_count)
- Consumer download từ MinIO, decompress và process

Benefits: Message size reduction 99.96%, queue throughput 50x faster.

==== 5.4.5.3 Event Sourcing Light Version

RabbitMQ events (`project.created`, `data.collected`, `analysis.finished`) serve as lightweight event log cho service coordination. Không phải full Event Sourcing vì events không được lưu vĩnh viễn và không có replay mechanism.

==== 5.4.5.4 CQRS Light Version

PostgreSQL write, Redis read cho project state. Write side lưu project metadata và analytics results. Read side lưu real-time progress với latency dưới 100ms. Không phải full CQRS vì không có separate read/write models.

=== 5.4.6 Tổng kết

Section này đã mô tả thiết kế cơ sở dữ liệu của hệ thống SMAP:

- Chiến lược Database: PostgreSQL, Redis, MinIO phù hợp với từng use case.
- ERD cho từng Service: Identity (3 tables), Project (1 table), Analytics (3 tables).
- Data Management Patterns: Database per Service, Distributed State Management, Claim Check Pattern.

Các quyết định thiết kế đảm bảo Independent Scaling, Fault Isolation, và Real-time Performance.
