# Note - Section 5.3.6 Frontend Application

## Đã chỉnh

- Viết lại `5.3.6` theo implementation trong `web-ui` thay vì mô tả frontend như một WebSocket/realtime client đầy đủ.
- Bổ sung đúng vai trò BFF/proxy của Next.js route handlers:
  - `/api/proxy/[...path]` forward request đến backend gateway.
  - proxy rewrite `Set-Cookie` để cookie hoạt động trên frontend domain.
  - `/api/auth/session` validate token với `identity-srv` trước khi set `smap_auth_token`.
- Mô tả đúng `apiClient`, `API_CONFIG`, TanStack Query và Zustand stores.
- Mô tả Metabase access là server-side route handler flow, không phải browser gọi trực tiếp Metabase credential/session.
- Mô tả Knowledge Assistant dựa trên `knowledgeApi.chat()` và `knowledgeApi.suggestions()`.
- Mô tả report workflow theo frontend route handlers + React Query polling + report job store.
- Hạ notification từ realtime/WebSocket claim xuống presentation state dựa trên `useNotificationStore`, `NotificationBanner`, `NotificationToasts` và `NotificationBell`.
- Giữ Electron packaging nhưng mô tả rõ hơn là chạy Next.js standalone server trong Electron shell.

## Evidence đã kiểm

- `web-ui/src/lib/api/config.ts`
- `web-ui/src/lib/api/client.ts`
- `web-ui/src/app/api/proxy/[...path]/route.ts`
- `web-ui/src/app/api/auth/session/route.ts`
- `web-ui/src/lib/stores/auth.ts`
- `web-ui/src/lib/stores/notifications.ts`
- `web-ui/src/lib/metabase/client.ts`
- `web-ui/src/lib/api/knowledge.ts`
- `web-ui/src/components/CampaignAssistant.tsx`
- `web-ui/src/lib/api/reports.ts`
- `web-ui/src/lib/hooks/use-reports.ts`
- `web-ui/electron/main.ts`
- `web-ui/package.json`

## Cần lưu ý sau

- Chưa vẽ diagram cho `5.3.6`; chỉ sửa text.
- Nếu cần diagram frontend sau này, nên vẽ BFF/proxy flow hoặc assistant/report interaction flow, không vẽ WebSocket flow nếu chưa có WebSocket client thật.
- Report workflow trong frontend hiện có local Next.js report handlers dưới `/api/proxy/reports/...`; nếu backend report service thay đổi thì section này cần audit lại.
- `API_CONFIG.ENDPOINTS.notification.ws` có khai báo path, nhưng chưa tìm thấy `new WebSocket`, `EventSource` hoặc WebSocket hook trong `web-ui`; không nên claim realtime client trong report chính.
