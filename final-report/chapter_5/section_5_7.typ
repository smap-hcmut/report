// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.7 Thiết kế triển khai hệ thống

Phần này trình bày thiết kế triển khai hệ thống SMAP lên môi trường production, bao gồm kiến trúc hạ tầng, mô hình container hóa, quy trình CI/CD và các chiến lược đảm bảo tính sẵn sàng cao của hệ thống.

=== 5.7.1 Mô hình triển khai

Hệ thống SMAP được triển khai theo mô hình Kubernetes-based Microservices Architecture, trong đó các services được đóng gói thành containers và orchestrate bởi Kubernetes cluster. Mô hình này cho phép scale từng service độc lập, đảm bảo fault tolerance và hỗ trợ rolling updates không gây downtime.

#align(center)[
  #image("../images/deploy/deployment-diagram.drawio.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Sơ đồ triển khai hệ thống SMAP_])
  #image_counter.step()
]

Kiến trúc triển khai được tổ chức thành các tầng sau:

- Tầng Ingress: NGINX Ingress Controller đóng vai trò load balancer và reverse proxy, xử lý TLS termination và routing requests đến các services tương ứng.

- Tầng Frontend: Web UI được triển khai dưới dạng Next.js application với Server-Side Rendering, phục vụ giao diện người dùng và gọi API đến backend services.

- Tầng Backend Services: Các microservices được triển khai độc lập bao gồm Identity Service, Project Service, Collector Service, Analytics Service và WebSocket Service.

- Tầng Workers: Các background workers xử lý tác vụ bất đồng bộ như TikTok Scraper, YouTube Scraper và Analytics Consumer.

- Tầng Infrastructure: Các dịch vụ hạ tầng bao gồm PostgreSQL cho lưu trữ dữ liệu quan hệ, Redis cho caching và pub/sub, RabbitMQ cho message queue và MinIO cho object storage.

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
- Ingress Controller: NGINX Ingress Controller
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
    table.cell(align: center + horizon, inset: (y: 0.8em))[8000-8081],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Application services communication],
    table.cell(align: center + horizon, inset: (y: 0.8em))[5432, 6379, 5672],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Internal],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Database và infrastructure services],
  )
]

TLS certificates được quản lý tự động bởi cert-manager với Let's Encrypt, đảm bảo tất cả traffic đều được mã hóa HTTPS.

=== 5.7.4 Container Registry và Image Management

Hệ thống sử dụng Harbor Registry làm private container registry để lưu trữ và quản lý Docker images. Quy ước đặt tên image tuân theo format:

```
registry.tantai.dev/smap/{service-name}:{timestamp}
```

Ví dụ các images trong hệ thống:

- registry.tantai.dev/smap/smap-identity:241215-143022
- registry.tantai.dev/smap/smap-project:241215-143022
- registry.tantai.dev/smap/smap-collector:241215-143022
- registry.tantai.dev/smap/smap-analytics-api:241215-143022
- registry.tantai.dev/smap/smap-websocket:241215-143022
- registry.tantai.dev/smap/smap-web-ui:241215-143022

Mỗi service được build bằng multi-stage Dockerfile để tối ưu kích thước image. Go services sử dụng scratch base image với binary compiled, trong khi Python services sử dụng slim base image với dependencies được cài đặt qua pip.

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

Mỗi service được triển khai với Kubernetes Deployment và Service resources. Cấu hình bao gồm:

- Replicas: Số lượng pod replicas để đảm bảo high availability. Frontend và backend services chạy 3 replicas, workers chạy 2 replicas.

- Resource Limits: Giới hạn CPU và memory cho mỗi container để tránh resource contention.

- Health Checks: Liveness probe và readiness probe để Kubernetes tự động restart unhealthy pods và chỉ route traffic đến healthy pods.

- Environment Variables: Cấu hình được inject qua ConfigMaps và Secrets, không hardcode trong image.

#context (align(center)[_Bảng #table_counter.display(): Cấu hình Resource Limits cho các services_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.30fr, 0.15fr, 0.20fr, 0.20fr, 0.15fr),
    stroke: 0.5pt,
    align: (left, center, center, center, center),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Service*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Replicas*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*CPU Request*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Memory Request*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Memory Limit*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Web UI],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[256Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[512Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Identity Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[128Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[256Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Project Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[128Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[256Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Collector Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[200m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[256Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[512Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics API],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[200m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[512Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1Gi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Analytics Consumer],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2],
    table.cell(align: center + horizon, inset: (y: 0.8em))[1000m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[2Gi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[4Gi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Service],
    table.cell(align: center + horizon, inset: (y: 0.8em))[3],
    table.cell(align: center + horizon, inset: (y: 0.8em))[100m],
    table.cell(align: center + horizon, inset: (y: 0.8em))[128Mi],
    table.cell(align: center + horizon, inset: (y: 0.8em))[256Mi],
  )
]

=== 5.7.7 Infrastructure Services

Các dịch vụ hạ tầng được triển khai với cấu hình đảm bảo data persistence và high availability:

- PostgreSQL: Triển khai dưới dạng StatefulSet với Persistent Volume Claims để lưu trữ dữ liệu. Mỗi service có database riêng biệt để đảm bảo isolation.

- Redis: Sử dụng cho caching và pub/sub messaging giữa các services. Cấu hình với password authentication và persistent storage.

- RabbitMQ: Message queue cluster với 3 nodes để đảm bảo high availability. Hỗ trợ message persistence và automatic failover.

- MinIO: Object storage cho lưu trữ raw data từ crawlers và export files. Cấu hình với bucket policies và access control.

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


