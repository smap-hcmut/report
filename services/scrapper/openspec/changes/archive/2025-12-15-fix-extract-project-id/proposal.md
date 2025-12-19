# Change: Fix extract_project_id Function for Complex Job IDs

## Why

Production analytics pipeline đang gặp lỗi **InvalidTextRepresentation** khi lưu dữ liệu vào PostgreSQL. Nguyên nhân: hàm `extract_project_id()` trong cả TikTok và YouTube crawler đang extract sai `project_id` khi job_id có format phức tạp.

### Vấn đề cụ thể

```python
# Current implementation uses rsplit("-", 2)
job_id = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0"
parts = job_id.rsplit("-", 2)
# Result: ["fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor", "Misa", "0"]
# → project_id = "uuid-competitor" (WRONG!)
```

### Expected behavior

```python
# Should extract UUID from the beginning
job_id = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0"
# → project_id = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80" (CORRECT!)
```

### Error in Production

```
psycopg2.errors.InvalidTextRepresentation: invalid input syntax for type uuid
project_id: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor"
```

## What Changes

- Refactor `extract_project_id()` function trong cả TikTok và YouTube services
- Thay đổi logic từ `rsplit("-", 2)` sang regex match UUID từ đầu string
- Thêm test cases cho các edge cases mới (competitor với tên phức tạp)
- Đảm bảo backward compatibility với các format job_id hiện có

## Impact

- **Affected specs**: crawler-services (project-id-extraction capability)
- **Affected code**:
  - `scrapper/tiktok/utils/helpers.py`
  - `scrapper/youtube/utils/helpers.py`
- **Affected tests**:
  - `scrapper/tiktok/tests/unit/test_helpers.py`
  - `scrapper/youtube/tests/unit/test_helpers.py`
- **Risk**: Low - isolated function change, no breaking changes to API
- **Effort**: ~1 hour (including tests)

## Job ID Formats Supported

| Format                 | Example                            | Expected project_id |
| ---------------------- | ---------------------------------- | ------------------- |
| Brand                  | `{uuid}-brand-{index}`             | `{uuid}`            |
| Competitor (simple)    | `{uuid}-competitor-{index}`        | `{uuid}`            |
| Competitor (with name) | `{uuid}-competitor-{name}-{index}` | `{uuid}`            |
| Dry-run (UUID only)    | `{uuid}`                           | `None`              |

## Solution Approach

Sử dụng regex để match UUID pattern từ đầu string thay vì dựa vào số lượng segments:

```python
def extract_project_id(job_id: str) -> Optional[str]:
    if not job_id:
        return None

    uuid_pattern = r"^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"
    match = re.match(uuid_pattern, job_id.lower())

    # If job_id IS exactly a UUID (dry-run), return None
    if match and match.group(1) == job_id.lower():
        return None

    return match.group(1) if match else None
```

## References

- Production Issue Report: `scrapper/document/PRODUCTION_ISSUE_2025-12-15.md`
- Analytics Event Fields: `scrapper/document/analytics-event-fields-analysis.md`
