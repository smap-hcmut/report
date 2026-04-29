#import "../counters.typ": image_counter, table_counter

== 5.1 Phương pháp tiếp cận

Chương này trình bày cách hệ thống SMAP được thiết kế dựa trên các yêu cầu và ràng buộc đã phân tích ở Chương 4. Thay vì xem thiết kế như một tập hợp sơ đồ độc lập, chương này tiếp cận kiến trúc theo hướng design-from-drivers, tức lấy các yêu cầu chức năng, yêu cầu phi chức năng và ranh giới service hiện tại làm cơ sở để lựa chọn tổ chức thành phần, cơ chế giao tiếp, mô hình lưu trữ và phương thức triển khai.

Trong bối cảnh của SMAP, thiết kế không chỉ nhằm mô tả các thành phần của hệ thống, mà còn nhằm trả lời ba câu hỏi cốt lõi. Thứ nhất, mỗi service sở hữu capability nào và không nên gánh trách nhiệm nào. Thứ hai, dữ liệu đi qua các lane xử lý bằng cơ chế nào cho phù hợp với từng loại workload. Thứ ba, các quyết định kiến trúc đó phản hồi ra sao đối với các yêu cầu về hiệu năng, bảo mật, tính sẵn sàng, tính toàn vẹn dữ liệu và khả năng quan sát hệ thống.

=== 5.1.1 Architectural Drivers

Các architectural drivers chính của SMAP được kế thừa trực tiếp từ phần NFR ở Chương 4 và được xem như cơ sở định hướng cho các quyết định thiết kế ở chương này.

#context (align(center)[_Bảng #table_counter.display(): Các architectural drivers chính của SMAP_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.12fr, 0.25fr, 0.63fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*ID*],
    table.cell(align: center + horizon)[*Driver*],
    table.cell(align: center + horizon)[*Ý nghĩa thiết kế*],

    [AC-01],
    [Modularity],
    [Hệ thống cần được chia thành các bounded context rõ ràng để tránh coupling không cần thiết giữa business context, execution plane, analytics, knowledge và notification.],
    [AC-02],
    [Scalability],
    [Các lane có tải khác nhau như API, analytics consumer, worker runtime và notification delivery cần có khả năng mở rộng theo vai trò riêng.],
    [AC-03],
    [Performance],
    [Các xử lý nặng không nên nằm trong request path đồng bộ; các lane thời gian thực cần có độ trễ phù hợp với trải nghiệm sử dụng.],
    [AC-04],
    [Security],
    [Xác thực, quản lý phiên và internal validation cần được tổ chức thành security boundary rõ ràng.],
    [AC-05],
    [Availability],
    [Các workload quan trọng cần cơ chế health check, tách lane xử lý và khả năng khôi phục phù hợp để giảm blast radius.],
    [AC-06],
    [Data Integrity],
    [Các luồng bất đồng bộ phải duy trì liên kết nhất quán giữa task, completion metadata, raw artifacts và kết quả downstream.],
    [AC-07],
    [Observability],
    [Thiết kế cần hỗ trợ logging, metrics hoặc các operational indicators đủ để theo dõi và chẩn đoán lỗi runtime.],
  )
]

=== 5.1.2 Nguyên tắc thiết kế

Từ các architectural drivers trên, nhóm nguyên tắc thiết kế được sử dụng cho SMAP có thể tóm lược như sau:

1. Phân tách hệ thống theo bounded context và trách nhiệm nghiệp vụ rõ ràng.
2. Tổ chức service theo hướng có thể triển khai và mở rộng tương đối độc lập.
3. Chuyên biệt hóa transport theo workload thay vì dùng một cơ chế giao tiếp duy nhất cho toàn bộ hệ thống.
4. Tách business control plane khỏi execution plane và các lane xử lý nền.
5. Áp dụng polyglot persistence theo nhu cầu dữ liệu thực tế của từng lớp hệ thống.
6. Tách logic nghiệp vụ khỏi delivery và infrastructure layers để tăng khả năng bảo trì và kiểm thử.

Các nguyên tắc này không chỉ là lựa chọn mang tính lý thuyết, mà còn là khung dùng để đọc và giải thích các quyết định thiết kế ở những mục tiếp theo. Chúng giúp lý giải vì sao hệ thống không được tổ chức theo một khối thống nhất, vì sao nhiều loại storage cùng tồn tại, và vì sao mỗi lane xử lý lại gắn với một cơ chế giao tiếp khác nhau.

=== 5.1.3 Liên hệ với SMAP

Trong architecture của SMAP, các nguyên tắc trên được phản ánh khá rõ. `project-srv` giữ business context, trong khi `ingest-srv` đảm nhiệm execution plane. `analysis-srv` xử lý analytics pipeline ở lane bất đồng bộ tách khỏi request path. `knowledge-srv` và `notification-srv` tạo thành các lớp khai thác kết quả và delivery. Ở mức storage, hệ thống đồng thời sử dụng PostgreSQL, Redis, Qdrant và MinIO theo vai trò chuyên biệt. Ở mức giao tiếp, internal HTTP, RabbitMQ, Kafka và Redis Pub/Sub cùng tồn tại như các transport được chọn theo tính chất workload.

Những đặc điểm này cho thấy thiết kế của SMAP không nên được đọc như một bản áp dụng máy móc của một pattern duy nhất, mà là kết quả của nhiều quyết định phối hợp để phản hồi trực tiếp với các yêu cầu và ràng buộc của hệ thống hiện tại. Đây cũng là cơ sở để các mục sau đi sâu vào kiến trúc tổng thể, dữ liệu, giao tiếp, triển khai và truy xuất nguồn gốc thiết kế.
