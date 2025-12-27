# Slide 13: Sequence Diagram - Execute Project
**Thời lượng**: 1.5 phút

---

## Nội dung hiển thị

```
SEQUENCE DIAGRAM - EXECUTE PROJECT (UC3)

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              [HÌNH: uc3_execute_part_1.png]                     │
│                                                                 │
│              Sequence diagram - Phần 1: Khởi tạo                │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      LUỒNG XỬ LÝ CHÍNH                          │
│                                                                 │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐    │
│  │  User  │  │Project │  │RabbitMQ│  │Collector│ │ AI/ML  │    │
│  │        │  │Service │  │        │  │Service │  │Service │    │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘    │
│      │           │           │           │           │          │
│      │ 1.Execute │           │           │           │          │
│      │──────────►│           │           │           │          │
│      │           │ 2.Publish │           │           │          │
│      │           │──────────►│           │           │          │
│      │           │           │ 3.Consume │           │          │
│      │           │           │──────────►│           │          │
│      │           │           │           │ 4.Crawl   │          │
│      │           │           │           │──────────►│          │
│      │           │           │           │           │ 5.Analyze│
│      │           │           │           │           │─────────►│
│      │           │           │           │           │          │
│      │◄──────────────────────────────────────────────│          │
│      │           6. Real-time Progress (WebSocket)   │          │
│      │                                               │          │
│  ════════════════════════════════════════════════════════════   │
│                                                                 │
│  Thời gian: 5-60 phút (tùy số lượng videos)                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Execute Part 1** | `report/images/sequence/uc3_execute_part_1.png` | Sequence diagram phần 1 - Khởi tạo |
| **Execute Part 2** | `report/images/sequence/uc3_execute_part_2.png` | Sequence diagram phần 2 - Crawling |
| **Execute Part 3** | `report/images/sequence/uc3_execute_part_3.png` | Sequence diagram phần 3 - Analyzing |
| **Execute Part 4** | `report/images/sequence/uc3_execute_part_4.png` | Sequence diagram phần 4 - Finalizing |
| (Alternative) Execute Project Flow | `report/images/data-flow/execute_project.png` | Data flow diagram |

---

## Văn nói (Script)

> "Đây là Sequence Diagram cho use case quan trọng nhất - **Execute Project**.
>
> [Chỉ vào diagram] Luồng xử lý như sau:
>
> **Bước 1**: User gửi request Execute đến Project Service.
>
> **Bước 2**: Project Service validate request, tạo execution record và publish message vào RabbitMQ.
>
> **Bước 3**: Collector Service consume message từ queue và bắt đầu crawl dữ liệu từ YouTube/TikTok.
>
> **Bước 4**: Với mỗi video crawl được, Collector gửi message cho AI/ML Service.
>
> **Bước 5**: AI/ML Service thực hiện sentiment analysis, aspect extraction và gửi kết quả về.
>
> **Bước 6**: Trong suốt quá trình, progress được cập nhật real-time qua WebSocket để user theo dõi.
>
> Toàn bộ quá trình này là **bất đồng bộ**, user không cần chờ đợi mà có thể theo dõi progress real-time.
>
> Do diagram khá dài, trong báo cáo chúng em đã chia thành 4 phần để dễ theo dõi."

---

## Ghi chú kỹ thuật
- UC3 là use case phức tạp nhất, có 4 phần sequence diagram
- Chọn 1 phần để show, giải thích tổng quan
- Nhấn mạnh: Async processing + Real-time updates
- Có thể dùng animation để show từng bước

---

## Các sequence diagrams khác (backup)
- `uc1_cau_hinh_project.png` - Cấu hình project
- `uc2_dryryn_part_1/2.png` - Dry-run
- `uc4_result_part_1/2.png` - View results
- `uc5_list_part_1/2.png` - List projects
- `uc6_export_part_1/2/3.png` - Export
- `uc7_part_1/2/3.png` - Trend detection

