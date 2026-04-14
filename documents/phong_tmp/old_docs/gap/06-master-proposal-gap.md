# Gap Analysis - phong_tmp/project/master-proposal.md

## Verdict

`master-proposal.md` là proposal định hướng tốt về business storytelling, nhưng hiện lệch lớn với runtime current ở:

- event-driven activation/pause/resume,
- adaptive crawl,
- crisis orchestration,
- datasource state machine,
- payload/contract được mô tả như đã finalized.

## Matrix

| Cụm claim cũ | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| Project execution flow | Project activate -> publish `project.activated` -> ingest consume -> source `READY -> ACTIVE`. | Runtime hiện tại: project activate gọi ingest internal activate/readiness trước hoặc trong transition; event publish không đủ để mô tả path chính. | Critical | Rewrite activation sequence theo internal readiness + internal activate. |
| Project pause/resume/archive flow | Project update local status rồi publish Kafka, ingest consume để pause/resume/archive datasources. | Runtime hiện tại: project lifecycle command phối hợp trực tiếp với ingest runtime contract; archive from active còn phải pause ingest trước. | Critical | Đổi sequence diagram theo synchronous coordination path hiện tại. |
| "Project Service chỉ phản ứng dựa trên Events" | Project nên tránh HTTP đồng bộ, chủ yếu event-driven. | Current runtime core đang không đi theo pattern này cho lifecycle. | Critical | Chuyển câu này sang `desired future architecture`, không để trong current behavior. |
| Datasource state machine | Chỉ mô tả `PENDING/READY/ACTIVE/PAUSED/COMPLETED/FAILED`, thiếu nuance archive/delete và target-centric runtime. | Runtime thực tế có `ARCHIVED`, soft delete datasource sau archive, target activation invariants, target-centric scheduling. | High | Cập nhật state machine + thêm target runtime semantics. |
| Crisis detection + project.crisis.started | Mô tả như current contract giữa analytics -> project -> notification -> ingest. | Current runtime pack không xem đây là implemented runtime core; đây vẫn là design/planned domain. | High | Chuyển thành `planned crisis domain`; không mô tả như flow đang chạy thật. |
| Adaptive crawl | Metrics tới là project gọi ingest `PUT /sources/{id}/crawl-mode` ngay. | Runtime pack hiện không inventory adaptive crawl như implemented domain; old path cũng dùng source naming cũ. | High | Chuyển sang `future adaptive orchestration`, đồng thời đổi naming nếu giữ lại. |
| Project config payload | `PUT /projects/{project_id}/config` như current contract. | Runtime cũ/khác chỗ dùng `crisis-config`; quan trọng hơn là crisis config không nên bị hiểu là đã gắn chặt vào adaptive runtime hiện hành. | Medium | Nếu giữ payload, ghi rõ đây là `config storage contract`, không đồng nghĩa với runtime crisis engine đã implemented. |

## Mismatch narrative

### 1. Proposal đang mô tả "đích đến", không còn là "trạng thái hiện tại"

Các phần có giọng văn quá khẳng định:

- `Project Service chỉ phản ứng dựa trên Events`
- `Publish project.activated -> ingest consume`
- `analytics.metrics.aggregated -> project -> ingest`
- `project.crisis.started -> notification`

Những câu này phù hợp để làm `target architecture`, nhưng không còn phù hợp nếu để trong file được đọc như tài liệu current-state.

### 2. Lifecycle project hiện tại đã đi theo hướng thực dụng hơn

Thay vì event choreography thuần:

- runtime đang dùng internal readiness/query/command,
- lifecycle guard nằm sát code hơn,
- transition an toàn hơn cho activate/resume/archive.

Điều này khiến proposal cũ bị "thiên thiết kế" hơn "thiên contract".

### 3. Crisis/adaptive đang bị over-promised

Proposal cũ mô tả rất sâu:

- consume metrics,
- evaluate thresholds,
- store alerts,
- notify,
- force crawl mode.

Trong runtime pack hiện tại, các phần này chưa được đóng gói thành implemented domain chính thức.

## Rewrite đề xuất

### Giữ lại những gì có giá trị

- Business context của `Campaign -> Project -> Datasource`.
- Ý nghĩa nghiệp vụ của crisis config.
- Tư duy phân tầng trách nhiệm giữa project và ingest.

### Đổi nhãn các section sau

- `Current Runtime`:
  - project lifecycle thật
  - datasource/target runtime thật
  - dryrun/execution thật
- `Target Architecture`:
  - crisis detection consumer
  - adaptive crawl
  - project.crisis.started orchestration

### Câu mở đầu nên đổi

Thay vì:

- "Project Service chỉ phản ứng dựa trên Events"

Nên dùng:

- "Thiết kế đích mong muốn là event-driven nhiều hơn; tuy nhiên runtime hiện tại vẫn dùng internal command/readiness path cho project lifecycle."

## Kết luận

Proposal này vẫn hữu ích để giữ `vision`, nhưng không nên dùng làm current BRD/SRS. Nếu giữ nguyên, nó sẽ kéo đội quay lại một kiến trúc chưa phải đường runtime đang chạy thật.
