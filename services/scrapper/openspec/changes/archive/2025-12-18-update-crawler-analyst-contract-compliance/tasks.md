# Implementation Plan

## 1. P0: Event Message - Add event_type

- [x] 1.1 Add `event_type` to TikTok event payload

  - File: `scrapper/tiktok/internal/infrastructure/rabbitmq/event_publisher.py`
  - Add `"event_type": "data.collected"` to event_payload dict
  - _Requirements: Event Message Contract Compliance_

- [x] 1.2 Add `event_type` to YouTube event payload
  - File: `scrapper/youtube/internal/infrastructure/rabbitmq/event_publisher.py`
  - Add `"event_type": "data.collected"` to event_payload dict
  - _Requirements: Event Message Contract Compliance_

## 2. P0: Event Message - Add task_type, brand_name, keyword

- [x] 2.1 Update TikTok `publish_data_collected()` signature

  - File: `scrapper/tiktok/internal/infrastructure/rabbitmq/event_publisher.py`
  - Add parameters: `task_type: str`, `brand_name: str`, `keyword: str`
  - Add fields to payload dict
  - _Requirements: Event Message Contract Compliance_

- [x] 2.2 Update YouTube `publish_data_collected()` signature

  - File: `scrapper/youtube/internal/infrastructure/rabbitmq/event_publisher.py`
  - Add parameters: `task_type: str`, `brand_name: str`, `keyword: str`
  - Add fields to payload dict
  - _Requirements: Event Message Contract Compliance_

- [x] 2.3 Create `extract_brand_info()` helper for TikTok

  - File: `scrapper/tiktok/utils/helpers.py`
  - Extract brand_name from job_id for competitor jobs
  - Return tuple: (brand_name, brand_type)
  - _Requirements: Brand Name Extraction_

- [x] 2.4 Create `extract_brand_info()` helper for YouTube

  - File: `scrapper/youtube/utils/helpers.py`
  - Same implementation as TikTok
  - _Requirements: Brand Name Extraction_

- [x] 2.5 Update TikTok `_upload_batch()` to pass new params

  - File: `scrapper/tiktok/application/crawler_service.py`
  - Update `_upload_batch()` signature to include `brand_name`
  - Pass `task_type`, `brand_name`, `keyword` to `publish_data_collected()`
  - _Requirements: Event Message Contract Compliance_

- [x] 2.6 Update YouTube `_upload_batch()` to pass new params

  - File: `scrapper/youtube/application/crawler_service.py`
  - Update `_upload_batch()` signature to include `brand_name`
  - Pass `task_type`, `brand_name`, `keyword` to `publish_data_collected()`
  - _Requirements: Event Message Contract Compliance_

- [x] 2.7 Update TikTok `add_to_batch()` and `flush_batch()` signatures

  - File: `scrapper/tiktok/application/crawler_service.py`
  - Add `brand_name` parameter to both methods
  - Propagate to `_upload_batch()`
  - _Requirements: Event Message Contract Compliance_

- [x] 2.8 Update YouTube `add_to_batch()` and `flush_batch()` signatures

  - File: `scrapper/youtube/application/crawler_service.py`
  - Add `brand_name` parameter to both methods
  - Propagate to `_upload_batch()`
  - _Requirements: Event Message Contract Compliance_

- [x] 2.9 Checkpoint - Verify P0 Event Message implementation
  - All P0 tasks completed successfully

## 3. P1: Batch Item - Fix platform uppercase

- [x] 3.1 Fix TikTok `meta.platform` to UPPERCASE

  - File: `scrapper/tiktok/utils/helpers.py`
  - Change `content.source.lower()` to `content.source.upper()`
  - Default: `"TIKTOK"` instead of `"tiktok"`
  - _Requirements: Batch Item Contract Compliance_

- [x] 3.2 Fix YouTube `meta.platform` to UPPERCASE
  - File: `scrapper/youtube/utils/helpers.py`
  - Change platform to `"YOUTUBE"` (uppercase)
  - _Requirements: Batch Item Contract Compliance_

## 4. P1: Batch Item - Add error_code and error_details

- [x] 4.1 Add error fields to TikTok `map_to_new_format()`

  - File: `scrapper/tiktok/utils/helpers.py`
  - Add `"error_code": result.error_code if not result.success else None`
  - Add `"error_details": result.error_response if not result.success else None`
  - Rename `"fetch_error"` to `"error_message"` for consistency
  - _Requirements: Batch Item Contract Compliance_

- [x] 4.2 Add error fields to YouTube `map_to_new_format()`
  - File: `scrapper/youtube/utils/helpers.py`
  - Same changes as TikTok
  - _Requirements: Batch Item Contract Compliance_

## 5. P1: Batch Item - Add flat author_name to comments

- [x] 5.1 Add `author_name` to TikTok comments

  - File: `scrapper/tiktok/utils/helpers.py`
  - Add `"author_name": comment.commenter_name` to comment_obj
  - Keep existing `user` object for backward compatibility
  - _Requirements: Batch Item Contract Compliance_

- [x] 5.2 Add `author_name` to YouTube comments

  - File: `scrapper/youtube/utils/helpers.py`
  - Same changes as TikTok
  - _Requirements: Batch Item Contract Compliance_

- [x] 5.3 Checkpoint - Verify P1 Batch Item implementation
  - All P1 tasks completed successfully

## 6. Testing & Validation

- [x] 6.1 Update unit tests for event message structure

  - Files: `tiktok/tests/integration/test_batch_upload.py`, `youtube/tests/integration/test_batch_upload.py`
  - Add assertions for `event_type`, `task_type`, `brand_name`, `keyword`
  - Added `test_event_contains_contract_v2_fields()` test
  - _Requirements: Event Message Contract Compliance_

- [x] 6.2 Update unit tests for batch item structure

  - Files: `tiktok/tests/unit/test_helpers.py`, `youtube/tests/unit/test_helpers.py`
  - Add assertions for UPPERCASE platform (`test_platform_is_uppercase`)
  - Add assertions for error_code, error_details (`test_error_fields_on_success`, `test_error_fields_on_failure`)
  - Add assertions for flat author_name in comments (`test_comments_have_flat_author_name`)
  - _Requirements: Batch Item Contract Compliance_

- [x] 6.3 Add unit tests for `extract_brand_info()`

  - Files: `tiktok/tests/unit/test_helpers.py`, `youtube/tests/unit/test_helpers.py`
  - Test brand job_id format: `{uuid}-brand-{index}`
  - Test competitor job_id format: `{uuid}-competitor-{name}-{index}`
  - Test edge cases: empty string, invalid format
  - Added `TestExtractBrandInfo` test class
  - _Requirements: Brand Name Extraction_

- [x] 6.4 Final Checkpoint - Verify all implementations
  - Run full test suite: All tests pass (TikTok: 26 unit + 9 integration, YouTube: 25 unit + 9 integration)
  - Verify contract compliance with Analytics Service expectations: ✅ Complete

---

## Summary

| Phase   | Tasks   | Files Changed | Effort   |
| ------- | ------- | ------------- | -------- |
| P0      | 1.1-2.9 | 6 files       | ~2 hours |
| P1      | 3.1-5.3 | 2 files       | ~45 min  |
| Testing | 6.1-6.4 | 4 files       | ~30 min  |

**Total Estimated Effort:** ~3 hours
