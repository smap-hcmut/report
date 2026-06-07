# SMAP Performance Debug Report

Date: 2026-06-06
Author: Ngộ Không (audit cho Tài)
Scope: vấn đề perf/scalability/correctness toàn workspace.
Method: 2 issue gốc (Tài flag) + 6 investigator song song (DB, broker+cache, external deps, web-ui, K8s runtime, RAG pipeline).

---

## 🔥 TOP CRITICAL — 7 món fix trước

| # | Issue | File:line | Tác hại | Effort |
|---|---|---|---|---|
| C1 | Multi-project starvation (no round-robin) | `ingest-srv/.../due_targets.go:31-33` + `scapper-srv/app/worker.py:127` | TTFD p95=68m vs p50=5m | 1d |
| C2 | Insight API JSON aggregate full-scan | `analysis-srv/internal/http/analytics_service.py:592-632` | p95 1.5s, semaphore khoá | 1d (index) + 2w (rollup) |
| C3 | Ontology Redis key TTL=0 (leak) | `project-srv/internal/ontology/repository/redis/rules.go:47` | Memory grow forever | 30min |
| C4 | Kafka producer **non-idempotent** | `shared-libs/go/kafka/producer.go:24-30` | UAP duplicate khi retry → double insight | 1h |
| C5 | Redis PubSub drop notifications | `notification-srv/internal/websocket/delivery/redis/subscriber.go:20` | User mất alert khi slow WS | 3d |
| C6 | Campaign RBAC bypass (search/chat) | `knowledge-srv/internal/search/usecase/helpers.go:16-48` | User A read User B campaign | 4h |
| C7 | Ingress timeout < statement timeout | Traefik 60s vs `ANALYTICS_DATABASE_STATEMENT_TIMEOUT_MS=90000` | Orphan DB query, pool exhaustion | 1h |

---

## ISSUE-01: Multi-project starvation — no round-robin

**Severity**: 🔴 CRITICAL | **From**: Tài flag + deep audit

### Root cause — 3 tầng đều FIFO

| Layer | File:line | Vấn đề |
|---|---|---|
| Ingest dispatcher | `ingest-srv/internal/execution/repository/postgre/due_targets.go:31-33` | `ORDER BY priority DESC, next_crawl_at ASC` toàn cục, không weight per-project |
| Ingest cron loop | `ingest-srv/internal/execution/usecase/cron.go:23-56` | Pull batch theo sort → 1 project chiếm slot |
| RabbitMQ topology | `ingest-srv/internal/execution/delivery/rabbitmq/producer/producer.go:118-129` | 3 queue per-platform (`tiktok_tasks`, `facebook_tasks`, `youtube_tasks`). KHÔNG per-project |
| Scapper consumer | `scapper-srv/app/worker.py:127` + `config.py:26` | `prefetch_count=4` global trên 1 channel 3 queue |
| Analysis batch | `analysis-srv/internal/consumer/server.py:265-269` | Batch `(project_id, domain_type_code)` chỉ sau Kafka → không cứu upstream |

### Hệ quả
- p50=325s, p95=4081s (gap 12.5×), khớp số đo.
- 50% E2E run no-data.

### Fix
1. **Per-project DRR** ở `due_targets.go` — WINDOW + ROW_NUMBER per project. 1d. Giảm gap ~70%.
2. **Per-project queue suffix** — `tiktok_tasks.{hash(project_id)%N}`. 3d.
3. **Token bucket per-project** ở ingest. Simplest.

---

## ISSUE-02: Insight API exceeded/timeout

**Severity**: 🔴 CRITICAL | **From**: Tài flag + deep audit

### Root cause
| # | Vấn đề | File:line |
|---|---|---|
| 1 | JSON path KHÔNG indexed: `uap_metadata->'engagement'->>'views'` aggregate full scan | `analysis-srv/internal/http/analytics_service.py:592-632` |
| 2 | `asyncio.Semaphore(8)` khoá 5 endpoint × 2 query = 10 ops | `analytics_service.py:349` |
| 3 | Không có rollup table — aggregate 500k+ row mỗi request | `migration/007_latest_post_insight_mart.sql` (chỉ dedup, không rollup) |

### Fix (ranked ROI)
| # | Fix | Effort | Gain p95 |
|---|---|---|---|
| 1 | Expression index `((uap_metadata->'engagement'->>'views')::bigint)` | 1d | ~50% |
| 2 | Semaphore 8 → 16 | 5min | ~15% |
| 3 | `kpi_daily` rollup table populated by consumer | 2w | ~70% |
| 4 | HTTP `Cache-Control: max-age=300, swr=600` | 2d | client 50% |
| 5 | Bundle 5 endpoint → 1 batch endpoint | 3d | ~30% |

### Go rewrite — **REJECT**
Bottleneck SQL+JSON+semaphore, không phải Python. Rewrite Go vẫn gặp đúng query plan. 8w → 30% gain → ROI tệ.

---

# AUDIT THÊM — Phát hiện ngoài 2 issue gốc

## A. DB / Postgres layer

### A1. 🔴 HIGH — Pool config KHÔNG wired vào client
**File**: `shared-libs/go/postgres/client.go:46-95`
**Vấn đề**: Const `DefaultMaxOpenConns=25`, `DefaultMaxIdleConns=5`, `DefaultConnMaxLifetime=5s` định nghĩa nhưng `NewWithLogger()` KHÔNG gọi `SetMaxOpenConns`/`SetMaxIdleConns`. Tất cả Go service (`project`, `identity`, `ingest`) dùng default stdlib (25 open, 0 idle timeout).
**Fix**: Gọi `db.SetMaxOpenConns(cfg.MaxOpenConns)` + `db.SetMaxIdleConns(cfg.MaxIdleConns)` trong `NewWithLogger`. 10 LoC.

### A2. 🔴 HIGH — Không có statement_timeout ở Go services
**File**: `project-srv/`, `identity-srv/`, `ingest-srv/` — không có `SET statement_timeout`
**Vấn đề**: Chỉ `analysis-srv/apps/api/main.py:93-98` set timeout. Go services runaway query pin backend vô hạn.
**Fix**: Thêm `SET statement_timeout = 30000` vào `shared-libs/go/postgres/client.go` after connect, hoặc per-query `SET LOCAL`.

### A3. 🟡 MED — Index thiếu trên `ingest.dryrun_results(project_id)`
**File**: `ingest-srv/migrations/001_create_schema_ingest_v1.sql:165`
**Vấn đề**: Hot query `WHERE project_id=$1 ORDER BY created_at DESC` seq-scan.
**Fix**: `CREATE INDEX idx_dryrun_results_project_created ON ingest.dryrun_results(project_id, created_at DESC);`

### A4. 🟡 MED — `BeginTx(ctx, nil)` không có timeout
**File**: 
- `ingest-srv/internal/dryrun/repository/postgre/dryrun.go:84`
- `ingest-srv/internal/execution/repository/postgre/cancel.go:33`
- `ingest-srv/internal/execution/repository/postgre/completion.go:12`
**Fix**: Wrap context với `context.WithTimeout(ctx, 30*time.Second)` trước BeginTx.

### A5. 🟢 LOW — `project.projects` FK `campaign_id` không CASCADE
**File**: `project-srv/migration/init_schema.sql:89`
**Vấn đề**: Delete campaign → orphan projects nếu race.
**Fix**: `ON DELETE CASCADE` hoặc app-level cleanup transaction.

---

## B. Message broker + Cache layer

### B1. 🔴 CRITICAL — Ontology Redis key TTL=0 (leak)
**File**: `project-srv/internal/ontology/repository/redis/rules.go:47`
**Vấn đề**: `Set(key, payload, 0)` = no expire. Key `smap:project:ontology-rules:{project_id}` tích lũy vô hạn.
**Fix**: TTL 7d hoặc đặt `MAXMEMORY-POLICY=allkeys-lru` ở Redis server.

### B2. 🔴 CRITICAL — Kafka producer non-idempotent
**File**: `shared-libs/go/kafka/producer.go:24-30`
**Vấn đề**: Sarama `Idempotent=false` default. Producer retry → UAP duplicate → analysis double-insert insight.
**Fix**: 
```go
config.Producer.Idempotent = true
config.Producer.RequiredAcks = sarama.WaitForAll
config.Net.MaxOpenRequests = 1
```

### B3. 🔴 CRITICAL — Redis PubSub silent drop
**File**: `notification-srv/internal/websocket/delivery/redis/subscriber.go:20`
**Vấn đề**: `PSubscribe(project:*:user:*, alert:*, ...)`. Redis PUBSUB không có backpressure → slow WS subscriber drop msg.
**Fix**: 
- Switch sang Redis Streams (`XADD`/`XREADGROUP` với consumer group) cho delivery guarantee.
- Hoặc thêm buffer queue per-subscriber + DLQ.

### B4. 🔴 HIGH — Kafka `WaitForLocal` acks
**File**: `shared-libs/go/kafka/producer.go:25`
**Vấn đề**: Chỉ chờ local broker ack, không replication. Broker fail → mất msg.
**Fix**: `RequiredAcks = WaitForAll` + `min.insync.replicas=2` ở broker.

### B5. 🔴 HIGH — Ontology cache stale 10s+ batch window
**File**: `project-srv/internal/ontology/repository/redis/rules.go:47`
**Vấn đề**: Khi rules update, analysis-srv consumer fetch via HTTP cache 60s (`analysis-srv/internal/http/project_client.py:57`). Edit ontology → up to 60s stale.
**Fix**: Pub invalidation event `project.ontology.invalidated.{project_id}` → analysis-srv subscriber clear cache.

### B6. 🔴 HIGH — Knowledge-srv không dedup duplicate UAP
**File**: `knowledge-srv/internal/indexing/delivery/kafka/consumer/handler.go:21-30`
**Vấn đề**: Error returns `fmt.Errorf()` nhưng `MarkMessage` always call → at-least-once không dedup. Replay offset → re-embed + re-upsert Qdrant.
**Fix**: Check `analytics_id` trong Postgres trước embed. Đã có UNIQUE constraint nhưng race ở app layer (xem F6).

### B7. 🟡 MED — RabbitMQ không có DLX
**File**: `ingest-srv/internal/execution/delivery/rabbitmq/constants.go:41-56`
**Vấn đề**: Queue durable=true nhưng KHÔNG declare DLX. Nack(requeue=false) → drop silent.
**Fix**: 
```go
args["x-dead-letter-exchange"] = "smap.dlx"
args["x-dead-letter-routing-key"] = queueName + ".dlq"
```

### B8. 🟡 MED — Kafka consumer rebalance RoundRobin (excess rebalance)
**File**: `shared-libs/go/kafka/consumer.go:26`
**Vấn đề**: Range/RoundRobin = stop-the-world rebalance khi pod restart.
**Fix**: `partition.assignment.strategy = sticky` (CooperativeStickyAssignor).

### B9. 🟡 MED — Redis pool config không wired
**File**: `shared-libs/go/redis/client.go:59-63`
**Vấn đề**: `NewClient()` không set pool. Default `pool_size=10`. Config nói 50 nhưng bị bỏ qua.
**Fix**: Wire `cfg.PoolSize` vào `redis.Options`.

### B10. 🟡 MED — Ontology Upsert race (no CAS)
**File**: `project-srv/internal/ontology/repository/redis/rules.go:26-51`
**Vấn đề**: Read existing → merge → write. 2 concurrent edit → last-write-wins, mất rule.
**Fix**: Dùng Redis WATCH/MULTI/EXEC hoặc Lua script atomic merge.

---

## C. External deps (Qdrant, Voyage, Gemini, MinIO, HTTP)

### C1. 🔴 HIGH — `http.Client{}` không timeout (Go default infinity)
**File**: `shared-libs/go/httpclient/wrapper.go:21`
**Vấn đề**: Nil client fallback = bare `http.Client{}` = NO timeout. Slow upstream → connection leak.
**Fix**: `&http.Client{Timeout: 30 * time.Second}` minimum.

### C2. 🔴 HIGH — Portal health check `http.DefaultClient`
**File**: `smap-deploy/portal/main.go:266,399,460,488`
**Vấn đề**: `http.DefaultClient.Do()` không có client-level timeout, chỉ ctx 3s. Hang sau 3s → socket leak.
**Fix**: Tạo dedicated client với `Timeout: 5*time.Second` + connection reuse.

### C3. 🔴 HIGH — LLM provider không cap tool-call iterations
**File**: `shared-libs/go/llm/provider.go:127-145`
**Vấn đề**: Retry loop không check max iterations. Tool call loop có thể infinite.
**Fix**: Add `maxToolIterations=10` guard.

### C4. 🟡 MED — Qdrant gRPC không keepalive
**File**: `knowledge-srv/pkg/qdrant/interface.go:78`
**Vấn đề**: `grpc.Dial(addr, opts...)` không set keepalive. Dead connection không detect.
**Fix**: 
```go
grpc.WithKeepaliveParams(keepalive.ClientParameters{
  Time: 30*time.Second, Timeout: 5*time.Second,
})
```

### C5. 🟡 MED — Voyage không batch ≤128 enforcement
**File**: `knowledge-srv/pkg/voyage/voyage.go:11-46`
**Vấn đề**: Voyage limit 128 inputs/call. Code không split. >128 → silent truncate/fail.
**Fix**: Chunk input thành slice 128, fan-out.

### C6. 🟡 MED — Retry không respect `Retry-After` header
**File**: `shared-libs/go/httpclient/client.go:81-88`
**Vấn đề**: Fixed 1s sleep, không đọc 429 Retry-After. Hammer API khi rate-limit.
**Fix**: Parse `Retry-After`, exponential backoff với jitter.

### C7. 🟡 MED — Qdrant 30s timeout quá ngắn cho large upsert
**File**: `knowledge-srv/pkg/qdrant/constant.go:7`
**Fix**: Tách timeout: search=10s, upsert_batch=60s.

### C8. 🟢 LOW — Scapper MinIO sync trong async context
**File**: `scapper-srv/app/worker.py:118-123`
**Vấn đề**: `Minio()` sync client trong FastAPI async → block event loop khi upload.
**Fix**: `aiobotocore` hoặc `asyncio.to_thread()`.

---

## D. Web-UI (Next.js 15 + React 19)

### D1. 🔴 HIGH — `smap/page.tsx` monolith 3142 dòng
**File**: `web-ui/src/app/smap/page.tsx:1`
**Vấn đề**: 5 tab (MAP, Projects, Insights, Stalker, Reports) bundle chung, all top-level import. `grep dynamic` zero match → không lazy load.
**Fix**: `dynamic(() => import('./tabs/InsightsTab'), {ssr: false})` cho 5 tab. Tiết kiệm ~200KB initial.

### D2. 🔴 HIGH — Context value KHÔNG memoized
**File**: `web-ui/src/app/smap/layout.tsx:129-141`
**Vấn đề**: `value={{...}}` literal mỗi render → all consumer re-render.
**Fix**: `const value = useMemo(() => ({...}), [deps])`.

### D3. 🔴 HIGH — Không có ErrorBoundary cho InsightsTab
**File**: `web-ui/src/app/smap/page.tsx:1410`
**Vấn đề**: Query throw → toàn page crash. Skeleton stuck nếu query fail mid-load.
**Fix**: Wrap `<ErrorBoundary fallback={...}>` quanh mỗi tab.

### D4. 🔴 HIGH — RSC missed — `smap/layout.tsx` 'use client'
**File**: `web-ui/src/app/smap/layout.tsx:1`
**Vấn đề**: Entire smap tree client-rendered. TopNav, gradient orbs không cần.
**Fix**: Tách `layout-shell.server.tsx` (RSC) + `layout-providers.client.tsx`.

### D5. 🟡 MED — `refetchOnMount: true` cho analytics
**File**: `web-ui/src/lib/hooks/analytics-query-options.ts:95`
**Vấn đề**: Force refetch dù fresh. Project toggle → double-fetch.
**Fix**: Bỏ hoặc conditional `refetchOnMount: (q) => q.state.dataUpdatedAt < scopeChangeTime`.

### D6. 🟡 MED — `setQueryData()` + `invalidateQueries()` redundant
**File**: `web-ui/src/app/smap/page.tsx:1043-1044`
**Fix**: Chỉ giữ `setQueryData()`.

### D7. 🟡 MED — `GlowCard` onMouseMove unthrottled (240 updates/s)
**File**: `web-ui/src/components/animated/GlowCard.tsx:16-43`
**Fix**: Throttle 60ms với `requestAnimationFrame`.

### D8. 🟡 MED — Avatar `<img>` raw, no LQIP
**File**: `web-ui/src/components/heap/tooltips/shared/Avatar.tsx:24-30`
**Fix**: Bg color placeholder + `loading="lazy"`.

---

## E. K8s runtime (smap-deploy)

### E1. 🔴 CRITICAL — Ingress timeout < statement timeout
**File**: `smap-deploy/services/analysis/api-deployment.yaml:62` + smap-ui ingress
**Vấn đề**: 
- `ANALYTICS_DATABASE_STATEMENT_TIMEOUT_MS=90000` (90s)
- `ANALYTICS_QUERY_TIMEOUT_MS=60000` (60s)
- Traefik default 60s
- → Traefik close ở 60s, DB query vẫn chạy 90s → orphan query → pool exhaustion
**Fix**: 
```yaml
# ingress middleware
spec:
  middlewares:
    - name: long-timeout
# Middleware
spec:
  responseHeaders:
    customResponseHeaders: {}
  # actual fix
spec:
  forwardingTimeouts:
    dialTimeout: 5s
    responseHeaderTimeout: 95s
    idleTimeout: 90s
```
Đồng bộ chain: Traefik 95s > app 90s > DB 80s.

### E2. 🔴 HIGH — 6 service single-replica + 0 PDB
**File**: 
- `services/identity/deployment.yaml:13` replicas=1
- `services/notification/deployment.yaml:14` replicas=1
- `services/ingest/deployment.yaml:13` replicas=1
- `services/project/deployment.yaml:13` replicas=1
- `services/knowledge/deployment.yaml:14` replicas=1
- `services/analysis/api-deployment.yaml:13` replicas=1
**Vấn đề**: Eviction = instant outage, no drain.
**Fix**: 
- `replicas: 2` cho critical (identity, project, analysis-api)
- Add `PodDisruptionBudget` `minAvailable: 1` cho all.

### E3. 🔴 HIGH — HPA chỉ có cho analysis-consumer
**File**: `smap-deploy/services/analysis/hpa.yaml` (existing) + missing cho rest
**Vấn đề**: analysis-api, identity, notification, ingest, project, knowledge — không HPA. Load tăng → single pod saturate (khớp benchmark 50 user → tail 7.8s).
**Fix**: HPA per service, target CPU 70% + custom metric (RabbitMQ queue depth, Kafka consumer lag).

### E4. 🔴 HIGH — Resource request 10m vs limit 500m (50× gap)
**File**: 
- `services/identity/deployment.yaml:89-95`
- `services/ingest/deployment.yaml:99-101`
- `services/notification/deployment.yaml:89-95`
- `services/project/deployment.yaml:89-95`
**Vấn đề**: Burstable QoS với request quá thấp → scheduler over-pack node → thrash khi load.
**Fix**: Tăng request lên 100-200m, limit 2× request.

### E5. 🟡 MED — `imagePullPolicy: IfNotPresent` ở services có tag reuse risk
**File**: `services/identity/deployment.yaml:63`, `services/ingest/deployment.yaml:69`
**Vấn đề**: Nếu tag reuse (rare nhưng possible), stale image bị cache.
**Fix**: `imagePullPolicy: Always` HOẶC đảm bảo tag immutable SHA.

### E6. 🟡 MED — ConfigMap update không trigger rollout
**File**: Tất cả `configmap.yaml` + `deployment.yaml`
**Vấn đề**: `envFrom: configMapRef:` không hash annotation. Config edit → pod không restart.
**Fix**: Kustomize `configMapGenerator` (auto hash suffix) hoặc Reloader operator.

### E7. 🟡 MED — analysis-consumer probe = exec file check
**File**: `services/analysis/deployment.yaml:108-137`
**Vấn đề**: `test -f /tmp/healthy` — nếu app hang nhưng file tồn tại → ready=true (sai).
**Fix**: HTTP `/healthz` từ in-process server.

### E8. 🟡 MED — smap-portal probe quá aggressive
**File**: `services/portal/deployment.yaml:37-60`
**Vấn đề**: `initialDelay=1s, timeout=1s, period=10s`, NO startup probe. Cold start fail → CrashLoopBackOff.
**Fix**: Add startup probe `failureThreshold: 30, periodSeconds: 5`.

---

## F. Knowledge-srv RAG pipeline

### F1. 🔴 CRITICAL — Campaign RBAC bypass (cross-user leak)
**File**: 
- `knowledge-srv/internal/search/usecase/helpers.go:16-48`
- `knowledge-srv/internal/search/delivery/http/process_request.go:17-18`
- `pkg/projectsrv/projectsrv.go:20-44`
**Vấn đề**: `resolveCampaignProjects()` gọi `GetCampaign(ctx, campaignID)` KHÔNG check `sc.UserID`. User A biết campaign_id của User B → search/chat được.
**Fix**: 
- Inject `user_id` vào `GetCampaign` call, validate ownership.
- Hoặc thêm middleware ở `process_request.go` check campaign membership trước khi vào usecase.

### F2. 🔴 HIGH — Kafka consumer silent drop on error
**File**: `knowledge-srv/internal/indexing/delivery/kafka/consumer/handler.go:23-24,59-60,98-99`
**Vấn đề**: JSON parse error / validation fail → `continue` + `MarkMessage` → msg mất.
**Fix**: 
- Implement DLQ topic `knowledge.indexing.dlq`.
- Bad msg → produce sang DLQ + log + MarkMessage.
- Transient error (DB timeout, Qdrant down) → return error, retry với backoff (sarama-cluster `Mark` only on success).

### F3. 🔴 HIGH — Pre-embed dedup race
**File**: `knowledge-srv/internal/indexing/usecase/index_batch.go:138-164`
**Vấn đề**: 2 concurrent msg same `analytics_id`:
1. Both check DB → miss
2. Both call Voyage (×2 cost)
3. Both upsert Qdrant (duplicate point)
4. First DB insert OK, second UNIQUE conflict (silent skip)
→ Qdrant duplicate, Postgres single.
**Fix**: 
- `INSERT ... ON CONFLICT DO NOTHING RETURNING id` trước embed
- Hoặc Redis `SETNX dedupe_key analytics_id EX 60` lock trước embed.

### F4. 🟡 MED — Qdrant upsert async (no wait=true)
**File**: `knowledge-srv/pkg/qdrant/qdrant.go:165,209`
**Vấn đề**: `pb.UpsertPoints` không set `Wait: true`. Newly indexed doc không tìm thấy ngay → demo UC-03 search vừa index xong sẽ miss.
**Fix**: `Wait: &wrapperspb.BoolValue{Value: true}` cho batch index.

### F5. 🟡 MED — Voyage rate-limit silent skip
**File**: `pkg/voyage/voyage.go:11-46`
**Vấn đề**: 429 → embed fail → doc skip, không retry.
**Fix**: Exponential backoff với jitter, max 3 retry, sau cùng → DLQ.

### F6. 🟡 MED — Per-doc embed (no batch)
**File**: `knowledge-srv/internal/embedding/usecase/generate.go:27`
**Vấn đề**: `voyage.Embed(ctx, []string{input.Text})` — 1 input/call. Concurrency=10 → 10 API call thay vì 1 batch.
**Fix**: Buffer 64 input → batch embed call → distribute kết quả.

### F7. 🟡 MED — Qdrant payload full text (64MB risk)
**File**: `knowledge-srv/internal/indexing/usecase/index_batch.go:226`
**Vấn đề**: `Content: cleanText` trong payload. Qdrant 64MB point limit.
**Fix**: Payload chỉ ref `analytics_id`. Content fetch từ Postgres khi cần.

### F8. 🟡 MED — No Qdrant collection cleanup on project archive
**Vấn đề**: Project archive/delete → Qdrant points orphan vĩnh viễn.
**Fix**: Lifecycle hook trong project-srv → publish `project.archived` event → knowledge-srv subscriber gọi `qdrant.DeletePoints(filter: project_id=X)`.

### F9. 🟢 LOW — Chat không streaming
**File**: `knowledge-srv/internal/chat/usecase/chat.go:176`
**Vấn đề**: `llm.Generate()` blocking 30s+, user thấy blank.
**Fix**: SSE/WS stream từ Gemini streaming API.

### F10. 🟢 LOW — Conversation không TTL
**File**: `knowledge-srv/migrations/005_create_conversations_table.sql`
**Fix**: Archive after 90d, soft-delete after 365d. Cron job.

---

## TÓM TẮT TỔNG QUAN

| Layer | Critical | High | Med | Low | Tổng |
|---|---|---|---|---|---|
| Gốc (Tài flag) | 2 | 0 | 0 | 0 | 2 |
| A. DB | 0 | 2 | 2 | 1 | 5 |
| B. Broker+Cache | 3 | 2 | 5 | 0 | 10 |
| C. External deps | 0 | 3 | 4 | 1 | 8 |
| D. Web-UI | 0 | 4 | 4 | 0 | 8 |
| E. K8s | 1 | 3 | 4 | 0 | 8 |
| F. RAG (knowledge) | 1 | 2 | 5 | 2 | 10 |
| **TỔNG** | **7** | **16** | **24** | **4** | **51** |

---

## ROADMAP — Đề xuất thứ tự fix

### Sprint 1 (1 tuần) — Đập hết CRITICAL
1. C3 Ontology TTL (30min) — quick win
2. C4 Kafka idempotent (1h)
3. C7 Ingress timeout chain (1h)
4. C6 Campaign RBAC (4h) — security
5. C1 Per-project DRR (1d) — fix TTFD
6. C2 JSON index + semaphore 16 (1d) — fix Insight latency
7. C5 Redis Streams thay PubSub (3d) — notification reliability

### Sprint 2 (1 tuần) — HIGH
- A1/A2: Wire pool config + statement_timeout Go
- B4/B5/B6: Kafka acks, ontology invalidation, knowledge dedup
- C1/C2/C3: HTTP timeout chain
- D1: Lazy-load smap/page.tsx tab
- E2/E3: replicas=2 + HPA cho critical services

### Sprint 3 (2 tuần) — MED/LOW + Pre-aggregation
- `kpi_daily` rollup table (C2 fix #3) — biggest p95 gain
- RAG cleanup + dedup races
- Web-UI memo + ErrorBoundary

### Reject
- ❌ Rewrite analysis-srv sang Go (8w, 30% gain) — ROI tệ
- ❌ Service mesh (Linkerd/Istio) — premature cho thesis scope

---

## Evidence path

Benchmark: `report/benchmark/reports/20260520-204400/benchmark-report.md`
TTFD: `report/documents/docs/indexing-time-to-first-data-benchmark.md`
Stability: `report/SMAP_STABILITY_FIX_REPORT.md`
Use cases: `report/final-report/chapter_4/section_4_4.typ`, `section_4_5.typ`

---

*Generated by 6 parallel investigators on 2026-06-06. Audit read-only, no edits applied.*
