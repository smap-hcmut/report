# Gap Analysis - documents/ingest-service-status.md

## Verdict

File này là tài liệu cũ "gần đúng nhất" ở tầng ingest low-level, nhưng vẫn lệch mạnh ở các chỗ quan trọng:

- dryrun semantics,
- target-centric runtime,
- passive source completeness,
- profile runtime,
- archive/delete semantics,
- project/ingest coordination model.

## Matrix

| Doc cũ / section | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `DryRun Domain` | Dryrun là "test datasource trước activate". | Dryrun hiện tại là `per-target`, không phải `per-datasource`; `target_id` là mandatory cho path crawl. | Critical | Rewrite toàn bộ domain từ "source validation" sang "target validation pipeline". |
| `DryRun Trigger flow` | `exec.Execute()` chạy dryrun, update result trực tiếp, pass chủ yếu thành `WARNING`, không thể hiện async pipeline. | Runtime thực tế publish task, worker ghi artifact lên MinIO, completion được consumer finalize thành `SUCCESS/WARNING/FAILED`, có duplicate/late completion handling. | Critical | Sửa flow thành async RMQ + MinIO + completion consumer. |
| `Activation Guard - KHONG check dryrun_status` | Activate source không check `dryrun_status`, imply rằng dryrun không phải guard chính. | Ở runtime core hiện tại, project readiness và target activation đều phụ thuộc dryrun usable của target. Source-level usecase vẫn tồn tại nhưng không còn là điểm nhìn đủ để mô tả hệ thống. | High | Ghi rõ: source-level lifecycle và project-level readiness là hai lớp khác nhau; project activation phụ thuộc latest dryrun usable của target. |
| `Source Types & Categories` | `FILE_UPLOAD` và `WEBHOOK` được mô tả như các passive source khả dụng đầy đủ. | Passive source hiện chưa có onboarding/runtime contract hoàn chỉnh; mới có base model + placeholder readiness gate. | Critical | Gắn nhãn `Partially implemented`; không mô tả passive source như feature production-complete. |
| `CrawlTarget Sub-Resource` | `KEYWORD`, `PROFILE`, `POST_URL` đều được trình bày như runtime ngang hàng. | Runtime mapping hiện chỉ rõ cho `TIKTOK + KEYWORD` và `FACEBOOK + POST_URL`; `PROFILE` mới hoàn chỉnh CRUD, chưa hoàn chỉnh dispatch/dryrun/scheduler runtime. | High | Thêm matrix support thực tế theo `source_type x target_type`; đánh dấu `PROFILE` là partial. |
| `Lifecycle` | Datasource lifecycle là trung tâm vận hành chính. | Runtime thực tế vận hành theo target nhiều hơn datasource: target create inactive, target activation dựa dryrun usable, scheduler dispatch due target, active-target invariant. | High | Giữ datasource lifecycle nhưng thêm hẳn section `Target-centric runtime semantics`. |
| `API Endpoints` | `DELETE /datasources/:id` ngầm là archive. | Runtime hiện tách `archive datasource` và `delete datasource`; delete chỉ sau archive và là soft delete. | Critical | Thêm route archive riêng, đổi nghĩa `DELETE`. |
| `Project lifecycle Kafka consumer missing` | Ingest chưa nhận project lifecycle events, nên project activate/pause chưa phản ánh xuống ingest. | Runtime core hiện tại không còn dựa vào Kafka path đó làm contract chính; project lifecycle phối hợp qua internal API. | High | Sửa từ "missing feature" sang "old architecture path not current source of truth". |
| `Adaptive Crawl Status` | Endpoint crawl-mode đã sẵn sàng cho crisis controller như một flow gần hoàn chỉnh. | Endpoint đúng là có, nhưng current runtime pack không coi adaptive crawl là core implemented flow. | Medium | Đánh dấu `endpoint implemented`, `caller/orchestration not part of current runtime core`. |

## Cụm mismatch chi tiết

### 1. Dryrun không còn là "validate datasource" đơn giản

Docs cũ mô tả:

- fetch source,
- check status `PENDING/READY`,
- chạy `exec.Execute()`,
- cập nhật datasource status.

Runtime hiện tại thực tế:

- dryrun trigger là per target,
- chạy qua queue/task,
- worker ghi artifact,
- consumer finalize result,
- success/warning usable có thể auto-activate target,
- duplicate completion phải idempotent,
- late completion không resurrect state đã archive/delete/cancel.

Đây là thay đổi quan trọng nhất vì nó ảnh hưởng:

- readiness,
- target activation,
- scheduler safety,
- observability,
- testing strategy.

### 2. Runtime hiện tại là target-centric

Các rule thực tế mà docs cũ chưa nhấn mạnh đủ:

- target mới tạo mặc định inactive,
- material target change có thể deactivate target,
- material target change mark datasource pending,
- activate target chỉ sau latest dryrun usable,
- deactivate/delete target active phải giữ invariant active target count.

Nếu giữ docs cũ, người đọc sẽ tưởng chỉ cần source `READY/ACTIVE` là đủ để hiểu runtime. Điều đó không còn đúng.

### 3. Passive source đang bị over-document

Docs cũ đang kể:

- FILE_UPLOAD one-shot,
- WEBHOOK continuous,
- onboarding hoàn chỉnh,
- lifecycle `READY -> ACTIVE -> COMPLETED` hoặc `ACTIVE` ổn định.

Nhưng implementation code-derived ghi rất rõ:

- passive create mới là base persistence,
- onboarding chỉ là placeholder gate,
- chưa có preview/analyze/confirm flow thật,
- chưa nên mô tả như feature hoàn chỉnh trong BRD chính.

### 4. PROFILE target đang bị overclaim

Docs cũ dễ làm người đọc nghĩ:

- `PROFILE` target đã tham gia đầy đủ dryrun/execution/scheduler,
- runtime support ngang `KEYWORD` và `POST_URL`.

Thực tế:

- API/CRUD có,
- runtime mapping chưa đủ,
- không nên mô tả như supported execution path.

## Rewrite đề xuất

### Nên đổi cấu trúc file thành:

1. `Datasource Domain`
   - CRUD
   - lifecycle usecases
   - archive/delete semantics
2. `Target Domain`
   - create inactive
   - activation invariants
   - material change side effects
3. `Dryrun Domain`
   - per-target trigger
   - async pipeline
   - completion semantics
4. `Execution + Scheduler`
   - due-target claim/dispatch
   - timestamp semantics
   - cancellation semantics
5. `Partial / Gap`
   - passive onboarding
   - profile runtime
   - single datasource lifecycle route exposure

### Câu chữ nên dùng

- Tránh câu kiểu `dryrun test datasource trước activate`.
- Thay bằng `dryrun validates target readiness for runtime`.
- Tránh mô tả `FILE_UPLOAD/WEBHOOK` như production-complete.
- Thêm support matrix thật của execution mapping.

## Kết luận

Đây là file đáng giữ lại nhưng phải refactor mạnh. Phần ingest low-level như queue/MinIO/UAP còn giá trị, nhưng phần business/runtime contract đang không còn phản ánh đúng behavior hiện tại.
