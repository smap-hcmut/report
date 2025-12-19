// chuong1
= CHƯƠNG 1: TỔNG QUAN

== 1.1 Giới thiệu đề tài
Trong thời đại số, sự tồn tại và phổ biến của các nền tảng truyền thông xã hội đã tạo ra một môi trường mà trong đó thông tin được tạo ra và lan truyền với tần suất cao mỗi ngày. Các tương tác của người dùng trên những nền tảng này hình thành một tập dữ liệu phi cấu trúc có quy mô lớn, phản ánh hành vi người dùng và xu hướng thị trường. Nguồn dữ liệu này có vai trò quan trọng trong việc hỗ trợ doanh nghiệp phân tích nhu cầu khách hàng và xây dựng chiến lược cạnh tranh.

Tuy nhiên, thách thức đặt ra nằm ở việc xử lý và khai thác hiệu quả khối lượng dữ liệu nói trên. Dữ liệu thô nếu không được tổ chức và phân tích phù hợp sẽ khó chuyển hóa thành thông tin có giá trị sử dụng. Do đó, thực tiễn đặt ra nhu cầu về một quy trình có khả năng chuyển đổi dữ liệu mạng xã hội thành thông tin có ý nghĩa, phục vụ việc nhận diện xu hướng và phân tích cảm xúc người dùng một cách có hệ thống.

Từ yêu cầu đó, đề tài tập trung nghiên cứu và phát triển hệ thống SMAP (Social Media Analytics Platform). Hệ thống được thiết kế nhằm tự động hóa các bước chính trong quy trình phân tích dữ liệu mạng xã hội, bao gồm thu thập dữ liệu từ nhiều nền tảng, xử lý ngôn ngữ tự nhiên cho tiếng Việt và trực quan hóa kết quả phân tích nhằm hỗ trợ ra quyết định. SMAP hướng tới việc cung cấp một nền tảng phân tích dữ liệu có tính ứng dụng cao, đáp ứng đồng thời yêu cầu kỹ thuật và nhu cầu khai thác thông tin trong thực tiễn.

== 1.2 Mục tiêu đề tài

Đề tài tập trung vào việc thiết kế và hiện thực hóa một nền tảng phân tích dữ liệu truyền thông xã hội, với ưu tiên hàng đầu là tính vững chắc của kiến trúc phần mềm và khả năng mở rộng hệ thống và không đi sâu vào nghiên cứu phát triển các mô hình học máy phức tạp. Cụ thể, hệ thống được xây dựng để tự động hóa quy trình kỹ thuật, kết nối các luồng dữ liệu nhằm rút ngắn Time-to-Insight (TTI), cho phép chuyển đổi nhanh chóng dữ liệu thô thành các chỉ số có ý nghĩa. Về khía cạnh phân tích, SMAP tích hợp các mô hình Aspect-Based Sentiment Analysis (ABSA) cho tiếng Việt như một module xử lý chức năng, phục vụ việc hiển thị các chỉ số về sức khỏe thương hiệu và phân tích cạnh tranh trên Dashboard. Trọng tâm cốt lõi của đồ án nằm ở việc giải quyết bài toán hiệu năng thông qua kiến trúc Microservices kết hợp Event-driven, sử dụng cơ chế giao tiếp qua message broker để đảm bảo tính độc lập và khả năng mở rộng linh hoạt cho từng dịch vụ. Qua đó, SMAP hướng đến giá trị thực tiễn của một sản phẩm phần mềm hoàn chỉnh, đề cao tính tổ chức và thiết kế hệ thống phân tán trong bối cảnh dữ liệu lớn

== 1.3 Phạm vi đề tài
=== 1.3.1 Phạm vi ứng dụng
Hệ thống SMAP (Social Media Analytics Platform) được định hướng là một nền tảng phân tích và khai thác dữ liệu mạng xã hội có tính linh hoạt cao, cho phép ứng dụng trong nhiều bối cảnh và quy mô tổ chức khác nhau.

Mục tiêu của nền tảng không giới hạn ở một lĩnh vực cụ thể, mà hướng đến tự động hóa toàn bộ quy trình phân tích thông tin xã hội, giúp rút ngắn thời gian từ khi dữ liệu xuất hiện đến khi tạo ra insight có thể hành động (Time-to-Insight).

=== 1.3.2 Phạm vi dữ liệu
Nguồn dữ liệu được sử dụng trong dự án bao gồm các bài đăng, bình luận và phản hồi công khai được thu thập từ những nền tảng mạng xã hội phổ biến như TikTok, YouTube và Facebook.

Phương pháp thu thập dữ liệu được thực hiện kết hợp giữa việc sử dụng API chính thức và kỹ thuật Web Scraping. Việc thu thập dữ liệu được tiến hành tập trung cho tiếng Việt, giúp mô hình có khả năng tập trung phân tích cho thị trường Việt Nam.

Thông tin được thu thập và phân tích là dữ liệu công khai, được người dùng tự tạo ra trên mạng xã hội. Vì vậy, mặc dù đảm bảo tính ổn định về thời gian trong xử lý và phản ánh nguyên trạng nội dung gốc, chúng tôi không thể xác nhận tính xác thực tuyệt đối của từng mẫu dữ liệu. Độ chính xác của phân tích phản ánh chính xác dữ liệu đầu vào được cung cấp.

=== 1.3.3 Phạm vi kỹ thuật
Về mặt kỹ thuật, dự án SMAP được kiến trúc lại theo mô hình Hệ thống Phân tán (Distributed System) vận hành dựa trên cơ chế Event-Driven Choreography (Vũ đạo hướng sự kiện). Thay vì sử dụng mô hình điều phối tập trung truyền thống, các dịch vụ trong SMAP hoạt động độc lập và phối hợp nhịp nhàng thông qua chuỗi sự kiện, đảm bảo tính Loose Coupling (Kết nối lỏng lẻo) tối đa.

Hệ thống áp dụng các mẫu thiết kế nâng cao như Claim-Check Pattern (tối ưu hóa băng thông Message Queue bằng cách offload dữ liệu tải trọng lớn sang MinIO Data Lake) và chiến lược Atomic Stream Processing (xử lý luồng đơn vị nhỏ: 1 bài viết là 1 file). Cách tiếp cận này không chỉ giải quyết triệt để bài toán Tải bất đối xứng (Asymmetric Workload) giữa khâu thu thập (I/O bound) và khâu phân tích AI (CPU bound), mà còn đảm bảo khả năng chịu lỗi (Fault Tolerance) ở mức độ hạt nhân.

Trong bối cảnh triển khai trên Cluster Kubernetes giới hạn tài nguyên, các dịch vụ được thiết kế hoàn toàn Stateless (Phi trạng thái), cho phép mở rộng ngang (Horizontal Scaling) linh hoạt và tận dụng tối đa phần cứng thông qua cơ chế lập lịch thông minh của Kubernetes.

