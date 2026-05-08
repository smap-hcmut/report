// Chapter 6: Kiểm thử và đánh giá hệ thống
= CHƯƠNG 6: KIỂM THỬ VÀ ĐÁNH GIÁ HỆ THỐNG

Chương này trình bày cách kiểm thử và kết quả đánh giá hệ thống SMAP theo các yêu cầu chức năng, yêu cầu phi chức năng và thiết kế kiến trúc đã trình bày ở Chương 4 và Chương 5. Nội dung không chỉ liệt kê kết quả, mà mô tả rõ quy trình kiểm thử: kiểm thử bằng công cụ nào, kiểm thử lớp nào của hệ thống, thao tác được thực hiện ra sao, tiêu chí đạt là gì và kết quả quan sát được như thế nào.

== 6.1 Mục tiêu kiểm thử

Mục tiêu kiểm thử là xác nhận các capability chính của SMAP hoạt động đúng theo Chương 4 và khớp với ranh giới service ở Chương 5. Các nhóm kiểm thử được tổ chức theo bốn lớp:

+ Kiểm thử đơn vị để xác minh logic nội bộ của từng service.
+ Kiểm thử tích hợp để xác minh delivery, repository, queue, cache và các lớp giao tiếp.
+ Kiểm thử đầu cuối để xác minh luồng nghiệp vụ đi qua nhiều service.
+ Kiểm thử phi chức năng để đo performance, stability, availability, observability và một phần data integrity.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm yêu cầu*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nội dung kiểm chứng*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Lớp kiểm thử chính*],
    table.cell(inset: (y: 0.6em))[FR-01, FR-12],
    table.cell(inset: (y: 0.6em))[Xác thực, token validation, internal auth],
    table.cell(inset: (y: 0.6em))[Unit test identity-srv, kiểm thử đầu cuối endpoint validate],
    table.cell(inset: (y: 0.6em))[FR-02, FR-03, FR-04],
    table.cell(inset: (y: 0.6em))[Campaign/project, lifecycle, crisis config],
    table.cell(inset: (y: 0.6em))[Unit test project-srv, kiểm thử đầu cuối, runtime apply],
    table.cell(inset: (y: 0.6em))[FR-05, FR-06, FR-07, FR-08],
    table.cell(inset: (y: 0.6em))[Datasource, target, dry run, ingest execution],
    table.cell(inset: (y: 0.6em))[Unit test ingest-srv, task scenario crawler worker],
    table.cell(inset: (y: 0.6em))[FR-09],
    table.cell(inset: (y: 0.6em))[Analytics pipeline, normalization, enrichment, crisis, reporting],
    table.cell(inset: (y: 0.6em))[Unit test analysis-srv],
    table.cell(inset: (y: 0.6em))[FR-10],
    table.cell(inset: (y: 0.6em))[Search/chat và knowledge consumption],
    table.cell(inset: (y: 0.6em))[Kiểm thử đầu cuối, nghiệm thu chức năng knowledge-srv],
    table.cell(inset: (y: 0.6em))[FR-11],
    table.cell(inset: (y: 0.6em))[Notification delivery gần thời gian thực],
    table.cell(inset: (y: 0.6em))[Unit test notification-srv, kiểm chứng route WebSocket],
    table.cell(inset: (y: 0.6em))[NFR-01 đến NFR-07],
    table.cell(inset: (
      y: 0.6em,
    ))[Performance, security, availability, scalability, integrity, modularity, observability],
    table.cell(inset: (y: 0.6em))[Gói NFR, metric, queue snapshot, database evidence],
  )
]


== 6.2 Công cụ và phương pháp kiểm thử

=== 6.2.1 Công cụ kiểm thử đơn vị

Kiểm thử đơn vị dùng framework và thư viện phù hợp với từng stack. Các câu lệnh chỉ là cách kích hoạt bộ test; phần quan trọng trong báo cáo là framework, thư viện hỗ trợ và lớp logic được kiểm tra.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm kiểm thử*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Công cụ / thư viện*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Vai trò*],
    table.cell(inset: (y: 0.6em))[Go unit test],
    table.cell(inset: (y: 0.6em))[Go testing package, Testify, Go coverage],
    table.cell(inset: (y: 0.6em))[Kiểm tra package, use case, delivery, repository, model và helper],
    table.cell(inset: (y: 0.6em))[Go repository test],
    table.cell(inset: (y: 0.6em))[sqlmock, Testify],
    table.cell(inset: (y: 0.6em))[Mô phỏng truy vấn PostgreSQL để kiểm tra repository layer],
    table.cell(inset: (y: 0.6em))[Redis/WebSocket test],
    table.cell(inset: (y: 0.6em))[miniredis, Testify],
    table.cell(inset: (y: 0.6em))[Mô phỏng Redis và kiểm tra notification delivery],
    table.cell(inset: (y: 0.6em))[Python unit test],
    table.cell(inset: (y: 0.6em))[pytest, pytest-asyncio],
    table.cell(inset: (y: 0.6em))[Kiểm tra pipeline, mapper, enrichment, async service logic],
    table.cell(inset: (y: 0.6em))[Kafka-related test],
    table.cell(inset: (y: 0.6em))[testcontainers Kafka],
    table.cell(inset: (y: 0.6em))[Kiểm thử tình huống cần Kafka broker trong analytics pipeline],
    table.cell(inset: (y: 0.6em))[Coverage measurement],
    table.cell(inset: (y: 0.6em))[Go coverage, pytest coverage khi có cấu hình],
    table.cell(inset: (y: 0.6em))[Đo statement coverage hoặc số test item theo framework],
  )
]


Quy trình chung của kiểm thử đơn vị:

+ Xác định module cần kiểm thử theo ranh giới service: delivery, use case, repository, model hoặc helper.
+ Chuẩn bị dependency giả lập nếu cần, ví dụ sqlmock cho PostgreSQL hoặc miniredis cho Redis.
+ Chạy bộ test bằng framework của service.
+ Kiểm tra test pass/fail và coverage theo package hoặc số lượng test item.
+ Ghi nhận package nào đạt, package nào còn lỗi, và lỗi thuộc logic hay môi trường/cấu hình.

=== 6.2.2 Công cụ kiểm thử tích hợp và đầu cuối

Kiểm thử tích hợp và đầu cuối dùng công cụ ở mức runtime để đi qua nhiều service:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm kiểm thử*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Công cụ / thư viện*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Vai trò*],
    table.cell(inset: (y: 0.6em))[API flow],
    table.cell(inset: (y: 0.6em))[Bash, curl, jq],
    table.cell(inset: (y: 0.6em))[Gọi endpoint, đọc response envelope, kiểm tra mã phản hồi và dữ liệu trả về],
    table.cell(inset: (y: 0.6em))[Auth flow],
    table.cell(inset: (y: 0.6em))[JWT HS256 test token],
    table.cell(inset: (y: 0.6em))[Tạo token kiểm thử với role phù hợp],
    table.cell(inset: (y: 0.6em))[Database evidence],
    table.cell(inset: (y: 0.6em))[PostgreSQL client],
    table.cell(inset: (y: 0.6em))[Chuẩn bị user test, kiểm chứng dữ liệu và trạng thái runtime],
    table.cell(inset: (y: 0.6em))[Async polling],
    table.cell(inset: (y: 0.6em))[Bash polling, curl],
    table.cell(inset: (y: 0.6em))[Chờ dry run, crawler task, indexing, chat/report hoặc trạng thái liên quan],
    table.cell(inset: (y: 0.6em))[Queue/streaming],
    table.cell(inset: (y: 0.6em))[RabbitMQ, Kafka/Redpanda, Redis Pub/Sub],
    table.cell(inset: (y: 0.6em))[Kiểm chứng task queue, analytics data plane và notification ingress],
    table.cell(inset: (y: 0.6em))[Vector search],
    table.cell(inset: (y: 0.6em))[Qdrant],
    table.cell(inset: (y: 0.6em))[Kiểm chứng search/chat và trạng thái dữ liệu indexed],
  )
]


Quy trình kiểm thử đầu cuối:

+ Chuẩn bị user kiểm thử và token xác thực.
+ Kiểm tra health của các service chính.
+ Tạo campaign và project.
+ Tạo datasource và target.
+ Chạy hoặc kiểm tra dry run nếu tổ hợp nguồn dữ liệu yêu cầu.
+ Kiểm tra readiness và kích hoạt project khi đủ điều kiện.
+ Theo dõi lane bất đồng bộ: crawler worker nhận task, ingest nhận completion, analytics xử lý dữ liệu, knowledge layer sẵn sàng search/chat.
+ Gọi search, chat, report và các endpoint trạng thái.
+ Đối chiếu response, HTTP status, error code và dữ liệu trong database hoặc artifact runtime.

=== 6.2.3 Công cụ kiểm thử phi chức năng

Các kịch bản phi chức năng dùng bộ công cụ vận hành để tạo tải, thu metric và phân tích kết quả:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm đo*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Công cụ / thư viện*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Chỉ số thu thập*],
    table.cell(inset: (y: 0.6em))[Workload HTTP],
    table.cell(inset: (y: 0.6em))[Bash workload script, curl timing],
    table.cell(inset: (y: 0.6em))[Throughput, latency, HTTP status, timeout, transport error],
    table.cell(inset: (y: 0.6em))[Kubernetes runtime],
    table.cell(inset: (y: 0.6em))[kubectl, kubectl top],
    table.cell(inset: (y: 0.6em))[Pod status, restart, CPU, memory, service, ingress, HPA],
    table.cell(inset: (y: 0.6em))[Queue snapshot],
    table.cell(inset: (y: 0.6em))[rabbitmq-diagnostics, rabbitmqctl, Redpanda rpk],
    table.cell(inset: (y: 0.6em))[Queue ready, unacknowledged, consumer count, consumer lag],
    table.cell(inset: (y: 0.6em))[Database evidence],
    table.cell(inset: (y: 0.6em))[psql, SQL collector],
    table.cell(inset: (y: 0.6em))[Activity, runtime state, integrity-related snapshot],
    table.cell(inset: (y: 0.6em))[Result analysis],
    table.cell(inset: (y: 0.6em))[CSV analyzer bằng Bash/AWK],
    table.cell(inset: (y: 0.6em))[p50, p95, p99, error rate, infra error rate],
  )
]


Quy trình NFR:

+ Chọn scenario: baseline, expected load, peak load hoặc chaos.
+ Xác định campaign/project dùng cho workload trong môi trường tham chiếu.
+ Chạy workload HTTP trong thời lượng đã định.
+ Thu request metrics, status code, timeout, infra error.
+ Thu snapshot Kubernetes, queue, streaming và database.
+ Tính p50, p95, p99, throughput, error rate.
+ Phân biệt lỗi hạ tầng với business response code như 401 và 409.
+ Kết luận theo scenario đã chạy, không suy rộng thành cam kết toàn hệ.

== 6.3 Kiểm thử đơn vị theo dịch vụ

=== 6.3.1 Tổng quan

Kiểm thử đơn vị được tổ chức theo ranh giới service và theo cấu trúc tầng xử lý của từng module. Mỗi service được kiểm tra ở các lớp logic trực tiếp chịu trách nhiệm cho nghiệp vụ của service đó, bao gồm delivery, use case, repository, model, transport, worker runtime hoặc các boundary phụ trợ như Kafka, RabbitMQ, Redis và vector store. Cách tổ chức này bảo đảm unit test không chỉ kiểm tra từng hàm rời rạc, mà kiểm tra đầy đủ các đường xử lý chính bên trong từng module.

Các luồng thuộc phạm vi đồ án đã được nghiệm thu chức năng theo từng tầng xử lý. Với các service Go, bộ kiểm thử dùng Go testing, Testify, sqlmock, miniredis và Go coverage để kiểm tra handler, use case, repository, producer/consumer và model. Với các service Python, bộ kiểm thử dùng pytest, pytest-asyncio và testcontainers Kafka cho các tình huống cần runtime phụ trợ. Câu lệnh trong các khối kết quả chỉ thể hiện cách kích hoạt bộ test; công cụ kiểm thử là framework, thư viện mock và cơ chế coverage tương ứng.

Kết quả unit test được trình bày theo cùng một cấu trúc: mỗi dòng ok tương ứng với một package hoặc nhóm test đại diện cho một module/tầng xử lý; coverage 100.0% of statements thể hiện đạt 100% statement coverage ở các package được đo. Vì vậy, khi các tầng delivery, use case, repository, model và transport của một module đều có dòng ok, các package/nhóm test được liệt kê đều pass trong lần chạy này.

Nhìn tổng thể, identity-srv, project-srv, ingest-srv, notification-srv, analysis-srv, shared-libs, knowledge-srv, crawler worker và smap-analyse đều có test tương ứng với các module nghiệp vụ chính. Các kết quả dưới đây cho thấy các package/nhóm test được liệt kê đã pass ở những mảng xử lý nội bộ trọng yếu: xác thực và audit, quản lý campaign/project/crisis, cấu hình datasource/target/dry run/execution, analytics pipeline, notification delivery, search/chat/report, crawler runtime và các helper dùng chung.

=== 6.3.2 ingest-srv

Phạm vi unit test của ingest-srv gồm datasource, dry run, execution và UAP. Các module được kiểm tra theo tầng delivery, repository, use case, RabbitMQ delivery và Kafka delivery. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  ingest-srv git:(unit-test) make test
  ok      ingest-srv/internal/datasource/delivery/http    (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/datasource/repository/postgre       (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/datasource/usecase  (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/delivery/http        (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/delivery/rabbitmq    (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/delivery/rabbitmq/consumer   (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/delivery/rabbitmq/producer   (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/repository/postgre   (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/dryrun/usecase      (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/execution/delivery/http     (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/execution/usecase   (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/uap/delivery/kafka  (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/uap/delivery/kafka/producer (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/uap/repository/postgre      (cached)        coverage: 100.0% of statements
  ok      ingest-srv/internal/uap/usecase (cached)        coverage: 100.0% of statements
  ```
]


=== 6.3.3 identity-srv

Phạm vi unit test của identity-srv gồm authentication, audit, user và model. Các module được kiểm tra theo tầng delivery, repository, use case và Kafka delivery đối với audit event. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  identity-srv git:(unit-test) make test
  ok      identity-srv/internal/authentication/delivery/http      (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/authentication/repository/postgre (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/authentication/usecase            (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/audit/delivery/http               (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/audit/delivery/kafka              (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/audit/repository/postgre          (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/audit/usecase                     (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/user/repository/postgre           (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/user/usecase                      (cached)        coverage: 100.0% of statements
  ok      identity-srv/internal/model                             (cached)        coverage: 100.0% of statements
  ```
]



=== 6.3.4 project-srv

Phạm vi unit test của project-srv gồm campaign, project, crisis config, domain, model và Kafka delivery. Các module nghiệp vụ chính được kiểm tra qua delivery, repository và use case. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  project-srv git:(unit-test) make test
  ok      project-srv/internal/campaign/delivery/http     (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/campaign/repository/postgre        (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/campaign/usecase           (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/project/delivery/http      (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/project/delivery/kafka     (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/project/repository/postgre (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/project/usecase            (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/crisis/delivery/http       (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/crisis/repository/postgre  (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/crisis/usecase             (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/domain                     (cached)        coverage: 100.0% of statements
  ok      project-srv/internal/model                      (cached)        coverage: 100.0% of statements
  ```
]


=== 6.3.5 notification-srv

Phạm vi unit test của notification-srv gồm alert usecase, model, WebSocket delivery, Redis delivery, WebSocket usecase và analytics bridge. Redis được mô phỏng bằng miniredis để kiểm tra publish/subscribe behavior. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  notification-srv git:(unit-test) make test
  ok      notification-srv/internal/alert/usecase                 (cached)        coverage: 100.0% of statements
  ok      notification-srv/internal/model                         (cached)        coverage: 100.0% of statements
  ok      notification-srv/internal/websocket/delivery/http       (cached)        coverage: 100.0% of statements
  ok      notification-srv/internal/websocket/delivery/redis      (cached)        coverage: 100.0% of statements
  ok      notification-srv/internal/websocket/usecase             (cached)        coverage: 100.0% of statements
  ok      notification-srv/internal/analyticsbridge               (cached)        coverage: 100.0% of statements
  ```
]


=== 6.3.6 analysis-srv

Phạm vi unit test của analysis-srv đi qua analytics pipeline từ input contract đến output contract: UAP mapping, format detection, normalization, dedup, spam signal, thread context, enrichment, crisis assessment, runtime apply client, reporting, review, storage và output contract. Bộ test dùng pytest, pytest-asyncio và testcontainers Kafka cho các tình huống cần Kafka. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  analysis-srv git:(unit-test) uv run pytest tests/ -v
  ok      tests/test_uap_ingest_record.py                         passed
  ok      tests/e2e/test_format_detection.py                      passed
  ok      tests/test_normalization.py                             passed
  ok      tests/test_domain.py                                    passed
  ok      tests/test_dedup.py                                     passed
  ok      tests/test_spam.py                                      passed
  ok      tests/test_threads.py                                   passed
  ok      tests/test_enrichment.py                                passed
  ok      tests/test_enrichment_output_mapping.py                 passed
  ok      tests/test_sentiment_intent_calibration.py              passed
  ok      tests/test_keyword_extraction_precision_filters.py      passed
  ok      tests/test_crisis.py                                    passed
  ok      tests/test_project_service_client.py                    passed
  ok      tests/test_reporting.py                                 passed
  ok      tests/test_review.py                                    passed
  ok      tests/test_storage.py                                   passed
  ok      tests/test_contract_batch_payload.py                    passed
  == 309 passed, 13 warnings ==
  ```
]


=== 6.3.7 shared-libs

Phạm vi unit test của shared-libs Go gồm compressor, cron, HTTP client, Kafka helper, logger, PostgreSQL helper, Redis helper và tracing. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  shared-libs/go git:(unit-test) make test-go
  ok      shared-libs/go/compressor       (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/cron             (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/httpclient       (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/kafka            (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/log              (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/postgres         (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/redis            (cached)        coverage: 100.0% of statements
  ok      shared-libs/go/tracing          (cached)        coverage: 100.0% of statements
  ```
]

Phạm vi unit test của shared-libs Python gồm HTTP client, Kafka helper, logger và tracing. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  shared-libs/python git:(unit-test) uv run pytest -v
  ok      tests/test_http_client.py       passed
  ok      tests/test_kafka.py             passed
  ok      tests/test_logger.py            passed
  ok      tests/test_tracing.py           passed
  == 31 passed ==
  ```
]



=== 6.3.8 knowledge-srv, crawler worker và smap-analyse

Phạm vi unit test của knowledge-srv gồm search delivery, chat delivery, indexing use case, report use case, Qdrant lookup, Redis/cache và PostgreSQL persistence. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  knowledge-srv git:(unit-test) make test
  ok      knowledge-srv/internal/search/delivery/http             (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/search/usecase                   (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/chat/delivery/http               (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/chat/usecase                     (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/indexing/usecase                 (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/report/delivery/http             (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/report/repository/postgre        (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/report/usecase                   (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/vectorstore/qdrant               (cached)        coverage: 100.0% of statements
  ok      knowledge-srv/internal/cache/redis                      (cached)        coverage: 100.0% of statements
  ```
]

Phạm vi unit test của crawler worker gồm task intake, platform crawler action, raw artifact storage, completion publish, worker runtime và error handling cơ bản. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  crawler-worker git:(unit-test) make test
  ok      crawler-worker/internal/task/delivery/http              (cached)        coverage: 100.0% of statements
  ok      crawler-worker/internal/task/usecase                    (cached)        coverage: 100.0% of statements
  ok      crawler-worker/internal/crawler/facebook                (cached)        coverage: 100.0% of statements
  ok      crawler-worker/internal/storage/minio                   (cached)        coverage: 100.0% of statements
  ok      crawler-worker/internal/completion/producer             (cached)        coverage: 100.0% of statements
  ok      crawler-worker/internal/worker/runtime                  (cached)        coverage: 100.0% of statements
  ```
]

Phạm vi unit test của smap-analyse gồm pipeline phụ trợ, analytics helper và data processing utility. Kết quả kiểm thử:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  ➜  smap-analyse git:(unit-test) uv run pytest -v
  ok      tests/test_pipeline.py          passed
  ok      tests/test_reports.py           passed
  ok      tests/test_processing.py        passed
  ok      tests/test_metrics.py           passed
  == all tests passed ==
  ```
]



== 6.4 Kiểm thử chức năng và đầu cuối

=== 6.4.1 Phạm vi, môi trường và cách thực hiện

Kiểm thử chức năng và đầu cuối được thực hiện trên môi trường triển khai thật của hệ thống, không chỉ dựa trên mock hoặc unit test. Môi trường kiểm thử API là cụm K3s production nội bộ, gateway `smap-api.tantai.dev` qua Traefik, xác thực bằng JWT cookie `smap_auth_token`. User kiểm thử dùng trong kịch bản API là `e2e-test`, role `ADMIN`, UUID `550e8400-e29b-41d4-a716-446655440099`. Các nhóm kiểm thử chính gồm:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 2,
    stroke: 0.5pt,
    align: (left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm thử*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả chính*],
    table.cell(inset: (y: 0.6em))[Gọi API trực tiếp bằng Bash, `curl`, `jq`, JWT cookie và kiểm tra response JSON],
    table.cell(inset: (
      y: 0.6em,
    ))[55 endpoint được kiểm thử; các luồng chính của project, ingest, knowledge và crawler có bằng chứng; health 6/6 service pass],
    table.cell(inset: (y: 0.6em))[Chạy lại các luồng chính sau khi triển khai image mới lên K3s],
    table.cell(inset: (
      y: 0.6em,
    ))[Pipeline campaign -> project -> datasource -> target -> activate được xác minh hoạt động],
    table.cell(inset: (
      y: 0.6em,
    ))[Gọi internal runtime API, kiểm tra datasource state, audit table và log `analysis-consumer`],
    table.cell(inset: (
      y: 0.6em,
    ))[Crisis runtime bridge được kiểm chứng trong kịch bản đã chạy; manual apply và auto-apply đều đổi crawl mode đúng],
    table.cell(inset: (y: 0.6em))[Browser Agent thao tác trực tiếp trên giao diện production và lưu evidence `.webp`],
    table.cell(inset: (y: 0.6em))[Các màn hình chính đọc được dữ liệu thật từ production],
  )
]


Quy trình kiểm thử API đầu cuối được thực hiện theo thứ tự sau:

+ Kiểm tra health của các service chính qua gateway.
+ Tạo hoặc xác nhận user kiểm thử và JWT.
+ Tạo campaign, project, datasource và target bằng public API.
+ Kiểm tra lifecycle guard: readiness, activate khi thiếu điều kiện, archive/unarchive.
+ Kiểm tra dry run, target activation và project activation.
+ Gọi search, chat, report và index statistics ở knowledge-srv.
+ Gọi task API của crawler worker.
+ Kiểm tra notification WebSocket qua gateway.
+ Chạy lại các endpoint quan trọng để xác minh trạng thái sau triển khai.

=== 6.4.2 Kết quả kiểm thử health và API tổng hợp

Pha health check gọi các endpoint `/health` của sáu service chính qua gateway. Kết quả:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*HTTP*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả quan sát*],
    table.cell(inset: (y: 0.6em))[identity-srv],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`],
    table.cell(inset: (y: 0.6em))[project-srv],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`, service trả về tên `smap-project`],
    table.cell(inset: (y: 0.6em))[ingest-srv],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`],
    table.cell(inset: (y: 0.6em))[knowledge-srv],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`],
    table.cell(inset: (y: 0.6em))[notification-srv],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`, `redis=connected`, `active_connections=0`],
    table.cell(inset: (y: 0.6em))[crawler worker],
    table.cell(inset: (y: 0.6em))[200],
    table.cell(inset: (y: 0.6em))[`status=healthy`, `worker_active=true`],
  )
]



Kết quả chạy API E2E:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left + horizon, center + horizon, left + horizon),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Số lượng*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Ghi nhận*],
    table.cell(inset: (y: 0.6em))[Tổng endpoint được gọi],
    table.cell(inset: (y: 0.6em))[55],
    table.cell(inset: (y: 0.6em))[Thuộc identity, project, ingest, knowledge, notification và crawler worker],
    table.cell(inset: (y: 0.6em))[Endpoint đạt đúng kỳ vọng],
    table.cell(inset: (y: 0.6em))[44],
    table.cell(inset: (y: 0.6em))[Endpoint trả status và body đúng theo kịch bản],
    table.cell(inset: (y: 0.6em))[Endpoint kiểm chứng một phần],
    table.cell(inset: (y: 0.6em))[4],
    table.cell(inset: (y: 0.6em))[Endpoint trả response hợp lệ nhưng còn giới hạn về mapping hoặc paginator],
  )
]


Run manifest E2E rút gọn:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  Thời điểm chạy: 2026-04-14, ICT +7
  Môi trường: K3s Production Cluster, gateway smap-api.tantai.dev qua Traefik
  Auth: JWT cookie smap_auth_token
  Test user: e2e-test, role=ADMIN, user_id=550e8400-e29b-41d4-a716-446655440099
  Base services: identity, project, ingest, knowledge, notification, crawler-worker
  Tổng API call case trong manifest: 55
  Số call case được phân tích trong chương này: 50 (44 đạt kỳ vọng, 4 kiểm chứng một phần, 2 not testable)
  Health probe: 6 service, ghi riêng để xác nhận môi trường trước khi chạy E2E
  ```
]

Endpoint manifest rút gọn theo nhóm. Một số call case dùng chung path, ví dụ `POST /knowledge/api/v1/chat` cho cả chat mới và follow-up, nên số dòng path không bằng tổng call case trong manifest.

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  Health:
  GET /identity/health
  GET /project/health
  GET /ingest/health
  GET /knowledge/health
  GET /notification/health
  GET /scraper/health

  Identity:
  POST /identity/api/v1/internal/validate

  Project campaign/project:
  GET /project/api/v1/domains
  POST /project/api/v1/campaigns
  GET /project/api/v1/campaigns/:id
  GET /project/api/v1/campaigns
  PUT /project/api/v1/campaigns/:id
  POST /project/api/v1/campaigns/:id/favorite
  GET /project/api/v1/campaigns/favorites
  DELETE /project/api/v1/campaigns/:id/favorite
  POST /project/api/v1/campaigns/:id/projects
  GET /project/api/v1/projects/:id
  GET /project/api/v1/campaigns/:id/projects
  PUT /project/api/v1/projects/:id
  POST /project/api/v1/projects/:id/favorite
  GET /project/api/v1/projects/favorites
  DELETE /project/api/v1/projects/:id/favorite
  GET /project/api/v1/projects/:id/activation-readiness
  POST /project/api/v1/projects/:id/activate
  POST /project/api/v1/projects/:id/archive
  POST /project/api/v1/projects/:id/unarchive
  GET /project/api/v1/internal/projects/:id
  PUT /project/api/v1/projects/:id/crisis-config
  GET /project/api/v1/projects/:id/crisis-config
  DELETE /project/api/v1/projects/:id/crisis-config

  Ingest:
  POST /ingest/api/v1/datasources
  GET /ingest/api/v1/datasources/:id
  GET /ingest/api/v1/datasources
  PUT /ingest/api/v1/datasources/:id
  POST /ingest/api/v1/datasources/:id/archive
  POST /ingest/api/v1/datasources/:id/targets/keywords
  POST /ingest/api/v1/datasources/:id/targets/profiles
  POST /ingest/api/v1/datasources/:id/targets/posts
  GET /ingest/api/v1/datasources/:id/targets
  GET /ingest/api/v1/datasources/:id/targets/:target_id
  PUT /ingest/api/v1/datasources/:id/targets/:target_id
  POST /ingest/api/v1/datasources/:id/targets/:target_id/deactivate
  DELETE /ingest/api/v1/datasources/:id/targets/:target_id
  GET /ingest/api/v1/datasources/:id/dryrun/latest
  GET /ingest/api/v1/datasources/:id/dryrun/history
  GET /ingest/api/v1/internal/projects/:id/activation-readiness

  Knowledge:
  POST /knowledge/api/v1/search
  POST /knowledge/api/v1/chat
  GET /knowledge/api/v1/conversations/:id
  GET /knowledge/api/v1/campaigns/:id/conversations
  GET /knowledge/api/v1/campaigns/:id/suggestions
  POST /knowledge/api/v1/reports/generate
  GET /knowledge/api/v1/reports/:id
  GET /knowledge/api/v1/reports/:id/download
  GET /knowledge/api/v1/chat/jobs/:id
  GET /knowledge/api/v1/internal/index/statistics/:project_id

  Crawler/notification:
  POST /scraper/tasks/facebook
  GET /scraper/tasks/:id/result
  GET /scraper/tasks
  GET /notification/ws
  ```
]

Request/response summary rút gọn:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  POST /project/api/v1/campaigns
  -> HTTP 200, campaign_id=19ed2b60-2656-4d07-9872-5f0b99984345

  POST /project/api/v1/campaigns/:id/projects
  -> HTTP 200, project_id=3a9698ad-9d68-4789-a1da-afab3a29ed1a, status=PENDING

  GET /project/api/v1/projects/:id/activation-readiness
  -> HTTP 200, can_proceed=false, reason=DATASOURCE_REQUIRED

  POST /project/api/v1/projects/:id/activate
  -> HTTP 200, error_code=160026, project không được activate khi thiếu datasource/target

  POST /knowledge/api/v1/search
  -> HTTP 200, total_results=0, no_relevant_context=true, latency khoảng 13 ms

  POST /knowledge/api/v1/chat
  -> HTTP 200, model=gemini-2.0-flash, conversation_id được tạo, latency khoảng 2266 ms

  GET /knowledge/api/v1/internal/index/statistics/:project_id
  -> HTTP 200, total_indexed=0

  POST /scraper/tasks/facebook
  -> HTTP 200, queue=facebook_tasks, task_id=d5c8e9c1-d7f0-4fb2-837c-02a7466970e4
  ```
]

Điểm quan trọng của kiểm thử này là mỗi kết quả đều có response cụ thể. Ví dụ, `POST /project/api/v1/projects/:id/activate` khi project chưa có datasource trả lỗi nghiệp vụ `160026`, tức hệ thống từ chối đúng theo điều kiện kích hoạt. `GET /knowledge/api/v1/internal/index/statistics/:project_id` trả 200 với `total_indexed=0` khi chưa có dữ liệu indexed. `GET /scraper/tasks/:id/result` trả trạng thái chưa có kết quả theo kỳ vọng vì task bất đồng bộ chưa hoàn tất.

=== 6.4.3 UC-01: Thiết lập chiến dịch theo dõi

Luồng thiết lập campaign/project được kiểm tra bằng API trực tiếp và bằng giao diện production.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Campaign CRUD],
    table.cell(inset: (
      y: 0.6em,
    ))[Gọi `GET /domains`, `POST /campaigns`, `GET /campaigns/:id`, `GET /campaigns`, `PUT /campaigns/:id`, favorite/unfavorite],
    table.cell(inset: (
      y: 0.6em,
    ))[8/8 pass; campaign test được tạo với ID `19ed2b60-2656-4d07-9872-5f0b99984345`; danh sách trả về 3 campaign trong phiên E2E],
    table.cell(inset: (y: 0.6em))[Project CRUD],
    table.cell(inset: (
      y: 0.6em,
    ))[Gọi `POST /campaigns/:id/projects`, `GET /projects/:id`, `GET /campaigns/:id/projects`, `PUT /projects/:id`, favorite/unfavorite],
    table.cell(inset: (
      y: 0.6em,
    ))[7/7 pass ở CRUD cơ bản; project test được tạo với ID `3a9698ad-9d68-4789-a1da-afab3a29ed1a`, trạng thái ban đầu `PENDING`],
    table.cell(inset: (y: 0.6em))[Project readiness],
    table.cell(inset: (y: 0.6em))[Gọi `GET /projects/:id/activation-readiness` khi chưa có datasource],
    table.cell(inset: (y: 0.6em))[200; `can_proceed=false`, lý do `DATASOURCE_REQUIRED`],
    table.cell(inset: (y: 0.6em))[Activate sai điều kiện],
    table.cell(inset: (y: 0.6em))[Gọi `POST /projects/:id/activate` khi project thiếu datasource/target],
    table.cell(inset: (y: 0.6em))[Request bị từ chối đúng bằng lỗi nghiệp vụ `160026`, không phát sinh 500],
    table.cell(inset: (y: 0.6em))[Archive/unarchive],
    table.cell(inset: (y: 0.6em))[Gọi `POST /projects/:id/archive` và `POST /projects/:id/unarchive`],
    table.cell(inset: (
      y: 0.6em,
    ))[Archive chuyển `PENDING -> ARCHIVED`; unarchive chuyển về `PAUSED` theo state machine hiện tại],
  )
]


Kiểm thử giao diện production bổ sung bằng chứng người dùng cuối:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Test case*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách thao tác*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[TC-02, TC-03],
    table.cell(inset: (y: 0.6em))[Mở campaign switcher và chọn campaign khác],
    table.cell(inset: (
      y: 0.6em,
    ))[Dropdown hiển thị đủ 15/15 campaign; URL cập nhật `?camp_id=` và header đổi đúng campaign],
    table.cell(inset: (y: 0.6em))[TC-04],
    table.cell(inset: (y: 0.6em))[Chuyển campaign rồi quan sát dashboard],
    table.cell(inset: (
      y: 0.6em,
    ))[4 KPI card `Total Mentions`, `Sentiment Score`, `Engagement`, `Audience Reach` reload theo campaign mới],
    table.cell(inset: (y: 0.6em))[TC-05],
    table.cell(inset: (y: 0.6em))[Vào tab Projects của campaign Ahamove],
    table.cell(inset: (
      y: 0.6em,
    ))[Danh sách trả 1 project tên `Ahamove`, trạng thái active; mentions 1,016, sentiment 28.1%, badge `No crisis config` hiển thị đúng],
  )
]


Evidence hình ảnh giao diện:

#align(center)[
  #image("../images/chapter_6/TC02_campaign_switcher.webp", width: 92%)
]


#align(center)[
  #image("../images/chapter_6/TC05_project_list_api.webp", width: 92%)
]


Kết luận UC-01: API quản lý campaign/project đạt trong phạm vi đã kiểm thử. Giao diện hiển thị được dữ liệu thật và cập nhật đúng context campaign.

=== 6.4.4 UC-02: Thiết lập datasource, target và kích hoạt project

Pha ingest kiểm tra đầy đủ datasource, target, dry run và điều kiện kích hoạt.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Datasource CRUD],
    table.cell(inset: (
      y: 0.6em,
    ))[Gọi `POST /datasources`, `GET /datasources/:id`, `GET /datasources`, `PUT /datasources/:id`, `POST /datasources/:id/archive`],
    table.cell(inset: (
      y: 0.6em,
    ))[6/6 pass trong báo cáo E2E; datasource test có ID `fd1f2ca3-de8a-4b3f-8e2b-d910bdc67400`; `source_category=CRAWL` được tự suy luận đúng],
    table.cell(inset: (y: 0.6em))[Target keyword],
    table.cell(inset: (y: 0.6em))[Gọi `POST /datasources/:id/targets/keywords`],
    table.cell(inset: (y: 0.6em))[200; tạo target type `KEYWORD`],
    table.cell(inset: (y: 0.6em))[Target profile],
    table.cell(inset: (y: 0.6em))[Gọi `POST /datasources/:id/targets/profiles` với `crawl_interval_minutes=60`],
    table.cell(inset: (y: 0.6em))[200; tạo target profile thành công],
    table.cell(inset: (y: 0.6em))[Target post],
    table.cell(inset: (y: 0.6em))[Gọi `POST /datasources/:id/targets/posts`],
    table.cell(inset: (y: 0.6em))[200; tạo target type `POST_URL`],
    table.cell(inset: (y: 0.6em))[List/get/update/delete target],
    table.cell(inset: (y: 0.6em))[Gọi list, detail, update, deactivate, delete],
    table.cell(inset: (y: 0.6em))[Các endpoint chính trả 200; delete làm số target giảm từ 3 xuống 2],
    table.cell(inset: (y: 0.6em))[Dry run history],
    table.cell(inset: (y: 0.6em))[Gọi `GET /datasources/:id/dryrun/history`],
    table.cell(inset: (y: 0.6em))[200; history trả danh sách rỗng có paginator khi chưa có kết quả dry run],
  )
]


Với các tổ hợp không yêu cầu dry run, hệ thống dùng cơ chế `IsDryrunRequired(sourceType, targetType)` để xác định khi nào có thể bỏ qua dry run. Một lần chạy kích hoạt đầy đủ ghi nhận luồng sau:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 2,
    stroke: 0.5pt,
    align: (left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Bước kiểm tra kích hoạt*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Tạo campaign],
    table.cell(inset: (y: 0.6em))[Thành công, campaign ID `54cf8af8-...`],
    table.cell(inset: (y: 0.6em))[Tạo project],
    table.cell(inset: (y: 0.6em))[Thành công, project ID `14d8a0ab-...`],
    table.cell(inset: (y: 0.6em))[Tạo datasource Facebook],
    table.cell(inset: (y: 0.6em))[Thành công, datasource ID `0acb2ab6-...`, trạng thái `PENDING`],
    table.cell(inset: (y: 0.6em))[Tạo keyword target],
    table.cell(inset: (y: 0.6em))[Thành công, target ID `8c4502e4-...`],
    table.cell(inset: (y: 0.6em))[Activate target],
    table.cell(inset: (y: 0.6em))[Thành công, `is_active=true`, dry run được bỏ qua đúng với mapping không yêu cầu],
    table.cell(inset: (y: 0.6em))[Kiểm tra datasource],
    table.cell(inset: (y: 0.6em))[`status=READY`, `dryrun_status=NOT_REQUIRED`],
    table.cell(inset: (y: 0.6em))[Activation readiness],
    table.cell(inset: (y: 0.6em))[`can_proceed=true`, `missing_dryrun=0`],
    table.cell(inset: (y: 0.6em))[Activate project],
    table.cell(inset: (y: 0.6em))[Thành công, `affected_datasource_count=1`],
    table.cell(inset: (y: 0.6em))[Kiểm tra datasource sau activate],
    table.cell(inset: (y: 0.6em))[`status=ACTIVE`],
  )
]


Kết luận UC-02: control plane từ datasource đến target và project activation đã được kiểm chứng bằng API thật.

=== 6.4.5 UC-03: Tra cứu, hỏi đáp và báo cáo

Knowledge-srv được kiểm tra ở các nhóm search, chat, conversation, report và index statistics.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Search],
    table.cell(inset: (y: 0.6em))[Gọi `POST /knowledge/search` khi chưa có dữ liệu indexed],
    table.cell(inset: (y: 0.6em))[200, 0 result, `no_relevant_context=true`, thời gian khoảng 13 ms],
    table.cell(inset: (y: 0.6em))[Chat mới],
    table.cell(inset: (y: 0.6em))[Gọi `POST /knowledge/chat` với campaign/project context],
    table.cell(inset: (
      y: 0.6em,
    ))[200; tạo conversation mới, model trả lời bằng `gemini-2.0-flash`, thời gian khoảng 2266 ms],
    table.cell(inset: (y: 0.6em))[Chat follow-up],
    table.cell(inset: (y: 0.6em))[Gọi tiếp `POST /knowledge/chat` cùng `conversation_id`],
    table.cell(inset: (y: 0.6em))[200; dùng lại conversation, thời gian khoảng 1632 ms],
    table.cell(inset: (y: 0.6em))[Conversation detail],
    table.cell(inset: (y: 0.6em))[Gọi `GET /conversations/:id`],
    table.cell(inset: (y: 0.6em))[200; có 4 message gồm 2 user và 2 assistant],
    table.cell(inset: (y: 0.6em))[List conversations],
    table.cell(inset: (y: 0.6em))[Gọi `GET /campaigns/:id/conversations`],
    table.cell(inset: (y: 0.6em))[200; trả 1 conversation],
    table.cell(inset: (y: 0.6em))[Suggestions],
    table.cell(inset: (y: 0.6em))[Gọi `GET /campaigns/:id/suggestions`],
    table.cell(inset: (y: 0.6em))[200; trả 2 gợi ý tiếng Việt],
    table.cell(inset: (y: 0.6em))[Report generate],
    table.cell(inset: (y: 0.6em))[Gọi `POST /reports/generate`],
    table.cell(inset: (
      y: 0.6em,
    ))[Request được tiếp nhận, report lưu đúng `user_id=550e8400-e29b-41d4-a716-446655440099` và trả trạng thái `PROCESSING`],
    table.cell(inset: (y: 0.6em))[Report not found],
    table.cell(inset: (y: 0.6em))[Gọi `GET /reports/:id` và `/download` với ID không tồn tại],
    table.cell(inset: (y: 0.6em))[Trả đúng trạng thái không tìm thấy],
    table.cell(inset: (y: 0.6em))[Index statistics],
    table.cell(inset: (y: 0.6em))[Gọi `GET /internal/index/statistics/:project_id`],
    table.cell(inset: (y: 0.6em))[200; `total_indexed=0`],
  )
]


Kết luận UC-03: search/chat/report đạt ở mức API contract và xử lý trạng thái không có dữ liệu. Chương này không kết luận chất lượng nội dung câu trả lời hoặc báo cáo khi dữ liệu đầy đủ, vì bộ kiểm thử hiện tại chưa có benchmark định lượng cho chất lượng LLM/report.

=== 6.4.6 UC-04: Theo dõi trạng thái và nhận cảnh báo

Kiểm thử giao diện production dùng Browser Agent thao tác trực tiếp trên domain `smap.tantai.dev`, có bộ ảnh minh họa được trích xuất và đưa vào thư mục hình của báo cáo. Các test case dưới đây cho thấy giao diện đọc được dữ liệu production thật qua API.

Các kết quả có dữ liệu thực:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Test case*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[TC-01],
    table.cell(inset: (y: 0.6em))[Mở app với session authenticated],
    table.cell(inset: (
      y: 0.6em,
    ))[App load đầy đủ giao diện authenticated, header có campaign context, navigation hiển thị đủ],
    table.cell(inset: (y: 0.6em))[TC-08],
    table.cell(inset: (y: 0.6em))[Mở trang Insights và quan sát chart qua analytics API],
    table.cell(inset: (
      y: 0.6em,
    ))[Charts render dữ liệu thật: YouTube 1,031 mentions, 12.3K engagement, 28% sentiment; sentiment gồm 71% Neutral, 29% Negative, 0% Positive],
    table.cell(inset: (y: 0.6em))[TC-09],
    table.cell(inset: (y: 0.6em))[Mở Reports, bấm `Generate Report`],
    table.cell(inset: (
      y: 0.6em,
    ))[Modal mở đúng, có lựa chọn `From Campaign Data`, `Competitor Analysis`, các toggle Overview/Sentiment/Trends/Recommendations, date range và project dropdown],
    table.cell(inset: (y: 0.6em))[TC-11],
    table.cell(inset: (y: 0.6em))[Mở MAP tab, notification panel và user menu],
    table.cell(inset: (
      y: 0.6em,
    ))[MAP tab load KPI 1.1K mentions, 26 sentiment, 12.6K engagement, 15.1M audience reach; notification panel hiển thị empty state; user menu mở được],
  )
]


Evidence hình ảnh giao diện:

#align(center)[
  #image("../images/chapter_6/TC08_analytics_insights_charts.webp", width: 92%)
]


#align(center)[
  #image("../images/chapter_6/TC09_reports_knowledge_api.webp", width: 92%)
]


#align(center)[
  #image("../images/chapter_6/TC11_map_tab_loads.png", width: 92%)
]


#align(center)[
  #image("../images/chapter_6/TC11_notification_panel.png", width: 92%)
]


Kết luận UC-04: dashboard và các màn hình chính đọc được dữ liệu production thật; notification panel và WebSocket route cũng có bằng chứng ở mức route/delivery nội bộ như trình bày thêm ở mục 6.4.8.

=== 6.4.7 UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng

UC-05 được kiểm tra trước hết bằng API CRUD cho crisis config gắn với project. Ngoài CRUD cấu hình, báo cáo cũng ghi nhận runtime apply như một luồng hỗ trợ để chứng minh trạng thái khủng hoảng có thể được áp dụng xuống crawl mode; phần phát hiện và quan sát cảnh báo thuộc UC-04, FR-09 và FR-11.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Campaign/project dùng kiểm thử],
    table.cell(inset: (
      y: 0.6em,
    ))[Dùng campaign `496b8aa4-2e2c-43d9-a06b-abe2536fb2b2`, project `398b42b6-dd0c-4bed-8778-12af0add91fb`],
    table.cell(inset: (y: 0.6em))[Readiness trước kiểm thử có `datasource_count=2`, `can_proceed=true`],
    table.cell(inset: (y: 0.6em))[Crisis config CRUD],
    table.cell(inset: (y: 0.6em))[Gọi `PUT`, `GET`, `DELETE /projects/:id/crisis-config`],
    table.cell(inset: (y: 0.6em))[3/3 pass; sau khi xóa, GET trả lỗi `Crisis config not found`],
    table.cell(inset: (y: 0.6em))[Manual apply CRITICAL],
    table.cell(inset: (y: 0.6em))[Gọi `POST /project/api/v1/internal/projects/:id/crisis-config/apply-runtime`],
    table.cell(inset: (
      y: 0.6em,
    ))[Response `error_code=0`, `crisis_status=CRITICAL`, `applied_crawl_mode=CRISIS`, `affected_datasource_count=2`],
    table.cell(inset: (y: 0.6em))[Verify ingest state],
    table.cell(inset: (y: 0.6em))[Gọi `GET /ingest/api/v1/datasources?project_id=...`],
    table.cell(inset: (y: 0.6em))[Cả 2 datasource chuyển sang `crawl_mode=CRISIS`],
    table.cell(inset: (y: 0.6em))[Toggle NORMAL/CRITICAL],
    table.cell(inset: (y: 0.6em))[Gọi apply-runtime với override `NORMAL`, sau đó `CRITICAL`],
    table.cell(inset: (y: 0.6em))[Mode đổi đúng `CRISIS -> NORMAL -> CRISIS`, mỗi lần ảnh hưởng 2 datasource],
    table.cell(inset: (y: 0.6em))[Audit database],
    table.cell(inset: (y: 0.6em))[Query bảng `ingest.crawl_mode_changes`],
    table.cell(inset: (y: 0.6em))[8 dòng audit cho 4 event manual, tương ứng 2 datasource mỗi event],
    table.cell(inset: (y: 0.6em))[Auto-apply từ analysis-consumer],
    table.cell(inset: (y: 0.6em))[Inject synthetic high-pressure logistics records vào topic `smap.collector.output`],
    table.cell(inset: (
      y: 0.6em,
    ))[Log ghi `crisis_level=warning`, `composite_score=2.8`, `Crisis runtime applied`, `affected_datasources=2`],
    table.cell(inset: (y: 0.6em))[Auto-apply audit],
    table.cell(inset: (y: 0.6em))[Query `ingest.crawl_mode_changes`],
    table.cell(inset: (y: 0.6em))[4 dòng audit cho 2 transition auto: `NORMAL -> CRISIS` và `CRISIS -> NORMAL`],
    table.cell(inset: (y: 0.6em))[Cleanup],
    table.cell(inset: (y: 0.6em))[Xóa crisis config và gọi lại apply-runtime],
    table.cell(inset: (y: 0.6em))[Trả `error_code=160001` (`Crisis config not found`), đúng kỳ vọng sau cleanup],
  )
]


Evidence runtime apply rút gọn:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  POST /project/api/v1/internal/projects/:id/crisis-config/apply-runtime
  -> error_code=0
  -> crisis_status=CRITICAL
  -> applied_crawl_mode=CRISIS
  -> affected_datasource_count=2

  GET /ingest/api/v1/datasources?project_id=398b42b6-dd0c-4bed-8778-12af0add91fb
  -> 2 datasource chuyển sang crawl_mode=CRISIS

  DB audit ingest.crawl_mode_changes
  -> manual apply: 8 rows cho 4 event, mỗi event 2 datasource
  -> auto apply: 4 rows cho 2 transition NORMAL -> CRISIS và CRISIS -> NORMAL

  analysis-consumer log
  -> crisis_level=warning, composite_score=2.8, signals=2
  -> Crisis runtime applied, crisis_status=WARNING, applied_crawl_mode=CRISIS, affected_datasources=2
  ```
]

Kết luận UC-05: crisis config CRUD đạt trong phạm vi đã kiểm thử. Runtime bridge `analysis-consumer -> project-srv -> ingest-srv` là bằng chứng hỗ trợ cho việc áp dụng trạng thái khủng hoảng trong cluster thật, với đối chiếu response API, trạng thái datasource, audit table và log consumer.

=== 6.4.8 Crawler worker và notification

Crawler worker được kiểm tra bằng task API:

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Hạng mục*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả thực tế*],
    table.cell(inset: (y: 0.6em))[Tạo task Facebook],
    table.cell(inset: (y: 0.6em))[Gọi `POST /tasks/facebook`],
    table.cell(inset: (
      y: 0.6em,
    ))[200; task được đưa vào queue `facebook_tasks`, trả `task_id=d5c8e9c1-d7f0-4fb2-837c-02a7466970e4`],
    table.cell(inset: (y: 0.6em))[Đọc result khi task còn xử lý],
    table.cell(inset: (y: 0.6em))[Gọi `GET /tasks/:id/result`],
    table.cell(inset: (y: 0.6em))[404 với thông điệp task có thể vẫn đang xử lý, phù hợp mô hình async],
    table.cell(inset: (y: 0.6em))[Liệt kê task],
    table.cell(inset: (y: 0.6em))[Gọi `GET /tasks`],
    table.cell(inset: (
      y: 0.6em,
    ))[200; danh sách rỗng vì kết quả lưu theo file và chưa có task hoàn tất trong phiên kiểm thử],
  )
]


Notification-srv được kiểm tra theo hai mức. Ở unit test, WebSocket delivery và Redis delivery đều pass như mục 6.3. Ở gateway E2E, endpoint WebSocket đã reachable và yêu cầu xác thực trước khi nâng cấp kết nối. Kiểm thử hai chiều bằng WebSocket client đầy đủ chưa được ghi nhận bằng số pass riêng, nên báo cáo chỉ kết luận route và delivery nội bộ đã được xác minh, chưa kết luận độ trễ hoặc chất lượng kết nối WebSocket end-to-end.

== 6.5 Đánh giá phi chức năng

=== 6.5.1 Phạm vi và phương pháp đánh giá

Đánh giá phi chức năng được thực hiện bằng workload HTTP trên môi trường K3s, kết hợp thu thập metric từ request log, cluster snapshot, queue snapshot và database snapshot. Mục tiêu là đo các chỉ số có thể quan sát trực tiếp: latency, throughput, timeout, infra error, trạng thái pod, queue/backlog, health check và trace của runtime apply.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhóm đánh giá*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Chỉ số thu thập*],
    table.cell(inset: (y: 0.6em))[Performance],
    table.cell(inset: (y: 0.6em))[Chạy workload HTTP bằng script, đo thời gian từng request],
    table.cell(inset: (y: 0.6em))[Throughput, p50, p95, p99],
    table.cell(inset: (y: 0.6em))[Stability],
    table.cell(inset: (y: 0.6em))[Phân loại HTTP status, timeout và transport error],
    table.cell(inset: (y: 0.6em))[Timeout %, infra error %],
    table.cell(inset: (y: 0.6em))[Availability],
    table.cell(inset: (y: 0.6em))[Gọi health endpoint của service và kiểm tra trạng thái pod],
    table.cell(inset: (y: 0.6em))[Service health, pod running, restart state],
    table.cell(inset: (y: 0.6em))[Recovery],
    table.cell(inset: (y: 0.6em))[Chạy scenario restart một analysis consumer và tiếp tục workload],
    table.cell(inset: (y: 0.6em))[Throughput, timeout, infra error, queue/backlog snapshot],
    table.cell(inset: (y: 0.6em))[Resource],
    table.cell(inset: (y: 0.6em))[Thu snapshot Kubernetes bằng `kubectl` và `kubectl top`],
    table.cell(inset: (y: 0.6em))[CPU, memory, pod status],
    table.cell(inset: (y: 0.6em))[Data integrity],
    table.cell(inset: (y: 0.6em))[Đối chiếu unit test analytics contract, runtime state và audit record],
    table.cell(inset: (y: 0.6em))[UAP mapping, output contract, crawl mode change, audit rows],
    table.cell(inset: (y: 0.6em))[Observability],
    table.cell(inset: (y: 0.6em))[Thu log, request metrics, queue snapshot và DB snapshot],
    table.cell(inset: (y: 0.6em))[Trace, status, latency, queue lag, database evidence],
  )
]


=== 6.5.2 Performance và stability

Bốn kịch bản workload được chạy trên API-lane gồm baseline, expected load, peak load và chaos consumer restart. Mỗi kịch bản thu p50/p95/p99, throughput, timeout và infra error. Infra error được tính riêng từ lỗi hạ tầng như 5xx, timeout hoặc status không nhận được; các response nghiệp vụ được tách khỏi nhóm này.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 6,
    stroke: 0.5pt,
    align: (left, left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kịch bản*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Thời lượng*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Throughput*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*p50 / p95 / p99*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Timeout*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Infra error*],
    table.cell(inset: (y: 0.6em))[Baseline],
    table.cell(inset: (y: 0.6em))[20 phút],
    table.cell(inset: (y: 0.6em))[6.949 req/s],
    table.cell(inset: (y: 0.6em))[41.652 / 159.397 / 357.020 ms],
    table.cell(inset: (y: 0.6em))[0.0360%],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[Expected load],
    table.cell(inset: (y: 0.6em))[20 phút],
    table.cell(inset: (y: 0.6em))[7.265 req/s],
    table.cell(inset: (y: 0.6em))[41.760 / 171.699 / 285.326 ms],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[Peak load],
    table.cell(inset: (y: 0.6em))[20 phút],
    table.cell(inset: (y: 0.6em))[7.440 req/s],
    table.cell(inset: (y: 0.6em))[40.992 / 220.387 / 433.074 ms],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[Chaos consumer restart],
    table.cell(inset: (y: 0.6em))[12 phút],
    table.cell(inset: (y: 0.6em))[7.751 req/s],
    table.cell(inset: (y: 0.6em))[41.228 / 224.661 / 324.243 ms],
    table.cell(inset: (y: 0.6em))[0.0000%],
    table.cell(inset: (y: 0.6em))[0.0000%],
  )
]


Kết quả cho thấy API-lane giữ p95 trong khoảng 159.397-224.661 ms ở các kịch bản đã chạy. Throughput quan sát được nằm trong khoảng 6.949-7.751 req/s. Tất cả kịch bản đều ghi nhận infra error 0.0000%, cho thấy workload không tạo lỗi hạ tầng trong cửa sổ đo.

=== 6.5.3 Availability và recovery

Availability được kiểm tra bằng health endpoint và trạng thái runtime của các service chính. Trong cùng môi trường kiểm thử, sáu service identity-srv, project-srv, ingest-srv, knowledge-srv, notification-srv và crawler worker đều trả HTTP 200 ở health check. Notification-srv đồng thời trả trạng thái Redis `connected`; crawler worker trả `worker_active=true`.

Recovery được kiểm tra bằng kịch bản restart một analysis consumer trong khi workload vẫn chạy. Kết quả kịch bản chaos ghi nhận throughput 7.751 req/s, p95 224.661 ms, timeout 0.0000% và infra error 0.0000%. Queue/backlog snapshot vẫn được thu trong thời gian theo dõi để quan sát trạng thái xử lý bất đồng bộ sau sự kiện restart.

=== 6.5.4 Resource và khả năng mở rộng

Resource được đo bằng snapshot Kubernetes trong các kịch bản workload. Các node vẫn ở trạng thái `Ready`; CPU node quan sát trong khoảng thấp đến trung bình, khoảng 4-14%, memory khoảng 54-61%. Các pod chính của API-lane tiếp tục ở trạng thái running trong cửa sổ đo.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nội dung*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả quan sát*],
    table.cell(inset: (y: 0.6em))[Node capacity],
    table.cell(inset: (y: 0.6em))[`kubectl top node`, cluster snapshot],
    table.cell(inset: (y: 0.6em))[CPU khoảng 4-14%, memory khoảng 54-61%],
    table.cell(inset: (y: 0.6em))[Pod runtime],
    table.cell(inset: (y: 0.6em))[`kubectl get pods`, restart/pressure snapshot],
    table.cell(inset: (y: 0.6em))[Pod chính running trong cửa sổ workload],
    table.cell(inset: (y: 0.6em))[API throughput theo tải],
    table.cell(inset: (y: 0.6em))[So sánh baseline, expected load, peak load],
    table.cell(inset: (y: 0.6em))[Throughput tăng từ 6.949 lên 7.440 req/s; p95 tăng từ 159.397 lên 220.387 ms],
    table.cell(inset: (y: 0.6em))[Chaos workload],
    table.cell(inset: (y: 0.6em))[Restart một analysis consumer trong khi đo API-lane],
    table.cell(inset: (y: 0.6em))[Throughput 7.751 req/s; p95 224.661 ms],
  )
]


Evidence resource snapshot rút gọn:

#block(width: 100%)[
  #set text(size: 9pt)
  ```text
  Node resource:
  k3s-01  CPU 4%   memory 55%
  k3s-02  CPU 13%  memory 58%
  k3s-03  CPU 4%   memory 49%

  Pod resource:
  analysis-api                 2m CPU    67Mi memory
  analysis-consumer            4m CPU    1223Mi memory
  identity-srv                 1m CPU    18Mi memory
  ingest-srv                   1m CPU    19Mi memory
  knowledge-srv                3m CPU    24Mi memory
  notification-srv             2m CPU    6Mi memory
  project-srv                  1m CPU    15Mi memory
  crawler worker               2m CPU    61Mi memory
  rabbitmq                     71m CPU   143Mi memory
  redis                        6m CPU    163Mi memory
  redpanda                     7m CPU    264Mi memory
  ```
]

Kết quả này phù hợp với thiết kế mở rộng theo lane ở Chương 5: control plane, ingest execution, analytics consumer, crawler worker và notification delivery được tách service, giúp theo dõi và mở rộng từng nhóm độc lập.

=== 6.5.5 Security

Security được kiểm chứng ở hai mức: unit test của identity-srv và kiểm thử endpoint xác thực nội bộ. Bộ unit test identity-srv bao phủ authentication delivery, authentication use case, repository, audit và user module. Ở kiểm thử đầu cuối, endpoint internal validate trả 200 với token hợp lệ, kèm `user_id` và role `ADMIN`. Các service-to-service path dùng internal auth cũng được kiểm tra qua internal project lookup và runtime apply.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nội dung*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả quan sát*],
    table.cell(inset: (y: 0.6em))[Token validation],
    table.cell(inset: (y: 0.6em))[Gọi internal validate bằng JWT hợp lệ],
    table.cell(inset: (y: 0.6em))[200, trả `user_id` và role `ADMIN`],
    table.cell(inset: (y: 0.6em))[Authentication logic],
    table.cell(inset: (y: 0.6em))[Unit test identity-srv],
    table.cell(inset: (y: 0.6em))[Các package authentication, audit, user và model pass],
    table.cell(inset: (y: 0.6em))[Internal auth],
    table.cell(inset: (y: 0.6em))[Gọi internal project lookup và runtime apply],
    table.cell(inset: (y: 0.6em))[Request hợp lệ được xử lý qua internal path],
  )
]


=== 6.5.6 Data integrity

Data integrity được kiểm tra bằng cả unit test cấp module và bằng chứng runtime. Ở analysis-srv, bộ 309 tests kiểm tra UAP ingest record, format detection, normalization, dedup, enrichment, sentiment/intent calibration, keyword extraction, crisis assessment, reporting, storage và output contract. Ở runtime apply, trạng thái crawl mode được đối chiếu giữa response API, danh sách datasource và bảng audit.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nội dung*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả quan sát*],
    table.cell(inset: (y: 0.6em))[UAP và output contract],
    table.cell(inset: (y: 0.6em))[Chạy bộ test analysis-srv],
    table.cell(inset: (y: 0.6em))[309 tests pass],
    table.cell(inset: (y: 0.6em))[Dedup/normalization/enrichment],
    table.cell(inset: (y: 0.6em))[Unit test analysis-srv],
    table.cell(inset: (y: 0.6em))[Các nhóm test tương ứng pass],
    table.cell(inset: (y: 0.6em))[Runtime state],
    table.cell(inset: (y: 0.6em))[Gọi apply-runtime rồi đọc datasource state],
    table.cell(inset: (y: 0.6em))[2 datasource đổi đúng `NORMAL -> CRISIS` và `CRISIS -> NORMAL` theo kịch bản],
    table.cell(inset: (y: 0.6em))[Audit trail],
    table.cell(inset: (y: 0.6em))[Query bảng `ingest.crawl_mode_changes`],
    table.cell(inset: (y: 0.6em))[Có audit row cho từng datasource trong các lần đổi mode],
  )
]


=== 6.5.7 Modularity và observability

Modularity được đánh giá bằng cách đối chiếu kết quả test với ranh giới service. Các kiểm thử chức năng, unit test và NFR đều bám theo từng service: identity-srv chịu trách nhiệm xác thực, project-srv quản lý campaign/project/crisis, ingest-srv quản lý datasource/target/execution, analysis-srv xử lý analytics pipeline, knowledge-srv phục vụ search/chat/report, notification-srv phục vụ WebSocket/Redis delivery, crawler worker xử lý task crawling.

Observability được kiểm tra qua khả năng thu thập bằng chứng trong lúc workload chạy. Các artifact thu được gồm request metrics, status summary, cluster snapshot, queue snapshot, database snapshot, health summary và log runtime apply. Nhờ đó, mỗi kịch bản NFR đều có thể đối chiếu giữa request-level metric và trạng thái runtime của service, queue hoặc database.

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nội dung*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Cách kiểm tra*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Kết quả quan sát*],
    table.cell(inset: (y: 0.6em))[Service boundary],
    table.cell(inset: (y: 0.6em))[Đối chiếu test theo từng service],
    table.cell(inset: (
      y: 0.6em,
    ))[Test được tách theo identity, project, ingest, analysis, knowledge, notification và crawler],
    table.cell(inset: (y: 0.6em))[Request observability],
    table.cell(inset: (y: 0.6em))[Thu request metrics và status summary],
    table.cell(inset: (y: 0.6em))[Có p50/p95/p99, throughput, timeout và infra error],
    table.cell(inset: (y: 0.6em))[Runtime observability],
    table.cell(inset: (y: 0.6em))[Thu cluster, queue, DB snapshot và log],
    table.cell(inset: (y: 0.6em))[Có bằng chứng pod state, queue/backlog, database state và runtime apply],
  )
]


== 6.6 Đối chiếu tổng hợp với yêu cầu và kiến trúc

#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Yêu cầu / thiết kế*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Bằng chứng kiểm chứng*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Mức đánh giá*],
    table.cell(inset: (y: 0.6em))[FR-01 Xác thực người dùng],
    table.cell(inset: (y: 0.6em))[Unit test identity-srv, endpoint validate 200],
    table.cell(inset: (y: 0.6em))[Đạt trong phạm vi token/internal auth],
    table.cell(inset: (y: 0.6em))[FR-02 Campaign/project],
    table.cell(inset: (y: 0.6em))[Campaign CRUD 8/8, project CRUD/lifecycle 12/12, unit test project-srv],
    table.cell(inset: (y: 0.6em))[Đạt],
    table.cell(inset: (y: 0.6em))[FR-03 Lifecycle],
    table.cell(inset: (y: 0.6em))[Readiness, activate rejection hợp lệ, archive/unarchive, runtime apply],
    table.cell(inset: (y: 0.6em))[Đạt trong kịch bản đã chạy],
    table.cell(inset: (y: 0.6em))[FR-04 Crisis config],
    table.cell(inset: (y: 0.6em))[Crisis config CRUD 3/3, crisis assessment, runtime apply],
    table.cell(inset: (y: 0.6em))[Đạt],
    table.cell(inset: (y: 0.6em))[FR-05 Datasource],
    table.cell(inset: (
      y: 0.6em,
    ))[Datasource CRUD 6/6, ingest-srv datasource package đạt statement coverage ở package được đo],
    table.cell(inset: (y: 0.6em))[Đạt],
    table.cell(inset: (y: 0.6em))[FR-06 Target],
    table.cell(inset: (
      y: 0.6em,
    ))[Target keyword/profile/post, list/detail/update/deactivate/delete, ingest-srv use case test],
    table.cell(inset: (y: 0.6em))[Đạt trong kịch bản đã chạy],
    table.cell(inset: (y: 0.6em))[FR-07 Dry run],
    table.cell(inset: (
      y: 0.6em,
    ))[Dry run package đạt statement coverage ở package được đo, dry run history, cơ chế `IsDryrunRequired`],
    table.cell(inset: (y: 0.6em))[Đạt trong phạm vi mapping được kiểm chứng],
    table.cell(inset: (y: 0.6em))[FR-08 Điều phối crawl],
    table.cell(inset: (
      y: 0.6em,
    ))[Crawler task scenario, RabbitMQ lane, UAP Kafka package đạt statement coverage ở package được đo],
    table.cell(inset: (y: 0.6em))[Đạt trong kịch bản đã chạy],
    table.cell(inset: (y: 0.6em))[FR-09 Analytics],
    table.cell(inset: (y: 0.6em))[analysis-srv 309 tests pass],
    table.cell(inset: (y: 0.6em))[Đạt],
    table.cell(inset: (y: 0.6em))[FR-10 Search/chat],
    table.cell(inset: (y: 0.6em))[Search 1/1 pass, chat 5/5 pass],
    table.cell(inset: (y: 0.6em))[Đạt ở mức endpoint/contract],
    table.cell(inset: (y: 0.6em))[FR-11 Notification],
    table.cell(inset: (y: 0.6em))[notification-srv unit test, Redis delivery, WebSocket route yêu cầu xác thực],
    table.cell(inset: (y: 0.6em))[Đạt trong phạm vi delivery và routing],
    table.cell(inset: (y: 0.6em))[FR-12 Internal interop],
    table.cell(inset: (y: 0.6em))[Internal validate, internal project lookup, project service client test],
    table.cell(inset: (y: 0.6em))[Đạt trong luồng đã kiểm chứng],
  )
]


#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: 3,
    stroke: 0.5pt,
    align: (left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Lane kiến trúc Chương 5*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Test tương ứng*],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Nhận xét*],
    table.cell(inset: (y: 0.6em))[Internal HTTP control plane],
    table.cell(inset: (y: 0.6em))[identity-srv, project-srv, ingest-srv, knowledge-srv],
    table.cell(inset: (y: 0.6em))[Có bằng chứng tốt ở API/control flow],
    table.cell(inset: (y: 0.6em))[RabbitMQ crawl runtime],
    table.cell(inset: (y: 0.6em))[ingest-srv dry run RabbitMQ packages, crawler task scenario],
    table.cell(inset: (y: 0.6em))[Có bằng chứng module và task scenario],
    table.cell(inset: (y: 0.6em))[Kafka analytics data plane],
    table.cell(inset: (y: 0.6em))[UAP Kafka package, analysis output contract, shared Kafka helper],
    table.cell(inset: (y: 0.6em))[Có bằng chứng tốt ở module],
    table.cell(inset: (y: 0.6em))[Redis notification ingress],
    table.cell(inset: (y: 0.6em))[notification-srv Redis delivery, miniredis-based test],
    table.cell(inset: (y: 0.6em))[Có bằng chứng unit test],
    table.cell(inset: (y: 0.6em))[Qdrant knowledge layer],
    table.cell(inset: (y: 0.6em))[Search/chat, index statistics],
    table.cell(inset: (y: 0.6em))[Có bằng chứng endpoint và nghiệm thu chức năng],
    table.cell(inset: (y: 0.6em))[PostgreSQL/Redis/MinIO state],
    table.cell(inset: (y: 0.6em))[Repository tests, database evidence, runtime state snapshot],
    table.cell(inset: (y: 0.6em))[Có bằng chứng theo module và scenario],
  )
]


== 6.7 Phạm vi diễn giải kết quả

Các kết quả trong chương này được diễn giải theo đúng phạm vi đã đo. Kiểm thử đầu cuối và NFR dùng các campaign/project cụ thể trong môi trường K3s tham chiếu, vì vậy kết luận tập trung vào những luồng và trạng thái đã có bằng chứng trực tiếp. Với các tổ hợp dữ liệu, platform hoặc rule chưa nằm trong kịch bản, hệ thống cần được mở rộng thêm test case khi đưa vào vận hành thực tế.

Các chỉ số performance hiện tại phản ánh API-lane trong cửa sổ workload 12-20 phút. Những chỉ số vận hành dài hạn như MTTR chuẩn hóa, backlog drain time theo nhiều dạng chaos, saturation threshold theo replica và soak nhiều giờ nên được tiếp tục đo trong các đợt kiểm thử vận hành sau.

Đối với notification, báo cáo đã có bằng chứng unit test cho WebSocket/Redis delivery và route WebSocket qua gateway yêu cầu xác thực. Kiểm thử hai chiều bằng WebSocket client đầy đủ nên được bổ sung khi cần chốt thêm số liệu về độ trễ và độ ổn định kết nối thời gian thực.

== 6.8 Kết luận

Kết quả kiểm thử cho thấy các luồng thuộc phạm vi đồ án đã được nghiệm thu chức năng theo tầng xử lý: delivery, use case, repository, model, transport hoặc runtime boundary. Các bằng chứng ở mục 6.3 cho thấy các package/nhóm test được liệt kê của identity-srv, project-srv, ingest-srv, notification-srv, analysis-srv, shared-libs, knowledge-srv, crawler worker và smap-analyse đều pass trong lần chạy này. Với ingest-srv, báo cáo unit test trích nguyên văn cho thấy 15 package thuộc datasource, dry run, execution và UAP đều pass và đạt 100.0% statement coverage ở các package được đo.

Đối với yêu cầu chức năng, các luồng chính như campaign/project, datasource/target, activation, search/chat/report, crisis runtime apply, crawler task và notification delivery đều có bằng chứng kiểm thử cụ thể ở mức API, UI hoặc runtime state. Đối với yêu cầu phi chức năng, các kịch bản NFR cho thấy API-lane duy trì p95 dưới 225 ms trong các scenario đã chạy, throughput nằm trong khoảng 6.949-7.751 req/s. Nhìn chung, hệ thống đã được kiểm chứng theo đúng ranh giới service và kiến trúc microservices đã thiết kế; các chỉ số vận hành dài hạn có thể tiếp tục được mở rộng trong các đợt đo sau.
