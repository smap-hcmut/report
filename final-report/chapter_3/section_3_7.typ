== 3.7 Công nghệ Backend

=== 3.7.1 Go và Gin Framework

Go là một ngôn ngữ lập trình mã nguồn mở được phát triển bởi Google, được thiết kế để xây dựng phần mềm đơn giản, đáng tin cậy, và hiệu quả. Go được công bố năm 2009 bởi Robert Griesemer, Rob Pike, và Ken Thompson. Go kết hợp sự đơn giản của các ngôn ngữ kiểu động với tính an toàn và hiệu suất của các ngôn ngữ kiểu tĩnh. Go đã trở thành một trong những ngôn ngữ phổ biến nhất để xây dựng microservice, ứng dụng cloud-native, và hệ thống phân tán.

Hiệu suất là một trong những điểm mạnh chính của Go. Go là ngôn ngữ biên dịch, mã được biên dịch thành mã máy gốc, cho phép tốc độ thực thi gần với C/C++. Trình biên dịch Go rất nhanh, có thể biên dịch các codebase lớn trong vài giây. Go có bộ thu gom rác hiệu quả, tự động quản lý bộ nhớ mà không hy sinh hiệu suất đáng kể. Bộ thu gom rác của Go được tối ưu hóa cho độ trễ thấp, với thời gian tạm dừng thường dưới 1ms.

Đồng thời là tính năng nổi bật nhất của Go, được triển khai thông qua goroutine và channel. Goroutine là các luồng nhẹ được quản lý bởi Go runtime, có thể tạo hàng nghìn hoặc hàng triệu goroutine mà không làm quá tải hệ thống. Mỗi goroutine chỉ tiêu thụ vài KB bộ nhớ ban đầu, so với các luồng truyền thống tiêu thụ MB. Channel là các kênh có kiểu để giao tiếp giữa các goroutine, triển khai mô hình CSP. Channel cho phép chia sẻ dữ liệu an toàn giữa các goroutine mà không cần khóa rõ ràng.

Sự đơn giản là triết lý thiết kế cốt lõi của Go. Go có cú pháp tối giản với chỉ 25 từ khóa, so với 50+ trong Java hay C++. Go không có class, kế thừa, hay nhiều tính năng phức tạp khác. Thay vào đó, Go tập trung vào composition thông qua interface và struct. Điều này làm cho mã Go dễ đọc và bảo trì.

Gin là một HTTP web framework được viết bằng Go, được biết đến với hiệu suất cao và thiết kế tối giản. Gin được phát triển năm 2014 và đã trở thành một trong những Go web framework phổ biến nhất. Gin cung cấp bộ định tuyến HTTP nhanh, hỗ trợ middleware, xác thực JSON, xử lý lỗi, và nhiều tính năng khác cần thiết để xây dựng REST API.

Bộ định tuyến HTTP nhanh là điểm mạnh cốt lõi của Gin. Gin sử dụng bộ định tuyến dựa trên radix tree để khớp tuyến đường cực nhanh. Bộ định tuyến có thể xử lý hàng triệu request mỗi giây với độ trễ dưới millisecond. Tham số tuyến đường, ký tự đại diện, và nhóm tuyến đường được hỗ trợ với cú pháp đơn giản.

Hỗ trợ middleware cho phép chèn logic vào pipeline xử lý request. Middleware có thể xử lý xác thực, ghi log, CORS, giới hạn tốc độ, và nhiều mối quan tâm xuyên suốt khác. Gin cung cấp nhiều middleware tích hợp sẵn và cho phép tạo middleware tùy chỉnh dễ dàng.

Xác thực JSON được tích hợp thông qua thẻ struct và thư viện validator. Nội dung request có thể được liên kết và xác thực tự động. Lỗi xác thực được trả về với thông báo chi tiết. Điều này giảm mã boilerplate và đảm bảo tính toàn vẹn dữ liệu.

=== 3.7.2 SQLBoiler

SQLBoiler là một công cụ ORM cho Go, khác biệt với các ORM truyền thống bằng cách tạo mã an toàn kiểu từ lược đồ cơ sở dữ liệu. Thay vì định nghĩa model trong mã và đồng bộ với cơ sở dữ liệu, SQLBoiler kiểm tra cơ sở dữ liệu hiện có và tạo mã Go tương ứng. Điều này đảm bảo các model luôn đồng bộ với lược đồ cơ sở dữ liệu và cung cấp tính an toàn kiểu tại thời điểm biên dịch.

ORM an toàn kiểu có nghĩa là tất cả các thao tác cơ sở dữ liệu được kiểm tra kiểu tại thời điểm biên dịch. Không có truy vấn dựa trên chuỗi hay xác nhận kiểu runtime. Nếu cột không tồn tại hoặc kiểu không khớp, mã sẽ không biên dịch được. Điều này phát hiện lỗi sớm và ngăn ngừa nhiều lỗi runtime.

Phương pháp tạo mã có nhiều lợi ích. Mã được tạo có thể đọc và debug được. Hiệu suất tốt hơn các ORM dựa trên reflection. Hỗ trợ IDE tốt với tự động hoàn thành và kiểm tra kiểu. Tuy nhiên, cần tạo lại mã khi lược đồ thay đổi.

=== 3.7.3 Python và FastAPI

Python là một ngôn ngữ lập trình đa năng, được biết đến với cú pháp rõ ràng và hệ sinh thái phong phú. Python đặc biệt mạnh trong khoa học dữ liệu, học máy, và scripting. Trong bối cảnh của SMAP, Python được sử dụng cho analysis-srv và scrapper service, nơi cần tận dụng các thư viện xử lý dữ liệu, AI/ML và cơ chế worker bất đồng bộ.

FastAPI là một web framework hiện đại cho Python, được thiết kế để xây dựng API với hiệu suất cao. FastAPI sử dụng gợi ý kiểu Python để tự động xác thực, tuần tự hóa, và tài liệu hóa. FastAPI có hiệu suất tốt nhờ sử dụng Starlette và Pydantic, đồng thời phù hợp với các service cần kết hợp API layer với các luồng xử lý bất đồng bộ.

Hỗ trợ bất đồng bộ trong FastAPI cho phép xử lý các request đồng thời một cách hiệu quả. Python asyncio được tích hợp sẵn, cho phép các thao tác I/O không chặn. Điều này quan trọng đối với các service vừa cung cấp API vừa phải phối hợp với worker runtime hoặc các pipeline xử lý dữ liệu.

Những lựa chọn công nghệ backend trên phản ánh hướng tiếp cận đa ngôn ngữ của SMAP: Go và Gin phù hợp với các service điều phối, API và business control plane, trong khi Python và FastAPI phù hợp hơn với các thành phần thiên về analytics pipeline và scrapper runtime.
