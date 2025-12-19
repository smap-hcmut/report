// Import counter dùng chung
#import "../counters.typ": table_counter

= CHƯƠNG 2: CÁC HỆ THỐNG LIÊN QUAN

== 2.1 Tổng quan thị trường
Thị trường Social Listening tại Việt Nam hiện nay có mức độ cạnh tranh cao, với sự phân chia rõ rệt giữa hai mô hình hoạt động chính: các đơn vị tư vấn chuyên sâu cung cấp báo cáo nghiên cứu (tiêu biểu như Buzzmetrics) và các nền tảng công nghệ tự phục vụ (SaaS) (như SocialHeat của YouNet Media). Trong bối cảnh hiện tại, lợi thế cạnh tranh không còn chỉ nằm ở khả năng thu thập dữ liệu thô, mà đã chuyển dịch sang độ tinh vi của các công nghệ AI được tích hợp, bao gồm:

- **Xử lý ngôn ngữ tự nhiên (NLP)**: Trọng tâm là khả năng phân tích cảm xúc theo khía cạnh (Aspect-Based Sentiment Analysis - ABSA) một cách chính xác cho tiếng Việt, ngôn ngữ vốn có độ phức tạp cao về ngữ nghĩa và ngữ cảnh.
- **Thị giác máy tính (Computer Vision)**: Công nghệ Lắng nghe bằng hình ảnh (Visual Listening) cho phép nhận dạng logo, vật thể và bối cảnh xuất hiện trong hệ sinh thái đa phương tiện. Đây được xem là tính năng cao cấp giúp thu thập các đề cập thương hiệu bị bỏ sót nếu chỉ dựa vào phân tích văn bản thuần túy.
- **Phát hiện bất thường (Anomaly Detection)**: Khả năng tự động phát hiện các đợt thảo luận tăng đột biến (spike detection) là giá trị cốt lõi hỗ trợ doanh nghiệp trong việc quản trị và xử lý khủng hoảng truyền thông.


== 2.2 Các hệ thống, dịch vụ tại Việt Nam

=== 2.2.1 YouNet Group (Buzzmetrics & YouNet Media)
Là đơn vị thống trị thị trường Việt Nam, YouNet Group vận hành một chiến lược hai gọng kìm thông minh. Họ tách biệt mô hình kinh doanh thành hai thương hiệu riêng biệt: Buzzmetrics, một đơn vị tư vấn chuyên sâu, và YouNet Media, nhà cung cấp nền tảng công nghệ SaaS SocialHeat.

==== a) Buzzmetrics
Buzzmetrics định vị mình là một công ty nghiên cứu thị trường tiên phong, áp dụng các phương pháp luận nghiên cứu vào dữ liệu mạng xã hội và thương mại điện tử từ năm 2013. Thay vì bản phần mềm, họ cung cấp các báo cáo phân tích chuyên sâu và tư vấn chiến lược cho các thương hiệu lớn.

Ưu điểm:
- Chất lượng insight vượt trội: Cung cấp các báo cáo phân tích sâu sắc bởi đội ngũ chuyên gia thay vì chỉ là dữ liệu thô.
- Phương pháp luận độc quyền: Chỉ số BSI (Buzzmetrics Social Index) đã trở thành một tiêu chuẩn ngành để đo lường độ lan truyền và hiệu quả chiến dịch.
- Độ tin cậy dữ liệu cao: Tiên phong áp dụng bộ lọc "Qualified Users" để loại bỏ các tương tác không chân thực (seeding, bots), đảm bảo tính chính xác của insight.

Nhược điểm:
- Mô hình dịch vụ: Khách hàng không có quyền truy cập trực tiếp vào nền tảng để tự khai thác dữ liệu và xử lý.
- Chi phí cao: Mô hình tư vấn chuyên sâu thường đi kèm với chi phí cao hơn so với các nền tảng SaaS tự phục vụ.
- Phụ thuộc vào đội ngũ chuyên gia: Chất lượng và tốc độ của báo cáo phụ thuộc vào năng lực và lịch làm việc của đội ngũ phân tích.

==== b) YouNet Media (Social Heat)
YouNet Media cung cấp SocialHeat, nền tảng Social Listening dạng SaaS hàng đầu tại Việt Nam, cho phép các doanh nghiệp tự theo dõi và phân tích dữ liệu mạng xã hội theo thời gian thực.

Ưu điểm:
- Nền tảng SaaS mạnh mẽ: Cung cấp công cụ tự phục vụ hàng đầu tại Việt Nam, cho phép khách hàng tự theo dõi và phân tích dữ liệu thời gian thực.
- Độ phủ dữ liệu lớn: Tuyên bố sở hữu nguồn dữ liệu mạng xã hội lớn nhất Việt Nam, bao gồm cả các nền tảng mới nổi như TikTok và Thread.
- Giao diện thân thiện: Nền tảng được quảng bá là dễ sử dụng, không yêu cầu đào tạo chuyên sâu, với dashboard có khả năng tùy chỉnh cao.

Nhược điểm:
- Khả năng phân tích AI: Mặc dù có phân tích cảm xúc, các tính năng AI sâu hơn như ABSA hay phân cụm chủ đề tự động không được quảng bá rõ ràng như các đối thủ quốc tế.
// - *Thiếu tính minh bạch về API*: Khả năng tích hợp với các hệ thống khác (CRM, BI) thông qua API không được làm nổi bật.

=== 2.2.2 Reputa
Reputa là một hệ thống giám sát và phân tích thông tin trên môi trường mạng, được hậu thuẫn bởi công nghệ của Viettel AI. Nền tảng này tập trung vào việc quản lý danh tiếng và phát hiện rủi ro cho các doanh nghiệp và cơ quan nhà nước.

Ưu điểm:
- Hậu thuẫn từ tập đoàn lớn: Có liên kết chặt chẽ với Viettel AI, do đó đảm bảo tính bảo mật và độ tin cậy cao.
- Tập trung vào quản lý danh tiếng: Phù hợp cho các tập đoàn lớn và cơ quan chính phủ có nhu cầu giám sát rủi ro và khủng hoảng truyền thông.
- Giá cả cạnh tranh: Cung cấp các gói dịch vụ theo tháng với mức giá rõ ràng, dễ tiếp cận cho nhiều quy mô doanh nghiệp.

Nhược điểm:
- Thông tin kỹ thuật hạn chế: Ít thông tin công khai về các công nghệ AI lõi (như ABSA, phát hiện bất thường) so với các đối thủ khác.
- Thị trường ngách: Việc tập trung vào khách hàng doanh nghiệp lớn và chính phủ có thể khiến sản phẩm kém linh hoạt cho các doanh nghiệp nhỏ và vừa hoặc các agency.

=== 2.2.3 Kompa
Kompa tự định vị là một công ty công nghệ dữ liệu có nguồn gốc từ thung lũng Silicon. Công ty nhấn mạnh vào năng lực Big Data và xử lý ngôn ngữ tự nhiên (NLP) để cung cấp các giải pháp vượt ra ngoài phạm vi Social Listening truyền thống.

Ưu điểm:
- Định vị công nghệ dữ liệu: Nhấn mạnh vào năng lực Big Data và NLP, cho thấy tham vọng cung cấp các giải pháp dữ liệu đa ngành.
- Cảnh báo nhanh: Cam kết gửi cảnh báo tự động về thông tin tiêu cực qua email/SMS trong vòng 15-30 phút.
- Gói dịch vụ linh hoạt: Cung cấp các gói từ cơ bản đến cao cấp với mức giá khởi điểm cạnh tranh, bắt đầu từ 10 triệu VNĐ/tháng.


=== 2.2.4 Commsights / Andi
Commsights là một dịch vụ thông tin tình báo truyền thông (media intelligence) với phạm vi bao phủ rộng, bao gồm cả các phương tiện truyền thống như báo in, TV, radio bên cạnh các nguồn kỹ thuật số.

Ưu điểm:
- Độ phủ đa kênh toàn diện: Giám sát cả các kênh truyền thông truyền thống, cung cấp cái nhìn 360 độ về sự hiện diện của thương hiệu.
- Kinh nghiệm lâu năm: Là một trong những đơn vị có kinh nghiệm lâu đời trong lĩnh vực theo dõi media tại Việt Nam.
- Tập trung vào phân tích định tính: Cung cấp các báo cáo phân tích chuyên sâu, tùy chỉnh theo nhu cầu của khách hàng.

Nhược điểm:
- Thiên về dịch vụ: Mô hình hoạt động giống một agency phân tích hơn là một nền tảng công nghệ tự phục vụ.
- Công nghệ lõi không rõ ràng: Ít thông tin về nền tảng công nghệ AI tự động, có thể phụ thuộc nhiều vào phân tích thủ công.

== 2.3 Các hệ thống, dịch vụ toàn cầu

=== 2.3.1 Talkwalker
Talkwalker là một nền tảng Social Listening và consumer intelligence toàn diện, được thiết kế cho các doanh nghiệp lớn cần phân tích sâu về thị trường, đối thủ và người tiêu dùng trên quy mô toàn cầu.

Ưu điểm:
- Độ phủ dữ liệu toàn cầu: Bao phủ hơn 30 mạng xã hội, 150 triệu trang web, và hỗ trợ 187 ngôn ngữ.
- Năng lực AI vượt trội: Công cụ Blue Silk™ AI cung cấp các tính năng hàng đầu như phân cụm hội thoại, phân tích cảm xúc theo khía cạnh, và dự báo xu hướng.
- Nền tảng toàn diện: Cung cấp một bộ giải pháp hoàn chỉnh từ quản lý khủng hoảng, phân tích xu hướng đến lắng nghe hình ảnh và âm thanh.

Nhược điểm:
- Chi phí rất cao: Là một giải pháp dành cho doanh nghiệp lớn với mức giá khởi điểm từ \$9,600/năm và có thể lên tới \$100,000.
- Độ phức tạp: Nền tảng tích hợp nhiều tính năng phức tạp, đòi hỏi thời gian để làm chủ.
- Xử lý Tiếng Việt: Mặc dù hỗ trợ đa ngôn ngữ, khả năng xử lý các sắc thái và tiếng lóng đặc thù của tiếng Việt có thể không bằng các công cụ địa phương.

=== 2.3.2 YouScan
YouScan là một nền tảng Social Listening được hỗ trợ bởi AI, nổi bật với khả năng phân tích hình ảnh và giao diện người dùng thân thiện. Nền tảng này giúp các thương hiệu hiểu rõ hơn về người tiêu dùng và quản lý danh tiếng.

Ưu điểm:
- Dẫn đầu về Visual Listening: Khả năng nhận dạng logo, đối tượng, bối cảnh trong hình ảnh và video là tốt nhất thị trường, giúp thu thập thêm tới 80% đề cập.
- Đổi mới với AI: Insights Copilot cho phép người dùng "trò chuyện với dữ liệu", giúp việc phân tích trở nên trực quan và dễ dàng hơn.
- Giao diện và trải nghiệm người dùng: Được đánh giá cao về giao diện thân thiện, dễ sử dụng và khả năng trực quan hóa dữ liệu xuất sắc.

Nhược điểm:
- Giá cả: Mặc dù có gói khởi điểm hợp lý (từ \$299/tháng), các tính năng cao cấp như Visual Insights là các add-on có thể làm tăng chi phí đáng kể.
- Hạn chế về API: Một số đánh giá đề cập đến các giới hạn về API, có thể ảnh hưởng đến khả năng tích hợp sâu.

=== 2.3.3 Meltwater
Meltwater là một nền tảng media intelligence và Social Listening toàn diện, được thiết kế chuyên biệt cho các đội ngũ PR và truyền thông doanh nghiệp. Nền tảng tập trung vào việc quản lý khủng hoảng và đo lường hiệu quả truyền thông.

Ưu điểm:
- Chuyên gia quản lý khủng hoảng: Tính năng "Spike Detection" là một công cụ mạnh mẽ và được định nghĩa rõ ràng để phát hiện các cuộc thảo luận tăng đột biến.
- Bộ giải pháp doanh nghiệp: Cung cấp một bộ công cụ media intelligence đẩy đủ, bao gồm cả giám sát tin tức truyền thống và mạng xã hội.
- Hỗ trợ khách hàng tốt: Được đánh giá cao về đội ngũ hỗ trợ khách hàng chuyên nghiệp và sẵn sàng giúp đỡ.

Nhược điểm:
- Chi phí rất cao và thiếu minh bạch: Giá cả không công khai, yêu cầu hợp đồng hàng năm và được biết đến là rất đắt, với chi phí trung bình từ \$15,000 đến \$20,000 mỗi năm.
- Trải nghiệm người dùng trái chiều: Có nhiều phàn nàn về trải nghiệm sử dụng nền tảng và các chiến thuật bán hàng.
- Phân tích AI cơ bản: Các tính năng như phân cụm chủ đề chủ yếu dựa vào word cloud, kém tinh vi hơn so với Talkwalker hay YouScan.


== 2.4 Ma trận so sánh tính năng
#context (align(center)[_Bảng #table_counter.display(): Ma trận so sánh tính năng các hệ thống_])
#table_counter.step()
// Đặt kích thước phông chữ cơ bản cho bảng
#text(size: 9pt)[
  // Cài đặt không căn đều lề phải
  #set par(justify: false)
  
  // Định nghĩa bảng
  #table(
    // Tỷ lệ các cột
    columns: (1.6fr, 1.1fr, 1.1fr, 1fr, 1fr, 1.1fr, 1fr, 1fr),
    // Đường viền mỏng
    stroke: 0.5pt,
    // Căn lề: Cột 1 (trái), các cột còn lại (giữa)
    align: (left, center, center, center, center, center, center, center),

    // HÀM TÔ MÀU CHO CÁC HÀNG TIÊU ĐỀ MỤC
    fill: (col, row) => {
      // Typst đếm hàng từ 0 (hàng tiêu đề chính).
      // Danh sách các hàng là tiêu đề mục cần tô xám.
      let grey-rows = (1, 7, 13, 17, 21, 24, 26, 30, 34, 38)
      if row in grey-rows {
        luma(230) // Màu xám nhạt
      } else {
        white // Nền trắng
      }
    },

    // --- HÀNG TIÊU ĐỀ CHÍNH ---
    [*Tiêu chí*], [*YouNet Media*], [*Buzzmetrics*], [*Reputa*], [*Kompa*], [*Talkwalker*], [*YouScan*], [*Meltwater*],

    // --- MỤC 1: PHẠM VI & NGUỒN DỮ LIỆU ---
    [1. Phạm vi & Nguồn Dữ liệu], [], [], [], [], [], [], [],
    
    [Phạm vi thị trường], [Tập trung VN], [Tập trung VN], [Tập trung VN], [Tập trung VN], [Toàn cầu], [Toàn cầu], [Toàn cầu],
    [Nguồn (MXH, Báo, Diễn đàn)], [Rộng (VN)], [Rộng (VN)], [Rộng (VN)], [Rộng (VN)], [Rất rộng], [Rất rộng], [Rất rộng],
    [Nguồn (TMĐT VN)], [Mạnh (TikTok)], [✓], [✓], [✓], [X], [X], [X],
    [Nguồn (TV, Radio, In)], [X], [X], [X], [X], [✓], [Audio/Video], [✓ (Podcast)],
    [Dữ liệu thời gian thực], [Rất mạnh], [X (Dịch vụ)], [✓], [✓], [Rất mạnh], [✓], [✓],

    // --- MỤC 2: NĂNG LỰC PHÂN TÍCH & AI ---
    [2. Năng lực Phân tích & AI], [], [], [], [], [], [], [],
    
    [Sentiment & Emotion], [✓], [✓ (Chuyên sâu)], [✓], [✓], [✓ (AI)], [✓ (AI)], [✓ (AI)],
    [Phân cụm chủ đề & Xu hướng], [✓], [✓ (Chuyên sâu)], [✓], [✓], [✓ (AI)], [✓ (AI)], [✓ (AI)],
    [Phân tích hình ảnh/video], [X], [X], [X], [X], [✓ (AI)], [✓ (AI)], [✓ (AI)],
    [So sánh đối thủ], [✓], [✓ (Chuyên sâu)], [✓], [✓], [✓], [✓], [✓],
    [Phân tích Influencer], [✓], [✓], [✓], [✓], [✓], [✓], [✓],

    // --- MỤC 3: BÁO CÁO & TRỰC QUAN HÓA ---
    [3. Báo cáo & Trực quan hóa], [], [], [], [], [], [], [],
    
    [Dashboard tùy chỉnh], [Rất linh hoạt], [X (Dịch vụ)], [✓], [✓], [Rất linh hoạt], [Rất linh hoạt], [Đa dạng],
    [Báo cáo tự động / Xuất file], [✓ (PPTX, Excel)], [X (Dịch vụ)], [✓ (PDF, Excel)], [✓ (PDF, Excel)], [Đa dạng], [Đa dạng], [Đa dạng],
    [Biểu đồ & Word Cloud], [Đa dạng], [Tùy chỉnh (Dịch vụ)], [Cơ bản], [Cơ bản], [Nâng cao], [Nâng cao], [Nâng cao],

    // --- MỤC 4: TÍCH HỢP & TỰ ĐỘNG HÓA ---
    [4. Tích hợp & Tự động hóa], [], [], [], [], [], [], [],
    
    [API / Tích hợp BI], [Hạn chế], [X], [?], [✓ (Tài chính)], [Mạnh], [Mạnh], [Mạnh],
    [Cảnh báo tự động], [✓ (Crisis)], [X (Dịch vụ)], [✓ (Email)], [✓ (Email/SMS)], [✓ (Spike)], [✓ (Tùy chỉnh)], [✓ (Spike)],
    [Quản lý tương tác (Reply)], [X], [X], [X], [X], [X], [X], [X],

    // --- MỤC 5: TRẢI NGHIỆM NGƯỜI DÙNG ---
    [5. Trải nghiệm Người dùng], [], [], [], [], [], [], [],
    
    [Giao diện dễ dùng], [✓], [N/A (Dịch vụ)], [?], [?], [✓✓], [✓✓], [✓],
    [Ngôn ngữ hỗ trợ], [Việt, Anh], [Việt, Anh], [Việt], [Việt, Anh], [Đa ngôn ngữ], [Đa ngôn ngữ], [Đa ngôn ngữ],

    // --- MỤC 6: BẢO MẬT & TUÂN THỦ ---
    [6. Bảo mật & Tuân thủ], [], [], [], [], [], [], [],
    
    [Tuân thủ GDPR / PDPA], [?], [?], [?], [✓], [✓], [✓], [✓],
    
    // --- MỤC 7: CHI PHÍ & GÓI DỊCH VỤ ---
    [7. Chi phí & Gói dịch vụ], [], [], [], [], [], [], [],
    
    [Mô hình tính phí], [Hybrid], [Dịch vụ], [Theo gói], [Theo gói], [Theo gói], [Theo gói], [Theo gói],
    [Giá khởi điểm (Ước tính)\*], [Theo gói], [Theo dự án], [~5 triệu/tháng], [~10 triệu/tháng], [~\$9,600/năm], [~\$299/tháng], [~\$15,000/năm],
    [Dùng thử / Demo], [Demo], [X], [X], [X], [Demo], [Demo/Trial], [Demo],

    // --- MỤC 8: HỖ TRỢ KHÁCH HÀNG ---
    [8. Hỗ trợ Khách hàng], [], [], [], [], [], [], [],
    
    [Hình thức hỗ trợ], [Chuyên viên], [Chuyên gia], [Email/Tel], [Email/Tel], [Chuyên viên], [Chuyên viên], [Chuyên viên],
    [Tài liệu & Training], [✓], [✓], [?], [✓], [✓], [✓], [✓],
    [Cộng đồng người dùng], [X], [X], [X], [X], [✓], [✓], [X],
  )
]
#text(size: 9pt, style: "italic")[
  *Chú thích:* (✓): Có tính năng; (✓✓): Tính năng mạnh/nổi bật; (X): Không có hoặc không hỗ trợ; (?): Không có thông tin công khai; (N/A): Không áp dụng.
  \ (\*): Mức giá ước tính dựa trên thông tin thị trường và báo giá tham khảo, có thể thay đổi tùy thời điểm.
]