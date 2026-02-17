# Slide 8: Infrastructure Components
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
INFRASTRUCTURE COMPONENTS

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    DATA LAYER                            │   │
│  │                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │   │
│  │  │ PostgreSQL  │  │ PostgreSQL  │  │     MinIO       │ │   │
│  │  │  (Identity) │  │  (Project)  │  │  (Object Store) │ │   │
│  │  │             │  │             │  │                 │ │   │
│  │  │ • Users     │  │ • Projects  │  │ • Videos        │ │   │
│  │  │ • Sessions  │  │ • Results   │  │ • Reports       │ │   │
│  │  │ • Tokens    │  │ • Analytics │  │ • Large files   │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  MESSAGING LAYER                         │   │
│  │                                                         │   │
│  │  ┌─────────────────────────┐  ┌───────────────────────┐│   │
│  │  │       RabbitMQ          │  │        Redis          ││   │
│  │  │                         │  │                       ││   │
│  │  │  • Async job processing │  │  • Pub/Sub real-time  ││   │
│  │  │  • Task queues          │  │  • Caching            ││   │
│  │  │  • Dead letter handling │  │  • Session store      ││   │
│  │  │  • Retry mechanism      │  │  • Rate limiting      ││   │
│  │  └─────────────────────────┘  └───────────────────────┘│   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  ORCHESTRATION                           │   │
│  │                                                         │   │
│  │              ☸️ KUBERNETES (On-premise)                  │   │
│  │                                                         │   │
│  │  • Auto-scaling pods    • Service discovery             │   │
│  │  • Load balancing       • Health checks                 │   │
│  │  • Rolling updates      • Secret management             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Deployment Diagram** | `report/images/deploy/Diagram-deployment-diagram.drawio.png` | Sơ đồ triển khai Kubernetes |
| (Alternative) Component Diagram | `report/images/Diagram-component-diagram.drawio.png` | Sơ đồ component tổng quan |

---

## Văn nói (Script)

> "Về infrastructure, hệ thống được chia thành 3 layers:
>
> **Data Layer** gồm:
> - 2 PostgreSQL databases độc lập cho Identity và Project services, theo pattern Database-per-Service
> - MinIO làm object storage cho videos, reports và các file lớn
>
> **Messaging Layer** gồm:
> - **RabbitMQ** cho async job processing - khi một project được execute, các tasks được đẩy vào queue và xử lý bất đồng bộ. RabbitMQ cũng hỗ trợ dead letter handling và retry mechanism.
> - **Redis** cho Pub/Sub real-time notifications, caching và rate limiting
>
> **Orchestration Layer**:
> - Toàn bộ hệ thống được triển khai trên **Kubernetes on-premise**, với auto-scaling, load balancing, rolling updates và health checks.
>
> Kiến trúc này cho phép scale từng component độc lập theo nhu cầu."

---

## Ghi chú kỹ thuật
- 3 layers: Data → Messaging → Orchestration
- Có thể dùng hình deployment diagram từ báo cáo
- Nhấn mạnh: Database-per-Service pattern
- Kubernetes = khả năng scale

---

## Key points
1. 2 PostgreSQL (Database-per-Service)
2. MinIO cho object storage
3. RabbitMQ (async) + Redis (real-time)
4. Kubernetes on-premise

