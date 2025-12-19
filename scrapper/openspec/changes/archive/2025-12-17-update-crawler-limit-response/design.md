# Design: Crawler Limit Enforcement & Response Format

## Context

### Background

Crawler services (YouTube và TikTok) nhận tasks từ Collector/Dispatcher qua RabbitMQ và trả về kết quả. Hiện tại có các vấn đề:

1. **Limit không được enforce đồng nhất** - một số task types không có limit
2. **Defaults hardcode trong code** - khó điều chỉnh theo môi trường
3. **Response format thiếu metadata** - Collector không track được chính xác

### Stakeholders

- **Collector Service**: Consumer của response, cần `limit_info` và `stats` để update state
- **Crawler Workers**: Producer của response, cần implement new format
- **DevOps**: Cần config qua env vars và K8s manifests

### Constraints

- Backward compatible với Collector (Collector đã có fallback logic)
- Không thay đổi message format từ Collector → Crawler
- Giữ nguyên default behavior cho existing tasks

---

## Goals / Non-Goals

### Goals

1. ✅ Tất cả task types phải có limit enforcement
2. ✅ Tất cả limit defaults phải configurable qua env vars
3. ✅ Response format phải có đủ fields theo contract
4. ✅ Backward compatible với Collector

### Non-Goals

- ❌ Thay đổi message format từ Collector → Crawler
- ❌ Thay đổi internal crawl logic (chỉ thêm limit enforcement)
- ❌ Thay đổi storage behavior (MinIO, MongoDB)

---

## Decisions

### Decision 1: Limit Config Structure

**What**: Thêm 2 loại config - default limits và max limits (safety caps)

**Why**:

- Default limits: Giá trị mặc định khi payload không specify
- Max limits: Safety cap để prevent resource exhaustion

**Config Structure:**

```python
# Default limits
default_search_limit: int = 50              # research_keyword, dryrun_keyword
default_limit_per_keyword: int = 50         # research_and_crawl
default_channel_limit: int = 100            # fetch_channel_content (YouTube)
default_profile_limit: int = 100            # fetch_profile_content (TikTok)
default_crawl_links_limit: int = 200        # crawl_links max URLs

# Hard limits (safety caps)
max_search_limit: int = 500
max_crawl_links_limit: int = 1000
max_channel_limit: int = 500
max_profile_limit: int = 500
```

**Alternatives Considered:**

- Single limit for all task types → Rejected: Không flexible
- No max limits → Rejected: Risk resource exhaustion

---

### Decision 2: Limit Validation Helper

**What**: Thêm helper method `_get_limit()` trong TaskService

**Why**:

- DRY principle - tránh duplicate validation logic
- Consistent behavior across all handlers
- Centralized logging for limit capping

**Implementation:**

```python
def _get_limit(self, payload, key, default, max_limit) -> int:
    limit = payload.get(key)
    if limit is None or limit <= 0:
        limit = default
    if limit > max_limit:
        logger.warning(f"{key}={limit} exceeds max={max_limit}, capping")
        limit = max_limit
    return limit
```

**Alternatives Considered:**

- Inline validation in each handler → Rejected: Code duplication
- Decorator pattern → Rejected: Overkill for simple validation

---

### Decision 3: Response Format Structure

**What**: Thêm `task_type`, `limit_info`, `stats`, `error` vào response root level

**Why**: Contract requirement từ Collector để track state chính xác

**Response Structure:**

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
  "payload": [...]
}
```

**Alternatives Considered:**

- Nested under `metadata` object → Rejected: Contract specifies root level
- Only add `stats` → Rejected: `limit_info` needed for platform limitation tracking

---

### Decision 4: Error Code Mapping

**What**: Map internal error types sang standard error codes

**Why**: Collector cần standard codes để quyết định retry logic

**Mapping:**

```python
error_mapping = {
    "infrastructure": "SEARCH_FAILED",
    "scraping": "SEARCH_FAILED",
    "rate_limit": "RATE_LIMITED",
    "auth": "AUTH_FAILED",
    "invalid_input": "INVALID_KEYWORD",
    "timeout": "TIMEOUT",
}
```

**Standard Codes:**
| Code | Description | Retryable |
|------|-------------|-----------|
| `SEARCH_FAILED` | Search API failed | ✅ Yes |
| `RATE_LIMITED` | Platform rate limit | ✅ Yes |
| `AUTH_FAILED` | Authentication failed | ❌ No |
| `INVALID_KEYWORD` | Invalid keyword | ❌ No |
| `TIMEOUT` | Request timeout | ✅ Yes |
| `UNKNOWN` | Unknown error | ✅ Yes |

---

## Architecture

### Component Interaction

```
┌─────────────────────────────────────────────────────────────────┐
│                        TaskService                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ _get_limit() │    │ _map_error   │    │ _publish_    │       │
│  │              │    │ _code()      │    │ dryrun_result│       │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘       │
│         │                   │                   │                │
│         ▼                   ▼                   ▼                │
│  ┌──────────────────────────────────────────────────────┐       │
│  │                    Task Handlers                      │       │
│  │  _handle_research_keyword()                          │       │
│  │  _handle_research_and_crawl()                        │       │
│  │  _handle_crawl_links()                               │       │
│  │  _handle_fetch_channel_content()                     │       │
│  │  _handle_fetch_profile_content()                     │       │
│  │  _handle_dryrun_keyword()                            │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CrawlerService                              │
├─────────────────────────────────────────────────────────────────┤
│  search_videos()           → Returns video URLs                  │
│  fetch_videos_batch()      → Crawl videos                       │
│  fetch_channel_videos()    → Crawl channel (YouTube)            │
│  fetch_profile_videos()    → Crawl profile (TikTok)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Settings                                  │
├─────────────────────────────────────────────────────────────────┤
│  default_search_limit      = 50                                  │
│  default_limit_per_keyword = 50                                  │
│  default_channel_limit     = 100                                 │
│  default_profile_limit     = 100                                 │
│  default_crawl_links_limit = 200                                 │
│  max_search_limit          = 500                                 │
│  max_crawl_links_limit     = 1000                                │
│  max_channel_limit         = 500                                 │
│  max_profile_limit         = 500                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Collector sends task message
   ↓
2. TaskService.handle_task() receives message
   ↓
3. _get_limit() validates and caps limit from payload
   ↓
4. Handler calls CrawlerService with validated limit
   ↓
5. CrawlerService enforces limit during crawl
   ↓
6. Handler collects stats (successful, failed, skipped)
   ↓
7. _publish_dryrun_result() formats response with new fields
   ↓
8. Response published to Collector
```

---

## Risks / Trade-offs

### Risk 1: Breaking Existing Unlimited Crawls

**Risk**: Tasks relying on unlimited behavior (limit=0) will be capped

**Mitigation**:

- Default limits are generous (100-200)
- Log warnings when capping
- Document in release notes

### Risk 2: Config Drift Between Environments

**Risk**: Different environments may have different limits

**Mitigation**:

- Document recommended values
- K8s ConfigMaps for consistency
- Validation in settings.py

### Risk 3: Response Format Mismatch

**Risk**: Collector may not handle new fields correctly

**Mitigation**:

- Collector already has fallback logic
- Deploy Collector first with fallback
- New fields are additive (not breaking)

---

## Migration Plan

### Phase 1: Config & Helpers (No behavior change)

1. Add limit settings to `config/settings.py`
2. Add env vars to `.env.example`
3. Add `_get_limit()` helper
4. Add `_map_error_code()` helper

### Phase 2: Limit Enforcement

1. Update `_handle_research_keyword()` to use config
2. Update `_handle_research_and_crawl()` to use config
3. Update `_handle_crawl_links()` to add limit
4. Update `_handle_fetch_channel_content()` to fix default
5. Update `_handle_fetch_profile_content()` to add limit
6. Update `_handle_dryrun_keyword()` to use config

### Phase 3: Response Format

1. Update `_publish_dryrun_result()` with new format
2. Update internal result format to include required data

### Phase 4: Testing & Deployment

1. Unit tests for new helpers
2. Integration tests for response format
3. Deploy to staging
4. Verify with Collector
5. Deploy to production

### Rollback Plan

1. Revert code changes
2. Keep config (no harm)
3. Collector fallback handles old format

---

## Open Questions

### Q1: Should we track `total_found` in search?

**Current**: Search returns `List[str]` (URLs only)
**Proposed**: Return dict with `video_urls` and `total_found`

**Decision**: Defer to Phase 2 - current implementation can calculate from result

### Q2: Apply new response format to all task types or just `dryrun_keyword`?

**Current**: Only `dryrun_keyword` publishes result to Collector
**Decision**: Start with `dryrun_keyword`, extend later if needed

### Q3: Should we add validation for `max_comments`?

**Current**: `max_comments` has no max cap
**Decision**: Out of scope - focus on video limits first
