# Kịch bản theo từng slide cho phần bảo vệ SMAP

Tài liệu này là bản ghi chú theo slide, dùng khi trình bày trực tiếp trước hội đồng. Mục tiêu không phải là liệt kê thông tin cho đủ, mà là giữ cho mỗi slide có một luận điểm rõ ràng: slide này xuất hiện để thuyết phục điều gì, và vì sao phải nói theo hướng đó.

Nguyên tắc dùng tài liệu này:

- Mỗi slide chỉ giữ một ý chính.
- Luôn nói từ bối cảnh đến lý do, rồi mới đến kỹ thuật.
- Nếu slide có hình hoặc sơ đồ, hãy nói theo hình, không đọc chữ trên slide.
- Khi hết thời gian, ưu tiên giữ phần kiến trúc, luồng xử lý và bằng chứng kiểm thử.

---

## Slide 1 - Trang bìa

Mục tiêu của slide này là định vị ngay cho hội đồng biết đề tài là gì, ai trình bày và đang nói về hệ thống nào.

Nên nói:

- Tên đề tài: SMAP - Social Media Analytics Platform.
- Tên nhóm, giảng viên hướng dẫn, và bối cảnh bảo vệ.

Vì sao phải nói như vậy:

- Slide mở đầu không nên đi thẳng vào kỹ thuật.
- Hội đồng cần một điểm neo trước khi nghe phần phân tích sâu.
- Nếu mở quá nhanh vào kiến trúc, người nghe sẽ mất bối cảnh và khó theo dõi mạch sau đó.

Chuyển ý:

- Sau khi định danh đề tài, chuyển ngay sang lý do đề tài này tồn tại trong thực tế.

---

## Slide 2 - Tóm tắt đề tài

Mục tiêu của slide này là chốt một câu rất ngắn: SMAP là gì, và nhóm đang làm gì với nó.

Nên nói:

- SMAP là hệ thống phân tích dữ liệu mạng xã hội.
- Trọng tâm của đồ án là thiết kế và hiện thực hệ thống, không phải nghiên cứu mô hình AI mới.
- Kết quả chính là một hệ thống có kiến trúc rõ, có thể chạy được và có thể kiểm thử được.

Vì sao phải nói như vậy:

- Hội đồng cần biết ngay phạm vi của đề tài để tránh kỳ vọng sai.
- Việc nói rõ đây là bài toán hệ thống giúp giữ tiêu chuẩn đánh giá đúng hướng.
- Nếu không chốt sớm phạm vi, các phần sau rất dễ bị hiểu thành một đồ án ML thuần túy.

Chuyển ý:

- Từ phần tóm tắt, dẫn sang bối cảnh thực tế và nhu cầu thị trường.

---

## Slide 3 - Bối cảnh thị trường

Mục tiêu của slide này là cho thấy bài toán không phải do nhóm tự đặt ra, mà xuất phát từ nhu cầu thật.

Nên nói:

- Social listening và social analytics là nhu cầu thật của marketing, brand tracking và nghiên cứu thị trường.
- Dữ liệu mạng xã hội vừa nhiều, vừa nhiễu, vừa thay đổi nhanh.
- Các hệ thống trên thị trường cho thấy đây là một bài toán có giá trị thương mại rõ ràng.

Vì sao phải nói như vậy:

- Một bài toán được chứng minh bằng bối cảnh thực tế sẽ thuyết phục hơn một bài toán chỉ có mô tả kỹ thuật.
- Hội đồng thường muốn biết: vì sao đề tài này đáng làm.
- Đây là chỗ tạo “lý do tồn tại” cho toàn bộ hệ thống.

Chuyển ý:

- Từ nhu cầu thị trường, chuyển sang bản chất kỹ thuật của dữ liệu và xử lý.

---

## Slide 4 - Bài toán cần giải quyết

Mục tiêu của slide này là tách rõ “có dữ liệu” khác với “biến dữ liệu thành insight”.

Nên nói:

- Dữ liệu MXH lớn, phi cấu trúc và có tính thời gian thực.
- Quy trình cần đi từ thu thập đến phân tích, rồi đến insight có thể sử dụng.
- Thách thức nằm ở khả năng scale, xử lý bất đồng bộ, chịu lỗi và giữ performance.

Vì sao phải nói như vậy:

- Đây là slide biến bối cảnh thị trường thành bài toán kỹ thuật cụ thể.
- Nếu không làm rõ khó khăn, kiến trúc phía sau sẽ trông như một lựa chọn ngẫu nhiên.
- Slide này tạo nền để giải thích vì sao kiến trúc hiện tại lại hợp lý.

Chuyển ý:

- Sau khi xác định bài toán, nói tiếp về mục tiêu và phạm vi mà nhóm chọn.

---

## Slide 5 - Mục tiêu và phạm vi

Mục tiêu của slide này là cho thấy nhóm chủ động giới hạn bài toán để làm sâu thay vì làm lan man.

Nên nói:

- Mục tiêu là xây dựng hệ thống có cấu trúc rõ, chạy được, kiểm thử được và mở rộng được.
- Phạm vi tập trung vào kiến trúc, luồng dữ liệu và phân tách trách nhiệm giữa các service.
- Nhóm không đặt mục tiêu nghiên cứu một mô hình AI mới từ đầu.

Vì sao phải nói như vậy:

- Nếu phạm vi không rõ, mọi phần sau đều dễ bị hỏi ngược rằng “làm đến đâu rồi”.
- Việc giới hạn phạm vi giúp hội đồng đánh giá đúng chiều sâu của đồ án.
- Đây cũng là chỗ để chặn trước các câu hỏi kiểu “sao không làm thêm cái này, cái kia”.

Chuyển ý:

- Từ mục tiêu và phạm vi, dẫn vào kiến trúc tổng quan của hệ thống.

---

## Slide 6 - System Context

Mục tiêu của slide này là đặt SMAP vào đúng hệ sinh thái sử dụng của nó.

Nên nói:

- SMAP đứng giữa người dùng nội bộ và các nền tảng mạng xã hội.
- Người dùng không tương tác trực tiếp với dữ liệu thô, mà tương tác với hệ thống đã xử lý.
- Hệ thống đóng vai trò như một lớp trung gian biến dữ liệu thô thành dữ liệu có giá trị.

Vì sao phải nói như vậy:

- Slide context giúp hội đồng hiểu “hệ thống ở đâu” trước khi đi vào “hệ thống gồm những gì”.
- Đây là bước chuyển từ bối cảnh thị trường sang kiến trúc phần mềm.
- Nếu thiếu slide này, phần container và service sau đó sẽ bị rơi vào trạng thái quá kỹ thuật.

Chuyển ý:

- Sau khi định vị hệ thống, đi vào cách hệ thống được tách thành các service.

---

## Slide 7 - Container Diagram

Mục tiêu của slide này là giải thích vì sao hệ thống không đi theo monolith, mà được tách thành nhiều service với công nghệ khác nhau.

Nên nói:

- Các service chính được chia theo nhiệm vụ, không chia theo cảm tính.
- Go phù hợp cho các service lõi cần hiệu năng và xử lý đồng thời tốt.
- Python phù hợp cho analytics và crawling vì hệ sinh thái xử lý dữ liệu và NLP mạnh hơn.
- Next.js phù hợp cho lớp giao diện và trải nghiệm người dùng.

Vì sao phải nói như vậy:

- Hội đồng thường hỏi “tại sao dùng nhiều công nghệ” chứ không chỉ hỏi “đã dùng gì”.
- Slide này phải trả lời được logic phân chia trách nhiệm và logic chọn runtime.
- Nếu chỉ liệt kê tên service, người nghe sẽ không thấy được tư duy kiến trúc phía sau.

Chuyển ý:

- Từ service-level, đi tiếp xuống hạ tầng hỗ trợ cho các service đó.

---

## Slide 8 - Infrastructure Components

Mục tiêu của slide này là chứng minh hệ thống không chỉ có service, mà còn có hạ tầng đúng với từng loại dữ liệu và tải.

Nên nói:

- PostgreSQL giữ dữ liệu nghiệp vụ cần tính nhất quán.
- Redis giữ cache, session và trạng thái ngắn hạn.
- MinIO giữ artifact lớn và dữ liệu thô.
- RabbitMQ và Redis Pub/Sub phục vụ các kiểu giao tiếp bất đồng bộ khác nhau.

Vì sao phải nói như vậy:

- Slide này giúp hội đồng thấy lựa chọn công nghệ không phải “thích gì dùng nấy”.
- Mỗi thành phần phải gắn với một loại workload cụ thể.
- Đây là điểm để giải thích trade-off giữa độ phức tạp vận hành và hiệu quả xử lý.

Chuyển ý:

- Sau hạ tầng, cần nói rõ cơ chế luồng sự kiện và cách xử lý payload lớn.

---

## Slide 9 - Event-Driven Architecture

Mục tiêu của slide này là chứng minh hệ thống xử lý theo dòng sự kiện, chứ không block người dùng chờ toàn bộ pipeline chạy xong.

Nên nói:

- Các tác vụ nặng được tách sang luồng async.
- RabbitMQ dùng cho job dispatch, Redis Pub/Sub cho fanout realtime.
- Claim-check pattern được dùng để tránh đẩy payload lớn trực tiếp qua queue.

Vì sao phải nói như vậy:

- Đây là một điểm kỹ thuật đắt giá, nên cần nhấn mạnh rõ.
- Hội đồng sẽ muốn biết hệ thống xử lý dữ liệu lớn bằng cách nào mà không nghẽn.
- Nếu nói đúng claim-check pattern, hệ thống sẽ trông có tư duy vận hành hơn là chỉ “có queue”.

Chuyển ý:

- Sau khi nêu cơ chế event-driven, giải thích tiếp tại sao chọn microservices thay vì kiến trúc khác.

---

## Slide 10 - Tại sao chọn Microservices

Mục tiêu của slide này là bảo vệ quyết định kiến trúc.

Nên nói:

- Workload của hệ thống không đồng nhất.
- Có service cần scale nhanh, có service cần ổn định, có service cần runtime khác nhau.
- Microservices giúp cô lập lỗi và mở rộng từng lane thay vì kéo cả hệ thống cùng scale.

Vì sao phải nói như vậy:

- Nếu không có slide này, kiến trúc phía trước sẽ giống mô tả thuần túy thay vì một lựa chọn có lý do.
- Đây là nơi phải nói rõ trade-off: phức tạp vận hành tăng, nhưng đổi lại khả năng cô lập lỗi và scale tốt hơn.
- Slide này là câu trả lời ngắn gọn cho câu hỏi phản biện phổ biến nhất.

Chuyển ý:

- Từ kiến trúc tổng thể, chuyển sang phần chức năng để chứng minh hệ thống phục vụ đúng nghiệp vụ.

---

## Slide 11 - Use Cases Overview

Mục tiêu của slide này là nối kiến trúc với nhu cầu nghiệp vụ cụ thể.

Nên nói:

- Hệ thống phục vụ các use case xoay quanh quản lý project, vận hành chiến dịch, theo dõi trạng thái và nhận cảnh báo.
- Không trình bày toàn bộ use case theo kiểu liệt kê máy móc.
- Chỉ nhấn vào các use case thật sự thể hiện giá trị của hệ thống.

Vì sao phải nói như vậy:

- Sau phần kiến trúc, hội đồng cần thấy kiến trúc đó phục vụ cái gì.
- Đây là chỗ chuyển từ “hệ thống được xây như thế nào” sang “hệ thống dùng để làm gì”.
- Nếu chỉ nói kiến trúc mà không nói use case, phần trình bày sẽ thiếu tính ứng dụng.

Chuyển ý:

- Trong các use case, chọn một pipeline chính để mô tả end-to-end.

---

## Slide 12 - Data Pipeline 4 giai đoạn

Mục tiêu của slide này là mô tả rõ cách dữ liệu đi từ đầu vào đến đầu ra.

Nên nói:

- Dữ liệu đi qua các giai đoạn: crawling, analyzing, aggregating, finalizing.
- Mỗi giai đoạn gắn với một service hoặc một vai trò rõ ràng.
- Pipeline này cho thấy hệ thống không xử lý rời rạc, mà xử lý theo chuỗi.

Vì sao phải nói như vậy:

- Đây là phần trả lời trực tiếp cho câu hỏi: hệ thống có chạy được luồng nghiệp vụ chính không.
- Một pipeline rõ ràng giúp hội đồng hiểu tác động của kiến trúc lên trải nghiệm thật.
- Đây cũng là nơi thể hiện tư duy thiết kế hướng dòng chảy dữ liệu.

Chuyển ý:

- Sau pipeline tổng thể, chọn một luồng quan trọng nhất để đi sâu bằng sequence diagram.

---

## Slide 13 - Sequence Diagram: Execute Project

Mục tiêu của slide này là chứng minh hệ thống phối hợp giữa các service được theo đúng runtime, không chỉ đúng trên sơ đồ.

Nên nói:

- User khởi tạo project.
- Project service điều phối.
- Collector hoặc crawler thực thi job.
- Analytics xử lý kết quả.
- Hệ thống trả trạng thái và thông báo về cho người dùng.

Vì sao phải nói như vậy:

- Đây là slide thực thi, nên cần nói theo luồng chứ không nói theo danh sách service.
- Hội đồng thường tin sequence diagram hơn một mô tả tổng quát vì nó thể hiện tính khả thi của hệ thống.
- Chọn một use case trung tâm giúp tránh lan man và cho thấy đường đi của dữ liệu từ đầu đến cuối.

Chuyển ý:

- Sau khi chứng minh luồng chạy, giải thích cách dữ liệu được tổ chức và lưu trữ.

---

## Slide 14 - Database Strategy

Mục tiêu của slide này là chứng minh hệ thống không ép mọi loại dữ liệu vào một cơ sở dữ liệu duy nhất.

Nên nói:

- Service nào giữ dữ liệu của service đó.
- PostgreSQL phù hợp với dữ liệu nghiệp vụ và quan hệ.
- Các luồng bất đồng bộ chấp nhận eventual consistency thay vì ép đồng bộ mọi thứ.

Vì sao phải nói như vậy:

- Đây là chỗ hội đồng có thể hỏi về nhất quán dữ liệu và phân tách boundary.
- Nói rõ chiến lược dữ liệu giúp bảo vệ kiến trúc microservices.
- Nếu bỏ qua slide này, phần kiến trúc sẽ thiếu một trụ cột quan trọng.

Chuyển ý:

- Sau khi nói kiến trúc và luồng, cần có bằng chứng về những gì đã hoàn thành.

---

## Slide 15 - Deliverables

Mục tiêu của slide này là chứng minh đồ án không chỉ ở mức ý tưởng mà đã có đầu ra cụ thể.

Nên nói:

- Có bộ phân tích yêu cầu, thiết kế và các sơ đồ kiến trúc.
- Có hiện thực các service lõi và hạ tầng triển khai.
- Có các pattern chính như event-driven, claim-check, saga hoặc tương đương.

Vì sao phải nói như vậy:

- Hội đồng cần thấy “bằng chứng bàn giao”, không chỉ lời mô tả.
- Slide này là chỗ chốt lại khối lượng công việc đã hoàn thành.
- Nó cũng giúp giảm cảm giác rằng phần trước chỉ là mô tả kiến trúc trên giấy.

Chuyển ý:

- Sau deliverables, cho một hoặc hai hình ảnh demo để làm hệ thống trở nên cụ thể hơn.

---

## Slide 16 - Demo / Screenshots

Mục tiêu của slide này là biến hệ thống từ một bản mô tả trừu tượng thành một thứ có thể nhìn thấy.

Nên nói:

- Giới thiệu nhanh landing page, project configuration, dry-run và dashboard.
- Chỉ nêu 1-2 điểm đáng chú ý trên giao diện.
- Nếu có video, chỉ dùng để minh họa tốc độ hoặc trạng thái thật.

Vì sao phải nói như vậy:

- Hội đồng thường phản ứng tốt hơn khi nhìn thấy kết quả trực quan.
- Demo không nên kéo dài; mục tiêu là xác nhận hệ thống có hiện thực.
- Slide này chỉ cần hỗ trợ niềm tin, không nên biến thành phần trình bày riêng.

Chuyển ý:

- Sau khi có bằng chứng hiện tại, nói tiếp về hướng phát triển tiếp theo.

---

## Slide 17 - Kế hoạch phát triển

Mục tiêu của slide này là cho thấy nhóm hiểu hệ thống hiện tại ở đâu và sẽ đi tiếp như thế nào.

Nên nói:

- Có thể mở rộng hạ tầng theo hướng hybrid hoặc cloud-friendly nếu cần.
- Có thể nâng cấp observability, benchmark và khả năng vận hành.
- Có thể mở rộng nguồn dữ liệu, pipeline và lớp tri thức.

Vì sao phải nói như vậy:

- Một đồ án tốt không cần tuyên bố đã giải quyết mọi thứ.
- Hội đồng thường đánh giá cao việc biết rõ hướng đi tiếp theo hơn là nói quá khả năng hiện tại.
- Slide này cho thấy nhóm nhìn hệ thống như một nền tảng có lộ trình.

Chuyển ý:

- Sau hướng phát triển, cần nói thẳng về những giới hạn còn tồn tại.

---

## Slide 18 - Hạn chế hiện tại

Mục tiêu của slide này là thể hiện sự trung thực và hiểu đúng phạm vi của đề tài.

Nên nói:

- Hệ thống vẫn còn các phần chưa hoàn thiện ở mức production.
- Các kiểm thử hoặc benchmark dài hạn chưa phải là điểm mạnh cuối cùng.
- Phạm vi dữ liệu và mô hình vẫn còn giới hạn.

Vì sao phải nói như vậy:

- Chủ động nói hạn chế làm câu trả lời phản biện chắc hơn.
- Hội đồng thường tin một nhóm biết giới hạn của mình hơn là một nhóm nói quá mức.
- Slide này giúp bảo vệ luận điểm rằng đề tài đã hoàn thành đúng phạm vi, không phải cố làm rộng ngoài khả năng.

Chuyển ý:

- Từ hạn chế, đi sang kết luận để khép lại câu chuyện của toàn bộ hệ thống.

---

## Slide 19 - Kết luận và Q&A

Mục tiêu của slide này là chốt lại giá trị của đề tài trong một câu ngắn và mời hội đồng phản biện.

Nên nói:

- SMAP là một hệ thống social media analytics có kiến trúc rõ ràng.
- Hệ thống đã có hiện thực, có luồng xử lý trọng yếu và có bằng chứng kiểm thử.
- Nhóm sẵn sàng trả lời câu hỏi phản biện.

Vì sao phải nói như vậy:

- Kết luận không cần thêm thông tin mới, mà cần tổng hợp đúng giá trị cốt lõi.
- Slide này phải để lại ấn tượng cuối cùng: hệ thống có tư duy kiến trúc, không chỉ là tập hợp công nghệ.
- Mời Q&A rõ ràng giúp chuyển nhịp sang phần phản biện một cách tự nhiên.

---

## Ghi chú cuối

Nếu cần rút ngắn thời gian, hãy giữ thứ tự ưu tiên sau:

1. Bối cảnh và bài toán.
2. Kiến trúc tổng quan và lý do chọn nó.
3. Pipeline chính và sequence diagram.
4. Bằng chứng kiểm thử.
5. Hạn chế và kết luận.

Nếu cần tăng độ thuyết phục, hãy luôn trả lời theo mẫu:

- Đây là vấn đề gì.
- Vì sao phải giải quyết theo cách này.
- Cách làm đó đổi lại điều gì.
- Bằng chứng hiện có là gì.