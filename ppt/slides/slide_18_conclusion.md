# Slide 18: Tổng kết & Q&A
**Thời lượng**: 1 phút + Q&A

---

## Nội dung hiển thị

```
TỔNG KẾT

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    ✅ ĐÃ HOÀN THÀNH                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  📋 PHÂN TÍCH                    🏗️ THIẾT KẾ            │   │
│  │  • 47 yêu cầu chức năng         • 5 Microservices      │   │
│  │  • 31 yêu cầu phi chức năng     • Event-Driven         │   │
│  │  • 7 Use Cases (Cockburn)       • Database-per-Service │   │
│  │  • 7 Business Rules             • Claim-Check Pattern  │   │
│  │                                                         │   │
│  │  📊 MÔ HÌNH HÓA                  ☸️ HẠ TẦNG             │   │
│  │  • 7 Activity Diagrams          • Kubernetes manifests │   │
│  │  • 7 Sequence Diagrams          • Auto-scaling config  │   │
│  │  • 3 ERD Diagrams               • CI/CD ready          │   │
│  │  • C4 Model (Context,           • Health checks        │   │
│  │    Container, Component)                               │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │   "Kiến trúc Microservices + Event-Driven               │   │
│  │    cho hệ thống Social Media Analytics                  │   │
│  │    có khả năng mở rộng và bảo trì cao"                  │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│                                                                 │
│                    🙏 CẢM ƠN THẦY VÀ CÁC BẠN!                   │
│                                                                 │
│                         ❓ Q & A                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| (Optional) Container Diagram thumbnail | `report/images/diagram/container-diagram.png` | Background mờ |
| (Optional) Team photo | Tự chụp | Ảnh nhóm (nếu có) |

---

## Văn nói (Script)

> "Tổng kết lại, đề tài đã hoàn thành mục tiêu phân tích và thiết kế hệ thống SMAP.
>
> **Về phân tích**: Chúng em đã định nghĩa 47 yêu cầu chức năng, 31 yêu cầu phi chức năng, đặc tả 7 use cases theo template Cockburn và 7 business rules.
>
> **Về thiết kế**: Kiến trúc Microservices với 5 services, Event-Driven architecture với RabbitMQ và Redis, Database-per-Service pattern, và Claim-Check pattern cho large payloads.
>
> **Về mô hình hóa**: 7 activity diagrams, 7 sequence diagrams, 3 ERD diagrams và C4 Model đầy đủ.
>
> **Về hạ tầng**: Kubernetes manifests với auto-scaling, health checks và CI/CD ready.
>
> [Đọc key message] Điểm nhấn của đề tài là kiến trúc **Microservices kết hợp Event-Driven** cho hệ thống Social Media Analytics, với khả năng **mở rộng** và **bảo trì cao**.
>
> Cảm ơn thầy và các bạn đã lắng nghe. Chúng em sẵn sàng trả lời câu hỏi."

---

## Ghi chú kỹ thuật
- Đây là slide cuối, nên tóm gọn và có impact
- 4 categories: Phân tích → Thiết kế → Mô hình hóa → Hạ tầng
- Key message ở giữa (quote box)
- Kết thúc bằng "Cảm ơn" và "Q&A"

---

## Câu hỏi thường gặp (chuẩn bị trước)

| Câu hỏi | Gợi ý trả lời |
|---------|---------------|
| Tại sao chọn Microservices? | Scale độc lập, fault isolation, tech diversity |
| Tại sao RabbitMQ không Kafka? | Task queue pattern, dễ setup, đủ cho scale hiện tại |
| Xử lý rate-limit như thế nào? | Exponential backoff, proxy rotation (chưa implement đầy đủ) |
| AI/ML models dùng gì? | PhoBERT cho sentiment, chưa implement hoàn chỉnh |
| Làm sao khi service down? | Message queue retry, dead letter queue, health checks |
| Tại sao 2 databases? | Database-per-Service pattern, độc lập scale và backup |
| Performance như thế nào? | Chưa load test, ước tính 100 videos/5-10 phút |

---

## Backup slides (nếu cần)
- Component diagrams chi tiết cho từng service
- Activity diagrams cho từng use case
- Sequence diagrams chi tiết
- ERD chi tiết từng database

