// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.2 Yêu cầu chức năng

Căn cứ vào nhóm người dùng và tác nhân hệ thống đã xác định ở mục 4.1, phần này tổng hợp các yêu cầu chức năng cốt lõi của SMAP. Thay vì mô tả hệ thống theo từng màn hình hay theo chi tiết hiện thực, các yêu cầu ở đây được viết ở mức capability để có thể ánh xạ sang use case nghiệp vụ ở mục 4.4 và thiết kế kỹ thuật ở Chương 5.

Các yêu cầu chức năng được chia thành ba nhóm lớn. Nhóm thứ nhất là các capability phục vụ thiết lập và quản lý ngữ cảnh nghiệp vụ, bao gồm xác thực, campaign/project, nguồn dữ liệu, mục tiêu thu thập, kiểm tra thử và cấu hình cảnh báo khủng hoảng. Nhóm thứ hai là các capability điều phối và xử lý dữ liệu, bao gồm điều khiển vòng đời vận hành, điều phối thu thập dữ liệu và xử lý phân tích. Nhóm thứ ba là các capability phục vụ khai thác kết quả, bao gồm tìm kiếm, hỏi đáp theo ngữ cảnh, thông báo kịp thời và các cơ chế kiểm tra nội bộ phục vụ liên thông an toàn giữa các thành phần.

#pagebreak()
#context (align(center)[_Bảng #table_counter.display(): Yêu cầu chức năng_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.32fr, 1fr, 0.18fr),
    stroke: 0.5pt,
    align: (left + top, center + horizon, left + horizon, center + horizon),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*ID*],
    table.cell(align: center + horizon)[*Tên yêu cầu*],
    table.cell(align: center + horizon)[*Mô tả*],
    table.cell(align: center + horizon)[*Mức ưu tiên*],

    align(center + horizon)[FR-01],
    [Xác thực người dùng],
    [Hệ thống phải cho phép người dùng đăng nhập bằng cơ chế xác thực hiện có, duy trì phiên truy cập và truy xuất thông tin người dùng hiện tại để sử dụng các chức năng nghiệp vụ.],
    [Cao],

    align(center + horizon)[FR-02],
    [Quản lý campaign và project],
    [Hệ thống phải cho phép tạo, xem, cập nhật và xóa campaign/project để thiết lập ngữ cảnh nghiệp vụ cho toàn bộ quá trình theo dõi và xử lý dữ liệu.],
    [Cao],

    align(center + horizon)[FR-03],
    [Điều khiển vòng đời project],
    [Hệ thống phải cho phép kiểm tra điều kiện sẵn sàng và thay đổi trạng thái vận hành của project như kích hoạt, tạm dừng, tiếp tục, lưu trữ và mở lại theo quy tắc nghiệp vụ hiện tại.],
    [Cao],

    align(center + horizon)[FR-04],
    [Quản lý cấu hình cảnh báo khủng hoảng],
    [Hệ thống phải cho phép cấu hình, xem và xóa các rule hoặc cấu hình giám sát khủng hoảng gắn với từng project.],
    [Cao],

    align(center + horizon)[FR-05],
    [Quản lý nguồn dữ liệu],
    [Hệ thống phải cho phép tạo và quản lý nguồn dữ liệu theo project, bao gồm xem chi tiết, cập nhật và duy trì trạng thái cấu hình phục vụ bước vận hành.],
    [Cao],

    align(center + horizon)[FR-06],
    [Quản lý mục tiêu thu thập],
    [Hệ thống phải cho phép tạo và quản lý mục tiêu thu thập theo các kiểu đầu vào mà hệ thống hiện hỗ trợ, làm cơ sở cho việc thu thập dữ liệu từ các nền tảng mạng xã hội.],
    [Cao],

    align(center + horizon)[FR-07],
    [Kiểm tra thử đầu vào],
    [Hệ thống phải cho phép thực hiện kiểm tra thử để đánh giá đầu vào thu thập dữ liệu và truy xuất kết quả kiểm tra gần nhất hoặc lịch sử kiểm tra phục vụ quyết định trước khi vận hành chính thức.],
    [Cao],

    align(center + horizon)[FR-08],
    [Điều phối thu thập dữ liệu],
    [Hệ thống phải hỗ trợ khởi tạo, theo dõi và ghi nhận kết quả của các hoạt động thu thập dữ liệu bất đồng bộ sau khi chiến dịch được đưa vào trạng thái vận hành.],
    [Cao],

    align(center + horizon)[FR-09],
    [Xử lý phân tích],
    [Hệ thống phải tiếp nhận dữ liệu đầu vào đã chuẩn hóa, thực hiện xử lý phân tích và tạo ra các kết quả có cấu trúc để phục vụ tra cứu, hỏi đáp, theo dõi trạng thái và cảnh báo.],
    [Cao],

    align(center + horizon)[FR-10],
    [Tra cứu và hỏi đáp dữ liệu],
    [Hệ thống phải hỗ trợ tìm kiếm, tra cứu và hỏi đáp theo ngữ cảnh trên dữ liệu và kết quả phân tích đã sẵn sàng cho việc khai thác.],
    [Cao],

    align(center + horizon)[FR-11],
    [Gửi thông báo],
    [Hệ thống phải hỗ trợ gửi các loại thông báo cần thiết như tiến độ xử lý, sự kiện chiến dịch hoặc cảnh báo tới người dùng phù hợp một cách kịp thời.],
    [Trung bình],

    align(center + horizon)[FR-12],
    [Kiểm tra liên thông nội bộ],
    [Hệ thống phải hỗ trợ các cơ chế kiểm tra nội bộ để bảo đảm các thành phần của hệ thống liên thông an toàn khi thực hiện các capability nghiệp vụ được bảo vệ.],
    [Trung bình],
  )
]
