// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

#pagebreak()

== 4.4 Use Case
#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1.2fr, 0.7fr, 0.8fr, 1.8fr),
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


=== UC-01: Cấu hình Project
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-01],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Cấu hình Project],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[-],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Tạo cấu hình Project để theo dõi thương hiệu/đối thủ và lưu ở trạng thái Draft.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: cấu hình nhanh, validate rõ ràng, có dry-run trước khi lưu.
      - SMAP System: đảm bảo giới hạn 10 projects/user; validate tên unique; bảo mật theo owner.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [User đã đăng nhập; user chưa vượt giới hạn 10 active projects.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [User chọn "Tạo Project mới" từ màn Projects.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [Project lưu với status = Draft, sẵn sàng cho UC-03.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu lỗi, thông báo rõ ràng và giữ dữ liệu đã nhập.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. User chọn "Tạo Project mới".
      2. Nhập thông tin cơ bản (tên 3-100 ký tự unique trong phạm vi user, mô tả, khoảng thời gian 1 ngày - 1 năm).
      3. Nhập từ khóa thương hiệu (1-10 từ khóa, mỗi từ 2-50 ký tự).
      4. Thêm đối thủ cạnh tranh (tối đa 5 đối thủ, mỗi đối thủ 1-5 từ khóa) - optional.
      5. Chọn platforms (YouTube và/hoặc TikTok, ít nhất 1 platform).
      6. Hệ thống hiển thị tổng quan cấu hình và thời gian xử lý ước tính.
      7. User chọn: (a) "Dry-run" để kiểm tra từ khóa (UC-02) hoặc (b) "Lưu Project".
      8. Hệ thống validate và lưu Project với status = Draft.
      9. Thông báo lưu thành công, điều hướng về danh sách Projects (UC-05).
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - A1 (bước 2-5): Validation errors (tên trùng, thiếu keyword, keyword < 2 ký tự, > 5 đối thủ, không chọn platform) → báo lỗi, yêu cầu sửa.
      - A2 (bước 7): User chọn dry-run → UC-02, sau đó quay lại bước 6 để chỉnh hoặc lưu.
      - E1 (bước 8): Database error → báo lỗi "Không thể lưu, vui lòng thử lại", giữ draft input.
    ],
  )
]

=== UC-02: Kiểm tra từ khóa (Dry-run)
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-02],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Kiểm tra từ khóa (Dry-run)],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[Social Media Platforms],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Xác thực chất lượng từ khóa trước khi lưu Project.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: muốn thấy mẫu kết quả để điều chỉnh từ khóa, tránh thu thập sai.
      - SMAP System: tôn trọng rate-limit của platforms, cung cấp feedback rõ ràng.
      - Social Media Platforms: không bị spam requests.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [Đang ở bước cấu hình từ khóa trong UC-01; user đã đăng nhập.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [User bấm "Dry-run" trong form cấu hình.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [Hiển thị mẫu 3 bài viết/từ khóa hoặc thông báo "Không tìm thấy kết quả".],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu bị rate-limit, thông báo "Không thể lấy mẫu lúc này, vui lòng thử lại sau".],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. User bấm "Dry-run".
      2. Hệ thống xác nhận và bắt đầu thu thập mẫu.
      3. Thu thập tối đa 3 bài viết/từ khóa từ platforms đã chọn.
      4. Hiển thị mẫu với: tiêu đề, nội dung tóm tắt, platform, views, likes.
      5. User đánh giá kết quả.
      6. User chọn: (a) "Chấp nhận" → quay UC-01 bước 6, hoặc (b) "Điều chỉnh" → quay UC-01 bước 3.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - A1 (bước 4): Không có kết quả → hiển thị "Không tìm thấy kết quả cho từ khóa này", cho phép thử lại.
      - A2 (bước 5): Kết quả không liên quan → user quay lại bước 3 UC-01 để chỉnh từ khóa.
      - E1 (bước 3): Rate-limit hoặc platform error → thông báo "Không thể lấy mẫu lúc này", gợi ý thử lại sau 5 phút.
    ],
  )
]

=== UC-03: Khởi chạy và theo dõi Project
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-03],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Khởi chạy và theo dõi Project],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[Social Media Platforms (YouTube, TikTok)],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Thực thi pipeline thu thập và phân tích dữ liệu, theo dõi tiến độ real-time.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: muốn chạy project, thấy tiến độ rõ, nhận cảnh báo khủng hoảng nếu có.
      - SMAP System: tuân thủ rate-limit, lưu partial results khi có lỗi.
      - Social Media Platforms: SMAP truy cập hợp lý, không spam.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [User đã đăng nhập; Project tồn tại với status = Draft; user là owner của Project.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [User nhấn "Khởi chạy Project" từ danh sách Projects.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [Project status = Completed, dữ liệu đã thu thập và phân tích, sẵn sàng cho UC-04.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu lỗi → status = Failed với failure_reason (CrawlFailed, AnalysisFailed, SystemFailed, Timeout); dữ liệu thô được giữ lại (is_partial_result = true) trong 90 ngày.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. User mở danh sách Projects (UC-05).
      2. Chọn Project có status = Draft.
      3. Nhấn "Khởi chạy Project".
      4. Hệ thống cập nhật status = Running và bắt đầu pipeline:
        - Bước 1: Crawling - thu thập bài viết và comments từ platforms.
        - Bước 2: Analyzing - chạy NLP pipeline (sentiment, keywords, aspects).
        - Bước 3: Aggregating - tính KPIs và metrics.
        - Bước 4: Finalizing - lưu kết quả và chuẩn bị dashboard.
      5. User mở chi tiết Project đang chạy.
      6. Hệ thống hiển thị real-time: stage hiện tại, phần trăm hoàn thành, thời gian đã chạy, số items đã xử lý theo platform.
      7. Nếu phát hiện crisis trong quá trình analyze → gửi cảnh báo ngay (UC-08), pipeline tiếp tục.
      8. Khi hoàn tất:
        - Cập nhật status = Completed.
        - Gửi thông báo qua in-app notification và email (nếu user đã bật).
      9. User điều hướng đến UC-04 để xem kết quả.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - E1 (bước 6): User hủy Project → hiển thị confirm dialog; nếu đồng ý: dừng pipeline, status = Cancelled, giữ dữ liệu đã thu thập.
      - E2 (bước 2): Chọn Project Failed → hiển thị lựa chọn: (a) "Chạy lại toàn bộ" → quay bước 4, (b) "Chỉnh sửa cấu hình" → UC-01.
      - E3 (bước 4): Crawling error (rate-limit, network) → retry 3 lần với exponential backoff; nếu vẫn fail: status = Failed, failure_reason = CrawlFailed, giữ partial data.
      - E4 (bước 4): Analysis error (model crash) → status = Failed, failure_reason = AnalysisFailed, giữ raw data; cho phép "Chạy lại phân tích" từ UC-04.
      - E5 (bước 4): Quá 2 giờ vẫn chưa xong → dừng pipeline, status = Failed, failure_reason = Timeout, is_partial_result = true, thông báo user có thể xem partial results hoặc chạy lại.
    ],
  )
]

=== UC-04: Xem kết quả phân tích và so sánh
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-04],
    [*Use Case Name*], [Xem kết quả phân tích và so sánh],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Marketing Analyst],
    [*Secondary Actor*], [-],
    [*Goal*], [Xem dashboard với KPIs, sentiment trends, aspects và so sánh đối thủ.],
    [*Stakeholders & Interests*],
    [
      - Marketing Analyst: cần insights rõ ràng, biết full/partial results, có thể drilldown.
      - SMAP System: hiển thị đúng dữ liệu available, tôn trọng retention 90 ngày.
    ],

    [*Preconditions*],
    [Project có has_result = true (Completed, Failed với partial, hoặc Cancelled); user đã đăng nhập và là owner.],

    [*Trigger*], [User mở Project từ danh sách (UC-05).],
    [*Success Guarantee*],
    [Dashboard hiển thị metrics, sentiment, aspects, competitor comparison theo dữ liệu hiện có.],

    [*Minimal Guarantee*], [Nếu dữ liệu đã hết retention (90 ngày) → hiển thị thông báo "Dữ liệu không còn khả dụng".],
    [*Main Flow*],
    [
      1. User mở Project có kết quả (Completed/Failed/Cancelled).
      2. Hệ thống hiển thị Dashboard với:
        - KPI Overview: tổng bài viết, phân bố sentiment, engagement metrics.
        - Sentiment Trend: biểu đồ theo thời gian.
        - Aspect Analysis: sentiment breakdown theo aspects (DESIGN, PERFORMANCE, PRICE, SERVICE, GENERAL).
        - Competitor Comparison: so sánh sentiment, engagement, share of voice (nếu có cấu hình đối thủ).
      3. User lọc theo: platform, sentiment, khoảng thời gian, aspect.
      4. User drilldown: click aspect → xem bài viết liên quan; click bài viết → xem full content + comments.
      5. Nếu không có đối thủ → ẩn phần Competitor Comparison.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - A1 (bước 4): User chọn "Xuất báo cáo" → UC-06.
      - E1 (bước 2): is_partial_result = true → hiển thị banner "Kết quả chưa đầy đủ" + nút "Chạy lại phân tích" (chỉ chạy lại analysis step, không crawl lại).
      - E2 (bước 2): Dữ liệu quá 90 ngày retention → hiển thị thông báo "Dữ liệu đã hết hạn lưu trữ (90 ngày), không thể xem chi tiết".
      - E3 (bước 2): Chỉ còn aggregated metadata (raw data đã cleanup) → hiển thị summary-only: KPIs tổng, sentiment overview, không có drilldown.
    ],
  )
]

=== UC-05: Quản lý danh sách Projects
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-05],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Quản lý danh sách Projects],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[-],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Xem, lọc, tìm kiếm Projects và điều hướng theo trạng thái.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: quản lý nhiều projects, tránh chỉnh sửa nhầm project đang chạy.
      - SMAP System: bảo vệ trạng thái (không cho sửa Running projects), hiển thị đúng owner.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [User đã đăng nhập.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [User mở màn "Projects" hoặc login vào hệ thống.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [Danh sách hiển thị với thao tác hợp lý theo trạng thái và ownership.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu thao tác bị chặn (do trạng thái/permission), hiển thị thông báo lỗi rõ ràng.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. User mở màn "Projects".
      2. Hệ thống hiển thị danh sách Projects của user với: tên, status (Draft/Running/Completed/Failed/Cancelled), thời gian tạo.
      3. User có thể: lọc theo status, tìm kiếm theo tên (case-insensitive, partial match), sắp xếp theo thời gian.
      4. User chọn một Project:
        - Draft → nút "Chỉnh sửa" (UC-01) và "Khởi chạy" (UC-03).
        - Running → nút "Xem tiến độ" (UC-03 bước 5-6) và "Hủy".
        - Completed/Failed/Cancelled → nút "Xem kết quả" (UC-04).
      5. User có thể soft-delete Project → hiển thị confirm; nếu đồng ý: đánh dấu deleted_at, ẩn khỏi danh sách, dữ liệu giữ 90 ngày.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - A1 (bước 4): User cố sửa Project Running → hệ thống chặn và thông báo "Không thể chỉnh sửa Project đang chạy".
      - A2 (bước 5): Xóa Project Running → hệ thống chặn và thông báo "Phải hủy Project trước khi xóa".
      - E1 (bước 5): Xóa Project thành công → cập nhật danh sách, hiển thị notification "Đã xóa Project, dữ liệu sẽ được giữ trong 90 ngày".
    ],
  )
]

=== UC-06: Xuất báo cáo
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-06],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Xuất báo cáo],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[-],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Tạo và tải file báo cáo phân tích.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: cần file báo cáo (PDF/PPTX/Excel) với nội dung tùy chọn.
      - SMAP System: sinh báo cáo trong thời gian hợp lý; fallback summary-only nếu quá nặng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [User đang xem Dashboard (UC-04); Project có dữ liệu (full hoặc partial).],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [User bấm "Xuất báo cáo" trên Dashboard.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [File báo cáo sinh thành công với metadata: analysis_version, export_time, filters, period, format.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu timeout (> 10 phút), thông báo lỗi và cho phép retry hoặc chọn summary-only.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. User chọn "Xuất báo cáo".
      2. User chọn: format (PDF/PPTX/Excel), nội dung (KPIs/Sentiment/Aspects/Competitor/Raw Data), period (toàn bộ hoặc custom range).
      3. User xác nhận.
      4. Hệ thống generate báo cáo async với progress indicator.
      5. Khi hoàn tất → cung cấp download link, gửi notification.
      6. User tải file báo cáo.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - E1 (bước 4): Timeout (> 10 phút) hoặc file > 100MB → hiển thị lỗi "Báo cáo quá lớn", cho phép: (a) Retry, (b) Chọn "Summary-only".
      - E2 (bước 2): Chọn "Summary-only" → báo cáo chỉ gồm: Executive Summary (1 trang), KPIs chính, Sentiment overview, Top 3 aspects, Top 3 insights. Kích thước: 5-10 slides PPTX hoặc 3-5 trang PDF.
      - E3 (bước 4): Dữ liệu đã quá retention 90 ngày → chỉ cho phép export summary-only từ aggregated metadata; nếu không có metadata → báo lỗi "Không thể xuất báo cáo".
    ],
  )
]

=== UC-07: Phát hiện trend tự động
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-07],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Phát hiện trend tự động],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[Social Media Platforms],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Cung cấp feed trends (nhạc/keywords/hashtags) được cập nhật định kỳ.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: nhận trends sớm, xếp hạng rõ ràng, không phải chạy thủ công.
      - SMAP System: tôn trọng rate-limit, lưu partial results nếu lỗi.
      - Social Media Platforms: được crawl ở mức hợp lý.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [Tính năng trend detection đã được bật trong system config; cron schedule đã được cấu hình (hàng ngày/hàng tuần); platforms có thể truy cập.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [Cron job trigger theo lịch đã cấu hình.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [TrendRun (run_id, timestamp, platforms, status=Completed) được tạo với top trends xếp hạng theo score; Marketing Analyst nhận notification.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu lỗi → TrendRun status=Failed, failure_reason ghi rõ; partial data được giữ (is_partial_result=true); user có thể xem phần đã thu thập.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. Cron job trigger theo lịch (ví dụ: 2AM hàng ngày).
      2. Hệ thống tạo TrendRun mới cho kỳ hiện tại.
      3. Gửi requests thu thập trending content (music/keywords/hashtags) từ YouTube và TikTok.
      4. Chuẩn hóa metadata: title, platform, timestamp, views, likes, shares, saves.
      5. Tính score dựa trên: engagement rate (likes+comments+shares / views) × velocity (growth rate trong 24h).
      6. Xếp hạng và lọc: top 50 trends/platform, loại trùng lặp, phân loại theo type (music/keyword/hashtag).
      7. Lưu TrendRun với status=Completed.
      8. Gửi notification cho all users có quyền: "Trends mới đã được cập nhật".
      9. Marketing Analyst mở Trend Dashboard, xem feed trends với filters: platform, type, date range, min_score.
      10. Marketing Analyst drilldown: click trend → xem chi tiết metadata và related posts.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - E1 (bước 3): Không có kết quả từ platform → lưu empty feed cho platform đó, ghi note "No trending content found".
      - E2 (bước 3): Rate-limit hoặc captcha → retry với backoff; nếu vẫn fail: skip platform đó, ghi partial, gửi warning notification.
      - E3 (bước 3): Platform error (network/API down) → bỏ qua platform đó, ghi partial, tiếp tục với platforms còn lại.
      - E4 (bước 2-6): Quá 2 giờ vẫn chưa xong → dừng, status=Failed, failure_reason=Timeout, is_partial_result=true, giữ dữ liệu đã thu.
      - E5 (bước 9): TrendRun gần nhất Failed (partial) → Dashboard hiển thị partial data với badge "Kết quả không đầy đủ", show platforms nào đã thu thập thành công.
    ],
  )
]

=== UC-08: Phát hiện khủng hoảng
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-08_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (1fr, 3fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case ID*],
    align(center + horizon)[UC-08],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Use Case Name*],
    align(center + horizon)[Phát hiện khủng hoảng],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Scope*],
    align(center + horizon)[SMAP System],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Level*],
    align(center + horizon)[User-goal],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Primary Actor*],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Secondary Actor*],
    align(center + horizon)[Social Media Platforms],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Goal*],
    [Nhận diện và cảnh báo sớm các tình huống khủng hoảng truyền thông cho thương hiệu.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Stakeholders & Interests*],
    [
      - Marketing Analyst: cần cảnh báo sớm, đánh giá mức độ nghiêm trọng, xem danh sách bài viết khủng hoảng.
      - SMAP System: phát hiện chính xác dựa trên NLP, phân loại risk level, gửi notification real-time.
      - Social Media Platforms: nguồn dữ liệu, không liên quan đến logic phát hiện.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    [Project đang chạy (UC-03) hoặc đã hoàn tất với dữ liệu; Analysis pipeline đã chạy xong (intent classification, sentiment analysis, impact calculation).],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    [
      - Trigger 1: Trong quá trình analyze (UC-03 bước 4.2) phát hiện bài viết crisis.
      - Trigger 2: User mở Crisis Dashboard từ Project đã hoàn tất.
    ],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Success Guarantee*],
    [Crisis alert được tạo với risk_level (CRITICAL/HIGH/MEDIUM/LOW); notification gửi đến Marketing Analyst; Crisis Dashboard hiển thị danh sách bài viết crisis xếp hạng theo impact_score.],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Minimal Guarantee*],
    [Nếu analysis lỗi → không có crisis detection; user nhận thông báo "Analysis failed, không thể phát hiện crisis".],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Main Flow*],
    [
      1. Analysis pipeline (UC-03 bước 4.2) chạy trên mỗi bài viết/comment:
        - Intent Classification: phát hiện intent = CRISIS (keywords: tẩy chay, lừa đảo, scam, boycott, độc hại, nguy hiểm).
        - Sentiment Analysis: xác định sentiment = NEGATIVE hoặc VERY_NEGATIVE.
        - Impact Calculation: tính impact_score (0-100) dựa trên:
          • Engagement: views, likes, comments, shares (weight 40%).
          • Reach: follower_count của tác giả, verified_status (weight 30%).
          • Virality: share_rate, comment_rate (weight 30%).
        - Risk Level: CRITICAL (score ≥ 80), HIGH (60-79), MEDIUM (40-59), LOW (< 40).
      2. Nếu phát hiện: intent=CRISIS AND sentiment=NEGATIVE/VERY_NEGATIVE AND risk_level≥MEDIUM:
        - Tạo CrisisAlert record: post_id, timestamp, risk_level, impact_score, platform, author, content_summary.
        - Gửi real-time notification:
          • In-app notification với priority=HIGH, màu đỏ.
          • Email alert với subject "🚨 Cảnh báo khủng hoảng - [Brand Name]".
          • Nội dung: risk level, platform, snippet, link xem chi tiết.
      3. Marketing Analyst nhận notification, click vào.
      4. Hệ thống mở Crisis Dashboard với:
        - Overview: tổng số crisis posts, phân bố theo risk_level, trend theo thời gian.
        - Crisis List: danh sách bài viết crisis sorted by impact_score (cao → thấp), hiển thị: title, platform, author, risk_level, impact_score, timestamp.
        - Filters: risk_level, platform, date_range.
        - Breakdown by Platform: chart showing crisis posts/platform.
        - Top Influencers: danh sách KOLs/verified accounts đang lan truyền crisis.
      5. Marketing Analyst drilldown: click bài viết → xem full content, comments, author profile.
      6. Marketing Analyst đánh giá và quyết định hành động (monitor, respond, escalate) - ngoài scope SMAP.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Extensions*],
    [
      - E1 (bước 2): Spike Detection - nếu số crisis posts tăng đột biến (> 5x average trong 1 giờ) → gửi thêm "Spike Alert" với priority=URGENT.
      - E2 (bước 3): User chưa đăng nhập → notification lưu trong inbox, gửi email alert.
      - E3 (bước 4): Không có crisis → Dashboard hiển thị "Không phát hiện khủng hoảng" với icon xanh.
      - E4 (bước 1): Analysis pipeline fail (model error) → không có crisis detection, ghi log error, thông báo admin.
      - E5 (bước 2): False positive (user report) → Marketing Analyst có thể "Dismiss alert", hệ thống ghi log để improve model.
    ],
  )
]
