// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.5 Sơ đồ tuần tự

Sơ đồ tuần tự cụ thể hóa các tương tác động giữa các thành phần hệ thống theo trình tự thời gian cho các Use Case đã được đặc tả ở mục 4.4. Các sơ đồ này làm rõ cơ chế giao tiếp giữa Web UI, các dịch vụ nghiệp vụ, hệ thống lưu trữ (PostgreSQL, MongoDB, Redis, MinIO) và hàng đợi thông điệp (RabbitMQ).

Các sơ đồ tuần tự được chia thành 3 nhóm chức năng chính:

- Nhóm Quản lý Project (UC-01, UC-05): Cấu hình và quản lý danh sách Projects, bao gồm tạo mới, xem danh sách, lọc và điều hướng theo trạng thái.

- Nhóm Thực thi và Phân tích (UC-02, UC-03, UC-04): Quy trình dry-run kiểm tra keywords, khởi chạy và giám sát Project với tiến độ real-time, và truy vấn kết quả phân tích trên dashboard.

- Nhóm Báo cáo và Cảnh báo (UC-06, UC-07, UC-08): Xuất báo cáo ở nhiều định dạng, phát hiện trend tự động theo cron job, và cảnh báo khủng hoảng thương hiệu.

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
