# Analytics Service Architecture Decision

## TL;DR

**Quyết định:** Giữ nguyên **analytics-service** (Go) với refactor structure, **KHÔNG dùng n8n**.

---

## Context

Migration Plan v2.3-v2.9 đề xuất chuyển Analytics từ monolithic service sang **n8n Orchestrator + Python Workers**.

Sau khi đánh giá hiện trạng và yêu cầu production, phát hiện n8n có những hạn chế nghiêm trọng.

---

## Problems với n8n

### 1. Không Scale Ngang ❌

**Vấn đề:**
- n8n là single instance application
- Không thể deploy multiple replicas với Kafka consumer
- Bottleneck khi xử lý hàng ngàn UAP records/sec

**Impact:**
- Throughput giới hạn ở ~100-200 records/sec
- Không đáp ứng được peak load (VD: import 10k records từ Excel)

### 2. Performance Overhead ❌

**Vấn đề:**
- Visual workflow engine có overhead lớn
- Mỗi node trong workflow phải serialize/deserialize data
- Không tận dụng được Go concurrency

**Benchmark:**
```
n8n workflow:     ~500ms per UAP record
Go orchestrator:  ~50ms per UAP record (10x faster)
```

### 3. Khó Debug Production Issues ❌

**Vấn đề:**
- Visual workflows không có stack trace
- Error messages không rõ ràng
- Khó reproduce issues locally

**Example:**
```
n8n error: "Node 'Sentiment Worker' failed"
→ Không biết lỗi ở đâu: network? timeout? worker crash?

Go error: "sentiment worker timeout after 5s: context deadline exceeded at worker.go:45"
→ Rõ ràng, có line number, có context
```

### 4. Vendor Lock-in ❌

**Vấn đề:**
- Logic business bị lock trong n8n workflows (JSON format)
- Khó migrate sang platform khác
- Phụ thuộc vào n8n updates/bugs



---

## Solution: Go Analytics Service

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  ANALYTICS SERVICE (Go)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Entry Point 1: Consumer                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  cmd/consumer/main.go                                   │    │
│  │  • Kafka consumer (analytics.uap.received)              │    │
│  │  • Goroutine pool (100 workers)                         │    │
│  │  • Process UAP records concurrently                     │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  Orchestrator Layer                                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  internal/orchestrator/pipeline.go                      │    │
│  │  • Call AI Workers (HTTP/gRPC)                          │    │
│  │  • Parallel execution (errgroup)                        │    │
│  │  • Aggregate results                                    │    │
│  │  • Error handling & retry                               │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  AI Worker Clients                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Sentiment   │  │   Aspect     │  │   Keyword    │          │
│  │   Client     │  │   Client     │  │   Client     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                  │
│         └─────────────────┴─────────────────┘                  │
│                            ↓ HTTP                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  AI Workers (Python FastAPI)                            │    │
│  │  • sentiment-worker:8000                                │    │
│  │  • aspect-worker:8000                                   │    │
│  │  • keyword-worker:8000                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Entry Point 2: API (Optional)                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  cmd/api/main.go                                        │    │
│  │  • Health check endpoint                                │    │
│  │  • Metrics endpoint (Prometheus)                        │    │
│  │  • Internal query API (optional)                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Repo Structure

```
services/analytics/
├── cmd/
│   ├── consumer/
│   │   └── main.go          # Kafka consumer entry point
│   └── api/
│       └── main.go          # API server entry point (optional)
│
├── internal/
│   ├── orchestrator/
│   │   ├── pipeline.go      # Main orchestration logic
│   │   └── pipeline_test.go
│   ├── workers/
│   │   ├── sentiment.go     # Sentiment worker client
│   │   ├── aspect.go        # Aspect worker client
│   │   └── keyword.go       # Keyword worker client
│   ├── repository/
│   │   ├── analytics.go     # Database access (analytics.*)
│   │   └── analytics_test.go
│   └── model/
│       ├── uap.go           # UAP struct
│       └── analytics.go     # PostAnalytics struct
│
├── pkg/
│   ├── kafka/
│   │   └── consumer.go      # Kafka consumer wrapper
│   └── httpclient/
│       └── client.go        # HTTP client with retry
│
├── config/
│   └── config.go            # Configuration
│
├── Dockerfile
├── go.mod
└── README.md
```

### Benefits

| Aspect | n8n | Go Service |
|--------|-----|------------|
| **Scalability** | ❌ Single instance | ✅ Horizontal (5-10 replicas) |
| **Performance** | ❌ ~500ms/record | ✅ ~50ms/record (10x) |
| **Throughput** | ❌ ~200 records/sec | ✅ ~2000 records/sec |
| **Debugging** | ❌ Visual workflows | ✅ Stack traces, line numbers |
| **Testing** | ❌ Hard to unit test | ✅ Easy unit + integration tests |
| **Observability** | ❌ Limited metrics | ✅ Prometheus, Jaeger, logs |
| **Maintainability** | ❌ JSON workflows | ✅ Code-based, type-safe |
| **Vendor Lock-in** | ❌ Yes | ✅ No |

---

## Implementation Plan

### Phase 1: Refactor Structure (Tuần 5)

- [ ] Tạo folder structure mới
- [ ] Move existing code vào internal/
- [ ] Tách consumer và orchestrator logic
- [ ] Add AI worker clients

### Phase 2: Add Concurrency (Tuần 5)

- [ ] Implement goroutine pool cho consumer
- [ ] Parallel AI worker calls (errgroup)
- [ ] Add retry logic với exponential backoff

### Phase 3: Scalability (Tuần 6)

- [ ] K8s deployment với multiple replicas
- [ ] Kafka consumer group configuration
- [ ] Load testing (target: 2000 records/sec)

### Phase 4: Observability (Tuần 6)

- [ ] Prometheus metrics
- [ ] Structured logging
- [ ] Distributed tracing (Jaeger)

---

## Migration from Current Code

### Current Structure (Cần refactor)

```
services/analytic/
├── cmd/
│   ├── api/          # API server
│   └── consumer/     # Kafka consumer
├── internal/
│   ├── analytic/     # Business logic (monolithic)
│   └── ...
```

### Changes Needed

1. **Rename:** `services/analytic/` → `services/analytics/`
2. **Restructure:** Tách orchestrator logic ra khỏi business logic
3. **Add:** AI worker clients (HTTP)
4. **Update:** UAP input format
5. **Add:** Concurrency với goroutines

### Code Changes

**Before (Monolithic):**
```go
// internal/analytic/service.go
func (s *Service) ProcessData(data Data) error {
    // All logic in one place
    sentiment := s.analyzeSentiment(data.Content)
    aspects := s.analyzeAspects(data.Content)
    keywords := s.extractKeywords(data.Content)
    
    return s.repo.Save(sentiment, aspects, keywords)
}
```

**After (Orchestrator + Workers):**
```go
// internal/orchestrator/pipeline.go
func (p *Pipeline) ProcessUAP(ctx context.Context, uap *UAP) error {
    // Call external AI workers
    sentiment, _ := p.sentimentClient.Analyze(ctx, uap.Content)
    
    // Parallel calls
    g, ctx := errgroup.WithContext(ctx)
    g.Go(func() error {
        aspectResult, err = p.aspectClient.Analyze(ctx, uap.Content)
        return err
    })
    g.Go(func() error {
        keywordResult, err = p.keywordClient.Extract(ctx, uap.Content)
        return err
    })
    g.Wait()
    
    return p.repo.Insert(ctx, analytics)
}
```

---

## Conclusion

**Quyết định cuối cùng:** Giữ nguyên Go service, refactor structure để:
- ✅ Scalable (horizontal scaling)
- ✅ Fast (Go concurrency)
- ✅ Maintainable (code-based logic)
- ✅ Observable (standard tooling)

**Không dùng n8n** vì không đáp ứng được yêu cầu production về scalability và performance.
