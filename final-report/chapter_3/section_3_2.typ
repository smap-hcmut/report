#import "../counters.typ": table_counter

== 3.2 Clean Architecture

=== 3.2.1 Nguyên tắc thiết kế

Clean Architecture là một kiểu kiến trúc phần mềm được đề xuất bởi Robert C. Martin nhằm tạo ra các hệ thống dễ hiểu, linh hoạt và dễ bảo trì. Ý tưởng cốt lõi của Clean Architecture là tách biệt các mối quan tâm trong ứng dụng thành các tầng riêng biệt, với nguyên tắc các phụ thuộc chỉ trỏ vào trong. Kiến trúc này đảm bảo rằng logic nghiệp vụ không phụ thuộc vào các chi tiết triển khai như framework, cơ sở dữ liệu, hay giao diện người dùng.

Theo Robert C. Martin, một kiến trúc tốt phải đạt được các mục tiêu sau: độc lập với framework, có khả năng kiểm thử cao, độc lập với giao diện người dùng, độc lập với cơ sở dữ liệu, và độc lập với bất kỳ tác nhân bên ngoài nào. Điều này có nghĩa là các quy tắc nghiệp vụ không nên biết gì về thế giới bên ngoài. Sự độc lập này cho phép thay đổi các chi tiết triển khai mà không ảnh hưởng đến logic nghiệp vụ cốt lõi.

Khả năng kiểm thử là một trong những lợi ích quan trọng nhất của Clean Architecture. Vì logic nghiệp vụ không phụ thuộc vào các phụ thuộc bên ngoài, nó có thể được kiểm thử một cách độc lập mà không cần mock cơ sở dữ liệu, web server, hay bất kỳ dịch vụ bên ngoài nào. Các unit test có thể chạy nhanh và đáng tin cậy vì chúng chỉ kiểm thử logic nghiệp vụ thuần túy.

=== 3.2.2 Các tầng và Dependency Rule

Clean Architecture tổ chức mã nguồn thành các tầng đồng tâm, với logic nghiệp vụ ở trung tâm và các chi tiết triển khai ở bên ngoài. Có bốn tầng chính: Entities, Use Cases, Interface Adapters, và Frameworks and Drivers.

==== 3.2.2.1 Entities

Entities là tầng trong cùng, chứa các quy tắc nghiệp vụ quan trọng nhất và ổn định nhất của ứng dụng. Đây là các mô hình miền đại diện cho các khái niệm nghiệp vụ cốt lõi. Tầng này không phụ thuộc vào các chi tiết triển khai như use case, controller hay cơ sở dữ liệu. Vì vậy, Entities chủ yếu chứa logic nghiệp vụ thuần túy, tức các quy tắc vẫn có ý nghĩa ngay cả khi chưa xét đến cách hệ thống được hiện thực.

==== 3.2.2.2 Use Cases

Tầng Use Cases chứa các quy tắc nghiệp vụ cụ thể của ứng dụng, tức các quy tắc mô tả cách ứng dụng sử dụng entities để đạt được một mục tiêu rõ ràng. Mỗi use case đại diện cho một chức năng nghiệp vụ cụ thể. Tầng này điều phối luồng dữ liệu đến và từ entities, đồng thời xác định các interface cần thiết để các tầng bên ngoài triển khai. Vì vậy, Use Cases vẫn giữ được sự tách biệt với giao diện người dùng, cơ sở dữ liệu hay các dịch vụ bên ngoài.

==== 3.2.2.3 Interface Adapters

Tầng Interface Adapters chịu trách nhiệm chuyển đổi dữ liệu giữa định dạng phù hợp với use case và định dạng phù hợp với các tác nhân bên ngoài như web hay cơ sở dữ liệu. Tầng này thường bao gồm controller nhận request và gọi use case, presenter định dạng dữ liệu để trả về cho giao diện người dùng, cùng gateway hoặc repository để truy cập dữ liệu. Đây cũng là nơi thể hiện rõ nguyên tắc dependency inversion: các use case xác định interface cần thiết, còn adapter ở bên ngoài triển khai các interface đó.

==== 3.2.2.4 Frameworks and Drivers

Tầng ngoài cùng chứa các framework và công cụ như cơ sở dữ liệu, web framework, API bên ngoài. Đây là nơi tất cả các chi tiết triển khai cụ thể nằm. Mã nguồn trong tầng này thường rất ít vì phần lớn công việc được thực hiện bởi các thư viện bên thứ ba. Tầng này giao tiếp với tầng Interface Adapters để tích hợp với phần còn lại của ứng dụng.

==== 3.2.2.5 Dependency Rule

Nguyên tắc quan trọng nhất của Clean Architecture là Dependency Rule: các phụ thuộc mã nguồn chỉ được trỏ vào trong. Nói cách khác, các tầng bên trong không nên phụ thuộc vào chi tiết của các tầng bên ngoài. Điều này thường được thực hiện thông qua dependency inversion, trong đó tầng trong xác định interface cần thiết, còn tầng ngoài cung cấp phần triển khai cụ thể.


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

So với MVC, Clean Architecture phức tạp hơn đáng kể nhưng mang lại khả năng kiểm thử và tính linh hoạt cao hơn nhiều. MVC phù hợp cho các ứng dụng nhỏ, đơn giản nơi logic nghiệp vụ không phức tạp và không cần độ bao phủ kiểm thử cao. Tuy nhiên, khi ứng dụng phát triển, MVC thường dẫn đến các controller phình to chứa cả logic nghiệp vụ lẫn logic trình bày, từ đó làm giảm khả năng kiểm thử và bảo trì.

Những nguyên tắc trên là cơ sở để phân tích cách các service trong SMAP tổ chức business logic, delivery layer và infrastructure layer ở các chương sau.
