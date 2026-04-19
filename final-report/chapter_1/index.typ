// chuong1
= CHƯƠNG 1: TỔNG QUAN

== 1.1 Giới thiệu đề tài

Trong bối cảnh chuyển đổi số, dữ liệu mạng xã hội ngày càng trở thành một nguồn thông tin quan trọng cho hoạt động theo dõi thương hiệu, phân tích xu hướng và hỗ trợ ra quyết định. Tuy nhiên, giá trị của nguồn dữ liệu này không chỉ nằm ở việc thu thập số lượng lớn bài đăng hay bình luận, mà còn nằm ở khả năng chuẩn hóa, phân tích và chuyển hóa dữ liệu thành thông tin có thể sử dụng trong thực tế.

Các hệ thống social listening hiện đại vì vậy không còn dừng ở mức hiển thị biểu đồ hay thống kê đơn giản. Chúng cần hỗ trợ một chuỗi xử lý gồm thu thập dữ liệu từ nhiều nguồn, xử lý và phân tích nội dung, lưu trữ kết quả có cấu trúc, khai thác thông tin theo ngữ cảnh, cũng như cung cấp cơ chế thông báo kịp thời khi xuất hiện tín hiệu quan trọng.

Từ nhu cầu đó, SMAP được xây dựng như một hệ thống phân tích dữ liệu mạng xã hội phục vụ mục đích vận hành nội bộ. Hệ thống được tổ chức thành nhiều thành phần với vai trò chuyên biệt, hỗ trợ luồng xử lý từ ngữ cảnh nghiệp vụ, thu thập dữ liệu, phân tích, khai thác thông tin theo ngữ cảnh, đến thông báo thời gian thực. Đây cũng là cơ sở để luận văn tập trung vào việc phân tích kiến trúc và hiện thực của hệ thống thay vì chỉ mô tả bài toán ở mức ý tưởng.

== 1.2 Mục tiêu đề tài

=== 1.2.1 Mục tiêu tổng quát

Mục tiêu tổng quát của đề tài là xây dựng một hệ thống phân tích dữ liệu mạng xã hội phục vụ nhu cầu vận hành nội bộ, có khả năng thu thập dữ liệu từ nhiều nguồn, chuẩn hóa và xử lý dữ liệu, từ đó hỗ trợ phân tích, tổng hợp thông tin và khai thác thông tin theo ngữ cảnh. Trọng tâm chính của đồ án là kiến trúc phần mềm, tổ chức luồng dữ liệu và sự phối hợp giữa các thành phần trong hệ thống, thay vì đi sâu vào việc nghiên cứu hoặc đề xuất các mô hình học máy mới.

=== 1.2.2 Mục tiêu cụ thể

Các mục tiêu cụ thể của đề tài bao gồm:

- Hỗ trợ thiết lập và quản lý các đối tượng phân tích cần thiết để làm cơ sở cho quá trình theo dõi và xử lý dữ liệu.
- Hỗ trợ thu thập và chuẩn bị dữ liệu từ các nguồn mạng xã hội theo quy trình có kiểm soát.
- Hỗ trợ xử lý và phân tích dữ liệu theo hướng bất đồng bộ để tạo ra các kết quả có cấu trúc phục vụ tra cứu, tổng hợp thông tin và hỗ trợ ra quyết định.
- Hỗ trợ tìm kiếm, tra cứu và khai thác thông tin theo ngữ cảnh từ dữ liệu và kết quả phân tích đã được xử lý.
- Hỗ trợ cập nhật thông tin và tín hiệu quan trọng theo hướng gần thời gian thực trong quá trình vận hành hệ thống.
- Xây dựng hệ thống theo hướng có cấu trúc rõ ràng, thuận lợi cho vận hành, bảo trì và nâng cấp sau này.

== 1.3 Phạm vi đề tài
=== 1.3.1 Phạm vi ứng dụng
Hệ thống SMAP được xây dựng nhằm hỗ trợ nhu cầu theo dõi, phân tích và tổng hợp thông tin từ mạng xã hội trong phạm vi vận hành nội bộ. Người dùng đích của hệ thống là các nhóm nội bộ như chuyên viên phân tích dữ liệu truyền thông xã hội, bộ phận theo dõi thương hiệu, marketing, nghiên cứu thị trường, truyền thông và các cấp quản lý có nhu cầu khai thác thông tin để hỗ trợ ra quyết định.

Phạm vi ứng dụng của hệ thống tập trung vào việc hỗ trợ quan sát dữ liệu, nhận diện tín hiệu đáng chú ý, tổng hợp kết quả phân tích và cung cấp thông tin phục vụ công tác theo dõi, đánh giá và ra quyết định.

=== 1.3.2 Phạm vi dữ liệu
Nguồn dữ liệu được sử dụng trong hệ thống bao gồm các bài đăng, bình luận và phản hồi công khai được thu thập từ các nền tảng mạng xã hội như TikTok, YouTube và Facebook.

Trong phạm vi của đồ án, dữ liệu được xem là đầu vào phục vụ cho quá trình thu thập, xử lý và phân tích thông tin. Hệ thống tập trung vào việc tổ chức luồng xử lý và khai thác giá trị từ dữ liệu đầu vào, không đặt mục tiêu xác minh tính xác thực tuyệt đối của từng nội dung phát sinh trên các nền tảng mạng xã hội.

=== 1.3.3 Phạm vi kỹ thuật
Về mặt kỹ thuật, đồ án tập trung vào việc xây dựng một hệ thống phân tán gồm nhiều thành phần chuyên biệt, trong đó dữ liệu được thu thập từ các nguồn mạng xã hội, chuẩn hóa, xử lý phân tích và cung cấp cho người dùng thông qua các cơ chế lưu trữ, truyền tin và thông báo phù hợp. Phạm vi kỹ thuật của đề tài bao gồm tổ chức kiến trúc hệ thống, thiết kế luồng xử lý dữ liệu và làm rõ cách các thành phần trong hệ thống phối hợp với nhau thông qua cả cơ chế giao tiếp đồng bộ lẫn bất đồng bộ.

Đồ án không đi sâu vào việc nghiên cứu các mô hình học máy mới hay tối ưu thuật toán ở mức học thuật. Trọng tâm chính là làm rõ cách hệ thống được tổ chức và hiện thực để hỗ trợ thiết lập đối tượng theo dõi, thu thập dữ liệu, xử lý phân tích, khai thác thông tin theo ngữ cảnh và cung cấp thông tin phục vụ công tác theo dõi, đánh giá và ra quyết định.

Ngoài ra, đồ án cũng xem xét các yếu tố hỗ trợ triển khai và vận hành như container hóa, tổ chức môi trường thực thi và khả năng mở rộng của từng thành phần, nhưng không đặt mục tiêu mô tả chi tiết toàn bộ hạ tầng triển khai như một tài liệu vận hành hoàn chỉnh.
