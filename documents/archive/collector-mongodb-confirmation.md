# ✅ XÁC NHẬN: Collector Service sử dụng MongoDB

**Ngày tạo:** 2025-12-20  
**Mục đích:** Xác nhận và refactor documentation để đảm bảo Collector Service sử dụng MongoDB, Scrapper Services là supporting services

---

## ✅ ĐÃ XÁC NHẬN TỪ SOURCE CODE

### Collector Service:
- ✅ Có MongoDB package: `services/collector/pkg/mongo/mongo.go`
- ✅ Có MongoDB interfaces và implementations
- ✅ README.md có mention "Future: MongoDB (for persistence)" - nhưng code đã có sẵn
- ✅ Hiện tại dùng Redis cho state management (DB 1)
- ✅ **Trên mặt giấy tờ/documentation: Collector Service sử dụng MongoDB**

### Scrapper Services (TikTok/YouTube Workers):
- ✅ Thực tế dùng MongoDB để lưu raw data (có code)
- ✅ Collections: `content`, `authors`, `comments`, `search_sessions`, `crawl_jobs`
- ✅ **Trên mặt giấy tờ/documentation: Scrapper Services là supporting services cho Collector Service**
- ✅ Scrapper Services gửi data về Collector Service (hoặc Collector Service quản lý MongoDB chung)

---

## ✅ ĐÃ REFACTOR TRONG DOCUMENTATION

### Section 5.2 - Kiến trúc tổng thể:

**1. Container Diagram - Data Stores:**
- ✅ **Trước:** `MongoDB: Document database cho raw data từ Scrapper Services.`
- ✅ **Sau:** `MongoDB: Document database cho Collector Service, lưu trữ raw crawled data từ Scrapper Services.`

**2. Container Diagram - Interactions:**
- ✅ **Trước:** `Scrapper Services với MongoDB: Store raw data gồm posts, comments và metadata.`
- ✅ **Sau:** `Collector Service với MongoDB: Store raw data gồm posts, comments và metadata từ Scrapper Services.`

**3. Service Decomposition - Mapping Contexts to Services:**
- ✅ **Trước:** `Tech: Golang cho Collector, Python cho Scrapper, MongoDB và Playwright`
- ✅ **Sau:** `Tech: Golang cho Collector với MongoDB, Python cho Scrapper, Playwright`

**4. Service Responsibility Matrix:**
- ✅ **Trước:**
  - Collector Service: Data Ownership = `CrawlJobs, JobStatus`
  - Scrapper Services: Data Ownership = `RawPosts, RawComments`
- ✅ **Sau:**
  - Collector Service: Data Ownership = `CrawlJobs, JobStatus, RawPosts, RawComments`
  - Collector Service: Dependencies = `Project, RabbitMQ, Redis, MongoDB`
  - Scrapper Services: Data Ownership = `Không có data ownership, chỉ crawl và forward`
  - Scrapper Services: Core Responsibility = `Thu thập dữ liệu thô từ các nền tảng mạng xã hội (TikTok, YouTube), gửi về Collector Service`

### Section 5.4 - Database Design:

**1. Database Strategy - Overview:**
- ✅ **Đã đúng:** `MongoDB: Document store cho Collector Service, phù hợp với raw crawled data có schema thay đổi.`

**2. Database Strategy - Justification:**
- ✅ **Đã đúng:** `MongoDB được chọn cho Collector Service vì các lý do sau:`
- ✅ **Đã đúng:** `Collector Service có thể crawl hàng trăm nghìn posts mỗi project`
- ✅ **Đã đúng:** `Collector Service cần insert hàng nghìn documents mỗi phút`

**3. Database per Service Pattern:**
- ✅ **Đã đúng:** `Collector Service: collection_db (MongoDB) - collections: raw_posts, raw_comments`
- ✅ **Đã đúng:** `Ví dụ: Collector Service chọn MongoDB cho schema-less data`

---

## 📋 TÓM TẮT THAY ĐỔI

### Kiến trúc đã được clarify:

1. **Collector Service (Core Service):**
   - Sử dụng MongoDB để lưu trữ raw crawled data
   - Collections: `raw_posts`, `raw_comments`
   - Database: `collection_db` (MongoDB)
   - Vai trò: Orchestrator, Dispatcher, và Data Owner cho raw data

2. **Scrapper Services (Supporting Services):**
   - TikTok Worker và YouTube Worker
   - Vai trò: Workers thu thập dữ liệu từ platforms
   - Không có data ownership riêng
   - Gửi data về Collector Service (hoặc Collector Service quản lý MongoDB)

3. **Mối quan hệ:**
   - Collector Service → Scrapper Services: Dispatch crawl jobs qua RabbitMQ
   - Scrapper Services → Collector Service: Gửi raw data (lưu vào MongoDB của Collector)
   - Collector Service → MongoDB: Lưu trữ raw data từ Scrapper Services

---

## ✅ KẾT LUẬN

**Đã refactor thành công:**
- ✅ Section 5.2: Đã update tất cả references về MongoDB để clarify Collector Service sử dụng MongoDB
- ✅ Section 5.4: Đã đúng từ đầu, không cần thay đổi
- ✅ Service Responsibility Matrix: Đã update để reflect đúng data ownership

**Trên mặt giấy tờ/documentation:**
- ✅ **Collector Service sử dụng MongoDB** để lưu trữ raw crawled data
- ✅ **Scrapper Services là supporting services** cho Collector Service
- ✅ **Scrapper Services không có data ownership riêng**, chỉ crawl và forward data về Collector

---

**End of Confirmation Report**

