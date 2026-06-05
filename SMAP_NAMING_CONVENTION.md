# SMAP Naming Convention

This file is the root convention for opening code during the project defense. It does not replace per-service domain conventions; it defines the cross-repo names and the rule for tracing an end-to-end flow.

## Canonical repo and service names

| Capability                                        | Runtime repo/service name | Public route prefix                 | Human-facing name          |
| ------------------------------------------------- | ------------------------- | ----------------------------------- | -------------------------- |
| Authentication and audit                          | `identity-srv`            | `/identity`                         | Identity service           |
| Campaign/project control plane                    | `project-srv`             | `/project`                          | Project service            |
| Datasource, dry run, crawl execution, UAP publish | `ingest-srv`              | `/ingest`                           | Ingest service             |
| Crawler worker                                    | `scapper-srv`             | `/scraper`                          | Scraper worker             |
| Analytics API and Kafka consumer                  | `analysis-srv`            | `/analytics` or UI analytics routes | Analysis service           |
| Search, chat, indexing, AI reports                | `knowledge-srv`           | `/knowledge`                        | Knowledge service          |
| WebSocket notifications                           | `notification-srv`        | `/notification`                     | Notification service       |
| Next.js application                               | `web-ui`                  | `/`                                 | SMAP UI                    |
| K3s, manifests, E2E, NFR                          | `smap-deploy`             | n/a                                 | Deployment source of truth |
| Official project report                           | `report`                  | n/a                                 | Report source              |

Important exception: `scapper-srv` is a legacy runtime name and must stay stable until a coordinated image, manifest, queue, DNS, and report migration exists. Use "scraper worker" in explanations, but keep `scapper-srv` in code, manifests, logs, image names, and kubectl commands. Do not use `scrapper`.

## Cross-repo layer convention

Go services:

| Layer              | Path convention                                      | Role                                                |
| ------------------ | ---------------------------------------------------- | --------------------------------------------------- |
| Process entrypoint | `cmd/server/main.go`                                 | Load config, wire infra, start HTTP/consumer server |
| HTTP server wiring | `internal/httpserver/*.go`                           | Register middleware, health, and domain handlers    |
| Route map          | `internal/<domain>/delivery/http/routes.go`          | The first file to open for HTTP paths               |
| Handler            | `internal/<domain>/delivery/http/handlers.go`        | Parse request, call usecase, return presenter       |
| Request parser     | `internal/<domain>/delivery/http/process_request.go` | Bind JSON/query/path, validate, extract scope       |
| Presenter          | `internal/<domain>/delivery/http/presenters.go`      | Convert usecase input/output to API DTO             |
| Domain logic       | `internal/<domain>/usecase/*.go`                     | Business rules and state transitions                |
| Repository         | `internal/<domain>/repository/<store>/*.go`          | SQL/Redis/object-store access only                  |
| MQ delivery        | `internal/<domain>/delivery/{kafka,rabbitmq}`        | Publish/consume transport messages                  |

Python services:

| Repo           | Path convention         | Role                                          |
| -------------- | ----------------------- | --------------------------------------------- |
| `analysis-srv` | `apps/api/main.py`      | Analytics read API                            |
| `analysis-srv` | `apps/consumer/main.py` | Kafka consumer process entrypoint             |
| `analysis-srv` | `internal/consumer/`    | Consume UAP/analytics topics and run pipeline |
| `scapper-srv`  | `app/main.py`           | FastAPI entrypoint and worker lifespan        |
| `scapper-srv`  | `app/router.py`         | Task submission/result API                    |
| `scapper-srv`  | `app/worker.py`         | RabbitMQ task consumer and crawler execution  |
| `scapper-srv`  | `app/publisher.py`      | RabbitMQ completion publisher                 |

Frontend:

| Layer             | Path convention                 | Role                                                |
| ----------------- | ------------------------------- | --------------------------------------------------- |
| Page              | `web-ui/src/app/**/page.tsx`    | User journey and screen composition                 |
| Component         | `web-ui/src/components/**`      | UI behavior and local interactions                  |
| Hook              | `web-ui/src/lib/hooks/use-*.ts` | React Query state and mutation boundary             |
| API client        | `web-ui/src/lib/api/*.ts`       | Backend contract and payload mapping                |
| Endpoint registry | `web-ui/src/lib/api/config.ts`  | Single source for route prefixes and endpoint paths |
| Store             | `web-ui/src/lib/stores/*.ts`    | Client-only session or UI state                     |

## Business vocabulary

Use these nouns consistently when explaining and naming code:

| Term              | Meaning                                  | Main owner                    |
| ----------------- | ---------------------------------------- | ----------------------------- |
| `campaign`        | Top-level monitoring/business objective  | `project-srv`                 |
| `project`         | Executable scope under a campaign        | `project-srv`                 |
| `datasource`      | Crawl/input configuration for a project  | `ingest-srv`                  |
| `target`          | Concrete crawl target under a datasource | `ingest-srv`                  |
| `dryrun`          | Pre-activation crawler validation sample | `ingest-srv` + `scapper-srv`  |
| `externalTask`    | RabbitMQ task sent to crawler worker     | `ingest-srv`                  |
| `rawBatch`        | Large crawl output stored in MinIO       | `ingest-srv`                  |
| `uapRecord`       | Normalized analytics event record        | `ingest-srv` + `analysis-srv` |
| `insight`         | Analysis output/read model               | `analysis-srv`                |
| `indexedDocument` | Knowledge/Qdrant document                | `knowledge-srv`               |
| `conversation`    | Knowledge chat thread                    | `knowledge-srv`               |
| `report`          | AI-generated knowledge artifact          | `knowledge-srv`               |
| `notification`    | WebSocket message to UI                  | `notification-srv`            |

## Identifier convention

| Context                            | Convention                                                              |
| ---------------------------------- | ----------------------------------------------------------------------- |
| JSON payloads and database columns | `snake_case`                                                            |
| TypeScript fields                  | `camelCase`, mapped at API boundary when backend uses `snake_case`      |
| Go exported types/methods          | `PascalCase`                                                            |
| Go private helpers                 | `camelCase`                                                             |
| Python variables/functions         | `snake_case`                                                            |
| Runtime service names              | `<capability>-srv`                                                      |
| Kubernetes app labels              | runtime service name, for example `project-srv`                         |
| Public route prefixes              | short capability noun, for example `/project`, `/knowledge`, `/scraper` |

Canonical cross-flow IDs:

| ID                               | Meaning                            |
| -------------------------------- | ---------------------------------- |
| `campaignId` / `campaign_id`     | Campaign scope                     |
| `projectId` / `project_id`       | Project scope                      |
| `datasourceId` / `datasource_id` | Datasource scope                   |
| `targetId` / `target_id`         | Crawl target scope                 |
| `taskId` / `task_id`             | RabbitMQ crawler task correlation  |
| `batchId` / `batch_id`           | Raw batch / UAP batch correlation  |
| `reportId` / `report_id`         | Knowledge report artifact          |
| `traceId` / `trace_id`           | Request or async trace correlation |

## HTTP and MQ naming

HTTP:

| Rule                                                            | Example                                              |
| --------------------------------------------------------------- | ---------------------------------------------------- |
| Route file is the map                                           | `internal/project/delivery/http/routes.go`           |
| Path nouns are plural for collections                           | `/projects`, `/datasources`, `/reports`              |
| State transitions are explicit subresources                     | `POST /projects/:id/activate`                        |
| Internal service APIs use `/internal/...` and internal key auth | `/api/v1/internal/projects/:id/activation-readiness` |
| Health payload `service` equals runtime service name            | `project-srv`, not `smap-project`                    |

Messaging:

| Rule                                              | Example                                            |
| ------------------------------------------------- | -------------------------------------------------- |
| Publisher method names start with `Publish`       | `PublishProjectEvent`, `PublishUAPRecord`          |
| Consumer handler names describe the consumed fact | `HandleDryrunCompletion`, `HandleProjectActivated` |
| RabbitMQ payloads carry `task_id` for idempotency | crawler task and completion                        |
| Kafka payloads carry project/campaign scope       | analytics and knowledge fan-out                    |

## Report-time trace rule

When presenting a flow, open files in this order:

1. UI page or E2E script that triggers the action.
2. Frontend hook and API client.
3. Backend `routes.go` for the public path.
4. Backend `handlers.go` and `process_request.go`.
5. Backend `usecase/*.go` where the business rule lives.
6. Repository or external client if the state change crosses a boundary.
7. MQ producer/consumer if the flow becomes async.
8. Read-side API or UI component that proves the result.

## Current exceptions and fixes

| Area                       | Current convention decision                                                      |
| -------------------------- | -------------------------------------------------------------------------------- |
| `scapper-srv` typo         | Keep runtime name; explain as "scraper worker (`scapper-srv`)"                   |
| Frontend `/reports/api/v1` | Mock competitor-analysis lane only; not the knowledge AI report backend          |
| Knowledge AI reports       | Canonical backend path is `/knowledge/api/v1/knowledge/reports`                  |
| Notification WebSocket     | Public path is `/notification/ws`; service receives `/ws` after prefix stripping |
| Project health             | `service` must return `project-srv`                                              |
