# Change: Update Crawler Services for Analyst Data Contract v2.0 Compliance

## Why

Analytics Service đã cập nhật Data Contract lên v2.0 với các yêu cầu mới, nhưng Crawler services (TikTok/YouTube) **chưa tuân thủ đầy đủ**:

1. **Event Message thiếu required fields** → Analytics không nhận đủ context để routing và processing

   - Thiếu `event_type: "data.collected"`
   - Thiếu `payload.task_type`, `payload.brand_name`, `payload.keyword`

2. **Batch Item Structure không đúng format** → Analytics phải handle edge cases
   - `meta.platform` đang lowercase, contract yêu cầu UPPERCASE
   - Thiếu `meta.error_code` cho error items
   - `comments[].author_name` nested trong `user` object thay vì flat

**Impact nếu không fix:**

- Analytics Service không thể filter theo brand/keyword
- Error tracking không có structured error codes
- Data processing pipeline có thể fail do format mismatch

## What Changes

### P0 - Critical (MUST DO)

1. **Add `event_type` to event payload** (TikTok + YouTube)

   - Add `"event_type": "data.collected"` to event envelope
   - Required by Analytics for event routing

2. **Add `task_type`, `brand_name`, `keyword` to event payload** (TikTok + YouTube)
   - Update `publish_data_collected()` signature
   - Pass values from crawler_service to event_publisher
   - Create `extract_brand_info()` helper function

### P1 - Required (SHOULD DO)

3. **Fix `meta.platform` to UPPERCASE** (TikTok + YouTube)

   - Update `map_to_new_format()` to use `.upper()`
   - Contract requires: `"TIKTOK"`, `"YOUTUBE"`

4. **Add `error_code` and `error_details` for error items** (TikTok + YouTube)

   - Use existing `CrawlResult.error_code` and `error_response`
   - Map to `meta.error_code` and `meta.error_details`

5. **Add flat `author_name` to comments** (TikTok + YouTube)
   - Add `"author_name": comment.commenter_name` alongside existing `user` object
   - Maintains backward compatibility while adding contract compliance

## Impact

- **Affected specs:** `crawler-services`
- **Affected code:**

  - `tiktok/internal/infrastructure/rabbitmq/event_publisher.py`
  - `youtube/internal/infrastructure/rabbitmq/event_publisher.py`
  - `tiktok/application/crawler_service.py`
  - `youtube/application/crawler_service.py`
  - `tiktok/utils/helpers.py`
  - `youtube/utils/helpers.py`

- **Dependencies:**
  - Analytics Service (consumer of data.collected events)
  - Collector Service (may use brand_name for routing)

## Estimated Effort

| Priority | Component                                 | Effort |
| -------- | ----------------------------------------- | ------ |
| P0       | Add event_type                            | 15 min |
| P0       | Add task_type/brand_name/keyword to event | 1 hour |
| P0       | Create extract_brand_info() helper        | 30 min |
| P1       | Fix platform uppercase                    | 15 min |
| P1       | Add error_code/error_details              | 30 min |
| P1       | Add flat author_name to comments          | 15 min |

**Total:** ~3 hours

## Risks

| Risk                                       | Impact | Mitigation                                    |
| ------------------------------------------ | ------ | --------------------------------------------- |
| Analytics Service không handle new fields  | LOW    | New fields are additive, backward compatible  |
| brand_name extraction fails for edge cases | MEDIUM | Default to None, Analytics handles gracefully |
| Breaking change for downstream consumers   | LOW    | All changes are additive, no field removal    |
