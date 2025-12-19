# Implementation Tasks

## 1. Types & Interfaces

- [x] 1.1 Create `lib/types/websocket.ts` with new interfaces
  - [x] ProjectNotificationMessage interface
  - [x] JobNotificationMessage interface
  - [x] Progress interface
  - [x] BatchData interface
  - [x] ContentItem interface
  - [x] AuthorInfo interface
  - [x] EngagementMetrics interface
  - [x] MediaInfo interface
  - [x] Platform enum (TIKTOK, YOUTUBE, INSTAGRAM)
  - [x] ProjectStatus enum (PROCESSING, COMPLETED, FAILED, PAUSED)
  - [x] JobStatus enum (PROCESSING, COMPLETED, FAILED, PAUSED)
- [x] 1.2 Deprecate `lib/types/dryrun.ts` with JSDoc comments

## 2. Environment Configuration

- [x] 2.1 Update `.env.example` with new WebSocket URL (port 8081)
- [x] 2.2 Update default values in code

## 3. WebSocket Service Refactor

- [x] 3.1 Update `services/websocketService.ts`
  - [x] Change URL pattern from path params to query params
  - [x] Remove token-based authentication code (now uses HttpOnly Cookie)
  - [x] Update `createProjectWebSocket()` function
  - [x] Add `createJobWebSocket()` function
  - [x] Update message parsing logic (support both old and new format)
- [x] 3.2 Update heartbeat mechanism if needed

## 4. Hooks Refactor

- [x] 4.1 Refactor `hooks/useProjectWebSocket.ts`
  - [x] Update URL construction (now uses query params via createProjectWebSocket)
  - [x] Update message handling for new structure (flat format with status)
  - [x] Remove token handling (now uses HttpOnly Cookie)
  - [x] Add status-specific callbacks (onProcessing, onCompleted, onFailed, onPaused)
  - [x] Add status and progress state
- [x] 4.2 Create `hooks/useJobWebSocket.ts`
  - [x] Implement job-specific connection
  - [x] Handle batch streaming with onBatch callback
  - [x] Implement content deduplication by content.id
  - [x] Handle progress updates
  - [x] Add contentList state with maxContentItems limit
  - [x] Add currentKeyword tracking

## 5. Project Processing State Component

- [x] 5.1 Refactor `components/dashboard/ProjectProcessingState.tsx`
  - [x] Update status mapping (INITIALIZING/CRAWLING → PROCESSING, DONE → COMPLETED)
  - [x] Add PAUSED state UI
  - [x] Add ETA display component
  - [x] Change error display from count to list
  - [x] Add auto-redirect with countdown on COMPLETED
  - [x] Add partial results handling on FAILED
  - [x] Update progress field names (done → current)

## 6. Job Components (New - Replace Dry-Run)

- [x] 6.1 Create `components/job/JobProgressState.tsx`
  - [x] Implement PROCESSING state UI
  - [x] Implement COMPLETED state UI
  - [x] Implement FAILED state UI
  - [x] Implement PAUSED state UI
  - [x] Add platform indicator (TikTok/YouTube/Instagram icons)
  - [x] Add batch progress indicator
  - [x] Add keyword display
  - [x] Add ETA display
- [x] 6.2 Create `components/job/ContentFeed.tsx`
  - [x] Implement real-time content list
  - [x] Add content item component
  - [x] Implement append animation
  - [x] Add duplicate check by content.id (handled by useJobWebSocket hook)
  - [x] Add auto-scroll to top on new items
- [x] 6.3 Create `components/job/BatchIndicator.tsx`
  - [x] Show current keyword being processed
  - [x] Show batch progress
  - [x] Show status-specific styling (processing/paused/completed)

## 7. Test Page Update

- [x] 7.1 Refactor `pages/ws-test.tsx`
  - [x] Remove token input and login flow (now uses HttpOnly Cookie)
  - [x] Update message display for new structure (supports both legacy and new format)
  - [x] Add Job testing support (Project/Job connection type selector)
  - [x] Update connection URL display (shows query param format)

## 8. Cleanup & Documentation

- [x] 8.1 Remove deprecated code (marked with @deprecated JSDoc comments)
- [x] 8.2 Update inline documentation (added comprehensive JSDoc comments)
- [x] 8.3 Update README if needed (WebSocket configuration already updated)
