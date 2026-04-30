# Note - Section 5.4 Data Design

## Đã chỉnh trong lượt này

- Đã hoàn thiện toàn bộ `5.4` từ `5.4.1` đến `5.4.8` theo current implementation.
- Đã rewrite `5.4.2 Identity Service` theo schema thật của `identity-srv`.
- Đã thay mô tả cũ `users/plans/subscriptions` bằng `users`, `jwt_keys`, `audit_logs`.
- Đã thay ERD ảnh cũ của `5.4.2` bằng hình mới bám schema hiện tại của `identity-srv`.
- Đã bổ sung lại table catalog và design decisions theo mô hình OAuth2/JWT + audit trail + Redis runtime complement.
- Đã rewrite `5.4.3 Project Service` theo schema thật gồm `campaigns`, `projects`, `projects_crisis_config`.
- Đã thay ERD cũ của `Project Service` bằng hình mới bám schema hiện tại.
- Đã rewrite `5.4.4 Analytics Service` theo schema thật gồm `post_insight`, `analytics_outbox`, `analytics_run_manifest`.
- Đã thay ERD cũ của `Analytics Service` bằng hình mới bám schema hiện tại.
- Đã thêm mới `5.4.5 Ingest Service` với data design đầy đủ cho `data_sources`, `crawl_targets`, `dryrun_results`, `scheduled_jobs`, `external_tasks`, `raw_batches`, `crawl_mode_changes`.
- Đã thêm mới `5.4.6 Knowledge Service` với data design đầy đủ cho `indexed_documents`, `indexing_dlq`, `conversations`, `messages`, `reports` và các derived views vận hành.
- Đã thêm ERD mới cho `Ingest Service` và `Knowledge Service`.
- Đã đổi numbering phần cuối thành `5.4.7 Data Management Patterns` và `5.4.8 Tổng kết` để nhường chỗ cho `Ingest` và `Knowledge`.
- Bổ sung tiêu chí đánh giá storage trước khi đưa ra lựa chọn.
- Bổ sung bảng trade-off giữa PostgreSQL, MongoDB, Neo4j, Redis, MinIO/S3-compatible object storage, Qdrant và phương án lưu raw payload trực tiếp trong message queue.
- Bỏ MongoDB khỏi storage stack của report chính.
- Bổ sung Qdrant vào storage stack.
- Mở rộng PostgreSQL từ Identity/Project/Analytics sang các schema/service metadata chính gồm `identity`, `project`, `ingest`, `schema_analysis` và `knowledge`.
- Hạ Redis về đúng vai trò cache/session/domain registry/PubSub thay vì single source of truth cho toàn bộ progress.
- Mô tả MinIO theo raw artifact, completion metadata và raw batch lineage, không khẳng định Protobuf/Zstd/lifecycle/benchmark trong report chính.
- Đã rewrite hoàn toàn `5.4.7 Data Management Patterns` theo các pattern có evidence: database-per-service, artifact reference, vector-and-metadata split, async operational tracking.
- Đã rewrite `5.4.8 Tổng kết` theo storage stack và schema mới của toàn bộ chương.

## Output diagrams

- `report/final-report/images/erd/identity-erd-current.dot`
- `report/final-report/images/erd/identity-erd-current.svg`
- `report/final-report/images/erd/project-erd-current.dot`
- `report/final-report/images/erd/project-erd-current.svg`
- `report/final-report/images/erd/analytic-erd-current.dot`
- `report/final-report/images/erd/analytic-erd-current.svg`
- `report/final-report/images/erd/ingest-erd-current.dot`
- `report/final-report/images/erd/ingest-erd-current.svg`
- `report/final-report/images/erd/knowledge-erd-current.dot`
- `report/final-report/images/erd/knowledge-erd-current.svg`

Tất cả ERD mới dùng Graphviz để text/padding được căn tự động, tránh lệch chữ như SVG thủ công.

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
- `knowledge-srv/migrations/003_create_indexing_statistics_view.sql`
- `knowledge-srv/migrations/005_create_conversations_table.sql`
- `knowledge-srv/migrations/006_create_messages_table.sql`
- `knowledge-srv/migrations/007_create_reports_table.sql`
- `knowledge-srv/migrations/010_drop_notebook_tables.sql`
- `scapper-srv/app/storage.py`
- `ingest-srv/internal/execution/usecase/consumer.go`
- `knowledge-srv/internal/point/constants.go`
