# SMAP Lifecycle Completion Plan

**Ngày cập nhật:** 2026-03-19  
**Phạm vi scan:** `ingest-srv`, `project-srv`  
**Mục tiêu file này:** chốt hiện trạng implement thật trong code và đưa ra kế hoạch hoàn thiện lifecycle end-to-end để theo dõi execution.

## 1. Kết luận ngắn

Hiện tại hệ thống đang ở trạng thái:

- `project-srv` đã có nền CRUD cho `campaign`, `project`, `crisis-config`, nhưng chưa đóng vai trò orchestration lifecycle như thiết kế mong muốn.
- `ingest-srv` đã có nhiều phần control-plane và execution-plane hơn tài liệu cũ mô tả: datasource CRUD, grouped target CRUD, dry run API, scheduler dispatch, RabbitMQ completion consumer, raw batch tracking, UAP parse/publish cho một số flow.
- Điểm nghẽn lớn nhất không còn là schema hay CRUD cơ bản, mà là **contract và orchestration giữa `project-srv` và `ingest-srv`**.

Nếu cần ưu tiên đúng thứ tự để "hoàn thiện lifecycle", thì nên đi theo hướng:

1. chốt state machine canonical cho `project` và `data_source`
2. hoàn thiện orchestration ở `project-srv`
3. mở entrypoint lifecycle nội bộ ở `ingest-srv`
4. nối event/HTTP contract giữa hai service
5. bổ sung test và observability trước khi mở rộng onboarding/passive flow

## 2. Hiện trạng implement

### 2.1 `project-srv`

#### Đã có

- `campaign` CRUD đầy đủ: route, usecase, repository.
- `project` CRUD cơ bản đầy đủ: create/detail/list/update/archive.
- `crisis-config` CRUD đầy đủ ở mức validation và persistence.
- DB schema hiện vẫn còn `project.status` và `project.config_status`.
- HTTP server đã mount đủ các module CRUD hiện có.

#### Chưa có hoặc mới ở mức khung

- Chưa có module quản lý datasource ở `project-srv`.
- Chưa có lớp orchestration setup/readiness cho project.
- Chưa có endpoint/business flow cho:
  - activate project
  - pause/resume project theo orchestration
  - analytics config
- Chưa có ingest client, analytics client, knowledge client.
- Kafka consumer server chỉ là skeleton, chưa setup domain consumer thật.
- Kafka producer được khởi tạo ở `cmd/consumer/main.go`, nhưng chưa có usecase publish event lifecycle.
- Chưa có outbox hoặc cơ chế đảm bảo event consistency.

#### Lệch đáng chú ý so với lifecycle mục tiêu

- `project` mới tạo đang được set `status=ACTIVE` ngay trong repository.
- Theo hướng chốt mới, `project.status` nên có thêm `DRAFT` và project mới phải bắt đầu từ `DRAFT`.
- `config_status` hiện có không phải blocker cho implementation plan; có thể giữ nguyên, không cần ưu tiên migrate/drop ở giai đoạn này.

#### Test/verification

- `go test ./...` tại `project-srv` chạy **pass** ngày `2026-03-18`.
- Tuy nhiên repo **không có test business meaningful**; gần như toàn bộ package báo `no test files`.

### 2.2 `ingest-srv`

#### Đã có

- Datasource CRUD public.
- Grouped crawl target CRUD public.
- Dry run API:
  - `POST /api/v1/datasources/:id/dryrun`
  - `GET /api/v1/datasources/:id/dryrun/latest`
  - `GET /api/v1/datasources/:id/dryrun/history`
- Internal crawl-mode route:
  - `PUT /api/v1/internal/ingest/datasources/:id/crawl-mode`
- Datasource lifecycle usecase đã có:
  - `Activate`
  - `Pause`
  - `Resume`
  - `UpdateCrawlMode`
- Execution plane đã có:
  - scheduler tick dispatch due targets
  - manual internal dispatch route
  - publish task sang RabbitMQ
  - consume completion từ RabbitMQ
  - tạo `external_tasks`, `scheduled_jobs`, `raw_batches`
  - verify MinIO object
- UAP pipeline đã có nhánh parse/publish cho TikTok `full_flow`.

#### Chưa có hoặc chưa nối đủ

- `Activate/Pause/Resume` mới tồn tại ở usecase, **chưa có internal HTTP route hoặc Kafka consumer thực sự gọi vào**.
- Chưa có project lifecycle consumer cho các event:
  - `project.activated`
  - `project.paused`
  - `project.resumed`
  - `project.archived`
- Chưa có publish event ngược về `project-srv` kiểu `ingest.source.*`.
- Dry run hiện mới là **control-plane validation only**:
  - executor nội bộ chỉ check config/target
  - chưa gọi remote crawler thật
  - success path hiện trả `WARNING` với message `control_plane_only_no_remote_execution`
- Passive onboarding cho `FILE_UPLOAD` / `WEBHOOK` chưa được implement đầy đủ.
- UAP parse hiện chưa phải generic parser pipeline; đang tập trung vào một flow cụ thể.

#### Trạng thái thực tế tốt hơn tài liệu cũ

- Nhiều tài liệu trong `documents/plan` và `documents/gap_analysis.md` của `ingest-srv` mô tả các phần "cần làm ở phase 2/3", nhưng nhiều phần trong số đó đã được hiện thực.
- Vì vậy không nên dùng riêng các tài liệu cũ để lên plan; phải ưu tiên code hiện tại làm source of truth.

#### Test/verification

- `go test ./...` tại `ingest-srv` ngày `2026-03-18` **fail**.
- Failure hiện tại nằm ở:
  - `internal/uap/usecase.TestPublishPayloadUsesCurrentUAPRecord`
  - panic nil pointer trong `internal/uap/usecase/publish.go`
- Ngoài package UAP, phần lớn package không có test files.

## 3. Lifecycle đích cần hoàn thiện

## 3.1 Campaign lifecycle

Ở mức tối thiểu:

- `ACTIVE`
- `INACTIVE`
- `ARCHIVED`

Campaign nên đóng vai trò grouping và không chặn sâu vào ingest runtime.

## 3.2 Project lifecycle

`project` chỉ nên giữ **một lớp status duy nhất**:

- `DRAFT`
- `ACTIVE`
- `PAUSED`
- `ARCHIVED`

Phần readiness setup chính vẫn nên được suy ra từ dữ liệu thật ở ingest side:

- project có ít nhất 1 datasource hay chưa
- passive source onboarding đã confirm hay chưa
- có crawl target nào chưa từng dry run hay không
- có crawl target nào có latest dry run `FAILED` hay không

### State flow đề xuất cho project

1. Tạo project
   - `status=DRAFT`
2. Cấu hình source/targets/rules
   - không đổi `project.status`
   - readiness được đọc từ aggregate data
3. Hoàn tất onboarding passive source nếu có
   - không đổi `project.status`
4. Chạy dry run cho các `target` crawl cần thiết
   - không tạo status dry run ở `project`
5. Activate project
   - `status=ACTIVE`
6. Tạm dừng project
   - `status=PAUSED`
7. Archive project
   - `status=ARCHIVED`
8. Unarchive project
   - `status=PAUSED`
   - không auto `ACTIVE`, phải qua hành động activate lại nếu cần

## 3.3 Datasource lifecycle

Theo code hiện tại của `ingest-srv`, lifecycle canonical nên là:

- `PENDING`
- `READY`
- `ACTIVE`
- `PAUSED`
- `FAILED`
- `COMPLETED`
- `ARCHIVED`

### State flow đề xuất cho datasource

- `PENDING -> READY`
  - crawl source dry run pass ở mức chấp nhận được
  - passive source onboarding confirm xong
- `READY -> ACTIVE`
  - chỉ qua internal orchestration từ `project-srv`
- `ACTIVE -> PAUSED`
  - khi project pause hoặc operator pause
- `PAUSED -> ACTIVE`
  - khi project resume
- `PENDING/READY/PAUSED/FAILED -> ARCHIVED`
  - archive mềm
- `ARCHIVED -> PAUSED`
  - unarchive để quay lại control-plane, không auto chạy lại runtime

## 3.4 End-to-end flow mong muốn

1. User tạo `campaign`
2. User tạo `project`
3. User cấu hình `crisis-config` và metadata cần thiết
4. User cấu hình datasource/targets qua `ingest-srv` nhưng dưới orchestration của `project-srv`
5. Nếu có passive source:
   - chạy onboarding
   - xác nhận mapping
6. Nếu có crawl source:
   - chạy dry run theo từng `target`
   - lưu evidence theo `target` và `datasource`
7. User hoặc system activate project
8. `project-srv` validate điều kiện
9. `project-srv` phát lệnh lifecycle sang `ingest-srv`
10. `ingest-srv` activate các datasource đủ điều kiện
11. scheduler dispatch -> crawler -> raw batch -> UAP -> downstream
12. khi pause/resume/archive project, `ingest-srv` đồng bộ source state tương ứng

## 3.5 Điều kiện activate project đã chốt

Project chỉ được activate khi thỏa các điều kiện tối thiểu sau:

1. project có **ít nhất 1 datasource**
2. nếu project có passive datasource thì datasource đó phải ở trạng thái **đã confirm**
3. với crawl datasource, mọi crawl target bắt buộc phải **đã từng có dry run**
4. với crawl datasource, **không có crawl target nào có latest dry run là `FAILED`**

Ghi chú quan trọng:

- activation là **fail toàn bộ** nếu chỉ cần 1 điều kiện bị fail
- rule hiện tại **không yêu cầu** tất cả target phải `SUCCESS`
- rule hiện tại **không tạo** dry run state ở `project`
- dry run vẫn là evidence ở `target` / `datasource`
- mặc định dry run lấy **10 data mẫu mỗi target**
- giá trị này nên được khai báo bằng named constant / enum config, không hard-code magic number
- `TODO:` phần passive confirm hiện chưa implement đầy đủ, nên trong giai đoạn đầu chỉ cần comment rõ đây là blocker rule của tương lai

## 4. Gap quan trọng cần xử lý

## 4.1 Gap A: ownership đúng nhưng orchestration chưa tồn tại

Hiện phân vai khá rõ:

- `project-srv` sở hữu business lifecycle
- `ingest-srv` sở hữu source/runtime lifecycle

Nhưng ở giữa chưa có lớp orchestration hoạt động thật.

**Hệ quả:** hai service đều có một nửa câu chuyện, nhưng chưa thành một vòng đời hoàn chỉnh.

## 4.2 Gap B: `project.status` hiện thiếu `DRAFT` nên lifecycle bắt đầu chưa đúng

Thiết kế chốt mới cần `project.status=DRAFT` cho project mới tạo, nhưng code hiện tại đang bắt đầu ở `ACTIVE`.

**Hệ quả:** backend đang bỏ qua bước setup ban đầu và làm activation mất ý nghĩa nghiệp vụ.

## 4.3 Gap C: `project-srv` tạo project ở trạng thái chưa hợp logic

Hiện repository create project set:

- `status=ACTIVE`

Đây là tín hiệu lifecycle bị lệch từ bước đầu tiên, vì activate đáng ra phải là hành động explicit sau khi đủ readiness.

## 4.4 Gap D: usecase lifecycle ở `ingest-srv` đang "mồ côi"

`Activate/Pause/Resume` đã có rule tốt ở usecase nhưng chưa có adapter gọi vào.

**Hệ quả:** code có nhưng chưa trở thành capability thật của hệ thống.

## 4.5 Gap E: dry run end-to-end chưa phải dry run thật

`ingest-srv` đã có API dry run và persistence, nhưng executor hiện chỉ validate control plane.

**Hệ quả:** `READY` hiện phản ánh "config hợp lệ" hơn là "crawl thử thành công".

## 4.6 Gap F: event contract chưa được implement

Docs đã nói nhiều về Kafka events, nhưng code hiện tại chưa có flow publish/consume lifecycle giữa hai service.

**Hệ quả:** chưa có cơ chế sync chuẩn cho activate/pause/resume/archive/crisis mode.

## 4.7 Gap G: test coverage chưa đủ để rollout an toàn

- `project-srv`: gần như không có test
- `ingest-srv`: ít test, và test hiện có đang fail

**Hệ quả:** rollout lifecycle rất dễ gãy ở integration boundary.

## 5. Kế hoạch thực hiện đề xuất

## Detailed phase docs

- [Phase 0 Implementation](/Users/phongdang/Documents/GitHub/SMAP/smap_lifecycle_phase0_implementation.md)
- [Phase 1 Implementation](/Users/phongdang/Documents/GitHub/SMAP/smap_lifecycle_phase1_implementation.md)

## Phase 0: Chốt canonical contract trước khi code tiếp

**Mục tiêu:** tránh việc mỗi repo đi một state machine khác nhau.

### Deliverables

- 1 tài liệu canonical cho:
  - project state machine
  - datasource state machine
  - dry run contract
  - activate/pause/resume/archive contract
  - event schema tối thiểu
- chốt transport theo hướng **hybrid ngay từ đầu**:
  - synchronous internal HTTP cho control-plane actions cần trả kết quả ngay
  - Kafka cho các tác vụ async, event propagation, notification, audit, downstream sync

### Acceptance criteria

- cả hai repo dùng cùng tên state và cùng transition rules
- dry run chỉ tồn tại ở `target` / `datasource`, không ở `project`
- rule activate project được chốt đúng theo 4 điều kiện tối thiểu ở mục `3.5`
- activation là fail toàn bộ nếu có bất kỳ lỗi readiness nào
- dry run default sample size được chốt là `10`

## Internal endpoints cần có

Để `project-srv` orchestration được `ingest-srv` một cách gọn và không phải tự fan-out quá nhiều request, nên có tối thiểu các internal endpoints sau ở `ingest-srv`.

### Bắt buộc

- `GET /api/v1/internal/ingest/projects/:project_id/activation-readiness`
  - trả summary để `project-srv` quyết định có được activate hay không
  - nên gồm tối thiểu:
    - `project_id`
    - `datasource_count`
    - `has_datasource`
    - `passive_unconfirmed_count`
    - `missing_target_dryrun_count`
    - `failed_target_dryrun_count`
    - `can_activate`
    - `errors[]`
    - danh sách datasource/target vi phạm nếu có
- `POST /api/v1/internal/ingest/projects/:project_id/activate`
  - activate toàn bộ datasource của project
  - nếu readiness fail ở bất kỳ datasource/target nào thì fail toàn bộ request
- `POST /api/v1/internal/ingest/projects/:project_id/pause`
  - pause toàn bộ datasource đang chạy của project
- `POST /api/v1/internal/ingest/projects/:project_id/resume`
  - resume toàn bộ datasource của project đang đủ điều kiện resume
- `POST /api/v1/internal/ingest/projects/:project_id/archive`
  - archive project-side runtime bằng cách archive toàn bộ datasource liên quan
- `POST /api/v1/internal/ingest/projects/:project_id/unarchive`
  - khôi phục toàn bộ datasource của project từ `ARCHIVED` về trạng thái có thể cấu hình lại
  - không auto activate lại runtime

### Tùy chọn nhưng nên có cho debug/admin

- `POST /api/v1/internal/ingest/datasources/:id/activate`
- `POST /api/v1/internal/ingest/datasources/:id/pause`
- `POST /api/v1/internal/ingest/datasources/:id/resume`
- `POST /api/v1/internal/ingest/datasources/:id/archive`
- `POST /api/v1/internal/ingest/datasources/:id/unarchive`

Các endpoint này nên được giữ lại cho admin/debug vì có ích khi cần isolate lỗi từng datasource mà không phải đi qua full project orchestration.

### Không cần thêm endpoint internal ở level project cho dry run

- dry run vẫn dùng flow hiện có ở level datasource/target
- `project-srv` chỉ cần đọc readiness aggregate, không cần có `POST /projects/:id/dryrun`

## Error contract cho internal HTTP

- lỗi auth:
  - giữ status code riêng theo middleware/auth layer hiện tại
- lỗi business hoặc input:
  - trả `400`
- lỗi infra nội bộ:
  - trả `500`

Gợi ý áp dụng:

- `GET /activation-readiness`
  - `200` nếu request hợp lệ, kể cả khi `can_activate=false`
  - payload chứa `errors[]` để giải thích lý do block
- `POST /activate|pause|resume|archive|unarchive`
  - `200` khi command thành công
  - `400` khi không thỏa precondition hoặc input không hợp lệ
  - `500` khi lỗi DB, MQ, network, storage hoặc lỗi infra khác

## Auth và transport đã chốt

- internal HTTP giữa service dùng **shared internal key**
- internal routes chỉ cho service nội bộ gọi, không mở cho public client
- strategy tổng thể là **hybrid ngay từ đầu**

### Dùng synchronous internal HTTP khi

- cần validate readiness và trả kết quả ngay cho user flow
- cần command có semantics rõ ràng kiểu activate/pause/resume/archive
- kết quả của action cần phản hồi trực tiếp cho `project-srv`

### Dùng Kafka khi

- tác vụ không cần block request hiện tại
- cần broadcast event cho nhiều consumer
- cần audit trail / downstream propagation / notification
- xử lý có khả năng kéo dài hoặc retry độc lập với request chính

### Mapping đề xuất

- `project-srv -> ingest-srv` readiness / activate / pause / resume / archive:
  - **HTTP internal**
- dry run execution thật, crawl runtime completion, publish UAP:
  - **async runtime path** hiện đã thiên về RabbitMQ/Kafka
- publish event sau khi activate/pause/resume/archive thành công:
  - **Kafka**
- notification / analytics / downstream sync:
  - **Kafka**

## Phase 1: Sửa nền lifecycle ở `project-srv`

**Ưu tiên:** rất cao

### Việc cần làm

- sửa create project để dùng default lifecycle hợp lý
- thêm `DRAFT` vào `project.status`
- thêm usecase/state transition cho:
  - activate project
  - pause project
  - resume project
  - archive project
- thêm endpoint orchestration tối thiểu:
  - `POST /projects/:id/activate`
  - `POST /projects/:id/pause`
  - `POST /projects/:id/resume`
  - `POST /projects/:id/archive`
  - `POST /projects/:id/unarchive`
- thêm endpoint/query aggregate readiness nếu cần cho UI/admin
- thêm validation để project chỉ activate khi:
  - project có ít nhất 1 datasource
  - passive datasource đã confirm
  - mọi crawl target bắt buộc đã có dry run
  - không có crawl target nào có latest dry run `FAILED`
  - `TODO:` phần passive confirm có thể để comment rule trước, chưa bắt buộc code đầy đủ ở bước đầu

### Acceptance criteria

- `project` chỉ còn một `status` vận hành
- project mới tạo có `status=DRAFT`
- project không thể activate nếu thiếu prerequisites

## Phase 2: Thêm integration layer ở `project-srv`

**Ưu tiên:** rất cao

### Việc cần làm

- tạo ingest client trong `project-srv`
- định nghĩa aggregate read model cho project setup:
  - project
  - crisis-config
  - datasources
  - targets
  - target-level dry run summary
- implement hybrid transport ngay từ đầu:
  - sync HTTP để ra lệnh ngay
  - async Kafka để audit và eventual consistency
- thêm producer cho các event lifecycle tối thiểu
- cân nhắc outbox cho event publish nếu cần consistency tốt

### Acceptance criteria

- `project-srv` có thể nhìn thấy readiness của ingest side
- UI chỉ cần gọi `project-srv`, không phải tự ghép rule từ nhiều service

## Phase 3: Mở lifecycle adapter thật ở `ingest-srv`

**Ưu tiên:** rất cao

### Việc cần làm

- mount internal route hoặc consumer cho:
  - `GET /api/v1/internal/ingest/projects/:project_id/activation-readiness`
  - `POST /api/v1/internal/ingest/projects/:project_id/activate`
  - `POST /api/v1/internal/ingest/projects/:project_id/pause`
  - `POST /api/v1/internal/ingest/projects/:project_id/resume`
  - `POST /api/v1/internal/ingest/projects/:project_id/archive`
  - `POST /api/v1/internal/ingest/projects/:project_id/unarchive`
- thêm query/update theo `project_id` để apply lifecycle hàng loạt
- nếu dùng Kafka:
  - implement project lifecycle consumer trong `ingest-srv`
- nếu dùng HTTP:
  - implement internal endpoints rõ ràng và secured

### Acceptance criteria

- `Activate/Pause/Resume` không còn chỉ là usecase chưa được gọi
- project orchestration có thể đổi state thực của datasource
- readiness endpoint trả đúng 3 điều kiện activate đã chốt

## Phase 4: Nâng dry run target từ control-plane sang real execution

**Ưu tiên:** cao

### Việc cần làm

- thay local dryrun executor bằng remote validation thật cho crawl source
- định nghĩa rõ output dry run:
  - warning chấp nhận được
  - failure blocker
  - sample evidence
- chốt default dry run sample size là `10` mỗi target
- giá trị sample size phải đi qua named constant / enum config, không hard-code
- lưu sample/result để UI đọc lại ở level `target`
- chuẩn hóa mapping từ dry run result -> `data_source.status`
- để `project-srv` suy ra readiness từ tập target/source thay vì lưu thêm status phụ ở `project`

### Acceptance criteria

- `READY` phản ánh source thực sự sẵn sàng vận hành
- dry run target-level dùng được để quyết định activate project

## Phase 5: Hoàn thiện passive onboarding

**Ưu tiên:** trung bình đến cao

### Việc cần làm

- `FILE_UPLOAD` sample upload + mapping preview
- `WEBHOOK` sample payload preview + mapping confirm
- luồng confirm mapping -> `onboarding_status=CONFIRMED`
- để `project-srv` đọc onboarding result như activation prerequisite

### Acceptance criteria

- project có passive source vẫn đi hết lifecycle chuẩn

## Phase 6: Hardening, test, observability

**Ưu tiên:** bắt buộc trước rollout production hoàn chỉnh

### Việc cần làm

- sửa test fail hiện tại ở `ingest-srv`
- thêm unit test cho state transition rules
- thêm integration test cho:
  - project activate -> ingest activate sources
  - project pause -> ingest pause sources
  - project resume -> ingest resume sources
  - project archive -> ingest archive sources
  - dry run failure blocks activation
- thêm structured audit/event log
- thêm dashboard/health signal cho:
  - due targets
  - published tasks
  - completion success/failure
  - raw batch parse status

### Acceptance criteria

- test bao phủ được lifecycle chính
- rollout có thể trace được lỗi theo project/source/target/task/batch

## 6. Backlog ưu tiên đề xuất

## P0

- Sửa `project-srv` create lifecycle default.
- Thêm `DRAFT` vào `project.status`.
- Chốt canonical state machine giữa `project-srv` và `ingest-srv`.
- Expose lifecycle adapter thật cho `Activate/Pause/Resume` ở `ingest-srv`.
- Expose `Archive/Unarchive` adapter ở `ingest-srv`.
- Thêm internal readiness endpoint theo `project_id`.
- Implement `project-srv` activate/pause/resume orchestration.
- Chốt hybrid transport ngay từ đầu.

## P1

- Thêm readiness aggregation ở `project-srv` dựa trên target/source evidence.
- Nâng dry run ở `ingest-srv` từ local validation sang remote execution.
- Chốt named constant / enum config cho dry run sample size = `10`.
- Thêm ingest client và project setup aggregate view.
- Thêm project lifecycle integration tests.

## P2

- Passive onboarding cho `FILE_UPLOAD` / `WEBHOOK`.
- Publish event ngược từ `ingest-srv` về `project-srv`.
- Dashboard setup status cho UI/admin.

## P3

- Outbox pattern.
- Retry policy và dead-letter handling cho lifecycle events.
- Metrics/alerts production-grade.

## 7. Checklist theo dõi thực thi

- [ ] Chốt canonical lifecycle doc cho `project` và `datasource`
- [ ] Sửa default status khi tạo project
- [ ] Thêm `DRAFT` vào `project.status`
- [ ] Thêm project activation usecase + endpoint
- [ ] Thêm project pause/resume usecase + endpoint
- [ ] Thêm project archive/unarchive usecase + endpoint
- [ ] Tạo ingest client trong `project-srv`
- [ ] Thêm `GET /api/v1/internal/ingest/projects/:project_id/activation-readiness`
- [ ] Mở adapter `activate/pause/resume/archive` trong `ingest-srv`
- [ ] Mở adapter `unarchive` trong `ingest-srv`
- [ ] Implement project lifecycle consumer hoặc internal lifecycle HTTP
- [ ] Nâng dry run thành real execution
- [ ] Hoàn thiện passive onboarding
- [ ] Sửa test fail ở `ingest-srv`
- [ ] Thêm test lifecycle cho `project-srv`
- [ ] Thêm integration tests cross-service
- [ ] Thêm audit log và metrics cho lifecycle

## 8. Đề xuất mốc execution thực tế

### Sprint 1

- Phase 0
- Phase 1
- một phần Phase 3

### Sprint 2

- phần còn lại của Phase 3
- Phase 2
- Phase 4

### Sprint 3

- Phase 5
- Phase 6

## 9. Gợi ý triển khai thực dụng

Với quyết định hiện tại, nên đi theo hybrid ngay từ đầu nhưng chia ranh giới rất rõ:

1. internal HTTP cho readiness và lifecycle command
2. Kafka cho event propagation và async side effects
3. giữ admin/debug endpoints ở datasource-level
4. chưa cần đụng migration bỏ `config_status`
5. passive confirm có thể để TODO comment ở bước đầu, nhưng rule activation phải được encode ngay từ bây giờ

Lý do:

- lifecycle command cần phản hồi rõ ràng và deterministic
- async event vẫn cần ngay từ đầu cho downstream sync/audit
- tách control plane và event plane sớm sẽ đỡ phải refactor transport lần hai

## 10. Nhận định cuối

Phần khó nhất của dự án lúc này không phải "thiếu module ingest" nữa, vì `ingest-srv` đã có khá nhiều implementation thật. Phần khó nhất là **biến hai service đang chạy song song thành một lifecycle thống nhất, có guardrails, có state machine rõ ràng, và có integration contract đủ chặt**.

Nói ngắn gọn:

- `project-srv` cần trở thành **bộ điều phối lifecycle**
- `ingest-srv` cần trở thành **runtime/control-plane executor có entrypoint rõ**
- dry run nên được giữ là **evidence ở target/source**, không phải lifecycle state của `project`
- activation phải **fail toàn bộ** nếu readiness còn bất kỳ lỗi nào
- hybrid transport là hướng nên đi ngay từ đầu
- phần còn thiếu lớn nhất là **glue code + state contract + test**
