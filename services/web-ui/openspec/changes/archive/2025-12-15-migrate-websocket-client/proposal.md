# Change: Migrate WebSocket Client to New Specification

## Why

Backend team đã cập nhật WebSocket API với cấu trúc message mới, authentication method mới (HttpOnly Cookie thay vì JWT token), và thêm Job notifications để thay thế hoàn toàn Dry-Run flow. Frontend cần migrate để đồng bộ với đặc tả mới trong `documents/websocket_frontend_integration.md`.

## What Changes

### Connection Setup

- **BREAKING**: Port thay đổi từ 8080 → 8081
- **BREAKING**: URL pattern thay đổi từ path params (`/ws/project/{id}`) → query params (`/ws?projectId={id}`)
- **BREAKING**: Authentication thay đổi từ JWT token qua query param → HttpOnly Cookie only
- Thêm Job-specific connection endpoint (`/ws?jobId={jobId}`)

### Project Notifications

- **BREAKING**: Message structure thay đổi từ `{ type, payload, timestamp }` → `{ status, progress? }`
- **BREAKING**: Status values thay đổi: `INITIALIZING/CRAWLING` gộp thành `PROCESSING`, `DONE` → `COMPLETED`, thêm `PAUSED`
- **BREAKING**: Progress field `errors` thay đổi từ `number` → `string[]`
- Thêm `eta` field (estimated time remaining in minutes)
- Thêm PAUSED state với UI behavior mới

### Job Notifications (Thay thế Dry-Run)

- **BREAKING**: Thay thế hoàn toàn `dryrun_result` message type
- **BREAKING**: Chuyển từ single message cuối cùng → real-time streaming theo batch
- **BREAKING**: Platform enum thay đổi: lowercase → UPPERCASE, bỏ `facebook`, thêm `INSTAGRAM`
- Thêm `batch` field với real-time content streaming
- Thêm `progress` field với ETA tracking
- Content structure simplified (bỏ comments, simplified author)

### UI Behavior

- Thêm PAUSED state UI cho cả Project và Job
- Thêm ETA display
- Thêm error list display (thay vì chỉ error count)
- Thêm auto-redirect với countdown khi COMPLETED
- Thêm partial results handling khi FAILED
- Thêm real-time content feed cho Job

## Impact

- Affected specs: `websocket` (new capability)
- Affected code:
  - `services/websocketService.ts` - Major refactor
  - `hooks/useProjectWebSocket.ts` - Refactor
  - `components/dashboard/ProjectProcessingState.tsx` - Major refactor
  - `pages/ws-test.tsx` - Refactor
  - `lib/types/dryrun.ts` - Deprecated, replaced by new types
  - `.env.example` - Update default values
- New files needed:
  - `lib/types/websocket.ts` - New types
  - `hooks/useJobWebSocket.ts` - New hook
  - `components/job/JobProgressState.tsx` - New component
  - `components/job/ContentFeed.tsx` - New component

## References

- Đặc tả mới: `documents/websocket_frontend_integration.md`
- Phân tích impact: `documents/WEBSOCKET_MIGRATION_IMPACT.md`
