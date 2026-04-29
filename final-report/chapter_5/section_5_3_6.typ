#import "../counters.typ": image_counter, table_counter

=== 5.3.6 Web UI

Web UI là frontend application cung cấp dashboard quản trị, project management interface, và real-time progress visualization. Service này tương tác với tất cả backend services qua REST APIs và WebSocket connections.

Vai trò của Web UI trong kiến trúc tổng thể:

- User Interface: Cung cấp UI cho tất cả Use Cases từ UC-01 đến UC-08.
- Real-time Visualization: Hiển thị progress updates qua WebSocket connections.
- API Client: Gọi REST APIs từ các backend services (Identity, Project, Analytics).
- State Management: Quản lý client-side state.

Service này đáp ứng tất cả Use Cases từ phía user interface và liên quan đến NFRs về Usability (UX requirements).

==== 5.3.6.1 Component Diagram - C4 Level 3

Web UI được tổ chức theo Component-based Architecture:

#align(center)[
  #image("../images/component/webui-component-diagram.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Component Diagram Web UI_])
  #image_counter.step()
]

==== 5.3.6.2 Component Catalog

#context (align(center)[_Bảng #table_counter.display(): Component Catalog - Web UI_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.18fr, 0.32fr, 0.20fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Component*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Responsibility*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Project \ Wizard],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Multi-step form để tạo project cho UC-01],
    table.cell(align: center + horizon, inset: (y: 0.8em))[User input (form data)],
    table.cell(align: center + horizon, inset: (y: 0.8em))[POST /projects API call],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React components],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Progress \ Tracker],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Real-time progress visualization cho UC-06],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket messages],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UI updates],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React + WebSocket],

    table.cell(align: center + horizon, inset: (y: 0.8em))[useWebSocket \ Hook],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection management với auto-reconnect],
    table.cell(align: center + horizon, inset: (y: 0.8em))[ProjectID, UserID],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket connection],
    table.cell(align: center + horizon, inset: (y: 0.8em))[React hooks],

    table.cell(align: center + horizon, inset: (y: 0.8em))[API \ Clients],
    table.cell(align: center + horizon, inset: (y: 0.8em))[REST API calls đến backend services],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API requests],
    table.cell(align: center + horizon, inset: (y: 0.8em))[API responses],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP Client],
  )
]

==== 5.3.6.3 Data Flow

Luồng xử lý chính của Web UI được chia thành 2 flows: Project Creation và Real-time Progress Updates.

===== a. Project Creation Flow

Luồng này được kích hoạt khi user tạo project mới theo UC-01:

#align(center)[
  #image("../images/data-flow/authen.png", width: 90%)
  #context (align(center)[_Hình #image_counter.display(): Luồng Project Creation Flow_])
  #image_counter.step()
]

===== b. Real-time Progress Updates Flow

Luồng này được kích hoạt khi project đang executing theo UC-06:

#context (
  align(center)[
    // #image("../images/data-flow/progress.png", width: 90%)
  ]
)
#context (align(center)[_Hình #image_counter.display(): Luồng Real-time Progress Updates Flow_])
#image_counter.step()


==== 5.3.6.4 Design Patterns áp dụng

Web UI áp dụng các design patterns sau:

- Component-based Architecture: React components như ProjectWizard, ProgressTracker, Dashboard. Mỗi component là một reusable unit với props và state. Reusability cao, maintainability tốt.

- Custom Hooks Pattern: useWebSocket(), useProjectProgress(), useAuth(). Encapsulate logic trong custom hooks, components consume hooks. Logic reuse và separation of concerns.

- Context API Pattern: AuthContext, ProjectContext. React Context để share state across components. Avoid prop drilling và centralized state management.

- Server-Side Rendering: Pages được render trên server, send HTML to client. SEO tốt hơn và initial load nhanh hơn.

==== 5.3.6.5 Performance Targets

#context (align(center)[_Bảng #table_counter.display(): Performance Targets - Web UI_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.40fr, 0.30fr, 0.30fr),
    stroke: 0.5pt,
    align: (left, center, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Metric*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Target*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*NFR Traceability*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dashboard Loading],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 3s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-UX-1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[First Contentful Paint],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 2s],
    table.cell(align: center + horizon, inset: (y: 0.8em))[NFR-UX-1],
    table.cell(align: center + horizon, inset: (y: 0.8em))[WebSocket Update Latency],
    table.cell(align: center + horizon, inset: (y: 0.8em))[< 100ms],
    table.cell(align: center + horizon, inset: (y: 0.8em))[AC-3],
  )
]

==== 5.3.6.6 Thiết kế giao diện

Phần này trình bày thiết kế giao diện người dùng của hệ thống SMAP, bao gồm các màn hình chính phục vụ cho các Use Cases đã định nghĩa trong Chương 4. Giao diện được thiết kế theo nguyên tắc đơn giản, trực quan và tập trung vào trải nghiệm người dùng.

===== a. Màn hình Landing Page

Màn hình Landing Page là điểm tiếp xúc đầu tiên của người dùng với hệ thống SMAP. Giao diện được thiết kế với phong cách hiện đại, tối giản và chuyên nghiệp nhằm tạo ấn tượng ban đầu tích cực cho Marketing Analyst.

#align(center)[
  #image("../images/UI/landing.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Landing Page của hệ thống SMAP_])
  #image_counter.step()
]

Màn hình Landing Page bao gồm các thành phần chính sau:

- Header Navigation: Thanh điều hướng phía trên với logo SMAP, các liên kết đến trang Features, Pricing, About và nút đăng nhập hoặc đăng ký.

- Hero Section: Khu vực giới thiệu chính với tiêu đề nổi bật, mô tả ngắn gọn về giá trị của hệ thống và nút Call-to-Action để bắt đầu sử dụng.

- Feature Highlights: Phần trình bày các tính năng nổi bật của hệ thống như phân tích sentiment, theo dõi đối thủ cạnh tranh và phát hiện xu hướng.

===== b. Màn hình Quản lý danh sách Projects

Màn hình này phục vụ cho UC-05 về Quản lý danh sách Projects, cho phép Marketing Analyst xem, lọc, tìm kiếm và điều hướng đến các chức năng tương ứng với trạng thái của từng project.

#align(center)[
  #image("../images/UI/cacprojects.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Quản lý danh sách Projects_])
  #image_counter.step()
]

Giao diện màn hình Quản lý danh sách Projects được tổ chức với các thành phần sau:

- Thanh công cụ phía trên: Bao gồm ô tìm kiếm theo tên project, bộ lọc theo trạng thái và nút tạo project mới.

- Danh sách Projects: Hiển thị dưới dạng bảng hoặc lưới với các thông tin tên project, trạng thái hiển thị bằng badge màu sắc khác nhau, ngày tạo, lần cập nhật cuối và preview từ khóa thương hiệu.

- Actions theo trạng thái: Mỗi project hiển thị các hành động phù hợp với trạng thái hiện tại. Project ở trạng thái Draft cho phép Khởi chạy hoặc Xóa. Project đang Running cho phép Xem tiến độ. Project Completed cho phép Xem kết quả, Xuất báo cáo hoặc Xóa. Project Failed cho phép Thử lại hoặc Xóa.

- Phân trang: Hỗ trợ infinite scroll hoặc pagination khi số lượng projects vượt quá 20 items mỗi trang.

===== c. Màn hình Dry-run kiểm tra từ khóa

Màn hình này phục vụ cho UC-02 về Kiểm tra từ khóa, cho phép Marketing Analyst xác thực chất lượng từ khóa trước khi lưu project bằng cách xem mẫu kết quả thu thập được.

#align(center)[
  #image("../images/UI/dryrun.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Dry-run kiểm tra từ khóa_])
  #image_counter.step()
]

Giao diện màn hình Dry-run bao gồm các thành phần chính:

- Thông tin từ khóa: Hiển thị danh sách các từ khóa đang được kiểm tra cùng với platform tương ứng.

- Kết quả mẫu: Hiển thị tối đa 3 posts mỗi từ khóa với các thông tin tiêu đề, preview nội dung, platform nguồn, số lượt xem, lượt thích, bình luận và chia sẻ.

- Trạng thái loading: Hiển thị indicator khi đang thu thập mẫu với thông báo tiến độ.

- Nút điều hướng: Cho phép người dùng quay lại chỉnh sửa từ khóa hoặc tiếp tục lưu project.

===== d. Màn hình Dashboard phân tích

Màn hình Dashboard phục vụ cho UC-04 về Xem kết quả phân tích, cung cấp cái nhìn tổng quan về sentiment trends, aspect analysis và competitor comparison cho Marketing Analyst.

#align(center)[
  #image("../images/UI/char1.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Dashboard phân tích tổng quan_])
  #image_counter.step()
]

Giao diện Dashboard được chia thành 4 phần chính theo đặc tả UC-04:

- Biểu đồ Line hoặc Area Chart: Hiển thị số lượng mentions theo thời gian với hỗ trợ radio button chọn khoảng thời gian và tooltip hiển thị chi tiết khi hover.

- Biểu đồ Bar Chart so sánh: Thể hiện share of voice giữa thương hiệu và các đối thủ cạnh tranh, giúp Marketing Analyst đánh giá vị thế thương hiệu trên thị trường.

- Keyword Cloud: Hiển thị top 20 từ khóa được nhắc đến nhiều nhất với kích thước font tỷ lệ thuận với tần suất xuất hiện. Vị trí từ khóa của thương hiệu được highlight để dễ nhận biết.

#align(center)[
  #image("../images/UI/char2.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Biểu đồ so sánh Share of Voice giữa thương hiệu và đối thủ_])
  #image_counter.step()
]

#align(center)[
  #image("../images/UI/char3.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Hiển thị chi tiết một từ khoá_])
  #image_counter.step()
]


#align(center)[
  #image("../images/UI/char4.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Bảng dữ liệu về bài viết thịnh hành_])
  #image_counter.step()
]

Dashboard hỗ trợ các tính năng tương tác sau:

- Bộ lọc: Cho phép lọc theo platform, sentiment, khoảng thời gian và aspect.

- Drilldown: Nhấn vào aspect để xem danh sách posts liên quan, nhấn vào post để xem chi tiết đầy đủ bao gồm cả comments.

- Xuất báo cáo: Nút điều hướng đến UC-06 để tạo và tải file báo cáo.

===== e. Màn hình Trend Dashboard

Màn hình này phục vụ cho UC-07 về Phát hiện trend tự động, hiển thị danh sách các xu hướng nổi bật được hệ thống thu thập và xếp hạng từ các nền tảng mạng xã hội.

#align(center)[
  #image("../images/UI/trend.png", width: 100%)
  #context (align(center)[_Hình #image_counter.display(): Màn hình Trend Dashboard_])
  #image_counter.step()
]

Giao diện Trend Dashboard bao gồm các thành phần:

- Trends Grid: Hiển thị lưới các xu hướng với thông tin tiêu đề, nền tảng nguồn, điểm xu hướng và chỉ số tăng trưởng.

- Bộ lọc: Cho phép lọc theo nền tảng, loại nội dung và khoảng thời gian.

- Thông tin chi tiết: Mỗi trend card hiển thị preview nội dung, số liệu engagement và velocity score.

- Cảnh báo trạng thái: Hiển thị thông báo khi dữ liệu từ một nền tảng gặp sự cố hoặc chưa được cập nhật.

===== f. Nguyên tắc thiết kế giao diện

Giao diện hệ thống SMAP được thiết kế tuân theo các nguyên tắc sau:

- Consistency: Sử dụng hệ thống design tokens thống nhất cho màu sắc, typography, spacing và components trên toàn bộ ứng dụng.

- Responsive Design: Giao diện tương thích với nhiều kích thước màn hình từ desktop đến tablet, đảm bảo trải nghiệm nhất quán.

- Accessibility: Tuân thủ các tiêu chuẩn WCAG về contrast ratio, keyboard navigation và screen reader support.

- Performance: Tối ưu hóa loading time với lazy loading cho images và code splitting cho các components lớn.

- Feedback: Cung cấp phản hồi trực quan cho mọi hành động của người dùng thông qua loading states, success messages và error notifications.
