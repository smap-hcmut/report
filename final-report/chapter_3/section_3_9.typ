== 3.9 Containerization và Orchestration

=== 3.9.1 Docker

Docker là một nền tảng phục vụ việc phát triển, đóng gói và chạy ứng dụng trong môi trường container. Container là các gói thực thi nhẹ và độc lập, bao gồm toàn bộ thành phần cần thiết để chạy ứng dụng như mã nguồn, runtime, công cụ hệ thống, thư viện và cấu hình. Docker cho phép đóng gói ứng dụng cùng toàn bộ phụ thuộc của nó thành các image container, có thể chạy nhất quán trên mọi môi trường triển khai.

Công nghệ container giải quyết vấn đề "hoạt động trên máy của tôi". Với Docker, ứng dụng và môi trường runtime của nó được đóng gói cùng nhau, đảm bảo hành vi nhất quán giữa các môi trường. Container chia sẻ kernel của hệ điều hành chủ nhưng được cô lập về hệ thống file, mạng và tiến trình. Nhờ đó, container nhẹ hơn nhiều so với máy ảo, khởi động nhanh và sử dụng ít tài nguyên.

Docker image là các template chỉ đọc chứa hướng dẫn để tạo container. Image được xây dựng từ Dockerfile, một file văn bản chứa các lệnh để lắp ráp image. Image có thể được phân lớp, mỗi hướng dẫn tạo một lớp. Các lớp được lưu trữ tạm và chia sẻ giữa các image, giảm dung lượng lưu trữ và thời gian xây dựng.

Docker Compose cho phép định nghĩa và chạy các ứng dụng đa container. File Compose định nghĩa các service, mạng, và volume. Một lệnh có thể khởi động tất cả service. Điều này đơn giản hóa việc phát triển và kiểm thử các ứng dụng microservice.

=== 3.9.2 Kubernetes

Kubernetes là một nền tảng điều phối container, tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng được đóng gói trong container. Kubernetes được phát triển ban đầu bởi Google và hiện được duy trì bởi Cloud Native Computing Foundation. Hệ thống này quản lý các cụm máy và lập lịch container trong pod lên từng node, đồng thời xử lý cân bằng tải, khám phá service, cập nhật luân phiên và tự phục hồi.

Khả năng điều phối của Kubernetes bao gồm nhiều thành phần. Pod là đơn vị triển khai nhỏ nhất, có thể chứa một hoặc nhiều container. Service cung cấp mạng ổn định và cân bằng tải cho pod. Deployment quản lý cập nhật luân phiên và rollback. ConfigMap và Secret được sử dụng để quản lý cấu hình và dữ liệu nhạy cảm. Ingress định tuyến lưu lượng bên ngoài đến service. Horizontal Pod Autoscaler tự động mở rộng pod dựa trên việc sử dụng tài nguyên.

Tự phục hồi là một trong những tính năng quan trọng của Kubernetes. Kubernetes tự động khởi động lại container bị crash, thay thế container khi node chết, và kill container không phản hồi kiểm tra sức khỏe. Điều này đảm bảo tính khả dụng cao mà không cần can thiệp thủ công.

Cấu hình khai báo cho phép định nghĩa trạng thái mong muốn của hệ thống trong các file YAML. Các controller của Kubernetes liên tục điều hòa trạng thái thực tế với trạng thái mong muốn. Điều này làm cho hạ tầng có thể tái tạo và được kiểm soát phiên bản.
