#import "../counters.typ": table_counter

== 3.3 Message Queue và Event-Driven Architecture

=== 3.3.1 Khái niệm Message Queue

Message Queue là một cơ chế giao tiếp bất đồng bộ cho phép các thành phần trong hệ thống phân tán trao đổi thông tin mà không cần kết nối trực tiếp với nhau. Trong mô hình này, producer đưa message vào queue, còn consumer lấy message ra để xử lý. Queue đóng vai trò như một bộ đệm trung gian, lưu trữ message cho đến khi consumer sẵn sàng tiếp nhận. Nhờ đó, hệ thống đạt được sự tách biệt về thời gian, khi producer và consumer không cần trực tuyến cùng lúc, và tách biệt về không gian, khi chúng không cần biết trực tiếp về địa chỉ hay cách triển khai của nhau.

Message Queue mang lại nhiều lợi ích quan trọng cho hệ thống phân tán. Xử lý bất đồng bộ cho phép producer tiếp tục công việc ngay sau khi gửi message mà không cần chờ xử lý hoàn tất. Cân bằng tải giúp hệ thống hấp thụ các đợt tăng lưu lượng đột ngột bằng cách xếp hàng và xử lý dần. Độ tin cậy được cải thiện thông qua lưu trữ message và cơ chế thử lại. Khả năng mở rộng cũng tốt hơn vì có thể tăng số lượng consumer để xử lý song song khi cần.

=== 3.3.2 RabbitMQ

RabbitMQ là một message broker mã nguồn mở phổ biến, triển khai AMQP, một giao thức chuẩn cho middleware hướng message. RabbitMQ đóng vai trò trung gian giữa producer và consumer, nhận message từ producer, định tuyến chúng đến đúng queue và chuyển giao đến consumer. RabbitMQ hỗ trợ nhiều mẫu nhắn tin khác nhau thông qua các loại exchange, cơ chế xác nhận và các queue durable để tăng độ tin cậy trong xử lý bất đồng bộ.

Kiến trúc của RabbitMQ bao gồm một số thành phần chính. Exchange nhận message từ producer và định tuyến đến queue dựa trên quy tắc định tuyến. Queue lưu trữ message cho đến khi consumer tiêu thụ. Binding định nghĩa quan hệ giữa exchange và queue. Routing key là thuộc tính của message được exchange sử dụng để quyết định định tuyến. Channel là kết nối ảo trong một kết nối TCP, giúp ghép nhiều thao tác trên cùng một kết nối vật lý.

RabbitMQ hỗ trợ bốn loại exchange chính. Fanout exchange phát sóng message đến tất cả queue được liên kết. Direct exchange định tuyến dựa trên khớp chính xác giữa routing key và binding key. Topic exchange định tuyến dựa trên mẫu với ký tự đại diện, phù hợp cho multicast có chọn lọc. Headers exchange định tuyến dựa trên header của message thay vì routing key. Sự linh hoạt này khiến RabbitMQ đặc biệt phù hợp với các bài toán task dispatch, workflow routing và request-response bất đồng bộ.

=== 3.3.3 Apache Kafka

Apache Kafka là một nền tảng event streaming phân tán được thiết kế cho thông lượng cao, khả năng lưu giữ message theo thời gian và xử lý dữ liệu theo dòng. Không giống với message queue truyền thống vốn nhấn mạnh vào việc chuyển giao message đến consumer rồi xóa đi, Kafka lưu message trong log bất biến theo từng topic và partition, cho phép nhiều consumer group đọc lại cùng một dòng sự kiện ở các tốc độ khác nhau.

Các khái niệm trung tâm của Kafka gồm topic, partition, offset và consumer group. Topic là luồng dữ liệu logic. Partition chia topic thành các đoạn độc lập để tăng khả năng song song hóa. Offset xác định vị trí của từng message trong partition. Consumer group cho phép nhiều consumer cùng phối hợp đọc một topic theo cách phân chia tải giữa các partition. Nhờ đó, Kafka vừa hỗ trợ throughput cao, vừa hỗ trợ replay, retention và tích hợp downstream hiệu quả.

Kafka thường phù hợp với các bài toán event propagation, analytics pipeline, audit stream và downstream processing. Khi dữ liệu cần được phát hành cho nhiều hệ thống tiêu thụ độc lập, cần giữ lại theo thời gian, hoặc cần replay lại để xử lý sau này, Kafka thường phù hợp hơn RabbitMQ. Tuy nhiên, Kafka cũng kéo theo độ phức tạp vận hành cao hơn và không phải lúc nào cũng là lựa chọn tối ưu cho task queue truyền thống.

=== 3.3.4 Producer-Consumer Pattern

Producer-Consumer pattern là một mẫu nhắn tin cơ bản trong đó producer tạo message và đưa vào queue hoặc stream, còn consumer nhận message ra để xử lý. Mẫu này tạo ra sự tách biệt rõ giữa bên phát sinh công việc và bên xử lý công việc. Producer có thể tạo message với tốc độ của mình, consumer có thể tiêu thụ theo tốc độ riêng, còn lớp trung gian giúp hấp thụ sự chênh lệch tải.

Cân bằng tải là một lợi ích quan trọng của mẫu này. Khi có nhiều consumer cùng tiêu thụ từ một queue hoặc cùng tham gia một consumer group, khối lượng công việc có thể được phân chia giữa chúng. Điều này cho phép mở rộng theo chiều ngang, giảm nguy cơ nghẽn cục bộ và giúp hệ thống phản ứng tốt hơn khi lưu lượng tăng cao.

=== 3.3.5 Publish/Subscribe và Event-Driven Architecture

Publish/Subscribe là một mẫu giao tiếp trong đó publisher phát hành message đến một chủ đề hoặc một exchange, còn subscriber nhận các message mà mình quan tâm. Khác với task queue một-một, trong mẫu này cùng một message có thể được nhiều thành phần tiếp nhận và xử lý độc lập. Điều này đặc biệt hữu ích khi một sự kiện cần kích hoạt nhiều hành vi downstream khác nhau.

Publish/Subscribe là một trong những cơ chế quan trọng thường được sử dụng trong các kiến trúc hướng sự kiện. Trong event-driven architecture, các thành phần giao tiếp với nhau thông qua event thay vì gọi trực tiếp lẫn nhau trong mọi tình huống. Khi một thay đổi trạng thái hoặc một hành vi đáng chú ý xảy ra, service phát hành event. Các service khác có thể đăng ký để phản ứng tương ứng mà không cần phụ thuộc trực tiếp vào service phát hành.

Ưu điểm của cách tiếp cận này là tăng loose coupling, hỗ trợ mở rộng hệ thống theo chiều ngang và làm cho downstream integration linh hoạt hơn. Tuy nhiên, event-driven architecture cũng làm tăng độ phức tạp trong việc theo dõi luồng xử lý, đảm bảo thứ tự, kiểm soát trùng lặp và bảo vệ tính nhất quán dữ liệu giữa các service.

=== 3.3.6 Delivery Semantics và các lưu ý thiết kế

Khi thiết kế hệ thống bất đồng bộ, một vấn đề quan trọng là delivery semantics, tức cách hệ thống đảm bảo việc gửi và nhận message. Có ba mức thường gặp. At-most-once nghĩa là message được gửi tối đa một lần, có thể mất message nhưng tránh trùng lặp. At-least-once nghĩa là message sẽ được giao ít nhất một lần, chấp nhận khả năng trùng lặp để đổi lấy độ tin cậy cao hơn. Exactly-once là mục tiêu khó đạt hơn nhiều trong thực tế và thường đòi hỏi cơ chế điều phối phức tạp ở cả producer, broker và consumer.

Ngoài delivery semantics, một số khái niệm khác cũng rất quan trọng. Ordering quyết định message có được giữ đúng thứ tự hay không. Retention xác định message được giữ lại trong bao lâu để hỗ trợ replay hoặc audit. Idempotency giúp consumer xử lý an toàn khi cùng một message được gửi lại nhiều lần. Consumer group giúp nhiều consumer chia sẻ khối lượng xử lý nhưng cũng kéo theo các vấn đề về rebalance và offset management. Những yếu tố này có ảnh hưởng trực tiếp đến độ tin cậy và khả năng mở rộng của hệ thống.

=== 3.3.7 So sánh các Message Brokers

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

    table.cell(align: center + horizon, inset: (y: 0.6em))[Mô hình chính],
    table.cell(align: center + horizon)[Task queue và routing linh hoạt],
    table.cell(align: center + horizon)[Event streaming và log phân tán],
    table.cell(align: center + horizon)[Stream nhẹ trong hệ sinh thái Redis],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Throughput],
    table.cell(align: center + horizon)[Trung bình],
    table.cell(align: center + horizon)[Rất cao],
    table.cell(align: center + horizon)[Cao],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Latency],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Trung bình],
    table.cell(align: center + horizon)[Rất thấp],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Retention],
    table.cell(align: center + horizon)[Chủ yếu theo queue],
    table.cell(align: center + horizon)[Mạnh, log-based retention],
    table.cell(align: center + horizon)[Có, nhưng đơn giản hơn Kafka],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Ordering],
    table.cell(align: center + horizon)[Theo queue],
    table.cell(align: center + horizon)[Theo partition],
    table.cell(align: center + horizon)[Theo stream],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Use Cases],
    table.cell(align: center + horizon)[Task dispatch, RPC, workflow queue],
    table.cell(align: center + horizon)[Analytics pipeline, event propagation, replay],
    table.cell(align: center + horizon)[Streaming nhẹ, cache-adjacent workloads],
  )
]

RabbitMQ phù hợp cho các trường hợp sử dụng hàng đợi message truyền thống như hàng đợi tác vụ, request-response bất đồng bộ và các tình huống cần định tuyến linh hoạt. Kafka phù hợp hơn cho event propagation, analytics pipeline và các tình huống cần giữ message theo thời gian để downstream có thể tiêu thụ hoặc replay. Redis Streams là một lựa chọn nhẹ hơn khi hệ thống đã có Redis và cần thêm một lớp stream đơn giản, nhưng không thay thế hoàn toàn vai trò của RabbitMQ hay Kafka trong các bài toán lớn hơn.

Những khái niệm và so sánh trên là cơ sở để phân tích các lựa chọn truyền tin trong SMAP. Trong current architecture, hệ thống không hoàn toàn event-driven end-to-end, vì vẫn tồn tại các lane điều khiển đồng bộ qua internal HTTP. Tuy nhiên, RabbitMQ, Kafka và các mô hình event propagation vẫn đóng vai trò quan trọng ở các luồng xử lý bất đồng bộ và downstream integration.
