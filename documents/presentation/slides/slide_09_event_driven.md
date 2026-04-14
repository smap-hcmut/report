# Slide 9: Event-Driven Architecture
**Thời lượng**: 1.5 phút ⭐ QUAN TRỌNG

---

## Nội dung hiển thị

```
EVENT-DRIVEN ARCHITECTURE

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│              [HÌNH: execute_project.png hoặc                    │
│               analytics-pipeline.png]                           │
│                                                                 │
│              Message Flow trong hệ thống SMAP                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      MESSAGE FLOW                               │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ Project  │───►│ RabbitMQ │───►│Collector │───►│  AI/ML   │  │
│  │ Service  │    │  Queue   │    │ Service  │    │ Service  │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │                                               │         │
│       │              ┌──────────┐                     │         │
│       └─────────────►│  Redis   │◄────────────────────┘         │
│                      │ Pub/Sub  │                               │
│                      └────┬─────┘                               │
│                           │                                     │
│                      ┌────▼─────┐                               │
│                      │WebSocket │───► 👤 User (Real-time)       │
│                      │ Service  │                               │
│                      └──────────┘                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   ⭐ CLAIM-CHECK PATTERN                        │
│                                                                 │
│  Vấn đề: Payload lớn (videos, transcripts) không nên           │
│          truyền qua message queue                               │
│                                                                 │
│  Giải pháp:                                                     │
│  ┌─────────┐  1. Store  ┌─────────┐  2. Send ID  ┌─────────┐   │
│  │ Service │──────────►│  MinIO  │              │ RabbitMQ│   │
│  │    A    │           │         │◄─────────────│  Queue  │   │
│  └─────────┘           └─────────┘  3. Retrieve └─────────┘   │
│                             ▲                         │         │
│                             │         4. Process      │         │
│                             └─────────────────────────┘         │
│                                      ┌─────────┐                │
│                                      │ Service │                │
│                                      │    B    │                │
│                                      └─────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Execute Project Flow** | `report/images/data-flow/execute_project.png` | Luồng thực thi project |
| **Analytics Pipeline** | `report/images/data-flow/analytics-pipeline.png` | Pipeline phân tích |
| **Real-time Flow** | `report/images/data-flow/real-time.png` | Luồng real-time notifications |
| (Alternative) Progress Flow | `report/images/data-flow/Progress.png` | Luồng cập nhật progress |

---

## Văn nói (Script)

> "Đây là slide quan trọng nhất về kiến trúc - **Event-Driven Architecture**.
>
> **Message Flow** hoạt động như sau:
> - Khi user execute một project, **Project Service** publish message vào **RabbitMQ**
> - **Collector Service** consume message, crawl dữ liệu và gửi tiếp cho **AI/ML Service**
> - Mỗi bước hoàn thành, services publish events vào **Redis Pub/Sub**
> - **WebSocket Service** subscribe và push real-time updates cho user
>
> **Điểm đặc biệt** là chúng em áp dụng **Claim-Check Pattern** để xử lý payload lớn:
> - Thay vì gửi toàn bộ video data qua message queue, service A lưu data vào **MinIO** trước
> - Chỉ gửi **reference ID** qua RabbitMQ
> - Service B nhận ID, retrieve data từ MinIO và xử lý
>
> Pattern này giúp message queue nhẹ, không bị bottleneck với large payloads."

---

## Ghi chú kỹ thuật
- Đây là điểm nhấn kỹ thuật của đề tài
- Claim-Check Pattern = giải pháp sáng tạo
- Dùng hình từ báo cáo: `execute_project.png` hoặc `analytics-pipeline.png`
- Animation: Hiện từng bước của flow

---

## Câu hỏi có thể gặp
- **Q**: Tại sao dùng RabbitMQ không Kafka?
- **A**: RabbitMQ phù hợp với task queue pattern, dễ setup, đủ cho scale hiện tại. Kafka phù hợp hơn cho event streaming với volume cực lớn.

