# SMAP System - Sequence Diagrams

> **Note**: Các sequence diagrams này được xây dựng dựa trên source code thực tế trong folder `services/`.

---

## Table of Contents

1. [UC-01: Cấu hình Project](#uc-01-cấu-hình-project)
2. [UC-02: Dry-run (Kiểm tra keywords)](#uc-02-dry-run-kiểm-tra-keywords)
3. [UC-03: Khởi chạy & Giám sát Project](#uc-03-khởi-chạy--giám-sát-project)
4. [UC-04: Xem kết quả & So sánh](#uc-04-xem-kết-quả--so-sánh)
5. [UC-05: Xuất báo cáo](#uc-05-xuất-báo-cáo)
6. [UC-06: Theo dõi tiến độ real-time (WebSocket)](#uc-06-theo-dõi-tiến-độ-real-time-websocket)
7. [UC-07: Phát hiện trend tự động](#uc-07-phát-hiện-trend-tự-động)
8. [UC-08: Phát hiện khủng hoảng](#uc-08-phát-hiện-khủng-hoảng)

---

## UC-01: Cấu hình Project

**Main Flow**: User tạo Project mới với brand và competitor keywords.

**Source**: `services/project/internal/project/usecase/project.go::Create()`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant ProjectAPI as Project Service
    participant PostgreSQL as PostgreSQL

    User->>WebUI: 1. Nhập thông tin Project<br/>(name, keywords, date range)
    WebUI->>ProjectAPI: 2. POST /projects<br/>{name, brand_keywords, competitor_keywords, ...}

    ProjectAPI->>ProjectAPI: 3. Validate date range
    ProjectAPI->>PostgreSQL: 4. INSERT INTO projects<br/>(status='draft', ...)
    PostgreSQL-->>ProjectAPI: Project created

    ProjectAPI-->>WebUI: 5. 201 Created<br/>{id, name, status: "draft"}
    WebUI-->>User: "Project đã được tạo thành công"
```

**Key Points**:

- Project status = `draft` sau khi tạo
- **NO Redis state**, **NO RabbitMQ event** được publish
- PostgreSQL lưu: project metadata, brand_keywords (JSONB), competitor_keywords (JSONB array)

---

## UC-02: Dry-run (Kiểm tra keywords)

**Main Flow**: User kiểm tra keywords trước khi chạy Project thật.

**Source**: `services/project/internal/project/usecase/project.go::DryRun()`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant ProjectAPI as Project Service
    participant RabbitMQ as RabbitMQ
    participant Collector as Collector Service
    participant Crawler as Crawler Services
    participant Analytics as Analytics Service

    User->>WebUI: 1. Click "Kiểm tra từ khóa"
    WebUI->>ProjectAPI: 2. POST /projects/dryrun<br/>{keywords, platform, date_range}

    ProjectAPI->>RabbitMQ: 3. Publish dryrun.created<br/>(sample: 5-10 items)
    ProjectAPI-->>WebUI: 202 Accepted

    RabbitMQ->>Collector: 4. Consume dryrun.created
    Collector->>Crawler: 5. Fetch sample items (1-2/keyword)
    Crawler-->>Collector: Sample data

    Collector->>RabbitMQ: 6. Publish data.collected
    RabbitMQ->>Analytics: 7. Consume & process<br/>(NLP pipeline)
    Analytics-->>Collector: Processing complete

    Collector->>ProjectAPI: 8. POST /internal/dryrun/callback
    WebUI->>ProjectAPI: 9. GET /dryrun/:id/results
    ProjectAPI-->>WebUI: Preview results
    WebUI-->>User: Hiển thị preview kết quả
```

**Key Points**:

- **Sampling strategy**: 1-2 items/keyword (total 5-10 items)
- **No project_id**: Dry-run tasks không gắn project_id
- **Callback mechanism**: Collector gọi webhook khi xong

---

## UC-03: Khởi chạy & Giám sát Project

**Main Flow**: User khởi chạy Project đã cấu hình và theo dõi tiến độ.

**Source**: `services/project/internal/project/usecase/project.go::Execute()`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant ProjectAPI as Project Service
    participant Redis as Redis
    participant RabbitMQ as RabbitMQ
    participant Collector as Collector Service
    participant Crawler as Crawler Services
    participant MinIO as MinIO
    participant Analytics as Analytics Service
    participant PostgreSQL as PostgreSQL

    %% ===== INITIALIZATION =====
    User->>WebUI: 1. Click "Khởi chạy"
    WebUI->>ProjectAPI: 2. POST /projects/:id/execute

    ProjectAPI->>PostgreSQL: 3. Verify ownership & update status='process'
    ProjectAPI->>Redis: 4. InitProjectState<br/>(status="INITIALIZING")
    ProjectAPI->>RabbitMQ: 5. Publish project.created
    ProjectAPI-->>WebUI: 200 OK

    %% ===== CRAWLING PHASE =====
    RabbitMQ->>Collector: 6. Consume project.created
    Collector->>Collector: 7. Generate job matrix<br/>(keywords × platforms × days)
    Collector->>Redis: 8. Update status="CRAWLING", total=120

    loop For each job
        Collector->>Crawler: 9. Dispatch crawl job
        Crawler-->>Collector: Batch (20-50 items)
        Collector->>MinIO: 10. Upload batch
        Collector->>RabbitMQ: 11. Publish data.collected
        Collector->>Redis: 12. HINCRBY done 1
    end

    %% ===== ANALYZING PHASE =====
    RabbitMQ->>Analytics: 13. Consume data.collected
    Analytics->>MinIO: 14. Download batch

    loop For each post
        Analytics->>Analytics: 15. Run NLP pipeline:<br/>(Preprocessing → Intent → Keyword → Sentiment → Impact)
    end

    Analytics->>PostgreSQL: 16. Batch INSERT post_analytics
    Analytics->>RabbitMQ: 17. Publish crisis.detected (if HIGH/CRITICAL)

    %% ===== COMPLETION =====
    Collector->>Redis: 18. Check done == total
    Collector->>Redis: 19. Update status="DONE"
    Collector->>ProjectAPI: 20. POST /internal/progress/callback
    ProjectAPI->>PostgreSQL: 21. UPDATE status='completed'

    WebUI->>ProjectAPI: 22. Polling GET /projects/:id/progress
    ProjectAPI-->>WebUI: {status:"DONE", progress:100%}
    WebUI-->>User: "Project hoàn tất!"
```

**Key Points**:

- **Transaction-like flow**: PostgreSQL → Redis → RabbitMQ (with rollback)
- **4 giai đoạn**: INITIALIZING → CRAWLING → PROCESSING → DONE
- **Redis state** (`smap:proj:{id}`) làm single source of truth cho progress
- **Batching**: Crawler upload 20-50 items/batch vào MinIO
- **Crisis detection**: Tự động trigger nếu CRISIS intent + high impact

---

## UC-04: Xem kết quả & So sánh

**Main Flow**: User xem dashboard với KPIs, sentiment trends, và so sánh đối thủ.

**Source**: `services/web-ui/pages/dashboard/project/[id].tsx`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant ProjectAPI as Project Service
    participant PostgreSQL as PostgreSQL

    User->>WebUI: 1. Navigate to Dashboard
    WebUI->>ProjectAPI: 2. GET /projects/:id
    ProjectAPI->>PostgreSQL: 3. Fetch project metadata
    ProjectAPI-->>WebUI: Project info

    WebUI->>ProjectAPI: 4. GET /projects/:id/stats
    ProjectAPI->>PostgreSQL: 5. Aggregated queries<br/>(COUNT, AVG, SUM by platform)
    ProjectAPI-->>WebUI: KPIs (total_posts, sentiment %, avg_impact)

    WebUI->>ProjectAPI: 6. GET /projects/:id/sentiment-trend
    ProjectAPI->>PostgreSQL: 7. Time-series query<br/>(GROUP BY date, sentiment)
    ProjectAPI-->>WebUI: Sentiment trend data

    WebUI->>ProjectAPI: 8. GET /projects/:id/aspects
    ProjectAPI->>PostgreSQL: 9. JSONB query<br/>(aspects_breakdown)
    ProjectAPI-->>WebUI: Aspect breakdown

    WebUI->>ProjectAPI: 10. GET /projects/:id/competitor-comparison
    ProjectAPI->>PostgreSQL: 11. GROUP BY keyword_source
    ProjectAPI-->>WebUI: Competitor stats

    WebUI-->>User: Dashboard đầy đủ:<br/>KPIs, charts, aspect breakdown, comparison
```

**Key Points**:

- **Aggregated queries**: GROUP BY, AVG(), COUNT() để tính KPIs
- **JSONB queries**: PostgreSQL JSONB operators để query aspect breakdown
- **Drilldown**: Click aspect → filter posts → view details

---

## UC-05: Xuất báo cáo

**Main Flow**: User xuất báo cáo dưới format PDF/PPTX/Excel.

**Source**: `services/web-ui/components/reports/ReportWizard.tsx`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant ReportAPI as Report Service
    participant PostgreSQL as PostgreSQL
    participant ReportEngine as Report Engine
    participant MinIO as MinIO

    User->>WebUI: 1. Chọn template, sections, format
    WebUI->>ReportAPI: 2. POST /reports/generate<br/>{project_id, template, format, ...}

    ReportAPI->>PostgreSQL: 3. INSERT INTO report_jobs<br/>(status='queued')
    ReportAPI-->>WebUI: 202 Accepted<br/>{report_id}

    Note over ReportEngine: Background worker picks up job

    ReportEngine->>PostgreSQL: 4. Fetch project data<br/>(KPIs, trends, aspects, ...)
    ReportEngine->>ReportEngine: 5. Generate report<br/>(PDF/PPTX/Excel)
    ReportEngine->>MinIO: 6. Upload report file
    ReportEngine->>PostgreSQL: 7. UPDATE status='completed'

    WebUI->>ReportAPI: 8. Polling GET /reports/:id/status
    ReportAPI-->>WebUI: {status:"completed", download_url}
    WebUI-->>User: "Báo cáo đã tạo xong!"<br/>[Tải xuống]
```

**Key Points**:

- **Async processing**: Report generation chạy background
- **Polling**: WebUI polls status mỗi 3s
- **Size limit**: File > 100MB → fail
- **MinIO pre-signed URL**: Download link có expiry 7 ngày

---

## UC-06: Theo dõi tiến độ real-time (WebSocket)

**Main Flow**: User kết nối WebSocket để nhận progress updates real-time.

**Source**: `services/websocket/internal/hub/hub.go`

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant WebUI as Web UI
    participant WSService as WebSocket Service
    participant Redis as Redis (Pub/Sub)
    participant ProjectAPI as Project Service
    participant Collector as Collector Service

    %% ===== CONNECTION =====
    User->>WebUI: 1. Navigate to Processing page
    WebUI->>WSService: 2. Connect WebSocket<br/>(ws://...?token={jwt})
    WSService->>WSService: 3. Validate JWT, register connection
    WSService->>Redis: 4. PSUBSCRIBE project:*:{user_id}
    WSService-->>WebUI: WebSocket established

    %% ===== PROGRESS UPDATES =====
    Collector->>Redis: 5. HINCRBY smap:proj:{id} done 1
    Collector->>ProjectAPI: 6. POST /internal/progress/callback<br/>(throttled: every 5s or 10%)

    ProjectAPI->>Redis: 7. PUBLISH project:{id}:{user_id}<br/>{type, progress, phases}
    Redis->>WSService: 8. Message received
    WSService->>WebUI: 9. Send WebSocket frame<br/>{progress, status}
    WebUI-->>User: Update progress bar

    %% ===== COMPLETION =====
    Collector->>ProjectAPI: 10. POST callback (status="DONE")
    ProjectAPI->>Redis: 11. PUBLISH project_completed
    Redis->>WSService: 12. Message
    WSService->>WebUI: 13. Send completion event
    WebUI-->>User: "Hoàn tất! Redirect sau 5s..."
```

**Key Points**:

- **Pattern subscription**: `project:*:{user_id}` để nhận tất cả projects
- **Throttling**: Collector chỉ gọi webhook mỗi 5s hoặc khi progress tăng 10%
- **Multi-connection**: 1 user có thể mở nhiều tabs

---

## UC-07: Phát hiện trend tự động

**Main Flow**: Cron job tự động thu thập và xếp hạng trends từ các platforms.

**Source**: `services/project/document/api.md` (Future feature)

```mermaid
sequenceDiagram
    autonumber
    participant Cron as Cron Job
    participant TrendService as Trend Service
    participant Crawler as Crawler Services
    participant PostgreSQL as PostgreSQL
    participant Redis as Redis
    participant User
    participant WebUI as Web UI

    %% ===== COLLECTION =====
    Cron->>TrendService: 1. Trigger (Daily 2:00 AM)
    TrendService->>PostgreSQL: 2. INSERT INTO trend_runs

    TrendService->>Crawler: 3. Request TikTok trends
    Crawler-->>TrendService: Trending music, hashtags, keywords

    TrendService->>Crawler: 4. Request YouTube trends
    Crawler-->>TrendService: Trending videos, topics

    %% ===== PROCESSING =====
    TrendService->>TrendService: 5. Normalize & calculate score:<br/>score = engagement_rate × velocity
    TrendService->>TrendService: 6. Rank trends (top 50/platform)

    TrendService->>PostgreSQL: 7. INSERT INTO trends<br/>(batch insert)
    TrendService->>PostgreSQL: 8. UPDATE trend_runs (status='COMPLETED')
    TrendService->>Redis: 9. SET trend:latest {run_id}

    %% ===== USER VIEWS =====
    User->>WebUI: 10. GET /trends
    WebUI->>TrendService: 11. GET /api/trends?run_id=latest
    TrendService->>PostgreSQL: 12. SELECT * FROM trends<br/>ORDER BY score DESC LIMIT 50
    TrendService-->>WebUI: Trends list
    WebUI-->>User: Display Trend Dashboard
```

**Key Points**:

- **Cron schedule**: Kubernetes CronJob chạy hàng ngày lúc 2:00 AM UTC
- **Score formula**: `engagement_rate × velocity`
- **Error handling**: Rate-limit → retry → skip platform → partial result
- **Cache**: Latest run_id được cache trong Redis (24h)

---

## UC-08: Phát hiện khủng hoảng

**Main Flow**: Hệ thống tự động phát hiện bài viết có nguy cơ khủng hoảng và cảnh báo user.

**Source**: `services/analytic/services/analytics/intent/intent_classifier.py`

```mermaid
sequenceDiagram
    autonumber
    participant Collector as Collector Service
    participant Analytics as Analytics Service
    participant PostgreSQL as PostgreSQL
    participant RabbitMQ as RabbitMQ
    participant WebSocket as WebSocket Service
    participant WebUI as Web UI
    participant User

    %% ===== DETECTION =====
    Collector->>RabbitMQ: 1. Publish data.collected
    RabbitMQ->>Analytics: 2. Consume data.collected
    Analytics->>Analytics: 3. Download batch from MinIO

    loop For each post
        Analytics->>Analytics: 4. Run NLP pipeline:<br/>- Preprocessing<br/>- Intent classification (CRISIS?)<br/>- Sentiment analysis (PhoBERT)<br/>- Impact calculation
    end

    Analytics->>PostgreSQL: 5. INSERT post_analytics<br/>(risk_level, impact_score)

    alt Risk Level = CRITICAL or HIGH
        Analytics->>RabbitMQ: 6. Publish crisis.detected<br/>{post_id, risk_level, impact_score, ...}
    end

    %% ===== ALERT =====
    RabbitMQ->>WebSocket: 7. Consume crisis.detected
    WebSocket->>Redis: 8. PUBLISH project:{id}:{user_id}
    Redis->>WebSocket: 9. Message
    WebSocket->>WebUI: 10. Send WebSocket frame
    WebUI-->>User: 🚨 "Phát hiện khủng hoảng: 1 bài viết nguy cơ cao"

    %% ===== USER VIEWS =====
    User->>WebUI: 11. Click "Xem chi tiết"
    WebUI->>ProjectAPI: 12. GET /projects/:id/crisis<br/>?risk_level=HIGH,CRITICAL
    ProjectAPI->>PostgreSQL: 13. SELECT * FROM post_analytics<br/>WHERE primary_intent='CRISIS'<br/>AND risk_level IN ('HIGH','CRITICAL')
    ProjectAPI-->>WebUI: Crisis posts list
    WebUI-->>User: Crisis Dashboard
```

**Key Points**:

- **Triple check**: Intent=CRISIS + Sentiment=VERY_NEGATIVE + Impact=HIGH/CRITICAL
- **Impact formula**: engagement × 0.3 + reach × 0.3 + sentiment × 0.2 + velocity × 0.2
- **Risk levels**: CRITICAL (>80), HIGH (60-80), MEDIUM (40-60), LOW (<40)
- **Real-time alert**: Qua WebSocket, user nhận ngay khi phát hiện

---

## Summary

Tổng cộng **8 sequence diagrams** đã được tạo, bao phủ toàn bộ 8 Use Cases:

| Use Case                     | Độ phức tạp | Số participants | Highlights                                           |
| ---------------------------- | ----------- | --------------- | ---------------------------------------------------- |
| UC-01: Cấu hình Project      | Medium      | 4               | PostgreSQL only, no events                           |
| UC-02: Dry-run               | Medium      | 7               | Sampling strategy, async callback                    |
| UC-03: Khởi chạy & Giám sát  | **High**    | 9               | 4 phases, Redis state, event-driven, rollback        |
| UC-04: Xem kết quả           | Medium      | 3               | Aggregation queries, JSONB, drilldown                |
| UC-05: Xuất báo cáo          | Medium      | 6               | Async processing, multi-format, MinIO pre-signed URL |
| UC-06: WebSocket Progress    | High        | 6               | Pub/Sub, throttling, multi-connection                |
| UC-07: Phát hiện trend       | Medium      | 7               | Cron job, score formula, partial results             |
| UC-08: Phát hiện khủng hoảng | **High**    | 7               | NLP pipeline, crisis detection logic                 |

**Những diagrams này được xây dựng dựa trên:**

- Source code thực tế trong folder `services/`
- API contracts (REST, RabbitMQ events, Redis Pub/Sub)
- Database schemas (PostgreSQL, Redis)
- Documentation files (architecture.md, event-drivent.md, api.md)

**Lưu ý khi chuyển sang Typst:**

- Mermaid không được hỗ trợ trực tiếp trong Typst
- Cần export các diagrams sang PNG/SVG bằng Mermaid CLI hoặc online tools
- Hoặc sử dụng PlantUML nếu Typst có plugin hỗ trợ
