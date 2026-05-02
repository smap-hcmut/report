#import "../counters.typ": image_counter, table_counter

=== 5.5.5 UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng

Trong bộ use case hiện tại ở Chương 4, UC-05 được hiểu là mục tiêu cho phép người dùng thiết lập, xem, cập nhật hoặc xóa bộ quy tắc cảnh báo khủng hoảng của một project. Ở mức sequence, mục tiêu này được cụ thể hóa qua hai interaction flows chính: xem hoặc lưu bộ quy tắc cảnh báo và xóa cấu hình cảnh báo khi không còn cần sử dụng.

Điểm chung của các flow trong mục này là Project Service giữ ownership của crisis configuration như một phần của business context. Cấu hình được quản lý theo project, còn việc hệ thống sử dụng các quy tắc đó để phát hiện hoặc phát cảnh báo ở runtime thuộc các luồng vận hành khác.

==== 5.5.5.1 Xem và lưu bộ quy tắc cảnh báo khủng hoảng

Luồng này mô tả cách người dùng mở cấu hình crisis của một project, xem trạng thái hiện có và lưu bộ quy tắc mới hoặc cập nhật bộ quy tắc đang áp dụng.

#align(center)[
  #image("../images/chapter_5/seq-uc05-crisis-config-upsert-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 1: Xem và lưu bộ quy tắc cảnh báo khủng hoảng_])
#image_counter.step()

Luồng xử lý:

- User mở chức năng cấu hình cảnh báo khủng hoảng của một project.

- Giao diện gửi request lấy cấu hình hiện có để nạp trạng thái ban đầu nếu project đã được thiết lập trước đó.

- Project Service kiểm tra quyền truy cập, project context và trả về bộ cấu hình hiện có hoặc trạng thái chưa có cấu hình.

- User bật một hoặc nhiều nhóm quy tắc như keyword, volume, sentiment hoặc influencer và nhập các điều kiện cảnh báo tương ứng.

- Giao diện gửi request lưu cấu hình mới đến Project Service.

- Service kiểm tra project, quyền thao tác và tính hợp lệ của từng nhóm quy tắc được bật.

- Nếu dữ liệu hợp lệ, service tạo mới hoặc cập nhật crisis configuration gắn với project trong persistence layer.

- Cấu hình đã lưu được trả lại cho giao diện để user xác nhận và tiếp tục theo dõi chiến dịch nếu cần.

Điểm quan trọng: Flow này chỉ quản lý dữ liệu cấu hình cảnh báo. Việc phát hiện khủng hoảng trong runtime không nằm trong sequence của UC-05.

==== 5.5.5.2 Xóa cấu hình cảnh báo khủng hoảng

Luồng này mô tả cách người dùng loại bỏ bộ quy tắc cảnh báo khủng hoảng đang gắn với một project.

#align(center)[
  #image("../images/chapter_5/seq-uc05-crisis-config-delete-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 2: Xóa cấu hình cảnh báo khủng hoảng_])
#image_counter.step()

Luồng xử lý:

- User chọn thao tác xóa cấu hình cảnh báo khủng hoảng trong phạm vi một project.

- Giao diện có thể yêu cầu xác nhận trước khi gửi request xóa.

- Project Service kiểm tra quyền quản lý project và xác nhận rằng project hoặc cấu hình tương ứng tồn tại.

- Nếu request hợp lệ, service xóa bản ghi crisis configuration gắn với project khỏi persistence layer.

- Hệ thống trả kết quả xóa thành công cho giao diện.

- Giao diện cập nhật lại trạng thái hiển thị để phản ánh rằng project không còn bộ quy tắc cảnh báo khủng hoảng đang áp dụng.

Điểm quan trọng: Việc xóa cấu hình chỉ thay đổi dữ liệu cấu hình của project. Nó không tự kích hoạt hành động vận hành khác ngoài việc loại bỏ đầu vào mà các luồng cảnh báo phía sau có thể sử dụng.
