# Slide 4: Bài toán cần giải quyết
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
BÀI TOÁN CẦN GIẢI QUYẾT

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    📊 ĐẶC ĐIỂM DỮ LIỆU MXH                      │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────┐ │
│  │  📈 KHỔNG   │  │  📝 PHI    │  │  ⚡ REAL-   │  │ 🌐 ĐA  │ │
│  │     LỒ      │  │  CẤU TRÚC  │  │    TIME     │  │ NGUỒN  │ │
│  │             │  │            │  │             │  │        │ │
│  │ Hàng triệu  │  │ Text, video│  │ Liên tục    │  │YouTube │ │
│  │ posts/ngày  │  │ comments   │  │ 24/7        │  │TikTok  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────┘ │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│                    🎯 YÊU CẦU HỆ THỐNG                          │
│                                                                 │
│     ┌─────────┐      ┌─────────┐      ┌─────────┐              │
│     │ THU THẬP│ ───► │PHÂN TÍCH│ ───► │ INSIGHT │              │
│     │         │      │         │      │         │              │
│     │ Crawling│      │Sentiment│      │Dashboard│              │
│     │ Videos  │      │ Aspect  │      │ Reports │              │
│     │Comments │      │ Trend   │      │ Alerts  │              │
│     └─────────┘      └─────────┘      └─────────┘              │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│                    ⚙️ THÁCH THỨC KỸ THUẬT                       │
│                                                                 │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ 🔄 SCALE      │  │ ⏱️ ASYNC      │  │ 🛡️ FAULT-TOLERANT │   │
│  │               │  │               │  │                   │   │
│  │ Xử lý hàng   │  │ Long-running  │  │ Không mất dữ liệu │   │
│  │ nghìn videos │  │ jobs (phút→   │  │ khi service down  │   │
│  │ đồng thời    │  │ giờ)          │  │                   │   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| Data flow diagram | Tự tạo hoặc dùng `report/images/data-flow/execute_project.png` | Minh họa luồng Thu thập → Phân tích → Insight |

---

## Văn nói (Script)

> "Vậy bài toán cụ thể mà chúng em cần giải quyết là gì?
>
> **Về đặc điểm dữ liệu**: Dữ liệu mạng xã hội có 4 đặc điểm chính - khổng lồ với hàng triệu posts mỗi ngày, phi cấu trúc với text, video, comments, real-time liên tục 24/7, và đến từ nhiều nguồn khác nhau như YouTube, TikTok.
>
> **Về yêu cầu hệ thống**: Chúng em cần xây dựng pipeline 3 giai đoạn - Thu thập dữ liệu từ các platforms, Phân tích sentiment và aspect, và cuối cùng là tạo Insight qua dashboard và báo cáo.
>
> **Về thách thức kỹ thuật**: Có 3 thách thức lớn:
> - **Scale**: Xử lý hàng nghìn videos đồng thời
> - **Async**: Các jobs chạy từ vài phút đến vài giờ
> - **Fault-tolerant**: Không được mất dữ liệu khi có service down
>
> Đây chính là lý do chúng em chọn kiến trúc Microservices và Event-Driven."

---

## Ghi chú kỹ thuật
- Slide này giải thích WHY - tại sao cần kiến trúc phức tạp
- 3 phần: Đặc điểm dữ liệu → Yêu cầu → Thách thức
- Animation: Hiện từng phần theo thứ tự
- Dùng icon để dễ nhìn

---

## Transition sang slide tiếp
> "Với những thách thức này, chúng em đã đặt ra mục tiêu và phạm vi cụ thể cho đề tài..."

