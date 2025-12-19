# Project Context

## Purpose

**SMAP (Social Media Analytics Platform)** là hệ thống phân tích mạng xã hội toàn diện được thiết kế để:

- **Thu thập dữ liệu** từ các nền tảng mạng xã hội (TikTok, YouTube, Instagram)
- **Phân tích nội dung** với các mô hình AI/ML chuyên biệt cho tiếng Việt
- **Trích xuất insights** từ sentiment, keywords, trends, và engagement metrics
- **Cung cấp dashboard** real-time với WebSocket notifications
- **Quản lý projects** và tracking brand/competitor analysis

### Tính năng nổi bật

- **Event-Driven Architecture**: Choreography pattern với RabbitMQ
- **Scalable Microservices**: Horizontal scaling với multiple workers
- **Vietnamese Language Support**: PhoBERT sentiment analysis, PyVi segmentation
- **Real-time Processing**: WebSocket notifications, async task processing
- **Clean Architecture**: Separation of concerns, dependency injection
- **Production-Ready**: Comprehensive testing, logging, error handling

---

## Tech Stack

### Backend Services

#### Python Services (3.12+)
- **Analytic Service**: FastAPI, PostgreSQL, PhoBERT ONNX, SpaCy-YAKE
- **Scrapper Services**: TikTok/YouTube workers, Playwright, yt-dlp
- **Speech2Text Service**: FastAPI, Whisper.cpp, Redis

#### Go Services (1.23+)
- **Collector Service**: Dispatcher/coordinator, RabbitMQ, Redis
- **Identity Service**: Gin, PostgreSQL, JWT, RabbitMQ
- **Project Service**: Gin, PostgreSQL, SQLBoiler
- **WebSocket Service**: WebSocket hub, Redis Pub/Sub

### Frontend
- **Web UI**: Next.js 15.2.3, TypeScript 5.8.2, React 19.0.0, Tailwind CSS

### Infrastructure
- **Databases**: PostgreSQL 15, MongoDB 6.x, Redis 7.0+
- **Message Queue**: RabbitMQ 3.x
- **Object Storage**: MinIO (S3-compatible)
- **Containerization**: Docker, Docker Compose, Kubernetes

### AI/ML Stack
- **PhoBERT ONNX**: Vietnamese sentiment analysis (5-class: 1-5★)
- **SpaCy + YAKE**: Keyword extraction (NER + statistical)
- **Whisper.cpp**: Speech-to-text transcription
- **PyVi**: Vietnamese text segmentation

### Package Management
- **Python**: `uv` (preferred), `pip` (fallback)
- **Go**: `go mod`

---

## Services Overview

### 1. Analytic Service (`services/analytic/`)
**Purpose**: Analytics engine cho phân tích nội dung mạng xã hội

**Key Features**:
- Vietnamese sentiment analysis với PhoBERT (5-class rating)
- Intent classification (7 categories: CRISIS, SEEDING, SPAM, COMPLAINT, LEAD, SUPPORT, DISCUSSION)
- Keyword extraction với SpaCy-YAKE
- Aspect-Based Sentiment Analysis (ABSA)
- Impact & Risk Calculator
- Text preprocessing và normalization
- RESTful API với FastAPI

**Tech**: Python 3.12+, FastAPI, PostgreSQL, Alembic, RabbitMQ, MinIO

**Architecture**: Clean Architecture với layers: command → internal → services → infrastructure

---

### 2. Collector Service (`services/collector/`)
**Purpose**: Dispatcher service điều phối crawl tasks đến platform-specific workers

**Key Features**:
- Nhận `CrawlRequest` từ RabbitMQ
- Validate và map payloads theo platform
- Phân phối tasks đến TikTok/YouTube workers
- Event-driven integration với Project Service
- Redis state management cho project progress
- Progress webhooks

**Tech**: Go 1.23+, RabbitMQ, Redis, MongoDB

**Architecture**: Clean Architecture với Producer-Consumer pattern

---

### 3. Identity Service (`services/identity/`)
**Purpose**: Authentication và subscription management

**Key Features**:
- User registration và email verification (OTP)
- HttpOnly cookie authentication (JWT)
- Subscription plans và free trial (14 days)
- Async email processing với RabbitMQ
- RESTful API với Swagger docs

**Tech**: Go 1.23+, Gin, PostgreSQL, SQLBoiler, RabbitMQ, JWT

**Architecture**: Clean Architecture với domain-driven design

---

### 4. Project Service (`services/project/`)
**Purpose**: Project management cho brand tracking và competitor analysis

**Key Features**:
- CRUD operations cho projects
- Brand keywords và competitor tracking
- Date range management
- Status tracking (Draft, Active, Completed, Archived, Cancelled)
- User isolation (users chỉ access được projects của mình)
- LLM integration cho keyword suggestions

**Tech**: Go 1.23+, Gin, PostgreSQL, SQLBoiler

**Architecture**: Clean Architecture với repository pattern

---

### 5. Scrapper Services (`services/scrapper/`)
**Purpose**: Social media data scraping workers

**Services**:
- **TikTok Worker**: Browser automation với Playwright, video metadata, comments, media download
- **YouTube Worker**: yt-dlp integration, 100% comment coverage, channel info, search
- **Instagram Worker**: Legacy production worker

**Key Features**:
- Research keyword, crawl links, research_and_crawl task types
- Concurrent crawling với configurable limits
- Smart upsert logic (static vs dynamic fields)
- Media download với FFmpeg
- MongoDB storage, MinIO for media files

**Tech**: Python 3.11/3.12+, Playwright, yt-dlp, MongoDB, MinIO, RabbitMQ

**Architecture**: Clean Architecture với application/domain/internal layers

---

### 6. Speech2Text Service (`services/speech2text/`)
**Purpose**: Speech-to-text transcription API

**Key Features**:
- Direct transcription từ audio URL
- Stateless architecture (no database)
- Dynamic model loading (base/small/medium)
- Sequential smart-chunking cho long audio (30+ minutes)
- Anti-hallucination filters
- Multi-language support (90+ languages)
- Async job processing với Redis

**Tech**: Python 3.12+, FastAPI, Whisper.cpp, Redis, FFmpeg

**Architecture**: Clean Architecture với service layer và dependency injection

---

### 7. Web UI (`services/web-ui/`)
**Purpose**: Frontend dashboard và analytics visualization

**Key Features**:
- Real-time dashboard với WebSocket integration
- Trend analysis và visualization
- Custom reports generation
- Workflow automation builder
- Multi-language support (i18n)
- Dark mode
- Responsive design

**Tech**: Next.js 15.2.3, TypeScript, React 19, Tailwind CSS, Chart.js, Recharts

**Architecture**: Component-based với React Context API

---

### 8. WebSocket Service (`services/websocket/`)
**Purpose**: Real-time notification hub

**Key Features**:
- HttpOnly cookie authentication
- Redis Pub/Sub integration
- Multiple connections per user
- Ping/Pong keep-alive (30s)
- Auto reconnection với retry logic
- Health & metrics endpoints
- Horizontal scaling ready

**Tech**: Go 1.25+, WebSocket, Redis Pub/Sub

**Architecture**: Hub pattern với connection management

---

## Project Conventions

### Code Style

#### Python Services
- **Formatting**: Black (default settings)
- **Linting**: flake8 với type checking
- **Type Hints**: Required cho function signatures
- **Naming**: snake_case cho variables/functions, PascalCase cho classes
- **Docstrings**: Google style cho public APIs

#### Go Services
- **Formatting**: `gofmt` hoặc `goimports`
- **Linting**: `golangci-lint`
- **Naming**: camelCase cho unexported, PascalCase cho exported
- **Comments**: Package-level và exported functions require comments

#### TypeScript/React
- **Formatting**: Prettier với default config
- **Linting**: ESLint với TypeScript rules
- **Naming**: camelCase cho variables/functions, PascalCase cho components
- **Type Safety**: Strict TypeScript mode

---

### Architecture Patterns

#### Clean Architecture
Tất cả services tuân theo Clean Architecture principles:

```
┌─────────────────────────────────────┐
│  Entry Points (cmd/)                │
│  - API handlers, consumers          │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Internal/Delivery                  │
│  - Routes, handlers, schemas       │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Services/UseCases                  │
│  - Business logic                   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Domain/Models                      │
│  - Entities, value objects          │
└─────────────────────────────────────┘
           ▲
           │
┌─────────────────────────────────────┐
│  Infrastructure/Adapters            │
│  - Database, queue, storage         │
└─────────────────────────────────────┘
```

**Benefits**:
- Testability: Mỗi layer có thể test độc lập
- Flexibility: Dễ swap implementations
- Maintainability: Clear separation of concerns
- Independence: Business logic không phụ thuộc frameworks

#### Event-Driven Architecture
- **Pattern**: Choreography (không phải Orchestration)
- **Message Broker**: RabbitMQ với topic exchanges
- **Event Schema**: Standardized với `event_id`, `event_type`, `timestamp`, `payload`
- **State Management**: Redis cho project progress tracking

#### Dependency Injection
- **Python**: Constructor injection với DI containers
- **Go**: Constructor functions (`New...`) với explicit dependencies
- **Benefits**: Testability, explicit dependencies, easy mocking

---

### Testing Strategy

#### Python Services
- **Framework**: pytest
- **Coverage**: Aim for 80%+ coverage
- **Test Types**:
  - Unit tests: Pure business logic
  - Integration tests: Database, queue interactions
  - E2E tests: Complete workflow validation
- **Test Structure**: Mirror source structure (`tests/unit/`, `tests/integration/`)

#### Go Services
- **Framework**: Standard `testing` package
- **Coverage**: `go test -cover`
- **Test Types**:
  - Unit tests: Business logic với mocks
  - Integration tests: Database, external services
- **Naming**: `*_test.go` files, `Test*` functions

#### Frontend
- **Framework**: Jest + React Testing Library
- **Test Types**:
  - Unit tests: Components, utilities
  - Integration tests: User flows
  - E2E tests: Playwright (if applicable)

---

### Git Workflow

#### Branching Strategy
- **main**: Production-ready code
- **develop**: Integration branch
- **feature/**: Feature branches (`feature/add-sentiment-analysis`)
- **fix/**: Bug fixes (`fix/websocket-reconnection`)
- **refactor/**: Code refactoring

#### Commit Conventions
Sử dụng [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:`: New feature
- `fix:`: Bug fix
- `docs:`: Documentation changes
- `style:`: Code style (formatting, no logic change)
- `refactor:`: Code refactoring
- `test:`: Adding/updating tests
- `chore:`: Maintenance tasks

**Examples**:
```
feat(analytic): add ABSA sentiment analysis
fix(collector): handle Redis connection errors
docs(identity): update API authentication guide
refactor(scrapper): extract common crawler logic
```

---

## Domain Context

### Core Concepts

#### Projects
- **Purpose**: Track brand và competitor analysis
- **Lifecycle**: Draft → Active → Completed/Archived/Cancelled
- **Components**: Brand keywords, competitor names, date ranges
- **Isolation**: Users chỉ access được projects của mình

#### Crawl Jobs
- **Types**: `research_keyword`, `crawl_links`, `research_and_crawl`
- **Platforms**: TikTok, YouTube, Instagram
- **State**: pending → processing → completed/failed
- **Tracking**: MongoDB với job metadata

#### Analytics Pipeline
1. **Preprocessing**: Text normalization, content merging
2. **Intent Classification**: 7-category classification (CRISIS, SEEDING, SPAM, etc.)
3. **Keyword Extraction**: SpaCy-YAKE hybrid approach
4. **Sentiment Analysis**: PhoBERT ONNX (5-class rating)
5. **ABSA**: Aspect-based sentiment (DESIGN, PERFORMANCE, PRICE, SERVICE, GENERAL)
6. **Impact Calculation**: Impact score (0-100) và risk level

#### Events Flow
```
Project Created → Collector → Crawler → Data Collected → Analytics → Results Published
```

**Key Events**:
- `project.created`: Trigger crawl jobs
- `data.collected`: Trigger analytics processing
- `analyze.result`: Analytics completion notification

---

## Important Constraints

### Technical Constraints

#### Performance
- **Analytics**: <100ms per sentiment prediction
- **Transcription**: 4-5x faster than realtime
- **Crawling**: Configurable limits (default 50 items/keyword)
- **API**: Response time <500ms for standard queries

#### Scalability
- **Horizontal Scaling**: All services support multiple replicas
- **Stateless Design**: Services không maintain session state
- **Database**: Connection pooling với configurable pool sizes
- **Queue**: Prefetch limits để prevent memory exhaustion

#### Security
- **Authentication**: HttpOnly cookies (không expose JWT trong URLs)
- **CORS**: Environment-based (production/staging/dev)
- **Input Validation**: Pydantic (Python) và go-playground/validator (Go)
- **SQL Injection**: Parameterized queries (SQLBoiler, SQLAlchemy)

#### Data Retention
- **Soft Delete**: Data retention cho audit purposes
- **Media Storage**: MinIO với configurable retention policies
- **Job History**: MongoDB với TTL indexes (optional)

### Business Constraints

#### Rate Limiting
- **Crawling**: Platform-specific limits (TikTok, YouTube)
- **API**: Configurable rate limits per endpoint
- **LLM**: API key quotas (Gemini, etc.)

#### Resource Limits
- **Memory**: Model loading (PhoBERT ~200-300MB, Whisper ~500MB-2GB)
- **Storage**: MinIO bucket quotas
- **Database**: Connection limits và query timeouts

---

## External Dependencies

### Infrastructure Services

#### PostgreSQL
- **Purpose**: Primary database cho Identity, Project, Analytic services
- **Versions**: 15+
- **Features**: JSONB support, full-text search, connection pooling

#### MongoDB
- **Purpose**: Document storage cho Scrapper services (videos, comments, jobs)
- **Versions**: 6.x+
- **Features**: TTL indexes, aggregation pipelines, change streams

#### Redis
- **Purpose**: 
  - State management (project progress)
  - Pub/Sub (WebSocket notifications)
  - Job state (Speech2Text async jobs)
- **Versions**: 7.0+
- **Features**: Pub/Sub, TTL, persistence

#### RabbitMQ
- **Purpose**: Message broker cho event-driven architecture
- **Versions**: 3.x
- **Features**: Topic exchanges, durable queues, message TTL

#### MinIO
- **Purpose**: S3-compatible object storage
- **Use Cases**:
  - Media files (audio, video)
  - Model artifacts (PhoBERT, Whisper)
  - Compressed data archives (Zstd)
- **Features**: Bucket policies, presigned URLs, compression metadata

### External APIs

#### Social Media Platforms
- **TikTok**: Browser automation (không có official API)
- **YouTube**: yt-dlp (không cần API key)
- **Instagram**: Legacy scraper (production)

#### AI/ML Services
- **PhoBERT**: Vietnamese BERT model (vinai/phobert-base)
- **Whisper**: OpenAI Whisper (via Whisper.cpp)
- **SpaCy**: NLP library với pre-trained models
- **YAKE**: Keyword extraction algorithm

#### LLM Providers
- **Gemini**: Keyword suggestions (Project Service)
- **Configurable**: Model và API key via environment variables

### Development Tools

#### Package Managers
- **Python**: `uv` (preferred), `pip` (fallback)
- **Go**: `go mod`
- **Node.js**: `npm`

#### Build Tools
- **Docker**: Multi-stage builds, distroless images
- **Make**: Common commands (`make run-api`, `make test`)
- **CI/CD**: GitHub Actions (if configured)

---

## Service Communication

### Event-Driven Integration

#### RabbitMQ Exchanges
- **`smap.events`**: Domain events (project.created, data.collected)
- **`collector.inbound`**: Crawl requests (legacy)
- **`results.inbound`**: Analysis results

#### Redis Channels
- **`user_noti:{user_id}`**: User-specific notifications
- **`project:{project_id}`**: Project progress updates

### HTTP APIs

#### Authentication
- **Identity Service**: `/identity/authentication/*`
- **Cookie**: `smap_auth_token` (HttpOnly, Secure, SameSite=Lax)

#### Service Endpoints
- **Analytic**: `/analytics/*` (posts, trends, keywords, alerts)
- **Project**: `/project/*` (CRUD operations)
- **Identity**: `/identity/*` (auth, plans, subscriptions)
- **Speech2Text**: `/transcribe` (sync), `/api/transcribe` (async)

### WebSocket
- **Endpoint**: `/ws` (WebSocket Service)
- **Authentication**: HttpOnly cookie (automatic)
- **Protocol**: JSON messages với `type` và `payload`

---

## Deployment

### Environment Configuration

#### Environment Variables
- **`ENV`**: `production` | `staging` | `dev` (controls CORS, security)
- **`DEBUG`**: `true` | `false` (logging verbosity)
- **`LOG_LEVEL`**: `DEBUG` | `INFO` | `WARNING` | `ERROR`

#### Service-Specific Configs
- Database URLs, connection pools
- RabbitMQ URLs, queue names
- MinIO endpoints, credentials
- JWT secrets, cookie settings
- Model paths, AI configurations

### Containerization
- **Docker**: Multi-stage builds, distroless images
- **Docker Compose**: Development environments
- **Kubernetes**: Production deployments với manifests

### Scaling Strategy
- **Stateless Services**: Horizontal scaling (multiple replicas)
- **Stateful Services**: Single replica hoặc stateful sets
- **Workers**: Configurable concurrency và prefetch limits
