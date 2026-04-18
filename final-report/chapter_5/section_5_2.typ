#import "../counters.typ": image_counter, table_counter

== 5.2 Kiến trúc tổng thể

=== 5.2.1 Lựa chọn phong cách kiến trúc

==== 5.2.1.1 Bối cảnh quyết định

Việc lựa chọn kiến trúc cho SMAP không chỉ là quyết định công nghệ, mà là phản hồi trực tiếp đối với các architectural drivers đã xác định ở mục 5.1. Hệ thống cần đồng thời xử lý API/business context, điều phối runtime ingest, analytics pipeline, semantic retrieval, realtime delivery và nhiều loại storage khác nhau. Điều này làm cho việc tổ chức kiến trúc trở thành một bài toán về workload specialization, service ownership và transport suitability, chứ không chỉ là việc chia code thành nhiều thư mục.

Ba động lực chính chi phối quyết định kiến trúc của SMAP là:

- nhu cầu tách biệt rõ giữa business context và execution plane;
- nhu cầu mở rộng độc lập cho các lane có tải khác nhau;
- nhu cầu cô lập lỗi giữa các thành phần như authentication, ingest runtime, analytics và delivery.

==== 5.2.1.2 Đánh giá các lựa chọn

Trong phạm vi của đồ án, ba phong cách kiến trúc thường được xem xét gồm Monolithic Architecture, Modular Monolith và Microservices Architecture. Mỗi phong cách có ưu điểm riêng, nhưng mức độ phù hợp với current SMAP là khác nhau.

#context (align(center)[_Bảng #table_counter.display(): So sánh các lựa chọn kiến trúc ở mức định tính_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.28fr, 0.24fr, 0.24fr, 0.24fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*Monolithic*],
    table.cell(align: center + horizon)[*Modular Monolith*],
    table.cell(align: center + horizon)[*Microservices*],

    [Tách biệt bounded context], [Thấp], [Trung bình], [Cao],
    [Mở rộng độc lập theo workload], [Thấp], [Thấp đến trung bình], [Cao],
    [Phù hợp đa runtime], [Thấp], [Thấp], [Cao],
    [Cô lập lỗi giữa các lane], [Thấp], [Trung bình], [Cao],
    [Độ đơn giản triển khai ban đầu], [Cao], [Trung bình], [Thấp],
    [Phù hợp với current SMAP], [Thấp], [Trung bình], [Cao],
  )
]

Monolithic Architecture có lợi thế về độ đơn giản trong giai đoạn đầu, nhưng không phù hợp khi hệ thống cần tách rõ nhiều lane xử lý có tính chất khác nhau. Modular Monolith cải thiện tổ chức code tốt hơn, nhưng vẫn không giải quyết triệt để bài toán polyglot runtime, fault isolation và scale theo từng vai trò runtime. Trong khi đó, Microservices Architecture phù hợp hơn với current SMAP vì cho phép phân tách business context, execution plane, analytics pipeline, retrieval và notification thành các thành phần có thể phát triển, triển khai và mở rộng tương đối độc lập.

==== 5.2.1.3 Kết luận lựa chọn kiến trúc

Từ các so sánh trên, Microservices Architecture là lựa chọn phù hợp nhất cho SMAP ở current-state. Lý do chính không nằm ở việc theo đuổi một mô hình kiến trúc phổ biến, mà ở chỗ cách tổ chức này phản hồi tốt nhất với các ràng buộc thật của hệ thống: nhiều bounded context, nhiều loại workload, nhiều công nghệ runtime và nhiều transport được chuyên biệt hóa theo từng lane xử lý.

=== 5.2.2 Kiến trúc tổng thể current-state

Hình dưới đây trình bày kiến trúc tổng thể của SMAP ở current-state.

#align(center)[#box(stroke: 1pt + gray, inset: 12pt, width: 100%)[
  Placeholder figure: `c4-container-current.svg`\
  Asset current-state sẽ được copy vào `final-report/images/` ở bước hoàn thiện.
]]
#context (align(center)[_Hình #image_counter.display(): Kiến trúc tổng thể current-state của SMAP_])
#image_counter.step()

Kiến trúc này cho thấy SMAP được chia thành sáu nhóm thành phần chính. `identity-srv` tạo security boundary cho toàn hệ thống. `project-srv` giữ business context và lifecycle của campaign/project. `ingest-srv` cùng `scapper-srv` hình thành execution plane để điều phối crawl và chuẩn hóa dữ liệu. `analysis-srv` xử lý pipeline AI/NLP. `knowledge-srv` xây dựng lớp semantic search và khai thác thông tin theo ngữ cảnh. `notification-srv` chịu trách nhiệm delivery theo thời gian thực. Ngoài ra, frontend hiện tại còn được tổ chức như một lớp giao diện đa vai trò, hỗ trợ web delivery, BI integration và desktop packaging khi cần.

Một điểm quan trọng của kiến trúc này là không áp dụng một transport duy nhất cho toàn bộ hệ thống. Control plane giữa `project-srv` và `ingest-srv` nghiêng về internal HTTP. Crawl runtime dùng RabbitMQ. Analytics data plane dùng Kafka. Notification ingress dùng Redis Pub/Sub. Cách tổ chức này giúp mỗi lane xử lý sử dụng cơ chế giao tiếp phù hợp hơn với tính chất workload thay vì ép toàn bộ hệ thống chạy theo cùng một khuôn mẫu.

==== Architecture Decision Matrix

#context (align(center)[_Bảng #table_counter.display(): Các quyết định kiến trúc chính_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.35fr, 0.22fr, 0.43fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Quyết định*],
    table.cell(align: center + horizon)[*Lựa chọn*],
    table.cell(align: center + horizon)[*Lý do chính*],

    [Tách identity khỏi business services],
    [`identity-srv` riêng],
    [Cô lập xác thực, JWT, session và OAuth2 khỏi các domain nghiệp vụ khác.],
    [Tách project context khỏi ingest runtime],
    [`project-srv` và `ingest-srv`],
    [Giữ ownership business context tách khỏi execution plane.],
    [Dùng internal HTTP cho lifecycle control],
    [Control plane đồng bộ],
    [Readiness check và activate/pause/resume cần phản hồi đồng bộ trước khi đổi business status.],
    [Dùng RabbitMQ cho crawl runtime],
    [Task queue theo platform],
    [Phù hợp cho work queue, dispatch task và completion correlation.],
    [Dùng Kafka cho analytics data plane],
    [Event streaming],
    [Phù hợp cho batch consumer, downstream fanout và replay.],
    [Dùng Redis cho notification ingress], [Pub/Sub channels], [Phù hợp cho fanout thời gian thực và routing nhẹ.],
    [Dùng Qdrant cho knowledge layer], [Vector store], [Phục vụ semantic search, chat và retrieval theo ngữ cảnh.],
  )
]

=== 5.2.3 Service Ownership và ranh giới trách nhiệm

Một thiết kế tốt không chỉ chỉ ra có bao nhiêu service, mà còn phải xác định rõ service nào sở hữu capability nào và service nào không nên gánh trách nhiệm nào. Điều này đặc biệt quan trọng trong các hệ thống đa service để tránh chồng chéo ownership và nguy cơ biến hệ thống thành distributed monolith.

#context (align(center)[_Bảng #table_counter.display(): Service Ownership and Boundary Matrix_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.32fr, 0.25fr, 0.23fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon)[*Ownership chính*],
    table.cell(align: center + horizon)[*Không nên sở hữu*],
    table.cell(align: center + horizon)[*Ý nghĩa ranh giới*],

    [`identity-srv`],
    [OAuth2, JWT, session, token validation],
    [business metadata, crawl runtime, analytics facts],
    [security boundary tách khỏi domain logic],
    [`project-srv`],
    [campaign, project, crisis config, business metadata],
    [raw batch, queue runtime state, vector index],
    [owner của business context],
    [`ingest-srv`],
    [datasource, target, dry run, scheduled job, external task, raw batch, UAP publishing],
    [OAuth/session, rich NLP logic, semantic retrieval],
    [owner của execution plane và data ingress],
    [`analysis-srv`],
    [NLP enrichment, reporting bundle, crisis signals, analytics topics],
    [project CRUD, datasource CRUD, websocket delivery],
    [owner của analytics pipeline],
    [`knowledge-srv`],
    [semantic search, chat, indexed documents, conversations],
    [crawl orchestration, project lifecycle control],
    [owner của retrieval và knowledge consumption],
    [`notification-srv`],
    [WebSocket connection management, alert formatting và dispatch],
    [project decision logic, analytics computation],
    [owner của delivery channels],
    [`scrapper-srv`],
    [platform-specific crawling, raw artifact storage và completion publish],
    [project business logic, analytics, semantic retrieval],
    [worker runtime tách khỏi business services],
  )
]

=== 5.2.4 Technology Stack và các lựa chọn hạ tầng

==== 5.2.4.1 Backend và frontend

#context (align(center)[_Bảng #table_counter.display(): Technology stack cho các lớp chính_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.4fr, 0.55fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Lớp / Service*],
    table.cell(align: center + horizon)[*Công nghệ chính*],
    table.cell(align: center + horizon)[*Lý do chính*],

    [Go services],
    [Go + Gin],
    [Phù hợp cho API services, internal HTTP control plane và các lane cần concurrency tốt với memory footprint thấp.],
    [Analytics runtime], [Python + consumer runtime], [Phù hợp với AI/NLP pipeline và hệ sinh thái xử lý dữ liệu.],
    [Scrapper runtime],
    [Python + FastAPI/worker],
    [Phù hợp cho browser automation, crawling runtime và worker lifecycle.],
    [Frontend],
    [Next.js + React + TypeScript + Tailwind CSS],
    [Phù hợp cho giao diện người dùng hiện đại, hỗ trợ i18n, BI integration và mở rộng đa hình thức triển khai.],
    [Desktop packaging], [Electron], [Cho phép tái sử dụng frontend stack hiện có cho desktop runtime khi cần.],
  )
]

==== 5.2.4.2 Data storage

#context (align(center)[_Bảng #table_counter.display(): Lựa chọn lớp lưu trữ dữ liệu_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.25fr, 0.55fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Storage*],
    table.cell(align: center + horizon)[*Vai trò chính*],
    table.cell(align: center + horizon)[*Lý do lựa chọn*],

    [PostgreSQL],
    [Metadata và dữ liệu nghiệp vụ],
    [Phù hợp cho dữ liệu quan hệ, trạng thái nghiệp vụ và transaction-oriented workloads.],
    [Redis],
    [Cache, session, pub/sub],
    [Phù hợp cho độ trễ thấp, fanout realtime, token blacklist và coordination nhẹ.],
    [Qdrant], [Vector search], [Phù hợp cho semantic retrieval, search/chat và khai thác thông tin theo ngữ cảnh.],
    [MinIO], [Object storage], [Phù hợp cho raw artifact, report output và các object trung gian trong pipeline.],
  )
]

==== 5.2.4.3 Transport và orchestration

#context (align(center)[_Bảng #table_counter.display(): Lựa chọn transport và orchestration_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.23fr, 0.55fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thành phần*],
    table.cell(align: center + horizon)[*Vai trò*],
    table.cell(align: center + horizon)[*Lý do lựa chọn*],

    [Internal HTTP], [Control plane], [Phù hợp cho readiness check và lifecycle control cần phản hồi đồng bộ.],
    [RabbitMQ], [Task queue], [Phù hợp cho crawl runtime, dispatch task và completion lane.],
    [Kafka], [Event streaming], [Phù hợp cho analytics data plane, fanout downstream và replay.],
    [Redis Pub/Sub], [Realtime ingress], [Phù hợp cho notification fanout và lightweight channel routing.],
    [Docker / Docker Compose],
    [Containerization và local orchestration],
    [Hỗ trợ đóng gói và dựng local/test stacks nhiều service.],
    [Kubernetes], [Workload orchestration], [Phù hợp cho deployment, scale-by-role và health-managed workloads.],
  )
]

=== 5.2.5 Tổng kết mục

Kiến trúc tổng thể của SMAP nên được hiểu như một hệ thống đa service được tổ chức theo capability và workload specialization, thay vì như một tập hợp service được tách ra thuần túy vì lý do kỹ thuật. Giá trị của thiết kế hiện tại nằm ở chỗ nó tách rõ business context khỏi execution plane, tách analytics khỏi request path, và tách knowledge/delivery thành các lớp tiêu thụ riêng. Cùng với đó, việc chuyên biệt hóa transport và storage giúp mỗi lane xử lý được tối ưu theo đặc điểm thực tế của nó.

Những lựa chọn này tạo nền cho các mục tiếp theo của Chương 5, nơi từng service, từng lớp dữ liệu và từng mẫu giao tiếp sẽ được phân tích sâu hơn ở mức thiết kế chi tiết.
