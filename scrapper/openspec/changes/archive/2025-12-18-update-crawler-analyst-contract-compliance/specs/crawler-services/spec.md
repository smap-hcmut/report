# Crawler Services - Contract Compliance Delta

## MODIFIED Requirements

### Requirement: DataCollected Event Publisher

The Crawler Service SHALL publish `data.collected` events to RabbitMQ `smap.events` exchange when batch data is uploaded to MinIO.

**Event Envelope Schema (Updated for Contract v2.0):**

```json
{
  "event_id": "string (unique)",
  "event_type": "data.collected",
  "timestamp": "string (ISO 8601)",
  "payload": {
    "minio_path": "string (required)",
    "project_id": "string (required, UUID)",
    "job_id": "string (required)",
    "batch_index": "integer (required, 1-based)",
    "content_count": "integer (required)",
    "platform": "string (required, lowercase: tiktok|youtube)",
    "task_type": "string (required)",
    "brand_name": "string (required)",
    "keyword": "string (required)"
  }
}
```

#### Scenario: Event published with all required fields

- **WHEN** a batch is uploaded to MinIO
- **THEN** the event SHALL include `event_type: "data.collected"`
- **AND** the payload SHALL include `task_type`, `brand_name`, `keyword`

#### Scenario: Brand name extracted from competitor job_id

- **WHEN** job_id format is `{uuid}-competitor-{name}-{index}`
- **THEN** `brand_name` SHALL be extracted as `{name}`

#### Scenario: Brand name provided for brand jobs

- **WHEN** job_id format is `{uuid}-brand-{index}`
- **THEN** `brand_name` SHALL be provided from task payload

---

### Requirement: Batch Item Meta Structure

The Crawler Service SHALL format batch item `meta` object according to Analytics Data Contract v2.0.

**Meta Object Schema:**

```json
{
  "id": "string (required)",
  "platform": "string (required, UPPERCASE: TIKTOK|YOUTUBE)",
  "fetch_status": "string (required: success|error)",
  "published_at": "string (required, ISO 8601)",
  "permalink": "string (required)",
  "error_code": "string (required if error)",
  "error_message": "string (optional)",
  "error_details": "object (optional)"
}
```

#### Scenario: Platform is UPPERCASE

- **WHEN** batch item is created for TikTok
- **THEN** `meta.platform` SHALL be `"TIKTOK"` (uppercase)

#### Scenario: Platform is UPPERCASE for YouTube

- **WHEN** batch item is created for YouTube
- **THEN** `meta.platform` SHALL be `"YOUTUBE"` (uppercase)

#### Scenario: Error item includes error_code

- **WHEN** crawl fails with an error
- **THEN** `meta.error_code` SHALL contain a valid ErrorCode enum value
- **AND** `meta.error_details` MAY contain additional error context

---

### Requirement: Batch Item Comments Structure

The Crawler Service SHALL format batch item `comments` array according to Analytics Data Contract v2.0.

**Comment Object Schema:**

```json
{
  "id": "string (optional)",
  "text": "string (required)",
  "author_name": "string (optional, flat field)",
  "likes": "integer (optional)",
  "created_at": "string (optional, ISO 8601)"
}
```

#### Scenario: Comment includes flat author_name

- **WHEN** comment is added to batch item
- **THEN** comment object SHALL include `author_name` as a flat field
- **AND** existing `user` object MAY be retained for backward compatibility

---

## ADDED Requirements

### Requirement: Brand Name Extraction Helper

The Crawler Service SHALL provide a helper function to extract brand information from job_id.

**Function Signature:**

```python
def extract_brand_info(job_id: str) -> tuple[Optional[str], str]:
    """
    Returns: (brand_name, brand_type)
    - brand_type: "brand" | "competitor" | "unknown"
    """
```

#### Scenario: Extract competitor name from job_id

- **WHEN** job_id is `"fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Toyota-0"`
- **THEN** function SHALL return `("Toyota", "competitor")`

#### Scenario: Brand job returns None for brand_name

- **WHEN** job_id is `"fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0"`
- **THEN** function SHALL return `(None, "brand")`
- **AND** caller SHALL provide brand_name from task payload

#### Scenario: Invalid job_id returns unknown

- **WHEN** job_id is empty or invalid format
- **THEN** function SHALL return `(None, "unknown")`
