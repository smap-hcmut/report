# Spec: WebSocket Phase-Based Progress

This spec defines the phase-based progress capability for WebSocket project notifications.

## ADDED Requirements

### Requirement: Phase Progress Data Structure

The system SHALL support a `PhaseProgress` data structure containing:
- `total`: Total items to process in this phase
- `done`: Number of completed items
- `errors`: Number of failed items
- `progress_percent`: Completion percentage (0.0 - 100.0)

#### Scenario: Crawl phase with partial completion
**Given** a project is processing
**When** the crawl phase has completed 80 of 100 items with 2 errors
**Then** the `crawl` progress shows `total: 100`, `done: 80`, `errors: 2`, `progress_percent: 82.0`

#### Scenario: Analyze phase not yet started
**Given** a project is still in crawl phase
**When** the analyze phase has not started
**Then** the `analyze` field is absent or null

---

### Requirement: Phase-Based Message Format

The system SHALL support project notification messages with `type` wrapper:
- `type`: Either `"project_progress"` or `"project_completed"`
- `payload`: Contains `project_id`, `status`, optional `crawl`, optional `analyze`, and `overall_progress_percent`

#### Scenario: Progress message during processing
**Given** a project is being processed
**When** both crawl and analyze phases are in progress
**Then** the message has `type: "project_progress"` with both phase data in payload

#### Scenario: Completed message
**Given** a project has finished processing
**When** all phases are complete
**Then** the message has `type: "project_completed"` with `status: "DONE"` in payload

---

### Requirement: Backward Compatibility

The system SHALL maintain backward compatibility with legacy message format:
- Legacy format: `{ status, progress? }` (flat structure without `type`)
- New format: `{ type, payload }` (wrapped structure)

#### Scenario: Legacy message detection
**Given** a WebSocket message is received
**When** the message has `status` field but no `type` field
**Then** the message is treated as legacy format

#### Scenario: Phase-based message detection
**Given** a WebSocket message is received
**When** the message has `type: "project_progress"` or `type: "project_completed"`
**Then** the message is treated as phase-based format

---

### Requirement: UI Phase Progress Display

The UI SHALL display separate progress bars for each phase:
- Crawl Phase: Shows `done/total (percentage%)` with optional error indicator
- Analyze Phase: Shows `done/total (percentage%)` with optional error indicator
- Overall Progress: Shows combined progress from `overall_progress_percent`

#### Scenario: Display crawl phase with errors
**Given** the crawl phase has 2 errors
**When** rendering the Crawl Phase progress bar
**Then** an error indicator with "⚠️ 2 errors" is displayed

#### Scenario: Display analyze phase when available
**Given** the analyze phase has started
**When** the `analyze` field is present in the message
**Then** the Analyze Phase progress bar is rendered with current values
