// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.5 Sơ đồ tuần tự

Sơ đồ tuần tự trong mục này minh họa các tương tác động giữa giao diện, các dịch vụ nghiệp vụ và các runtime lane của SMAP theo trình tự thời gian. Thay vì được đọc như một ánh xạ một-một tuyệt đối với từng bảng use case ở mục 4.4, các sơ đồ ở đây đóng vai trò lớp minh họa cho những mẫu tương tác quan trọng giữa business control plane, execution plane, analytics pipeline, knowledge retrieval và notification delivery.

Ở góc nhìn kiến trúc hiện tại, các sơ đồ tập trung làm rõ cách các thành phần trao đổi qua internal HTTP, RabbitMQ, Kafka và Redis Pub/Sub, cũng như cách metadata hoặc artifacts đi qua PostgreSQL, Redis, MinIO và Qdrant theo từng luồng xử lý. Các nhãn UC trong các tiểu mục bên dưới được dùng như mã tham chiếu của từng sơ đồ trong bộ tài liệu hiện có.

Các sơ đồ tuần tự được chia thành 3 nhóm minh họa chính:

- Nhóm thiết lập và quản lý ngữ cảnh nghiệp vụ: các luồng tạo hoặc cấu hình project và quản lý danh sách theo dõi.

- Nhóm điều phối runtime và xử lý dữ liệu: các luồng dry run, kích hoạt hoặc theo dõi runtime, phân tích dữ liệu và hiển thị kết quả.

- Nhóm delivery và khai thác đầu ra: các luồng báo cáo, cảnh báo, trend hoặc crisis monitoring, cùng các tương tác hướng người dùng ở lớp khai thác kết quả.

#import "section_5_5_1.typ" as section_5_5_1
#section_5_5_1

#import "section_5_5_2.typ" as section_5_5_2
#section_5_5_2

#import "section_5_5_3.typ" as section_5_5_3
#section_5_5_3

#import "section_5_5_4.typ" as section_5_5_4
#section_5_5_4

#import "section_5_5_5.typ" as section_5_5_5
#section_5_5_5

#import "section_5_5_6.typ" as section_5_5_6
#section_5_5_6

#import "section_5_5_7.typ" as section_5_5_7
#section_5_5_7

#import "section_5_5_8.typ" as section_5_5_8
#section_5_5_8

=== Tổng kết

Section này đã mô tả các Sequence Diagrams cho 8 Use Cases chính của hệ thống SMAP:

- UC-01 Cấu hình Project: Luồng tạo project với draft status.

- UC-02 Dry-run: Sampling strategy để test keywords.

- UC-03 Khởi chạy và Giám sát: Transaction-like flow với rollback mechanism.

- UC-04 Xem kết quả: Dashboard aggregations và drilldown.

- UC-05 Quản lý danh sách Projects: List view với filtering, sorting, status-based navigation và soft delete.

- UC-06 Xuất báo cáo: Async export workflow với multiple formats (PDF, Excel, CSV) và MinIO storage.

- UC-07 Trend Detection: Cron-based crawling với scoring.

- UC-08 Crisis Detection: Triple-check logic với multi-channel alerting.

Các sequence diagrams thể hiện rõ event-driven architecture, async processing patterns, và real-time communication mechanisms của hệ thống.
