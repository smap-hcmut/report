# KẾ HOẠCH THUYẾT TRÌNH ĐỒ ÁN SMAP (CẢI THIỆN)

## Social Media Analytics Platform

### Thời lượng: 20 phút

---

## TỔNG QUAN CẤU TRÚC THUYẾT TRÌNH

| Phần | Nội dung            | Thời gian | Slide |
| ---- | ------------------- | --------- | ----- |
| 1    | Mở đầu & Giới thiệu | 1.5 phút  | 1-2   |
| 2    | Bối cảnh & Vấn đề   | 2 phút    | 3-4   |
| 3    | Mục tiêu & Phạm vi  | 1.5 phút  | 5     |
| 4    | Kiến trúc tổng quan | 6 phút    | 6-10  |
| 5    | Luồng xử lý chính   | 5 phút    | 11-14 |
| 6    | Kết quả đạt được    | 1.5 phút  | 15-16 |
| 7    | Kế hoạch phát triển | 1 phút    | 17    |
| 8    | Kết luận            | 1.5 phút  | 18-19 |

> **Lưu ý**: Với 20 phút, chỉ nên có 15-18 slides. Mỗi slide ~1 phút, không nên nhồi nhét quá nhiều.

---

## CHI TIẾT TỪNG PHẦN

### PHẦN 1: MỞ ĐẦU (1.5 phút)

**Slide 1: Trang bìa**

- Tên đề tài: "Xây dựng hệ thống SMAP – Social Media Analytics Platform"
- Sinh viên: Nguyễn Tấn Tài, Đặng Quốc Phong, Nguyễn Chánh Tín
- GVHD: Thầy Lê Đình Thuận

**Slide 2: Tóm tắt đề tài (30 giây)**

- SMAP = Nền tảng phân tích dữ liệu mạng xã hội
- Trọng tâm: **Thiết kế kiến trúc phần mềm** (không phải ML)
- Kết quả: Bộ thiết kế + hạ tầng Kubernetes
- **Hook**: Giải pháp thay thế cho các công cụ đắt đỏ trên thị trường

---

### PHẦN 2: BỐI CẢNH & VẤN ĐỀ (2 phút)

**Slide 3: Thị trường Social Listening**

- **Việt Nam**: YouNet (SocialHeat, Buzzmetrics), Reputa, Kompa
- **Quốc tế**: Talkwalker, YouScan, Meltwater
- **Vấn đề**:
  - Chi phí cao (\$299-\$20,000/năm)
  - Xử lý tiếng Việt chưa tối ưu
  - Thiếu tính linh hoạt cho doanh nghiệp nhỏ

**Slide 4: Bài toán cần giải quyết**

- **Đặc điểm dữ liệu MXH**: Khổng lồ, phi cấu trúc, real-time
- **Quy trình cần**: Thu thập → Phân tích → Insight
- **Thách thức kỹ thuật**:
  - Scalability: Xử lý hàng nghìn videos
  - Async Processing: Không block user
  - Fault Tolerance: Lỗi một phần không sập toàn hệ thống
  - Performance: Time-to-Insight cần nhanh

---

### PHẦN 3: MỤC TIÊU & PHẠM VI (1.5 phút)

**Slide 5: Mục tiêu & Phạm vi**

**Mục tiêu:**

- Thiết kế kiến trúc **Microservices + Event-driven**
- Áp dụng **Clean Architecture** & **Domain-Driven Design**
- Tự động hóa quy trình: Crawling → Analyzing → Insight
- Rút ngắn Time-to-Insight

**Phạm vi:**

- **Nguồn dữ liệu**: YouTube, TikTok (dữ liệu công khai)
- **Phương pháp**: API chính thức + Web Scraping
- **Triển khai**: On-premise Kubernetes
- **Không bao gồm**: Nghiên cứu ML chuyên sâu (dùng pre-trained models)

---

### PHẦN 4: KIẾN TRÚC TỔNG QUAN (6 phút) ⭐ TRỌNG TÂM

**Slide 6: System Context (C4 Level 1) - 45 giây**

- Sơ đồ tổng quan: **User → SMAP → Social Platforms**
- Giải thích ngắn gọn các actors:
  - Marketing Team: Người dùng chính
  - SMAP System: Nền tảng phân tích
  - YouTube/TikTok: Nguồn dữ liệu

**Slide 7: Container Diagram (C4 Level 2) - 1.5 phút**

**10 Application Services** (nhấn mạnh polyglot):

**Golang Services (4):**

- Identity Service - Xác thực JWT
- Project Service - Quản lý campaigns
- Collector Service - Điều phối crawling
- WebSocket Service - Real-time notifications

**Python Services (6):**

- Analytics Service - Sentiment (PhoBERT), Intent, Aspect
- Speech2Text Service - Audio to text (tiếng Việt)
- YouTube Scraper - Thu thập YouTube
- TikTok Scraper - Thu thập TikTok
- FFmpeg Service - Video processing
- Playwright Service - Browser automation

**Frontend:**

- Web UI (Next.js/TypeScript) - Dashboard

**Slide 8: Infrastructure Components - 1 phút**

**Databases (3):**

- PostgreSQL (2): Identity, Project - ACID transactions
- MongoDB (1): Collector - Flexible schema
- Redis: Caching + Pub/Sub

**Message Queue:**

- RabbitMQ: Async processing, task distribution
- Redis Pub/Sub: Real-time notifications

**Storage:**

- MinIO: Object storage (videos, crawl results)

**Orchestration:**

- Kubernetes: Container orchestration
- Docker: Containerization

**Slide 9: Event-Driven Architecture - 1.5 phút**

**Message Flow:**

- **RabbitMQ Exchanges**:

  - `data.collected` → Analytics Service
  - `data.analyzed` → Project Service
  - `project.completed` → WebSocket Service

- **Claim-Check Pattern** (QUAN TRỌNG):

  - Large payload (videos, JSON) → MinIO
  - Event chỉ chứa reference (object_id)
  - Service download khi cần
  - **Lợi ích**: Giảm message size, tránh timeout

- **Redis Pub/Sub**:
  - Real-time progress tracking
  - WebSocket broadcast to frontend

**Slide 10: Tại sao chọn kiến trúc này? - 1.5 phút**

**So sánh 3 phong cách:**

- Monolithic: Single deployment, tightly coupled
- Modular Monolith: Modules nhưng vẫn chung process
- **Microservices**: Services độc lập, runtime isolation

**Quyết định dựa trên AHP Matrix** (điểm 4.7/5.0):

**3 lý do chính:**

1. **Asymmetric Workload**

   - Crawler/Analytics tiêu tốn tài nguyên cao hơn API
   - Cần scale riêng từng service

2. **Polyglot Runtime**

   - Python: AI/ML (PhoBERT, scikit-learn)
   - Go: High-performance API
   - Next.js: Modern frontend
   - Monolithic không hỗ trợ đa ngôn ngữ

3. **Fault Isolation**
   - Lỗi Crawler không làm sập Identity/Project
   - Eventual Consistency qua Saga Pattern
   - Circuit Breaker cho external calls

**Architecture Characteristics:**

- **AC-1**: Availability (99.5% uptime)
- **AC-2**: Performance (API <500ms p95)
- **AC-3**: Scalability (Horizontal scaling)

---

### PHẦN 5: LUỒNG XỬ LÝ CHÍNH (5 phút)

**Slide 11: Use Cases Overview - 45 giây**

**8 Use Cases chính:**

- UC-01: Cấu hình Project
- UC-02: Dry-run từ khóa
- UC-03: Execute Project (Khởi chạy thu thập)
- UC-04: Xem kết quả phân tích
- UC-05: Liệt kê danh sách Projects
- UC-06: Xuất báo cáo (PDF/Excel)
- UC-07: Phát hiện xu hướng tự động
- UC-08: Realtime Progress Tracking

> Sơ đồ Use Case (1 hình tổng quan)

**Slide 12: Data Pipeline (QUAN TRỌNG) - 2 phút**

**4 Giai đoạn xử lý:**

```
CRAWLING → ANALYZING → AGGREGATING → FINALIZING
(Collector) (Analytics)  (Project)     (Project)
```

**1. CRAWLING** (Collector Service):

- Crawl videos, comments, metadata từ YouTube/TikTok
- Lưu vào MinIO (Claim-Check Pattern)
- Pub event: `data.collected` → RabbitMQ

**2. ANALYZING** (Analytics Service):

- Nhận event từ RabbitMQ
- Download data từ MinIO
- **PhoBERT Sentiment** (3 labels: Positive/Negative/Neutral)
- **Intent Classification** (7 categories)
- **Aspect Extraction** (tính năng/đặc điểm được nhắc đến)
- **Performance**: <100ms inference per text
- Pub event: `data.analyzed`

**3. AGGREGATING** (Project Service):

- Tổng hợp kết quả từ nhiều videos
- Calculate statistics: sentiment ratio, top aspects, trending keywords
- Generate insights

**4. FINALIZING** (Project Service):

- Mark project complete
- WebSocket notification → User (real-time)

**Thời gian xử lý:**

- 100 videos: ~5-10 phút
- 1000 videos: ~30-60 phút

**Slide 13: Sequence Diagram - Execute Project - 1.5 phút**

- Chọn UC-03 Execute Project (quan trọng nhất)
- Giải thích tương tác:
  - User → Project Service: Create project
  - Project Service → Collector Service: Dispatch crawl job
  - Collector → Scraper Services: Crawl tasks
  - Scraper → MinIO: Save results
  - Scraper → RabbitMQ: Pub `data.collected`
  - Analytics → RabbitMQ: Subscribe event
  - Analytics → MinIO: Download data
  - Analytics → Project Service: Save analysis
  - Project → WebSocket: Notify user

> Có thể show 1 trong 4 parts của sequence diagram (chọn part quan trọng nhất)

**Slide 14: Database Strategy - 45 giây**

**Database-per-Service Pattern:**

- **Identity DB** (PostgreSQL): Users, Roles, Sessions
- **Project DB** (PostgreSQL): Projects, Campaigns, Analytics Results
- **Collector DB** (MongoDB): Crawl Jobs, Tasks (flexible schema)

**Eventual Consistency:**

- Services giao tiếp qua events
- Saga Pattern cho distributed transactions
- Trade-off: CAP theorem → chọn Availability + Partition Tolerance

> ERD tổng quan (3 hình nhỏ hoặc 1 hình gộp)

---

### PHẦN 6: KẾT QUẢ ĐẠT ĐƯỢC (1.5 phút)

**Slide 15: Deliverables - 1 phút**

**Phân tích hệ thống:**

- ✅ 47 Functional Requirements
- ✅ 31 Non-Functional Requirements
- ✅ 7 Architecture Characteristics

**Thiết kế:**

- ✅ 8 Activity Diagrams
- ✅ 19 Sequence Diagrams (chi tiết tương tác)
- ✅ 7 Component Diagrams (C4 Level 3)
- ✅ 3 ERD Diagrams

**Implementation:**

- ✅ 10 Microservices (partial implementation)
- ✅ Kubernetes Infrastructure (đầy đủ)
- ✅ Clean Architecture trong từng service
- ✅ Event-Driven Choreography

**Design Patterns:**

- ✅ Domain-Driven Design
- ✅ Claim-Check Pattern
- ✅ Saga Pattern
- ✅ Master-Worker Pattern

**Slide 16: Demo/Screenshots - 30 giây**

**UI Screenshots:**

- Landing Page
- Project Configuration
- Dry-run Results
- Analytics Dashboard (4 charts):
  - Sentiment Distribution
  - Top Aspects
  - Trending Keywords
  - Timeline Analysis

> Hoặc video demo 30 giây (nếu có)

---

### PHẦN 7: KẾ HOẠCH PHÁT TRIỂN(1 phút)

**Slide 17: Kế hoạch phát triển - Hybrid Architecture - 1 phút**

**Migration strategy**: Hybrid Architecture (On-premise + AWS Cloud)

**On-premise (Core Services)**:

- Identity, Project Services
- PostgreSQL (dữ liệu nhạy cảm)
- Tuân thủ GDPR và bảo mật

**AWS Cloud (Scalable Services)**:

- **Scrapers → AWS Lambda** (serverless, pay-per-use)
- **FFmpeg/Playwright → ECS Fargate** (heavy tasks)
- **Analytics Service → Lambda + SQS**

**Shared Infrastructure Migration**:

- MinIO → **S3** (object storage)
- RabbitMQ → **EventBridge + SQS**
- MongoDB → **DocumentDB**
- Redis → **ElastiCache**

**Lợi ích**:

- ✅ Cost optimization (pay-per-use cho scrapers)
- ✅ Auto-scaling (Lambda scale 0 → thousands)
- ✅ Managed services (giảm operational overhead)
- ✅ Security (core data vẫn on-premise)

**Timeline**:

- **Phase 1 (3-6 tháng)**: Migrate Scrapers, MinIO→S3, RabbitMQ→EventBridge
- **Phase 2 (6-12 tháng)**: Analytics lên Lambda, MongoDB→DocumentDB
- **Phase 3 (12+ tháng)**: Multi-region deployment, CloudFront CDN

---

### PHẦN 8: KẾT LUẬN (1.5 phút)

**Slide 18: Hạn chế hiện tại - 30 giây**

- Tập trung thiết kế, chưa hiện thực đầy đủ
- AI/ML Service chưa hoàn chỉnh (dùng pre-trained models)
- Chỉ hỗ trợ 2 platforms (YouTube, TikTok)
- Rate-limit handling chưa được test thực tế
- Load testing chưa được thực hiện
- User manual và API docs chưa hoàn thiện

> Chi tiết kế hoạch phát triển: Xem Slide 17

**Slide 19: Tổng kết & Q&A - 1 phút**

**Những gì đã đạt được:**

- ✅ Phân tích + Thiết kế hệ thống đầy đủ
- ✅ Kiến trúc vững chắc: Microservices + Event-driven + Clean Architecture
- ✅ Công nghệ hiện đại: Go, Python, Next.js, Kubernetes
- ✅ Hạ tầng sẵn sàng cho production

**Giá trị mang lại:**

- Giải quyết vấn đề thực tế của thị trường Social Listening
- Tiềm năng phát triển thành sản phẩm thương mại
- Kiến trúc có khả năng mở rộng và bảo trì cao

**Mở cho Q&A**

---

## GỢI Ý TRÌNH BÀY

### Nguyên tắc vàng cho 20 phút:

- **15-18 slides** là tối đa
- **1 slide = 1 ý chính** (không nhồi nhét)
- **Mỗi slide ~1 phút** (có slide nhanh, có slide chậm)
- **Dùng hình > chữ** (diagram nói thay bạn)
- **Nhấn mạnh con số**: 10 services, 47 FRs, 19 sequence diagrams

### Điểm nhấn quan trọng (phải nói rõ):

1. **Microservices + Event-driven** - Lý do chọn (AHP matrix 4.7/5.0), lợi ích
2. **Claim-Check Pattern** - Giải pháp sáng tạo cho large payload
3. **Data Pipeline 4 giai đoạn** - Luồng xử lý chính với thời gian cụ thể
4. **Kubernetes** - Khả năng scale, deployment strategy
5. **10 services với polyglot** - Go, Python, Next.js
6. **Clean Architecture** - 4 layers, SOLID principles
7. **PhoBERT Performance** - <100ms inference

### Những thứ KHÔNG cần nói chi tiết:

- ERD từng bảng (chỉ show hình tổng quan)
- Code implementation chi tiết
- Từng yêu cầu FR/NFR (chỉ nói con số tổng)
- So sánh chi tiết các đối thủ
- Tất cả 19 sequence diagrams (chỉ 1 diagram quan trọng nhất)

### Câu hỏi thường gặp (chuẩn bị sẵn):

**Kiến trúc:**

1. Tại sao chọn Microservices không phải Monolithic?

   - → Asymmetric workload, Polyglot, Fault isolation, AHP matrix 4.7/5.0

2. Tại sao dùng RabbitMQ không phải Kafka?

   - → RabbitMQ đơn giản hơn, phù hợp với message routing phức tạp, overhead thấp cho scale nhỏ

3. Clean Architecture được áp dụng như thế nào?

   - → 4 layers (Delivery, Usecase, Repository, Domain), Dependency Injection, SOLID principles

4. Eventual Consistency được xử lý ra sao?
   - → Saga Pattern, compensating transactions, idempotent consumers

**Kỹ thuật:** 5. Xử lý rate-limit từ platforms như thế nào?

- → Exponential backoff, request throttling, queue-based approach

6. Độ chính xác sentiment analysis?

   - → PhoBERT pre-trained, cần fine-tune cho domain cụ thể, accuracy ~85-90%

7. Claim-Check Pattern hoạt động ra sao?

   - → Large payload → MinIO, event chỉ chứa object_id, service download khi cần

8. Làm sao đảm bảo Fault Tolerance?
   - → Circuit Breaker, Retry với exponential backoff, Dead Letter Queue, Health checks

**Triển khai:** 9. Kubernetes deployment như thế nào?

- → Helm charts, ConfigMaps, Secrets, HPA (Horizontal Pod Autoscaler), Service Mesh (Istio)

10. Monitoring & Observability?
    - → Prometheus + Grafana, Distributed Tracing (Jaeger), Centralized Logging (ELK)

### Tips thuyết trình:

- **Tập trình bày 2-3 lần**, canh đúng 20 phút
- **Chuẩn bị 2-3 slides backup** cho Q&A (Component diagrams, Activity diagrams)
- **Nếu hết giờ**: Bỏ phần Demo, giữ Kết luận
- **Giọng nói**: Tự tin, rõ ràng, không đọc slides
- **Tương tác**: Nhìn vào hội đồng, không quay lưng
- **Pointer**: Dùng để chỉ diagram, không vung lung tung

### Phân công trình bày (nếu nhóm 3 người):

**Người 1** (Tài): Slides 1-5 (Mở đầu, Bối cảnh, Mục tiêu)
**Người 2** (Phong): Slides 6-10 (Kiến trúc) + Slides 15-16 (Kết quả)
**Người 3** (Tín): Slides 11-14 (Luồng xử lý) + Slides 17-18 (Kết luận)

Hoặc 1 người present chính, 2 người hỗ trợ Q&A.

---

## DANH SÁCH HÌNH ẢNH TỪ BÁO CÁO

Tất cả hình ảnh đã có sẵn trong `report/images/`:

### Diagrams (Bắt buộc)

| Slide | Hình                       | Đường dẫn                                                    |
| ----- | -------------------------- | ------------------------------------------------------------ |
| 6     | Context Diagram            | `report/images/diagram/context-diagram.png`                  |
| 7     | Container Diagram          | `report/images/diagram/container-diagram.png`                |
| 10    | Monolithic Architecture    | `report/images/architecture/monolithic_architecture.png`     |
| 10    | Modular Monolith           | `report/images/architecture/modular_monolith.png`            |
| 10    | Microservices Architecture | `report/images/architecture/microservices_architecture.png`  |
| 8     | Deployment Diagram         | `report/images/deploy/Diagram-deployment-diagram.drawio.png` |

### Data Flow (Quan trọng)

| Slide | Hình                 | Đường dẫn                                        |
| ----- | -------------------- | ------------------------------------------------ |
| 9, 12 | Analytics Pipeline   | `report/images/data-flow/analytics-pipeline.png` |
| 9     | Execute Project Flow | `report/images/data-flow/execute_project.png`    |
| 9     | Real-time Flow       | `report/images/data-flow/real-time.png`          |
| 9     | Progress Flow        | `report/images/data-flow/Progress.png`           |

### Sequence Diagrams

| Slide | Hình               | Đường dẫn                                       |
| ----- | ------------------ | ----------------------------------------------- |
| 13    | UC3 Execute Part 1 | `report/images/sequence/uc3_execute_part_1.png` |
| 13    | UC3 Execute Part 2 | `report/images/sequence/uc3_execute_part_2.png` |
| 13    | UC3 Execute Part 3 | `report/images/sequence/uc3_execute_part_3.png` |
| 13    | UC3 Execute Part 4 | `report/images/sequence/uc3_execute_part_4.png` |

### ERD Diagrams

| Slide | Hình         | Đường dẫn                            |
| ----- | ------------ | ------------------------------------ |
| 14    | Identity ERD | `report/images/erd/identity-erd.png` |
| 14    | Project ERD  | `report/images/erd/project-erd.png`  |
| 14    | Analytic ERD | `report/images/erd/analytic-erd.png` |

### UI Screenshots

| Slide | Hình          | Đường dẫn                          |
| ----- | ------------- | ---------------------------------- |
| 16    | Landing Page  | `report/images/UI/landing.png`     |
| 16    | Projects List | `report/images/UI/cacprojects.png` |
| 16    | Dry-run       | `report/images/UI/dryrun.png`      |
| 16    | Chart 1       | `report/images/UI/char1.png`       |
| 16    | Chart 2       | `report/images/UI/char2.png`       |
| 16    | Chart 3       | `report/images/UI/char3.png`       |
| 16    | Chart 4       | `report/images/UI/char4.png`       |
| 16    | Trend         | `report/images/UI/trend.png`       |

### Khác

| Slide | Hình            | Đường dẫn                           |
| ----- | --------------- | ----------------------------------- |
| 1     | Logo trường     | `report/images/hcmut.png`           |
| 15    | NFR Radar Chart | `report/images/NFRs_rada_chart.png` |

### Activity Diagrams (Backup)

- `report/images/activity/1.png` đến `8.png` - 8 activity diagrams
- `report/images/activity/dry.png` - Dry-run activity

### Component Diagrams (Backup)

- `report/images/component/identity-component-diagram.png`
- `report/images/component/project-component-diagram.png`
- `report/images/component/collector-component-diagram.png`
- `report/images/component/analytic-component-diagram.png`
- `report/images/component/websocket-component-diagram.png`
- `report/images/component/webui-component-diagram.png`

---

## DANH SÁCH FILE SLIDE CHI TIẾT

Mỗi slide đã được tạo file riêng với nội dung, hình ảnh cần có và văn nói:

| Slide | File                                                                  | Nội dung                         | Trạng thái |
| ----- | --------------------------------------------------------------------- | -------------------------------- | ---------- |
| 1     | [slide_01_title.md](slides/slide_01_title.md)                         | Trang bìa                        | ✅ Done    |
| 2     | [slide_02_summary.md](slides/slide_02_summary.md)                     | Tóm tắt đề tài                   | ✅ Done    |
| 3     | [slide_03_market.md](slides/slide_03_market.md)                       | Thị trường Social Listening      | ✅ Done    |
| 4     | [slide_04_problem.md](slides/slide_04_problem.md)                     | Bài toán cần giải quyết          | ✅ Done    |
| 5     | [slide_05_scope.md](slides/slide_05_scope.md)                         | Mục tiêu & Phạm vi               | ✅ Done    |
| 6     | [slide_06_context.md](slides/slide_06_context.md)                     | System Context (C4 Level 1)      | ✅ Done    |
| 7     | [slide_07_container.md](slides/slide_07_container.md)                 | Container Diagram - 10 services  | ✅ Updated |
| 8     | [slide_08_infrastructure.md](slides/slide_08_infrastructure.md)       | Infrastructure Components        | ✅ Done    |
| 9     | [slide_09_event_driven.md](slides/slide_09_event_driven.md)           | Event-Driven Architecture        | ✅ Done    |
| 10    | [slide_10_why_microservices.md](slides/slide_10_why_microservices.md) | Why Microservices + AHP matrix   | ✅ Updated |
| 11    | [slide_11_usecases.md](slides/slide_11_usecases.md)                   | Use Cases (8 UCs)                | ✅ Updated |
| 12    | [slide_12_pipeline.md](slides/slide_12_pipeline.md)                   | Data Pipeline + thời gian        | ✅ Done    |
| 13    | [slide_13_sequence.md](slides/slide_13_sequence.md)                   | Sequence Diagram                 | ✅ Done    |
| 14    | [slide_14_database.md](slides/slide_14_database.md)                   | Database Strategy                | ✅ Done    |
| 15    | [slide_15_results.md](slides/slide_15_results.md)                     | Deliverables (19 SD, 8 AD)       | ✅ Updated |
| 16    | [slide_16_demo.md](slides/slide_16_demo.md)                           | Demo/Screenshots                 | ✅ Done    |
| 17    | [slide_17_roadmap.md](slides/slide_17_roadmap.md)                     | **Kế hoạch phát triển - Hybrid** | ✅ **New** |
| 18    | [slide_18_limitations.md](slides/slide_18_limitations.md)             | Hạn chế hiện tại                 | ✅ Updated |
| 19    | [slide_19_conclusion.md](slides/slide_19_conclusion.md)               | Tổng kết & Q&A                   | ✅ Done    |

---

## TIMELINE CHUẨN BỊ

| Ngày | Công việc                                     |
| ---- | --------------------------------------------- |
| D-7  | Hoàn thành nội dung slides                    |
| D-6  | Update slides cần chỉnh sửa (7,10,11,12,15)   |
| D-5  | Review và chỉnh sửa toàn bộ                   |
| D-4  | Chuẩn bị câu trả lời cho 10 câu hỏi Q&A       |
| D-3  | Tập trình bày lần 1 (full run)                |
| D-2  | Tập trình bày lần 2, canh thời gian chính xác |
| D-1  | Final review, tập Q&A, check kỹ thuật         |
| D-0  | Thuyết trình                                  |

---

## NHẬN XÉT & CẢI THIỆN TỪ ANALYSIS

### Những điểm đã cải thiện trong plan này:

✅ **Slide 7**: Cập nhật từ 5 services → **10 services** với chi tiết polyglot stack

✅ **Slide 10**: Bổ sung **AHP matrix (4.7/5.0)** và 7 Architecture Characteristics

✅ **Slide 11**: Bổ sung **UC-08 Realtime Progress Tracking**

✅ **Slide 12**: Thêm **thời gian xử lý cụ thể** (100 videos: 5-10 phút, 1000 videos: 30-60 phút)

✅ **Slide 15**: Cập nhật số liệu chính xác:

- 8 Activity Diagrams (thay vì 7)
- **19 Sequence Diagrams** (thay vì 7)
- 7 Component Diagrams (bổ sung)
- 7 Architecture Characteristics (bổ sung)

✅ **Câu hỏi Q&A**: Mở rộng từ 4 → **10 câu hỏi** với câu trả lời chi tiết, bao gồm:

- Clean Architecture & DDD
- Saga Pattern
- Eventual Consistency
- Monitoring & Observability

✅ **Điểm nhấn**: Bổ sung các metrics cụ thể:

- PhoBERT Performance: <100ms inference
- API Performance: <500ms p95
- Availability: 99.5% uptime

✅ **Tips thuyết trình**: Bổ sung phần phân công nếu nhóm 3 người

### Những slide cần update nội dung:

| Slide | Cần update                       | Ưu tiên  |
| ----- | -------------------------------- | -------- |
| 7     | 10 services thay vì 5            | 🔴 Cao   |
| 10    | Bổ sung AHP matrix               | 🔴 Cao   |
| 12    | Thời gian xử lý cụ thể           | 🟡 Trung |
| 15    | Số liệu chính xác (19 SD, 8 AD)  | 🟡 Trung |
| 11    | UC-08 Realtime Progress Tracking | 🟢 Thấp  |

---

_Ghi chú: Plan này đã được cải thiện dựa trên phân tích toàn diện codebase và report. Tập trung vào con số cụ thể, metrics đo lường được, và giải thích rõ ràng các quyết định kiến trúc._
