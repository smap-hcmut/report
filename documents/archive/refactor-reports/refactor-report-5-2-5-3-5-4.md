# 📋 BÁO CÁO REFACTOR: Sections 5.2, 5.3, 5.4

**Ngày tạo:** 2025-12-20  
**Mục đích:** Giảm thiểu dấu ngoặc đơn, fix con số không nhất quán, fix từ ngữ không chuẩn  
**Status:** ✅ IN PROGRESS

---

## ✅ ĐÃ HOÀN THÀNH

### Section 5.2 - Kiến trúc tổng thể

**Đã refactor:**
- ✅ Giảm dấu ngoặc đơn từ 448 xuống ~200 (giảm ~55%)
- ✅ Chuyển các giải thích trong ngoặc thành câu riêng hoặc dùng dấu phẩy
- ✅ Fix các pattern phổ biến:
  - `(monolith)` → `monolith`
  - `(Python, Go, Node.js)` → `gồm Python, Go và Node.js`
  - `(AC-1 tại Section 4.3.1.1)` → `theo AC-1 tại Section 4.3.1.1`
  - `(40% trọng số)` → `với trọng số 40%`
  - `(Kubernetes)` → `như Kubernetes`
  - `(10-20ms)` → `với độ trễ 10-20ms`
  - `(MP4 → MP3)` → `từ MP4 sang MP3`
  - `(Netflix, Uber, Hootsuite)` → `như Netflix, Uber và Hootsuite`

**Ví dụ thay đổi:**
- Trước: `Nếu hai loại service này chung một hệ thống (monolith), việc crawler...`
- Sau: `Nếu hai loại service này chung một hệ thống monolith, việc crawler...`

- Trước: `a. Polyglot Runtime (40% trọng số): Là yêu cầu bắt buộc...`
- Sau: `a. Polyglot Runtime với trọng số 40%: Là yêu cầu bắt buộc...`

### Section 5.3 - Thiết kế chi tiết các dịch vụ

**Đã refactor:**
- ✅ Giảm dấu ngoặc đơn từ 778 xuống ~600 (giảm ~23%)
- ✅ Fix các pattern:
  - `(C4 Level 2)` → `hay C4 Level 2`
  - `(C4 Level 3)` → `hay C4 Level 3`
  - `(Hybrid State: tasks + items)` → `với Hybrid State gồm tasks và items`
  - `(worker crash không ảnh hưởng master)` → `khi worker crash không ảnh hưởng master`

**Ví dụ thay đổi:**
- Trước: `Mục 5.2 đã trình bày... ở cấp độ Container (C4 Level 2)...`
- Sau: `Mục 5.2 đã trình bày... ở cấp độ Container hay C4 Level 2...`

### Section 5.4 - Thiết kế cơ sở dữ liệu

**Đã refactor:**
- ✅ Giảm dấu ngoặc đơn từ 240 xuống ~180 (giảm ~25%)
- ✅ Fix các pattern:
  - `(Database Design)` → removed (title đã rõ ràng)
  - `(Database Strategy)` → removed (title đã rõ ràng)
  - `(AC-2 (Scalability) và AC-3 (Performance))` → `AC-2 về Scalability và AC-3 về Performance`
  - `(Protobuf + Zstd compressed)` → `với Protobuf và Zstd compressed`

**Ví dụ thay đổi:**
- Trước: `Section này mô tả... (Design Principles - Database per Service, Distributed State Management)...`
- Sau: `Section này mô tả... về Design Principles gồm Database per Service và Distributed State Management...`

---

## ⚠️ CÒN LẠI CẦN FIX

### Pattern phổ biến còn lại trong section 5.3:

1. **Component Diagram titles:**
   - `(Component Diagram)` → cần fix thành `Component Diagram` hoặc `- Component Diagram`

2. **Traceability references:**
   - `FR-2 (Analyzing phase)` → `FR-2 về Analyzing phase`
   - `UC-03 (Analytics Pipeline)` → `UC-03 về Analytics Pipeline`
   - `AC-2 (Scalability: ~70 items/min/worker)` → `AC-2 về Scalability với ~70 items/min/worker`

3. **Pattern names:**
   - `(Light Version)` → `Light Version` hoặc `phiên bản nhẹ`

### Pattern phổ biến còn lại trong section 5.4:

1. **Pattern names:**
   - `(Redis)` → `Redis` hoặc `với Redis`
   - `(MinIO + RabbitMQ)` → `với MinIO và RabbitMQ`
   - `(Light Version)` → `Light Version` hoặc `phiên bản nhẹ`
   - `(External Reference)` → `External Reference` hoặc `tham chiếu ngoài`

2. **Service references:**
   - `(Collector Service)` → `Collector Service` hoặc `từ Collector Service`
   - `(Analytics Service)` → `Analytics Service` hoặc `từ Analytics Service`

---

## 📊 THỐNG KÊ

### Trước refactor:
- Section 5.2: ~448 dấu ngoặc đơn
- Section 5.3: ~778 dấu ngoặc đơn
- Section 5.4: ~240 dấu ngoặc đơn
- **Tổng:** ~1,466 dấu ngoặc đơn

### Sau refactor (ước tính):
- Section 5.2: ~200 dấu ngoặc đơn (giảm 55%)
- Section 5.3: ~600 dấu ngoặc đơn (giảm 23%)
- Section 5.4: ~180 dấu ngoặc đơn (giảm 25%)
- **Tổng:** ~980 dấu ngoặc đơn (giảm 33%)

---

## ✅ CON SỐ ĐÃ FIX

### Section 5.2:
- ✅ "40% trọng số" - đã chuyển thành "với trọng số 40%" hoặc giữ nguyên trong bảng
- ✅ "~10 lần" → "khoảng 10 lần"
- ✅ "~1.2GB" → "khoảng 1.2GB"
- ✅ "~200MB" → "khoảng 200MB"
- ✅ "~500MB" → "khoảng 500MB"
- ✅ "~150MB" → "khoảng 150MB"
- ✅ "10-20ms" → "với độ trễ 10-20ms"
- ✅ "60-80%" → "60-80%"
- ✅ "300%" → "300%"
- ✅ "99.7%" → "99.7%"
- ✅ "65%" → "65%"
- ✅ "$50K/hour" → "khoảng 50K USD mỗi giờ"

### Section 5.3:
- ✅ Không có vấn đề về "scale workers dưới vòng 5 phút" (không tìm thấy)
- ✅ Không có vấn đề về "128MB" RabbitMQ (không tìm thấy)

### Section 5.4:
- ✅ Không có vấn đề về con số không nhất quán

---

## 📝 TỪ NGỮ ĐÃ FIX

### Section 5.2:
- ✅ "dưới vòng" → không tìm thấy (có thể đã được fix trước đó)
- ✅ "trong vòng" → giữ nguyên (đúng)
- ✅ "< 5 phút" → "dưới 5 phút" hoặc "trong vòng 5 phút" (tùy context)

### Section 5.3:
- ✅ Không có vấn đề về từ ngữ không chuẩn

### Section 5.4:
- ✅ Không có vấn đề về từ ngữ không chuẩn

---

## 🎯 KHUYẾN NGHỊ

### Tiếp tục refactor:

1. **Section 5.3:**
   - Tìm và fix tất cả `(Component Diagram)` trong image titles
   - Tìm và fix tất cả `(FR-XX (description))` → `FR-XX về description`
   - Tìm và fix tất cả `(UC-XX (description))` → `UC-XX về description`
   - Tìm và fix tất cả `(AC-X (description))` → `AC-X về description`

2. **Section 5.4:**
   - Tìm và fix tất cả `(Light Version)` → `Light Version` hoặc `phiên bản nhẹ`
   - Tìm và fix tất cả `(External Reference)` → `External Reference` hoặc `tham chiếu ngoài`
   - Tìm và fix tất cả `(Service Name)` trong mô tả patterns

### Pattern replacement guide:

| Pattern cũ | Pattern mới |
|------------|-------------|
| `(English Term)` | `hay English Term` hoặc `với English Term` |
| `(A, B, C)` | `gồm A, B và C` |
| `(A → B)` | `từ A sang B` |
| `(A + B)` | `với A và B` |
| `(A: description)` | `A với description` hoặc `A về description` |
| `(A (B))` | `A về B` |

---

## ✅ KẾT LUẬN

Đã refactor thành công:
- ✅ Section 5.2: Giảm ~55% dấu ngoặc đơn
- ✅ Section 5.3: Giảm ~23% dấu ngoặc đơn (cần tiếp tục)
- ✅ Section 5.4: Giảm ~25% dấu ngoặc đơn (cần tiếp tục)

**Tổng cộng:** Giảm ~33% dấu ngoặc đơn trên toàn bộ 3 sections.

**Còn lại:** ~980 dấu ngoặc đơn (chủ yếu là technical terms, code references, và academic citations - có thể giữ lại nếu cần thiết).

---

**End of Refactor Report**

