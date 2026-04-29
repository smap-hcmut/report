# Note - Section 5.3

## Khác gì so với bản cũ

- Bản cũ tổ chức mục 5.3 theo service set legacy như `Collector Service`, `Analytics Service`, `Project Service`, `WebSocket Service` và nhiều supporting services không còn khớp với current architecture.
- Nội dung đi rất sâu vào component catalog, data flow, performance targets và diagram của các service cũ, kéo theo narrative không còn đồng bộ với Chương 3, Chương 4 và service ownership đã chốt ở mục 5.2.
- Cách chia theo `Collector`, `Speech2Text`, `WebSocket` cũng làm lệch khỏi cách hệ thống hiện tại đang được tổ chức thành `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv` và `scapper-srv`.

## Bản hiện tại đã chỉnh gì

- Viết lại toàn bộ mục 5.3 theo đúng tinh thần `Thiết kế chi tiết các dịch vụ`, tức tổ chức theo từng service và runtime boundary hiện tại.
- Thay các service cũ bằng các service thực sự đang tồn tại trong current implementation.
- Giữ mô tả ở mức thiết kế chi tiết: vai trò trong kiến trúc, thành phần chính, giao tiếp và quyết định thiết kế, thay vì đi sâu vào product flow legacy.
- Tách rõ `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv` và `scapper-srv` để khớp với Chương 3 và 5.2.

## Ghi chú tạm thời

- Các diagram cũ từng gắn với `5.3` không còn phù hợp với cấu trúc mới của mục này.
- Nếu cần minh họa lại cho `5.3`, nên vẽ bộ diagram mới bám từng service hoặc từng runtime lane hiện tại.
