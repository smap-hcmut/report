#import "../counters.typ": image_counter, table_counter

=== 5.5.4 UC-04: Theo dõi trạng thái và nhận cảnh báo

Trong bộ use case hiện tại ở Chương 4, UC-04 được hiểu là mục tiêu giúp người dùng theo dõi trạng thái vận hành của campaign, project hoặc nguồn dữ liệu và kịp thời nhận biết khi có sự kiện hoặc cảnh báo quan trọng. Ở mức sequence, mục tiêu này được cụ thể hóa qua hai interaction flows chính là quan sát trạng thái hiện tại và nhận thông báo hoặc cảnh báo khi hệ thống phát sinh sự kiện liên quan. Bên cạnh đó, mục này bổ sung một supporting technical sequence để làm rõ cách cảnh báo khủng hoảng có thể được tạo ra từ chuỗi crawl và analytics trước khi đi vào notification lane.

Điểm chung của các flow trong mục này là người dùng chỉ quan sát và phản ứng; giao diện không trực tiếp thay đổi trạng thái vận hành. Các thao tác thay đổi vòng đời vẫn thuộc UC-02.

==== 5.5.4.1 Quan sát trạng thái hiện tại

Luồng này mô tả cách người dùng mở khu vực theo dõi và xem trạng thái hiện tại của campaign, project, nguồn dữ liệu hoặc các quá trình xử lý liên quan.

#align(center)[
  #image("../images/chapter_5/seq-uc04-status-observation-flow.svg", width: 89%)
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

==== 5.5.4.3 Supporting flow: phát hiện khủng hoảng từ dữ liệu crawl

Luồng này nối rõ phần xử lý nền đứng phía sau UC-04: dữ liệu được thu thập bởi execution plane, chuẩn hóa và đưa vào analytics pipeline; kết quả phân tích được đánh giá theo ngữ cảnh rule khủng hoảng của project; khi điều kiện cảnh báo khớp, hệ thống phát sinh `CRISIS_ALERT` để notification lane phân phối theo flow ở mục 5.5.4.2 và chi tiết giao tiếp ở mục 5.6.3.4.

#align(center)[
  #image("../images/chapter_5/seq-uc04-crisis-crawl-analytics-flow.svg", width: 92%)
]
#context (
  align(
    center,
  )[_Hình #image_counter.display(): Sequence Diagram UC-04 Supporting Flow: Crawl, phân tích và đánh giá khủng hoảng_]
)
#image_counter.step()

Luồng xử lý:

- Cấu hình cảnh báo khủng hoảng được Project Service quản lý theo project và được analytics lane sử dụng như rule context, bao gồm các nhóm rule như keyword, volume, sentiment hoặc influencer.

- Ingest Service dispatch task thu thập sang RabbitMQ; Scapper Worker thực thi crawl, materialize raw artifact vào MinIO và trả completion envelope về ingest lane.

- Ingest Service verify artifact, parse dữ liệu và publish các bản ghi chuẩn hóa vào Kafka analytics input để analytics pipeline tiêu thụ.

- Analysis Service chạy pipeline NLP, persist insight có cấu trúc và đánh giá các tín hiệu như sentiment, keyword, risk hoặc ngưỡng volume theo ngữ cảnh rule của project.

- Nếu điều kiện khủng hoảng được kích hoạt, Analysis Service tạo `CRISIS_ALERT` với severity, metric, threshold và affected aspects để đưa sang notification lane.

- Phần delivery cụ thể của alert không lặp lại trong supporting flow này; nó được mô tả ở flow notification delivery tại mục 5.5.4.2 và communication pattern tại mục 5.6.3.4.

Điểm quan trọng: Flow này mô tả quan hệ nhân quả giữa crawl, phân tích và cảnh báo, nhưng vẫn giữ đúng ranh giới use case. Người dùng không trực tiếp điều khiển analytics pipeline trong UC-04; họ quan sát kết quả cảnh báo được hệ thống phát sinh từ các lane xử lý nền.
