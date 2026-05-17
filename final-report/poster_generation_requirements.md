# Yêu cầu thiết kế poster đồ án SMAP

## Mục tiêu

Thiết kế một poster học thuật cho đồ án chuyên ngành. Poster cần sáng tạo, không dùng template có sẵn, nhưng vẫn giữ cảm giác chuyên nghiệp, rõ ràng và phù hợp bối cảnh báo cáo cuối kỳ tại Trường Đại học Bách Khoa TP.HCM.

## Thông tin bắt buộc

### 1. Mã đề tài - Tên đề tài

- Mã đề tài: **HK252-DATN-386**
- Tên đề tài tiếng Việt: **Nền tảng phân tích mạng xã hội**
- Tên đề tài tiếng Anh: **SMAP - Social Media Analysis Platform**
- Tên đề tài hiển thị: **Nền tảng phân tích mạng xã hội - SMAP**
- Tên ngắn hiển thị nổi bật: **SMAP**
- Dòng mô tả phụ: **Nền tảng phân tích dữ liệu mạng xã hội phục vụ theo dõi, tổng hợp thông tin và hỗ trợ ra quyết định**

### 2. Giảng viên hướng dẫn

- **ThS. Lê Đình Thuận**

### 3. Sinh viên thực hiện

- Đặng Quốc Phong - 2212548
- Nguyễn Chánh Tín - 2213491
- Nguyễn Tấn Tài - 2212990

Thông tin theo định dạng khai báo:

- MSSV: `2212548_2213491_2212990`
- Họ tên sinh viên: `Đặng Quốc Phong_Nguyễn Chánh Tín_Nguyễn Tấn Tài`

## Nội dung poster

### 4. Vấn đề giải quyết

Dữ liệu mạng xã hội ngày càng trở thành nguồn thông tin quan trọng cho hoạt động theo dõi thương hiệu, phân tích xu hướng và hỗ trợ ra quyết định. Tuy nhiên, dữ liệu này có khối lượng lớn, thay đổi liên tục, phân tán trên nhiều nền tảng và thường ở dạng phi cấu trúc.

Các nhóm vận hành cần một hệ thống có khả năng:

- Theo dõi dữ liệu từ nhiều nguồn mạng xã hội.
- Chuẩn hóa và xử lý dữ liệu thu thập được.
- Phân tích tín hiệu đáng chú ý như cảm xúc, xu hướng, chủ đề và rủi ro.
- Khai thác kết quả phân tích theo ngữ cảnh.
- Nhận thông báo kịp thời khi có tình huống cần chú ý.

### 5. Giải pháp

SMAP được xây dựng như một hệ thống Social Media Analysis Platform theo hướng microservices, tập trung vào kiến trúc phần mềm, tổ chức luồng dữ liệu và khả năng vận hành.

Các nhóm giải pháp chính:

- **Thiết lập phạm vi theo dõi:** hỗ trợ campaign, project, nguồn dữ liệu và mục tiêu thu thập.
- **Thu thập dữ liệu:** điều phối crawl task từ các nền tảng mạng xã hội như TikTok, YouTube và Facebook.
- **Xử lý và phân tích:** chuẩn hóa dữ liệu, phân tích NLP/AI, trích xuất insight, sentiment, keyword, risk và các chỉ số hỗ trợ đánh giá.
- **Khai thác tri thức:** semantic search, chat theo ngữ cảnh và sinh báo cáo từ dữ liệu đã phân tích.
- **Theo dõi và cảnh báo:** notification gần thời gian thực cho trạng thái, lỗi xử lý và tín hiệu quan trọng.
- **Kiến trúc vận hành:** sử dụng các lane xử lý phù hợp cho API, crawl execution, analytics, retrieval và realtime delivery.

### 6. Kết quả

Đề tài đã xây dựng được một hệ thống SMAP có cấu trúc rõ ràng, có phân tách trách nhiệm theo service và có bằng chứng kiểm thử cho các luồng trọng yếu.

Kết quả nổi bật:

- Hoàn thiện mô hình yêu cầu với các use case chính cho quy trình social listening nội bộ.
- Thiết kế kiến trúc microservices theo capability và workload lane.
- Tổ chức luồng dữ liệu từ thiết lập campaign/project, thu thập, phân tích, truy hồi tri thức đến thông báo.
- Kết hợp nhiều công nghệ lưu trữ và truyền thông như PostgreSQL, Redis, MinIO, Qdrant, RabbitMQ, Kafka và WebSocket.
- Xây dựng giao diện web phục vụ kiểm thử và khai thác hệ thống.
- Có kiểm thử unit, kiểm thử chức năng, kiểm thử đầu cuối và đánh giá phi chức năng trong phạm vi đã đo.
- Hệ thống hỗ trợ các chức năng chính: quản lý campaign/project, datasource/target, analytics dashboard, semantic search, knowledge chat, AI reports, notification và crisis configuration.

## Gợi ý bố cục poster

Khổ poster đề xuất: **A1 dọc** hoặc **A0 dọc**.

### Bố cục tổng thể

1. **Header trên cùng**
   - Logo trường ở góc trái.
   - Tên trường/khoa ở góc phải hoặc dưới logo.
   - Tên đề tài lớn ở trung tâm.
   - Mã đề tài, GVHD và nhóm sinh viên đặt ngay dưới tiêu đề.

2. **Cột trái: Vấn đề**
   - Minh họa dữ liệu mạng xã hội phân tán.
   - Các bullet ngắn về dữ liệu lớn, nhiễu, phi cấu trúc, khó khai thác kịp thời.

3. **Cột giữa: Giải pháp SMAP**
   - Sơ đồ pipeline đơn giản:
     `Social Platforms -> Crawl -> Normalize -> Analytics -> Knowledge -> Dashboard/Alerts`
   - Dùng icon cho từng bước: network, database, AI, search, dashboard, bell.

4. **Cột phải: Kết quả**
   - Dùng các ô metric hoặc thẻ thông tin ngắn.
   - Nhấn mạnh hệ thống đã có kiến trúc, giao diện, kiểm thử và khả năng vận hành.

5. **Footer**
   - Từ khóa công nghệ: Microservices, Event-Driven, NLP/AI, Semantic Search, RAG, Realtime Notification, Kubernetes.
   - Có thể thêm QR hoặc URL demo nếu cần: `smap.tantai.dev`.

## Phong cách thiết kế

- Phong cách: hiện đại, học thuật, công nghệ, rõ ràng.
- Màu chủ đạo: xanh dương HCMUT, trắng, xanh nhạt; có thể dùng một màu nhấn như cam hoặc cyan cho các điểm nổi bật.
- Không dùng nền quá rối; ưu tiên các mảng rõ, đường nối pipeline và icon tuyến tính.
- Typography: tiêu đề lớn, đậm; nội dung ngắn gọn; không nhồi quá nhiều chữ.
- Nên dùng infographic thay vì đoạn văn dài.
- Poster cần nhìn được từ xa: tiêu đề, vấn đề, giải pháp và kết quả phải nhận ra ngay trong 5 giây.

## Prompt gợi ý để đưa vào công cụ tạo poster

Thiết kế poster học thuật khổ A1 dọc cho đề tài “Nền tảng phân tích mạng xã hội - SMAP”. Tên tiếng Anh: “SMAP - Social Media Analysis Platform”. Poster mang phong cách công nghệ hiện đại, chuyên nghiệp, sáng tạo, không dùng template có sẵn. Màu chủ đạo xanh dương - trắng theo tinh thần Đại học Bách Khoa TP.HCM, có điểm nhấn cyan/cam nhẹ.

Nội dung bắt buộc gồm: mã đề tài HK252-DATN-386, tên đề tài tiếng Việt “Nền tảng phân tích mạng xã hội”, tên đề tài tiếng Anh “SMAP - Social Media Analysis Platform”, GVHD ThS. Lê Đình Thuận, sinh viên Đặng Quốc Phong - 2212548, Nguyễn Chánh Tín - 2213491, Nguyễn Tấn Tài - 2212990.

Poster chia thành các khu vực rõ ràng: Vấn đề giải quyết, Giải pháp, Kết quả. Phần vấn đề mô tả dữ liệu mạng xã hội lớn, nhiễu, phi cấu trúc, phân tán và cần khai thác kịp thời. Phần giải pháp trình bày SMAP như một nền tảng microservices hỗ trợ thu thập dữ liệu, chuẩn hóa, phân tích NLP/AI, semantic search, knowledge chat, AI reports, dashboard và realtime alerts. Phần kết quả nêu hệ thống đã xây dựng được kiến trúc rõ ràng, giao diện web, các luồng campaign/project, crawl, analytics, search/chat/report, notification và có kiểm thử chức năng, E2E, NFR trong phạm vi đo.

Tạo một infographic pipeline ở trung tâm: Social Platforms -> Crawl -> Normalize -> Analytics -> Knowledge -> Dashboard/Alerts. Dùng icon tối giản cho mạng xã hội, dữ liệu, AI, tìm kiếm, báo cáo và thông báo. Bố cục phải dễ đọc từ xa, ít chữ, nhiều cấu trúc trực quan, phù hợp poster bảo vệ đồ án chuyên ngành.
