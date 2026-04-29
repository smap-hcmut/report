#import "../counters.typ": image_counter, table_counter

=== 5.3.3 Project Service

Project Service là dịch vụ giữ business context của hệ thống SMAP. Dịch vụ này sở hữu campaign, project và crisis configuration, đồng thời quản lý vòng đời nghiệp vụ của project trước khi các lane runtime phía sau được kích hoạt. Đây là service trung tâm của business control plane, nơi các thao tác của người dùng được chuyển thành trạng thái nghiệp vụ rõ ràng trước khi đi vào execution flow.

Vai trò của Project Service trong kiến trúc tổng thể:

- Business Context Owner: Quản lý campaign, project và các metadata nghiệp vụ gắn với đối tượng theo dõi.
- Lifecycle Control Layer: Điều khiển activate, pause, resume, archive và unarchive theo vòng đời nghiệp vụ của project.
- Crisis Configuration Owner: Lưu trữ và quản lý các cấu hình giám sát khủng hoảng theo project.
- Internal Control Client: Gọi internal HTTP sang `ingest-srv` để kiểm tra readiness hoặc điều khiển runtime tương ứng.

Service này đáp ứng trực tiếp FR-02 về Campaign and Project Management, FR-03 về Project Lifecycle Control và FR-04 về Crisis Configuration Management. Ở mức use case, nó liên quan trực tiếp đến UC-02 về Create Campaign and Project, UC-04 về Control Project Lifecycle và UC-08 về Manage Crisis Configuration.

==== 5.3.3.1 Component Diagram - C4 Level 3

Project Service được tổ chức theo hướng tách biệt rõ delivery, usecase và persistence layer. Trọng tâm của service không nằm ở task runtime mà ở việc giữ trạng thái nghiệp vụ, điều phối lifecycle control và nối business context với các internal services liên quan.

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
    columns: (0.22fr, 0.34fr, 0.22fr, 0.22fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input / Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý HTTP routes cho project CRUD, lifecycle control và internal detail lookup],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / JSON response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin + HTTP handler],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Điều phối business logic cho project, campaign relation và metadata handling],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Create / update input, detail/list output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Lifecycle UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kiểm tra readiness, gọi internal HTTP tới ingest và cập nhật trạng thái project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project state / lifecycle command],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UseCase + internal client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Crisis Config UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý cấu hình giám sát khủng hoảng gắn với project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project ID / config payload],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go domain logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu project, campaign relation và cập nhật trạng thái nghiệp vụ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL queries / project rows],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostgreSQL repository],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Ingest Client],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao tiếp internal HTTP với `ingest-srv` cho readiness và lifecycle control],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project ID / HTTP response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal HTTP client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Lifecycle Event Publisher],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Phát hành lifecycle event sau khi transition nghiệp vụ thành công],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lifecycle payload / published event],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka producer],
  )
]

==== 5.3.3.3 Data Flow

Luồng xử lý chính của Project Service có thể nhìn qua ba flow quan trọng: project creation flow, lifecycle control flow và crisis configuration flow.

===== a. Project Creation Flow

Luồng này được kích hoạt khi người dùng tạo campaign hoặc project mới:

#align(center)[
  #image("../images/data-flow/project_create.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Creation Flow_])
  #image_counter.step()
]

Ở flow này, service thực hiện các bước chính sau:

1. nhận request tạo campaign hoặc project;
2. kiểm tra dữ liệu đầu vào và domain context tương ứng;
3. lưu project với business metadata đầy đủ;
4. trả về trạng thái nghiệp vụ ban đầu cho các bước cấu hình tiếp theo.

===== b. Project Lifecycle Control Flow

Luồng này được kích hoạt khi người dùng yêu cầu activate, pause, resume hoặc archive project:

#align(center)[
  #image("../images/data-flow/execute_project.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Lifecycle Control Flow_])
  #image_counter.step()
]

Ở flow này, `project-srv` không trực tiếp thực thi runtime mà:

1. kiểm tra trạng thái hiện tại của project;
2. gọi internal HTTP sang `ingest-srv` để kiểm tra readiness hoặc điều khiển runtime;
3. cập nhật `project.status` cục bộ nếu transition hợp lệ;
4. phát hành lifecycle event như một lane lan truyền hậu chuyển trạng thái.

===== c. Crisis Configuration Flow

Luồng này xử lý việc tạo, cập nhật hoặc xóa cấu hình giám sát khủng hoảng gắn với từng project:

- người dùng gửi cấu hình crisis liên quan đến project;
- service kiểm tra project context và tính hợp lệ của payload;
- `project-srv` lưu hoặc cập nhật dữ liệu crisis configuration trong persistence layer;
- cấu hình này sau đó trở thành đầu vào cho các lane giám sát tương ứng.

==== 5.3.3.4 Design Patterns áp dụng

Project Service áp dụng các design patterns sau:

- Clean Architecture: giữ ranh giới rõ giữa delivery, usecase và persistence layer.
- Repository Pattern: tách truy cập dữ liệu project và crisis configuration khỏi business logic.
- Control Plane Pattern: lifecycle control được giữ ở lớp nghiệp vụ thay vì bị đẩy sang execution runtime.
- Internal Service Client Pattern: dùng internal HTTP client để điều phối readiness và lifecycle giữa `project-srv` và `ingest-srv`.
- Event Publishing Pattern: phát lifecycle event sau khi business transition thành công để downstream consumers có thể phản ứng tiếp.

==== 5.3.3.5 Key Decisions

- Xem project như business context owner, không phải runtime executor.
- Giữ lifecycle control ở `project-srv`, còn runtime execution state ở `ingest-srv`.
- Dùng internal HTTP cho lifecycle control plane để giữ phản hồi đồng bộ ở các thao tác quan trọng.
- Chỉ phát lifecycle event sau khi trạng thái nghiệp vụ đã được cập nhật thành công.

==== 5.3.3.6 Dependencies

Internal Dependencies:

- Project UseCase: điều phối CRUD và metadata logic.
- Lifecycle UseCase: xử lý readiness và lifecycle transitions.
- Crisis Config UseCase: xử lý cấu hình giám sát khủng hoảng.
- Project Repository: lưu project metadata và trạng thái nghiệp vụ.

External Dependencies:

- PostgreSQL: lưu campaign, project và crisis configuration.
- Redis domain registry: hỗ trợ tra cứu domain context khi cần.
- `ingest-srv`: nhận internal HTTP call cho readiness và lifecycle control.
- Kafka producer: phát lifecycle event cho các consumer downstream.
