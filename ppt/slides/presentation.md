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
    font-size: 1.5em;
  }
  h2 {
    color: #2874a6;
    font-size: 1em;
  }
  h3 {
    color: #5dade2;
    font-size: 1em;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }
  .small {
    font-size: 0.8em;
  }
  table {
    font-size: 0.85em;
  }
  .note {
    background-color: #fef9e7;
    padding: 0.5rem;
    border-left: 4px solid #f1c40f;
    font-size: 0.75em;
    margin-top: 1rem;
  }
---

<!-- _class: lead -->
<!-- _paginate: false -->

![bg right:35% 80%](../../report/images/hcmut.png)

# **ĐỒ ÁN CHUYÊN NGÀNH**

## XÂY DỰNG HỆ THỐNG SMAP

### Social Media Analytics Platform

**GVHD:** ThS. Lê Đình Thuận

**Sinh viên thực hiện:**

- Nguyễn Tấn Tài – 2212990
- Đặng Quốc Phong – 2012049
- Nguyễn Chánh Tín – 2014749

_TP.HCM, Tháng 12/2024_

---

# Tóm tắt đề tài

<div class="columns">
<div>

## SMAP là gì?

**Social Media Analytics Platform**

Nền tảng thu thập và phân tích dữ liệu từ mạng xã hội (YouTube, TikTok)

**Thiết kế kiến trúc phần mềm**

- Microservices + Event-Driven
- Clean Architecture + DDD
- _Không phải nghiên cứu ML_

</div>
<div>

## Kết quả chính

| Hạng mục                     | Số lượng |
| ---------------------------- | -------- |
| Functional Requirements      | 47       |
| Non-Functional Requirements  | 31       |
| Microservices                | 10       |
| Sequence Diagrams            | 19       |
| Architecture Characteristics | 7        |

## Triển khai

Kubernetes On-premise
_(Roadmap: Hybrid AWS - Slide 17)_

</div>
</div>

---

# Thị trường Social Listening

<div class="columns">
<div>

| Quốc tế    | Việt Nam     |
| ---------- | ------------ |
| Talkwalker | Kompa        |
| YouScan    | Brandwatch   |
| Meltwater  | YouNet Media |
| Brandwatch | Buzzmetrics  |

</div>
<div>

## Vấn đề hiện tại

| Vấn đề              | Mô tả                   |
| ------------------- | ----------------------- |
| **Chi phí cao**     | $299 - $20,000/năm      |
| **Tiếng Việt**      | Xử lý NLP chưa tối ưu   |
| **Phụ thuộc**       | Không kiểm soát dữ liệu |
| **Thiếu linh hoạt** | Khó tùy chỉnh cho SME   |

**→ Cơ hội cho giải pháp hybrid on-premise, tùy chỉnh cao**

</div>
</div>

---

# Bài toán cần giải quyết

<div class="columns">
<div>

## Đặc điểm dữ liệu MXH

| Đặc điểm         | Mô tả                 |
| ---------------- | --------------------- |
| **Khổng lồ**     | Hàng triệu posts/ngày |
| **Phi cấu trúc** | Text, video, comments |
| **Real-time**    | Liên tục 24/7         |
| **Đa nguồn**     | YouTube, TikTok...    |

## Quy trình cần xây dựng

```
THU THẬP → PHÂN TÍCH → INSIGHT
(Crawling)  (Sentiment)  (Dashboard)
```

</div>
<div>

## Thách thức kỹ thuật

| Thách thức           | Yêu cầu                            |
| -------------------- | ---------------------------------- |
| **Scalability**      | Xử lý hàng nghìn videos đồng thời  |
| **Async Processing** | Long-running jobs (phút → giờ)     |
| **Fault-tolerant**   | Không mất dữ liệu khi service down |
| **Performance**      | Time-to-Insight nhanh              |

**→ Lý do chọn Microservices + Event-Driven**

</div>
</div>

---

# Mục tiêu & Phạm vi

<div class="columns">
<div>

Thiết kế kiến trúc phần mềm theo **4 phương pháp**:

1. **Microservices Architecture**
2. **Event-Driven Architecture**
3. **Clean Architecture** (4 layers)
4. **Domain-Driven Design**

| Primary (90%) | Target             |
| ------------- | ------------------ |
| Availability  | 99.5% uptime       |
| Performance   | API <500ms p95     |
| Scalability   | Horizontal scaling |

</div>
<div>

## Trong phạm vi

- YouTube, TikTok (dữ liệu công khai)
- API chính thức + Web Scraping
- Kubernetes On-premise
- **8 Use Cases** chính

## Ngoài phạm vi

- Facebook, Instagram (cần API riêng)
- Nghiên cứu ML chuyên sâu
- Cloud deployment _(xem Roadmap)_

</div>
</div>

---

# System Context (C4 Level 1)

![bg right:55% 90%](../../report/images/diagram/context-diagram.png)

## Actors chính

**Marketing Team**: Người dùng chính

- Cấu hình project, keywords
- Xem kết quả phân tích
- Xuất báo cáo

**SMAP System**
Nền tảng phân tích trung tâm

**Social Platforms**YouTube, TikTok - Nguồn dữ liệu

---

# Container Diagram - Tổng quan (C4 Level 2)

![bg right:50% 95%](../../report/images/diagram/container-diagram.png)

## 10 Application Services

**Polyglot Architecture**

| Stack           | Services                                             | Mục đích              |
| --------------- | ---------------------------------------------------- | --------------------- |
| **Golang** (4)  | Identity, Project, Collector, WebSocket              | High-performance APIs |
| **Python** (6)  | Analytics, Speech2Text, Scrapers, FFmpeg, Playwright | ML/AI & Scraping      |
| **Next.js** (1) | Web UI                                               | Dashboard             |

<div class="note">
Chi tiết từng nhóm services → Slide tiếp theo
</div>

---

<!--
NOTE: Slide này là phần 2 của Container Diagram
Do nội dung dài, tách thành 2 slides để dễ đọc
-->

# Container Diagram - Chi tiết Services

<div class="columns">
<div>

## Golang Services (4)

| Service       | Chức năng                        |
| ------------- | -------------------------------- |
| **Identity**  | JWT Auth, Users management       |
| **Project**   | CRUD projects, Config keywords   |
| **Collector** | Dispatch crawling jobs           |
| **WebSocket** | Real-time progress notifications |

Lý do chọn Go: High-performance, low latency APIs

</div>
<div>

## Python Services (6)

| Service             | Chức năng                            |
| ------------------- | ------------------------------------ |
| **Analytics**       | PhoBERT sentiment, Aspect extraction |
| **Speech2Text**     | Audio → Text (tiếng Việt)            |
| **YouTube Scraper** | API + Metadata crawling              |
| **TikTok Scraper**  | Playwright scraping                  |
| **FFmpeg**          | Video processing                     |
| **Playwright**      | Browser automation                   |

Lý do chọn Python: ML ecosystem, Scraping libraries

</div>
</div>

<div class="note">
Backup: Component Diagrams chi tiết cho từng service (Slide 20-23)
</div>

---

# Infrastructure Components

<div class="columns">
<div>

## Data Layer

| Component          | Mục đích                         |
| ------------------ | -------------------------------- |
| **PostgreSQL** (2) | Identity DB, Project DB          |
| **MongoDB**        | Collector - Flexible schema      |
| **MinIO**          | Object storage (videos, results) |
| **Redis**          | Caching + Pub/Sub                |

## Messaging Layer

| Component         | Mục đích                |
| ----------------- | ----------------------- |
| **RabbitMQ**      | Async job processing    |
| **Redis Pub/Sub** | Real-time notifications |

</div>
<div>

## Orchestration Layer

Kubernetes On-premise

| Feature           | Mô tả                |
| ----------------- | -------------------- |
| Auto-scaling      | HPA cho pods         |
| Load balancing    | Service mesh         |
| Rolling updates   | Zero-downtime deploy |
| Health checks     | Liveness + Readiness |
| Secret management | ConfigMaps, Secrets  |

<div class="note">
Backup: Deployment Diagram (Slide 26)
</div>

</div>
</div>

---

# Event-Driven Architecture - Message Flow

![bg right:45% 90%](../../report/images/data-flow/execute_project.png)

## Luồng xử lý chính

```
Project Service
      ↓ (publish)
   RabbitMQ
      ↓ (consume)
Collector Service
      ↓ (crawl)
  AI/ML Service
      ↓ (publish)
  Redis Pub/Sub
      ↓ (subscribe)
WebSocket Service
      ↓ (push)
    User
```

Toàn bộ quá trình là bất đồng bộ

<div class="note">
Chi tiết Claim-Check Pattern → Slide tiếp theo
</div>

---

<!--
NOTE: Slide này là phần 2 của Event-Driven Architecture
Tách riêng Claim-Check Pattern vì đây là điểm nhấn kỹ thuật quan trọng
-->

# Event-Driven Architecture - Claim-Check Pattern

<div class="columns">
<div>

## Vấn đề

Payload lớn (videos, transcripts, JSON results) không nên truyền qua message queue:

- Message size limit
- Network bottleneck
- Timeout issues

## Giải pháp: Claim-Check Pattern

```
Service A → MinIO (store data)
         → RabbitMQ (send object_id only)
                    ↓
Service B ← MinIO (retrieve by object_id)
         ← RabbitMQ (receive object_id)
```

</div>
<div>

## Luồng chi tiết

| Step | Action                                   |
| ---- | ---------------------------------------- |
| 1    | Service A lưu data vào **MinIO**         |
| 2    | Service A gửi **object_id** qua RabbitMQ |
| 3    | Service B nhận **object_id** từ queue    |
| 4    | Service B download data từ **MinIO**     |
| 5    | Service B xử lý data                     |

## Lợi ích

- Message queue nhẹ, nhanh
- Không bị bottleneck với large payloads
- Dễ retry (data đã persist)

</div>
</div>

---

# Tại sao chọn Microservices? (1/2)

![bg right:40% 95%](../../report/images/architecture/microservices_architecture.png)

## So sánh 3 kiến trúc

| Kiến trúc         | Điểm AHP    |
| ----------------- | ----------- |
| Monolithic        | 2.3/5.0     |
| Modular Monolith  | 3.5/5.0     |
| **Microservices** | **4.7/5.0** |

## Quyết định dựa trên AHP Matrix

Analytic Hierarchy Process - Phương pháp ra quyết định đa tiêu chí

<div class="note">
Chi tiết 3 lý do chính → Slide tiếp theo
</div>

---

<!--
NOTE: Slide này là phần 2 của "Tại sao chọn Microservices"
Tách riêng để giải thích chi tiết 3 lý do và Architecture Characteristics
-->

# Tại sao chọn Microservices? (2/2)

<div class="columns">
<div>

## 3 Lý do chính

1. Asymmetric Workload

- Crawler/Analytics cần nhiều resources
- Identity/Project cần ít resources
- → Scale riêng từng service

2. Polyglot Runtime

- Python: AI/ML (PhoBERT, scikit-learn)
- Go: High-performance APIs
- Next.js: Modern frontend
- → Monolithic không hỗ trợ

3. Fault Isolation

- Lỗi Crawler ≠ sập Identity/Project
- Eventual Consistency qua Saga Pattern
- Circuit Breaker cho external calls

</div>
<div>

## 7 Architecture Characteristics

| AC               | Target             | Priority  |
| ---------------- | ------------------ | --------- |
| **Availability** | 99.5% uptime       | Primary   |
| **Performance**  | <500ms p95         | Primary   |
| **Scalability**  | Horizontal         | Primary   |
| Maintainability  | Clean Arch         | Secondary |
| Testability      | Unit + Integration | Secondary |
| Security         | JWT + RBAC         | Secondary |
| Observability    | Logs + Metrics     | Secondary |

<div class="note">
Backup: NFR Radar Chart (Slide 25)
</div>

</div>
</div>

---

# Use Cases Overview

<div class="columns">
<div>

## 8 Use Cases chính

| UC    | Tên                | Mô tả                 |
| ----- | ------------------ | --------------------- |
| UC-01 | Cấu hình Project   | Tạo project, keywords |
| UC-02 | Dry-run từ khóa    | Test trước khi chạy   |
| UC-03 | Execute Project    | Khởi chạy thu thập    |
| UC-04 | Xem kết quả        | Dashboard analytics   |
| UC-05 | Liệt kê Projects   | List, filter, search  |
| UC-06 | Xuất báo cáo       | PDF, Excel, PPTX      |
| UC-07 | Phát hiện xu hướng | Auto trend detection  |
| UC-08 | Realtime Progress  | WebSocket tracking    |

</div>
<div>

## Đặc tả Use Case

Template: Cockburn format

- Main flow
- Alternative flows
- Pre/Post conditions
- Extensions

## Diagrams đã tạo

| Loại              | Số lượng |
| ----------------- | -------- |
| Activity Diagrams | 8        |
| Sequence Diagrams | 19       |

<div class="note">
Backup: Activity Diagrams (Slide 24)
</div>

</div>
</div>

---

# Data Pipeline - 4 Giai đoạn

![bg right:45% 90%](../../report/images/data-flow/analytics-pipeline.png)

## Luồng xử lý chính

```
CRAWLING → ANALYZING → AGGREGATING → FINALIZING
```

| Giai đoạn      | Service   | Công việc                 |
| -------------- | --------- | ------------------------- |
| 1. Crawling    | Collector | YouTube/TikTok → MinIO    |
| 2. Analyzing   | Analytics | PhoBERT Sentiment, Aspect |
| 3. Aggregating | Project   | Tổng hợp statistics       |
| 4. Finalizing  | Project   | Notify user (WebSocket)   |

## Thời gian xử lý (ước tính)

| Videos      | Thời gian   |
| ----------- | ----------- |
| 100 videos  | ~5-10 phút  |
| 1000 videos | ~30-60 phút |

---

# Sequence Diagram - Execute Project (UC-03)

![bg right:55% 95%](../../report/images/sequence/uc3_execute_part_1.png)

## Luồng xử lý UC-03

| Step | Action                          |
| ---- | ------------------------------- |
| 1    | User → Project Service          |
| 2    | Project → RabbitMQ (publish)    |
| 3    | Collector → Scraper (crawl)     |
| 4    | Scraper → MinIO (save)          |
| 5    | Analytics → Process (sentiment) |
| 6    | Project → WebSocket (notify)    |

Toàn bộ quá trình là bất đồng bộ

<div class="note">
UC-03 có 4 parts sequence diagram trong báo cáo
</div>

---

# Database Strategy

<div class="columns">
<div>

## Database-per-Service Pattern

| Database     | Service   | Loại       |
| ------------ | --------- | ---------- |
| Identity DB  | Identity  | PostgreSQL |
| Project DB   | Project   | PostgreSQL |
| Collector DB | Collector | MongoDB    |

## Design Patterns áp dụng

| Pattern           | Mục đích            |
| ----------------- | ------------------- |
| Soft Delete       | Không xóa vĩnh viễn |
| Optimized Indexes | Query performance   |
| Foreign Keys      | Data integrity      |

</div>
<div>

![width:450px](../../report/images/erd/project-erd.png)

## Eventual Consistency

- Saga Pattern cho distributed transactions
- Compensating transactions khi rollback
- Idempotent consumers tránh duplicate

<div class="note">
Backup: 3 ERD Diagrams chi tiết (Slide 27)
</div>

</div>
</div>

---

# Kết quả đạt được (1/2)

<div class="columns">
<div>

## Phân tích yêu cầu

| Hạng mục                     | Số lượng |
| ---------------------------- | -------- |
| Functional Requirements      | 47       |
| Non-Functional Requirements  | 31       |
| Business Rules               | 7        |
| Architecture Characteristics | 7        |
| Actors                       | 2        |

## Thiết kế kiến trúc

| Hạng mục           | Số lượng |
| ------------------ | -------- |
| Microservices      | 10       |
| Activity Diagrams  | 8        |
| Sequence Diagrams  | 19       |
| Component Diagrams | 7        |
| ERD Diagrams       | 3        |

</div>
<div>

## Hạ tầng Kubernetes

- Deployment manifests (10 services)
- ConfigMaps và Secrets
- Ingress configuration
- Horizontal Pod Autoscaler
- Health checks + Readiness probes

## Design Patterns

- Domain-Driven Design
- Clean Architecture (4 layers)
- Claim-Check Pattern
- Saga Pattern
- Master-Worker Pattern

</div>
</div>

<div class="note">
Chi tiết tài liệu bổ sung → Slide tiếp theo
</div>

---

<!--
NOTE: Slide này là phần 2 của "Kết quả đạt được"
Tách riêng để hiển thị tài liệu bổ sung và metrics
-->

# Kết quả đạt được (2/2)

<div class="columns">
<div>

## Tài liệu bổ sung

| Tài liệu            | Mô tả                         |
| ------------------- | ----------------------------- |
| Traceability Matrix | FR → Design mapping           |
| ADRs                | Architecture Decision Records |
| Gap Analysis        | Limitations & Future work     |
| API Documentation   | OpenAPI specs                 |

## Metrics đo lường

| Metric            | Target           |
| ----------------- | ---------------- |
| API Response Time | <500ms p95       |
| PhoBERT Inference | <100ms/text      |
| Availability      | 99.5% uptime     |
| Crawl Throughput  | 100 videos/10min |

</div>
<div>

## Tổng hợp con số

```
┌─────────────────────────────┐
│  47 FRs + 31 NFRs + 7 BRs   │
│  ─────────────────────────  │
│  10 Services (Polyglot)     │
│  19 Sequence Diagrams       │
│  8 Activity Diagrams        │
│  7 Component Diagrams       │
│  3 ERD Diagrams             │
│  ─────────────────────────  │
│  Full K8s Infrastructure    │
│  Clean Architecture         │
│  Event-Driven + DDD         │
└─────────────────────────────┘
```

</div>
</div>

---

# Demo - UI Screenshots

<div class="columns">
<div>

![width:400px](../../report/images/UI/landing.png)
_Landing Page_

![width:400px](../../report/images/UI/dryrun.png)
_Dry-run Keywords_

</div>
<div>

![width:400px](../../report/images/UI/char1.png)
_Analytics Dashboard_

![width:400px](../../report/images/UI/trend.png)
_Trend Detection_

</div>
</div>

<div class="note">
Thêm screenshots: cacprojects.png, char2.png, char3.png, char4.png
</div>

---

# Kế hoạch phát triển: Hybrid Architecture

<div class="columns">
<div>

## On-premise (Core Services)

| Component        | Lý do             |
| ---------------- | ----------------- |
| Identity Service | Dữ liệu nhạy cảm  |
| Project Service  | Business logic    |
| PostgreSQL       | ACID transactions |

Security & Compliance (GDPR)

## AWS Cloud (Scalable Services)

| Component         | AWS Service         |
| ----------------- | ------------------- |
| Scrapers          | Lambda (Serverless) |
| FFmpeg/Playwright | ECS Fargate         |
| Analytics         | Lambda + SQS        |

</div>
<div>

## Shared Infrastructure

| On-premise | AWS               |
| ---------- | ----------------- |
| MinIO      | S3                |
| RabbitMQ   | EventBridge + SQS |
| MongoDB    | DocumentDB        |
| Redis      | ElastiCache       |

## Lợi ích

- Cost Optimization: Pay-per-use
- Auto-scaling: Lambda 0 → ∞
- Managed Services: Giảm ops
- Security: Core data on-premise

</div>
</div>

<div class="note">
Timeline: Phase 1 (3-6 tháng) → Phase 2 (6-12 tháng) → Phase 3 (12+ tháng)
</div>

---

# Hạn chế hiện tại

<div class="columns">
<div>

## Hạn chế

| Hạng mục  | Mô tả                                     |
| --------- | ----------------------------------------- |
| Phạm vi   | Tập trung thiết kế, chưa implement đầy đủ |
| AI/ML     | Dùng pre-trained models (PhoBERT)         |
| Platforms | Chỉ YouTube, TikTok                       |
| Testing   | Rate-limit, Load test chưa thực hiện      |
| Docs      | User manual chưa hoàn thiện               |

</div>
<div>

## Hướng khắc phục

Ngắn hạn (3-6 tháng):

- Fine-tune models cho domain cụ thể
- Dashboard visualization nâng cao
- Export PDF, PPTX, Excel

Trung hạn (6-12 tháng):

- Thêm Facebook, Instagram, Twitter/X
- Competitor benchmarking
- Predictive analytics

Chi tiết: Slide 17 (Hybrid Architecture)

</div>
</div>

---

<!-- _class: lead -->

# Tổng kết

<div class="columns">
<div>

## Đã hoàn thành

Phân tích:

- 47 FRs + 31 NFRs + 7 BRs
- 8 Use Cases (Cockburn template)

Thiết kế:

- 10 Microservices (Polyglot)
- Event-Driven + Clean Architecture
- Database-per-Service + Claim-Check

Hạ tầng:

- Kubernetes manifests
- Auto-scaling + Health checks

</div>
<div>

## Giá trị mang lại

- Giải quyết vấn đề thực tế thị trường Social Listening
- Tiềm năng phát triển thành sản phẩm thương mại
- Kiến trúc mở rộng và bảo trì cao

## Tầm nhìn

Hybrid Architecture (On-premise + AWS)

- Core services: On-premise (Security)
- Scalable services: AWS Cloud (Cost)

</div>
</div>

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Cảm ơn Thầy và các bạn!

## Q & A

Nhóm sẵn sàng trả lời câu hỏi

---

<!-- _class: lead -->
<!-- _paginate: false -->

# BACKUP SLIDES

_Các slides bổ sung để trả lời câu hỏi chi tiết_

---

<!--
BACKUP SLIDE 20
Trigger: Khi được hỏi chi tiết về Identity Service
Related to: Slide 7 (Container Diagram)
-->

# Backup: Component Diagram - Identity Service

![bg contain](../../report/images/component/identity-component-diagram.png)

<div class="note">
Trigger từ Slide 7 (Container Diagram) khi được hỏi về Identity Service
</div>

---

<!--
BACKUP SLIDE 21
Trigger: Khi được hỏi chi tiết về Project Service
Related to: Slide 7 (Container Diagram)
-->

# Backup: Component Diagram - Project Service

![bg contain](../../report/images/component/project-component-diagram.png)

<div class="note">
Trigger từ Slide 7 (Container Diagram) khi được hỏi về Project Service
</div>

---

<!--
BACKUP SLIDE 22
Trigger: Khi được hỏi chi tiết về Collector Service
Related to: Slide 7 (Container Diagram)
-->

# Backup: Component Diagram - Collector Service

![bg contain](../../report/images/component/collector-component-diagram.png)

<div class="note">
Trigger từ Slide 7 (Container Diagram) khi được hỏi về Collector Service
</div>

---

<!--
BACKUP SLIDE 23
Trigger: Khi được hỏi chi tiết về Analytics Service
Related to: Slide 7 (Container Diagram), Slide 12 (Data Pipeline)
-->

# Backup: Component Diagram - Analytics Service

![bg contain](../../report/images/component/analytic-component-diagram.png)

<div class="note">
Trigger từ Slide 7, 12 khi được hỏi về Analytics/AI Service
</div>

---

<!--
BACKUP SLIDE 24
Trigger: Khi được hỏi chi tiết về Activity Diagrams
Related to: Slide 11 (Use Cases Overview)
-->

# Backup: Activity Diagram - Execute Project (UC-03)

![bg contain](../../report/images/activity/3.png)

<div class="note">
Trigger từ Slide 11 (Use Cases) khi được hỏi về luồng nghiệp vụ UC-03
</div>

---

<!--
BACKUP SLIDE 25
Trigger: Khi được hỏi về NFRs chi tiết
Related to: Slide 10 (Why Microservices), Slide 15 (Results)
-->

# Backup: NFR Radar Chart

![bg right:60% 90%](../../report/images/NFRs_rada_chart.png)

## Non-Functional Requirements

- 31 NFRs được định nghĩa
- Phân loại theo FURPS+
- Đo lường được (measurable)
- Có acceptance criteria

<div class="note">
Trigger từ Slide 10, 15 khi được hỏi về NFRs
</div>

---

<!--
BACKUP SLIDE 26
Trigger: Khi được hỏi về Kubernetes deployment
Related to: Slide 8 (Infrastructure)
-->

# Backup: Deployment Diagram

![bg contain](../../report/images/deploy/Diagram-deployment-diagram.drawio.png)

<div class="note">
Trigger từ Slide 8 (Infrastructure) khi được hỏi về K8s deployment
</div>

---

<!--
BACKUP SLIDE 27
Trigger: Khi được hỏi chi tiết về Database design
Related to: Slide 14 (Database Strategy)
-->

# Backup: ERD Diagrams

<div class="columns">
<div>

![width:450px](../../report/images/erd/identity-erd.png)
_Identity Database_

</div>
<div>

![width:450px](../../report/images/erd/analytic-erd.png)
_Analytics Schema_

</div>
</div>

<div class="note">
Trigger từ Slide 14 (Database Strategy) khi được hỏi về ERD chi tiết
</div>
