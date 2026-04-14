# Phase 4: Figures, Tables, References, and Appendix

## Mục tiêu

Chuẩn hóa toàn bộ hiện vật hỗ trợ để bản nộp chính thức không chỉ đúng nội dung mà còn đủ chuẩn về hình, bảng, references và appendix.

## Input Truth

- `report/thesis/images/...`
- `report/thesis/list_of_figures.md`
- `report/thesis/list_of_tables.md`
- `report/thesis/references.md`
- `report/thesis/00_technology_inventory.md`
- `report/thesis/01_source_evidence_matrix.md`
- `document/reporting/images/...`

## Việc phải làm

### 1. Chuẩn hóa figures

Quy tắc chọn hình:

- ưu tiên hình trong `report/thesis/images/...`
- chỉ tái dùng hình cũ trong `document/reporting/images` nếu:
  - nội dung còn đúng với current implementation
  - chất lượng đủ để nộp
  - không mâu thuẫn với chapter text mới

Phải lập danh sách:

- hình giữ nguyên
- hình cần verify thêm
- hình phải thay
- hình phải bỏ

### 2. Chuẩn hóa tables

Quy tắc:

- list of tables phải khớp bảng thật trong bản Typst cuối
- table numbering phải nhất quán với chapter
- bảng từ thesis mới là canonical
- bảng cũ trong Typst chỉ giữ nếu còn đúng và hỗ trợ chapter text mới

Phải rà đặc biệt:

- các bảng FR/NFR
- các bảng schema/data dictionary
- các bảng module mapping
- các bảng evaluation/test matrix

### 3. Chuẩn hóa references

Mục tiêu:

- chuyển `references.md` thành danh mục tham khảo dùng được cho bản nộp
- chuẩn hóa style citation theo format cuối cùng được chọn

Quy tắc:

- external references phải sạch và thống nhất format
- internal references giữ có chọn lọc
- các internal evidence quá sâu nên chuyển xuống appendix nếu làm phần references chính bị nặng

### 4. Chốt appendix strategy

Appendix cần chứa:

- `00_technology_inventory.md`
- `01_source_evidence_matrix.md`
- supporting materials/checklists nếu cần giữ để hội đồng tra cứu

Không để appendix lấn át thân bài. Appendix chỉ hỗ trợ kiểm chứng, không thay thân luận văn.

### 5. Đồng bộ list files và asset links

Phải kiểm tra:

- list of figures khớp asset thật
- list of tables khớp bảng thật
- mọi ảnh dùng trong Typst đều còn tồn tại
- caption và nội dung trong chapter khớp với list files

## Deliverables

- Danh sách figures `keep / verify / replace / drop`
- Danh sách tables `keep / rewrite / drop`
- Bộ references đã chuẩn hóa cho bản nộp
- Appendix strategy và danh sách file appendix cuối cùng

## Checklist hoàn thành

- [ ] Đã chốt hình nào là canonical
- [ ] Đã loại các hình cũ lệch source
- [ ] `list_of_figures` khớp asset thật
- [ ] `list_of_tables` khớp bảng thật
- [ ] `references` đã được chuẩn hóa cho bản nộp
- [ ] Appendix đã được giới hạn đúng vai trò supporting materials
- [ ] Không còn asset nào được dùng nhưng không rõ nguồn hoặc không còn đúng
