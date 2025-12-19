#import "../counters.typ": table_counter

= CHƯƠNG 3: CƠ SỞ LÝ THUYẾT

// Các nền tảng lý thuyết và công nghệ được sử dụng trong việc xây dựng hệ thống SMAP bao gồm các kiến trúc phần mềm hiện đại (Microservices, Clean Architecture), các công nghệ giao tiếp và xử lý dữ liệu (Message Queue, Real-time Communication, Database Technologies), cũng như các khía cạnh bảo mật (Authentication, Security) và các công nghệ cụ thể được áp dụng trong dự án.

== 3.1 Kiến Trúc Microservices

=== 3.1.1 Định nghĩa

Kiến trúc Microservices là một phong cách kiến trúc phần mềm (architectural style) trong đó một ứng dụng được xây dựng như một tập hợp các dịch vụ nhỏ, độc lập, mỗi dịch vụ chạy trong process riêng của nó và giao tiếp với nhau thông qua các cơ chế nhẹ như HTTP API hoặc Message Queue. Theo Martin Fowler, một trong những người tiên phong trong việc định nghĩa kiến trúc này, Microservices là cách tiếp cận để phát triển một ứng dụng đơn lẻ như một bộ các dịch vụ nhỏ, mỗi dịch vụ chạy trong process riêng và giao tiếp với các cơ chế nhẹ, thường là HTTP resource API.

Sam Newman, tác giả của cuốn "Building Microservices", mở rộng định nghĩa này bằng cách nhấn mạnh rằng Microservices là các dịch vụ có thể triển khai độc lập được tổ chức xung quanh các khả năng nghiệp vụ (business capabilities). Mỗi service sở hữu dữ liệu và logic nghiệp vụ của riêng nó, cho phép các team phát triển, triển khai và mở rộng các service một cách độc lập. Điều này tạo ra sự linh hoạt cao trong việc lựa chọn công nghệ và khả năng thích ứng nhanh với thay đổi của yêu cầu nghiệp vụ.

=== 3.1.2 Đặc điểm chính

==== Loosely Coupled (Liên kết lỏng lẻo)

Các Microservices được thiết kế để có mức độ liên kết thấp với nhau, nghĩa là thay đổi trong một service không yêu cầu thay đổi trong các service khác. Mỗi service có interface rõ ràng và giao tiếp thông qua các API được định nghĩa tốt. Điều này cho phép các team phát triển các service một cách độc lập mà không cần phối hợp chặt chẽ với các team khác. Loose coupling cũng giảm thiểu rủi ro khi thay đổi, vì một lỗi trong một service không lan truyền sang các service khác. Trong hệ thống SMAP, Identity Service có thể thay đổi cách lưu trữ thông tin người dùng mà không ảnh hưởng đến Project Service hay Collector Service.

==== Independently Deployable (Triển khai độc lập)

Một trong những lợi ích quan trọng nhất của Microservices là khả năng triển khai từng service một cách độc lập mà không cần triển khai lại toàn bộ hệ thống. Điều này cho phép các team phát triển và phát hành tính năng mới nhanh hơn, giảm thời gian downtime và rủi ro khi triển khai. Mỗi service có thể có chu kỳ phát hành riêng, cho phép các team làm việc với tốc độ khác nhau tùy theo nhu cầu nghiệp vụ. Continuous Deployment trở nên khả thi hơn khi chỉ cần triển khai các service đã thay đổi thay vì toàn bộ ứng dụng. Trong thực tế, nếu WebSocket Service cần cập nhật để cải thiện hiệu suất real-time notification, team có thể triển khai chỉ service này mà không ảnh hưởng đến các service khác đang chạy.

==== Organized Around Business Capabilities (Tổ chức theo khả năng nghiệp vụ)

Microservices được tổ chức xung quanh các khả năng nghiệp vụ thay vì các layer kỹ thuật. Mỗi service đại diện cho một domain nghiệp vụ cụ thể và sở hữu toàn bộ stack công nghệ cần thiết để thực hiện chức năng đó, từ giao diện người dùng đến cơ sở dữ liệu. Cách tiếp cận này phản ánh cấu trúc tổ chức của doanh nghiệp và cho phép các team cross-functional làm việc hiệu quả hơn. Trong hệ thống SMAP, Identity Service tập trung vào authentication và subscription management, Project Service quản lý projects và brand tracking, Collector Service xử lý task dispatching, và WebSocket Service cung cấp real-time notifications - mỗi service phản ánh một khả năng nghiệp vụ riêng biệt.

==== Decentralized Data Management (Quản lý dữ liệu phi tập trung)

Trong kiến trúc Microservices, mỗi service quản lý cơ sở dữ liệu riêng của nó, theo nguyên tắc "database per service". Điều này cho phép mỗi service chọn công nghệ database phù hợp nhất với nhu cầu của nó (polyglot persistence). Tuy nhiên, cách tiếp cận này cũng đặt ra thách thức về data consistency và distributed transactions. Thay vì sử dụng ACID transactions truyền thống, Microservices thường áp dụng eventual consistency và saga pattern để đảm bảo tính nhất quán dữ liệu. Trong SMAP, Identity Service sử dụng PostgreSQL cho dữ liệu có cấu trúc và quan hệ chặt chẽ, trong khi Collector Service sử dụng MongoDB cho dữ liệu crawl có schema linh hoạt, và WebSocket Service sử dụng Redis cho real-time messaging.

==== Infrastructure Automation (Tự động hóa hạ tầng)

Microservices đòi hỏi mức độ tự động hóa cao trong việc triển khai, giám sát và quản lý hạ tầng. Với số lượng lớn các service cần quản lý, việc thực hiện thủ công trở nên không khả thi. Các công cụ như Docker cho containerization, Kubernetes cho orchestration, và CI/CD pipelines cho automated deployment là thiết yếu. Infrastructure as Code (IaC) cho phép định nghĩa và quản lý hạ tầng thông qua code, đảm bảo tính nhất quán và khả năng tái tạo môi trường. Monitoring và logging tập trung cũng cần thiết để theo dõi health và performance của các service phân tán. Hệ thống SMAP sử dụng Docker để đóng gói các service và Kubernetes để orchestration, cho phép scaling tự động và self-healing khi có service bị lỗi.

=== 3.1.3 So sánh với Kiến trúc Monolithic
#pagebreak()
#context (align(center)[_Bảng #table_counter.display(): So sánh Microservices và Monolithic_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.5fr, 1.5fr),
    stroke: 0.5pt,
    align: (left, left, left),
    
    [*Tiêu chí*], [*Microservices*], [*Monolithic*],
    
    [Scalability], [Có thể mở rộng từng service độc lập theo nhu cầu cụ thể], [Phải mở rộng toàn bộ ứng dụng, lãng phí tài nguyên],
    
    [Deployment], [Triển khai từng service độc lập, giảm rủi ro], [Triển khai toàn bộ ứng dụng, downtime cao hơn],
    
    [Development], [Nhiều team có thể làm việc song song trên các service khác nhau], [Một codebase lớn, dễ xung đột code],
    
    [Debugging], [Phức tạp hơn do distributed tracing, cần công cụ chuyên dụng], [Đơn giản hơn, có thể gỡ lỗi trong một process],
    
    [Data Consistency], [Eventual consistency, cần xử lý distributed transactions], [Strong consistency với ACID transactions],
    
    [Infrastructure Cost], [Chi phí cao hơn do cần nhiều resources và công cụ quản lý], [Chi phí thấp hơn cho hệ thống nhỏ],
  )
]

==== Phân tích ưu nhược điểm

Kiến trúc Microservices mang lại nhiều lợi ích đáng kể cho các hệ thống lớn và phức tạp. Khả năng mở rộng độc lập cho phép tối ưu hóa tài nguyên - ví dụ, trong SMAP, Collector Service có thể mở rộng nhiều instances để xử lý lượng lớn crawl requests trong khi Identity Service chỉ cần vài instances do traffic thấp hơn. Việc triển khai độc lập giảm thiểu rủi ro và cho phép phát hành tính năng nhanh hơn. Fault isolation đảm bảo rằng lỗi trong một service không làm sập toàn bộ hệ thống. Technology diversity cho phép chọn công nghệ phù hợp nhất cho từng service - Go cho performance, Python cho data processing, Node.js cho real-time.

Tuy nhiên, Microservices cũng đi kèm với những thách thức đáng kể. Operational complexity tăng lên đáng kể khi phải quản lý nhiều service, database, và deployment pipeline. Network latency và reliability trở thành vấn đề khi các service giao tiếp qua network thay vì in-process calls. Distributed transactions và data consistency khó đảm bảo hơn, thường phải chấp nhận eventual consistency. Testing trở nên phức tạp hơn khi cần kiểm thử integration giữa nhiều service. Chi phí infrastructure và công cụ monitoring/logging cao hơn. Đối với các hệ thống nhỏ hoặc team nhỏ, những chi phí này có thể không xứng đáng với lợi ích mang lại.

Ngược lại, kiến trúc Monolithic phù hợp hơn cho các ứng dụng nhỏ, đơn giản với team nhỏ. Việc phát triển và gỡ lỗi đơn giản hơn khi tất cả code ở một nơi. Deployment đơn giản hơn với một artifact duy nhất. Data consistency dễ đảm bảo với ACID transactions. Chi phí infrastructure thấp hơn. Tuy nhiên, khi ứng dụng phát triển, Monolithic architecture sẽ gặp phải các vấn đề về scalability, deployment risk, và khó khăn trong việc bảo trì codebase lớn.

=== 3.1.4 Khi nào nên sử dụng Microservices

Microservices phù hợp nhất cho các tổ chức và dự án có những đặc điểm sau. Đầu tiên là các team lớn với nhiều developers - khi có nhiều team làm việc song song, Microservices cho phép họ làm việc độc lập mà không bị chặn lẫn nhau. Domain nghiệp vụ phức tạp với nhiều bounded contexts khác nhau cũng là dấu hiệu tốt cho Microservices, vì mỗi service có thể tập trung vào một domain cụ thể. Nhu cầu mở rộng độc lập các phần khác nhau của hệ thống là lý do quan trọng - ví dụ, trong SMAP, Collector Service cần mở rộng nhiều hơn Identity Service. Yêu cầu về high availability và fault tolerance cũng ủng hộ Microservices vì lỗi được cô lập trong từng service. Cuối cùng, nếu tổ chức đã có kinh nghiệm với DevOps, containerization, và cloud infrastructure, việc áp dụng Microservices sẽ dễ dàng hơn.

Ngược lại, Microservices không phù hợp trong một số trường hợp. Team nhỏ (dưới 10 người) thường không có đủ resources để quản lý complexity của Microservices. Các dự án MVP hoặc proof-of-concept nên bắt đầu với Monolithic để xác thực ý tưởng nhanh hơn. Domain nghiệp vụ đơn giản không có nhiều bounded contexts không cần sự phức tạp của Microservices. Nếu tổ chức chưa có kinh nghiệm với DevOps và cloud infrastructure, chi phí học tập và thiết lập có thể quá cao. Trong những trường hợp này, bắt đầu với Monolithic architecture và sau đó chuyển đổi sang Microservices khi cần thiết là chiến lược hợp lý hơn. Điều quan trọng là đánh giá trade-offs và chọn architecture phù hợp với context cụ thể của dự án và tổ chức.

== 3.2 Clean Architecture

=== 3.2.1 Nguyên tắc thiết kế

Clean Architecture là một phong cách kiến trúc phần mềm được đề xuất bởi Robert C. Martin (Uncle Bob) nhằm tạo ra các hệ thống dễ hiểu, linh hoạt và bảo trì. Ý tưởng cốt lõi của Clean Architecture là tách biệt các concerns khác nhau trong ứng dụng thành các layer riêng biệt, với nguyên tắc dependency chỉ trỏ vào trong (inward). Kiến trúc này đảm bảo rằng business logic (phần quan trọng nhất của ứng dụng) không phụ thuộc vào các chi tiết triển khai như framework, database, hay UI.

Theo Robert C. Martin, một kiến trúc tốt phải đạt được các mục tiêu sau: độc lập với frameworks (independent of frameworks), có khả năng kiểm thử cao (testable), độc lập với UI (independent of UI), độc lập với database (independent of database), và độc lập với bất kỳ external agency nào. Điều này có nghĩa là business rules không nên biết gì về thế giới bên ngoài - chúng không quan tâm dữ liệu được lưu ở đâu, UI được hiển thị như thế nào, hay framework nào đang được sử dụng. Sự độc lập này cho phép thay đổi các chi tiết triển khai mà không ảnh hưởng đến core business logic.

Testability là một trong những lợi ích quan trọng nhất của Clean Architecture. Vì business logic không phụ thuộc vào external dependencies, nó có thể được kiểm thử một cách độc lập mà không cần giả lập database, web server, hay bất kỳ external service nào. Unit tests có thể chạy nhanh và đáng tin cậy vì chúng chỉ kiểm thử pure business logic. Integration tests cũng dễ viết hơn vì các boundaries giữa các layer được định nghĩa rõ ràng. Trong hệ thống SMAP, use cases của Identity Service có thể được kiểm thử mà không cần khởi động PostgreSQL hay RabbitMQ thật.

Sự độc lập với frameworks và external agencies mang lại tính linh hoạt lớn. Nếu muốn chuyển từ Gin sang Echo framework, chỉ cần thay đổi delivery layer mà không động đến business logic. Nếu muốn chuyển đổi từ PostgreSQL sang MySQL, chỉ cần triển khai repository interface mới. Nếu muốn thêm gRPC endpoint bên cạnh REST API, chỉ cần thêm một delivery layer mới. Business logic vẫn giữ nguyên trong tất cả các trường hợp này, giảm thiểu rủi ro và công sức khi thay đổi.

=== 3.2.2 Các Layer và Dependency Rule

Clean Architecture tổ chức code thành các layer đồng tâm, với business logic ở trung tâm và các chi tiết triển khai ở bên ngoài. Có bốn layer chính: Entities, Use Cases, Interface Adapters, và Frameworks & Drivers.

==== Entities (Domain Models)

Entities là layer trong cùng, chứa các business rules quan trọng nhất và ổn định nhất của ứng dụng. Đây là các domain models đại diện cho các khái niệm nghiệp vụ cốt lõi. Entities không phụ thuộc vào bất kỳ layer nào khác và không biết gì về use cases, controllers, hay databases. Chúng chỉ chứa business logic thuần túy - các rules mà sẽ tồn tại ngay cả khi không có ứng dụng. Trong SMAP, User entity có thể chứa logic xác thực email format, Subscription entity có thể chứa logic tính toán trial period, Project entity có thể chứa logic xác thực date range. Những rules này là bất biến bất kể ứng dụng được triển khai như thế nào.

==== Use Cases (Business Logic)

Use Cases layer chứa application-specific business rules - các rules mô tả cách ứng dụng sử dụng entities để đạt được mục tiêu cụ thể. Mỗi use case đại diện cho một chức năng nghiệp vụ cụ thể như "Register User", "Create Project", "Dispatch Crawl Task". Use cases điều phối flow của dữ liệu đến và từ entities, và chỉ đạo entities thực hiện business rules của chúng. Use cases không biết gì về UI, database, hay external services - chúng chỉ định nghĩa interfaces (ports) mà các layer bên ngoài phải triển khai. Trong Identity Service của SMAP, RegisterUserUseCase điều phối việc xác thực input, băm password, lưu user vào database, và gửi OTP email, nhưng nó không biết PostgreSQL hay RabbitMQ được sử dụng như thế nào.

==== Interface Adapters (Controllers, Presenters, Gateways)

Interface Adapters layer chịu trách nhiệm chuyển đổi dữ liệu giữa format phù hợp với use cases và format phù hợp với external agencies như database hay web. Layer này bao gồm controllers (nhận HTTP requests và gọi use cases), presenters (định dạng dữ liệu để trả về cho UI), và gateways/repositories (triển khai interfaces được định nghĩa bởi use cases để truy cập database). Đây là nơi dependency inversion xảy ra - use cases định nghĩa interfaces, và adapters triển khai chúng. Trong SMAP, HTTP handlers phân tích cú pháp JSON requests, gọi use cases với domain models, và định dạng responses. Repositories triển khai data access interfaces được định nghĩa bởi use cases, sử dụng SQLBoiler để tương tác với PostgreSQL.

==== Frameworks & Drivers (External Services)

Layer ngoài cùng chứa các frameworks và tools như database, web framework, external APIs. Đây là nơi tất cả các chi tiết triển khai cụ thể nằm. Code trong layer này thường rất ít vì phần lớn công việc được thực hiện bởi third-party libraries. Layer này giao tiếp với Interface Adapters layer để tích hợp với phần còn lại của ứng dụng. Trong SMAP, đây là nơi có Gin framework setup, PostgreSQL connection, RabbitMQ client, Redis client. Những thành phần này có thể thay đổi mà không ảnh hưởng đến business logic.

==== Dependency Rule

Nguyên tắc quan trọng nhất của Clean Architecture là Dependency Rule: source code dependencies chỉ được trỏ vào trong (inward). Code ở layer trong không được biết gì về code ở layer ngoài. Entities không biết gì về Use Cases. Use Cases không biết gì về Controllers hay Databases. Điều này đạt được thông qua dependency inversion - layer trong định nghĩa interfaces, layer ngoài triển khai chúng. Khi use case cần truy cập database, nó định nghĩa một repository interface. Repository implementation ở layer ngoài triển khai interface đó. Dependency trỏ vào trong (use case → interface) chứ không phải ra ngoài (use case → concrete repository).

=== 3.2.3 So sánh với MVC và Hexagonal Architecture

#context (align(center)[_Bảng #table_counter.display(): So sánh Clean Architecture, MVC và Hexagonal Architecture_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    
    [*Tiêu chí*], [*Clean Architecture*], [*MVC*], [*Hexagonal Architecture*],
    
    [Testability], [Rất cao, business logic hoàn toàn độc lập], [Trung bình, business logic thường lẫn với controller], [Rất cao, tương tự Clean Architecture],
    
    [Complexity], [Cao, nhiều layers và abstractions], [Thấp, cấu trúc đơn giản], [Trung bình, ít layers hơn Clean Architecture],
    
    [Learning Curve], [Dốc, cần hiểu dependency inversion], [Thoải, pattern phổ biến], [Trung bình, concepts dễ hiểu hơn],
    
    [Flexibility], [Rất cao, dễ thay đổi triển khai], [Thấp, tight coupling với framework], [Cao, ports & adapters dễ thay đổi],
    
    [Boilerplate], [Nhiều, cần nhiều interfaces và abstractions], [Ít, code ngắn gọn hơn], [Trung bình, cần ports & adapters],
  )
]

==== Phân tích Trade-offs

Clean Architecture và Hexagonal Architecture (Ports & Adapters) có nhiều điểm tương đồng - cả hai đều nhấn mạnh việc tách biệt business logic khỏi external concerns thông qua abstractions. Sự khác biệt chính là Clean Architecture có cấu trúc layers rõ ràng hơn với sự phân biệt giữa Entities và Use Cases, trong khi Hexagonal Architecture tập trung vào khái niệm ports (interfaces) và adapters (implementations). Clean Architecture có thể được xem như một sự tiến hóa của Hexagonal Architecture với structure rõ ràng hơn. Trong thực tế, nhiều hệ thống kết hợp ý tưởng từ cả hai patterns.

So với MVC (Model-View-Controller), Clean Architecture phức tạp hơn đáng kể nhưng mang lại testability và flexibility cao hơn nhiều. MVC phù hợp cho các ứng dụng nhỏ, đơn giản nơi business logic không phức tạp và không cần test coverage cao. Tuy nhiên, khi ứng dụng phát triển, MVC thường dẫn đến "fat controllers" chứa cả business logic lẫn presentation logic, khó kiểm thử và bảo trì. Clean Architecture giải quyết vấn đề này bằng cách tách biệt rõ ràng các concerns, nhưng đổi lại phải chấp nhận boilerplate code nhiều hơn.

Trade-off chính khi chọn Clean Architecture là giữa simplicity và long-term maintainability. Với các dự án nhỏ, MVP, hoặc prototypes, overhead của Clean Architecture có thể không xứng đáng. Tuy nhiên, với các hệ thống lớn, phức tạp, có nhiều developers, và cần bảo trì trong thời gian dài, đầu tư vào Clean Architecture sẽ mang lại lợi ích thông qua testability cao hơn, flexibility trong việc thay đổi triển khai, và khả năng onboard developers mới dễ dàng hơn nhờ structure rõ ràng.


== 3.3 Message Queue và Event-Driven Architecture

=== 3.3.1 Giới thiệu Message Queue

Message Queue là một cơ chế giao tiếp bất đồng bộ (asynchronous communication) cho phép các thành phần trong hệ thống phân tán trao đổi thông tin mà không cần kết nối trực tiếp với nhau. Trong mô hình này, producer (người gửi) đưa messages vào queue, và consumer (người nhận) lấy messages ra khỏi queue để xử lý. Queue đóng vai trò như một bộ đệm trung gian, lưu trữ messages cho đến khi consumer sẵn sàng xử lý. Điều này tạo ra sự tách biệt về thời gian (temporal decoupling) - producer và consumer không cần online cùng lúc, và tách biệt về không gian (spatial decoupling) - chúng không cần biết địa chỉ của nhau.

Message Queue mang lại nhiều lợi ích quan trọng cho hệ thống phân tán. Asynchronous processing cho phép producer tiếp tục công việc ngay sau khi gửi message mà không cần chờ consumer xử lý xong, cải thiện response time và throughput. Load leveling giúp hệ thống xử lý được traffic spikes - khi có nhiều requests đột ngột, messages được xếp hàng lại và xử lý dần thay vì làm quá tải consumers. Reliability được cải thiện thông qua message persistence và retry mechanisms - nếu consumer thất bại, message vẫn được giữ trong queue để xử lý lại. Scalability trở nên dễ dàng hơn khi có thể thêm nhiều consumers để xử lý messages song song. Trong hệ thống SMAP, Message Queue được sử dụng để xử lý email sending bất đồng bộ và phân phối crawl tasks đến workers.

=== 3.3.2 RabbitMQ

RabbitMQ là một message broker mã nguồn mở phổ biến, triển khai AMQP (Advanced Message Queuing Protocol) - một protocol chuẩn cho message-oriented middleware. RabbitMQ đóng vai trò trung gian giữa producers và consumers, nhận messages từ producers, định tuyến chúng đến đúng queues, và gửi đến consumers. RabbitMQ hỗ trợ nhiều messaging patterns khác nhau thông qua các loại exchanges, đảm bảo message delivery thông qua acknowledgments, và cung cấp persistence để không mất messages khi broker khởi động lại.

Architecture của RabbitMQ bao gồm các thành phần chính sau. Exchanges nhận messages từ producers và định tuyến chúng đến queues dựa trên routing rules. Queues lưu trữ messages cho đến khi consumers tiêu thụ chúng. Bindings định nghĩa relationships giữa exchanges và queues, xác định messages nào được định tuyến đến queue nào. Routing keys là attributes của messages được exchanges sử dụng để quyết định routing. Channels là virtual connections trong một TCP connection, cho phép multiplexing nhiều operations trên một connection.

RabbitMQ hỗ trợ bốn loại exchanges chính, mỗi loại có routing behavior khác nhau. Fanout exchange phát sóng messages đến tất cả queues được gắn kết với nó, bỏ qua routing key, phù hợp cho pub/sub pattern. Direct exchange định tuyến messages đến queues có binding key khớp chính xác với routing key của message, phù hợp cho unicast messaging. Topic exchange định tuyến messages dựa trên pattern matching giữa routing key và binding pattern, hỗ trợ wildcards (\* và \#), phù hợp cho selective multicast. Headers exchange định tuyến dựa trên message headers thay vì routing key, ít được sử dụng hơn nhưng linh hoạt hơn. Trong SMAP, fanout exchange được sử dụng để phát sóng crawl requests đến multiple platform queues.

Message acknowledgment là cơ chế quan trọng đảm bảo reliability. Khi consumer nhận message, nó phải gửi acknowledgment (ack) về RabbitMQ để xác nhận rằng message đã được xử lý thành công. Chỉ khi nhận được ack, RabbitMQ mới xóa message khỏi queue. Nếu consumer thất bại trước khi gửi ack (connection lost, process crashed), RabbitMQ sẽ gửi lại message đến consumer khác. Điều này đảm bảo at-least-once delivery, message sẽ được gửi ít nhất một lần, có thể nhiều hơn nếu có failures. Consumer cần triển khai idempotent processing để xử lý duplicate messages. RabbitMQ cũng hỗ trợ negative acknowledgment (nack) để từ chối messages và optional requeue.

=== 3.3.3 Producer-Consumer Pattern

Producer-Consumer pattern là một messaging pattern cơ bản trong đó producers tạo ra messages và đưa vào queue, consumers lấy messages ra và xử lý. Pattern này tạo ra decoupling hoàn toàn giữa producers và consumers, chúng không cần biết về sự tồn tại của nhau, chỉ cần biết về queue. Producers có thể tạo messages với tốc độ của chúng, consumers có thể tiêu thụ với tốc độ của chúng, và queue đệm sự chênh lệch. Điều này cho phép producers và consumers mở rộng độc lập, có thể có nhiều producers gửi vào cùng một queue, và nhiều consumers xử lý messages từ queue đó song song.

Load balancing là một lợi ích quan trọng của Producer-Consumer pattern. Khi có nhiều consumers cùng tiêu thụ từ một queue, RabbitMQ phân phối messages giữa chúng theo round-robin fashion (mặc định). Điều này cho phép horizontal scaling, khi workload tăng, chỉ cần thêm consumers. Nếu một consumer chậm hoặc bận, messages sẽ được định tuyến đến consumers khác. Prefetch count có thể được cấu hình để kiểm soát số lượng unacknowledged messages mỗi consumer có thể có, đảm bảo fair distribution. Trong SMAP, nhiều crawler workers có thể tiêu thụ từ cùng một platform queue, tự động cân bằng tải crawl tasks.

Reliability và retry mechanisms là features quan trọng khác. Nếu consumer thất bại khi xử lý message, message sẽ được xếp hàng lại và gửi đến consumer khác. Dead Letter Exchanges (DLX) có thể được cấu hình để xử lý messages không thể xử lý sau nhiều lần thử lại - những messages này được định tuyến đến một queue đặc biệt để điều tra. Message TTL (Time To Live) có thể được thiết lập để tự động hết hạn messages cũ. Queue length limits có thể được thiết lập để ngăn chặn memory overflow. Những mechanisms này đảm bảo hệ thống mạnh mẽ và có thể phục hồi từ failures.

=== 3.3.4 Pub/Sub Pattern

Publish/Subscribe (Pub/Sub) pattern là một messaging pattern trong đó publishers phát sóng messages đến nhiều subscribers quan tâm. Khác với Producer-Consumer pattern (một message được tiêu thụ bởi một consumer), trong Pub/Sub pattern, một message được gửi đến tất cả subscribers. Publishers không biết có bao nhiêu subscribers hay subscribers là ai. Subscribers không biết publishers là ai. Sự decoupling này cho phép thêm subscribers mới mà không cần thay đổi publishers.

Trong RabbitMQ, Pub/Sub pattern được triển khai bằng fanout exchange. Publisher gửi message đến fanout exchange. Exchange phát sóng message đến tất cả queues được gắn kết với nó. Mỗi subscriber có queue riêng được gắn kết với exchange. Khi message đến exchange, nó được sao chép và gửi đến tất cả queues. Mỗi subscriber nhận một bản sao của message và xử lý độc lập. Trong SMAP, khi Identity Service cần gửi email, nó xuất bản message đến email exchange, và email worker tiêu thụ message để gửi email thực tế.

Pub/Sub pattern là nền tảng của Event-Driven Architecture (EDA), trong đó các thành phần giao tiếp thông qua events. Khi một sự kiện xảy ra (ví dụ: user registered, order placed, payment completed), service xuất bản một event. Các services khác quan tâm đến event đó đăng ký và phản ứng accordingly. Điều này tạo ra loose coupling cao, services không cần biết về nhau, chỉ cần biết về events. Thêm features mới trở nên dễ dàng, chỉ cần thêm subscriber mới cho events hiện có. EDA cho phép xây dựng reactive systems có khả năng phản hồi nhanh với changes và mở rộng tốt.

=== 3.3.5 So sánh Message Brokers

#context (align(center)[_Bảng #table_counter.display(): So sánh các Message Brokers_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    
    [*Tiêu chí*], [*RabbitMQ*], [*Apache Kafka*], [*Redis Streams*],
    
    [Throughput], [Trung bình (10K-20K msg/s)], [Rất cao (100K-1M msg/s)], [Cao (50K-100K msg/s)],
    
    [Latency], [Thấp (~10ms)], [Trung bình (~50ms)], [Rất thấp (~1ms)],
    
    [Persistence], [Có, durable queues], [Có, log-based storage], [Có, append-only log],
    
    [Ordering], [Per-queue ordering], [Per-partition ordering], [Per-stream ordering],
    
    [Use Cases], [Task queues, RPC, routing], [Event streaming, log aggregation], [Real-time analytics, caching],
  )
]

==== Phân tích lựa chọn

RabbitMQ phù hợp cho traditional message queuing use cases như task queues, request-response patterns, và complex routing scenarios. Nó cung cấp flexible routing thông qua exchanges, strong delivery guarantees thông qua acknowledgments, và hệ sinh thái trưởng thành với nhiều client libraries. RabbitMQ là lựa chọn tốt khi cần routing logic phức tạp, priority queues, hoặc message TTL. Trong SMAP, RabbitMQ được chọn vì nhu cầu fan-out routing (một crawl request cần được phân phối đến nhiều platform queues) và task queue semantics (mỗi task được xử lý bởi một worker).

Apache Kafka được thiết kế cho high-throughput event streaming và log aggregation. Nó có thể xử lý millions of messages per second và giữ lại messages trong thời gian dài (days, weeks). Kafka phù hợp cho event sourcing, stream processing, và scenarios cần phát lại messages. Tuy nhiên, Kafka có operational complexity cao hơn và latency cao hơn RabbitMQ. Kafka là thừa thãi cho simple task queues nhưng xuất sắc cho event-driven architectures ở quy mô lớn.

Redis Streams là giải pháp thay thế nhẹ cho message streaming, tích hợp sẵn trong Redis. Nó có latency rất thấp và throughput cao, phù hợp cho real-time use cases. Tuy nhiên, Redis Streams không có routing capabilities phức tạp như RabbitMQ và không được thiết kế cho long-term message retention như Kafka. Redis Streams phù hợp cho simple pub/sub scenarios, real-time analytics, và caching use cases. Trong SMAP, Redis được sử dụng cho Pub/Sub real-time notifications chứ không phải task queuing, vì latency là ưu tiên hơn reliability.


== 3.4 Real-time Communication

=== 3.4.1 WebSocket Protocol

WebSocket là một communication protocol cung cấp full-duplex communication channels qua một TCP connection duy nhất. Khác với HTTP truyền thống (request-response model), WebSocket cho phép server đẩy data đến client bất cứ lúc nào mà không cần client yêu cầu. Điều này làm cho WebSocket lý tưởng cho các ứng dụng real-time như chat, notifications, live updates, và collaborative editing. WebSocket được chuẩn hóa bởi IETF as RFC 6455 và được hỗ trợ rộng rãi bởi tất cả modern browsers.

Full-duplex communication có nghĩa là cả client và server đều có thể gửi messages độc lập với nhau cùng một lúc. Không giống như HTTP polling nơi client phải liên tục gửi requests để kiểm tra updates, với WebSocket, server có thể đẩy updates ngay khi có data mới. Điều này giảm latency đáng kể và giảm overhead của việc thiết lập connections liên tục. Một khi WebSocket connection được thiết lập, nó được giữ mở (persistent connection) cho đến khi một trong hai bên đóng nó, cho phép bidirectional communication với minimal overhead.

WebSocket handshake process bắt đầu với một HTTP request đặc biệt từ client. Client gửi HTTP GET request với headers đặc biệt: `Upgrade: websocket` và `Connection: Upgrade`, cùng với `Sec-WebSocket-Key` để security. Nếu server hỗ trợ WebSocket, nó phản hồi với status code 101 (Switching Protocols) và headers tương ứng. Sau handshake thành công, connection được nâng cấp từ HTTP sang WebSocket protocol, và cả hai bên có thể bắt đầu gửi WebSocket frames. Frames là đơn vị data nhỏ nhất trong WebSocket, có thể chứa text hoặc binary data, và có overhead rất thấp (chỉ 2-14 bytes per frame).

Low latency là một trong những ưu điểm lớn nhất của WebSocket. Vì connection được giữ mở, không có overhead của TCP handshake và HTTP headers cho mỗi message. Messages được gửi ngay lập tức khi có data, không cần polling. Trong thực tế, WebSocket có thể đạt latency dưới 10ms trong local network và 50-100ms qua internet, phụ thuộc vào network conditions. Điều này làm cho WebSocket phù hợp cho các ứng dụng yêu cầu instant updates như gaming, trading platforms, và real-time collaboration tools. Trong hệ thống SMAP, WebSocket được sử dụng để đẩy crawl completion notifications đến users ngay lập tức.

Browser support cho WebSocket là xuất sắc - tất cả modern browsers (Chrome, Firefox, Safari, Edge) đều hỗ trợ WebSocket API. JavaScript WebSocket API rất đơn giản: `new WebSocket(url)` để tạo connection, `send()` để gửi messages, và event listeners (`onopen`, `onmessage`, `onerror`, `onclose`) để xử lý events. Điều này làm cho WebSocket dễ tích hợp vào web applications. Tuy nhiên, cần xử lý reconnection logic khi connection drops, triển khai heartbeat/ping-pong để phát hiện dead connections, và xử lý backpressure khi messages arrive faster than they can be processed.

=== 3.4.2 Redis Pub/Sub

Redis Pub/Sub là một messaging system được tích hợp sẵn trong Redis, cho phép publishers gửi messages đến channels và subscribers nhận messages từ channels họ đăng ký. Redis Pub/Sub hoạt động hoàn toàn in-memory, không có persistence, và sử dụng fire-and-forget semantics - messages được gửi đến subscribers đang online, nếu không có subscriber nào, message bị loại bỏ. Điều này làm cho Redis Pub/Sub rất nhanh nhưng không đáng tin cậy như message queues truyền thống.

In-memory messaging là lý do Redis Pub/Sub có latency cực thấp. Vì tất cả operations diễn ra trong RAM và không có disk I/O, messages được gửi trong microseconds. Redis có thể xử lý hàng triệu messages per second trên hardware thông thường. Điều này làm cho Redis Pub/Sub lý tưởng cho use cases cần latency thấp nhất có thể, như real-time notifications, live dashboards, và chat applications. Trong SMAP, Redis Pub/Sub được sử dụng để phát sóng notifications từ crawler workers đến WebSocket service với latency ~1ms.

Pattern subscriptions là một feature mạnh mẽ của Redis Pub/Sub. Thay vì đăng ký đến một channel cụ thể, subscribers có thể đăng ký đến một pattern sử dụng wildcards. Ví dụ, `PSUBSCRIBE user_noti:*` sẽ đăng ký đến tất cả channels bắt đầu với `user_noti:`, như `user_noti:user123`, `user_noti:user456`, etc. Điều này cho phép flexible routing mà không cần tạo nhiều subscriptions. Trong SMAP, WebSocket service đăng ký đến pattern `user_noti:*` và trích xuất user ID từ channel name để định tuyến message đến đúng WebSocket connection.

Fire-and-forget semantics có nghĩa là Redis không đảm bảo message delivery. Nếu không có subscriber nào đang lắng nghe channel khi message được xuất bản, message bị mất. Nếu subscriber đang xử lý message và crash, message cũng bị mất. Redis không có message persistence, acknowledgments, hay retry mechanisms. Điều này là trade-off cho performance - bằng cách bỏ qua reliability guarantees, Redis đạt được latency rất thấp (~1ms). Use cases phù hợp là những scenarios mà mất occasional messages là chấp nhận được, như real-time notifications (user có thể làm mới để lấy updates) hay live metrics (next update sẽ đến soon).

=== 3.4.3 So sánh Real-time Protocols

#context (align(center)[_Bảng #table_counter.display(): So sánh các Real-time Protocols_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.2fr, 1.2fr, 1.2fr, 1.2fr),
    stroke: 0.5pt,
    align: (left, center, center, center, center),
    
    [*Tiêu chí*], [*WebSocket*], [*Server-Sent Events*], [*Long Polling*], [*gRPC Streaming*],
    
    [Latency], [Rất thấp (~10ms)], [Thấp (~20ms)], [Cao (~100ms+)], [Rất thấp (~10ms)],
    
    [Browser Support], [Xuất sắc (all modern)], [Tốt (no IE)], [Phổ quát], [Yêu cầu library],
    
    [Complexity], [Trung bình], [Thấp], [Thấp], [Cao],
    
    [Bi-directional], [Có (full-duplex)], [Không (server→client only)], [Có (mô phỏng)], [Có (full-duplex)],
  )
]

==== Phân tích lựa chọn protocols

WebSocket là lựa chọn tốt nhất cho true bidirectional real-time communication. Nó có latency thấp, overhead thấp, và được hỗ trợ rộng rãi. WebSocket phù hợp cho chat applications, collaborative editing, gaming, và bất kỳ use case nào cần client và server gửi messages cho nhau thường xuyên. Tuy nhiên, WebSocket có complexity cao hơn - cần xử lý connection management, reconnection logic, và heartbeats. WebSocket cũng có thể gặp vấn đề với firewalls và proxies không hỗ trợ protocol upgrade.

Server-Sent Events (SSE) là một giải pháp thay thế đơn giản hơn cho scenarios chỉ cần server đẩy data đến client (unidirectional). SSE sử dụng regular HTTP connection và được tích hợp sẵn trong browsers qua EventSource API. SSE tự động kết nối lại khi connection drops và có built-in event IDs cho message ordering. Tuy nhiên, SSE không hỗ trợ binary data và không có bidirectional communication. SSE phù hợp cho live feeds, notifications, và progress updates.

Long Polling là technique cũ hơn, mô phỏng real-time bằng cách client gửi HTTP request và server giữ request mở cho đến khi có data hoặc timeout. Khi response được gửi, client ngay lập tức gửi request mới. Long Polling có latency cao hơn và overhead lớn hơn do phải thiết lập HTTP connections liên tục. Tuy nhiên, nó hoạt động với bất kỳ HTTP infrastructure nào và không có compatibility issues. Long Polling phù hợp khi WebSocket không khả dụng hoặc như fallback mechanism.

gRPC Streaming cung cấp bidirectional streaming qua HTTP/2. Nó có performance tương đương WebSocket và hỗ trợ strongly-typed messages thông qua Protocol Buffers. gRPC phù hợp cho service-to-service communication trong microservices architectures. Tuy nhiên, browser support yêu cầu gRPC-Web proxy và complexity cao hơn WebSocket. gRPC Streaming là lựa chọn xuất sắc cho backend services nhưng WebSocket vẫn tốt hơn cho browser clients.


== 3.5 Database Technologies

=== 3.5.1 PostgreSQL

PostgreSQL là một relational database management system (RDBMS) mã nguồn mở, được biết đến với độ tin cậy cao, tính năng phong phú, và tuân thủ chuẩn SQL. PostgreSQL được phát triển từ năm 1986 tại University of California, Berkeley, và đã trở thành một trong những database systems phổ biến nhất cho enterprise applications. PostgreSQL hỗ trợ cả SQL (relational) và JSON (non-relational) querying, làm cho nó trở thành một "object-relational database" linh hoạt.

ACID compliance là một trong những điểm mạnh quan trọng nhất của PostgreSQL. ACID là viết tắt của Atomicity (transactions hoàn thành hoàn toàn hoặc không hoàn thành gì cả), Consistency (database luôn ở trạng thái hợp lệ), Isolation (concurrent transactions không ảnh hưởng lẫn nhau), và Durability (committed data không bị mất ngay cả khi system crash). ACID guarantees đảm bảo data integrity và reliability, đặc biệt quan trọng cho financial applications, e-commerce, và bất kỳ system nào cần strong consistency. PostgreSQL triển khai ACID thông qua Multi-Version Concurrency Control (MVCC), cho phép high concurrency mà không cần locking.

JSONB support là một feature độc đáo làm cho PostgreSQL linh hoạt hơn traditional relational databases. JSONB là binary JSON format được PostgreSQL lưu trữ hiệu quả và hỗ trợ indexing. Điều này cho phép lưu trữ semi-structured data trong relational database mà vẫn có thể truy vấn hiệu quả. JSONB hỗ trợ operators đặc biệt như `->`, `->>`, `@>`, `?` để truy vấn JSON data. GIN (Generalized Inverted Index) có thể được tạo trên JSONB columns để tăng tốc queries. Trong SMAP, Project Service sử dụng JSONB để lưu trữ `competitor_keywords_map` - một structure linh hoạt có thể chứa keywords cho nhiều competitors khác nhau mà không cần schema cố định.

=== 3.5.2 MongoDB

MongoDB là một document-oriented NoSQL database, lưu trữ data dưới dạng JSON-like documents (BSON - Binary JSON) thay vì rows và columns như relational databases. MongoDB được thiết kế cho scalability, flexibility, và performance với semi-structured data. Mỗi document có thể có structure khác nhau, cho phép schema evolution dễ dàng mà không cần migrations. MongoDB được phát hành năm 2009 và đã trở thành một trong những NoSQL databases phổ biến nhất.

Flexible schema là một trong những lợi ích lớn nhất của MongoDB. Không giống như relational databases yêu cầu định nghĩa schema trước, MongoDB cho phép chèn documents với structures khác nhau vào cùng một collection. Điều này rất hữu ích khi data structure không cố định hoặc phát triển theo thời gian. Ví dụ, trong SMAP, crawl results từ YouTube có structure khác với TikTok - YouTube có view count, TikTok có play count. Với MongoDB, cả hai có thể được lưu trong cùng collection mà không cần nullable columns hay separate tables.

=== 3.5.3 Redis

Redis (Remote Dictionary Server) là một in-memory data structure store được sử dụng như database, cache, và message broker. Redis lưu trữ tất cả data trong RAM, cho phép extremely fast read và write operations với latency sub-millisecond. Redis hỗ trợ nhiều data structures như strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs, và geospatial indexes. Redis được phát hành năm 2009 và đã trở thành de facto standard cho caching và real-time applications.

=== 3.5.4 Polyglot Persistence

Polyglot Persistence là architectural approach sử dụng nhiều database technologies khác nhau trong cùng một application, mỗi database được chọn dựa trên use case cụ thể. Thay vì sử dụng một database cho tất cả data, polyglot persistence chọn "right tool for the job" - relational database cho structured data, document database cho flexible schema, key-value store cho caching. Approach này tối ưu hóa performance, scalability, và developer productivity bằng cách tận dụng strengths của mỗi database type.

#context (align(center)[_Bảng #table_counter.display(): So sánh các Database Technologies_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    
    [*Tiêu chí*], [*PostgreSQL*], [*MongoDB*], [*Redis*],
    
    [Data Model], [Relational (tables, rows)], [Document (JSON-like)], [Key-Value, Data Structures],
    
    [Consistency], [Mạnh (ACID)], [Eventual (có thể điều chỉnh)], [Eventual (in-memory)],
    
    [Scalability], [Vertical + Read Replicas], [Horizontal (Sharding)], [Horizontal (Clustering)],
    
    [Performance], [Tốt (disk-based)], [Rất tốt (disk-based)], [Xuất sắc (in-memory)],
    
    [Use Cases], [Structured data, transactions], [Semi-structured, flexible schema], [Caching, real-time, sessions],
  )
]

Trong SMAP, polyglot persistence được chọn vì benefits vượt trội costs. Hệ thống có clear bounded contexts (Identity, Project, Collector, WebSocket) với data requirements khác nhau. Team có expertise cần thiết. Microservices architecture đã có operational complexity, thêm multiple databases không tăng complexity quá nhiều.


== 3.6 Authentication và Security

=== 3.6.1 JWT (JSON Web Token)

JSON Web Token (JWT) là một open standard (RFC 7519) định nghĩa một cách compact và self-contained để truyền thông tin an toàn giữa các parties dưới dạng JSON object. JWT được sử dụng rộng rãi cho authentication và information exchange trong web applications và APIs. Một trong những lợi ích chính của JWT là stateless authentication - server không cần lưu trữ session data, tất cả thông tin cần thiết được mã hóa trong token itself.

JWT bao gồm ba phần được phân tách bởi dấu chấm (.): Header, Payload, và Signature. *Header* chứa metadata về token, thường bao gồm type (JWT) và signing algorithm (HS256, RS256, etc.). *Payload* chứa claims - các statements về entity (thường là user) và additional metadata. *Signature* được tạo bằng cách mã hóa header và payload, sau đó ký với secret key sử dụng algorithm specified trong header.

=== 3.6.2 HttpOnly Cookie

HttpOnly Cookie là một cookie attribute được thiết lập bởi server để ngăn chặn client-side scripts từ việc truy cập cookie. Khi cookie có HttpOnly flag, JavaScript code không thể đọc cookie value thông qua `document.cookie`. Điều này là một security measure quan trọng để bảo vệ against Cross-Site Scripting (XSS) attacks. HttpOnly cookies thường được sử dụng để lưu trữ authentication tokens như JWT, session IDs, và sensitive data khác.

Cookies có nhiều attributes kiểm soát behavior và security của chúng. HttpOnly ngăn chặn JavaScript access, bảo vệ against XSS. Secure đảm bảo cookie chỉ được gửi qua HTTPS connections, bảo vệ against man-in-the-middle attacks. SameSite kiểm soát khi nào cookie được gửi với cross-site requests, có ba values: Strict (never sent with cross-site requests), Lax (sent with top-level navigations), và None (always sent, requires Secure).

=== 3.6.3 Password Hashing

Password hashing là process chuyển đổi plaintext password thành một fixed-size string (hash) sử dụng one-way cryptographic function. Hash functions được thiết kế để không thể đảo ngược - không thể suy ra original password từ hash. Khi user đăng ký, password được băm và hash được lưu trong database. Khi user đăng nhập, input password được băm và so sánh với stored hash.

bcrypt là một password hashing algorithm được thiết kế đặc biệt cho password storage. bcrypt có nhiều properties làm cho nó an toàn: chậm by design (computationally expensive), adaptive (cost factor có thể tăng theo thời gian), và tự động tạo và bao gồm salt. bcrypt được coi là industry standard cho password hashing và được khuyến nghị bởi OWASP (Open Web Application Security Project).

#context (align(center)[_Bảng #table_counter.display(): So sánh các Password Hashing Algorithms_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.2fr, 1.2fr, 1.2fr, 1.5fr),
    stroke: 0.5pt,
    align: (center, center, center, center, left),
    
    [*Algorithm*], [*Security*], [*Performance*], [*Memory Usage*], [*Notes*],
    
    [bcrypt], [Rất cao], [Chậm (by design)], [Thấp], [Industry standard, adaptive cost],
    
    [Argon2], [Rất cao], [Chậm], [Cao (có thể cấu hình)], [Winner of Password Hashing Competition 2015],
    
    [PBKDF2], [Cao], [Trung bình], [Thấp], [NIST approved, widely supported],
    
    [SHA256], [Thấp], [Rất nhanh], [Thấp], [KHÔNG khuyến nghị cho passwords (quá nhanh)],
  )
]

=== 3.6.4 Security Best Practices

Input validation là first line of defense against nhiều attacks. Tất cả user input phải được xác thực trước khi xử lý. Validation nên kiểm tra data type, format, length, và allowed values. SQL injection prevention tốt nhất là sử dụng parameterized queries (prepared statements) thay vì string concatenation. HTTPS/TLS mã hóa tất cả communication giữa client và server, bảo vệ against eavesdropping và man-in-the-middle attacks. Rate limiting hạn chế số lượng requests một client có thể thực hiện trong một time period, bảo vệ against brute-force attacks và denial-of-service attacks.


== 3.7 Công nghệ sử dụng

=== 3.7.1 Go Programming Language

Go (hay Golang) là một programming language mã nguồn mở được phát triển bởi Google, được thiết kế cho xây dựng simple, reliable, và efficient software. Go được công bố năm 2009 bởi Robert Griesemer, Rob Pike, và Ken Thompson. Go kết hợp simplicity của dynamically-typed languages với safety và performance của statically-typed languages. Go đã trở thành một trong những languages phổ biến nhất cho xây dựng microservices, cloud-native applications, và distributed systems.

Performance là một trong những strengths chính của Go. Go là compiled language - code được biên dịch thành native machine code, cho phép execution speed gần với C/C++. Go compiler rất nhanh, có thể biên dịch large codebases trong seconds. Go có garbage collector hiệu quả, tự động quản lý memory mà không hy sinh performance đáng kể. Garbage collector của Go được tối ưu hóa cho low-latency, với pause times thường dưới 1ms.

Concurrency là feature nổi bật nhất của Go, được triển khai thông qua goroutines và channels. Goroutines là lightweight threads được quản lý bởi Go runtime, có thể tạo hàng nghìn hoặc millions goroutines mà không làm quá tải system. Mỗi goroutine chỉ chiếm vài KB memory ban đầu, so với threads truyền thống chiếm MBs. Channels là typed conduits cho communication giữa goroutines, triển khai CSP (Communicating Sequential Processes) model. Channels cho phép safe data sharing giữa goroutines mà không cần explicit locks.

Simplicity là design philosophy cốt lõi của Go. Go có minimalist syntax với chỉ 25 keywords, so với 50+ trong Java hay C++. Go không có classes, inheritance, generics (cho đến Go 1.18), hay nhiều features phức tạp khác. Thay vào đó, Go tập trung vào composition thông qua interfaces và structs. Điều này làm cho Go code dễ đọc và dễ bảo trì.

=== 3.7.2 Gin Framework

Gin là một HTTP web framework được viết bằng Go, được biết đến với performance cao và minimalist design. Gin được phát triển năm 2014 và đã trở thành một trong những Go web frameworks phổ biến nhất. Gin cung cấp fast HTTP router, middleware support, JSON validation, error handling, và nhiều features khác cần thiết cho xây dựng REST APIs.

Fast HTTP router là core strength của Gin. Gin sử dụng radix tree-based router (httprouter) cho extremely fast route matching. Router có thể xử lý millions of requests per second với latency sub-millisecond. Middleware support cho phép chèn logic vào request processing pipeline. JSON validation được tích hợp thông qua struct tags và validator library.

=== 3.7.3 SQLBoiler

SQLBoiler là một ORM (Object-Relational Mapping) tool cho Go, khác biệt với traditional ORMs bằng cách tạo type-safe code từ database schema. Thay vì định nghĩa models trong code và đồng bộ với database, SQLBoiler kiểm tra existing database và tạo Go code tương ứng. Điều này đảm bảo models luôn đồng bộ với database schema và cung cấp compile-time type safety.

Type-safe ORM có nghĩa là tất cả database operations được type-checked tại compile time. Không có string-based queries hay runtime type assertions. Nếu column không tồn tại hoặc type không khớp, code sẽ không biên dịch. Điều này phát hiện errors sớm và ngăn chặn nhiều runtime bugs.

=== 3.7.4 Docker & Kubernetes

Docker là một nền tảng phục vụ việc phát triển, đóng gói và vận hành ứng dụng trong môi trường container. Container là các gói thực thi nhẹ và độc lập, bao gồm toàn bộ thành phần cần thiết để vận hành ứng dụng như mã nguồn, môi trường chạy, công cụ hệ thống, thư viện và cấu hình. Docker cho phép đóng gói ứng dụng cùng toàn bộ phụ thuộc của nó thành các container image, có thể chạy nhất quán trên mọi môi trường triển khai.

Công nghệ container giải quyết vấn đề “chạy đúng trên máy tôi nhưng lỗi ở nơi khác”. Với Docker, ứng dụng và môi trường vận hành của nó được đóng gói chung, bảo đảm hành vi nhất quán giữa các môi trường. Các container chia sẻ nhân hệ điều hành của máy chủ nhưng được cô lập về hệ thống tệp, mạng và tiến trình. Nhờ đó, container nhẹ hơn nhiều so với máy ảo, khởi động nhanh và sử dụng ít tài nguyên.

Kubernetes là một nền tảng điều phối container, tự động thực hiện việc triển khai, mở rộng và quản lý các ứng dụng dạng container. Kubernetes được phát triển ban đầu bởi Google và hiện được duy trì bởi Cloud Native Computing Foundation (CNCF). Hệ thống này quản lý các cụm máy (node) và phân lịch các container trong pod lên từng node, đồng thời xử lý cân bằng tải, khám phá dịch vụ, cập nhật luân phiên và tự phục hồi.

Các khả năng điều phối của Kubernetes bao gồm nhiều thành phần. Pod là đơn vị triển khai nhỏ nhất, có thể chứa một hoặc nhiều container. Service cung cấp cơ chế kết nối mạng ổn định và cân bằng tải cho các pod. Deployment quản lý quá trình cập nhật luân phiên và phục hồi phiên bản. ConfigMap và Secret được sử dụng để quản lý cấu hình và dữ liệu nhạy cảm. Ingress điều phối truy cập từ bên ngoài vào các dịch vụ. Horizontal Pod Autoscaler tự động mở rộng pod dựa trên mức sử dụng tài nguyên hệ thống.

Lợi ích của Docker và Kubernetes bao gồm khả năng di chuyển linh hoạt giữa các môi trường, khả năng mở rộng tốt, tính nhất quán cao, hiệu quả sử dụng tài nguyên và tốc độ triển khai nhanh. Trong hệ thống SMAP, Docker được sử dụng để đóng gói toàn bộ dịch vụ, còn Kubernetes được sử dụng để điều phối trong môi trường vận hành, cho phép mở rộng linh hoạt và triển khai không gián đoạn.

== 3.8 Tổng kết

Chương này đã trình bày đầy đủ các nền tảng lý thuyết cần thiết để hiểu và đánh giá hệ thống SMAP. Các kiến trúc Microservices và Clean Architecture cung cấp framework tổng thể cho việc thiết kế hệ thống. Message Queue và Real-time Communication giải quyết các vấn đề về giao tiếp bất đồng bộ và real-time. Database Technologies với Polyglot Persistence cho phép tối ưu hóa lưu trữ dữ liệu. Authentication và Security đảm bảo an toàn cho hệ thống. Cuối cùng, các công nghệ cụ thể (Go, Gin, SQLBoiler, Docker, Kubernetes) cung cấp công cụ để triển khai các concepts này trong thực tế.

Những kiến thức này sẽ là nền tảng cho Chương 4, nơi chúng ta sẽ phân tích yêu cầu và thiết kế chi tiết hệ thống SMAP, áp dụng các nguyên lý và công nghệ đã được trình bày trong chương này.

