# Slide 10: Tại sao chọn kiến trúc này?
**Thời lượng**: 1.5 phút

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
│          QUYẾT ĐỊNH DỰA TRÊN AHP MATRIX: 4.7/5.0 ⭐            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              3 LÝ DO CHÍNH CHỌN MICROSERVICES           │   │
│  │                                                         │   │
│  │  1️⃣ ASYMMETRIC WORKLOAD                                │   │
│  │     Crawler/Analytics tiêu tốn resources cao hơn API   │   │
│  │     → Scale riêng từng service                         │   │
│  │                                                         │   │
│  │  2️⃣ POLYGLOT RUNTIME                                   │   │
│  │     Python (AI/ML), Go (API), Next.js (Frontend)       │   │
│  │     → Monolithic không hỗ trợ đa ngôn ngữ             │   │
│  │                                                         │   │
│  │  3️⃣ FAULT ISOLATION                                    │   │
│  │     Lỗi Crawler không làm sập Identity/Project         │   │
│  │     → Eventual Consistency qua Saga Pattern            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           ARCHITECTURE CHARACTERISTICS (7 ACs)          │   │
│  │                                                         │   │
│  │  PRIMARY (90% trọng số):                               │   │
│  │  • AC-1: Availability      → 99.5% uptime              │   │
│  │  • AC-2: Performance       → API <500ms p95            │   │
│  │  • AC-3: Scalability       → Horizontal scaling        │   │
│  │                                                         │   │
│  │  SECONDARY:                                            │   │
│  │  • AC-4: Maintainability   • AC-6: Security            │   │
│  │  • AC-5: Testability       • AC-7: Observability       │   │
│  └─────────────────────────────────────────────────────────┘   │
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
> [Chỉ vào hình so sánh] Có 3 lựa chọn: Monolithic, Modular Monolith, và Microservices.
>
> Quyết định này được đưa ra dựa trên **AHP Matrix** (Analytic Hierarchy Process) với điểm **4.7/5.0** cho Microservices, vượt xa Monolithic (2.3) và Modular Monolith (3.5).
>
> **3 lý do chính**:
>
> **1. Asymmetric Workload**: Crawler và Analytics Service tiêu tốn CPU/Memory cao hơn Identity hoặc Project Service nhiều lần. Microservices cho phép scale riêng từng service theo nhu cầu.
>
> **2. Polyglot Runtime**: Chúng em cần Python cho AI/ML vì PhoBERT và scikit-learn, Go cho high-performance APIs, và Next.js cho modern frontend. Monolithic không hỗ trợ đa ngôn ngữ như vậy.
>
> **3. Fault Isolation**: Nếu Crawler down do rate-limit từ platforms, Identity và Project Services vẫn hoạt động bình thường. Eventual Consistency được xử lý qua Saga Pattern.
>
> Về **Architecture Characteristics**, chúng em đã định nghĩa 7 ACs, trong đó 3 PRIMARY chiếm 90% trọng số:
> - **Availability**: 99.5% uptime
> - **Performance**: API response time <500ms ở p95
> - **Scalability**: Horizontal scaling với Kubernetes
>
> Trade-offs: Complexity cao hơn, cần DevOps skills, nhưng với yêu cầu của bài toán, đây là lựa chọn tối ưu."

---

## Ghi chú kỹ thuật
- Dùng 3 hình từ báo cáo để so sánh
- 5 lợi ích chính của Microservices
- Chuẩn bị trả lời về trade-offs nếu được hỏi

---

## Câu hỏi có thể gặp
- **Q**: Trade-offs của Microservices?
- **A**: Complexity cao hơn, cần DevOps skills, network latency, distributed transactions khó hơn. Nhưng với Kubernetes và message queue, chúng em đã giải quyết được phần lớn.

