// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.5 Sơ đồ hoạt động (Activity Diagram)

=== Biểu đồ hoạt động cho UC-01: Cấu hình Project theo dõi

#image("../images/activity/1.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-01_])
#image_counter.step()

Sơ đồ mô tả luồng cấu hình Project theo dõi thương hiệu. Brand Manager nhập thông tin cơ bản (tên, mô tả, thời gian), cấu hình từ khóa thương hiệu và đối thủ, chọn nền tảng (YouTube, TikTok) và giới hạn thu thập. Người dùng có thể thực hiện dry-run để kiểm tra từ khóa trước khi lưu. Hệ thống validate và lưu Project ở trạng thái Draft nếu hợp lệ, hoặc hiển thị lỗi yêu cầu sửa.

=== Biểu đồ hoạt động cho UC-02: Kiểm tra từ khóa (Dry-run)

#image("../images/activity/2.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02_])
#image_counter.step()

Sơ đồ mô tả luồng dry-run kiểm tra từ khóa. Khi người dùng bấm "Dry-run", Project Service tạo job_id, lưu mapping vào Redis và gửi message đến RabbitMQ. Collector Service dispatch task đến Crawler Workers (YouTube/TikTok) để crawl mẫu 3 bài viết/từ khóa với đầy đủ metadata, content, interaction, author và comments. Kết quả được gửi về qua webhook đến Project Service, sau đó publish lên Redis Pub/Sub. WebSocket Service nhận và gửi đến client qua WebSocket. Client hiển thị kết quả mẫu để người dùng đánh giá và điều chỉnh từ khóa nếu cần.

=== Biểu đồ hoạt động cho UC-03: Khởi chạy và theo dõi Project

#image("../images/activity/3.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-03_])
#image_counter.step()

Sơ đồ mô tả luồng khởi chạy và theo dõi Project. Brand Manager chọn Project Draft và nhấn "Khởi chạy". Hệ thống chuyển status sang Running và thực thi 4 pha: Crawling (thu thập dữ liệu), Analyzing (phân tích sentiment và aspect), Aggregating (tổng hợp metrics), Finalizing (hoàn tất). Tiến độ real-time được hiển thị qua WebSocket. Nếu phát hiện crisis, hệ thống gửi cảnh báo tức thời. Người dùng có thể hủy Project (status=Cancelled) hoặc xử lý lỗi/timeout (status=Failed với failure_reason). Khi hoàn tất, status=Completed và cho phép xem kết quả.
