// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.7 Thiết kế triển khai hệ thống

Phần này trình bày thiết kế triển khai hệ thống SMAP lên môi trường production, bao gồm kiến trúc hạ tầng, mô hình container hóa, quy trình CI/CD và các chiến lược đảm bảo tính sẵn sàng cao của hệ thống.

=== 5.7.1 Mô hình triển khai

Hệ thống SMAP được triển khai theo mô hình Kubernetes-based Microservices Architecture, trong đó các services được đóng gói thành containers và orchestrate bởi Kubernetes cluster. Ở góc nhìn triển khai, các trách nhiệm API, scheduler, consumer và worker được tách thành các pod riêng khi cần, giúp mỗi workload có vòng đời scale, restart và rollout độc lập hơn.

#align(center)[
  #image("../images/deploy/deployment-diagram-current.excalidraw.svg", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Sơ đồ triển khai hệ thống SMAP_])
  #image_counter.step()
]

Kiến trúc triển khai được tổ chức thành các tầng sau:

- Tầng Ingress: Traefik Gateway đóng vai trò load balancer và reverse proxy, xử lý TLS termination và routing requests đến các services tương ứng.

- Tầng Frontend: `web-ui` được triển khai như một pod giao diện và backend-for-frontend, phục vụ giao diện người dùng và gọi API đến backend services.

- Tầng API Pods: Các pod phục vụ HTTP hoặc WebSocket bao gồm `identity-api`, `project-api`, `ingest-api`, `knowledge-api`, `notification-delivery` và `scapper-api`.

- Tầng Runtime Pods: Các pod nền bao gồm `identity-audit-consumer`, `project-consumer`, `ingest-scheduler`, `ingest-completion-consumer`, `analysis-consumer`, `knowledge-consumer` và `scapper-worker`.

- Tầng Infrastructure: Các dịch vụ hạ tầng bao gồm PostgreSQL cho lưu trữ dữ liệu quan hệ, Redis cho caching và pub/sub, RabbitMQ cho task queue, Kafka cho analytics data plane, MinIO cho object storage và Qdrant cho vector retrieval.

=== 5.7.2 Cấu hình phần cứng và phần mềm

Kubernetes cluster được thiết kế với cấu hình phần cứng phù hợp cho workload của hệ thống SMAP.

#context (align(center)[_Bảng #table_counter.display(): Cấu hình phần cứng Kubernetes Cluster_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.20fr, 0.15fr, 0.15fr, 0.25fr),
    stroke: 0.5pt,
    align: (left, center, center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Loại Node*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Số lượng*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*CPU*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*RAM*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Storage*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Master Nodes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4 cores],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100GB SSD],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Worker Nodes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8 cores],
    table.cell(align: center + horizon, inset: (y: 0.8em))[16GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[200GB SSD],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AI/ML Nodes],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[16 cores],
    table.cell(align: center + horizon, inset: (y: 0.8em))[32GB],
    table.cell(align: center + horizon, inset: (y: 0.8em))[500GB SSD],
  )
]

Phần mềm được sử dụng trong môi trường triển khai bao gồm:

- Hệ điều hành: Ubuntu 20.04 LTS
- Container Runtime: Docker 24.0 trở lên
- Kubernetes: phiên bản 1.28 trở lên
- Ingress Gateway: Traefik
- Container Registry: Harbor Registry tại registry.tantai.dev

=== 5.7.3 Cấu hình mạng và bảo mật

Hệ thống được cấu hình với domain smap-api.tantai.dev cho production environment. Các quy tắc firewall được thiết lập để đảm bảo an toàn cho hệ thống.

#context (align(center)[_Bảng #table_counter.display(): Cấu hình Firewall Rules_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.20fr, 0.25fr, 0.55fr),
    stroke: 0.5pt,
    align: (center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Port*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Phạm vi*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Mô tả*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[80, 443],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Public],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP và HTTPS traffic từ internet],
    table.cell(align: center + horizon, inset: (y: 0.8em))[22],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Restricted IPs],
    table.cell(align: center + horizon, inset: (y: 0.8em))[SSH access cho quản trị viên],
    table.cell(align: center + horizon, inset: (y: 0.8em))[6443],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kubernetes API Server],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3000, 8080, 8081, 8082, 8105],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API pods và WebSocket delivery surface],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5432, 6379, 5672, 9092/9094, 9000-9001, 6333-6334],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database, object storage, streaming và message infrastructure],
  )
]

TLS certificates được quản lý tự động bởi cert-manager với Let's Encrypt, đảm bảo tất cả traffic đều được mã hóa HTTPS.

=== 5.7.4 Container Registry và Image Management

Hệ thống sử dụng Harbor Registry làm private container registry để lưu trữ và quản lý Docker images. Quy ước đặt tên image tuân theo format:

```
registry.tantai.dev/smap/{service-name}:{timestamp}
```

Ví dụ các images trong hệ thống:

- registry.tantai.dev/smap/identity-srv:241215-143022
- registry.tantai.dev/smap/project-srv:241215-143022
- registry.tantai.dev/smap/ingest-srv:241215-143022
- registry.tantai.dev/smap/knowledge-srv:241215-143022
- registry.tantai.dev/smap/notification-srv:241215-143022
- registry.tantai.dev/smap/analysis-consumer:241215-143022
- registry.tantai.dev/smap/scapper-srv:241215-143022
- registry.tantai.dev/smap/smap-ui:241215-143022

Mỗi service được build bằng multi-stage Dockerfile để tối ưu kích thước image. Các Go services sử dụng runtime distroless sau giai đoạn biên dịch binary, trong khi các Python services chủ yếu sử dụng slim base image với dependencies được cài đặt qua pip.

=== 5.7.5 CI/CD Pipeline

Quy trình CI/CD được tự động hóa thông qua GitHub Actions với các stages chính:

- Detect Changes: Xác định các services có thay đổi code để chỉ build và deploy những services cần thiết.

- Build and Test: Chạy unit tests và build Docker images cho các services có thay đổi.

- Deploy Staging: Tự động deploy lên môi trường staging khi merge vào branch develop.

- Deploy Production: Deploy lên production khi merge vào branch main với approval từ team lead.

#context (align(center)[_Bảng #table_counter.display(): Cấu hình môi trường triển khai_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.25fr, 0.25fr, 0.50fr),
    stroke: 0.5pt,
    align: (center, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Môi trường*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Namespace*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Đặc điểm*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Development],
    table.cell(align: center + horizon, inset: (y: 0.8em))[smap-dev],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Debug enabled, mock services, local testing],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Staging],
    table.cell(align: center + horizon, inset: (y: 0.8em))[smap-staging],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Production-like, load testing, QA validation],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Production],
    table.cell(align: center + horizon, inset: (y: 0.8em))[smap],
    table.cell(align: center + horizon, inset: (y: 0.8em))[High availability, monitoring, auto-scaling],
  )
]

=== 5.7.6 Cấu hình Kubernetes Deployments

Các workload trong hệ thống được triển khai thành các Deployment riêng theo pod role thay vì gộp toàn bộ trách nhiệm của một service vào một pod duy nhất. Cách tách này đặc biệt quan trọng với các service vừa có API vừa có consumer hoặc scheduler, vì chúng có nhịp tải, dependency surface và vòng đời rollout khác nhau.

Các nguyên tắc triển khai chính gồm:

- Pod Role Separation: API pod, scheduler pod, consumer pod và worker pod được tách riêng khi cùng thuộc một service boundary.
- Health Checks: Các pod có HTTP surface sử dụng liveness probe và readiness probe; các consumer hoặc worker pod có thể dùng probe theo tiến trình hoặc theo runtime contract phù hợp.
- Environment Variables: Cấu hình được inject qua ConfigMaps và Secrets, không hardcode trong image.
- Independent Scaling: API pods ưu tiên ổn định request path, trong khi consumer hoặc worker pods có thể scale theo queue depth, topic load hoặc throughput của lane tương ứng.

#context (align(center)[_Bảng #table_counter.display(): Pod deployment matrix trong kiến trúc triển khai_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.21fr, 0.18fr, 0.33fr, 0.12fr, 0.16fr),
    stroke: 0.5pt,
    align: (left, left, left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Runtime pod*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thuộc service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Vai trò*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Port*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Ghi chú*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[web-ui],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web UI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Frontend/BFF],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3000],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Nhận traffic từ gateway và proxy browser requests],

    table.cell(align: center + horizon, inset: (y: 0.8em))[identity-api],
    table.cell(align: center + horizon, inset: (y: 0.8em))[identity-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Auth, session và internal validation API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8080],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP surface của security boundary],

    table.cell(align: center + horizon, inset: (y: 0.8em))[identity-audit-consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[identity-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka audit consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pod nền cho audit logging],

    table.cell(align: center + horizon, inset: (y: 0.8em))[project-api],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Campaign, project, lifecycle và crisis API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8082],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Business control plane API],

    table.cell(align: center + horizon, inset: (y: 0.8em))[project-consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[project-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka lifecycle hoặc event consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Background pod theo event lane],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-api],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Datasource, target, dry run và lifecycle API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8081],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP surface của execution ingress lane],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-scheduler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Scheduled crawl và heartbeat dispatch],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Tách riêng để scale và restart độc lập với API],

    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-completion-consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ingest-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ completion consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Nhận completion cho execution và dry run lanes],

    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[analysis-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka analytics pipeline consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[CPU-heavy analytics runtime pod],

    table.cell(align: center + horizon, inset: (y: 0.8em))[knowledge-api],
    table.cell(align: center + horizon, inset: (y: 0.8em))[knowledge-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Search, chat, report và indexing control API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8080],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP surface cho retrieval và report capability],

    table.cell(align: center + horizon, inset: (y: 0.8em))[knowledge-consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[knowledge-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka downstream indexing consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Background pod cho indexing lane],

    table.cell(align: center + horizon, inset: (y: 0.8em))[notification-delivery],
    table.cell(align: center + horizon, inset: (y: 0.8em))[notification-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket/API và Redis Pub/Sub delivery],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8081],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Giữ subscriber cùng pod delivery vì phụ thuộc in-memory WebSocket hub],

    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-worker],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ crawl worker],
    table.cell(align: center + horizon, inset: (y: 0.8em))[N/A],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Thực thi crawl task và materialize raw artifact],

    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-api],
    table.cell(align: center + horizon, inset: (y: 0.8em))[scapper-srv],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Auxiliary submit, result và health API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[8105],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pod hỗ trợ cho thao tác vận hành hoặc kiểm tra cục bộ],
  )
]

Các pod có HTTP surface thường được publish qua `Service` ổn định để gateway route traffic. Ngược lại, consumer, scheduler và worker pods chủ yếu giao tiếp với RabbitMQ, Kafka, Redis hoặc storage backend, nên không cần cổng ứng dụng công khai trừ khi workload đó chọn expose health hoặc metrics theo một contract riêng.

=== 5.7.7 Infrastructure Services

Các dịch vụ hạ tầng được triển khai với cấu hình đảm bảo data persistence và high availability:

- PostgreSQL: Triển khai dưới dạng StatefulSet với Persistent Volume Claims để lưu trữ dữ liệu. Mỗi service có database riêng biệt để đảm bảo isolation.

- Redis: Sử dụng cho caching và pub/sub messaging giữa các services. Cấu hình với password authentication và persistent storage.

- RabbitMQ: Message queue cluster với 3 nodes để đảm bảo high availability. Hỗ trợ message persistence và automatic failover.

- Kafka: Streaming backbone cho analytics data plane, downstream indexing và các consumer runtime bất đồng bộ.

- MinIO: Object storage cho lưu trữ raw data từ crawlers và export files. Cấu hình với bucket policies và access control.

- Qdrant: Vector store phục vụ semantic retrieval và indexing lane của Knowledge Service.

=== 5.7.8 Monitoring và Logging

Hệ thống monitoring được thiết lập với Prometheus để thu thập metrics và Grafana để visualization. Các metrics quan trọng được theo dõi bao gồm:

- HTTP request rate và latency
- Error rate theo service và endpoint
- Resource utilization của pods
- Message queue depth và processing rate
- Database connection pool status

Logging được centralize thông qua Fluentd, thu thập logs từ tất cả containers và forward đến Elasticsearch. Mỗi service sử dụng structured logging với các fields chuẩn như service name, request ID, timestamp và log level.

=== 5.7.9 Backup và Disaster Recovery

Chiến lược backup được thiết lập để đảm bảo khả năng phục hồi dữ liệu:

- Database Backup: CronJob chạy hàng ngày lúc 2:00 AM để backup PostgreSQL databases. Backup files được nén và upload lên MinIO với retention policy 30 ngày.

- Configuration Backup: Kubernetes configurations được export và lưu trữ định kỳ, cho phép restore toàn bộ cluster trong trường hợp disaster.

- Rollback Strategy: Kubernetes hỗ trợ rollback deployment về revision trước đó trong trường hợp phát hiện lỗi sau khi deploy. Automated rollback được trigger khi error rate vượt ngưỡng cho phép.

=== 5.7.10 Quy trình triển khai

Quy trình triển khai một phiên bản mới của hệ thống tuân theo các bước sau:

1. Developer push code lên branch feature và tạo Pull Request.

2. CI pipeline tự động chạy tests và build Docker images.

3. Sau khi PR được approve và merge vào develop, hệ thống tự động deploy lên staging.

4. QA team thực hiện testing trên staging environment.

5. Khi staging được approve, merge vào main để trigger production deployment.

6. Production deployment sử dụng rolling update strategy, đảm bảo zero downtime.

7. Monitoring alerts được theo dõi trong 30 phút sau deployment để phát hiện issues.

8. Nếu phát hiện lỗi, thực hiện rollback về version trước đó.
