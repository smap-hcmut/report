# CHAPTER 2: THEORETICAL BACKGROUND & TECHNOLOGIES

## 2.1 Domain Knowledge

### 2.1.1 Lớp lý thuyết

Trong hệ thống social media analytics, một số thuật ngữ nghiệp vụ xuất hiện lặp lại và có vai trò định hình thiết kế kiến trúc. `Campaign` thường được hiểu là lớp grouping ở mức business, dùng để gom nhiều hoạt động theo một chủ đề hoặc mục tiêu chung. `Project` là đơn vị monitoring cụ thể hơn, mang business metadata đủ rõ để hệ thống biết mình đang theo dõi đối tượng nào. `Datasource` là kết nối tới nguồn dữ liệu, còn `CrawlTarget` là đầu vào cụ thể cho việc thu thập như keyword, profile hoặc post URL. `CrisisConfig` là tập điều kiện hoặc ngưỡng dùng để đánh giá khi nào một project chuyển sang trạng thái khủng hoảng.

Ngoài ra, trong hệ thống phân tích nhiều lớp, khái niệm payload chuẩn hóa là rất quan trọng. Một canonical payload giúp downstream pipeline không phụ thuộc vào sự khác biệt của raw platform-specific formats. Điều này vừa làm giảm coupling, vừa giúp kiểm soát chất lượng dữ liệu tốt hơn.

### 2.1.2 Lớp phân tích trên dự án SMAP

Trong SMAP, các thuật ngữ nghiệp vụ trên không chỉ xuất hiện ở mức tài liệu mà còn được phản ánh trong cấu trúc service boundaries. `project-srv` là service nắm business semantics của `project`, `campaign`, brand metadata và lifecycle mức nghiệp vụ. `ingest-srv` lại là nơi nắm `data_source`, `crawl_target`, `scheduled_job`, `external_task`, `raw_batch`. Điều này cho thấy nhóm phát triển đã tách business layer khỏi execution layer ở mức kiến trúc, thay vì để tất cả thực thể sống chung trong một service.

`UAP` là canonical payload của lane ingest-to-analysis. Đây là một khái niệm kỹ thuật nhưng có tác động trực tiếp đến domain vì nó mang theo các trường như `project_id`, `domain_type_code`, `crawl_keyword` và `platform`, từ đó giữ được ngữ cảnh nghiệp vụ trong analytics pipeline.

### 2.1.3 Lớp minh họa từ mã nguồn

- Business context được mô tả trong `../tong-quan.md`, nơi `Campaign`, `Project`, `Datasource`, `CrawlTarget` và `CrisisConfig` được định nghĩa như các lớp khái niệm cốt lõi.
- Ownership boundary của execution layer được thể hiện trong `../ingest-srv/README.md`, phần entity chính và ownership rules.
- Canonical analytics input được chốt ở `../3-event-contracts.md`, nhóm `3.3 Ingest -> Analysis`, với topic `smap.collector.output` và payload UAP tối thiểu.

Table 2.1 provides a compact glossary of the most important domain terms used throughout the thesis.

| Thuật ngữ | Nghĩa trong SMAP |
| --- | --- |
| Campaign | nhóm ngữ cảnh kinh doanh bao gồm nhiều project |
| Project | đơn vị theo dõi cụ thể, gắn với brand/entity/domain |
| Datasource | nguồn dữ liệu phục vụ ingest runtime |
| CrawlTarget | đầu vào cụ thể cho crawl như keyword, profile hoặc post |
| UAP | canonical payload giữa ingest và analytics |
| CrisisConfig | cấu hình ngưỡng và luật đánh giá trạng thái khủng hoảng |

## 2.2 Architectural Patterns

### 2.2.1 Monolithic vs Microservices

#### Lớp lý thuyết

Monolithic architecture tập trung toàn bộ business logic, persistence, delivery và background processing vào một application unit duy nhất. Ưu điểm của mô hình này là đơn giản trong giai đoạn đầu, dễ triển khai và ít chi phí phối hợp giữa các thành phần. Tuy nhiên, khi hệ thống phải xử lý nhiều loại workload khác nhau, monolith thường gặp giới hạn về scale, cô lập lỗi và tốc độ thay đổi từng phần.

Microservices architecture chia hệ thống thành nhiều service độc lập theo bounded contexts. Mỗi service có thể được phát triển, triển khai và scale tương đối độc lập. Đổi lại, hệ thống phải chấp nhận chi phí cao hơn về distributed communication, contract management, tracing và operational complexity.

#### Lớp phân tích trên dự án SMAP

SMAP rõ ràng nghiêng về microservices chứ không phải monolith. Điều này không chỉ thể hiện ở số lượng thư mục service, mà còn ở việc mỗi service có `go.mod` hoặc `pyproject.toml` riêng, README riêng, Dockerfile riêng và local/deployment config riêng. Bài toán của SMAP cũng là loại bài toán ít phù hợp với monolith: API CRUD, OAuth2, crawl runtime, NLP pipeline, vector indexing và notification realtime có các đặc tính tải rất khác nhau.

Ví dụ, `analysis-srv` cần runtime Python với dependency ML nặng và có thể scale theo CPU-bound batch processing. Trong khi đó, `identity-srv` và `project-srv` là API-oriented Go services với profile tài nguyên khác hẳn. Nếu hai loại workload này bị đặt chung vào một monolith, việc tối ưu triển khai và scale sẽ trở nên kém hiệu quả.

#### Lớp minh họa từ mã nguồn

- `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` chứng minh mỗi Go service là một module độc lập.
- `../analysis-srv/pyproject.toml` và `../scapper-srv/requirements.txt` chứng minh analytics và crawler runtime dùng Python độc lập với Go services.
- `../analysis-srv/apps/consumer/deployment.yaml` chứng minh ít nhất analytics consumer đã được đóng gói như một workload riêng có thể deploy độc lập.

Table 2.2 compares monolithic and microservice styles in the context of the current SMAP codebase.

| Tiêu chí | Monolithic | Microservices trong SMAP |
| --- | --- | --- |
| Deployment unit | một artifact lớn | nhiều service với Dockerfile và manifest riêng |
| Runtime specialization | hạn chế | Go cho API/control, Python cho analytics/crawler |
| Scaling | scale đồng loạt | scale theo workload, ví dụ analytics consumer có HPA |
| Boundary ownership | dễ mờ | campaign/project, ingest, analytics, knowledge tách rõ hơn |

### 2.2.2 Event-Driven Architecture

#### Lớp lý thuyết

Event-Driven Architecture là phong cách kiến trúc trong đó các thành phần giao tiếp qua event hoặc message bất đồng bộ thay vì phụ thuộc vào lời gọi đồng bộ trực tiếp ở mọi nơi. Phong cách này phù hợp với các bài toán có thời gian xử lý kéo dài, throughput cao, hoặc cần fanout tới nhiều downstream consumers.

Tuy nhiên, một điểm quan trọng là không phải mọi hệ thống có message broker đều là event-driven ở mọi lane. Một kiến trúc thực tế thường dùng kết hợp cả control plane đồng bộ và data plane bất đồng bộ, tùy vào tính chất từng loại tương tác.

#### Lớp phân tích trên dự án SMAP

SMAP là ví dụ điển hình của cách phân tách cơ chế truyền thông theo từng loại luồng xử lý. Hệ thống hiện tại không dùng một cơ chế giao tiếp duy nhất cho mọi luồng. `project-srv -> ingest-srv` hiện nghiêng về internal HTTP cho lifecycle/control plane. `ingest-srv <-> scapper-srv` dùng RabbitMQ cho task queue. `ingest-srv -> analysis-srv -> knowledge-srv` dùng Kafka như analytics data plane. `notification-srv` lại ingest message từ Redis Pub/Sub.

Việc lựa chọn như vậy là hợp lý. Internal HTTP thuận lợi cho control semantics và phản hồi nhanh. RabbitMQ phù hợp với work queue và completion correlation theo `task_id`. Kafka phù hợp với streaming analytics outputs và downstream fanout. Redis Pub/Sub phù hợp cho realtime ingress nhẹ. Điều này cho thấy SMAP không áp dụng event-driven như một khẩu hiệu chung chung, mà áp dụng có chọn lọc theo lane.

#### Lớp minh họa từ mã nguồn

- `../ingest-srv/go.mod:13` xác nhận RabbitMQ client `amqp091-go` được dùng trong ingest runtime.
- `../analysis-srv/pyproject.toml:10` xác nhận `aiokafka` được dùng cho analytics pipeline.
- `../notification-srv/go.mod:8` xác nhận `redis/go-redis/v9` được dùng trong notification ingress.
- `../document/gap/007_reporting_execution_and_transport_contract_mismatch.md` chỉ ra rõ current transport mix và cảnh báo việc hiểu sai report cũ.

Table 2.3 compares the communication mechanisms that coexist in the current architecture.

| Cơ chế | Vai trò trong SMAP | Bằng chứng |
| --- | --- | --- |
| Internal HTTP | control plane giữa business và execution layers | route files + gap doc |
| RabbitMQ | crawl tasks và completion metadata | `ingest-srv/go.mod`, `scapper-srv/RABBITMQ.md` |
| Kafka | analytics data plane | `analysis-srv/pyproject.toml`, `analysis-srv/README.md` |
| Redis Pub/Sub | notification ingress và cache | `notification-srv/documents/contracts.md`, `knowledge-srv/go.mod` |

## 2.3 Backend Technologies

### 2.3.1 Go backend stack

#### Lớp lý thuyết

Gin là một HTTP web framework phổ biến trong hệ sinh thái Go, thường được chọn nhờ tốc độ xử lý tốt, middleware model rõ ràng và chi phí runtime thấp. Viper thường được dùng để quản lý cấu hình đa nguồn, bao gồm file cấu hình và biến môi trường. SQLBoiler là công cụ sinh mã ORM theo schema quan hệ, giúp tạo typed models và queries mà vẫn giữ style tương đối gần với SQL.

#### Lớp phân tích trên dự án SMAP

Các Go services trong SMAP dùng một stack tương đối nhất quán gồm Gin, Viper, SQLBoiler và Swagger tooling. Sự nhất quán này giúp giảm cognitive load khi có nhiều service, đồng thời cho phép tái sử dụng shared-libs cho tracing, auth, Redis, RabbitMQ, Kafka và cron. Đối với một hệ nhiều bounded contexts, đây là lựa chọn hợp lý vì đội ngũ có thể giữ đồng nhất delivery conventions, config style và observability practices.

#### Lớp minh họa từ mã nguồn

- `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` đều xác nhận `gin-gonic/gin`.
- `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod` xác nhận `viper` và `sqlboiler`.
- Tính năng xác thực OAuth2 được hiện thực tại `../identity-srv/internal/authentication/delivery/http/oauth.go` thông qua các hàm `OAuthLogin` và `OAuthCallback`.
- Tính năng lấy thông tin người dùng hiện tại và logout được hiện thực tại `../identity-srv/internal/authentication/delivery/http/handlers.go` thông qua `GetMe` và `Logout`.

### 2.3.2 Python backend stack

#### Lớp lý thuyết

Python thường được lựa chọn cho analytics workloads do hệ sinh thái ML/NLP mạnh và phong phú. Trong các hệ thống cần xử lý bất đồng bộ, thư viện như `aiokafka` và `aio-pika` cho phép xây dựng consumer và queue worker theo mô hình async tương đối linh hoạt. Khi kết hợp với SQLAlchemy, asyncpg, MinIO SDK và Redis client, Python có thể đảm nhiệm cả pipeline dữ liệu lẫn kết nối hạ tầng.

#### Lớp phân tích trên dự án SMAP

Trong SMAP, Python không được dùng cho toàn bộ backend mà được dùng chọn lọc cho hai lane chính. `analysis-srv` dùng Python vì cần stack NLP/ML phức tạp, trong khi `scapper-srv` dùng Python cho crawler worker và FastAPI debug/runtime API. Điều này phản ánh một quyết định kiến trúc hợp lý: chỉ đưa Python vào những nơi lợi ích từ ecosystem ML hoặc SDK vượt trội hơn chi phí runtime.

#### Lớp minh họa từ mã nguồn

- `../analysis-srv/pyproject.toml` xác nhận `aiokafka`, `aio-pika`, `sqlalchemy`, `asyncpg`, `minio`, `torch`, `transformers`, `spacy`, `yake`, `polars`, `pydantic`.
- `../scapper-srv/requirements.txt` xác nhận `fastapi`, `uvicorn`, `aio-pika`, `aioboto3`, `loguru`.
- Tính năng consume và xử lý message Kafka được hiện thực tại `../analysis-srv/internal/consumer/server.py` qua lớp `ConsumerServer` và hàm `_handle_message`.
- Tính năng chạy pipeline analytics được hiện thực tại `../analysis-srv/internal/pipeline/usecase/usecase.py` qua hàm `run`.
- Tính năng NLP batch enrichment được hiện thực tại `../analysis-srv/internal/analytics/usecase/batch_enricher.py` qua hàm `enrich_batch`.

### 2.3.3 Cơ chế authentication

#### Lớp lý thuyết

Một hệ thống đa dịch vụ thường cần tách identity provider khỏi business services. OAuth2 được dùng để xác thực người dùng với bên thứ ba, sau đó hệ thống phát JWT nội bộ để các service downstream có thể xác thực request mà không cần round-trip về identity provider ở mọi lần gọi.

#### Lớp phân tích trên dự án SMAP

SMAP sử dụng Google OAuth2 ở `identity-srv`, sau đó phát JWT HS256 và lưu token trong cookie `smap_auth_token`. Thiết kế này phù hợp với mô hình web app, nơi trình duyệt có thể tự động gửi cookie tới backend. Đồng thời, các service khác như `project-srv` và `notification-srv` có thể xác thực dựa trên JWT hoặc shared internal key mà không trực tiếp xử lý OAuth2 flow.

#### Lớp minh họa từ mã nguồn

- Flow OAuth2 được hiện thực tại `../identity-srv/internal/authentication/delivery/http/oauth.go` qua `OAuthLogin` và `OAuthCallback`.
- Session được tạo tại `../identity-srv/internal/authentication/usecase/util.go` qua hàm `createSession`, và trong `../identity-srv/internal/authentication/usecase/session.go` qua `CreateSession`.
- Cấu hình JWT, cookie và access control nằm tại `../identity-srv/config/auth-config.yaml:54-105`.
- Notification WebSocket yêu cầu JWT qua cookie hoặc query param, được mô tả tại `../notification-srv/documents/contracts.md:10-24` và handler tại `../notification-srv/internal/websocket/delivery/http/handlers.go` qua `HandleWebSocket`.

Table 2.4 summarizes the backend technology stack by service boundary.

| Service | Ngôn ngữ / framework | Vai trò kỹ thuật chính |
| --- | --- | --- |
| `identity-srv` | Go + Gin + OAuth2 + JWT | xác thực, session, token validation |
| `project-srv` | Go + Gin + SQLBoiler | campaign/project/crisis config |
| `ingest-srv` | Go + Gin + RabbitMQ + Kafka | datasource lifecycle, dry run, UAP publishing |
| `analysis-srv` | Python + aiokafka + SQLAlchemy + NLP stack | analytics pipeline bất đồng bộ |
| `knowledge-srv` | Go + Gin + Qdrant + LLM clients | search, chat, indexing, notebook |
| `notification-srv` | Go + Gin + WebSocket + Redis | realtime delivery và Discord alerting |
| `scapper-srv` | Python + FastAPI + aio-pika | crawl worker runtime |

Table 2.5 summarizes the authentication components confirmed in the source code.

| Thành phần | Công nghệ / cơ chế | Bằng chứng |
| --- | --- | --- |
| External authentication | Google OAuth2 | `identity-srv/internal/authentication/delivery/http/oauth.go` |
| Internal token | JWT HS256 | `identity-srv/config/auth-config.yaml` |
| Session / blacklist | Redis-backed session manager | `identity-srv/internal/authentication/usecase/util.go`, config file |
| Browser auth transport | HttpOnly cookie | `identity-srv/config/auth-config.yaml`, notification contracts |
| Internal service validation | shared internal key | `identity-srv/config/auth-config.yaml`, internal routes |

## 2.4 Frontend Technologies

### 2.4.1 Lớp lý thuyết

Trong một luận văn phần mềm, frontend technologies thường bao gồm framework UI, cơ chế rendering, state management và kết nối tới backend. Tuy nhiên, để tuân thủ nguyên tắc bằng chứng mã nguồn, những công nghệ này chỉ nên được khẳng định khi xuất hiện trong `package.json` hoặc cấu trúc source frontend tương ứng.

### 2.4.2 Lớp phân tích trên dự án SMAP

Tại thời điểm khảo sát workspace hiện tại, không tìm thấy `package.json` nào trong toàn bộ thư mục dự án. Do đó, không có đủ bằng chứng để khẳng định hệ thống đang dùng React, Next.js, Vue, CSR, SSR hay state management cụ thể nào.

Điều này không có nghĩa là hệ thống không có frontend, mà chỉ có nghĩa rằng frontend source code không hiện diện trong phạm vi workspace đang được phân tích. Vì vậy, Chương 2 chỉ có thể ghi nhận frontend là một external client role hoặc dashboard consumer, thay vì mô tả stack kỹ thuật cụ thể.

### 2.4.3 Lớp minh họa từ mã nguồn

- Kết quả quét `**/package.json` trong workspace không trả về file nào.
- `../notification-srv/README.md` và `../notification-srv/documents/contracts.md` chỉ xác nhận sự tồn tại của browser dashboards và WebSocket clients, không xác nhận frontend implementation stack.

## 2.5 Database & Storage

### 2.5.1 Lớp lý thuyết

RDBMS như PostgreSQL phù hợp với dữ liệu có cấu trúc rõ, cần transaction và ràng buộc toàn vẹn. Redis phù hợp với cache, session hoặc pub/sub do đặc tính truy cập nhanh và in-memory. Object storage như MinIO phù hợp với file lớn hoặc raw payload. Vector database như Qdrant phù hợp với semantic retrieval, khi dữ liệu đã được chuyển thành embedding vectors.

### 2.5.2 Lớp phân tích trên dự án SMAP

SMAP không dùng một cơ chế lưu trữ duy nhất, mà áp dụng persistence specialization. PostgreSQL được dùng cho dữ liệu nghiệp vụ và metadata. Redis được dùng cho session, blacklist, cache và notification ingress. MinIO được dùng cho raw artifacts và report artifacts. Qdrant được dùng trong knowledge layer để lưu vector index.

Lựa chọn này phù hợp với đặc thù của hệ thống. Raw crawl data không nên bị nhét hết vào queue hoặc bảng quan hệ. Search layer không nên chỉ dựa vào relational queries nếu hệ thống hướng tới semantic retrieval. Ngược lại, các thực thể nghiệp vụ như project, datasource hay audit log vẫn cần relational consistency của PostgreSQL.

### 2.5.3 Lớp minh họa từ mã nguồn

- PostgreSQL local stack được mô tả tại `../project-srv/docker-compose.yml:3-27` và `../ingest-srv/docker-compose.yml:12-36`.
- Redis local stack được mô tả tại `../project-srv/docker-compose.yml:29-50` và `../ingest-srv/docker-compose.yml:38-57`.
- MinIO được hiện thực trong hạ tầng ingest tại `../ingest-srv/docker-compose.yml:59-98`.
- Qdrant được cấu hình tại `../knowledge-srv/config/knowledge-config.yaml:16-20` và được truy cập qua `../knowledge-srv/pkg/qdrant/qdrant.go` bằng các hàm `Search`, `SearchWithFilter`, `SearchBatch`.

Table 2.6 classifies the storage technologies by data role in the current system.

| Công nghệ | Loại dữ liệu chính | Vai trò |
| --- | --- | --- |
| PostgreSQL | business metadata, runtime records, analytics facts | relational persistence và toàn vẹn dữ liệu |
| Redis | session, cache, pub/sub messages | truy cập nhanh và giao tiếp thời gian thực |
| MinIO | raw artifacts, report artifacts | object storage và claim-check |
| Qdrant | embeddings và vector index | semantic retrieval |

## 2.6 Infrastructure & DevOps

### 2.6.1 Lớp lý thuyết

Trong các hệ thống đa dịch vụ, Docker được dùng để đóng gói từng service thành artifact có thể triển khai lặp lại. Docker Compose thường được dùng cho môi trường local hoặc integration testing. Kubernetes phù hợp khi hệ thống cần scale workload độc lập, triển khai rolling update và dùng health probes. HPA là cơ chế tự động co giãn pod dựa trên metric như CPU hoặc memory.

### 2.6.2 Lớp phân tích trên dự án SMAP

Workspace hiện tại có bằng chứng mạnh cho containerization và một phần orchestration. Mỗi service chính đều có Dockerfile riêng. `project-srv` và `ingest-srv` có local Docker Compose stacks. `analysis-srv` có deployment manifest và HPA, cho thấy ít nhất analytics consumer đã được thiết kế như một Kubernetes workload có thể scale.

Điểm cần nhấn mạnh là CI/CD pipeline cụ thể chưa thể xác nhận vì không tìm thấy workflow files trong workspace. Do đó, phần DevOps của luận văn chỉ nên khẳng định Docker, Docker Compose, Kubernetes Deployment và HPA; còn pipeline CI/CD nên được ghi là chưa có đủ bằng chứng trực tiếp.

### 2.6.3 Lớp minh họa từ mã nguồn

- Dockerfiles hiện diện tại các service server/consumer, ví dụ `../analysis-srv/apps/consumer/Dockerfile`, `../scapper-srv/Dockerfile`, `../identity-srv/cmd/server/Dockerfile`.
- Local infra stack của project service được mô tả trong `../project-srv/docker-compose.yml` với PostgreSQL, Redis, Zookeeper, Kafka và dev UIs.
- Local infra stack của ingest service được mô tả trong `../ingest-srv/docker-compose.yml` với PostgreSQL, Redis, MinIO, Kafka và RabbitMQ.
- Kubernetes Deployment được hiện thực tại `../analysis-srv/apps/consumer/deployment.yaml`.
- HorizontalPodAutoscaler được hiện thực tại `../analysis-srv/manifests/hpa.yaml`.

Table 2.7 summarizes the infrastructure and deployment technologies that can be confirmed directly from the repository.

| Thành phần | Công nghệ / hiện vật | Bằng chứng |
| --- | --- | --- |
| Container artifact | Dockerfile theo service | Dockerfiles của các service |
| Local multi-service stack | Docker Compose | `project-srv/docker-compose.yml`, `ingest-srv/docker-compose.yml` |
| Orchestration | Kubernetes Deployment | `analysis-srv/apps/consumer/deployment.yaml` |
| Auto scaling | HorizontalPodAutoscaler | `analysis-srv/manifests/hpa.yaml` |
| Registry-style deployment | Harbor image reference | `analysis-srv/apps/consumer/deployment.yaml` |

## 2.7 Kết luận chương

Chương này cho thấy SMAP là một hệ thống backend-centric, đa dịch vụ, dùng song song Go và Python để tối ưu cho các loại workload khác nhau. Các công nghệ quan trọng như PostgreSQL, Redis, Kafka, RabbitMQ, MinIO, Qdrant, Gin, FastAPI, OAuth2, JWT, Docker và Kubernetes đều có bằng chứng trực tiếp từ mã nguồn. Ngược lại, frontend stack và CI/CD pipeline cụ thể chưa được xác nhận trong phạm vi workspace hiện tại, nên sẽ không được mô tả như một fact trong các chương tiếp theo.
