# Slide 10: Tại sao chọn kiến trúc này?
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
TẠI SAO CHỌN MICROSERVICES + EVENT-DRIVEN?

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│              [HÌNH: So sánh 3 kiến trúc]                        │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  MONOLITHIC │  │   MODULAR   │  │     MICROSERVICES       │ │
│  │             │  │  MONOLITH   │  │     (Chọn ✓)            │ │
│  │  ┌───────┐  │  │  ┌───────┐  │  │  ┌───┐ ┌───┐ ┌───┐     │ │
│  │  │       │  │  │  │ ┌───┐ │  │  │  │ A │ │ B │ │ C │     │ │
│  │  │  ALL  │  │  │  │ │ A │ │  │  │  └───┘ └───┘ └───┘     │ │
│  │  │  IN   │  │  │  │ ├───┤ │  │  │    ↕     ↕     ↕       │ │
│  │  │  ONE  │  │  │  │ │ B │ │  │  │  ┌───┐ ┌───┐ ┌───┐     │ │
│  │  │       │  │  │  │ ├───┤ │  │  │  │DB │ │DB │ │DB │     │ │
│  │  └───────┘  │  │  │ │ C │ │  │  │  └───┘ └───┘ └───┘     │ │
│  │             │  │  │ └───┘ │  │  │                         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    LỢI ÍCH CỦA KIẾN TRÚC ĐÃ CHỌN               │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  🔄 SCALE       │  │  🛡️ FAULT       │  │  🔧 TECH        │ │
│  │    ĐỘC LẬP     │  │    ISOLATION    │  │    DIVERSITY    │ │
│  │                 │  │                 │  │                 │ │
│  │ Collector cần   │  │ AI/ML down     │  │ Go cho API      │ │
│  │ nhiều resources │  │ không ảnh      │  │ Python cho ML   │ │
│  │ → scale riêng   │  │ hưởng Collector│  │ Chọn đúng tool  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  👥 TEAM        │  │  🚀 DEPLOY      │                      │
│  │    AUTONOMY     │  │    ĐỘC LẬP     │                      │
│  │                 │  │                 │                      │
│  │ Mỗi team phụ    │  │ Update 1       │                      │
│  │ trách 1 service │  │ service không  │                      │
│  │ độc lập         │  │ cần redeploy   │                      │
│  └─────────────────┘  └─────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Monolithic Architecture** | `report/images/architecture/monolithic_architecture.png` | Kiến trúc monolithic |
| **Modular Monolith** | `report/images/architecture/modular_monolith.png` | Kiến trúc modular monolith |
| **Microservices Architecture** | `report/images/architecture/microservices_architecture.png` | Kiến trúc microservices |

---

## Văn nói (Script)

> "Tại sao chúng em chọn Microservices thay vì Monolithic?
>
> [Chỉ vào hình so sánh] Có 3 lựa chọn: Monolithic truyền thống, Modular Monolith, và Microservices. Chúng em chọn Microservices vì các lợi ích sau:
>
> **Scale độc lập**: Collector Service cần nhiều resources để crawl → có thể scale riêng mà không ảnh hưởng services khác.
>
> **Fault Isolation**: Nếu AI/ML Service gặp lỗi, Collector vẫn tiếp tục thu thập dữ liệu bình thường.
>
> **Tech Diversity**: Dùng Go cho các API services vì performance, Python cho AI/ML vì ecosystem ML phong phú.
>
> **Team Autonomy**: Mỗi team có thể phát triển và deploy service của mình độc lập.
>
> **Deploy độc lập**: Update một service không cần redeploy toàn bộ hệ thống.
>
> Tất nhiên, Microservices cũng có trade-offs như complexity cao hơn, nhưng với yêu cầu scale và fault-tolerance của bài toán, đây là lựa chọn phù hợp."

---

## Ghi chú kỹ thuật
- Dùng 3 hình từ báo cáo để so sánh
- 5 lợi ích chính của Microservices
- Chuẩn bị trả lời về trade-offs nếu được hỏi

---

## Câu hỏi có thể gặp
- **Q**: Trade-offs của Microservices?
- **A**: Complexity cao hơn, cần DevOps skills, network latency, distributed transactions khó hơn. Nhưng với Kubernetes và message queue, chúng em đã giải quyết được phần lớn.

