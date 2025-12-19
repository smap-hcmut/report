# Design: Fix extract_project_id Function

## Problem Analysis

### Current Implementation

```python
# scrapper/tiktok/utils/helpers.py (line 21-66)
# scrapper/youtube/utils/helpers.py (line 15-65)

def extract_project_id(job_id: str) -> Optional[str]:
    if not job_id:
        return None

    # Check if it's a UUID (dry-run job)
    uuid_pattern = r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    if re.match(uuid_pattern, job_id.lower()):
        return None

    # PROBLEM: rsplit("-", 2) assumes only 2 segments after project_id
    parts = job_id.rsplit("-", 2)

    if len(parts) >= 3:
        try:
            int(parts[-1])
            return parts[0]  # ← Returns wrong value for complex job_ids
        except ValueError:
            pass
    # ...
```

### Failure Case

```
Input:  "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0"
                                              ↑
rsplit("-", 2) splits from right:
  parts[0] = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor"  ← WRONG
  parts[1] = "Misa"
  parts[2] = "0"

Expected: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

### Root Cause

The `rsplit("-", 2)` approach assumes job_id format is always `{project_id}-{type}-{index}` with exactly 3 segments. This breaks when:

- Competitor name contains hyphens: `{uuid}-competitor-My-Brand-0`
- Competitor name is present: `{uuid}-competitor-Misa-0`

---

## Solution Design

### Approach: UUID Prefix Extraction

Instead of parsing from the right, extract UUID from the beginning of the string using regex.

### New Implementation

```python
import re
from typing import Optional

def extract_project_id(job_id: str) -> Optional[str]:
    """
    Extract project_id (UUID) from job_id.

    Job ID formats:
    - {uuid}-brand-{index}
    - {uuid}-competitor-{index}
    - {uuid}-competitor-{name}-{index}
    - {uuid} (dry-run - returns None)

    Args:
        job_id: Job identifier string

    Returns:
        UUID project_id if found, None for dry-run or invalid formats
    """
    if not job_id:
        return None

    # UUID pattern at the start of string
    uuid_pattern = r"^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"
    match = re.match(uuid_pattern, job_id.lower())

    if not match:
        return None

    extracted_uuid = match.group(1)

    # If job_id IS exactly a UUID (dry-run), return None
    # Dry-run jobs don't have a project context
    if extracted_uuid == job_id.lower():
        return None

    return extracted_uuid
```

### Key Changes

| Aspect            | Before                   | After                   |
| ----------------- | ------------------------ | ----------------------- |
| Parsing direction | Right-to-left (`rsplit`) | Left-to-right (regex)   |
| UUID extraction   | Implicit (first segment) | Explicit (regex match)  |
| Dry-run detection | Exact UUID match         | UUID equals full job_id |
| Complexity        | O(n) string splits       | O(1) regex match        |

---

## Test Cases

### Existing Tests (Must Pass)

```python
# Brand format
assert extract_project_id("proj_abc123-brand-0") == "proj_abc123"  # ❌ Will fail - not UUID
assert extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

# Competitor format
assert extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

# Dry-run (UUID only)
assert extract_project_id("550e8400-e29b-41d4-a716-446655440000") is None

# Empty/None
assert extract_project_id("") is None
assert extract_project_id(None) is None
```

### New Tests (Production Cases)

```python
# Competitor with name
assert extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

# Competitor with hyphenated name
assert extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-My-Brand-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

# Multiple segments after UUID
assert extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-keyword-search-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

### Edge Cases

```python
# Invalid format (no UUID prefix)
assert extract_project_id("invalid-job-id") is None
assert extract_project_id("proj_abc123-brand-0") is None  # Not a UUID

# Uppercase UUID
assert extract_project_id("FC5D5FFB-36CC-4C8D-A288-F5215AF7FB80-brand-0") == "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

---

## Breaking Changes Analysis

### Potential Breaking Change

The new implementation **only accepts UUID-prefixed job_ids**. Non-UUID project_ids like `proj_abc123-brand-0` will return `None`.

### Impact Assessment

| Job ID Format                      | Before   | After    | Impact       |
| ---------------------------------- | -------- | -------- | ------------ |
| `{uuid}-brand-{index}`             | ✅ Works | ✅ Works | None         |
| `{uuid}-competitor-{index}`        | ✅ Works | ✅ Works | None         |
| `{uuid}-competitor-{name}-{index}` | ❌ Wrong | ✅ Works | **Fixed**    |
| `{uuid}` (dry-run)                 | ✅ None  | ✅ None  | None         |
| `proj_abc123-brand-0`              | ✅ Works | ❌ None  | **Breaking** |

### Mitigation

Based on production logs and `PRODUCTION_ISSUE_2025-12-15.md`, all production job_ids use UUID format. The non-UUID format (`proj_abc123`) appears only in test examples.

**Recommendation**: Update test cases to use UUID format to match production reality.

---

## Rollout Plan

1. **Phase 1**: Deploy fix to TikTok and YouTube crawlers
2. **Phase 2**: Monitor analytics pipeline for errors
3. **Phase 3**: Verify no more `InvalidTextRepresentation` errors

### Rollback Plan

If issues arise, revert to previous implementation. The change is isolated to a single function with no external dependencies.

---

## Files Changed

| File                                          | Change Type | Description                     |
| --------------------------------------------- | ----------- | ------------------------------- |
| `scrapper/tiktok/utils/helpers.py`            | Modified    | Refactor `extract_project_id()` |
| `scrapper/youtube/utils/helpers.py`           | Modified    | Refactor `extract_project_id()` |
| `scrapper/tiktok/tests/unit/test_helpers.py`  | Modified    | Add new test cases              |
| `scrapper/youtube/tests/unit/test_helpers.py` | Modified    | Add new test cases              |
