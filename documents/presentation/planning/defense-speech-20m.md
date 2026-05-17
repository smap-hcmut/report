# Kịch bản thuyết trình 20 phút cho SMAP

## Mục tiêu của bài nói

Tài liệu này là phần lời nói dùng khi bảo vệ trước hội đồng. Cách trình bày được viết theo giọng văn trang trọng, rõ ý, bám đúng hiện thực code và `report/final-report/` hiện tại. Mục tiêu của bài nói là làm cho hội đồng thấy được ba điều: bài toán là gì, nhóm đã chọn kiến trúc nào và vì sao, và hệ thống đã có bằng chứng kiểm thử ra sao.

## Nhịp thời gian đề xuất

| Phần | Thời lượng |
|---|---:|
| Mở đầu và nêu bài toán | 1 phút |
| Bối cảnh, mục tiêu, phạm vi | 3 phút |
| Kiến trúc tổng quan và trade-off | 5 phút |
| Luồng xử lý chính | 4 phút |
| Kiểm thử và kết quả | 3 phút |
| Hạn chế và hướng phát triển | 2 phút |
| Kết luận | 2 phút |

---

## 1. Mở đầu

"Thưa quý thầy cô, em xin phép trình bày đề tài **Xây dựng hệ thống SMAP - Social Media Analytics Platform**. 

Ngay từ đầu, nhóm em xác định đây **không phải** là một đồ án nghiên cứu mô hình học máy theo nghĩa thuần túy. Trọng tâm của đề tài là thiết kế và hiện thực một hệ thống phần mềm có khả năng thu thập, chuẩn hóa, phân tích, truy hồi và hiển thị dữ liệu mạng xã hội theo hướng microservices, event-driven và polyglot persistence.

Lý do nhóm em chọn hướng này là vì bài toán social listening trong thực tế không chỉ là đọc dữ liệu. Dữ liệu đến từ nhiều nền tảng khác nhau, có độ nhiễu cao, thay đổi liên tục, và nếu xử lý không khéo thì hệ thống sẽ bị nghẽn ở cả khâu thu thập lẫn khâu phân tích. Vì vậy, ngay từ kiến trúc, nhóm em muốn chứng minh một điều rất cụ thể: hệ thống có thể chạy được, có boundary rõ ràng giữa các service, và có bằng chứng kiểm thử cho các luồng trọng yếu."

"Trong phần trình bày hôm nay, em sẽ đi theo một mạch rất rõ: đầu tiên là bối cảnh và mục tiêu; tiếp theo là kiến trúc tổng quan và lý do chọn các công nghệ; sau đó là các luồng xử lý chính; cuối cùng là kiểm thử, kết quả, hạn chế và hướng phát triển. Em xin phép trình bày ngắn gọn nhưng đầy đủ, để hội đồng có thể nhìn thấy từ bài toán cho tới bằng chứng triển khai."

---

## 2. Bối cảnh, mục tiêu và phạm vi

"Trước hết, về bối cảnh, social listening và social analytics là một nhu cầu rất thật trong vận hành nội bộ của các nhóm marketing, theo dõi thương hiệu, nghiên cứu thị trường và quản lý truyền thông. Các hệ thống trên thị trường thường giải quyết bài toán này theo hai hướng: либо là dịch vụ phân tích chuyên sâu, либо là nền tảng tự phục vụ có dashboard và cảnh báo. Điều đó cho thấy nhu cầu không chỉ dừng ở việc thu thập dữ liệu, mà còn cần tổ chức dữ liệu thành insight có thể sử dụng được.

Từ bối cảnh đó, SMAP được định vị là một nền tảng phục vụ vận hành nội bộ. Chúng em không đặt mục tiêu xây dựng một sản phẩm bao phủ toàn bộ thị trường, mà chọn một phạm vi đủ sâu để chứng minh kiến trúc và luồng xử lý của hệ thống. Nói cách khác, nhóm em ưu tiên chiều sâu của hệ thống hơn là độ rộng tính năng.

Về mục tiêu cụ thể, báo cáo hiện tại đã đặc tả **12 yêu cầu chức năng**, **7 yêu cầu phi chức năng** và **5 use case nghiệp vụ chính**. Các use case này xoay quanh những việc cốt lõi mà một nhóm phân tích nội bộ cần làm: thiết lập chiến dịch theo dõi, vận hành chiến dịch, tra cứu và hỏi đáp dữ liệu phân tích, theo dõi trạng thái và nhận cảnh báo, cũng như thiết lập hoặc quản lý quy tắc cảnh báo khủng hoảng.

Về phạm vi kỹ thuật, đồ án tập trung vào tổ chức kiến trúc hệ thống, tổ chức luồng dữ liệu, phân ranh giới giữa các service và lựa chọn công nghệ lưu trữ, giao tiếp cho phù hợp với từng loại workload. Nhóm em không đi sâu vào việc đề xuất một mô hình AI mới, mà sử dụng các công cụ và mô hình phù hợp để giải quyết bài toán trong phạm vi đã chọn."

"Nếu tóm gọn lại trong một câu, thì mục tiêu của đề tài là: xây dựng một hệ thống social media analytics có cấu trúc rõ, chạy được, kiểm thử được, và có thể mở rộng tiếp theo từng giai đoạn."

---

## 3. Kiến trúc tổng quan và trade-off

"Sang phần kiến trúc, đây là phần quan trọng nhất của bài trình bày. Hệ thống thực tế hiện được tổ chức thành **8 service folder chính**: `identity-srv`, `project-srv`, `ingest-srv`, `analysis-srv`, `knowledge-srv`, `notification-srv`, `scapper-srv` và `web-ui`.

Nhóm em cố tình không gom tất cả vào một khối monolith, vì workload của hệ thống là không đồng nhất. Có những phần rất nhẹ như xác thực, quản lý dự án và hiển thị giao diện; nhưng cũng có những phần nặng hơn rất nhiều như crawl dữ liệu, phân tích NLP, truy hồi tri thức và phát realtime notification. Nếu ép toàn bộ vào một tiến trình duy nhất, khi crawl hoặc analytics bị tải cao, các luồng nghiệp vụ nhẹ hơn cũng bị kéo chậm theo. Vì vậy, lựa chọn microservices ở đây không phải vì nó ‘đẹp’, mà vì nó phù hợp với bản chất workload của bài toán.

Trade-off của lựa chọn này là gì? Rõ ràng là phức tạp vận hành tăng lên. Khi dùng microservices, nhóm em phải chấp nhận nhiều boundary hơn, nhiều chỗ giao tiếp hơn, và việc debug cũng khó hơn monolith. Tuy nhiên, đổi lại hệ thống có khả năng cô lập lỗi tốt hơn, scale theo lane tốt hơn, và từng service có thể dùng ngôn ngữ phù hợp nhất với nhiệm vụ của nó. Vì vậy, nhóm em chọn Go cho các backend service lõi, Python cho analytics và crawler worker, còn Next.js 15 cho giao diện web.

Ở lớp giao tiếp, hệ thống cũng không dùng một cơ chế cho mọi thứ. Nhóm em dùng **RabbitMQ** cho crawl task, vì đây là kiểu workload dispatch theo job; dùng **Kafka** cho analytics data plane, vì đây là luồng dữ liệu cần downstream consumers; dùng **Redis Pub/Sub** cho realtime notification, vì đây là kênh fanout nhanh cho WebSocket; và dùng HTTP nội bộ cho các API đồng bộ cần phản hồi ngay. Trade-off ở đây là chúng em phải vận hành nhiều cơ chế messaging khác nhau, nhưng bù lại mỗi cơ chế đều đúng với đúng loại tải của nó.

Về lưu trữ, hệ thống áp dụng polyglot persistence. **PostgreSQL** giữ các dữ liệu nghiệp vụ cần transaction, constraint và truy vấn quan hệ; **Redis** giữ session, cache và các trạng thái ngắn hạn; **MinIO** giữ raw artifact và file output lớn; còn **Qdrant** giữ vector search và truy hồi ngữ nghĩa. Nhóm em không chọn một database duy nhất cho tất cả, vì như vậy sẽ ép những workload khác nhau vào cùng một mô hình lưu trữ không phù hợp."

"Nếu cần một câu chốt cho phần kiến trúc, em xin nói như sau: nhóm em chấp nhận độ phức tạp vận hành cao hơn để đổi lấy khả năng cô lập lỗi, chia tải hợp lý và tổ chức hệ thống đúng theo từng loại nghiệp vụ."

---

## 4. Luồng xử lý chính

"Từ kiến trúc tổng quan, em xin chuyển sang luồng xử lý chính để hội đồng thấy kiến trúc này bám sát nghiệp vụ như thế nào.

Đầu tiên là phía quản lý nghiệp vụ. `project-srv` chịu trách nhiệm quản lý campaign, project, brand keywords, competitor keywords, trạng thái và crisis config. `ingest-srv` chịu trách nhiệm quản lý datasource, target, dry run, crawl mode, lineage và chuẩn hóa UAP. Hai service này được tách boundary rất rõ: `project-srv` giữ business context, còn `ingest-srv` giữ execution context. Cách tách này giúp tránh việc trộn lẫn quyết định nghiệp vụ với hành vi runtime.

Khi project được kích hoạt, hệ thống đi vào lane thực thi. `scapper-srv` đóng vai trò crawler worker bất đồng bộ, nhận task từ RabbitMQ và tạo raw artifact. Sau đó `ingest-srv` chuẩn hóa dữ liệu sang UAP và publish tiếp sang analytics data plane. Đây là chỗ claim-check pattern trở nên quan trọng: hệ thống không đẩy raw payload lớn thẳng qua queue, mà lưu artifact ở object storage rồi chỉ truyền reference qua message. Nhờ đó, message queue không bị phình và luồng xử lý cũng dễ replay hơn.

Tiếp theo là lane phân tích. `analysis-srv` là event-driven NLP analytics engine. Pipeline của nó gồm nhiều pha: normalization, dedup, spam detection, thread topology, NLP enrichment, enrichment, review, reporting và crisis detection. Ở đây, các mô hình như PhoBERT ONNX, YAKE và SpaCy NER được dùng đúng vai trò của chúng: trích xuất tín hiệu sentiment, keyword, topic và các yếu tố hỗ trợ đánh giá. Kết quả được ghi xuống PostgreSQL và đồng thời publish sang Kafka để các service downstream như `knowledge-srv` tiêu thụ.

`knowledge-srv` tiếp tục nhận dữ liệu đã phân tích, lập chỉ mục vào Qdrant và cung cấp semantic search, chat theo ngữ cảnh, report generation và notebook integration. Ở lớp này, nhiệm vụ của service không phải là crawl hay phân tích lại từ đầu, mà là biến dữ liệu đã có thành tri thức có thể tra cứu và khai thác. `notification-srv` thì chịu trách nhiệm realtime delivery thông qua Redis Pub/Sub và WebSocket, để người dùng nhận được trạng thái và cảnh báo gần thời gian thực."

"Điểm em muốn nhấn mạnh ở phần này là: luồng xử lý của SMAP không phải là một đường thẳng đơn giản, mà là một chuỗi lane được phân tách theo trách nhiệm. Chính việc tách lane như vậy làm cho hệ thống dễ mở rộng, dễ kiểm thử và dễ diễn giải hơn khi báo cáo kết quả."

---

## 5. Kiểm thử và kết quả

"Sau phần kiến trúc và luồng xử lý, câu hỏi quan trọng tiếp theo là: hệ thống đã hoạt động được đến đâu, và bằng chứng kiểm thử của nhóm em là gì.

Về unit test, các package được báo cáo trong những service chính đều đạt **100% statement coverage** trong lần chạy được trích dẫn trong report. Điều này cho thấy logic nội bộ ở tầng delivery, use case, repository, model và transport đã được kiểm tra khá kỹ. Đặc biệt, các service như `identity-srv`, `project-srv` và `ingest-srv` đều có test theo đúng boundary của mình.

Về kiểm thử đầu cuối, report hiện ghi nhận **55 endpoints**, trong đó **44 pass**, **5 fail**, **4 partial** và **2 untestable**. Em xin nói thẳng là nhóm em không xem đây là một điểm yếu cần che giấu. Ngược lại, việc report rõ phần nào pass, phần nào fail, phần nào partial cho thấy nhóm em có thái độ kiểm thử trung thực. Một số luồng như crisis runtime bridge đã được verify riêng ở addendum ngày 2026-05-06, tức là sau báo cáo E2E chính, để xác nhận rằng cơ chế project-srv sang ingest-srv thực sự hoạt động trong runtime.

Về phi chức năng, các số đo trong môi trường K3s tham chiếu cho thấy API-lane giữ được p95 dưới 225 ms trong các scenario đã chạy, với throughput quan sát trong khoảng **6.949 đến 7.751 req/s**. Tuy nhiên, em muốn nhấn mạnh rằng đây là số đo trong cửa sổ workload cụ thể, không phải cam kết SLA production. Report cũng đã nói rõ rằng những kết quả này là baseline quan sát được, chứ chưa phải trần năng lực của toàn hệ thống.

Chính vì vậy, khi trình bày trước hội đồng, em sẽ không nói rằng hệ thống ‘hoàn hảo’. Em sẽ nói đúng hơn rằng hệ thống đã có bằng chứng kiểm thử tốt ở các luồng chính, nhưng vẫn còn các phần cần hoàn thiện thêm ở mức vận hành dài hạn và kiểm thử realtime end-to-end."

---

## 6. Hạn chế và hướng phát triển

"Ở phần này, em xin trình bày rất thẳng thắn về những hạn chế hiện tại.

Thứ nhất, hệ thống của chúng em vẫn đang là một đồ án thiên về kiến trúc và hiện thực hệ thống, nên các lớp vận hành như observability, runbook, backup/restore và disaster recovery chưa đạt mức hoàn chỉnh như một hệ thống production. Kiến trúc đã có, nhưng bộ vận hành toàn diện vẫn là hướng phát triển tiếp theo.

Thứ hai, kiểm thử realtime end-to-end vẫn là một điểm cần bổ sung. Report hiện có bằng chứng internal delivery và route cho notification, nhưng nếu hội đồng hỏi về độ trễ end-to-end của client, em sẽ trả lời đúng rằng phần này chưa được chuẩn hóa thành một chỉ tiêu định lượng cuối cùng.

Thứ ba, các phép đo NFR hiện mới là baseline trong cửa sổ đo K3s, chưa phải soak test nhiều giờ hay benchmark ở quy mô production. Do đó, em sẽ không suy rộng các số đo hiện tại thành năng lực tối đa của hệ thống.

Thứ tư, analytics và knowledge layer vẫn còn phạm vi nhất định. Chúng em đã chứng minh được pipeline, indexing, search, chat và report generation trong phạm vi dữ liệu và mô hình đã chọn, nhưng nếu muốn đi xa hơn về đa ngôn ngữ, benchmark chất lượng tri thức, hoặc các mô hình đánh giá hallucination và citation grounding, thì đó sẽ là hướng mở rộng cho giai đoạn sau.

Điểm quan trọng là: nhóm em không xem các hạn chế này là thất bại. Nhóm em xem chúng là ranh giới rõ ràng của phạm vi đề tài. Một đồ án tốt không nhất thiết phải giải quyết mọi thứ; điều quan trọng là biết rõ mình giải quyết cái gì, chưa giải quyết cái gì, và vì sao."

---

## 7. Kết luận

"Để kết thúc phần trình bày, em xin tóm lại ngắn gọn như sau.

SMAP là một hệ thống social media analytics được tổ chức theo hướng microservices, event-driven và polyglot persistence. Hệ thống hiện có 8 service folder chính, có phân ranh giới rõ theo capability và workload lane, có luồng dữ liệu từ thu thập đến phân tích đến truy hồi tri thức và cảnh báo, và có bằng chứng kiểm thử cho các luồng trọng yếu.

Giá trị lớn nhất của đề tài, theo em, không nằm ở việc dùng thật nhiều công nghệ, mà nằm ở chỗ các công nghệ đó được đặt đúng vai trò. RabbitMQ được dùng cho task dispatch, Kafka cho analytics stream, Redis cho realtime fanout, PostgreSQL cho metadata và lineage, MinIO cho artifact lớn, Qdrant cho semantic retrieval, còn WebSocket phục vụ notification gần thời gian thực. Mỗi lựa chọn đều có lý do và đều có trade-off đi kèm.

Vì vậy, nếu phải chốt lại đề tài trong một câu, em sẽ nói rằng: nhóm em đã xây dựng được một nền tảng có kiến trúc nhất quán, có hiện thực chạy được và có bằng chứng kiểm thử, đồng thời cũng xác định rõ các giới hạn hiện tại để tiếp tục phát triển trong các giai đoạn sau.

Em xin cảm ơn quý thầy cô đã lắng nghe, và em sẵn sàng trả lời các câu hỏi phản biện."

---

## 8. Câu nói ngắn để dùng khi cần chuyển ý hoặc chốt ý

- "Điểm em muốn nhấn mạnh ở đây là kiến trúc của hệ thống bám rất sát đúng loại workload mà nó phải xử lý."
- "Nhóm em chấp nhận phức tạp vận hành hơn để đổi lấy khả năng cô lập lỗi và scale theo lane."
- "Đây là số đo quan sát được trong môi trường K3s tham chiếu, không phải SLA production."
- "Em xin nói đúng theo bằng chứng hiện có, không suy rộng quá phạm vi report và code."
- "Những phần chưa hoàn chỉnh đã được nhóm em ghi nhận rõ như hạn chế và hướng phát triển."
