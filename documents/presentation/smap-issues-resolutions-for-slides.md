# SMAP - Góc Nhìn Business Về Vấn Đề Và Phương Án Xử Lý

Tài liệu này tổng hợp các vấn đề đã gặp trong quá trình phát triển SMAP theo góc nhìn business trước, kỹ thuật sau. Mỗi vấn đề được diễn giải theo logic: nó làm giảm giá trị sử dụng của hệ thống như thế nào, ảnh hưởng gì đến người dùng marketing, và team đã đưa ra hướng xử lý ra sao để biến SMAP từ một hệ thống crawl dữ liệu thành một nền tảng hỗ trợ ra quyết định.

## Cách Đọc Nhanh

| Nhóm         | Thông điệp business nên đưa lên slide                                                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Business     | SMAP cần giúp marketer hiểu tình hình thương hiệu, phản ứng với rủi ro và tạo báo cáo hành động được, không chỉ xem dữ liệu thô.                                    |
| Big Data     | Khi nhiều campaign/project chạy đồng thời, hệ thống phải đảm bảo mỗi campaign đều có dữ liệu đúng scope, đúng thời điểm và không bị campaign khác chiếm tài nguyên. |
| Infra        | Độ ổn định vận hành quyết định niềm tin vào dữ liệu: service phải thật sự xử lý được job, không chỉ hiển thị trạng thái Ready.                                      |
| Logic code   | Nếu UI, API và pipeline hiểu khác nhau về cùng một dữ liệu, marketer sẽ nhìn thấy insight sai dù backend có thể đã xử lý đúng.                                      |
| AI/Analytics | AI chỉ có giá trị khi insight đúng ngữ cảnh thị trường; cần đo precision/recall/F1 và kiểm soát dữ liệu nhiễu thay vì chỉ demo kết quả đẹp.                         |

## Slide 1 - Bài Toán Thực Tế Khi Xây SMAP

SMAP hướng tới marketing user, nên giá trị business không nằm ở việc "có crawl social media" mà nằm ở 5 năng lực:

1. Theo dõi đúng phạm vi từng campaign/project để marketer không đọc nhầm dữ liệu.
2. Biến dữ liệu social lớn, nhiều nguồn và nhiều noise thành insight có thể hành động.
3. Phát hiện rủi ro thương hiệu sớm để team marketing có thời gian phản ứng.
4. Tạo chat/report có căn cứ dữ liệu thật, dùng được cho phân tích và ra quyết định.
5. Duy trì độ tin cậy vận hành khi nhiều campaign chạy đồng thời.

## Phiên Bản Business-First Để Đưa Vào Slide

Phần này là bản chắt lọc có thể đưa trực tiếp vào slide hoặc lời thuyết trình. Các mô tả tránh đi sâu vào tên service, thay vào đó tập trung vào tác động đến giá trị sản phẩm.

| Vấn đề business                                              | Vì sao quan trọng                                                                                                            | Hướng xử lý của team                                                                                                                      | Thông điệp slide                                                                             |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Dữ liệu nhiều campaign có nguy cơ không được xử lý công bằng | Nếu tạo nhiều campaign cùng lúc mà chỉ campaign đầu có data, marketer sẽ ra quyết định dựa trên dữ liệu thiếu mà không biết. | Thiết kế lại job theo campaign/project/source, thêm fairness cho scheduler, theo dõi queue theo từng campaign và viết E2E test song song. | SMAP cần đảm bảo campaign isolation, không chỉ tăng throughput tổng.                         |
| Filter Insights không chính xác hoặc chậm                    | Marketer dùng filter để trả lời câu hỏi business; filter sai đồng nghĩa insight sai.                                         | Đẩy filter xuống API/DB, tối ưu index/pagination, thêm loading state nhẹ và kiểm thử theo từng scope.                                     | Dashboard đáng tin khi filter contract thống nhất từ UI đến dữ liệu.                         |
| Dữ liệu crawl bị off-topic                                   | Nếu dữ liệu nhiễu đi vào phân tích, sentiment/report sẽ phản ánh sai tình hình thương hiệu.                                  | Dùng ontology, regex có kiểm soát, relevance filtering và source lineage để loại hoặc phân tách dữ liệu không liên quan.                  | Chất lượng insight bắt đầu từ chất lượng dữ liệu đầu vào.                                    |
| Crisis monitoring chưa thành luồng hoàn chỉnh                | Marketing team cần biết khi nào thương hiệu có rủi ro và khi nào hệ thống nên crawl sâu hơn.                                 | Nối cấu hình crisis theo project với adaptive crawling và notification theo ngưỡng riêng.                                                 | Crisis là một vòng phản ứng: phát hiện, tăng thu thập, cảnh báo và hỗ trợ xử lý.             |
| Notification quá ồn                                          | Nếu mọi thứ đều popup, cảnh báo quan trọng sẽ bị bỏ qua.                                                                     | Chỉ popup crisis, còn analysis/system notification nằm trong bell và có cooldown/dedupe.                                                  | Alert tốt phải ưu tiên tín hiệu quan trọng, không làm phiền người dùng.                      |
| Chat/report chưa đủ tính business                            | Report chung chung không giúp marketer ra quyết định.                                                                        | Grounding report/chat vào campaign knowledge, evidence, source và action recommendation.                                                  | AI report phải là tài liệu phân tích có căn cứ, không phải văn bản sinh tự động chung chung. |
| Project/campaign lifecycle chưa rõ                           | Khi project đã pause/archive nhưng dữ liệu vẫn ảnh hưởng dashboard, marketer có thể hiểu sai tình trạng campaign.            | Thêm state Active/Pause/Resume/Archive, tách project active khỏi project cũ và quản lý quyền thao tác.                                    | Lifecycle là cách kiểm soát phạm vi dữ liệu và trách nhiệm vận hành.                         |
| Stalker chưa gắn chặt vào insight                            | Data từ page/entity cụ thể cần được phân biệt với data keyword crawl.                                                        | Thêm filter source/stalker, soft delete/flush và loại data đã flush khỏi Insights.                                                        | Mỗi nguồn dữ liệu cần lineage rõ để marketer tin và kiểm chứng.                              |
| RBAC chưa được giải thích tốt trên UI                        | User bị chặn quyền nhưng không hiểu vì sao, làm giảm trải nghiệm quản trị.                                                   | Backend enforce admin-only, frontend hiển thị thông báo quyền rõ ràng và disable action không hợp lệ.                                     | Governance tốt cần vừa an toàn vừa dễ hiểu.                                                  |
| Service Ready nhưng worker có thể chết im                    | Hệ thống nhìn khỏe nhưng không tạo dữ liệu mới, làm dashboard mất độ tin cậy.                                                | Fail-fast worker, readiness thật, kiểm tra queue/consumer và log tập trung.                                                               | Reliability của data pipeline phải đo bằng khả năng xử lý job thật.                          |
| AI sentiment chưa đủ ổn trên dữ liệu thật                    | Nếu sentiment sai, brand health và crisis signal bị lệch.                                                                    | Đo bằng gold sample thật, tính precision/recall/F1, phân tách relevance và sentiment calibration.                                         | AI cần được đánh giá bằng số liệu thật, không chỉ bằng demo trực quan.                       |
| Benchmark cần có bằng chứng thuyết phục                      | Đồ án cần chứng minh hệ thống chịu tải và phản hồi tốt bằng công cụ chuẩn.                                                   | Dùng k6, Locust, JMeter, Newman, snapshot Kubernetes và report có chart/table.                                                            | Validation có raw evidence giúp kết quả bảo vệ đáng tin hơn.                                 |

## Narrative Gợi Ý Cho Slide

Có thể trình bày theo mạch sau:

1. **Bài toán business:** Marketing team cần theo dõi nhiều chiến dịch, nhiều nguồn social và nhiều tín hiệu rủi ro cùng lúc.
2. **Thách thức dữ liệu:** Dữ liệu social lớn, nhiễu, thay đổi nhanh và dễ bị sai scope nếu campaign/project không được quản lý chặt.
3. **Thách thức vận hành:** Trong kiến trúc microservices, hệ thống có thể "trông như đang chạy" nhưng worker hoặc queue bên dưới đã nghẽn.
4. **Thách thức AI:** Sentiment, chat và report chỉ có ý nghĩa khi được grounding vào dữ liệu đúng ngữ cảnh.
5. **Giải pháp của team:** Xây control-plane cho campaign/project, data-plane có filter/source lineage, runtime có health thật, và evaluation có benchmark.

## A. Business / Product Issues

### 1. Crisis config có backend nhưng UI/use case chưa thành E2E

- **Vấn đề:** Project tab hiển thị `No crisis config`, nút config không ổn định, query data crisis sai hoặc không hiện gì.
- **Tác động:** Marketing user không thể cấu hình brand risk theo project, làm mất use case quan trọng của hệ thống.
- **Phương án:** Nối E2E: UI config project crisis -> project-srv lưu config -> analysis-srv đọc runtime config -> adaptive crawling -> notification-srv gửi alert.
- **Đã đưa vào design:** Tách ngưỡng `WATCH` để boost crawling và `WARNING/CRITICAL` để notify user.
- **Thông điệp slide:** Crisis monitoring không chỉ là threshold; nó là closed-loop từ cấu hình đến crawl mode, detection và notification.

### 2. Ngôn ngữ crisis ban đầu quá technical, chưa đúng với marketing user

- **Vấn đề:** UI config crisis có các trường raw/technical, chưa giống cách marketer quản lý brand risk.
- **Tác động:** User business khó hiểu và khó dùng đúng cách cấu hình.
- **Phương án:** Đổi wording thành `Brand Risk Monitoring`, `Conversation Spike`, `Negative Sentiment Share`, `Issue Keywords`, `Influencer Amplification`, `Response Policy`.
- **Nhận định thêm:** Cột keyword group/weight/terms không nên chỉ là text input tự do; nên có preset/domain option và edit có guardrail.
- **Thông điệp slide:** Thiết kế UI được domain-specialized cho marketing, không expose raw engineering model một cách thẳng.

### 3. Notification bị spam và không phân loại giá trị business

- **Vấn đề:** Notification analysis/system hiện popup quá nhiều, làm loãng tin quan trọng.
- **Tác động:** User mất tín hiệu crisis, UI tạo cảm giác hệ thống ồn ào.
- **Phương án:** Chỉ popup với crisis alert; analysis notification chỉ nằm trong bell; dùng severity/title/content mapping và cooldown/dedupe.
- **Thông điệp slide:** Alerting cần signal discipline: crisis mới interrupt, insight bình thường chỉ lưu để user xem.

### 4. Chat và Reports ban đầu không đủ giá trị business

- **Vấn đề:** Chat trả lời không tự nhiên, report sinh ra nội dung chung chung, chưa đủ chất lượng để đưa cho business.
- **Tác động:** Mất use case quan trọng: campaign chatbot và AI report.
- **Phương án:** Gắn chat/report với knowledge-srv, campaign scope, artifacts lưu tại tab Reports, report có evidence/citation/section business như Executive Summary, Sentiment Drivers, Audience Language, Marketing Actions.
- **Thông điệp slide:** Report không phải export data; report là business intelligence artifact có grounding trong campaign knowledge.

### 5. Report tab thiếu delete và permission

- **Vấn đề:** UI Reports có View/Open/Download nhưng không có delete; cần phân quyền.
- **Tác động:** Report artifact tích lũy rác, admin không quản lý được output.
- **Phương án:** Thêm delete action có RBAC; user thường chỉ xem/tải, admin mới xóa.
- **Thông điệp slide:** Artifact lifecycle cũng cần governance như campaign/project lifecycle.

### 6. Project/Campaign lifecycle chưa đầy đủ

- **Vấn đề:** UI có pause campaign, không cần delete campaign, nhưng project thiếu Active/Pause/Resume/Archive.
- **Tác động:** Data pipeline khó biết entity nào còn được crawl/analysis, project cũ vẫn có thể làm nhiễu Insights.
- **Phương án:** Quản lý state rõ: `ACTIVE`, `PAUSED`, `ARCHIVED`; UI tách active project với các status khác; action pause/resume/archive cho project.
- **Thông điệp slide:** Lifecycle state là control-plane của data pipeline, không chỉ là nhãn trang trí trên UI.

### 7. Keyword management của project cần append-only

- **Vấn đề:** Hệ thống chưa có cơ chế update thêm keyword cho project rõ ràng; sửa keyword cũ có thể phá reproducibility của data đã crawl.
- **Tác động:** Nếu edit keyword cũ, kết quả lịch sử không còn truy vết được vì không rõ data được crawl theo điều kiện nào.
- **Phương án:** Cho append keyword mới; hạn chế/chống sửa keyword cũ; nếu cần thay đổi thì versioning keyword set hoặc archive target cũ.
- **Thông điệp slide:** Để đảm bảo auditability, crawl target nên versioned/append-only thay vì overwrite.

### 8. Stalker tab chưa bind đầy đủ vào hệ thống

- **Vấn đề:** Stalker dùng để theo dõi page/entity cụ thể, nhưng data vẫn trộn chung Insights/MAP, thiếu filter source/stalker và thiếu delete/flush đúng nghĩa.
- **Tác động:** Marketing user không phân biệt được data từ keyword crawl và data từ stalker; paused stalker vẫn có data cũ làm nhiễu analysis.
- **Phương án:** Thêm soft delete/flush; data của stalker đã flush không còn hiện trong Insights; thêm sourceKind/dataSource filter; hiển thị stalker data chung nhưng có segment/filter rõ.
- **Thông điệp slide:** Stalker là scoped data source, cần data lineage rõ khi visualize.

### 9. Facebook group private không thể coi như page công khai

- **Vấn đề:** User hỏi stalker có gắn group FB cần accept mới vào được không.
- **Tác động:** Private group có giới hạn access, cookie/account, policy và rủi ro crawl khác page public.
- **Phương án:** Tách loại target: public page/post vs private group; group private cần account/session được cấp quyền, legal/permission guardrail, và trạng thái target `NEEDS_ACCESS`.
- **Thông điệp slide:** Social source không đồng nhất; access model là một phần của thiết kế crawler.

### 10. Identity/RBAC cần rõ vai trò

- **Vấn đề:** Backend đã chặn mutation với `INSUFFICIENT_PERMISSIONS`, nhưng client ban đầu chưa hiện popup/giải thích riêng; đồng thời cần allow chỉ user `@hcmut.edu.vn` và cấp admin cho user cụ thể.
- **Tác động:** User không hiểu vì sao thao tác tạo project/campaign fail; security policy không được thể hiện tốt trên UX.
- **Phương án:** Identity chỉ cho email domain hợp lệ; admin-only cho mutation tạo/sửa/xóa resource trigger pipeline; UI map lỗi permission thành toast/modal để giải thích.
- **Thông điệp slide:** RBAC phải đồng bộ BE và UX: backend enforce, frontend explain.

## B. Big Data / Data Pipeline Issues

### 11. Tạo nhiều campaign đồng thời có nguy cơ chỉ campaign đầu được xử lý

- **Vấn đề:** Khi tạo 2 campaign cùng lúc, pipeline có thể chỉ chạy data cho campaign đầu hoặc campaign sau bị starvation.
- **Tác động:** Đây là lỗi nghiêm trọng với big data/control-plane: campaign isolation không đảm bảo, marketing user thiếu data mà không biết.
- **Nguyên nhân khả năng cao:** Queue/scheduler/dedupe key chưa scope đủ theo `campaign_id + project_id + datasource_id`; worker có thể xử lý FIFO và backlog của campaign đầu ăn hết capacity; job orchestration có thể tạo task cho campaign đầu trước rồi không fairness cho campaign sau.
- **Phương án:** Định nghĩa job key/idempotency theo campaign-project-source; queue metric per campaign; scheduler fairness/round-robin; per-campaign quota; E2E test tạo 2 campaign song song và verify cả hai có task, completion, post_insight.
- **Thông điệp slide:** Big data pipeline cần multi-tenant fairness, không chỉ cần throughput tổng.

### 12. Query pagination/filter trên Insights từng timeout/không chính xác

- **Vấn đề:** Filter scope, keyword, project, sourceKind, pagination và sort engagement có lúc không work chính xác; pagination từng timeout.
- **Tác động:** Dashboard có thể show sai tập dữ liệu, marketer đưa quyết định sai.
- **Phương án:** Đẩy filter xuống API/SQL thay vì filter client; thêm loading state nhẹ từng region; optimize offset/limit và index; auto sort engagement; gắn link source gốc.
- **Thông điệp slide:** Visualization chỉ có giá trị khi filter contract đúng từ UI đến DB.

### 13. Materialized view refresh của analytics bị timeout

- **Vấn đề:** `analysis-api` mart refresh bị `statement timeout`; latest API có lúc stale vì materialized view chưa refresh xong.
- **Tác động:** Dashboard có thể hiện data cũ, gây hiểu nhầm campaign không có data mới.
- **Phương án:** Tăng timeout refresh có kiểm soát, manual refresh khi cần, deferred/short refresh behavior, phân biệt query live và mart stale.
- **Kết quả đo được:** Manual mart refresh từng mất khoảng 281s; sau đó cấu hình timeout refresh được nâng lên 600s.
- **Thông điệp slide:** Big data dashboard cần refresh strategy riêng, không thể query/refresh blocking tùy tiện.

### 14. JSON metadata query scan lớn khi flush/stalker visibility

- **Vấn đề:** Exclude data của flushed stalker/crawl target cần query `post_insight.uap_metadata`; cách query không indexable có thể chậm.
- **Tác động:** Flush/visibility update có thể gây 502/504 trên data lớn.
- **Phương án:** Dùng JSONB containment để tận dụng GIN index `idx_post_insight_uap_metadata`; soft-delete target và exclude trong analytics query.
- **Thông điệp slide:** Data lineage metadata phải được index hóa vì nó nằm trên đường query business.

### 15. Engagement sort làm user tưởng campaign không có data mới

- **Vấn đề:** API/UI mặc định sort theo engagement nên post mới có engagement thấp bị đẩy xuống dưới; user nghĩ campaign Ahamove không có data mới.
- **Tác động:** Hiểu nhầm về freshness của crawler.
- **Phương án:** Thêm sort theo time/latest, hiển thị timestamp/data freshness, giải thích sort mode; default phù hợp với use case hoặc có toggle rõ.
- **Thông điệp slide:** Ranking theo business value khác với freshness; UI cần expose cả hai.

### 16. Data crawl có off-topic/noise cao

- **Vấn đề:** Campaign Ahamove có nhiều post/comment về tình yêu, quote, nội dung không liên quan nhưng vẫn vào analytics.
- **Tác động:** Sentiment/keyword/report bị nhiễm noise; positive/neutral ratio có thể sai.
- **Phương án:** Domain ontology + regex/rule config cho marketer; relevance classifier; source/campaign keyword guardrail; show off-topic confidence và filter.
- **Thông điệp slide:** Chất lượng insight phụ thuộc vào relevance filtering trước khi phân tích sentiment.

## B.1. Mô Tả Chi Tiết Các Vấn Đề Big Data Theo Dạng Báo Cáo

Phần này diễn giải sâu hơn các vấn đề Big Data đã chọn để có thể đưa vào báo cáo hoặc dùng làm lời thuyết trình. Trọng tâm không chỉ là lỗi kỹ thuật, mà là rủi ro business khi hệ thống phân tích social media phải xử lý dữ liệu lớn, nhiều chiến dịch và nhiều nguồn dữ liệu cùng lúc.

### 1. Đảm bảo dữ liệu công bằng giữa nhiều campaign chạy đồng thời

Trong một hệ thống social listening phục vụ marketing, mỗi campaign đại diện cho một mục tiêu theo dõi riêng: một thương hiệu, một sản phẩm, một giai đoạn truyền thông hoặc một chiến dịch cụ thể. Vì vậy, khi người dùng tạo nhiều campaign trong cùng một thời điểm, hệ thống không được phép để campaign tạo trước chiếm toàn bộ tài nguyên crawl/analysis, khiến campaign tạo sau không có dữ liệu hoặc có dữ liệu rất trễ.

Vấn đề này có thể xảy ra khi pipeline xử lý dữ liệu chỉ tối ưu theo hàng đợi tổng, thay vì có cơ chế công bằng theo từng campaign. Ví dụ, nếu campaign đầu tiên sinh ra lượng crawl task lớn, worker có thể liên tục xử lý backlog của campaign đó trước. Campaign thứ hai dù đã được tạo thành công trên UI nhưng chưa nhận được task crawl tương ứng, hoặc task đã được tạo nhưng bị đẩy sâu trong queue. Từ góc nhìn business, đây là vấn đề nghiêm trọng vì marketer có thể nhìn vào dashboard của campaign mới và kết luận sai rằng thị trường chưa có dữ liệu, trong khi thực tế hệ thống chưa xử lý đến campaign đó.

Tác động lớn nhất của vấn đề này là mất tính cô lập giữa các campaign. Một nền tảng phân tích mạng xã hội không chỉ cần crawl nhiều dữ liệu, mà còn phải đảm bảo dữ liệu được phân bổ đúng theo từng ngữ cảnh theo dõi. Nếu không có campaign isolation, các chỉ số như mention volume, sentiment, top keywords hoặc crisis signal sẽ không còn đáng tin cậy khi hệ thống chạy nhiều chiến dịch đồng thời.

Phương án xử lý là thiết kế pipeline theo hướng multi-tenant ngay từ tầng job orchestration. Mỗi task cần được định danh theo khóa đủ chặt như `campaign_id + project_id + datasource_id`, thay vì chỉ dựa trên keyword hoặc source chung. Scheduler cần có cơ chế fairness, ví dụ round-robin theo campaign hoặc quota theo campaign trong từng chu kỳ xử lý. Queue metrics cũng nên được tách theo campaign/project để phát hiện sớm campaign nào đang bị đói tài nguyên. Ngoài ra, cần có E2E test tạo hai campaign cùng lúc, sau đó kiểm tra cả hai đều có crawl task, completion event và bản ghi analytics tương ứng trong `post_insight`.

Nội dung có thể đưa vào slide: **SMAP không chỉ cần throughput cao, mà cần đảm bảo mỗi campaign đều được xử lý công bằng và đúng phạm vi.**

### 2. Từ Metabase sang coded API query cho filter dữ liệu phân tích

Ở giai đoạn đầu, team đã triển khai Metabase để đổ dữ liệu phân tích về đó và phục vụ việc xem, lọc, kiểm tra nhanh các kết quả analytics. Đây là một lựa chọn hợp lý ở thời điểm khám phá dữ liệu vì Metabase mang lại nhiều giá trị: dễ dựng dashboard, dễ nhìn nhanh phân bố dữ liệu, dễ kiểm tra các bảng analytics, và hỗ trợ team hiểu dữ liệu đang được crawl/analysis như thế nào mà chưa cần xây toàn bộ API riêng.

Tuy nhiên, khi SMAP chuyển từ công cụ nội bộ sang sản phẩm phục vụ marketing user, nhu cầu filter không còn chỉ là lọc dữ liệu để quan sát. Filter trở thành một phần của trải nghiệm sản phẩm: user chọn campaign, project, source kind, platform, sentiment, keyword, stalker source, pagination, sort theo engagement hoặc latest, sau đó toàn bộ chart, list post, report và chat đều phải đọc cùng một phạm vi dữ liệu. Đây là yêu cầu mà Metabase không còn phù hợp để làm runtime API chính.

Giới hạn lớn nhất của Metabase nằm ở tính thích ứng với business workflow. Metabase rất tốt cho BI dashboard nội bộ, nhưng API/filter của nó khó đáp ứng các yêu cầu động của sản phẩm như phân quyền theo user, filter theo campaign/project hiện tại trên UI, đồng bộ trạng thái project/stalker đã pause/flush, xử lý pagination tối ưu, hoặc trả response shape đúng với component frontend. Ngoài ra, khi filter logic nằm trong dashboard BI, rất khó tái sử dụng chính xác cùng logic đó cho Insights, MAP, Reports, Chat và notification. Điều này tạo ra rủi ro: cùng một câu hỏi business nhưng mỗi nơi trong hệ thống có thể hiểu scope dữ liệu khác nhau.

Vì vậy, team chuyển hướng sang coded API query trong `analysis-api`. Thay vì để UI phụ thuộc vào một dashboard/query builder bên ngoài, các filter quan trọng được định nghĩa trong API contract rõ ràng: `campaignId`, `projectIds`, `sourceKind`, `keywords`, `platform`, `sentiment`, `contentType`, `limit`, `offset`, `sort`. Cách làm này giúp filter trở thành một phần chính thức của domain logic, có thể kiểm thử, tối ưu bằng index, cache, materialized view và tái sử dụng cho nhiều màn hình khác nhau.

Việc chuyển sang coded API query cũng giúp giải quyết vấn đề hiệu năng. Với Metabase, query thường phục vụ phân tích tương tác của con người, không nhất thiết tối ưu cho nhiều request nhỏ, liên tục và có pagination như UI sản phẩm. Với API tự viết, team có thể kiểm soát query plan, thêm index phù hợp, giới hạn `limit`, tối ưu `offset`, sort theo engagement/latest, và trả response nhẹ đúng nhu cầu frontend. Đồng thời, khi cần loại dữ liệu từ stalker đã flush hoặc project archived, logic này có thể được đưa trực tiếp vào API thay vì phải chỉnh nhiều dashboard rời rạc.

Tác động business của quyết định này khá rõ: marketer nhận được trải nghiệm filter thống nhất và đáng tin hơn. Khi họ chọn một project hoặc keyword, toàn bộ dashboard, post list, chart và report cùng nhìn vào một tập dữ liệu. Điều này quan trọng hơn việc chỉ có dashboard đẹp, vì quyết định marketing phụ thuộc vào tính nhất quán của insight.

Nội dung có thể đưa vào slide: **Metabase giúp team khám phá và kiểm tra dữ liệu nhanh, nhưng sản phẩm cần coded API query để đảm bảo filter động, phân quyền, hiệu năng và tính nhất quán business.**

### 3. Chiến lược refresh dữ liệu analytics trên dữ liệu lớn

Khi dữ liệu social tăng lên, dashboard không thể lúc nào cũng query trực tiếp toàn bộ bảng dữ liệu thô. Các chỉ số như KPI, sentiment distribution, platform distribution, keyword ranking hoặc project stats thường cần được tổng hợp trước để phản hồi nhanh trên UI. Vì vậy, hệ thống sử dụng các lớp dữ liệu đã xử lý như materialized view hoặc mart analytics để phục vụ truy vấn.

Vấn đề xuất hiện khi quá trình refresh các bảng tổng hợp này mất nhiều thời gian. Trong quá trình vận hành, có trường hợp refresh mart bị `statement timeout`, khiến dữ liệu mới đã vào bảng gốc nhưng dashboard vẫn đọc dữ liệu cũ. Với người dùng marketing, biểu hiện là campaign dường như không có dữ liệu mới, hoặc số liệu trên dashboard không khớp với dữ liệu thực tế vừa được crawl.

Đây là một vấn đề đặc trưng của big data dashboard: cần cân bằng giữa tốc độ phản hồi và độ mới của dữ liệu. Nếu query trực tiếp bảng gốc, UI có thể chậm hoặc timeout. Nếu phụ thuộc hoàn toàn vào bảng tổng hợp, UI nhanh hơn nhưng có rủi ro stale khi refresh chậm. Do đó, hệ thống cần một chiến lược refresh rõ ràng thay vì refresh blocking tùy tiện trong request path.

Phương án xử lý là tăng timeout refresh có kiểm soát, tách refresh khỏi request quan trọng khi cần, theo dõi thời gian refresh, và phân biệt rõ dữ liệu live với dữ liệu mart. Trong một lần kiểm tra thực tế, manual refresh mất khoảng 281 giây, cho thấy timeout 180 giây trước đó không đủ cho dữ liệu hiện tại. Sau đó cấu hình timeout được nâng lên 600 giây để tránh refresh thất bại sớm, đồng thời cần tiếp tục tối ưu query/mart để không chỉ dựa vào tăng timeout.

Về mặt business, vấn đề này ảnh hưởng trực tiếp đến niềm tin vào dashboard. Nếu marketer vừa cấu hình campaign hoặc stalker nhưng không thấy dữ liệu mới, họ có thể nghĩ hệ thống không hoạt động. Vì vậy, ngoài tối ưu backend, UI cũng nên thể hiện data freshness hoặc thời điểm cập nhật cuối cùng để user hiểu số liệu đang ở trạng thái nào.

Nội dung có thể đưa vào slide: **Với dữ liệu lớn, dashboard cần chiến lược tổng hợp và refresh riêng để vừa nhanh vừa đủ mới.**

### 4. Metadata và data lineage trở thành đường query chính

Ban đầu, metadata của dữ liệu crawl có thể chỉ được xem như thông tin bổ sung: dữ liệu đến từ nguồn nào, target nào, stalker nào, campaign/project nào. Tuy nhiên, khi hệ thống phát triển, metadata này trở thành yếu tố cốt lõi để filter và kiểm soát phạm vi phân tích. Ví dụ, khi một stalker bị flush hoặc một crawl target bị archive, dữ liệu liên quan cần được loại khỏi Insights mà không hard delete khỏi hệ thống.

Vấn đề là metadata thường được lưu dưới dạng JSON/JSONB để linh hoạt với nhiều loại source. Nếu query metadata bằng cách scan JSON không tối ưu, các thao tác filter hoặc flush có thể trở nên chậm khi dữ liệu lớn. Điều này không chỉ là vấn đề kỹ thuật DB; nó ảnh hưởng trực tiếp đến khả năng quản trị dữ liệu của business user. Khi user xóa/flush một nguồn stalker, họ kỳ vọng dữ liệu đó không còn xuất hiện trong dashboard. Nếu hệ thống mất nhiều thời gian hoặc timeout, trải nghiệm sẽ giống như thao tác không có hiệu lực.

Phương án được đưa ra là coi data lineage như một phần chính của mô hình truy vấn. Các trường metadata quan trọng cần được query bằng cách indexable, ví dụ dùng JSONB containment để tận dụng GIN index như `idx_post_insight_uap_metadata`. Đồng thời, các thao tác delete/flush nên là soft delete ở tầng source/target, sau đó analytics API loại dữ liệu tương ứng khỏi response. Cách này giữ được khả năng audit dữ liệu lịch sử mà vẫn đảm bảo dashboard phản ánh đúng phạm vi user mong muốn.

Tác động business là hệ thống cho phép marketer kiểm soát nguồn dữ liệu một cách an toàn. Họ có thể thử theo dõi một page/entity, sau đó flush hoặc archive mà không phá dữ liệu gốc, nhưng dashboard vẫn sạch và đúng scope.

Nội dung có thể đưa vào slide: **Trong social analytics, metadata không chỉ để lưu vết; nó là điều kiện để kiểm soát phạm vi insight.**

### 5. Cân bằng giữa dữ liệu mới và dữ liệu có tương tác cao

Trong social media analysis, một bài viết có nhiều tương tác thường quan trọng vì nó thể hiện mức độ lan truyền hoặc ảnh hưởng. Vì vậy, việc sort post theo engagement là hợp lý cho nhiều use case marketing. Tuy nhiên, nếu UI chỉ ưu tiên engagement, các bài viết mới nhưng chưa có nhiều tương tác sẽ bị đẩy xuống dưới. Điều này tạo ra hiểu nhầm rằng campaign không có dữ liệu mới, đặc biệt trong các campaign đang cần theo dõi real-time.

Vấn đề này cho thấy cùng một tập dữ liệu có thể phục vụ nhiều câu hỏi business khác nhau. Nếu marketer muốn biết "nội dung nào đang ảnh hưởng mạnh nhất", sort theo engagement là phù hợp. Nhưng nếu họ muốn biết "hệ thống có đang crawl dữ liệu mới không" hoặc "thị trường vừa nói gì gần đây", sort theo thời gian lại quan trọng hơn. Nếu UI không làm rõ hai góc nhìn này, người dùng có thể hiểu sai trạng thái hệ thống.

Phương án là hỗ trợ nhiều chế độ sắp xếp và thể hiện rõ ý nghĩa của từng chế độ. Insights nên có `Top engagement` để ưu tiên nội dung ảnh hưởng cao, đồng thời có `Latest` hoặc sort theo time để kiểm tra freshness. Post card cũng cần hiển thị thời gian, source link và source kind để user tự kiểm chứng. Với API, `sort=engagement` và `sort=time` cần được xử lý rõ ràng, có pagination ổn định và response nhất quán.

Từ góc nhìn business, đây là bài toán thiết kế insight chứ không chỉ là sort dữ liệu. Một dashboard tốt phải cho marketer chuyển đổi giữa hai câu hỏi: "điều gì đang tác động lớn nhất?" và "điều gì vừa xảy ra?".

Nội dung có thể đưa vào slide: **Ranking theo mức độ ảnh hưởng và theo độ mới là hai nhu cầu khác nhau; SMAP cần hỗ trợ cả hai.**

### 6. Dữ liệu off-topic làm giảm chất lượng insight

Dữ liệu mạng xã hội có đặc điểm rất nhiễu. Khi crawl theo keyword hoặc nguồn rộng, hệ thống có thể thu về nhiều nội dung không thật sự liên quan đến thương hiệu hoặc ngành hàng đang theo dõi. Trong campaign Ahamove, đã xuất hiện nhiều nội dung về tình yêu, quote, hoặc câu chuyện cá nhân không liên quan trực tiếp đến logistics nhưng vẫn đi vào analytics. Khi các nội dung này được phân tích sentiment, keyword hoặc đưa vào report, kết quả business có thể bị lệch.

Tác động của off-topic data đặc biệt nghiêm trọng với các chỉ số tổng hợp. Một vài bài không liên quan có thể không đáng kể khi xem thủ công, nhưng khi đi vào thống kê sentiment, keyword ranking hoặc report generation, chúng làm thay đổi bức tranh tổng thể. Ví dụ, hệ thống có thể ghi nhận positive/negative sentiment không phản ánh trải nghiệm khách hàng với thương hiệu, mà phản ánh cảm xúc của một nội dung ngoài ngành. Điều này làm giảm độ tin cậy của brand health, crisis detection và recommendation trong report.

Phương án xử lý là thêm lớp relevance trước hoặc song song với sentiment. Hệ thống cần biết một nội dung có liên quan đến campaign/project hay không trước khi dùng nó để tính chỉ số business. Lớp này có thể kết hợp nhiều kỹ thuật: ontology theo ngành, regex/rule do marketer cấu hình, keyword group có trọng số, source whitelist/blacklist, và về sau là relevance classifier. Quan trọng hơn, rule này phải được versioned và áp dụng xuyên suốt crawl, analysis, query, chat và report để tránh mỗi tầng hiểu "liên quan" theo một cách khác nhau.

Về mặt sản phẩm, cũng nên cho user thấy hoặc filter theo độ liên quan. Ví dụ, post có thể có nhãn `brand-relevant`, `industry-relevant` hoặc `off-topic candidate`. Điều này giúp marketer vừa không bỏ lỡ tín hiệu lạ, vừa không để dữ liệu nhiễu làm sai dashboard chính.

Nội dung có thể đưa vào slide: **Chất lượng insight không bắt đầu từ mô hình AI, mà bắt đầu từ việc xác định dữ liệu nào thật sự liên quan đến business.**

## C. Infra / Runtime / Kubernetes Issues

### 17. Service Ready nhưng worker bên trong có thể đã chết im

- **Vấn đề:** Có case reconnect Rabbit nhiều lần rồi worker im, pod vẫn Ready, flow không chạy.
- **Tác động:** Hệ thống nhìn có vẻ healthy nhưng không process data.
- **Phương án:** Fail-fast nếu worker startup fail; readiness phải check worker/queue state; timeout task; publish completion error thay vì treo unacked.
- **Đã làm với scapper-srv:** Worker startup fail thì raise để K8s restart; task handler có timeout; stale task sinh error completion.
- **Thông điệp slide:** Health check của microservice phải đo runtime capability, không chỉ HTTP process alive.

### 18. RabbitMQ backlog/unacked cần được giám sát như SLO

- **Vấn đề:** Queue có ready/unacked messages; nếu consumer chết im thì backlog tăng nhưng app vẫn Running.
- **Tác động:** Crawl/ingest delay không hiện ra UI ngay.
- **Phương án:** Theo dõi `messages_ready`, `messages_unacknowledged`, `consumers`; alert khi consumer = 0 hoặc unacked lâu; dashboard central log.
- **Thông điệp slide:** Queue metrics là bằng chứng sức khỏe của data pipeline.

### 19. Docker image sai architecture khi deploy lên cluster

- **Vấn đề:** Build/push image arm64 từ máy local, cluster amd64 kéo image bị `no match for platform`.
- **Tác động:** Rollout fail/ImagePullBackOff.
- **Phương án:** Buildx với `--platform linux/amd64` cho image deploy; verify image platform trước rollout.
- **Thông điệp slide:** CI/CD cần reproducible target platform, không phụ thuộc kiến trúc máy dev.

### 20. Log noise che mất lỗi thật

- **Vấn đề:** Info logs quá nhiều; warning/error quan trọng bị loãng.
- **Tác động:** Khi debug central log, khó nhìn thấy lỗi critical.
- **Phương án:** Phân loại log error/warn/info; production chỉ print warn/error cho service noisy; ops alert chỉ CRITICAL; user notification cũng phân loại.
- **Thông điệp slide:** Observability không chỉ là ghi nhiều log, mà là giữ signal-to-noise ratio.

### 21. Qdrant missing collection gây log error nhiều

- **Vấn đề:** Knowledge-srv query collection chưa tồn tại bị log như lỗi nghiêm trọng.
- **Tác động:** Log noisy, user nghĩ service fail.
- **Phương án:** Map missing collection thành sentinel/empty state; auto-create collection hoặc skip quiet cho đến khi có data.
- **Thông điệp slide:** Expected empty state không nên trở thành production error.

### 22. Redis outage/loading có thể gây lỗi tạm thời

- **Vấn đề:** Có thời điểm Redis loading/outage trong log.
- **Tác động:** Cache/session/notification có thể lỗi thoáng qua.
- **Phương án:** Retry có giới hạn, fallback, readiness dependency rõ, log warn có context và recovery.
- **Thông điệp slide:** Stateful dependency phải có graceful degradation.

### 23. 502 dưới load cần được phân biệt application vs edge/gateway

- **Vấn đề:** Benchmark Locust 50 users có 1 request `analytics_sentiment` 502, nhưng app logs không có exception match.
- **Tác động:** Cần biết lỗi ở app, ingress, timeout proxy hay network tail.
- **Phương án:** Log trace_id qua gateway->service; benchmark có log scan; maintenance-window stress test cao hơn; thêm metric 5xx per route.
- **Thông điệp slide:** 5xx investigation cần end-to-end trace, không chỉ đọc app log.

### 24. Autoscaling có tác động đến benchmark/runtime

- **Vấn đề:** HPA scale analysis-consumer lên/xuống trong lúc hệ thống hoạt động; startup/readiness event có thể xuất hiện khi rollout.
- **Tác động:** Benchmark hoặc log scan có thể bị nhiễu bởi event rollout/scale.
- **Phương án:** Tách rollout window và benchmark window; ghi snapshot trước/sau; đọc events theo thời gian.
- **Thông điệp slide:** Benchmark cần evidence về trạng thái cluster, không chỉ latency table.

## D. Logic Code / UI Contract Issues

### 25. UI hardcode/stale type làm sai dữ liệu hiển thị

- **Vấn đề:** Project card hardcode `crisis_config: undefined`; type status cũ `ACTIVE/INACTIVE`; comment sentiment cards bị hardcode positive trong khi detail record đúng.
- **Tác động:** UI làm người dùng thấy data sai dù backend đúng.
- **Phương án:** Sync DTO/type với backend; bỏ hardcode; dùng field sentiment/source/status thật từ API; test render theo sample response.
- **Thông điệp slide:** Contract drift giữa UI và API là nguồn lỗi lớn trong dashboard data.

### 26. Modal config crisis đè lên menu bar

- **Vấn đề:** Popup config crisis overlay sai z-index/layout, đè lên menu bar hệ thống.
- **Tác động:** UX kém và khó thao tác.
- **Phương án:** Chỉnh modal layering, scroll container, header/action sticky đúng vị trí.
- **Thông điệp slide:** Tool phức tạp vẫn cần polish UX để marketer dùng thật được.

### 27. Source link của post/comment thiếu hoặc chưa test đầy đủ

- **Vấn đề:** Post card cần gắn link gốc bài viết/comment; user cần verify source.
- **Tác động:** Mất trust, không thể audit insight.
- **Phương án:** Expose `url` từ API, nút `Source` mở link gốc; test với YouTube/Facebook/TikTok.
- **Thông điệp slide:** Social analytics cần traceability: mỗi insight nên quay về source gốc.

### 28. Chart ban đầu chưa tối ưu cho marketer

- **Vấn đề:** Chart MAP/Insights cần rõ hơn, có pie chart/legend platform, màu sắc/phân loại dễ đọc.
- **Tác động:** User khó đọc nhanh insight.
- **Phương án:** Dùng pie chart cho distribution, legend màu theo platform, sort/pagination rõ, chart title business-facing.
- **Thông điệp slide:** Visualization cần support decision, không chỉ render số liệu.

### 29. Project settings nên tách Project Info và Project Crisis Config

- **Vấn đề:** Project metadata, keyword/data collection và brand risk nằm chung modal dễ gây rối.
- **Tác động:** User khó tìm đúng nơi cấu hình.
- **Phương án:** Tách tab `Project info`, `Data collection`, `Brand risk`; crisis là một tab riêng với preset và response policy.
- **Thông điệp slide:** Tách control-plane theo mental model của user.

### 30. Permission lỗi BE nhưng UI chưa handler tốt

- **Vấn đề:** BE trả `INSUFFICIENT_PERMISSIONS`, UI chỉ để network error trong devtools.
- **Tác động:** User không biết cần admin hay quyền nào.
- **Phương án:** Frontend catch permission error, hiện toast/modal "Need ADMIN", disable action nếu role không đủ.
- **Thông điệp slide:** Security control cần visible affordance, không chỉ hidden failure.

## E. AI / Analytics / Knowledge Issues

### 31. Sentiment không có positive hoặc classification không ổn

- **Vấn đề:** Có giai đoạn campaign Ahamove và campaign cũ hầu như không có positive; sau đó phát hiện UI/list và analysis labels cần kiểm tra chất lượng.
- **Tác động:** Marketing insight bị lệch risk/brand health.
- **Phương án:** Đo AI bằng gold sample thật, tách relevance filtering và sentiment calibration, không demo fill domain.
- **Benchmark hiện tại:** 45 mẫu Ahamove thật: Accuracy 0.444, Macro F1 0.440, Weighted F1 0.449; negative F1 0.710 nhưng neutral/positive yếu.
- **Thông điệp slide:** Team đo chất lượng AI bằng precision/recall/F1, nhận diện rõ điểm yếu neutral/positive.

### 32. Report generation cần RAG/knowledge grounding thật

- **Vấn đề:** Report ban đầu có cảm giác chung chung/mock; user expect report phục vụ business.
- **Tác động:** AI report không thuyết phục khi demo với hội đồng.
- **Phương án:** Đưa report generation vào knowledge-srv/campaign knowledge; report section có evidence, confidence, source coverage, watchouts và recommended actions.
- **Thông điệp slide:** RAG/report phải có grounding, citation và actionability.

### 33. Chat không đơn thuần là RAG

- **Vấn đề:** Chat trong campaign cần hỏi đáp tự nhiên, gen report, truy vấn artifacts và data analytics; nếu chỉ RAG text thì thiếu.
- **Tác động:** Chatbot không tạo giá trị cho workflow marketer.
- **Phương án:** Chat orchestration: query analytics + knowledge search + report artifact creation + follow-up context.
- **Thông điệp slide:** Campaign copilot là workflow agent nhỏ, không chỉ semantic search box.

### 34. Regex/ontology config cần apply cả crawl, analysis và query

- **Vấn đề:** User cần expose một phần regex ontology cho marketing user cấu hình keyword group/rule.
- **Tác động:** Nếu regex chỉ apply lúc query mà không apply crawl/analysis, dữ liệu và insight lệch nhau.
- **Phương án:** Ontology rule là single source of truth: crawl targeting, analysis enrichment, search/filter và report đều dùng cùng version rule; có preview/test regex.
- **Thông điệp slide:** Domain ontology phải xuyên suốt pipeline, không phải setting UI cục bộ.

### 35. Knowledge cache/performance cần tối ưu nhiều lớp

- **Vấn đề:** Chat/report/query có thể chậm khi gọi knowledge/analytics lặp lại.
- **Tác động:** UX hỏi đáp và report generation kém.
- **Phương án:** Cache theo campaign/project/filter; cache search result có TTL; invalidate khi ingestion/analysis mới; summary cache cho report sections.
- **Thông điệp slide:** Knowledge layer cần cache có invalidation theo data freshness.

## F. Benchmark / Validation Issues

### 36. Cần benchmark bằng tool chuẩn, không chỉ script tự chế

- **Vấn đề:** Báo cáo đồ án cần số liệu legit: response time, load test concurrent users, AI precision/recall/F1.
- **Tác động:** Nếu chỉ nói "đã test" sẽ yếu khi bảo vệ.
- **Phương án:** Setup benchmark kit với k6, Locust, JMeter, Newman, kubectl/RabbitMQ/Redpanda snapshot và AI evaluator.
- **Kết quả hiện tại:** Report đã sinh tại `report/benchmark/reports/20260520-204400/benchmark-report.md`.
- **Thông điệp slide:** Validation có raw evidence, tool phổ biến và chart/table đọc được.

### 37. Benchmark cần ghi rõ giới hạn của phép đo

- **Vấn đề:** Benchmark live production-safe không phải destructive stress test.
- **Tác động:** Không nên claim hệ thống chỉ chịu được 50 users hoặc chịu vô hạn.
- **Phương án:** Ghi rõ `highest tested clean/accepted level`, không gọi là hard limit; nếu cần hard limit thì maintenance-window stress test.
- **Thông điệp slide:** Đo lường nghiêm túc cần nói đúng phương pháp và giới hạn.

## G. Các Vấn Đề Nên Đưa Vào Slide Theo Mức Độ Ưu Tiên

### Nên đưa vào slide chính

| Priority | Vấn đề                                                                                | Lý do nên nói                                               |
| -------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| P0       | Multi-campaign fairness: tạo 2 campaign đồng thời có nguy cơ chỉ campaign đầu có data | Thể hiện bài toán big data/control-plane thật.              |
| P0       | Filter/query Insights sai hoặc timeout                                                | Ảnh hưởng trực tiếp đến kết quả marketing user đọc.         |
| P0       | Service Ready nhưng worker chết im                                                    | Bài học microservices/Kubernetes rất thực tế.               |
| P0       | AI sentiment F1 còn thấp trên mẫu thật                                                | Trung thực, có số đo, cho thấy cần relevance + calibration. |
| P1       | Crisis config E2E + adaptive crawling + notification                                  | Use case khác biệt của hệ thống.                            |
| P1       | Report/chat cần grounding trong knowledge                                             | Use case business quan trọng.                               |
| P1       | RBAC admin-only và UX permission                                                      | Governance và security.                                     |
| P1       | Materialized view/query timeout và cache/index                                        | Big data performance story rõ.                              |

### Có thể đưa vào backup slide

| Vấn đề                                | Ghi chú                       |
| ------------------------------------- | ----------------------------- |
| Docker image platform mismatch        | Bài học deployment.           |
| Qdrant missing collection noisy error | Bài học expected empty state. |
| Notification spam                     | Bài học signal-to-noise.      |
| Source link/pagination/pie chart      | Bài học product polish.       |
| Project status active/paused/archived | Bài học lifecycle.            |
| Stalker soft delete/flush/filter      | Bài học data lineage.         |

## H. Gợi Ý Slide Flow

### Slide: "Những thách thức thực tế"

- Data social lớn, nhiều noise, nhiều source và nhiều campaign chạy đồng thời.
- Dashboard phải filter đúng scope và phản hồi nhanh.
- Microservices có thể Ready nhưng worker background chết im.
- AI insight phải được đo bằng số thật, không chỉ demo.

### Slide: "Cách team xử lý"

- Control-plane rõ: campaign/project status, RBAC admin-only, append-only keywords.
- Data-plane rõ: per-campaign scoping, queue monitoring, filter đẩy xuống API/DB, index/cache.
- Runtime rõ: fail-fast worker, readiness thật, central log, rollout + smoke test.
- AI layer rõ: ontology/relevance, RAG grounding, precision/recall/F1 benchmark.

### Slide: "Bằng chứng đo lường"

- k6: 1,800 requests, p95 130 ms, 0% fail.
- Locust: 25 concurrent users zero-error; 50 concurrent users accepted threshold với 0.02% error.
- JMeter: 300 API requests, 0% fail; p95 cao nhất analytics_kpis khoảng 1.5s.
- AI sentiment: Macro F1 0.440 trên 45 mẫu Ahamove thật.

### Slide: "Bài học kỹ thuật"

- Throughput tổng không đủ; cần fairness theo campaign/project.
- Health check HTTP không đủ; cần worker/queue readiness.
- Filter UI không đủ; query contract phải thống nhất UI -> API -> DB.
- Report/chat không được "AI nói chung"; cần evidence và campaign knowledge.

## I. Các Đầu Việc Có Thể Làm Tiếp Nếu Muốn Nâng Chất Lượng Hệ Thống

1. Viết E2E test tạo 2 campaign đồng thời, verify cả hai có crawl task, completion event và `post_insight`.
2. Thêm dashboard internal cho queue lag/unacked/consumer count theo campaign/source.
3. Thêm trace_id chạy qua gateway, analysis-api, knowledge-srv để truy 502.
4. Xây relevance classifier trước sentiment/report, dùng ontology regex versioned.
5. Mở rộng AI gold dataset lên 150-300 mẫu/3 domain: Ahamove logistics, Tanca HRM/CRM, marketing trend Vietnam.
6. Chạy maintenance-window stress test để tìm hard limit thật: 50/100/200/500 concurrent users.
7. Tích hợp benchmark report vào chapter evaluation và slide NFR.
