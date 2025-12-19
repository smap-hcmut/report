# Spec: Project ID Extraction

## Overview

This specification defines the behavior of the `extract_project_id()` function used by TikTok and YouTube crawler services to extract project identifiers from job IDs.

---

## MODIFIED Requirements

### Requirement 1: UUID Extraction from Job ID

The system SHALL extract a valid UUID project_id from the beginning of a job_id string.

#### Scenario: Standard brand job ID

**Given** a job_id in format `{uuid}-brand-{index}`
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID portion

```python
# Example
extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-brand-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

#### Scenario: Simple competitor job ID

**Given** a job_id in format `{uuid}-competitor-{index}`
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID portion

```python
# Example
extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

#### Scenario: Competitor job ID with name

**Given** a job_id in format `{uuid}-competitor-{name}-{index}`
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID portion regardless of the competitor name

```python
# Example
extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-Misa-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

#### Scenario: Competitor job ID with hyphenated name

**Given** a job_id in format `{uuid}-competitor-{name-with-hyphens}-{index}`
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID portion regardless of hyphens in the name

```python
# Example
extract_project_id("fc5d5ffb-36cc-4c8d-a288-f5215af7fb80-competitor-My-Brand-Name-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

---

### Requirement 2: Dry-run Job ID Handling

The system SHALL return `None` for dry-run job IDs that consist only of a UUID.

#### Scenario: Dry-run job ID (UUID only)

**Given** a job_id that is exactly a UUID with no suffix
**When** `extract_project_id()` is called
**Then** the function SHALL return `None`

```python
# Example
extract_project_id("550e8400-e29b-41d4-a716-446655440000")
# Returns: None
```

#### Scenario: Uppercase UUID dry-run

**Given** a job_id that is an uppercase UUID
**When** `extract_project_id()` is called
**Then** the function SHALL return `None` (case-insensitive)

```python
# Example
extract_project_id("550E8400-E29B-41D4-A716-446655440000")
# Returns: None
```

---

### Requirement 3: Invalid Input Handling

The system SHALL return `None` for invalid or empty inputs.

#### Scenario: Empty string

**Given** an empty string job_id
**When** `extract_project_id()` is called
**Then** the function SHALL return `None`

```python
# Example
extract_project_id("")
# Returns: None
```

#### Scenario: None input

**Given** a `None` job_id
**When** `extract_project_id()` is called
**Then** the function SHALL return `None`

```python
# Example
extract_project_id(None)
# Returns: None
```

#### Scenario: Non-UUID prefix

**Given** a job_id that does not start with a valid UUID
**When** `extract_project_id()` is called
**Then** the function SHALL return `None`

```python
# Example
extract_project_id("invalid-job-id")
# Returns: None

extract_project_id("proj_abc123-brand-0")
# Returns: None (not a UUID)
```

---

### Requirement 4: Case Insensitivity

The system SHALL handle UUIDs in a case-insensitive manner and return lowercase.

#### Scenario: Uppercase UUID in job ID

**Given** a job_id with uppercase UUID
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID in lowercase

```python
# Example
extract_project_id("FC5D5FFB-36CC-4C8D-A288-F5215AF7FB80-brand-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

#### Scenario: Mixed case UUID

**Given** a job_id with mixed case UUID
**When** `extract_project_id()` is called
**Then** the function SHALL return the UUID in lowercase

```python
# Example
extract_project_id("Fc5d5Ffb-36Cc-4c8D-A288-f5215aF7Fb80-brand-0")
# Returns: "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
```

---

## Related Capabilities

- **crawler-services**: Main crawler service specification
- **analytics-integration**: Analytics service event publishing

## Cross-References

- Production Issue: `scrapper/document/PRODUCTION_ISSUE_2025-12-15.md`
- Analytics Event Fields: `scrapper/document/analytics-event-fields-analysis.md`
