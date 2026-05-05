// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.6 Mẫu giao tiếp và tích hợp

Mục 5.3 đã trình bày chi tiết cấu trúc nội bộ của từng service, còn mục 5.5 đã mô tả các tương tác giữa services theo thời gian qua Sequence Diagrams. Mục này tập trung vào các mẫu giao tiếp và cơ chế tích hợp được sử dụng trong hệ thống SMAP, giải thích tại sao chọn từng pattern và cách chúng hoạt động.

=== 5.6.1 Mẫu giao tiếp

Hệ thống SMAP không sử dụng một cơ chế giao tiếp duy nhất cho toàn bộ kiến trúc. Thay vào đó, các thành phần được kết nối bằng nhiều communication patterns khác nhau tùy theo tính chất của từng lane xử lý: tương tác người dùng cần phản hồi nhanh, control plane nội bộ cần đồng bộ, execution plane cần dispatch bất đồng bộ, analytics downstream cần fanout theo stream, còn notification cần khả năng phát thông báo kịp thời tới các phiên theo dõi phù hợp.

==== 5.6.1.1 Tổng quan các mẫu giao tiếp

#context (align(center)[_Bảng #table_counter.display(): Tổng quan các mẫu giao tiếp trong hệ thống SMAP_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.19fr, 0.24fr, 0.23fr, 0.16fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Pattern*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại tương tác*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Công nghệ chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Khi sử dụng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ví dụ trong hệ thống*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Request-response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện hoặc service gọi trực tiếp và chờ kết quả],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP, route handlers, internal HTTP],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CRUD, readiness check, search hoặc chat],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện gọi project API; project-srv gọi ingest-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Async task dispatch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Execution plane publish task và nhận completion bất đồng bộ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Crawl runtime, dry run runtime, completion correlation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv → scapper-srv → ingest completion queues],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Event streaming],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Downstream fanout và stream processing giữa analytics với knowledge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Analytics intake, insights published, batch completed, downstream knowledge materialization],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv → knowledge-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Realtime notification delivery],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Notification ingress và route message tới phiên theo dõi phù hợp],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Redis Pub/Sub + WebSocket hub],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo trạng thái, campaign event, crisis alert],
    table.cell(align: center + horizon, inset: (y: 0.8em))[backend publisher → notification-srv],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Artifact reference],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Payload lớn được materialize ra object storage, chỉ trao đổi metadata hoặc reference],
    table.cell(align: center + horizon, inset: (y: 0.8em))[MinIO + metadata or event reference],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Raw crawl artifacts, knowledge-side report artifacts, batch file inputs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[raw batch lineage, knowledge report file_url],
  )
]

#block(inset: (left: 1em, top: 0.5em, bottom: 0.5em))[
  _Lưu ý: Cột "Công nghệ chính" phản ánh transport hoặc integration mechanism giữ vai trò trung tâm trong kiến trúc của SMAP. Một pattern có thể đi kèm thêm cache, object storage hoặc route handler hỗ trợ, nhưng bảng chỉ liệt kê lớp giao tiếp chính._
]

==== 5.6.1.2 Synchronous Request-Response Pattern

Synchronous request-response được sử dụng ở những nơi hệ thống cần trả kết quả ngay sau khi kiểm tra quyền truy cập, tính hợp lệ của input hoặc trạng thái hiện tại của đối tượng nghiệp vụ. Pattern này xuất hiện ở cả hai cấp: giữa giao diện với backend và giữa các service trong control plane nội bộ.

Các interaction tiêu biểu:

#context (align(center)[_Bảng #table_counter.display(): Các interaction đồng bộ tiêu biểu_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.26fr, 0.18fr, 0.18fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Pattern con*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Bên tham gia chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Transport*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Vai trò*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ví dụ*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[User-facing API call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện → identity, project, ingest, knowledge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP qua same-origin proxy hoặc route handlers],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CRUD, truy vấn, search và chat],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tạo project, tạo datasource, gửi câu hỏi chat],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal control call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project-srv ↔ ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal HTTP],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Readiness check và lifecycle control],
    table.cell(align: center + horizon, inset: (y: 0.8em))[activation-readiness, activate, pause, resume],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Knowledge retrieval request],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giao diện → knowledge-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP API đã xác thực],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tra cứu và hỏi đáp theo ngữ cảnh],
    table.cell(align: center + horizon, inset: (y: 0.8em))[search, chat, conversation detail],
  )
]

Ở phía người dùng, giao diện chủ yếu gọi backend thông qua lớp proxy hoặc route handlers để giữ same-origin behavior cho cookie và giảm CORS complexity. Ở phía nội bộ, internal HTTP được dùng khi business control plane cần phản hồi đồng bộ trước khi thay đổi trạng thái nghiệp vụ, chẳng hạn readiness check và activate hoặc resume ở project-srv.

==== 5.6.1.3 Asynchronous Messaging Pattern

Asynchronous messaging được sử dụng ở các lane mà xử lý không nên nằm trên synchronous request path. Trong kiến trúc của SMAP, hai nhóm bất đồng bộ quan trọng nhất không dùng cùng một transport: RabbitMQ phục vụ execution plane của crawl runtime, còn Kafka phục vụ analytics data plane và downstream fanout sang knowledge lane.

Ở execution plane, RabbitMQ phù hợp với task dispatch và completion correlation:

- ingest-srv publish crawl hoặc dry run task theo queue platform-specific;
- scapper-srv consume task, thực thi runtime và publish completion envelope trở lại;
- ingest-srv correlate completion bằng task_id, object metadata và raw batch lineage.

Ở analytics downstream, Kafka phù hợp với stream fanout và retrieval preparation:

- analysis-srv consume dữ liệu đầu vào đã chuẩn hóa từ analytics data plane;
- analysis-srv publish các outputs downstream như batch completed, insight hoặc digest;
- knowledge-srv consume các topic này để tiếp tục indexing, retrieval và materialization liên quan.

Điểm cốt lõi của pattern bất đồng bộ ở đây là tách control plane khỏi processing plane. Người dùng không chờ trực tiếp quá trình crawl, analytics hay indexing kết thúc trong một HTTP request duy nhất; thay vào đó, trạng thái và kết quả được materialize dần qua các lane runtime tương ứng.

==== 5.6.1.4 Realtime Notification Delivery Pattern

Realtime notification delivery được sử dụng khi hệ thống cần phát thông báo hoặc cảnh báo kịp thời cho user trong phạm vi được phép theo dõi. Trong SMAP, pattern này được tổ chức thành hai lớp: Redis Pub/Sub làm notification ingress và Notification Service làm delivery boundary.

Luồng delivery chính:

- backend publisher phát message vào Redis channel theo user scope, project scope, campaign scope hoặc system scope;
- notification-srv subscribe các channel phù hợp, parse message type và route theo recipient hoặc broadcast scope;
- nếu có active compatible connection, message được đẩy vào WebSocket hub để giao diện hoặc client tương thích nhận và hiển thị.

Vì connection là stateful, Redis Pub/Sub giúp nhiều notification instances nhìn thấy cùng một notification ingress stream. Tuy nhiên, pattern này chỉ mô tả delivery capability ở phía hệ thống; nó không mặc định khẳng định mọi loại giao diện đều tiêu thụ trực tiếp cùng một kênh realtime ở mọi tình huống.

Ở lớp giao diện, notification presentation vẫn có lớp state riêng. Vì vậy, pattern này phản ánh delivery semantics của notification boundary nhiều hơn là một ràng buộc bắt buộc cho mọi client.

==== 5.6.1.5 Artifact Reference Pattern

Artifact reference pattern được dùng khi payload hoặc output không phù hợp để truyền trực tiếp qua message body hoặc lưu hoàn toàn trong relational row. Thay vì truyền nguyên dữ liệu lớn qua queue, hệ thống materialize artifact ra object storage và chỉ trao đổi metadata hoặc reference cần thiết giữa các lane xử lý.

Trong SMAP, pattern này xuất hiện ở hai nơi chính:

- scapper runtime materialize raw output vào local filesystem ở development mode hoặc MinIO ở production mode; ingest-srv chỉ nhận storage bucket, storage path, checksum, batch_id và completion metadata để tiếp tục xử lý;
- knowledge-side report generation, như một capability mở rộng của knowledge layer ngoài bộ use case cốt lõi ở Chương 4, lưu artifact báo cáo ở object storage, còn PostgreSQL chỉ giữ report metadata, status và file URL.

Lợi ích của cách làm này là giữ queue message và relational metadata ở kích thước hợp lý, đồng thời vẫn bảo toàn được lineage giữa task, artifact và kết quả downstream. Pattern này đồng bộ với cách mục 5.4 mô tả storage stack và artifact lineage, nên không cần giả định benchmark cứng hay contract dữ liệu nén khi chưa có cơ sở thực nghiệm hoặc mô tả thiết kế tương ứng.


=== 5.6.2 RabbitMQ cho execution plane

Trong kiến trúc của SMAP, RabbitMQ không đóng vai trò event bus trung tâm cho toàn bộ hệ thống. Phạm vi của nó hẹp hơn và rõ ràng hơn: làm lớp tích hợp bất đồng bộ giữa ingest-srv và scapper-srv cho hai nhu cầu chính là dispatch crawl task theo nền tảng và nhận completion envelope để correlate kết quả xử lý.

==== 5.6.2.1 Topology dispatch và completion

Topology RabbitMQ của SMAP được tổ chức theo từng lane nghiệp vụ cụ thể thay vì một exchange tổng quát cho mọi business event. Task dispatch đi qua direct exchange riêng cho từng nền tảng, còn completion được publish trở lại các durable queue để ingest-srv consume theo lane execution hoặc dry run.

#context (align(center)[_Bảng #table_counter.display(): Topology RabbitMQ trong execution plane_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.26fr, 0.13fr, 0.16fr, 0.17fr, 0.28fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tên*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Publisher chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Consumer chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Vai trò*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[
      ingest\_tiktok\_#linebreak()
      tasks_exc
    ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Direct exchange],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv qua tiktok_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route task TikTok vào queue xử lý tương ứng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[
      ingest\_facebook\_#linebreak()
      tasks_exc
    ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Direct exchange],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv qua facebook_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route task Facebook vào queue xử lý tương ứng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[
      ingest\_youtube\_#linebreak()
      tasks_exc
    ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Direct exchange],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv qua youtube_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Route task YouTube vào queue xử lý tương ứng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[tiktok_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Durable queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hàng đợi task TikTok dùng chung cho execution và dry run],

    table.cell(align: center + horizon, inset: (y: 0.8em))[facebook_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Durable queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hàng đợi task Facebook dùng chung cho execution và dry run],

    table.cell(align: center + horizon, inset: (y: 0.8em))[youtube_tasks],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Durable queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Hàng đợi task YouTube dùng chung cho execution và dry run],

    table.cell(align: center + horizon, inset: (y: 0.8em))[
      ingest\_task\_#linebreak()
      completions
    ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Durable queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv execution consumer],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Nhận completion cho execution lane và correlate theo task_id],

    table.cell(align: center + horizon, inset: (y: 0.8em))[
      ingest\_dryrun\_#linebreak()
      completions
    ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Durable queue],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv dryrun consumer],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Nhận completion cho dry run lane để cập nhật readiness và kết quả kiểm thử],
  )
]

Một số điểm quan trọng của topology này:

- Mỗi nền tảng có một direct exchange riêng, và routing key trùng với tên queue đích tương ứng.
- Execution lane và dry run lane dùng chung các task queue theo nền tảng; việc tách hai lane xảy ra ở completion path dựa trên metadata runtime_kind.
- Completion envelope được scapper-srv publish trực tiếp vào queue đích bằng queue name, thay vì đi qua một exchange tổng quát cho mọi completion event.
- Cả queue lẫn message đều được cấu hình theo hướng durable và persistent để hỗ trợ xử lý bất đồng bộ ổn định hơn qua các lần restart thông thường.

==== 5.6.2.2 Delivery semantics và xử lý lỗi

Trong hiện thực của SMAP, delivery semantics ở RabbitMQ được giữ theo hướng đơn giản nhưng rõ ràng ở phía consumer thay vì dựa vào một broker-side retry fabric phức tạp. ingest-srv consume completion queues với manual acknowledgment và phân biệt rõ giữa payload không hợp lệ về mặt nghiệp vụ với lỗi xử lý tạm thời.

#context (align(center)[_Bảng #table_counter.display(): Hành vi xử lý completion message ở ingest-srv_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.30fr, 0.22fr, 0.48fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tình huống*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hành vi consumer*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ý nghĩa*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Completion hợp lệ và xử lý thành công],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Ack],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Kết thúc vòng đời message sau khi ingest-srv đã correlate và cập nhật trạng thái tương ứng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Payload không parse được hoặc JSON không hợp lệ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Ack và discard],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Tránh để poison message bị redelivery lặp lại khi bản thân payload đã hỏng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[task_id không tồn tại hoặc completion input không hợp lệ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Ack và discard],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Không retry các message sai ngữ nghĩa nghiệp vụ vì khả năng thành công lại gần như không tăng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Lỗi xử lý tạm thời ở use case hoặc hạ tầng phụ trợ],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Nack với requeue],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Cho phép RabbitMQ giao lại message để completion được thử xử lý lại ở lượt sau],
  )
]

Thiết kế này cho thấy fault handling ở lane này chủ yếu nằm ở application consumer logic: message hợp lệ sẽ được correlate theo task_id cùng storage metadata, message sai ngữ nghĩa sẽ bị loại bỏ có chủ đích, còn lỗi tạm thời sẽ được trả lại queue để redelivery. Vì vậy, mục này không giả định sẵn một DLX, DLQ riêng hay exponential backoff cố định nếu thiết kế và hiện thực của SMAP chưa thể hiện rõ các cơ chế đó.

=== 5.6.3 Giao tiếp thời gian thực

Trong SMAP, giao tiếp thời gian thực được tổ chức quanh notification-srv như một delivery boundary chuyên biệt. Backend publishers không gửi trực tiếp message tới từng phiên người dùng; thay vào đó, chúng publish notification vào Redis Pub/Sub, còn notification-srv subscribe ingress stream này, chuẩn hóa payload và đẩy kết quả ra WebSocket cho các kết nối đang hoạt động.

==== 5.6.3.1 Redis ingress và routing theo scope

Vì WebSocket connection là stateful và gắn với từng instance cụ thể, notification-srv cần một ingress layer dùng chung để mọi instance đều quan sát cùng một notification stream. Redis Pub/Sub đáp ứng vai trò này bằng pattern subscription trên các channel scope hóa theo user, project, campaign hoặc system.

#context (align(center)[_Bảng #table_counter.display(): Các channel pattern của notification ingress_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.28fr, 0.18fr, 0.35fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Channel pattern*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Scope*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại message tiêu biểu*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ý nghĩa delivery*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[project:\*:user:\*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project + user],
    table.cell(align: center + horizon, inset: (y: 0.8em))[DATA_ONBOARDING, ANALYTICS_PIPELINE],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thông báo tiến độ onboarding hoặc analytics gắn với một project nhưng nhắm đến user cụ thể],

    table.cell(align: center + horizon, inset: (y: 0.8em))[campaign:\*:user:\*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Campaign + user],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CAMPAIGN_EVENT],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thông báo lifecycle hoặc artifact event của campaign cho user liên quan],

    table.cell(align: center + horizon, inset: (y: 0.8em))[alert:\*:user:\*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Alert + user],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CRISIS_ALERT],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Cảnh báo khủng hoảng hoặc alert chuyên biệt gửi đến user mục tiêu],

    table.cell(align: center + horizon, inset: (y: 0.8em))[system:\*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[System-wide],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SYSTEM],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thông báo broadcast không ràng buộc vào một user cụ thể],
  )
]

Luồng xử lý ở notification-srv gồm các bước sau:

- mọi instance của notification-srv pattern-subscribe các channel trên;
- khi nhận message, service parse channel để xác định scope, entity_id, subtype và user_id đích nếu có;
- payload được nhận diện loại message dựa trên cấu trúc dữ liệu, sau đó transform thành WebSocket envelope thống nhất;
- hub trong bộ nhớ gửi message đến tất cả active connections của user tương ứng, hoặc broadcast nếu channel thuộc system scope.

Điểm quan trọng ở đây là routing lõi của notification lane mang tính user-centric. Dù channel name mang ngữ nghĩa project hoặc campaign, hub chủ yếu index connection theo user_id. Vì vậy, mục này mô tả delivery semantics theo user-targeted notification và system broadcast, không giả định cơ chế subscription động theo từng project ở mọi client.

==== 5.6.3.2 Thiết lập kết nối và vòng đời phiên

Trong hiện thực của SMAP, WebSocket được xác thực ngay tại HTTP upgrade boundary thay vì dùng một auth frame sau khi kết nối đã mở. Client mở `GET /ws` và cung cấp JWT theo một trong hai cách:

- cookie `smap_auth_token`, là cách dùng chính khi giao diện chạy cùng hệ xác thực;
- query parameter `token`, chủ yếu phù hợp cho debug hoặc các client tích hợp đơn giản.

Notification Service verify token trước khi nâng cấp kết nối và trích xuất user_id từ JWT payload. Sau khi upgrade thành công, connection được đăng ký vào hub trong bộ nhớ theo user_id và bắt đầu hai vòng lặp nội bộ:

- `readPump` chủ yếu giữ connection sống, nhận close hoặc control frames và hiện chưa định nghĩa business message riêng từ client lên server;
- `writePump` chịu trách nhiệm đẩy notification ra ngoài và phát WebSocket ping định kỳ;
- `pong` được dùng để gia hạn read deadline, qua đó phát hiện stale connection và cleanup khi peer không còn phản hồi.

Thiết kế này cho thấy realtime lane thiên về server-to-client push. Các message nghiệp vụ được đẩy từ backend qua Redis ingress rồi ra WebSocket, còn phía client không cần thực hiện thêm bước subscribe hay gửi auth envelope sau khi connection đã được chấp nhận.

==== 5.6.3.3 Notification envelope và message families

Tất cả WebSocket frames gửi tới client đều dùng cùng một envelope gồm ba thành phần: `type`, `timestamp` và `payload`. Cách đóng gói thống nhất này giúp frontend hoặc client tương thích xử lý nhiều nhóm thông báo khác nhau mà không cần thay đổi transport contract.

#context (align(center)[_Bảng #table_counter.display(): Các loại WebSocket messages_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.4fr, 0.28fr, 0.60fr),
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hướng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[DATA_ONBOARDING],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thông báo trạng thái và kết quả onboarding dữ liệu theo source hoặc project context],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ANALYTICS_PIPELINE],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Cập nhật tiến độ pipeline analytics với phase, progress và các bộ đếm xử lý],

    table.cell(align: center + horizon, inset: (y: 0.8em))[CRISIS_ALERT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Cảnh báo khủng hoảng với severity, metric, threshold và các affected aspects],

    table.cell(align: center + horizon, inset: (y: 0.8em))[CAMPAIGN_EVENT],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thông báo các sự kiện liên quan đến campaign như hoàn tất xử lý hoặc artifact đã sẵn sàng],

    table.cell(align: center + horizon, inset: (y: 0.8em))[SYSTEM],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Server → Client],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Thông báo broadcast hoặc maintenance event ở phạm vi toàn hệ thống],
  )
]

Ngoài WebSocket delivery, một số message families như `CRISIS_ALERT`, `DATA_ONBOARDING` và `CAMPAIGN_EVENT` còn có thể được chuyển tiếp sang alert dispatch layer của notification-srv cho các kênh ngoài trình duyệt như Discord. Tuy vậy, realtime contract ở đây vẫn được giữ thống nhất dưới cùng một WebSocket envelope, giúp notification boundary tách rời khỏi logic hiển thị cụ thể ở từng client.

=== 5.6.4 Giám sát hệ thống

Trong thiết kế và hiện thực của SMAP đã có các khối observability cốt lõi, nhưng mức độ hoàn thiện chưa đồng đều giữa mọi service. Phần rõ ràng nhất hiện nay gồm logging có ngữ cảnh, health hoặc readiness probes ở các API services chính, trace_id propagation xuyên qua HTTP và RabbitMQ, cùng một số metric domain-specific ở analysis-srv. Vì vậy, mục này mô tả các cơ chế observability đang được tổ chức trong hệ thống thay vì giả định một monitoring surface hoàn toàn đồng nhất cho toàn bộ hệ thống.

==== 5.6.4.1 Logging và ngữ cảnh chẩn đoán

Logging trong SMAP được tổ chức theo shared abstractions thay vì để từng service tự định nghĩa hoàn toàn độc lập. Ở Go services, lớp logger dùng Zap và có thể xuất console hoặc JSON tùy cấu hình. Ở Python runtime như scapper-srv, Loguru được dùng với patcher để chèn trace_id vào record và cũng tách riêng giữa chế độ production với development.

#context (align(center)[_Bảng #table_counter.display(): Cơ chế logging hiện có theo nhóm runtime_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.18fr, 0.25fr, 0.35fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nhóm service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Library*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Hành vi output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đặc điểm chẩn đoán*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Go API services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Zap],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Console hoặc JSON tùy cấu hình],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Có thể enrich theo context với trace_id, user_id; middleware HTTP phân mức log theo status code và bỏ qua health endpoints],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Python runtime services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Loguru],
    table.cell(align: center + horizon, inset: (y: 0.8em))[JSON trong production, dễ đọc hơn trong chế độ chẩn đoán],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[trace_id được gắn vào record; scapper-srv còn intercept logging chuẩn của framework để gom về cùng logger],
  )
]

Một số quy ước logging hiện có đáng chú ý:

- HTTP middleware ở Go services log `2xx/3xx` ở mức `INFO`, `4xx` ở mức `WARN`, và `5xx` ở mức `ERROR`.
- Các probe như `/health`, `/ready`, `/live` được bỏ khỏi access logging để tránh làm nhiễu operational logs.
- Trong production mode, logger của scapper-srv chuẩn hóa record thành các trường như timestamp, trace_id, level, caller, message và service.

Thiết kế này cho phép truy vết theo yêu cầu xử lý và theo ngữ cảnh người dùng tốt hơn so với logging thuần văn bản, nhưng điều đó không có nghĩa mọi service đều luôn chạy ở cùng một encoding hoặc cùng một backend log collector.

==== 5.6.4.2 Health và readiness probes

Phần lớn Go API services trong SMAP đều expose bộ probe `health`, `ready` và `live`, nhưng nội dung kiểm tra cụ thể khác nhau theo dependency footprint của từng service. Ngược lại, Python runtime như scapper-srv hiện chỉ expose một endpoint `health` đơn giản hơn.

#context (align(center)[_Bảng #table_counter.display(): Probe surface hiện có theo service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.18fr, 0.28fr, 0.36fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Endpoints*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Readiness hoặc health chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ghi chú*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[identity-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health, /ready, /live],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/ready ping PostgreSQL],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Phù hợp cho API auth và session lane],

    table.cell(align: center + horizon, inset: (y: 0.8em))[project-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health, /ready, /live],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/ready ping PostgreSQL],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Probe đơn giản, tập trung vào dependency quan trọng nhất của control plane],

    table.cell(align: center + horizon, inset: (y: 0.8em))[knowledge-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health, /ready, /live],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/ready ping PostgreSQL và Redis],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Phản ánh retrieval lane phụ thuộc cả relational store lẫn cache],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health, /ready, /live],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[/ready yêu cầu PostgreSQL và Redis; đồng thời report trạng thái MinIO, Kafka, RabbitMQ],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Probe giàu thông tin nhất trong nhóm Go services của hệ thống],

    table.cell(align: center + horizon, inset: (y: 0.8em))[notification-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health, /ready, /live],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health và /ready ping Redis; /health trả thêm hub stats],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Cho thấy trạng thái delivery boundary và số connection đang hoạt động],

    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health],
    table.cell(align: center + horizon, inset: (y: 0.8em))[/health trả worker_active cùng một số config hints],
    table.cell(align: center + horizon, inset: (
      y: 0.8em,
    ))[Chưa có bộ ready hoặc live tách riêng như các Go API services],
  )
]

Các probe này đủ để phục vụ triển khai có orchestrator hoặc gateway health monitoring, đồng thời phản ánh mức độ phụ thuộc và độ sâu kiểm tra khác nhau giữa các service hơn là một contract hạ tầng hoàn toàn chuẩn hóa.

==== 5.6.4.3 Metric instrumentation hiện có

Surface `/metrics` trong hệ thống chưa được chuẩn hóa đồng nhất giữa mọi service. Tuy nhiên, analysis-srv đã có lớp metric instrumentation dùng Prometheus primitives với graceful fallback sang no-op khi thư viện metrics chưa được cài hoặc chưa được bật trong môi trường chạy.

#context (align(center)[_Bảng #table_counter.display(): Metric instrumentation tiêu biểu trong hệ thống_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.38fr, 0.15fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Nhãn*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis_pipeline_runs_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[status],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis_stage_duration_seconds],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Histogram],
    table.cell(align: center + horizon, inset: (y: 0.8em))[stage],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis_kafka_publish_total],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Counter],
    table.cell(align: center + horizon, inset: (y: 0.8em))[topic, status],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis_crisis_level],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gauge],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project_id],
  )
]

Ngoài các metric object này, notification-srv trả thêm `active_connections` và `total_unique_users` qua endpoint `health`, cho thấy một số operational stats đang được surfacing qua probe response thay vì qua metric endpoint chuyên dụng. Điều này củng cố nhận định rằng lớp observability của hệ thống vẫn đang phát triển theo từng lane cụ thể, chưa phải một platform metrics đồng nhất hoàn toàn.

==== 5.6.4.4 Trace ID propagation

SMAP hiện implement mức tracing cơ bản dựa trên `X-Trace-Id` thay vì một distributed tracing stack đầy đủ theo span. Dù vậy, cơ chế này đã đủ để nối một số hop quan trọng trong control plane và execution plane:

- Go API services dùng middleware tracing để nhận hoặc tạo `X-Trace-Id`, gắn nó vào request context và echo lại trên response header.
- Shared HTTP client trong Go có thể inject `X-Trace-Id` vào outbound requests, giúp duy trì correlation khi một service gọi sang service khác.
- Shared RabbitMQ layer chèn `X-Trace-Id` vào message headers khi publish nếu context mang trace_id.
- scapper-srv trích xuất `X-Trace-Id` từ inbound HTTP requests và từ RabbitMQ message headers, sau đó tiếp tục dùng cùng trace_id khi publish completion envelope trở lại queue.

Với mức propagation này, việc chẩn đoán liên service chủ yếu vẫn dựa trên log correlation hơn là trên trace visualization. Hệ thống chưa thể hiện đầy đủ span model hoặc backend như Jaeger hay OpenTelemetry collector trong hiện thực của SMAP.

=== 5.6.5 Tổng kết

- Hệ thống sử dụng nhiều communication patterns theo từng lane xử lý: request-response cho CRUD, control và retrieval; RabbitMQ cho execution task dispatch; Kafka cho analytics downstream; Redis Pub/Sub kết hợp WebSocket cho notification delivery; và artifact reference cho raw crawl artifacts cùng knowledge-side report artifacts, trong đó nhóm report thuộc capability mở rộng của knowledge layer ngoài bộ use case cốt lõi ở Chương 4.

- RabbitMQ trong kiến trúc của SMAP chỉ đóng vai trò execution-plane broker giữa ingest-srv và scapper-srv. Task được route theo exchange hoặc queue platform-specific, còn completion được correlate lại ở ingest lane bằng task_id và metadata kèm theo.

- Realtime notification được tổ chức theo user-targeted delivery boundary. notification-srv xác thực kết nối ngay tại HTTP upgrade, subscribe Redis ingress theo các channel pattern định trước, rồi đẩy các WebSocket envelope thống nhất ra các phiên đang hoạt động.

- Lớp observability hiện có đủ cho vận hành cơ bản: logging có ngữ cảnh, probe endpoints ở các API services chính, trace_id propagation qua HTTP và RabbitMQ, cùng metric instrumentation bước đầu ở analysis-srv. Tuy nhiên, monitoring surface vẫn chưa hoàn toàn đồng nhất giữa mọi runtime và vẫn còn dư địa để mở rộng trong các vòng hoàn thiện tiếp theo.
