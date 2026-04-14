# Rule Inventory Master

## Tóm tắt

Đây là bảng inventory tổng để index các business rule đang có thật trong code. Con số hiện tại là **khoảng 54 rule runtime/core đã implement**, chưa tính:
- `passive source + onboarding`
- `profile target runtime`
- `identity OAuth full product flow`
- `infra resilience/outage simulation`

Phân bổ hiện tại:

| Domain | Rule Count Ước lượng | Trạng thái |
| --- | ---: | --- |
| Campaign | 2 | Implemented |
| Project lifecycle + readiness | 12 | Implemented |
| Datasource CRUD + lifecycle + crawl-mode | 12 | Implemented |
| Target CRUD + activation invariants | 10 | Implemented |
| Dry-run | 10 | Implemented |
| Execution + scheduler | 8 | Implemented |

## Master Index

| Rule ID | Domain | Rule Title | Trigger / Command | Preconditions | State Transition | Side Effects | Error Outcome | Source of Truth | Coverage | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CAM-01 | Campaign | Campaign phải tồn tại để create project | `POST /campaigns/:id/projects` | campaign tồn tại, chưa archived | tạo project `DRAFT` | project record mới | `400` nếu invalid/not found | project create usecase + repo | CRUD | Implemented |
| CAM-02 | Campaign | Campaign archived không tạo project mới | `POST /campaigns/:id/projects` | campaign archived | không đổi | không tạo record | `400` | test + create guard | CRUD edge | Implemented |
| PROJ-01 | Project | Activate chỉ cho `DRAFT` | `POST /projects/:id/activate` | status `DRAFT` | `DRAFT -> ACTIVE` | gọi ingest activate, publish event | `400` nếu status khác | `project/model` + `lifecycle.go` | lifecycle + decision table | Implemented |
| PROJ-02 | Project | Pause chỉ cho `ACTIVE` | `POST /projects/:id/pause` | status `ACTIVE` | `ACTIVE -> PAUSED` | gọi ingest pause, publish event | `400` nếu status khác | `project/model` + `lifecycle.go` | lifecycle + concurrency | Implemented |
| PROJ-03 | Project | Resume chỉ cho `PAUSED` | `POST /projects/:id/resume` | status `PAUSED`, readiness `resume` pass | `PAUSED -> ACTIVE` | gọi ingest resume, publish event | `400` nếu blocked | `project/model` + `lifecycle.go` | lifecycle + decision table | Implemented |
| PROJ-04 | Project | Archive cho `DRAFT/ACTIVE/PAUSED` | `POST /projects/:id/archive` | status eligible | `* -> ARCHIVED` | nếu `ACTIVE` thì pause ingest trước | `400` nếu invalid | `project/model` + `lifecycle.go` | lifecycle | Implemented |
| PROJ-05 | Project | Unarchive chỉ cho `ARCHIVED` và trả về `PAUSED` | `POST /projects/:id/unarchive` | status `ARCHIVED` | `ARCHIVED -> PAUSED` | publish event | `400` nếu invalid | `project/model` + `lifecycle.go` | lifecycle | Implemented |
| PROJ-06 | Project | Delete chỉ sau archived | `DELETE /projects/:id` | archived | soft/hard delete theo repo | xóa project | `400` nếu chưa archived | delete flow + tests | CRUD + lifecycle edge | Implemented |
| PROJ-07 | Project | Activation readiness phân tách `activate` và `resume` | `GET /projects/:id/activation-readiness` | project tồn tại | không đổi | query ingest internal | `400` nếu invalid command | `helpers.go` + ingest client | lifecycle + internal contract | Implemented |
| PROJ-08 | Project | Readiness fail nếu không có datasource | readiness | datasource count = 0 | không đổi | error aggregate | blocked | `project_lifecycle.go` | lifecycle | Implemented |
| PROJ-09 | Project | Readiness fail nếu passive source chưa confirmed | readiness | passive datasource onboarding chưa confirmed | không đổi | error aggregate | blocked | `project_lifecycle.go` | coverage gap | Partially implemented |
| PROJ-10 | Project | Readiness fail nếu target chưa có dry-run usable | readiness | latest dryrun missing/failed | không đổi | error aggregate | blocked | `project_lifecycle.go` | lifecycle/runtime | Implemented |
| PROJ-11 | Project | Readiness fail nếu crawl datasource không có active target | readiness | crawl source active target count = 0 | không đổi | error aggregate | blocked | `project_lifecycle.go` | lifecycle | Implemented |
| PROJ-12 | Project | Lifecycle command dùng optimistic status guard để tránh race local | activate/pause/resume | expected current status | chỉ một transition local hợp lệ | publish event một lần local | `400` status conflict | `repo.UpdateStatus(...ExpectedStatuses)` | project concurrency | Implemented |
| DS-01 | Datasource | Create datasource yêu cầu project available và source type/category hợp lệ | `POST /datasources` | project available, source type valid | record mới `PENDING/READY` theo repo default | persist datasource | `400` nếu invalid | `datasource.go` + repo | CRUD | Implemented |
| DS-02 | Datasource | Create dưới archived project bị chặn | `POST /datasources` | project archived | không đổi | không tạo record | `400` | project internal check | CRUD edge | Implemented |
| DS-03 | Datasource | Crawl datasource phải có crawl config | `POST /datasources` | crawl mode + interval > 0 | không đổi | không tạo nếu invalid | `400` | `validCreateInput` | CRUD/error contract | Implemented |
| DS-04 | Datasource | Passive source create chưa enforce onboarding contract thật | `POST /datasources` | passive source | persist base datasource ở mức tối thiểu | TODO onboarding | không block thêm | `datasource.go` TODO | gap register | Partially implemented |
| DS-05 | Datasource | Detail/List không trả deleted datasource | `GET /datasources` / `GET /datasources/:id` | not deleted | không đổi | query visible set | `400`/not found | repo query semantics | CRUD | Implemented |
| DS-06 | Datasource | Update bị chặn khi target trong source đang dry-run `RUNNING` | `PUT /datasources/:id` | không có target running | update fields | có thể reset dryrun snapshot | `400` nếu blocked | `ensureDatasourceTargetsDryrunNotRunning` | no-side-effect/runtime guard | Implemented |
| DS-07 | Datasource | Runtime material change trên datasource active bị chặn | `PUT /datasources/:id` | source not `ACTIVE` nếu đổi config/mapping | update allowed/blocked | không mutate active config | `400` nếu blocked | `datasource.go` | runtime guard matrix | Implemented |
| DS-08 | Datasource | Archive chỉ là archive, chưa delete | `POST /datasources/:id/archive` | not running, not already archived | `* -> ARCHIVED` | vẫn detail/list theo semantics archive | `400` nếu blocked | `datasource.go` | CRUD + idempotency | Implemented |
| DS-09 | Datasource | Delete chỉ sau archive và là soft delete | `DELETE /datasources/:id` | status `ARCHIVED`, not running | set `deleted_at` | detail không còn thấy | `400` nếu chưa archived | `datasource.go` + repo | CRUD | Implemented |
| DS-10 | Datasource | ActivateDataSource chỉ từ `READY` | code-level usecase | status `READY`, runtime prerequisites pass | `READY -> ACTIVE` | clear paused marker | `400` nếu invalid | `datasource_lifecycle.go` | coverage gap | Implemented |
| DS-11 | Datasource | PauseDataSource chỉ từ `ACTIVE` | code-level usecase | status `ACTIVE` | `ACTIVE -> PAUSED` | persist paused state | `400` nếu invalid | `datasource_lifecycle.go` | coverage gap | Implemented |
| DS-12 | Datasource | ResumeDataSource chỉ từ `PAUSED` | code-level usecase | status `PAUSED`, runtime prerequisites pass | `PAUSED -> ACTIVE` | clear paused marker | `400` if invalid | `datasource_lifecycle.go` | coverage gap | Implemented |
| DS-13 | Datasource | Update crawl mode chỉ cho crawl source ở `READY/ACTIVE/PAUSED` | `PUT /internal/datasources/:id/crawl-mode` | source category crawl, valid mode, valid crawl config | mode change | audit crawl mode change | `400` nếu invalid | `datasource_lifecycle.go` | internal contract/runtime guard | Implemented |
| TGT-01 | Target | Chỉ crawl datasource mới tạo target | `POST /datasources/:id/targets/*` | datasource category crawl, not archived | create target | persist target inactive | `400` nếu invalid | `target.go` | CRUD | Implemented |
| TGT-02 | Target | Target mới tạo mặc định inactive | target create | datasource valid | `is_active=false` | chờ dryrun usable | không có | `createTarget` | CRUD regression | Implemented |
| TGT-03 | Target | Profile target có CRUD nhưng runtime chưa map đủ | `POST /profiles` | datasource valid | create record | chưa có execution mapping | không có | `CreateProfileTarget` + execution helper | gap | Partially implemented |
| TGT-04 | Target | Update target bị chặn khi target đang dry-run `RUNNING` | `PUT /targets/:id` | latest not running | update fields | material change có thể deactivate target | `400` nếu blocked | `ensureTargetDryrunNotRunning` | target runtime guard | Implemented |
| TGT-05 | Target | Material target change sẽ mark datasource pending và deactivate target nếu đang active | `PUT /targets/:id` | material fields changed | target maybe `active -> inactive`, datasource pending | invalidate readiness | `200` with side effect | `target.go` | runtime consistency | Implemented |
| TGT-06 | Target | Activate target chỉ sau latest dry-run usable | `POST /targets/:id/activate` | latest status `SUCCESS/WARNING` | `inactive -> active` | readiness source/project có thể pass | `400` nếu no usable dryrun | `target.go` | CRUD/lifecycle | Implemented |
| TGT-07 | Target | Deactivate/delete active target phải giữ invariant active target count | `POST /deactivate`, `DELETE` | không làm crawl source mất active target bắt buộc | active count preserved | may block command | `400` nếu vi phạm | `ensureCanRemoveActiveTarget` | target guard matrix | Implemented |
| TGT-08 | Target | Delete target là hard delete | `DELETE /targets/:id` | target exists, not running, invariant pass | hard delete row | latest/history vẫn không ghost | `400` nếu blocked | target repo + tests | CRUD + side effect | Implemented |
| TGT-09 | Target | Facebook `POST_URL` yêu cầu `platform_meta.parse_ids` để dispatch | execution | parse_ids valid | dispatch allowed | build post_detail spec | `400/409` nếu invalid | `parseFacebookParseIDs` | facebook execution e2e | Implemented |
| TGT-10 | Target | Unsupported execution mapping bị chặn | dispatch | no known source_type x target_type mapping | không đổi | không publish task | `409/400` | `buildDispatchSpecs` | execution faults | Implemented |
| DRY-01 | Dryrun | Trigger dryrun là per-target, không phải per-datasource | `POST /datasources/:id/dryrun` | target_id required | create dryrun result/job | publish dryrun task | `400` nếu thiếu target_id | routes + usecase + tests | CRUD/lifecycle/runtime | Implemented |
| DRY-02 | Dryrun | Retrigger cùng target khi latest `RUNNING` bị chặn | trigger | latest not running | no new result | preserve current runtime | `400` if blocked | dryrun usecase | runtime guard/no-side-effect | Implemented |
| DRY-03 | Dryrun | Latest/history lookup theo datasource + target lineage | `GET latest/history` | datasource/target valid | không đổi | list dryrun lineage | `400` nếu not found/invalid | dryrun endpoints + repo | runtime consistency | Implemented |
| DRY-04 | Dryrun | Completion `error` finalize result thành `FAILED` | MQ completion | valid task id | running -> failed | update result + datasource snapshot | not found/error if missing task | `HandleCompletion` | completion faults | Implemented |
| DRY-05 | Dryrun | Completion success tải artifact từ MinIO rồi build result | MQ completion | storage bucket/path valid | running -> success/warning/failed | verify artifact, parse bytes | `FAILED` nếu artifact unusable | `HandleCompletion` + minio verify | runtime minio | Implemented |
| DRY-06 | Dryrun | Usable dry-run sẽ auto-activate target | completion success/warning | final status usable | target inactive -> active | readiness may unblock | no separate API needed | dryrun complete repo opt `ActivateTarget` | runtime/lifecycle | Implemented |
| DRY-07 | Dryrun | Duplicate completion không được phình history hay phá state | duplicate MQ completion | result already terminal | no transition | idempotent return | no-op | `HandleCompletion` duplicate branch | duplicate burst/idempotency | Implemented |
| DRY-08 | Dryrun | Late completion không được resurrect datasource/target state đã delete/archive | late completion | entity may have changed | preserve safe state | no ghost state | ignore/idempotent safe update | completion tests | completion faults | Implemented |
| DRY-09 | Dryrun | Dryrun usable/failure ảnh hưởng readiness theo target | completion -> readiness | latest available | readiness aggregate changes | project activation may block/unblock | blocked until usable | `project_lifecycle.go` | lifecycle/runtime consistency | Implemented |
| DRY-10 | Dryrun | Terminal dryrun phải có artifact usable cho nhánh success/warning | completion success | artifact exists in MinIO | terminal result persisted | store sample/warnings/metrics | fail if artifact broken | minio verify + tests | runtime minio | Implemented |
| EXE-01 | Execution | Manual dispatch chỉ cho crawl source, non-archived, active target, crawl_mode present | `POST /internal/.../dispatch` | dispatch context valid | create scheduled job/task | publish task | `409` if blocked | `validateDispatchContext` | execution faults | Implemented |
| EXE-02 | Execution | Scheduled dispatch còn yêu cầu datasource `ACTIVE` | scheduler tick | valid dispatch context + source active | claim + dispatch | update next/last crawl timestamps | no dispatch if blocked | `validateScheduledDispatchContext` | scheduler guard | Implemented |
| EXE-03 | Execution | Tiktok keyword dispatch mapping là `full_flow` per keyword | dispatch | source `TIKTOK`, target `KEYWORD` | create N dispatch specs | publish N tasks | unsupported if no keywords | `buildDispatchSpecs` | runtime completion | Implemented |
| EXE-04 | Execution | Facebook post dispatch mapping là `post_detail` | dispatch | source `FACEBOOK`, target `POST_URL`, parse_ids valid | create 1 spec | publish 1 task | blocked if parse_ids invalid | `buildDispatchSpecs` | facebook execution | Implemented |
| EXE-05 | Execution | Scheduler claim set `last_crawl_at` tại thời điểm dispatch, completion không overwrite lại | scheduler + completion | due target | update timing fields consistently | stable observability | fixed bug regression | claim repo + execution helpers | scheduler stress | Implemented |
| EXE-06 | Execution | Pause/archive project sẽ cancel runtime in-flight của project | project event | project pause/archive | running jobs -> cancelled | rollback claim-state / ignore late completion | runtime stop | execution runtime control + datasource project lifecycle | scheduler guard | Implemented |
| EXE-07 | Execution | Completion success/failure cập nhật `last_success_at` / `last_error_at`, không đè `last_crawl_at` | MQ completion | task exists | update health timestamps | preserve start time semantics | safe no-op for cancelled duplicate | execution consumer/repo helpers | scheduler stress | Implemented |
| EXE-08 | Execution | Scheduler phải re-check context sau claim để tránh dispatch nhầm sau state change | scheduler tick | target/source could change after claim | release claim or continue | avoid stale dispatch | safe skip | execution cron/usecase | scheduler guard | Implemented |
| ID-01 | Identity | Public auth routes là login/callback; runtime E2E chủ yếu dùng JWT bypass/local secret | `/authentication/*` | provider configured | session/token flow | auth boundary | 401/redirect semantics | auth routes + test harness | boundary only | Partially implemented |
| ID-02 | Identity | Protected routes dùng JWT auth; internal routes dùng `X-Internal-Key` | `/me`, `/internal/*` | valid JWT or internal key | no business transition | auth gate | `401/403` if invalid | middleware wiring | internal/error contract | Implemented |
| ID-03 | Identity | Runtime chain hiện dùng identity như auth boundary, không phải source of truth cho lifecycle | cross-service | JWT/internal validate | no domain transition | authorization only | blocked if invalid | httpserver/auth routes | boundary docs | Implemented |

## Coverage Map

Các nhóm test hiện đang làm evidence cho inventory này:

| Group | Suites chính |
| --- | --- |
| CRUD | `test_crud.py`, `test_crud_edge_cases.py` |
| Lifecycle | `test_lifecycle.py`, `test_lifecycle_edge_cases.py`, `test_project_lifecycle_concurrency.py` |
| Dryrun | `test_runtime_completion_e2e.py`, `test_dryrun_completion_faults.py`, `test_dryrun_completion_duplicate_burst.py` |
| Execution | `test_execution_dispatch_faults.py`, `test_facebook_post_url_execution_e2e.py`, `test_manual_dispatch_stress.py` |
| Scheduler | `test_scheduler_e2e.py`, `test_scheduler_guard_matrix.py`, `test_scheduler_stress_matrix.py`, `test_scheduler_concurrent_projects.py`, `test_scheduler_runtime_soak.py` |
| Runtime consistency | `test_runtime_state_matrix.py`, `test_runtime_consistency_matrix.py`, `test_runtime_minio_contract.py` |
| Idempotency + side effect | `test_no_side_effect_contracts.py`, `test_idempotency_contract.py`, `test_archive_delete_update_concurrent_stress.py` |
| Boundary/contract | `test_internal_api_contract.py`, `test_error_contract.py`, `test_zero_500_matrix.py`, `test_zero_500_expanded.py`, `test_infra_boundary_contract.py`, `test_trace_contract.py` |
