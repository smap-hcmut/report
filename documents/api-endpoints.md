# SMAP API Endpoints Reference

> **Base domain:** `https://smap-api.tantai.dev`
> Each service is routed via Traefik with a path prefix stripped before reaching the service.

---

## 1. Identity Service

**Prefix:** `/identity` → stripped → service at `identity-api:80`
**Swagger UI:** `https://smap-api.tantai.dev/identity/swagger/index.html`

### Authentication

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/identity/authentication/login` | Public | Redirect to OAuth provider (Google) |
| GET | `/identity/authentication/callback` | Public | OAuth callback, sets auth cookie |
| POST | `/identity/authentication/logout` | Cookie/Bearer | Logout, clears cookie |
| GET | `/identity/authentication/me` | Cookie/Bearer | Get current user info |

### Internal (Service-to-Service)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/identity/authentication/internal/validate` | X-Service-Key | Validate JWT token |
| POST | `/identity/authentication/internal/revoke-token` | Cookie/Bearer + Admin | Revoke a token |
| GET | `/identity/authentication/internal/users/:id` | X-Service-Key | Get user by ID |

### Audit

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/identity/audit-logs` | Cookie/Bearer + Admin | List audit logs |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/identity/health` | Health check |
| GET | `/identity/ready` | Readiness check |
| GET | `/identity/live` | Liveness check |

---

## 2. Project Service

**Prefix:** `/project` → stripped → service at `project-api:80`
**Swagger UI:** `https://smap-api.tantai.dev/project/swagger/index.html`

### Campaigns

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/project/api/v1/campaigns` | Cookie/Bearer | Create campaign |
| GET | `/project/api/v1/campaigns` | Cookie/Bearer | List campaigns |
| GET | `/project/api/v1/campaigns/:id` | Cookie/Bearer | Get campaign detail |
| PUT | `/project/api/v1/campaigns/:id` | Cookie/Bearer | Update campaign |
| DELETE | `/project/api/v1/campaigns/:id` | Cookie/Bearer | Archive campaign |

### Projects (nested under campaign)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/project/api/v1/campaigns/:id/projects` | Cookie/Bearer | Create project |
| GET | `/project/api/v1/campaigns/:id/projects` | Cookie/Bearer | List projects in campaign |
| GET | `/project/api/v1/projects/:projectId` | Cookie/Bearer | Get project detail |
| PUT | `/project/api/v1/projects/:projectId` | Cookie/Bearer | Update project |
| DELETE | `/project/api/v1/projects/:projectId` | Cookie/Bearer | Archive project |

### Crisis Configuration

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| PUT | `/project/api/v1/projects/:projectId/crisis-config` | Cookie/Bearer | Upsert crisis config |
| GET | `/project/api/v1/projects/:projectId/crisis-config` | Cookie/Bearer | Get crisis config |
| DELETE | `/project/api/v1/projects/:projectId/crisis-config` | Cookie/Bearer | Delete crisis config |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/project/health` | Health check |
| GET | `/project/ready` | Readiness check |
| GET | `/project/live` | Liveness check |

---

## 3. Ingest Service

**Prefix:** `/ingest` → stripped → service at `ingest-api:80`
**Swagger UI:** `https://smap-api.tantai.dev/ingest/swagger/index.html`

### Data Sources

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/ingest/api/v1/datasources` | Cookie/Bearer | Create data source |
| GET | `/ingest/api/v1/datasources` | Cookie/Bearer | List data sources |
| GET | `/ingest/api/v1/datasources/:id` | Cookie/Bearer | Get data source detail |
| PUT | `/ingest/api/v1/datasources/:id` | Cookie/Bearer | Update data source |
| DELETE | `/ingest/api/v1/datasources/:id` | Cookie/Bearer | Archive data source |

### Crawl Targets (nested under data source)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/ingest/api/v1/datasources/:id/targets/keywords` | Cookie/Bearer | Add keyword target |
| POST | `/ingest/api/v1/datasources/:id/targets/profiles` | Cookie/Bearer | Add profile target |
| POST | `/ingest/api/v1/datasources/:id/targets/posts` | Cookie/Bearer | Add post target |
| GET | `/ingest/api/v1/datasources/:id/targets` | Cookie/Bearer | List targets |
| GET | `/ingest/api/v1/datasources/:id/targets/:target_id` | Cookie/Bearer | Get target detail |
| PUT | `/ingest/api/v1/datasources/:id/targets/:target_id` | Cookie/Bearer | Update target |
| DELETE | `/ingest/api/v1/datasources/:id/targets/:target_id` | Cookie/Bearer | Delete target |

### Dry Run

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/ingest/api/v1/datasources/:id/dryrun` | Cookie/Bearer | Trigger dry run |
| GET | `/ingest/api/v1/datasources/:id/dryrun/latest` | Cookie/Bearer | Get latest dry run result |
| GET | `/ingest/api/v1/datasources/:id/dryrun/history` | Cookie/Bearer | Dry run history |

### Internal (Service-to-Service)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| PUT | `/ingest/api/v1/ingest/datasources/:id/crawl-mode` | Internal Key | Update crawl mode |
| POST | `/ingest/api/v1/ingest/datasources/:id/targets/:target_id/dispatch` | Internal Key | Dispatch target for execution |
| GET | `/ingest/api/v1/ingest/ping` | — | Service ping |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ingest/health` | Health check |
| GET | `/ingest/ready` | Readiness check |
| GET | `/ingest/live` | Liveness check |

---

## 4. Knowledge Service

**Prefix:** `/knowledge` → stripped → service at `knowledge-api:80`
**Swagger UI:** `https://smap-api.tantai.dev/knowledge/swagger/index.html`

### Chat & Conversations

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/knowledge/api/v1/chat` | Cookie/Bearer | Send chat message (RAG-based) |
| GET | `/knowledge/api/v1/conversations/:conversation_id` | Cookie/Bearer | Get conversation history |
| GET | `/knowledge/api/v1/campaigns/:campaign_id/conversations` | Cookie/Bearer | List conversations for campaign |
| GET | `/knowledge/api/v1/campaigns/:campaign_id/suggestions` | Cookie/Bearer | Get AI suggestions |

### Search

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/knowledge/api/v1/search` | Cookie/Bearer | Search knowledge base |

### Reports

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/knowledge/api/v1/reports/generate` | Cookie/Bearer | Generate AI report |
| GET | `/knowledge/api/v1/reports/:report_id` | Cookie/Bearer | Get report status/content |
| GET | `/knowledge/api/v1/reports/:report_id/download` | Cookie/Bearer | Download report file |

### Internal (Service-to-Service)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/knowledge/internal/index` | X-Service-Key | Index documents |
| POST | `/knowledge/internal/index/retry` | X-Service-Key | Retry failed indexing |
| POST | `/knowledge/internal/index/reconcile` | X-Service-Key | Reconcile index |
| GET | `/knowledge/internal/index/statistics/:project_id` | X-Service-Key | Get indexing statistics |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/knowledge/health` | Health check |
| GET | `/knowledge/ready` | Readiness check |
| GET | `/knowledge/live` | Liveness check |

---

## 5. Notification Service

**Prefix:** `/notification` → stripped → service at `notification-api:80`

### WebSocket

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/notification/ws` | Cookie/Bearer | WebSocket connection for real-time notifications |

> Clients connect via WebSocket and receive push notifications (alerts, crisis events, system messages) through Redis pub/sub.

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notification/health` | Health check |
| GET | `/notification/ready` | Readiness check |
| GET | `/notification/live` | Liveness check |

---

## 6. Scraper Service

**Prefix:** `/scraper` → stripped → service at `scapper-api:80`
**Docs UI:** `https://smap-api.tantai.dev/scraper/docs`

> Internal worker service that submits scraping tasks to RabbitMQ queues (TikTok, Facebook, YouTube) via TinLikeSub API. Results are stored in MinIO.

### Tasks

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/scraper/api/v1/tasks/{platform}` | Internal | Submit scraping task to platform queue |
| GET | `/scraper/api/v1/tasks/{task_id}/result` | Internal | Get task result by ID |
| GET | `/scraper/api/v1/tasks` | Internal | List recent task results (default: last 20) |

**Supported platforms:** `tiktok`, `facebook`, `youtube`

**Example request body** for `POST /scraper/api/v1/tasks/tiktok`:

```json
{
  "action": "get_post",
  "params": { "url": "https://www.tiktok.com/@user/video/123" }
}
```

### Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/scraper/health` | Health check (includes worker active status) |
| GET | `/scraper/` | Service info + docs link |

---

## Authentication Reference

| Method | Header/Cookie | Used By |
|--------|--------------|---------|
| HttpOnly Cookie | `smap_auth_token` | All user-facing APIs (preferred) |
| Bearer Token | `Authorization: Bearer <token>` | All user-facing APIs (fallback) |
| Service Key | `X-Service-Key: <encrypted-key>` | identity ↔ other services |
| Internal Key | `X-Internal-Key: <key>` | project-srv internal routes |

---

## Service Communication Flow

```
Client
  │
  ▼
Traefik (smap-api.tantai.dev)
  ├── /identity/*   ──► identity-api:8080
  ├── /project/*    ──► project-api:8080
  ├── /ingest/*     ──► ingest-api:8080
  ├── /knowledge/*  ──► knowledge-api:8080
  ├── /notification/* ──► notification-api:8080
  └── /scraper/*    ──► scapper-api:8105

Internal (in-cluster)
  project-api ──► identity-api  (token validate)
  project-api ──► ingest-api    (crawl mode, dispatch)
  ingest-consumer ──► knowledge-api (index documents)
  analysis-consumer ──► notification-api (push alerts via Kafka)
```
