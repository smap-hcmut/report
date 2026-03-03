---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-family: 'Arial', 'Helvetica Neue', sans-serif;
    background-color: #ffffff;
  }
  h1 {
    color: #1a5276;
    font-size: 1.4em;
  }
  h2 {
    color: #2874a6;
    font-size: 1em;
  }
  h3 {
    color: #5dade2;
    font-size: 0.95em;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }
  .small {
    font-size: 0.75em;
  }
  table {
    font-size: 0.8em;
  }
  .done {
    color: #27ae60;
    font-weight: bold;
  }
  .progress {
    color: #f39c12;
    font-weight: bold;
  }
  .todo {
    color: #e74c3c;
    font-weight: bold;
  }
  .note {
    background-color: #eaf2f8;
    padding: 0.5rem;
    border-left: 4px solid #2874a6;
    font-size: 0.75em;
    margin-top: 0.5rem;
  }
  .warn {
    background-color: #fef9e7;
    padding: 0.5rem;
    border-left: 4px solid #f1c40f;
    font-size: 0.75em;
    margin-top: 0.5rem;
  }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# **SMAP – Weekly Progress Report**

## Tuần 24/02 → 03/03/2026

**Người báo cáo:** Nguyễn Tấn Tài  
**Dự án:** SMAP Migration – Public SaaS → On-Premise Enterprise  
**Ngày họp:** 03/03/2026

---

# Agenda

1. **Tổng quan tiến độ** – Migration Plan Progress
2. **Chi tiết công việc đã hoàn thành** – 4 Services
3. **Infrastructure & DevOps** – Ansible, K3s, Helm
4. **Thiết kế & Kiến trúc** – Architecture Decisions
5. **Vấn đề gặp phải** – Issues & Blockers
6. **Kế hoạch tuần tiếp theo** – Next Steps

---

# Tổng quan Migration Plan

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Migration Plan v2.13

- **Mục tiêu:** Public SaaS → On-Premise Enterprise
- **Thời gian:** 3 tháng (12 tuần)
- **Bắt đầu:** 06/02/2026
- **Phiên bản hiện tại:** v2.13

## Phạm vi thay đổi

| Cũ (SaaS)    | Mới (On-Premise) |
| ------------ | ---------------- |
| 8 services   | 6 Core + 1 UI    |
| Multi-tenant | Single-tenant    |
| Subscription | License fee      |

</div>
<div>

## Kiến trúc mới

```
Go Services (5):
  ├── Auth Service
  ├── Project Service
  ├── Ingest Service
  ├── Notification Service
  └── Knowledge Service

Python Service (1):
  └── Analytics Service (AI Pipeline)
      ├── PhoBERT ONNX (Sentiment)
      ├── PhoBERT ONNX (ABSA)
      ├── YAKE + spaCy (Keywords)
      └── Impact Calculation
```

</div>
</div>

---

# Tiến độ tổng quan

<style scoped>
section { font-size: 24px; }
</style>

Sau khi bắt đầu giai đoạn 2, nhiệm vụ đầu tiên là refactor các service cũ, build các service mới theo clean architecture, đảm bảo context cơ bản:

| Service                        |    Status     | Mô tả ngắn                                            |
| ------------------------------ | :-----------: | ----------------------------------------------------- |
| **Identity Service**           | Done Detailed | OAuth2/JWT, RBAC, Audit Logging                       |
| **Notification Service**       | Done Detailed | WebSocket, Redis Pub/Sub, Discord                     |
| **Analytics Service** (Python) |  Refactored   | 5-Stage AI Pipeline, Kafka, PhoBERT ONNX, YAKE, spaCy |
| **Knowledge Service**          | Done Phase 1  | RAG, Qdrant Vector DB, Gemini LLM                     |
| **Project Service**            |    Pending    | CRUD cơ bản cho Project, Campaign                     |
| **Ingest Service**             |  In-progress  | Hiện tại chỉ đang code Integration Module             |
| **Migration Plan**             |     v2.13     | 13 lần cập nhật, chốt kiến trúc 6 Backend + 1 UI      |

---

# Identity Service (Auth)

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Đã hoàn thành

- OAuth2 login flow (Google)
- JWT HS256 token generation & verification
- Session management (Redis)
- RBAC: ADMIN / ANALYST / VIEWER
- Audit logging (PostgreSQL + Kafka)
- Internal API (service-to-service)
- HttpOnly Cookie + Bearer token
- Swagger API docs

## Chưa hoàn thành

- Docker & Kubernetes deployment

</div>
<div>

## Tech Stack

| Component | Technology                     |
| --------- | ------------------------------ |
| Language  | Go 1.25.4                      |
| Framework | Gin 1.11.0                     |
| Database  | PostgreSQL (`schema_identity`) |
| Cache     | Redis (session, blacklist)     |
| Queue     | Kafka (audit events)           |
| Auth      | Google OAuth2 + JWT HS256      |

</div>
</div>

---

# Identity Service API Endpoints

<style scoped>
section { font-size: 24px; }
</style>

- `GET /authentication/login` – OAuth2 redirect
- `GET /authentication/callback` – Token issuance
- `POST /authentication/logout` – Session cleanup
- `GET /authentication/me` – User info
- `POST /internal/validate` – S2S validation

---

# Notification Service

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Đã hoàn thành

- WebSocket connection management (JWT auth)
- Redis Pub/Sub subscriber
- Hub-based message routing (user-scoped)
- 4 message types: DATA_ONBOARDING, ANALYTICS_PIPELINE, CRISIS_ALERT, CAMPAIGN_EVENT
- Discord integration (Rich Embeds)
- Project-level filtering

</div>
<div>

## Kiến trúc

```
Backend Services
  → Redis Pub/Sub
  → notification-srv
  → Hub (routing by UserID)
  → WebSocket → Browser

  [Crisis Path]
  → Discord Webhook (Rich Embed)
```

</div>
</div>

---

# Analytics Service (Python – AI Pipeline)

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## 5-Stage AI Pipeline

1. **Text Preprocessing** – Spam detection, normalization
2. **Intent Classification** – CRISIS/SPAM/COMPLAINT/LEAD/SUPPORT/DISCUSSION
3. **Keyword Extraction** – YAKE + spaCy NER + Aspect Mapping
4. **Sentiment Analysis** – PhoBERT ONNX (Overall + ABSA)
5. **Impact Calculation** – Engagement, virality, risk scoring

## UAP Integration

- Input: `smap.collector.output` (UAP v1.0)
- Output: `smap.analytics.output` (Enriched batch)

</div>
<div>

## Tech Stack

| Component   | Technology                     |
| ----------- | ------------------------------ |
| Language    | Python 3.12+                   |
| Package Mgr | uv                             |
| Queue       | Kafka (aiokafka)               |
| Database    | PostgreSQL (`schema_analysis`) |
| Model       | PhoBERT ONNX                   |
| Keywords    | YAKE + spaCy                   |

</div>
</div>

---

# Knowledge Service (RAG)

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Đã hoàn thành

- Semantic Search (Qdrant + Voyage AI)
- RAG Chat (Gemini 1.5-pro, multi-turn)
- Report Generation (Map-Reduce pattern)
- Analytics Indexing (Kafka + HTTP)
- 3-Tier Caching (embedding, campaign, search)
- PostgreSQL metadata tables
- MinIO report storage

## Đã hoàn thành

- Chưa test E2E thực tế
- Chưa có các tính năng generate report

</div>
<div>

## API Endpoints

| Endpoint                        | Purpose         |
| ------------------------------- | --------------- |
| `POST /api/v1/search`           | Semantic search |
| `POST /api/v1/chat`             | RAG Q&A         |
| `POST /api/v1/reports/generate` | Async report    |
| `POST /internal/index`          | Index batch     |

</div>
</div>

---

# Infrastructure & DevOps

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Chiến lược "Turnkey Deployment"

- **IaC (Infrastructure as Code):** Sử dụng **Ansible** để tự động hóa cấu hình OS & Security.
- **Container Orchestration:** Triển khai trên cụm **K3s** (Lightweight Kubernetes) tối ưu cho On-Premise.
- **Packaging:** Mỗi service được đóng gói thành **Helm Charts** để quản lý version và cấu hình tập trung.
- **Database:** Tối ưu hóa vận hành với **Multi-schema** trên 1 instance PostgreSQL duy nhất.

</div>
<div>

## Trạng thái CI/CD & Pipeline

- **Hiện trạng:** <span style="color: #e74c34; font-weight: bold;">Chưa hoàn thành (Pending)</span>
- **Kế hoạch:**
  - Triển khai **Woodpecker CI** (Lightweight, CI-as-code).
  - Cấu hình **Pipeline as Code** (`.woodpecker.yml`) cho từng service:
    - Build Multi-arch Images (ARM64/AMD64).
    - Security Scan (Trivy) & Linting.
    - Tự động Push vào Private Registry.

</div>
</div>

---

# Thiết kế Kiến trúc – Quyết định quan trọng

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Architecture Decisions

| Quyết định              | Lý do                                     |
| ----------------------- | ----------------------------------------- |
| **HS256 over RS256**    | Simple, fast, sufficient cho on-premise   |
| **Multi-Schema DB**     | 1 PostgreSQL, 4 schemas – giảm ops        |
| **Kafka over RabbitMQ** | Event streaming, consumer groups          |
| **RabbitMQ**            | Legecy keep for integration from Tín      |
| **PhoBERT ONNX**        | Vietnamese NLP, no GPU required           |
| **Qdrant**              | Vector DB cho RAG, cosine similarity      |
| **Go + Python**         | Go (5 services) + Python (Analytics = AI) |

</div>
<div>

## Multi-Schema Database

```
PostgreSQL (Single Instance)
  ├── schema_identity  (Auth)
  ├── schema_project   (Project)
  ├── schema_ingest    (Ingest)
  ├── schema_analysis  (Analytics)
  └── schema_knowledge (RAG)

Qdrant (Separate)
  └── smap_analytics (Vector DB)
```

**Anti-Superbase Rules:**

- No Cross-Schema Writes
- Single Connection String
- Note: Always remember prefix schema

</div>
</div>

---

# Vấn đề – Per Service (1/3)

<style scoped>
section { font-size: 26px; }
</style>

<div class="columns">
<div>

## Identity Service

| #   | Issue                                | Severity |
| --- | ------------------------------------ | :------: |
| 1   | Audit log query chậm (>1M rows, >2s) |  Medium  |
| 2   | HS256 JWT – shared secret risk       |  Medium  |
| 3   | Redis single point of failure        |  Medium  |
| 4   | Service keys plaintext trong config  |  Medium  |
| 5   | Thiếu Prometheus metrics             |  Medium  |
| 6   | Chưa có integration tests cho OAuth  |   Low    |

</div>
<div>

## Notification Service

| #   | Issue                                   | Severity |
| --- | --------------------------------------- | :------: |
| 1   | Hub single goroutine – bottleneck >50k  |  Medium  |
| 2   | Message loss khi client disconnect      |  Medium  |
| 3   | Thiếu per-user rate limiting (DoS risk) |  Medium  |
| 4   | Thiếu metrics/observability             |  Medium  |

</div>
</div>

---

<style scoped>
section { font-size: 26px; }
</style>

<div class="columns">

<div>

## Analytics Service

| #   | Issue                              | Severity |
| --- | ---------------------------------- | :------: |
| 1   | PhoBERT ~100-200ms/text (CPU only) |  Medium  |
| 2   | Single consumer instance           |  Medium  |
| 3   | Poison messages skip, không DLQ    |  Medium  |
| 4   | Thiếu monitoring metrics           |  Medium  |
| 5   | Hardcoded thresholds trong code    |   Low    |
| 6   | Chưa có unit/integration tests     |  Medium  |

</div>
<div>

## Knowledge Service

| #   | Issue                                  | Severity |
| --- | -------------------------------------- | :------: |
| 1   | **Conversation Export chưa implement** | **HIGH** |
| 2   | Token window rough estimation          |  Medium  |
| 3   | Không có rate limiting                 |  Medium  |
| 4   | Thiếu prompt injection protection      |  Medium  |

</div>
</div>

---

# Vấn đề – Cross-cutting & Bugs (2/3)

<style scoped>
section { font-size: 20px; }
</style>

<div class="columns">
<div>

## Cross-cutting Issues (tất cả services)

| Vấn đề                        | Impact                  |  Status  |
| ----------------------------- | ----------------------- | :------: |
| **Thiếu Prometheus metrics**  | Không monitor realtime  | Planning |
| **Thiếu Grafana dashboard**   | Không visualize health  | Planning |
| **Thiếu distributed tracing** | Khó debug cross-service |   Todo   |
| **Load testing chưa xong**    | Chưa validate targets   |  30-80%  |
| **Redis single instance**     | SPOF cho Auth + Noti    |   Todo   |
| **Test coverage thấp**        | Risk regression bugs    | Partial  |

</div>
<div>

## Known Bugs

| Bug                                         | Service      | Severity |
| ------------------------------------------- | ------------ | :------: |
| **#45** Connection leak khi disconnect      | Notification |  Medium  |
| **#67** Discord webhook timeout log thiếu   | Notification |   Low    |
| **#001** Kafka producer buffer không flush  | Analytics    |  Medium  |
| **#002** PhoBERT chậm với text >512 tokens  | Analytics    |   Low    |
| **#001** OAuth state cleanup chưa implement | Identity     |   Low    |
| **#002** Audit log pagination performance   | Identity     |  Medium  |

### Workarounds đã có

- Bug #45: Ping/Pong timeout cleanup sau 60s
- Bug #001 (Analytics): Graceful shutdown với SIGTERM
- Bug #002 (Analytics): Truncate text trước inference
- Bug #001 (Identity): Redis TTL auto cleanup 5 phút

</div>
</div>

---

# Vấn đề – Planned & Roadmap (3/3)

<style scoped>
section { font-size: 20px; }
</style>

<div class="columns">
<div>

## Short-term (1-2 tháng)

| Task                              | Service          | Priority |
| --------------------------------- | ---------------- | :------: |
| Prometheus metrics export         | All              | **HIGH** |
| Grafana monitoring dashboard      | All              | **HIGH** |
| Load testing comprehensive        | All              | **HIGH** |
| **Conversation Export & Summary** | Knowledge        | **HIGH** |
| Dead Letter Queue (DLQ)           | Analytics        |  Medium  |
| Per-user rate limiting            | Noti + Knowledge |  Medium  |
| Unit + Integration tests          | Analytics        |  Medium  |
| 2FA/MFA support                   | Identity         |  Medium  |

</div>
<div>

## Mid-term (3-6 tháng)

- Redis Sentinel/Cluster (HA)
- Multi-provider OAuth2 (Azure AD, Okta)
- Sharded Hub >50k connections
- Batch inference PhoBERT (GPU)
- OpenTelemetry distributed tracing
- Cache invalidation granular
- WebSocket/SSE real-time updates

## Long-term (6+ tháng)

- Migrate JWT sang RS256
- Multi-region deployment
- Auto-scaling
- Advanced hallucination detection
- Custom report templates

</div>
</div>

<div class="warn">

⚠️ Tất cả issues đều có **workaround** và **không block** tiến độ hiện tại. Priority focus: **Monitoring + Testing + Knowledge Export**.

</div>

---

# Kế hoạch tuần tiếp theo

<style scoped>
section { font-size: 23px; }
</style>

<div class="columns">
<div>

## Ưu tiên cao

- [ ] Hoàn thiện **Ingest Service** documentation
- [ ] Hoàn thiện **Project Service** documentation
- [ ] Thiết lập load testing framework (k6)
- [ ] Bắt đầu integration testing cross-service

## Ưu tiên trung bình

- [ ] Prometheus metrics cho Identity + Notification
- [ ] Setup monitoring dashboard (Grafana)
- [ ] Contract testing giữa các services

</div>
<div>

## Timeline tổng quan

```
Phase 1: Foundation (Done)
  Migration Plan v2.13
  Architecture Decisions

Phase 2: Service Design (In Progress)
  Identity Service
  Notification Service
  Analytics Service
  Knowledge Service
  🔄 Ingest Service
  🔄 Project Service

Phase 3: Integration & Testing
  ⏳ Cross-service integration
  ⏳ Load testing
  ⏳ Monitoring setup
```

</div>
</div>

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Q&A

## Câu hỏi & Thảo luận

**Nguyễn Tấn Tài** – SMAP Migration Project

_03/03/2026_
