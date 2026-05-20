# Kịch bản thuyết trình DATN cho SMAP

Tài liệu này là bản lời nói đầy đủ nếu em đứng trước hội đồng DATN. Mục tiêu không phải là đọc lại slide, mà là có một mạch trình bày rõ ràng, có lý do cho từng quyết định, và có sẵn các điểm chặn để trả lời phản biện.

Nguyên tắc khi dùng tài liệu này:

- Mỗi slide chỉ giữ một ý chính.
- Nói theo thứ tự: vấn đề -> khoảng trống -> giải pháp -> bằng chứng.
- Không đọc chữ trên slide, chỉ dùng slide làm mốc để dẫn ý.
- Nếu bị hỏi xoáy, ưu tiên trả lời bằng lý do kỹ thuật và bằng chứng hiện có.

---

## Slide 1 - Trang bìa
Em xin chào Hội đồng. nhóm em là SMAP gồm 3 thành viên em là Đặng Quốc Phong, bạn NTT và bạn NCT
em xin phép bắt đầu phần trình bày.

Các nền tảng mạng xã hội hiện nay liên tục tạo ra một khối lượng rất lớn nội dung do người dùng đăng tải, bao gồm bài đăng, video, bình luận và các tương tác diễn ra theo thời gian. những dữ liệu này mang ý nghĩa rất rõ ràng: người dùng đang khen hay chê, đang hài lòng hay phàn nàn, và đang quan tâm đến vấn đề gì.

Chính vì vậy, đối với các doanh nghiệp đặc biệt là các nhóm marketing, dữ liệu mạng xã hội là một nguồn thông tin quan trọng để theo dõi phản hồi thị trường, đánh giá hiệu quả chiến dịch, cũng như phát hiện sớm các vấn đề liên quan đến sản phẩm hoặc thương hiệu.

Tuy nhiên, lượng dữ liệu được tạo ra liên tục và phân tán trên nhiều nền tảng khác nhau, việc theo dõi thủ công tiêu tốn nhiều thời gian và sẽ khó khăn việc tổng hợp, so sánh và nhìn thấy bức tranh chung. Vấn đề lúc này không phải là thiếu dữ liệu hay thiếu ý nghĩa, mà là khó tổng hợp, khó so sánh và khó nhìn thấy bức tranh chung trong thời gian đủ nhanh để ra quyết định.

Từ nhu cầu thực tế đó, bài toán được đặt ra là: làm thế nào để thu thập, xử lý và tổng hợp dữ liệu mạng xã hội nhằm giúp các nhóm marketing và doanh nghiệp  nhìn được bức tranh tổng thể về phản hồi và xu hướng của người dùng.

Xuất phát từ bối cảnh này, nhóm em thực hiện đồ án chuyên ngành với đề tài Xây dựng hệ thống SMAP - Social Media Analytics Platform, tập trung vào thiết kế kiến trúc hệ thống cho bài toán phân tích dữ liệu mạng xã hội (hay còn gọi là Social Listening).
 
Chuyển ý:

- Từ slide này, em sẽ sang slide 2 để nói vì sao bài toán này có ý nghĩa thực tế và vì sao nhóm em chọn hướng làm này.

---

## Slide 2 - Bài toán và khoảng trống

SMAP được định nghĩa như một nền tảng trung tâm, có nhiệm vụ thu thập dữ liệu từ mạng xã hội, tổ chức lại dữ liệu theo cấu trúc phù hợp và cung cấp các kết quả tổng hợp để người dùng có thể khai thác ở mức tổng thể.

Trong đồ án này, trọng tâm của nhóm không nằm ở việc xây dựng hay tối ưu các mô hình phân tích, mà nằm ở cách thiết kế kiến trúc hệ thống: dữ liệu được đi vào hệ thống như thế nào, được xử lý qua những thành phần nào, và được tổng hợp ra sao để phục vụ nhu cầu sử dụng thực tế.

Trong quá trình thực hiện đề tài, nhóm em đã khảo sát một số hệ thống Social Listening tiêu biểu đang được triển khai tại Việt Nam và trên thị trường quốc tế.

Trên thị trường quốc tế, các nền tảng như Talkwalker, YouScan và Meltwater cung cấp cho người dùng giải pháp thu thập với nhiều nền tảng mxh, với khả năng phân tích dữ liệu ở quy mô lớn và tích hợp nhiều công nghệ AI.

Tại Việt Nam, có thể kể đến các đơn vị như YouNet Media,Buzzmetrics, Reputa và Kompa.
toàn bộ các hệ thống này phục vụ cho những nhu cầu khác nhau, từ nghiên cứu thị trường chuyên sâu cho đến theo dõi và giám sát dữ liệu mạng xã hội theo thời gian thực.


Khi tham khảo và phân tích, nhóm em nhận thấy các hệ thống này thường vận hành theo hai hướng chính.

Hướng thứ nhất là mô hình dịch vụ phân tích, trong đó dữ liệu sau khi thu thập sẽ được xử lý và diễn giải chủ yếu bởi đội ngũ chuyên gia, nhằm tạo ra các báo cáo chuyên sâu cho từng khách hàng.

Hướng thứ hai là mô hình nền tảng, cho phép nhiều doanh nghiệp và nhiều người dùng trực tiếp truy cập hệ thống để theo dõi thương hiệu, chiến dịch hoặc từ khóa của họ theo thời gian thực.

Hệ thống SMAP mà nhóm em thiết kế đi theo hướng thứ hai,
tức là một nền tảng dùng chung, nơi mỗi doanh nghiệp có thể sử dụng hệ thống để theo dõi dữ liệu của riêng mình,
tương tự như cách người dùng truy cập một hệ thống trung tâm để khai thác thông tin.


Khi tiếp cận theo hướng này, bài toán đặt ra không chỉ là thu thập và phân tích dữ liệu,
mà là thiết kế kiến trúc để hệ thống có thể phục vụ đồng thời nhiều người dùng, với các đặc điểm:

Thứ nhất, về đặc điểm dữ liệu, dữ liệu mạng xã hội có khối lượng rất lớn, chủ yếu là phi cấu trúc như video, bài đăng và bình luận ở mỗi nền tàng sẽ có sự khác nhau, được tạo ra liên tục theo thời gian, và đến từ nhiều nguồn khác nhau.

Thứ hai, nếu nhìn dưới góc độ hệ thống, nhu cầu thực tế cần một quy trình rõ ràng gồm 3 bước: thu thập dữ liệu, phân tích, và tổng hợp thành insight để người dùng theo dõi được bức tranh tổng thể.

Và từ đó phát sinh ba thách thức chính.
Một là khả năng mở rộng: nhiều người dùng với nhiều dự án sẽ tạo ra nhiều tác vụ chạy song song, và có sự chênh lệch tài nguyên trong hệ thống
Hai là bất đồng bộ: các công việc thu thập và phân tích thường chạy dài, không thể xử lý kiểu đồng bộ.
Ba là khả năng chịu lỗi: cần cô lập lỗi giữa các thành phần để một phần gặp sự cố không kéo sập toàn hệ thống và không làm mất dữ liệu.

Đây là một trong những cơ sở để nhóm em lựa chọn hướng kiến trúc microservices kết hợp event-driven ở các phần sau
---

## Slide 3 - Mục tiêu và phạm vi

Từ bài toán hệ thống vừa trình bày, em xin làm rõ lại mục tiêu và phạm vi của đồ án, nhằm xác định rõ những gì hệ thống SMAP hướng tới và những gì nằm ngoài phạm vi thực hiện.



Về mục tiêu, đồ án tập trung vào việc thiết kế kiến trúc hệ thống cho một nền tảng Social Media Analytics theo mô hình dùng chung, có khả năng phục vụ nhiều project và nhiều người dùng đồng thời. Trọng tâm của nhóm em là cách tổ chức các thành phần trong hệ thống, luồng xử lý dữ liệu và cơ chế phối hợp giữa các dịch vụ.

Đồ án không đặt mục tiêu nghiên cứu hay tối ưu mô hình AI, mà sử dụng các mô hình có sẵn như một thành phần trong kiến trúc, nhằm tập trung giải quyết bài toán ở mức hệ thống.

Về phạm vi, trong đồ án này nhóm em tập trung vào dữ liệu mạng xã hội công khai, với các chức năng chính bao gồm thu thập dữ liệu, phân tích và tổng hợp kết quả để người dùng theo dõi phản hồi và xu hướng ở mức tổng thể.


Với phạm vi như vậy, các slide tiếp theo sẽ đi sâu vào kiến trúc tổng thể và các quyết định thiết kế của hệ thống SMAP.

---

## Slide 4 - System Architecture

Hình dùng trên slide: [slide4-system-architecture.excalidraw](./slide4-system-architecture.excalidraw)

Nội dung trên slide:

- Sơ đồ kiến trúc phân tầng: Client/UI, API/control plane, Worker/data processing, Messaging/event bus, Storage.
- Các service chỉ ghi tên: `web-ui`, `identity-srv`, `project-srv`, `ingest-srv`, `scapper-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`.
- Các đường giao tiếp chính: HTTP request/response, RabbitMQ, Redpanda/Kafka API, Redis Pub/Sub, S3/MinIO, PostgreSQL, Qdrant.

Lời nói:

Từ slide này em chuyển sang phần quan trọng nhất của đồ án là kiến trúc và thiết kế hệ thống. Nhóm em không thiết kế hệ thống theo kiểu một backend lớn xử lý tất cả, mà chia thành các service theo ranh giới nghiệp vụ và theo loại workload.

Ở tầng client, người dùng thao tác qua `web-ui`. Các thao tác đồng bộ như đăng nhập, tạo project, cấu hình datasource, xem dashboard hoặc gọi báo cáo đi qua HTTP request/response.

Ở tầng control plane, `identity-srv` phụ trách định danh người dùng; `project-srv` giữ ngữ cảnh nghiệp vụ gồm campaign, project, trạng thái vòng đời, cấu hình crisis và metadata để gom dữ liệu theo project. Cấu hình datasource, crawl target, lịch chạy và lineage kỹ thuật được tách sang `ingest-srv`.

Điểm quan trọng là `ingest-srv` đóng vai trò điều phối và chuẩn hóa. Khi một project được kích hoạt, `project-srv` gọi nội bộ sang `ingest-srv` để kiểm tra readiness và activate. Sau đó `ingest-srv` tạo `scheduled_jobs`, `external_tasks`, publish task sang RabbitMQ cho `scapper-srv`.

`scapper-srv` là worker crawler. Service này không trả dữ liệu lớn trực tiếp qua message, mà upload raw artifact lên MinIO, sau đó publish completion message về RabbitMQ. Cách này giống claim-check pattern: message chỉ mang metadata và đường dẫn artifact, còn dữ liệu lớn nằm trong object storage.

Khi nhận completion, `ingest-srv` kiểm tra artifact trong MinIO, tạo `raw_batches`, parse raw data và chuẩn hóa sang UAP. Các record UAP được publish lên Redpanda bằng Kafka API, cụ thể là topic `smap.collector.output`.

Từ đây pipeline phân tích chạy bất đồng bộ. `analysis-srv` consume UAP, xử lý normalization, dedup, spam, thread, NLP, enrichment, reporting và crisis; kết quả được ghi vào PostgreSQL schema `analysis` và publish các event `analytics.*`.

Hai service phía sau dùng chung kết quả phân tích nhưng phục vụ mục tiêu khác nhau. `knowledge-srv` consume event analytics để index tài liệu vào Qdrant, phục vụ semantic search, chat và report. `notification-srv` consume digest hoặc crisis event, bridge sang Redis Pub/Sub và WebSocket để đẩy trạng thái hoặc cảnh báo realtime cho người dùng.

Vì vậy, nếu nhìn tổng thể, giao tiếp trong hệ thống được chia rất rõ: HTTP cho thao tác đồng bộ của người dùng và internal command; RabbitMQ cho crawl task cần retry/ack; Redpanda/Kafka API cho stream phân tích; Redis Pub/Sub và WebSocket cho realtime fan-out; MinIO cho artifact lớn; PostgreSQL và Qdrant cho dữ liệu truy vấn.

Ý em muốn nhấn mạnh ở slide này là kiến trúc microservices ở đây không chỉ là tách code thành nhiều service, mà là tách theo trách nhiệm và theo đặc tính giao tiếp của từng loại xử lý.

Chuyển ý:

- Sau khi có sơ đồ kiến trúc, slide tiếp theo sẽ đi vào mô hình dữ liệu lõi, nhưng chỉ chọn những bảng và store quan trọng nhất để tránh biến slide thành tài liệu schema.

---

## Slide 5 - Database Design / Data Model

Hình dùng trên slide: [slide5-data-model-pipeline.excalidraw](./slide5-data-model-pipeline.excalidraw)

Nội dung trên slide:

- Không show toàn bộ database, chỉ show các entity lõi theo service ownership.
- `project`: `campaigns`, `projects`, `projects_crisis_config`.
- `ingest`: `data_sources`, `crawl_targets`, `scheduled_jobs`, `external_tasks`, `raw_batches`.
- `analysis`: `post_insight`.
- `knowledge`: `indexed_documents`, `conversations/messages`, `reports`.
- Store ngoài SQL: MinIO cho artifact, Redpanda topics cho stream, Qdrant cho vector index.

Lời nói:

Với mô hình dữ liệu, nhóm em không trình bày một ERD dày đặc toàn bộ bảng, vì hệ thống không phải một monolithic database duy nhất. Thiết kế hiện tại đi theo hướng mỗi service sở hữu một phần dữ liệu của mình, còn dữ liệu đi qua pipeline bằng message và artifact reference.

Phần `project` là ngữ cảnh nghiệp vụ. `campaigns` đại diện cho chiến dịch hoặc nhóm theo dõi ở mức cao. `projects` là đơn vị vận hành chính mà người dùng cấu hình và theo dõi. `projects_crisis_config` lưu cấu hình liên quan đến cảnh báo khủng hoảng cho từng project.

Phần `ingest` là ngữ cảnh thực thi. `data_sources` mô tả nguồn dữ liệu; `crawl_targets` mô tả mục tiêu crawl cụ thể; `scheduled_jobs` là lịch hoặc lần chạy; `external_tasks` là task đã dispatch ra crawler; `raw_batches` là lineage của dữ liệu raw sau khi crawler hoàn thành.

Điểm đáng chú ý là raw data không được nhét trực tiếp vào database. Raw JSON và UAP JSONL được lưu ở MinIO. Database chỉ lưu metadata, checksum, trạng thái xử lý và đường dẫn object. Thiết kế này giảm tải cho PostgreSQL và giúp truy vết lại batch dữ liệu khi cần debug.

Sau bước ingest, dữ liệu chuẩn hóa đi qua Redpanda topic `smap.collector.output`. `analysis-srv` consume topic này và tạo read model chính là bảng `post_insight`. Bảng này lưu các trường UAP lõi, sentiment, aspect, keyword, risk, engagement, quality và processing metadata để phục vụ dashboard.

Ở phía knowledge, `indexed_documents` lưu trạng thái những tài liệu đã được đưa vào vector store, kèm `analytics_id`, `project_id`, `qdrant_point_id`, `collection_name` và hash nội dung. Các bảng `conversations/messages` và `reports` phục vụ chat/report. Vector thật nằm trong Qdrant, thường theo collection của project như `proj_{project_id}`.

Như vậy Slide 5 không chỉ là ERD, mà là data pipeline map với ownership của từng service: project giữ business context, ingest giữ execution lineage, analysis giữ read model phân tích, knowledge giữ metadata cho search/chat/report, còn MinIO và Qdrant xử lý hai loại dữ liệu đặc thù là artifact lớn và vector embedding.

Chuyển ý:

- Từ mô hình dữ liệu này, slide 6 sẽ đi vào sequence lõi của hệ thống, tức là một project được kích hoạt thì dữ liệu đi qua các service như thế nào.

---

## Slide 6 - Core Algorithm / Logic

Hình dùng trên slide: [slide6-core-sequence-ingest-analysis.excalidraw](./slide6-core-sequence-ingest-analysis.excalidraw)

Nội dung trên slide:

- Sequence chính: activate project -> dispatch crawl task -> upload raw artifact -> completion -> normalize UAP -> analytics -> knowledge/notification.
- Nêu 3 ý kỹ thuật: bất đồng bộ, claim-check qua MinIO, event-driven fan-out.

Lời nói:

Slide này em chọn sequence phức tạp nhất của hệ thống: từ lúc người dùng activate project đến lúc dữ liệu được phân tích và có thể xuất hiện ở dashboard, search, report hoặc notification.

Bước đầu tiên là người dùng thao tác trên `web-ui`, request đi tới `project-srv`. `project-srv` không tự crawl dữ liệu, mà kiểm tra trạng thái project rồi gọi internal HTTP sang `ingest-srv` để activate. Đây là phần request/response vì người dùng cần biết thao tác activate có hợp lệ hay không.

Sau khi activate, `ingest-srv` chuyển sang xử lý bất đồng bộ. Service này tạo job/task trong database, build payload theo datasource và target, rồi publish task sang RabbitMQ. RabbitMQ được dùng ở đây vì crawler là tác vụ dài, có thể fail, cần ACK/NACK, retry và không nên khóa request của người dùng.

`scapper-srv` consume task từ RabbitMQ, gọi các crawler handler tương ứng với nền tảng như TikTok, Facebook hoặc YouTube. Khi crawl xong, service upload raw artifact lên MinIO theo đường dẫn có platform, action, ngày và task id. Sau đó nó publish completion message về RabbitMQ.

Điểm quan trọng là completion message không chứa toàn bộ dữ liệu raw. Nó chỉ chứa reference tới object trên MinIO, bucket/path, checksum và metadata batch. Nhờ vậy message nhỏ, queue ổn định hơn, còn dữ liệu lớn được lưu ở object storage.

`ingest-srv` consume completion, kiểm tra task id, kiểm tra duplicate raw batch, xác minh object trong MinIO rồi mới tạo `raw_batches`. Tiếp theo `ingest-srv` đọc raw artifact, parse theo từng platform, chuẩn hóa thành UAP và publish từng record sang Redpanda topic `smap.collector.output`.

`analysis-srv` consume UAP, chạy pipeline gồm normalization, dedup, spam detection, thread, NLP, enrichment, reporting và crisis. Kết quả được ghi vào PostgreSQL bảng `analysis.post_insight`. Sau đó service publish các event như `analytics.batch.completed`, `analytics.insights.published` và `analytics.report.digest`.

Từ các event analytics này, hệ thống tách thành hai nhánh. `knowledge-srv` index nội dung sang Qdrant để phục vụ semantic search, chat và report. `notification-srv` bridge digest hoặc crisis event sang Redis Pub/Sub và WebSocket để gửi thông báo realtime.

Như vậy sequence lõi thể hiện ba quyết định thiết kế chính. Một là các công việc dài chạy bất đồng bộ. Hai là dữ liệu lớn đi qua MinIO bằng claim-check thay vì nhét vào message. Ba là sau khi analysis xong, kết quả được fan-out bằng event để knowledge và notification có thể phát triển độc lập.

Chuyển ý:

- Sau phần kiến trúc và logic lõi, em sẽ chuyển nhanh sang demo để chứng minh các phần chính đang chạy được, sau đó kết thúc bằng kiểm thử, hạn chế và hướng phát triển.

---

## Slide 7 - Demo flow

Nội dung trên slide:

- Demo theo một luồng ngắn: đăng nhập -> chọn project -> xem dữ liệu phân tích -> search/report/notification.
- Không demo quá sâu phần cấu hình crawler nếu thời gian còn ít.

Lời nói:

Vì tổng thời gian trình bày chỉ khoảng 15 phút, phần demo em sẽ đi theo một happy path ngắn để chứng minh các thành phần chính có liên kết với nhau.

Đầu tiên em đăng nhập vào hệ thống và vào danh sách project. Đây là phần đi qua `identity-srv` và `project-srv`.

Tiếp theo em mở một project đã có dữ liệu, xem các chỉ số phân tích trên dashboard. Phần này sử dụng dữ liệu đã được `analysis-srv` xử lý và lưu ở read model.

Sau đó em mở phần search hoặc report để minh họa nhánh `knowledge-srv`, tức là dữ liệu sau phân tích có thể được index và khai thác lại theo ngữ nghĩa hoặc theo báo cáo.

Nếu còn thời gian, em sẽ chỉ nhanh trạng thái notification hoặc luồng cảnh báo realtime để thể hiện nhánh `notification-srv`.

Điểm em muốn hội đồng nhìn trong demo không phải là từng màn hình đẹp hay nhiều tính năng nhỏ, mà là luồng hệ thống: user thao tác ở web, dữ liệu đã đi qua pipeline, kết quả được tổng hợp lại để phục vụ dashboard và khai thác.

---

## Slide 8 - Kiểm thử và bằng chứng hiện có

Nội dung trên slide:

- Benchmark ngày 17/05/2026: 4.286 samples.
- Overall p50/p95/p99: 101.717 ms / 190.197 ms / 727.142 ms.
- Dashboard-critical paths sạch hơn: analytics p95 192.162 ms, UI p95 181.748 ms, infra error 0.0%.
- Ghi rõ giới hạn: crawler lane trong benchmark còn bị ảnh hưởng bởi RabbitMQ/scapper readiness.

Lời nói:

Về kiểm thử, nhóm em có hai nhóm bằng chứng. Nhóm thứ nhất là kiểm thử chức năng và tích hợp để đảm bảo các API, service và pipeline chính hoạt động. Nhóm thứ hai là benchmark NFR để đo một số chỉ số độ trễ và lỗi ở trạng thái hệ thống thực tế.

Ở benchmark ngày 17/05/2026, hệ thống ghi nhận 4.286 samples. Nếu nhìn tổng thể, p50 khoảng 101.717 ms, p95 khoảng 190.197 ms và p99 khoảng 727.142 ms. Các đường quan trọng cho dashboard có kết quả ổn hơn: analytics p95 khoảng 192.162 ms, UI p95 khoảng 181.748 ms và infra error 0.0%.

Tuy nhiên nhóm em không trình bày benchmark này như một cam kết production SLA. Nó là bằng chứng baseline cho thấy các luồng dashboard và API quan trọng chạy được với độ trễ đo được. Đồng thời benchmark cũng chỉ ra phần crawler lane còn có điểm yếu khi RabbitMQ hoặc readiness của `scapper-srv` chưa ổn định trong lần đo đó.

Vì vậy cách nhìn đúng là: phần dashboard/read model đã có số liệu khá sạch, còn crawler lane là phần cần tiếp tục hardening nếu đưa sang môi trường production dài hạn.

---

## Slide 9 - Hạn chế và hướng phát triển

Nội dung trên slide:

- Chưa xem đây là production SLA hoặc long-running soak test.
- Crawler lane cần hardening thêm về readiness, retry, backoff và observability.
- Cần bổ sung benchmark chất lượng semantic/AI và đo E2E latency đầy đủ.
- Cần hoàn thiện backup/restore, runbook vận hành và monitoring dashboard.

Lời nói:

Về hạn chế, nhóm em nhìn nhận hệ thống đã chứng minh được kiến trúc và các luồng chính, nhưng chưa thể xem là một hệ thống production hoàn chỉnh.

Thứ nhất, benchmark hiện tại mới là baseline theo kịch bản có kiểm soát, chưa phải soak test chạy dài nhiều giờ hoặc nhiều ngày. Nếu triển khai production, cần đo thêm độ ổn định, memory, queue lag, throughput và recovery sau lỗi.

Thứ hai, crawler lane là phần phụ thuộc vào queue, worker và nguồn dữ liệu bên ngoài nên cần được hardening thêm. Các hướng cụ thể là readiness check rõ hơn, retry/backoff tốt hơn, dead-letter queue, metric queue depth và cảnh báo khi worker không consume.

Thứ ba, phần AI và semantic cần benchmark chất lượng riêng. Trong đồ án, trọng tâm của nhóm là kiến trúc và pipeline, nên chất lượng mô hình không phải phần tối ưu chính. Nếu phát triển tiếp, cần đánh giá chất lượng sentiment, topic/aspect và semantic search trên bộ dữ liệu chuẩn hơn.

Cuối cùng, để vận hành thật, hệ thống cần hoàn thiện backup/restore, runbook xử lý sự cố, monitoring dashboard và policy bảo mật dữ liệu.

---

## Slide 10 - Kết luận

Nội dung trên slide:

- SMAP giải quyết bài toán Social Listening ở mức kiến trúc hệ thống.
- Kiến trúc hiện thực theo microservices, event-driven và data pipeline rõ ràng.
- Đã có bằng chứng chạy thực tế, đồng thời xác định rõ phần cần phát triển tiếp.

Lời nói:

Để kết luận, đồ án SMAP tập trung giải quyết bài toán Social Listening ở góc độ hệ thống: làm thế nào để thu thập, chuẩn hóa, phân tích và tổng hợp dữ liệu mạng xã hội cho nhiều project và nhiều người dùng.

Nhóm em đã hiện thực hệ thống theo kiến trúc microservices kết hợp event-driven. Các service được tách theo trách nhiệm rõ ràng: project giữ ngữ cảnh nghiệp vụ, ingest điều phối và chuẩn hóa, scapper thu thập dữ liệu, analysis xử lý NLP và tạo read model, knowledge phục vụ search/chat/report, notification phục vụ realtime.

Điểm quan trọng là kiến trúc này không chỉ nằm trên slide mà đã map được với code, schema, queue, topic và artifact storage trong repo. Hệ thống cũng có benchmark và kiểm thử ở mức baseline để chứng minh các luồng chính đang hoạt động.

Hướng phát triển tiếp theo là hardening crawler lane, đo E2E latency đầy đủ hơn, benchmark chất lượng semantic/AI và hoàn thiện các phần vận hành production.

Em xin kết thúc phần trình bày tại đây và sẵn sàng trả lời câu hỏi của Hội đồng.

---

## Backup cho hỏi đáp

### Nếu hỏi vì sao chọn microservices

Vì các workload trong SMAP khác nhau rõ rệt. Auth/project là request/response ngắn; crawler là job dài, dễ lỗi và cần retry; analysis là stream processing; knowledge là vector indexing; notification là realtime fan-out. Nếu gom tất cả vào một service, lỗi hoặc tải cao ở crawler/analysis có thể ảnh hưởng trực tiếp tới dashboard và auth.

### Nếu hỏi vì sao dùng RabbitMQ và Redpanda cùng lúc

RabbitMQ dùng cho task command kiểu crawler: cần ACK/NACK, retry, completion queue và task lifecycle rõ ràng. Redpanda/Kafka API dùng cho event stream phân tích: UAP records và analytics events cần được nhiều consumer đọc độc lập như analysis, knowledge và notification.

### Nếu hỏi vì sao không gửi raw data trực tiếp qua queue

Raw social data có thể lớn và không đều kích thước. Hệ thống dùng MinIO làm artifact storage, còn message chỉ chứa reference, checksum và metadata. Cách này giảm áp lực lên queue, dễ retry và dễ truy vết lại batch.

### Nếu hỏi project chứa gì

`project-srv` giữ business context: campaign, project, trạng thái vòng đời, cấu hình crisis và metadata để nhóm dữ liệu theo project. Còn cấu hình datasource/crawl target chi tiết, scheduled job, external task và raw batch nằm ở `ingest-srv`, vì đó là execution context của pipeline.

### Nếu hỏi giao tiếp giữa các service

User-facing và internal command dùng HTTP request/response. Crawler dispatch/completion dùng RabbitMQ. UAP và analytics events dùng Redpanda/Kafka API. Realtime notification dùng Redis Pub/Sub và WebSocket. Raw/UAP artifact lớn lưu ở MinIO. SQL metadata/read model lưu ở PostgreSQL. Semantic vector lưu ở Qdrant.

### Nếu hỏi Slide 5 vì sao không show đủ bảng

Vì mục tiêu thuyết trình 15 phút là chứng minh thiết kế dữ liệu lõi, không phải đọc migration. Slide chỉ show các entity đại diện cho từng boundary: project context, ingest lineage, analysis read model, knowledge index và các store đặc thù.

### Nếu hỏi độ tin cậy benchmark

Benchmark ngày 17/05/2026 là baseline đo trong môi trường hiện có, không phải production SLA. Nó cho thấy dashboard/API quan trọng có số liệu tốt và cũng phát hiện crawler lane còn cần hardening. Nhóm em trình bày cả kết quả tốt và điểm yếu để tránh phóng đại.

### File/code có thể mở khi bị hỏi sâu

- `project-srv/internal/project/usecase/lifecycle.go`: activate project và gọi ingest.
- `project-srv/pkg/microservice/ingest/usecase.go`: HTTP internal client sang ingest.
- `ingest-srv/internal/execution/usecase/usecase.go`: dispatch target/job/task.
- `ingest-srv/internal/execution/delivery/rabbitmq/producer/producer.go`: publish task RabbitMQ.
- `scapper-srv/app/worker.py`: consume task và chạy crawler worker.
- `scapper-srv/app/storage.py`: upload raw artifact lên MinIO.
- `scapper-srv/app/publisher.py`: publish completion message.
- `ingest-srv/internal/execution/usecase/consumer.go`: consume completion, verify artifact, tạo raw batch.
- `ingest-srv/internal/uap/usecase/usecase.go`: parse raw batch và chuẩn hóa UAP.
- `ingest-srv/internal/uap/delivery/kafka/producer/producer.go`: publish UAP lên stream.
- `analysis-srv/internal/pipeline/usecase/run_pipeline.py`: pipeline phân tích.
- `analysis-srv/internal/contract_publisher/usecase/usecase.py`: publish analytics events.
- `knowledge-srv/internal/indexing/usecase/index_batch.go`: index vào Qdrant.
- `notification-srv/internal/analyticsbridge/bridge.go`: bridge analytics event sang Redis/WebSocket.
