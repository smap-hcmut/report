# Design: WebSocket Client Migration

## Context

Backend team đã cập nhật WebSocket API với nhiều breaking changes. Frontend cần migrate để đồng bộ với đặc tả mới. Đây là cross-cutting change ảnh hưởng đến nhiều components và services.

### Stakeholders

- Frontend team: Implement migration
- Backend team: Đã deploy API mới
- QA team: Test integration

### Constraints

- Cần backward compatibility trong thời gian chuyển đổi (nếu backend chưa deploy hoàn toàn)
- Không được break existing functionality
- Real-time content streaming cần handle performance

## Goals / Non-Goals

### Goals

- Đồng bộ hoàn toàn với đặc tả `websocket_frontend_integration.md`
- Implement Job notifications thay thế Dry-Run
- Cải thiện UX với ETA display, error details, PAUSED state
- Clean code architecture với proper separation of concerns

### Non-Goals

- Không thay đổi business logic của Project/Job processing
- Không implement offline support
- Không implement WebSocket reconnection với state recovery

## Decisions

### Decision 1: URL Pattern Migration

**What**: Chuyển từ path params sang query params

```typescript
// Old
const projectUrl = `${baseUrl}/project/${projectId}`;

// New
const projectUrl = `${baseUrl}?projectId=${projectId}`;
```

**Why**: Đồng bộ với backend API mới, cho phép flexible routing

### Decision 2: Authentication via HttpOnly Cookie

**What**: Loại bỏ JWT token qua query param, sử dụng HttpOnly Cookie
**Why**:

- Security: HttpOnly Cookie không thể bị XSS attack đọc
- Simplicity: Không cần manual token handling
- Backend requirement: API mới chỉ support Cookie

**Trade-off**: Mất khả năng test với manual token input

### Decision 3: Separate Hook cho Job

**What**: Tạo `useJobWebSocket` riêng thay vì extend `useProjectWebSocket`
**Why**:

- Job có behavior khác (streaming content vs progress only)
- Separation of concerns
- Easier testing và maintenance

### Decision 4: Content Deduplication Strategy

**What**: Sử dụng `content.id` để check duplicate khi append

```typescript
const addContent = (newContent: ContentItem[]) => {
  setContentList((prev) => {
    const existingIds = new Set(prev.map((c) => c.id));
    const unique = newContent.filter((c) => !existingIds.has(c.id));
    return [...unique, ...prev]; // newest first
  });
};
```

**Why**: Tránh duplicate content khi có network issues hoặc reconnection

### Decision 5: Status Mapping Strategy

**What**: Map old status values to new ones trong transition period

```typescript
const mapLegacyStatus = (status: string): ProjectStatus => {
  switch (status) {
    case "INITIALIZING":
    case "CRAWLING":
      return "PROCESSING";
    case "DONE":
      return "COMPLETED";
    default:
      return status as ProjectStatus;
  }
};
```

**Why**: Backward compatibility nếu backend chưa deploy hoàn toàn

### Decision 6: Type Organization

**What**: Tạo single file `lib/types/websocket.ts` chứa tất cả WebSocket types
**Why**:

- Centralized type definitions
- Easy to maintain
- Clear separation từ API types

## Risks / Trade-offs

| Risk                                | Impact | Mitigation                                            |
| ----------------------------------- | ------ | ----------------------------------------------------- |
| Backend chưa deploy API mới         | High   | Feature flag để toggle old/new implementation         |
| Performance với real-time streaming | Medium | Virtualized list, throttle updates                    |
| Cookie không được gửi (CORS)        | High   | Ensure `credentials: 'include'` và proper CORS config |
| Breaking existing tests             | Medium | Update tests incrementally                            |

## Migration Plan

### Phase 1: Types & Infrastructure (Day 1)

1. Create new type definitions
2. Update environment config
3. Refactor WebSocket service

### Phase 2: Project Notifications (Day 2)

1. Refactor useProjectWebSocket hook
2. Update ProjectProcessingState component
3. Test Project flow

### Phase 3: Job Notifications (Day 3-4)

1. Create useJobWebSocket hook
2. Create Job components
3. Test Job/Dry-Run flow

### Phase 4: Cleanup (Day 5)

1. Remove deprecated code
2. Update documentation
3. Final testing

### Rollback Plan

1. Revert to previous commit
2. Re-deploy old frontend
3. Coordinate with backend for API version

## Open Questions

1. **Feature flag**: Cần implement feature flag để toggle giữa old/new implementation không?
2. **Backward compatibility period**: Backend sẽ support old API trong bao lâu?
3. **Error handling**: Cần implement retry logic cho failed batches không?
4. **Offline support**: Có cần cache content khi offline không?
