# Tasks: Fix extract_project_id Function

## 1. TikTok Service

- [x] 1.1 Refactor `extract_project_id()` in `scrapper/tiktok/utils/helpers.py`

  - Replace `rsplit("-", 2)` logic with regex UUID extraction
  - Handle dry-run case (job_id is exactly UUID → return None)
  - Maintain backward compatibility

- [x] 1.2 Add test cases in `scrapper/tiktok/tests/unit/test_helpers.py`
  - Test `{uuid}-competitor-{name}-{index}` format
  - Test `{uuid}-competitor-{name-with-hyphen}-{index}` format
  - Verify existing tests still pass

## 2. YouTube Service

- [x] 2.1 Refactor `extract_project_id()` in `scrapper/youtube/utils/helpers.py`

  - Apply same fix as TikTok service
  - Ensure identical behavior across services

- [x] 2.2 Add test cases in `scrapper/youtube/tests/unit/test_helpers.py`
  - Mirror test cases from TikTok service
  - Verify existing tests still pass

## 3. Validation

- [x] 3.1 Run all unit tests for TikTok service

  ```bash
  cd scrapper/tiktok && pytest tests/unit/test_helpers.py -v
  ```

  ✅ 17 passed

- [x] 3.2 Run all unit tests for YouTube service

  ```bash
  cd scrapper/youtube && pytest tests/unit/test_helpers.py -v
  ```

  ✅ 17 passed

- [x] 3.3 Manual verification with production job_id samples
  - ✅ `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0` → `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80`
  - ✅ `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-0` → `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80`
  - ✅ `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0` → `fc5d5ffb-36cc-4c8d-a288-f5215af7fb80`
  - ✅ `550e8400-e29b-41d4-a716-446655440000` → `None` (dry-run)

## Dependencies

- Task 1.1 and 2.1 can be done in parallel
- Task 1.2 depends on 1.1
- Task 2.2 depends on 2.1
- Task 3.x depends on all implementation tasks

## Estimated Effort

| Task                 | Effort      |
| -------------------- | ----------- |
| 1.1 TikTok refactor  | 15 min      |
| 1.2 TikTok tests     | 15 min      |
| 2.1 YouTube refactor | 15 min      |
| 2.2 YouTube tests    | 15 min      |
| 3.x Validation       | 15 min      |
| **Total**            | **~1 hour** |
