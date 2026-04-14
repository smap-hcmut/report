// Chapter 0: Phần mở đầu (Lời cam đoan, Lời cảm ơn, Tóm tắt)

// ============= LỜI CAM ĐOAN =============
#align(center)[
  *LỜI CAM ĐOAN*
]

#v(2em)

Chúng tôi cam đoan đồ án chuyên ngành với đề tài “Xây dựng hệ thống SMAP – Social Media Analytics Platform” là công trình nghiên cứu độc lập của nhóm tác giả, được thực hiện dưới sự hướng dẫn của thầy Lê Đình Thuận. Toàn bộ nội dung nghiên cứu và các kết quả trình bày trong đồ án đều trung thực, là công sức của chính nhóm thực hiện và chưa từng được công bố trong bất kỳ công trình nào tại các cơ sở đào tạo khác. Mọi số liệu, bảng biểu và thông tin tham khảo từ các nguồn bên ngoài đều được trích dẫn rõ ràng, đầy đủ theo đúng quy định về sở hữu trí tuệ. Chúng tôi xin hoàn toàn chịu trách nhiệm trước hội đồng và nhà trường nếu phát hiện có bất kỳ hành vi gian lận hoặc sao chép không hợp lệ nào liên quan đến đồ án này.
#v(4em)

#align(right)[
  #grid(
    columns: 1,
    row-gutter: 1em,
    [_Thành phố Hồ Chí Minh, ngày 21 tháng 12 năm 2025_],
    [_Sinh viên thực hiện_],
    [Nguyễn Tấn Tài],
    [Đặng Quốc Phong],
    [Nguyễn Chánh Tín],
  )
]

#pagebreak()

// ============= LỜI CẢM ƠN =============
#align(center)[
  *LỜI CẢM ƠN*
]


Trước tiên, chúng tôi xin gửi lời cảm ơn chân thành đến quý thầy/cô trong Khoa Khoa học Và Kỹ thuật Máy tính, Trường Đại học Bách Khoa - Đại học Quốc gia TP.HCM, những người đã tận tình truyền đạt kiến thức và tạo điều kiện thuận lợi cho em trong suốt quá trình học tập.

Đặc biệt, em xin bày tỏ lòng biết ơn sâu sắc đến thầy Lê Đình Thuận, người đã hướng dẫn, động viên và đóng góp nhiều ý kiến quý báu trong suốt quá trình thực hiện đề tài này. Sự chỉ bảo tận tâm của thầy đã giúp chúng em hoàn thành tốt báo cáo này.

Em xin chân thành cảm ơn!


#pagebreak()

// ============= TÓM TẮT ĐỀ TÀI =============
#align(center)[
  *TÓM TẮT ĐỀ TÀI*
]

Đề tài tập trung xây dựng hệ thống SMAP - Social Media Analytics Platform  nhằm hỗ trợ phân tích dữ liệu mạng xã hội phục vụ hoạt động marketing. Trọng tâm của đồ án không nằm ở việc nghiên cứu thuật toán học máy chuyên sâu, mà tập trung vào bài toán thiết kế kiến trúc phần mềm, tổ chức luồng xử lý dữ liệu và đảm bảo khả năng vận hành ổn định trong bối cảnh dữ liệu lớn và thay đổi liên tục.

Hệ thống được định hướng như một nền tảng phục vụ nhu cầu vận hành và khai thác thông tin trong phạm vi nội bộ, hỗ trợ thu thập, xử lý, phân tích và tổng hợp dữ liệu từ các nguồn mạng xã hội nhằm cung cấp thông tin có giá trị cho việc theo dõi thương hiệu, nhận diện xu hướng và hỗ trợ ra quyết định. Trên cơ sở đó, đồ án tập trung vào việc phân tích yêu cầu, thiết kế kiến trúc và hiện thực các thành phần kỹ thuật chính của hệ thống theo hướng phân tách nhiều dịch vụ với các vai trò chuyên biệt như quản lý ngữ cảnh nghiệp vụ, điều phối thu thập dữ liệu, xử lý phân tích, truy hồi tri thức và thông báo thời gian thực.

Kết quả đạt được là một hệ thống có cấu trúc rõ ràng, tạo nền tảng thuận lợi cho việc phát triển, bảo trì và mở rộng trong các giai đoạn tiếp theo. Đồng thời, báo cáo cũng hệ thống hóa các quyết định thiết kế quan trọng, các thành phần kỹ thuật cốt lõi và các luồng xử lý dữ liệu chính trong hệ thống.
