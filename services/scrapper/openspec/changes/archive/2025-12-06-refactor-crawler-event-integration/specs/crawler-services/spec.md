## ADDED Requirements

### Requirement: Result Meta TaskType Field

The Crawler services SHALL include a `task_type` field in the `meta` object of every content item returned in crawl results.

The `task_type` field SHALL contain one of the following values:

- `dryrun_keyword` - For dry-run keyword testing
- `research_and_crawl` - For project execution (brand/competitor crawling)
- `research_keyword` - For research-only operations
- `crawl_links` - For crawling specific URLs

#### Scenario: Dry-run result includes task_type

- **WHEN** a crawler processes a `dryrun_keyword` task
- **THEN** every content item in the result payload SHALL have `meta.task_type` set to `"dryrun_keyword"`

#### Scenario: Project execution result includes task_type

- **WHEN** a crawler processes a `research_and_crawl` task for project execution
- **THEN** every content item in the result payload SHALL have `meta.task_type` set to `"research_and_crawl"`

#### Scenario: TaskType propagation through call chain

- **WHEN** TaskService receives a task message with a specific task_type
- **THEN** the task_type SHALL be propagated to CrawlerService and included in the final result meta

---

### Requirement: YouTube Result Publisher

The YouTube Crawler service SHALL publish crawl results to the Collector Service via RabbitMQ.

The publisher SHALL:

- Connect to the `results.inbound` exchange
- Use routing key `youtube.res`
- Publish results in the same format as TikTok service

#### Scenario: YouTube publishes dry-run results

- **WHEN** YouTube crawler completes a dry-run task
- **THEN** the service SHALL publish the result to `results.inbound` exchange with routing key `youtube.res`

#### Scenario: YouTube publishes project execution results

- **WHEN** YouTube crawler completes a project execution task
- **THEN** the service SHALL publish the result to `results.inbound` exchange with `task_type: "research_and_crawl"` in meta

---

### Requirement: DataCollected Event Publisher

The Crawler services SHALL publish `data.collected` events to notify downstream services (Analytics) when batch data is available.

The event SHALL be published to:

- Exchange: `smap.events` (topic type)
- Routing Key: `data.collected`

#### Scenario: Publish data.collected event after batch upload

- **WHEN** a crawler uploads a batch of content items to MinIO
- **THEN** the service SHALL publish a `data.collected` event with the following payload:
  - `project_id`: Extracted from job_id
  - `job_id`: The original job identifier
  - `platform`: `"tiktok"` or `"youtube"`
  - `minio_path`: Full path to the uploaded batch file
  - `content_count`: Number of items in the batch
  - `batch_index`: Sequential batch number
  - `total_batches`: Total expected batches (if known)

#### Scenario: Event schema validation

- **WHEN** a `data.collected` event is published
- **THEN** the event SHALL include `event_id` (UUID) and `timestamp` (ISO 8601) at the root level

---

### Requirement: Batch Upload to MinIO

The Crawler services SHALL upload crawl results in batches to MinIO instead of per-item uploads.

Batch sizes:

- TikTok: 50 items per batch
- YouTube: 20 items per batch

#### Scenario: TikTok batch upload

- **WHEN** TikTok crawler accumulates 50 content items
- **THEN** the service SHALL upload them as a single JSON file to MinIO
- **AND** the file path SHALL follow the pattern: `crawl-results/{project_id}/{brand|competitor}/batch_{index:03d}.json`

#### Scenario: YouTube batch upload

- **WHEN** YouTube crawler accumulates 20 content items
- **THEN** the service SHALL upload them as a single JSON file to MinIO
- **AND** the file path SHALL follow the same pattern as TikTok

#### Scenario: Remaining items upload

- **WHEN** crawling completes with fewer items than batch size remaining
- **THEN** the service SHALL upload the remaining items as a final batch

---

### Requirement: Project ID Extraction from Job ID

The Crawler services SHALL extract `project_id` from `job_id` for project execution tasks.

Job ID formats:

- Brand: `{projectID}-brand-{index}`
- Competitor: `{projectID}-{competitor_name}-{index}`
- Dry-run: `{uuid}` (no extraction needed)

#### Scenario: Extract project_id from brand job

- **WHEN** job_id is `"proj_abc-brand-0"`
- **THEN** the extracted project_id SHALL be `"proj_abc"`

#### Scenario: Extract project_id from competitor job

- **WHEN** job_id is `"proj_abc-toyota-0"`
- **THEN** the extracted project_id SHALL be `"proj_abc"`

#### Scenario: Dry-run job has no project_id

- **WHEN** job_id is a UUID (dry-run task)
- **THEN** project_id extraction SHALL return `None` or empty string

---

### Requirement: Enhanced Error Reporting

The Crawler services SHALL return structured error information when crawling fails.

#### Scenario: Rate limit error

- **WHEN** a crawler encounters a platform rate limit
- **THEN** the result SHALL include:
  - `success: false`
  - `error.code: "RATE_LIMITED"`
  - `error.details.retry_after`: Seconds until retry is safe

#### Scenario: Content removed error

- **WHEN** a crawler cannot find the requested content
- **THEN** the result SHALL include:
  - `success: false`
  - `error.code: "CONTENT_REMOVED"`
  - `error.details.url`: The URL that was not found

#### Scenario: Network error

- **WHEN** a crawler encounters a network connectivity issue
- **THEN** the result SHALL include:
  - `success: false`
  - `error.code: "NETWORK_ERROR"`
  - `error.message`: Human-readable description

---

### Requirement: Result Message Schema

The Crawler services SHALL return results in a standardized schema that includes all required fields for Collector routing.

#### Scenario: Successful result schema

- **WHEN** a crawler successfully processes content
- **THEN** the result message SHALL contain:
  ```json
  {
    "success": true,
    "payload": [
      {
        "meta": {
          "id": "<external_id>",
          "platform": "<tiktok|youtube>",
          "job_id": "<job_id>",
          "task_type": "<task_type>",
          "crawled_at": "<ISO8601>",
          "published_at": "<ISO8601>"
        },
        "content": {...},
        "interaction": {...},
        "author": {...},
        "comments": [...]
      }
    ]
  }
  ```

#### Scenario: Failed result schema

- **WHEN** a crawler fails to process content
- **THEN** the result message SHALL contain:
  ```json
  {
    "success": false,
    "payload": [],
    "error": {
      "code": "<ERROR_CODE>",
      "message": "<human_readable>",
      "details": {...}
    }
  }
  ```
