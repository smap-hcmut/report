# SMAP - Social Media Analytics Platform

> Nền tảng phân tích dữ liệu mạng xã hội tự động cho Marketing Analyst

---

## 🎯 Tổng quan

SMAP là hệ thống phân tích mạng xã hội giúp Marketing Analyst theo dõi thương hiệu và đối thủ cạnh tranh trên các nền tảng YouTube, TikTok, Facebook. Hệ thống tự động thu thập dữ liệu, phân tích sentiment, trích xuất insights và cảnh báo khủng hoảng.

**Actor chính:** Marketing Analyst

**Platforms hỗ trợ:** YouTube, TikTok, Facebook

---

## 📋 8 Use Cases Chính

SMAP cung cấp 8 use cases được chia thành 3 nhóm chức năng:

### Nhóm 1: Quản lý Project
1. **UC-01: Cấu hình Project** - Tạo project theo dõi thương hiệu và đối thủ
2. **UC-05: Quản lý danh sách Projects** - Xem, lọc, điều hướng projects

### Nhóm 2: Thực thi và Phân tích
3. **UC-02: Kiểm tra từ khóa (Dry-run)** - Test keywords trước khi chạy thật
4. **UC-03: Khởi chạy và theo dõi Project** - Execute pipeline và monitor real-time
5. **UC-04: Xem kết quả phân tích** - Dashboard với KPIs và insights

### Nhóm 3: Báo cáo và Cảnh báo
6. **UC-06: Xuất báo cáo** - Export báo cáo PDF/Excel/CSV
7. **UC-07: Phát hiện trend tự động** - Cron job thu thập trends hàng ngày
8. **UC-08: Phát hiện khủng hoảng** - Real-time crisis monitoring và alerting

---

## UC-01: Cấu hình Project

### Mục đích
Tạo cấu hình Project mới để theo dõi thương hiệu và đối thủ cạnh tranh trên các nền tảng mạng xã hội. Project được lưu ở trạng thái **Draft**, cho phép kiểm tra và chỉnh sửa trước khi khởi chạy thu thập dữ liệu.

### Cách SMAP giải quyết

**Wizard 4 bước cấu hình:**

**Bước 1: Thông tin cơ bản**
- Tên Project (3-100 ký tự, unique)
- Mô tả
- Khoảng thời gian phân tích (1 ngày - 1 năm)

**Bước 2: Cấu hình thương hiệu**
- Tên thương hiệu
- Từ khóa thương hiệu (1-10 từ khóa, mỗi từ 2-50 ký tự)

**Bước 3: Cấu hình đối thủ**
- Thêm đối thủ cạnh tranh (1-5 đối thủ)
- Mỗi đối thủ có 1-5 từ khóa

**Bước 4: Chọn platforms và xác nhận**
- YouTube, TikTok, Facebook (ít nhất 1 bắt buộc)
- Hiển thị tổng quan cấu hình
- Thời gian xử lý ước tính

**Lưu hoặc Dry-run:**
- **Lưu Project**: Lưu với status "draft", không trigger thu thập dữ liệu
- **Dry-run**: Chuyển sang UC-02 để test keywords trước

### Validation Rules
- Tên Project unique cho mỗi user
- Độ dài từ khóa: 2-50 ký tự
- Tối đa 5 đối thủ
- Khoảng thời gian hợp lệ (to_date > from_date)
- Ít nhất 1 platform được chọn

### Output
- Project được lưu vào PostgreSQL với status "draft"
- Project ID được tạo
- User có thể thấy Project trong danh sách (UC-05)
- Project sẵn sàng cho việc khởi chạy (UC-03)

### Lợi ích
- ✅ Cấu hình linh hoạt với wizard trực quan
- ✅ Validation ngay lập tức để tránh lỗi
- ✅ Không tốn tài nguyên khi chưa sẵn sàng (explicit execution)
- ✅ Có thể test keywords trước khi chạy thật (dry-run)

---

## UC-02: Kiểm tra từ khóa (Dry-run)

### Mục đích
Xác thực chất lượng từ khóa trước khi lưu Project. Hệ thống thu thập mẫu nhỏ (3 posts/từ khóa) để đánh giá độ liên quan và điều chỉnh keywords nếu cần.

### Cách SMAP giải quyết

**Sampling Strategy:**
- Thu thập tối đa **3 posts mỗi từ khóa** từ platforms đã chọn
- Thời gian xử lý: 30-60 giây (timeout 90 giây)
- Không lưu vào database chính (ephemeral data)

**Quy trình:**

1. User nhấn nút "Dry-run" trong UC-01 bước 8
2. Hệ thống hiển thị loading "Đang thu thập mẫu..."
3. Collector Service dispatch jobs đến Crawler Services với sample size giới hạn
4. Crawler fetch metadata từ platform APIs
5. Hệ thống hiển thị kết quả mẫu với:
   - Tiêu đề
   - Preview nội dung
   - Platform
   - Engagement metrics (views, likes, comments, shares)

**User xem xét:**
- Chất lượng kết quả
- Độ liên quan của từ khóa
- Quyết định: Tiếp tục (quay lại UC-01 bước 7) hoặc Quay lại (điều chỉnh từ khóa)

### Xử lý Exception

**Không tìm thấy kết quả:**
- Hiển thị "Không tìm thấy kết quả cho từ khóa: [tên]"
- Các từ khóa khác vẫn hiển thị bình thường
- User có thể điều chỉnh từ khóa

**Rate-limit từ platform:**
- Hiển thị "Không thể lấy mẫu do giới hạn từ [platform], vui lòng thử lại sau 5 phút"
- Các platforms khác tiếp tục xử lý

**Timeout:**
- Nếu xử lý > 90 giây: hiển thị "Dry-run timeout"
- User có thể thử lại hoặc điều chỉnh từ khóa

### Lợi ích
- ✅ Tiết kiệm thời gian và chi phí (không chạy full pipeline)
- ✅ Phát hiện từ khóa không hiệu quả sớm
- ✅ Điều chỉnh keywords trước khi commit
- ✅ Preview kết quả để đánh giá chất lượng

---

## UC-03: Khởi chạy và theo dõi Project

### Mục đích
Khởi chạy Project để thực thi pipeline xử lý dữ liệu. User theo dõi tiến độ real-time qua WebSocket và nhận notification khi hoàn tất.

### Cách SMAP giải quyết

**Pipeline 4 giai đoạn:**

**1. Crawling Phase**
- Thu thập posts và comments từ platforms
- Batch processing: 20-50 items/batch
- Upload batches vào MinIO (object storage)
- Publish events qua RabbitMQ

**2. Analyzing Phase**
- Analytics Service consume events
- Download batches từ MinIO
- Chạy NLP pipeline 5 bước:
  - **Preprocessing**: Merge content, normalize Vietnamese text, detect spam
  - **Intent Classification**: 7 categories (REVIEW, COMPLAINT, QUESTION, PRAISE, CRISIS, SEEDING, NOISE)
  - **Keyword Extraction**: Hybrid approach (dictionary + statistical)
  - **Sentiment Analysis**: Overall + aspect-based (DESIGN, PERFORMANCE, PRICE, SERVICE, GENERAL)
  - **Impact Calculation**: Score 0-100, Risk Level (LOW/MEDIUM/HIGH/CRITICAL)
- Batch INSERT kết quả vào PostgreSQL

**3. Aggregating Phase**
- Tính toán KPIs tổng hợp
- Sentiment distribution
- Aspect breakdown
- Competitor comparison metrics

**4. Finalizing Phase**
- Cleanup temporary data
- Update project status thành "completed"
- Send notification qua WebSocket

### Real-time Progress Tracking

**Redis State Management:**
```
Key: smap:proj:{project_id}
Fields:
- status: INITIALIZING → CRAWLING → ANALYZING → DONE
- total_jobs: Tổng số jobs cần xử lý
- done_jobs: Số jobs đã hoàn thành
- progress_percentage: done/total * 100
- current_phase: Giai đoạn hiện tại
- eta_seconds: Thời gian ước tính còn lại
```

**WebSocket Updates:**
- User mở trang chi tiết Project
- WebSocket connection established
- Nhận updates real-time từ Redis Pub/Sub
- Hiển thị: giai đoạn, phần trăm, thời gian đã chạy, items đã xử lý, ETA

### Xử lý Exception

**Truy cập không được phép:**
- Verify ownership: project.created_by = user_id
- Hiển thị "Bạn không có quyền truy cập project"

**Status không hợp lệ:**
- Chỉ cho phép execute nếu status = "draft" hoặc "failed"
- Hiển thị "Project đã được khởi chạy hoặc đang thực thi"

**Thực thi thất bại:**
- Update status thành "failed"
- Hiển thị "Project khởi chạy thất bại, vui lòng thử lại!"
- User có thể retry với cùng config

### Performance Targets
- Thời gian xử lý trung bình: 35-50 phút
- Max timeout: 2 giờ
- Throughput: ≥ 70 items/phút (per Analytics worker)
- NLP Pipeline latency (p95): < 700ms

### Lợi ích
- ✅ Tự động hóa hoàn toàn (không cần can thiệp thủ công)
- ✅ Theo dõi tiến độ real-time với WebSocket
- ✅ Xử lý song song với event-driven architecture
- ✅ Fault tolerance với retry mechanism
- ✅ Scalable với independent service scaling

---

## UC-04: Xem kết quả phân tích

### Mục đích
Xem dashboard phân tích với sentiment trends, aspect analysis, và competitor comparison. Dashboard hỗ trợ filtering, sorting và drilldown vào chi tiết posts.

### Cách SMAP giải quyết

**Dashboard 4 phần chính:**

**A. Line/Area Chart - Mentions theo thời gian**
- Hiển thị số lượng mentions của brand và đối thủ theo timeline
- Hỗ trợ radio buttons để chuyển đổi giữa các metrics
- Tooltip hiển thị chi tiết khi hover
- Phát hiện trends tăng/giảm đột ngột

**B. Bar Chart - Share of Voice**
- So sánh thị phần giữa brand và đối thủ
- Tính theo số lượng mentions
- Hiển thị phần trăm và số tuyệt đối
- Insight: Brand có visibility như thế nào so với đối thủ

**C. Keyword Cloud - Top 20 Keywords**
- Hiển thị keywords phổ biến nhất
- Size tương ứng với frequency
- Highlight vị trí keyword của brand
- Click vào keyword để filter posts

**D. Bar Chart theo Aspect - Sentiment Breakdown**
- Phân tích sentiment theo từng aspect (DESIGN, PERFORMANCE, PRICE, SERVICE, GENERAL)
- Stacked bar: Positive/Neutral/Negative
- Xác định aspect nào đang được khen/chê nhiều nhất
- Click vào aspect để drilldown

### Filtering và Drilldown

**Filters hỗ trợ:**
- Platform (YouTube, TikTok, Facebook)
- Sentiment (Positive, Neutral, Negative)
- Khoảng thời gian (date range picker)
- Aspect (DESIGN, PERFORMANCE, PRICE, SERVICE, GENERAL)

**Drilldown workflow:**
1. User click vào aspect trên bar chart
2. Hiển thị danh sách posts liên quan đến aspect đó
3. User click vào post cụ thể
4. Modal hiển thị full details:
   - Full content
   - Aspect-level sentiment
   - Extracted keywords
   - Impact breakdown (engagement, reach, velocity)
   - Top comments với sentiment

### Performance
- Dashboard load < 2s
- Drilldown queries < 500ms
- Aggregation queries optimized với indexes

### Lợi ích
- ✅ Insights trực quan với charts và visualizations
- ✅ So sánh brand vs đối thủ một cách rõ ràng
- ✅ Phát hiện điểm mạnh/yếu theo aspect
- ✅ Drilldown để xem chi tiết posts
- ✅ Filtering linh hoạt để phân tích sâu

---

## UC-05: Quản lý danh sách Projects

### Mục đích
Quản lý danh sách Projects cá nhân: xem, lọc, tìm kiếm, và điều hướng đến các chức năng tùy theo status. Hệ thống đảm bảo ownership và status-based permissions.

### Cách SMAP giải quyết

**List View:**
- Hiển thị danh sách Projects của user (ownership: created_by = user_id)
- Mỗi Project card hiển thị:
  - Tên Project
  - Status badge (Draft/Running/Completed/Failed)
  - Ngày tạo
  - Lần cập nhật cuối
  - Preview từ khóa thương hiệu (3 keywords đầu)

**Filtering và Sorting:**
- Filter theo status (dropdown)
- Search theo tên (search box)
- Sort options (ngày tạo, tên, status)
- Hiển thị count: "Hiển thị X trong tổng Y projects"

**Status-based Actions:**

**Draft Projects:**
- Actions: "Khởi chạy" (→ UC-03), "Xóa"
- Click card: Navigate đến UC-01 (Edit configuration)

**Running Projects:**
- Actions: "Xem tiến độ" (→ UC-03)
- Nút "Xóa" bị vô hiệu hóa (không cho phép xóa running project)
- Click card: Navigate đến UC-03 (Monitor progress)

**Completed Projects:**
- Actions: "Xem kết quả" (→ UC-04), "Xuất báo cáo" (→ UC-06), "Xóa"
- Click card: Navigate đến UC-04 (Dashboard)

**Failed Projects:**
- Actions: "Thử lại" (→ UC-03), "Xóa"
- Click card: Navigate đến UC-03 (Retry)

### Soft Delete
- Xóa Project: Hiển thị confirmation dialog
- Nếu confirm: Set deleted_at = NOW() (soft delete)
- Project biến mất khỏi danh sách
- Hiển thị toast "Đã xóa Project"
- Có thể restore sau nếu cần (admin feature)

### Pagination
- Nếu user có > 50 projects: Apply pagination
- 20 projects mỗi trang
- Infinite scroll support

### Lợi ích
- ✅ Entry point chính sau khi login
- ✅ Quản lý tập trung tất cả projects
- ✅ Status-based navigation rõ ràng
- ✅ Filtering và search nhanh chóng
- ✅ Soft delete để có thể recovery

---

## UC-06: Xuất báo cáo

### Mục đích
Tạo và tải file báo cáo phân tích ở nhiều định dạng (PDF, Excel, CSV). Hệ thống hỗ trợ tuỳ chỉnh nội dung báo cáo và thời gian dữ liệu.

### Cách SMAP giải quyết

**Export Configuration Dialog:**

**Options:**
- **Định dạng file**: PDF, Excel, CSV
- **Khoảng thời gian**: Toàn bộ hoặc tùy chỉnh (date range)
- **Sections cần export**:
  - Overview (KPIs tổng quan)
  - Sentiment Analysis (phân tích cảm xúc)
  - Competitor Comparison (so sánh đối thủ)
  - Crisis Posts (bài viết khủng hoảng)

**Async Processing Workflow:**

1. User nhấn "Xuất báo cáo" từ Dashboard (UC-04)
2. Hiển thị Export Configuration Dialog
3. User chọn options và submit
4. Project Service validate và tạo export_request record (status: pending)
5. Publish export.requested event vào RabbitMQ
6. Trả về HTTP 202 Accepted với export_request_id
7. Hiển thị toast "Báo cáo đang được tạo, bạn sẽ nhận thông báo khi hoàn tất"
8. User có thể tiếp tục sử dụng hệ thống (không block UI)

**Report Generation (Background Worker):**

1. Export Worker consume export.requested event
2. Query analytics data từ PostgreSQL với filters
3. Generate report file theo định dạng:
   - **PDF**: Template engine (WeasyPrint) render HTML → PDF với charts và tables
   - **Excel**: Library (openpyxl) tạo spreadsheet với multiple sheets
   - **CSV**: Export raw data với comma-separated format
4. Upload file lên MinIO bucket `reports/`
5. Generate pre-signed download URL (7-day expiry)
6. Update export_request: status = completed, download_url, file_size
7. Publish export.completed event

**Notification và Download:**

1. WebSocket Service forward notification đến client
2. Web UI hiển thị notification banner "Báo cáo của bạn đã sẵn sàng" với link Download
3. User click Download hoặc navigate đến Export History page
4. Web UI request download_url từ Project Service
5. Trigger browser download từ MinIO pre-signed URL
6. File được tải về với tên `{project_name}_report_{date}.{format}`

### Exception Handling

**Export thất bại:**
- Timeout > 10 phút
- Database error
- Out of memory
- Update status = failed với reason
- Publish export.failed event
- User nhận notification "Tạo báo cáo thất bại, vui lòng thử lại"

### Performance
- Summary-only mode: < 30s
- Full report: < 10 phút
- Timeout threshold: 10 phút
- Queue & Worker pattern để xử lý tác vụ nặng

### Lợi ích
- ✅ Async processing không block UI
- ✅ Hỗ trợ nhiều định dạng (PDF, Excel, CSV)
- ✅ Tuỳ chỉnh nội dung và thời gian
- ✅ Download link với expiry để bảo mật
- ✅ Export history để audit

---

## UC-07: Phát hiện trend tự động

### Mục đích
Hệ thống tự động thu thập và xếp hạng trending content (music, keywords, hashtags) từ YouTube và TikTok theo lịch định kỳ. Marketing Analysts nhận feed trends để nắm bắt xu hướng sớm.

### Cách SMAP giải quyết

**Cron Schedule:**
- Kubernetes CronJob trigger hàng ngày lúc 2:00 AM UTC+7
- System Timer tự động kích hoạt Trend Service

**Quy trình tự động:**

**1. Trend Crawling**
- Trend Service tạo trend_run record (status: running)
- Initialize Redis state để track progress
- Request trending data từ TikTok và YouTube Crawler Services
- Thu thập:
  - Trending videos
  - Trending music/audio
  - Trending hashtags
  - Trending keywords

**2. Scoring và Ranking**
- Normalize metadata từ các platforms thành unified schema
- Calculate trend score:
  ```
  score = engagement_rate × velocity × 100
  
  engagement_rate = (likes + comments + shares) / views
  velocity = growth_rate_24h
  ```
- Rank và filter top 50 per platform
- Deduplicate cross-platform (cùng content trên nhiều platform)

**3. Storage và Caching**
- Batch insert vào PostgreSQL table `trends`
- Cache latest run_id trong Redis
- Lưu trữ 30 ngày, trends cũ hơn được tự động archive

**4. Notification**
- Broadcast notification đến tất cả Marketing Analysts
- WebSocket push notification real-time
- Email digest (optional)

### Trend Dashboard

**User Views Trends:**
1. User navigate đến Trends page
2. Trend Service fetch latest run_id từ Redis cache
3. Query trends từ PostgreSQL
4. Web UI render Trend Dashboard với:
   - Trends Grid (lưới thông tin)
   - Tiêu đề, nền tảng, điểm số, chỉ số tăng trưởng
   - Filters: Platform, loại nội dung, thời gian

**Drilldown:**
- Click vào trend để xem details
- Hiển thị related posts từ own projects (nếu có)
- Gợi ý cách áp dụng trend cho brand

### Exception Handling

**Lỗi thu thập từ platform:**
- Exponential backoff (thử lại 3 lần)
- Nếu vẫn fail: Bỏ qua platform bị lỗi, tiếp tục với platforms còn lại
- Mark is_partial_result = true
- Dashboard hiển thị cảnh báo "Dữ liệu từ [Platform] đang gặp sự cố"

**Timeout:**
- Nếu quy trình > giới hạn: Dừng và lưu partial data
- Dashboard hiển thị dữ liệu đã thu thập + cảnh báo chưa hoàn tất

**Toàn bộ thất bại:**
- Hiển thị dữ liệu của ngày hôm trước
- Thông báo lỗi cập nhật

### Lợi ích
- ✅ Tự động hóa hoàn toàn (không cần can thiệp)
- ✅ Nắm bắt trends sớm hơn 24-48 giờ
- ✅ Cross-platform trending insights
- ✅ Scoring algorithm để rank trends
- ✅ Historical data để phân tích xu hướng

---

## UC-08: Phát hiện khủng hoảng

### Mục đích
Thiết lập các chủ đề giám sát (Crisis Monitors) với từ khóa và ngưỡng cảnh báo cụ thể. Hệ thống tự động quét liên tục và gửi thông báo khi phát hiện nguy cơ khủng hoảng thương hiệu.

### Cách SMAP giải quyết

**Giai đoạn 1: User cấu hình giám sát**

**Crisis Monitor Configuration:**
1. User truy cập module "Crisis Management"
2. Chọn "Tạo giám sát mới"
3. Nhập thông tin:
   - Tên thương hiệu/Chủ đề cần bảo vệ
   - Từ khóa giám sát
   - Chọn nền tảng (Facebook, TikTok, YouTube)
   - Ngưỡng cảnh báo (ví dụ: Độ tiêu cực > 80%)
   - Kênh nhận thông báo (Email, App, SMS)
4. Hệ thống validate và lưu cấu hình "Crisis Monitor"
5. Kích hoạt tác vụ chạy ngầm (Background Scheduler)

**Giai đoạn 2: Hệ thống thực thi và Cảnh báo**

**Triple-Check Logic:**

Trong UC-03 Analytics Pipeline, sau khi save kết quả vào PostgreSQL, hệ thống check:

```
IF (Intent = CRISIS) 
   AND (Sentiment = NEGATIVE hoặc VERY_NEGATIVE)
   AND (Risk Level = HIGH hoặc CRITICAL)
THEN
   Trigger Crisis Alert
```

**Crisis Detection Workflow:**

1. Analytics Service phát hiện post thỏa mãn triple-check criteria
2. Build alert payload với:
   - Post details (content, author, platform, URL)
   - Metrics (views, likes, comments, shares)
   - Analytics results (sentiment, keywords, impact score)
3. Publish crisis.detected event vào RabbitMQ (high priority)
4. Đồng thời publish vào Redis Pub/Sub (ensure real-time delivery)

**Multi-channel Alerting:**

1. WebSocket Service receive message từ Redis Pub/Sub
2. Forward đến connected client (nếu user online)
3. Web UI hiển thị:
   - Notification banner (màu đỏ, urgent)
   - Play alert sound
   - Show browser notification
   - Update unread count badge

**Giai đoạn 3: User phản ứng**

**Crisis Dashboard:**

1. User nhận notification và click để xem chi tiết
2. Navigate đến Crisis Dashboard
3. Project API query crisis posts từ PostgreSQL với filters
4. Web UI render dashboard với:
   - Crisis posts list sorted by impact score
   - Filters: Platform, time range, risk level
   - Metrics: Total crisis posts, affected users, total engagement

**Post Details và Actions:**

1. User click vào crisis post
2. Modal hiển thị full details:
   - Full content và context
   - Sentiment breakdown by aspect
   - Impact analysis (reach, velocity, risk factors)
   - Top comments với sentiment
3. User thực hiện actions:
   - Mark as handled
   - Export crisis report
   - Share với team
   - Create response plan

### Continuous Monitoring

**Background Scheduler:**
- Chạy theo chu kỳ định sẵn (ví dụ: mỗi 15 phút)
- Quét dữ liệu mới nhất trên các nền tảng
- Chỉ lưu các bài viết vi phạm ngưỡng (tối ưu storage)
- Không lưu toàn bộ dữ liệu như Project

### Tạm dừng và Điều chỉnh

**Tạm dừng giám sát:**
- User chọn Monitor đang chạy và nhấn "Tạm dừng"
- Hệ thống ngắt lịch chạy ngầm (status: Inactive)
- Không có thông báo mới cho đến khi kích hoạt lại

**Điều chỉnh cấu hình:**
- Nếu nhận quá nhiều thông báo rác:
  - Thêm "Từ khóa loại trừ"
  - Nâng cao "Ngưỡng cảnh báo"
- Hệ thống cập nhật luồng quét với tham số mới

### Exception Handling

**Lỗi hệ thống giám sát:**
- Service chạy ngầm bị gián đoạn (Server down, API lỗi)
- Ghi log lỗi
- Gửi email cảnh báo cho Admin
- Khi phục hồi: Tự động chạy bù dữ liệu hoặc bắt đầu từ thời điểm hiện tại

### Sự khác biệt với Project

**Project (UC-01, UC-03):**
- Chạy 1 lần trên dữ liệu quá khứ
- Phân tích sâu và toàn diện
- Lưu toàn bộ dữ liệu
- Thời gian xử lý: 35-50 phút

**Crisis Monitor (UC-08):**
- Chạy liên tục trên dữ liệu real-time/near real-time
- Phát hiện nhanh và cảnh báo
- Chỉ lưu posts vi phạm ngưỡng
- Chu kỳ: Mỗi 15 phút

### Lợi ích
- ✅ Phát hiện khủng hoảng sớm (6-12 giờ trước khi lan rộng)
- ✅ Triple-check logic giảm false positives
- ✅ Multi-channel alerting (WebSocket, Email, SMS)
- ✅ Real-time monitoring liên tục
- ✅ Tuỳ chỉnh ngưỡng và từ khóa linh hoạt
- ✅ Crisis Dashboard để quản lý và phản ứng

---

## 🏗️ Kiến trúc Hệ thống

### Microservices Architecture

SMAP sử dụng kiến trúc Microservices với 7 core services và 4 supporting services:

**Core Services:**
1. **Identity Service** (Golang) - Authentication, JWT, user management
2. **Project Service** (Golang) - Project CRUD, orchestration, state management
3. **Collector Service** (Golang) - Master node, task dispatching, progress tracking
4. **WebSocket Service** (Golang) - Real-time communication, Pub/Sub
5. **Analytics Service** (Python) - NLP pipeline, sentiment analysis, AI/ML
6. **Speech2Text Service** (Python) - Audio transcription với Whisper
7. **Web UI** (Next.js) - Frontend dashboard, SSR support

**Supporting Services:**
1. **Scrapper Services** (Python) - Platform-specific crawlers (YouTube, TikTok, Facebook)
2. **FFmpeg Service** (Python) - Media processing, audio/video conversion
3. **Playwright Service** (Python) - Browser automation, advanced crawling
4. **MongoDB** (Temporary storage) - Raw data từ crawlers trước khi normalize

### Technology Stack

**Backend:**
- Golang: Identity, Project, Collector, WebSocket
- Python: Analytics, Speech2Text, Scrapper Services
- Node.js: Web UI (Next.js)

**Storage:**
- PostgreSQL: Relational data (users, projects, analytics results)
- Redis: Distributed cache, state management, Pub/Sub
- MinIO: Object storage (batches, reports, media files)
- MongoDB: Temporary raw data storage

**Messaging:**
- RabbitMQ: Event-driven architecture, async processing

**AI/ML:**
- PhoBERT: Vietnamese sentiment analysis
- Whisper: Speech-to-text
- Scikit-learn: Keyword extraction, classification

### Design Patterns

**Event-Driven Architecture:**
- Services giao tiếp qua RabbitMQ events
- Decoupling, async processing, resilience

**Master-Worker Pattern:**
- Collector Service (Master) dispatch tasks đến Scrapper Services (Workers)
- Independent scaling, fault tolerance

**Claim Check Pattern:**
- Lưu payload lớn vào MinIO, chỉ gửi reference qua RabbitMQ
- Message size reduction 99.96%, queue throughput 50x faster

**Repository Pattern:**
- Abstract data access qua interfaces
- Business logic không phụ thuộc storage implementation

**Clean Architecture:**
- 4 layers: Delivery → UseCase → Domain → Infrastructure
- Dependency inversion, testability cao

---

## 📊 Performance Targets

**API Response Time:**
- Project Creation: < 500ms
- Dashboard Load: < 2s
- Drilldown Queries: < 500ms

**Processing:**
- NLP Pipeline (p95): < 700ms
- Throughput: ≥ 70 items/phút (per worker)
- Project Execution: 35-50 phút (trung bình)

**Real-time:**
- WebSocket Latency: < 100ms
- Progress Update Frequency: Mỗi 5 giây
- Crisis Alert Latency: < 2 giây

**Scalability:**
- Concurrent Projects: ≥ 20 projects
- Concurrent Users: ≥ 50 users
- Independent service scaling

---

## 🎯 Tổng kết

SMAP là nền tảng phân tích mạng xã hội toàn diện với 8 use cases phục vụ Marketing Analyst:

**Quản lý Project:** Cấu hình linh hoạt, quản lý tập trung

**Thực thi và Phân tích:** Tự động hóa hoàn toàn, real-time monitoring, NLP pipeline 5 bước

**Báo cáo và Cảnh báo:** Export đa định dạng, trend detection tự động, crisis monitoring liên tục

**Kiến trúc:** Microservices với event-driven, polyglot persistence, independent scaling

**Performance:** Sub-second response time, high throughput, real-time updates

---

**SMAP - Tự động hóa phân tích mạng xã hội cho Marketing Analyst**
