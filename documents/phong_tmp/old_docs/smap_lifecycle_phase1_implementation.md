# SMAP Lifecycle Phase 1 Implementation

**Ngày cập nhật:** 2026-03-19  
**Mục tiêu phase:** dựng nền lifecycle ở `project-srv` để project bắt đầu đúng từ `DRAFT` và có public command rõ ràng cho `activate / pause / resume / archive / unarchive`.  
**Tính chất phase:** runtime code trong `project-srv` + migration status + test cơ bản.  
**Dependency:** Phase 0 đã chốt contract.

## 1. Mục tiêu cụ thể

Phase 1 chỉ tập trung vào `project-srv`.

### Phải đạt được

- thêm `DRAFT` vào `project.status`
- project mới tạo mặc định ở `DRAFT`
- có lifecycle usecase cho:
  - activate
  - pause
  - resume
  - archive
  - unarchive
- có public endpoints tương ứng để UI/admin gọi
- encode rule local cho state transition
- chuẩn bị interface/port để Phase 2 cắm ingest readiness + lifecycle gateway

### Chưa cần làm trong phase này

- concrete ingest HTTP client
- Kafka publish thật
- ingest internal endpoints
- passive confirm flow thật
- dry run runtime thật

## 2. Thiết kế triển khai

## 2.1 Nguyên tắc

- Phase 1 sửa `project-srv` sao cho lifecycle nội bộ đúng trước
- Các dependency sang `ingest-srv` phải đi qua interface rõ ràng
- Nếu dependency chưa cắm ở Phase 1, phải có stub/fake để code compile và test được

## 2.2 Rule state transition ở `project-srv`

### Allowed

- `DRAFT -> ACTIVE`
  - chỉ khi readiness pass
- `ACTIVE -> PAUSED`
- `PAUSED -> ACTIVE`
- `DRAFT|ACTIVE|PAUSED -> ARCHIVED`
- `ARCHIVED -> PAUSED`

### Not allowed

- `ACTIVE -> DRAFT`
- `PAUSED -> DRAFT`
- `ARCHIVED -> ACTIVE` trực tiếp

## 2.3 Readiness dependency

Trong Phase 1, `project-srv` nên có một port kiểu:

```go
type LifecycleGateway interface {
    GetActivationReadiness(ctx context.Context, projectID string) (ActivationReadiness, error)
    ActivateProjectSources(ctx context.Context, projectID string) error
    PauseProjectSources(ctx context.Context, projectID string) error
    ResumeProjectSources(ctx context.Context, projectID string) error
    ArchiveProjectSources(ctx context.Context, projectID string) error
    UnarchiveProjectSources(ctx context.Context, projectID string) error
}
```

Phase 1 chỉ cần định nghĩa port + fake/noop adapter dùng cho test hoặc wiring tạm.
Concrete HTTP client để gọi `ingest-srv` sẽ đi ở Phase 2.

## 3. Danh sách file cần sửa / tạo

## 3.1 Database / generated code

### Sửa / tạo

- `[project-srv/migration/init_schema.sql](/Users/phongdang/Documents/GitHub/SMAP/project-srv/migration/init_schema.sql)`
  - chỉ dùng làm reference cũ, không nên sửa trực tiếp nếu đã có môi trường chạy
- tạo migration mới:
  - `[project-srv/migration/000003_project_status_draft_lifecycle.sql](/Users/phongdang/Documents/GitHub/SMAP/project-srv/migration/000003_project_status_draft_lifecycle.sql)`

### Sau migration

- regenerate `sqlboiler`
- generated files dưới `[project-srv/internal/sqlboiler](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/sqlboiler)` sẽ thay đổi

## 3.2 Domain model

- [project-srv/internal/model/project.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/model/project.go)
  - thêm `ProjectStatusDraft`
  - cập nhật mapping từ DB -> domain

## 3.3 Project domain contract

- [project-srv/internal/project/interface.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/interface.go)
  - thêm method:
    - `Activate`
    - `Pause`
    - `Resume`
    - `Unarchive`
- [project-srv/internal/project/types.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/types.go)
  - thêm input/output cho lifecycle actions
- [project-srv/internal/project/errors.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/errors.go)
  - thêm lỗi:
    - invalid transition
    - activate not allowed
    - pause not allowed
    - resume not allowed
    - unarchive not allowed
    - readiness failed
    - lifecycle gateway failed

## 3.4 Usecase layer

- [project-srv/internal/project/usecase/project.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/project.go)
  - đổi create default từ `ACTIVE` sang `DRAFT`
- [project-srv/internal/project/usecase/helpers.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/helpers.go)
  - update allowed statuses
  - thêm helpers validate transition
- tạo file mới:
  - `[project-srv/internal/project/usecase/lifecycle.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/lifecycle.go)`
    - implement activate/pause/resume/unarchive
- [project-srv/internal/project/usecase/new.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/new.go)
  - inject lifecycle gateway interface

## 3.5 Repository layer

- [project-srv/internal/project/repository/interface.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/repository/interface.go)
  - có thể giữ `Update`, hoặc thêm method semantic hơn như `UpdateStatus`
- [project-srv/internal/project/repository/option.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/repository/option.go)
  - nếu cần, tách option cho lifecycle update
- [project-srv/internal/project/repository/postgre/project.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/repository/postgre/project.go)
  - create default = `DRAFT`
  - support archive/unarchive/update status theo rule mới

## 3.6 HTTP delivery

- [project-srv/internal/project/delivery/http/routes.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/routes.go)
  - thêm routes:
    - `POST /projects/:project_id/activate`
    - `POST /projects/:project_id/pause`
    - `POST /projects/:project_id/resume`
    - `POST /projects/:project_id/archive`
    - `POST /projects/:project_id/unarchive`
- [project-srv/internal/project/delivery/http/process_request.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/process_request.go)
  - thêm request parser cho lifecycle endpoints
- [project-srv/internal/project/delivery/http/handlers.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/handlers.go)
  - thêm handlers lifecycle
- [project-srv/internal/project/delivery/http/presenters.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/presenters.go)
  - update enum docs cho `DRAFT`
  - thêm response type nếu cần
- [project-srv/internal/project/delivery/http/errors.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/errors.go)
  - map lifecycle business errors về `400`

## 3.7 Server wiring

- [project-srv/internal/httpserver/handler.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/httpserver/handler.go)
  - wire usecase constructor mới có lifecycle gateway stub/fake

## 3.8 Test files nên tạo

- `[project-srv/internal/project/usecase/lifecycle_test.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/lifecycle_test.go)`
- `[project-srv/internal/project/usecase/project_create_test.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/usecase/project_create_test.go)`
- nếu cần:
  - `[project-srv/internal/project/delivery/http/handlers_test.go](/Users/phongdang/Documents/GitHub/SMAP/project-srv/internal/project/delivery/http/handlers_test.go)`

## 4. Trình tự hiện thực đề xuất

## Step 1: Migration + enum

Làm trước để mọi layer sau cùng nhìn một model.

### Việc làm

- tạo migration `000003_project_status_draft_lifecycle.sql`
- thêm `DRAFT` vào enum `schema_project.project_status`
- set default `projects.status = DRAFT`
- regenerate `sqlboiler`

### Review point

- DB enum đúng
- generated code build được

## Step 2: Domain + repository

### Việc làm

- thêm `ProjectStatusDraft`
- sửa repository create default thành `DRAFT`
- đảm bảo list/detail/update map đúng status mới

### Review point

- tạo project mới ra `DRAFT`
- API detail/list không bị vỡ enum

## Step 3: Lifecycle usecase

### Việc làm

- thêm lifecycle inputs/errors
- thêm usecase methods:
  - `Activate`
  - `Pause`
  - `Resume`
  - `Unarchive`
- rule:
  - `Activate` gọi lifecycle gateway để lấy readiness
  - nếu readiness fail -> business error `400`
  - nếu readiness pass nhưng gateway infra fail -> `500`

### Review point

- transition rule rõ và không chồng chéo
- error semantics đúng

## Step 4: Public HTTP endpoints

### Việc làm

- expose các route lifecycle
- map response/error theo contract đã chốt
- archive dùng `POST /projects/:id/archive`
- unarchive dùng `POST /projects/:id/unarchive`

### Review point

- route shape thống nhất
- swagger/comments cập nhật đúng

## Step 5: Tests tối thiểu

### Usecase tests bắt buộc

- create project -> status `DRAFT`
- `DRAFT -> ACTIVE` khi readiness pass
- activate fail nếu:
  - không có datasource
  - missing dry run
  - dry run latest failed
  - passive unconfirmed
- `ACTIVE -> PAUSED`
- `PAUSED -> ACTIVE`
- `ARCHIVED -> PAUSED`
- transition invalid trả business error

## 5. Response/Error contract trong Phase 1

## 5.1 Public project lifecycle endpoints

- business/input error -> `400`
- infra error -> `500`
- auth vẫn theo middleware hiện có

### Ví dụ

- activate nhưng readiness fail -> `400`
- activate nhưng ingest gateway timeout -> `500`
- resume từ `DRAFT` -> `400`

## 6. Ngoài scope Phase 1

- concrete HTTP client gọi `ingest-srv`
- internal endpoints ở `ingest-srv`
- Kafka producer/consumer thật
- real passive confirm flow
- real target dry run execution

## 7. Acceptance criteria của Phase 1

- project mới tạo luôn là `DRAFT`
- project có public lifecycle endpoints đủ:
  - activate
  - pause
  - resume
  - archive
  - unarchive
- usecase layer encode đúng state transition
- code build sau migration + sqlboiler regen
- có test cơ bản cho create + lifecycle

## 8. Checklist review

- [ ] Migration thêm `DRAFT` rõ ràng và an toàn
- [ ] Repository create không còn default `ACTIVE`
- [ ] Domain model có `DRAFT`
- [ ] Lifecycle usecase không gọi thẳng HTTP client thật
- [ ] Lifecycle gateway được abstract qua interface
- [ ] Public routes lifecycle đã mở đủ
- [ ] Error map đúng `400` business, `500` infra
- [ ] Có test cho transition chính

## 9. Rủi ro cần để ý

- regen `sqlboiler` có thể kéo theo nhiều file generated thay đổi
- nếu cố nhét concrete ingest client ngay ở Phase 1, review sẽ bị loãng và khó isolate bug
- nếu không thêm test cho `DRAFT`, rất dễ regress về default `ACTIVE`
