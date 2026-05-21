# SMAP 15-Minute Presentation Follow Script

Mục tiêu: dùng full deck 30 phút nhưng trình bày trong 15 phút có kiểm soát. Người nói cần bám `CORE-15`, pass nhanh `FULL-30`, không mở `BACKUP-QA` trừ khi hội đồng hỏi.

## Timebox tổng

| Mốc | Nội dung | Thời lượng |
|---|---|---:|
| 0:00-1:00 | Mở bài + SMAP là gì | 1:00 |
| 1:00-2:30 | Bài toán + phạm vi | 1:30 |
| 2:30-4:00 | Requirements + architecture idea | 1:30 |
| 4:00-6:00 | C4/context/container | 2:00 |
| 6:00-9:00 | 3 runtime flows | 3:00 |
| 9:00-10:30 | Deployment + testing | 1:30 |
| 10:30-11:45 | NFR/benchmark | 1:15 |
| 11:45-14:15 | Demo live | 2:30 |
| 14:15-15:00 | Kết luận + limitation | 0:45 |

## Rule khi bị trễ

Nếu tới phút 7 chưa nói xong flow 2, bỏ `Flow 1A` chi tiết và nói câu pass:

> Phần sequence đầy đủ nhóm để trong backup; em đi vào hai điểm quan trọng nhất là claim-check ingestion và analytics/knowledge output.

Nếu tới phút 10 chưa bắt đầu testing, bỏ unit screenshot và chỉ nói integration + benchmark.

Nếu tới phút 12 chưa demo, bỏ chat/report live, chỉ show dashboard + health/K9s proof.

## Script theo slide

### Slide 1 - Title

Mode: `CORE-15`, 30-40 giây.

Nói:

> Em xin trình bày đồ án SMAP - Social Media Analytics Platform. Luận điểm chính của nhóm là: bài toán social listening không chỉ là crawl dữ liệu và vẽ dashboard, mà là xây dựng một nền tảng phân tích chiến dịch có control plane, data plane, analytics/knowledge lane và realtime delivery. Trong 15 phút, em sẽ tập trung vào flow chính, evidence vận hành và demo.

### Slide 2 - SMAP là gì?

Mode: `CORE-15`, 30 giây.

Nói:

> SMAP là nền tảng thu thập dữ liệu mạng xã hội công khai, chuẩn hóa theo campaign/project, phân tích sentiment/topic/relevance và cung cấp dashboard, chat/report, notification. Trọng tâm đồ án là kiến trúc hệ thống và luồng dữ liệu bất đồng bộ, không phải nghiên cứu mô hình AI mới.

### Slide 3 - Thị trường

Mode: `FULL-30`, pass trong 15 giây.

Nói:

> Nhóm có khảo sát các nền tảng social listening trong và ngoài nước. Điểm rút ra là thị trường có hai hướng: dịch vụ phân tích bởi chuyên gia và platform self-service. SMAP chọn hướng platform.

PASS:

> Em đi nhanh qua phần thị trường để tập trung vào bài toán hệ thống.

### Slide 4 - Bài toán cần giải quyết

Mode: `CORE-15`, 45 giây.

Nói:

> Dữ liệu mạng xã hội có khối lượng lớn, đa nguồn, phi cấu trúc và tạo liên tục. Ở mức hệ thống, các job crawl và phân tích thường chạy dài, nhiều project có tải khác nhau và không thể xử lý đồng bộ trong request/response. Vì vậy hệ thống cần scale, async và fault isolation. Đây là cơ sở nhóm chọn microservices kết hợp event-driven.

### Slide 5 - Mục tiêu và phạm vi

Mode: `CORE-15`, 35 giây.

Nói:

> Mục tiêu là thiết kế platform dùng chung cho nhiều project, có pipeline thu thập, phân tích và khai thác insight. Ngoài phạm vi là tối ưu AI model, xây dựng SaaS thương mại đầy đủ hoặc cam kết SLA production tuyệt đối. Nhóm đánh giá bằng evidence: code, deployment, tests và benchmark.

### Slide 6 - Requirements

Mode: `CORE-15`, 45 giây.

Nói:

> Final report chốt 12 functional requirements, 7 non-functional requirements và 5 user-goal use cases. Nhóm gom yêu cầu theo capability: auth/internal auth, campaign/project lifecycle, datasource/target execution, analytics insight, knowledge chat/report và notification/crisis response. Cách gom này giúp trace từ nghiệp vụ sang service và test.

### Slide 7 - Use case overview

Mode: `FULL-30`, pass trong 15 giây.

Nói:

> Use case ở đây được gom theo mục tiêu người dùng, không đếm internal pipeline như user use case riêng. Chi tiết nhóm để backup nếu hội đồng hỏi.

### Slide 8 - Ý tưởng kiến trúc

Mode: `CORE-15`, 45 giây.

Nói:

> SMAP tách workload thành nhiều lane. Control plane cần consistency nên có identity/project. Data plane có job dài nên có ingest/scapper/RabbitMQ/MinIO. Analytics lane consume event và tạo read model. Knowledge lane dùng Qdrant cho semantic retrieval. Notification lane dùng Redis/WebSocket. Tách như vậy để mỗi lane scale và fail độc lập.

### Slide 9 - System context

Mode: `CORE-15`, 40 giây.

Nói:

> Ở C4 level 1, người dùng chính là analyst/marketing user. Họ cấu hình campaign, xem insight và nhận cảnh báo. Hệ thống tương tác với social platforms và provider/crawler bên ngoài. Điểm quan trọng là social platforms không phải user; chúng là external data sources.

### Slide 10 - Container architecture

Mode: `CORE-15`, 60 giây.

Nói:

> Container hiện tại gồm web-ui, identity-srv, project-srv, ingest-srv, scapper-srv, analysis-api/analysis-consumer, knowledge-srv và notification-srv. `smap-deploy` là source of truth cho deployment. UI gọi qua API boundary, service đồng bộ dùng HTTP nội bộ khi cần validation tức thời, còn dữ liệu lớn và analytics đi qua message bus.

### Slide 11 - Vì sao microservices?

Mode: `FULL-30`, pass trong 20 giây.

Nói:

> Nhóm không chọn microservices vì buzzword. Lý do là workload khác nhau: CRUD, crawl task, analytics stream, vector retrieval và realtime notification. Trade-off là vận hành phức tạp hơn, nên cần deploy source of truth và log/health proof.

### Slide 12 - Messaging/storage matrix

Mode: `CORE-15`, 45 giây.

Nói:

> RabbitMQ dùng cho task queue vì cần ack/retry. Kafka/Redpanda dùng cho UAP và analytics contract vì cần stream/replay. Redis Pub/Sub dùng cho fan-out notification nhẹ. PostgreSQL giữ metadata và marts, MinIO giữ raw payload, Qdrant giữ vector index. Mỗi tool giải một trách nhiệm khác nhau.

### Slide 13 - Flow overview

Mode: `CORE-15`, 20 giây.

Nói:

> Sau đây là flow chính từ campaign đến insight: user cấu hình project, ingest tạo runtime task, scapper lấy dữ liệu, MinIO giữ raw artifact, UAP đi qua Kafka, analysis tạo insight, knowledge/report/notification khai thác output.

### Slide 14 - Flow 1A setup

Mode: `FULL-30`, pass trong 15 giây.

Nói:

> Setup chi tiết có trong sequence backup. Ý chính: project-srv giữ business context, ingest-srv giữ execution context.

### Slide 15 - Flow 1B activation readiness

Mode: `CORE-15`, 45 giây.

Nói:

> Khi activate project, project-srv không chỉ đổi status. Nó kiểm tra trạng thái, gọi ingest-srv để lấy readiness, nếu fail thì chặn bằng lỗi nghiệp vụ, nếu pass thì ingest activate datasource runtime rồi project mới chuyển ACTIVE. Đây là nơi business state và execution state gặp nhau.

### Slide 16 - Flow 2 ingestion/UAP

Mode: `CORE-15`, 55 giây.

Nói:

> Ingest scheduler tìm target đến hạn, claim target bằng update có điều kiện để tránh duplicate job, tạo scheduled job/external task và publish RabbitMQ. Scapper worker xử lý crawl, upload raw artifact lên MinIO rồi gửi completion. Ingest verify object, parse raw batch thành UAP và publish sang `smap.collector.output`. Đây là claim-check pattern trong runtime thật.

### Slide 17 - Flow 3 analytics/knowledge/notification

Mode: `CORE-15`, 60 giây.

Nói:

> Analysis-consumer consume UAP, group theo project/domain, chạy NLP pipeline, ghi `analysis.post_insight` và publish ba contract topic: batch completed, insights published, report digest. Knowledge-srv consume để index Qdrant cho search/chat/report. Notification-srv consume digest hoặc crisis alert, publish Redis channel rồi route qua WebSocket. Discord chỉ là đường cảnh báo critical crisis, không phải mọi notification.

### Slide 18 - Crisis runtime loop

Mode: `FULL-30`, pass trong 20 giây.

Nói:

> Crisis runtime là luồng nâng cao: analysis phát hiện risk, project-srv giữ quyết định nghiệp vụ, ingest-srv đổi crawl mode. Chi tiết này nhóm để backup vì trong 15 phút em ưu tiên flow dữ liệu chính.

### Slide 19 - Deployment

Mode: `CORE-15`, 40 giây.

Nói:

> Hệ thống đang deploy trên K3s homelab namespace `smap`. UI là `smap.tantai.dev`, API là `smap-api.tantai.dev`, routing qua Traefik path prefix. `smap-deploy` là source of truth để tránh slide nói một kiểu nhưng production chạy một kiểu khác.

### Slide 20 - Module/Clean Architecture

Mode: `FULL-30`, pass trong 15 giây.

Nói:

> Trong từng service, nhóm tổ chức theo Clean Architecture và feature-based packaging để test được usecase và thay adapter hạ tầng khi cần.

### Slide 21 - Testing strategy

Mode: `CORE-15`, 35 giây.

Nói:

> Nhóm test theo bốn lớp: unit test cho logic service, integration test cho contract giữa service, E2E/live route test trên deployment, và NFR benchmark trên live domain/K8s.

### Slide 22 - Unit evidence

Mode: `FULL-30`, pass trong 10 giây.

Nói:

> Unit evidence chứng minh regression safety cho các service. Em đi nhanh để tập trung vào integration và NFR.

### Slide 23 - Integration evidence

Mode: `CORE-15`, 45 giây.

Nói:

> Integration evidence có campaign CRUD 8/8, datasource CRUD 6/6, readiness/activation validate đúng business rule và crisis runtime project-srv -> ingest-srv verified. Điểm quan trọng là không chỉ service chạy riêng lẻ, mà các boundary giao tiếp đúng.

### Slide 24 - E2E/live verification

Mode: `CORE-15`, 35 giây.

Nói:

> E2E snapshot gọi 55 endpoints, 44 pass, 4 partial, 2 chưa test đầy đủ do cần điều kiện runtime/browser sâu hơn. Nhóm không claim 100%, mà dùng con số này để chỉ ra core flow đã verify và phần còn giới hạn.

### Slide 25 - NFR benchmark

Mode: `CORE-15`, 45 giây.

Nói:

> NFR chạy trên live K8s. Locust 50 concurrent users đạt p95 khoảng 240ms, error 0.02%; k6 1800 requests đạt p95 khoảng 130ms và không ghi nhận lỗi. AI sentiment baseline accuracy khoảng 0.444, macro F1 khoảng 0.440. Đây là measured baseline, không phải SLA tuyệt đối hay claim model AI tốt.

### Slide 26 - Demo live

Mode: `CORE-15`, 2 phút 30 giây.

Nói trước khi demo:

> Demo sẽ đi theo user journey ngắn: live UI, dashboard insight, project/report surface, sau đó proof vận hành bằng health/K9s/log. Nhóm không trigger crawl job dài ngay trong 15 phút vì external platform và queue cadence có thể làm mất thời gian.

### Slide 27 - Kết quả đạt được

Mode: `CORE-15`, 30 giây.

Nói:

> Kết quả chính là một platform social analytics chạy thật, có control/data/analytics/knowledge/realtime lanes, có K3s deployment, có test và benchmark evidence. Nhóm cũng đã ghi rõ limitation thay vì chỉ trình bày phần đẹp.

### Slide 28 - Giới hạn và hướng phát triển

Mode: `CORE-15`, 25 giây.

Nói:

> Giới hạn là benchmark còn theo cửa sổ ngắn, chưa đo full WebSocket client latency, AI quality còn baseline và external-source hardening cần tiếp tục. Hướng tiếp theo là observability/runbook, long-soak benchmark và cải thiện ontology/AI quality.

### Slide 29 - Thank You

Mode: `CORE-15`, 10 giây.

Nói:

> Em xin kết thúc phần trình bày chính và sẵn sàng trả lời câu hỏi của Hội đồng.

