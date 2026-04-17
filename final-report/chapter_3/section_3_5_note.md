# Note - Section 3.5

## Khác gì so với bản cũ

- Bản cũ đặt tên mục là `Database Technologies` và đưa `MongoDB` vào như một phần trung tâm.
- Cấu trúc cũ chưa phản ánh đúng current storage stack của SMAP.
- Chưa có `Qdrant` và `MinIO`, dù đây là hai thành phần storage/current-state quan trọng.

## Bản hiện tại đã chỉnh gì

- Đổi tên mục thành `Data Storage Technologies`.
- Bỏ `MongoDB`, thay bằng `Qdrant` và bổ sung `MinIO`.
- Viết lại theo current storage stack thật của SMAP: `PostgreSQL`, `Redis`, `Qdrant`, `MinIO`.
- Cập nhật bảng so sánh và phần `Polyglot Persistence` để bám đúng current implementation, nhấn rõ vai trò từng lớp lưu trữ trong hệ thống.
