// Import counter dùng chung
#import "../counters.typ": image_counter, table_counter

== 4.3 Non-Functional Requirements

Bên cạnh các yêu cầu chức năng, hệ thống SMAP còn cần đáp ứng một nhóm yêu cầu phi chức năng nhằm bảo đảm tính ổn định, an toàn và khả năng vận hành của toàn bộ kiến trúc. Đối với một hệ thống đa service, các yêu cầu phi chức năng không chỉ đóng vai trò tiêu chí đánh giá chất lượng, mà còn là cơ sở trực tiếp chi phối các quyết định về storage, transport, authentication, deployment và observability.

Trong phạm vi của luận văn, các yêu cầu phi chức năng dưới đây được xác định theo hướng evidence-based, tức được suy ra từ cấu trúc service, runtime contracts, manifests, cấu hình bảo mật và current implementation. Vì vậy, phần này ưu tiên các đặc tính có thể bảo vệ được bằng source code hoặc artifact kỹ thuật, thay vì đưa ra các cam kết số cứng chưa có benchmark tương ứng.

=== 4.3.1 Đặc tính kiến trúc

Phần này trình bày các đặc tính kiến trúc được xem là quan trọng đối với SMAP ở mức thiết kế hệ thống. Đây là các thuộc tính mang tính định hướng, dùng để đánh giá vì sao kiến trúc được tổ chức theo nhiều service, vì sao cần các lane bất đồng bộ, và vì sao việc tách các bounded context là cần thiết đối với hệ thống hiện tại.

#context (align(center)[_Bảng #table_counter.display(): Đặc tính kiến trúc chính_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 0.6fr, 1.2fr, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.6em))[*AC*],
    table.cell(align: center + horizon)[*Đặc tính*],
    table.cell(align: center + horizon)[*Ý nghĩa đối với hệ thống*],
    table.cell(align: center + horizon)[*Chỉ báo đánh giá / định hướng*],

    align(center + horizon)[AC-01],
    [Modularity],
    [Hệ thống cần được tách thành các thành phần có trách nhiệm tương đối độc lập, giúp giới hạn blast radius khi thay đổi hoặc lỗi xảy ra ở một lane xử lý cụ thể.],
    [Tách rõ bounded context theo service/module; giảm phụ thuộc chéo không cần thiết giữa các thành phần.],

    align(center + horizon)[AC-02],
    [Scalability],
    [Các workload có tính chất khác nhau như API, analytics, crawl runtime hoặc notification cần có khả năng được mở rộng linh hoạt theo mức tải riêng.],
    [Có thể scale theo service hoặc theo runtime role; không buộc mọi thành phần phải mở rộng đồng thời.],

    align(center + horizon)[AC-03],
    [Performance],
    [Các luồng đồng bộ và bất đồng bộ phải được tổ chức sao cho hệ thống phản hồi ổn định với người dùng trong khi vẫn xử lý được các tác vụ nền nặng.],
    [Tách request-response path khỏi processing path; ưu tiên xử lý nền cho các lane tốn tài nguyên.],

    align(center + horizon)[AC-04],
    [Security],
    [Hệ thống cần có security boundary rõ ràng cho xác thực người dùng, service-to-service validation và bảo vệ các kết nối thời gian thực.],
    [Sử dụng auth layer riêng, token validation, cookie/JWT policies và internal auth mechanisms.],

    align(center + horizon)[AC-05],
    [Availability],
    [Các thành phần quan trọng phải hỗ trợ cơ chế phát hiện lỗi runtime và khả năng khôi phục phù hợp để duy trì tính sẵn sàng.],
    [Health check, probe, restart policy, tách lane xử lý để giảm ảnh hưởng dây chuyền.],

    align(center + horizon)[AC-06],
    [Data Integrity],
    [Các luồng bất đồng bộ cần đảm bảo liên kết đúng giữa task, completion metadata và raw artifacts để tránh sai lệch dữ liệu.],
    [Correlation key, idempotency, contract nhất quán giữa producer và consumer.],

    align(center + horizon)[AC-07],
    [Observability],
    [Hệ thống cần hỗ trợ logging, metrics hoặc các chỉ báo runtime đủ để theo dõi và chẩn đoán lỗi ở các lane xử lý chính.],
    [Có logging có cấu hình, metrics hoặc runtime indicators ở các workload quan trọng.],
  )
]

=== 4.3.2 Thuộc tính chất lượng

Các thuộc tính chất lượng dưới đây được viết ở mức yêu cầu hệ thống, bám sát current implementation và các artifact kỹ thuật hiện có. Thay vì mô tả quá chi tiết theo kiểu product aspiration, phần này tập trung vào những nhóm chất lượng có thể nối trực tiếp với source code, config và deployment manifests.

#context (align(center)[_Bảng #table_counter.display(): Yêu cầu phi chức năng cốt lõi_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 0.55fr, 1.1fr, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.6em))[*ID*],
    table.cell(align: center + horizon)[*Nhóm*],
    table.cell(align: center + horizon)[*Yêu cầu*],
    table.cell(align: center + horizon)[*Chỉ báo / Bằng chứng định hướng*],

    align(center + horizon)[NFR-01],
    [Performance],
    [Hệ thống phải hỗ trợ xử lý bất đồng bộ cho các lane phân tích và xử lý nền thay vì ép toàn bộ logic vào request-response đồng bộ.],
    [Consumer-based processing, tách analytics pipeline và runtime lanes khỏi HTTP path.],

    align(center + horizon)[NFR-02],
    [Security],
    [Hệ thống phải hỗ trợ xác thực người dùng, quản lý phiên truy cập và bảo vệ giao tiếp giữa các service bằng các cơ chế xác thực phù hợp.],
    [OAuth2, JWT, HttpOnly cookie, internal auth, token validation.],

    align(center + horizon)[NFR-03],
    [Availability],
    [Các workload quan trọng phải có cơ chế phát hiện lỗi runtime và hỗ trợ khôi phục để duy trì vận hành ổn định.],
    [Probe, health check, restart/redeploy strategy, tách workload theo vai trò.],

    align(center + horizon)[NFR-04],
    [Scalability],
    [Các lane xử lý có tải biến động phải có khả năng mở rộng theo workload thay vì phụ thuộc vào mở rộng đồng loạt toàn hệ thống.],
    [Autoscaling hoặc scale-by-role cho consumer, worker và các runtime lane tương ứng.],

    align(center + horizon)[NFR-05],
    [Data Integrity],
    [Các flow bất đồng bộ phải duy trì được tính nhất quán giữa task, completion metadata, artifact storage và kết quả downstream.],
    [Correlation key, idempotent handling, canonical contract, raw batch lineage.],

    align(center + horizon)[NFR-06],
    [Modularity],
    [Các bounded context chính phải được tách thành service hoặc module tương đối độc lập để dễ thay đổi, bảo trì và kiểm thử.],
    [Service boundaries rõ, ownership dữ liệu rõ, module tách theo capability.],

    align(center + horizon)[NFR-07],
    [Observability],
    [Hệ thống phải hỗ trợ đủ logging hoặc chỉ báo runtime để theo dõi lỗi và giám sát các lane xử lý quan trọng.],
    [Structured logs, runtime metrics, operational indicators ở các workload chính.],
  )
]

=== 4.3.3 Nhận xét và liên hệ với SMAP

Đối với SMAP, các yêu cầu phi chức năng trên không tồn tại độc lập mà gắn trực tiếp với kiến trúc hiện tại của hệ thống. Việc tách `analysis-srv` thành consumer runtime, việc sử dụng nhiều lớp lưu trữ khác nhau, sự hiện diện của OAuth2/JWT/cookie-based authentication, hay các lane truyền tin bất đồng bộ cho thấy thiết kế hệ thống thực tế đang là phản hồi trực tiếp đối với yêu cầu về hiệu năng, bảo mật, khả năng mở rộng, tính nhất quán dữ liệu và khả năng quan sát runtime.

Vì vậy, phần NFR trong chương này không nên được hiểu như một danh sách cam kết số liệu tuyệt đối, mà là bộ tiêu chí chất lượng cốt lõi dùng để định hướng thiết kế và đánh giá hệ thống ở các chương sau. Các chỉ số định lượng chi tiết, nếu cần, sẽ chỉ nên được chốt ở mức thực nghiệm khi có benchmark, test artifact hoặc kết quả vận hành tương ứng.
