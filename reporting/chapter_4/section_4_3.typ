// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter


== 4.3 Non-Functional Requirements
Dựa trên đặc thù xử lý dữ liệu lớn từ mạng xã hội với luồng thông tin phát sinh liên tục, nhóm đã thiết lập bộ tiêu chí phi chức năng  làm rào chắn kỹ thuật cho dự án. Các yêu cầu này không tồn tại độc lập mà hỗ trợ lẫn nhau, được chia làm hai trụ cột chính là đặc tính kiến trúc và thuộc tính chất lượng

=== 4.3.1 Đặc tính kiến trúc
Phần này xác định các đặc tính kiến trúc (Architecture Characteristics) nhằm đảm bảo hiệu quả vận hành và cấu trúc của hệ thống. Đây là các tiêu chí kỹ thuật dùng để đánh giá và định hướng thiết kế, giúp hệ thống đáp ứng các ràng buộc về công nghệ và bảo trì.
==== 4.3.1.1 Đặc tính kiến trúc chính
#context (align(center)[_Bảng #table_counter.display(): Đặc tính kiến trúc chính_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Định nghĩa & tầm quan trọng*],

    align(center + horizon)[AC-1],
    [
      *Modularity*: Phân rã hệ thống thành các microservices độc lập với low coupling, high cohesion. Mỗi service có trách nhiệm rõ ràng (thu thập, phân tích, quản lý project, authentication). \
      Tầm quan trọng: Cho phép triển khai và mở rộng từng service độc lập, hỗ trợ thay đổi các AI/ML models (NLP models, ASR models) mà không ảnh hưởng đến các service khác.
    ],

    align(center + horizon)[AC-2],
    [
      *Scalability*: Khả năng mở rộng hệ thống theo chiều ngang (horizontal scaling) để xử lý tăng tải. Hỗ trợ multiple workers cho crawling và analytics processing. \
      Tầm quan trọng: Cần thiết cho các tác vụ xử lý khối lượng lớn dữ liệu từ nhiều platform đồng thời, bằng cách scale riêng biệt các service theo nhu cầu (ví dụ: scale crawling workers khi có nhiều projects chạy).
    ],

    align(center + horizon)[AC-3],
    [
      *Performance*: Đáp ứng yêu cầu nhanh để đảm bảo trải nghiệm người dùng mượt mà và xử lý dữ liệu hiệu quả. \
      Tầm quan trọng: Cần thiết cho việc cập nhật tiến độ thời gian thực và sự tuỳ biến của dashboard. Thời gian phản hồi của các modules NLP phải tối ưu để không làm chậm analytics pipeline.
    ],

    align(center + horizon)[AC-4],
    [
      *Testability*: Hệ thống dễ dàng kiểm thử ở mọi cấp độ (unit, integration, e2e) với khả năng mock dependencies và cô lập các components. \
      Tầm quan trọng: Đảm bảo chất lượng code, contract gửi/nhận khi có nhiều services phức tạp, cho phép tái cấu trúc an toàn và phát triển nhanh với độ tin cậy cao.
    ],
  )
]

#context (align(center)[_Bảng #table_counter.display(): Metrics & Mục tiêu - Đặc tính kiến trúc chính_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Metrics & Mục tiêu*],

    align(center + horizon)[AC-1],
    [
      Metrics: Coupling index (I), Efferent coupling (Ce) \
      Mục tiêu: I ≈ 0, Ce < 5. Mỗi service core có ≤ 3 dependencies trực tiếp.
    ],

    align(center + horizon)[AC-2],
    [
      Metrics: Số lượng concurrent workers, throughput (items/phút), response time dưới tải \
      Mục tiêu: Scale từ 2 - 20 workers trong < 5 phút (do AI Docker images nặng >1GB). Xử lý 1,000 items/phút với 10 workers (bao gồm cả posts và comments). Hệ thống cần đảm bảo throughput ổn định khi số lượng projects chạy đồng thời tăng lên, với khả năng xử lý song song nhiều batch dữ liệu từ các platform khác nhau.
    ],

    align(center + horizon)[AC-3],
    [
      Metrics: Response time percentiles (p95), throughput, NLP response time \
      Mục tiêu: NLP response time < 700ms (p95) trên CPU. API response < 500ms (p95), dashboard load < 2 giây, WebSocket message delivery < 100ms.
    ],

    align(center + horizon)[AC-4],
    [
      Metrics: Code coverage, số lượng tests, thời gian chạy test suite \
      Mục tiêu: Code coverage ≥ 80%, ≥ 100 unit tests/service, test suite chạy < 5 phút.
    ],
  )
]

==== 4.3.1.2 Đặc tính kiến trúc bổ trợ

#context (align(center)[_Bảng #table_counter.display(): Đặc tính kiến trúc bổ trợ_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Định nghĩa & Tầm quan trọng*],

    align(center + horizon)[AC-5],
    [
      *Deployability*: Khả năng triển khai hệ thống một cách nhanh chóng và an toàn với minimal downtime. \
      Tầm quan trọng: Cho phép cập nhật thường xuyên các AI models và features mới mà không gián đoạn dịch vụ cho người dùng.
    ],

    align(center + horizon)[AC-6],
    [
      *Maintainability*: Dễ dàng bảo trì, cập nhật và mở rộng hệ thống theo thời gian với chi phí thấp. \
      Tầm quan trọng: Cho phép thêm platform mới (Facebook, Instagram) và cập nhật AI models mà không cần tái cấu trúc lớn.
    ],

    align(center + horizon)[AC-7],
    [
      *Observability*: Khả năng theo dõi, giám sát và debug hệ thống thông qua metrics, logs và traces. \
      Tầm quan trọng: Critical cho việc phát hiện sớm các vấn đề (rate limiting, model errors, queue backlog) và tối ưu hóa hiệu năng.
    ],
  )
]

#context (align(center)[_Bảng #table_counter.display(): Metrics & Mục tiêu - Đặc tính kiến trúc bổ trợ_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Metrics & Mục tiêu*],
    align(center + horizon)[AC-5],
    [
      Metrics: Deployment time, deployment frequency, rollback time \
      Mục tiêu: Deployment time < 5 phút, rollback < 5 phút. Downtime < 30 giây với rolling deployment.
    ],

    align(center + horizon)[AC-6],
    [
      Metrics: Số lượng breaking changes, plugin/adapter isolation, backward compatibility \
      Mục tiêu: Zero breaking changes khi thêm platform mới, architecture hỗ trợ plugin pattern, 100% backward compatibility với API v1.
    ],

    align(center + horizon)[AC-7],
    [
      Metrics: Log coverage, metrics coverage, trace coverage, alert response time \
      Mục tiêu: 100% errors được log, metrics coverage cho tất cả critical paths, alert response time < 5 phút.
    ],
  )
]
\

// === PHẦN 2: THUỘC TÍNH CHẤT LƯỢNG ===
=== 4.3.2 Thuộc tính chất lượng
Mục này xác định các thuộc tính chất lượng nhằm mô tả hành vi và hiệu quả sử dụng của hệ thống từ góc độ người dùng cuối. Các tiêu chí này được thiết lập làm cơ sở để đánh giá mức độ đáp ứng của hệ thống đối với các nhu cầu thực tế trong quá trình vận hành. Các thuộc tính được nhóm thành 3 nhóm lớn dựa trên bản chất: (1) Hiệu năng & Vận hành, (2) An toàn & Tuân thủ, (3) Trải nghiệm & Hỗ trợ.

==== 4.3.2.1 Hiệu năng & Vận hành
#context (align(center)[_Bảng #table_counter.display(): Hiệu năng & Vận hành_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (0.35fr, 0.45fr, 0.9fr),
    // Điều chỉnh lại cột đầu nhỏ hơn xíu cho cân
    stroke: 0.5pt,
    align: (left + top, left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Khía cạnh*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Yêu cầu/Mục tiêu*],

    // === PERFORMANCE ===
    // Response Time (4 rows)
    table.cell(rowspan: 4, align(center + horizon)[*Performance:* \ Response Time]),
    align(center + horizon)[API Endpoints], [Response time < 500ms (p95) và < 1 giây (p99)],
    align(center + horizon)[Dashboard Loading],
    table.cell(align: horizon, inset: (y: 0.8em))[Dashboard initial load < 3 giây],
    align(center + horizon)[WebSocket Updates], [WebSocket message delivery < 100ms (p95)],
    align(center + horizon)[Report Generation],
    table.cell(align: horizon, inset: (y: 0.8em))[Report generation < 10 phút],

    // Throughput (3 rows)
    table.cell(rowspan: 3, align(center + horizon)[*Performance:* \ Throughput]),
    align(center + horizon)[Crawling],
    [Hệ thống tận dụng tối đa rate-limit của từng platform. Hỗ trợ parallel crawling. Thu thập đồng thời cả posts và comments từ các nền tảng mạng xã hội.],
    align(center + horizon)[Analytics Processing],
    [Xử lý \~70 items/phút với 1 worker (bao gồm cả posts và comments), batch processing 20-50 items/batch. Mỗi item được phân tích qua pipeline NLP đầy đủ: preprocessing, intent classification, keyword extraction, sentiment analysis, impact calculation.],
    align(center + horizon)[WebSocket Connections], [Hỗ trợ 1,000 concurrent WebSocket connections],

    // Resource Utilization (3 rows)
    table.cell(rowspan: 3, align(center + horizon)[*Performance:* \ Resource Utilization]),
    align(center + horizon)[CPU], [CPU usage < 60% dưới normal load, < 90% dưới hard load],
    align(center + horizon)[Memory], [Memory usage < 1GB/service instance, NLP model loading < 2GB RAM],
    align(center + horizon)[Network], [Network latency < 50ms giữa services trong cùng namespace trong cụm clusters.],
  )
]

==== 4.3.2.2 An toàn & Tuân thủ

#context (align(center)[_Bảng #table_counter.display(): An toàn & Tuân thủ_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (0.35fr, 0.45fr, 0.9fr),
    // Điều chỉnh lại cột đầu nhỏ hơn xíu cho cân
    stroke: 0.5pt,
    // Căn giữa dọc + ngang cho 2 cột đầu, cột cuối căn trái + trên cùng
    align: (center + horizon, center + horizon, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Khía cạnh*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Yêu cầu/Mục tiêu*],

    // === SECURITY ===
    // Auth & Authorization (3 rows)
    table.cell(rowspan: 2, [*Security:* \ Auth & Authorization]),
    [User Authentication], [JWT với HttpOnly cookies, session timeout 2 giờ hoặc 30 ngày với "remember me"],
    [Authorization], [Verify ownership trước mọi thao tác trên Project, role-based access control (RBAC)],

    // Data Protection (3 rows)
    table.cell(rowspan: 2, [*Security:* \ Data Protection]),
    [Data Encryption], [TLS 1.3 cho tất cả communications, AES-256 cho data at rest],
    [Password Security],
    [Minimum 8 characters. Password được hash trước khi lưu vào database, không lưu plaintext. Hệ thống validate độ dài tối thiểu ở cả frontend và backend để đảm bảo bảo mật.],

    // Application Security (3 rows)
    table.cell(rowspan: 2, [*Security:* \ Application Security]),
    [Input Validation], [Validate tất cả inputs, sanitize user inputs, prevent SQL injection],
    [CORS Policy], [CORS chỉ cho phép production domains, localhost cho development],

    // === COMPLIANCE ===
    // Data Governance (4 rows)
    table.cell(rowspan: 2, [*Compliance:* \ Data Governance]),
    [Right to Access], [User có thể export dữ liệu của mình trong format JSON, CSV, Excel],
    [Right to Delete],
    [Soft-delete với retention 30-60 ngày, hard-delete hoặc anonymize sau đó. PII không giữ > 60 ngày],

    // Platform Compliance (3 rows)
    table.cell(rowspan: 2, [*Compliance:* \ Platform Compliance]),
    [Rate Limit Compliance], [Tôn trọng rate limits của YouTube, TikTok, không bypass captcha],
    [Terms of Service], [Tuân thủ Terms of Service của các platforms, chỉ crawl dữ liệu được phép],
  )
]


==== 4.3.2.3 Trải nghiệm & Hỗ trợ
#context (align(center)[_Bảng #table_counter.display(): Trải nghiệm & Hỗ trợ_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (0.35fr, 0.45fr, 0.9fr),
    // Điều chỉnh lại cột đầu nhỏ hơn xíu cho cân
    stroke: 0.5pt,
    // Căn giữa dọc + ngang cho 2 cột đầu, cột cuối căn trái + trên cùng
    align: (center + horizon, center + horizon, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Khía cạnh*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Yêu cầu/Mục tiêu*],

    // === USABILITY ===
    // User Experience (5 rows)
    table.cell(rowspan: 6, [*Usability:* \ User Experience]),
    [Internationalization], table.cell(align: horizon, inset: (y: 0.8em))[Đa ngôn ngữ (tiếng Việt, tiếng Anh)],
    [Loading States], [Hiển thị loading indicators cho mọi async operations, skeleton screens],
    [Error Messages], [Error messages rõ ràng, actionable, với error codes để support],
    [Confirmation Dialogs], [Xác nhận cho destructive actions, có thể undo trong 30 giây],
    [Progress Indicators], [Real-time progress với percentage, time remaining, items processed],
    [Onboarding], [Tutorial cho first-time users, tooltips cho complex features],

    // Logging (3 rows)
    table.cell(rowspan: 3, [*Monitoring:* \ Logging]),
    [Application Metrics], [Prometheus cho application metrics, dashboard với KPI],
    [Log Levels], [Structured logging: DEBUG, INFO, WARNING, ERROR, CRITICAL],
    [Log Format], [JSON format (timestamp, level, service, trace_id, message)],
  )
]
