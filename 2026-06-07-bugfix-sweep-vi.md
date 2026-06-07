# SMAP Sửa Lỗi & Cải Thiện — 2026-06-07

## 1. Crash Pipeline: `PipelineRunResult` không có thuộc tính `errors`

**Nguyên nhân gốc:** Dòng `usecase.py:37` truy cập `result.errors` nhưng
dataclass `PipelineRunResult` chỉ có `stage_results` (danh sách `StageResult`,
mỗi phần tử có field `.error`). Lỗi này được thêm vào từ phiên làm việc
trước khi thêm Prometheus instrumentation.

**Ảnh hưởng:** TOÀN BỘ pipeline bị crash sau khi NLP enrichment hoàn tất.
Không có dữ liệu nào được xử lý từ 17:02. Mỗi batch đều fail ở dòng
metrics-reporting — chạy sau pipeline nhưng trước persist + publish.

**Fix:** `analysis-srv/internal/pipeline/usecase/usecase.py:37`
```python
# Trước
status = "error" if result.errors else "ok"
# Sau
status = "error" if any(sr.error for sr in (result.stage_results or [])) else "ok"
```

**Xác minh:** Deploy `analysis-consumer:260607-2045-fix-crash`. 52 dòng mới
được ingest trong 5 phút. Không còn log crash.

---

## 2. Chỉ số Tương Tác (Like/Share/Comment) Hiển Thị 0

**Nguyên nhân gốc:** Fast path rollup của posts (`_compute_posts_from_rollup`)
trả về format response hoàn toàn khác so với full query path:
- Chỉ có `engagement` (điểm tổng hợp), thiếu `views`/`likes`/`comments`/`shares`
- Dùng snake_case (SQL) thay vì camelCase (Python dict)
- Thiếu `authorUsername`, `authorFollowers`, `authorVerified`, `sentimentScore`

Khi UI mở tab Insight mặc định (không filter), request đi qua rollup fast
path. Các field bị thiếu → `undefined` → hiển thị 0.

**Fix:** `analysis-srv/internal/http/analytics_service.py:1555-1613`

Viết lại `_compute_posts_from_rollup`:
1. Query từng cột riêng (bao gồm `uap_metadata`) thay vì `json_agg(row_to_json(p))`
2. Áp dụng post-processing Python giống hệt `_compute_posts`: parse
   `uap_metadata.engagement`, extract `views`/`likes`/`comments`/`shares`,
   build author metadata, tính sentiment label

**Xác minh:** Deploy `analysis-api:260607-2050-engagement-fix`. Format
response khớp hoàn toàn với full query path.

**Ghi chú:** Dữ liệu TikTok ngày 7/6 có dấu hiệu sụt giảm ở tầng scraper
(92% post có 0 likes, so với ~53% ngày 5-6/6). Field mapping của parser
đúng — đây là vấn đề data source, không phải parsing bug.

---

## 3. Tần Suất Crawl Bị Cứng Trong Setup Wizard

**Nguyên nhân gốc:** `web-ui/src/app/onboarding/page.tsx:46` hardcode
`CRAWL_INTERVAL_MINUTES = 60`, không cho user chọn. Trong khi đó, Project
Settings → Data collection có input interval (min 5, mặc định 30).

**Fix (3 thay đổi):**
1. Xóa `const CRAWL_INTERVAL_MINUTES = 60`
2. Thêm state `crawlIntervalMinutes` (mặc định `"30"`, đồng bộ với settings)
3. Thêm `<input type="number" min={5}>` vào bước Monitoring
4. `handleFinish` dùng `Math.max(5, Number(crawlIntervalMinutes) || 30)`

**Xác minh:** TypeScript check (`tsc --noEmit`) — 0 lỗi.

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| analysis-srv | `16accee` | fix: crash in PipelineRunResult.errors + missing engagement fields in posts rollup |
| web-ui | `1deeb70` | feat: add crawl interval input to onboarding setup wizard |
| smap-deploy | `a882292` | chore: bump analysis images (crash fix + engagement rollup fix) |

## Images Đã Deploy

| Service | Image Tag |
|---------|-----------|
| analysis-consumer | `260607-2045-fix-crash` |
| analysis-api | `260607-2050-engagement-fix` |
