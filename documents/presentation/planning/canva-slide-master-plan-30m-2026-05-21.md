# SMAP Slide Master Plan - Full 30m Deck + 15m Pass Mode

Ngày audit: 2026-05-21, Asia/Ho_Chi_Minh.

Nguồn đã đọc:

- Canva design `DAHKSMZBTTU`, 42 pages, title `Đồ Án`.
- Export PDF audit: `/Users/tantai/Workspaces/smap/report/documents/presentation/canva-audit/current-canva-deck.pdf`.
- Contact sheets:
  - `/Users/tantai/Workspaces/smap/report/documents/presentation/canva-audit/contact-sheet-1.png`
  - `/Users/tantai/Workspaces/smap/report/documents/presentation/canva-audit/contact-sheet-2.png`
  - `/Users/tantai/Workspaces/smap/report/documents/presentation/canva-audit/contact-sheet-3.png`
- Codebase thật: `project-srv`, `ingest-srv`, `scapper-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`, `web-ui`, `smap-deploy`.
- Evidence report: `smap-deploy/e2e-report.md`, `report/benchmark/reports/20260520-204400/benchmark-report.md`, final report chapter 4/6/7.

## 1. Quy ước đồng bộ cho mọi slide

Thêm cùng một dòng ở đầu presenter notes của từng slide:

```text
MODE: [CORE-15] hoặc [FULL-30] hoặc [BACKUP-QA].
15P: nói ý A trong N giây, rồi chuyển.
30P: nói thêm ý B/C nếu có thời gian.
PASS: nếu đang chạy 15 phút, nói câu chuyển và bỏ qua phần chi tiết.
```

Nếu muốn hiện trực tiếp trên slide, đặt badge nhỏ ở góc phải dưới:

- `CORE-15`: bắt buộc cho bản 15 phút.
- `FULL-30`: nói khi có 30 phút hoặc nếu hội đồng hỏi trong lúc trình bày.
- `BACKUP-QA`: không trình bày trong 15 phút; dùng cho phản biện 45 phút.
- `DO-NOT-PRESENT`: slide cũ hoặc sai ground truth, chỉ giữ làm source hoặc xóa.

Câu pass chuẩn để team dùng:

> Do thời lượng 15 phút, phần này nhóm xin đi qua nhanh; chi tiết đã để ở backup/Q&A, em tập trung vào flow chính và evidence vận hành.

## 2. Visual Audit Deck Hiện Tại

### Nhận xét tổng thể

Deck có hai cụm rất rõ:

1. Trang 1-26 là version mới hơn, có narrative tốt, có testing/NFR, có các sequence diagram đúng hướng.
2. Trang 27-42 là cụm cũ/appendix, có nhiều claim lệch codebase hiện tại: `Collector`, `Speech2Text`, `WebSocket Service`, `4 Go + 6 Python`, `7 FR | 8 Usecase | 2 Actors`.

Ngoài mismatch semantic, nhiều slide có khối màu xanh mint/light-blue đang che title hoặc nội dung. Đây là lỗi visual thực tế khi export, không chỉ là vấn đề text. Các trang có rủi ro che nội dung: 2, 3, 8, 10, 15, 17, 27, 30, 31, 38, 41, 42.

### Page-by-page action

| Page | Hiện trạng visual/semantic | Action |
|---:|---|---|
| 1 | Cover ổn, nhưng subtitle viết sát `SMAPSocial`. | Giữ, sửa subtitle thành thesis statement rõ. |
| 2 | `SMAP là gì?` ổn về ý; block mint che một phần visual. | CORE-15, sửa layout và rút text. |
| 3 | Market slide tốt nhưng block mint che giữa slide. | CORE-15/FULL-30, chỉnh layer block ra sau. |
| 4 | Bài toán dữ liệu + thách thức tốt. | CORE-15, giữ, thêm "campaign-specific" và "long-running jobs". |
| 5 | Section divider. | FULL-30 hoặc bỏ trong 15p. |
| 6 | Mục tiêu/phạm vi đúng. | CORE-15, giữ, thêm ngoài phạm vi: không tối ưu AI model. |
| 7 | Section divider architecture. | FULL-30, pass nhanh hoặc bỏ. |
| 8 | C4 context có actors chính, nhưng block che title. | CORE-15, sửa visual, giữ content sau khi check actor wording. |
| 9 | Use case diagram 5 UC khá khớp final report. | CORE-15, dùng thay cho old 8 UC. |
| 10 | Container diagram có service gần đúng, nhưng title/table bị block che mạnh; diagram hơi nhỏ. | CORE-15, redraw/sửa layout. |
| 11 | Sequence campaign/project/config/datasource quá nhỏ, không đọc được khi chiếu. | FULL-30, chuyển thành simplified flow + backup full sequence. |
| 12 | Sequence activation readiness đúng hướng, nhưng quá nhỏ. | CORE-15, redraw thành 5 bước. |
| 13 | Sequence ingestion/UAP đúng hướng, nhưng quá nhiều lifeline. | CORE-15, redraw thành 6 bước + backup full sequence. |
| 14 | Sequence analytics/knowledge/notification đúng hướng, có nhiều chi tiết tốt. | CORE-15, redraw thành 3 lane. |
| 15 | Claim-check slide đúng ý nhưng block che title; flow hình hơi nhỏ. | CORE-15/FULL-30, sửa visual, thêm MinIO + RabbitMQ + UAP. |
| 16 | Chỉ có chữ "Trình bày thêm..." placeholder. | Xóa hoặc biến thành messaging/storage matrix. |
| 17 | Module diagram tốt nhưng title bị che; diagram nhỏ. | FULL-30, sửa visual; 15p chỉ nói 1 câu. |
| 18 | Section divider deployment. | FULL-30 hoặc bỏ. |
| 19 | Placeholder "thêm phần triển khai". | Thay bằng deployment truth K3s/domain/source-of-truth. |
| 20 | Section divider results. | Có thể giữ làm transition. |
| 21 | Testing strategy table tốt. | CORE-15, giữ. |
| 22 | Unit screenshots dày. | FULL-30/BACKUP-QA, không chiếu lâu. |
| 23 | Integration table tốt. | CORE-15/FULL-30, giữ nhưng rút chữ khi 15p. |
| 24 | Integration/e2e method + result table tốt. | CORE-15, giữ vì có evidence 55 endpoints. |
| 25 | NFR slide tốt, có charts. | CORE-15, giữ, thêm caveat baseline/not SLA. |
| 26 | Thank you. | Kết thúc main deck; backup sau trang này. |
| 27 | Container cũ nhưng có stack Go(4)/Python(6), service cũ. | DO-NOT-PRESENT; thay bằng backup "old slide corrected". |
| 28 | Architecture flow cũ, chữ nhỏ, có Speech2Text. | BACKUP-QA nếu annotate as target/old; không dùng main. |
| 29 | Infra components có MongoDB/Collector wording, orchestration generic. | FULL-30/BACKUP, sửa MongoDB claim nếu không còn core. |
| 30 | Message flow cũ/khó đọc; title bị che. | BACKUP only hoặc redraw. |
| 31 | Why microservices/AHP, có lý do tốt nhưng block che title. | FULL-30, sửa visual. |
| 32 | Microservices diagram cũ, có Collector/Speech2Text/WebSocket. | DO-NOT-PRESENT; sai ground truth. |
| 33 | Use cases overview 8 UC cũ. | DO-NOT-PRESENT; mâu thuẫn final 5 UC. |
| 34 | Sequence có thể là old flow, chữ quá nhỏ. | BACKUP only nếu annotate rõ. |
| 35 | Data Pipeline 4 giai đoạn cũ: Collector + Speech-to-Text. | DO-NOT-PRESENT; thay bằng Ingest/Scapper/UAP/Analytics. |
| 36 | ERD nghiệp vụ cũ. | BACKUP-QA; chỉ dùng nếu hỏi data model. |
| 37 | ERD analytics cũ. | BACKUP-QA; kiểm lại schema nếu dùng. |
| 38 | Results slide cũ, có 7 FR/8 UC/2 Actors, 4 Go/6 Python. | DO-NOT-PRESENT; phải thay. |
| 39 | UI section divider. | FULL-30, có thể dùng trước demo screenshots. |
| 40 | Future plan divider. | BACKUP-QA. |
| 41 | Hybrid infra future, block che title, có AWS/Lambda future claim. | BACKUP-QA only; nói là future, không current. |
| 42 | Service refinement future, block che title. | BACKUP-QA, sửa visual nếu giữ. |

## 3. Full Deck Đề Xuất Cho 30 Phút

Deck đầy đủ nên có 32 slide chính + backup. Bản 15 phút chỉ nói các slide `CORE-15`, các slide `FULL-30` chỉ đi qua bằng câu pass.

### Section A - Bối cảnh và phạm vi

#### Slide 1 - `SMAP - Social Media Analytics Platform`

Mode: `CORE-15`.

Message:

- Thesis: SMAP là platform phân tích chiến dịch mạng xã hội, không chỉ là dashboard crawl dữ liệu.
- 4 lane chính: control plane, data plane, analytics/knowledge lane, realtime delivery.

Update:

- Sửa subtitle: `Nền tảng phân tích chiến dịch mạng xã hội với control plane, data plane và knowledge lane tách biệt`.
- Fix `SMAPSocial` thành `SMAP - Social Media Analytics Platform`.

#### Slide 2 - `SMAP là gì?`

Mode: `CORE-15`.

On-slide:

- Thu thập dữ liệu công khai từ social platforms.
- Chuẩn hóa dữ liệu theo project/campaign.
- Phân tích sentiment/topic/relevance và tổng hợp insight.
- Cung cấp dashboard, chat/report, notification.

15P:

> SMAP là platform dùng chung cho nhiều campaign/project. Trọng tâm đồ án là kiến trúc hệ thống và luồng dữ liệu, không phải nghiên cứu mô hình AI mới.

30P add:

- Nói rõ ngoài phạm vi: không tối ưu model AI, không claim production SaaS đầy đủ.

#### Slide 3 - `Thị trường Social Listening`

Mode: `FULL-30`, pass trong 15p.

On-slide:

- Quốc tế: Talkwalker, Brandwatch, Meltwater, YouScan.
- Việt Nam: YouNet Media, Buzzmetrics, Reputa, Kompa.
- Hai hướng: dịch vụ phân tích bởi chuyên gia vs nền tảng self-service.

15P pass:

> Thị trường có nhiều giải pháp, nhưng nhóm chọn hướng platform self-service; em đi tiếp vào bài toán hệ thống.

#### Slide 4 - `Bài toán cần giải quyết`

Mode: `CORE-15`.

On-slide:

- Big volume, multi-source, continuous, unstructured.
- Jobs chạy dài, tải biến động, nhiều project đồng thời.
- Cần async, scale, fault isolation, không mất raw data.

Ground truth update:

- Thêm cụm `campaign-specific fairness`: dữ liệu và benchmark phải xét theo project/campaign, không chỉ tổng số bản ghi.

#### Slide 5 - `Mục tiêu và phạm vi`

Mode: `CORE-15`.

On-slide:

- Thiết kế kiến trúc platform social analytics.
- Tổ chức luồng dữ liệu bất đồng bộ.
- Chứng minh bằng deployment, tests, benchmark.
- Ngoài phạm vi: model AI mới, SLA production tuyệt đối, full commercial product.

### Section B - Requirements và kiến trúc

#### Slide 6 - `Yêu cầu hệ thống`

Mode: `CORE-15`.

On-slide:

- `12 FR | 7 NFR | 5 user-goal use cases`.
- Capability groups:
  - Auth/Internal auth.
  - Campaign/Project lifecycle.
  - Datasource/Target execution.
  - Analytics insight.
  - Knowledge chat/report.
  - Notification/Crisis response.

Evidence:

- `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:9`.
- `/Users/tantai/Workspaces/smap/report/final-report/chapter_4/section_4_4.typ:5`.

#### Slide 7 - `Use Case Overview`

Mode: `FULL-30`.

Use page 9 visual, not page 33.

5 use cases:

1. Thiết lập chiến dịch theo dõi.
2. Vận hành chiến dịch theo dõi.
3. Tra cứu và hỏi đáp dữ liệu phân tích.
4. Theo dõi trạng thái và nhận cảnh báo.
5. Thiết lập và quản lý quy tắc khủng hoảng.

15P pass:

> Các use case được gom theo mục tiêu người dùng; nhóm không đếm internal pipeline như user use case.

#### Slide 8 - `Ý tưởng kiến trúc: tách lane theo workload`

Mode: `CORE-15`.

On-slide:

```text
Control plane: Identity + Project
Data plane: Ingest + Scapper + RabbitMQ + MinIO
Analytics lane: Kafka/Redpanda + Analysis + PostgreSQL
Knowledge lane: Knowledge + Qdrant + LLM provider
Realtime lane: Notification + Redis Pub/Sub + WebSocket/Discord critical alert
```

Speaker point:

- Đây là lý do microservices có cơ sở, không phải tách tùy tiện.

#### Slide 9 - `System Context (C4 Level 1)`

Mode: `CORE-15`.

Update visual:

- Sửa block mint che title.
- Actors:
  - Marketing analyst / business user.
  - Admin/operator.
  - Social media platforms / external providers.
  - Identity/provider boundary nếu cần.

Không nói chỉ có 2 actors.

#### Slide 10 - `Container Architecture hiện tại`

Mode: `CORE-15`.

Phải redraw hoặc sửa mạnh.

On-slide service list:

- `web-ui`
- `identity-srv`
- `project-srv`
- `ingest-srv`
- `scapper-srv`
- `analysis-api`, `analysis-consumer`
- `knowledge-srv`
- `notification-srv`
- Infra: PostgreSQL, RabbitMQ, Redpanda/Kafka, Redis, MinIO, Qdrant.

Không dùng:

- `Collector`
- `Speech2Text`
- `WebSocket Service` như service độc lập core
- `MongoDB` như collector storage nếu không chứng minh current runtime.

Evidence:

- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:14`.
- `/Users/tantai/Workspaces/smap/SYSTEM_CONTEXT.md:7`.

#### Slide 11 - `Vì sao Microservices?`

Mode: `FULL-30`.

Sửa page 31.

Nói theo trade-off:

- Lợi: tách workload, scale độc lập, isolate failure, chọn ngôn ngữ theo domain.
- Giá phải trả: deployment/observability phức tạp hơn.
- Biện pháp giảm rủi ro: `smap-deploy` source of truth, K3s namespace, explicit route/health/log runbooks.

15P pass:

> Nhóm chấp nhận độ phức tạp vận hành để cô lập workload có tính chất rất khác nhau.

#### Slide 12 - `Messaging và Storage Matrix`

Mode: `CORE-15`.

Thay page 16 placeholder.

On-slide:

| Layer | Tool | Why |
|---|---|---|
| Task queue | RabbitMQ | ack/retry cho crawl task dài |
| Analytics stream | Redpanda/Kafka | UAP và analytics contract, replay/downstream |
| Realtime fan-out | Redis Pub/Sub | nhẹ, transient, WebSocket delivery |
| Raw payload | MinIO | claim-check artifact |
| Transaction/mart | PostgreSQL | state + query/filter |
| Semantic retrieval | Qdrant | vector search cho chat/report |

### Section C - Runtime flows

#### Slide 13 - `Flow overview: từ campaign đến insight`

Mode: `CORE-15`.

On-slide simplified:

```text
User -> Project setup -> Ingest runtime -> Scapper worker -> Raw MinIO
     -> UAP Kafka -> Analysis post_insight -> Knowledge Qdrant
     -> Dashboard/Chat/Report/Notification
```

Purpose:

- Đây là slide bridge trước khi đi vào 3 flow chi tiết.

#### Slide 14 - `Flow 1A: Campaign, Project, Datasource`

Mode: `FULL-30`.

Sửa page 11.

Không dùng full sequence diagram trong main; sequence chi tiết đưa backup.

On-slide 5 bước:

1. User tạo campaign.
2. User tạo project dưới campaign.
3. `project-srv` validate campaign/domain và lưu PostgreSQL.
4. User cấu hình datasource/target qua `ingest-srv`.
5. Schedule nằm trong `crawl_mode`, `crawl_interval_minutes`, target state.

15P pass:

> Phần setup này chứng minh project-srv giữ business context, ingest-srv giữ execution context.

#### Slide 15 - `Flow 1B: Activation readiness`

Mode: `CORE-15`.

Sửa page 12 thành flow dễ đọc:

1. User bấm activate.
2. `project-srv` detail project + validate status.
3. `project-srv` gọi `ingest-srv` readiness.
4. Nếu readiness fail: block bằng lỗi nghiệp vụ.
5. Nếu pass: ingest activate runtime, project status -> ACTIVE.

Evidence:

- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:12`.
- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:246`.
- `/Users/tantai/Workspaces/smap/project-srv/pkg/microservice/ingest/usecase.go:15`.

#### Slide 16 - `Flow 2: Ingestion, Claim-Check và UAP`

Mode: `CORE-15`.

Sửa page 13 thành diagram:

```text
ListDueTargets -> ClaimTarget -> scheduled_jobs/external_tasks
-> RabbitMQ task -> scapper-srv -> MinIO raw artifact
-> completion -> raw_batches -> UAP parser -> smap.collector.output
```

Speaker point:

- RabbitMQ giải bài toán task worker.
- MinIO giải bài toán payload lớn.
- UAP giải bài toán format thống nhất cho analytics.

Evidence:

- `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:19`.
- `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:62`.
- `/Users/tantai/Workspaces/smap/scapper-srv/app/worker.py:318`.
- `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/usecase.go:62`.

#### Slide 17 - `Flow 3: Analytics, Knowledge, Notification`

Mode: `CORE-15`.

Sửa page 14 thành 3 lane:

1. Analytics lane:
   - consume `smap.collector.output`
   - group by `project_id`, `domain_type_code`
   - persist `analysis.post_insight`
   - publish `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest`
2. Knowledge lane:
   - consume analytics topics
   - index Qdrant
   - serve search/chat/report
3. Notification lane:
   - consume digest/crisis alert
   - publish Redis channel
   - WebSocket delivery
   - Discord only for critical crisis with `ops_alert=true`

Evidence:

- `/Users/tantai/Workspaces/smap/analysis-srv/internal/consumer/server.py:272`.
- `/Users/tantai/Workspaces/smap/analysis-srv/internal/contract_publisher/usecase/publish_order.py:1`.
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_batch.go:17`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:274`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:100`.

#### Slide 18 - `Crisis runtime loop`

Mode: `FULL-30`.

On-slide:

```text
Analysis detects risk -> analytics.crisis.alert
-> notification-srv routes alert
-> analysis-consumer can call project-srv internal apply-runtime
-> project-srv maps crisis level to crawl mode
-> ingest-srv updates datasource runtime
```

Important nuance:

- Business crisis status: `NORMAL`, `WARNING`, `CRITICAL`.
- Crawl mode can be `NORMAL`/`CRISIS`.
- Do not collapse both as one enum.

Evidence:

- `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/usecase/crisis_config.go:119`.
- `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/usecase/crisis_config.go:220`.
- `/Users/tantai/Workspaces/smap/smap-deploy/e2e-report.md:29`.

### Section D - Deployment, implementation, testing

#### Slide 19 - `Triển khai và vận hành`

Mode: `CORE-15`.

Thay page 19 placeholder.

On-slide:

- K3s homelab, namespace `smap`.
- UI: `https://smap.tantai.dev`.
- API: `https://smap-api.tantai.dev`.
- Traefik path prefixes: `/identity`, `/project`, `/ingest`, `/analytics`, `/knowledge`, `/notification`, `/scraper`.
- `smap-deploy` là source of truth.

Evidence:

- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:1`.
- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:58`.

#### Slide 20 - `Module Diagram / Clean Architecture`

Mode: `FULL-30`.

Sửa page 17:

- Giữ Clean Architecture, DIP, feature-based packaging.
- Không cần trình bày quá sâu trong 15p.
- Nếu hỏi code quality, dùng slide này để nói unit test, domain independence, adapter infra.

#### Slide 21 - `Đánh giá hệ thống: strategy`

Mode: `CORE-15`.

Use page 21.

On-slide:

- Unit test: service boundary.
- Integration: service-to-service + infra.
- E2E/live route: public API/UI evidence.
- NFR: benchmark live K8s.

#### Slide 22 - `Unit test evidence`

Mode: `FULL-30`.

Use page 22.

Update:

- Không đọc từng screenshot.
- Nói "unit evidence dùng để chứng minh regression safety".
- Có thể thêm số tổng nếu đã chốt từ report; nếu không, không phóng đại.

#### Slide 23 - `Integration evidence`

Mode: `CORE-15`.

Use page 23.

On-slide:

- Campaign CRUD 8/8.
- Datasource CRUD 6/6.
- Readiness/activation reject đúng business rule.
- Crisis runtime project-srv -> ingest-srv verified.

#### Slide 24 - `E2E/live verification`

Mode: `CORE-15`.

Use page 24.

On-slide:

- 55 endpoints called.
- 44 pass.
- 4 partial.
- 2 not fully tested.
- Kèm caveat: số này là evidence snapshot, không phải 100% completion claim.

#### Slide 25 - `Non-functional evaluation`

Mode: `CORE-15`.

Use page 25.

On-slide:

- Live domain/K8s homelab.
- Locust 50 concurrent users: p95 240ms, error 0.02%.
- k6 1800 req: p95 130ms, 0% error.
- API-lane report p95 <225ms trong measured scenarios.
- AI sentiment: accuracy 0.444, macro F1 0.440.

Caveat bắt buộc:

> Đây là measured baseline trong scenario cụ thể, không phải SLA production tuyệt đối; AI score là baseline quality evidence, không phải claim model tốt.

### Section E - Demo, kết quả, kết luận

#### Slide 26 - `Demo live: user journey`

Mode: `CORE-15`.

Thêm trước Thank You.

On-slide:

1. Open live UI and campaign.
2. Show dashboard map/insights.
3. Show project/settings or lifecycle.
4. Show report/chat if stable.
5. Show K9s/log/health proof.
6. Show notification/Discord proof as backup if safe.

#### Slide 27 - `Kết quả đạt được`

Mode: `CORE-15`.

Thay page 38 cũ.

On-slide:

- Full platform lanes implemented.
- K3s live deployment.
- End-to-end runtime path verified at core boundaries.
- Test/benchmark package with raw evidence.
- Known limitations explicitly documented.

Không dùng:

- `7 FR | 8 Usecase | 2 Actors`.
- `4 Golang service, 6 python service`.

#### Slide 28 - `Giới hạn và hướng phát triển`

Mode: `CORE-15`.

On-slide:

- Long soak/saturation/backlog benchmark chưa đủ.
- Full client WebSocket latency chưa đo riêng.
- AI quality baseline còn thấp.
- External platform/rate limit cần hardening.
- Observability/runbook cần mở rộng.

#### Slide 29 - `Thank You`

Mode: `CORE-15`.

Kết main deck ở đây.

### Backup / Q&A slides

#### Slide B1 - `Old claims corrected`

Mode: `BACKUP-QA`.

Dùng để phòng khi hội đồng thấy slide/diagrams cũ:

| Old claim | Correct current wording |
|---|---|
| Collector service | `ingest-srv` + `scapper-srv` data plane |
| Speech2Text core service | Future/extension, not main current proof |
| WebSocket service | `notification-srv` with WebSocket domain |
| 4 Go + 6 Python | Go core backend + Python analysis/scapper; do not count old services |
| 7 FR / 8 UC / 2 actors | 12 FR / 7 NFR / 5 user-goal UCs |

#### Slide B2 - `Infrastructure components`

Mode: `BACKUP-QA`.

Sửa page 29:

- PostgreSQL: identity/project/ingest/analysis/knowledge metadata and marts.
- MinIO: raw artifacts.
- RabbitMQ: crawl task queue.
- Redpanda/Kafka: UAP + analytics contracts.
- Redis: session/cache/pubsub.
- Qdrant: vector knowledge index.
- Remove MongoDB unless team has current deploy proof.

#### Slide B3 - `Full sequence diagrams`

Mode: `BACKUP-QA`.

Giữ pages 11-14 full sequence nhưng phóng to từng flow hoặc tách thành từng trang:

- B3.1 Setup campaign/project/datasource.
- B3.2 Activation readiness.
- B3.3 Ingestion/UAP.
- B3.4 Analytics/knowledge/notification.

#### Slide B4 - `Data model / ERD`

Mode: `BACKUP-QA`.

Pages 36-37 chỉ dùng nếu hỏi data model. Nếu dùng, phải nói:

- ERD là conceptual/legacy support.
- Runtime schema quan trọng cho defense là project/campaign/config, ingest raw_batches/external_tasks, analysis.post_insight, knowledge indexing tables.

#### Slide B5 - `Notification and Discord`

Mode: `BACKUP-QA`.

Correct claim:

- WebSocket: regular browser delivery.
- Redis Pub/Sub: internal fan-out.
- Discord: critical crisis alert path only when payload severity is critical and `ops_alert=true`.

Evidence:

- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:100`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:112`.

#### Slide B6 - `Benchmark methodology`

Mode: `BACKUP-QA`.

Content:

- Tools: Newman, k6, Locust, JMeter, Python AI evaluator.
- Measured on live K3s/homelab.
- Acceptance threshold error <= 0.1%, p95 <= 2500ms in benchmark kit.
- Limitations: short window, no long soak, no saturation-to-failure.

#### Slide B7 - `AI quality baseline`

Mode: `BACKUP-QA`.

Content:

- Accuracy 0.444, macro F1 0.440.
- Meaning: evaluation loop exists, but model quality is not yet strong.
- Future: domain ontology, better labels, prompt/model tuning, sample expansion.

## 4. Slide Completion Checklist

- [ ] Add mode note convention to every slide.
- [ ] Fix all mint/light-blue overlay blocks that hide titles/tables.
- [ ] Replace page 16 and 19 placeholders.
- [ ] Replace page 27/32/35/38 old architecture/result claims.
- [ ] Convert pages 11-14 into readable simplified flow slides; keep full sequence as backup.
- [ ] Add deployment slide with K3s/domain/source-of-truth.
- [ ] Add demo live slide before Thank You.
- [ ] Add old-claims-corrected backup slide.
- [ ] Move ERD/deep diagrams/future infra after Thank You.
- [ ] Do not claim full production SLA, full real-time latency, or high AI quality.

