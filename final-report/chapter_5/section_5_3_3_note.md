# Note - Section 5.3.3

## Khác gì so với bản cũ

- Bản cũ mô tả `Project Service` như một execution orchestrator theo narrative cũ, gồm publish event tới `Collector Service`, nhận webhook callback và quản lý progress state.
- Các component như `Webhook UseCase`, `RabbitMQ Producer`, `StateUseCase` và các flow `Project Execution` / `Progress Callback` đều bám luồng cũ.
- Traceability cũ chỉ map tới `FR-1`, `FR-2` và `UC-01`, `UC-03`, chưa phản ánh role hiện tại của `project-srv` trong lifecycle control và crisis configuration.

## Bản hiện tại đã chỉnh gì

- Viết lại `5.3.3` theo current `project-srv` implementation.
- Chuyển trọng tâm của service từ execution orchestration sang business context ownership, project lifecycle control và crisis configuration management.
- Cập nhật component catalog theo các thành phần phù hợp hơn như `Project Handler`, `Project UseCase`, `Lifecycle UseCase`, `Crisis Config UseCase`, `Project Repository`, `Ingest Client` và `Lifecycle Event Publisher`.
- Chỉnh traceability để bám `FR-02`, `FR-03`, `FR-04` và `UC-02`, `UC-04`, `UC-08`.

## Ghi chú tạm thời

- Các hình trong mục này hiện vẫn là asset cũ và cần được thay bằng diagram current-state phù hợp hơn ở bước hoàn thiện sau.
