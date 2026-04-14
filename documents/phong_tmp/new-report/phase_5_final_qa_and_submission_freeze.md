# Phase 5: Final QA and Submission Freeze

## Mục tiêu

Khóa bản nộp cuối cùng sau khi shell, nội dung và hiện vật hỗ trợ đã được migrate. Phase này là lớp kiểm soát chất lượng cuối trước khi freeze bản nộp chính thức.

## Input Truth

- Bản Typst đã migrate xong từ Phase 2-4
- `report_SMAP/phong_tmp/new-report/thesis/submission_checklist.md`
- Source code hiện tại
- Các báo cáo kiểm thử mới nhất

## Việc phải làm

### 1. Compile và kiểm tra assembly

Phải xác nhận:

- Typst compile được
- không thiếu asset
- outline hoạt động đúng
- page numbering đúng
- heading hierarchy đúng
- front matter và appendix vào đúng vị trí

### 2. Rà factual correctness

Kiểm tra chéo toàn tài liệu với current implementation, đặc biệt ở các điểm bắt buộc:

- lifecycle `PENDING | ACTIVE | PAUSED | ARCHIVED`
- `project.crisis_status = NORMAL | WARNING | CRITICAL`
- `domain_type_code` xuyên `project -> ingest -> analysis`
- `analysis-srv` consume `smap.collector.output`
- output topics:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
- `notification-srv` WebSocket route `/ws`
- `scapper-srv` hiện dùng FastAPI app + worker lifespan

### 3. Rà mức độ claim của Chương 6

Phải khóa rõ:

- test evidence nào là source-level
- test evidence nào là integration/E2E
- phần nào mới là pipeline unblocked
- phần nào chưa đủ bằng chứng để claim full real-data end-to-end analytics

### 4. Rà ngôn ngữ học thuật

Checklist:

- giọng văn không còn quá “internal engineering memo”
- thuật ngữ Việt/Anh nhất quán
- hạn chế và future work được trình bày trung thực
- conclusion đóng vòng với objective và evaluation

### 5. Review gates trước khi freeze

Gate 1: `factual correctness`

- source khớp
- không còn mismatch lớn

Gate 2: `academic wording`

- đủ chuẩn văn phong đồ án
- không quá product-marketing

Gate 3: `submission readiness`

- compile được
- hình, bảng, references, appendix đầy đủ
- checklist nộp đạt

## Deliverables

- Một bản `freeze candidate`
- Một danh sách lỗi còn lại nếu có
- Một quyết định rõ:
  - `ready for submission`
  - hoặc `needs final fixes`

## Checklist hoàn thành

- [ ] Typst compile không lỗi
- [ ] Mục lục, số trang, heading hierarchy đúng
- [ ] Không còn claim lệch implementation
- [ ] Chương 6 không overclaim dữ liệu thực tế nếu chưa đủ bằng chứng
- [ ] Chương 7 đóng vòng với Chương 1 và Chương 6
- [ ] Ngôn ngữ học thuật đã được rà
- [ ] Figures, tables, references, appendix đã ổn
- [ ] Đã có freeze candidate cuối
