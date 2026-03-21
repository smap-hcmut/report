# 06. Gap Register

## Mục đích

Tài liệu này ghi lại các branch/domain đã xuất hiện trong code nhưng **chưa hoàn chỉnh** hoặc **chưa có runtime contract đầy đủ**. Chúng không được coi là behavior chính thức hoàn thiện trong BRD chính.

## Gap List

### GAP-01 Passive source + onboarding

**Observed behavior**
- `FILE_UPLOAD` và `WEBHOOK` đã có model/state (`SourceType`, `SourceCategory`, `OnboardingStatus`).
- `project_lifecycle` hiện đọc `onboarding_status == CONFIRMED` như một placeholder readiness gate.
- `datasource.Create(...)` cho passive source hiện chỉ persist base datasource.

**Why it is incomplete**
- Chưa có preview/analyze/confirm onboarding flow thật.
- Chưa có runtime lifecycle hoàn chỉnh cho passive source.
- Readiness branch hiện chỉ là temporary assumption.

**Code evidence**
- `ingest-srv/internal/model/data_source.go`
- `ingest-srv/internal/datasource/usecase/datasource.go`
- `ingest-srv/internal/datasource/usecase/project_lifecycle.go`
- `ingest-srv/internal/datasource/repository/postgre/datasource.go`

**Impact**
- Không nên mô tả passive source như feature hoàn chỉnh trong BRD chính.
- Coverage hiện chỉ nên ghi nhận placeholder gate.

### GAP-02 Profile target runtime

**Observed behavior**
- `PROFILE` là target type hợp lệ.
- API create/list/detail/update/delete profile target đã tồn tại.
- Execution mapping hiện không có nhánh runtime hoàn chỉnh cho `PROFILE`.

**Why it is incomplete**
- `buildDispatchSpecs(...)` hiện chỉ support:
  - `TIKTOK + KEYWORD`
  - `FACEBOOK + POST_URL`
- Dry-run/execution/scheduler path cho `PROFILE` chưa có runtime contract đầy đủ.

**Code evidence**
- `ingest-srv/internal/datasource/usecase/target.go`
- `ingest-srv/internal/execution/usecase/helpers.go`

**Impact**
- BRD chính chỉ ghi `PROFILE CRUD implemented`.
- Runtime spec cho `PROFILE` phải để `Partially implemented`.

### GAP-03 Single datasource lifecycle HTTP exposure

**Observed behavior**
- `ActivateDataSource`, `PauseDataSource`, `ResumeDataSource` đã có usecase.
- Hiện chưa thấy public/internal HTTP route riêng để black-box E2E thuần API cho chúng.

**Code evidence**
- `ingest-srv/internal/datasource/usecase/datasource_lifecycle.go`
- `ingest-srv/internal/datasource/delivery/http/routes.go`

**Impact**
- Có capability ở tầng usecase, nhưng acceptance/coverage hiện mới ở mức code-level inference chứ chưa phải API-runtime contract hoàn chỉnh.

### GAP-04 Identity full OAuth business flow

**Observed behavior**
- `identity-srv` có login/callback/logout/me/internal validate.
- Runtime pack hiện chỉ dùng auth boundary và local JWT/internal key semantics.

**Why it is incomplete in this report**
- Không phải trọng tâm runtime core.
- Chưa có E2E product-level sâu cho redirect/session/provider-specific behavior.

**Impact**
- Chỉ mô tả identity như boundary trong BRD pack này.

### GAP-05 Infra resilience / outage behavior

**Observed behavior**
- Batch test đã phủ rất tốt business-invalid không leak `500`.
- Nhưng chưa mô phỏng sâu outage thật của Rabbit/MinIO/DB, reconnect dài, backlog lớn, restart giữa chừng.

**Impact**
- BRD/SRS hiện chỉ có thể mô tả expected boundary behavior, không thể khẳng định long-haul resilience hoàn toàn.

## Needs Clarification

Các điểm cần clarification nếu sau này muốn nâng bộ tài liệu từ runtime-core sang product-complete:
- passive onboarding chuẩn cho `FILE_UPLOAD` và `WEBHOOK`
- runtime mapping chuẩn cho `PROFILE`
- semantics của full identity OAuth user journey
- outage policy chính thức khi Rabbit/MinIO/DB chập chờn dài hạn
