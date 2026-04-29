# Note - Section 5.3.5

## Khác gì so với bản cũ

- Bản cũ mô tả mục này như `WebSocket Service`, tức chỉ phản ánh một nửa của service boundary hiện tại.
- Traceability cũ gắn với `FR-2` và progress tracking, chưa khớp với bộ FR/UC mới của Chương 4.
- Data flow cũ chủ yếu xoay quanh progress updates từ service cũ, chưa phản ánh đầy đủ alert dispatch và channel patterns hiện tại.

## Bản hiện tại đã chỉnh gì

- Đổi mục này thành `Notification Service` để khớp đúng service boundary hiện tại.
- Bổ sung cả hai nhánh chính: WebSocket delivery và alert/Discord dispatch.
- Cập nhật traceability để bám `FR-11` và `UC-07`.
- Viết lại component catalog, data flow, design patterns, key decisions và dependencies theo current implementation của `notification-srv`.

## Ghi chú tạm thời

- Mục này hiện chưa gắn diagram mới; nếu về sau bổ sung hình, nên dùng diagram current-state cho WebSocket connection flow và Redis → notification → WebSocket/Discord delivery flow.
