# Note - Section 4.4

## Khác gì so với bản cũ

- Bản cũ viết bộ Use Case rất dài và rất chi tiết theo product flow cũ, bám mạnh vào wizard, dashboard, export, trend và crisis monitor theo narrative trước đây.
- Nhiều use case cũ mô tả sâu ở mức UI, timeout, schedule, chart layout, storage behavior và các ràng buộc chi tiết khó trace trực tiếp với current implementation.
- Actor trong use case vẫn giữ `Marketing Analyst` và các flow cũ, không còn khớp với actor model mới ở mục 4.1 và bộ FR mới ở mục 4.2.

## Bản hiện tại đã chỉnh gì

- Viết lại toàn bộ mục 4.4 theo hướng capability-based, bám current implementation và service boundaries của hệ thống.
- Rút bộ Use Case về các luồng cốt lõi như xác thực, tạo campaign/project, cấu hình datasource và dry run, lifecycle control, analytics + knowledge, search/chat, realtime alert và crisis configuration.
- Giảm mạnh các chi tiết mang tính UI/product spec cũ, chỉ giữ mức đủ để mô tả mục tiêu, actor, trigger, hậu điều kiện và luồng chính.
- Bổ sung phần `Minh họa hiện thực` cho từng use case để dễ trace sang route, service hoặc module hiện có trong hệ thống.
