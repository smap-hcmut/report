# Spec Delta: Crawler Services

## ADDED Requirements

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

## Configuration Reference

### Environment Variables

| Variable                    | Default | Description                                  |
| --------------------------- | ------- | -------------------------------------------- |
| `DEFAULT_SEARCH_LIMIT`      | 50      | Default for research_keyword, dryrun_keyword |
| `DEFAULT_LIMIT_PER_KEYWORD` | 50      | Default for research_and_crawl               |
| `DEFAULT_CHANNEL_LIMIT`     | 100     | Default for fetch_channel_content (YouTube)  |
| `DEFAULT_PROFILE_LIMIT`     | 100     | Default for fetch_profile_content (TikTok)   |
| `DEFAULT_CRAWL_LINKS_LIMIT` | 200     | Default for crawl_links                      |
| `MAX_SEARCH_LIMIT`          | 500     | Maximum for search-based tasks               |
| `MAX_CRAWL_LINKS_LIMIT`     | 1000    | Maximum for crawl_links                      |
| `MAX_CHANNEL_LIMIT`         | 500     | Maximum for fetch_channel_content            |
| `MAX_PROFILE_LIMIT`         | 500     | Maximum for fetch_profile_content            |

### Response Format

```json
{
  "success": true,
  "task_type": "dryrun_keyword",
  "limit_info": {
    "requested_limit": 50,
    "applied_limit": 50,
    "total_found": 30,
    "platform_limited": true
  },
  "stats": {
    "successful": 28,
    "failed": 2,
    "skipped": 0,
    "completion_rate": 0.93
  },
  "error": {
    "code": "RATE_LIMITED",
    "message": "Platform rate limit exceeded"
  },
  "payload": [...]
}
```

### Error Codes

| Code              | Description           | Retryable |
| ----------------- | --------------------- | --------- |
| `SEARCH_FAILED`   | Search API failed     | ✅ Yes    |
| `RATE_LIMITED`    | Platform rate limit   | ✅ Yes    |
| `AUTH_FAILED`     | Authentication failed | ❌ No     |
| `INVALID_KEYWORD` | Invalid keyword       | ❌ No     |
| `TIMEOUT`         | Request timeout       | ✅ Yes    |
| `UNKNOWN`         | Unknown error         | ✅ Yes    |
