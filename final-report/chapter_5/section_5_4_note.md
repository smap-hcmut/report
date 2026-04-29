# Note - Section 5.4 Data Design

## Đã chỉnh trong lượt này

- Chỉ chỉnh `5.4.1 Chiến lược lựa chọn Storage`.
- Bổ sung tiêu chí đánh giá storage trước khi đưa ra lựa chọn.
- Bổ sung bảng trade-off giữa PostgreSQL, MongoDB, Neo4j, Redis, MinIO/S3-compatible object storage, Qdrant và phương án lưu raw payload trực tiếp trong message queue.
- Bỏ MongoDB khỏi storage stack của report chính.
- Bổ sung Qdrant vào storage stack.
- Mở rộng PostgreSQL từ Identity/Project/Analytics sang các schema/service metadata chính gồm `identity`, `project`, `ingest`, `schema_analysis` và `knowledge`.
- Hạ Redis về đúng vai trò cache/session/domain registry/PubSub thay vì single source of truth cho toàn bộ progress.
- Mô tả MinIO theo raw artifact, completion metadata và raw batch lineage, không khẳng định Protobuf/Zstd/lifecycle/benchmark trong report chính.

## Chưa chỉnh trong lượt này

- `5.4.2 Identity Service` vẫn đang lệch schema thật; cần thay `plans/subscriptions/password/OTP` bằng `users`, `jwt_keys`, `audit_logs`.
- `5.4.3 Project Service` vẫn đang thiếu `campaigns` và `projects_crisis_config`.
- `5.4.4 Analytics Service` vẫn đang dùng bảng cũ `post_analytics`, `post_comments`, `crawl_errors`; cần đổi sang `post_insight`, `analytics_outbox`, `analytics_run_manifest`.
- Chưa thêm mục riêng cho `Ingest Service` data design.
- Chưa thêm mục riêng cho `Knowledge Service` data design và Qdrant/vector tracking.
- `5.4.5 Data Management Patterns` vẫn cần rewrite vì còn claim `smap:proj:{project_id}`, Protobuf/Zstd/RabbitMQ event cũ và benchmark chưa có evidence.
- `5.4.6 Tổng kết` vẫn cần sửa sau khi các mục con đã được cập nhật.

## Evidence chính đã dùng

- `identity-srv/migration/01_auth_service_schema.sql`
- `project-srv/migration/init_schema.sql`
- `project-srv/migration/000002_add_crisis_config.sql`
- `ingest-srv/migrations/001_create_schema_ingest_v1.sql`
- `analysis-srv/migration/init_db.sql`
- `analysis-srv/migration/001_create_analytics_outbox.sql`
- `analysis-srv/migration/002_create_analytics_run_manifest.sql`
- `knowledge-srv/migrations/001_create_indexed_documents_table.sql`
- `knowledge-srv/migrations/002_create_indexing_dlq_table.sql`
- `knowledge-srv/migrations/005_create_conversations_table.sql`
- `knowledge-srv/migrations/006_create_messages_table.sql`
- `knowledge-srv/migrations/007_create_reports_table.sql`
- `scapper-srv/app/storage.py`
- `ingest-srv/internal/execution/usecase/consumer.go`
