# Source-Code Evidence Matrix

## 1. Mục đích

Ma trận này được dùng để đảm bảo các chương sau không mô tả công nghệ hoặc tính năng vượt quá bằng chứng có trong mã nguồn. Mỗi dòng dưới đây nối một capability hoặc công nghệ với file nguồn cụ thể và entry point/hàm chính nếu có thể xác định được.

## 2. Capability matrix

| Capability | Công nghệ / cách làm | File bằng chứng | Hàm / entry point |
| --- | --- | --- | --- |
| OAuth2 login | Gin + Google OAuth2 | `../identity-srv/internal/authentication/delivery/http/oauth.go` | `OAuthLogin`, `OAuthCallback` |
| Session creation | Redis-backed session | `../identity-srv/internal/authentication/usecase/util.go`, `../identity-srv/internal/authentication/usecase/session.go` | `createSession`, `CreateSession` |
| Current user / logout | Gin handlers + JWT/cookie | `../identity-srv/internal/authentication/delivery/http/handlers.go` | `Logout`, `GetMe` |
| Project persistence | PostgreSQL + repository pattern | `../project-srv/internal/project/repository/postgre/project.go` | `Create`, `Update`, `UpdateStatus` |
| Datasource lifecycle | Gin + usecase layer | `../ingest-srv/internal/datasource/usecase/datasource_lifecycle.go` | `ActivateDataSource`, `PauseDataSource`, `ResumeDataSource`, `UpdateCrawlMode` |
| Project-to-ingest lifecycle | usecase control plane | `../ingest-srv/internal/datasource/usecase/project_lifecycle.go` | `Activate`, `Pause`, `Resume` |
| Target activation | ingest runtime control | `../ingest-srv/internal/datasource/usecase/target.go` | `ActivateTarget` |
| Analysis consumer runtime | Python consumer server | `../analysis-srv/internal/consumer/server.py`, `../analysis-srv/apps/consumer/main.py` | `ConsumerServer`, `_handle_message`, `run` |
| Pipeline execution | pipeline runner | `../analysis-srv/internal/pipeline/usecase/usecase.py` | `run` |
| NLP batch enrichment | analytics usecase | `../analysis-srv/internal/analytics/usecase/batch_enricher.py` | `enrich_batch` |
| Enrichment stage | phase 4 enrichment | `../analysis-srv/internal/enrichment/usecase/enrich_batch.py` | `enrich_batch` |
| Semantic search | Go + Qdrant | `../knowledge-srv/internal/search/usecase/search.go`, `../knowledge-srv/pkg/qdrant/qdrant.go` | `Search`, `SearchWithFilter` |
| Chat / RAG | Gin + LLM integration | `../knowledge-srv/internal/chat/delivery/http/handlers.go`, `../knowledge-srv/internal/chat/usecase/chat.go` | `Chat`, `GetChatJob`, `Chat` |
| Notebook sync | NotebookLM orchestration | `../knowledge-srv/internal/notebook/usecase/sync.go`, `../knowledge-srv/internal/notebook/usecase/query.go` | `SyncPart`, `SubmitChatJob`, `GetChatJobStatus` |
| WebSocket connection | Gorilla WebSocket | `../notification-srv/internal/websocket/delivery/http/handlers.go` | `HandleWebSocket` |
| Discord alert dispatch | alert usecases | `../notification-srv/internal/alert/usecase/dispatch_crisis.go`, `dispatch_campaign.go`, `dispatch_onboarding.go` | `DispatchCrisisAlert`, `DispatchCampaignEvent`, `DispatchDataOnboarding` |
| Crawl task publish | RabbitMQ publisher | `../scapper-srv/app/publisher.py` | `publish_task`, `publish_completion` |
| Worker bootstrap | FastAPI lifespan + worker startup | `../scapper-srv/app/main.py`, `../scapper-srv/app/worker.py` | `lifespan`, `Worker.start` |

## 3. Hạ tầng và deployment matrix

| Concern | File bằng chứng | Ghi chú |
| --- | --- | --- |
| Kafka E2E local broker | `../analysis-srv/docker-compose.e2e.yml` | dùng `confluentinc/cp-kafka:7.5.0`, KRaft mode |
| Kubernetes Deployment | `../analysis-srv/apps/consumer/deployment.yaml` | deployment cho `analysis-consumer` |
| HPA autoscaling | `../analysis-srv/manifests/hpa.yaml` | scale theo CPU cho consumer |
| Project service local stack | `../project-srv/docker-compose.yml` | PostgreSQL, Redis, Zookeeper, Kafka, dev UIs |
| Ingest service local stack | `../ingest-srv/docker-compose.yml` | PostgreSQL, Redis, MinIO, Kafka, RabbitMQ |
| Knowledge runtime infra | `../knowledge-srv/config/knowledge-config.yaml` | Qdrant, PostgreSQL, Redis, MinIO, Kafka, Gemini, Voyage, Maestro |
| Identity runtime infra | `../identity-srv/config/auth-config.yaml` | PostgreSQL, Redis, Kafka, OAuth2, JWT, cookie, internal auth |

## 4. Kết luận sử dụng ma trận

Ba kết luận quan trọng được rút ra từ ma trận bằng chứng.

Thứ nhất, backend và hạ tầng của hệ thống có bằng chứng mạnh. Điều này cho phép Chương 2, Chương 4 và Chương 5 đi sâu vào backend architecture mà không cần suy diễn.

Thứ hai, frontend stack và CI/CD pipeline chưa có đủ bằng chứng. Vì vậy, trong luận văn chỉ nên mô tả chúng như khoảng trống tài liệu hoặc phần ngoài phạm vi xác nhận, thay vì khẳng định tên framework cụ thể.

Thứ ba, phần lớn các capability cốt lõi đều có thể liên kết được tới file và hàm hiện thực. Đây là điều kiện cần để triển khai các chương sau theo nguyên tắc “bằng chứng mã nguồn”.
