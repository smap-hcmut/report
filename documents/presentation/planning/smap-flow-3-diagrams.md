# SMAP - 3 luồng hệ thống để đưa vào slide

File này chia luồng tổng thể thành 3 hình nhỏ để trình bày dễ hơn trong 15 phút. Mỗi hình chỉ tập trung vào một ý: cấu hình, ingest, và outflow phân tích/cảnh báo.

---

## Hình 1 - Luồng Thiết lập & Kích hoạt Chiến dịch

Trọng tâm: tách rời quản lý nghiệp vụ dự án ở `project-srv` và quản lý kỹ thuật thu thập dữ liệu ở `ingest-srv`.

```mermaid
sequenceDiagram
    autonumber
    actor User as User / Web UI
    participant Project as project-srv
    participant Ingest as ingest-srv
    participant PG as PostgreSQL

    User->>Project: Cấu hình Campaign / Project
    Project->>PG: Lưu campaign, project, crisis config
    Project-->>User: Trả trạng thái cấu hình

    User->>Project: Activate Project
    Project->>Ingest: Internal HTTP: readiness / activate
    Ingest-->>Project: Activation accepted
    Project->>PG: Cập nhật trạng thái project
    Project-->>User: Project activated

    User->>Ingest: Cấu hình datasource / target / schedule
    Ingest->>PG: Lưu data_sources, crawl_targets, scheduled_jobs
    Ingest-->>User: Ingest config saved
```

Gợi ý nói ngắn:

- `project-srv` giữ business context: campaign, project, trạng thái, cấu hình crisis.
- `ingest-srv` giữ execution context: datasource, target, schedule, task lineage.
- Khi activate, `project-srv` gọi internal HTTP sang `ingest-srv` để bắt đầu phần thu thập.

---

## Hình 2 - Luồng Thu thập & Chuẩn hóa Dữ liệu Thô

Trọng tâm: bất đồng bộ qua RabbitMQ và MinIO để crawler có thể scale, không làm nghẽn core service.

```mermaid
sequenceDiagram
    autonumber
    participant Ingest as ingest-srv
    participant PG as PostgreSQL
    participant Rabbit as RabbitMQ
    participant Scapper as scapper-srv
    participant Social as TikTok / Facebook / YouTube
    participant MinIO as MinIO

    Ingest->>PG: Scheduler đọc scheduled_jobs
    Ingest->>PG: Tạo external_tasks
    Ingest->>Rabbit: Publish crawl task

    Rabbit-->>Scapper: Deliver task
    Scapper->>Social: Crawl public posts / comments / videos
    Social-->>Scapper: Raw social data

    Scapper->>MinIO: Upload raw artifact
    Scapper->>Rabbit: Publish completion message

    Rabbit-->>Ingest: Deliver completion
    Ingest->>MinIO: Verify / read raw artifact
    Ingest->>PG: Tạo raw_batches
    Ingest->>Ingest: Chuẩn hóa raw sang UAP
```

Gợi ý nói ngắn:

- RabbitMQ đóng vai trò buffer cho crawl task, giúp `scapper-srv` scale độc lập.
- Raw data lớn không đi trực tiếp trong message, mà lưu ở MinIO theo kiểu artifact reference.
- UAP là định dạng chung, giúp tầng analysis không cần biết dữ liệu đến từ TikTok, Facebook hay YouTube.

---

## Hình 3 - Luồng Phân tích, Tri thức & Cảnh báo Realtime

Trọng tâm: Redpanda/Kafka API cho analytics streaming, PostgreSQL cho read model, Qdrant cho vector search, Redis/WebSocket cho realtime.

```mermaid
sequenceDiagram
    autonumber
    participant Ingest as ingest-srv
    participant Stream as Redpanda / Kafka API
    participant Analysis as analysis-srv
    participant PG as PostgreSQL
    participant Knowledge as knowledge-srv
    participant Qdrant as Qdrant
    participant Notify as notification-srv
    participant Redis as Redis Pub/Sub
    actor User as User / Web UI

    Ingest->>Stream: Publish UAP records<br/>topic: smap.collector.output

    Stream-->>Analysis: Consume UAP records
    Analysis->>Analysis: NLP pipeline / sentiment / aspect / crisis
    Analysis->>PG: Lưu analysis.post_insight
    Analysis->>Stream: Publish analytics.*

    Stream-->>Knowledge: Consume analytics events
    Knowledge->>Qdrant: Index embeddings / documents
    Knowledge-->>User: Search / Chat RAG / Report

    Stream-->>Notify: Consume digest / crisis events
    Notify->>Redis: Publish notification channel
    Redis-->>Notify: Pub/Sub fanout
    Notify-->>User: WebSocket realtime update
```

Gợi ý nói ngắn:

- Redpanda/Kafka API phù hợp với luồng UAP/analytics vì đây là stream record lớn và có nhiều consumer.
- `analysis-srv` tạo read model chính ở `analysis.post_insight`.
- `knowledge-srv` index vào Qdrant để phục vụ AI search, chat RAG và report.
- `notification-srv` nhận digest/crisis event, đẩy qua Redis Pub/Sub và WebSocket cho realtime dashboard.

