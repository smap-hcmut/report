# Slide 7: Container Diagram (C4 Level 2)
**Thời lượng**: 1.5 phút

---

## Nội dung hiển thị

```
CONTAINER DIAGRAM (C4 Level 2)

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│              [HÌNH: container-diagram.png]                      │
│                                                                 │
│              Sơ đồ các containers trong hệ thống SMAP           │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        5 SERVICES CHÍNH                         │
│                                                                 │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────┐│
│  │ Identity  │ │  Project  │ │ Collector │ │  AI/ML    │ │ WS ││
│  │  Service  │ │  Service  │ │  Service  │ │  Service  │ │Svc ││
│  │   (Go)    │ │   (Go)    │ │   (Go)    │ │ (Python)  │ │(Go)││
│  │           │ │           │ │           │ │           │ │    ││
│  │ • Auth    │ │ • CRUD    │ │ • Crawl   │ │ •Sentiment│ │Real││
│  │ • JWT     │ │ • Config  │ │ • YouTube │ │ • Aspect  │ │time││
│  │ • Users   │ │ • Execute │ │ • TikTok  │ │ • Trend   │ │    ││
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Container Diagram** | `report/images/diagram/container-diagram.png` | Sơ đồ C4 Level 2 - Containers |

---

## Văn nói (Script)

> "Đi sâu hơn vào bên trong, đây là Container Diagram theo C4 Model, cho thấy các thành phần chính của hệ thống.
>
> SMAP được chia thành **5 services chính**:
>
> **Identity Service** viết bằng Go, chịu trách nhiệm xác thực người dùng, quản lý JWT tokens và thông tin users.
>
> **Project Service** cũng viết bằng Go, quản lý CRUD các projects, cấu hình keywords, platforms và điều phối việc thực thi.
>
> **Collector Service** là service thu thập dữ liệu từ YouTube và TikTok, bao gồm videos, comments, và metadata.
>
> **AI/ML Service** viết bằng Python, thực hiện phân tích sentiment, aspect extraction và trend detection.
>
> **WebSocket Service** cung cấp real-time notifications cho frontend, cập nhật progress và kết quả.
>
> Các services giao tiếp với nhau qua **RabbitMQ** cho async processing và **Redis Pub/Sub** cho real-time events."

---

## Ghi chú kỹ thuật
- Hình chính là `container-diagram.png` từ báo cáo
- Bảng tóm tắt 5 services bên dưới
- Nhấn mạnh: Go cho performance, Python cho ML
- Không cần giải thích chi tiết từng service

---

## Key points
1. 5 Services: Identity, Project, Collector, AI/ML, WebSocket
2. Go (4 services) + Python (1 service)
3. Giao tiếp: RabbitMQ + Redis Pub/Sub

