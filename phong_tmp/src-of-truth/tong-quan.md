# SMAP - Tài Liệu Tổng Quan Hệ Thống

**Ngày cập nhật:** 2026-04-13  
**Loại tài liệu:** BRD tổng quan / canonical context document  
**Audience chính:** Architecture / Engineering, có đủ business context để dùng chung với Product / Strategy

## 1. Executive Summary

SMAP là viết tắt của **Social Media Analytics Platform**, một nền tảng social listening và market intelligence giúp agency hoặc doanh nghiệp:

- theo dõi thảo luận trên mạng xã hội theo chiến dịch, nhãn hàng, đối thủ, chủ đề
- phân tích cảm xúc, ý định, issue, thực thể và xu hướng thị trường
- phát hiện tín hiệu khủng hoảng và tăng cường crawl khi cần
- lưu dữ liệu enriched để phục vụ dashboard realtime, reporting và RAG

SMAP không chỉ là hệ crawl dữ liệu. Đây là một nền tảng phân tích nhiều lớp, trong đó:

- `project-srv` giữ business context
- `ingest-srv` thu thập và chuẩn hóa dữ liệu đầu vào
- `analysis-srv` chạy AI/NLP pipeline
- `knowledge-srv` tạo lớp report/RAG
- `notification-srv` cung cấp cảnh báo tới người dùng

Lưu ý về cách viết báo cáo:

- `*-srv` là tên logical service / bounded context
- khi mô tả runtime hoặc deployment, phải gọi rõ workload như `project-api`, `project-consumer`, `ingest-api`, `ingest-consumer`, `ingest-scheduler`, `analysis-consumer`, `knowledge-api`, `knowledge-consumer`, `notification-api`
- current source có chỗ đã gom nhiều workload vào cùng một entry point `cmd/server`, nhưng điều đó **không** làm mất đi các lane vận hành `api / consumer / scheduler`

### Khách hàng mục tiêu

- agency làm social listening / campaign monitoring
- brand team / marketing team
- research / strategy team
- communication / PR / crisis team

### Giá trị cốt lõi

- theo dõi social theo `campaign -> project -> datasource -> crawl target`
- phân tích đối thủ, intent, issue, sentiment và market dynamics
- adaptive crawl khi có khủng hoảng
- dashboard realtime + report narrative qua `knowledge-srv`
- notification khi có tín hiệu tiêu cực hoặc crisis

## 2. Product Vision và Capabilities

SMAP được định hướng như một nền tảng social intelligence đa domain, không khóa cứng vào một ngành duy nhất.

### 2.1 Social listening

Ở giai đoạn hiện tại, SMAP chủ yếu phục vụ social listening theo:

- keyword-based crawl
- campaign/project-based monitoring

Trong tương lai, hệ thống cần mở rộng sang:

- profile/page/channel target
- creator/influencer monitoring
- post URL / thread URL monitoring

### 2.2 Market và brand intelligence

SMAP phải hỗ trợ:

- share of voice
- competitor comparison
- brand health tracking
- consumer intent / issue / pain point mining
- campaign effectiveness review
- trend and topic discovery

### 2.3 Crisis monitoring và adaptive crawl

SMAP phải cho phép:

- user cấu hình crisis rules theo từng project
- analysis phát hiện tín hiệu bất thường
- system tăng tần suất crawl khi project rơi vào `CRISIS`
- user được gợi ý cách theo dõi, drill-down và phân tích tiếp

### 2.4 Reporting và explainability

SMAP không chỉ đưa ra chart, mà còn phải hỗ trợ:

- dashboard realtime
- insight cards
- digest / report tổng hợp
- hỏi đáp narrative qua RAG

## 3. Core Business Model

Các entity nên được hiểu theo thứ tự business sau.

### 3.1 Campaign

`Campaign` là lớp grouping business cấp cao.

Ví dụ:

- chiến dịch theo quý
- chiến dịch theo thương hiệu
- chiến dịch theo dòng sản phẩm

Campaign không giữ runtime crawl detail; nó là khung business để gom nhiều `project`.

### 3.2 Project

`Project` là đơn vị monitoring chính của hệ thống.

Một project đại diện cho một bài toán theo dõi cụ thể, ví dụ:

- theo dõi thảo luận về Xanh SM trong domain mobility
- so sánh Grab và Ahamove trong nhóm giao hàng nội thành
- theo dõi perception của một brand đối với một chiến dịch

Project bắt buộc phải mang business context đủ rõ để analysis hiểu “mình đang phân tích cái gì”.

### 3.3 Datasource

`Datasource` là kết nối tới nguồn dữ liệu.

Ví dụ:

- TikTok
- Facebook
- YouTube
- file upload
- webhook

Datasource thuộc runtime/execution plane, không phải business entity chính.

### 3.4 Crawl Target

`Crawl Target` là đầu vào cụ thể cho việc thu thập dữ liệu.

Hiện tại ưu tiên:

- keyword

Trong tương lai mở rộng:

- profile/page/channel
- post/video URL

### 3.5 Crisis Config

`Crisis Config` là tập rule giúp project xác định khủng hoảng.

Hiện hệ thống hướng tới cấu hình theo:

- keywords trigger
- volume trigger
- sentiment trigger
- influencer trigger

## 4. Project Configuration Canonical

Để project có thể được phân tích đúng ngữ cảnh, project phải chứa business metadata tối thiểu.

### 4.1 Cấu hình tối thiểu của project

Project cần có:

- `brand`
- `entity_type`
- `entity_name`
- `domain_type_code`

Trong đó:

- `brand` giúp gom nhãn hàng / brand family
- `entity_type` mô tả loại thực thể đang theo dõi
- `entity_name` mô tả đối tượng cụ thể
- `domain_type_code` quyết định ontology/rule pack mà analysis sẽ dùng

### 4.2 Extension target cho project configuration

Trong tương lai, project nên mở rộng thêm các nhóm config business như:

- own-brand focus
- competitor set
- marketing intent focus
- issue priority profile
- audience or market segment focus

Các config này giúp analysis và reporting bám đúng mục tiêu của brand team, thay vì chỉ phân tích “social chatter” chung chung.

### 4.3 Implementation note từ current source

Current source đã có:

- `brand`
- `entity_type`
- `entity_name`
- `domain_type_code`

Current source **chưa thấy** config riêng cho:

- own-brand / nhãn hàng trọng tâm
- competitor set
- marketing-plan focus

Phần này là **target project configuration extension**, chưa nên viết như implemented fact.

## 5. Domain và Ontology Model

Đây là phần trọng tâm của SMAP nếu muốn mở rộng đa domain.

## 5.1 Domain là business context bắt buộc

Mỗi `project` phải chọn `domain_type_code`.

Ví dụ:

- `mobility_vn`
- `ev`
- `fnb`
- `banking`
- `generic`

`domain_type_code` là đầu vào bắt buộc để `analysis-srv` biết:

- dùng ontology nào
- dùng rule set nào
- ưu tiên entities/issues/intents nào

## 5.2 Use case hiện tại và mở rộng tương lai

Hiện tại SMAP tập trung vào **On-demand Mobility tại Việt Nam**, ví dụ:

- Grab
- Ahamove
- Be
- Xanh SM

Trong tương lai, hệ thống phải mở rộng dễ dàng sang:

- FMCG
- banking
- F&B
- EV
- telco
- healthcare

## 5.3 Pattern mở rộng domain

Pattern canonical nên là:

- `domain registry`
- `ontology pack`
- `active ontology per domain`

Điều này giúp:

- thêm domain mới mà không phá domain cũ
- quản lý version
- bật/tắt / thay thế ontology theo domain

## 5.4 Ontology không chỉ là taxonomy

Ontology/domain pack không nên chỉ chứa taxonomy đơn giản.

Nó cần chứa ít nhất:

- entities
- competitors
- issue categories
- intent groups
- marketing concepts
- source/channel semantics
- domain-specific keywords và alias

## 5.5 Implementation note từ current source

Current source đã có:

- `domain_type_code` ở `project`
- propagation từ `project -> ingest -> UAP`

Current source **chưa có đầy đủ**:

- DB-managed ontology governance
- lifecycle `draft -> approved -> active`
- validation pipeline cho ontology packs

## 6. Hướng dẫn Khởi Tạo Hệ Thống

Đây là flow khởi tạo canonical của SMAP.

### 6.1 Bước 1: Tạo campaign

User tạo `campaign` để làm lớp grouping business.

Output:

- campaign record
- campaign status ban đầu

### 6.2 Bước 2: Tạo project

User tạo `project` dưới campaign.

Project phải chọn tối thiểu:

- `name`
- `brand`
- `entity_type`
- `entity_name`
- `domain_type_code`

Output:

- project record
- business context để downstream services hiểu được mục tiêu theo dõi

### 6.3 Bước 3: Cấu hình business context của project

User hoặc system bổ sung:

- crisis config
- phân nhóm target monitoring
- định hướng competitor / intent / focus nếu hệ thống hỗ trợ

### 6.4 Bước 4: Thêm datasource

User cấu hình datasource tương ứng với nguồn cần thu thập:

- social platform crawl source
- passive source

Output:

- datasource records trong `ingest-srv`

### 6.5 Bước 5: Thêm crawl target

User thêm crawl targets.

Hiện tại:

- keyword

Tương lai:

- profile/page/channel
- URL

### 6.6 Bước 6: Dry-run / onboarding

`ingest-srv` thực hiện:

- dry-run cho crawl sources
- onboarding cho passive sources nếu cần

Output:

- readiness evidence
- runtime status cho datasource

### 6.7 Bước 7: Readiness check

Trước khi activate, hệ thống phải xác nhận project đủ điều kiện chạy.

Điều kiện tối thiểu nên gồm:

- có datasource
- datasource usable
- crawl target đã qua kiểm tra tối thiểu
- business context hợp lệ

### 6.8 Bước 8: Activate project

Khi readiness pass:

- `project` được activate ở business layer
- `ingest` activate runtime execution

### 6.9 Bước 9: Scheduler / cron bắt đầu chạy

Sau activate:

- scheduler dispatch crawl jobs
- hệ thống đi vào normal running mode

### 6.10 Implementation note từ current source

Current source đã có:

- business lifecycle chính cho `campaign/project`
- datasource runtime lifecycle
- `project_config_status`

Trong overview này, `project_config_status` chỉ nên xem là implementation detail, không phải business entity chính.

## 7. Lifecycle và State Model

Canonical lifecycle được giữ đơn giản và dễ hiểu.

### 7.1 Campaign

- `PENDING`
- `ACTIVE`
- `PAUSED`
- `ARCHIVED`

### 7.2 Project

- `PENDING`
- `ACTIVE`
- `PAUSED`
- `ARCHIVED`

### 7.3 Datasource

- `PENDING`
- `READY`
- `ACTIVE`
- `PAUSED`
- `FAILED`
- `COMPLETED`
- `ARCHIVED`

### 7.4 Crisis State

Canonical overview giữ tối giản:

- `NORMAL`
- `CRISIS`

### 7.5 Ghi chú quan trọng

- cơ chế tránh bật/tắt crisis liên tục là **business rule / usecase**
- không cần mở thêm state trong overview nếu business chưa yêu cầu

### 7.6 Implementation note từ current source

Current source `crisis-config` vẫn đang dùng:

- `NORMAL`
- `WARNING`
- `CRITICAL`

Đây là current source note, không phải canonical target state nếu overview muốn giữ đơn giản.

## 8. Kiến Trúc Hệ Thống Tổng Thể

SMAP được tổ chức theo mô hình multi-service với ownership rõ ràng.

### 8.0 Quy ước đọc `service` và `workload`

Trong tài liệu này cần tách rõ hai lớp:

- `service` là logical ownership, ví dụ `ingest-srv`
- `workload` là lane vận hành cụ thể, ví dụ `ingest-api`, `ingest-consumer`, `ingest-scheduler`

Current source có xu hướng gom nhiều workload vào cùng entry point `cmd/server`, nhưng khi viết báo cáo kiến trúc hoặc deployment vẫn phải gọi rõ workload. Đây là điểm quan trọng để tránh hiểu nhầm rằng một service chỉ có một process duy nhất.

### 8.1 `project-srv`

Vai trò:

- giữ campaign/project
- giữ business context
- giữ domain selection
- giữ crisis policy/config
- là business/control plane

Workload cần gọi rõ trong báo cáo:

- `project-api`: HTTP API cho campaign/project/config và control-plane actions
- `project-consumer`: Kafka consumer xử lý event bất đồng bộ liên quan tới project/control plane

Implementation note từ current source:

- current source đang gom `project-api` và `project-consumer` vào cùng `project-srv/cmd/server/main.go`

### 8.2 `ingest-srv`

Vai trò:

- quản lý datasource và crawl targets
- chạy dry-run / onboarding
- dispatch crawl jobs
- tạo raw batch
- sinh UAP
- là execution plane

Workload cần gọi rõ trong báo cáo:

- `ingest-api`: HTTP API quản lý datasource, crawl target, dry-run, activation và internal operations
- `ingest-consumer`: consumer nhận completion/result từ RabbitMQ, cập nhật runtime state, persist raw batch và publish UAP
- `ingest-scheduler`: scheduler tick theo cron, chọn target đến hạn và dispatch crawl jobs

Implementation note từ current source:

- current source đang gom `ingest-api`, `ingest-consumer` và `ingest-scheduler` vào cùng `ingest-srv/cmd/server/main.go`

### 8.3 `analysis-srv`

Vai trò:

- consume UAP
- chạy AI/NLP pipeline
- tạo signal / insight / enriched facts
- là intelligence plane

Workload cần gọi rõ trong báo cáo:

- `analysis-consumer`: Kafka consumer consume UAP, chạy pipeline và publish outputs downstream

Implementation note từ current source:

- current source chỉ thấy workload triển khai rõ ràng là `analysis-consumer`
- chưa nên viết `analysis-api` hoặc `analysis-scheduler` như implemented fact

### 8.4 `knowledge-srv`

Vai trò:

- indexing
- RAG retrieval
- report materialization

Workload cần gọi rõ trong báo cáo:

- `knowledge-api`: HTTP API phục vụ search, chat, notebook, report retrieval
- `knowledge-consumer`: Kafka consumer index `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest`

Implementation note từ current source:

- current source đang gom `knowledge-api` và `knowledge-consumer` vào cùng `knowledge-srv/cmd/server/main.go`

### 8.5 `notification-srv`

Vai trò:

- phát cảnh báo cho người dùng

Workload cần gọi rõ trong báo cáo:

- `notification-api`: HTTP/WebSocket gateway phát notification tới user, hiện dựa trên Redis pub/sub và websocket delivery

Implementation note từ current source:

- current source hiện chỉ thấy workload runtime rõ ràng là `notification-api`
- chưa nên viết `notification-consumer` hoặc `notification-scheduler` như implemented fact nếu chỉ dựa trên proposal/doc

### 8.6 Kiến trúc logic

Normal flow:

- `project -> ingest -> scrapper -> raw -> UAP -> analysis -> knowledge/dashboard`

Runtime lane thường được diễn đạt rõ hơn thành:

- `project-api -> ingest-api -> ingest-scheduler -> scrapper -> ingest-consumer -> analysis-consumer -> knowledge-consumer -> knowledge-api/dashboard`

Crisis flow:

- `analysis signal -> project evaluates crisis -> project asks ingest to intensify crawl -> ingest crawl mode up -> notify user`

## 9. End-to-End Data Flow

## 9.1 Normal flow

1. `project-srv` giữ business context của project
2. `ingest-srv` crawl dữ liệu theo schedule
3. raw data được lưu và parse thành UAP
4. UAP được gửi sang `analysis-srv`
5. `analysis-srv` enrich dữ liệu, tính signal, insight và facts
6. gold/time-series được lưu để làm dashboard
7. outputs phù hợp được gửi sang `knowledge-srv`
8. dashboard và RAG dùng các lớp dữ liệu này để phục vụ user

## 9.2 Crisis flow

1. `analysis-srv` phát hiện signal bất thường
2. `project-srv` đánh giá project có vào `CRISIS` hay không
3. nếu vào `CRISIS`, `project-srv` yêu cầu `ingest-srv` tăng crawl intensity
4. `ingest-srv` chuyển `crawl_mode`
5. dữ liệu mới được đẩy nhanh hơn về `analysis-srv`
6. `notification-api` phát alert cho user nếu cần

## 9.3 Domain context flow

`domain_type_code` phải đi xuyên suốt:

- `project`
- `ingest runtime`
- `UAP`
- `analysis`
- `knowledge/reporting context`

## 10. Pipeline Phân Tích AI & NLP

Pipeline target ở mức business-technical nên gồm:

- ingestion normalization
- dedup
- spam / noise handling
- thread / hierarchy handling
- entity extraction
- sentiment analysis
- issue / aspect analysis
- intent analysis
- domain-aware ontology application
- metrics / marts / insights / digest generation

### Ý nghĩa

Pipeline không chỉ phân loại “positive/negative”, mà phải tạo được:

- entity facts
- issue facts
- intent clues
- comparative signals
- market-level narratives

### Implementation note từ current source

Current source `analysis-srv` đã có skeleton cho:

- intent
- keyword
- sentiment
- impact

Nhưng current source vẫn chưa align hoàn toàn với UAP canonical mới từ `ingest-srv`.

## 11. Reporting và Alerting Layer

## 11.1 Dashboard

Dashboard cần lấy dữ liệu từ gold/time-series layer để hiển thị:

- volume theo thời gian
- sentiment trend
- issue distribution
- competitor comparison
- campaign/project drill-down

## 11.2 `knowledge-srv`

`knowledge-srv` đóng vai trò:

- index insight materials
- build report/digest layer
- phục vụ RAG retrieval và narrative explanation

Khi viết báo cáo runtime, nên tách:

- `knowledge-consumer` cho index/materialization lane
- `knowledge-api` cho retrieval/chat/report serving lane

## 11.3 `notification-srv`

`notification-srv` đóng vai trò:

- alert negative spike
- alert crisis started
- alert crisis resolved

Current source note:

- hiện thấy rõ `notification-api` là lane triển khai thực tế
- chưa nên mặc định có `notification-consumer` hoặc `notification-scheduler` nếu không dẫn từ source runtime hiện tại

## 11.4 Implementation note từ current source

Current docs/source của `knowledge-srv` đã rõ hướng 3-layer:

- `analytics.batch.completed`
- `analytics.insights.published`
- `analytics.report.digest`

## 12. Data Privacy & Compliance

Đây là **target requirement section**.

Current SMAP core source chưa thể hiện đầy đủ privacy/compliance implementation, nên phần này phải được coi là canonical requirement cho hệ thống mong muốn.

### 12.1 Dữ liệu nhạy cảm cần chú ý

- username / handle
- profile URL
- author ID
- avatar URL
- phone / email nếu xuất hiện trong raw text
- raw text chứa PII
- internal cross-service identifiers nếu không cần expose ra UI

### 12.2 Nguyên tắc xử lý

- hash / tokenize internal identifiers khi không cần hiển thị trực tiếp
- mask / redact PII trong reporting và RAG context nếu không cần thiết
- tách raw storage và reporting storage
- hạn chế quyền truy cập theo vai trò
- có retention policy cho raw data và enriched data
- có audit log cho các thao tác nhạy cảm

### 12.3 Mục tiêu compliance

SMAP nên được thiết kế để:

- giảm nguy cơ lộ PII không cần thiết
- giảm việc lan truyền raw personal content vào report/RAG
- đảm bảo downstream services không tự ý giữ dữ liệu quá mức cần thiết

## 13. Phân Quyền và Vai Trò Người Dùng

Đây là **canonical business requirement**, không phải implemented fact.

### 13.1 Vai trò mục tiêu

- `Admin`
- `Manager/Owner`
- `Analyst`
- `Viewer`

### 13.2 Capability theo vai trò

`Admin`

- quản trị domain registry / ontology governance
- quản trị system-level settings
- quản trị quyền và lifecycle toàn hệ

`Manager/Owner`

- tạo campaign/project
- cấu hình datasource/targets
- activate/pause/archive project
- chỉnh crisis config
- xem toàn bộ dashboard/report liên quan

`Analyst`

- vận hành monitoring
- theo dõi dashboard
- phân tích insight
- xem alert
- cập nhật một số config được cấp quyền

`Viewer`

- chỉ đọc dashboard / report / alert

### 13.3 Implementation note từ current source

Current source chưa thấy RBAC model đầy đủ nằm ngay trong các SMAP services.

Auth/RBAC hiện nên được xem là phụ thuộc vào:

- external auth assumptions
- gateway / auth service

Vì vậy phần này là target requirement, không được viết như capability đã hoàn tất.

## 14. Related Canonical Docs

Tài liệu này là entrypoint tổng quan. Các tài liệu chi tiết đi kèm:

- [2-state-machine.md](/Users/phongdang/Documents/GitHub/SMAP/2-state-machine.md)
- [3-event-contracts.md](/Users/phongdang/Documents/GitHub/SMAP/3-event-contracts.md)
- [4-implementation-gap-checklist.md](/Users/phongdang/Documents/GitHub/SMAP/4-implementation-gap-checklist.md)
- [5-rollout-order.md](/Users/phongdang/Documents/GitHub/SMAP/5-rollout-order.md)

Ý nghĩa:

- `tong-quan.md`: canonical overview / BRD context
- `2-state-machine.md`: canonical lifecycle và state rules
- `3-event-contracts.md`: canonical event và contract rules
- `4-implementation-gap-checklist.md`: implementation status
- `5-rollout-order.md`: rollout sequencing

## 15. Kết luận

SMAP được định hướng là một nền tảng social listening và social intelligence đa domain, trong đó:

- `project` giữ business intent
- `domain_type_code` giữ ngữ cảnh phân tích
- `ingest` giữ execution
- `analysis` giữ intelligence
- `knowledge` giữ reporting/RAG
- `notification` giữ phản ứng user-facing

Nếu chỉ chốt một nguyên tắc nền tảng nhất cho hệ thống này, thì đó là:

**mọi project phải mang domain rõ ràng, và toàn bộ pipeline từ crawl đến analysis đến reporting phải luôn bám vào business context của project đó.**
