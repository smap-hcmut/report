# Slide 5: Mục tiêu & Phạm vi
**Thời lượng**: 1.5 phút

---

## Nội dung hiển thị

```
MỤC TIÊU & PHẠM VI

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    🎯 MỤC TIÊU                           │   │
│  │                                                         │   │
│  │  Thiết kế kiến trúc phần mềm cho hệ thống              │   │
│  │  Social Media Analytics theo mô hình:                   │   │
│  │                                                         │   │
│  │       MICROSERVICES + EVENT-DRIVEN                      │   │
│  │       + CLEAN ARCHITECTURE + DDD                        │   │
│  │                                                         │   │
│  │  • Tự động hóa: Crawling → Analyzing → Insight         │   │
│  │  • Rút ngắn Time-to-Insight                            │   │
│  │  • Có khả năng mở rộng (Scalable)                      │   │
│  │  • Dễ bảo trì (Maintainable)                           │   │
│  │  • Chịu lỗi tốt (Fault-tolerant)                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────┐  ┌────────────────────────────┐  │
│  │    ✅ TRONG PHẠM VI      │  │    ❌ NGOÀI PHẠM VI        │  │
│  │                          │  │                            │  │
│  │  • YouTube, TikTok       │  │  • Facebook, Instagram     │  │
│  │    (dữ liệu công khai)   │  │    (cần API riêng)         │  │
│  │                          │  │                            │  │
│  │  • Phân tích & Thiết kế  │  │  • Nghiên cứu ML/AI        │  │
│  │    kiến trúc đầy đủ      │  │    chuyên sâu              │  │
│  │                          │  │                            │  │
│  │  • Kubernetes            │  │  • Cloud deployment        │  │
│  │    On-premise            │  │    (AWS, GCP, Azure)       │  │
│  │                          │  │                            │  │
│  │  • 8 Use Cases chính     │  │  • Mobile app              │  │
│  │                          │  │                            │  │
│  └──────────────────────────┘  └────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| (Optional) Scope diagram | Tự tạo | Venn diagram In/Out of scope |

---

## Văn nói (Script)

> "Về mục tiêu, đề tài tập trung vào việc **thiết kế kiến trúc phần mềm** cho hệ thống Social Media Analytics Platform.
>
> Chúng em áp dụng **4 phương pháp kiến trúc chính**:
> 1. **Microservices Architecture** - Chia hệ thống thành 10 services độc lập
> 2. **Event-Driven Architecture** - Giao tiếp bất đồng bộ qua message queue
> 3. **Clean Architecture** - 4 layers với SOLID principles
> 4. **Domain-Driven Design** - Tổ chức code theo business domain
>
> **Mục tiêu cụ thể**:
> - Tự động hóa quy trình: Crawling → Analyzing → Insight
> - Rút ngắn Time-to-Insight cho marketing analysts
> - Thiết kế có khả năng mở rộng, dễ bảo trì và chịu lỗi tốt
>
> **Trong phạm vi** đề tài:
> - Nguồn dữ liệu: YouTube và TikTok (dữ liệu công khai)
> - Phân tích và thiết kế kiến trúc đầy đủ
> - Triển khai trên Kubernetes on-premise
> - **8 Use Cases** từ cấu hình đến xuất báo cáo và realtime tracking
>
> **Ngoài phạm vi**:
> - Các platforms khác như Facebook, Instagram (cần API riêng)
> - Nghiên cứu ML/AI chuyên sâu - chúng em sử dụng pre-trained models như PhoBERT
> - Cloud deployment (AWS, GCP, Azure) và Mobile app"

---

## Ghi chú kỹ thuật
- Slide này quan trọng để set expectation
- 2 cột: Trong phạm vi (xanh) | Ngoài phạm vi (đỏ/xám)
- Nhấn mạnh "Thiết kế kiến trúc" không phải "Nghiên cứu ML"
- Giúp tránh câu hỏi về ML accuracy

---

## Key points
1. Mục tiêu = Thiết kế kiến trúc Microservices + Event-Driven
2. Platforms = YouTube + TikTok only
3. Deployment = Kubernetes on-premise
4. KHÔNG nghiên cứu ML chuyên sâu

