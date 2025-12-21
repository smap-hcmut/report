// Chapter 0: Phần mở đầu (Lời cam đoan, Lời cảm ơn, Tóm tắt)

// ============= LỜI CAM ĐOAN =============
#align(center)[
  *LỜI CAM ĐOAN*
]

#v(2em)

Chúng em xin cam đoan luận văn tốt nghiệp với đề tài "Xây dựng hệ thống SMAP - Social Media Analytics Platform" là công trình nghiên cứu độc lập của nhóm tác giả dưới sự hướng dẫn của thầy Lê Đình Thuận. Các nội dung nghiên cứu và kết quả được trình bày trong luận văn là trung thực, là công sức của chính nhóm thực hiện và chưa từng được công bố trong bất kỳ công trình nào tại các cơ sở đào tạo khác. Mọi số liệu, bảng biểu và thông tin tham khảo từ các nguồn khác đều được trích dẫn nguồn gốc rõ ràng, đầy đủ theo quy định về sở hữu trí tuệ. Chúng em xin chịu hoàn toàn trách nhiệm trước hội đồng và nhà trường nếu phát hiện có bất kỳ sự gian lận hoặc sao chép không hợp lệ nào trong đồ án này.
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


Trước tiên, em xin gửi lời cảm ơn chân thành đến quý thầy/cô trong Khoa Khoa học Và Kỹ thuật Máy tính, Trường Đại học Bách Khoa - Đại học Quốc gia TP.HCM, những người đã tận tình truyền đạt kiến thức và tạo điều kiện thuận lợi cho em trong suốt quá trình học tập.

Đặc biệt, em xin bày tỏ lòng biết ơn sâu sắc đến thầy Lê Đình Thuận, người đã hướng dẫn, động viên và đóng góp nhiều ý kiến quý báu trong suốt quá trình thực hiện đề tài này. Sự chỉ bảo tận tâm của thầy đã giúp chúng em hoàn thành tốt báo cáo này.

Em xin chân thành cảm ơn!


#pagebreak()

// ============= TÓM TẮT ĐỀ TÀI =============
#align(center)[
  *TÓM TẮT ĐỀ TÀI*
]

Sự phổ biến của các nền tảng mạng xã hội đã tạo ra một khối lượng lớn dữ liệu phi cấu trúc, phản ánh hành vi người dùng và xu hướng thị trường. Việc khai thác hiệu quả nguồn dữ liệu này đặt ra nhiều thách thức, đặc biệt trong việc tổ chức, xử lý và chuyển đổi dữ liệu thô thành thông tin có ý nghĩa phục vụ cho hoạt động ra quyết định.

Xuất phát từ nhu cầu đó, đề tài tập trung nghiên cứu và xây dựng một hệ thống hỗ trợ phân tích dữ liệu mạng xã hội, nhằm thu thập, xử lý và tổng hợp thông tin từ các nền tảng trực tuyến. Hệ thống hướng tới việc cung cấp các phân tích tổng quan, hỗ trợ so sánh, đánh giá và theo dõi các biến động trong môi trường truyền thông số.

Hệ thống được thiết kế theo hướng phân tán, chú trọng đến khả năng mở rộng, tính linh hoạt và khả năng đáp ứng trong môi trường có khối lượng dữ liệu lớn và thay đổi liên tục. Các cơ chế xử lý bất đồng bộ và cập nhật thông tin theo thời gian gần thực được xem xét nhằm nâng cao hiệu quả vận hành của hệ thống.

Báo cáo trình bày quá trình phân tích yêu cầu, thiết kế kiến trúc và đề xuất giải pháp tổng thể cho hệ thống. Kết quả của đề tài góp phần xây dựng một nền tảng định hướng cho việc phát triển các hệ thống phân tích mạng xã hội, đáp ứng nhu cầu ứng dụng trong thực tiễn và có khả năng mở rộng trong tương lai.
