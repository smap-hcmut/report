# Design: Crawler Analyst Contract Compliance

## Context

Analytics Service đã publish Data Contract v2.0 với các yêu cầu mới cho event message và batch item structure. Crawler services (TikTok và YouTube) cần được cập nhật để tuân thủ contract này.

**Stakeholders:**

- Analytics Service (consumer)
- Collector Service (may use brand_name for routing)
- Crawler Services (TikTok, YouTube - producers)

**Constraints:**

- Backward compatibility với existing consumers
- Minimal code changes
- No breaking changes to existing functionality

## Goals / Non-Goals

**Goals:**

- Tuân thủ 100% Analytics Data Contract v2.0
- Maintain backward compatibility với existing fields
- Consistent implementation across TikTok và YouTube services

**Non-Goals:**

- Refactor existing code structure
- Add new features beyond contract compliance
- Change existing field names (only add new fields)

## Decisions

### Decision 1: Add fields to event payload (not replace)

**What:** Thêm `event_type`, `task_type`, `brand_name`, `keyword` vào event payload.

**Why:**

- Additive changes không break existing consumers
- Analytics Service có thể handle gracefully nếu fields missing trong transition period

**Alternatives considered:**

- Replace entire event structure → Rejected: Breaking change
- Version event schema → Rejected: Over-engineering for simple addition

### Decision 2: Extract brand_name from job_id for competitor jobs

**What:** Tạo helper function `extract_brand_info()` để extract brand_name từ job_id.

**Why:**

- Competitor job_id format: `{uuid}-competitor-{name}-{index}` đã chứa brand name
- Không cần thay đổi task payload structure

**Alternatives considered:**

- Always require brand_name in task payload → Rejected: Breaking change to Collector
- Store brand_name in separate config → Rejected: Over-engineering

### Decision 3: Keep both flat and nested comment author fields

**What:** Thêm `author_name` flat field, giữ lại `user` object.

**Why:**

- Contract yêu cầu flat `author_name`
- Existing consumers có thể đang dùng `user.name`
- Backward compatibility

**Alternatives considered:**

- Remove `user` object → Rejected: Breaking change
- Only keep `user` object → Rejected: Contract non-compliance

## Data Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  TaskService    │────▶│ CrawlerService  │────▶│ EventPublisher  │
│                 │     │                 │     │                 │
│ - task_type     │     │ - add_to_batch()│     │ - event_type    │
│ - keyword       │     │ - _upload_batch │     │ - task_type     │
│ - brand_name*   │     │ - flush_batch() │     │ - brand_name    │
└─────────────────┘     └─────────────────┘     │ - keyword       │
                                                └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │ Analytics Svc   │
                                                │ (Consumer)      │
                                                └─────────────────┘

* brand_name: extracted from job_id for competitor jobs,
              provided from task payload for brand jobs
```

## Implementation Strategy

### Phase 1: Event Message (P0)

1. Update `event_publisher.py` in both services
2. Update `crawler_service.py` to pass new params
3. Create `extract_brand_info()` helper

### Phase 2: Batch Item Structure (P1)

1. Update `helpers.py` - `map_to_new_format()` function
2. Fix platform uppercase
3. Add error_code, error_details
4. Add flat author_name to comments

## Risks / Trade-offs

| Risk                        | Impact | Mitigation                                    |
| --------------------------- | ------ | --------------------------------------------- |
| brand_name extraction fails | MEDIUM | Default to None, Analytics handles gracefully |
| Existing tests break        | LOW    | Update tests to expect new fields             |
| Performance impact          | LOW    | Minimal - only string operations              |

## Migration Plan

1. **Deploy Crawler updates** - New fields are additive
2. **Analytics Service** - Already expects new fields (contract v2.0)
3. **No rollback needed** - Changes are backward compatible

## Open Questions

1. **Q:** Should brand_name be required or optional in event payload?
   **A:** Required per contract, but Analytics should handle None gracefully.

2. **Q:** Should we validate brand_name format?
   **A:** No - trust upstream (Collector) to provide valid values.
