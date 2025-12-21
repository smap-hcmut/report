// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.5 Sơ đồ hoạt động

=== 4.5.1 Vòng đời Project từ cấu hình đến xem kết quả và xuất báo cáo

Sơ đồ này mô tả vòng đời Project theo luồng nghiệp vụ chính, bắt đầu từ cấu hình (UC-01), kiểm tra từ khóa bằng dry-run (UC-02), khởi chạy và theo dõi tiến độ xử lý (UC-03), xem kết quả phân tích trên dashboard (UC-04), và kết thúc ở bước xuất báo cáo (UC-06). Ở mức tổng quan, sơ đồ tập trung vào các quyết định nghiệp vụ quan trọng (lưu cấu hình hay dry-run, trạng thái Project, và export bất đồng bộ), đồng thời lược bỏ các nhánh lỗi kỹ thuật chi tiết nhằm làm nổi bật dòng chảy tác vụ của người dùng và phản hồi tương ứng của hệ thống.

#pad(left: 150pt)[#image("../images/activity/1.png", width: 50%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động vòng đời Project_])
#image_counter.step()


=== 4.5.2 Chi tiết quy trình cấu hình Project và xác thực dữ liệu (UC-01)

Sơ đồ này chi tiết hóa wizard cấu hình Project trong UC-01, bao gồm các bước thu thập thông tin cơ bản, cấu hình thương hiệu và bộ từ khóa, khai báo đối thủ, lựa chọn nền tảng theo dõi, và bước tổng quan trước khi lưu.
#pad(left: 40pt)[#image("../images/activity/2.png", width: 90%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-01_])
#image_counter.step()


=== 4.5.3 Luồng kiểm tra từ khóa trước khi lưu (UC-02)

Sơ đồ này mô tả nhánh tùy chọn Dry-run trong quá trình cấu hình, nhằm giúp người dùng đánh giá nhanh chất lượng từ khóa dựa trên một mẫu dữ liệu nhỏ từ các nền tảng đã chọn.

#pad(left: 40pt)[#image("../images/activity/dry.png", width: 90%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-02_])
#image_counter.step()


=== 4.5.4 Chi tiết quy trình khởi chạy và theo dõi tiến độ Project (UC-03)

Sơ đồ này minh họa quy trình khởi chạy Project và theo dõi tiến độ xử lý theo thời gian thực.

#pad(left: 10pt)[#image("../images/activity/4.png", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-03_])
#image_counter.step()


=== 4.5.5 Quy trình xuất báo cáo bất đồng bộ (UC-06)

Sơ đồ này mô tả quy trình xuất báo cáo dưới dạng tác vụ nền. Sau khi người dùng gửi yêu cầu export từ dashboard, hệ thống ghi nhận yêu cầu, tạo job và đưa vào hàng đợi để xử lý bất đồng bộ.

#pad(left: 20pt)[#image("../images/activity/5.png", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-06_])
#image_counter.step()


=== 4.5.6 Quy trình phát hiện Trend tự động (UC-07)
Sơ đồ mô tả quy trình hệ thống tự động thu thập và xếp hạng trending content theo chu kỳ


#pad(left: 10pt)[#image("../images/activity/6.png", width: 100%)]
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-07_])
#image_counter.step()


=== 4.5.7 Quy trình cấu hình và giám sát khủng hoảng (UC-08)

Sơ đồ này mô tả hai pha chính của chức năng Crisis Monitor: (1) người dùng cấu hình chủ đề giám sát (từ khóa bao gồm/loại trừ, nền tảng, ngưỡng cảnh báo, kênh nhận thông báo) và kích hoạt monitor; (2) hệ thống chạy tác vụ nền theo lịch để quét dữ liệu mới, đánh giá điều kiện vượt ngưỡng, tạo cảnh báo và gửi thông báo tức thì. Luồng này khác với Project ở chỗ giám sát diễn ra liên tục theo thời gian thực/near real-time và chỉ lưu các trường hợp “hit” để tối ưu lưu trữ.

#image("../images/activity/7.png")
#context (align(center)[_Hình #image_counter.display(): Sơ đồ hoạt động UC-08_])
#image_counter.step()
