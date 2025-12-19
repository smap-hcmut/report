# Implementation Tasks

## 1. TikTok Crawler Implementation

- [x] 1.1 Add `_publish_research_and_crawl_result()` method to `TaskService`
  - Build flat message format per contract
  - Calculate `platform_limited` flag
  - Map error codes using existing `_map_error_code()` pattern
- [x] 1.2 Modify `handle_task()` to call publish for `research_and_crawl`

  - Call after `_handle_research_and_crawl()` completes
  - Handle both success and error cases
  - Extract `requested_limit` from payload

- [x] 1.3 Add unit tests for `_publish_research_and_crawl_result()`
  - Test flat message format
  - Test `platform_limited` calculation
  - Test error code mapping
  - Test publisher not configured case

## 2. YouTube Crawler Implementation

- [x] 2.1 Add `_publish_research_and_crawl_result()` method to `TaskService`
  - Same implementation as TikTok (platform = "youtube")
- [x] 2.2 Modify `handle_task()` to call publish for `research_and_crawl`

  - Same pattern as TikTok

- [x] 2.3 Add unit tests for `_publish_research_and_crawl_result()`
  - Same test cases as TikTok

## 3. Integration Testing

- [x] 3.1 Add integration test: Message published to correct exchange/queue

  - Verify message goes to `results.inbound` exchange
  - Verify routing key is `tiktok.res` / `youtube.res`

- [x] 3.2 Add integration test: Message format validation
  - Verify all required fields present
  - Verify flat structure (no nested payload)

## 4. Documentation

- [x] 4.1 Update `crawler_behavior.md` to document new publish behavior
- [x] 4.2 Update `crawler-to-collector-response-contract.md` if needed

## Dependencies

- Task 2.x depends on Task 1.x (can copy implementation pattern)
- Task 3.x depends on Task 1.x and 2.x
- Task 4.x can be done in parallel

## Verification

After implementation:

1. Run unit tests: `pytest tests/unit/test_task_service*.py -v`
2. Run integration tests: `pytest tests/integration/test_result_publishing.py -v`
3. Manual test: Send `research_and_crawl` task and verify message in RabbitMQ
