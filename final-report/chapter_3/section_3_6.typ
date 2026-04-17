#import "../counters.typ": table_counter

== 3.6 Authentication và Security

=== 3.6.1 JWT

JSON Web Token là một tiêu chuẩn mở theo RFC 7519 định nghĩa một cách gọn nhẹ và tự chứa để truyền thông tin an toàn giữa các bên dưới dạng đối tượng JSON. JWT được sử dụng rộng rãi cho xác thực và trao đổi thông tin trong các ứng dụng web và API. Một trong những lợi ích chính của JWT là xác thực không trạng thái, server không cần lưu trữ dữ liệu phiên, tất cả thông tin cần thiết được mã hóa trong chính token.

JWT bao gồm ba phần được phân tách bởi dấu chấm: Header, Payload, và Signature. Header chứa siêu dữ liệu về token, thường bao gồm loại và thuật toán ký. Payload chứa các claim, các tuyên bố về thực thể thường là người dùng và siêu dữ liệu bổ sung. Signature được tạo bằng cách mã hóa header và payload, sau đó ký với khóa bí mật sử dụng thuật toán được chỉ định trong header.

Các claim trong JWT payload có thể là các claim đã đăng ký được định nghĩa trong đặc tả như iss (issuer), exp (expiration time), sub (subject), các claim công khai được định nghĩa bởi người dùng, hoặc các claim riêng tư được thỏa thuận giữa các bên. Các claim đã đăng ký cung cấp khả năng tương tác, trong khi các claim tùy chỉnh cho phép truyền dữ liệu cụ thể của ứng dụng.

Xác thực không trạng thái là lợi ích chính của JWT. Server không cần lưu trữ dữ liệu phiên, tất cả thông tin cần thiết nằm trong token. Điều này cho phép mở rộng theo chiều ngang dễ dàng, bất kỳ server nào cũng có thể xác minh token mà không cần kho lưu trữ phiên chia sẻ. Tuy nhiên, không trạng thái cũng có nhược điểm, không thể vô hiệu hóa token trước thời gian hết hạn mà không có các cơ chế bổ sung như danh sách đen token.

=== 3.6.2 HttpOnly Cookie

HttpOnly Cookie là một thuộc tính cookie được đặt bởi server để ngăn các script phía client truy cập cookie. Khi cookie có cờ HttpOnly, mã JavaScript không thể đọc giá trị cookie thông qua document.cookie. Điều này là một biện pháp bảo mật quan trọng để bảo vệ chống lại các cuộc tấn công Cross-Site Scripting. HttpOnly cookie thường được sử dụng để lưu trữ các token xác thực như JWT, ID phiên, và dữ liệu nhạy cảm khác.

Cookie có nhiều thuộc tính kiểm soát hành vi và bảo mật của chúng. HttpOnly ngăn truy cập JavaScript, bảo vệ chống lại XSS. Secure đảm bảo cookie chỉ được gửi qua kết nối HTTPS, bảo vệ chống lại các cuộc tấn công man-in-the-middle. SameSite kiểm soát khi nào cookie được gửi với các request cross-site, có ba giá trị: Strict không bao giờ gửi với request cross-site, Lax gửi với điều hướng cấp cao nhất, và None luôn gửi nhưng yêu cầu Secure.

=== 3.6.3 Password Hashing

Băm mật khẩu là quá trình chuyển đổi mật khẩu văn bản thô thành một chuỗi có kích thước cố định sử dụng hàm mật mã một chiều. Các hàm băm được thiết kế để không thể đảo ngược, không thể suy ra mật khẩu gốc từ hash. Khi người dùng đăng ký, mật khẩu được băm và hash được lưu trữ trong cơ sở dữ liệu. Khi người dùng đăng nhập, mật khẩu đầu vào được băm và so sánh với hash đã lưu trữ.

bcrypt là một thuật toán băm mật khẩu được thiết kế đặc biệt cho lưu trữ mật khẩu. bcrypt có nhiều thuộc tính làm cho nó an toàn: chậm theo thiết kế để tốn kém về mặt tính toán, thích ứng với hệ số chi phí có thể tăng theo thời gian, và tự động tạo và bao gồm salt. bcrypt được coi là tiêu chuẩn ngành cho băm mật khẩu và được khuyến nghị bởi OWASP.

#context (align(center)[_Bảng #table_counter.display(): So sánh các Password Hashing Algorithms_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.2fr, 1.2fr, 1.2fr),
    stroke: 0.5pt,
    align: (center, center, center, center, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Algorithm*],
    table.cell(align: center + horizon)[*Security*],
    table.cell(align: center + horizon)[*Performance*],
    table.cell(align: center + horizon)[*Memory Usage*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[bcrypt],
    table.cell(align: center + horizon)[Rất cao],
    table.cell(align: center + horizon)[Chậm],
    table.cell(align: center + horizon)[Thấp],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Argon2],
    table.cell(align: center + horizon)[Rất cao],
    table.cell(align: center + horizon)[Chậm],
    table.cell(align: center + horizon)[Cao, có thể cấu hình],

    table.cell(align: center + horizon, inset: (y: 0.6em))[PBKDF2],
    table.cell(align: center + horizon)[Cao],
    table.cell(align: center + horizon)[Trung bình],
    table.cell(align: center + horizon)[Thấp],

    table.cell(align: center + horizon, inset: (y: 0.6em))[SHA256],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Rất nhanh],
    table.cell(align: center + horizon)[Thấp],
  )
]

=== 3.6.4 Security Practices

Xác thực đầu vào là tuyến phòng thủ đầu tiên chống lại nhiều cuộc tấn công. Tất cả đầu vào của người dùng phải được xác thực trước khi xử lý. Xác thực nên kiểm tra loại dữ liệu, định dạng, độ dài, và các giá trị được phép. Phòng chống SQL injection tốt nhất là sử dụng truy vấn có tham số thay vì nối chuỗi.

HTTPS/TLS mã hóa tất cả giao tiếp giữa client và server, bảo vệ chống lại nghe lén và các cuộc tấn công man-in-the-middle. TLS 1.3 là phiên bản mới nhất với bảo mật và hiệu suất được cải thiện. Tất cả các ứng dụng sản xuất nên sử dụng HTTPS độc quyền.

Giới hạn tốc độ hạn chế số lượng request mà một client có thể thực hiện trong một khoảng thời gian, bảo vệ chống lại các cuộc tấn công brute-force và denial-of-service. Giới hạn tốc độ có thể được triển khai ở nhiều cấp độ: theo IP, theo người dùng, theo endpoint.

CORS là một cơ chế bảo mật kiểm soát các request cross-origin. Trình duyệt thực thi chính sách same-origin, ngăn các script từ một origin truy cập tài nguyên từ origin khác. Các header CORS cho phép server chỉ định origin nào được phép truy cập tài nguyên.
