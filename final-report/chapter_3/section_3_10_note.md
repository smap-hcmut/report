# Note - Runtime Entry Positioning In Report

## Mục đích

Khóa lại cách mô tả `api`, `consumer`, `scheduler` trong report và diagram để tránh viết không nhất quán ở các chương sau.

## Rule cần giữ

- Khi viết report, có thể mô tả `api`, `consumer`, `scheduler` như 3 entry riêng.
- Có thể vẽ hoặc mô tả chúng như 3 container/độc lập trong deployment narrative.
- Không cần nhấn mạnh việc hiện tại có thể đang gom trên cùng một server vật lý hay cùng một môi trường chạy.

## Cách diễn đạt ưu tiên

- `api` là entry phục vụ HTTP/WebSocket hoặc public/internal APIs.
- `consumer` là entry chuyên xử lý message/event bất đồng bộ.
- `scheduler` là entry phục vụ scheduling, tick, hoặc trigger job định kỳ.

## Lưu ý cho Chương 3

- Chương 3 là cơ sở lý thuyết, nên không bắt buộc đưa chi tiết này vào nếu không cần.
- Nếu cần liên hệ với hệ thống, chỉ nên viết ở mức tổng quát, không cần giải thích chi tiết deployment runtime hiện tại.

## Lưu ý cho Chương 4-5

- Chương 4 và Chương 5 có thể mô tả 3 entry trên như các runtime roles tách biệt.
- Nếu dùng diagram, ưu tiên cách vẽ tách riêng `api`, `consumer`, `scheduler` để dễ đọc và dễ mapping với trách nhiệm hệ thống.

## Ghi nhớ

- Mục tiêu là giữ deployment narrative rõ ràng và dễ bảo vệ.
- Không cần mô tả theo đúng từng setup tạm thời nếu cách đó làm giảm độ rõ của kiến trúc.

## Khác gì so với bản cũ

- Bản cũ chỉ gồm `Docker` và `Kubernetes`, mô tả khá chung chung.
- Chưa tách rõ `Docker Compose` và `Auto Scaling / Self-Healing`.
- Chưa chốt cách diễn đạt về `api / consumer / scheduler` trong report.

## Bản hiện tại đã chỉnh gì

- Tách cấu trúc thành `Docker`, `Docker Compose`, `Kubernetes`, `Auto Scaling và Self-Healing`.
- Giữ mục này ở mức lý thuyết vừa đủ, không kể quá sâu về deployment thật.
- Khóa lại runtime narrative để khi viết report có thể xem `api / consumer / scheduler` như 3 entry/container tách biệt nếu cần để dễ đọc và dễ bảo vệ.
