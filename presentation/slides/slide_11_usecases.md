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
│                      8 USE CASES CHÍNH                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  UC1: Cấu hình Project                                   │   │
│  │       → Tạo project, nhập keywords, chọn platforms       │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC2: Dry-run từ khóa                                    │   │
│  │       → Test keywords trước khi chạy thật                │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC3: Execute Project ⭐                                 │   │
│  │       → Khởi chạy thu thập dữ liệu                       │   │
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
│  ├─────────────────────────────────────────────────────────┤   │
│  │  UC8: Realtime Progress Tracking                         │   │
│  │       → Theo dõi tiến trình real-time qua WebSocket      │   │
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

> "Về phân tích yêu cầu, chúng em đã xác định **8 use cases chính** cho hệ thống:
>
> **UC1 - Cấu hình Project**: Người dùng tạo project mới, nhập keywords cần theo dõi và chọn platforms (YouTube, TikTok).
>
> **UC2 - Dry-run từ khóa**: Test keywords trước khi chạy thật để xem số lượng kết quả dự kiến, tránh lãng phí resources.
>
> **UC3 - Execute Project**: Đây là use case quan trọng nhất - khởi chạy thu thập dữ liệu. Khi execute, hệ thống sẽ crawl videos, comments và metadata.
>
> **UC4 - Xem kết quả phân tích**: Xem dashboard với sentiment analysis, aspect extraction, trending keywords và timeline analysis.
>
> **UC5 - Quản lý danh sách Projects**: List, filter, search và delete các projects. Quản lý nhiều campaigns cùng lúc.
>
> **UC6 - Xuất báo cáo**: Export kết quả ra PDF, PowerPoint hoặc Excel để chia sẻ với stakeholders.
>
> **UC7 - Phát hiện xu hướng tự động**: Hệ thống tự động detect trends và gửi alerts khi có sự thay đổi đột ngột về sentiment hoặc volume.
>
> **UC8 - Realtime Progress Tracking**: Theo dõi tiến trình thu thập và phân tích real-time qua WebSocket. User biết được đang ở giai đoạn nào của pipeline.
>
> Tất cả 8 use cases được đặc tả đầy đủ theo template Cockburn với main flow, extensions và activity diagrams."

---

## Ghi chú kỹ thuật
- Liệt kê nhanh 8 UC, không đi sâu chi tiết từng UC
- Nhấn mạnh UC3 là quan trọng nhất (sẽ show sequence diagram ở slide sau)
- UC8 là bổ sung mới - Realtime Progress Tracking qua WebSocket
- Cockburn template = chuẩn công nghiệp cho use case specification

---

## Activity Diagrams có sẵn (backup)
- `activity/1.png` - UC1: Cấu hình Project
- `activity/2.png` - UC2: Dry-run
- `activity/3.png` - UC3: Execute Project
- `activity/4.png` - UC4: View Results
- `activity/5.png` - UC5: List Projects
- `activity/6.png` - UC6: Export
- `activity/7.png` - UC7: Trend Detection
- `activity/8.png` - UC8: Realtime Progress Tracking

