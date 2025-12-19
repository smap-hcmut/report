// Chapter 7: Phụ lục

= CHƯƠNG 7: PHỤ LỤC

== Phụ lục A: Danh sách từ viết tắt

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  [*Từ viết tắt*], [*Nghĩa đầy đủ*],
  [SMAP], [Social Media Analytics Platform],
  [API], [Application Programming Interface],
  [REST], [Representational State Transfer],
  [HTTP], [Hypertext Transfer Protocol],
  [HTTPS], [Hypertext Transfer Protocol Secure],
  [JSON], [JavaScript Object Notation],
  [JWT], [JSON Web Token],
  [UUID], [Universally Unique Identifier],
  [CRUD], [Create, Read, Update, Delete],
  [SQL], [Structured Query Language],
  [NoSQL], [Not Only SQL],
  [RDBMS], [Relational Database Management System],
  [ORM], [Object-Relational Mapping],
  [MVC], [Model-View-Controller],
  [UI], [User Interface],
  [UX], [User Experience],
  [URL], [Uniform Resource Locator],
  [URI], [Uniform Resource Identifier],
  [TCP], [Transmission Control Protocol],
  [IP], [Internet Protocol],
  [DNS], [Domain Name System],
  [SSL], [Secure Sockets Layer],
  [TLS], [Transport Layer Security],
  [OAuth], [Open Authorization],
  [CORS], [Cross-Origin Resource Sharing],
  [WebSocket], [Web Socket Protocol],
  [RabbitMQ], [Message Queue System],
  [Redis], [Remote Dictionary Server],
  [PostgreSQL], [Post-greSQL Database],
  [MinIO], [Minimal Object Storage],
  [Docker], [Container Platform],
  [K8s], [Kubernetes],
  [CI/CD], [Continuous Integration/Continuous Deployment],
  [AI], [Artificial Intelligence],
  [ML], [Machine Learning],
  [NLP], [Natural Language Processing],
  [KPI], [Key Performance Indicator],
  [SoV], [Share of Voice],
  [NSS], [Net Sentiment Score],
  [OLAP], [Online Analytical Processing],
  [ETL], [Extract, Transform, Load],
  [DTO], [Data Transfer Object],
  [DAO], [Data Access Object],
  [SOLID], [Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion],
  [DRY], [Don't Repeat Yourself],
  [KISS], [Keep It Simple, Stupid],
  [YAGNI], [You Aren't Gonna Need It],
  [TDD], [Test-Driven Development],
  [BDD], [Behavior-Driven Development],
  [UML], [Unified Modeling Language],
  [ERD], [Entity Relationship Diagram],
  [BPMN], [Business Process Model and Notation],
  [SRS], [Software Requirements Specification],
  [SDD], [Software Design Document],
  [NFR], [Non-Functional Requirement],
  [FR], [Functional Requirement],
  [UC], [Use Case],
  [BR], [Business Rule],
)

#pagebreak()

== Phụ lục B: Glossary (Bảng thuật ngữ)

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Thuật ngữ*], [*Định nghĩa*],
  [Brand Manager], [Nhà quản lý thương hiệu, người sử dụng chính của hệ thống SMAP để theo dõi danh tiếng thương hiệu và phân tích đối thủ cạnh tranh.],
  [Social Media Platform], [Nền tảng mạng xã hội như YouTube, TikTok, Facebook cung cấp dữ liệu công khai cho hệ thống thu thập và phân tích.],
  [Project], [Dự án theo dõi thương hiệu bao gồm cấu hình từ khóa, đối thủ, nền tảng và khoảng thời gian theo dõi.],
  [Dry-run], [Chức năng kiểm tra chất lượng từ khóa bằng cách thu thập mẫu kết quả trước khi chạy project chính thức.],
  [Crawler Worker], [Thành phần thu thập dữ liệu từ các nền tảng mạng xã hội thông qua web scraping.],
  [Sentiment Analysis], [Phân tích cảm xúc của nội dung (tích cực, tiêu cực, trung tính) sử dụng AI/ML.],
  [Aspect Extraction], [Trích xuất các khía cạnh được đề cập trong nội dung (ví dụ: pin, giá, hiệu năng).],
  [Crisis Detection], [Phát hiện khủng hoảng truyền thông dựa trên sự tăng trưởng đột biến của thảo luận tiêu cực.],
  [Trend Detection], [Phát hiện xu hướng tự động dựa trên engagement và velocity của nội dung.],
  [Share of Voice (SoV)], [Tỷ lệ phần trăm thảo luận về thương hiệu so với tổng thảo luận trong ngành.],
  [Net Sentiment Score (NSS)], [Điểm cảm xúc ròng tính bằng (Positive - Negative) / Total.],
  [Microservices], [Kiến trúc phần mềm chia hệ thống thành các services nhỏ, độc lập, dễ mở rộng và bảo trì.],
  [Message Queue], [Hàng đợi tin nhắn cho phép các services giao tiếp bất đồng bộ (sử dụng RabbitMQ).],
  [Pub/Sub], [Mô hình publish-subscribe cho phép gửi thông báo real-time đến nhiều subscribers (sử dụng Redis).],
  [WebSocket], [Giao thức cho phép giao tiếp hai chiều real-time giữa client và server.],
  [Soft Delete], [Xóa logic bằng cách đánh dấu deleted_at thay vì xóa vật lý khỏi database.],
  [Partial Result], [Kết quả không đầy đủ do lỗi, timeout hoặc hủy giữa chừng (is_partial_result=true).],
  [Retention Window], [Khoảng thời gian lưu trữ dữ liệu (90 ngày) trước khi archive hoặc xóa.],
  [Rate Limit], [Giới hạn số lượng requests trong một khoảng thời gian để tránh spam.],
  [Captcha], [Cơ chế xác thực người dùng thật của các platforms để chống bot.],
  [Job ID], [Mã định danh duy nhất cho mỗi tác vụ thu thập hoặc phân tích.],
  [Webhook], [Cơ chế callback HTTP cho phép service gửi thông báo đến service khác khi có sự kiện.],
  [JWT Token], [JSON Web Token dùng để xác thực và truyền thông tin user giữa các services.],
  [JSONB], [Binary JSON format của PostgreSQL cho phép lưu trữ và query dữ liệu JSON hiệu quả.],
  [UUID], [Universally Unique Identifier, mã định danh duy nhất 128-bit.],
  [RFC3339], [Chuẩn định dạng timestamp ISO 8601 (ví dụ: 2024-01-15T10:30:00Z).],
)


// == Phụ lục C: Cấu trúc thư mục source code

// ```
// smap-api/
// ├── src/
// │   ├── identity/          # Identity Service
// │   │   ├── cmd/           # Entry points
// │   │   ├── internal/      # Business logic
// │   │   │   ├── model/     # Domain models
// │   │   │   ├── repository/# Data access
// │   │   │   ├── usecase/   # Use cases
// │   │   │   └── handler/   # HTTP handlers
// │   │   ├── migration/     # Database migrations
// │   │   └── pkg/           # Shared packages
// │   │
// │   ├── project/           # Project Service
// │   │   ├── cmd/
// │   │   ├── internal/
// │   │   │   ├── model/
// │   │   │   ├── repository/
// │   │   │   ├── usecase/
// │   │   │   ├── handler/
// │   │   │   └── webhook/   # Webhook handlers
// │   │   ├── migration/
// │   │   └── pkg/
// │   │
// │   ├── collector/         # Collector Service
// │   │   ├── cmd/
// │   │   ├── internal/
// │   │   │   ├── results/   # Results handler
// │   │   │   └── dispatcher/# Task dispatcher
// │   │   └── pkg/
// │   │
// │   ├── websocket/         # WebSocket Service
// │   │   ├── cmd/
// │   │   ├── internal/
// │   │   │   ├── websocket/ # WebSocket handlers
// │   │   │   └── redis/     # Redis subscriber
// │   │   └── pkg/
// │   │
// │   └── tests/             # Integration tests
// │       └── e2e/
// │
// ├── report/                # Báo cáo đề tài
// │   ├── chapter_0/         # Lời cam đoan, cảm ơn, tóm tắt
// │   ├── chapter_1/         # Giới thiệu
// │   ├── chapter_2/         # Cơ sở lý thuyết
// │   ├── chapter_3/         # Phân tích bài toán
// │   ├── chapter_4/         # Phân tích thiết kế
// │   ├── chapter_5/         # Tổng kết
// │   ├── chapter_6/         # Tài liệu tham khảo
// │   ├── chapter_8/         # Phụ lục
// │   ├── images/            # Hình ảnh, diagrams
// │   └── main.typ           # File chính
// │
// └── docs/                  # Tài liệu kỹ thuật
//     ├── DRY-RUN-DATA-FLOW.md
//     ├── MESSAGE-STRUCTURE-SPECIFICATION.md
//     └── README.md
// ```

// #pagebreak()

// == Phụ lục D: Environment Variables

// Các biến môi trường cần thiết cho từng service:

// *Identity Service:*
// ```bash
// DATABASE_URL=postgresql://user:pass@localhost:5432/identity
// JWT_SECRET=your-secret-key
// JWT_EXPIRATION=24h
// REDIS_URL=redis://localhost:6379
// PORT=8001
// ```

// *Project Service:*
// ```bash
// DATABASE_URL=postgresql://user:pass@localhost:5432/project
// JWT_SECRET=your-secret-key
// REDIS_URL=redis://localhost:6379
// RABBITMQ_URL=amqp://guest:guest@localhost:5672/
// COLLECTOR_WEBHOOK_KEY=internal-secret-key
// PORT=8002
// ```

// *Collector Service:*
// ```bash
// RABBITMQ_URL=amqp://guest:guest@localhost:5672/
// PROJECT_SERVICE_URL=http://localhost:8002
// INTERNAL_WEBHOOK_KEY=internal-secret-key
// MINIO_ENDPOINT=localhost:9000
// MINIO_ACCESS_KEY=minioadmin
// MINIO_SECRET_KEY=minioadmin
// PORT=8003
// ```

// *WebSocket Service:*
// ```bash
// REDIS_URL=redis://localhost:6379
// JWT_SECRET=your-secret-key
// PORT=8004
// ```

// #pagebreak()

// == Phụ lục E: API Endpoints Summary

// *Identity Service (Port 8001):*
// - POST /auth/register - Đăng ký user mới
// - POST /auth/login - Đăng nhập
// - POST /auth/refresh - Refresh JWT token
// - GET /users/me - Lấy thông tin user hiện tại
// - GET /plans - Lấy danh sách plans
// - POST /subscriptions - Tạo subscription mới

// *Project Service (Port 8002):*
// - POST /projects - Tạo project mới (Draft)
// - GET /projects - Lấy danh sách projects
// - GET /projects/{id} - Lấy chi tiết project
// - PUT /projects/{id} - Cập nhật project (chỉ Draft)
// - DELETE /projects/{id} - Soft delete project
// - POST /projects/{id}/start - Khởi chạy project
// - POST /projects/dryrun - Dry-run từ khóa
// - GET /projects/{id}/results - Lấy kết quả phân tích
// - POST /projects/{id}/export - Xuất báo cáo
// - POST /internal/collector/dryrun/callback - Webhook từ Collector

// *WebSocket Service (Port 8004):*
// - WS /ws - WebSocket connection endpoint

