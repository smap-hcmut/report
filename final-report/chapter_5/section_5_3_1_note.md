# Note - Section 5.3.1

## Khác gì so với bản cũ

- Bản cũ dùng `Collector Service` làm mục đầu tiên của 5.3 và mô tả rất sâu theo mô hình dispatcher, worker, webhook callback và state tracking.
- Phần này không còn khớp với current implementation và cũng kéo cả mục 5.3 theo service set cũ.
- Các diagram, bảng component catalog, data flow và performance targets trong mục cũ đều bám narrative legacy của `Collector Service`.

## Bản hiện tại đã chỉnh gì

- Thay hoàn toàn `5.3.1` bằng `identity-srv` để mở đầu 5.3 bằng một service cốt lõi có bằng chứng hiện thực rõ trong current source.
- Giữ mục này ở đúng tinh thần `Thiết kế chi tiết các dịch vụ`, không viết theo kiểu `tính năng` hay chia thành các lớp lý thuyết/phân tích như trước.
- Tổ chức lại nội dung theo ba ý chính: vai trò của service trong kiến trúc tổng thể, các thành phần chính và cách current source phản ánh các quyết định thiết kế đó.
- Viết lại câu chữ theo hướng ngắn, chia ý rõ hơn để dễ đọc và dễ rà soát hơn trong quá trình hoàn thiện report.

## Ghi chú tạm thời

- Các diagram cũ từng thuộc `Collector Service` không còn phù hợp với mục `5.3.1` mới.
- Nếu sau này cần thêm hình cho mục này, nên dùng diagram hoặc sequence mới bám luồng OAuth2, JWT, cookie và session management của `identity-srv`.
