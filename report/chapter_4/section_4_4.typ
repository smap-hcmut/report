// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

\

== 4.4 Use Case
#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1.2fr, 0.8fr, 0.8fr, 1.8fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),

    table.header([*ID*], [*Tên Use Case*], [*Primary Actor*], [*Secondary Actor*], [*Mục tiêu (Goal)*]),

    [UC-01], [Cấu hình Project],
    table.cell(rowspan: 8, [*Marketing Analyst*]),
    [-], [Tạo cấu hình Project với thông tin thương hiệu, từ khóa, đối thủ, platforms],

    [UC-02], [Kiểm tra từ khóa (Dry-run)],
    [Social Media Platforms], [Xác thực chất lượng từ khóa bằng mẫu kết quả],

    [UC-03], [Khởi chạy và theo dõi Project],
    [Social Media Platforms], [Thực thi pipeline thu thập và phân tích dữ liệu],

    [UC-04], [Xem kết quả phân tích],
    [-], [Xem dashboard với KPIs, sentiment, aspects và so sánh đối thủ],

    [UC-05], [Quản lý danh sách Projects],
    [-], [Xem, lọc, tìm kiếm và điều hướng Projects theo trạng thái],

    [UC-06], [Xuất báo cáo],
    [-], [Tạo và tải báo cáo phân tích ở nhiều định dạng],

    [UC-07], [Phát hiện trend tự động],
    [Social Media Platforms], [Thu thập và xếp hạng trends theo lịch định kỳ],

    [UC-08], [Phát hiện khủng hoảng],
    [Social Media Platforms], [Nhận diện và cảnh báo khủng hoảng truyền thông],
  )
]

\

=== UC-01: Cấu hình Project
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-01: Cấu hình Project],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Marketing Analyst tạo cấu hình Project mới để theo dõi thương hiệu và đối thủ cạnh tranh trên các nền tảng mạng xã hội. Project được lưu ở trạng thái Draft, cho phép kiểm tra và chỉnh sửa trước khi khởi chạy thu thập dữ liệu.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User nhấn "Tạo Project mới" từ màn hình Projects.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập vào hệ thống SMAP.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Project mới được lưu vào database với status "draft".
      2. Project ID được tạo và trả về cho user.
      3. User có thể thấy Project trong danh sách (UC-05).
      4. Project sẵn sàng cho việc khởi chạy (UC-03).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User nhấn "Tạo Project mới".
      2. Hệ thống hiển thị wizard cấu hình (4 bước).
      3. User nhập thông tin cơ bản: tên (3-100 ký tự, unique), mô tả, khoảng thời gian (1 ngày - 1 năm).
      4. User nhập tên thương hiệu và từ khóa thương hiệu (1-10 từ khóa, mỗi từ 2-50 ký tự).
      5. User thêm đối thủ cạnh tranh (1-5 đối thủ với 1-5 từ khóa mỗi đối thủ).
      6. User chọn platforms: YouTube, TikTok, Facebook (ít nhất 1 bắt buộc).
      7. Hệ thống hiển thị tổng quan cấu hình và thời gian xử lý ước tính.
      8. User chọn "Lưu Project" hoặc "Dry-run".
      9. Hệ thống validate tất cả inputs.
      10. Hệ thống lưu Project vào database với status "draft".
      11. Hệ thống hiển thị thông báo "Lưu Project thành công".
      12. Hệ thống chuyển hướng về danh sách Projects (UC-05).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Dry-run từ khóa* \
      Tại Bước 8 của luồng cơ bản:
      - 8A.1. User nhấn nút "Dry-run".
      - 8A.2. Hệ thống chuyển hướng đến UC-02 (Dry-run).
      - 8A.3. Sau khi dry-run hoàn tất, user xem lại kết quả mẫu.
      - 8A.4. User điều chỉnh từ khóa nếu cần.
      - Tiếp tục tại bước 7.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi validation* \
      Tại Bước 9 của luồng cơ bản, nếu validation thất bại:
      - 9.E.1. Hệ thống highlight các trường lỗi với thông báo cụ thể:\
        • Tên Project đã tồn tại cho user này \
        • Thiếu tên thương hiệu hoặc từ khóa thương hiệu \
        • Độ dài từ khóa không hợp lệ (< 2 hoặc > 50 ký tự) \
        • Quá nhiều đối thủ (> 5) \
        • Chưa chọn platform \
        • Khoảng thời gian không hợp lệ (to_date <= from_date) \
      - 9.E.2. User sửa các trường lỗi.
      - Tiếp tục tại bước 9.

      *Lỗi database* \
      Tại Bước 10 của luồng cơ bản, nếu database không khả dụng:
      - 10.E.1. Hệ thống hiển thị "Không thể lưu Project, vui lòng thử lại sau".
      - 10.E.2. Hệ thống giữ lại dữ liệu form để tránh mất dữ liệu.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Tạo project không trigger background processing
    ],
  )
]

=== UC-02: Kiểm tra từ khóa (Dry-run)
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-02: Kiểm tra từ khóa (Dry-run)],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Đặng Quốc Phong],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[01/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Social Media Platforms
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Marketing Analyst thực hiện dry-run để xác thực chất lượng từ khóa trước khi lưu Project. Hệ thống thu thập mẫu nhỏ (3 posts/từ khóa) để đánh giá độ liên quan và điều chỉnh keywords nếu cần.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[User nhấn nút "Dry-run" trong UC-01 bước 8.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3)[
      1. User đang ở wizard cấu hình Project (UC-01).
      2. User đã nhập thương hiệu và ít nhất 1 đối thủ.
      3. User đã chọn ít nhất 1 platform.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. User nhận được kết quả mẫu hoặc thông báo "Không tìm thấy kết quả".
      2. User quay lại UC-01 để tiếp tục cấu hình hoặc lưu Project.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3)[
      1. User nhấn nút "Dry-run".
      2. Hệ thống hiển thị loading với thông báo "Đang thu thập mẫu...".
      3. Hệ thống crawl tối đa 3 posts mỗi từ khóa từ platforms đã chọn.
      4. Hệ thống hiển thị kết quả mẫu với: tiêu đề, preview nội dung, platform, views, likes, comments, shares.
      5. User xem xét chất lượng và độ liên quan của kết quả.
      6. User chọn "Tiếp tục" (quay lại UC-01 bước 7) hoặc "Quay lại" (quay lại UC-01 bước 4).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Không tìm thấy kết quả* \
      Tại Bước 4 của luồng cơ bản, nếu không tìm thấy posts cho từ khóa:
      - 4A.1. Hệ thống hiển thị "Không tìm thấy kết quả cho từ khóa: [tên]".
      - 4A.2. Các từ khóa khác vẫn hiển thị kết quả bình thường.
      - 4A.3. User có thể thử lại hoặc điều chỉnh từ khóa.
      - Tiếp tục tại bước 5.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi rate-limit* \
      Tại Bước 3 của luồng cơ bản, nếu platform trả về lỗi do gửi quá nhiều yêu cầu:
      - 3.E.1. Hệ thống hiển thị "Không thể lấy mẫu do giới hạn từ [platform], vui lòng thử lại sau 5 phút".
      - 3.E.2. Các platforms khác tiếp tục xử lý.
      - Kết thúc use case.

      *Lỗi timeout* \
      Tại Bước 3 của luồng cơ bản, nếu xử lý > 90 giây:
      - 3.E.3. Hệ thống hiển thị "Dry-run timeout".
      - 3.E.4. User có thể thử lại hoặc điều chỉnh từ khóa.
      - Tiếp tục tại bước 5.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Thời gian trung bình 30-60 giây, timeout threshold 90 giây
    ],
  )
]

\

=== UC-03: Khởi chạy và theo dõi Project
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-03: Khởi chạy và theo dõi Project],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Social Media Platforms
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Marketing Analyst khởi chạy Project để thực thi pipeline 4 giai đoạn: (1)Crawling, (2)Analyzing, (3)Aggregating, (4)Finalizing. User theo dõi tiến độ real-time.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[User nhấn "Khởi chạy" từ danh sách Projects (UC-05).],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3)[
      1. Project tồn tại với status "draft".
      2. User là owner của Project.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Project status được cập nhật thành "completed" hoặc "failed".
      2. Dữ liệu đã thu thập và phân tích, lưu vào PostgreSQL.
      3. User nhận notification hoàn tất.
      4. Dashboard sẵn sàng để xem (UC-04).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User chọn draft Project từ danh sách.
      2. User nhấn nút "Khởi chạy".
      3. Hệ thống verify ownership và status.
      4. Hệ thống cập nhật status thành "process".\

      5. Hệ thống thực thi pipeline 4 giai đoạn: (1)Crawling - thu thập posts/comments, (2)Analyzing - chạy NLP pipeline 5 bước, (3)Aggregating, (4)Finalizing - cleanup và notify.
      6. User mở trang chi tiết Project để theo dõi tiến độ.
      7. Hệ thống hiển thị real-time: giai đoạn hiện tại, phần trăm, thời gian đã chạy, items đã xử lý, ETA.
      9. Khi hoàn tất: gửi notification, hiển thị "Project hoàn tất! Xem kết quả".
      10. User nhấn notification hoặc Project để điều hướng đến Dashboard (UC-04).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Thử lại Project thất bại* \
      Tại bước 1 của luồng cơ bản, nếu chọn failed project:
      - 1A.1. Hệ thống hiển thị "Thử lại".
      - 1A.2. User chọn thử lại: tiếp tục tại bước 3.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Truy cập không được phép* \
      Tại bước 1 của luồng cơ bản, nếu user không phải owner:
      - 1.E.1. Hệ thống hiển thị "Bạn không có quyền truy cập project".
      - Kết thúc use case.

      *Status không hợp lệ* \
      Tại bước 3 của luồng cơ bản, nếu status không phải "draft"/"failed":
      - 3.E.1. Hệ thống hiển thị "Project đã được khởi chạy hoặc đang thực thi".
      - Kết thúc use case.

      *Thực thi thất bại* \
      Tại Bước 5 của luồng cơ bản, nếu hệ thống gặp lỗi trong quá trình xử lý:
      - 5.E.1. Hệ thống hiển thị "Project khởi chạy thất bại, vui lòng thử lại!" và cập nhật status thành "failed".
      - 5.E.2. Quay lại bước 1 của luồng cơ bản.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      - Hệ thống xử lý dữ liệu với pipeline 4 giai đoạn: (1)Crawling - thu thập posts/comments, (2)Analyzing - chạy NLP pipeline 5 bước, (3)Aggregating, (4)Finalizing - cleanup và notify.
      - Trung bình 35-50 phút, max timeout 2 giờ.
    ],
  )
]

\

=== UC-04: Xem kết quả phân tích
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-04: Xem kết quả phân tích],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Marketing Analyst xem dashboard phân tích với sentiment trends, aspect analysis, và competitor comparison. Dashboard hỗ trợ filtering, sorting và drilldown vào chi tiết posts.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[User mở completed Project từ danh sách (UC-05).],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3)[
      1. Project có có status là "completed".
      2. User là owner của Project.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      User đã xem insights và có thông tin, bổ trợ cho việc đưa ra quyết định marketing.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3)[
      1. User mở "completed" Project từ danh sách.
      2. Hệ thống hiển thị Dashboard với 4 phần: \
      (A) KPI Overview - tổng posts, pie chart sentiment, engagement rate, \
      (B) Sentiment Trend - line chart theo timeline,\
      (C) Aspect Analysis - bar chart với top aspects,\
      (D) Competitor Comparison - so sánh sentiment và share of voice (nếu có cấu hình).
      3. User áp dụng filters: platform, sentiment, khoảng thời gian, aspect.
      4. User drilldown: nhấn aspect để xem posts liên quan, nhấn post để xem chi tiết đầy đủ với comments.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Xuất báo cáo* \
      Tại Bước 4 của luồng cơ bản:
      - 4A.1. User nhấn nút "Xuất báo cáo".
      - 4A.2. Hệ thống chuyển hướng đến UC-06.
      - 4A.3. Sau khi export hoàn tất, quay lại Dashboard.
      - Tiếp tục tại bước 4.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3, align: center + horizon)[\-
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      Dashboard load < 2s, drilldown queries < 500ms.
    ],
  )
]

\

=== UC-05: Quản lý danh sách Projects
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-05: Quản lý danh sách Projects],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Marketing Analyst quản lý danh sách Projects cá nhân: xem, lọc, tìm kiếm, và điều hướng đến các chức năng tùy theo status. Hệ thống đảm bảo ownership và status-based permissions.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User mở màn hình "Projects" từ navigation menu hoặc sau khi login.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      User đã đăng nhập vào hệ thống SMAP.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. User đã xem danh sách Projects và thực hiện actions phù hợp với status.
      2. Lịch sử navigation được lưu để quay lại.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3)[
      1. User mở màn hình "Projects".
      2. Hệ thống hiển thị danh sách Projects của user với: tên, status badge, ngày tạo, lần cập nhật cuối, preview từ khóa thương hiệu.
      3. User áp dụng filters: status, tìm kiếm theo tên, sắp xếp.
      4. User chọn Project và thấy actions tương ứng status: \
        - Draft (Khởi chạy - UC-03, Xóa); \
        - Running (Xem tiến độ - UC-03); \
        - Completed (Xem kết quả - UC-04, Xuất - UC-06, Xóa); \
        - Failed (Thử lại - UC-03, Xóa).
      5. User chọn action và điều hướng đến UC tương ứng.
      6. Nếu user chọn "Xóa": dialog xác nhận xuất hiện, nếu xác nhận: ẩn khỏi danh sách, hiển thị "Đã xóa Project".
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      *Multiple Filters* \
      Tại Bước 3 của luồng cơ bản:
      - 3A.1. User áp dụng nhiều tiêu chí (ví dụ: Status "completed").
      - 3A.2. Hệ thống áp dụng tất cả filters với logic AND.
      - 3A.3. Hiển thị count: "Hiển thị X trong tổng Y projects".
      - Tiếp tục tại bước 4. \

      *Nhấn Project Card* \
      Tại Bước 4 của luồng cơ bản, user nhấn card project:
      - 4A.1. Nếu status là "completed": điều hướng đến UC-04.
      - 4A.2. Nếu status là "process": điều hướng đến UC-03.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Xóa Running Project* \
      Tại Bước 6 của luồng cơ bản, nếu user cố xóa running project:
      - 6.E.1. Hệ thống chặn action.
      - 6.E.2. Nút "Xóa" bị vô hiệu hóa cho Running projects.
      - Tiếp tục tại bước 4.

      *Cần Pagination* \
      Tại Bước 2 của luồng cơ bản, nếu user có > 50 projects:
      - 2.E.1. Triển khai pagination: 20 projects mỗi trang.
      - 2.E.2. Infinite scroll.
      - Tiếp tục tại bước 3.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3)[
      - User chỉ thấy projects của mình, soft delete.
      - Tối ưu hiệu suất với composite index (created_by, deleted_at, status), pagination 20 items/trang.
    ],
  )
]

\

=== UC-06: Xuất báo cáo
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()
#text()[
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-06: Xuất báo cáo],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(colspan: 3)[
      #set par(justify: true)
      Marketing Analyst tạo và tải file báo cáo phân tích ở nhiều định dạng. Hệ thống hỗ trợ tuỳ chỉnh nội dung báo cáo và thời gian dữ liệu.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[User nhấn nút "Xuất báo cáo" trên Dashboard (UC-04).],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. User đang xem Dashboard của Project có dữ liệu (UC-04).
      2. Project có "completed" status.
      3. User có quyền export (project owner).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. File báo cáo được tạo và upload lên MinIO.
      2. Download link khả dụng với 7-day expiry.
      3. User nhận notification khi sẵn sàng.
      4. Lịch sử export được ghi log để audit.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. User nhấn nút "Xuất báo cáo".
      2. Hệ thống hiển thị hộp thoại cấu hình.
      3. User chọn options và nhấn "Xuất báo cáo".
      4. Hệ thống validate thông tin hợp lệ.
      5. Hệ thống ghi nhận yêu cầu thành công và hiển thị thông báo: "Hệ thống đang tạo báo cáo, bạn sẽ nhận được thông báo khi hoàn tất".
      6. Hệ thống đóng hộp thoại và cho phép User tiếp tục sử dụng các chức năng khác (không block màn hình).
      7. Sau khi xử lý xong, Hệ thống gửi một thông báo (Notification) "Báo cáo của bạn đã sẵn sàng".
      8. User nhấn vào thông báo.
      9. Hệ thống chuyển hướng đến trang tải xuống.
      10. User nhấn "Tải xuống" để lưu file về máy.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3, align: center + horizon, inset: (y: 0.8em))[
      \-
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      *Xử lý thất bại / Timeout (Sau bước 6)* \
      Nếu quá trình tạo báo cáo gặp lỗi kỹ thuật hoặc quá thời gian cho phép (> 10 phút):
      - 6.E.1. Hệ thống hủy tác vụ ngầm.
      - 6.E.2. Hệ thống gửi một thông báo (Notification) cho User: "Tạo báo cáo thất bại do dữ liệu quá lớn. Vui lòng thử lại với khoảng thời gian ngắn hơn".
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[
      *Notes and issues*],
    table.cell(colspan: 3, align: horizon)[
      *Validation Rules:*
      - Frontend (FE): Validate UX cơ bản (disable nút, check ngày tháng).
      - Backend (BE): Validate chặt chẽ dữ liệu đầu vào, trả về HTTP 400 nếu request không hợp lệ (để chống spam request tool).

      *Performance & Technical:*
      - Chế độ "Summary-only" dự kiến xử lý < 30s.
      - Sử dụng cơ chế Queue & Worker để xử lý tác vụ nặng.
      - Set timeout là 10 phút cho mỗi job export để tránh treo hệ thống.
    ],
  )
]

\

=== UC-07: Phát hiện trend tự động
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-07: Phát hiện trend tự động],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[30/11/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Social Media Platforms
      - System Actor: System Timer
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[Hệ thống tự động thu thập và xếp hạng trending content (music, keywords, hashtags) từ YouTube và TikTok theo lịch định kỳ. Marketing Analysts nhận feed trends để nắm bắt xu hướng sớm.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[System Timer trigger hàng ngày lúc 2:00 AM UTC+7.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. Cron schedule đã được hệ thống cấu hình (daily/weekly).
      2. Social Media Platforms khả dụng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. TrendRun được tạo với status "completed" hoặc "failed".
      2. Top trends được lưu vào database và xếp hạng theo score.
      3. Tất cả Marketing Analysts nhận notification.
      4. Trend Dashboard được cập nhật với latest feed.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      1. Vào thời gian định kỳ hàng ngày, Hệ thống tự động kích hoạt quy trình cập nhật xu hướng.
      2. Hệ thống thu thập dữ liệu bài viết từ các nền tảng mạng xã hội được cấu hình.
      3. Hệ thống chuẩn hóa dữ liệu, tính toán điểm xu hướng (Trend Score) và tốc độ tăng trưởng (Velocity) cho từng nội dung.
      4. Hệ thống thực hiện xếp hạng, lọc bỏ các nội dung trùng lặp và lưu trữ danh sách Top xu hướng nổi bật nhất.
      5. Marketing Analyst truy cập vào màn hình "Trend Dashboard".
      6. Hệ thống hiển thị lưới thông tin các xu hướng (Trends Grid) đã được xử lý.
      7. User xem danh sách với các thông tin tóm tắt: tiêu đề, nền tảng, điểm số, và chỉ số tăng trưởng.
      8. User sử dụng bộ lọc (theo nền tảng, loại nội dung, thời gian) để thu hẹp phạm vi tìm kiếm.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3, align: center + horizon, inset: (y: 0.6em))[
      \-
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi thu thập từ nguồn dữ liệu (Platform Error)* \
      Tại Bước 2 của luồng hệ thống, nếu gặp sự cố kết nối với các platforms:
      - 2.E.1. Hệ thống tự động thử lại kết nối nhiều lần.
      - 2.E.2. Nếu vẫn thất bại: Hệ thống bỏ qua nền tảng bị lỗi và tiếp tục xử lý các nền tảng còn lại.
      - 2.E.3. Dashboard hiển thị dữ liệu từ các nền tảng thành công, kèm thông báo cảnh báo màu vàng: "Dữ liệu từ [Tên Platform] đang gặp sự cố".
      - 2.E.4. Trường hợp toàn bộ thất bại: Hệ thống hiển thị dữ liệu của ngày hôm trước kèm thông báo lỗi cập nhật.

      *Xử lý quá thời gian (System Timeout)* \
      Nếu quy trình cập nhật kéo dài quá giới hạn cho phép (> 2 giờ):
      - 8.E.1. Hệ thống dừng quy trình cập nhật hiện tại.
      - 8.E.2. Dashboard hiển thị phần dữ liệu đã thu thập được tính đến thời điểm dừng (Partial Data) kèm cảnh báo dữ liệu chưa hoàn tất.
    ],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[
      - Áp dụng Exponential Backoff (thử lại 3 lần) trước khi đánh dấu platform failed.
      - Lịch trình Daily 2:00 AM UTC+7 (low traffic, trends đã stabilize)
      - Lưu trữ dữ liệu 30 ngày, trends cũ hơn được tự động archive
    ],
  )
]

\

=== UC-08: Phát hiện khủng hoảng
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-08_])
#table_counter.step()
#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-08: Cấu hình và Giám sát Khủng hoảng],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nguyễn Tấn Tài],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[20/10/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nguyễn Thành Tín],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[20/12/2025],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Marketing Analyst
      - Secondary Actor: Social Media Platforms
      - System Actor: Background Scheduler
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(colspan: 3, align: horizon)[
      Marketing Analyst thiết lập các chủ đề giám sát (Crisis Monitors) với từ khóa và ngưỡng cảnh báo cụ thể. Hệ thống sẽ tự động quét liên tục dựa trên cấu hình này và gửi thông báo khi phát hiện nguy cơ.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3)[
      - User muốn thiết lập một chủ đề theo dõi mới.
      - Hoặc: Hệ thống phát hiện dữ liệu khớp với cấu hình giám sát đã tạo.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3)[
      User đã đăng nhập vào hệ thống.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Một "Crisis Monitor" mới được lưu và kích hoạt lịch trình chạy ngầm.
      2. Nếu phát hiện khủng hoảng: Alert được tạo và Notification được gửi đi.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3)[
      *Giai đoạn 1: User cấu hình giám sát (Setup)*
      1. User truy cập module "Crisis Management" và chọn "Tạo giám sát mới".
      2. User nhập thông tin cấu hình:
        - Tên thương hiệu/Chủ đề cần bảo vệ.
        - Từ khóa bao gồm (Include Keywords) và Từ khóa loại trừ (Exclude Keywords).
        - Chọn nền tảng theo dõi (Facebook, TikTok...).
        - Ngưỡng cảnh báo (Ví dụ: Chỉ báo khi độ tiêu cực > 80%).
        - Kênh nhận thông báo (Email, App, SMS).
      3. Hệ thống kiểm tra hợp lệ và lưu cấu hình "Crisis Monitor".
      4. Hệ thống kích hoạt tác vụ chạy ngầm (Background Job) cho cấu hình này.

      *Giai đoạn 2: Hệ thống thực thi và Cảnh báo (Automated)*
      5. Theo chu kỳ định sẵn (ví dụ: mỗi 15 phút), Hệ thống tự động quét dữ liệu mới nhất trên các nền tảng dựa theo từ khóa đã cấu hình.
      6. Nếu phát hiện nội dung vi phạm ngưỡng an toàn: Hệ thống tạo Cảnh báo (Alert).
      7. Hệ thống gửi thông báo tức thì đến User qua các kênh đã đăng ký.

      *Giai đoạn 3: User phản ứng*
      8. User nhận thông báo và bấm vào để xem chi tiết.
      9. User xem danh sách các bài viết gây khủng hoảng và thực hiện hành động xử lý (Bỏ qua hoặc Báo cáo).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[

      *Tạm dừng giám sát* \
      Tại màn hình quản lý Crisis Monitor:
      - A.1. User chọn một Monitor đang chạy và nhấn "Tạm dừng".
      - A.2. Hệ thống ngắt lịch chạy ngầm của Monitor đó (trạng thái Inactive).
      - A.3. Không có thông báo mới nào được gửi cho đến khi kích hoạt lại.

      *Điều chỉnh cấu hình* \
      Nếu User nhận quá nhiều thông báo rác (False Positive):
      - B.1. User vào "Chỉnh sửa Monitor".
      - B.2. User thêm "Từ khóa loại trừ" hoặc nâng cao "Ngưỡng cảnh báo".
      - B.3. Hệ thống cập nhật luồng quét với tham số mới.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi hệ thống giám sát* \
      Nếu Service chạy ngầm bị gián đoạn (Server down, API lỗi):
      - E.1. Hệ thống ghi log lỗi.
      - E.2. Gửi email cảnh báo cho Admin hệ thống: "Crisis Monitor Service is DOWN".
      - E.3. Khi hệ thống phục hồi, tự động chạy bù (backfill) dữ liệu trong khoảng thời gian chết (nếu khả thi) hoặc bắt đầu quét từ thời điểm hiện tại.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3)[
      *Sự khác biệt với Project:*
      - Project (UC-01): Chạy 1 lần trên dữ liệu quá khứ để phân tích sâu.
      - Crisis Monitor (UC-08): Chạy liên tục trên dữ liệu thời gian thực (Real-time/Near real-time Data) để phân tích và phát hiện khủng hoảng.

      *Technical:*
      - Cơ chế: Không lưu toàn bộ dữ liệu, chỉ lưu các bài viết vi phạm (Hit) để tối ưu storage.
    ],
  )
]
