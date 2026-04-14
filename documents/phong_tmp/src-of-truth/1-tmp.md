# SMAP Platform - Current Source Snapshot

**Ngày cập nhật:** 2026-04-13  
**Vai trò tài liệu:** working snapshot để đối chiếu source hiện tại. BRD canonical vẫn là [tong-quan.md](/Users/phongdang/Documents/GitHub/SMAP/tong-quan.md).

Tài liệu này không thay thế `tong-quan.md`; mục tiêu là giữ một bản nhìn nhanh về 7 microservices và những chỗ cần phân biệt giữa **current source** và **target architecture**.

## 1. Tổng quan

SMAP (Social Media Analytics Platform) là nền tảng social listening / market intelligence / crisis monitoring, gồm 7 service chính:

- `identity-srv`: xác thực, JWT, RBAC, audit.
- `project-srv`: business/control plane cho `Campaign -> Project -> Crisis Config`.
- `ingest-srv`: execution plane cho datasource, target, task dispatch, raw batch, UAP.
- `scapper-srv`: crawler worker/API cho TikTok/Facebook/YouTube qua TinLikeSub SDK.
- `analysis-srv`: intelligence plane cho UAP consume, NLP/enrichment, domain-aware routing, contract publishing.
- `knowledge-srv`: reporting/RAG plane cho indexing, chat, report generation.
- `notification-srv`: realtime alert/WebSocket/Discord relay.

Flow chính:

```text
user
  -> identity-srv
  -> project-srv
  -> ingest-srv
  -> scapper-srv
  -> ingest-srv
  -> analysis-srv
  -> knowledge-srv / notification-srv
```

## 2. Service Snapshot

### 2.1 `identity-srv`

Current source:

- Go service cho OAuth2/JWT/RBAC/audit.
- README hiện mô tả API, consumer, test client.
- Role chính: `ADMIN`, `ANALYST`, `VIEWER`.
- DB schema theo docs/service là `schema_identity`.

Target/cleanup note:

- Nếu muốn đơn giản hóa deployment, có thể merge consumer/test-client path theo kế hoạch riêng; không claim là source hiện đã merge.

### 2.2 `project-srv`

Current source:

- Sở hữu `campaign`, `project`, `crisis-config`.
- Business lifecycle canonical hiện là:
  - `campaign`: `PENDING | ACTIVE | PAUSED | ARCHIVED`
  - `project`: `PENDING | ACTIVE | PAUSED | ARCHIVED`
- `DRAFT` tồn tại ở `project_config_status`, không phải lifecycle chính của `project.status`.
- DB schema hiện tại trong migrations/repositories là `project`, không phải `schema_project`.
- `Project` đã có `domain_type_code`.
- Domain registry hiện là cross-service path:
  - `analysis-srv` publish domain list vào Redis key `smap:domains`
  - `project-srv` đọc Redis để validate/list domain
- `project-srv` đã có endpoint list domain ở module project.

Target note:

- `project-srv` vẫn là nơi phù hợp để own final crisis state `NORMAL | CRISIS`.
- DB-managed ontology/domain governance là target future, chưa phải current implementation.

### 2.3 `ingest-srv`

Current source:

- Sở hữu datasource/runtime lifecycle:
  - `PENDING | READY | ACTIVE | PAUSED | FAILED | COMPLETED | ARCHIVED`
- Có `crawl_mode` tách riêng runtime status:
  - `SLEEP | NORMAL | CRISIS`
- DB schema hiện tại là `ingest`, không phải `schema_ingest`.
- Project client parse `domain_type_code` từ `project-srv`.
- `domain_type_code` đã được snapshot vào:
  - `external_tasks`
  - `raw_batches`
  - UAP payload
- UAP publish topic hiện tại là `smap.collector.output`.
- Có execution completion path từ RabbitMQ, verify MinIO object, tạo raw batch và parse/publish UAP.

Target note:

- Cần chuẩn hóa event/adapter giữa `project-srv` và `ingest-srv` cho crisis-driven crawl mode.

### 2.4 `scapper-srv`

Current source:

- Python/FastAPI + RabbitMQ worker.
- Source hiện có code path:
  - consume task từ RabbitMQ
  - chạy handler theo platform/action
  - lưu result vào local hoặc MinIO tùy `MODE`
  - publish completion vào queue `ingest_task_completions` hoặc `ingest_dryrun_completions`
- README status cũ vẫn có dòng MinIO/completion “Not implemented yet”; đoạn đó cần xem là stale hoặc cần e2e verification lại với source hiện tại.

Target note:

- Cần smoke/e2e để xác nhận production path MinIO + completion thật sự chạy ổn, không chỉ có code path.

### 2.5 `analysis-srv`

Current source:

- Consumer input topic mặc định là `smap.collector.output`.
- Đã có dual/auto-detection parser:
  - legacy UAP có `uap_version`
  - ingest flat format có `identity`
- `UAPRecord` đã có `domain_type_code`.
- `UAPRecord.from_ingest_record()` parse flat ingest payload và giữ `domain_type_code`.
- Consumer server đã route domain bằng `domain_type_code`:
  - lookup domain config từ domain registry
  - set `_resolved_domain_overlay`
  - truyền ontology vào `RunContext`
- Contract publisher hiện dùng 3 topic active cho knowledge:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
- Vẫn còn stale docstring trong `analysis-srv/internal/model/insight_message.py` nhắc `smap.analytics.output`, nhưng active constants ghi rõ không dùng legacy topic đó.

Gap còn lại:

- Không còn là “chưa parse UAP canonical”.
- Gap đúng hơn là hardening/parity:
  - test/e2e contract
  - parity với `smap-analyse` core
  - ontology validator
  - Mention model
  - semantic/topic enrichment depth
  - crisis signal outbound sang `project-srv`

### 2.6 `knowledge-srv`

Current source/docs:

- Sở hữu RAG/reporting/indexing.
- README mô tả 3-layer indexing và các topic mong đợi:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
- Có Qdrant, Gemini/Voyage, MinIO report storage theo config/docs.

Gap còn lại:

- Cần verify runtime consumer schema khớp hoàn toàn với output hiện tại từ `analysis-srv`.

### 2.7 `notification-srv`

Current source/docs:

- Realtime notification hub qua WebSocket.
- Redis Pub/Sub relay.
- Discord webhook alerts.
- Event categories trong README/docs gồm:
  - `DATA_ONBOARDING`
  - `ANALYTICS_PIPELINE`
  - `CRISIS_ALERT`
  - `CAMPAIGN_EVENT`
  - `SYSTEM`

Target note:

- Cần nối alert policy vào crisis final state từ `project-srv`, tránh bắn alert trực tiếp từ raw signal nếu business state chưa chốt.

## 3. Corrected End-to-End Data Flow

```text
Browser
  -> identity-srv
  -> project-srv
       campaign/project/crisis config/domain_type_code
  -> ingest-srv
       datasource/target/dryrun/schedule/task/raw batch/UAP
  -> scapper-srv
       crawl + raw artifact + completion
  -> ingest-srv
       completion handling + UAP publish
  -> Kafka topic: smap.collector.output
  -> analysis-srv
       flat UAP parser + domain routing + NLP/enrichment
  -> Kafka topics:
       analytics.batch.completed
       analytics.insights.published
       analytics.report.digest
  -> knowledge-srv
       indexing/RAG/reporting
  -> notification-srv
       realtime alert when policy says user should know
```

## 4. Các Correction Quan Trọng So Với Note Cũ

- Không dùng `DRAFT -> ACTIVE -> PAUSED -> ARCHIVED` cho project lifecycle chính. Dùng `PENDING | ACTIVE | PAUSED | ARCHIVED`.
- Không nói `analysis-srv` chưa parse UAP mới nữa. Source hiện đã có flat ingest parser và domain routing theo `domain_type_code`.
- Không nói domain registry current source là DB table trong `project-srv`. Current source là `analysis-srv YAML/domain config -> Redis smap:domains -> project-srv`.
- Không gọi `schema_project` / `schema_ingest` là current schema của hai service này. Current migrations/repositories dùng `project` / `ingest`.
- Không gọi `smap.analytics.output` là active output topic. Active constants hiện dùng 3 topic `analytics.*`; `smap.analytics.output` chỉ còn là stale docstring/legacy mention.
- `uap.record.created` nếu xuất hiện trong docs thì chỉ là target/future rename. Current topic vẫn là `smap.collector.output`.

## 5. Việc Nên Làm Tiếp

- Cập nhật các canonical docs còn lại để bỏ claim stale về analysis UAP/domain routing.
- Thêm note vào `6-srv-core-mismatch-report.md` rằng report đó supersede các gap cũ liên quan analysis input.
- Verify e2e `scapper -> ingest` MinIO/completion path vì README và source đang lệch nhau.
- Verify `analysis -> knowledge` contract bằng test hoặc smoke runtime, vì source đã có publisher nhưng cần đảm bảo knowledge consumer đọc đúng schema.
