# SMAP Thesis Defense Ground Truth

Tài liệu này được viết lại dựa trên code thực và `report/final-report/` hiện tại, không bám vào các planning markdown cũ nếu chúng còn claim lệch với hiện thực. Mục tiêu là chốt đúng câu chuyện để bảo vệ trước hội đồng: nói đúng cái đã làm, chỉ rõ trade-off, và chuẩn bị sẵn câu hỏi phản biện khó.

## 1. Nguồn chuẩn tôi bám

Ưu tiên theo thứ tự:

1. Service README và code thật trong các repo service.
2. `smap-deploy/decision-log.md` và `smap-deploy/e2e-report.md`.
3. `report/final-report/chapter_4` đến `chapter_7`.
4. `report/final-report/chapter_8` và `chapter_9` chỉ dùng để hiểu report đang viết gì, không coi là bằng chứng triển khai.
5. `report/documents/presentation/planning/` chỉ dùng để phát hiện claim cũ, không dùng làm nguồn sự thật.

## 2. Current Truth từ code thực

- Hệ thống hiện có 8 service folder chính: `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`, `scapper-srv`, `web-ui`.
- Stack thực tế là Go cho các backend service lõi, Python cho `analysis-srv` và `scapper-srv`, TypeScript/Next.js 15 cho `web-ui`.
- Giao tiếp thực tế chia rõ:
  - RabbitMQ cho crawl task giữa ingest và crawler worker.
  - Kafka cho analytics data plane và các event phân tích.
  - Redis Pub/Sub cho notification ingress / realtime fanout.
  - HTTP nội bộ cho các API đồng bộ cần phản hồi ngay.
- Storage thực tế là polyglot persistence:
  - PostgreSQL cho metadata, lineage, state bền vững.
  - Redis cho session/cache/pub-sub/state ngắn hạn.
  - MinIO cho raw artifact và file output.
  - Qdrant cho vector search / RAG.
- `identity-srv` thực sự là OAuth2/JWT auth boundary, có API, consumer audit và test client.
- `project-srv` thực sự quản lý project/campaign lifecycle, brand keywords, competitor keywords, status và crisis config.
- `ingest-srv` thực sự quản lý datasource, target, dry run, crawl mode, lineage, UAP normalization và publish sang analytics.
- `analysis-srv` thực sự là NLP analytics engine event-driven, có pipeline 9 pha, PhoBERT ONNX, YAKE + SpaCy NER, dedup, spam, threads, reporting và crisis detection.
- `knowledge-srv` thực sự làm RAG, vector search, report generation, indexing, NotebookLM integration, Voyage AI embeddings và Gemini-based generation.
- `notification-srv` thực sự làm WebSocket realtime và alert delivery; README nói Discord alerts, nhưng code evidence cho phần Discord cần kiểm tra kỹ trước khi nói như feature hoàn chỉnh.
- `scapper-srv` thực sự là async crawler worker, submit task API và local debug output có; production handoff raw upload / completion publish vẫn cần nói thận trọng nếu không có evidence đầy đủ.
- `smap-deploy/e2e-report.md` addendum 2026-05-06 là evidence quan trọng cho crisis runtime bridge; khi nói trước hội đồng phải tách rõ "đã thiết kế" và "đã verify".

## 3. Chapter-by-chapter map của final report

### Chapter 0: Front matter
- Lời cam đoan, lời cảm ơn, tóm tắt đề tài.
- Dùng để mở báo cáo, không phải nội dung kỹ thuật.

### Chapter 1: Tổng quan
- Nêu bối cảnh social listening, mục tiêu, phạm vi dữ liệu và phạm vi kỹ thuật.
- Report này xác định rõ trọng tâm là thiết kế kiến trúc và luồng xử lý, không phải nghiên cứu ML chuyên sâu.
- Đây là chapter để nói vấn đề, không phải để khoe công nghệ.

### Chapter 2: Hệ thống liên quan
- So sánh các hệ thống trong nước và toàn cầu.
- Mục đích là đặt SMAP vào bối cảnh giải pháp social listening/media intelligence hiện có.
- Khi bảo vệ, chapter này chỉ nên dùng để giải thích vì sao bài toán có ý nghĩa thực tế.

### Chapter 3: Cơ sở kỹ thuật và công nghệ
- Gồm 11 section, hệ thống hóa nền tảng về microservices, communication, storage, AI/NLP, deployment.
- Đây là chapter lý thuyết nền, không phải bằng chứng rằng tất cả công nghệ đó đều được dùng hoàn chỉnh như một sản phẩm thương mại.
- Có thể dùng để giải thích tại sao chọn RabbitMQ, Kafka, Redis, MinIO, Qdrant, PhoBERT, Kubernetes.

### Chapter 4: Phân tích hệ thống
- Chapter này đặc tả 12 functional requirements, 7 non-functional requirements và 5 use cases.
- Đây là nơi chốt scope nghiệp vụ thật của report hiện tại.
- Nếu bị hỏi “hệ thống làm được gì?”, câu trả lời phải bám chapter này và code thật, không bám planning cũ.

### Chapter 5: Thiết kế hệ thống
- Đây là chapter quan trọng nhất của bảo vệ.
- Các phần chính:
  - 5.1 định hướng kiến trúc.
  - 5.2 system architecture overview.
  - 5.3 thiết kế chi tiết các service.
  - 5.4 thiết kế cơ sở dữ liệu.
  - 5.5 sequence diagrams.
  - 5.6 communication patterns.
  - 5.7 deployment architecture.
  - 5.8 traceability validation.
- Đây là chapter phải nói rõ trade-off, boundary, và why not alternatives.

### Chapter 6: Kiểm thử và đánh giá
- Chapter này trình bày unit test, integration/E2E, và NFR.
- Điểm cần nhớ:
  - Unit test theo service là rất mạnh.
  - E2E không phải 100% pass; report và addendum có dữ liệu chi tiết.
  - p95 và throughput là số đo trong K3s / workload window cụ thể, không phải cam kết production scale.
  - `infra_error` cần được nói cẩn thận vì report và artifact có cách diễn giải khác nhau ở một số chỗ.

### Chapter 7: Tổng kết
- Chapter này rất hữu ích cho defense vì nó nói thẳng hạn chế và hướng phát triển.
- Đây là nơi nên dùng để thể hiện sự trung thực: observability chưa đồng đều, realtime E2E còn thiếu, benchmarking dài hạn chưa hoàn chỉnh, analytics scope chưa phải đa ngôn ngữ tổng quát.
- Không nên né chapter này; hội đồng thường thích hỏi ở đây.

### Chapter 8: Tài liệu tham khảo
- Có nhiều reference chuẩn về microservices, DDD, Kafka, Redis, Kubernetes, PhoBERT, Qdrant, v.v.
- Tuy nhiên có một số reference liên quan Whisper / speech recognition cần đối chiếu rất kỹ với code thực trước khi đưa lên slide như một chức năng đã bàn giao.

### Chapter 9: Phụ lục
- Chứa acronym list và glossary.
- Dùng để tra cứu thuật ngữ, không phải nơi để khẳng định tính năng đã implemented nếu code không có.

## 4. Những claim cũ phải bỏ hoặc nói rất cẩn thận

- Không nói SMAP có 10 service nếu đang bám code thực hiện tại. Con số đúng để nói trong defense là 8 service folder chính.
- Không nói report hiện tại có 47 FR và 31 NFR. Chapter 4 / chapter 6 / chapter 7 hiện đang đi theo mốc 12 FR và 7 NFR.
- Không nói Whisper/Speech2Text là feature đã bàn giao nếu code không có source tương ứng. Nếu muốn nhắc, chỉ được xem là future work hoặc tài liệu tham khảo liên quan.
- Không nói E2E đã pass toàn bộ. Evidence hiện có là 44/55 endpoints pass, còn failures và partials phải biết giải thích.
- Không nói realtime notification đã chứng minh end-to-end client latency đầy đủ nếu chỉ có internal delivery / route evidence.
- Không nói performance là production SLA. Số đo hiện tại chỉ là observed baseline trong K3s và trong window đo cụ thể.
- Không dùng README/planning cũ làm chuẩn, đặc biệt các file còn nhắc service cũ hoặc port cũ.

## 5. Trade-off thật cần trình bày trước hội đồng

### Microservices vs monolith
- Chọn microservices vì workload không đồng nhất: auth/project nhẹ hơn crawl/analytics.
- Trade-off: phức tạp vận hành, khó debug, distributed state và network overhead tăng.
- Bù lại: isolate lỗi, scale từng lane, tách Go/Python/Next.js đúng sở trường.

### RabbitMQ vs Kafka vs Redis Pub/Sub
- RabbitMQ hợp với task dispatch / crawl runtime.
- Kafka hợp với analytics stream / data plane / downstream consumers.
- Redis Pub/Sub hợp với realtime fanout và notification.
- Trade-off: phải vận hành nhiều cơ chế message, nhưng mỗi cơ chế đúng với workload của nó.

### PostgreSQL vs MongoDB/Neo4j/Qdrant/MinIO
- PostgreSQL giữ metadata cần transaction, constraint và truy vấn quan hệ.
- MinIO giữ raw artifact lớn để tránh phình queue và table.
- Qdrant giữ semantic retrieval.
- MongoDB/Neo4j không phải lõi vì overhead vận hành cao hơn lợi ích trong scope hiện tại.

### Claim-check / object storage vs nhét payload vào queue
- Không gửi raw artifact lớn trực tiếp qua message queue.
- Gửi reference và lưu artifact ở object storage.
- Trade-off: thêm dependency vào MinIO, nhưng đổi lại giảm bottleneck và dễ replay hơn.

## 6. Câu hỏi yếu dễ bị hội đồng hỏi

1. Vì sao chọn microservices cho đồ án, có phải over-engineering không?
2. Vì sao dùng cả RabbitMQ và Kafka?
3. Vì sao chọn Qdrant thay vì MongoDB/Neo4j/Pinecone?
4. Whisper / speech-to-text đã implement chưa?
5. Discord alert có code thật hay chỉ là design intent?
6. E2E 55 endpoints, tại sao không phải tất cả đều pass?
7. Realtime notification đã chứng minh end-to-end latency chưa?
8. `infra_error` được định nghĩa thế nào?
9. Port trong local dev khác K8s vì sao?
10. Analytics pipeline có benchmark dài hạn hoặc soak test chưa?
11. Nếu một service fail giữa chừng thì sao?
12. Sao knowledge service dùng Voyage embeddings / Gemini, có lý do gì?

## 7. Slide phụ nên chuẩn bị

- Slide phụ 1: Truth table về service count, language, port, runtime.
- Slide phụ 2: Messaging choice matrix: RabbitMQ vs Kafka vs Redis Pub/Sub.
- Slide phụ 3: E2E result snapshot với 44 pass / 5 fail / 4 partial / 2 untestable.
- Slide phụ 4: NFR snapshot: p95, throughput, infra_error caveat.
- Slide phụ 5: Limitations and scope boundaries.
- Slide phụ 6: Not implemented / future work: Whisper, Discord, WebSocket E2E, soak test.
- Slide phụ 7: Data storage rationale: PostgreSQL / Redis / MinIO / Qdrant.

## 8. Cách trình bày trước hội đồng

### Mở đầu
- Nói ngắn gọn vấn đề: social listening cần pipeline xử lý dữ liệu lớn, không đồng nhất, và phải phục vụ người dùng nội bộ.
- Chốt ngay scope: đây là đồ án thiên về kiến trúc và hiện thực hệ thống, không phải một paper tối ưu ML.

### Thân bài
- Đi theo mạch: problem -> requirements -> architecture -> data flow -> testing -> limitations.
- Mỗi lần nói về công nghệ, phải trả lời được “tại sao chọn nó, và đổi lại phải chấp nhận gì”.
- Không phóng đại feature; chỉ nói những gì code và report có bằng chứng.

### Kết luận
- Nhấn vào ba giá trị thật: có kiến trúc rõ, có code chạy được, có evidence kiểm thử.
- Nhấn vào tính trung thực: biết rõ những gì chưa hoàn chỉnh và đã ghi trong hạn chế / future work.

## 9. Tóm tắt để tôi tự nhắc trước khi lên bảo vệ

- Đừng dùng planning cũ làm nguồn sự thật.
- Đừng nói quá số service, số FR/NFR, hoặc chất lượng E2E.
- Đừng biến Whisper/Discord thành feature đã bàn giao nếu chưa có code.
- Đừng nói performance là SLA production.
- Luôn quay lại trade-off và evidence.

## 10. Kết luận thực tế

SMAP hiện là một hệ thống social media analytics có kiến trúc microservices, event-driven, polyglot persistence, và đã có bằng chứng chạy được ở mức service, pipeline và E2E một phần. Nó đủ mạnh để bảo vệ như một đồ án kỹ thuật nghiêm túc, miễn là trình bày đúng phạm vi, đúng số liệu, và không đồng nhất design intent với code đã triển khai.

## 11. Kịch bản trình bày 20 phút

Mục tiêu của phần nói là không đi vào lan man công nghệ, mà trả lời đúng 3 câu hỏi của hội đồng: bài toán là gì, tôi đã chọn kiến trúc nào và vì sao, và bằng chứng nào chứng minh hệ thống thật sự chạy được.

### 11.1 Mở đầu 60 giây

Mở bằng một câu rất rõ:

> "Đề tài này không phải là một bài nghiên cứu ML thuần túy. Đây là một hệ thống social media analytics được thiết kế và hiện thực theo hướng microservices, event-driven và polyglot persistence để xử lý dữ liệu lớn, không đồng nhất, và vẫn phục vụ được nhu cầu nội bộ."

Sau đó chốt ngay 3 ý:

- Bài toán thật: social listening nội bộ cho brand/competitor tracking, analytics và alert.
- Phạm vi thật: kiến trúc hệ thống, workflow, storage, giao tiếp, kiểm thử.
- Bằng chứng thật: code chạy được, report có test evidence, và có giới hạn rõ ràng.

### 11.2 Thân bài theo 5 chặng

| Chặng | Slide | Mục tiêu nói | Câu chốt nên dùng |
|---|---|---|---|
| 1 | 1-2 | Giới thiệu đề tài và scope | "Tôi đang chứng minh một kiến trúc làm việc được, không chỉ một ý tưởng." |
| 2 | 3-5 | Bối cảnh, vấn đề, phạm vi | "SMAP được làm cho bài toán nội bộ, có giới hạn rõ, nên tôi chọn scope đủ sâu để chứng minh kiến trúc." |
| 3 | 6-10 | System context, container, infrastructure, event-driven, why microservices | "Tách lane theo workload là quyết định kiến trúc cốt lõi của hệ thống này." |
| 4 | 11-14 | Use cases, pipeline, sequence, database | "Tôi sẽ đi từ use case tới data flow để hội đồng thấy kiến trúc bám nghiệp vụ." |
| 5 | 15-19 | Kết quả, demo, roadmap, limitations, conclusion | "Đây là phần tôi nói rõ cái đã làm được, cái chưa làm được, và vì sao." |

### 11.3 Cách chuyển ý giữa các phần

- Từ vấn đề sang kiến trúc: "Để giải quyết bài toán này, một monolith đồng bộ sẽ gây nghẽn ở crawl và analytics, nên tôi tách lane và tách message bus."
- Từ kiến trúc sang kiểm thử: "Sau khi thiết kế boundary như vậy, câu hỏi tiếp theo là nó có chạy đúng không; vì vậy tôi trình bày luôn evidence kiểm thử."
- Từ kết quả sang hạn chế: "Những con số này là baseline quan sát được, không phải SLA production, nên tôi nói rõ giới hạn đo."

### 11.4 Câu kết nên dùng

> "Tôi không khẳng định SMAP là sản phẩm hoàn chỉnh cho mọi tình huống. Tôi khẳng định rằng trong phạm vi đã chọn, hệ thống có kiến trúc nhất quán, có hiện thực chạy được, có bằng chứng kiểm thử, và có hướng phát triển rõ ràng."

## 12. Những gì phải chuẩn bị trước khi vào phòng bảo vệ

### 12.1 Bộ tài liệu phải mở sẵn

- `report/final-report/chapter_4/index.typ`
- `report/final-report/chapter_5/index.typ`
- `report/final-report/chapter_6/index.typ`
- `report/final-report/chapter_7/index.typ`
- `smap-deploy/decision-log.md`
- `smap-deploy/e2e-report.md`
- `identity-srv/README.md`
- `project-srv/README.md`
- `ingest-srv/README.md`
- `analysis-srv/README.md`
- `knowledge-srv/README.md`
- `notification-srv/README.md`
- `scapper-srv/README.md`

### 12.2 Number sheet phải thuộc

- 8 service folder chính.
- 12 FR, 7 NFR, 5 use cases.
- E2E: 44 pass / 5 fail / 4 partial / 2 untestable.
- NFR: p95 trong cửa sổ quan sát dưới 225 ms, throughput 6.949-7.751 req/s.
- Unit test: các package được báo cáo đều đạt 100% statement coverage trong lần chạy trích dẫn.
- Crisis runtime bridge: manual runtime apply và auto-apply đều đã được verify ngày 2026-05-06.

### 12.3 Demo path an toàn

Nếu demo trực tiếp, thứ tự an toàn nhất là:

1. Login.
2. Mở project đã có sẵn hoặc project mẫu.
3. Hiển thị project/service boundary.
4. Đi vào dashboard hoặc insight page.
5. Nếu flow activate/dry run có rủi ro, dừng ở evidence/trace thay vì cố làm live.

Nếu một endpoint không ổn định, đừng cố cứu live demo bằng cách tranh luận; chuyển ngay sang backup slide và nói rõ đó là feature scope hoặc gap kiểm thử.

### 12.4 Những câu bắt buộc phải trả lời được

- "Tại sao chọn microservices?"
- "Tại sao RabbitMQ, Kafka và Redis lại cùng tồn tại?"
- "Tại sao Qdrant thay vì một vector store khác?"
- "Whisper có thực sự được triển khai không?"
- "E2E tại sao không phải 100% pass?"
- "Realtime notification đã có end-to-end evidence chưa?"
- "performance số đo này có phải SLA production không?"

## 13. Slide phụ để làm hội đồng bất ngờ

Các slide phụ này không đưa vào main 20 phút. Chúng chỉ xuất hiện khi hội đồng đào sâu vào điểm yếu.

| Slide phụ | Mục tiêu | Nội dung nên có |
|---|---|---|
| BP-1 | Chốt lại truth table hệ thống | service count thật, language stack, port/local vs K8s, trách nhiệm từng service |
| BP-2 | So sánh messaging | RabbitMQ vs Kafka vs Redis Pub/Sub, lý do chọn từng cái |
| BP-3 | So sánh storage | PostgreSQL vs Redis vs MinIO vs Qdrant |
| BP-4 | E2E evidence snapshot | 44/55 pass, 5 fail, 4 partial, 2 untestable, và vì sao |
| BP-5 | NFR caveat | p95/throughput/infra_error, cửa sổ đo, không phải production SLA |
| BP-6 | Not implemented / future work | Whisper, Discord, WebSocket E2E, soak test, observability |
| BP-7 | Local dev vs K8s | giải thích 8081/8082 là local dev, K8s dùng 8080 |
| BP-8 | Traceability map | FR/UC -> service -> test evidence |

### 13.1 Câu hỏi yếu đi kèm slide phụ

| Câu hỏi | Trả lời an toàn | Slide phụ |
|---|---|---|
| "Vì sao không làm monolith?" | Workload không đồng nhất; isolate lỗi và scale theo lane hiệu quả hơn | BP-2, BP-3 |
| "Vì sao dùng cả Kafka lẫn RabbitMQ?" | Mỗi broker phục vụ workload khác nhau: task dispatch vs data plane | BP-2 |
| "Whisper đã triển khai chưa?" | Chưa có source evidence; chỉ nên xem là future work hoặc reference | BP-6 |
| "Discord alert có thật không?" | Chỉ nói những gì code/README xác nhận; nếu không có source thì ghi là design intent | BP-6 |
| "E2E sao không 100% pass?" | Có failures/partials; phải nói rõ nguyên nhân và phạm vi | BP-4 |
| "Realtime đã chứng minh chưa?" | Internal delivery/route có evidence; full client latency vẫn là hạn chế | BP-6 |
| "infra_error vì sao khác nhau?" | Khác cách định nghĩa giữa report và CSV; phải nói đúng semantics | BP-5 |
| "port trong report sai à?" | Local dev port khác K8s port; không phải bug nếu giải thích đúng | BP-7 |

## 14. Trade-off và lựa chọn phải nói rõ

### 14.1 Microservices thay vì monolith

- Lý do chọn: workload chênh lệch lớn, cần tách auth/project khỏi crawl/analytics.
- Trade-off: khó vận hành hơn, distributed debugging khó hơn, network hop nhiều hơn.
- Cách nói trước hội đồng: "Tôi chấp nhận độ phức tạp vận hành để đổi lấy khả năng cô lập lỗi và scale theo lane."

### 14.2 RabbitMQ, Kafka, Redis Pub/Sub cùng tồn tại

- RabbitMQ: phù hợp task dispatch và crawl completion.
- Kafka: phù hợp analytics stream và downstream consumers.
- Redis Pub/Sub: phù hợp realtime fanout.
- Cách nói: "Tôi không chọn một broker cho mọi thứ; tôi chọn đúng broker cho đúng kiểu tải."

### 14.3 PostgreSQL, Redis, MinIO, Qdrant

- PostgreSQL: metadata, lineage, transaction, constraint.
- Redis: session/cache/state ngắn hạn.
- MinIO: artifact lớn và replay-friendly.
- Qdrant: semantic search / RAG.
- Cách nói: "Polyglot persistence không phải để phức tạp hóa, mà để tránh ép mọi dữ liệu vào một mô hình lưu trữ không phù hợp."

### 14.4 Go, Python, Next.js

- Go cho API và orchestration.
- Python cho analytics/NLP.
- Next.js cho UI và BFF.
- Trade-off: polyglot tăng chi phí maintain, nhưng phù hợp nhất với capability của từng lane.

## 15. Những câu tuyệt đối không nên nói

- Không nói 47 FR / 31 NFR nếu đang bám final report hiện tại.
- Không nói hệ thống có 10 service đã hoàn chỉnh nếu code truth là 8 service folder chính.
- Không nói Whisper/Speech2Text là feature đã bàn giao nếu không có code evidence.
- Không nói E2E pass 100%.
- Không nói realtime đã có end-to-end latency chuẩn production.
- Không nói performance hiện tại là SLA production.

## 16. Kết luận dùng khi chốt bài

> "Điểm mạnh nhất của SMAP không nằm ở việc tôi dùng nhiều công nghệ, mà ở chỗ tôi chứng minh được một pipeline social media analytics có boundary rõ, có hiện thực chạy được, có kiểm thử, có số đo và có giới hạn. Tôi chấp nhận trade-off của microservices và polyglot persistence vì nó phù hợp với bài toán thật và đã được chứng minh bằng code cùng evidence trong report."