#import "../counters.typ": image_counter, table_counter

== 4.1 Nhu cầu người dùng hệ thống
Dựa trên kết quả khảo sát về thị hiếu người dùng và phân tích quy trình nghiệp vụ Marketing trong thực tế, nhóm tác giả đã xác định các tác nhân chính tương tác với hệ thống, qua đó làm rõ phạm vi, vai trò và trách nhiệm của từng đối tượng trong quá trình vận hành SMAP.

#context (align(center)[_Bảng #table_counter.display(): Danh sách Tác nhân_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 0.7fr, 1fr),
    stroke: 0.5pt,

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Actor ID*],
    table.cell(align: center + horizon)[*Actor (Tác nhân)*],
    table.cell(align: center + horizon)[*Vai trò chính (Role)*],

    align(center + horizon)[A-01],
    align(center + horizon)[Marketing Analyst],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Người sử dụng chính. \

      Đặc điểm:
      - Chuyên gia 2-5 năm kinh nghiệm.
      - Làm việc tại Agency/FMCG.

      Pain points:
      - Thu thập dữ liệu thủ công, rời rạc.
      - Khó phát hiện khủng hoảng sớm.

      Mục tiêu:
      - Theo dõi danh tiếng thương hiệu.
      - So sánh đối thủ cạnh tranh.
    ],

    align(center + horizon)[A-02],
    align(center + horizon)[Social Media Platforms \ (Nền tảng mạng xã hội)],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Hệ thống bên ngoài (External Actor). \

      Đặc điểm:
      - Nằm ngoài boundary SMAP.
      - Cung cấp dữ liệu thô.

      Phương thức:
      - Web scraping.
      - API chính thức.

      Ràng buộc:
      - Giới hạn tốc độ truy cập.
    ],
  )
]

#pagebreak()
