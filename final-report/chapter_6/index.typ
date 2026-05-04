// Chapter 6: Tổng kết

= CHƯƠNG 6: TỔNG KẾT

== 6.1 Kết quả đạt được

Đề tài đã hoàn thành việc phân tích và thiết kế hệ thống SMAP theo hướng nhất quán từ yêu cầu đến kiến trúc. Ở cấp phân tích hệ thống, nhóm đã xác định ba tác nhân chính gồm nhóm người dùng chuyên môn nội bộ, nền tảng mạng xã hội và nhà cung cấp định danh. Trên cơ sở đó, hệ thống được đặc tả thành mười hai yêu cầu chức năng, bảy đặc tính kiến trúc và bảy yêu cầu phi chức năng cốt lõi, đồng thời được tổ chức lại thành năm use case nghiệp vụ chính theo góc nhìn mục tiêu sử dụng của người dùng.

Ở cấp thiết kế kiến trúc, SMAP được mô hình hóa như một hệ thống đa service có chuyên biệt hóa theo capability và workload. `identity-srv` giữ vai trò security boundary; `project-srv` quản lý business context và lifecycle; `ingest-srv` cùng `scapper-srv` hình thành execution plane; `analysis-srv` đảm nhiệm analytics pipeline; `knowledge-srv` xây dựng lớp retrieval và khai thác tri thức; `notification-srv` thực hiện delivery theo thời gian thực; còn frontend đóng vai trò lớp giao diện, backend-for-frontend và desktop shell khi cần. Cách phân tách này giúp Chương 5 giải thích được rõ ràng ranh giới trách nhiệm, luồng dữ liệu và các điểm phối hợp giữa các lane xử lý.

Ở cấp dữ liệu và tích hợp, đề tài đã làm rõ mô hình polyglot persistence của SMAP với PostgreSQL cho metadata và trạng thái nghiệp vụ, Redis cho cache hoặc state ngắn hạn, MinIO cho artifact lớn và Qdrant cho vector retrieval. Về giao tiếp, các transport được chọn theo tính chất workload: internal HTTP cho control plane, RabbitMQ cho execution plane, Kafka cho analytics downstream và Redis Pub/Sub cho notification ingress. Ở cấp triển khai, chương thiết kế cũng đã mô tả mô hình pod-role separation, trong đó API, scheduler, consumer và worker được tách thành các workload riêng khi cần để phù hợp hơn với đặc điểm vận hành của từng lane.

Cuối cùng, bộ tài liệu thiết kế đã được nối lại thành một cấu trúc có truy xuất nguồn gốc rõ ràng. Các activity diagram ở Chương 4, sequence diagram ở Chương 5, thiết kế dữ liệu, communication patterns, deployment view và traceability matrix cùng tạo thành một chuỗi mô tả thống nhất, cho thấy các quyết định kỹ thuật không đứng riêng lẻ mà đều xuất phát từ yêu cầu và ràng buộc của hệ thống.

== 6.2 Hạn chế

Hạn chế lớn nhất của đề tài nằm ở phạm vi công việc. Trọng tâm của luận văn là phân tích và thiết kế hệ thống, không phải đánh giá thực nghiệm toàn diện trên môi trường vận hành đầy đủ. Vì vậy, nhiều nội dung trong các chương trước được trình bày như quyết định thiết kế hoặc định hướng vận hành, chứ chưa phải là các kết quả benchmark hay các cam kết định lượng đã được kiểm chứng đầy đủ bằng tải thật.

Ở góc độ kỹ thuật, một số lớp của hệ thống vẫn còn cần được hoàn thiện thêm để đạt độ trưởng thành vận hành cao hơn. Lớp observability chưa đồng nhất hoàn toàn giữa mọi runtime; trace ID propagation đã có nhưng chưa đi kèm một lớp hiển thị trace trực quan xuyên service; metrics surface cũng chưa được chuẩn hóa như nhau giữa các lane xử lý. Tương tự, các nội dung như backup, disaster recovery, quy trình vận hành và tự động hóa triển khai hiện mới chủ yếu được mô tả ở mức thiết kế hoặc bằng các cấu hình rời rạc, chưa hình thành một bộ vận hành hoàn chỉnh và đồng đều cho toàn bộ hệ thống.

Ngoài ra, một số capability của SMAP còn chịu giới hạn tự nhiên từ môi trường bên ngoài. Crawl runtime phụ thuộc vào chính sách, quota và sự thay đổi kỹ thuật từ các nền tảng mạng xã hội. Analytics lane hiện cũng thiên về phạm vi dữ liệu và mô hình phục vụ tiếng Việt hơn là một pipeline đa ngôn ngữ tổng quát. Ở knowledge layer, report generation đã được nhận diện như một capability mở rộng, nhưng chưa nên được xem là trục chức năng cốt lõi ngang hàng với các use case chính của Chương 4.

== 6.3 Hướng phát triển

Trong giai đoạn tiếp theo, một hướng phát triển quan trọng là hoàn thiện chiều sâu vận hành của hệ thống. Điều này bao gồm việc chuẩn hóa metrics surface cho các runtime quan trọng, bổ sung lớp trace visualization phù hợp, hoàn thiện runbook và các quy trình backup hoặc restore, cũng như củng cố deployment automation theo mô hình pod-role đã được thiết kế ở Chương 5. Các bước này sẽ giúp kiến trúc đã mô tả tiến gần hơn đến một trạng thái vận hành ổn định và dễ quan sát hơn.

Ở lớp xử lý dữ liệu, hệ thống có thể được mở rộng theo hai hướng. Hướng thứ nhất là tăng độ trưởng thành của analytics và retrieval, bao gồm nâng cao chất lượng mô hình, mở rộng phạm vi ngôn ngữ khi cần và làm giàu thêm lớp khai thác tri thức ở knowledge layer. Hướng thứ hai là tiếp tục hoàn thiện knowledge-side report capability và các workflow báo cáo phụ trợ để biến nhánh mở rộng này thành một năng lực ổn định hơn, nếu nó thực sự được ưu tiên trong các vòng phát triển tiếp theo.

Ở lớp execution và data ingress, việc mở rộng thêm nguồn crawl hoặc nền tảng mới là hướng phát triển tự nhiên, nhưng cần được thực hiện có chọn lọc theo điều kiện kỹ thuật và chính sách của từng nền tảng. Song song với đó, các đợt benchmark, load testing và operational rehearsal cũng nên được bổ sung để chuyển các giả định về hiệu năng, khả năng mở rộng và tính sẵn sàng thành các kết quả có thể kiểm chứng rõ ràng hơn.

== 6.4 Kết luận

Nhìn tổng thể, đề tài đã hoàn thành mục tiêu phân tích và thiết kế hệ thống SMAP theo một cách tiếp cận có cấu trúc và nhất quán. Từ việc xác định tác nhân, use case, yêu cầu chức năng và phi chức năng, luận văn đã đi tiếp đến các quyết định về service boundary, communication pattern, data design, deployment view và traceability. Kết quả đạt được không chỉ là tập hợp các sơ đồ riêng lẻ, mà là một bức tranh kiến trúc thống nhất, trong đó mỗi phần đều có thể giải thích được bằng các yêu cầu và ràng buộc ban đầu của hệ thống.

Điểm quan trọng nhất của bản thiết kế là làm rõ được logic tổ chức của SMAP như một hệ thống nhiều lane xử lý với transport và storage được chuyên biệt hóa theo workload. Việc tách business control plane khỏi execution plane, tách analytics khỏi request path, và tách knowledge hoặc notification thành các lớp tiêu thụ riêng đã tạo nên một kiến trúc có khả năng mở rộng, dễ truy vết hơn và phù hợp hơn với bản chất của bài toán phân tích mạng xã hội.

Mặc dù vẫn còn những giới hạn và khoảng trống cần được hoàn thiện ở các vòng triển khai tiếp theo, bộ tài liệu hiện tại đã tạo ra một nền tảng vững chắc cho quá trình hiện thực hóa, kiểm thử và hardening hệ thống. Theo nghĩa đó, giá trị chính của đề tài nằm ở việc xây dựng được một cơ sở kiến trúc rõ ràng, có truy xuất nguồn gốc với yêu cầu và đủ chi tiết để tiếp tục phát triển thành một hệ thống vận hành thực tế trong các giai đoạn sau.
