# Gap Analysis - documents/dataflow-detailed.md

## Verdict

Đây là file có độ lệch kiến trúc rất lớn. Nó mô tả một hệ thống thiên về:

- UI wizard orchestration,
- passive onboarding đầy đủ,
- dryrun qua Kafka riêng,
- adaptive crawl qua project-scheduler,
- topic naming cũ.

Trong khi runtime core hiện tại lại bám vào:

- campaign/project lifecycle,
- datasource/target,
- per-target dryrun,
- RabbitMQ + MinIO completion pipeline,
- internal project/ingest coordination.

## Matrix

| Doc cũ / section | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `Flow 0 - Tạo Campaign & Project` | UI gọi `POST /projects` để tạo project ở `DRAFT`. | Runtime hiện tại project create nằm dưới campaign: `POST /campaigns/:id/projects`. | High | Đổi wizard flow để project create là nested under campaign. |
| `Flow 0 - Data Source setup` | File mô tả `POST /sources`, `upload-sample`, passive source setup khá đầy đủ. | Runtime pack không coi passive onboarding là completed feature; datasource current canonical naming là `datasources`, không phải `sources`. | Critical | Đổi naming `sources -> datasources`; hạ passive onboarding xuống `Planned/Gap`. |
| `Flow 0 - DATA ONBOARDING` | `POST /sources/{id}/schema/preview` và `schema/confirm` là flow chuẩn hiện tại. | Current implementation pack chỉ ghi passive onboarding là gap; chưa nên mô tả preview/confirm như active runtime contract. | Critical | Chuyển section này sang `Future flow` hoặc `Planned passive onboarding`. |
| `Flow 0 - DRY RUN` | UI push Kafka `project.dryrun.requested`, worker consume, worker publish `project.dryrun.completed`. | Runtime hiện tại trigger qua HTTP `POST /datasources/:id/dryrun`, publish task sang RabbitMQ, completion finalize ở ingest consumer; không có flow `project.dryrun.*` làm source of truth. | Critical | Rewrite dryrun flow theo ingest-owned HTTP trigger + RabbitMQ + MinIO artifact. |
| `Flow 0 - ACTIVATE` | Điều kiện activate tóm tắt là onboarding confirmed và dryrun success/warning. | Runtime hiện tại readiness sâu hơn nhiều: datasource existence, passive confirmed placeholder, latest usable dryrun theo target, active target count. | High | Thêm explicit readiness matrix; không tóm gọn bằng 2 điều kiện đơn giản. |
| `Flow 1 - Ingestion` | UAP đi vào topic `analytics.uap.received`. | Canonical topic hiện tại là `smap.collector.output`. | Critical | Sửa ngay topic name để tránh downstream config sai. |
| `Flow 3 - Adaptive Crawl` | Project-scheduler consume metrics rồi gọi `PUT /sources/{id}/crawl-mode`. | Adaptive crawl không nằm trong runtime core đã chốt; flow này hiện chỉ nên xem là planned/aspirational. | High | Dời cả section sang `Future Architecture` hoặc `Planned Adaptive Crawl`. |

## Cụm mismatch chi tiết

### 1. Flow wizard đang over-document UI orchestration

Doc này làm người đọc nghĩ:

- project create là root-level,
- source onboarding là flow chuẩn đang chạy,
- UI là orchestrator tuyệt đối cho mọi bước.

Thực tế runtime pack hiện tại cho thấy:

- campaign/project hierarchy chặt hơn,
- ingest lifecycle/readiness có contract riêng,
- passive onboarding chưa hoàn chỉnh nên không thể xem là flow đã "sống".

### 2. Dryrun ownership đang sai

Trong file cũ:

- project namespace tham gia sâu vào dryrun event naming.

Trong implementation hiện tại:

- dryrun là domain của `ingest-srv`,
- trigger ở ingest API,
- lineage theo datasource + target,
- completion đi qua RabbitMQ/MinIO contract,
- readiness effect quay ngược lên project lifecycle.

Nếu giữ mô tả cũ, boundary giữa `project` và `ingest` sẽ bị hiểu sai.

### 3. Topic naming cũ là lỗi nguy hiểm

Claim cũ:

- `analytics.uap.received`

Canonical topic hiện tại:

- `smap.collector.output`

Đây là lệch `Critical` vì downstream services/config/scripts có thể bám sai topic và pipeline không chạy.

### 4. Adaptive crawl đang là design, chưa phải runtime fact

Doc cũ mô tả rất cụ thể:

- metrics đến,
- project-scheduler đánh giá,
- gọi ingest đổi crawl mode.

Nhưng implementation pack hiện tại không inventory flow này như runtime implemented domain.

Do đó, nếu muốn giữ section này, phải đổi nhãn:

- `Planned Adaptive Architecture`
- không được dùng ngôn ngữ khẳng định như "hệ thống đang vận hành như sau".

## Rewrite đề xuất

### Cấu trúc mới nên là

1. `Current Runtime Flow`
   - create campaign/project
   - create datasource/target
   - readiness
   - dryrun
   - execution/scheduler
2. `Current Data Pipeline`
   - RMQ task
   - scapper worker
   - MinIO artifact
   - `smap.collector.output`
3. `Planned Flows`
   - passive onboarding
   - adaptive crawl
   - crisis orchestration

### Câu chữ nên đổi

- `Hệ thống hiện đang` chỉ dùng cho flow đã có trong code-derived pack.
- `Dự kiến / planned / design option` cho passive onboarding và adaptive crawl.

## Kết luận

Đây là file nên sửa rất sớm vì nó đang trộn `current runtime` với `future design`, làm boundary giữa `project` và `ingest` sai lệch đáng kể.
