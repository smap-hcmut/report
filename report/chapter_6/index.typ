// Chapter 6: Tổng kết

= CHƯƠNG 6: TỔNG KẾT

== 6.1 Kết quả đạt được

Đề tài đã hoàn thành việc phân tích và thiết kế hệ thống SMAP với các kết quả chính sau:

Về phân tích yêu cầu, nhóm đã xác định được 2 actors chính là Marketing Analyst và Social Media Platforms, đồng thời phân tích 7 use cases cấp user-goal bao gồm cấu hình project, dry-run từ khóa, khởi chạy và theo dõi tiến trình, xem kết quả phân tích, quản lý danh sách projects, xuất báo cáo và phát hiện xu hướng tự động. Tổng cộng 47 yêu cầu chức năng và 31 yêu cầu phi chức năng đã được định nghĩa chi tiết, cùng với 7 business rules toàn cục đảm bảo tính nhất quán của hệ thống.

Về thiết kế kiến trúc, hệ thống được thiết kế theo mô hình microservices với 5 services chính: Identity Service, Project Service, Collector Service, AI/ML Service và WebSocket Service. Database schema sử dụng 2 PostgreSQL databases độc lập cho Identity và Project services, áp dụng chiến lược Database-per-Service. Message flow được thiết kế sử dụng RabbitMQ cho xử lý bất đồng bộ và Redis Pub/Sub cho thông báo thời gian thực. Data pipeline được thiết kế với 4 giai đoạn: crawling, analyzing, aggregating và finalizing.

Về mô hình hóa, nhóm đã xây dựng 7 activity diagrams mô tả luồng nghiệp vụ chi tiết, 7 sequence diagrams mô tả tương tác giữa các components, và ERD diagram mô tả cấu trúc database cùng relationships. Tất cả 7 use cases được đặc tả đầy đủ theo template Cockburn với main flow và extensions.

== 6.2 Hạn chế

Đề tài còn một số hạn chế cần được nhận diện:

Về phạm vi, đề tài tập trung chủ yếu vào giai đoạn phân tích và thiết kế, chưa triển khai đầy đủ tất cả các use cases. Module AI/ML Service với các chức năng sentiment analysis, aspect extraction và trend detection chưa được hiện thực hoàn chỉnh. Hệ thống hiện tại chỉ hỗ trợ 2 nền tảng YouTube và TikTok, chưa mở rộng sang các nền tảng khác như Facebook hay Instagram.

Về kỹ thuật, giải pháp xử lý rate-limit và captcha từ các platforms chưa được nghiên cứu sâu. Cơ chế backup và disaster recovery chưa được thiết kế chi tiết. Performance testing và load testing chưa được thực hiện để xác định giới hạn thực tế của hệ thống.

Về tài liệu, user manual và deployment guide chưa được xây dựng đầy đủ. API documentation cho tất cả endpoints chưa hoàn thiện. Runbook cho operations và troubleshooting chưa được biên soạn.

== 6.3 Hướng phát triển

Dựa trên kết quả đạt được và các hạn chế đã nhận diện, nhóm đề xuất các hướng phát triển tiếp theo:

Trong ngắn hạn từ 3 đến 6 tháng, ưu tiên hoàn thiện hiện thực các use cases còn lại, triển khai AI/ML Service với các models phân tích sentiment và aspect extraction cho tiếng Việt, xây dựng dashboard visualization với các biểu đồ và metrics thời gian thực, và hiện thực chức năng xuất báo cáo với các định dạng PDF, PPTX và Excel.

Trong trung hạn từ 6 đến 12 tháng, mở rộng hỗ trợ thêm các platforms như Facebook, Instagram và Twitter/X. Phát triển tính năng competitor benchmarking nâng cao với khả năng so sánh đa chiều. Xây dựng recommendation system đề xuất keywords và strategies dựa trên dữ liệu lịch sử. Hiện thực advanced analytics với predictive models dự báo xu hướng.

Tích hợp với các công cụ marketing automation để tự động hóa quy trình phản hồi. Xây dựng marketplace cho AI models và templates cho phép cộng đồng đóng góp. Mở rộng sang các thị trường quốc tế với hỗ trợ đa ngôn ngữ.

== 6.4 Kết luận

Đề tài đã hoàn thành mục tiêu phân tích và thiết kế hệ thống SMAP, một nền tảng phân tích mạng xã hội toàn diện đáp ứng nhu cầu thực tế của doanh nghiệp trong việc theo dõi danh tiếng thương hiệu và phát hiện sớm khủng hoảng truyền thông.

Kiến trúc microservices kết hợp event-driven được thiết kế cho phép hệ thống dễ dàng mở rộng theo chiều ngang và bảo trì độc lập từng service. Các use cases được phân tích chi tiết với đầy đủ main flow và exception handling, đảm bảo coverage cho các tình huống nghiệp vụ thực tế. Database schema được thiết kế tối ưu với indexes và soft delete pattern, hỗ trợ truy vấn hiệu quả và khôi phục dữ liệu. Message flow được thiết kế rõ ràng với RabbitMQ và Redis Pub/Sub, đảm bảo xử lý bất đồng bộ và thông báo thời gian thực.

Ma trận truy xuất nguồn gốc đã được xây dựng để đảm bảo mọi yêu cầu chức năng và phi chức năng đều được ánh xạ đến các thành phần thiết kế tương ứng. Hồ sơ quyết định kiến trúc ghi nhận các lựa chọn thiết kế quan trọng cùng với lý do và trade-offs. Phân tích khoảng trống đã nhận diện các gaps, limitations và trade-offs cần được xem xét trong quá trình hiện thực.

Hệ thống có tiềm năng phát triển thành một sản phẩm có khả năng cạnh tranh trên thị trường social media analytics. Các hướng phát triển tiếp theo đã được xác định rõ ràng, tạo nền tảng vững chắc cho việc triển khai và mở rộng hệ thống trong tương lai.

