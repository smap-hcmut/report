#import "../counters.typ": image_counter, table_counter

== 4.1 Nhóm người dùng và tác nhân hệ thống

Trong phạm vi của SMAP, việc xác định tác nhân hệ thống không dựa trên kết quả khảo sát người dùng trực tiếp, mà được tổng hợp từ phạm vi ứng dụng đã nêu ở Chương 1, từ nhóm chức năng của hệ thống, và từ các luồng tương tác. Cách tiếp cận này giúp xác định rõ ai là người sử dụng chính của hệ thống, đâu là các tác nhân bên ngoài, và mỗi tác nhân tương tác với SMAP theo vai trò nào.

Nhìn ở mức tổng quát, SMAP phục vụ trước hết cho các nhóm người dùng chuyên môn nội bộ có nhu cầu theo dõi, phân tích và tổng hợp thông tin từ mạng xã hội. Bên cạnh đó, hệ thống còn phụ thuộc vào một số tác nhân kỹ thuật bên ngoài như nền tảng mạng xã hội là nguồn dữ liệu đầu vào và nhà cung cấp định danh hỗ trợ xác thực người dùng.

#context (align(center)[_Bảng #table_counter.display(): Danh sách tác nhân hệ thống_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 0.9fr, 1.2fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Actor ID*],
    table.cell(align: center + horizon)[*Tác nhân*],
    table.cell(align: center + horizon)[*Vai trò chính*],

    align(center + horizon)[A-01],
    align(center + horizon)[Nhóm người dùng chuyên môn nội bộ],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Đây là nhóm người dùng chính của hệ thống, bao gồm các vai trò như chuyên viên phân tích dữ liệu truyền thông xã hội, bộ phận theo dõi thương hiệu, marketing, nghiên cứu thị trường, truyền thông và các cấp quản lý. \

      Nhóm tác nhân này sử dụng SMAP để:
      - cấu hình và quản lý project theo dõi;
      - theo dõi trạng thái xử lý và kết quả phân tích;
      - tra cứu, tổng hợp và khai thác thông tin theo ngữ cảnh;
      - nhận thông báo hoặc cảnh báo phục vụ đánh giá và ra quyết định.
    ],

    align(center + horizon)[A-02],
    align(center + horizon)[Nền tảng mạng xã hội],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Đây là tác nhân bên ngoài cung cấp dữ liệu đầu vào cho hệ thống. \

      Vai trò của tác nhân này gồm:
      - là nguồn phát sinh bài đăng, bình luận và tín hiệu mạng xã hội;
      - tạo ra các ràng buộc truy cập dữ liệu như giới hạn truy cập, thay đổi cấu trúc nền tảng hoặc giới hạn kỹ thuật khác;
      - ảnh hưởng trực tiếp đến khả năng thu thập, cập nhật và chuẩn hóa dữ liệu của hệ thống.
    ],

    align(center + horizon)[A-03],
    align(center + horizon)[Nhà cung cấp định danh],
    table.cell(align: horizon, inset: (y: 0.6em))[
      Đây là tác nhân hỗ trợ xác thực người dùng thông qua cơ chế OAuth2. \

      Vai trò của tác nhân này gồm:
      - xác nhận danh tính người dùng trong bước đăng nhập ban đầu;
      - cung cấp thông tin định danh cần thiết để thiết lập phiên truy cập;
      - làm đầu vào cho lớp xác thực của hệ thống trước khi người dùng sử dụng các chức năng nghiệp vụ.
    ],
  )
]
