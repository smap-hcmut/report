# SMAP Defense Q&A - 45 Minutes Detailed Pack

Mục tiêu: chuẩn bị câu trả lời cho phần phản biện 45 phút. Mỗi câu gồm câu trả lời ngắn, phần đào sâu nếu thầy hỏi tiếp, và evidence nên mở.

## 1. Kiến trúc và phạm vi

### Q01. Vì sao chọn microservices, có over-engineering không?

Trả lời ngắn:

> Nếu chỉ làm dashboard nhỏ thì monolith đủ. SMAP tách microservices vì workload khác nhau rõ rệt: CRUD/lifecycle, crawl task dài, analytics stream, vector retrieval và realtime notification. Tách service giúp scale/fail độc lập, nhưng nhóm thừa nhận trade-off là vận hành phức tạp hơn.

Đào sâu:

- `project-srv` cần consistency và business rules.
- `ingest-srv` cần scheduler, target claim và queue dispatch.
- `scapper-srv` là worker phụ thuộc external platform.
- `analysis-consumer` cần batch/event processing.
- `knowledge-srv` cần Qdrant/LLM retrieval.
- `notification-srv` cần WebSocket/Redis delivery.

Evidence:

- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:14`.
- `/Users/tantai/Workspaces/smap/SYSTEM_CONTEXT.md:104`.

### Q02. Nếu làm monolith thì có được không?

Trả lời:

> Có thể được ở prototype nhỏ. Nhưng monolith sẽ làm request/response, scheduler, crawler, analytics và websocket bị chung failure domain. Ví dụ scapper bị external timeout có thể ảnh hưởng API lifecycle; analytics chậm có thể ảnh hưởng dashboard/control plane. SMAP chọn tách lane để cô lập những phần dễ chậm và dễ fail.

Trade-off:

- Monolith dễ deploy hơn.
- Microservices cần route, health, logging, source-of-truth rõ hơn.

### Q03. Contribution chính của đồ án là gì?

Trả lời:

> Contribution không phải model AI mới. Contribution là platform architecture cho social analytics theo campaign: control plane có lifecycle/readiness, data plane có async crawl và claim-check, analytics lane có post_insight/contracts, knowledge lane có Qdrant/chat/report, và deployment/test/benchmark evidence.

### Q04. SMAP khác gì một dashboard BI như Metabase?

Trả lời:

> Metabase/Grafana chủ yếu visualization trên dữ liệu đã có. SMAP bao gồm phần trước visualization: campaign lifecycle, datasource/target execution, worker crawl, raw artifact, UAP normalization, NLP analytics, crisis runtime, knowledge retrieval và notification.

### Q05. Vì sao không tập trung cải thiện AI?

Trả lời:

> Vì phạm vi đồ án là kiến trúc hệ thống. AI model được xem là component trong pipeline. Nhóm vẫn đo AI sentiment baseline để biết chất lượng hiện tại, nhưng không claim nghiên cứu model mới. Nếu mở rộng, hướng cải thiện là dataset label, domain ontology, prompt/model tuning và benchmark chất lượng.

### Q06. Có đang overclaim production-ready không?

Trả lời:

> Không. Nhóm claim hệ thống có live K3s deployment, core flow verified và benchmark baseline. Nhóm không claim SLA production tuyệt đối, không claim full long-soak, không claim AI accuracy cao, và không claim full client WebSocket latency đã đo.

## 2. Requirements, use cases, actors

### Q07. Vì sao slide cũ nói 7 FR/8 use cases/2 actors, còn bây giờ nói 12 FR/7 NFR/5 use cases?

Trả lời:

> Slide cũ là snapshot sớm. Final report đã refactor yêu cầu theo capability: 12 FR, 7 NFR và 5 user-goal use cases. Cách mới chính xác hơn vì internal pipeline không nên bị đếm lẫn thành user use case độc lập.

Evidence:

- `/Users/tantai/Workspaces/smap/report/final-report/chapter_7/index.typ:9`.
- `/Users/tantai/Workspaces/smap/report/final-report/chapter_4/section_4_4.typ:5`.

### Q08. 5 use cases hiện tại là gì?

Trả lời:

1. Thiết lập chiến dịch theo dõi.
2. Vận hành chiến dịch theo dõi.
3. Tra cứu và hỏi đáp dữ liệu phân tích.
4. Theo dõi trạng thái và nhận cảnh báo.
5. Thiết lập và quản lý quy tắc khủng hoảng.

### Q09. Actor chính là ai?

Trả lời:

> Actor người dùng chính là analyst/marketing user. Ngoài ra có admin/operator cho các thao tác nhạy cảm và external systems như social media platforms/provider. Không nên nói chỉ có đúng 2 actor nếu đã đưa identity/provider boundary vào kiến trúc.

### Q10. Vì sao internal auth cũng là requirement?

Trả lời:

> Vì nhiều flow nhạy cảm không đi từ browser trực tiếp: project-srv gọi ingest-srv activation, analysis-consumer gọi project-srv apply runtime. Những route này cần internal auth/boundary để tránh public user gọi nhầm hoặc bypass business rules.

## 3. Messaging và dữ liệu

### Q11. Vì sao dùng cả RabbitMQ, Kafka/Redpanda và Redis?

Trả lời ngắn:

> RabbitMQ cho task queue có ack/retry, Kafka/Redpanda cho event stream/replay, Redis Pub/Sub cho fan-out notification nhẹ.

Đào sâu:

- Crawl task dài, có timeout/retry -> RabbitMQ.
- UAP và analytics contract là stream downstream -> Kafka/Redpanda.
- Notification không cần lưu bền như event log -> Redis Pub/Sub.

### Q12. Nếu chỉ dùng Kafka cho tất cả thì sao?

Trả lời:

> Kafka có thể làm nhiều việc, nhưng worker task queue cần ack/retry semantics và routing đơn giản theo platform. RabbitMQ phù hợp hơn cho crawler worker. Ngược lại, analytics output cần event stream và downstream replay, Kafka phù hợp hơn RabbitMQ. Dùng đúng tool cho đúng responsibility.

### Q13. Nếu chỉ dùng RabbitMQ cho tất cả thì sao?

Trả lời:

> RabbitMQ mạnh ở task queue, nhưng analytics/knowledge cần stream có ordering và replay theo topic/consumer. Kafka/Redpanda phù hợp hơn cho dữ liệu phân tích đi qua nhiều consumer.

### Q14. Claim-check pattern là gì trong SMAP?

Trả lời:

> Message queue chỉ truyền metadata/pointer, payload lớn lưu ở object storage. Scapper upload raw artifact lên MinIO, completion message gửi pointer về ingest. Ingest verify object rồi parse thành UAP. Cách này tránh queue bị nghẽn bởi video/transcript/JSON lớn.

Evidence:

- `/Users/tantai/Workspaces/smap/scapper-srv/app/worker.py:336`.
- `/Users/tantai/Workspaces/smap/ingest-srv/internal/uap/usecase/usecase.go:38`.

### Q15. Vì sao cần UAP?

Trả lời:

> Mỗi social platform có format khác nhau. UAP là format thống nhất cho downstream analytics. Nhờ UAP, analysis-srv không cần biết raw payload đến từ TikTok/Facebook/YouTube khác nhau thế nào.

### Q16. Vì sao dùng MinIO thay vì lưu raw vào PostgreSQL?

Trả lời:

> Raw payload lớn, phi cấu trúc và có lifecycle khác transactional metadata. PostgreSQL phù hợp state/query; MinIO phù hợp object artifact. Lưu raw vào PostgreSQL làm DB phình to, query chậm và khó quản lý payload lớn.

### Q17. Vì sao dùng PostgreSQL cho analytics mart?

Trả lời:

> Analytics dashboard cần filter theo project, time, sentiment, source, keyword/relevance. PostgreSQL có index, JSONB/GIN và transaction tốt. Raw event vẫn đi qua stream/object, nhưng read model phục vụ UI nên đặt ở PostgreSQL.

### Q18. Vì sao cần latest insight mart/materialized view?

Trả lời:

> Raw `analysis.post_insight` có thể có nhiều bản ghi/phiên bản. Dashboard thường cần insight mới nhất và filter nhanh. Latest insight mart giúp tránh timeout và giữ query UI ổn định hơn, trong khi raw table vẫn giữ evidence.

Evidence:

- `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:1`.
- `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:87`.

### Q19. Vì sao dùng Qdrant?

Trả lời:

> Chat/report cần semantic retrieval, không chỉ filter. Qdrant tối ưu vector search theo embedding. PostgreSQL vẫn là source of truth cho insight, còn Qdrant là retrieval index để knowledge-srv tìm nội dung liên quan theo project.

### Q20. Qdrant missing collection thì sao?

Trả lời:

> Knowledge-srv có logic ensure collection khi index batch/digest. Nếu project chưa có collection, hệ thống nên trả empty/controlled result thay vì biến thành outage. Đây là một hardening đã được rút ra từ production-stability work.

## 4. Runtime flows

### Q21. Project activation làm gì ngoài đổi status?

Trả lời:

> Project activation kiểm tra status hiện tại, gọi ingest-srv readiness, nếu thiếu datasource/target thì block. Nếu pass thì ingest activate runtime rồi project-srv mới chuyển project sang ACTIVE. Điều này giữ business state và execution state đồng bộ.

Evidence:

- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:12`.
- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:246`.

### Q22. Readiness fail thì phản hồi sao?

Trả lời:

> Hệ thống trả lỗi nghiệp vụ, không phải server error. E2E đã có case thiếu datasource thì `can_proceed=false`, activation bị từ chối bằng lỗi nghiệp vụ. Đây là expected behavior.

### Q23. Scheduler tránh duplicate crawl job như thế nào?

Trả lời:

> Ingest scheduler list due targets, sau đó claim bằng update có điều kiện. Nếu target đã bị worker khác claim, rows affected bằng 0 và target bị skip. Đây là atomic claim để giảm duplicate khi concurrent.

Evidence:

- `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:19`.
- `/Users/tantai/Workspaces/smap/ingest-srv/internal/execution/repository/postgre/due_targets.go:62`.

### Q24. Nếu scapper fail hoặc timeout thì sao?

Trả lời:

> Worker trả completion có status error/timeout; task queue có ack/retry semantics. Ingest có completion/error để mark trạng thái thay vì im lặng mất task. Đây là lý do crawl task không gọi HTTP sync trực tiếp.

### Q25. Raw payload có mất không?

Trả lời:

> Success path lưu raw artifact vào MinIO trước, completion chỉ chứa pointer/checksum/metadata. Ingest verify object rồi mới parse raw batch. Vì vậy raw evidence được tách khỏi message queue.

### Q26. Analysis publish output theo thứ tự có ý nghĩa gì?

Trả lời:

> Contract publisher publish batch completed, insights published, rồi report digest. Knowledge dùng digest như tín hiệu run complete. Thứ tự giúp downstream hiểu lifecycle của analytics output.

Evidence:

- `/Users/tantai/Workspaces/smap/analysis-srv/internal/contract_publisher/usecase/publish_order.py:1`.

### Q27. Notification có thật sự realtime không?

Trả lời:

> Gần thời gian thực sau khi analytics phát digest/crisis alert. Nó không phải realtime tuyệt đối từ lúc social post xuất hiện vì còn phụ thuộc crawl interval, queue và analytics cadence. Nhóm nên dùng từ `near-real-time`.

### Q28. Discord hoạt động thế nào?

Trả lời:

> Discord là alert path cho crisis critical có `ops_alert=true`, không phải mọi notification. Kafka crisis alert được bridge sang Redis channel, WebSocket usecase route message và nếu severity critical thì dispatch Discord embed.

Evidence:

- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:100`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:112`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/alert/usecase/dispatch_crisis.go:13`.

### Q29. Vì sao không gửi Discord cho mọi alert?

Trả lời:

> Gửi mọi notification ra Discord sẽ gây spam và giảm giá trị cảnh báo. Code hiện chỉ đẩy Discord cho crisis critical/ops alert để giữ signal discipline. Các notification thường đi qua WebSocket/dashboard.

### Q30. Crisis status và crawl mode có phải một thứ không?

Trả lời:

> Không. Business crisis status có thể là `NORMAL`, `WARNING`, `CRITICAL` trong project-srv. Crawl mode là behavior của ingest runtime, ví dụ normal/crisis crawl frequency. Project-srv quyết định mapping từ crisis config sang crawl mode.

## 5. Deployment và vận hành

### Q31. Hệ thống đang chạy ở đâu?

Trả lời:

> K3s homelab, namespace `smap`. UI public là `smap.tantai.dev`, API public là `smap-api.tantai.dev` với Traefik path prefixes.

Evidence:

- `/Users/tantai/Workspaces/smap/smap-deploy/single-source-of-truth.md:1`.
- `/Users/tantai/Workspaces/smap/SYSTEM_CONTEXT.md:36`.

### Q32. Vì sao `smap-deploy` là source of truth?

Trả lời:

> Microservices rất dễ lệch giữa slide, code và route thật. `smap-deploy` chốt namespace, service role, ingress path, health, operational commands. Khi bảo vệ, nhóm bám `smap-deploy` để nói đúng runtime.

### Q33. Nếu một service restart thì hệ thống có chết không?

Trả lời:

> Không nên chết toàn bộ vì service được tách lane. Tuy nhiên một lane có thể degraded. Ví dụ Redis restart làm notification bridge có transient errors, nhưng UI/API vẫn 200. Cách trả lời đúng là hệ thống có fault isolation, không phải zero-impact tuyệt đối.

### Q34. Redis vừa restart có đáng lo không?

Trả lời:

> Có tác động transient đến notification/crisis runtime state. Audit live thấy Redis load RDB khoảng 12.5s, notification/analysis có log transient, sau đó notification health báo Redis connected. Đây là bằng chứng hệ thống vận hành thật và cũng là lý do future work cần observability/runbook tốt hơn.

### Q35. Tại sao notification health 200 nhưng logs có warn?

Trả lời:

> Health phản ánh trạng thái hiện tại; log warn phản ánh transient trước đó. Với hệ thống distributed, cần đọc cả hai. Nếu health đã connected và không có warn mới, có thể tiếp tục demo; nếu warn đang lặp lại thì không nên demo notification live.

### Q36. K9s dùng để chứng minh gì?

Trả lời:

> K9s chứng minh hệ thống chạy thật trên namespace `smap`: pod readiness, deploy availability, logs từng service. Nó không thay test, nhưng là live ops proof.

## 6. Testing và benchmark

### Q37. Unit test chứng minh gì?

Trả lời:

> Unit test chứng minh logic service boundary không regress khi refactor: usecase, repository, handler, adapter. Nó không chứng minh service-to-service flow, nên cần integration/E2E.

### Q38. Integration test chứng minh gì?

Trả lời:

> Chứng minh các service giao tiếp đúng và giữ business state đúng: campaign CRUD, datasource CRUD, activation readiness, crisis runtime project-srv -> ingest-srv.

### Q39. E2E 55 endpoints có ý nghĩa gì?

Trả lời:

> Đây là snapshot gọi route thật trên deployment để kiểm tra API contract. 44 pass chứng minh core coverage, 4 partial/failed/not-testable chỉ ra giới hạn. Nhóm không claim 100% pass.

### Q40. Vì sao không 100% endpoint pass?

Trả lời:

> Một số endpoint phụ thuộc trạng thái runtime/browser sâu, dryrun/target activation condition hoặc feature gap tại thời điểm report. Quan trọng là core flows đã verify và các gap được ghi rõ.

### Q41. Benchmark có phải production SLA không?

Trả lời:

> Không. Benchmark là measured baseline trên live K3s trong scenario cụ thể. Muốn SLA cần long soak, saturation-to-failure, workload profile ổn định và monitoring đầy đủ.

### Q42. 50 concurrent users nghĩa là gì?

Trả lời:

> Là mức tải cao nhất đã test trong benchmark kit mà hệ thống còn trong ngưỡng acceptance của nhóm. Không phải max capacity cuối cùng. Muốn biết max cần tăng tải đến saturation và đo queue backlog/CPU/memory/error profile.

### Q43. p95 240ms đo cho cái gì?

Trả lời:

> Đo API/load scenario, không phải thời gian từ social post đến insight. Crawl end-to-end có external platform, queue và analytics cadence riêng, cần benchmark khác.

### Q44. AI sentiment accuracy 0.444 có thấp không?

Trả lời:

> Có, và nhóm không né. Đây là baseline evaluation, không phải claim model tốt. Điểm mạnh là hệ thống có evaluation loop và biết hướng cải thiện. Phạm vi đồ án là platform, không phải AI research.

### Q45. Macro F1 là gì và vì sao dùng?

Trả lời:

> Macro F1 trung bình F1 từng class, ít bị class lớn lấn át. Với sentiment thường có class imbalance, macro F1 cho thấy chất lượng giữa các nhãn hơn accuracy đơn thuần.

### Q46. Nếu thầy bảo benchmark quá ngắn?

Trả lời:

> Đúng. Nhóm ghi limitation: benchmark window ngắn, chưa long soak, chưa saturation/backlog drain. Kết luận chỉ là đạt baseline trong scenario đã đo.

### Q47. Test WebSocket end-to-end đã đủ chưa?

Trả lời:

> Chưa đủ để claim full client latency NFR. Evidence hiện có là route/internal delivery/health/log/code path. Full E2E WebSocket latency từ analytics event đến browser frame là future work.

## 7. AI, knowledge, report

### Q48. Chat/report có hallucination không?

Trả lời:

> Có rủi ro, nên knowledge lane phải grounding theo project insight, Qdrant index và analytics fallback. Nhóm không nên claim chat luôn đúng; chỉ claim có kiến trúc giảm hallucination bằng campaign-scoped evidence.

### Q49. Vì sao cần analytics fallback trong chat?

Trả lời:

> Nếu vector index chưa đủ hoặc Qdrant collection chưa có, chat vẫn có thể trả lời từ analytics snapshot thay vì fail hoàn toàn. Đây là degradation path.

### Q50. Report generation lấy dữ liệu từ đâu?

Trả lời:

> Report nên lấy từ knowledge/analytics evidence theo project: Qdrant indexed insight, PostgreSQL analytics snapshot và generated digest. Không nên nói report tự suy diễn từ model.

### Q51. Nếu Qdrant index stale thì sao?

Trả lời:

> Qdrant là index, source of truth vẫn ở PostgreSQL/analytics output. Khi index stale, cần invalidate/reindex theo analytics events. Đây là lý do knowledge-srv có consumer cho analytics topics.

### Q52. Vì sao dùng LLM provider ngoài?

Trả lời:

> Vì đồ án tập trung platform. LLM được dùng như component để diễn giải/summary trên dữ liệu đã grounded. Nếu cần độc lập hơn, future work có thể thay provider hoặc dùng local model.

## 8. Business/product questions

### Q53. SMAP giải quyết giá trị kinh doanh gì?

Trả lời:

> Giúp analyst theo dõi chiến dịch theo project, hiểu sentiment/topic/relevance, phát hiện sớm rủi ro, và tạo report/chat dựa trên evidence. Giá trị là giảm thời gian tổng hợp thủ công và tăng khả năng phản ứng theo chiến dịch.

### Q54. Vì sao campaign fairness quan trọng?

Trả lời:

> Nếu chỉ nhìn tổng throughput toàn hệ thống, campaign nhỏ có thể bị che bởi campaign lớn. Social listening cần scope theo campaign/project để analyst hiểu đúng ngữ cảnh và đánh giá công bằng.

### Q55. Làm sao xử lý off-topic/noise?

Trả lời:

> Có nhiều lớp: keyword/domain config ở project, relevance/ontology ở analytics, latest insight mart filter. Nhưng nhóm thừa nhận cần cải thiện bằng label data và domain ontology.

### Q56. Public vs private data?

Trả lời:

> Phạm vi đồ án là dữ liệu mạng xã hội công khai hoặc dữ liệu mà hệ thống/provider được phép truy cập. Không claim xử lý private user data sâu hoặc bypass platform policy.

### Q57. Nếu social platform đổi API/rate limit thì sao?

Trả lời:

> Tác động nằm chủ yếu ở scapper/provider adapter. Kiến trúc tách scapper khỏi ingest core giúp thay adapter/hardening mà không thay toàn bộ pipeline. Nhưng external dependency vẫn là risk.

### Q58. Hệ thống có multi-tenant đầy đủ chưa?

Trả lời:

> Hệ thống đi theo hướng shared platform với campaign/project scope và auth boundary. Tuy nhiên multi-tenant enterprise đầy đủ như billing/isolation policy/audit retention là future scope.

## 9. Security/RBAC

### Q59. Route nào cần admin-only?

Trả lời:

> Các route nhạy cảm như crisis config/runtime change cần admin/internal boundary. Vì nó có thể thay đổi crawl mode và tác động hệ thống, không nên để user thường gọi trực tiếp.

Evidence:

- `/Users/tantai/Workspaces/smap/project-srv/internal/crisis/delivery/http/routes.go:13`.

### Q60. Internal route khác public route thế nào?

Trả lời:

> Public route phục vụ browser/user qua auth. Internal route dùng service-to-service call, ví dụ project-srv gọi ingest activation hoặc analysis-consumer gọi project runtime. Internal route cần auth riêng để tránh bypass.

### Q61. Có lộ secret không?

Trả lời:

> Khi demo không show secret value. Chỉ show rằng secret/env/config tồn tại hoặc service health connected. Nếu cần chứng minh Discord, mở channel history hoặc code path, không paste webhook URL.

## 10. Codebase truth / slide mismatch

### Q62. Slide cũ có Collector/Speech2Text, có sai không?

Trả lời:

> Sai nếu nói như current core implementation. Current data plane là `ingest-srv` và `scapper-srv`; Speech2Text nếu còn nhắc thì là extension/future hoặc old design, không phải main proof.

### Q63. WebSocket service có phải service riêng không?

Trả lời:

> Current service là `notification-srv`, bên trong có WebSocket domain. Không nên gọi `WebSocket Service` như một core repo riêng nếu không có repo/deploy tương ứng.

### Q64. MongoDB có còn là storage chính không?

Trả lời:

> Trong current runtime/evidence chính, PostgreSQL/MinIO/Qdrant/Redis/Redpanda/RabbitMQ mới là các storage/bus cần bảo vệ. Nếu slide cũ có MongoDB collector flexible schema thì phải annotate là old/target hoặc bỏ nếu không có current deploy proof.

### Q65. `smap.collector.output` nghe giống Collector, có mâu thuẫn không?

Trả lời:

> Tên topic có thể còn legacy naming, nhưng runtime service tạo UAP hiện nằm ở ingest-srv. Không nên suy ra có Collector service hiện tại chỉ từ tên topic.

### Q66. Scapper hay Scrapper viết thế nào?

Trả lời:

> Repo hiện là `scapper-srv` theo codebase. Trong slide nên viết đúng repo/service name hoặc nếu dùng từ tiếng Anh phổ thông thì ghi `scraper worker` nhưng không đổi tên repo.

## 11. Demo/live defense

### Q67. Nếu demo live không load thì sao?

Trả lời:

> Chuyển sang proof: curl 200, K8s pods, screenshot saved, logs/health. Live demo là minh họa; evidence vận hành là health, logs, tests và benchmark.

### Q68. Nếu notification không hiện trên UI?

Trả lời:

> Notification phụ thuộc analytics event cadence. Health/log/code chứng minh delivery path; không nên fake crisis nếu chưa chuẩn bị. Nhóm sẽ show notification health Redis connected và K8s logs.

### Q69. Nếu Discord không có alert mới?

Trả lời:

> Discord chỉ nhận critical ops alert, không phải mọi event. Nếu không có real crisis event, không nên gửi giả trên production. Chứng minh bằng channel history/code path/secret configured mà không lộ secret.

### Q70. Nếu thầy hỏi "proof hệ thống chạy thật?"

Trả lời:

> Mở live UI, chạy curl 200, mở K9s namespace `smap`, show pods ready, show notification/analytics health và logs. Đây là proof runtime thật ngoài code.

## 12. Kết luận nên dùng khi bị hỏi câu tổng hợp

### Q71. Nếu phải tóm tắt đồ án trong 30 giây?

Trả lời:

> SMAP là platform social analytics theo campaign. Điểm chính là tách control plane, data plane, analytics/knowledge lane và notification lane để xử lý dữ liệu mạng xã hội bất đồng bộ, nhiều nguồn và có tải biến động. Hệ thống có deployment thật trên K3s, có test/benchmark evidence, và nhóm trình bày rõ cả limitation như AI quality baseline, benchmark window ngắn và WebSocket latency chưa đo đầy đủ.

### Q72. Nếu thầy hỏi "điểm yếu lớn nhất?"

Trả lời:

> Điểm yếu lớn nhất là evaluation chưa đủ sâu cho production-grade: benchmark chưa long soak/saturation, AI quality còn baseline, notification latency chưa đo end-to-end. Nhưng nhóm đã nhận diện rõ và có architecture để tiếp tục hardening.

### Q73. Nếu thầy hỏi "điểm mạnh lớn nhất?"

Trả lời:

> Điểm mạnh là hệ thống có end-to-end platform thinking: không chỉ UI hoặc AI, mà có lifecycle, async ingestion, raw artifact, normalized UAP, analytics contracts, knowledge retrieval, notification và live ops proof.

