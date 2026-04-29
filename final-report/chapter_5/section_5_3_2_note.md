# Note - Section 5.3.2

## Khác gì so với bản cũ

- Bản cũ mô tả Analytics Service theo flow cũ dựa trên RabbitMQ, object storage batch download và `Crawler Services` như nguồn đầu vào chính.
- Component catalog, data flow và dependencies cũ không còn khớp với analytics runtime hiện tại đã chuyển sang Kafka consumer pipeline.
- Traceability cũ cũng lệch vì analytics đang được nối với FR/UC cũ thay vì capability hiện tại của hệ thống.

## Bản hiện tại đã chỉnh gì

- Viết lại `5.3.2` theo `analysis-srv` current implementation.
- Đổi narrative đầu vào sang Kafka intake flow và downstream `analytics.*` topic publishing.
- Cập nhật component catalog theo các thành phần thực sự quan trọng của analytics runtime hiện tại như `ConsumerServer`, `Ingestion Adapter`, `PipelineUseCase`, `PostInsight UseCase` và `Contract Publisher`.
- Chỉnh lại traceability để bám `FR-09` và `UC-05`.

## Ghi chú tạm thời

- Các hình đang dùng trong mục này hiện vẫn là asset cũ và cần được thay bằng diagram current-state tương ứng ở bước hoàn thiện sau.
