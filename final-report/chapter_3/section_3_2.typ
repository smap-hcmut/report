#import "../counters.typ": table_counter

== 3.2 Clean Architecture

=== 3.2.1 Nguyên tắc thiết kế

Clean Architecture là một kiểu kiến trúc phần mềm được đề xuất bởi Robert C. Martin nhằm tạo ra các hệ thống dễ hiểu, linh hoạt và dễ bảo trì. Ý tưởng cốt lõi của Clean Architecture là tách biệt các mối quan tâm trong ứng dụng thành các tầng riêng biệt, với nguyên tắc các phụ thuộc chỉ trỏ vào trong. Kiến trúc này đảm bảo rằng logic nghiệp vụ không phụ thuộc vào các chi tiết triển khai như framework, cơ sở dữ liệu, hay giao diện người dùng.

Theo Robert C. Martin, một kiến trúc tốt phải đạt được các mục tiêu sau: độc lập với framework, có khả năng kiểm thử cao, độc lập với giao diện người dùng, độc lập với cơ sở dữ liệu, và độc lập với bất kỳ tác nhân bên ngoài nào. Điều này có nghĩa là các quy tắc nghiệp vụ không nên biết gì về thế giới bên ngoài. Sự độc lập này cho phép thay đổi các chi tiết triển khai mà không ảnh hưởng đến logic nghiệp vụ cốt lõi.

Khả năng kiểm thử là một trong những lợi ích quan trọng nhất của Clean Architecture. Vì logic nghiệp vụ không phụ thuộc vào các phụ thuộc bên ngoài, nó có thể được kiểm thử một cách độc lập mà không cần mock cơ sở dữ liệu, web server, hay bất kỳ dịch vụ bên ngoài nào. Các unit test có thể chạy nhanh và đáng tin cậy vì chúng chỉ kiểm thử logic nghiệp vụ thuần túy.

=== 3.2.2 Các tầng và Dependency Rule

Clean Architecture tổ chức mã nguồn thành các tầng đồng tâm, với logic nghiệp vụ ở trung tâm và các chi tiết triển khai ở bên ngoài. Có bốn tầng chính: Entities, Use Cases, Interface Adapters, và Frameworks and Drivers.

==== 3.2.2.1 Entities

Entities là tầng trong cùng, chứa các quy tắc nghiệp vụ quan trọng nhất và ổn định nhất của ứng dụng. Đây là các mô hình miền đại diện cho các khái niệm nghiệp vụ cốt lõi. Entities không phụ thuộc vào bất kỳ tầng nào khác và không biết gì về use case, controller, hay cơ sở dữ liệu. Chúng chỉ chứa logic nghiệp vụ thuần túy, các quy tắc mà sẽ tồn tại ngay cả khi không có ứng dụng.

==== 3.2.2.2 Use Cases

Tầng Use Cases chứa các quy tắc nghiệp vụ cụ thể của ứng dụng, các quy tắc mô tả cách ứng dụng sử dụng entities để đạt được mục tiêu cụ thể. Mỗi use case đại diện cho một chức năng nghiệp vụ cụ thể. Use Cases điều phối luồng dữ liệu đến và từ entities, và chỉ đạo entities thực hiện các quy tắc nghiệp vụ của chúng. Use Cases không biết gì về giao diện người dùng, cơ sở dữ liệu, hay các dịch vụ bên ngoài, chúng chỉ định nghĩa các interface mà các tầng bên ngoài phải triển khai.

==== 3.2.2.3 Interface Adapters

Tầng Interface Adapters chịu trách nhiệm chuyển đổi dữ liệu giữa định dạng phù hợp với use case và định dạng phù hợp với các tác nhân bên ngoài như cơ sở dữ liệu hay web. Tầng này bao gồm các controller nhận HTTP request và gọi use case, các presenter định dạng dữ liệu để trả về cho giao diện người dùng, và các gateway hoặc repository triển khai các interface được định nghĩa bởi use case để truy cập cơ sở dữ liệu. Đây là nơi dependency inversion xảy ra, use case định nghĩa interface, và adapter triển khai chúng.

==== 3.2.2.4 Frameworks and Drivers

Tầng ngoài cùng chứa các framework và công cụ như cơ sở dữ liệu, web framework, API bên ngoài. Đây là nơi tất cả các chi tiết triển khai cụ thể nằm. Mã nguồn trong tầng này thường rất ít vì phần lớn công việc được thực hiện bởi các thư viện bên thứ ba. Tầng này giao tiếp với tầng Interface Adapters để tích hợp với phần còn lại của ứng dụng.

==== 3.2.2.5 Dependency Rule

Nguyên tắc quan trọng nhất của Clean Architecture là Dependency Rule: các phụ thuộc mã nguồn chỉ được trỏ vào trong. Mã ở tầng trong không được biết gì về mã ở tầng ngoài. Entities không biết gì về Use Cases. Use Cases không biết gì về Controller hay cơ sở dữ liệu. Điều này đạt được thông qua dependency inversion, tầng trong định nghĩa interface, tầng ngoài triển khai chúng.


=== 3.2.3 So sánh với MVC và Hexagonal Architecture

#context (align(center)[_Bảng #table_counter.display(): So sánh Clean Architecture, MVC và Hexagonal Architecture_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*Clean Architecture*],
    table.cell(align: center + horizon)[*MVC*],
    table.cell(align: center + horizon)[*Hexagonal Architecture*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Testability],
    table.cell(align: center + horizon)[Rất cao, business logic hoàn toàn độc lập],
    table.cell(align: center + horizon)[Trung bình, business logic thường lẫn với controller],
    table.cell(align: center + horizon)[Rất cao, tương tự Clean Architecture],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Complexity],
    table.cell(align: center + horizon)[Cao, nhiều tầng và abstractions],
    table.cell(align: center + horizon)[Thấp, cấu trúc đơn giản],
    table.cell(align: center + horizon)[Trung bình, ít tầng hơn Clean Architecture],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Learning Curve],
    table.cell(align: center + horizon)[Dốc, cần hiểu dependency inversion],
    table.cell(align: center + horizon)[Thoải, pattern phổ biến],
    table.cell(align: center + horizon)[Trung bình, concepts dễ hiểu hơn],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Flexibility],
    table.cell(align: center + horizon)[Rất cao, dễ thay đổi triển khai],
    table.cell(align: center + horizon)[Thấp, tight coupling với framework],
    table.cell(align: center + horizon)[Cao, ports và adapters dễ thay đổi],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Boilerplate],
    table.cell(align: center + horizon)[Nhiều, cần nhiều interfaces và abstractions],
    table.cell(align: center + horizon)[Ít, mã nguồn ngắn gọn hơn],
    table.cell(align: center + horizon)[Trung bình, cần ports và adapters],
  )
]

Clean Architecture và Hexagonal Architecture có nhiều điểm tương đồng, cả hai đều nhấn mạnh việc tách biệt logic nghiệp vụ khỏi các mối quan tâm bên ngoài thông qua abstraction. Sự khác biệt chính là Clean Architecture có cấu trúc tầng rõ ràng hơn với sự phân biệt giữa Entities và Use Cases, trong khi Hexagonal Architecture tập trung vào khái niệm port và adapter. Clean Architecture có thể được xem như một sự phát triển của Hexagonal Architecture với cấu trúc rõ ràng hơn.

So với MVC, Clean Architecture phức tạp hơn đáng kể nhưng mang lại khả năng kiểm thử và tính linh hoạt cao hơn nhiều. MVC phù hợp cho các ứng dụng nhỏ, đơn giản nơi logic nghiệp vụ không phức tạp và không cần độ bao phủ kiểm thử cao. Tuy nhiên, khi ứng dụng phát triển, MVC thường dẫn đến các controller phình to chứa cả logic nghiệp vụ lẫn logic trình bày, khó kiểm thử và bảo trì.
