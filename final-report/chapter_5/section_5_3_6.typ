#import "../counters.typ": image_counter, table_counter

=== 5.3.6 Frontend Application

Frontend Application là lớp giao diện người dùng của hệ thống SMAP, đồng thời cũng là điểm tích hợp giữa người dùng cuối với các backend services, các luồng realtime và một số lớp khai thác dữ liệu hỗ trợ như BI querying. Trong current implementation, frontend không chỉ được tổ chức như một web application dựa trên Next.js và React, mà còn có khả năng đóng gói desktop thông qua Electron.

Vai trò của Frontend Application trong kiến trúc tổng thể:

- User Interface Layer: Cung cấp các màn hình và luồng thao tác cho người dùng nội bộ.
- API Client Layer: Gọi các REST APIs hoặc proxy routes tới backend services.
- Realtime Client Layer: Thiết lập kết nối WebSocket và hiển thị thông báo/cập nhật theo thời gian thực.
- BI Integration Layer: Tích hợp với Metabase thông qua các API route trung gian.
- Desktop Delivery Layer: Hỗ trợ đóng gói desktop qua Electron khi cần triển khai ngoài môi trường web browser thuần túy.

Frontend Application liên quan trực tiếp đến nhóm use case nơi người dùng nội bộ cấu hình project, theo dõi kết quả, tìm kiếm, hỏi đáp và nhận thông báo. Ở mức yêu cầu, nó hỗ trợ trực tiếp các capability liên quan đến khai thác kết quả, realtime delivery và trải nghiệm sử dụng hệ thống.

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

    table.cell(align: center + horizon, inset: (y: 0.8em))[App Routes / Pages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tổ chức các màn hình và route nghiệp vụ cho authentication, campaigns, reports, settings và các vùng thao tác chính của hệ thống],
    table.cell(align: center + horizon, inset: (y: 0.8em))[URL route / rendered page],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js + React],

    table.cell(align: center + horizon, inset: (y: 0.8em))[API Proxy / Route Layer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Đóng vai trò lớp trung gian cho một số API calls, analytics endpoints và proxy routes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Frontend request / backend response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js route handlers],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Hook / Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý kết nối WebSocket, nhận message realtime và cập nhật UI tương ứng],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Realtime event / UI update],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React hook + client service],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Metabase Integration Layer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gửi truy vấn, lấy metadata hoặc dataset từ Metabase thông qua các route trung gian],
    table.cell(align: center + horizon, inset: (y: 0.8em))[BI query / dataset response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Metabase client + API routes],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Desktop Packaging Layer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Đóng gói frontend hiện tại thành desktop runtime khi cần triển khai ngoài browser],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web assets / desktop bundle],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Electron],
  )
]

==== 5.3.6.2 Data Flow

Frontend Application có ba luồng chính đáng chú ý: route rendering & API consumption, realtime update flow và BI integration flow.

===== a. Route Rendering and API Consumption Flow

Flow này bắt đầu khi người dùng truy cập vào một route nghiệp vụ của hệ thống.

1. Frontend resolve route tương ứng trong ứng dụng Next.js.
2. Các component hoặc page tương ứng được render.
3. Dữ liệu cần thiết được truy xuất từ backend services qua API calls hoặc proxy routes.
4. Kết quả được bind vào component state và hiển thị cho người dùng.

===== b. Realtime Update Flow

Flow này được kích hoạt khi người dùng cần nhận thông báo hoặc trạng thái cập nhật theo thời gian thực.

1. Frontend mở kết nối WebSocket thông qua hook hoặc client service tương ứng.
2. Notification layer đẩy message theo scope phù hợp về frontend.
3. Hook/service parse message và cập nhật state của UI.
4. Người dùng nhìn thấy thay đổi trạng thái hoặc thông báo mà không cần polling thủ công.

===== c. BI Integration Flow

Flow này được kích hoạt khi frontend cần truy cập metadata, query result hoặc dataset từ Metabase.

1. Frontend gọi các route API nội bộ dành cho Metabase integration.
2. Các route này thực hiện truy vấn hoặc lấy metadata từ Metabase service.
3. Kết quả được trả về frontend dưới dạng dữ liệu phù hợp để hiển thị hoặc tích hợp vào trải nghiệm sử dụng.

==== 5.3.6.3 Design Patterns áp dụng

Frontend Application áp dụng các design patterns sau:

- Component-Based Architecture: UI được chia thành các component hoặc page có thể tái sử dụng.
- Route-Based Organization: tổ chức giao diện theo route và feature area để giữ ranh giới rõ giữa các vùng chức năng.
- Hook / Service Separation: logic như WebSocket, API consumption hoặc BI integration được tách khỏi phần hiển thị UI.
- Proxy Layer Pattern: sử dụng route handlers làm lớp trung gian cho một số backend hoặc BI queries.
- Desktop Shell Pattern: tái sử dụng frontend web stack trong desktop runtime qua Electron.

==== 5.3.6.4 Key Decisions

- Chọn Next.js và React để giữ sự linh hoạt giữa route organization, rendering strategy và component-based UI.
- Giữ WebSocket logic ở hook/service layer thay vì nhúng trực tiếp vào từng page.
- Tách Metabase integration thành một lớp riêng để không làm rối các luồng nghiệp vụ chính.
- Hỗ trợ Electron packaging để mở rộng hình thức triển khai mà không cần viết lại frontend bằng một stack khác.

==== 5.3.6.5 Dependencies

Internal Dependencies:

- App routes và page components.
- API route handlers cho proxy và Metabase integration.
- WebSocket hook/service cho realtime updates.
- UI component tree và state management tương ứng.

External Dependencies:

- Backend services của SMAP qua REST APIs.
- Notification Service qua WebSocket.
- Metabase như một lớp BI/query backend phụ trợ.
- Electron runtime cho desktop packaging.
