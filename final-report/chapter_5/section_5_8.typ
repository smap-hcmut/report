// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.8 Truy xuất nguồn gốc và xác thực thiết kế

Các mục trước đã trình bày kiến trúc hệ thống SMAP từ nguyên tắc thiết kế, kiến trúc tổng thể, thiết kế thành phần, dữ liệu, giao tiếp và triển khai. Mục này tổng hợp mối liên hệ giữa các yêu cầu ở Chương 4 với những quyết định thiết kế đã trình bày ở Chương 5, đồng thời chỉ ra các khoảng trống và các đánh đổi kiến trúc còn cần được lưu ý.

=== 5.8.1 Ma trận truy xuất nguồn gốc

Phần này liên hệ các yêu cầu chức năng, đặc tính kiến trúc và yêu cầu phi chức năng của Chương 4 với các mục thiết kế tương ứng trong Chương 5. Mục tiêu không phải là lặp lại chi tiết hiện thực, mà là chỉ ra mỗi yêu cầu đã được phản ánh ở đâu trong kiến trúc và vì sao các quyết định đó phù hợp với phạm vi hệ thống.

==== 5.8.1.1 Truy xuất yêu cầu chức năng

Bảng dưới đây liên hệ các yêu cầu chức năng ở mục 4.2 với các use case chính, các service chịu trách nhiệm và các mục thiết kế liên quan trong Chương 5.

#context (align(center)[_Bảng #table_counter.display(): Ma trận truy xuất yêu cầu chức năng_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.10fr, 0.23fr, 0.18fr, 0.22fr, 0.27fr),
    stroke: 0.5pt,
    align: (center, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*FR*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Liên hệ Use Case*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục thiết kế liên quan*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-01],
    table.cell(align: horizon, inset: (y: 0.8em))[Xác thực người dùng],
    table.cell(align: horizon, inset: (y: 0.8em))[Supporting concern],
    table.cell(align: horizon, inset: (y: 0.8em))[identity-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.1, 5.3.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-02],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý campaign và project],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[project-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.3.6, 5.5.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-03],
    table.cell(align: horizon, inset: (y: 0.8em))[Điều khiển vòng đời project],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-02],
    table.cell(align: horizon, inset: (y: 0.8em))[project-srv, ingest-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.3.4, 5.3.6, 5.5.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-04],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý cấu hình cảnh báo khủng hoảng],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-05],
    table.cell(align: horizon, inset: (y: 0.8em))[project-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.3, 5.3.6, 5.5.5],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-05],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý nguồn dữ liệu],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[ingest-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.4, 5.3.6, 5.5.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-06],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý mục tiêu thu thập],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[ingest-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.4, 5.3.6, 5.5.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-07],
    table.cell(align: horizon, inset: (y: 0.8em))[Kiểm tra thử đầu vào],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[ingest-srv, project-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.4, 5.3.3, 5.3.6, 5.5.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-08],
    table.cell(align: horizon, inset: (y: 0.8em))[Điều phối thu thập dữ liệu],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-02],
    table.cell(align: horizon, inset: (y: 0.8em))[ingest-srv, scapper-srv, analysis-srv],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.4, 5.3.8, 5.6.2, 5.5.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-09],
    table.cell(align: horizon, inset: (y: 0.8em))[Xử lý phân tích],
    table.cell(align: horizon, inset: (y: 0.8em))[Supporting concern],
    table.cell(align: horizon, inset: (y: 0.8em))[analysis-srv, ingest-srv, knowledge-srv],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.2, 5.3.4, 5.3.7, 5.6.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-10],
    table.cell(align: horizon, inset: (y: 0.8em))[Tra cứu và hỏi đáp dữ liệu],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-03],
    table.cell(align: horizon, inset: (y: 0.8em))[knowledge-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.7, 5.3.6, 5.5.3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-11],
    table.cell(align: horizon, inset: (y: 0.8em))[Gửi thông báo],
    table.cell(align: horizon, inset: (y: 0.8em))[UC-04],
    table.cell(align: horizon, inset: (y: 0.8em))[notification-srv, frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.5, 5.3.6, 5.6.3, 5.5.4],

    table.cell(align: center + horizon, inset: (y: 0.8em))[FR-12],
    table.cell(align: horizon, inset: (y: 0.8em))[Kiểm tra liên thông nội bộ],
    table.cell(align: horizon, inset: (y: 0.8em))[Supporting concern],
    table.cell(align: horizon, inset: (y: 0.8em))[identity-srv, project-srv, ingest-srv],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.1, 5.3.3, 5.6.1],
  )
]

Nhìn từ ma trận trên, có ba nhóm liên hệ chính:

- FR-01, FR-09 và FR-12 đóng vai trò supporting concern cho các use case được bảo vệ, đúng với cách Chương 4 đã tách các cơ chế xác thực, xử lý nền và kiểm tra liên thông khỏi mục tiêu nghiệp vụ của người dùng.
- FR-02 đến FR-08 chủ yếu gắn với hai mục tiêu nghiệp vụ đầu tiên là thiết lập và vận hành chiến dịch theo dõi, trong đó `project-srv`, `ingest-srv` và `scapper-srv` tạo thành trục business control plane kết hợp với execution plane.
- FR-10 và FR-11 gắn trực tiếp với các capability khai thác kết quả ở `knowledge-srv`, `notification-srv` và lớp giao diện người dùng.

==== 5.8.1.2 Truy xuất đặc tính kiến trúc

Bảng dưới đây liên hệ bảy đặc tính kiến trúc ở mục 4.3.1 với các quyết định thiết kế chính trong Chương 5.

#context (align(center)[_Bảng #table_counter.display(): Ma trận truy xuất đặc tính kiến trúc_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.10fr, 0.20fr, 0.42fr, 0.28fr),
    stroke: 0.5pt,
    align: (center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*AC*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đặc tính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Quyết định thiết kế chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục thiết kế liên quan*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-01],
    table.cell(align: horizon, inset: (y: 0.8em))[Modularity],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách bounded context theo identity, project, ingest, analytics, knowledge và notification; ownership dữ liệu và trách nhiệm được chia rõ theo service boundary],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.1, 5.2.2, 5.2.3, 5.3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-02],
    table.cell(align: horizon, inset: (y: 0.8em))[Scalability],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách lane đồng bộ và bất đồng bộ, tách pod theo vai trò API, consumer, scheduler và worker để hỗ trợ mở rộng theo workload],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.1, 5.6.1, 5.7.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-03],
    table.cell(align: horizon, inset: (y: 0.8em))[Performance],
    table.cell(align: horizon, inset: (y: 0.8em))[Giữ request path gọn ở control plane, đẩy xử lý nặng sang các lane nền và chọn runtime phù hợp theo loại workload],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.2, 5.2.4, 5.6.1],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-04],
    table.cell(align: horizon, inset: (y: 0.8em))[Security],
    table.cell(align: horizon, inset: (y: 0.8em))[Tổ chức security boundary riêng ở `identity-srv`, dùng JWT, session, cookie và internal validation để bảo vệ các capability nghiệp vụ],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.2.3, 5.3.1, 5.3.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-05],
    table.cell(align: horizon, inset: (y: 0.8em))[Availability],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng probe, tách workload theo lane và pod role, cùng các cơ chế khởi động lại hoặc triển khai lại phù hợp theo môi trường orchestration],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.6.4, 5.7.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-06],
    table.cell(align: horizon, inset: (y: 0.8em))[Data Integrity],
    table.cell(align: horizon, inset: (y: 0.8em))[Duy trì khóa tương quan, lineage metadata, outbox hoặc tracking tables để nối task, artifact và dữ liệu downstream một cách nhất quán],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.4, 5.6.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-07],
    table.cell(align: horizon, inset: (y: 0.8em))[Observability],
    table.cell(align: horizon, inset: (y: 0.8em))[Tổ chức logging có ngữ cảnh, probe endpoints, trace ID propagation và các chỉ báo vận hành ở những runtime quan trọng],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.6.4, 5.7.8],
  )
]

==== 5.8.1.3 Truy xuất yêu cầu phi chức năng

Bảng dưới đây liên hệ các yêu cầu phi chức năng ở mục 4.3.2 với các nhóm quyết định thiết kế tương ứng trong Chương 5.

#context (align(center)[_Bảng #table_counter.display(): Ma trận truy xuất yêu cầu phi chức năng_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.10fr, 0.18fr, 0.44fr, 0.28fr),
    stroke: 0.5pt,
    align: (center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nhóm*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phản hồi thiết kế*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục thiết kế liên quan*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-01],
    table.cell(align: horizon, inset: (y: 0.8em))[Performance],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách luồng xử lý nền khỏi request-response đồng bộ, dùng queue hoặc stream cho các lane analytics, ingest và indexing],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.2, 5.6.1, 5.6.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-02],
    table.cell(align: horizon, inset: (y: 0.8em))[Security],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng OAuth2, JWT, HttpOnly cookie, kiểm tra token và cơ chế xác thực nội bộ phù hợp với từng nhóm giao tiếp],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.3.1, 5.3.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-03],
    table.cell(align: horizon, inset: (y: 0.8em))[Availability],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách workload theo vai trò, bổ sung probe và cơ chế triển khai lại để hỗ trợ khôi phục khi lane xử lý gặp lỗi],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.6.4, 5.7.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-04],
    table.cell(align: horizon, inset: (y: 0.8em))[Scalability],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách pod theo vai trò API, consumer, scheduler và worker để hỗ trợ mở rộng theo lane thay vì mở rộng đồng loạt toàn hệ thống],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.2.4, 5.7.6],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-05],
    table.cell(align: horizon, inset: (y: 0.8em))[Data Integrity],
    table.cell(align: horizon, inset: (y: 0.8em))[Duy trì hợp đồng dữ liệu rõ ràng, tracking metadata, correlation key và raw artifact lineage giữa các thành phần bất đồng bộ],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.4, 5.6.2],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-06],
    table.cell(align: horizon, inset: (y: 0.8em))[Modularity],
    table.cell(align: horizon, inset: (y: 0.8em))[Tách service boundary, ownership dữ liệu và delivery layer khỏi business logic để hỗ trợ thay đổi, bảo trì và kiểm thử],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.1.2, 5.2.3, 5.3],

    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-07],
    table.cell(align: horizon, inset: (y: 0.8em))[Observability],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng logging có ngữ cảnh, trace ID propagation, health/readiness probes và chỉ báo vận hành cho các runtime quan trọng],
    table.cell(align: horizon, inset: (y: 0.8em))[Mục 5.6.4, 5.7.8],
  )
]

==== 5.8.1.4 Tổng hợp coverage

#context (align(center)[_Bảng #table_counter.display(): Tổng hợp coverage_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.34fr, 0.16fr, 0.18fr, 0.32fr),
    stroke: 0.5pt,
    align: (left, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tổng số*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đã liên hệ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục thiết kế liên quan*],

    table.cell(align: horizon, inset: (y: 0.8em))[Functional Requirements],
    table.cell(align: center + horizon, inset: (y: 0.8em))[12],
    table.cell(align: center + horizon, inset: (y: 0.8em))[12],
    table.cell(align: horizon, inset: (y: 0.8em))[5.3, 5.5, 5.6],

    table.cell(align: horizon, inset: (y: 0.8em))[Architecture Characteristics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: horizon, inset: (y: 0.8em))[5.1, 5.2, 5.4, 5.6, 5.7],

    table.cell(align: horizon, inset: (y: 0.8em))[Non-Functional Requirements],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: horizon, inset: (y: 0.8em))[5.1, 5.3, 5.4, 5.6, 5.7],
  )
]

Tổng cộng, 26 yêu cầu và đặc tính định hướng từ Chương 4 đã được liên hệ tới các mục thiết kế tương ứng trong Chương 5. Điều này cho thấy Chương 5 bám sát khung yêu cầu đã đặt ra, đồng thời vẫn giữ được sự phân tách giữa use case nghiệp vụ, supporting concern và các quyết định kỹ thuật nội bộ.

=== 5.8.2 Hồ sơ quyết định kiến trúc

Phần này ghi lại sáu quyết định kiến trúc quan trọng của hệ thống SMAP, cùng bối cảnh, lựa chọn thay thế và hệ quả chính của từng quyết định.

==== ADR-001: Kiến trúc Microservices theo bounded context

Bối cảnh: Hệ thống cần đồng thời hỗ trợ business context, execution plane, analytics pipeline, knowledge retrieval và notification delivery. Các nhóm tải và ranh giới trách nhiệm khác nhau đủ lớn để việc gộp mọi thứ vào một runtime duy nhất làm tăng coupling và blast radius.

Quyết định: Tổ chức SMAP theo kiến trúc microservices, tách các bounded context chính thành `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv` và `scapper-srv`.

Các lựa chọn đã xem xét:

- Monolithic Architecture: đơn giản hơn trong giai đoạn đầu nhưng khó tách workload và fault isolation.
- Modular Monolith: cải thiện tổ chức code nhưng vẫn không giải quyết triệt để polyglot runtime và deployment separation.
- Microservices Architecture: phù hợp hơn với nhiều lane xử lý có đặc tính khác nhau.

Hệ quả tích cực:

- Tách rõ ownership giữa security, business context, execution, analytics, retrieval và delivery.
- Cho phép triển khai và mở rộng các lane xử lý theo vai trò độc lập hơn.
- Giảm nguy cơ lỗi ở một lane lan sang toàn bộ hệ thống.

Hệ quả cần chấp nhận:

- Độ phức tạp vận hành cao hơn so với monolith.
- Cần quản lý giao tiếp liên service, cấu hình nhiều runtime và nhiều storage hơn.

Mục liên quan: 5.1.1, 5.2.1, 5.2.3.

==== ADR-002: Polyglot runtime với Go và Python

Bối cảnh: Các API và control plane cần runtime gọn nhẹ, concurrency tốt và chi phí bộ nhớ hợp lý, trong khi analytics hoặc crawl runtime cần hệ sinh thái thư viện dữ liệu và automation phong phú hơn.

Quyết định: Dùng Go cho các service nghiêng về API, control plane hoặc delivery như `identity-srv`, `project-srv`, `ingest-srv`, `knowledge-srv`, `notification-srv`; dùng Python cho `analysis-srv` và `scapper-srv` để phục vụ NLP pipeline và crawl runtime.

Các lựa chọn đã xem xét:

- All Go: thuận lợi cho thống nhất stack nhưng không phù hợp với hệ sinh thái NLP hiện có.
- All Python: thuận lợi cho thống nhất stack nhưng không tối ưu cho mọi lane control plane hoặc delivery.
- Polyglot Runtime: chọn runtime phù hợp theo loại workload.

Hệ quả tích cực:

- Mỗi lane xử lý có thể dùng công cụ phù hợp với nhiệm vụ chính.
- Các API services và runtime nền được tối ưu theo hai nhóm nhu cầu khác nhau.

Hệ quả cần chấp nhận:

- Tăng chi phí bảo trì do phải vận hành hai stack backend chính.
- Chia sẻ logic xuyên runtime cần dựa vào contract giao tiếp rõ ràng thay vì function call trực tiếp.

Mục liên quan: 5.2.4, 5.3.1 đến 5.3.8.

==== ADR-003: Chuyên biệt hóa cơ chế giao tiếp theo lane xử lý

Bối cảnh: Hệ thống không chỉ có một kiểu tương tác. Control plane cần phản hồi đồng bộ; crawl runtime cần task dispatch và completion correlation; analytics downstream cần event streaming; notification cần ingress nhẹ cho realtime delivery.

Quyết định: Không dùng một broker trung tâm cho toàn bộ hệ thống. Thay vào đó, internal HTTP được dùng cho control plane, RabbitMQ cho execution plane, Kafka cho analytics data plane và Redis Pub/Sub cho notification ingress.

Các lựa chọn đã xem xét:

- Chỉ dùng synchronous HTTP: đơn giản hơn nhưng không phù hợp với các tác vụ nền dài và các lane cần fanout.
- Dùng một broker chung cho mọi tương tác: thống nhất transport nhưng làm mờ semantics giữa các lane xử lý.
- Chuyên biệt hóa transport theo lane: phản ánh rõ hơn đặc tính workload.

Hệ quả tích cực:

- Mỗi lane xử lý dùng cơ chế giao tiếp phù hợp với vai trò của nó.
- Control plane, execution plane, analytics data plane và notification ingress được tách nghĩa rõ ràng hơn.

Hệ quả cần chấp nhận:

- Tăng độ phức tạp tích hợp vì hệ thống phải vận hành nhiều loại transport.
- Việc chẩn đoán liên lane đòi hỏi traceability tốt hơn ở message contract và logging.

Mục liên quan: 5.2.2, 5.6.1, 5.6.2, 5.6.3.

==== ADR-004: Polyglot persistence với PostgreSQL, Redis, MinIO và Qdrant

Bối cảnh: Hệ thống đồng thời cần dữ liệu quan hệ, state ngắn hạn, object artifact và vector retrieval. Một storage duy nhất không phù hợp cho toàn bộ các loại dữ liệu này.

Quyết định: Dùng PostgreSQL cho metadata và trạng thái nghiệp vụ, Redis cho cache hoặc state ngắn hạn, MinIO cho raw artifact và report artifact, Qdrant cho vector retrieval ở knowledge layer.

Các lựa chọn đã xem xét:

- Relational-first cho mọi dữ liệu: thuận lợi cho thống nhất query model nhưng không phù hợp với raw artifact và vector retrieval.
- Document-store-centric: linh hoạt cho payload lớn nhưng không tối ưu cho transaction-oriented business metadata.
- Specialized storage theo vai trò dữ liệu: cân bằng hơn giữa tính phù hợp và chi phí vận hành.

Hệ quả tích cực:

- Mỗi lớp dữ liệu được đặt vào storage model phù hợp hơn với retrieval pattern và vòng đời của nó.
- Giảm áp lực nhúng raw artifact hoặc vector payload vào relational model.

Hệ quả cần chấp nhận:

- Tăng chi phí vận hành vì phải quản lý nhiều loại storage.
- Quan hệ xuyên storage cần được nối ở application layer và qua metadata tracking.

Mục liên quan: 5.2.4, 5.4, 5.6.1.

==== ADR-005: Redis cho cache, state ngắn hạn và notification ingress

Bối cảnh: Hệ thống cần một lớp lưu trữ có độ trễ thấp cho session-related state, cache retrieval hoặc dashboard, và notification ingress theo channel pattern cho realtime delivery.

Quyết định: Sử dụng Redis như một thành phần đa vai trò cho cache, state ngắn hạn và Pub/Sub ingress ở notification lane.

Các lựa chọn đã xem xét:

- Dùng các hệ riêng cho cache, state và pub/sub: tăng độ tách biệt nhưng làm chi phí vận hành cao hơn.
- Dồn toàn bộ state ngắn hạn về relational storage: đơn giản hơn nhưng không phù hợp với đặc tính độ trễ thấp.
- Redis unified layer: phù hợp hơn với nhu cầu latency thấp và lightweight coordination.

Hệ quả tích cực:

- Hỗ trợ các lane cần cache hoặc realtime ingress bằng cùng một lớp hạ tầng quen thuộc.
- Giảm số lượng thành phần phụ trợ phải vận hành cho các nhu cầu latency-sensitive.

Hệ quả cần chấp nhận:

- Redis trở thành dependency quan trọng cho nhiều chức năng ngắn hạn.
- Một số lane cần chính sách fallback phù hợp khi Redis không sẵn sàng.

Mục liên quan: 5.2.4, 5.3.1, 5.3.7, 5.3.5, 5.6.3.

==== ADR-006: Kubernetes cho orchestration theo pod role

Bối cảnh: Hệ thống có nhiều workload khác nhau, trong đó một service có thể đồng thời có API pod, consumer pod, scheduler pod hoặc worker pod. Việc vận hành, rollout và scale sẽ khó tách bạch nếu mọi trách nhiệm bị gom vào cùng một deployment duy nhất.

Quyết định: Dùng Kubernetes để triển khai workload theo pod role, tách riêng API, scheduler, consumer và worker khi cần.

Các lựa chọn đã xem xét:

- Docker Compose: phù hợp cho local stack nhưng không đủ linh hoạt cho scale-by-role ở môi trường orchestration.
- Triển khai service-level mà không tách pod role: đơn giản hơn nhưng khó tối ưu vòng đời của từng workload.
- Kubernetes theo pod role: phù hợp hơn với các lane có tải và nhịp xử lý khác nhau.

Hệ quả tích cực:

- Hỗ trợ rollout, restart và scale độc lập hơn theo vai trò xử lý.
- Phù hợp với các probe, policy và dependency surface khác nhau giữa API pods và runtime pods.

Hệ quả cần chấp nhận:

- Tăng số lượng manifest và độ phức tạp vận hành.
- Cần quy ước triển khai rõ ràng để tránh drift giữa service boundary và pod role.

Mục liên quan: 5.2.4, 5.7.1, 5.7.6.

=== 5.8.3 Phân tích khoảng trống

Phần này tổng hợp một số khoảng trống kỹ thuật, hạn chế vận hành và các đánh đổi kiến trúc còn tồn tại trong phạm vi thiết kế hiện tại của SMAP.

==== 5.8.3.1 Khoảng trống kỹ thuật

#context (align(center)[_Bảng #table_counter.display(): Các khoảng trống kỹ thuật_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.36fr, 0.24fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Khoảng trống*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Giải pháp tạm thời*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ưu tiên*],

    table.cell(align: horizon, inset: (y: 0.8em))[Metrics surface đồng nhất],
    table.cell(align: horizon, inset: (y: 0.8em))[Không phải mọi runtime đều công bố cùng một surface metrics hoặc cùng một chuẩn observability],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng logging có ngữ cảnh, probe và metric instrumentation ở các lane quan trọng trước],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P1],

    table.cell(align: horizon, inset: (y: 0.8em))[Distributed tracing visualization],
    table.cell(align: horizon, inset: (y: 0.8em))[Hệ thống có trace ID propagation nhưng chưa có lớp hiển thị trace trực quan xuyên service],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng log correlation theo trace_id trong giai đoạn hiện tại],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Kênh thông báo bổ sung],
    table.cell(align: horizon, inset: (y: 0.8em))[Notification lane hiện tập trung vào WebSocket delivery và một số kênh ngoài trình duyệt như Discord; các kênh khác chưa phải capability chính],
    table.cell(align: horizon, inset: (y: 0.8em))[Ưu tiên realtime delivery và alert dispatch hiện có],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Maturity của workflow báo cáo],
    table.cell(align: horizon, inset: (y: 0.8em))[Knowledge-side report capability đã có nhưng workflow báo cáo và mẫu trình bày còn mang tính mở rộng, chưa phải trục năng lực cốt lõi của Chương 4],
    table.cell(align: horizon, inset: (y: 0.8em))[Giữ report capability ở vai trò mở rộng ngoài bộ use case cốt lõi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Mở rộng NLP đa ngôn ngữ],
    table.cell(align: horizon, inset: (y: 0.8em))[Analytics lane hiện thiên về mô hình và dữ liệu phục vụ tiếng Việt, chưa phải một pipeline đa ngôn ngữ đầy đủ],
    table.cell(align: horizon, inset: (y: 0.8em))[Giới hạn phạm vi phân tích theo miền và ngôn ngữ phù hợp với mô hình hiện hành],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P2],

    table.cell(align: horizon, inset: (y: 0.8em))[Ứng dụng di động native],
    table.cell(align: horizon, inset: (y: 0.8em))[Lớp giao diện hiện ưu tiên web và desktop packaging hơn là một mobile app native riêng],
    table.cell(align: horizon, inset: (y: 0.8em))[Tận dụng responsive web UI và desktop packaging khi cần],
    table.cell(align: center + horizon, inset: (y: 0.8em))[P3],
  )
]

==== 5.8.3.2 Hạn chế đã biết

#context (align(center)[_Bảng #table_counter.display(): Các hạn chế đã biết_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.24fr, 0.34fr, 0.42fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hạn chế*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nguyên nhân*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Giải pháp giảm thiểu*],

    table.cell(align: horizon, inset: (y: 0.8em))[Platform policies và rate limits],
    table.cell(align: horizon, inset: (y: 0.8em))[Khả năng crawl phụ thuộc vào chính sách, quota và thay đổi kỹ thuật từ các nền tảng bên ngoài],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng scheduling phù hợp, cache metadata, giảm tải không cần thiết và điều chỉnh lane crawl theo chính sách hiện hành],

    table.cell(align: horizon, inset: (y: 0.8em))[Độ ổn định của crawler],
    table.cell(align: horizon, inset: (y: 0.8em))[Các thay đổi ở giao diện hoặc contract của nền tảng bên ngoài có thể làm giảm độ ổn định của crawl runtime],
    table.cell(align: horizon, inset: (y: 0.8em))[Theo dõi lỗi runtime, tách worker pod và cho phép cập nhật lane crawl độc lập với control plane],

    table.cell(align: horizon, inset: (y: 0.8em))[Phạm vi ngôn ngữ của NLP],
    table.cell(align: horizon, inset: (y: 0.8em))[Các mô hình hiện hành được tối ưu theo phạm vi ngôn ngữ và miền dữ liệu nhất định],
    table.cell(align: horizon, inset: (y: 0.8em))[Giới hạn phạm vi phân tích, bổ sung human review ở các trường hợp nhạy cảm và mở rộng model khi cần],

    table.cell(align: horizon, inset: (y: 0.8em))[Độ trễ của cảnh báo],
    table.cell(align: horizon, inset: (y: 0.8em))[Realtime notification phụ thuộc vào cadence của ingest, analytics và notification lane; không phải mọi cảnh báo đều xuất hiện tức thời ở cấp mili-giây],
    table.cell(align: horizon, inset: (y: 0.8em))[Điều chỉnh chu kỳ xử lý, tách lane runtime và ưu tiên alert path khi workload yêu cầu],

    table.cell(align: horizon, inset: (y: 0.8em))[Tăng trưởng artifact và metadata],
    table.cell(align: horizon, inset: (y: 0.8em))[Raw artifact, report artifact và tracking metadata tăng theo thời gian vận hành và phạm vi campaign],
    table.cell(align: horizon, inset: (y: 0.8em))[Áp dụng retention policy, archive và lifecycle management phù hợp với môi trường triển khai],

    table.cell(align: horizon, inset: (y: 0.8em))[Độ phức tạp vận hành đa service],
    table.cell(align: horizon, inset: (y: 0.8em))[Nhiều runtime, nhiều storage và nhiều transport làm tăng chi phí vận hành so với kiến trúc đơn khối],
    table.cell(align: horizon, inset: (y: 0.8em))[Giữ ranh giới ownership rõ, chuẩn hóa contract giao tiếp và tách pod theo vai trò xử lý],
  )
]

Những hạn chế trên nên được hiểu như ràng buộc vận hành tự nhiên của bài toán và của kiến trúc đa lane, không phải như dấu hiệu cho thấy thiết kế tổng thể thiếu nhất quán.

==== 5.8.3.3 Đánh đổi kiến trúc có chủ đích

#context (align(center)[_Bảng #table_counter.display(): Các đánh đổi kiến trúc có chủ đích_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.24fr, 0.26fr, 0.22fr, 0.28fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đánh đổi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lựa chọn*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Từ bỏ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lý do*],

    table.cell(align: horizon, inset: (y: 0.8em))[Consistency vs Availability],
    table.cell(align: horizon, inset: (y: 0.8em))[Eventual consistency ở các lane bất đồng bộ],
    table.cell(align: horizon, inset: (y: 0.8em))[Strong consistency xuyên mọi lane],
    table.cell(align: horizon, inset: (y: 0.8em))[Task dispatch, analytics downstream và notification delivery cần tách khỏi request path để giảm coupling và giữ hệ thống linh hoạt hơn],

    table.cell(align: horizon, inset: (y: 0.8em))[Specialization vs Simplicity],
    table.cell(align: horizon, inset: (y: 0.8em))[Microservices, pod-role separation và polyglot runtime],
    table.cell(align: horizon, inset: (y: 0.8em))[Kiến trúc đơn khối đơn giản hơn],
    table.cell(align: horizon, inset: (y: 0.8em))[SMAP cần tách rõ business context, execution, analytics, retrieval và delivery theo workload specialization],

    table.cell(align: horizon, inset: (y: 0.8em))[Performance vs Operational Complexity],
    table.cell(align: horizon, inset: (y: 0.8em))[Dùng transport và storage chuyên biệt theo lane],
    table.cell(align: horizon, inset: (y: 0.8em))[Một stack đồng nhất dễ vận hành hơn],
    table.cell(align: horizon, inset: (y: 0.8em))[HTTP, RabbitMQ, Kafka, Redis Pub/Sub, PostgreSQL, MinIO và Qdrant được chọn để phù hợp hơn với từng loại dữ liệu và tương tác],

    table.cell(align: horizon, inset: (y: 0.8em))[Realtime vs Efficient Processing],
    table.cell(align: horizon, inset: (y: 0.8em))[Realtime delivery ở notification lane, bất đồng bộ ở các lane nền],
    table.cell(align: horizon, inset: (y: 0.8em))[Xử lý tức thời cho toàn bộ pipeline],
    table.cell(align: horizon, inset: (y: 0.8em))[Không phải mọi bước crawl, analytics hay indexing đều cần hoặc phù hợp với realtime end-to-end],

    table.cell(align: horizon, inset: (y: 0.8em))[Rich Lineage vs Storage Footprint],
    table.cell(align: horizon, inset: (y: 0.8em))[Giữ metadata tracking và artifact reference],
    table.cell(align: horizon, inset: (y: 0.8em))[Mô hình dữ liệu tối giản hơn],
    table.cell(align: horizon, inset: (y: 0.8em))[Hệ thống cần nối được task, completion, raw artifact, indexing state và report artifact để phục vụ vận hành và truy vết],
  )
]

=== Tổng kết

Mục 5.8 cho thấy các yêu cầu và đặc tính chất lượng của Chương 4 đều có điểm tựa rõ ràng trong thiết kế Chương 5. Các ma trận truy xuất nguồn gốc chỉ ra mối liên hệ giữa use case, service boundary, dữ liệu, giao tiếp và triển khai; các hồ sơ quyết định kiến trúc giải thích vì sao hệ thống được tổ chức theo nhiều lane và nhiều storage chuyên biệt; còn phần phân tích khoảng trống nêu rõ những khu vực vẫn cần được hoàn thiện thêm.

Vì vậy, mục này nên được đọc như một bước xác thực thiết kế ở cấp kiến trúc, chứ không phải như một tuyên bố rằng mọi mục tiêu vận hành đã được đo kiểm định lượng đầy đủ. Giá trị chính của phần này nằm ở chỗ nó giữ cho Chương 5 nhất quán với Chương 4, đồng thời làm rõ các giới hạn và đánh đổi mà hệ thống chấp nhận trong phạm vi hiện tại.

#pagebreak()
