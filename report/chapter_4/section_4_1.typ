// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.1 Nhu cầu người dùng hệ thống (User Story)
Dựa trên kết quả khảo sát về thị hiếu người dùng và phân tích quy trình nghiệp vụ Marketing trong thực tế, nhóm tác giả đã xác định các tác nhân chính tương tác với hệ thống, qua đó làm rõ phạm vi, vai trò và trách nhiệm của từng đối tượng trong quá trình vận hành SMAP.
// === 4.1.1 Các bên liên quan & vai trò (Stakeholders & Roles)
#context (align(center)[_Bảng #table_counter.display(): Danh sách Tác nhân_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 0.6fr, 1fr),
    stroke: 0.5pt,

    // --- HÀNG TIÊU ĐỀ (Đã tăng chiều cao) ---
    // Sử dụng table.cell với inset: (y: 1em) để tăng khoảng đệm trên/dưới
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actor ID*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actor (Tác nhân)*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Vai trò chính (Role)*],

    // --- CÁC HÀNG DỮ LIỆU ---
    align(center + horizon)[A-01],
    align(center + horizon)[Marketing Analyst],
    [
      Người sử dụng chính của hệ thống. \
      Mục tiêu:
      - Theo dõi danh tiếng thương hiệu trên mạng xã hội
      - So sánh với đối thủ cạnh tranh
      - Phát hiện sớm khủng hoảng
    ],

    align(center + horizon)[A-02],
    align(center + horizon)[Social Media Platforms \
      (Nền tảng mạng xã hội)],
    [
      Hệ thống bên ngoài cung cấp dữ liệu \
      Đặc điểm:
      - Nằm ngoài boundary SMAP
      - SMAP thu thập dữ liệu công khai bằng web scraping và kết hợp với sử dụng API chính thức
      - Có thể giới hạn tốc độ truy cập (rate-limit)
    ],
  )
]
