# Note - Section 5.3.4

## Khác gì so với bản cũ

- Bản cũ tiếp tục dùng `Identity Service` thêm một lần nữa ở mục `5.3.4`, tạo ra tình trạng trùng service với `5.3.1`.
- Nội dung cũ cũng bám auth flow cũ hơn current implementation, còn registration, password hashing, OTP verification và email event publishing.
- Điều này làm `5.3` vừa bị trùng service, vừa lệch current architecture.

## Bản hiện tại đã chỉnh gì

- Thay hoàn toàn `5.3.4` bằng `Ingest Service` để bám đúng service boundary còn thiếu trong current hệ thống.
- Tập trung mô tả đúng các capability chính của `ingest-srv`: datasource, target, dry run, execution plane, completion handling và UAP publishing.
- Tổ chức lại thành phần, data flow, design patterns, key decisions và dependencies theo current implementation.

## Ghi chú tạm thời

- Đã bổ sung một SVG current-state cho flow completion handling và UAP publishing.
- Source của hình này hiện được giữ ở dạng PlantUML `.puml` và render ra `.svg` để nhúng vào report.
- Các flow datasource-target management và dry run validation hiện vẫn mới được mô tả bằng văn bản.
