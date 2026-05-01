// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.5 Sơ đồ hoạt động

Phần này sử dụng sơ đồ hoạt động để mô tả dòng công việc nghiệp vụ tương ứng với các use case đã xác định ở mục 4.4. Các sơ đồ trong mục này tập trung vào thứ tự hoạt động, điểm quyết định và kết quả quan sát được ở mức người dùng; không mô tả trình tự gọi giữa các thành phần kỹ thuật. Các sơ đồ tuần tự chi tiết thuộc Chương 5.

=== 4.5.1 Quy trình nghiệp vụ tổng quát

Sơ đồ dưới đây mô tả dòng nghiệp vụ tổng quát của SMAP từ thiết lập chiến dịch, cấu hình cảnh báo bổ sung khi cần, vận hành theo dõi, cho đến khai thác kết quả hoặc nhận cảnh báo. Đây là sơ đồ hoạt động tổng quan, không phải sơ đồ tuần tự.

#pad(left: 25pt)[#image("../images/chapter_4/excalidraw/overall-activity-flow-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động tổng quát của hệ thống_])
#image_counter.step()

=== 4.5.2 UC-01: Thiết lập chiến dịch theo dõi

Sơ đồ hoạt động này mô tả cách người dùng tạo hoặc chọn campaign, tạo project, khai báo nguồn dữ liệu, cấu hình mục tiêu thu thập và thực hiện kiểm tra thử khi cần. Kết quả của luồng là chiến dịch có cấu hình đầu vào đủ điều kiện để chuyển sang vận hành hoặc danh sách điểm cần điều chỉnh.

#pad(left: 20pt)[#image("../images/chapter_4/excalidraw/uc01-setup-monitoring-campaign-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-01 - Thiết lập chiến dịch theo dõi_])
#image_counter.step()

=== 4.5.3 UC-02: Vận hành chiến dịch theo dõi

Sơ đồ hoạt động này mô tả cách người dùng kiểm tra mức độ sẵn sàng và thực hiện các thao tác vận hành như kích hoạt, tạm dừng, tiếp tục, lưu trữ hoặc mở lại chiến dịch. Các nhánh lỗi thể hiện trường hợp thao tác không hợp lệ hoặc chiến dịch chưa đủ điều kiện vận hành.

#pad(left: 20pt)[#image("../images/chapter_4/excalidraw/uc02-operate-monitoring-campaign-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02 - Vận hành chiến dịch theo dõi_])
#image_counter.step()

=== 4.5.4 UC-03: Tra cứu và hỏi đáp dữ liệu phân tích

Sơ đồ hoạt động này mô tả cách người dùng gửi truy vấn hoặc câu hỏi, hệ thống kiểm tra phạm vi truy cập, tìm dữ liệu liên quan và trả kết quả tra cứu hoặc câu trả lời có dẫn chứng. Nếu không có dữ liệu phù hợp, hệ thống trả kết quả rỗng có kiểm soát thay vì suy diễn thiếu căn cứ.

#pad(left: 20pt)[#image("../images/chapter_4/excalidraw/uc03-search-chat-analysis-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-03 - Tra cứu và hỏi đáp dữ liệu phân tích_])
#image_counter.step()

=== 4.5.5 UC-04: Theo dõi trạng thái và nhận cảnh báo

Sơ đồ hoạt động này mô tả cách người dùng mở khu vực theo dõi, xem trạng thái hiện tại và nhận thông báo hoặc cảnh báo khi có sự kiện liên quan. Use case này chỉ giúp người dùng quan sát và phản ứng, không trực tiếp thay đổi trạng thái vận hành.

#pad(left: 20pt)[#image("../images/chapter_4/excalidraw/uc04-monitor-alerts-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-04 - Theo dõi trạng thái và nhận cảnh báo_])
#image_counter.step()

=== 4.5.6 UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng

Sơ đồ hoạt động này mô tả cách người dùng xem, tạo, cập nhật hoặc xóa bộ quy tắc cảnh báo khủng hoảng của một project. Kết quả của luồng là bộ quy tắc được lưu, được xóa hoặc yêu cầu bị từ chối do thiếu quyền hay dữ liệu không hợp lệ.

#pad(left: 20pt)[#image("../images/chapter_4/excalidraw/uc05-crisis-rules-report.excalidraw.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-05 - Thiết lập và quản lý quy tắc cảnh báo khủng hoảng_])
#image_counter.step()
