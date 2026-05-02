// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 5.5 Sơ đồ tuần tự

Sơ đồ tuần tự trong mục này minh họa các tương tác động giữa giao diện, các dịch vụ nghiệp vụ và các runtime lane của SMAP theo trình tự thời gian. Thay vì được đọc như một ánh xạ một-một tuyệt đối với từng bảng use case ở mục 4.4, các sơ đồ ở đây đóng vai trò lớp minh họa cho những interaction patterns quan trọng giữa business control plane, execution plane, analytics pipeline, knowledge retrieval và notification delivery.

Ở góc nhìn kiến trúc hiện tại, các sơ đồ tập trung làm rõ cách các thành phần trao đổi qua internal HTTP, RabbitMQ, Kafka và Redis Pub/Sub, cũng như cách metadata hoặc artifacts đi qua PostgreSQL, Redis, MinIO và Qdrant theo từng luồng xử lý. Các nhãn UC trong các tiểu mục bên dưới được dùng như mã tham chiếu của từng sơ đồ trong bộ tài liệu hiện có.

Các sơ đồ tuần tự trong mục này được tổ chức theo năm nhóm mục tiêu nghiệp vụ tương ứng với Chương 4:

- Thiết lập chiến dịch theo dõi.

- Vận hành chiến dịch theo dõi.

- Tra cứu và hỏi đáp dữ liệu phân tích.

- Theo dõi trạng thái và nhận cảnh báo.

- Thiết lập và quản lý quy tắc cảnh báo khủng hoảng.

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

=== Tổng kết

Section này mô tả các sequence diagrams dùng để minh họa cách SMAP hiện thực hóa các mục tiêu nghiệp vụ đã xác định ở Chương 4. Ở mức kỹ thuật, các sơ đồ làm rõ những tương tác quan trọng giữa giao diện, project context, ingest runtime, analytics pipeline, knowledge retrieval và notification delivery.

Bên trong mỗi nhóm mục tiêu nghiệp vụ, một số sơ đồ có thể đi sâu vào các subflow kỹ thuật như readiness validation, dispatch thu thập, xử lý nền, truy hồi tri thức hoặc phát thông báo. Mục tiêu của phần này không phải lặp lại logic use case ở Chương 4, mà là cho thấy các thành phần hệ thống phối hợp với nhau như thế nào để tạo ra kết quả quan sát được đối với người dùng.
