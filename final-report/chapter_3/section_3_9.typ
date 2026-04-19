== 3.9 Containerization và Orchestration

=== 3.9.1 Docker

Docker là một nền tảng phục vụ việc phát triển, đóng gói và chạy ứng dụng trong môi trường container. Container là các gói thực thi nhẹ và độc lập, bao gồm toàn bộ thành phần cần thiết để chạy ứng dụng như mã nguồn, runtime, công cụ hệ thống, thư viện và cấu hình. Docker cho phép đóng gói ứng dụng cùng toàn bộ phụ thuộc của nó thành các image container, có thể chạy nhất quán trên nhiều môi trường triển khai khác nhau.

Công nghệ container giải quyết vấn đề khác biệt môi trường chạy giữa máy phát triển, máy kiểm thử và máy triển khai. Khi ứng dụng và các phụ thuộc của nó được đóng gói trong cùng một image, hành vi của ứng dụng trở nên nhất quán hơn và ít phụ thuộc vào cấu hình thủ công của từng máy. Nhờ đó, container đặc biệt phù hợp với các hệ thống có nhiều thành phần hoặc nhiều service cần được triển khai độc lập.

Docker image là các template chỉ đọc chứa hướng dẫn để tạo container. Image thường được xây dựng từ Dockerfile, trong đó mô tả rõ các bước cài đặt môi trường, sao chép mã nguồn, cấu hình runtime và lệnh khởi động. Cấu trúc phân lớp của image giúp tối ưu không gian lưu trữ và tăng tốc quá trình build lại khi chỉ một phần của ứng dụng thay đổi.

=== 3.9.2 Docker Compose

Docker Compose là công cụ cho phép định nghĩa và khởi động nhiều container như một tập hợp thống nhất. Thay vì chạy từng container riêng lẻ bằng lệnh thủ công, Docker Compose cho phép mô tả service, network, volume và dependency trong một file cấu hình. Cách tiếp cận này đặc biệt hữu ích trong môi trường phát triển, kiểm thử tích hợp hoặc mô phỏng các hệ thống nhiều thành phần ở quy mô gọn nhẹ.

Trong các hệ thống nhiều service, Docker Compose giúp đơn giản hóa quá trình khởi động đồng thời nhiều thành phần như API service, cache, message broker hay cơ sở dữ liệu. Điều này không thay thế cho orchestration ở quy mô lớn, nhưng là bước đệm quan trọng để duy trì tính nhất quán môi trường trong quá trình phát triển và kiểm thử.

=== 3.9.3 Kubernetes

Kubernetes là một nền tảng orchestration cho container, được thiết kế để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng được đóng gói trong container. Hệ thống này cho phép phân phối workload lên nhiều node, điều phối vòng đời của container, và duy trì trạng thái mong muốn của ứng dụng trong môi trường triển khai.

Khả năng orchestration của Kubernetes được xây dựng trên nhiều thành phần cơ bản. Pod là đơn vị triển khai nhỏ nhất, có thể chứa một hoặc nhiều container. Deployment quản lý việc phát hành phiên bản mới và hỗ trợ rollback. Service cung cấp lớp địa chỉ ổn định và cân bằng tải cho các pod. ConfigMap và Secret hỗ trợ tách cấu hình khỏi image triển khai. Ingress cho phép định tuyến lưu lượng từ bên ngoài vào các service trong cụm.

Một lợi ích quan trọng của Kubernetes là khả năng duy trì trạng thái mong muốn của hệ thống. Các controller liên tục so sánh trạng thái thực tế với cấu hình khai báo và tự động điều chỉnh khi có sai lệch. Nhờ đó, việc triển khai trở nên có thể tái tạo, dễ kiểm soát bằng mã cấu hình và phù hợp với các hệ thống cần vận hành ổn định ở quy mô nhiều service.

=== 3.9.4 Auto Scaling và Self-Healing

Trong các hệ thống phân tán, tải xử lý giữa các thành phần thường không đồng đều và có thể thay đổi theo thời gian. Vì vậy, orchestration không chỉ dừng ở việc khởi động container mà còn cần hỗ trợ mở rộng và phục hồi tự động. Auto scaling cho phép tăng hoặc giảm số lượng bản sao của một thành phần dựa trên tín hiệu như CPU, bộ nhớ hoặc tải xử lý. Điều này giúp hệ thống sử dụng tài nguyên linh hoạt hơn và tránh lãng phí trong các thời điểm tải thấp.

Self-healing là khả năng tự khôi phục khi container hoặc pod gặp sự cố. Nếu một tiến trình bị treo, crash hoặc không còn đáp ứng kiểm tra sức khỏe, hệ thống orchestration có thể tự động khởi động lại hoặc thay thế instance tương ứng. Cơ chế này đặc biệt quan trọng với các hệ thống nhiều thành phần, nơi việc can thiệp thủ công vào từng service sẽ nhanh chóng trở nên khó quản lý.

Các cơ chế auto scaling và self-healing không thay thế cho thiết kế hệ thống tốt, nhưng chúng là những lớp hỗ trợ vận hành quan trọng giúp tăng tính sẵn sàng và ổn định của hệ thống khi được triển khai ở môi trường thực tế.

Những khái niệm về containerization và orchestration là nền tảng phù hợp để hiểu cách các hệ thống nhiều service như SMAP có thể được đóng gói, triển khai và vận hành theo hướng nhất quán hơn, đồng thời tạo tiền đề cho việc mở rộng và quản lý các thành phần độc lập ở các chương sau.
