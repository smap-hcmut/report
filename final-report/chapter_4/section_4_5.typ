// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.5 Sơ đồ hoạt động và luồng xử lý chính

Phần này sử dụng các sơ đồ current-state để mô tả các luồng hoạt động chính của hệ thống SMAP. Mục tiêu của các sơ đồ không phải là minh họa giao diện người dùng chi tiết, mà là làm rõ cách các capability cốt lõi của hệ thống được tổ chức và vận hành từ góc nhìn quy trình nghiệp vụ và luồng xử lý kỹ thuật.

=== 4.5.1 Tổng quan use case của hệ thống

Hình dưới đây trình bày sơ đồ use case tổng quát của SMAP theo current-state. Sơ đồ giúp nhìn nhanh các nhóm tương tác chính giữa người dùng nội bộ, hệ thống runtime và các capability cốt lõi như xác thực, quản lý project, dry run, lifecycle control, search/chat và notification.

#pad(left: 40pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_3/overall-use-case-diagram.svg", width: 85%)]
#context (align(center)[_Hình #image_counter.display(): Tổng quan use case của hệ thống_])
#image_counter.step()

=== 4.5.2 Quy trình nghiệp vụ chính của hệ thống

Sơ đồ này mô tả quy trình nghiệp vụ chính của SMAP ở mức activity-style current-state. Quy trình bắt đầu từ lớp business configuration, chuyển qua lớp ingest preparation, sau đó đi vào analytics processing, knowledge indexing và cuối cùng là consumption/delivery.

#pad(left: 40pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_3/business-process-main-flow.svg", width: 85%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình nghiệp vụ chính của hệ thống_])
#image_counter.step()

=== 4.5.3 Quy trình xác thực người dùng

Sơ đồ này mô tả luồng xác thực người dùng trong current-state, từ bước truy cập login cho tới khi hệ thống thiết lập được phiên làm việc hợp lệ. Đây là flow quan trọng vì nó là điểm vào cho toàn bộ các protected routes và các tương tác người dùng với hệ thống.

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-authentication-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình xác thực người dùng_])
#image_counter.step()

=== 4.5.4 Quy trình điều khiển vòng đời project

Sơ đồ này mô tả cách project được kiểm tra readiness và chuyển trạng thái trong kiến trúc hiện tại của SMAP. Điểm đáng chú ý là lifecycle control diễn ra qua một control plane gồm `project-srv` và các internal APIs của `ingest-srv`, thay vì hoàn toàn đi theo event-driven orchestration.

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-project-lifecycle-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình điều khiển vòng đời project_])
#image_counter.step()

=== 4.5.5 Quy trình dry run và kiểm tra readiness

Sơ đồ này minh họa use case dry run trong current-state, nơi người dùng cấu hình datasource và crawl target, sau đó chạy một luồng kiểm tra thử để tạo bằng chứng readiness trước khi kích hoạt project hoặc lane runtime chính thức.

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-dryrun-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình dry run và kiểm tra readiness_])
#image_counter.step()

=== 4.5.6 Quy trình analytics đến knowledge

Sơ đồ này mô tả lane xử lý bất đồng bộ quan trọng của hệ thống, nơi dữ liệu đã chuẩn hóa được tiêu thụ bởi analytics runtime, đi qua pipeline xử lý và sau đó được phát hành downstream để phục vụ knowledge layer. Đây là một trong những luồng kỹ thuật cốt lõi thể hiện rõ multi-stage processing trong current architecture của SMAP.

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-analytics-pipeline-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình analytics đến knowledge_])
#image_counter.step()

=== 4.5.7 Quy trình tìm kiếm, hỏi đáp và thông báo thời gian thực

Hai sơ đồ dưới đây thể hiện hai lớp delivery quan trọng của hệ thống. Một mặt, knowledge layer hỗ trợ người dùng tìm kiếm và hỏi đáp theo ngữ cảnh trên dữ liệu đã được index. Mặt khác, notification layer hỗ trợ đẩy cảnh báo và cập nhật thời gian thực tới người dùng thông qua các kênh tương tác phù hợp.

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-knowledge-chat-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình tìm kiếm và hỏi đáp theo ngữ cảnh_])
#image_counter.step()

#pad(left: 20pt)[#image("../../documents/phong_tmp/new-report/thesis/images/chapter_4/seq-notification-alert-flow.svg", width: 95%)]
#context (align(center)[_Hình #image_counter.display(): Quy trình thông báo thời gian thực_])
#image_counter.step()
