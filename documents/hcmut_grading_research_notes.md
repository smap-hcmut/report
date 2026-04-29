# HCMUT Grading Research Notes for SMAP Thesis

## Mục đích

File này ghi lại kết quả research nhanh về cách chấm điểm đồ án tốt nghiệp tại Trường Đại học Bách Khoa - ĐHQG TP.HCM, đặc biệt trong bối cảnh Khoa Khoa học và Kỹ thuật Máy tính, ngành Khoa học Máy tính / Công nghệ Phần mềm.

Lưu ý quan trọng: chưa tìm thấy rubric chấm điểm công khai chính thức của Khoa KH&KT Máy tính cho ĐATN/LVTN. Vì vậy, tài liệu này tách rõ:

- phần có nguồn công khai
- phần suy luận từ thông lệ chấm đồ án kỹ thuật và dấu vết công khai
- phần áp dụng thực tế cho đồ án SMAP

## Kết quả research từ nguồn công khai

### 1. Học phần tốt nghiệp của Khoa KH&KT Máy tính

Các học phần tốt nghiệp liên quan đến Khoa KH&KT Máy tính xuất hiện trên hệ thống MyBK/HCMUT, gồm:

- `CO4337` - Đồ án Tốt nghiệp (Khoa học Máy tính)
- `CO4357` - Đồ án Tốt nghiệp (Công nghệ Thông tin)
- `CO4347` - Đồ án Tốt nghiệp (Kỹ thuật Máy tính)

Nguồn:

- https://mybk.hcmut.edu.vn/bksi/public/vi/blog/danh-muc-loai-tru-tu-chon-tu-do
- https://mybk.hcmut.edu.vn/bksi/public/vi/blog/chuan-tong-so-tin-chi-tich-luy-de-dang-ky-cac-hoc-phan-tt-nghip-khoa-2024

### 2. Hồ sơ nộp sau bảo vệ có phiếu chấm điểm

Các mẫu/hướng dẫn thesis HCMUT có nhắc đến việc báo cáo sau bảo vệ cần đi kèm:

- phiếu nhiệm vụ
- phiếu chấm điểm hướng dẫn
- phiếu chấm điểm phản biện
- lời cam đoan
- lời cảm ơn
- tóm tắt
- mục lục
- danh mục bảng/hình nếu có
- nội dung luận văn/đồ án
- tài liệu tham khảo
- phụ lục nếu có

Điều này cho thấy việc chấm điểm có biểu mẫu chính thức, nhưng biểu mẫu chi tiết nhiều khả năng là tài liệu nội bộ của Khoa/GVHD/GVPB/Hội đồng.

Nguồn tham khảo template:

- https://www.overleaf.com/latex/templates/hcmut-thesis-slash-dissertation-template/zsbhtnzktbsy

### 3. Định hướng của Khoa KH&KT Máy tính

Trang Khoa KH&KT Máy tính nhấn mạnh:

- chương trình đào tạo theo hướng chuẩn quốc tế/ABET
- hoạt động nghiên cứu khoa học
- năng lực xây dựng sản phẩm có ý nghĩa thực tiễn
- chuẩn bị kỹ năng nghề nghiệp và năng lực kỹ thuật cho sinh viên

Điều này gợi ý hội đồng thường xem trọng cả:

- nền tảng kỹ thuật
- tính thực tiễn của hệ thống
- phương pháp phân tích/thiết kế
- khả năng chứng minh bằng hiện thực
- năng lực trình bày và bảo vệ

Nguồn:

- https://cse.hcmut.edu.vn/nganh-ky-thuat-may-tinh

## Kết luận research

Chưa tìm thấy rubric điểm công khai chính thức cho ĐATN/LVTN ngành Khoa học Máy tính hoặc Công nghệ Phần mềm của HCMUT.

Tuy nhiên, có thể rút ra định hướng chấm điểm có khả năng cao như sau:

- hội đồng không chỉ chấm báo cáo, mà còn chấm mức độ hiểu hệ thống và khả năng bảo vệ
- báo cáo phải trình bày đúng phương pháp, đúng kỹ thuật, có bằng chứng
- hệ thống phải có sản phẩm/hiện thực đủ thuyết phục
- các claim trong báo cáo cần khớp implementation thực tế
- hạn chế phải được nêu trung thực, không overclaim

## Các nhóm tiêu chí hội đồng có khả năng soi mạnh

### 1. Bài toán và mục tiêu

Hội đồng có thể đánh giá:

- đề tài có giải quyết vấn đề rõ ràng không
- phạm vi có hợp lý không
- đối tượng sử dụng có cụ thể không
- contribution của nhóm là gì
- đề tài có phù hợp chuyên ngành Khoa học Máy tính / Công nghệ Phần mềm không

### 2. Phân tích và thiết kế hệ thống

Hội đồng có thể xem:

- requirement có rõ không
- use case có logic không
- kiến trúc có phù hợp bài toán không
- database/API/sequence có nhất quán không
- có phân tích trade-off không
- thiết kế có khớp implementation không

### 3. Hiện thực kỹ thuật

Hội đồng có thể hỏi:

- hệ thống thật có chạy không
- flow chính có demo được không
- service boundaries có rõ không
- code có phản ánh đúng thiết kế không
- có xử lý lỗi và edge cases quan trọng không
- có khác biệt nào giữa báo cáo và source không

### 4. Kiểm thử và đánh giá

Hội đồng có thể quan tâm:

- có unit/integration/E2E test không
- có evidence từ quá trình chạy thật không
- có benchmark hoặc giới hạn đánh giá rõ không
- test có bao phủ flow chính không
- có phân biệt giữa pipeline ready và full real-data validation không

### 5. Báo cáo và hình thức

Hội đồng có thể đánh giá:

- văn phong có học thuật không
- bố cục chương có logic không
- hình/bảng có rõ, đúng và được tham chiếu không
- tài liệu tham khảo có chuẩn không
- có phụ lục kỹ thuật hỗ trợ không
- báo cáo có overclaim hoặc mâu thuẫn nội bộ không

### 6. Bảo vệ và phản biện

Hội đồng có thể đánh giá:

- sinh viên có hiểu hệ thống thật không
- có giải thích được quyết định kiến trúc không
- có nhận diện được giới hạn không
- có trả lời được câu hỏi về thuật toán, kỹ thuật, testing và deployment không
- có phân biệt current implementation với future work không

## Áp dụng cho đồ án SMAP

Để tối ưu khả năng được đánh giá tốt, SMAP nên nhấn mạnh các điểm sau:

### 1. Chứng minh hệ thống thật có chạy

SMAP nên dùng bằng chứng từ:

- `e2e-report.md`
- `final-report.md`
- test assets trong `analysis-srv`, `ingest-srv`, `notification-srv`
- source-code evidence matrix

Điểm cần trình bày rõ:

- pipeline core đã được unblock
- các bug blocker đã được phát hiện và sửa
- hệ thống có flow tích hợp nhiều service, không chỉ là thiết kế giấy

### 2. Báo cáo phải khớp source hiện tại

Các phần cần fact-check kỹ:

- lifecycle `PENDING | ACTIVE | PAUSED | ARCHIVED`
- `project.crisis_status = NORMAL | WARNING | CRITICAL`
- `domain_type_code` đi qua `project -> ingest -> analysis`
- `analysis-srv` consume `smap.collector.output`
- output topics:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
- `notification-srv` WebSocket route `/ws`
- `scapper-srv` dùng FastAPI app + worker lifespan

### 3. Không overclaim phần chưa chứng minh đủ

Không nên khẳng định rằng hệ thống đã hoàn tất đầy đủ:

- crawl data thực tế quy mô lớn
- analyze dữ liệu thực tế có chất lượng đo được
- dashboard/report hoàn chỉnh với dữ liệu thật
- benchmark throughput/latency đầy đủ

Nếu chưa có evidence, nên ghi là:

- pipeline đã sẵn sàng nhận dữ liệu
- các blocker tích hợp chính đã được xử lý
- cần thêm real-data validation và benchmark trong future work

### 4. Nhấn mạnh contribution phù hợp chuyên ngành

Các contribution nên được trình bày theo hướng:

- kiến trúc microservices cho social media analytics
- phân tách control plane, execution plane, analytics plane, knowledge plane
- UAP/domain-aware data contract
- pipeline ingest -> analysis -> knowledge
- kiểm thử và sửa lỗi E2E trên hệ thống thật
- source-code-evidenced thesis: báo cáo khớp implementation thay vì mô tả rời rạc

## Câu hỏi phản biện có khả năng xuất hiện

1. Đóng góp chính của đề tài là gì: thuật toán AI, kiến trúc hệ thống, hay hiện thực pipeline?
2. Vì sao chọn microservices thay vì modular monolith?
3. Hệ thống đã được kiểm thử đến mức nào? Có dữ liệu crawl/analyze thực tế chưa?
4. `domain_type_code` đóng vai trò gì trong pipeline phân tích?
5. UAP contract giúp gì cho việc tách `ingest-srv` và `analysis-srv`?
6. Nếu một service trong pipeline lỗi thì hệ thống xử lý thế nào?
7. Vì sao dùng Kafka, RabbitMQ, Redis Pub/Sub cùng lúc?
8. Các giới hạn lớn nhất của hệ thống hiện tại là gì?
9. Nếu mở rộng sang domain mới hoặc platform mới thì cần thay đổi gì?
10. Làm sao chứng minh báo cáo không mô tả sai implementation?

## Kết luận ngắn

Không có rubric công khai đủ chi tiết để chắc chắn hội đồng sẽ chia điểm như thế nào. Tuy nhiên, với đồ án thuộc Khoa KH&KT Máy tính, hướng tối ưu là chuẩn bị báo cáo theo tiêu chí:

- đúng bài toán
- đúng kỹ thuật
- có hiện thực
- có kiểm thử
- có bằng chứng
- có giới hạn trung thực
- bảo vệ được các quyết định kiến trúc

Với SMAP, trọng tâm nên là chứng minh đây không chỉ là một ý tưởng social listening, mà là một hệ thống microservices có pipeline thật, có tích hợp thật, có bug-fix/E2E evidence, và có báo cáo bám sát source hiện tại.
