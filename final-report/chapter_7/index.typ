// Chapter 7: Tổng kết

= CHƯƠNG 7: TỔNG KẾT

== 7.1 Tổng kết kết quả thực hiện

Đề tài đã xây dựng SMAP theo một chuỗi nội dung tương đối đầy đủ từ khảo sát bài toán, phân tích yêu cầu, thiết kế kiến trúc đến kiểm thử và đánh giá hệ thống. Ở giai đoạn phân tích, báo cáo đã xác định bối cảnh của bài toán social listening, đối chiếu với một số hệ thống liên quan và rút ra nhu cầu cốt lõi: người dùng cần thiết lập phạm vi theo dõi, vận hành thu thập dữ liệu, khai thác kết quả phân tích và nhận biết các tình huống cần chú ý trong quá trình theo dõi.

Trên cơ sở đó, Chương 4 đã đặc tả hệ thống bằng mười hai yêu cầu chức năng, bảy yêu cầu phi chức năng và năm use case nghiệp vụ chính. Cách tổ chức use case tập trung vào mục tiêu của người dùng thay vì tên module kỹ thuật: thiết lập chiến dịch theo dõi, vận hành chiến dịch, tra cứu và hỏi đáp dữ liệu phân tích, theo dõi trạng thái và nhận cảnh báo, thiết lập hoặc quản lý quy tắc cảnh báo khủng hoảng. Các cơ chế như xác thực, xử lý analytics, kiểm tra nội bộ hoặc message bus được đặt đúng vai trò là capability hỗ trợ cho các use case được bảo vệ, không bị tách thành use case người dùng giả tạo.

Ở Chương 5, đề tài đã thiết kế SMAP như một hệ thống microservices có phân tách rõ theo capability và workload lane. `identity-srv` giữ security boundary; `project-srv` quản lý campaign, project, lifecycle và crisis configuration; `ingest-srv` cùng `scapper-srv` hình thành execution plane cho datasource, target, dry run và crawl task; `analysis-srv` gồm `analysis-consumer` cho analytics pipeline và `analysis-api` cho dashboard read path; `knowledge-srv` phục vụ search, chat, report và indexing; `notification-srv` giữ delivery boundary cho Redis/WebSocket; frontend đóng vai trò giao diện và backend-for-frontend cho browser. Thiết kế này giúp tách control plane khỏi các luồng xử lý nền nặng, đồng thời cho phép từng lane có cách scale, storage và transport phù hợp.

Về dữ liệu và giao tiếp, báo cáo đã làm rõ vai trò của PostgreSQL, Redis, MinIO và Qdrant trong mô hình polyglot persistence. PostgreSQL lưu metadata nghiệp vụ, insight và trạng thái xử lý; Redis hỗ trợ cache hoặc Pub/Sub notification; MinIO lưu artifact lớn; Qdrant phục vụ semantic retrieval. Về transport, hệ thống sử dụng internal HTTP cho các tương tác đồng bộ cần phản hồi ngay, RabbitMQ cho crawl execution runtime, Kafka cho analytics data plane và Redis Pub/Sub cho notification ingress. Việc chọn nhiều cơ chế giao tiếp làm tăng độ phức tạp vận hành, nhưng phù hợp với bản chất không đồng nhất của workload trong SMAP.

Chương 6 bổ sung lớp bằng chứng thực nghiệm cho các thiết kế trên. Các bộ kiểm thử unit theo service cho thấy những package/nhóm test được liệt kê của identity-srv, project-srv, ingest-srv, notification-srv, analysis-srv, shared-libs, knowledge-srv, crawler worker và smap-analyse đều pass trong lần chạy được báo cáo. Các kịch bản kiểm thử chức năng và đầu cuối đã xác minh nhiều luồng chính như quản lý campaign/project, datasource/target, activation, search/chat/report, crisis runtime apply, crawler task và notification delivery ở mức API, UI hoặc runtime state. Các kịch bản NFR cho thấy API-lane duy trì p95 dưới 225 ms trong các scenario đã chạy, throughput quan sát nằm trong khoảng 6.949-7.751 req/s và không ghi nhận infra error trong cửa sổ đo.

Nhìn chung, kết quả đạt được không chỉ là một tập hợp sơ đồ hoặc mô tả rời rạc. Báo cáo đã nối được yêu cầu, use case, activity diagram, service boundary, data design, sequence diagram, communication pattern, deployment view và kiểm thử thành một mạch diễn giải thống nhất. Nhờ đó, người đọc có thể truy vết từ nhu cầu nghiệp vụ ở Chương 4 sang quyết định kiến trúc ở Chương 5 và bằng chứng kiểm chứng ở Chương 6.

== 7.2 Đóng góp chính của đề tài

Đóng góp thứ nhất của đề tài là cách tổ chức lại bài toán social listening thành một mô hình yêu cầu có ranh giới rõ. Thay vì mô tả hệ thống theo từng màn hình hoặc từng service, báo cáo tách rõ mục tiêu người dùng, capability hỗ trợ và các concern kỹ thuật. Điều này giúp bộ use case cô đọng hơn, tránh nhầm lẫn giữa nghiệp vụ người dùng và luồng xử lý nội bộ như analytics, indexing hoặc queue processing.

Đóng góp thứ hai là thiết kế kiến trúc đa lane cho một hệ thống có nhiều kiểu tải khác nhau. SMAP không ép toàn bộ xử lý vào request-response đồng bộ mà tách riêng control plane, execution plane, analytics data plane, knowledge retrieval và notification delivery. Cách tiếp cận này phù hợp với các hệ thống cần vừa phản hồi thao tác người dùng, vừa xử lý crawl, phân tích NLP, indexing và phát thông báo trong nền.

Đóng góp thứ ba là mô tả được sự phối hợp giữa nhiều cơ chế lưu trữ và truyền thông theo trách nhiệm cụ thể. PostgreSQL, Redis, MinIO, Qdrant, RabbitMQ và Kafka không được liệt kê như các công nghệ độc lập, mà được đặt vào từng lane xử lý và từng loại dữ liệu. Điều này làm rõ vì sao hệ thống cần polyglot persistence và vì sao mỗi transport được chọn cho một nhóm tương tác khác nhau.

Đóng góp thứ tư là việc gắn thiết kế với bằng chứng kiểm thử. Chương 6 không chỉ nêu rằng hệ thống đã được kiểm thử, mà chỉ ra lớp kiểm thử, công cụ, phạm vi, kết quả quan sát và giới hạn diễn giải. Các kết quả này giúp kết luận về hệ thống có cơ sở hơn: những phần đã đo thì được nêu bằng số liệu hoặc evidence cụ thể; những phần chưa đo đủ thì được giữ ở mức phạm vi cần mở rộng sau.

== 7.3 Hạn chế

Hạn chế đầu tiên nằm ở phạm vi dữ liệu và kịch bản kiểm thử. Các kết quả E2E và NFR trong Chương 6 được đo trên những campaign/project cụ thể trong môi trường K3s tham chiếu, vì vậy chúng không nên được hiểu như cam kết tuyệt đối cho mọi tổ hợp dữ liệu, nền tảng, rule hoặc profile tải. Các chỉ số latency và throughput hiện phản ánh API-lane trong cửa sổ workload 12-20 phút; những phép đo dài hơn như soak test nhiều giờ, saturation threshold theo replica, backlog drain time hoặc nhiều dạng chaos khác vẫn cần được bổ sung nếu hệ thống bước vào vận hành chính thức.

Hạn chế thứ hai là độ trưởng thành vận hành chưa đồng đều giữa mọi runtime. Hệ thống đã có health check, logging, probe và một số bằng chứng observability trong kiểm thử, nhưng metrics surface chưa được chuẩn hóa hoàn toàn giữa các service. Trace ID propagation và log correlation có giá trị khi chẩn đoán, nhưng chưa đi kèm một lớp visualization xuyên service hoàn chỉnh. Các nội dung như runbook, backup/restore, disaster recovery và chính sách retention cũng cần được hoàn thiện thêm để tạo thành một bộ vận hành nhất quán.

Hạn chế thứ ba liên quan đến notification và realtime. Báo cáo đã có bằng chứng unit test cho WebSocket/Redis delivery và route WebSocket qua gateway yêu cầu xác thực, nhưng kiểm thử hai chiều bằng WebSocket client đầy đủ chưa được ghi nhận bằng số pass riêng. Vì vậy, kết luận hiện tại chỉ nên dừng ở khả năng route, xác thực và delivery nội bộ, chưa nên mở rộng thành cam kết về độ trễ realtime end-to-end hoặc độ ổn định kết nối trong nhiều điều kiện mạng khác nhau.

Hạn chế thứ tư đến từ bản chất của bài toán thu thập và phân tích dữ liệu mạng xã hội. Crawl runtime phụ thuộc vào chính sách, quota, cấu trúc giao diện và thay đổi kỹ thuật từ các nền tảng bên ngoài. Analytics lane hiện cũng được kiểm chứng trong phạm vi mô hình, ontology và dữ liệu nhất định, chưa phải pipeline đa ngôn ngữ hoặc đa miền tổng quát cho mọi ngữ cảnh. Với knowledge layer, chất lượng câu trả lời và báo cáo LLM cần thêm benchmark hoặc tiêu chí đánh giá nội dung nếu muốn kết luận ở mức chất lượng tri thức, thay vì chỉ ở mức endpoint/contract.

== 7.4 Hướng phát triển

Hướng phát triển quan trọng nhất là tăng độ trưởng thành vận hành. Hệ thống cần được bổ sung metrics chuẩn cho các runtime chính, dashboard giám sát theo lane, trace visualization xuyên service, alerting vận hành và runbook xử lý sự cố. Các quy trình backup, restore, retention và disaster recovery nên được cụ thể hóa bằng cấu hình và rehearsal thay vì chỉ dừng ở định hướng thiết kế.

Hướng thứ hai là mở rộng kiểm thử phi chức năng. Các kịch bản hiện tại nên được bổ sung thêm soak test dài hơn, chaos test nhiều dạng hơn, đo backlog drain time cho RabbitMQ/Kafka, kiểm thử saturation khi tăng replica và kiểm thử WebSocket end-to-end bằng client đầy đủ. Những phép đo này sẽ giúp chuyển các giả định về availability, scalability và realtime delivery thành bằng chứng vận hành có độ tin cậy cao hơn.

Hướng thứ ba là nâng cấp analytics và knowledge layer. Analytics pipeline có thể tiếp tục được cải thiện ở các bước calibration sentiment, intent, keyword extraction, crisis assessment và domain ontology. Knowledge layer có thể được mở rộng bằng benchmark chất lượng retrieval, đánh giá hallucination, đánh giá citation grounding và cải thiện report generation. Khi các capability này được đo bằng tiêu chí nội dung rõ ràng, báo cáo trong tương lai có thể kết luận không chỉ endpoint hoạt động đúng mà còn chất lượng phân tích đạt yêu cầu.

Hướng thứ tư là mở rộng execution plane một cách có kiểm soát. Việc thêm nền tảng crawl, kiểu datasource hoặc target mới cần đi kèm contract dữ liệu, dry run mapping, quota policy và test case tương ứng. Mỗi mở rộng nên giữ nguyên nguyên tắc của kiến trúc hiện tại: control plane không bị kéo vào workload crawl nặng, artifact lớn vẫn đi qua object storage, còn dữ liệu chuẩn hóa tiếp tục được publish vào analytics data plane bằng contract có thể truy vết.

== 7.5 Kết luận

SMAP đã đạt được mục tiêu chính của đề tài: xây dựng một hệ thống social media analytics có thiết kế nhất quán, có phân tách trách nhiệm rõ và có bằng chứng kiểm thử cho các luồng trọng yếu. Từ góc nhìn nghiệp vụ, hệ thống hỗ trợ các bước chính của một quy trình social listening nội bộ: thiết lập chiến dịch, vận hành thu thập dữ liệu, khai thác kết quả phân tích, theo dõi trạng thái và quản lý ngữ cảnh cảnh báo khủng hoảng. Từ góc nhìn kỹ thuật, hệ thống được tổ chức thành các service và lane xử lý phù hợp với đặc điểm tải của từng nhóm chức năng.

Giá trị nổi bật của đề tài nằm ở tính truy xuất nguồn gốc giữa yêu cầu, kiến trúc và kiểm thử. Các quyết định như tách service theo capability, dùng RabbitMQ cho crawl task, dùng Kafka cho analytics data plane, dùng Redis cho notification ingress, dùng Qdrant cho retrieval và tách `analysis-api` khỏi `analysis-consumer` đều có liên hệ trực tiếp với yêu cầu hoặc đặc tính chất lượng đã đặt ra. Chương 6 cho thấy nhiều phần quan trọng của thiết kế đã được kiểm chứng bằng test cụ thể, đồng thời cũng chỉ ra ranh giới của những kết luận chưa nên suy rộng.

Mặc dù vẫn còn các hướng cần hoàn thiện về vận hành dài hạn, observability, benchmark chất lượng tri thức và kiểm thử realtime sâu hơn, nền tảng hiện tại đã đủ rõ để tiếp tục phát triển thành một hệ thống vận hành thực tế. Theo nghĩa đó, đề tài không chỉ dừng ở việc mô tả một kiến trúc đề xuất, mà đã hình thành được một bản thiết kế có kiểm chứng, có giới hạn diễn giải rõ ràng và có lộ trình phát triển tiếp theo.
