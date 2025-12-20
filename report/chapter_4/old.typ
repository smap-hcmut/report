
// #import "chuong4.typ"
// File: chuong4.typ (Đã làm sạch và thêm viền cho tất cả các bảng)

// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

= CHƯƠNG 4: PHÂN TÍCH THIẾT KẾ

== 4.1 Nhu cầu người dùng hệ thống (User Story)

=== 4.1.1 Các bên liên quan & vai trò (Stakeholders & Roles)
#context (align(center)[_Bảng #table_counter.display(): Stakeholders & Roles_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
  columns: (auto, 1fr, 1fr),
  stroke: 0.5pt,
  [*Actor ID*], [*Actor (Tác nhân)*], [*Vai trò chính (Role)*],
  [A-01], [Marketing Analyst (nhà phân tích marketing)], [Người dùng cốt lõi, sử dụng SMAP để tìm kiếm thông tin chuyên sâu (insights), theo dõi đối thủ, và nắm bắt xu hướng thị trường.],
  [A-02], [Community Manager (quản lý cộng đồng)], [Người dùng cần theo dõi và phản ứng tức thời với các thảo luận trên mạng xã hội, đặc biệt là các tình huống khủng hoảng.],
  [A-03], [Client Viewer (khách hàng/người xem)], [Người dùng chỉ có quyền xem các Dashboard đã được chia sẻ, không có quyền chỉnh sửa hay cấu hình.],
  // [A-04], [System Administrator (Quản trị Hệ thống)], [Người dùng chịu trách nhiệm quản lý cấu hình hệ thống, bảo mật, vai trò người dùng (RBAC) và kiểm tra nhật ký (Audit Log).], [US-10 (System Administration)],
  [A-04], [Social Media Platform (Nền tảng mạng xã hội)], [Nguồn cung cấp dữ liệu bên ngoài data source (vd: Tiktok, Youtube, Facebook).],
)]


=== 4.1.2 User stories
#context (align(center)[_Bảng #table_counter.display(): User Stories_])
#table_counter.step()
#table(
  columns: (auto, auto, 1fr),
  stroke: 0.5pt,
  [*ID*], [*Actor*], [*Mô tả *],
  [US-01], [Marketing Analyst], [Là một nhà phân tích Marketing, tôi muốn xem dashboard các chủ đề thịnh hành theo thời gian thực, để tôi có thể nhanh chóng nắm bắt cơ hội và lên ý tưởng nội dung phù hợp.],
  [US-02], [Marketing Analyst], [Là một nhà phân tích Marketing, tôi muốn xem biểu đồ so sánh Share of Voice (SoV) giữa thương hiệu của tôi và các đối thủ, để tôi có thể đánh giá nhanh vị thế của thương hiệu trên thị trường.],
  [US-03], [Community Manager], [Là một quản lý cộng đồng, tôi muốn nhận cảnh báo tức thời qua Zalo/mail khi có thảo luận tiêu cực, để tôi có thể phản ứng và xử lý khủng hoảng ngay cả khi không ngồi trước máy tính.],
  [US-04], [Marketing Analyst], [Là một nhà phân tích Marketing, tôi muốn xuất báo cáo hiệu suất tháng dưới dạng PDF chỉ bằng một cú nhấp chuột, để tôi có thể tiết kiệm thời gian và gửi cho khách hàng một cách chuyên nghiệp.],
  [US-05], [Marketing Analyst], [Là một nhà phân tích Marketing, tôi muốn tìm kiếm KOC trong lĩnh vực ("Làm đẹp" có từ 10k-50k người theo dõi), để tôi có thể tìm được đối tác phù hợp với ngân sách chiến dịch nhỏ.],
  // [US-06], [Marketing Analyst], [Là một nhà phân tích Marketing, tôi muốn chia sẻ một dashboard chỉ đọc, có mật khẩu cho khách hàng, để họ có thể tự theo dõi hiệu suất một cách minh bạch mà không làm ảnh hưởng đến cấu hình của tôi.],
)


== 4.2 Yêu cầu chức năng (Functional Requirements)
#context (align(center)[_Bảng #table_counter.display(): Functional Requirements_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  [*ID*], [*Mô tả*],
  [FR-COL-1], [Hệ thống có khả năng khởi tạo các tác vụ thu thập dữ liệu (cào hoặc qua API) bất đồng bộ dựa trên các thông số truy vấn được truyền qua Message Queue (RabbitMQ).],
  [FR-COL-2], [Hệ thống nhận diện và loại bỏ các bài đăng trùng lặp (ví dụ: chia sẻ lại bài viết) dựa trên nội dung chính hoặc URL.],
  [FR-COL-3], [Dữ liệu thu thập từ các nền tảng khác nhau được chuyển đổi thành một schema chuẩn hóa thống nhất trước khi đưa vào phân tích.],
  [FR-AI-1], [Hệ thống phân tích một bài đăng để xác định Khía cạnh (VD: pin, giá, hiệu năng) và gán điểm cảm xúc riêng cho từng khía cạnh đó.],
  [FR-AI-2], [Hệ thống tự động phân cụm các bài đăng thành các chủ đề thảo luận (Topic Clusters) có ý nghĩa và gán nhãn cho chúng.],
  [FR-AI-3], [Hệ thống liên tục kiểm tra tốc độ tăng trưởng của các thảo luận tiêu cực để phát hiện sự tăng trưởng đột biến (spikes) vượt ngưỡng thống kê.],
  [FR-VISUAL-1], [Hệ thống hỗ trợ các truy vấn OLAP (Online Analytical Processing) để tính toán các chỉ số SoV và NSS dựa trên bộ lọc khía cạnh (Aspect).],
  [FR-VISUAL-2], [Cho phép người dùng tạo, chỉnh sửa và quản lý các dự án theo dõi bao gồm thương hiệu mục tiêu và danh sách đối thủ cạnh tranh.],
  [FR-NOTI-1], [Cung cấp giao diện và API để tạo, chỉnh sửa và kích hoạt các quy tắc cảnh báo dựa trên các ngưỡng Sentiment và Volume đã định.],
  [FR-NOTI-2], [Hệ thống có khả năng gửi cảnh báo tới các kênh ngoại vi (như Zalo/Email/SMS) sau khi nhận sự kiện từ dịch vụ AI/ML.],
)



== 4.3 Yêu cầu phi chức năng (Non-Functional Requirements)
#context (align(center)[_Bảng #table_counter.display(): Non-Functional Requirements_])
#table_counter.step()
// Bảng NFR đã được cập nhật với các yêu cầu mới
#text()[
  #set par(justify: false)
  #table(
    columns: (0.43fr, 2fr, 0.9fr),
    stroke: 0.5pt,
    
    // --- Hàng Tiêu Đề ---
    [*ID*], [*Mô tả*], [*Liên quan đến User Story*],

    // --- Scalability (Khả năng mở rộng) ---
    [NFR-SC1], [Hệ thống phải có khả năng xử lý và lưu trữ tối thiểu 500,000 bài đăng mới mỗi ngày với khả năng mở rộng theo chiều ngang (horizontal scaling).], [US-01, US-02, US-05],
    [NFR-SC2], [Kiến trúc Message Queue (RabbitMQ) phải hỗ trợ throughput tối thiểu 5,000 messages/giây trong giờ cao điểm.], [FR-COL-1, US-01],
    [NFR-SC3], [Database phải hỗ trợ auto-scaling và partitioning theo thời gian để xử lý lượng dữ liệu tăng trưởng 100% hàng năm.], [US-01, US-02, US-04],
    
    // --- Availability (Độ khả dụng) ---
    [NFR-A1], [Hệ thống phải đảm bảo Availability ≥ 99.5% (downtime tối đa ~3.65 giờ/tháng), không tính thời gian bảo trì đã lên lịch.], [US-01, US-02, US-03, US-06],
    [NFR-A2], [Hệ thống cảnh báo (Alert Service) phải có Availability ≥ 99.9% để đảm bảo không bỏ lỡ cảnh báo khủng hoảng.], [US-03, FR-NOTI-1, FR-NOTI-2],
    [NFR-A3], [Triển khai cơ chế Circuit Breaker cho các external API calls (TikTok, Facebook, YouTube) để tránh cascade failure.], [FR-COL-1, A-04],
    
    // --- Performance (Hiệu năng) ---
    [NFR-P1], [Thời gian phản hồi của Dashboard phải đạt p99 ≤ 500ms cho các truy vấn phức tạp (OLAP queries) với dataset 30 ngày gần nhất.], [US-01, US-02, FR-VISUAL-1],
    [NFR-P2], [API xuất báo cáo PDF phải hoàn thành trong p95 ≤ 5 giây cho báo cáo tháng (≤ 50 trang).], [US-04],
    [NFR-P3], [Chức năng tìm kiếm KOC phải trả về kết quả trong p95 ≤ 2 giây với bộ lọc phức tạp (nhiều tiêu chí đồng thời).], [US-05],
    
    // --- Reliability (Độ tin cậy) ---
    [NFR-R1], [Hệ thống phải có khả năng Auto-retry với exponential backoff cho các tác vụ thu thập dữ liệu thất bại (tối đa 3 lần retry).], [FR-COL-1],
    [NFR-R2], [Triển khai Health Check endpoints cho tất cả microservices với response time < 100ms.], [All US],
    
    // --- Maintainability (Khả năng bảo trì) ---
    [NFR-M1], [Mỗi microservice phải có CI/CD pipeline tự động với thời gian deployment < 15 phút từ commit đến production.], [All FR],
    [NFR-M2], [Codebase phải tuân thủ coding standards và tự động kiểm tra bằng linter/formatter (ESLint, Black, Prettier).], [All FR],
    [NFR-M3], [Tài liệu kiến trúc hệ thống (Architecture Decision Records - ADR) phải được cập nhật cho mọi quyết định thiết kế quan trọng, phù hợp với team size 2-5 developers.], [All FR],

    // --- Observability (Khả năng quan sát) ---
    [NFR-O1], [Cấu hình alerting rules cho các SLI chính: CPU > 80%, Memory > 85%, Error Rate > 1%, Queue Depth > 10,000 messages.], [All US],
    [NFR-O2], [Dashboard monitoring tổng quan (Grafana) phải hiển thị real-time metrics của tất cả services với độ trễ < 30 giây.], [US-01, FR-VISUAL-1],

    // --- Usability (Khả năng sử dụng) ---
    [NFR-U1], [Giao diện Dashboard phải đạt điểm Lighthouse Performance Score ≥ 85 và hỗ trợ responsive design cho mobile/tablet.], [US-01, US-02, US-06],
    [NFR-U2], [Hệ thống phải hỗ trợ i18n (internationalization) ít nhất 2 ngôn ngữ (Tiếng Việt, Tiếng Anh).], [US-06, A-03],
  )
]

== 4.4 Danh sách Use Case
#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()
#table(
  columns: (auto, 1fr, auto),
  stroke: 0.5pt,
  [*ID*], [*Tên Use Case*], [*Tác nhân*],
  [UC-01], [Khám phá xu hướng nội dung], [Marketing Analyst],
  [UC-02], [Thiết lập theo dõi đối thủ], [Marketing Analyst],
  [UC-03], [Quản lý cảnh báo khủng hoảng], [Community Manager],
  [UC-04], [Xuất báo cáo nhanh], [Marketing Analyst],
  [UC-05], [Tìm kiếm người ảnh hưởng], [Marketing Analyst],
  // [UC-06], [Chia sẻ Dashboard], [Marketing Analyst],
  // [UC-06], [Cấu hình phân tích dịp đặc biệt], [Marketing Analyst],
  // [UC-07], [Tạo phân khúc người tiêu dùng], [Marketing Analyst],
  // [UC-08], [Tích hợp dữ liệu khảo sát], [Marketing Analyst],
  // [UC-09], [Kết nối Nguồn dữ liệu], [Marketing Analyst],
  // [UC-10], [Xử lý Yêu cầu Dữ liệu Cá nhân (DSAR)], [System Administrator],
)




== 4.5 Đặc tả Use Case

=== Chi tiết Use Case UC-01: Khám phá Xu hướng Nội dung
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [Người dùng đã đăng nhập.],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Trend Dashboard".
    2. Người dùng nhập từ khóa, chọn bộ lọc (thời gian, nền tảng).
    3. Hệ thống hiển thị các chủ đề, hashtag và bài đăng mẫu.
    4. Người dùng xem chi tiết một bài đăng và lưu vào bộ sưu tập.
  ],
  [*Luồng thay thế:*], [2a. Người dùng chọn một ngành hàng có sẵn thay vì nhập từ khóa.],
  [*Luồng ngoại lệ:*], [3e. Không có dữ liệu phù hợp, hệ thống hiển thị trạng thái trống (204 No Content).],
  [*Hậu điều kiện:*], [Ý tưởng nội dung được lưu lại.],
  [*NFR Hooks:*], [TTI (NFR-P1), Query Latency (NFR-P2).],
  [*UI Mapping:*], [Màn hình: Trend Dashboard, Topic Detail.],
)]

=== Chi tiết Use Case UC-02: Thiết lập Theo dõi Đối thủ
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [Người dùng đã đăng nhập và có quyền Member.],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Project Setup" và chọn "Tạo mới".
    2. Người dùng nhập Tên dự án, thêm thương hiệu của mình và các đối thủ bằng từ khóa hoặc URL.
    3. Người dùng nhấn "Lưu".
    4. Hệ thống tạo dự án và bắt đầu job thu thập dữ liệu.
    5. Người dùng được chuyển đến màn hình "Compare Dashboard".
  ],
  [*Luồng thay thế:*], ["2a. Người dùng chọn ""Nhập từ CSV"" để thêm danh sách đối thủ hàng loạt."],
  [*Luồng ngoại lệ:*], [
    - 2e. Tên dự án bị trùng, hệ thống trả về lỗi 409 Conflict.
    - 2e. URL không hợp lệ, hệ thống trả về lỗi 422 Unprocessable Entity.
  ],
  [*Hậu điều kiện:*], [
    1. Dự án ở trạng thái "Active".
    2. Job thu thập dữ liệu được khởi chạy.
  ],
  [*NFR Hooks:*], ["Query Latency (NFR-P2), TTI (NFR-P1)."],
  [*UI Mapping:*], ["Màn hình: Project Setup, Compare Dashboard."],
)

=== Chi tiết Use Case UC-03: Quản lý Cảnh báo Khủng hoảng
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Community Manager],
  [*Tiền điều kiện:*], [
    1. Người dùng đã đăng nhập và có quyền Member.
    2. Đã có quy tắc cảnh báo được thiết lập.
  ],
  [*Luồng chính:*], [
    1. Hệ thống phát hiện một sự kiện khớp với quy tắc cảnh báo.
    2. Hệ thống gửi thông báo đến kênh đã cấu hình (Email/Zalo).
    3. Người dùng nhận thông báo, nhấp vào link để xem chi tiết trong "Alert Inbox".
    4. Người dùng nhấn "Acknowledge" để xác nhận đã tiếp nhận.
    5. Sau khi xử lý, người dùng nhấn "Dismiss" và thêm ghi chú.
  ],
  [*Luồng thay thế:*], ["5a. Người dùng nhấn ""Escalate"" để chuyển cảnh báo cho người quản lý."],
  [*Luồng ngoại lệ:*], [
    - 2e. Kênh thông báo (Zalo) chưa được kết nối, hệ thống trả về lỗi 412 Precondition Failed và ghi log.
    - 2e. Vượt ngưỡng rate-limit của kênh thông báo, hệ thống trả về lỗi 429 và thực hiện backoff.
  ],
  [*Hậu điều kiện:*], [Cảnh báo được xử lý và trạng thái được cập nhật. Hành động được ghi vào audit log.],
  [*NFR Hooks:*], ["Alert Latency (p95 ≤ 5 phút), Audit Log (ghi ≤ 2 giây), alert_fp_rate SLO ≤ 10%."],
  [*UI Mapping:*], ["Màn hình: Alert Rules, Alert Inbox, Alert Detail."],
)

=== Chi tiết Use Case UC-04: Xuất Báo cáo Nhanh
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [
    1. Người dùng đã đăng nhập.
    2. Đã có ít nhất một nguồn dữ liệu được kết nối.
  ],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Report Wizard".
    2. Người dùng chọn khoảng thời gian và mẫu báo cáo.
    3. Người dùng nhấn "Xem trước".
    4. Người dùng nhấn "Tạo báo cáo" (bất đồng bộ).
    5. Hệ thống xử lý và người dùng nhận được link tải xuống khi hoàn tất.
  ],
  [*Luồng thay thế:*], ["2a. Người dùng chọn ""Lưu mẫu tùy chỉnh"" để tái sử dụng cấu hình báo cáo."],
  [*Luồng ngoại lệ:*], [
    - 3e. Không có dữ liệu trong khoảng thời gian đã chọn, hệ thống trả về trạng thái trống (204 No Content).
    - 4e. Job render báo cáo bị lỗi, hệ thống trả về lỗi 503 Service Unavailable và cho phép thử lại.
  ],
  [*Hậu điều kiện:*], [
    1. Báo cáo được tạo.
    2. Hành động được ghi vào audit log.
  ],
  [*NFR Hooks:*], [Thời gian render p95 ≤ 60 giây, kích thước file ≤ 20MB.],
  [*UI Mapping:*], [Màn hình: Report Wizard, Report Preview.],
)

=== Chi tiết Use Case UC-05: Tìm kiếm người ảnh hưởng
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [Người dùng đã đăng nhập.],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "KOL Search".
    2. Người dùng áp dụng các bộ lọc (lĩnh vực, nền tảng, lượng người theo dõi).
    3. Người dùng xem danh sách kết quả và mở một hồ sơ chi tiết.
    4. Người dùng nhấn "Thêm vào danh sách" để lưu hồ sơ vào một danh sách tiềm năng.
  ],
  [*Luồng thay thế:*], [2a. Người dùng tìm kiếm trực tiếp theo tên hoặc handle của người ảnh hưởng.],
  [*Luồng ngoại lệ:*], ["3e. Không có kết quả phù hợp, hệ thống gợi ý nới lỏng bộ lọc."],
  [*Hậu điều kiện:*], [Danh sách người ảnh hưởng tiềm năng được lưu lại.],
  [*NFR Hooks:*], [Freshness dữ liệu ≤ 7 ngày (FR4.3).],
  [*UI Mapping:*], ["Màn hình: KOL Search, KOL Profile."],
)

=== Chi tiết Use Case UC-06: Cấu hình Phân tích Dịp đặc biệt
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [
    1. Người dùng đã đăng nhập và có quyền Member.
    2. Dự án đã có dữ liệu nền ít nhất 28 ngày.
  ],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Occasions Analysis" và chọn "Tạo mới".
    2. Người dùng nhập Tên sự kiện, chọn Khung thời gian và nhập các Từ khóa liên quan.
    3. Hệ thống hiển thị bản xem trước của chỉ số "Lift".
    4. Người dùng nhấn "Lưu".
    5. Hệ thống tạo một job tính toán định kỳ (15 phút/lần).
  ],
  [*Luồng thay thế:*], ["3a. Không đủ dữ liệu nền, hệ thống gợi ý mở rộng khung thời gian."],
  [*Luồng ngoại lệ:*], [
    - 2e. Tên sự kiện bị trùng, hệ thống trả về lỗi 409 Conflict.
    - 5e. Hàng đợi job bị đầy, hệ thống trả về lỗi 503 Service Unavailable và tự động thử lại.
  ],
  [*Hậu điều kiện:*], [
    1. Sự kiện được tạo thành công.
    2. Dashboard của sự kiện hiển thị các widget về lift, peak days, top themes.
  ],
  [*NFR Hooks:*], ["Query Latency (NFR-P2), occasion_job_lag metric (NFR-O1)."],
  [*UI Mapping:*], ["Màn hình: Occasion Config, Occasion Insights."],
)

=== Chi tiết Use Case UC-07: Tạo phân khúc người tiêu dùng
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [
    1. Người dùng đã đăng nhập và có quyền Member.
    2. Dự án đã có dữ liệu ít nhất 7 ngày.
  ],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Segment Builder" và chọn "Tạo mới".
    2. Người dùng đặt tên và chọn các điều kiện (nhân khẩu học, chủ đề, sentiment).
    3. Hệ thống hiển thị số lượng người dùng ước tính và insight sơ bộ.
    4. Người dùng nhấn "Lưu".
  ],
  [*Luồng thay thế:*], [2a. Người dùng nhập điều kiện từ tệp CSV.],
  [*Luồng ngoại lệ:*], [
    - 2e. Điều kiện xung đột, hệ thống trả về lỗi 422 Unprocessable Entity.
    - 4e. Tên phân khúc bị trùng, hệ thống trả về lỗi 409 Conflict.
  ],
  [*Hậu điều kiện:*], [Phân khúc mới có thể được sử dụng như một bộ lọc chung trên toàn hệ thống.],
  [*NFR Hooks:*], ["Query Latency (NFR-P2), Privacy (NFR-C1, NFR-C2)."],
  [*UI Mapping:*], ["Màn hình: Segment Builder, Segment Insights."],
)



=== Chi tiết Use Case UC-08: Tích hợp Dữ liệu Khảo sát
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-08_])
#table_counter.step()
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  align: (left + top, left + top),
  [*Tác nhân:*], [Marketing Analyst],
  [*Tiền điều kiện:*], [
    1. Người dùng đã đăng nhập.
    2. Có tệp CSV hợp lệ hoặc token kết nối từ nhà cung cấp khảo sát (Google Forms, Typeform).
  ],
  [*Luồng chính:*], [
    1. Người dùng điều hướng đến màn hình "Survey Integration" và chọn "Nhập dữ liệu".
    2. Người dùng tải lên tệp CSV.
    3. Hệ thống xác thực schema và hiển thị giao diện ánh xạ.
    4. Người dùng ánh xạ một câu hỏi trong khảo sát với một chủ đề trong hệ thống.
    5. Người dùng xem dashboard so sánh kết quả.
  ],
  [*Luồng thay thế:*], [2a. Người dùng kết nối qua webhook để kéo dữ liệu định kỳ.],
  [*Luồng ngoại lệ:*], [
    - 2e. Tệp CSV lỗi encoding hoặc thiếu cột, hệ thống trả về lỗi 422 Unprocessable Entity.
    - 4e. Ánh xạ bị trùng, hệ thống trả về lỗi 409 Conflict.
  ],
  [*Hậu điều kiện:*], [
    1. Dữ liệu khảo sát được nhập và ánh xạ thành công.
    2. Hành động được ghi vào audit log.
  ],
  [*NFR Hooks:*], [Thời gian parse ≤ 60 giây cho tệp 50MB; không lưu trữ PII thô từ khảo sát.],
  [*UI Mapping:*], ["Màn hình: Survey Import & Mapping, Survey Compare."],
)

// === Chi tiết Use Case UC-09: Kết nối Nguồn dữ liệu
// #table(
//   columns: (auto, 1fr),
//   stroke: 0.5pt,
//   align: (left + top, left + top),
//   [*Tác nhân:*], [Marketing Analyst],
//   [*Tiền điều kiện:*], [1. Người dùng đã đăng nhập và có quyền Member.],
//   [*Luồng chính:*], [
//     1. Người dùng điều hướng đến màn hình "Data Source Connections" và chọn "Thêm nguồn mới".
//     2. Người dùng chọn nền tảng (ví dụ: Facebook).
//     3. Hệ thống chuyển hướng đến trang xác thực OAuth của nền tảng, hiển thị rõ các quyền (scopes) được yêu cầu.
//     4. Người dùng đồng ý cấp quyền.
//     5. Hệ thống nhận và lưu trữ an toàn (mã hóa) access token và refresh token.
//     6. Hệ thống thực hiện một cuộc gọi API kiểm tra (health-check) để xác nhận kết nối thành công.
//     7. Nguồn dữ liệu mới hiển thị trong danh sách với trạng thái "Connected".
//   ],
//   [*Luồng thay thế:*], ["5a. Refresh token thất bại, hệ thống cập nhật trạng thái nguồn dữ liệu thành ""Re-authentication needed"" và gửi thông báo cho người dùng."],
//   [*Luồng ngoại lệ:*], [
//     - 4e. Người dùng từ chối cấp quyền, hệ thống hiển thị thông báo "Kết nối thất bại do không được cấp quyền."
//     - 4e. Nền tảng trả về lỗi rate-limit, hệ thống trả về lỗi 429 và thực hiện backoff.
//   ],
//   [*Hậu điều kiện:*], [
//     1. Nguồn dữ liệu được kết nối thành công.
//     2. Hành động được ghi vào audit log, bao gồm cả các scope đã được đồng ý.
//   ],
//   [*NFR Hooks:*], ["Secret Rotation (NFR-S3), Audit Log (FR-SYS-2), Consent Logging (NFR-C3)."],
//   [*UI Mapping:*], [Màn hình: Data Source Connections.],
// )

== 4.6 Sơ đồ hoạt động (Activity Diagram)


=== Biểu đồ hoạt động cho UC-01: Khám phá xu hướng nội dung


#image("../images/activity/1.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-01_])
#image_counter.step()


// Hình 1 mô tả luồng nghiệp vụ "Khám phá xu hướng nội dung".
// Luồng này bắt đầu khi Marketing Analyst thực hiện tìm kiếm,
// cho thấy hai luồng thay thế là tìm bằng từ khóa hoặc chọn topic có sẵn.
// Hệ thống sau đó sẽ truy vấn và rẽ nhánh dựa trên việc có tìm thấy kết quả hay không...

=== Biểu đồ hoạt động cho UC-02: Thiết lập theo dõi đối thủ

#image("../images/activity/2.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02_])
#image_counter.step()

// Hình 2 mô tả luồng "Thiết lập theo dõi đối thủ".
// Sơ đồ này tập trung vào các bước xác thực dữ liệu (validation)
// phía hệ thống. Sau khi người dùng nhấn "Lưu", hệ thống sẽ
// kiểm tra một loạt các điều kiện ngoại lệ như tên dự án bị trùng
// (lỗi 409) hoặc URL không hợp lệ (lỗi 422) trước khi
// chính thức tạo dự án và khởi chạy job thu thập.

=== Biểu đồ hoạt động cho UC-03: Quản lý cảnh báo khủng hoảng


#image("../images/activity/3.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-03_])
#image_counter.step()

// Hình 3 mô tả luồng nghiệp vụ quan trọng "Quản lý cảnh báo khủng hoảng".
// Đây là một quy trình bắt đầu hoàn toàn tự động từ phía hệ thống.
// Sơ đồ cho thấy cách hệ thống xử lý các ngoại lệ khi gửi thông báo
// (như lỗi 429 Rate Limit) và sau đó chuyển luồng cho Community Manager
// để thực hiện các hành động phản hồi như "Acknowledge" hoặc "Escalate".

#pagebreak()
== 4.7 Kiến trúc hệ thống tổng quan

#import "section_4_7.typ" as system_architecture_overview
#system_architecture_overview

#import "section_4_7_2.typ" as system_architecture_selection
#system_architecture_selection
#pagebreak()

== 4.8 Sơ đồ tuần tự

#image("../images/sequence/1.png")
#context (align(center)[_Hình #image_counter.display(): uc-01_])
#image_counter.step()

#image("../images/sequence/2.png")
#context (align(center)[_Hình #image_counter.display(): uc-02_])
#image_counter.step()

#image("../images/sequence/3.png")
#context (align(center)[_Hình #image_counter.display(): uc-03_])
#image_counter.step()

#image("../images/sequence/4.png")
#context (align(center)[_Hình #image_counter.display(): uc-04_])
#image_counter.step()

#image("../images/sequence/5.png")
#context (align(center)[_Hình #image_counter.display(): uc-05_])
#image_counter.step()

#image("../images/sequence/6.png")
#context (align(center)[_Hình #image_counter.display(): 6_])
#image_counter.step()

#image("../images/sequence/8.png")
#context (align(center)[_Hình #image_counter.display(): 8_])
#image_counter.step()

== 4.9 Sơ đồ dữ liệu

#image("../images/schema/SMAP-collector.png")
#context (align(center)[_Hình #image_counter.display(): collector schema_])
#image_counter.step()
