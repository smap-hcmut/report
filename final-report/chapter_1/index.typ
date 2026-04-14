// chuong1
= CHƯƠNG 1: TỔNG QUAN

== 1.1 Giới thiệu đề tài

Trong bối cảnh chuyển đổi số, dữ liệu mạng xã hội ngày càng trở thành một nguồn thông tin quan trọng cho hoạt động theo dõi thương hiệu, phân tích xu hướng và hỗ trợ ra quyết định. Tuy nhiên, giá trị của nguồn dữ liệu này không chỉ nằm ở việc thu thập số lượng lớn bài đăng hay bình luận, mà còn nằm ở khả năng chuẩn hóa, phân tích và chuyển hóa dữ liệu thành thông tin có thể sử dụng trong thực tế.

Các hệ thống social listening hiện đại vì vậy không còn dừng ở mức hiển thị biểu đồ hay thống kê đơn giản. Chúng cần hỗ trợ một chuỗi xử lý gồm thu thập dữ liệu từ nhiều nguồn, xử lý và phân tích nội dung, lưu trữ kết quả có cấu trúc, khai thác thông tin theo ngữ cảnh, cũng như cung cấp cơ chế thông báo kịp thời khi xuất hiện tín hiệu quan trọng.

Từ nhu cầu đó, SMAP được xây dựng như một hệ thống phân tích dữ liệu mạng xã hội phục vụ mục đích vận hành nội bộ. Hệ thống được tổ chức thành nhiều thành phần với vai trò chuyên biệt, hỗ trợ luồng xử lý từ ngữ cảnh nghiệp vụ, thu thập dữ liệu, phân tích, khai thác thông tin theo ngữ cảnh, đến thông báo thời gian thực. Đây cũng là cơ sở để luận văn tập trung vào việc phân tích kiến trúc và hiện thực của hệ thống thay vì chỉ mô tả bài toán ở mức ý tưởng.

== 1.2 Mục tiêu đề tài

Đề tài tập trung vào việc thiết kế và hiện thực hóa một nền tảng phân tích dữ liệu truyền thông xã hội, với ưu tiên hàng đầu là tính vững chắc của kiến trúc phần mềm và khả năng mở rộng hệ thống và không đi sâu vào nghiên cứu phát triển các mô hình học máy phức tạp. Cụ thể, hệ thống được xây dựng để tự động hóa quy trình kỹ thuật, kết nối các luồng dữ liệu nhằm rút ngắn Time-to-Insight, cho phép chuyển đổi nhanh chóng dữ liệu thô thành các chỉ số có ý nghĩa. Về khía cạnh phân tích, SMAP tích hợp các mô hình Aspect-Based Sentiment Analysis cho tiếng Việt như một module xử lý chức năng, phục vụ việc hiển thị các chỉ số về sức khỏe thương hiệu và phân tích cạnh tranh trên Dashboard. Trọng tâm cốt lõi của đồ án nằm ở việc giải quyết bài toán hiệu năng thông qua kiến trúc Microservices kết hợp Event-driven, sử dụng cơ chế giao tiếp qua message broker để đảm bảo tính độc lập và khả năng mở rộng linh hoạt cho từng dịch vụ. Qua đó, SMAP hướng đến giá trị thực tiễn của một sản phẩm phần mềm hoàn chỉnh, đề cao tính tổ chức và thiết kế hệ thống phân tán trong bối cảnh dữ liệu lớn

== 1.3 Phạm vi đề tài
=== 1.3.1 Phạm vi ứng dụng
Hệ thống SMAP - Social Media Analytics Platform được định hướng là một nền tảng phân tích và khai thác dữ liệu mạng xã hội có tính linh hoạt cao, cho phép ứng dụng trong nhiều bối cảnh và quy mô tổ chức khác nhau.

Mục tiêu của nền tảng không giới hạn ở một lĩnh vực cụ thể, mà hướng đến tự động hóa toàn bộ quy trình phân tích thông tin xã hội, giúp rút ngắn thời gian từ khi dữ liệu xuất hiện đến khi tạo ra insight có thể hành động.

=== 1.3.2 Phạm vi dữ liệu
Nguồn dữ liệu được sử dụng trong dự án bao gồm các bài đăng, bình luận và phản hồi công khai được thu thập từ những nền tảng mạng xã hội phổ biến như TikTok, YouTube và Facebook.

Phương pháp thu thập dữ liệu được thực hiện kết hợp giữa việc sử dụng API chính thức và kỹ thuật Web Scraping. Thông tin được thu thập và phân tích là dữ liệu công khai, được người dùng tự tạo ra trên mạng xã hội. Vì vậy, mặc dù đảm bảo tính ổn định về thời gian trong xử lý và phản ánh nguyên trạng nội dung gốc, chúng tôi không thể xác nhận tính xác thực tuyệt đối của từng mẫu dữ liệu. Độ chính xác của phân tích phản ánh chính xác dữ liệu đầu vào được cung cấp.

=== 1.3.3 Phạm vi kỹ thuật
Về mặt kỹ thuật, dự án SMAP được kiến trúc lại theo mô hình Distributed System vận hành dựa trên cơ chế Event-Driven Choreography. Thay vì sử dụng mô hình điều phối tập trung truyền thống, các dịch vụ trong SMAP hoạt động độc lập và phối hợp nhịp nhàng thông qua chuỗi sự kiện, đảm bảo tính Loose Coupling tối đa.

Hệ thống áp dụng các mẫu thiết kế nâng cao như Claim-Check Pattern, tối ưu hóa băng thông Message Queue bằng cách offload dữ liệu tải trọng lớn sang MinIO Data Lake và chiến lược Atomic Stream Processing. Cách tiếp cận này không chỉ giải quyết triệt để bài toán Asymmetric Workload giữa khâu thu thập và khâu phân tích AI, mà còn đảm bảo khả năng chịu lỗi..

Trong bối cảnh triển khai trên Cluster Kubernetes giới hạn tài nguyên, các dịch vụ được thiết kế hoàn toàn Stateless, cho phép Horizontal Scaling linh hoạt và tận dụng tối đa phần cứng thông qua cơ chế lập lịch thông minh của Kubernetes.
