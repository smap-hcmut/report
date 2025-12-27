# Slide 12: Data Pipeline
**Thời lượng**: 1.5 phút ⭐ QUAN TRỌNG

---

## Nội dung hiển thị

```
DATA PIPELINE - 4 GIAI ĐOẠN

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│              [HÌNH: analytics-pipeline.png]                     │
│                                                                 │
│              Data Pipeline của hệ thống SMAP                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │    1     │   │    2     │   │    3     │   │    4     │     │
│  │ CRAWLING │──►│ANALYZING │──►│AGGREGAT- │──►│FINALIZING│     │
│  │          │   │          │   │   ING    │   │          │     │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘     │
│                                                                 │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │Collector │   │  AI/ML   │   │ Project  │   │ Project  │     │
│  │ Service  │   │ Service  │   │ Service  │   │ Service  │     │
│  │          │   │          │   │          │   │          │     │
│  │• YouTube │   │•Sentiment│   │• Combine │   │• Mark    │     │
│  │• TikTok  │   │• Aspect  │   │  results │   │  complete│     │
│  │• Videos  │   │• Keyword │   │• Calculate│  │• Notify  │     │
│  │• Comments│   │• Trend   │   │  stats   │   │  user    │     │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘     │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│  ⏱️ THỜI GIAN XỬ LÝ (ước tính)                                  │
│                                                                 │
│  100 videos: ~5-10 phút                                         │
│  1000 videos: ~30-60 phút                                       │
│  (Phụ thuộc vào độ dài video và số comments)                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Analytics Pipeline** | `report/images/data-flow/analytics-pipeline.png` | Pipeline 4 giai đoạn |
| (Alternative) Analytics Ingestion | `report/images/data-flow/analytics_ingestion.png` | Luồng ingestion data |
| (Alternative) Crawler Results | `report/images/data-flow/crawler_results_processing.png` | Xử lý kết quả crawl |

---

## Văn nói (Script)

> "Đây là Data Pipeline - luồng xử lý dữ liệu chính của hệ thống, gồm **4 giai đoạn**:
>
> **Giai đoạn 1 - Crawling**: Collector Service thu thập dữ liệu từ YouTube và TikTok. Với mỗi keyword, service crawl videos, comments, metadata và lưu vào MinIO.
>
> **Giai đoạn 2 - Analyzing**: AI/ML Service nhận dữ liệu và thực hiện phân tích:
> - Sentiment analysis: Tích cực, tiêu cực, trung lập
> - Aspect extraction: Xác định các khía cạnh được đề cập
> - Keyword extraction: Tìm trending keywords
>
> **Giai đoạn 3 - Aggregating**: Project Service tổng hợp kết quả từ nhiều videos, tính toán statistics như tỷ lệ sentiment, top aspects, trending topics.
>
> **Giai đoạn 4 - Finalizing**: Đánh dấu project hoàn thành, gửi notification cho user qua WebSocket.
>
> Về thời gian, với 100 videos mất khoảng 5-10 phút, 1000 videos khoảng 30-60 phút, tùy thuộc vào độ dài video và số lượng comments."

---

## Ghi chú kỹ thuật
- Đây là slide quan trọng, giải thích core business logic
- Dùng hình `analytics-pipeline.png` từ báo cáo
- 4 giai đoạn rõ ràng với service phụ trách
- Ước tính thời gian giúp hội đồng hiểu scale

---

## Chi tiết từng giai đoạn (backup)
1. **Crawling**: YouTube API + TikTok scraping → MinIO
2. **Analyzing**: PhoBERT sentiment + Aspect extraction
3. **Aggregating**: SQL aggregation + Statistics calculation
4. **Finalizing**: Status update + WebSocket notification

