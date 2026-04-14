# Danh sách công nghệ xác nhận từ mã nguồn

## 1. Nguyên tắc xác nhận

Danh sách dưới đây chỉ bao gồm các công nghệ được xác nhận trực tiếp từ `go.mod`, `pyproject.toml`, `requirements.txt`, `Dockerfile`, `docker-compose*.yml`, `deployment.yaml`, `hpa.yaml`, hoặc file cấu hình runtime. Những công nghệ không có bằng chứng trong mã nguồn hiện tại sẽ không được liệt kê như một phần chắc chắn của hệ thống.

## 2. Công nghệ backend và ngôn ngữ

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| Ngôn ngữ | Go `1.25.x` | `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` |
| Ngôn ngữ | Python `>=3.12` | `../analysis-srv/pyproject.toml`, `../smap-analyse/pyproject.toml` |
| Web framework Go | Gin | `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` |
| Web framework Python | FastAPI | `../scapper-srv/requirements.txt`, `../shared-libs/python/pyproject.toml` |
| ASGI server | Uvicorn | `../scapper-srv/requirements.txt`, `../shared-libs/python/pyproject.toml` |
| Config management | Viper | `../identity-srv/go.mod`, `../project-srv/go.mod`, `../ingest-srv/go.mod`, `../knowledge-srv/go.mod`, `../notification-srv/go.mod` |

## 3. Authentication và security

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| OAuth2 | Google OAuth2 | `../identity-srv/go.mod`, `../identity-srv/config/auth-config.yaml` |
| JWT | HS256 JWT | `../identity-srv/config/auth-config.yaml`, `../project-srv/go.mod`, `../notification-srv/go.mod` |
| Cookie auth | HttpOnly cookie `smap_auth_token` | `../identity-srv/config/auth-config.yaml`, `../project-srv/README.md`, `../notification-srv/documents/contracts.md` |
| Internal service auth | Shared internal key | `../identity-srv/config/auth-config.yaml`, `../knowledge-srv/config/knowledge-config.yaml` |

## 4. Cơ sở dữ liệu, cache và storage

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| RDBMS | PostgreSQL | `../project-srv/docker-compose.yml`, `../ingest-srv/docker-compose.yml`, `../identity-srv/config/auth-config.yaml` |
| Cache / session / pubsub | Redis | `../notification-srv/go.mod`, `../analysis-srv/pyproject.toml`, `../knowledge-srv/go.mod`, `../project-srv/docker-compose.yml`, `../ingest-srv/docker-compose.yml` |
| Object storage | MinIO | `../analysis-srv/pyproject.toml`, `../shared-libs/go/go.mod`, `../ingest-srv/docker-compose.yml`, `../knowledge-srv/config/knowledge-config.yaml` |
| Vector database | Qdrant | `../knowledge-srv/go.mod`, `../knowledge-srv/config/knowledge-config.yaml` |

## 5. Message broker và giao tiếp bất đồng bộ

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| Streaming / event bus | Kafka | `../identity-srv/go.mod`, `../knowledge-srv/go.mod`, `../analysis-srv/pyproject.toml`, `../analysis-srv/docker-compose.e2e.yml`, `../project-srv/docker-compose.yml` |
| Kafka client Go | Sarama | `../identity-srv/go.mod`, `../knowledge-srv/go.mod`, `../shared-libs/go/go.mod` |
| AMQP broker | RabbitMQ | `../ingest-srv/go.mod`, `../shared-libs/go/go.mod`, `../scapper-srv/requirements.txt`, `../ingest-srv/docker-compose.yml` |
| Python AMQP client | aio-pika | `../analysis-srv/pyproject.toml`, `../scapper-srv/requirements.txt` |

## 6. NLP, ML và analytics

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| Deep learning | PyTorch | `../analysis-srv/pyproject.toml`, `../smap-analyse/pyproject.toml` |
| Transformer stack | Hugging Face Transformers | `../analysis-srv/pyproject.toml`, `../smap-analyse/pyproject.toml` |
| ONNX optimization | Optimum ONNX Runtime | `../analysis-srv/pyproject.toml` |
| Vietnamese NLP | PyVi | `../analysis-srv/pyproject.toml` |
| General NLP | SpaCy | `../analysis-srv/pyproject.toml` |
| Keyword extraction | YAKE | `../analysis-srv/pyproject.toml` |
| Similarity / dedup | datasketch | `../analysis-srv/pyproject.toml` |
| DataFrame analytics | Polars | `../analysis-srv/pyproject.toml`, `../smap-analyse/pyproject.toml` |
| Local analytics DB | DuckDB | `../smap-analyse/pyproject.toml` |

## 7. Logging, observability, testing

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| Logging Go | Zap | `../shared-libs/go/go.mod` |
| Logging Go | Logrus | `../knowledge-srv/go.mod` |
| Logging Python | Loguru | `../analysis-srv/pyproject.toml`, `../scapper-srv/requirements.txt` |
| Metrics | Prometheus client | `../analysis-srv/pyproject.toml` |
| Testing Python | pytest, pytest-asyncio, testcontainers | `../analysis-srv/pyproject.toml`, `../shared-libs/python/pyproject.toml` |
| Testing Go | testify | `../notification-srv/go.mod` |

## 8. DevOps và triển khai

| Nhóm | Công nghệ | Bằng chứng |
| --- | --- | --- |
| Containerization | Dockerfile | `../analysis-srv/apps/consumer/Dockerfile`, `../scapper-srv/Dockerfile`, `../identity-srv/cmd/server/Dockerfile`, `../project-srv/cmd/server/Dockerfile`, `../ingest-srv/cmd/server/Dockerfile`, `../knowledge-srv/cmd/server/Dockerfile`, `../notification-srv/cmd/server/Dockerfile` |
| Local environment | Docker Compose | `../project-srv/docker-compose.yml`, `../ingest-srv/docker-compose.yml`, `../analysis-srv/docker-compose.e2e.yml` |
| Orchestration | Kubernetes Deployment | `../analysis-srv/apps/consumer/deployment.yaml` |
| Auto scaling | HorizontalPodAutoscaler | `../analysis-srv/manifests/hpa.yaml` |
| Registry | Harbor-style image registry | `../analysis-srv/apps/consumer/deployment.yaml` |

## 9. Công nghệ chưa được xác nhận trực tiếp

Các hạng mục sau chưa nên được coi là fact của hệ thống tại thời điểm hiện tại:

- frontend framework cụ thể như Next.js, React, Vue, vì workspace hiện tại không có `package.json`
- CI/CD implementation cụ thể như GitHub Actions, GitLab CI hoặc Jenkins, vì không tìm thấy `.github/workflows/*` hay pipeline manifests tương ứng

Hai điểm này cần được ghi rõ trong luận văn để tránh vi phạm nguyên tắc “bằng chứng mã nguồn”.
