# Project Service - Complete Specification

**Phiên bản:** 2.1 (Crisis Detection + Adaptive Crawl Redesign)  
**Ngày cập nhật:** 20/02/2026  
**Repo:** project-srv (Go)  
**Tác giả:** System Architect

---

## MỤC LỤC

1. [Tổng quan](#1-tổng-quan)
2. [Vai trò và Trách nhiệm](#2-vai-trò-và-trách-nhiệm)
3. [Entity Hierarchy](#3-entity-hierarchy)
4. [State Machine](#4-state-machine)
5. [Modules và API](#5-modules-và-api)
6. [Adaptive Crawl](#6-adaptive-crawl)
7. [Crisis Detection](#7-crisis-detection)
8. [Dashboard Orchestration](#8-dashboard-orchestration)
9. [Implementation Status](#9-implementation-status)
10. [Deployment Checklist](#10-deployment-checklist)

---

## 1. TỔNG QUAN

### 1.1 Định nghĩa

Project Service là **"Orchestration Brain"** của hệ thống SMAP Enterprise - bộ não điều phối trung tâm chịu trách nhiệm:

- **Lifecycle Management:** Quản lý vòng đời của Campaign và Project
- **Adaptive Crawl Controller:** Điều khiển thu thập thích ứng dựa trên metrics

### 1.2 Tech Stack

```yaml
Language: Go
Framework: Gin (HTTP), Kafka (Events)
Database: PostgreSQL (schema_project.* schema)
Cache: Redis (optional, for dashboard)
Message Queue: Kafka
```

---

## 2. VAI TRÒ VÀ TRÁCH NHIỆM

### 2.1 Project Service vs Ingest Service

**Nguyên tắc phân chia:**

| Aspect             | Project Service (Brain)               | Ingest Service (Executor)         |
| ------------------ | ------------------------------------- | --------------------------------- |
| **Role**           | Decision Maker                        | Task Executor                     |
| **Responsibility** | WHAT, WHEN, WHY                       | HOW                               |
| **Data Sources**   | Manage metadata (config, schedule)    | Execute actual ingestion          |
| **File Upload**    | Trigger upload flow, validate         | Parse file, transform to UAP      |
| **Crawl**          | Schedule crawl jobs, decide frequency | Call external API, fetch data     |
| **Webhook**        | Generate webhook URL, manage config   | Receive webhook, validate payload |
| **Adaptive**       | Consume metrics, decide mode          | Execute crawl with new frequency  |
| **State**          | Manage project state machine          | Report job status back            |
| **Database**       | schema_project.\* (metadata)          | schema_ingest.\* (execution logs) |

**CRITICAL: Data Source Ownership**

```
DATA SOURCE = Thực thể của INGEST SERVICE

┌─────────────────────────────────────────────────────────────────┐
│  WHO CREATES DATA SOURCE?                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Frontend] User clicks "Add Data Source"                       │
│      ↓                                                          │
│  [Project Service] Validate project exists                      │
│      ↓                                                          │
│  [Project Service] Call Ingest Service API:                     │
│      POST /ingest/sources                                       │
│      {                                                          │
│        project_id: "proj_vf8",                                  │
│        name: "TikTok VF8",                                      │
│        source_type: "TIKTOK",                                   │
│        config: {...}                                            │
│      }                                                          │
│      ↓                                                          │
│  [Ingest Service] CREATE data source:                           │
│      - Generate ID: gen_random_uuid()                           │
│      - INSERT schema_ingest.data_sources                        │
│      - Return: {id: "src_tiktok_01", status: "PENDING"}        │
│      ↓                                                          │
│  [Project Service] Store reference:                             │
│      - Cache source_id in memory (optional)                     │
│      - OR query Ingest Service when needed                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Database Schema Ownership:**

```sql
-- INGEST SERVICE owns this table
CREATE TABLE schema_ingest.data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Ingest Service generates
    project_id UUID NOT NULL,  -- Reference to Project Service
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(20) NOT NULL,
    source_category VARCHAR(10) NOT NULL DEFAULT 'passive',

    -- Config
    config JSONB,

    -- Adaptive Crawl (only for crawl sources)
    crawl_mode VARCHAR(20) DEFAULT 'NORMAL',
    crawl_interval_minutes INT DEFAULT 11,
    next_crawl_at TIMESTAMPTZ,

    -- Metrics
    last_crawl_at TIMESTAMPTZ,
    last_crawl_metrics JSONB,
    baseline_metrics JSONB,

    -- Status
    status VARCHAR(20) DEFAULT 'PENDING',
    onboarding_status VARCHAR(20),
    dryrun_status VARCHAR(20),
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project Service does NOT have a data_sources table
-- It queries Ingest Service via HTTP API or Kafka events
```

**Why Ingest Service owns Data Sources?**

1. **Separation of Concerns:**
   - Project Service = Business logic (projects, campaigns)
   - Ingest Service = Data ingestion logic (sources, crawling)

2. **Scalability:**
   - Ingest Service can scale independently
   - Can have multiple Ingest Service instances

3. **Domain Boundaries:**
   - Data Source lifecycle tied to ingestion execution
   - Ingest Service knows best about crawl status, errors, metrics

### 2.2 Core Responsibilities

```
┌─────────────────────────────────────────────────────────────────┐
│           PROJECT SERVICE - ORCHESTRATION BRAIN                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. LIFECYCLE MANAGEMENT                                        │
│     ✓ Quản lý state machine của Project                         │
│     ✓ Validate state transitions                                │
│     ✓ Enforce business rules                                    │
│     ✓ Audit trail cho mọi state change                          │
│                                                                 │
│  2. DATA INGESTION ORCHESTRATION                                │
│     ✓ Quyết định WHEN to ingest (schedule, on-demand)           │
│     ✓ Quyết định HOW to ingest (profile, strategy)              │
│     ✓ Quyết định WHAT to ingest (sources, filters)              │
│     ✓ Publish commands → Ingest Service                         │
│                                                                 │
│  3. ADAPTIVE CRAWL CONTROLLER                                   │
│     ✓ Consume metrics từ Analytics Service                      │
│     ✓ Calculate baseline (7-day averages)                       │
│     ✓ Determine crawl mode (Sleep/Normal/Crisis)                │
│     ✓ Publish mode change events                                │
│                                                                 │
│  4. INTEGRATION HUB                                             │
│     ✓ Coordinate Ingest, Analytics, Knowledge, Notification     │
│     ✓ Aggregate dashboard data từ Analytics                     │
│     ✓ Trigger crisis alerts qua Notification                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. ENTITY HIERARCHY

### 3.1 Mô hình 3 tầng

```
Tầng 3: CAMPAIGN (Logical Analysis Unit)
  ├── Project "Monitor VF8"  (brand=VinFast)
  └── Project "Monitor BYD Seal" (brand=BYD)
  → RAG scope: WHERE project_id IN ('VF8', 'BYD Seal')

Tầng 2: PROJECT (Entity Monitoring Unit)
  ├── brand: "VinFast"
  ├── entity_type: "product"
  ├── entity_name: "VF8"
  ├── Data Source: Excel Feedback T1
  ├── Data Source: TikTok Crawl "vinfast vf8"
  └── Data Source: Webhook từ CRM
  → Health Check: Dashboard riêng cho entity VF8

Tầng 1: DATA SOURCE (Physical Data Unit)
  ├── Raw File: feedback_t1.xlsx
  ├── Schema Mapping: AI Agent suggested
  └── Output: 500 UAP records
  → Normalization: Biến raw data thành UAP
```

### 3.2 Multi-Source per Project

**Nguyên tắc:** Một Project có thể có NHIỀU Data Sources với các loại khác nhau, hoạt động song song và độc lập.

**Ví dụ thực tế:**

```
Project "Monitor VF8" (1 Project - theo dõi thương hiệu VF8)
│
├── Data Source 1: "Feedback Q1 2026" (FILE_UPLOAD)
│   ├─ Type: Excel file upload
│   ├─ File: feedback_q1.xlsx (500 dòng)
│   ├─ Status: COMPLETED (upload 1 lần xong)
│   └─ Purpose: Phân tích feedback từ khách hàng
│
├── Data Source 2: "TikTok VF8" (CRAWL)
│   ├─ Type: TikTok crawl
│   ├─ Keywords: "vinfast vf8", "vf8 review"
│   ├─ Status: ACTIVE, NORMAL mode (crawl mỗi 11 phút)
│   └─ Purpose: Thu thập mentions từ TikTok
│
├── Data Source 3: "CRM Webhook" (WEBHOOK)
│   ├─ Type: Webhook từ CRM
│   ├─ URL: https://smap.com/webhook/proj_vf8/crm
│   ├─ Status: ACTIVE (nhận real-time)
│   └─ Purpose: Nhận complaints từ CRM system
│
└── Data Source 4: "YouTube VF8" (CRAWL)
    ├─ Type: YouTube crawl
    ├─ Keywords: "vinfast vf8"
    ├─ Status: ACTIVE, CRISIS mode (crawl mỗi 2 phút)
    └─ Purpose: Thu thập video reviews
```

**Quan hệ:**

```
1 PROJECT (Entity Monitoring Unit)
  = Monitor 1 entity (VF8)
  = Có NHIỀU Data Sources (Excel + TikTok + Webhook + YouTube)
  = Tất cả data từ các sources này được gộp lại để phân tích VF8

1 DATA SOURCE (Physical Data Unit)
  = 1 nguồn dữ liệu cụ thể
  = Có lifecycle riêng (PENDING → READY → ACTIVE → COMPLETED/PAUSED)
  = Có type riêng (FILE_UPLOAD, CRAWL, WEBHOOK)
```

**Lifecycle độc lập:**

| Source Type             | Lifecycle  | Schedule       | Adaptive Crawl | Ví dụ                                 |
| ----------------------- | ---------- | -------------- | -------------- | ------------------------------------- |
| FILE_UPLOAD             | One-time   | Manual         | ❌ KHÔNG       | User upload feedback_q1.xlsx 1 lần    |
| WEBHOOK                 | Continuous | Real-time push | ❌ KHÔNG       | CRM push complaints real-time         |
| FACEBOOK/TIKTOK/YOUTUBE | Continuous | Scheduled poll | ✅ CÓ          | Crawl TikTok mỗi 11 phút (có thể đổi) |

**Tại sao cần nhiều Data Sources?**

- Một entity (VF8) được nhắc đến ở nhiều nơi: TikTok, YouTube, Excel feedback, CRM complaints
- Mỗi nguồn có cách thu thập khác nhau: upload file, crawl API, webhook
- Cần gộp tất cả để có cái nhìn toàn diện về VF8

---

## 4. STATE MACHINE

### 4.1 Design Principles

1. **Separation of Concerns:** Project lifecycle ≠ Data Source lifecycle
2. **Clear Semantics:** States must be meaningful to users
3. **Explicit Triggers:** Every transition specifies WHO (User/System/External)
4. **Minimal Complexity:** Avoid transient states, use sub-statuses

### 4.2 Project State Machine (4 States)

```
[*] ──► DRAFT ──► ACTIVE ──► ARCHIVED
          │         │
          │         ↓
          │       PAUSED
          │         │
          └────────►
```

**State Definitions:**

| State    | Meaning                      | User Perspective                |
| -------- | ---------------------------- | ------------------------------- |
| DRAFT    | Project created, configuring | "I'm setting up my project"     |
| ACTIVE   | Project is live, monitoring  | "My project is monitoring data" |
| PAUSED   | Temporarily stopped          | "I paused monitoring"           |
| ARCHIVED | Permanently stopped          | "This project is done"          |

**Transition Table:**

| From          | To       | Trigger        | By   | Validation           | Actions                    |
| ------------- | -------- | -------------- | ---- | -------------------- | -------------------------- |
| null          | DRAFT    | User creates   | USER | None                 | INSERT project             |
| DRAFT         | ACTIVE   | User activates | USER | ≥1 source READY      | Publish project.activated  |
| ACTIVE        | PAUSED   | User pauses    | USER | None                 | Pause all sources          |
| PAUSED        | ACTIVE   | User resumes   | USER | ≥1 source can resume | Resume sources             |
| ACTIVE/PAUSED | ARCHIVED | User archives  | USER | None                 | Cancel all jobs (see Note) |

**Note on "Cancel all jobs":**

Khi archive project, Project Service publish event `project.archived` với list `source_ids[]`. Ingest Service consume event này và stop crawling cho các sources đó.

**Implementation:** Xem chi tiết tại `documents/ingest/job_scheduler_implementation.md`

**Flow:**

```
[Project Service] Archive Project
    → Update: project.status = ARCHIVED
    → Update: all sources.status = ARCHIVED
    → Publish: project.archived {project_id, source_ids[]}
    ↓
[Ingest Service] Consume event
    → Skip ARCHIVED sources in worker loop
    → (No explicit job cancellation needed with database-driven approach)
```

---

### 4.3 Data Source State Machine (6 States)

```
[*] ──► PENDING ──► READY ──► ACTIVE ──► COMPLETED
          │          │         │
          │          │         ↓
          │          │       PAUSED
          │          │         │
          │          └────────►
          │
          └──────────────────► FAILED
```

**State Definitions:**

| State     | Meaning                      | Applies To     | User Perspective              |
| --------- | ---------------------------- | -------------- | ----------------------------- |
| PENDING   | Waiting for validation       | All            | "I'm configuring this source" |
| READY     | Validated, ready to activate | All            | "This source is ready"        |
| ACTIVE    | Running (crawling/receiving) | All            | "Actively collecting data"    |
| PAUSED    | Temporarily stopped          | Crawl, Webhook | "I paused this source"        |
| COMPLETED | Finished (one-time)          | FILE_UPLOAD    | "File upload completed"       |
| FAILED    | Error, needs intervention    | All            | "This source has an error"    |

**Validation by Source Type:**

| Source Type             | PENDING → READY Validation                       |
| ----------------------- | ------------------------------------------------ |
| FILE_UPLOAD             | User uploads → AI Schema Mapping → User confirms |
| WEBHOOK                 | User defines schema → AI mapping → User confirms |
| FACEBOOK/TIKTOK/YOUTUBE | User configs → Dry Run → User reviews → Success  |

---

## 5. MODULES VÀ API

### 5.1 Module Structure

```
internal/
├── projects/          # Project CRUD + State Machine
├── campaigns/         # Campaign CRUD
├── scheduler/         # Adaptive controller (consume metrics, decide mode)
├── dashboard/         # Dashboard aggregation
├── crisis/            # Crisis config + alert management
├── orchestrator/      # Command publisher (to Ingest)
├── ingest_client/     # HTTP client to call Ingest Service API
└── health/            # Health check metrics
```

**IMPORTANT: NO sources/ module**

Project Service KHÔNG có domain/repository cho Data Sources vì:

- Data Sources thuộc về Ingest Service
- Project Service chỉ gọi Ingest Service API qua HTTP client
- Không duplicate domain logic

**Example: ingest_client/**

```go
// internal/ingest_client/client.go

type IngestClient struct {
    baseURL    string
    httpClient *http.Client
}

func (c *IngestClient) CreateSource(ctx context.Context, req CreateSourceRequest) (*Source, error) {
    // POST /ingest/sources
}

func (c *IngestClient) GetSource(ctx context.Context, sourceID string) (*Source, error) {
    // GET /ingest/sources/{id}
}

func (c *IngestClient) UpdateSource(ctx context.Context, sourceID string, req UpdateSourceRequest) error {
    // PUT /ingest/sources/{id}
}

func (c *IngestClient) ActivateSource(ctx context.Context, sourceID string) error {
    // POST /ingest/sources/{id}/activate
}
```

### 5.2 Core API Endpoints

**Projects:**

```
POST   /projects                    # Create project
GET    /projects                    # List projects
GET    /projects/{id}               # Get project details
PUT    /projects/{id}               # Update project
DELETE /projects/{id}               # Delete project
POST   /projects/{id}/activate      # Activate project
POST   /projects/{id}/pause         # Pause project
POST   /projects/{id}/resume        # Resume project
POST   /projects/{id}/archive       # Archive project
GET    /projects/{id}/dashboard     # Get dashboard data
```

**Data Sources:**

```
POST   /projects/{id}/sources       # Project Service receives request
                                     # → Calls Ingest Service API
                                     # → Returns source_id from Ingest

GET    /sources/{id}                # Query Ingest Service directly
                                     # OR Project Service proxies to Ingest

PUT    /sources/{id}                # Update source config
                                     # → Project Service → Ingest Service

DELETE /sources/{id}                # Delete source
                                     # → Project Service → Ingest Service

POST   /sources/{id}/dry-run        # Trigger dry run
                                     # → Project Service → Ingest Service

POST   /sources/{id}/activate       # Activate source
                                     # → Project Service updates status via Ingest API

POST   /sources/{id}/pause          # Pause source
POST   /sources/{id}/resume         # Resume source
```

**Note:** Project Service là API Gateway cho Frontend, nhưng actual data source records được store và manage bởi Ingest Service.

**Campaigns:**

```
POST   /campaigns                     # Create campaign
GET    /campaigns                     # List campaigns
GET    /campaigns/{id}                # Get campaign details
PUT    /campaigns/{id}                # Update campaign
DELETE /campaigns/{id}                # Delete campaign
POST   /campaigns/{id}/projects       # Add project to campaign
DELETE /campaigns/{id}/projects/{pid} # Remove project
```

### 5.3 Database Schema

**Project Service Schema (schema_project.\*):**

```sql
-- Projects (Tầng 2: Entity Monitoring Unit)
CREATE TABLE schema_project.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    entity_type VARCHAR(50),
    entity_name VARCHAR(200),
    description TEXT,

    -- Status
    status VARCHAR(20) DEFAULT 'DRAFT',

    -- Metadata
    created_by UUID NOT NULL,
    activated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaigns (Tầng 3: Logical Analysis Unit)
CREATE TABLE schema_project.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaign-Project relationship
CREATE TABLE schema_project.campaign_projects (
    campaign_id UUID REFERENCES schema_project.campaigns(id),
    project_id UUID REFERENCES schema_project.projects(id),
    added_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (campaign_id, project_id)
);
```

**Ingest Service Schema (schema_ingest.\*):**

```sql
-- Data Sources (Tầng 1: Physical Data Unit)
-- OWNED BY INGEST SERVICE - Project Service queries via API
CREATE TABLE schema_ingest.data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Generated by Ingest Service
    project_id UUID NOT NULL,  -- Foreign key to Project Service (logical reference)
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(20) NOT NULL,
    source_category VARCHAR(10) NOT NULL DEFAULT 'passive',

    -- Config
    config JSONB,

    -- Adaptive Crawl (only for crawl sources)
    crawl_mode VARCHAR(20) DEFAULT 'NORMAL',
    crawl_interval_minutes INT DEFAULT 11,
    next_crawl_at TIMESTAMPTZ,

    -- Metrics
    last_crawl_at TIMESTAMPTZ,
    last_crawl_metrics JSONB,
    baseline_metrics JSONB,

    -- Status
    status VARCHAR(20) DEFAULT 'PENDING',
    onboarding_status VARCHAR(20),
    dryrun_status VARCHAR(20),
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chk_crawl_mode_only_for_crawl
        CHECK (
            (source_category = 'crawl' AND crawl_mode IN ('SLEEP', 'NORMAL', 'CRISIS'))
            OR (source_category = 'passive' AND crawl_mode IS NULL)
        )
);

-- Note: No foreign key constraint on project_id because it's cross-service reference
-- Project Service and Ingest Service are separate databases/services
```

**Cross-Service Communication:**

```
[Frontend] POST /projects/{id}/sources
    ↓
[Project Service API]
    1. Validate project exists (query schema_project.projects)
    2. Call Ingest Service: POST /ingest/sources
    ↓
[Ingest Service API]
    1. INSERT schema_ingest.data_sources
    2. Return: {id: "src_123", status: "PENDING"}
    ↓
[Project Service]
    1. Return source_id to Frontend
    2. (Optional) Cache source_id for quick lookup
```

### 5.4 Kafka Event Handlers (Consumers)

Project Service consume các events từ Ingest và Analytics để:

- Trigger adaptive crawl decisions (từ Analytics metrics)
- Update internal state nếu cần (optional caching)

**Module:** `internal/consumers/` hoặc `internal/scheduler/consumers.go`

**IMPORTANT:** Project Service KHÔNG update database của Ingest Service. Chỉ:

1. Consume events để biết status
2. Make decisions (adaptive crawl mode)
3. Publish commands back to Ingest Service

#### 5.4.1 Crawl Completed Handler

**Purpose:** Nhận thông báo crawl hoàn thành (for monitoring/logging only)

**Flow:**

```
INPUT: ingest.crawl.completed
  ├─ source_id
  ├─ items_count
  ├─ status (SUCCESS/FAILED)
  ├─ crawl_duration_ms
  └─ timestamp

PROCESS:
  1. Log crawl completion
  2. (Optional) Update local cache if needed
  3. No database update - Ingest Service owns the data

OUTPUT: Logged
  └─ Project Service aware of crawl status
     (Ingest Service already updated its own database)

NOTE: Ingest Service tự update schema_ingest.data_sources
      Project Service chỉ consume để biết status
```

#### 5.4.2 File Upload Completed Handler

**Purpose:** Nhận thông báo FILE_UPLOAD source processing hoàn thành

**Context:** Khi user upload file Excel/CSV (FILE_UPLOAD source), Ingest Service xử lý file và publish event này.

**Flow:**

```
INPUT: ingest.file.completed
  ├─ source_id (FILE_UPLOAD source)
  ├─ items_count (số dòng đã parse)
  ├─ status (SUCCESS/FAILED)
  ├─ file_url (s3://bucket/file.xlsx)
  └─ processing_duration_ms

PROCESS:
  1. Log file processing completion
  2. (Optional) Update local cache if needed
  3. No database update - Ingest Service owns the data

OUTPUT: Logged
  └─ Project Service aware of file upload status
     (Ingest Service already updated status to COMPLETED/FAILED)

EXAMPLE:
  User uploads "feedback_q1.xlsx" (500 rows)
  → Ingest Service parses → 500 UAP records
  → Ingest Service updates: schema_ingest.data_sources status = COMPLETED
  → Publish: ingest.file.completed {source_id, items_count: 500, status: SUCCESS}
  → Project Service logs: "File upload completed for source_id"

NOTE: Ingest Service tự update schema_ingest.data_sources
      Project Service chỉ consume để biết status
```

#### 5.4.3 Dry Run Completed Handler

**Purpose:** Nhận thông báo dry run results

**Flow:**

```
INPUT: ingest.dryrun.completed
  ├─ source_id
  ├─ status (SUCCESS/FAILED)
  ├─ sample_data (max 10 items)
  ├─ total_found
  └─ warnings[]

PROCESS:
  1. Log dry run completion
  2. (Optional) Update local cache if needed
  3. No database update - Ingest Service owns the data

OUTPUT: Logged
  ├─ If SUCCESS: Source ready to activate (Ingest Service updated status = READY)
  └─ If FAILED: User needs to fix config (Ingest Service kept status = PENDING)

NOTE: Ingest Service tự update schema_ingest.data_sources
      - status = READY (if SUCCESS) or PENDING (if FAILED)
      - dryrun_status = SUCCESS/FAILED
      - dryrun_results = {...}
      Project Service chỉ consume để biết status
```

#### 5.4.4 Metrics Aggregated Handler (Adaptive Scheduler)

**Purpose:** Quyết định crawl mode dựa trên metrics từ Analytics

**Flow:**

```
INPUT: analytics.metrics.aggregated
  ├─ source_id
  ├─ negative_ratio (0.45 = 45%)
  ├─ velocity (items/hour)
  └─ new_items_count

PROCESS:
  1. Get source info from Ingest Service:
     - Call: GET /ingest/sources/{source_id}
     - Check: source_category = crawl? (skip if passive)
  2. Load baseline metrics (7-day average)
  3. Determine new mode:
     - Compare current vs baseline
     - Apply rules (see Section 6.3)
  4. If mode changed:
     - Calculate new interval:
       * SLEEP → 60 min
       * NORMAL → 11 min
       * CRISIS → 2 min
     - Call Ingest Service API:
       PUT /ingest/sources/{source_id}/crawl-mode
       {
         crawl_mode: "CRISIS",
         crawl_interval: 2,
         reason: "Negative ratio 45% >> baseline 10%"
       }
     - Publish: project.mode.changed (for notification)
  5. Store current metrics for next comparison

OUTPUT: Mode change (if needed)
  ├─ Ingest Service updated with new mode
  ├─ Event published for notification
  └─ Next crawl scheduled by Ingest Service

NOTE: Project Service KHÔNG update database trực tiếp
      Chỉ gọi Ingest Service API để thay đổi mode
```

---

## 6. ADAPTIVE CRAWL

### 6.0 Relationship: Adaptive Crawl vs Crisis Detection

**2 Mechanisms khác nhau nhưng bổ trợ cho nhau:**

```
┌─────────────────────────────────────────────────────────────────┐
│         ADAPTIVE CRAWL vs CRISIS DETECTION                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ADAPTIVE CRAWL (Automatic - Metrics-based)                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Purpose: Tự động điều chỉnh tần suất crawl               │  │
│  │  Trigger: Analytics metrics (every 5 min)                 │  │
│  │  Input:   analytics.metrics.aggregated                    │  │
│  │           {negative_ratio, velocity, new_items_count}     │  │
│  │  Logic:   Simple threshold-based rules                    │  │
│  │           - negative_ratio > 30% → CRISIS                 │  │
│  │           - velocity > 2x baseline → CRISIS               │  │
│  │           - new_items < 5 → SLEEP                         │  │
│  │  Action:  Change crawl_mode + crawl_interval              │  │
│  │  Scope:   Per source (independent)                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  CRISIS DETECTION (User-configured - Rule-based)                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Purpose: Phát hiện khủng hoảng theo rules của user       │  │
│  │  Trigger: Background job (every 5 min)                    │  │
│  │  Input:   schema_analysis.post_insight (recent data)      │  │
│  │  Logic:   Complex user-defined rules                      │  │
│  │           - Keywords (critical terms)                     │  │
│  │           - Volume (spike detection)                      │  │
│  │           - Sentiment (negative ratio + ABSA)             │  │
│  │           - Influencer (viral posts)                      │  │
│  │  Action:  Send alerts + Store history                     │  │
│  │  Scope:   Per project (aggregate all sources)             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  INTERACTION:                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Crisis Detection CÓ THỂ trigger Adaptive Crawl:          │  │
│  │                                                           │  │
│  │  [Analytics] Detect crisis (keywords/volume/sentiment)    │  │
│  │      → Publish: analytics.crisis.detected                 │  │
│  │      ↓                                                    │  │
│  │  [Project Service] Consume crisis alert                   │  │
│  │      → If severity=CRITICAL + source is crawl             │  │
│  │      → Publish: project.crisis.started                    │  │
│  │      ↓                                                    │  │
│  │  [Adaptive Scheduler] Consume crisis event                │  │
│  │      → Force switch to CRISIS mode (override metrics)     │  │
│  │      → crawl_interval = 2 min                             │  │
│  │                                                           │  │
│  │  Nhưng Adaptive Crawl KHÔNG trigger Crisis Detection      │  │
│  │  (chỉ là điều chỉnh tần suất, không phải alert)           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**So sánh chi tiết:**

| Aspect             | Adaptive Crawl                       | Crisis Detection                                        |
| ------------------ | ------------------------------------ | ------------------------------------------------------- |
| **Purpose**        | Optimize crawl frequency             | Alert user of crisis                                    |
| **Trigger**        | Automatic (metrics)                  | User-configured rules                                   |
| **Input**          | `analytics.metrics.aggregated`       | `schema_analysis.post_insight`                          |
| **Logic**          | Simple thresholds                    | Complex rules (keywords, volume, sentiment, influencer) |
| **Decision Maker** | Project Service (Adaptive Scheduler) | Analytics Service (Crisis Detector)                     |
| **Output**         | Change crawl_mode                    | Send alerts + Store history                             |
| **Scope**          | Per source                           | Per project (all sources)                               |
| **User Control**   | No (automatic)                       | Yes (configure rules)                                   |
| **Notification**   | No                                   | Yes (email, Slack, SMS)                                 |

**Use Cases:**

1. **Adaptive Crawl only:**
   - Tự động tăng tần suất khi có nhiều data mới
   - Tự động giảm tần suất khi ít data
   - Không cần user config

2. **Crisis Detection only:**
   - User muốn được alert khi có từ khóa nhạy cảm
   - User muốn biết khi có influencer nói xấu
   - Cần lưu lịch sử alerts

3. **Both (Recommended):**
   - Crisis Detection phát hiện khủng hoảng → Alert user
   - Đồng thời trigger Adaptive Crawl → Tăng tần suất thu thập
   - User được thông báo + Hệ thống tự động thu thập nhiều hơn

**Example Scenario:**

```
Timeline:
─────────────────────────────────────────────────────────────────
T0 (10:00): Normal state
  - TikTok source: NORMAL mode (11 min interval)
  - No crisis detected

T1 (10:05): Analytics detects high negative ratio
  - Metrics: negative_ratio = 35%
  - Adaptive Crawl: NORMAL → CRISIS (2 min interval)
  - Crisis Detection: Not triggered yet (no critical keywords)

T2 (10:10): User posts with critical keywords
  - Post: "Xe VF8 lừa đảo, pin giả mạo"
  - Crisis Detection: TRIGGERED (keywords_trigger)
  - Alert sent to user via email/Slack
  - Adaptive Crawl: Already in CRISIS mode (no change)

T3 (10:11): More negative posts
  - Metrics: negative_ratio = 50%
  - Adaptive Crawl: Stay in CRISIS mode
  - Crisis Detection: Already alerted (no duplicate)

T4 (10:00): Situation improves
  - Metrics: negative_ratio = 11%
  - Adaptive Crawl: CRISIS → NORMAL (11 min interval)
  - Crisis Detection: Mark alert as RESOLVED
─────────────────────────────────────────────────────────────────
```

---

### 6.1 CRITICAL RULE

**Adaptive Crawl CHỈ áp dụng cho CRAWL sources:**

| Source Type | Category | Adaptive Crawl | Lý do             |
| ----------- | -------- | -------------- | ----------------- |
| FILE_UPLOAD | passive  | ❌ KHÔNG       | One-time upload   |
| WEBHOOK     | passive  | ❌ KHÔNG       | Event-driven      |
| FACEBOOK    | crawl    | ✅ CÓ          | Scheduled polling |
| TIKTOK      | crawl    | ✅ CÓ          | Scheduled polling |
| YOUTUBE     | crawl    | ✅ CÓ          | Scheduled polling |

### 6.2 Crawl Modes

| Mode   | Interval | When to Use                               |
| ------ | -------- | ----------------------------------------- |
| SLEEP  | 60 min   | Low activity (< 5 new items/hour)         |
| NORMAL | 11 min   | Normal activity (baseline)                |
| CRISIS | 2 min    | High negative sentiment or velocity spike |

### 6.3 Mode Decision Logic

**2 Ways to Trigger Mode Change:**

#### 6.3.1 Automatic (Metrics-based) - Primary Method

**Input:** `analytics.metrics.aggregated` (every 5 min)

**Decision Flow:**

```
INPUT: Current Metrics + Baseline (7-day avg)
  ├─ current.negative_ratio = 0.45 (45%)
  ├─ current.velocity = 50 items/hour
  ├─ current.new_items_count = 50
  ├─ baseline.avg_negative_ratio = 0.10 (10%)
  └─ baseline.avg_velocity = 20 items/hour

DECISION TREE (Priority Order):

1. CRISIS Detection (Highest Priority)
   ├─ Rule 1: negative_ratio > 30%?
   │  └─ YES → CRISIS MODE (2 min)
   ├─ Rule 2: negative_ratio > 3x baseline?
   │  └─ 0.45 / 0.10 = 4.5x > 3x → CRISIS MODE
   └─ Rule 3: velocity > 2x baseline AND negative_ratio > 20%?
      └─ 50 / 20 = 2.5x > 2x AND 45% > 20% → CRISIS MODE

2. SLEEP Detection (Lowest Priority)
   ├─ Rule 4: new_items_count < 5?
   │  └─ YES → SLEEP MODE (60 min)
   └─ Rule 5: velocity < 10 items/hour?
      └─ YES → SLEEP MODE (60 min)

3. Default: NORMAL MODE (11 min)

OUTPUT: Determined Mode
  └─ Example: CRISIS MODE (45% >> 10% baseline)
```

**Example Payload:**

```json
{
  "source_id": "src_tiktok_01",
  "new_items_count": 50,
  "negative_ratio": 0.45,
  "velocity": 50.0,
  "time_window": "last_5min"
}
```

#### 6.3.2 Manual (Crisis-triggered) - Override Method

**Input:** `analytics.crisis.detected` (when crisis detected)

**Decision Flow:**

```
INPUT: analytics.crisis.detected
  ├─ alert_id
  ├─ source_id
  ├─ trigger_type (keywords/volume/sentiment/influencer)
  └─ severity (CRITICAL/HIGH/MEDIUM/LOW)

PROCESS:
  1. Check severity:
     - If NOT CRITICAL → SKIP (no override)
     - If CRITICAL → Continue
  2. Get source from database
  3. Check source_category:
     - If passive → SKIP (no adaptive crawl)
     - If crawl → Continue
  4. FORCE switch to CRISIS mode:
     - Override any metrics-based decision
     - crawl_mode = CRISIS
     - crawl_interval = 2 min
     - next_crawl_at = NOW (immediate)
     - reason = "Crisis detected: {trigger_type}"
  5. Publish: project.crisis.started

OUTPUT: Mode changed to CRISIS
  ├─ Database updated
  ├─ Event published to Ingest Service
  └─ Next crawl triggered immediately
```

**Example Payload:**

```json
{
  "alert_id": "alert_103",
  "project_id": "proj_vf8",
  "source_id": "src_tiktok_01",
  "trigger_type": "keywords_trigger",
  "severity": "CRITICAL",
  "metrics": {...},
  "detected_at": "2026-02-19T10:30:00Z"
}
```

**Priority:**

- Crisis-triggered (manual) > Metrics-based (automatic)
- Nếu crisis detected → Force CRISIS mode ngay lập tức
- Nếu không có crisis → Dùng metrics để quyết định

---

### 6.4 Adaptive Flow

**Path 1: Metrics-based (Automatic)**

```
[Analytics Service - Metrics Aggregator]
    Every 5 minutes:
    - Aggregate metrics per source
    - Publish: analytics.metrics.aggregated
    ↓
[Project Service - Adaptive Scheduler]
    - Consume: analytics.metrics.aggregated
    - Filter: Only process crawl sources
    - Load baseline: avg_negative_ratio = 10%
    - Determine mode: 45% >> 10% → CRISIS MODE
    - Update data_source:
        crawl_mode: NORMAL → CRISIS
        crawl_interval: 11min → 2min
        next_crawl_at: NOW()
    - Publish: project.mode.changed
    ↓
[Ingest Service]
    - Consume: project.mode.changed
    - Reschedule job (2min interval)
    - Trigger crawl IMMEDIATELY
```

**Path 2: Crisis-triggered (Manual Override)**

```
[Analytics Service - Crisis Detector]
    Every 5 minutes:
    - Check crisis rules (keywords, volume, sentiment, influencer)
    - Detect: Critical keywords found
    - Publish: analytics.crisis.detected
    ↓
[Project Service - Crisis Handler]
    - Consume: analytics.crisis.detected
    - Store alert in crisis_alerts table
    - If severity=CRITICAL + source is crawl:
        → FORCE switch to CRISIS mode (override metrics)
        → Update data_source: crawl_mode = CRISIS, crawl_interval = 2
        → Publish: project.crisis.started
    ↓
[Ingest Service]
    - Consume: project.crisis.started
    - Reschedule job (2min interval)
    - Trigger crawl IMMEDIATELY
    ↓
[Notification Service]
    - Consume: project.crisis.started
    - Send alerts to user (email, Slack, SMS)
```

**Combined Flow (Both Active):**

```
Timeline:
─────────────────────────────────────────────────────────────────
T0 (10:00): Normal state
  Source: NORMAL mode (11 min)

T1 (10:05): Metrics show high negative ratio
  [Metrics Aggregator] Publish: analytics.metrics.aggregated
  [Adaptive Scheduler] Switch to CRISIS mode (Path 1)
  Source: CRISIS mode (2 min) ← Automatic

T2 (10:07): First crisis crawl
  [Ingest] Crawl with 2 min interval

T3 (10:10): Crisis Detector finds critical keywords
  [Crisis Detector] Publish: analytics.crisis.detected
  [Crisis Handler] Store alert + Publish: project.crisis.started
  [Notification] Send alert to user ← Manual alert
  Source: Already in CRISIS mode (no change)

T4 (10:10): Continue crisis crawling
  [Ingest] Crawl every 2 min

T5 (10:00): Situation improves
  [Metrics Aggregator] negative_ratio = 11%
  [Adaptive Scheduler] Switch to NORMAL mode (Path 1)
  [Crisis Handler] Mark alert as RESOLVED
  Source: NORMAL mode (11 min) ← Automatic
─────────────────────────────────────────────────────────────────
```

---

## 7. CRISIS DETECTION & ADAPTIVE CRAWL

### 7.1 Overview

**Concept:**

- **Adaptive Crawl:** ALWAYS ENABLED - System tự động điều chỉnh crawl frequency dựa trên metrics
- **Crisis Detection:** User config 4 triggers (Keywords, Volume, Sentiment, Influencer) với default values
- **System tự động dùng crisis_detection thresholds cho adaptive crawl** → Consistent behavior

**Vai trò phân chia:**

- **Project Service:** Quản lý Crisis Detection Config (CRUD API, store config)
- **Analytics Service:**
  - Publish metrics (every 5 min) → `analytics.metrics.aggregated`
  - Thực thi crisis detection logic → `analytics.crisis.detected`
- **Project Service (Adaptive Scheduler):**
  - Consume metrics → Extract threshold từ crisis_detection config → Call Ingest API
- **Project Service (Crisis Handler):**
  - Consume crisis alerts → Store alert → Call Ingest API (if CRITICAL)
- **Ingest Service:** Execute crawl với mode được chỉ định

**Flow:**

```
[Project Service] Store crisis_detection config (user input)
    ↓
[Analytics Service] Publish metrics every 5 min
    → Publish: analytics.metrics.aggregated
    ↓
[Project Service - Adaptive Scheduler]
    → Consume: analytics.metrics.aggregated
    → Extract threshold from crisis_detection config
    → Compare metrics vs threshold
    → Call Ingest API: Update crawl mode if needed
    ↓
[Ingest Service] Update crawl_mode and schedule next crawl

    ┌─────────────────────────────────────────────┐
    │  PARALLEL: Crisis Detection                 │
    └─────────────────────────────────────────────┘

[Analytics Service] Analyze UAP → Check crisis_detection rules
    → Publish: analytics.crisis.detected
    ↓
[Project Service - Crisis Handler]
    → Consume: analytics.crisis.detected
    → Store alert in crisis_alerts table
    → If CRITICAL: Call Ingest API to force CRISIS mode
    → Publish: project.crisis.started (for notification)
    ↓
[Notification Service] Push alert to user (email, Slack, SMS)
```

---

### 7.2 Crisis Detection Config Structure

**User chỉ cần config Crisis Detection. Adaptive Crawl tự động hoạt động.**

**Config JSON:**

```json
{
  "project_id": "proj_vf8",

  // CHỈ CẦN CONFIG CRISIS DETECTION
  // Adaptive crawl tự động:
  //   - ALWAYS enabled (không cần user config)
  //   - Dùng crisis_detection thresholds
  //   - Sleep mode: hardcoded (< 10 items/hour)

  "crisis_detection": {
    // Trigger 1: Keywords (Default: disabled)
    "keywords_trigger": {
      "enabled": false, // ENUM: true | false - Default: false
      "logic": "OR", // ENUM: "AND" | "OR" - Default: "OR"
      "groups": [
        {
          "name": "Từ ngữ nghiêm trọng",
          "keywords": ["lừa đảo", "scam", "giả mạo"],
          "weight": 10 // 1-100
        }
      ]
    },

    // Trigger 2: Volume (Default: enabled)
    "volume_trigger": {
      "enabled": true, // ENUM: true | false - Default: true
      "metric": "MENTIONS", // ENUM: "MENTIONS" | "ENGAGEMENT" | "REACH" - Default: "MENTIONS"
      "rules": [
        {
          "level": "CRITICAL", // ENUM: "WARNING" | "CRITICAL" - Default: "CRITICAL"
          "threshold_percent_growth": 200, // Default: 200 (3x baseline)
          "comparison_window_hours": 1, // Default: 1
          "baseline": "PREVIOUS_PERIOD" // ENUM: "PREVIOUS_PERIOD" | "AVERAGE_7D" | "AVERAGE_30D" - Default: "PREVIOUS_PERIOD"
        }
      ]
    },

    // Trigger 3: Sentiment (Default: enabled)
    "sentiment_trigger": {
      "enabled": true, // ENUM: true | false - Default: true
      "min_sample_size": 50, // Default: 50
      "rules": [
        {
          "type": "NEGATIVE_SPIKE", // ENUM: "NEGATIVE_SPIKE" | "ASPECT_NEGATIVE" - Default: "NEGATIVE_SPIKE"
          "threshold_percent": 30 // Default: 30 - ADAPTIVE CRAWL DÙNG THRESHOLD NÀY
        }
      ]
    },

    // Trigger 4: Influencer (Default: disabled)
    "influencer_trigger": {
      "enabled": false, // ENUM: true | false - Default: false
      "logic": "OR", // ENUM: "AND" | "OR" - Default: "OR"
      "rules": [
        {
          "type": "HIGH_REACH", // ENUM: "HIGH_REACH" | "VIRAL_NEGATIVE" - Default: "HIGH_REACH"
          "min_followers": 100000,
          "required_sentiment": "NEGATIVE" // ENUM: "NEGATIVE" | "NEUTRAL" - Default: "NEGATIVE"
        }
      ]
    }
  }
}
```

**ENUM Fields Summary:**

| Field                                           | Enum Values                                    | Default           | Description                         |
| ----------------------------------------------- | ---------------------------------------------- | ----------------- | ----------------------------------- |
| `keywords_trigger.enabled`                      | `true`, `false`                                | `false`           | Enable/disable keywords trigger     |
| `keywords_trigger.logic`                        | `AND`, `OR`                                    | `OR`              | Logic operator for keyword groups   |
| `volume_trigger.enabled`                        | `true`, `false`                                | `true`            | Enable/disable volume trigger       |
| `volume_trigger.metric`                         | `MENTIONS`, `ENGAGEMENT`, `REACH`              | `MENTIONS`        | Metric to monitor                   |
| `volume_trigger.rules[].level`                  | `WARNING`, `CRITICAL`                          | `CRITICAL`        | Alert severity level                |
| `volume_trigger.rules[].baseline`               | `PREVIOUS_PERIOD`, `AVERAGE_7D`, `AVERAGE_30D` | `PREVIOUS_PERIOD` | Baseline calculation method         |
| `sentiment_trigger.enabled`                     | `true`, `false`                                | `true`            | Enable/disable sentiment trigger    |
| `sentiment_trigger.rules[].type`                | `NEGATIVE_SPIKE`, `ASPECT_NEGATIVE`            | `NEGATIVE_SPIKE`  | Sentiment rule type                 |
| `influencer_trigger.enabled`                    | `true`, `false`                                | `false`           | Enable/disable influencer trigger   |
| `influencer_trigger.logic`                      | `AND`, `OR`                                    | `OR`              | Logic operator for influencer rules |
| `influencer_trigger.rules[].type`               | `HIGH_REACH`, `VIRAL_NEGATIVE`                 | `HIGH_REACH`      | Influencer rule type                |
| `influencer_trigger.rules[].required_sentiment` | `NEGATIVE`, `NEUTRAL`                          | `NEGATIVE`        | Required sentiment for trigger      |

---

### 7.3 Default Config (System-generated)

**Khi user tạo project mới, system tạo default config:**

```json
{
  "project_id": "proj_vf8",
  "crisis_detection": {
    "keywords_trigger": {
      "enabled": false,
      "logic": "OR",
      "groups": []
    },
    "volume_trigger": {
      "enabled": true,
      "metric": "MENTIONS",
      "rules": [
        {
          "level": "CRITICAL",
          "threshold_percent_growth": 200,
          "comparison_window_hours": 1,
          "baseline": "PREVIOUS_PERIOD"
        }
      ]
    },
    "sentiment_trigger": {
      "enabled": true,
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 30
        }
      ]
    },
    "influencer_trigger": {
      "enabled": false,
      "logic": "OR",
      "rules": []
    }
  }
}
```

**Default Behavior:**

- Alert ở 30% negative HOẶC 200% volume growth
- Adaptive crawl tự động switch ở 30% negative
- Sleep mode ở < 10 items/hour (hardcoded)
- User chỉ cần customize nếu muốn thay đổi thresholds

**Frontend Tooltips (Hướng dẫn cho user):**

| Trigger        | Tooltip                                                                                                  |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| **Keywords**   | "Phát hiện từ khóa nhạy cảm như 'lừa đảo', 'scam'. Mặc định: Tắt (bạn cần thêm từ khóa để bật)"          |
| **Volume**     | "Phát hiện tăng đột biến lượng mentions. Mặc định: Bật - Cảnh báo khi tăng 200% (3x) so với giờ trước"   |
| **Sentiment**  | "Phát hiện tỷ lệ negative cao. Mặc định: Bật - Cảnh báo khi > 30% negative (cần tối thiểu 50 bình luận)" |
| **Influencer** | "Phát hiện influencer lớn hoặc bài viral negative. Mặc định: Tắt (bạn cần cấu hình để bật)"              |

---

### 7.4 System Behavior (Adaptive Crawl - Always Enabled)

**Adaptive Crawl = System behavior, KHÔNG cần user config.**

**3 Rules để quyết định crawl mode:**

#### Rule 1: Crisis Detection → Adaptive Crawl (Automatic)

**Trigger:** Analytics Service phát hiện crisis → Publish `analytics.crisis.detected`

**Flow:**

```
[Analytics Service] Detect crisis (keywords/volume/sentiment/influencer)
    → Publish: analytics.crisis.detected
    ↓
[Project Service - Crisis Handler]
    1. Consume: analytics.crisis.detected
    2. Store alert in crisis_alerts table
    3. Check conditions:
       - severity = CRITICAL?
       - source_id exists?
       - source_category = crawl?
    4. If ALL YES:
       → Call Ingest API: PUT /ingest/sources/{source_id}/crawl-mode
         {
           crawl_mode: "CRISIS",
           crawl_interval: 2,
           reason: "Crisis detected: {trigger_type}"
         }
    5. Publish: project.crisis.started (for notification)
    ↓
[Ingest Service] Update crawl_mode → Schedule next crawl in 2 min
```

**Example:**

```
T0 (10:00): Normal state
  - TikTok source: NORMAL mode (11 min interval)

T1 (10:05): Analytics detects critical keywords
  - Post: "Xe VF8 lừa đảo, pin giả mạo"
  - Crisis Detection: TRIGGERED (keywords_trigger)
  - Severity: CRITICAL

T2 (10:05): Project Service handles crisis
  - Store alert in crisis_alerts table
  - Call Ingest API: PUT /crawl-mode {mode: CRISIS, interval: 2}
  - Publish: project.crisis.started

T3 (10:07): Ingest Service crawls immediately
  - Next crawl: 10:09, 10:11, 10:13... (every 2 min)
```

**NOTE:** Analytics Service PUBLISH event → Project Service CONSUME → Call Ingest API

---

#### Rule 2: Metrics-based Adaptive Crawl (Automatic)

**Trigger:** Analytics Service publish metrics every 5 min → `analytics.metrics.aggregated`

**Flow:**

```
[Analytics Service] Aggregate metrics (every 5 min)
    → Publish: analytics.metrics.aggregated
    ↓
[Project Service - Adaptive Scheduler]
    1. Consume: analytics.metrics.aggregated
    2. Get source info:
       - Call: GET /ingest/sources/{source_id}
       - Check: source_category = crawl? (skip if passive)
    3. Load crisis_detection config:
       - Query: schema_project.project_configs
       - Extract: sentiment_trigger.threshold_percent (e.g., 30%)
    4. Compare metrics vs threshold:
       - current.negative_ratio = 35%
       - 35% > 30% → CRISIS mode
    5. Determine new mode:
       - CRISIS: negative_ratio > threshold
       - SLEEP: new_items_count < 10/hour (hardcoded)
       - NORMAL: otherwise
    6. If mode changed:
       → Call Ingest API: PUT /ingest/sources/{source_id}/crawl-mode
         {
           crawl_mode: "CRISIS",
           crawl_interval: 2,
           reason: "Negative ratio 35% > threshold 30%"
         }
    ↓
[Ingest Service] Update crawl_mode → Schedule next crawl
```

**Decision Logic:**

```
INPUT: Current Metrics + Crisis Detection Config
  ├─ current.negative_ratio = 0.35 (35%)
  ├─ current.new_items_count = 50
  ├─ config.sentiment_trigger.threshold_percent = 30
  └─ hardcoded.sleep_threshold = 10 items/hour

DECISION TREE (Priority Order):

1. CRISIS Detection (Highest Priority)
   ├─ Rule: negative_ratio > threshold?
   │  └─ 35% > 30% → CRISIS MODE (2 min)

2. SLEEP Detection (Lowest Priority)
   ├─ Rule: new_items_count < 10/hour?
   │  └─ 50 > 10 → NOT SLEEP

3. Default: NORMAL MODE (11 min)

OUTPUT: CRISIS MODE
  └─ Reason: "Negative ratio 35% > threshold 30%"
```

**Example:**

```
T0 (10:00): Normal state
  - TikTok source: NORMAL mode (11 min)
  - Config: sentiment_trigger.threshold_percent = 30%

T1 (10:05): Metrics show high negative ratio
  - Metrics: negative_ratio = 35%, new_items = 50
  - Adaptive Scheduler: 35% > 30% → CRISIS mode
  - Call Ingest API: PUT /crawl-mode {mode: CRISIS, interval: 2}

T2 (10:07): Ingest Service crawls with 2 min interval
  - Next crawl: 10:09, 10:11, 10:13...

T3 (11:00): Situation improves
  - Metrics: negative_ratio = 12%
  - Adaptive Scheduler: 12% < 30% → NORMAL mode
  - Call Ingest API: PUT /crawl-mode {mode: NORMAL, interval: 11}
```

**NOTE:** Project Service KHÔNG update Ingest database trực tiếp, chỉ gọi API

---

#### Rule 3: Sleep Mode (Automatic - Hardcoded)

**Trigger:** Low activity detected (< 10 items/hour)

**Flow:**

```
[Analytics Service] Publish metrics
    → analytics.metrics.aggregated {new_items_count: 3}
    ↓
[Project Service - Adaptive Scheduler]
    1. Check: new_items_count < 10/hour?
    2. If YES:
       → Call Ingest API: PUT /ingest/sources/{source_id}/crawl-mode
         {
           crawl_mode: "SLEEP",
           crawl_interval: 60,
           reason: "Low activity: 3 items/hour < 10"
         }
    ↓
[Ingest Service] Update crawl_mode → Schedule next crawl in 60 min
```

**Example:**

```
T0 (10:00): Normal state
  - TikTok source: NORMAL mode (11 min)

T1 (10:05): Metrics show low activity
  - Metrics: new_items_count = 3 (last hour)
  - Adaptive Scheduler: 3 < 10 → SLEEP mode
  - Call Ingest API: PUT /crawl-mode {mode: SLEEP, interval: 60}

T2 (11:05): Next crawl (60 min later)
  - Ingest Service crawls again

T3 (11:10): Activity increases
  - Metrics: new_items_count = 25
  - Adaptive Scheduler: 25 > 10 → NORMAL mode
  - Call Ingest API: PUT /crawl-mode {mode: NORMAL, interval: 11}
```

**Sleep Threshold:** Hardcoded = 10 items/hour (KHÔNG cần user config)

---

**Summary:**

| Rule       | Trigger            | Threshold Source                                     | Mode          | Interval |
| ---------- | ------------------ | ---------------------------------------------------- | ------------- | -------- |
| **Rule 1** | Crisis detected    | Analytics Service                                    | CRISIS        | 2 min    |
| **Rule 2** | Metrics aggregated | crisis_detection.sentiment_trigger.threshold_percent | CRISIS/NORMAL | 2/11 min |
| **Rule 3** | Low activity       | Hardcoded (10 items/hour)                            | SLEEP         | 60 min   |

**Priority:** Rule 1 (Crisis) > Rule 2 (Metrics) > Rule 3 (Sleep)

---

### 7.5 Configuration Management (Project Service)

### 7.5 Configuration Management (Project Service)

#### 7.5.1 Database Schema

```sql
-- Store crisis detection config per project
CREATE TABLE schema_project.project_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES schema_project.projects(id) ON DELETE CASCADE,

    -- Crisis Detection Config (JSONB - complex structure)
    -- Adaptive crawl tự động dùng thresholds từ config này
    crisis_detection JSONB NOT NULL,

    -- Metadata
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: 1 config per project
    CONSTRAINT uq_project_config UNIQUE (project_id)
);

CREATE INDEX idx_project_configs_project ON schema_project.project_configs(project_id);
```

**Example crisis_detection JSONB:**

```json
{
  "keywords_trigger": {
    "enabled": false,
    "logic": "OR",
    "groups": []
  },
  "volume_trigger": {
    "enabled": true,
    "metric": "MENTIONS",
    "rules": [
      {
        "level": "CRITICAL",
        "threshold_percent_growth": 200,
        "comparison_window_hours": 1,
        "baseline": "PREVIOUS_PERIOD"
      }
    ]
  },
  "sentiment_trigger": {
    "enabled": true,
    "min_sample_size": 50,
    "rules": [
      {
        "type": "NEGATIVE_SPIKE",
        "threshold_percent": 30
      }
    ]
  },
  "influencer_trigger": {
    "enabled": false,
    "logic": "OR",
    "rules": []
  }
}
```

---

#### 7.5.2 API Endpoints

**Create/Update Crisis Detection Config:**

```http
PUT /projects/{project_id}/config
Authorization: Bearer {token}
Content-Type: application/json

{
  "crisis_detection": {
    "sentiment_trigger": {
      "enabled": true,
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 25
        }
      ]
    },
    "volume_trigger": {
      "enabled": true,
      "metric": "MENTIONS",
      "rules": [
        {
          "level": "CRITICAL",
          "threshold_percent_growth": 200,
          "comparison_window_hours": 1,
          "baseline": "PREVIOUS_PERIOD"
        }
      ]
    }
  }
}

Response 200:
{
  "id": "config_103",
  "project_id": "proj_vf8",
  "crisis_detection": {
    "keywords_trigger": {...},
    "volume_trigger": {...},
    "sentiment_trigger": {...},
    "influencer_trigger": {...}
  },
  "created_at": "2026-02-19T10:00:00Z",
  "updated_at": "2026-02-19T10:00:00Z"
}
```

**Get Crisis Detection Config:**

```http
GET /projects/{project_id}/config
Authorization: Bearer {token}

Response 200:
{
  "id": "config_103",
  "project_id": "proj_vf8",
  "crisis_detection": {
    "keywords_trigger": {
      "enabled": false,
      "logic": "OR",
      "groups": []
    },
    "volume_trigger": {
      "enabled": true,
      "metric": "MENTIONS",
      "rules": [...]
    },
    "sentiment_trigger": {
      "enabled": true,
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 30
        }
      ]
    },
    "influencer_trigger": {
      "enabled": false,
      "logic": "OR",
      "rules": []
    }
  },
  "created_at": "2026-02-19T10:00:00Z",
  "updated_at": "2026-02-19T10:00:00Z"
}

Response 404 (if not configured):
{
  "error": "Config not found for project"
}
```

**Partial Update (Only Sentiment Trigger):**

```http
PUT /projects/{project_id}/config
Content-Type: application/json

{
  "crisis_detection": {
    "sentiment_trigger": {
      "threshold_percent": 20
    }
  }
}

Response 200:
{
  "crisis_detection": {
    "sentiment_trigger": {
      "threshold_percent": 20  // Updated
    },
    "volume_trigger": {...},  // Unchanged
    "keywords_trigger": {...},  // Unchanged
    "influencer_trigger": {...}  // Unchanged
  }
}
```

---

#### 7.5.3 Implementation Flow

```
INPUT: PUT /projects/{id}/config
  ├─ project_id
  └─ crisis_detection (full or partial update)

PROCESS:
  1. Validate config structure:
     - Check ENUM values (enabled, logic, metric, level, type, etc.)
     - Check required fields per trigger
     - Validate thresholds (> 0)
     - Validate min_sample_size (> 0)

  2. Check project exists:
     - Query: schema_project.projects WHERE id = project_id
     - If NOT found → Error 404

  3. Merge with existing config (if partial update):
     - Load existing config from database
     - Deep merge new fields with existing
     - Keep unchanged fields as-is

  4. Upsert config:
     - INSERT or UPDATE schema_project.project_configs
     - Unique constraint: 1 config per project
     - ON CONFLICT (project_id) DO UPDATE

  5. Publish event:
     - Topic: project.config.updated
     - Payload: {
         project_id,
         crisis_detection,
         updated_by,
         timestamp
       }
     - Consumer: Analytics Service (cache config for crisis detection)

OUTPUT: Config stored + Event published
  ├─ Response 200: {id, project_id, crisis_detection, created_at, updated_at}
  ├─ Analytics Service receives update → Refresh cached config
  └─ Adaptive Scheduler uses new threshold on next metrics event
```

**NOTE:** Adaptive crawl tự động dùng threshold từ crisis_detection config, không cần separate API

---

### 7.6 Crisis Detection Execution (Analytics Service)

**Xem chi tiết:** `documents/analysis/crisis_detection_implementation.md`

#### 7.6.1 Data Flow

```
[Analytics Service - UAP Consumer]
    1. Consume: smap.collector.output (UAP batch)
    2. Analyze: Sentiment, Aspect, Keywords
    3. Store: schema_analysis.post_insight
    ↓
[Analytics Service - Crisis Detector (Background Job)]
    Every 5 minutes:
    1. Load crisis configs from Project Service (or cache)
    2. Query recent data (last 5 min)
    3. Check against each trigger:
       - Keywords trigger
       - Volume trigger
       - Sentiment trigger
       - Influencer trigger
    4. If detected → Publish: analytics.crisis.detected
    ↓
[Project Service - Crisis Handler]
    1. Consume: analytics.crisis.detected
    2. Store alert in crisis_alerts table
    3. Check adaptive_crawl config:
       - If enabled → Trigger adaptive crawl
    4. Publish: project.crisis.started
    ↓
[Notification Service]
    1. Consume: project.crisis.started
    2. Send alerts via configured channels (email, Slack, SMS)
```

#### 7.6.2 Kafka Event: analytics.crisis.detected

**Topic:** `analytics.crisis.detected`

**Payload:**

```json
{
  "alert_id": "alert_103",
  "project_id": "proj_vf8",
  "source_id": "src_tiktok_01",
  "trigger_type": "sentiment_trigger",
  "severity": "CRITICAL",
  "metrics": {
    "negative_ratio": 0.45,
    "positive_ratio": 0.25,
    "neutral_ratio": 0.3,
    "sample_size": 110,
    "time_window": "last_5min"
  },
  "matched_rules": [
    {
      "rule_type": "negative_ratio",
      "threshold": 0.3,
      "actual_value": 0.45,
      "exceeded_by": 0.11
    }
  ],
  "sample_posts": [
    {
      "id": "post_103",
      "content": "Pin xe sụt quá nhanh, chỉ chạy được 200km",
      "sentiment": "NEGATIVE",
      "sentiment_score": -0.8,
      "aspects": ["battery", "range"]
    }
  ],
  "detected_at": "2026-02-19T10:30:00Z"
}
```

**Field Definitions:**

| Field           | Type   | Description                                                                                     |
| --------------- | ------ | ----------------------------------------------------------------------------------------------- |
| `alert_id`      | string | Unique alert ID                                                                                 |
| `project_id`    | string | Project ID                                                                                      |
| `source_id`     | string | Data source ID                                                                                  |
| `trigger_type`  | string | Which trigger detected: keywords_trigger, volume_trigger, sentiment_trigger, influencer_trigger |
| `severity`      | string | CRITICAL, HIGH, MEDIUM, LOW                                                                     |
| `metrics`       | object | Aggregated metrics that triggered alert                                                         |
| `matched_rules` | array  | Which specific rules were violated                                                              |
| `sample_posts`  | array  | Sample posts that triggered alert (max 5)                                                       |
| `detected_at`   | string | ISO8601 timestamp                                                                               |

#### 7.6.3 Crisis Alert Storage (Project Service)

```sql
-- Store crisis alerts for history
CREATE TABLE schema_project.crisis_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES schema_project.projects(id),
    source_id UUID,

    -- Alert details
    trigger_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    metrics JSONB NOT NULL,
    matched_rules JSONB NOT NULL,
    sample_posts JSONB,

    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, RESOLVED, ACKNOWLEDGED
    detected_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ,
    acknowledged_by UUID,
    acknowledged_at TIMESTAMPTZ,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_crisis_alerts_project ON schema_project.crisis_alerts(project_id, detected_at DESC);
CREATE INDEX idx_crisis_alerts_status ON schema_project.crisis_alerts(status, detected_at DESC);
```

#### 7.6.4 Crisis Handler (Project Service)

**Flow:**

```
INPUT: analytics.crisis.detected
  ├─ alert_id
  ├─ project_id, source_id
  ├─ trigger_type, severity
  ├─ metrics, matched_rules
  └─ sample_posts[]

PROCESS:
  1. Store alert in database:
     - INSERT schema_project.crisis_alerts
     - Fields: project_id, source_id, trigger_type, severity
     - Status: ACTIVE
     - Store: metrics, matched_rules, sample_posts

  2. Check if should trigger adaptive crawl:
     - Condition 1: severity = CRITICAL?
     - Condition 2: source_id exists?
     - If YES → Continue to step 3
     - If NO → Skip to step 4

  3. Trigger adaptive crawl (if CRITICAL):
     - Get source info: GET /ingest/sources/{source_id}
     - Check: source_category = crawl?
     - If YES:
       * Call Ingest API: PUT /ingest/sources/{source_id}/crawl-mode
         {
           crawl_mode: "CRISIS",
           crawl_interval: 2,
           reason: "Crisis detected: {trigger_type}"
         }

  4. Publish crisis.started event:
     - Topic: project.crisis.started
     - Payload: {project_id, source_id, alert_id, severity, metrics}
     - Consumers:
       * Notification Service → Send alerts (email, Slack, SMS)

OUTPUT: Alert stored + Events published
  ├─ Alert history saved for dashboard
  ├─ Adaptive crawl triggered (if CRITICAL + crawl source)
  └─ Notifications sent to user

NOTE: Project Service gọi Ingest Service API để update mode
      KHÔNG update database của Ingest Service trực tiếp
```

---

### 7.7 Kafka Topics Summary

```yaml
# Config management
project.config.updated:
  producer: project-srv
  consumer: analytics-srv
  payload: { project_id, crisis_detection, updated_by, timestamp }
  purpose: Notify Analytics Service of config changes (cache for crisis detection)

# Metrics aggregation (for adaptive crawl)
analytics.metrics.aggregated:
  producer: analytics-srv
  consumer: project-srv
  payload: { source_id, negative_ratio, velocity, new_items_count, time_window }
  purpose: Trigger adaptive crawl mode changes

# Crisis detection
analytics.crisis.detected:
  producer: analytics-srv
  consumer: project-srv
  payload:
    {
      alert_id,
      project_id,
      source_id,
      trigger_type,
      severity,
      metrics,
      matched_rules,
      sample_posts,
    }
  purpose: Alert Project Service of detected crisis

# Crisis notification
project.crisis.started:
  producer: project-srv
  consumers: [noti-srv]
  payload: { project_id, source_id, alert_id, severity, metrics, timestamp }
  purpose: Send notifications to user (email, Slack, SMS)

project.crisis.resolved:
  producer: project-srv
  consumers: [noti-srv]
  payload: { project_id, source_id, alert_id, duration_minutes }
  purpose: Notify crisis resolved

# Adaptive crawl mode change (optional notification)
project.mode.changed:
  producer: project-srv
  consumers: [noti-srv]
  payload: { source_id, old_mode, new_mode, reason, timestamp }
  purpose: Notify mode change (optional - for monitoring)
```

---

### 7.8 Implementation Checklist

**Project Service:**

- [ ] Database: Create `project_configs` table (crisis_detection only)
- [ ] Database: Create `crisis_alerts` table
- [ ] API: PUT /projects/{id}/config (crisis_detection)
- [ ] API: GET /projects/{id}/config (crisis_detection)
- [ ] API: GET /projects/{id}/crisis-alerts (list alerts)
- [ ] Consumer: analytics.crisis.detected → Store alert + Trigger adaptive crawl (if CRITICAL)
- [ ] Consumer: analytics.metrics.aggregated → Adaptive Scheduler (extract threshold from crisis_detection)
- [ ] Producer: project.config.updated (when config changes)
- [ ] Producer: project.crisis.started (when crisis detected)
- [ ] Producer: project.mode.changed (when crawl mode changes)
- [ ] Adaptive Scheduler: Extract threshold from crisis_detection.sentiment_trigger.threshold_percent
- [ ] Adaptive Scheduler: Compare metrics vs threshold → Call Ingest API if mode change needed
- [ ] Adaptive Scheduler: Sleep mode detection (< 10 items/hour hardcoded)

**Analytics Service:**

- [ ] Consumer: project.config.updated → Cache crisis_detection config
- [ ] Background Job: Crisis Detector (every 5 min)
- [ ] Detection Logic: Keywords, Volume, Sentiment, Influencer triggers
- [ ] Producer: analytics.crisis.detected (when crisis detected)
- [ ] Producer: analytics.metrics.aggregated (every 5 min per source)

**Notification Service:**

- [ ] Consumer: project.crisis.started → Send alerts via email, Slack, SMS
- [ ] Consumer: project.crisis.resolved → Send resolution notification
- [ ] Consumer: project.mode.changed → Send mode change notification (optional)

---

## 8. DASHBOARD ORCHESTRATION

### 8.1 Architecture Pattern

**API Gateway Pattern** - Project Service là single entry point cho Dashboard.

```
[User Browser]
    ↓ GET /projects/{id}/dashboard
[Project Service - Dashboard Module]
    ├─► Query schema_project.projects (metadata)
    ├─► Query schema_ingest.data_sources (sources summary)
    └─► HTTP GET /analytics/projects/{id}/insights
        ↓
    [Analytics Service]
        ├─► Check Redis cache (5 min TTL)
        └─► Query analytics.post_analytics
        ↓ Return JSON
    [Project Service]
        - Combine: metadata + sources + analytics
        - Return unified response
```

### 8.2 Dashboard Response Structure

```json
{
  "project": {
    "id": "proj_vf8",
    "name": "Monitor VF8",
    "brand": "VinFast",
    "status": "ACTIVE",
    "activated_at": "2026-02-01T00:00:00Z"
  },
  "sources": {
    "total_sources": 4,
    "total_records": 2100,
    "breakdown": {
      "file_sources": 1,
      "webhook_sources": 1,
      "crawl_sources": 2
    },
    "crawl_modes": {
      "crisis": 1,
      "normal": 1,
      "sleep": 0
    },
    "sources_detail": [
      {
        "id": "src_excel_01",
        "name": "Feedback Q1",
        "type": "FILE_UPLOAD",
        "status": "COMPLETED",
        "record_count": 500
      },
      {
        "id": "src_tiktok_01",
        "name": "TikTok VF8",
        "type": "TIKTOK",
        "status": "ACTIVE",
        "crawl_mode": "NORMAL",
        "record_count": 1000
      }
    ]
  },
  "analytics": {
    "sentiment": {
      "positive": 45,
      "neutral": 30,
      "negative": 25
    },
    "top_keywords": [
      {"keyword": "pin", "count": 110},
      {"keyword": "giá", "count": 100}
    ],
    "trends": [...],
    "aspects": [...]
  }
}
```

### 8.3 Real-time Updates

**HTTP Pull (initial load) + WebSocket Push (real-time updates)**

```
Initial Load:
  User opens dashboard → HTTP GET /dashboard → Full data

Real-time Updates:
  [Notification Service]
      - Consume: project.crisis.started
      - Push WebSocket: {type: "CRISIS_ALERT", payload: {...}}
      ↓
  [User Browser]
      - Receive WebSocket message
      - Update crisis badge (no full reload)
```

---

## 9. KAFKA TOPICS

### 9.1 Topics Produced by Project Service

```yaml
# Lifecycle Events
project.created:
  payload: {project_id, name, entity_type, sources[], created_by}
  consumers: [analytics-srv, knowledge-srv]

project.activated:
  payload: {project_id, sources[], analytics_config, activated_at}
  consumers: [ingest-srv, analytics-srv, knowledge-srv]

project.paused:
  payload: {project_id, paused_by, reason}
  consumers: [ingest-srv]

project.resumed:
  payload: {project_id, resumed_by}
  consumers: [ingest-srv]

project.archived:
  payload: {project_id, source_ids[], archived_by, timestamp}
  consumers: [ingest-srv]
  purpose: Cancel all scheduled jobs for archived sources

# Orchestration Commands
ingest.crawl.requested:
  payload: {source_id, profile, config}
  consumer: ingest-srv

ingest.file.process:
  payload: {source_id, file_url, mapping_rules}
  consumer: ingest-srv

ingest.webhook.activate:
  payload: {source_id, webhook_url, secret, payload_schema}
  consumer: ingest-srv

# Adaptive Crawl Events
project.crisis.started:
  payload: {project_id, source_id, metrics, severity, reason}
  consumers: [ingest-srv, noti-srv]

project.crisis.resolved:
  payload: {project_id, source_id, duration_minutes}
  consumers: [ingest-srv, noti-srv]

project.mode.changed:
  payload: {source_id, old_mode, new_mode, reason}
  consumers: [ingest-srv]
```

### 9.2 Topics Consumed by Project Service

```yaml
# Feedback from Analytics (for Adaptive Crawl)
analytics.metrics.aggregated:
  producer: analytics-srv
  purpose: Adaptive crawl decision making
  payload:
    source_id: string # "src_tiktok_01"
    project_id: string # "proj_vf8"
    new_items_count: int # 50
    negative_ratio: float # 0.45 (45%)
    positive_ratio: float # 0.30 (30%)
    neutral_ratio: float # 0.25 (25%)
    velocity: float # 50.0 (items/hour)
    avg_sentiment_score: float # -0.35 (-1 to 1)
    time_window: string # "last_5min"
    timestamp: string # "2026-02-19T10:30:00Z"
  example:
    {
      "source_id": "src_tiktok_01",
      "project_id": "proj_vf8",
      "new_items_count": 50,
      "negative_ratio": 0.45,
      "positive_ratio": 0.30,
      "neutral_ratio": 0.25,
      "velocity": 50.0,
      "avg_sentiment_score": -0.35,
      "time_window": "last_5min",
      "timestamp": "2026-02-19T10:30:00Z",
    }

# Status updates from Ingest (after crawl execution)
ingest.crawl.completed:
  producer: ingest-srv
  purpose: Update crawl schedule and metrics
  payload:
    source_id: string # "src_tiktok_01"
    project_id: string # "proj_vf8"
    items_count: int # 50 (items fetched)
    status: string # "SUCCESS" | "FAILED" | "PARTIAL"
    error_message: string # null or error details
    crawl_duration_ms: int # 3500 (execution time)
    next_cursor: string # Pagination cursor (optional)
    timestamp: string # "2026-02-19T10:25:00Z"
  example:
    {
      "source_id": "src_tiktok_01",
      "project_id": "proj_vf8",
      "items_count": 50,
      "status": "SUCCESS",
      "error_message": null,
      "crawl_duration_ms": 3500,
      "next_cursor": "cursor_abc103",
      "timestamp": "2026-02-19T10:25:00Z",
    }

# File processing completion
ingest.file.completed:
  producer: ingest-srv
  purpose: Update data source status after file processing
  payload:
    source_id: string # "src_excel_01"
    project_id: string # "proj_vf8"
    items_count: int # 500 (rows processed)
    status: string # "SUCCESS" | "FAILED"
    error_message: string # null or error details
    file_url: string # "s3://bucket/file.xlsx"
    processing_duration_ms: int # 10000
    timestamp: string # "2026-02-19T10:20:00Z"
  example:
    {
      "source_id": "src_excel_01",
      "project_id": "proj_vf8",
      "items_count": 500,
      "status": "SUCCESS",
      "error_message": null,
      "file_url": "s3://smap-uploads/proj_vf8/feedback_q1.xlsx",
      "processing_duration_ms": 10000,
      "timestamp": "2026-02-19T10:20:00Z",
    }

# Dry run completion
ingest.dryrun.completed:
  producer: ingest-srv
  purpose: Update project config_status with dry run results
  payload:
    source_id: string # "src_youtube_01"
    project_id: string # "proj_vf8"
    status: string # "SUCCESS" | "FAILED" | "WARNING"
    sample_data: array # Sample items (max 10)
    total_found: int # Total items available
    error_message: string # null or error details
    warnings: array # ["Low quality data", ...]
    timestamp: string # "2026-02-19T10:11:00Z"
  example:
    {
      "source_id": "src_youtube_01",
      "project_id": "proj_vf8",
      "status": "SUCCESS",
      "sample_data":
        [
          {
            "title": "VF8 Review 2026",
            "author": "Tech Reviewer",
            "views": 5000,
            "published_at": "2026-02-18T10:00:00Z",
            "content": "Great car but battery drains fast...",
          },
        ],
      "total_found": 110,
      "error_message": null,
      "warnings": [],
      "timestamp": "2026-02-19T10:11:00Z",
    }
```

---

## 10. TESTING SCENARIOS

### 10.1 Scenario 1: Add FILE_UPLOAD to ACTIVE Project

```
Given: Project ACTIVE with 1 TikTok source (ACTIVE, NORMAL mode)
When: User adds FILE_UPLOAD source
Then:
  - Source created: status=PENDING, source_category=passive
  - NO dry run required
  - User uploads file → Onboarding (AI Schema Mapping)
  - User confirms mapping → status=READY
  - User activates → status=ACTIVE
  - crawl_mode remains NULL (not applicable)
  - Analytics Service SKIPS this source
  - Adaptive Scheduler SKIPS this source
```

### 10.2 Scenario 2: Add YOUTUBE to ACTIVE Project

```
Given: Project ACTIVE with 1 Excel source (COMPLETED)
When: User adds YOUTUBE source
Then:
  - Source created: status=PENDING, source_category=crawl
  - Dry run REQUIRED
  - User triggers dry run → dryrun_status=RUNNING
  - Dry run completes → dryrun_status=SUCCESS, status=READY
  - User activates → status=ACTIVE, crawl_mode=NORMAL
  - Scheduler picks up and starts crawling
  - Analytics Service INCLUDES this source
  - Adaptive Scheduler processes metrics
```

### 10.3 Scenario 3: Crisis Detected on New Source

```
Given: YouTube source just activated (5 min ago)
When: First batch analyzed, 45% negative
Then:
  - Analytics aggregates metrics
  - Publishes: analytics.metrics.aggregated
  - Adaptive Scheduler receives
  - Compares with baseline
  - Switches to CRISIS mode (2 min interval)
  - Publishes: project.crisis.started
  - Notification Service sends alert
  - Dashboard shows crisis badge
```

### 10.4 Scenario 4: Add Source When Project PAUSED

```
Given: Project PAUSED
When: User adds new source
Then:
  - Source created: status=PENDING ✅
  - User can configure and dry run ✅
  - User CANNOT activate ❌
  - Error: "Cannot activate source when project is paused"
  - Solution: User must resume project first
```

---

## 11. CONCLUSION

Project Service là "Orchestration Brain" của hệ thống SMAP Enterprise với các trách nhiệm chính:

1. ✅ **Lifecycle Management:** Quản lý state machine của Project và Data Source
2. ✅ **Data Ingestion Orchestration:** Điều phối thu thập dữ liệu từ đa nguồn
3. ✅ **Adaptive Crawl Controller:** Điều khiển thu thập thích ứng dựa trên metrics
4. ✅ **Integration Hub:** Kết nối Frontend với các backend services
5. ✅ **Crisis Detection:** Quản lý rules và trigger alerts
6. ✅ **Dashboard Orchestration:** Tổng hợp dữ liệu từ nhiều nguồn

**Key Principles:**

- Decision Maker (WHAT, WHEN, WHY) - NOT Executor (HOW)
- Manage metadata - NOT execution
- Orchestrate - NOT implement
- Coordinate - NOT duplicate

**Status:** SPECIFICATION COMPLETE - READY FOR IMPLEMENTATION 🚀

---

**Last Updated:** 19/02/2026  
**Version:** 2.0 (Consolidated)  
**Author:** System Architect
