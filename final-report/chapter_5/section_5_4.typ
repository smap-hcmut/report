// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.4 Thiết kế cơ sở dữ liệu

Section này mô tả thiết kế dữ liệu của hệ thống SMAP, bao gồm chiến lược lựa chọn storage, schema dữ liệu theo từng service và các pattern quản lý dữ liệu phân tán.

=== 5.4.1 Chiến lược lựa chọn Storage

Thiết kế dữ liệu của SMAP không thể dựa trên một database duy nhất vì hệ thống có nhiều loại workload khác nhau: dữ liệu nghiệp vụ cần transaction, raw crawl artifact có kích thước thay đổi, metadata bán cấu trúc cần linh hoạt, dữ liệu truy hồi ngữ nghĩa cần vector index, và notification/session/cache cần latency thấp. Vì vậy, lựa chọn storage được đánh giá theo từng nhóm nhu cầu trước khi chốt kiến trúc lưu trữ cuối cùng.

==== 5.4.1.1 Tiêu chí đánh giá

Các phương án lưu trữ được so sánh theo sáu tiêu chí chính:

- Transactional consistency: mức độ phù hợp với dữ liệu cần ACID, constraint, index và transaction.
- Semi-structured flexibility: khả năng lưu metadata hoặc payload có cấu trúc thay đổi theo platform/domain.
- Large artifact handling: khả năng lưu raw crawl output hoặc report artifact mà không làm phình message queue hoặc bảng quan hệ.
- Retrieval model: mức độ phù hợp với relational query, cache lookup, graph traversal hoặc semantic vector search.
- Operational complexity: số lượng hệ thống phải vận hành, backup, monitor và migrate.
- Service ownership: khả năng giữ ranh giới dữ liệu theo service boundary và tránh coupling trực tiếp giữa các bounded context.

==== 5.4.1.2 So sánh các phương án lưu trữ

#context (align(center)[_Bảng #table_counter.display(): So sánh các phương án lưu trữ cho SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.24fr, 0.26fr, 0.24fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phương án*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Workload phù hợp*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Điểm mạnh*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trade-off*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Vai trò trong SMAP*],

    table.cell(align: horizon, inset: (y: 0.8em))[PostgreSQL],
    table.cell(align: horizon, inset: (y: 0.8em))[Metadata nghiệp vụ, lineage, analytics rows, conversation/report tracking],
    table.cell(align: horizon, inset: (y: 0.8em))[ACID, schema rõ ràng, FK nội bộ schema, index mạnh, JSONB cho metadata linh hoạt],
    table.cell(align: horizon, inset: (y: 0.8em))[Không tối ưu cho raw artifact lớn hoặc vector similarity search; cross-service FK vẫn phải tránh],
    table.cell(align: horizon, inset: (y: 0.8em))[Storage chính cho dữ liệu có cấu trúc],

    table.cell(align: horizon, inset: (y: 0.8em))[MongoDB],
    table.cell(align: horizon, inset: (y: 0.8em))[Document payload linh hoạt, dữ liệu bán cấu trúc thay đổi thường xuyên],
    table.cell(align: horizon, inset: (y: 0.8em))[Schema linh hoạt, dễ lưu document theo platform],
    table.cell(align: horizon, inset: (y: 0.8em))[Tăng thêm một database vận hành; raw crawl artifact vẫn phù hợp hơn với object storage; metadata quan hệ vẫn cần constraint],
    table.cell(align: horizon, inset: (y: 0.8em))[Không chọn làm storage chính],

    table.cell(align: horizon, inset: (y: 0.8em))[Neo4j],
    table.cell(align: horizon, inset: (y: 0.8em))[Graph traversal, relationship discovery, entity graph nhiều bậc],
    table.cell(align: horizon, inset: (y: 0.8em))[Mạnh khi quan hệ giữa actor, topic, campaign và entity là trung tâm của truy vấn],
    table.cell(align: horizon, inset: (y: 0.8em))[Các quan hệ chính của SMAP vẫn được xử lý tốt bằng relational model và vector retrieval; thêm Neo4j làm tăng chi phí vận hành],
    table.cell(align: horizon, inset: (y: 0.8em))[Không chọn cho phạm vi hiện tại],

    table.cell(align: horizon, inset: (y: 0.8em))[Redis],
    table.cell(align: horizon, inset: (y: 0.8em))[Session, cache, registry nhỏ, Pub/Sub, state ngắn hạn],
    table.cell(align: horizon, inset: (y: 0.8em))[Latency thấp, TTL, atomic operations, phù hợp dữ liệu tạm],
    table.cell(align: horizon, inset: (y: 0.8em))[Không thay thế durable database; dữ liệu cần có nguồn bền vững để tái tạo khi cache mất],
    table.cell(align: horizon, inset: (y: 0.8em))[Cache/session/PubSub layer],

    table.cell(align: horizon, inset: (y: 0.8em))[MinIO / S3-compatible object storage],
    table.cell(align: horizon, inset: (y: 0.8em))[Raw crawl artifacts, report artifacts, file output],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu object lớn tốt, tách payload khỏi queue, API S3-compatible],
    table.cell(align: horizon, inset: (y: 0.8em))[Không phù hợp cho query nghiệp vụ trực tiếp; cần metadata lineage trong database quan hệ],
    table.cell(align: horizon, inset: (y: 0.8em))[Object storage chính],

    table.cell(align: horizon, inset: (y: 0.8em))[Qdrant],
    table.cell(align: horizon, inset: (y: 0.8em))[Embedding, semantic search, RAG retrieval],
    table.cell(align: horizon, inset: (y: 0.8em))[Vector similarity search, payload filter, collection theo project],
    table.cell(align: horizon, inset: (y: 0.8em))[Không thay thế metadata store; cần đồng bộ với PostgreSQL tracking và indexing status],
    table.cell(align: horizon, inset: (y: 0.8em))[Vector store cho Knowledge Service],

    table.cell(align: horizon, inset: (y: 0.8em))[Lưu raw payload trực tiếp trong message queue],
    table.cell(align: horizon, inset: (y: 0.8em))[Task nhỏ, event metadata ngắn],
    table.cell(align: horizon, inset: (y: 0.8em))[Đơn giản vì consumer nhận đủ dữ liệu từ message],
    table.cell(align: horizon, inset: (y: 0.8em))[Làm message lớn, khó retry/replay artifact, tăng áp lực broker và memory],
    table.cell(align: horizon, inset: (y: 0.8em))[Không dùng cho raw artifact lớn],
  )
]

Từ bảng so sánh trên, SMAP chọn chiến lược polyglot persistence thay vì ép toàn bộ dữ liệu vào một database duy nhất. PostgreSQL giữ phần dữ liệu bền vững có cấu trúc; Redis giữ cache/session/state ngắn hạn; MinIO giữ artifact; Qdrant giữ vector index. MongoDB và Neo4j không được chọn làm thành phần lõi vì workload hiện tại chưa cần document database hoặc graph database riêng vượt quá khả năng kết hợp PostgreSQL JSONB, object storage và vector retrieval.

==== 5.4.1.3 Tổng quan Storage Stack

Kiến trúc lưu trữ của SMAP gồm các nhóm thành phần chính sau:

- PostgreSQL được sử dụng làm relational database chính cho metadata và dữ liệu nghiệp vụ có cấu trúc. Các schema chính gồm `identity`, `project`, `ingest`, `schema_analysis` và `knowledge`, tương ứng với dữ liệu người dùng, campaign/project, datasource/runtime lineage, analytics insights và knowledge metadata.

- Redis được sử dụng cho các state ngắn hạn và truy cập nhanh như session/auth state, token/session mapping, domain registry, search cache, embedding/search result cache và Redis Pub/Sub cho notification delivery.

- MinIO đóng vai trò object storage cho raw crawl artifacts, storage metadata của ingest runtime và các artifact báo cáo. Service xử lý chỉ trao đổi metadata hoặc reference qua message/event thay vì truyền toàn bộ raw payload qua queue.

- Qdrant được sử dụng làm vector store cho Knowledge Service. Các analytics outputs sau khi được index sẽ trở thành vector points để phục vụ semantic search, RAG chat và các truy vấn tri thức theo campaign/project scope.

- Local filesystem `output/` được sử dụng trong scapper runtime ở development mode như một biến thể triển khai của raw artifact storage, trong khi production mode dùng MinIO.

==== 5.4.1.4 Lý do lựa chọn

PostgreSQL phù hợp với các dữ liệu cần tính nhất quán và truy vấn quan hệ như user, JWT key, audit log, campaign, project, datasource, crawl target, external task, raw batch lineage, analytics insight, indexing status, conversation và report metadata. Khả năng hỗ trợ transaction, index, foreign key, enum và JSONB giúp mỗi service vừa giữ được cấu trúc dữ liệu rõ ràng, vừa có đủ độ linh hoạt cho các trường metadata bán cấu trúc.

Redis được lựa chọn cho các dữ liệu có vòng đời ngắn hoặc cần latency thấp. Trong SMAP, Redis không thay thế database quan hệ mà bổ sung cho các nhu cầu như session lookup, blacklist/session mapping, cache kết quả search, cache mapping campaign-project, cache domain registry và Pub/Sub notification. TTL và atomic operations giúp giảm tải database chính cho các dữ liệu tạm thời hoặc được tính lại từ nguồn dữ liệu bền vững.

MinIO được sử dụng cho các artifact có kích thước hoặc vòng đời không phù hợp để lưu trực tiếp trong message body hoặc bảng quan hệ. Scapper runtime ghi raw result thành artifact, Ingest Service nhận completion metadata, kiểm tra object metadata và tạo `raw_batches` lineage trước khi parse hoặc publish dữ liệu chuẩn hóa. Với S3-compatible API, MinIO cũng phù hợp cho các artifact báo cáo hoặc file output cần được truy xuất lại.

Qdrant được lựa chọn vì workload của Knowledge Service là semantic retrieval thay vì relational lookup. Vector embeddings, payload filters và collection theo project cho phép hệ thống tìm kiếm theo ngữ nghĩa trên kết quả analytics, trong khi PostgreSQL vẫn giữ phần tracking metadata như indexed documents, conversations, messages và reports.

=== 5.4.2 Identity Service

Identity Service quản lý security data cho cơ chế xác thực OAuth2/JWT của hệ thống SMAP. Ở lớp lưu trữ bền vững, service này sử dụng ba bảng chính là `users`, `jwt_keys` và `audit_logs`. Các state runtime có vòng đời ngắn như session hoặc token blacklist được giữ ở Redis theo chiến lược lưu trữ đã nêu ở mục 5.4.1, nên không xuất hiện trong relational schema của service.

==== 5.4.2.1 Database Schema

Schema `identity` được tổ chức quanh ba nhóm dữ liệu. Nhóm thứ nhất là hồ sơ người dùng đã được xác thực qua identity provider, lưu trong `users`. Nhóm thứ hai là vòng đời khóa ký JWT, lưu trong `jwt_keys` để hỗ trợ phát hành token và key rotation. Nhóm thứ ba là dữ liệu truy vết xác thực và ủy quyền, lưu trong `audit_logs` như một audit trail cục bộ của security boundary này.

Thiết kế này cho thấy Identity Service không theo mô hình username/password truyền thống, cũng không nhúng session runtime vào PostgreSQL như nguồn dữ liệu chính. Thay vào đó, PostgreSQL chỉ giữ các thực thể cần tính bền vững và truy vết lâu dài, còn session hoặc blacklist state được xử lý ở Redis layer.

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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông tin tài khoản người dùng đã đăng nhập qua OAuth2 SSO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `email` (UK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_users_email`, `idx_users_is_active`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`email` unique; `email`, `role_hash` not null],

    table.cell(align: center + horizon, inset: (y: 0.8em))[`jwt_keys`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu cặp khóa ký JWT và trạng thái vòng đời của từng key],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`kid` (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_jwt_keys_status`, `idx_jwt_keys_created_at`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`private_key`, `public_key`, `status` not null],

    table.cell(align: center + horizon, inset: (y: 0.8em))[`audit_logs`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Audit trail cho các sự kiện authentication và authorization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`id` (PK), `user_id` (FK nội bộ)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`idx_audit_logs_user_id`, `idx_audit_logs_created_at`, `idx_audit_logs_action`],
    table.cell(align: center + horizon, inset: (y: 0.8em))[`action` not null; `user_id` tham chiếu `users.id`],
  )
]

==== 5.4.2.3 Design Decisions

- Email as Principal Identifier: `users.email` là định danh duy nhất của người dùng vì service bám cơ chế OAuth2 SSO thay vì username/password truyền thống.
- Protected Role Storage: thông tin vai trò không được lưu dưới dạng role text đơn giản mà đi qua trường `role_hash`, giúp tách representation nghiệp vụ khỏi raw identity payload từ provider.
- JWT Key Lifecycle Table: `jwt_keys` được tách riêng để service có thể quản lý active, rotating và retired keys mà không trộn với bảng người dùng.
- Append-Only Audit Trail: `audit_logs` giữ dữ liệu truy vết authentication/authorization ở PostgreSQL để phục vụ audit và phân tích vận hành lâu dài.
- Redis as Runtime Complement: session lookup và token blacklist là state ngắn hạn ở Redis, còn PostgreSQL chỉ giữ các thực thể bảo mật cần tính bền vững.

=== 5.4.3 Project Service

Project Service quản lý project lifecycle với 1 table: `projects`. Bảng này sử dụng JSONB và array types nhằm hỗ trợ flexible data structure.

==== 5.4.3.1 Database Schema

#align(center)[
  #image("../images/erd/project-erd.png", width: 60%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Project Service_])
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

=== 5.4.4 Analytics Service

Analytics Service lưu kết quả phân tích NLP với 3 tables: `post_analytics`, `post_comments`, và `crawl_errors`.

==== 5.4.4.1 Database Schema

#align(center)[
  #image("../images/erd/analytic-erd.png", width: 60%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Analytics Service_])
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
- Database Schema cho từng Service: Identity (3 tables), Project (1 table), Analytics (3 tables).
- Data Management Patterns: Database per Service, Distributed State Management, Claim Check Pattern.

Các quyết định thiết kế đảm bảo Independent Scaling, Fault Isolation, và Real-time Performance.
