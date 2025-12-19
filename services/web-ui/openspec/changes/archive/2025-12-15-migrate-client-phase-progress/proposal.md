# Change: Migrate Client to Phase-Based Progress

## Why

Backend team đã cập nhật WebSocket message format để hỗ trợ **phase-based progress** cho projects. Format mới cung cấp chi tiết tiến độ cho từng phase (`crawl`, `analyze`) thay vì chỉ có overall progress đơn giản.

Frontend cần migrate để:
1. Nhận và xử lý message format mới với `crawl` và `analyze` phases
2. Hiển thị progress chi tiết cho từng phase trong UI
3. Duy trì backward compatibility với legacy format

## What Changes

### TypeScript Types (`lib/types/websocket.ts`)

- **ADDED**: `PhaseProgress` interface cho progress của từng phase
- **ADDED**: `ProjectPhasePayload` interface cho payload format mới
- **ADDED**: `ProjectPhaseMessage` interface cho message wrapper
- **ADDED**: Type guards `isPhaseBasedMessage()` và `isLegacyMessage()`

### WebSocket Service (`services/websocketService.ts`)

- **MODIFIED**: Message handler để detect phase-based format (`type: "project_progress"`)
- **ADDED**: Event emission `project_phase_notification` cho messages mới

### React Hook (`hooks/useProjectWebSocket.ts`)

- **MODIFIED**: Thêm state `crawlProgress` và `analyzeProgress`
- **MODIFIED**: Message handler để parse phase-based payload
- **ADDED**: Callbacks `onCrawlProgress` và `onAnalyzeProgress`

### UI Component (`components/dashboard/ProjectProcessingState.tsx`)

- **MODIFIED**: Hiển thị progress bars cho từng phase (Crawl, Analyze)
- **ADDED**: Error indicators cho mỗi phase
- **MODIFIED**: Overall progress sử dụng `overall_progress_percent`

## Impact

- Affected specs: `websocket-phase-progress` (new capability)
- Affected files:
  - `lib/types/websocket.ts`
  - `services/websocketService.ts`
  - `hooks/useProjectWebSocket.ts`
  - `components/dashboard/ProjectProcessingState.tsx`

## References

- Client migration guide: `documents/client-phase-progress-migration.md`
- Existing WebSocket migration: `openspec/changes/migrate-websocket-client/`
