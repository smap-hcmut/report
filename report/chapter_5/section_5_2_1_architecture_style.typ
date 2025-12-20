== 5.2.1 Lựa chọn phong cách kiến trúc

=== 5.2.1.1 Bối cảnh quyết định

Việc lựa chọn kiến trúc cho SMAP không chỉ là quyết định công nghệ, mà chính là quá trình giải quyết các mâu thuẫn kỹ thuật (technical trade-offs) xuất phát từ đặc thù nghiệp vụ và yêu cầu phi chức năng của dự án. Trước khi phân tích từng phương án, nhóm xác định các "Architectural Drivers" chính (yếu tố thúc đẩy về kiến trúc):

==== Sự bất đối xứng về tải (Asymmetric Workload)

- *Crawler Service & Analytics Service:* Chạy dưới dạng background job, tiêu tốn tài nguyên CPU và mạng ở mức rất cao (high throughput). Khối lượng xử lý ước tính cao hơn ~10 lần so với các dịch vụ khác, do liên tục ingest và xử lý dữ liệu thô.

- *API Services (Identity, Project, WebSocket):* Chủ yếu phục vụ request/response, cần độ trễ thấp (low latency) để đảm bảo trải nghiệm người dùng cuối.

- *Thách thức:* Nếu hai loại service này chung một hệ thống (monolith), việc crawler chạy tải lớn có thể chiếm dụng tài nguyên, khiến dashboard/API bị chậm hoặc treo toàn hệ thống.

==== Đa dạng công nghệ (Polyglot Technology Stack)

- *Python (3 services):* Analytics, Speech2Text, Scrapper - yêu cầu bắt buộc cho AI/NLP (PyTorch, PhoBERT, Scikit-learn).

- *Golang (4 services):* Identity, Project, Collector, WebSocket - tối ưu cho API nhờ khả năng xử lý đa luồng tốt và tiết kiệm RAM.

- *Next.js/TypeScript (1 service):* Web UI - framework hiện đại cho frontend với SSR support.

- *Thách thức:* Monolith gần như không thể tích hợp, vận hành hiệu quả cùng lúc ba runtime (Python, Go, Node.js) bên trong một tiến trình chung.

==== Yêu cầu về tính sẵn sàng & cô lập (Availability & Isolation)

- *Ví dụ:* Nếu module phân tích AI lỗi (như tràn bộ nhớ do load ML model PhoBERT ~1.2GB) thì không được phép làm sập tính năng đăng nhập hoặc dashboard cho user.

- *Yêu cầu NFR:* AC-1 (Availability 99.5% overall, 99.9% cho Alert Service).

- *Thách thức:* Cần một kiến trúc mà lỗi từng phần không ảnh hưởng toàn hệ thống.

Dựa trên các yếu tố này, nhóm đề bài lựa chọn 3 mô hình kiến trúc phổ biến để đánh giá và so sánh:
- Monolithic Architecture (Kiến trúc nguyên khối)
- Microservices Architecture (Kiến trúc vi dịch vụ)
- Modular Monolith (Nguyên khối mô-đun hóa)

#import "../counters.typ": table_counter

=== 5.2.1.2 Phân tích các lựa chọn

Dựa trên bối cảnh kỹ thuật đã xác lập, nhóm phân tích 3 mô hình kiến trúc dưới góc độ vận hành thực tiễn của SMAP.

==== 1. Monolithic Architecture (Kiến trúc nguyên khối)

Trong mô hình này, toàn bộ hệ thống (module Crawler, Analytics, API) được tích hợp vào một ứng dụng duy nhất, triển khai như một đơn vị (single deployable unit).

*Ưu điểm:*

- *Đơn giản trong phát triển ban đầu:* Không cần thiết lập hạ tầng phân tán, dễ dàng debug và test toàn bộ hệ thống trong môi trường local.

- *Hiệu năng giao tiếp nội bộ:* Các module giao tiếp trực tiếp qua function calls (in-process), độ trễ cực thấp (microseconds), không có overhead của network.

- *Giao dịch ACID dễ dàng:* Tất cả dữ liệu nằm trong một database, có thể sử dụng transaction để đảm bảo tính nhất quán dữ liệu.

- *Chi phí vận hành thấp:* Chỉ cần quản lý một ứng dụng, một database, giảm thiểu độ phức tạp DevOps.

*Nhược điểm trong context SMAP:*

- *Không giải quyết được bài toán Polyglot Runtime:* Việc tích hợp Python (Crawler/Analytics) và Golang (API) vào một khối đòi hỏi các giải pháp phức tạp:
  - CGO (C bindings): Cho phép Go gọi code C/Python nhưng gây rủi ro về memory management, dễ leak và khó debug.
  - Sub-process calls: Gọi Python script từ Go qua command line, tăng độ trễ đáng kể (từ microseconds lên milliseconds) và khó quản lý lifecycle.
  - Docker multi-stage build phức tạp: Phải đóng gói cả Python runtime và Go binary vào một image, làm tăng kích thước container từ ~20MB (Go Alpine) lên ~500MB+ (Python + dependencies).

- *Không thể scale độc lập (Independent Scaling):* Khi Crawler Service cần scale lên 20 pods để xử lý chiến dịch lớn, phải scale toàn bộ monolith, kéo theo cả API Service không cần thiết → lãng phí tài nguyên (over-provisioning). Ví dụ: Chi phí cloud tăng 10x nhưng chỉ 10% tài nguyên được sử dụng cho API.

- *Rủi ro tài nguyên (Resource Contention):* Crawler tiêu tốn CPU/RAM gấp ~10 lần API. Khi Crawler hoạt động mạnh, nó chiếm dụng toàn bộ tài nguyên server, khiến các request đơn giản (đăng nhập, xem báo cáo) bị timeout hoặc bị từ chối (throttling).

- *Blast radius lớn:* Nếu module Analytics bị crash do OOM khi load model AI nặng (PhoBERT ~1.2GB), toàn bộ ứng dụng sẽ sập, kéo theo cả API Service ngừng hoạt động → vi phạm yêu cầu Availability 99.5%.

==== 2. Modular Monolith (Nguyên khối mô-đun hóa)

Mô hình này chia tách code thành các module rõ ràng theo domain (Domain-Driven Design), nhưng vẫn chạy trên một tiến trình (Single Process) và một môi trường runtime (Single Runtime).

*Ưu điểm:*

- *Tổ chức code tốt:* Áp dụng nguyên tắc Separation of Concerns, mỗi module có trách nhiệm rõ ràng, dễ maintain và test từng module độc lập.

- *Dễ refactor:* Có thể tách module thành microservice sau này khi cần thiết (Strangler Pattern).

- *Đơn giản hơn Microservices:* Không cần quản lý network communication, service discovery, distributed tracing phức tạp.

*Nhược điểm trong context SMAP:*

- *Vẫn không giải quyết được bài toán Polyglot Runtime:* Giống như Monolith, Modular Monolith vẫn chỉ chạy trên một runtime duy nhất. Nếu chọn Python làm runtime chính, API Service sẽ mất đi lợi thế về hiệu năng của Golang. Nếu chọn Go, phải giải quyết vấn đề tích hợp Python (CGO/sub-process) như đã nêu ở Monolith.

- *Không có Runtime Isolation:* Tất cả modules chạy chung một process, chia sẻ cùng một heap memory. Nếu module Analytics bị memory leak khi load model AI nặng, nó sẽ chiếm dụng toàn bộ RAM của process, khiến các module khác (API, Crawler) không còn tài nguyên để hoạt động → toàn bộ ứng dụng crash.

- *Không thể scale độc lập:* Giống Monolith, phải scale toàn bộ ứng dụng, không thể chỉ scale Crawler Service khi cần thiết.

- *Deployment coupling:* Mọi thay đổi code ở bất kỳ module nào đều yêu cầu rebuild và redeploy toàn bộ ứng dụng, tăng rủi ro và thời gian downtime.

*Khi nào phù hợp:* Modular Monolith phù hợp cho các hệ thống:
- Có workload đồng đều giữa các modules
- Sử dụng cùng một technology stack
- Team nhỏ, chưa có kinh nghiệm với distributed systems
- Yêu cầu đơn giản về scalability và fault isolation

==== 3. Microservices Architecture (Kiến trúc vi dịch vụ)

Hệ thống được chia tách vật lý thành các service riêng biệt, mỗi service có thể được phát triển, triển khai và scale độc lập. Trong SMAP, các services chính bao gồm: Identity Service, Project Service, Collector Service, Analytics Service, Speech2Text Service, WebSocket Service, Web UI.

*Ưu điểm:*

- *Scale chính xác (Precision Scaling):* Khi có chiến dịch lớn cần crawl 10M posts, nhóm chỉ cần tăng số lượng container cho Crawler Service từ 2 lên 20 pods. API Service và các service khác vẫn giữ nguyên 2 pods. Điều này tối ưu hóa triệt để chi phí hạ tầng, chỉ trả tiền cho tài nguyên thực sự sử dụng.

- *Đa dạng Runtime (Polyglot Runtime):* Mỗi service có thể chọn technology stack phù hợp nhất:
  - *Python Services (3 services):* Analytics, Speech2Text, Scrapper - chạy trong môi trường Python container đầy đủ thư viện (PyTorch, Scikit-learn, PhoBERT), image size ~500MB.
  - *Golang Services (4 services):* Identity, Project, Collector, WebSocket - chạy trong môi trường Alpine Linux siêu nhẹ của Go, image size ~20MB.
  - *Next.js Service (1 service):* Web UI - Node.js runtime với SSR support, image size ~150MB.
  - Không có xung đột thư viện hoặc runtime conflicts.

- *Cô lập lỗi (Fault Isolation):* Mỗi service chạy trong container riêng biệt với resource limits. Nếu Analytics Service bị OOM khi load model AI, nó chỉ crash container của chính nó, không ảnh hưởng đến các service khác. API Service vẫn tiếp tục phục vụ user đăng nhập và xem dashboard.

- *Phát triển độc lập (Independent Development):* Các team có thể phát triển và deploy services độc lập, không cần chờ các team khác, tăng tốc độ phát triển (faster time-to-market).

- *Technology Evolution:* Có thể nâng cấp hoặc thay thế technology stack của từng service mà không ảnh hưởng đến services khác. Ví dụ: Nâng cấp Analytics Service từ Python 3.10 lên 3.12 để tận dụng performance improvements.

*Nhược điểm trong context SMAP:*

- *Độ phức tạp vận hành:* Quản lý nhiều service, cần hạ tầng orchestration (Kubernetes), service discovery, monitoring, logging tập trung.

- *Độ trễ mạng:* Giao tiếp giữa các service qua network (10-20ms) thay vì function call (microseconds).

- *Nhất quán dữ liệu:* Không thể sử dụng ACID transactions giữa các service. SMAP giải quyết bằng Event-Driven Architecture với RabbitMQ.

- *Chi phí vận hành cao hơn:* Cần nhiều tài nguyên vận hành hơn (Kubernetes control plane, monitoring tools, RabbitMQ cluster).

=== 5.2.1.3 Ma trận quyết định

Sau khi phân tích chi tiết từng mô hình kiến trúc, nhóm xây dựng ma trận quyết định định lượng để so sánh khách quan các lựa chọn.

==== Bảng so sánh tổng quan theo tiêu chí chất lượng

Bảng dưới đây so sánh ba mô hình kiến trúc theo các tiêu chí chất lượng kiến trúc phổ biến (Architectural Quality Attributes), sử dụng thang điểm từ 1 (kém nhất) đến 5 (tốt nhất):

#context (align(center)[_Bảng #table_counter.display(): So sánh các phong cách kiến trúc_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.25fr, 0.25fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, center, center, center),
    [*Tiêu chí*], [*Monolithic*], [*Modular Monolith*], [*Microservices*],
    [Cost (Chi phí)], [5], [5], [2],
    [Maintainability], [2], [4], [5],
    [Testability], [2], [3], [5],
    [Deployability], [1], [3], [5],
    [Simplicity], [5], [4], [2],
    [Scalability], [2], [3], [5],
    [Elasticity], [1], [2], [5],
    [Responsiveness], [3], [3], [5],
    [Fault-tolerance], [2], [3], [5],
    [Evolvability], [2], [3], [5],
    [Interoperability], [2], [3], [5],
  )
]

*Nhận xét:* Microservices Architecture đạt điểm cao nhất (5 điểm) ở hầu hết các tiêu chí liên quan đến khả năng mở rộng, khả năng chịu lỗi và tính linh hoạt. Tuy nhiên, Monolithic Architecture lại vượt trội về Simplicity (5 điểm) và Cost (5 điểm), phù hợp với các dự án nhỏ hoặc MVP.

==== Ma trận trọng số dựa trên Architectural Drivers của SMAP

Để lượng hóa sự lựa chọn phù hợp với context của SMAP, nhóm xây dựng ma trận trọng số tập trung vào ba Architectural Drivers chính:

#context (align(center)[_Bảng #table_counter.display(): Ma trận trọng số theo Architectural Drivers_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.3fr, 0.15fr, 0.15fr, 0.15fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, center, center, center, center),
    [*Architectural Driver*], [*Trọng số*], [*Monolithic*], [*Modular Monolith*], [*Microservices*],
    [Polyglot Runtime Support], [40%], [1/5], [1/5], [5/5],
    [Independent Scaling], [30%], [1/5], [2/5], [5/5],
    [Fault Isolation], [20%], [2/5], [3/5], [5/5],
    [Development Velocity], [10%], [4/5], [4/5], [4/5],
    [*Tổng điểm (weighted)*], [], [1.5], [2.0], [4.7],
  )
]

*Kết quả:* Microservices Architecture đạt 4.7/5.0 điểm (94%), vượt trội so với Monolithic (1.5/5.0 - 30%) và Modular Monolith (2.0/5.0 - 40%). Ba Architectural Drivers chính (Polyglot, Scaling, Fault Isolation) chiếm 90% trọng số quyết định.

=== 5.2.1.4 Evidence từ hệ thống thực tế

Dựa trên source code đã triển khai, hệ thống SMAP hiện có 7 microservices độc lập:

#context (align(center)[_Bảng #table_counter.display(): Danh sách services thực tế_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.05fr, 0.25fr, 0.15fr, 0.15fr, 0.15fr, 0.25fr),
    stroke: 0.5pt,
    align: (center, left, center, center, center, left),
    [*#*], [*Service*], [*Tech Stack*], [*Image Size*], [*Lines of Code*], [*Key Features*],
    [1], [Identity], [Go 1.25], [~25MB], [~10K], [JWT, bcrypt, HttpOnly cookies],
    [2], [Project], [Go 1.25], [~25MB], [~12K], [Project CRUD, Event publish],
    [3], [Collector], [Go 1.25], [~30MB], [~8K], [Dispatcher, Master-Worker],
    [4], [Analytics], [Python 3.12], [~520MB], [~15K], [PhoBERT, NLP pipeline],
    [5], [Speech2Text], [Python 3.12], [~480MB], [~8K], [ASR, Whisper model],
    [6], [WebSocket], [Go 1.25], [~22MB], [~5K], [Real-time, Redis Pub/Sub],
    [7], [Web UI], [Next.js 15], [~160MB], [~8K], [SSR, React 19, Tailwind],
  )
]

*Polyglot Runtime Evidence:*
- Go services: Total 4 services, ~70MB combined (excluding web UI)
- Python services: Total 3 services, ~1GB combined
- Next.js service: 1 service, ~160MB
- *Tổng 3 runtimes khác nhau không thể chạy trong một monolith*

*Independent Scaling Evidence (từ docker-compose và K8s manifests):*
- Identity: 2 replicas (stable workload)
- Project: 2 replicas (stable workload)
- Collector: 2-10 replicas (auto-scale based on queue length)
- Analytics: 3-20 replicas (auto-scale based on CPU)
- WebSocket: 2-5 replicas (based on connection count)
- Web UI: 3 replicas (fixed)

*Fault Isolation Evidence:*
- Mỗi service có Dockerfile riêng với resource limits
- Kubernetes liveness/readiness probes cho mỗi service
- RabbitMQ dead-letter queue cho failed messages
- Redis Pub/Sub cho event isolation

=== 5.2.1.5 Quyết định cuối cùng

Dựa trên phân tích trên, nhóm quyết định chọn *Microservices Architecture* làm phong cách kiến trúc chính cho hệ thống SMAP.

*Lý do chính:*

1. *Polyglot Runtime (40% trọng số):* Là yêu cầu bắt buộc do đặc thù kỹ thuật:
   - Python không thể thay thế cho AI/NLP (PhoBERT, PyTorch)
   - Golang không thể thay thế cho API performance
   - Monolith và Modular Monolith đều không giải quyết được vấn đề này

2. *Independent Scaling (30% trọng số):* Chênh lệch workload ~10x giữa Crawler/Analytics và API:
   - Microservices cho phép scale chính xác từng service
   - Tiết kiệm chi phí: Chỉ scale service cần thiết
   - Đáp ứng AC-2 (Scalability: 1,000 items/min with 10 workers)

3. *Fault Isolation (20% trọng số):* Đảm bảo yêu cầu Availability 99.5%:
   - Analytics crash không làm sập Identity/Project
   - Đáp ứng AC-1 (Availability 99.5% overall)

4. *Evidence từ code:* Hệ thống đã triển khai 7 services với 3 runtimes khác nhau, chứng minh tính khả thi và hiệu quả của Microservices.

*Trade-offs được chấp nhận:*

- Độ phức tạp vận hành cao hơn → Giải quyết bằng Kubernetes + Docker Compose
- Độ trễ mạng ~10-20ms → Chấp nhận được so với lợi ích về scalability và isolation
- Chi phí vận hành cao hơn → Được bù đắp bằng precision scaling (tiết kiệm compute cost)

Quyết định này phù hợp với các yêu cầu phi chức năng đã đặt ra ở Chapter 4, đặc biệt là AC-1 (Modularity), AC-2 (Scalability), và AC-3 (Performance).

