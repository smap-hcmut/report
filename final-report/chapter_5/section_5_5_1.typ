#import "../counters.typ": image_counter, table_counter

=== 5.5.1 UC-01: Cấu hình Project

UC-01 mô tả quy trình tạo mới một Project phân tích. Marketing Analyst định nghĩa scope phân tích thông qua việc cấu hình các từ khóa thương hiệu và từ khóa đối thủ, cùng với khoảng thời gian phân tích.

Project được lưu với trạng thái draft và không kích hoạt bất kỳ xử lý nào. Thiết kế này tuân thủ nguyên tắc explicit execution, tránh việc hệ thống tự động crawl dữ liệu khi người dùng chưa sẵn sàng.

#align(center)[
  #image("../images/sequence/uc1_cau_hinh_project.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01: Cấu hình Project_])
#image_counter.step()

Luồng xử lý chính:

- User điền thông tin Project qua wizard 4 bước: thông tin cơ bản, cấu hình thương hiệu, cấu hình đối thủ, và xác nhận.

- Web UI gửi POST request đến Project Service với JWT authentication.

- Project Service validate date range và lưu Project vào PostgreSQL với status draft.

- Trả về HTTP 201 Created với project_id để sử dụng cho các bước tiếp theo.

Điểm quan trọng: Việc tạo Project không trigger bất kỳ background processing nào. Không có Redis state initialization hay RabbitMQ event publishing ở bước này.
