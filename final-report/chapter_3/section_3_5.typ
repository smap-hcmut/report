#import "../counters.typ": table_counter

== 3.5 Data Storage Technologies

=== 3.5.1 PostgreSQL

PostgreSQL là một hệ quản trị cơ sở dữ liệu quan hệ mã nguồn mở, được biết đến với độ tin cậy cao, tính năng phong phú và tuân thủ chuẩn SQL. PostgreSQL hỗ trợ cả truy vấn quan hệ truyền thống lẫn dữ liệu bán cấu trúc thông qua JSONB, nhờ đó phù hợp với nhiều kiểu bài toán trong các hệ thống doanh nghiệp và hệ thống phân tán hiện đại.

Tuân thủ ACID là một trong những điểm mạnh chính của PostgreSQL. ACID là viết tắt của Atomicity, Consistency, Isolation và Durability, giúp đảm bảo các giao dịch được xử lý an toàn và dữ liệu duy trì tính toàn vẹn ngay cả khi hệ thống gặp sự cố. PostgreSQL triển khai ACID thông qua cơ chế kiểm soát đồng thời đa phiên bản, cho phép đồng thời cao mà không cần phụ thuộc hoàn toàn vào khóa truyền thống.

Trong thực tế, PostgreSQL đặc biệt phù hợp cho các dữ liệu nghiệp vụ có cấu trúc rõ ràng, yêu cầu ràng buộc chặt chẽ và cần truy vấn quan hệ ổn định. Đây cũng là lớp lưu trữ quan hệ chủ đạo trong nhiều service của SMAP, nơi các metadata, trạng thái nghiệp vụ, lịch sử thao tác và dữ liệu phân tích được duy trì lâu dài.

=== 3.5.2 Redis

Redis là một hệ thống lưu trữ dữ liệu trong bộ nhớ, thường được sử dụng như cache, session store, coordination layer hoặc message infrastructure nhẹ. Redis hỗ trợ nhiều cấu trúc dữ liệu như string, hash, list, set và sorted set, cho phép thực hiện các thao tác nhanh với độ trễ rất thấp.

Vì dữ liệu được xử lý chủ yếu trong RAM, Redis có hiệu suất rất cao và phù hợp với các trường hợp cần phản hồi nhanh. Tuy nhiên, Redis thường không được xem là lớp lưu trữ nghiệp vụ chính cho dữ liệu quan hệ dài hạn, mà đóng vai trò hỗ trợ cho các nhu cầu như cache, session management, rate limiting, blacklist token hoặc pub/sub thời gian thực.

Trong ngữ cảnh của SMAP, Redis có giá trị ở tính linh hoạt hơn là ở vai trò cơ sở dữ liệu trung tâm. Nó phù hợp cho các luồng cần hiệu năng cao như session/token blacklist trong xác thực, cache kết quả tìm kiếm, và fanout thông điệp thời gian thực cho notification layer.

=== 3.5.3 Qdrant

Qdrant là một vector database được thiết kế để lưu trữ và truy vấn embedding vector với hiệu năng cao. Khác với cơ sở dữ liệu quan hệ truyền thống, Qdrant tối ưu cho các bài toán semantic search, similarity search và retrieval dựa trên khoảng cách vector.

Trong các hệ thống hiện đại có tích hợp xử lý ngôn ngữ tự nhiên hoặc hỏi đáp theo ngữ cảnh, vector database đóng vai trò quan trọng vì nó cho phép ánh xạ văn bản thành vector và tìm các nội dung gần nghĩa thay vì chỉ dựa vào khớp từ khóa. Nhờ đó, hệ thống có thể hỗ trợ các truy vấn ngữ nghĩa, tìm kiếm theo ngữ cảnh và các luồng khai thác thông tin nâng cao.

Đối với SMAP, Qdrant phù hợp với lớp khai thác thông tin theo ngữ cảnh, nơi dữ liệu đã qua xử lý và phân tích cần được lập chỉ mục để phục vụ semantic search, chat và các khả năng truy vấn dựa trên embedding. Vì vậy, Qdrant không thay thế PostgreSQL hay Redis, mà bổ sung một lớp lưu trữ tối ưu cho dữ liệu vector.

=== 3.5.4 MinIO

MinIO là một hệ thống object storage tương thích S3, phù hợp cho việc lưu trữ các file và artifact kích thước lớn như raw payload, file báo cáo, batch outputs hoặc các tài nguyên trung gian trong pipeline dữ liệu. Khác với cơ sở dữ liệu quan hệ hay vector database, MinIO không tối ưu cho truy vấn nghiệp vụ chi tiết, mà tối ưu cho lưu trữ và truy xuất đối tượng.

Object storage đặc biệt hữu ích trong các hệ thống xử lý dữ liệu nhiều giai đoạn vì nó giúp tách phần dữ liệu tải trọng lớn khỏi các message hoặc metadata điều phối. Cách tiếp cận này làm cho các lane xử lý bất đồng bộ gọn hơn, đồng thời giữ lại được artifact gốc để truy vết, kiểm tra hoặc xử lý lại khi cần.

Trong SMAP, MinIO phù hợp với nhu cầu lưu raw crawl artifacts, kết quả trung gian và các tài liệu đầu ra như report bundles. Nó đóng vai trò là lớp lưu trữ file/object, bổ sung cho PostgreSQL, Redis và Qdrant trong kiến trúc lưu trữ tổng thể của hệ thống.

=== 3.5.5 Polyglot Persistence

Polyglot Persistence là phương pháp sử dụng nhiều công nghệ lưu trữ khác nhau trong cùng một hệ thống, trong đó mỗi công nghệ được lựa chọn dựa trên kiểu dữ liệu và nhu cầu truy cập cụ thể. Thay vì cố gắng giải quyết mọi bài toán bằng một cơ sở dữ liệu duy nhất, hệ thống tận dụng điểm mạnh của từng loại lưu trữ để tối ưu cho từng lớp chức năng.

Trong thực tế, một hệ thống có thể dùng cơ sở dữ liệu quan hệ cho metadata và giao dịch, cache hoặc in-memory store cho hiệu năng và điều phối, vector database cho semantic retrieval, và object storage cho các file hoặc artifact dung lượng lớn. Cách tiếp cận này giúp tối ưu hóa hiệu năng, khả năng mở rộng và tính phù hợp của từng lớp dữ liệu.

#context (align(center)[_Bảng #table_counter.display(): So sánh các công nghệ lưu trữ dữ liệu_])
#table_counter.step()

#text(size: 10pt)[
  #set par(justify: false)
  #table(
    columns: (1.15fr, 1.2fr, 1.2fr, 1.2fr, 1.2fr),
    stroke: 0.5pt,
    align: (left, left, left, left, left),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Tiêu chí*],
    table.cell(align: center + horizon)[*PostgreSQL*],
    table.cell(align: center + horizon)[*Redis*],
    table.cell(align: center + horizon)[*Qdrant*],
    table.cell(align: center + horizon)[*MinIO*],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Loại dữ liệu],
    table.cell(align: center + horizon)[Dữ liệu quan hệ và metadata],
    table.cell(align: center + horizon)[Cache, session, pub/sub],
    table.cell(align: center + horizon)[Embedding vector và semantic index],
    table.cell(align: center + horizon)[File, object, raw artifacts],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Mô hình truy cập],
    table.cell(align: center + horizon)[SQL và transaction],
    table.cell(align: center + horizon)[Key-value / in-memory operations],
    table.cell(align: center + horizon)[Similarity search theo vector],
    table.cell(align: center + horizon)[Object read/write],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Điểm mạnh],
    table.cell(align: center + horizon)[Tính nhất quán và truy vấn quan hệ mạnh],
    table.cell(align: center + horizon)[Độ trễ thấp và hiệu năng cao],
    table.cell(align: center + horizon)[Tối ưu cho semantic search],
    table.cell(align: center + horizon)[Lưu trữ artifact lớn và bền vững],

    table.cell(align: center + horizon, inset: (y: 0.6em))[Vai trò trong SMAP],
    table.cell(align: center + horizon)[Lưu trữ nghiệp vụ và metadata chính],
    table.cell(align: center + horizon)[Session, cache và realtime fanout],
    table.cell(align: center + horizon)[Tìm kiếm và khai thác thông tin theo ngữ cảnh],
    table.cell(align: center + horizon)[Lưu raw results và outputs],
  )
]

Với SMAP, cách tiếp cận polyglot persistence phản ánh đúng bản chất của hệ thống đa dịch vụ: không có một loại lưu trữ nào tối ưu cho mọi nhu cầu. PostgreSQL phù hợp cho metadata và dữ liệu nghiệp vụ, Redis phù hợp cho cache và coordination nhẹ, Qdrant phù hợp cho semantic retrieval, còn MinIO phù hợp cho object storage. Sự kết hợp này tạo ra một kiến trúc lưu trữ linh hoạt và bám sát nhu cầu xử lý thực tế của hệ thống.
