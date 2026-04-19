# Note - Section 3.3

## Khác gì so với bản cũ

- Bản cũ nghiêng mạnh về RabbitMQ và message queue truyền thống.
- Chưa có mục riêng cho Kafka.
- Chưa tách rõ `Publish/Subscribe`, `Event-Driven Architecture`, `delivery semantics` và các khái niệm như `ordering`, `retention`, `idempotency`, `consumer group`.
- Bảng so sánh broker dùng một số số liệu cụ thể dễ bị hỏi nguồn.

## Bản hiện tại đã chỉnh gì

- Bổ sung mục riêng cho `Apache Kafka`.
- Tách rõ `Producer-Consumer`, `Publish/Subscribe và Event-Driven Architecture`, và `Delivery Semantics`.
- Cập nhật bảng so sánh broker theo hướng định tính, dễ đọc hơn và ít overclaim hơn.
- Thêm đoạn kết nối với current architecture của SMAP: RabbitMQ cho lane task/runtime, Kafka cho event propagation và pipeline bất đồng bộ, hệ thống không hoàn toàn event-driven end-to-end vì vẫn có lane internal HTTP.
