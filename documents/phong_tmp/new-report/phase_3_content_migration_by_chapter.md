# Phase 3: Content Migration by Chapter

## Mục tiêu

Migrate nội dung từ `report_SMAP/phong_tmp/new-report/thesis` sang shell Typst tại `report_SMAP/final-report` sau khi khung Typst đã được tái cấu trúc ở Phase 2. Đây là phase lớn nhất, tập trung vào nội dung học thuật và factual correctness.

## Input Truth

- `report_SMAP/phong_tmp/new-report/thesis/*.md`
- Kết quả audit Phase 1
- Kết quả shell restructure Phase 2
- Source code hiện tại của các service
- `e2e-report.md`
- `final-report.md`

## Quy tắc migrate

- Ưu tiên `semantic equivalence`, không copy máy móc Markdown sang Typst.
- Đoạn nào trái current implementation phải rewrite trước khi port.
- Đoạn nào chỉ là working note, internal note hoặc implementation scratch thì không đưa vào bản nộp.
- Đoạn nào chưa đủ bằng chứng phải diễn đạt như limitation, không được claim như fact.

## Kế hoạch theo chương

### Chương 1-2

Mục tiêu:

- chốt context đề tài
- chốt motivation, objective, scope
- chốt nền tảng lý thuyết và technology background

Việc phải làm:

- port nội dung từ `chapter_1_introduction.md`
- port nội dung từ `chapter_2_theoretical_background_and_technologies.md`
- chuẩn hóa văn phong học thuật
- bỏ hoặc rewrite các đoạn product-heavy nếu không phù hợp với giọng luận văn

### Chương 3-4

Mục tiêu:

- chốt requirements, non-functional requirements, use cases
- chốt system design, data design, module design, sequence diagrams, API design

Việc phải làm:

- port `chapter_3_system_analysis.md`
- port `chapter_4_system_design.md`
- giữ traceability giữa yêu cầu và thiết kế
- rà các đoạn mô tả schema/table/route để khớp current source
- mọi sequence, API, lifecycle phải bám implementation hiện tại hoặc ghi rõ là target/partial

### Chương 5

Mục tiêu:

- mô tả implementation hiện tại một cách chính xác, không bị stale

Việc phải làm:

- port `chapter_5_implementation.md`
- rà đặc biệt các chỗ dễ lệch:
  - service entry points
  - runtime model của `scapper-srv`
  - lifecycle logic
  - `domain_type_code`
  - ingest -> analysis -> knowledge flow
- chỉ dùng code snippets còn đúng với source hiện tại

### Chương 6

Mục tiêu:

- biến chương đánh giá thành chương có bằng chứng mạnh hơn current draft

Việc phải làm:

- port `chapter_6_evaluation_and_testing.md`
- tích hợp thêm bằng chứng từ `e2e-report.md` và `final-report.md`
- phân tách rõ:
  - source-level test evidence
  - integration/E2E evidence
  - những gì chưa được chứng minh bằng real-data end-to-end
- không overclaim rằng hệ thống đã crawl/analyze dữ liệu thực tế hoàn chỉnh nếu chưa có bằng chứng đủ mạnh

### Chương 7

Mục tiêu:

- đóng vòng mục tiêu luận văn
- nêu đóng góp, giới hạn và hướng phát triển

Việc phải làm:

- port `chapter_7_conclusion.md`
- đảm bảo conclusion đóng vòng với Chương 1 và Chương 6
- tăng giọng học thuật, giảm giọng “engineering memo”

## Trạng thái cần theo dõi

Mỗi chapter phải được gán một trạng thái:

- `ported`
- `rewritten`
- `pending verification`

Gợi ý dùng bảng theo dõi:

| Chapter | Trạng thái | Ghi chú |
| --- | --- | --- |
| Chapter 1 |  |  |
| Chapter 2 |  |  |
| Chapter 3 |  |  |
| Chapter 4 |  |  |
| Chapter 5 |  |  |
| Chapter 6 |  |  |
| Chapter 7 |  |  |

## Deliverables

- Nội dung Typst của từng chapter đã được port hoặc rewrite.
- Bảng trạng thái `ported / rewritten / pending verification`.
- Danh sách factual checks đã qua cho mỗi chapter.

## Checklist hoàn thành

- [ ] Chương 1-2 đã bám thesis mới
- [ ] Chương 3-4 đã bám thesis mới và khớp source
- [ ] Chương 5 đã được update theo implementation hiện tại
- [ ] Chương 6 đã tích hợp E2E/final integration evidence
- [ ] Chương 7 đã đóng vòng với mục tiêu và đánh giá
- [ ] Không còn đoạn working-note style trong thân luận văn
- [ ] Mỗi chapter đã có trạng thái rõ ràng
