// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.5 Đặc tả Use Case

=== UC-01: Cấu hình Project theo dõi
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-01],
    [*Use Case Name*], [Cấu hình Project theo dõi],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [-],
    [*Goal*], [Tạo cấu hình Project theo dõi thương hiệu/đối thủ và lưu ở trạng thái Draft.],
    [*Stakeholders & Interests*], [
      - Brand Manager: cấu hình nhanh, validate rõ, có dry-run trước khi lưu.
      - SMAP System: đảm bảo ràng buộc số lượng project/keyword/platform; lưu an toàn; bảo mật theo user.
    ],
    [*Preconditions*], [User đăng nhập; user có quyền tạo project (không vượt BR1).],
    [*Trigger*], [User chọn "Tạo Project mới" từ màn Projects.],
    [*Success Guarantee*], [Project lưu status = Draft, sẵn sàng khởi chạy UC-03.],
    [*Minimal Guarantee*], [Nếu lỗi, hệ thống thông báo và giữ dữ liệu đã nhập để retry.],
    [*Main Flow*], [
      1. User chọn "Tạo Project mới".
      2. Nhập thông tin cơ bản (tên/mô tả/khoảng thời gian).
      3. Nhập thương hiệu + keyword + exclude keyword (optional).
      4. Thêm đối thủ (optional).
      5. Chọn platform và cấu hình thu thập.
      6. Hệ thống hiển thị tổng quan cấu hình.
      7. User chọn: (a) Dry-run → UC-02 hoặc (b) Lưu Project.
      8. Hệ thống validate và lưu Project Draft.
      9. Hệ thống thông báo lưu thành công, điều hướng về quản lý Projects.
    ],
    [*Extensions*], [
      - A1 (bước 2–5) Validation errors: tên trùng; thiếu keyword; keyword quá ngắn; quá 5 đối thủ; không chọn platform → báo lỗi yêu cầu sửa.
      - A2 (bước 7) Dry-run: user chọn dry-run → UC-02; sau đó quay lại chỉnh keyword hoặc lưu.
      - A3 (bước 8) Storage/System error: lưu thất bại → báo lỗi, giữ draft input, cho retry.
    ],
  )
]

=== UC-02: Kiểm tra từ khóa (Dry-run)
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-02],
    [*Use Case Name*], [Kiểm tra từ khóa (Dry-run)],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [Social Media Platforms],
    [*Goal*], [Kiểm tra chất lượng từ khóa trước khi lưu Project.],
    [*Stakeholders & Interests*], [
      - Brand Manager: muốn thấy mẫu kết quả để chỉnh từ khóa, tránh thu thập sai.
      - SMAP System: tôn trọng rate-limit, cung cấp feedback rõ ràng (có thể 0 kết quả).
      - Social Media Platforms: có rate-limit/captcha, không bị spam.
    ],
    [*Preconditions*], [Ở bước cấu hình từ khóa (UC-01); user đăng nhập.],
    [*Trigger*], [User bấm "Dry-run" trong cấu hình từ khóa.],
    [*Success Guarantee*], [Hiển thị mẫu kết quả (có thể 0) hoặc thông báo "Không có kết quả"; user có cơ sở chỉnh từ khóa.],
    [*Minimal Guarantee*], [Nếu bị chặn/rate-limit, hệ thống thông báo không thể lấy mẫu lúc này.],
    [*Main Flow*], [
      1. User bấm "Dry-run".
      2. Hệ thống xác nhận, bắt đầu dry-run.
      3. Thu thập mẫu (3 bài/từ khóa) từ platforms.
      4. Hiển thị mẫu (title, content, platform, views/likes).
      5. User đánh giá và điều chỉnh nếu cần.
      6. User chọn chấp nhận (quay UC-01 bước 6) hoặc chỉnh (UC-01 bước 3).
    ],
    [*Extensions*], [
      - A1: Không có kết quả → quay lại bước 1.
      - A2: Kết quả không liên quan → quay lại bước 1/UC-01 bước 3 chỉnh từ khóa.
      - E1: Rate-limit/captcha → thông báo "Không thể lấy mẫu lúc này", gợi ý thử lại/giảm từ khóa.
    ],
  )
]

=== UC-03: Khởi chạy và theo dõi Project
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-03],
    [*Use Case Name*], [Khởi chạy và theo dõi Project],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal level],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [Social Media Platforms (YouTube, TikTok, …)],
    [*Goal*], [Run-to-completion một Project (thu thập + phân tích + theo dõi tiến độ)],
    [*Stakeholders & Interests*], [
      - Brand Manager: muốn chạy project, thấy tiến độ rõ, nhận cảnh báo khủng hoảng, có kết quả full/partial.
      - SMAP System: tuân thủ timeout, rate-limit, lưu partial khi có sự cố.
      - Social Media Platforms: có rate-limit/captcha; SMAP truy cập hợp lý (không dùng API chính thức).
    ],
    [*Preconditions*], [User đăng nhập; Project tồn tại, status = Draft; user là owner (BR-VISIBILITY-01).],
    [*Trigger*], [User nhấn "Khởi chạy Project" từ màn Projects.],
    [*Success Guarantee*], [Project status = Completed, dữ liệu thu thập + phân tích sẵn sàng cho UC-04.],
    [*Minimal Guarantee*], [Nếu lỗi/dừng giữa chừng → status = Failed hoặc Cancelled; nếu status=Failed thì failure_reason được ghi nhận (bao gồm Timeout theo BR-TIMEOUT-01); dữ liệu thô giữ lại (partial) trong retention window để xem/ retry / re-analyze.],
    [*Main Flow*], [
      1. User mở Projects.
      2. Hệ thống hiển thị danh sách Projects + trạng thái.
      3. User chọn Project status = Draft.
      4. User nhấn "Khởi chạy Project".
      5. Hệ thống xử lý: 
        - 5.1 Running;
        - 5.2 Crawling từ platforms;
        - 5.3 Analyzing (sentiment/aspect/metrics);
        - 5.4 Aggregating/Finalizing.
      6. Hiển thị thông báo "Project đang chạy…".
      7. User mở chi tiết Project đang chạy.
      8. Hệ thống hiển thị/auto-update stage (Crawling/Analyzing/Aggregating/Finalizing), tiến độ %, thời gian, volume theo platform, cảnh báo khủng hoảng.
      9. Khi xong:
        - 9.1 status = Completed;
        - 9.2 thông báo user.
      10. User điều hướng UC-04 xem kết quả.
    ],
    [*Extensions*], [
      - E1 (bước 7–8) Hủy: confirm → status=Cancelled, giữ dữ liệu, kết thúc.
      - E2 (bước 3) Retry Failed: "Chạy lại" → bước 5; hoặc "Chỉnh sửa" → UC-01.
      - E3 (bước 5/8) Crisis: phát hiện crisis → gửi cảnh báo, cho xem ngay; luồng chính tiếp tục.
      - E4 (bước 5–8) Lỗi hệ thống/crawl/analysis: status=Failed, failure_reason=CrawlFailed|AnalysisFailed|SystemFailed; giữ partial; thông báo lỗi; kết thúc.
      - E5 (bước 7–8) Re-run phân tích: đã có dữ liệu thô, AnalysisFailed/NeedReAnalyze → chạy lại phân tích, cập nhật analysis_version, hiển thị kết quả mới.
      - E6 (bước 5–8, BR-TIMEOUT-01) Timeout >2h, status=Failed, failure_reason=Timeout, is_partial_result=true, giữ dữ liệu đã thu thập.
    ],
  )
]

=== UC-04: Xem kết quả phân tích và so sánh
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-04],
    [*Use Case Name*], [Xem kết quả phân tích và so sánh],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [-],
    [*Goal*], [Xem dashboard kết quả (full/partial), so sánh đối thủ.],
    [*Stakeholders & Interests*], [
      - Brand Manager: cần insight, có cảnh báo, biết partial/full.
      - SMAP System: hiển thị đúng dữ liệu còn khả dụng, tôn trọng retention.
    ],
    [*Preconditions*], [Project có has_result=true; user đăng nhập và là owner.],
    [*Trigger*], [User mở Project có has_result=true (Completed/Failed/Cancelled).],
    [*Success Guarantee*], [Dashboard hiển thị metrics/sentiment/aspect/compare theo dữ liệu hiện có (full hoặc partial).],
    [*Minimal Guarantee*], [Nếu thiếu/archived dữ liệu → thông báo, không hiển thị chi tiết hoặc chỉ hiển thị summary.],
    [*Main Flow*], [
      1. User mở Project có kết quả/partial (Completed/Failed/Cancelled).
      2. Hệ thống hiển thị dashboard (KPIs, sentiment trend, aspect, competitor compare).
      3. User lọc/drilldown/xuất báo cáo.
      4. Nếu không có đối thủ → ẩn phần so sánh.
    ],
    [*Extensions*], [
      - A1 (bước 3): User chọn "Xuất báo cáo" → UC-06.
      - E1 (bước 2): Dữ liệu archived/xóa → thông báo (BR-RETENTION-01), hướng dẫn restore/không xem chi tiết; nếu chỉ còn metadata/aggregated artifacts → hiển thị summary-only, nếu không có artifacts → báo "không khả dụng".
      - E2 (bước 2): Partial (`is_partial_result=true`) → banner + nút "Chạy lại phân tích AI" (UC-03 E5).
    ],
  )
]

=== UC-05: Quản lý danh sách Projects
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-05],
    [*Use Case Name*], [Quản lý danh sách Projects],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [-],
    [*Goal*], [Xem/lọc/tìm/chỉnh sửa Project (Draft), điều hướng xem/kết quả.],
    [*Stakeholders & Interests*], [
      - Brand Manager: quản lý chiến dịch, tránh chỉnh sửa nhầm project đang chạy.
      - SMAP System: bảo vệ trạng thái (không sửa Running), tôn trọng visibility.
    ],
    [*Preconditions*], [User đăng nhập; có Projects.],
    [*Trigger*], [User mở màn "Projects".],
    [*Success Guarantee*], [Danh sách hiển thị; các thao tác hợp lệ (lọc/tìm/điều hướng/soft-delete/chỉnh sửa Draft) thực hiện được theo quyền & trạng thái.],
    [*Minimal Guarantee*], [Nếu thao tác bị chặn (do trạng thái/permission), hệ thống báo lỗi; dữ liệu không đổi.],
    [*Main Flow*], [
      1. User mở "Projects".
      2. Hệ thống hiển thị danh sách + trạng thái.
      3. User lọc/tìm kiếm.
      4. User chọn một Project:
         - Nếu Draft → chỉnh sửa (UC-01).
         - Nếu Running/Completed/Failed → điều hướng UC-03/UC-04.
      5. User có thể soft-delete; hệ thống xác nhận.
    ],
    [*Extensions*], [
      - A1: Sửa Project đang Running → hệ thống chặn và thông báo.
      - E1: Xóa Project → confirm; nếu đồng ý, soft-delete và cập nhật danh sách.
    ],
  )
]

=== UC-06: Xuất báo cáo
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-06],
    [*Use Case Name*], [Xuất báo cáo],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [-],
    [*Goal*], [Sinh và tải báo cáo phân tích.],
    [*Stakeholders & Interests*], [
      - Brand Manager: cần file báo cáo (PDF/PPTX/Excel) với nội dung lựa chọn.
      - SMAP System: sinh báo cáo trong giới hạn thời gian/kích thước; fallback khi quá nặng.
    ],
    [*Preconditions*], [User đã xem kết quả (UC-04); Project có dữ liệu (full/partial).],
    [*Trigger*], [User bấm "Xuất báo cáo" trên Dashboard (UC-04).],
    [*Success Guarantee*], [File báo cáo sinh thành công, gắn metadata (analysis_version, thời điểm export, filters/period, format).],
    [*Minimal Guarantee*], [Nếu quá thời gian/kích thước, thông báo lỗi và cho phép retry/summary-only.],
    [*Main Flow*], [
      1. User chọn "Xuất báo cáo".
      2. User chọn format/nội dung/period.
      3. User xác nhận.
      4. Hệ thống generate báo cáo theo lựa chọn.
      5. Cung cấp file download.
    ],
    [*Extensions*], [
      - E1: Timeout/file quá lớn → báo lỗi, cho retry hoặc chọn "summary-only"; summary-only = Executive Summary + KPIs + Sentiment tổng quan + top 3 aspects + 3 insights (không drilldown).
      - E2: Dữ liệu đã archived (BR-RETENTION-01) → chỉ cho phép export summary-only hoặc báo không khả dụng (tùy cấu hình triển khai).
    ],
  )
]

=== UC-07: Phát hiện trend tự động
#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*Use Case ID*], [UC-07],
    [*Use Case Name*], [Phát hiện trend tự động],
    [*Scope*], [SMAP System],
    [*Level*], [User-goal],
    [*Primary Actor*], [Brand Manager],
    [*Secondary Actor*], [Social Media Platforms],
    [*Goal*], [Cung cấp và cho phép Brand Manager xem feed trend (nhạc/từ khóa/hashtag) được cập nhật theo lịch.],
    [*Stakeholders & Interests*], [
      - Brand Manager: nhận trend sớm, xếp hạng rõ, không phải chạy thủ công.
      - SMAP System: tôn trọng rate-limit, tránh spam, lưu kết quả partial nếu gặp sự cố.
      - Social Media Platforms: được crawl ở mức hợp lý.
    ],
    [*Preconditions*], [Tính năng phát hiện trend đã được bật hoặc Brand Manager có quyền "Chạy ngay"; user đăng nhập và là owner để xem kết quả; platforms có thể truy cập. Kết quả mỗi lần chạy được lưu thành một TrendRun (run_id, time_window, platforms, status, is_partial_result, failure_reason).],
    [*Trigger*], [Đến kỳ chạy theo lịch đã cấu hình hoặc user chọn "Chạy ngay".],
    [*Success Guarantee*], [Feed trend cho kỳ chạy được tạo và lưu (TrendRun status = Completed), có top danh sách theo score, Brand Manager được thông báo và có thể truy cập xem feed trend.],
    [*Minimal Guarantee*], [Nếu lỗi/timeout/rate-limit → TrendRun status = Failed, failure_reason set; dữ liệu thu thập được giữ lại (is_partial_result=true); UI hiển thị "Failed (Partial)" và cho phép Brand Manager xem phần đã thu thập.],
    [*Main Flow*], [
      1. Đến kỳ chạy theo lịch phát hiện trend đã cấu hình hoặc user chọn "Chạy ngay".
      2. Hệ thống bắt đầu phiên chạy TrendRun cho kỳ hiện tại.
      3. Gửi truy vấn trend/từ khóa/hashtag/nhạc tới các platforms được bật.
      4. Thu thập và chuẩn hóa metadata (title, platform, thời gian, views/likes/shares).
      5. Tính score và xếp hạng (theo engagement/velocity).
      6. Gộp/loại trùng, phân loại theo loại trend (nhạc/từ khóa/hashtag).
      7. Lưu feed trend, gắn kỳ chạy và platform; áp dụng giới hạn tối đa N trend items/platform theo BR-TREND-LIMIT-01.
      8. Thông báo Brand Manager có feed trend mới; cung cấp link xem (Trend Dashboard).
      9. Brand Manager mở và xem feed trend trên Trend Dashboard.
    ],
    [*Extensions*], [
      - E1: Không có kết quả → lưu feed trống, ghi chú "Không có trend phù hợp kỳ này".
      - E2: Rate-limit/captcha → đánh dấu partial, đề xuất giảm tần suất/lịch.
      - E3: Platform lỗi/không truy cập → bỏ qua platform đó, ghi lại partial và cảnh báo.
      - E4 (BR-TIMEOUT-01): Timeout >2h → dừng, status=Failed, failure_reason=Timeout, is_partial_result=true, giữ dữ liệu thu được.
      - E5: Nếu TrendRun gần nhất Failed (partial) → Trend Dashboard hiển thị phần dữ liệu đã thu được, gắn badge "Failed (Partial)".
    ],
  )
]
