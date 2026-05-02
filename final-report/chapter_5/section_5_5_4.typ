#import "../counters.typ": image_counter, table_counter

=== 5.5.4 UC-04: Theo dõi trạng thái và nhận cảnh báo

Trong bộ use case hiện tại ở Chương 4, UC-04 được hiểu là mục tiêu giúp người dùng theo dõi trạng thái vận hành của campaign, project hoặc nguồn dữ liệu và kịp thời nhận biết khi có sự kiện hoặc cảnh báo quan trọng. Ở mức sequence, mục tiêu này được cụ thể hóa qua hai interaction flows chính: quan sát trạng thái hiện tại và nhận thông báo hoặc cảnh báo khi hệ thống phát sinh sự kiện liên quan.

Điểm chung của các flow trong mục này là người dùng chỉ quan sát và phản ứng; giao diện không trực tiếp thay đổi trạng thái vận hành. Các thao tác thay đổi vòng đời vẫn thuộc UC-02.

==== 5.5.4.1 Quan sát trạng thái hiện tại

Luồng này mô tả cách người dùng mở khu vực theo dõi và xem trạng thái hiện tại của campaign, project, nguồn dữ liệu hoặc các quá trình xử lý liên quan.

#align(center)[
  #image("../images/chapter_5/seq-uc04-status-observation-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 1: Quan sát trạng thái hiện tại_])
#image_counter.step()

Luồng xử lý:

- User mở dashboard hoặc khu vực theo dõi của một campaign hay project.

- Giao diện gửi request lấy trạng thái hiện tại trong phạm vi user được phép theo dõi.

- Hệ thống kiểm tra quyền truy cập và xác định campaign, project hoặc nguồn dữ liệu nào được phép hiển thị.

- Dịch vụ tương ứng trả về trạng thái hiện tại, thời điểm cập nhật gần nhất và các metadata cần thiết để giao diện biểu diễn ngữ cảnh vận hành.

- Giao diện hiển thị trạng thái hiện tại để user đánh giá và quyết định có cần mở sâu hơn hay thực hiện thao tác ở use case khác hay không.

Điểm quan trọng: Flow này tập trung vào khả năng quan sát trạng thái, không đồng nghĩa rằng hệ thống đang phát sinh cảnh báo mới ở thời điểm user truy cập.

==== 5.5.4.2 Nhận thông báo và cảnh báo

Luồng này mô tả cách hệ thống phân loại sự kiện, route thông báo và hiển thị nội dung cảnh báo cho user trong phạm vi được phép theo dõi.

#align(center)[
  #image("../images/chapter_5/seq-uc04-notification-delivery-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 2: Nhận thông báo và cảnh báo_])
#image_counter.step()

Luồng xử lý:

- Khi có trạng thái mới, lỗi xử lý hoặc cảnh báo nghiệp vụ trong phạm vi theo dõi, backend publisher phát sinh notification event tương ứng.

- Notification Service nhận message đầu vào, parse loại sự kiện và xác định recipient hoặc scope liên quan.

- Hệ thống chuẩn hóa payload cảnh báo, route về connection hub hoặc lane delivery phù hợp nếu có active compatible connection.

- Nếu user đang có phiên nhận thông báo hợp lệ, hệ thống hiển thị thông báo trên giao diện hoặc cập nhật lớp presentation tương ứng.

- User xem nội dung tóm tắt, mở chi tiết cảnh báo hoặc điều hướng đến campaign/project liên quan để tiếp tục đánh giá tình hình.

Điểm quan trọng: Flow này mô tả delivery capability của hệ thống khi có sự kiện và khi có phiên nhận thông báo phù hợp. Nó không mặc định khẳng định mọi loại giao diện trong mọi thời điểm đều đang tiêu thụ trực tiếp cùng một kênh realtime.
