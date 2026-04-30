#import "../counters.typ": image_counter, table_counter

=== 5.5.6 UC-06: Xuất báo cáo

UC-06 mô tả quy trình xuất báo cáo phân tích ở nhiều định dạng (PDF, Excel, CSV). Marketing Analyst có thể tùy chỉnh nội dung báo cáo, chọn khoảng thời gian dữ liệu, và tải file về máy. Hệ thống xử lý export request bất đồng bộ để không block UI, sau đó thông báo cho user khi file sẵn sàng.

==== 5.5.6.1 Export Configuration và Request

#align(center)[
  #image("../images/sequence/uc6_export_part_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 1: Export Configuration và Submission_]
)
#image_counter.step()

Luồng xử lý:

- User đang xem Dashboard (UC-04) và click nút Xuất báo cáo.

- Web UI hiển thị Export Configuration Dialog với các options: định dạng file (PDF, Excel, CSV), khoảng thời gian dữ liệu (toàn bộ hoặc tùy chỉnh), sections cần export (Overview, Sentiment Analysis, Competitor Comparison, Crisis Posts).

- User chọn options và click Xuất báo cáo.

- Web UI validate input và gửi POST request đến Project Service endpoint POST /api/v1/projects/:id/export.

- Project Service verify ownership (project.created_by = user_id) và validate export configuration.

- Project Service tạo export_request record trong PostgreSQL với status pending và enqueue export job.

- Publish export.requested event vào RabbitMQ queue export.jobs.

- Trả về HTTP 202 Accepted với export_request_id, Web UI đóng dialog và hiển thị toast Báo cáo đang được tạo, bạn sẽ nhận thông báo khi hoàn tất.

==== 5.5.6.2 Report Generation và Storage

#align(center)[
  #image("../images/sequence/uc6_export_part_2_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 2-1: Report Generation Pipeline_])
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc6_export_part_2_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 2-2: Report Generation Pipeline_])
#image_counter.step()

Luồng xử lý:

- Export Worker Service consume export.requested event từ RabbitMQ.

- Query analytics data từ PostgreSQL dựa trên project_id và date_range filters.

- Generate report file theo định dạng được chọn:
  - PDF: Sử dụng template engine (e.g., WeasyPrint) để render HTML → PDF với charts và tables.
  - Excel: Sử dụng library (e.g., openpyxl) để tạo spreadsheet với multiple sheets.
  - CSV: Export raw data với comma-separated format.

- Upload generated file lên MinIO bucket reports/ với object key projects/{project_id}/exports/{export_request_id}.{format}.

- Generate pre-signed download URL với 7-day expiry từ MinIO.

- Update export_request record trong PostgreSQL: status = completed, download_url, file_size, completed_at = NOW().

- Publish export.completed event vào RabbitMQ với download_url payload.

==== 5.5.6.3 Notification và Download

#align(center)[
  #image("../images/sequence/uc6_export_part_3_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 3-1: User Notification và File Download_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc6_export_part_3_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-06 Part 3-2: User Notification và File Download_]
)
#image_counter.step()

Luồng xử lý:

- WebSocket Service consume export.completed event từ RabbitMQ hoặc receive notification qua Redis Pub/Sub.

- Forward notification message đến connected client (nếu user đang online).

- Web UI hiển thị notification banner Báo cáo của bạn đã sẵn sàng với link Download.

- User click Download link hoặc navigate đến Export History page.

- Web UI gửi GET request đến Project Service /api/v1/projects/:id/exports/:export_id.

- Project Service query export_request từ PostgreSQL, verify ownership và download_url chưa expire.

- Trả về download_url (MinIO pre-signed URL).

- Web UI trigger browser download từ MinIO URL, file được tải về máy user với tên {project_name}_report_{date}.{format}.

Exception Handling: Nếu export job fails (timeout > 10 phút, database error, out of memory), Export Worker update status = failed, reason, và publish export.failed event. User nhận notification Tạo báo cáo thất bại, vui lòng thử lại.
