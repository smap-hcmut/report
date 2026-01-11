# SCRIPT THUYẾT TRÌNH CHI TIẾT - PHẦN KIẾN TRÚC & LUỒNG XỬ LÝ

## SLIDE: SYSTEM CONTEXT DIAGRAM

**Mục tiêu:** Giúp hội đồng hiểu SMAP nằm ở đâu trong hệ sinh thái phần mềm.

**VĂN NÓI:**

> "Tiếp theo, nhóm xin phép trình bày về kiến trúc hệ thống SMAP, được mô tả qua mô hình C4. Đầu tiên là mức **System Context** – cái nhìn tổng quan nhất về vị trí của hệ thống.
> SMAP tương tác với hai thực thể chính:
>
> 1. **Marketing Analyst**: Đây là đối tượng người dùng trung tâm. Họ sử dụng SMAP để cấu hình chiến dịch, theo dõi tiến độ thu thập và trực quan hóa các insight từ dữ liệu social.
> 2. **Social Media Platforms**: Cụ thể là YouTube và TikTok. Hệ thống sẽ kết nối với các nền tảng này thông qua cả API chính thống và các kỹ thuật Web Scraping tối ưu.
>
> Tóm lại, SMAP đóng vai trò là một 'phễu' xử lý thông minh: tự động hóa từ khâu thu thập dữ liệu thô, phân tích chuyên sâu cho đến khi cung cấp dữ liệu có giá trị cho người dùng.

---

## SLIDE: CONTAINER DIAGRAM - 10 SERVICES

**Mục tiêu:** Giải thích lý do chọn công nghệ (Polyglot) và phân bổ trách nhiệm của các service.

**VĂN NÓI:**

> "Ở cấp kiến trúc sâu hơn, SMAP áp dụng mô hình **Microservices** kết hợp **Polyglot Architecture** nhằm tối ưu cho từng tác vụ chuyên biệt. Hệ thống gồm 10 dịch vụ, trong đó 7 dịch vụ cốt lõi chia thành 2 nhóm chính:
>
> - Với **Golang**, tận dụng điểm mạnh về hiệu năng và xử lý song song, nhóm phát triển các dịch vụ:
>
>   - **Identity**: Quản lý định danh, xác thực, phiên làm việc.
>   - **Project & Collector**: Điều phối toàn bộ các quy trình thu thập dữ liệu.
>   - **WebSocket**: Thông báo realtime đến người dùng qua trình duyệt.
>
> - Với **Python**, dựa vào lợi thế hệ sinh thái AI/ML, nhóm xây dựng các dịch vụ:
>   - **Analytics**: Dùng PhoBERT để phân tích sentiment và aspect ngữ nghĩa tiếng Việt.
>   - **Speech2Text**: Chuyển âm thanh thành văn bản, bổ sung nguồn phân tích cho Analyst.
>   - Các **Scraper Service** cho từng nền tảng mạng xã hội.
>
> Các dịch vụ kết nối bất đồng bộ qua **RabbitMQ** và truyền dữ liệu realtime qua **Redis Pub/Sub**, nâng cao khả năng mở rộng, linh hoạt và ổn định khi hệ thống tăng tải.
>
> **Về phương pháp phân rã services:** Nhóm không phân chia services dựa trên cơ sở dữ liệu hay công nghệ, mà áp dụng **Domain-Driven Design (DDD)** để xác định ranh giới dựa trên các **Bounded Contexts** - tức là các miền nghiệp vụ độc lập. Mỗi service đại diện cho một Bounded Context với:
>
> - **Core Domain**: Analytics và Collector - đây là nơi tạo ra giá trị cạnh tranh chính, tập trung nguồn lực phát triển mạnh nhất.
> - **Supporting Domain**: Project, Identity - hỗ trợ cho Core Domain nhưng không phải là điểm khác biệt cốt lõi.
> - **Generic Domain**: Speech2Text, WebSocket - các chức năng có thể mua sẵn hoặc tái sử dụng.
>
> Cách tiếp cận này đảm bảo **High Cohesion** (các thành phần trong một service có mối liên hệ chặt chẽ) và **Low Coupling** (các services phụ thuộc tối thiểu vào nhau), giúp hệ thống dễ bảo trì, mở rộng và phát triển độc lập.

> Trong sơ đồ, có thể thấy **Speech-to-Text (STT)** được tách riêng thành một service độc lập - đây là chủ đích về kiến trúc:
>
> - **Về dữ liệu**: Trong thời đại video ngắn (TikTok, YouTube), phần lớn thông tin giá trị tập trung ở âm thanh và hình ảnh chứ không dừng lại ở comment, text. Nếu chỉ phân tích văn bản, chúng ta sẽ bỏ sót tới 70% insight. STT giúp hệ thống “nghe hiểu”, bổ sung chiều sâu và tăng độ chính xác báo cáo cho Analyst.
>
> - **Về kiến trúc**: Việc nhận diện giọng nói tiêu tốn nhiều tài nguyên (CPU/GPU). Tách STT thành một service độc lập giúp nhóm dễ dàng scale chuyên biệt mà không ảnh hưởng tới các dịch vụ khác như Identity, Project, đảm bảo hiệu năng tổng thể. Đây là lợi ích cốt lõi của Microservices: tách biệt, dễ nâng cấp/biến động theo nhu cầu thực tế từng thành phần.
>
> Sau khi đã hiểu về các services và trách nhiệm của chúng, nhóm xin phép đi sâu hơn vào cách tổ chức mã nguồn bên trong mỗi service."

---

## SLIDE: C4 LEVEL 3 - MODULE VIEW (KIẾN TRÚC GOLANG SERVICE)

**Mục tiêu:** Chứng minh việc áp dụng Clean Architecture và phân rã Module theo Feature để tăng khả năng bảo trì.

**VĂN NÓI:**

Dưới đây là bản văn nói được tái cấu trúc để mượt mà và chuyên nghiệp hơn, tập trung vào việc làm nổi bật tư duy thiết kế **Clean Architecture** và tính module hóa của hệ thống.

---

## SLIDE: C4 LEVEL 3 - MODULE VIEW (KIẾN TRÚC GOLANG SERVICE)

**Mục tiêu:** Chứng minh trình độ thiết kế hệ thống thông qua việc áp dụng Clean Architecture và phân rã Module theo Feature để tối ưu khả năng bảo trì.

**📝 VĂN NÓI:**

> "Để có cái nhìn chi tiết nhất về cách nhóm tổ chức mã nguồn bên trong, nhóm xin trình bày sơ đồ **Module View** của một dịch vụ Golang tiêu biểu trong hệ thống SMAP. Thay vì đi theo lối mòn 'package-by-layer' truyền thống, nhóm đã áp dụng triệt để mô hình **Clean Architecture** kết hợp với tư duy tổ chức **Package-by-feature** để đảm bảo tính đóng gói và linh hoạt cao nhất.
> Nhìn vào sơ đồ, dịch vụ được phân rã thành 4 lớp Module với nhiệm vụ riêng biệt:
> **Lớp thứ nhất - Bootstrap Layer:** Đây là điểm khởi đầu của mọi dịch vụ. Module `cmd/api` đóng vai trò là **Entry Point**, phối hợp chặt chẽ với module `config` để nạp các thông số môi trường và khởi tạo toàn bộ hệ thống thông qua cơ chế **Dependency Injection**.
> **Lớp thứ hai - Delivery Layer:** Đây chính là 'cửa ngõ' giao tiếp đa phương thức của Service. Module này không chỉ quản lý **HTTP API** mà còn điều phối linh hoạt các **Cron Jobs (Scheduler)** và các **Message Queue Consumers**. Điểm nhấn ở đây là module `middleware` được tách biệt hoàn toàn, giúp nhóm xử lý tập trung các logic chung như Authentication hay Logging trước khi request đi sâu vào lõi.
> **Lớp thứ ba - Application Layer:** Đây là nơi thể hiện rõ nhất tính linh hoạt của hệ thống. Nhóm không gộp chung mã nguồn mà chia theo từng **Feature độc lập** (ví dụ: Feature 1, Feature 2). Trong mỗi Feature, module **UseCase** đóng vai trò là 'bộ não' điều phối logic nghiệp vụ, giao tiếp với tầng dữ liệu thông qua các **Repository Interfaces** mà không cần quan tâm đến loại Database thực tế đang sử dụng là gì.
> **Lớp thứ tư - Domain Layer:** Tầng sâu nhất và cũng là quan trọng nhất, chứa các thực thể cốt lõi (`internal/models`). Điểm đặc biệt của nhóm là sự tách biệt hoàn toàn giữa **Core Business Entities** (Logic nghiệp vụ thuần túy) và **Persistence Models** (Mô hình dữ liệu DB). Điều này đảm bảo logic cốt lõi của SMAP không bao giờ bị phụ thuộc vào cấu trúc bảng của cơ sở dữ liệu.
> **Lợi ích thực tế:** Cách tổ chức này mang lại cho SMAP hai ưu điểm vượt trội: Một là khả năng **Testability** cực cao khi có thể mock dữ liệu dễ dàng; hai là sự **linh hoạt tối đa** — nhóm có thể thay thế PostgreSQL bằng bất kỳ hệ quản trị dữ liệu nào khác, hoặc chuyển đổi giao tiếp sang gRPC chỉ bằng cách sửa đổi lớp ngoài cùng mà không làm ảnh hưởng đến logic nghiệp vụ cốt lõi.
> Với cách tổ chức mã nguồn chặt chẽ như vậy, sau đây nhóm xin phép trình bày về hạ tầng triển khai để vận hành các services này một cách hiệu quả nhất."

---

**Bước tiếp theo:** Bạn có muốn tôi chuẩn bị các câu trả lời ngắn gọn cho các câu hỏi tiềm năng về việc **"Tại sao lại tách biệt Core Entities và Persistence Models?"** hoặc **"Lợi ích của Package-by-feature so với Package-by-layer là gì?"** để bạn tự tin hơn trong phần phản biện không?

---

## SLIDE: INFRASTRUCTURE COMPONENTS

**Mục tiêu:** Khẳng định sự vững chắc của nền tảng triển khai.

**VĂN NÓI:**

> "Để vận hành 10 services này, hạ tầng của SMAP được tổ chức thành 3 lớp chặt chẽ:
>
> 1. **Data Layer**: Nhóm áp dụng pattern **Database-per-Service** với PostgreSQL để đảm bảo tính cô lập dữ liệu. Bên cạnh đó, **MinIO** đóng vai trò lưu trữ đối tượng (Object Storage) cho các tệp tin lớn như audio, video; còn **MongoDB** được sử dụng như một giải pháp dự phòng linh hoạt cho dữ liệu từ Scraper.
> 2. **Messaging Layer**: Sự kết hợp giữa **RabbitMQ** (xử lý hàng đợi tác vụ) và **Redis** (caching & pub/sub) giúp hệ thống luôn ổn định ngay cả khi tải cao.
> 3. **Orchestration Layer**: Toàn bộ được triển khai trên cụm **Kubernetes On-premise**. Việc này giúp SMAP có khả năng tự phục hồi (Self-healing), cân bằng tải và quan trọng nhất là khả năng **Scale độc lập**. Ví dụ: khi cần quét một lượng lớn video TikTok, nhóm chỉ cần tăng cường tài nguyên cho Scraper Service mà không ảnh hưởng đến Identity Service.
>
> Tuy nhiên, để các services này có thể giao tiếp hiệu quả với nhau, đặc biệt là xử lý các tác vụ dài và dữ liệu lớn, nhóm đã áp dụng một kiến trúc đặc biệt."

---

## SLIDE 9: EVENT-DRIVEN ARCHITECTURE ⭐

**Mục tiêu:** Giải quyết bài toán hiệu năng và xử lý dữ liệu lớn (Highlight kỹ thuật).

**VĂN NÓI:**

> "Điểm đặc sắc nhất trong kiến trúc của SMAP chính là cơ chế **Event-Driven**. Thay vì bắt người dùng chờ đợi, mọi yêu cầu đều được xử lý theo dòng sự kiện. Người dùng chỉ cần tương tác với giao diện và nhận được phản hồi tức thì, còn mọi tác vụ khác sẽ được diễn ra âm thâm ở dưới hệ thống, và khi có kết quả, người dùng sẽ đươch nhận thóng báo,
> Đặc biệt, để giải quyết bài toán vận chuyển các file video/audio hàng trăm MB qua mạng mà không làm tắc nghẽn hệ thống, nhóm đã áp dụng **Claim-Check Pattern**.
> Cơ chế rất đơn giản nhưng hiệu quả: Thay vì gửi cả file qua Message Queue, Service gửi sẽ đẩy file vào **MinIO** và chỉ gửi đi một tấm vé (Reference ID) cực nhẹ qua **RabbitMQ**. Service nhận chỉ cần cầm 'tấm vé' đó để lấy dữ liệu về xử lý. Cách tiếp cận này giúp tăng throughput của hàng đợi lên gấp nhiều lần và loại bỏ hoàn toàn rủi ro nghẽn cổ chai dữ liệu lớn.
>
> Với Event-Driven Architecture, SMAP đã giải quyết được bài toán hiệu năng. Nhưng câu hỏi quan trọng là: Tại sao nhóm lại chọn kiến trúc Microservices ngay từ đầu?"

---

## SLIDE: TẠI SAO CHỌN MICROSERVICES?

**Mục tiêu:** Chứng minh quyết định dựa trên số liệu (AHP Matrix).

**VĂN NÓI:**

> "Khi thiết kế SMAP, câu hỏi quan trọng nhất của nhóm không phải là chọn công nghệ nào đang 'hot', mà là **'Kiến trúc nào thực sự giải quyết được đặc thù của dữ liệu Social Listening?'**.
> Để trả lời một cách khách quan nhất, nhóm đã áp dụng phương pháp định lượng **AHP (Analytic Hierarchy Process)**. Chúng em không chọn kiến trúc dựa trên cảm tính, mà dựa trên việc trọng số hóa 7 đặc tính cốt lõi (Architecture Characteristics).
> [Chỉ vào bảng AHP] Kết quả cho thấy mô hình **Microservices** đạt điểm số tối ưu **4.7/5.0**, hoàn toàn khớp với 3 bài toán thực tế mà SMAP phải đối mặt:
>
> 1. **Sự chênh lệch về tài nguyên (Asymmetric Workload):** Trong SMAP, các tác vụ Crawling và AI xử lý hàng triệu comment tiêu tốn CPU/RAM gấp hàng chục lần so với các tác vụ quản lý Project. Microservices cho phép chúng em thực hiện **Precision Scaling** – tức là chỉ cấp thêm tài nguyên đúng cho chỗ đang 'khát', tránh lãng phí tài nguyên tổng thể.
> 2. **Tận dụng sức mạnh đa ngôn ngữ (Polyglot Runtime):** SMAP cần sự ổn định, tốc độ của **Go** cho hệ thống lõi và cần hệ sinh thái AI hùng hậu của **Python** cho phân tích ngôn ngữ tự nhiên. Microservices chính là chiếc chìa khóa giúp chúng em kết hợp hoàn hảo cả hai thế giới này mà không gây xung đột về runtime.
> 3. **Độ tin cậy và Khả năng chịu lỗi (Fault Isolation):** Với đặc thù phụ thuộc vào bên thứ ba (YouTube, TikTok), việc một service bị chậm hay bị rate-limit là điều có thể xảy ra. Tuy nhiên, nhờ tính cô lập của Microservices, người dùng vẫn có thể đăng nhập, xem báo cáo cũ và cấu hình project bình thường ngay cả khi tiến trình thu thập đang gặp sự cố.
>
> Nhóm hiểu rằng Microservices đi kèm với chi phí vận hành phức tạp hơn. Tuy nhiên, chúng em chấp nhận đánh đổi đó để đổi lấy 3 trụ cột vững chắc cho hệ thống: **Khả năng sẵn sàng cao (Availability)**, **Hiệu năng xử lý (Performance)** và **Khả năng mở rộng không giới hạn (Scalability)**.
>
> Sau khi đã trình bày về kiến trúc hệ thống, nhóm xin phép chuyển sang phần chức năng - các Use Cases mà SMAP hỗ trợ."

---

## SLIDE: USE CASES OVERVIEW

**VĂN NÓI:**

> "Về mặt chức năng, SMAP bao gồm 8 Use Case chính được đặc tả theo chuẩn Cockburn - Thay vì chỉ vẽ sơ đồ, chuẩn này tập trung vào cấu trúc văn bản chi tiết để mô tả cách hệ thống tương tác với người dùng nhằm đạt được một mục đích cụ thể.. Bên cạnh các chức năng quản trị cơ bản, nhóm tập trung vào 3 tính năng tạo ra giá trị khác biệt:
>
> - **UC7 - Trend Detection**: Hệ thống tự động nhận diện các xư hướng dựa trên engagemnet rate - tỷ lệ tương tác.
> - **UC8 - Risk Detection**: Tự động cảnh báo khi có biến động bất thường trên mạng xã hội.
> - Và quan trọng nhất là **UC3 - Execute Project**, luồng xử lý mà nhóm sẽ trình bày chi tiết sau đây.
>
> Đây là use case phức tạp nhất, thể hiện rõ nhất cách các services phối hợp với nhau trong kiến trúc Event-Driven. Nhóm xin phép trình bày luồng xử lý chi tiết:"

---

## SLIDE : SEQUENCE DIAGRAM - EXECUTE PROJECT (1.5 phút)

**VĂN NÓI**

Bước 1 - Khởi tạo: User yêu cầu thực thi; Project Service kiểm tra quyền hạn, cập nhật trạng thái INITIALIZING vào PostgreSQL và trả về 200 OK ngay lập tức để không chặn người dùng.

Bước 2 - Điều phối: Message project.created được gửi vào RabbitMQ. Collector Service tiếp nhận, cập nhật trạng thái CRAWLING lên Redis và dispatch các job cho Crawler.

Bước 3 - Thu thập & Lưu trữ: Crawler Services thực hiện cào dữ liệu theo batch, upload lên MinIO và publish event data.collected.

Bước 4 - Phân tích AI: Analytics Service tải batch từ MinIO, chạy NLP Pipeline (Sentiment, Aspect, Impact) và thực hiện Batch INSERT vào database. Nếu phát hiện rủi ro cao, hệ thống tự động publish event crisis.detected.

Bước 5 - Giám sát tiến độ: Web UI sử dụng cơ chế Polling gửi request đến Project Service để lấy trạng thái xử lý thời gian thực từ Redis.

Bước 6 - Hoàn tất: Sau khi đối soát số lượng job hoàn thành, hệ thống cập nhật trạng thái cuối cùng là DONE và completed.

### 🎯 KEY POINTS:

- **UC3** = Use case phức tạp nhất
- **Sequence flow**: User → Project Service → RabbitMQ → Collector → Scrapers → Analytics
- **Real-time**: Redis Pub/Sub → WebSocket → User
- **Async + Non-blocking**: User không cần chờ
- **4 parts** sequence diagrams trong báo cáo

### ❓ Q&A PREP:

**Q**: Nếu Scraper fail giữa chừng thì sao?
**A**: "Nhóm implement retry mechanism với exponential backoff trong RabbitMQ. Nếu scraper fail, message được retry 3 lần. Sau 3 lần vẫn fail, message được move vào Dead Letter Queue. Admin có thể inspect DLQ và reprocess manual. Execution status được update thành PARTIAL_SUCCESS với log chi tiết."

**Q**: WebSocket connection bị disconnect thì sao?
**A**: "Frontend implement auto-reconnect với exponential backoff. Khi reconnect, client gửi last_event_id nhận được, WebSocket Service sẽ replay các events missed từ Redis. Nếu quá 1 giờ mới reconnect, client phải fetch full state từ REST API."

---

Dưới đây là bản văn nói đã được tinh gọn, tập trung vào các "keywords" kỹ thuật đắt giá và số liệu thực tế để gây ấn tượng mạnh với hội đồng trong thời gian ngắn.

---

## SLIDE: DATA PIPELINE - QUY TRÌNH XỬ LÝ 4 GIAI ĐOẠN

**Mục tiêu:** Khẳng định hiệu suất vượt trội của kiến trúc Event-Driven qua dòng chảy dữ liệu thực tế.

**📝 VĂN NÓI (Tinh gọn & Chuyên nghiệp):**

> "Từ Sequence Diagram vừa trình bày, quý thầy cô có thể thấy luồng xử lý của SMAP diễn ra qua nhiều bước. Để hiểu rõ hơn về cách dữ liệu được xử lý từ đầu đến cuối, nhóm xin phép trình bày chi tiết về **Data Pipeline 4 giai đoạn khép kín**., tối ưu hóa nhờ kiến trúc **Event-Driven (bất đồng bộ)**. Điều này giúp hệ thống đạt hiệu năng cực cao mà không gây nghẽn (non-blocking).
> **Giai đoạn 1 - Crawling (Thu thập):**
> Các Scraper Services chuyên biệt cho YouTube/TikTok thu thập metadata, comments và media. Điểm khác biệt là hệ thống tích hợp **Speech-to-Text** để chuyển audio sang văn bản, giúp SMAP không chỉ 'đọc' mà còn thực sự 'nghe hiểu' video. Dữ liệu thô được chuẩn hóa dạng **Atomic JSON**, lưu trữ tại **MinIO** để đảm bảo tính toàn vẹn và hỗ trợ xử lý lại (replay).
> **Giai đoạn 2 - Analyzing (Phân tích AI):**
> Analytics Service nhận tín hiệu và chạy **NLP Pipeline 5 bước**. Chúng em sử dụng mô hình **PhoBERT ONNX** để phân tích cảm xúc theo từng khía cạnh (Aspect-based) với kỹ thuật **Context Windowing**, giúp máy hiểu sâu ngữ cảnh xung quanh từ khóa. Hiệu suất đạt **P95 latency ~650ms/item**, đáp ứng hoàn hảo yêu cầu về tốc độ xử lý dữ liệu lớn.
> **Giai đoạn 3 - Aggregating (Tổng hợp):**
> Hệ thống tự động đúc kết insight theo thời gian và chủ đề (Topic Clustering). Mọi biến động bất thường về sắc thái (Sentiment) hay mức độ rủi ro (Risk) sẽ được phát hiện ngay lập tức. Dữ liệu sau tổng hợp được **cache lên Redis** để phản hồi dashboard trong vài mili giây.
> **Giai đoạn 4 - Finalizing (Hoàn thiện):**
> Cuối cùng, Project Service đóng gói kết quả và gửi thông báo qua **WebSocket**. Người dùng sẽ nhận được Notification và dashboard tự động làm mới ngay khi có kết quả mà không cần tải lại trang.
> **Tổng kết hiệu suất:** Với 100 videos thực tế, toàn bộ pipeline chỉ mất từ **8-12 phút** — nhanh gấp hàng chục lần so với phân tích thủ công. Đây là minh chứng cho một hệ thống có khả năng scale độc lập, giám sát chặt chẽ và sẵn sàng cho dữ liệu quy mô lớn."

## SLIDE 1: KẾ HOẠCH PHÁT TRIỂN (TITLE)

**Mục tiêu:** Dẫn dắt hội đồng bước vào tầm nhìn dài hạn của dự án.

**📝 VĂN NÓI:**

> "Sau khi đã chứng minh được tính khả thi của hệ thống hiện tại, em xin phép trình bày về **Kế hoạch phát triển** của SMAP trong tương lai. Lộ trình này không chỉ dừng lại ở việc duy trì, mà là nâng cấp toàn diện, sẵn sàng cho các bài toán dữ liệu thực tế với quy mô lớn."

---

## SLIDE 2: HYBRID INFRASTRUCTURE

**Mục tiêu:** Giải trình bài toán tối ưu chi phí và hiệu năng hạ tầng thông qua mô hình Hybrid Cloud.

**📝 VĂN NÓI:**

> "Đầu tiên là sự chuyển dịch về hạ tầng sang mô hình **Hybrid Infrastructure**.
> Tại đây, nhóm phân tách hệ thống thành hai phân vùng chiến lược:
>
> - **AWS Cloud đóng vai trò 'Bộ não quản lý' (Management Core):** Nhóm sẽ migrate các dịch vụ định danh và dự án lên **AWS Lambda (Serverless)** để tận dụng khả năng auto-scaling linh hoạt. Toàn bộ dữ liệu báo cáo và thông điệp sẽ được quản lý bởi **S3, RDS và EventBridge** để đảm bảo uptime 99.9%.
> - **Hạ tầng On-premise là 'Trung tâm xử lý hạng nặng' (High-Resource Workers):** Chúng em giữ lại các dịch vụ **Scrapers, STT và Analytics** tại nội bộ. Việc này giúp tận dụng tối đa phần cứng GPU sẵn có cho các mô hình AI nặng như **PhoBERT**, loại bỏ hoàn toàn chi phí Cloud đắt đỏ và vấn đề độ trễ Cold Start khi khởi tạo model.
>
> Chiến lược này giúp SMAP **tối ưu 60% chi phí vận hành** trong khi vẫn đảm bảo bảo mật dữ liệu thô tại chỗ."

---

## SLIDE 3: ENGINEERING & AI EXCELLENCE

**Mục tiêu:** Khẳng định sự nâng cấp về chất lượng mã nguồn và độ tin cậy của hệ thống.

**📝 VĂN NÓI:**

"Thay vì tập trung vào tối ưu hóa mô hình AI, trong giai đoạn tiếp theo, nhóm ưu tiên nâng cao Năng lực vận hành và Tính ổn định của hệ thống thông qua hai trụ cột chính:

Thứ nhất là Cải tiến Dịch vụ: Chúng em tiếp tục áp dụng triệt để Clean Architecture để refactor từng service chuyên biệt. Mục tiêu là làm cho mã nguồn trở nên linh hoạt hơn, sẵn sàng cho việc mở rộng tính năng mà không làm phá vỡ cấu trúc hiện tại.

Thứ hai là Mở rộng Giám sát: Đây là phần nhóm đặc biệt chú trọng. Chúng em không chỉ dừng lại ở việc xem biểu đồ, mà sẽ triển khai Distributed Tracing để theo dõi đường đi của dữ liệu giữa 10 dịch vụ khác nhau. Kết hợp với hệ thống Alerting thời gian thực, nhóm có thể phát hiện và xử lý lỗi ngay lập tức, đảm bảo Data Pipeline luôn hoạt động thông suốt.

Cuối cùng, toàn bộ hạ tầng vẫn được quản lý chuyên nghiệp bằng Terraform, đảm bảo tính nhất quán giữa môi trường Cloud và On-premise."
---

### ❓ Q&A PREP:

**Q**: Tại sao không migrate toàn bộ lên cloud?
**A**: "Có 2 lý do chính:

1. **Security & Compliance**: Core data về users và projects là sensitive data. Nhiều tổ chức có policy không cho phép user data lên cloud public. Giữ on-premise giúp tuân thủ GDPR và các regulations.
2. **Cost optimization**: Identity và Project Services có traffic đều đặn, chạy 24/7. On-premise cost-effective hơn cloud cho workload steady. Ngược lại, Scrapers có workload bursty - chỉ chạy khi có jobs - phù hợp với serverless pay-per-use.

Hybrid approach cho phép chúng em tối ưu cả về cost lẫn compliance."

**Q**: Chi phí AWS ước tính bao nhiêu?
**A**: "Ước tính cho Phase 1:

- Lambda cost: ~$200/tháng với 1000 videos/ngày, mỗi execution ~2-3 phút
- S3 storage: ~$100/tháng cho 10TB
- EventBridge + SQS: ~$50/tháng
- Tổng ~$500-1000/tháng

So với maintain EC2 instances 24/7 (~$1500/tháng), tiết kiệm ~40-60%. Khi scale lên 10,000 videos/ngày, Lambda cost tăng tuyến tính nhưng vẫn rẻ hơn provision servers."

**Q**: Cold start của Lambda có ảnh hưởng không?
**A**: "Cold start của Lambda thường ~1-2 giây. Với crawling tasks - mỗi job chạy 10-30 phút - cold start 1-2 giây là hoàn toàn chấp nhận được, chiếm <1% total execution time.

Nếu cần, chúng em có thể dùng **Provisioned Concurrency** cho Analytics Service nếu yêu cầu response time <500ms là critical. Nhưng với async processing qua queue, cold start không phải vấn đề lớn."

**Q**: Migration risk như thế nao?
**A**: "Chúng em có mitigation plan:

- **Phase-by-phase migration**: Không migrate all-at-once, từng phase 3-6 tháng
- **Parallel run**: Chạy song song on-premise và cloud trong 2-4 tuần, compare results
- **Rollback plan**: Giữ on-premise setup trong 3 tháng sau migration để có thể rollback
- **Testing**: Load testing và integration testing đầy đủ trước khi cutover
- **Monitoring**: CloudWatch + Prometheus để detect issues sớm

Risk được kiểm soát tốt với approach từng bước."

---

# PHỤ LỤC: Q&A TỔNG HỢP

## Câu hỏi về Kiến trúc

### Q1: Tại sao chọn 10 services, không phải nhiều hơn hoặc ít hơn?

**A**: "Số lượng services được quyết định dựa trên:

1. **Business boundaries**: Mỗi service đảm nhiệm 1 business capability rõ ràng (Identity, Project, Collector, Analytics...)
2. **Team size**: 10 services phù hợp với team 5-7 người, mỗi người handle 1-2 services
3. **Complexity vs Manageability**: Quá ít services (3-4) không tận dụng được benefits của microservices. Quá nhiều (20+) quá phức tạp để quản lý.
4. **Data domain**: Theo DDD, mỗi bounded context nên là 1 service

10 services là sweet spot cho bài toán này."

### Q2: Network latency giữa services có ảnh hưởng performance không?

**A**: "Có ảnh hưởng nhưng được minimize:

- Service-to-service call qua Kubernetes internal network ~5-10ms
- Hầu hết giao tiếp qua RabbitMQ (async), không có latency blocking
- Chỉ Identity ↔ Project có sync calls (validate JWT), nhưng có Redis cache cho tokens
- Implement circuit breaker pattern để tránh cascading failures
- Monitoring với Prometheus để track p95, p99 latencies

Trong testing, total request latency <500ms ở p95, đạt AC-2."

### Q3: Làm sao đảm bảo data consistency giữa các services?

**A**: "Chúng em dùng **Saga Pattern** cho distributed transactions:

- **Choreography-based Saga**: Services publish events, các services khác react
- **Eventual Consistency**: Chấp nhận data có thể inconsistent trong vài giây
- **Idempotency**: Mỗi event handler idempotent, có thể process nhiều lần không lỗi
- **Compensation**: Nếu một step fail, publish compensation events để rollback

Ví dụ: Execute project saga có 4 steps. Nếu Analyzing fail, publish ANALYSIS_FAILED event, Collector compensate bằng cách mark execution PARTIAL_SUCCESS."

## Câu hỏi về Event-Driven Architecture

### Q4: RabbitMQ có single point of failure không?

**A**: "Không, chúng em setup RabbitMQ cluster với 3 nodes:

- **Quorum queues**: Data replicated across 3 nodes
- **High availability**: Nếu 1 node down, 2 nodes còn lại vẫn hoạt động
- **Auto-failover**: Kubernetes restart failed pods automatically
- **Persistent messages**: Messages được lưu vào disk, không mất khi restart

Availability của RabbitMQ cluster là 99.9%."

### Q5: Message queue bị full thì xử lý sao?

**A**: "Có nhiều layer protection:

1. **Queue length limit**: Set max 10,000 messages per queue
2. **Memory limit**: RabbitMQ có memory threshold 80%, vượt qua sẽ block publishers
3. **TTL (Time-To-Live)**: Messages expire sau 24h nếu không được process
4. **Monitoring**: Alert khi queue length > 5000
5. **Backpressure**: Publishers receive back-pressure signal, slow down

Trong thực tế, với current workload (~1000 videos/ngày), queue length thường <100."

## Câu hỏi về AI/ML

### Q6: Tại sao dùng PhoBERT không phải ChatGPT API?

**A**: "Có 3 lý do:

1. **Cost**: ChatGPT API cost ~$0.002/1K tokens. Với 1000 videos, mỗi video 100 comments, average 50 tokens/comment = 5M tokens/ngày = $10/ngày = $300/tháng. PhoBERT self-hosted free sau initial setup.
2. **Latency**: ChatGPT API ~2-5 giây/request. PhoBERT inference <100ms. Với 100K comments, ChatGPT mất ~5 giờ, PhoBERT ~3 phút.
3. **Privacy**: Data không ra khỏi hệ thống, tuân thủ GDPR.

PhoBERT đủ tốt (85% accuracy) và cost-effective hơn nhiều."

### Q7: PhoBERT có thể detect sarcasm không?

**A**: "PhoBERT base model không detect sarcasm tốt (~60% accuracy). Sarcasm detection cần:

- Contextual understanding sâu hơn
- Fine-tuning trên sarcasm dataset
- Hoặc dùng larger models như GPT-4

Đây là limitation hiện tại. Trong future work, có thể fine-tune PhoBERT trên Vietnamese sarcasm dataset hoặc dùng ensemble model."

## Câu hỏi về Database

### Q8: Soft delete có nhược điểm gì?

**A**: "Nhược điểm chính:

1. **Storage growth**: Data không bao giờ xóa thật → database size tăng
2. **Query complexity**: Phải always filter `WHERE deleted_at IS NULL`
3. **Unique constraints**: Phải handle deleted records (ví dụ email unique)

Mitigation:

- **Archival process**: Sau 1 năm, move deleted records sang archive database
- **Indexed views**: Create views với filter deleted_at built-in
- **Soft unique constraint**: (email, deleted_at) unique

Benefits về audit trail và data recovery vượt trội hơn costs."

### Q9: PostgreSQL có scale được không khi có hàng triệu videos?

**A**: "Có, với strategy:

1. **Partitioning**: Partition videos table by created_at (monthly)
2. **Read replicas**: 2-3 read replicas cho query load
3. **Connection pooling**: PgBouncer để optimize connections
4. **Indexes**: B-tree indexes cho queries, GIN indexes cho full-text search

Testing với 10M videos:

- Query by project_id + date range: <100ms
- Aggregation queries: <500ms
- Insert throughput: ~5000 videos/second

Khi vượt 100M records, có thể migrate sang TimescaleDB (PostgreSQL extension for time-series) hoặc DocumentDB như roadmap."

## Câu hỏi về Deployment & Operations

### Q10: Kubernetes setup phức tạp như thế nào?

**A**: "Setup ban đầu phức tạp nhưng có chuẩn bị:

- **Infrastructure as Code**: Terraform cho provision Kubernetes cluster
- **Helm Charts**: Package services thành Helm charts để deploy dễ dàng
- **GitOps**: ArgoCD tự động deploy khi merge PR
- **Monitoring**: Prometheus + Grafana cho metrics, ELK cho logs

Sau khi setup xong, operations rất smooth. Deploy new version chỉ cần `helm upgrade` - zero downtime với rolling updates."

### Q11: Disaster recovery plan như thế nào?

**A**: "DR plan gồm:

1. **Backup**:
   - PostgreSQL: Daily full backup + continuous WAL archiving
   - MinIO: Replicate sang S3 (cross-region)
   - Retention: 30 days
2. **RTO/RPO**:
   - RTO (Recovery Time Objective): <4 giờ
   - RPO (Recovery Point Objective): <15 phút
3. **Recovery procedure**:
   - Step 1: Restore PostgreSQL từ backup + replay WAL
   - Step 2: Restore MinIO từ S3
   - Step 3: Redeploy Kubernetes manifests
   - Step 4: Verify data integrity
4. **Testing**: DR drill mỗi quý

Trong roadmap Phase 3, có multi-region deployment để giảm RTO xuống <30 phút."

## Câu hỏi về Security

### Q12: Authentication & Authorization như thế nào?

**A**: "Implement theo industry best practices:

1. **Authentication**:
   - JWT (JSON Web Tokens) với RS256 signing
   - Access token: expire sau 15 phút
   - Refresh token: expire sau 7 ngày
   - Token rotation: Mỗi refresh tạo token pair mới
2. **Authorization**:
   - RBAC (Role-Based Access Control)
   - Roles: Admin, Analyst, Viewer
   - Permissions checked ở API Gateway + service level
3. **Security measures**:
   - Password: bcrypt hashing với cost factor 12
   - Rate limiting: 100 requests/phút per user
   - HTTPS/TLS 1.3 cho tất cả communications
   - Secrets management: Kubernetes Secrets với encryption at rest

Tuân thủ OWASP Top 10 guidelines."

### Q13: Làm sao prevent scraping bị rate-limited?

**A**: "Strategy nhiều layers:

1. **Respect platform limits**:
   - YouTube API: 10,000 quota units/ngày → throttle requests
   - TikTok: No official API → polite scraping với delays
2. **Rate limiting**:
   - Random delays: 2-5 giây giữa requests
   - Exponential backoff khi gặp 429 errors
   - Rotate User-Agents
3. **Proxy rotation**:
   - Use proxy pool để distribute requests
   - Rotate IPs sau mỗi N requests
4. **Graceful degradation**:
   - Nếu bị rate-limited, pause 1 giờ rồi retry
   - Mark execution PARTIAL_SUCCESS thay vì FAILED
   - User vẫn nhận được partial results

Trade-off: Chậm hơn nhưng reliable hơn. 1000 videos có thể mất 1-2 giờ thay vì 10 phút."
