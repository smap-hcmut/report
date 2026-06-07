# SMAP Audit Chất Lượng Dữ Liệu — 2026-06-07

## Phạm vi

Kiểm tra toàn diện: sentiment scores, engagement metrics, keyword extraction,
intent classification, và pipeline correctness. Nguồn: `analysis.post_insight`
DB (112K records, 3 ngày gần nhất).

---

## 1. Sentiment Scores: Chỉ 3 Giá Trị Rời Rạc (Thiết Kế)

**Phát hiện:** 112K records chỉ có đúng -0.5, 0, hoặc +0.5. Không có phổ
liên tục.

```
 overall_sentiment_score | count
-------------------------+-------
                     0.5 | 50838  (POSITIVE)
                    -0.5 | 35377  (NEGATIVE)
                       0 | 25839  (NEUTRAL)
```

**Nguyên nhân:** Sentiment model là classifier 3 lớp. Score được suy từ
label, không phải regression. `normalize_sentiment_score()` chỉ đảo dấu
— không discretize.

**Đánh giá:** Không phải bug — kiến trúc model hiện tại. Nhưng hạn chế
độ sâu phân tích (không phân biệt được "hơi tích cực" và "rất tích cực").

**Đề xuất:** Nâng cấp lên regression model hoặc dùng raw confidence làm
score.

---

## 2. Engagement Score Thiếu ~40% Records

**Phát hiện:** engagement_score = 0 cho nhiều records có likes > 0.

**Nguyên nhân:** Intent classifier `should_skip`. Khi `primary_intent` là
SEEDING hoặc SPAM, pipeline return sớm ở Stage 2 — **trước** sentiment,
keywords, và impact calculation.

Pattern SEEDING gồm `\b0\d{9,10}\b` (số điện thoại VN). Content chứa SĐT
bị skip toàn bộ. VD: 221 YouTube records có likes=3, TẤT CẢ bị phân loại
SEEDING vì description có số liên hệ.

```
 primary_intent | processing_status |  cnt
----------------+-------------------+------
 SEEDING        | success_skipped   |  922  (0.9%)
 SPAM           | success_skipped   |  140  (0.1%)
```

**Đánh giá:** 0.9% skip rate chấp nhận được cho spam filtering. Nhưng mất
sentiment + engagement data cho skipped records là không tối ưu.

**Đề xuất:** Tách skip khỏi impact calculation. Vẫn compute engagement_score
và sentiment trước khi return sớm.

---

## 3. Empty Keywords: 57% Records Thành Công

**Phát hiện:** 3924 / 6894 records `success` (56.9%) không có keywords.

**Phân tích:** Pipeline: dictionary matching → AI extraction (SpacyYake) →
filter. Content mẫu không có keywords: comment ngắn ("Cức đó 🤣🤣🤣🤣", 11
ký tự), thảo luận tài xế ("Đơn này toàn đơn tmdt bác nhỉ", 29 ký tự).

**Đánh giá:** Impact trung bình. Comment ngắn tự nhiên ít keywords. Nhưng
57% vẫn cao — dictionary coverage gap hoặc AI extraction threshold quá chặt.

**Đề xuất:** Kiểm tra SpacyYake config (min_ngram_size, top_k) và keyword
map coverage. Xem xét giảm `ai_threshold`.

---

## 4. TikTok/Facebook Engagement Giảm Mạnh (7/6)

**Phát hiện:** TikTok avg likes giảm từ 3-28 (1-6/6) xuống đúng 1.0 ngày
7/6. Facebook giảm từ ~1.0 xuống 0.24.

**Nguyên nhân:** Parser field mapping đúng. JSON engagement từ Kafka khớp
với DB. Vấn đề nằm ở scraper — data nguồn không có engagement.

**Đề xuất:** Audit scraper config và API access (TikTok rate limits, session).

---

## 5. Pipeline Health

| Chỉ số | Trạng thái |
|--------|-----------|
| Crash errors | **Đã fix** — 0 errors từ lúc deploy |
| Data ingest | **OK** — 104 dòng mới trong 20 phút |
| NULL fields | **OK** — 0 NULLs |
| Contract publish | **OK** — batch.completed + digest |
| Pod health | **OK** — 25/25 Running |

---

## Tổng Hợp Đề Xuất

| Ưu tiên | Vấn đề | Hành động |
|----------|--------|-----------|
| P0 | N/A — crash đã fix | Done |
| P1 | Keywords rỗng (57%) | Tune SpacyYake, mở rộng dictionary |
| P2 | Sentiment granularity | Cân nhắc regression model |
| P3 | SEEDING skip mất data | Compute engagement_score trước early return |
| P3 | TikTok scraper engagement | Audit scraper config |
