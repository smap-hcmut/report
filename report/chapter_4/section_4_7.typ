// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.7 Sơ đồ tuần tự (Sequence Diagram)

Sơ đồ tuần tự (Sequence Diagram) cụ thể hóa các tương tác động giữa các thành phần hệ thống theo trình tự thời gian cho các Use Case đã được đặc tả ở trên. Các sơ đồ này làm rõ cơ chế giao tiếp giữa Web UI, các dịch vụ nghiệp vụ (Microservices), hệ thống lưu trữ và hàng đợi thông điệp để thực hiện các chức năng cốt lõi.

Các sơ đồ tuần tự được chia thành 3 nhóm chức năng chính:

*1. Nhóm Quản lý Project (UC-01, UC-02, UC-03):* Mô tả quy trình cấu hình, kiểm tra và khởi chạy Project, bao gồm các tương tác giữa Web UI, Project Service, Redis, RabbitMQ, Collector Service và Crawler Services.

*2. Nhóm Phân tích & Báo cáo (UC-04, UC-05):* Trình bày luồng xử lý dữ liệu từ crawling, qua analytics pipeline (preprocessing, intent, sentiment, impact), đến việc lưu trữ và xuất báo cáo với nhiều định dạng (PDF, PPTX, Excel).

*3. Nhóm Tự động hóa & Cảnh báo (UC-06, UC-07, UC-08):* Mô tả các chức năng tự động của hệ thống như phát hiện trend theo cron job, cảnh báo khủng hoảng real-time, và cập nhật tiến độ qua WebSocket.

Các sơ đồ tuần tự bên dưới được xây dựng dựa trên kiến trúc hệ thống thực tế (Section 3.2), API contracts giữa các services, và event-driven architecture (RabbitMQ, Redis Pub/Sub). Mỗi sơ đồ bao gồm:
- *Main Flow:* Luồng chính thể hiện tương tác bình thường khi không có lỗi.
- *Error Handling:* Các nhánh xử lý lỗi quan trọng như timeout, rate-limit, validation failure.
- *Performance Optimization:* Các kỹ thuật như batching (20-50 items), async processing, throttled webhook callbacks.

=== 4.7.1 UC-01: Cấu hình Project

Use Case đầu tiên mô tả quy trình tạo mới một Project phân tích. Đây là bước khởi đầu trong hành trình phân tích thương hiệu, nơi Marketing Analyst định nghĩa scope phân tích thông qua việc cấu hình các từ khóa thương hiệu (brand keywords) và từ khóa đối thủ (competitor keywords), cùng với khoảng thời gian phân tích.

Điểm đặc biệt của UC này là Project được lưu với trạng thái `draft` và *không kích hoạt bất kỳ xử lý nào*. Điều này cho phép người dùng có thời gian kiểm tra, chỉnh sửa cấu hình trước khi thực sự khởi chạy (UC-03). Thiết kế này tuân thủ nguyên tắc "explicit execution" - tránh việc hệ thống tự động crawl dữ liệu khi người dùng chưa sẵn sàng, giúp tiết kiệm chi phí API calls và đảm bảo chất lượng cấu hình.

#figure(
  image("../images/sequence/uc1_cau_hinh_project.png", width: 100%),
  caption: [
    Sequence Diagram UC-01: Cấu hình Project.
    Luồng tạo Project mới với brand và competitor keywords, lưu vào PostgreSQL với status = "draft".
    Không có Redis state hoặc RabbitMQ event được tạo ra ở bước này.
  ],
) <fig:uc01_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01_])
#image_counter.step()

*Các bước chính trong UC-01:*

+ *User Input (Steps 1-5):* Marketing Analyst điền thông tin Project qua wizard 4 bước: (1) Thông tin cơ bản (tên, mô tả, khoảng thời gian), (2) Cấu hình thương hiệu chính, (3) Cấu hình đối thủ cạnh tranh, (4) Review và xác nhận.

+ *API Request (Step 6):* Web UI gửi POST request đến `/projects` endpoint với payload chứa toàn bộ thông tin cấu hình. Request này được authenticated bằng JWT token trong cookie `smap_auth_token`.

+ *Date Range Validation (Step 7):* Project Service kiểm tra tính hợp lệ của khoảng thời gian: `to_date` phải lớn hơn `from_date`. Validation này quan trọng vì sẽ ảnh hưởng trực tiếp đến số lượng jobs crawling sau này.

+ *Keyword Validation (Step 8 - Currently Disabled):* Trong thiết kế ban đầu, hệ thống sử dụng LLM (Language Model) để validate và normalize keywords. Tuy nhiên, tính năng này hiện đang bị tắt do vấn đề timeout khi gọi LLM API. Keywords được lưu trực tiếp mà không qua xử lý.

+ *Database Persistence (Steps 9-10):* Project được lưu vào PostgreSQL với các đặc điểm:
  - Status ban đầu: `draft` (chưa được execute)
  - Brand keywords và competitor keywords lưu dưới dạng JSONB arrays
  - Thời gian tạo (`created_at`) và người tạo (`created_by`) được ghi nhận
  - UUID được generate tự động làm primary key

+ *Response (Step 11):* Trả về HTTP 201 Created với Project object, bao gồm `project_id` để sử dụng cho các bước tiếp theo.

*Điểm kỹ thuật quan trọng:*

- *No side effects:* Việc tạo Project *không* trigger bất kỳ background processing nào. Không có Redis state initialization, không có RabbitMQ event publishing. Đây là thiết kế chủ đích để tách biệt "configuration" và "execution".

- *JSONB storage:* PostgreSQL JSONB column cho phép lưu trữ flexible schema (competitor có thể có số lượng keywords khác nhau) đồng thời vẫn hỗ trợ indexing và querying hiệu quả.

- *Idempotency consideration:* Nếu user submit form nhiều lần (do network issues), mỗi lần sẽ tạo ra một Project mới (với UUID khác nhau). Điều này an toàn vì Project ở trạng thái draft có thể xóa dễ dàng.

- *Future enhancement:* Keyword validation qua LLM sẽ được enable lại khi giải quyết được vấn đề timeout, có thể thông qua async processing hoặc caching kết quả validation.

=== 4.7.2 UC-02: Dry-run (Kiểm tra keywords)

UC-02 cung cấp cơ chế "thử nghiệm" keywords trước khi chạy Project thật. Đây là tính năng quan trọng giúp Marketing Analyst đánh giá chất lượng keywords và điều chỉnh cấu hình nếu cần, tránh lãng phí tài nguyên crawling cho keywords kém chất lượng.

Dry-run sử dụng *sampling strategy* để giảm chi phí: thay vì crawl toàn bộ dữ liệu trong khoảng thời gian đã chọn, hệ thống chỉ lấy 1-2 items mẫu cho mỗi keyword trên mỗi platform (tổng cộng 5-10 items). Các mẫu này đủ để đánh giá engagement rate, sentiment distribution, và relevance của keyword.

Sequence diagram được chia thành 2 phần do độ dài: Part 1 tập trung vào setup và crawling, Part 2 mô tả analytics pipeline và hiển thị kết quả.

==== Part 1: Setup & Crawling

#figure(
  image("../images/sequence/uc2_dryryn_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-02 (Part 1/2): Dry-run Setup & Crawling.
    User submit keywords để test, hệ thống apply sampling strategy và dispatch crawl jobs với số lượng giới hạn.
  ],
) <fig:uc02_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *User Initiation (Steps 1-2):* User chọn "Kiểm tra từ khóa", nhập danh sách keywords (brand hoặc competitor), chọn platform (TikTok/YouTube), và khoảng thời gian test. Request được gửi đến `/projects/dryrun` endpoint.

+ *Sampling Strategy (Step 3):* Đây là điểm khác biệt chính giữa dry-run và production run. Sampling UseCase áp dụng config-driven limits:
  - TikTok: 1-2 items per keyword (configurable)
  - YouTube: 1-2 items per keyword
  - Total cap: không quá 10 items cho toàn bộ dry-run

  Strategy này đảm bảo thời gian response nhanh (< 2 phút) và chi phí API calls thấp.

+ *Event Publishing (Step 4):* Project Service publish `dryrun.created` event vào RabbitMQ với routing key `dryrun.created`. Event payload chứa:
  - `task_id`: UUID để tracking
  - `keywords`: danh sách keywords cần test
  - `platform`: platform được chọn
  - `sample_size`: số lượng items per keyword
  - `callback_url`: endpoint để report kết quả

+ *Async Response (Step 5):* API trả về HTTP 202 Accepted ngay lập tức với `task_id`, không đợi crawling hoàn tất. Web UI bắt đầu polling `/dryrun/:id/status` mỗi 3 giây.

+ *Collector Consumes Event (Steps 5-7):* Collector Service nhận event từ RabbitMQ, parse keywords, và dispatch jobs đến Crawler Services. Mỗi keyword tạo ra 1 job với constraint `limit=sample_size`.

+ *Crawler Execution (Step 7):* Crawler services (TikTok/YouTube) fetch metadata từ platform APIs:
  - Respect rate-limits (avoid being blocked)
  - Chỉ lấy metadata (title, views, likes, etc.), không download video
  - Return Atomic JSON format (chuẩn hóa cross-platform)

+ *MinIO Upload (Step 8):* Batch items được upload vào MinIO với path `dryrun/{task_id}/batch_0.json`. MinIO được chọn thay vì PostgreSQL để tránh bloat database với temporary data.

==== Part 2: Analytics & Results

#figure(
  image("../images/sequence/uc2_dryryn_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-02 (Part 2/2): Analytics Pipeline & Results Display.
    Analytics Service xử lý batch từ MinIO, chạy full pipeline, lưu kết quả vào PostgreSQL, và trả về cho user qua polling.
  ],
) <fig:uc02_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Data.Collected Event (Steps 9-10):* Collector publish `data.collected` event với `minio_path` pointing đến batch file. Event này trigger Analytics Service để bắt đầu xử lý.

+ *Analytics Pipeline (Steps 11-12):* Analytics Service download batch từ MinIO và chạy *full 5-step pipeline* cho mỗi item:
  1. *Preprocessing:* Merge caption + transcription + top comments, normalize Vietnamese text
  2. *Intent Classification:* Detect post intent (REVIEW, COMPLAINT, CRISIS, SEEDING)
  3. *Keyword Extraction:* Hybrid dictionary + YAKE algorithm với aspect mapping
  4. *Sentiment Analysis:* PhoBERT-based overall + aspect-level sentiment
  5. *Impact Calculation:* Engagement score + reach score + sentiment weight + velocity

  Lưu ý: Dry-run sử dụng *same pipeline* như production để đảm bảo kết quả representative.

+ *Database Save (Step 13):* Kết quả được lưu vào `post_analytics` table với:
  - `project_id = NULL` (để phân biệt với production data)
  - `task_type = "dryrun"` (để dễ filter và cleanup)
  - Đầy đủ metrics: sentiment, impact_score, keywords, aspects

+ *Callback Webhook (Step 15):* Collector gọi webhook `/internal/dryrun/callback` để báo completion. Webhook này update task status trong Redis cache.

+ *Polling & Results (Steps 16-17):* Web UI polling detect `status = "completed"`, gọi `/dryrun/:id/results` để fetch summarized results:
  - Per-keyword statistics: avg sentiment, avg engagement rate
  - Top posts với highest impact
  - Sentiment distribution chart data
  - Recommendation: keyword nào nên giữ, keyword nào nên loại

+ *Display (Step 18):* Web UI render preview dashboard với insights:
  - "Keyword X có engagement cao nhất (8.5%), nên prioritize"
  - "Keyword Y có 80% negative sentiment, cân nhắc loại bỏ"
  - Sample posts để user xem context

*Điểm kỹ thuật quan trọng:*

- *No project_id:* Dry-run data không gắn với Project nào, dễ dàng cleanup sau một khoảng thời gian (e.g., 7 days retention).

- *Full pipeline reuse:* Sử dụng lại toàn bộ analytics code, không cần maintain separate "simplified" logic cho dry-run. Điều này đảm bảo consistency và giảm maintenance burden.

- *Async architecture:* Hoàn toàn event-driven (RabbitMQ), cho phép scale horizontally khi có nhiều dry-run requests đồng thời.

- *Cost optimization:* Sampling + MinIO temporary storage + 7-day retention giúp giảm chi phí đáng kể so với full production run.

=== 4.7.3 UC-03: Khởi chạy & Giám sát Project

UC-03 là luồng xử lý phức tạp nhất trong hệ thống, bao gồm 4 giai đoạn chính: (1) Execute & Initialize, (2) Collector Dispatches Jobs, (3) Analytics Pipeline, và (4) Completion. Do độ phức tạp cao, sequence diagram được chia thành 4 phần tương ứng với 4 giai đoạn.

Use Case này thể hiện rõ *transaction-like flow* với rollback mechanism ở mỗi bước, *event-driven architecture* giữa các services, và *real-time progress tracking* qua Redis state. Đây là "backbone" của toàn bộ hệ thống phân tích.

==== Part 1: Execute & Initialize

#figure(
  image("../images/sequence/uc3_execute_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-03 (Part 1/4): Execute & Initialize Project.
    User trigger execution, hệ thống verify ownership, update PostgreSQL status, init Redis state, và publish RabbitMQ event với rollback mechanism ở mỗi bước.
  ],
) <fig:uc03_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *User Trigger (Steps 1-2):* Marketing Analyst click "Khởi chạy" trên một Draft Project. Web UI gửi POST request đến `/projects/:id/execute` endpoint với authentication cookie.

+ *Ownership Verification (Step 3):* Bước security quan trọng: Project Service query PostgreSQL để verify user là owner của Project (`created_by == user_id`). Nếu không match, trả về 403 Forbidden.

+ *Duplicate Execution Check (Step 4):* Hệ thống kiểm tra Redis state (`smap:proj:{id}`) để đảm bảo Project chưa đang execute. Nếu state tồn tại, trả về 409 Conflict với error code 30008. Điều này prevent race condition khi user click "Khởi chạy" nhiều lần.

+ *PostgreSQL Status Update (Step 5):* *Critical step* - Update Project status từ `draft` thành `process` trong PostgreSQL. Đây là bước *đầu tiên* trong transaction-like flow. Nếu bước này fail, không có side effects nào xảy ra.

+ *Redis State Initialization (Steps 7-9):* Tạo Redis hash `smap:proj:{id}` với fields:
  - `status: "INITIALIZING"` (giai đoạn đầu tiên)
  - `total: 0`, `done: 0`, `errors: 0` (sẽ được update bởi Collector)
  - `user_id: {user_id}` (để route WebSocket notifications)
  - TTL: 7 days (604800 seconds) để auto-cleanup

  *Rollback on failure:* Nếu Redis init fail, hệ thống rollback PostgreSQL status về `draft`. Điều này đảm bảo consistency giữa PostgreSQL (source of truth) và Redis (runtime state).

+ *RabbitMQ Event Publishing (Step 10):* Publish `project.created` event vào exchange `smap.events` với routing key `project.created`. Event payload chứa:
  - `project_id`, `user_id` (để tracking và notification)
  - `brand_keywords`, `competitor_keywords` (để Collector generate jobs)
  - `from_date`, `to_date` (time range để crawl)

  *Rollback on failure:* Nếu RabbitMQ publish fail, hệ thống rollback *cả* Redis state và PostgreSQL status. Đây là điểm quan trọng nhất của rollback mechanism.

+ *Success Response (Step 11):* Trả về 200 OK với `{project_id, status: "executing"}`. Web UI ngay lập tức navigate đến Project Processing page với progress bar.

*Điểm kỹ thuật quan trọng:*

- *Transaction-like flow:* Mặc dù không sử dụng distributed transaction (2PC), hệ thống implement manual rollback ở mỗi step để đảm bảo consistency. Order of operations: PostgreSQL → Redis → RabbitMQ (từ persistent nhất đến ephemeral nhất).

- *Redis as runtime state:* Redis state (`smap:proj:{id}`) là single source of truth cho progress tracking. Mọi services (Collector, Analytics, WebSocket) đều đọc/ghi vào Redis này.

- *Event-driven decoupling:* Project Service không biết gì về Collector hay Analytics. Sau khi publish event, responsibility được chuyển giao. Điều này cho phép scale và deploy services độc lập.

- *User experience:* Toàn bộ flow execute + initialize chỉ mất ~200-500ms (fast database writes + Redis set + RabbitMQ publish). User nhận response nhanh chóng và được redirect đến monitoring page.

==== Part 2: Collector Dispatches Jobs

#figure(
  image("../images/sequence/uc3_execute_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-03 (Part 2/4): Collector Dispatches Crawl Jobs.
    Collector Service consume project.created event, parse keywords, generate job matrix, và dispatch crawl jobs đến Crawler Services với batching strategy.
  ],
) <fig:uc03_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Event Consumption (Step 12):* Collector Service consume `project.created` event từ RabbitMQ. Collector có dedicated consumer với prefetch count = 1 để avoid overloading.

+ *Keyword Parsing (Step 13):* Extract và normalize keywords:
  - Brand keywords: `["VinFast", "VF3", "VF8"]`
  - Competitor keywords: `[{name: "Toyota", keywords: ["Vios", "Camry"]}, ...]`

+ *Job Matrix Generation (Step 14):* Tính toán số lượng jobs cần dispatch. Công thức:
  ```
  total_jobs = num_keywords × num_platforms × num_days
  ```

  Ví dụ: 3 keywords × 2 platforms (TikTok, YouTube) × 30 days = 180 jobs.

  Mỗi job đại diện cho việc crawl 1 keyword trên 1 platform trong 1 ngày cụ thể. Granularity này cho phép parallel processing và fine-grained progress tracking.

+ *Redis State Update (Step 15):* Update Redis state:
  - `status: "CRAWLING"` (chuyển sang giai đoạn 2)
  - `total: 180` (total jobs để track progress)

+ *Job Dispatching Loop (Steps 16-19):* Collector dispatch jobs sequentially hoặc với controlled parallelism. Mỗi job:
  - Được route đến appropriate Crawler Service (TikTok Crawler hoặc YouTube Crawler)
  - Chứa context: `{keyword, platform, date, project_id}`
  - Crawler crawl data từ platform API, respect rate-limits
  - Crawler return batch of 20-50 items (Atomic JSON format)

+ *MinIO Upload (Step 17):* Batch được upload vào MinIO với path:
  ```
  crawl/{project_id}/batch_{X}.json
  ```

  MinIO được chọn vì:
  - Object storage tối ưu cho large files (batch có thể 1-5 MB)
  - S3-compatible, dễ scale
  - Tách biệt storage concerns khỏi PostgreSQL

+ *Data.Collected Event (Step 18):* Collector publish `data.collected` event cho mỗi batch với payload:
  ```json
  {
    "project_id": "...",
    "minio_path": "crawl/{project_id}/batch_X.json",
    "batch_index": X,
    "items_count": 45
  }
  ```

+ *Progress Update (Step 19):* Sau mỗi job hoàn thành, Collector increment Redis counter:
  ```
  HINCRBY smap:proj:{id} done 1
  ```

  Điều này cho phép real-time progress tracking (done / total × 100%).

+ *Status Transition (Step 20):* Khi tất cả crawl jobs complete, Collector update:
  ```
  HSET smap:proj:{id} status "PROCESSING"
  ```

*Điểm kỹ thuật quan trọng:*

- *Batching strategy:* Crawler trả về 20-50 items/batch thay vì 1 item/request. Điều này giảm drastically số lượng MinIO uploads và RabbitMQ messages. Trade-off: latency slightly higher nhưng throughput cao hơn nhiều.

- *Idempotency:* Nếu Collector crash và restart, RabbitMQ sẽ redeliver `project.created` event. Collector check Redis state - nếu đã tồn tại, skip processing (avoid duplicate crawling).

- *Rate-limit handling:* Crawler services có built-in exponential backoff khi gặp HTTP 429. Collector không cần quan tâm chi tiết này (separation of concerns).

- *Error handling:* Nếu một job fail (e.g., keyword không có results), Collector increment `errors` counter nhưng vẫn tiếp tục các jobs khác. Failure của 1 job không làm fail toàn bộ Project.

==== Part 3: Analytics Pipeline

#figure(
  image("../images/sequence/uc3_execute_part_3.png", width: 100%),
  caption: [
    Sequence Diagram UC-03 (Part 3/4): Analytics Pipeline Processing.
    Analytics Service consume data.collected events, download batches từ MinIO, chạy 5-step pipeline (preprocessing, intent, keywords, sentiment, impact), và save vào PostgreSQL với crisis detection.
  ],
) <fig:uc03_part3_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 3_])
#image_counter.step()

*Các bước chính trong Part 3:*

+ *Event Consumption (Step 21):* Analytics Service consume `data.collected` events từ RabbitMQ. Service có multiple consumers (e.g., 5 workers) để process batches parallel.

+ *MinIO Download (Step 22):* Download batch JSON từ MinIO. File size typically 1-5 MB (20-50 items × ~50-100 KB/item với full metadata).

+ *Analytics Pipeline (Step 23):* Mỗi post trong batch đi qua 5-step pipeline:

  *Step 1 - Preprocessing:*
  - Merge text sources: caption + transcription (nếu có) + top 10 comments
  - Normalize Vietnamese: convert teencode ("k", "ko" → "không"), remove excessive emojis
  - Compute noise stats: spam probability, text length, hashtag density

  *Step 2 - Intent Classification:*
  - Classify post intent: REVIEW, COMPLAINT, CRISIS, SEEDING
  - Pattern matching + LLM (if available)
  - Produce `should_skip` signal cho spam/seeding posts

  *Step 3 - Keyword Extraction:*
  - Hybrid approach: dictionary matching + YAKE algorithm
  - Extract keywords với confidence scores
  - Map keywords to aspects (e.g., "pin kém" → aspect "Pin")

  *Step 4 - Sentiment Analysis:*
  - PhoBERT-based multi-label classification
  - Overall sentiment: VERY_POSITIVE, POSITIVE, NEUTRAL, NEGATIVE, VERY_NEGATIVE
  - Aspect-level sentiment: per-aspect sentiment breakdown

  *Step 5 - Impact Calculation:*
  - Engagement score: `(likes + comments + shares) / views`
  - Reach score: `follower_count × (is_verified ? 1.5 : 1.0)`
  - Combine với sentiment và velocity:
    ```
    impact_score = (engagement × 0.3 + reach × 0.3 +
                    sentiment_weight × 0.2 + velocity × 0.2) × 100
    ```
  - Determine risk level: CRITICAL (≥80), HIGH (60-80), MEDIUM (40-60), LOW (\<40)

+ *Database Persistence (Step 24):* Batch INSERT vào `post_analytics` table (20-50 rows/transaction). PostgreSQL JSONB columns lưu:
  - `aspects_breakdown`: array of `{name, sentiment, confidence}`
  - `keywords`: array of extracted keywords
  - `sentiment_probabilities`: model output probabilities
  - `impact_breakdown`: detailed impact components

+ *Crisis Detection (Step 25):* Sau khi save, system check từng post:
  ```
  if (primary_intent == "CRISIS" &&
      overall_sentiment in ["NEGATIVE", "VERY_NEGATIVE"] &&
      risk_level in ["HIGH", "CRITICAL"]) {
    trigger_crisis_alert()
  }
  ```

  *Crisis alert* publish separate `crisis.detected` event với payload chứa post details để WebSocket Service notify user immediately.

+ *Acknowledge (Step 26):* ACK RabbitMQ message để confirm batch đã được processed successfully. Nếu processing fail, message sẽ được requeued (với retry limit).

*Điểm kỹ thuật quan trọng:*

- *Pipeline orchestration:* `AnalyticsOrchestrator` class coordinate toàn bộ 5 steps, handle errors gracefully, và log processing time per step cho monitoring.

- *Skip logic optimization:* Posts được classify là spam/seeding sẽ skip steps 3-5 (keyword extraction, sentiment, impact). Chỉ persist minimal record với `overall_sentiment = NEUTRAL`, `impact_score = 0`. Điều này save ~70% compute time cho noise posts.

- *Batch processing:* Process 20-50 posts trong 1 transaction thay vì 50 separate transactions. PostgreSQL performance cải thiện drastically (10-20x faster).

- *Model caching:* PhoBERT model (1.3 GB) được load vào RAM lúc startup và reuse cho mọi requests. Warm-up time ~5 seconds nhưng inference chỉ ~100ms/post (on GPU) hoặc ~300ms/post (on CPU).

- *Error isolation:* Nếu 1 post trong batch fail (e.g., malformed JSON), skip post đó nhưng tiếp tục process remaining posts. Failure của 1 post không làm fail cả batch.

==== Part 4: Completion & Notification

#figure(
  image("../images/sequence/uc3_execute_part_4.png", width: 100%),
  caption: [
    Sequence Diagram UC-03 (Part 4/4): Project Completion & User Notification.
    Collector detect completion (done == total), update PostgreSQL status, call progress webhook, Project Service publish notification qua Redis Pub/Sub để WebSocket deliver đến user.
  ],
) <fig:uc03_part4_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 4_])
#image_counter.step()

*Các bước chính trong Part 4:*

+ *Completion Detection (Step 27):* Collector periodically (mỗi 10 giây hoặc sau mỗi batch) check Redis state:
  ```
  HGETALL smap:proj:{id}
  ```

  Compare `done` vs `total`. Nếu `done >= total`, project đã complete.

+ *Status Finalization (Step 28):* Collector update Redis:
  ```
  HSET smap:proj:{id} status "DONE"
  ```

+ *Progress Callback (Step 29):* Collector gọi webhook `POST /internal/progress/callback` với payload:
  ```json
  {
    "project_id": "...",
    "user_id": "...",
    "status": "DONE",
    "total": 180,
    "done": 180,
    "errors": 5
  }
  ```

+ *PostgreSQL Status Update (Step 30):* Project Service update Project status từ `process` → `completed` trong PostgreSQL. Đây là final state transition, marking project as ready for viewing.

+ *Redis Pub/Sub Notification (Step 31):* Project Service publish message đến Redis Pub/Sub channel:
  ```
  channel: project:{project_id}:{user_id}
  message: {
    "type": "project_completed",
    "project_id": "...",
    "message": "Project analysis completed successfully!",
    "stats": {
      "total_posts": 2847,
      "processing_time": "18 minutes"
    }
  }
  ```

+ *User Polling (Step 32):* Web UI đang polling `/projects/:id/progress` mỗi 5 giây. Khi detect `status = "DONE"`, hiển thị success notification và start 5-second countdown redirect đến Dashboard.

*Điểm kỹ thuật quan trọng:*

- *Eventual consistency:* Có delay nhỏ (< 10 giây) giữa lúc last batch complete và lúc Collector detect completion. Đây là trade-off chấp nhận được để avoid constant polling overhead.

- *Webhook vs Polling:* Hệ thống sử dụng *hybrid approach*:
  - Webhook (push) cho backend-to-backend communication (Collector → Project Service)
  - Polling (pull) cho frontend-to-backend (Web UI → Project API)

  Webhook faster và more efficient cho server-side, nhưng polling reliable hơn cho client-side (avoid WebSocket complexity ở bước này).

- *Notification routing:* Redis Pub/Sub pattern `project:{project_id}:{user_id}` đảm bảo message chỉ được deliver đến đúng user. WebSocket Service subscribe pattern `project:*:{user_id}` để receive tất cả projects của user.

- *Failure handling:* Nếu webhook fail (Project Service down), Collector sẽ retry với exponential backoff (3 lần). Nếu vẫn fail, Collector log error nhưng vẫn mark project as done trong Redis. User vẫn có thể thấy kết quả khi Project Service recover (vì PostgreSQL state consistent).

- *Cleanup strategy:* Redis state với TTL 7 days sẽ tự động expire. PostgreSQL Project record được giữ permanently (hoặc theo retention policy của organization).

=== 4.7.4 UC-04: Xem kết quả phân tích

Sau khi Project hoàn tất (status = `completed`), Marketing Analyst truy cập Dashboard để xem tổng quan và drilldown vào chi tiết. UC-04 mô tả quy trình truy vấn dữ liệu phân tích từ PostgreSQL, aggregating statistics, và hiển thị insights theo multiple dimensions (sentiment, aspects, competitors, time-series).

Điểm đặc biệt của UC này là việc sử dụng *PostgreSQL JSONB operators* để query nested data structures hiệu quả, kết hợp với *multi-level aggregations* để tạo ra dashboard insights phong phú. Sequence diagram được chia thành 2 phần: Part 1 cho Overview Dashboard, Part 2 cho Drilldown Details.

==== Part 1: Overview Dashboard

#figure(
  image("../images/sequence/uc4_result_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-04 (Part 1/2): Overview Dashboard.
    User truy cập Project Dashboard, hệ thống fetch aggregated statistics từ PostgreSQL bao gồm sentiment distribution, aspect breakdown, competitor comparison, và time-series trends.
  ],
) <fig:uc04_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *Page Load (Steps 1-2):* User navigate đến `/dashboard/project/:id`. Web UI gửi GET request đến `/projects/:id/dashboard` để fetch overview statistics.

+ *Project Metadata (Step 3):* Project API query PostgreSQL để lấy thông tin cơ bản:
  ```sql
  SELECT id, name, status, from_date, to_date,
         brand_keywords, competitor_keywords, created_at
  FROM projects WHERE id = $1 AND created_by = $2
  ```

  Ownership verification được thực hiện implicit qua `created_by` filter.

+ *Overall Statistics (Step 4):* Aggregation query để tính KPIs tổng quan:
  ```sql
  SELECT
    COUNT(*) as total_posts,
    AVG(impact_score) as avg_impact,
    SUM(CASE WHEN risk_level IN ('HIGH','CRITICAL') THEN 1 ELSE 0 END) as crisis_count,
    AVG(engagement_rate) as avg_engagement
  FROM post_analytics
  WHERE project_id = $1
  ```

+ *Sentiment Distribution (Step 5):* Query phân bố sentiment:
  ```sql
  SELECT overall_sentiment, COUNT(*) as count
  FROM post_analytics
  WHERE project_id = $1
  GROUP BY overall_sentiment
  ORDER BY count DESC
  ```

  Kết quả dạng: `{POSITIVE: 1200, NEUTRAL: 800, NEGATIVE: 300, ...}` để render pie chart.

+ *Aspect Breakdown (Step 6):* Sử dụng JSONB operators để extract và aggregate aspects:
  ```sql
  SELECT
    aspect->>'name' as aspect_name,
    COUNT(*) as mention_count,
    AVG((aspect->>'sentiment_score')::float) as avg_sentiment
  FROM post_analytics,
       jsonb_array_elements(aspects_breakdown) as aspect
  WHERE project_id = $1
  GROUP BY aspect->>'name'
  ORDER BY mention_count DESC
  LIMIT 10
  ```

  Trả về top 10 aspects được mention nhiều nhất với sentiment score trung bình.

+ *Competitor Comparison (Step 7):* Query để so sánh thương hiệu chính vs đối thủ:
  ```sql
  SELECT
    competitor_name,
    COUNT(*) as post_count,
    AVG(overall_sentiment_score) as avg_sentiment,
    AVG(impact_score) as avg_impact
  FROM post_analytics
  WHERE project_id = $1
  GROUP BY competitor_name
  ORDER BY post_count DESC
  ```

+ *Time-series Trend (Step 8):* Query sentiment trend theo thời gian:
  ```sql
  SELECT
    DATE_TRUNC('day', published_at) as date,
    overall_sentiment,
    COUNT(*) as count
  FROM post_analytics
  WHERE project_id = $1
  GROUP BY date, overall_sentiment
  ORDER BY date ASC
  ```

  Data này được sử dụng để render line chart showing sentiment evolution over time.

+ *Response Aggregation (Step 9):* Project API tổng hợp tất cả statistics vào single response object:
  ```json
  {
    "project": {...},
    "kpis": {total_posts, avg_impact, crisis_count, ...},
    "sentiment_distribution": [...],
    "top_aspects": [...],
    "competitor_comparison": [...],
    "time_series": [...]
  }
  ```

+ *Dashboard Rendering (Step 10):* Web UI render full dashboard với:
  - KPI cards (4 metrics)
  - Sentiment pie chart
  - Aspect breakdown bar chart
  - Competitor comparison table
  - Time-series line chart

*Điểm kỹ thuật quan trọng:*

- *JSONB performance:* PostgreSQL JSONB operators (`->`, `->>`, `@>`) với GIN indexes cho phép query nested structures hiệu quả. Query time ~50-200ms cho projects với 10K+ posts.

- *Single request:* Tất cả statistics được fetch trong 1 API call (với multiple DB queries parallel) thay vì multiple API calls. Điều này giảm network latency và improve UX.

- *Date truncation:* `DATE_TRUNC('day', ...)` cho phép flexible time-series aggregation. Có thể switch sang 'hour', 'week', 'month' based on date range.

- *Caching opportunity:* Dashboard data có thể cache trong Redis với TTL 5-10 phút vì insights không cần real-time updates sau khi project completed.

==== Part 2: Drilldown Details

#figure(
  image("../images/sequence/uc4_result_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-04 (Part 2/2): Drilldown vào chi tiết posts.
    User click vào aspect hoặc competitor để xem danh sách posts liên quan, sau đó click vào post cụ thể để xem full details bao gồm comments, aspect breakdown, và impact breakdown.
  ],
) <fig:uc04_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Aspect Drilldown (Steps 16-17):* User click vào aspect "Giá cả". Web UI gửi request `/projects/:id/posts?aspect=Giá cả&page=1&limit=20`.

+ *Posts Query with Filters (Step 18):* PostgreSQL query với JSONB containment operator:
  ```sql
  SELECT id, title, author, platform, published_at,
         overall_sentiment, impact_score, engagement_rate
  FROM post_analytics
  WHERE project_id = $1
    AND aspects_breakdown @> '[{"name": "Giá cả"}]'
  ORDER BY impact_score DESC
  LIMIT 20 OFFSET 0
  ```

  `@>` operator kiểm tra JSONB array có chứa object với `name = "Giá cả"` hay không. GIN index trên `aspects_breakdown` column tăng tốc query drastically.

+ *Posts List Display (Step 19):* Web UI render danh sách posts với:
  - Title + thumbnail
  - Sentiment badge (color-coded)
  - Impact score (with risk level indicator)
  - Quick link to original post

+ *Post Details Request (Steps 19-20):* User click vào 1 post. Web UI request `/posts/:post_id/details`.

+ *Full Post Data (Step 21):* Query toàn bộ data của post:
  ```sql
  SELECT * FROM post_analytics WHERE id = $1
  ```

  Trả về tất cả fields bao gồm:
  - Content: caption, transcription
  - Metrics: views, likes, comments, shares, saves
  - Analytics: sentiment probabilities, keywords, aspects breakdown, impact breakdown
  - Metadata: platform, author, published_at, url

+ *Comments Fetch (Step 22):* Query top comments của post (nếu có):
  ```sql
  SELECT content, author, likes, sentiment, published_at
  FROM comments
  WHERE post_id = $1
  ORDER BY likes DESC
  LIMIT 50
  ```

  Comments cũng được analyze sentiment để hiển thị sentiment distribution in comments.

+ *Modal Display (Step 23):* Web UI hiển thị modal với:
  - Full content (caption + transcription)
  - Aspect-level sentiment breakdown (bar chart)
  - Keywords extracted
  - Impact breakdown (engagement, reach, sentiment, velocity components)
  - Top 50 comments với sentiment
  - Action buttons: "Đánh dấu đã xử lý", "Chia sẻ", "Export"

*Điểm kỹ thuật quan trọng:*

- *JSONB containment:* Operator `@>` cho phép filter posts by aspect name efficiently. Alternative: `EXISTS(SELECT 1 FROM jsonb_array_elements(aspects_breakdown) WHERE elem->>'name' = 'Giá cả')` nhưng slower.

- *Pagination:* LIMIT/OFFSET được sử dụng cho pagination. Với large datasets (10K+ posts), có thể optimize bằng cursor-based pagination (`WHERE id > last_id`).

- *Lazy loading:* Comments chỉ được fetch khi user click vào post, không fetch upfront cho tất cả posts. Điều này tiết kiệm bandwidth và DB load.

- *Sentiment visualization:* Aspect-level sentiment được render dưới dạng horizontal bar chart với color gradient (red → yellow → green) để dễ nhìn.

- *Deep linking:* URL chứa `?post_id=xxx` để support shareable links. User có thể copy URL và chia sẻ với team members.

=== 4.7.5 UC-06: Cập nhật tiến độ Real-time

UC-06 mô tả cơ chế real-time progress tracking qua WebSocket connection. Đây là tính năng quan trọng giúp user theo dõi tiến độ xử lý Project mà không cần refresh page, tạo trải nghiệm UX mượt mà và professional.

Hệ thống sử dụng *Redis Pub/Sub* làm message bus để broadcast progress updates từ backend services (Collector, Analytics) đến WebSocket Service, sau đó deliver đến connected clients. Sequence diagram được chia thành 3 phần: Part 1 cho Connection Setup, Part 2 cho Progress Updates, Part 3 cho Completion & Disconnection.

==== Part 1: WebSocket Connection Setup

#figure(
  image("../images/sequence/uc6_export_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-06 (Part 1/3): WebSocket Connection Setup.
    User mở Project Processing page, Web UI establish WebSocket connection với authentication, WebSocket Service verify token và subscribe Redis channel pattern để receive project updates.
  ],
) <fig:uc06_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *Page Load (Steps 1-2):* User navigate đến Project Processing page (`/projects/:id/processing`). Web UI render progress UI với initial state: "Đang khởi tạo...".

+ *WebSocket Handshake (Step 3):* Web UI initiate WebSocket connection đến `wss://api.smap.com/ws`. Connection được upgrade từ HTTP/1.1 sang WebSocket protocol.

+ *Authentication (Step 4):* Ngay sau khi connection established, client gửi auth message:
  ```json
  {
    "type": "auth",
    "token": "eyJhbGc...",  // JWT token
    "project_id": "..."
  }
  ```

+ *Token Verification (Steps 5-6):* WebSocket Service verify JWT token:
  - Decode token để extract `user_id`
  - Verify signature với secret key
  - Check expiration time
  - Optionally: query Redis để check token không bị revoked

  Nếu token invalid → close connection với code 4001 "Unauthorized".

+ *Redis Channel Subscription (Step 7):* WebSocket Service subscribe Redis Pub/Sub channel pattern:
  ```
  PSUBSCRIBE project:{project_id}:{user_id}
  ```

  Pattern subscription cho phép receive tất cả messages published đến channel này. Chỉ messages của đúng project và đúng user mới được deliver (security by design).

+ *Subscription Confirmation (Step 8):* WebSocket Service gửi confirmation message đến client:
  ```json
  {
    "type": "subscribed",
    "project_id": "...",
    "message": "Successfully subscribed to project updates"
  }
  ```

+ *Initial State Display (Step 9):* Web UI hiển thị progress bar với initial message: "Đang xử lý... 0%".

*Điểm kỹ thuật quan trọng:*

- *WebSocket over HTTPS:* Production sử dụng WSS (WebSocket Secure) để encrypt traffic. Tránh downgrade attacks.

- *JWT in WebSocket:* Token được gửi qua WebSocket message (không phải WebSocket URL query param) để avoid token leakage in logs/browser history.

- *Pattern subscription:* Redis PSUBSCRIBE cho phép subscribe multiple projects của cùng user với single subscription: `project:*:{user_id}`. Tuy nhiên, hiện tại chỉ subscribe single project để simplicity.

- *Connection pooling:* WebSocket Service maintain connection pool (e.g., 10K concurrent connections per instance). Sử dụng Goroutines (Go) hoặc async I/O (Node.js) để handle concurrent connections efficiently.

- *Heartbeat mechanism:* WebSocket Service gửi PING frames mỗi 30 giây để detect dead connections. Client respond với PONG. Nếu 3 PINGs không có PONG → close connection.

==== Part 2: Progress Updates

#figure(
  image("../images/sequence/uc6_export_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-06 (Part 2/3): Real-time Progress Updates.
    Collector và Analytics Services publish progress updates vào Redis Pub/Sub, WebSocket Service receive và broadcast đến connected client với throttling mechanism để avoid overwhelming.
  ],
) <fig:uc06_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Progress Event from Collector (Step 10):* Sau mỗi crawl job hoàn thành, Collector update Redis state và publish progress message:
  ```
  PUBLISH project:{project_id}:{user_id} {
    "type": "progress",
    "phase": "CRAWLING",
    "done": 1,
    "total": 120,
    "percentage": 0.8,
    "message": "Đã thu thập 1/120 items"
  }
  ```

+ *Message Propagation (Steps 11-12):* Redis Pub/Sub deliver message đến WebSocket Service (subscribed client). WebSocket Service receive message từ Redis.

+ *Throttling Logic (Step 13):* Trước khi forward message đến client, WebSocket Service apply throttling:
  ```go
  // Only send if > 500ms since last message
  if time.Since(lastSent) < 500*time.Millisecond {
    return // Skip this message
  }
  ```

  Throttling prevents overwhelming client với quá nhiều messages (e.g., 120 jobs → 120 messages trong vài giây). Client chỉ nhận updates mỗi 500ms, đủ cho smooth progress bar animation.

+ *WebSocket Message (Step 14):* WebSocket Service forward message đến client qua WebSocket connection.

+ *UI Update (Step 15):* Web UI handle message:
  - Update progress bar percentage: `progress = done / total × 100%`
  - Update phase indicator: highlight "Thu thập dữ liệu" phase
  - Display current message: "Đã thu thập 1/120 items (0.8%)"
  - Optionally: update estimated time remaining

+ *Repeated Updates (Steps 16-17):* Process repeats cho mỗi progress update. Khi phase transition (CRAWLING → PROCESSING), message type vẫn là "progress" nhưng `phase` field changes.

*Điểm kỹ thuật quan trọng:*

- *Redis Pub/Sub scalability:* Redis Pub/Sub không persist messages. Nếu WebSocket Service down lúc message được publish, message sẽ lost. Trade-off này acceptable vì progress updates không critical (user có thể refresh).

- *Throttling strategies:*
  - *Time-based:* Chỉ send message mỗi 500ms (current implementation)
  - *Percentage-based:* Chỉ send khi percentage change ≥ 1%
  - *Hybrid:* Combine cả hai approaches

- *Message ordering:* Redis Pub/Sub đảm bảo messages được deliver theo order. Tuy nhiên, nếu có multiple WebSocket instances với load balancer, message order có thể không guaranteed cross-instance.

- *Backpressure handling:* Nếu client slow (e.g., tab inactive, slow network), WebSocket send buffer có thể full. WebSocket Service detect và skip messages hoặc close connection để avoid memory leak.

- *Progressive enhancement:* Nếu WebSocket connection fail, Web UI fallback về polling mechanism (query `/projects/:id/progress` mỗi 5 giây).

==== Part 3: Completion & Disconnection

#figure(
  image("../images/sequence/uc6_export_part_3.png", width: 100%),
  caption: [
    Sequence Diagram UC-06 (Part 3/3): Project Completion & Connection Cleanup.
    Project hoàn tất, WebSocket Service deliver completion notification, Web UI redirect user đến Dashboard, và cleanup WebSocket connection.
  ],
) <fig:uc06_part3_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 3_])
#image_counter.step()

*Các bước chính trong Part 3:*

+ *Completion Message (Steps 18-19):* Khi Project hoàn tất, Project Service publish completion message:
  ```json
  {
    "type": "project_completed",
    "project_id": "...",
    "status": "COMPLETED",
    "message": "Phân tích hoàn tất!",
    "stats": {
      "total_posts": 2847,
      "processing_time": "18 minutes",
      "avg_sentiment": 0.65
    }
  }
  ```

+ *Final Update (Steps 20-21):* Web UI handle completion message:
  - Update progress bar to 100%
  - Show success notification: "✅ Phân tích hoàn tất!"
  - Display final statistics
  - Start 5-second countdown: "Chuyển đến Dashboard trong 5s..."

+ *Auto-redirect (Step 22):* Sau 5 giây, Web UI navigate đến Dashboard page: `window.location.href = '/dashboard/project/:id'`.

+ *Connection Cleanup (Steps 23-25):* Khi user navigate away (hoặc close tab):
  - Web UI send WebSocket close frame với code 1000 "Normal Closure"
  - WebSocket Service receive close frame
  - WebSocket Service cleanup:
    - Unsubscribe Redis channel: `PUNSUBSCRIBE project:{project_id}:{user_id}`
    - Remove connection từ connection pool
    - Close underlying TCP connection
  - Connection terminated gracefully

*Điểm kỹ thuật quan trọng:*

- *Graceful closure:* WebSocket close codes follow RFC 6455:
  - 1000: Normal closure (user navigated away)
  - 1001: Going away (browser tab closed)
  - 4001: Unauthorized (auth failed)
  - 4008: Policy violation (rate-limit exceeded)

- *Resource cleanup:* WebSocket Service MUST unsubscribe Redis channels khi connection close để avoid memory leaks. Redis track subscribers per channel.

- *Automatic reconnection:* Nếu connection bị dropped unexpectedly (network issue), Web UI tự động reconnect với exponential backoff (1s, 2s, 4s, 8s, max 30s).

- *State synchronization:* Sau reconnect, Web UI query `/projects/:id/progress` để sync latest state trước khi continue listening WebSocket updates.

- *Connection limits:* WebSocket Service enforce per-user connection limit (e.g., max 10 concurrent connections) để prevent abuse.

=== 4.7.6 UC-07: Phát hiện trend tự động

UC-07 mô tả quy trình tự động phát hiện trending topics trên TikTok và YouTube thông qua Kubernetes CronJob chạy hàng ngày. Đây là tính năng giúp Marketing Analysts stay updated với latest trends để adjust campaign strategies kịp thời.

Hệ thống crawl trending data từ platform APIs, normalize metadata, calculate trend scores dựa trên engagement rate và velocity, sau đó lưu vào PostgreSQL và notify users. Sequence diagram được chia thành 3 phần: Part 1 cho Cron Trigger & Crawling, Part 2 cho Scoring & Storage, Part 3 cho User Views Trends.

==== Part 1: Cron Trigger & Crawling

#figure(
  image("../images/sequence/uc7_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-07 (Part 1/3): Cron Trigger & Trend Crawling.
    Kubernetes CronJob trigger Trend Service hàng ngày lúc 2:00 AM, Trend Service request trending data từ TikTok và YouTube Crawler Services với error handling cho rate-limits.
  ],
) <fig:uc07_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *Cron Schedule (Step 1):* Kubernetes CronJob với schedule `0 2 * * *` (daily at 2:00 AM UTC) trigger Trend Service. Thời điểm 2:00 AM được chọn vì:
  - Low traffic period (ít ảnh hưởng đến production workload)
  - Sau khi daily trends đã stabilize (trends thường peak vào ~10 PM - 1 AM)

+ *Create Trend Run (Steps 2-3):* Trend Service tạo record trong `trend_runs` table để tracking:
  ```sql
  INSERT INTO trend_runs (id, timestamp, platforms, status, is_partial_result)
  VALUES (uuid_generate_v4(), NOW(), ['tiktok', 'youtube'], 'INITIALIZING', false)
  RETURNING id
  ```

  `is_partial_result` flag được set false initially. Nếu một platform fail, flag sẽ được update thành true.

+ *Redis State Initialization (Step 4):* Set Redis key để tracking job progress:
  ```
  SET trend:run:{run_id}:status "RUNNING" EX 7200
  ```

  TTL 7200 seconds (2 hours) là timeout cho job. Nếu job chạy quá 2 giờ, Redis key expire và job được consider failed.

+ *TikTok Trends Request (Steps 5-6):* Trend Service request TikTok Crawler:
  ```
  GET /tiktok/trends?type=music,hashtag,keyword
  ```

  Crawler call TikTok Discover API để fetch:
  - Trending music tracks
  - Trending hashtags
  - Trending keywords/challenges

+ *Rate-limit Handling (Steps 7-9):* Nếu TikTok API trả về `429 Too Many Requests`:
  ```json
  {
    "error": "Rate limit exceeded",
    "retry_after": 300  // seconds
  }
  ```

  Trend Service apply exponential backoff:
  - 1st retry: Wait 5 minutes
  - 2nd retry: Wait 10 minutes
  - 3rd retry: Wait 20 minutes

  Nếu vẫn fail sau 3 retries → update `is_partial_result = true`, `failed_platforms = ['tiktok']`, skip TikTok và continue với YouTube.

+ *TikTok Trends Response (Step 10):* Crawler trả về normalized trends:
  ```json
  [
    {
      "type": "music",
      "title": "Song X",
      "views": 15000000,
      "likes": 2000000,
      "shares": 500000,
      "velocity": 1.20  // +120% growth in 24h
    },
    {
      "type": "hashtag",
      "title": "#ChallengeName",
      "views": 8000000,
      "posts": 50000,
      "velocity": 0.85
    }
    // ... more trends
  ]
  ```

+ *YouTube Trends Request (Steps 11-13):* Tương tự với YouTube:
  ```
  GET /youtube/trends?category=all
  ```

  Crawler call YouTube Trending API để fetch trending videos và topics.

*Điểm kỹ thuật quan trọng:*

- *Cron vs Event-driven:* Trend detection sử dụng cron-based trigger vì là scheduled job. Khác với UC-03 (event-driven) vì không có user action trigger.

- *Platform independence:* Nếu một platform fail, job vẫn continue với remaining platforms. Partial results vẫn valuable hơn no results.

- *Rate-limit strategy:* Exponential backoff với jitter (random delay) để avoid thundering herd. TikTok/YouTube APIs có strict rate-limits (e.g., 100 requests/hour).

- *Graceful degradation:* `is_partial_result` flag cho phép user biết data không complete. UI hiển thị warning: "⚠️ Trends from TikTok unavailable due to rate-limit".

- *Idempotency:* Nếu Cron job trigger multiple times (Kubernetes restart), check Redis `trend:run:{date}:status` trước khi start new run để avoid duplicates.

==== Part 2: Scoring & Storage

#figure(
  image("../images/sequence/uc7_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-07 (Part 2/3): Trend Scoring & Storage.
    Trend Service normalize metadata, calculate trend scores dựa trên engagement rate và velocity, rank và filter top trends, sau đó batch insert vào PostgreSQL và cache latest run_id trong Redis.
  ],
) <fig:uc07_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Metadata Normalization (Step 14):* Trend Service normalize heterogeneous data từ TikTok/YouTube thành unified schema:
  ```go
  type Trend struct {
    Platform    string    // "tiktok" | "youtube"
    Type        string    // "music" | "hashtag" | "keyword" | "video"
    Title       string
    Views       int64
    Likes       int64
    Comments    int64
    Shares      int64
    Saves       int64
    Velocity    float64   // Growth rate (24h)
    Timestamp   time.Time
  }
  ```

+ *Score Calculation (Step 15):* Calculate trend score cho mỗi item:
  ```
  engagement_rate = (likes + comments + shares) / views
  score = engagement_rate × velocity × 100
  ```

  *Rationale:*
  - `engagement_rate`: Measures quality of engagement (high engagement = resonates với audience)
  - `velocity`: Measures growth momentum (high velocity = trending up fast)
  - Multiply cả hai để balance giữa "currently popular" và "rising fast"

  *Example:*
  - Song A: 10M views, 2M likes, velocity +120% → engagement=0.2, score=24
  - Song B: 1M views, 300K likes, velocity +300% → engagement=0.3, score=90
  - Song B có score cao hơn vì velocity cao (early trend detection)

+ *Ranking & Filtering (Step 16):*
  - Sort trends by score DESC
  - Filter top 50 per platform (100 total for 2 platforms)
  - Deduplicate: nếu cùng title/music xuất hiện trên cả TikTok và YouTube → merge và keep highest score
  - Classify by type: separate music, hashtag, keyword, video

+ *Batch Insert (Step 17):* Insert 100 trends vào PostgreSQL trong single transaction:
  ```sql
  INSERT INTO trends
    (run_id, platform, type, title, score, views, likes,
     shares, velocity, metadata, created_at)
  VALUES
    ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW()),
    ... (100 rows)
  ```

  Batch insert thay vì 100 separate INSERTs cải thiện performance ~50x.

+ *Finalize Trend Run (Step 18):* Update `trend_runs` status:
  ```sql
  UPDATE trend_runs
  SET status = 'COMPLETED',
      completed_at = NOW(),
      total_trends = 100
  WHERE id = $1
  ```

+ *Cache Latest Run (Steps 19-20):* Cache `run_id` trong Redis để tăng tốc queries:
  ```
  SET trend:latest {run_id} EX 86400
  ```

  TTL 86400 seconds (24 hours) match với cron frequency. Next run sẽ overwrite key này.

+ *Cleanup Temp State (Step 21):* Delete temporary Redis key:
  ```
  DEL trend:run:{run_id}:status
  ```

+ *User Notification (Steps 22-24):* Trend Service gọi Notification Service để broadcast:
  ```json
  {
    "type": "trend_update",
    "message": "Trends mới đã được cập nhật",
    "run_id": "...",
    "total_trends": 100
  }
  ```

  Notification Service send in-app notification đến tất cả Marketing Analysts. Optionally, send email digest với top 10 trends.

*Điểm kỹ thuật quan trọng:*

- *Score formula tuning:* Weights cho engagement_rate và velocity có thể adjust based on empirical data. Future: add time decay factor để prioritize recent trends.

- *Deduplication logic:* Cross-platform deduplication complex vì title formats khác nhau. Example: "Song X - Artist Y" (YouTube) vs "Song X" (TikTok). Sử dụng fuzzy matching (Levenshtein distance < 3).

- *Metadata JSONB:* `metadata` column (JSONB) lưu platform-specific data (e.g., TikTok `music_id`, YouTube `video_id`) để support deep links.

- *Historical comparison:* Future enhancement: so sánh với trends từ previous days để detect "rising stars" (new entries in top 50) vs "fading trends" (dropped out).

==== Part 3: User Views Trends

#figure(
  image("../images/sequence/uc7_part_3.png", width: 100%),
  caption: [
    Sequence Diagram UC-07 (Part 3/3): User Views Trend Dashboard.
    User mở Trend Dashboard, hệ thống fetch latest trends từ Redis cache và PostgreSQL, hiển thị với filters. User click vào trend cụ thể để xem details và related posts từ own projects.
  ],
) <fig:uc07_part3_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 3_])
#image_counter.step()

*Các bước chính trong Part 3:*

+ *Dashboard Access (Steps 25-26):* User navigate đến `/trends` page. Web UI request `GET /api/trends?run_id=latest`.

+ *Fetch Latest Run ID (Steps 27-28):* Trend Service query Redis cache:
  ```
  GET trend:latest
  ```

  Redis trả về `run_id` của latest completed run. Cache hit ~99% (vì trends chỉ update daily).

+ *Fetch Trends (Steps 29-30):* Query PostgreSQL với filters:
  ```sql
  SELECT * FROM trends
  WHERE run_id = $1
  ORDER BY score DESC
  LIMIT 50
  ```

  User có thể apply filters:
  - Platform: TikTok only, YouTube only, or All
  - Type: Music, Hashtag, Keyword, Video
  - Date: Latest, Yesterday, Last 7 days
  - Min score: ≥ 50, ≥ 70, ≥ 90

+ *Display Dashboard (Step 31):* Web UI render Trend Dashboard với:
  - Grid layout: 2 columns × 25 rows
  - Each trend card shows: title, platform badge, score, views, velocity indicator
  - Sort by score DESC (highest impact trends first)
  - Filter sidebar với dropdowns

+ *Trend Details (Steps 32-33):* User click vào trend "Song X". Web UI request `GET /api/trends/{trend_id}/details`.

+ *Fetch Trend Details (Step 34):* Query full trend data:
  ```sql
  SELECT * FROM trends WHERE id = $1
  ```

+ *Fetch Related Posts (Step 35):* Query posts từ user's own projects có chứa trend keyword:
  ```sql
  SELECT * FROM post_analytics
  WHERE created_by = $1  -- user's projects only
    AND keywords @> '["Song X"]'
  ORDER BY published_at DESC
  LIMIT 10
  ```

  Điều này giúp user correlate external trends với own brand mentions.

+ *Modal Display (Step 36):* Web UI hiển thị modal với:
  - Trend metadata: views, likes, score, velocity
  - Growth chart: 7-day trend line (nếu có historical data)
  - Related posts từ user's projects (top 10)
  - Action buttons:
    - "Thêm vào Project" (add keyword to existing project)
    - "Tạo Project mới" (quick-create project với trend as keyword)
    - "Xem trên Platform" (deep link đến TikTok/YouTube)

*Điểm kỹ thuật quan trọng:*

- *Cache-first architecture:* Redis cache (`trend:latest`) được check đầu tiên. PostgreSQL chỉ được query khi cache miss (e.g., first request after cron job).

- *Cross-project insights:* Related posts query cho phép user thấy brand của mình có mention trending topics hay không. Nếu có → opportunity để amplify. Nếu không → consider joining trend.

- *Actionable insights:* Modal không chỉ show data mà còn provide actions (add to project, create project). Điều này tăng value của trend detection feature.

- *Historical tracking:* Future: lưu daily snapshots để track trend evolution. Example: "Song X peaked at score 95 on 2024-03-15, now declining to 70".

- *Personalization:* Future: recommend trends based on user's industry/keywords. Example: nếu user có nhiều projects về "xe điện" → prioritize trending hashtags liên quan.

=== 4.7.7 UC-08: Phát hiện khủng hoảng

UC-08 là Use Case quan trọng nhất về mặt business value, mô tả cơ chế tự động phát hiện và cảnh báo các bài viết có nguy cơ gây khủng hoảng thương hiệu (brand crisis). Hệ thống sử dụng *triple-check logic* (Intent + Sentiment + Impact) để identify crisis posts với độ chính xác cao, sau đó trigger real-time alerts đến Marketing Analysts.

Sequence diagram được chia thành 4 phần: Part 1 cho Analytics Pipeline & Detection, Part 2 cho Crisis Alert Publishing, Part 3 cho User Receives Alert, Part 4 cho Crisis Dashboard & Response.

==== Part 1: Analytics Pipeline & Crisis Detection

#figure(
  image("../images/sequence/uc8_part_1.png", width: 100%),
  caption: [
    Sequence Diagram UC-08 (Part 1/4): Analytics Pipeline & Crisis Detection Logic.
    Analytics Service chạy full pipeline cho post, sau khi save vào PostgreSQL, check triple-check criteria (Intent=CRISIS && Sentiment=NEGATIVE && Impact=HIGH/CRITICAL) để detect crisis.
  ],
) <fig:uc08_part1_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 1_])
#image_counter.step()

*Các bước chính trong Part 1:*

+ *Data Collection (Steps 1-2):* Analytics Service receive `data.collected` event từ Collector, download batch từ MinIO (đã mô tả chi tiết trong UC-03 Part 3).

+ *Step 1: Preprocessing (Step 3):* Merge caption + transcription + top comments, normalize Vietnamese text. Output: `full_text` với ~500-2000 words.

+ *Step 2: Intent Classification (Steps 4-5):* Intent Classifier analyze `full_text`:
  ```python
  def classify_intent(text: str) -> Intent:
      # Pattern matching cho crisis keywords
      crisis_keywords = ["lỗi nghiêm trọng", "gian lận", "kiện",
                         "tẩy chay", "đòi bồi thường", ...]

      # LLM-based classification (if available)
      intent = llm.classify(text, labels=["REVIEW", "COMPLAINT",
                                          "CRISIS", "SEEDING"])

      # Combine pattern + LLM
      if has_crisis_keywords(text) or intent == "CRISIS":
          return Intent.CRISIS
      ...
  ```

  Intent.CRISIS được assign cho posts chứa:
  - Accusations (cáo buộc): gian lận, lừa đảo, không an toàn
  - Legal threats: kiện, khiếu nại cơ quan chức năng
  - Calls for action: tẩy chay, boycott, đòi bồi thường

+ *Step 3: Keyword Extraction (Step 6):* Extract keywords để identify affected aspects. Example: "lỗi phanh nghiêm trọng" → aspects: ["Phanh", "An toàn"].

+ *Step 4: Sentiment Analysis (Steps 7-8):* PhoBERT-based sentiment model:
  ```python
  sentiment_probs = phobert_model.predict(text)
  # Output: {
  #   "VERY_NEGATIVE": 0.75,
  #   "NEGATIVE": 0.20,
  #   "NEUTRAL": 0.05,
  #   ...
  # }

  overall_sentiment = argmax(sentiment_probs)
  sentiment_score = sentiment_probs[overall_sentiment]
  ```

  Crisis posts typically có `VERY_NEGATIVE` hoặc `NEGATIVE` với confidence > 0.7.

+ *Step 5: Impact Calculation (Steps 9-10):* Impact Calculator compute risk score:
  ```python
  engagement_score = (likes + comments + shares) / views * 100
  reach_score = follower_count * (1.5 if verified else 1.0)
  sentiment_weight = abs(sentiment_score - 0.5) * 2  # 0-1 range
  velocity = views_24h / (hours_since_publish * avg_views_per_hour)

  impact_score = (
      engagement_score * 0.3 +
      reach_score * 0.3 +
      sentiment_weight * 0.2 +
      velocity * 0.2
  ) * 100

  # Risk level thresholds
  if impact_score >= 80:
      risk_level = "CRITICAL"
  elif impact_score >= 60:
      risk_level = "HIGH"
  elif impact_score >= 40:
      risk_level = "MEDIUM"
  else:
      risk_level = "LOW"
  ```

+ *Database Save (Step 11):* Batch INSERT toàn bộ analytics results vào `post_analytics` table, bao gồm `primary_intent`, `overall_sentiment`, `impact_score`, `risk_level`.

+ *Crisis Detection Logic (Step 12):* Sau khi save, Analytics Service check triple-check criteria:
  ```python
  def is_crisis(post: PostAnalytics) -> bool:
      return (
          post.primary_intent == Intent.CRISIS and
          post.overall_sentiment in [Sentiment.NEGATIVE, Sentiment.VERY_NEGATIVE] and
          post.risk_level in [RiskLevel.HIGH, RiskLevel.CRITICAL]
      )
  ```

  *Rationale:*
  - *Intent check:* Đảm bảo content chứa crisis signals (accusations, threats)
  - *Sentiment check:* Verify sentiment thực sự negative (avoid false positives từ sarcasm/jokes)
  - *Impact check:* Prioritize high-impact posts (viral potential)

  Triple-check giảm false positive rate từ ~15% (single check) xuống ~3%.

*Điểm kỹ thuật quan trọng:*

- *Crisis keywords database:* Maintain curated list của ~500 crisis-related keywords/phrases trong Vietnamese context. List được update periodically based on actual crisis cases.

- *LLM fallback:* Nếu LLM unavailable (timeout/cost), fallback về pattern matching only. Pattern matching có recall ~70% (bỏ sót 30% crisis) nhưng precision ~90% (ít false positives).

- *Aspect-level crisis:* Future enhancement: detect crisis ở aspect level. Example: post overall neutral nhưng aspect "An toàn" có very negative sentiment → potential crisis signal.

- *Velocity importance:* High velocity posts (going viral) được prioritize vì có potential để spread rapidly. Low velocity posts với crisis intent vẫn được track nhưng lower priority.

==== Part 2: Crisis Alert Publishing

#figure(
  image("../images/sequence/uc8_part_2.png", width: 100%),
  caption: [
    Sequence Diagram UC-08 (Part 2/4): Crisis Alert Publishing.
    Khi detect crisis, Analytics Service publish crisis.detected event vào RabbitMQ và Redis Pub/Sub simultaneously để ensure delivery qua multiple channels.
  ],
) <fig:uc08_part2_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 2_])
#image_counter.step()

*Các bước chính trong Part 2:*

+ *Build Alert Payload (Step 13):* Analytics Service construct crisis alert message:
  ```json
  {
    "type": "crisis_detected",
    "post_id": "...",
    "project_id": "...",
    "user_id": "...",
    "severity": "HIGH",  // or "CRITICAL"
    "title": "Post title preview (100 chars)",
    "platform": "tiktok",
    "author": "username",
    "published_at": "2024-03-20T10:30:00Z",
    "metrics": {
      "views": 150000,
      "likes": 12000,
      "comments": 3500,
      "impact_score": 85.3
    },
    "analytics": {
      "intent": "CRISIS",
      "sentiment": "VERY_NEGATIVE",
      "sentiment_score": -0.82,
      "keywords": ["lỗi nghiêm trọng", "không an toàn", ...]
    },
    "url": "https://tiktok.com/@user/video/123456",
    "detected_at": "2024-03-20T11:15:00Z"
  }
  ```

+ *Publish to RabbitMQ (Steps 14-15):* Publish event vào RabbitMQ exchange `smap.events` với routing key `crisis.detected`:
  ```python
  channel.basic_publish(
      exchange='smap.events',
      routing_key='crisis.detected',
      body=json.dumps(alert_payload),
      properties=pika.BasicProperties(
          delivery_mode=2,  # Persistent message
          priority=9,       # High priority (0-9 scale)
          expiration='3600000'  # 1 hour TTL
      )
  )
  ```

  *Priority=9* đảm bảo crisis alerts được process trước other messages trong queue.

+ *Publish to Redis Pub/Sub (Steps 16-17):* Đồng thời publish vào Redis Pub/Sub channel:
  ```
  PUBLISH crisis:{project_id}:{user_id} {alert_payload}
  ```

  *Dual publishing* (RabbitMQ + Redis) đảm bảo:
  - RabbitMQ: Reliable delivery với persistence, retries
  - Redis Pub/Sub: Real-time delivery đến WebSocket connections

+ *ACK RabbitMQ (Step 18):* Analytics Service ACK `data.collected` message để confirm processing done.

*Điểm kỹ thuật quan trọng:*

- *Dual-channel strategy:*
  - RabbitMQ cho durable notifications (survive service restarts)
  - Redis Pub/Sub cho immediate delivery (< 100ms latency)
  - If WebSocket offline, user vẫn receive notification khi reconnect (via polling `/alerts/unread`)

- *Priority queuing:* RabbitMQ priority queues đảm bảo crisis alerts được process trước regular progress updates. Requires `x-max-priority=10` argument khi declare queue.

- *Deduplication:* Nếu cùng post được analyzed multiple times (re-run project), check `post_id` trong Redis (`SETNX crisis:notified:{post_id}`) để avoid duplicate alerts.

- *Alert aggregation:* Nếu detect nhiều crisis posts trong short time (e.g., 10 posts trong 5 phút), aggregate thành single notification: "⚠️ Phát hiện 10 bài viết nguy cơ cao" thay vì spam 10 alerts.

==== Part 3: User Receives Alert

#figure(
  image("../images/sequence/uc8_part_3.png", width: 100%),
  caption: [
    Sequence Diagram UC-08 (Part 3/4): User Receives Real-time Alert.
    WebSocket Service receive crisis alert từ Redis Pub/Sub, deliver đến connected client, Web UI hiển thị prominent notification banner với alert sound và quick action buttons.
  ],
) <fig:uc08_part3_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 3_])
#image_counter.step()

*Các bước chính trong Part 3:*

+ *WebSocket Delivery (Steps 19-20):* WebSocket Service (subscribed to `crisis:{project_id}:{user_id}`) receive message từ Redis, forward đến connected client.

+ *Alert Rendering (Step 21):* Web UI handle crisis alert với high-priority treatment:
  ```javascript
  function handleCrisisAlert(alert) {
    // 1. Show notification banner (top of page, red background)
    showBanner({
      type: 'crisis',
      severity: alert.severity,  // HIGH or CRITICAL
      message: `🚨 Phát hiện khủng hoảng: ${alert.title}`,
      actions: [
        { label: 'Xem chi tiết', onClick: () => openCrisisModal(alert) },
        { label: 'Đánh dấu đã xử lý', onClick: () => markAsHandled(alert.post_id) }
      ]
    });

    // 2. Play alert sound (if user enabled)
    if (userPrefs.enableSound) {
      playSound('crisis-alert.mp3');
    }

    // 3. Add to Crisis Dashboard list (local state)
    dispatch(addCrisisPost(alert));

    // 4. Show browser notification (if permission granted)
    if (Notification.permission === 'granted') {
      new Notification('SMAP Crisis Alert', {
        body: alert.title,
        icon: '/crisis-icon.png',
        badge: '/badge.png',
        vibrate: [200, 100, 200]
      });
    }

    // 5. Update unread count badge
    updateUnreadCount(prev => prev + 1);
  }
  ```

*Điểm kỹ thuật quan trọng:*

- *Multi-modal alerts:*
  - In-app banner (always shown)
  - Sound notification (user-configurable)
  - Browser notification (requires permission)
  - Badge count (persistent across page reloads)

- *Severity-based styling:*
  - CRITICAL: Red banner + continuous pulsing animation
  - HIGH: Orange banner + subtle fade animation
  - (MEDIUM/LOW không trigger real-time alerts)

- *Accessibility:* Alert sound có option để disable (for users in quiet environments). Banner có high contrast ratio (WCAG AAA compliant) và keyboard navigation support.

- *Notification persistence:* Browser notifications persist even khi user switch tabs. Clicking notification focuses SMAP tab và opens crisis modal.

==== Part 4: Crisis Dashboard & Response

#figure(
  image("../images/sequence/uc8_part_4.png", width: 100%),
  caption: [
    Sequence Diagram UC-08 (Part 4/4): Crisis Dashboard & User Response.
    User click "Xem chi tiết" để mở Crisis Dashboard, query tất cả crisis posts từ PostgreSQL, hiển thị với filters và sort by impact. User click vào post cụ thể để xem full details và thực hiện actions.
  ],
) <fig:uc08_part4_sequence>

#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 4_])
#image_counter.step()

*Các bước chính trong Part 4:*

+ *Dashboard Access (Steps 22-23):* User click "Xem chi tiết" hoặc navigate đến `/crisis` page. Web UI request `GET /api/crisis?project_id=xxx`.

+ *Query Crisis Posts (Step 24):* Project API query PostgreSQL:
  ```sql
  SELECT * FROM post_analytics
  WHERE project_id = $1
    AND primary_intent = 'CRISIS'
    AND overall_sentiment IN ('NEGATIVE', 'VERY_NEGATIVE')
    AND risk_level IN ('HIGH', 'CRITICAL')
  ORDER BY impact_score DESC, published_at DESC
  LIMIT 100
  ```

  Filters available:
  - Risk level: CRITICAL only, HIGH only, or Both
  - Platform: TikTok, YouTube, or All
  - Date range: Last 24h, Last 7 days, Custom
  - Status: Unhandled, Handled, All

+ *Dashboard Display (Step 25):* Web UI render Crisis Dashboard:
  ```
  ┌─────────────────────────────────────────────┐
  │ 🚨 Crisis Dashboard              [Filters]  │
  ├─────────────────────────────────────────────┤
  │ ┌─────────────────────────────────────────┐ │
  │ │ [CRITICAL] TikTok @user123              │ │
  │ │ Impact: 92.5 | Views: 2.3M | Likes: 180K│ │
  │ │ "Lỗi nghiêm trọng, đòi bồi thường..."   │ │
  │ │ Published: 2h ago | Unhandled           │ │
  │ │ [Xem chi tiết] [Đánh dấu đã xử lý]      │ │
  │ └─────────────────────────────────────────┘ │
  │ ┌─────────────────────────────────────────┐ │
  │ │ [HIGH] YouTube @reviewer_x              │ │
  │ │ Impact: 78.2 | Views: 500K | Likes: 45K │ │
  │ │ "Không khuyến khích mua, gian lận..."   │ │
  │ │ Published: 5h ago | Handled ✓           │ │
  │ └─────────────────────────────────────────┘ │
  │ ...                                         │
  └─────────────────────────────────────────────┘
  ```

+ *Post Details (Steps 26-27):* User click vào crisis post. Web UI request `/posts/:post_id/details`.

+ *Full Details Query (Steps 28-29):* Query toàn bộ post data và comments (đã mô tả trong UC-04 Part 2).

+ *Modal Display (Step 30):* Web UI hiển thị crisis post modal với enriched information:
  - **Content section**: Full caption + transcription với crisis keywords highlighted
  - **Metrics section**: Views, likes, comments, shares với trend indicators
  - **Analytics section**:
    - Intent: CRISIS badge
    - Sentiment: VERY_NEGATIVE với score -0.82
    - Impact breakdown: engagement (32), reach (28), sentiment (18), velocity (22) = 85.3
    - Keywords: crisis-related keywords highlighted in red
    - Aspects: affected aspects (e.g., "Chất lượng: -0.9", "An toàn: -0.85")
  - **Comments section**: Top 50 comments sorted by likes, với sentiment annotations
  - **Action buttons**:
    - 🔗 "Mở link gốc" (deep link to TikTok/YouTube)
    - ✅ "Đánh dấu đã xử lý" (mark as handled)
    - 📧 "Gửi báo cáo" (send crisis report to stakeholders via email)
    - 👥 "Chia sẻ team" (share with team members in SMAP)
    - 📋 "Export" (export post details as PDF)

+ *Mark as Handled (Steps 31-32):* User click "Đánh dấu đã xử lý". Web UI send `PATCH /posts/:id`:
  ```json
  {
    "handled": true,
    "handled_by": "{user_id}",
    "handled_at": "2024-03-20T12:30:00Z",
    "notes": "Đã liên hệ với KH và giải quyết"
  }
  ```

  PostgreSQL update `post_analytics` table. UI remove crisis badge và update status.

*Điểm kỹ thuật quan trọng:*

- *Crisis prioritization:* Dashboard sort by `impact_score DESC` để hiển thị urgent cases đầu tiên. CRITICAL posts có red left border, HIGH posts có orange border.

- *Status tracking:* `handled` flag cho phép user track which crisis posts đã được addressed. Filters: "Unhandled" (action required), "Handled" (resolved).

- *Collaborative response:* "Chia sẻ team" feature cho phép assign crisis post đến specific team member với \@mentions và comments (future enhancement).

- *Audit trail:* Mọi actions (mark as handled, export, share) được log vào `crisis_actions` table với timestamps và user_id để audit compliance.

- *Escalation workflow:* Nếu crisis post không được handled trong 4 hours → escalate notification đến manager (configurable via org settings).

- *Response templates:* Future: provide pre-defined response templates (apology, explanation, solution) để team respond nhanh chóng và consistently trên social platforms.
