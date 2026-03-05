# Ingest Service - Job Scheduler Implementation

**Service:** ingest-srv  
**Language:** Go  
**Purpose:** Schedule and execute crawl jobs for data sources  
**Ngày tạo:** 19/02/2026

---

## 1. OVERVIEW

Ingest Service cần implement Job Scheduler để:

1. Schedule recurring crawl jobs cho các crawl sources (Facebook, TikTok, YouTube)
2. Cancel jobs khi project archived
3. Reschedule jobs khi adaptive crawl mode thay đổi (Normal → Crisis)

---

## 2. ARCHITECTURE OPTIONS

### Option 1: Event-driven with In-memory Scheduler (robfig/cron)

**Pros:**

- ✅ Real-time response to events
- ✅ Precise timing control
- ✅ Low latency

**Cons:**

- ❌ State lost on restart
- ❌ Complex state management
- ❌ Harder to scale horizontally

### Option 2: Database-driven Polling (RECOMMENDED)

**Pros:**

- ✅ Simple implementation
- ✅ Persistent state (survives restarts)
- ✅ Easy to scale (multiple workers)
- ✅ No need to cancel jobs explicitly

**Cons:**

- ❌ Polling overhead (query DB every minute)
- ❌ Max 1 minute delay

**Recommendation:** Use **Database-driven Polling** for simplicity and reliability.

---

## 3. DATABASE-DRIVEN IMPLEMENTATION

### 3.1 Worker Loop

```go
// cmd/worker/main.go

package main

import (
    "context"
    "time"
    "github.com/your-org/ingest-srv/internal/crawler"
)

type CrawlWorker struct {
    repo      DataSourceRepository
    crawler   Crawler
    logger    Logger
}

func (w *CrawlWorker) Run(ctx context.Context) {
    ticker := time.NewTicker(1 * time.Minute)
    defer ticker.Stop()

    w.logger.Info("Crawl worker started")

    for {
        select {
        case <-ticker.C:
            w.processDueSources(ctx)

        case <-ctx.Done():
            w.logger.Info("Crawl worker stopped")
            return
        }
    }
}

func (w *CrawlWorker) processDueSources(ctx context.Context) {
    // 1. Query sources due for crawl
    sources, err := w.repo.GetDueSources(ctx, time.Now())
    if err != nil {
        w.logger.Errorf("Failed to get due sources: %v", err)
        return
    }

    w.logger.Infof("Found %d sources due for crawl", len(sources))

    // 2. Execute crawls (parallel)
    for _, source := range sources {
        // Skip if archived
        if source.Status == "ARCHIVED" {
            w.logger.Debugf("Skipping archived source %s", source.ID)
            continue
        }

        // Execute in goroutine (non-blocking)
        go w.executeCrawl(ctx, source)
    }
}

func (w *CrawlWorker) executeCrawl(ctx context.Context, source DataSource) {
    w.logger.Infof("Executing crawl for source %s (mode=%s)", source.ID, source.CrawlMode)

    // 1. Call external crawl API
    items, err := w.crawler.Crawl(ctx, CrawlRequest{
        SourceID:   source.ID,
        SourceType: source.SourceType,
        Config:     source.Config,
        Profile:    "INCREMENTAL_MONITOR",
    })

    if err != nil {
        w.logger.Errorf("Crawl failed for source %s: %v", source.ID, err)

        // Publish failure event
        w.publishCrawlCompleted(ctx, source.ID, 0, "FAILED", err.Error())
        return
    }

    w.logger.Infof("Crawl completed for source %s: %d items", source.ID, len(items))

    // 2. Transform to UAP and publish
    for _, item := range items {
        uap := w.transformToUAP(item, source)
        w.publishUAP(ctx, uap)
    }

    // 3. Publish success event
    w.publishCrawlCompleted(ctx, source.ID, len(items), "SUCCESS", "")
}
```

### 3.2 Repository Query

```go
// internal/repository/data_source.go

func (r *DataSourceRepository) GetDueSources(ctx context.Context, now time.Time) ([]DataSource, error) {
    query := `
        SELECT
            id, project_id, name, source_type, source_category,
            config, crawl_mode, crawl_interval_minutes, next_crawl_at,
            status
        FROM schema_ingest.data_sources
        WHERE
            status = 'ACTIVE'
            AND source_category = 'crawl'
            AND next_crawl_at <= $1
        ORDER BY next_crawl_at ASC
        LIMIT 100
    `

    rows, err := r.db.QueryContext(ctx, query, now)
    if err != nil {
        return nil, fmt.Errorf("failed to query due sources: %w", err)
    }
    defer rows.Close()

    sources := []DataSource{}
    for rows.Next() {
        var source DataSource
        err := rows.Scan(
            &source.ID, &source.ProjectID, &source.Name,
            &source.SourceType, &source.SourceCategory,
            &source.Config, &source.CrawlMode,
            &source.CrawlIntervalMinutes, &source.NextCrawlAt,
            &source.Status,
        )
        if err != nil {
            return nil, fmt.Errorf("failed to scan source: %w", err)
        }
        sources = append(sources, source)
    }

    return sources, nil
}
```

### 3.3 Update Next Crawl Time

Project Service sẽ update `next_crawl_at` sau khi nhận `ingest.crawl.completed`:

```go
// Project Service - internal/consumers/crawl_completed.go

func (h *CrawlCompletedHandler) Handle(ctx context.Context, msg CrawlCompletedMessage) error {
    source, err := h.repo.GetByID(ctx, msg.SourceID)
    if err != nil {
        return err
    }

    // Calculate next crawl time
    nextCrawlAt := time.Now().Add(
        time.Duration(source.CrawlIntervalMinutes) * time.Minute,
    )

    // Update database
    err = h.repo.Update(ctx, msg.SourceID, UpdateDataSourceInput{
        LastCrawlAt:  time.Now(),
        NextCrawlAt:  nextCrawlAt,
        Status:       "ACTIVE",
    })

    return err
}
```

---

## 4. HANDLING ARCHIVED PROJECTS

### 4.1 Approach: Skip in Worker Loop

**No need to cancel jobs explicitly** - just check status in worker loop.

```go
func (w *CrawlWorker) processDueSources(ctx context.Context) {
    sources, err := w.repo.GetDueSources(ctx, time.Now())

    for _, source := range sources {
        // Skip archived sources
        if source.Status == "ARCHIVED" {
            w.logger.Debugf("Skipping archived source %s", source.ID)
            continue
        }

        go w.executeCrawl(ctx, source)
    }
}
```

### 4.2 Optional: Consume project.archived Event

Nếu muốn log hoặc cleanup:

```go
// internal/consumers/project_archived.go

type ProjectArchivedHandler struct {
    logger Logger
}

func (h *ProjectArchivedHandler) Handle(ctx context.Context, msg ProjectArchivedMessage) error {
    h.logger.Infof(
        "Project %s archived with %d sources - jobs will be skipped automatically",
        msg.ProjectID, len(msg.SourceIDs),
    )

    // Optional: Cleanup any cached state
    // No need to cancel jobs - worker loop will skip ARCHIVED sources

    return nil
}
```

---

## 5. HANDLING ADAPTIVE CRAWL MODE CHANGES

### 5.1 Consume project.crisis.started

```go
// internal/consumers/crisis_started.go

type CrisisStartedHandler struct {
    repo   DataSourceRepository
    logger Logger
}

func (h *CrisisStartedHandler) Handle(ctx context.Context, msg CrisisStartedMessage) error {
    h.logger.Infof(
        "Crisis started for source %s - mode will change to CRISIS",
        msg.SourceID,
    )

    // Project Service already updated crawl_mode and crawl_interval
    // Worker will pick up new interval on next poll

    // Optional: Trigger immediate crawl
    source, err := h.repo.GetByID(ctx, msg.SourceID)
    if err != nil {
        return err
    }

    go h.executeCrawl(ctx, source)

    return nil
}
```

**Note:** Project Service đã update `crawl_interval` và `next_crawl_at` trong database. Worker sẽ tự động pick up interval mới.

---

## 6. SCALING CONSIDERATIONS

### 6.1 Multiple Worker Instances

**Problem:** Multiple workers query cùng DB → duplicate crawls

**Solution 1: Row-level Locking**

```sql
-- Use FOR UPDATE SKIP LOCKED
SELECT id, ...
FROM schema_ingest.data_sources
WHERE status = 'ACTIVE'
  AND source_category = 'crawl'
  AND next_crawl_at <= $1
ORDER BY next_crawl_at ASC
LIMIT 100
FOR UPDATE SKIP LOCKED;
```

**Solution 2: Optimistic Locking**

```go
func (w *CrawlWorker) processDueSources(ctx context.Context) {
    sources, _ := w.repo.GetDueSources(ctx, time.Now())

    for _, source := range sources {
        // Try to claim the source
        claimed, err := w.repo.ClaimSource(ctx, source.ID, w.workerID)
        if err != nil || !claimed {
            continue  // Another worker claimed it
        }

        go w.executeCrawl(ctx, source)
    }
}

func (r *DataSourceRepository) ClaimSource(ctx context.Context, sourceID, workerID string) (bool, error) {
    // Update with WHERE clause to ensure atomicity
    query := `
        UPDATE schema_ingest.data_sources
        SET
            claimed_by = $1,
            claimed_at = NOW()
        WHERE
            id = $2
            AND (claimed_by IS NULL OR claimed_at < NOW() - INTERVAL '5 minutes')
        RETURNING id
    `

    var id string
    err := r.db.QueryRowContext(ctx, query, workerID, sourceID).Scan(&id)
    if err == sql.ErrNoRows {
        return false, nil  // Already claimed by another worker
    }
    if err != nil {
        return false, err
    }

    return true, nil
}
```

### 6.2 Recommended Approach

Use **FOR UPDATE SKIP LOCKED** - simpler and built-in PostgreSQL feature.

---

## 7. MONITORING & ALERTS

### 7.1 Metrics to Track

```go
// Prometheus metrics
var (
    crawlsExecuted = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "ingest_crawls_executed_total",
            Help: "Total number of crawls executed",
        },
        []string{"source_type", "status"},
    )

    crawlDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "ingest_crawl_duration_seconds",
            Help: "Crawl execution duration",
        },
        []string{"source_type"},
    )

    sourcesSkipped = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "ingest_sources_skipped_total",
            Help: "Total number of sources skipped",
        },
        []string{"reason"},  // "archived", "failed", "claimed"
    )
)
```

### 7.2 Alerts

```yaml
# Prometheus alert rules
groups:
  - name: ingest_worker
    rules:
      - alert: CrawlWorkerDown
        expr: up{job="ingest-worker"} == 0
        for: 5m
        annotations:
          summary: "Crawl worker is down"

      - alert: HighCrawlFailureRate
        expr: rate(ingest_crawls_executed_total{status="FAILED"}[5m]) > 0.1
        for: 10m
        annotations:
          summary: "High crawl failure rate (>10%)"

      - alert: CrawlBacklog
        expr: count(schema_ingest_data_sources{status="ACTIVE", next_crawl_at < now()}) > 50
        for: 15m
        annotations:
          summary: "Crawl backlog is building up"
```

---

## 8. TESTING

### 8.1 Unit Tests

```go
func TestGetDueSources(t *testing.T) {
    repo := setupTestRepo(t)

    // Insert test data
    repo.Insert(ctx, DataSource{
        ID:                   "src_1",
        Status:               "ACTIVE",
        SourceCategory:       "crawl",
        NextCrawlAt:          time.Now().Add(-5 * time.Minute),
    })

    // Query
    sources, err := repo.GetDueSources(ctx, time.Now())

    assert.NoError(t, err)
    assert.Len(t, sources, 1)
    assert.Equal(t, "src_1", sources[0].ID)
}

func TestSkipArchivedSources(t *testing.T) {
    worker := setupTestWorker(t)

    // Insert archived source
    worker.repo.Insert(ctx, DataSource{
        ID:             "src_archived",
        Status:         "ARCHIVED",
        NextCrawlAt:    time.Now().Add(-5 * time.Minute),
    })

    // Process
    worker.processDueSources(ctx)

    // Verify no crawl executed
    assert.Equal(t, 0, worker.crawler.CallCount())
}
```

### 8.2 Integration Tests

```go
func TestEndToEndCrawlFlow(t *testing.T) {
    // 1. Setup
    worker := setupIntegrationTest(t)

    // 2. Insert source due for crawl
    sourceID := "src_test"
    worker.repo.Insert(ctx, DataSource{
        ID:                   sourceID,
        Status:               "ACTIVE",
        SourceCategory:       "crawl",
        CrawlMode:            "NORMAL",
        CrawlIntervalMinutes: 15,
        NextCrawlAt:          time.Now().Add(-1 * time.Minute),
    })

    // 3. Run worker
    worker.processDueSources(ctx)

    // 4. Wait for completion
    time.Sleep(2 * time.Second)

    // 5. Verify crawl executed
    assert.Equal(t, 1, worker.crawler.CallCount())

    // 6. Verify event published
    events := worker.kafkaProducer.GetPublishedEvents()
    assert.Len(t, events, 1)
    assert.Equal(t, "ingest.crawl.completed", events[0].Topic)
}
```

---

## 9. DEPLOYMENT

### 9.1 Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingest-worker
spec:
  replicas: 3 # Multiple workers for HA
  selector:
    matchLabels:
      app: ingest-worker
  template:
    metadata:
      labels:
        app: ingest-worker
    spec:
      containers:
        - name: worker
          image: ingest-srv:latest
          command: ["/app/worker"]
          env:
            - name: WORKER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: DB_HOST
              value: postgres
            - name: KAFKA_BROKERS
              value: kafka:9092
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

### 9.2 Configuration

```yaml
# config.yaml
worker:
  poll_interval: 1m
  max_concurrent_crawls: 10
  claim_timeout: 5m

database:
  host: postgres
  port: 5432
  database: smap
  schema: schema_ingest

kafka:
  brokers:
    - kafka:9092
  topics:
    crawl_completed: ingest.crawl.completed
```

---

## 10. SUMMARY

**Recommended Implementation:**

- ✅ Database-driven polling (every 1 minute)
- ✅ Skip ARCHIVED sources in worker loop
- ✅ Use FOR UPDATE SKIP LOCKED for scaling
- ✅ Optional: Consume project.archived for logging

**Key Benefits:**

- Simple and reliable
- Survives restarts
- Easy to scale horizontally
- No complex state management

**Trade-offs:**

- Max 1 minute delay (acceptable for crawl use case)
- Polling overhead (minimal with proper indexing)

---

**Last Updated:** 19/02/2026  
**Author:** System Architect
