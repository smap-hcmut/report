# Analytics Refresh Incident — 2026-06-08

## TL;DR

UI showed no analytics data for ~34 hours even though `ingest-srv` and
`analysis-consumer` kept producing rows because every iteration of
`analysis-api`'s global mart-refresh loop timed out before it could rebuild
`kpi_daily`, `posts_recent_top`, and `metrics_daily`. The
`analysis.latest_post_insight` materialized view had grown to dedupe over an
8.2M-row `analysis.post_insight`, and `REFRESH MATERIALIZED VIEW
CONCURRENTLY` no longer fit inside the 180 s mart-refresh timeout. The
TRUNCATE-and-rebuild chain that fed the rollups never ran because of the
upstream failure.

The fix replaces the global rebuild with a per-project refresh that reads
straight from `analysis.post_insight` (DISTINCT ON inline), scoped by
`project_id`. Cost now scales with one project's slice instead of the whole
table.

## Detection

| Signal | Source | Observation |
| --- | --- | --- |
| Empty Insight tabs while campaigns active | UI complaint | Mentions / posts / sentiment all empty for every campaign |
| `kpi_daily.refreshed_at = 2026-06-07 04:01 UTC` | direct PG query | All 3 rollups frozen 34 h while `post_insight` continued growing |
| `analysis-api` warning every 1 h | `kubectl logs analysis-api` | `canceling statement due to statement timeout` for `SELECT analysis.refresh_latest_post_insight()` since 2026-06-08 00:47 UTC, 100 % failure rate |
| `analysis.post_insight = 8,237,928 rows` | PG count | View dedupes 8.2 M rows → 59 k unique per `REFRESH MATERIALIZED VIEW CONCURRENTLY` |

## Root cause

The original analytics read-model was layered:

1. `REFRESH MATERIALIZED VIEW CONCURRENTLY analysis.latest_post_insight`
   (one pass over all 8 M rows).
2. `TRUNCATE analysis.kpi_daily; INSERT … FROM latest_post_insight;`
3. `TRUNCATE analysis.posts_recent_top; INSERT … FROM latest_post_insight;`
4. `TRUNCATE analysis.metrics_daily; INSERT … FROM latest_post_insight;`

Every step ran under the same backend with a shared `statement_timeout`
(180 s by deploy config, 240 s by code default). Step 1 alone exceeded the
budget once `post_insight` crossed roughly 5 M rows. The transaction rolled
back so steps 2–4 never landed; the rollups stayed frozen at their last
successful timestamp. Subsequent iterations hit the same wall in a loop.

Even a one-shot manual `REFRESH MATERIALIZED VIEW CONCURRENTLY` couldn't
finish within reasonable bounds while three `analysis-consumer` pods were
running `auto_ontology` heavy `GROUP BY post_insight` scans against the same
table (no index on `created_at`). The IO contention compounded the timeout.

## What changed

### 1. Per-project refresh functions (`migration/015_per_project_refresh.sql`)

Three new SQL functions, each rewriting a single project's rows:

- `analysis.refresh_kpi_daily_for_project(text)`
- `analysis.refresh_posts_recent_top_for_project(text)`
- `analysis.refresh_metrics_daily_for_project(text)`

A wrapper `analysis.refresh_project_rollups(text)` holds a per-project
advisory lock and calls all three. Each function reads `post_insight`
directly with `DISTINCT ON` inline — no dependency on the materialized
view. Cost scales with the project's row count, not the table's.

`SECURITY DEFINER`, owned by `postgres`, `EXECUTE` granted to
`analysis_prod`.

### 2. Supporting index (`migration/016_post_insight_dedupe_index.sql`)

`idx_post_insight_project_dedupe_v2` covers the dedupe ordering
(`project_id`, normalized platform, dedupe key, time columns) with the
exact partial predicate the refresh uses
(`business_relevance_score >= 0.30 OR source_kind IN ('focused_page',
'focused_profile')`). The pre-existing
`idx_post_insight_project_relevant_dedupe_latest` was filtered at `>= 0.45`
and the planner could not use it.

Built `CONCURRENTLY` to avoid blocking ingest writes.

### 3. New refresh loop (`apps/api/main.py`)

- `_per_project_rollup_loop` replaces `_latest_post_insight_mart_loop`.
- Each tick:
  - Lists projects worth refreshing from a UNION of `kpi_daily`,
    `posts_recent_top`, and recent `post_insight` rows (window =
    `ANALYTICS_MART_REFRESH_SECONDS * 4`).
  - Calls `analysis.refresh_project_rollups(project_id)` per project,
    sequentially, with a per-project `statement_timeout` of 15–120 s.
  - A per-project failure is logged but does not abort the tick.
- Fallback: when the SQL function is not present (migration 015 not yet
  applied) the loop runs equivalent DELETE+INSERT for `posts_recent_top`
  and `metrics_daily` from Python using `analysis_prod`'s native
  privileges. `kpi_daily` requires the SQL function.

### 4. Deploy config (`smap-deploy/services/analysis/api-deployment.yaml`)

- `ANALYTICS_MART_REFRESH_SECONDS`: `3600` → `300` (loop ticks every 5 min;
  per-project cost is small enough).
- `ANALYTICS_MART_REFRESH_TIMEOUT_MS`: `180000` → `60000` (per-project
  budget; the loop never holds the whole table again).
- New: `ANALYTICS_USE_LATEST_MART=false`. `analytics_service` reads directly
  from `analysis.post_insight` (inline DISTINCT ON) instead of the
  materialized view. The rollup tables stay authoritative for the KPI /
  platforms / sentiment / posts fast paths.
- Image bumped to `analysis-api:260608-2151-per-project-refresh`.

## Sibling findings (queued / triaged, not yet fixed)

| Severity | Finding | Notes |
| --- | --- | --- |
| ⚠️ Medium | `notification-srv` logs `XReadGroup failed: NOGROUP` for `smap:notifications:stream` every second since the last Redis restart. | The subscriber never (re)creates the Redis Streams consumer group after Redis comes back on an `emptyDir` boot. Needs a `XGROUP CREATE … MKSTREAM` retry. |
| ⚠️ Medium | `knowledge-srv` logs `gate=content_too_short` for most Facebook comments (`indexed=0` for entire batches). | Expected behaviour given `MinContentLength = 10` runes vs short reactions, but the WARN-level log spam should drop to DEBUG. Not a correctness bug. |
| ⚠️ Medium | `analysis.post_insight` has no index on `created_at`. `auto_ontology._fetch_candidates` (3 consumer pods, every 30 min) does parallel seq scans. | Add `CREATE INDEX CONCURRENTLY idx_post_insight_created_at ON analysis.post_insight (created_at)` or change the candidate query to `content_created_at`. |
| ℹ️ Low | `rabbitmq` `queue.declare ... not_found: 'facebook_tasks'` after Redis/RabbitMQ pod restart. | `scapper-srv` declares passively and races `ingest-srv`. Self-heals once `ingest-srv` publishes; otherwise scapper retries. Acceptable for `emptyDir` topology. |
| ✅ Done in this change | `knowledge-srv GetOneDocument: Document not found: sql: no rows in result set` repeats. | Already addressed by 81365c9; verify after this rollout. |

## Validation plan

1. Apply `migration/015_per_project_refresh.sql` as `postgres` ✅
2. Apply `migration/016_post_insight_dedupe_index.sql` as `postgres` (in
   progress at time of writing, CREATE INDEX CONCURRENTLY).
3. Rollout `analysis-api:260608-2151-per-project-refresh` ✅
4. Manually call `analysis.refresh_project_rollups($project_id)` for every
   project with active campaigns, confirm `kpi_daily.refreshed_at = now()`.
5. Hit `GET /api/v1/analytics/kpis?campaignId=…` and confirm non-empty
   `mentions`. Confirm the same for `/platforms`, `/sentiment`,
   `/posts`.
6. Watch `analysis-api` logs for one full refresh tick (5 min);
   `analysis-api rollup tick complete: projects=N succeeded=N failed=0` is
   the success line.

## Follow-ups

- Drop the `analysis.latest_post_insight` materialized view once we are
  fully confident no consumer depends on it. The `analytics_service` flag
  `ANALYTICS_USE_LATEST_MART` now defaults to the inline path so the view
  is effectively unused.
- Move heavy field derivation (source identity, quality flags, engagement
  projections) into the consumer write path so the refresh can shrink
  further to a pure GROUP BY.
- Stagger `auto_ontology` across consumer pods (jittered start, pod-local
  offset) so three replicas don't fire parallel heavy scans on the same
  minute boundary.

## Owners / artifacts

- `analysis-srv` migration + main.py — this PR
- `smap-deploy` image bump + env tweaks — this PR
- Image: `registry.tantai.dev/smap/analysis-api:260608-2151-per-project-refresh`
- DB migrations applied on `pg15_prod` (172.16.19.10) at 2026-06-08
  during incident response.
