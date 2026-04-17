#import "../counters.typ": table_counter

== 3.5 Database Technologies

=== 3.5.1 PostgreSQL

PostgreSQL là một hệ quản trị cơ sở dữ liệu quan hệ mã nguồn mở, được biết đến với độ tin cậy cao, tính năng phong phú, và tuân thủ chuẩn SQL. PostgreSQL được phát triển từ năm 1986 tại Đại học California, Berkeley, và đã trở thành một trong những hệ thống cơ sở dữ liệu phổ biến nhất cho các ứng dụng doanh nghiệp. PostgreSQL hỗ trợ cả truy vấn SQL quan hệ và JSON phi quan hệ, làm cho nó trở thành một cơ sở dữ liệu đối tượng-quan hệ linh hoạt.

Tuân thủ ACID là một trong những điểm mạnh chính của PostgreSQL. ACID là viết tắt của Atomicity - tính nguyên tử, Consistency - tính nhất quán, Isolation - tính cô lập, và Durability - tính bền vững. Tính nguyên tử đảm bảo các giao dịch hoàn thành đầy đủ hoặc không hoàn thành gì cả. Tính nhất quán đảm bảo cơ sở dữ liệu luôn ở trạng thái hợp lệ. Tính cô lập đảm bảo các giao dịch đồng thời không ảnh hưởng lẫn nhau. Tính bền vững đảm bảo dữ liệu đã commit không bị mất ngay cả khi hệ thống gặp sự cố. Các đảm bảo ACID đảm bảo tính toàn vẹn và độ tin cậy của dữ liệu, đặc biệt quan trọng cho các ứng dụng tài chính, thương mại điện tử, và bất kỳ hệ thống nào cần tính nhất quán mạnh. PostgreSQL triển khai ACID thông qua Kiểm soát Đồng thời Đa phiên bản, cho phép đồng thời cao mà không cần khóa.

Hỗ trợ JSONB là một tính năng độc đáo làm cho PostgreSQL linh hoạt hơn các cơ sở dữ liệu quan hệ truyền thống. JSONB là định dạng JSON nhị phân được PostgreSQL lưu trữ hiệu quả và hỗ trợ đánh chỉ mục. Điều này cho phép lưu trữ dữ liệu bán cấu trúc trong cơ sở dữ liệu quan hệ mà vẫn có thể truy vấn hiệu quả. JSONB hỗ trợ các toán tử đặc biệt để truy vấn dữ liệu JSON. Chỉ mục GIN có thể được tạo trên các cột JSONB để tăng tốc truy vấn.

=== 3.5.2 MongoDB

MongoDB là một cơ sở dữ liệu NoSQL hướng tài liệu, lưu trữ dữ liệu dưới dạng tài liệu giống JSON thay vì hàng và cột như cơ sở dữ liệu quan hệ. MongoDB được thiết kế cho khả năng mở rộng, tính linh hoạt, và hiệu suất với dữ liệu bán cấu trúc. Mỗi tài liệu có thể có cấu trúc khác nhau, cho phép phát triển lược đồ dễ dàng mà không cần di chuyển. MongoDB được phát hành năm 2009 và đã trở thành một trong những cơ sở dữ liệu NoSQL phổ biến nhất.

Lược đồ linh hoạt là một trong những lợi ích lớn nhất của MongoDB. Không giống như cơ sở dữ liệu quan hệ yêu cầu định nghĩa lược đồ trước, MongoDB cho phép chèn tài liệu với cấu trúc khác nhau vào cùng một bộ sưu tập. Điều này rất hữu ích khi cấu trúc dữ liệu không cố định hoặc phát triển theo thời gian.

Mở rộng theo chiều ngang là một điểm mạnh khác của MongoDB. MongoDB hỗ trợ sharding, phân phối dữ liệu trên nhiều server. Mỗi shard chứa một tập con của dữ liệu, và bộ định tuyến MongoDB định tuyến truy vấn đến đúng shard. Điều này cho phép mở rộng ra ngoài bằng cách thêm server thay vì mở rộng lên bằng cách nâng cấp phần cứng.

=== 3.5.3 Redis

Redis là một kho lưu trữ cấu trúc dữ liệu trong bộ nhớ được sử dụng như cơ sở dữ liệu, bộ nhớ đệm, và message broker. Redis lưu trữ tất cả dữ liệu trong RAM, cho phép các thao tác đọc và ghi cực nhanh với độ trễ dưới millisecond. Redis hỗ trợ nhiều cấu trúc dữ liệu như chuỗi, hash, danh sách, tập hợp, tập hợp có thứ tự, bitmap, hyperloglog, và chỉ mục không gian địa lý. Redis được phát hành năm 2009 và đã trở thành tiêu chuẩn thực tế cho bộ nhớ đệm và các ứng dụng thời gian thực.

Lưu trữ trong bộ nhớ là lý do Redis có hiệu suất xuất sắc. Tất cả dữ liệu được lưu trữ trong RAM, không có I/O đĩa cho các thao tác đọc. Redis có thể xử lý hàng triệu thao tác mỗi giây trên phần cứng tiêu chuẩn. Điều này làm cho Redis lý tưởng cho bộ nhớ đệm, lưu trữ phiên, và phân tích thời gian thực.

Cấu trúc dữ liệu phong phú phân biệt Redis với các kho key-value đơn giản. Chuỗi cho các giá trị đơn giản và bộ đếm. Hash cho các đối tượng với nhiều trường. Danh sách cho hàng đợi và ngăn xếp. Tập hợp cho các bộ sưu tập duy nhất. Tập hợp có thứ tự cho bảng xếp hạng và hàng đợi ưu tiên. Mỗi cấu trúc dữ liệu có các thao tác được tối ưu hóa, cho phép các thao tác phức tạp trong các lệnh đơn.

Các tùy chọn bền vững cho phép Redis lưu dữ liệu xuống đĩa để khôi phục sau khi khởi động lại. Ảnh chụp RDB tạo ảnh chụp tại thời điểm của tập dữ liệu. Log AOF ghi lại mọi thao tác ghi. Cả hai có thể được kết hợp để cân bằng giữa hiệu suất và tính bền vững.

=== 3.5.4 Polyglot Persistence

Polyglot Persistence là phương pháp kiến trúc sử dụng nhiều công nghệ cơ sở dữ liệu khác nhau trong cùng một ứng dụng, mỗi cơ sở dữ liệu được chọn dựa trên trường hợp sử dụng cụ thể. Thay vì sử dụng một cơ sở dữ liệu cho tất cả dữ liệu, polyglot persistence chọn công cụ phù hợp cho từng công việc: cơ sở dữ liệu quan hệ cho dữ liệu có cấu trúc, cơ sở dữ liệu tài liệu cho lược đồ linh hoạt, kho key-value cho bộ nhớ đệm. Phương pháp này tối ưu hóa hiệu suất, khả năng mở rộng, và năng suất của nhà phát triển bằng cách tận dụng điểm mạnh của mỗi loại cơ sở dữ liệu.

#context (align(center)[_Bảng #table_counter.display(): So sánh các Database Technologies_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.2fr, 1.3fr, 1.3fr, 1.3fr),
    stroke: 0.5pt,
    align: (left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*PostgreSQL*],
    table.cell(align: center + horizon)[*MongoDB*],
    table.cell(align: center + horizon)[*Redis*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Data Model],
    table.cell(align: center + horizon)[Relational, tables và rows],
    table.cell(align: center + horizon)[Document, JSON-like],
    table.cell(align: center + horizon)[Key-Value, Data Structures],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Consistency],
    table.cell(align: center + horizon)[Mạnh, ACID],
    table.cell(align: center + horizon)[Eventual, có thể điều chỉnh],
    table.cell(align: center + horizon)[Eventual, in-memory],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Scalability],
    table.cell(align: center + horizon)[Vertical và Read Replicas],
    table.cell(align: center + horizon)[Horizontal, Sharding],
    table.cell(align: center + horizon)[Horizontal, Clustering],

    table.cell(align: center + horizon, inset: (y: 1em))[Performance],
    table.cell(align: center + horizon)[Tốt, disk-based],
    table.cell(align: center + horizon)[Rất tốt, disk-based],
    table.cell(align: center + horizon)[Xuất sắc, in-memory],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Use Cases],
    table.cell(align: center + horizon)[Structured data, transactions],
    table.cell(align: center + horizon)[Semi-structured, flexible schema],
    table.cell(align: center + horizon)[Caching, real-time, sessions],
  )
]

Polyglot persistence có nhiều lợi ích. Tối ưu hóa hiệu suất cho phép chọn cơ sở dữ liệu tối ưu cho từng khối lượng công việc. Tính linh hoạt về khả năng mở rộng cho phép mở rộng từng cơ sở dữ liệu độc lập. Năng suất của nhà phát triển tăng khi sử dụng cơ sở dữ liệu phù hợp với mô hình dữ liệu. Tối ưu hóa chi phí cho phép sử dụng lưu trữ rẻ hơn cho dữ liệu ít quan trọng hơn.

Tuy nhiên, polyglot persistence cũng có những thách thức. Độ phức tạp vận hành tăng khi phải quản lý nhiều hệ thống cơ sở dữ liệu. Tính nhất quán dữ liệu khó đảm bảo khi dữ liệu được phân tán trên các cơ sở dữ liệu. Chuyên môn của nhóm cần thiết cho mỗi công nghệ cơ sở dữ liệu. Độ phức tạp tích hợp khi cần kết hợp dữ liệu từ nhiều nguồn.
