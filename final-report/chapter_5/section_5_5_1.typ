#import "../counters.typ": image_counter, table_counter

=== 5.5.1 UC-01: Cấu hình Project

Trong bộ use case hiện tại ở Chương 4, UC-01 được hiểu là mục tiêu thiết lập một chiến dịch theo dõi đủ điều kiện vận hành. Ở mức sequence, mục tiêu này được cụ thể hóa qua ba interaction flows chính: tạo campaign và project, khai báo nguồn dữ liệu cùng mục tiêu thu thập, và thực hiện kiểm tra thử khi cần.

Điểm chung của các flow trong mục này là chúng chỉ hoàn tất phần cấu hình đầu vào. Hệ thống chưa bước sang giai đoạn vận hành chính thức cho đến khi người dùng chủ động chuyển sang UC-02.

==== 5.5.1.1 Tạo campaign và project

Luồng này mô tả phần đầu của mục tiêu thiết lập chiến dịch, nơi người dùng tạo campaign mới hoặc gắn project vào campaign đã tồn tại.

#align(center)[
  #image("../images/chapter_5/seq-uc01-campaign-project-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01 Part 1: Tạo campaign và project_])
#image_counter.step()

Luồng xử lý:

- User bắt đầu một chiến dịch theo dõi mới hoặc chọn campaign đã tồn tại làm ngữ cảnh nghiệp vụ.

- Giao diện gửi request tạo campaign hoặc project đến Project Service kèm thông tin nhận diện đối tượng theo dõi.

- Project Service kiểm tra dữ liệu đầu vào, lưu campaign nếu cần và tạo project gắn với campaign tương ứng.

- Hệ thống trả lại campaign_id, project_id và trạng thái cấu hình ban đầu để người dùng tiếp tục thiết lập các thành phần còn lại.

Điểm quan trọng: Việc tạo campaign và project chưa kích hoạt runtime thu thập hay xử lý nền. Đây mới là bước thiết lập business context cho chiến dịch.

==== 5.5.1.2 Khai báo nguồn dữ liệu và mục tiêu thu thập

Luồng này tiếp nối ngay sau khi project đã tồn tại, tập trung vào việc khai báo datasource và target cần thu thập cho chiến dịch.

#align(center)[
  #image("../images/chapter_5/seq-uc01-datasource-target-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01 Part 2: Khai báo nguồn dữ liệu và mục tiêu thu thập_])
#image_counter.step()

Luồng xử lý:

- User mở phần cấu hình nguồn dữ liệu của project vừa tạo.

- Giao diện gửi request đến Ingest Service để tạo datasource theo loại nền tảng hoặc nguồn dữ liệu phù hợp.

- User tiếp tục khai báo một hoặc nhiều mục tiêu thu thập như keyword, profile hoặc post URL.

- Ingest Service kiểm tra loại mục tiêu, lưu datasource và target tương ứng, đồng thời cập nhật trạng thái cấu hình phục vụ bước readiness ở phía sau.

- Giao diện nhận lại metadata cần thiết để người dùng quyết định có cần thực hiện kiểm tra thử hay không.

==== 5.5.1.3 Kiểm tra thử và đánh giá mức sẵn sàng

Luồng này phản ánh nhánh kiểm tra thử của UC-01, chỉ được thực hiện khi tổ hợp nguồn dữ liệu và mục tiêu thu thập yêu cầu bước xác nhận trước khi vận hành.

#align(center)[
  #image("../images/chapter_5/seq-uc01-dryrun-readiness-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-01 Part 3: Kiểm tra thử và đánh giá mức sẵn sàng_])
#image_counter.step()

Luồng xử lý:

- User yêu cầu chạy kiểm tra thử cho một tổ hợp datasource-target đã khai báo.

- Ingest Service tạo yêu cầu dry run, ghi nhận trạng thái kiểm tra và chuyển tác vụ phù hợp xuống runtime thu thập nếu cần lấy mẫu.

- Runtime thu thập truy xuất dữ liệu mẫu hoặc xác nhận khả năng truy cập nguồn dữ liệu, sau đó trả kết quả về ingest lane.

- Ingest Service lưu kết quả kiểm tra thử gần nhất và lịch sử kiểm tra liên quan.

- Hệ thống cập nhật chỉ báo readiness của datasource hoặc target để người dùng đánh giá liệu chiến dịch đã đủ điều kiện bước sang UC-02 hay chưa.
