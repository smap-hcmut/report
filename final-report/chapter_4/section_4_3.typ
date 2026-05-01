// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.3 Yêu cầu phi chức năng

Bên cạnh các yêu cầu chức năng, hệ thống SMAP còn cần đáp ứng một nhóm yêu cầu phi chức năng nhằm bảo đảm tính ổn định, an toàn và khả năng vận hành của toàn bộ kiến trúc. Đối với một hệ thống gồm nhiều dịch vụ phối hợp, các yêu cầu phi chức năng không chỉ đóng vai trò tiêu chí đánh giá chất lượng, mà còn là cơ sở chi phối các quyết định về lưu trữ, truyền thông, xác thực, triển khai và quan sát vận hành.

Trong phạm vi của luận văn, các yêu cầu phi chức năng dưới đây được trình bày ở mức hệ thống. Mục tiêu là xác định các thuộc tính chất lượng cần được bảo đảm trong quá trình thiết kế và đánh giá, đồng thời tránh đưa ra các cam kết định lượng khi chưa có cơ sở thực nghiệm tương ứng.

=== 4.3.1 Đặc tính kiến trúc

Phần này trình bày các đặc tính kiến trúc được xem là quan trọng đối với SMAP ở mức thiết kế hệ thống. Đây là các thuộc tính mang tính định hướng, dùng để đánh giá vì sao kiến trúc được tổ chức theo nhiều dịch vụ, vì sao cần các luồng xử lý bất đồng bộ, và vì sao việc tách các miền trách nhiệm là cần thiết đối với hệ thống.

#context (align(center)[_Bảng #table_counter.display(): Đặc tính kiến trúc chính_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr, 1.2fr, 1fr),
    stroke: 0.5pt,
    align: (left + horizon, center + horizon, left + horizon, left + horizon),

    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon)[*Đặc tính*],
    table.cell(align: center + horizon)[*Ý nghĩa đối với hệ thống*],
    table.cell(align: center + horizon)[*Chỉ báo đánh giá / định hướng*],

    align(center + horizon)[AC-01],
    [Modularity],
    [Hệ thống cần được tách thành các thành phần có trách nhiệm tương đối độc lập, giúp giới hạn blast radius khi thay đổi hoặc lỗi xảy ra ở một lane xử lý cụ thể.],
    [Tách rõ miền trách nhiệm theo dịch vụ hoặc mô-đun; giảm phụ thuộc chéo không cần thiết giữa các thành phần.],

    align(center + horizon)[AC-02],
    [Scalability],
    [Các nhóm tải có tính chất khác nhau như tương tác người dùng, thu thập dữ liệu, phân tích hoặc thông báo cần có khả năng được mở rộng linh hoạt theo nhu cầu riêng.],
    [Có thể mở rộng theo vai trò xử lý; không buộc mọi thành phần phải mở rộng đồng thời.],

    align(center + horizon)[AC-03],
    [Performance],
    [Các luồng đồng bộ và bất đồng bộ phải được tổ chức sao cho hệ thống phản hồi ổn định với người dùng trong khi vẫn xử lý được các tác vụ nền nặng.],
    [Tách luồng phản hồi trực tiếp khỏi luồng xử lý nền; ưu tiên xử lý bất đồng bộ cho các tác vụ tốn tài nguyên.],

    align(center + horizon)[AC-04],
    [Security],
    [Hệ thống cần có ranh giới bảo mật rõ ràng cho xác thực người dùng, kiểm tra giao tiếp giữa các dịch vụ và bảo vệ các kênh thông báo.],
    [Sử dụng lớp xác thực riêng, kiểm tra token, chính sách phiên truy cập và cơ chế kiểm tra nội bộ phù hợp.],

    align(center + horizon)[AC-05],
    [Availability],
    [Các thành phần quan trọng phải hỗ trợ cơ chế phát hiện lỗi trong quá trình vận hành và khả năng khôi phục phù hợp để duy trì tính sẵn sàng.],
    [Health check, probe, chính sách khởi động lại và tách luồng xử lý để giảm ảnh hưởng dây chuyền.],

    align(center + horizon)[AC-06],
    [Data Integrity],
    [Các luồng bất đồng bộ cần đảm bảo liên kết đúng giữa nhiệm vụ xử lý, trạng thái hoàn tất và dữ liệu thu thập gốc để tránh sai lệch dữ liệu.],
    [Khóa tương quan, khả năng xử lý lặp an toàn và hợp đồng dữ liệu nhất quán giữa các thành phần.],

    align(center + horizon)[AC-07],
    [Observability],
    [Hệ thống cần hỗ trợ nhật ký, chỉ số hoặc các chỉ báo vận hành đủ để theo dõi và chẩn đoán lỗi ở các luồng xử lý chính.],
    [Có nhật ký có cấu hình, chỉ số vận hành hoặc chỉ báo trạng thái ở các nhóm xử lý quan trọng.],
  )
]

=== 4.3.2 Thuộc tính chất lượng

Các thuộc tính chất lượng dưới đây được viết ở mức yêu cầu hệ thống. Phần này tập trung vào những nhóm chất lượng cần thiết để hệ thống vận hành ổn định, an toàn và có khả năng mở rộng trong phạm vi nghiệp vụ đã xác định.

#context (align(center)[_Bảng #table_counter.display(): Yêu cầu phi chức năng cốt lõi_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 0.55fr, 1.1fr, 1fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, left + horizon, left + horizon),

    table.cell(align: center + horizon, inset: (y: 0.6em))[*ID*],
    table.cell(align: center + horizon)[*Nhóm*],
    table.cell(align: center + horizon)[*Yêu cầu*],
    table.cell(align: center + horizon)[*Chỉ báo / Bằng chứng định hướng*],

    align(center + horizon)[NFR-01],
    [Performance],
    [Hệ thống phải hỗ trợ xử lý bất đồng bộ cho các lane phân tích và xử lý nền thay vì ép toàn bộ logic vào request-response đồng bộ.],
    [Xử lý nền theo luồng sự kiện; tách luồng phân tích và xử lý nặng khỏi luồng phản hồi trực tiếp.],

    align(center + horizon)[NFR-02],
    [Security],
    [Hệ thống phải hỗ trợ xác thực người dùng, quản lý phiên truy cập và bảo vệ giao tiếp giữa các dịch vụ bằng các cơ chế xác thực phù hợp.],
    [OAuth2, JWT, HttpOnly cookie, internal auth, token validation.],

    align(center + horizon)[NFR-03],
    [Availability],
    [Các nhóm xử lý quan trọng phải có cơ chế phát hiện lỗi và hỗ trợ khôi phục để duy trì vận hành ổn định.],
    [Probe, health check, chiến lược khởi động lại hoặc triển khai lại, tách nhóm xử lý theo vai trò.],

    align(center + horizon)[NFR-04],
    [Scalability],
    [Các luồng xử lý có tải biến động phải có khả năng mở rộng theo vai trò thay vì phụ thuộc vào mở rộng đồng loạt toàn hệ thống.],
    [Mở rộng theo vai trò xử lý khi nhu cầu tải thay đổi.],

    align(center + horizon)[NFR-05],
    [Data Integrity],
    [Các luồng bất đồng bộ phải duy trì được tính nhất quán giữa nhiệm vụ xử lý, trạng thái hoàn tất, dữ liệu thu thập và kết quả xử lý tiếp theo.],
    [Khóa tương quan, xử lý lặp an toàn, hợp đồng dữ liệu thống nhất và khả năng truy vết dữ liệu nguồn.],

    align(center + horizon)[NFR-06],
    [Modularity],
    [Các miền trách nhiệm chính phải được tách thành dịch vụ hoặc mô-đun tương đối độc lập để dễ thay đổi, bảo trì và kiểm thử.],
    [Service boundaries rõ, ownership dữ liệu rõ, module tách theo capability.],

    align(center + horizon)[NFR-07],
    [Observability],
    [Hệ thống phải hỗ trợ đủ nhật ký hoặc chỉ báo vận hành để theo dõi lỗi và giám sát các luồng xử lý quan trọng.],
    [Nhật ký có cấu trúc, chỉ số vận hành và chỉ báo trạng thái ở các nhóm xử lý chính.],
  )
]

=== 4.3.3 Nhận xét và liên hệ với SMAP

Đối với SMAP, các yêu cầu phi chức năng trên không tồn tại độc lập mà gắn trực tiếp với kiến trúc của hệ thống. Việc tách các luồng xử lý phân tích, sử dụng nhiều lớp lưu trữ, áp dụng cơ chế xác thực người dùng và tổ chức truyền tin bất đồng bộ cho thấy thiết kế hệ thống cần đồng thời đáp ứng các yêu cầu về hiệu năng, bảo mật, khả năng mở rộng, tính nhất quán dữ liệu và khả năng quan sát vận hành.

Vì vậy, phần NFR trong chương này không nên được hiểu như một danh sách cam kết số liệu tuyệt đối, mà là bộ tiêu chí chất lượng cốt lõi dùng để định hướng thiết kế và đánh giá hệ thống ở các chương sau. Các chỉ số định lượng chi tiết, nếu cần, chỉ nên được xác định khi có kết quả thực nghiệm hoặc kết quả vận hành tương ứng.
