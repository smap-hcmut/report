# SMAP Analytics Data Quality Audit — 2026-06-07

## Scope

End-to-end quality check: sentiment scores, engagement metrics, keyword extraction,
intent classification, and data pipeline correctness. Source: `analysis.post_insight`
DB (112K records, last 3 days).

---

## 1. Sentiment Scores: Discrete Only (Design Choice)

**Finding:** All 112K records have exactly -0.5, 0, or +0.5 as sentiment score.
No continuous spectrum.

```
 overall_sentiment_score | count
-------------------------+-------
                     0.5 | 50838  (POSITIVE)
                    -0.5 | 35377  (NEGATIVE)
                       0 | 25839  (NEUTRAL)
```

**Root cause:** Sentiment model is a 3-class classifier. Score is derived from
label, not a regression output. `normalize_sentiment_score()` only re-signs
the raw score — doesn't discretize. The discrete values come from the model.

**Assessment:** Not a bug — current model architecture. However, limits
analytical depth (can't distinguish "slightly positive" from "very positive").

**Recommendation:** Future enhancement — upgrade to regression model or
expose raw confidence as granular score.

---

## 2. Engagement Score Missing for ~40% Records

**Finding:** engagement_score = 0 for records that have likes > 0.

```
 platform | total | has_likes | engagement_score=0 | pct_zero
----------+-------+-----------+-------------------+----------
 youtube  |  2690 |      2671 |               503 |    18.7%
 tiktok   |   217 |        17 |                16 |     7.4%
 facebook |    74 |         2 |                 2 |     2.7%
```

**Root cause:** Intent classifier's `should_skip` flag. When `primary_intent`
is SEEDING or SPAM, the pipeline returns early at Stage 2 — **before** sentiment
analysis, keyword extraction, and impact calculation.

SEEDING patterns include `\b0\d{9,10}\b` (Vietnamese phone numbers). Any
content containing a phone number is skipped entirely. Example: 221 YouTube
records with likes=3 ALL classified as SEEDING because descriptions include
contact numbers.

```
 primary_intent | processing_status |  cnt
----------------+-------------------+------
 SEEDING        | success_skipped   |  922  (0.9%)
 SPAM           | success_skipped   |  140  (0.1%)
```

**Assessment:** 0.9% skip rate is acceptable for spam filtering. But losing
sentiment + engagement data for skipped records is suboptimal — at minimum,
calculating engagement_score should still happen.

**Recommendation:** Decouple skip from impact calculation. Mark records as
SPAM/SEEDING for downstream filtering but still compute engagement_score
and sentiment before the early return.

---

## 3. Empty Keywords: 57% of Non-Skipped Records

**Finding:** 3924 out of 6894 `success` records (56.9%) have zero keywords
extracted.

**Analysis:** Keyword extraction pipeline:
1. Dictionary matching (domain-specific keyword map)
2. AI extraction (SpacyYake) if dictionary hits < ai_threshold
3. Filter, dedup, sort, limit

Sample content with no keywords: short Vietnamese comments ("Cức đó 🤣🤣🤣🤣",
11 chars), delivery driver discussions ("Đơn này toàn đơn tmdt bác nhỉ", 29
chars), and longer text (121 chars). The dictionary likely doesn't cover
general social media vocabulary, and AI extraction may have minimum length
or quality thresholds.

**Assessment:** Moderate impact. Short comments naturally have few keywords.
But 57% is high — suggests dictionary coverage gap or AI extraction threshold
too strict.

**Recommendation:** Check SpacyYake config (min_ngram_size, window_size, top_k)
and keyword map coverage. Consider lowering `ai_threshold` if it's preventing
AI extraction from running.

---

## 4. TikTok/Facebook Engagement Drop (June 7)

**Finding:** TikTok avg likes dropped from 3-28 (June 1-6) to exactly 1.0
on June 7. Facebook dropped from ~1.0 to 0.24.

```
    date    | platform | count | avg_likes | avg_comments | avg_shares
------------+----------+-------+-----------+--------------+-----------
 2026-06-07 | tiktok   |   217 |      1.00 |         0.00 |      0.00
 2026-06-06 | tiktok   |  2196 |      0.23 |         0.00 |      0.00
 2026-06-05 | tiktok   |  3614 |     10.18 |         1.03 |      0.62
```

**Root cause:** Parser field mapping verified correct. Engagement JSON from
Kafka matches DB storage (`likes`/`comments`/`shares` keys). The drop is in
the scraped data itself — scraper may be returning default/placeholder values
or collecting less engagement data.

**Assessment:** Scraper-side issue. Not a code bug in analysis or ingest
services.

**Recommendation:** Audit scraper configurations and API access (TikTok
rate limits, session expiration). Check if scraper pods were redeployed
around June 7.

---

## 5. Data Pipeline Health

| Metric | Status |
|--------|--------|
| Crash errors | **Fixed** — 0 errors since deploy |
| Data ingestion | **OK** — 104 new rows in 20 min |
| NULL critical fields | **OK** — 0 NULLs |
| Contract publish | **OK** — batch.completed + digest published |
| Pod health | **OK** — 25/25 Running |

---

## Recommendations Summary

| Priority | Issue | Action |
|----------|-------|--------|
| P0 | N/A — crash fixed | Done |
| P1 | Keywords empty (57%) | Tune SpacyYake thresholds, expand keyword dictionary |
| P2 | Sentiment granularity | Consider regression model for richer analytics |
| P3 | SEEDING skip loses data | Compute engagement_score before early return |
| P3 | TikTok scraper engagement | Audit scraper configs and API access |
