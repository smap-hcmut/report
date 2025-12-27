# Slide 11: Use Cases Overview
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
USE CASES OVERVIEW

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              [HÌNH: Use Case Diagram tổng quan]                 │
│                                                                 │
│              Hoặc tự vẽ sơ đồ đơn giản:                         │
│                                                                 │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      7 USE CASES CHÍNH                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  UC1: Cấu hình Project                                   │   │
│  │       → Tạo project, nhập keywords, chọn platforms       │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC2: Dry-run từ khóa                                    │   │
│  │       → Test keywords trước khi chạy thật                │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC3: Khởi chạy & Theo dõi tiến trình ⭐                 │   │
│  │       → Execute project, real-time progress tracking     │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC4: Xem kết quả phân tích                              │   │
│  │       → Dashboard sentiment, aspects, trends             │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC5: Quản lý danh sách Projects                         │   │
│  │       → List, filter, search, delete projects            │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC6: Xuất báo cáo                                       │   │
│  │       → Export PDF, PPTX, Excel                          │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC7: Phát hiện xu hướng tự động                         │   │
│  │       → Auto trend detection, alerts                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Actor chính: Marketing Analyst                                 │
│  Tất cả UC được đặc tả theo template Cockburn                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| Use Case Diagram | Tự tạo từ báo cáo Chapter 3 | Sơ đồ UC tổng quan với 7 use cases |
| (Reference) Activity diagrams | `report/images/activity/1.png` đến `8.png` | Backup nếu cần giải thích chi tiết |

---

## Văn nói (Script)

> "Về phân tích yêu cầu, chúng em đã xác định **7 use cases chính** cho hệ thống:
>
> **UC1 - Cấu hình Project**: Người dùng tạo project mới, nhập keywords cần theo dõi và chọn platforms.
>
> **UC2 - Dry-run từ khóa**: Test keywords trước khi chạy thật để xem số lượng kết quả dự kiến.
>
> **UC3 - Khởi chạy và Theo dõi tiến trình**: Đây là use case quan trọng nhất - execute project và theo dõi progress real-time qua WebSocket.
>
> **UC4 - Xem kết quả phân tích**: Xem dashboard với sentiment analysis, aspect extraction và trending keywords.
>
> **UC5 - Quản lý danh sách Projects**: List, filter, search và delete các projects.
>
> **UC6 - Xuất báo cáo**: Export kết quả ra PDF, PowerPoint hoặc Excel.
>
> **UC7 - Phát hiện xu hướng tự động**: Hệ thống tự động detect trends và gửi alerts.
>
> Tất cả use cases được đặc tả đầy đủ theo template Cockburn với main flow và extensions."

---

## Ghi chú kỹ thuật
- Liệt kê nhanh 7 UC, không đi sâu chi tiết
- Nhấn mạnh UC3 là quan trọng nhất (sẽ show sequence diagram)
- Cockburn template = chuẩn công nghiệp

---

## Activity Diagrams có sẵn (backup)
- `activity/1.png` - UC1: Cấu hình Project
- `activity/2.png` - UC2: Dry-run
- `activity/3.png` - UC3: Execute
- `activity/4.png` - UC4: View Results
- `activity/5.png` - UC5: List Projects
- `activity/6.png` - UC6: Export
- `activity/7.png` - UC7: Trend Detection
- `activity/8.png` - UC8: Crisis Monitor

