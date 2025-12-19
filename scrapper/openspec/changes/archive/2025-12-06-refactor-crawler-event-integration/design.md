## Context

Collector Service đã được cập nhật để phân biệt giữa dry-run và project execution results dựa trên `task_type` field trong result meta. Tuy nhiên, Crawler services (TikTok/YouTube) chưa include field này, dẫn đến:

- Project execution results bị route sai → xử lý như dry-run
- Redis state không được update
- User không nhận được progress updates

**Stakeholders:**

- Crawler Team (TikTok/YouTube services)
- Collector Service (đã implement routing logic)
- Analytics Service (sẽ consume `data.collected` events)
- Project Service (nhận progress webhooks)

## Goals / Non-Goals

**Goals:**

- Add `task_type` field to all crawler result meta
- Create YouTube Result Publisher (TikTok already has one)
- Implement `data.collected` event publishing
- Implement batch upload to MinIO for better performance
- Standardize error reporting across services

**Non-Goals:**

- Modify Collector Service (already implemented)
- Implement Analytics Service consumer (separate scope)
- Change existing dry-run flow behavior

## Decisions

### Decision 1: TaskType Field Location

**What:** Add `task_type` to `meta` object of each content item, not at message root level.

**Why:**

- Collector extracts task_type from content items
- Allows mixed task_types in single batch (future flexibility)
- Consistent with existing meta structure

**Alternatives considered:**

- Add at message root level → Rejected: Collector already expects it in meta
- Add as separate field outside payload → Rejected: Breaking change to message schema

### Decision 2: YouTube Publisher Pattern

**What:** Copy TikTok publisher pattern with adjusted exchange/routing key.

**Why:**

- Proven pattern already working in production
- Consistent codebase across services
- Minimal implementation effort

**Alternatives considered:**

- Shared library for both services → Rejected: Adds complexity, services are independent
- Different message format → Rejected: Collector expects same format

### Decision 3: Batch Upload Strategy

**What:** Accumulate items in memory, upload when batch is full.

**Why:**

- Reduces MinIO operations (50x fewer for TikTok)
- Smaller message sizes in queue
- Analytics can parallel fetch from MinIO

**Alternatives considered:**

- Stream upload → Rejected: More complex, MinIO doesn't support well
- Per-item upload (current) → Rejected: Too many operations, queue congestion

### Decision 4: Batch Sizes

**What:** TikTok: 50 items, YouTube: 20 items

**Why:**

- TikTok content is smaller (~1KB per item)
- YouTube content is larger (~5KB per item with comments)
- Target batch file size: ~50-100KB

**Alternatives considered:**

- Same size for both → Rejected: YouTube batches would be too large
- Dynamic sizing → Rejected: Adds complexity, fixed sizes are predictable

### Decision 5: MinIO Path Structure

**What:** `crawl-results/{project_id}/{brand|competitor}/batch_{index:03d}.json`

**Why:**

- Organized by project for easy cleanup
- Separated by brand/competitor for parallel processing
- Zero-padded index for proper sorting

**Alternatives considered:**

- Flat structure → Rejected: Hard to manage at scale
- Date-based partitioning → Rejected: Project-based is more useful

### Decision 6: Event Publisher Separation

**What:** Separate `DataCollectedEventPublisher` class from existing `RabbitMQPublisher`.

**Why:**

- Different exchange (`smap.events` vs `results.inbound`)
- Different routing key pattern
- Single Responsibility Principle

**Alternatives considered:**

- Extend existing publisher → Rejected: Violates SRP, harder to test
- Generic publisher with config → Rejected: Over-engineering for 2 use cases

## Risks / Trade-offs

| Risk                                       | Impact | Mitigation                                          |
| ------------------------------------------ | ------ | --------------------------------------------------- |
| Missing task_type breaks project execution | HIGH   | Collector defaults to dry-run (backward compatible) |
| Batch upload increases memory usage        | MEDIUM | Configurable batch size, flush on shutdown          |
| Event publisher connection failure         | MEDIUM | Retry logic, graceful degradation                   |
| MinIO path conflicts                       | LOW    | Include timestamp in batch filename                 |
| Batch upload increases latency             | MEDIUM | Async upload, don't block crawling                  |

## Migration Plan

### Phase 1: TaskType Implementation (Week 1)

1. Add `task_type` field to result meta (both services)
2. Create YouTube publisher
3. Propagate `task_type` from task to result
4. Deploy and verify Collector routing works

**Rollback:** Remove task_type field, Collector falls back to dry-run handler

### Phase 2: Event-Driven Integration (Week 2)

1. Create `DataCollectedEventPublisher`
2. Implement batch upload logic
3. Publish `data.collected` events
4. Test with Analytics Service (mock)

**Rollback:** Disable event publishing, continue with per-item upload

### Phase 3: Optimization (Week 3)

1. Tune batch sizes based on metrics
2. Add metadata.json generation
3. Performance testing
4. Enhanced error reporting

**Rollback:** Revert to default batch sizes

## Open Questions

1. **Q:** Should we support mixed task_types in a single batch?
   **A:** Not for now, but design allows it for future flexibility.

2. **Q:** How to handle partial batch upload failures?
   **A:** Retry entire batch, log failed items for investigation.

3. **Q:** Should Analytics Service be notified of dry-run results?
   **A:** No, dry-run results go directly to Project Service via Collector.

## Data Flow Diagrams

### Current Flow (Broken for Project Execution)

```
Crawler → RabbitMQ (no task_type) → Collector → handleDryRunResult() ❌
```

### Target Flow (After Implementation)

```
Crawler → MinIO (batch upload)
       → RabbitMQ (data.collected event with minio_path)
       → Analytics Service (fetch from MinIO)

Crawler → RabbitMQ (result with task_type) → Collector
       → handleProjectResult() → Redis + Progress Webhook ✅
```

### Message Flow Sequence

```
1. TaskService receives task message
2. TaskService extracts task_type from message
3. TaskService calls CrawlerService.fetch_videos_batch(task_type=...)
4. CrawlerService crawls content
5. CrawlerService calls map_to_new_format(task_type=...)
6. CrawlerService accumulates batch
7. When batch full:
   a. Upload batch to MinIO
   b. Publish data.collected event
8. CrawlerService returns results to TaskService
9. TaskService publishes result to Collector
10. Collector routes based on task_type
```
