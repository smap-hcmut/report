#import "../counters.typ": image_counter, table_counter

=== 5.5.2 UC-02: Vận hành chiến dịch theo dõi

Trong bộ use case hiện tại ở Chương 4, UC-02 được hiểu là mục tiêu đưa một chiến dịch đã được thiết lập sang trạng thái vận hành có kiểm soát. Ở mức sequence, mục tiêu này được thể hiện qua hai interaction flows chính: kiểm tra mức sẵn sàng trước khi kích hoạt và điều khiển các thao tác vận hành như tạm dừng, tiếp tục, lưu trữ hoặc mở lại chiến dịch.

Điểm chung của các flow trong mục này là Project Service giữ vai trò business control plane, còn Ingest Service giữ execution plane. Vì vậy, giao diện không điều khiển trực tiếp runtime thu thập dữ liệu mà luôn đi qua lớp lifecycle control của project.

==== 5.5.2.1 Kiểm tra mức sẵn sàng và kích hoạt chiến dịch

Luồng này mô tả cách người dùng kiểm tra readiness và kích hoạt một chiến dịch khi cấu hình đầu vào đã được thiết lập.

#align(center)[
  #image("../images/chapter_5/seq-uc02-readiness-activation-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 1: Kiểm tra mức sẵn sàng và kích hoạt chiến dịch_])
#image_counter.step()

Luồng xử lý:

- User mở project hoặc campaign cần vận hành và yêu cầu kiểm tra mức sẵn sàng.

- Giao diện gửi request đến Project Service để lấy kết quả readiness của chiến dịch.

- Project Service kiểm tra trạng thái hiện tại của project và gọi internal HTTP sang Ingest Service để đánh giá readiness dựa trên nguồn dữ liệu, mục tiêu thu thập và kết quả kiểm tra thử cần thiết.

- Nếu readiness đạt yêu cầu, user xác nhận thao tác kích hoạt.

- Project Service gửi lệnh activate sang Ingest Service để chuyển các nguồn dữ liệu đủ điều kiện sang trạng thái vận hành.

- Sau khi điều phối thành công, Project Service cập nhật trạng thái project sang ACTIVE và trả kết quả cho giao diện.

Điểm quan trọng: Kích hoạt chiến dịch là thao tác điều khiển nghiệp vụ ở `project-srv`, không phải việc giao diện trực tiếp publish task thu thập hay tự gọi runtime xử lý nền.

==== 5.5.2.2 Tạm dừng, tiếp tục, lưu trữ và mở lại chiến dịch

Luồng này mô tả các thao tác vận hành còn lại sau khi chiến dịch đã được tạo và có thể đã hoạt động trước đó.

#align(center)[
  #image("../images/chapter_5/seq-uc02-lifecycle-control-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 2: Tạm dừng, tiếp tục, lưu trữ và mở lại chiến dịch_])
#image_counter.step()

Luồng xử lý:

- Khi user chọn tạm dừng, giao diện gửi request pause đến Project Service.

- Project Service kiểm tra transition hợp lệ, rồi gọi Ingest Service để dừng các nguồn dữ liệu đang hoạt động trước khi cập nhật project sang PAUSED.

- Khi user chọn tiếp tục, Project Service kiểm tra lại mức sẵn sàng trước khi gọi Ingest Service resume runtime và chuyển project về ACTIVE.

- Khi user chọn lưu trữ, Project Service chuyển project sang ARCHIVED; nếu chiến dịch đang hoạt động thì phần execution liên quan được dừng trước.

- Khi user mở lại một chiến dịch đã lưu trữ, Project Service đưa chiến dịch về trạng thái PAUSED để user có thể kiểm tra lại trước khi vận hành tiếp.

Điểm quan trọng: Các thao tác pause, resume, archive và unarchive đều được áp dụng như các business transitions có kiểm soát. Trạng thái project không được thay đổi chỉ dựa trên giao diện; mỗi thao tác đều phải đi qua validation và lifecycle control tương ứng.
