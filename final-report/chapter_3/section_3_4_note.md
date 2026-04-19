# Note - Section 3.4

## Khác gì so với bản cũ

- Bản cũ có lỗi chính tả và một số diễn đạt chưa mượt ở phần `Redis Pub/Sub`.
- Bảng so sánh real-time protocols dùng số liệu độ trễ cụ thể dễ bị hỏi nguồn.
- Chưa có câu nối sang cách giao tiếp thời gian thực trong SMAP.

## Bản hiện tại đã chỉnh gì

- Sửa lại phần diễn giải `Redis Pub/Sub` theo hướng rõ hơn và tự nhiên hơn.
- Bỏ các số cứng trong bảng latency, chuyển sang mức đánh giá định tính.
- Chỉnh một số cụm từ trong bảng cho dễ đọc hơn.
- Thêm một câu kết nối với SMAP ở cuối mục, nhấn vào WebSocket delivery và Redis Pub/Sub fanout.
