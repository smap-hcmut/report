# SMAP Canva Defense Update Pack - 2026-05-21

Mục tiêu của file này là biến deck Canva hiện tại thành bộ slide bảo vệ 15 phút + demo ngắn, đồng thời chuẩn bị bộ phản biện 45 phút. Nội dung bên dưới dựa trên:

- Canva deck `DAHKSMZBTTU` hiện có 42 trang, title `Đồ Án`.
- Presenter notes trong Canva, đặc biệt các trang mô tả Campaign/Project activation, Ingestion/UAP, Analytics/Knowledge/Notification, Testing/NFR.
- Codebase thật trong `/Users/tantai/Workspaces/smap`.
- Source-of-truth triển khai trong `smap-deploy`.
- Final report, benchmark report, E2E report và các tài liệu presentation planning hiện có.

## 1. Kết luận nhanh

Deck hiện tại có nền tảng tốt nhưng chưa sẵn sàng để bảo vệ 15 phút vì đang trộn ba lớp nội dung:

1. Narrative đúng hướng: bài toán social listening, kiến trúc event-driven, claim-check, Clean Architecture, testing/NFR.
2. Ground truth hiện tại: Project -> Ingest -> Scapper -> Analysis -> Knowledge -> Notification -> UI, có K3s deployment và benchmark/evidence thật.
3. Nội dung cũ hoặc placeholder: `Collector`, `Speech2Text`, `WebSocket service`, `4 Golang + 6 Python service`, `7 FR | 8 Usecase | 2 Actors`, các slide còn ghi "dùng dataflow..." hoặc "thêm phần triển khai".

Hướng sửa: rút main deck còn 14 slide, đưa phần còn lại xuống backup. Bài trình bày nên bán một luận điểm chính:

> SMAP không chỉ là dashboard crawl mạng xã hội, mà là một nền tảng phân tích chiến dịch có control plane rõ ràng, data plane bất đồng bộ, analytics/knowledge lane tách riêng, và bằng chứng vận hành đo được trên K3s.

## 2. Ground Truth Phải Khớp Khi Nói

### Service / repo hiện tại

Không nói "Collector/Speech2Text/WebSocket service" như core service đã hoàn thiện. Ground truth theo workspace và deploy hiện tại:

| Nhóm | Service / repo | Vai trò đúng khi thuyết trình |
|---|---|---|
| Control plane | `identity-srv` | Auth, user/session, internal auth boundary. |
| Control plane | `project-srv` | Campaign/project lifecycle, readiness, activation, crisis config, ontology/domain config. |
| Data plane | `ingest-srv` | Datasource/target, scheduler, due target claim, RabbitMQ dispatch, raw batch/UAP publishing. |
| Data plane | `scapper-srv` | Worker nhận crawl task, gọi provider/crawler, lưu artifact MinIO, trả completion về ingest. |
| Analytics lane | `analysis-api`, `analysis-consumer` | Consume UAP, NLP enrichment, persist `analysis.post_insight`, publish analytics contracts. |
| Knowledge lane | `knowledge-srv` | Index Qdrant, chat/report grounded by campaign evidence, analytics fallback. |
| Realtime lane | `notification-srv` | Kafka -> Redis Pub/Sub -> WebSocket notification bridge. |
| Frontend | `web-ui` | Next.js UI cho campaign/project, dashboard, chat/report, notification. |
| Deploy | `smap-deploy` | Source of truth cho namespace, route, service role, K3s runtime. |

Evidence:

- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:14` liệt kê service triển khai chính.
- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:27` mô tả runtime flow Project -> Ingest -> Scapper -> Analysis -> Knowledge/UI.
- `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:11` tổng kết các lane hiện tại.

### Requirements / use cases

Không dùng lại câu "7 FR | 8 Usecase | 2 Actors" trong main deck. Final report hiện tại chốt:

- 12 Functional Requirements.
- 7 Non-functional Requirements.
- 5 user-goal use cases.
- Actor model không chỉ có 2 actor đơn giản; có người dùng, quản trị/vận hành, và identity/provider/system boundary.

Evidence:

- `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:9`.
- `/Users/tantai/Workspaces/smap/report/final-report/chapter_4/section_4_2_note.md:11`.
- `/Users/tantai/Workspaces/smap/report/final-report/chapter_4/section_4_4.typ:5`.

### Messaging / storage

Giải thích theo trách nhiệm, không theo "dùng nhiều công nghệ cho vui":

| Công nghệ | Dùng cho | Lý do bảo vệ |
|---|---|---|
| RabbitMQ | Crawl task dispatch và completion | Work queue cần ack/retry, phù hợp task worker lâu và dễ fail. |
| Kafka/Redpanda | UAP và analytics contract topics | Data/event log cho analytics/knowledge downstream, cần ordering theo topic và replay. |
| Redis Pub/Sub | Notification fan-out nội bộ | Tín hiệu realtime nhẹ, không phải nguồn dữ liệu bền vững. |
| PostgreSQL | Transactional metadata + analytics mart | Campaign/project/config và `analysis.post_insight`; có index/JSONB cho filter. |
| MinIO | Raw artifact / batch object | Claim-check: message nhẹ, payload lớn nằm ở object storage. |
| Qdrant | Vector search cho knowledge/chat/report | Semantic retrieval theo project/campaign, tách khỏi OLTP. |

Evidence:

- `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/delivery/rabbitmq/producer/producer.go:15`.
- `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/delivery/kafka/producer/producer.go`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:19`.
- `/Users/tantai/Workspaces/smap/analysis-srv/migration/init_db.sql:1`.
- `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:87`.
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_batch.go:17`.

## 3. Gap Analysis Theo Deck Canva

### Gap 1 - Deck quá dài so với 15 phút

Hiện tại 42 trang. Với 15 phút bao gồm demo, main deck chỉ nên có 12-14 slide. Nếu giữ 42 slide, team sẽ bị cuốn vào kiến trúc chi tiết và không đủ thời gian demo/kết luận.

Fix:

- Main deck: 14 slide.
- Backup appendix: giữ các slide ERD, module diagram, benchmark raw detail, future work, old deep architecture.
- Q&A 45 phút dùng backup, không trình chiếu hết trong 15 phút.

### Gap 2 - Trộn service cũ và service hiện tại

Các slide sau cần sửa hoặc đưa backup:

- Slide có `4 Golang service, 6 Python service`.
- Slide có `Identity, Collector, Speech2Text, Project, Analytics, WebSocket`.
- Slide pipeline cũ `Crawling Collector + Speech-to-Text`.

Fix:

- Dùng service truth: Go core backend + Python analytics/scapper + Next.js UI.
- Nếu nhắc Speech-to-Text/Whisper, chỉ nói là extension/future hoặc pipeline capability chưa phải trọng tâm defense.

### Gap 3 - Requirements/use case count mâu thuẫn final report

Deck có câu `7 FR | 8 Usecase | 2 Actors`, trong khi report chốt 12 FR, 7 NFR, 5 use cases. Đây là điểm thầy rất dễ bắt.

Fix:

- Slide requirement chỉ dùng: `12 FR | 7 NFR | 5 user-goal use cases`.
- Nhóm theo capability thay vì liệt kê dài:
  - Identity/internal auth.
  - Campaign/project lifecycle.
  - Datasource/target execution.
  - Analytics insight.
  - Knowledge/chat/report.
  - Notification/crisis response.

### Gap 4 - Placeholder trong slide là rủi ro bảo vệ

Một số slide vẫn còn note dạng "dùng dataflow đơn giản..." hoặc "thêm phần triển khai". Nếu trình chiếu, nó làm mất độ tin cậy.

Fix:

- Thay bằng 3 flow thật:
  1. Control plane: Campaign/Project -> readiness -> activation -> ingest runtime.
  2. Data plane: scheduler -> RabbitMQ -> scapper -> MinIO -> raw batch -> UAP -> Kafka.
  3. Insight plane: analysis -> post_insight -> contracts -> knowledge/Qdrant -> notification/WebSocket.

### Gap 5 - Testing/NFR cần nói có caveat

Deck đang có số đẹp, nhưng phải nói đúng:

- E2E report: 55 endpoints, 44 pass, 5 failed, 4 partial, 2 not testable ở thời điểm report.
- NFR benchmark là live K8s baseline, không phải SLA tuyệt đối.
- Notification đã verify route/internal delivery, nhưng chưa đo full client WebSocket latency end-to-end như một NFR riêng.
- AI sentiment accuracy 0.444 macro F1 0.440 là baseline quality evidence, không phải claim "AI rất chính xác".

Fix:

- Slide kết quả nên nói "measured baseline" và "known limitations".
- Khi bị hỏi, thẳng thắn: hệ thống chứng minh architecture/runtime/evidence, còn AI quality là hướng cải thiện.

## 4. Main Deck 14 Slide Cho 15 Phút

| # | Thời lượng | Slide title đề xuất | Mục tiêu | Update Canva |
|---|---:|---|---|---|
| 1 | 0:40 | `SMAP - Social Media Analytics Platform` | Mở bài, nêu luận điểm. | Giữ title, sửa subtitle thành thesis statement ngắn. |
| 2 | 0:50 | `Bài toán: dữ liệu mạng xã hội khó vận hành` | Nêu pain: đa nguồn, nhiễu, realtime, campaign-specific. | Giữ problem/market slide, rút chữ. |
| 3 | 0:50 | `Phạm vi đồ án` | Chốt không phải ML research; là platform/pipeline/ops. | Gộp goal/scope. |
| 4 | 1:00 | `Yêu cầu hệ thống` | 12 FR, 7 NFR, 5 use cases theo capability. | Thay toàn bộ count cũ. |
| 5 | 1:10 | `Ý tưởng kiến trúc` | Vì sao tách control/data/insight/realtime lanes. | Dùng diagram đơn giản. |
| 6 | 1:10 | `Container Architecture hiện tại` | Map service thật. | Sửa C4/container theo repo thật. |
| 7 | 1:00 | `Flow 1: Project activation` | Nói control plane không chỉ CRUD. | Dùng notes trang 11-12 thành slide chính. |
| 8 | 1:20 | `Flow 2: Ingestion và Claim-Check` | Scheduler -> RabbitMQ -> scapper -> MinIO -> UAP -> Kafka. | Thay placeholder dataflow. |
| 9 | 1:20 | `Flow 3: Analytics, Knowledge, Notification` | UAP -> NLP -> post_insight -> contracts -> Qdrant/WS. | Dùng notes trang 14 thành slide. |
| 10 | 0:55 | `Triển khai trên K3s homelab` | Chứng minh hệ thống chạy thật. | Thay placeholder deployment. |
| 11 | 1:00 | `Testing evidence` | Unit/integration/E2E có mapping FR/NFR. | Giữ testing slide, sửa số và caveat. |
| 12 | 1:00 | `Benchmark và chất lượng AI` | NFR baseline + AI baseline minh bạch. | Giữ benchmark slide, thêm caveat. |
| 13 | 3:00 | `Demo live` | Show flow người dùng: project/dashboard/chat/report/notification. | Slide demo checklist, không chữ dài. |
| 14 | 0:45 | `Kết luận và giới hạn` | Kết luận đóng vòng + limitations. | Giữ conclusion/future nhưng chuyển limitation rõ. |

Tổng: khoảng 14:00-14:30, còn 30-60 giây buffer.

## 5. Cách Sửa Cụ Thể Trên Canva

### Giữ và chỉnh

- Trang 1: giữ title nhưng sửa headline phụ:
  - Nên dùng: `Nền tảng phân tích chiến dịch mạng xã hội với control plane, data plane và knowledge lane tách biệt`.
- Trang 2-6: giữ phần bối cảnh/vấn đề/thị trường/scope nhưng rút còn tối đa 3 ý/slide.
- Các slide C4/context/container: giữ nếu hình không còn service cũ. Nếu có `Collector`, `Speech2Text`, `WebSocket service`, sửa ngay.
- Slide Event-Driven Architecture và Claim-Check: giữ, nhưng thêm ví dụ thật từ SMAP.
- Slide Clean Architecture/module: đưa backup nếu không có thời gian; chỉ nhắc 1 câu trong main.
- Slide testing/NFR: giữ, cập nhật số và caveat.

### Thay hoặc xóa khỏi main deck

- Xóa khỏi main: `4 Golang service, 6 Python service`.
- Xóa hoặc đưa backup: `Identity, Collector, Speech2Text, Project, Analytics, WebSocket`.
- Xóa count cũ `7 FR | 8 Usecase | 2 Actors`.
- Xóa placeholder text dạng "dùng dataflow..." hoặc "thêm phần triển khai".
- ERD chi tiết: backup. Trong 15 phút chỉ cần nói storage responsibility.
- Future work/hybrid infra dài: backup, chỉ giữ 1 slide limitation/future.

### Convert presenter notes thành slide thật

Presenter notes trang 11-14 trong Canva hiện đã rất tốt. Nên biến thành 3 slide chính:

1. `Flow 1: Project activation`
   - Project-srv validate status.
   - Gọi ingest readiness.
   - Nếu đủ datasource/target thì ingest activate runtime.
   - Project status chuyển ACTIVE.
   - Crisis config có thể đổi crawl mode qua internal runtime API.

2. `Flow 2: Ingestion and UAP`
   - Scheduler tìm due target.
   - Atomic claim tránh duplicate job.
   - RabbitMQ dispatch task cho scapper worker.
   - Worker upload artifact lên MinIO.
   - Ingest parse raw batch thành UAP.
   - UAP publish sang Kafka/Redpanda.

3. `Flow 3: Insight delivery`
   - Analysis consume UAP theo project/domain.
   - Persist `analysis.post_insight`.
   - Publish `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest`.
   - Knowledge index Qdrant và hỗ trợ chat/report.
   - Notification consume digest/crisis alert, fan-out Redis/WebSocket.

## 6. Script Thuyết Trình 15 Phút

### Slide 1 - Title

> Em xin trình bày đồ án SMAP - Social Media Analytics Platform. Luận điểm chính của nhóm là: để phân tích mạng xã hội theo chiến dịch, vấn đề không chỉ là crawl dữ liệu hay vẽ dashboard, mà là xây dựng một nền tảng có control plane để quản lý chiến dịch, data plane để thu thập dữ liệu bất đồng bộ, analytics lane để biến dữ liệu thô thành insight, và knowledge lane để hỗ trợ chat/report có căn cứ.

### Slide 2 - Bài toán

> Dữ liệu mạng xã hội có ba khó khăn lớn. Thứ nhất là đa nguồn và không đồng nhất: Facebook, YouTube, TikTok có format, rate limit và hành vi khác nhau. Thứ hai là nhiễu: không phải bài nào chứa từ khóa cũng liên quan đến chiến dịch. Thứ ba là tính thời gian: khi có khủng hoảng truyền thông, hệ thống phải tăng tần suất theo dõi và gửi tín hiệu sớm, thay vì đợi báo cáo thủ công.

### Slide 3 - Phạm vi

> Phạm vi đồ án của nhóm là platform engineering cho bài toán social listening. Nhóm không đặt mục tiêu tạo một mô hình AI mới, mà xây dựng pipeline và hệ thống vận hành: quản lý campaign/project, cấu hình nguồn dữ liệu, thu thập bất đồng bộ, phân tích sentiment/topic/relevance, lưu insight, tìm kiếm tri thức và thông báo realtime. Vì vậy tiêu chí đánh giá là đúng luồng nghiệp vụ, đúng contract giữa service, và có evidence test/benchmark.

### Slide 4 - Requirements

> Yêu cầu được gom theo capability. Final report hiện tại chốt 12 functional requirements, 7 non-functional requirements và 5 nhóm use case theo mục tiêu người dùng. Các capability chính gồm: authentication/internal auth, campaign/project lifecycle, datasource/target execution, analytics insight, knowledge chat/report, và notification/crisis response. Cách gom này giúp tránh liệt kê API rời rạc, đồng thời trace được từng yêu cầu tới test và module triển khai.

### Slide 5 - Ý tưởng kiến trúc

> SMAP tách thành nhiều lane vì mỗi lane có đặc tính vận hành khác nhau. Control plane cần consistency và validation, nên dùng Project/Identity service và PostgreSQL. Data plane có task lâu, dễ retry, nên dùng scheduler, RabbitMQ và worker. Analytics lane cần consume event và tạo mart, nên dùng Kafka/Redpanda và analysis database. Knowledge lane cần semantic search, nên dùng Qdrant. Notification lane cần fan-out nhanh, nên dùng Redis Pub/Sub và WebSocket. Việc tách lane không phải để làm microservices cho phức tạp, mà để cô lập rủi ro và scale đúng điểm nghẽn.

### Slide 6 - Container Architecture

> Container architecture hiện tại gồm các service chính: identity-srv, project-srv, ingest-srv, scapper-srv, analysis-api/analysis-consumer, knowledge-srv, notification-srv và web-ui. Repo `smap-deploy` là source of truth cho deployment trên K3s, route public và service role. Điểm quan trọng là UI không gọi database trực tiếp; UI đi qua API boundary. Các service đồng bộ dùng internal HTTP khi cần validation tức thời, còn dữ liệu/insight đi qua message bus.

### Slide 7 - Flow 1: Project Activation

> Khi user kích hoạt project, project-srv không đơn giản đổi status. Nó kiểm tra status hiện tại, gọi ingest-srv để lấy activation readiness, kiểm tra datasource/target đã đủ điều kiện, sau đó mới gọi ingest activate runtime và update project sang ACTIVE. Với crisis config, project-srv cũng là nơi quyết định khi nào cần chuyển crawl mode sang CRISIS và gọi internal endpoint của ingest-srv. Flow này chứng minh control plane có business rule, không phải CRUD mỏng.

### Slide 8 - Flow 2: Ingestion và Claim-Check

> Data plane bắt đầu từ scheduler trong ingest-srv. Scheduler query các target active đã đến hạn, claim target bằng update có điều kiện để tránh hai worker tạo cùng job. Sau đó ingest tạo scheduled job/external task và publish task qua RabbitMQ. Scapper worker nhận task, gọi crawler/provider, lưu kết quả lớn lên MinIO và gửi completion về ingest. Ingest verify object, parse raw batch thành UAP và publish record sang Kafka/Redpanda. Đây là claim-check pattern: message chỉ chứa metadata, payload lớn nằm ở object storage.

### Slide 9 - Flow 3: Analytics, Knowledge, Notification

> Analysis-consumer consume UAP, group theo project và domain, chạy normalization, dedup, NLP enrichment, relevance/sentiment/topic/aspect, sau đó persist vào `analysis.post_insight`. Sau khi flush, service publish các contract topic theo thứ tự: batch completed, insights published, report digest. Knowledge-srv consume các topic này để index Qdrant, phục vụ chat/report có citation. Notification-srv consume digest hoặc crisis alert, đẩy qua Redis Pub/Sub và WebSocket. Vì vậy insight không chỉ nằm ở dashboard, mà còn đi vào knowledge và realtime signal.

### Slide 10 - Deployment

> Hệ thống được deploy trên K3s homelab namespace `smap`. Public UI là `smap.tantai.dev`, API là `smap-api.tantai.dev` với path prefix cho từng service. `smap-deploy/single-source-of-truth.md` được dùng làm tài liệu nguồn cho route, namespace, service role và các lưu ý runtime. Đây là điểm nhóm dùng để tránh tình trạng slide nói một kiểu nhưng production route chạy một kiểu khác.

### Slide 11 - Testing Evidence

> Nhóm kiểm thử theo bốn lớp: unit test cho logic service, integration/API test cho contract giữa service, E2E/live test cho route triển khai, và NFR benchmark trên K3s. Evidence hiện tại có campaign CRUD 8/8, datasource CRUD 6/6, project lifecycle/readiness/activation được verify, crisis runtime bridge project-srv -> ingest-srv được verify. E2E report ghi nhận 55 endpoints, trong đó 44 pass, 4 partial và có một số failed/not-testable ở thời điểm report. Nhóm trình bày con số này minh bạch để thể hiện cả phần đã đạt và giới hạn còn lại.

### Slide 12 - Benchmark và AI Quality

> Benchmark không được trình bày như SLA tuyệt đối, mà là measured baseline trên môi trường K3s cụ thể. API-lane benchmark có p95 dưới khoảng 225ms trong các scenario báo cáo; benchmark kit cũng có k6 1800 requests p95 khoảng 130ms, Locust 50 concurrent users p95 khoảng 240ms với error 0.02%. Với AI quality, sentiment baseline accuracy khoảng 0.444, macro F1 khoảng 0.440 trên sample. Con số này cho thấy hệ thống có evaluation loop, đồng thời xác định rõ hướng cải thiện chất lượng mô hình và ontology.

### Slide 13 - Demo

> Demo của nhóm sẽ đi theo một user journey ngắn: mở UI, chọn campaign/project, xem project lifecycle hoặc cấu hình crisis, mở dashboard insight theo campaign, sau đó demo chat/report hoặc notification nếu tín hiệu realtime đang sẵn sàng. Mục tiêu demo là chứng minh luồng platform end-to-end ở mức người dùng, không phải chạy lại toàn bộ crawl job live trong vài phút.

### Slide 14 - Kết luận

> Kết quả chính của SMAP là một nền tảng phân tích chiến dịch có kiến trúc tách lane rõ ràng, có code service tương ứng, có deployment thật, có test và benchmark evidence. Giới hạn hiện tại là benchmark còn theo cửa sổ đo ngắn, notification chưa đo full client latency như một NFR riêng, và AI quality còn là baseline. Hướng tiếp theo là tăng observability/runbook, mở rộng benchmark dài hơn, và cải thiện analytics/knowledge quality.

## 7. Demo Plan 3-4 Phút

### Demo chính

1. Mở `https://smap.tantai.dev`.
2. Chọn một campaign/project có dữ liệu.
3. Show project status/lifecycle hoặc settings:
   - Nếu có nút Activate/Pause/Resume hoặc crisis config: nói đây là control plane.
   - Không dành thời gian tạo campaign mới nếu dữ liệu seed không chắc.
4. Show dashboard/insights:
   - Filter theo campaign/project.
   - Chỉ ra sentiment/topic/source/relevance.
   - Nói dữ liệu đến từ `analysis.post_insight` hoặc latest insight mart.
5. Show knowledge/chat/report nếu ổn:
   - Hỏi một câu theo campaign, ví dụ: "Tóm tắt sentiment chính của chiến dịch này".
   - Nếu chat/report chậm, chuyển qua dashboard và nói knowledge lane dùng Qdrant + analytics fallback.
6. Nếu notification có tín hiệu:
   - Show WebSocket notification hoặc notification UI.
   - Nếu không có live event, nói route/internal bridge đã verify, demo chính tập trung dashboard/chat.

### Demo fallback nếu mạng/service chậm

Nếu live demo không ổn trong phòng:

- Dùng screenshot hoặc browser tab đã load sẵn.
- Chỉ nói: "Do thời lượng demo ngắn, em dùng project đã có dữ liệu thay vì kích hoạt crawl job mới. Luồng crawl thật đã được verify trong E2E/benchmark report và có evidence ở backup slide."
- Không cố trigger dryrun/crawl live vì dryrun/target activation có conditional readiness và dễ mất thời gian.

## 8. Q&A Phản Biện 45 Phút

### 1. Vì sao chọn microservices, có over-engineering không?

Trả lời:

> Nếu chỉ làm dashboard nhỏ thì monolith đủ. Nhưng SMAP có nhiều workload khác nhau: request/CRUD cần consistency, crawl task chạy lâu và có retry, analytics consume event theo batch, knowledge cần vector search, notification cần fan-out realtime. Nhóm tách service theo lane vận hành để cô lập lỗi và scale đúng điểm nghẽn. Ví dụ scapper worker fail không làm project-srv mất khả năng quản lý campaign; analytics chậm không làm activation project bị chặn. Điểm trade-off là vận hành phức tạp hơn, nên nhóm dùng `smap-deploy` làm source of truth và giới hạn service boundary theo capability.

### 2. Vì sao dùng cả RabbitMQ, Kafka/Redpanda và Redis Pub/Sub?

Trả lời:

> Ba công nghệ giải ba loại vấn đề khác nhau. RabbitMQ dùng cho crawl task vì cần ack/retry và worker queue. Kafka/Redpanda dùng cho UAP và analytics contract vì đó là data/event stream cần downstream consume và có khả năng replay. Redis Pub/Sub dùng cho notification fan-out nhẹ, không phải persistent data log. Nếu dùng một bus cho tất cả, hoặc task retry sẽ khó, hoặc notification bị nặng, hoặc analytics thiếu log semantics.

### 3. Claim-check pattern trong hệ thống là gì?

Trả lời:

> Payload crawl có thể lớn, gồm raw posts/comments/media metadata. Nếu nhét toàn bộ vào message queue thì message nặng, retry tốn tài nguyên và dễ vượt limit. Claim-check pattern nghĩa là queue chỉ chứa metadata và pointer, còn dữ liệu lớn lưu ở MinIO. Scapper upload artifact lên MinIO, ingest nhận completion, verify object rồi parse thành UAP. Cách này làm message nhỏ, worker dễ retry và dữ liệu raw vẫn audit được.

### 4. Vì sao không lưu hết vào PostgreSQL?

Trả lời:

> PostgreSQL phù hợp metadata, campaign config, transactional state và analytics mart đã chuẩn hóa. Nhưng raw crawl artifact lớn và không đồng nhất nên phù hợp object storage. Vector embedding cần similarity search nên dùng Qdrant. Notification transient dùng Redis. Nhóm không dùng một database cho mọi thứ vì mỗi loại dữ liệu có pattern truy vấn và lifecycle khác nhau.

### 5. Vì sao dùng Qdrant?

Trả lời:

> Knowledge/chat/report cần truy vấn ngữ nghĩa theo nội dung bài viết, digest và insight. PostgreSQL/MongoDB có thể filter tốt nhưng không tối ưu semantic vector search. Qdrant là vector database chuyên dụng, có collection theo project và hỗ trợ upsert/search embedding. Nhóm vẫn giữ analytics truth ở PostgreSQL; Qdrant là index phục vụ retrieval, không phải nguồn sự thật duy nhất.

### 6. Vì sao Go và Python?

Trả lời:

> Go dùng cho service backend cần API, lifecycle, concurrency và deployment nhẹ. Python dùng cho analytics/scapper vì hệ sinh thái NLP, crawler và data processing thuận tiện hơn. Đây là split theo ecosystem: control/data-plane service ổn định bằng Go, AI/data-processing bằng Python.

### 7. Hệ thống có thật sự realtime không?

Trả lời:

> Nhóm không claim realtime tuyệt đối. Luồng notification là near-real-time sau khi analytics publish digest hoặc crisis alert. Latency phụ thuộc vào crawl interval, queue, analytics cadence và WebSocket delivery. Evidence hiện có verify route/internal bridge, Redis/WebSocket wiring và crisis alert path; full client end-to-end latency chưa được đo như một NFR riêng, nên nhóm ghi rõ là limitation.

### 8. Nếu professor hỏi "AI accuracy 0.444 thấp quá?"

Trả lời:

> Đúng, nhóm không trình bày đây là mô hình sentiment tốt. Đây là baseline evaluation để chứng minh hệ thống có vòng đo chất lượng AI. Mục tiêu đồ án là platform/pipeline/evidence, không phải research một mô hình sentiment mới. Con số này giúp nhóm xác định hướng cải thiện: ontology theo domain, labeling tốt hơn, prompt/model tuning và benchmark mở rộng.

### 9. Vì sao E2E không pass 100%?

Trả lời:

> Vì E2E report đo cả những endpoint đang partial, feature gap hoặc phụ thuộc trạng thái dữ liệu. Nhóm không che số này: 55 endpoints, 44 pass, 4 partial và còn failed/not-testable tại thời điểm report. Điều quan trọng là các luồng core đã verify: campaign CRUD, datasource CRUD, project lifecycle/readiness/activation, crisis runtime bridge. Các điểm chưa pass được ghi thành limitation/follow-up.

### 10. Dryrun chưa hoàn chỉnh thì ảnh hưởng gì?

Trả lời:

> Dryrun là chức năng hỗ trợ kiểm tra keyword/target trước activation. Core platform vẫn có lifecycle, datasource/target config, scheduler, crawl dispatch và analytics pipeline. Tuy nhiên, nếu dryrun mapping chưa full, một số target activation có thể bị chặn bởi readiness rule. Khi demo, nhóm không nên live-trigger dryrun mà nên show project có dữ liệu và nói rõ limitation.

### 11. Crisis runtime hoạt động thế nào?

Trả lời:

> Crisis config nằm ở project-srv. Khi phân tích phát hiện mức cảnh báo đủ ngưỡng, analysis-consumer có thể gọi project-srv internal runtime apply. Project-srv map crisis level sang crawl mode, gọi ingest-srv để cập nhật runtime crawl mode cho datasource/target liên quan. Evidence E2E đã verify WARNING -> CRISIS -> NORMAL và có audit row trong ingest.

### 12. Làm sao tránh duplicate crawl job?

Trả lời:

> Ingest scheduler không chỉ select due target rồi dispatch. Nó claim target bằng update có điều kiện trên trạng thái active/due và next crawl time. Nếu một worker khác đã claim trước, rows affected bằng 0 và target bị skip. Đây là cách atomic claim để giảm duplicate trong môi trường concurrent.

### 13. Nếu scapper worker fail giữa chừng?

Trả lời:

> Task queue dùng RabbitMQ với ack/retry semantics. Worker cũng publish completion payload gồm trạng thái success/error/timeout. Nếu success thì có artifact pointer MinIO; nếu fail thì ingest có completion/error để mark task. Đây là lý do RabbitMQ phù hợp hơn direct HTTP cho crawl task dài.

### 14. Nếu analytics chậm thì UI có chết không?

Trả lời:

> UI vẫn có thể truy cập project/control plane vì analytics lane tách riêng. Dashboard có thể hiển thị dữ liệu mới nhất đã materialize. Trong production-stability fix trước đó, nhóm cũng xử lý các vấn đề timeout bằng latest insight mart/materialized view và index phù hợp. Trade-off là insight có thể trễ, nhưng hệ thống không nên fail toàn bộ.

### 15. Vì sao cần materialized/latest insight mart?

Trả lời:

> Raw `analysis.post_insight` có thể nhiều dòng và có nhiều phiên bản insight. Dashboard thường cần bản mới nhất theo project/source/content và filter nhanh theo sentiment/relevance/time. Latest insight mart giúp query UI ổn định hơn, giảm timeout, trong khi raw table vẫn giữ lịch sử/audit.

### 16. Làm sao đảm bảo dữ liệu đúng campaign?

Trả lời:

> Từ datasource/target đến UAP và post_insight đều mang project/campaign/domain metadata. Scheduler query target theo project/datasource active, analysis group theo project/domain, dashboard filter theo project. Đây là lý do nhóm nhấn mạnh campaign fairness: đo và hiển thị theo phạm vi chiến dịch, không chỉ tổng throughput toàn hệ thống.

### 17. Off-topic/noisy posts xử lý thế nào?

Trả lời:

> Hệ thống có nhiều lớp giảm nhiễu: keyword/domain config ở project, relevance/ontology ở analytics, latest insight mart có guardrail/filter để dashboard không chỉ dựa vào text contains keyword. Nhóm vẫn thừa nhận đây là điểm cần cải thiện bằng dữ liệu label và ontology domain tốt hơn.

### 18. Vì sao không chỉ dùng Metabase/Grafana?

Trả lời:

> Metabase/Grafana phù hợp visualization trên dữ liệu đã có. SMAP cần nhiều phần trước visualization: campaign lifecycle, datasource/target execution, crawl worker, raw artifact, UAP normalization, NLP, crisis runtime, knowledge/chat/report và notification. Dashboard chỉ là một surface của platform.

### 19. Vì sao `smap-deploy` là source of truth?

Trả lời:

> Vì trong microservices, thông tin route/namespace/service role rất dễ lệch giữa code, slide và production. `smap-deploy/single-source-of-truth.md` chốt domain, path prefix, namespace, service role và runtime flow. Khi thuyết trình, nhóm bám tài liệu này để tránh nói sai deployment.

### 20. Benchmark có đại diện production thật không?

Trả lời:

> Benchmark chạy trên live K3s/homelab deployment thật, nên có giá trị hơn test local. Nhưng nó vẫn là baseline trong cửa sổ đo cụ thể, không phải SLA tuyệt đối. Báo cáo nói rõ workload 12-20 phút, chưa có long soak, chưa đo saturation/backlog drain. Vì vậy kết luận đúng là "đạt baseline trong scenario đã đo".

### 21. 50 concurrent users có nghĩa gì?

Trả lời:

> Đó là mức tải cao nhất đã test trong benchmark kit mà hệ thống vẫn nằm trong ngưỡng acceptance của nhóm, không phải giới hạn tối đa cuối cùng của hệ thống. Muốn claim capacity thật cần stress test tăng dần đến saturation, đo queue backlog, CPU/memory và error profile dài hơn.

### 22. Vì sao test API-lane p95 nhưng không test toàn bộ crawl end-to-end?

Trả lời:

> API-lane p95 đo responsiveness của route public/control/query. Crawl end-to-end phụ thuộc external platform, queue worker, provider rate limit và analytics cadence, nên cần benchmark riêng theo job duration/backlog. Nhóm đã có evidence cho dispatch/completion và live E2E core flows, nhưng không claim p95 API là p95 toàn pipeline crawl.

### 23. Làm sao kiểm soát quyền admin/RBAC?

Trả lời:

> Các route nhạy cảm như crisis config được bảo vệ bằng admin-only middleware hoặc internal auth boundary. User-facing route và internal runtime route tách nhau. Đây là điểm quan trọng vì crisis runtime có thể thay đổi crawl mode, không nên mở như API public thường.

### 24. Nếu knowledge/Qdrant thiếu collection thì sao?

Trả lời:

> Knowledge-srv có logic ensure collection khi index batch/digest. Trước đây production có lỗi missing collection và đã được harden. Khi search mà project chưa có index, hệ thống nên trả empty/controlled result thay vì xem như service outage.

### 25. Chat/report có hallucination không?

Trả lời:

> Rủi ro có, nên nhóm thiết kế knowledge lane dựa trên indexing/citation và analytics fallback. Chat/report nên trả lời dựa trên insight đã lưu theo project, không tự suy diễn ngoài campaign. Đây cũng là lý do report/chat quality được đưa vào future improvement, gồm citation, grounding và domain ontology.

### 26. Vì sao actor/use case đổi so với slide cũ?

Trả lời:

> Slide cũ là snapshot sớm. Sau khi mapping final report, nhóm chuyển sang capability-based requirements: 12 FR, 7 NFR, 5 user-goal use cases. Cách này chính xác hơn vì các flow như internal auth, analytics, notification là supporting capability, không nên đếm lẫn thành user use case độc lập.

### 27. Có gì là implemented, có gì là future?

Trả lời:

> Implemented: campaign/project lifecycle, datasource/target execution, scheduler/worker path, raw artifact/UAP, analytics post insight, knowledge indexing/chat/report surface, notification bridge, K3s deployment, test/benchmark evidence. Future/limited: long-soak benchmark, full WebSocket client latency measurement, stronger AI sentiment/ontology quality, broader external-source hardening, deeper observability/runbook.

### 28. Nếu thầy hỏi "điểm mới của đồ án là gì?"

Trả lời:

> Điểm mới ở cấp đồ án là cách kết hợp campaign control plane với event-driven data/analytics/knowledge pipeline có evidence vận hành. Nhiều demo social listening chỉ dừng ở crawl + dashboard; SMAP thêm lifecycle/readiness, crisis runtime, claim-check ingestion, analytics contract, vector knowledge và benchmark/test mapping.

### 29. Nếu thầy hỏi "nhóm học được gì?"

Trả lời:

> Nhóm học được rằng hệ thống dữ liệu không chỉ đúng ở thuật toán mà còn phải đúng contract, đúng trạng thái vận hành và có evidence. Các vấn đề như route prefix, missing Qdrant collection, analytics timeout, readiness rule hay notification latency đều là bài học về production engineering. Vì vậy nhóm trình bày cả kết quả và limitation thay vì chỉ show giao diện.

### 30. Nếu thầy bắt lỗi "slide nói social listening market nhưng demo là hệ thống nội bộ?"

Trả lời:

> Market slide là bối cảnh nhu cầu. Contribution của đồ án không phải bán sản phẩm hoàn chỉnh như Brandwatch, mà xây dựng prototype platform có các building block cốt lõi: campaign config, multi-source ingestion, analytics insight, knowledge retrieval và notification. Demo tập trung vào capability đã implement trong phạm vi đồ án.

## 9. Evidence Map Nên Đưa Vào Backup

| Claim | Evidence |
|---|---|
| Project activation có readiness và ingest activation | `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:12`, `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:246`, `/Users/tantai/Workspaces/smap/project-srv/pkg/microservice/ingest/usecase.go:15` |
| Crisis config đổi crawl mode qua internal runtime | `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/usecase/crisis_config.go:119`, `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/usecase/crisis_config.go:220`, `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/delivery/http/routes.go:13` |
| Scheduler list/claim due targets | `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/usecase/cron.go:12`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:19`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:62` |
| RabbitMQ dispatch | `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/usecase/usecase.go:204`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/delivery/rabbitmq/producer/producer.go:15` |
| Scapper upload MinIO và completion | `/Users/tantai/Workspaces/smap/scapper-srv/app/worker.py:239`, `/Users/tantai/Workspaces/smap/scapper-srv/app/worker.py:318`, `/Users/tantai/Workspaces/smap/scapper-srv/app/worker.py:336` |
| Raw batch -> UAP -> publish | `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/usecase.go:14`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/usecase.go:38`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/usecase.go:62`, `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/publisher.go:23` |
| Analysis consumes UAP và publishes contracts | `/Users/tantai/Workspaces/smap/analysis-srv/README.md:194`, `/Users/tantai/Workspaces/smap/analysis-srv/internal/consumer/server.py:272`, `/Users/tantai/Workspaces/smap/analysis-srv/internal/consumer/server.py:373`, `/Users/tantai/Workspaces/smap/analysis-srv/internal/contract_publisher/usecase/publish_order.py:1` |
| Latest insight mart và index | `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:1`, `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:87`, `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:123` |
| Knowledge consumes analytics and indexes Qdrant | `/Users/tantai/Workspaces/smap/knowledge-srv/internal/consumer/handler.go:22`, `/Users/tantai/Workspaces/smap/knowledge-srv/internal/consumer/handler.go:69`, `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_batch.go:17`, `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_digest.go:60` |
| Chat/report analytics fallback | `/Users/tantai/Workspaces/smap/knowledge-srv/internal/chat/usecase/analytics_fallback.go:18`, `/Users/tantai/Workspaces/smap/knowledge-srv/internal/report/delivery/http/handlers.go:12` |
| Notification Kafka -> Redis -> WebSocket | `/Users/tantai/Workspaces/smap/notification-srv/internal/httpserver/handler.go:36`, `/Users/tantai/Workspaces/smap/notification-srv/internal/httpserver/handler.go:71`, `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:95`, `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:146` |
| Deploy source of truth | `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:1`, `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:14`, `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:58` |
| E2E numbers and crisis bridge | `/Users/tantai/Workspaces/smap/smap-deploy/e2e-report.md:14`, `/Users/tantai/Workspaces/smap/smap-deploy/e2e-report.md:29`, `/Users/tantai/Workspaces/smap/smap-deploy/e2e-report.md:31`, `/Users/tantai/Workspaces/smap/smap-deploy/e2e-report.md:39` |
| Benchmark numbers | `/Users/tantai/Workspaces/smap/report/benchmark/reports/20260520-204400/benchmark-report.md:7`, `/Users/tantai/Workspaces/smap/report/benchmark/reports/20260520-204400/benchmark-report.md:35`, `/Users/tantai/Workspaces/smap/report/benchmark/reports/20260520-204400/benchmark-report.md:54`, `/Users/tantai/Workspaces/smap/report/benchmark/reports/20260520-204400/benchmark-report.md:72` |
| Final report limitation/conclusion | `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:31`, `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:51` |

## 10. Backup Slide Đề Xuất Cho 45 Phút Q&A

1. `Messaging matrix: RabbitMQ vs Kafka vs Redis`
2. `Storage matrix: PostgreSQL vs MinIO vs Qdrant`
3. `Activation readiness sequence`
4. `Crisis runtime sequence`
5. `Claim-check pattern with raw batch`
6. `UAP contract and analytics topics`
7. `Latest insight mart and dashboard filters`
8. `Knowledge indexing and chat/report grounding`
9. `Notification bridge and near-real-time caveat`
10. `FR/NFR traceability table`
11. `E2E endpoint result summary`
12. `Benchmark methodology and caveats`
13. `AI quality baseline and improvement plan`
14. `Known limitations`
15. `Implemented vs future scope`

## 11. Checklist Cho Team Trước Khi Lên Bảo Vệ

- [ ] Main deck còn khoảng 14 slide, backup để sau `Thank you`.
- [ ] Xóa hoặc sửa mọi chữ `Collector`, `Speech2Text`, `WebSocket service` nếu đang nói như service core hiện tại.
- [ ] Sửa count thành `12 FR | 7 NFR | 5 user-goal use cases`.
- [ ] Xóa toàn bộ placeholder text.
- [ ] Thêm 3 flow thật: activation, ingestion/UAP, analytics/knowledge/notification.
- [ ] Slide benchmark có caveat "measured baseline, not absolute SLA".
- [ ] Slide AI quality nói là baseline, không claim model tốt.
- [ ] Demo mở sẵn tab UI/project/dashboard/chat trước khi trình bày.
- [ ] Chuẩn bị fallback screenshot nếu live network chậm.
- [ ] Người phản biện học thuộc 10 câu: microservices, RabbitMQ/Kafka/Redis, claim-check, Qdrant, E2E not 100%, AI accuracy, realtime caveat, dryrun limitation, benchmark scope, implemented vs future.

