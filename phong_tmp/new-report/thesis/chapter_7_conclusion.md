# CHAPTER 7: CONCLUSION

## 7.1 Achievement and Objective Fulfillment

Luận văn này đã thực hiện việc phân tích, mô hình hóa và hệ thống hóa kiến trúc của nền tảng SMAP dựa trên mã nguồn hiện có trong workspace. Khác với cách tiếp cận thuần mô tả sản phẩm, nội dung của luận văn được xây dựng theo nguyên tắc bằng chứng mã nguồn, nghĩa là các kết luận về công nghệ, mô-đun, luồng xử lý và ràng buộc triển khai chỉ được đưa ra khi có dấu vết trực tiếp trong source code, manifest hoặc file cấu hình thực tế. Trên cơ sở đó, luận văn đã tái lập mối liên hệ chặt chẽ giữa yêu cầu hệ thống, thiết kế kiến trúc và hiện thực hóa kỹ thuật.

Xét theo các mục tiêu đã nêu ở Chương 1, có thể nhận thấy phần lớn mục tiêu chính đã được hoàn thành ở mức phân tích và tài liệu hóa kỹ thuật. Mục tiêu xây dựng cái nhìn tổng thể về một nền tảng social media analytics đa dịch vụ đã được đáp ứng thông qua việc xác định rõ các bounded contexts gồm xác thực, quản lý ngữ cảnh nghiệp vụ, ingest runtime, analytics pipeline, knowledge layer và notification layer. Mục tiêu phân tích các công nghệ cốt lõi cũng đã được hoàn thành khi luận văn lập được danh mục công nghệ có bằng chứng trực tiếp từ mã nguồn, bao gồm Go, Python, Gin, FastAPI, PostgreSQL, Redis, Kafka, RabbitMQ, MinIO, Qdrant, OAuth2, JWT, Docker và Kubernetes. Mục tiêu giải thích cách hệ thống hiện thực các năng lực quan trọng cũng đã được đáp ứng qua Chương 5, nơi các tính năng lõi như xác thực OAuth2, quản lý project, điều khiển vòng đời datasource, xử lý analytics bất đồng bộ, tìm kiếm ngữ nghĩa và thông báo thời gian thực đã được nối trực tiếp tới file và hàm hiện thực tương ứng.

Tuy nhiên, mức độ hoàn thành của luận văn cần được hiểu đúng về bản chất. Luận văn này hoàn thành mạnh ở bình diện phân tích hệ thống, thiết kế kiến trúc và đối chiếu hiện thực hóa dựa trên source code. Ngược lại, một số mục tiêu chỉ mới đạt ở mức tài liệu hóa dựa trên bằng chứng sẵn có, chưa đạt ở mức thực nghiệm đầy đủ. Cụ thể, Chương 6 cho thấy hệ thống có test assets tương đối phong phú, có các chỉ báo sẵn sàng về hiệu năng như autoscaling, phân tách hàng đợi, cache và xử lý bất đồng bộ, đồng thời có thêm bằng chứng xác thực tích hợp từ `e2e-report.md` và `final-report.md`. Tuy nhiên, vẫn chưa có benchmark report hoặc coverage report đầy đủ để khẳng định các kết quả định lượng mạnh. Vì vậy, luận văn đạt tốt mục tiêu nhận diện và phân tích hệ thống, nhưng phần đánh giá thực nghiệm vẫn còn giới hạn ở mức chỉ báo kiến trúc, hiện vật kiểm thử và xác thực tích hợp vận hành.

Từ góc độ kỹ thuật, ba kết quả nổi bật có thể được tổng kết như sau. Thứ nhất, hệ thống đã được nhận diện như một kiến trúc đa tầng có sự phân tách cơ chế truyền thông giữa các dịch vụ một cách rõ ràng: internal HTTP cho control plane, RabbitMQ cho crawl runtime, Kafka cho analytics data plane và Redis Pub/Sub cho notification ingress. Thứ hai, lớp phân tích và lớp tri thức đã được hiện thực ở mức đủ sâu để tạo ra giá trị kỹ thuật khác biệt cho hệ thống, thể hiện qua pipeline NLP nhiều giai đoạn, vector search, chat và truy hồi phục vụ báo cáo. Thứ ba, luận văn đã chỉ ra được các liên kết cụ thể giữa thiết kế và hiện thực, nhờ đó tránh được tình trạng “thiết kế một hệ thống khác với hệ thống đang tồn tại trong mã nguồn”.

Table 7.1 summarizes the degree to which the main objectives of the thesis have been fulfilled.

| Objective | Mức độ hoàn thành | Cơ sở kết luận |
| --- | --- | --- |
| Xác định bức tranh tổng thể của hệ thống | High | Chương 2, 3 và 4 đã mô tả rõ bounded contexts, stack công nghệ và kiến trúc tổng thể |
| Đối chiếu yêu cầu với thiết kế | High | Chương 3 và Chương 4 có traceability matrix, module mapping và API grouping |
| Giải thích hiện thực hóa theo source code | High | Chương 5 liên kết trực tiếp file và hàm cho các tính năng lõi |
| Đánh giá và kiểm thử hệ thống | Medium-High | Chương 6 có test matrix, evaluation indicators và thêm bằng chứng E2E/integration từ báo cáo vận hành, nhưng chưa có benchmark thực nghiệm đầy đủ |
| Hoàn thiện gói luận văn nộp được | Medium-High | thesis package đã có front matter, lists, appendix, references và checklist, nhưng vẫn cần dàn trang cuối theo chuẩn nộp |

## 7.2 Limitations

Hạn chế thứ nhất nằm ở phạm vi hiện vật của workspace. Mã nguồn hiện tại chưa chứa frontend source code hoặc manifest frontend đủ rõ để xác nhận framework giao diện, cơ chế rendering hay state management. Do đó, phần giao diện người dùng trong luận văn chỉ có thể được trình bày như một bề mặt tương tác được suy ra từ backend contracts, chứ chưa thể được mô tả đầy đủ như một hệ con có hiện thực độc lập.

Hạn chế thứ hai nằm ở lớp hạ tầng triển khai và chuỗi phân phối phần mềm. Mặc dù Dockerfile, Docker Compose, Kubernetes Deployment và HPA đã được xác nhận bằng mã nguồn, các workflow CI/CD cụ thể chưa xuất hiện trong workspace dưới dạng workflow files hoặc pipeline manifests tương ứng. Vì vậy, phần DevOps của luận văn mới dừng ở mức kiến trúc đóng gói và triển khai từng workload, chưa thể đi tới mức mô tả hoàn chỉnh quy trình tích hợp liên tục và phân phối liên tục của toàn hệ thống.

Hạn chế thứ ba liên quan trực tiếp đến độ mạnh của phần đánh giá. Như đã trình bày ở Chương 6, hệ thống có nhiều chỉ báo cho thấy đã được thiết kế hướng đến hiệu năng và khả năng mở rộng, ví dụ như cấu hình tài nguyên cho analytics consumer, cơ chế tự động co giãn, xử lý bất đồng bộ theo consumer model và các lớp cache cho search. Tuy nhiên, những bằng chứng này mới cho phép đánh giá ở mức các chỉ báo kiến trúc dựa trên bằng chứng và các kết quả xác thực tích hợp, chứ chưa đủ để xem như một thí nghiệm đo hiệu năng có kiểm soát. Nói cách khác, phần đánh giá hiện tại mạnh ở phương diện readiness, test assets và E2E verification, nhưng chưa mạnh ở phương diện thực nghiệm định lượng.

Hạn chế thứ tư là tính lịch sử của một số tài liệu trong workspace. Luận văn đã chủ động phân biệt giữa `current`, `target` và `legacy`, nhưng chính sự đồng tồn tại của nhiều tài liệu ở các giai đoạn khác nhau vẫn làm tăng chi phí nhận thức khi đối chiếu hệ thống. Điều này đặc biệt rõ ở các chủ đề như mô hình transport, vòng đời project-execution và kiến trúc phản hồi khủng hoảng.

Table 7.2 summarizes the thesis contributions in a compact form.

| Nhóm đóng góp | Nội dung chính |
| --- | --- |
| Đóng góp về hệ thống hóa | tái cấu trúc lại kiến trúc SMAP theo bằng chứng mã nguồn thay vì mô tả rời rạc |
| Đóng góp về đối chiếu kỹ thuật | nối yêu cầu, thiết kế, hiện thực và đánh giá bằng file/hàm cụ thể |
| Đóng góp về tài liệu học thuật | tạo một thesis package có cấu trúc gần hoàn chỉnh, có front matter, list, appendix và references |

## 7.3 Future Development

Các hướng phát triển tiếp theo nên được phân thành ba nhóm để phản ánh đúng mức độ ưu tiên học thuật và kỹ thuật.

Nhóm thứ nhất là mở rộng chức năng. Theo hướng này, hệ thống có thể tiếp tục hoàn thiện knowledge workflows bằng cách mở rộng cơ chế sinh báo cáo, kiểm soát trích dẫn trong câu trả lời, quản lý chỉ mục thông minh hơn và tăng chiều sâu của các tương tác chat hoặc notebook synchronization. Đây là nhóm phát triển làm giàu giá trị sử dụng trực tiếp của nền tảng.

Nhóm thứ hai là hoàn thiện kiến trúc. Trọng tâm lớn nhất ở đây là hiện thực hóa đầy đủ vòng lặp phản hồi khủng hoảng theo kiến trúc mục tiêu, trong đó `analysis-srv` phát tín hiệu sang `project-srv`, `project-srv` là nơi chốt trạng thái khủng hoảng ở mức nghiệp vụ, và `ingest-srv` điều chỉnh chế độ crawl tương ứng. Nếu được hoàn thiện đúng mức, hướng này sẽ giúp hệ thống chuyển từ một nền tảng social listening có phản ứng thụ động sang một nền tảng có khả năng thích ứng động theo trạng thái rủi ro của miền nghiệp vụ.

Nhóm thứ ba là xác thực thực nghiệm. Đây là hướng có ý nghĩa học thuật đặc biệt quan trọng vì sẽ gia cố cho các kết luận ở Chương 6. Cụ thể, cần bổ sung benchmark reports, coverage reports, kết quả chạy test có kiểm chứng và các số liệu định lượng về throughput, latency, tài nguyên tiêu thụ hoặc chất lượng phản hồi của các tầng analytics và knowledge. Khi đó, hệ thống không chỉ được chứng minh ở mức cấu trúc mã nguồn và thiết kế kiến trúc, mà còn được đánh giá định lượng theo chuẩn thực nghiệm chặt chẽ hơn.

Ngoài ba hướng trên, một hướng phụ trợ nhưng cần thiết là hoàn thiện hệ thống hiện vật kỹ thuật và tài liệu phụ trợ, đặc biệt ở frontend source, CI/CD pipeline và deployment truth cho toàn nền tảng. Đây không phải là hướng mở rộng tính năng trực tiếp, nhưng lại có vai trò quan trọng trong việc làm cho hệ thống dễ bảo trì, dễ đánh giá và dễ chuyển giao hơn trong các giai đoạn phát triển tiếp theo.

## 7.4 Final Remarks

Tổng thể, SMAP là một hệ thống có độ phức tạp kỹ thuật cao và có tính thực tiễn rõ rệt. Qua quá trình phân tích, có thể thấy hệ thống đã vượt khỏi mô hình của một ứng dụng CRUD đơn giản để trở thành một nền tảng phân tích dữ liệu xã hội nhiều lớp, trong đó ngữ cảnh nghiệp vụ, runtime thu thập dữ liệu, pipeline phân tích, lớp tri thức và lớp thông báo được tách bạch thành các thành phần có vai trò tương đối rõ ràng. Đây là nền tảng tốt để hệ thống tiếp tục mở rộng theo chiều sâu cả về chức năng lẫn kiến trúc.

Về mặt luận văn, giá trị cốt lõi không chỉ nằm ở việc mô tả một hệ thống đang tồn tại, mà còn ở việc chứng minh được sự liên kết giữa ba lớp: yêu cầu, thiết kế và hiện thực. Chương 3 đã xác lập tập yêu cầu và use case dựa trên tài liệu và route thực tế. Chương 4 đã chuyển hóa các yêu cầu đó thành mô hình kiến trúc, thiết kế dữ liệu và thiết kế mô-đun. Chương 5 đã đối chiếu các quyết định thiết kế với code thực thi cụ thể. Chương 6 đã cho thấy hệ thống có một nền tảng kiểm thử và các chỉ báo sẵn sàng cho vận hành, dù chưa có đủ hiện vật để khẳng định đánh giá thực nghiệm định lượng ở mức đầy đủ. Nhờ đó, chương kết luận này có thể khẳng định rằng các mục tiêu cốt lõi của luận văn đã được hoàn thành ở mức phân tích kiến trúc và đối chiếu hiện thực hóa, đồng thời cũng chỉ ra trung thực những giới hạn còn tồn tại.

Nếu tiếp tục được phát triển theo hướng bổ sung hiện vật triển khai, số liệu thực nghiệm và các thành phần còn thiếu như frontend source hoặc pipeline CI/CD, SMAP sẽ không chỉ là một hệ thống có nền tảng kỹ thuật tốt, mà còn trở thành một đối tượng nghiên cứu và đánh giá có độ hoàn thiện học thuật cao hơn. Đây cũng chính là giá trị tiếp nối mà luận văn này hướng tới: tạo một nền tảng tài liệu đáng tin cậy để các bước phát triển sau có thể được thực hiện trên cơ sở nhất quán giữa mã nguồn, kiến trúc và mục tiêu nghiên cứu.
