# Design: CrawlerResultMessage Publish for research_and_crawl

## Context

Collector Service cần nhận thông báo khi Crawler hoàn thành task `research_and_crawl` để:

1. Update Redis state (tasks_done, items_actual, items_errors)
2. Send progress webhook về Project Service
3. Check project completion

Hiện tại chỉ có `dryrun_keyword` publish result, `research_and_crawl` không publish.

## Goals

- Crawler publish `CrawlerResultMessage` về Collector sau khi `research_and_crawl` hoàn thành
- Message format theo contract specification (flat, no payload)
- Không thay đổi `data.collected` event (vẫn cần cho Analytics)

## Non-Goals

- Không thay đổi `dryrun_keyword` behavior
- Không thay đổi `data.collected` event format
- Không thay đổi Collector implementation (chỉ thêm message từ Crawler)

## Decisions

### Decision 1: Reuse existing `result_publisher`

**What:** Sử dụng `result_publisher` đã có sẵn (dùng cho `dryrun_keyword`)

**Why:**

- Đã được inject và configured trong `bootstrap.py`
- Đã connect đến đúng exchange (`results.inbound`)
- Đã có routing key configured (`tiktok.res` / `youtube.res`)

**Alternatives considered:**

- Tạo publisher mới → Không cần thiết, tăng complexity

### Decision 2: Flat message format (no payload)

**What:** Message chỉ chứa stats summary, không chứa content payload

**Why:**

- Theo contract specification `collector-crawler-contract.md`
- Content đã được upload lên MinIO và notify qua `data.collected` event
- Collector chỉ cần stats để update Redis state

**Message structure:**

```json
{
  "success": true,
  "task_type": "research_and_crawl",
  "job_id": "proj123-brand-0",
  "platform": "tiktok",
  "requested_limit": 50,
  "applied_limit": 50,
  "total_found": 30,
  "platform_limited": true,
  "successful": 28,
  "failed": 2,
  "skipped": 0,
  "error_code": null,
  "error_message": null
}
```

### Decision 3: Publish timing - after task completion

**What:** Publish message SAU KHI `_handle_research_and_crawl()` hoàn thành (tất cả batches done)

**Why:**

- Collector cần biết tổng số items đã crawl
- `data.collected` event gửi per batch, `CrawlerResultMessage` gửi per task

**Flow:**

```
research_and_crawl task
    │
    ├── Crawl keyword 1
    │   ├── Upload batch 1 → data.collected event
    │   └── Upload batch 2 → data.collected event
    │
    ├── Crawl keyword 2
    │   └── Upload batch 3 → data.collected event
    │
    └── Task complete → CrawlerResultMessage (this change)
```

### Decision 4: Error handling - graceful failure

**What:** Nếu publish fail, log error nhưng không fail task

**Why:**

- Task đã hoàn thành, data đã được lưu
- Publish failure không nên rollback crawl work
- Consistent với `_publish_dryrun_result()` behavior

## Risks / Trade-offs

| Risk                    | Mitigation                             |
| ----------------------- | -------------------------------------- |
| Publisher not connected | Log warning, continue (same as dryrun) |
| Message format mismatch | Unit tests validate format             |
| Duplicate messages      | Collector should be idempotent         |

## Implementation Details

### Method signature

```python
async def _publish_research_and_crawl_result(
    self,
    job_id: str,
    result: Dict[str, Any],
    success: bool,
    requested_limit: int,
    error: Optional[Exception] = None,
) -> None:
```

### Integration point in handle_task()

```python
elif task_type == "research_and_crawl":
    result = await self._handle_research_and_crawl(...)

    # NEW: Publish result to Collector
    keywords = payload.get("keywords", [])
    limit_per_keyword = self._get_limit(
        payload, "limit_per_keyword",
        settings.default_limit_per_keyword,
        settings.max_search_limit,
    )
    await self._publish_research_and_crawl_result(
        job_id=job_id,
        result=result,
        success=True,
        requested_limit=limit_per_keyword * len(keywords),
    )
```

## Open Questions

1. **Q:** Có cần publish cho `crawl_links` và `fetch_profile_content` không?
   **A:** Theo contract, chỉ `research_and_crawl` cần publish. Các task khác có thể thêm sau nếu cần.

2. **Q:** `requested_limit` tính như thế nào khi có multiple keywords?
   **A:** `limit_per_keyword * len(keywords)` - tổng limit expected
