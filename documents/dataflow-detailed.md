# SMAP Data Flow Specification v3.0 (Component-Level)

**Ngày cập nhật:** 20/02/2026  
**Trọng tâm:** Chi tiết hóa luồng dữ liệu qua từng **Process/Unit** cụ thể, dựa trên Kiến trúc Đồng nhất UAP và Entity Hierarchy mới.

---

## 1. TỔNG QUAN KIẾN TRÚC

```mermaid
flowchart TD
    subgraph Client["CLIENT"]
        UI[Web UI - Next.js]
    end

    subgraph Core["CORE SERVICES"]
        subgraph Auth["Auth Service"]
            AU[auth-api]
        end
        subgraph Project["Project Service"]
            PA[project-api]
            PS[project-scheduler]
        end
        subgraph Ingest["Ingest Service"]
            IA[ingest-api]
            IW[ingest-worker]
            IC[ingest-cron]
        end
        subgraph Analytics["Analytics Service"]
            AA[analytics-consumer]
        end
        subgraph Knowledge["Knowledge Service"]
            KA[know-api]
            KI[know-indexer]
        end
        subgraph Notification["Notification Service"]
            NH[noti-hub - WebSocket]
        end
    end

    subgraph Processing["AI WORKERS (Python)"]
        WS[py-worker-sentiment]
        WA[py-worker-aspect]
        WK[py-worker-keyword]
    end

    subgraph Data["DATA"]
        PG[(PostgreSQL - 4 Schemas)]
        Qdrant[(Qdrant Vector DB)]
        MinIO[(MinIO Object Storage)]
        Redis[(Redis Cache/PubSub)]
    end

    UI -->|REST| IA & PA & KA & AU
    UI <-->|WebSocket| NH

    IA --> MinIO
    IA --> IW
    IC --> IW
    IW --> Kafka[(Kafka)]

    Kafka --> AA
    AA -->|HTTP/gRPC| WS & WA & WK
    AA --> PG
    AA -->|DATA_READY| Redis
    AA -->|knowledge.index| Kafka

    Kafka --> KI
    KI --> Qdrant
    KA --> Qdrant & PG

    PS -->|Crawl Cmd| IA

    Redis --> NH
```

---

## 2. ĐỊNH NGHĨA CÁC ĐƠN VỊ XỬ LÝ (CORE UNITS)

| Service | Unit | Loại | Nhiệm vụ |
| --- | --- | --- | --- |
| **Auth** | `auth-api` | HTTP Server | Xử lý SSO, quản lý User, roles, JWT |
| **Project** | `project-api` | HTTP Server | Quản lý Campaign/Project, Dashboard, Crisis Config |
| | `project-scheduler` | Cron/Worker | Đánh giá Khủng hoảng, quyết định Adaptive Crawl |
| **Ingest** | `ingest-api` | HTTP Server | Nhận file upload, webhook, config data source, trigger AI Schema Mapping |
| | `ingest-worker` | Consumer | Parse file, gọi External API, transform sang UAP |
| | `ingest-cron` | Scheduler | Trigger crawl định kỳ dựa theo Crawl Mode |
| **Analytics** | `analytics-consumer`| Go Orchestrator | Điều phối luồng xử lý AI, phân luồng ghi DB |
| | `py-worker-sentiment`| Micro-service | Chạy Model Sentiment |
| | `py-worker-aspect` | Micro-service | Chạy Model Aspect Extraction |
| | `py-worker-keyword` | Micro-service | Chạy Model Keyword Extraction |
| **Knowledge** | `know-api` | HTTP Server | Phục vụ Chat RAG, báo cáo tự động |
| | `know-indexer` | Consumer | Nhúng (Embed) văn bản → Upsert vào Qdrant |
| **Notification**| `noti-hub` | WebSocket | Đẩy events Realtime (Alerts, Metrics update) |

---

## 3. FLOW 0: TẠO CAMPAIGN & PROJECT (ENTITY HIERARCHY)

> **Thiết kế mới:** Dữ liệu được tổ chức theo cấu trúc `Campaign` (Tầng 3) → `Project` (Tầng 2) → `Data Source` (Tầng 1).
> **UI Pattern:** Wizard tạo Project (Tầng 2 & 1) sử dụng **Popup/Modal Window**. Nếu user đóng giữa chừng, Project lưu ở trạng thái `DRAFT`.

### 3.1 Khởi tạo Project (Bước 1)

```mermaid
sequenceDiagram
    participant User as User
    participant UI as Web UI
    participant API as project-api
    participant DB as Postgres

    User->>UI: 1. Click "Tạo Project mới"
    UI->>UI: 2. Mở Popup Wizard (Step 1)
    User->>UI: 3. Điền {name, brand, entity_type, entity_name}
    UI->>API: 4. POST /projects
    API->>DB: 5. INSERT projects (status=DRAFT)
    DB-->>API: project_id
    API-->>UI: 201 Created {project_id}
```

### 3.2 Thêm & Cấu hình Data Source (Bước 2)

> **Phân loại Source:**
>
> - **Crawl Sources** (FB, TikTok, YT): Hệ thống đi lấy → Cần **Dry Run**.
> - **Passive Sources** (Webhook, File): Dữ liệu đẩy vào → Cần **AI Schema Mapping** (Onboarding).

```mermaid
sequenceDiagram
    participant User as User
    participant UI as Web UI
    participant P_API as project-api
    participant I_API as ingest-api
    participant MinIO as MinIO
    participant DB as Postgres

    UI->>UI: 1. Danh sách Types [FILE_UPLOAD, WEBHOOK, FACEBOOK, TIKTOK...]
    User->>UI: 2. Chọn Source Type

    alt Crawl (FB, TikTok, YT)
        UI->>User: Form nhập Config (page_id, keywords...)
        User->>UI: Submit
        UI->>I_API: POST /sources
    else Passive: WEBHOOK
        UI->>User: Form define `payload_schema` JSON
        User->>UI: Submit
        UI->>I_API: POST /sources
    else Passive: FILE_UPLOAD
        UI->>User: Drag & Drop khu vực Upload File Mẫu
        User->>UI: Upload "sample.xlsx"
        UI->>I_API: POST /sources/upload-sample
        I_API->>MinIO: Save to /temp/
        MinIO-->>I_API: file_path
        I_API->>DB: INSERT data_sources (status=PENDING)
    end
```

### 3.3 DATA ONBOARDING - AI Schema Mapping (Bước 3)

> Chỉ áp dụng cho Passive Sources. API gọi LLM đồng bộ (synchronous) để gợi ý mapping.

```mermaid
sequenceDiagram
    participant UI as Web UI
    participant API as ingest-api
    participant LLM as LLM
    participant DB as Postgres

    par Song song cho từng Passive Source
        UI->>API: 1. POST /sources/{id}/schema/preview
        API->>LLM: 2. Gửi Sample File Header / Payload Schema
        LLM-->>API: 3. Gợi ý Mapping sang chuẩn UAP
        API-->>UI: 4. Preview Data (Cột gốc -> UAP -> Data mẫu)
    end

    User->>UI: 5. Chỉnh sửa & Xác nhận
    UI->>API: 6. POST /sources/{id}/schema/confirm
    API->>DB: 7. UPDATE mapping_rules, onboarding_status=CONFIRMED
```

### 3.4 DRY RUN - Chạy thử (Bước 4)

> Chỉ áp dụng cho Crawl Sources. Thực hiện Bất đồng bộ qua Kafka để không treo UI.

```mermaid
sequenceDiagram
    participant UI as Web UI
    participant Kafka as Kafka
    participant Worker as ingest-worker
    participant DB as Postgres

    UI->>Kafka: 1. Push [project.dryrun.requested]
    Kafka->>Worker: 2. Consume (mode=DRYRUN)

    par Fetch
        Worker->>Worker: 3. Test Connection + Lấy 5 items mới nhất
    end

    Worker->>DB: 4. Lưu dryrun_results
    Worker->>Kafka: 5. Push [project.dryrun.completed]
    UI->>User: 6. Hiển thị Kết quả mẫu
```

### 3.5 ACTIVATE (Bước 5)

Điều kiện: Onboarding `CONFIRMED` và Dry Run `SUCCESS/WARNING`. Chuyển Project sang `ACTIVE`.

---

## 4. FLOW 1: XỬ LÝ DỮ LIỆU ĐẦU VÀO (INGESTION)

Dữ liệu đầu vào đều quy về một cấu trúc vật lý chung: **Unified Analytics Payload (UAP)**. Tất cả nguồn (File, Webhook, Crawl) đều kết thúc bằng việc đẩy UAP vào `Kafka`.

### 4.1 File Upload (Batch Processing)

1. Tầng `ingest-api` nhận file, ném lên MinIO, tạo Job rỗng vào DB. Đẩy sự kiện Kafka.
2. Tầng `ingest-worker` tiêu thụ Kafka, kéo file dạng stream từ MinIO.
3. `ingest-worker` áp dụng `mapping_rules` (đã duyệt ở bước 3.3).
4. `ingest-worker` gửi từng Batch UAP vào topic `analytics.uap.received`.

### 4.2 Webhook (Push)

1. External Service gọi POST vào Endpoint webhook sinh bởi API hệ thống.
2. `ingest-api` Verify Signature (SYNC), Validate Schema.
3. Nếu hợp lệ, push Event vào Kafka `ingest.external.received`.
4. `ingest-worker` lấy lô dữ liệu, Dedup, Transform theo quy tắc Mapping. Đẩy sang `analytics.uap.received`.

### 4.3 Scheduled Crawl (Pull)

1. `ingest-cron` chạy, kiểm tra các Crawl Source tới lịch hẹn `next_crawl_at`.
2. Gửi job vào `ingest.crawl.scheduled`.
3. `ingest-worker` consume, gọi qua các MMO API lấy data.
4. Xử lý Time Check (Bỏ qua bài cũ), Dedup. Transform sang chuẩn UAP và bắn sang topic.

---

## 5. FLOW 2: ORCHESTRATION PHÂN TÍCH (ANALYTICS PIPELINE)

> **Thay đổi Lõi:** Bỏ hoàn toàn `n8n` để giảm Overhead. Thay bằng `analytics-consumer` viết bằng **Go** để tối ưu hóa Multi-threading, Batching và quản lý kết nối CSDL (Postgres).

```mermaid
sequenceDiagram
    participant Kafka as Kafka
    participant Orchestrator as analytics-consumer (Go)
    participant PyWorker as AI Workers (Python)
    participant PG as Postgres
    participant Redis as Redis
    
    Kafka->>Orchestrator: 1. Consume M UAP items/batch
    
    Orchestrator->>PyWorker: 2. POST /analyze/sentiment (Batch)
    PyWorker-->>Orchestrator: [Sentiments]
    
    par For Negative/Neutral items
        Orchestrator->>PyWorker: 3a. POST /analyze/aspect
    and For all items
        Orchestrator->>PyWorker: 3b. POST /extract/keywords
    end
    
    PyWorker-->>Orchestrator: All Results
    
    Orchestrator->>PG: 4. BULK INSERT analytics_post_analytics
    
    par Async Noti
        Orchestrator->>Redis: 5. Publish "DATA_READY"
    and Quality Gate Indexing
        Orchestrator->>Kafka: 6. Push UAP (đã gán nhãn) -> knowledge.index
    end
```

---

## 6. FLOW 3: TRIFATE CRAWL & CRISIS KHỦNG HOẢNG (ADAPTIVE CRAWL)

Sự phân tách trách nhiệm rõ ràng ở hệ thống mới: **Project Service** (đóng vai **Bộ Não** Orchestrator cấp Domain) đưa ra quyết định dựa trên số liệu từ **Analytics**, sau đó truyền mệnh lệnh cho **Ingest Service** (đóng vai **Tay Chân** Executor).

```mermaid
sequenceDiagram
    participant AS as Analytics
    participant Kafka
    participant PS as Project Service (Scheduler)
    participant IS as Ingest Service
    participant NH as Notification Hub

    loop Every 5 mins
        AS->>Kafka: 1. Publish [analytics.metrics.aggregated]
        Kafka-->>PS: 2. PS Consume Metrics
        PS->>PS: 3. Đánh giá ngưỡng Crisis (Thresholds VD: Negative > 30%)
        
        alt Khủng hoảng xảy ra (Crisis)
            PS->>Kafka: 4. Publish [project.crisis.started]
            Kafka->>NH: 5. Gửi cảnh báo SMS/Email/Slack
            PS->>IS: 6. PUT /sources/{id}/crawl-mode (CRISIS: 2 mins)
        else Số liệu thấp điểm
            PS->>IS: PUT /sources/{id}/crawl-mode (SLEEP: 60 mins)
        else Bình thường
            PS->>IS: PUT /sources/{id}/crawl-mode (NORMAL: 15 mins)
        end
    end
```

---

## 7. FLOW 4: KNOWLEDGE (RAG VÀ VECTORD DB)

### 7.1 Indexing (Chỉ đẩy data "có giá trị")

`know-indexer` tiêu thụ Topic `knowledge.index` (Topic này chỉ được ghi vào bởi Analytics Pipeline sau quá trình Quality Filter). `know-indexer` bắn HTTP tới OpenAI Embeddings lấy Vector và Upsert cùng MetaData (để filter) vào Qdrant.

### 7.2 The Campaign War Room - Chat Query (Cross-Project Comparison)

Giao diện Chat ở quy mô **Campaign (Tầng 3)**. User có thể gộp nhiều `Project (Tầng 2)` vào 1 chiến dịch. Từ đó, Chat truy vấn chéo.

```mermaid
sequenceDiagram
    participant User as User
    participant API as know-api
    participant Qdrant as Qdrant
    participant DB as Postgres
    participant LLM as OpenAI

    User->>API: 1. "So sánh ưu nhược điểm VF8 (Project A) và VF9 (Project B)?"

    par Vector Search
        API->>Qdrant: 2. Hybrid Search (Vector + Filter: project_id IN [A, B])
    and Aggregate Stats
        API->>DB: 2a. Lấy Sentiment distribution của A và B
    end

    Qdrant-->>API: Relevant chunks
    DB-->>API: Statistical data
    API->>LLM: 3. Build Prompt + Cung cấp báo cáo số liệu & chunk text
    LLM-->>API: Answer
    API-->>User: 4. Stream response + Citations
```

### 7.3 Generative Báo Cáo

LLM tạo Dashboard báo cáo tự động (Campaign Artifacts). Báo cáo sinh ra được lưu tĩnh trên `MinIO` dưới dạng Markdown/PDF. Các Báo cáo này có the Inline-edited trực tiếp bởi Analyst trên Web UI.

---

## 8. DANH SÁCH KAFKA TOPIC TOÀN CỤC

| Topic | Producer | Consumer | Nhiệm vụ |
| --- | --- | --- | --- |
| `audit.events` | Mọi Service | auth-service | Nhật ký hệ thống |
| `project.created` <br> `project.updated` <br> `project.deleted` | project-api | Các Service (tùy vào luồng) | Đồng bộ trạng thái Project |
| `campaign.*` | project-api | know-api | Quản lý Campaign |
| `ingest.file.uploaded` | ingest-api | ingest-worker | Xử lý File |
| `ingest.schema.*` | ingest-api | Frontend | Schema Suggestion |
| `ingest.external.received` | ingest-api (webhook) | ingest-worker | Xử lý Webhook Payload |
| `ingest.crawl.scheduled` | ingest-cron | ingest-worker | Kích hoạt Tool Crawl |
| `analytics.uap.received` | ingest-worker | analytics-consumer | Truyền UAP cần phân tích |
| `analytics.metrics.aggregated` <br> `analytics.insights.aggregated`| analytics | project-scheduler | Tổng hợp số liệu định kỳ |
| `knowledge.index` | analytics-consumer | know-indexer | Data sạch đi Indexing |
| `project.crisis.*` | project-scheduler | noti-hub | Loa báo động Khủng hoảng |
| `notification.*.sent` | Các Core Service | noti-hub | Lệnh Push Notification |

---

## 9. CẤU TRÚC UNIFIED ANALYTICS PAYLOAD (UAP)

Bộ khung dữ liệu đi khắp hệ thống:

```json
{
  "id": "uuid-v4",
  "project_id": "proj_vf8",
  "source_id": "src_tiktok_1",
  "content": "Xe đi êm nhưng pin sụt nhanh",
  "content_created_at": "2026-02-06T01:00:00Z",
  "ingested_at": "2026-02-07T10:00:00Z",
  "platform": "tiktok",
  "metadata": { 
      "author": "Nguyễn A", 
      "time_type": "absolute" 
  }
}
```

**Nguyên tắc Thời gian:** Hệ thống ưu tiên truy vấn trên Dashboard bằng trường `content_created_at` (Lúc sự kiện diễn ra). Hệ thống tracking độ trễ bằng `ingested_at` (Lúc SMAP thu thập được). Cả 2 đều dùng định dạng chuẩn quốc tế UTC.

---

**[End of Data Flow Specification]**
