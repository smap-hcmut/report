# SMAP Workspace Index

Updated: 2026-06-05

Workspace: `/Users/ts.1126/Workspaces/smap`

Purpose: quick operational index for the SMAP graduation-project workspace. This file maps the service repos, official report/use-case sources, homelab deployment repo, Kubernetes context, live cluster snapshot, and the main contracts needed before taking complex tasks.

## Scope read in this pass

Target repos pulled and indexed:

| Repo | Branch | Current commit | Role |
|---|---|---:|---|
| `analysis-srv` | `master` | `5482ffe` | Analytics API and consumer, NLP pipeline, post insights, dashboard analytics |
| `identity-srv` | `master` | `7a60d8d` | OAuth2, JWT, RBAC, sessions, audit logs |
| `ingest-srv` | `master` | `d424afb` | Datasources, crawl targets, dry-run, UAP publishing, crawler dispatch |
| `knowledge-srv` | `master` | `5cc8e1e` | RAG, vector indexing, semantic search, chat, report generation |
| `notification-srv` | `master` | `f886ed0` | WebSocket realtime updates, Redis Pub/Sub bridge, Discord alerts |
| `project-srv` | `master` | `0001309` | Campaign/project control plane, lifecycle orchestration, crisis and ontology config |
| `scapper-srv` | `main` | `e53ef04` | Python crawler worker/API for TikTok/Facebook/YouTube tasks |
| `report` | `master` | `c9252ef` | Official report, use cases, diagrams, slides, evaluation evidence |
| `smap-deploy` | `main` | `77a646b` | Homelab Kubernetes manifests, NFR evidence, deploy runbooks |

Other top-level repos present but not deep-read in this pass:

| Path | Likely role |
|---|---|
| `web-ui` | Next.js dashboard/UI |
| `shared-libs` | Shared Go/Python libraries, auth middleware/contracts |

## System mental model

SMAP is a Social Media Analytics Platform for marketing analysts. The current architecture is microservice-oriented and event-driven.

Main flow:

```text
Web UI
  -> identity-srv for OAuth2/JWT/RBAC
  -> project-srv for campaigns/projects/config/lifecycle
  -> ingest-srv for datasources, dry-runs, crawl target dispatch
  -> scapper-srv through RabbitMQ for social crawl execution
  -> MinIO/raw batches and UAP records
  -> Kafka/Redpanda topic smap.collector.output
  -> analysis-srv consumer for normalization, dedup, spam, threads, NLP, enrichment, reporting, crisis assessment
  -> PostgreSQL schema_analysis.post_insight and analytics Kafka topics
  -> knowledge-srv indexes valuable analytics into Qdrant and serves search/chat/report generation
  -> notification-srv pushes realtime progress/alerts to browser and Discord
```

Core domain entities:

| Layer | Main entities | Owning service |
|---|---|---|
| Identity | User, session, JWT, roles, audit logs | `identity-srv` |
| Business control plane | Campaign, project, project lifecycle, crisis config, ontology rules | `project-srv` |
| Ingest plane | Data source, crawl target, dry-run, external task, raw batch, UAP | `ingest-srv` |
| Crawler runtime | Task queue, platform handler, crawl result | `scapper-srv` |
| Analytics | Mention/post insight, NLP fact, reporting bundle, crisis assessment | `analysis-srv` |
| Knowledge/RAG | Indexed document, Qdrant point, conversation, generated report | `knowledge-srv` |
| Realtime | WebSocket connection, notification event, alert dispatch | `notification-srv` |

## Official report and use-case sources

Use `report` as the official thesis/report source, not as implementation truth when it conflicts with current code.

Important paths:

| Path | Use |
|---|---|
| `report/final-report/main.typ` | Main Typst report entrypoint |
| `report/final-report/chapter_*` | Final report chapters |
| `report/documents/docs/api-endpoints.md` | Public API reference by service prefix |
| `report/documents/docs/dataflow-detailed.md` | Component-level dataflow and UAP model |
| `report/documents/docs/migration-plan.md` | Original architecture/migration plan |
| `report/documents/docs/indexing-time-to-first-data-benchmark.md` | Benchmark TTFD (campaign/project start → first data) with SQL + recommendations |
| `report/documents/presentation/slides` | Defense slide content |
| `report/documents/presentation/evaluation` | Evaluation/unit-test/NFR presentation material |
| `report/documents/barem.md` | HCMUT grading rubric |

Main official use cases from presentation material:

| UC | Name | Summary |
|---|---|---|
| UC1 | Cấu hình Project | Create project, configure keywords/platforms |
| UC2 | Dry-run từ khóa | Estimate/test keyword results before real execution |
| UC3 | Execute Project | Start data collection and processing |
| UC4 | Xem kết quả phân tích | Dashboard sentiment, aspects, trends, posts |
| UC5 | Quản lý danh sách Projects | List/filter/search/archive projects |
| UC6 | Xuất báo cáo | Export/generate PDF/PPTX/Excel-style outputs |
| UC7 | Phát hiện xu hướng tự động | Trend/crisis/alert detection |
| UC8 | Realtime Progress Tracking | Follow progress through WebSocket |

Known report caveat: some report docs still mention older names like Collector/WebSocket/MongoDB. Current code/deploy uses `ingest-srv`, `scapper-srv`, `notification-srv`, Redpanda/Kafka, PostgreSQL schemas, MinIO, Redis, Qdrant. For implementation tasks, prefer current repo README/routes/migrations over old report wording.

## Service map

### `analysis-srv`

Role: event-driven Python analytics engine and dashboard analytics API.

Key paths:

| Path | Use |
|---|---|
| `apps/api/main.py` | FastAPI analytics HTTP API |
| `apps/consumer/main.py` | Kafka consumer entrypoint |
| `internal/pipeline` | Multi-stage analytics pipeline |
| `internal/analytics/usecase` | NLP batch enrichment |
| `internal/http/analytics_service.py` | Dashboard query service |
| `internal/post_insight` | PostgreSQL persistence for insights |
| `internal/ontology` | Runtime ontology/user rules |
| `internal/crisis` | Crisis assessment |
| `config/domains`, `config/ontology` | Domain and ontology YAML configs |
| `migration` | SQL migrations for analytics schema |

Primary behavior:

| Area | Notes |
|---|---|
| Input | Consumes UAP from `smap.collector.output` |
| Pipeline | normalization, dedup, spam, thread topology, NLP, enrichment, review, reporting, crisis |
| Output | Writes `schema_analysis.post_insight`, publishes `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest` |
| HTTP API | `/health`, `/ready`, `/api/v1/analytics/kpis`, `/platforms`, `/sentiment`, `/keywords`, `/posts`, `/posts/export`, `/project-stats`, `/heap`, `/api/v1/internal/analytics/hidden-crawl-targets` |

Recent pull highlights:

| Area | Change |
|---|---|
| API | `apps/api/main.py` and `internal/http/analytics_service.py` expanded heavily |
| Domains | New `kotex_goodnight`, `tanca`, HRM/CRM, marketing ontology configs |
| DB | New migrations `006_posts_filter_dedupe_index`, `007_latest_post_insight_mart`, `008_hidden_crawl_targets` |
| Integration | Project client and hidden crawl targets support |
| Quality | New tests for sentiment labels, hidden crawl target, posts export, relevance |

### `identity-srv`

Role: central authentication and authorization service.

Key paths:

| Path | Use |
|---|---|
| `cmd/server/main.go` | Gin API server entrypoint |
| `internal/authentication` | OAuth2/JWT/session/blacklist logic |
| `internal/audit` | Audit log domain |
| `internal/httpserver` | Route wiring and health checks |
| `config` | Viper config and access-control roles |
| `migration` | `schema_identity` migrations |
| `documents/auth-service-integration.md` | Integration guide for other services |

Primary behavior:

| Area | Notes |
|---|---|
| Auth | Google OAuth2, JWT HS256, HttpOnly cookie in production, Bearer fallback in development |
| Authz | ADMIN, ANALYST, VIEWER roles; email-to-role mapping in config |
| Session | Redis-backed sessions and token blacklist |
| Audit | Writes audit logs to PostgreSQL, Kafka only for async audit consumer |
| API | `/authentication/login`, `/callback`, `/logout`, `/me`, `/authentication/internal/validate`, `/revoke-token`, `/users/:id`, `/audit-logs`, `/health`, `/ready`, `/live` |

Recent pull highlights: access-control role config and config tests were added/updated.

### `ingest-srv`

Role: ingest control plane between project configuration and crawler/analytics runtime.

Key paths:

| Path | Use |
|---|---|
| `cmd/server/main.go` | Gin API server |
| `internal/datasource` | Data source and crawl target lifecycle |
| `internal/dryrun` | Keyword/source dry-run |
| `internal/execution` | Internal dispatch into crawler runtime |
| `internal/uap` | UAP mapping/spec implementation |
| `internal/consumer` | Runtime consumer wiring |
| `pkg/microservice/project` | Project service client |
| `documents/resource/input-output/UAP_SPECIFICATION_VNEXT.md` | Canonical UAP details |

Primary behavior:

| Area | Notes |
|---|---|
| Owns | `data_sources`, `crawl_targets`, `external_tasks`, `raw_batches`, lineage and UAP output |
| Does not own | `projects`, `campaigns`, crisis policy, final business project state |
| Dispatch | Publishes crawler tasks through RabbitMQ |
| Analytics integration | Publishes normalized UAP to downstream analytics |
| APIs | `/datasources`, `/datasources/:id/targets/*`, dry-run endpoints, `/internal/projects/:project_id/activate|pause|resume|crawl-mode`, `/internal/datasources/:id/targets/:target_id/dispatch` |

Recent pull highlights:

| Area | Change |
|---|---|
| Runtime | Fail fast when ingest runtime dependencies are unavailable |
| Data control | Analytics exclusions, target visibility, hidden-target flow |
| UAP | Attribution/usecase changes |
| API | Data source and execution handlers expanded |

### `project-srv`

Role: business orchestration brain for campaigns/projects and runtime policy.

Key paths:

| Path | Use |
|---|---|
| `cmd/server/main.go` | Gin API server |
| `internal/campaign` | Campaign CRUD/favorites/lifecycle |
| `internal/project` | Project CRUD, activation, pause/resume/archive |
| `internal/crisis` | Project crisis config and runtime application |
| `internal/ontology` | Project-level ontology rules |
| `pkg/microservice/ingest` | Ingest service client |
| `documents/service_interactions.md` | Service interaction notes |
| `documents/crisis-config-mapping.md` | Crisis config mapping |

Primary behavior:

| Area | Notes |
|---|---|
| Campaign API | `/campaigns`, `/campaigns/:id`, favorites, pause/resume/archive |
| Project API | `/campaigns/:id/projects`, `/projects/:project_id`, activation-readiness, activate, pause, resume, archive, favorite |
| Runtime config | `/projects/:project_id/crisis-config`, `/projects/:project_id/ontology-rules` |
| Internal API | `/internal/projects/:project_id`, runtime crisis/ontology endpoints |
| Integration | Calls `ingest-srv` to activate/pause/resume ingest state and dispatch work |

Recent pull highlights: ontology rules domain, crisis config response policy, crisis mapping docs, Redis ontology repository, and new migration for crisis watch response policy.

### `scapper-srv`

Role: Python crawler worker/API that executes platform-specific crawl tasks.

Key paths:

| Path | Use |
|---|---|
| `app/main.py` | FastAPI app, health/live/ready |
| `app/router.py` | Task API |
| `app/worker.py` | RabbitMQ worker runtime |
| `app/handlers/facebook.py` | Facebook handlers |
| `app/handlers/tiktok.py` | TikTok handlers |
| `app/handlers/youtube.py` | YouTube handlers |
| `app/config.py` | Runtime config |

Primary behavior:

| Area | Notes |
|---|---|
| API | `/api/v1/tasks/{platform}`, `/api/v1/tasks/{task_id}/result`, `/api/v1/tasks`, `/health`, `/live`, `/ready` |
| Queue | RabbitMQ task ingestion |
| Storage | MinIO for crawl artifacts/result payloads |
| Platforms | TikTok, Facebook, YouTube handlers |

Recent pull highlights: hardened worker runtime, logging config, Facebook GraphQL/v2 flows, TikTok focused-profile/full-flow handling.

### `knowledge-srv`

Role: RAG/search/report service over analytics outputs.

Key paths:

| Path | Use |
|---|---|
| `cmd/server/main.go` | Gin API server |
| `internal/indexing` | Kafka consumer and vector indexing |
| `internal/search` | Semantic search |
| `internal/chat` | RAG chat/Q&A |
| `internal/report` | Report generation/list/content/download |
| `internal/contentquality` | Content quality scoring |
| `pkg/analytics` | Analysis API client |
| `pkg/qdrant`, `pkg/voyage` | Vector DB and embedding integration |
| `documents/master-proposal.md` | Domain proposal |

Primary behavior:

| Area | Notes |
|---|---|
| Indexing input | `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest` |
| Vector DB | Qdrant collections, campaign/project scoped |
| AI | Voyage embeddings, Gemini generation according to docs/config |
| APIs | `/knowledge/search`, `/knowledge/reports`, `/knowledge/reports/generate`, report content/download/process/posts/comments, `/internal/index`, `/internal/index/retry`, `/internal/index/reconcile`, `/internal/index/statistics/:project_id` |

Recent pull highlights: analytics fallback for chat, business report runtime/generator, content quality, analytics client package, report APIs expanded.

### `notification-srv`

Role: realtime notification hub and critical alert dispatcher.

Key paths:

| Path | Use |
|---|---|
| `cmd/server/main.go` | Gin server entrypoint |
| `internal/websocket` | WebSocket domain and hub |
| `internal/alert` | Discord/business alert dispatch |
| `internal/analyticsbridge` | Analytics bridge |
| `internal/httpserver` | Route wiring and health |

Primary behavior:

| Area | Notes |
|---|---|
| WebSocket | Service receives `/ws` after Traefik strips `/notification`; browser calls `/notification/ws` |
| Auth | JWT from query token or cookie due browser WebSocket header limitation |
| Broker | Redis Pub/Sub subscriber |
| Alerting | Discord webhook dispatch |
| Health | `/health`, `/ready`, `/live` |

Recent pull highlights: analytics bridge improvements, request logger, WebSocket transport updates, degraded startup when Redis connection fails.

## API prefix quick map

Docs expect public API under `https://smap-api.tantai.dev` with path prefixes stripped before services.

| Public prefix | Service | Internal base |
|---|---|---|
| `/identity` | `identity-srv` | identity API |
| `/project` | `project-srv` | `/api/v1` |
| `/ingest` | `ingest-srv` | `/api/v1` |
| `/knowledge` | `knowledge-srv` | `/api/v1/knowledge` |
| `/notification` | `notification-srv` | `/ws` for WebSocket after strip |
| `/scraper` | `scapper-srv` | `/api/v1` |
| `/analytics` | `analysis-api` | `/api/v1/analytics` |

Current live caveat: standard Kubernetes `Ingress` and Traefik `IngressRoute` queries in the homelab cluster only showed `smap.tantai.dev` and `smap-portal.tantai.dev`, not `smap-api.tantai.dev`. If debugging public API routing, inspect external proxy/Traefik configuration outside standard Ingress resources.

## Deploy and homelab index

Repo: `smap-deploy`

Important paths:

| Path | Use |
|---|---|
| `single-source-of-truth.md` | Primary deploy/ops source of truth |
| `base` | Namespace, infra configmaps, registry secret, shared secret manifests |
| `infrastructure/redis` | Redis StatefulSet/service/PDB |
| `infrastructure/rabbitmq` | RabbitMQ StatefulSet/service/PDB |
| `infrastructure/redpanda` | Redpanda/console manifests |
| `services/*` | Service deployments/configmaps/secrets |
| `devops/logging` | Central/node logging |
| `nfr` | NFR evidence kit, runbooks, scripts |
| `portal` | Internal portal |
| `ui-test` | UI test fixtures/tests |

Do not paste or expose values from `base/secrets` or `services/*/secret.yaml`. Some manifests contain base64-encoded secret material.

Kubernetes context snapshot:

| Context | Cluster | User | Namespace |
|---|---|---|---|
| `homelab` | `homelab` | `homelab` | default/not set in context |
| `smap-log` | `homelab` | `smap-log` | `smap` |

Current `kubectl config get-contexts` showed `homelab` as active.

Suggested k9s entrypoint:

```bash
k9s --context homelab -n smap
```

Live cluster snapshot from `kubectl --context homelab get pods,deploy,sts,hpa,svc,ingress -n smap`:

| Component | Current live state |
|---|---|
| `analysis-api` | `1/1` Running |
| `analysis-consumer` | deployment `1/2` available; one pod Running and one pod `CrashLoopBackOff`; HPA reports CPU `108%/70%`, replicas `2`, max `3` |
| `identity-srv` | `1/1` Running |
| `ingest-srv` | `1/1` Running |
| `knowledge-srv` | `1/1` Running |
| `notification-srv` | `1/1` Running |
| `project-srv` | `1/1` Running |
| `scapper-srv` | `1/1` Running |
| `rabbitmq` | StatefulSet `1/1`, pod Running |
| `redis` | StatefulSet `0/1`, pod `ContainerCreating` |
| `redpanda` | StatefulSet `1/1`, pod Running |
| `smap-ui` | `1/1` Running |
| `smap-portal` | `1/1` Running |
| `smap-central-log`, `smap-node-log` | Running |

Live ingress snapshot:

| Host | Namespace | Resource |
|---|---|---|
| `smap.tantai.dev` | `smap` | standard Ingress `smap-ui` |
| `smap-portal.tantai.dev` | `smap` | standard Ingress `smap-portal` |
| `rancher.tantai.dev` | `cattle-system` | standard Ingress |
| `longhorn.tantai.dev` | `longhorn-system` | standard Ingress |

Operational commands from deploy docs:

```bash
kubectl --context homelab get pods -n smap
kubectl --context homelab get deploy -n smap
kubectl --context homelab get service -n smap
kubectl --context homelab get ingress -A
kubectl --context homelab rollout status deploy/analysis-api -n smap
kubectl --context homelab rollout status deploy/ingest-srv -n smap
kubectl --context homelab rollout status deploy/project-srv -n smap
kubectl --context homelab rollout status deploy/smap-ui -n smap
```

## NFR and benchmark evidence

Primary NFR folder: `smap-deploy/nfr`

Evidence kit rules:

| Artifact | Purpose |
|---|---|
| `run-info.json` | Scenario, timestamp, duration, image/commit metadata |
| `environment.md` | Cluster/environment snapshot |
| `scenario-plan.md` | Pass criteria and workload plan |
| `summary.md` | p50/p95/p99, throughput, timeout/error |
| `conclusion.md` | Accept/partial/reject and next actions |
| `raw/cluster`, `raw/queues`, `raw/db`, `raw/metrics` | Proof for report claims |

Latest report-ready benchmark read:

| Run | Result |
|---|---|
| `smap-deploy/nfr/artifacts/20260517_real_benchmark_01` | Read-only production benchmark over live SMAP deployment |

Key numbers from `report-ready-benchmark.md`:

| Metric | Value |
|---|---:|
| Samples | `4286` |
| Overall p50/p95/p99 | `101.717 / 190.197 / 727.142 ms` |
| Overall infra error | `5.483%` |
| Analytics p95 | `192.162 ms`, `0.0%` infra error |
| UI p95 | `181.748 ms`, `0.0%` infra error |
| Observed live mentions | `6.7K` |
| Observed engagement | `10.9K` |

Benchmark caveat: the 2026-05-17 report marked full-system result as partial because RabbitMQ was unavailable and `scapper-srv` was not ready at that time. Live snapshot on 2026-06-05 now shows RabbitMQ and `scapper-srv` Running, but Redis is currently not Ready and `analysis-consumer` has a CrashLooping replica. Do not reuse the old crawler-lane failure as current truth without a fresh run.

Long-window NFR baseline from the same evidence package:

| Scenario | Duration | Throughput | p50/p95/p99 | Timeout | Infra error |
|---|---:|---:|---:|---:|---:|
| Baseline | 20 min | `6.949 req/s` | `41.652 / 159.397 / 357.020 ms` | `0.0360%` | `0.0000%` |
| Expected load | 20 min | `7.265 req/s` | `41.760 / 171.699 / 285.326 ms` | `0.0000%` | `0.0000%` |
| Peak load | 20 min | `7.440 req/s` | `40.992 / 220.387 / 433.074 ms` | `0.0000%` | `0.0000%` |
| Chaos consumer restart | 12 min | `7.751 req/s` | `41.228 / 224.661 / 324.243 ms` | `0.0000%` | `0.0000%` |

Missing/weak NFR evidence called out by current docs:

| Gap | Impact |
|---|---|
| Fresh 4-8 hour soak | Cannot claim long-running stability for latest deploy |
| Saturation threshold test | Cannot state hard capacity limit |
| Full queue drain/MTTR proof | Async reliability claims remain partial |
| DB duplicate/loss/orphan audit for latest deployment | Data integrity claims need fresh proof |
| NLP semantic quality local benchmark missing PhoBERT artifact | Need run inside analysis image or provide model artifact |

## Contracts and topics

Canonical payload: UAP, with required business time `content_created_at` and system time `ingested_at`.

Important topics/events:

| Topic/event | Producer | Consumer |
|---|---|---|
| `smap.collector.output` | Ingest/crawler pipeline | `analysis-srv` |
| `analytics.batch.completed` | `analysis-srv` | `knowledge-srv` |
| `analytics.insights.published` | `analysis-srv` | `knowledge-srv`, possibly notification/report flows |
| `analytics.report.digest` | `analysis-srv` | `knowledge-srv` |
| Redis Pub/Sub notification channels | Backend services | `notification-srv` |
| RabbitMQ task queues | `ingest-srv` | `scapper-srv` |

## Current risk list for future tasks

| Risk | What to check first |
|---|---|
| Live `analysis-consumer` instability | `kubectl --context homelab logs deploy/analysis-consumer -n smap --tail=200` and pod events |
| Live `redis` not Ready | StatefulSet events, PVC/Longhorn attachment, pod describe |
| Public API route ambiguity | Traefik/external proxy config because standard Ingress/IngressRoute does not list `smap-api.tantai.dev` |
| Report/docs drift | Confirm against current service routes and migrations before editing final report |
| Secrets in manifests | Avoid printing secret values; rotate if accidentally exposed |
| Benchmark claims stale | Re-run NFR before making latest performance/reliability claims |

## How to approach complex tasks

For service-code tasks:

| Task type | Read first |
|---|---|
| API behavior | `internal/*/delivery/http/routes.go`, handlers, presenters, process_request |
| Business logic | `internal/*/usecase` |
| Persistence | `internal/*/repository`, `internal/sqlboiler`, migrations |
| Inter-service bugs | `pkg/microservice/*`, configmap env in `smap-deploy/services/*` |
| Analytics dashboard bugs | `analysis-srv/apps/api/main.py`, `analysis-srv/internal/http/analytics_service.py` |
| Report generation bugs | `knowledge-srv/internal/report`, `pkg/analytics`, `analysis-srv` APIs |
| Crawl/runtime bugs | `ingest-srv/internal/execution`, `scapper-srv/app/worker.py`, RabbitMQ manifests |

For deployment tasks:

| Task type | Read first |
|---|---|
| Desired state | `smap-deploy/single-source-of-truth.md` and matching service manifest |
| Live state | `kubectl --context homelab get pods,deploy,sts,hpa,svc,ingress -n smap` |
| Service config | `smap-deploy/services/<service>/configmap.yaml` and non-secret key names in `secret.yaml` |
| Infra failures | `infrastructure/redis`, `infrastructure/rabbitmq`, `infrastructure/redpanda`, Longhorn events |
| NFR/report claims | `smap-deploy/nfr/artifacts/*/summary.md`, `conclusion.md`, raw evidence |

For report/thesis tasks:

| Task type | Read first |
|---|---|
| Final Typst edits | `report/final-report/main.typ`, relevant `chapter_*` section |
| API documentation | `report/documents/docs/api-endpoints.md` plus current route files |
| Architecture/dataflow | `report/documents/docs/dataflow-detailed.md`, `smap-deploy/single-source-of-truth.md` |
| Use cases/slides | `report/documents/presentation/slides` |
| Evaluation/NFR | `report/documents/presentation/evaluation`, `smap-deploy/nfr` |

No tests or builds were run during this indexing pass.
