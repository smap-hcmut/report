// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.4 Thiết kế cơ sở dữ liệu (Database Design)

Section này mô tả chi tiết thiết kế cơ sở dữ liệu của hệ thống SMAP, bao gồm chiến lược lựa chọn database, ERD cho từng service, và các patterns quản lý dữ liệu phân tán. Nội dung này liên kết trực tiếp với Section 5.1 (Design Principles - Database per Service, Distributed State Management), Section 5.2 (System Architecture - Container Diagram với Data Stores), và Section 5.3 (Component Diagrams - Repository layers).

=== 5.4.1 Chiến lược lựa chọn Database (Database Strategy)

Hệ thống SMAP áp dụng nguyên tắc Polyglot Persistence [Fowler, 2011], sử dụng nhiều loại database khác nhau phù hợp với từng use case cụ thể. Quyết định này xuất phát từ yêu cầu AC-2 (Scalability) và AC-3 (Performance) trong Chapter 4, Section 4.3, đòi hỏi hệ thống phải xử lý được khối lượng lớn dữ liệu đa dạng với hiệu năng cao.

==== 5.4.1.1 Tổng quan kiến trúc Database

Hệ thống SMAP sử dụng kiến trúc Microservices với Database per Service pattern [Newman, 2015], trong đó mỗi service sở hữu và quản lý database riêng của mình. Điều này đảm bảo:

a. Independent Scaling: Mỗi service có thể scale database độc lập theo workload riêng (ví dụ: Analytics Service cần xử lý batch lớn, trong khi Identity Service chỉ cần xử lý authentication requests).

b. Technology Freedom: Mỗi service chọn database phù hợp nhất với đặc điểm dữ liệu của mình (ví dụ: PostgreSQL cho structured data, MongoDB cho schema-less data, Redis cho in-memory state).

c. Fault Isolation: Database crash của một service không ảnh hưởng đến các service khác, đáp ứng yêu cầu AC-1 (Availability 99.5%).

Hệ thống sử dụng 4 loại database chính:

- PostgreSQL: Relational database cho Identity, Project, và Analytics services, phù hợp với structured data và ACID requirements.
- MongoDB: Document store cho Collector Service, phù hợp với raw crawled data có schema thay đổi.
- Redis: In-memory database cho distributed state management và Pub/Sub, đảm bảo real-time performance (< 100ms latency).
- MinIO: Object storage cho batch files (Protobuf + Zstd compressed), tối ưu cho large file handling.

==== 5.4.1.2 Ma trận lựa chọn Database

#context (align(center)[_Bảng #table_counter.display(): Ma trận lựa chọn Database cho các Services_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.15fr, 0.15fr, 0.1fr, 0.25fr, 0.15fr, 0.1fr, 0.1fr),
    stroke: 0.5pt,
    align: (left, left, center, left, left, left, left),

    // Header
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Database*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Type*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lý do chọn*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đặc điểm dữ liệu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Read/Write Pattern*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Consistency*],

    // Identity Service
    table.cell(align: horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Relational],
    table.cell(align: horizon, inset: (y: 0.8em))[ACID cho auth, relational users-roles],
    table.cell(align: horizon, inset: (y: 0.8em))[Structured, normalized],
    table.cell(align: horizon, inset: (y: 0.8em))[Read-heavy (login), Write-light (registration)],
    table.cell(align: horizon, inset: (y: 0.8em))[Strong consistency],

    // Project Service
    table.cell(align: horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Relational],
    table.cell(align: horizon, inset: (y: 0.8em))[Relational projects-keywords, JSONB cho flexible data],
    table.cell(align: horizon, inset: (y: 0.8em))[Structured + JSONB],
    table.cell(align: horizon, inset: (y: 0.8em))[Read-heavy (list projects), Write-medium (CRUD)],
    table.cell(align: horizon, inset: (y: 0.8em))[Strong consistency],

    // Analytics Service
    table.cell(align: horizon, inset: (y: 0.8em))[Analytics Service],
    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Relational],
    table.cell(align: horizon, inset: (y: 0.8em))[Structured analysis results, complex queries],
    table.cell(align: horizon, inset: (y: 0.8em))[Structured + JSONB (aspects, keywords)],
    table.cell(align: horizon, inset: (y: 0.8em))[Write-heavy (batch inserts), Read-heavy (aggregations)],
    table.cell(align: horizon, inset: (y: 0.8em))[Eventual consistency (batch)],

    // Collector Service
    table.cell(align: horizon, inset: (y: 0.8em))[Collector Service],
    table.cell(align: horizon, inset: (y: 0.8em))[MongoDB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Document],
    table.cell(align: horizon, inset: (y: 0.8em))[Schema-less cho raw social data],
    table.cell(align: horizon, inset: (y: 0.8em))[Unstructured, variable schema],
    table.cell(align: horizon, inset: (y: 0.8em))[Write-heavy (crawled data), Read-light (debugging)],
    table.cell(align: horizon, inset: (y: 0.8em))[Eventual consistency],

    // State Management
    table.cell(align: horizon, inset: (y: 0.8em))[State Management],
    table.cell(align: horizon, inset: (y: 0.8em))[Redis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[In-memory],
    table.cell(align: horizon, inset: (y: 0.8em))[Fast access, atomic operations, TTL],
    table.cell(align: horizon, inset: (y: 0.8em))[Key-value, Hash],
    table.cell(align: horizon, inset: (y: 0.8em))[Read/Write-heavy (real-time updates)],
    table.cell(align: horizon, inset: (y: 0.8em))[Strong consistency (single instance)],

    // Object Storage
    table.cell(align: horizon, inset: (y: 0.8em))[Object Storage],
    table.cell(align: horizon, inset: (y: 0.8em))[MinIO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Object],
    table.cell(align: horizon, inset: (y: 0.8em))[Large files, batch data],
    table.cell(align: horizon, inset: (y: 0.8em))[Binary (Protobuf + Zstd)],
    table.cell(align: horizon, inset: (y: 0.8em))[Write-once, Read-many],
    table.cell(align: horizon, inset: (y: 0.8em))[Eventual consistency],
  )
]

==== 5.4.1.3 Lý do lựa chọn từng Database

a. PostgreSQL cho Identity, Project, và Analytics Services

PostgreSQL được chọn cho 3 services này vì các lý do sau:

- ACID Compliance: Cần thiết cho authentication, authorization, và financial transactions. Identity Service phải đảm bảo không có race conditions khi tạo user hoặc update subscription.

- Relational Integrity: Foreign keys và constraints đảm bảo data consistency. Ví dụ: `subscriptions.user_id` phải reference đến `users.id` tồn tại.

- JSONB Support: PostgreSQL hỗ trợ JSONB (Binary JSON) cho flexible data trong structured schema. Ví dụ: `projects.competitor_keywords_map` (JSONB) lưu map từ competitor name → keywords array, `post_analytics.aspects_breakdown` (JSONB) lưu aspect-based sentiment breakdown.

- Complex Queries: SQL queries với JOINs, aggregations cho analytics. Analytics Service cần query phức tạp như: "Tính average sentiment score theo brand và platform trong khoảng thời gian".

- Mature Ecosystem: ORMs (SQLBoiler cho Go, SQLAlchemy cho Python), migration tools (Alembic), và monitoring tools (pg_stat_statements) hỗ trợ tốt.

Evidence: `services/identity/migration/01_add_user_indexes.sql.sql`, `services/project/migration/01_add_project.sql`, `services/analytic/models/database.py`.

b. MongoDB cho Collector Service

MongoDB được chọn cho Collector Service vì các lý do sau:

- Schema-less: Raw crawled data có structure thay đổi theo platform (TikTok vs YouTube). Ví dụ: TikTok posts có `music_info`, YouTube posts có `video_duration`, không thể enforce schema cố định.

- Horizontal Scaling: Sharding cho large datasets. Collector Service có thể crawl hàng trăm nghìn posts mỗi project, cần scale horizontal.

- Document Model: Phù hợp với nested data (posts với comments, metadata). Một document có thể chứa toàn bộ post data với nested comments array.

- Write Performance: High write throughput cho batch inserts. Collector Service cần insert hàng nghìn documents mỗi phút.

Trade-off: Không có ACID transactions như PostgreSQL, nhưng acceptable cho raw data storage (có thể retry nếu fail).

c. Redis cho State Management

Redis được chọn cho distributed state management vì các lý do sau:

- In-Memory Speed: Sub-millisecond latency cho real-time progress tracking. WebSocket Service cần query project state với latency < 100ms (p95) để đáp ứng AC-3 (Performance).

- Atomic Operations: `HINCRBY`, `HSET` cho distributed state updates. Nhiều workers (Collector, Analytics) có thể update cùng một project state đồng thời mà không có race conditions.

- TTL Support: Auto-expire state sau khi project hoàn thành (24 hours TTL). Tránh memory leak và cleanup tự động.

- Pub/Sub: Real-time event broadcasting cho WebSocket. Redis Pub/Sub cho phép WebSocket Service subscribe vào `project:{projectID}:{userID}` topic để nhận progress updates.

Evidence: `services/project/internal/state/repository/redis/state_repo.go` - Redis Hash operations với key pattern `smap:proj:{project_id}`.

d. MinIO cho Object Storage

MinIO được chọn cho object storage vì các lý do sau:

- Large File Handling: Batch files (50-500KB) không phù hợp cho message queue. Nếu gửi 500KB qua RabbitMQ, message queue sẽ bị overload.

- Cost Efficiency: Cheaper than database storage cho binary data. PostgreSQL/MongoDB không tối ưu cho large binary files.

- Lifecycle Management: Auto-delete sau 7 ngày. MinIO lifecycle policy tự động xóa files sau khi đã được process xong.

- S3-Compatible: Dễ migrate sang AWS S3 nếu cần. MinIO API tương thích với S3, có thể switch provider mà không cần thay đổi code.

Evidence: Claim Check Pattern implementation trong `documents/chapter5/4.5.1.md` (Lines 432-581).

==== 5.4.1.4 Database per Service Pattern

Database per Service là một nguyên tắc cốt lõi trong Microservices Architecture [Newman, 2015], trong đó mỗi service sở hữu và quản lý database riêng của mình, không chia sẻ database giữa các services.

Nguyên tắc:

Mỗi service có database riêng, độc lập về schema, connection pool, và backup strategy. Services không truy cập trực tiếp vào database của service khác, chỉ giao tiếp qua well-defined APIs hoặc events.

Lợi ích:

a. Independent Scaling: Scale database theo workload của từng service. Ví dụ: Analytics Service cần scale PostgreSQL cho batch processing, trong khi Identity Service chỉ cần scale cho authentication requests.

b. Technology Freedom: Mỗi service chọn database phù hợp nhất. Ví dụ: Collector Service chọn MongoDB cho schema-less data, trong khi Identity Service chọn PostgreSQL cho ACID requirements.

c. Fault Isolation: Database crash của một service không ảnh hưởng service khác. Ví dụ: Nếu Analytics database crash, Identity và Project services vẫn hoạt động bình thường.

d. Team Autonomy: Mỗi team quản lý database của service mình, có thể deploy migrations, optimize queries, và scale độc lập.

Trade-offs:

a. No Cross-Service Queries: Không thể JOIN giữa `Identity.users` và `Project.projects`. Phải query từng service riêng và merge ở application layer.

b. Data Consistency: Phải đảm bảo consistency ở application layer. Ví dụ: `projects.created_by` phải validate user_id qua JWT token, không có FK constraint.

c. Operational Complexity: Quản lý nhiều databases (3 PostgreSQL instances, 1 MongoDB, 1 Redis, 1 MinIO) đòi hỏi monitoring và backup strategies phức tạp hơn.

Implementation trong SMAP:

- Identity Service: `identity_db` (PostgreSQL) - 3 tables: users, plans, subscriptions
- Project Service: `project_db` (PostgreSQL) - 1 table: projects
- Analytics Service: `analytics_db` (PostgreSQL) - 3 tables: post_analytics, post_comments, crawl_errors
- Collector Service: `collection_db` (MongoDB) - collections: raw_posts, raw_comments
- State Management: Redis DB 1 (separate from cache DB 0) - keys: `smap:proj:{project_id}`
- Object Storage: MinIO buckets: `collection-data`, `analytics-data`

Evidence: Section 5.2.2 (Service Decomposition) mô tả chi tiết bounded contexts và database ownership.

=== 5.4.2 ERD Identity Service

Identity Service quản lý authentication, authorization, và subscription management. Database sử dụng PostgreSQL với 3 tables chính: `users`, `plans`, và `subscriptions`. Thiết kế này đảm bảo ACID compliance cho các operations quan trọng như user registration, login, và subscription management.

==== 5.4.2.1 Tổng quan

Identity Service database được thiết kế để hỗ trợ:

a. User Management: Lưu trữ thông tin người dùng, password hashing (bcrypt), OTP verification, và role-based access control (RBAC).

b. Subscription Management: Định nghĩa subscription plans và quản lý user subscriptions với status tracking (active, trialing, cancelled, expired).

c. Data Integrity: Foreign key constraints đảm bảo `subscriptions.user_id` và `subscriptions.plan_id` reference đến records tồn tại.

==== 5.4.2.2 ERD Diagram

```mermaid
erDiagram
    USERS ||--o{ SUBSCRIPTIONS : "has"
    PLANS ||--o{ SUBSCRIPTIONS : "defines"

    USERS {
        uuid id PK
        varchar username UK "Email address"
        varchar full_name
        text password_hash "bcrypt, cost 10"
        text role_hash "Encrypted role (USER/ADMIN)"
        text avatar_url
        boolean is_active "Account verified"
        varchar otp "6-digit OTP"
        timestamp otp_expired_at
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at "Soft delete"
    }

    PLANS {
        uuid id PK
        varchar name
        varchar code UK "Unique identifier"
        text description
        int max_usage "API call limit per day"
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }

    SUBSCRIPTIONS {
        uuid id PK
        uuid user_id FK "References users.id"
        uuid plan_id FK "References plans.id"
        varchar status "trialing, active, cancelled, expired, past_due"
        timestamp trial_ends_at
        timestamp starts_at
        timestamp ends_at
        timestamp cancelled_at
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
```

// TODO: Add ERD image for Identity Service
// #figure(
//   image("../images/schema/identity-schema.png", width: 100%),
//   caption: [
//     ERD - Identity Service.
//     Mô tả cấu trúc database với 3 tables: users, plans, subscriptions. Mối quan hệ: users ← subscriptions → plans (many-to-many qua subscriptions).
//   ]
// ) <fig:identity_erd>

// #context (align(center)[_Hình #image_counter.display(): ERD - Identity Service_])
// #image_counter.step()

==== 5.4.2.3 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Identity Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.2fr, 0.3fr, 0.2fr, 0.15fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),

    // Header
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key Columns*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    // users
    table.cell(align: horizon, inset: (y: 0.8em))[`users`],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu thông tin người dùng, authentication],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK), `username` (UK)],
    table.cell(align: horizon, inset: (y: 0.8em))[`idx_users_username`, `idx_users_deleted_at`],
    table.cell(align: horizon, inset: (y: 0.8em))[`username` unique, `password_hash` NOT NULL],

    // plans
    table.cell(align: horizon, inset: (y: 0.8em))[`plans`],
    table.cell(align: horizon, inset: (y: 0.8em))[Định nghĩa subscription plans],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK), `code` (UK)],
    table.cell(align: horizon, inset: (y: 0.8em))[`idx_plans_code`, `idx_plans_deleted_at`],
    table.cell(align: horizon, inset: (y: 0.8em))[`code` unique, `max_usage` > 0],

    // subscriptions
    table.cell(align: horizon, inset: (y: 0.8em))[`subscriptions`],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý subscription của users],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK), `user_id` (FK), `plan_id` (FK)],
    table.cell(align: horizon, inset: (y: 0.8em))[`idx_subscriptions_user_id`, `idx_subscriptions_status`],
    table.cell(align: horizon, inset: (y: 0.8em))[Foreign keys to users, plans],
  )
]

==== 5.4.2.4 Relationships

a. USERS → SUBSCRIPTIONS: One-to-Many

Một user có thể có nhiều subscriptions (lịch sử subscriptions), nhưng chỉ có 1 subscription active tại một thời điểm. Foreign key `subscriptions.user_id` reference đến `users.id` với CASCADE delete (nếu user bị xóa, subscriptions cũng bị xóa).

b. PLANS → SUBSCRIPTIONS: One-to-Many

Một plan có thể được subscribe bởi nhiều users. Foreign key `subscriptions.plan_id` reference đến `plans.id` với RESTRICT delete (không thể xóa plan nếu còn subscriptions đang active).

c. Cascade Behavior

Khi user bị soft delete (`deleted_at` được set), subscriptions không bị xóa để giữ lịch sử. Tuy nhiên, nếu user bị hard delete (xóa vĩnh viễn), subscriptions sẽ bị CASCADE delete.

==== 5.4.2.5 Design Decisions

a. Soft Delete Pattern

Tất cả tables có `deleted_at` timestamp để hỗ trợ audit trail và recovery. Khi query, phải filter `WHERE deleted_at IS NULL` để loại bỏ records đã bị xóa.

Lợi ích:
- Audit trail: Biết được khi nào record bị xóa
- Recovery: Có thể restore record nếu xóa nhầm
- Historical data: Giữ lại dữ liệu lịch sử cho analytics

b. Password Hashing

Password được hash bằng bcrypt với cost 10 (DefaultCost), minimum 8 characters. Password không bao giờ được lưu plaintext trong database.

Evidence: `services/identity/pkg/encrypter/password.go` - `bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)`.

c. Role Encryption

Role được hash (SHA256) thành `role_hash` để tránh plaintext trong database. Điều này đảm bảo ngay cả khi database bị leak, attacker không thể biết role của user.

d. OTP Storage

OTP (6-digit) và `otp_expired_at` được lưu trong `users` table. OTP tự động expire sau 10 phút. Sau khi verify OTP, `otp` và `otp_expired_at` được set về NULL.

=== 5.4.3 ERD Project Service

Project Service quản lý project lifecycle (CRUD, execution, status tracking). Database sử dụng PostgreSQL với 1 table chính: `projects`. Thiết kế này tối ưu cho việc lưu trữ cấu hình project (brand keywords, competitor keywords) với flexible data structure (JSONB) và array types.

==== 5.4.3.1 Tổng quan

Project Service database được thiết kế để hỗ trợ:

a. Project Configuration: Lưu trữ thông tin project (name, description, status, date range), brand keywords, competitor keywords, và exclude keywords.

b. Flexible Data Structure: Sử dụng JSONB cho `competitor_keywords_map` để lưu map từ competitor name → keywords array, cho phép số lượng competitors và keywords thay đổi.

c. Cross-Database Relationship: `projects.created_by` tham chiếu đến `users.id` nhưng không có FK constraint (khác database), validation được thực hiện ở application layer qua JWT token.

==== 5.4.3.2 ERD Diagram

```mermaid
erDiagram
    PROJECTS {
        uuid id PK "Auto-generated UUID"
        varchar name
        text description
        varchar status "draft|active|completed|archived|cancelled"
        timestamptz from_date "Project start date"
        timestamptz to_date "Project end date"
        varchar brand_name
        text_array competitor_names "Array of competitor names"
        text_array brand_keywords "Array of brand keywords"
        jsonb competitor_keywords_map "Map: competitor -> keywords"
        text_array exclude_keywords
        uuid created_by "User ID from JWT (no FK)"
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at "Soft delete"
    }
```

// TODO: Add ERD image for Project Service (existing image: SMAP-collector.png)
// #figure(
//   image("../images/schema/SMAP-collector.png", width: 100%),
//   caption: [
//     ERD - Project Service.
//     Mô tả cấu trúc database với table projects. Lưu ý: created_by không có FK constraint vì reference đến users table ở database khác (Identity Service).
//   ]
// ) <fig:project_erd>

// #context (align(center)[_Hình #image_counter.display(): ERD - Project Service_])
// #image_counter.step()

==== 5.4.3.3 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Project Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.2fr, 0.3fr, 0.2fr, 0.15fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),

    // Header
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key Columns*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    // projects
    table.cell(align: horizon, inset: (y: 0.8em))[`projects`],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu thông tin project theo dõi thương hiệu],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[`idx_projects_created_by`, `idx_projects_status`, `idx_projects_deleted_at`],
    table.cell(align: horizon, inset: (y: 0.8em))[`status` enum, `to_date` > `from_date`],
  )
]

==== 5.4.3.4 Data Types và Constraints

a. UUID Primary Key

Sử dụng `gen_random_uuid()` cho primary key `id`. UUID đảm bảo uniqueness across distributed systems và không cần centralized ID generation.

Evidence: `services/project/migration/01_add_project.sql` - `CREATE EXTENSION IF NOT EXISTS "uuid-ossp"` và `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.

b. TEXT[] Array Type

PostgreSQL array type cho `competitor_names`, `brand_keywords`, và `exclude_keywords`. Cho phép lưu multiple values trong một column mà không cần separate table.

Ví dụ:
```sql
brand_keywords = ARRAY['VinFast', 'VF8', 'xe điện']
competitor_names = ARRAY['Tesla', 'BYD']
```

c. JSONB cho Flexible Data

`competitor_keywords_map` sử dụng JSONB để lưu map từ competitor name → keywords array. Cho phép số lượng competitors và keywords thay đổi linh hoạt.

Ví dụ:
```json
{
  "Tesla": ["Model 3", "Model Y", "xe điện Tesla"],
  "BYD": ["BYD Atto 3", "xe điện BYD"],
  "VinFast": ["VF8", "VF9"]
}
```

d. ENUM cho Status

`status` phải là một trong: `draft`, `active`, `completed`, `archived`, `cancelled`. Enum đảm bảo data integrity và dễ query.

e. TIMESTAMPTZ

Tất cả time fields (`from_date`, `to_date`, `created_at`, `updated_at`, `deleted_at`) sử dụng `TIMESTAMPTZ` (timestamp with timezone) để đảm bảo timezone-aware timestamps.

==== 5.4.3.5 Cross-Database Relationship

Logical Relationship (No Foreign Key):

`projects.created_by` tham chiếu đến `users.id` nhưng không có FK constraint vì nằm ở 2 databases khác nhau (Project Service database và Identity Service database).

Validation được thực hiện ở application layer:

a. JWT Token Validation: Khi user tạo project, JWT token chứa `user_id` được validate bởi Identity Service middleware. Nếu token invalid, request bị reject.

b. Ownership Check: Khi user query projects, system filter `WHERE created_by = user_id` (từ JWT token) để đảm bảo user chỉ thấy projects của mình.

Lợi ích:

a. Independent Scaling: Identity và Project services có thể scale databases độc lập.

b. Deploy và Maintain Riêng Biệt: Mỗi service có thể deploy migrations và optimize queries độc lập.

c. Tránh Distributed Transaction Complexity: Không cần distributed transactions để đảm bảo consistency giữa 2 databases.

Trade-off: Phải đảm bảo `created_by` validation ở application layer, không có database-level constraint.

Evidence: `services/project/internal/project/usecase/project.go` - `Create` function validate ownership qua JWT token.

=== 5.4.4 ERD Analytics Service

Analytics Service lưu trữ kết quả phân tích NLP (sentiment, intent, impact) và metadata từ crawled posts. Database sử dụng PostgreSQL với 3 tables chính: `post_analytics`, `post_comments`, và `crawl_errors`. Thiết kế này tối ưu cho việc query analytics results với complex aggregations và JSONB fields cho flexible data.

==== 5.4.4.1 Tổng quan

Analytics Service database được thiết kế để hỗ trợ:

a. Post Analytics: Lưu trữ kết quả phân tích NLP cho mỗi post (sentiment, intent, impact score, risk level, aspects breakdown, keywords).

b. Comment Analysis: Tách comments ra table riêng (`post_comments`) để enable comment-level sentiment analysis và querying.

c. Error Tracking: Lưu errors từ crawling process (`crawl_errors`) để analyze và debug.

d. Flexible Schema: Sử dụng JSONB cho `aspects_breakdown`, `keywords`, `impact_breakdown` để linh hoạt với schema changes.

==== 5.4.4.2 ERD Diagram

```mermaid
erDiagram
    post_analytics ||--o{ post_comments : "has many"
    post_analytics ||--o{ crawl_errors : "may have"

    post_analytics {
        string id PK "Content ID từ platform"
        uuid project_id FK "UUID của project (nullable for dry-run)"
        string platform "TIKTOK | YOUTUBE"
        timestamp published_at
        timestamp analyzed_at

        string overall_sentiment "POSITIVE | NEGATIVE | NEUTRAL"
        float overall_sentiment_score "-1.0 to 1.0"
        float overall_confidence "0.0 to 1.0"

        string primary_intent "REVIEW | COMPLAINT | QUESTION..."
        float intent_confidence

        float impact_score "0 to 100"
        string risk_level "LOW | MEDIUM | HIGH | CRITICAL"
        boolean is_viral
        boolean is_kol

        jsonb aspects_breakdown "Aspect-based sentiment"
        jsonb keywords "Extracted keywords"
        jsonb sentiment_probabilities
        jsonb impact_breakdown

        integer view_count
        integer like_count
        integer comment_count
        integer share_count
        integer save_count
        integer follower_count

        text content_text "Nội dung bài viết"
        text content_transcription "Transcription audio/video"
        integer media_duration
        jsonb hashtags
        text permalink

        string author_id
        string author_name
        string author_username
        text author_avatar_url
        boolean author_is_verified

        string brand_name
        string keyword

        string job_id
        integer batch_index
        string task_type "research_and_crawl"
        string keyword_source
        timestamp crawled_at
        string pipeline_version

        string fetch_status "success | error"
        string error_code
        text fetch_error
        jsonb error_details

        integer processing_time_ms
        string model_version
    }

    post_comments {
        serial id PK
        string post_id FK "FK to post_analytics"
        string comment_id "Comment ID từ platform"
        text text
        string author_name
        integer likes
        string sentiment "POSITIVE | NEGATIVE | NEUTRAL"
        float sentiment_score
        timestamp commented_at
        timestamp created_at
    }

    crawl_errors {
        serial id PK
        string content_id
        uuid project_id FK
        string job_id
        string platform
        string error_code
        string error_category
        text error_message
        jsonb error_details
        text permalink
        timestamp created_at
    }
```

// TODO: Add ERD image for Analytics Service
// #figure(
//   image("../images/schema/analytics-schema.png", width: 100%),
//   caption: [
//     ERD - Analytics Service.
//     Mô tả cấu trúc database với 3 tables: post_analytics, post_comments, crawl_errors. Mối quan hệ: post_analytics → post_comments (One-to-Many), post_analytics → crawl_errors (Zero-to-Many).
//   ]
// ) <fig:analytics_erd>

// #context (align(center)[_Hình #image_counter.display(): ERD - Analytics Service_])
// #image_counter.step()

==== 5.4.4.3 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Analytics Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.2fr, 0.25fr, 0.2fr, 0.2fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),

    // Header
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key Columns*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    // post_analytics
    table.cell(align: horizon, inset: (y: 0.8em))[`post_analytics`],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu kết quả phân tích NLP cho mỗi post],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[`idx_post_analytics_job_id`, `idx_post_analytics_project_id`, `idx_post_analytics_platform`, `idx_post_analytics_brand_name`, `idx_post_analytics_keyword`, `idx_post_analytics_author_id`, `idx_post_analytics_published_at`, `idx_post_analytics_fetch_status`],
    table.cell(align: horizon, inset: (y: 0.8em))[`platform` enum, `overall_sentiment` enum, `risk_level` enum],

    // post_comments
    table.cell(align: horizon, inset: (y: 0.8em))[`post_comments`],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu comments và sentiment analysis],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK), `post_id` (FK)],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[`idx_post_comments_post_id`, `idx_post_comments_sentiment`, `idx_post_comments_commented_at`],
    table.cell(align: horizon, inset: (y: 0.8em))[Foreign key to post_analytics (CASCADE delete)],

    // crawl_errors
    table.cell(align: horizon, inset: (y: 0.8em))[`crawl_errors`],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu errors từ crawling process],
    table.cell(align: horizon, inset: (y: 0.8em))[`id` (PK)],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[`idx_crawl_errors_project_id`, `idx_crawl_errors_error_code`, `idx_crawl_errors_job_id`],
    table.cell(align: horizon, inset: (y: 0.8em))[-],
  )
]

==== 5.4.4.4 Relationships

a. post_analytics → post_comments: One-to-Many

Một post có nhiều comments. Foreign key `post_comments.post_id` reference đến `post_analytics.id` với CASCADE delete (nếu post bị xóa, comments cũng bị xóa).

b. post_analytics → crawl_errors: Zero-to-Many

Một post có thể có error record nếu crawl fail. Không có FK constraint vì `crawl_errors.content_id` là String (content ID từ platform), không phải FK đến `post_analytics.id`.

c. post_analytics → project: Many-to-One (External Reference)

Nhiều posts thuộc một project. `post_analytics.project_id` reference đến `projects.id` nhưng không có FK constraint (khác database). `project_id` có thể NULL để support dry-run tasks.

==== 5.4.4.5 JSONB Fields

a. aspects_breakdown (JSONB)

Lưu aspect-based sentiment breakdown. Mỗi aspect có sentiment và score.

Ví dụ:
```json
{
  "product_quality": {"sentiment": "NEGATIVE", "score": -0.8},
  "customer_service": {"sentiment": "POSITIVE", "score": 0.6},
  "price": {"sentiment": "NEUTRAL", "score": 0.1}
}
```

b. keywords (JSONB)

Lưu extracted keywords với aspects mapping và confidence score.

Ví dụ:
```json
{
  "extracted": ["VinFast", "VF8", "xe điện"],
  "aspects": ["product", "price"],
  "confidence": 0.95
}
```

c. impact_breakdown (JSONB)

Lưu chi tiết impact calculation (engagement score, reach score, sentiment weight, velocity, final score).

Ví dụ:
```json
{
  "engagement_score": 85.5,
  "reach_score": 72.3,
  "sentiment_weight": -0.6,
  "velocity": 1.2,
  "final_score": 78.4
}
```

Evidence: `services/analytic/models/database.py` - JSONB columns definition và usage.

==== 5.4.4.6 Design Decisions

a. Nullable project_id

Cho phép `project_id = NULL` để support dry-run tasks (không thuộc project nào). Dry-run tasks được sử dụng để test keywords trước khi tạo project thật.

b. Separate Comments Table

Tách comments ra table riêng (`post_comments`) để enable:
- Comment-level sentiment analysis: Mỗi comment có sentiment riêng
- Querying: Dễ query comments theo sentiment, author, hoặc time range
- Scalability: Comments có thể có số lượng lớn (hàng trăm comments per post)

c. Error Tracking

`crawl_errors` table lưu errors riêng để:
- Analyze error patterns: Query errors theo error_code, platform, project_id
- Debug: Chi tiết error (error_message, error_details JSONB) giúp debug nhanh hơn
- Monitoring: Track error rate per project/platform

d. JSONB for Flexible Data

Sử dụng JSONB cho `aspects_breakdown`, `keywords`, `impact_breakdown` để:
- Schema flexibility: Có thể thêm/bớt fields mà không cần migration
- Query performance: PostgreSQL có thể index và query JSONB fields
- Storage efficiency: JSONB được compress và stored as binary

Evidence: `services/analytic/models/database.py` - JSONB columns và indexes.

=== 5.4.5 Data Management Patterns

Section này mô tả các patterns quản lý dữ liệu phân tán trong hệ thống SMAP, bao gồm Distributed State Management (Redis), Claim Check Pattern (MinIO + RabbitMQ), Event Sourcing (Light Version), và CQRS (Light Version). Các patterns này đảm bảo hệ thống có thể scale và maintain data consistency trong môi trường distributed.

==== 5.4.5.1 Database per Service Pattern

Đã mô tả chi tiết ở Section 5.4.1.4. Pattern này đảm bảo mỗi service sở hữu database riêng, không chia sẻ database giữa các services.

==== 5.4.5.2 Distributed State Management (Redis)

Problem: Cần track project progress real-time across multiple services (Project, Collector, Analytics) mà không tạo tight coupling. Nếu mỗi service query PostgreSQL để lấy project state, sẽ có vấn đề:
- Latency cao: PostgreSQL query mất 10-50ms, không đáp ứng yêu cầu < 100ms (p95) cho WebSocket updates
- Race conditions: Nhiều workers update cùng một project state đồng thời
- Tight coupling: Services phải biết database schema của nhau

Solution: Redis Hash với key pattern `smap:proj:{project_id}` làm Single Source of Truth (SSOT) cho project state.

Data Structure:

```
Key: smap:proj:{project_id}
Hash Fields:
  - status: "INITIALIZING" | "CRAWLING" | "PROCESSING" | "DONE" | "FAILED"
  - crawl_total: Integer (tổng số items cần crawl)
  - crawl_done: Integer (số items đã crawl xong)
  - crawl_errors: Integer (số items crawl bị lỗi)
  - analyze_total: Integer (tổng số items cần analyze)
  - analyze_done: Integer (số items đã analyze xong)
  - analyze_errors: Integer (số items analyze bị lỗi)
  - total: Integer (backward compatibility)
  - done: Integer (backward compatibility)
  - errors: Integer (backward compatibility)
TTL: 7 days (604800 seconds)
```

Implementation:

a. Redis DB 1: Dedicated database cho state management (separate from cache DB 0). DB 0 sử dụng `volatile-lru` eviction policy, DB 1 sử dụng `noeviction` policy để đảm bảo state không bị xóa.

b. Atomic Operations:
- `HINCRBY`: Atomic increment cho `crawl_done`, `analyze_done`, `errors`
- `HSET`: Atomic multi-field updates với pipeline
- `HGETALL`: Atomic read tất cả fields trong một round-trip

c. TTL Management: Auto-expire sau 7 days, refresh TTL khi có updates để đảm bảo active projects không bị expire sớm.

Evidence: `services/project/internal/state/repository/redis/state_repo.go`:
- `InitState`: Lines 37-73 - Initialize state với pipeline (atomic)
- `IncrementDone`: Lines 185-198 - Atomic increment với `HINCRBY`
- `RefreshTTL`: Lines 225-235 - Refresh TTL to 7 days

Benefits:

a. Real-time Progress Tracking: Latency < 100ms (p95) cho WebSocket updates, đáp ứng AC-3 (Performance).

b. Atomic Updates: Không có race conditions khi nhiều workers update cùng một project state.

c. Auto-cleanup: TTL tự động xóa state sau khi project hoàn thành, tránh memory leak.

d. Decoupled Services: Services không cần biết database schema của nhau, chỉ cần biết Redis key pattern.

==== 5.4.5.3 Claim Check Pattern

Problem: Khi gửi batch data (50 posts × ~10KB = ~500KB) qua RabbitMQ, message queue bị overload và latency tăng cao. Nếu gửi individual messages (1 message/item), queue sẽ bị quá tải và không đáp ứng AC-3 (Performance) - yêu cầu tối ưu throughput và giảm latency.

Solution: Claim Check Pattern [Hohpe & Woolf, 2003] - Lưu payload lớn vào MinIO, chỉ gửi reference (object key) qua RabbitMQ.

Flow:

a. Producer (Collector Service):
1. Upload batch file (Protobuf + Zstd compressed) lên MinIO
2. Path: `collection-data/{year}/{month}/{day}/{job_id}/batch_{index}.bin`
3. Publish RabbitMQ event với metadata:
```json
{
  "job_id": "uuid-123",
  "bucket": "collection-data",
  "object_key": "2024/12/20/uuid-123/batch_1.bin",
  "size": 10485760,
  "item_count": 50,
  "timestamp": 1733299200
}
```

b. Consumer (Analytics Service):
1. Receive event từ RabbitMQ
2. Download batch file từ MinIO bằng `object_key`
3. Decompress (Zstd) và parse (Protobuf)
4. Process items và ACK message

Benefits:

a. Message Size Reduction: 500KB → ~200 bytes (99.96% reduction). Queue chỉ cần xử lý metadata, không phải payload lớn.

b. Queue Throughput Improvement: 50x faster (smaller messages). Queue có thể process 10,000 messages/second thay vì 200 messages/second.

c. Network Bandwidth Savings: Data transfer only once (Producer → MinIO), not multiple times (Producer → Queue → Consumer). Giảm network bandwidth usage đáng kể.

Lifecycle Management:

a. MinIO Lifecycle Policy: Auto-delete files sau 7 ngày. Files đã được process xong không cần giữ lại lâu.

b. Bucket Partitioning: `year/month/day/{job_id}/` để optimize IOPS và dễ quản lý.

Evidence: `documents/chapter5/4.5.1.md` (Lines 432-581) - Claim Check Pattern details và implementation.

==== 5.4.5.4 Event Sourcing (Light Version)

Pattern: RabbitMQ events (`project.created`, `data.collected`, `analysis.finished`) serve as lightweight event log.

Not Full Event Sourcing:

a. Events không được lưu vĩnh viễn: Events chỉ tồn tại trong queue, sau khi consumed và ACKed thì bị xóa.

b. Không có event replay mechanism: Không thể replay events để rebuild state.

c. Không có event store: Không có centralized event store để query historical events.

Use Cases:

a. Service Coordination (Choreography): Services react to events mà không cần central orchestrator. Ví dụ: `project.created` event trigger Collector Service để dispatch crawl jobs.

b. Async Processing Triggers: Events trigger async processing. Ví dụ: `data.collected` event trigger Analytics Service để process batch.

c. Event-Driven State Updates: Events trigger state updates. Ví dụ: `analysis.finished` event trigger Project Service để update project status.

Evidence: Section 5.5 (Communication Patterns) mô tả chi tiết RabbitMQ topology và event schemas.

==== 5.4.5.5 CQRS (Light Version)

Pattern: PostgreSQL write, Redis read cho project state.

Write Side (PostgreSQL):

a. Project Metadata: `projects` table lưu project configuration (name, description, keywords, etc.). Write operations: CREATE, UPDATE, DELETE.

b. Analytics Results: `post_analytics` table lưu kết quả phân tích NLP. Write operations: Batch INSERT từ Analytics Service.

Read Side (Redis):

a. Real-time Progress: `smap:proj:{id}` Hash lưu real-time progress (status, done, total, errors). Read operations: `HGETALL` để lấy tất cả fields.

b. Fast Queries: Latency < 100ms (p95) cho WebSocket updates, đáp ứng AC-3 (Performance).

Not Full CQRS:

a. Không có separate read/write models: Vẫn sử dụng cùng một domain model cho cả read và write.

b. Không có eventual consistency guarantees: Redis state được update đồng bộ với PostgreSQL (không có delay).

c. Chỉ áp dụng cho real-time progress tracking: Không áp dụng cho tất cả data, chỉ cho project state.

Evidence: `services/project/internal/state/repository/redis/state_repo.go` - Redis read operations, `services/project/internal/project/usecase/project.go` - PostgreSQL write operations.

=== 5.4.6 Tổng kết và Kết luận

Section này đã mô tả chi tiết thiết kế cơ sở dữ liệu của hệ thống SMAP, bao gồm:

a. Chiến lược lựa chọn Database: Hệ thống sử dụng 4 loại database (PostgreSQL, MongoDB, Redis, MinIO) phù hợp với từng use case, đảm bảo AC-2 (Scalability) và AC-3 (Performance).

b. ERD cho từng Service: Identity Service (3 tables), Project Service (1 table), Analytics Service (3 tables) với relationships, indexes, và constraints chi tiết.

c. Data Management Patterns: Database per Service, Distributed State Management (Redis), Claim Check Pattern (MinIO + RabbitMQ), Event Sourcing (Light Version), và CQRS (Light Version).

Các quyết định thiết kế này đảm bảo:

- Independent Scaling: Mỗi service có thể scale database độc lập
- Fault Isolation: Database crash của một service không ảnh hưởng service khác
- Real-time Performance: Redis state management đảm bảo latency < 100ms (p95)
- Data Consistency: ACID compliance cho critical operations, eventual consistency cho batch processing

Forward References:

- Section 5.5: Communication Patterns (RabbitMQ topology, event schemas, WebSocket + Redis Pub/Sub)
- Chapter 6: Implementation details (migration scripts, connection pooling, backup strategies)

