// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.2 Yêu cầu chức năng (Functional Requirements)
#context (align(center)[_Bảng #table_counter.display(): Functional Requirements_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*ID*], [*Mô tả*],
    
    // FR-1: Cấu hình Project (UC-01)
    [FR-1.1], [Hệ thống cho phép tạo Project mới với thông tin cơ bản (tên, mô tả, khoảng thời gian). Tên: 3-100 ký tự, duy nhất trong phạm vi user. Thời gian theo dõi: tối thiểu 1 ngày, tối đa 1 năm.],
    [FR-1.2], [Cấu hình từ khóa thương hiệu (≥1, ≤10; mỗi từ khóa 2-50 ký tự).],
    [FR-1.3], [Cấu hình đối thủ (tối đa 5 đối thủ, mỗi đối thủ 1-5 từ khóa).],
    [FR-1.4], [Cấu hình từ khóa loại trừ (tối đa 20).],
    [FR-1.5], [Chọn nền tảng mạng xã hội (YouTube, TikTok, ...).],
    [FR-1.6], [Cấu hình giới hạn thu thập: ≤1000 bài viết/từ khóa/platform; ≤100 comments/bài viết.],
    [FR-1.7], [Lưu Project ở trạng thái Draft.],
    [FR-1.8], [Validate trước khi lưu (tên duy nhất, số lượng/độ dài từ khóa, chọn platform).],
    [FR-1.9], [Hiển thị thời gian xử lý ước tính dựa trên số từ khóa, số platform, số bài mong muốn.],
    
    // FR-2: Dry-run Từ khóa (UC-02)
    [FR-2.1], [Cho phép user dry-run từ khóa trước khi lưu Project.],
    [FR-2.2], [Thu thập mẫu 3 bài/từ khóa từ các platform đã chọn.],
    [FR-2.3], [Hiển thị mẫu với tiêu đề, nội dung tóm tắt, platform, views/likes.],
    [FR-2.4], [Xử lý trường hợp không có kết quả.],
    [FR-2.5], [Cho phép điều chỉnh từ khóa dựa trên kết quả dry-run.],
    
    // FR-3: Thực thi & Giám sát Project (UC-03)
    [FR-3.1], [Cho phép khởi chạy Project trạng thái Draft.],
    [FR-3.2], [Đổi trạng thái Project sang Running khi khởi chạy.],
    [FR-3.3], [Thực thi theo các pha: Crawling → Analyzing → Aggregating → Finalizing.],
    [FR-3.4], [Hiển thị tiến độ real-time: stage, %, thời gian, volume theo platform.],
    [FR-3.5], [Cho phép hủy Project đang chạy (status=Cancelled, giữ dữ liệu đã thu thập).],
    [FR-3.6], [Xử lý lỗi: status=Failed, failure_reason ∈ {CrawlFailed, AnalysisFailed, SystemFailed, Timeout}, giữ partial.],
    [FR-3.7], [Cho phép chạy lại Project đã Failed hoặc chạy lại pha phân tích trên dữ liệu thô.],
    [FR-3.8], [Đặt status=Completed khi hoàn tất.],
    [FR-3.9], [Thông báo user khi Project hoàn tất.],
    [FR-3.10], [Hỗ trợ re-run phân tích AI trên dữ liệu thô (cập nhật analysis_version, hiển thị kết quả mới).],
    
    // FR-4: Xem kết quả & So sánh (UC-04)
    [FR-4.1], [Hiển thị dashboard cho Project có has_result=true với KPI, sentiment trend, aspect, so sánh đối thủ (nếu có).],
    [FR-4.2], [Cho phép lọc và drilldown kết quả.],
    [FR-4.3], [Ẩn phần so sánh khi không cấu hình đối thủ.],
    [FR-4.4], [Hiển thị chỉ báo partial khi `is_partial_result=true`.],
    [FR-4.5], [Cho phép re-run AI phân tích đối với partial results.],
    [FR-4.6], [Tuân thủ retention: khi archived, chỉ hiển thị summary hoặc báo không khả dụng.],
    
    // FR-5: Quản lý danh sách Projects (UC-05)
    [FR-5.1], [Hiển thị danh sách Project của user kèm trạng thái.],
    [FR-5.2], [Lọc và tìm kiếm Project.],
    [FR-5.3], [Chỉnh sửa Project Draft.],
    [FR-5.4], [Chặn chỉnh sửa Project Running.],
    [FR-5.5], [Điều hướng theo trạng thái: Draft → UC-01, Running → UC-03, Completed/Failed/Cancelled → UC-04.],
    [FR-5.6], [Soft-delete Project (confirm, đánh dấu deleted, giữ lịch sử trong retention).],
    
    // FR-6: Xuất báo cáo (UC-06)
    [FR-6.1], [Cho phép xuất báo cáo từ dashboard.],
    [FR-6.2], [Hỗ trợ định dạng PDF, PPTX, Excel.],
    [FR-6.3], [Chọn nội dung và khoảng thời gian báo cáo.],
    [FR-6.4], [Gắn metadata: analysis_version, thời điểm export, bộ lọc, period, format.],
    [FR-6.5], [Cung cấp link tải báo cáo.],
    [FR-6.6], [Xử lý trường hợp báo cáo lớn/timeout; hỗ trợ summary-only.],
    [FR-6.7], [Summary-only gồm Executive Summary, KPIs, tổng quan Sentiment, top 3 aspects, top 3 insights.],
    
    // FR-7: Phát hiện trend tự động (UC-07)
    [FR-7.1], [Cho phép bật/lập lịch phát hiện trend tự động (daily/weekly hoặc chạy ngay).],
    [FR-7.2], [Tự động crawl nội dung trend (nhạc/từ khóa/hashtag) từ các platform đã chọn theo lịch.],
    [FR-7.3], [Chuẩn hóa metadata trend: tiêu đề, platform, thời gian, chỉ số tương tác.],
    [FR-7.4], [Tính score (engagement/velocity) và xếp hạng trend.],
    [FR-7.5], [Lưu mỗi lần chạy dưới dạng TrendRun (thời gian chạy, platform, score, is_partial_result khi cần).],
    [FR-7.6], [Thông báo Brand Manager khi có feed trend mới.],
    [FR-7.7], [Cung cấp Trend Dashboard để xem danh sách trend đã xếp hạng.],
  )
]
