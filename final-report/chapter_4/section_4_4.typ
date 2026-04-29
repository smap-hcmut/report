// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.4 Use Case

Sau khi xác định các yêu cầu chức năng và phi chức năng, phần này trình bày các use case cốt lõi của hệ thống SMAP ở mức đủ để mô tả cách hệ thống được sử dụng và vận hành. Các use case ở đây được viết ở mức capability, bám current implementation và có thể nối trực tiếp sang service boundaries, API routes hoặc runtime flows tương ứng.

#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1.4fr, 0.9fr, 1.5fr),
    stroke: 0.5pt,
    align: (center + horizon, left + horizon, center + horizon, left + horizon),

    table.header([*ID*], [*Tên Use Case*], [*Actor chính*], [*Phạm vi chính*]),

    [UC-01], [Authenticate User], [Nhóm người dùng chuyên môn nội bộ], [Xác thực người dùng và thiết lập phiên truy cập],
    [UC-02], [Create Campaign and Project], [Nhóm người dùng chuyên môn nội bộ], [Tạo campaign/project và business context],
    [UC-03], [Configure Datasource and Run Dry Run], [Nhóm người dùng chuyên môn nội bộ], [Tạo datasource, target và kiểm tra readiness],
    [UC-04], [Control Project Lifecycle], [Nhóm người dùng chuyên môn nội bộ / System Runtime], [Kiểm tra readiness, activate, pause, resume, archive],
    [UC-05], [Execute Analytics and Build Knowledge], [System Runtime], [Consume dữ liệu, chạy analytics pipeline, index tri thức],
    [UC-06], [Search and Chat Over Knowledge], [Nhóm người dùng chuyên môn nội bộ], [Tìm kiếm, tra cứu và hỏi đáp theo ngữ cảnh],
    [UC-07], [Receive Realtime Alerts], [Nhóm người dùng chuyên môn nội bộ], [Nhận thông báo và cập nhật thời gian thực],
    [UC-08], [Manage Crisis Configuration], [Nhóm người dùng chuyên môn nội bộ], [Thiết lập và quản lý cấu hình giám sát khủng hoảng],
  )
]

=== 4.4.1 UC-01: Authenticate User

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Cho phép người dùng đăng nhập và thiết lập phiên truy cập hợp lệ để sử dụng các chức năng được bảo vệ.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Người dùng chưa có phiên hợp lệ hoặc cần xác thực lại.],
    [*Kích hoạt*], [Người dùng truy cập luồng đăng nhập.],
    [*Hậu điều kiện*], [JWT/cookie hoặc session hợp lệ được thiết lập; người dùng có thể truy cập protected routes.],
  )
]

Luồng chính:

1. Người dùng truy cập luồng đăng nhập.
2. `identity-srv` chuyển hướng người dùng sang nhà cung cấp định danh.
3. Sau khi xác thực thành công, callback được trả về hệ thống.
4. `identity-srv` tạo session và phát token/cookie phục vụ truy cập.
5. Người dùng có thể truy cập các route được bảo vệ hoặc lấy thông tin người dùng hiện tại.

Minh họa hiện thực:

- `../identity-srv/internal/authentication/delivery/http/routes.go`
- `../identity-srv/internal/authentication/delivery/http/oauth.go`

=== 4.4.2 UC-02: Create Campaign and Project

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Tạo campaign hoặc project làm ngữ cảnh nghiệp vụ cho các lane xử lý dữ liệu về sau.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Người dùng đã đăng nhập.],
    [*Kích hoạt*], [Người dùng chọn tạo campaign hoặc project mới.],
    [*Hậu điều kiện*], [Campaign và project được lưu trong persistence layer cùng metadata ban đầu.],
  )
]

Luồng chính:

1. Người dùng gửi yêu cầu tạo campaign hoặc project.
2. `project-srv` xác thực yêu cầu và kiểm tra dữ liệu đầu vào.
3. Hệ thống lưu campaign/project vào database.
4. Dữ liệu business context được trả về để tiếp tục cấu hình downstream.

Minh họa hiện thực:

- `../project-srv/internal/project/delivery/http/routes.go`
- `../project-srv/internal/project/repository/postgre/project.go`

=== 4.4.3 UC-03: Configure Datasource and Run Dry Run

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Tạo datasource, cấu hình crawl target và kiểm tra readiness trước khi chạy chính thức.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Project đã tồn tại.],
    [*Kích hoạt*], [Người dùng cấu hình nguồn dữ liệu và chạy dry run.],
    [*Hậu điều kiện*], [Datasource, target và kết quả dry run được lưu để phục vụ các bước vận hành sau.],
  )
]

Luồng chính:

1. Người dùng tạo datasource cho project.
2. Người dùng thêm hoặc kích hoạt crawl target phù hợp.
3. Người dùng khởi chạy dry run.
4. Hệ thống lưu kết quả dry run và các bằng chứng readiness liên quan.

Minh họa hiện thực:

- `../ingest-srv/internal/datasource/delivery/http/routes.go`
- `../ingest-srv/internal/dryrun/delivery/http/routes.go`
- `../ingest-srv/internal/datasource/usecase/target.go`

=== 4.4.4 UC-04: Control Project Lifecycle

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Điều khiển vòng đời project thông qua kiểm tra readiness và các thao tác activate, pause, resume, archive hoặc unarchive.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ / System Runtime],
    [*Tiền điều kiện*], [Project đã tồn tại và có trạng thái phù hợp với thao tác được yêu cầu.],
    [*Kích hoạt*], [Người dùng hoặc runtime lane gửi yêu cầu thay đổi trạng thái project.],
    [*Hậu điều kiện*], [Trạng thái project và runtime liên quan được cập nhật phù hợp theo control flow hiện tại.],
  )
]

Luồng chính:

1. Hệ thống kiểm tra trạng thái hiện tại và readiness của project.
2. `project-srv` gọi internal APIs của `ingest-srv` để kiểm tra hoặc điều khiển runtime tương ứng.
3. Nếu thao tác hợp lệ, hệ thống cập nhật trạng thái project.
4. Event hoặc trạng thái downstream được phát hành theo lane hiện tại của hệ thống.

Minh họa hiện thực:

- `../project-srv/internal/project/usecase/lifecycle.go`
- `../project-srv/pkg/microservice/ingest/usecase.go`
- `../ingest-srv/internal/datasource/usecase/project_lifecycle.go`

=== 4.4.5 UC-05: Execute Analytics and Build Knowledge

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Tiếp nhận dữ liệu đầu vào đã chuẩn hóa, thực thi analytics pipeline và xây dựng knowledge index downstream.],
    [*Actor chính*], [System Runtime],
    [*Tiền điều kiện*], [Dữ liệu chuẩn hóa đã được publish vào lane analytics.],
    [*Kích hoạt*], [Message xuất hiện trên topic hoặc channel đầu vào của analytics runtime.],
    [*Hậu điều kiện*], [Kết quả analytics được sinh ra và dữ liệu phục vụ knowledge layer được index downstream.],
  )
]

Luồng chính:

1. `analysis-srv` consume message đầu vào từ analytics lane.
2. Hệ thống chạy pipeline NLP và các bước xử lý liên quan.
3. Kết quả được publish ra các lane downstream.
4. `knowledge-srv` consume dữ liệu downstream và thực hiện indexing.

Minh họa hiện thực:

- `../analysis-srv/internal/consumer/server.py`
- `../analysis-srv/internal/pipeline/usecase/usecase.py`
- `../knowledge-srv/internal/indexing/delivery/kafka/consumer/consumer.go`

=== 4.4.6 UC-06: Search and Chat Over Knowledge

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-06_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Cho phép người dùng tìm kiếm, tra cứu và hỏi đáp theo ngữ cảnh trên dữ liệu đã được index.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Người dùng đã đăng nhập và dữ liệu liên quan đã được index.],
    [*Kích hoạt*], [Người dùng gửi truy vấn search hoặc chat.],
    [*Hậu điều kiện*], [Kết quả truy vấn hoặc câu trả lời được trả về cho người dùng.],
  )
]

Luồng chính:

1. Người dùng gửi yêu cầu search hoặc chat.
2. `knowledge-srv` xác thực yêu cầu.
3. Search usecase truy vấn các lớp dữ liệu phù hợp.
4. Chat usecase kết hợp search results với generation hoặc notebook logic tương ứng.

Minh họa hiện thực:

- `../knowledge-srv/internal/search/delivery/http/routes.go`
- `../knowledge-srv/internal/chat/delivery/http/routes.go`
- `../knowledge-srv/internal/search/usecase/search.go`
- `../knowledge-srv/internal/chat/usecase/chat.go`

=== 4.4.7 UC-07: Receive Realtime Alerts

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-07_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Đẩy cảnh báo hoặc cập nhật trạng thái theo thời gian thực tới người dùng qua các kênh phù hợp.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Người dùng có JWT/cookie hợp lệ và đã thiết lập kết nối phù hợp.],
    [*Kích hoạt*], [Backend services publish message vào Redis channels hoặc lane tương ứng.],
    [*Hậu điều kiện*], [Client nhận được thông báo hoặc cập nhật thời gian thực tương ứng.],
  )
]

Luồng chính:

1. Client mở kết nối `GET /ws`.
2. `notification-srv` xác thực token hoặc cookie.
3. Backend publish message vào channel phù hợp.
4. `notification-srv` subscribe, transform và đẩy message đến client.

Minh họa hiện thực:

- `../notification-srv/internal/websocket/delivery/http/routes.go`
- `../notification-srv/internal/websocket/delivery/http/handlers.go`
- `../notification-srv/documents/contracts.md`

=== 4.4.8 UC-08: Manage Crisis Configuration

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-08_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top),

    [*Mục tiêu*], [Cho phép người dùng thiết lập, xem và cập nhật cấu hình giám sát khủng hoảng cho từng project.],
    [*Actor chính*], [Nhóm người dùng chuyên môn nội bộ],
    [*Tiền điều kiện*], [Người dùng đã đăng nhập và project liên quan đã tồn tại.],
    [*Kích hoạt*], [Người dùng truy cập luồng cấu hình crisis monitor hoặc crisis rule.],
    [*Hậu điều kiện*], [Cấu hình crisis được lưu và sẵn sàng cho các luồng giám sát liên quan.],
  )
]

Luồng chính:

1. Người dùng truy cập luồng cấu hình crisis.
2. Hệ thống nhận dữ liệu cấu hình và kiểm tra tính hợp lệ.
3. `project-srv` lưu hoặc cập nhật crisis configuration gắn với project.
4. Dữ liệu cấu hình được dùng làm đầu vào cho các luồng giám sát liên quan.

Minh họa hiện thực:

- `../project-srv/internal/crisis/delivery/http/routes.go`
