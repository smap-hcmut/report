# Service: Ingest Service

> **Template Version**: 1.0  
> **Last Updated**: 03/03/2026  
> **Status**: 🚧 In Development

---

## 🎯 Business Context

### Chức năng chính

Ingest Service là service chịu trách nhiệm thu nhận dữ liệu đầu vào từ nhiều nguồn, chuẩn hóa dữ liệu về một chuẩn thống nhất, và đẩy tiếp sang Analysis.

Phạm vi chính:

- Quản lý `data source` cho từng `project`
- Nhận cấu hình crawl, file upload, webhook
- Gửi task crawl qua RabbitMQ cho bên thứ 3
- Nhận raw result, lưu MinIO, parse và map sang UAP
- Publish dữ liệu chuẩn hóa qua Kafka topic `smap.collector.output`
- Nhận command/event từ `project-srv` để đồng bộ lifecycle và adaptive crawl

### Luồng xử lý

```
User / Project Service
    → Create / Update Data Source
    → Dry Run / Mapping Confirmation
    → Scheduler or Manual Trigger
    → RabbitMQ → 3rd-party crawler
    → Raw file to MinIO + response callback
    → Parse / Transform / Validate
    → Publish UAP to Kafka (smap.collector.output)
```

### Giá trị cốt lõi

- Tách ownership `data source` ra khỏi `project-srv`, giữ boundary rõ ràng
- Chuẩn hóa dữ liệu đa nguồn về một chuẩn UAP duy nhất cho Analysis
- Hỗ trợ adaptive crawl theo tín hiệu khủng hoảng từ `project-srv`
- Tạo nền tảng mở rộng cho TikTok trước, sau đó Facebook / YouTube / file upload / webhook

---

## 🛠 Technical Details

### Protocol & Architecture

- **Protocol**: REST API + Kafka + RabbitMQ
- **Pattern**: Microservices + Event-Driven
- **Design**: Layered / Clean Architecture với module theo domain

### Tech Stack

| Component | Technology | Version | Purpose |
| --------- | ---------- | ------- | ------- |
| Language | Go | 1.25.6 | Backend service |
| Framework | Gin | 1.11.0 | HTTP routing |
| Database | PostgreSQL | 15-alpine (local infra) | Primary data store |
| Cache | Redis | 7-alpine (local infra) | Runtime cache / support services |
| Queue | Kafka + RabbitMQ | cp-kafka 7.5.0 / rabbitmq 3.13 | Event bus + crawler integration |
| Storage | MinIO | latest | Raw file storage |
| ORM | SQLBoiler | 4.19.7 | DB access generation |
| Scheduler | robfig/cron | 3.0.1 | Heartbeat scheduling |

### Database Schema

#### PostgreSQL Tables

**1. `schema_ingest.data_sources`** - Bảng trung tâm quản lý lifecycle và config của source

```sql
CREATE TABLE schema_ingest.data_sources (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    source_type schema_ingest.source_type NOT NULL,
    source_category schema_ingest.source_category NOT NULL,
    status schema_ingest.source_status NOT NULL DEFAULT 'PENDING',
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    mapping_rules JSONB,
    onboarding_status schema_ingest.onboarding_status NOT NULL DEFAULT 'NOT_REQUIRED',
    dryrun_status schema_ingest.dryrun_status NOT NULL DEFAULT 'NOT_REQUIRED',
    dryrun_last_result_id UUID,
    crawl_mode schema_ingest.crawl_mode,
    crawl_interval_minutes INTEGER,
    next_crawl_at TIMESTAMPTZ,
    webhook_id VARCHAR(255),
    webhook_secret_encrypted TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
-- Indexes: project_id, status+category, next_crawl_at (partial), config GIN, mapping_rules GIN
```

**2. `schema_ingest.dryrun_results`** - Lưu lịch sử validate/dry-run của source

```sql
CREATE TABLE schema_ingest.dryrun_results (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES schema_ingest.data_sources(id),
    project_id UUID NOT NULL,
    job_id VARCHAR(255),
    status schema_ingest.dryrun_status NOT NULL DEFAULT 'PENDING',
    sample_count INTEGER NOT NULL DEFAULT 0,
    total_found INTEGER,
    sample_data JSONB,
    warnings JSONB,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**3. `schema_ingest.scheduled_jobs`** - Ghi nhận từng lần scheduler tạo job

```sql
CREATE TABLE schema_ingest.scheduled_jobs (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES schema_ingest.data_sources(id),
    project_id UUID NOT NULL,
    status schema_ingest.job_status NOT NULL DEFAULT 'PENDING',
    trigger_type schema_ingest.trigger_type NOT NULL,
    crawl_mode schema_ingest.crawl_mode NOT NULL,
    scheduled_for TIMESTAMPTZ NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**4. `schema_ingest.external_tasks`** - Track request/response với crawler bên thứ 3

```sql
CREATE TABLE schema_ingest.external_tasks (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES schema_ingest.data_sources(id),
    project_id UUID NOT NULL,
    scheduled_job_id UUID REFERENCES schema_ingest.scheduled_jobs(id),
    task_id UUID NOT NULL UNIQUE,
    platform VARCHAR(50) NOT NULL,
    task_type VARCHAR(100) NOT NULL,
    routing_key VARCHAR(100) NOT NULL,
    request_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status schema_ingest.job_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**5. `schema_ingest.raw_batches`** - Track raw file/batch và publish lifecycle

```sql
CREATE TABLE schema_ingest.raw_batches (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES schema_ingest.data_sources(id),
    project_id UUID NOT NULL,
    external_task_id UUID REFERENCES schema_ingest.external_tasks(id),
    batch_id VARCHAR(255) NOT NULL,
    status schema_ingest.batch_status NOT NULL DEFAULT 'RECEIVED',
    storage_bucket VARCHAR(100) NOT NULL,
    storage_path TEXT NOT NULL,
    publish_status schema_ingest.publish_status NOT NULL DEFAULT 'PENDING',
    publish_record_count INTEGER NOT NULL DEFAULT 0,
    uap_published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_id, batch_id)
);
```

**6. `schema_ingest.crawl_mode_changes`** - Audit trail cho adaptive crawl

```sql
CREATE TABLE schema_ingest.crawl_mode_changes (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES schema_ingest.data_sources(id),
    project_id UUID NOT NULL,
    trigger_type schema_ingest.trigger_type NOT NULL,
    from_mode schema_ingest.crawl_mode NOT NULL,
    to_mode schema_ingest.crawl_mode NOT NULL,
    from_interval_minutes INTEGER NOT NULL,
    to_interval_minutes INTEGER NOT NULL,
    event_ref VARCHAR(255),
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**7. `schema_ingest.crawl_mode_defaults`** - Bảng config default interval theo mode

```sql
CREATE TABLE schema_ingest.crawl_mode_defaults (
    mode schema_ingest.crawl_mode PRIMARY KEY,
    interval_minutes INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Gap schema đã xác định**:

- Thiết kế hiện tại mới đủ cho V1 per-datasource
- Theo [gap_analysis.md](/mnt/f/SMAP_v2/ingest-srv/documents/gap_analysis.md), nếu cần crawl nhiều target với tần suất riêng trong cùng 1 datasource thì cần thêm bảng `crawl_targets`
- Khi đó scheduler, dry run, và external task nên chuyển dần sang per-target

---

## 📡 API Endpoints

### Domain/Module 1: Data Source Management

#### `POST /sources`

**Purpose**: Tạo mới một data source thuộc project

**Authentication**: JWT / internal auth theo middleware hiện có

**Request**:

```json
{
  "project_id": "uuid",
  "name": "TikTok Da Lat Monitoring",
  "source_type": "TIKTOK",
  "source_category": "CRAWL",
  "config": {
    "max_results": 100,
    "comment_limit": 50
  }
}
```

**Response** (Success):

```json
{
  "id": "uuid",
  "status": "PENDING",
  "project_id": "uuid"
}
```

**Business Logic Flow**:

1. Validate payload và rule `source_type`/`source_category`
2. Tạo `data_sources` với trạng thái `PENDING`
3. Publish `ingest.source.created`
4. Trả source vừa tạo

#### `PUT /sources/:id`

**Purpose**: Update metadata/config/mapping theo state guard

**Authentication**: JWT / internal auth

**Business Rules chính**:

1. `name`, `description` có thể sửa mọi lúc
2. `config`, `mapping_rules`, `source_type` không được sửa tự do khi source đang `ACTIVE`
3. Nếu thay đổi field ảnh hưởng runtime thì phải reset `dryrun_status` và clear `dryrun_last_result_id`

#### `POST /sources/file-upload`

**Purpose**: Upload file, lưu MinIO và tạo source `FILE_UPLOAD`

**Authentication**: JWT

**Business Logic Flow**:

1. Nhận file
2. Upload raw lên MinIO
3. Tạo `data_source` loại `FILE_UPLOAD`
4. Chờ flow mapping preview/confirm

#### `POST /sources/:id/mapping/preview`

**Purpose**: Phân tích sample file/payload và gợi ý `mapping_rules`

**Authentication**: JWT / internal auth

**Business Logic Flow**:

1. Đọc sample từ MinIO hoặc payload đã nhận
2. Phân tích field/header
3. Tạo preview mapping theo UAP target paths
4. Trả về sample data + suggested mapping

#### `PUT /sources/:id/mapping`

**Purpose**: Confirm hoặc update `mapping_rules` cho passive source

**Authentication**: JWT / internal auth

**Business Logic Flow**:

1. Validate JSON shape của mapping
2. Lưu `data_sources.mapping_rules`
3. Update `onboarding_status`
4. Đưa source sang trạng thái sẵn sàng nếu đủ điều kiện

#### `POST /sources/:id/webhook/bootstrap`

**Purpose**: Sinh `webhook_id` và secret cho source webhook

**Authentication**: JWT / internal auth

**Business Logic Flow**:

1. Validate source là `WEBHOOK`
2. Sinh `webhook_id`
3. Sinh và mã hóa secret
4. Lưu vào `data_sources`

#### `PUT /ingest/sources/:id/crawl-mode`

**Purpose**: Internal API để `project-srv` đổi `crawl_mode`

**Authentication**: Internal service auth

**Business Logic Flow**:

1. Validate source thuộc project và là crawl source
2. Đổi `crawl_mode` + `crawl_interval_minutes`
3. Ghi `crawl_mode_changes`
4. Re-register scheduler nếu cần
5. Publish `ingest.crawl_mode.changed`

### Domain/Module 2: Dry Run & Onboarding

#### `POST /sources/:id/dryrun`

**Purpose**: Chạy validate thử trước khi source vào `READY`

**Authentication**: JWT / internal auth

**Business Logic Flow**:

1. Chỉ cho source `PENDING` hoặc `READY`
2. Nếu là crawl source, tạo `external_task` giới hạn với `scheduled_job_id = NULL`
3. Nếu là file upload, parse sample
4. Lưu `dryrun_results`
5. Update `dryrun_status` và `dryrun_last_result_id`
6. Publish `ingest.dryrun.completed`

### Domain/Module 3: Internal Operations

#### `POST /internal/sources/:id/trigger`

**Purpose**: Manual trigger tạo task crawl ngoài scheduler

**Authentication**: Internal service auth

#### `POST /internal/raw-batches/:id/replay`

**Purpose**: Replay parse/publish cho raw batch đã lưu

**Authentication**: Internal service auth

### Domain/Module 4: Webhook Receiver

#### `POST /webhook/:webhook_id`

**Purpose**: Nhận push data từ external system vào source `WEBHOOK`

**Authentication**: Signature verification

**Business Logic Flow**:

1. Tìm source theo `webhook_id`
2. Reject nếu source `PAUSED`, `ARCHIVED`, soft-deleted hoặc signature invalid
3. Tạo `raw_batch`
4. Đưa vào parser pipeline

---

## 🔗 Integration & Dependencies

### External Services

**1. Project Service** (Upstream)

- **Method**: Kafka + HTTP
- **Purpose**: Đồng bộ lifecycle project và adaptive crawl
- **Events/Endpoints Used**:
  - Kafka: `project.activated`, `project.paused`, `project.resumed`, `project.archived`
  - HTTP inbound: `PUT /ingest/sources/:id/crawl-mode`
- **Error Handling**: Retry khi xử lý event; HTTP internal auth + retry ở caller side

**2. Third-party Crawler** (Downstream)

- **Method**: RabbitMQ + MinIO handoff
- **Purpose**: Crawl dữ liệu social platform
- **Contract Source**: [RABBITMQ.md](/mnt/f/SMAP_v2/ingest-srv/documents/resource/ingest-intergrate-3rdparty/RABBITMQ.md)
- **Error Handling**: Track qua `external_tasks`, lưu lỗi vào `error_message`, hỗ trợ manual trigger / replay

**3. Analysis Service** (Downstream)

- **Method**: Kafka
- **Purpose**: Nhận dữ liệu UAP chuẩn hóa để phân tích
- **Topic**: `smap.collector.output`
- **Contract**: 1 UAP message = 1 đơn vị phân tích (`post`, `comment`, `reply`)

### Infrastructure Dependencies

**Message Queue**

```text
Kafka Topics:
- smap.collector.output      -> UAP output sang Analysis
- ingest.events              -> service event topic hiện có trong config
- project.*                  -> lifecycle events từ project-srv

RabbitMQ:
- publish task crawl theo contract RABBITMQ.md
- consume response callback từ crawler
```

**Storage**

```text
MinIO bucket:
- ingest-data -> lưu raw files / uploaded files / crawler outputs
```

**Database**

```text
Database: PostgreSQL
Schema: schema_ingest
Migrations:
- 001_create_schema_ingest_v1.sql
- 002_seed_ingest_defaults.sql
```

---

## 🎨 Key Features & Highlights

### 1. Unified UAP Output

**Description**: Tất cả raw data từ crawl, file upload, webhook đều được chuẩn hóa về UAP trước khi sang Analysis.

**Implementation**:

- `mapping_rules` JSONB cho passive source
- parser pipeline tách `batch_status` và `publish_status`
- giữ `raw.original_fields` + `trace.raw_ref` để audit/reprocess

**Benefits**:

- Analysis chỉ cần consume 1 chuẩn duy nhất
- Giảm coupling giữa platform raw format và downstream analytics

### 2. Adaptive Crawl Control

**Description**: `project-srv` điều chỉnh `SLEEP / NORMAL / CRISIS`, ingest áp dụng ngay vào runtime.

**Implementation**:

- internal API `PUT /ingest/sources/:id/crawl-mode`
- `crawl_mode_changes` audit log
- `crawl_mode_defaults` làm fallback interval config

**Benefits**:

- Tăng tần suất khi có tín hiệu khủng hoảng
- Giảm tải khi traffic thấp

### 3. Crawler Decoupling qua RabbitMQ

**Description**: Ingest không trực tiếp crawl social network, mà giao việc cho bên thứ 3.

**Implementation**:

- `external_tasks` để correlation request/response
- raw output lưu MinIO rồi parse bất đồng bộ
- hỗ trợ `manual trigger` và `replay`

**Benefits**:

- Tách boundary rõ giữa orchestration và crawling
- Dễ thay crawler provider sau này

### 4. Gap đã xác định: per-target crawl

**Description**: Requirement mới cho phép 1 datasource chứa nhiều target với tần suất riêng.

**Current**:

- Scheduler và state hiện tại đang per-datasource

**Problem**:

- Không CRUD target riêng lẻ tốt
- Không dry-run/thống kê tốt theo từng keyword/profile/post URL

**Direction**:

- Thêm bảng `crawl_targets`
- Scheduler per-target
- Có thể thêm `target_id` vào `external_tasks` và `dryrun_results`

---

## 🚧 Status & Roadmap

### ✅ Done (Implemented / Documented Foundation)

- [x] Schema proposal `v1.3` chốt ownership, contracts, business rules
- [x] Migration `001_create_schema_ingest_v1.sql`
- [x] Seed `002_seed_ingest_defaults.sql`
- [x] SQLBoiler config cho prod-like và local
- [x] Local infra config với Docker Compose
- [x] Domain models cho core tables
- [x] Implementation plan `v1.1`
- [x] Gap analysis cho crawl per-target

### 🔄 In Progress

- [ ] Repository / usecase implementation cho datasource
- [ ] API layer cho source CRUD và onboarding
- [ ] Scheduler + crawler integration runtime
- [ ] Parser pipeline + Kafka publisher
- [ ] Webhook receiver

### 📋 Todo (Planned)

- [ ] Thêm `crawl_targets` nếu chốt per-target scheduling là bắt buộc
- [ ] DTO/request-response contracts chi tiết cho từng endpoint
- [ ] Monitoring + metrics + readiness checks
- [ ] Integration tests end-to-end
- [ ] Load testing

### 🐛 Known Bugs

- [ ] Chưa có benchmark runtime thật - Severity: Medium
- [ ] Chưa có implementation đầy đủ cho FILE_UPLOAD onboarding AI mapping - Severity: Medium
- [ ] Thiết kế scheduler hiện tại vẫn ở level datasource, chưa cover per-target - Severity: High nếu requirement mới được giữ

---

## ⚠️ Known Issues & Limitations

### 1. Scalability / Scheduling Granularity

**Issue**: Thiết kế V1 hiện tại chạy scheduler ở level datasource, chưa phải level target.

- **Current**: `data_sources` giữ `crawl_interval_minutes`, `next_crawl_at`, `last_crawl_at`
- **Problem**: Không hỗ trợ nhiều target trong cùng datasource với tần suất khác nhau
- **Impact**: Keyword/profile/post URL không thể tối ưu lịch crawl riêng
- **Workaround**: Tạm tách nhiều datasource khác nhau cho từng nhóm target nếu cần
- **TODO**: Bổ sung `crawl_targets` và chuyển scheduler sang per-target

### 2. FILE_UPLOAD Onboarding

**Issue**: Schema và mapping rules đã sẵn sàng, nhưng flow AI-assisted mapping chưa implement runtime.

- **Current**: Có `mapping_rules`, `onboarding_status`, preview/confirm đã có trong plan
- **Problem**: Chưa có AI analyze thật và UX human-in-the-loop hoàn chỉnh
- **Impact**: File upload mới dừng ở mức thiết kế / bootstrap
- **Workaround**: Cho phép map thủ công hoặc postpone use case này trong V1
- **TODO**: Tích hợp AI schema detection + mapping suggestion

### 3. Completion Event Ambiguity cũ

**Issue**: Một số tài liệu cũ nhắc `ingest.data.first_batch`, trong khi proposal mới dùng `ingest.crawl.completed`.

- **Current**: Canonical event đã chốt là `ingest.crawl.completed`
- **Problem**: Nếu service khác bám theo tài liệu cũ sẽ lệch contract
- **Impact**: Lệch integration giữa services
- **Workaround**: Chỉ coi `ingest.crawl.completed` là contract mới
- **TODO**: Đồng bộ tài liệu cũ nếu còn tồn tại chỗ nào khác

---

## 🔮 Future Enhancements

### Short-term (1-2 months)

- [ ] Hoàn thiện datasource CRUD + dryrun + onboarding endpoints
- [ ] Hoàn thiện RabbitMQ crawler integration và parser pipeline
- [ ] Hoàn thiện project event sync + adaptive crawl

### Mid-term (3-6 months)

- [ ] Bổ sung `crawl_targets` nếu requirement per-target được chốt
- [ ] AI-assisted mapping cho file upload/webhook
- [ ] Monitoring dashboard + alerting + replay tooling

### Long-term (6+ months)

- [ ] Hỗ trợ đầy đủ Facebook / YouTube / nguồn passive khác
- [ ] Bổ sung media intelligence pipeline (OCR/ASR trên raw media)
- [ ] Tối ưu dedup, lineage, và data quality scoring

---

## 🔧 Configuration

**Files**:

- `config/ingest-config.yaml`
- `config/ingest-config.local.yaml`

```yaml
environment:
  name: development

http_server:
  host: 0.0.0.0
  port: 8080
  mode: debug

postgres:
  host: 172.16.19.10
  port: 5432
  user: ingest_master
  dbname: smap
  schema: schema_ingest

redis:
  host: redis.tantai.dev
  port: 6379

minio:
  endpoint: 172.16.21.10:9000
  bucket: ingest-data

kafka:
  brokers:
    - kafka.tantai.dev:9094
  topic: ingest.events
  group_id: ingest-consumer

rabbitmq:
  url: amqp://admin:***@172.16.21.206:5672/

scheduler:
  heartbeat_cron: "*/1 * * * *"
  timezone: Asia/Ho_Chi_Minh
```

**Environment Variables**:

```bash
# Required
INGEST_CONFIG_FILE=./config/ingest-config.local.yaml

# Runtime
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=ingest_master
POSTGRES_DBNAME=smap
KAFKA_BROKERS=127.0.0.1:9092
RABBITMQ_URL=amqp://admin:***@127.0.0.1:5672/
```

---

## 📊 Performance Metrics

### Estimated Performance

**Note**: Chưa có load test thực tế. Đây là đánh giá theo design hiện tại.

- **Source CRUD / dryrun metadata APIs**: low-latency, chủ yếu bound bởi PostgreSQL
- **Scheduler tick**: chạy mỗi 1 phút, query theo partial index `next_crawl_at`
- **Crawler integration**: latency phụ thuộc chủ yếu vào bên thứ 3 và MinIO handoff
- **Parser pipeline**: throughput phụ thuộc kích thước raw batch và số record UAP sinh ra
- **TODO**: chạy benchmark cho parse batch TikTok nhiều post/comment/reply

---

## 🔐 Security

### Authentication

- **Method**: JWT cho user-facing API, internal key cho internal service calls
- **Token Storage**: Cookie / header tùy middleware hiện có
- **Internal Auth**: `internal.internal_key` trong config

### Authorization

- **Model**: Scope-based / service-to-service validation theo middleware hiện có
- **Critical Internal APIs**:
  - `PUT /ingest/sources/:id/crawl-mode`
  - `POST /internal/sources/:id/trigger`
  - `POST /internal/raw-batches/:id/replay`

### Data Protection

- **Encryption at Rest**: webhook secret lưu dạng encrypted field
- **Encryption in Transit**: phụ thuộc deployment TLS/reverse proxy
- **Sensitive Data**: raw payload lưu MinIO, cần kiểm soát access bucket
- **Secrets Management**: hiện đang qua config/env; production nên chuyển sang secret manager

### Security Best Practices

- [x] Input validation and sanitization
- [x] SQL injection prevention qua SQLBoiler/query mods
- [ ] CSRF protection nếu có browser cookie flow
- [ ] Rate limiting cho webhook/public APIs
- [x] Internal API authentication
- [x] Audit logging qua DB tables (`crawl_mode_changes`, task/batch history)
- [ ] Dependency scanning
- [ ] Security headers

---

## 🧪 Testing

### Test Coverage

- **Unit Tests**: Chưa chốt coverage
- **Integration Tests**: Planned
- **E2E Tests**: Planned
- **Load Tests**: Planned

### Running Tests / Local Runtime

```bash
# Generate models
make models-local

# Run local infra
docker compose up -d

# Run API
make run-api-local

# Run consumer
make run-consumer-local

# Run scheduler
make run-scheduler-local
```

### Test Strategy

- **Unit Tests**: usecase/repository logic, state transitions, mapping validation
- **Integration Tests**: PostgreSQL + RabbitMQ + Kafka + MinIO local stack
- **Critical Scenarios**:
  - source lifecycle
  - dryrun success/warning/fail
  - external task request/response
  - raw batch parse/publish lifecycle
  - crawl mode change audit log
  - webhook reject rules

---

## 🚀 Deployment

### Docker

```bash
# Local infra
cd ingest-srv
docker compose up -d

# Local runtime
make run-api-local
make run-consumer-local
make run-scheduler-local
```

### CI/CD Pipeline

```yaml
# Planned
name: Ingest CI
on:
  push:
    branches: [main]
jobs:
  test-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: make test
      - name: Build
        run: docker build -t ingest-srv .
```

---

## 📚 Documentation

### Architecture Docs

- [Gap Analysis](/mnt/f/SMAP_v2/ingest-srv/documents/gap_analysis.md)
- [Ingest Design Notes](/mnt/f/SMAP_v2/ingest-srv/documents/resource/ingest/ingest_des.md)
- [Schema Alignment Proposal](/mnt/f/SMAP_v2/ingest-srv/documents/resource/ingest/ingest_project_schema_alignment_proposal.md)
- [Implementation Plan](/mnt/f/SMAP_v2/ingest-srv/documents/resource/ingest/ingest_plan.md)
- [3rd-party RabbitMQ Contract](/mnt/f/SMAP_v2/ingest-srv/documents/resource/ingest-intergrate-3rdparty/RABBITMQ.md)

### Developer Guides

- `Makefile` targets cho local runtime
- `docker-compose.yml` cho local infrastructure
- `sqlboiler.toml` / `sqlboiler.local.toml` cho model generation

---

## 📝 Changelog

### 1.0 - 03/03/2026

**Added**

- Tạo report tổng hợp cho ingest service theo template chuẩn
- Tổng hợp schema proposal v1.3, implementation plan v1.1, gap analysis hiện tại
- Bổ sung quyết định mới về passive onboarding, internal ops endpoints, canonical events

**Changed**

- Phản ánh gap mới: scheduler per-target qua `crawl_targets`
- Đồng bộ contract chính thức với `RABBITMQ.md`

**Deprecated**

- `ingest.data.first_batch` không còn là contract mới được khuyến nghị

---

## 📋 Appendix

### Glossary

- **UAP**: Unified Analysis Payload, chuẩn message đầu vào cho Analysis
- **Dry Run**: Chạy thử source để xác nhận cấu hình usable trước khi vận hành thật
- **Passive Source**: Source nhận dữ liệu từ file upload hoặc webhook, không tự crawl
- **Crawl Source**: Source chủ động gửi task đi crawl theo lịch

### Related Services

- **project-srv**: owner của project lifecycle, crisis config, adaptive crawl decision
- **analysis-srv**: consume UAP từ `smap.collector.output`
- **notification-srv**: downstream nhận crisis alert từ `project-srv`

---

**Document Version**: 1.0  
**Last Updated**: 03/03/2026  
**Maintained By**: Ingest Service Team  
**Review Cycle**: Weekly during implementation

---

## 📌 Quick Reference Card

```text
Service: ingest-srv
Port: 8080
Config: config/ingest-config.yaml / config/ingest-config.local.yaml
Schema: schema_ingest
Output Topic: smap.collector.output
3rd-party Contract: documents/resource/ingest-intergrate-3rdparty/RABBITMQ.md

Quick Start:
1. docker compose up -d
2. make models-local
3. make run-api-local
4. make run-consumer-local
5. make run-scheduler-local

Core Decisions:
- ingest-srv owns data_sources
- project-srv controls project lifecycle and adaptive crawl decision
- 1 UAP = 1 analysis unit
- crawl per-target is an identified next schema evolution
```
