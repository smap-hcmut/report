# Ingest Service - API Specification

**Service:** ingest-srv  
**Language:** Go  
**Purpose:** Manage data sources and execute data ingestion  
**Ngày tạo:** 19/02/2026

---

## 1. OVERVIEW

Ingest Service là owner của Data Sources và chịu trách nhiệm:

1. **CRUD Data Sources:** Create, Read, Update, Delete data sources
2. **Execute Ingestion:** Parse files, crawl APIs, receive webhooks
3. **Transform to UAP:** Convert raw data → Unified Analytics Payload
4. **Publish Events:** Notify other services về status changes

**Database Ownership:** `schema_ingest.data_sources`

---

## 2. DATA SOURCE CRUD APIs

### 2.1 Create Data Source

**Endpoint:** `POST /ingest/sources`

**Request:**

```json
{
  "project_id": "proj_vf8",
  "name": "TikTok VF8",
  "source_type": "TIKTOK",
  "source_category": "crawl",
  "config": {
    "keywords": ["vinfast vf8", "vf8 review"],
    "date_range": "last_30_days",
    "filters": {
      "min_views": 1000
    }
  }
}
```

**Response 201:**

```json
{
  "id": "src_tiktok_01",
  "project_id": "proj_vf8",
  "name": "TikTok VF8",
  "source_type": "TIKTOK",
  "source_category": "crawl",
  "status": "PENDING",
  "config": {...},
  "created_at": "2026-02-19T10:00:00Z",
  "updated_at": "2026-02-19T10:00:00Z"
}
```

**Validation:**

- `project_id` must exist (call Project Service to verify)
- `source_type` must be valid: FILE_UPLOAD, WEBHOOK, FACEBOOK, TIKTOK, YOUTUBE
- `source_category` auto-determined:
  - FILE_UPLOAD, WEBHOOK → `passive`
  - FACEBOOK, TIKTOK, YOUTUBE → `crawl`

---

### 2.2 Get Data Source

**Endpoint:** `GET /ingest/sources/{id}`

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "project_id": "proj_vf8",
  "name": "TikTok VF8",
  "source_type": "TIKTOK",
  "source_category": "crawl",
  "status": "ACTIVE",
  "config": {...},
  
  // Crawl-specific fields (only if source_category = crawl)
  "crawl_mode": "NORMAL",
  "crawl_interval_minutes": 11,
  "next_crawl_at": "2026-02-19T10:11:00Z",
  "last_crawl_at": "2026-02-19T10:00:00Z",
  "last_crawl_metrics": {
    "items_count": 50,
    "status": "SUCCESS",
    "crawl_duration_ms": 3500
  },
  
  // Onboarding fields
  "onboarding_status": "COMPLETED",
  "dryrun_status": "SUCCESS",
  "dryrun_results": {...},
  
  "created_at": "2026-02-19T09:00:00Z",
  "updated_at": "2026-02-19T10:00:00Z"
}
```

---

### 2.3 List Data Sources

**Endpoint:** `GET /ingest/sources?project_id={project_id}&status={status}`

**Query Parameters:**

- `project_id` (optional): Filter by project
- `status` (optional): Filter by status
- `source_category` (optional): Filter by category (crawl/passive)
- `limit` (optional): Default 50, max 200
- `offset` (optional): Default 0

**Response 200:**

```json
{
  "total": 4,
  "sources": [
    {
      "id": "src_tiktok_01",
      "project_id": "proj_vf8",
      "name": "TikTok VF8",
      "source_type": "TIKTOK",
      "source_category": "crawl",
      "status": "ACTIVE",
      "crawl_mode": "NORMAL",
      "record_count": 1000,
      "created_at": "2026-02-19T09:00:00Z"
    },
    {...}
  ]
}
```

---

### 2.4 Update Data Source

**Endpoint:** `PUT /ingest/sources/{id}`

**Request:**

```json
{
  "name": "TikTok VF8 Updated",
  "config": {
    "keywords": ["vinfast vf8", "vf8 2026"],
    "filters": {
      "min_views": 500
    }
  }
}
```

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "name": "TikTok VF8 Updated",
  "config": {...},
  "updated_at": "2026-02-19T11:00:00Z"
}
```

**Validation:**

- Cannot update `source_type`, `source_category`, `project_id`
- Cannot update if status = ACTIVE (must pause first)

---

### 2.5 Delete Data Source

**Endpoint:** `DELETE /ingest/sources/{id}`

**Response 204:** No Content

**Validation:**

- Cannot delete if status = ACTIVE (must pause/archive first)
- Soft delete: Set `deleted_at` timestamp

---

## 3. DATA SOURCE LIFECYCLE APIs

### 3.1 Activate Data Source

**Endpoint:** `POST /ingest/sources/{id}/activate`

**Request:** Empty body

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "status": "ACTIVE",
  "activated_at": "2026-02-19T10:00:00Z"
}
```

**Actions:**

- Update: `status = ACTIVE`, `activated_at = NOW()`
- If `source_category = crawl`:
  - Set `crawl_mode = NORMAL`
  - Set `crawl_interval_minutes = 11`
  - Set `next_crawl_at = NOW()`
- Publish event: `ingest.source.activated`

**Validation:**

- Current status must be READY
- Parent project must be ACTIVE (call Project Service to verify)

---

### 3.2 Pause Data Source

**Endpoint:** `POST /ingest/sources/{id}/pause`

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "status": "PAUSED",
  "paused_at": "2026-02-19T11:00:00Z"
}
```

**Actions:**

- Update: `status = PAUSED`, `paused_at = NOW()`
- If `source_category = crawl`:
  - Set `next_crawl_at = NULL` (stop scheduling)
- Publish event: `ingest.source.paused`

---

### 3.3 Resume Data Source

**Endpoint:** `POST /ingest/sources/{id}/resume`

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "status": "ACTIVE",
  "resumed_at": "2026-02-19T12:00:00Z"
}
```

**Actions:**

- Update: `status = ACTIVE`, `resumed_at = NOW()`
- If `source_category = crawl`:
  - Set `next_crawl_at = NOW()` (resume scheduling)
- Publish event: `ingest.source.resumed`

---

## 4. ADAPTIVE CRAWL APIs

### 4.1 Update Crawl Mode

**Endpoint:** `PUT /ingest/sources/{id}/crawl-mode`

**Caller:** Project Service (Adaptive Scheduler)

**Request:**

```json
{
  "crawl_mode": "CRISIS",
  "crawl_interval_minutes": 2,
  "reason": "Negative ratio 45% >> baseline 10%"
}
```

**Response 200:**

```json
{
  "id": "src_tiktok_01",
  "crawl_mode": "CRISIS",
  "crawl_interval_minutes": 2,
  "next_crawl_at": "2026-02-19T10:02:00Z",
  "mode_changed_at": "2026-02-19T10:00:00Z",
  "mode_change_reason": "Negative ratio 45% >> baseline 10%"
}
```

**Actions:**

- Update: `crawl_mode`, `crawl_interval_minutes`
- Calculate: `next_crawl_at = NOW() + interval`
- Store: `mode_change_reason`, `mode_changed_at`
- Publish event: `ingest.crawl_mode.changed`

**Validation:**

- `source_category` must be `crawl`
- `crawl_mode` must be: SLEEP, NORMAL, CRISIS
- `crawl_interval_minutes` must match mode:
  - SLEEP: 60
  - NORMAL: 11
  - CRISIS: 2

---

### 4.2 Get Crawl Schedule

**Endpoint:** `GET /ingest/sources/due?limit={limit}`

**Purpose:** Internal API for worker to query sources due for crawl

**Query Parameters:**

- `limit` (optional): Default 100

**Response 200:**

```json
{
  "total": 5,
  "sources": [
    {
      "id": "src_tiktok_01",
      "project_id": "proj_vf8",
      "source_type": "TIKTOK",
      "crawl_mode": "CRISIS",
      "crawl_interval_minutes": 2,
      "next_crawl_at": "2026-02-19T10:00:00Z",
      "config": {...}
    },
    {...}
  ]
}
```

**Query Logic:**

```sql
SELECT *
FROM schema_ingest.data_sources
WHERE
  status = 'ACTIVE'
  AND source_category = 'crawl'
  AND next_crawl_at <= NOW()
ORDER BY next_crawl_at ASC
LIMIT $1;
```

---

## 5. DRY RUN API

### 5.1 Trigger Dry Run

**Endpoint:** `POST /ingest/sources/{id}/dry-run`

**Purpose:** Test crawl config before activation

**Request:** Empty body

**Response 202:** Accepted

```json
{
  "id": "src_tiktok_01",
  "dryrun_status": "RUNNING",
  "message": "Dry run started, results will be available shortly"
}
```

**Actions:**

- Update: `dryrun_status = RUNNING`
- Trigger async job: Execute crawl with `profile = DRY_RUN`
- Publish event: `ingest.dryrun.started`

**Validation:**

- `source_category` must be `crawl`
- Current status must be PENDING or READY

---

### 5.2 Get Dry Run Results

**Endpoint:** `GET /ingest/sources/{id}/dry-run`

**Response 200:**

```json
{
  "source_id": "src_tiktok_01",
  "dryrun_status": "SUCCESS",
  "results": {
    "status": "SUCCESS",
    "total_found": 150,
    "sample_data": [
      {
        "title": "VF8 Review 2026",
        "author": "Tech Reviewer",
        "views": 5000,
        "published_at": "2026-02-18T10:00:00Z",
        "content": "Great car but battery drains fast..."
      },
      {...}
    ],
    "warnings": [],
    "timestamp": "2026-02-19T10:15:00Z"
  }
}
```

**Response 200 (if FAILED):**

```json
{
  "source_id": "src_tiktok_01",
  "dryrun_status": "FAILED",
  "results": {
    "status": "FAILED",
    "error_message": "Authentication failed: Invalid API key",
    "timestamp": "2026-02-19T10:15:00Z"
  }
}
```

---

## 6. FILE UPLOAD API

### 6.1 Generate Upload URL

**Endpoint:** `POST /ingest/sources/{id}/upload-url`

**Purpose:** Generate presigned URL for file upload

**Request:**

```json
{
  "filename": "feedback_q1.xlsx",
  "content_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
}
```

**Response 200:**

```json
{
  "upload_url": "https://minio.smap.com/uploads/proj_vf8/src_excel_01/feedback_q1.xlsx?X-Amz-...",
  "expires_at": "2026-02-19T11:00:00Z",
  "file_url": "s3://smap-uploads/proj_vf8/src_excel_01/feedback_q1.xlsx"
}
```

**Validation:**

- `source_type` must be FILE_UPLOAD
- File size limit: 100MB
- Allowed types: .xlsx, .csv, .json

---

### 6.2 Process File

**Endpoint:** `POST /ingest/sources/{id}/process-file`

**Purpose:** Trigger file processing after upload

**Request:**

```json
{
  "file_url": "s3://smap-uploads/proj_vf8/src_excel_01/feedback_q1.xlsx",
  "mapping_rules": {
    "content": "Ý kiến khách hàng",
    "content_created_at": "Ngày gửi",
    "metadata.author": "Tên KH",
    "metadata.rating": "Đánh giá"
  }
}
```

**Response 202:** Accepted

```json
{
  "id": "src_excel_01",
  "status": "PROCESSING",
  "message": "File processing started"
}
```

**Actions:**

- Update: `status = PROCESSING`
- Trigger async job: Parse file → Transform to UAP → Publish
- Publish event: `ingest.file.processing`

---

## 7. WEBHOOK API

### 7.1 Generate Webhook URL

**Endpoint:** `POST /ingest/sources/{id}/webhook-url`

**Purpose:** Generate webhook URL and secret

**Request:** Empty body

**Response 200:**

```json
{
  "webhook_url": "https://smap.com/webhook/abc123def456",
  "secret": "whsec_7f8a9b0c1d2e3f4g5h6i7j8k9l0m1n2o",
  "instructions": "Send POST requests to webhook_url with HMAC-SHA256 signature in X-Webhook-Signature header"
}
```

**Actions:**

- Generate: `webhook_id` (random UUID)
- Generate: `secret` (random 32-byte string)
- Store: `webhook_url`, `secret` in config
- Update: `status = READY`

---

### 7.2 Receive Webhook

**Endpoint:** `POST /webhook/{webhook_id}`

**Purpose:** Receive webhook data from external systems

**Headers:**

- `X-Webhook-Signature`: HMAC-SHA256 signature

**Request:**

```json
{
  "customer_name": "Nguyễn Văn A",
  "feedback": "Xe đi êm nhưng pin sụt nhanh",
  "rating": 4,
  "date": "06/02/2026 08:00"
}
```

**Response 200:**

```json
{
  "status": "accepted",
  "message": "Webhook received and queued for processing"
}
```

**Actions:**

- Validate: HMAC signature
- Apply: mapping_rules
- Transform: → UAP
- Publish: `smap.collector.output`
- Update: `last_received_at = NOW()`, increment `record_count`

**Response 401 (if signature invalid):**

```json
{
  "error": "Invalid signature"
}
```

---

## 8. KAFKA EVENTS PUBLISHED

### 8.1 Source Lifecycle Events

```yaml
ingest.source.created:
  payload: {source_id, project_id, source_type, status}

ingest.source.activated:
  payload: {source_id, project_id, activated_at}

ingest.source.paused:
  payload: {source_id, project_id, paused_at}

ingest.source.resumed:
  payload: {source_id, project_id, resumed_at}

ingest.source.deleted:
  payload: {source_id, project_id, deleted_at}
```

### 8.2 Ingestion Events

```yaml
ingest.crawl.completed:
  payload:
    source_id: string
    project_id: string
    items_count: int
    status: string  # SUCCESS | FAILED | PARTIAL
    error_message: string
    crawl_duration_ms: int
    next_cursor: string
    timestamp: string

ingest.file.completed:
  payload:
    source_id: string
    project_id: string
    items_count: int
    status: string  # SUCCESS | FAILED
    error_message: string
    file_url: string
    processing_duration_ms: int
    timestamp: string

ingest.dryrun.completed:
  payload:
    source_id: string
    project_id: string
    status: string  # SUCCESS | FAILED | WARNING
    sample_data: array
    total_found: int
    error_message: string
    warnings: array
    timestamp: string

ingest.crawl_mode.changed:
  payload:
    source_id: string
    project_id: string
    old_mode: string
    new_mode: string
    crawl_interval_minutes: int
    reason: string
    timestamp: string
```

---

## 9. ERROR RESPONSES

### 9.1 Standard Error Format

```json
{
  "error": {
    "code": "SOURCE_NOT_FOUND",
    "message": "Data source not found",
    "details": {
      "source_id": "src_invalid_01"
    }
  }
}
```

### 9.2 Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `SOURCE_NOT_FOUND` | 404 | Data source not found |
| `INVALID_SOURCE_TYPE` | 400 | Invalid source type |
| `INVALID_STATUS_TRANSITION` | 400 | Cannot transition from current status |
| `PROJECT_NOT_ACTIVE` | 400 | Parent project is not active |
| `CRAWL_MODE_NOT_APPLICABLE` | 400 | Crawl mode only for crawl sources |
| `VALIDATION_FAILED` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `INTERNAL_ERROR` | 500 | Internal server error |

---

## 10. AUTHENTICATION

All APIs require JWT authentication:

```
Authorization: Bearer <jwt_token>
```

JWT must contain:
- `user_id`: User identifier
- `permissions`: Array of permissions
- `exp`: Expiration timestamp

Required permissions:
- `ingest:sources:read` - Read data sources
- `ingest:sources:write` - Create/update data sources
- `ingest:sources:delete` - Delete data sources
- `ingest:sources:activate` - Activate/pause/resume sources

---

**Last Updated:** 19/02/2026  
**Author:** System Architect
