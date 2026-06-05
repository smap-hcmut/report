# SMAP E2E Flow Map

This file is the code-opening map for project defense. Start from `smap-deploy/e2e-test.sh` for the full backend E2E and from `web-ui/src/app/smap/page.tsx` for the main UI journey.

## One-line system flow

User authenticates -> creates campaign/project -> configures datasource/targets -> dry run validates crawler -> project activation enables scheduled crawl -> scraper worker returns raw artifacts -> ingest normalizes UAP -> analysis consumes Kafka -> knowledge indexes/searches/chats/reports -> notification pushes realtime UI events.

## Flow 0: E2E test harness

| Step | File | What to show |
| --- | --- | --- |
| Test entrypoint | `smap-deploy/e2e-test.sh` | Public gateway bases and the full ordered scenario |
| Test user seed | `smap-deploy/e2e-test.sh` | Identity test user and JWT setup |
| Flow checkpoints | `smap-deploy/e2e-test.sh` | Campaign, project, datasource, dryrun, activation, knowledge, report checks |
| UI smoke/API contract | `smap-deploy/ui-test/tests/2-dashboard.spec.ts` | Dashboard behavior |
| UI API contract | `smap-deploy/ui-test/tests/3-api-contracts.spec.ts` | Frontend proxy/session contract |

## Flow 1: Auth and session

| Layer | File | Responsibility |
| --- | --- | --- |
| UI page | `web-ui/src/app/auth/login/page.tsx` | Login entry |
| UI state | `web-ui/src/lib/stores/auth.ts` | Client auth/session store |
| UI hook | `web-ui/src/lib/hooks/use-auth.ts` | Session mutation/query boundary |
| Endpoint registry | `web-ui/src/lib/api/config.ts` | `/identity/api/v1/authentication/*` |
| Backend routes | `identity-srv/internal/authentication/delivery/http/routes.go` | Auth HTTP map |
| Backend HTTP wiring | `identity-srv/internal/httpserver/handler.go` | Middleware and domain registration |
| Backend entrypoint | `identity-srv/cmd/server/main.go` | Config and server startup |
| Async audit | `identity-srv/internal/audit/delivery/kafka/consumer/` | Audit event consumption |

## Flow 2: Campaign and project control plane

| Layer | File | Responsibility |
| --- | --- | --- |
| UI page | `web-ui/src/app/smap/page.tsx` | Main campaign/project screen |
| UI hooks | `web-ui/src/lib/hooks/use-campaigns.ts` | Campaign queries and mutations |
| UI hooks | `web-ui/src/lib/hooks/use-projects.ts` | Project queries and mutations |
| API clients | `web-ui/src/lib/api/campaigns.ts` | Campaign API contract |
| API clients | `web-ui/src/lib/api/projects.ts` | Project API contract |
| Backend campaign routes | `project-srv/internal/campaign/delivery/http/routes.go` | `/campaigns` path map |
| Backend project routes | `project-srv/internal/project/delivery/http/routes.go` | `/projects` path map |
| Business rules | `project-srv/internal/campaign/usecase/campaign.go` | Campaign lifecycle |
| Business rules | `project-srv/internal/project/usecase/project.go` | Project CRUD |
| Lifecycle rules | `project-srv/internal/project/usecase/lifecycle.go` | Activate, pause, resume, archive |
| Event output | `project-srv/internal/project/delivery/kafka/producer/producer.go` | Project lifecycle events |

## Flow 3: Datasource, target, and dry run

| Layer | File | Responsibility |
| --- | --- | --- |
| UI page | `web-ui/src/app/smap/settings/page.tsx` | Datasource/target setup screen |
| UI hook | `web-ui/src/lib/hooks/use-datasources.ts` | Datasource target query boundary |
| API client | `web-ui/src/lib/api/datasources.ts` | Ingest datasource endpoints |
| Backend routes | `ingest-srv/internal/datasource/delivery/http/routes.go` | Datasource and target HTTP map |
| Dryrun routes | `ingest-srv/internal/dryrun/delivery/http/routes.go` | Dryrun trigger/status map |
| Dryrun publisher | `ingest-srv/internal/dryrun/delivery/rabbitmq/producer/producer.go` | Publish crawler dryrun task |
| Worker API | `scapper-srv/app/router.py` | Task API for manual/debug calls |
| Worker runtime | `scapper-srv/app/main.py` | FastAPI lifespan starts worker |
| Worker consumer | `scapper-srv/app/worker.py` | RabbitMQ consume, crawl, upload artifact |
| Completion publisher | `scapper-srv/app/publisher.py` | Publish completion back to ingest |
| Completion consumer | `ingest-srv/internal/dryrun/delivery/rabbitmq/consumer/workers.go` | Consume dryrun completion |

## Flow 4: Activation and scheduled crawl

| Layer | File | Responsibility |
| --- | --- | --- |
| UI mutation | `web-ui/src/lib/api/projects.ts` | `POST /project/api/v1/projects/:id/activate` |
| Project route | `project-srv/internal/project/delivery/http/routes.go` | Activation route map |
| Lifecycle rule | `project-srv/internal/project/usecase/lifecycle.go` | Validate campaign/project state before activation |
| Ingest bridge | `project-srv/pkg/microservice/ingest` | Internal call to ingest readiness/runtime APIs |
| Ingest execution routes | `ingest-srv/internal/execution/delivery/http/routes.go` | Execution/internal control paths |
| Rabbit publisher | `ingest-srv/internal/execution/delivery/rabbitmq/producer/producer.go` | Publish scheduled crawler task |
| Rabbit consumer | `ingest-srv/internal/execution/delivery/rabbitmq/consumer/workers.go` | Consume crawler completion |
| UAP publisher | `ingest-srv/internal/uap/delivery/kafka/producer/producer.go` | Publish normalized UAP to Kafka |

## Flow 5: Analytics consume and dashboard read

| Layer | File | Responsibility |
| --- | --- | --- |
| Kafka consumer entry | `analysis-srv/apps/consumer/main.py` | Wire Kafka producer/consumer and pipeline dependencies |
| Consumer implementation | `analysis-srv/internal/consumer/` | Consume UAP and build analytics records |
| Read API entry | `analysis-srv/apps/api/main.py` | `/api/v1/analytics/*` endpoints |
| UI API routes | `web-ui/src/app/api/analytics/*.ts` | Next.js route layer for analytics reads |
| UI hooks | `web-ui/src/lib/hooks/use-campaign-kpis.ts` | Campaign KPI dashboard query |
| UI hooks | `web-ui/src/lib/hooks/use-platform-stats.ts` | Platform breakdown query |
| UI hooks | `web-ui/src/lib/hooks/use-sentiment-data.ts` | Sentiment trend query |
| UI hooks | `web-ui/src/lib/hooks/use-trending-keywords.ts` | Keyword trend query |

## Flow 6: Knowledge search, chat, and AI report

| Layer | File | Responsibility |
| --- | --- | --- |
| Kafka consumer | `knowledge-srv/internal/consumer/server.go` | Start knowledge consumer server |
| Indexing consumer | `knowledge-srv/internal/indexing/delivery/kafka/consumer/workers.go` | Consume analytics/knowledge events |
| Indexing routes | `knowledge-srv/internal/indexing/delivery/http/routes.go` | Internal indexing controls |
| Search routes | `knowledge-srv/internal/search/delivery/http/routes.go` | `/api/v1/knowledge/search` |
| Chat routes | `knowledge-srv/internal/chat/delivery/http/routes.go` | `/api/v1/knowledge/chat` |
| Report routes | `knowledge-srv/internal/report/delivery/http/routes.go` | `/api/v1/knowledge/reports/*` |
| Report usecase | `knowledge-srv/internal/report/usecase/report.go` | Create/status/download report logic |
| Report generator | `knowledge-srv/internal/report/usecase/generator.go` | Build and store generated report |
| UI knowledge client | `web-ui/src/lib/api/knowledge.ts` | Chat/suggestions API contract |
| UI assistant | `web-ui/src/components/CampaignAssistant.tsx` | Campaign chat UX |

Note: `web-ui/src/lib/api/reports.ts` is the mock competitor-analysis UI lane using `/reports/api/v1`. The production AI report backend is `knowledge-srv` and uses `/knowledge/api/v1/knowledge/reports`.

## Flow 7: Notification WebSocket

| Layer | File | Responsibility |
| --- | --- | --- |
| Analytics bridge | `notification-srv/internal/analyticsbridge/bridge.go` | Convert analytics/crisis events to websocket payloads |
| HTTP wiring | `notification-srv/internal/httpserver/handler.go` | Register `/ws` at service root |
| WS routes | `notification-srv/internal/websocket/delivery/http/routes.go` | WebSocket route map |
| WS handler | `notification-srv/internal/websocket/delivery/http/handlers.go` | Upgrade HTTP to websocket |
| WS usecase | `notification-srv/internal/websocket/usecase/` | Hub, channels, connection lifecycle |
| UI socket | `web-ui/src/components/NotificationSocket.tsx` | Browser endpoint `/notification/ws` |
| Endpoint registry | `web-ui/src/lib/api/config.ts` | Public WS path `/notification/ws` |

The public gateway path is `/notification/ws`; after prefix stripping the service should receive `/ws`.

## Flow 8: Deployment and runtime source of truth

| Area | File | Responsibility |
| --- | --- | --- |
| Service manifests | `smap-deploy/services/*/deployment.yaml` | Image, probes, envFrom, service |
| Infra manifests | `smap-deploy/infrastructure/*` | Redis, RabbitMQ, Redpanda, storage-backed dependencies |
| Public deployment note | `smap-deploy/single-source-of-truth.md` | Human source of truth for K3s/gateway |
| Longhorn incident RCA | `LONGHORN_ROOT_CAUSE_REPORT.md` | Storage root-cause and mitigation |
| Business process stop report | `SMAP_BUSINESS_DATA_PROCESS_STOP_REPORT.md` | Pending/stopped data process state |
| Workspace index | `SMAP_WORKSPACE_INDEX.md` | Repo inventory |

## Bugs and contract issues found in this convention pass

| Finding | Impact | Action |
| --- | --- | --- |
| `project-srv` health returned `service: "smap-project"` | Health output did not match runtime service name | Fixed to `project-srv` |
| `web-ui` knowledge report endpoints missed the `/knowledge` domain segment | Future callers would hit `/knowledge/api/v1/reports`, while backend/E2E use `/knowledge/api/v1/knowledge/reports` | Fixed endpoint registry |
| Human-facing worker name used `Scapper` | Confusing during defense because English term is scraper | Changed display name to "Scraper Worker Service (`scapper-srv`)" |
| `web-ui` report APIs have two meanings | Competitor mock reports and knowledge AI reports could be confused | Documented separation in config and this map |
| Old E2E report said WebSocket was unreachable | Current code registers `/ws` at root, matching prefix stripping expectation | Treat old report item as stale unless cluster ingress contradicts it |

## Validation gates for this map

Run these gates after code changes touching the mapped areas:

| Gate | Command |
| --- | --- |
| Project service static/build test | `cd project-srv && go test ./...` |
| Scapper syntax | `cd scapper-srv && python3 -m compileall -q app` |
| Web UI type check | `cd web-ui && npx tsc --noEmit --pretty false` |
| Backend E2E | `cd smap-deploy && ./e2e-test.sh` |
| UI smoke/API | `cd smap-deploy/ui-test && npm test` |
