#import "../counters.typ": image_counter, table_counter

=== 5.3.3 Project Service

Project Service là service quản lý vòng đời của các dự án phân tích thương hiệu và đối thủ cạnh tranh trong hệ thống SMAP. Service này đóng vai trò Aggregator trong kiến trúc tổng thể, quản lý project metadata, orchestrate execution flow, và publish events để trigger các services khác.

Vai trò của Project Service trong kiến trúc tổng thể:

- Project Management: CRUD operations cho projects, competitors, và keywords.
- Execution Orchestrator: Khởi tạo và điều phối quá trình crawl dữ liệu cho UC-03.
- State Coordinator: Quản lý project state trong distributed cache (initialization, không update trực tiếp).
- Event Publisher: Publish project events để trigger Collector Service.
- Webhook Receiver: Nhận progress callbacks từ Collector Service và publish đến Pub/Sub.

Service này đáp ứng FR-1 về Cấu hình Project và FR-2 về Thực thi và Giám sát Project, liên quan trực tiếp đến UC-01 về Cấu hình Project và UC-03 về Execution.

==== 5.3.3.1 Component Diagram - C4 Level 3

Project Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/project-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ thành phần của Project Service_])
  #image_counter.step()
]

==== 5.3.3.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Project Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectHandler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request handlers cho project CRUD và execution],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP requests],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Framework (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectUseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Business logic cho project management và execution orchestration],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CreateInput, ExecuteInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectOutput, status],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[StateUseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý project state trong distributed cache],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, state updates],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectState],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Webhook \ UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transform progress callbacks → Pub/Sub messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress Callback],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub publish],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pub/Sub Client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ \ Producer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Publish project events đến message queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectCreated Event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message published],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AMQP Client (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database data access layer cho projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[State \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache data access layer cho project state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache commands],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cache Client (Go)],
  )
]

==== 5.3.3.3 Data Flow

Luồng xử lý chính của Project Service được chia thành 3 flows: Project Creation, Project Execution, và Progress Callback Handling.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới theo UC-01:

#align(center)[
  #image("../images/data-flow/project_create.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Creation Flow - UC-01_])
  #image_counter.step()
]

===== b. Project Execution Flow

Luồng này được kích hoạt khi user execute project theo UC-03:

#align(center)[
  #image("../images/data-flow/execute_project.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Execution Flow - UC-03_])
  #image_counter.step()
]

===== c. Progress Callback Flow

Luồng này xử lý progress callbacks từ Collector Service:

#align(center)[
  #image("../images/data-flow/webhook_callback.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Progress Callback Flow_])
  #image_counter.step()
]

==== 5.3.3.4 Design Patterns áp dụng

Project Service áp dụng các design patterns sau:

- Clean Architecture: 4 layers Delivery → UseCase → Domain → Infrastructure với dependency inversion. Testability cao, maintainability tốt.

- Repository Pattern: ProjectRepository cho database, StateRepository cho cache. Abstract data access qua interfaces, business logic không phụ thuộc vào storage cụ thể.

- Event-Driven Architecture: Producer publish project events. Decoupling giữa services, async processing, và resilience.

- Distributed State Management: StateUseCase quản lý project state trong distributed cache. Single Source of Truth cho project progress, real-time updates qua Pub/Sub.

- Explicit Execution Pattern: Project được tạo với status="draft", chỉ execute khi user explicitly call Execute(). User có thể review và edit configuration trước khi execute.

==== 5.3.3.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Project Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Creation Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Execution Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress Callback Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-P1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Concurrent Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[≥ 50 projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
  )
]

==== 5.3.3.6 Key Decisions

- Draft Status Pattern: Project được tạo với status="draft", không kích hoạt bất kỳ processing nào. Cho phép user review và edit configuration trước khi execute.

- Explicit Execution: Tách biệt "configuration" và "execution" thành 2 operations riêng biệt. User có thể tạo nhiều projects và execute sau.

- Duplicate Execution Prevention: Check cache state trước khi execute, return error nếu project đang executing. Tránh duplicate processing và inconsistent state.

- Rollback Logic: Nếu message queue publish fails sau khi đã update database và init cache, rollback cả hai. Đảm bảo consistency.

==== 5.3.3.7 Dependencies

Internal Dependencies:

- StateUseCase: Quản lý project state trong distributed cache.
- RabbitMQProducer: Publish project events.
- SamplingUseCase: Dry-run functionality.

External Dependencies:

- Relational Database (PostgreSQL): Project metadata persistence.
- Distributed Cache (Redis): State management và Pub/Sub.
- Message Queue (RabbitMQ): Event publishing.
- Identity Service: User authentication (JWT validation).
