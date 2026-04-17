# Note - Section 4.5

## Khác gì so với bản cũ

- Bản cũ sử dụng toàn bộ bộ activity diagram legacy và bám mạnh vào product flow cũ như wizard project, export report, trend dashboard và crisis monitor.
- Nhiều caption cũ mô tả hành vi ở mức UI hoặc flow sản phẩm cũ, không còn phản ánh tốt current implementation của SMAP.
- Bộ hình cũ cũng không còn khớp với actor/use case/functional requirements mới đã được chỉnh ở các mục 4.1, 4.2 và 4.4.

## Bản hiện tại đã chỉnh gì

- Viết lại toàn bộ mục 4.5 theo hướng current-state diagrams.
- Thay các hình legacy bằng các sơ đồ mới đã được chuẩn bị và audit trong `report/documents/phong_tmp/new-report/diagrams`.
- Chuyển trục mô tả từ product flow cũ sang các lane xử lý chính của hệ thống hiện tại: cấu hình ngữ cảnh nghiệp vụ, project lifecycle control, dry run, crawl runtime completion, analytics-to-knowledge, search/chat và realtime delivery.
- Giữ phần giải thích ở mức quy trình hệ thống, không đi sâu vào UI behavior không còn là trọng tâm của current report.
