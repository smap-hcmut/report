# SMAP Bug Fix & Improvement Sweep — 2026-06-07

## 1. Pipeline Crash: `PipelineRunResult` has no attribute `errors`

**Root cause:** `usecase.py:37` accessed `result.errors` but `PipelineRunResult`
dataclass only exposes `stage_results` (list of `StageResult`, each with
`.error` field). This was introduced in the previous session's Prometheus
instrumentation patch.

**Impact:** ALL pipeline runs crashed after NLP enrichment. No data was
processed for any project from 17:02 local time onwards. Every batch
failed at the metrics-reporting line, which runs after the pipeline
completes but before persist + publish.

**Fix:** `analysis-srv/internal/pipeline/usecase/usecase.py:37`
```python
# Before
status = "error" if result.errors else "ok"
# After
status = "error" if any(sr.error for sr in (result.stage_results or [])) else "ok"
```

**Verification:** Deployed `analysis-consumer:260607-2045-fix-crash`. 52 new
rows ingested within 5 minutes of rollout. No crash logs since.

---

## 2. Engagement Metrics Displaying 0 on All Records

**Root cause:** The posts rollup fast path (`_compute_posts_from_rollup`)
returned a completely different response shape from the full query path.
Specifically:
- Only returned `engagement` (composite score), missing `views`/`likes`/
  `comments`/`shares` individual fields
- Used SQL snake_case aliases instead of Python camelCase dict keys
- Missing `authorUsername`, `authorFollowers`, `authorVerified`, `sentimentScore`

When the UI hits the unfiltered Insight tab (the default), it takes the
rollup fast path. The missing fields rendered as `undefined` → displayed 0.

**Fix:** `analysis-srv/internal/http/analytics_service.py:1555-1613`

Rewrote `_compute_posts_from_rollup` to:
1. Query individual columns (including `uap_metadata`) instead of using
   `json_agg(row_to_json(p))`
2. Apply the same Python post-processing as `_compute_posts`: parse
   `uap_metadata.engagement`, extract `views`/`likes`/`comments`/`shares`,
   build author metadata, compute sentiment label

**Verification:** Deployed `analysis-api:260607-2050-engagement-fix`.
Response format now matches full query path exactly.

**Note:** TikTok engagement on June 7 already showed a data-level drop
(92% of posts had 0 likes, vs ~53% on June 5-6). This appears to be a
scraper-side issue, not a parsing bug — the parser field mapping is
correct and data in DB is structurally valid.

---

## 3. Crawl Interval Hardcoded in Setup Wizard

**Root cause:** `web-ui/src/app/onboarding/page.tsx:46` hardcoded
`CRAWL_INTERVAL_MINUTES = 60` with no user input. Meanwhile, Project
Settings → Data collection exposes an interval input (min 5, default 30).

**Fix (3 changes):**
1. Removed `const CRAWL_INTERVAL_MINUTES = 60`
2. Added `crawlIntervalMinutes` state (default `"30"`, matching settings page)
3. Added interval `<input type="number" min={5}>` to Monitoring step UI
4. `handleFinish` uses `Math.max(5, Number(crawlIntervalMinutes) || 30)`

**Verification:** TypeScript check passes (`tsc --noEmit`), 0 errors.

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| analysis-srv | `16accee` | fix: crash in PipelineRunResult.errors + missing engagement fields in posts rollup |
| web-ui | `1deeb70` | feat: add crawl interval input to onboarding setup wizard |
| smap-deploy | `a882292` | chore: bump analysis images (crash fix + engagement rollup fix) |

## Deployed Images

| Service | Image Tag |
|---------|-----------|
| analysis-consumer | `260607-2045-fix-crash` |
| analysis-api | `260607-2050-engagement-fix` |
