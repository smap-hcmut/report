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
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Metadata nghiệp vụ, lineage, analytics rows, conversation/report tracking],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[ACID, schema rõ ràng, FK nội bộ schema, index mạnh, JSONB cho metadata linh hoạt],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Không tối ưu cho raw artifact lớn hoặc vector similarity search; cross-service FK vẫn phải tránh],
    table.cell(align: horizon, inset: (y: 0.8em))[Storage chính cho dữ liệu có cấu trúc],

    table.cell(align: horizon, inset: (y: 0.8em))[MongoDB],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Document payload linh hoạt, dữ liệu bán cấu trúc thay đổi thường xuyên],
    table.cell(align: horizon, inset: (y: 0.8em))[Schema linh hoạt, dễ lưu document theo platform],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Tăng thêm một database vận hành; raw crawl artifact vẫn phù hợp hơn với object storage; metadata quan hệ vẫn cần constraint],
    table.cell(align: horizon, inset: (y: 0.8em))[Không chọn làm storage chính],

    table.cell(align: horizon, inset: (y: 0.8em))[Neo4j],
    table.cell(align: horizon, inset: (y: 0.8em))[Graph traversal, relationship discovery, entity graph nhiều bậc],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Mạnh khi quan hệ giữa actor, topic, campaign và entity là trung tâm của truy vấn],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Các quan hệ chính của SMAP vẫn được xử lý tốt bằng relational model và vector retrieval; thêm Neo4j làm tăng chi phí vận hành],
    table.cell(align: horizon, inset: (y: 0.8em))[Không chọn cho phạm vi hiện tại],

    table.cell(align: horizon, inset: (y: 0.8em))[Redis],
    table.cell(align: horizon, inset: (y: 0.8em))[Session, cache, registry nhỏ, Pub/Sub, state ngắn hạn],
    table.cell(align: horizon, inset: (y: 0.8em))[Latency thấp, TTL, atomic operations, phù hợp dữ liệu tạm],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Không thay thế durable database; dữ liệu cần có nguồn bền vững để tái tạo khi cache mất],
    table.cell(align: horizon, inset: (y: 0.8em))[Cache/session/PubSub layer],

    table.cell(align: horizon, inset: (y: 0.8em))[MinIO / S3-compatible object storage],
    table.cell(align: horizon, inset: (y: 0.8em))[Raw crawl artifacts, report artifacts, file output],
    table.cell(align: horizon, inset: (y: 0.8em))[Lưu object lớn tốt, tách payload khỏi queue, API S3-compatible],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Không phù hợp cho query nghiệp vụ trực tiếp; cần metadata lineage trong database quan hệ],
    table.cell(align: horizon, inset: (y: 0.8em))[Object storage chính],

    table.cell(align: horizon, inset: (y: 0.8em))[Qdrant],
    table.cell(align: horizon, inset: (y: 0.8em))[Embedding, semantic search, RAG retrieval],
    table.cell(align: horizon, inset: (y: 0.8em))[Vector similarity search, payload filter, collection theo project],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Không thay thế metadata store; cần đồng bộ với PostgreSQL tracking và indexing status],
    table.cell(align: horizon, inset: (y: 0.8em))[Vector store cho Knowledge Service],

    table.cell(align: horizon, inset: (y: 0.8em))[Lưu raw payload trực tiếp trong message queue],
    table.cell(align: horizon, inset: (y: 0.8em))[Task nhỏ, event metadata ngắn],
    table.cell(align: horizon, inset: (y: 0.8em))[Đơn giản vì consumer nhận đủ dữ liệu từ message],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Làm message lớn, khó retry/replay artifact, tăng áp lực broker và memory],
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

#align(center)[
  #image("../images/erd/identity-erd-current.svg", width: 78%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Identity Service_])
#image_counter.step()

Schema `identity` được tổ chức quanh ba nhóm dữ liệu. Nhóm thứ nhất là hồ sơ người dùng đã được xác thực qua identity provider, lưu trong `users`. Nhóm thứ hai là vòng đời khóa ký JWT, lưu trong `jwt_keys` để hỗ trợ phát hành token và key rotation. Nhóm thứ ba là dữ liệu truy vết xác thực và ủy quyền, lưu trong `audit_logs` như một audit trail cục bộ của security boundary này.

Thiết kế này cho thấy Identity Service không theo mô hình username/password truyền thống, cũng không nhúng session runtime vào PostgreSQL như nguồn dữ liệu chính. Thay vào đó, PostgreSQL chỉ giữ các thực thể cần tính bền vững và truy vết lâu dài, còn session hoặc blacklist state được xử lý ở Redis layer.

==== 5.4.2.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Identity Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.25fr, 0.20fr, 0.43fr, 0.2fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[users],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông tin tài khoản người dùng đã đăng nhập qua OAuth2 SSO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), email (UK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_users_email, idx_users_is_active],
    table.cell(align: center + horizon, inset: (y: 0.8em))[email unique; email, role_hash not null],

    table.cell(align: center + horizon, inset: (y: 0.8em))[jwt_keys],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu cặp khóa ký JWT và trạng thái vòng đời của từng key],
    table.cell(align: center + horizon, inset: (y: 0.8em))[kid (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_jwt_keys_status, idx_jwt_keys_created_at],
    table.cell(align: center + horizon, inset: (y: 0.8em))[private_key, public_key, status not null],

    table.cell(align: center + horizon, inset: (y: 0.8em))[audit_logs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Audit trail cho các sự kiện authentication và authorization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), user_id (FK nội bộ)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_audit_logs_user_id, idx_audit_logs_created_at, idx_audit_logs_action],
    table.cell(align: center + horizon, inset: (y: 0.8em))[action not null; user_id tham chiếu users.id],
  )
]

==== 5.4.2.3 Design Decisions

- Email as Principal Identifier: `users.email` là định danh duy nhất của người dùng vì service bám cơ chế OAuth2 SSO thay vì username/password truyền thống.
- Protected Role Storage: thông tin vai trò không được lưu dưới dạng role text đơn giản mà đi qua trường `role_hash`, giúp tách representation nghiệp vụ khỏi raw identity payload từ provider.
- JWT Key Lifecycle Table: `jwt_keys` được tách riêng để service có thể quản lý active, rotating và retired keys mà không trộn với bảng người dùng.
- Append-Only Audit Trail: `audit_logs` giữ dữ liệu truy vết authentication/authorization ở PostgreSQL để phục vụ audit và phân tích vận hành lâu dài.
- Redis as Runtime Complement: session lookup và token blacklist là state ngắn hạn ở Redis, còn PostgreSQL chỉ giữ các thực thể bảo mật cần tính bền vững.

=== 5.4.3 Project Service

Project Service giữ business context của campaign/project và cấu hình crisis ở schema `project`. Ở lớp dữ liệu bền vững, service này được tổ chức quanh ba thực thể chính là `campaigns`, `projects` và `projects_crisis_config`. Cấu trúc này cho phép tách rõ aggregate marketing cấp campaign, thực thể vận hành cấp project và phần cấu hình giám sát crisis theo từng project.

==== 5.4.3.1 Database Schema

#align(center)[
  #image("../images/erd/project-erd-current.svg", width: 82%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Project Service_])
#image_counter.step()

==== 5.4.3.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Project Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.28fr, 0.18fr, 0.20fr, 0.16fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[campaigns],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Aggregate cấp campaign cho hoạt động theo dõi và grouping project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_campaigns_status, idx_campaigns_created_by, idx_campaigns_date_range, GIN favorite_user_ids],
    table.cell(align: center + horizon, inset: (y: 0.8em))[status enum; soft delete qua deleted_at],

    table.cell(align: center + horizon, inset: (y: 0.8em))[projects],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thực thể project gắn campaign, entity context và trạng thái vận hành nghiệp vụ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), campaign_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_projects_campaign_id, idx_projects_status, idx_projects_config_status, idx_projects_domain_type_code, GIN favorite_user_ids],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FK nội bộ sang campaigns; status và config_status là enum],

    table.cell(align: center + horizon, inset: (y: 0.8em))[projects_crisis_config],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cấu hình trigger crisis theo từng project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project_id (PK/FK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_projects_crisis_config_status],
    table.cell(align: center + horizon, inset: (y: 0.8em))[One-to-one với projects; xóa cascade khi project bị xóa],
  )
]

==== 5.4.3.3 Relationship và Design Decisions

Thiết kế dữ liệu của Project Service bám sát business ownership. `campaigns.id -> projects.campaign_id` là quan hệ nội bộ một-nhiều bên trong cùng schema. `projects.id -> projects_crisis_config.project_id` là quan hệ một-một, trong đó `project_id` đồng thời là primary key và foreign key để đảm bảo mỗi project có tối đa một crisis configuration đang hiệu lực ở lớp dữ liệu chính.

Các trường như `created_by` ở `campaigns` và `projects` chỉ giữ external reference tới identity boundary, không có FK xuyên service. Điều này giữ nguyên nguyên tắc database-per-service trong khi vẫn cho phép application layer kiểm tra quyền hoặc user context qua JWT và internal validation.

Một quyết định quan trọng khác là tách `status` khỏi `config_status` ở `projects`. `status` phản ánh vòng đời nghiệp vụ ở mức activate/pause/archive, còn `config_status` phản ánh mức hoàn tất của các bước cấu hình như draft, onboarding hoặc dry run. Cách tách này giúp service không phải nhồi nhiều semantics khác nhau vào một cột trạng thái duy nhất.

Phần crisis configuration được giữ dưới dạng JSONB theo từng nhóm rule như keywords, volume, sentiment và influencer. Cách làm này phù hợp với tính bán cấu trúc của rule payload, nhưng ownership vẫn được neo chặt vào `project_id` để tránh biến cấu hình crisis thành một bounded context tách rời khỏi project.

=== 5.4.4 Analytics Service

Analytics Service lưu kết quả phân tích và dữ liệu điều phối lane bất đồng bộ trong schema `schema_analysis`. Ở lớp relational, ba đối tượng chính hiện tại là `post_insight`, `analytics_outbox` và `analytics_run_manifest`. Chúng phản ánh ba nhu cầu khác nhau: lưu insight đã enrich, đảm bảo publish downstream đáng tin cậy, và giữ run-level manifest cho audit hoặc replay context.

==== 5.4.4.1 Database Schema

#align(center)[
  #image("../images/erd/analytic-erd-current.svg", width: 82%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Analytics Service_])
#image_counter.step()

==== 5.4.4.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Analytics Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.30fr, 0.18fr, 0.34fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[post_insight],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Insight đã enrich cho từng nội dung hoặc mention đã qua pipeline phân tích],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_post_insight_project, idx_post_insight_platform, idx_post_insight_sentiment, GIN aspects, GIN uap_metadata],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analytics_outbox],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Transactional outbox cho Kafka delivery của các message downstream],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), run_id],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_outbox_pending],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analytics_run_manifest],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Manifest theo từng run để lưu context và hỗ trợ audit hoặc replay reasoning],
    table.cell(align: center + horizon, inset: (y: 0.8em))[run_id (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_run_manifest_project],
  )
]

==== 5.4.4.3 Data Shape và Design Decisions

`post_insight` là bảng trung tâm của analytics schema hiện tại. Thay vì tách `post_analytics` và `post_comments` thành hai bảng như bản cũ, service hiện dùng một cấu trúc insight giàu thông tin hơn, chứa nội dung, sentiment, aspects, keywords, risk, engagement, quality và processing metadata trong cùng một row. Điều này phù hợp với cách pipeline hiện tại phát sinh `NLPFact` và persist thành `post_insight`.

`analytics_outbox` và `analytics_run_manifest` không đại diện cho dữ liệu người dùng cuối mà cho nhu cầu điều phối lane bất đồng bộ. `analytics_outbox` giữ các payload chờ gửi hoặc đã gửi xuống Kafka, trong khi `analytics_run_manifest` lưu context ở mức `run_id` để service có thể truy lại batch reasoning, project scope hoặc campaign scope mà không cần đọc lại toàn bộ raw input.

Các trường bán cấu trúc như `uap_metadata`, `aspects` hoặc `risk_factors` được giữ ở JSONB thay vì bẻ thành hàng loạt bảng con. Đây là trade-off hợp lý vì dữ liệu enrichment mang tính đa dạng theo domain, model version và runtime stage, nhưng vẫn cần được query/filter ở mức vừa phải bằng GIN index.

- Direct Insight Persistence: kết quả enrichment được materialize trực tiếp thành `post_insight` thay vì chia nhỏ thành nhiều bảng comment/error cũ.
- Transactional Outbox: `analytics_outbox` là lớp đệm bền vững giữa persistence và Kafka publish để giảm rủi ro mất message downstream.
- Run-Level Audit Context: `analytics_run_manifest` giữ metadata ở cấp pipeline run thay vì trộn với từng row insight.
- External References over Cross-Service FK: `project_id`, `campaign_id` hay `source_id` được giữ như external identifiers, không tạo FK xuyên service boundary.

=== 5.4.5 Ingest Service

Ingest Service sở hữu schema `ingest`, nơi lưu cả metadata cấu hình nguồn dữ liệu lẫn lineage của runtime bất đồng bộ. Đây là phần dữ liệu phức tạp nhất trong hệ thống vì phải nối được business context của project với task dispatch, completion metadata, raw artifact storage và trạng thái publish sang analytics data plane.

==== 5.4.5.1 Database Schema

#align(center)[
  #image("../images/erd/ingest-erd-current.svg", width: 92%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Ingest Service_])
#image_counter.step()

==== 5.4.5.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Ingest Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.17fr, 0.27fr, 0.18fr, 0.22fr, 0.16fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Constraints*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[data_sources],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Root entity cho datasource theo project và loại source],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), dryrun_last_result_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_data_sources_project_deleted, idx_data_sources_status_category, GIN config, GIN mapping_rules],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Enum cho type/category/status; nhiều check constraint theo source semantics],

    table.cell(align: center + horizon, inset: (y: 0.8em))[crawl_targets],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Per-target schedule và input cụ thể cho keyword/profile/post URL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), data_source_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_crawl_targets_data_source, idx_crawl_targets_next_crawl_active, idx_crawl_targets_type],
    table.cell(align: center + horizon, inset: (y: 0.8em))[crawl_interval_minutes > 0],

    table.cell(align: center + horizon, inset: (y: 0.8em))[dryrun_results],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Bằng chứng readiness và sample output cho dry run],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), source_id (FK), target_id (FK nullable)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_dryrun_results_project_created_desc, idx_dryrun_results_source_created_desc, idx_dryrun_results_job_id],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Non-negative checks cho sample/total counts],

    table.cell(align: center + horizon, inset: (y: 0.8em))[scheduled_jobs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Job điều phối lịch chạy crawl hoặc trigger runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), source_id (FK), target_id (FK nullable)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_scheduled_jobs_status_scheduled_for, idx_scheduled_jobs_project_scheduled_for_desc, idx_scheduled_jobs_target],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Retry count non-negative; enum trigger/crawl mode],

    table.cell(align: center + horizon, inset: (y: 0.8em))[external_tasks],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Correlation layer giữa ingest runtime và worker task bên ngoài],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), task_id (UK), scheduled_job_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_external_tasks_status_created_desc, idx_external_tasks_scheduled_job_id, idx_external_tasks_target],
    table.cell(align: center + horizon, inset: (y: 0.8em))[task_id unique để chống duplicate completion],

    table.cell(align: center + horizon, inset: (y: 0.8em))[raw_batches],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Lineage của raw artifact và trạng thái publish sang UAP/analytics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), external_task_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_raw_batches_project_received_desc, idx_raw_batches_publish_status_received_desc, idx_raw_batches_checksum],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Unique (source_id, batch_id); bucket/path thay raw payload],

    table.cell(align: center + horizon, inset: (y: 0.8em))[crawl_mode_changes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Audit trail cho việc đổi crawl mode và interval],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), source_id (FK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[idx_crawl_mode_changes_source_triggered_desc, idx_crawl_mode_changes_project_triggered_desc],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Interval non-negative checks],
  )
]

==== 5.4.5.3 Lineage Model và Design Decisions

`data_sources` là root entity của ingest domain. `crawl_targets` mở rộng root này theo mô hình một datasource có nhiều target, và đây cũng là nơi per-target scheduling được giữ thay vì gói hết vào datasource row. `dryrun_results` là lớp bằng chứng readiness độc lập, cho phép service lưu lịch sử dry run và tái dùng kết quả gần nhất trong lifecycle control.

Chuỗi runtime bất đồng bộ được biểu diễn qua `scheduled_jobs -> external_tasks -> raw_batches`. `scheduled_jobs` phản ánh ý định chạy ở mức ingest runtime, `external_tasks` phản ánh task đã dispatch sang worker, còn `raw_batches` phản ánh artifact đã materialize và trạng thái publish sang analytics. Chuỗi này quan trọng vì nó cho phép trace từ project/source/target đến task ngoài, rồi đến object storage và cuối cùng đến UAP publishing.

Thiết kế dữ liệu ở đây ưu tiên reference metadata thay vì nhúng raw payload lớn vào relational rows hoặc message queue. Các cột như `storage_bucket`, `storage_path`, `checksum` và `publish_status` trong `raw_batches` là bằng chứng rõ rằng service xem object storage là nơi giữ artifact thực, còn database chỉ giữ lineage và operational state.

Các enum như `source_status`, `dryrun_status`, `job_status`, `batch_status` và `publish_status` cũng là quyết định thiết kế quan trọng. Chúng làm cho runtime lane có thể được điều phối bằng trạng thái rõ ràng ở cấp dữ liệu, thay vì chỉ dựa vào log hoặc queue state bên ngoài.

=== 5.4.6 Knowledge Service

Knowledge Service dùng mô hình polyglot persistence rõ ràng nhất trong hệ thống: PostgreSQL giữ metadata bền vững cho indexing, chat và report; Qdrant giữ vector index; Redis giữ search cache; MinIO giữ report artifact. Trong phạm vi mục 5.4 này, phần relational schema tập trung vào các bảng chính của schema `knowledge` và vai trò của chúng trong việc phối hợp với vector store.

==== 5.4.6.1 Database Schema

#align(center)[
  #image("../images/erd/knowledge-erd-current.svg", width: 92%)
]
#context (align(center)[_Hình #image_counter.display(): Database Schema - Knowledge Service_])
#image_counter.step()

==== 5.4.6.2 Table Catalog

#context (align(center)[_Bảng #table_counter.display(): Knowledge Service Tables_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.3fr, 0.28fr, 0.18fr, 0.22fr, 0.14fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Table / View*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục đích*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Key*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Indexes / Derived Object*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ghi chú*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[indexed_documents],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Tracking metadata cho record đã hoặc đang được index vào Qdrant],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), analytics_id (UK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Indexes theo project_id, batch_id, status, content_hash, created_at],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Chứa collection_name và qdrant_point_id như vector references],

    table.cell(align: center + horizon, inset: (y: 0.8em))[indexing_dlq],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dead-letter queue cho các record indexing thất bại],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Indexes theo analytics_id, batch_id, unresolved errors, retry eligibility],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giữ raw_payload để debug hoặc replay],

    table.cell(align: center + horizon, inset: (y: 0.8em))[conversations],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Session hỏi đáp đa lượt theo campaign và user],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK)],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Indexes theo (campaign_id, user_id), status, last_message_at, created_at],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scoped theo campaign thay vì project trực tiếp],

    table.cell(align: center + horizon, inset: (y: 0.8em))[messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu từng message user hoặc assistant cùng metadata truy hồi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK), conversation_id (FK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[idx_messages_conversation_created],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cascade delete theo conversation],

    table.cell(align: center + horizon, inset: (y: 0.8em))[reports],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Tracking metadata cho capability report generation ở knowledge layer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[id (PK)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Indexes theo campaign_id, user_id, status, params_hash],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Capability mở rộng ngoài FR/UC cốt lõi],

    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[indexing_stats_by_project, indexing_stats_by_batch, indexing_error_summary, indexing_health_check],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Derived views cho monitoring và vận hành indexing lane],
    table.cell(align: center + horizon, inset: (y: 0.8em))[View],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tạo từ indexed_documents và indexing_dlq],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Không phải nguồn dữ liệu gốc],
  )
]

==== 5.4.6.3 Relational Metadata, Vector Store và Design Decisions

`indexed_documents` là cầu nối giữa relational metadata và vector store. Bảng này không lưu embedding vector, mà lưu `qdrant_point_id`, `collection_name`, `content_hash`, trạng thái index và metrics xử lý. Điều đó cho phép Knowledge Service dùng Qdrant cho retrieval nhưng vẫn giữ được khả năng query operational state bằng SQL.

`indexing_dlq` đóng vai trò vùng cách ly cho các record indexing thất bại. Thay vì ghi đè lỗi lên record chính một cách mơ hồ, service giữ riêng raw payload, error type, retry_count và resolved flag để vận hành có thể retry hoặc xử lý ngoại lệ có kiểm soát.

Ở nhánh consumption đồng bộ, `conversations` và `messages` tạo thành mô hình normalized cho chat history. `conversations` giữ session-level metadata, còn `messages` giữ user message, assistant response, citations, filters_used và search metadata. Thiết kế này phù hợp với multi-turn RAG interaction hơn là nhúng toàn bộ exchange vào một blob duy nhất.

`reports` phản ánh capability mở rộng của knowledge layer. Bảng này lưu request scope, report type, params hash, artifact URL, status và metrics generation; trong khi bản thân report artifact được materialize ở object storage chứ không nhúng vào database row. Ngoài ra, migration `010` đã loại bỏ các notebook tables cũ, nên relational schema hiện tại không còn xem notebook/maestro là capability lõi của service.

=== 5.4.7 Data Management Patterns

==== 5.4.7.1 Database per Service và External Reference IDs

SMAP giữ database-per-service ở mức logical schema ownership. `identity`, `project`, `ingest`, `schema_analysis` và `knowledge` đều sở hữu dữ liệu cục bộ của mình, trong khi các liên kết xuyên service như `created_by`, `project_id`, `campaign_id` hay `source_id` chỉ được giữ như external identifiers. Cách làm này tránh FK xuyên boundary nhưng vẫn cho phép trace ở application layer.

==== 5.4.7.2 Artifact Reference Pattern

Các payload lớn không được coi là relational first-class data. Scapper runtime materialize raw output vào local filesystem ở development mode hoặc MinIO ở production mode; `ingest.raw_batches` chỉ giữ bucket/path/checksum/size và lineage metadata. Tương tự, knowledge-side reports lưu artifact URL thay vì nhúng toàn bộ báo cáo vào PostgreSQL row.

==== 5.4.7.3 Vector and Metadata Split

Knowledge retrieval được tách thành hai lớp. Qdrant giữ vector points và payload phục vụ semantic search; PostgreSQL giữ `indexed_documents`, `indexing_dlq`, `conversations`, `messages` và `reports`. Thiết kế này cho phép tối ưu retrieval model mà không đánh đổi khả năng query operational tracking bằng SQL.

==== 5.4.7.4 Async Operational Tracking

Các lane bất đồng bộ quan trọng đều có bảng tracking riêng. Ở analytics có `analytics_outbox` và `analytics_run_manifest`. Ở ingest có `dryrun_results`, `scheduled_jobs`, `external_tasks`, `raw_batches`, `crawl_mode_changes`. Ở knowledge có `indexed_documents`, `indexing_dlq` và các statistics views. Pattern chung ở đây là không để queue broker hoặc object storage trở thành nguồn trạng thái duy nhất; database giữ đủ metadata để audit, retry và reconciliation.

=== 5.4.8 Tổng kết

Thiết kế dữ liệu của SMAP là một ví dụ điển hình của polyglot persistence theo service boundary và workload. PostgreSQL giữ metadata có cấu trúc và operational tracking; Redis giữ cache, session và state ngắn hạn; MinIO giữ artifact lớn; Qdrant giữ vector index. Mỗi loại storage được chọn theo retrieval model và vòng đời dữ liệu thay vì vì một khuôn mẫu duy nhất áp cho toàn hệ thống.

Ở mức schema chi tiết, Identity Service giữ `users`, `jwt_keys`, `audit_logs`; Project Service giữ `campaigns`, `projects`, `projects_crisis_config`; Analytics Service giữ `post_insight`, `analytics_outbox`, `analytics_run_manifest`; Ingest Service giữ execution lineage quanh `data_sources`, `crawl_targets`, `dryrun_results`, `scheduled_jobs`, `external_tasks`, `raw_batches`, `crawl_mode_changes`; Knowledge Service giữ tracking, chat và report metadata quanh `indexed_documents`, `indexing_dlq`, `conversations`, `messages`, `reports` cùng các derived views vận hành.

Những lựa chọn này giúp hệ thống giữ được ranh giới ownership rõ ràng, hỗ trợ tracing cho các lane bất đồng bộ, và tránh nhét raw artifact hoặc vector retrieval vào những storage model không phù hợp. Đây cũng là nền dữ liệu để các mục giao tiếp, triển khai và traceability ở các phần sau có thể giải thích được theo current implementation thay vì theo các giả định kiến trúc cũ.
