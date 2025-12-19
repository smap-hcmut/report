// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.3 Yêu cầu phi chức năng (Non-Functional Requirements)
#context (align(center)[_Bảng #table_counter.display(): Non-Functional Requirements_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*ID*], [*Mô tả*],
    
    // NFR-1: Hiệu năng
    [NFR-1.1], [Thời gian xử lý Project tối đa 2 giờ (BR-TIMEOUT-01); quá hạn → status=Failed, failure_reason=Timeout, is_partial_result=true, giữ dữ liệu đã thu thập trong retention.],
    [NFR-1.2], [Hiển thị tiến độ real-time trong quá trình thực thi.],
    [NFR-1.3], [Xử lý rate-limit từ platform (retry, backoff, thông báo phù hợp).],
    [NFR-1.4], [Sinh báo cáo trong giới hạn thời gian hợp lý; nếu vượt → timeout/summary-only (BR-EXPORT-TIMEOUT-01).],
    
    // NFR-2: Khả năng mở rộng
    [NFR-2.1], [Mỗi user tối đa 10 projects trong retention window (Running + Completed + Failed/Cancelled nếu has_result=true; Draft không tính).],
    [NFR-2.2], [Hỗ trợ thu thập: ≤1000 bài viết/từ khóa/platform; ≤100 comments/bài viết.],
    [NFR-2.3], [Hỗ trợ đa nền tảng: YouTube, TikTok (hiện tại); Facebook, Instagram, Twitter/X (tương lai).],
    
    // NFR-3: Bảo mật & Quyền riêng tư
    [NFR-3.1], [Dữ liệu chỉ hiển thị cho chủ sở hữu (BR-VISIBILITY-01).],
    [NFR-3.2], [Chỉ thu thập nội dung công khai.],
    [NFR-3.3], [Không thu thập PII nhạy cảm.],
    [NFR-3.4], [Yêu cầu xác thực cho mọi thao tác.],
    [NFR-3.5], [Kiểm tra quyền sở hữu trước khi cho phép thao tác trên Project.],
    
    // NFR-4: Quản lý dữ liệu
    [NFR-4.1], [Thời gian lưu trữ 90 ngày (BR-RETENTION-01); sau đó archive hoặc xóa tùy gói.],
    [NFR-4.2], [Giữ partial results khi lỗi/timeout.],
    [NFR-4.3], [Quản lý phiên bản phân tích (analysis_version); hỗ trợ re-run với model mới.],
    [NFR-4.4], [Soft-delete giữ lịch sử, cho phép khả năng khôi phục trong retention.],
    [NFR-4.5], [Cho phép export dữ liệu bất cứ lúc nào (theo gói).],
    
    // NFR-5: Độ tin cậy
    [NFR-5.1], [Xử lý lỗi nền tảng: rate-limit, captcha, lỗi kết nối.],
    [NFR-5.2], [Bảo toàn dữ liệu đã thu thập khi có lỗi.],
    [NFR-5.3], [Cung cấp thông báo lỗi rõ ràng kèm failure_reason.],
    [NFR-5.4], [Hỗ trợ retry cho Project Failed.],
    [NFR-5.5], [Hỗ trợ re-run phân tích AI độc lập với thu thập dữ liệu.],
    
    // NFR-6: Khả dụng (Usability)
    [NFR-6.1], [Cho phép dry-run trước khi chạy thật.],
    [NFR-6.2], [Hiển thị thời gian xử lý ước tính trước khi khởi chạy.],
    [NFR-6.3], [Hiển thị tiến độ real-time khi thực thi.],
    [NFR-6.4], [Gửi cảnh báo khủng hoảng trong quá trình chạy.],
    [NFR-6.5], [Hiển thị rõ partial results bằng visual indicator/badge.],
    [NFR-6.6], [Xác nhận thao tác huỷ/xóa (destructive actions).],
    [NFR-6.7], [Điều hướng rõ ràng giữa các trạng thái Project.],
    
    // NFR-7: Khả trì
    [NFR-7.1], [Dễ dàng thêm platform mới mà không refactor lớn.],
    [NFR-7.2], [Phân tách rõ: thu thập (crawl) / phân tích (AI) / trình bày (dashboard).],
    [NFR-7.3], [Phiên bản hóa kết quả AI để hỗ trợ cập nhật model.],
    
    // NFR-8: Tuân thủ
    [NFR-8.1], [Tôn trọng rate-limit và chính sách truy cập công khai của nền tảng (BR-RATE-LIMIT-01, BR-COMPLIANCE-01).],
    [NFR-8.2], [Chỉ thu thập dữ liệu công khai (BR-COMPLIANCE-01).],
    [NFR-8.3], [Thực thi chính sách retention (BR-RETENTION-01).],
    [NFR-8.4], [Cung cấp khả năng export dữ liệu theo quyền sở hữu.],
  )
]
