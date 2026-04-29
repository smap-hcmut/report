#import "../counters.typ": image_counter, table_counter

=== 5.3.4 Identity Service

Identity Service là service quản lý authentication và authorization trong hệ thống SMAP, cung cấp JWT-based authentication, role-based access control, và user management. Service này đóng vai trò Utility service trong kiến trúc tổng thể, được sử dụng bởi tất cả các services khác để verify user identity và permissions.

Vai trò của Identity Service trong kiến trúc tổng thể:

- Authentication Provider: Cung cấp login, registration, và JWT token generation.
- Authorization Provider: Role-based access control (USER, ADMIN) và permission checking.
- User Management: CRUD operations cho user accounts và profiles.
- Session Management: HttpOnly cookie-based session management với refresh tokens.

Service này đáp ứng các NFRs về Security (Authentication & Authorization) và liên quan đến tất cả Use Cases (user phải authenticated để sử dụng hệ thống).

==== 5.3.4.1 Component Diagram - C4 Level 3

Identity Service được tổ chức theo Clean Architecture với 4 layers chính:

#align(center)[
  #image("../images/component/identity-component-diagram.png", width: 100%)
  #context (
    align(
      center,
    )[_Hình #image_counter.display(): Biểu đồ thành phần của Identity Service - Clean Architecture 4 layers_]
  )
  #image_counter.step()
]

==== 5.3.4.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Identity Service_])
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

    table.cell(align: center + horizon, inset: (y: 0.8em))[AuthHandler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request handlers cho authentication operations],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP requests (POST)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP responses (JSON)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Framework (Go)],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth \ Middleware],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT validation từ HttpOnly cookie, set scope trong context],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request với cookie],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Context với scope],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Authentication \ UseCase],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Business logic cho authentication: login, register, OTP verification],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LoginInput, RegisterInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[LoginOutput với JWT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User \ UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business logic cho user management: CRUD, password change],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CreateInput, UpdateInput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UserOutput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Password \ Encrypter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Password hashing và verification],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Plain password],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hashed password],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hashing Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT \ Manager],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT token generation và validation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User claims],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT token string],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JWT Library],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User \ Repository],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database data access layer cho users],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL queries],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SQL ORM (Go)],
  )
]

==== 5.3.4.3 Data Flow

Luồng xử lý chính của Identity Service được chia thành 3 flows: User Registration, User Login, và JWT Validation.

===== a. User Registration Flow

Luồng này được kích hoạt khi user đăng ký tài khoản mới:

#align(center)[
  #image("../images/data-flow/user_registration_flow.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng User Registration Flow_])
  #image_counter.step()
]

===== b. User Login Flow

Luồng này được kích hoạt khi user đăng nhập:

#align(center)[
  #image("../images/data-flow/user_login.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng User Login Flow_])
  #image_counter.step()
]

===== c. JWT Validation Flow

Luồng này được kích hoạt cho mỗi authenticated request:

#align(center)[
  #image("../images/data-flow/auth_middleware.png", width: 80%)
  #context (align(center)[_Hình #image_counter.display(): Luồng JWT Validation - Auth Middleware_])
  #image_counter.step()
]

==== 5.3.4.4 Design Patterns áp dụng

Identity Service áp dụng các design patterns sau:

- Clean Architecture: 4 layers Delivery → UseCase → Domain → Infrastructure với dependency inversion. Testability cao, maintainability tốt.

- Repository Pattern: UserRepository cho database. Abstract data access qua interfaces, business logic không phụ thuộc vào database cụ thể.

- Strategy Pattern: PasswordEncrypter có thể switch hashing algorithm. Encrypter interface với HashPassword() và CheckPasswordHash() methods.

- HttpOnly Cookie Pattern: JWT token được set trong HttpOnly cookie thay vì localStorage. Bảo vệ khỏi XSS attacks.

- Role-Based Access Control: User model có Role field, JWT token chứa role claim. Middleware check role từ JWT payload, enforce permissions.

==== 5.3.4.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Identity Service_])
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth Check Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 10ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Login Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Registration Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 500ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
  )
]

==== 5.3.4.6 Key Decisions

- Secure Password Hashing: Sử dụng industry-standard hashing algorithm. Balance giữa security và performance, đủ mạnh để resist brute-force attacks.

- HttpOnly Cookie cho JWT: Set JWT token trong HttpOnly cookie thay vì localStorage. Bảo vệ khỏi XSS attacks và CSRF protection.

- OTP-based Email Verification: Sử dụng OTP cho email verification thay vì magic links. OTP đơn giản hơn, không cần email template phức tạp.

- Async Email Sending: Publish email events đến message queue thay vì gửi email trực tiếp. Không block request handler, improve response time.

- Role-Based Access Control: JWT token chứa role claim, middleware enforce permissions dựa trên role. Fine-grained access control.

==== 5.3.4.7 Dependencies

Internal Dependencies:

- UserUseCase: Quản lý user accounts và profiles.
- PasswordEncrypter: Hash và verify passwords.
- JWTManager: Generate và validate JWT tokens.
- RabbitMQProducer: Publish email events.

External Dependencies:

- Relational Database (PostgreSQL): User data persistence.
- Message Queue (RabbitMQ): Email event publishing (async email sending).
- Consumer Service: Process email events (OTP sending via SMTP).
