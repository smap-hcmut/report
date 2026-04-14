# Phase 1: Audit and Source of Truth

## Mục tiêu

Khóa lại hai nguồn sự thật trước khi chỉnh report nộp chính thức:

- `report/thesis/*.md` là `content truth`
- `document/reporting/*.typ` là `layout truth`

Phase này không sửa nội dung nộp ngay. Mục tiêu là audit để biết:

- phần nào của Typst cũ còn dùng được
- phần nào đã lệch source hiện tại
- phần nào phải bỏ hoặc viết lại hoàn toàn

## Input Truth

- Bộ nội dung mẫu mới: `report/thesis`
- Bộ Typst nộp cũ: `document/reporting`
- Source code hiện tại của các service liên quan
- Các báo cáo kiểm thử gần đây như `e2e-report.md`, `final-report.md`

## Việc phải làm

### 1. Chốt vai trò của hai nguồn tài liệu

- Xác nhận `report/thesis` là nguồn nội dung chuẩn để migrate.
- Xác nhận `document/reporting` chỉ là shell dàn trang và cấu trúc Typst.
- Không xem nội dung cũ trong `document/reporting` là nguồn sự thật nếu trái source hiện tại.

### 2. Lập bảng đối chiếu current-state

Tạo bảng audit cho từng chapter Typst cũ:

| Khu vực | Tình trạng | Hành động |
| --- | --- | --- |
| Front matter | còn dùng được / cần sửa nhẹ / cần thay | keep / rewrite |
| Chương 1-7 | khớp một phần / lệch mạnh / legacy | port / rewrite / drop |
| Hình | đúng / lỗi thời / không chắc | keep / verify / replace |
| Bảng | đúng / overclaim / không còn phù hợp | keep / rewrite / drop |

Checklist audit tối thiểu:

- chapter mapping cũ có khớp thesis mới không
- mô hình service ownership có còn đúng không
- use case cũ có còn phản ánh current implementation không
- số lượng service, runtime, transport, topic có còn đúng không
- các claim về frontend, CI/CD, survey, deployment, AI pipeline có bằng chứng thật không

### 3. Tạo danh sách legacy content không được giữ

Phải có một checklist rõ các nhóm nội dung cũ không được kéo sang bản nộp:

- claim về survey hoặc user research nếu không có artifact chính thức
- claim về frontend stack cụ thể nếu source hiện tại không xác nhận
- claim về CI/CD implementation nếu không có workflow/manifests thật
- claim về deployment topology cũ không còn đúng với current source
- service/component cũ không còn là owner hiện tại
- use case cũ mang tính product vision nhưng không còn bám backend/source
- target metrics không có benchmark evidence

### 4. Lập mapping `old typst -> new thesis`

Tạo bảng mapping tối thiểu:

| Typst cũ | Thesis mới | Kết luận |
| --- | --- | --- |
| `chapter_0` | abstract / acknowledgements / abbreviations | keep shell, rewrite content |
| `chapter_1` | `chapter_1_introduction.md` | rewrite theo thesis mới |
| `chapter_2` | `chapter_2_theoretical_background_and_technologies.md` | rewrite |
| `chapter_3` | `chapter_3_system_analysis.md` | rewrite / port theo section |
| `chapter_4` | `chapter_4_system_design.md` | rewrite / port theo section |
| `chapter_5` | `chapter_5_implementation.md` | rewrite / port theo section |
| `chapter_6` | `chapter_6_evaluation_and_testing.md` | rewrite + thêm E2E evidence |
| `chapter_7` | `chapter_7_conclusion.md` | rewrite theo thesis mới |
| `chapter_8` | appendix materials | keep shell, rebuild content |

## Deliverables

- Một bảng `source of truth` chốt vai trò từng thư mục.
- Một bảng `old typst -> new thesis`.
- Một danh sách `legacy content phải bỏ / rewrite`.
- Một danh sách hình và bảng cần verify ở phase sau.

## Checklist hoàn thành

- [ ] Đã chốt `report/thesis` là `content truth`
- [ ] Đã chốt `document/reporting` là `layout truth`
- [ ] Đã có bảng mapping chapter cũ sang chapter mới
- [ ] Đã liệt kê hết các nhóm claim cũ không được giữ
- [ ] Đã đánh dấu được các khu vực `keep / rewrite / drop`
- [ ] Không còn phần nào bị mơ hồ giữa `current implementation` và `legacy reporting draft`
