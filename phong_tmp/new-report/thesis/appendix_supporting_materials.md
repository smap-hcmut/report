# Appendix: Supporting Materials

## A. Purpose of the Appendix

Appendix này tập hợp các hiện vật hỗ trợ nhưng không nhất thiết phải đặt trong phần nội dung chính của luận văn. Mục tiêu là giúp người đọc có thể lần ngược từ các kết luận trong thân luận văn sang các nguồn bằng chứng kỹ thuật cụ thể mà không làm gián đoạn mạch trình bày chính.

## B. Technical Evidence Files

Các file hỗ trợ kỹ thuật quan trọng nhất gồm:

- `00_technology_inventory.md`: danh sách công nghệ được xác nhận trực tiếp từ mã nguồn
- `01_source_evidence_matrix.md`: ma trận nối capability với file nguồn và hàm hiện thực
- `list_of_figures.md`: danh sách hình minh họa trong luận văn
- `list_of_tables.md`: danh sách bảng biểu trong luận văn

Các file này nên được xem như phụ lục kỹ thuật. Trong phiên bản nộp hoàn chỉnh, chúng có thể được đặt ở cuối tài liệu hoặc được tích hợp vào phần appendix chính thức tùy theo yêu cầu định dạng của khoa.

## C. Evidence Interpretation Rules

Luận văn này áp dụng ba quy tắc diễn giải bằng chứng.

Thứ nhất, công nghệ chỉ được xem là hiện diện nếu có dấu vết trực tiếp trong `go.mod`, `pyproject.toml`, `requirements.txt`, `Dockerfile`, `docker-compose`, `deployment.yaml`, `hpa.yaml` hoặc file cấu hình có liên quan.

Thứ hai, khi một tính năng được mô tả ở Chương 5, luận văn ưu tiên liên kết tới file và hàm thực tế. Nếu chỉ có route nhưng chưa tìm được usecase hoặc repository cụ thể, điều đó phải được nêu đúng như giới hạn của bằng chứng.

Thứ ba, các khác biệt giữa `current`, `target` và `legacy` phải được giữ rõ trong toàn bộ tài liệu. Một contract tương lai hoặc một kiến trúc mục tiêu không được phép bị diễn đạt như thể đó là runtime fact nếu mã nguồn hiện tại chưa chứng minh điều đó.

## D. Suggested Final Packaging Order

Đối với bản nộp hoàn chỉnh, thứ tự đóng gói tài liệu được khuyến nghị như sau:

1. Bìa luận văn
2. Abstract
3. Acknowledgements
4. Abbreviations
5. Mục lục
6. List of Figures
7. List of Tables
8. Chapter 1 đến Chapter 7
9. Appendix: Supporting Materials
10. Tài liệu tham khảo nội bộ hoặc appendix kỹ thuật mở rộng nếu cần

## E. Scope Note

Appendix này không thay thế cho nội dung chính của luận văn. Nó chỉ đóng vai trò hỗ trợ việc kiểm chứng, tra cứu và dàn trang. Các kết luận học thuật vẫn phải được trình bày trong các chương chính, đặc biệt ở Chương 3 đến Chương 7.
