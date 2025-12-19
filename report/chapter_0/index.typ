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
    [_Thành phố Hồ Chí Minh, ngày ... tháng ... năm 2025_],
    [_Sinh viên thực hiện_],
    [],
    [],
    [],
    [_(Ký và ghi rõ họ tên)_]
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
*Trong bối cảnh mạng xã hội phát triển mạnh mẽ, việc theo dõi và phân tích danh tiếng thương hiệu trên các nền tảng mạng xã hội như YouTube, TikTok, Facebook,... trở thành nhu cầu thiết yếu của doanh nghiệp. Hệ thống SMAP (Social Media Analytics Platform) được phát triển nhằm cung cấp giải pháp cho việc thu thập, phân tích và trực quan hóa dữ liệu mạng xã hội. Đề tài xây dựng hệ thống có khả năng thu thập dữ liệu tự động, phân tích cảm xúc và trích xuất khía cạnh từ nội dung, so sánh với đối thủ cạnh tranh, phát hiện sớm khủng hoảng truyền thông, phát hiện xu hướng nội dung, và cung cấp dashboard trực quan với khả năng xuất báo cáo. Hệ thống được thiết kế theo kiến trúc microservices, sử dụng RabbitMQ, MinIO và các công nghệ AI/ML hiện đại. Báo cáo tập trung vào việc phân tích yêu cầu, thiết kế kiến trúc và đề xuất giải pháp kỹ thuật cho các chức năng cốt lõi của hệ thống nhằm đáp ứng nhu cầu thực tế trong việc theo dõi danh tiếng thương hiệu và phát hiện sớm khủng hoảng.*