# Note - Section 5.2

## Khác gì so với bản cũ

- Bản cũ bám mạnh vào service set cũ như `Collector Service`, `Speech2Text Service`, `WebSocket Service` và storage stack cũ có `MongoDB`.
- Diagram context/container, service decomposition và data store choices không còn khớp với current implementation đã chốt ở Chương 3 và Chương 4.
- Mục này cũng dùng nhiều ma trận điểm số và trọng số khá cứng, khó bảo vệ nếu không có cơ sở chấm điểm rõ ràng.

## Bản hiện tại đã chỉnh gì

- Viết lại toàn bộ theo current architecture của SMAP.
- Giữ khung `lựa chọn kiến trúc`, `kiến trúc tổng thể`, `service ownership`, `technology stack`, `tổng kết`, nhưng thay toàn bộ narrative cũ bằng current-state model.
- Dùng lại hình kiến trúc tổng thể current-state đã chuẩn bị trong bộ source-of-truth mới.
- Đồng bộ service boundaries với các service hiện tại: `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`, `scapper-srv`.
- Đồng bộ storage và transport choices với Chương 3: PostgreSQL, Redis, Qdrant, MinIO, internal HTTP, RabbitMQ, Kafka, Redis Pub/Sub.
- Bỏ phần lớn các scoring matrix và con số cứng khó bảo vệ, chuyển sang đánh giá định tính và justification theo architectural drivers.
