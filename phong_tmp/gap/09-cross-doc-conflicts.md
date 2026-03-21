# Cross-Doc Conflicts

Mục tiêu file này là ghi lại những chỗ các docs cũ tự mâu thuẫn với nhau, để tránh việc team chọn nhầm "version of truth".

## 1. Project lifecycle architecture

### Conflict

- `documents/project-service-status.md`
  - nói project service chưa có internal API đáng kể, Kafka consumer TODO, adaptive trống.
- `phong_tmp/project/master-proposal.md`
  - mô tả project lifecycle và adaptive crawl như flow event-driven gần như hoàn chỉnh.
- `documents/migration-plan.md`
  - mô tả chi tiết cả Kafka lifecycle events, adaptive crawl orchestration, config_status, dashboard orchestration.

### Ý nghĩa

Ba tài liệu này không thể cùng đúng ở cùng một thời điểm. Nếu đọc ngẫu nhiên một file, người đọc sẽ có nhận thức khác hẳn về phạm vi hiện thực của `project-srv`.

### Nên xử lý

- Giữ `project-service-status` như current-state reference sau khi rewrite.
- Chuyển `master-proposal` và các phần tương ứng trong `migration-plan` thành `target architecture`.

## 2. Dryrun ownership và transport

### Conflict

- `documents/ingest-service-status.md`
  - mô tả dryrun kiểu usecase trực tiếp `exec.Execute()`.
- `phong_tmp/ingest/api_config_project_ingest.md`
  - mô tả dryrun là control-plane only, không tạo external task, không publish RabbitMQ.
- `documents/dataflow-detailed.md`
  - mô tả dryrun qua Kafka `project.dryrun.requested/completed`.
- `phong_tmp/code-derived-brd-srs`
  - dryrun per-target, publish task, worker artifact, completion consumer.

### Ý nghĩa

Bốn mô tả này thuộc bốn mô hình khác nhau. Nếu không chốt lại, mọi tài liệu downstream về testing, FE, observability đều sẽ lệch.

### Nên xử lý

- Chốt duy nhất một dryrun current-state theo code-derived pack.
- Gắn nhãn historical/planned cho các flow còn lại.

## 3. Passive onboarding

### Conflict

- `documents/dataflow-detailed.md`
  - mô tả `schema/preview` và `schema/confirm` như flow wizard chuẩn.
- `documents/migration-plan.md`
  - mô tả `FILE_UPLOAD/WEBHOOK` onboarding khá hoàn chỉnh và đi tới `READY/ACTIVE/COMPLETED`.
- `phong_tmp/code-derived-brd-srs/06-gap-register.md`
  - ghi rõ passive onboarding chưa hoàn chỉnh, chỉ có placeholder readiness gate.

### Ý nghĩa

Docs cũ đang overstate passive source rất mạnh.

### Nên xử lý

- Chuyển toàn bộ passive onboarding hiện tại sang `Planned/Gap`.
- Chỉ giữ lại những gì current code thật sự có: base datasource persistence + placeholder readiness field usage.

## 4. PROFILE target support

### Conflict

- `documents/ingest-service-status.md` và `migration-plan.md`
  - trình bày `PROFILE` như target loại chuẩn tương đương `KEYWORD` và `POST_URL`.
- `phong_tmp/code-derived-brd-srs`
  - ghi `PROFILE` mới CRUD, runtime mapping chưa hoàn chỉnh.

### Ý nghĩa

Support matrix cũ bị overclaim.

### Nên xử lý

- Tạo support matrix rõ theo `source_type x target_type x runtime support level`.

## 5. Archive vs delete

### Conflict

- `documents/api-endpoints.md`
  - dùng `DELETE` cho archive project/datasource.
- `documents/project-service-status.md`
  - `DELETE /projects/:projectId -> Archive`.
- `code-derived-brd-srs`
  - tách rõ `archive`, `unarchive`, `delete`.

### Ý nghĩa

Đây là conflict nguy hiểm vì tác động trực tiếp lên FE actions, QA testcases, và audit semantics.

### Nên xử lý

- Rewrite toàn bộ endpoint docs và flow docs để `archive` và `delete` là 2 command khác nhau.

## 6. Topic naming

### Conflict

- `documents/dataflow-detailed.md`
  - dùng topic name cũ cho UAP downstream.
- `documents/ingest-service-status.md` và `phong_tmp/ingest/report_ingest.md`
  - dùng `smap.collector.output`.

### Ý nghĩa

Đây là conflict config-level, có thể gây fail pipeline nếu ai đó đọc nhầm tài liệu.

### Nên xử lý

- Chốt canonical topic list ở một file current-state riêng.

## 7. Current-state vs design-state bị trộn

### Conflict gốc

Hầu hết docs cũ đều trộn ba lớp:

- implementation hiện tại,
- proposal/design tương lai,
- roadmap tasks.

### Hậu quả

- Dev mới không biết đâu là flow đang chạy,
- QA không biết test theo route nào,
- FE không biết expectation nào là hiện tại hay planned,
- tài liệu trở thành "đúng theo một phần nào đó" nhưng không dùng được làm source of truth.

### Nên xử lý

Mọi docs cần thêm tag đầu file:

- `Current Runtime`
- `Target Architecture`
- `Roadmap / Proposal`

Nếu một file chứa cả ba lớp, phải tách file.
