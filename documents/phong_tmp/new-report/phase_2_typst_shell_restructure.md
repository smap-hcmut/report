# Phase 2: Typst Shell Restructure

## Mục tiêu

Giữ lại shell Typst cũ để phục vụ nộp chính thức, nhưng tái cấu trúc nó theo đúng thesis mới. Phase này chỉ xử lý khung nộp và chapter wiring, chưa đi sâu migrate toàn bộ nội dung từng chương.

## Input Truth

- `report_SMAP/final-report/main.typ`
- `report_SMAP/final-report/config.typ`
- `report_SMAP/final-report/counters.typ`
- `report_SMAP/phong_tmp/new-report/thesis/thesis_master.md`
- Kết quả audit từ Phase 1

## Việc phải làm

### 1. Giữ các phần shell còn đúng

Giữ làm nền:

- `main.typ`
- `config.typ`
- `counters.typ`
- logo, margin, page numbering, outline, header

Không tự ý đổi visual system nếu không cần cho việc nộp.

### 2. Chốt lại cấu trúc tài liệu chính thức

Khung cuối phải map theo thesis mới:

1. Front matter
2. Chapter 1: Introduction
3. Chapter 2: Theoretical Background and Technologies
4. Chapter 3: System Analysis
5. Chapter 4: System Design
6. Chapter 5: Implementation
7. Chapter 6: Evaluation and Testing
8. Chapter 7: Conclusion
9. Appendix / Supporting Materials
10. References, list of figures, list of tables, abbreviations theo cấu hình nộp cuối

### 3. Tái tổ chức chapter Typst

Quy tắc bắt buộc:

- `chapter_0` giữ front matter, nhưng nội dung phải viết lại theo thesis mới
- `chapter_1` đến `chapter_7` phải phản ánh đúng chapter mới
- `chapter_8` dùng cho appendix / supporting materials
- không giữ chapter naming cũ nếu nó mâu thuẫn với thesis mới
- không vá từng section cũ nếu section model không còn đúng

### 4. Lập sơ đồ `keep / replace / remove`

Phải đánh dấu rõ:

- file shell Typst nào giữ nguyên
- file chapter nào chỉ giữ vỏ
- file section nào thay toàn bộ
- file nào bỏ hẳn khỏi flow nộp cuối

Mức quyết định:

- `keep`: chỉ áp dụng cho shell và utility
- `replace content`: dùng cho chapter/index còn giữ tên file nhưng thay nội dung
- `remove from assembly`: cho chapter/section cũ không còn dùng

### 5. Chốt assembly plan

Tạo một assembly plan để người implement không phải tự đoán:

- `main.typ` include chapter nào theo thứ tự nào
- phần nào đứng trước mục lục, phần nào sau mục lục
- list of figures, list of tables, abbreviations, references sẽ nằm ở đâu trong bản cuối

## Deliverables

- Sơ đồ cấu trúc Typst cuối cùng.
- Mapping file nào `keep`, file nào `replace content`, file nào `remove from assembly`.
- Trình tự include cuối cùng cho `main.typ`.

## Checklist hoàn thành

- [ ] Đã chốt cấu trúc chapter đúng theo `thesis_master.md`
- [ ] Đã xác định rõ shell nào giữ nguyên
- [ ] Đã xác định rõ chapter/section nào chỉ giữ vỏ
- [ ] Đã xác định rõ file cũ nào không được đưa vào assembly cuối
- [ ] Đã có assembly order cuối cùng cho bản nộp
- [ ] Không còn conflict giữa chapter mapping cũ và thesis mới
