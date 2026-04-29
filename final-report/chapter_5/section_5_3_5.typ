#import "../counters.typ": image_counter, table_counter

=== 5.3.5 WebSocket Service

WebSocket Service là service cung cấp real-time communication giữa hệ thống và clients (Web UI), cho phép push progress updates, notifications, và system status đến users mà không cần polling. Service này consume messages từ Pub/Sub và deliver đến WebSocket clients.

Vai trò của WebSocket Service trong kiến trúc tổng thể:

- Real-time Communication Hub: Cung cấp WebSocket connections cho clients.
- Message Router: Route messages từ Pub/Sub topics đến đúng WebSocket connections.
- Connection Manager: Quản lý lifecycle của WebSocket connections (connect, disconnect, heartbeat).
- Progress Delivery: Deliver progress updates từ Collector Service đến Web UI clients.

Service này đáp ứng FR-2 (Real-time progress tracking) và liên quan trực tiếp đến UC-06 (Progress updates).

==== 5.3.5.1 Component Diagram - C4 Level 3

WebSocket Service được tổ chức theo Clean Architecture với 3 layers chính:

#align(center)[
  #image("../images/component/websocket-component-diagram.png", width: 100%)
  #context (
    align(
      center,
    )[_Hình #image_counter.display(): Biểu đồ thành phần của WebSocket Service - Clean Architecture 3 layers_]
  )
  #image_counter.step()
]

==== 5.3.5.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket \ Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Handle WebSocket connections, upgrade HTTP → WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP upgrade request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Library (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection \ Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý WebSocket connections với topic mapping],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection, topic],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection registry],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Message \ Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route messages từ Pub/Sub → WebSocket connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub \ Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Subscribe to topics, receive messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Topic pattern],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub Client (Go)],
  )
]

==== 5.3.5.3 Data Flow

Luồng xử lý chính của WebSocket Service được chia thành 2 flows: Connection Establishment và Message Delivery.

===== a. Connection Establishment Flow

Luồng này được kích hoạt khi client connect WebSocket:

#align(center)[
  #image("../images/data-flow/webSocket_connection.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Connection Establishment Flow của WebSocket Service_])
  #image_counter.step()
]

===== b. Message Delivery Flow

#align(center)[
  #image("../images/data-flow/real-time.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Message Delivery Flow của WebSocket Service_])
  #image_counter.step()
]

==== 5.3.5.4 Design Patterns áp dụng

WebSocket Service áp dụng các design patterns sau:

- Observer Pattern: Pub/Sub subscribe to topics, receive messages khi có updates. Decoupling giữa publishers và subscribers, scalability với multiple WebSocket instances.

- Connection Pooling: ConnectionManager quản lý multiple WebSocket connections. In-memory registry của connections với topic mapping, efficient lookup và broadcast.

- Graceful Shutdown: Close WebSocket connections gracefully, unsubscribe từ topics, và wait for in-flight messages. Không mất messages trong quá trình shutdown.

- Health Check Pattern: Shallow và Deep health checks. Shallow check cho HTTP server và connection, Deep check cho Pub/Sub working và message delivery.

==== 5.3.5.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - WebSocket Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Latency (p95)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connection Establishment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 50ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Concurrent Connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 1,000],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 5,000 msg/min],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
  )
]

==== 5.3.5.6 Key Decisions

- Pub/Sub cho Message Routing: Sử dụng Pub/Sub thay vì direct WebSocket-to-WebSocket communication. Decoupling giữa publishers và WebSocket Service, scalability với multiple instances.

- Topic-Based Routing: Sử dụng topic pattern để route messages đến đúng connections. Mỗi user chỉ nhận messages cho projects của họ.

- Connection Registry: In-memory registry của WebSocket connections với topic mapping. Fast lookup và efficient broadcast.

- Graceful Shutdown: Close connections gracefully, unsubscribe từ topics, và wait for in-flight messages. Không mất messages trong quá trình shutdown.

==== 5.3.5.7 Dependencies

Internal Dependencies:

- ConnectionManager: Quản lý WebSocket connections.
- MessageHandler: Route messages từ Pub/Sub đến WebSocket connections.

External Dependencies:

- Distributed Cache (Redis) Pub/Sub: Message consumption.
- Project Service: Publish messages to Pub/Sub (progress callbacks).
- Web UI: WebSocket clients connect và receive messages.
