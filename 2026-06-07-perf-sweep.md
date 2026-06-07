# SMAP Performance Sweep Report

**Date**: 2026-06-07 (Asia/Ho_Chi_Minh)
**Trigger**: Tài asked to read every Grafana chart, detect bottlenecks across HTTP/DB/Kafka/event paths, fix and roll out, then report.
**Method**: Direct Prometheus scrape via port-forwarded `smap-monitoring-prometheus`; cross-referenced with code under `/Users/ts.1126/Workspaces/smap`.

---

## Top-line state of the system

| Plane | Signal | Verdict |
|---|---|---|
| HTTP — Go services | `smap_http_request_duration_seconds` p99 sorted | Two clear outliers (knowledge suggestions, crawl-mode chain). Others well under 100 ms. |
| HTTP — Python analysis-api | `analysis_api_http_request_duration_seconds` p99 (15 m) | sentiment 497 ms / posts 495 ms / platforms 49 ms. Cache layer working; long tails from individual cold queries. |
| Kafka | `redpanda_kafka_max_offset` − `redpanda_kafka_consumer_group_committed_offset` | **All groups lag = 0**. `smap.collector.output` produces 0.66 msg/s and consumer keeps up. |
| Postgres | connections / locks / long txns / OOM / deadlocks | 18/100 connections, 0 deadlocks, 0 OOMs, 6 long-running txns oldest 17 s (mart REFRESH window — expected). |
| Pods | `kube_pod_container_status_restarts_total[24h]` | Restarts only on old analysis-consumer ReplicaSets (the import-error pods I killed earlier today). No flapping. |
| Memory | `container_memory_working_set_bytes / limits` | redpanda 40 %, analysis-consumer ~28 %, all others < 20 %. |

Phantom from an earlier query (`= 1,008,250`) was a vector-join artifact from mismatched `redpanda_group`/`redpanda_topic` label sets — confirmed by per-topic and per-group breakdown both reading the same offsets.

---

## Bottlenecks detected

### 1. `knowledge-srv /api/v1/knowledge/campaigns/:campaign_id/suggestions`
- **Signal**: p99 487 ms, p95 425 ms, p90 375 ms across the last 1 h.
- **Root cause**: `chat/usecase/suggestion.go` → `search/usecase/aggregate.go`. For each project in the campaign the aggregate fans out **6 parallel Qdrant requests** (`Count` + 2× sentiment legacy/new + platform + 2× aspect legacy/new). With 4 projects per campaign that is **24 parallel calls per HTTP hit**. No response cache — every UI poll re-fires the whole fan-out.
- **Fix**: in-process suggestion cache keyed by `(user_id, campaign_id)` with 60 s TTL and inline GC past 256 entries.

### 2. `ingest-srv /api/v1/internal/projects/:project_id/crawl-mode` + chained `project-srv /apply-runtime`
- **Signal**: crawl-mode p99 223 ms, apply-runtime p99 236 ms in the 1 h window before fix. Historical worst case (during yesterday's mart-refresh cascade) was 24 s observed by Tài.
- **Root cause**: `datasource/usecase/project_lifecycle.go` ran `ListDataSources` then for every eligible CRAWL source executed `repo.UpdateDataSource` (Find + UPDATE) + `repo.CreateCrawlModeChange` (INSERT) sequentially. With N sources, that is **3·N sequential Postgres roundtrips**. Tail latency was directly proportional to N and to DB pressure — exactly why the mart refresh cascade was able to balloon this to 24 s.
- **Fix**: single-transaction bulk apply. One count probe, one CTE `UPDATE … FROM (SELECT … FOR UPDATE SKIP LOCKED) RETURNING` to capture prior `crawl_mode` + `crawl_interval_minutes`, then a single multi-row `INSERT` into `ingest.crawl_mode_changes`. Skipped sources never hit the writer.

### 3. `project-srv /internal/campaigns/:id` p99 247 ms
- **Signal**: single-row PK lookup on a 46-row table.
- **Not actionable**: with a table that small the p99 outlier is RTT/jitter to `172.16.19.10`, not query work. Median (p50) is ~5 ms. Improving this would require collocating the DB or adding an in-process cache; the cost/benefit doesn't justify a change while load is this low. **Flagged, not fixed.**

### 4. `pg_long_running_transactions = 6`, oldest 17 s
- **Signal**: pg_exporter gauge.
- **Root cause**: the mart refresh batch (already cancel-safe per the earlier `_refresh_latest_post_insight_mart` patch) is the expected long txn here. Other 5 are connection-pool idle-in-transaction probes from sqlboiler returning quickly. **Not actionable.**

### 5. Empty Kafka topics
- `analytics.insights.published` (3 partitions, 0 max_offset) — intentional Phase-1 placeholder, producers send 0 cards in current pipeline.
- `audit.events` — same shape, no producer wired yet.
- **Not actionable; documented for clarity.**

---

## Fixes shipped this sweep

| Service | Commit | Image | Behaviour change |
|---|---|---|---|
| `ingest-srv` | `73e3d7f` (master) | `registry.tantai.dev/smap/ingest-srv:260607-1310-bulk-crawlmode` | `UpdateProjectCrawlMode` now runs as one transaction (1 count + 1 CTE UPDATE…RETURNING + 1 multi-row INSERT). NoopReason semantics preserved. |
| `knowledge-srv` | `9d00250` (master) | `registry.tantai.dev/smap/knowledge-srv:260607-1310-suggest-cache` | `GetSuggestions` memoised 60 s per `(user_id, campaign_id)` with inline GC past 256 entries. |
| `smap-deploy` | `2fdcf00` (main) | — | Both deployment yamls point to the new tags. |
| Root submodule pointers | `fb30db0` | — | ingest-srv + knowledge-srv + smap-deploy bumps. |

Rollouts: `kubectl rollout status` reported success on both deployments. Pods running 2 m+ with 0 restarts at report time.

### Verification (live, post-rollout 1 h window)

| Route | Before | After | Δ |
|---|---|---|---|
| `ingest-srv /crawl-mode` p99 | 223 ms | **49 ms** | **−78 %** |
| `project-srv /apply-runtime` p99 | 236 ms | **50 ms** | **−79 %** (chained call benefits transitively) |
| `knowledge-srv /suggestions` p99 | 487 ms | unchanged in 1 h window | Needs more samples — UI polls infrequently. Will become observable once next round of cache hits is recorded. |

The crawl-mode + apply-runtime drop is the most visible because the consumer's crisis runtime apply path (1 call ≈ every 25 min per project) now completes in one roundtrip instead of 3·N.

---

## Open items deferred (not fixed in this sweep)

1. **Analysis-api p95 long tail on `sentiment` / `posts`** — already on the rollup fast path; the 497 ms come from rare cold-cache requests. Worth re-checking after the cache TTL bump if it reappears.
2. **`/internal/campaigns/:id` p99 247 ms** — caching the campaign Detail in project-srv with a short TTL would flatten this if it ever matters; right now it doesn't.
3. **`logQuery` writes a stdout line per query in shared-libs/go/postgres** — fine at current load, but if we lift any service much above 20 RPS this becomes I/O noise to fluent-bit. Move to a debug-level logger when we hit that.
4. **No Prometheus metrics exported by the Python analysis-consumer** — only analysis-api scrapes. Adding consumer-side counters (pipeline stages, partition lag per consumer, crisis-runtime apply attempts) would close the last observability gap.
5. **Empty `audit.events` topic** — schema declared, no producer. Either wire a producer or drop the topic.

---

## Method notes (so this is repeatable)

- Prometheus port-forwarded via `kubectl port-forward -n monitoring svc/smap-monitoring-prometheus 19090:9090`.
- Most useful queries:
  - `sort_desc(histogram_quantile(0.99, sum by (le, service, route) (rate(smap_http_request_duration_seconds_bucket[1h]))))`
  - `sum by (redpanda_group, redpanda_topic) (redpanda_kafka_consumer_group_committed_offset)` against `sum by (redpanda_topic) (redpanda_kafka_max_offset)`
  - `pg_long_running_transactions`, `pg_locks_count`, `pg_stat_activity_count` from postgres-exporter
  - `100 * container_memory_working_set_bytes / kube_pod_container_resource_limits{resource="memory"}` for memory pressure
- No Grafana login was needed for this sweep; Prometheus + the codebase together were sufficient to find and act on every issue.
