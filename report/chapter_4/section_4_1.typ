// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

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
    [A-01], [Marketing Analyst], [
      Người sử dụng chính của hệ thống. Mục tiêu:
      - Theo dõi danh tiếng thương hiệu trên mạng xã hội
      - So sánh với đối thủ cạnh tranh
      - Phát hiện sớm khủng hoảng
    ],
    [A-02], [Social Media Platforms (Nền tảng mạng xã hội)], [
      Hệ thống bên ngoài cung cấp dữ liệu
      Đặc điểm:
      - Nằm ngoài boundary SMAP
      - SMAP thu thập dữ liệu công khai bằng web scraping và kết hợp với sử dụng API chính thức
      - Có thể giới hạn tốc độ truy cập (rate-limit)
    ],
  )
]

=== 4.1.2 Business Rules
#context (align(center)[_Bảng #table_counter.display(): Business Rules_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),
    [*ID*], [*Mô tả*],
    [BR-RETENTION-01], [Dữ liệu được lưu trữ 90 ngày, sau đó archive/xóa tùy gói dịch vụ.],
    [BR-TIMEOUT-01], [Nếu xử lý vượt 2 giờ → hệ thống dừng, đánh dấu `is_partial_result=true`, set status=Failed, failure_reason=Timeout, giữ dữ liệu đã thu thập.],
    [BR-VISIBILITY-01], [Dữ liệu và Project chỉ visible với chủ sở hữu.],
    [BR-RATE-LIMIT-01], [Crawl chịu rate-limit/captcha từ platform; có thể cần retry/backoff (thể hiện qua thông báo lỗi).],
    [BR-TREND-LIMIT-01], [Mỗi kỳ TrendRun trả về tối đa N trend items/platform (N tùy gói dịch vụ).],
    [BR-EXPORT-TIMEOUT-01], [Sinh báo cáo tối đa X phút/format; quá giới hạn → timeout (áp dụng UC-06 E1).],
    [BR-COMPLIANCE-01], [Chỉ crawl dữ liệu công khai, tôn trọng chính sách truy cập công khai và rate-limit của nền tảng, không bypass captcha, không thu thập PII nhạy cảm.],
  )
]
