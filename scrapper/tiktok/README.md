# TikTok Scraper Worker

A robust TikTok data scraper built with Clean Architecture principles. The worker receives tasks from RabbitMQ, scrapes TikTok data using Playwright and HTTP APIs, and persists results to MongoDB with media files uploaded to MinIO.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [System Architecture Diagrams](#system-architecture-diagrams)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Worker](#running-the-worker)
- [Task Types](#task-types)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Deployment Guide](#deployment-guide)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)

## Architecture Overview

The scraper follows **Clean Architecture** with clear separation of concerns:

```
Producer System → RabbitMQ Queue → Worker (TaskService + CrawlerService)
    → MongoDB (metadata) + MinIO (media files)
```

### Layer Architecture

- **Domain Layer**: Pure business entities (Content, Author, Comment) with no external dependencies
- **Application Layer**: Use cases and orchestration (TaskService, CrawlerService)
- **Infrastructure Layer**: External adapters (RabbitMQ, MongoDB, Playwright, MinIO)
- **Entry Point**: Dependency injection and application bootstrap


## System Architecture Diagrams

### High-Level System Architecture

```mermaid
graph TB
    subgraph "External Systems"
        Producer[Producer Service]
        TikTok[TikTok Platform]
    end
    
    subgraph "Message Queue"
        RabbitMQ[(RabbitMQ)]
        TaskQueue[Task Queue]
        ResultExchange[Result Exchange]
    end
    
    subgraph "Worker Service"
        Worker[TikTok Worker]
        TaskService[Task Service]
        CrawlerService[Crawler Service]
    end
    
    subgraph "Scrapers"
        VideoAPI[Video API]
        CreatorAPI[Creator API]
        CommentScraper[Comment Scraper]
        SearchScraper[Search Scraper]
        ProfileScraper[Profile Scraper]
    end
    
    subgraph "Storage Layer"
        MongoDB[(MongoDB)]
        MinIO[(MinIO S3)]
    end
    
    subgraph "External Services"
        Playwright[Playwright Service]
        FFmpeg[FFmpeg Service]
        STT[Speech-to-Text API]
    end
    
    Producer -->|Publish Task| RabbitMQ
    RabbitMQ --> TaskQueue
    TaskQueue -->|Consume| Worker
    Worker --> TaskService
    TaskService --> CrawlerService
    
    CrawlerService --> VideoAPI
    CrawlerService --> CreatorAPI
    CrawlerService --> CommentScraper
    CrawlerService --> SearchScraper
    CrawlerService --> ProfileScraper
    
    VideoAPI -->|HTTP API| TikTok
    CreatorAPI -->|HTTP API| TikTok
    CommentScraper -->|Playwright| Playwright
    SearchScraper -->|Playwright| Playwright
    ProfileScraper -->|REST API| Playwright
    
    CrawlerService -->|Save Metadata| MongoDB
    CrawlerService -->|Upload Media| MinIO
    CrawlerService -->|Convert Media| FFmpeg
    CrawlerService -->|Transcribe| STT
    
    TaskService -->|Publish Result| ResultExchange
    ResultExchange --> RabbitMQ
    
    style Worker fill:#4CAF50
    style MongoDB fill:#47A248
    style MinIO fill:#C72E49
    style RabbitMQ fill:#FF6600
```

### Data Flow Sequence

```mermaid
sequenceDiagram
    participant P as Producer
    participant RMQ as RabbitMQ
    participant W as Worker
    participant TS as TaskService
    participant CS as CrawlerService
    participant TT as TikTok API
    participant PW as Playwright
    participant DB as MongoDB
    participant S3 as MinIO
    participant STT as Speech2Text
    
    P->>RMQ: Publish Task (crawl_links)
    RMQ->>W: Consume Message
    W->>TS: handle_task()
    TS->>DB: Create Job Record
    TS->>CS: fetch_videos_batch()
    
    par Parallel Scraping
        CS->>TT: Scrape Video Metadata
        TT-->>CS: Video Data
        CS->>TT: Scrape Creator Info
        TT-->>CS: Creator Data
        CS->>PW: Scrape Comments
        PW-->>CS: Comments Data
    end
    
    CS->>S3: Download & Upload Media
    S3-->>CS: Media Path
    
    CS->>STT: Transcribe Audio
    STT-->>CS: Transcription
    
    CS->>DB: Save Content
    CS->>DB: Save Author
    CS->>DB: Save Comments
    
    CS-->>TS: CrawlResult
    TS->>DB: Update Job Status
    TS->>RMQ: Publish Result
    RMQ-->>P: Result Message
```

### Clean Architecture Layers

```mermaid
graph TB
    subgraph "Entry Point"
        Main[main.py]
        Bootstrap[bootstrap.py]
        WorkerService[worker_service.py]
    end
    
    subgraph "Application Layer"
        TaskService[TaskService]
        CrawlerService[CrawlerService]
        Interfaces[Interfaces/Ports]
    end
    
    subgraph "Domain Layer"
        Content[Content Entity]
        Author[Author Entity]
        Comment[Comment Entity]
        Enums[Enums]
    end
    
    subgraph "Infrastructure Layer - Adapters"
        VideoScraper[VideoAPI]
        CreatorScraper[CreatorAPI]
        CommentScraper[CommentScraper]
        SearchScraper[SearchScraper]
        ProfileScraper[ProfileScraper]
        MediaDownloader[MediaDownloader]
    end
    
    subgraph "Infrastructure Layer - Repositories"
        ContentRepo[ContentRepository]
        AuthorRepo[AuthorRepository]
        CommentRepo[CommentRepository]
    end
    
    subgraph "Infrastructure Layer - External"
        RabbitMQ[RabbitMQ Consumer]
        MongoDB[MongoDB Client]
        MinIO[MinIO Storage]
        Playwright[Playwright Browser]
    end
    
    Main --> Bootstrap
    Bootstrap --> WorkerService
    WorkerService --> TaskService
    TaskService --> CrawlerService
    CrawlerService --> Interfaces
    
    Interfaces -.implements.-> VideoScraper
    Interfaces -.implements.-> CreatorScraper
    Interfaces -.implements.-> CommentScraper
    Interfaces -.implements.-> SearchScraper
    Interfaces -.implements.-> ProfileScraper
    Interfaces -.implements.-> MediaDownloader
    Interfaces -.implements.-> ContentRepo
    Interfaces -.implements.-> AuthorRepo
    Interfaces -.implements.-> CommentRepo
    
    CrawlerService --> Content
    CrawlerService --> Author
    CrawlerService --> Comment
    
    VideoScraper --> MongoDB
    ContentRepo --> MongoDB
    AuthorRepo --> MongoDB
    CommentRepo --> MongoDB
    MediaDownloader --> MinIO
    CommentScraper --> Playwright
    SearchScraper --> Playwright
    ProfileScraper --> Playwright
    WorkerService --> RabbitMQ
    
    style Main fill:#FF6B6B
    style TaskService fill:#4ECDC4
    style CrawlerService fill:#4ECDC4
    style Content fill:#95E1D3
    style Author fill:#95E1D3
    style Comment fill:#95E1D3
```


### Component Interaction Flow

```mermaid
graph LR
    subgraph "Bootstrap Phase"
        B1[Initialize MongoDB]
        B2[Initialize Playwright]
        B3[Initialize Scrapers]
        B4[Initialize Services]
        B1 --> B2 --> B3 --> B4
    end
    
    subgraph "Task Processing"
        T1[Receive Task]
        T2[Create Job]
        T3[Route to Handler]
        T4[Execute Crawl]
        T5[Save Results]
        T6[Update Job]
        T1 --> T2 --> T3 --> T4 --> T5 --> T6
    end
    
    subgraph "Crawl Execution"
        C1[Scrape Video]
        C2[Download Media]
        C3[Scrape Creator]
        C4[Scrape Comments]
        C5[Transcribe Audio]
        C1 --> C2
        C1 --> C3
        C1 --> C4
        C2 --> C5
    end
    
    B4 --> T1
    T4 --> C1
```

### Data Model Relationships

```mermaid
erDiagram
    CONTENT ||--o{ COMMENT : "has many"
    CONTENT }o--|| AUTHOR : "created by"
    COMMENT }o--|| CONTENT : "belongs to"
    COMMENT ||--o{ COMMENT : "has replies"
    CRAWL_JOB ||--o{ CONTENT : "produces"
    SEARCH_SESSION ||--o{ CONTENT : "finds"
    
    CONTENT {
        string source
        string external_id
        string url
        string job_id
        string author_id
        string description
        int duration_seconds
        string media_path
        int view_count
        int like_count
        datetime published_at
        datetime crawled_at
    }
    
    AUTHOR {
        string source
        string external_id
        string username
        string display_name
        int follower_count
        int video_count
        datetime crawled_at
    }
    
    COMMENT {
        string source
        string external_id
        string parent_type
        string parent_id
        string comment_text
        int like_count
        datetime published_at
    }
    
    CRAWL_JOB {
        string job_id
        string task_type
        string status
        json payload
        array minio_keys
        datetime created_at
    }
    
    SEARCH_SESSION {
        string keyword
        array video_urls
        string sort_by
        string job_id
        datetime created_at
    }
```

## Features

- **Five Task Types**: `research_keyword`, `crawl_links`, `research_and_crawl`, `fetch_profile_content`, `dryrun_keyword` with automatic retry logic
- **Comprehensive Data Collection**: Video metadata, creator profiles, comments, and search results
- **Media Download**: Audio/video download with FFmpeg support and automatic MinIO upload
- **Speech-to-Text**: Automatic audio transcription integration
- **Concurrent Processing**: Configurable concurrent workers for high throughput
- **Smart Upsert Logic**: Efficient updates that preserve static data and refresh dynamic metrics
- **Remote Playwright Service**: Isolated browser automation via WebSocket endpoint
- **Retry Mechanism**: Automatic retry up to 3 times with configurable delay
- **Job Tracking**: Complete job lifecycle tracking in MongoDB
- **Flexible Storage**: Optional MongoDB persistence and MinIO archival
- **Result Publishing**: Publish task results back to RabbitMQ for downstream processing


## Prerequisites

- **Python 3.12** (matches Dockerfile)
- **RabbitMQ 3.x** (message queue)
- **MongoDB 6.x** (data persistence)
- **MinIO** (object storage for media files)
- **FFmpeg** (for audio/video processing)
- **Playwright Chromium** (browser automation)
- **Docker & Docker Compose** (for containerized deployment)

## Installation

### 1. Clone and Navigate

```bash
cd scrapper/tiktok
```

### 2. Create Virtual Environment (Recommended)

```bash
python -m venv .venv
# On Windows
.venv\Scripts\activate
# On Linux/macOS
source .venv/bin/activate
```

### 3. Install Dependencies

Using pip:
```bash
pip install --upgrade pip
pip install -r requirements.txt
playwright install --with-deps chromium
```

Using uv (faster):
```bash
pip install uv
uv sync
playwright install --with-deps chromium
```

### 4. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your RabbitMQ, MongoDB, and MinIO credentials.

### 5. Start Infrastructure Services

Ensure RabbitMQ, MongoDB, and MinIO are running with the credentials specified in your `.env` file.

## Configuration

Key environment variables (see `.env.example` for complete list):

### RabbitMQ Settings

```bash
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/
RABBITMQ_QUEUE_NAME=tiktok_tasks
RABBITMQ_PREFETCH_COUNT=1
```

### MongoDB Settings

```bash
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=tiktok_scraper
MONGODB_USER=
MONGODB_PASSWORD=
MONGODB_AUTH_SOURCE=admin
```

### Crawler Settings

```bash
CRAWLER_MAX_CONCURRENT=8
CRAWLER_TIMEOUT=30000
CRAWLER_WAIT_AFTER_LOAD=3000
CRAWLER_SCROLL_DELAY=1500
```

### Media Download Settings

```bash
MEDIA_DOWNLOAD_ENABLED=true
MEDIA_DEFAULT_TYPE=audio
MEDIA_DOWNLOAD_DIR=./downloads
MEDIA_ENABLE_FFMPEG=true
```

### MinIO Settings

```bash
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_SECURE=false
MINIO_BUCKET_NAME=tiktok-media
MINIO_ARCHIVE_BUCKET=tiktok-archive
```

### Playwright Settings

```bash
PLAYWRIGHT_WS_ENDPOINT=  # Optional: Remote Playwright service
PLAYWRIGHT_REST_API_ENABLED=true
PLAYWRIGHT_REST_API_URL=http://localhost:8001
```

### Speech-to-Text Settings

```bash
STT_API_ENABLED=true
STT_API_URL=http://localhost/transcribe
STT_API_KEY=your-api-key
STT_TIMEOUT=300
```

### Storage Options

```bash
ENABLE_DB_PERSISTENCE=false  # Default: disable MongoDB persistence
ENABLE_JSON_ARCHIVE=true     # Default: enable MinIO archival
```


## Running the Worker

### Local Development

```bash
python -m app.main
```

The worker will:
1. Bootstrap dependencies
2. Connect to RabbitMQ queue
3. Wait for tasks
4. Process tasks as they arrive

Stop the worker with `Ctrl+C` for graceful shutdown.

### Docker Compose

From the `scrapper/` directory:

```bash
docker compose build tiktok-worker
docker compose up tiktok-worker
```

The compose file includes:
- **playwright-service**: Remote browser automation service
- **tiktok-worker**: Scraper worker connected to Playwright service
- **ffmpeg-service**: Media conversion service

The source code is mounted as a volume, allowing live code updates with service restart.

## Task Types

All job payloads accept optional time filtering:
- `time_range`: Positive integer in days (e.g., 7 for last 7 days)
- `since_date`: ISO 8601 date string (e.g., "2024-01-01")
- `until_date`: ISO 8601 date string (e.g., "2024-12-31")

When provided, the worker only persists content published within the specified window.

### 1. Research Keyword

Search TikTok by keyword and save results to `search_sessions` collection.

**Payload:**
```json
{
  "task_type": "research_keyword",
  "job_id": "uuid-123",
  "payload": {
    "keyword": "python tutorial",
    "limit": 50,
    "sort_by": "views"
  }
}
```

### 2. Crawl Links

Crawl specific video URLs with optional media download.

**Payload:**
```json
{
  "task_type": "crawl_links",
  "job_id": "uuid-456",
  "payload": {
    "video_urls": [
      "https://www.tiktok.com/@user/video/123",
      "https://www.tiktok.com/@user/video/456"
    ],
    "download_media": true,
    "media_type": "audio",
    "include_comments": true,
    "max_comments": 200,
    "time_range": 14,
    "save_to_db_enabled": true,
    "media_download_enabled": true,
    "archive_storage_enabled": true
  }
}
```

### 3. Research and Crawl

Perform keyword search then crawl all found videos in a single job.

**Payload:**
```json
{
  "task_type": "research_and_crawl",
  "job_id": "uuid-789",
  "payload": {
    "keywords": ["music production", "beat making"],
    "limit_per_keyword": 100,
    "download_media": true,
    "media_type": "audio",
    "time_range": 30
  }
}
```

### 4. Fetch Profile Content

Crawl all videos from a TikTok profile.

**Payload:**
```json
{
  "task_type": "fetch_profile_content",
  "job_id": "uuid-101",
  "payload": {
    "profile_url": "https://www.tiktok.com/@username",
    "download_media": true,
    "include_comments": true,
    "max_comments": 100,
    "since_date": "2024-01-01",
    "until_date": "2024-12-31"
  }
}
```

### 5. Dry Run Keyword

Search and scrape without persistence (for testing/validation).

**Payload:**
```json
{
  "task_type": "dryrun_keyword",
  "job_id": "uuid-202",
  "payload": {
    "keywords": ["test keyword"],
    "limit": 10,
    "include_comments": true,
    "max_comments": 50
  }
}
```

### Storage Control Flags

Each task supports fine-grained storage control:

- `save_to_db_enabled`: Save to MongoDB (default: false)
- `media_download_enabled`: Download media files (default: true)
- `archive_storage_enabled`: Archive to MinIO (default: true)

### Result Storage

Data is persisted to MongoDB collections:
- `crawl_jobs`: Job tracking with status and timestamps
- `content`: Video metadata and metrics
- `authors`: Creator profiles
- `comments`: Video comments
- `search_sessions`: Keyword search results

Media files are uploaded to MinIO bucket with paths stored in content documents.


## Project Structure

```
tiktok/
├── app/                          # Entry points & DI
│   ├── main.py                   # Application entry point
│   ├── bootstrap.py              # Dependency injection container
│   └── worker_service.py         # Worker orchestration
├── application/                  # Use cases & interfaces
│   ├── interfaces.py             # Abstract interfaces (ports)
│   ├── crawler_service.py        # Crawling orchestration
│   └── task_service.py           # Task handling & job tracking
├── domain/                       # Business entities
│   ├── entities/                 # Content, Author, Comment
│   │   ├── content.py
│   │   ├── author.py
│   │   ├── comment.py
│   │   ├── crawl_job.py
│   │   └── search_session.py
│   ├── value_objects/            # Metrics
│   └── enums.py                  # Platform, MediaType, etc.
├── internal/                     # Infrastructure adapters
│   ├── adapters/
│   │   ├── scrapers_tiktok/      # HTTP & Playwright scrapers
│   │   │   ├── video_api.py
│   │   │   ├── creator_api.py
│   │   │   ├── comment_scraper.py
│   │   │   ├── search_scraper.py
│   │   │   ├── profile_scraper.py
│   │   │   └── media_downloader.py
│   │   └── repository_mongo.py   # MongoDB repositories
│   └── infrastructure/
│       ├── mongo/                # MongoDB client helpers
│       ├── playwright/           # Browser automation setup
│       ├── rabbitmq/             # Message queue helpers
│       │   ├── consumer.py
│       │   ├── publisher.py
│       │   └── helpers.py
│       ├── minio/                # Object storage client
│       │   ├── storage.py
│       │   ├── async_uploader.py
│       │   └── upload_task.py
│       ├── compression/          # Zstd compression
│       │   ├── interfaces.py
│       │   └── zstd_compressor.py
│       └── rest_client/          # External API clients
│           ├── playwright_rest_client.py
│           └── speech2text_rest_client.py
├── config/                       # Configuration
│   ├── settings.py               # Pydantic settings model
│   └── selectors.py              # CSS/XPath selectors
├── utils/                        # Utilities
│   ├── logger.py
│   ├── helpers.py
│   ├── io_utils.py
│   └── browser_stealth.py
├── tests/                        # Test suite
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/                         # Documentation
├── downloads/                    # Local media storage (gitignored)
├── .env.example                  # Environment template
├── requirements.txt              # Python dependencies
├── pyproject.toml                # UV project configuration
├── uv.lock                       # UV lock file
├── Dockerfile                    # Container image
└── README.md                     # This file
```

## Testing

### Run Unit Tests

```bash
pytest tests/unit
```

### Run Integration Tests

Requires MongoDB and RabbitMQ test instances:

```bash
pytest tests/integration
```

### Run End-to-End Tests

Includes Playwright browser automation:

```bash
pytest tests/e2e
```

### Run All Tests

```bash
pytest
```

**Note:** Use separate test database and queue to avoid affecting production data.


## Deployment Guide

### Docker Deployment

#### 1. Build Docker Image

```bash
cd scrapper/tiktok
docker build -t tiktok-scraper:latest .
```

The Dockerfile uses multi-stage builds:
- **Stage 1 (Builder)**: Uses `uv` for ultra-fast dependency installation
- **Stage 2 (Runtime)**: Minimal Python 3.12 slim image with only runtime dependencies

#### 2. Run with Docker Compose

From `scrapper/` directory:

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f tiktok-worker

# Stop services
docker compose down
```

#### 3. Environment Configuration

Create `.env` file in `scrapper/tiktok/`:

```bash
# Copy from example
cp .env.example .env

# Edit with your credentials
nano .env
```

#### 4. Service Dependencies

The worker requires these services to be running:

```yaml
services:
  playwright-service:  # Browser automation
  tiktok-worker:       # Main scraper worker
  ffmpeg-service:      # Media conversion
```

### Production Deployment

#### Infrastructure Requirements

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[Nginx/HAProxy]
    end
    
    subgraph "Worker Cluster"
        W1[Worker 1]
        W2[Worker 2]
        W3[Worker N]
    end
    
    subgraph "Message Queue Cluster"
        RMQ1[RabbitMQ Primary]
        RMQ2[RabbitMQ Replica]
    end
    
    subgraph "Database Cluster"
        DB1[MongoDB Primary]
        DB2[MongoDB Secondary]
        DB3[MongoDB Arbiter]
    end
    
    subgraph "Object Storage"
        S3[MinIO Cluster]
    end
    
    LB --> W1
    LB --> W2
    LB --> W3
    
    W1 --> RMQ1
    W2 --> RMQ1
    W3 --> RMQ1
    
    RMQ1 -.replicate.-> RMQ2
    
    W1 --> DB1
    W2 --> DB1
    W3 --> DB1
    
    DB1 -.replicate.-> DB2
    DB1 -.replicate.-> DB3
    
    W1 --> S3
    W2 --> S3
    W3 --> S3
```

#### 1. Kubernetes Deployment

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tiktok-scraper
  namespace: scraper
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tiktok-scraper
  template:
    metadata:
      labels:
        app: tiktok-scraper
    spec:
      containers:
      - name: tiktok-scraper
        image: your-registry/tiktok-scraper:latest
        env:
        - name: RABBITMQ_HOST
          valueFrom:
            configMapKeyRef:
              name: scraper-config
              key: rabbitmq_host
        - name: MONGODB_HOST
          valueFrom:
            configMapKeyRef:
              name: scraper-config
              key: mongodb_host
        - name: MINIO_ENDPOINT
          valueFrom:
            configMapKeyRef:
              name: scraper-config
              key: minio_endpoint
        - name: RABBITMQ_PASSWORD
          valueFrom:
            secretKeyRef:
              name: scraper-secrets
              key: rabbitmq_password
        - name: MONGODB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: scraper-secrets
              key: mongodb_password
        - name: MINIO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: scraper-secrets
              key: minio_secret_key
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          exec:
            command:
            - pgrep
            - -f
            - "python.*app.main"
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          exec:
            command:
            - pgrep
            - -f
            - "python.*app.main"
          initialDelaySeconds: 30
          periodSeconds: 10
```

Deploy to Kubernetes:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
```

#### 2. Docker Swarm Deployment

Create `docker-stack.yml`:

```yaml
version: '3.8'

services:
  tiktok-scraper:
    image: your-registry/tiktok-scraper:latest
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    environment:
      RABBITMQ_HOST: rabbitmq
      MONGODB_HOST: mongodb
      MINIO_ENDPOINT: minio:9000
      PLAYWRIGHT_WS_ENDPOINT: ws://playwright:4444
    secrets:
      - rabbitmq_password
      - mongodb_password
      - minio_secret_key
    networks:
      - scraper-network

secrets:
  rabbitmq_password:
    external: true
  mongodb_password:
    external: true
  minio_secret_key:
    external: true

networks:
  scraper-network:
    driver: overlay
```

Deploy to Swarm:

```bash
docker stack deploy -c docker-stack.yml scraper
```

#### 3. Scaling Considerations

**Horizontal Scaling:**
- Add more worker instances to handle increased load
- Each worker consumes from the same RabbitMQ queue
- RabbitMQ distributes tasks across workers (round-robin)

```bash
# Kubernetes
kubectl scale deployment tiktok-scraper --replicas=5

# Docker Compose
docker compose up -d --scale tiktok-worker=5

# Docker Swarm
docker service scale scraper_tiktok-scraper=5
```

**Vertical Scaling:**
- Increase `CRAWLER_MAX_CONCURRENT` for more parallel tasks per worker
- Increase memory/CPU limits in deployment config
- Monitor resource usage and adjust accordingly

**Queue Management:**
- Set `RABBITMQ_PREFETCH_COUNT=1` for fair distribution
- Use separate queues for different task priorities
- Monitor queue depth and adjust worker count

#### 4. Monitoring & Observability

**Logging:**
```bash
# View logs
docker compose logs -f tiktok-worker

# Kubernetes
kubectl logs -f deployment/tiktok-scraper

# Export to file
docker compose logs tiktok-worker > logs/worker.log
```

**Metrics to Monitor:**
- Queue depth (RabbitMQ)
- Task processing rate
- Error rate
- Memory/CPU usage
- MongoDB connection pool
- MinIO upload throughput

**Health Checks:**
```bash
# Check worker process
docker exec tiktok-scraper pgrep -f "python.*app.main"

# Check RabbitMQ connection
docker exec tiktok-scraper python -c "import pika; pika.BlockingConnection()"

# Check MongoDB connection
docker exec tiktok-scraper python -c "from pymongo import MongoClient; MongoClient('mongodb://...')"
```

#### 5. Backup & Recovery

**MongoDB Backup:**
```bash
# Backup
mongodump --uri="mongodb://user:pass@host:27017/tiktok_crawl" --out=/backup

# Restore
mongorestore --uri="mongodb://user:pass@host:27017/tiktok_crawl" /backup/tiktok_crawl
```

**MinIO Backup:**
```bash
# Sync to backup location
mc mirror minio/tiktok-media backup/tiktok-media
mc mirror minio/tiktok-archive backup/tiktok-archive
```

#### 6. Security Best Practices

- Use secrets management (Kubernetes Secrets, Docker Secrets, Vault)
- Enable TLS for RabbitMQ, MongoDB, MinIO connections
- Use network policies to restrict inter-service communication
- Rotate credentials regularly
- Run containers as non-root user
- Scan images for vulnerabilities

```bash
# Scan Docker image
docker scan tiktok-scraper:latest

# Run as non-root (add to Dockerfile)
USER 1000:1000
```


## Troubleshooting

### RabbitMQ Connection Failed

- Verify RabbitMQ is running: `docker ps` or check service status
- Check credentials in `.env` match RabbitMQ configuration
- Verify port 5672 is accessible
- Check `RABBITMQ_VHOST` if using non-default vhost
- Test connection: `telnet rabbitmq-host 5672`

### MongoDB Connection Failed

- Verify MongoDB is running and accessible
- Check connection string format in `.env`
- Verify authentication credentials if auth is enabled
- Check `MONGODB_AUTH_SOURCE` matches your MongoDB setup
- Test connection: `mongosh "mongodb://user:pass@host:27017/db"`

### Playwright Errors

- Reinstall browser: `playwright install --with-deps chromium`
- Check system dependencies: `playwright install-deps`
- If using Docker, verify `PLAYWRIGHT_BROWSERS_PATH` in Dockerfile
- For remote Playwright, verify `PLAYWRIGHT_WS_ENDPOINT` is accessible
- Check Playwright service logs: `docker compose logs playwright-service`

### Slow Crawling

- Increase `CRAWLER_MAX_CONCURRENT` for more parallel workers
- Check if rate limiting is active
- Verify network latency to TikTok servers
- Monitor MongoDB write performance
- Check MinIO upload bandwidth

### Media Download Issues

- Verify FFmpeg is installed: `ffmpeg -version`
- Check MinIO credentials and bucket existence
- Verify `MEDIA_DOWNLOAD_DIR` has write permissions
- Check disk space availability
- Monitor MinIO logs for upload errors

### Memory Issues

- Reduce `CRAWLER_MAX_CONCURRENT` to lower memory usage
- Increase Docker memory limits
- Monitor memory usage: `docker stats tiktok-scraper`
- Check for memory leaks in logs
- Restart worker periodically if needed

### Task Processing Stuck

- Check RabbitMQ queue depth: `rabbitmqctl list_queues`
- Verify worker is consuming: `docker logs tiktok-scraper`
- Check for deadlocks in MongoDB
- Verify Playwright service is responsive
- Restart worker if hung: `docker compose restart tiktok-worker`

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Detailed architecture documentation
- [REFACTORING_SUMMARY.md](docs/REFACTORING_SUMMARY.md) - Refactoring history
- [.env.example](.env.example) - Complete environment variable documentation
- [MESSAGE-STRUCTURE-SPECIFICATION.md](../../MESSAGE-STRUCTURE-SPECIFICATION.md) - Message format specification

## Key Entry Points

- `app/main.py:1` - Application entry point
- `app/bootstrap.py:1` - Dependency injection setup
- `application/task_service.py:1` - Task type routing
- `application/crawler_service.py:1` - Crawling orchestration

## Observability

### Logging

- Logs are written to stdout and `logs/` directory
- Log level controlled by `LOG_LEVEL` environment variable (DEBUG/INFO/WARNING)
- Worker name set via `WORKER_NAME` for multi-instance deployments
- Structured logging with timestamps and context

### Job Tracking

Jobs collection stores:
- Job status: `QUEUED`, `RUNNING`, `COMPLETED`, `FAILED`, `RETRYING`
- Timestamps: `created_at`, `started_at`, `completed_at`
- Error messages and retry count
- Associated content/search result IDs
- MinIO object keys for uploaded media

### Retry Logic

- Automatic retry up to 3 attempts
- Configurable delay between retries: `WORKER_RETRY_DELAY`
- Failed jobs remain in database for investigation
- Separate retry service can reprocess failed jobs

### Performance Metrics

Monitor these key metrics:
- **Throughput**: Tasks processed per minute
- **Latency**: Average task processing time
- **Error Rate**: Failed tasks / total tasks
- **Queue Depth**: Pending tasks in RabbitMQ
- **Resource Usage**: CPU, memory, network I/O

## Contributing

When adding new features or modifying the scraper:

1. Follow Clean Architecture principles
2. Update relevant documentation files
3. Add tests for new functionality
4. Update `.env.example` for new configuration options
5. Keep README synchronized with code changes
6. Update Mermaid diagrams if architecture changes

## License

MIT License - See LICENSE file for details

---

**Last Updated:** 2025-12-02  
**Version:** 3.0.0 (Clean Architecture + Multi-Platform Support)  
**Maintainer:** SMAP AI Team

