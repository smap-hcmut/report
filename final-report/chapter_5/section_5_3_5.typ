#import "../counters.typ": image_counter, table_counter

=== 5.3.5 Notification Service

Notification Service là dịch vụ chịu trách nhiệm cho lớp realtime delivery và alert dispatch của hệ thống SMAP. Dịch vụ này tiếp nhận message từ Redis Pub/Sub, định tuyến đến WebSocket clients, và trong các trường hợp phù hợp sẽ xây dựng alert payload để gửi sang các kênh bên ngoài như Discord.

Vai trò của Notification Service trong kiến trúc tổng thể:

- WebSocket Delivery Hub: Quản lý kết nối WebSocket và đẩy message đến người dùng theo scope phù hợp.
- Redis Ingress Consumer: Tiếp nhận message từ các backend publishers qua channel patterns.
- Alert Dispatch Layer: Chuyển các message loại alert thành thông điệp giàu ngữ nghĩa cho kênh bên ngoài.
- Connection Lifecycle Manager: Kiểm soát upgrade, register và vòng đời kết nối realtime.

Service này đáp ứng trực tiếp FR-11 về Realtime Notification và liên quan trực tiếp đến UC-07 về Receive Realtime Alerts.

==== 5.3.5.1 Thành phần chính

#context (align(center)[_Bảng #table_counter.display(): Thành phần chính của Notification Service_])
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

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý HTTP upgrade request và thiết lập kết nối WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Upgrade request / WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin + Gorilla WebSocket],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Request Processor],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Extract token, fallback cookie, validate request DTO và xác minh JWT trước khi upgrade],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Query params / user identity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT validation layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection Manager / Hub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Đăng ký và quản lý vòng đời kết nối, route message đến client phù hợp],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection / routed output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[In-memory connection registry],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis Subscriber],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Subscribe các channel pattern và tiếp nhận message từ backend publishers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Channel / payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis Pub/Sub],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Router],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transform payload và quyết định đẩy về WebSocket hay alert lane tương ứng],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis message / delivery output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Alert UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xây dựng payload cảnh báo và dispatch ra Discord khi cần],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Alert input / Discord message],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Alert domain logic],
  )
]

==== 5.3.5.2 Data Flow

Notification Service có hai luồng xử lý chính: connection establishment và realtime/alert delivery.

===== a. WebSocket Connection Flow

Flow này bắt đầu khi client mở kết nối `GET /ws`.

Ở flow này, service thực hiện các bước chính sau:

1. nhận request upgrade với token query hoặc auth cookie;
2. validate request DTO và xác minh JWT;
3. upgrade HTTP connection thành WebSocket;
4. đăng ký kết nối vào hub để sẵn sàng nhận message theo scope tương ứng.

===== b. Realtime and Alert Delivery Flow

Flow này bắt đầu khi backend publisher phát message vào Redis channels.

Ở flow này, service thực hiện các bước chính sau:

1. Redis subscriber nhận message từ channel pattern phù hợp;
2. message được parse, phân loại và route theo loại sự kiện;
3. nếu là realtime update, message được đẩy đến WebSocket clients phù hợp;
4. nếu là alert, service có thể dựng payload và dispatch sang Discord hoặc kênh tương ứng.

==== 5.3.5.3 Design Patterns áp dụng

Notification Service áp dụng các design patterns sau:

- Publish/Subscribe Ingress: nhận dữ liệu từ nhiều backend publishers qua Redis channel patterns.
- Hub / Connection Registry Pattern: quản lý các kết nối đang sống và route message theo scope.
- Delivery Routing Pattern: tách việc nhận message khỏi quyết định message đó đi về WebSocket hay alert lane khác.
- Alert Formatting Pattern: xây dựng message giàu ngữ nghĩa trước khi gửi ra kênh bên ngoài như Discord.

==== 5.3.5.4 Key Decisions

- Dùng Redis Pub/Sub làm notification ingress thay vì để backend services nói chuyện trực tiếp với từng WebSocket connection.
- Xác thực ở bước upgrade để giữ security boundary rõ ràng cho realtime connection.
- Tách riêng alert dispatch khỏi connection management để service hỗ trợ được nhiều loại delivery semantics trong cùng một boundary.

==== 5.3.5.5 Dependencies

Internal Dependencies:

- WebSocket handler và request processor cho connection flow.
- Connection manager / hub cho lifecycle của WebSocket connections.
- Message routing logic cho realtime updates và alerts.
- Alert usecase cho Discord dispatch.

External Dependencies:

- Redis Pub/Sub: nguồn message đầu vào từ backend publishers.
- Discord webhook/client: kênh nhận cảnh báo bên ngoài.
- Frontend clients: bên tiêu thụ WebSocket messages.
- Identity/JWT layer: nguồn xác minh token trước khi upgrade connection.
