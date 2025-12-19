# crawler-services Specification

## Purpose
TBD - created by archiving change refactor-crawler-event-integration. Update Purpose after archive.
## Requirements
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

- **WHEN** YouTube crawler completes a `research_and_crawl` task
- **THEN** the service SHALL publish a `CrawlerResultMessage` to `results.inbound` exchange
- **AND** the message SHALL use flat format with `task_type: "research_and_crawl"`
- **AND** the message SHALL NOT contain a `payload` field

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

### Requirement: Configurable Limit Settings

The Crawler services SHALL provide configurable limit settings via environment variables for all task types.

#### Scenario: Default limits are applied when payload doesn't specify

- **GIVEN** a task payload without limit field
- **WHEN** the task is processed
- **THEN** the default limit from settings SHALL be applied
- **AND** the default limit SHALL be configurable via environment variable

#### Scenario: Max limits cap excessive values

- **GIVEN** a task payload with limit exceeding max_limit
- **WHEN** the task is processed
- **THEN** the limit SHALL be capped at max_limit
- **AND** a warning SHALL be logged

#### Scenario: Invalid limits use defaults

- **GIVEN** a task payload with limit <= 0
- **WHEN** the task is processed
- **THEN** the default limit SHALL be applied

---

### Requirement: Limit Enforcement for crawl_links Task

The Crawler services SHALL enforce a limit on the number of URLs processed in `crawl_links` tasks.

#### Scenario: URLs are truncated when exceeding limit

- **GIVEN** a `crawl_links` task with more URLs than the limit
- **WHEN** the task is processed
- **THEN** only the first N URLs (up to limit) SHALL be processed
- **AND** a warning SHALL be logged indicating truncation

#### Scenario: Default limit is applied when not specified

- **GIVEN** a `crawl_links` task without limit field
- **WHEN** the task is processed
- **THEN** the default_crawl_links_limit SHALL be applied

---

### Requirement: Limit Enforcement for fetch_profile_content Task (TikTok)

The TikTok Crawler service SHALL enforce a limit on the number of videos fetched from a profile.

#### Scenario: Profile videos are limited

- **GIVEN** a `fetch_profile_content` task with a limit
- **WHEN** the task is processed
- **THEN** only the first N videos (up to limit) SHALL be fetched

#### Scenario: Default limit is applied when not specified

- **GIVEN** a `fetch_profile_content` task without limit field
- **WHEN** the task is processed
- **THEN** the default_profile_limit SHALL be applied

---

### Requirement: Enhanced Response Format for dryrun_keyword

The Crawler services SHALL return an enhanced response format for `dryrun_keyword` tasks that includes task_type, limit_info, stats, and error objects.

#### Scenario: Success response includes all required fields

- **GIVEN** a successful `dryrun_keyword` task
- **WHEN** the result is published
- **THEN** the response SHALL include:
  - `success: true`
  - `task_type: "dryrun_keyword"`
  - `limit_info` object with `requested_limit`, `applied_limit`, `total_found`, `platform_limited`
  - `stats` object with `successful`, `failed`, `skipped`, `completion_rate`
  - `payload` array with crawl results

#### Scenario: Failure response includes error object

- **GIVEN** a failed `dryrun_keyword` task
- **WHEN** the result is published
- **THEN** the response SHALL include:
  - `success: false`
  - `task_type: "dryrun_keyword"`
  - `error` object with `code` and `message`
  - `limit_info` object (with zeros if applicable)
  - `stats` object (with zeros)
  - `payload: []`

#### Scenario: Platform limited flag is set correctly

- **GIVEN** a search that returns fewer results than requested limit
- **WHEN** the result is published
- **THEN** `limit_info.platform_limited` SHALL be `true`
- **AND** `limit_info.total_found` SHALL be less than `limit_info.requested_limit`

#### Scenario: No results case

- **GIVEN** a search that returns zero results
- **WHEN** the result is published
- **THEN** `success` SHALL be `true`
- **AND** `limit_info.platform_limited` SHALL be `true`
- **AND** `stats.successful` SHALL be `0`
- **AND** `payload` SHALL be empty array

---

### Requirement: Standard Error Codes

The Crawler services SHALL use standard error codes in the error response object.

#### Scenario: Search failure maps to SEARCH_FAILED

- **GIVEN** a task that fails due to search API error
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `SEARCH_FAILED`

#### Scenario: Rate limit maps to RATE_LIMITED

- **GIVEN** a task that fails due to platform rate limiting
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `RATE_LIMITED`

#### Scenario: Authentication failure maps to AUTH_FAILED

- **GIVEN** a task that fails due to authentication error
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `AUTH_FAILED`

#### Scenario: Invalid keyword maps to INVALID_KEYWORD

- **GIVEN** a task that fails due to invalid keyword
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `INVALID_KEYWORD`

#### Scenario: Timeout maps to TIMEOUT

- **GIVEN** a task that fails due to timeout
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `TIMEOUT`

#### Scenario: Unknown error maps to UNKNOWN

- **GIVEN** a task that fails due to unknown error
- **WHEN** the error is mapped
- **THEN** the error code SHALL be `UNKNOWN`

---

### Requirement: fetch_channel_content Default Limit (YouTube)

The YouTube Crawler service SHALL use a configurable default limit for `fetch_channel_content` tasks instead of unlimited (0).

#### Scenario: Default limit is applied instead of unlimited

- **GIVEN** a `fetch_channel_content` task without limit field
- **WHEN** the task is processed
- **THEN** the default_channel_limit (100) SHALL be applied
- **AND** the behavior SHALL NOT be unlimited

#### Scenario: Limit can be overridden via payload

- **GIVEN** a `fetch_channel_content` task with explicit limit
- **WHEN** the task is processed
- **THEN** the specified limit SHALL be used (up to max_channel_limit)

---

### Requirement: Consistent Default Limits Across Platforms

The Crawler services SHALL use consistent default limits for equivalent task types across YouTube and TikTok.

#### Scenario: dryrun_keyword uses same default on both platforms

- **GIVEN** a `dryrun_keyword` task without limit field
- **WHEN** processed by YouTube Crawler
- **THEN** default_search_limit (50) SHALL be applied

- **GIVEN** a `dryrun_keyword` task without limit field
- **WHEN** processed by TikTok Crawler
- **THEN** default_search_limit (50) SHALL be applied
- **AND** the previous inconsistent default (10) SHALL NOT be used

---

### Requirement: CrawlerResultMessage Publish for research_and_crawl

The Crawler services SHALL publish a `CrawlerResultMessage` to the Collector Service after completing a `research_and_crawl` task.

The message SHALL be published to:

- Exchange: `results.inbound` (direct type)
- Routing Key: `tiktok.res` (TikTok) or `youtube.res` (YouTube)

The message SHALL use a **flat format** (no nested payload) containing only task statistics.

#### Scenario: Successful research_and_crawl publishes result

- **WHEN** a crawler successfully completes a `research_and_crawl` task
- **THEN** the service SHALL publish a `CrawlerResultMessage` with:
  - `success: true`
  - `task_type: "research_and_crawl"`
  - `job_id`: The original job identifier
  - `platform`: `"tiktok"` or `"youtube"`
  - `requested_limit`: Total limit requested (limit_per_keyword × number of keywords)
  - `applied_limit`: Actual limit applied
  - `total_found`: Total items found on platform
  - `platform_limited`: `true` if `total_found < requested_limit`
  - `successful`: Number of items crawled successfully
  - `failed`: Number of items that failed to crawl
  - `skipped`: Number of items skipped
  - `error_code: null`
  - `error_message: null`

#### Scenario: Failed research_and_crawl publishes error result

- **WHEN** a crawler fails to complete a `research_and_crawl` task
- **THEN** the service SHALL publish a `CrawlerResultMessage` with:
  - `success: false`
  - `task_type: "research_and_crawl"`
  - `job_id`: The original job identifier
  - `platform`: `"tiktok"` or `"youtube"`
  - `error_code`: One of the standard error codes
  - `error_message`: Human-readable error description
  - All stats fields set to `0`

#### Scenario: Platform limited flag calculation

- **GIVEN** a `research_and_crawl` task with `requested_limit` of 100
- **WHEN** the platform returns only 30 items
- **THEN** `platform_limited` SHALL be `true`
- **AND** `total_found` SHALL be `30`

#### Scenario: No results case

- **GIVEN** a `research_and_crawl` task for a keyword with no results
- **WHEN** the task completes
- **THEN** `success` SHALL be `true`
- **AND** `platform_limited` SHALL be `true`
- **AND** `total_found` SHALL be `0`
- **AND** `successful` SHALL be `0`

#### Scenario: Publish timing

- **WHEN** a `research_and_crawl` task completes (all keywords processed, all batches uploaded)
- **THEN** the `CrawlerResultMessage` SHALL be published AFTER all `data.collected` events
- **AND** the message SHALL contain aggregated statistics from all keywords

#### Scenario: Publisher failure handling

- **WHEN** the result publisher fails to publish the message
- **THEN** the error SHALL be logged
- **AND** the task SHALL NOT be marked as failed (data is already persisted)

---

### Requirement: CrawlerResultMessage Flat Format

The `CrawlerResultMessage` for `research_and_crawl` tasks SHALL NOT include a `payload` field with content items.

#### Scenario: Message does not contain payload

- **WHEN** a `CrawlerResultMessage` is published for `research_and_crawl`
- **THEN** the message SHALL NOT contain a `payload` field
- **AND** the message SHALL only contain statistics fields at the root level

#### Scenario: Content is delivered via data.collected events

- **WHEN** content items are crawled during `research_and_crawl`
- **THEN** the content SHALL be uploaded to MinIO in batches
- **AND** `data.collected` events SHALL notify Analytics of each batch
- **AND** `CrawlerResultMessage` SHALL only report statistics

---

