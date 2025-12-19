# Change: Add CrawlerResultMessage Publish for research_and_crawl

## Why

Hiện tại cả TikTok và YouTube crawler **KHÔNG** publish result message về Collector sau khi hoàn thành task `research_and_crawl`. Chỉ có `dryrun_keyword` mới publish result.

**Hệ quả:**

- Collector không biết khi nào task hoàn thành
- Redis state không được update (`tasks_done`, `items_actual`, `items_errors`)
- Progress webhook không được gửi về Project Service
- Project completion check không hoạt động

**Evidence từ code:**

- TikTok `task_service.py` line 181-183: Chỉ publish cho `dryrun_keyword`
- YouTube `task_service.py` line 152-156: Chỉ publish cho `dryrun_keyword`

## What Changes

1. **ADDED**: Method `_publish_research_and_crawl_result()` trong `TaskService` (cả TikTok và YouTube)
2. **MODIFIED**: `handle_task()` để gọi publish sau khi `research_and_crawl` hoàn thành
3. **ADDED**: Flat message format theo `CrawlerResultMessage` contract (không có payload)

**Message Format (theo collector-crawler-contract.md):**

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

## Impact

- **Affected specs:** `crawler-services`
- **Affected code:**
  - `scrapper/tiktok/application/task_service.py`
  - `scrapper/youtube/application/task_service.py`
- **Dependencies:** Sử dụng `result_publisher` đã có sẵn (dùng cho `dryrun_keyword`)
- **Breaking changes:** Không có - đây là thêm mới, không thay đổi behavior hiện tại

## Related Documents

- `scrapper/document/collector-crawler-contract.md` - Contract specification
- `scrapper/document/crawler-collector-contract-gap-analysis.md` - Gap analysis
- `scrapper/document/crawler-to-collector-response-contract.md` - Response contract details
