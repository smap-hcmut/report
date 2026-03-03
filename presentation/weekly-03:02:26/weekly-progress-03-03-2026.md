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
| **Analytics Service** (Python) |  Refactored   | AI Pipeline (Python), Kafka, PhoBERT, YAKE, spaCy     |
| **Knowledge Service**          | Done Phase 1  | RAG, Qdrant Vector DB, Gemini LLM                     |
| **Project Service**            |    Pending    | CRUD Project/Campaign, Crisis Detection logic          |
| **Ingest Service**             |  In-progress  | Integration Module, AI Schema Agent (Onboarding)      |
| **Migration Plan**             |     v2.13     | Chốt kiến trúc 6 Backend + 1 UI                       |

---

# Identity Service (Auth)

<style scoped>
section { font-size: 24px; }
</style>

<div class="columns">
<div>

## Hiện trạng & Thách thức

- Chưa test E2E thực tế trên tập dữ liệu lớn.
- Các tính năng tự động tạo Báo cáo (Report Generation) đang trong giai đoạn hoàn thiện logic Map-Reduce.
- Token window management: Đang sử dụng ước lượng thô, cần tối ưu hóa chính xác hơn.
- OAuth2 login flow (Google Integration)
- JWT token generation & internal validation
- RBAC: ADMIN / ANALYST / VIEWER mapping
- Audit logging flow (Async via Kafka)

</div>
<div>

## Tech Stack

| Component | Technology                     |
| --------- | ------------------------------ |
| Language  | Go 1.25.4                      |
| Framework | Gin 1.11.0                     |
| Database  | PostgreSQL (`schema_identity`) |
| Cache     | Redis (session, blacklist)     |
| Auth      | Google OAuth2 + JWT HS256      |

</div>
</div>

---

## Technical Contract (Interface)

<style scoped>
section { font-size: 24px; }
</style>

- `GET /authentication/login` – OAuth2 redirect
- `GET /authentication/callback` – Token issuance
- `GET /authentication/me` – User identity retrieval
- `POST /internal/validate` – S2S Token Validation
- **Kafka:** `audit.events` (Topic publisher)

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

- WebSocket connection manager (JWT logic)
- Redis Pub/Sub subscriber (Multi-channel)
- Discord integration (Rich Embeds Alert)
- Project-level message routing

## Technical Contract (Interface)

- `GET /ws?token=...` – WebSocket Handshake
- **Redis Channels:**
  - `project:{id}:user:{uid}`
  - `alert:crisis:user:{uid}`
- **Alert:** Discord Webhook API integration

</div>
<div>

## Tech Stack

| Component | Technology            |
| --------- | --------------------- |
| Language  | Go                    |
| Framework | Standard Library / WS |
| Cache     | Redis Pub/Sub         |
| Push      | Discord API           |

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

- Context-aware Semantic Search (Qdrant)
- RAG Chat integration (Gemini 1.5-pro)
- 3-Tier Caching (Embedding/Campaign/Search)
- Vector Indexing worker (UAP input)

## Technical Contract (Interface)

- `POST /api/v1/search` – Semantic Search
- `POST /api/v1/chat` – Multi-turn RAG Q&A
- `POST /internal/index/by-file` – Batch Index
- **Kafka:** `analytics.batch.completed` (Consumer)

</div>
<div>

## Tech Stack

| Component | Technology            |
| --------- | --------------------- |
| Language  | Go                    |
| Vector DB | Qdrant                |
| Embedding | Voyage AI / OpenAI    |
| LLM       | Gemini 1.5-pro        |
| Storage   | MinIO (Artifacts)     |

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

| #   | Issue (từ Report)                    | Severity |
| --- | ------------------------------------ | :------: |
| 1   | HS256 JWT – Rủi ro lộ shared secret  |  Medium  |
| 2   | Audit log query chậm khi data >1M    |  Low     |

</div>
<div>

## Notification Service

| #   | Issue (từ Report)                    | Severity |
| --- | ------------------------------------ | :------: |
| 1   | Push-only (Không nhận data ngược lại)|  Low     |
| 2   | Connection leak khi ngắt kết nối đột ngột|  Medium  |

</div>
</div>

---

<style scoped>
section { font-size: 26px; }
</style>

<div class="columns">

<div>

## Analytics Service

| #   | Issue (từ Report)                    | Severity |
| --- | ------------------------------------ | :------: |
| 1   | Phase 6: Legacy Cleanup CHƯA BẮT ĐẦU |  Medium  |
| 2   | Hiệu năng PhoBERT bị giới hạn trên CPU|  Low     |

</div>
<div>

## Knowledge Service

| #   | Issue (từ Report)                    | Severity |
| --- | ------------------------------------ | :------: |
| 1   | Thiếu kiểm thử E2E với data thực tế  |  HIGH    |
| 2   | Tính năng Report Gen chưa hoàn thiện |  HIGH    |
| 3   | Ước lượng Token window còn thô       |  Medium  |

</div>
</div>

---

# Vấn đề – Cross-cutting & Bugs (2/3)

<style scoped>
section { font-size: 21px; }
</style>

<div class="columns">
<div>

## Cross-cutting Issues

| Vấn đề (Technical Debt)       | Impact                  |  Status  |
| ----------------------------- | ----------------------- | :------: |
| **Thiếu Distributed Tracing** | Khó debug cross-service |   Todo   |
| **Redis Single Instance**     | SPOF cho toàn hệ thống  |   Todo   |
| **Test Coverage thấp**        | Risk regression bugs    | Partial  |

</div>
<div>

## Security & Reliability

| Bug                                         | Service      | Severity |
| ------------------------------------------- | ------------ | :------: |
| **#45** Connection leak on disconnect       | Notification |  Medium  |
| **#001** Kafka producer buffer flush delay  | Analytics    |  Medium  |
| **#001** OAuth state cleanup missing        | Identity     |   Low    |

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

## Short-term (Tháng 3/2026 - Sprint 1)

- Hoàn thiện **Ingest & Project Service** code-base.
- E2E Integration: Ingest -> Analytics -> Knowledge.
- Triển khai **Woodpecker CI** & ArgoCD.
- Fix bugs bảo mật (JWT risk, connection leaks).

</div>
<div>

## Mid-term (Tháng 4/2026 - Sprint 2)

- **Report Generation:** Full feature implementation.
- Security Hardening (Key Rotation, RS256).
- Load Testing & Performance Tuning.
- Triển khai Prometheus/Grafana monitoring.

## Final Milestone (Tháng 5/2026)

- **Thesis Documentation & Report.**
- System Verification & Final Audit.
- **Graduation Defense.**

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
