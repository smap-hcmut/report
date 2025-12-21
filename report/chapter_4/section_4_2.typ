// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.2 Functional Requirements
Căn cứ vào các mục tiêu nghiệp vụ của Marketing Analyst (A-01) và các ràng buộc kỹ thuật từ các nền tảng mạng xã hội (A-02) đã phân tích tại mục 4.1, nhóm tác giả xác định các yêu cầu chức năng (FR) cần thiết để hiện thực hóa hệ thống. Các chức năng này được chia thành 3 nhóm chính: thu thập dữ liệu, phân tích dữ liệu và báo cáo trực quan.

#context (align(center)[_Bảng #table_counter.display(): Functional Requirements_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (0.08fr, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*ID*],
    table.cell(align: center + horizon)[*Mô tả*],

    // FR-1: Cấu hình Project (UC-01)
    align(center + horizon)[FR-1],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cho phép Marketing Analyst tạo và cấu hình Project mới để theo dõi thương hiệu. Project bao gồm: \
      (1) Thông tin cơ bản: tên (3-100 ký tự, duy nhất trong phạm vi user), mô tả, khoảng thời gian theo dõi (tối thiểu 1 ngày, tối đa 1 năm, không vượt quá ngày hiện tại); \
      (2) Từ khóa thương hiệu: từ 1 đến 10 từ khóa, mỗi từ khóa 2-50 ký tự, hỗ trợ gợi ý từ khóa tự động; \
      (3) Đối thủ cạnh tranh: tối đa 5 đối thủ, mỗi đối thủ 1-5 từ khóa; \
      (4) Nền tảng mạng xã hội: chọn ít nhất 1 platform; \
      (5) Chạy thử nghiệm trích xuất mẫu 3 kết quả/từ khóa (kèm chỉ số tương tác) để verify độ phủ; hỗ trợ thử nghiệm lặp lại, không lưu trạng thái (stateless). \
      (6) Hệ thống validate tất cả thông tin trước khi lưu và hiển thị thời gian xử lý ước tính dựa trên số lượng từ khóa, platform và bài viết mong muốn.\
      (7) Ghi nhận bản ghi Project vào cơ sở dữ liệu, Project chỉ chạy khi user thực hiện khởi chạy.],

    // FR-2: Thực thi & Giám sát Project (UC-03)
    align(center + horizon)[FR-2],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cho phép Marketing Analyst khởi chạy Project từ trạng thái Draft và theo dõi tiến độ xử lý theo thời gian thực. Quá trình xử lý diễn ra qua các pha:\
      (1) Thu thập dữ liệu (Crawling): thu thập bài viết và comments từ các platform đã chọn; \
      (2) Phân tích dữ liệu (Analyzing): chạy pipeline AI để phân tích sentiment, keywords, aspects;\
      (3) Tổng hợp kết quả (Aggregating): tính toán KPI và metrics; \
      (4) Hoàn tất (Finalizing): cập nhật trạng thái và thông báo người dùng. Hệ thống hiển thị tiến độ real-time bao gồm: giai đoạn hiện tại, phần trăm hoàn thành, thời gian đã xử lý, và số lượng bài viết theo từng platform. \

      Khi hoàn tất, hệ thống tự động cập nhật trạng thái và thông báo người dùng qua nhiều kênh (thông báo trong ứng dụng, email tùy chọn).],

    // FR-3: Quản lý danh sách Projects (UC-05)
    align(center + horizon)[FR-3],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cung cấp giao diện quản lý danh sách Projects của Marketing Analyst. Danh sách hiển thị các Project kèm thông tin: tên; trạng thái (draft, process, completed, failed, cancelled); thời gian tạo.\

      Người dùng có thể: \
      (1) Lọc Projects theo trạng thái;\
      (2) Tìm kiếm theo tên (không phân biệt hoa thường, tìm kiếm một phần);\
      (3) Sắp xếp theo thời gian (tăng dần hoặc giảm dần). \
      Chỉnh sửa Project chỉ được phép khi Project ở trạng thái Draft. Projects đang chạy không thể chỉnh sửa, chỉ có thể xem tiến độ hoặc hủy. Hệ thống tự động điều hướng người dùng đến trang phù hợp dựa trên trạng thái Project: \
      (1) Draft - trang chỉnh sửa; \
      (2) Đang chạy - trang giám sát; \
      (3) Hoàn tất/Thất bại/Đã hủy - trang dashboard. \

      Người dùng có thể xóa Project (soft-delete), hệ thống sẽ đánh dấu đã xóa nhưng vẫn giữ lại dữ liệu trong một khoảng thời gian nhất định cho mục đích audit và tuân thủ.],

    // FR-4: Xem kết quả & So sánh (UC-04)
    align(center + horizon)[FR-4],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cung cấp dashboard trực quan để Marketing Analyst xem kết quả phân tích và so sánh với đối thủ. Dashboard hiển thị: \
      (1) KPI tổng quan: tổng số bài viết, phân bố sentiment, các chỉ số tương tác; \
      (2) Biểu đồ sentiment trend theo thời gian; \
      (3) Phân tích theo khía cạnh với sentiment breakdown; \
      (4) So sánh với đối thủ (nếu có cấu hình) bao gồm so sánh sentiment, engagement, và share of voice. \

      Người dùng có thể lọc kết quả theo platform, sentiment, khoảng thời gian, và khía cạnh. Hệ thống hỗ trợ drilldown: click vào khía cạnh để xem các bài viết liên quan, click vào bài viết để xem nội dung đầy đủ và comments.],

    // FR-5: Xuất báo cáo (UC-06)
    align(center + horizon)[FR-5],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cho phép Marketing Analyst xuất báo cáo từ dashboard với nhiều định dạng (PDF, PPTX, Excel). Người dùng có thể chọn nội dung báo cáo (KPIs, Sentiment Analysis, Aspect Analysis, So sánh đối thủ, Raw Data) và khoảng thời gian. \

      Báo cáo được gắn metadata bao gồm: phiên bản phân tích, thời điểm xuất, bộ lọc đã áp dụng, khoảng thời gian, và định dạng. Hệ thống xử lý báo cáo bất đồng bộ và cung cấp link tải khi hoàn tất.],

    // FR-6: Phát hiện trend tự động (UC-07)
    align(center + horizon)[FR-6],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống tự động phát hiện trend để Marketing Analyst theo dõi các xu hướng mới nổi trên mạng xã hội thông qua cron job chạy định kỳ (hàng ngày, hàng tuần) theo lịch trình được cấu hình sẵn. Hệ thống tự động thực hiện: \
      (1) Thu thập nội dung trend (nhạc, từ khóa, hashtag) từ các platform đã được cấu hình trong Project;\
      (2) Chuẩn hóa metadata bao gồm: tiêu đề, platform, thời gian, chỉ số tương tác (views, likes, comments, shares, saves);\
      (3) Tính toán điểm số dựa trên engagement và velocity để xếp hạng trends; \
      (4) Lưu lại mỗi lần chạy với thông tin: thời gian chạy, platform, danh sách trends đã xếp hạng, và điểm số. \
      Hệ thống cung cấp Trend Dashboard để Marketing Analyst xem danh sách trends đã xếp hạng với các chức năng: \
      (1) Lọc theo platform, khoảng thời gian, điểm số tối thiểu; \
      (2) Sắp xếp theo điểm số (giảm dần) hoặc thời gian phát hiện (mới nhất); \
      (3) Xem chi tiết từng trend bao gồm metadata đầy đủ và các bài viết liên quan.],

    // FR-7: Phát hiện khủng hoảng (UC-08)
    align(center + horizon)[FR-7],
    table.cell(align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống cung cấp chức năng giám sát khủng hoảng chủ động (Crisis Monitoring). Marketing Analyst có thể thiết lập các chủ đề giám sát (Crisis Monitors) với cấu hình: \
      (1) Tên thương hiệu/chủ đề cần bảo vệ; \
      (2) Từ khóa bao gồm (Include Keywords); \
      (3) Nền tảng theo dõi; \
      (4) Ngưỡng cảnh báo; \

      Hệ thống tự động quét dữ liệu mới nhất theo chu kỳ định sẵn (ví dụ: mỗi 3 tiếng) thông qua cron job. Khi phát hiện nội dung vi phạm ngưỡng an toàn, hệ thống: \
      (1) Tạo cảnh báo (Alert); \
      (2) Gửi thông báo tức thì đến user qua các kênh thông báo; \
      (3) Lưu trữ các bài viết vi phạm (Hit) để tối ưu storage. \
    ],
  )
]
