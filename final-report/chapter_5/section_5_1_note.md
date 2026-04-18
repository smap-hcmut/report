# Note - Section 5.1

## Khác gì so với bản cũ

- Bản cũ mở đầu Chương 5 bằng bộ NFR và Architecture Characteristics cũ, trong đó có nhiều metrics và target số cứng không còn khớp với Chương 4 đã chỉnh lại.
- Phần phân nhóm như `Usability`, `Compliance`, `Architecture Quality` và radar chart kéo mục 5.1 theo hướng product quality cũ hơn là kiến trúc hiện tại của hệ thống.
- Nhiều chỉ số như throughput, coverage, deploy time, rollback time hoặc backward compatibility được nêu quá cụ thể, khó bảo vệ khi chưa có artifact thực nghiệm tương ứng.

## Bản hiện tại đã chỉnh gì

- Viết lại mục 5.1 theo hướng design-from-drivers, lấy yêu cầu ở Chương 4 làm cơ sở cho phần thiết kế hệ thống.
- Thay bộ NFR/AC cũ bằng bảng architectural drivers mới bám trực tiếp `4.3`.
- Bỏ radar chart và hầu hết các metric số cứng khó bảo vệ.
- Chốt lại một bộ nguyên tắc thiết kế ngắn gọn, bám current architecture của SMAP: bounded context, transport specialization, polyglot persistence, tách business control plane khỏi execution plane.
- Bổ sung phần liên hệ trực tiếp với current SMAP để mở đường cho các mục thiết kế chi tiết phía sau.
