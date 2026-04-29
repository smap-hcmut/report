#import "../counters.typ": image_counter, table_counter

=== 5.3.1 Identity Service

Identity Service là dịch vụ chịu trách nhiệm cho security boundary của toàn hệ thống SMAP. Dịch vụ này tập trung vào xác thực người dùng, quản lý session, phát hành token, hỗ trợ internal token validation cho các service khác, và trong current implementation còn duy trì một audit processing lane chạy nền để xử lý audit events bất đồng bộ.

Vai trò của Identity Service trong kiến trúc tổng thể:

- Authentication Gateway: Xử lý đăng nhập và callback với external identity provider.
- Session Manager: Tạo và duy trì phiên truy cập sau khi xác thực thành công.
- Token Authority: Phát hành và xác thực JWT cho protected routes và internal validation.
- Security Boundary: Tách riêng xác thực khỏi business logic của project, ingest, analytics và knowledge.
- Audit Processing Lane: Tiêu thụ audit events và flush dữ liệu truy vết vào persistence layer theo batch.

Service này đáp ứng trực tiếp FR-01 về User Authentication và liên quan trực tiếp đến UC-01 về Authenticate User. Ngoài capability auth-facing, current source còn có một consumer lane phục vụ audit logging và truy vết vận hành.

==== 5.3.1.1 Component Diagram - C4 Level 3

Identity Service được tổ chức theo hướng tách biệt delivery, usecase và infrastructure để giữ rõ ranh giới giữa protocol handling, auth logic và persistence.

#align(center)[
  #image("../images/component/identity-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ thành phần của Identity Service_])
  #image_counter.step()
]

==== 5.3.1.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Identity Service_])
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

    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth / Internal Handlers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý login, callback, logout, `/me` và các internal validation routes ở lớp HTTP delivery],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / JSON response hoặc redirect],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin + HTTP handler],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Authentication UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Điều phối OAuth2 flow, xử lý callback, hoàn tất phiên truy cập],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Login input / session output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Phát hành và xác thực token dùng cho protected routes và internal validation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Claims / signed token],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Session Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tạo, duy trì và thu hồi session hoặc blacklist state khi cần],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Session key / session state],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis-backed session layer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Audit Consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tiêu thụ audit events từ Kafka, gom batch theo size hoặc timeout và flush vào persistence layer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Audit event / persisted audit rows],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka consumer runtime],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User / Audit Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Lưu thông tin người dùng, audit log và dữ liệu identity liên quan],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Persistence commands / query results],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostgreSQL repository],
  )
]

==== 5.3.1.3 Data Flow

Luồng xử lý chính của Identity Service có thể nhìn qua ba flow quan trọng: OAuth2 login flow, protected-route validation flow và audit event processing flow.

===== a. OAuth2 Login Flow

Luồng này mô tả quá trình người dùng bắt đầu đăng nhập, được chuyển sang identity provider và quay lại hệ thống với phiên truy cập hợp lệ:

#align(center)[
  #image("../images/data-flow/user_login.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng OAuth2 login trong Identity Service_])
  #image_counter.step()
]

===== b. Protected Route Validation Flow

Luồng này mô tả cách token hoặc cookie được kiểm tra trước khi các route bảo vệ cho phép truy cập:

#align(center)[
  #image("../images/data-flow/auth_middleware.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng xác thực protected routes trong Identity Service_])
  #image_counter.step()
]

===== c. Audit Event Processing Flow

Luồng này phản ánh consumer lane chạy nền của service:

1. consumer runtime nhận audit events từ Kafka topic tương ứng;
2. các event được parse và gom thành batch theo size hoặc timeout;
3. batch được flush vào PostgreSQL thông qua audit repository;
4. dữ liệu truy vết sau đó phục vụ audit trail và phân tích vận hành.

==== 5.3.1.4 Design Patterns áp dụng

Identity Service áp dụng các design patterns sau:

- OAuth2 Delegation Pattern: Tận dụng external identity provider cho bước xác thực ban đầu, giảm việc tự quản lý mật khẩu nội bộ.
- Token-Based Authentication: Dùng JWT làm lớp đại diện cho phiên truy cập sau đăng nhập.
- Session Management Pattern: Dùng session layer để kiểm soát vòng đời truy cập thay vì chỉ phụ thuộc hoàn toàn vào token stateless.
- Background Consumer Pattern: Audit processing được tách khỏi request path và flush theo batch ở runtime nền.
- Repository Pattern: Tách truy cập dữ liệu người dùng và audit log khỏi business logic xác thực.
- Clean Architecture: Giữ ranh giới rõ giữa handler, usecase và infrastructure để tăng tính bảo trì và khả năng kiểm thử.

==== 5.3.1.5 Key Decisions

- Kết hợp OAuth2 với JWT và HttpOnly cookie để vừa tận dụng identity provider bên ngoài, vừa giữ được quyền kiểm soát phiên truy cập ở lớp ứng dụng nội bộ.
- Giữ session management ở usecase/infrastructure layer thay vì nhúng trực tiếp trong handler.
- Tách internal token validation thành một capability riêng để các service khác dùng chung security boundary của hệ thống.
- Giữ audit consumer trong cùng service boundary để auth và audit trail vẫn được quản lý gần nhau, nhưng tách execution của audit khỏi request path chính.

==== 5.3.1.6 Dependencies

Internal Dependencies:

- Authentication UseCase: Điều phối login flow, callback và session completion.
- JWT Manager: Ký và xác thực token.
- Session Manager: Tạo và duy trì session hoặc blacklist state.
- Audit Consumer: tiêu thụ và flush audit events theo batch.
- User / Audit Repository: Lưu user data và audit trail.

External Dependencies:

- OAuth2 Provider: Nguồn xác thực ban đầu của người dùng.
- Redis: Quản lý session/blacklist runtime.
- PostgreSQL: Lưu trữ dữ liệu identity và audit log.
- Kafka: audit event ingress cho consumer lane.
- Backend Services khác: Tiêu thụ internal token validation khi cần.
