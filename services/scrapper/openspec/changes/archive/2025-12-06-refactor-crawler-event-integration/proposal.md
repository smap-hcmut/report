# Change: Refactor Crawler Services for Event-Driven Integration

## Why

Collector Service đã được cập nhật để phân biệt giữa dry-run và project execution results, nhưng Crawler services (TikTok/YouTube) **chưa tương thích**:

1. **Missing `task_type` in result meta** → Collector không thể route đúng → Project execution bị xử lý như dry-run
2. **YouTube thiếu Result Publisher** → Không thể gửi kết quả về Collector
3. **Chưa có DataCollected Event** → Analytics Service không nhận được data để phân tích
4. **Per-item upload thay vì batch** → Không tối ưu, gây nghẽn queue

**Impact nếu không fix:**

- User không nhận được progress updates cho project execution
- Redis state không được update
- Analytics pipeline bị block

## What Changes

### P0 - Critical (MUST DO)

1. **Add `task_type` to result meta** (TikTok + YouTube)

   - Update `map_to_new_format()` function
   - Propagate `task_type` through call chain
   - Values: `dryrun_keyword`, `research_and_crawl`, `research_keyword`, `crawl_links`

2. **Create RabbitMQ Publisher for YouTube**
   - Copy pattern from TikTok
   - Publish results to `results.inbound` exchange

### P1 - Required (SHOULD DO)

3. **Implement DataCollected Event Publisher** (TikTok + YouTube)

   - Publish to `smap.events` exchange with routing key `data.collected`
   - Include `minio_path` for Analytics Service to fetch data

4. **Implement Batch Upload to MinIO**
   - TikTok: 50 items per batch
   - YouTube: 20 items per batch
   - Path structure: `crawl-results/{project_id}/{brand|competitor}/batch_{index}.json`

### P2 - Recommended (NICE TO HAVE)

5. **Enhanced Error Reporting**
   - Structured error codes: `RATE_LIMITED`, `AUTH_FAILED`, `NETWORK_ERROR`, etc.
   - Include `retry_after` for retryable errors

## Impact

- **Affected specs:** `crawler-services` (new capability)
- **Affected code:**

  - `scrapper/tiktok/utils/helpers.py`
  - `scrapper/tiktok/application/crawler_service.py`
  - `scrapper/tiktok/application/task_service.py`
  - `scrapper/tiktok/app/bootstrap.py`
  - `scrapper/youtube/utils/helpers.py`
  - `scrapper/youtube/application/crawler_service.py`
  - `scrapper/youtube/application/task_service.py`
  - `scrapper/youtube/app/bootstrap.py`
  - `scrapper/youtube/internal/infrastructure/rabbitmq/` (new files)

- **Dependencies:**
  - Collector Service (already implemented task_type routing)
  - Analytics Service (will consume `data.collected` events)
  - MinIO (for batch storage)

## Estimated Effort

| Priority | Component                        | Effort  |
| -------- | -------------------------------- | ------- |
| P0       | TaskType in meta (both services) | 6 hours |
| P0       | YouTube Result Publisher         | 2 hours |
| P1       | DataCollected Event Publisher    | 4 hours |
| P1       | Batch Upload Logic               | 8 hours |
| P2       | Enhanced Error Reporting         | 4 hours |

**Total:** ~24 hours (3-4 days)

## Risks

| Risk                                         | Impact | Mitigation                                                  |
| -------------------------------------------- | ------ | ----------------------------------------------------------- |
| Missing `task_type` breaks project execution | HIGH   | Collector defaults to dry-run handler (backward compatible) |
| Batch upload increases latency               | MEDIUM | Async upload, configurable batch size                       |
| Event publisher connection failure           | MEDIUM | Retry logic, graceful degradation                           |
