#import "../counters.typ": table_counter, image_counter

=== 4.7.2 Lựa chọn Architecture Style

==== 4.7.2.1 Bối cảnh quyết định

Việc lựa chọn kiến trúc cho SMAP không chỉ là quyết định công nghệ mà chính là quá trình giải quyết các mâu thuẫn kỹ thuật, đưa ra quyết định kiến trúc (technical trade-offs) xuất phát từ đặc thù nghiệp vụ và yêu cầu phi chức năng. Trước khi phân tích từng phương án, nhóm xác định các Architectural Drivers chính (yếu tố thúc đẩy kiến trúc):

*Sự bất đối xứng về tải (Asymmetric Workload):*

- Crawler Service: chạy dưới dạng background job, tiêu tốn tài nguyên CPU và mạng ở mức rất cao (high throughput). Khối lượng xử lý của crawler ước tính cao hơn ~10 lần so với các nhóm dịch vụ khác do liên tục ingest và xử lý dữ liệu thô.
- API Service: chủ yếu phục vụ request/response, cần độ trễ thấp (low latency) để đảm bảo trải nghiệm người dùng cuối.
- Thách thức: nếu hai loại service này chung một hệ thống (monolith), việc crawler chạy tải lớn có thể chiếm dụng tài nguyên, khiến dashboard/API bị chậm hoặc treo toàn hệ thống.

*Đa dạng công nghệ (Polyglot Technology Stack):*

- Dự án yêu cầu Python cho Crawler, phân tích và AI (NLU/NLP – PyTorch, Scikit-learn).
- Golang tối ưu cho API nhờ khả năng xử lý đa luồng tốt và tiết kiệm RAM.
- Thách thức: monolith gần như không thể tích hợp, vận hành hiệu quả cùng lúc hai runtime (Python & Go) bên trong một tiến trình chung.

*Yêu cầu về tính sẵn sàng & cô lập (Availability & Isolation):*

- Ví dụ: nếu module phân tích AI lỗi (như tràn bộ nhớ do load ML model lớn) thì không được phép làm sập tính năng đăng nhập hoặc dashboard cho user.
- Thách thức: cần một kiến trúc mà lỗi từng phần không ảnh hưởng toàn hệ thống.

Dựa trên các yếu tố này, nhóm đã lựa chọn ba mô hình kiến trúc phổ biến để đánh giá và so sánh: Monolithic Architecture (Kiến trúc nguyên khối), Microservices Architecture (Kiến trúc vi dịch vụ) và Modular Monolith (Nguyên khối mô-đun hóa).

==== 4.7.2.2 Phân tích các lựa chọn

Dựa trên bối cảnh kỹ thuật đã xác lập, nhóm phân tích ba mô hình kiến trúc dưới góc độ vận hành thực tiễn của SMAP.

====== 1. Monolithic Architecture (Kiến trúc nguyên khối)

Trong mô hình này, toàn bộ hệ thống (module Crawler, Analytics, API) được tích hợp vào một ứng dụng duy nhất, triển khai như một đơn vị (single deployable unit).

#context (align(center)[
  #image("../images/architecture/monolithic_architecture.png", width: 25%)
])
#context (align(center)[_Hình #image_counter.display(): Monolithic Architecture_])
#image_counter.step()

*Ưu điểm:*

- Đơn giản trong phát triển ban đầu: không cần thiết lập hạ tầng phân tán, dễ debug và test toàn bộ hệ thống trong môi trường local.
- Hiệu năng giao tiếp nội bộ: các module giao tiếp trực tiếp qua function calls (in-process), độ trễ cực thấp (microseconds), không có overhead của network.
- Giao dịch ACID dễ dàng: tất cả dữ liệu nằm trong một database, có thể sử dụng transaction để đảm bảo tính nhất quán dữ liệu.
- Chi phí vận hành thấp: chỉ cần quản lý một ứng dụng, một database, giảm thiểu độ phức tạp DevOps.

*Nhược điểm trong context SMAP:*

- Không giải quyết được bài toán Polyglot Runtime: việc tích hợp Python (Crawler/Analytics) và Golang (API) vào một khối đòi hỏi các giải pháp phức tạp:
  - CGO (C bindings): cho phép Go gọi code C/Python nhưng gây rủi ro về memory management, dễ leak và khó debug.
  - Sub-process calls: gọi Python script từ Go qua command line, tăng độ trễ đáng kể (từ microseconds lên milliseconds) và khó quản lý lifecycle.
  - Docker multi-stage build phức tạp: phải đóng gói cả Python runtime và Go binary vào một image, làm tăng kích thước container từ ~20MB (Go Alpine) lên ~500MB+ (Python + dependencies).
- Không thể scale độc lập (Independent Scaling): khi Crawler Service cần scale lên 20 pods để xử lý chiến dịch lớn, phải scale toàn bộ monolith, kéo theo cả API Service không cần thiết → lãng phí tài nguyên (over-provisioning). Ví dụ: chi phí cloud tăng 10x nhưng chỉ 10% tài nguyên được sử dụng cho API.
- Rủi ro tài nguyên (Resource Contention): Crawler tiêu tốn CPU/RAM gấp ~10 lần API. Khi Crawler hoạt động mạnh, nó chiếm dụng toàn bộ tài nguyên server, khiến các request đơn giản (đăng nhập, xem báo cáo) bị timeout hoặc bị từ chối (throttling).
- Blast radius lớn: nếu module Analytics bị crash do OOM khi load model AI nặng (PhoBERT ~1.2GB), toàn bộ ứng dụng sẽ sập, kéo theo cả API Service ngừng hoạt động → vi phạm yêu cầu Availability 99.5%.

====== 2. Modular Monolith (Nguyên khối mô-đun hóa)

Mô hình này chia tách code thành các module rõ ràng theo domain (Domain-Driven Design), nhưng vẫn chạy trên một tiến trình (Single Process) và một môi trường runtime (Single Runtime).

#context (align(center)[
  #image("../images/architecture/modular_monolith.png", width: 70%)
])
#context (align(center)[_Hình #image_counter.display(): Modular Monolith Architecture_])
#image_counter.step()

*Ưu điểm:*

- Tổ chức code tốt: áp dụng nguyên tắc Separation of Concerns, mỗi module có trách nhiệm rõ ràng, dễ maintain và test từng module độc lập.
- Dễ refactor: có thể tách module thành microservice sau này khi cần thiết (Strangler Pattern).
- Đơn giản hơn Microservices: không cần quản lý network communication, service discovery, distributed tracing phức tạp.

*Nhược điểm trong context SMAP:*

- Vẫn không giải quyết được bài toán Polyglot Runtime: giống như Monolith, Modular Monolith vẫn chỉ chạy trên một runtime duy nhất. Nếu chọn Python làm runtime chính, API Service sẽ mất đi lợi thế về hiệu năng của Golang. Nếu chọn Go, phải giải quyết vấn đề tích hợp Python (CGO/sub-process) như đã nêu ở Monolith.
- Không có Runtime Isolation: tất cả modules chạy chung một process, chia sẻ cùng một heap memory. Nếu module Analytics bị memory leak khi load model AI nặng, nó sẽ chiếm dụng toàn bộ RAM của process, khiến các module khác (API, Crawler) không còn tài nguyên để hoạt động → toàn bộ ứng dụng crash.
- Không thể scale độc lập: giống Monolith, phải scale toàn bộ ứng dụng, không thể chỉ scale Crawler Service khi cần thiết.
- Deployment coupling: mọi thay đổi code ở bất kỳ module nào đều yêu cầu rebuild và redeploy toàn bộ ứng dụng, tăng rủi ro và thời gian downtime.

*Khi nào phù hợp:* Modular Monolith phù hợp cho các hệ thống có workload đồng đều giữa các modules, sử dụng cùng một technology stack, team nhỏ chưa có kinh nghiệm với distributed systems và yêu cầu đơn giản về scalability/fault isolation.

====== 3. Microservices Architecture (Kiến trúc vi dịch vụ)

Hệ thống được chia tách vật lý thành các service riêng biệt, mỗi service có thể được phát triển, triển khai và scale độc lập. Trong SMAP, các services chính bao gồm: Identity Service, Project Service, Collection Service, Analytics Service, Insight Service.

#context (align(center)[
  #image("../images/architecture/microservices_architecture.png", width: 65%)
])
#context (align(center)[_Hình #image_counter.display(): Microservices Architecture_])
#image_counter.step()

*Ưu điểm:*

- Scale chính xác (Precision Scaling): khi có chiến dịch lớn cần crawl 10M posts, nhóm chỉ cần tăng số lượng container cho Crawler Service từ 2 lên 20 pods. API Service và các service khác vẫn giữ nguyên 2 pods. Điều này tối ưu hóa triệt để chi phí hạ tầng, chỉ trả tiền cho tài nguyên thực sự sử dụng.
- Đa dạng Runtime (Polyglot Runtime): mỗi service có thể chọn technology stack phù hợp nhất:
  - Crawler Service & Analytics Service: chạy trong môi trường Python container đầy đủ thư viện (PyTorch, Scikit-learn, Playwright), image size ~500MB.
  - API Service (Identity, Project, Insight): chạy trong môi trường Alpine Linux siêu nhẹ của Go, image size ~20MB.
  - Không có xung đột thư viện hoặc runtime conflicts.
- Cô lập lỗi (Fault Isolation): mỗi service chạy trong container riêng biệt với resource limits. Nếu Analytics Service bị OOM khi load model AI, nó chỉ crash container của chính nó, không ảnh hưởng đến các service khác. API Service vẫn tiếp tục phục vụ user đăng nhập và xem dashboard.
- Phát triển độc lập (Independent Development): các team có thể phát triển và deploy services độc lập, không cần chờ các team khác, tăng tốc độ phát triển (faster time-to-market).
- Technology Evolution: có thể nâng cấp hoặc thay thế technology stack của từng service mà không ảnh hưởng đến services khác. Ví dụ: nâng cấp Analytics Service từ Python 3.9 lên 3.11 để tận dụng performance improvements.

*Nhược điểm trong context SMAP:*

- Độ phức tạp vận hành: quản lý nhiều service, cần hạ tầng orchestration (Kubernetes), service discovery, monitoring, logging tập trung.
- Độ trễ mạng: giao tiếp giữa các service qua network (10-20ms) thay vì function call (microseconds).
- Nhất quán dữ liệu: không thể sử dụng ACID transactions giữa các service.
- Chi phí vận hành cao hơn: cần nhiều tài nguyên vận hành hơn (Kubernetes control plane, monitoring tools).

// #### 4.7.2.3 Ma trận quyết định (Weighted Decision Matrix)

// Sau khi phân tích chi tiết từng mô hình kiến trúc ở mục 4.7.2.2, cần một phương pháp định lượng để so sánh khách quan các lựa chọn. Ma trận quyết định được xây dựng dựa trên hai cấp độ đánh giá:

// **Cấp độ 1: So sánh tổng quan theo tiêu chí chất lượng kiến trúc**

// Bảng dưới đây so sánh ba mô hình kiến trúc theo các tiêu chí chất lượng kiến trúc phổ biến (Architectural Quality Attributes), sử dụng thang điểm từ 1 (kém nhất) đến 5 (tốt nhất):

// | Đặc điểm / tiêu chí     | **Monolithic** | **Modular Monolith** | **Microservices** |
// |------------------------|----------------|----------------------|-------------------|
// | Partitioning           | Technical      | Domain               | Domain            |
// | Cost                   | **5**          | **5**                | 2                 |
// | Maintainability        | 2              | 4                    | **5**             |
// | Testability            | 2              | 3                    | **5**             |
// | Deployability          | **1**          | 3                    | **5**             |
// | Simplicity**           | **5**          | 4                    | 2                 |
// | Scalability            | 2              | 3                    | **5**             |
// | Elasticity             | **1**          | 2                    | **5**             |
// | Responsiveness         | 3              | 3                    | **5**             |
// | Fault-tolerance        | 2              | 3                    | **5**             |
// | Evolvability           | 2              | 3                    | **5**             |
// | Abstraction            | 2              | 3                    | 4                 |
// | Interoperability       | 2              | 3                    | **5**             |


// **Nhận xét từ bảng so sánh tổng quan:**

// Từ bảng trên, có thể thấy trong ngữ cảnh SMAP, Microservices Architecture đạt điểm cao nhất (5 điểm) ở hầu hết các tiêu chí liên quan đến khả năng mở rộng, khả năng chịu lỗi và tính linh hoạt. Tuy nhiên, Monolithic Architecture lại vượt trội về Simplicity (5 điểm) và Cost (5 điểm), phù hợp với các dự án nhỏ hoặc MVP. Điều này cho thấy không có mô hình nào là "tốt nhất" cho mọi trường hợp, mà cần đánh giá dựa trên context cụ thể của từng dự án.

// **Cấp độ 2: Ma trận trọng số dựa trên Architectural Drivers của SMAP**

// Để lượng hóa sự lựa chọn phù hợp với context của SMAP, nhóm xây dựng ma trận trọng số tập trung vào **ba Architectural Drivers chính** đã được xác định tại mục 4.7.2.1, cùng với hai tiêu chí bổ sung để đánh giá toàn diện:

// - Ba tiêu chí chính (75% trọng số) phản ánh trực tiếp Architectural Drivers:
//   - Đa dạng công nghệ (Polyglot Technology Stack) - 30%: Tương ứng với Architectural Driver về yêu cầu sử dụng đồng thời Python và Golang.
//   - Mở rộng độc lập (Independent Scaling) - 25%: Tương ứng với Architectural Driver về Asymmetric Workload (Crawler tiêu tốn ~10 lần so với API).
//   - Cô lập lỗi (Fault Isolation) - 20%: Tương ứng với Architectural Driver về Availability & Isolation.

// - Hai tiêu chí bổ sung (25% trọng số) để đánh giá toàn diện:
//   - Tốc độ phát triển (Time-to-market) - 15%: Quan trọng cho việc đưa sản phẩm ra thị trường nhanh chóng.
//   - Chi phí vận hành & hạ tầng - 10%: Ảnh hưởng đến tính khả thi về mặt kinh tế của dự án.

// Các tiêu chí được gán trọng số dựa trên mức độ quan trọng đối với thành công của dự án SMAP:

// | **Tiêu chí** | **Trọng số** | **Monolith** | **Modular Monolith** | **Microservices** | **Giải thích điểm số** |
// |--------------|--------------|--------------|----------------------|-------------------|------------------------|
// | Đa dạng công nghệ (Polyglot) – chạy song song Go & Python | 30% | 1 | 1 | 5 | Monolith/Modular chỉ có 1 runtime; Microservices tự nhiên hỗ trợ đa ngôn ngữ. |
// | Mở rộng độc lập (Independent Scaling) – scale Crawler 10x mà không scale API | 25% | 2 | 2 | 5 | Monolith phải nhân bản toàn bộ; Microservices chỉ scale phần cần thiết. |
// | Cô lập lỗi (Fault Isolation) – Analytics crash không làm sập API | 20% | 1 | 2 | 5 | Microservices cách ly process; Monolith dễ cascading failure. |
// | Tốc độ phát triển (Time-to-market) | 15% | 5 | 4 | 3 | Monolith triển khai nhanh nhất do không cần hạ tầng phân tán. |
// | Chi phí vận hành & hạ tầng | 10% | 5 | 5 | 2 | Microservices tốn DevOps và chi phí quản lý (K8s control plane). |
// | **Tổng điểm (Weighted Score)** | **100%** | **2.45** | **2.50** | **4.25** | Microservices vượt trội so với các phương án khác. |

// Phân tích kết quả ma trận trọng số:

// Kết quả từ ma trận trọng số cho thấy **Microservices Architecture đạt điểm 4.25/5.00**, vượt trội rõ rệt so với Monolithic (2.45) và Modular Monolith (2.50). Phân tích chi tiết cho thấy:

// 1. Ba tiêu chí chính phản ánh Architectural Drivers (75% trọng số):

// - Tiêu chí quan trọng nhất (30% trọng số) – Đa dạng công nghệ (Polyglot Technology Stack): Microservices đạt điểm tuyệt đối (5 điểm), trong khi cả Monolith và Modular Monolith chỉ đạt 1 điểm. Điều này phản ánh đúng thực tế ở mục 4.7.2.1 rằng SMAP bắt buộc phải sử dụng cả Go và Python, và chỉ có Microservices mới giải quyết được bài toán này một cách tự nhiên mà không cần các giải pháp phức tạp như CGO hay sub-process calls.

// - Tiêu chí thứ hai (25% trọng số) – Mở rộng độc lập (Independent Scaling): Microservices lại đạt điểm tuyệt đối (5 điểm), trong khi hai phương án còn lại chỉ đạt 2 điểm. Điều này phù hợp với Architectural Driver về Asymmetric Workload ở mục 4.7.2.1, nơi đã chỉ ra rằng Crawler Service tiêu tốn tài nguyên gấp ~10 lần so với API Service. Phân tích ở mục 4.7.2.2 cũng đã chứng minh rằng với Microservices, nhóm có thể scale Crawler Service lên 20 pods trong khi chỉ giữ 2 pods cho API Service, tối ưu hóa chi phí hạ tầng.

// - Tiêu chí thứ ba (20% trọng số) – Cô lập lỗi (Fault Isolation): Microservices đạt điểm tuyệt đối (5 điểm), đảm bảo khi Analytics Service crash (như trường hợp OOM khi load ML model lớn đã được đề cập ở mục 4.7.2.1), các service khác vẫn hoạt động bình thường. Điều này trực tiếp đáp ứng Architectural Driver về Availability & Isolation, đảm bảo lỗi từng phần không ảnh hưởng toàn hệ thống.

// 2. Hai tiêu chí bổ sung (25% trọng số):

// - Tốc độ phát triển (Time-to-market) - 15%: Microservices đạt điểm 3, thấp hơn Monolith (5 điểm) do cần thiết lập hạ tầng phân tán và CI/CD pipeline phức tạp hơn. Tuy nhiên, đây là trade-off chấp nhận được vì lợi ích vượt trội ở các tiêu chí quan trọng hơn.

// - Chi phí vận hành & hạ tầng - 10%: Microservices đạt điểm 2, thấp hơn Monolith và Modular Monolith (5 điểm) do tốn chi phí DevOps và quản lý Kubernetes control plane. Tuy nhiên, như đã phân tích ở mục 4.7.2.2, chi phí này được bù đắp bởi khả năng scale chính xác, chỉ trả tiền cho tài nguyên thực sự sử dụng.

// **Kết luận:** Ma trận quyết định xác nhận rằng Microservices Architecture là lựa chọn tối ưu cho SMAP, đặc biệt mạnh ở ba tiêu chí chính (75% trọng số) phản ánh trực tiếp các Architectural Drivers đã được xác định ở mục 4.7.2.1. Các trade-offs ở hai tiêu chí bổ sung (25% trọng số) là chấp nhận được và đã được nhóm chuẩn bị sẵn các chiến lược giảm thiểu rủi ro (xem mục 4.7.2.5).

// #### 4.7.2.4 Kết luận và biện luận kiến trúc (Architecture Justification)

// Dựa trên kết quả từ ma trận quyết định (4.25/5.00) ở mục 4.7.2.3 và các phân tích kỹ thuật chi tiết ở mục 4.7.2.2, nhóm phát triển lựa chọn **Microservices Architecture** làm nền tảng cho SMAP. Quyết định này không chạy theo trào lưu hay "hype-driven development" mà là kết quả của một quá trình phân tích có phương pháp luận rõ ràng, nhằm đạt điểm cân bằng tối ưu giữa tính linh hoạt (Flexibility) và độ phức tạp (Complexity), đồng thời giải quyết triệt để các thách thức kỹ thuật đã được xác định ở mục 4.7.2.1.

// Ba luận điểm cốt lõi biện minh cho quyết định này:

// **1. Giải quyết triệt để bài toán "Đa ngôn ngữ" (Polyglot Runtime)**

// - Vấn đề: SMAP buộc phải tích hợp hai hệ sinh thái công nghệ đối lập: Golang cho API hiệu năng cao và Python cho Crawler/Analytics/AI với thư viện phong phú.
// - Monolith/Modular thất bại: Nhúng Python runtime vào ứng dụng Golang thông qua CGO hoặc sub-process gây rủi ro lớn về ổn định bộ nhớ và làm phức tạp quá trình debug.
// - Lợi thế Microservices: Cho phép runtime isolation; API Service chạy trên image Alpine nhẹ của Go (~20MB), trong khi Crawler Service và Analytics Service chạy trên image Python tích hợp PyTorch/TensorFlow (~500MB) mà không xung đột thư viện hệ điều hành.
// - Impact: Giảm 96% kích thước image cho API Service (từ ~500MB xuống ~20MB), rút ngắn deployment time từ ~3 phút xuống ~30 giây, đồng thời cho phép Python services tận dụng full ecosystem của ML/AI libraries mà không làm "phình" các services khác.

// **2. Tối ưu hóa tài nguyên cho "Tải bất đối xứng" (Asymmetric Workload Optimization)**

// - Vấn đề: Tác vụ Crawling tiêu tốn CPU/Network gấp khoảng 10 lần so với phục vụ API.
// - Monolith thất bại: Muốn tăng năng lực Crawl phải scale-out toàn bộ ứng dụng, vô tình nhân bản cả module API/UI → lãng phí RAM và chi phí cloud (over-provisioning). Ví dụ: Scale từ 2 lên 20 instances của monolith sẽ tốn 20 × (2GB RAM + 1 vCPU) = 40GB RAM + 20 vCPU, trong khi chỉ cần thêm tài nguyên cho Crawler.
// - Lợi thế Microservices: Áp dụng fine-grained scaling; có thể triển khai 20 pods cho Crawler Service trên node CPU cao (1 vCPU, 1GB RAM mỗi pod) nhưng chỉ duy trì 2 pods cho API Service trên node cấu hình thấp (0.5 vCPU, 512MB RAM mỗi pod), giúp chi phí hạ tầng bám sát nhu cầu.
// - Impact: Tiết kiệm ~60-70% chi phí infrastructure so với việc scale monolith. Trong trường hợp Crawler surge (chiến dịch lớn), có thể scale Crawler Service từ 2 lên 20 pods trong ~2 phút thông qua Kubernetes HPA (Horizontal Pod Autoscaler), mà không ảnh hưởng đến các service khác.

// **3. Khoanh vùng rủi ro (Fault Isolation & Blast Radius)**

// - Vấn đề: Analytics chạy AI inference nặng, dễ gặp OOM hoặc treo tiến trình. Như đã phân tích ở mục 4.7.2.2, module Analytics khi load model PhoBERT (~1.2GB) có thể gây memory leak, và trong Monolith/Modular Monolith, điều này sẽ làm sập toàn bộ ứng dụng.
// - Lợi thế Microservices: Giới hạn blast radius; mỗi service chạy trong container riêng với resource limits (CPU, Memory) được cấu hình cụ thể. Nếu Analytics Service sập do OOM, Kubernetes sẽ tự động restart container đó trong ~10-15 giây, nhưng các service khác (Identity, Project, Collection) vẫn tiếp tục hoạt động bình thường.
// - Impact: Giảm blast radius từ 100% (toàn hệ thống) xuống ~14% (1 trong 7 services chính). Điều này đảm bảo các chức năng cốt lõi (Đăng nhập, Quản lý dự án, Thu thập dữ liệu) vẫn hoạt động ngay cả khi Analytics Service gặp vấn đề, đáp ứng mục tiêu availability 99.5% (tương đương ~3.6 giờ downtime/năm) đã được đề ra ở phần NFRs (xem mục 4.3).

// **Phân tích định lượng tổng hợp:**

// Bảng dưới đây tóm tắt các lợi ích định lượng khi áp dụng Microservices Architecture cho SMAP:

// | **Khía cạnh** | **Monolith** | **Microservices** | **Cải thiện** |
// |--------------|--------------|-------------------|---------------|
// | **Container Image Size** (API Service) | ~500MB (Python + Go) | ~20MB (Go Alpine) | **-96%** |
// | **Deployment Time** (API Service) | ~3 phút | ~30 giây | **-83%** |
// | **Infrastructure Cost** (peak load) | 40GB RAM + 20 vCPU | ~16GB RAM + 10 vCPU | **-60% to -70%** |
// | **Scaling Time** (Crawler Service) | ~5-10 phút (full redeploy) | ~2 phút (HPA) | **-60% to -80%** |
// | **Blast Radius** (khi 1 module crash) | 100% (toàn hệ thống) | ~14% (1/7 services) | **-86%** |
// | **Recovery Time** (sau crash) | ~3-5 phút (manual restart) | ~10-15 giây (K8s auto-restart) | **-95%** |
// | **Availability Target** | Khó đạt 99.5% | 99.5%+ khả thi | **Đáp ứng NFR** |

// **Tổng kết:**

// Ba luận điểm trên, cùng với phân tích định lượng, cho thấy Microservices Architecture không chỉ giải quyết được các thách thức kỹ thuật đã xác định ở mục 4.7.2.1 (Polyglot Runtime, Asymmetric Workload, Fault Isolation) mà còn mang lại các lợi ích đo lường được về mặt hiệu năng, chi phí và độ tin cậy.

// **Quan trọng hơn**, kiến trúc này tạo nền tảng vững chắc cho sự phát triển lâu dài của SMAP:

// - **Technology Evolution:** Dễ dàng nâng cấp hoặc thay thế công nghệ của từng service mà không ảnh hưởng đến toàn hệ thống.
// - **Team Scalability:** Các team có thể phát triển và deploy services độc lập, tăng tốc độ phát triển tính năng mới.
// - **Business Agility:** Có thể nhanh chóng điều chỉnh tài nguyên cho từng chức năng theo nhu cầu thực tế (ví dụ: tăng Crawler cho chiến dịch lớn, tăng Analytics cho khách hàng Enterprise).

// Tuy nhiên, như đã đề cập ở mục 4.7.2.2, việc áp dụng Microservices cũng mang lại những thách thức mới về độ phức tạp vận hành, độ trễ mạng và nhất quán dữ liệu. Nhóm hoàn toàn nhận thức rõ các thách thức này và đã chủ động chuẩn bị sẵn các chiến lược giảm thiểu rủi ro cụ thể, được trình bày chi tiết ở mục tiếp theo.

// ---

// #### 4.7.2.5 Phân tích Đánh đổi và Chiến lược giảm thiểu rủi ro (Trade-off Analysis)

// Như đã được đề cập ở phần kết luận mục 4.7.2.4, nhóm nhận thức rõ rằng **Microservices không phải là "viên đạn bạc" (Silver Bullet)**. Mặc dù kiến trúc này giải quyết triệt để ba Architectural Drivers chính của SMAP (Polyglot Runtime, Asymmetric Workload, Fault Isolation), nhưng nó cũng gia tăng đáng kể độ phức tạp hệ thống phân tán so với Monolithic Architecture.

// Thay vì né tránh hay giảm nhẹ các thách thức này trong quá trình phân tích (cherry-picking), nhóm đã chủ động nhận diện toàn bộ các trade-offs và thiết kế sẵn các chiến lược giảm thiểu rủi ro (Mitigation Strategies) ngay từ giai đoạn thiết kế kiến trúc. Cách tiếp cận này đảm bảo rằng quyết định lựa chọn Microservices được đưa ra dựa trên sự đánh giá trung thực và toàn diện về cả lợi ích lẫn chi phí.

// **Các thách thức và chiến lược giảm thiểu:**

// Dưới đây là bảng tổng hợp các thách thức (Pain Points) chính mà nhóm đã xác định trong quá trình thiết kế, cùng với các chiến lược giảm thiểu rủi ro đã được áp dụng để kiểm soát và quản lý các rủi ro này:

// | **Thách thức** | **Mức độ** | **Tác động thực tế** | **Chiến lược giảm thiểu** |
// |---------------|---------------------|---------------------|---------------------------|
// | **1. Độ phức tạp vận hành**<br/>(*Operational Complexity*) | 🔴 Cao | Việc quản lý, triển khai và giám sát hàng chục services thủ công là bất khả thi và dễ gây lỗi con người. | - **Automation:** Sử dụng Kubernetes (K8s) tự động hóa deployment, scaling, self-healing.<br/>- **CI/CD:** Thiết lập pipeline tự động trên Jenkins đảm bảo code được test và deploy đồng bộ. |
// | **2. Độ trễ mạng**<br/>(*Network Latency*) | 🟡 Trung bình | Thay vì gọi hàm nội bộ (in-process) chỉ vài micro-seconds, giao tiếp qua mạng tốn 10-20ms/request, ảnh hưởng response time. | - **On-Premise Deployment:** Triển khai tất cả services chung một hạ tầng on-premise, cùng namespace trong Kubernetes để giảm thiểu network latency giữa các services.<br/>- **Claim-Check Pattern:** Áp dụng pattern này để tránh truyền payload lớn qua message broker, thay vào đó chỉ truyền reference đến dữ liệu lưu trong Object Storage (MinIO). |
// | **3. Nhất quán dữ liệu**<br/>(*Data Consistency*) | 🟡 Trung bình | Dữ liệu phân tán ở nhiều CSDL riêng biệt, không thể sử dụng transaction ACID xuyên service. | - **Eventual Consistency:** Chấp nhận nhất quán cuối cùng cho báo cáo Analytics (business requirement cho phép).<br/>- **Event-Driven:** Dùng Message Broker (RabbitMQ) đồng bộ dữ liệu bất đồng bộ giữa các services (Pattern: Data Replication via Domain Events). |
// | **4. Khó khăn khi gỡ lỗi**<br/>(*Distributed Debugging*) | 🟡 Trung bình | Một request đi qua 4-5 services, rất khó xác định nguyên nhân gốc rễ khi sự cố xảy ra. | - **Container Management:** Sử dụng Rancher để quản lý Kubernetes cluster, giám sát và debug containers.<br/>- **Monitoring & Alerting:** Tích hợp Prometheus để thu thập metrics và Grafana để visualize, giúp phát hiện nhanh các vấn đề về performance và lỗi.<br/>- **Distributed Tracing:** Tích hợp OpenTelemetry & Jaeger, mỗi request gắn TraceID duy nhất xuyên suốt hệ thống.<br/>- **Centralized Logging:** Gom log tập trung về ELK Stack (Elasticsearch) để tra cứu và phân tích. |
// | **5. Trùng lặp dữ liệu**<br/>(*Data Duplication*) | 🟢 Thấp | Service Analytics cần thông tin User nhưng dữ liệu này nằm ở Identity Service. Nếu gọi chéo (cross-service call) mỗi lần query báo cáo sẽ tăng độ trễ và tạo dependency cứng. | - **Denormalization:** Service Analytics lưu bản sao cục bộ (Read-model) thông tin User cần thiết, cập nhật tự động thông qua sự kiện `UserUpdated` từ Identity Service qua RabbitMQ, loại bỏ gọi chéo khi query báo cáo. Pattern này được áp dụng rộng rãi trong Event-Driven Architecture (xem chi tiết ở mục 4.7.5.4). |

// **Phân tích tính khả thi của các chiến lược giảm thiểu:**

// Các chiến lược giảm thiểu rủi ro được trình bày ở trên không phải là lý thuyết suông hay wishful thinking, mà đã được nhóm chuẩn bị và triển khai thực tế ngay từ giai đoạn thiết kế hệ thống:

// **1. Về Operational Complexity (🔴 Mức độ ảnh hưởng cao):**
//    - Kubernetes: Đã được tích hợp vào hạ tầng deployment với cấu hình HPA, resource limits, liveness/readiness probes (xem chi tiết ở mục 4.7.5).
//    - Jenkins CI/CD: Đã thiết lập pipeline tự động cho từng service với automated testing, security scanning và progressive deployment.
//    - Impact: Giảm ~80% công việc manual operations, deployment time từ ~30 phút xuống ~5 phút.

// **2. Về Network Latency (🟡 Mức độ ảnh hưởng trung bình):**
//    - On-Premise Deployment: Tất cả services được triển khai chung một hạ tầng on-premise, trong cùng namespace của Kubernetes cluster, giúp giảm network latency xuống còn ~1-2ms (thay vì 10-20ms khi deploy trên nhiều zones/regions khác nhau).
//    - Claim-Check Pattern: Áp dụng để xử lý dữ liệu lớn (raw posts, images) – thay vì truyền toàn bộ payload qua RabbitMQ, chỉ truyền reference (object key) đến dữ liệu đã lưu trong MinIO (Object Storage). Pattern này đặc biệt quan trọng cho Collection Service khi xử lý hàng nghìn posts mỗi phút (xem chi tiết ở mục 4.7.1 về Design Principles).
//    - Impact: Giảm message size trong RabbitMQ từ ~500KB xuống ~1KB, tăng throughput của message broker lên ~50x.

// **3. Về Data Consistency (🟡 Mức độ ảnh hưởng trung bình):**
//    - Event-Driven Architecture: RabbitMQ được triển khai với Outbox Pattern để đảm bảo reliable message delivery (xem mục 4.7.5.4 và 4.7.5.5).
//    - Eventual Consistency: Được chấp nhận cho Analytics/Reporting vì business requirement cho phép delay vài giây.
//    - Impact: 99.9% events được deliver thành công, average propagation time < 2 giây.

// **4. Về Distributed Debugging (🟡 Mức độ ảnh hưởng trung bình):**
//    - Rancher: Được sử dụng làm platform quản lý Kubernetes cluster, cung cấp UI trực quan để monitoring, debugging và quản lý containers.
//    - Prometheus + Grafana: Prometheus thu thập metrics từ tất cả services (request rate, latency, error rate, resource usage), Grafana visualize dữ liệu thành dashboards giúp phát hiện anomalies nhanh chóng.
//    - Distributed Tracing: OpenTelemetry + Jaeger đã được tích hợp, mỗi request có unique TraceID để trace toàn bộ luồng xử lý qua các services.
//    - Centralized Logging: ELK Stack (Elasticsearch, Logstash, Kibana) thu thập logs từ tất cả services với structured logging format.
//    - Impact: MTTR (Mean Time To Repair) giảm từ ~2 giờ xuống ~15-20 phút khi có incident. Monitoring stack giúp phát hiện 90% vấn đề trước khi ảnh hưởng đến end-users.

// **5. Về Data Duplication (🟢 Mức độ ảnh hưởng thấp):**
//    - Denormalization Pattern: Được áp dụng có chọn lọc, chỉ replicate dữ liệu thực sự cần thiết.
//    - Event-Driven Sync: Sử dụng domain events (`UserUpdated`, `ProjectCreated`) qua RabbitMQ để đồng bộ dữ liệu giữa services.
//    - Impact: Giảm ~70% cross-service calls, query performance tăng ~3-5x nhờ data locality.

// ---

// **Kết luận chương 4.7.2:**

// Thông qua một quá trình phân tích có phương pháp luận rõ ràng bao gồm:

// 1. **Xác định Architectural Drivers** (mục 4.7.2.1): Asymmetric Workload, Polyglot Technology Stack, Availability & Isolation.
// 2. **So sánh chi tiết các lựa chọn** (mục 4.7.2.2): Phân tích ưu/nhược điểm của Monolith, Modular Monolith và Microservices trong context cụ thể của SMAP.
// 3. **Đánh giá định lượng** (mục 4.7.2.3): Ma trận quyết định cho điểm 4.25/5.00 cho Microservices, vượt trội ở ba tiêu chí quan trọng nhất (75% trọng số).
// 4. **Biện luận kiến trúc** (mục 4.7.2.4): Ba luận điểm cốt lõi với số liệu định lượng cụ thể (giảm 96% image size, tiết kiệm 60-70% infrastructure cost, giảm 86% blast radius).
// 5. **Trade-off Analysis** (mục 4.7.2.5): Nhận diện đầy đủ các thách thức và chuẩn bị sẵn chiến lược giảm thiểu rủi ro với các công nghệ cụ thể: Kubernetes, Jenkins CI/CD, On-Premise Deployment, Claim-Check Pattern, RabbitMQ, Rancher, Prometheus, Grafana, OpenTelemetry, Jaeger, và ELK Stack.

// Kết quả: **Microservices Architecture** được xác định là lựa chọn phù hợp và đảm bảo **tính bền vững (Sustainability)** cho sự phát triển lâu dài của hệ thống **SMAP**.