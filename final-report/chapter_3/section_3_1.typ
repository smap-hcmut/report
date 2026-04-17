#import "../counters.typ": table_counter

== 3.1 Kiến trúc Microservices

=== 3.1.1 Định nghĩa và nguồn gốc

Kiến trúc Microservices là một phong cách kiến trúc phần mềm trong đó một ứng dụng được xây dựng như một tập hợp các dịch vụ nhỏ, độc lập, mỗi dịch vụ chạy trong tiến trình riêng và giao tiếp với nhau thông qua các cơ chế nhẹ như HTTP API hoặc Message Queue. Theo Martin Fowler, Microservices là cách tiếp cận để phát triển một ứng dụng đơn lẻ như một bộ các dịch vụ nhỏ, mỗi dịch vụ chạy trong tiến trình riêng và giao tiếp với các cơ chế nhẹ, thường là HTTP Resource API.

Sam Newman mở rộng định nghĩa này bằng cách nhấn mạnh rằng Microservices là các dịch vụ có thể triển khai độc lập và được tổ chức xung quanh các khả năng nghiệp vụ. Mỗi dịch vụ thường sở hữu logic xử lý và dữ liệu liên quan của riêng nó, qua đó tạo điều kiện cho việc phát triển, triển khai và mở rộng theo từng thành phần tương đối độc lập.

=== 3.1.2 Đặc điểm chính

==== 3.1.2.1 Loose Coupling

Các vi dịch vụ được thiết kế để có mức độ liên kết thấp với nhau, nghĩa là thay đổi trong một dịch vụ không yêu cầu thay đổi trong các dịch vụ khác. Mỗi dịch vụ có giao diện rõ ràng và giao tiếp thông qua các API được định nghĩa tốt. Điều này cho phép các nhóm phát triển các dịch vụ một cách độc lập mà không cần phối hợp chặt chẽ với các nhóm khác. Liên kết lỏng lẻo cũng giảm thiểu rủi ro khi thay đổi, vì một lỗi trong một dịch vụ không lan truyền sang các dịch vụ khác.

==== 3.1.2.2 Triển khai độc lập

Một trong những lợi ích quan trọng nhất của kiến trúc Microservices là khả năng triển khai từng dịch vụ một cách độc lập mà không cần triển khai lại toàn bộ hệ thống. Điều này cho phép các nhóm phát triển và phát hành tính năng mới nhanh hơn, giảm thời gian ngừng hoạt động và rủi ro khi triển khai. Mỗi dịch vụ có thể có chu kỳ phát hành riêng, cho phép các nhóm làm việc với tốc độ khác nhau tùy theo nhu cầu nghiệp vụ.

==== 3.1.2.3 Tổ chức theo khả năng nghiệp vụ

Các vi dịch vụ được tổ chức xung quanh các khả năng nghiệp vụ thay vì các lớp kỹ thuật. Mỗi dịch vụ đại diện cho một lĩnh vực nghiệp vụ cụ thể và sở hữu toàn bộ ngăn xếp công nghệ cần thiết để thực hiện chức năng đó, từ giao diện người dùng đến cơ sở dữ liệu. Cách tiếp cận này phản ánh cấu trúc tổ chức của doanh nghiệp và cho phép các nhóm đa chức năng làm việc hiệu quả hơn.

==== 3.1.2.4 Quản lý dữ liệu phi tập trung

Trong kiến trúc Microservices, các dịch vụ thường hướng tới việc quản lý dữ liệu theo cách tách biệt tương đối, thay vì phụ thuộc vào một mô hình dữ liệu tập trung duy nhất. Cách tiếp cận này cho phép mỗi dịch vụ lựa chọn công nghệ và cách tổ chức dữ liệu phù hợp hơn với nhu cầu riêng. Tuy nhiên, nó cũng đặt ra thách thức về tính nhất quán dữ liệu và giao dịch phân tán. Vì vậy, các hệ thống microservices thường phải sử dụng những chiến lược như eventual consistency hoặc các cơ chế điều phối phù hợp để kiểm soát nhất quán dữ liệu.

==== 3.1.2.5 Tự động hóa hạ tầng

Kiến trúc Microservices thường kéo theo nhu cầu tự động hóa cao trong triển khai, giám sát và quản lý hạ tầng. Khi số lượng dịch vụ tăng lên, việc vận hành thủ công trở nên khó duy trì và dễ phát sinh sai lệch giữa các môi trường. Vì vậy, microservices thường đi kèm với các công cụ và quy trình hỗ trợ container hóa, điều phối triển khai, giám sát và tái tạo môi trường một cách nhất quán.

=== 3.1.3 So sánh với kiến trúc Monolithic

#context (align(center)[_Bảng #table_counter.display(): So sánh Microservices và Monolithic_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.5fr, 1.5fr),
    stroke: 0.5pt,
    align: (left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*Microservices*],
    table.cell(align: center + horizon)[*Monolithic*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Khả năng mở rộng],
    table.cell(align: left + horizon)[Có thể mở rộng từng service độc lập theo nhu cầu cụ thể],
    table.cell(align: left + horizon)[Phải mở rộng toàn bộ ứng dụng],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Triển khai],
    table.cell(align: left + horizon)[Triển khai từng service độc lập, giảm rủi ro],
    table.cell(align: left + horizon)[Triển khai toàn bộ ứng dụng, thời gian ngừng hoạt động cao hơn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Phát triển],
    table.cell(align: left + horizon)[Nhiều nhóm có thể làm việc song song trên các service khác nhau],
    table.cell(align: left + horizon)[Một codebase lớn, dễ xung đột mã nguồn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Gỡ lỗi],
    table.cell(align: left + horizon)[Phức tạp hơn do distributed tracing, cần công cụ chuyên dụng],
    table.cell(align: left + horizon)[Đơn giản hơn, có thể gỡ lỗi trong một tiến trình],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Tính nhất quán dữ liệu],
    table.cell(align: left + horizon)[Eventual consistency, cần xử lý distributed transactions],
    table.cell(align: left + horizon)[Strong consistency với ACID transactions],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Chi phí hạ tầng],
    table.cell(align: left + horizon)[Chi phí cao hơn do cần nhiều tài nguyên và công cụ quản lý],
    table.cell(align: left + horizon)[Chi phí thấp hơn cho hệ thống nhỏ],
  )
]

Kiến trúc Microservices mang lại nhiều lợi ích cho các hệ thống có phạm vi chức năng lớn hoặc cần tách biệt rõ các khả năng nghiệp vụ. Khả năng mở rộng và triển khai tương đối độc lập giúp tối ưu hóa tài nguyên và giảm rủi ro khi thay đổi từng phần của hệ thống. Đồng thời, cách tiếp cận này cũng hỗ trợ lựa chọn công nghệ linh hoạt hơn cho từng dịch vụ.

Tuy nhiên, Microservices cũng đi kèm với những thách thức rõ rệt. Độ phức tạp vận hành tăng lên khi phải quản lý nhiều dịch vụ, nhiều điểm giao tiếp và nhiều lớp dữ liệu. Độ trễ mạng, độ tin cậy của các kết nối liên dịch vụ, cũng như bài toán kiểm thử tích hợp và nhất quán dữ liệu đều trở nên khó xử lý hơn so với kiến trúc nguyên khối.

Ngược lại, kiến trúc Monolithic thường phù hợp hơn với các ứng dụng nhỏ hoặc các hệ thống chưa có nhu cầu tách biệt rõ theo nhiều khả năng nghiệp vụ. Việc phát triển, triển khai và gỡ lỗi thường trực tiếp hơn khi toàn bộ mã nguồn và dữ liệu tập trung trong một khối thống nhất.

Những đặc điểm trên là cơ sở để sử dụng kiến trúc Microservices như một nền tảng lý thuyết phù hợp khi phân tích và thiết kế hệ thống SMAP ở các chương sau.
