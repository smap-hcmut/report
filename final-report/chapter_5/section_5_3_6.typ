#import "../counters.typ": table_counter

=== 5.3.6 Frontend Application

Frontend Application là lớp giao diện và web delivery boundary của hệ thống SMAP. Thành phần này được xây dựng bằng Next.js và React, cung cấp các màn hình thao tác cho người dùng nội bộ, đồng thời giữ vai trò trung gian same-origin cho nhiều lời gọi đến backend services. Thay vì để browser gọi trực tiếp từng service, frontend gom phần lớn request qua các Next.js route handlers để xử lý proxy, cookie, Metabase access và một số workflow hướng UI.

Vai trò của Frontend Application trong kiến trúc tổng thể:

- Web UI Shell: Cung cấp layout, navigation, dashboard, campaign workspace, reports, settings và assistant panel.
- API Gateway for Browser Calls: Định tuyến request từ browser qua `/api/proxy/*` trước khi chuyển tiếp đến backend gateway.
- Auth Session Bridge: Điều phối OAuth redirect, kiểm tra session và xử lý cookie trên frontend domain.
- Analytics and BI Gateway: Gọi Metabase từ server-side route handlers để lấy dữ liệu analytics phục vụ dashboard và query builder.
- Knowledge Assistant Client: Gửi chat request và suggestion request đến `knowledge-srv`, đồng thời hiển thị câu trả lời, citation và gợi ý truy vấn.
- Report Workflow Surface: Cung cấp UI, route handlers và polling state cho report list, report detail, process tracking, post review và lazy comment loading.
- Desktop Shell: Đóng gói Next.js standalone server trong Electron để phân phối cùng một web UI dưới dạng desktop runtime.

Frontend Application hỗ trợ trực tiếp các use case có tương tác người dùng như cấu hình campaign/project, quản lý datasource, xem analytics dashboard, khai thác knowledge assistant, tạo hoặc xem report và nhận notification trong giao diện.

==== 5.3.6.1 Thành phần chính

#context (align(center)[_Bảng #table_counter.display(): Thành phần chính của Frontend Application_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.40fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thành phần*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trách nhiệm chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input / Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[App Routes and Layout Shell],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tổ chức route, layout, provider tree, navigation, dashboard workspace, report pages, settings và các vùng UI chính],
    table.cell(align: center + horizon, inset: (y: 0.8em))[URL route + scope / rendered UI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js App Router + React],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth and Session State],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Khởi tạo OAuth login, kiểm tra user hiện hành, lưu trạng thái auth và chuyển hướng khi session không hợp lệ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[OAuth/cookie/session / user state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Zustand + Next.js route handler],

    table.cell(align: center + horizon, inset: (y: 0.8em))[API Client and Proxy Routes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Chuẩn hóa endpoint, gửi request kèm cookie, unwrap response envelope và proxy browser request sang backend gateway],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / normalized response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Fetch API + Next.js route handlers],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Server State and Local Stores],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý cache dữ liệu server, auth state, notification state, selected campaign scope và long-running report jobs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Query params + UI events / cached state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TanStack Query + Zustand],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics and Metabase Gateway],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thực thi các analytics route server-side, quản lý Metabase session và chuyển kết quả query thành JSON phù hợp cho UI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics query / dashboard dataset],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js API routes + Metabase API],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Knowledge Assistant Surface],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gửi chat và suggestion request theo campaign scope, hiển thị markdown answer, citations và follow-up suggestions],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User question / assistant response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React component + Knowledge API client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Report Workflow Surface],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Điều phối list/detail/process/posts/comments của report workflow, lưu job state và polling tiến trình xử lý],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Report action / report state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js route handlers + React Query],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Electron Desktop Shell],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Khởi động Next.js standalone server, mở BrowserWindow và đóng gói web UI thành desktop application],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Standalone web bundle / desktop runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Electron + electron-builder],
  )
]

==== 5.3.6.2 Data Flow

Frontend Application có sáu luồng xử lý chính: auth and session flow, service API consumption flow, analytics and Metabase flow, knowledge assistant flow, report workflow flow và notification presentation flow.

===== a. Auth and Session Flow

Luồng này bắt đầu khi người dùng đăng nhập hoặc khi ứng dụng cần xác nhận session đang tồn tại.

1. Người dùng chọn login provider trong giao diện authentication.
2. Auth store tạo login URL qua `/api/proxy` để đi đến endpoint login của `identity-srv` và gắn redirect URL về frontend callback.
3. Proxy route chuyển tiếp request đến backend gateway và rewrite `Set-Cookie` để cookie hoạt động trên frontend domain.
4. Khi callback có token, route `/api/auth/session` xác thực token bằng endpoint `/me` của `identity-srv` trước khi set cookie `smap_auth_token` trên frontend domain.
5. `AuthProvider` gọi `fetchCurrentUser()` khi app mount để nạp user state cho các component phía dưới.
6. API client phát sự kiện `auth:unauthorized` khi gặp HTTP 401; auth store reset state và đưa người dùng về login route nếu đang ở protected area.

===== b. Service API Consumption Flow

Luồng này bao phủ các thao tác UI gọi đến `identity-srv`, `project-srv`, `ingest-srv` và `knowledge-srv`.

1. Page, component hoặc hook gọi API module tương ứng như `projectApi`, `datasourceApi`, `knowledgeApi` hoặc `reportsApi`.
2. `API_CONFIG` ánh xạ endpoint theo service prefix và chọn base URL phù hợp với môi trường thực thi.
3. Ở browser, request đi qua same-origin path `/api/proxy/*` để tránh CORS và giữ cookie flow thống nhất.
4. Catch-all proxy route loại bỏ hop-by-hop headers, chuyển tiếp cookie, forward method/body đến backend gateway và rewrite cookie ở response khi cần.
5. API client unwrap response envelope của Go services, chuẩn hóa lỗi và trả dữ liệu cho React Query hoặc component caller.
6. TanStack Query cache server state theo query key; Zustand giữ các state thuần UI như auth, notification, campaign scope và report jobs.

===== c. Analytics and Metabase Flow

Luồng này phục vụ dashboard, chart builder và các hook analytics.

1. UI gọi các route như `/api/analytics/kpis`, `/api/analytics/heap`, `/api/analytics/posts` hoặc các route `/api/metabase/*`.
2. Route handler chạy server-side và dùng Metabase client để lấy session, retry khi session hết hạn và gọi Metabase API.
3. Với native query, Metabase trả dữ liệu dạng rows/columns; frontend route chuyển đổi thành mảng object có key rõ ràng.
4. Các hook analytics nhận JSON đã chuẩn hóa và bind vào card, chart, heap space hoặc query builder.
5. Campaign/project filtering được áp dụng ở server-side query helper để các dashboard chỉ lấy dữ liệu thuộc scope đang chọn.

===== d. Knowledge Assistant Flow

Luồng này bắt đầu khi người dùng mở assistant panel trong campaign workspace.

1. Assistant đọc `activeCampaignId` từ scope provider và lấy campaign name từ campaign hook.
2. Khi campaign thay đổi, assistant gọi suggestion endpoint của `knowledge-srv`; nếu response không có suggestion thì UI dùng bộ gợi ý mặc định.
3. Khi người dùng gửi câu hỏi, assistant gọi `knowledgeApi.chat()` với `campaign_id`, `message` và `conversation_id` nếu đã có hội thoại trước đó.
4. Response được chuyển thành message blocks để hiển thị markdown, citations, suggestions và trạng thái lỗi nếu request thất bại.
5. Conversation state được lưu theo campaign trong localStorage để người dùng tiếp tục phiên hỏi đáp trong cùng frontend runtime.

===== e. Report Workflow Flow

Luồng này bao phủ report list, generate action, process tracking và post review.

1. Reports tab gọi `useReports()` theo `activeCampaignId` để lấy danh sách report.
2. Generate Report modal gửi request tạo report qua `reportsApi.generateCompetitor()` với campaign, competitor URLs, platforms, sections và giới hạn số post.
3. Khi request thành công, report job được ghi vào `useReportJobsStore`, đồng thời list query bị invalidate để UI cập nhật.
4. `useReportProcess()` polling process endpoint mỗi 3 giây khi job đang ở trạng thái non-terminal và dừng khi job hoàn tất, failed hoặc cancelled.
5. Report detail và review modal lazy-load posts/comments theo trang để tránh tải toàn bộ dữ liệu review trong một request.
6. Cancel và retry action cập nhật report job store, invalidate query liên quan và làm mới UI state.

===== f. Notification Presentation Flow

Luồng notification trong frontend tập trung ở lớp presentation state.

1. Component có thể push notification vào `useNotificationStore` với severity, title và content.
2. Store giới hạn số notification lưu trữ, đánh dấu read/unread và quản lý trạng thái dismiss cho toast hoặc banner.
3. `NotificationBanner`, `NotificationToasts` và `NotificationBell` cùng đọc từ store để render các biến thể hiển thị khác nhau.
4. Critical notification không auto-dismiss; các severity còn lại có thời gian dismiss mặc định để giảm nhiễu giao diện.

==== 5.3.6.3 Design Patterns áp dụng

Frontend Application áp dụng các design patterns sau:

- Backend-for-Frontend / Proxy Route Pattern: Browser gọi same-origin route handlers, còn frontend server chịu trách nhiệm forward đến backend gateway và xử lý cookie.
- Server State and Client State Separation: TanStack Query quản lý dữ liệu server, trong khi Zustand quản lý auth state, scope, notification và report job state.
- Route-Based UI Composition: App Router tổ chức UI theo route, layout và feature area để giữ ranh giới màn hình rõ ràng.
- Server-Side BI Gateway: Metabase credential, session và query execution được giữ ở server-side route handlers thay vì lộ trực tiếp cho browser.
- Polling-Based Job Tracking: Report process dùng polling có điều kiện cho workload dài thay vì block request path hoặc dựa vào state cục bộ thuần túy.
- Assistant Client Orchestration: Assistant panel giữ conversation state phía client, còn knowledge generation được delegated sang `knowledge-srv`.
- Desktop Shell Pattern: Electron tái sử dụng Next.js standalone output và mở web UI trong BrowserWindow.

==== 5.3.6.4 Key Decisions

- Chọn Next.js App Router để kết hợp page routing, server-side route handlers và web UI trong cùng một frontend boundary.
- Đưa browser request qua `/api/proxy/*` để giảm CORS complexity và giữ cookie/session behavior nhất quán giữa local, web và desktop runtime.
- Giữ Metabase access ở server-side route handlers nhằm không đưa Metabase credentials/session xuống browser.
- Dùng TanStack Query cho server state để có cache, invalidation, polling và pagination thống nhất giữa dashboard, reports và detail views.
- Dùng Zustand cho state tương tác cục bộ như auth persistence, selected scope, notifications và report job tracking.
- Theo dõi report process bằng polling có điều kiện, phù hợp với trạng thái long-running job mà không yêu cầu persistent push connection trong frontend.
- Đóng gói desktop bằng Electron trên cùng Next.js standalone server để tránh duy trì một UI codebase riêng.

==== 5.3.6.5 Dependencies

Internal Dependencies:

- App routes, layouts, providers và feature components trong Next.js App Router.
- API configuration, API client và catch-all proxy route `/api/proxy/[...path]`.
- Auth store, notification store, scope provider, assistant provider và report jobs store.
- TanStack Query hooks cho campaigns, projects, datasources, analytics, knowledge và reports.
- Analytics route handlers và Metabase client server-side.
- Electron main process, preload script và standalone server packaging scripts.

External Dependencies:

- Backend gateway hoặc `API_BASE_URL` chứa các service prefix `identity`, `project`, `ingest`, `knowledge` và các API route liên quan.
- `identity-srv` cho OAuth login, logout và current-user validation.
- `project-srv` cho campaign/project management và lifecycle actions.
- `ingest-srv` cho datasource, target và dry run operations.
- `knowledge-srv` cho chat, suggestions, knowledge reports và insight-facing endpoints.
- Metabase cho analytics query, metadata, saved cards và dataset access.
- Electron runtime cho desktop packaging.
