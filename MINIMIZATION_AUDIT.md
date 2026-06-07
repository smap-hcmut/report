# SMAP Minimization Audit — v3 (sau verify pass)

Ngày: 2026-06-06
Tác giả: Ngộ Không (AI agent) cho Tài
Phạm vi: Toàn bộ workspace `smap/` (9 repos, đã pull latest)
Nguồn UC chính thức: `report/final-report/chapter_4/section_4_1..5.typ`

## 0a. Thay đổi v2 → v3 (sau verify pass)

| Item | v2 nói | v3 fix |
|---|---|---|
| identity-srv `internal/audit/` | UNSURE | **DROP** — verify: Kafka topic `audit.events` zero producer (skeleton code), web-ui không gọi, ingress không expose, OAuth login KHÔNG ghi audit synchronously → orphan thật. |
| scapper-srv `router.py` | DROP | **DROP confirm** — verify: ingress smap-deploy KHÔNG có route `/scraper`, zero HTTP caller. Drop safe. |
| web-ui `/onboarding` | DROP | **KEEP** — verify: `auth/signup/page.tsx:49` push tới, `CampaignSwitcher.tsx` push tới (button "Create new campaign"). Gọi 7+ API tạo campaign/project/datasource. CRITICAL flow. |
| web-ui `/campaigns` redirect | DROP | **KEEP** — verify: `auth/callback/page.tsx`, `auth/login/page.tsx`, `settings/layout.tsx` đều redirect về `/campaigns` → `/smap`. Auth exit point. |
| web-ui `/smap/processing` | DROP | **DROP confirm** — orphan, không reach từ bất kỳ flow nào. Onboarding push trực tiếp `/smap?camp_id=`. |
| web-ui `/showcase`, `/auth/forgot-password` | DROP | **DROP confirm** — zero referrer, forgot-password chỉ mock setTimeout. |
| shared-libs Python toàn bộ | DROP | **DROP confirm** — 0 importer, no Dockerfile/pyproject.toml reference. analysis-srv tự implement local `pkg/logger`, `pkg/kafka`, `pkg/redis`, `pkg/postgre`. |
| shared-libs Go `locale`/`gemini`/`database`/`compressor` | DROP | **DROP confirm** — 0 importer, không có `go.mod replace` của ai. |

## 0b. Thay đổi v1 → v2 (sau review của Tài)

| # | Vấn đề | v1 nói | v2 fix |
|---|---|---|---|
| 2.1 | UAP integrity (ingest-srv attribution + analytics_exclusions + target_visibility + hidden_crawl_targets) | Đề xuất DROP ~250 LoC | **KEEP TẤT CẢ** — verify cross-service: chúng nuôi UAP `platform_meta["smap"]` mà analysis-srv dùng để filter hidden/flushed targets. Drop = data leak. |
| 2.2 | Report subsystem (knowledge-srv `internal/report` + analysis-srv `build_bi_reports.py` + web-ui `reports/` + topic `analytics.report.digest`) | Đề xuất DROP ~7K LoC | **KEEP TOÀN BỘ** — UC chính thức không nhắc, nhưng đây là missing trong report team mà Tài coi là quan trọng, giữ lại. |
| 2.3 | Ontology (project-srv ontology + redis repo + web-ui `ontology/` editor) | Đề xuất DROP ~600 LoC | **KEEP TOÀN BỘ** — Trace cross-service xác nhận 2-layer system: per-domain default + per-project overlay, analysis-srv consume qua HTTP. Tài hypothesis đúng. |

→ Net LoC dự kiến cắt giảm từ ~19K xuống còn ~10.9K. Trọng tâm dịch về `shared-libs` mồ côi và pages chết trong web-ui.

## 1. Mục tiêu (không đổi)

Đối chiếu toàn bộ source code với 5 UC + 12 FR. Giữ nếu thuộc UC/FR hoặc support layer (UAP, ontology, report). Drop nếu trace không tới được.

## 2. Map UC ↔ FR ↔ Service (cập nhật ghi chú support layer)

| UC | Tên | FR chính | Service chịu trách nhiệm |
|---|---|---|---|
| UC-01 | Thiết lập chiến dịch theo dõi | FR-02, FR-05, FR-06, FR-07 | `project-srv` (campaign/project) + `ingest-srv` (datasource/target/dry-run) |
| UC-02 | Vận hành chiến dịch | FR-03, FR-08 | `project-srv` (lifecycle) + `ingest-srv` (dispatch) + `scapper-srv` (crawl) |
| UC-03 | Tra cứu và hỏi đáp dữ liệu phân tích | FR-10 | `knowledge-srv` (search + RAG chat) + `analysis-srv` (analytics fallback) |
| UC-04 | Theo dõi trạng thái và nhận cảnh báo | FR-11 | `notification-srv` (WS + Redis + Discord) + `analysis-srv` (dashboard + crisis) |
| UC-05 | Quản lý quy tắc cảnh báo khủng hoảng | FR-04 | `project-srv` (crisis-config CRUD) |
| supporting | Xác thực | FR-01 | `identity-srv` (OAuth2/JWT) |
| supporting | Phân tích dữ liệu | FR-09 | `analysis-srv` (9-stage pipeline) + `knowledge-srv` (indexing) |
| supporting | Liên thông nội bộ | FR-12 | tất cả services có `/internal/*` |
| **support layer (ngoài UC chính thức nhưng KEEP)** | UAP integrity | — | `ingest-srv` (attribution, visibility, hidden_targets) + `analysis-srv` (filter expr) |
| **support layer** | Ontology dual-layer | — | `analysis-srv` (domain default + FileOntologyRegistry) + `project-srv` (Redis overlay) + web-ui `ontology/` |
| **support layer** | Report generation (missing trong UC report nhưng quan trọng) | — | `knowledge-srv/internal/report` + `analysis-srv/internal/reporting/build_bi_reports.py` + topic `analytics.report.digest` + `notification-srv` bridge digest + web-ui `reports/` |

## 3. UAP integrity chain — chi tiết (cần ghi nhớ)

```
ingest-srv/internal/uap/usecase/usecase.go:70,78
  → withIngestAttribution()  [attribution.go]
    → set platform_meta["smap"].{data_source_id, target_id, external_task_id, source_kind, keyword, page_id}
    → publish Kafka smap.collector.output

ingest-srv/internal/datasource/usecase/target.go (DeleteTarget)
  → analytics_exclusions.go.hideTargetFromAnalytics()
    → HTTP POST analysis-srv /api/v1/internal/analytics/hidden-crawl-targets
  → target_visibility.go.targetFlushedPlatformMeta()
    → set platform_meta["smap"].{visibility="flushed", deleted_at}

analysis-srv/internal/http/analytics_service.py:_hidden_target_filter_expr (~L296-305)
  → reads platform_meta["smap"].visibility != "flushed"
  → reads platform_meta["smap"].data_source_id, target_id
  → joins analysis.hidden_crawl_targets ON target_id
```

Drop bất kỳ mắt xích nào → deleted target leak vào dashboard analytics → user thấy data đã bị xoá. **MUST KEEP ALL.**

## 4. Ontology dual-layer — chi tiết (cần ghi nhớ)

```
[Layer 1 — domain default, immutable, load 1 lần startup]
analysis-srv/config/ontology/{entities,taxonomy,vinfast_vn,marketing_campaign_vn,...}.yaml
analysis-srv/config/domains/{_default,vinfast,ahamove,grab}.yaml
  → FileOntologyRegistry.from_yaml() [file_registry.py:79]
  → ConsumerRegistry.initialize() [server.py:212]
  → Pydantic-validated, in-memory

[Layer 2 — project overlay, dynamic, Redis]
project-srv/internal/ontology/repository/redis/rules.go
  key: smap:project:ontology-rules:{project_id}
  value: {project_id, enabled, rules[], updated_by, timestamps}
  ← UI editor: web-ui/src/components/ontology/OntologyRulesEditor
  ← HTTP: project-srv /projects/:id/ontology-rules (GET/PUT/POST/test/DELETE)

[Consumer wiring]
analysis-srv/internal/consumer/server.py
  _get_ontology_runtime_config(project_id)
    → analysis-srv/internal/http/project_client.py:108-142
    → HTTP GET project-srv /api/v1/internal/projects/{project_id}/ontology-rules
    → cache 60s, fallback to Layer 1 only if project-srv fail

analysis-srv/internal/enrichment/usecase/semantic_enricher.py:107-128
  SimplifiedSemanticInferenceEnricher.__init__(ontology_registry)
    → aspect_seed_phrases() / issue_seed_phrases() (Layer 1)
    → user_signal_rules("ASPECT"/"ISSUE"/"TOPIC") (Layer 2 overlay)
    → merged at batch time
```

Tài's hypothesis đúng: **default per-domain + per-project overlay loaded vào Redis**. KEEP toàn bộ chain.

## 5. Per-repo audit (revised)

### 5.1 `identity-srv`

| Path | Type | UC/FR | Verdict | LoC | Ghi chú |
|---|---|---|---|---|---|
| `internal/authentication/`, `internal/user/`, `internal/httpserver/`, `internal/sqlboiler/`, `migration/01_*.sql` | core | FR-01 | KEEP | ~6.3K | OAuth2 + JWT + session |
| `internal/audit/` | domain | — | **DROP** | ~742 | **v3 confirm DROP.** Topic `audit.events` zero producer, web-ui không gọi, ingress không expose. Skeleton code. |
| `internal/consumer/` | Kafka consumer | — | **DROP** | ~236 | Orphan: không route + không UC trace. Có thể là consumer của `audit.events` → drop kèm. |

**Dự kiến cắt identity-srv:** **~978 LoC** (consumer + audit domain + migration bảng `audit_logs` + Kafka topic).

### 5.2 `project-srv`

| Path | Type | UC/FR | Verdict | LoC | Ghi chú |
|---|---|---|---|---|---|
| Campaign + Project CRUD + lifecycle + crisis-config + internal | core | UC-01/02/05 + FR-12 | KEEP | — | |
| `GET /domains` | route | UC-01 | KEEP | — | |
| **Favorites** (6 endpoints: `POST/DELETE /campaigns/:id/favorite`, `GET /campaigns/favorites`, tương tự cho `/projects`) | route | — | **DROP** | ~150 | UC không nhắc. UI không hook (audit web-ui xác nhận `is_favorite` field thừa). |
| `internal/ontology/` (delivery/usecase/repository/redis) + 5 endpoints | domain | support (Layer 2 overlay) | **KEEP** | ~600 | **REVISED — KEEP**. Chain confirmed ở §4. |
| `internal/crisis/usecase/crisis_preset.go` | usecase | UC-05 | KEEP | — | |

**Dự kiến cắt project-srv:** ~150 LoC (favorites).

### 5.3 `ingest-srv` (REVISED — UAP safety pass)

| Path | Type | UC/FR | Verdict | LoC | Ghi chú |
|---|---|---|---|---|---|
| Datasource + Target CRUD/lifecycle, Dryrun, Execution, UAP parsers + Kafka publisher | core | UC-01/02 + FR-09 | KEEP | — | |
| `internal/uap/usecase/attribution.go` | UAP enrich | UAP support (cross-svc) | **KEEP** | ~74 | **REVISED — KEEP.** Ghi `platform_meta["smap"]`. Drop = data leak. |
| `internal/datasource/usecase/analytics_exclusions.go` | cross-svc call | UAP support | **KEEP** | ~60 | **REVISED — KEEP.** Push hidden target qua HTTP. |
| `internal/datasource/usecase/target_visibility.go` | metadata mark | UAP support | **KEEP** | ~31 | **REVISED — KEEP.** `visibility="flushed"` marker. |
| `hidden_crawl_targets` entity | model | UAP support | **KEEP** | — | **REVISED — KEEP.** |
| `internal/datasource/usecase/datasource.go` Archive/Delete | logic | UC-02 (operational) | UNSURE | ~60 | Archive cấp datasource: UC-02 không nhắc, nhưng operational cleanup hợp lý. Tài quyết. |
| `crawl_mode_changes`/`crawl_mode_defaults` entities | state machine | UC-02 internal | KEEP | — | Internal state, không user-facing nhưng nuôi lifecycle. |

**Dự kiến cắt ingest-srv:** **0 LoC** (toàn bộ UAP chain giữ). Archive datasource để Tài quyết.

### 5.4 `scapper-srv`

| Path | Type | FR | Verdict | LoC |
|---|---|---|---|---|
| `app/worker.py`, `handlers/*`, `publisher.py`, `main.py`, `config.py`, `schemas.py`, `logging_config.py` | core | FR-08 | KEEP | ~1626 |
| `app/router.py` HTTP `/api/v1/tasks/*` | route | — | **DROP** | 102 |

**Ghi chú:** router debug — ingest-srv không gọi, public ingress `/scraper` không phục vụ UC. Drop + xoá ingress prefix `/scraper` trong smap-deploy.

**Dự kiến cắt scapper-srv:** 102 LoC.

### 5.5 `analysis-srv`

| Path | Type | FR/UC | Verdict | Ghi chú |
|---|---|---|---|---|
| 9-stage pipeline (normalization, dedup, spam, threads, sentiment, intent, keyword, enrichment, review, impact, evaluation) | core | FR-09 | KEEP | |
| Pipeline runner, contract publisher, ingestion, post_insight, storage, outbox, builder, runtime, ontology, text_preprocessing | infra | FR-09 | KEEP | |
| Dashboard API (`/kpis`, `/platforms`, `/sentiment`, `/keywords`, `/posts`, `/project-stats`) | route | UC-04 | KEEP | |
| `internal/crisis/` assess | logic | UC-04 | KEEP | |
| `internal/reporting/build_bi_reports.py` (~1659 LoC) | logic | report support | **KEEP** | **REVISED.** Per Tài 2.2, giữ. Sinh `analytics.report.digest`. |
| `/internal/analytics/hidden-crawl-targets` endpoint | route | UAP support | **KEEP** | **REVISED.** Receive endpoint cho ingest-srv `hideTargetFromAnalytics`. |
| `apps/api/main.py` `/heap` | route | — | **DROP** | ~50 | Debug endpoint, không UC. |
| `apps/api/main.py` `/posts/export` (CSV/SVG) | route | report support | **KEEP** | **REVISED.** Export = report-related, giữ theo 2.2. |
| `config/domains/kotex_goodnight.yaml`, `tanca.yaml` | config | — | **UNSURE** | Sample HRM domains. Không support UC nào nhưng cũng không hại. Drop nếu Tài muốn sạch. |
| `config/ontology/hrm_crm_vn.yaml` | config | — | **UNSURE** | Đi kèm `tanca`. |

**Dự kiến cắt analysis-srv:** ~50 LoC (heap). 3 YAML để Tài quyết.

### 5.6 `knowledge-srv` (REVISED — report KEEP)

| Path | Type | UC/FR | Verdict | LoC |
|---|---|---|---|---|
| `internal/indexing/`, `internal/search/`, `internal/chat/`, `internal/point/`, `internal/embedding/`, `internal/contentquality/` | core | UC-03 + FR-09 | KEEP | ~10K |
| `pkg/analytics`, `pkg/qdrant`, `pkg/voyage`, `pkg/projectsrv` | libs | UC-03/FR-09 | KEEP | ~1451 |
| `internal/report/` (`/knowledge/reports` + business_report.go ~3788 LoC) | domain | report support | **KEEP** | ~3788 | **REVISED — KEEP** per Tài 2.2. |

**Dự kiến cắt knowledge-srv:** 0 LoC.

### 5.7 `notification-srv` (REVISED — analyticsbridge digest KEEP)

| Path | Type | UC/FR | Verdict | LoC |
|---|---|---|---|---|
| `internal/websocket/` (toàn bộ) | core | UC-04 | KEEP | ~1180 |
| `internal/alert/usecase/dispatch_{crisis,campaign,onboarding}.go` | dispatcher | UC-04/FR-11 | KEEP | ~162 |
| `internal/analyticsbridge/bridge.go` | bridge | report + UC-04 | **KEEP** | ~468 | **REVISED — KEEP.** Cần cho cả crisis alert lẫn report digest (Tài 2.2 keep report). |
| Infra (`httpserver`, `cmd`, `config`, `model`) | infra | UC-04 | KEEP | — |

**Dự kiến cắt notification-srv:** 0 LoC.

### 5.8 `shared-libs`

| Package | Lang | Importers | Verdict | LoC |
|---|---|---|---|---|
| log, response, errors, auth, kafka, middleware, redis, discord | Go | 5 | KEEP | ~5725 |
| encrypter, paginator, httpclient, constants | Go | 3–4 | KEEP | ~998 |
| postgres, tracing, minio, contracts | Go | 2 | KEEP | ~2445 |
| util, rabbitmq, llm, cron | Go | 1 | KEEP | ~1515 |
| **locale**, **gemini**, **database**, **compressor** | Go | 0 | **DROP** | 820 |
| **python/http, kafka, logger, postgres, redis, tracing** | Python | 0 | **DROP** | 7313 |

**Dự kiến cắt shared-libs:** **~8133 LoC** (820 Go + 7313 Python). Orphan absolutely.

### 5.9 `web-ui` (REVISED — reports + ontology KEEP)

#### Pages

| Route | UC | Verdict | LoC | Ghi chú |
|---|---|---|---|---|
| `/auth/login`, `/signup`, `/callback` | FR-01 | KEEP | ~721 | |
| `/auth/forgot-password` | — | **DROP** | 161 | identity-srv không có endpoint, dead UX, mock setTimeout. |
| `/settings` | FR-01 | KEEP | 143 | |
| `/smap` (5 tabs) | UC-01/02/03/04 | KEEP | 3138 | |
| `/smap/settings` (crisis + ontology) | UC-05 + support | **KEEP** | 623 | Ontology editor giữ. |
| `/smap/reports/[reportId]` | report support | **KEEP** | wrapper | |
| `/onboarding` setup wizard | UC-01 | **KEEP** | 942 | **v3 REVISED.** Signup push tới, CampaignSwitcher dùng. Gọi 7+ API. Critical signup→onboarding→campaign flow. |
| `/smap/processing` demo progress | — | **DROP** | 261 | Orphan, không reach. Onboarding push trực tiếp `/smap?camp_id=`. |
| `/showcase` UI library demo | — | **DROP** | 926 | Dev sandbox. |
| `/campaigns` redirect-only | FR-01 | **KEEP** | 9 | **v3 REVISED.** Auth callback + login + settings layout redirect tới. Auth exit point. |

#### Components

| Dir | UC | Verdict | LoC |
|---|---|---|---|
| `auth/`, `cards/`, `charts/`, `crisis/`, `heap/`, `icons/`, `ui/` | UC-01..05 + base | KEEP | ~8300 |
| `ontology/` OntologyRulesEditor | support (Layer 2) | **KEEP** | 334 | **REVISED.** |
| `reports/` Report UI | report support | **KEEP** | 739 | **REVISED.** |
| `animated/` decorative | — | **UNSURE** | 424 | Nice-to-have, giữ nếu UI/UX cần. Tài quyết. |

#### API clients / hooks / stores

| File | UC | Verdict | LoC | Ghi chú |
|---|---|---|---|---|
| `client.ts`, `config.ts`, `campaigns.ts`, `datasources.ts`, `projects.ts`, `knowledge.ts` | UC-01..03 + FR-01 | KEEP | ~965 | Field `is_favorite` thừa nhưng giữ struct (drop sau khi project-srv drop favorites). |
| `reports.ts` | report support | **KEEP** | 525 | **REVISED.** |
| `use-reports.ts` hook | report support | **KEEP** | 202 | **REVISED.** |
| `reportJobs.ts` store | report support | **KEEP** | 65 | **REVISED.** |

#### Buttons / actions

| Action | Verdict |
|---|---|
| Create/activate/pause/resume/archive project + campaign | KEEP (UC-01/02) |
| Crisis rule editor | KEEP (UC-05) |
| Search + chat panel | KEEP (UC-03) |
| Status dashboard + notification bell | KEEP (UC-04) |
| **Export mentions (CSV/SVG)** | **KEEP** (report support) |
| **Generate/Download report** | **KEEP** (report support) |
| **Favorite campaign/project** (stub, không hook UI) | **DROP** (đi kèm project-srv favorites cắt) |
| **Ontology rules editor** | **KEEP** (Layer 2 overlay) |

**Dự kiến cắt web-ui:** **~1.4K LoC** (forgot-password 161 + processing 261 + showcase 926 + favorite stubs). `onboarding` + `/campaigns` redirect GIỮ. `animated/` để Tài quyết.

## 6. Tổng kết LoC dự kiến cắt (v3)

| Repo | LoC cắt | Ghi chú |
|---|---:|---|
| identity-srv | **~978** | consumer 236 + audit domain 742 + migration audit_logs + Kafka topic `audit.events` |
| project-srv | ~150 | favorites (6 endpoints + UI stub) |
| ingest-srv | 0 | UAP chain giữ; Archive/Delete để UNSURE |
| scapper-srv | ~102 | router.py confirmed dead |
| analysis-srv | ~50 | `/heap` debug |
| knowledge-srv | 0 | report subsystem giữ (Tài 2.2) |
| notification-srv | 0 | analyticsbridge digest giữ |
| shared-libs | **~8133** | 4 Go pkg orphan + Python toàn bộ |
| web-ui | **~1348** | forgot-password 161 + processing 261 + showcase 926 + favorite stubs ~xx; onboarding + /campaigns redirect GIỮ |
| **Tổng** | **~10.8K LoC** | (v1: ~19K, v2: ~11K) |

## 7. UNSURE — cần Tài quyết (còn lại sau v3 verify)

| Item | LoC | Ghi chú |
|---|---:|---|
| ingest-srv datasource `Archive/Delete` | ~60 | UC-02 không nhắc cấp datasource. Operational cleanup. |
| analysis-srv `config/domains/kotex_goodnight.yaml`, `tanca.yaml`, `config/ontology/hrm_crm_vn.yaml` | — | Sample HRM, zero reference từ active project. Drop nếu muốn sạch. |
| web-ui `components/animated/` | 424 | Decorative; giữ nếu UX cần. |

## 8. Bug / contract issues phát hiện (v3)

1. **project-srv** `is_favorite` field trả về API nhưng UI không render → field thừa. Drop kèm favorites.
2. **scapper-srv** public route `/api/v1/tasks/*` không auth → may là ClusterIP only (verify: không có ingress). Drop router để tránh attack surface tương lai.
3. **web-ui `/auth/forgot-password`** UI tồn tại nhưng identity-srv không có endpoint → dead UX (mock setTimeout). Drop.
4. **shared-libs/python** 7313 LoC mồ côi xác nhận — analysis-srv + scapper-srv tự implement local helpers. Drop sạch hoặc plan migrate sau (nếu muốn re-adopt).
5. **analysis-srv `/heap`** debug endpoint expose qua API gateway nếu không ACL.
6. **identity-srv `internal/audit/`** SKELETON CODE: Kafka topic `audit.events` không có producer. Consumer + repo + endpoint đều có nhưng OAuth login KHÔNG ghi audit. Đây là design dở dang. Drop hoặc hoàn thiện producer.
7. **web-ui `/smap/processing`** dead orphan: onboarding push trực tiếp `/smap?camp_id=`, không qua processing. Drop.
8. **ingest-srv `analytics_exclusions.go`** trước đây v1 đề xuất drop SAI — bài học: phải trace UAP cross-service trước khi cắt. v2 đã fix, v3 verify lại.

## 9. Đề xuất kế hoạch Phase 2 (v3 — thứ tự an toàn)

Mỗi pass: 1 repo / 1 commit / 1 push / cập nhật `report/MINIMIZATION_REPORT.md`.

1. **shared-libs Python (7313 LoC)** — 0 importer xác nhận. Drop sạch thư mục `python/`.
2. **shared-libs Go (820 LoC)** — `locale`, `gemini`, `database`, `compressor`. Test downstream: `go mod tidy` + `go build` từng Go service.
3. **identity-srv audit + consumer (~978 LoC)** — drop `internal/audit/` + `internal/consumer/` + migration audit_logs + bỏ Kafka topic config `audit.events`.
4. **scapper-srv router.py (102 LoC)** — drop `app/router.py` + `main.py:89` `include_router(...)`. Health endpoints `/live`, `/ready`, `/health` GIỮ (k8s probe phụ thuộc).
5. **project-srv favorites (~150 LoC)** — drop 6 endpoints + usecase + repo + migration cột `is_favorite` (nếu có) + web-ui `is_favorite` references.
6. **analysis-srv `/heap` (~50 LoC)** — drop debug endpoint.
7. **web-ui dead pages (~1.4K LoC)** — drop `/auth/forgot-password`, `/smap/processing`, `/showcase`, favorite stubs trong `campaigns.ts`/`projects.ts`. **GIỮ `/onboarding` + `/campaigns` redirect.**

UNSURE pending Tài duyệt:
8. (optional) ingest-srv datasource archive/delete (60 LoC).
9. (optional) analysis-srv sample domain configs (kotex/tanca/hrm_crm_vn).
10. (optional) web-ui `components/animated/` (424 LoC).

## 10. Quy tắc đã chốt cho Phase 2

- KHÔNG đụng UAP chain (attribution/exclusions/visibility/hidden_targets).
- KHÔNG đụng report subsystem (knowledge `internal/report`, analysis `build_bi_reports.py`, notification `analyticsbridge`, web-ui `reports/`, topic `analytics.report.digest`).
- KHÔNG đụng ontology chain (analysis `config/ontology/*` + project Redis overlay + web-ui `ontology/`).
- Mỗi commit phải pass: Go (`go test ./...`), Python (`compileall`), TS (`tsc --noEmit`).
- Sau pass shared-libs Go: chạy `staticcheck` + `deadcode` mỗi service downstream.

---

**Kết luận v3:** Drop scope **~10.8K LoC**. Sau verify pass:
- `shared-libs` orphan (8.1K LoC, zero importer) — vùng an toàn nhất.
- `identity-srv` audit skeleton (978 LoC) — design dở dang.
- `web-ui` dead pages (1.4K LoC) — `/onboarding` + `/campaigns` redirect GIỮ (auth/signup flow critical).
- `project-srv` favorites (150) + `scapper-srv` router (102) + `analysis-srv` /heap (50).

Các vùng còn lại (UAP chain, report subsystem, ontology dual-layer) đều giữ theo 3 directive Tài + verify cross-service.

7 pass chính + 3 pass optional. Đợi Tài chốt audit v3, vào Phase 2 theo §9.
