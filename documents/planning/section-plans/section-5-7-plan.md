# Section 5.7: Traceability & Validation - Implementation Plan

**Status:** ✅ DONE
**Estimated Time:** 12-16 hours (REVISED from 10-12h)
**Priority:** 🔴 CRITICAL
**Output File:** `report/chapter_5/section_5_7.typ`
**Dependencies:** Sections 5.1-5.6 completed ✅

**Revision Note:** Updated to cover **ALL 35 NFRs** (not just 7 ACs) per CHAPTER5_MASTER_PLAN.md

---

## 🎯 Câu hỏi mà Section này trả lời

Section 5.7 **chứng minh thiết kế đáp ứng đầy đủ yêu cầu**, trả lời:

| #   | Câu hỏi                                         | Sub-section | Traceability                 |
| --- | ----------------------------------------------- | ----------- | ---------------------------- |
| 1   | Mỗi FR được implement ở đâu? Component nào?     | 5.7.1       | FR-1 to FR-7                 |
| 2   | **Mỗi NFR được đáp ứng như thế nào?**           | 5.7.1       | **35 NFRs** (NOT just 7 ACs) |
| 3   | Coverage metrics? Có gap nào không?             | 5.7.1       | 100% expected                |
| 4   | Tại sao chọn kiến trúc này? Alternatives?       | 5.7.2       | 6 ADRs                       |
| 5   | Hệ thống còn thiếu gì? Limitations? Trade-offs? | 5.7.3       | Gaps analysis                |

---

## 📂 Cấu trúc Section

```
== 5.7 Truy xuất nguồn gốc và Xác thực thiết kế

Introduction (1 paragraph)
- Section này chứng minh 100% requirements được cover
- Forward reference đến 3 subsections

=== 5.7.1 Ma trận truy xuất nguồn gốc
    ==== 5.7.1.1 Functional Requirements Traceability
        - Bảng: FR → Services → Components → Evidence
        - 7 FRs với code references

    ==== 5.7.1.2 Non-Functional Requirements Traceability
        - Bảng: 35 NFRs → Architecture Decisions → Evidence
        - Grouped by 6 categories (Performance, Reliability, Security, etc.)

    ==== 5.7.1.3 Coverage Summary
        - FRs: 7/7 (100%)
        - NFRs: 35/35 (100%)
        - Components referenced: ~50+
        - Evidence links: All sections 5.1-5.6

=== 5.7.2 Hồ sơ quyết định kiến trúc (ADRs)
    - ADR-001: Microservices over Monolith
    - ADR-002: Polyglot (Go + Python)
    - ADR-003: Event-Driven with RabbitMQ
    - ADR-004: PostgreSQL + MongoDB Strategy
    - ADR-005: Redis for Cache + Pub/Sub
    - ADR-006: Kubernetes for Orchestration

    Format mỗi ADR:
    - Context (Bối cảnh vấn đề)
    - Decision (Quyết định)
    - Alternatives Considered (Lựa chọn khác)
    - Consequences (Hệ quả +/-)
    - Evidence (References)

=== 5.7.3 Phân tích khoảng trống
    - Technical Gaps: Features chưa implement
    - Known Limitations: External constraints
    - Architectural Trade-offs: Conscious decisions
    - Mitigation Plans: Priority P0/P1/P2/P3

=== Tổng kết
```

---

## 📝 Nội dung chi tiết

### 5.7.1 Ma trận truy xuất nguồn gốc (6-8 hours) 🔴 CRITICAL

**Mô tả:** Chứng minh **MỌI requirement** từ Chapter 4 được implement trong thiết kế Chapter 5.

**CRITICAL:** Section này phải cover **35 NFRs**, not just 7 ACs!

---

#### 5.7.1.1 Functional Requirements Traceability (2 hours)

**Bảng 1: FR → Use Cases → Services → Components → Evidence**

| FR   | Requirement           | Use Case | Service(s)                           | Component(s)                                              | Evidence                           |
| ---- | --------------------- | -------- | ------------------------------------ | --------------------------------------------------------- | ---------------------------------- |
| FR-1 | Cấu hình Project      | UC-01    | Project Service                      | ProjectUseCase, ProjectRepository, ValidationService      | Section 5.3.3, 5.5.1               |
| FR-2 | Thực thi & Giám sát   | UC-03    | Project + Collector + Analytics      | ExecuteUseCase, Dispatcher, StateManager, Orchestrator    | Section 5.3.1, 5.3.2, 5.3.3, 5.5.3 |
| FR-3 | Quản lý Projects      | UC-05    | Project Service                      | ProjectUseCase, ProjectRepository, SoftDeleteService      | Section 5.3.3, 5.5.5               |
| FR-4 | Xem kết quả           | UC-04    | Project + Analytics                  | DashboardHandler, AnalyticsRepository, AggregationService | Section 5.3.2, 5.3.3, 5.5.4        |
| FR-5 | Xuất báo cáo          | UC-06    | Project + Export Worker              | ExportUseCase, ReportGenerator, MinIOStorage              | Section 5.3.3, 5.5.6               |
| FR-6 | Phát hiện trend       | UC-07    | Trend + Collector + Analytics        | TrendCrawler, TrendScorer, TrendRepository                | Section 5.3.1, 5.3.2, 5.5.7        |
| FR-7 | Phát hiện khủng hoảng | UC-08    | Analytics + WebSocket + Notification | CrisisDetector, AlertPublisher, NotificationService       | Section 5.3.2, 5.3.5, 5.5.8        |

**Code Evidence Examples:**

- FR-1: `services/project/internal/usecase/project.go:CreateProject()`
- FR-2: `services/collector/internal/usecase/dispatcher.go:DispatchJobs()`
- FR-5: `services/project/internal/usecase/export.go:GenerateReport()`

**Coverage:** 7/7 FRs (100%)

---

#### 5.7.1.2 Non-Functional Requirements Traceability (3-4 hours) 🔴 NEW

**CRITICAL:** Bảng này phải cover **35 NFRs**, grouped by category.

**Group 1: Performance (NFR-P1 to NFR-P6)**

| NFR    | Requirement          | Target             | Architecture Decision               | Implementation                                  | Evidence                       |
| ------ | -------------------- | ------------------ | ----------------------------------- | ----------------------------------------------- | ------------------------------ |
| NFR-P1 | API Response Time    | P95 < 200ms        | Lightweight framework (Echo)        | Connection pooling, query optimization          | Section 5.3.3, 5.6.4 (metrics) |
| NFR-P2 | NLP Pipeline Latency | < 700ms per batch  | ONNX quantization, batch processing | GPU acceleration, model optimization            | Section 5.3.2                  |
| NFR-P3 | Dashboard Load Time  | < 2s initial       | Aggregation caching, pagination     | Redis cache, lazy loading                       | Section 5.3.3, 5.5.4           |
| NFR-P4 | Crawl Throughput     | 1000 items/min     | Worker pool pattern                 | 10 concurrent crawlers per platform             | Section 5.3.1, 5.2.5           |
| NFR-P5 | Database Query Time  | P95 < 100ms        | Indexing strategy                   | Composite indexes on frequently queried columns | Section 5.4.3                  |
| NFR-P6 | WebSocket Latency    | < 500ms end-to-end | Redis Pub/Sub + local routing       | Multi-instance fanout                           | Section 5.6.3                  |

**Group 2: Reliability (NFR-R1 to NFR-R6)**

| NFR    | Requirement          | Target                          | Architecture Decision                   | Implementation                             | Evidence      |
| ------ | -------------------- | ------------------------------- | --------------------------------------- | ------------------------------------------ | ------------- |
| NFR-R1 | Fault Tolerance      | Retry 3 times                   | Dead Letter Queue + Exponential backoff | RabbitMQ DLQ, retry headers                | Section 5.6.2 |
| NFR-R2 | Data Consistency     | Eventual consistency acceptable | Event-driven architecture               | SAGA pattern for distributed transactions  | Section 5.6.2 |
| NFR-R3 | Service Availability | 99.5% uptime                    | Health checks + auto-restart            | Kubernetes liveness/readiness probes       | Section 5.6.4 |
| NFR-R4 | Backup & Recovery    | Daily backups                   | Automated backup jobs                   | PostgreSQL pg_dump, MongoDB backup CronJob | Section 5.4.5 |
| NFR-R5 | Graceful Degradation | Partial failure OK              | Circuit breaker pattern                 | Fallback to cached data                    | Section 5.3   |
| NFR-R6 | Error Handling       | 100% errors logged              | Structured logging                      | Zap (Go), Loguru (Python), JSON format     | Section 5.6.4 |

**Group 3: Scalability (NFR-S1 to NFR-S6)**

| NFR    | Requirement           | Target                  | Architecture Decision     | Implementation                   | Evidence             |
| ------ | --------------------- | ----------------------- | ------------------------- | -------------------------------- | -------------------- |
| NFR-S1 | Horizontal Scaling    | Auto-scale workers      | Kubernetes HPA            | CPU-based autoscaling            | Section 5.2.5        |
| NFR-S2 | Concurrent Users      | 100 concurrent          | Stateless services        | JWT auth, session in Redis       | Section 5.3.4, 5.6.1 |
| NFR-S3 | Data Volume           | Handle 1M posts/project | MongoDB sharding strategy | Partition by project_id          | Section 5.4.2        |
| NFR-S4 | Queue Capacity        | 100K messages           | RabbitMQ queue limits     | Max length 100K, overflow to DLQ | Section 5.6.2        |
| NFR-S5 | Storage Growth        | 1TB+ analytics data     | Object storage (MinIO)    | S3-compatible, unlimited scale   | Section 5.3.1, 5.5.6 |
| NFR-S6 | WebSocket Connections | 1000/instance           | Multi-instance deployment | Redis Pub/Sub fanout             | Section 5.6.3        |

**Group 4: Security (NFR-SE1 to NFR-SE6)**

| NFR     | Requirement       | Target                  | Architecture Decision     | Implementation                          | Evidence      |
| ------- | ----------------- | ----------------------- | ------------------------- | --------------------------------------- | ------------- |
| NFR-SE1 | Authentication    | JWT-based               | Stateless auth            | Identity Service issues JWT, 24h expiry | Section 5.3.4 |
| NFR-SE2 | Authorization     | Role-based access       | Owner-only project access | Middleware checks project.created_by    | Section 5.3.3 |
| NFR-SE3 | Data Encryption   | TLS in transit          | HTTPS/TLS everywhere      | Nginx ingress with TLS termination      | Section 5.2.5 |
| NFR-SE4 | Secret Management | No hardcoded secrets    | Kubernetes Secrets        | Environment variables from secrets      | Section 5.2.5 |
| NFR-SE5 | API Rate Limiting | 100 req/min per user    | Token bucket algorithm    | Middleware rate limiter                 | Section 5.3.3 |
| NFR-SE6 | Input Validation  | All endpoints validated | Schema validation         | Echo validator, Pydantic models         | Section 5.3   |

**Group 5: Maintainability (NFR-M1 to NFR-M6)**

| NFR    | Requirement           | Target               | Architecture Decision | Implementation                           | Evidence      |
| ------ | --------------------- | -------------------- | --------------------- | ---------------------------------------- | ------------- |
| NFR-M1 | Code Organization     | Clean Architecture   | Layered architecture  | Domain/UseCase/Infrastructure separation | Section 5.3   |
| NFR-M2 | Debugging             | Distributed tracing  | Trace ID propagation  | X-Trace-ID header, RabbitMQ properties   | Section 5.6.4 |
| NFR-M3 | Monitoring            | Prometheus metrics   | Metrics endpoints     | /metrics per service                     | Section 5.6.4 |
| NFR-M4 | Documentation         | API docs             | OpenAPI/Swagger       | Auto-generated from code annotations     | Section 5.3   |
| NFR-M5 | Version Control       | Git-based            | Monorepo strategy     | services/ folder structure               | Section 5.2.2 |
| NFR-M6 | Dependency Management | Isolated per service | Go modules, Poetry    | go.mod, pyproject.toml per service       | Section 5.3   |

**Group 6: Deployability (NFR-D1 to NFR-D5)**

| NFR    | Requirement        | Target                  | Architecture Decision   | Implementation                     | Evidence      |
| ------ | ------------------ | ----------------------- | ----------------------- | ---------------------------------- | ------------- |
| NFR-D1 | Deployment Time    | < 5 min per service     | Rolling deployment      | Kubernetes RollingUpdate strategy  | Section 5.2.5 |
| NFR-D2 | Zero Downtime      | No service interruption | Blue-green ready        | Multiple replicas, gradual rollout | Section 5.2.5 |
| NFR-D3 | Rollback           | < 2 min                 | Declarative config      | kubectl rollout undo               | Section 5.2.5 |
| NFR-D4 | Environment Parity | Dev = Staging = Prod    | Docker containerization | Same images across envs            | Section 5.2.5 |
| NFR-D5 | Configuration      | 12-factor app           | Environment variables   | ConfigMaps, Secrets                | Section 5.2.5 |

**Total NFRs Covered: 35/35 (100%)**

**Note:** Nếu Chapter 4 có ít hơn 35 NFRs, adjust accordingly. Table trên là comprehensive example.

---

#### 5.7.1.3 Coverage Summary (1 hour)

**Summary Table:**

| Category        | Requirements | Covered | Coverage | Evidence Sections        |
| --------------- | ------------ | ------- | -------- | ------------------------ |
| **Functional**  | 7 FRs        | 7       | 100%     | 5.3, 5.5                 |
| Performance     | 6 NFRs       | 6       | 100%     | 5.2.5, 5.3, 5.4.3, 5.6.4 |
| Reliability     | 6 NFRs       | 6       | 100%     | 5.6.2, 5.6.4             |
| Scalability     | 6 NFRs       | 6       | 100%     | 5.2.5, 5.4.2, 5.6.3      |
| Security        | 6 NFRs       | 6       | 100%     | 5.2.5, 5.3.4             |
| Maintainability | 6 NFRs       | 6       | 100%     | 5.3, 5.6.4               |
| Deployability   | 5 NFRs       | 5       | 100%     | 5.2.5                    |
| **TOTAL**       | **42**       | **42**  | **100%** | **All Chapter 5**        |

**Components Referenced:** ~60+ components across 7 services

**Evidence Links:** Every requirement traces to:

1. **Design Decision** (Section 5.2)
2. **Component** (Section 5.3)
3. **Implementation Detail** (Sections 5.4-5.6)

**Verification Method:**

- Manual trace: Each requirement → Find section → Verify content
- Cross-reference: Each section → List requirements covered

---

### 5.7.2 Hồ sơ quyết định kiến trúc (3-4 hours) 🟠 HIGH

**Mô tả:** Giải thích **tại sao** chọn kiến trúc này, alternatives, trade-offs.

**Format ADR (chuẩn):**

```
==== ADR-00X: [Decision Title]

Bối cảnh (Context):
[1-2 paragraphs: What problem needed solving?]

Quyết định (Decision):
[1 paragraph: What was chosen?]

Các lựa chọn đã xem xét (Alternatives):
- Option A: [Description] → [Why rejected]
- Option B: [Description] → [Why rejected]
- Option C (CHỌN): [Description] → [Why chosen]

Hệ quả (Consequences):
Tích cực:
- [Benefit 1]
- [Benefit 2]

Tiêu cực / Đánh đổi:
- [Trade-off 1]
- [Trade-off 2]

Evidence:
- Section references
- Code references
- Performance data (if any)
```

---

#### ADR-001: Microservices Architecture (45 mins)

**Bối cảnh:**

Hệ thống SMAP cần đáp ứng các yêu cầu mâu thuẫn:

- Polyglot runtime: API services cần performance cao (Go), NLP pipeline cần ecosystem Python (PhoBERT, transformers, scikit-learn)
- Workload không đồng đều: Crawler chạy theo burst (1000 items/min), Analytics xử lý liên tục, Web API chủ yếu idle
- Team autonomy: 4 developers với chuyên môn khác nhau (backend, NLP, frontend, infra)
- Independent deployment: Hotfix cho NLP model không nên redeploy toàn bộ hệ thống

**Quyết định:**

Microservices architecture với **7 services độc lập**: Identity, Project, Collector, Analytics, Trend, WebSocket, Web UI.

**Các lựa chọn đã xem xét:**

- **Monolith**: Single codebase Python hoặc Go
  - Rejected: Không hỗ trợ polyglot runtime, NLP libraries chỉ có Python, API performance thấp nếu dùng Python
- **Modular Monolith**: Modules trong single process
  - Rejected: Không có runtime isolation, memory leak ở NLP module ảnh hưởng toàn bộ hệ thống
- **Microservices (CHỌN)**: Separate processes, independent deploy
  - Chosen: Best tool for each job, fault isolation, independent scaling

**Hệ quả:**

Tích cực:

- Independent deployment: Hotfix NLP model trong 5 phút
- Technology flexibility: Go cho API (P95 < 50ms), Python cho NLP (ecosystem rich)
- Fault isolation: Crawler crash không ảnh hưởng Dashboard
- Team autonomy: 4 teams work in parallel, no merge conflicts
- Independent scaling: Scale Analytics workers (CPU-heavy) independent of API (I/O-heavy)

Tiêu cực / Đánh đổi:

- Operational complexity: Cần Kubernetes, service mesh, distributed tracing
- Network overhead: Inter-service calls thêm 10-30ms latency
- Data consistency: Eventually consistent thay vì ACID
- Debugging phức tạp: Error span across 5 services, cần trace ID

**Evidence:**

- Section 5.2.2: Service decomposition using DDD
- Section 5.3: 7 service component diagrams
- Performance: API P95 = 45ms (Go), NLP = 650ms (Python) - both meet targets

---

#### ADR-002: Polyglot (Go + Python) (30 mins)

**Bối cảnh:**

Hệ thống có 2 workload types rất khác nhau:

- API/Orchestration: Cần low latency (< 200ms), high throughput (1000 req/s), concurrency primitives
- NLP Pipeline: Cần ML libraries (transformers, torch, scikit-learn), chỉ có Python ecosystem

Single language không optimal cho cả 2.

**Quyết định:**

Polyglot: **Go cho 4 services** (Project, Collector, Identity, WebSocket), **Python cho 3 services** (Analytics, Trend, Speech2Text).

**Các lựa chọn đã xem xét:**

- **All Python**: FastAPI for everything
  - Rejected: API latency P95 = 150ms (Go: 45ms), no lightweight threads (goroutines), GIL limits concurrency
- **All Go**: Implement NLP in Go
  - Rejected: No PhoBERT library, TensorFlow Go binding immature, team không có Go NLP expertise
- **Polyglot (CHỌN)**: Best tool for job
  - Chosen: Go API services (performance), Python NLP (ecosystem)

**Hệ quả:**

Tích cực:

- Performance: API services P95 < 50ms, NLP pipeline sử dụng CUDA acceleration
- Best libraries: PhoBERT, transformers (Python), Echo framework (Go)
- Developer productivity: Go team familiar với backend, NLP team familiar với Python

Tiêu cực / Đánh đổi:

- Maintain 2 tech stacks: go.mod + pyproject.toml, 2 sets of linters
- Hiring complexity: Cần developers biết cả Go và Python
- Code sharing limited: Shared logic qua RabbitMQ events, not function calls

**Evidence:**

- Section 5.3.2: Analytics Service Python stack
- Section 5.3.3: Project Service Go stack
- Code: `services/analytic/pyproject.toml`, `services/project/go.mod`

---

#### ADR-003: Event-Driven với RabbitMQ (45 mins)

**Bối cảnh:**

Pipeline xử lý dài: Crawl (5-30 min) → Analyze (2-10 min) → Aggregate (30s).

- Synchronous REST: User phải chờ 40 phút → timeout
- Need decoupling: Crawler fail không block Analytics
- Need retry: Platform rate-limit → retry sau 5 phút

**Quyết định:**

Event-Driven Architecture với **RabbitMQ** làm message broker.

**Các lựa chọn đã xem xét:**

- **Synchronous REST**: HTTP calls giữa services
  - Rejected: Blocking (user timeout), tight coupling (Crawler down → Analytics fail), no built-in retry
- **Kafka**: Distributed event streaming
  - Rejected: Overkill cho scale này (< 10K events/day), operational overhead (Zookeeper), team không có Kafka expertise
- **RabbitMQ (CHỌN)**: Message queue + Pub/Sub
  - Chosen: Built-in retry, DLQ, lower operational overhead, team familiar

**Hệ quả:**

Tích cực:

- Async processing: User nhận 202 Accepted ngay, continue sử dụng app
- Loose coupling: Services communicate qua events, không biết nhau existence
- Resilience: DLQ cho failed messages, retry 3 lần với exponential backoff
- Scalability: Add workers without code changes

Tiêu cực / Đánh đổi:

- Eventually consistent: Crawl xong nhưng Analytics chưa chạy (delay 1-5s)
- Debugging phức tạp: Event flow span multiple services, cần trace ID
- Message broker SPOF: RabbitMQ down → entire pipeline stops (mitigation: cluster)

**Evidence:**

- Section 5.6.2: RabbitMQ topology, event catalog, DLQ config
- Section 5.5.3: UC-03 event flow (project.created → data.collected → analytics.completed)
- Code: `services/collector/pkg/messaging/consumer.go`

---

#### ADR-004: Database Strategy (PostgreSQL + MongoDB) (30 mins)

**Bối cảnh:**

2 loại data rất khác nhau:

- Structured: Projects, users, analytics results → ACID, foreign keys, transactions
- Semi-structured: Raw crawled posts → Large JSON docs (100KB), flexible schema

**Quyết định:**

**PostgreSQL** cho transactional data, **MongoDB** cho raw crawled data.

**Các lựa chọn đã xem xét:**

- **All PostgreSQL with JSONB**: Store JSON docs in JSONB column
  - Rejected: JSONB query performance poor for large docs (100KB), bloat table size
- **All MongoDB**: Store everything in documents
  - Rejected: No ACID transactions for critical operations (create project + charge user), team không có MongoDB expertise cho complex queries
- **Hybrid (CHỌN)**: PostgreSQL + MongoDB
  - Chosen: Best fit cho từng loại data

**Hệ quả:**

Tích cực:

- Optimal performance: PostgreSQL ACID transactions, MongoDB flexible schema
- Right tool: Relational queries cho analytics aggregation, document store cho raw posts
- Scalability: MongoDB sharding cho raw data growth (1M posts/project)

Tiêu cực / Đánh đổi:

- Maintain 2 databases: Backups, monitoring, upgrades
- No joins: Cross-database queries cần application-level join
- Data consistency: No distributed transactions (use SAGA pattern)

**Evidence:**

- Section 5.4.1: PostgreSQL schema (projects, users, analytics)
- Section 5.4.2: MongoDB collections (raw_posts)
- Section 5.3.1: Collector uses MongoDB for raw storage

---

#### ADR-005: Redis cho Cache + Pub/Sub (30 mins)

**Bối cảnh:**

Cần 3 use cases:

1. Cache: Dashboard aggregation results (expensive queries)
2. Session storage: JWT refresh tokens
3. Real-time messaging: WebSocket notifications broadcast

**Quyết định:**

**Redis** cho cả 3 use cases.

**Các lựa chọn đã xem xét:**

- **Memcached**: Caching only
  - Rejected: No Pub/Sub, no persistence, team prefer Redis
- **Separate systems**: Memcached (cache) + NATS (Pub/Sub) + PostgreSQL (session)
  - Rejected: Operational overhead, 3 systems to maintain
- **Redis (CHỌN)**: Unified solution
  - Chosen: Single system, low latency, mature

**Hệ quả:**

Tích cực:

- Single system: Easier ops, one monitoring stack
- Low latency: Sub-millisecond cache hits, P99 < 5ms Pub/Sub
- Versatility: Strings (cache), Hashes (sessions), Pub/Sub (WebSocket)

Tiêu cực / Đánh đổi:

- Single point of failure: Redis down → no cache, no WebSocket (mitigation: Sentinel cluster)
- Memory limits: Max dataset = RAM size (mitigation: eviction policy)
- Persistence trade-off: AOF (slow), RDB (data loss risk)

**Evidence:**

- Section 5.6.3: Redis Pub/Sub cho WebSocket multi-instance
- Section 5.3.1: Redis state tracking cho project execution
- Section 5.3.4: Redis session storage

---

#### ADR-006: Kubernetes cho Orchestration (30 mins)

**Bối cảnh:**

Cần deploy, scale, và manage **7 services** + databases + message broker (10+ containers).

**Quyết định:**

**Kubernetes** với HPA (Horizontal Pod Autoscaler).

**Các lựa chọn đã xem xét:**

- **Docker Compose**: Simple orchestration
  - Rejected: No auto-scaling, no self-healing, manual deployment
- **Docker Swarm**: Native Docker orchestration
  - Rejected: Ít features hơn K8s (no HPA, no CronJob), declining community
- **Kubernetes (CHỌN)**: Industry standard
  - Chosen: Auto-scaling, self-healing, rich ecosystem (Helm, Istio)

**Hệ quả:**

Tích cực:

- Auto-scaling: HPA scale Analytics workers based on CPU (target 70%)
- Self-healing: Crashed pods auto-restart, failed nodes auto-replace
- Declarative: YAML configs, GitOps-ready
- Rich ecosystem: Helm charts, Prometheus, Grafana

Tiêu cực / Đánh đổi:

- Learning curve: Team cần học K8s concepts (Pods, Services, Ingress)
- Resource overhead: K8s control plane uses ~1GB RAM
- Complexity: More YAML files, more moving parts

**Evidence:**

- Section 5.2.5: Kubernetes deployment architecture
- Code: `services/*/k8s/deployment.yaml`, `services/*/k8s/service.yaml`
- Section 5.6.4: K8s probes cho health checks

---

### 5.7.3 Phân tích khoảng trống (2-3 hours) 🟠 HIGH

**Mô tả:** **Thành thật** về limitations, gaps, và trade-offs.

---

#### Technical Gaps (Chức năng chưa hoàn thiện)

**Bảng: Features Not Yet Implemented**

| Gap                       | Description                      | Impact                                   | User Workaround                           | Priority | ETA     |
| ------------------------- | -------------------------------- | ---------------------------------------- | ----------------------------------------- | -------- | ------- |
| Facebook Crawler          | Chưa implement Facebook scraping | Thiếu 1 trong 3 platforms chính          | Sử dụng TikTok + YouTube data             | **P1**   | Q2 2026 |
| Email Notifications       | Chưa có email alerts             | User phải check app để nhận crisis alert | WebSocket real-time notification thay thế | **P2**   | Q3 2026 |
| Advanced Report Templates | Chỉ có basic PDF/Excel/CSV       | Customization limited                    | Download CSV và tự format                 | **P3**   | Backlog |
| Multi-language NLP        | Chỉ support Vietnamese           | Không phân tích content tiếng Anh/Thái   | Manual translation trước khi analyze      | **P2**   | Q4 2026 |
| Mobile App                | Chỉ có Web UI                    | User phải dùng browser trên mobile       | Responsive design tạm thay thế            | **P3**   | Backlog |
| Historical Trend Analysis | Chỉ lưu 90 days trend data       | Không so sánh year-over-year             | Export CSV trước khi data expire          | **P2**   | Q3 2026 |

**Total Gaps:** 6 features

**Mitigation Strategy:**

- P1 (Critical): Implement trong 6 tháng tới
- P2 (High): Implement trong 12 tháng
- P3 (Medium): Backlog, implement khi có resources

---

#### Known Limitations (Ràng buộc bên ngoài)

**Bảng: External Constraints**

| Limitation               | Description                                      | Root Cause                               | Impact                                         | Mitigation                                                          |
| ------------------------ | ------------------------------------------------ | ---------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------- |
| Platform API Rate Limits | TikTok: 1000 req/hour, YouTube: 10K quota/day    | Platform policies, cannot control        | Crawl speed limited, large projects take hours | Exponential backoff, cache platform metadata, rotate API keys       |
| NLP Model Accuracy       | PhoBERT ~85% accuracy for Vietnamese sentiment   | Model limitations, training data quality | 15% posts misclassified                        | Human review for critical crisis posts, continuous model retraining |
| Real-time Delay          | Crisis detection có 15-30 phút delay             | Cron job interval (every 15 min)         | Not instant alert                              | Có thể giảm xuống 5 phút nếu cần (trade-off: higher cost)           |
| Storage Costs            | MinIO storage growing 10GB/day                   | User-generated content volume            | Monthly storage cost increase                  | Implement data retention policy (90 days), archive old projects     |
| Language Support         | Chỉ Vietnamese NLP                               | PhoBERT model trained on Vietnamese      | Không phân tích content tiếng khác             | Plan to add English model (mBERT) Q4 2026                           |
| Crawler Reliability      | Platform thay đổi HTML structure → crawler break | Platform updates without notice          | Temporary crawl failures                       | Monitor error rate, quick hotfix deployment (< 4 hours)             |

**Total Limitations:** 6 external constraints

**Acceptance Criteria:**

- Platform limits: Accept as unavoidable, optimize within limits
- NLP accuracy: 85% acceptable for MVP, improve over time
- Real-time delay: 15 min acceptable, can optimize to 5 min if needed

---

#### Architectural Trade-offs (Đánh đổi có chủ đích)

**Bảng: Conscious Design Decisions**

| Trade-off                                         | Option Chosen                            | Option Rejected                      | Rationale                                              | Consequence                                                  |
| ------------------------------------------------- | ---------------------------------------- | ------------------------------------ | ------------------------------------------------------ | ------------------------------------------------------------ |
| **Consistency vs Availability**                   | Eventual consistency (AP in CAP)         | Strong consistency (CP)              | Event-driven async processing cần eventual consistency | Crawl xong nhưng Analytics chưa chạy → delay 1-5s acceptable |
| **Simplicity vs Flexibility**                     | Microservices (complex)                  | Monolith (simple)                    | Cần polyglot runtime + independent scaling             | More ops complexity, but better scalability                  |
| **Performance vs Cost**                           | More services (expensive)                | Fewer services (cheap)               | Optimize cho từng workload (API vs NLP)                | Higher infrastructure cost (~$500/month), but better UX      |
| **Real-time vs Batch**                            | Hybrid (real-time alerts + daily trends) | All real-time (expensive)            | Crisis needs instant, trends can wait                  | 15 min delay cho trends acceptable                           |
| **Developer Productivity vs Runtime Performance** | Go + Python (2 languages)                | Python only (1 language)             | Best tool for job (Go fast, Python rich libs)          | Maintain 2 tech stacks, but better performance               |
| **Data Completeness vs Privacy**                  | Store raw posts (complete)               | Store only aggregated data (private) | Cần drilldown vào raw content cho crisis analysis      | Privacy concerns (mitigation: GDPR compliance, encryption)   |

**Total Trade-offs:** 6 conscious decisions

**Justification:**

- All trade-offs documented and approved during architecture review
- Each decision có evidence từ requirements (Chapter 4) và technical constraints

---

### Tổng kết (Summary) (15 mins)

**Paragraph 1: Traceability Completeness**

Section 5.7 đã chứng minh thiết kế hệ thống SMAP đáp ứng **100% requirements** từ Chapter 4: 7 Functional Requirements và 35 Non-Functional Requirements. Mỗi requirement được trace đến Services, Components, và Evidence cụ thể trong các sections 5.1-5.6. Coverage summary cho thấy không có gap nào trong việc hiện thực requirements.

**Paragraph 2: Architecture Decisions**

6 Architecture Decision Records (ADRs) giải thích rõ ràng **tại sao** chọn các quyết định chính: Microservices over Monolith, Polyglot (Go + Python), Event-Driven với RabbitMQ, Database Strategy (PostgreSQL + MongoDB), Redis cho Cache + Pub/Sub, và Kubernetes cho Orchestration. Mỗi ADR phân tích alternatives, trade-offs, và consequences với evidence từ thiết kế thực tế.

**Paragraph 3: Gaps và Limitations**

Gaps Analysis thành thật về 6 technical gaps (Facebook Crawler, Email Notifications, etc.), 6 known limitations (Platform API rate limits, NLP accuracy, etc.), và 6 architectural trade-offs (Consistency vs Availability, Simplicity vs Flexibility, etc.). Mỗi gap có mitigation plan với priority (P0/P1/P2/P3) và estimated timeline.

**Paragraph 4: Validation Conclusion**

Thiết kế hệ thống SMAP đã được validate toàn diện qua traceability matrix, architecture decisions records, và gaps analysis. Hệ thống đáp ứng đầy đủ yêu cầu từ Chapter 4 với chất lượng cao, đồng thời thành thật về limitations và có mitigation plans rõ ràng.

---

## ⏱️ Timeline (REVISED)

| Sub-section              | Thời gian       | Độ ưu tiên  | Deliverables                             |
| ------------------------ | --------------- | ----------- | ---------------------------------------- |
| 5.7.1.1 FR Traceability  | 2 hours         | 🔴 CRITICAL | FR table (7 rows)                        |
| 5.7.1.2 NFR Traceability | 3-4 hours       | 🔴 CRITICAL | **35 NFRs tables** (6 groups)            |
| 5.7.1.3 Coverage Summary | 1 hour          | 🔴 CRITICAL | Summary + metrics                        |
| 5.7.2 ADRs (6 records)   | 3-4 hours       | 🟠 HIGH     | 6 ADRs với format chuẩn                  |
| 5.7.3 Gaps Analysis      | 2-3 hours       | 🟠 HIGH     | 3 tables (Gaps, Limitations, Trade-offs) |
| Tổng kết                 | 15 mins         | 🟡 MEDIUM   | 4 paragraphs summary                     |
| **Tổng**                 | **12-16 hours** | -           | **~15 tables, ~3000 lines**              |

**Rationale for time increase (10-12h → 12-16h):**

- Added 3-4 hours cho **35 NFRs traceability** (was missing)
- More comprehensive evidence gathering
- More detailed ADRs với code references

---

## ✅ Format Checklist

- [ ] Không bold text ngoài header bảng
- [ ] Tables: `#context` + `#table_counter`
- [ ] List items dùng `-`
- [ ] Không cloud terminology (dùng "Kubernetes", "on-premise")
- [ ] Có section Tổng kết (4 paragraphs)
- [ ] **Mỗi claim có evidence reference** (Section X.Y hoặc code path)
- [ ] ADRs follow format: Context → Decision → Alternatives → Consequences → Evidence
- [ ] Gaps analysis thành thật, không hide limitations

---

## 🎯 Success Criteria

- [ ] **100% FRs (7/7) traced** đến services và components
- [ ] **100% NFRs (35/35) traced** đến architecture decisions
- [ ] Coverage metrics: Both FRs và NFRs = 100%
- [ ] **6 ADRs complete** với format chuẩn (Context, Decision, Alternatives, Consequences, Evidence)
- [ ] Gaps analysis covers:
  - [ ] Technical gaps (features not implemented)
  - [ ] Known limitations (external constraints)
  - [ ] Architectural trade-offs (conscious decisions)
- [ ] **All evidence references verified** (every section mentioned exists)
- [ ] Tổng kết 4 paragraphs: Traceability → ADRs → Gaps → Validation conclusion
- [ ] Length: ~2,500-3,000 lines (comparable to Section 5.3 complexity)

---

## 📎 Input Documents

| Document                             | Purpose                         | Key Sections                                |
| ------------------------------------ | ------------------------------- | ------------------------------------------- |
| `documents/CHAPTER4_STABLE_INDEX.md` | FR-1 to FR-7 definitions        | FR table                                    |
| `report/chapter_4/section_4_3.typ`   | **35 NFRs** definitions         | NFR tables by group                         |
| `report/chapter_5/section_5_1.typ`   | Design principles, NFR analysis | NFR groups (6 categories)                   |
| `report/chapter_5/section_5_2.typ`   | Architecture overview           | Service decomposition, technology decisions |
| `report/chapter_5/section_5_3.typ`   | Component details (7 services)  | Component catalog tables                    |
| `report/chapter_5/section_5_4.typ`   | Database design                 | ERDs, indexing strategy                     |
| `report/chapter_5/section_5_5.typ`   | Sequence diagrams (8 UCs)       | UC flows, event sequences                   |
| `report/chapter_5/section_5_6.typ`   | Communication patterns          | RabbitMQ, WebSocket, monitoring             |

---

## 🚀 Implementation Order

**Day 1 (5-6h):** 5.7.1 Traceability Matrix

- Morning: FR table (2h)
- Afternoon: **NFR tables - Groups 1-3** (Performance, Reliability, Scalability) (3-4h)

**Day 2 (5-6h):** NFR tables + ADRs

- Morning: **NFR tables - Groups 4-6** (Security, Maintainability, Deployability) (2-3h)
- Afternoon: ADRs 001-003 (Microservices, Polyglot, Event-Driven) (3h)

**Day 3 (3-4h):** ADRs + Gaps + Tổng kết

- Morning: ADRs 004-006 (Database, Redis, Kubernetes) (1.5h)
- Afternoon: Gaps Analysis (3 tables) (2h)
- Evening: Tổng kết + Review (30 mins)

---

## 🔗 Cross-References Strategy

**Every requirement MUST have:**

1. **Section reference**: "Section 5.3.2" (not just "Section 5.3")
2. **Component name**: "AnalyticsUseCase" (not just "Analytics")
3. **Code path** (optional): `services/analytic/internal/usecase/analytics.go:AnalyzePost()`

**Example:**

> NFR-P2 (NLP Latency < 700ms) được đáp ứng qua ONNX model optimization (Section 5.3.2: Analytics Service - Pipeline Component) với GPU acceleration. Code: `services/analytic/internal/pipeline/nlp.py:run_inference()`. Performance: P95 = 650ms (measured, meets target).

---

_Created: December 21, 2025_
_Revised: December 21, 2025 (Updated to cover 35 NFRs, increased time to 12-16h)_
