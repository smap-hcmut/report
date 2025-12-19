# Client Migration Guide: Phase-Based Progress

**Date:** 2025-12-15  
**Target Audience:** Frontend Team  
**Related:** `phase-based-progress-implementation-guide.md`

---

## Overview

WebSocket service đã được nâng cấp để hỗ trợ **phase-based progress** cho projects. Format mới cung cấp chi tiết tiến độ cho từng phase (crawl, analyze) thay vì chỉ có overall progress.

```
┌─────────────────────────────────────────────────────┐
│ NEW: Phase-Based Progress                           │
├─────────────────────────────────────────────────────┤
│ Project: proj_xyz                                   │
│ Status: PROCESSING                                  │
│ ┌─────────────────────────────────────────────────┐ │
│ │ Crawl Phase     [████████░░] 80% (80/100)       │ │
│ │ Analyze Phase   [█████░░░░░] 59% (45/78)        │ │
│ └─────────────────────────────────────────────────┘ │
│ Overall: 70.5%                                      │
└─────────────────────────────────────────────────────┘
```

---

## 1. TypeScript Types

Add the following types to your frontend codebase:

```typescript
// types/websocket.ts

// Phase progress cho từng phase (crawl/analyze)
export interface PhaseProgress {
  total: number; // Total items in this phase
  done: number; // Completed items
  errors: number; // Failed items
  progress_percent: number; // 0.0 - 100.0
}

// Payload cho phase-based messages
export interface ProjectPhasePayload {
  project_id: string;
  status: "INITIALIZING" | "PROCESSING" | "DONE" | "FAILED";
  crawl?: PhaseProgress; // Optional - may not be present at INITIALIZING
  analyze?: PhaseProgress; // Optional - may not be present during crawl phase
  overall_progress_percent: number;
}

// Phase-based message format
export interface ProjectPhaseMessage {
  type: "project_progress" | "project_completed";
  payload: ProjectPhasePayload;
}

// Legacy format (still supported for backward compatibility)
export interface LegacyProgressMessage {
  status: string;
  progress?: {
    current: number;
    total: number;
    percentage: number;
    eta: number;
    errors: string[];
  };
}

// Union type for all possible messages
export type WebSocketMessage = ProjectPhaseMessage | LegacyProgressMessage;
```

---

## 2. Message Detection Helper

```typescript
// utils/websocket.ts

/**
 * Check if message is in phase-based format
 */
export function isPhaseBasedMessage(
  data: unknown
): data is ProjectPhaseMessage {
  if (typeof data !== "object" || data === null) return false;
  const msg = data as Record<string, unknown>;
  return msg.type === "project_progress" || msg.type === "project_completed";
}

/**
 * Check if message is in legacy format
 */
export function isLegacyMessage(data: unknown): data is LegacyProgressMessage {
  if (typeof data !== "object" || data === null) return false;
  const msg = data as Record<string, unknown>;
  return "status" in msg && !("type" in msg);
}
```

---

## 3. WebSocket Message Handler

```typescript
// hooks/useProjectWebSocket.ts

import { useEffect, useCallback, useState } from "react";

interface ProjectProgress {
  projectId: string;
  status: string;
  crawlProgress?: PhaseProgress;
  analyzeProgress?: PhaseProgress;
  overallPercent: number;
  isCompleted: boolean;
  isFailed: boolean;
}

export function useProjectWebSocket(
  projectId: string,
  userId: string
): ProjectProgress | null {
  const [progress, setProgress] = useState<ProjectProgress | null>(null);

  const handleMessage = useCallback(
    (event: MessageEvent) => {
      try {
        const data = JSON.parse(event.data);

        // Handle phase-based format (NEW)
        if (isPhaseBasedMessage(data)) {
          const { payload, type } = data;

          setProgress({
            projectId: payload.project_id,
            status: payload.status,
            crawlProgress: payload.crawl,
            analyzeProgress: payload.analyze,
            overallPercent: payload.overall_progress_percent,
            isCompleted:
              type === "project_completed" && payload.status === "DONE",
            isFailed: payload.status === "FAILED",
          });
          return;
        }

        // Handle legacy format (backward compatibility)
        if (isLegacyMessage(data)) {
          setProgress({
            projectId,
            status: data.status,
            overallPercent: data.progress?.percentage ?? 0,
            isCompleted: data.status === "COMPLETED",
            isFailed: data.status === "FAILED",
          });
          return;
        }

        console.warn("Unknown message format:", data);
      } catch (error) {
        console.error("Failed to parse WebSocket message:", error);
      }
    },
    [projectId]
  );

  useEffect(() => {
    const ws = new WebSocket(`wss://your-websocket-url/ws`);

    ws.onopen = () => {
      // Subscribe to project channel
      ws.send(
        JSON.stringify({
          action: "subscribe",
          topic: `project:${projectId}:${userId}`,
        })
      );
    };

    ws.onmessage = handleMessage;

    ws.onerror = (error) => {
      console.error("WebSocket error:", error);
    };

    return () => {
      ws.close();
    };
  }, [projectId, userId, handleMessage]);

  return progress;
}
```

---

## 4. React Component Example

```tsx
// components/ProjectProgress.tsx

import React from "react";
import {
  useProjectWebSocket,
  PhaseProgress,
} from "../hooks/useProjectWebSocket";

interface PhaseProgressBarProps {
  label: string;
  phase?: PhaseProgress;
}

const PhaseProgressBar: React.FC<PhaseProgressBarProps> = ({
  label,
  phase,
}) => {
  if (!phase) return null;

  const percent = Math.round(phase.progress_percent);
  const hasErrors = phase.errors > 0;

  return (
    <div className="phase-progress">
      <div className="phase-label">
        <span>{label}</span>
        <span>
          {phase.done}/{phase.total} ({percent}%)
        </span>
        {hasErrors && <span className="errors">⚠️ {phase.errors} errors</span>}
      </div>
      <div className="progress-bar">
        <div
          className={`progress-fill ${hasErrors ? "has-errors" : ""}`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
};

interface ProjectProgressProps {
  projectId: string;
  userId: string;
}

export const ProjectProgress: React.FC<ProjectProgressProps> = ({
  projectId,
  userId,
}) => {
  const progress = useProjectWebSocket(projectId, userId);

  if (!progress) {
    return <div className="loading">Connecting...</div>;
  }

  if (progress.isFailed) {
    return <div className="error">Project processing failed</div>;
  }

  if (progress.isCompleted) {
    return <div className="success">Processing complete! ✅</div>;
  }

  return (
    <div className="project-progress">
      <h3>Project Progress</h3>
      <div className="status-badge">{progress.status}</div>

      {/* Phase-based progress bars */}
      <PhaseProgressBar label="Crawl Phase" phase={progress.crawlProgress} />
      <PhaseProgressBar
        label="Analyze Phase"
        phase={progress.analyzeProgress}
      />

      {/* Overall progress */}
      <div className="overall-progress">
        <div className="overall-label">
          Overall: {Math.round(progress.overallPercent)}%
        </div>
        <div className="progress-bar overall">
          <div
            className="progress-fill"
            style={{ width: `${progress.overallPercent}%` }}
          />
        </div>
      </div>
    </div>
  );
};
```

---

## 5. CSS Styles

```css
/* styles/project-progress.css */

.project-progress {
  padding: 1.5rem;
  border-radius: 12px;
  background: #1a1a2e;
  color: #fff;
}

.status-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
  margin-bottom: 1rem;
  background: #16213e;
}

.phase-progress {
  margin-bottom: 1rem;
}

.phase-label {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

.phase-label .errors {
  color: #ff6b6b;
}

.progress-bar {
  height: 8px;
  background: #16213e;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4facfe 0%, #00f2fe 100%);
  transition: width 0.3s ease;
}

.progress-fill.has-errors {
  background: linear-gradient(90deg, #f093fb 0%, #f5576c 100%);
}

.overall-progress {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #16213e;
}

.overall-label {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.progress-bar.overall {
  height: 12px;
}
```

---

## 6. Migration Checklist

- [ ] Add new TypeScript types to your codebase
- [ ] Add `isPhaseBasedMessage()` and `isLegacyMessage()` helpers
- [ ] Update WebSocket message handler to detect message format
- [ ] Update UI components to display phase-based progress
- [ ] Test with legacy format messages (backward compatibility)
- [ ] Test with new phase-based messages
- [ ] Remove legacy code after full migration (optional)

---

## 7. Message Examples

### Phase-Based Format (NEW)

```json
{
  "type": "project_progress",
  "payload": {
    "project_id": "proj_xyz",
    "status": "PROCESSING",
    "crawl": {
      "total": 100,
      "done": 80,
      "errors": 2,
      "progress_percent": 82.0
    },
    "analyze": {
      "total": 78,
      "done": 45,
      "errors": 1,
      "progress_percent": 59.0
    },
    "overall_progress_percent": 70.5
  }
}
```

### Completed Message

```json
{
  "type": "project_completed",
  "payload": {
    "project_id": "proj_xyz",
    "status": "DONE",
    "crawl": {
      "total": 100,
      "done": 98,
      "errors": 2,
      "progress_percent": 100.0
    },
    "analyze": {
      "total": 98,
      "done": 95,
      "errors": 3,
      "progress_percent": 100.0
    },
    "overall_progress_percent": 100.0
  }
}
```

### Status Values

| Status         | Description                             |
| -------------- | --------------------------------------- |
| `INITIALIZING` | Project is being initialized            |
| `PROCESSING`   | Crawl and/or analyze phases in progress |
| `DONE`         | All phases completed successfully       |
| `FAILED`       | Processing failed                       |

---

## 8. FAQ

### Q: Will legacy format still work?

**A:** Yes, backend supports both formats. Legacy format will continue to work for backward compatibility.

### Q: How do I know which format I'm receiving?

**A:** Check if `type` field exists. Phase-based messages have `type: "project_progress"` or `type: "project_completed"`. Legacy messages have `status` field without `type`.

### Q: What if `crawl` or `analyze` is null/undefined?

**A:** This is normal. At `INITIALIZING` status, both may be absent. During crawl phase, `analyze` may not be present yet.

### Q: How is `overall_progress_percent` calculated?

**A:** Backend calculates it as weighted average of crawl (40%) and analyze (60%) progress, but this may vary.

---

## Support

If you have questions about this migration, contact the backend team or create an issue in the repository.
