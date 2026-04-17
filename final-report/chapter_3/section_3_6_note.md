# Note - Section 3.6

## Khác gì so với bản cũ

- Bản cũ có mục `Password Hashing` và bảng so sánh hashing algorithms theo hướng lý thuyết chung.
- Phần này không bám sát auth stack hiện tại của SMAP, vì current implementation chủ yếu dùng `OAuth2 + JWT + HttpOnly Cookie`.
- Chưa có câu nối sang auth model thật của hệ thống.

## Bản hiện tại đã chỉnh gì

- Thay `Password Hashing` bằng `OAuth2`.
- Bỏ bảng hashing cũ.
- Viết lại theo hướng phù hợp hơn với current auth stack: OAuth2 cho đăng nhập ban đầu, JWT/cookie cho phiên truy cập sau đăng nhập.
- Thêm câu nối cuối mục để liên hệ trực tiếp với các luồng xác thực và bảo vệ kết nối của SMAP.
