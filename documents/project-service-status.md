# Project Service — Status Document

> Generated from code review: `services/project/`
> Date: 2026-03-06

---

## 1. Tổng quan

Project Service quản lý hierarchy Campaign → Project → CrisisConfig. Được viết bằng Go, Gin framework, PostgreSQL (SQLBoiler), không có domain logic phụ thuộc vào ingest/data source.

**Ba domain:**

- `campaign` — quản lý marketing campaigns (top-level container)
- `project` — quản lý monitoring projects (thuộc về campaign)
- `crisis` — quản lý crisis detection config (1-1 với project)

---

## 2. Data Hierarchy

```text
Campaign
  ├── id, name, description, status (ACTIVE/INACTIVE/ARCHIVED)
  ├── start_date, end_date (optional)
  └── Projects[]
        ├── id, campaign_id, name, brand, entity_type, entity_name
        ├── status: ACTIVE | PAUSED | ARCHIVED
        ├── config_status: (wizard states, xem bên dưới)
        └── CrisisConfig (1-1)
              ├── status: NORMAL | WARNING | CRITICAL
              └── triggers: keywords | volume | sentiment | influencer (JSONB)
```

### ProjectConfigStatus (wizard states)

```text
DRAFT → CONFIGURING → ONBOARDING → ONBOARDING_DONE
                                         ↓
                               DRYRUN_RUNNING → DRYRUN_SUCCESS → ACTIVE
                                             → DRYRUN_FAILED  → ERROR
```

**Lưu ý:** Các state transitions này được định nghĩa trong model nhưng **không có usecase nào transition chúng**. Không có method `SetStatus`, `StartOnboarding`, v.v. trong project usecase. State hiện tại chỉ được set từ bên ngoài (ingest service hoặc manually).

### EntityType (project monitoring targets)

`product` | `campaign` | `service` | `competitor` | `topic`

---

## 3. API Endpoints

```text
Campaign:
  POST   /campaigns           → Create
  GET    /campaigns           → List (filter: status, name; paginated)
  GET    /campaigns/:id       → Detail
  PUT    /campaigns/:id       → Update
  DELETE /campaigns/:id       → Archive (soft delete)

Project (nested under campaign + direct):
  POST   /campaigns/:id/projects      → Create (requires campaign_id)
  GET    /campaigns/:id/projects      → List projects of campaign
  GET    /projects/:projectId         → Detail
  PUT    /projects/:projectId         → Update
  DELETE /projects/:projectId         → Archive

Crisis Config:
  PUT    /projects/:projectId/crisis-config   → Upsert
  GET    /projects/:projectId/crisis-config   → Detail
  DELETE /projects/:projectId/crisis-config   → Delete
```

Tất cả routes đều require `mw.Auth()` (JWT authentication).

---

## 4. CrisisConfig — Chi Tiết

Crisis config được lưu dưới dạng JSONB trong PostgreSQL, hỗ trợ 4 loại trigger:

| Trigger | Logic |
|---------|-------|
| `keywords_trigger` | Keyword groups với weight và logic OR/AND |
| `volume_trigger` | % spike so với baseline (e.g. average_last_7_days), theo window giờ |
| `sentiment_trigger` | negative_ratio hoặc absa_aspect_alert, với min_sample_size |
| `influencer_trigger` | macro_influencer (min followers) hoặc viral_post (min shares/comments) |

Status của CrisisConfig (`NORMAL/WARNING/CRITICAL`) chỉ là metadata — **không có logic detection nào trong project service**. Detection xảy ra ở analysis service; project service chỉ lưu config.

---

## 5. Kafka Consumer — Chưa Implement

File: [consumer/handler.go](../services/project/consumer/handler.go)

```go
func (srv *ConsumerServer) setupDomains(ctx context.Context) (*domainConsumers, error) {
    // TODO: Initialize domain consumers here
    return &domainConsumers{}, nil
}
```

ConsumerServer có infrastructure wired (kafka producer, redis client, postgres) nhưng `setupDomains()`, `startConsumers()`, `stopConsumers()` đều là TODO scaffold. **Không có Kafka topic nào được subscribe.**

---

## 6. Adaptive Crawl — Chưa Implement

Thư mục `services/project/adaptive/` tồn tại nhưng **hoàn toàn trống**, không có file nào.

Theo thiết kế (trong `ingest-project-boundary.md`), Adaptive Crawl cần project service phát hiện crisis → thay đổi crawl frequency của ingest service. Hiện tại logic này chưa tồn tại ở bất kỳ service nào:

- Project service: `adaptive/` trống
- Analysis service: topic `analytics.metrics.aggregated` chưa được publish
- Ingest service: chưa rõ (code chưa được paste vào repo này)

---

## 7. Tình Trạng Tổng Thể

**Implemented và hoạt động:**

- Campaign CRUD (full: Create/List/Detail/Update/Archive)
- Project CRUD (full, với campaign validation khi create)
- Crisis Config CRUD (Upsert/Detail/Delete, JSONB storage)
- Soft delete (archive) cho cả Campaign và Project
- ProjectConfigStatus enum (wizard states) defined trong model

**Chưa implement / còn TODO:**

- Kafka consumer (scaffold trống, không subscribe topic nào)
- Adaptive crawl (thư mục trống)
- ProjectConfigStatus transitions trong usecase — state chỉ được set externally
- Không có internal API endpoint để các service khác query (e.g., ingest service hỏi "project có đang active không?")

**Liên quan tới vấn đề Ingest/Project boundary:**

- Project service không có DataSource domain — đây là phần của ingest service
- Project service không expose API nội bộ → knowledge service đang gọi HTTP `/projects` với JWT (xem knowledge-service-status.md)
- Consumer infrastructure có kafka producer nhưng chưa dùng → khi implement Adaptive Crawl, project service sẽ có thể publish event thay vì gọi HTTP đồng bộ
