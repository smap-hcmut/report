# 📋 MASTER PLAN: CHƯƠNG 5 - THIẾT KẾ HỆ THỐNG SMAP

## DETAILED ACTION PLAN FOR CHAPTER 5 COMPLETION

**Created:** December 20, 2025  
**Status:** 🟡 In Planning  
**Target:** Complete Chapter 5 with evidence-based system design documentation

---

## 📊 CURRENT STATE ASSESSMENT

### What We Have

#### 1. **Existing Documentation** (`documents/chapter5/`)

- ✅ `4.5.1.md` - Giới thiệu & Phương pháp (1003 lines) - **OUTDATED**
- ✅ `4.5.2.md` - Architecture Style Selection (309 lines) - **OUTDATED**
- ✅ `4.5.3.md` - Service Decomposition (210 lines) - **OUTDATED**
- ⚠️ `4.5.4.md` - Placeholder (needs content)
- ⚠️ `4.5.5.md` - Placeholder (needs content)
- ⚠️ `4.5.6.md` - Placeholder (needs content)
- ⚠️ `4.5.7.md` - Placeholder (needs content)
- ✅ `WRITING-GUIDE.md` - Comprehensive writing guidelines
- ✅ `README-PLACEHOLDERS.md` - Status tracking

#### 2. **Report Structure** (`report/chapter_5/`)

- ✅ `index.typ` - Chapter index (imports 4 sections)
- ✅ `section_5_1.typ` - Introduction (114 lines) - **NEEDS UPDATE**
- ⚠️ `section_5_2.typ` - System Architecture Overview
- ⚠️ `section_5_3.typ` - Sequence Diagrams
- ⚠️ `section_5_4.typ` - ERD

#### 3. **Source Code** (Up-to-date)

- ✅ `services/identity/` - Golang Identity Service
- ✅ `services/project/` - Golang Project Service
- ✅ `services/collector/` - Golang Collection Service
- ✅ `services/analytic/` - Python Analytics Service
- ✅ `services/scrapper/` - Python Scrapper Services (TikTok, YouTube)
- ✅ `services/speech2text/` - Python Speech2Text Service
- ✅ `services/websocket/` - Golang WebSocket Service
- ✅ `services/web-ui/` - Next.js Frontend

#### 4. **Chapter 4 Reference** (Stable & Complete)

- ✅ `CHAPTER4_STABLE_INDEX.md` - Complete index
- ✅ Functional Requirements (FR-1 to FR-7)
- ✅ Non-Functional Requirements (7 ACs Primary + 3 Secondary)
- ✅ Use Cases (UC-01 to UC-08)

---

## 🎯 CHAPTER 5 STRUCTURE (Following C4 Model)

### Proposed Structure

```
CHƯƠNG 5: THIẾT KẾ HỆ THỐNG
│
├─ 5.1 Giới thiệu và phương pháp tiếp cận ⚠️ (Needs update to 8 principles)
│   ├─ 5.1.1 Nguyên tắc thiết kế (8 principles grouped into 4 categories):
│   │   ├─ Core Principles: DDD, Microservices, Event-Driven
│   │   ├─ Data Patterns: Claim Check, Distributed State Management (Redis)
│   │   ├─ Code Quality: SOLID, Port & Adapter Pattern
│   │   └─ Observability: Observability-Driven Development
│   └─ 5.1.2 Phương pháp mô hình hóa (C4 Model: Context → Container → Component → Code)
│
├─ 5.2 Kiến trúc tổng thể ⚠️ (Major work needed)
│   ├─ 5.2.1 Lựa chọn Architecture Style (Microservices vs Monolith vs Modular Monolith)
│   ├─ 5.2.2 Phân rã hệ thống (Service Decomposition: DDD → Bounded Contexts → Services)
│   ├─ 5.2.3 System Context Diagram (C4 Level 1)
│   ├─ 5.2.4 Container Diagram (C4 Level 2)
│   └─ 5.2.5 Technology Stack & Justification
│
├─ 5.3 Thiết kế chi tiết các dịch vụ ⚠️ (Major work needed)
│   ├─ 5.3.1 Identity Service (Component Diagram + Flow)
│   ├─ 5.3.2 Project Service (Component Diagram + Flow)
│   ├─ 5.3.3 Collection Service (Component Diagram + Master-Worker Pattern)
│   ├─ 5.3.4 Analytics Service (Component Diagram + NLP Pipeline)
│   ├─ 5.3.5 Speech2Text Service (Component Diagram + ASR Flow)
│   ├─ 5.3.6 WebSocket Service (Component Diagram + Real-time Architecture)
│   └─ 5.3.7 Web UI (Component Diagram + Frontend Architecture)
│
├─ 5.4 Thiết kế cơ sở dữ liệu ⚠️ (Major work needed)
│   ├─ 5.4.1 Database Strategy (PostgreSQL, MongoDB, Redis, MinIO)
│   ├─ 5.4.2 ERD per Service (Identity, Project, Analytics)
│   └─ 5.4.3 Data Management Patterns ⚠️ NEW
│       ├─ Database per Service (No foreign keys across services)
│       ├─ Distributed State Management (Redis HASH: smap:proj:{id}, TTL 24h)
│       ├─ Claim Check Pattern (MinIO + RabbitMQ references)
│       ├─ Event Sourcing (Light version via RabbitMQ)
│       └─ CQRS (Light version: PostgreSQL write, Redis read)
│
├─ 5.5 Mẫu giao tiếp & tích hợp ⚠️ (New section)
│   ├─ 5.5.1 Communication Patterns (REST, Event-Driven, Claim Check)
│   ├─ 5.5.2 RabbitMQ Topology (Event schemas: project.created, data.collected, analysis.finished, job.completed)
│   ├─ 5.5.3 Real-time Communication (WebSocket + Redis Pub/Sub)
│   └─ 5.5.4 Monitoring & Alerting ⚠️ NEW (Observability-Driven Development)
│       ├─ Structured Logging (Zap for Go, Loguru for Python)
│       ├─ Prometheus Metrics (Counters, Histograms, Gauges)
│       ├─ Health Checks (Shallow + Deep)
│       └─ Distributed Tracing (Trace ID propagation)
│
└─ 5.6 Traceability & Validation ⚠️ (New section)
    ├─ 5.6.1 Traceability Matrix (FR/NFR → Services → Components → Evidence)
    ├─ 5.6.2 Architecture Decision Records (ADRs)
    └─ 5.6.3 Gaps Analysis (Technical debts, known limitations, roadmap)
```

---

## 📝 DETAILED TASK BREAKDOWN

### PHASE 1: FOUNDATION (Days 1-3) - Priority: 🔴 CRITICAL

#### Task 1.1: Update Section 5.1 ✅

**Status:** Minor updates needed  
**Time:** 2 hours

- [ ] **1.1.1** Review current `section_5_1.typ` (114 lines)
- [ ] **1.1.2** Cross-reference with Chapter 4 NFRs
- [ ] **1.1.3** Update NFR priorities table with actual metrics
- [ ] **1.1.4** Verify C4 Model introduction aligns with subsequent sections
- [ ] **1.1.5** Add forward references to sections 5.2-5.6

**Deliverable:** Updated `section_5_1.typ`

---

#### Task 1.2: Create Section 5.2 - Kiến trúc tổng thể 🔴

**Status:** Major work  
**Time:** 16-20 hours

**Sub-task 1.2.1: Lựa chọn Architecture Style (4 hours)**

**Input Sources:**

- `documents/chapter5/4.5.2.md` (309 lines - OUTDATED)
- Chapter 4: AC-1 (Modularity), AC-2 (Scalability), AC-3 (Performance)

**Steps:**

1. [ ] Review outdated 4.5.2.md for structure
2. [ ] Scan ALL services code to identify ACTUAL architecture:
   ```
   - services/identity/    → Verify independence
   - services/project/     → Verify independence
   - services/collector/   → Check Master-Worker pattern
   - services/analytic/    → Check Python FastAPI structure
   - services/websocket/   → Check real-time architecture
   ```
3. [ ] Create comparison table: Monolith vs Modular Monolith vs Microservices
4. [ ] Add **EVIDENCE** section:
   - Number of services: 7 (count from actual code)
   - Technology diversity: Go (4 services), Python (3 services), Next.js (1)
   - Independent deployment: List Docker images from docker-compose files
   - Performance metrics: Reference Chapter 4 AC-3 targets
5. [ ] Write ADR-001: "Why Microservices for SMAP?"
   - Context: Polyglot runtime (Go + Python), asymmetric workload
   - Decision: Microservices
   - Alternatives: Monolith (rejected - polyglot issue), Modular Monolith (rejected - no runtime isolation)
   - Evidence: Link to actual services, performance benchmarks

**Deliverable:** `section_5_2_1_architecture_style.typ` with ADR-001

---

**Sub-task 1.2.2: Phân rã hệ thống (Service Decomposition) (4 hours)**

**Input Sources:**

- `documents/chapter5/4.5.3.md` (210 lines - OUTDATED)
- Actual service folders structure

**Steps:**

1. [ ] Scan all service folders to create ACTUAL Bounded Contexts map:
   ```
   - Identity Context     → services/identity/
   - Project Context      → services/project/
   - Collection Context   → services/collector/ + services/scrapper/
   - Analytics Context    → services/analytic/ + services/speech2text/
   - Real-time Context    → services/websocket/
   - UI Context           → services/web-ui/
   ```
2. [ ] For EACH Bounded Context, extract from code:

   - Main entities (from database models)
   - Core responsibilities (from README, main.go, or main entry points)
   - Technology stack (from go.mod, pyproject.toml, package.json)
   - Dependencies (from imports, Dockerfile, docker-compose)

3. [ ] Create Service Responsibility Matrix (table):

   ```
   | Service | Type | Responsibility | Data Ownership | Dependencies | Tech Stack |
   ```

4. [ ] Validate against DDD principles:
   - High Cohesion: Each service owns a clear business domain
   - Low Coupling: Services communicate via events/APIs, not direct DB access
   - Independent Deployability: Each has own Dockerfile

**Deliverable:** `section_5_2_2_service_decomposition.typ` with evidence from code

---

**Sub-task 1.2.3: System Context Diagram (C4 Level 1) (3 hours)**

**Steps:**

1. [ ] Identify ALL external actors/systems by scanning code:

   - From `services/web-ui/`: User types (Marketing Analyst)
   - From `services/collector/`, `services/scrapper/`: External platforms (TikTok API, YouTube Data API)
   - From `services/identity/`: Authentication (JWT, OAuth if any)
   - From `services/websocket/`: Real-time notification systems
   - Check for email/SMS integrations

2. [ ] Create System Context Diagram (use Mermaid or PlantUML):

   ```
   Actors: Marketing Analyst, Admin
   External Systems: TikTok, YouTube, Facebook, Email Service, Push Notification
   SMAP System: (black box)
   ```

3. [ ] Write description for each connection (protocol, data type)

**Deliverable:** `section_5_2_3_context_diagram.typ` with diagram + table

---

**Sub-task 1.2.4: Container Diagram (C4 Level 2) (5 hours)**

**Steps:**

1. [ ] List ALL containers by scanning code:

   ```
   From docker-compose files:
   - Web Application (Next.js)
   - API Gateway (Nginx reverse proxy)
   - Identity Service (Golang)
   - Project Service (Golang)
   - Collection Service (Golang + Dispatcher)
   - Crawler Workers (Python: TikTok, YouTube)
   - Analytics Service (Python FastAPI)
   - Speech2Text Service (Python)
   - WebSocket Service (Golang)
   - PostgreSQL (multiple databases)
   - MongoDB (raw data)
   - Redis (cache + pub/sub)
   - RabbitMQ (message broker)
   - MinIO (object storage)
   ```

2. [ ] For EACH container, extract:

   - Technology (language, framework, version from code)
   - Port (from docker-compose, config files)
   - Responsibility (from README, code structure)
   - Connections (from config files, environment variables)

3. [ ] Create Container Diagram (Mermaid C4 or PlantUML):

   - Show all containers
   - Show connections with protocols (HTTP, gRPC, AMQP, Redis Pub/Sub)
   - Group by bounded context (use color coding)

4. [ ] Add container catalog table:
   ```
   | Container | Technology | Responsibility | Protocols | Persistence |
   ```

**Deliverable:** `section_5_2_4_container_diagram.typ` with diagram + catalog

---

**Sub-task 1.2.5: Technology Stack & Justification (4 hours)**

**Steps:**

1. [ ] Scan ALL tech from code:

   ```
   Languages:
   - Golang (from go.mod files): versions
   - Python (from pyproject.toml): versions
   - TypeScript/JavaScript (from package.json)

   Frameworks:
   - Gin (Go web framework)
   - FastAPI (Python API framework)
   - Next.js (React framework)

   Databases:
   - PostgreSQL (from docker-compose: versions, databases list)
   - MongoDB (from docker-compose)
   - Redis (from docker-compose: cache + pub/sub)

   Infrastructure:
   - RabbitMQ (message broker)
   - MinIO (S3-compatible storage)
   - Kubernetes (from k8s/ folders)

   AI/ML Libraries:
   - From services/analytic/pyproject.toml
   - From services/speech2text/pyproject.toml
   ```

2. [ ] For EACH technology, create justification entry:

   - Technology: [Name + Version]
   - Category: [Language/Framework/Database/Infrastructure]
   - Why Chosen: [3-5 specific reasons from code evidence]
   - Alternatives Rejected: [List + why rejected]
   - Trade-offs: [Pros/Cons with evidence]
   - Evidence: [Link to code, performance metrics, cost analysis]

3. [ ] Create Technology Decision Matrix (table)

4. [ ] Add Cost Analysis (if available):
   - On-premise vs Cloud comparison
   - Reference from Chapter 4 AC-5 (Deployability)

**Deliverable:** `section_5_2_5_technology_stack.typ` with decision matrix

---

### PHASE 2: DETAILED DESIGN (Days 4-7) - Priority: 🟠 HIGH

#### Task 2.1: Create Section 5.3 - Thiết kế chi tiết các dịch vụ 🟠

**Status:** Major work  
**Time:** 24-28 hours (7 services × 3-4 hours each)

**Template for EACH Service (3-4 hours per service):**

```markdown
### 5.3.X [Service Name] Component Diagram

#### Context

[1-2 câu mô tả vai trò của service trong hệ thống]

#### Component Diagram (C4 Level 3)

[Vẽ diagram với các components nội bộ]

Components to identify from code:

1. Entry point (main.go, main.py, app.py)
2. API layer (routers, controllers)
3. Business logic (usecase/, services/)
4. Data access (repository/, models/)
5. External integrations (clients/, adapters/)
6. Utilities (utils/, helpers/)

#### Component Catalog

| Component | Responsibility | Input | Output | Technology | Performance |
| --------- | -------------- | ----- | ------ | ---------- | ----------- |
| ...       | ...            | ...   | ...    | ...        | ...         |

#### Data Flow

[Sequence diagram hoặc flow chart cho main use case]

#### Design Patterns Applied

- Pattern 1: [Where] → [Benefit]
- Pattern 2: [Where] → [Benefit]

#### Performance Characteristics

[Metrics với evidence từ Chapter 4.3]

#### Key Decisions

- Decision 1: [What] → [Why] → [Evidence]
```

**Services to Document (Order by priority):**

1. [ ] **5.3.1 Identity Service** (3h)

   - Scan `services/identity/internal/` for structure
   - Extract: auth flow, JWT generation, password hashing
   - Performance: < 10ms auth check (from AC-3)

2. [ ] **5.3.2 Project Service** (3h)

   - Scan `services/project/internal/` for structure
   - Extract: project CRUD, event publishing
   - Link to UC-01 (Cấu hình Project)

3. [ ] **5.3.3 Collection Service** (4h) - COMPLEX

   - Scan `services/collector/internal/` for Master-Worker pattern
   - Scan `services/scrapper/` for actual crawlers
   - Extract: dispatcher logic, job queue, rate limiting
   - Link to UC-02 (Dry-run), UC-03 (Execution)
   - Performance: 1,000 items/min with 10 workers (from AC-2)

4. [ ] **5.3.4 Analytics Service** (4h) - COMPLEX

   - Scan `services/analytic/` for NLP pipeline
   - Extract: preprocessing, intent, keyword, sentiment, impact (5 steps)
   - Link to FR-2 (Analyzing phase)
   - Performance: ~70 items/min/worker, < 700ms NLP (from AC-3)

5. [ ] **5.3.5 Speech2Text Service** (3h)

   - Scan `services/speech2text/` for ASR flow
   - Extract: audio processing pipeline
   - Link to video analysis features

6. [ ] **5.3.6 WebSocket Service** (3h)

   - Scan `services/websocket/internal/` for real-time architecture
   - Extract: connection management, Redis Pub/Sub integration
   - Link to UC-06 (Real-time progress), FR-2 (progress tracking)
   - Performance: < 100ms delivery, 1,000 concurrent connections (from AC-3)

7. [ ] **5.3.7 Web UI** (2h)
   - Scan `services/web-ui/components/` for architecture
   - Extract: component structure, state management, API integration
   - Link to all UCs (UI entry points)

**Deliverable:** 7 files: `section_5_3_1.typ` to `section_5_3_7.typ`

---

### PHASE 3: DATA DESIGN (Days 8-10) - Priority: 🟠 HIGH

#### Task 3.1: Create Section 5.4 - Thiết kế cơ sở dữ liệu 🟠

**Status:** Major work  
**Time:** 20-24 hours

**Sub-task 3.1.1: Database Strategy (4 hours)**

**Steps:**

1. [ ] Scan docker-compose files to list ALL databases:

   ```
   PostgreSQL databases:
   - identity_db
   - project_db
   - analytics_db
   - (list all from docker-compose)

   MongoDB databases:
   - (list collections from code)

   Redis usage:
   - Cache (keys pattern)
   - Pub/Sub (topics pattern)

   MinIO buckets:
   - (list from code/config)
   ```

2. [ ] For EACH database, explain:

   - Why this database type for this data?
   - Read/Write patterns
   - Consistency requirements
   - Scalability strategy

3. [ ] Create Database Strategy Matrix:
   ```
   | Service | Database | Type | Why Chosen | Data Characteristics |
   ```

**Deliverable:** `section_5_4_1_database_strategy.typ`

---

**Sub-task 3.1.2-3.1.6: Create ERDs (4 hours each service)**

**For EACH service's database:**

1. [ ] **Extract schema from code:**

   - Golang: from `models/`, `repository/`, migration files
   - Python: from `models/`, SQLAlchemy models, Alembic migrations

2. [ ] **Create ERD:**

   - Use Mermaid ER diagram syntax
   - Show entities, attributes, relationships
   - Mark primary keys, foreign keys, indexes

3. [ ] **Add table descriptions:**

   ```
   | Table | Purpose | Key Columns | Indexes | Constraints |
   ```

4. [ ] **Explain relationships:**
   - One-to-Many, Many-to-Many
   - Referential integrity
   - Cascade behavior

**Services to document:**

- [ ] 5.4.2 Identity Service ERD (4h)
- [ ] 5.4.3 Project Service ERD (4h)
- [ ] 5.4.4 Collection Service ERD (MongoDB - document structure) (3h)
- [ ] 5.4.5 Analytics Service ERD (4h) - COMPLEX (post_analytics JSONB)
- [ ] 5.4.6 Data Management Patterns (3h)

**For 5.4.6 Data Management Patterns:**

- Event Sourcing (if used)
- CQRS (if used)
- Cache Strategy (Redis keys pattern, TTL strategy)
- Data lifecycle (retention, archival)

**Deliverable:** 6 files: `section_5_4_1.typ` to `section_5_4_6.typ`

---

### PHASE 4: COMMUNICATION & INTEGRATION (Days 11-12) - Priority: 🟡 MEDIUM

#### Task 4.1: Create Section 5.5 - Mẫu giao tiếp & tích hợp 🟡

**Status:** New section  
**Time:** 12-16 hours

**Sub-task 4.5.1: Communication Patterns (4 hours)**

**Steps:**

1. [ ] Scan code for ALL communication types:

   ```
   REST APIs:
   - From services/*/internal/api/
   - List endpoints, methods, payload formats

   gRPC (if any):
   - Check for .proto files
   - List service definitions

   Event-Driven:
   - From RabbitMQ usage in code
   - List events: project.created, data.collected, etc.
   ```

2. [ ] Create Communication Pattern Matrix:
   ```
   | Pattern | When Used | Services | Protocol | Trade-offs |
   | REST | Synchronous request/response | API Gateway → Services | HTTP/JSON | Simple but blocking |
   | Event-Driven | Async workflows | Project → Collection → Analytics | AMQP | Resilient but complex |
   | WebSocket | Real-time updates | WebSocket Service → UI | WebSocket | Low latency but stateful |
   ```

**Deliverable:** `section_5_5_1_communication_patterns.typ`

---

**Sub-task 4.5.2: Event-Driven Architecture (4 hours)**

**Steps:**

1. [ ] Scan RabbitMQ usage in code:

   - Publishers: which services publish which events
   - Consumers: which services consume which events
   - Message format: payload structure

2. [ ] Create Event Catalog:

   ```
   | Event Name | Publisher | Consumer(s) | Payload | When Triggered |
   | project.created | Project Service | Collection Service | {projectId, ...} | UC-03 step 4 |
   | data.collected | Collection Service | Analytics Service | {jobId, dataRef} | After crawling |
   ```

3. [ ] Document RabbitMQ topology:
   - Exchanges
   - Queues
   - Bindings
   - Dead Letter Queue (if any)

**Deliverable:** `section_5_5_2_event_driven.typ`

---

**Sub-task 4.5.3: API Design Principles (2 hours)**

**Steps:**

1. [ ] Extract API conventions from code:

   - URL patterns
   - HTTP methods
   - Status codes
   - Error format
   - Versioning strategy

2. [ ] Create API Design Guidelines table

**Deliverable:** `section_5_5_3_api_design.typ`

---

**Sub-task 4.5.4: Real-time Communication (3 hours)**

**Steps:**

1. [ ] Scan WebSocket Service + Redis Pub/Sub:

   - Connection lifecycle
   - Topic patterns: `project:{projectID}:{userID}`
   - Message types

2. [ ] Create Real-time Architecture Diagram

3. [ ] Link to UC-06 (Progress tracking)

**Deliverable:** `section_5_5_4_realtime_communication.typ`

---

### PHASE 5: TRACEABILITY & VALIDATION (Days 13-14) - Priority: 🔴 CRITICAL

#### Task 5.1: Create Section 5.6 - Traceability & Validation 🔴

**Status:** New section (ESSENTIAL for evidence)  
**Time:** 12-16 hours

**Sub-task 5.6.1: Traceability Matrix (8 hours)**

**This is THE MOST IMPORTANT section for "đủ dẫn chứng"!**

**Steps:**

1. [ ] Create FR → Services → Components → Evidence table:

   ```
   | FR ID | Description | Service | Component | Evidence |
   | FR-1 | Cấu hình Project | Project Service | ProjectUsecase | UC-01, section 5.3.2 |
   | FR-2 | Thực thi & Giám sát | Project + Collection + Analytics | ExecuteUC + Dispatcher + Orchestrator | UC-03, section 5.3.3, 5.3.4 |
   | ... | ... | ... | ... | ... |
   ```

2. [ ] Create NFR → Architecture Decisions → Evidence table:

   ```
   | NFR ID | Description | Target | Decision | How Addressed | Evidence |
   | AC-1 | Modularity | I ≈ 0, Ce < 5 | Microservices | 7 independent services | Section 5.2.2, actual code |
   | AC-2 | Scalability | 1,000 items/min | Horizontal scaling | Kubernetes HPA | Section 5.2.5, docker-compose |
   | AC-3 | Performance | NLP < 700ms | Pipeline optimization | Measured in production | Section 5.3.4, metrics |
   | ... | ... | ... | ... | ... | ... |
   ```

3. [ ] Calculate coverage:
   - FRs covered: X/7 (100% expected)
   - NFRs covered: X/10 (100% expected)

**Deliverable:** `section_5_6_1_traceability_matrix.typ`

---

**Sub-task 5.6.2: Architecture Decision Records (4 hours)**

**Steps:**

1. [ ] Document ALL major ADRs:

   - ADR-001: Microservices over Monolith
   - ADR-002: Polyglot (Go + Python)
   - ADR-003: Event-Driven with RabbitMQ
   - ADR-004: PostgreSQL for transactional, MongoDB for raw data
   - ADR-005: Redis for cache + pub/sub
   - ADR-006: Kubernetes for orchestration

2. [ ] Use ADR template from WRITING-GUIDE.md

**Deliverable:** `section_5_6_2_architecture_decisions.typ`

---

**Sub-task 5.6.3: Gaps Analysis (4 hours)**

**Steps:**

1. [ ] Identify gaps by comparing:

   - Chapter 4 requirements vs implemented features
   - Planned architecture vs actual code

2. [ ] Create Gaps tables:

   - Technical Gaps (features not yet implemented)
   - Known Limitations (external constraints)
   - Architectural Trade-offs (conscious decisions)

3. [ ] For each gap, provide:
   - Impact (🔴/🟠/🟡/🟢)
   - Priority (P0/P1/P2/P3)
   - Mitigation plan
   - ETA

**Deliverable:** `section_5_6_3_gaps_analysis.typ`

---

## 🎯 SUCCESS CRITERIA

### Must Have (for 9/10 score)

- [ ] All FR/NFR traced to implementation (Traceability Matrix complete)
- [ ] All major services documented with Component Diagrams (C4 L3)
- [ ] All databases documented with ERDs
- [ ] Architecture decisions justified with alternatives + evidence
- [ ] Gaps honestly identified with mitigation plans

### Nice to Have (for 10/10 score)

- [ ] Performance metrics from actual measurements
- [ ] Cost analysis (On-premise vs Cloud)
- [ ] Sequence diagrams for complex flows
- [ ] API documentation with examples

---

## 📅 TIMELINE SUMMARY

| Phase                      | Tasks                            | Duration    | Priority    |
| -------------------------- | -------------------------------- | ----------- | ----------- |
| **Phase 1: Foundation**    | 5.1, 5.2 (Architecture Overview) | 3 days      | 🔴 CRITICAL |
| **Phase 2: Services**      | 5.3 (7 Component Diagrams)       | 4 days      | 🟠 HIGH     |
| **Phase 3: Data**          | 5.4 (ERDs + Strategy)            | 3 days      | 🟠 HIGH     |
| **Phase 4: Communication** | 5.5 (Patterns + Events)          | 2 days      | 🟡 MEDIUM   |
| **Phase 5: Validation**    | 5.6 (Traceability + ADRs)        | 2 days      | 🔴 CRITICAL |
| **TOTAL**                  | 29 files + diagrams              | **14 days** | -           |

---

## 📂 OUTPUT FILES (29 files total)

```
report/chapter_5/
├── section_5_1.typ ✅ (update)
├── section_5_2.typ (new - combines 5 sub-sections):
│   ├── 5_2_1_architecture_style.typ
│   ├── 5_2_2_service_decomposition.typ
│   ├── 5_2_3_context_diagram.typ
│   ├── 5_2_4_container_diagram.typ
│   └── 5_2_5_technology_stack.typ
├── section_5_3.typ (new - combines 7 sub-sections):
│   ├── 5_3_1_identity_service.typ
│   ├── 5_3_2_project_service.typ
│   ├── 5_3_3_collection_service.typ
│   ├── 5_3_4_analytics_service.typ
│   ├── 5_3_5_speech2text_service.typ
│   ├── 5_3_6_websocket_service.typ
│   └── 5_3_7_web_ui.typ
├── section_5_4.typ (new - combines 6 sub-sections):
│   ├── 5_4_1_database_strategy.typ
│   ├── 5_4_2_erd_identity.typ
│   ├── 5_4_3_erd_project.typ
│   ├── 5_4_4_erd_collection.typ
│   ├── 5_4_5_erd_analytics.typ
│   └── 5_4_6_data_patterns.typ
├── section_5_5.typ (new - combines 4 sub-sections):
│   ├── 5_5_1_communication_patterns.typ
│   ├── 5_5_2_event_driven.typ
│   ├── 5_5_3_api_design.typ
│   └── 5_5_4_realtime_communication.typ
└── section_5_6.typ (new - combines 3 sub-sections):
    ├── 5_6_1_traceability_matrix.typ
    ├── 5_6_2_architecture_decisions.typ
    └── 5_6_3_gaps_analysis.typ
```

---

## 🔧 TOOLS & RESOURCES

### Code Scanning Tools

- `codebase_search`: Semantic search for understanding architecture
- `grep`: Find specific patterns (imports, models, APIs)
- `read_file`: Read actual implementation files
- `list_dir`: Discover service structures

### Diagram Tools

- Mermaid (for diagrams in Typst)
- C4 Model syntax
- PlantUML (if needed)

### Reference Documents

- `WRITING-GUIDE.md` - Follow templates for each section
- `CHAPTER4_STABLE_INDEX.md` - Source of truth for requirements
- Actual service code - Source of truth for implementation

---

## ✅ QUALITY CHECKLIST (Per Section)

Before marking a section complete:

- [ ] **WHAT:** Described component/decision clearly?
- [ ] **WHY:** Explained reason for choosing this approach?
- [ ] **ALTERNATIVES:** Compared with other options?
- [ ] **TRADE-OFFS:** Listed pros/cons with evidence?
- [ ] **EVIDENCE:** Provided specific data (metrics, code refs)?
- [ ] **DIAGRAMS:** Included visual aids where needed?
- [ ] **TRACE:** Linked back to Chapter 4 requirements?
- [ ] **SUMMARY:** Key takeaways listed?

---

## 🚀 GETTING STARTED

### Recommended Order:

1. **Start with Phase 1, Task 1.2.1** (Architecture Style)

   - This sets the foundation for everything else
   - 4 hours, HIGH impact

2. **Then Phase 1, Task 1.2.2** (Service Decomposition)

   - Defines all services to document
   - 4 hours, HIGH impact

3. **Then Phase 2** (Component Diagrams for 7 services)

   - This is the bulk of the work
   - Can be done in parallel if multiple people

4. **Phase 5, Task 5.1** (Traceability Matrix) - CRITICAL

   - This proves "đủ dẫn chứng"
   - 8 hours, HIGHEST impact

5. **Other phases** as time permits

---

## 💡 KEY PRINCIPLES

### Evidence-Based Writing

- Every claim must have code reference or metric
- No "hand-waving" (e.g., "performance is good" ❌)
- Specific numbers (e.g., "< 700ms NLP p95" ✅)

### Traceability

- Every FR/NFR must trace to code
- Every service must justify its existence
- Every decision must have alternatives comparison

### Honesty

- Document gaps and limitations
- Explain trade-offs transparently
- Provide mitigation plans

---

**End of Plan**  
**Ready to execute:** Start with Phase 1, Task 1.2.1  
**Questions:** Refer to WRITING-GUIDE.md for templates

---

_Generated by: AI Assistant_  
_Date: December 20, 2025_  
_Purpose: Master plan for completing Chapter 5 with evidence-based documentation_
