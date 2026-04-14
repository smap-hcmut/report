# SMAP Rollout Order

**Ngày cập nhật:** 2026-04-13  
**Tài liệu nền:** [2-state-machine.md](/Users/phongdang/Documents/GitHub/SMAP/2-state-machine.md), [3-event-contracts.md](/Users/phongdang/Documents/GitHub/SMAP/3-event-contracts.md), [4-implementation-gap-checklist.md](/Users/phongdang/Documents/GitHub/SMAP/4-implementation-gap-checklist.md), [6-srv-core-mismatch-report.md](/Users/phongdang/Documents/GitHub/SMAP/6-srv-core-mismatch-report.md)

## 1. Mục tiêu

Tài liệu này chốt thứ tự rollout an toàn từ source hiện tại sang target architecture, không làm gãy:

- `project -> ingest -> analysis -> knowledge`
- `domain_type_code` propagation
- crisis feedback loop
- reporting/RAG pipeline

Ghi chú quan trọng: source hiện tại **đã có** parser ingest flat UAP và domain routing theo `domain_type_code` trong `analysis-srv`. Vì vậy Phase 1 không còn là “build parser từ đầu”, mà là verify/harden/parity.

## 2. Thứ Tự Rollout Khuyến Nghị

1. **Freeze source snapshot và cleanup misleading docs**
2. **Verify/harden `ingest -> analysis` UAP + domain routing**
3. **Verify/align `analysis -> knowledge` output contracts**
4. **Hoàn thiện crisis final state ownership ở `project-srv`**
5. **Nối crisis control từ `project-srv` xuống `ingest-srv`**
6. **Nối notification theo business crisis state**
7. **Mở ontology governance / DB-managed config như target future**

Nếu chỉ làm một việc đầu tiên, hãy làm:

**verify/harden UAP flat parser + domain routing hiện có trong `analysis-srv`, rồi khóa test contract với payload thật từ `ingest-srv`.**

## 3. Phase-by-phase

## Phase 0 - Source Snapshot và Contract Freeze

### Mục tiêu

- thống nhất vocabulary
- phân biệt current source vs target architecture
- loại bỏ claim stale trong docs

### Việc cần làm

- chốt `2-state-machine.md` là state/control reference
- chốt `3-event-contracts.md` là contract target/current reference
- chốt `4-implementation-gap-checklist.md` là baseline gap mới
- ghi rõ current source:
  - UAP topic: `smap.collector.output`
  - analysis output topics: `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest`
  - domain registry: `analysis-srv YAML/domain config -> Redis smap:domains -> project-srv`
  - current schemas: `project` và `ingest`

### Gate để qua phase

- không còn doc root nào claim `analysis-srv` chưa parse flat UAP hoặc chưa có `domain_type_code`
- `uap.record.created` nếu còn nhắc thì phải là target/future only
- `schema_project` / `schema_ingest` chỉ còn trong legacy docs hoặc proposal cũ

## Phase 1 - Verify/Harden `ingest -> analysis`

### Mục tiêu

Xác nhận source path hiện có thật sự hoạt động ổn với payload từ `ingest-srv`:

- `smap.collector.output`
- ingest flat UAP format
- `domain_type_code`
- domain routing / ontology overlay

### Việc cần làm

- thêm hoặc chạy tests cho `UAPRecord.from_ingest_record()`
- thêm hoặc chạy e2e test `domain_type_code -> domain_overlay`
- dùng fixture lấy từ UAP payload thật của `ingest-srv`
- cleanup stale docstring `smap.analytics.output`
- đo/log parse failure, unknown format, missing `project_id`, missing `domain_type_code`
- xác nhận fallback `_default` domain hoạt động khi domain code unknown/empty

### Gate để qua phase

- `analysis-srv` consume được flat UAP từ `ingest-srv`
- `domain_type_code` xuất hiện trong runtime processing
- domain overlay không rỗng
- legacy/stale topic mention không còn gây hiểu nhầm

### Rollback

- giữ dual parser hiện có:
  - legacy `uap_version`
  - ingest flat `identity`

## Phase 2 - Verify/Align `analysis -> knowledge`

### Mục tiêu

Khóa output contract cho reporting/RAG:

- `analytics.batch.completed`
- `analytics.insights.published`
- `analytics.report.digest`

### Việc cần làm

- verify runtime publisher của `analysis-srv` publish đủ 3 topic theo active constants
- verify `knowledge-srv` consumer đọc đúng topic/schema thực tế
- chốt mapping:
  - post-level enriched documents
  - insight cards
  - digest/report materials
  - gold/time-series facts
- xử lý parity gap trong `6-srv-core-mismatch-report.md` nếu ảnh hưởng schema output

### Gate để qua phase

- có smoke/e2e cho ít nhất `analytics.batch.completed` và `analytics.report.digest`
- `knowledge-srv` index/report không cần workaround thủ công
- schema không còn phụ thuộc legacy `smap.analytics.output`

### Rollback

- giữ contract publisher backward-compatible trong một giai đoạn
- nếu cần, chỉ tắt consumer mới chứ không rollback UAP input path

## Phase 3 - Crisis Final State ở `project-srv`

### Mục tiêu

Đưa `project-srv` thành owner final crisis state:

- `NORMAL`
- `CRISIS`

### Việc cần làm

- thêm model/persistence cho crisis final state nếu chưa có
- implement transition:
  - enter crisis
  - resolve crisis
- apply crisis config/policy khi nhận analysis signal
- đảm bảo anti-flapping là business rule, không thêm state trung gian
- chạy shadow mode trước: tính state nhưng chưa điều khiển ingest

### Gate để qua phase

- `project-srv` nhận signal và tính state đúng
- transition idempotent
- có audit/log vì sao chuyển crisis state

### Rollback

- giữ crisis evaluation ở shadow/read-only mode
- không phát control event xuống ingest

## Phase 4 - Crisis Control `project -> ingest`

### Mục tiêu

Cho phép `project-srv` điều khiển runtime `crawl_mode` ở `ingest-srv` dựa trên crisis final state.

### Việc cần làm

- implement/chuẩn hóa handler cho `project.crawl_mode.change_requested`
- map:
  - `NORMAL -> crawl_mode=NORMAL`
  - `CRISIS -> crawl_mode=CRISIS`
- idempotent mode change nếu event retry
- log mode cũ/mới, reason, `project_id`, `domain_type_code`

### Gate để qua phase

- crisis started đổi được crawl mode sang `CRISIS`
- crisis resolved đổi được crawl mode về `NORMAL`
- không có repeated update storm

### Rollback

- disable consumer/handler control event
- fallback toàn hệ về `crawl_mode=NORMAL`

## Phase 5 - Notification

### Mục tiêu

Thông báo user theo business state đã chốt, không spam theo raw signal.

### Việc cần làm

- bind notification vào:
  - crisis started
  - crisis resolved
  - optional negative spike nếu policy cho phép
- include context:
  - `project_id`
  - `campaign_id`
  - `domain_type_code`
  - severity/reason
- dedup alert repeated events

### Gate để qua phase

- user nhận alert đúng lúc
- notification phản ánh `project-srv` crisis state, không phản ánh raw signal chưa được chốt

### Rollback

- tắt notification publisher/consumer, giữ crisis loop nội bộ chạy tiếp

## Phase 6 - Ontology Governance / Domain Config Lifecycle

### Mục tiêu

Mở rộng từ current source `analysis-srv YAML/domain config -> Redis -> project-srv` sang governance mạnh hơn nếu sản phẩm cần admin-editable ontology.

### Việc cần làm

- quyết định ownership trước khi implement:
  - giữ ở `analysis-srv`
  - tạo domain/config service riêng
  - hoặc DB-managed module có API admin riêng
- thiết kế lifecycle:
  - `DRAFT`
  - `VALIDATED`
  - `APPROVED`
  - `ACTIVE`
  - `RETIRED`
- thêm validation:
  - schema validation
  - semantic validation
  - source-channel checks
  - uniqueness/overlap checks
- thêm versioning/rollback/audit trail
- gắn `domain_type_code -> active ontology pack`

### Vì sao phase này đi sau

- domain propagation hiện đã có source path hoạt động
- governance là bài toán product/admin/quality lớn hơn, không nên chặn crisis/reporting contract hardening

### Rollback

- revert active version pointer
- fallback về YAML/domain config hiện tại

## 4. Rủi Ro Chính

### Rủi ro 1: Docs làm implementer build lại thứ đã có

- Giảm rủi ro: cập nhật rõ `analysis-srv` đã parse flat UAP và route domain.

### Rủi ro 2: Mở crisis control quá sớm

- Giảm rủi ro: shadow mode ở `project-srv` trước khi phát control event xuống ingest.

### Rủi ro 3: Topic name lẫn current và future

- Giảm rủi ro: `smap.collector.output` là current; `uap.record.created` chỉ là future rename.

### Rủi ro 4: Ontology DB-managed bị rác

- Giảm rủi ro: không cho edit trực tiếp thành active; dùng draft/validated/approved/active + rollback.

### Rủi ro 5: README/source mismatch ở `scapper-srv`

- Giảm rủi ro: verify e2e MinIO/completion rồi cập nhật README/status.

## 5. Go/No-Go Checklist

- [ ] `analysis-srv` flat UAP parser có test với payload thật từ `ingest-srv`
- [ ] `domain_type_code` route ra domain overlay đúng
- [ ] `analysis -> knowledge` 3 topic có smoke/e2e
- [ ] stale `smap.analytics.output` mention được cleanup hoặc marked legacy
- [ ] crisis state chỉ dùng `NORMAL | CRISIS`
- [ ] `project -> ingest` crawl mode change idempotent
- [ ] notification theo business crisis state
- [ ] ontology governance không claim current source nếu chưa implement

## 6. Kết luận

Rollout an toàn nhất hiện tại không phải “build lại analysis UAP parser”, mà là:

1. cleanup docs/source stale
2. verify/harden parser/domain routing đã có
3. verify output schema sang knowledge
4. thêm crisis final state ở `project-srv`
5. nối crawl mode control xuống `ingest-srv`
6. rồi mới mở ontology governance đầy đủ

Nếu đảo thứ tự và mở crisis control trước khi analytics/output contract ổn định, hệ thống sẽ phản ứng nhanh nhưng có thể phản ứng trên signal chưa đủ tin cậy.
