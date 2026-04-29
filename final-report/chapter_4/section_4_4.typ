#import "../counters.typ": table_counter

== 4.4 Use Case

Sau khi xác định các yêu cầu chức năng và phi chức năng, phần này mô tả các use case cốt lõi của hệ thống SMAP ở góc nhìn người dùng và tác nhân vận hành. Mỗi use case được viết theo mục tiêu sử dụng hệ thống, không theo cấu trúc mã nguồn, nhưng vẫn bám sát các capability đang được triển khai trong các service boundary của SMAP.

Các use case được chia thành ba nhóm. Nhóm thứ nhất là các use case do người dùng nội bộ trực tiếp khởi tạo, gồm xác thực, tạo campaign/project, cấu hình datasource, tìm kiếm tri thức và cấu hình crisis. Nhóm thứ hai là các use case điều khiển vòng đời và xử lý nền, gồm lifecycle control, crawl/analytics execution và knowledge indexing. Nhóm thứ ba là các use case hỗ trợ delivery, gồm notification; các validation nội bộ được xem như supporting concern nằm trong các use case xác thực và lifecycle control thay vì được tách thành một use case độc lập.

#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.40fr, 0.34fr, 0.24fr, 0.68fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon),

    table.header([*ID*], [*Tên Use Case*], [*Actor chính*], [*FR liên quan*], [*Mục tiêu nghiệp vụ*]),

    [UC-01],
    [Xác thực người dùng],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-01, FR-12],
    [Thiết lập phiên truy cập hợp lệ để người dùng sử dụng các chức năng được bảo vệ và để các service có thể xác thực yêu cầu liên quan.],

    [UC-02],
    [Tạo campaign và project],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-02],
    [Tạo ngữ cảnh nghiệp vụ cho hoạt động theo dõi, cấu hình datasource và phân tích dữ liệu.],

    [UC-03],
    [Cấu hình datasource, target và dry run],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-05, FR-06, FR-07],
    [Khai báo nguồn dữ liệu, target thu thập và kiểm tra readiness trước khi kích hoạt luồng chạy chính thức.],

    [UC-04],
    [Điều khiển vòng đời project],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-03, FR-08, FR-12],
    [Kiểm tra điều kiện vận hành và chuyển trạng thái project, đồng thời kích hoạt hoặc dừng các lane runtime liên quan.],

    [UC-05],
    [Thực thi analytics và xây dựng knowledge index],
    [System Runtime],
    [FR-08, FR-09, FR-10],
    [Tiếp nhận dữ liệu đã chuẩn hóa, chạy pipeline phân tích và đưa kết quả sang knowledge layer để phục vụ truy hồi.],

    [UC-06],
    [Tìm kiếm và hỏi đáp trên knowledge],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-10],
    [Cho phép người dùng khai thác dữ liệu đã được index thông qua semantic search, chat theo ngữ cảnh và câu trả lời có dẫn chứng.],

    [UC-07],
    [Nhận notification và cảnh báo],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-11],
    [Truyền tải thông báo vận hành, trạng thái xử lý hoặc cảnh báo đến người dùng qua lớp delivery phù hợp.],

    [UC-08],
    [Quản lý cấu hình crisis],
    [Nhóm người dùng chuyên môn nội bộ],
    [FR-04],
    [Thiết lập và cập nhật các rule giám sát crisis gắn với project để làm đầu vào cho các luồng phát hiện và cảnh báo.],
  )
]

=== 4.4.1 UC-01: Xác thực người dùng

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-01: Xác thực người dùng],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Nhà cung cấp định danh
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng thực hiện đăng nhập để thiết lập phiên truy cập hợp lệ trước khi sử dụng các chức năng được bảo vệ của SMAP. Hệ thống phối hợp với nhà cung cấp định danh để xác thực người dùng, sau đó tạo session hoặc token phục vụ các yêu cầu tiếp theo và các bước kiểm tra nội bộ liên quan đến xác thực.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User chọn đăng nhập hoặc truy cập một chức năng yêu cầu xác thực.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User chưa có phiên truy cập hợp lệ hoặc cần xác thực lại.
      2. Hệ thống SMAP có thể giao tiếp với nhà cung cấp định danh.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Phiên truy cập hợp lệ được thiết lập cho user.
      2. User có thể sử dụng các chức năng được bảo vệ của hệ thống.
      3. Thông tin xác thực có thể được sử dụng cho các yêu cầu kiểm tra nội bộ liên quan.
      4. Nếu xác thực thất bại thì không tạo phiên truy cập.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User truy cập chức năng đăng nhập hoặc một tài nguyên yêu cầu xác thực.
      2. Hệ thống chuyển hướng user sang nhà cung cấp định danh.
      3. User cung cấp thông tin xác thực tại nhà cung cấp định danh.
      4. Nhà cung cấp định danh trả kết quả xác thực về cho SMAP.
      5. Hệ thống kiểm tra callback và thông tin định danh nhận được.
      6. Hệ thống tạo session hoặc token/cookie cho user.
      7. Hệ thống cho phép user tiếp tục truy cập các chức năng được bảo vệ.
      8. Khi có yêu cầu nội bộ liên quan đến xác thực, hệ thống kiểm tra tính hợp lệ của session hoặc token tương ứng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *User đã có phiên hợp lệ* \
      Tại Bước 1 của luồng cơ bản:
      - 1A.1. Hệ thống nhận thấy user đang có phiên truy cập hợp lệ.
      - 1A.2. Hệ thống bỏ qua bước chuyển hướng sang nhà cung cấp định danh.
      - 1A.3. User tiếp tục truy cập tài nguyên được cấp quyền.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Xác thực bị từ chối* \
      Tại Bước 3 hoặc Bước 4 của luồng cơ bản, nếu nhà cung cấp định danh không chấp nhận xác thực:
      - 4.E.1. Hệ thống không tạo session hoặc token cho user.
      - 4.E.2. Hệ thống thông báo user cần thực hiện lại đăng nhập để tiếp tục.
      - Kết thúc use case.

      *Callback hoặc token không hợp lệ* \
      Tại Bước 5 của luồng cơ bản, nếu callback hoặc token không hợp lệ:
      - 5.E.1. Hệ thống từ chối yêu cầu xác thực.
      - 5.E.2. Hệ thống xóa thông tin phiên tạm nếu có.
      - 5.E.3. User được yêu cầu xác thực lại trước khi tiếp tục.
      - Kết thúc use case.

      *Không kết nối được nhà cung cấp định danh* \
      Tại Bước 2 hoặc Bước 4 của luồng cơ bản, nếu kết nối đến nhà cung cấp định danh thất bại:
      - 4.E.4. Hệ thống thông báo tạm thời không thể hoàn tất đăng nhập.
      - 4.E.5. User có thể thử lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này bao phủ cả bước thiết lập phiên truy cập cho user và khả năng kiểm tra tính hợp lệ của thông tin xác thực trong các yêu cầu nội bộ liên quan đến FR-12.
    ],
  )
]

=== 4.4.2 UC-02: Tạo campaign và project

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-02: Tạo campaign và project],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng tạo campaign và project để thiết lập ngữ cảnh nghiệp vụ cho quá trình theo dõi, cấu hình datasource, cấu hình crisis và các bước xử lý downstream. Thông tin được lưu ở lớp persistence dưới dạng thực thể nghiệp vụ ban đầu để người dùng tiếp tục cấu hình và vận hành project về sau.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User chọn tạo campaign mới, project mới hoặc thêm project vào một campaign hiện có.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập vào hệ thống SMAP.
      2. User có quyền tạo campaign hoặc project trong phạm vi làm việc tương ứng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Campaign mới được lưu nếu user yêu cầu tạo campaign.
      2. Project mới được lưu cùng metadata ban đầu và liên kết với campaign tương ứng.
      3. Campaign ID hoặc Project ID được tạo và trả về cho user.
      4. User có thể tiếp tục cấu hình datasource, target, crisis configuration hoặc các bước quản lý tiếp theo.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User truy cập chức năng tạo campaign hoặc project.
      2. Hệ thống hiển thị biểu mẫu nhập thông tin nghiệp vụ ban đầu.
      3. User nhập thông tin campaign mới hoặc chọn một campaign hiện có.
      4. User nhập thông tin project và các metadata cần thiết.
      5. Hệ thống kiểm tra tính đầy đủ và hợp lệ của dữ liệu đầu vào.
      6. Nếu request bao gồm campaign mới, hệ thống tạo campaign và lưu vào persistence layer.
      7. Hệ thống tạo project và liên kết project với campaign tương ứng.
      8. Hệ thống trả kết quả tạo thành công để user tiếp tục các bước cấu hình downstream.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Tạo project dưới campaign hiện có* \
      Tại Bước 3 của luồng cơ bản:
      - 3A.1. User chọn một campaign đã tồn tại thay vì tạo campaign mới.
      - 3A.2. Hệ thống bỏ qua bước tạo campaign.
      - 3A.3. Hệ thống tiếp tục tạo project và liên kết với campaign đã chọn.
      - Tiếp tục tại bước 7.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi validation dữ liệu* \
      Tại Bước 5 của luồng cơ bản, nếu dữ liệu đầu vào không hợp lệ:
      - 5.E.1. Hệ thống hiển thị thông báo lỗi tại các trường liên quan.
      - 5.E.2. User chỉnh sửa thông tin campaign hoặc project.
      - Tiếp tục tại bước 4.

      *Campaign không hợp lệ hoặc không thuộc quyền truy cập* \
      Tại Bước 7 của luồng cơ bản, nếu campaign được chọn không hợp lệ hoặc user không có quyền sử dụng:
      - 7.E.1. Hệ thống từ chối tạo project.
      - 7.E.2. Hệ thống yêu cầu user chọn campaign hợp lệ khác hoặc tạo campaign mới.
      - Kết thúc use case.

      *Lỗi persistence* \
      Tại Bước 6 hoặc Bước 7 của luồng cơ bản, nếu hệ thống không thể lưu campaign hoặc project:
      - 7.E.3. Hệ thống hiển thị thông báo không thể hoàn tất thao tác tạo.
      - 7.E.4. User có thể thử lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này thiết lập business context ban đầu cho project, nhưng chưa kích hoạt crawl runtime hay analytics processing.
    ],
  )
]

=== 4.4.3 UC-03: Cấu hình datasource, target và dry run

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-03: Cấu hình datasource, target và dry run],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Nền tảng mạng xã hội
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng cấu hình datasource và crawl target cho một project, sau đó thực hiện dry run để kiểm tra đầu vào thu thập dữ liệu trước khi vận hành chính thức. Hệ thống lưu datasource, target và kết quả dry run, đồng thời dùng kết quả dry run làm evidence readiness cho các bước kích hoạt về sau đối với những tổ hợp source-target yêu cầu validation.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User chọn cấu hình datasource cho project hoặc yêu cầu chạy dry run trên một target đã khai báo.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. Project đã tồn tại và user có quyền cấu hình datasource cho project đó.
      2. User đã đăng nhập vào hệ thống SMAP.
      3. Project chưa ở trạng thái ngăn cản việc thêm hoặc chỉnh sửa datasource.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Datasource được lưu và liên kết với project tương ứng.
      2. Một hoặc nhiều target được lưu dưới datasource tương ứng.
      3. Kết quả dry run mới nhất và lịch sử dry run được ghi nhận nếu user đã chạy dry run.
      4. Datasource được cập nhật trạng thái readiness phù hợp; nếu dry run usable thì target có thể được kích hoạt và datasource có thể chuyển sang trạng thái sẵn sàng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User truy cập chức năng cấu hình datasource trong một project đã tồn tại.
      2. Hệ thống hiển thị biểu mẫu tạo datasource và các lựa chọn cấu hình liên quan.
      3. User nhập thông tin datasource và gửi yêu cầu tạo.
      4. Hệ thống kiểm tra dữ liệu đầu vào và lưu datasource cho project.
      5. User thêm một hoặc nhiều crawl target cho datasource.
      6. Hệ thống kiểm tra loại target, dữ liệu đầu vào và lưu target ở trạng thái chưa kích hoạt.
      7. User yêu cầu chạy dry run cho một target hoặc cặp datasource-target cần kiểm tra.
      8. Hệ thống tạo một dry run result ở trạng thái `RUNNING`, cập nhật trạng thái dry run của datasource và dispatch công việc lấy mẫu bất đồng bộ.
      9. Hệ thống thu thập dữ liệu mẫu từ nền tảng mạng xã hội tương ứng.
      10. Khi dry run hoàn tất, hệ thống lưu kết quả mới nhất và lịch sử dry run cho datasource hoặc target tương ứng.
      11. Nếu kết quả dry run ở trạng thái usable như `SUCCESS` hoặc `WARNING`, hệ thống cập nhật datasource sang trạng thái sẵn sàng và có thể kích hoạt target tương ứng.
      12. User xem kết quả dry run gần nhất hoặc lịch sử dry run để quyết định tiếp tục bước kích hoạt project sau này.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Tổ hợp source-target không yêu cầu dry run* \
      Tại Bước 7 của luồng cơ bản:
      - 7A.1. Hệ thống xác định tổ hợp source-target hiện tại không có dry run mapping bắt buộc.
      - 7A.2. User có thể bỏ qua bước dry run và tiếp tục kích hoạt target theo luồng phù hợp.
      - 7A.3. Khi target được kích hoạt thành công, datasource có thể được chuyển sang trạng thái sẵn sàng mà không cần evidence dry run.
      - Kết thúc use case.

      *Chạy lại dry run sau khi chỉnh target* \
      Tại Bước 12 của luồng cơ bản:
      - 12A.1. User xem kết quả dry run và nhận thấy cần chỉnh target hoặc input crawl.
      - 12A.2. User cập nhật target hoặc datasource.
      - 12A.3. Hệ thống đưa datasource về trạng thái chờ xác nhận lại.
      - 12A.4. User chạy lại dry run với cấu hình mới.
      - Tiếp tục tại bước 8.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Lỗi validation datasource hoặc target* \
      Tại Bước 4 hoặc Bước 6 của luồng cơ bản, nếu dữ liệu đầu vào không hợp lệ:
      - 6.E.1. Hệ thống từ chối lưu datasource hoặc target.
      - 6.E.2. Hệ thống hiển thị lỗi tại các trường liên quan.
      - 6.E.3. User chỉnh sửa dữ liệu và gửi lại yêu cầu.
      - Tiếp tục tại bước 3 hoặc bước 5.

      *Dry run đã đang chạy* \
      Tại Bước 8 của luồng cơ bản, nếu đã tồn tại một dry run `RUNNING` cho cùng datasource-target:
      - 8.E.1. Hệ thống từ chối tạo thêm yêu cầu dry run mới.
      - 8.E.2. User chờ kết quả dry run hiện tại hoặc kiểm tra lại trạng thái sau.
      - Kết thúc use case.

      *Dry run thất bại hoặc không usable* \
      Tại Bước 10 hoặc Bước 11 của luồng cơ bản, nếu crawler trả lỗi hoặc kết quả dry run thất bại:
      - 11.E.1. Hệ thống ghi nhận kết quả `FAILED` và lưu thông tin lỗi liên quan.
      - 11.E.2. Datasource vẫn chưa đủ điều kiện sẵn sàng cho bước kích hoạt yêu cầu validation.
      - 11.E.3. User cần điều chỉnh cấu hình và chạy lại dry run nếu muốn tiếp tục.
      - Kết thúc use case.

      *Lỗi dispatch hoặc lưu kết quả* \
      Tại Bước 8 hoặc Bước 10 của luồng cơ bản, nếu hệ thống không dispatch được dry run hoặc không lưu được kết quả:
      - 10.E.1. Hệ thống thông báo thao tác dry run không hoàn tất thành công.
      - 10.E.2. User có thể thử lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Dry run trong implementation hiện tại là bất đồng bộ, có endpoint truy xuất `latest` và `history`. Việc yêu cầu dry run hay cho phép bỏ qua phụ thuộc vào tổ hợp `source_type` và `target_type`; khi user thay đổi material target config, datasource có thể bị đưa về trạng thái `PENDING` để yêu cầu xác nhận lại readiness.
    ],
  )
]

=== 4.4.4 UC-04: Điều khiển vòng đời project

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-04: Điều khiển vòng đời project],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng kiểm tra readiness và điều khiển trạng thái project thông qua các thao tác activate, pause, resume, archive và unarchive. Trước các thao tác activate hoặc resume, hệ thống đánh giá điều kiện sẵn sàng của project dựa trên datasource, target và bằng chứng dry run trong ingest domain. Khi thao tác hợp lệ, project-srv điều phối lifecycle tương ứng ở ingest-srv, cập nhật trạng thái project và phát lifecycle event cho các bước downstream.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User yêu cầu kiểm tra readiness hoặc thay đổi trạng thái lifecycle của một project.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. Project đã tồn tại và user có quyền quản lý project đó.
      2. Project đang ở trạng thái cho phép thực hiện command được chọn.
      3. Với activate, pause hoặc resume, kênh giao tiếp internal giữa project-srv và ingest-srv sẵn sàng phục vụ điều phối lifecycle.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Nếu command hợp lệ và thành công, trạng thái project được cập nhật theo thao tác tương ứng.
      2. Với activate, pause hoặc resume, lifecycle của datasource liên quan trong ingest domain được cập nhật theo command tương ứng.
      3. Với unarchive, project được đưa về trạng thái tạm dừng để có thể resume lại sau khi kiểm tra điều kiện phù hợp.
      4. Lifecycle event tương ứng được phát sau khi trạng thái local của project được cập nhật thành công.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User chọn thao tác `activate` cho một project ở trạng thái chờ kích hoạt.
      2. Hệ thống kiểm tra trạng thái hiện tại của project có cho phép activate hay không.
      3. project-srv yêu cầu ingest-srv trả thông tin activation readiness của project.
      4. ingest-srv đánh giá readiness dựa trên datasource, active target, trạng thái datasource và bằng chứng dry run cần thiết.
      5. Nếu readiness đạt yêu cầu, project-srv gọi internal lifecycle endpoint của ingest-srv để activate các datasource đủ điều kiện.
      6. ingest-srv cập nhật lifecycle của datasource thuộc project sang trạng thái hoạt động phù hợp.
      7. project-srv cập nhật trạng thái project sang `ACTIVE`.
      8. project-srv phát lifecycle event `project.lifecycle.activated`.
      9. Hệ thống trả kết quả thành công cho user.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Kiểm tra readiness mà không thay đổi trạng thái* \
      Trước Bước 1 của luồng cơ bản:
      - R1. User chọn kiểm tra readiness thay vì activate ngay.
      - R2. Hệ thống truy vấn ingest-srv để tổng hợp readiness của project.
      - R3. Hệ thống trả về các chỉ báo như thiếu datasource, thiếu target active, thiếu dry run hoặc dry run failed.
      - R4. Không có thay đổi trạng thái lifecycle nào được thực hiện.
      - Kết thúc use case.

      *Tạm dừng project* \
      Thay cho Bước 1 của luồng cơ bản:
      - P1. User chọn thao tác `pause` cho một project đang hoạt động.
      - P2. Hệ thống gọi ingest-srv để pause lifecycle của datasource và hủy runtime liên quan nếu cần.
      - P3. project-srv cập nhật trạng thái project sang `PAUSED`.
      - P4. project-srv phát lifecycle event `project.lifecycle.paused`.
      - Kết thúc use case.

      *Tiếp tục project đã tạm dừng* \
      Thay cho Bước 1 của luồng cơ bản:
      - RS1. User chọn thao tác `resume` cho một project đang ở trạng thái `PAUSED`.
      - RS2. Hệ thống thực hiện lại bước kiểm tra readiness như luồng activate.
      - RS3. Nếu readiness đạt yêu cầu, project-srv gọi ingest-srv để resume lifecycle của datasource liên quan.
      - RS4. project-srv cập nhật trạng thái project sang `ACTIVE` và phát lifecycle event `project.lifecycle.resumed`.
      - Kết thúc use case.

      *Lưu trữ project* \
      Thay cho Bước 1 của luồng cơ bản:
      - A1. User chọn thao tác `archive` cho project.
      - A2. Nếu project đang `ACTIVE`, hệ thống pause ingest lifecycle trước khi archive.
      - A3. project-srv cập nhật trạng thái project sang `ARCHIVED`.
      - A4. project-srv phát lifecycle event `project.lifecycle.archived`.
      - Kết thúc use case.

      *Mở lại project đã archive* \
      Thay cho Bước 1 của luồng cơ bản:
      - U1. User chọn thao tác `unarchive` cho project đã lưu trữ.
      - U2. project-srv cập nhật trạng thái project sang `PAUSED`.
      - U3. project-srv phát lifecycle event `project.lifecycle.unarchived`.
      - U4. User có thể tiếp tục dùng thao tác `resume` nếu muốn vận hành lại project.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Readiness không đạt yêu cầu* \
      Tại Bước 4 của luồng cơ bản hoặc RS2 của luồng resume, nếu readiness không đạt:
      - 4.E.1. Hệ thống từ chối thao tác activate hoặc resume.
      - 4.E.2. Hệ thống trả về các lỗi readiness như thiếu datasource, datasource ở trạng thái không hợp lệ, thiếu target active, thiếu dry run hoặc dry run failed.
      - 4.E.3. User cần điều chỉnh cấu hình trước khi thử lại.
      - Kết thúc use case.

      *Lỗi chuyển trạng thái không hợp lệ* \
      Tại Bước 2 của luồng cơ bản hoặc tại các bước đầu của các luồng thay thế, nếu project không ở trạng thái cho phép command được chọn:
      - 2.E.1. Hệ thống từ chối thao tác lifecycle.
      - 2.E.2. Không có thay đổi nào được áp dụng lên project hoặc datasource.
      - Kết thúc use case.

      *Lỗi gọi lifecycle manager nội bộ* \
      Tại Bước 3, Bước 5 hoặc các bước nội bộ tương đương trong luồng pause/resume/archive, nếu project-srv không gọi được ingest-srv hoặc bị từ chối:
      - 5.E.1. Hệ thống thông báo thao tác lifecycle không thể hoàn tất.
      - 5.E.2. Trạng thái project local không được cập nhật thành công.
      - Kết thúc use case.

      *Lỗi cạnh tranh trạng thái hoặc cập nhật persistence* \
      Tại Bước 7 hoặc các bước cập nhật trạng thái local tương đương, nếu trạng thái project đã bị thay đổi bởi yêu cầu khác hoặc lưu thất bại:
      - 7.E.1. Hệ thống từ chối hoàn tất thao tác hiện tại.
      - 7.E.2. User cần tải lại trạng thái project và thực hiện lại nếu cần.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này phụ thuộc vào giao tiếp internal giữa project-srv và ingest-srv để lấy activation readiness và điều phối activate/pause/resume. Trong implementation hiện tại, `archive` không activate lại project mà `unarchive` chỉ đưa project về `PAUSED`; nếu muốn vận hành lại thì user phải thực hiện `resume`, và thao tác này lại chịu kiểm tra readiness.
    ],
  )
]

=== 4.4.5 UC-05: Thực thi analytics và xây dựng knowledge index

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-05: Thực thi analytics và xây dựng knowledge index],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: System Runtime
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[System Runtime tiếp nhận dữ liệu đầu vào đã được ingest hoặc chuẩn hóa, chạy pipeline phân tích trong `analysis-srv`, lưu các kết quả analytics cần thiết và phát các message downstream. Sau đó `knowledge-srv` tiêu thụ các message batch, insight hoặc digest phù hợp để tạo metadata theo dõi, sinh embedding và index nội dung vào knowledge store phục vụ tìm kiếm và truy hồi về sau.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[Message đầu vào của analytics runtime hoặc message indexing downstream xuất hiện trên các topic tiêu thụ tương ứng.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. Dữ liệu đầu vào hợp lệ đã được publish vào lane analytics.
      2. `analysis-srv` và `knowledge-srv` đang chạy consumer tương ứng.
      3. Hạ tầng lưu trữ và message bus cần thiết cho pipeline, metadata và indexing downstream sẵn sàng phục vụ xử lý.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Kết quả analytics được tạo ra và các message downstream liên quan được phát hành hoặc lưu nhận phù hợp.
      2. Các bản ghi hoặc insight đủ điều kiện được index vào knowledge layer và gắn với project tương ứng.
      3. Những bản ghi không đủ điều kiện có thể bị skip, còn lỗi indexing được đánh dấu thất bại và lưu thông tin theo dõi tương ứng.
      4. Dữ liệu đã index có thể được dùng cho tìm kiếm và hỏi đáp ở các use case phía sau.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. System Runtime nhận message đầu vào cho analytics processing.
      2. `analysis-srv` giải mã message, xác định project context và chuyển dữ liệu về bundle sẵn sàng cho pipeline.
      3. Hệ thống tạo run context và thực thi analytics pipeline qua các bước chuẩn hóa, lọc, tổ chức thread và NLP enrichment.
      4. `analysis-srv` tạo ra các analytics fact hoặc insight tương ứng.
      5. Hệ thống lưu các kết quả analytics cần thiết và publish message downstream cho các consumer liên quan.
      6. `knowledge-srv` consume message batch completed, insights published hoặc report digest phù hợp với indexing flow.
      7. Knowledge indexing use case kiểm tra dữ liệu, tạo hoặc cập nhật tracking metadata cho từng record cần index.
      8. Hệ thống sinh embedding cho nội dung đủ điều kiện và chuẩn bị payload phục vụ truy hồi.
      9. Hệ thống upsert vector và metadata vào collection theo project trong Qdrant.
      10. Hệ thống cập nhật trạng thái index thành công và làm mới cache tìm kiếm liên quan khi cần.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Index từ legacy batch file* \
      Tại Bước 6 của luồng cơ bản:
      - L1. `knowledge-srv` nhận message batch completed ở định dạng cũ với `file_url` thay vì `documents[]`.
      - L2. Hệ thống tải file JSONL từ object storage.
      - L3. Hệ thống parse file thành batch record và tiếp tục xử lý indexing theo lô.
      - Tiếp tục tại bước 7.

      *Message downstream không yêu cầu index* \
      Tại Bước 6 của luồng cơ bản:
      - S1. `knowledge-srv` nhận insight hoặc digest message với cờ `should_index = false`.
      - S2. Hệ thống bỏ qua record đó mà không tạo thao tác index.
      - Kết thúc nhánh xử lý cho message này.

      *Record bị bỏ qua do duplicate hoặc chất lượng không phù hợp* \
      Tại Bước 7 của luồng cơ bản:
      - D1. Hệ thống phát hiện record trùng nội dung, không hợp lệ hoặc không đạt điều kiện tiền xử lý.
      - D2. Record được đánh dấu `skipped` thay vì tiếp tục sang bước embedding và upsert.
      - Tiếp tục với record khác trong batch.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Message đầu vào không hợp lệ hoặc không hỗ trợ* \
      Tại Bước 2 của luồng cơ bản, nếu `analysis-srv` không parse được message hoặc gặp UAP format không hợp lệ:
      - 2.E.1. Hệ thống ghi log và bỏ qua message lỗi.
      - 2.E.2. Không tạo pipeline run hợp lệ cho message đó.
      - Kết thúc nhánh xử lý cho message này.

      *Lỗi persist hoặc publish analytics từng phần* \
      Tại Bước 5 của luồng cơ bản, nếu một analytics fact không persist hoặc publish được:
      - 5.E.1. Hệ thống ghi log lỗi cho fact tương ứng.
      - 5.E.2. Các fact còn lại vẫn tiếp tục được xử lý theo khả năng.
      - Tiếp tục với các fact khác.

      *Lỗi embedding, database hoặc Qdrant khi index* \
      Tại Bước 8 hoặc Bước 9 của luồng cơ bản, nếu quá trình tạo embedding hoặc upsert thất bại:
      - 9.E.1. Hệ thống đánh dấu record ở trạng thái thất bại.
      - 9.E.2. Hệ thống lưu thông tin lỗi và có thể ghi record vào DLQ hoặc tracking store tương ứng.
      - 9.E.3. Các record khác trong batch vẫn tiếp tục xử lý.

      *Message indexing downstream sai định dạng* \
      Tại Bước 6 của luồng cơ bản, nếu `knowledge-srv` không parse được message indexing:
      - 6.E.1. Hệ thống ghi log cảnh báo và bỏ qua message đó.
      - Kết thúc nhánh xử lý cho message này.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Đây là use case hỗ trợ hệ thống, không được khởi tạo trực tiếp bởi user. Trong implementation hiện tại, analytics và indexing downstream không phải một transaction đồng bộ duy nhất mà là chuỗi consumer bất đồng bộ; vì vậy một phần record có thể thành công, một phần bị skip hoặc failed. `knowledge-srv` hiện hỗ trợ cả format batch cũ dựa trên `file_url` lẫn format mới dựa trên `documents[]`, đồng thời index các insight hoặc digest riêng biệt khi message downstream yêu cầu.
    ],
  )
]

=== 4.4.6 UC-06: Tìm kiếm và hỏi đáp trên knowledge

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-06: Tìm kiếm và hỏi đáp trên knowledge],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng tra cứu tri thức đã được index bằng semantic search hoặc gửi câu hỏi cho chat assistant theo ngữ cảnh campaign. Hệ thống truy xuất dữ liệu liên quan từ knowledge store, tổng hợp kết quả, và trong nhánh chat sẽ kết hợp search result với conversation history để sinh câu trả lời có citations và gợi ý follow-up.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User gửi truy vấn search, câu hỏi chat, hoặc yêu cầu xem lại conversation trong phạm vi một campaign.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền truy cập campaign tương ứng.
      2. Dữ liệu liên quan đã được index vào knowledge layer hoặc đã tồn tại collection phù hợp để truy vấn.
      3. Các thành phần search, embedding, storage conversation và dịch vụ sinh câu trả lời sẵn sàng phục vụ yêu cầu.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Kết quả search hoặc câu trả lời chat được trả về cho user.
      2. Trong nhánh chat, conversation và message mới được lưu cùng citations, search metadata và suggestions tương ứng.
      3. Nếu không có ngữ cảnh liên quan, hệ thống trả kết quả rỗng hoặc cờ thiếu context thay vì giả định có dữ liệu phù hợp.
      4. Các kết quả trả về có thể được dùng để tiếp tục đặt câu hỏi hoặc điều hướng sang truy vấn tiếp theo.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở knowledge assistant trong phạm vi một campaign và gửi câu hỏi chat.
      2. Hệ thống kiểm tra input, xác định intent của truy vấn và tạo conversation mới hoặc nạp conversation hiện có cùng history tương ứng.
      3. Hệ thống xây dựng search input từ câu hỏi, campaign context và các filter liên quan.
      4. `knowledge-srv` resolve campaign thành tập project phù hợp và sinh embedding cho truy vấn.
      5. Hệ thống tìm kiếm song song trên các collection theo project, lọc theo score và tổng hợp search result liên quan.
      6. Hệ thống xây prompt từ câu hỏi, search result và conversation history.
      7. Dịch vụ sinh câu trả lời tạo ra answer dựa trên prompt đã được grounding bởi context truy hồi.
      8. Hệ thống trích citations, suggestions và search metadata từ kết quả truy vấn.
      9. Hệ thống lưu user message, assistant message và cập nhật conversation state.
      10. Hệ thống trả answer, citations, suggestions và metadata cho user.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Search-only không qua chat* \
      Thay cho Bước 1 của luồng cơ bản:
      - S1. User gửi truy vấn search thay vì chat.
      - S2. Hệ thống thực hiện các bước resolve campaign, embed query, search collection và aggregate kết quả.
      - S3. Hệ thống trả danh sách search result, aggregations và cờ `no relevant context` nếu phù hợp.
      - Kết thúc use case.

      *Tiếp tục conversation đã tồn tại* \
      Tại Bước 2 của luồng cơ bản:
      - C1. User gửi thêm message vào một conversation đã có.
      - C2. Hệ thống nạp history của conversation theo giới hạn cho phép.
      - C3. Hệ thống dùng history đó để xây prompt trước khi sinh câu trả lời mới.
      - Tiếp tục tại bước 3.

      *Hệ thống suy ra thêm filter từ nội dung truy vấn* \
      Tại Bước 3 của luồng cơ bản:
      - F1. Nếu user không chỉ định platform nhưng câu hỏi chứa tín hiệu rõ ràng, hệ thống suy luận platform filter phù hợp.
      - F2. Hệ thống áp dụng filter đó vào search input trước khi truy hồi.
      - Tiếp tục tại bước 4.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Input chat/search không hợp lệ* \
      Tại Bước 2 hoặc Bước 3 của luồng cơ bản, nếu campaign thiếu, câu hỏi quá ngắn hoặc quá dài:
      - 3.E.1. Hệ thống từ chối yêu cầu và trả lỗi validation tương ứng.
      - Kết thúc use case.

      *Conversation không tồn tại hoặc đã archived* \
      Tại Bước 2 của luồng cơ bản, nếu user tham chiếu conversation không hợp lệ:
      - 2.E.1. Hệ thống trả lỗi conversation không tồn tại hoặc không còn cho phép tiếp tục.
      - Kết thúc use case.

      *Lỗi search, embedding hoặc sinh câu trả lời* \
      Tại Bước 4 đến Bước 7 của luồng cơ bản, nếu search, embedding hoặc LLM thất bại:
      - 7.E.1. Hệ thống trả lỗi cho nhánh xử lý hiện tại.
      - 7.E.2. Không tạo kết quả answer hoàn chỉnh cho yêu cầu đó.
      - Kết thúc use case.

      *Campaign không có dữ liệu index phù hợp* \
      Tại Bước 5 của luồng search hoặc chat, nếu không có collection tồn tại hoặc không có kết quả đủ score:
      - 5.E.1. Hệ thống trả kết quả ít hoặc không có context liên quan.
      - 5.E.2. Hệ thống tránh giả định có chứng cứ khi không truy hồi được dữ liệu phù hợp.
      - Kết thúc hoặc tiếp tục theo cách hiển thị kết quả rỗng của client.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Trong implementation hiện tại, search và chat dùng chung search foundation: resolve campaign → embed query → search theo collection Qdrant của từng project → aggregate kết quả. `chat` là synchronous RAG entrypoint, lưu conversation/messages vào persistence và trả citations dựa trực tiếp trên search result đã truy hồi. Search cache có thể được dùng trong nhánh search; với những project chưa có collection, hệ thống bỏ qua collection không tồn tại thay vì coi là lỗi toàn cục.
    ],
  )
]

=== 4.4.7 UC-07: Nhận notification và cảnh báo

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-07: Nhận notification và cảnh báo],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: System Runtime
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Hệ thống tiếp nhận các notification event hoặc alert từ backend services, chuẩn hóa payload và route chúng tới kênh delivery phù hợp theo user scope hoặc system scope. Với một số loại sự kiện như crisis alert, campaign event hoặc data onboarding, notification layer còn có thể phát side alert riêng. Nếu người nhận có active compatible connection hoặc lớp presentation phù hợp, thông báo có thể được đẩy tới runtime delivery channel tương ứng.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[Backend service publish notification event hoặc alert vào notification channel tương ứng để yêu cầu delivery tới người nhận phù hợp.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. Có backend service phát sinh notification hoặc alert hợp lệ.
      2. Notification runtime đang subscribe các channel đầu vào tương ứng.
      3. Nếu sử dụng nhánh WebSocket delivery, người nhận có thông tin xác thực hợp lệ và đã thiết lập kết nối tương thích.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Notification payload được chuẩn hóa thành envelope delivery.
      2. Message được route tới user scope hoặc system scope phù hợp.
      3. Nếu có active supported connection, message có thể được đẩy qua kênh realtime tương ứng.
      4. Với một số loại alert, hệ thống có thể phát thêm side alert qua handler chuyên biệt.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. Một backend service phát sinh sự kiện notification hoặc alert cho user hay phạm vi hệ thống.
      2. Service đó publish payload vào Redis channel hoặc notification channel tương ứng.
      3. `notification-srv` subscriber nhận message từ channel đã đăng ký.
      4. Hệ thống parse channel để xác định scope, loại thông báo và recipient liên quan nếu có.
      5. Hệ thống phát hiện message type và transform payload thô thành notification envelope chuẩn.
      6. Nếu loại thông báo yêu cầu escalation phù hợp, hệ thống dispatch alert side-channel tương ứng.
      7. Hệ thống route message vào connection hub theo user scope hoặc broadcast scope.
      8. Nếu người nhận đang có active compatible connection, hệ thống push message tới connection đó.
      9. Lớp client hoặc presentation tiêu thụ message và hiển thị thông báo theo khả năng triển khai của mình.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Kết nối delivery dùng cookie thay vì query token* \
      Trước Bước 8 của luồng cơ bản:
      - W1. Người nhận thiết lập kết nối delivery bằng cookie xác thực thay vì token trên query.
      - W2. Notification layer xác minh token từ cookie trước khi cho phép đăng ký connection.
      - Tiếp tục tại bước 8.

      *Thông báo broadcast hệ thống* \
      Tại Bước 7 của luồng cơ bản:
      - B1. Message thuộc system scope và không ràng buộc với một user cụ thể.
      - B2. Hệ thống broadcast message cho các active connection phù hợp thay vì route tới riêng một user.
      - Tiếp tục tại bước 8.

      *Không có active connection ở thời điểm gửi* \
      Tại Bước 8 của luồng cơ bản:
      - N1. Hệ thống không tìm thấy active compatible connection cho recipient hiện tại.
      - N2. Không có push realtime nào được hoàn tất ở thời điểm đó.
      - Kết thúc nhánh delivery realtime cho message này.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Kết nối hoặc xác thực delivery không hợp lệ* \
      Trước Bước 8 của luồng cơ bản, nếu token/cookie không hợp lệ hoặc websocket upgrade thất bại:
      - 8.E.1. Hệ thống từ chối đăng ký connection.
      - 8.E.2. Message không được đẩy qua nhánh connection đó.
      - Kết thúc use case cho connection hiện tại.

      *Channel hoặc payload notification không hợp lệ* \
      Tại Bước 4 hoặc Bước 5 của luồng cơ bản, nếu channel không parse được hoặc payload sai định dạng:
      - 5.E.1. Hệ thống ghi log cảnh báo và bỏ qua message lỗi.
      - 5.E.2. Không thực hiện route hoặc dispatch cho message đó.
      - Kết thúc nhánh xử lý cho message này.

      *Lỗi alert side-channel* \
      Tại Bước 6 của luồng cơ bản, nếu alert handler phụ thất bại:
      - 6.E.1. Hệ thống ghi log lỗi cho nhánh alert phụ.
      - 6.E.2. Việc route notification realtime chính vẫn có thể tiếp tục nếu hub còn hoạt động.
      - Tiếp tục tại bước 7.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này mô tả notification delivery capability ở mức hệ thống, không khẳng định chi tiết mọi client UI hiện đã consume đầy đủ luồng realtime. Trong implementation hiện tại, notification layer nhận input từ Redis Pub/Sub, transform theo các contract như `DATA_ONBOARDING`, `ANALYTICS_PIPELINE`, `CRISIS_ALERT`, `CAMPAIGN_EVENT`, rồi route vào WebSocket hub hoặc dispatch sang alert side-channel. Delivery realtime phụ thuộc vào việc có active compatible connection tại thời điểm xử lý.
    ],
  )
]

=== 4.4.8 UC-08: Quản lý cấu hình crisis

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-08_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-08: Quản lý cấu hình crisis],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Created by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Date created*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated by*],
    align(center + horizon)[Nhóm tác giả],
    table.cell(align: center + horizon, inset: (y: 0.6em))[*Last updated*],
    align(center + horizon)[29/04/2026],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng thiết lập, xem, cập nhật hoặc xóa cấu hình crisis cho từng project để định nghĩa các trigger theo keyword, volume, sentiment hoặc influencer. Hệ thống kiểm tra project tồn tại, validate cấu hình theo từng nhóm rule và lưu dữ liệu này làm đầu vào cho các luồng giám sát hoặc cảnh báo downstream.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.6em))[User truy cập luồng cấu hình crisis của một project và gửi yêu cầu xem, cập nhật hoặc xóa cấu hình.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền quản lý project tương ứng.
      2. Project liên quan đã tồn tại trong hệ thống.
      3. User có dữ liệu cấu hình phù hợp với các nhóm trigger muốn bật.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Crisis config được tạo mới hoặc cập nhật cho project nếu yêu cầu hợp lệ.
      2. User có thể truy xuất lại chi tiết cấu hình đã lưu cho project.
      3. Nếu user xóa cấu hình, project không còn crisis config tương ứng trong persistence layer.
      4. Cấu hình hợp lệ trở thành đầu vào cho các luồng giám sát crisis downstream.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở trang cấu hình crisis của một project.
      2. Hệ thống nạp thông tin cấu hình hiện có của project nếu đã tồn tại.
      3. User nhập hoặc chỉnh sửa các trigger như keyword, volume, sentiment hoặc influencer.
      4. User gửi yêu cầu lưu cấu hình.
      5. Hệ thống kiểm tra project tồn tại và validate dữ liệu cấu hình theo từng nhóm trigger.
      6. Nếu dữ liệu hợp lệ, `project-srv` tạo mới hoặc cập nhật crisis config gắn với `project_id` tương ứng.
      7. Hệ thống trả lại cấu hình crisis đã lưu thành công cho user.
      8. Cấu hình này sẵn sàng cho các luồng giám sát hoặc cảnh báo downstream sử dụng.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Xem chi tiết cấu hình crisis hiện có* \
      Trước Bước 3 của luồng cơ bản:
      - D1. User chỉ yêu cầu xem cấu hình crisis của project.
      - D2. Hệ thống truy xuất crisis config theo `project_id` và trả về dữ liệu hiện có.
      - D3. Không phát sinh thao tác lưu mới.
      - Kết thúc use case.

      *Xóa cấu hình crisis* \
      Thay cho Bước 4 của luồng cơ bản:
      - X1. User chọn xóa cấu hình crisis của project.
      - X2. Hệ thống xóa bản ghi cấu hình theo `project_id` tương ứng.
      - X3. Hệ thống trả kết quả xóa thành công.
      - Kết thúc use case.

      *Chỉ bật một phần trigger* \
      Tại Bước 3 của luồng cơ bản:
      - P1. User chỉ cung cấp một số nhóm trigger thay vì toàn bộ keyword, volume, sentiment và influencer.
      - P2. Hệ thống chỉ lưu các nhóm trigger được cung cấp và giữ cấu hình phù hợp với request hợp lệ.
      - Tiếp tục tại bước 4.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Project không hợp lệ hoặc không tồn tại* \
      Tại Bước 5 của luồng cơ bản, nếu `project_id` không hợp lệ hoặc project không tồn tại:
      - 5.E.1. Hệ thống từ chối thao tác với crisis config.
      - 5.E.2. Không tạo hoặc cập nhật cấu hình nào.
      - Kết thúc use case.

      *Dữ liệu trigger không hợp lệ* \
      Tại Bước 5 của luồng cơ bản, nếu request không có trigger nào hoặc trigger bật nhưng thiếu rule bắt buộc:
      - 5.E.1. Hệ thống trả lỗi validation tương ứng cho keyword, volume, sentiment hoặc influencer rule.
      - 5.E.2. User chỉnh sửa cấu hình trước khi gửi lại.
      - Tiếp tục tại bước 3.

      *Xóa hoặc truy xuất cấu hình không tồn tại* \
      Trong nhánh detail hoặc delete, nếu project chưa có crisis config:
      - 2.E.1. Hệ thống trả về lỗi not found cho crisis config.
      - Kết thúc use case.

      *Lỗi persistence* \
      Tại Bước 6 của luồng cơ bản hoặc X2 của nhánh xóa, nếu hệ thống không thể lưu hoặc xóa cấu hình:
      - 6.E.1. Hệ thống thông báo thao tác crisis config không hoàn tất.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Notes and issues*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này chỉ bao phủ quản lý cấu hình crisis, không bao gồm bản thân luồng phát hiện crisis runtime. Trong implementation hiện tại, cấu hình được lưu theo `project_id` và hỗ trợ các nhóm trigger như `keywords_trigger`, `volume_trigger`, `sentiment_trigger`, `influencer_trigger`; mỗi nhóm có validation riêng trước khi upsert. Dữ liệu cấu hình sau khi lưu là input cho các luồng giám sát hoặc cảnh báo downstream, chứ không tự kích hoạt detection ngay trong use case này.
    ],
  )
]
