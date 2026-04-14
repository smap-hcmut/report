# CHAPTER 1: INTRODUCTION

## 1.1 Context & Motivation

### 1.1.1 Lớp lý thuyết

Trong bối cảnh chuyển đổi số, dữ liệu mạng xã hội không còn chỉ đóng vai trò truyền thông mà đã trở thành một nguồn dữ liệu chiến lược cho hoạt động marketing, nghiên cứu thị trường và quản trị rủi ro thương hiệu. Khối lượng thảo luận trực tuyến tăng nhanh, tính đa dạng của nền tảng ngày càng lớn, trong khi chu kỳ phản ứng của doanh nghiệp đối với khủng hoảng truyền thông ngày càng ngắn. Vì vậy, một hệ thống social listening hiện đại cần thỏa đồng thời ba điều kiện: khả năng thu thập dữ liệu liên tục, năng lực phân tích ngữ nghĩa đủ sâu, và khả năng chuyển hóa dữ liệu thành tri thức có thể hành động.

Các nền tảng social intelligence thế hệ mới thường không dừng ở việc thu thập bài viết và hiển thị biểu đồ. Chúng còn phải hỗ trợ phân tích ý định, cảm xúc, xu hướng, chủ đề nổi bật, phát hiện tín hiệu bất thường, và cung cấp cơ chế hỏi đáp hoặc báo cáo tự động. Điều này dẫn tới nhu cầu kiến trúc đa tầng, trong đó lớp ingestion, lớp analytics và lớp knowledge được phân tách rõ ràng để phục vụ các mục tiêu khác nhau.

### 1.1.2 Lớp phân tích trên dự án SMAP

Workspace SMAP phản ánh trực tiếp bối cảnh trên. Tài liệu `../tong-quan.md` xác định SMAP là `Social Media Analytics Platform` với định hướng social listening, market intelligence, crisis detection, dashboarding, reporting và RAG. Về mặt mã nguồn, hệ thống đã được tách thành nhiều service độc lập như `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv` và `notification-srv`. Việc phân tách này cho thấy bài toán của hệ thống không còn là một ứng dụng CRUD đơn giản, mà là một chuỗi xử lý nhiều pha kéo dài từ business context đến retrieval-augmented knowledge.

Động lực thực tế của dự án còn được thể hiện qua cấu trúc công nghệ. `analysis-srv` sử dụng một tập phụ thuộc NLP/ML khá nặng như `torch`, `transformers`, `spacy`, `yake`, `polars`, trong khi `knowledge-srv` sử dụng Qdrant, Gemini, Voyage AI và Maestro để phục vụ vector search, RAG và notebook synchronization. Điều này cho thấy hệ thống được xây dựng nhằm giải quyết không chỉ vấn đề thu thập dữ liệu, mà còn cả vấn đề giải thích và tái sử dụng tri thức từ dữ liệu đó.

### 1.1.3 Lớp minh họa từ mã nguồn

Các bằng chứng mã nguồn nổi bật cho bối cảnh và động lực của hệ thống bao gồm:

- `../analysis-srv/pyproject.toml:25-43` xác nhận hệ thống đã tích hợp stack NLP/ML thực tế, bao gồm PyTorch, Transformers, Optimum ONNX Runtime, SpaCy, YAKE, Polars, Datasketch và Prometheus client.
- `../knowledge-srv/go.mod:14-24` xác nhận lớp knowledge sử dụng Qdrant, Redis, gRPC và Sarama, cho thấy định hướng retrieval và indexing là một phần hiện thực hóa thật sự chứ không chỉ tồn tại ở mức ý tưởng.
- `../notification-srv/go.mod:6-12` cho thấy hệ thống đã tích hợp Gorilla WebSocket và Redis Pub/Sub, phù hợp với nhu cầu phản hồi thời gian thực.

## 1.2 Problem Statement

### 1.2.1 Lớp lý thuyết

Một hệ thống social listening truyền thống thường gặp ít nhất ba nhóm hạn chế. Thứ nhất là hạn chế về tích hợp nguồn dữ liệu: dữ liệu từ các nền tảng khác nhau có định dạng dị biệt, gây khó khăn cho xử lý downstream. Thứ hai là hạn chế về hiệu năng và mở rộng: nếu toàn bộ logic được đặt trong một ứng dụng đồng nhất, việc scale cho crawl, NLP và API sẽ trở nên kém hiệu quả. Thứ ba là hạn chế về khả năng hành động: dashboard đơn thuần không đủ giúp người dùng phản ứng nhanh với khủng hoảng hoặc truy vấn insight theo ngữ cảnh.

### 1.2.2 Lớp phân tích trên dự án SMAP

Từ current codebase, có thể xác định ba khó khăn thực tế mà SMAP đang giải quyết.

Khó khăn thứ nhất là bài toán chuẩn hóa dữ liệu đầu vào. `ingest-srv` phải quản lý `data_sources`, `crawl_targets`, `external_tasks`, `raw_batches` và cuối cùng chuẩn hóa dữ liệu thành UAP trước khi chuyển cho `analysis-srv`. Điều này cho thấy raw data từ crawler chưa thể được phân tích trực tiếp mà cần một lớp chuẩn hóa trung gian.

Khó khăn thứ hai là bài toán xử lý bất đồng bộ nhiều giai đoạn. `analysis-srv` không chỉ chạy một mô hình sentiment đơn lẻ mà là một pipeline nhiều pha. Lớp analytics vì thế cần tách khỏi API/control plane để tránh coupling giữa thời gian phản hồi HTTP và thời gian xử lý NLP.

Khó khăn thứ ba là bài toán chuyển từ dữ liệu sang tri thức có thể sử dụng. Sự tồn tại của `knowledge-srv` chứng minh rằng kết quả analytics không đủ nếu chỉ lưu trong database quan hệ; hệ thống cần một lớp indexing và retrieval riêng để tạo semantic search, RAG chat và report generation.

### 1.2.3 Lớp minh họa từ mã nguồn

- Bài toán chuẩn hóa đầu vào được hiện thực tại `../ingest-srv/internal/datasource/usecase/datasource_lifecycle.go` thông qua các hàm `ActivateDataSource`, `PauseDataSource`, `ResumeDataSource`, `UpdateCrawlMode`, và được nối tiếp sang luồng UAP publishing ở lane ingest runtime.
- Bài toán xử lý bất đồng bộ nhiều pha được hiện thực tại `../analysis-srv/internal/consumer/server.py` thông qua lớp `ConsumerServer` và hàm `_handle_message`, kết hợp với `../analysis-srv/internal/pipeline/usecase/usecase.py` thông qua hàm `run`.
- Bài toán semantic retrieval được hiện thực tại `../knowledge-srv/internal/search/usecase/search.go` thông qua hàm `Search`, kết hợp với `../knowledge-srv/pkg/qdrant/qdrant.go` qua các hàm `Search` và `SearchWithFilter`.

Table 1.1 summarizes the main problem groups addressed by the system and explains why each group matters from an engineering perspective.

| Problem Group | Mô tả | Tác động nếu không giải quyết |
| --- | --- | --- |
| Heterogeneous social data | Dữ liệu từ nhiều nền tảng có cấu trúc và metadata khác nhau | downstream analytics khó chuẩn hóa và khó tái sử dụng |
| Multi-stage asynchronous processing | NLP, enrichment và reporting không thể gói gọn trong request-response đơn giản | hiệu năng hệ thống suy giảm, khó scale độc lập từng workload |
| Actionable knowledge generation | Dữ liệu và insight thô chưa đủ để hỗ trợ ra quyết định | dashboard không đủ sâu cho search, chat, report và crisis response |

## 1.3 Objectives

### 1.3.1 Main Goals

Mục tiêu chính của hệ thống là xây dựng một nền tảng social media analytics có khả năng thu thập dữ liệu đa nguồn, chuẩn hóa và phân tích dữ liệu bằng pipeline AI/NLP, đồng thời chuyển hóa kết quả phân tích thành lớp tri thức phục vụ dashboard, search, reporting và cảnh báo thời gian thực.

### 1.3.2 Specific Goals

Các mục tiêu cụ thể được xác định như sau:

- hiện thực lớp quản lý business context và project lifecycle
- hiện thực lớp ingest runtime có khả năng điều phối crawl và chuẩn hóa dữ liệu thành UAP
- hiện thực analytics pipeline bất đồng bộ với nhiều giai đoạn xử lý NLP
- hiện thực knowledge layer dựa trên vector search và RAG
- hiện thực notification layer cho WebSocket và Discord alerts
- đảm bảo hệ thống có thể được triển khai bằng container và một phần workload có thể chạy trên Kubernetes

Table 1.2 maps the thesis objectives to the technical directions observable in the current codebase.

| Objective Type | Objective | Kết nối với mã nguồn |
| --- | --- | --- |
| Main Goal | xây dựng nền tảng social media analytics nhiều lớp | sự tồn tại của `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv` |
| Specific Goal | quản lý business context và project lifecycle | `project-srv/internal/project/*`, `internal/campaign/*`, `internal/crisis/*` |
| Specific Goal | điều phối ingest runtime và chuẩn hóa UAP | `ingest-srv/internal/datasource/*`, `internal/dryrun/*`, `internal/uap/*` |
| Specific Goal | xử lý analytics bất đồng bộ | `analysis-srv/internal/consumer/*`, `internal/pipeline/*`, `internal/analytics/*` |
| Specific Goal | xây dựng knowledge layer cho search và chat | `knowledge-srv/internal/search/*`, `internal/chat/*`, `internal/indexing/*` |
| Specific Goal | cung cấp notification thời gian thực | `notification-srv/internal/websocket/*`, `internal/alert/*` |

## 1.4 Scope of Work

### 1.4.1 Phạm vi thực hiện

Các module có bằng chứng rõ trong mã nguồn và được xem là nằm trong phạm vi của luận văn gồm:

- `identity-srv`: xác thực và phân quyền
- `project-srv`: quản lý project và business metadata
- `ingest-srv`: quản lý datasource, lifecycle ingest, crawl runtime, UAP publishing
- `analysis-srv`: NLP/analytics pipeline
- `knowledge-srv`: search, RAG, indexing, report generation
- `notification-srv`: realtime notification và Discord alerts
- `scapper-srv`: crawler worker runtime
- `shared-libs`: thư viện dùng chung cho Go và Python

### 1.4.2 Ngoài phạm vi xác nhận

Các phần sau hiện chưa có đủ bằng chứng trong workspace để mô tả chi tiết như một phần chắc chắn của hệ thống:

- frontend framework cụ thể
- CI/CD pipeline cụ thể
- production topology đầy đủ của toàn bộ platform ở mức cluster-wide

Table 1.3 classifies the thesis scope into confirmed in-scope areas and items currently outside direct source-code verification.

| Phân loại | Nội dung |
| --- | --- |
| In scope | backend services, messaging, storage, runtime lifecycle, analytics, knowledge, notification |
| In scope | Docker / Docker Compose / Kubernetes manifests có mặt trong repo |
| Out of direct verification scope | frontend framework và UI implementation details |
| Out of direct verification scope | CI/CD tooling cụ thể |
| Out of direct verification scope | benchmark định lượng production-scale đầy đủ |

## 1.5 Methodology

### 1.5.1 Lớp lý thuyết

Trong phát triển phần mềm, phương pháp lặp gia tăng thường phù hợp hơn với các hệ thống nhiều thành phần, đặc biệt khi domain và hạ tầng thay đổi trong quá trình hiện thực. Phương pháp này cho phép hệ thống được xây dựng theo từng increment: hoàn thiện một lane kỹ thuật, kiểm thử, đo đạc, sau đó mới mở rộng sang lane tiếp theo.

### 1.5.2 Lớp phân tích trên dự án SMAP

Workspace hiện tại không chứa bằng chứng trực tiếp của sprint board, issue workflow hoặc tài liệu process chính thức, vì vậy không thể khẳng định chắc chắn rằng toàn dự án đang dùng Scrum đầy đủ. Tuy nhiên, từ cấu trúc nhiều service, sự tồn tại của nhiều README cập nhật, contract docs, gap notes và các deployment/test manifests riêng, có thể nhận thấy hệ thống được phát triển theo hướng lặp gia tăng và theo module.

Cách hiện thực này phù hợp với bản chất của SMAP. Các lane như authentication, crawl runtime, analytics pipeline và knowledge indexing có thể được phát triển tương đối độc lập, rồi ghép lại qua contract boundaries. Do đó, trong luận văn, phương pháp phát triển sẽ được mô tả là iterative and incremental development với định hướng Agile, nhưng kèm lưu ý rằng đây là kết luận ở mức suy diễn thận trọng từ cấu trúc mã nguồn chứ không phải từ artifact quản trị dự án.

### 1.5.3 Lớp minh họa từ mã nguồn

Các dấu hiệu ủng hộ nhận định này gồm:

- `../analysis-srv/manifests/hpa.yaml` và `../analysis-srv/apps/consumer/deployment.yaml` cho thấy workload analytics được triển khai và scale độc lập.
- `../project-srv/docker-compose.yml` và `../ingest-srv/docker-compose.yml` cho thấy từng service có local stack riêng, phù hợp với tiến trình phát triển module hóa.
- các tài liệu như `../3-event-contracts.md` và `../document/gap/007_reporting_execution_and_transport_contract_mismatch.md` cho thấy nhóm phát triển liên tục hiệu chỉnh contract và đối chiếu lại kiến trúc theo quá trình triển khai.

Table 1.4 summarizes the development methodology interpretation used in this thesis.

| Khía cạnh | Quan sát từ repo | Diễn giải trong luận văn |
| --- | --- | --- |
| Service isolation | nhiều service có manifest và Dockerfile riêng | phát triển lặp gia tăng theo module |
| Contract evolution | có contract docs và gap notes | thiết kế được hiệu chỉnh dần qua các vòng triển khai |
| Deployment separation | analytics có Deployment và HPA riêng | workload được tách để kiểm thử và vận hành độc lập |

## 1.6 Thesis Organization

Luận văn được tổ chức thành bảy chương.

Chương 1 giới thiệu bối cảnh, bài toán, mục tiêu, phạm vi và phương pháp thực hiện. Chương 2 trình bày nền tảng lý thuyết và danh sách công nghệ thực tế được xác nhận từ mã nguồn. Chương 3 phân tích yêu cầu hệ thống, use cases và quy trình nghiệp vụ. Chương 4 mô tả thiết kế hệ thống, bao gồm kiến trúc tổng thể, cơ sở dữ liệu, module, sequence diagrams và API design. Chương 5 đi sâu vào hiện thực hóa, giải thích cách các tính năng lõi được cài đặt trong source code thực tế. Chương 6 đánh giá và kiểm thử. Cuối cùng, Chương 7 tổng kết kết quả, hạn chế và hướng phát triển tiếp theo.

Table 1.5 outlines the role of each chapter in the overall logic of the thesis.

| Chapter | Vai trò |
| --- | --- |
| Chapter 1 | đặt bối cảnh, bài toán, mục tiêu và phạm vi |
| Chapter 2 | xây dựng nền tảng lý thuyết và công nghệ |
| Chapter 3 | phân tích yêu cầu và quy trình nghiệp vụ |
| Chapter 4 | chuyển yêu cầu thành thiết kế hệ thống |
| Chapter 5 | đối chiếu thiết kế với hiện thực hóa từ source code |
| Chapter 6 | đánh giá, kiểm thử và chỉ ra mức độ bao phủ |
| Chapter 7 | tổng kết mức độ hoàn thành, hạn chế và hướng phát triển |
