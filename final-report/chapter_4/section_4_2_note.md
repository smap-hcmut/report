# Note - Section 4.2

## Khác gì so với bản cũ

- Bản cũ viết Functional Requirements theo product flow cũ, gắn rất chặt với wizard, dashboard, export, trend và crisis theo narrative trước đây.
- Nhiều yêu cầu được mô tả ở mức màn hình hoặc hành vi UI khá chi tiết, khó bám current implementation và khó trace về service boundaries.
- Bộ FR cũ bỏ sót nhiều capability hiện có của hệ thống như authentication, lifecycle control, datasource/target management, search/chat, realtime notification và internal validation.

## Bản hiện tại đã chỉnh gì

- Viết lại toàn bộ Functional Requirements theo hướng capability-based, bám current implementation của SMAP.
- Mở rộng bộ FR thành 12 yêu cầu chức năng để phản ánh đầy đủ hơn các lớp chức năng hiện có của hệ thống.
- Giảm các chi tiết quá sâu ở mức UI/product flow, giữ mô tả ở mức đủ để trace sang service, API và implementation modules.
- Chia các yêu cầu thành các nhóm capability lớn: thiết lập ngữ cảnh nghiệp vụ, điều phối/xử lý dữ liệu và khai thác kết quả.
