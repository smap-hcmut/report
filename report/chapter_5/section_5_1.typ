#import "../counters.typ": image_counter, table_counter


Dựa trên các yêu cầu đã phân tích ở Chương 4: Functional Requirements (mục 4.2), Non-Functional Requirements (mục 4.3) và Use Cases (mục 4.4), kiến trúc tổng thể của hệ thống SMAP được trình bày ở chương này, bao gồm các quyết định thiết kế quan trọng, cấu trúc các thành phần và công nghệ được lựa chọn.
== 5.1 Phương pháp tiếp cận

Áp dụng phương pháp phân tích yêu cầu phi chức năng (NFR-driven analysis) để thiết kế kiến trúc tuân thủ các ràng buộc vận hành của hệ thống. Kiến trúc được thiết kế tập trung vào 6 nhóm yêu cầu phi chức năng chính được phân tích chi tiết ở mục 4.3. Các nhóm này được xác định để phản ánh đúng trọng tâm thiết kế: vừa dựa trên tầm quan trọng đối với SMAP, vừa dựa trên quy mô yêu cầu của mỗi nhóm:

#align(center)[
  #image("../images/NFRs_rada_chart.png", width: 45%)
  #context (align(center)[_Hình #image_counter.display(): Phân bố NFRs theo 6 nhóm chính_])
  #image_counter.step()
]

Phân tích phân bố NFRs:

1. Scalability - 7 NFRs: Là architectural driver quan trọng nhất cho việc chọn Microservices. Bao gồm AC-2 về scale workers, 3 yêu cầu về throughput, và 3 yêu cầu về resource utilization. Đây là yêu cầu quan trọng nhất vì đặc thù xử lý dữ liệu lớn từ nhiều platforms đồng thời.

2. Usability – 9 NFRs: Gồm 6 yêu cầu về UX như i18n, loading states, error messages, confirmations, progress indicators và onboarding; cùng 3 yêu cầu về monitoring. Tập trung vào trải nghiệm người dùng cuối và khả năng vận hành.

3. Security – 7 NFRs: Bao gồm 2 NFRs về Authentication & Authorization, 2 NFRs về Data Protection, và 3 NFRs về Application Security. Đảm bảo an toàn dữ liệu người dùng.

4. Performance – 4 NFRs: Tập trung vào Response Time cho API endpoints, Dashboard loading, WebSocket updates, và Report generation. Đây là yêu cầu về độ trễ, khác với Scalability là yêu cầu về throughput.

5. Compliance – 4 NFRs: Gồm 2 NFRs về Data Governance và 2 NFRs về Platform Compliance. Đảm bảo hệ thống tuân thủ quy định và chính sách của các platforms.

6. Architecture Quality – 4 NFRs: Gồm các yêu cầu về Maintainability, Deployability, Testability, và Observability. Đây là các yêu cầu về khả năng bảo trì và vận hành lâu dài của hệ thống.

#context (align(center)[_Bảng #table_counter.display(): Architecture Characteristics (7 ACs chính)_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (0.08fr, 0.20fr, 0.16fr, 0.27fr, 0.30fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),

    table.header(
      table.cell(align: center + horizon, inset: 0.7em)[*AC*], [*Characteristic*], [*Priority*], [*Metrics*], [*Target*]
    ),

    [AC-1], [Modularity],
    table.cell(rowspan: 3, [*Primary*]),
    // Gộp 3 dòng Primary
    [Coupling index, Efferent coupling],
    table.cell(align: left + horizon, inset: 0.6em)[I ≈ 0, Ce < 5, ≤ 3 deps/service],

    [AC-2], [Scalability], [Workers, throughput],
    table.cell(align: left + horizon, inset: 0.6em)[Scale 2-20 workers < 5 min, 1,000 items/min],
    [AC-3], [Performance], [Response time],
    table.cell(align: left + horizon, inset: 0.6em)[API < 500ms (p95), Dashboard < 2s, NLP < 700ms],

    [AC-4], [Testability],
    table.cell(rowspan: 4, [*Secondary*]),
    // Gộp 4 dòng Secondary
    [Coverage, tests],
    table.cell(align: left + horizon, inset: 0.6em)[Coverage ≥ 80%, ≥ 100 tests/service],

    [AC-5], [Deployability], [Deploy time],
    table.cell(align: left + horizon, inset: 0.6em)[Deploy < 5 min, rollback < 5 min, downtime < 30s],
    [AC-6], [Maintainability], [Breaking changes],
    table.cell(align: left + horizon, inset: 0.6em)[Zero breaking changes, 100% backward compat],
    [AC-7], [Observability], [Log/metrics coverage],
    table.cell(align: left + horizon, inset: 0.6em)[100% errors logged, alert < 5 min],
  )
]

Cách phân loại NFRs:

- Scalability bao gồm cả Throughput và Resource Utilization từ mục 4.3.2.1, vì khả năng tối ưu tài nguyên và xử lý throughput cao là nền tảng để scale hệ thống. Đây là lý do Microservices được chọn như phân tích ở mục 5.2.1.

- Performance chỉ tập trung vào Response Time - yêu cầu về độ trễ thấp cho trải nghiệm người dùng, khác với Scalability là yêu cầu về throughput và capacity.

- Architecture Quality gộp AC-4, AC-5, AC-6, AC-7 vì đều liên quan đến khả năng bảo trì và vận hành dài hạn của hệ thống.

Primary Architecture Characteristics:

- AC-1 (Modularity) là Primary AC nhưng không xuất hiện như một "nhóm NFRs" riêng vì đây là một đặc tính kiến trúc cấu trúc thay vì yêu cầu đo lường được. Modularity được thể hiện qua quyết định kiến trúc - việc chọn Microservices architecture với các services độc lập chính là cách đáp ứng AC-1. Metrics của AC-1 như Coupling index I ≈ 0 và Ce < 5 sẽ được đo tại mức architecture.

- Modularity đóng vai trò tiên quyết: chỉ khi có Modularity (microservices) thì mới có thể đạt được Scalability (scale từng service độc lập) và Performance (tối ưu từng service riêng).

Các Architecture Characteristics sẽ được phân tích đánh đổi về các quyết định kiến trúc (ADRs) và hiện thực chứng minh ở mục 5.6 (Traceability Matrix).

=== 5.1.1 Nguyên tắc thiết kế

Để đảm bảo hệ thống SMAP đáp ứng hiệu quả các yêu cầu phi chức năng về hiệu năng và khả năng mở rộng, kiến trúc hệ thống tuân thủ 8 nguyên tắc thiết kế cốt lõi, được tổ chức thành 4 nhóm chính. Các nguyên tắc này được triển khai theo thứ tự từ tầm nhìn chiến lược (Strategic Design), định hình kiến trúc tổng thể (Architectural Style) đến các mẫu thiết kế kỹ thuật cụ thể (Tactical Patterns).

#table(
  columns: (0.4fr, 0.6fr),
  align: (left, left),
  stroke: 0.5pt,
  table.cell(align: center + horizon, inset: (y: 0.8em))[*Nhóm*],
  table.cell(align: center + horizon, inset: (y: 0.8em))[*Nguyên tắc thiết kế*],

  table.cell(align: center + horizon, inset: (y: 0.8em))[Core Principles],
  table.cell(align: horizon, inset: (y: 0.8em))[
    (1) Domain-Driven Design (DDD) \
    (2) Microservices Architecture \
    (3) Event-Driven Architecture
  ],

  table.cell(align: center + horizon, inset: (y: 0.8em))[Data Patterns],
  table.cell(align: horizon, inset: (y: 0.8em))[
    (4) Claim Check Pattern \
    (5) Distributed State Management
  ],

  table.cell(align: center + horizon, inset: (y: 0.8em))[Code Quality],
  table.cell(align: horizon, inset: (y: 0.8em))[
    (6) SOLID Principles \
    (7) Port and Adapter Pattern
  ],

  table.cell(align: center + horizon, inset: (y: 0.8em))[Observability],
  table.cell(align: horizon, inset: (y: 0.8em))[
    (8) Observability-Driven Development
  ],
)

==== 5.1.1.1 Domain-Driven Design

Hệ thống phân tích mạng xã hội SMAP là một domain phức tạp với nhiều khái niệm nghiệp vụ chồng chéo: "User" có thể là tài khoản đăng nhập trong Identity hoặc tác giả bài viết trong Analytics, "Project" có thể là cấu hình theo dõi hoặc job xử lý dữ liệu. Nếu thiết kế theo hướng database-first, hệ thống sẽ gặp 3 vấn đề chính:

- Cùng một thuật ngữ, nhưng có ý nghĩa khác nhau giữa các module, dẫn đến confusion trong development và maintenance.
- Logic nghiệp vụ bị ràng buộc chặt với cấu trúc database, khó thay đổi khi requirements thay đổi.
- Không thể scale độc lập các phần khác nhau của hệ thống vì chúng phụ thuộc lẫn nhau.

Các vấn đề này liên quan trực tiếp đến AC-1 về tính mô-đun hóa và AC-6 về khả năng bảo trì dài hạn của hệ thống.

Domain-Driven Design (DDD) - Thiết kế hướng miền nghiệp vụ, là một phương pháp tiếp cận thiết kế phần mềm tập trung vào việc mô hình hóa nghiệp vụ thay vì phụ thuộc vào kỹ thuật. DDD chia hệ thống thành các Bounded Context - Ngữ cảnh giới hạn - mỗi context là một phạm vi trong đó các thuật ngữ nghiệp vụ được mô tả, sử dụng một cách nhất quán. Các Bounded Context được phân loại thành 3 loại:

- Core Domain: Đại diện cho các nghiệp vụ trọng tâm của hệ thống, nơi tạo ra giá trị cốt lõi và lợi thế cạnh tranh khác biệt. Các chức năng trong Core Domain cần được thiết kế và tối ưu kỹ lưỡng vì chúng trực tiếp quyết định chất lượng và hiệu quả của hệ thống (ví dụ: phân tích nội dung mạng xã hội, thu thập và xử lý dữ liệu).
- Supporting Domain: Bao gồm các nghiệp vụ có vai trò hỗ trợ cho Core Domain trong quá trình vận hành hệ thống, nhưng không phải là yếu tố tạo nên sự khác biệt chính. Các domain này vẫn cần được thiết kế phù hợp để đảm bảo hệ thống hoạt động trơn tru (ví dụ: quản lý dự án, quản lý cấu hình).
- Generic Domain: Gồm các chức năng mang tính phổ biến, ít phụ thuộc vào đặc thù nghiệp vụ của hệ thống và thường đã có các giải pháp tiêu chuẩn sẵn có. Do đó, các domain này có thể tái sử dụng hoặc tích hợp từ các công cụ, framework bên ngoài thay vì tự xây dựng từ đầu (ví dụ: quản lý định danh và phân quyền người dùng).

Hệ thống SMAP được chia thành 5 Bounded Contexts dựa trên phân tích domain:

#context (align(center)[_Bảng #table_counter.display(): Bounded Contexts của hệ thống SMAP_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (0.30fr, 0.20fr, 0.50fr),
    stroke: 0.5pt,
    align: (left + top, center + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Bounded Context*],
    table.cell(align: center + horizon)[*Loại Domain*],
    table.cell(align: center + horizon)[*Chức năng*],

    align(center + horizon)[Identity & \
      Access Management \
      (IAM)],
    table.cell(align: center + horizon)[Generic Domain],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Quản lý định danh, xác thực, cấp phát JWT tokens.\
    ],

    align(center + horizon)[Project Management],
    table.cell(align: center + horizon)[Supporting Domain],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Workspace để người dùng cấu hình projects, competitors, keywords.\
    ],

    align(center + horizon)[Data Collection],
    table.cell(align: center + horizon)[Core Domain],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Giao tiếp platforms bên ngoài (TikTok, YouTube, Facebook) để thu thập dữ liệu thô.\
    ],

    align(center + horizon)[Content Analysis],
    table.cell(align: center + horizon)[Core Domain],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Phân tích dữ liệu thô qua NLP pipeline (Intent, Sentiment, Impact).\
    ],

    align(center + horizon)[Business Intelligence \
      (BI)],
    table.cell(align: center + horizon)[Core Domain],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Tổng hợp, trực quan hóa dữ liệu, cảnh báo real-time.\
    ],
  )
]

// *Tài liệu tham khảo:* E. Evans, "Domain-Driven Design: Tackling Complexity in the Heart of Software", 2003.

==== 5.1.1.2 Microservices Architecture

Kiến trúc Monolithic truyền thống gặp 3 vấn đề chính khi xử lý workload lớn và đa dạng như SMAP:

- Tight Coupling: Tất cả modules trong cùng một process, lỗi ở một module có thể crash toàn bộ hệ thống.
- Crawler là IO-bound và Analytics là CPU-bound có yêu cầu tài nguyên khác nhau nhưng phải chạy cùng một instance, không thể tối ưu riêng.
- Không thể scale từng phần độc lập - phải scale toàn bộ monolith, dẫn đến lãng phí tài nguyên.

Vấn đề này liên quan trực tiếp đến AC-2 về Scalability - yêu cầu scale 2-20 workers trong vòng 5 phút và xử lý 1,000 items/phút, cùng AC-3 về Performance - tối ưu response time cho từng service riêng.

Microservices Architecture chia hệ thống thành các services nhỏ, độc lập, mỗi service:
- Có database riêng theo nguyên tắc Decentralized Data Management
- Có thể deploy độc lập với minimal downtime, đáp ứng AC-5 về Deployability
- Có thể scale độc lập dựa trên workload
- Có thể chọn technology stack phù hợp theo đặc thù công việc

Các services giao tiếp qua well-defined APIs hoặc events, đảm bảo loose coupling.

#context (align(center)[_Bảng #table_counter.display(): Danh sách các Microservices của hệ thống SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.1fr, 0.25fr, 0.35fr, 0.3fr),
    stroke: 0.5pt,
    align: (center, left, left, left),

    // Header
    table.cell(align: center + horizon, inset: (y: 0.8em))[*STT*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tên Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Chức năng chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý xác thực, cấp phát JWT, quản lý tài khoản],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, PostgreSQL],

    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý dự án: CRUD, trạng thái thực thi, orchestration],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, PostgreSQL, \ Redis],

    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Dispatch job thu thập dữ liệu & tracking tiến độ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, MongoDB, \ Redis],

    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Giao tiếp realtime, truyền phát trạng thái hệ thống],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, Redis Pub/Sub],

    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scrapper Services],
    table.cell(align: horizon, inset: (y: 0.8em))[Thu thập dữ liệu thô từ các nền tảng mạng xã hội],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, Playwright],

    table.cell(align: center + horizon, inset: (y: 0.8em))[6],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FFmpeg Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Xử lý media: tải xuống, chuyển đổi audio/video dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, FFmpeg],

    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Playwright Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Tự động hóa browser, crawling nâng cao dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, Playwright],

    table.cell(align: center + horizon, inset: (y: 0.8em))[8],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Pipeline NLP: phân tích Intent, Sentiment, Impact, xử lý batch dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, PostgreSQL, \ MinIO],

    table.cell(align: center + horizon, inset: (y: 0.8em))[9],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Speech2Text Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Chuyển đổi audio sang transcript (Whisper)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, MinIO],

    table.cell(align: center + horizon, inset: (y: 0.8em))[10],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web UI (Next.js 15)],
    table.cell(align: horizon, inset: (y: 0.8em))[Dashboard quản trị, cấu hình dự án, realtime view],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js (Frontend)],
  )
]

Lợi ích đạt được:

- Crawler là IO-bound scale 2-20 workers, Analytics là CPU-bound scale 1-10 workers độc lập, xử lý 1,000 items/phút với 10 workers, đáp ứng AC-2
- Lỗi ở Analytics không ảnh hưởng đến Identity hoặc Project
- Go cho high-concurrency APIs, Python cho ML/AI workloads
- Tối ưu CPU cho Analytics, Memory cho Crawler riêng biệt

// Tài liệu tham khảo: M. Fowler, "Microservices: a definition of this new architectural term", 2014.

==== 5.1.1.3 Event-Driven Architecture

Trong kiến trúc Microservices, nếu sử dụng synchronous communication - tức là giao tiếp qua REST API calls, hệ thống gặp 3 vấn đề:

- Back-pressure - khi Analytics Service xử lý chậm, Collector Service phải đợi response, dẫn đến blocking và giảm throughput, vô tình đẩy network latency lên cao.
- Services phải biết địa chỉ và trạng thái của nhau, có các cơ chế như polling để biết trạng thái của nhau, dẫn tới khó scale và maintain, dẫn đến Tight Coupling.
- Availability Issues - nếu Analytics Service down, Collector Service không thể gửi dữ liệu, dẫn đến data loss và phải buộc có boiler code để handle retry logic.

Vấn đề này đặc biệt nghiêm trọng với SMAP vì:
- Crawler thu thập dữ liệu liên tục với high throughput
- Analytics xử lý chậm với NLP pipeline ~700ms/item - chức năng phân tích Intent, Sentiment, Impact
- Cần xử lý bất đồng bộ để đảm bảo không mất dữ liệu

Vấn đề liên quan đến AC-3 về Performance - yêu cầu xử lý bất đồng bộ để đạt throughput cao, và AC-2 về Scalability - scale consumers độc lập.

Event-Driven Architecture sử dụng Message Broker làm trung gian, cho phép:
- Producer gửi event và không cần đợi consumer xử lý xong, hoạt động bất đồng bộ.
- Decoupling - Services không cần biết địa chỉ của nhau, chỉ cần biết routing key.
- Resilience - Events được lưu trong queue, consumer có thể xử lý sau khi recover.
- Scalability - Nhiều consumers có thể xử lý cùng một event type, tự động load balancing.

// Tài liệu tham khảo: G. Hohpe & B. Woolf, "Enterprise Integration Patterns", 2003.

==== 5.1.1.4 Claim Check Pattern

Khi Scrapper Service gửi dữ liệu crawled tới Analytics Service qua RabbitMQ, nếu gửi toàn bộ payload (50 posts × ~10KB mỗi post = ~500KB per message), hệ thống gặp 3 vấn đề:

- Message Queue Overload - RabbitMQ phải xử lý messages lớn, làm chậm broker và giảm throughput.
- Network Bandwidth Waste - Dữ liệu được transfer nhiều lần (Producer → Queue → Consumer), lãng phí bandwidth.
- Message Size Limits - RabbitMQ có giới hạn message size (mặc định 128MB), nhưng messages lớn làm chậm broker đáng kể.

Tuy nhiên nếu gửi message đơn lẻ (1 message/item), thì queue sẽ bị quá tải và độ trễ tăng cao, không đáp ứng AC-3 (Performance) - yêu cầu tối ưu throughput và giảm độ trễ cho message processing.

Vấn đề này liên quan đến AC-3 (Performance) - yêu cầu tối ưu throughput và giảm độ trễ cho message processing.

Claim Check Pattern tách payload lớn khỏi message:
- Payload Storage: Dữ liệu thô được lưu vào Object Storage (MinIO/S3) với unique path
- Claim Check: Message chỉ chứa reference (path/URL) đến payload, không chứa dữ liệu thô
- Retrieval: Consumer đọc claim check từ message, sau đó fetch payload từ Object Storage

Lợi ích đạt được:
- Giảm tải cho hàng đợi - Từ 50,000 messages đơn lẻ giảm xuống còn 1,000 batch references (50 items/batch)
- Kích thước mỗi message được giảm nhỏ
- Throughput tăng đáng kể, Queue processing nhanh hơn 50x (vì messages nhỏ hơn)

==== 5.1.1.5 Distributed State Management

Trong kiến trúc Microservices phân tán, không có orchestrator trung tâm để theo dõi tiến độ xử lý của một project qua nhiều services (Collector, Analytics, Scrapper). Mỗi service chỉ biết về phần việc của mình, dẫn đến 3 vấn đề chính:

- Dashboard không thể hiển thị tiến độ real-time chính xác vì mỗi service có state riêng, không có nguồn dữ liệu tập trung.
- Duplicate work - Khi service restart, không biết đã xử lý tới đâu, dẫn đến có thể xử lý lại.
- No progress tracking - user không biết project đang ở stage nào, phần trăm hoàn thành bao nhiêu, dẫn đến poor UX và không đáp ứng NFR-UX-6 (Real-time progress indicators).

Vấn đề này liên quan trực tiếp đến AC-3 về Performance - yêu cầu response time cho WebSocket updates < 100ms (p95), và NFR-UX-6 về Real-time progress indicators. Với Redis làm Single Source of Truth, WebSocket Service có thể đọc state và broadcast updates < 100ms, đáp ứng yêu cầu AC-3.

Distributed State Management sử dụng Redis làm "Single Source of Truth" (SSOT) để tập trung hóa trạng thái project. Tất cả services đều read/write vào cùng một Redis instance, đảm bảo:

- Centralized State - Một nguồn duy nhất cho project state, tất cả services đọc từ đây
- Atomic Updates - Redis HASH operations (HINCRBY, HSET) đảm bảo consistency

Lợi ích đạt được:

- Resource efficiency - Tránh duplicate work khi service restart

==== 5.1.1.6 SOLID Principles

Ở cấp độ implementation, code không tuân thủ SOLID principles dẫn đến 3 vấn đề:

- Tight Coupling - Classes phụ thuộc chặt vào concrete implementations, khó thay đổi và test.
- Low Testability - Không thể mock dependencies, phải test với real database/APIs, chậm và không reliable.
- Poor Maintainability - Thay đổi một phần code ảnh hưởng đến nhiều phần khác, dễ introduce bugs.

Vấn đề này liên quan đến AC-4 (Testability) - yêu cầu coverage ≥ 80%, ≥ 100 tests/service (mục 4.3.1), và AC-6 (Maintainability) - zero breaking changes, 100% backward compatibility.

SOLID principles là 5 nguyên tắc thiết kế hướng đối tượng:
- S - Single Responsibility: Mỗi class chỉ có một lý do để thay đổi
- O - Open/Closed: Mở rộng thông qua inheritance/interface, đóng với modification
- L - Liskov Substitution: Subtypes phải thay thế được base types
- I - Interface Segregation: Interfaces nhỏ, focused, không yêu cầu thực thi các hàm không sử dụng
- D - Dependency Inversion: Phụ thuộc vào abstractions, không phải implementations

Kết hợp với Clean Architecture (3-layer pattern: Delivery → UseCase → Repository), SOLID đảm bảo code dễ test, dễ maintain, dễ extend.

Lợi ích đạt được:

- Testability - Có thể viết unit test bao phủ phần lớn logic nghiệp vụ và sử dụng mock cho các interface phụ thuộc.
- Maintainability - hạn chế tối đa các thay đổi phá vỡ tương thích, đảm bảo hệ thống ổn định và dễ dàng mở rộng trong quá trình vận hành.

==== 5.1.1.7 Port and Adapter Pattern

Khi business logic bị gắn chặt với infrastructure (database, external APIs, message broker), hệ thống gặp 3 vấn đề:

- Technology Lock-in, tức là khó thay đổi công nghệ (ví dụ: PostgreSQL sang MongoDB) vì business logic phụ thuộc vào SQL queries.
- Không thể test business logic độc lập, phải setup database/APIs, chậm và không tin cậy.
- Thay đổi vendor (ví dụ: Whisper sang Google Speech-to-Text) yêu cầu tái cấu trúc toàn bộ code.

Vấn đề này liên quan đến AC-4 (Testability) - yêu cầu coverage ≥ 80% với unit tests, và AC-6 (Maintainability) - linh hoạt để thay đổi technology stack.

Port and Adapter Pattern (Hexagonal Architecture) tách biệt business logic khỏi infrastructure:

- Ports (Interfaces): Định nghĩa "giao diện giao tiếp" mà business logic cần
- Adapters (Implementations): Cung cấp triển khai cụ thể cho từng technology

Business logic chỉ phụ thuộc vào Ports (abstractions), không phụ thuộc vào Adapters (concretions). Điều này cho phép:
- Thay đổi công nghệ mà không thay đổi business logic
- Mock Ports trong unit tests
- Test business logic độc lập với infrastructure

Lợi ích đạt được:

- Testability - Unit tests với mock Ports
- Flexibility - Thay đổi công nghệ nhanh, chỉ implement Adapter mới
- Code quality - Business logic không có infrastructure dependencies

==== 5.1.1.8 Observability-Driven Development

Trong hệ thống phân tán (Microservices), nếu không có observability từ đầu, việc debug và monitor gặp 3 vấn đề nghiêm trọng:

- Khó khăn trong việc debug - khi lỗi xảy ra, không biết request đi qua services nào, mất bao lâu, fail ở đâu. Phải check logs của nhiều services, mất hàng giờ để tìm root cause.
- Không có công cụ giám sát hiệu năng - không biết service nào là bottleneck, không có metrics để optimize. Response time chậm nhưng không biết nguyên nhân.
- Giám sát bị động - chỉ phát hiện vấn đề khi users report, có thể dẫn tới system có thể down hàng giờ mà không biết.

Vấn đề này đặc biệt nghiêm trọng với SMAP vì:
- Nhiều services phân tán, request đi qua nhiều services
- Async processing qua RabbitMQ, khó truy vết flow

Vấn đề liên quan đến AC-7 (Observability) - yêu cầu 100% errors logged, alert < 5 min (mục 4.3.1), và NFR-MON-1 - Metrics cho tất cả critical operations (mục 4.3.2.3).

Observability-Driven Development đặt observability lên hàng đầu ngay từ thiết kế. Mọi service phải xuất ra 3 loại telemetry data:

- Logs: ghi lại events, errors với structured format (JSON), bao gồm user_id, context.
- Metrics: đo lường performance (latency, throughput, error rate) với counters, histograms, gauges.

Kết hợp với Health Checks (liveness + readiness), hệ thống có thể:
- Monitor performance real-time với metrics
- Proactive alerting khi có issues
- Tối ưu bottlenecks dựa trên data

Lợi ích đạt được:

- Debug time giảm - từ không thể dự đoán xuống còn dưới 5 phút
- Error coverage - 100% errors logged với context

Lưu ý về Security và Compliance:

Các yêu cầu về Security (7 NFRs) và Compliance (4 NFRs) được thống nhất, mô tả thông qua các quyết định kiến trúc cụ thể ở các mục sau:

- Security: Authentication & Authorization được thực thi trong Identity Service với JWT và HttpOnly cookies. Data Protection với TLS 1.3 và AES-256 encryption được áp dụng ở infrastructure level.

- Compliance: Data Governance (Right to Access, Right to Delete) được thực thi qua API endpoints trong Project Service và Identity Service. Platform Compliance (Rate limit, Terms of Service) được áp dụng trong Collector Service và Scrapper Services.

Bảng dưới đây thể hiện mối liên hệ giữa từng nguyên tắc, ảnh hưởng của từng nguyên tắc tới việc kiến tạo, kiến thiết kiến trúc cho hệ thống SMAP:

#context (align(center)[_Bảng #table_counter.display(): Liên hệ nguyên tắc thiết kế_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.20fr, 0.25fr, 0.40fr),
    stroke: 0.5pt,
    align: (center, center, center, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nguyên tắc*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phạm vi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đóng góp*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[DDD],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Toàn hệ thống],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Maintainability, Understandability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xác định ranh giới nghiệp vụ],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Microservices],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kiến trúc vật lý],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scalability, Fault Tolerance],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scale độc lập từng service],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Event-Driven],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao tiếp liên dịch vụ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Performance, Decoupling],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý bất đồng bộ qua RabbitMQ],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Claim Check],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý dữ liệu lớn],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Performance, Efficiency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tối ưu băng thông Message Queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Distributed State],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Quản lý trạng thái],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Consistency, \ Real-time],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis SSOT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SOLID],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Source code],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Testability, Maintainability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Clean Architecture],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Port \& \ Adapter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Component design],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Flexibility, Testability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Technology swapping],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Observability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Monitoring & \ Debugging],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Observability, Debuggability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Logs, Metrics, Traces],
  )
]

=== 5.1.2 C4 Model

Bằng cách sử dụng C4 Model, nội dung sau của chương mô tả kiến trúc hệ thống SMAP theo bốn cấp độ chi tiết tăng dần, từ tổng quan đến chi tiết triển khai.

#context (align(center)[_Bảng #table_counter.display(): Tóm tắt phạm vi biểu đồ C4_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.1fr, 0.3fr, 0.28fr, 0.27fr, 0.20fr),
    stroke: 0.5pt,
    align: (center, center, center, center, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Level*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tên biểu đồ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phạm vi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả kỹ thuật*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đối tượng*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[System Context],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Toàn bộ hệ sinh thái dự án],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thấp],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business Stakeholders, PM],

    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Container Diagram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Toàn hệ thống SMAP],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Trung bình],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Architects, Lead Developers],

    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Component Diagram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Service cụ thể],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Cao],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Developers],

    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ERD / Class Diagram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database / Module],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Rất cao],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Developers, DBAs],
  )
]
