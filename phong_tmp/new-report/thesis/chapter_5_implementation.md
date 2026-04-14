# CHAPTER 5: IMPLEMENTATION

## 5.1 Development Environment

### 5.1.1 Lớp lý thuyết

Môi trường phát triển của một hệ thống đa dịch vụ cần hỗ trợ đồng thời nhiều runtime, nhiều loại dependency hạ tầng và nhiều kiểu artifact triển khai. Khi backend được chia thành nhiều service và sử dụng hơn một ngôn ngữ lập trình, môi trường phát triển không chỉ là máy tính cài IDE, mà còn phải bao gồm local infrastructure stack, trình quản lý dependency, container runtime và bộ công cụ kiểm thử tương ứng.

Một môi trường tốt phải thỏa ba điều kiện. Thứ nhất, tái lập được các dependency chính của hệ thống ở local hoặc test environment. Thứ hai, cho phép tách riêng từng service để phát triển hoặc kiểm thử độc lập. Thứ ba, phản ánh tương đối trung thực deployment model ở production hoặc staging, ít nhất ở mức workload separation và dependency contracts.

### 5.1.2 Lớp phân tích trên dự án SMAP

Workspace SMAP hiện tại cho thấy một môi trường phát triển đa runtime, gồm Go và Python. Mỗi service có manifest dependency riêng, ví dụ `go.mod` hoặc `pyproject.toml`, cùng Dockerfile riêng để đóng gói artifact. Về local infrastructure, `project-srv` và `ingest-srv` có Docker Compose stacks riêng. `analysis-srv` có Kafka E2E environment riêng để phục vụ integration tests. Điều này chứng tỏ môi trường phát triển của dự án được tổ chức theo hướng service-oriented thay vì “chạy tất cả bằng một lệnh duy nhất”.

Từ các file cấu hình hiện có, có thể suy ra môi trường phát triển tối thiểu cần các thành phần sau: Go 1.25.x, Python 3.12+, PostgreSQL, Redis, Kafka, RabbitMQ, MinIO, Docker và ít nhất một số manifest Kubernetes để phản ánh cách analytics workload được triển khai. Đồng thời, việc có `deployment.yaml` và `hpa.yaml` trong `analysis-srv` cho thấy đội ngũ đã không dừng ở local-only development mà có suy nghĩ rõ về deployment trên môi trường orchestrated.

### 5.1.3 Lớp minh họa từ mã nguồn

| Thành phần | Bằng chứng |
| --- | --- |
| Go runtime | `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` |
| Python runtime | `../analysis-srv/pyproject.toml`, `../smap-analyse/pyproject.toml` |
| Local infra cho project | `../project-srv/docker-compose.yml` |
| Local infra cho ingest | `../ingest-srv/docker-compose.yml` |
| Kafka E2E test infra | `../analysis-srv/docker-compose.e2e.yml` |
| Kubernetes deployment | `../analysis-srv/apps/consumer/deployment.yaml` |
| Autoscaling | `../analysis-srv/manifests/hpa.yaml` |

### 5.1.4 Bảng toolchain phát triển

| Thành phần | Công nghệ xác nhận | Vai trò |
| --- | --- | --- |
| Backend Go | Go `1.25.x` | identity, project, ingest, knowledge, notification |
| Backend Python | Python `>=3.12` | analytics pipeline, crawler runtime, shared libs |
| API framework | Gin, FastAPI | HTTP/WebSocket APIs và worker debug API |
| DB / broker local | PostgreSQL, Redis, Kafka, RabbitMQ, MinIO | local integration và runtime phụ trợ |
| Container | Docker, Docker Compose | đóng gói và dựng local stack |
| Orchestration | Kubernetes Deployment, HPA | analytics consumer runtime |
| Test tooling | pytest, pytest-asyncio, testcontainers, testify | unit, e2e và integration tests |

## 5.2 Project Structure

### 5.2.1 Lớp lý thuyết

Project structure của một hệ thống đa dịch vụ cần được giải thích ở hai lớp: lớp workspace và lớp service. Ở lớp workspace, cần chỉ rõ đây là monorepo thực sự hay chỉ là một multi-service workspace. Ở lớp service, cần giải thích cách source code được chia thành các package hoặc module delivery, usecase, repository và infrastructure.

Giải thích project structure là bước rất quan trọng trong luận văn vì nó cho người đọc cái nhìn thực tế về cách nhóm phát triển tổ chức mã nguồn. Một sơ đồ kiến trúc đẹp sẽ không đủ giá trị nếu không thể nối với cấu trúc thư mục cụ thể trong repository.

### 5.2.2 Lớp phân tích trên dự án SMAP

Ở cấp workspace, SMAP hiện tại không phải là một root monorepo có Git repository chung cho toàn bộ hệ thống, mà là một tập hợp nhiều service và thư viện dùng chung đặt cạnh nhau. Những thư mục trọng tâm gồm `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`, `scapper-srv`, `shared-libs` và `smap-analyse`. Cách tổ chức này phù hợp với một hệ thống đang được chia bounded context mạnh, nhưng cũng tạo thêm chi phí về đồng bộ tài liệu và versioning ở cấp toàn nền tảng.

Ở cấp service, có thể thấy một mô hình tổ chức khá nhất quán. Các Go service thường có `cmd/`, `internal/`, `config/`, `migration/` hoặc `migrations/`, `docs/` và Dockerfile riêng. Python services như `analysis-srv` có `apps/consumer`, `internal/`, `pkg/`, `config/`, `tests/`, `scripts/`, `migration/` và `manifests/`. Điều này cho thấy một định hướng tổ chức source code thiên về domain modules và separation of concerns, thay vì đặt mọi thứ trong một cây file phẳng.

### 5.2.3 Bảng giải thích cấu trúc thư mục

| Thư mục | Ý nghĩa |
| --- | --- |
| `identity-srv/` | Service xác thực và phân quyền |
| `project-srv/` | Service quản lý project, campaign và cấu hình nghiệp vụ |
| `ingest-srv/` | Service quản lý datasource, runtime ingest và UAP publishing |
| `analysis-srv/` | Service xử lý analytics pipeline bằng Python |
| `knowledge-srv/` | Service indexing, search, chat và reporting |
| `notification-srv/` | Service WebSocket và Discord notification |
| `scapper-srv/` | Worker runtime cho crawl tasks |
| `shared-libs/` | Thư viện dùng chung cho Go và Python |
| `smap-analyse/` | Nested repo liên quan đến core pipeline / service wrapping |

### 5.2.4 Lớp minh họa từ mã nguồn

#### Cấu trúc `analysis-srv`

README của `analysis-srv` mô tả khá đầy đủ cây thư mục, cho thấy:

- `apps/consumer/` là entry point runtime
- `internal/consumer/` là consumer layer
- `internal/pipeline/` là pipeline orchestrator
- `internal/analytics/` là NLP batch enricher
- `pkg/` chứa adapter cho Kafka, MinIO, PostgreSQL, Redis, PhoBERT ONNX, SpaCy/YAKE
- `migration/` chứa schema SQL cho analytics persistence

#### Cấu trúc `ingest-srv`

README của `ingest-srv` xác định các module cốt lõi:

- `internal/datasource`
- `internal/dryrun`
- `internal/crawler`
- `internal/parser`
- `internal/scheduler`
- `internal/projectsync`
- `internal/httpserver`

Điều này cho thấy ingest layer được chia theo capability vận hành, không chỉ theo CRUD table.

#### Cấu trúc `scapper-srv`

Trong trạng thái source hiện tại, `scapper-srv` nên được hiểu như một dịch vụ FastAPI có worker RabbitMQ chạy kèm trong vòng đời ứng dụng, thay vì một worker độc lập tách hoàn toàn khỏi lớp API. File `../scapper-srv/app/main.py` cho thấy `FastAPI` được khởi tạo với `lifespan`, trong đó đối tượng `Worker` được gọi `start()` ở giai đoạn startup và `stop()` ở giai đoạn shutdown. Điều này có nghĩa là entry point tiêu biểu nhất của service hiện nay là `app/main.py`.

Chi tiết này quan trọng đối với luận văn vì nó thay đổi cách mô tả runtime boundary của service. `app/worker.py` vẫn là nơi chứa logic worker cốt lõi, nhưng về mặt tổ chức triển khai, service hiện đã hợp nhất API surface, health endpoints và worker bootstrap vào cùng một application lifecycle. Do đó, khi mô tả kiến trúc hiện thực ở Chương 5, `app/main.py` là điểm đại diện chính xác hơn cho current implementation.

### 5.2.5 Bảng entry point và artifact triển khai

| Service | Entry point chính | Artifact runtime | Bằng chứng |
| --- | --- | --- | --- |
| `identity-srv` | `cmd/server/main.go` | Docker image từ `cmd/server/Dockerfile` | source tree + Dockerfile |
| `project-srv` | `cmd/server/main.go` | Docker image và local compose stack | source tree + `docker-compose.yml` |
| `ingest-srv` | `cmd/server/main.go` | Docker image và local compose stack | source tree + `docker-compose.yml` |
| `analysis-srv` | `apps/consumer/main.py` | Docker image, Deployment, HPA | source tree + manifests |
| `knowledge-srv` | `cmd/server/main.go` | Docker image | source tree + Dockerfile |
| `notification-srv` | `cmd/server/main.go` | Docker image | source tree + Dockerfile |
| `scapper-srv` | `app/main.py` | Docker image | source tree + Dockerfile |

## 5.3 Core Feature Implementation

Phần này tập trung vào sáu tính năng khó và quan trọng nhất của hệ thống, được chọn dựa trên hai tiêu chí: có độ phức tạp kỹ thuật cao và có bằng chứng hiện thực rõ trong mã nguồn.

### 5.3.1 Tính năng 1: OAuth2 login và session management

#### Lớp lý thuyết

Trong các hệ thống web hiện đại, xác thực qua OAuth2 giúp tận dụng identity provider bên ngoài, giảm chi phí quản lý mật khẩu nội bộ. Tuy nhiên, sau khi xác thực thành công, hệ thống vẫn cần một cơ chế phiên làm việc nội bộ để kiểm soát quyền truy cập và duy trì trạng thái giữa các request. JWT và session store thường được kết hợp để vừa giữ tính stateless ở tầng token, vừa cho phép thu hồi phiên hoặc quản lý blacklist khi cần.

#### Lớp phân tích trên dự án SMAP

SMAP hiện thực luồng này trong `identity-srv`. Ở lớp delivery, handler `OAuthLogin` xử lý request và chuyển người dùng sang provider. Sau khi provider gọi callback, `OAuthCallback` gọi usecase để đổi code lấy token và hoàn tất phiên làm việc. Một điểm đáng chú ý là hệ thống hỗ trợ hai mode: development mode có thể trả token trong JSON response để dễ test, còn production mode thiết lập HttpOnly cookie và redirect.

Việc tạo session không bị nhúng trực tiếp trong handler mà được tách ở usecase layer thông qua `createSession`. Cách làm này có hai ưu điểm. Thứ nhất, business logic xác thực không bị buộc chặt vào một delivery protocol cụ thể. Thứ hai, session strategy có thể thay đổi ở tầng usecase/session manager mà không phá handler layer.

#### Lớp minh họa từ mã nguồn

Tính năng này được hiện thực tại file `../identity-srv/internal/authentication/delivery/http/oauth.go` thông qua các hàm `OAuthLogin` và `OAuthCallback`. Logic tạo token và tạo session được nối tới `../identity-srv/internal/authentication/usecase/util.go` thông qua hàm `createSession`.

Code snippet tiêu biểu:

```go
func (h handler) OAuthLogin(c *gin.Context) {
    ctx := c.Request.Context()
    input := h.processLoginRequest(c)
    output, err := h.uc.InitiateOAuthLogin(ctx, input)
    if err != nil {
        response.Error(c, h.mapError(err), h.discord)
        return
    }
    h.setStateCookie(c, output.State)
    c.Redirect(http.StatusTemporaryRedirect, output.AuthURL)
}
```

```go
func (u *ImplUsecase) createSession(ctx context.Context, userID, jti string, rememberMe bool) error {
    if u.sessionManager == nil {
        return nil
    }
    return u.sessionManager.CreateSession(ctx, userID, jti, rememberMe)
}
```

### 5.3.2 Tính năng 2: Project persistence và metadata management

#### Lớp lý thuyết

Project metadata là hạt nhân ngữ cảnh của toàn hệ thống social analytics. Nếu project không giữ đúng các trường như brand, entity type, entity name hoặc domain type code, downstream analytics rất khó phân tích đúng ngữ nghĩa của dữ liệu. Do đó, logic tạo project không nên chỉ là một thao tác insert CRUD cơ bản, mà phải đảm bảo business metadata cốt lõi được thiết lập đầy đủ ngay từ đầu.

#### Lớp phân tích trên dự án SMAP

Trong `project-srv`, repository PostgreSQL chịu trách nhiệm ghi project vào bảng `project.projects`. Hàm `Create` cho thấy khi một project mới được tạo, nhiều thuộc tính quan trọng được thiết lập ngay tại thời điểm insert như `campaign_id`, `brand`, `entity_type`, `entity_name`, `domain_type_code`, `status=PENDING` và `config_status=DRAFT`. Điều này phản ánh rõ tư duy “project as business context” chứ không chỉ là một record chứa tên và mô tả.

Ưu điểm của cách làm này là project luôn được tạo trong một trạng thái lifecycle có kiểm soát, đồng thời giữ được đủ business metadata cho bước kiểm tra điều kiện kích hoạt và domain routing ở các service downstream. Đây là một lựa chọn thiết kế rất quan trọng vì nó bảo đảm tính nhất quán liên chương giữa phân tích yêu cầu, thiết kế dữ liệu và hiện thực hóa.

#### Lớp minh họa từ mã nguồn

Tính năng này được hiện thực tại file `../project-srv/internal/project/repository/postgre/project.go` thông qua hàm `Create`.

Code snippet tiêu biểu:

```go
func (r *implRepository) Create(ctx context.Context, opt repository.CreateOptions) (model.Project, error) {
    now := time.Now().UTC()
    query := `
        INSERT INTO project.projects (
            campaign_id,
            name,
            description,
            brand,
            entity_type,
            entity_name,
            domain_type_code,
            status,
            config_status,
            created_by,
            created_at,
            updated_at
        ) VALUES ($1, $2, NULLIF($3, ''), NULLIF($4, ''), $5, $6, $7, $8, $9, $10, $11, $12)
        RETURNING id
    `
```

Đoạn mã trên cho thấy project không được tạo với status tùy ý. Thay vào đó, status và config status được gắn ngay theo vòng đời chuẩn. Đây là bằng chứng rõ cho việc business rules đã được đưa vào implementation layer.

### 5.3.3 Tính năng 3: Datasource lifecycle và crawl mode update

#### Lớp lý thuyết

Trong các hệ thống crawl dữ liệu, vòng đời của datasource cần được quản lý như một state machine có kiểm soát, thay vì để mọi trạng thái chuyển tự do. Các thao tác như activate, pause, resume hay thay đổi crawl mode thường cần kiểm tra điều kiện tiền đề, trạng thái hiện tại và ghi lại audit trail. Nếu bỏ qua các bước này, execution runtime sẽ trở nên khó kiểm soát và rất dễ mất tính nhất quán với business state.

#### Lớp phân tích trên dự án SMAP

`ingest-srv` hiện thực khá rõ tư duy trên. Hàm `ActivateDataSource` chỉ cho phép chuyển từ `READY` sang `ACTIVE` khi runtime prerequisites đã thỏa. Hàm `PauseDataSource` chỉ cho phép pause khi source đang `ACTIVE`. Hàm `ResumeDataSource` chỉ cho phép resume khi source đang `PAUSED`. Đặc biệt, hàm `UpdateCrawlMode` không chỉ cập nhật mode mới mà còn ghi thêm một record vào `crawl_mode_changes`, nhờ đó hệ thống có audit trail cho các lần thay đổi chính sách crawl.

Ưu điểm của thiết kế này là mọi thao tác điều khiển runtime đều đi qua usecase layer với kiểm tra ràng buộc rõ ràng. Điều đó giúp bảo vệ execution plane khỏi các lệnh không hợp lệ và tăng khả năng truy vết khi cần kiểm tra lịch sử vận hành.

#### Lớp minh họa từ mã nguồn

Tính năng này được hiện thực tại file `../ingest-srv/internal/datasource/usecase/datasource_lifecycle.go` thông qua các hàm `ActivateDataSource`, `PauseDataSource`, `ResumeDataSource` và `UpdateCrawlMode`.

Code snippet tiêu biểu:

```go
func (uc *implUseCase) ActivateDataSource(ctx context.Context, id string) (datasource.ActivateOutput, error) {
    current, err := uc.repo.DetailDataSource(ctx, strings.TrimSpace(id))
    if err != nil {
        return datasource.ActivateOutput{}, datasource.ErrNotFound
    }
    if current.Status != model.SourceStatusReady {
        return datasource.ActivateOutput{}, datasource.ErrActivateNotAllowed
    }
    if err := uc.ensureRuntimePrerequisites(ctx, current, datasource.ErrActivateNotAllowed); err != nil {
        return datasource.ActivateOutput{}, err
    }
    updated, err := uc.repo.UpdateDataSource(ctx, repo.UpdateDataSourceOptions{
        ID:            current.ID,
        Status:        string(model.SourceStatusActive),
        ClearPausedAt: true,
    })
    ...
}
```

```go
if _, err := uc.repo.CreateCrawlModeChange(ctx, repo.CreateCrawlModeChangeOptions{
    SourceID:            current.ID,
    ProjectID:           current.ProjectID,
    TriggerType:         strings.TrimSpace(input.TriggerType),
    FromMode:            string(*current.CrawlMode),
    ToMode:              strings.TrimSpace(input.CrawlMode),
    ...
}); err != nil {
    return datasource.UpdateCrawlModeOutput{}, datasource.ErrUpdateFailed
}
```

### 5.3.4 Tính năng 4: Kafka consumer và analytics pipeline execution

#### Lớp lý thuyết

Một analytics pipeline bất đồng bộ thường được thiết kế theo kiểu consumer-based processing. Message được lấy từ broker, parse về canonical data model, sau đó được chuyển qua nhiều stage xử lý như normalization, enrichment, scoring và publishing. Với các workload CPU-bound hoặc mixed I/O + CPU như NLP, việc tách pipeline khỏi HTTP request path là gần như bắt buộc nếu hệ thống muốn duy trì hiệu năng ổn định.

#### Lớp phân tích trên dự án SMAP

Trong `analysis-srv`, lớp `ConsumerServer` đảm nhiệm phần intake của Kafka message. Hàm `_handle_message` cho thấy một flow xử lý khá rõ: decode message, auto-detect format, parse thành `UAPRecord`, route domain bằng `domain_type_code`, adapt sang `IngestedBatchBundle`, tạo `RunContext`, chạy pipeline qua `asyncio.to_thread`, rồi persist và publish kết quả. Cấu trúc này phản ánh rõ một pipeline-oriented architecture đúng nghĩa, không phải chỉ là “consume rồi gọi vài hàm xử lý” rời rạc.

Ở tầng pipeline, lớp `PipelineUseCase` chỉ đóng vai trò wrapper mỏng quanh `run_pipeline()`. Đây là một thiết kế hợp lý vì giữ được separation of concerns: consumer layer lo orchestration của intake, còn pipeline layer tập trung vào xử lý domain. Khi hệ thống cần mở rộng stage mới, thay đổi này có thể được giới hạn ở pipeline package mà không phải sửa sâu ở delivery layer.

#### Lớp minh họa từ mã nguồn

Tính năng này được hiện thực tại `../analysis-srv/internal/consumer/server.py` thông qua lớp `ConsumerServer` và hàm `_handle_message`, kết hợp với `../analysis-srv/internal/pipeline/usecase/usecase.py` qua hàm `run`.

Code snippet tiêu biểu:

```python
result = await asyncio.to_thread(
    self.pipeline_usecase.run,
    bundle,
    ctx,
    self.pipeline_config,
)
```

```python
def run(
    self,
    batch: IngestedBatchBundle,
    ctx: RunContext,
    config: PipelineConfig,
) -> PipelineRunResult:
    result = run_pipeline(batch, ctx, config)
    return result
```

Đoạn mã này cho thấy rõ quyết định kỹ thuật: phần xử lý pipeline nặng được đẩy sang thread pool bằng `asyncio.to_thread`, trong khi orchestration của consumer vẫn ở lớp async. Điều này làm giảm nguy cơ block event loop khi pipeline chạy các bước CPU-bound.

### 5.3.5 Tính năng 5: Semantic search và chat routing

#### Lớp lý thuyết

Trong hệ thống RAG, luồng xử lý chuẩn thường gồm các bước: xác thực request, truy hồi dữ liệu liên quan, xây prompt, gọi mô hình sinh ngôn ngữ, lưu lại lịch sử hội thoại và trả kết quả. Nếu hệ thống có nhiều backend như Qdrant search và NotebookLM flow, usecase layer cần thêm một bước routing để quyết định backend phù hợp theo intent hoặc trạng thái dữ liệu.

#### Lớp phân tích trên dự án SMAP

`knowledge-srv` hiện thực khá rõ mô hình này. Hàm `Search` ở search usecase chạy theo flow: validate input, kiểm tra cache, resolve campaign, generate embedding, build filter, search Qdrant, post-filter theo score, aggregate và cache kết quả. Trong khi đó, hàm `Chat` ở chat usecase thực hiện routing giữa NotebookLM path và Qdrant path. Nếu notebook path được bật và dữ liệu đã sync, hệ thống submit async job. Nếu không, hệ thống chạy search rồi build prompt, gọi Gemini và lưu conversation/messages.

Ưu điểm của thiết kế này là khả năng mở rộng backend cho các luồng xử lý tri thức mà không phá contract ở tầng HTTP. Người dùng vẫn gọi một route chat thống nhất, nhưng bên trong service có thể chọn đường xử lý khác nhau theo context thực tế. Đây là một dạng điều phối xử lý rất điển hình của các dịch vụ tri thức nhiều lớp.

#### Lớp minh họa từ mã nguồn

Tính năng tìm kiếm được hiện thực tại `../knowledge-srv/internal/search/usecase/search.go` qua hàm `Search`. Tính năng chat được hiện thực tại `../knowledge-srv/internal/chat/usecase/chat.go` qua hàm `Chat` và `GetChatJobStatus`.

Code snippet tiêu biểu:

```go
// Flow: check cache → resolve campaign → embed query → search Qdrant → filter by Score → aggregate → cache → return
func (uc *implUseCase) Search(ctx context.Context, sc model.Scope, input search.SearchInput) (search.SearchOutput, error) {
    ...
    cachedData, err := uc.cacheRepo.GetSearchResults(ctx, cacheKey)
    ...
    generateOutput, err := uc.embeddingUC.Generate(ctx, embedding.GenerateInput{Text: input.Query})
    ...
    pointResults, err := uc.pointUC.Search(ctx, point.SearchInput{...})
    ...
}
```

### 5.3.6 Tính năng 6: Realtime notification và crisis dispatch

#### Lớp lý thuyết

Trong các hệ thống phân tích theo thời gian thực, notification layer không chỉ có vai trò hiển thị thông báo. Nó còn là điểm cuối của một chuỗi xử lý dài, nơi dữ liệu đã được rút gọn và chuẩn hóa phải được chuyển hóa thành thông điệp phù hợp với kênh nhận. Đối với WebSocket, mục tiêu là duy trì kết nối và đẩy khung dữ liệu nhẹ theo scope người dùng hoặc project. Đối với Discord webhook, mục tiêu là dựng thông điệp giàu ngữ nghĩa với tiêu đề, severity, metric và ngữ cảnh hành động.

#### Lớp phân tích trên dự án SMAP

`notification-srv` hiện thực hai nhánh delivery khác nhau nhưng bổ trợ cho nhau. Ở nhánh WebSocket, handler `HandleWebSocket` thực hiện validate request, upgrade connection và đăng ký kết nối vào usecase/hub layer. Ở nhánh alerting, usecase `DispatchCrisisAlert` xây dựng danh sách `EmbedField`, phân loại severity thành message type phù hợp, rồi gửi embed qua Discord client. Cách tổ chức này có ưu điểm là tách rõ connection management khỏi alert formatting, đồng thời làm cho notification layer có thể mở rộng thêm loại message mới mà không phá logic hiện có.

#### Lớp minh họa từ mã nguồn

Tính năng này được hiện thực tại `../notification-srv/internal/websocket/delivery/http/handlers.go` thông qua hàm `HandleWebSocket`, và tại `../notification-srv/internal/alert/usecase/dispatch_crisis.go` thông qua hàm `DispatchCrisisAlert`.

Code snippet tiêu biểu:

```go
func (h *handler) HandleWebSocket(c *gin.Context) {
    req, userID, err := h.processUpgradeRequest(c)
    if err != nil {
        response.Error(c, h.mapError(err))
        return
    }

    upgrader := websocket.Upgrader{...}
    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        return
    }

    input := req.toInput(conn, userID)
    if err := h.uc.Register(c.Request.Context(), input); err != nil {
        conn.Close()
        return
    }
}
```

```go
func (uc *implUseCase) DispatchCrisisAlert(ctx context.Context, input alert.CrisisAlertInput) error {
    fields := []discord.EmbedField{
        buildField("Severity", strings.ToUpper(input.Severity), true),
        buildField("Alert Type", strings.ToTitle(input.AlertType), true),
        buildField("Metric", input.Metric, true),
    }
    opts := discord.MessageOptions{
        Type:        msgType,
        Title:       fmt.Sprintf("🚨 Crisis Alert: %s", input.ProjectName),
        Description: fmt.Sprintf("Unusual activity detected in project **%s** (%s).", input.ProjectName, input.ProjectID),
        Fields:      fields,
        Timestamp:   time.Now(),
    }
    return uc.discord.SendEmbed(ctx, opts)
}
```

Hai đoạn mã trên thể hiện rõ hai kiểu delivery semantics khác nhau trong cùng một service. WebSocket flow ưu tiên connection registration và session-scoped delivery, trong khi Discord flow ưu tiên formatting của alert payload. Đây là một minh chứng tốt cho quyết định kiến trúc tách `internal/websocket` và `internal/alert` thành hai domain riêng trong `notification-srv`.

## 5.4 Deployment Process

### 5.4.1 Lớp lý thuyết

Quy trình triển khai của hệ thống nhiều service thường bao gồm hai mức: đóng gói từng service bằng Dockerfile và tổ chức runtime bằng Docker Compose hoặc Kubernetes manifests. Docker giúp chuẩn hóa artifact. Docker Compose giúp tái lập environment cục bộ. Kubernetes manifests giúp mô tả deployment, resource allocation, probe và autoscaling trong môi trường orchestrated.

### 5.4.2 Lớp phân tích trên dự án SMAP

Workspace hiện tại cho thấy quá trình triển khai được thiết kế theo hướng tách riêng artifact theo service. Mỗi service chính đều có Dockerfile riêng, cho phép build độc lập. `project-srv` và `ingest-srv` dùng Docker Compose để dựng local stack có đủ PostgreSQL, Redis, Kafka, RabbitMQ hoặc MinIO. `analysis-srv` có deployment manifest và HPA, chứng minh rằng consumer workload của analytics đã được suy nghĩ cho môi trường Kubernetes.

Điểm cần nhấn mạnh là CI/CD pipeline cụ thể chưa có bằng chứng trực tiếp trong workspace. Vì vậy, deployment process trong luận văn này chỉ dừng ở mức artifact build và deployment manifests thực tế, không mô tả giả định về GitHub Actions hoặc pipeline release nếu chưa có file chứng minh.

### 5.4.3 Lớp minh họa từ mã nguồn

- Dockerfiles: `../analysis-srv/apps/consumer/Dockerfile`, `../scapper-srv/Dockerfile`, `../identity-srv/cmd/server/Dockerfile`, `../project-srv/cmd/server/Dockerfile`, `../ingest-srv/cmd/server/Dockerfile`, `../knowledge-srv/cmd/server/Dockerfile`, `../notification-srv/cmd/server/Dockerfile`
- Docker Compose local stacks: `../project-srv/docker-compose.yml`, `../ingest-srv/docker-compose.yml`
- Kubernetes Deployment: `../analysis-srv/apps/consumer/deployment.yaml`
- HPA: `../analysis-srv/manifests/hpa.yaml`

Ví dụ, `analysis-srv/apps/consumer/deployment.yaml` hiện thực các quyết định triển khai sau:

- image registry rõ ràng: `registry.tantai.dev/smap/analysis-consumer:latest`
- resource request/limit cho workload NLP nặng
- `livenessProbe` và `startupProbe`
- `terminationGracePeriodSeconds` để Kafka consumer có thời gian commit offset trước khi shutdown

## 5.5 User Interface Gallery

### 5.5.1 Phạm vi xác nhận

Theo nguyên tắc bằng chứng mã nguồn, phần giao diện người dùng chỉ có thể được viết chi tiết khi có frontend source hoặc ít nhất có asset UI nằm trong workspace hiện tại. Tại thời điểm khảo sát, không tìm thấy `package.json` hoặc thư mục frontend source code nào trong workspace. Vì vậy, không thể mô tả framework UI, cơ chế rendering, state management hoặc gallery màn hình như một phần đã được xác nhận trực tiếp từ mã nguồn.

### 5.5.2 Những gì có thể khẳng định

Mặc dù không có frontend source, có thể xác nhận rằng hệ thống có ít nhất các interaction surfaces sau:

- Browser dashboard hoặc web client, được nhắc đến trong `../notification-srv/README.md`
- WebSocket client kết nối tới `GET /ws`, được mô tả tại `../notification-srv/documents/contracts.md`
- Chat/search UI logic ở tầng backend, được xác nhận qua `knowledge-srv` routes và conversation storage

### 5.5.3 Kết luận cho phần UI gallery

Phần UI gallery sẽ được xem là `ngoài phạm vi xác nhận trực tiếp` của luận văn này nếu chỉ dựa trên workspace hiện tại. Nếu về sau người phát triển bổ sung frontend source hoặc bộ screenshot chính thức, phần này có thể được mở rộng mà không làm thay đổi logic của các chương trước.

## 5.6 Kết luận chương

Chương này cho thấy hiện thực của SMAP có độ bám khá sát với kiến trúc đã phân tích và thiết kế ở các chương trước. Authentication được tách thành luồng OAuth2 và session management rõ ràng. Project metadata được lưu với business semantics đầy đủ. Datasource lifecycle được kiểm soát qua state transitions và audit trail. Analytics pipeline vận hành theo consumer-based model với thread offloading cho xử lý nặng. Knowledge layer hiện thực retrieval và routing giữa nhiều backend xử lý.

Điểm quan trọng nhất của chương là mọi tính năng lõi đều đã được nối trực tiếp tới file và hàm thực tế trong source code. Điều này bảo đảm luận văn không chỉ dừng ở mức mô tả kiến trúc, mà thực sự đi sâu vào hiện thực hóa. Đồng thời, phần deployment cũng chỉ khẳng định những gì có bằng chứng từ Dockerfile, Docker Compose, Kubernetes Deployment và HPA. Đây là cách tiếp cận nhất quán với nguyên tắc “source-code evidence” đã đặt ra từ đầu.
