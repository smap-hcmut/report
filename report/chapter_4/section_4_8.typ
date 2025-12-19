// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.8 Sơ đồ tuần tự (Sequence Diagram)

=== Sơ đồ tuần tự UC-01: Cấu hình Project theo dõi

#image("../images/sequence/1.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-01_])
#image_counter.step()

Sơ đồ tuần tự mô tả tương tác giữa Client, Project Service và Database trong quá trình cấu hình Project. Client gửi request POST /projects với thông tin project, Project Service validate dữ liệu và lưu vào Database với status=Draft, sau đó trả về response chứa project_id cho Client.

=== Sơ đồ tuần tự UC-02: Kiểm tra từ khóa (Dry-run)

#image("../images/sequence/2.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-02_])
#image_counter.step()

Sơ đồ tuần tự mô tả luồng dry-run từ khóa qua các services. Client gửi POST /projects/dryrun, Project Service tạo job_id và publish message lên RabbitMQ. Collector Service nhận message, dispatch đến Crawler Workers để thu thập mẫu dữ liệu. Kết quả được gửi về qua webhook đến Project Service, sau đó publish lên Redis Pub/Sub. WebSocket Service subscribe và gửi kết quả real-time đến Client qua WebSocket connection.

=== Sơ đồ tuần tự UC-03: Khởi chạy và theo dõi Project

#image("../images/sequence/3.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-03_])
#image_counter.step()

Sơ đồ tuần tự mô tả quá trình khởi chạy Project với các pha xử lý. Client gửi POST /projects/{id}/start, Project Service cập nhật status=Running và publish message lên RabbitMQ. Collector Service điều phối Crawler Workers thu thập dữ liệu, sau đó gửi đến AI/ML Service để phân tích. Tiến độ từng pha được publish lên Redis Pub/Sub và WebSocket Service gửi real-time updates đến Client. Khi hoàn tất, Project Service cập nhật status=Completed.

=== Sơ đồ tuần tự UC-04: Xem kết quả phân tích

#image("../images/sequence/4.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-04_])
#image_counter.step()

Sơ đồ tuần tự mô tả quá trình xem kết quả phân tích. Client gửi GET /projects/{id}/results, Project Service truy vấn Database lấy kết quả phân tích bao gồm KPIs, sentiment trends, aspects và competitor comparison, sau đó trả về cho Client để hiển thị trên dashboard.

=== Sơ đồ tuần tự UC-05: Quản lý danh sách Projects

#image("../images/sequence/5.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-05_])
#image_counter.step()

Sơ đồ tuần tự mô tả quá trình quản lý danh sách Projects. Client gửi GET /projects với các filter parameters, Project Service truy vấn Database lấy danh sách projects của user kèm trạng thái, sau đó trả về cho Client. Client có thể thực hiện các thao tác như chỉnh sửa Draft (PUT /projects/{id}), xóa (DELETE /projects/{id}) hoặc điều hướng đến các use case khác.

=== Sơ đồ tuần tự UC-06: Xuất báo cáo

#image("../images/sequence/6.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-06_])
#image_counter.step()

Sơ đồ tuần tự mô tả quá trình xuất báo cáo. Client gửi POST /projects/{id}/export với format và nội dung mong muốn, Project Service tạo export job và trả về job_id. Hệ thống xử lý bất đồng bộ, generate báo cáo (PDF/PPTX/Excel) và lưu vào MinIO. Khi hoàn tất, gửi notification qua WebSocket với download link. Nếu timeout hoặc file quá lớn, hệ thống fallback sang summary-only mode.

=== Sơ đồ tuần tự UC-07: Phát hiện trend tự động

#image("../images/sequence/8.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ tuần tự UC-07_])
#image_counter.step()

Sơ đồ tuần tự mô tả quá trình phát hiện trend tự động theo lịch. Scheduler trigger TrendRun job, gửi message lên RabbitMQ. Collector Service dispatch đến Crawler Workers thu thập trend data từ các platforms. AI/ML Service tính score và xếp hạng trends theo engagement/velocity. Kết quả được lưu vào Database và publish notification lên Redis Pub/Sub. WebSocket Service gửi thông báo có feed trend mới đến Client, cho phép truy cập Trend Dashboard.

