# useProjectWebSocket Hook

## Mô tả

Hook này quản lý kết nối WebSocket dựa trên URL parameter `?project={id}`.

**Behavior:**
- ✅ **Kết nối** khi URL có `?project={project_id}` → WebSocket kết nối đến `/projects/{project_id}`
- ❌ **Ngắt kết nối** ngay lập tức khi:
  - Không có param `?project=` trong URL
  - Chuyển sang trang khác
  - Component unmount

## Cách sử dụng

### 1. Import hook

```typescript
import { useProjectWebSocket } from '@/hooks/useProjectWebSocket'
```

### 2. Sử dụng trong component

```typescript
function MyComponent() {
  const { isConnected, error, projectId } = useProjectWebSocket({
    onMessage: (message) => {
      console.log('Received message:', message)
      // Handle WebSocket message
    },
    onConnect: () => {
      console.log('Connected to project WebSocket')
    },
    onDisconnect: () => {
      console.log('Disconnected from project WebSocket')
    },
    onError: (error) => {
      console.error('WebSocket error:', error)
    }
  })

  return (
    <div>
      {isConnected && <p>Connected to project: {projectId}</p>}
      {error && <p>Error: {error}</p>}
    </div>
  )
}
```

## API

### Parameters

```typescript
interface UseProjectWebSocketOptions {
  onMessage?: (data: any) => void    // Callback khi nhận message
  onConnect?: () => void              // Callback khi connect thành công
  onDisconnect?: () => void           // Callback khi disconnect
  onError?: (error: any) => void      // Callback khi có lỗi
}
```

### Return Values

```typescript
{
  isConnected: boolean      // Trạng thái kết nối
  error: string | null      // Lỗi (nếu có)
  projectId: string | null  // Project ID hiện tại
  disconnect: () => void    // Function để ngắt kết nối thủ công
}
```

## Ví dụ

### Ví dụ 1: Basic Usage trong DashboardContext

```typescript
export function DashboardProvider({ children }) {
  const [state, dispatch] = useReducer(dashboardReducer, initialState)

  const { isConnected, error } = useProjectWebSocket({
    onMessage: (message) => {
      // Handle project-specific WebSocket messages
      if (message.type === 'project_update') {
        dispatch({ type: 'UPDATE_PROJECT', payload: message.data })
      }
    }
  })

  return (
    <DashboardContext.Provider value={...}>
      {children}
    </DashboardContext.Provider>
  )
}
```

### Ví dụ 2: Với manual disconnect

```typescript
function ProjectDetail() {
  const { isConnected, disconnect } = useProjectWebSocket({
    onMessage: (message) => {
      console.log('Message:', message)
    }
  })

  const handleLeave = () => {
    disconnect() // Ngắt kết nối thủ công
    router.push('/projects')
  }

  return (
    <div>
      <button onClick={handleLeave}>Leave Project</button>
    </div>
  )
}
```

## Flow Diagram

```
┌─────────────────────────────────────────────────┐
│  User navigates to /dashboard?project=123       │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  Hook detects ?project=123 in URL               │
│  → createProjectWebSocket(123)                  │
│  → Connect to ws://.../projects/123             │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  Connection established                         │
│  → onConnect() called                           │
│  → isConnected = true                           │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  Receiving messages                             │
│  → onMessage(data) called for each message      │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  User navigates away (removes ?project param)   │
│  → disconnect() called automatically            │
│  → WebSocket closed                             │
│  → onDisconnect() called                        │
│  → isConnected = false                          │
└─────────────────────────────────────────────────┘
```

## Notes

- Hook tự động cleanup khi component unmount
- Chỉ duy trì 1 connection tại một thời điểm
- Khi chuyển project (từ `?project=123` → `?project=456`), hook tự động:
  1. Ngắt kết nối từ project 123
  2. Kết nối mới đến project 456
- WebSocket URL được tạo từ `NEXT_PUBLIC_WS_URL` env variable
- **Reconnection Prevention**: Khi disconnect thủ công (URL không còn `?project=`), WebSocket sẽ:
  1. Set `shouldReconnect = false`
  2. Clear tất cả reconnect timeouts
  3. Reset reconnect attempts về 0
  4. **KHÔNG BAO GIỜ** cố reconnect lại

## Environment Variables

```env
NEXT_PUBLIC_WS_URL=wss://smap-api.tantai.dev/ws
```

WebSocket sẽ kết nối đến: `wss://smap-api.tantai.dev/ws/projects/{project_id}`
