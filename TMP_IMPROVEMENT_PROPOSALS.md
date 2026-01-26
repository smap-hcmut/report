# Đề xuất Cải tiến SMAP

> Dựa trên feedback từ thực tế marketing agency - Ngày 26/01/2026

---

## 📋 Tổng quan

Sau khi trao đổi với các chuyên gia marketing, chúng tôi nhận thấy cần điều chỉnh một số use cases và tính năng của SMAP để phù hợp hơn với thực tế công việc của marketing agency.

---

## 🎯 Vấn đề 1: Hiểu lầm về Social Listening

### Hiện tại (Sai)

**UC-08: Phát hiện Khủng hoảng Sớm**

- Hệ thống tự động phát hiện khủng hoảng trước khi xảy ra
- Cron job chạy mỗi 3 giờ để quét dữ liệu mới
- Gửi cảnh báo khi phát hiện nội dung nguy hiểm
- Mục tiêu: Phát hiện sớm 6-12 giờ

### Thực tế từ Marketing Agency

**Social Listening được dùng KHI khủng hoảng ĐÃ xảy ra**

Khi nào cần Social Listening:

- ✅ Công ty **đã** phát hiện sản phẩm bị complain nhiều
- ✅ Khủng hoảng **đã** xảy ra, cần tìm nguyên nhân
- ✅ Cần biết khủng hoảng ở **khía cạnh nào** (SERVICE? PERFORMANCE? PRICE?)
- ❌ KHÔNG phải để phát hiện sớm khủng hoảng

### Tại sao hiểu lầm này xảy ra?

1. **Góc nhìn kỹ thuật**: Nghĩ rằng AI có thể dự đoán khủng hoảng
2. **Thiếu hiểu biết thực tế**: Không biết workflow thực tế của marketing team
3. **Overestimate AI**: Tin rằng AI có thể phát hiện mọi thứ tự động

### Đề xuất thay đổi

**Đổi tên: UC-08 → "Phân tích Khủng hoảng"**

**Mục đích mới:**

- Phân tích khủng hoảng **đã xảy ra**
- Xác định **khía cạnh nào** đang bị chê
- Tìm **nguyên nhân** cụ thể
- Đề xuất **hành động** xử lý

**Workflow mới:**

```
1. Công ty phát hiện có vấn đề (qua báo cáo, feedback, media)
2. Team Media kích hoạt phân tích khủng hoảng trong SMAP
3. SMAP thu thập và phân tích dữ liệu
4. Output: Khía cạnh nào bị chê + Mức độ nghiêm trọng + Hành động đề xuất
```

**Ví dụ cụ thể:**

```
Tình huống: VinFast nhận nhiều complaint về bảo hành

Trước đây (Sai):
- SMAP tự động phát hiện và gửi cảnh báo
- Team Media nhận alert từ hệ thống

Thực tế (Đúng):
- VinFast đã biết có vấn đề (qua hotline, social media, báo chí)
- Team Media chạy phân tích trong SMAP với từ khóa:
  + "VinFast bảo hành"
  + "VinFast hỏng"
  + "VinFast dịch vụ"
- SMAP phân tích và cho biết:
  + SERVICE - Bảo hành: 40% mentions (nghiêm trọng nhất)
  + PERFORMANCE - Lỗi phần mềm: 27% mentions
  + PERFORMANCE - Pin: 20% mentions
- Team Media biết cần ưu tiên xử lý SERVICE trước
```

---

## 🎯 Vấn đề 2: Input - Ai nhập từ khóa?

### Hiện tại (Chưa rõ)

- Hệ thống có AI tự động phát hiện
- User chỉ cần nhập tên thương hiệu
- SMAP tự động tìm từ khóa liên quan

### Thực tế từ Marketing Agency

**Team Media luôn có sẵn list từ khóa**

Trong một agency marketing:

- Có **Team Media** chuyên theo dõi mạng xã hội
- Team này có **kinh nghiệm** và **hiểu biết** về ngành
- Họ luôn có **list từ khóa** để theo dõi, bao gồm:
  - Từ khóa về sản phẩm/thương hiệu
  - Từ khóa gây negative (dựa trên kinh nghiệm)
  - Từ khóa về đối thủ
  - Từ khóa về trend

### Đề xuất thay đổi

**Input hoàn toàn từ User (Team Media)**

**Cấu hình phân tích khủng hoảng:**

```
Sản phẩm: VinFast VF8

Từ khóa negative (Team Media tự nhập):
- "VinFast lừa đảo"
- "VinFast chất lượng kém"
- "VinFast hỏng liên tục"
- "VinFast bảo hành tệ"
- "tẩy chay VinFast"
- "VF8 hỏng pin"
- "VF8 lỗi phần mềm"
- "VF8 màn hình treo"
- ... (Team tự thêm dựa trên kinh nghiệm)

Nguồn ưu tiên (Team Media tự chọn):
- Pages review xe: "Xe Hay", "Ô tô 360", "Car Review VN"
- Groups: "Hội VinFast Việt Nam", "Cộng đồng xe điện"
- KOLs: Các reviewer có >50K followers
```

**Vai trò của SMAP:**

- ❌ KHÔNG tự động tìm từ khóa
- ❌ KHÔNG tự động phát hiện khủng hoảng
- ✅ Nhận input từ Team Media
- ✅ Thu thập và phân tích dữ liệu
- ✅ Gợi ý ngưỡng (threshold) dựa trên best practices

**Lý do:**

1. **Tin tưởng vào chuyên gia**: Team Media hiểu ngành hơn AI
2. **Tránh nhiễu**: AI không thể phân biệt context
3. **Linh hoạt**: Mỗi ngành, mỗi sản phẩm có từ khóa khác nhau

---

## 🎯 Vấn đề 3: Output - Cần gì từ phân tích?

### Hiện tại (Chưa đủ)

- Sentiment score: 60% Tích cực, 30% Tiêu cực, 10% Trung lập
- Impact score: 85/100
- Risk level: CRITICAL
- Số liệu engagement: views, likes, comments, shares

### Thực tế từ Marketing Agency

**Không cần số liệu %, cần ý nghĩa cụ thể**

Team Media cần biết:

- ❌ KHÔNG cần: "60% tiêu cực"
- ✅ CẦN: "SERVICE - Bảo hành đang bị chê nhiều nhất"
- ❌ KHÔNG cần: "Impact score 85/100"
- ✅ CẦN: "Vấn đề nghiêm trọng, cần xử lý ngay"

### Đề xuất thay đổi

**Output tập trung vào Khía cạnh (Aspect)**

**Format mới:**

```
Phân tích Khủng hoảng: VinFast VF8
Thời gian: 01/01/2025 - 15/01/2025

=== TỔNG QUAN ===
Tổng bài viết negative: 450 bài
Tổng engagement: 5.2M
Số người bị ảnh hưởng: ~500K

=== PHÂN TÍCH THEO KHÍA CẠNH ===

1. SERVICE - Bảo hành (180 bài - 40%)
   Mức độ: ⚠️⚠️⚠️ NGHIÊM TRỌNG

   Vấn đề cụ thể:
   - "Bảo hành lâu, chờ 2-3 tháng" (80 bài)
   - "Phụ tùng không có, phải đợi" (50 bài)
   - "Nhân viên thiếu chuyên nghiệp" (30 bài)
   - "Không giải quyết được vấn đề" (20 bài)

   Nguồn chính:
   - Page "Xe Hay": 15 bài, 1.8M engagement
   - KOL Reviewer ABC: 5 bài, 900K engagement
   - Group "Hội VinFast": 80 bài, 600K engagement

   → HÀNH ĐỘNG: Ưu tiên xử lý NGAY
     1. Rà soát quy trình bảo hành
     2. Tăng tốc độ: 2-3 tháng → 2-3 tuần
     3. Tăng stock phụ tùng
     4. Training nhân viên
     5. Liên hệ các case đang pending

2. PERFORMANCE - Lỗi phần mềm (120 bài - 27%)
   Mức độ: ⚠️⚠️ CẦN CHÚ Ý

   Vấn đề cụ thể:
   - "Màn hình treo, phải reset" (60 bài)
   - "Lỗi cảm biến, báo sai" (30 bài)
   - "Phần mềm lag, chậm" (20 bài)
   - "Update OTA gây lỗi mới" (10 bài)

   → HÀNH ĐỘNG: Update phần mềm trong 1 tuần
     1. Release hotfix
     2. Thông báo lịch update
     3. Hướng dẫn workaround
     4. Mở hotline 24/7

3. PERFORMANCE - Pin (90 bài - 20%)
   Mức độ: ⚠️ THẤP

   Vấn đề cụ thể:
   - "Pin yếu hơn quảng cáo" (50 bài)
   - "Sạc chậm" (25 bài)
   - "Tụt pin nhanh khi trời lạnh" (15 bài)

   → HÀNH ĐỘNG: Giải thích và giáo dục
     1. Video giải thích cách tính quãng đường
     2. Tips sử dụng để tối ưu pin
     3. So sánh với xe điện khác
```

**Điểm khác biệt:**

- ✅ Rõ ràng: Khía cạnh nào bị chê
- ✅ Cụ thể: Vấn đề chi tiết là gì
- ✅ Ưu tiên: Xử lý cái nào trước
- ✅ Hành động: Làm gì cụ thể

---

## 🎯 Vấn đề 4: Lọc theo Nguồn - Tránh nhiễu

### Hiện tại (Có vấn đề)

- Crawl tất cả bài viết có chứa từ khóa
- Không phân biệt nguồn
- Dễ bị nhiễu từ tin tức không liên quan

### Thực tế từ Marketing Agency

**Vấn đề với crawl theo từ khóa thuần túy:**

**Ví dụ 1: Tin tức không liên quan**

```
Từ khóa: "Toyota"
Kết quả crawl:
- "Ông A lái Toyota gây tai nạn" ❌ Không liên quan đến thương hiệu
- "Toyota tài trợ giải bóng đá" ❌ Không phải review sản phẩm
- "Review Toyota Vios 2024" ✅ Đúng context

→ Nếu không lọc nguồn, sẽ có nhiều nhiễu
```

**Ví dụ 2: Context khác nhau**

```
Từ khóa: "VinFast"
Nguồn khác nhau:
- Trang tin tức: "VinFast mở nhà máy mới" → Tin tức, không phải review
- Page review xe: "Review VinFast VF8" → Đúng context
- Group xe hơi: "VF8 của tôi hỏng rồi" → Đúng context
- Trang cá nhân: "Hôm nay đi VinFast" → Không có giá trị phân tích
```

### Đề xuất thay đổi

**Ưu tiên theo Nguồn (Source Priority)**

**Cấu hình nguồn:**

```
Loại nguồn theo độ ưu tiên:

1. Pages Review chuyên ngành (Độ ưu tiên: CAO)
   - Xe: "Xe Hay", "Ô tô 360", "Car Review VN"
   - Làm đẹp: "Beauty Blogger", "Review Mỹ phẩm"
   - Công nghệ: "Tech Review", "Fptshop Review"

   Lý do: Nội dung chuyên sâu, có giá trị phân tích cao

2. Groups chuyên ngành (Độ ưu tiên: CAO)
   - "Hội VinFast Việt Nam"
   - "Cộng đồng xe điện"
   - "Tư vấn mua xe"

   Lý do: Người dùng thực, chia sẻ trải nghiệm thật

3. KOLs/Influencers (Độ ưu tiên: TRUNG BÌNH)
   - Reviewers có >50K followers
   - Verified accounts

   Lý do: Ảnh hưởng lớn, nhưng có thể bias

4. Trang tin tức (Độ ưu tiên: THẤP)
   - Chỉ lấy nếu là bài review/đánh giá
   - Bỏ qua tin tức chung chung

   Lý do: Thường không có phân tích sâu

5. Trang cá nhân (Độ ưu tiên: RẤT THẤP)
   - Chỉ lấy nếu có engagement cao
   - Bỏ qua status ngắn

   Lý do: Nhiều nhiễu, ít giá trị
```

**Cơ chế lọc:**

```
Bước 1: Crawl theo từ khóa
Bước 2: Phân loại nguồn
Bước 3: Áp dụng độ ưu tiên
Bước 4: Lọc bỏ nhiễu
Bước 5: Phân tích

Ví dụ:
- "Ông A lái Toyota gây tai nạn"
  → Nguồn: Trang tin tức
  → Context: Tin tức, không phải review
  → Quyết định: BỎ QUA

- "Review Toyota Vios sau 5 năm sử dụng"
  → Nguồn: Page "Xe Hay"
  → Context: Review chuyên sâu
  → Quyết định: PHÂN TÍCH
```

**Lợi ích:**

- ✅ Giảm 70% nhiễu
- ✅ Tăng độ chính xác phân tích
- ✅ Tập trung vào nguồn có giá trị

---

## 🎯 Vấn đề 5: Phân tích theo Domain

### Hiện tại (One-size-fits-all)

- Một thuật toán phân tích cho tất cả ngành
- Không phân biệt domain
- Aspect cố định: DESIGN, PERFORMANCE, PRICE, SERVICE

### Thực tế từ Marketing Agency

**Mỗi domain cần phân tích khác nhau**

**Ví dụ 1: Ngành Xe hơi**

```
Aspects quan trọng:
- DESIGN: Ngoại hình, nội thất, màu sắc
- PERFORMANCE: Động cơ, vận hành, tiết kiệm nhiên liệu
- PRICE: Giá xe, chi phí bảo dưỡng
- SERVICE: Bảo hành, dịch vụ sau bán
- SAFETY: An toàn, airbag, phanh

Từ khóa đặc trưng:
- "động cơ", "vận hành", "tiết kiệm xăng"
- "bảo hành", "phụ tùng", "dịch vụ"
- "an toàn", "va chạm", "airbag"
```

**Ví dụ 2: Ngành Làm đẹp**

```
Aspects quan trọng:
- EFFECTIVENESS: Hiệu quả, kết quả
- INGREDIENTS: Thành phần, công thức
- TEXTURE: Kết cấu, mùi hương
- PRICE: Giá cả, giá trị
- PACKAGING: Bao bì, thiết kế

Từ khóa đặc trưng:
- "hiệu quả", "kết quả", "da đẹp"
- "thành phần", "công thức", "tự nhiên"
- "mùi hương", "kết cấu", "thấm nhanh"
```

**Ví dụ 3: Ngành Công nghệ**

```
Aspects quan trọng:
- PERFORMANCE: Hiệu năng, tốc độ
- FEATURES: Tính năng, công nghệ
- DESIGN: Thiết kế, màn hình
- PRICE: Giá cả, giá trị
- BATTERY: Pin, sạc

Từ khóa đặc trưng:
- "hiệu năng", "nhanh", "mượt"
- "tính năng", "camera", "màn hình"
- "pin", "sạc", "dùng lâu"
```

### Đề xuất thay đổi

**Phân tích theo Domain-specific**

**Cấu hình domain:**

```
Khi tạo project, chọn domain:
- Ô tô / Xe máy
- Làm đẹp / Mỹ phẩm
- Công nghệ / Điện tử
- Thực phẩm / F&B
- Thời trang / Phụ kiện
- ... (mở rộng sau)

Mỗi domain có:
1. Aspects riêng
2. Từ khóa đặc trưng riêng
3. Thuật toán phân tích riêng
4. Ngưỡng đánh giá riêng
```

**Ví dụ cụ thể:**

```
Domain: Ô tô
Aspects: DESIGN, PERFORMANCE, PRICE, SERVICE, SAFETY

Phân tích comment: "Xe đẹp nhưng động cơ yếu, giá hơi cao"
→ DESIGN: Tích cực ("đẹp")
→ PERFORMANCE: Tiêu cực ("động cơ yếu")
→ PRICE: Tiêu cực ("giá hơi cao")

Domain: Làm đẹp
Aspects: EFFECTIVENESS, INGREDIENTS, TEXTURE, PRICE, PACKAGING

Phân tích comment: "Kem dưỡng thấm nhanh, da mịn hơn nhưng hơi đắt"
→ TEXTURE: Tích cực ("thấm nhanh")
→ EFFECTIVENESS: Tích cực ("da mịn hơn")
→ PRICE: Tiêu cực ("hơi đắt")
```

**Lợi ích:**

- ✅ Phân tích chính xác hơn theo từng ngành
- ✅ Aspects phù hợp với domain
- ✅ Từ khóa đặc trưng của ngành
- ✅ Dễ mở rộng sang ngành mới

---

## 🎯 Vấn đề 6: 3 Use Cases khác nhau

### Hiện tại (Chưa phân biệt rõ)

- Tất cả use cases đều quan trọng như nhau
- Không rõ ai làm, khi nào làm
- Workflow không rõ ràng

### Thực tế từ Marketing Agency

**3 công việc marketing khác nhau, 3 team khác nhau**

### Đề xuất thay đổi

**Phân biệt rõ 3 Use Cases:**

**UC-01: Phân tích Đối thủ**

- **Ai làm:** Team Research
- **Khi nào:** Trước khi bắt đầu chiến dịch mới
- **Mục đích:** Nghiên cứu thị trường, học hỏi từ đối thủ
- **Output:** Báo cáo so sánh, insights để lên plan
- **Độ quan trọng:** ⭐⭐⭐ (Quan trọng)

**UC-02: Phân tích Khủng hoảng**

- **Ai làm:** Team Media
- **Khi nào:** Khi công ty phát hiện có vấn đề
- **Mục đích:** Tìm nguyên nhân, xác định khía cạnh bị chê
- **Output:** Khía cạnh + Mức độ + Hành động đề xuất
- **Độ quan trọng:** ⭐⭐⭐⭐⭐ (RẤT quan trọng - Lý do chính dùng Social Listening)

**UC-03: Phát hiện Trend**

- **Ai làm:** Team Content
- **Khi nào:** Hàng ngày
- **Mục đích:** Biết trend để lên bài cho page
- **Output:** List trends, gợi ý content
- **Độ quan trọng:** ⭐⭐ (Nice-to-have, không quan trọng lắm)

**Workflow thực tế:**

```
1. Trước chiến dịch:
   Team Research → UC-01: Phân tích Đối thủ
   → Lên plan chiến dịch

2. Khi có vấn đề:
   Công ty phát hiện complain nhiều
   → Team Media → UC-02: Phân tích Khủng hoảng
   → Xác định nguyên nhân → Xử lý

3. Hàng ngày:
   Team Content → UC-03: Phát hiện Trend
   → Lên content cho page
```

---

## 📊 Tổng kết Đề xuất

### Thay đổi quan trọng nhất

**1. UC-08 → UC-02: Phân tích Khủng hoảng**

- ❌ Bỏ: Phát hiện sớm khủng hoảng
- ✅ Thêm: Phân tích khủng hoảng đã xảy ra
- ✅ Focus: Xác định khía cạnh bị chê

**2. Input từ Chuyên gia**

- ❌ Bỏ: AI tự động tìm từ khóa
- ✅ Thêm: Team Media tự nhập từ khóa
- ✅ SMAP chỉ gợi ý ngưỡng

**3. Output tập trung Khía cạnh**

- ❌ Bỏ: Số liệu % khô khan
- ✅ Thêm: Ý nghĩa cụ thể (khía cạnh nào bị chê)
- ✅ Thêm: Hành động đề xuất cụ thể

**4. Lọc theo Nguồn**

- ✅ Thêm: Ưu tiên pages review, groups chuyên ngành
- ✅ Thêm: Lọc bỏ tin tức không liên quan
- ✅ Giảm 70% nhiễu

**5. Phân tích theo Domain**

- ✅ Thêm: Chọn domain khi tạo project
- ✅ Thêm: Aspects riêng cho từng domain
- ✅ Thêm: Thuật toán riêng cho từng ngành

### Lý do thay đổi

**Từ góc nhìn kỹ thuật → Góc nhìn thực tế marketing**

- Hiểu đúng cách marketing agency làm việc
- Tin tưởng vào expertise của marketing team
- Focus vào giá trị thực tế, không phải con số

### Ưu tiên triển khai

**Phase 1 (Quan trọng nhất):**

1. Đổi UC-08 → UC-02: Phân tích Khủng hoảng
2. Input từ Team Media (tự nhập từ khóa)
3. Output tập trung Khía cạnh

**Phase 2 (Quan trọng):** 4. Lọc theo Nguồn 5. Phân biệt rõ 3 Use Cases

**Phase 3 (Mở rộng sau):** 6. Phân tích theo Domain

---

## 🔍 Câu hỏi cần Research thêm

### 1. Output Format

- Chị đi hỏi xem có file mẫu output không?
- Marketing team mong muốn output như thế nào?
- Format nào dễ đọc và hành động nhất?

### 2. Domain-specific Analysis

- Cần research thêm về cách phân tích từng domain
- Mỗi domain có aspects nào?
- Từ khóa đặc trưng của từng domain?
- Thuật toán phân tích khác nhau như thế nào?

### 3. Source Priority

- Làm sao xác định độ ưu tiên của nguồn?
- Tiêu chí nào để đánh giá nguồn có giá trị?
- Có cần cho user tự cấu hình nguồn không?

---

**Tài liệu này sẽ được cập nhật khi có thêm feedback từ marketing agency**
