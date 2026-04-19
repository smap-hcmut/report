#import "../counters.typ": table_counter

== 3.4 Real-time Communication

=== 3.4.1 WebSocket Protocol

WebSocket là một giao thức giao tiếp cung cấp các kênh giao tiếp song công qua một kết nối TCP duy nhất. Khác với HTTP truyền thống theo mô hình request-response, WebSocket cho phép server đẩy dữ liệu đến client bất cứ lúc nào mà không cần client yêu cầu. Điều này làm cho WebSocket lý tưởng cho các ứng dụng thời gian thực như chat, thông báo, cập nhật trực tiếp, và chỉnh sửa cộng tác. WebSocket được chuẩn hóa bởi IETF theo RFC 6455 và được hỗ trợ rộng rãi bởi tất cả trình duyệt hiện đại.

Giao tiếp song công có nghĩa là cả client và server đều có thể gửi message độc lập với nhau cùng một lúc. Không giống như HTTP polling nơi client phải liên tục gửi request để kiểm tra cập nhật, với WebSocket, server có thể đẩy cập nhật ngay khi có dữ liệu mới. Điều này giảm độ trễ đáng kể và giảm chi phí của việc thiết lập kết nối liên tục. Một khi kết nối WebSocket được thiết lập, nó được giữ mở cho đến khi một trong hai bên đóng nó, cho phép giao tiếp hai chiều với chi phí tối thiểu.

Quá trình bắt tay WebSocket bắt đầu với một HTTP request đặc biệt từ client. Client gửi HTTP GET request với các header đặc biệt: Upgrade websocket và Connection Upgrade, cùng với Sec-WebSocket-Key để bảo mật. Nếu server hỗ trợ WebSocket, nó phản hồi với mã trạng thái 101 Switching Protocols và các header tương ứng. Sau khi bắt tay thành công, kết nối được nâng cấp từ HTTP sang giao thức WebSocket, và cả hai bên có thể bắt đầu gửi WebSocket frame. Frame là đơn vị dữ liệu nhỏ nhất trong WebSocket, có thể chứa dữ liệu văn bản hoặc nhị phân, và có chi phí rất thấp chỉ 2-14 byte mỗi frame.

Độ trễ thấp là một trong những ưu điểm lớn nhất của WebSocket. Vì kết nối được giữ mở, không có chi phí của TCP handshake và HTTP header cho mỗi message. Message được gửi ngay lập tức khi có dữ liệu, không cần polling. Trong thực tế, WebSocket có thể đạt độ trễ dưới 10ms trong mạng cục bộ và 50-100ms qua internet, tùy thuộc vào điều kiện mạng.

=== 3.4.2 Redis Pub/Sub

Redis Pub/Sub là một hệ thống nhắn tin được tích hợp sẵn trong Redis, cho phép publisher gửi message đến channel và subscriber nhận message từ channel họ đăng ký. Redis Pub/Sub hoạt động hoàn toàn trong bộ nhớ, không có tính bền vững, và sử dụng ngữ nghĩa "bắn và quên", message được gửi đến subscriber đang trực tuyến, nếu không có subscriber nào, message bị loại bỏ. Điều này làm cho Redis Pub/Sub rất nhanh nhưng không đáng tin cậy như hàng đợi message truyền thống.

Việc truyền thông điệp trong bộ nhớ là lý do Redis Pub/Sub có độ trễ cực thấp. Vì tất cả thao tác diễn ra trong RAM và không có I/O đĩa, message được gửi rất nhanh. Redis có thể xử lý lượng lớn message trên phần cứng tiêu chuẩn. Điều này làm cho Redis Pub/Sub phù hợp với các trường hợp sử dụng cần độ trễ thấp, như thông báo thời gian thực, dashboard trực tiếp và ứng dụng chat.

Đăng ký theo mẫu là một tính năng mạnh mẽ của Redis Pub/Sub. Thay vì đăng ký đến một channel cụ thể, subscriber có thể đăng ký đến một mẫu sử dụng ký tự đại diện. Điều này cho phép định tuyến linh hoạt mà không cần tạo nhiều đăng ký.

Ngữ nghĩa Fire and Forget có nghĩa là Redis không đảm bảo việc gửi message. Nếu không có subscriber nào đang lắng nghe channel khi message được phát hành, message bị mất. Nếu subscriber đang xử lý message và gặp sự cố, message cũng bị mất. Redis không có tính bền vững message, cơ chế xác nhận hay cơ chế thử lại. Điều này là sự đánh đổi cho hiệu suất, khi hệ thống ưu tiên độ trễ thấp hơn các đảm bảo về độ tin cậy.

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
    table.cell(align: center + horizon)[Rất thấp],
    table.cell(align: center + horizon)[Thấp],
    table.cell(align: center + horizon)[Cao],
    table.cell(align: center + horizon)[Rất thấp],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Browser Support],
    table.cell(align: center + horizon)[Xuất sắc, trình duyệt hiện đại],
    table.cell(align: center + horizon)[Tốt, không hỗ trợ IE],
    table.cell(align: center + horizon)[Phổ quát],
    table.cell(align: center + horizon)[Cần thư viện hỗ trợ],

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

Những khái niệm và so sánh trên là cơ sở để phân tích các lựa chọn giao tiếp thời gian thực trong SMAP, đặc biệt ở lớp WebSocket delivery và lớp fanout nội bộ dựa trên Redis Pub/Sub.
