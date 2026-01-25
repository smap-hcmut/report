# 📑 CHAPTER 4 STABLE CONTENT INDEX

**Status:** ✅ **STABLE & LOCKED**  
**Last Updated:** December 20, 2025  
**Source:** Sections 4.1 - 4.4 đã được team chốt

---

## 📊 OVERVIEW

| Section | Title                       | Status    | Lines | Last Modified |
| ------- | --------------------------- | --------- | ----- | ------------- |
| **4.1** | Nhu cầu người dùng hệ thống | ✅ Stable | 55    | Dec 2025      |
| **4.2** | Yêu cầu chức năng           | ✅ Stable | 111   | Dec 2025      |
| **4.3** | Yêu cầu phi chức năng       | ✅ Stable | 275   | Dec 2025      |
| **4.4** | Use Case                    | ✅ Stable | 840   | Dec 2025      |

---

## 🎯 SECTION 4.1: NHU CẦU NGƯỜI DÙNG HỆ THỐNG

### Actors (2)

#### **A-01: Marketing Analyst** (Primary User)

- **Đặc điểm:**
  - Chuyên gia 2-5 năm kinh nghiệm
  - Làm việc tại Agency/FMCG
- **Pain points:**
  - Thu thập dữ liệu thủ công, rời rạc
  - Khó phát hiện khủng hoảng sớm
- **Mục tiêu:**
  - Theo dõi danh tiếng thương hiệu
  - So sánh đối thủ cạnh tranh

#### **A-02: Social Media Platforms** (External Actor)

- **Đặc điểm:**
  - Nằm ngoài boundary SMAP
  - Cung cấp dữ liệu thô
- **Phương thức:**
  - Web scraping
  - API chính thức
- **Ràng buộc:**
  - Giới hạn tốc độ truy cập

---

## ⚙️ SECTION 4.2: YÊU CẦU CHỨC NĂNG

### Functional Requirements (7)

| FR ID    | Title                 | Mapped UC    | Key Features                                            |
| -------- | --------------------- | ------------ | ------------------------------------------------------- |
| **FR-1** | Cấu hình Project      | UC-01        | Tên, mô tả, từ khóa, đối thủ, platforms, dry-run        |
| **FR-2** | Thực thi & Giám sát   | UC-02, UC-03 | 4 phases: Crawling, Analyzing, Aggregating, Finalizing  |
| **FR-3** | Quản lý Projects      | UC-05        | Lọc, tìm kiếm, sắp xếp, soft-delete                     |
| **FR-4** | Xem kết quả & So sánh | UC-04        | Dashboard với KPI, sentiment trend, aspects, competitor |
| **FR-5** | Xuất báo cáo          | UC-06        | PDF, PPTX, Excel với metadata                           |
| **FR-6** | Phát hiện trend       | UC-07        | Cron job, thu thập trends, xếp hạng                     |
| **FR-7** | Phát hiện khủng hoảng | UC-08        | Crisis Monitors, cron job, cảnh báo real-time           |

### Key Business Rules

1. **Project chỉ chạy khi user khởi chạy** (không tự động khi tạo)
2. **Tên Project unique trong phạm vi user**
3. **Khoảng thời gian:** 1 ngày - 1 năm, không vượt quá hiện tại
4. **Từ khóa thương hiệu:** 1-10 từ khóa, mỗi từ 2-50 ký tự
5. **Đối thủ:** Tối đa 5 đối thủ, mỗi đối thủ 1-5 từ khóa
6. **Platforms:** Ít nhất 1 bắt buộc (YouTube, TikTok, Facebook)
7. **Dry-run:** 3 posts/từ khóa, stateless
8. **Soft-delete:** Retention 30-60 ngày
9. **Crisis Monitor:** Cron job mỗi 3-15 phút, chỉ lưu bài viết vi phạm

---

## 🏗️ SECTION 4.3: YÊU CẦU PHI CHỨC NĂNG

### 4.3.1 Đặc tính kiến trúc

#### Primary ACs (4)

| AC       | Characteristic  | Metrics                                    | Target                                                                         |
| -------- | --------------- | ------------------------------------------ | ------------------------------------------------------------------------------ |
| **AC-1** | **Modularity**  | Coupling index (I), Efferent coupling (Ce) | I ≈ 0, Ce < 5, ≤ 3 deps/service                                                |
| **AC-2** | **Scalability** | Concurrent workers, throughput             | Scale 2-20 workers < 5 min, 1,000 items/min with 10 workers (posts + comments) |
| **AC-3** | **Performance** | Response time, NLP time                    | NLP < 700ms (p95) CPU, API < 500ms (p95), Dashboard < 2s                       |
| **AC-4** | **Testability** | Coverage, tests, duration                  | Coverage ≥ 80%, ≥ 100 tests/service, suite < 5 min                             |

#### Secondary ACs (3)

| AC       | Characteristic      | Metrics                         | Target                                                        |
| -------- | ------------------- | ------------------------------- | ------------------------------------------------------------- |
| **AC-5** | **Deployability**   | Deploy time, rollback           | Deploy < 5 min, rollback < 5 min, downtime < 30s              |
| **AC-6** | **Maintainability** | Breaking changes, compatibility | Zero breaking changes, plugin pattern, 100% backward compat   |
| **AC-7** | **Observability**   | Log/metrics/trace coverage      | 100% errors logged, all critical paths covered, alert < 5 min |

### 4.3.2 Thuộc tính chất lượng

#### 4.3.2.1 Hiệu năng & Vận hành

**Performance:**

- **Response Time:** API < 500ms (p95), Dashboard < 3s, WebSocket < 100ms, Report < 10 min
- **Throughput:**
  - Crawling: Max rate-limit per platform, parallel crawling, posts + comments
  - Analytics: ~70 items/min with 1 worker (posts + comments), 20-50 items/batch, full NLP pipeline
  - WebSocket: 1,000 concurrent connections
- **Resource Utilization:** CPU < 60% normal / < 90% hard, Memory < 1GB/service / < 2GB NLP, Network latency < 50ms intra-cluster

#### 4.3.2.2 An toàn & Tuân thủ

**Security:**

- **Auth & Authorization:** JWT với HttpOnly cookies, session 2h / 30 days (remember me), ownership verify, RBAC
- **Data Protection:** TLS 1.3, AES-256 at rest, password min 8 chars (bcrypt), no plaintext
- **Application Security:** Input validation, sanitize, prevent SQL injection, CORS

**Compliance:**

- **Data Governance:** Right to access (JSON, CSV, Excel), right to delete (soft 30-60 days), no PII > 60 days
- **Platform Compliance:** Respect rate limits, follow ToS, no captcha bypass

#### 4.3.2.3 Trải nghiệm & Hỗ trợ

**Usability:**

- **UX:** Đa ngôn ngữ (VI, EN), loading states, error messages with codes, confirmation dialogs, undo 30s, real-time progress, onboarding

**Monitoring:**

- **Logging:** Prometheus metrics, structured logs (DEBUG, INFO, WARNING, ERROR, CRITICAL), JSON format with trace_id

---

## 📋 SECTION 4.4: USE CASE

### Use Case Summary (8)

| UC ID     | Name                       | Primary Actor     | Secondary Actor        | Goal                                                      |
| --------- | -------------------------- | ----------------- | ---------------------- | --------------------------------------------------------- |
| **UC-01** | Cấu hình Project           | Marketing Analyst | -                      | Tạo cấu hình với thương hiệu, từ khóa, đối thủ, platforms |
| **UC-02** | Kiểm tra từ khóa (Dry-run) | Marketing Analyst | Social Media Platforms | Xác thực chất lượng từ khóa bằng mẫu                      |
| **UC-03** | Khởi chạy và theo dõi      | Marketing Analyst | Social Media Platforms | Thực thi pipeline thu thập và phân tích                   |
| **UC-04** | Xem kết quả phân tích      | Marketing Analyst | -                      | Xem dashboard với KPIs, sentiment, aspects                |
| **UC-05** | Quản lý Projects           | Marketing Analyst | -                      | Xem, lọc, tìm kiếm, điều hướng theo status                |
| **UC-06** | Xuất báo cáo               | Marketing Analyst | -                      | Tạo và tải báo cáo ở nhiều định dạng                      |
| **UC-07** | Phát hiện trend            | Marketing Analyst | Social Media Platforms | Thu thập và xếp hạng trends định kỳ                       |
| **UC-08** | Phát hiện khủng hoảng      | Marketing Analyst | Social Media Platforms | Nhận diện và cảnh báo khủng hoảng                         |

---

### UC-01: Cấu hình Project

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (12 steps):**

1. User nhấn "Tạo Project mới"
2. Hệ thống hiển thị wizard (4 bước)
3. User nhập thông tin cơ bản
4. User nhập thương hiệu và từ khóa
5. User thêm đối thủ (1-5 đối thủ)
6. User chọn platforms (≥1)
7. Hệ thống hiển thị tổng quan
8. User chọn "Lưu" hoặc "Dry-run"
9. Hệ thống validate
10. Lưu với status "draft"
11. Hiển thị thông báo thành công
12. Chuyển về danh sách

**Alternative Flows:**

- **Dry-run từ khóa:** Tại bước 8 → UC-02 → quay lại bước 7

**Exceptions:**

- **Lỗi validation:** Highlight trường lỗi → user sửa → quay lại bước 9
- **Lỗi database:** Hiển thị thông báo, giữ form data → kết thúc

**Notes:**

- Tạo project KHÔNG trigger background processing

---

### UC-02: Kiểm tra từ khóa (Dry-run)

**Metadata:**

- Created: 01/11/2025 by Đặng Quốc Phong
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (6 steps):**

1. User nhấn "Dry-run"
2. Hiển thị loading
3. Crawl tối đa 3 posts/từ khóa
4. Hiển thị kết quả mẫu
5. User xem xét
6. User chọn "Tiếp tục" hoặc "Quay lại"

**Alternative Flows:**

- **Không tìm thấy kết quả:** Hiển thị thông báo, các từ khóa khác vẫn hiển thị

**Exceptions:**

- **Rate-limit:** Hiển thị thông báo, platforms khác tiếp tục
- **Timeout (>90s):** Hiển thị timeout, user có thể thử lại

**Notes:**

- Thời gian TB: 30-60s, timeout: 90s

---

### UC-03: Khởi chạy và theo dõi Project

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (10 steps):**

1. User chọn draft Project
2. User nhấn "Khởi chạy"
3. Hệ thống verify ownership và status
4. Cập nhật status → "process"
5. Thực hiện xử lý dữ liệu (pipeline 4 giai đoạn - xem Notes)
6. User mở trang chi tiết
7. Hiển thị real-time progress
8. _(Missing step - nhảy từ 7 → 9)_
9. Khi hoàn tất: gửi notification
10. User điều hướng đến Dashboard

**Alternative Flows:**

- **Thử lại failed project:** Hiển thị "Thử lại" → tiếp tục bước 3

**Exceptions:**

- **Truy cập không được phép:** Hiển thị thông báo → kết thúc
- **Status không hợp lệ:** Hiển thị thông báo → kết thúc
- **Thực thi thất bại:** Hiển thị thông báo, status → "failed" → quay lại bước 1

**Notes:**

- **Pipeline 4 giai đoạn:** (1) Crawling - posts/comments, (2) Analyzing - NLP 5 bước, (3) Aggregating, (4) Finalizing - cleanup & notify
- **Thời gian:** TB 35-50 phút, max timeout 2 giờ

**⚠️ Known Issue:**

- Flow có comment out chi tiết pipeline ở bước 5 (dòng 304)
- Missing step 8 (nhảy từ step 7 → 9)

---

### UC-04: Xem kết quả phân tích

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (4 steps):**

1. User mở completed Project
2. Hiển thị Dashboard (4 phần: KPI, Sentiment Trend, Aspect, Competitor)
3. User áp dụng filters
4. User drilldown vào chi tiết

**Alternative Flows:**

- **Xuất báo cáo:** Tại bước 4 → UC-06 → quay lại bước 4

**Exceptions:**

- _(Empty - "\-")_

**Notes:**

- Dashboard load < 2s, drilldown < 500ms

---

### UC-05: Quản lý danh sách Projects

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (6 steps):**

1. User mở "Projects"
2. Hiển thị danh sách với metadata
3. User áp dụng filters
4. User chọn Project và thấy actions theo status
5. User chọn action → điều hướng UC tương ứng
6. Nếu "Xóa": dialog xác nhận → soft delete

**Alternative Flows:**

- **Multiple Filters:** Logic AND, hiển thị count
- **Nhấn Project Card:** Điều hướng tự động theo status

**Exceptions:**

- **Xóa Running Project:** Nút bị disable
- **Cần Pagination:** >50 projects → 20/page, infinite scroll

**Notes:**

- User chỉ thấy projects của mình
- Composite index (created_by, deleted_at, status)
- Pagination 20 items/page

---

### UC-06: Xuất báo cáo

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Normal Flow (10 steps):**

1. User nhấn "Xuất báo cáo"
2. Hiển thị hộp thoại cấu hình
3. User chọn options
4. Validate thông tin
5. Ghi nhận yêu cầu, hiển thị thông báo
6. Đóng hộp thoại (non-blocking)
7. Sau khi xong: gửi notification
8. User nhấn notification
9. Chuyển đến trang download
10. User tải file

**Alternative Flows:**

- _(Empty - "\-")_

**Exceptions:**

- **Timeout (>10 phút):** Hủy tác vụ, gửi notification thất bại

**Notes:**

- **Validation:** FE (UX basic), BE (strict, HTTP 400)
- **Performance:** Summary-only < 30s, Queue & Worker, timeout 10 min

**⚠️ Known Issue:**

- Step 2 "Hiển thị hộp thoại cấu hình" - quá abstract, không mention format/sections/period

---

### UC-07: Phát hiện trend tự động

**Metadata:**

- Created: 20/10/2025 by Nguyễn Tấn Tài
- Last updated: 30/11/2025 by Nguyễn Thành Tín

**Actors:**

- Primary: Marketing Analyst
- Secondary: Social Media Platforms
- **System Actor: System Timer**

**Trigger:** System Timer hàng ngày 2:00 AM UTC+7

**Normal Flow (8 steps):**

1. Hệ thống tự động kích hoạt
2. Thu thập dữ liệu từ platforms
3. Chuẩn hóa, tính Trend Score & Velocity
4. Xếp hạng, lọc trùng, lưu Top trends
5. Marketing Analyst truy cập "Trend Dashboard"
6. Hiển thị Trends Grid
7. User xem danh sách
8. User dùng bộ lọc

**Alternative Flows:**

- _(Empty - "\-")_

**Exceptions:**

- **Platform Error:** Retry, bỏ qua nền tảng lỗi, hiển thị warning
- **System Timeout (>2h):** Dừng, hiển thị Partial Data

**Notes:**

- Exponential Backoff (3 lần)
- Daily 2:00 AM UTC+7
- Retention 30 ngày, auto-archive

---

### UC-08: Phát hiện khủng hoảng (Crisis Monitoring)

**Metadata:**

- Created: **20/10/2024** ⚠️
- Last updated: 20/12/2025 by Nguyễn Thành Tín

**Actors:**

- Primary: Marketing Analyst
- Secondary: Social Media Platforms
- **System Actor: Background Scheduler**

**Trigger:**

- User muốn thiết lập chủ đề theo dõi
- Hoặc: Hệ thống phát hiện dữ liệu khớp

**Normal Flow (3 giai đoạn, 9 steps):**

**Giai đoạn 1: Setup (4 steps)**

1. User truy cập "Crisis Management"
2. User nhập cấu hình (tên, include/exclude keywords, platforms, ngưỡng, kênh thông báo)
3. Hệ thống validate và lưu
4. Kích hoạt Background Job

**Giai đoạn 2: Automated (3 steps)** 5. Theo chu kỳ (mỗi 15 phút): quét dữ liệu mới 6. Nếu vi phạm: tạo Alert 7. Gửi thông báo tức thì

**Giai đoạn 3: User Response (2 steps)** 8. User nhận và xem chi tiết 9. User xử lý (Bỏ qua / Báo cáo)

**Alternative Flows:**

- **Tạm dừng giám sát:** Ngắt cron, status → Inactive
- **Điều chỉnh cấu hình:** Thêm exclude keywords, nâng ngưỡng

**Exceptions:**

- **Lỗi service:** Log, email admin, backfill (nếu có) hoặc quét từ hiện tại

**Notes:**

- **Khác với Project:** Project = 1 lần, quá khứ; Crisis = liên tục, real-time
- **Technical:** Chỉ lưu bài viết vi phạm (Hit)

**⚠️ Known Issue:**

- Created date = 2024 (should be 2025)
- Step 2 có 5 sub-items (quá nhiều detail trong 1 step)

---

## 🔍 TECHNICAL DETAILS SUMMARY

### System Architecture

- **Microservices:** Project, Collector, Analytics, WebUI, WebSocket, Identity
- **Event-Driven:** RabbitMQ (`project.created`, `data.collected`)
- **State Management:** Redis (progress state, Pub/Sub)
- **Database:** PostgreSQL (metadata, analytics)
- **Storage:** MinIO (crawled data, reports)
- **Monitoring:** Prometheus, structured logs (JSON)

### Key Technologies

- **NLP Pipeline:** Preprocessing → Intent → Keyword → Sentiment → Impact (5 steps)
- **AI Models:** PhoBERT-based, ~70 items/min/worker
- **Auth:** JWT with HttpOnly cookies, bcrypt (cost 10), min 8 chars
- **Deployment:** Kubernetes, rolling deployment, < 5 min deploy/rollback
- **Scalability:** Horizontal scaling, 2-20 workers, Docker images >1GB

### Data Flow

1. **Project Creation:** User → WebUI → Project Service → PostgreSQL (draft)
2. **Project Execution:** User trigger → Status update → RabbitMQ publish → Collector
3. **Crawling:** Collector → Crawlers → MinIO (batches) → RabbitMQ
4. **Analytics:** Consumer → Analytics Orchestrator → NLP Pipeline → PostgreSQL
5. **Progress Updates:** Webhook → WebSocket Service → Redis Pub/Sub → WebUI
6. **Crisis Monitoring:** Cron → Background Job → Platform Scan → Alert + Notification

### Performance Benchmarks

- **Crawling:** 1,000 items/min with 10 workers
- **Analytics:** ~70 items/min with 1 worker (full pipeline)
- **NLP:** < 700ms (p95) on CPU
- **API:** < 500ms (p95)
- **Dashboard:** < 2s load, < 500ms drilldown
- **WebSocket:** < 100ms delivery, 1,000 concurrent connections
- **Report:** < 10 min generation

---

## ⚠️ KNOWN ISSUES & DISCREPANCIES

### UC-03 (Critical)

1. **Step 5 abstraction:** Chi tiết pipeline bị comment out (dòng 304)
2. **Missing step 8:** Flow nhảy từ step 7 → 9

### UC-04 (Minor)

1. **Empty Exceptions:** Không có exception nào được define

### UC-06 (Minor)

1. **Step 2 abstract:** Không mention format/sections/period options

### UC-08 (Minor)

1. **Date typo:** Created date = 2024 (should be 2025)
2. **Step 2 overload:** 5 sub-items trong 1 step

### General

- UC-01 Step 5: Không có từ "tùy chọn" cho competitors (có thể intentional)
- UC-02 Precondition 2: "Thương hiệu và ít nhất 1 đối thủ" (có thể strict)
- FR-7 vs UC-08: Đã được align (Crisis Monitoring as standalone feature)

---

## ✅ VALIDATION CHECKLIST

- [x] All sections read and indexed
- [x] Metadata captured (dates, authors, versions)
- [x] Business rules documented
- [x] Technical specs noted
- [x] Known issues flagged
- [x] Cross-references verified
- [x] Performance targets recorded
- [x] Compliance requirements listed

---

## 📝 CHANGE LOG

| Date       | Author           | Changes                       | Scope                     |
| ---------- | ---------------- | ----------------------------- | ------------------------- |
| 20/12/2025 | AI Assistant     | Initial stable index creation | All sections 4.1-4.4      |
| 30/11/2025 | Team             | Last update before lock       | Multiple UCs              |
| 20/10/2025 | Team             | Initial creation              | UC-01, 03, 04, 05, 06, 07 |
| 01/11/2025 | Đặng Quốc Phong  | UC-02 created                 | UC-02                     |
| 20/12/2025 | Nguyễn Thành Tín | UC-08 last update             | UC-08                     |

---

**End of Stable Index**  
Generated by: AI Assistant  
For: SMAP Report Chapter 4  
Team: Nguyễn Tấn Tài, Nguyễn Thành Tín, Đặng Quốc Phong
