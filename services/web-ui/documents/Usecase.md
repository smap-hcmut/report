[https://gemini.google.com/share/6d0bd1ae3555](https://gemini.google.com/share/6d0bd1ae3555)

# **Báo cáo Phân tích Yêu cầu Hệ thống cho Nền tảng SMAP (Phiên bản 2.0)**

Phiên bản: 6.0  
Ngày: 9 tháng 10 năm 2025  
Mục đích: Tài liệu này đặc tả chi tiết các yêu cầu chức năng, phi chức năng, và các kịch bản sử dụng cho nền tảng SMAP. Báo cáo này đóng vai trò là nguồn thông tin chính thức (Single Source of Truth) cho đội ngũ phát triển, kiểm thử và các bên liên quan trong suốt vòng đời dự án.

---

### **1\. Các Bên liên quan & Vai trò (Stakeholders & Roles)**

| Vai trò (Role) | Tên gọi trong tài liệu | Mô tả |
| :---- | :---- | :---- |
| Người dùng chính | **Marketing Analyst** | Người trực tiếp sử dụng SMAP để thực hiện các tác vụ phân tích, báo cáo, nghiên cứu xu hướng, đối thủ và người tiêu dùng. |
| Người quản lý cộng đồng | **Community Manager** | Người sử dụng SMAP chủ yếu cho các tác vụ vận hành hàng ngày như theo dõi thảo luận, quản lý khủng hoảng và tương tác với người dùng. |
| Khách hàng của người dùng | **Client Viewer** | Người nhận báo cáo hoặc truy cập vào các dashboard chỉ đọc để theo dõi hiệu suất. |
| Quản trị viên hệ thống | **System Administrator** | Người chịu trách nhiệm vận hành, bảo trì và giám sát hệ thống SMAP. |
| Chủ sở hữu sản phẩm | **Product Owner** | Người định hướng tầm nhìn sản phẩm và ưu tiên các yêu cầu. |

---

### **2\. Bảng thuật ngữ (Glossary)**

| Thuật ngữ | Viết tắt | Định nghĩa | Ví dụ |
| :---- | :---- | :---- | :---- |
| **Time to Insight** | TTI | Time to Insight (TTI) là khoảng thời gian từ lúc người dùng thực hiện một hành động yêu cầu thông tin cho đến khi họ nhìn thấy được kết quả hoặc insight tương ứng hiển thị trên hệ thống.Nói cách khác, TTI đo tốc độ mà hệ thống có thể biến một “ý định” của người dùng thành một “hiểu biết có giá trị”. | Ngay khi họ nhấn nút “Phân tích”, hệ thống ghi nhận một sự kiện (event) — đây là thời điểm bắt đầu, gọi là event\_time.Từ đó, trong một kiến trúc event-driven, hàng loạt tiến trình tự động được kích hoạt: Collector nhận yêu cầu và gửi nó vào hàng đợi sự kiện (Kafka/NATS,…). Worker / Processor bắt đầu tìm kiếm dữ liệu từ nhiều nguồn, gọi mô hình AI/NLP để phân tích nội dung, chủ đề, cảm xúc. Aggregator gom kết quả, lọc nhiễu, chuẩn hóa dữ liệu. Publisher đẩy kết quả cuối cùng lên dashboard hoặc API hiển thị. Khi toàn bộ pipeline hoàn tất và dashboard hiển thị danh sách các chủ đề, đó là thời điểm **insight xuất hiện**, gọi là **insight\_ready\_at**.  |
| **Share of Voice** | SoV | Tỷ lệ phần trăm thảo luận về một thương hiệu so với tổng số thảo luận của tất cả các thương hiệu được theo dõi trong cùng một dự án. (bao gồm thương hiệu đối thủ) | YouNet Media ghi nhận tổng 759.988 thảo luận về Top 10 thương hiệu Coffee Shop trên MXH nửa đầu 2025\. Trong đó có số lượt nhắc theo thương hiệu: Highlands \= 199.281, Starbucks \= 197.562, Trung Nguyên Legend \= 105.322Tính SOV (Share of Voice) theo mentions SOV Highlands \= 199.281 / 759.988 ≈ 26,2% SOV Starbucks \= 197.562 / 759.988 ≈ 26,0% SOV Trung Nguyên Legend \= 105.322 / 759.988 ≈ 13,9% ⇒ Các thương hiệu khác (trong Top 10\) cộng lại ≈ 33,9%.   |
| **Net Sentiment Score** | NSS | Net Sentiment Score (NSS) là chỉ số thể hiện cảm xúc ròng của cộng đồng hoặc người dùng đối với một chủ đề, thương hiệu hoặc sự kiện, được tính bằng tỷ lệ phần trăm thảo luận tích cực trừ đi tỷ lệ phần trăm thảo luận tiêu cực. Nói ngắn gọn, NSS cho biết “mọi người đang cảm thấy thế nào” về điều bạn đang theo dõi — vui, buồn, hay tức giận — và mức độ cảm xúc đó mạnh đến đâu. | **NSS \= (% Thảo luận Tích cực) − (% Thảo luận Tiêu cực)** Trong đó: \- % Thảo luận Tích cực \= Tỷ lệ các bài viết, bình luận, hoặc tin tức có cảm xúc tốt, thể hiện sự hài lòng, đồng tình, yêu thích, ủng hộ. \- % Thảo luận Tiêu cực \= Tỷ lệ các bài viết, bình luận, hoặc tin tức có cảm xúc xấu, thể hiện sự bức xúc, thất vọng, chỉ trích. |
| **Acceptance Criteria** | AC | Các điều kiện cụ thể mà một User Story phải thỏa mãn để được coi là hoàn thành. |  |
| **Service Level Objective** | SLO | Mục tiêu chất lượng dịch vụ cụ thể, có thể đo lường được. (số liệu và yêu cầu cho “yêu cầu phi chức năng”) | Mẹo viết SLO nhanh (template) SLI (cách đo): Công thức/truy vấn cụ thể SLO (mục tiêu): Ngưỡng \+ percentile \+ cửa sổ thời gian Phạm vi/Loại trừ: kênh, region, mã lỗi, bảo trì có lịch Alert theo error budget: cảnh báo khi burn rate cao (vd. \>14,4× trong 1 giờ hoặc \>6× trong 6 giờ) để không “đốt” hết ngân sách lỗi. ví dụ: Web/App – Tính sẵn sàng SLI: Tỷ lệ request thành công \= 1 \- (5xx \+ timeout)/tổng request. SLO: 99,9% / 30 ngày → error budget \= 43,2 phút/tháng. Loại trừ: Bảo trì có lịch ≤ 30 phút/tháng; lỗi 4xx do client.  |
| **Service Level Indicator** | SLI | Chỉ số đo lường chất lượng dịch vụ. | vd : Crash-free (Mobile) Đo gì? % phiên không crash (SDK crash reporting) Công thức: 1 \- sessions\_crashed / sessions\_total  |
| **Personally Identifiable Information** | PII | Thông tin nhận dạng cá nhân. | Bất kỳ dữ liệu nào xác định trực tiếp một người, hoặc có thể xác định gián tiếp khi kết hợp với dữ liệu khác. Nhóm 1 – Định danh trực tiếp Họ tên đầy đủ \+ địa chỉ nhà/văn phòng Số CCCD/CMND, số hộ chiếu, số giấy phép lái xe Số điện thoại, email cá nhân (ví dụ: tennguyen@gmail.com) Ảnh khuôn mặt, vân tay, giọng nói (sinh trắc học) Số thẻ ngân hàng/thẻ tín dụng, số tài khoản, mã số thuế Chữ ký tay/điện tử, hình ảnh giấy tờ tùy thân Nhóm 2 – Định danh gián tiếp (quasi-identifiers) Tự thân có thể chưa “chỉ đích danh”, nhưng kết hợp lại sẽ xác định được cá nhân: Ngày sinh, giới tính, nơi ở cấp quận/huyện, biển số xe Địa chỉ IP, cookie ID, ID quảng cáo (IDFA/GAID), IMEI thiết bị Mã khách hàng nội bộ, lịch sử vị trí GPS, log truy cập, hành vi duyệt web Email dạng công ty (t.nguyen@company.com)—thường vẫn coi là PII Nhóm 3 – PII nhạy cảm (cần bảo vệ cao) Sức khỏe/bệnh án, thông tin tài chính/thu nhập, dữ liệu sinh trắc Niềm tin tôn giáo/chính trị, khuynh hướng tính dục Dữ liệu trẻ em, vị trí thời gian thực Cái gì không phải PII? Dữ liệu đã ẩn danh thực sự (không thể truy hồi về cá nhân) Dữ liệu tổng hợp theo nhóm (ví dụ: “35% người dùng ở HN dùng iOS”) |
| **Role-Based Access Control** | RBAC | Kiểm soát truy cập dựa trên vai trò. |  |
| **Mean Time To Acknowledge** | MTTA | Mean Time To Acknowledge (MTTA) là thời gian trung bình mà đội ngũ vận hành (hoặc hệ thống tự động) cần để ghi nhận một cảnh báo kể từ khi nó được phát ra. Nói đơn giản: MTTA đo xem bạn mất bao lâu để “phản ứng” lại một cảnh báo khi sự cố xảy ra. | Ví dụ: Lúc 14:00:00, hệ thống phát hiện CPU vượt 90%. Alert được gửi đến Slack kênh \#oncall-alerts. Lúc 14:03:30, kỹ sư trực ca nhấn “Acknowledge” trong PagerDuty. |
| **Data Subject Access Request** | DSAR | Một yêu cầu chính thức của cá nhân (data subject) — tức là người mà dữ liệu cá nhân của họ đang được tổ chức nắm giữ — đề nghị được biết, xem, hoặc nhận bản sao dữ liệu cá nhân của họ mà tổ chức đang lưu trữ và xử lý. |  |
| 95th percentile | p95 | Giá trị mà **95% quan sát ≤ giá trị đó** và **5% còn lại \> giá trị đó**.  | Bạn có **100** request, sắp xếp latency tăng dần. **p95** là **giá trị ở vị trí thứ 95** trong danh sách đã sắp. Nếu vị trí 95 \= **180 ms**, thì **95% request ≤ 180 ms**, còn 5% chậm hơn. |

---

### **3\. User Stories và Acceptance Criteria (AC)**

Các User Story được tinh chỉnh để bao gồm mệnh đề "So that..." và tập trung vào các giá trị nhỏ, có thể kiểm thử được.

| ID | User Story & Acceptance Criteria |
| :---- | :---- |
| **US-01** | **Là một Marketing Analyst, tôi muốn xem dashboard các chủ đề thịnh hành theo thời gian thực, để tôi có thể nhanh chóng nắm bắt cơ hội và lên ý tưởng nội dung phù hợp.**  **AC 1:** **Given** một thảo luận mới được đăng tải công khai, **When** hệ thống thu thập và xử lý, **Then** TTI end-to-end phải đạt p95 ≤ 10 phút.  **AC 2:** **Given** người dùng mở dashboard Xu hướng với bộ lọc 7 ngày, **When** dữ liệu được truy vấn, **Then** thời gian tải trang phải đạt p95 ≤ 1.5 giây (cache nóng) và p99 ≤ 3 giây.  **AC 3:** **Given** nhiều nguồn tin đăng lại cùng một nội dung, **Then** hệ thống phải chống trùng lặp (deduplication) với tỷ lệ chính xác ≥ 95%. |
| **US-02** | **Là một Marketing Analyst, tôi muốn xem biểu đồ so sánh Share of Voice (SoV) giữa thương hiệu của tôi và các đối thủ, để tôi có thể đánh giá nhanh vị thế của thương hiệu trên thị trường.** **AC 1:** **Given** một dự án đã được thiết lập với 3 đối thủ, **When** người dùng xem dashboard so sánh, **Then** các chỉ số SoV và Net Sentiment Score phải được tính toán và hiển thị cho từng đối thủ. **AC 2:** **Given** người dùng chọn so sánh hiệu suất theo kỳ (tuần/tháng), **Then** hệ thống phải hiển thị delta (thay đổi) của các chỉ số so với kỳ trước. |
| **US-03** | **Là một Marketing Analyst, tôi muốn xuất báo cáo hiệu suất tháng dưới dạng PDF chỉ bằng một cú nhấp chuột, để tôi có thể tiết kiệm thời gian và gửi cho khách hàng một cách chuyên nghiệp.** **AC 1:** **Given** người dùng đã kết nối một trang Facebook, **When** họ chọn "Xuất báo cáo tháng trước", **Then** hệ thống phải tạo ra một tệp PDF chứa các chỉ số tăng trưởng và top 5 bài đăng hiệu quả nhất trong vòng 60 giây. |
| **US-04** | **Là một Marketing Analyst, tôi muốn tìm kiếm KOC trong lĩnh vực "Làm đẹp" có từ 10k-50k người theo dõi, để tôi có thể tìm được đối tác phù hợp với ngân sách chiến dịch nhỏ.** **AC 1:** **Given** người dùng tìm kiếm KOC trong lĩnh vực "Làm đẹp", **When** kết quả hiển thị, **Then** dữ liệu về Tỷ lệ Tương tác (ER) và số lượng người theo dõi của mỗi KOC không được cũ hơn 7 ngày. **AC 2:** **Given** một KOC có tài khoản trên cả Facebook và TikTok, **Then** hệ thống phải nhận diện và hợp nhất thành một hồ sơ duy nhất. |
| **US-05** | **Là một Marketing Analyst, tôi muốn tạo một phân khúc người dùng "Nữ, 18-24, quan tâm đến mỹ phẩm", để tôi có thể phân tích sâu hơn về nhóm đối tượng mục tiêu chính của mình.** **AC 1:** **Given** người dùng tạo một phân khúc "Nữ, 18-24, quan tâm đến mỹ phẩm", **When** họ lưu lại, **Then** phân khúc này phải có thể được áp dụng như một bộ lọc trên toàn hệ thống. **AC 2:** **Given** một phân khúc được tạo, **Then** hệ thống phải hiển thị biểu đồ phân tích các chủ đề thảo luận và sentiment riêng của phân khúc đó. |
| **US-07** | **Là một Community Manager, tôi muốn nhận cảnh báo tức thời qua Zalo khi có thảo luận tiêu cực, để tôi có thể phản ứng và xử lý khủng hoảng ngay cả khi không ngồi trước máy tính.** **AC 1:** **Given** một quy tắc cảnh báo được thiết lập (ví dụ: sentiment ≤ \-0.6 VÀ số lượng thảo luận tăng ≥ 3σ trong 30 phút), **When** điều kiện được thỏa mãn, **Then** thời gian từ lúc phát hiện đến lúc gửi cảnh báo qua Zalo/Email phải đạt p95 ≤ 5 phút. **AC 2:** **Given** một cảnh báo được gửi đi, **Then** Community Manager phải có các hành động "Ghi nhận" (Acknowledge) hoặc "Bỏ qua" (Dismiss) và hệ thống phải ghi lại audit log cho các hành động này với tỷ lệ sai sót dương tính (false positive rate) được đánh dấu ≤ 10%. |
| **US-09** | **Là một Marketing Analyst, tôi muốn chia sẻ một dashboard chỉ đọc có mật khẩu cho khách hàng, để họ có thể tự theo dõi hiệu suất một cách minh bạch mà không làm ảnh hưởng đến cấu hình của tôi.** **AC 1:** **Given** một Client Viewer truy cập vào đường link dashboard được chia sẻ, **When** trang được tải, **Then** thời gian tải trang phải đạt p95 ≤ 2 giây và p99 ≤ 4 giây dưới tải 1000 người dùng đồng thời. **AC 2:** **Given** Client Viewer đang xem dashboard, **Then** họ chỉ có quyền xem dữ liệu và không thể thay đổi cấu hình của dashboard. |
| **US-10** | **Là một Marketing Analyst, tôi muốn cấu hình một sự kiện "Tết 2026" để đo lường mức độ tăng trưởng thảo luận, để tôi có thể đánh giá hiệu quả của chiến dịch mùa vụ so với ngày thường.** **AC 1:** **Given** người dùng cấu hình một sự kiện "Tết 2026" với khung thời gian và từ khóa cụ thể, **When** hệ thống xử lý, **Then** dashboard phải hiển thị chỉ số "Lift" của lượng thảo luận so với giai đoạn nền (baseline) trước sự kiện. |
| **US-11** | **Là một Marketing Analyst, tôi muốn nhập kết quả khảo sát và so sánh với dữ liệu thảo luận tự nhiên, để tôi có thể xác thực các insight và có một cái nhìn đa chiều về người tiêu dùng.AC 1:** **Given** người dùng tải lên một tệp CSV chứa kết quả khảo sát, **When** họ ánh xạ một câu hỏi khảo sát với một chủ đề thảo luận, **Then** dashboard phải hiển thị song song biểu đồ kết quả khảo sát và biểu đồ sentiment của chủ đề tương ứng. |
| **US-SYS-01** | **Là một System Administrator, tôi muốn có hệ thống phân quyền (RBAC) và Audit Log, để tôi có thể kiểm soát truy cập và truy vết các thay đổi nhằm đảm bảo an ninh và tuân thủ.** **AC 1:** **Given** một hành động thay đổi cấu hình (tạo dự án, sửa cảnh báo) được thực hiện, **Then** một bản ghi audit log tương ứng phải được tạo ra trong vòng ≤ 2 giây. **AC 2:** **Given** một người dùng có vai trò "Viewer", **When** họ cố gắng thực hiện một hành động ghi (POST/PATCH/DELETE) tới bất kỳ endpoint cấu hình nào, **Then** hệ thống phải trả về lỗi 403 Forbidden. |

---

### **4\. Đặc tả Yêu cầu (Requirements Specification)**

#### **4.1. Yêu cầu Chức năng (Functional Requirements)**

* **Quy ước chung cho API:**  
  * **Versioning:** Header x-api-version: 1\.  
  * **Idempotency:** Header x-idempotency-key cho các request POST, PATCH, DELETE.  
  * **Pagination:** Phân trang dựa trên con trỏ (limit, cursor).  
  * **Rate Limiting:** Mặc định: GET 120 req/phút/user; POST/PATCH/DELETE 60 req/phút/user. Lỗi 429 Too Many Requests phải có header Retry-After.  
  * **Error Model:** { "code": "...", "message": "...", "details": \[...\] }. Các mã lỗi chuẩn bao gồm: 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 412 Precondition Failed, 422 Unprocessable Entity, 429 Too Many Requests.

| ID | Giải pháp | Yêu cầu | API Contract (Ví dụ) |
| :---- | :---- | :---- | :---- |
| **FR1.2** | Trend Analysis | Lấy danh sách chủ đề thịnh hành. | GET /api/v1/trends/topics?period=7d\&platform=tiktok **200 OK:** { "items": \[{"topic", "volume", "delta", "confidence"}\] } |
| **FR1.3** | Trend Analysis | Lấy danh sách hashtag thịnh hành. | GET /api/v1/trends/hashtags?period=7d **200 OK:** { "items": \[{"hashtag", "volume", "er", "sample\_posts": \[id,...\]}\] } |
| **FR1.4** | Trend Analysis | Lấy bài đăng mẫu cho một chủ đề. | GET /api/v1/trends/samples?topic=...\&limit=20 **200 OK:** { "items": \[{"post\_id", "canonical\_url",...}\] } |
| **FR2.1** | Brand Insight | Tạo dự án theo dõi thương hiệu và đối thủ. | POST /api/v1/projects {name, brands:\[...\]} **201 Created:** { "project\_id": "..." } |
| **FR2.2** | Brand Insight | So sánh chỉ số các thương hiệu. | GET /api/v1/projects/{id}/compare?period=30d **200 OK:** { "sov": \[...\], "nss": \[...\], "delta": {...} } |
| **FR2.3** | Consumer Insight | Phân tích nhân khẩu học khán giả. | GET /api/v1/audience/insights?project\_id=... **200 OK:** { "demographics": {...}, "interests": \[...\] } |
| **FR3.1** | Campaign Insight | Quản lý chia sẻ dashboard. | POST /api/v1/dashboards/{id}/share {password?, expires\_at?} → **200 OK** {share\_url} DELETE /.../share → **204 No Content** **Roles:** Owner, Member. **Errors:** 403, 409\. |
| **FR3.2** | Campaign Insight | Tạo báo cáo PDF (bất đồng bộ). | POST /api/v1/reports → **202 Accepted** {report\_id} GET /api/v1/reports/{id} → {status, url} **Errors:** 401, 403, 422\. |
| **FR3.3** | Campaign Insight | Tạo dashboard tùy chỉnh. | POST /api/v1/dashboards {name, layout} **201 Created:** { "dashboard\_id": "..." } |
| **FR3.4** | Campaign Insight | So sánh hiệu quả các giai đoạn của chiến dịch. | \`GET /api/v1/campaigns/compare?project\_id={id}\&phase=pre |
| **FR4.1** | KOL Analysis | Tìm kiếm người ảnh hưởng. | GET /api/v1/kols/search?platform=...\&followers\_gte=...\&domain=... **200 OK:** { "items": \[...\] } |
| **FR4.2** | KOL Analysis | Lấy thông tin chi tiết của người ảnh hưởng. | GET /api/v1/kols/{id} **200 OK:** {..., "merged\_profiles": \[...\] } |
| **FR4.3** | KOL Analysis | Lấy thống kê cập nhật của KOL. | GET /api/v1/kols/{id}/stats?fresh\_within=7d **200 OK:** {er, followers,...} **206 Partial Content:** nếu dữ liệu cũ. |
| **FR5.1** | Crisis Management | Quản lý quy tắc cảnh báo. | POST /api/v1/alerts/rules {...} → **201** GET /api/v1/alerts/rules?project\_id=... → **200** PATCH /api/v1/alerts/rules/{id} {...} → **200** DELETE /api/v1/alerts/rules/{id} → **204** **Roles:** Owner, Member. |
| **FR5.2** | Crisis Management | Xử lý một cảnh báo. | POST /api/v1/alerts/{id}/actions **Body:** \`{ "action": "ack" |
| **FR7.1** | Occasions Analysis | Cấu hình một sự kiện mùa vụ. | POST /api/v1/occasions {name, window:{start,end}, keywords:\[...\]} **201 Created:** { "occasion\_id": "..." } |
| **FR7.2** | Occasions Analysis | Lấy dữ liệu nền. | GET /api/v1/occasions/{id}/baseline?lookback=28d **200 OK:** { "timeseries": \[...\] } |
| **FR7.3** | Occasions Analysis | Lấy chỉ số tăng trưởng của sự kiện. | GET /api/v1/occasions/{id}/lift **200 OK:** { "lift": {"volume\_pct", "engagement\_pct"}, "peaks": \[...\] } |
| **FR7.4** | Occasions Analysis | Xuất dữ liệu sự kiện. | \`POST /api/v1/occasions/{id}/export { "format": "pdf" |
| **FR8.1** | Online Survey | Nhập dữ liệu khảo sát từ CSV. | POST /api/v1/surveys/import (multipart) **202 Accepted:** { "survey\_id": "..." } **Errors:** 401, 403, 422\. |
| **FR8.2** | Online Survey | Ánh xạ câu hỏi khảo sát với chủ đề. | POST /api/v1/surveys/{id}/mapping {question\_id, topic} **204 No Content** **Errors:** 401, 403, 404, 409\. |
| **FR8.3** | Online Survey | So khớp kết quả khảo sát và topic. | GET /api/v1/surveys/{id}/compare?topic=... **200 OK:** { "survey": {...}, "social": {...} } |
| **FR8.4** | Online Survey | Lấy danh sách câu hỏi khảo sát. | GET /api/v1/surveys/{id}/questions **200 OK:** { "items": \[...\] } |
| **FR-SYS-1** | System/Platform | Quản lý thành viên và vai trò. | POST /api/v1/projects/{id}/members {user\_id, role} **Rule Matrix:** Viewer=chỉ GET; Member=GET/POST; Owner=full. **Roles:** Owner. |
| **FR-SYS-2** | System/Platform | Truy xuất Audit Log. | GET /api/v1/audit?resource=project\&id=... **200 OK:** { "items": \[...\] } **Roles:** Owner. |
| **FR-PRV-1** | Privacy | Yêu cầu xuất dữ liệu cá nhân (DSAR). | POST /api/v1/privacy/export **202 Accepted:** {job\_id} **Roles:** System Administrator. |
| **FR-PRV-2** | Privacy | Yêu cầu xóa dữ liệu cá nhân (DSAR). | POST /api/v1/privacy/delete **202 Accepted:** {job\_id} **Roles:** System Administrator. |

#### **4.2. Yêu cầu Phi chức năng (Non-Functional Requirements)**

| ID | Hạng mục | Yêu cầu (SLO/Chính sách) |
| :---- | :---- | :---- |
| **NFR-P1** | **Performance** | **Time to Insight (TTI):** p95 ≤ 10 phút. Phân bổ: Collector ≤5’, Normalize/ML ≤3’, Materialize/Cache ≤2’. |
| **NFR-P2** | **Performance** | **Query Latency (Dashboard):** p95 ≤ 1.5 giây, p99 ≤ 3 giây với 5,000 CCU (đo tại Edge). |
| **NFR-A1** | **Availability** | **Độ khả dụng hệ thống:** SLO ≥ 99.5%. |
| **NFR-A2** | **Availability** | **Disaster Recovery:** RPO ≤ 1 giờ; RTO ≤ 4 giờ. |
| **NFR-S1** | **Security** | **Xác thực & Phân quyền:** Sử dụng OAuth2/OIDC. Triển khai RBAC. |
| **NFR-S2** | **Security** | **Bảo mật dữ liệu:** Mã hóa at-rest (AES-26) và in-transit (TLS 1.2+). Tuân thủ OWASP ASVS Level 2\. |
| **NFR-S3** | **Security** | **Quản lý Bí mật:** Xoay vòng khóa (secret rotation) 90 ngày, sử dụng KMS. Không lưu token/key dạng plaintext. |
| **NFR-C1** | **Compliance/Privacy** | **Xử lý PII:** Dữ liệu PII phải được phân loại, che mờ (masking) khi hiển thị. |
| **NFR-C2** | **Compliance/Privacy** | **Lưu trữ dữ liệu:** Chính sách lưu trữ PII không quá 180 ngày. Audit log 180 ngày. |
| **NFR-C3** | **Compliance** | **Thu thập dữ liệu:** Tuân thủ robots.txt và ToS của các nền tảng nguồn. Ghi lại nhật ký đồng ý (consent log) cho các kết nối OAuth. |
| **NFR-C4** | **Compliance/Privacy** | **DSAR SLA:** Yêu cầu DSAR (export/delete) phải được hoàn tất trong vòng ≤ 30 ngày. |
| **NFR-O1** | **Observability** | **Metrics:** Theo dõi các SLI bắt buộc: ingest\_rate, dedupe\_rate, trend\_job\_lag, alert\_delivery\_latency, dashboard\_p95\_latency (đo tại application, sliding window 10 phút), alert\_fp\_rate (SLO ≤ 10%). |

---

### **5\. Kịch bản Sử dụng (Use Cases)**

| ID | Tên Use Case | Tác nhân |
| :---- | :---- | :---- |
| **UC-01** | Khám phá Xu hướng Nội dung | Marketing Analyst |
| **UC-02** | Thiết lập Theo dõi Đối thủ | Marketing Analyst |
| **UC-03** | Quản lý Cảnh báo Khủng hoảng | Community Manager |
| **UC-04** | Xuất Báo cáo Nhanh | Marketing Analyst |
| **UC-05** | Tìm kiếm Người ảnh hưởng | Marketing Analyst |
| **UC-06** | Cấu hình Phân tích Dịp đặc biệt | Marketing Analyst |
| **UC-07** | Tạo Phân khúc Người tiêu dùng | Marketing Analyst |
| **UC-08** | Tích hợp Dữ liệu Khảo sát | Marketing Analyst |
| **UC-09** | Kết nối Nguồn dữ liệu | Marketing Analyst |
| **UC-10** | Xử lý Yêu cầu Dữ liệu Cá nhân (DSAR) | System Administrator |

---

**Chi tiết Use Case UC-01: Khám phá Xu hướng Nội dung**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | Người dùng đã đăng nhập. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Trend Dashboard". 2\. Người dùng nhập từ khóa, chọn bộ lọc (thời gian, nền tảng). 3\. Hệ thống hiển thị các chủ đề, hashtag và bài đăng mẫu. 4\. Người dùng xem chi tiết một bài đăng và lưu vào bộ sưu tập. |
| **Luồng thay thế:** | **2a.** Người dùng chọn một ngành hàng có sẵn thay vì nhập từ khóa. |
| **Luồng ngoại lệ:** | **3e.** Không có dữ liệu phù hợp, hệ thống hiển thị trạng thái trống (204 No Content). |
| **Hậu điều kiện:** | Ý tưởng nội dung được lưu lại. |
| **NFR Hooks:** | TTI (NFR-P1), Query Latency (NFR-P2). |
| **UI Mapping:** | Màn hình: Trend Dashboard, Topic Detail. |

---

**Chi tiết Use Case UC-02: Thiết lập Theo dõi Đối thủ**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập và có quyền ≥ Member. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Project Setup" và chọn "Tạo mới". 2\. Người dùng nhập Tên dự án, thêm thương hiệu của mình và các đối thủ bằng từ khóa hoặc URL. 3\. Người dùng nhấn "Lưu". 4\. Hệ thống tạo dự án và bắt đầu job thu thập dữ liệu. 5\. Người dùng được chuyển đến màn hình "Compare Dashboard". |
| **Luồng thay thế:** | **2a.** Người dùng chọn "Nhập từ CSV" để thêm danh sách đối thủ hàng loạt. |
| **Luồng ngoại lệ:** | **2e.** Tên dự án bị trùng, hệ thống trả về lỗi 409 Conflict. **2e.** URL không hợp lệ, hệ thống trả về lỗi 422 Unprocessable Entity. |
| **Hậu điều kiện:** | 1\. Dự án ở trạng thái "Active". 2\. Job thu thập dữ liệu được khởi chạy. |
| **NFR Hooks:** | Query Latency (NFR-P2), TTI (NFR-P1). |
| **UI Mapping:** | Màn hình: Project Setup, Compare Dashboard. |

---

**Chi tiết Use Case UC-03: Quản lý Cảnh báo Khủng hoảng**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Community Manager |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập và có quyền ≥ Member. 2\. Đã có quy tắc cảnh báo được thiết lập. |
| **Luồng chính:** | 1\. Hệ thống phát hiện một sự kiện khớp với quy tắc cảnh báo. 2\. Hệ thống gửi thông báo đến kênh đã cấu hình (Email/Zalo). 3\. Người dùng nhận thông báo, nhấp vào link để xem chi tiết trong "Alert Inbox". 4\. Người dùng nhấn "Acknowledge" để xác nhận đã tiếp nhận. 5\. Sau khi xử lý, người dùng nhấn "Dismiss" và thêm ghi chú. |
| **Luồng thay thế:** | **5a.** Người dùng nhấn "Escalate" để chuyển cảnh báo cho người quản lý. |
| **Luồng ngoại lệ:** | **2e.** Kênh thông báo (Zalo) chưa được kết nối, hệ thống trả về lỗi 412 Precondition Failed và ghi log. **2e.** Vượt ngưỡng rate-limit của kênh thông báo, hệ thống trả về lỗi 429 và thực hiện backoff. |
| **Hậu điều kiện:** | Cảnh báo được xử lý và trạng thái được cập nhật. Hành động được ghi vào audit log. |
| **NFR Hooks:** | Alert Latency (p95 ≤ 5 phút), Audit Log (ghi ≤ 2 giây), alert\_fp\_rate SLO ≤ 10%. |
| **UI Mapping:** | Màn hình: Alert Rules, Alert Inbox, Alert Detail. |

---

**Chi tiết Use Case UC-04: Xuất Báo cáo Nhanh**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập. 2\. Đã có ít nhất một nguồn dữ liệu được kết nối. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Report Wizard". 2\. Người dùng chọn khoảng thời gian và mẫu báo cáo. 3\. Người dùng nhấn "Xem trước". 4\. Người dùng nhấn "Tạo báo cáo" (bất đồng bộ). 5\. Hệ thống xử lý và người dùng nhận được link tải xuống khi hoàn tất. |
| **Luồng thay thế:** | **2a.** Người dùng chọn "Lưu mẫu tùy chỉnh" để tái sử dụng cấu hình báo cáo. |
| **Luồng ngoại lệ:** | **3e.** Không có dữ liệu trong khoảng thời gian đã chọn, hệ thống trả về trạng thái trống (204 No Content). **4e.** Job render báo cáo bị lỗi, hệ thống trả về lỗi 503 Service Unavailable và cho phép thử lại. |
| **Hậu điều kiện:** | 1\. Báo cáo được tạo. 2\. Hành động được ghi vào audit log. |
| **NFR Hooks:** | Thời gian render p95 ≤ 60 giây, kích thước file ≤ 20MB. |
| **UI Mapping:** | Màn hình: Report Wizard, Report Preview. |

---

**Chi tiết Use Case UC-05: Tìm kiếm Người ảnh hưởng**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | Người dùng đã đăng nhập. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "KOL Search". 2\. Người dùng áp dụng các bộ lọc (lĩnh vực, nền tảng, lượng người theo dõi). 3\. Người dùng xem danh sách kết quả và mở một hồ sơ chi tiết. 4\. Người dùng nhấn "Thêm vào danh sách" để lưu hồ sơ vào một danh sách tiềm năng. |
| **Luồng thay thế:** | **2a.** Người dùng tìm kiếm trực tiếp theo tên hoặc handle của người ảnh hưởng. |
| **Luồng ngoại lệ:** | **3e.** Không có kết quả phù hợp, hệ thống gợi ý nới lỏng bộ lọc. |
| **Hậu điều kiện:** | Danh sách người ảnh hưởng tiềm năng được lưu lại. |
| **NFR Hooks:** | Freshness dữ liệu ≤ 7 ngày (FR4.3). |
| **UI Mapping:** | Màn hình: KOL Search, KOL Profile. |

---

**Chi tiết Use Case UC-06: Cấu hình Phân tích Dịp đặc biệt**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập và có quyền ≥ Member. 2\. Dự án đã có dữ liệu nền ít nhất 28 ngày. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Occasions Analysis" và chọn "Tạo mới". 2\. Người dùng nhập Tên sự kiện, chọn Khung thời gian và nhập các Từ khóa liên quan. 3\. Hệ thống hiển thị bản xem trước của chỉ số "Lift". 4\. Người dùng nhấn "Lưu". 5\. Hệ thống tạo một job tính toán định kỳ (15 phút/lần). |
| **Luồng thay thế:** | **3a.** Không đủ dữ liệu nền, hệ thống gợi ý mở rộng khung thời gian. |
| **Luồng ngoại lệ:** | **2e.** Tên sự kiện bị trùng, hệ thống trả về lỗi 409 Conflict. **5e.** Hàng đợi job bị đầy, hệ thống trả về lỗi 503 Service Unavailable và tự động thử lại. |
| **Hậu điều kiện:** | 1\. Sự kiện được tạo thành công. 2\. Dashboard của sự kiện hiển thị các widget về lift, peak days, top themes. |
| **NFR Hooks:** | Query Latency (NFR-P2), occasion\_job\_lag metric (NFR-O1). |
| **UI Mapping:** | Màn hình: Occasion Config, Occasion Insights. |

---

**Chi tiết Use Case UC-07: Tạo Phân khúc Người tiêu dùng**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập và có quyền ≥ Member. 2\. Dự án đã có dữ liệu ít nhất 7 ngày. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Segment Builder" và chọn "Tạo mới". 2\. Người dùng đặt tên và chọn các điều kiện (nhân khẩu học, chủ đề, sentiment). 3\. Hệ thống hiển thị số lượng người dùng ước tính và insight sơ bộ. 4\. Người dùng nhấn "Lưu". |
| **Luồng thay thế:** | **2a.** Người dùng nhập điều kiện từ tệp CSV. |
| **Luồng ngoại lệ:** | **2e.** Điều kiện xung đột, hệ thống trả về lỗi 422 Unprocessable Entity. **4e.** Tên phân khúc bị trùng, hệ thống trả về lỗi 409 Conflict. |
| **Hậu điều kiện:** | Phân khúc mới có thể được sử dụng như một bộ lọc chung trên toàn hệ thống. |
| **NFR Hooks:** | Query Latency (NFR-P2), Privacy (NFR-C1, NFR-C2). |
| **UI Mapping:** | Màn hình: Segment Builder, Segment Insights. |

---

**Chi tiết Use Case UC-08: Tích hợp Dữ liệu Khảo sát**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập. 2\. Có tệp CSV hợp lệ hoặc token kết nối từ nhà cung cấp khảo sát (Google Forms, Typeform). |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Survey Integration" và chọn "Nhập dữ liệu". 2\. Người dùng tải lên tệp CSV. 3\. Hệ thống xác thực schema và hiển thị giao diện ánh xạ. 4\. Người dùng ánh xạ một câu hỏi trong khảo sát với một chủ đề trong hệ thống. 5\. Người dùng xem dashboard so sánh kết quả. |
| **Luồng thay thế:** | **2a.** Người dùng kết nối qua webhook để kéo dữ liệu định kỳ. |
| **Luồng ngoại lệ:** | **2e.** Tệp CSV lỗi encoding hoặc thiếu cột, hệ thống trả về lỗi 422 Unprocessable Entity. **4e.** Ánh xạ bị trùng, hệ thống trả về lỗi 409 Conflict. |
| **Hậu điều kiện:** | 1\. Dữ liệu khảo sát được nhập và ánh xạ thành công. 2\. Hành động được ghi vào audit log. |
| **NFR Hooks:** | Thời gian parse ≤ 60 giây cho tệp 50MB; không lưu trữ PII thô từ khảo sát. |
| **UI Mapping:** | Màn hình: Survey Import & Mapping, Survey Compare. |

---

**Chi tiết Use Case UC-09: Kết nối Nguồn dữ liệu**

|  |  |
| :---- | :---- |
| **Tác nhân:** | Marketing Analyst |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập và có quyền ≥ Member. |
| **Luồng chính:** | 1\. Người dùng điều hướng đến màn hình "Data Source Connections" và chọn "Thêm nguồn mới". 2\. Người dùng chọn nền tảng (ví dụ: Facebook). 3\. Hệ thống chuyển hướng đến trang xác thực OAuth của nền tảng, hiển thị rõ các quyền (scopes) được yêu cầu. 4\. Người dùng đồng ý cấp quyền. 5\. Hệ thống nhận và lưu trữ an toàn (mã hóa) access token và refresh token. 6\. Hệ thống thực hiện một cuộc gọi API kiểm tra (health-check) để xác nhận kết nối thành công. 7\. Nguồn dữ liệu mới hiển thị trong danh sách với trạng thái "Connected". |
| **Luồng thay thế:** | **5a.** Refresh token thất bại, hệ thống cập nhật trạng thái nguồn dữ liệu thành "Re-authentication needed" và gửi thông báo cho người dùng. |
| **Luồng ngoại lệ:** | **4e.** Người dùng từ chối cấp quyền, hệ thống hiển thị thông báo "Kết nối thất bại do không được cấp quyền." **4e.** Nền tảng trả về lỗi rate-limit, hệ thống trả về lỗi 429 và thực hiện backoff. |
| **Hậu điều kiện:** | 1\. Nguồn dữ liệu được kết nối thành công. 2\. Hành động được ghi vào audit log, bao gồm cả các scope đã được đồng ý. |
| **NFR Hooks:** | Secret Rotation (NFR-S3), Audit Log (FR-SYS-2), Consent Logging (NFR-C3). |
| **UI Mapping:** | Màn hình: Data Source Connections. |

---

**Chi tiết Use Case UC-10: Xử lý Yêu cầu Dữ liệu Cá nhân (DSAR)**

|  |  |
| :---- | :---- |
| **Tác nhân:** | System Administrator |
| **Tiền điều kiện:** | 1\. Người dùng đã đăng nhập với vai trò Admin. 2\. Đã nhận được yêu cầu DSAR và xác minh danh tính của người yêu cầu. |
| **Luồng chính:** | 1\. Admin điều hướng đến màn hình "Privacy Management". 2\. Admin chọn "Tạo yêu cầu DSAR mới" và nhập thông tin định danh của người dùng. 3\. Admin chọn hành động "Export" hoặc "Delete". 4\. Hệ thống tạo một job bất đồng bộ để xử lý yêu cầu. 5\. Khi job hoàn tất, hệ thống gửi thông báo cho Admin (với link tải xuống bảo mật nếu là export, hoặc xác nhận đã xóa). |
| **Luồng thay thế:** | **3a.** Admin chọn "Hủy yêu cầu" nếu yêu cầu không hợp lệ. |
| **Luồng ngoại lệ:** | **2e.** Không tìm thấy người dùng, hệ thống trả về lỗi 404 Not Found. **3e.** Dữ liệu yêu cầu xóa đã vượt quá thời hạn lưu trữ, hệ thống trả về lỗi 410 Gone. |
| **Hậu điều kiện:** | 1\. Yêu cầu DSAR được hoàn tất trong vòng 30 ngày. 2\. Toàn bộ quá trình được ghi lại trong audit log. |
| **NFR Hooks:** | DSAR SLA (NFR-C4), link export hết hạn sau 7 ngày, dữ liệu export được mã hóa. |
| **UI Mapping:** | Màn hình: Privacy Management Dashboard. |

---

### **6\. Ma trận Truy vết Yêu cầu (Traceability Matrix)**

| Giải pháp | User Story (US) | Yêu cầu Chức năng (FR) | Yêu cầu Phi chức năng (NFR) | Use Case (UC) |
| :---- | :---- | :---- | :---- | :---- |
| **Trend Analysis** | US-01 | FR1.2 \- FR1.4 | NFR-P1, NFR-P2 | UC-01 |
| **Brand Insight** | US-02 | FR2.1, FR2.2 | NFR-P2, NFR-A1 | UC-02 |
| **Campaign Insight** | US-03, US-09 | FR3.1 \- FR3.4 | NFR-P2, NFR-S1 | UC-04 |
| **Crisis Management** | US-07 | FR5.1, FR5.2 | NFR-P1, NFR-O1 | UC-03 |
| **Consumer Insight** | US-05 | FR2.3 | NFR-C1, NFR-C2 | UC-07 |
| **KOL Analysis** | US-04 | FR4.1 \- FR4.3 | NFR-C1 | UC-05 |
| **Occasions Analysis** | US-10 | FR7.1 \- FR7.4 | NFR-P1, NFR-P2 | UC-06 |
| **Online Survey** | US-11 | FR8.1 \- FR8.4 | NFR-C1, NFR-C2 | UC-08 |
| **System/Platform** | US-SYS-01 | FR-SYS-1, FR-SYS-2, FR-PRV-1/2 | NFR-A1, NFR-S1, NFR-C2 | UC-09, UC-10 |

---

### **7\. Phụ lục**

#### **Phụ lục A: Sơ đồ Dữ liệu Chuẩn hóa (Normalized Data Schema)**

JSON

{  
  "post\_id": "string",  
  "canonical\_url": "string",  
  "source": "string",  
  "author\_id": "string",  
  "published\_at": "timestamp",  
  "fetched\_at": "timestamp",  
  "content": { "title": "string", "text": "string" },  
  "lang": "vi|en|...",  
  "metrics": { "like": 0, "share": 0, "comment": 0, "view": 0 },  
  "entities": \[{ "type": "brand|product|person", "text": "string", "confidence": 0.0 }\],  
  "sentiment": { "label": "pos|neu|neg", "score": \-1.0, "confidence": 0.0 },  
  "trend\_score": 0.0,  
  "topics": \["string"\],  
  "pii\_classification": "none|low|moderate|high",  
  "lineage": { "ingest\_source\_id": "string", "pipeline\_version": "string" }  
}

#### **Phụ lục B: Phạm vi Quyền OAuth & Nhật ký Đồng ý**

| Nền tảng | Phạm vi (Scope) | Mô tả |
| :---- | :---- | :---- |
| Facebook | pages\_read\_engagement | Đọc nội dung, bình luận, tương tác trên các trang đã được cấp quyền. |
|  | pages\_read\_user\_content | Đọc các bài đăng do người dùng tạo trên trang. |
|  | read\_insights | Đọc dữ liệu phân tích của trang. |
| TikTok | video.list | Đọc danh sách video công khai của tài khoản. |
|  | user.info.basic | Đọc thông tin cơ bản của tài khoản. |

**Nhật ký Đồng ý (Consent Log):** Mỗi khi người dùng hoàn tất quy trình OAuth (UC-09), một bản ghi sẽ được tạo với cấu trúc:

JSON

{  
  "user\_id": "string",  
  "provider": "facebook|tiktok|...",  
  "scopes\_granted": \["pages\_read\_engagement", "read\_insights", "..."\],  
  "consent\_at": "timestamp",  
  "provider\_user\_id": "string"  
}

#### **Phụ lục C: Chiến lược Kiểm thử và Đo lường**

* **Load Testing:** Sử dụng k6/JMeter để mô phỏng 5,000 CCU trên các dashboard chính và 1,000 CCU trên các dashboard chia sẻ để xác thực SLO về độ trễ (NFR-P2).  
* **Pipeline SLI Monitoring:** Mỗi giai đoạn của pipeline xử lý dữ liệu (Collector, Normalize, Materialize) sẽ xuất ra các metric Prometheus (collector\_lag, normalize\_latency, materialize\_latency). Thiết lập Alertmanager để cảnh báo nếu TTI\_p95 \> 10 phút trong 3 chu kỳ liên tiếp.  
* **Deduplication Evaluation:** Xây dựng một tập dữ liệu kiểm thử chứa các bài đăng trùng lặp từ nhiều nguồn. Chạy thuật toán dedupe và tính toán chỉ số F1-score để đảm bảo đạt ≥ 95%.  
* **Alerting E2E Test:** Triển khai các bài kiểm thử tổng hợp (synthetic tests) để tự động tạo ra các "gói" thảo luận tiêu cực đột biến mỗi giờ, sau đó đo lường alert\_delivery\_latency và MTTA từ đầu cuối.

