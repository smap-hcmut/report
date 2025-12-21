#import "../counters.typ": image_counter, table_counter

== 5.2 Kiến trúc tổng thể

=== 5.2.1 Lựa chọn phong cách kiến trúc

==== 5.2.1.1 Bối cảnh quyết định

Việc lựa chọn kiến trúc cho SMAP không chỉ là quyết định công nghệ, mà chính là quá trình giải quyết các mâu thuẫn kỹ thuật xuất phát từ đặc thù nghiệp vụ và yêu cầu phi chức năng của dự án. Trước khi phân tích từng phương án, nhóm xác định các yếu tố thúc đẩy về kiến trúc:

*a. Sự bất đối xứng về tải*

Crawler Service và Analytics Service chạy dưới dạng background job, tiêu tốn tài nguyên CPU và mạng ở mức rất cao. Khối lượng xử lý ước tính cao hơn đáng kể so với các dịch vụ khác, do liên tục ingest và xử lý dữ liệu thô.

API Services chủ yếu phục vụ request/response, cần độ trễ thấp để đảm bảo trải nghiệm người dùng cuối.

Thách thức: Nếu hai loại service này chung một hệ thống monolith, việc crawler chạy tải lớn có thể chiếm dụng tài nguyên, khiến dashboard và API bị chậm hoặc treo toàn hệ thống.

*b. Đa dạng công nghệ*

Python services yêu cầu bắt buộc cho AI/NLP với các thư viện như PyTorch, PhoBERT, Scikit-learn và thư viện phong phú khác.

Golang: Identity, Project, Collector, WebSocket - tối ưu cho API nhờ khả năng xử lý đa luồng tốt và tiết kiệm RAM, tối ưu cho các tác vụ I/O.

Next.js/TypeScript - Web UI - framework hiện đại cho frontend với SSR support.

Thách thức: Monolith gần như không thể tích hợp và vận hành hiệu quả cùng lúc ba runtime gồm Python, Go và Node.js bên trong một tiến trình chung.

*c. Yêu cầu về tính sẵn sàng và cô lập*

Khi Module phân tích AI lỗi, ví dụ tràn bộ nhớ do load ML model PhoBERT, thì không được phép làm sập tính năng đăng nhập hoặc dashboard cho user.

Yêu cầu NFR: AC-1.

Thách thức: Cần một kiến trúc mà lỗi từng phần không ảnh hưởng toàn hệ thống.

Dựa trên các yếu tố này, nhóm tác giả lựa chọn 3 mô hình kiến trúc phổ biến để đánh giá và so sánh:
- Monolithic Architecture
- Microservices Architecture
- Modular Monolith

Việc lựa chọn kiến trúc phù hợp là quyết định quan trọng nhất trong thiết kế hệ thống, ảnh hưởng trực tiếp đến khả năng đáp ứng các yêu cầu phi chức năng đã được xác định tại Chương 4, Mục 4.3.

==== 5.2.1.2 Phân tích các lựa chọn

Dựa trên bối cảnh kỹ thuật đã xác lập, nhóm phân tích 3 mô hình kiến trúc dưới góc độ vận hành thực tiễn của SMAP.

*a. Monolithic Architecture*

Trong mô hình này, toàn bộ hệ thống gồm module Crawler, Analytics và API được tích hợp vào một ứng dụng duy nhất, triển khai như một đơn vị.

#align(center)[
  #image("../images/architecture/monolithic_architecture.png", width: 25%)
  #context (align(center)[_Hình #image_counter.display(): Monolithic Architecture_])
  #image_counter.step()
]

Ưu điểm:
- Đơn giản trong phát triển ban đầu: không cần thiết lập hạ tầng phân tán, dễ dàng debug và test toàn bộ hệ thống trong môi trường local.
- Hiệu năng giao tiếp nội bộ: các module giao tiếp trực tiếp qua function calls, độ trễ cực thấp, không có overhead của network.
- Giao dịch ACID dễ dàng: tất cả dữ liệu nằm trong một database, có thể sử dụng transaction để đảm bảo tính nhất quán dữ liệu.
- Chi phí vận hành thấp: chỉ cần quản lý một ứng dụng, một database, giảm thiểu độ phức tạp DevOps.

Nhược điểm trong context SMAP:
- Không giải quyết được bài toán Polyglot Runtime: Việc tích hợp Python và Golang vào một khối đòi hỏi các giải pháp phức tạp như CGO, sub-process calls hoặc Docker multi-stage build phức tạp.

- Không thể scale độc lập: Khi Crawler Service cần scale lên để xử lý chiến dịch lớn, phải scale toàn bộ monolith, kéo theo cả API Service không cần thiết, dẫn đến lãng phí tài nguyên do over-provisioning.

- Rủi ro tài nguyên: Crawler tiêu tốn CPU và RAM cao hơn đáng kể so với API. Khi Crawler hoạt động mạnh, nó chiếm dụng toàn bộ tài nguyên server, khiến các request đơn giản như đăng nhập và xem báo cáo bị timeout hoặc bị từ chối do throttling.

- Blast radius lớn: Nếu module Analytics bị crash do OOM khi load model AI nặng như PhoBERT, toàn bộ ứng dụng sẽ sập, kéo theo cả API Service ngừng hoạt động, vi phạm yêu cầu Availability theo AC-1 tại Section 4.3.1.1. Đây là rủi ro cao không thể chấp nhận trong môi trường production.

*b. Modular Monolith*

Modular Monolith chia tách code thành các module rõ ràng theo domain theo phương pháp Domain-Driven Design, nhưng vẫn chạy trên một tiến trình duy nhất và một môi trường runtime duy nhất.

#align(center)[
  #image("../images/architecture/modular_monolith.png", width: 70%)
  #context (align(center)[_Hình #image_counter.display(): Modular Monolith Architecture_])
  #image_counter.step()
]

Ưu điểm:

- Tổ chức code tốt: Áp dụng nguyên tắc Separation of Concerns, mỗi module có trách nhiệm rõ ràng, dễ maintain và test từng module độc lập.
- Dễ refactor: Có thể tách module thành microservice sau này khi cần thiết theo Strangler Pattern.
- Đơn giản hơn Microservices: Không cần quản lý network communication, service discovery, distributed tracing phức tạp.

Nhược điểm trong context SMAP:

- Vẫn không giải quyết được bài toán polyglot runtime: Giống như monolith, modular monolith vẫn chỉ chạy trên một runtime duy nhất. Nếu chọn Python làm runtime chính, API service sẽ mất đi lợi thế về hiệu năng của Golang. Nếu chọn Go, phải giải quyết vấn đề tích hợp Python thông qua CGO hoặc sub-process như đã nêu ở monolith.

- Không có runtime isolation: Tất cả modules chạy chung một process, chia sẻ cùng một heap memory. Nếu module analytics bị memory leak khi load model AI nặng, nó sẽ chiếm dụng toàn bộ RAM của process, khiến các module khác như API và crawler không còn tài nguyên để hoạt động, dẫn đến toàn bộ ứng dụng crash.

- Không thể scale độc lập: Giống monolith, phải scale toàn bộ ứng dụng, không thể chỉ scale crawler service khi cần thiết.

- Deployment coupling: Mọi thay đổi code ở bất kỳ module nào đều yêu cầu rebuild và redeploy toàn bộ ứng dụng, tăng rủi ro và thời gian downtime.

Khi nào phù hợp: Modular monolith phù hợp cho các hệ thống có workload đồng đều giữa các modules, sử dụng cùng một technology stack, team nhỏ chưa có kinh nghiệm với distributed systems, và yêu cầu đơn giản về scalability và fault isolation. Tuy nhiên, SMAP không phù hợp do có asymmetric workload, polyglot requirement, và yêu cầu cao về cả scalability và fault isolation.

Kết luận: Modular monolith không phù hợp với context của SMAP do không giải quyết được 3 architectural drivers chính.

*c. Microservices Architecture*

Microservices Architecture chia tách vật lý hệ thống thành các service riêng biệt, mỗi service có thể được phát triển, triển khai và scale độc lập. Trong SMAP, các services chính bao gồm: Identity Service, Project Service, Collector Service, Analytics Service, Speech2Text Service, WebSocket Service, Web UI.

#align(center)[
  #image("../images/architecture/microservices_architecture.png", width: 50%)
  #context (align(center)[_Hình #image_counter.display(): Microservices Architecture_])
  #image_counter.step()
]

Ưu điểm:

- Scale chính xác: Khi có chiến dịch lớn cần crawl dữ liệu lớn, nhóm chỉ cần tăng số lượng container cho Crawler Service. API Service và các service khác vẫn giữ nguyên. Điều này tối ưu hóa triệt để chi phí hạ tầng, chỉ trả tiền cho tài nguyên thực sự sử dụng.

- Đa dạng Runtime: Mỗi service có thể chọn technology stack phù hợp nhất. Python Services cho Analytics, Speech2Text, Scrapper, FFmpeg và Playwright, chạy trong môi trường Python container đầy đủ thư viện như PyTorch, Scikit-learn và PhoBERT. Golang Services cho Identity, Project, Collector và WebSocket, chạy trong môi trường Alpine Linux siêu nhẹ của Go. Next.js Service cho Web UI, sử dụng Node.js runtime với SSR support. Không có xung đột thư viện hoặc runtime conflicts.

- Cô lập lỗi: Mỗi service chạy trong container riêng biệt với resource limits. Nếu Analytics Service bị OOM khi load model AI, nó chỉ crash container của chính nó, không ảnh hưởng đến các service khác. API Service vẫn tiếp tục phục vụ user đăng nhập và xem dashboard.

- Phát triển độc lập: Các team có thể phát triển và deploy services độc lập, không cần chờ các team khác, tăng tốc độ phát triển và đưa sản phẩm ra thị trường nhanh hơn.

- Technology Evolution: Có thể nâng cấp hoặc thay thế technology stack của từng service mà không ảnh hưởng đến services khác. Ví dụ: Nâng cấp Analytics Service từ Python 3.10 lên 3.12 để tận dụng các cải tiến về hiệu năng.

Nhược điểm trong context SMAP:

- Độ phức tạp vận hành: Quản lý nhiều service, cần hạ tầng orchestration như Kubernetes, service discovery, monitoring và logging tập trung.

- Độ trễ mạng: Giao tiếp giữa các service qua network với độ trễ cao hơn so với function call. Tuy nhiên, trade-off này được chấp nhận do lợi ích về scalability vượt trội.

- Nhất quán dữ liệu: Không thể sử dụng ACID transactions giữa các service. SMAP giải quyết bằng Event-Driven Architecture với RabbitMQ, áp dụng Eventual Consistency pattern.

- Chi phí vận hành cao hơn: Cần nhiều tài nguyên vận hành hơn, ví dụ Kubernetes control plane, monitoring stack, RabbitMQ cluster. Chi phí này được bù đắp bằng precision scaling, tiết kiệm đáng kể compute cost trong peak loads.

==== 5.2.1.3 Ma trận quyết định

Sau khi phân tích chi tiết từng mô hình kiến trúc, nhóm xây dựng ma trận quyết định định lượng để so sánh khách quan các lựa chọn.

*a. Bảng so sánh tổng quan theo tiêu chí chất lượng*

Bảng dưới đây so sánh ba mô hình kiến trúc theo các tiêu chí chất lượng kiến trúc phổ biến, sử dụng thang điểm từ 1 (kém nhất) đến 5 (tốt nhất):

#context (align(center)[_Bảng #table_counter.display(): So sánh các phong cách kiến trúc_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.25fr, 0.25fr, 0.25fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, center, center, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Monolithic*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Modular Monolith*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Microservices*],
    table.cell(align: horizon, inset: (y: 0.8em))[Cost],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: horizon, inset: (y: 0.8em))[Maintainability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Testability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Deployability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Simplicity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: horizon, inset: (y: 0.8em))[Scalability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Elasticity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Responsiveness],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Fault-tolerance],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Evolvability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: horizon, inset: (y: 0.8em))[Interoperability],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
  )
]

Nhận xét: Microservices Architecture đạt điểm cao nhất ở hầu hết các tiêu chí liên quan đến khả năng mở rộng, khả năng chịu lỗi và tính linh hoạt. Tuy nhiên, Monolithic Architecture lại vượt trội về Simplicity và Cost, phù hợp với các dự án nhỏ hoặc MVP.

*b. Ma trận trọng số dựa trên Architectural Drivers của SMAP*

Để lượng hóa sự lựa chọn phù hợp với context của SMAP, nhóm xây dựng ma trận trọng số tập trung vào ba Architectural Drivers chính:

#context (align(center)[_Bảng #table_counter.display(): Ma trận trọng số theo Architectural Drivers_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.3fr, 0.15fr, 0.15fr, 0.15fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, center, center, center, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Architectural Driver*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trọng số*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Monolithic*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Modular Monolith*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Microservices*],
    table.cell(align: horizon, inset: (y: 0.8em))[Polyglot Runtime Support],
    table.cell(align: center + horizon, inset: (y: 0.8em))[40%],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5/5],
    table.cell(align: horizon, inset: (y: 0.8em))[Independent Scaling],
    table.cell(align: center + horizon, inset: (y: 0.8em))[30%],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5/5],
    table.cell(align: horizon, inset: (y: 0.8em))[Fault Isolation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[20%],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5/5],
    table.cell(align: horizon, inset: (y: 0.8em))[Development Velocity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[10%],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4/5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4/5],
    table.cell(align: horizon, inset: (y: 0.8em))[*Tổng điểm*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1.5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2.0],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4.7],
  )
]

Kết quả: Microservices Architecture đạt điểm cao nhất, vượt trội so với Monolithic và Modular Monolith. Ba Architectural Drivers chính chiếm phần lớn trọng số quyết định.

==== 5.2.1.4 Chứng cứ từ hệ thống thực tế

Dựa trên source code đã triển khai, hệ thống SMAP hiện có 7 core microservices và 3 supporting services:

#context (align(center)[_Bảng #table_counter.display(): Danh sách Core Microservices_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.1fr, 0.25fr, 0.35fr, 0.3fr),
    stroke: 0.5pt,
    align: (center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*STT*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tên Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Chức năng chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý xác thực, cấp phát JWT, quản lý tài khoản],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý dự án: CRUD, trạng thái thực thi, orchestration],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, PostgreSQL, \ Redis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Dispatch job thu thập dữ liệu và tracking tiến độ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, PostgreSQL, \ Redis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Giao tiếp realtime, truyền phát trạng thái hệ thống],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Golang, Redis Pub/Sub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Pipeline NLP: phân tích Intent, Sentiment, Impact, xử lý batch dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, PostgreSQL, \ MinIO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[6],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Speech2Text Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Chuyển đổi audio sang transcript bằng Whisper],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, MinIO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[7],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web UI],
    table.cell(align: horizon, inset: (y: 0.8em))[Dashboard quản trị, cấu hình dự án, realtime view],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js Frontend],
  )
]

Ngoài ra, hệ thống còn có 3 supporting services hỗ trợ cho các core services:

#context (align(center)[_Bảng #table_counter.display(): Danh sách Supporting Services_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.1fr, 0.25fr, 0.35fr, 0.3fr),
    stroke: 0.5pt,
    align: (center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*STT*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tên Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Chức năng chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scrapper Services],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Thu thập dữ liệu thô từ các nền tảng mạng xã hội],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, Playwright],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FFmpeg Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Xử lý media: tải xuống, chuyển đổi audio/video dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, FFmpeg],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Playwright Service],
    table.cell(align: horizon, inset: (y: 0.8em))[Tự động hóa browser, crawling nâng cao dữ liệu],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python, Playwright],
  )
]

*Polyglot Runtime Evidence:*

Hệ thống sử dụng 3 runtimes khác nhau, mỗi runtime được tối ưu cho use case cụ thể:
- Go services: Các core services với image size nhỏ, startup time nhanh
- Python services: Core và supporting services với thư viện AI/ML phong phú
- Next.js service: Frontend service với SSR support

Việc sử dụng đa dạng runtime này không thể thực hiện được trong một monolith, chứng minh tính cần thiết của kiến trúc Microservices.

*Independent Scaling Evidence:*

Từ docker-compose và Kubernetes manifests, các services có khả năng scale độc lập:
- Identity và Project: Số lượng replicas ổn định do workload đều
- Collector: Auto-scale dựa trên queue depth và CPU usage
- Analytics: Auto-scale dựa trên CPU và memory usage
- WebSocket: Scale dựa trên số lượng connections
- Web UI: Số lượng replicas cố định với CDN support
- Scrapper Services: Scale độc lập theo workload của từng platform

Khả năng scale độc lập này cho phép tối ưu hóa tài nguyên và chi phí vận hành.

*Fault Isolation Evidence:*

Mỗi service có các cơ chế cô lập lỗi:
- Dockerfile riêng với resource limits
- Kubernetes liveness/readiness probes
- RabbitMQ dead-letter queue cho failed messages
- Redis Pub/Sub cho event isolation
- Circuit breaker pattern implementation
- Health check endpoints với detailed status

Các cơ chế này đảm bảo lỗi ở một service không lan truyền sang các service khác, duy trì tính sẵn sàng của hệ thống.

==== 5.2.1.5 Quyết định cuối cùng

Dựa trên phân tích trên, nhóm quyết định chọn Microservices Architecture làm phong cách kiến trúc chính cho hệ thống SMAP.

Lý do chính:

a. Polyglot Runtime: Là yêu cầu bắt buộc do đặc thù kỹ thuật. Python không thể thay thế cho AI/NLP, Golang không thể thay thế cho API performance. Monolith và Modular Monolith đều không giải quyết được vấn đề này.

b. Independent Scaling: Chênh lệch workload lớn giữa Crawler/Analytics và API. Microservices cho phép scale chính xác từng service, tiết kiệm chi phí và đáp ứng yêu cầu về Scalability.

c. Fault Isolation: Đảm bảo yêu cầu Availability. Analytics crash không làm sập Identity/Project, đáp ứng AC-1.

d. Evidence từ code: Hệ thống đã triển khai thành công với 7 core services và 3 supporting services, chứng minh tính khả thi và hiệu quả của Microservices.

Trade-offs được chấp nhận:

- Độ phức tạp vận hành cao hơn: Giải quyết bằng Infrastructure as Code, GitOps, và automated monitoring
- Độ trễ mạng: Chấp nhận được do lợi ích về scalability và isolation
- Chi phí vận hành ban đầu cao hơn: ROI positive nhờ precision scaling và giảm downtime cost

Quyết định này phù hợp với các yêu cầu phi chức năng đã đặt ra ở Chapter 4, Section 4.3, đặc biệt là:
- AC-1 về Modularity: Microservices đảm bảo loose coupling giữa domains
- AC-2 về Scalability: Independent scaling cho từng service theo workload
- AC-3 về Performance: Polyglot optimization cho từng use case

=== 5.2.2 Phân rã hệ thống

Dựa trên quyết định lựa chọn kiến trúc Microservices tại mục 5.2.1, thách thức then chốt tiếp theo là xác định ranh giới cho từng service. Nếu phân rã hệ thống không hợp lý, chia quá nhỏ hoặc quá lớn, sẽ dễ dẫn tới rủi ro hình thành Distributed Monolith, khiến hệ thống vừa phải gánh chịu toàn bộ độ phức tạp của distributed architecture nhưng lại không tận dụng tốt tính linh hoạt vốn có.

Mục tiêu phần này là xây dựng kiến trúc dịch vụ đảm bảo hai nguyên tắc vàng trong thiết kế phần mềm:

- High Cohesion: Các thành phần bên trong một service có mối liên hệ mạnh mẽ với nhau, cùng phục vụ một business capability cụ thể.
- Low Coupling: Các service có sự phụ thuộc tối thiểu vào nhau, giao tiếp qua well-defined interfaces.

==== 5.2.2.1 Phương pháp phân rã

Để đảm bảo kiến trúc hệ thống phản ánh chính xác nghiệp vụ phức tạp của một nền tảng phân tích mạng xã hội, nhóm phát triển áp dụng phương pháp Domain-Driven Design như đã trình bày ở mục 5.1.1.1. Phương pháp này đã được chứng minh hiệu quả trong việc thiết kế hệ thống phân tán phức tạp. Thay vì phân chia dịch vụ dựa trên các bảng dữ liệu hoặc các tầng kỹ thuật, nhóm phân chia dựa trên các miền nghiệp vụ.

Quy trình phân rã được tiến hành theo 3 bước chính:

*a. Nhận diện các miền con*

Hệ thống SMAP được phân tích và tách thành các miền con, dựa trên vai trò của từng miền đối với hoạt động kinh doanh:

- Core Domain: Là nơi tạo ra lợi thế cạnh tranh chính cho hệ thống, ví dụ Phân tích nội dung và Thu thập dữ liệu. Đây là khu vực tập trung nguồn lực phát triển mạnh nhất.
- Supporting Domain: Bao gồm các chức năng quan trọng nhưng không phải cốt lõi, giúp hỗ trợ cho Core Domain, ví dụ Quản lý dự án.
- Generic Domain: Các chức năng phổ biến, có thể áp dụng các giải pháp đã có sẵn hoặc dùng dịch vụ thứ ba, ví dụ Quản lý định danh và truy cập.

*b. Định nghĩa Bounded Contexts*

Đây là bước trọng yếu để xác lập ranh giới giữa các Microservice. Mỗi Bounded Context là một phạm vi mà trong đó các thuật ngữ nghiệp vụ được hiểu nhất quán và rõ ràng.

Ví dụ: Cùng là thuật ngữ User nhưng trong Context Identity thì là tài khoản đăng nhập với các attributes như email, password và role, còn trong Context Analysis lại là tác giả bài viết trên mạng xã hội với các attributes như social_id, platform và follower_count. Thực tế trong SMAP có nhiều biến thể khác nhau của User entity ở các Bounded Contexts khác nhau. Việc phân định rõ ràng các Bounded Context giúp phòng tránh sự chồng chéo về logic và xung đột dữ liệu giữa các dịch vụ, đảm bảo tính toàn vẹn và bảo trì hệ thống dễ dàng hơn.

*c. Ánh xạ Contexts to Services*

Sau khi xác định các Bounded Context, nhóm chuyển đổi mỗi Context thành một Microservice vật lý tương ứng:

- Nguyên tắc phổ quát: Mỗi Bounded Context nên ánh xạ thành một Microservice riêng biệt theo tỷ lệ 1:1.
- Lưu ý ngoại lệ: Trong trường hợp có hai Context có quan hệ tương tác quá chặt hoặc shared data lớn, có thể cân nhắc gộp chúng vào chung một dịch vụ. Trong SMAP, Analytics và Speech2Text services được tách riêng do khác biệt lớn về resource requirements, cũng như scaling patterns khác nhau.

==== 5.2.2.2 Bounded Contexts đã xác định

Dựa trên phân tích các miền con, hệ thống SMAP được chia thành 5 Bounded Contexts độc lập. Việc xác định ranh giới rõ ràng giúp đảm bảo nguyên tắc Separation of Concerns, mỗi ngữ cảnh chỉ xử lý một tập trung nghiệp vụ cụ thể.

#context (align(center)[_Bảng #table_counter.display(): Bounded Contexts của hệ thống SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.08fr, 0.25fr, 0.15fr, 0.52fr),
    stroke: 0.5pt,
    align: (center, left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*STT*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Context Name*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phân loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mục tiêu chính và Thực thể*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity & Access Management],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Generic Domain],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Quản lý định danh, bảo mật, xác thực. Thực thể: User, Role, AuthSession],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Management],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Supporting Domain],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Cung cấp workspace để người dùng cấu hình, quản lý đối tượng theo dõi. Thực thể: Project, CompetitorProfile, KeywordSet],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Data Collection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Core Domain],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Thu thập dữ liệu thô từ nền tảng bên ngoài thông qua kỹ thuật crawl và ingest. Thực thể: CrawlJob, RawData, PlatformSource],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Content Analysis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Core Domain],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Xử lý thông minh và AI để chuyển hóa dữ liệu thô thành cấu trúc có ý nghĩa. Thực thể: AnalysisTask, SentimentResult, ExtractedEntity, ImpactScore],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business Intelligence],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Core Domain],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Tổng hợp, trực quan hóa số liệu phục vụ phân tích, cảnh báo. Thực thể: CompetitorMetric, TrendLine, NotificationRule, Dashboard],
  )
]

==== 5.2.2.3 Mapping Contexts to Services

Dựa trên 5 Bounded Contexts đã xác định, nhóm áp dụng chiến lược ánh xạ One-to-One Mapping để chuyển đổi các mô hình nghiệp vụ thành các đơn vị phần mềm vật lý.

Chiến lược này đảm bảo tính độc lập cao nhất về mặt triển khai và công nghệ. Hệ thống SMAP được cấu thành từ 7 core Microservices và 3 supporting services:

#context (align(center)[_Bảng #table_counter.display(): Ánh xạ Bounded Contexts sang Services_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.08fr, 0.25fr, 0.25fr, 0.42fr),
    stroke: 0.5pt,
    align: (center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*STT*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Bounded Context*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trách nhiệm và Technology Stack*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity & Access Management],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Quản lý xác thực, cấp phát JWT, quản lý tài khoản. Tech: Golang, PostgreSQL, JWT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Management],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Quản lý dự án: CRUD, trạng thái thực thi, orchestration. Tech: Golang, PostgreSQL, Redis, RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Data Collection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector Service + Scrapper Services],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Dispatch job thu thập dữ liệu và tracking tiến độ. Tech: Golang cho Collector, Python cho Scrapper, Playwright],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Content Analysis],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Service + Speech2Text Service],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Pipeline NLP: phân tích Intent, Sentiment, Impact. Tech: Python, PostgreSQL, MinIO, PhoBERT, Whisper],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business Intelligence],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Service + Web UI],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Giao tiếp realtime, truyền phát trạng thái hệ thống, Dashboard. Tech: Golang, Next.js, Redis Pub/Sub],
  )
]

Lưu ý về Service Decomposition:

- Collector Service: Đóng vai trò Dispatcher và Orchestrator, nhận events từ Project Service và phân phối crawl jobs đến Scrapper Services.
- Scrapper Services là Supporting services: Các workers độc lập chạy trên Python, có thể scale độc lập dựa trên workload. Bao gồm TikTok Worker và YouTube Worker, sử dụng FFmpeg Service và Playwright Service để xử lý media và browser automation.
- FFmpeg Service là Supporting service: Xử lý chuyển đổi media, được gọi bởi Scrapper Services qua HTTP API.
- Playwright Service là Supporting service: Cung cấp browser automation capabilities, được sử dụng bởi TikTok Worker qua WebSocket.
- Analytics Service: Xử lý NLP pipeline cho text content.
- Speech2Text Service: Xử lý audio và video content, chuyển đổi sang transcript bằng Whisper model.

==== 5.2.2.4 Service Responsibility Matrix

Để đảm bảo nguyên tắc Single Responsibility Principle và tránh sự chồng chéo chức năng, nhóm xác định ma trận trách nhiệm chi tiết cho từng dịch vụ. Bảng này đóng vai trò như bản cam kết về phạm vi hoạt động của mỗi service.

#context (align(center)[_Bảng #table_counter.display(): Ma trận trách nhiệm dịch vụ_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.20fr, 0.15fr, 0.30fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, center, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Type*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Core Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Data Ownership*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Dependencies*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Utility],
    table.cell(align: horizon, inset: (y: 0.8em))[Xác thực, Phân quyền, Quản lý phiên],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Users, Roles, Tokens],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Independent],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Aggregator],
    table.cell(align: horizon, inset: (y: 0.8em))[Quản lý workspace, cấu hình đối thủ và từ khóa, publish events],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Projects, Competitors, Keywords],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Orchestrator],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Điều phối quy trình crawl dữ liệu, quản lý jobs, tracking progress, lưu trữ raw data],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CrawlJobs, JobStatus, RawPosts, RawComments],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project, RabbitMQ, Redis, MongoDB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scrapper Services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Worker],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Thu thập dữ liệu thô từ các nền tảng mạng xã hội, gửi về Collector Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Không có data ownership],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Collector, MinIO, FFmpeg, Playwright],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Compute],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Chạy mô hình AI để phân tích cảm xúc, trích xuất thực thể, tính impact],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SentimentResults, Topics, Entities],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ, PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Speech2Text Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Compute],
    table.cell(align: horizon, inset: (y: 0.8em))[Chuyển đổi audio/video sang transcript],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Transcriptions],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIO, RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Real-time],
    table.cell(align: horizon, inset: (y: 0.8em))[Giao tiếp realtime, truyền phát trạng thái hệ thống đến clients],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Connections],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis Pub/Sub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web UI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Frontend],
    table.cell(align: horizon, inset: (y: 0.8em))[Dashboard quản trị, cấu hình dự án, realtime view, visualization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Client State],
    table.cell(align: center + horizon, inset: (y: 0.8em))[All API services, WebSocket],
  )
]

=== 5.2.3 System Context Diagram

System Context Diagram mô tả hệ thống SMAP ở mức độ cao nhất, thể hiện các actors bên ngoài và mối quan hệ của chúng với hệ thống.

#align(center)[
  #image("../images/diagram/context-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): System Context Diagram của SMAP_])
  #image_counter.step()
]

Diagram thể hiện hệ thống SMAP tương tác với ba loại actors chính: Marketing Analyst sử dụng Web UI để quản lý projects và xem analytics, Social Media Platforms cung cấp dữ liệu thô thông qua crawling, và Email Service gửi notifications cho người dùng.

=== 5.2.4 Container Diagram

Container Diagram mô tả các containers trong hệ thống SMAP và cách chúng tương tác với nhau. Mỗi container là một deployable unit có thể chạy độc lập.

#align(center)[
  #image("../images/diagram/container-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Container Diagram của SMAP_])
  #image_counter.step()
]

Container Diagram thể hiện 10 application containers (7 core services + 3 supporting services) và 5 data stores (PostgreSQL, MongoDB, Redis, MinIO, RabbitMQ), cùng với các communication patterns chính:

- REST API cho synchronous operations giữa Web UI và backend services
- RabbitMQ cho asynchronous event-driven communication giữa các services
- Redis Pub/Sub cho real-time notifications đến WebSocket clients
- Polyglot persistence với PostgreSQL, MongoDB, Redis và MinIO phục vụ các use cases khác nhau

=== 5.2.5 Technology Stack và Justification

Hệ thống SMAP sử dụng polyglot technology stack để tối ưu hóa hiệu năng và phù hợp với đặc thù của từng service.

==== 5.2.5.1 Backend Services

#context (align(center)[_Bảng #table_counter.display(): Technology Stack cho Backend Services_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.20fr, 0.15fr, 0.25fr, 0.40fr),
    stroke: 0.5pt,
    align: (left, center, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Language*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Framework*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Justification*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go 1.25],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[High concurrency, low latency, memory efficient],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go 1.25],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin],
    table.cell(align: horizon, inset: (y: 0.8em))[Relational data, ACID transactions, high throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go 1.25],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin],
    table.cell(align: horizon, inset: (y: 0.8em))[Master-Worker pattern, high concurrency, efficient job dispatching],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Go 1.25],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gorilla WebSocket],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Real-time communication, low latency, efficient connection management],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python 3.12],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI],
    table.cell(align: horizon, inset: (y: 0.8em))[AI/NLP libraries, scientific computing ecosystem],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Speech2Text],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python 3.12],
    table.cell(align: center + horizon, inset: (y: 0.8em))[FastAPI],
    table.cell(align: horizon, inset: (y: 0.8em))[Whisper model integration, audio processing libraries],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scrapper],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Python 3.12],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Playwright, yt-dlp],
    table.cell(align: horizon, inset: (y: 0.8em))[Browser automation, media extraction, platform-specific tools],
  )
]

==== 5.2.5.2 Frontend

#context (align(center)[_Bảng #table_counter.display(): Technology Stack cho Frontend_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.25fr, 0.50fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Justification*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Framework],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Next.js 15.2.3, React 19.0.0],
    table.cell(align: horizon, inset: (y: 0.8em))[SSR cho SEO và initial load performance, modern React features],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Language],
    table.cell(align: center + horizon, inset: (y: 0.8em))[TypeScript 5.8.2],
    table.cell(align: horizon, inset: (y: 0.8em))[Type safety, developer productivity, fast development với HMR],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Styling],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tailwind CSS],
    table.cell(align: horizon, inset: (y: 0.8em))[Utility-first CSS, rapid UI development, consistent design system],
  )
]

==== 5.2.5.3 Data Stores

#context (align(center)[_Bảng #table_counter.display(): Technology Stack cho Data Stores_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: true)
  #table(
    columns: (0.20fr, 0.20fr, 0.60fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Data Store*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Type*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Justification*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[PostgreSQL 15],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Relational DB],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[ACID transactions, complex queries, relational data],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MongoDB 6.x],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Document DB],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Schema-less cho raw social data, flexible schema evolution, high write throughput],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis 7.0+],
    table.cell(align: center + horizon, inset: (y: 0.8em))[In-Memory DB],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Distributed state management, Pub/Sub cho real-time updates, low latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIO],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Object Storage],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[S3-compatible, media files storage, cost-effective],
  )
]

==== 5.2.5.4 Infrastructure Components

#context (align(center)[_Bảng #table_counter.display(): Infrastructure Components_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.25fr, 0.55fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Category*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Purpose*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Message Broker],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ 3.x],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Event-driven communication, reliable message delivery, dead-letter queues],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Containerization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Docker, Docker Compose],
    table.cell(align: horizon, inset: (y: 0.8em))[Container images cho tất cả services, local development environment],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Orchestration],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kubernetes],
    table.cell(align: horizon, inset: (
      y: 0.8em,
    ))[Production orchestration trên môi trường on-premise, auto-scaling, self-healing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Metrics],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Prometheus, Grafana],
    table.cell(align: horizon, inset: (y: 0.8em))[Metrics collection và visualization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Logging],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ELK Stack],
    table.cell(align: horizon, inset: (y: 0.8em))[Centralized logging],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tracing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Jaeger],
    table.cell(align: horizon, inset: (y: 0.8em))[Distributed tracing],
  )
]

==== 5.2.5.5 Technology Selection Rationale

Việc lựa chọn polyglot stack được quyết định dựa trên ba yếu tố chính:

- Go cho API Services: High concurrency với goroutines, low memory footprint, fast compilation, throughput cao. Đáp ứng AC-3 Performance với API response time thấp.

- Python cho AI/ML Services: Rich ecosystem với thư viện AI/ML phong phú, PhoBERT model chỉ có Python implementation, scientific libraries là core dependencies, development velocity nhanh hơn so với implementing AI from scratch.

- Next.js cho Frontend: SSR performance cho initial load nhanh, SEO benefits, developer productivity cao với TypeScript type safety. Đáp ứng NFR về Dashboard loading time.

Trade-offs được chấp nhận: Tăng độ phức tạp vận hành được bù đắp bằng lợi ích về performance, resource efficiency và development velocity. ROI positive trong thời gian ngắn nhờ precision scaling và giảm downtime cost.

=== 5.2.6 Tổng Kết

Việc lựa chọn Microservices Architecture cho hệ thống SMAP được chứng minh là quyết định tối ưu dựa trên:

a. Quantitative Decision Matrix: Điểm cao với trọng số từ 3 Architectural Drivers chính \
b. Evidence-based Analysis: 7 core services và 3 supporting services thực tế với metrics cụ thể từ môi trường triển khai \
c. Industry Alignment: Consistent với các hệ thống tương tự \
d. Technical Necessity: Polyglot requirement khiến các lựa chọn khác không khả thi \

Kiến trúc này thiết lập nền tảng vững chắc cho việc implement chi tiết ở Chapter 6, đồng thời đảm bảo đáp ứng toàn bộ NFRs đã xác định ở Chapter 4.
