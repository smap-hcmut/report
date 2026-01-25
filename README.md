# SMAP - Social Media Analytics Platform

Repository tập trung quản lý toàn bộ các thành phần của hệ thống SMAP, bao gồm: code cập nhật mới nhất của từng service, tài liệu hướng dẫn sử dụng, quyết định kiến trúc, diagrams, báo cáo đồ án, và slides thuyết trình.

## Tổng quan

**SMAP (Social Media Analytics Platform)** là nền tảng thu thập và phân tích dữ liệu từ mạng xã hội (YouTube, TikTok), được thiết kế với kiến trúc Microservices và Event-Driven Architecture.

### Mục tiêu chính

- Thu thập dữ liệu từ các nền tảng mạng xã hội (YouTube, TikTok)
- Phân tích sentiment và aspect bằng AI/ML (PhoBERT)
- Cung cấp insights và báo cáo cho Marketing Analyst
- Tự động hóa quy trình từ Crawling → Analyzing → Insight

## Cấu trúc Repository

``` Markdown
smap-dispacher/
├── services/          # Code của các microservices
├── report/            # Báo cáo đồ án (Typst)
├── ppt/               # Slides thuyết trình (Marp)
├── documents/         # Tài liệu workspace (guides, planning, drafts)
├── diagrams/          # PlantUML diagrams (sequence, activity, component, etc.)
└── README.md          # File này
```

## Services

Hệ thống SMAP bao gồm các microservices sau:

### Backend Services (Golang)

| Service | Port | Mô tả |
|---------|------|-------|
| **Identity** | 8083 | Authentication, user management, JWT issuing |
| **Project** | 8080 | Project CRUD, execution orchestration, webhook handling |
| **Collector** | 8081 | Crawl orchestration, progress updates |
| **WebSocket** | 8082 | Real-time notifications to clients |

### Backend Services (Python)

| Service | Mô tả |
|---------|-------|
| **Analytics** | Phân tích sentiment và aspect bằng PhoBERT |
| **Speech2Text** | Chuyển đổi âm thanh thành văn bản (Whisper) |
| **Scrapper** | Thu thập dữ liệu từ YouTube, TikTok |

### Frontend

| Service | Mô tả |
|---------|-------|
| **Web UI** | Next.js dashboard cho Marketing Analyst |

### Infrastructure Components

- **PostgreSQL**: Primary database
- **MongoDB**: Document storage cho Collector
- **Redis**: State management, Pub/Sub, job mapping
- **RabbitMQ**: Async event messaging
- **MinIO**: Object storage
- **Kubernetes**: Container orchestration (on-premise)

## Thư mục chính

### `services/`

Chứa code cập nhật mới nhất của từng service (được copy và commit thủ công định kỳ). Mỗi service có cấu trúc riêng:

- **Golang services**: Clean Architecture với Module-First approach
- **Python services**: FastAPI với Pydantic models
- **TypeScript services**: Next.js với React

**Lưu ý**: Các file build artifacts, dependencies, và config files được ignore bởi `.gitignore` để tối ưu indexing. Sử dụng `make clean` trong `services/Makefile` để dọn dẹp.

### `report/`

Báo cáo đồ án được soạn thảo bằng **Typst**, tổ chức theo chapters:

- Chapter 1: Giới thiệu
- Chapter 2: Hệ thống liên quan
- Chapter 3: Phân tích bài toán & yêu cầu
- Chapter 4: Phân tích hệ thống
- Chapter 5: Thiết kế hệ thống
- Chapter 6: Tổng kết
- Chapter 7: Tài liệu tham khảo
- Chapter 8: Phụ lục

Hình ảnh được tổ chức trong `report/images/` theo categories: `diagram/`, `architecture/`, `sequence/`, `data-flow/`, `deploy/`, etc.

### `ppt/`

Slides thuyết trình sử dụng **Marp** format:

- `planning/`: Kế hoạch và script thuyết trình
- `slides/`: Actual slides (Marp format)
- `evaluation/`: Đánh giá và phản hồi

Xem [ppt/README.md](ppt/README.md) để biết thêm chi tiết.

### `documents/`

Workspace để viết và chuẩn bị content trước khi đưa vào `report/`:

- `guides/`: Writing guides, format guides, templates
- `references/`: Reference data, indexes, charts data
- `planning/`: Planning documents, master plans
- `drafts/`: Draft content chưa integrate
- `verification/`: Verification và evaluation reports
- `archive/`: Files đã integrate hoặc không còn dùng

Xem [documents/README.md](documents/README.md) để biết thêm chi tiết.

### `diagrams/`

PlantUML diagrams mô tả kiến trúc và luồng xử lý:

- `sequence/`: Sequence diagrams (use cases)
- `activity/`: Activity diagrams
- `component/`: Component diagrams (C4 Level 3)
- `data-flow/`: Data flow diagrams
- `authentication/`: Authentication flow
- `realtime/`: Real-time communication flow

Xem [diagrams/README.md](diagrams/README.md) để biết thêm chi tiết.

## Kiến trúc hệ thống

### Architecture Style

- **Microservices Architecture**: 10 application services
- **Event-Driven Architecture**: Async communication qua RabbitMQ
- **Polyglot Architecture**: Golang (performance) + Python (AI/ML)
- **Clean Architecture**: Module-First approach với DDD

### Design Principles

- **Domain-Driven Design (DDD)**: Phân rã services dựa trên Bounded Contexts
- **High Cohesion, Low Coupling**: Services độc lập, dễ maintain
- **Event Sourcing**: State management qua events
- **CQRS**: Tách biệt read/write operations

## Technology Stack

### Backend

- **Golang 1.23+**: Gin framework, SQLBoiler ORM
- **Python 3.11+**: FastAPI, Pydantic, PhoBERT, Whisper
- **TypeScript**: Next.js, React

### Databases

- **PostgreSQL 15+**: Primary relational database
- **MongoDB**: Document storage
- **Redis**: Caching, Pub/Sub, state management

### Messaging & Communication

- **RabbitMQ**: Async event messaging
- **Redis Pub/Sub**: Real-time notifications
- **WebSocket**: Real-time client communication

### Infrastructure

- **Docker**: Containerization
- **Kubernetes**: Container orchestration (on-premise)
- **MinIO**: Object storage

## Quy trình làm việc

### 1. Development

- Mỗi service được phát triển độc lập trong repository riêng
- Code được copy vào `services/` định kỳ để tracking và documentation

### 2. Documentation

- **Planning**: Viết trong `documents/planning/`
- **Drafting**: Viết draft trong `documents/drafts/`
- **Integration**: Integrate vào `report/` khi hoàn thành
- **Verification**: Review và evaluation trong `documents/verification/`

### 3. Diagrams

- Tạo PlantUML diagrams trong `diagrams/`
- Export images vào `report/images/` khi cần

### 4. Presentation

- Planning trong `ppt/planning/`
- Tạo slides trong `ppt/slides/` (Marp format)
- Generate PDF/HTML từ Marp CLI

## Build & Deploy

### Services

Mỗi service có build process riêng. Xem README trong từng service folder:

```bash
# Example: Build Project Service (Golang)
cd services/project
go build ./cmd/api

# Example: Run Analytics Service (Python)
cd services/analytic
uv run python -m app.main
```

### Report

Generate PDF từ Typst:

```bash
cd report
typst compile main.typ
```

### Presentation

Generate PDF từ Marp:

```bash
cd ppt
marp slides/presentation.md --pdf
```

## Maintenance

### Cleanup Services

Sử dụng Makefile để dọn dẹp build artifacts:

```bash
cd services
make clean          # Clean all services
make clean-python   # Clean Python services only
make clean-go       # Clean Go services only
```

### File Organization

- **Naming convention**:
  - Files: kebab-case (lowercase)
  - Folders: lowercase
  - Code: theo convention của từng language

- **Structure**:
  - Mỗi folder có README.md mô tả structure
  - Archive old files thay vì xóa
  - Giữ consistency trong naming
