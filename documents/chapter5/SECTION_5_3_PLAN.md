# 📋 SƯỜN VÀ KẾ HOẠCH CHI TIẾT: SECTION 5.3 - THIẾT KẾ CHI TIẾT CÁC DỊCH VỤ

**Ngày tạo:** 2025-12-20  
**Mục đích:** Sườn và dự định viết chi tiết cho Section 5.3 - Component Diagrams (C4 Level 3)  
**Tham chiếu:** CHAPTER5_MASTER_PLAN.md, WRITING-GUIDE.md, 4.5.6.md

---

## 📊 HIỆN TRẠNG SECTION 5.3

### File hiện tại

- **`report/chapter_5/section-extra.typ`**: Chứa Sequence Diagrams (5.3) - ✅ Đã hoàn thành
- **`report/chapter_5/index.typ`**: 
  - Import `section_5_3.typ` như "service_decomposition" (file chưa tồn tại)
  - Import `section-extra.typ` như "sequence" (Sequence Diagrams)

### Vấn đề cần giải quyết

Theo **CHAPTER5_MASTER_PLAN.md**, Section 5.3 nên là **"Thiết kế chi tiết các dịch vụ"** với **Component Diagrams (C4 Level 3)**, không phải Sequence Diagrams.

**Giải pháp đề xuất:**
- **Section 5.3**: Component Diagrams (C4 Level 3) - Thiết kế chi tiết các dịch vụ
- **Section 5.3.8** (hoặc section riêng): Sequence Diagrams - Giữ nguyên nội dung từ `section-extra.typ`

---

## 🎯 CẤU TRÚC SECTION 5.3 (THEO MASTER_PLAN)

### Tổng quan

Section 5.3 mô tả **cấu trúc nội bộ** của từng service ở cấp độ Component (C4 Level 3), làm rõ:
- Các components bên trong mỗi service
- Trách nhiệm của từng component
- Cách các components tương tác với nhau
- Design patterns được áp dụng
- Performance characteristics

### Cấu trúc chi tiết

```
5.3 Thiết kế chi tiết các dịch vụ
│
├─ 5.3.1 Identity Service (Component Diagram + Flow)
├─ 5.3.2 Project Service (Component Diagram + Flow)
├─ 5.3.3 Collection Service (Component Diagram + Master-Worker Pattern)
├─ 5.3.4 Analytics Service (Component Diagram + NLP Pipeline)
├─ 5.3.5 Speech2Text Service (Component Diagram + ASR Flow)
├─ 5.3.6 WebSocket Service (Component Diagram + Real-time Architecture)
└─ 5.3.7 Web UI (Component Diagram + Frontend Architecture)
```

**Lưu ý:** Sequence Diagrams (hiện tại trong `section-extra.typ`) có thể:
- Option A: Giữ nguyên trong `section-extra.typ` và đổi tên section thành 5.3.8
- Option B: Tách thành section riêng (5.4 hoặc 5.5) nếu cần

---

## 📝 TEMPLATE CHO MỖI SERVICE (Theo WRITING-GUIDE.md)

### Cấu trúc chuẩn cho mỗi service (5.3.X)

```markdown
=== 5.3.X [Service Name] - Component Diagram

==== Context

[1-2 câu mô tả vai trò của service trong hệ thống]
- Vai trò trong kiến trúc tổng thể (Section 5.2)
- Link đến Use Cases liên quan (Chapter 4)
- Link đến FRs/NFRs được đáp ứng

==== Component Diagram (C4 Level 3)

[Vẽ diagram với các components nội bộ]

**Components cần identify từ code:**
1. Entry point (main.go, main.py, app.py)
2. API layer (routers, controllers, handlers)
3. Business logic (usecase/, services/, domain/)
4. Data access (repository/, models/, database/)
5. External integrations (clients/, adapters/, infrastructure/)
6. Utilities (utils/, helpers/, common/)

**Diagram Structure:**
- Presentation Layer (API endpoints, handlers)
- Application Layer (Use cases, business logic)
- Domain Layer (Domain models, business rules)
- Infrastructure Layer (Repositories, external clients)

==== Component Catalog

| Component | Responsibility | Input | Output | Technology | Performance |
|-----------|----------------|-------|--------|------------|-------------|
| [Component 1] | [Trách nhiệm] | [Input] | [Output] | [Tech] | [Metric] |
| ... | ... | ... | ... | ... | ... |

==== Data Flow

[Mô tả luồng xử lý chính với sequence hoặc flow chart]

```
1. [Step 1 với timing]
   ↓
2. [Step 2 với timing]
   ↓
   ...
```

==== Design Patterns Applied

- Pattern 1: [Where applied] → [Benefit]
- Pattern 2: [Where applied] → [Benefit]

**Patterns cần identify:**
- Clean Architecture (Layered structure)
- Port and Adapter Pattern (Interface-based design)
- Repository Pattern (Data access abstraction)
- Factory Pattern (Object creation)
- Strategy Pattern (Algorithm selection)
- Observer Pattern (Event handling)

==== Performance Characteristics

[Metrics với evidence từ Chapter 4.3 và actual measurements]

| Metric | Value | Target | Status | Evidence |
|--------|-------|--------|--------|-----------|
| [Metric 1] | [Value] | [Target] | ✅/⚠️/❌ | [Source] |
| ... | ... | ... | ... | ... |

==== Key Decisions

- Decision 1: [What] → [Why] → [Evidence]
- Decision 2: [What] → [Why] → [Evidence]

**Decisions cần document:**
- Technology choices (framework, libraries)
- Architecture patterns (layered, hexagonal, etc.)
- Data access strategies (ORM, raw SQL, etc.)
- Error handling approaches
- Caching strategies

==== Dependencies

**Internal Dependencies:**
- [Service/Component 1]: [Why needed]
- [Service/Component 2]: [Why needed]

**External Dependencies:**
- [Database/Queue/Storage]: [Usage pattern]
- [Third-party API]: [Integration purpose]

==== Summary

[Key takeaways - 3-5 bullet points]
- Component structure và responsibilities
- Design patterns và benefits
- Performance metrics và achievements
- Link forward đến sections khác
```

---

## 🔍 CHI TIẾT TỪNG SERVICE

### 5.3.1 Identity Service

**Priority:** 🟠 HIGH  
**Time Estimate:** 3 hours  
**Complexity:** Medium

**Components cần identify (từ `services/identity/`):**
- API Layer: HTTP handlers (Gin), routes, middleware
- Application Layer: UseCase (user, auth), business logic
- Domain Layer: User model, Role model, Token model
- Infrastructure Layer: PostgreSQL repository, JWT generator, Password hasher
- External: JWT validation, HttpOnly cookie management

**Key Features:**
- Authentication (Login, Logout)
- Authorization (Role-based access)
- User management (CRUD)
- Session management (Refresh tokens)

**Design Patterns:**
- Clean Architecture (Layered)
- Repository Pattern (Data access)
- Strategy Pattern (Password hashing strategies)

**Performance Targets (from Chapter 4):**
- Auth check: < 10ms (AC-3)
- Login response: < 500ms (AC-3)

**Links:**
- FR-1: Authentication & Authorization
- UC-01: User login flow
- Section 5.2.2: Identity Service trong Container Diagram

---

### 5.3.2 Project Service

**Priority:** 🟠 HIGH  
**Time Estimate:** 3 hours  
**Complexity:** Medium

**Components cần identify (từ `services/project/`):**
- API Layer: HTTP handlers, routes (Gin)
- Application Layer: ProjectUsecase, WebhookUsecase, StateUsecase
- Domain Layer: Project model, Competitor model, KeywordSet model
- Infrastructure Layer: PostgreSQL repository, Redis client, RabbitMQ publisher
- External: Event publishing (`project.created`)

**Key Features:**
- Project CRUD operations
- Project execution (UC-03)
- Event publishing (RabbitMQ)
- State management (Redis)

**Design Patterns:**
- Clean Architecture (Layered)
- Event-Driven Architecture (RabbitMQ events)
- Distributed State Management (Redis SSOT)

**Performance Targets:**
- Project creation: < 500ms (AC-3)
- Event publishing: < 100ms (AC-3)

**Links:**
- FR-1: Cấu hình Project (UC-01)
- FR-2: Thực thi & Giám sát Project (UC-03)
- Section 5.2.2: Project Service trong Container Diagram

---

### 5.3.3 Collection Service

**Priority:** 🔴 CRITICAL  
**Time Estimate:** 4 hours  
**Complexity:** High (Master-Worker Pattern)

**Components cần identify (từ `services/collector/` và `services/scrapper/`):**
- API Layer: HTTP handlers (Gin)
- Application Layer: DispatcherUsecase, ProjectEventConsumer
- Domain Layer: CrawlJob model, JobStatus model
- Infrastructure Layer: PostgreSQL repository, RabbitMQ consumer/publisher, Redis client
- Workers: TikTok Worker, YouTube Worker (Python)
- Supporting Services: FFmpeg Service, Playwright Service

**Key Features:**
- Job dispatching (Master-Worker pattern)
- Progress tracking (Redis state)
- Event consumption (`project.created`)
- Event publishing (`data.collected`)

**Design Patterns:**
- Master-Worker Pattern (Job distribution)
- Event-Driven Architecture (RabbitMQ)
- Distributed State Management (Redis)

**Performance Targets:**
- Throughput: 1,000 items/min with 10 workers (AC-2)
- Job dispatch: < 50ms (AC-3)

**Links:**
- FR-2: Thực thi & Giám sát Project (UC-03)
- UC-02: Dry-run (sampling strategy)
- UC-03: Execution (full crawl)
- Section 5.2.2: Collector + Scrapper Services

---

### 5.3.4 Analytics Service

**Priority:** 🔴 CRITICAL  
**Time Estimate:** 4 hours  
**Complexity:** High (NLP Pipeline)

**Components cần identify (từ `services/analytic/`):**
- API Layer: FastAPI endpoints, health checks
- Application Layer: AnalyticsOrchestrator, EventConsumer
- Domain Layer: Preprocessing, IntentClassifier, KeywordExtractor, SentimentAnalyzer, ImpactCalculator
- Infrastructure Layer: PostgreSQL repository, MinIO client, RabbitMQ consumer
- ML Models: PhoBERT (sentiment), PhoBERT-NER (entities), LDA (topics)

**Key Features:**
- NLP Pipeline (5 steps: Preprocessing → Intent → Keyword → Sentiment → Impact)
- Batch processing (20-50 items/batch)
- Event consumption (`data.collected`)
- Result persistence (PostgreSQL)

**Design Patterns:**
- Pipeline Pattern (NLP stages)
- Batch Processing (Efficiency)
- Event-Driven Architecture (RabbitMQ)

**Performance Targets:**
- Throughput: ~70 items/min/worker (AC-2)
- NLP response time: < 700ms (p95) (AC-3)

**Links:**
- FR-2: Analyzing phase (UC-03)
- UC-03: Analytics pipeline execution
- Section 5.2.2: Analytics Service

---

### 5.3.5 Speech2Text Service

**Priority:** 🟡 MEDIUM  
**Time Estimate:** 3 hours  
**Complexity:** Medium

**Components cần identify (từ `services/speech2text/`):**
- API Layer: FastAPI endpoints
- Application Layer: TranscriptionUsecase
- Domain Layer: AudioProcessor, WhisperModel
- Infrastructure Layer: MinIO client (audio storage), RabbitMQ publisher
- ML Model: Whisper (OpenAI)

**Key Features:**
- Audio/video transcription
- MinIO integration (audio retrieval)
- Event publishing (`transcription.completed`)

**Design Patterns:**
- Port and Adapter Pattern (ITranscriber interface)
- Event-Driven Architecture (RabbitMQ)

**Performance Targets:**
- Transcription: < 5s for 1-minute audio (AC-3)

**Links:**
- FR-2: Video analysis (UC-03)
- Section 5.2.2: Speech2Text Service

---

### 5.3.6 WebSocket Service

**Priority:** 🟠 HIGH  
**Time Estimate:** 3 hours  
**Complexity:** Medium

**Components cần identify (từ `services/websocket/`):**
- API Layer: WebSocket handlers (Gorilla WebSocket)
- Application Layer: ConnectionManager, MessageHandler
- Domain Layer: Connection model, Message model
- Infrastructure Layer: Redis Pub/Sub client
- External: Redis Pub/Sub (topic: `project:{projectID}:{userID}`)

**Key Features:**
- Real-time communication (WebSocket)
- Connection management (1,000+ concurrent)
- Redis Pub/Sub integration
- Progress updates (UC-06)

**Design Patterns:**
- Observer Pattern (Redis Pub/Sub)
- Connection Pooling (WebSocket management)

**Performance Targets:**
- WebSocket latency: < 100ms (p95) (AC-3)
- Concurrent connections: 1,000+ (AC-2)

**Links:**
- FR-2: Real-time progress tracking (UC-06)
- UC-06: Progress updates
- Section 5.2.2: WebSocket Service

---

### 5.3.7 Web UI

**Priority:** 🟡 MEDIUM  
**Time Estimate:** 2 hours  
**Complexity:** Low-Medium

**Components cần identify (từ `services/web-ui/`):**
- Presentation Layer: React components, pages
- Application Layer: API clients, state management (Zustand/Redux)
- Infrastructure Layer: Next.js API routes, WebSocket client
- External: REST API calls, WebSocket connections

**Key Features:**
- Dashboard (project management)
- Real-time updates (WebSocket)
- Report generation UI (UC-04)
- Authentication UI (login, logout)

**Design Patterns:**
- Component-based Architecture (React)
- Server-Side Rendering (Next.js SSR)
- Client-Side State Management (Zustand/Redux)

**Performance Targets:**
- Dashboard loading: < 3s (NFR-UX-1)
- Initial load: < 2s (NFR-UX-2)

**Links:**
- All UCs (UI entry points)
- Section 5.2.2: Web UI

---

## 📋 CHECKLIST CHO MỖI SERVICE

Trước khi hoàn thành mỗi service, kiểm tra:

- [ ] **WHAT:** Đã mô tả rõ components và responsibilities?
- [ ] **WHY:** Đã giải thích lý do tổ chức như vậy?
- [ ] **DIAGRAM:** Có Component Diagram (C4 Level 3)?
- [ ] **CATALOG:** Có bảng Component Catalog đầy đủ?
- [ ] **DATA FLOW:** Có mô tả luồng xử lý chính?
- [ ] **PATTERNS:** Đã identify và giải thích design patterns?
- [ ] **PERFORMANCE:** Có metrics với evidence?
- [ ] **DECISIONS:** Đã document key decisions?
- [ ] **DEPENDENCIES:** Đã list internal và external dependencies?
- [ ] **TRACE:** Đã link đến FRs/NFRs và Use Cases?
- [ ] **SUMMARY:** Có phần tóm tắt key takeaways?

---

## 🔧 CÁCH THỨC THỰC HIỆN

### Bước 1: Scan Code Structure

Với mỗi service, scan:
```
services/[service-name]/
├── internal/          # Internal packages
│   ├── api/          # API layer
│   ├── usecase/      # Business logic
│   ├── repository/   # Data access
│   └── model/        # Domain models
├── pkg/              # Shared packages
├── main.go/main.py   # Entry point
├── go.mod/pyproject.toml  # Dependencies
└── README.md         # Documentation
```

### Bước 2: Identify Components

Sử dụng `codebase_search` và `grep` để:
- Tìm entry points
- Identify API routes/handlers
- Extract use cases
- List repositories
- Find external integrations

### Bước 3: Create Component Diagram

Vẽ diagram theo C4 Level 3:
- Use Mermaid hoặc ASCII art
- Show layers (Presentation → Application → Domain → Infrastructure)
- Show connections between components
- Mark external dependencies

### Bước 4: Document Components

Tạo Component Catalog table:
- Component name
- Responsibility
- Input/Output
- Technology
- Performance metrics

### Bước 5: Document Patterns & Decisions

Identify và document:
- Design patterns applied
- Key architectural decisions
- Trade-offs và rationale

### Bước 6: Link to Requirements

Trace đến:
- Functional Requirements (FRs)
- Non-Functional Requirements (NFRs)
- Use Cases (UCs)
- Previous sections (5.1, 5.2)

---

## 📊 TIMELINE & PRIORITY

| Service | Priority | Time | Complexity | Order |
|---------|----------|------|------------|-------|
| 5.3.3 Collection Service | 🔴 CRITICAL | 4h | High | 1 |
| 5.3.4 Analytics Service | 🔴 CRITICAL | 4h | High | 2 |
| 5.3.2 Project Service | 🟠 HIGH | 3h | Medium | 3 |
| 5.3.1 Identity Service | 🟠 HIGH | 3h | Medium | 4 |
| 5.3.6 WebSocket Service | 🟠 HIGH | 3h | Medium | 5 |
| 5.3.5 Speech2Text Service | 🟡 MEDIUM | 3h | Medium | 6 |
| 5.3.7 Web UI | 🟡 MEDIUM | 2h | Low-Medium | 7 |
| **TOTAL** | - | **22 hours** | - | - |

---

## ✅ SUCCESS CRITERIA

### Must Have (for 9/10 score)

- [ ] All 7 services documented với Component Diagrams
- [ ] Component Catalog đầy đủ cho mỗi service
- [ ] Design patterns identified và explained
- [ ] Performance metrics với evidence
- [ ] Traceability đến FRs/NFRs/UCs

### Nice to Have (for 10/10 score)

- [ ] Sequence diagrams cho complex flows (có thể reuse từ `section-extra.typ`)
- [ ] Code snippets cho key components
- [ ] Detailed performance analysis
- [ ] Comparison với alternatives

---

## 📚 REFERENCES

- **CHAPTER5_MASTER_PLAN.md**: Overall structure và timeline
- **WRITING-GUIDE.md**: Templates và academic standards
- **4.5.6.md**: Example Component Diagrams (Analytics, Collection)
- **Section 5.2**: Container Diagrams (context cho Component Diagrams)
- **Chapter 4**: Requirements và Use Cases (traceability)

---

## 🚀 NEXT STEPS

1. **Start with 5.3.3 (Collection Service)** - Highest priority, most complex
2. **Then 5.3.4 (Analytics Service)** - Critical, complex NLP pipeline
3. **Continue với các services còn lại** theo priority order
4. **Review và refine** sau khi hoàn thành tất cả
5. **Integrate với Sequence Diagrams** (từ `section-extra.typ`) nếu cần

---

**End of Plan**  
**Ready to execute:** Start with 5.3.3 (Collection Service)  
**Questions:** Refer to WRITING-GUIDE.md for templates

---

_Generated by: AI Assistant_  
_Date: December 20, 2025_  
_Purpose: Detailed plan for Section 5.3 - Component Diagrams (C4 Level 3)_

