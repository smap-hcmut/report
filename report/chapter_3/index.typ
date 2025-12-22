#import "../counters.typ": table_counter

= CHƯƠNG 3: CƠ SỞ LÝ THUYẾT
Chương này hệ thống hóa các nền tảng lý thuyết và công nghệ chủ đạo làm cơ sở cho việc thiết kế, hiện thực và đánh giá hệ thống SMAP. Nội dung bao quát các phong cách kiến trúc, cơ chế giao tiếp trong hệ thống phân tán, nhóm công nghệ lưu trữ dữ liệu cùng các công nghệ triển khai.
== 3.1 Kiến trúc Microservices

=== 3.1.1 Định nghĩa và nguồn gốc

Kiến trúc Microservices là một phong cách kiến trúc phần mềm trong đó một ứng dụng được xây dựng như một tập hợp các dịch vụ nhỏ, độc lập, mỗi dịch vụ chạy trong tiến trình riêng và giao tiếp với nhau thông qua các cơ chế nhẹ như HTTP API hoặc Message Queue. Theo Martin Fowler, Microservices là cách tiếp cận để phát triển một ứng dụng đơn lẻ như một bộ các dịch vụ nhỏ, mỗi dịch vụ chạy trong tiến trình riêng và giao tiếp với các cơ chế nhẹ, thường là HTTP Resource API.

Sam Newman, tác giả của cuốn "Building Microservices", mở rộng định nghĩa này bằng cách nhấn mạnh rằng Microservices là các dịch vụ có thể triển khai độc lập được tổ chức xung quanh các khả năng nghiệp vụ. Mỗi dịch vụ sở hữu dữ liệu và logic nghiệp vụ của riêng nó, cho phép các nhóm phát triển, triển khai và mở rộng các dịch vụ một cách độc lập. Điều này tạo ra sự linh hoạt cao trong việc lựa chọn công nghệ và khả năng thích ứng nhanh với thay đổi của yêu cầu nghiệp vụ.

=== 3.1.2 Đặc điểm chính

==== 3.1.2.1 Loose Coupling

Các vi dịch vụ được thiết kế để có mức độ liên kết thấp với nhau, nghĩa là thay đổi trong một dịch vụ không yêu cầu thay đổi trong các dịch vụ khác. Mỗi dịch vụ có giao diện rõ ràng và giao tiếp thông qua các API được định nghĩa tốt. Điều này cho phép các nhóm phát triển các dịch vụ một cách độc lập mà không cần phối hợp chặt chẽ với các nhóm khác. Liên kết lỏng lẻo cũng giảm thiểu rủi ro khi thay đổi, vì một lỗi trong một dịch vụ không lan truyền sang các dịch vụ khác.

==== 3.1.2.2 Triển khai độc lập

Một trong những lợi ích quan trọng nhất của kiến trúc Microservices là khả năng triển khai từng dịch vụ một cách độc lập mà không cần triển khai lại toàn bộ hệ thống. Điều này cho phép các nhóm phát triển và phát hành tính năng mới nhanh hơn, giảm thời gian ngừng hoạt động và rủi ro khi triển khai. Mỗi dịch vụ có thể có chu kỳ phát hành riêng, cho phép các nhóm làm việc với tốc độ khác nhau tùy theo nhu cầu nghiệp vụ.

==== 3.1.2.3 Tổ chức theo khả năng nghiệp vụ

Các vi dịch vụ được tổ chức xung quanh các khả năng nghiệp vụ thay vì các lớp kỹ thuật. Mỗi dịch vụ đại diện cho một lĩnh vực nghiệp vụ cụ thể và sở hữu toàn bộ ngăn xếp công nghệ cần thiết để thực hiện chức năng đó, từ giao diện người dùng đến cơ sở dữ liệu. Cách tiếp cận này phản ánh cấu trúc tổ chức của doanh nghiệp và cho phép các nhóm đa chức năng làm việc hiệu quả hơn.

==== 3.1.2.4 Quản lý dữ liệu phi tập trung

Trong kiến trúc Microservices, mỗi dịch vụ quản lý cơ sở dữ liệu riêng của nó, theo nguyên tắc "một cơ sở dữ liệu cho mỗi dịch vụ". Điều này cho phép mỗi dịch vụ chọn công nghệ cơ sở dữ liệu phù hợp nhất với nhu cầu của nó. Tuy nhiên, cách tiếp cận này cũng đặt ra thách thức về tính nhất quán dữ liệu và các giao dịch phân tán. Thay vì sử dụng các giao dịch ACID truyền thống, Microservices thường áp dụng eventual consistency và  Saga Pattern để đảm bảo tính nhất quán dữ liệu.

==== 3.1.2.5 Tự động hóa hạ tầng

Kiến trúc Microservices đòi hỏi mức độ tự động hóa cao trong việc triển khai, giám sát và quản lý hạ tầng. Với số lượng lớn các dịch vụ cần quản lý, việc thực hiện thủ công trở nên không khả thi. Các công cụ như Docker cho việc đóng gói container, Kubernetes cho điều phối, và các CI/CD Pipeline cho triển khai tự động là thiết yếu. Infrastructure as Code cho phép định nghĩa và quản lý hạ tầng thông qua mã nguồn, đảm bảo tính nhất quán và khả năng tái tạo môi trường.

=== 3.1.3 So sánh với kiến trúc Monolithic

#context (align(center)[_Bảng #table_counter.display(): So sánh Microservices và Monolithic_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.5fr, 1.5fr),
    stroke: 0.5pt,
    align: (left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*Microservices*],
    table.cell(align: center + horizon)[*Monolithic*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Khả năng mở rộng],
    table.cell(align: left + horizon)[Có thể mở rộng từng service độc lập theo nhu cầu cụ thể],
    table.cell(align: left + horizon)[Phải mở rộng toàn bộ ứng dụng],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Triển khai],
    table.cell(align: left + horizon)[Triển khai từng service độc lập, giảm rủi ro],
    table.cell(align: left + horizon)[Triển khai toàn bộ ứng dụng, thời gian ngừng hoạt động cao hơn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Phát triển],
    table.cell(align: left + horizon)[Nhiều nhóm có thể làm việc song song trên các service khác nhau],
    table.cell(align: left + horizon)[Một codebase lớn, dễ xung đột mã nguồn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Gỡ lỗi],
    table.cell(align: left + horizon)[Phức tạp hơn do distributed tracing, cần công cụ chuyên dụng],
    table.cell(align: left + horizon)[Đơn giản hơn, có thể gỡ lỗi trong một tiến trình],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Tính nhất quán dữ liệu],
    table.cell(align: left + horizon)[Eventual consistency, cần xử lý distributed transactions],
    table.cell(align: left + horizon)[Strong consistency với ACID transactions],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Chi phí hạ tầng],
    table.cell(align: left + horizon)[Chi phí cao hơn do cần nhiều tài nguyên và công cụ quản lý],
    table.cell(align: left + horizon)[Chi phí thấp hơn cho hệ thống nhỏ],
  )
]

Kiến trúc Microservices mang lại nhiều lợi ích đáng kể cho các hệ thống lớn và phức tạp. Khả năng mở rộng độc lập cho phép tối ưu hóa tài nguyên. Việc triển khai độc lập giảm thiểu rủi ro và cho phép phát hành tính năng nhanh hơn. Cách ly lỗi đảm bảo rằng lỗi trong một dịch vụ không làm sập toàn bộ hệ thống. Đa dạng công nghệ cho phép chọn công nghệ phù hợp nhất cho từng dịch vụ.

Tuy nhiên, Microservices cũng đi kèm với những thách thức đáng kể. Độ phức tạp vận hành tăng lên đáng kể khi phải quản lý nhiều dịch vụ, cơ sở dữ liệu, và đường ống triển khai. Độ trễ mạng và độ tin cậy trở thành vấn đề khi các dịch vụ giao tiếp qua mạng thay vì các cuộc gọi trong tiến trình. Giao dịch phân tán và tính nhất quán dữ liệu khó đảm bảo hơn. Kiểm thử trở nên phức tạp hơn khi cần kiểm thử tích hợp giữa nhiều dịch vụ.

Ngược lại, kiến trúc Monolithic phù hợp hơn cho các ứng dụng nhỏ, đơn giản với nhóm nhỏ. Việc phát triển và gỡ lỗi đơn giản hơn khi tất cả mã nguồn ở một nơi. Triển khai đơn giản hơn với một sản phẩm duy nhất. Tính nhất quán dữ liệu dễ đảm bảo với các giao dịch ACID.


== 3.2 Clean Architecture

=== 3.2.1 Nguyên tắc thiết kế

Clean Architecture là một kiểu kiến trúc phần mềm được đề xuất bởi Robert C. Martin nhằm tạo ra các hệ thống dễ hiểu, linh hoạt và dễ bảo trì. Ý tưởng cốt lõi của Clean Architecture là tách biệt các mối quan tâm trong ứng dụng thành các tầng riêng biệt, với nguyên tắc các phụ thuộc chỉ trỏ vào trong. Kiến trúc này đảm bảo rằng logic nghiệp vụ không phụ thuộc vào các chi tiết triển khai như framework, cơ sở dữ liệu, hay giao diện người dùng.

Theo Robert C. Martin, một kiến trúc tốt phải đạt được các mục tiêu sau: độc lập với framework, có khả năng kiểm thử cao, độc lập với giao diện người dùng, độc lập với cơ sở dữ liệu, và độc lập với bất kỳ tác nhân bên ngoài nào. Điều này có nghĩa là các quy tắc nghiệp vụ không nên biết gì về thế giới bên ngoài. Sự độc lập này cho phép thay đổi các chi tiết triển khai mà không ảnh hưởng đến logic nghiệp vụ cốt lõi.

Khả năng kiểm thử là một trong những lợi ích quan trọng nhất của Clean Architecture. Vì logic nghiệp vụ không phụ thuộc vào các phụ thuộc bên ngoài, nó có thể được kiểm thử một cách độc lập mà không cần mock cơ sở dữ liệu, web server, hay bất kỳ dịch vụ bên ngoài nào. Các unit test có thể chạy nhanh và đáng tin cậy vì chúng chỉ kiểm thử logic nghiệp vụ thuần túy.

=== 3.2.2 Các tầng và Dependency Rule

Clean Architecture tổ chức mã nguồn thành các tầng đồng tâm, với logic nghiệp vụ ở trung tâm và các chi tiết triển khai ở bên ngoài. Có bốn tầng chính: Entities, Use Cases, Interface Adapters, và Frameworks and Drivers.

==== 3.2.2.1 Entities

Entities là tầng trong cùng, chứa các quy tắc nghiệp vụ quan trọng nhất và ổn định nhất của ứng dụng. Đây là các mô hình miền đại diện cho các khái niệm nghiệp vụ cốt lõi. Entities không phụ thuộc vào bất kỳ tầng nào khác và không biết gì về use case, controller, hay cơ sở dữ liệu. Chúng chỉ chứa logic nghiệp vụ thuần túy, các quy tắc mà sẽ tồn tại ngay cả khi không có ứng dụng.

==== 3.2.2.2 Use Cases

Tầng Use Cases chứa các quy tắc nghiệp vụ cụ thể của ứng dụng, các quy tắc mô tả cách ứng dụng sử dụng entities để đạt được mục tiêu cụ thể. Mỗi use case đại diện cho một chức năng nghiệp vụ cụ thể. Use Cases điều phối luồng dữ liệu đến và từ entities, và chỉ đạo entities thực hiện các quy tắc nghiệp vụ của chúng. Use Cases không biết gì về giao diện người dùng, cơ sở dữ liệu, hay các dịch vụ bên ngoài, chúng chỉ định nghĩa các interface mà các tầng bên ngoài phải triển khai.

==== 3.2.2.3 Interface Adapters

Tầng Interface Adapters chịu trách nhiệm chuyển đổi dữ liệu giữa định dạng phù hợp với use case và định dạng phù hợp với các tác nhân bên ngoài như cơ sở dữ liệu hay web. Tầng này bao gồm các controller nhận HTTP request và gọi use case, các presenter định dạng dữ liệu để trả về cho giao diện người dùng, và các gateway hoặc repository triển khai các interface được định nghĩa bởi use case để truy cập cơ sở dữ liệu. Đây là nơi dependency inversion xảy ra, use case định nghĩa interface, và adapter triển khai chúng.

==== 3.2.2.4 Frameworks and Drivers

Tầng ngoài cùng chứa các framework và công cụ như cơ sở dữ liệu, web framework, API bên ngoài. Đây là nơi tất cả các chi tiết triển khai cụ thể nằm. Mã nguồn trong tầng này thường rất ít vì phần lớn công việc được thực hiện bởi các thư viện bên thứ ba. Tầng này giao tiếp với tầng Interface Adapters để tích hợp với phần còn lại của ứng dụng.

==== 3.2.2.5 Dependency Rule

Nguyên tắc quan trọng nhất của Clean Architecture là Dependency Rule: các phụ thuộc mã nguồn chỉ được trỏ vào trong. Mã ở tầng trong không được biết gì về mã ở tầng ngoài. Entities không biết gì về Use Cases. Use Cases không biết gì về Controller hay cơ sở dữ liệu. Điều này đạt được thông qua dependency inversion, tầng trong định nghĩa interface, tầng ngoài triển khai chúng.


=== 3.2.3 So sánh với MVC và Hexagonal Architecture

#context (align(center)[_Bảng #table_counter.display(): So sánh Clean Architecture, MVC và Hexagonal Architecture_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*Clean Architecture*],
    table.cell(align: center + horizon)[*MVC*],
    table.cell(align: center + horizon)[*Hexagonal Architecture*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Testability],
    table.cell(align: center + horizon)[Rất cao, business logic hoàn toàn độc lập],
    table.cell(align: center + horizon)[Trung bình, business logic thường lẫn với controller],
    table.cell(align: center + horizon)[Rất cao, tương tự Clean Architecture],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Complexity],
    table.cell(align: center + horizon)[Cao, nhiều tầng và abstractions],
    table.cell(align: center + horizon)[Thấp, cấu trúc đơn giản],
    table.cell(align: center + horizon)[Trung bình, ít tầng hơn Clean Architecture],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Learning Curve],
    table.cell(align: center + horizon)[Dốc, cần hiểu dependency inversion],
    table.cell(align: center + horizon)[Thoải, pattern phổ biến],
    table.cell(align: center + horizon)[Trung bình, concepts dễ hiểu hơn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Flexibility],
    table.cell(align: center + horizon)[Rất cao, dễ thay đổi triển khai],
    table.cell(align: center + horizon)[Thấp, tight coupling với framework],
    table.cell(align: center + horizon)[Cao, ports và adapters dễ thay đổi],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Boilerplate],
    table.cell(align: center + horizon)[Nhiều, cần nhiều interfaces và abstractions],
    table.cell(align: center + horizon)[Ít, mã nguồn ngắn gọn hơn],
    table.cell(align: center + horizon)[Trung bình, cần ports và adapters],
  )
]

Clean Architecture và Hexagonal Architecture có nhiều điểm tương đồng, cả hai đều nhấn mạnh việc tách biệt logic nghiệp vụ khỏi các mối quan tâm bên ngoài thông qua abstraction. Sự khác biệt chính là Clean Architecture có cấu trúc tầng rõ ràng hơn với sự phân biệt giữa Entities và Use Cases, trong khi Hexagonal Architecture tập trung vào khái niệm port và adapter. Clean Architecture có thể được xem như một sự phát triển của Hexagonal Architecture với cấu trúc rõ ràng hơn.

So với MVC, Clean Architecture phức tạp hơn đáng kể nhưng mang lại khả năng kiểm thử và tính linh hoạt cao hơn nhiều. MVC phù hợp cho các ứng dụng nhỏ, đơn giản nơi logic nghiệp vụ không phức tạp và không cần độ bao phủ kiểm thử cao. Tuy nhiên, khi ứng dụng phát triển, MVC thường dẫn đến các controller phình to chứa cả logic nghiệp vụ lẫn logic trình bày, khó kiểm thử và bảo trì.

== 3.3 Message Queue và Event-Driven Architecture

=== 3.3.1 Khái niệm Message Queue

Message Queue là một cơ chế giao tiếp bất đồng bộ cho phép các thành phần trong hệ thống phân tán trao đổi thông tin mà không cần kết nối trực tiếp với nhau. Trong mô hình này, producer đưa message vào queue, và consumer lấy message ra khỏi queue để xử lý. Queue đóng vai trò như một bộ đệm trung gian, lưu trữ message cho đến khi consumer sẵn sàng xử lý. Điều này tạo ra sự tách biệt về thời gian, producer và consumer không cần trực tuyến cùng lúc, và sự tách biệt về không gian, chúng không cần biết địa chỉ của nhau.

Message Queue mang lại nhiều lợi ích quan trọng cho hệ thống phân tán. Xử lý bất đồng bộ cho phép producer tiếp tục công việc ngay sau khi gửi message mà không cần chờ consumer xử lý xong, cải thiện thời gian phản hồi và thông lượng. Cân bằng tải giúp hệ thống xử lý được các đợt tăng lưu lượng đột ngột, khi có nhiều request bất ngờ, message được xếp hàng và xử lý dần thay vì làm quá tải consumer. Độ tin cậy được cải thiện thông qua việc lưu trữ message và cơ chế thử lại, nếu consumer thất bại, message vẫn được giữ trong queue để xử lý lại. Khả năng mở rộng trở nên dễ dàng hơn khi có thể thêm nhiều consumer để xử lý message song song.

=== 3.3.2 RabbitMQ

RabbitMQ là một message broker mã nguồn mở phổ biến, triển khai AMQP, một giao thức chuẩn cho middleware hướng message. RabbitMQ đóng vai trò trung gian giữa producer và consumer, nhận message từ producer, định tuyến chúng đến đúng queue, và chuyển giao đến consumer. RabbitMQ hỗ trợ nhiều mẫu nhắn tin khác nhau thông qua các loại exchange, đảm bảo việc gửi message thông qua cơ chế xác nhận, và cung cấp tính bền vững để không mất message khi broker khởi động lại.

Kiến trúc của RabbitMQ bao gồm các thành phần chính sau. Exchange nhận message từ producer và định tuyến chúng đến queue dựa trên quy tắc định tuyến. Queue lưu trữ message cho đến khi consumer tiêu thụ chúng. Binding định nghĩa mối quan hệ giữa exchange và queue, xác định message nào được định tuyến đến queue nào. Routing key là thuộc tính của message được exchange sử dụng để quyết định định tuyến. Channel là kết nối ảo trong một kết nối TCP, cho phép ghép kênh nhiều thao tác trên một kết nối.

RabbitMQ hỗ trợ bốn loại exchange chính, mỗi loại có hành vi định tuyến khác nhau. Fanout exchange phát sóng message đến tất cả queue được liên kết với nó, bỏ qua routing key, phù hợp cho mẫu publish/subscribe. Direct exchange định tuyến message đến queue có binding key khớp chính xác với routing key của message, phù hợp cho nhắn tin đơn hướng. Topic exchange định tuyến message dựa trên khớp mẫu giữa routing key và binding pattern, hỗ trợ ký tự đại diện, phù hợp cho multicast có chọn lọc. Headers exchange định tuyến dựa trên header của message thay vì routing key.

Cơ chế xác nhận message là một cơ chế quan trọng đảm bảo độ tin cậy. Khi consumer nhận message, nó phải gửi xác nhận về RabbitMQ để xác nhận rằng message đã được xử lý thành công. Chỉ khi nhận được xác nhận, RabbitMQ mới xóa message khỏi queue. Nếu consumer thất bại trước khi gửi xác nhận, RabbitMQ sẽ gửi lại message đến consumer khác. Điều này đảm bảo việc gửi ít nhất một lần, message sẽ được gửi ít nhất một lần, có thể nhiều hơn nếu có lỗi.

=== 3.3.3 Producer-Consumer Pattern

Producer-Consumer pattern là một mẫu nhắn tin cơ bản trong đó producer tạo ra message và đưa vào queue, consumer lấy message ra và xử lý. Mẫu này tạo ra sự tách biệt hoàn toàn giữa producer và consumer, chúng không cần biết về sự tồn tại của nhau, chỉ cần biết về queue. Producer có thể tạo message với tốc độ của chúng, consumer có thể tiêu thụ với tốc độ của chúng, và queue đệm sự chênh lệch. Điều này cho phép producer và consumer mở rộng độc lập.

Cân bằng tải là một lợi ích quan trọng của mẫu Producer-Consumer. Khi có nhiều consumer cùng tiêu thụ từ một queue, RabbitMQ phân phối message giữa chúng theo kiểu vòng tròn. Điều này cho phép mở rộng theo chiều ngang, khi khối lượng công việc tăng, chỉ cần thêm consumer. Nếu một consumer chậm hoặc bận, message sẽ được định tuyến đến consumer khác.

=== 3.3.4 Publish/Subscribe Pattern

Publish/Subscribe pattern là một mẫu nhắn tin trong đó publisher phát sóng message đến nhiều subscriber quan tâm. Khác với mẫu Producer-Consumer, trong mẫu Pub/Sub, một message được gửi đến tất cả subscriber. Publisher không biết có bao nhiêu subscriber hay subscriber là ai. Subscriber không biết publisher là ai. Sự tách biệt này cho phép thêm subscriber mới mà không cần thay đổi publisher.

Trong RabbitMQ, mẫu Pub/Sub được triển khai bằng fanout exchange. Publisher gửi message đến fanout exchange. Exchange phát sóng message đến tất cả queue được liên kết với nó. Mỗi subscriber có queue riêng được liên kết với exchange. Khi message đến exchange, nó được sao chép và gửi đến tất cả queue. Mỗi subscriber nhận một bản sao của message và xử lý độc lập.

Mẫu Pub/Sub là nền tảng của Kiến trúc Hướng Sự kiện, trong đó các thành phần giao tiếp thông qua event. Khi một event xảy ra, service phát hành một event. Các service khác quan tâm đến event đó đăng ký và phản ứng tương ứng. Điều này tạo ra sự liên kết lỏng lẻo cao, các service không cần biết về nhau, chỉ cần biết về event.

=== 3.3.5 So sánh các Message Brokers

#context (align(center)[_Bảng #table_counter.display(): So sánh các Message Brokers_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*RabbitMQ*],
    table.cell(align: center + horizon)[*Apache Kafka*],
    table.cell(align: center + horizon)[*Redis Streams*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Throughput],
    table.cell(align: center + horizon)[Trung bình, 10K-20K msg/s],
    table.cell(align: center + horizon)[Rất cao, 100K-1M msg/s],
    table.cell(align: center + horizon)[Cao, 50K-100K msg/s],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Latency],
    table.cell(align: center + horizon)[Thấp, khoảng 10ms],
    table.cell(align: center + horizon)[Trung bình, khoảng 50ms],
    table.cell(align: center + horizon)[Rất thấp, khoảng 1ms],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Persistence],
    table.cell(align: center + horizon)[Có, durable queues],
    table.cell(align: center + horizon)[Có, log-based storage],
    table.cell(align: center + horizon)[Có, append-only log],

    table.cell(align: center + horizon, inset: (y: 1em))[Ordering],
    table.cell(align: center + horizon)[Per-queue ordering],
    table.cell(align: center + horizon)[Per-partition ordering],
    table.cell(align: center + horizon)[Per-stream ordering],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Use Cases],
    table.cell(align: center + horizon)[Task queues, RPC, routing],
    table.cell(align: center + horizon)[Event streaming, log aggregation],
    table.cell(align: center + horizon)[Real-time analytics, caching],
  )
]

RabbitMQ phù hợp cho các trường hợp sử dụng hàng đợi message truyền thống như hàng đợi tác vụ, mẫu request-response, và các tình huống định tuyến phức tạp. Nó cung cấp định tuyến linh hoạt thông qua exchange, đảm bảo gửi mạnh mẽ thông qua cơ chế xác nhận, và hệ sinh thái trưởng thành với nhiều thư viện client. RabbitMQ là lựa chọn tốt khi cần logic định tuyến phức tạp, hàng đợi ưu tiên, hoặc TTL message.

Apache Kafka được thiết kế cho streaming sự kiện thông lượng cao và tập hợp log. Nó có thể xử lý hàng triệu message mỗi giây và giữ lại message trong thời gian dài. Kafka phù hợp cho event sourcing, xử lý stream, và các tình huống cần phát lại message. Tuy nhiên, Kafka có độ phức tạp vận hành cao hơn và độ trễ cao hơn RabbitMQ.

Redis Streams là giải pháp thay thế nhẹ cho streaming message, được tích hợp sẵn trong Redis. Nó có độ trễ rất thấp và thông lượng cao, phù hợp cho các trường hợp sử dụng thời gian thực. Tuy nhiên, Redis Streams không có khả năng định tuyến phức tạp như RabbitMQ và không được thiết kế để lưu giữ message lâu dài như Kafka.


== 3.4 Real-time Communication

=== 3.4.1 WebSocket Protocol

WebSocket là một giao thức giao tiếp cung cấp các kênh giao tiếp song công qua một kết nối TCP duy nhất. Khác với HTTP truyền thống theo mô hình request-response, WebSocket cho phép server đẩy dữ liệu đến client bất cứ lúc nào mà không cần client yêu cầu. Điều này làm cho WebSocket lý tưởng cho các ứng dụng thời gian thực như chat, thông báo, cập nhật trực tiếp, và chỉnh sửa cộng tác. WebSocket được chuẩn hóa bởi IETF theo RFC 6455 và được hỗ trợ rộng rãi bởi tất cả trình duyệt hiện đại.

Giao tiếp song công có nghĩa là cả client và server đều có thể gửi message độc lập với nhau cùng một lúc. Không giống như HTTP polling nơi client phải liên tục gửi request để kiểm tra cập nhật, với WebSocket, server có thể đẩy cập nhật ngay khi có dữ liệu mới. Điều này giảm độ trễ đáng kể và giảm chi phí của việc thiết lập kết nối liên tục. Một khi kết nối WebSocket được thiết lập, nó được giữ mở cho đến khi một trong hai bên đóng nó, cho phép giao tiếp hai chiều với chi phí tối thiểu.

Quá trình bắt tay WebSocket bắt đầu với một HTTP request đặc biệt từ client. Client gửi HTTP GET request với các header đặc biệt: Upgrade websocket và Connection Upgrade, cùng với Sec-WebSocket-Key để bảo mật. Nếu server hỗ trợ WebSocket, nó phản hồi với mã trạng thái 101 Switching Protocols và các header tương ứng. Sau khi bắt tay thành công, kết nối được nâng cấp từ HTTP sang giao thức WebSocket, và cả hai bên có thể bắt đầu gửi WebSocket frame. Frame là đơn vị dữ liệu nhỏ nhất trong WebSocket, có thể chứa dữ liệu văn bản hoặc nhị phân, và có chi phí rất thấp chỉ 2-14 byte mỗi frame.

Độ trễ thấp là một trong những ưu điểm lớn nhất của WebSocket. Vì kết nối được giữ mở, không có chi phí của TCP handshake và HTTP header cho mỗi message. Message được gửi ngay lập tức khi có dữ liệu, không cần polling. Trong thực tế, WebSocket có thể đạt độ trễ dưới 10ms trong mạng cục bộ và 50-100ms qua internet, tùy thuộc vào điều kiện mạng.

=== 3.4.2 Redis Pub/Sub

Redis Pub/Sub là một hệ thống nhắn tin được tích hợp sẵn trong Redis, cho phép publisher gửi message đến channel và subscriber nhận message từ channel họ đăng ký. Redis Pub/Sub hoạt động hoàn toàn trong bộ nhớ, không có tính bền vững, và sử dụng ngữ nghĩa "bắn và quên", message được gửi đến subscriber đang trực tuyến, nếu không có subscriber nào, message bị loại bỏ. Điều này làm cho Redis Pub/Sub rất nhanh nhưng không đáng tin cậy như hàng đợi message truyền thống.

Messagging trong bộ nhớ là lý do Redis Pub/Sub có độ trễ cực thấp. Vì tất cả thao tác diễn ra trong RAM và không có I/O đĩa, message được gửi trong vài microsecond. Redis có thể xử lý hàng triệu message mỗi giây trên phần cứng tiêu chuẩn. Điều này làm cho Redis Pub/Sub lý tưởng cho các trường hợp sử dụng cần độ trễ thấp nhất có thể, như thông báo thời gian thực, dashboard trực tiếp, và ứng dụng chat.

Đăng ký theo mẫu là một tính năng mạnh mẽ của Redis Pub/Sub. Thay vì đăng ký đến một channel cụ thể, subscriber có thể đăng ký đến một mẫu sử dụng ký tự đại diện. Điều này cho phép định tuyến linh hoạt mà không cần tạo nhiều đăng ký.

Ngữ nghĩa Fire and Forget có nghĩa là Redis không đảm bảo việc gửi message. Nếu không có subscriber nào đang lắng nghe channel khi message được phát hành, message bị mất. Nếu subscriber đang xử lý message và gặp sự cố, message cũng bị mất. Redis không có tính bền vững message, cơ chế xác nhận, hay cơ chế thử lại. Điều này là sự đánh đổi cho hiệu suất, bằng cách bỏ qua các đảm bảo độ tin cậy, Redis đạt được độ trễ rất thấp khoảng 1ms.

=== 3.4.3 So sánh các Real-time Protocols

#context (align(center)[_Bảng #table_counter.display(): So sánh các Real-time Protocols_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.2fr, 1.2fr, 1.2fr, 1.2fr),
    stroke: 0.5pt,
    align: (left, center, center, center, center),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*WebSocket*],
    table.cell(align: center + horizon)[*Server-Sent Events*],
    table.cell(align: center + horizon)[*Long Polling*],
    table.cell(align: center + horizon)[*gRPC*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Latency],
    table.cell(align: center + horizon)[Rất thấp, khoảng 10ms],
    table.cell(align: center + horizon)[Thấp, khoảng 20ms],
    table.cell(align: center + horizon)[Cao, trên 100ms],
    table.cell(align: center + horizon)[Rất thấp, khoảng 10ms],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Browser Support],
    table.cell(align: center + horizon)[Xuất sắc, all modern],
    table.cell(align: center + horizon)[Tốt, không hỗ trợ IE],
    table.cell(align: center + horizon)[Phổ quát],
    table.cell(align: center + horizon)[Yêu cầu library],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Complexity],
    table.cell(align: center + horizon)[Trung bình],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Cao],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Bi-directional],
    table.cell(align: center + horizon)[Có, full-duplex],
    table.cell(align: center + horizon)[Không, chỉ server đến client],
    table.cell(align: center + horizon)[Có, mô phỏng],
    table.cell(align: center + horizon)[Có, full-duplex],
  )
]

WebSocket là lựa chọn tốt nhất cho giao tiếp thời gian thực hai chiều thực sự. Nó có độ trễ thấp, chi phí thấp, và được hỗ trợ rộng rãi. WebSocket phù hợp cho ứng dụng chat, chỉnh sửa cộng tác, game, và bất kỳ trường hợp sử dụng nào cần client và server gửi message cho nhau thường xuyên. Tuy nhiên, WebSocket có độ phức tạp cao hơn, cần xử lý quản lý kết nối, logic kết nối lại, và heartbeat.

Server-Sent Events là một giải pháp thay thế đơn giản hơn cho các tình huống chỉ cần server đẩy dữ liệu đến client. SSE sử dụng kết nối HTTP thông thường và được tích hợp sẵn trong trình duyệt qua EventSource API. SSE tự động kết nối lại khi kết nối bị ngắt và có ID sự kiện tích hợp sẵn để sắp xếp thứ tự message. Tuy nhiên, SSE không hỗ trợ dữ liệu nhị phân và không có giao tiếp hai chiều.

Long Polling là kỹ thuật cũ hơn, mô phỏng thời gian thực bằng cách client gửi HTTP request và server giữ request mở cho đến khi có dữ liệu hoặc hết thời gian chờ. Khi response được gửi, client ngay lập tức gửi request mới. Long Polling có độ trễ cao hơn và chi phí lớn hơn do phải thiết lập kết nối HTTP liên tục. Tuy nhiên, nó hoạt động với bất kỳ hạ tầng HTTP nào và không có vấn đề tương thích.

gRPC Streaming cung cấp streaming hai chiều qua HTTP/2. Nó có hiệu suất tương đương với WebSocket và hỗ trợ message có kiểu mạnh thông qua Protocol Buffers. gRPC phù hợp cho giao tiếp service-to-service trong kiến trúc microservice. Tuy nhiên, hỗ trợ trình duyệt yêu cầu gRPC-Web proxy và độ phức tạp cao hơn WebSocket.


== 3.5 Database Technologies

=== 3.5.1 PostgreSQL

PostgreSQL là một hệ quản trị cơ sở dữ liệu quan hệ mã nguồn mở, được biết đến với độ tin cậy cao, tính năng phong phú, và tuân thủ chuẩn SQL. PostgreSQL được phát triển từ năm 1986 tại Đại học California, Berkeley, và đã trở thành một trong những hệ thống cơ sở dữ liệu phổ biến nhất cho các ứng dụng doanh nghiệp. PostgreSQL hỗ trợ cả truy vấn SQL quan hệ và JSON phi quan hệ, làm cho nó trở thành một cơ sở dữ liệu đối tượng-quan hệ linh hoạt.

Tuân thủ ACID là một trong những điểm mạnh chính của PostgreSQL. ACID là viết tắt của Atomicity - tính nguyên tử, Consistency - tính nhất quán, Isolation - tính cô lập, và Durability - tính bền vững. Tính nguyên tử đảm bảo các giao dịch hoàn thành đầy đủ hoặc không hoàn thành gì cả. Tính nhất quán đảm bảo cơ sở dữ liệu luôn ở trạng thái hợp lệ. Tính cô lập đảm bảo các giao dịch đồng thời không ảnh hưởng lẫn nhau. Tính bền vững đảm bảo dữ liệu đã commit không bị mất ngay cả khi hệ thống gặp sự cố. Các đảm bảo ACID đảm bảo tính toàn vẹn và độ tin cậy của dữ liệu, đặc biệt quan trọng cho các ứng dụng tài chính, thương mại điện tử, và bất kỳ hệ thống nào cần tính nhất quán mạnh. PostgreSQL triển khai ACID thông qua Kiểm soát Đồng thời Đa phiên bản, cho phép đồng thời cao mà không cần khóa.

Hỗ trợ JSONB là một tính năng độc đáo làm cho PostgreSQL linh hoạt hơn các cơ sở dữ liệu quan hệ truyền thống. JSONB là định dạng JSON nhị phân được PostgreSQL lưu trữ hiệu quả và hỗ trợ đánh chỉ mục. Điều này cho phép lưu trữ dữ liệu bán cấu trúc trong cơ sở dữ liệu quan hệ mà vẫn có thể truy vấn hiệu quả. JSONB hỗ trợ các toán tử đặc biệt để truy vấn dữ liệu JSON. Chỉ mục GIN có thể được tạo trên các cột JSONB để tăng tốc truy vấn.

=== 3.5.2 MongoDB

MongoDB là một cơ sở dữ liệu NoSQL hướng tài liệu, lưu trữ dữ liệu dưới dạng tài liệu giống JSON thay vì hàng và cột như cơ sở dữ liệu quan hệ. MongoDB được thiết kế cho khả năng mở rộng, tính linh hoạt, và hiệu suất với dữ liệu bán cấu trúc. Mỗi tài liệu có thể có cấu trúc khác nhau, cho phép phát triển lược đồ dễ dàng mà không cần di chuyển. MongoDB được phát hành năm 2009 và đã trở thành một trong những cơ sở dữ liệu NoSQL phổ biến nhất.

Lược đồ linh hoạt là một trong những lợi ích lớn nhất của MongoDB. Không giống như cơ sở dữ liệu quan hệ yêu cầu định nghĩa lược đồ trước, MongoDB cho phép chèn tài liệu với cấu trúc khác nhau vào cùng một bộ sưu tập. Điều này rất hữu ích khi cấu trúc dữ liệu không cố định hoặc phát triển theo thời gian.

Mở rộng theo chiều ngang là một điểm mạnh khác của MongoDB. MongoDB hỗ trợ sharding, phân phối dữ liệu trên nhiều server. Mỗi shard chứa một tập con của dữ liệu, và bộ định tuyến MongoDB định tuyến truy vấn đến đúng shard. Điều này cho phép mở rộng ra ngoài bằng cách thêm server thay vì mở rộng lên bằng cách nâng cấp phần cứng.

=== 3.5.3 Redis

Redis là một kho lưu trữ cấu trúc dữ liệu trong bộ nhớ được sử dụng như cơ sở dữ liệu, bộ nhớ đệm, và message broker. Redis lưu trữ tất cả dữ liệu trong RAM, cho phép các thao tác đọc và ghi cực nhanh với độ trễ dưới millisecond. Redis hỗ trợ nhiều cấu trúc dữ liệu như chuỗi, hash, danh sách, tập hợp, tập hợp có thứ tự, bitmap, hyperloglog, và chỉ mục không gian địa lý. Redis được phát hành năm 2009 và đã trở thành tiêu chuẩn thực tế cho bộ nhớ đệm và các ứng dụng thời gian thực.

Lưu trữ trong bộ nhớ là lý do Redis có hiệu suất xuất sắc. Tất cả dữ liệu được lưu trữ trong RAM, không có I/O đĩa cho các thao tác đọc. Redis có thể xử lý hàng triệu thao tác mỗi giây trên phần cứng tiêu chuẩn. Điều này làm cho Redis lý tưởng cho bộ nhớ đệm, lưu trữ phiên, và phân tích thời gian thực.

Cấu trúc dữ liệu phong phú phân biệt Redis với các kho key-value đơn giản. Chuỗi cho các giá trị đơn giản và bộ đếm. Hash cho các đối tượng với nhiều trường. Danh sách cho hàng đợi và ngăn xếp. Tập hợp cho các bộ sưu tập duy nhất. Tập hợp có thứ tự cho bảng xếp hạng và hàng đợi ưu tiên. Mỗi cấu trúc dữ liệu có các thao tác được tối ưu hóa, cho phép các thao tác phức tạp trong các lệnh đơn.

Các tùy chọn bền vững cho phép Redis lưu dữ liệu xuống đĩa để khôi phục sau khi khởi động lại. Ảnh chụp RDB tạo ảnh chụp tại thời điểm của tập dữ liệu. Log AOF ghi lại mọi thao tác ghi. Cả hai có thể được kết hợp để cân bằng giữa hiệu suất và tính bền vững.

=== 3.5.4 Polyglot Persistence

Polyglot Persistence là phương pháp kiến trúc sử dụng nhiều công nghệ cơ sở dữ liệu khác nhau trong cùng một ứng dụng, mỗi cơ sở dữ liệu được chọn dựa trên trường hợp sử dụng cụ thể. Thay vì sử dụng một cơ sở dữ liệu cho tất cả dữ liệu, polyglot persistence chọn công cụ phù hợp cho từng công việc: cơ sở dữ liệu quan hệ cho dữ liệu có cấu trúc, cơ sở dữ liệu tài liệu cho lược đồ linh hoạt, kho key-value cho bộ nhớ đệm. Phương pháp này tối ưu hóa hiệu suất, khả năng mở rộng, và năng suất của nhà phát triển bằng cách tận dụng điểm mạnh của mỗi loại cơ sở dữ liệu.

#context (align(center)[_Bảng #table_counter.display(): So sánh các Database Technologies_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*PostgreSQL*],
    table.cell(align: center + horizon)[*MongoDB*],
    table.cell(align: center + horizon)[*Redis*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Data Model],
    table.cell(align: center + horizon)[Relational, tables và rows],
    table.cell(align: center + horizon)[Document, JSON-like],
    table.cell(align: center + horizon)[Key-Value, Data Structures],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Consistency],
    table.cell(align: center + horizon)[Mạnh, ACID],
    table.cell(align: center + horizon)[Eventual, có thể điều chỉnh],
    table.cell(align: center + horizon)[Eventual, in-memory],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Scalability],
    table.cell(align: center + horizon)[Vertical và Read Replicas],
    table.cell(align: center + horizon)[Horizontal, Sharding],
    table.cell(align: center + horizon)[Horizontal, Clustering],

    table.cell(align: center + horizon, inset: (y: 1em))[Performance],
    table.cell(align: center + horizon)[Tốt, disk-based],
    table.cell(align: center + horizon)[Rất tốt, disk-based],
    table.cell(align: center + horizon)[Xuất sắc, in-memory],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Use Cases],
    table.cell(align: center + horizon)[Structured data, transactions],
    table.cell(align: center + horizon)[Semi-structured, flexible schema],
    table.cell(align: center + horizon)[Caching, real-time, sessions],
  )
]

Polyglot persistence có nhiều lợi ích. Tối ưu hóa hiệu suất cho phép chọn cơ sở dữ liệu tối ưu cho từng khối lượng công việc. Tính linh hoạt về khả năng mở rộng cho phép mở rộng từng cơ sở dữ liệu độc lập. Năng suất của nhà phát triển tăng khi sử dụng cơ sở dữ liệu phù hợp với mô hình dữ liệu. Tối ưu hóa chi phí cho phép sử dụng lưu trữ rẻ hơn cho dữ liệu ít quan trọng hơn.

Tuy nhiên, polyglot persistence cũng có những thách thức. Độ phức tạp vận hành tăng khi phải quản lý nhiều hệ thống cơ sở dữ liệu. Tính nhất quán dữ liệu khó đảm bảo khi dữ liệu được phân tán trên các cơ sở dữ liệu. Chuyên môn của nhóm cần thiết cho mỗi công nghệ cơ sở dữ liệu. Độ phức tạp tích hợp khi cần kết hợp dữ liệu từ nhiều nguồn.


== 3.6 Authentication và Security

=== 3.6.1 JWT

JSON Web Token là một tiêu chuẩn mở theo RFC 7519 định nghĩa một cách gọn nhẹ và tự chứa để truyền thông tin an toàn giữa các bên dưới dạng đối tượng JSON. JWT được sử dụng rộng rãi cho xác thực và trao đổi thông tin trong các ứng dụng web và API. Một trong những lợi ích chính của JWT là xác thực không trạng thái, server không cần lưu trữ dữ liệu phiên, tất cả thông tin cần thiết được mã hóa trong chính token.

JWT bao gồm ba phần được phân tách bởi dấu chấm: Header, Payload, và Signature. Header chứa siêu dữ liệu về token, thường bao gồm loại và thuật toán ký. Payload chứa các claim, các tuyên bố về thực thể thường là người dùng và siêu dữ liệu bổ sung. Signature được tạo bằng cách mã hóa header và payload, sau đó ký với khóa bí mật sử dụng thuật toán được chỉ định trong header.

Các claim trong JWT payload có thể là các claim đã đăng ký được định nghĩa trong đặc tả như iss (issuer), exp (expiration time), sub (subject), các claim công khai được định nghĩa bởi người dùng, hoặc các claim riêng tư được thỏa thuận giữa các bên. Các claim đã đăng ký cung cấp khả năng tương tác, trong khi các claim tùy chỉnh cho phép truyền dữ liệu cụ thể của ứng dụng.

Xác thực không trạng thái là lợi ích chính của JWT. Server không cần lưu trữ dữ liệu phiên, tất cả thông tin cần thiết nằm trong token. Điều này cho phép mở rộng theo chiều ngang dễ dàng, bất kỳ server nào cũng có thể xác minh token mà không cần kho lưu trữ phiên chia sẻ. Tuy nhiên, không trạng thái cũng có nhược điểm, không thể vô hiệu hóa token trước thời gian hết hạn mà không có các cơ chế bổ sung như danh sách đen token.

=== 3.6.2 HttpOnly Cookie

HttpOnly Cookie là một thuộc tính cookie được đặt bởi server để ngăn các script phía client truy cập cookie. Khi cookie có cờ HttpOnly, mã JavaScript không thể đọc giá trị cookie thông qua document.cookie. Điều này là một biện pháp bảo mật quan trọng để bảo vệ chống lại các cuộc tấn công Cross-Site Scripting. HttpOnly cookie thường được sử dụng để lưu trữ các token xác thực như JWT, ID phiên, và dữ liệu nhạy cảm khác.

Cookie có nhiều thuộc tính kiểm soát hành vi và bảo mật của chúng. HttpOnly ngăn truy cập JavaScript, bảo vệ chống lại XSS. Secure đảm bảo cookie chỉ được gửi qua kết nối HTTPS, bảo vệ chống lại các cuộc tấn công man-in-the-middle. SameSite kiểm soát khi nào cookie được gửi với các request cross-site, có ba giá trị: Strict không bao giờ gửi với request cross-site, Lax gửi với điều hướng cấp cao nhất, và None luôn gửi nhưng yêu cầu Secure.

=== 3.6.3 Password Hashing

Băm mật khẩu là quá trình chuyển đổi mật khẩu văn bản thô thành một chuỗi có kích thước cố định sử dụng hàm mật mã một chiều. Các hàm băm được thiết kế để không thể đảo ngược, không thể suy ra mật khẩu gốc từ hash. Khi người dùng đăng ký, mật khẩu được băm và hash được lưu trữ trong cơ sở dữ liệu. Khi người dùng đăng nhập, mật khẩu đầu vào được băm và so sánh với hash đã lưu trữ.

bcrypt là một thuật toán băm mật khẩu được thiết kế đặc biệt cho lưu trữ mật khẩu. bcrypt có nhiều thuộc tính làm cho nó an toàn: chậm theo thiết kế để tốn kém về mặt tính toán, thích ứng với hệ số chi phí có thể tăng theo thời gian, và tự động tạo và bao gồm salt. bcrypt được coi là tiêu chuẩn ngành cho băm mật khẩu và được khuyến nghị bởi OWASP.

#context (align(center)[_Bảng #table_counter.display(): So sánh các Password Hashing Algorithms_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.2fr, 1.2fr, 1.2fr),
    stroke: 0.5pt,
    align: (center, center, center, center, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Algorithm*],
    table.cell(align: center + horizon)[*Security*],
    table.cell(align: center + horizon)[*Performance*],
    table.cell(align: center + horizon)[*Memory Usage*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[bcrypt],
    table.cell(align: center + horizon)[Rất cao],
    table.cell(align: center + horizon)[Chậm],
    table.cell(align: center + horizon)[Thấp],
   

    table.cell(align: center + horizon, inset: (y: 0.6em))[Argon2],
    table.cell(align: center + horizon)[Rất cao],
    table.cell(align: center + horizon)[Chậm],
    table.cell(align: center + horizon)[Cao, có thể cấu hình],
    

    table.cell(align: center + horizon, inset: (y: 0.6em))[PBKDF2],
    table.cell(align: center + horizon)[Cao],
    table.cell(align: center + horizon)[Trung bình],
    table.cell(align: center + horizon)[Thấp],
   

    table.cell(align: center + horizon, inset: (y: 0.6em))[SHA256],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Rất nhanh],
    table.cell(align: center + horizon)[Thấp],
   
  )
]

=== 3.6.4 Security Practices

Xác thực đầu vào là tuyến phòng thủ đầu tiên chống lại nhiều cuộc tấn công. Tất cả đầu vào của người dùng phải được xác thực trước khi xử lý. Xác thực nên kiểm tra loại dữ liệu, định dạng, độ dài, và các giá trị được phép. Phòng chống SQL injection tốt nhất là sử dụng truy vấn có tham số thay vì nối chuỗi.

HTTPS/TLS mã hóa tất cả giao tiếp giữa client và server, bảo vệ chống lại nghe lén và các cuộc tấn công man-in-the-middle. TLS 1.3 là phiên bản mới nhất với bảo mật và hiệu suất được cải thiện. Tất cả các ứng dụng sản xuất nên sử dụng HTTPS độc quyền.

Giới hạn tốc độ hạn chế số lượng request mà một client có thể thực hiện trong một khoảng thời gian, bảo vệ chống lại các cuộc tấn công brute-force và denial-of-service. Giới hạn tốc độ có thể được triển khai ở nhiều cấp độ: theo IP, theo người dùng, theo endpoint.

CORS là một cơ chế bảo mật kiểm soát các request cross-origin. Trình duyệt thực thi chính sách same-origin, ngăn các script từ một origin truy cập tài nguyên từ origin khác. Các header CORS cho phép server chỉ định origin nào được phép truy cập tài nguyên.


== 3.7 Công nghệ Backend

=== 3.7.1 Go và Gin Framework

Go là một ngôn ngữ lập trình mã nguồn mở được phát triển bởi Google, được thiết kế để xây dựng phần mềm đơn giản, đáng tin cậy, và hiệu quả. Go được công bố năm 2009 bởi Robert Griesemer, Rob Pike, và Ken Thompson. Go kết hợp sự đơn giản của các ngôn ngữ kiểu động với tính an toàn và hiệu suất của các ngôn ngữ kiểu tĩnh. Go đã trở thành một trong những ngôn ngữ phổ biến nhất để xây dựng microservice, ứng dụng cloud-native, và hệ thống phân tán.

Hiệu suất là một trong những điểm mạnh chính của Go. Go là ngôn ngữ biên dịch, mã được biên dịch thành mã máy gốc, cho phép tốc độ thực thi gần với C/C++. Trình biên dịch Go rất nhanh, có thể biên dịch các codebase lớn trong vài giây. Go có bộ thu gom rác hiệu quả, tự động quản lý bộ nhớ mà không hy sinh hiệu suất đáng kể. Bộ thu gom rác của Go được tối ưu hóa cho độ trễ thấp, với thời gian tạm dừng thường dưới 1ms.

Đồng thời là tính năng nổi bật nhất của Go, được triển khai thông qua goroutine và channel. Goroutine là các luồng nhẹ được quản lý bởi Go runtime, có thể tạo hàng nghìn hoặc hàng triệu goroutine mà không làm quá tải hệ thống. Mỗi goroutine chỉ tiêu thụ vài KB bộ nhớ ban đầu, so với các luồng truyền thống tiêu thụ MB. Channel là các kênh có kiểu để giao tiếp giữa các goroutine, triển khai mô hình CSP. Channel cho phép chia sẻ dữ liệu an toàn giữa các goroutine mà không cần khóa rõ ràng.

Sự đơn giản là triết lý thiết kế cốt lõi của Go. Go có cú pháp tối giản với chỉ 25 từ khóa, so với 50+ trong Java hay C++. Go không có class, kế thừa, hay nhiều tính năng phức tạp khác. Thay vào đó, Go tập trung vào composition thông qua interface và struct. Điều này làm cho mã Go dễ đọc và bảo trì.

Gin là một HTTP web framework được viết bằng Go, được biết đến với hiệu suất cao và thiết kế tối giản. Gin được phát triển năm 2014 và đã trở thành một trong những Go web framework phổ biến nhất. Gin cung cấp bộ định tuyến HTTP nhanh, hỗ trợ middleware, xác thực JSON, xử lý lỗi, và nhiều tính năng khác cần thiết để xây dựng REST API.

Bộ định tuyến HTTP nhanh là điểm mạnh cốt lõi của Gin. Gin sử dụng bộ định tuyến dựa trên radix tree để khớp tuyến đường cực nhanh. Bộ định tuyến có thể xử lý hàng triệu request mỗi giây với độ trễ dưới millisecond. Tham số tuyến đường, ký tự đại diện, và nhóm tuyến đường được hỗ trợ với cú pháp đơn giản.

Hỗ trợ middleware cho phép chèn logic vào pipeline xử lý request. Middleware có thể xử lý xác thực, ghi log, CORS, giới hạn tốc độ, và nhiều mối quan tâm xuyên suốt khác. Gin cung cấp nhiều middleware tích hợp sẵn và cho phép tạo middleware tùy chỉnh dễ dàng.

Xác thực JSON được tích hợp thông qua thẻ struct và thư viện validator. Nội dung request có thể được liên kết và xác thực tự động. Lỗi xác thực được trả về với thông báo chi tiết. Điều này giảm mã boilerplate và đảm bảo tính toàn vẹn dữ liệu.

=== 3.7.2 SQLBoiler

SQLBoiler là một công cụ ORM cho Go, khác biệt với các ORM truyền thống bằng cách tạo mã an toàn kiểu từ lược đồ cơ sở dữ liệu. Thay vì định nghĩa model trong mã và đồng bộ với cơ sở dữ liệu, SQLBoiler kiểm tra cơ sở dữ liệu hiện có và tạo mã Go tương ứng. Điều này đảm bảo các model luôn đồng bộ với lược đồ cơ sở dữ liệu và cung cấp tính an toàn kiểu tại thời điểm biên dịch.

ORM an toàn kiểu có nghĩa là tất cả các thao tác cơ sở dữ liệu được kiểm tra kiểu tại thời điểm biên dịch. Không có truy vấn dựa trên chuỗi hay xác nhận kiểu runtime. Nếu cột không tồn tại hoặc kiểu không khớp, mã sẽ không biên dịch được. Điều này phát hiện lỗi sớm và ngăn ngừa nhiều lỗi runtime.

Phương pháp tạo mã có nhiều lợi ích. Mã được tạo có thể đọc và debug được. Hiệu suất tốt hơn các ORM dựa trên reflection. Hỗ trợ IDE tốt với tự động hoàn thành và kiểm tra kiểu. Tuy nhiên, cần tạo lại mã khi lược đồ thay đổi.

=== 3.7.3 Python và FastAPI

Python là một ngôn ngữ lập trình đa năng, được biết đến với cú pháp rõ ràng và hệ sinh thái phong phú. Python đặc biệt mạnh trong khoa học dữ liệu, học máy, và scripting. Trong bối cảnh của SMAP, Python được sử dụng cho Analytics Service và Speech2Text Service, nơi cần tận dụng các thư viện AI/ML như PyTorch, PhoBERT, và Whisper.

FastAPI là một web framework hiện đại cho Python, được thiết kế để xây dựng API với hiệu suất cao. FastAPI sử dụng gợi ý kiểu Python để tự động xác thực, tuần tự hóa, và tài liệu hóa. FastAPI có hiệu suất tương đương với Node.js và Go nhờ sử dụng Starlette và Pydantic.

Hỗ trợ bất đồng bộ trong FastAPI cho phép xử lý các request đồng thời một cách hiệu quả. Python asyncio được tích hợp sẵn, cho phép các thao tác I/O không chặn. Điều này quan trọng cho các service cần xử lý nhiều request đồng thời như các endpoint API.


== 3.8 Công nghệ Frontend

=== 3.8.1 Next.js

Next.js là một React framework được phát triển bởi Vercel, cung cấp nhiều tính năng để xây dựng các ứng dụng web sẵn sàng sản xuất. Next.js hỗ trợ Server-Side Rendering, Static Site Generation, và Client-Side Rendering, cho phép chọn chiến lược render phù hợp cho từng trang. Next.js đã trở thành một trong những React framework phổ biến nhất cho các ứng dụng doanh nghiệp.

Server-Side Rendering cho phép render các React component trên server và gửi HTML đến client. Điều này cải thiện thời gian tải trang ban đầu và SEO vì các công cụ tìm kiếm có thể lập chỉ mục nội dung. SSR đặc biệt quan trọng cho các trang có nhiều nội dung và ứng dụng cần SEO tốt.

App Router là hệ thống định tuyến mới trong Next.js 13+, sử dụng định tuyến dựa trên hệ thống file với React Server Components. App Router cho phép bố cục lồng nhau, trạng thái tải, và ranh giới lỗi được định nghĩa một cách khai báo. Server Components giảm kích thước bundle JavaScript bằng cách render component trên server.

API Routes cho phép tạo các endpoint API trong cùng ứng dụng Next.js. Điều này hữu ích cho mẫu backend-for-frontend, nơi frontend cần lớp API để tổng hợp dữ liệu từ nhiều service. API Routes có thể xử lý xác thực, chuyển đổi dữ liệu, và bộ nhớ đệm.

=== 3.8.2 React

React là một thư viện JavaScript để xây dựng giao diện người dùng, được phát triển bởi Facebook. React sử dụng kiến trúc dựa trên component, nơi UI được chia thành các component có thể tái sử dụng. React đã trở thành một trong những thư viện frontend phổ biến nhất với hệ sinh thái rộng lớn.

Kiến trúc dựa trên component cho phép xây dựng UI phức tạp từ các phần nhỏ, độc lập. Mỗi component quản lý trạng thái và render của riêng nó. Các component có thể được kết hợp để tạo UI phức tạp. Điều này tăng khả năng tái sử dụng và bảo trì.

Virtual DOM là một trong những đổi mới của React. Thay vì thao tác DOM trực tiếp, React tạo biểu diễn ảo của DOM trong bộ nhớ. Khi trạng thái thay đổi, React tính toán các thay đổi tối thiểu cần thiết và cập nhật DOM theo lô. Điều này cải thiện hiệu suất đáng kể.

Hook là tính năng được giới thiệu trong React 16.8, cho phép sử dụng trạng thái và tính năng vòng đời trong các functional component. useState cho trạng thái cục bộ, useEffect cho tác dụng phụ, useContext cho tiêu thụ context. Hook làm cho mã ngắn gọn và dễ kiểm thử hơn class component.

=== 3.8.3 TypeScript

TypeScript là một tập cha của JavaScript thêm kiểu tĩnh. TypeScript được phát triển bởi Microsoft và đã trở thành tiêu chuẩn cho các ứng dụng JavaScript quy mô lớn. Mã TypeScript được biên dịch thành JavaScript, có thể chạy trên bất kỳ runtime JavaScript nào.

Kiểu tĩnh là lợi ích chính của TypeScript. Các kiểu được kiểm tra tại thời điểm biên dịch, phát hiện lỗi trước khi mã chạy. Hỗ trợ IDE tốt hơn với tự động hoàn thành, tái cấu trúc, và điều hướng. Tài liệu được nhúng trong mã thông qua các kiểu.

Suy luận kiểu giảm mã boilerplate. TypeScript có thể suy luận kiểu từ ngữ cảnh, không cần chú thích mọi biến. Điều này cân bằng giữa tính an toàn kiểu và năng suất của nhà phát triển.

Interface và Type cho phép định nghĩa hình dạng của các đối tượng. Interface có thể mở rộng và triển khai. Union type và intersection type cho phép biểu đạt các mối quan hệ kiểu phức tạp. Generic cho phép mã có thể tái sử dụng và an toàn kiểu.

=== 3.8.4 Tailwind CSS

Tailwind CSS là một CSS framework utility-first, cung cấp các class tiện ích cấp thấp thay vì các component được thiết kế sẵn. Tailwind cho phép xây dựng thiết kế tùy chỉnh mà không cần viết CSS tùy chỉnh. Tailwind đã trở thành một trong những CSS framework phổ biến nhất cho phát triển web hiện đại.

Phương pháp utility-first có nghĩa là styling được thực hiện bằng cách kết hợp các class tiện ích. Thay vì viết CSS tùy chỉnh cho mỗi component, các nhà phát triển sử dụng các class được định nghĩa sẵn như flex, pt-4, text-center. Điều này tăng tốc độ phát triển và tính nhất quán.

Thiết kế responsive được tích hợp sẵn với các tiền tố responsive. Các class như md:flex chỉ áp dụng trên màn hình trung bình trở lên. Điều này làm cho thiết kế responsive dễ dàng và có thể dự đoán được.

Tùy chỉnh thông qua file cấu hình cho phép định nghĩa màu sắc, khoảng cách, phông chữ, và breakpoint tùy chỉnh. Tailwind có thể được điều chỉnh cho hệ thống thiết kế của dự án. Tích hợp PurgeCSS loại bỏ các style không sử dụng trong bản build sản xuất.


== 3.9 Containerization và Orchestration

=== 3.9.1 Docker

Docker là một nền tảng phục vụ việc phát triển, đóng gói và chạy ứng dụng trong môi trường container. Container là các gói thực thi nhẹ và độc lập, bao gồm toàn bộ thành phần cần thiết để chạy ứng dụng như mã nguồn, runtime, công cụ hệ thống, thư viện và cấu hình. Docker cho phép đóng gói ứng dụng cùng toàn bộ phụ thuộc của nó thành các image container, có thể chạy nhất quán trên mọi môi trường triển khai.

Công nghệ container giải quyết vấn đề "hoạt động trên máy của tôi". Với Docker, ứng dụng và môi trường runtime của nó được đóng gói cùng nhau, đảm bảo hành vi nhất quán giữa các môi trường. Container chia sẻ kernel của hệ điều hành chủ nhưng được cô lập về hệ thống file, mạng và tiến trình. Nhờ đó, container nhẹ hơn nhiều so với máy ảo, khởi động nhanh và sử dụng ít tài nguyên.

Docker image là các template chỉ đọc chứa hướng dẫn để tạo container. Image được xây dựng từ Dockerfile, một file văn bản chứa các lệnh để lắp ráp image. Image có thể được phân lớp, mỗi hướng dẫn tạo một lớp. Các lớp được lưu trữ tạm và chia sẻ giữa các image, giảm dung lượng lưu trữ và thời gian xây dựng.

Docker Compose cho phép định nghĩa và chạy các ứng dụng đa container. File Compose định nghĩa các service, mạng, và volume. Một lệnh có thể khởi động tất cả service. Điều này đơn giản hóa việc phát triển và kiểm thử các ứng dụng microservice.

=== 3.9.2 Kubernetes

Kubernetes là một nền tảng điều phối container, tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng được đóng gói trong container. Kubernetes được phát triển ban đầu bởi Google và hiện được duy trì bởi Cloud Native Computing Foundation. Hệ thống này quản lý các cụm máy và lập lịch container trong pod lên từng node, đồng thời xử lý cân bằng tải, khám phá service, cập nhật luân phiên và tự phục hồi.

Khả năng điều phối của Kubernetes bao gồm nhiều thành phần. Pod là đơn vị triển khai nhỏ nhất, có thể chứa một hoặc nhiều container. Service cung cấp mạng ổn định và cân bằng tải cho pod. Deployment quản lý cập nhật luân phiên và rollback. ConfigMap và Secret được sử dụng để quản lý cấu hình và dữ liệu nhạy cảm. Ingress định tuyến lưu lượng bên ngoài đến service. Horizontal Pod Autoscaler tự động mở rộng pod dựa trên việc sử dụng tài nguyên.

Tự phục hồi là một trong những tính năng quan trọng của Kubernetes. Kubernetes tự động khởi động lại container bị crash, thay thế container khi node chết, và kill container không phản hồi kiểm tra sức khỏe. Điều này đảm bảo tính khả dụng cao mà không cần can thiệp thủ công.

Cấu hình khai báo cho phép định nghĩa trạng thái mong muốn của hệ thống trong các file YAML. Các controller của Kubernetes liên tục điều hòa trạng thái thực tế với trạng thái mong muốn. Điều này làm cho hạ tầng có thể tái tạo và được kiểm soát phiên bản.

== 3.10 Tổng kết

Chương này đã trình bày đầy đủ các nền tảng lý thuyết cần thiết để hiểu và đánh giá hệ thống SMAP. Các kiến trúc Microservice và Clean Architecture cung cấp khung tổng thể cho việc thiết kế hệ thống. Message Queue và giao tiếp thời gian thực giải quyết các vấn đề về giao tiếp bất đồng bộ và thời gian thực. Các công nghệ cơ sở dữ liệu với Polyglot Persistence cho phép tối ưu hóa lưu trữ dữ liệu. Xác thực và bảo mật đảm bảo tính an toàn của hệ thống. Các công nghệ backend như Go, Gin, SQLBoiler, Python, FastAPI cung cấp nền tảng để xây dựng các service. Các công nghệ frontend như Next.js, React, TypeScript, Tailwind CSS cho phép xây dựng giao diện người dùng hiện đại. Cuối cùng, Docker và Kubernetes cung cấp công cụ để đóng gói container và điều phối.

Những kiến thức này sẽ là nền tảng cho Chương 4, nơi phân tích các yêu cầu hệ thống của SMAP, và Chương 5, nơi phân tích thiết kế chi tiết hệ thống, áp dụng các nguyên tắc và công nghệ đã được trình bày trong chương này.
