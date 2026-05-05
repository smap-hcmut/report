// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.5 Sơ đồ hoạt động

Phần này sử dụng sơ đồ hoạt động để mô tả dòng công việc nghiệp vụ tương ứng với các use case đã xác định ở mục 4.4. Các sơ đồ trong mục này tập trung vào thứ tự hoạt động, điểm quyết định và kết quả quan sát được ở mức người dùng; không mô tả trình tự gọi giữa các thành phần kỹ thuật. Các sơ đồ tuần tự chi tiết thuộc Chương 5.

=== 4.5.1 Quy trình nghiệp vụ tổng quát

Sơ đồ dưới đây mô tả dòng nghiệp vụ tổng quát của SMAP từ thiết lập chiến dịch, cấu hình cảnh báo bổ sung khi cần, vận hành theo dõi, cho đến khai thác kết quả hoặc nhận cảnh báo. Đây là sơ đồ hoạt động tổng quan, không phải sơ đồ tuần tự.

#align(center)[#image("../images/chapter_4/puml/overall-activity-flow-report.svg", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động tổng quát của hệ thống_])
#image_counter.step()

=== 4.5.2 UC-01: Thiết lập chiến dịch theo dõi

Sơ đồ hoạt động này mô tả cách người dùng tạo hoặc chọn campaign, tạo project, khai báo nguồn dữ liệu, cấu hình mục tiêu thu thập và thực hiện kiểm tra thử khi cần. Kết quả của luồng là chiến dịch có cấu hình đầu vào đủ điều kiện để chuyển sang vận hành hoặc danh sách điểm cần điều chỉnh.

#align(center)[#image("../images/chapter_4/puml/uc01-setup-monitoring-campaign-report.svg", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-01 - Thiết lập chiến dịch theo dõi_])
#image_counter.step()

=== 4.5.3 UC-02: Vận hành chiến dịch theo dõi

Use case này được tách thành ba sơ đồ hoạt động nhỏ hơn để phản ánh đúng ba nhóm thao tác nghiệp vụ chính: kiểm tra readiness, kích hoạt hoặc tiếp tục chiến dịch, và các thao tác thay đổi trạng thái còn lại như tạm dừng, lưu trữ hoặc mở lại.

===== a. Kiểm tra readiness

Sơ đồ này mô tả trường hợp user chỉ yêu cầu đánh giá mức độ sẵn sàng của chiến dịch mà chưa đổi trạng thái vận hành.

#align(center)[#image("../images/chapter_4/puml/uc02-readiness-check-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02A - Kiểm tra readiness_])
#image_counter.step()

===== b. Kích hoạt hoặc tiếp tục chiến dịch

Sơ đồ này mô tả nhánh vận hành cần đi qua kiểm tra readiness trước khi hệ thống cho phép campaign hoặc project chuyển sang trạng thái hoạt động.

#align(center)[#image("../images/chapter_4/puml/uc02-activate-resume-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02B - Kích hoạt hoặc tiếp tục chiến dịch_])
#image_counter.step()

===== c. Tạm dừng, lưu trữ hoặc mở lại

Sơ đồ này mô tả các thao tác thay đổi trạng thái không đi qua cùng một nhánh readiness như kích hoạt hoặc tiếp tục, mà được kiểm tra theo tính hợp lệ của trạng thái hiện tại.

#align(center)[#image("../images/chapter_4/puml/uc02-lifecycle-other-actions-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02C - Tạm dừng, lưu trữ hoặc mở lại_])
#image_counter.step()

=== 4.5.4 UC-03: Tra cứu và hỏi đáp dữ liệu phân tích

Sơ đồ hoạt động này mô tả cách người dùng gửi truy vấn hoặc câu hỏi, hệ thống kiểm tra phạm vi truy cập, tìm dữ liệu liên quan và trả kết quả tra cứu hoặc câu trả lời có dẫn chứng. Nếu không có dữ liệu phù hợp, hệ thống trả kết quả rỗng có kiểm soát thay vì suy diễn thiếu căn cứ.

#align(center)[#image("../images/chapter_4/puml/uc03-search-chat-analysis-report.svg", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-03 - Tra cứu và hỏi đáp dữ liệu phân tích_])
#image_counter.step()

=== 4.5.5 UC-04: Theo dõi trạng thái và nhận cảnh báo

Sơ đồ hoạt động này mô tả cách người dùng mở khu vực theo dõi, xem trạng thái hiện tại và nhận thông báo hoặc cảnh báo khi có sự kiện liên quan. Use case này chỉ giúp người dùng quan sát và phản ứng, không trực tiếp thay đổi trạng thái vận hành.

#align(center)[#image("../images/chapter_4/puml/uc04-monitor-alerts-report.svg", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-04 - Theo dõi trạng thái và nhận cảnh báo_])
#image_counter.step()

=== 4.5.6 UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng

Use case này được tách thành ba sơ đồ hoạt động nhỏ hơn để phản ánh rõ ba nhóm thao tác chính: xem cấu hình hiện có, lưu hoặc cập nhật quy tắc, và xóa cấu hình cảnh báo khủng hoảng.

===== a. Xem cấu hình hiện có

Sơ đồ này mô tả trường hợp user chỉ mở cấu hình cảnh báo khủng hoảng để xem trạng thái hiện có của một project.

#align(center)[#image("../images/chapter_4/puml/uc05-view-crisis-rules-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-05A - Xem cấu hình cảnh báo khủng hoảng_])
#image_counter.step()

===== b. Lưu hoặc cập nhật quy tắc

Sơ đồ này mô tả trường hợp user bật các nhóm quy tắc, nhập điều kiện cảnh báo và gửi yêu cầu lưu hoặc cập nhật cấu hình.

#align(center)[#image("../images/chapter_4/puml/uc05-save-crisis-rules-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-05B - Lưu hoặc cập nhật cấu hình cảnh báo khủng hoảng_])
#image_counter.step()

===== c. Xóa cấu hình

Sơ đồ này mô tả trường hợp user yêu cầu xóa cấu hình cảnh báo khủng hoảng của project sau bước xác nhận thao tác.

#align(center)[#image("../images/chapter_4/puml/uc05-delete-crisis-rules-report.svg", width: 82%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-05C - Xóa cấu hình cảnh báo khủng hoảng_])
#image_counter.step()
