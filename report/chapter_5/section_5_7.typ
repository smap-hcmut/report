// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.7 Truy xuất nguồn gốc và Xác thực thiết kế

Các mục trước đã trình bày chi tiết kiến trúc hệ thống SMAP từ nguyên tắc thiết kế, kiến trúc tổng thể, thiết kế thành phần, cơ sở dữ liệu, luồng xử lý đến các mẫu giao tiếp. Mục này chứng minh thiết kế đáp ứng đầy đủ các yêu cầu từ Chương 4, giải thích các quyết định kiến trúc quan trọng, và phân tích các khoảng trống cùng hạn chế của hệ thống.

=== 5.7.1 Ma trận truy xuất nguồn gốc

Ma trận truy xuất nguồn gốc chứng minh mỗi yêu cầu từ Chương 4 được hiện thực trong thiết kế Chương 5. Phần này bao gồm truy xuất cho 7 yêu cầu chức năng và 7 đặc tính kiến trúc.

==== 5.7.1.1 Truy xuất yêu cầu chức năng

Bảng dưới đây ánh xạ từng yêu cầu chức năng đến các Use Cases, Services, Components và Evidence trong thiết kế.

#context (align(center)[_Bảng #table_counter.display(): Ma trận truy xuất yêu cầu chức năng_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.08fr, 0.22fr, 0.10fr, 0.25fr, 0.35fr),
    stroke: 0.5pt,
    align: (center, left, center, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*FR*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Services*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-1],
    table.cell(align: horizon, inset: (y: 0.8em))[Cấu hình Project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.5.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-2],
    table.cell(align: horizon, inset: (y: 0.8em))[Thực thi và Giám sát],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-02, UC-03],
    table.cell(align: horizon, inset: (y: 0.8em))[Project, Collector, Analytics],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.1, 5.3.2, 5.3.3, 5.5.2, 5.5.3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-3],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý Projects],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-05],
    table.cell(align: horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.5.5],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-4],
    table.cell(align: horizon, inset: (y: 0.8em))[Xem kết quả và So sánh],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-04],
    table.cell(align: horizon, inset: (y: 0.8em))[Project, Analytics],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.2, 5.3.3, 5.5.4],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-5],
    table.cell(align: horizon, inset: (y: 0.8em))[Xuất báo cáo],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-06],
    table.cell(align: horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.5.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-6],
    table.cell(align: horizon, inset: (y: 0.8em))[Phát hiện trend],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-07],
    table.cell(align: horizon, inset: (y: 0.8em))[Collector, Analytics],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.1, 5.3.2, 5.5.7],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-7],
    table.cell(align: horizon, inset: (y: 0.8em))[Phát hiện khủng hoảng],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UC-08],
    table.cell(align: horizon, inset: (y: 0.8em))[Analytics, WebSocket],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.2, 5.3.5, 5.5.8],
  )
]

Chi tiết truy xuất từng yêu cầu chức năng:

- FR-1 Cấu hình Project: Project Service cung cấp REST API để tạo và cấu hình project với thông tin thương hiệu, từ khóa, đối thủ và platforms. Wizard 4 bước được hiện thực trong Web UI, validation được thực hiện ở cả frontend và backend. Evidence tại mục 5.3.3 mô tả Project Service components và mục 5.5.1 mô tả sequence diagram UC-01.

- FR-2 Thực thi và Giám sát: Pipeline 4 giai đoạn được hiện thực qua Event-Driven Architecture. Project Service publish event khi user khởi chạy, Collector Service dispatch jobs đến Scrapper Services, Analytics Service xử lý NLP pipeline, WebSocket Service broadcast tiến độ real-time. Evidence tại các mục 5.3.1, 5.3.2, 5.3.3 và sequence diagrams UC-02, UC-03.

- FR-3 Quản lý Projects: Project Service cung cấp API để lọc, tìm kiếm, sắp xếp danh sách projects. Soft-delete với retention 30-60 ngày được hiện thực qua deleted_at column. Evidence tại mục 5.3.3 và sequence diagram UC-05.

- FR-4 Xem kết quả và So sánh: Dashboard với 4 phần KPI, Sentiment Trend, Aspect và Competitor được hiện thực trong Project Service với dữ liệu từ Analytics Service. Redis cache tối ưu response time dưới 2 giây. Evidence tại mục 5.3.2, 5.3.3 và sequence diagram UC-04.

- FR-5 Xuất báo cáo: Export worker xử lý bất đồng bộ, hỗ trợ PDF, Excel, CSV. File được lưu trên MinIO, notification qua WebSocket khi hoàn thành. Timeout 10 phút cho large reports. Evidence tại mục 5.3.3 và sequence diagram UC-06.

- FR-6 Phát hiện trend: Cron job chạy hàng ngày lúc 2:00 AM UTC+7, thu thập trends từ các platforms, tính Trend Score và Velocity, lưu Top trends với retention 30 ngày. Evidence tại mục 5.3.1, 5.3.2 và sequence diagram UC-07.

- FR-7 Phát hiện khủng hoảng: Crisis Monitor chạy mỗi 15 phút, quét dữ liệu mới theo cấu hình keywords và ngưỡng, tạo Alert và gửi notification real-time qua WebSocket. Evidence tại mục 5.3.2, 5.3.5 và sequence diagram UC-08.


==== 5.7.1.2 Truy xuất đặc tính kiến trúc

Bảng dưới đây ánh xạ 7 đặc tính kiến trúc từ mục 4.3.1 đến các quyết định thiết kế và evidence trong Chương 5.

#context (align(center)[_Bảng #table_counter.display(): Ma trận truy xuất đặc tính kiến trúc_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.08fr, 0.18fr, 0.30fr, 0.22fr, 0.22fr),
    stroke: 0.5pt,
    align: (center, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đặc tính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metrics và Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Quyết định thiết kế*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-1],
    table.cell(align: horizon, inset: (y: 0.8em))[Modularity],
    table.cell(align: horizon, inset: (y: 0.8em))[I ≈ 0, Ce < 5, ≤ 3 deps/service],
    table.cell(align: horizon, inset: (y: 0.8em))[Microservices, DDD Bounded Contexts],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.1, 5.2.1, 5.2.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-2],
    table.cell(align: horizon, inset: (y: 0.8em))[Scalability],
    table.cell(align: horizon, inset: (y: 0.8em))[Scale 2-20 workers < 5 min, 1,000 items/min],
    table.cell(align: horizon, inset: (y: 0.8em))[Independent scaling, Kubernetes HPA],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.2.1, 5.2.5],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
    table.cell(align: horizon, inset: (y: 0.8em))[Performance],
    table.cell(align: horizon, inset: (y: 0.8em))[API < 500ms, Dashboard < 2s, NLP < 700ms],
    table.cell(align: horizon, inset: (y: 0.8em))[Polyglot runtime, Redis cache],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3, 5.6.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-4],
    table.cell(align: horizon, inset: (y: 0.8em))[Testability],
    table.cell(align: horizon, inset: (y: 0.8em))[Coverage ≥ 80%, ≥ 100 tests/service],
    table.cell(align: horizon, inset: (y: 0.8em))[SOLID, Port and Adapter],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.1.6, 5.1.1.7],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-5],
    table.cell(align: horizon, inset: (y: 0.8em))[Deployability],
    table.cell(align: horizon, inset: (y: 0.8em))[Deploy < 5 min, rollback < 5 min],
    table.cell(align: horizon, inset: (y: 0.8em))[Kubernetes rolling update],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.2.5],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-6],
    table.cell(align: horizon, inset: (y: 0.8em))[Maintainability],
    table.cell(align: horizon, inset: (y: 0.8em))[Zero breaking changes, 100% backward compat],
    table.cell(align: horizon, inset: (y: 0.8em))[Clean Architecture, API versioning],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.1, 5.3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-7],
    table.cell(align: horizon, inset: (y: 0.8em))[Observability],
    table.cell(align: horizon, inset: (y: 0.8em))[100% errors logged, alert < 5 min],
    table.cell(align: horizon, inset: (y: 0.8em))[Structured logging, Prometheus],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.6.4],
  )
]

Chi tiết truy xuất từng đặc tính kiến trúc:

- AC-1 Modularity: Kiến trúc Microservices với 7 core services và 3 supporting services đảm bảo loose coupling. Mỗi service có database riêng, giao tiếp qua well-defined APIs hoặc events. DDD Bounded Contexts xác định ranh giới rõ ràng giữa các domains. Coupling index I ≈ 0 đạt được nhờ services chỉ phụ thuộc vào abstractions, không phụ thuộc trực tiếp vào nhau.

- AC-2 Scalability: Kubernetes HPA cho phép auto-scale workers dựa trên CPU và queue depth. Collector workers có thể scale từ 2-20 instances trong vòng 5 phút. Throughput đạt 1,000 items/phút với 10 workers nhờ parallel processing và batch optimization.

- AC-3 Performance: Polyglot runtime tối ưu cho từng workload, Go cho API services đạt response time thấp, Python cho NLP pipeline với ecosystem phong phú. Redis cache cho dashboard aggregation giảm response time xuống dưới 2 giây. NLP pipeline với ONNX optimization đạt dưới 700ms per batch.

- AC-4 Testability: SOLID principles và Port and Adapter pattern cho phép mock dependencies trong unit tests. Business logic tách biệt khỏi infrastructure, có thể test độc lập. Target coverage 80% với 100+ tests per service.

- AC-5 Deployability: Kubernetes rolling update strategy đảm bảo zero-downtime deployment. Mỗi service có thể deploy độc lập trong vòng 5 phút. Rollback thực hiện qua kubectl rollout undo trong vòng 5 phút.

- AC-6 Maintainability: Clean Architecture với 3 layers tách biệt business logic khỏi infrastructure. API versioning đảm bảo backward compatibility. Plugin pattern cho phép extend functionality mà không breaking existing code.

- AC-7 Observability: Structured logging với JSON format, Zap cho Go services và Loguru cho Python services. Prometheus metrics cho monitoring với /metrics endpoint per service. Health checks với liveness và readiness probes. Alert rules cấu hình để notify trong vòng 5 phút khi có issues.


==== 5.7.1.3 Truy xuất yêu cầu phi chức năng

Ngoài 7 đặc tính kiến trúc chính, hệ thống còn đáp ứng các yêu cầu phi chức năng chi tiết từ mục 4.3.2. Bảng dưới đây tổng hợp theo 4 nhóm chính.

#context (align(center)[_Bảng #table_counter.display(): Truy xuất NFRs nhóm Hiệu năng và Vận hành_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.30fr, 0.45fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hiện thực*],

    table.cell(align: horizon, inset: (y: 0.8em))[Response Time],
    table.cell(align: horizon, inset: (y: 0.8em))[API < 500ms, Dashboard < 3s, WebSocket < 100ms],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Go framework Gin cho API, Redis cache cho Dashboard, Redis Pub/Sub cho WebSocket. Evidence: Mục 5.3, 5.6.3],

    table.cell(align: horizon, inset: (y: 0.8em))[Throughput],
    table.cell(align: horizon, inset: (y: 0.8em))[Crawling max rate-limit, Analytics 70 items/min/worker],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Worker pool pattern với parallel crawlers, batch processing 20-50 items. Evidence: Mục 5.3.1, 5.3.2],

    table.cell(align: horizon, inset: (y: 0.8em))[Resource Utilization],
    table.cell(align: horizon, inset: (y: 0.8em))[CPU < 60% normal, Memory < 1GB/service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Kubernetes resource limits, independent scaling per service. Evidence: Mục 5.2.5],

    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket Connections],
    table.cell(align: horizon, inset: (y: 0.8em))[1,000 concurrent connections],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Multi-instance WebSocket với Redis Pub/Sub fanout. Evidence: Mục 5.6.3],
  )
]

#context (align(center)[_Bảng #table_counter.display(): Truy xuất NFRs nhóm An toàn và Tuân thủ_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.30fr, 0.45fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hiện thực*],

    table.cell(align: horizon, inset: (y: 0.8em))[Authentication],
    table.cell(align: horizon, inset: (y: 0.8em))[JWT với HttpOnly cookies, session 2h/30 days],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Identity Service cấp phát JWT, refresh token mechanism. Evidence: Mục 5.3.4],

    table.cell(align: horizon, inset: (y: 0.8em))[Authorization],
    table.cell(align: horizon, inset: (y: 0.8em))[Ownership verify, RBAC],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Middleware kiểm tra project.created_by, role-based access control. Evidence: Mục 5.3.3, 5.3.4],

    table.cell(align: horizon, inset: (y: 0.8em))[Data Protection],
    table.cell(align: horizon, inset: (y: 0.8em))[TLS 1.3, AES-256 at rest],
    table.cell(align: horizon, inset: (y: 0.8em))[TLS termination tại ingress, encrypted storage. Evidence: Mục 5.2.5],

    table.cell(align: horizon, inset: (y: 0.8em))[Application Security],
    table.cell(align: horizon, inset: (y: 0.8em))[Input validation, SQL injection prevention],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Schema validation với Pydantic và Go validator, parameterized queries. Evidence: Mục 5.3],

    table.cell(align: horizon, inset: (y: 0.8em))[Data Governance],
    table.cell(align: horizon, inset: (y: 0.8em))[Right to access, right to delete],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Export API cho JSON/CSV/Excel, soft-delete với retention 30-60 ngày. Evidence: Mục 5.3.3],

    table.cell(align: horizon, inset: (y: 0.8em))[Platform Compliance],
    table.cell(align: horizon, inset: (y: 0.8em))[Respect rate limits, follow ToS],
    table.cell(align: horizon, inset: (y: 0.8em))[Rate limiter per platform, exponential backoff. Evidence: Mục 5.3.1],
  )
]

#context (align(center)[_Bảng #table_counter.display(): Truy xuất NFRs nhóm Trải nghiệm và Hỗ trợ_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.30fr, 0.45fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hiện thực*],

    table.cell(align: horizon, inset: (y: 0.8em))[Đa ngôn ngữ],
    table.cell(align: horizon, inset: (y: 0.8em))[Hỗ trợ VI, EN],
    table.cell(align: horizon, inset: (y: 0.8em))[i18n trong Web UI với Next.js. Evidence: Mục 5.3.6],

    table.cell(align: horizon, inset: (y: 0.8em))[Loading States],
    table.cell(align: horizon, inset: (y: 0.8em))[Hiển thị trạng thái loading],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Skeleton loading, progress indicators trong Web UI. Evidence: Mục 5.3.6],

    table.cell(align: horizon, inset: (y: 0.8em))[Error Messages],
    table.cell(align: horizon, inset: (y: 0.8em))[Error codes và messages rõ ràng],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Standardized error response format với code và message. Evidence: Mục 5.6.1],

    table.cell(align: horizon, inset: (y: 0.8em))[Real-time Progress],
    table.cell(align: horizon, inset: (y: 0.8em))[Hiển thị tiến độ thời gian thực],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket push updates với phase và percent. Evidence: Mục 5.6.3],

    table.cell(align: horizon, inset: (y: 0.8em))[Monitoring],
    table.cell(align: horizon, inset: (y: 0.8em))[Prometheus metrics, structured logs],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[/metrics endpoint per service, JSON logs với trace_id. Evidence: Mục 5.6.4],
  )
]

==== 5.7.1.4 Tổng hợp Coverage

#context (align(center)[_Bảng #table_counter.display(): Tổng hợp Coverage_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.30fr, 0.20fr, 0.20fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tổng số*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đã cover*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Evidence Sections*],

    table.cell(align: horizon, inset: (y: 0.8em))[Functional Requirements],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7 (100%)],
    table.cell(align: horizon, inset: (y: 0.8em))[5.3, 5.5],

    table.cell(align: horizon, inset: (y: 0.8em))[Architecture Characteristics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7 (100%)],
    table.cell(align: horizon, inset: (y: 0.8em))[5.1, 5.2, 5.6],

    table.cell(align: horizon, inset: (y: 0.8em))[Performance NFRs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4 (100%)],
    table.cell(align: horizon, inset: (y: 0.8em))[5.3, 5.6],

    table.cell(align: horizon, inset: (y: 0.8em))[Security NFRs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[6],
    table.cell(align: center + horizon, inset: (y: 0.8em))[6 (100%)],
    table.cell(align: horizon, inset: (y: 0.8em))[5.2.5, 5.3.4],

    table.cell(align: horizon, inset: (y: 0.8em))[Usability NFRs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5 (100%)],
    table.cell(align: horizon, inset: (y: 0.8em))[5.3.6, 5.6],
  )
]

Tổng cộng: 29 yêu cầu đã được truy xuất đến các quyết định thiết kế và evidence cụ thể trong Chương 5. Mỗi yêu cầu có ít nhất một section reference chứng minh cách hiện thực.


=== 5.7.2 Hồ sơ quyết định kiến trúc

Phần này ghi lại 6 quyết định kiến trúc quan trọng nhất của hệ thống SMAP, giải thích bối cảnh, lý do lựa chọn, các phương án đã xem xét và hệ quả của mỗi quyết định.

==== ADR-001: Kiến trúc Microservices

Bối cảnh: Hệ thống SMAP cần đáp ứng các yêu cầu mâu thuẫn về runtime. API services cần hiệu năng cao với Go, NLP pipeline cần ecosystem Python với PhoBERT và transformers. Workload không đồng đều giữa Crawler chạy theo burst và Analytics xử lý liên tục. Yêu cầu fault isolation để lỗi ở một module không ảnh hưởng toàn hệ thống.

Quyết định: Chọn kiến trúc Microservices với 7 core services và 3 supporting services, mỗi service có database riêng và có thể deploy độc lập.

Các lựa chọn đã xem xét:

- Monolithic: Single codebase, đơn giản nhưng không hỗ trợ polyglot runtime, không thể scale độc lập, blast radius lớn khi có lỗi.

- Modular Monolith: Tổ chức code theo modules nhưng vẫn chạy trên một runtime, không giải quyết được polyglot requirement và runtime isolation.

- Microservices: Tách biệt vật lý các services, hỗ trợ polyglot runtime, independent scaling, fault isolation tốt.

Hệ quả tích cực:

- Independent deployment cho phép hotfix NLP model trong 5 phút mà không ảnh hưởng API services.

- Technology flexibility với Go cho API đạt P95 dưới 50ms, Python cho NLP với ecosystem phong phú.

- Fault isolation đảm bảo Crawler crash không ảnh hưởng Dashboard.

- Independent scaling cho phép scale Analytics workers độc lập với API.

Hệ quả tiêu cực:

- Operational complexity cao hơn, cần Kubernetes và distributed tracing.

- Network overhead thêm 10-30ms latency cho inter-service calls.

- Data consistency chuyển sang eventually consistent thay vì ACID.

Evidence: Mục 5.2.1 phân tích chi tiết 3 phương án, mục 5.2.2 mô tả service decomposition.

==== ADR-002: Polyglot Runtime với Go và Python

Bối cảnh: Hệ thống có 2 loại workload khác nhau. API và Orchestration cần low latency dưới 200ms, high throughput và concurrency primitives. NLP Pipeline cần ML libraries như transformers, torch, scikit-learn chỉ có trong Python ecosystem.

Quyết định: Sử dụng Go cho 4 services là Project, Collector, Identity, WebSocket và Python cho 3 services là Analytics, Speech2Text, Scrapper.

Các lựa chọn đã xem xét:

- All Python với FastAPI: API latency P95 khoảng 150ms cao hơn Go, GIL giới hạn concurrency.

- All Go: Không có PhoBERT library, TensorFlow Go binding chưa mature.

- Polyglot Go và Python: Best tool for each job, tối ưu cho từng workload.

Hệ quả tích cực:

- Performance tối ưu với API services P95 dưới 50ms, NLP pipeline sử dụng CUDA acceleration.

- Best libraries với PhoBERT và transformers cho Python, Gin framework cho Go.

- Developer productivity với team backend quen Go, team NLP quen Python.

Hệ quả tiêu cực:

- Maintain 2 tech stacks với go.mod và pyproject.toml, 2 sets of linters.

- Hiring complexity cần developers biết cả Go và Python.

- Code sharing limited, shared logic qua RabbitMQ events thay vì function calls.

Evidence: Mục 5.3.2 mô tả Analytics Service Python stack, mục 5.3.3 mô tả Project Service Go stack.

==== ADR-003: Event-Driven Architecture với RabbitMQ

Bối cảnh: Pipeline xử lý dài từ Crawl 5-30 phút đến Analyze 2-10 phút đến Aggregate 30 giây. Synchronous REST sẽ gây timeout cho user. Cần decoupling để Crawler fail không block Analytics. Cần retry mechanism khi platform rate-limit.

Quyết định: Sử dụng Event-Driven Architecture với RabbitMQ làm message broker trung tâm.

Các lựa chọn đã xem xét:

- Synchronous REST: Blocking gây user timeout, tight coupling, không có built-in retry.

- Kafka: Overkill cho scale dưới 10K events/day, operational overhead với Zookeeper.

- RabbitMQ: Built-in retry, Dead Letter Queue, lower operational overhead.

Hệ quả tích cực:

- Async processing cho phép user nhận 202 Accepted ngay và tiếp tục sử dụng app.

- Loose coupling với services giao tiếp qua events, không biết nhau existence.

- Resilience với DLQ cho failed messages, retry 3 lần với exponential backoff.

- Scalability cho phép add workers mà không cần code changes.

Hệ quả tiêu cực:

- Eventually consistent với delay 1-5 giây giữa crawl xong và analytics bắt đầu.

- Debugging phức tạp với event flow span multiple services, cần trace ID.

- Message broker là single point of failure, cần cluster để mitigation.

Evidence: Mục 5.6.2 mô tả RabbitMQ topology, event catalog, DLQ config.


==== ADR-004: Database Strategy với PostgreSQL và MongoDB

Bối cảnh: Hệ thống có 2 loại data khác nhau. Structured data như Projects, users, analytics results cần ACID, foreign keys, transactions. Semi-structured data như raw crawled posts là large JSON docs khoảng 100KB với flexible schema.

Quyết định: Sử dụng PostgreSQL cho transactional data và MongoDB cho raw crawled data.

Các lựa chọn đã xem xét:

- All PostgreSQL với JSONB: JSONB query performance kém cho large docs, bloat table size.

- All MongoDB: Không có ACID transactions cho critical operations, team thiếu expertise cho complex queries.

- Hybrid PostgreSQL và MongoDB: Best fit cho từng loại data.

Hệ quả tích cực:

- Optimal performance với PostgreSQL ACID transactions và MongoDB flexible schema.

- Right tool với relational queries cho analytics aggregation, document store cho raw posts.

- Scalability với MongoDB sharding cho raw data growth lên đến 1M posts/project.

Hệ quả tiêu cực:

- Maintain 2 databases với backups, monitoring, upgrades riêng.

- No joins giữa databases, cần application-level join.

- Data consistency không có distributed transactions, sử dụng SAGA pattern.

Evidence: Mục 5.4.1 mô tả PostgreSQL schema, mục 5.4.2 mô tả MongoDB collections.

==== ADR-005: Redis cho Cache và Pub/Sub

Bối cảnh: Cần 3 use cases là Cache cho dashboard aggregation results, Session storage cho JWT refresh tokens, và Real-time messaging cho WebSocket notifications broadcast.

Quyết định: Sử dụng Redis cho cả 3 use cases.

Các lựa chọn đã xem xét:

- Memcached: Chỉ caching, không có Pub/Sub và persistence.

- Separate systems với Memcached cho cache, NATS cho Pub/Sub, PostgreSQL cho session: Operational overhead cao với 3 systems.

- Redis unified solution: Single system cho cả 3 use cases.

Hệ quả tích cực:

- Single system dễ vận hành với một monitoring stack.

- Low latency với sub-millisecond cache hits, P99 dưới 5ms cho Pub/Sub.

- Versatility với Strings cho cache, Hashes cho sessions, Pub/Sub cho WebSocket.

Hệ quả tiêu cực:

- Single point of failure khi Redis down thì không có cache và WebSocket, cần Sentinel cluster để mitigation.

- Memory limits với max dataset bằng RAM size, cần eviction policy.

- Persistence trade-off giữa AOF chậm và RDB có risk data loss.

Evidence: Mục 5.6.3 mô tả Redis Pub/Sub cho WebSocket multi-instance, mục 5.3.1 mô tả Redis state tracking.

==== ADR-006: Kubernetes cho Orchestration

Bối cảnh: Cần deploy, scale và manage 7 services cùng databases và message broker, tổng cộng hơn 10 containers.

Quyết định: Sử dụng Kubernetes với Horizontal Pod Autoscaler.

Các lựa chọn đã xem xét:

- Docker Compose: Simple orchestration nhưng không có auto-scaling và self-healing.

- Docker Swarm: Native Docker orchestration nhưng ít features hơn Kubernetes, declining community.

- Kubernetes: Industry standard với auto-scaling, self-healing, rich ecosystem.

Hệ quả tích cực:

- Auto-scaling với HPA scale Analytics workers dựa trên CPU target 70%.

- Self-healing với crashed pods auto-restart, failed nodes auto-replace.

- Declarative với YAML configs, GitOps-ready.

- Rich ecosystem với Helm charts, Prometheus, Grafana.

Hệ quả tiêu cực:

- Learning curve với team cần học Kubernetes concepts như Pods, Services, Ingress.

- Resource overhead với control plane sử dụng khoảng 1GB RAM.

- Complexity với nhiều YAML files và moving parts.

Evidence: Mục 5.2.5 mô tả Kubernetes deployment architecture, mục 5.6.4 mô tả Kubernetes probes cho health checks.


=== 5.7.3 Phân tích khoảng trống

Phần này phân tích các khoảng trống kỹ thuật, hạn chế đã biết và các đánh đổi kiến trúc có chủ đích trong thiết kế hệ thống SMAP.

==== 5.7.3.1 Khoảng trống kỹ thuật

Bảng dưới đây liệt kê các chức năng chưa hoàn thiện trong phiên bản hiện tại.

#context (align(center)[_Bảng #table_counter.display(): Các khoảng trống kỹ thuật_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.35fr, 0.25fr, 0.20fr),
    stroke: 0.5pt,
    align: (left, left, left, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Khoảng trống*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Giải pháp tạm thời*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ưu tiên*],

    table.cell(align: horizon, inset: (y: 0.8em))[Facebook Crawler],
    table.cell(align: horizon, inset: (y: 0.8em))[Chưa hiện thực Facebook scraping do API restrictions phức tạp],
    table.cell(align: horizon, inset: (y: 0.8em))[Sử dụng TikTok và YouTube data],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P1],

    table.cell(align: horizon, inset: (y: 0.8em))[Email Notifications],
    table.cell(align: horizon, inset: (y: 0.8em))[Chưa có email alerts cho crisis detection],
    table.cell(align: horizon, inset: (y: 0.8em))[WebSocket real-time notification],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Advanced Report Templates],
    table.cell(align: horizon, inset: (y: 0.8em))[Chỉ có basic PDF, Excel, CSV templates],
    table.cell(align: horizon, inset: (y: 0.8em))[Download CSV và tự format],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P3],

    table.cell(align: horizon, inset: (y: 0.8em))[Multi-language NLP],
    table.cell(align: horizon, inset: (y: 0.8em))[Chỉ hỗ trợ Vietnamese, chưa có English],
    table.cell(align: horizon, inset: (y: 0.8em))[Manual translation trước khi analyze],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Distributed Tracing UI],
    table.cell(align: horizon, inset: (y: 0.8em))[Chưa có visualization tool như Jaeger],
    table.cell(align: horizon, inset: (y: 0.8em))[Manual log search với trace_id],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Mobile App],
    table.cell(align: horizon, inset: (y: 0.8em))[Chỉ có Web UI, chưa có native mobile app],
    table.cell(align: horizon, inset: (y: 0.8em))[Responsive design trên mobile browser],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P3],
  )
]

Chiến lược xử lý khoảng trống:

- P1 Critical: Hiện thực trong 6 tháng tới, ảnh hưởng trực tiếp đến business value.

- P2 High: Hiện thực trong 12 tháng, cải thiện user experience và operational efficiency.

- P3 Medium: Backlog, hiện thực khi có resources.

==== 5.7.3.2 Hạn chế đã biết

Bảng dưới đây liệt kê các ràng buộc bên ngoài không thể thay đổi.

#context (align(center)[_Bảng #table_counter.display(): Các hạn chế đã biết_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.33fr, 0.45fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hạn chế*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nguyên nhân*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Giải pháp giảm thiểu*],

    table.cell(align: horizon, inset: (y: 0.8em))[Platform API Rate Limits],
    table.cell(align: horizon, inset: (y: 0.8em))[TikTok 1000 req/hour, YouTube 10K quota/day do platform policies],
    table.cell(align: horizon, inset: (y: 0.8em))[Exponential backoff, cache platform metadata, rotate API keys nếu có],

    table.cell(align: horizon, inset: (y: 0.8em))[NLP Model Accuracy],
    table.cell(align: horizon, inset: (y: 0.8em))[PhoBERT khoảng 85% accuracy cho Vietnamese sentiment],
    table.cell(align: horizon, inset: (y: 0.8em))[Human review cho critical crisis posts, continuous model retraining],

    table.cell(align: horizon, inset: (y: 0.8em))[Real-time Delay],
    table.cell(align: horizon, inset: (y: 0.8em))[Crisis detection có 15-30 phút delay do cron job interval],
    table.cell(align: horizon, inset: (y: 0.8em))[Có thể giảm xuống 5 phút nếu cần với trade-off higher resource cost],

    table.cell(align: horizon, inset: (y: 0.8em))[Storage Growth],
    table.cell(align: horizon, inset: (y: 0.8em))[MinIO storage tăng khoảng 10GB/day do user-generated content],
    table.cell(align: horizon, inset: (y: 0.8em))[Data retention policy 90 ngày, archive old projects],

    table.cell(align: horizon, inset: (y: 0.8em))[Crawler Reliability],
    table.cell(align: horizon, inset: (y: 0.8em))[Platform thay đổi HTML structure gây crawler break],
    table.cell(align: horizon, inset: (y: 0.8em))[Monitor error rate, quick hotfix deployment dưới 4 giờ],

    table.cell(align: horizon, inset: (y: 0.8em))[Language Support],
    table.cell(align: horizon, inset: (y: 0.8em))[PhoBERT model chỉ trained trên Vietnamese],
    table.cell(align: horizon, inset: (y: 0.8em))[Plan thêm English model với mBERT trong tương lai],
  )
]

Acceptance Criteria cho các hạn chế:

- Platform limits: Chấp nhận như unavoidable, tối ưu trong giới hạn cho phép.

- NLP accuracy: 85% acceptable cho MVP, cải thiện dần qua model retraining.

- Real-time delay: 15 phút acceptable, có thể optimize xuống 5 phút nếu business cần.

==== 5.7.3.3 Đánh đổi kiến trúc có chủ đích

Bảng dưới đây liệt kê các quyết định thiết kế có trade-off được chấp nhận có chủ đích.

#context (align(center)[_Bảng #table_counter.display(): Các đánh đổi kiến trúc có chủ đích_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.26fr, 0.26fr, 0.26fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đánh đổi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lựa chọn*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Từ bỏ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lý do*],

    table.cell(align: horizon, inset: (y: 0.8em))[Consistency vs Availability],
    table.cell(align: horizon, inset: (y: 0.8em))[Eventual consistency, AP trong CAP],
    table.cell(align: horizon, inset: (y: 0.8em))[Strong consistency, CP],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Event-driven async processing cần eventual consistency, delay 1-5s acceptable],

    table.cell(align: horizon, inset: (y: 0.8em))[Simplicity vs Flexibility],
    table.cell(align: horizon, inset: (y: 0.8em))[Microservices phức tạp],
    table.cell(align: horizon, inset: (y: 0.8em))[Monolith đơn giản],
    table.cell(align: horizon, inset: (y: 0.8em))[Cần polyglot runtime và independent scaling],

    table.cell(align: horizon, inset: (y: 0.8em))[Performance vs Cost],
    table.cell(align: horizon, inset: (y: 0.8em))[Nhiều services tốn kém hơn],
    table.cell(align: horizon, inset: (y: 0.8em))[Ít services tiết kiệm],
    table.cell(align: horizon, inset: (y: 0.8em))[Optimize cho từng workload, better UX],

    table.cell(align: horizon, inset: (y: 0.8em))[Real-time vs Batch],
    table.cell(align: horizon, inset: (y: 0.8em))[Hybrid với real-time alerts và daily trends],
    table.cell(align: horizon, inset: (y: 0.8em))[All real-time tốn kém],
    table.cell(align: horizon, inset: (y: 0.8em))[Crisis cần instant, trends có thể chờ],

    table.cell(align: horizon, inset: (y: 0.8em))[Developer Productivity vs Runtime Performance],
    table.cell(align: horizon, inset: (y: 0.8em))[Go và Python, 2 languages],
    table.cell(align: horizon, inset: (y: 0.8em))[Python only, 1 language],
    table.cell(align: horizon, inset: (y: 0.8em))[Best tool for job, Go fast, Python rich libs],

    table.cell(align: horizon, inset: (y: 0.8em))[Data Completeness vs Privacy],
    table.cell(align: horizon, inset: (y: 0.8em))[Store raw posts đầy đủ],
    table.cell(align: horizon, inset: (y: 0.8em))[Chỉ store aggregated data],
    table.cell(align: horizon, inset: (y: 0.8em))[Cần drilldown vào raw content cho crisis analysis],
  )
]

Justification: Tất cả trade-offs đã được documented và approved trong quá trình architecture review. Mỗi quyết định có evidence từ requirements Chương 4 và technical constraints.


=== Tổng kết

Mục 5.7 đã chứng minh thiết kế hệ thống SMAP đáp ứng đầy đủ các yêu cầu từ Chương 4. Ma trận truy xuất nguồn gốc cho thấy 7 yêu cầu chức năng, 7 đặc tính kiến trúc và các yêu cầu phi chức năng về hiệu năng, an toàn, trải nghiệm đều được hiện thực với evidence cụ thể trong các mục 5.1 đến 5.6.

6 hồ sơ quyết định kiến trúc giải thích rõ ràng lý do chọn Microservices, Polyglot Runtime, Event-Driven Architecture, Database Strategy, Redis và Kubernetes. Mỗi quyết định phân tích các phương án đã xem xét, hệ quả tích cực và tiêu cực, cùng evidence từ thiết kế thực tế.

Phân tích khoảng trống xác định 6 chức năng chưa hoàn thiện với priority và giải pháp tạm thời, 6 hạn chế bên ngoài với acceptance criteria, và 6 đánh đổi kiến trúc có chủ đích với justification. Các khoảng trống và hạn chế đều có mitigation plan rõ ràng.

Thiết kế hệ thống SMAP đã được validate toàn diện qua traceability matrix, architecture decision records và gaps analysis. Hệ thống đáp ứng đầy đủ yêu cầu từ Chương 4 với chất lượng cao, đồng thời thành thật về limitations và có mitigation plans cho các khoảng trống.

