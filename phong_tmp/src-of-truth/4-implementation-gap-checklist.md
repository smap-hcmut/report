# SMAP Implementation Gap Checklist

**Ngày cập nhật:** 2026-04-13  
**Tài liệu nền:** [2-state-machine.md](/Users/phongdang/Documents/GitHub/SMAP/2-state-machine.md), [3-event-contracts.md](/Users/phongdang/Documents/GitHub/SMAP/3-event-contracts.md), [6-srv-core-mismatch-report.md](/Users/phongdang/Documents/GitHub/SMAP/6-srv-core-mismatch-report.md)

## 1. Mục tiêu

Tài liệu này chốt rõ cái gì **đã có trong source** và cái gì **cần hoàn thành** để khớp target architecture. Mỗi item dùng một trong các nhãn:

- `Already in source`
- `Partially implemented`
- `Planned only`
- `Missing`

Ghi chú quan trọng: bản 2026-04-13 supersede các checklist cũ từng nói `analysis-srv` chưa parse UAP flat/canonical mới. Source hiện tại đã có parser flat ingest format và domain routing theo `domain_type_code`.

## 2. Đã Có Trong Source

### 2.1 `project-srv` / control plane

- `campaign` và `project` dùng lifecycle `PENDING | ACTIVE | PAUSED | ARCHIVED`
  - Status: `Already in source`
- `DRAFT` thuộc `project_config_status`, không phải lifecycle chính của `project.status`
  - Status: `Already in source`
- `Project` có `domain_type_code`, `entity_type`, `entity_name`, `brand`, `campaign_id`
  - Status: `Already in source`
- `project-srv` validate/list domain qua Redis-backed registry đọc key `smap:domains` do `analysis-srv` publish
  - Status: `Already in source`
- `project-srv` có `crisis-config` CRUD/module riêng
  - Status: `Already in source`
- DB schema hiện tại trong source là `project`, không phải `schema_project`
  - Status: `Already in source`
- Lifecycle publisher/client wiring với ingest đã có một phần, nhưng crisis loop end-to-end chưa hoàn chỉnh
  - Status: `Partially implemented`

### 2.2 `ingest-srv` / execution plane

- Datasource lifecycle runtime: `PENDING | READY | ACTIVE | PAUSED | FAILED | COMPLETED | ARCHIVED`
  - Status: `Already in source`
- `crawl_mode` tách riêng status: `SLEEP | NORMAL | CRISIS`
  - Status: `Already in source`
- Dry-run/onboarding/readiness logic ở mức runtime
  - Status: `Already in source`
- Project microservice client đã parse `domain_type_code`
  - Status: `Already in source`
- `domain_type_code` đã snapshot vào `external_tasks`, `raw_batches`, UAP
  - Status: `Already in source`
- UAP publish topic current là `smap.collector.output`
  - Status: `Already in source`
- Execution completion path có verify MinIO object, tạo raw batch, parse/publish UAP
  - Status: `Already in source`
- DB schema hiện tại trong source là `ingest`, không phải `schema_ingest`
  - Status: `Already in source`

### 2.3 `scapper-srv` / crawl worker

- Source có worker consume RabbitMQ task và chạy TinLikeSub handlers
  - Status: `Already in source`
- Source có storage local/MinIO theo `MODE`
  - Status: `Already in source`
- Source có publisher completion về `ingest_task_completions` / `ingest_dryrun_completions`
  - Status: `Already in source`
- README/status cũ vẫn nói MinIO/completion chưa implement, nên cần runtime/e2e verification để xác nhận production path
  - Status: `Partially implemented`

### 2.4 `analysis-srv` / intelligence plane

- Consumer app, Kafka plumbing, pipeline skeleton đã có
  - Status: `Already in source`
- UAP model có `domain_type_code`
  - Status: `Already in source`
- `UAPRecord.from_ingest_record()` đã parse ingest flat format có `identity`, `content`, `author`, `engagement`, `temporal`, `hierarchy`, `domain_type_code`, `crawl_keyword`
  - Status: `Already in source`
- Consumer server auto-detect legacy UAP vs ingest flat payload
  - Status: `Already in source`
- Domain routing theo `domain_type_code` đã có và truyền ontology overlay vào `RunContext`
  - Status: `Already in source`
- Contract publisher constants active cho:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
  - Status: `Already in source`
- `smap.analytics.output` chỉ còn xuất hiện như stale docstring/legacy mention, không phải active constant
  - Status: `Partially implemented`

### 2.5 `knowledge-srv` / reporting plane

- README/docs mô tả RAG/indexing/reporting architecture
  - Status: `Already in source`
- 3-layer topic expectation đã khớp với active constants của `analysis-srv`:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
  - Status: `Already in source`
- Cần verify schema runtime giữa publisher và consumer, không chỉ topic name
  - Status: `Partially implemented`

### 2.6 `notification-srv`

- WebSocket/Redis PubSub/Discord alert direction đã có trong docs/source
  - Status: `Already in source`
- Chưa thấy policy gắn trực tiếp với `project-srv` crisis final state
  - Status: `Missing`

## 3. Cần Hoàn Thành Để Khớp Target Architecture

### 3.1 Project và crisis ownership

- Add/chuẩn hóa persistence/model cho crisis final state tối giản `NORMAL | CRISIS`
  - Status: `Missing`
- Implement `project-srv` là owner final crisis decision
  - Status: `Missing`
- Tách rõ `analysis signal` và `project final crisis decision`
  - Status: `Missing`
- Gắn notification policy vào crisis state transitions
  - Status: `Missing`

### 3.2 Project -> Ingest control loop

- Chuẩn hóa adapter/event/command cho lifecycle `project -> ingest`
  - Status: `Partially implemented`
- Implement crisis-driven crawl mode change:
  - `NORMAL -> crawl_mode=NORMAL`
  - `CRISIS -> crawl_mode=CRISIS`
  - Status: `Missing`
- Bảo đảm idempotency/retry cho repeated mode change
  - Status: `Missing`

### 3.3 Analysis hardening và parity

- Cleanup stale legacy mention `smap.analytics.output`
  - Status: `Partially implemented`
- Harden flat UAP parser bằng tests/fixtures với payload thật từ `ingest-srv`
  - Status: `Partially implemented`
- Nâng parity với `smap-analyse` theo [6-srv-core-mismatch-report.md](/Users/phongdang/Documents/GitHub/SMAP/6-srv-core-mismatch-report.md):
  - TopicArtifactFact contract
  - ontology validator source-channel checks
  - Mention model fields/semantics
  - semantic/topic enrichers
  - Status: `Partially implemented`
- Implement outbound signal contract sang `project-srv`
  - Status: `Missing`

### 3.4 Analysis -> Knowledge contract

- Verify schema thực tế cho 3 topic `analytics.*`, không chỉ verify topic name
  - Status: `Partially implemented`
- Chốt mapping giữa:
  - post-level documents
  - insight cards
  - digest/report materials
  - gold/time-series facts
  - Status: `Partially implemented`

### 3.5 Domain / ontology governance

- Current source domain registry là `analysis-srv YAML/domain config -> Redis smap:domains -> project-srv`
  - Status: `Already in source`
- DB-managed ontology lifecycle vẫn là target future:
  - `DRAFT -> VALIDATED -> APPROVED -> ACTIVE -> RETIRED`
  - Status: `Planned only`
- Cần schema validation, semantic validation, versioning, rollback, audit trail cho ontology packs
  - Status: `Missing`
- Cần ranh giới rõ giữa:
  - `domain_type_code` registry
  - ontology pack definition
  - active ontology version per domain
  - Status: `Missing`

## 4. Priority Checklist Theo Service

### `project-srv`

- [ ] Add canonical crisis final state `NORMAL | CRISIS`
- [ ] Implement crisis transition logic from `analysis.signal.computed`
- [ ] Publish/request crawl mode changes to `ingest-srv`
- [ ] Bind notification policy to crisis started/resolved
- [ ] Keep domain registry as Redis-read current source unless ontology governance work explicitly changes ownership

### `ingest-srv`

- [ ] Standardize `project -> ingest` lifecycle/crisis command adapter
- [ ] Wire `project.crawl_mode.change_requested` to runtime `crawl_mode`
- [ ] Add idempotency/logging for crawl mode changes
- [ ] Keep `smap.collector.output` as current UAP topic unless a dedicated topic migration is approved

### `scapper-srv`

- [ ] Run/record smoke test for production `MODE=production` MinIO upload
- [ ] Run/record smoke test for completion publish to ingest queues
- [ ] Update stale README/status once runtime path is verified

### `analysis-srv`

- [ ] Cleanup stale `smap.analytics.output` docstring
- [ ] Add/keep e2e tests for flat UAP parser and domain routing
- [ ] Fix parity gaps from `6-srv-core-mismatch-report.md`
- [ ] Implement `analysis.signal.computed` outbound to `project-srv`
- [ ] Keep final crisis decision out of `analysis-srv` if following recommended ownership

### `knowledge-srv`

- [ ] Verify runtime schema for `analytics.batch.completed`
- [ ] Verify runtime schema for `analytics.insights.published`
- [ ] Verify runtime schema for `analytics.report.digest`
- [ ] Define exact mapping from analytics outputs to RAG/report/dashboard materials

### Shared contracts

- [ ] Document `smap.collector.output` as current UAP topic
- [ ] Mark `uap.record.created` as future rename only if still desired
- [ ] Lock crisis event names and minimum payloads
- [ ] Decide whether DB-managed ontology governance belongs in a new service, `analysis-srv`, or a shared admin/domain service before implementation

## 5. Done Criteria

- Docs no longer claim `analysis-srv` has no flat UAP parser or no `domain_type_code` routing.
- Docs distinguish current `analysis-srv YAML -> Redis -> project-srv` domain registry from future DB-managed ontology governance.
- Docs use `project` / `ingest` for current schema names and only mention `schema_project` / `schema_ingest` as legacy docs if needed.
- Crisis remains canonical `NORMAL | CRISIS`; anti-flapping is business rule, not extra state.
- `smap.collector.output` is current UAP topic; `uap.record.created` is target/future only.
- Remaining gaps focus on crisis ownership, control loop, output schema verification, core parity, and ontology governance.
