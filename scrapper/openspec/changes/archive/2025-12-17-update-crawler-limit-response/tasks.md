# Tasks: Update Crawler Limit Enforcement & Response Format

## Overview

Estimated effort: ~16 hours (2 days)
Priority: 🔴 High

---

## 1. Config Changes

### 1.1 YouTube Config

- [x] 1.1.1 Add limit settings to `scrapper/youtube/config/settings.py`

  - Add `default_search_limit: int = 50`
  - Add `default_limit_per_keyword: int = 50`
  - Add `default_channel_limit: int = 100`
  - Add `default_crawl_links_limit: int = 200`
  - Add `max_search_limit: int = 500`
  - Add `max_crawl_links_limit: int = 1000`
  - Add `max_channel_limit: int = 500`

- [x] 1.1.2 Update `scrapper/youtube/.env.example`

  - Add env vars for all limit settings
  - Add comments explaining each setting

- [x] 1.1.3 Update `scrapper/youtube/k8s/*.yaml` (if exists)
  - Add env vars to deployment manifests

### 1.2 TikTok Config

- [x] 1.2.1 Add limit settings to `scrapper/tiktok/config/settings.py`

  - Add `default_search_limit: int = 50`
  - Add `default_limit_per_keyword: int = 50`
  - Add `default_profile_limit: int = 100`
  - Add `default_crawl_links_limit: int = 200`
  - Add `max_search_limit: int = 500`
  - Add `max_crawl_links_limit: int = 1000`
  - Add `max_profile_limit: int = 500`

- [x] 1.2.2 Update `scrapper/tiktok/.env.example`

  - Add env vars for all limit settings
  - Add comments explaining each setting

- [x] 1.2.3 Update `scrapper/tiktok/k8s/*.yaml` (if exists)
  - Add env vars to deployment manifests

---

## 2. Task Service - Helper Methods

### 2.1 YouTube TaskService Helpers

- [x] 2.1.1 Add `_get_limit()` method to `scrapper/youtube/application/task_service.py`

  - Validate limit from payload
  - Apply default if not provided or invalid
  - Cap at max_limit with warning log
  - Return validated limit

- [x] 2.1.2 Add `_map_error_code()` method to `scrapper/youtube/application/task_service.py`
  - Map internal error types to standard codes
  - Support: SEARCH_FAILED, RATE_LIMITED, AUTH_FAILED, INVALID_KEYWORD, TIMEOUT, UNKNOWN

### 2.2 TikTok TaskService Helpers

- [x] 2.2.1 Add `_get_limit()` method to `scrapper/tiktok/application/task_service.py`

  - Same implementation as YouTube

- [x] 2.2.2 Add `_map_error_code()` method to `scrapper/tiktok/application/task_service.py`
  - Same implementation as YouTube

---

## 3. Task Service - Handler Updates (YouTube)

### 3.1 YouTube Handlers

- [x] 3.1.1 Update `_handle_research_keyword()` in YouTube

  - Replace `payload.get("limit", 50)` with `_get_limit()` call
  - Use `settings.default_search_limit` and `settings.max_search_limit`

- [x] 3.1.2 Update `_handle_research_and_crawl()` in YouTube

  - Replace `payload.get("limit_per_keyword", 50)` with `_get_limit()` call
  - Use `settings.default_limit_per_keyword` and `settings.max_search_limit`

- [x] 3.1.3 Update `_handle_crawl_links()` in YouTube - **ADD LIMIT**

  - Add limit extraction using `_get_limit()`
  - Truncate `video_urls` if exceeds limit
  - Log warning when truncating
  - Use `settings.default_crawl_links_limit` and `settings.max_crawl_links_limit`

- [x] 3.1.4 Update `_handle_fetch_channel_content()` in YouTube - **FIX DEFAULT**

  - Replace `payload.get("limit", 0)` with `_get_limit()` call
  - Use `settings.default_channel_limit` and `settings.max_channel_limit`
  - Remove unlimited (0) behavior

- [x] 3.1.5 Update `_handle_dryrun_keyword()` in YouTube
  - Replace hardcoded limit with `_get_limit()` call
  - Support both `limit_per_keyword` and `limit` fields
  - Use `settings.default_search_limit` and `settings.max_search_limit`

---

## 4. Task Service - Handler Updates (TikTok)

### 4.1 TikTok Handlers

- [x] 4.1.1 Update `_handle_research_keyword()` in TikTok

  - Replace `payload.get("limit", 50)` with `_get_limit()` call
  - Use `settings.default_search_limit` and `settings.max_search_limit`

- [x] 4.1.2 Update `_handle_research_and_crawl()` in TikTok

  - Replace `payload.get("limit_per_keyword", 50)` with `_get_limit()` call
  - Use `settings.default_limit_per_keyword` and `settings.max_search_limit`

- [x] 4.1.3 Update `_handle_crawl_links()` in TikTok - **ADD LIMIT**

  - Add limit extraction using `_get_limit()`
  - Truncate `video_urls` if exceeds limit
  - Log warning when truncating
  - Use `settings.default_crawl_links_limit` and `settings.max_crawl_links_limit`

- [x] 4.1.4 Update `_handle_fetch_profile_content()` in TikTok - **ADD LIMIT**

  - Add limit extraction using `_get_limit()`
  - Pass limit to `crawler_service.fetch_profile_videos()`
  - Use `settings.default_profile_limit` and `settings.max_profile_limit`

- [x] 4.1.5 Update `_handle_dryrun_keyword()` in TikTok
  - Replace hardcoded limit (10) with `_get_limit()` call
  - Fix inconsistent default (was 10, should be 50)
  - Support both `limit_per_keyword` and `limit` fields
  - Use `settings.default_search_limit` and `settings.max_search_limit`

---

## 5. Crawler Service Updates

### 5.1 TikTok CrawlerService

- [x] 5.1.1 Update `fetch_profile_videos()` in `scrapper/tiktok/application/crawler_service.py`
  - Add `limit: int` parameter
  - Enforce limit on video URLs before crawling
  - Log when limiting

### 5.2 YouTube CrawlerService

- [x] 5.2.1 Verify `fetch_channel_videos()` in `scrapper/youtube/application/crawler_service.py`
  - Ensure limit parameter is properly enforced
  - Fix if limit=0 means unlimited

---

## 6. Response Format Updates

### 6.1 YouTube Response

- [x] 6.1.1 Update `_handle_dryrun_keyword()` return format in YouTube

  - Add `limit` field for `limit_info`
  - Add `total_videos` field for `limit_info.total_found`
  - Ensure `total_successful`, `total_failed`, `total_skipped` are present

- [x] 6.1.2 Update `_publish_dryrun_result()` in YouTube - **NEW FORMAT**
  - Add `task_type` at root level
  - Add `limit_info` object with 4 fields
  - Add `stats` object with 4 fields
  - Add `error` object when `success: false`
  - Use `_map_error_code()` for error codes

### 6.2 TikTok Response

- [x] 6.2.1 Update `_handle_dryrun_keyword()` return format in TikTok

  - Add `limit` field for `limit_info`
  - Ensure statistics fields are present

- [x] 6.2.2 Update `_publish_dryrun_result()` in TikTok - **NEW FORMAT**
  - Add `task_type` at root level
  - Add `limit_info` object with 4 fields
  - Add `stats` object with 4 fields
  - Add `error` object when `success: false`
  - Use `_map_error_code()` for error codes

---

## 7. Testing

### 7.1 Unit Tests

- [x] 7.1.1 Write unit tests for `_get_limit()` helper

  - Test default value when not provided
  - Test capping at max_limit
  - Test invalid values (0, negative)
  - Test valid values within range
  - ✅ 26 tests passing (YouTube & TikTok)

- [x] 7.1.2 Write unit tests for `_map_error_code()` helper

  - Test all error type mappings
  - Test unknown error type → UNKNOWN
  - ✅ Tests include exception message parsing

- [x] 7.1.3 Write unit tests for new response format
  - Test success case with all fields
  - Test failure case with error object
  - Test no results case (platform_limited)
  - ✅ 7 tests passing (YouTube & TikTok)

### 7.2 Integration Tests

- [ ] 7.2.1 Test `crawl_links` with limit enforcement

  - Verify URLs are truncated when exceeding limit
  - Verify warning is logged

- [ ] 7.2.2 Test `fetch_channel_content` with new default

  - Verify default limit is applied
  - Verify limit can be overridden

- [ ] 7.2.3 Test `fetch_profile_content` with limit

  - Verify limit is enforced
  - Verify limit can be overridden

- [ ] 7.2.4 Test response format with Collector
  - Verify Collector can parse new format
  - Verify fallback works for old format

---

## 8. Documentation

- [x] 8.1 Update `scrapper/document/crawler-implementation-plan.md` with completion status
- [x] 8.2 Update `scrapper/README.MD` if needed

  - Added "Limit Enforcement" section with default limits table
  - Added "Response Format" section with JSON examples
  - Added error codes documentation
  - Updated changelog with v2.1.0

- [x] 8.3 Add release notes for breaking changes
  - Created `scrapper/document/RELEASE_NOTES_2.1.0.md`
  - Documented breaking changes and migration guide
  - Listed all configuration changes

---

## Dependencies

```
1. Config Changes (1.x)
   ↓
2. Helper Methods (2.x)
   ↓
3. Handler Updates (3.x, 4.x) - Can be parallelized
   ↓
4. Crawler Service Updates (5.x)
   ↓
5. Response Format Updates (6.x)
   ↓
6. Testing (7.x)
   ↓
7. Documentation (8.x)
```

## Parallelization

- Tasks 3.x (YouTube handlers) and 4.x (TikTok handlers) can be done in parallel
- Tasks 6.1 (YouTube response) and 6.2 (TikTok response) can be done in parallel
- Tasks 7.1 (unit tests) can start after 2.x is complete
