# WebSocket Client Specification

## ADDED Requirements

### Requirement: WebSocket Connection Setup

The system SHALL establish WebSocket connections using query parameters for resource identification.

#### Scenario: Project-specific connection

- **WHEN** connecting to a project WebSocket
- **THEN** the system SHALL use URL format `ws://{host}/ws?projectId={projectId}`

#### Scenario: Job-specific connection

- **WHEN** connecting to a job WebSocket
- **THEN** the system SHALL use URL format `ws://{host}/ws?jobId={jobId}`

#### Scenario: Authentication via Cookie

- **WHEN** establishing a WebSocket connection
- **THEN** the system SHALL rely on HttpOnly Cookie for authentication
- **AND** the system SHALL NOT send JWT token via query parameter

---

### Requirement: Project Notification Message Handling

The system SHALL process project notification messages with the new structure.

#### Scenario: Receive project status update

- **WHEN** a project notification message is received
- **THEN** the system SHALL parse the message as `{ status: ProjectStatus, progress?: Progress }`
- **AND** the system SHALL update UI based on the status value

#### Scenario: Handle PROCESSING status

- **WHEN** project status is `PROCESSING`
- **THEN** the system SHALL display progress bar and metrics
- **AND** the system SHALL show ETA if available
- **AND** the system SHALL display error list from `progress.errors`
- **AND** the system SHALL enable "Pause" and "Cancel" buttons

#### Scenario: Handle COMPLETED status

- **WHEN** project status is `COMPLETED`
- **THEN** the system SHALL hide progress interface
- **AND** the system SHALL show success notification
- **AND** the system SHALL display 5-second countdown before auto-redirect
- **AND** the system SHALL allow user to cancel auto-redirect

#### Scenario: Handle FAILED status

- **WHEN** project status is `FAILED`
- **THEN** the system SHALL hide progress interface
- **AND** the system SHALL show error notification (persistent)
- **AND** the system SHALL display detailed error list
- **AND** the system SHALL check for partial results (`progress.current > 0`)
- **AND** the system SHALL enable "View Partial Results" button if partial data exists

#### Scenario: Handle PAUSED status

- **WHEN** project status is `PAUSED`
- **THEN** the system SHALL display frozen progress bar
- **AND** the system SHALL show pause reason if available
- **AND** the system SHALL enable "Resume" and "Cancel" buttons
- **AND** the system SHALL stop live updates

---

### Requirement: Job Notification Message Handling

The system SHALL process job notification messages with real-time content streaming.

#### Scenario: Receive job status update

- **WHEN** a job notification message is received
- **THEN** the system SHALL parse the message as `{ platform: Platform, status: JobStatus, batch?: BatchData, progress?: Progress }`

#### Scenario: Handle job PROCESSING with batch data

- **WHEN** job status is `PROCESSING` and batch data is present
- **THEN** the system SHALL append `batch.content_list` to the content feed
- **AND** the system SHALL check for duplicate content by `content.id`
- **AND** the system SHALL display current keyword from `batch.keyword`
- **AND** the system SHALL update progress metrics

#### Scenario: Handle job COMPLETED status

- **WHEN** job status is `COMPLETED`
- **THEN** the system SHALL hide progress interface
- **AND** the system SHALL display completion summary with total content count
- **AND** the system SHALL show final statistics
- **AND** the system SHALL stop content feed updates

#### Scenario: Handle job FAILED status

- **WHEN** job status is `FAILED`
- **THEN** the system SHALL hide progress interface
- **AND** the system SHALL display error summary
- **AND** the system SHALL check for partial results
- **AND** the system SHALL enable "View Partial Results" button if content exists

#### Scenario: Handle job PAUSED status

- **WHEN** job status is `PAUSED`
- **THEN** the system SHALL freeze content feed
- **AND** the system SHALL display pause information
- **AND** the system SHALL enable "Resume" and "Cancel" buttons

---

### Requirement: Platform Support

The system SHALL support the specified social media platforms.

#### Scenario: Display platform indicator

- **WHEN** displaying job information
- **THEN** the system SHALL show platform icon for TIKTOK, YOUTUBE, or INSTAGRAM

#### Scenario: Platform enum values

- **WHEN** parsing platform from message
- **THEN** the system SHALL accept uppercase values: `TIKTOK`, `YOUTUBE`, `INSTAGRAM`
- **AND** the system SHALL NOT accept `facebook` (deprecated)

---

### Requirement: Progress Display

The system SHALL display progress information with ETA.

#### Scenario: Display progress bar

- **WHEN** progress data is available
- **THEN** the system SHALL display progress bar with `progress.percentage`
- **AND** the system SHALL show `progress.current` of `progress.total` items

#### Scenario: Display ETA

- **WHEN** `progress.eta` is available
- **THEN** the system SHALL display estimated time remaining
- **AND** the system SHALL format ETA from minutes (float64) to human-readable format

#### Scenario: Display error list

- **WHEN** `progress.errors` array is not empty
- **THEN** the system SHALL display scrollable list of error messages
- **AND** the system SHALL show error count badge

---

### Requirement: Content Feed

The system SHALL display real-time content feed for job notifications.

#### Scenario: Append new content

- **WHEN** new batch content is received
- **THEN** the system SHALL prepend new items to the feed (newest first)
- **AND** the system SHALL animate new items appearance

#### Scenario: Prevent duplicate content

- **WHEN** appending content to feed
- **THEN** the system SHALL check `content.id` against existing items
- **AND** the system SHALL skip items that already exist

#### Scenario: Display content item

- **WHEN** rendering a content item
- **THEN** the system SHALL display text, author info, and engagement metrics
- **AND** the system SHALL display media thumbnail if available
- **AND** the system SHALL provide permalink to original content

---

### Requirement: Auto-Redirect on Completion

The system SHALL implement auto-redirect with user control.

#### Scenario: Start countdown on completion

- **WHEN** project or job status changes to `COMPLETED`
- **THEN** the system SHALL display 5-second countdown
- **AND** the system SHALL show "Redirecting in X seconds..." message

#### Scenario: Cancel auto-redirect

- **WHEN** user clicks cancel button during countdown
- **THEN** the system SHALL stop the countdown
- **AND** the system SHALL remain on current page

#### Scenario: Execute redirect

- **WHEN** countdown reaches zero
- **THEN** the system SHALL navigate to results page

---

## REMOVED Requirements

### Requirement: JWT Token Authentication for WebSocket

**Reason**: Replaced by HttpOnly Cookie authentication for improved security
**Migration**: Remove token input fields and token handling code

### Requirement: Dry-Run Message Type

**Reason**: Replaced by Job Notification messages with real-time streaming
**Migration**: Use `useJobWebSocket` hook instead of handling `dryrun_result` messages

### Requirement: Facebook Platform Support

**Reason**: Facebook platform is no longer supported by backend
**Migration**: Remove Facebook-related UI elements and logic
