# Gap Analysis - phong_tmp/crisis/crisis.md

## Verdict

File này là design note cho `crisis + adaptive crawl`, không phản ánh runtime core đã implement. Nó hữu ích như product thinking, nhưng nguy hiểm nếu bị đọc như spec hiện hành.

## Matrix

| Cụm claim cũ | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `Adaptive Crawl = ALWAYS ENABLED` | Adaptive crawl là system behavior mặc định, không cần config riêng. | Current runtime pack không inventory adaptive crawl như implemented behavior chính thức. | High | Đổi thành `Target design` hoặc `Planned behavior`, không nói như fact hiện tại. |
| `Crisis Detection -> Adaptive Crawl Automatic` | Analytics detect crisis -> project handler -> force switch crawl mode -> ingest crawl immediately. | Chưa phải runtime flow đã chốt trong current implementation pack. | High | Đổi các rule này sang `proposed automation`. |
| `Metrics-based Adaptive Crawl` | `analytics.metrics.aggregated` là input active cho project adaptive scheduler. | Hiện không nên mô tả như current runtime contract đã active. | High | Gắn nhãn `future consumer flow`. |
| `Sleep Mode hardcoded` | Sleep mode threshold là behavior tự động hiện hành. | Không có evidence trong runtime core pack cho việc xem đây là implemented fact. | Medium | Chuyển sang `proposed heuristic`. |
| `Call Ingest API: PUT /crawl-mode {mode, interval}` | Project/adaptive runtime đã có caller chính thức tới ingest. | Endpoint crawl-mode có tồn tại, nhưng caller/orchestration chưa nên mô tả như phần runtime đã hoàn thiện. | Medium | Ghi rõ: `endpoint implemented, orchestrator flow not confirmed as runtime core`. |

## Phân tích

### 1. Tài liệu này là product design, không phải code-derived spec

Điểm dễ gây hiểu nhầm:

- văn phong khẳng định,
- có default values cụ thể,
- có system behavior rules,
- có API examples như thể đã stabilized.

Trong khi current runtime pack không hề xem `crisis/adaptive` là domain implemented ở mức tương đương `project lifecycle` hay `dryrun/execution`.

### 2. Những gì vẫn có thể giữ lại

- shape của crisis config,
- reasoning nghiệp vụ cho defaults,
- UX tooltips,
- định hướng về volume/sentiment/influencer triggers.

Những thứ này vẫn có giá trị cho sản phẩm, chỉ là không nên trộn với claim runtime hiện tại.

### 3. Những gì không nên giữ dưới nhãn "current behavior"

- adaptive crawl always enabled,
- automatic mode switching,
- sleep mode hardcoded,
- crisis -> ingest immediate command path như fact,
- metrics/insights event handling như flow đang chạy thật.

## Rewrite đề xuất

### Đổi tiêu đề/nhãn file

Từ:

- `crisis.md`

Sang:

- `crisis-design-proposal.md`
- hoặc `crisis-future-behavior.md`

### Thêm disclaimer đầu file

Ví dụ:

`Tài liệu này mô tả desired product behavior cho crisis detection và adaptive crawl. Đây không phải current runtime contract đã được xác nhận từ implementation hiện tại.`

### Chia nội dung thành 2 lớp

1. `Current implemented`
   - crisis config storage nếu có
   - auth/boundary liên quan nếu có
2. `Planned automation`
   - automatic adaptive crawl
   - metrics consumer
   - sleep mode
   - force crawl mode transitions

## Kết luận

File này không "sai" theo nghĩa design, nhưng sai nếu dùng làm tài liệu implementation hiện tại. Cách xử lý tốt nhất là đổi nhãn từ `spec hiện tại` sang `future design`.
