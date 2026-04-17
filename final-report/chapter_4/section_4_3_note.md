# Note - Section 4.3

## Khác gì so với bản cũ

- Bản cũ giữ đúng tinh thần viết về yêu cầu phi chức năng, nhưng đi quá sâu vào các metrics và target số cứng.
- Nhiều chỉ số như throughput, latency, coverage, rollback time, concurrent WebSocket connections hoặc các ràng buộc compliance được viết rất cụ thể nhưng chưa có benchmark hoặc artifact tương ứng để bảo vệ.
- Một số phần bảo mật còn bám logic cũ như password policy, trong khi current auth stack của SMAP đã nghiêng rõ hơn về OAuth2, JWT và HttpOnly cookie.

## Bản hiện tại đã chỉnh gì

- Giữ lại khung lớn của mục 4.3 nhưng viết lại theo hướng evidence-based.
- Tách phần nội dung thành `Đặc tính kiến trúc` và `Thuộc tính chất lượng` với phạm vi rõ ràng hơn.
- Bỏ phần lớn các số cứng khó bảo vệ, thay bằng các chỉ báo đánh giá và định hướng chất lượng có thể nối với current implementation.
- Đồng bộ các nhóm NFR với bộ yêu cầu phi chức năng đã chốt ở source-of-truth: Performance, Security, Availability, Scalability, Data Integrity, Modularity và Observability.
- Chốt lại phần cuối theo hướng xem NFR là bộ tiêu chí thiết kế và đánh giá, không phải danh sách cam kết benchmark tuyệt đối khi chưa có thực nghiệm tương ứng.
