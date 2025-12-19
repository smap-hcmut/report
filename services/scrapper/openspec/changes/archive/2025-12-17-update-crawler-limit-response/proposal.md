# Change: Update Crawler Limit Enforcement & Response Format

## Why

Hiện tại có 3 vấn đề nghiêm trọng trong Crawler services:

1. **Thiếu Limit Enforcement**: Một số task types (`crawl_links`, `fetch_channel_content`, `fetch_profile_content`) không có limit hoặc default là unlimited (0), gây risk resource exhaustion và unexpected behavior.

2. **Hardcoded Default Values**: Tất cả limit defaults đều hardcode trong code (50, 10, 0), không configurable qua environment variables, gây khó khăn khi cần điều chỉnh theo môi trường.

3. **Response Format Thiếu Fields**: Response gửi về Collector thiếu các fields quan trọng (`task_type`, `limit_info`, `stats`, `error`), khiến Collector không thể track chính xác trạng thái crawl.

## What Changes

### Config Changes

- **ADDED**: 10 limit settings mới trong `config/settings.py` (cả YouTube và TikTok)
- **ADDED**: Environment variables tương ứng trong `.env.example`
- **ADDED**: K8s manifest updates cho env vars

### Task Service Changes

- **ADDED**: Helper method `_get_limit()` để validate và cap limits
- **ADDED**: Helper method `_map_error_code()` để map error types sang standard codes
- **MODIFIED**: `_handle_research_keyword()` - dùng config thay vì hardcode
- **MODIFIED**: `_handle_research_and_crawl()` - dùng config thay vì hardcode
- **MODIFIED**: `_handle_crawl_links()` - **THÊM limit enforcement** (hiện không có)
- **MODIFIED**: `_handle_fetch_channel_content()` (YouTube) - **FIX default 0 → config**
- **MODIFIED**: `_handle_fetch_profile_content()` (TikTok) - **THÊM limit parameter**
- **MODIFIED**: `_handle_dryrun_keyword()` - dùng config, fix inconsistent defaults
- **MODIFIED**: `_publish_dryrun_result()` - **NEW response format** với `task_type`, `limit_info`, `stats`, `error`

### Crawler Service Changes

- **MODIFIED**: `fetch_profile_videos()` (TikTok) - thêm limit parameter
- **MODIFIED**: `fetch_channel_videos()` (YouTube) - fix limit logic

## Impact

### Affected Specs

- `specs/crawler-services/spec.md` - Task handling và response format

### Affected Code

**YouTube Crawler:**

- `scrapper/youtube/config/settings.py`
- `scrapper/youtube/.env.example`
- `scrapper/youtube/application/task_service.py`
- `scrapper/youtube/application/crawler_service.py`
- `scrapper/youtube/k8s/*.yaml`

**TikTok Crawler:**

- `scrapper/tiktok/config/settings.py`
- `scrapper/tiktok/.env.example`
- `scrapper/tiktok/application/task_service.py`
- `scrapper/tiktok/application/crawler_service.py`
- `scrapper/tiktok/k8s/*.yaml`

### Breaking Changes

| Change                      | Impact                          | Mitigation                             |
| --------------------------- | ------------------------------- | -------------------------------------- |
| `crawl_links` có limit      | Tasks với >200 URLs bị truncate | Default cao (200), log warning         |
| `fetch_channel` default ≠ 0 | Unlimited crawls bị limit       | Default 100, có thể override           |
| `fetch_profile` có limit    | Unlimited crawls bị limit       | Default 100, có thể override           |
| New response fields         | Collector cần handle            | Additive change, Collector có fallback |

### Backward Compatibility

- Response format mới là **additive** - Collector đã có fallback logic
- Default limits giữ nguyên behavior cũ (50 cho search)
- New config vars có defaults - không bắt buộc set

## Related Documents

- `scrapper/document/crawler-implementation-plan.md` - Chi tiết implementation
- `scrapper/document/crawler-response-update-request.md` - Contract từ Collector
- `scrapper/document/collector-crawler-contract.md` - Full contract specification
- `scrapper/document/crawler-limit-optimization.md` - Phân tích vấn đề limit
