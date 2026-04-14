# Thesis Submission Checklist

## 1. Structural Checklist

- [ ] Có bìa luận văn đúng mẫu
- [ ] Có `Abstract`
- [ ] Có `Acknowledgements` nếu cần
- [ ] Có `Abbreviations`
- [ ] Có mục lục
- [ ] Có `List of Figures`
- [ ] Có `List of Tables`
- [ ] Có đủ Chương 1 đến Chương 7
- [ ] Có appendix hoặc phụ lục hỗ trợ nếu cần
- [ ] Có danh sách tài liệu tham khảo

## 2. Content Consistency Checklist

- [ ] Công nghệ trong Chương 2 đều có bằng chứng từ mã nguồn
- [ ] Functional requirements ở Chương 3 khớp với thiết kế ở Chương 4
- [ ] Thiết kế ở Chương 4 khớp với hiện thực hóa ở Chương 5
- [ ] Đánh giá ở Chương 6 không vượt quá bằng chứng test hiện có
- [ ] Kết luận ở Chương 7 đóng vòng với mục tiêu ở Chương 1
- [ ] Các phần `current`, `target`, `legacy` không bị trộn lẫn

## 3. Diagram Checklist

- [ ] Mọi hình đều có caption trực tiếp trong chương
- [ ] `List of Figures` khớp với hình thực tế
- [ ] Hình dùng định dạng ổn định như `SVG`
- [ ] Sequence diagram có mô tả luồng dữ liệu ít nhất hai đoạn văn
- [ ] Hình không bị lỗi render, tràn chữ hoặc sai notation

## 4. Table Checklist

- [ ] Mọi bảng quan trọng đều có caption trực tiếp trong chương
- [ ] `List of Tables` khớp với bảng thực tế
- [ ] Data dictionary đã đủ các bảng trọng yếu
- [ ] Có traceability matrix giữa yêu cầu và hiện thực
- [ ] Có test matrix hoặc coverage matrix ở Chương 6

## 5. Evidence Checklist

- [ ] Tính năng mô tả ở Chương 5 đều có file và hàm hiện thực
- [ ] Những phần chưa có bằng chứng đã được ghi rõ là giới hạn
- [ ] Frontend/CI-CD chỉ được khẳng định nếu có source hoặc manifest thực tế
- [ ] Các số liệu hiệu năng chỉ được khẳng định khi có hiện vật hỗ trợ

## 6. Packaging Checklist

- [ ] `thesis_master.md` phản ánh đúng thứ tự đóng gói cuối
- [ ] `references.md` đã được rà lại trước khi nộp
- [ ] `appendix_supporting_materials.md` khớp với các file kỹ thuật hiện có
- [ ] Toàn bộ file Markdown đã được rà lại lỗi chính tả và lỗi số hiệu
