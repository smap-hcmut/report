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

- Các mục trong `5.3` hiện chưa đồng đều về mức độ hoàn thiện của phần Data Flow và diagram đi kèm.

### Tình trạng từng mục

- `5.3.1 Identity Service`
  - Đã có phần Data Flow.
  - Đang dùng các hình `user_login.png` và `auth_middleware.png` là asset cũ.
  - Chưa có diagram current-state riêng cho service này.

- `5.3.2 Analytics Service`
  - Đã có phần Data Flow.
  - Nội dung đã được kéo về đúng current implementation hơn.
  - Tuy nhiên các hình `analytic-component-diagram.png`, `analytics_ingestion.png`, `analytics-pipeline.png` vẫn là asset cũ và cần thay sau.

- `5.3.3 Project Service`
  - Đã có phần Data Flow.
  - Nội dung đã được kéo về đúng current implementation hơn.
  - Các hình `project-component-diagram.png`, `project_create.png`, `execute_project.png` vẫn là asset cũ.
  - Flow crisis configuration hiện mới mô tả bằng văn bản, chưa có hình riêng.

- `5.3.4 Ingest Service`
  - Đã có phần Data Flow bằng văn bản.
  - Chưa có hình Data Flow đi kèm như các mục khác.
  - Nếu bổ sung sau, nên ưu tiên hình cho execution plane, dry run và completion handling + UAP publishing.

- `5.3.5 WebSocket Service`
  - Đã có phần Data Flow.
  - Nội dung vẫn còn bám service set và narrative cũ.
  - Các hình `websocket-component-diagram.png`, `webSocket_connection.png`, `real-time.png` là asset cũ và cần thay sau.

- `5.3.6 Web UI`
  - Đã có phần Data Flow nhưng chưa hoàn chỉnh: flow thứ hai chỉ còn caption, chưa có hình thực sự.
  - Toàn bộ phần component, data flow và UI gallery vẫn đang bám narrative cũ.
  - Các hình `webui-component-diagram.png`, `authen.png`, các hình UI và `trend.png` là asset cũ và cần thay sau.

### Tổng kết rà soát

- Các mục đã được kéo về current implementation tốt hơn: `5.3.1`, `5.3.2`, `5.3.3`, `5.3.4`.
- Các mục còn lệch mạnh hoặc còn bám asset cũ: `5.3.5`, `5.3.6`.
- Chưa có mục nào trong `5.3` có bộ diagram mới hoàn chỉnh bám current-state như `4.5`.
- Khi hoàn thiện sau, nên thay diagram theo từng service hoặc runtime lane, thay vì tiếp tục dùng asset legacy hiện tại.
