#import "../counters.typ": table_counter

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
