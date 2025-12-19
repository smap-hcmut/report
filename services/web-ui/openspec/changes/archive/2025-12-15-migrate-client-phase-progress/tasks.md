# Tasks: Migrate Client to Phase-Based Progress

## Phase 1: TypeScript Types

- [x] **1.1** Add `PhaseProgress` interface to `lib/types/websocket.ts`
  - Fields: `total`, `done`, `errors`, `progress_percent`
- [x] **1.2** Add `ProjectPhasePayload` interface
  - Fields: `project_id`, `status`, `crawl?`, `analyze?`, `overall_progress_percent`
- [x] **1.3** Add `ProjectPhaseMessage` interface with `type` wrapper
- [x] **1.4** Add type guards `isPhaseBasedMessage()` and `isLegacyMessage()`

**Validation**: TypeScript compiles without errors ✅

---

## Phase 2: WebSocket Service

- [x] **2.1** Update message handler in `websocketService.ts` to detect phase-based format
  - Check for `type: "project_progress"` or `type: "project_completed"`
- [x] **2.2** Emit `project_phase_notification` event for new format messages
- [x] **2.3** Maintain backward compatibility with legacy format

**Validation**: Console log shows correct event emission for both formats ✅

---

## Phase 3: React Hook

- [x] **3.1** Add `crawlProgress` and `analyzeProgress` state to `useProjectWebSocket.ts`
- [x] **3.2** Update message handler to parse phase-based payload
- [x] **3.3** Add callbacks `onCrawlProgress` and `onAnalyzeProgress` to options
- [x] **3.4** Update return type to include new progress fields

**Validation**: Hook correctly exposes phase progress data ✅

---

## Phase 4: UI Component

- [x] **4.1** Create `PhaseProgressBar` sub-component in `ProjectProcessingState.tsx`
  - Display label, done/total, percentage, error count
- [x] **4.2** Add Crawl Phase progress bar
- [x] **4.3** Add Analyze Phase progress bar
- [x] **4.4** Update overall progress to use `overall_progress_percent`
- [x] **4.5** Add error indicators with warning icon for each phase

**Validation**: UI displays phase-specific progress bars with correct values ✅

---

## Phase 5: Testing & Verification

## Phase 5: Testing & Verification

- [x] **5.1** Test with mock phase-based WebSocket messages via `/ws-test` page
- [x] **5.2** Test backward compatibility with legacy message format
- [x] **5.3** Verify UI correctly displays progress for all states (INITIALIZING, PROCESSING, DONE, FAILED)

**Validation**: All manual tests pass ✅

