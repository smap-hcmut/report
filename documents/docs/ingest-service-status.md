# Ingest Service — Status Document

> Generated from code review: `dispatcher-srv/`
> Date: 2026-03-08 (verified against actual code)

---

## 1. Tổng quan

Ingest Service (codebase: `dispatcher-srv`) quản lý data collection từ external sources (crawl & webhook) → parse thành UAP (Unified Analytics Payload) → publish downstream. Được viết bằng Go, Gin framework, PostgreSQL, RabbitMQ, MinIO.

**Bốn domain:**

- `datasource` — quản lý data sources (crawl/webhook), targets (keywords/profiles/posts)
- `execution` — orchestrate crawl tasks (RabbitMQ producer/consumer)
- `dryrun` — test datasource trước activate
- `uap` — parse raw batch data → UAP format

---

## 2. DataSource Domain

### 2.1 Lifecycle

**File:** `internal/model/ingest_types.go:20-30`

```
PENDING → READY → [PAUSED | ACTIVE] → ARCHIVED
                         ↓
                       FAILED
(COMPLETED: chỉ cho one-shot passive source như FILE_UPLOAD)
```

**Tất cả 7 trạng thái:**

| Status | Ý nghĩa |
| --- | --- |
| `PENDING` | Mới tạo hoặc vừa sửa config, chưa sẵn sàng chạy |
| `READY` | Đã dry run/validate xong, chờ activate |
| `ACTIVE` | Đang chạy trong runtime |
| `PAUSED` | Tạm dừng, có thể resume |
| `FAILED` | Lỗi, cần can thiệp trước khi chạy lại |
| `COMPLETED` | Chỉ dùng cho one-shot passive (FILE_UPLOAD) |
| `ARCHIVED` | Ngừng vận hành, chỉ giữ lịch sử (soft delete) |

**Status transitions:**

- `Create` → PENDING (basic validation, không check prerequisites)
- `Activate` → READY → ACTIVE (enforce state guard: crawl config + active targets, hoặc webhook fields)
- `Pause` → ACTIVE → PAUSED
- `Resume` → PAUSED → ACTIVE
- `Archive` → (any) → ARCHIVED (`deleted_at` + `archived_at` timestamps)

### 2.2 Source Types & Categories

**File:** `internal/model/ingest_types.go:3-11`

| SourceType | Category | Config Required | Targets |
| --- | --- | --- | --- |
| `TIKTOK` | CRAWL | crawl_mode, crawl_interval_minutes | KEYWORD, PROFILE, POST_URL |
| `FACEBOOK` | CRAWL | crawl_mode, crawl_interval_minutes | KEYWORD, PROFILE, POST_URL |
| `YOUTUBE` | CRAWL | crawl_mode, crawl_interval_minutes | KEYWORD, PROFILE, POST_URL |
| `FILE_UPLOAD` | PASSIVE | (N/A) | (N/A) |
| `WEBHOOK` | PASSIVE | webhook_id, webhook_secret_encrypted | (N/A) |

**Crawl sources (`Activate` prerequisites):**

- `crawl_mode` không được nil
- `crawl_interval_minutes` > 0
- ≥ 1 active target

**Webhook sources (`Activate` prerequisites):**

- `webhook_id` không rỗng
- `webhook_secret_encrypted` không rỗng

### 2.3 CrawlTarget Sub-Resource

**File:** `internal/model/ingest_types.go:91-97`

| Type | Constant | Use |
| --- | --- | --- |
| **KEYWORD** | `TargetTypeKeyword` | Crawl theo từ khóa |
| **PROFILE** | `TargetTypeProfile` | Crawl theo profile/page/channel |
| **POST_URL** | `TargetTypePostURL` | Crawl theo link bài viết/video cụ thể |

Routes: `POST/GET/PUT/DELETE /datasources/:id/targets/{keywords,profiles,posts}`

### 2.4 CrawlModeChange Audit

**File:** `internal/model/crawl_mode_change.go:9-24`

Khi `UpdateCrawlMode` thành công, ghi record vào `crawl_mode_changes`:

| Field | Mô tả |
| --- | --- |
| `source_id`, `project_id` | Context |
| `trigger_type` | Enum: MANUAL, SCHEDULED, PROJECT_EVENT, CRISIS_EVENT, WEBHOOK_PUSH |
| `from_mode` → `to_mode` | Transition |
| `from_interval_minutes` → `to_interval_minutes` | Interval change |
| `reason`, `event_ref`, `triggered_by` | Audit trail |
| `triggered_at`, `created_at` | Timestamps |

### 2.5 UpdateCrawlMode Logic (chi tiết)

**File:** `internal/datasource/usecase/lifecycle.go:137-197`

1. Validate input
2. Fetch datasource, error nếu không tồn tại
3. Check category == CRAWL (else ErrCrawlModeNotAllowed)
4. Check status ∈ {READY, ACTIVE, PAUSED} (else ErrCrawlModeNotAllowed)
5. Validate crawl config (interval > 0, mode not nil)
6. Update datasource với crawl_mode mới
7. Extract triggered_by user ID từ context
8. Create CrawlModeChange audit record
9. Return updated datasource

### 2.6 API Endpoints

```
Public (mw.Auth):
  POST   /datasources
  GET    /datasources?filter
  GET    /datasources/:id
  PUT    /datasources/:id
  DELETE /datasources/:id

  POST   /datasources/:id/targets/{keywords,profiles,posts}
  GET    /datasources/:id/targets
  GET    /datasources/:id/targets/:target_id
  PUT    /datasources/:id/targets/:target_id
  DELETE /datasources/:id/targets/:target_id

Internal (mw.InternalAuth — header: X-Internal-Key):
  PUT    /datasources/:id/crawl-mode   (Adaptive Crawl control)
```

**InternalAuth:** Header `X-Internal-Key`, validate bằng string comparison với `internal.internal_key` config.

---

## 3. Execution Domain (RabbitMQ + Scheduler)

### 3.1 Scheduler + Cron

**File:** `config/config.go:269`

```go
viper.SetDefault("scheduler.heartbeat_cron", "*/1 * * * *")
```

- Chạy mỗi **1 phút**
- `Start()` → `RegisterJobs()` → `ExecutionJob.Register()` → `cron.AddJob()`
- Cron wrapper có panic recovery

### 3.2 RabbitMQ Queues

**File:** `internal/execution/delivery/rabbitmq/constants.go`

| Queue | Constant | Direction |
| --- | --- | --- |
| `tiktok_tasks` | `TikTokTasksQueueName` | Dispatcher → Scraper (produce) |
| `facebook_tasks` | `FacebookTasksQueueName` | Dispatcher → Scraper (produce) |
| `youtube_tasks` | `YoutubeTasksQueueName` | Dispatcher → Scraper (produce) |
| `ingest_task_completions` | `IngestTaskCompletionsQueueName` | Scraper → Dispatcher (consume) |

**Consumer:** `ingest-execution-completion-consumer`

**UseCase methods:**

- `DispatchTarget()` — publish 1 target crawl task sang queue tương ứng theo source type
- `DispatchTargetManually()` — admin manual dispatch
- `DispatchDueTargets()` (CronUseCase) — scheduler batch dispatch

### 3.3 HandleCompletion Flow

**File:** `internal/execution/usecase/handle_completion.go`

```text
RabbitMQ consumer nhận completion message
  → Parse status (SUCCESS / ERROR)

SUCCESS path:
  1. Check duplicate (raw_batch đã tồn tại?)
  2. Verify MinIO object exists + get file info
  3. Extract size_bytes từ metadata hoặc MinIO
  4. CompleteTaskSuccess() → create raw_batch record
  5. IF shouldParseUAP() [TikTok + full_flow mode]:
     → ParseAndStoreRawBatch() → download JSONL → publish smap.collector.output
  6. Return

ERROR path:
  1. Check duplicate error completion
  2. CompleteTaskError() với error details
```

---

## 4. UAP Domain

### 4.1 UAP Struct

**File:** `internal/uap/types.go:29-97`

```go
type UAPRecord struct {
    Identity   UAPIdentity    // UAPID, OriginID, UAPType, Platform, URL, TaskID, ProjectID
    Hierarchy  UAPHierarchy   // ParentID, RootID, Depth
    Content    UAPContent     // Text, Hashtags, TikTokKeywords, Language, ExternalLinks...
    Author     UAPAuthor      // ID, Username, Nickname, Avatar, IsVerified
    Engagement UAPEngagement  // Likes, CommentsCount, Shares, Views, Bookmarks, SortScore
    Media      []UAPMedia     // Type, URL, DownloadURL, Duration, Thumbnail
    Temporal   UAPTemporal    // PostedAt, IngestedAt
}
```

### 4.2 Parse & Publish

**UseCase:** `ParseAndStoreRawBatch()`

**MinIO bucket:** `ingest-data` (`config/config.go:250`)
**Kafka topic:** `smap.collector.output` (`config/config.go:256`)

Flow:

1. Parse file_url (format: `s3://bucket/path`)
2. Download từ MinIO
3. Parse raw data → validate UAP format
4. Lưu vào `raw_batches` table
5. Publish vào Kafka: `smap.collector.output`

---

## 5. DryRun Domain

### 5.1 Test Before Activation

**File:** `internal/dryrun/usecase/dryrun.go`

UseCase methods:

- `Trigger(ctx, TriggerInput)` — start dryrun test
- `GetLatest(ctx, GetLatestInput)` — lấy result dryrun cuối cùng
- `ListHistory(ctx, ListHistoryInput)` — paginated history

**Trigger flow:**

1. Validate input
2. Fetch source, error nếu không tồn tại
3. Check source status ∈ {PENDING, READY}
4. Với CRAWL source: validate target là active
5. Create initial result với status RUNNING
6. Execute dryrun via `exec.Execute()`
7. Update result với final status
8. Update datasource:
   - `WARNING` result → status=READY, dryrun_status=WARNING
   - Else → status=PENDING, dryrun_status=FAILED

### 5.2 DryRun Status Values

**File:** `internal/model/ingest_types.go:43-52`

| Status | Ý nghĩa |
| --- | --- |
| `NOT_REQUIRED` | Source không cần dry run |
| `PENDING` | Đã tạo request nhưng chưa bắt đầu |
| `RUNNING` | Đang thực thi |
| `SUCCESS` | Pass hoàn toàn |
| `WARNING` | Usable nhưng có cảnh báo |
| `FAILED` | Thất bại, cần fix trước khi activate |

### 5.3 Activation Guard — KHÔNG check dryrun_status

**Verified từ code** (`lifecycle.go:28-57`): `Activate()` **không** kiểm tra `dryrun_status`. Điều kiện activate chỉ gồm:

- Source status == READY
- (CRAWL) crawl_mode, interval > 0, ≥ 1 active target
- (WEBHOOK) webhook_id, webhook_secret_encrypted không rỗng

---

## 6. Tình Trạng Tổng Thể

**Implemented và hoạt động:**

- DataSource CRUD (full: Create/List/Detail/Update/Archive)
- Lifecycle transitions (Activate/Pause/Resume) với state guards
- CrawlTarget CRUD (3 types: KEYWORD, PROFILE, POST_URL)
- CrawlModeChange audit logging (đầy đủ fields)
- Scheduler chạy mỗi 1 phút
- RabbitMQ: 3 task queues (tiktok/facebook/youtube), 1 completion queue
- Dryrun control (Trigger/GetLatest/ListHistory) với 6 status values
- UAP parsing + Kafka publishing (`smap.collector.output`)
- InternalAuth middleware (`X-Internal-Key` header)

**Không implement / chưa rõ:**

- Ingest chưa có Kafka consumer cho `project.lifecycle` events → project activate/pause không được phản ánh sang ingest (cần implement ở Phase 3 roadmap)
- `shouldParseUAP()` chỉ trigger với TikTok + full_flow mode — logic cho Facebook/YouTube chưa rõ

---

## 7. Adaptive Crawl Status

**InternalRoute:** `PUT /internal/datasources/:id/crawl-mode` (header: `X-Internal-Key`)

**Auth:** Direct string compare `X-Internal-Key` vs `internal.internal_key` config.

**Usecase:** `UpdateCrawlMode()` — xem Section 2.5 cho chi tiết.

**TriggerType enum đã định nghĩa:**

- `MANUAL` — do user/admin trigger
- `SCHEDULED` — do scheduler
- `PROJECT_EVENT` — do project lifecycle event
- `CRISIS_EVENT` — do adaptive crawl/crisis controller
- `WEBHOOK_PUSH` — do dữ liệu push từ webhook

**Who calls it?** Chưa có caller nào trong codebase. Ingest đã chuẩn bị endpoint và TriggerType enum, nhưng chưa có:

- Project service consumer (để receive crisis decision)
- Analytics metrics aggregator (để cung cấp data cho crisis detection)

Xem `documents/report-08-03.md` Phase 5 cho implementation plan.
