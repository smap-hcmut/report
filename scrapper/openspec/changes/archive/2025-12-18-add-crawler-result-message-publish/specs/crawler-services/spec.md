## ADDED Requirements

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

## MODIFIED Requirements

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
