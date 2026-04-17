// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.2 Functional Requirements

Căn cứ vào nhóm người dùng và tác nhân hệ thống đã xác định ở mục 4.1, cùng với các capability được thể hiện trong current implementation, phần này tổng hợp các yêu cầu chức năng cốt lõi của SMAP. Thay vì mô tả hệ thống theo từng màn hình hay theo luồng giao diện chi tiết, các yêu cầu ở đây được viết ở mức capability để có thể ánh xạ trực tiếp sang service boundaries, API routes và các module hiện thực của hệ thống.

Các yêu cầu chức năng được chia thành ba nhóm lớn. Nhóm thứ nhất là các capability phục vụ thiết lập và quản lý ngữ cảnh nghiệp vụ, bao gồm xác thực, campaign/project, datasource, crawl target và crisis configuration. Nhóm thứ hai là các capability điều phối và xử lý dữ liệu, bao gồm lifecycle control, dry run, crawl runtime orchestration và analytics processing. Nhóm thứ ba là các capability phục vụ khai thác kết quả, bao gồm tìm kiếm và hỏi đáp theo ngữ cảnh, thông báo thời gian thực và các internal validation flows phục vụ liên thông giữa các service.

#pagebreak()
#context (align(center)[_Bảng #table_counter.display(): Functional Requirements_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.12fr, 0.32fr, 1fr, 0.18fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, center + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*ID*],
    table.cell(align: center + horizon)[*Tên yêu cầu*],
    table.cell(align: center + horizon)[*Mô tả*],
    table.cell(align: center + horizon)[*Mức ưu tiên*],

    align(center + horizon)[FR-01],
    [User Authentication],
    [Hệ thống phải cho phép người dùng đăng nhập bằng cơ chế xác thực hiện có, duy trì phiên truy cập và truy xuất thông tin người dùng hiện tại để sử dụng các chức năng nghiệp vụ.],
    [Cao],

    align(center + horizon)[FR-02],
    [Campaign and Project Management],
    [Hệ thống phải cho phép tạo, xem, cập nhật và xóa campaign/project để thiết lập ngữ cảnh nghiệp vụ cho toàn bộ quá trình theo dõi và xử lý dữ liệu.],
    [Cao],

    align(center + horizon)[FR-03],
    [Project Lifecycle Control],
    [Hệ thống phải cho phép kiểm tra điều kiện kích hoạt và thay đổi trạng thái project như activate, pause, resume, archive và unarchive theo luồng điều phối hiện tại.],
    [Cao],

    align(center + horizon)[FR-04],
    [Crisis Configuration Management],
    [Hệ thống phải cho phép cấu hình, xem và xóa các rule hoặc cấu hình giám sát khủng hoảng gắn với từng project.],
    [Cao],

    align(center + horizon)[FR-05],
    [Datasource Management],
    [Hệ thống phải cho phép tạo và quản lý datasource, bao gồm xem chi tiết, cập nhật, lưu trữ trạng thái và thực hiện các thao tác quản lý vòng đời phù hợp.],
    [Cao],

    align(center + horizon)[FR-06],
    [Crawl Target Management],
    [Hệ thống phải cho phép tạo và quản lý crawl target theo các kiểu đầu vào mà hệ thống hiện hỗ trợ, làm cơ sở cho việc thu thập dữ liệu từ các nền tảng mạng xã hội.],
    [Cao],

    align(center + horizon)[FR-07],
    [Dry Run Validation],
    [Hệ thống phải cho phép thực hiện dry run để kiểm tra đầu vào thu thập dữ liệu và truy xuất kết quả dry run gần nhất hoặc lịch sử dry run phục vụ đánh giá trước khi vận hành chính thức.],
    [Cao],

    align(center + horizon)[FR-08],
    [Crawl Runtime Orchestration],
    [Hệ thống phải hỗ trợ publish crawl task, tiếp nhận completion metadata, liên kết raw artifact với quá trình ingest và điều phối lane thu thập dữ liệu bất đồng bộ.],
    [Cao],

    align(center + horizon)[FR-09],
    [Analytics Processing],
    [Hệ thống phải tiếp nhận dữ liệu đầu vào đã chuẩn hóa, thực thi pipeline phân tích và tạo ra các kết quả phân tích có cấu trúc để phục vụ các lớp downstream.],
    [Cao],

    align(center + horizon)[FR-10],
    [Knowledge Search and Chat],
    [Hệ thống phải hỗ trợ tìm kiếm, tra cứu và hỏi đáp theo ngữ cảnh trên dữ liệu và kết quả phân tích đã được lập chỉ mục.],
    [Cao],

    align(center + horizon)[FR-11],
    [Realtime Notification],
    [Hệ thống phải hỗ trợ kết nối thời gian thực và đẩy các loại thông báo cần thiết như tiến độ xử lý, sự kiện chiến dịch hoặc cảnh báo tới người dùng phù hợp.],
    [Trung bình],

    align(center + horizon)[FR-12],
    [Internal Service Validation],
    [Hệ thống phải hỗ trợ các internal route hoặc cơ chế kiểm tra phục vụ liên thông an toàn giữa các service, ví dụ token validation hoặc internal lookup.],
    [Trung bình],
  )
]
