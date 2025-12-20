== 5.1 Giới thiệu và phương pháp tiếp cận

Chương này trình bày kiến trúc tổng thể của hệ thống SMAP (Social Media Analytics Platform), bao gồm các quyết định thiết kế quan trọng, cấu trúc các thành phần và công nghệ được lựa chọn. Kiến trúc được thiết kế dựa trên các yêu cầu ở mục 4.2 (Functional Requirements) và 4.3 (Non-Functional Requirements), tập trung vào các nhóm tiêu chí chính sau:

#list(
  tight: true,
  [
    *Khả năng mở rộng (Scalability):* Xử lý 500k posts/ngày, 5.000 messages/giây và mở rộng dữ liệu 100% mỗi năm để tránh nghẽn cổ chai.
  ],
  [
    *Hiệu năng (Performance):* Dashboard response time < 500ms (p99), tìm kiếm KOC ≤ 2s và xuất báo cáo ≤ 5s nhằm tối ưu trải nghiệm người dùng theo thời gian thực.
  ],
  [
    *Tính sẵn sàng (Availability):* Đảm bảo 99.5% cho toàn hệ thống và 99.9% đối với Alert Service để không bỏ lỡ sự kiện quan trọng.
  ],
  [
    *Khả năng bảo trì (Maintainability):* CI/CD < 15 phút, tuân thủ coding standards và cập nhật ADR cho mỗi quyết định kiến trúc để đảm bảo chất lượng khi mở rộng đội ngũ.
  ],
)

#import "../counters.typ": table_counter, image_counter

#image("../images/chart/NFRs_rada_chart.png")
#context (align(center)[_Hình #image_counter.display(): Tổng quan các nhóm NFR_])
#image_counter.step()

Tổng quan NFR được phân loại thành bảy nhóm: Performance, Scalability, Availability, Reliability, Maintainability, Observability và Usability. Mỗi nhóm được đánh giá theo số lượng yêu cầu liên quan và mức độ ưu tiên vận hành, giúp nắm bắt toàn bộ các khía cạnh kỹ thuật trọng yếu.

=== 5.1.1 Nguyên tắc thiết kế

Để đảm bảo hệ thống SMAP đáp ứng hiệu quả các yêu cầu phi chức năng về hiệu năng và khả năng mở rộng, kiến trúc hệ thống tuân thủ 5 nguyên tắc thiết kế cốt lõi. Các nguyên tắc này được triển khai theo thứ tự từ tầm nhìn chiến lược (Strategic Design), định hình kiến trúc tổng thể (Architectural Style) đến các mẫu thiết kế kỹ thuật cụ thể (Tactical Patterns).

====== a. Domain-Driven Design (DDD – Thiết kế hướng miền nghiệp vụ):
ddd đóng vai trò nền tảng chiến lược, giúp kiểm soát độ phức tạp domain bằng cách mô hình hóa nghiệp vụ thay vì phụ thuộc vào kỹ thuật (database-first). Hệ thống được chia thành các Bounded Context rõ ràng như Data Collection, Content Analysis, Campaign Management và IAM, giảm chồng chéo logic và tạo nền tảng cho kiến trúc Microservices.

*Tài liệu tham khảo:* E. Evans, “Domain-Driven Design: Tackling Complexity in the Heart of Software”, 2003.

====== b. Microservices Architecture (Kiến trúc vi dịch vụ):
dựa trên các Bounded Context, hệ thống hiện thực hóa dưới dạng microservices để tuân thủ nguyên tắc Single Responsibility và Decentralized Data Management. Ví dụ, Crawler Service (IO-bound) và Analytics Service (CPU-bound) có thể scale độc lập với API Service (Golang), cô lập lỗi của từng service.

*Tài liệu tham khảo:* M. Fowler, “Microservices: a definition of this new architectural term”, 2014.

====== c. Event-Driven Architecture (Kiến trúc hướng sự kiện):
cơ chế giao tiếp chính giữa các microservices là bất đồng bộ. Khi có dữ liệu mới, sự kiện được phát qua Message Broker để các consumer xử lý theo tốc độ riêng, giúp tăng availability và tránh back-pressure.

*Tài liệu tham khảo:* G. Hohpe & B. Woolf, “Enterprise Integration Patterns”, 2003.

====== d. Claim Check Pattern:
mẫu thiết kế này tối ưu hiệu năng khi xử lý dữ liệu đa phương tiện kích thước lớn. Payload thô được lưu vào Object Storage (MinIO/S3), còn message chỉ chứa Reference ID/Claim Check để các service truy vấn ngược, giảm tải cho Message Queue.

*Tài liệu tham khảo:* Microsoft Azure Architecture Patterns, “Claim-Check Pattern”.

====== e. SOLID Principles:
ở cấp triển khai chi tiết, SOLID đảm bảo mã nguồn dễ đọc, dễ kiểm thử và mở rộng, hỗ trợ quy trình CI/CD hạn chế regression.

Bảng dưới đây thể hiện mối liên hệ giữa từng nguyên tắc và các chỉ số chất lượng mục tiêu:

#context (align(center)[_Bảng #table_counter.display(): Liên hệ nguyên tắc thiết kế_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.22fr, 0.26fr, 0.36fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    [*Nguyên tắc thiết kế*], [*Phạm vi áp dụng*], [*NFR mục tiêu*], [*Đóng góp chính cho SMAP*],
    [DDD], [Toàn hệ thống], [Maintainability, Understandability], [Xác định ranh giới nghiệp vụ rõ ràng],
    [Microservices], [Kiến trúc vật lý], [Scalability, Fault Tolerance], [Scale độc lập Crawler và Analyzer],
    [Event-Driven], [Giao tiếp liên dịch vụ], [Performance, Decoupling], [Xử lý bất đồng bộ lưu lượng lớn],
    [Claim Check], [Xử lý dữ liệu], [Performance, Efficiency], [Tối ưu băng thông Message Queue],
    [SOLID], [Source code], [Testability, Maintainability], [Đảm bảo chất lượng code nội tại],
  )
]

=== 5.1.2 Phương pháp mô hình hóa kiến trúc

Để thống nhất nhận thức kiến trúc giữa các bên liên quan, báo cáo áp dụng C4 Model (Context, Containers, Components, Code) [S. Brown, 2018] nhằm minh họa hệ thống theo bốn cấp độ “zoom-in”.

====== Các cấp độ C4 áp dụng cho SMAP

1. *Level 1 – System Context:* Định nghĩa phạm vi và mối quan hệ của SMAP với các tác nhân bên ngoài trong toàn bộ hệ sinh thái.
    - Mục tiêu: Xác định vai trò của SMAP trong bức tranh tổng thể.
    - Đối tượng mô tả: SMAP System (hộp đen), Actors (Brand Manager, Data Analyst, Admin) và hệ thống ngoại vi (TikTok API, YouTube Data API, Email Service, Notification Push Service).
    - Hình ảnh chi tiết: xem mục 4.6.4.

2. *Level 2 – Container:* Làm rõ các đơn vị triển khai độc lập (ứng dụng, cơ sở dữ liệu, hàng đợi, hạ tầng).
    - Mục tiêu: Trả lời “Hệ thống gồm thành phần nào và tương tác ra sao?”
    - Container chính: Web Application (ReactJS), API Gateway (Golang/Nginx), các microservice (Crawler – Python, Analyzer – Python/FastAPI, Campaign – Golang), Data Stores (PostgreSQL, MongoDB, MinIO, Redis).
    - Hình ảnh chi tiết: xem mục 4.6.5.

3. *Level 3 – Component:* Diễn tả cấu trúc nội bộ của từng container, đặc biệt với microservice phức tạp.
    - Mục tiêu: Làm rõ tổ chức nội bộ và các luồng tương tác (Controller, Service, Repository, Utility).
    - Hình ảnh chi tiết: Analytics Service và Crawler Service ở mục 4.6.6.

4. *Level 4 – Code:* Chi tiết nhất (class diagram, ERD). Nội dung này nằm ở các chương thiết kế dữ liệu và hiện thực.

Bảng tóm tắt phạm vi, độ chi tiết và đối tượng đọc của từng cấp độ:

#context (align(center)[_Bảng #table_counter.display(): Tóm tắt phạm vi biểu đồ C4_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.11fr, 0.2fr, 0.23fr, 0.25fr, 0.22fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),
    [*Level*], [*Tên biểu đồ*], [*Phạm vi (Scope)*], [*Chi tiết kỹ thuật*], [*Đối tượng chính*],
    [Level 1], [System Context], [Toàn bộ hệ sinh thái dự án], [Thấp – không đề cập công nghệ], [Business Stakeholders, PM],
    [Level 2], [Container Diagram], [Toàn hệ thống SMAP], [Trung bình – giao thức, tech stack], [Architects, Lead Developers],
    [Level 3], [Component Diagram], [Một service cụ thể], [Cao – implementation logic], [Developers],
    [Level 4], [ERD / Class Diagram], [Database / Module], [Rất cao – cấu trúc dữ liệu], [Developers, DBAs],
  )
]
