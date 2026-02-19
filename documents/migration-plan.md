# SMAP Migration Plan v2.0

## Từ Public SaaS → On-Premise Enterprise Solution

**Ngày tạo:** 06/02/2026  
**Cập nhật:** 15/02/2026 (v2.11 - Auth Service Adaptation to Current Implementation)  
**Thời gian thực hiện:** 3 tháng (12 tuần)  
**Người thực hiện:** Nguyễn Tấn Tài

---

**Changelog:**

| Version | Ngày       | Nội dung                                                                     |
| ------- | ---------- | ---------------------------------------------------------------------------- |
| v2.0    | 06/02/2026 | Initial migration plan                                                       |
| v2.1    | 06/02/2026 | Tích hợp UAP, Entity Hierarchy, AI Schema Agent                              |
| v2.2    | 06/02/2026 | Tích hợp Time Handling Strategy                                              |
| v2.3    | 07/02/2026 | Chốt Hybrid Architecture & Multi-Schema Database                             |
| v2.4    | 07/02/2026 | Enhanced UX: Dry-Run, Vector Trigger, Campaign War Room                      |
| v2.5    | 07/02/2026 | Real-time Engine & Intelligent Crawling                                      |
| v2.6    | 07/02/2026 | Artifact Editing: Inline Editor + Google Docs Integration                    |
| v2.7    | 07/02/2026 | Turnkey Deployment Strategy (IaC): Ansible + K3s + Helm                      |
| v2.8    | 09/02/2026 | Auth Service Deep Dive: JWT Middleware, Audit Log Strategy, Business Context |
| v2.9    | 09/02/2026 | Enterprise Security: Token Blacklist, Multi-Provider, Key Rotation           |
| v2.10   | 09/02/2026 | **REVISION:** Analytics Service - Revert n8n, Keep Traditional Go Service    |
| v2.11   | 15/02/2026 | **ADAPTATION:** Auth Service - Align with Current Identity Service v2.0.0    |

---

## 0. TECHNICAL FOUNDATION

### 0.1 Unified Analytics Payload (UAP) - Canonical Data Model

Mọi dữ liệu đầu vào (Excel, CSV, JSON, Social Crawl) **BẮT BUỘC** phải được chuẩn hóa về định dạng UAP trước khi vào Analytics Service.

```json
{
  "id": "uuid-v4", // Định danh duy nhất
  "project_id": "proj_vinfast_qv", // Thuộc Project nào
  "source_id": "src_excel_feedback_t1", // Truy vết nguồn gốc

  "content": "Xe đi êm nhưng pin sụt nhanh quá", // [CORE] Văn bản để AI phân tích

  // TIME SEMANTICS (2 trường thời gian riêng biệt - BẮT BUỘC)
  "content_created_at": "2026-02-06T01:00:00Z", // [CORE] Thời điểm sự kiện xảy ra (UTC)
  "ingested_at": "2026-02-06T10:00:00Z", // [SYSTEM] Thời điểm SMAP thu thập (UTC)

  "platform": "internal_excel", // Nguồn gốc (tiktok, youtube, excel, crm)
  "metadata": {
    // Dữ liệu phụ (Schema-less) cho RAG
    "author": "Nguyễn Văn A",
    "rating": 4,
    "branch": "Chi nhánh HCM",
    "original_time_value": "06/02/2026 08:00", // Giá trị thời gian gốc (trước normalize)
    "time_type": "absolute" // absolute | relative | fallback
  }
}
```

**Time Fields Explanation:**

| Field                | Mục đích                                                   | Ví dụ                                                                |
| -------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------- |
| `content_created_at` | **Business:** Trend charts, RAG context, behavior analysis | User đăng comment lúc 01:00 AM VN → stored as 18:00 UTC (ngày trước) |
| `ingested_at`        | **Ops:** Latency measurement, debug, filter recent records | SMAP crawl lúc 10:00 AM VN → stored as 03:00 UTC                     |

**Lợi ích:**

- Analytics Service **không phụ thuộc** vào nguồn dữ liệu gốc
- Dễ dàng thêm nguồn dữ liệu mới mà không sửa core logic
- Metadata schema-less cho phép RAG trích xuất linh hoạt
- **Time semantics rõ ràng** - không nhầm lẫn giữa thời gian thực và thời gian thu thập

### 0.2 Entity Hierarchy - Mô hình 3 tầng

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTITY HIERARCHY                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Tầng 3: CAMPAIGN (Logical Analysis Unit)                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Campaign "So sánh Xe điện"                             │    │
│  │  ├── Project "Monitor VF8"  (brand=VinFast)             │    │
│  │  └── Project "Monitor BYD Seal" (brand=BYD)             │    │
│  │  → RAG scope: WHERE project_id IN ('VF8', 'BYD Seal')   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           ↑                                     │
│  Tầng 2: PROJECT (Entity Monitoring Unit)                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Project "Monitor VF8"                                  │    │
│  │  ├── brand: "VinFast" (text, dùng để nhóm hiển thị)    │    │
│  │  ├── entity_type: "product"                             │    │
│  │  ├── entity_name: "VF8"                                 │    │
│  │  ├── Data Source: Excel Feedback T1                     │    │
│  │  ├── Data Source: TikTok Crawl "vinfast vf8"            │    │
│  │  └── Data Source: Webhook từ CRM                        │    │
│  │  → Health Check: Dashboard riêng cho entity VF8         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           ↑                                     │
│  Tầng 1: DATA SOURCE (Physical Data Unit)                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Data Source "Excel Feedback T1"                        │    │
│  │  ├── Raw File: feedback_t1.xlsx                         │    │
│  │  ├── Schema Mapping: AI Agent suggested                 │    │
│  │  └── Output: 500 UAP records                            │    │
│  │  → Normalization: Biến raw data thành UAP               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Vai trò từng tầng:**

| Tầng | Entity      | Vai trò                | Chức năng chính                                       |
| ---- | ----------- | ---------------------- | ----------------------------------------------------- |
| 1    | Data Source | Physical Data Unit     | Chuẩn hóa raw → UAP                                   |
| 2    | Project     | Entity Monitoring Unit | Dashboard, Health Check, Alerts cho 1 thực thể cụ thể |
| 3    | Campaign    | Logical Analysis Unit  | RAG scope, So sánh cross-project                      |

> **Lưu ý:** Project = 1 thực thể cụ thể cần monitor (sản phẩm, chiến dịch, dịch vụ...), KHÔNG phải toàn bộ brand. Brand chỉ là text field metadata để nhóm hiển thị.

#### 0.2.1 Multi-Source per Project - Quan hệ 1:N (CRITICAL)

**Nguyên tắc quan trọng:** Một Project có thể có NHIỀU Data Sources với các loại khác nhau, hoạt động song song và độc lập.

```
┌─────────────────────────────────────────────────────────────────┐
│  Project "Monitor VF8" (1 Project)                              │
│  ├── brand: "VinFast"                                           │
│  ├── entity_type: "product"                                     │
│  ├── entity_name: "VF8"                                         │
│  │                                                              │
│  ├── Data Source 1: Excel "Feedback Q1.xlsx" (PASSIVE)          │
│  │   ├── Type: FILE_UPLOAD                                      │
│  │   ├── Status: COMPLETED                                      │
│  │   ├── Records: 500 UAP                                       │
│  │   ├── Onboarding: AI Schema Mapping DONE                     │
│  │   └── Trigger: Manual upload (one-time)                      │
│  │                                                              │
│  ├── Data Source 2: TikTok Crawl "vinfast vf8" (CRAWL)          │
│  │   ├── Type: TIKTOK                                           │
│  │   ├── Status: ACTIVE                                         │
│  │   ├── Records: 1000 UAP (ongoing)                            │
│  │   ├── Crawl Mode: NORMAL (15 min interval)                   │
│  │   ├── Dry Run: SUCCESS                                       │
│  │   └── Trigger: Scheduled poll (every 15 min)                 │
│  │                                                              │
│  ├── Data Source 3: Webhook từ CRM (PASSIVE)                    │
│  │   ├── Type: WEBHOOK                                          │
│  │   ├── Status: ACTIVE                                         │
│  │   ├── Records: 300 UAP (ongoing)                             │
│  │   ├── Onboarding: AI Schema Mapping DONE                     │
│  │   ├── Webhook URL: https://smap.com/webhook/abc123           │
│  │   └── Trigger: External push (real-time)                     │
│  │                                                              │
│  └── Data Source 4: YouTube Crawl "vf8 review" (CRAWL)          │
│      ├── Type: YOUTUBE                                          │
│      ├── Status: ACTIVE                                         │
│      ├── Records: 300 UAP (ongoing)                             │
│      ├── Crawl Mode: CRISIS (2 min interval) ← Adaptive!        │
│      ├── Dry Run: SUCCESS                                       │
│      └── Trigger: Scheduled poll (every 2 min - crisis mode)    │
│                                                                 │
│  → Dashboard aggregates: 500 + 1000 + 300 + 300 = 2100 UAP      │
│  → Có thể filter theo từng source_id                            │
│  → Mỗi source có lifecycle và schedule riêng biệt               │
└─────────────────────────────────────────────────────────────────┘
```

**Quan hệ Database:**

```sql
-- 1 Project : N Data Sources
schema_project.projects (1)
    ↓ project_id
schema_ingest.data_sources (N)

-- Example:
-- project_id = "proj_vf8"
--   ├── source_id = "src_excel_01"    (FILE_UPLOAD)
--   ├── source_id = "src_tiktok_01"   (TIKTOK, crawl_mode=NORMAL)
--   ├── source_id = "src_webhook_01"  (WEBHOOK)
--   └── source_id = "src_youtube_01"  (YOUTUBE, crawl_mode=CRISIS)
```

**Lifecycle độc lập của từng Data Source:**

| Source Type     | Lifecycle                                           | Schedule                  | Adaptive Crawl                   |
| --------------- | --------------------------------------------------- | ------------------------- | -------------------------------- |
| **FILE_UPLOAD** | One-time: Upload → Onboarding → Process → COMPLETED | Manual trigger            | ❌ Không áp dụng                 |
| **WEBHOOK**     | Continuous: Activate → Receive → Process (ongoing)  | External push (real-time) | ❌ Không áp dụng                 |
| **FACEBOOK**    | Continuous: Activate → Crawl → Process (ongoing)    | Scheduled poll            | ✅ Áp dụng (Sleep/Normal/Crisis) |
| **TIKTOK**      | Continuous: Activate → Crawl → Process (ongoing)    | Scheduled poll            | ✅ Áp dụng (Sleep/Normal/Crisis) |
| **YOUTUBE**     | Continuous: Activate → Crawl → Process (ongoing)    | Scheduled poll            | ✅ Áp dụng (Sleep/Normal/Crisis) |

**Flow chi tiết cho từng loại:**

**1. FILE_UPLOAD (Passive - One-time):**

```
User uploads Excel file
    ↓
[Project Service]
    - Validate project is ACTIVE
    - Create data_source (type=FILE_UPLOAD, status=PENDING)
    - Generate MinIO presigned URL
    - Return upload URL to user
    ↓
[User uploads file to MinIO]
    ↓
[Project Service]
    - Detect file uploaded (MinIO webhook)
    - Trigger AI Schema Mapping (Onboarding)
    - User confirms mapping
    - Publish: ingest.file.process {source_id, file_url, mapping_rules}
    ↓
[Ingest Service]
    - Download file from MinIO
    - Parse Excel → rows
    - Apply mapping_rules
    - Transform rows → UAP batch
    - Publish: smap.collector.output (UAP batch)
    - Publish: ingest.file.completed {source_id, items_count=500}
    ↓
[Project Service]
    - Update data_source (status=COMPLETED, record_count=500)
    - NO SCHEDULE (one-time only)
```

**2. WEBHOOK (Passive - Continuous):**

```
User configures webhook
    ↓
[Project Service]
    - Create data_source (type=WEBHOOK, status=PENDING)
    - User defines payload_schema
    - Trigger AI Schema Mapping (Onboarding)
    - User confirms mapping
    - Generate webhook_url + secret
    - Publish: ingest.webhook.activate {source_id, webhook_url, secret, mapping_rules}
    ↓
[Ingest Service]
    - Register webhook endpoint
    - Listen for incoming requests
    ↓
[External CRM pushes data]
    POST https://smap.com/webhook/abc123
    Body: {"customer_name": "...", "feedback": "...", "date": "..."}
    ↓
[Ingest Service]
    - Validate signature (HMAC)
    - Apply mapping_rules
    - Transform → UAP
    - Publish: smap.collector.output (UAP single/batch)
    ↓
[Project Service]
    - Update data_source.last_received_at
    - Increment data_source.record_count
    - NO SCHEDULE (event-driven)
```

**3. TIKTOK/YOUTUBE/FACEBOOK (Crawl - Continuous + Adaptive):**

```
Project activated
    ↓
[Project Service]
    - Create data_source (type=TIKTOK, status=PENDING)
    - User configures keywords, filters
    - Trigger Dry Run
    - User confirms Dry Run results
    - Update data_source (status=ACTIVE, crawl_mode=NORMAL, crawl_interval=15)
    - Schedule initial crawl: next_crawl_at = NOW()
    ↓
[Project Service - Scheduler (runs every 1 minute)]
    - Query: SELECT * FROM schema_ingest.data_sources
             WHERE next_crawl_at <= NOW() AND status = 'ACTIVE'
    - Found: src_tiktok_01 (due now)
    - Publish: ingest.crawl.requested {
        source_id: "src_tiktok_01",
        profile: "INCREMENTAL_MONITOR",
        config: {keywords: ["vinfast vf8"], date_range: "since_last_crawl"}
      }
    ↓
[Ingest Service - Worker]
    - Consume: ingest.crawl.requested
    - Call external crawl API (teammate's server)
    - Receive raw data (50 items)
    - Transform → UAP batch
    - Publish: smap.collector.output (UAP batch)
    - Publish: ingest.crawl.completed {source_id, items_count=50}
    ↓
[Analytics Service]
    - Consume: smap.collector.output
    - Analyze 50 items
    - Detect: negative_ratio = 45% (CRISIS!)
    - Publish: analytics.metrics.aggregated {
        source_id: "src_tiktok_01",
        new_items_count: 50,
        negative_ratio: 0.45,
        velocity: 50 items/hour
      }
    ↓
[Project Service - Adaptive Scheduler]
    - Consume: analytics.metrics.aggregated
    - Load baseline: avg_negative_ratio = 12%
    - Compare: 45% >> 12% → SWITCH TO CRISIS MODE
    - Update data_source:
        - crawl_mode: NORMAL → CRISIS
        - crawl_interval: 15min → 2min
        - next_crawl_at: NOW() + 2min
    - Publish: project.crisis.started
    ↓
[Ingest Service]
    - Consume: project.crisis.started
    - Cancel old schedule (15min)
    - Schedule new job (2min)
    - Trigger crawl IMMEDIATELY
    ↓
[Loop continues with 2min interval until crisis resolved]
```

**Dashboard Aggregation:**

```sql
-- Dashboard query: Aggregate TẤT CẢ sources của 1 project
SELECT
    p.id AS project_id,
    p.name AS project_name,
    COUNT(DISTINCT ds.id) AS total_sources,
    SUM(ds.record_count) AS total_records,

    -- Breakdown by source type
    COUNT(DISTINCT CASE WHEN ds.source_type = 'FILE_UPLOAD' THEN ds.id END) AS file_sources,
    COUNT(DISTINCT CASE WHEN ds.source_type = 'WEBHOOK' THEN ds.id END) AS webhook_sources,
    COUNT(DISTINCT CASE WHEN ds.source_category = 'crawl' THEN ds.id END) AS crawl_sources,

    -- Crawl mode breakdown (chỉ cho crawl sources)
    COUNT(DISTINCT CASE WHEN ds.crawl_mode = 'CRISIS' THEN ds.id END) AS crisis_sources,
    COUNT(DISTINCT CASE WHEN ds.crawl_mode = 'NORMAL' THEN ds.id END) AS normal_sources,
    COUNT(DISTINCT CASE WHEN ds.crawl_mode = 'SLEEP' THEN ds.id END) AS sleep_sources

FROM schema_project.projects p
LEFT JOIN schema_ingest.data_sources ds ON ds.project_id = p.id
WHERE p.id = 'proj_vf8'
GROUP BY p.id, p.name;

-- Result:
-- project_id | project_name | total_sources | total_records | file_sources | webhook_sources | crawl_sources | crisis_sources | normal_sources | sleep_sources
-- proj_vf8   | Monitor VF8  | 4             | 2100          | 1            | 1               | 2             | 1              | 1              | 0
```

**Key Insights:**

1. ✅ **Một Project có thể có NHIỀU sources** - không giới hạn số lượng
2. ✅ **Mỗi source có lifecycle riêng** - FILE_UPLOAD one-time, WEBHOOK continuous, CRAWL scheduled
3. ✅ **Adaptive Crawl chỉ áp dụng cho CRAWL sources** - FILE_UPLOAD và WEBHOOK không có schedule
4. ✅ **Mỗi CRAWL source có crawl_mode riêng** - Source A có thể CRISIS, Source B vẫn NORMAL
5. ✅ **Dashboard aggregate TẤT CẢ sources** - user thấy tổng thể, có thể filter theo source_id
6. ✅ **Sources hoạt động song song và độc lập** - không block lẫn nhau

**Ví dụ thực tế:**

```
Project "Monitor VF8" có 4 sources:

Timeline:
─────────────────────────────────────────────────────────────────
T0 (Day 1):
  - User uploads Excel (500 records) → COMPLETED ngay
  - User configures TikTok crawl → Dry Run → Activate
  - TikTok starts crawling every 15 min

T1 (Day 2):
  - User configures Webhook → Generate URL → Activate
  - CRM starts pushing data (real-time)
  - TikTok continues crawling (15 min interval)

T2 (Day 3):
  - User adds YouTube crawl → Dry Run → Activate
  - YouTube starts crawling every 15 min
  - TikTok continues (15 min)
  - Webhook continues (real-time)

T3 (Day 4):
  - Analytics detects crisis on YouTube (45% negative)
  - YouTube switches to CRISIS mode (2 min interval)
  - TikTok continues NORMAL mode (15 min) ← Không bị ảnh hưởng
  - Webhook continues (real-time)

T4 (Day 5):
  - YouTube crisis resolved → Back to NORMAL (15 min)
  - All sources continue normally

Dashboard shows:
  - Total records: 500 (Excel) + 2000 (TikTok) + 500 (Webhook) + 800 (YouTube) = 3800
  - Can filter by source to see breakdown
─────────────────────────────────────────────────────────────────
```

### 0.3 AI Schema Agent - Universal Adapter

**Workflow chuẩn hóa dữ liệu:**

```
┌──────────────────────────────────────────────────────────────────┐
│                    AI SCHEMA AGENT WORKFLOW                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. INGESTION                                                    │
│     User upload file (Excel/CSV/JSON)                            │
│                    ↓                                             │
│  2. INSPECTION (LLM)                                             │
│     AI đọc Header + 5 dòng đầu                                   │
│     Prompt: "Tìm cột 'Nội dung phản hồi' → map sang content"     │
│                    ↓                                             │
│  3. SUGGESTION                                                   │
│     Hiển thị bảng mapping gợi ý:                                 │
│     ┌────────────────────┬─────────────┬────────────┐            │
│     │ Cột gốc            │ UAP Field   │ Confidence │            │
│     ├────────────────────┼─────────────┼────────────┤            │
│     │ Ý kiến khách hàng  │ content     │ 95%        │            │
│     │ Ngày gửi           │ created_at  │ 90%        │            │
│     │ Tên KH             │ metadata.   │ 85%        │            │
│     │                    │ author      │            │            │
│     └────────────────────┴─────────────┴────────────┘            │
│                    ↓                                             │
│  4. CONFIRMATION                                                 │
│     User xác nhận hoặc chỉnh sửa mapping                         │
│                    ↓                                             │
│  5. TRANSFORMATION (ETL)                                         │
│     Convert toàn bộ file → UAP records                           │
│     Push vào Message Queue → Analytics Service                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 0.4 Time Handling Strategy - Chiến lược Xử lý Thời gian

**Vấn đề:** Sai lệch timezone, định dạng ngày tháng không đồng nhất, và nhầm lẫn giữa "thời gian thực" vs "thời gian thu thập" có thể gây sai lệch nghiêm trọng trong Trend charts và Alert system.

#### 0.4.1 Time Semantics - 2 Trường Thời gian Bắt buộc

| Trường                   | Định nghĩa                                    | Mục đích                               |
| ------------------------ | --------------------------------------------- | -------------------------------------- |
| **`content_created_at`** | Thời điểm sự kiện xảy ra (user đăng, ghi log) | **Business:** Trend, RAG, behavior     |
| **`ingested_at`**        | Thời điểm SMAP thu thập                       | **Ops:** Latency, debug, filter recent |

#### 0.4.2 Storage & Normalization Rules

| Aspect            | Rule                                           |
| ----------------- | ---------------------------------------------- |
| **Format**        | ISO 8601 UTC (`YYYY-MM-DDThh:mm:ssZ`)          |
| **Database**      | PostgreSQL: `TIMESTAMPTZ`, MongoDB: `ISODate`  |
| **Qdrant**        | Unix Timestamp (Integer) cho range filtering   |
| **Relative time** | "2 giờ trước" → Tính từ `ingested_at`          |
| **Fallback**      | Không parse được → Dùng `ingested_at` cho cả 2 |

#### 0.4.3 Key Implementation Points

**Dashboard Visualization:**

- Client gửi timezone: `?tz=Asia/Ho_Chi_Minh`
- Server aggregate: `GROUP BY date_trunc('day', content_created_at AT TIME ZONE $tz)`

**Alert Logic:**

- Chỉ alert nếu `content_created_at` trong 24h gần nhất
- Historical import KHÔNG trigger crisis alert

**RAG Temporal Queries:**

- "tuần này" → Pre-filter `content_created_at` TRƯỚC vector search
- Tránh "ảo giác" lấy data cũ trả lời câu hỏi về hiện tại

### 0.5 Multi-Schema Database Strategy

**Vấn đề:** Microservices thuần túy yêu cầu Database-per-Service, nhưng với On-Premise B2B Solution, việc vận hành 5-6 DB instances gây lãng phí tài nguyên và phức tạp hóa Backup/Restore.

**Quyết định:** **Logical Separation on Single Physical Instance** - 1 PostgreSQL Cluster, phân chia bằng Schemas.

```
┌─────────────────────────────────────────────────────────────────┐
│              MULTI-SCHEMA DATABASE ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PostgreSQL Physical Instance (Single)                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ schema_identity.*      │  │ schema_project.*  │  │ schema_ingest.*    │      │    │
│  │  │ - users     │  │ - projects  │  │ - sources   │      │    │
│  │  │ - audit_logs│  │ - campaigns │  │ - jobs      │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  │                                                         │    │
│  │  ┌─────────────┐                                        │    │
│  │  │ schema_analysis.* │     ┌─────────────────────────────┐    │    │
│  │  │ - post_     │     │  Qdrant (Separate Instance) │    │    │
│  │  │   analytics │     │  - Vector embeddings        │    │    │
│  │  │ - comments  │     │  - RAG search               │    │    │
│  │  └─────────────┘     └─────────────────────────────┘    │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Schema Mapping:**

| Service           | Schema        | Tables                                 |
| ----------------- | ------------- | -------------------------------------- |
| Auth Service      | `schema_identity.*`      | users, audit_logs                      |
| Project Service   | `schema_project.*`  | projects, campaigns, campaign_projects |
| Ingest Service    | `schema_ingest.*`    | data_sources, jobs                     |
| Analytics Service | `schema_analysis.*` | post_analytics, comments, errors       |
| Knowledge Service | _(Qdrant)_    | Vector DB riêng                        |

**Anti-Superbase Rules:**

1. **No Cross-Schema Writes:** Service A KHÔNG được INSERT/UPDATE vào Schema của Service B
2. **Read-Only for Reporting:** JOIN cross-schema chỉ cho Dashboard/Reporting
3. **Single Connection String:** Khách hàng chỉ cần 1 connection, hệ thống tự migrate schemas

### 0.6 Hybrid Architecture - Tech Stack (FINALIZED v2.10)

**Chiến lược:** **Golang** (Core Services) + **Python** (AI Workers) - ~~n8n removed due to scalability issues~~

**REVISION v2.10:** Sau khi đánh giá hiện trạng, quyết định **KHÔNG dùng n8n** cho Analytics vì:

1. ❌ Không scale ngang được (single instance bottleneck)
2. ❌ Tốc độ chậm (overhead của visual workflow engine)
3. ❌ Khó debug production issues
4. ❌ Vendor lock-in

**Quyết định mới:** Giữ nguyên **analytics-service** (Go) với refactor structure.

```
┌─────────────────────────────────────────────────────────────────┐
│                    REVISED ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CORE SERVICES (Golang)                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│  │  Auth   │ │ Project │ │ Ingest  │ │Analytics│ │Knowledge│    │
│  │ Service │ │ Service │ │ Service │ │ Service │ │ Service │    │
│  └─────────┘ └─────────┘ └─────────┘ └────┬────┘ └─────────┘    │
│                                           │                     │
│                                           ↓ HTTP/gRPC           │
│  AI WORKERS (Python FastAPI)                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                │
│  │  Sentiment  │ │   Aspect    │ │  Keyword    │                │
│  │   Worker    │ │   Worker    │ │   Worker    │                │
│  │ (PhoBERT)   │ │  (PhoBERT)  │ │(Underthesea)│                │
│  └─────────────┘ └─────────────┘ └─────────────┘                │
│                                                                 │
│  NOTIFICATION SERVICE (Golang)                                  │
│  ┌─────────────┐                                                │
│  │    Noti     │                                                │
│  │   Service   │                                                │
│  └─────────────┘                                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Tech Stack Matrix:**

| Service               | Type           | Language/Tool      | Lý do                                          |
| --------------------- | -------------- | ------------------ | ---------------------------------------------- |
| Auth Service          | Core Logic     | **Golang**         | High performance, concurrency, strict typing   |
| Project Service       | Core Logic     | **Golang**         | Business logic chặt chẽ                        |
| Ingest Service        | Core Logic     | **Golang**         | File parsing nhanh, OpenAI SDK Go cho AI Agent |
| **Analytics Service** | **Core Logic** | **Golang**         | **Consumer + Orchestrator, scalable, fast**    |
| Notification          | Real-time      | **Golang**         | Xử lý hàng ngàn WebSocket connections          |
| Knowledge Service     | AI Logic       | **Golang**         | go-qdrant, go-openai - RAG pipeline tối ưu     |
| AI Workers            | Micro-func     | **Python FastAPI** | PhoBERT/Whisper wrappers, stateless            |

**Lợi ích của Go Analytics Service:**

- **Scalability:** Horizontal scaling với Kubernetes (multiple replicas)
- **Performance:** Go concurrency xử lý hàng ngàn UAP records/sec
- **Observability:** Standard logging, metrics, tracing
- **Maintainability:** Code-based logic dễ debug hơn visual workflows

---

## 1. TỔNG QUAN THAY ĐỔI

### 1.1 Mô hình kinh doanh

| Khía cạnh  | Cũ (SaaS)                 | Mới (On-Premise)                        |
| ---------- | ------------------------- | --------------------------------------- |
| Deployment | Centralized, multi-tenant | Distributed, single-tenant per customer |
| Data       | Trên server của SMAP      | Trên server của khách hàng              |
| Revenue    | Subscription monthly      | License fee + Support                   |
| Packaging  | Docker images             | Helm Charts                             |

### 1.2 Use Cases (Updated với Entity Hierarchy)

| Cũ (8 UC)                | Mới (3 UC)                | Entity Level | Ghi chú                                                       |
| ------------------------ | ------------------------- | ------------ | ------------------------------------------------------------- |
| UC-01: Cấu hình Project  | → UC-01: Data Onboarding  | Data Source  | Refactor: tách Crawl (Dry Run) vs Passive (AI Schema Mapping) |
| UC-02: Dry-run           | ❌ XOÁ (gộp vào UC-01)    | -            | Dry Run chỉ cho Crawl sources                                 |
| UC-03: Execute & Monitor | → UC-02: Brand Monitoring | Project      | Project = Entity cụ thể                                       |
| UC-04: Xem kết quả       | → UC-02: Brand Monitoring | Project      | Merge                                                         |
| UC-05: List Projects     | Giữ nguyên                | Project      | Filter theo brand                                             |
| UC-06: Export            | Giữ nguyên                | Project      | Utility                                                       |
| UC-07: Trend Detection   | ❌ XOÁ                    | -            | Không phù hợp                                                 |
| UC-08: Crisis Monitor    | → UC-02: Brand Monitoring | Project      | Merge                                                         |
| (Mới)                    | UC-03: RAG Chatbot        | Campaign     | Thêm mới                                                      |

**Use Case → Entity Mapping:**

- **UC-01 (Data Onboarding):** Tạo Data Source, AI Schema Agent chuẩn hóa → UAP
- **UC-02 (Brand Monitoring):** Dashboard cho 1 Project, không so sánh
- **UC-03 (RAG Chatbot):** Chọn Campaign → RAG query cross-project

---

## 2. RESTRUCTURE SERVICES THEO DDD

### 2.1 Bounded Contexts mới (Updated với UAP & Entity Hierarchy)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SMAP Enterprise Platform                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │     AUTH     │  │    INGEST    │  │  ANALYTICS   │           │
│  │   Context    │  │   Context    │  │   Context    │           │
│  │              │  │              │  │              │           │
│  │ • SSO/OAuth  │  │ • Data Source│  │ • UAP Input  │           │
│  │ • RBAC       │  │ • File Upload│  │ • Sentiment  │           │
│  │ • Domain ACL │  │ • Crawling   │  │ • ABSA       │           │
│  │              │  │ • AI Schema  │  │ • Keywords   │           │
│  │              │  │   Agent      │  │              │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   PROJECT    │  │ NOTIFICATION │  │  KNOWLEDGE   │           │
│  │   Context    │  │   Context    │  │   Context    │           │
│  │              │  │              │  │              │           │
│  │ • Project    │  │ • WebSocket  │  │ • Campaign   │           │
│  │   CRUD       │  │ • Alerts     │  │ • RAG Engine │           │
│  │ • Campaign   │  │ • Push Noti  │  │ • Vector DB  │           │
│  │   CRUD       │  │              │  │ • Chat       │           │
│  │ • Dashboard  │  │              │  │              │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow với UAP

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW WITH UAP                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  RAW DATA SOURCES                                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                │
│  │  Excel  │ │   CSV   │ │  JSON   │ │ Social  │                │
│  │  File   │ │  File   │ │  File   │ │ Crawl   │                │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘                │
│       │           │           │           │                     │
│       └───────────┴─────┬─────┴───────────┘                     │
│                         ↓                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              INGEST SERVICE                             │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │           AI SCHEMA AGENT (LLM)                 │    │    │
│  │  │  • Inspect raw data structure                   │    │    │
│  │  │  • Suggest field mapping                        │    │    │
│  │  │  • User confirmation                            │    │    │
│  │  │  • Transform to UAP                             │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              UNIFIED ANALYTICS PAYLOAD (UAP)            │    │
│  │  {                                                      │    │
│  │    "id": "uuid",                                        │    │
│  │    "project_id": "proj_xxx",                            │    │
│  │    "source_id": "src_xxx",                              │    │
│  │    "content": "...",        ← CORE: Text for AI         │    │
│  │    "created_at": "...",     ← CORE: Timestamp           │    │
│  │    "platform": "...",                                   │    │
│  │    "metadata": {...}        ← Schema-less for RAG       │    │
│  │  }                                                      │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              ANALYTICS SERVICE                          │    │
│  │  • Sentiment Analysis (PhoBERT)                         │    │
│  │  • Aspect-Based Sentiment Analysis                      │    │
│  │  • Keyword Extraction                                   │    │
│  │  • Impact Calculation                                   │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│       ┌────────────────────┴────────────────────┐               │
│       ↓                                         ↓               │
│  ┌─────────────┐                         ┌─────────────┐        │
│  │ PostgreSQL  │                         │   Qdrant    │        │
│  │ (analytics) │                         │ (vectors)   │        │
│  └──────┬──────┘                         └──────┬──────┘        │
│         ↓                                       ↓               │
│  ┌─────────────┐                         ┌─────────────┐        │
│  │  PROJECT    │                         │  KNOWLEDGE  │        │
│  │  SERVICE    │                         │  SERVICE    │        │
│  │ (Dashboard) │                         │ (RAG Chat)  │        │
│  └─────────────┘                         └─────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Service Mapping: Cũ → Mới

| Service Cũ    | Service Mới            | Language    | Hành động            | Lý do                                |
| ------------- | ---------------------- | ----------- | -------------------- | ------------------------------------ |
| `identity`    | `auth-service`         | **Go**      | 🔄 SIMPLIFY          | SSO, user entity cho audit log       |
| `project`     | `project-service`      | **Go**      | 🔄 EXTEND            | Thêm Campaign entity, Dashboard      |
| `collector`   | `ingest-service`       | **Go**      | 🔄 RENAME + REFACTOR | AI Schema Agent, file parsing        |
| `analytic`    | `analytics-service`    | **Go**      | 🔄 REFACTOR          | Consumer + Orchestrator, UAP input   |
| `websocket`   | `notification-service` | **Go**      | 🔄 RENAME            | Đổi tên cho rõ nghĩa hơn             |
| `speech2text` | `ai-workers`           | **Python**  | 🔀 MERGE             | Gộp thành AI worker                  |
| `scrapper`    | ❌ XOÁ                 | -           | 🗑️ REMOVE            | Outsource cho External Data Provider |
| `web-ui`      | `web-ui`               | **Next.js** | 🔄 REFACTOR          | Đổi UI flow theo Entity Hierarchy    |
| (Mới)         | `knowledge-service`    | **Go**      | ➕ TẠO MỚI           | RAG Chatbot với Campaign scope       |

### 2.4 Kiến trúc Services mới (Hybrid Architecture)

```
TRƯỚC (8 services):                    SAU (6 Core + AI Workers):
─────────────────────                  ─────────────────────
identity          ──────────────────►  auth-service (Go, simplified)
project           ──────────────────►  project-service (Go, + Campaign)
collector         ──────────────────►  ingest-service (Go, + AI Schema)
scrapper          ──────────────────►  ❌ XOÁ (dùng External API)
analytic          ──────────────────►  analytics-service (Go, refactor)
speech2text       ──────────────────►  ai-workers (Python FastAPI)
websocket         ──────────────────►  notification-service (Go)
(mới)             ──────────────────►  knowledge-service (Go, RAG)
web-ui            ──────────────────►  web-ui (Next.js)

Tech Stack Summary:
─────────────────────
Core Services    → Golang (6 services)
AI Workers       → Python FastAPI (3 workers: sentiment, aspect, keyword)
Frontend         → Next.js
Database         → 1 PostgreSQL (4 schemas) + Qdrant + Redis
Message Queue    → Kafka
```

---

## 3. CHI TIẾT TỪNG SERVICE MỚI

### 3.1 Auth Service (Adapted từ Identity Service v2.0.0)

> **ADAPTATION NOTE (v2.11):** Section này đã được cập nhật để phản ánh hiện trạng Identity Service v2.0.0 đang hoạt động tốt. Thay vì viết lại từ đầu, chúng ta sẽ refactor structure và bổ sung tính năng thiếu.

**Current State Assessment:**

✅ **STRENGTHS (Already Working):**

- OAuth2/OIDC integration với Google, Azure AD, Okta
- Token blacklist (Redis-based) cho instant revocation
- Session management (Redis DB 0)
- Audit log với Kafka async publishing
- Dual authentication mode (Cookie + Header)
- Rate limiting & domain-based access control
- 2 entry points: API server + Kafka consumer

🟡 **GAPS (Need Refactoring):**

- Database schema: `schema_identity.*` → `schema_identity.*` (2-3h)
- Folder name: `services/identity/` → `services/auth-service/` (2h)
- Provider abstraction: Hardcoded logic → Interface pattern (1d)
- User-level blacklist: Only token-level → Add user-level (1h)

**Business Context trong SMAP:**

Auth Service trong SMAP On-Premise có vai trò đặc biệt:

1. **Single-Tenant per Customer:**
   - Mỗi khách hàng có 1 instance riêng → Không cần multi-tenancy
   - Chỉ quản lý users trong 1 organization (VD: VinFast)
   - Đơn giản hóa được rất nhiều so với SaaS

2. **Enterprise SSO Integration:**
   - Khách hàng enterprise đã có Google Workspace/Azure AD/Okta
   - SMAP integrate với SSO của họ, không tự quản lý users
   - Giảm compliance burden (GDPR, password security)

3. **Role-Based Access Control (RBAC):**
   - **ADMIN:** IT team - quản lý config, users, alerts
   - **ANALYST:** Marketing team - tạo projects, chạy analysis
   - **VIEWER:** Executives - chỉ xem dashboard (read-only)

4. **Audit Trail cho Compliance:**
   - Track mọi hành động: ai tạo project, ai xóa data, ai export
   - Retention 90 ngày (configurable)
   - Async publishing qua Kafka → không block business logic

5. **Domain-Based Access Control:**
   - Chỉ cho phép email thuộc domain của khách hàng
   - VD: Chỉ `@vinfast.com` và `@agency-partner.com`
   - Tự động block external emails

**Service Specification:**

````yaml
name: auth-service
current_name: identity # Will be renamed
language: Go
version: v2.0.0 (Simplified)

responsibility:
  - Multi-provider OAuth2/OIDC (Google, Azure AD, Okta)
  - Domain-based access control
  - Config-based role mapping (email → role)
  - JWT issuing & validation (HS256 symmetric)
  - Session management (Redis-backed)
  - Token blacklist (instant revocation)
  - User entity management (for audit log)
  - Dual authentication mode (Cookie + Header)

bỏ_hoàn_toàn:
  - User registration form (dùng SSO)
  - Password management
  - Email verification/OTP
  - Subscription plans

modules:
  - /oauth # OAuth2 callback handlers
  - /session # Session CRUD operations
  - /users # User management (internal)
  - /audit # Audit log consumer

api_endpoints:
  # Public endpoints
  - GET /auth/login/:provider # Redirect to OAuth provider
  - GET /auth/callback/:provider # OAuth callback handler
  - POST /auth/logout # Logout & invalidate session
  - GET /auth/me # Get current user info
  - POST /auth/refresh # Refresh session (remember me)

  # Internal endpoints (service-to-service)
  - POST /internal/validate # Token validation
  - GET /internal/users/:id # User lookup

database: PostgreSQL (schema_identity.* → schema_identity.*)
cache: Redis DB 0 - Sessions, blacklist
message_queue: Kafka - Audit events publishing

config_file: config.yaml


**JWT Configuration (Current Implementation - HS256):**

> **DESIGN DECISION:** Giữ nguyên HS256 thay vì migrate sang RS256

**Rationale:**
- ✅ **Simpler:** Không cần quản lý key pairs, JWKS endpoint
- ✅ **Faster:** HS256 nhanh hơn RS256 (symmetric vs asymmetric)
- ✅ **Sufficient:** On-premise single-tenant không cần public key distribution
- ✅ **Working:** Đã test kỹ, stable trong production
- ✅ **Pragmatic:** Graduation project ưu tiên working code hơn theoretical best practices

**Trade-offs:**
- ❌ Shared secret across services (less secure than private key isolation)
- ❌ Harder key rotation (need restart all services)
- ✅ Document as "future enhancement" trong thesis

```yaml
jwt:
  # Algorithm: HS256 (Symmetric) - Simple & Fast
  algorithm: HS256
  secret_key: ${JWT_SECRET_KEY} # Minimum 32 characters

  # Token TTL
  ttl: 28800 # 8 hours (balance security vs UX)

  # Claims Structure
  claims:
    issuer: "smap-auth-service"
    audience: ["smap-api", "smap-ui"]
    custom:
      - user_id        # UUID
      - email          # string
      - role           # ADMIN | ANALYST | VIEWER
      - jti            # JWT ID (unique per token, for blacklist)
````

**Token Validation Strategy:**

Services validate JWT bằng shared secret:

1. **Auth Service** ký JWT bằng secret key
2. **Các services khác** validate JWT bằng cùng secret key
3. **Shared secret** được mount vào tất cả services qua K8s Secret
4. **Fallback**: Service có thể gọi `/internal/validate` nếu cần

**Lợi ích:**

- Simple implementation (1 secret key)
- Fast validation (symmetric crypto)
- No external dependencies
- Sufficient cho on-premise deployment

**Role Mapping (Current Implementation - Config-based):**

> **DESIGN DECISION:** Giữ nguyên config-based role mapping thay vì Google Groups API

**Rationale:**

- ✅ **Simple:** Direct email-to-role mapping, no external API calls
- ✅ **Fast:** No latency from Directory API
- ✅ **Reliable:** No dependency on Google API availability
- ✅ **Flexible:** Support multiple providers (Google, Azure, Okta) uniformly
- ✅ **Working:** Đã test kỹ, đáp ứng đủ requirements

**Trade-offs:**

- ❌ Manual updates (need config change + restart)
- ❌ Not real-time (5-10 min delay for role changes)
- ✅ Add Provider Abstraction để dễ extend sau này

```yaml
access_control:
  # Domain restriction
  allowed_domains:
    - vinfast.com
    - agency-partner.com

  # Role mapping - email → role
  user_roles:
    # ADMIN users
    cmo@vinfast.com: ADMIN
    it-admin@vinfast.com: ADMIN

    # ANALYST users
    analyst@vinfast.com: ANALYST
    marketing@agency-partner.com: ANALYST

    # VIEWER users (explicit)
    executive@vinfast.com: VIEWER

  # Default role for allowed domains
  default_role: VIEWER

  # Block list (revoked users)
  blocked_users:
    - ex-employee@vinfast.com
```

**Implementation Flow:**

1. User login via OAuth → Get email from provider
2. Check `allowed_domains` → Reject if not allowed
3. Check `blocked_users` → Reject if blocked
4. Lookup `user_roles[email]` → Get role
5. If not found → Use `default_role`
6. Create/update user record in DB
7. Issue JWT with role claim

**Dual Authentication Mode (Current Feature):**

Identity Service v2.0.0 hỗ trợ 2 authentication modes:

**1. Cookie-based (Browser/Web UI):**

```yaml
cookie:
  name: smap_session
  http_only: true
  secure: true # HTTPS only
  same_site: lax
  domain: .smap.local # Share across subdomains
  path: /
  max_age: 28800 # 8 hours
```

**Flow:**

- User login → Set HttpOnly cookie
- Browser tự động gửi cookie với mọi request
- Middleware extract session ID từ cookie
- Lookup session trong Redis → Get user info

**2. Header-based (API/Mobile):**

```
Authorization: Bearer <jwt_token>
```

**Flow:**

- User login → Return JWT token
- Client gửi token trong Authorization header
- Middleware validate JWT → Extract claims

**Middleware Priority:**

```go
func (m *AuthMiddleware) Authenticate(r *http.Request) (*User, error) {
    // 1. Try Authorization header first (API clients)
    if token := r.Header.Get("Authorization"); token != "" {
        return m.validateJWT(token)
    }

    // 2. Fallback to cookie (Browser)
    if cookie, err := r.Cookie("smap_session"); err == nil {
        return m.validateSession(cookie.Value)
    }

    return nil, ErrUnauthorized
}
```

**Lợi ích:**

- Browser: Automatic cookie handling, XSS protection
- API/Mobile: Stateless JWT, easy integration
- Flexibility: Support both web và mobile clients

**Token Blacklist (Current Implementation):**

```yaml
blacklist:
  enabled: true
  backend: redis
  db: 0
  key_pattern: "blacklist:{jti}"
```

**Current Implementation:**

```go
// Revoke specific token
func (s *AuthService) RevokeToken(jti string, remainingTTL time.Duration) error {
    return s.redis.Set(ctx,
        fmt.Sprintf("blacklist:%s", jti),
        "1",
        remainingTTL, // TTL = remaining token lifetime
    ).Err()
}

// Check if token is blacklisted
func (m *AuthMiddleware) isBlacklisted(jti string) bool {
    exists, _ := m.redis.Exists(ctx, fmt.Sprintf("blacklist:%s", jti)).Result()
    return exists > 0
}
```

**🔴 GAP: User-level Blacklist (Need to Add):**

Hiện tại chỉ revoke được từng token riêng lẻ. Cần thêm khả năng revoke ALL tokens của 1 user.

**Enhancement:**

```go
// NEW: Revoke all user tokens
func (s *AuthService) RevokeUserAccess(userID string) error {
    // Block all current tokens của user này
    // TTL = max token lifetime (8 hours)
    return s.redis.Set(ctx,
        fmt.Sprintf("blacklist:user:%s", userID),
        "1",
        8 * time.Hour,
    ).Err()
}

// Enhanced middleware check
func (m *AuthMiddleware) isBlacklisted(userID, jti string) bool {
    // Check user-level blacklist first
    userBlocked, _ := m.redis.Exists(ctx,
        fmt.Sprintf("blacklist:user:%s", userID)).Result()
    if userBlocked > 0 {
        return true
    }

    // Check token-level blacklist
    tokenBlocked, _ := m.redis.Exists(ctx,
        fmt.Sprintf("blacklist:%s", jti)).Result()
    return tokenBlocked > 0
}
```

**Use Cases:**

- User báo mất laptop → Admin revoke ALL tokens của user đó
- Employee bị sa thải → Admin block account ngay lập tức
- Security incident → Revoke access tức thì

**Effort:** 1 hour

**Session Management (Current Implementation):**

```yaml
session:
  backend: redis
  db: 0
  ttl: 28800 # 8 hours
  key_pattern: "session:{session_id}"

  # Remember me feature
  remember_me:
    enabled: true
    ttl: 604800 # 7 days
```

**Session Structure:**

```go
type Session struct {
    ID        string    `json:"id"`
    UserID    string    `json:"user_id"`
    Email     string    `json:"email"`
    Role      string    `json:"role"`
    CreatedAt time.Time `json:"created_at"`
    ExpiresAt time.Time `json:"expires_at"`
    IPAddress string    `json:"ip_address"`
    UserAgent string    `json:"user_agent"`
}
```

**Operations:**

- **Create:** Login → Generate session ID → Store in Redis
- **Read:** Middleware → Get session from Redis → Inject user into context
- **Update:** Refresh → Extend TTL
- **Delete:** Logout → Delete from Redis

**Auto Cleanup:**

- Redis TTL tự động xóa expired sessions
- Không cần background job

**Lợi ích:**

- Fast (Redis in-memory)
- Scalable (stateless services, state in Redis)
- Reliable (Redis persistence)
- Simple (no database queries)

**Audit Log (Current Implementation - Kafka Async):**

```yaml
audit:
  enabled: true
  kafka:
    topic: audit.events
    brokers:
      - kafka:9092
  retention_days: 90
```

**Async Publishing Pattern:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUDIT LOG FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Request                                                   │
│       ↓                                                         │
│  ┌─────────────────┐                                            │
│  │ Any Service     │                                            │
│  │ (Business Logic)│                                            │
│  └────────┬────────┘                                            │
│           │                                                     │
│           ├─► 1. Execute business logic                        │
│           │                                                     │
│           ├─► 2. Push audit event to Kafka                     │
│           │    Topic: audit.events                             │
│           │    → NON-BLOCKING (fire-and-forget)                │
│           │                                                     │
│           └─► 3. Return response to user                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Kafka Topic: audit.events                  │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Auth Service - Audit Consumer                 │    │
│  │  • Consume audit events from Kafka                      │    │
│  │  • Batch insert to schema_identity.audit_logs (every 5s/100 msgs)  │    │
│  │  • Retry on failure                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Event Schema:**

```json
{
  "user_id": "uuid",
  "action": "CREATE_PROJECT",
  "resource_type": "project",
  "resource_id": "uuid",
  "metadata": {
    "project_name": "Monitor VF8",
    "brand": "VinFast"
  },
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "timestamp": "2026-02-15T10:30:00Z"
}
```

**Database Schema:**

```sql
CREATE SCHEMA auth; -- Renamed from schema_identity

CREATE TABLE schema_identity.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days')
);

CREATE INDEX idx_audit_logs_user ON schema_identity.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON schema_identity.audit_logs(action);
CREATE INDEX idx_audit_logs_created ON schema_identity.audit_logs(created_at);
CREATE INDEX idx_audit_logs_expires ON schema_identity.audit_logs(expires_at);
```

**Cleanup Job:**

```bash
# K8s CronJob - runs daily at 2 AM
0 2 * * * psql -c "DELETE FROM schema_identity.audit_logs WHERE expires_at < NOW()"
```

**Lợi ích:**

- Non-blocking (không làm chậm business logic)
- Reliable (Kafka guarantees delivery)
- Scalable (Kafka handles high throughput)
- Decoupled (services không phụ thuộc Auth Service)

**Multi-Provider Support (Current Implementation):**

Identity Service v2.0.0 đã hỗ trợ 3 providers:

```yaml
oauth:
  providers:
    google:
      enabled: true
      client_id: ${GOOGLE_CLIENT_ID}
      client_secret: ${GOOGLE_CLIENT_SECRET}
      redirect_uri: ${APP_URL}/auth/callback/google
      scopes:
        - openid
        - email
        - profile

    azure:
      enabled: false
      tenant_id: ${AZURE_TENANT_ID}
      client_id: ${AZURE_CLIENT_ID}
      client_secret: ${AZURE_CLIENT_SECRET}
      redirect_uri: ${APP_URL}/auth/callback/azure

    okta:
      enabled: false
      domain: ${OKTA_DOMAIN}
      client_id: ${OKTA_CLIENT_ID}
      client_secret: ${OKTA_CLIENT_SECRET}
      redirect_uri: ${APP_URL}/auth/callback/okta
```

**🔴 GAP: Provider Abstraction (Need Refactoring):**

Hiện tại code hardcode logic cho từng provider. Cần refactor theo Interface pattern.

**Target Architecture:**

```go
// pkg/auth/provider/interface.go
type IdentityProvider interface {
    GetAuthURL(state string) string
    ExchangeCode(code string) (*TokenResponse, error)
    GetUserInfo(accessToken string) (*UserInfo, error)
    ValidateToken(accessToken string) error
}

type UserInfo struct {
    Email     string
    Name      string
    AvatarURL string
}

// Implementations
type GoogleProvider struct {...}
type AzureADProvider struct {...}
type OktaProvider struct {...}
```

**Benefits:**

- Easy to add new providers (LDAP, SAML, custom SSO)
- Easy to test (mock interface)
- Clean code (no if/else chains)
- Extensible (plugin pattern)

**Effort:** 1 day

**Database Schema (Current → Target):**

**Current:**

```sql
CREATE SCHEMA schema_identity;

CREATE TABLE schema_identity.users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'VIEWER',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE schema_identity.audit_logs (...);
```

**Target:**

```sql
-- Rename schema
ALTER SCHEMA schema_identity RENAME TO auth;

-- Tables remain the same, just different schema
CREATE TABLE schema_identity.users (...);
CREATE TABLE schema_identity.audit_logs (...);
```

**Migration Steps:**

1. Run SQL: `ALTER SCHEMA schema_identity RENAME TO auth;`
2. Update config: `postgres.schema: auth`
3. Regenerate SQLBoiler models: `make models`
4. Test all database operations
5. Update documentation

**Effort:** 2-3 hours  
**Risk:** 🟡 MEDIUM (need downtime for schema rename)

**JWT Middleware for Other Services:**

Mỗi service (Project, Ingest, Analytics, Knowledge, Notification) cần implement JWT verification middleware:

```go
// Shared middleware package: pkg/auth/middleware.go
package auth

import (
    "context"
    "fmt"
    "net/http"
    "strings"

    "github.com/golang-jwt/jwt/v5"
    "github.com/redis/go-redis/v9"
)

type JWTMiddleware struct {
    secretKey []byte
    redis     *redis.Client
}

func NewJWTMiddleware(secretKey string, redisClient *redis.Client) *JWTMiddleware {
    return &JWTMiddleware{
        secretKey: []byte(secretKey),
        redis:     redisClient,
    }
}

func (m *JWTMiddleware) Authenticate(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // 1. Extract token from Authorization header
        authHeader := r.Header.Get("Authorization")
        if authHeader == "" {
            http.Error(w, "Missing authorization header", http.StatusUnauthorized)
            return
        }

        tokenString := strings.TrimPrefix(authHeader, "Bearer ")

        // 2. Parse & validate JWT using shared secret
        token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
            // Verify signing method
            if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
                return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
            }
            return m.secretKey, nil
        })

        if err != nil || !token.Valid {
            http.Error(w, "Invalid token", http.StatusUnauthorized)
            return
        }

        // 3. Extract claims
        claims, ok := token.Claims.(jwt.MapClaims)
        if !ok {
            http.Error(w, "Invalid token claims", http.StatusUnauthorized)
            return
        }

        // 4. Verify issuer
        if claims["iss"] != "smap-auth-service" {
            http.Error(w, "Invalid token issuer", http.StatusUnauthorized)
            return
        }

        // 5. Check Redis blacklist
        userID := claims["user_id"].(string)
        jti, _ := claims["jti"].(string)

        // Check user-level blacklist
        isUserBlacklisted, _ := m.redis.Exists(r.Context(),
            fmt.Sprintf("blacklist:user:%s", userID)).Result()
        if isUserBlacklisted > 0 {
            http.Error(w, "Token revoked", http.StatusUnauthorized)
            return
        }

        // Check token-level blacklist
        if jti != "" {
            isTokenBlacklisted, _ := m.redis.Exists(r.Context(),
                fmt.Sprintf("blacklist:%s", jti)).Result()
            if isTokenBlacklisted > 0 {
                http.Error(w, "Token revoked", http.StatusUnauthorized)
                return
            }
        }

        // 6. Inject user info into context
        ctx := context.WithValue(r.Context(), "user_id", userID)
        ctx = context.WithValue(ctx, "email", claims["email"].(string))
        ctx = context.WithValue(ctx, "role", claims["role"].(string))

        // 7. Pass to next handler
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

// Authorization helper - check role
func RequireRole(role string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            userRole := r.Context().Value("role").(string)

            // Role hierarchy: ADMIN > ANALYST > VIEWER
            if !hasPermission(userRole, role) {
                http.Error(w, "Insufficient permissions", http.StatusForbidden)
                return
            }

            next.ServeHTTP(w, r)
        })
    }
}

func hasPermission(userRole, requiredRole string) bool {
    roleHierarchy := map[string]int{
        "ADMIN":   3,
        "ANALYST": 2,
        "VIEWER":  1,
    }
    return roleHierarchy[userRole] >= roleHierarchy[requiredRole]
}
```

**Usage trong Project Service:**

```go
func main() {
    // Initialize JWT middleware
    authMiddleware := auth.NewJWTMiddleware(
        os.Getenv("JWT_SECRET_KEY"),
        redisClient,
    )

    // Setup routes
    r := chi.NewRouter()

    // Public routes
    r.Get("/health", healthHandler)

    // Protected routes
    r.Group(func(r chi.Router) {
        r.Use(authMiddleware.Authenticate)

        // All users can view
        r.Get("/projects", listProjectsHandler)

        // Only ANALYST+ can create
        r.With(auth.RequireRole("ANALYST")).Post("/projects", createProjectHandler)

        // Only ADMIN can delete
        r.With(auth.RequireRole("ADMIN")).Delete("/projects/{id}", deleteProjectHandler)
    })

    http.ListenAndServe(":8080", r)
}
```

**Migration Tasks (Tuần 1):**

| Task                      | Description                                     | Effort | Priority  |
| ------------------------- | ----------------------------------------------- | ------ | --------- |
| 1. Database Schema Rename | `ALTER SCHEMA schema_identity RENAME TO auth`   | 2-3h   | 🔴 HIGH   |
| 2. Folder Rename          | `services/identity/` → `services/auth-service/` | 2h     | 🔴 HIGH   |
| 3. Provider Abstraction   | Refactor OAuth logic → Interface pattern        | 1d     | 🔴 HIGH   |
| 4. User-level Blacklist   | Add `blacklist:user:{user_id}` support          | 1h     | 🔴 HIGH   |
| 5. Update Config          | Rename config keys, update docs                 | 1h     | 🟡 MEDIUM |
| 6. Regenerate Models      | SQLBoiler models for new schema                 | 30m    | 🟡 MEDIUM |
| 7. Update Tests           | Fix broken tests after refactoring              | 2h     | 🟡 MEDIUM |
| 8. Update Documentation   | README, API docs, architecture diagrams         | 2h     | 🟡 MEDIUM |

**Total Effort:** 2-3 days

**Risk Assessment:**

- 🟡 MEDIUM: Database schema rename needs downtime
- 🟢 LOW: Other tasks are non-breaking refactors

**Future Enhancements (Phase 2-3):**

**Phase 2 (Tuần 2-4):**

1. **Refresh Token Support:**
   - Add refresh token generation
   - Add `/auth/refresh` endpoint
   - Shorter access token TTL (15m) + longer refresh token (7d)
   - Better security vs UX balance
   - **Effort:** 4-6 hours

2. **Enhanced Audit Log:**
   - Add more event types
   - Add filtering & search API
   - Add export functionality
   - **Effort:** 1 day

**Phase 3 (Tuần 12):** 3. **Key Rotation (Optional):**

- Flexible key loading (file, env, K8s secret)
- Automatic rotation mechanism
- Zero-downtime rotation
- **Effort:** 1-2 days
- **Note:** Only if migrate to RS256

1. **Google Groups Integration (Optional):**
   - Dynamic role mapping from Google Groups
   - Background sync job
   - Cache in Redis
   - **Effort:** 1-2 days
   - **Note:** Only if customer requests

2. **RS256 Migration (Optional):**
   - Generate RSA key pairs
   - Implement JWKS endpoint
   - Update all service middlewares
   - **Effort:** 2-3 days
   - **Note:** Only if security requirements demand it

**Roles & Permissions:**

| Role        | Permissions                                                                                                                                                                     | Use Cases                                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| **ADMIN**   | • Full access to all features<br>• Manage users & roles<br>• Configure system settings<br>• View all projects & data<br>• Manage alerts & notifications<br>• Export audit logs  | IT team, System administrators              |
| **ANALYST** | • Create & manage projects<br>• Upload data sources<br>• Run analysis<br>• View insights & reports<br>• Export data<br>• Use RAG chatbot<br>• Configure alerts for own projects | Marketing team, Data analysts               |
| **VIEWER**  | • View dashboards (read-only)<br>• View reports<br>• View insights<br>• Cannot create/edit/delete                                                                               | Executives, Stakeholders, External partners |

**Permission Matrix:**

| Action           | ADMIN | ANALYST  | VIEWER |
| ---------------- | ----- | -------- | ------ |
| View Dashboard   | ✅    | ✅       | ✅     |
| Create Project   | ✅    | ✅       | ❌     |
| Edit Project     | ✅    | ✅ (own) | ❌     |
| Delete Project   | ✅    | ✅ (own) | ❌     |
| Upload Data      | ✅    | ✅       | ❌     |
| Run Analysis     | ✅    | ✅       | ❌     |
| Export Data      | ✅    | ✅       | ❌     |
| Manage Users     | ✅    | ❌       | ❌     |
| Configure System | ✅    | ❌       | ❌     |
| View Audit Logs  | ✅    | ❌       | ❌     |

**Summary - What Changed from Original Plan:**

| Aspect                   | Original Plan (v2.10)   | Adapted Plan (v2.11)                        | Rationale                                  |
| ------------------------ | ----------------------- | ------------------------------------------- | ------------------------------------------ |
| **JWT Algorithm**        | RS256 (asymmetric)      | ✅ HS256 (symmetric)                        | Simpler, faster, sufficient for on-premise |
| **Role Mapping**         | Google Groups API       | ✅ Config-based                             | No external dependency, simpler, working   |
| **Token TTL**            | 15m access + 7d refresh | ✅ 8h single token                          | Better UX, sufficient security             |
| **Database Schema**      | `schema_identity.*`                | ✅ `schema_identity.*` (rename from `schema_identity`) | Align with plan                            |
| **Folder Name**          | `auth-service`          | ✅ `auth-service` (rename from `identity`)  | Align with plan                            |
| **Provider Abstraction** | Not mentioned           | ✅ Add Interface pattern                    | Improve code quality                       |
| **User-level Blacklist** | Token-level only        | ✅ Add user-level                           | Security enhancement                       |
| **Dual Auth Mode**       | Not mentioned           | ✅ Keep (Cookie + Header)                   | Already working, good feature              |
| **Audit Log**            | Kafka async             | ✅ Kafka async                              | Already working perfectly                  |
| **Session Management**   | Redis                   | ✅ Redis                                    | Already working perfectly                  |

**Key Decisions:**

1. ✅ **Keep HS256:** Pragmatic choice for graduation project
2. ✅ **Keep Config-based Roles:** Simple, reliable, no external dependencies
3. ✅ **Keep 8h Token TTL:** Balance security vs UX
4. ✅ **Add Provider Abstraction:** Improve code quality & extensibility
5. ✅ **Add User-level Blacklist:** Important security enhancement
6. ✅ **Keep Dual Auth Mode:** Good feature, already working
7. ✅ **Rename Schema & Folder:** Align with migration plan naming

**Migration Philosophy:**

> "Refactor structure, not rewrite. Leverage what's working, enhance what's missing."

Identity Service v2.0.0 đã rất solid. Chúng ta chỉ cần:

- Rename để align với plan
- Refactor để improve code quality
- Add missing features (user-level blacklist, provider abstraction)
- Document design decisions trong thesis

**Estimated Timeline:**

- Week 1: Core refactoring (schema rename, folder rename, provider abstraction)
- Week 2-4: Enhancements (refresh token, enhanced audit log)
- Week 12: Optional features (key rotation, Google Groups, RS256)

### 3.2 Project Service - Orchestration Brain (UPDATED v2.12)

> **CRITICAL UPDATE (v2.12):** Làm rõ vai trò Project Service là "Bộ não điều phối" (Orchestration Brain) của hệ thống, phân biệt rõ ràng với Ingest Service (Executor).

**Vai trò tổng quan:**

Project Service là **Decision Maker** - quyết định WHAT, WHEN, WHY. Ingest Service là **Task Executor** - thực thi HOW.

```
┌─────────────────────────────────────────────────────────────────┐
│           PROJECT SERVICE - ORCHESTRATION BRAIN                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. LIFECYCLE MANAGEMENT (Quản lý vòng đời)                     │
│     ✓ Quản lý state machine của Project (xem Section 3.2.5)     │
│     ✓ Validate state transitions                                │
│     ✓ Enforce business rules                                    │
│     ✓ Audit trail cho mọi state change                          │
│                                                                 │
│  2. DATA INGESTION ORCHESTRATION (Điều phối thu thập dữ liệu)   │
│     ✓ Quyết định WHEN to ingest (schedule, on-demand, reactive) │
│     ✓ Quyết định HOW to ingest (profile, strategy)              │
│     ✓ Quyết định WHAT to ingest (sources, filters, limits)      │
│     ✓ Publish commands → Ingest Service (executor)              │
│                                                                 │
│  3. ADAPTIVE CRAWL CONTROLLER (Điều khiển thu thập thích ứng)   │
│     ✓ Consume metrics từ Analytics Service                      │
│     ✓ Calculate baseline (7-day averages)                       │
│     ✓ Determine crawl mode (Sleep/Normal/Crisis)                │
│     ✓ Publish mode change events → Ingest Service               │
│                                                                 │
│  4. INTEGRATION HUB (Trung tâm tích hợp)                        │
│     ✓ Coordinate Ingest, Analytics, Knowledge, Notification     │
│     ✓ Aggregate dashboard data từ Analytics                     │
│     ✓ Trigger crisis alerts qua Notification                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Service Specification:**

```yaml
name: project-service
language: Go
version: v2.12 (Orchestration Brain)

responsibility:
  # Core Entities
  - Project CRUD (Entity Monitoring Unit - Tầng 2)
  - Campaign CRUD (Logical Analysis Unit - Tầng 3)
  - Data Source metadata management (config, schedule)

  # Orchestration
  - Lifecycle state machine management
  - Data ingestion orchestration (schedule, trigger)
  - Adaptive crawl decision making

  # Integration
  - Dashboard data aggregation (from Analytics)
  - Crisis detection coordination
  - Event publishing (Kafka producer)

modules:
  - /projects # Project CRUD + State Machine
  - /campaigns # Campaign CRUD
  - /sources # Data Source metadata (NOT execution)
  - /scheduler # Crawl scheduler + Adaptive controller
  - /dashboard # Dashboard aggregation
  - /orchestrator # Command publisher (to Ingest)
  - /health # Health check metrics

entities:
  Project:
    - id: UUID
    - name: string (e.g., "Monitor VF8")
    - brand: string (e.g., "VinFast")
    - entity_type: string (product, campaign, service, competitor, topic)
    - entity_name: string (e.g., "VF8")
    - description: text
    - industry: string
    - status: string # DRAFT, ACTIVE, PAUSED, ARCHIVED, ERROR
    - config_status: string # CONFIGURING, ONBOARDING, DRYRUN_RUNNING, etc.
    - created_by: UUID
    - activated_at: timestamp
    - created_at: timestamp
    - updated_at: timestamp

  Campaign:
    - id: UUID
    - name: string (e.g., "So sánh Xe điện")
    - description: text
    - project_ids: UUID[]
    - created_by: UUID
    - created_at: timestamp
    - updated_at: timestamp

  DataSource (metadata only):
    - id: UUID
    - project_id: UUID
    - name: string
    - source_type: string (FILE_UPLOAD, WEBHOOK, FACEBOOK, TIKTOK, YOUTUBE)
    - source_category: string (crawl, passive)
    - config: JSONB
    - crawl_mode: string (SLEEP, NORMAL, CRISIS)
    - crawl_interval_minutes: int
    - next_crawl_at: timestamp
    - last_crawl_metrics: JSONB
    - baseline_metrics: JSONB
    - status: string (PENDING, ACTIVE, PAUSED, FAILED)

database: PostgreSQL (schema_project.* schema)

kafka_topics_produced:
  # Lifecycle events
  - project.created
  - project.activated
  - project.paused
  - project.resumed
  - project.archived

  # Orchestration commands
  - ingest.crawl.requested # Command to Ingest: execute crawl
  - ingest.file.process # Command to Ingest: process uploaded file
  - ingest.webhook.activate # Command to Ingest: activate webhook

  # Adaptive crawl events
  - project.crisis.started # Crisis mode activated
  - project.crisis.resolved # Crisis mode resolved
  - project.mode.changed # Crawl mode changed

kafka_topics_consumed:
  # Feedback from Analytics for adaptive crawl
  - analytics.metrics.aggregated

  # Status updates from Ingest
  - ingest.crawl.completed
  - ingest.file.completed
  - ingest.dryrun.completed
```

**Database Schema (business.\*):**

```sql
-- Projects table (Entity Monitoring Unit - Tầng 2)
CREATE TABLE schema_project.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    entity_type VARCHAR(50),
    entity_name VARCHAR(200),
    description TEXT,
    industry VARCHAR(100),

    -- Status fields
    status VARCHAR(20) DEFAULT 'DRAFT',           -- DRAFT, ACTIVE, PAUSED, ARCHIVED, ERROR
    config_status VARCHAR(20) DEFAULT 'DRAFT',    -- CONFIGURING, ONBOARDING, DRYRUN_RUNNING, etc.

    -- Metadata
    created_by UUID NOT NULL,
    activated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Campaigns table (Logical Analysis Unit - Tầng 3)
CREATE TABLE schema_project.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Campaign-Project relationship (many-to-many)
CREATE TABLE schema_project.campaign_projects (
    campaign_id UUID REFERENCES schema_project.campaigns(id) ON DELETE CASCADE,
    project_id UUID REFERENCES schema_project.projects(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (campaign_id, project_id)
);

-- State transition audit trail (NEW)
CREATE TABLE business.project_state_transitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES schema_project.projects(id),

    from_state VARCHAR(50) NOT NULL,
    to_state VARCHAR(50) NOT NULL,

    trigger_type VARCHAR(20) NOT NULL,  -- 'USER' | 'SYSTEM'
    triggered_by UUID,                  -- user_id (if USER trigger)

    validation_passed BOOLEAN,
    validation_errors JSONB,
    actions_taken JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_projects_created_by ON schema_project.projects(created_by);
CREATE INDEX idx_projects_status ON schema_project.projects(status);
CREATE INDEX idx_campaigns_created_by ON schema_project.campaigns(created_by);
CREATE INDEX idx_campaign_projects_campaign ON schema_project.campaign_projects(campaign_id);
CREATE INDEX idx_campaign_projects_project ON schema_project.campaign_projects(project_id);
CREATE INDEX idx_project_transitions_project ON business.project_state_transitions(project_id, created_at DESC);
```

#### 3.2.1 Phân biệt Project Service vs Ingest Service

**Nguyên tắc phân chia trách nhiệm:**

| Aspect             | Project Service (Brain)               | Ingest Service (Executor)          |
| ------------------ | ------------------------------------- | ---------------------------------- |
| **Role**           | Decision Maker                        | Task Executor                      |
| **Responsibility** | WHAT, WHEN, WHY                       | HOW                                |
| **Data Sources**   | Manage metadata (config, schedule)    | Execute actual ingestion           |
| **File Upload**    | Trigger upload flow, validate         | Parse file, transform to UAP       |
| **Crawl**          | Schedule crawl jobs, decide frequency | Call external API, fetch data      |
| **Webhook**        | Generate webhook URL, manage config   | Receive webhook, validate payload  |
| **AI Schema**      | Coordinate onboarding flow            | Execute LLM calls, suggest mapping |
| **Dry Run**        | Trigger dry run, collect results      | Execute test crawl, return samples |
| **Adaptive**       | Consume metrics, decide mode          | Execute crawl with new frequency   |
| **State**          | Manage project state machine          | Report job status back             |
| **Database**       | business.\* (metadata)                | ingest.\* (execution logs)         |

**Ví dụ cụ thể:**

**Scenario 1: File Upload**

```
User uploads Excel file
    ↓
[Project Service]
    - Validate project is ACTIVE
    - Generate upload URL (MinIO presigned)
    - Create data_source record (status: PENDING)
    - Publish: ingest.file.process {source_id, file_url, mapping_rules}
    ↓
[Ingest Service]
    - Consume: ingest.file.process
    - Download file from MinIO
    - Parse Excel → rows
    - Apply mapping_rules (from AI Schema Mapping)
    - Transform rows → UAP
    - Publish: smap.collector.output (UAP batch)
    - Publish: ingest.file.completed {source_id, items_count, status}
    ↓
[Project Service]
    - Consume: ingest.file.completed
    - Update data_source (status: COMPLETED, record_count)
```

**Scenario 2: Scheduled Crawl**

```
Cron job triggers (every 15 minutes)
    ↓
[Project Service - Scheduler]
    - Query: SELECT * FROM schema_ingest.data_sources
             WHERE next_crawl_at <= NOW() AND status = 'ACTIVE'
    - For each source:
        - Determine crawl profile (Incremental Monitor)
        - Build crawl config (keywords, date_range, limit)
        - Publish: ingest.crawl.requested {source_id, profile, config}
    ↓
[Ingest Service - Worker]
    - Consume: ingest.crawl.requested
    - Call external crawl API (teammate's server)
        POST /api/crawl {keywords, platforms, date_range}
    - Receive raw data (JSON/JSONL)
    - Transform → UAP
    - Publish: smap.collector.output (UAP batch)
    - Publish: ingest.crawl.completed {source_id, items_count, status}
    ↓
[Project Service - Metrics Consumer]
    - Consume: ingest.crawl.completed
    - Update schema_ingest.data_sources:
        - last_crawl_at = NOW()
        - last_crawl_metrics = {items_count, ...}
        - next_crawl_at = NOW() + crawl_interval
```

**Scenario 3: Adaptive Crawl (Crisis Mode)**

```
[Analytics Service]
    - Analyze batch of UAP
    - Detect: negative_ratio = 45% > 30% threshold
    - Aggregate metrics per source
    - Publish: analytics.metrics.aggregated {source_id, metrics}
    ↓
[Project Service - Adaptive Scheduler]
    - Consume: analytics.metrics.aggregated
    - Load baseline: avg_negative_ratio = 12%
    - Compare: 45% >> 12% → CRISIS MODE
    - Update schema_ingest.data_sources:
        - crawl_mode: NORMAL → CRISIS
        - crawl_interval: 15min → 2min
        - next_crawl_at: NOW() + 2min
        - mode_change_reason: "Negative ratio 45% > 30%"
    - Publish: project.crisis.started {project_id, source_id, metrics}
    ↓
[Ingest Service]
    - Consume: project.crisis.started
    - Cancel scheduled job (15min)
    - Schedule new job (2min)
    - Trigger crawl IMMEDIATELY (không đợi 2min)
    ↓
[Notification Service]
    - Consume: project.crisis.started
    - Send Slack alert: "🚨 VF8 TikTok: 45% negative!"
    - Send WebSocket to Dashboard: real-time badge update
```

#### 3.2.2 Kafka Topics Architecture

**Topics do Project Service produce:**

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

# Orchestration Commands (to Ingest Service)
ingest.crawl.requested:
  payload: {source_id, profile, config: {keywords, date_range, limit}}
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

**Topics do Project Service consume:**

```yaml
# Feedback from Analytics (for adaptive crawl)
analytics.metrics.aggregated:
  payload: {source_id, new_items_count, negative_ratio, velocity, timestamp}
  purpose: Adaptive crawl decision making

# Status updates from Ingest
ingest.crawl.completed:
  payload: {source_id, items_count, status, error_message}
  purpose: Update crawl schedule

ingest.file.completed:
  payload: {source_id, items_count, status, error_message}
  purpose: Update data source status

ingest.dryrun.completed:
  payload: {source_id, status, sample_data[], error_message}
  purpose: Update project config_status
```

#### 3.2.3 Adaptive Crawl Implementation

**Database Schema bổ sung (schema_ingest.data_sources):**

```sql
-- Managed by Project Service, executed by Ingest Service
CREATE TABLE schema_ingest.data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(20) NOT NULL,
    source_category VARCHAR(10) NOT NULL DEFAULT 'passive',

    -- Config
    config JSONB,

    -- Adaptive Crawl fields
    crawl_mode VARCHAR(20) DEFAULT 'NORMAL',        -- SLEEP | NORMAL | CRISIS
    crawl_interval_minutes INT DEFAULT 15,
    next_crawl_at TIMESTAMPTZ,

    -- Metrics tracking
    last_crawl_at TIMESTAMPTZ,
    last_crawl_metrics JSONB,
    baseline_metrics JSONB,

    -- Mode change tracking
    mode_changed_at TIMESTAMPTZ,
    mode_change_reason TEXT,

    -- Status
    status VARCHAR(20) DEFAULT 'PENDING',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_data_sources_next_crawl
ON schema_ingest.data_sources(next_crawl_at)
WHERE status = 'ACTIVE' AND source_category = 'crawl';
```

**Adaptive Scheduler Logic:**

```go
// internal/scheduler/adaptive.go
package scheduler

type AdaptiveScheduler struct {
    repo          DataSourceRepository
    kafkaProducer KafkaProducer
    logger        Logger
}

func (s *AdaptiveScheduler) ProcessMetrics(ctx context.Context, metrics SourceMetrics) error {
    // 1. Get source with baseline
    source, err := s.repo.GetByID(ctx, metrics.SourceID)
    if err != nil {
        return err
    }

    // 2. Determine new mode
    newMode := s.determineMode(metrics, source.BaselineMetrics)

    // 3. If mode changed, update and publish event
    if newMode != source.CrawlMode {
        interval := s.getIntervalForMode(newMode)
        reason := s.getModeChangeReason(metrics, source.BaselineMetrics, newMode)

        // Update database
        err := s.repo.UpdateCrawlMode(ctx, source.ID, UpdateCrawlModeInput{
            CrawlMode:        newMode,
            CrawlInterval:    interval,
            NextCrawlAt:      time.Now().Add(time.Duration(interval) * time.Minute),
            ModeChangeReason: reason,
        })

        // Publish event
        if newMode == CrawlModeCrisis {
            s.kafkaProducer.Publish(ctx, "project.crisis.started", CrisisEvent{
                ProjectID: source.ProjectID,
                SourceID:  source.ID,
                Metrics:   metrics,
                Reason:    reason,
            })
        }
    }

    return nil
}

func (s *AdaptiveScheduler) determineMode(current SourceMetrics, baseline BaselineMetrics) CrawlMode {
    // Crisis detection
    if current.NegativeRatio > 0.30 {
        return CrawlModeCrisis
    }

    if baseline.AvgVelocity > 0 {
        velocityIncrease := (current.Velocity - baseline.AvgVelocity) / baseline.AvgVelocity
        if velocityIncrease > 2.0 {
            return CrawlModeCrisis
        }
    }

    // Sleep detection
    if current.NewItemsCount < 5 {
        return CrawlModeSleep
    }

    return CrawlModeNormal
}
```

#### 3.2.4 Crawl Scheduler (Cron Job)

```go
// cmd/scheduler/main.go
package main

func main() {
    scheduler := NewCrawlScheduler(repo, kafkaProducer, logger)

    // Run every minute
    ticker := time.NewTicker(1 * time.Minute)
    defer ticker.Stop()

    for range ticker.C {
        ctx := context.Background()

        // Get sources due for crawl
        sources, err := repo.GetDueSources(ctx, time.Now())
        if err != nil {
            logger.Errorf(ctx, "failed to get due sources: %v", err)
            continue
        }

        // Publish crawl commands
        for _, source := range sources {
            profile := s.determineCrawlProfile(source)
            config := s.buildCrawlConfig(source, profile)

            err := kafkaProducer.Publish(ctx, "ingest.crawl.requested", CrawlCommand{
                SourceID: source.ID,
                Profile:  profile,
                Config:   config,
            })

            if err != nil {
                logger.Errorf(ctx, "failed to publish crawl command: %v", err)
            }
        }
    }
}
```

#### 3.2.4.1 Dashboard Orchestration (NEW - v2.13)

**Vai trò:** Project Service là **Dashboard Owner** - điều phối và tổng hợp dữ liệu từ nhiều nguồn để phục vụ Dashboard UI.

**Architecture Pattern:** API Gateway Pattern - Single entry point cho Dashboard, proxy calls tới backend services.

```
┌─────────────────────────────────────────────────────────────────┐
│              DASHBOARD ORCHESTRATION FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [User Browser]                                                 │
│      │                                                          │
│      │ HTTP GET /projects/{id}/dashboard?time_range=7d         │
│      ↓                                                          │
│  [Project Service - Dashboard Module] ← OWNER                   │
│      │                                                          │
│      ├─► Query schema_project.projects (metadata)                     │
│      │   ✅ project_id, name, brand, status, activated_at       │
│      │                                                          │
│      ├─► Query business.data_sources (sources summary)          │
│      │   ✅ total_sources, record_count, crawl_modes            │
│      │   ✅ sources_detail (id, name, type, status, metrics)    │
│      │                                                          │
│      └─► HTTP GET /analytics/projects/{id}/insights             │
│          ↓                                                      │
│      [Analytics Service - Insights API] ← PROVIDER              │
│          │                                                      │
│          ├─► Check Redis cache (5 min TTL)                      │
│          │   Key: insights:proj_{id}:7d                         │
│          │                                                      │
│          └─► Query analytics.post_analytics                     │
│              ✅ Aggregate: sentiment, keywords, trends, aspects  │
│              ✅ Cache result (5 min TTL)                         │
│              ✅ Return JSON                                      │
│          ↓                                                      │
│      [Project Service]                                          │
│          - Combine: metadata + sources + analytics              │
│          - Handle errors (fallback if Analytics down)           │
│          - Return unified response                              │
│      ↓                                                          │
│  [User Browser]                                                 │
│      - Render Dashboard                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**API Endpoint:**

```go
// GET /projects/{id}/dashboard?time_range=7d
func (h *DashboardHandler) GetDashboard(c *gin.Context) {
    projectID := c.Param("id")
    timeRange := c.DefaultQuery("time_range", "7d")
    
    // 1. Get project metadata (local DB)
    project, err := h.projectRepo.GetByID(c.Request.Context(), projectID)
    if err != nil {
        c.JSON(404, gin.H{"error": "project not found"})
        return
    }
    
    // 2. Get data sources summary (local DB)
    sources, err := h.sourceRepo.ListByProject(c.Request.Context(), projectID)
    if err != nil {
        c.JSON(500, gin.H{"error": "failed to get sources"})
        return
    }
    
    sourceSummary := h.aggregateSourceSummary(sources)
    
    // 3. Call Analytics Service for insights (HTTP - REAL-TIME)
    analyticsResp, err := h.analyticsClient.GetProjectInsights(
        c.Request.Context(),
        projectID,
        timeRange,
    )
    
    // Handle Analytics Service unavailable (graceful degradation)
    if err != nil {
        h.logger.Warnf("Analytics service unavailable: %v", err)
        c.JSON(200, gin.H{
            "project":   project,
            "sources":   sourceSummary,
            "analytics": nil,
            "error":     "Analytics service temporarily unavailable",
        })
        return
    }
    
    // 4. Combine response
    c.JSON(200, gin.H{
        "project":   project,
        "sources":   sourceSummary,
        "analytics": analyticsResp,
    })
}

func (h *DashboardHandler) aggregateSourceSummary(sources []DataSource) SourceSummary {
    summary := SourceSummary{
        TotalSources: len(sources),
        SourcesDetail: []SourceDetail{},
    }
    
    for _, src := range sources {
        summary.TotalRecords += src.RecordCount
        
        // Count by type
        switch src.SourceType {
        case "FILE_UPLOAD":
            summary.FileSources++
        case "WEBHOOK":
            summary.WebhookSources++
        default:
            summary.CrawlSources++
        }
        
        // Count by crawl mode
        if src.CrawlMode == "CRISIS" {
            summary.CrisisSources++
        } else if src.CrawlMode == "NORMAL" {
            summary.NormalSources++
        } else if src.CrawlMode == "SLEEP" {
            summary.SleepSources++
        }
        
        // Add detail
        summary.SourcesDetail = append(summary.SourcesDetail, SourceDetail{
            ID:          src.ID,
            Name:        src.Name,
            Type:        src.SourceType,
            Status:      src.Status,
            CrawlMode:   src.CrawlMode,
            RecordCount: src.RecordCount,
        })
    }
    
    return summary
}
```

**Response Structure:**

```json
{
  "project": {
    "id": "proj_vf8",
    "name": "Monitor VF8",
    "brand": "VinFast",
    "entity_type": "product",
    "entity_name": "VF8",
    "status": "ACTIVE",
    "activated_at": "2026-02-15T10:00:00Z"
  },
  "sources": {
    "total_sources": 4,
    "total_records": 2100,
    "file_sources": 1,
    "webhook_sources": 1,
    "crawl_sources": 2,
    "crisis_sources": 1,
    "normal_sources": 1,
    "sleep_sources": 0,
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
        "name": "TikTok Crawl",
        "type": "TIKTOK",
        "status": "ACTIVE",
        "crawl_mode": "CRISIS",
        "record_count": 1000
      }
    ]
  },
  "analytics": {
    "sentiment": {
      "positive": 45,
      "negative": 32,
      "neutral": 23,
      "distribution": [
        {"date": "2026-02-13", "positive": 40, "negative": 35, "neutral": 25},
        {"date": "2026-02-14", "positive": 42, "negative": 33, "neutral": 25},
        {"date": "2026-02-15", "positive": 45, "negative": 32, "neutral": 23}
      ]
    },
    "top_keywords": [
      {"keyword": "xe điện", "count": 450, "sentiment": "neutral"},
      {"keyword": "pin", "count": 320, "sentiment": "negative"},
      {"keyword": "sạc", "count": 280, "sentiment": "negative"}
    ],
    "aspects": [
      {"aspect": "BATTERY", "positive": 20, "negative": 60, "neutral": 20},
      {"aspect": "PRICE", "positive": 10, "negative": 70, "neutral": 20}
    ],
    "trends": {
      "sentiment_trend": "declining",
      "volume_trend": "increasing"
    }
  }
}
```

**Real-time Updates (WebSocket Push):**

```
[Analytics Service - Background Job]
    - Every 1 minute: Aggregate latest metrics
    - Detect significant changes (sentiment shift > 5%, etc.)
    - Publish to Redis: project:{id}:user:{uid}
    ↓
[Notification Service]
    - Subscribe Redis: project:*:user:*
    - Receive message
    - Transform to WebSocket message
    - Push to connected clients
    ↓
[Dashboard UI]
    - Receive WebSocket event
    - Update specific chart/metric (incremental update)
    - Show notification badge
```

**WebSocket Message Types:**

```typescript
// Type 1: Metrics Update (Incremental)
{
  "type": "DASHBOARD_METRICS_UPDATE",
  "timestamp": "2026-02-19T10:30:00Z",
  "payload": {
    "project_id": "proj_vf8",
    "metrics": {
      "sentiment": {"positive": 45, "negative": 32, "neutral": 23},
      "total_records": 2150
    },
    "change_summary": {
      "sentiment_shift": "+3% negative",
      "new_records": 50
    }
  }
}

// Type 2: Crisis Alert (High Priority)
{
  "type": "CRISIS_ALERT",
  "timestamp": "2026-02-19T10:31:00Z",
  "payload": {
    "project_id": "proj_vf8",
    "severity": "CRITICAL",
    "alert_type": "sentiment_spike",
    "metric": "Negative Sentiment",
    "current_value": 0.45,
    "threshold": 0.30,
    "affected_aspects": ["BATTERY", "PRICE"]
  }
}

// Type 3: Source Status Update
{
  "type": "DATA_SOURCE_UPDATE",
  "timestamp": "2026-02-19T10:32:00Z",
  "payload": {
    "project_id": "proj_vf8",
    "source_id": "src_tiktok_01",
    "status": "ACTIVE",
    "crawl_mode": "CRISIS",
    "message": "Switched to crisis mode due to sentiment spike"
  }
}
```

**Responsibilities Summary:**

| Service | Dashboard Role | Data Owned | API Provided |
|---------|---------------|------------|--------------|
| **Project Service** | **Dashboard Owner** | schema_project.projects<br>business.data_sources | GET /projects/{id}/dashboard<br>(Orchestrate + Aggregate) |
| **Analytics Service** | **Insights Provider** | analytics.post_analytics | GET /analytics/projects/{id}/insights<br>(Sentiment, Keywords, Trends) |
| **Notification Service** | **Real-time Pusher** | Redis Pub/Sub (transient) | WebSocket /ws<br>(Push updates) |

**Key Design Decisions:**

1. ✅ **Hybrid Approach:** HTTP Pull (initial load) + WebSocket Push (real-time updates)
2. ✅ **Separation of Concerns:** Project Service orchestrates, Analytics Service provides insights
3. ✅ **Graceful Degradation:** Dashboard works even if Analytics Service is down (shows metadata only)
4. ✅ **Cache Strategy:** Analytics Service caches insights (5 min TTL) for performance
5. ✅ **Change Detection:** Only push WebSocket updates when significant changes occur (> 5% shift)
6. ✅ **No Data Duplication:** Project Service doesn't store analytics data, always proxies to Analytics

**Performance Characteristics:**

| Metric | Value | Note |
|--------|-------|------|
| Initial Load | 200-500ms | HTTP + Redis cache |
| WebSocket Latency | 10-50ms | Redis Pub/Sub → WebSocket |
| Update Frequency | 1 min | Configurable per project |
| Cache TTL | 5 min | Balance freshness vs load |

---

#### 3.2.5 Simplified State Machine (REVISED - v2.12)

**Design Principles:**

1. **Separation of Concerns:** Project lifecycle ≠ Data Source lifecycle
2. **Clear Semantics:** States must be meaningful to users, not just technical execution details
3. **Explicit Triggers:** Every transition must specify WHO (User/System/External) triggers it
4. **Minimal Complexity:** Avoid transient states, use sub-statuses for execution details

---

**3.2.5.1 Project State Machine (4 States Only)**

Project states represent the BUSINESS LIFECYCLE of a monitoring entity, not technical execution details.

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROJECT STATE MACHINE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [*] ──────────► DRAFT ──────────► ACTIVE ──────────► ARCHIVED  │
│                   │                  │                           │
│                   │                  ↓                           │
│                   │                PAUSED                        │
│                   │                  │                           │
│                   │                  ↓                           │
│                   └──────────────► ACTIVE                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**State Definitions:**

| State      | Meaning                                                  | User Perspective                                  |
| ---------- | -------------------------------------------------------- | ------------------------------------------------- |
| `DRAFT`    | Project created, user is configuring data sources       | "I'm setting up my project"                       |
| `ACTIVE`   | Project is live, data sources are running                | "My project is monitoring data"                   |
| `PAUSED`   | Project temporarily stopped, can be resumed              | "I paused monitoring, will resume later"          |
| `ARCHIVED` | Project permanently stopped, historical data kept (90d)  | "This project is done, keep data for compliance"  |

**Project Transition Table:**

| From State | To State   | Trigger Event                    | Triggered By | Validation                                | System Actions                                                                 | Example                                                      |
| ---------- | ---------- | -------------------------------- | ------------ | ----------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| `null`     | `DRAFT`    | User creates project             | **USER**     | None                                      | INSERT INTO schema_project.projects (status='DRAFT')                                 | User clicks "New Project" button                             |
| `DRAFT`    | `ACTIVE`   | User activates project           | **USER**     | At least 1 data source with status=READY | UPDATE projects SET status='ACTIVE', activated_at=NOW(); Publish project.activated | User clicks "Activate Project" after configuring sources    |
| `ACTIVE`   | `PAUSED`   | User pauses project              | **USER**     | None                                      | UPDATE projects SET status='PAUSED'; Pause all ACTIVE sources; Publish project.paused | User clicks "Pause" button                                   |
| `PAUSED`   | `ACTIVE`   | User resumes project             | **USER**     | At least 1 data source can be resumed    | UPDATE projects SET status='ACTIVE'; Resume all PAUSED sources; Publish project.resumed | User clicks "Resume" button                                  |
| `ACTIVE`   | `ARCHIVED` | User archives project            | **USER**     | None                                      | UPDATE projects SET status='ARCHIVED', archived_at=NOW(); Cancel all jobs; Publish project.archived | User clicks "Archive" button                                 |
| `PAUSED`   | `ARCHIVED` | User archives paused project     | **USER**     | None                                      | UPDATE projects SET status='ARCHIVED', archived_at=NOW(); Publish project.archived | User clicks "Archive" button on paused project               |
| `DRAFT`    | `ARCHIVED` | User deletes draft project       | **USER**     | None                                      | UPDATE projects SET status='ARCHIVED', archived_at=NOW()                       | User clicks "Delete" on draft project                        |

**Key Insights:**

- ✅ **No CONFIGURING state** - DRAFT already means "user is configuring"
- ✅ **No ACTIVATING state** - activation is atomic, no transient state needed
- ✅ **No ONBOARDING_* states** - those belong to Data Source lifecycle, not Project
- ✅ **No DRYRUN_* states** - dry run is a Data Source validation step, not Project state
- ✅ **Clear trigger actors** - every transition explicitly states WHO triggers it

---

**3.2.5.2 Data Source State Machine (6 States)**

Data Source states represent the OPERATIONAL LIFECYCLE of individual data ingestion channels.

```
┌─────────────────────────────────────────────────────────────────┐
│                 DATA SOURCE STATE MACHINE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [*] ──► PENDING ──► READY ──► ACTIVE ──► COMPLETED             │
│            │          │         │                               │
│            │          │         ↓                               │
│            │          │       PAUSED                            │
│            │          │         │                               │
│            │          │         ↓                               │
│            │          └───────► ACTIVE                          │
│            │                                                    │
│            └──────────────────► FAILED                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**State Definitions:**

| State       | Meaning                                                  | Applies To                    | User Perspective                                  |
| ----------- | -------------------------------------------------------- | ----------------------------- | ------------------------------------------------- |
| `PENDING`   | Source created, waiting for configuration/validation     | All types                     | "I'm configuring this source"                     |
| `READY`     | Source validated, ready to activate                      | All types                     | "This source is ready to go"                      |
| `ACTIVE`    | Source is running (crawling/receiving data)              | All types                     | "This source is actively collecting data"         |
| `PAUSED`    | Source temporarily stopped (by user or parent project)   | Crawl, Webhook                | "I paused this source"                            |
| `COMPLETED` | Source finished (one-time sources only)                  | FILE_UPLOAD                   | "File upload completed"                           |
| `FAILED`    | Source encountered error, needs user intervention        | All types                     | "This source has an error, please fix"            |

**Data Source Transition Table:**

| From State | To State    | Trigger Event                                | Triggered By | Validation                                | System Actions                                                                 | Example                                                      |
| ---------- | ----------- | -------------------------------------------- | ------------ | ----------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| `null`     | `PENDING`   | User adds data source to project             | **USER**     | None                                      | INSERT INTO schema_ingest.data_sources (status='PENDING')                             | User clicks "Add Data Source" → selects type                 |
| `PENDING`  | `READY`     | Validation passed (onboarding/dry run)       | **SYSTEM**   | Depends on source type (see below)        | UPDATE data_sources SET status='READY', validated_at=NOW()                     | AI Schema Mapping confirmed OR Dry Run success               |
| `PENDING`  | `FAILED`    | Validation failed                            | **SYSTEM**   | None                                      | UPDATE data_sources SET status='FAILED', error_message='...'                   | Dry Run failed (auth error, connection timeout)              |
| `FAILED`   | `PENDING`   | User fixes config and retries                | **USER**     | None                                      | UPDATE data_sources SET status='PENDING', error_message=NULL                   | User updates keywords, clicks "Retry Validation"             |
| `READY`    | `ACTIVE`    | Parent project activated OR user activates   | **USER**     | Parent project status = ACTIVE            | UPDATE data_sources SET status='ACTIVE', activated_at=NOW(); Schedule jobs (if crawl) | Project activated → all READY sources become ACTIVE          |
| `ACTIVE`   | `PAUSED`    | User pauses source OR parent project paused  | **USER**     | None                                      | UPDATE data_sources SET status='PAUSED'; Cancel scheduled jobs                 | User clicks "Pause Source" OR Project paused                 |
| `PAUSED`   | `ACTIVE`    | User resumes source OR parent project resumed| **USER**     | Parent project status = ACTIVE            | UPDATE data_sources SET status='ACTIVE'; Reschedule jobs                       | User clicks "Resume Source" OR Project resumed               |
| `ACTIVE`   | `COMPLETED` | File upload processing finished              | **SYSTEM**   | source_type = FILE_UPLOAD                 | UPDATE data_sources SET status='COMPLETED', completed_at=NOW()                 | Ingest Service finished parsing Excel file                   |
| `ACTIVE`   | `FAILED`    | Runtime error (crawl API down, webhook auth) | **SYSTEM**   | None                                      | UPDATE data_sources SET status='FAILED', error_message='...'                   | External crawl API returns 500 error                         |
| `ACTIVE`   | `FAILED`    | Webhook signature validation failed          | **EXTERNAL** | HMAC signature mismatch                   | UPDATE data_sources SET status='FAILED', error_message='Invalid signature'     | External CRM sends webhook with wrong secret                 |

**Validation Rules by Source Type:**

| Source Type     | PENDING → READY Validation                                                                 | Triggered By | Example                                                      |
| --------------- | ------------------------------------------------------------------------------------------ | ------------ | ------------------------------------------------------------ |
| `FILE_UPLOAD`   | User uploads file → AI Schema Mapping → User confirms mapping                              | **USER**     | User uploads Excel → AI suggests mapping → User clicks "Confirm" |
| `WEBHOOK`       | User defines payload_schema → AI Schema Mapping → User confirms mapping → Webhook URL generated | **USER**     | User provides sample JSON → AI suggests mapping → User clicks "Confirm" |
| `FACEBOOK`      | User configures keywords → Dry Run (fetch sample data) → User reviews results → Success   | **SYSTEM**   | User enters "vinfast vf8" → System fetches 10 sample posts → User clicks "Looks good" |
| `TIKTOK`        | User configures keywords → Dry Run (fetch sample data) → User reviews results → Success   | **SYSTEM**   | User enters "vinfast vf8" → System fetches 10 sample videos → User clicks "Looks good" |
| `YOUTUBE`       | User configures keywords → Dry Run (fetch sample data) → User reviews results → Success   | **SYSTEM**   | User enters "vf8 review" → System fetches 10 sample videos → User clicks "Looks good" |

**Sub-Statuses (NOT main status, stored in separate columns):**

These are NOT part of the main state machine, but provide additional context for UI/debugging:

```sql
-- schema_project.projects table
status VARCHAR(20) NOT NULL,  -- DRAFT | ACTIVE | PAUSED | ARCHIVED

-- schema_ingest.data_sources table
status VARCHAR(20) NOT NULL,  -- PENDING | READY | ACTIVE | PAUSED | COMPLETED | FAILED

-- Sub-statuses (optional, for UI details)
onboarding_status VARCHAR(20),  -- NULL | IN_PROGRESS | CONFIRMED | REJECTED (for FILE_UPLOAD, WEBHOOK)
dryrun_status VARCHAR(20),      -- NULL | RUNNING | SUCCESS | WARNING | FAILED (for CRAWL sources)
error_message TEXT,             -- Error details when status=FAILED
last_error_at TIMESTAMPTZ,      -- Last error timestamp
```

**Key Insights:**

- ✅ **Separation:** Project states (4) vs Data Source states (6) - clear hierarchy
- ✅ **Meaningful:** States represent user-facing concepts, not technical execution steps
- ✅ **Sub-statuses:** Onboarding/Dry Run details stored separately, not polluting main state
- ✅ **Explicit triggers:** Every transition specifies WHO (User/System/External) triggers it
- ✅ **Lifecycle clarity:** FILE_UPLOAD ends at COMPLETED, CRAWL/WEBHOOK stay ACTIVE indefinitely

---

**3.2.5.3 Combined Flow Examples**

**Example 1: FILE_UPLOAD Source (Passive - One-time)**

```
Timeline:
─────────────────────────────────────────────────────────────────
T0: User creates project
    Project: null → DRAFT (USER)
    
T1: User adds File Upload source
    Source: null → PENDING (USER)
    
T2: User uploads Excel file
    Source: PENDING (onboarding_status=IN_PROGRESS) (SYSTEM)
    AI Schema Agent analyzes file
    
T3: User confirms mapping
    Source: PENDING → READY (USER)
    onboarding_status=CONFIRMED
    
T4: User activates project
    Project: DRAFT → ACTIVE (USER)
    Source: READY → ACTIVE (SYSTEM - cascaded from project)
    
T5: Ingest Service processes file
    Source: ACTIVE (processing 500 rows)
    
T6: Processing finished
    Source: ACTIVE → COMPLETED (SYSTEM)
    record_count=500
    
Result:
  - Project: ACTIVE (continues monitoring)
  - Source: COMPLETED (one-time, done)
─────────────────────────────────────────────────────────────────
```

**Example 2: TIKTOK Crawl Source (Active - Continuous)**

```
Timeline:
─────────────────────────────────────────────────────────────────
T0: User creates project
    Project: null → DRAFT (USER)
    
T1: User adds TikTok Crawl source
    Source: null → PENDING (USER)
    
T2: User configures keywords "vinfast vf8"
    Source: PENDING (dryrun_status=NULL)
    
T3: User clicks "Dry Run"
    Source: PENDING (dryrun_status=RUNNING) (SYSTEM)
    Ingest Service calls external crawl API
    
T4: Dry Run returns 10 sample videos
    Source: PENDING (dryrun_status=SUCCESS) (SYSTEM)
    User reviews sample data
    
T5: User clicks "Looks good"
    Source: PENDING → READY (USER)
    
T6: User activates project
    Project: DRAFT → ACTIVE (USER)
    Source: READY → ACTIVE (SYSTEM - cascaded from project)
    
T7: Scheduler starts crawling every 15 min
    Source: ACTIVE (crawl_mode=NORMAL, crawl_interval=15)
    
T8: Analytics detects crisis (45% negative)
    Source: ACTIVE (crawl_mode=CRISIS, crawl_interval=2) (SYSTEM)
    Adaptive Crawl switches mode
    
T9: User pauses project
    Project: ACTIVE → PAUSED (USER)
    Source: ACTIVE → PAUSED (SYSTEM - cascaded from project)
    
T10: User resumes project
    Project: PAUSED → ACTIVE (USER)
    Source: PAUSED → ACTIVE (SYSTEM - cascaded from project)
    
Result:
  - Project: ACTIVE (continues monitoring)
  - Source: ACTIVE (crawling every 2 min - crisis mode)
─────────────────────────────────────────────────────────────────
```

**Example 3: WEBHOOK Source (Passive - Continuous)**

```
Timeline:
─────────────────────────────────────────────────────────────────
T0: User creates project
    Project: null → DRAFT (USER)
    
T1: User adds Webhook source
    Source: null → PENDING (USER)
    
T2: User provides sample JSON payload
    Source: PENDING (onboarding_status=IN_PROGRESS) (SYSTEM)
    AI Schema Agent analyzes payload
    
T3: User confirms mapping
    Source: PENDING → READY (USER)
    onboarding_status=CONFIRMED
    webhook_url generated: https://smap.com/webhook/abc123
    
T4: User activates project
    Project: DRAFT → ACTIVE (USER)
    Source: READY → ACTIVE (SYSTEM - cascaded from project)
    
T5: External CRM pushes data
    Source: ACTIVE (receiving data) (EXTERNAL)
    Ingest Service validates HMAC signature
    
T6: Invalid signature received
    Source: ACTIVE → FAILED (EXTERNAL)
    error_message="Invalid HMAC signature"
    
T7: User fixes CRM webhook secret
    Source: FAILED → PENDING (USER)
    User clicks "Retry"
    
T8: User re-validates
    Source: PENDING → READY (USER)
    
T9: System auto-activates (parent project is ACTIVE)
    Source: READY → ACTIVE (SYSTEM)
    
Result:
  - Project: ACTIVE (continues monitoring)
  - Source: ACTIVE (receiving webhook data)
─────────────────────────────────────────────────────────────────
```

---

**3.2.5.4 Database Schema (Updated)**

```sql
-- schema_project.projects table
CREATE TABLE schema_project.projects (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    entity_type VARCHAR(50),
    entity_name VARCHAR(255),
    
    -- SIMPLIFIED STATUS (4 states only)
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- Allowed values: DRAFT | ACTIVE | PAUSED | ARCHIVED
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    
    created_by VARCHAR(50) NOT NULL,
    
    CONSTRAINT chk_project_status CHECK (status IN ('DRAFT', 'ACTIVE', 'PAUSED', 'ARCHIVED'))
);

-- schema_ingest.data_sources table
CREATE TABLE schema_ingest.data_sources (
    id VARCHAR(50) PRIMARY KEY,
    project_id VARCHAR(50) NOT NULL REFERENCES schema_project.projects(id),
    
    source_type VARCHAR(20) NOT NULL,
    -- Allowed values: FILE_UPLOAD | WEBHOOK | FACEBOOK | TIKTOK | YOUTUBE
    
    source_category VARCHAR(20) NOT NULL,
    -- Allowed values: passive | crawl
    
    -- SIMPLIFIED STATUS (6 states)
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- Allowed values: PENDING | READY | ACTIVE | PAUSED | COMPLETED | FAILED
    
    -- SUB-STATUSES (not main status, for UI details)
    onboarding_status VARCHAR(20),
    -- NULL | IN_PROGRESS | CONFIRMED | REJECTED (for FILE_UPLOAD, WEBHOOK)
    
    dryrun_status VARCHAR(20),
    -- NULL | RUNNING | SUCCESS | WARNING | FAILED (for CRAWL sources)
    
    error_message TEXT,
    last_error_at TIMESTAMPTZ,
    
    -- Crawl-specific fields (NULL for passive sources)
    crawl_mode VARCHAR(20),
    -- NULL | SLEEP | NORMAL | CRISIS (for CRAWL sources only)
    
    crawl_interval INT,
    -- Interval in minutes (NULL for passive sources)
    
    next_crawl_at TIMESTAMPTZ,
    -- Next scheduled crawl time (NULL for passive sources)
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    validated_at TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    record_count INT DEFAULT 0,
    last_received_at TIMESTAMPTZ,
    
    CONSTRAINT chk_source_status CHECK (status IN ('PENDING', 'READY', 'ACTIVE', 'PAUSED', 'COMPLETED', 'FAILED')),
    CONSTRAINT chk_source_type CHECK (source_type IN ('FILE_UPLOAD', 'WEBHOOK', 'FACEBOOK', 'TIKTOK', 'YOUTUBE')),
    CONSTRAINT chk_source_category CHECK (source_category IN ('passive', 'crawl')),
    CONSTRAINT chk_onboarding_status CHECK (onboarding_status IN ('IN_PROGRESS', 'CONFIRMED', 'REJECTED')),
    CONSTRAINT chk_dryrun_status CHECK (dryrun_status IN ('RUNNING', 'SUCCESS', 'WARNING', 'FAILED')),
    CONSTRAINT chk_crawl_mode CHECK (crawl_mode IN ('SLEEP', 'NORMAL', 'CRISIS'))
);

-- State transition audit log
CREATE TABLE business.project_state_history (
    id SERIAL PRIMARY KEY,
    project_id VARCHAR(50) NOT NULL REFERENCES schema_project.projects(id),
    from_state VARCHAR(20),
    to_state VARCHAR(20) NOT NULL,
    triggered_by VARCHAR(20) NOT NULL,
    -- USER | SYSTEM | EXTERNAL
    trigger_actor_id VARCHAR(50),
    -- user_id if triggered_by=USER, NULL otherwise
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_triggered_by CHECK (triggered_by IN ('USER', 'SYSTEM', 'EXTERNAL'))
);

CREATE TABLE ingest.data_source_state_history (
    id SERIAL PRIMARY KEY,
    source_id VARCHAR(50) NOT NULL REFERENCES schema_ingest.data_sources(id),
    from_state VARCHAR(20),
    to_state VARCHAR(20) NOT NULL,
    triggered_by VARCHAR(20) NOT NULL,
    trigger_actor_id VARCHAR(50),
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_triggered_by CHECK (triggered_by IN ('USER', 'SYSTEM', 'EXTERNAL'))
);
```

---

**3.2.5.5 API Endpoints (Updated)**

```go
// GET /projects/{id}
// Returns project with current status and all data sources

// Response:
{
    "id": "proj_vf8",
    "name": "Monitor VF8",
    "status": "ACTIVE",
    "activated_at": "2026-02-15T10:00:00Z",
    "data_sources": [
        {
            "id": "src_excel_01",
            "type": "FILE_UPLOAD",
            "status": "COMPLETED",
            "onboarding_status": "CONFIRMED",
            "record_count": 500,
            "completed_at": "2026-02-15T10:05:00Z"
        },
        {
            "id": "src_tiktok_01",
            "type": "TIKTOK",
            "status": "ACTIVE",
            "dryrun_status": "SUCCESS",
            "crawl_mode": "CRISIS",
            "crawl_interval": 2,
            "next_crawl_at": "2026-02-15T10:47:00Z",
            "record_count": 1000
        }
    ]
}

// POST /projects/{id}/activate
// Activates project (DRAFT → ACTIVE)
// Validation: At least 1 data source with status=READY

// POST /projects/{id}/pause
// Pauses project (ACTIVE → PAUSED)
// Cascades to all ACTIVE data sources

// POST /projects/{id}/resume
// Resumes project (PAUSED → ACTIVE)
// Cascades to all PAUSED data sources

// POST /projects/{id}/archive
// Archives project (ACTIVE/PAUSED → ARCHIVED)

// GET /projects/{id}/state-history
// Returns state transition audit log with trigger actors

// Response:
{
    "transitions": [
        {
            "from_state": null,
            "to_state": "DRAFT",
            "triggered_by": "USER",
            "trigger_actor_id": "user_123",
            "reason": "User created project",
            "created_at": "2026-02-15T09:00:00Z"
        },
        {
            "from_state": "DRAFT",
            "to_state": "ACTIVE",
            "triggered_by": "USER",
            "trigger_actor_id": "user_123",
            "reason": "User clicked Activate button",
            "created_at": "2026-02-15T10:00:00Z"
        },
        {
            "from_state": "ACTIVE",
            "to_state": "PAUSED",
            "triggered_by": "USER",
            "trigger_actor_id": "user_123",
            "reason": "User clicked Pause button",
            "created_at": "2026-02-15T11:00:00Z"
        }
    ]
}

// POST /data-sources/{id}/validate
// Triggers validation (PENDING → READY or FAILED)
// For FILE_UPLOAD/WEBHOOK: Triggers AI Schema Mapping
// For CRAWL: Triggers Dry Run

// POST /data-sources/{id}/retry
// Retries failed source (FAILED → PENDING)

// POST /data-sources/{id}/pause
// Pauses individual source (ACTIVE → PAUSED)

// POST /data-sources/{id}/resume
// Resumes individual source (PAUSED → ACTIVE)
```

**Complete State Machine:**

```
[*] ──────────────────────────────────────────► DRAFT
     User creates project

DRAFT ──────────────────────────────────────► CONFIGURING
     User adds data sources
     Trigger: User action
     Validation: None
```

---

### 3.3 Ingest Service (Data Source + AI Schema Agent)

```yaml
name: ingest-service
language: Go
responsibility:
  - Data source management (Crawl + Passive)
  - File upload & parsing (Excel, CSV, JSON)
  - Webhook endpoint management (payload schema, URL generation)
  - External crawl API integration (thay scrapper)
  - AI Schema Mapping coordination (cho File Upload + Webhook)
  - Dry Run coordination (cho Crawl sources)
  - Job orchestration

modules:
  - /sources # Quản lý data sources
  - /upload # File upload endpoint
  - /webhook # Webhook management (register, receive, schema)
  - /crawl # External API adapter (gọi teammate's server)
  - /schema # AI Schema Mapping (preview, confirm)
  - /dryrun # Dry Run cho crawl sources
  - /jobs # Job management

source_categories:
  # Crawl Sources (cần Dry Run)
  - type: FACEBOOK
    category: crawl
    trigger: scheduled_poll
  - type: TIKTOK
    category: crawl
    trigger: one_time_crawl
  - type: YOUTUBE
    category: crawl
    trigger: scheduled_poll

  # Passive Sources (cần Data Onboarding - AI Schema Mapping)
  - type: FILE_UPLOAD
    category: passive
    trigger: manual_upload
    onboarding: ai_schema_mapping (from file header)
  - type: WEBHOOK
    category: passive
    trigger: external_push
    onboarding: ai_schema_mapping (from payload_schema)

data_adapters:
  # Adapter 1: File Upload (tự xử lý)
  - type: file
    formats: [excel, csv, json]
    handler: internal

  # Adapter 2: External Crawl API (outsource)
  - type: social_crawl
    provider: external_mmo_server
    protocol: REST API / gRPC
    platforms: [youtube, tiktok, facebook]
    handler: external_api_client

external_api_contract:
  # Request gửi đi
  request:
    endpoint: POST /api/crawl
    payload:
      keywords: ["vinfast", "vf8"]
      platforms: ["youtube", "tiktok"]
      date_range: { from: "2025-01-01", to: "2025-02-01" }
      limit_per_keyword: 50

  # Response nhận về
  response:
    format: JSON / JSONL
    delivery:
      - sync: Direct response (cho small requests)
      - async: Webhook callback (cho large requests)
    schema:
      - content_id
      - platform
      - title
      - description
      - author
      - engagement (views, likes, comments)
      - published_at
      - media_url (optional)

database:
  - PostgreSQL (ingest_db) - metadata
  - MongoDB (raw_data) - raw content từ external API

message_queues:
  - ingest.file.uploaded
  - ingest.crawl.requested # Gửi request tới external
  - ingest.crawl.completed # Nhận callback từ external
  - ingest.data.ready
```

**Lợi ích của External Data Provider:**

| Aspect         | Tự build Scrapper                    | External API               |
| -------------- | ------------------------------------ | -------------------------- |
| Complexity     | 🔴 Cao (anti-bot, proxy, rate limit) | 🟢 Thấp (chỉ call API)     |
| Maintenance    | 🔴 Liên tục update khi platform đổi  | 🟢 Teammate lo             |
| Cost           | 🔴 Server, proxy, captcha solving    | 🟡 Trả phí API             |
| Reliability    | 🔴 Dễ bị block                       | 🟢 Teammate có kinh nghiệm |
| Time to market | 🔴 Chậm                              | 🟢 Nhanh                   |

### 3.4 Analytics Service (Refactored - Go Consumer + Orchestrator)

**REVISION v2.10:** Giữ nguyên Go service, refactor structure để scalable và maintainable.

**Lý do không dùng n8n:**

1. ❌ Single instance bottleneck - không scale ngang
2. ❌ Performance overhead của visual workflow engine
3. ❌ Khó debug production issues (visual workflows không có stack trace)
4. ❌ Vendor lock-in

```yaml
name: analytics-service
language: Go
architecture: Consumer + Orchestrator + AI Workers

responsibility:
  - Consume UAP từ Kafka
  - Orchestrate AI analysis pipeline
  - Call AI Workers (HTTP/gRPC)
  - Aggregate results
  - Write to schema_analysis.* schema
  - Publish completion events

modules:
  - /consumer # Kafka consumer (UAP messages)
  - /orchestrator # Pipeline orchestration logic
  - /workers # AI worker clients (HTTP)
  - /repository # Database access (schema_analysis.*)
  - /api # Internal API (optional, for monitoring)

entry_points:
  - cmd/consumer/main.go # Kafka consumer process
  - cmd/api/main.go # API server (optional, for health check)

ai_workers:
  - name: sentiment-worker
    language: Python (FastAPI)
    endpoint: http://sentiment-worker:8000/analyze/sentiment
    input: {content: string}
    output: {sentiment: string, score: float}

  - name: aspect-worker
    language: Python (FastAPI)
    endpoint: http://aspect-worker:8000/analyze/aspects
    input: {content: string, aspects: string[]}
    output: [{aspect, sentiment, score, keywords}]

  - name: keyword-worker
    language: Python (FastAPI)
    endpoint: http://keyword-worker:8000/extract/keywords
    input: {content: string}
    output: {keywords: string[]}

database: PostgreSQL (schema_analysis.* schema)

message_queues:
  consume:
    - analytics.uap.received
  publish:
    - analytics.sentiment.completed
    - analytics.batch.completed
```

**Analytics Pipeline Flow (Go Orchestrator):**

```go
// internal/orchestrator/pipeline.go
package orchestrator

type Pipeline struct {
    sentimentClient *workers.SentimentClient
    aspectClient    *workers.AspectClient
    keywordClient   *workers.KeywordClient
    repo            *repository.AnalyticsRepo
}

func (p *Pipeline) ProcessUAP(ctx context.Context, uap *UAP) error {
    // 1. Call Sentiment Worker
    sentiment, err := p.sentimentClient.Analyze(ctx, uap.Content)
    if err != nil {
        return fmt.Errorf("sentiment analysis failed: %w", err)
    }

    // 2. Call Aspect Worker (parallel with keyword)
    var aspectResult *AspectResult
    var keywordResult *KeywordResult

    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() error {
        var err error
        aspectResult, err = p.aspectClient.Analyze(ctx, uap.Content, aspects)
        return err
    })

    g.Go(func() error {
        var err error
        keywordResult, err = p.keywordClient.Extract(ctx, uap.Content)
        return err
    })

    if err := g.Wait(); err != nil {
        return fmt.Errorf("parallel analysis failed: %w", err)
    }

    // 3. Aggregate results
    analytics := &PostAnalytics{
        ProjectID:           uap.ProjectID,
        SourceID:            uap.SourceID,
        Content:             uap.Content,
        ContentCreatedAt:    uap.ContentCreatedAt,
        IngestedAt:          uap.IngestedAt,
        OverallSentiment:    sentiment.Sentiment,
        OverallSentimentScore: sentiment.Score,
        Aspects:             aspectResult.Aspects,
        Keywords:            keywordResult.Keywords,
    }

    // 4. Save to database
    if err := p.repo.Insert(ctx, analytics); err != nil {
        return fmt.Errorf("failed to save analytics: %w", err)
    }

    return nil
}
```

**Consumer Implementation:**

```go
// cmd/consumer/main.go
package main

func main() {
    // Initialize Kafka consumer
    consumer := kafka.NewConsumer(kafka.ConsumerConfig{
        Brokers: []string{"kafka:9092"},
        Topic:   "analytics.uap.received",
        GroupID: "analytics-consumer",
    })

    // Initialize pipeline
    pipeline := orchestrator.NewPipeline(
        workers.NewSentimentClient("http://sentiment-worker:8000"),
        workers.NewAspectClient("http://aspect-worker:8000"),
        workers.NewKeywordClient("http://keyword-worker:8000"),
        repository.NewAnalyticsRepo(db),
    )

    // Process messages
    for {
        msg, err := consumer.ReadMessage(ctx)
        if err != nil {
            log.Error("failed to read message", err)
            continue
        }

        var uap UAP
        if err := json.Unmarshal(msg.Value, &uap); err != nil {
            log.Error("failed to unmarshal UAP", err)
            continue
        }

        // Process in goroutine for concurrency
        go func(uap UAP) {
            if err := pipeline.ProcessUAP(ctx, &uap); err != nil {
                log.Error("failed to process UAP", err)
            }
        }(uap)
    }
}
```

**Scalability Strategy:**

```yaml
# k8s/analytics-consumer-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics-consumer
spec:
  replicas: 5 # Horizontal scaling
  selector:
    matchLabels:
      app: analytics-consumer
  template:
    spec:
      containers:
        - name: consumer
          image: analytics-service:latest
          command: ["/app/consumer"]
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1Gi
          env:
            - name: KAFKA_BROKERS
              value: "kafka:9092"
            - name: KAFKA_GROUP_ID
              value: "analytics-consumer"
```

**Lợi ích:**

- ✅ **Horizontal Scaling:** Deploy 5-10 consumer replicas
- ✅ **Performance:** Go concurrency xử lý hàng ngàn UAP/sec
- ✅ **Observability:** Standard logging, metrics (Prometheus), tracing (Jaeger)
- ✅ **Maintainability:** Code-based logic, dễ debug, dễ test
- ✅ **Reliability:** Kafka consumer group auto-rebalancing

### 3.5 Notification Service (Rename từ websocket)

```yaml
name: notification-service
language: Go
responsibility:
  - WebSocket connections (giữ nguyên)
  - Real-time notifications
  - Alert dispatching

modules:
  - /ws # WebSocket hub (giữ nguyên)
  - /alerts # Alert dispatcher (MỚI)

integrations:
  - Slack webhook
  - Email (SMTP)
  - In-app notifications (WebSocket)

database: Không cần (stateless, dùng Redis Pub/Sub)
```

### 3.6 Knowledge Service (Mới hoàn toàn)

```yaml
name: knowledge-service
language: Go # Chuyển từ Python sang Go theo quyết định v2.3
responsibility:
  - RAG (Retrieval-Augmented Generation)
  - Vector embeddings
  - Conversational Q&A
  - Context retrieval

modules:
  - /embed # Text → Vector embedding
  - /search # Semantic search
  - /chat # Conversational interface

tech_stack:
  - Qdrant (Vector DB)
  - OpenAI API / Local LLM
  - LangChain

database: Qdrant (vector_db)

message_queues:
  - knowledge.indexed
  - knowledge.query.completed
```

---

## 4. DATABASE RESTRUCTURE

### 4.1 Multi-Schema Strategy (Single PostgreSQL Instance)

Theo quyết định ở Section 0.5, sử dụng **1 PostgreSQL Instance** với **4 Schemas** thay vì nhiều databases riêng biệt.

**Migration từ hệ thống cũ:**

| DB Cũ                  | Schema Mới     | Hành động                        |
| ---------------------- | -------------- | -------------------------------- |
| identity_db            | `schema_identity.*`       | Simplify: chỉ users + audit_logs |
| project_db             | `schema_project.*`   | Giữ + thêm campaigns table       |
| (Mới)                  | `schema_ingest.*`     | Tạo mới cho Data Sources         |
| collector_db (MongoDB) | ❌ XOÁ         | Không cần raw storage riêng      |
| analytics_db           | `schema_analysis.*`  | Giữ + extend với UAP fields      |
| (Mới)                  | Qdrant (riêng) | Vector DB cho RAG                |
| (Mới)                  | Redis (riêng)  | Session store, cache             |

**Connection String:** Khách hàng chỉ cần cung cấp 1 PostgreSQL connection. Hệ thống tự động tạo schemas khi migrate.

### 4.2 Schema Definitions

#### auth.\* (Auth Service)

```sql
-- Schema creation
CREATE SCHEMA IF NOT EXISTS auth;

-- Users table (auto-created on first SSO login)
CREATE TABLE schema_identity.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'VIEWER',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit log table
CREATE TABLE schema_identity.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES schema_identity.users(id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_auth_users_email ON schema_identity.users(email);
CREATE INDEX idx_auth_audit_user ON schema_identity.audit_logs(user_id);
CREATE INDEX idx_auth_audit_created ON schema_identity.audit_logs(created_at);
```

#### business.\* (Project Service)

```sql
CREATE SCHEMA IF NOT EXISTS business;

-- Projects table (Entity Monitoring Unit - Tầng 2)
CREATE TABLE schema_project.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),                    -- Tên brand (text, dùng để nhóm hiển thị)
    entity_type VARCHAR(50),               -- product, campaign, service, competitor, topic
    entity_name VARCHAR(200),              -- Tên thực thể cụ thể (VD: "VF8")
    description TEXT,
    industry VARCHAR(100),
    config_status VARCHAR(20) DEFAULT 'DRAFT',
    -- Values: DRAFT, CONFIGURING, ONBOARDING, ONBOARDING_DONE,
    --         DRYRUN_RUNNING, DRYRUN_SUCCESS, DRYRUN_FAILED, ACTIVE, ERROR
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Campaigns table (Tầng 3 - Logical Analysis Unit)
CREATE TABLE schema_project.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Campaign-Project relationship (many-to-many)
CREATE TABLE schema_project.campaign_projects (
    campaign_id UUID REFERENCES schema_project.campaigns(id) ON DELETE CASCADE,
    project_id UUID REFERENCES schema_project.projects(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (campaign_id, project_id)
);

-- Campaign Artifacts table (AI-generated reports, documents)
CREATE TABLE business.campaign_artifacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES schema_project.campaigns(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,           -- "Báo cáo so sánh Q1.pdf"
    file_type VARCHAR(50),                -- "application/pdf", "text/markdown"
    storage_path TEXT NOT NULL,           -- MinIO path
    created_by_ai BOOLEAN DEFAULT true,
    -- Editing support fields (v2.5)
    content_markdown TEXT,                -- Editable source content
    google_doc_id VARCHAR(255),           -- Google Drive file ID (optional)
    google_doc_url TEXT,                  -- Direct edit URL (optional)
    last_synced_at TIMESTAMPTZ,           -- Last sync from Google Docs
    version INTEGER DEFAULT 1,            -- Version tracking for audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_biz_projects_created_by ON schema_project.projects(created_by);
CREATE INDEX idx_biz_campaigns_created_by ON schema_project.campaigns(created_by);
CREATE INDEX idx_biz_artifacts_campaign ON business.campaign_artifacts(campaign_id);
```

#### ingest.\* (Ingest Service)

```sql
CREATE SCHEMA IF NOT EXISTS ingest;

-- Data Sources table (Tầng 1 - Physical Data Unit)
CREATE TABLE schema_ingest.data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL, -- Reference to schema_project.projects
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(20) NOT NULL, -- 'FILE_UPLOAD', 'WEBHOOK', 'FACEBOOK', 'TIKTOK', 'YOUTUBE'
    source_category VARCHAR(10) NOT NULL DEFAULT 'passive', -- 'crawl' hoặc 'passive'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'mapping', 'processing', 'completed', 'failed'

    -- File info (cho FILE_UPLOAD)
    file_config JSONB, -- {filename, size, mime_type, minio_path, sample_file_path}

    -- Webhook info (cho WEBHOOK)
    webhook_config JSONB, -- {name, description, payload_schema, webhook_url, secret}

    -- Crawl info (cho FACEBOOK, TIKTOK, YOUTUBE)
    crawl_config JSONB, -- {page_id, access_token, sync_interval, keywords...}

    -- AI Schema Agent mapping (cho FILE_UPLOAD + WEBHOOK)
    schema_mapping JSONB, -- {content: {source_column, confidence}, created_at: {...}, metadata: {...}}
    mapping_rules JSONB, -- Confirmed mapping rules
    onboarding_status VARCHAR(20), -- PENDING, MAPPING_READY, CONFIRMED (chỉ cho passive sources)

    -- Stats
    record_count INT DEFAULT 0,
    error_count INT DEFAULT 0,

    -- Connection check (cho crawl sources)
    last_check_at TIMESTAMPTZ,
    last_error_msg TEXT, -- Đã sanitize
    credential_hash VARCHAR(255),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_ingest_sources_project ON schema_ingest.data_sources(project_id);
CREATE INDEX idx_ingest_sources_status ON schema_ingest.data_sources(status);
```

#### analytics.\* (Analytics Service / n8n Workers)

```sql
CREATE SCHEMA IF NOT EXISTS analytics;

-- Post analytics table (UAP-based)
CREATE TABLE analytics.post_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL, -- Reference to schema_project.projects
    source_id UUID NOT NULL,  -- Reference to schema_ingest.data_sources

    -- UAP Core Fields
    content TEXT NOT NULL,
    content_created_at TIMESTAMPTZ NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    platform VARCHAR(50),

    -- Analysis Results
    overall_sentiment VARCHAR(20),
    overall_sentiment_score FLOAT,
    aspects JSONB, -- [{aspect, sentiment, score, keywords}]
    keywords TEXT[],
    risk_level VARCHAR(20),

    -- Metadata
    uap_metadata JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crawl errors tracking
CREATE TABLE analytics.crawl_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL,
    error_type VARCHAR(50),
    error_message TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ana_post_project ON analytics.post_analytics(project_id);
CREATE INDEX idx_ana_post_source ON analytics.post_analytics(source_id);
CREATE INDEX idx_ana_post_created ON analytics.post_analytics(content_created_at);
CREATE INDEX idx_ana_post_sentiment ON analytics.post_analytics(overall_sentiment);
```

---

## 5. USE CASE IMPLEMENTATION

### 5.1 UC-01: Smart Data Onboarding (Tầng 1 - Data Source)

**Vấn đề UX cần giải quyết:**

- **Blind Crawling:** User nhập keyword sai → thu thập dữ liệu rác, lãng phí tài nguyên
- **Vector Ambiguity:** Chưa rõ thời điểm đưa data vào Qdrant → RAG không thể filter theo sentiment/aspect

**Quan hệ Entity:** 1 Project có thể có NHIỀU Data Sources (1:N relationship)

```
┌─────────────────────────────────────────────────────────────────┐
│  Project "Monitor VF8" (Tầng 2)                                 │
│  ├── brand: "VinFast", entity_type: "product", entity_name: "VF8"│
│  ├── Data Source 1: Excel "Feedback VF8 Q1.xlsx" (500 records)  │
│  ├── Data Source 2: TikTok Crawl "vinfast vf8" (1000 records)   │
│  ├── Data Source 3: Webhook từ CRM (ongoing)                    │
│  └── Data Source 4: YouTube Crawl "vf8 review" (300 records)    │
│                                                                 │
│  → Tổng: 1800+ UAP records, tất cả có project_id = "Monitor VF8"│
│  → Dashboard aggregates TẤT CẢ sources cho entity VF8           │
│  → Có thể filter theo từng source_id                            │
└─────────────────────────────────────────────────────────────────┘
```

```
Actor: Data Officer / Marketing Admin
Entity Level: Data Source (Tầng 1)

Precondition: User đã tạo Project (Tầng 2) với brand, entity_type, entity_name

Flow:
1. User chọn Project để thêm Data Source
   - Một Project có thể có NHIỀU Data Sources
   - Mỗi lần thêm = tạo 1 Data Source mới
   - User có thể lặp lại flow này nhiều lần cho cùng 1 Project

2. User chọn loại nguồn dữ liệu:
   A. Crawl Sources (cần Dry Run):
      - Facebook, TikTok, YouTube
      - Config optional (page_id, access_token, sync_interval)
      - Không set thì crawl theo cơ chế mặc định
   B. Passive Sources (cần Data Onboarding - AI Schema Mapping):
      - File Upload (Excel, CSV, JSON)
      - Webhook (user define payload schema)

3. Nếu File Upload (Passive):
   a. Upload file mẫu → MinIO (/temp/{project_id}/)
   b. AI Schema Agent inspect (LLM đọc Header + 5 dòng) — SYNCHRONOUS
   c. Hiển thị bảng mapping gợi ý:
      ┌────────────────────┬─────────────┬────────────┐
      │ Cột gốc            │ UAP Field   │ Confidence │
      ├────────────────────┼─────────────┼────────────┤
      │ Ý kiến khách hàng  │ content     │ 95%        │
      │ Ngày gửi           │ created_at  │ 90%        │
      │ Tên KH             │ metadata.   │ 85%        │
      │                    │ author      │            │
      └────────────────────┴─────────────┴────────────┘
   d. User confirm/edit mapping
   e. Mapping rules lưu vào source config (onboarding_status=CONFIRMED)

4. Nếu Webhook (Passive):
   a. User define payload schema (JSON structure mà webhook sẽ gửi)
      VD: {"message": "string", "user": "string", "timestamp": "datetime"}
   b. AI Schema Agent suggest mapping sang UAP — SYNCHRONOUS
   c. User confirm/edit mapping
   d. Mapping rules lưu vào source config (onboarding_status=CONFIRMED)
   e. Webhook URL + secret sẽ được generate khi Activate

5. Nếu Crawl Source (Facebook, TikTok, YouTube):
   a. Nhập config (optional: keywords, page_id, access_token...)

   b. DRY-RUN Step (Preview Mode):
      - User bấm "Test Crawl / Preview"
      - Worker test connection + fetch 5 items mới nhất — ASYNC qua Kafka
      - Hiển thị preview (Raw Text + Metadata) trong popup
      - Decision:
        • Case A (Lỗi): User điều chỉnh config → Test lại
        • Case B (OK): User bấm "Confirm"

6. Activate Project (khi đủ điều kiện):
   - Passive sources: onboarding_status = CONFIRMED
   - Crawl sources: dryrun = SUCCESS/WARNING
   - Generate webhook URLs, schedule crawl jobs

7. Sau Activate:
   - File Upload: User upload file thật → Transform toàn bộ → UAP → Queue
   - Webhook: External service push data → Apply mapping rules → UAP → Queue
   - Crawl: Scheduled jobs fetch data → Transform → UAP → Queue

8. n8n Workflow trigger → gọi AI Workers (Sentiment, Aspect, Keyword)

9. VECTOR UPSERT TRIGGER (The Knowledge Hook):
   - CHỈ KHI data đã có đủ nhãn (Sentiment + Aspect)
   - n8n gọi API: POST /knowledge/index

Output:
- Data Source record trong schema_ingest.* schema
- UAP records trong schema_analysis.* schema
- Vector embeddings trong Qdrant (với sentiment/aspect metadata)

Services involved:
- ingest-service (orchestration, AI Schema Agent, Dry-Run)
- analytics-pipeline (n8n + AI Workers)
- knowledge-service (vector indexing sau khi có labels)
```

### 5.2 UC-02: Brand Health Monitoring (Tầng 2 - Project)

```
Actor: Marketing Manager / CMO
Entity Level: Project (Tầng 2) — 1 Project = 1 thực thể cụ thể

Flow:
1. User mở Dashboard
2. Chọn Project để monitor (e.g., "Monitor VF8")
   - Có thể filter theo brand để tìm nhanh (VD: brand="VinFast")
3. Dashboard hiển thị dữ liệu của TẤT CẢ Data Sources trong Project:
   - Overall sentiment score
   - Sentiment trend over time
   - Aspect breakdown (DESIGN, PRICE, SERVICE...)
   - Top keywords
   - Recent mentions
   - Data Source breakdown (nguồn nào đóng góp bao nhiêu)

4. Crisis Alert (background):
   - Hệ thống monitor sentiment threshold
   - Nếu negative > threshold → Trigger alert
   - Gửi notification qua Slack/Email/In-app

5. User có thể:
   - Filter by date, platform, aspect, data source
   - Drill-down vào specific mentions
   - Export report

Query scope: WHERE project_id = 'VinFast'
(Không so sánh cross-project tại đây)

Services involved:
- project-service (dashboard data aggregation)
- notification-service (WebSocket, alerts)
- analytics-service (data retrieval)
```

### 5.3 UC-03: Diagnostic Analytics & RAG - Campaign War Room (Tầng 3)

**Vấn đề UX cần giải quyết:**

- **Passive Interface:** Giao diện Campaign chỉ có chat → Manager cần cái nhìn tổng quan ngay lập tức
- **Lack of Artifacts:** Chat xong thông tin trôi đi, không lưu báo cáo AI tạo ra

**Giải pháp: Campaign War Room Dashboard** - Trung tâm Chỉ huy Chiến lược với 3 thành phần:

![Campaign UI](../../documents/images/campaing-ui.png)

**A. Visual Comparison Widgets (Auto-load khi mở Campaign):**

| Widget               | Loại biểu đồ      | Ý nghĩa                                                            |
| -------------------- | ----------------- | ------------------------------------------------------------------ |
| **Share of Voice**   | Pie/Donut Chart   | Ai chiếm sóng thảo luận nhiều hơn? (VD: VinFast 65% - BYD 35%)     |
| **Sentiment Battle** | Stacked Bar Chart | So sánh tỷ lệ Tích cực/Tiêu cực giữa các brands                    |
| **Aspect Heatmap**   | Heatmap Table     | Ma trận: Trục tung = Aspects, Trục hoành = Brands, Màu = Sentiment |

**B. RAG Chat Interface (Contextual Assistant):**

- Tự động nạp context của các Projects trong Campaign
- Smart Suggestions dựa trên Heatmap: _"Tại sao VinFast bị đỏ ở mục 'Giá'?"_

**C. Artifacts Library (với Edit Capability):**

- User yêu cầu: _"Viết báo cáo so sánh tháng này, xuất PDF"_
- RAG Engine → Generate Text → Convert PDF → Upload MinIO
- File xuất hiện trong list "Generated Reports"

**Artifact Actions:**

| Action                 | Mô tả                              | Implementation                                    |
| ---------------------- | ---------------------------------- | ------------------------------------------------- |
| **Preview**            | Xem nhanh nội dung                 | Modal với PDF viewer / Markdown renderer          |
| **Download**           | Tải về máy                         | Direct link từ MinIO                              |
| **Edit (Inline)**      | Chỉnh sửa trực tiếp trong UI       | Rich Text Editor (TipTap/Lexical) → Re-export PDF |
| **Edit (Google Docs)** | Mở trong Google Docs với live sync | OAuth → Create/Update Google Doc → Embed iframe   |

**Edit Workflow Options:**

```
Option A: Inline Editor (Recommended for MVP)
─────────────────────────────────────────────
User click "Edit" → Load Markdown content → TipTap Editor
                 → User chỉnh sửa
                 → Save → Re-generate PDF → Update MinIO
                 → Artifact version +1

Option B: Google Docs Integration (Advanced)
─────────────────────────────────────────────
User click "Open in Google Docs"
  → Check if google_doc_id exists
  → NO:  Create new Google Doc (via Drive API)
         → Store google_doc_id in artifact metadata
         → Open in new tab / embed iframe
  → YES: Open existing doc
         → Changes auto-saved by Google
         → "Sync to SMAP" button → Pull content → Re-export PDF
```

> **Note:** Schema đã được cập nhật trong Section 3.2 (business.campaign_artifacts table).

```
Actor: Marketing Analyst / Content Planner / CMO
Entity Level: Campaign (Tầng 3)

Flow:
1. User tạo hoặc chọn Campaign:
   - Case 1 (Deep Dive): Campaign "Audit VinFast" → chỉ chứa Project VinFast
   - Case 2 (Compare): Campaign "VinFast vs BYD" → chứa cả 2 Projects

2. Campaign War Room auto-loads:
   - Aggregate data từ các Project con
   - Render: SoV Chart, Sentiment Battle, Aspect Heatmap

3. User tương tác với RAG Chat (Sidebar):
   - Hỏi câu hỏi bằng ngôn ngữ tự nhiên
   - Nhận Smart Suggestions dựa trên visual data
   - Yêu cầu generate reports

4. Knowledge Service xử lý:
   a. Lấy danh sách project_ids từ Campaign
   b. Build Qdrant filter: WHERE project_id IN (campaign.project_ids)
   c. Hybrid Search: Vector similarity + Sentiment/Aspect filter
   d. Generate answer với citations
   e. Nếu yêu cầu report: Generate → PDF → MinIO → Save metadata

5. User nhận:
   - Visual overview (Macro View) ngay lập tức
   - Câu trả lời chi tiết (Micro View) qua Chat
   - Artifacts có thể download/share/edit

6. User chỉnh sửa Artifact (Optional):
   a. Inline Edit: Click "Edit" → TipTap Editor → Save → Re-export PDF
   b. Google Docs: Click "Open in Docs" → Edit in Google → "Sync to SMAP"
   c. Version history được lưu lại cho audit trail

Query scope: WHERE project_id IN (SELECT project_id FROM campaign_projects WHERE campaign_id = ?)

Services involved:
- project-service (Campaign CRUD, Aggregation API, Artifacts metadata)
- knowledge-service (RAG engine, Report generation)
- MinIO (Artifacts storage)
```

### 5.4 Use Case → Entity → Service Mapping

```
┌─────────────────────────────────────────────────────────────────┐
│                USE CASE → ENTITY → SERVICE MAPPING              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  UC-01: Smart Data Onboarding                                   │
│  ├── Entity: Data Source (Tầng 1)                               │
│  ├── Primary Service: ingest-service                            │
│  ├── Supporting: analytics-pipeline (n8n), knowledge-service    │
│  ├── UX Features:                                               │
│  │   Crawl sources (FB, TikTok, YT): Dry-Run Preview           │
│  │   Passive sources (File, Webhook): AI Schema Mapping         │
│  └── Output: UAP records, Vector embeddings (with labels)       │
│                                                                 │
│  UC-02: Brand Health Monitoring                                 │
│  ├── Entity: Project (Tầng 2) — 1 Project = 1 Entity cụ thể    │
│  ├── Primary Service: project-service                           │
│  ├── Supporting: notification-service, analytics (read)         │
│  └── Scope: Single Project (entity), all Data Sources           │
│                                                                 │
│  UC-03: Campaign War Room (RAG + Visual)                        │
│  ├── Entity: Campaign (Tầng 3)                                  │
│  ├── Primary Service: knowledge-service, project-service        │
│  ├── UX Features: Visual Comparison, Smart Suggestions,         │
│  │                Artifacts Library                             │
│  └── Scope: Multiple Projects, Cross-brand comparison           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 Vector Indexing Strategy (Knowledge Hook)

**Quy tắc:** Data chỉ được đưa vào Qdrant SAU KHI đã có đủ labels từ Analytics Pipeline.

```
┌─────────────────────────────────────────────────────────────────┐
│                    VECTOR INDEXING FLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Ingest Service                                                 │
│       ↓ UAP (raw)                                               │
│  Kafka                                                          │
│       ↓                                                         │
│  n8n Analytics Pipeline                                         │
│       ↓ Sentiment Worker                                        │
│       ↓ Aspect Worker                                           │
│       ↓ Keyword Worker                                          │
│       ↓                                                         │
│  [CHECKPOINT: Has sentiment + aspects?]                         │
│       │                                                         │
│       ├── NO → Save to schema_analysis.* only (không index)           │
│       │                                                         │
│       └── YES → POST /knowledge/index                           │
│                    ↓                                            │
│                 Qdrant                                          │
│                 {                                               │
│                   content: "...",                               │
│                   sentiment: "NEGATIVE",                        │
│                   aspects: ["PIN", "SERVICE"],                  │
│                   project_id: "proj_xxx",                       │
│                   created_at_ts: 1707206400                     │
│                 }                                               │
│                                                                 │
│  Lợi ích: RAG có thể Hybrid Search                              │
│  - "Tìm comment tiêu cực về Pin" → filter sentiment + aspect    │
│  - "So sánh VinFast vs BYD về giá" → filter project + aspect    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.6 Operational Mechanics - Cơ chế Vận hành Thông minh

**Mục tiêu:** Chuyển đổi từ "Thu thập tĩnh" sang "Giám sát thích ứng" (Adaptive Monitoring).

#### 5.6.1 Reactive Dashboard (Dashboard Phản ứng Tức thì)

**Vấn đề:** Dashboard cần hiển thị dữ liệu "Live" mà không cần User reload trang.

**Giải pháp:** Event-Driven Update thay vì Polling

```
┌─────────────────────────────────────────────────────────────────┐
│                    REACTIVE DASHBOARD FLOW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Ingest Service                                                 │
│       │ (Hoàn tất xử lý file/batch)                             │
│       ↓                                                         │
│  Redis Pub/Sub ──── Event: DATA_READY ────►  Notification Svc   │
│                                                     │           │
│                                                     ↓           │
│                                              WebSocket Push     │
│                                                     │           │
│                                                     ↓           │
│                                              Browser (React)    │
│                                              ┌─────────────┐    │
│                                              │ React Query │    │
│                                              │ Stale-While │    │
│                                              │ -Revalidate │    │
│                                              └─────────────┘    │
│                                                     │           │
│                                                     ↓           │
│                                              Background Refetch │
│                                                     │           │
│                                                     ↓           │
│                                              Charts Auto-Update │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 5.6.2 Adaptive Frequency Crawling (Thu thập Thích ứng)

**Vấn đề:** Lịch trình cố định (15 phút/lần) gây lãng phí khi thấp điểm, phản ứng chậm khi khủng hoảng.

**Giải pháp:** Tần suất Crawl động dựa trên kết quả phân tích lần trước (Feedback Loop).

| Chế độ             | Tần suất     | Điều kiện kích hoạt                            |
| ------------------ | ------------ | ---------------------------------------------- |
| 💤 **Sleep Mode**  | 60-120 phút  | Tin mới < 5/giờ (thấp điểm)                    |
| 🚶 **Normal Mode** | 15-30 phút   | Số lượng tin ổn định                           |
| 🔥 **CRISIS MODE** | **1-3 phút** | Negative Ratio > 30% HOẶC Velocity tăng > 200% |

**Lợi ích:** Hệ thống tự động "sang số" - khi có "phốt", Dashboard cập nhật gần như Real-time.

#### 5.6.3 Crawl Profiles (Chiến lược Thu thập)

**Vấn đề:** Crawl mù quáng ("Crawl hết") gây lãng phí và nhiễu dữ liệu.

**Profile A: Initial Backfill (Khởi tạo)**

```yaml
purpose: Lấy dữ liệu nền cho Trend charts
sort_by: relevance | engagement
time_window: last_30_days
limit: 1000 items
frequency: ONE_TIME (khi tạo Project)
```

**Profile B: Incremental Monitor (Giám sát)**

```yaml
purpose: Bắt thảo luận MỚI NHẤT
sort_by: date | upload_date
time_window: since_last_crawl
strategy: DELTA_ONLY (chỉ lấy phần chênh lệch)
frequency: ADAPTIVE (theo Runtime Mode)
```

#### 5.6.4 Post-Fetch Filtering & Deduplication

**Vấn đề:** API MXH trả về dữ liệu cũ (viral content) lẫn vào dữ liệu mới.

**Quy trình lọc trong Ingest Service:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    POST-FETCH FILTERING                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  API Response (N items)                                         │
│       │                                                         │
│       ↓                                                         │
│  ┌─────────────────────────────────────────┐                    │
│  │ STEP 1: TIME CHECK                      │                    │
│  │ Compare content_created_at vs           │                    │
│  │ last_successful_crawl_time              │                    │
│  │                                         │                    │
│  │ IF older → SKIP (chỉ update metadata)   │                    │
│  │ IF newer → ACCEPT                       │                    │
│  └─────────────────────────────────────────┘                    │
│       │                                                         │
│       ↓ (Accepted items only)                                   │
│  ┌─────────────────────────────────────────┐                    │
│  │ STEP 2: DEDUPLICATION                   │                    │
│  │ Check external_id in Database           │                    │
│  │                                         │                    │
│  │ IF exists → SKIP (đã phân tích rồi)     │                    │
│  │ IF new → PROCESS                        │                    │
│  └─────────────────────────────────────────┘                    │
│       │                                                         │
│       ↓ (New items only)                                        │
│  Analytics Pipeline (n8n)                                       │
│                                                                 │
│  Kết quả: Chỉ phân tích dữ liệu MỚI và CHƯA XỬ LÝ               │
│           → Tiết kiệm chi phí AI                                │
│           → Không sai lệch thống kê                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Giá trị của Operational Mechanics:**

1. **Tiết kiệm:** Không crawl rác, không crawl lại cái cũ
2. **Nhanh nhạy:** Tự động tăng tốc khi có biến (Crisis Mode)
3. **Chính xác:** Dashboard hiển thị dữ liệu thực tế mới nhất

---

## 6. TIMELINE CHI TIẾT (12 TUẦN) - Updated với Entity Hierarchy

### Phase 1: Foundation (Tuần 1-4)

#### Tuần 1: Auth Service + Entity Hierarchy Setup

| Task                                           | Effort | Owner |
| ---------------------------------------------- | ------ | ----- |
| Setup Google OAuth2 integration                | 4h     | Dev   |
| **Implement JWT RS256 signing & validation**   | 4h     | Dev   |
| **Setup JWKS endpoint for public key**         | 2h     | Dev   |
| **Create shared JWT middleware package**       | 4h     | Dev   |
| **Add Redis blacklist check to middleware**    | 2h     | Dev   |
| **Google Groups integration (Directory API)**  | 4h     | Dev   |
| **Redis cache for Groups membership**          | 2h     | Dev   |
| Implement domain restriction                   | 2h     | Dev   |
| Implement role mapping từ config               | 4h     | Dev   |
| **Identity Provider abstraction (Interface)**  | 3h     | Dev   |
| **Flexible key loading (file/env/k8s)**        | 2h     | Dev   |
| **OAuth error handling & user-friendly pages** | 3h     | Dev   |
| **Audit log Kafka publisher (shared pkg)**     | 3h     | Dev   |
| **Audit log consumer in Auth Service**         | 3h     | Dev   |
| **Audit log retention policy & cleanup job**   | 2h     | Dev   |
| Create auth-config.yaml template               | 2h     | Dev   |
| **Create campaigns table (Tầng 3)**            | 2h     | Dev   |
| **Create campaign_projects table**             | 1h     | Dev   |
| Update Docker Compose                          | 2h     | Dev   |

**Deliverables:**

- Auth Service hoạt động với Google SSO
- JWT middleware package với blacklist check
- Identity Provider abstraction (dễ thêm Azure/Okta sau)
- Flexible key loading (file/env/k8s secrets)
- Audit log flow hoàn chỉnh (async via Kafka)

#### Tuần 2: Project Service + Ingest Service Setup

| Task                                      | Effort | Owner |
| ----------------------------------------- | ------ | ----- |
| Integrate auth-service với web-ui         | 4h     | Dev   |
| **Add Campaign CRUD to project-service**  | 4h     | Dev   |
| **Create ingest_db + data_sources table** | 2h     | Dev   |
| **Setup ingest-service skeleton**         | 4h     | Dev   |
| Delete identity_db (không cần nữa)        | 1h     | Dev   |
| Test auth flow end-to-end                 | 4h     | Dev   |

#### Tuần 3: File Upload + UAP Transformation

| Task                                  | Effort | Owner |
| ------------------------------------- | ------ | ----- |
| File upload endpoint (ingest-service) | 1d     | Dev   |
| Excel parser adapter                  | 1d     | Dev   |
| CSV/JSON parser adapter               | 4h     | Dev   |
| **UAP transformation logic**          | 4h     | Dev   |
| **UAP validation schema**             | 2h     | Dev   |
| Unit tests                            | 4h     | Dev   |

#### Tuần 4: AI Schema Agent (MVP)

| Task                                     | Effort | Owner |
| ---------------------------------------- | ------ | ----- |
| **AI Schema Agent Python sidecar**       | 1d     | Dev   |
| **LLM integration (OpenAI API)**         | 4h     | Dev   |
| **Schema suggestion prompt engineering** | 4h     | Dev   |
| Manual mapping UI (fallback)             | 4h     | Dev   |
| Integration test                         | 4h     | Dev   |

**Deliverable Phase 1:**

- Entity Hierarchy (Project + Campaign) hoạt động
- User có thể upload file và AI Schema Agent suggest mapping
- Data được transform thành UAP

---

### Phase 2: Core Features (Tuần 5-8)

#### Tuần 5: Analytics Service với UAP Input

| Task                                    | Effort | Owner |
| --------------------------------------- | ------ | ----- |
| **Update Analytics để nhận UAP input**  | 1d     | Dev   |
| Merge speech2text vào analytics-service | 4h     | Dev   |
| **Add source_id tracking**              | 2h     | Dev   |
| Update message queue routing            | 4h     | Dev   |
| Integration test                        | 4h     | Dev   |

#### Tuần 6: External Crawl API Integration

| Task                                | Effort | Owner |
| ----------------------------------- | ------ | ----- |
| External Crawl API client           | 1d     | Dev   |
| Define API contract với teammate    | 2h     | Dev   |
| **Crawl data → UAP transformation** | 4h     | Dev   |
| Webhook callback handler            | 4h     | Dev   |
| Error handling & retry              | 4h     | Dev   |

#### Tuần 7: Notification Service + Dashboard

| Task                                     | Effort | Owner |
| ---------------------------------------- | ------ | ----- |
| Rename websocket → notification-service  | 2h     | Dev   |
| Slack webhook integration                | 4h     | Dev   |
| Email alert integration                  | 4h     | Dev   |
| **Dashboard với Project scope (Tầng 2)** | 1d     | Dev   |
| **Data Source breakdown widget**         | 4h     | Dev   |

#### Tuần 8: Campaign Management UI

| Task                                  | Effort | Owner |
| ------------------------------------- | ------ | ----- |
| **Campaign CRUD UI**                  | 1d     | Dev   |
| **Add/Remove Projects to Campaign**   | 4h     | Dev   |
| **Campaign selector for RAG context** | 4h     | Dev   |
| Alert notification UI                 | 4h     | Dev   |

**Deliverable Phase 2:**

- Dashboard với Project scope (UC-02)
- Campaign management hoạt động
- External crawl integration ready

---

### Phase 3: RAG & Polish (Tuần 9-12)

#### Tuần 9: Knowledge Service Setup

| Task                               | Effort | Owner |
| ---------------------------------- | ------ | ----- |
| Qdrant setup (Docker)              | 2h     | Dev   |
| Embedding service (OpenAI)         | 4h     | Dev   |
| **Vector indexing với project_id** | 1d     | Dev   |
| Basic search API                   | 4h     | Dev   |

#### Tuần 10: Campaign-Scoped RAG

| Task                               | Effort | Owner |
| ---------------------------------- | ------ | ----- |
| LangChain integration              | 1d     | Dev   |
| **Campaign scope filter logic**    | 4h     | Dev   |
| **Cross-project comparison logic** | 4h     | Dev   |
| Citation extraction                | 4h     | Dev   |

#### Tuần 11: Chat UI + Integration

| Task                          | Effort | Owner |
| ----------------------------- | ------ | ----- |
| Chat interface (web-ui)       | 1d     | Dev   |
| **Campaign context selector** | 4h     | Dev   |
| Streaming response            | 4h     | Dev   |
| Chat history                  | 4h     | Dev   |
| End-to-end testing            | 4h     | Dev   |

#### Tuần 12: Helm Charts + Documentation + Security Hardening

| Task                                    | Effort | Owner |
| --------------------------------------- | ------ | ----- |
| Helm chart cho mỗi service              | 1d     | Dev   |
| values.yaml templates                   | 4h     | Dev   |
| **JWT Key Rotation implementation**     | 1d     | Dev   |
| **Multi-key JWKS endpoint**             | 2h     | Dev   |
| **Azure AD provider implementation**    | 4h     | Dev   |
| **Entity Hierarchy documentation**      | 4h     | Dev   |
| **UAP schema documentation**            | 2h     | Dev   |
| **Security enhancements documentation** | 2h     | Dev   |
| API documentation update                | 4h     | Dev   |
| Demo preparation                        | 4h     | Dev   |

**Deliverable Phase 3:**

- RAG Chatbot với Campaign scope (UC-03)
- Cross-project comparison hoạt động
- **JWT Key Rotation mechanism (automatic)**
- **Multi-provider support (Google + Azure AD)**
- Helm Charts ready

---

## 7. RISK MANAGEMENT

| Risk                        | Probability | Impact   | Mitigation                              |
| --------------------------- | ----------- | -------- | --------------------------------------- |
| LLM API cost cao            | Medium      | Medium   | Set budget limit, cache responses       |
| RAG accuracy thấp           | Medium      | High     | Tune prompts, add feedback loop         |
| Migration data loss         | Low         | Critical | Backup trước migrate, test kỹ           |
| Timeline trễ                | Medium      | Medium   | Buffer 1 tuần mỗi phase                 |
| Helm Charts phức tạp        | Low         | Low      | Dùng template có sẵn                    |
| **AI Schema Agent sai**     | Medium      | Medium   | User confirmation step, manual fallback |
| **Campaign scope phức tạp** | Low         | Medium   | Clear UI, validation rules              |
| **UAP schema evolution**    | Low         | Medium   | Versioning, backward compatibility      |
| **JWT key bị lộ**           | Low         | Critical | Key rotation, monitor access logs       |
| **Redis blacklist down**    | Low         | High     | Fallback to short token TTL (15m)       |
| **Identity provider down**  | Low         | Critical | Cache user info, graceful degradation   |

---

## 8. SUCCESS METRICS

| Metric                         | Target                 |
| ------------------------------ | ---------------------- |
| File upload success rate       | > 95%                  |
| **AI Schema mapping accuracy** | > 80% (với AI suggest) |
| **UAP transformation rate**    | > 99%                  |
| Alert latency                  | < 5 phút               |
| RAG answer relevance           | > 70% (user rating)    |
| **Campaign query performance** | < 2s (cross-project)   |
| Helm deployment time           | < 30 phút              |
| **JWT verification latency**   | < 5ms (with blacklist) |
| **Token revocation time**      | < 100ms (instant)      |
| **Key rotation downtime**      | 0s (zero-downtime)     |

---

## 9. APPENDIX

### A. Kafka Topics (Updated với Entity Hierarchy)

```
# Auth Service
audit.events # Audit log events từ tất cả services (NEW)

# Project Service
project.created
project.updated
project.deleted
campaign.created # NEW
campaign.updated # NEW
campaign.project.added # NEW
campaign.project.removed # NEW

# Ingest Service
ingest.source.created
ingest.file.uploaded
ingest.schema.suggested # AI Schema Agent output (FILE_UPLOAD + WEBHOOK)
ingest.schema.confirmed # User confirmed mapping
ingest.uap.ready # UAP records ready
ingest.crawl.requested
ingest.crawl.completed
ingest.dryrun.requested # Dry Run cho crawl sources (NEW)
ingest.dryrun.completed # Dry Run result (NEW)
ingest.external.received # Webhook data received (NEW)

# Analytics Service
analytics.uap.received # NEW - UAP input
analytics.sentiment.started
analytics.sentiment.completed
analytics.batch.completed
analytics.embedded # Vector ready for Qdrant

# Knowledge Service
knowledge.document.indexed
knowledge.query.received
knowledge.answer.generated

# Notification Service

notification.alert.triggered
notification.push.sent
notification.email.sent
notification.slack.sent

```

### B. API Endpoints (Updated với Entity Hierarchy)

```

# Auth Service

GET /auth/login # Redirect to Google OAuth
GET /auth/callback # OAuth callback
POST /auth/logout # Logout, clear session
GET /auth/me # Get current user info + role
GET /auth/validate # Validate token (internal)

# Project Service (Tầng 2 + Tầng 3)

POST /api/v1/projects # Create project {name, brand, entity_type, entity_name, description, industry}
GET /api/v1/projects # List projects (filter by brand, entity_type)
GET /api/v1/projects/:id # Get project details
PUT /api/v1/projects/:id # Update project
DELETE /api/v1/projects/:id # Delete project
GET /api/v1/projects/:id/dashboard # Get dashboard data

POST /api/v1/campaigns # Create campaign (NEW)
GET /api/v1/campaigns # List campaigns (NEW)
GET /api/v1/campaigns/:id # Get campaign details (NEW)
PUT /api/v1/campaigns/:id # Update campaign (NEW)
DELETE /api/v1/campaigns/:id # Delete campaign (NEW)
POST /api/v1/campaigns/:id/projects # Add project to campaign (NEW)
DELETE /api/v1/campaigns/:id/projects/:projectId # Remove project (NEW)

# Campaign Artifacts (NEW - Artifact Editing)
GET    /api/v1/campaigns/:id/artifacts           # List artifacts
GET    /api/v1/campaigns/:id/artifacts/:aid      # Get artifact details
PUT    /api/v1/campaigns/:id/artifacts/:aid      # Update artifact (inline edit)
DELETE /api/v1/campaigns/:id/artifacts/:aid      # Delete artifact
POST   /api/v1/campaigns/:id/artifacts/:aid/export  # Re-export to PDF
POST   /api/v1/campaigns/:id/artifacts/:aid/gdocs   # Create/Open Google Doc
POST   /api/v1/campaigns/:id/artifacts/:aid/sync    # Sync from Google Docs

# Ingest Service (Tầng 1)

POST /api/v1/sources # Create data source
GET /api/v1/sources # List sources (filter by project_id)
GET /api/v1/sources/:id # Get source details
POST /api/v1/sources/:id/upload # Upload file (FILE_UPLOAD)
POST /api/v1/sources/:id/upload-sample # Upload sample file for onboarding
POST /api/v1/sources/:id/crawl # Start crawl (Crawl sources)

POST /api/v1/sources/:id/schema/preview # AI schema suggestion (NEW - cho FILE_UPLOAD + WEBHOOK)
POST /api/v1/sources/:id/schema/confirm # Confirm mapping (NEW)

POST /api/v1/projects/:id/dry-run # Dry Run cho crawl sources (NEW)
GET /api/v1/projects/:id/dry-run/:dryrunId # Get dry run result (NEW)

POST /api/v1/projects/:id/activate # Activate project (NEW)

# Webhook endpoints
POST /api/v1/webhook/:path # Receive webhook data (external)
GET /api/v1/sources/:id/webhook # Get webhook URL + secret

# Analytics Service

GET /api/v1/analytics/summary # Get summary (filter by project_id)
GET /api/v1/analytics/aspects # Get aspect breakdown
GET /api/v1/analytics/trends # Get trends

# Knowledge Service (Campaign-scoped)

POST /api/v1/chat # Send message (with campaign_id)
GET /api/v1/chat/history # Get chat history
POST /api/v1/index # Index documents

# Notification Service

GET /ws # WebSocket connection
POST /api/v1/alerts/config # Configure alerts
POST /api/v1/alerts/trigger # Trigger alert (internal)
GET /api/v1/alerts/history # Alert history

```

### C. UAP Schema Reference (với Time Semantics)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Unified Analytics Payload (UAP)",
  "type": "object",
  "required": [
    "id",
    "project_id",
    "source_id",
    "content",
    "content_created_at",
    "ingested_at",
    "platform"
  ],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique identifier for this record"
    },
    "project_id": {
      "type": "string",
      "format": "uuid",
      "description": "Reference to Project (Tầng 2)"
    },
    "source_id": {
      "type": "string",
      "format": "uuid",
      "description": "Reference to Data Source (Tầng 1)"
    },
    "content": {
      "type": "string",
      "minLength": 1,
      "description": "Main text content for AI analysis (REQUIRED)"
    },
    "content_created_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 UTC - When content was originally created (BUSINESS TIME)"
    },
    "ingested_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 UTC - When SMAP ingested this record (SYSTEM TIME)"
    },
    "platform": {
      "type": "string",
      "enum": [
        "tiktok",
        "youtube",
        "facebook",
        "internal_excel",
        "internal_csv",
        "internal_json",
        "crm",
        "api"
      ],
      "description": "Source platform identifier"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": true,
      "description": "Schema-less additional fields for RAG",
      "properties": {
        "author": {
          "type": "string",
          "description": "Content author name"
        },
        "original_time_value": {
          "type": "string",
          "description": "Original time value before normalization (e.g., '2 giờ trước', '06/02/2026')"
        },
        "time_type": {
          "type": "string",
          "enum": ["absolute", "relative", "fallback"],
          "description": "How content_created_at was determined"
        },
        "source_timezone": {
          "type": "string",
          "description": "Original timezone of the source data (e.g., 'Asia/Ho_Chi_Minh')"
        }
      }
    }
  }
}
```

### C.1 Time Handling Rules (Quick Reference)

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIME HANDLING RULES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📌 STORAGE RULES                                               │
│  ├── ALL timestamps stored in UTC (ISO 8601)                    │
│  ├── PostgreSQL: TIMESTAMPTZ type                               │
│  ├── MongoDB: ISODate type                                      │
│  └── Qdrant: Unix Timestamp (Integer) for range filtering       │
│                                                                 │
│  📌 TWO TIME FIELDS (MANDATORY)                                 │
│  ├── content_created_at: When event HAPPENED (business)         │
│  └── ingested_at: When SMAP COLLECTED it (system)               │
│                                                                 │
│  📌 INPUT NORMALIZATION                                         │
│  ├── Absolute: "06/02/2026" → "2026-02-06T00:00:00Z"            │
│  ├── Relative: "2 giờ trước" → Calculate from ingested_at       │
│  └── Fallback: Unknown format → Use ingested_at as both         │
│                                                                 │
│  📌 DASHBOARD VISUALIZATION                                     │
│  ├── Client sends timezone: ?tz=Asia/Ho_Chi_Minh                │
│  └── Server aggregates: AT TIME ZONE 'Asia/Ho_Chi_Minh'         │
│                                                                 │
│  📌 ALERT LOGIC                                                 │
│  ├── Only alert if content_created_at within 24h window         │
│  └── Historical imports do NOT trigger crisis alerts            │
│                                                                 │
│  📌 RAG TEMPORAL QUERIES                                        │
│  ├── "tuần này" → Filter by content_created_at range            │
│  └── Pre-filter BEFORE vector search for accuracy               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. TURNKEY DEPLOYMENT STRATEGY (IaC)

**Phạm vi:** Quy trình đóng gói và cài đặt sản phẩm tại hạ tầng khách hàng (On-Premise).
**Công nghệ lõi:** Ansible (Provisioning), K3s (Orchestration), Helm (Package Management).

### 10.1 Triết lý: Infrastructure as Code (IaC)

Thay vì phương pháp thủ công (SSH vào từng server cấu hình), SMAP áp dụng mô hình **"Turnkey Solution" (Giải pháp Chìa khóa trao tay)**. Toàn bộ quy trình từ thiết lập OS, dựng Cluster đến deploy ứng dụng được tự động hóa 100% thông qua Code.

**Tại sao chọn K3s & Ansible?**

| Tool        | Lý do                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------- |
| **Ansible** | Agentless (chỉ cần SSH key), phù hợp để "xây móng nhà" (OS Tuning, Security, Containerd) |
| **K3s**     | Lightweight Kubernetes (< 100MB), chuẩn CNCF, phù hợp On-Premise tài nguyên hạn chế      |

### 10.2 Quy trình Cài đặt Tự động (Installation Pipeline)

Hệ thống cung cấp bộ cài `smap-installer` (`.tar.gz`). Khách hàng chỉ cần chạy: `./install.sh`

```
┌─────────────────────────────────────────────────────────────────┐
│                    INSTALLATION PIPELINE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TẦNG 1: INFRASTRUCTURE LAYER (Ansible)                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  • Check Environment (OS, RAM, CPU, Disk)               │    │
│  │  • OS Tuning (Swap off, Sysctl, Firewall)               │    │
│  │  • K3s Provisioning (Single/HA mode)                    │    │
│  │  • Install KEDA (Auto-scaling) + Longhorn (Storage)     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                    │
│  TẦNG 2: MIDDLEWARE LAYER (Helm Charts)                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  • PostgreSQL HA Cluster (Zalando Operator)             │    │
│  │  • Qdrant Vector DB Cluster                             │    │
│  │  • Kafka Message Queue Cluster                          │    │
│  │  • MinIO Object Storage                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                    │
│  TẦNG 3: APPLICATION LAYER (SMAP Services)                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  • Load Docker Images (Auth, Project, Ingest, Workers)  │    │
│  │  • Apply ConfigMaps/Secrets                             │    │
│  │  • Deploy Pods & Services via Helm                      │    │
│  │  • Health Check & Smoke Test                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 10.3 Chiến lược Air-Gapped (Offline Deployment)

Đối với khách hàng Doanh nghiệp/Ngân hàng yêu cầu bảo mật cao, không cho server kết nối Internet:

| Component         | Chiến lược Offline                                                   |
| ----------------- | -------------------------------------------------------------------- |
| **Docker Images** | `docker save` → `.tar` files, Ansible `ctr images import`            |
| **Helm Charts**   | Pre-download vào thư mục local                                       |
| **AI Models**     | PhoBERT/Whisper (Quantized) đóng gói sẵn, mount qua `HostPath`/`PVC` |
| **Dependencies**  | Bundled trong installer package                                      |

### 10.4 Cấu trúc Ops Repository

```
smap-ops/
├── inventory/              # File khai báo IP servers khách hàng
├── offline-assets/         # Docker Images & Models (cho bản Offline)
│   ├── images/             # *.tar files
│   └── models/             # PhoBERT, Whisper quantized
├── roles/                  # Ansible Roles
│   ├── common/             # OS hardening, dependencies
│   ├── k3s/                # Cài đặt K3s Cluster
│   ├── storage/            # Setup Longhorn/LocalPath
│   └── smap-app/           # Chạy Helm Install
├── charts/                 # Helm Charts của SMAP Services
│   ├── auth-service/
│   ├── project-service/
│   ├── ingest-service/
│   ├── analytics-pipeline/
│   ├── knowledge-service/
│   └── notification-service/
├── playbooks/
│   ├── install.yml         # Playbook cài mới
│   ├── update.yml          # Playbook nâng cấp version
│   └── backup.yml          # Playbook backup data
└── install.sh              # Wrapper script (User Interface)
```

### 10.5 Giá trị của IaC Deployment

| Aspect            | Benefit                                                        |
| ----------------- | -------------------------------------------------------------- |
| **Consistency**   | Loại bỏ lỗi cấu hình tay ("It works on my machine")            |
| **Security**      | Khách hàng kiểm soát qua code, không cần trao SSH root lâu dài |
| **Scalability**   | Thêm node mới = thêm IP vào inventory + chạy lại Ansible       |
| **Auditability**  | Mọi thay đổi được version control trong Git                    |
| **Repeatability** | Cài đặt N lần cho N khách hàng với kết quả giống nhau          |
