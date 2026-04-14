# Figure Notes

## 1. `c4-context-current.svg`

Hình này trả lời câu hỏi: SMAP nằm ở đâu trong tương quan với người dùng và hệ thống bên ngoài. Hai nhóm người dùng chính là `Agency / Brand Team` và `Analyst / PR Team`. Ba nhóm external dependencies là `Google OAuth2`, các nền tảng xã hội, và các dịch vụ AI.

Khi đọc hình này, nên chú ý rằng đây là view mức bối cảnh, không phải view triển khai. Mục tiêu của hình là làm rõ ranh giới hệ thống và các nhóm tác nhân liên quan, không mô tả chi tiết transport nội bộ.

## 2. `c4-container-current.svg`

Hình này là trục chính để hiểu kiến trúc nhiều service hiện tại. `identity-srv` tạo security boundary. `project-srv` giữ business context. `ingest-srv` và `scapper-srv` tạo execution plane. `analysis-srv` là lớp NLP/analytics. `knowledge-srv` là lớp semantic search và chat. `notification-srv` là lớp delivery.

Các hộp màu xanh lá và cam biểu thị hạ tầng chính. PostgreSQL, Redis, MinIO và Qdrant là storage/infrastructure. Kafka và RabbitMQ là các cơ chế giao tiếp bất đồng bộ. Nhìn vào các nhãn quan hệ sẽ thấy ngay sự phân tách giữa `HTTP control`, `dispatch tasks`, `Kafka UAP`, và `analytics topics`.

## 3. `c4-component-analysis-current.svg`

Hình này đi sâu vào `analysis-srv`. Khi đọc hình, nên theo thứ tự từ trái sang phải: `Kafka Consumer` nhận `smap.collector.output`, `UAP Adapter` chuyển payload sang mô hình nội bộ, `Analytics Pipeline` chạy các pha xử lý, `Signal Evaluator` đánh giá tín hiệu, và `Topic Publisher` phát các topic downstream.

Nhóm lưu trữ phía dưới cho thấy pipeline không hoạt động độc lập khỏi persistence. PostgreSQL giữ analytics facts, Redis/MinIO hỗ trợ cache và raw lookup. `knowledge-srv` ở góc phải dưới là consumer downstream của các topic do analytics phát ra.

## 4. `c4-component-knowledge-current.svg`

Hình này mô tả `knowledge-srv` như một lớp tri thức độc lập. `Kafka Consumers` nhận dữ liệu downstream, `Indexer` chuyển document sang vector/index metadata, `Search and RAG API` phục vụ truy hồi và chat, `Notebook Sync` hỗ trợ notebook workflow, và `Report API` phục vụ đầu ra báo cáo.

Điểm quan trọng của hình là nó cho thấy knowledge layer không chỉ là một API search. Nó còn phối hợp Qdrant, metadata storage và external AI services. Vì vậy, khi đọc hình nên xem `knowledge-srv` như một orchestration layer cho retrieval và generation, không chỉ là một service CRUD thông thường.

## 5. `dynamic-current-dataflow.svg`

Đây là hình tóm tắt luồng dữ liệu hiện tại theo 5 bước. `project-srv` khởi động control plane, `ingest-srv` điều phối datasource và UAP, `scapper-srv` đảm nhiệm crawl runtime, `analysis-srv` xử lý pipeline, và `knowledge-srv` tiêu thụ analytics outputs.

Hộp `MinIO raw artifacts` phía dưới nhấn mạnh claim-check pattern: raw artifact không đi hết trong message bus mà được lưu ra object storage, còn các lane messaging mang metadata hoặc payload chuẩn hóa. Điều này là chìa khóa để hiểu vì sao hệ thống chia storage và messaging như hiện tại.

## 6. `messaging-topology-current.svg`

Hình này chỉ tập trung vào topology giao tiếp. Nó nên được đọc theo 4 lane: `Control Plane`, `Crawl Runtime`, `Analytics Data Plane`, và `Notification Ingress`.

Giá trị chính của hình là làm rõ một điểm thường bị hiểu sai: hệ thống không dùng một broker chung cho mọi luồng. HTTP được dùng cho control, RabbitMQ cho task runtime, Kafka cho analytics pipeline, và Redis Pub/Sub cho notification ingress.

## 7. `crisis-loop-target.svg`

Đây là hình `target / partial`, không phải current runtime fact. Khi đọc hình, nên xem đây là mô hình định hướng cho giai đoạn sau: `analysis-srv` phát tín hiệu, `project-srv` chốt trạng thái nghiệp vụ, `ingest-srv` điều chỉnh crawl, và `notification-srv` làm nhiệm vụ cảnh báo.

Ý nghĩa của hình là phân biệt rất rõ `analysis signal` với `business crisis state`. `analysis-srv` có thể phát `candidate` hoặc `signal`, nhưng quyết định nghiệp vụ cuối cùng vẫn nên nằm ở `project-srv` nếu hệ thống đi đúng theo định hướng target architecture.

## 8. `deployment-current-partial.svg`

Hình này cho cái nhìn deployment-oriented ở mức vừa đủ. Phần trên là client/edge, phần giữa là application workloads, phần dưới là infrastructure. Không nên đọc hình này như production topology hoàn chỉnh, mà nên xem nó là view `current / partial` dựa trên artifact có trong repo.

Điểm chính cần rút ra là workload đã được tách theo lane: `identity-api`, `project-api`, `ingest-api / scheduler`, `analysis-consumer`, `knowledge-api / consumer`, `notification-api`. Điều này phản ánh đúng cách hệ thống được vận hành theo service và theo kiểu workload separation.

## 9. `sequence-project-execution-current.svg`

Đây là sequence chính của luận văn cho luồng thực thi project. Luồng bắt đầu từ `User`, đi vào `project-srv`, sau đó chuyển sang `ingest-srv`, RabbitMQ, `scapper-srv`, MinIO, và cuối cùng lan sang `analysis-srv`.

Khi đọc hình, nên chú ý rằng không phải mọi bước đều là lời gọi trực tiếp giữa các service. Có bước là task dispatch qua RabbitMQ, có bước là object handoff qua MinIO, và có bước là publish sang analytics lane. Đây là hình giúp nối business lifecycle với runtime processing trong một sequence duy nhất.

## 10. `uml-class-business-domain.svg`

Hình này là class view khái niệm, không phải lớp code-level đầy đủ. Nó mô tả chuỗi nghiệp vụ: `Campaign` chứa `Project`, `Project` sở hữu `Datasource`, `Datasource` sở hữu `CrawlTarget`, và `Project` có thể có `CrisisConfig`.

Nên dùng hình này để hiểu quan hệ giữa các khái niệm business, không dùng nó để suy diễn tất cả trường vật lý trong database. Data dictionary và migration files vẫn là nguồn chi tiết hơn cho schema vật lý.

## 11. `uml-state-lifecycle-current.svg`

Hình này mô tả hai state model riêng: `Project lifecycle` và `Business crisis status`. Ở phía project, các trạng thái hiện hành là `PENDING`, `ACTIVE`, `PAUSED`, `ARCHIVED`. Ở phía trạng thái khủng hoảng nghiệp vụ, hình hiện phản ánh `NORMAL`, `WARNING`, `CRITICAL` thay vì rút gọn thành hai mức.

Giá trị của hình nằm ở chỗ nó giúp tách bạch hai loại state khác nhau: state điều khiển execution của project và state đánh giá rủi ro truyền thông ở mức business. Nếu không tách, rất dễ nhầm giữa “project đang paused” với “project đang ở trạng thái critical”.
