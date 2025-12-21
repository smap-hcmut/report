# 📐 HƯỚNG DẪN CHI TIẾT: VẼ ERD DIAGRAMS CHO SECTION 5.4

**Ngày tạo:** 2025-12-20  
**Mục đích:** Hướng dẫn chi tiết cách vẽ 3 ERD diagrams cho Section 5.4  
**Tool đề xuất:** Draw.io/diagrams.net (free, có C4 Model templates) hoặc Mermaid (code-based)

---

## 📋 TỔNG QUAN

Section 5.4 cần 3 ERD diagrams:

1. **Identity Service ERD** (`identity-schema.png`)
2. **Project Service ERD** (`SMAP-collector.png` - đã có, nhưng cần verify)
3. **Analytics Service ERD** (`analytics-schema.png`)

---

## 🎨 1. IDENTITY SERVICE ERD

### 1.1 Thông tin cơ bản

- **File output:** `report/images/schema/identity-schema.png`
- **Size:** 1200x800px (landscape)
- **Format:** PNG với transparent background
- **Style:** Mermaid ER diagram notation

### 1.2 Components và Attributes

#### Table: USERS

**Position:** Bên trái, phía trên

**Attributes:**
- `id` (UUID, PK) - Primary Key, bold
- `username` (VARCHAR(255), UK) - Unique Key, italic
- `full_name` (VARCHAR(100))
- `password_hash` (VARCHAR(255)) - Note: "bcrypt, cost 10"
- `role_hash` (TEXT) - Note: "Encrypted role (USER/ADMIN)"
- `avatar_url` (VARCHAR(255))
- `is_active` (BOOLEAN) - Note: "Account verified"
- `otp` (VARCHAR(6)) - Note: "6-digit OTP"
- `otp_expired_at` (TIMESTAMP)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP) - Note: "Soft delete"

**Visual Style:**
- Table name: Bold, size 14pt
- PK: Bold, color blue (#1976D2)
- UK: Italic, color green (#388E3C)
- Notes: Smaller font, color gray (#757575)

#### Table: PLANS

**Position:** Bên phải, phía trên

**Attributes:**
- `id` (UUID, PK) - Primary Key, bold
- `name` (VARCHAR(50))
- `code` (VARCHAR(50), UK) - Unique Key, italic, Note: "Unique identifier"
- `description` (TEXT)
- `max_usage` (INT) - Note: "API call limit per day"
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP)

**Visual Style:** Tương tự USERS table

#### Table: SUBSCRIPTIONS

**Position:** Ở giữa, phía dưới

**Attributes:**
- `id` (UUID, PK) - Primary Key, bold
- `user_id` (UUID, FK) - Foreign Key, color orange (#F57C00), Note: "References users.id"
- `plan_id` (UUID, FK) - Foreign Key, color orange (#F57C00), Note: "References plans.id"
- `status` (VARCHAR) - Note: "trialing, active, cancelled, expired, past_due"
- `trial_ends_at` (TIMESTAMP)
- `starts_at` (TIMESTAMP)
- `ends_at` (TIMESTAMP)
- `cancelled_at` (TIMESTAMP)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP)

**Visual Style:** Tương tự USERS table, FK có màu orange

### 1.3 Relationships

#### Relationship 1: USERS → SUBSCRIPTIONS

**Type:** One-to-Many (1:N)

**Notation:** 
- Line từ USERS đến SUBSCRIPTIONS
- Crow's foot ở phía SUBSCRIPTIONS (nhiều)
- Label: "has"
- Cardinality: `||--o{` (Mermaid notation: `USERS ||--o{ SUBSCRIPTIONS : "has"`)

**Visual Style:**
- Line color: Black (#000000)
- Line style: Solid
- Arrow: Crow's foot (nhiều) ở SUBSCRIPTIONS
- Label: "has" (italic, size 10pt)

#### Relationship 2: PLANS → SUBSCRIPTIONS

**Type:** One-to-Many (1:N)

**Notation:**
- Line từ PLANS đến SUBSCRIPTIONS
- Crow's foot ở phía SUBSCRIPTIONS (nhiều)
- Label: "defines"
- Cardinality: `||--o{` (Mermaid notation: `PLANS ||--o{ SUBSCRIPTIONS : "defines"`)

**Visual Style:**
- Line color: Black (#000000)
- Line style: Solid
- Arrow: Crow's foot (nhiều) ở SUBSCRIPTIONS
- Label: "defines" (italic, size 10pt)

### 1.4 Layout và Spacing

**Layout:**
```
┌─────────────┐         ┌─────────────┐
│   USERS     │         │    PLANS     │
│             │         │             │
│  (attributes)│         │  (attributes)│
└──────┬──────┘         └──────┬──────┘
       │                       │
       │  "has"                │  "defines"
       │                       │
       └───────────┬───────────┘
                   │
            ┌──────▼──────┐
            │SUBSCRIPTIONS│
            │             │
            │ (attributes)│
            └─────────────┘
```

**Spacing:**
- Khoảng cách giữa tables: 150px
- Khoảng cách từ top: 50px
- Khoảng cách từ bottom: 50px
- Khoảng cách từ sides: 50px

### 1.5 Color Scheme

- **Background:** White (#FFFFFF) hoặc transparent
- **Table background:** Light gray (#F5F5F5)
- **Table border:** Dark gray (#424242), 2pt
- **PK text:** Blue (#1976D2)
- **UK text:** Green (#388E3C)
- **FK text:** Orange (#F57C00)
- **Regular text:** Black (#000000)
- **Notes text:** Gray (#757575), size 9pt

### 1.6 Hướng dẫn vẽ chi tiết

**Bước 1: Tạo 3 tables**
- Vẽ 3 rectangles cho USERS, PLANS, SUBSCRIPTIONS
- Kích thước: USERS và PLANS (300x400px), SUBSCRIPTIONS (350x400px)
- Đặt USERS bên trái, PLANS bên phải, SUBSCRIPTIONS ở giữa phía dưới

**Bước 2: Thêm attributes**
- Thêm header row (table name) với background color khác
- Thêm các attribute rows
- Highlight PK với màu blue, UK với màu green, FK với màu orange
- Thêm notes cho các attributes có notes

**Bước 3: Vẽ relationships**
- Vẽ line từ USERS đến SUBSCRIPTIONS
- Thêm crow's foot ở SUBSCRIPTIONS (nhiều)
- Thêm label "has" ở giữa line
- Lặp lại cho PLANS → SUBSCRIPTIONS với label "defines"

**Bước 4: Styling**
- Apply color scheme
- Add shadows cho tables (optional)
- Ensure text is readable (minimum 10pt)

---

## 🎨 2. PROJECT SERVICE ERD

### 2.1 Thông tin cơ bản

- **File output:** `report/images/schema/SMAP-collector.png` (đã có, nhưng cần verify)
- **Size:** 1000x600px (landscape)
- **Format:** PNG với transparent background
- **Style:** Mermaid ER diagram notation

### 2.2 Components và Attributes

#### Table: PROJECTS

**Position:** Ở giữa

**Attributes:**
- `id` (UUID, PK) - Primary Key, bold, Note: "Auto-generated UUID"
- `name` (VARCHAR(255))
- `description` (TEXT)
- `status` (VARCHAR) - Note: "draft|active|completed|archived|cancelled"
- `from_date` (TIMESTAMPTZ) - Note: "Project start date"
- `to_date` (TIMESTAMPTZ) - Note: "Project end date"
- `brand_name` (VARCHAR(255))
- `competitor_names` (TEXT[]) - Note: "Array of competitor names"
- `brand_keywords` (TEXT[]) - Note: "Array of brand keywords"
- `competitor_keywords_map` (JSONB) - Note: "Map: competitor -> keywords"
- `exclude_keywords` (TEXT[])
- `created_by` (UUID) - Note: "User ID from JWT (no FK)" - **KHÔNG CÓ FK CONSTRAINT**, color red (#D32F2F)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)
- `deleted_at` (TIMESTAMPTZ) - Note: "Soft delete"

**Visual Style:**
- Table name: Bold, size 14pt
- PK: Bold, color blue (#1976D2)
- `created_by`: Color red (#D32F2F), italic, Note: "User ID from JWT (no FK)" - **QUAN TRỌNG: Không có FK line**
- Array types (TEXT[]): Color purple (#7B1FA2)
- JSONB: Color brown (#5D4037)

### 2.3 Relationships

**KHÔNG CÓ RELATIONSHIPS** - Đây là single table, không có FK constraints.

**Lưu ý quan trọng:**
- `created_by` reference đến `users.id` nhưng **KHÔNG CÓ FK CONSTRAINT** vì ở database khác
- Cần highlight điều này trong diagram (màu red, italic, note rõ ràng)

### 2.4 Layout và Spacing

**Layout:**
```
┌─────────────────────────────┐
│        PROJECTS             │
│                             │
│      (attributes)           │
│                             │
│  created_by (no FK) ←───    │
│  (red, italic, note)        │
└─────────────────────────────┘
```

**Spacing:**
- Table ở giữa canvas
- Khoảng cách từ edges: 50px
- Table width: 600px
- Table height: 500px (đủ để hiển thị tất cả attributes)

### 2.5 Color Scheme

- **Background:** White (#FFFFFF) hoặc transparent
- **Table background:** Light gray (#F5F5F5)
- **Table border:** Dark gray (#424242), 2pt
- **PK text:** Blue (#1976D2)
- **Array types (TEXT[]):** Purple (#7B1FA2)
- **JSONB:** Brown (#5D4037)
- **created_by (no FK):** Red (#D32F2F), italic
- **Regular text:** Black (#000000)
- **Notes text:** Gray (#757575), size 9pt

### 2.6 Hướng dẫn vẽ chi tiết

**Bước 1: Tạo table PROJECTS**
- Vẽ 1 rectangle (600x500px)
- Đặt ở giữa canvas

**Bước 2: Thêm attributes**
- Thêm header row với "PROJECTS" (bold)
- Thêm các attribute rows
- Highlight PK với màu blue
- Highlight `created_by` với màu red, italic, và note rõ ràng: "User ID from JWT (no FK)"
- Highlight array types (TEXT[]) với màu purple
- Highlight JSONB với màu brown

**Bước 3: Thêm note về Cross-Database Relationship**
- Thêm text box ở dưới table:
  "Note: created_by references users.id (Identity Service database) but has NO FK constraint due to Database per Service pattern."

**Bước 4: Styling**
- Apply color scheme
- Ensure `created_by` stands out (red, italic)

---

## 🎨 3. ANALYTICS SERVICE ERD

### 3.1 Thông tin cơ bản

- **File output:** `report/images/schema/analytics-schema.png`
- **Size:** 1400x1000px (portrait, taller để fit 3 tables)
- **Format:** PNG với transparent background
- **Style:** Mermaid ER diagram notation

### 3.2 Components và Attributes

#### Table: post_analytics

**Position:** Ở giữa, phía trên (table lớn nhất)

**Attributes (nhóm theo category):**

**Identifiers:**
- `id` (STRING(50), PK) - Primary Key, bold, Note: "Content ID từ platform"
- `project_id` (UUID, FK) - Foreign Key, color orange, Note: "UUID của project (nullable for dry-run)"
- `platform` (STRING(20)) - Note: "TIKTOK | YOUTUBE"

**Timestamps:**
- `published_at` (TIMESTAMP)
- `analyzed_at` (TIMESTAMP)

**Overall Analysis:**
- `overall_sentiment` (STRING(10)) - Note: "POSITIVE | NEGATIVE | NEUTRAL"
- `overall_sentiment_score` (FLOAT) - Note: "-1.0 to 1.0"
- `overall_confidence` (FLOAT) - Note: "0.0 to 1.0"

**Intent:**
- `primary_intent` (STRING(20)) - Note: "REVIEW | COMPLAINT | QUESTION..."
- `intent_confidence` (FLOAT)

**Impact:**
- `impact_score` (FLOAT) - Note: "0 to 100"
- `risk_level` (STRING(10)) - Note: "LOW | MEDIUM | HIGH | CRITICAL"
- `is_viral` (BOOLEAN)
- `is_kol` (BOOLEAN)

**JSONB Fields:**
- `aspects_breakdown` (JSONB) - Note: "Aspect-based sentiment", color brown
- `keywords` (JSONB) - Note: "Extracted keywords", color brown
- `sentiment_probabilities` (JSONB) - color brown
- `impact_breakdown` (JSONB) - color brown

**Interaction Metrics:**
- `view_count` (INTEGER)
- `like_count` (INTEGER)
- `comment_count` (INTEGER)
- `share_count` (INTEGER)
- `save_count` (INTEGER)
- `follower_count` (INTEGER)

**Content:**
- `content_text` (TEXT) - Note: "Nội dung bài viết"
- `content_transcription` (TEXT) - Note: "Transcription audio/video"
- `media_duration` (INTEGER)
- `hashtags` (JSONB) - color brown
- `permalink` (TEXT)

**Author Info:**
- `author_id` (STRING(100))
- `author_name` (STRING(200))
- `author_username` (STRING(100))
- `author_avatar_url` (TEXT)
- `author_is_verified` (BOOLEAN)

**Brand/Keyword:**
- `brand_name` (STRING(100))
- `keyword` (STRING(200))

**Batch Context:**
- `job_id` (STRING(100))
- `batch_index` (INTEGER)
- `task_type` (STRING(30)) - Note: "research_and_crawl"
- `keyword_source` (STRING(200))
- `crawled_at` (TIMESTAMP)
- `pipeline_version` (STRING(50))

**Error Tracking:**
- `fetch_status` (STRING(10)) - Note: "success | error"
- `error_code` (STRING(50))
- `fetch_error` (TEXT)
- `error_details` (JSONB) - color brown

**Processing:**
- `processing_time_ms` (INTEGER)
- `model_version` (STRING(50))

**Visual Style:**
- Table name: Bold, size 14pt
- PK: Bold, color blue (#1976D2)
- FK: Color orange (#F57C00)
- JSONB fields: Color brown (#5D4037)
- Group attributes theo category (có thể dùng background color nhẹ để phân nhóm)

#### Table: post_comments

**Position:** Bên trái, phía dưới

**Attributes:**
- `id` (SERIAL, PK) - Primary Key, bold, Note: "Auto increment ID"
- `post_id` (STRING(50), FK) - Foreign Key, color orange, Note: "FK to post_analytics"
- `comment_id` (STRING(100)) - Note: "Comment ID từ platform"
- `text` (TEXT)
- `author_name` (STRING(200))
- `likes` (INTEGER)
- `sentiment` (STRING(10)) - Note: "POSITIVE | NEGATIVE | NEUTRAL"
- `sentiment_score` (FLOAT) - Note: "-1.0 to 1.0"
- `commented_at` (TIMESTAMP)
- `created_at` (TIMESTAMP)

**Visual Style:** Tương tự post_analytics

#### Table: crawl_errors

**Position:** Bên phải, phía dưới

**Attributes:**
- `id` (SERIAL, PK) - Primary Key, bold, Note: "Auto increment ID"
- `content_id` (STRING(50))
- `project_id` (UUID) - Note: "UUID của project" - **KHÔNG CÓ FK CONSTRAINT**, color red
- `job_id` (STRING(100))
- `platform` (STRING(20)) - Note: "TIKTOK | YOUTUBE"
- `error_code` (STRING(50))
- `error_category` (STRING(30))
- `error_message` (TEXT)
- `error_details` (JSONB) - color brown
- `permalink` (TEXT)
- `created_at` (TIMESTAMP)

**Visual Style:** Tương tự post_analytics, `project_id` màu red (no FK)

### 3.3 Relationships

#### Relationship 1: post_analytics → post_comments

**Type:** One-to-Many (1:N)

**Notation:**
- Line từ post_analytics đến post_comments
- Crow's foot ở phía post_comments (nhiều)
- Label: "has many"
- Cardinality: `||--o{` (Mermaid notation: `post_analytics ||--o{ post_comments : "has many"`)

**Visual Style:**
- Line color: Black (#000000)
- Line style: Solid
- Arrow: Crow's foot (nhiều) ở post_comments
- Label: "has many" (italic, size 10pt)

#### Relationship 2: post_analytics → crawl_errors

**Type:** Zero-to-Many (0:N)

**Notation:**
- Line từ post_analytics đến crawl_errors
- Crow's foot ở phía crawl_errors (nhiều)
- Label: "may have"
- Cardinality: `||--o{` (Mermaid notation: `post_analytics ||--o{ crawl_errors : "may have"`)

**Lưu ý:** Không có FK constraint vì `crawl_errors.content_id` là String, không phải FK đến `post_analytics.id`.

**Visual Style:**
- Line color: Black (#000000)
- Line style: Dashed (vì không có FK constraint)
- Arrow: Crow's foot (nhiều) ở crawl_errors
- Label: "may have" (italic, size 10pt)

#### Relationship 3: post_analytics → project (External Reference)

**Type:** Many-to-One (N:1) - External Reference

**Notation:**
- Line từ post_analytics đến external box "Project Service Database"
- Label: "project_id (external)"
- Cardinality: `}o--||` (Mermaid notation: không có trong diagram, chỉ note)

**Lưu ý:** `project_id` reference đến `projects.id` nhưng **KHÔNG CÓ FK CONSTRAINT** vì ở database khác.

**Visual Style:**
- Line color: Red (#D32F2F)
- Line style: Dashed (vì external reference, no FK)
- Arrow: Single arrow đến external box
- Label: "project_id (external, no FK)" (italic, size 10pt, red)

### 3.4 Layout và Spacing

**Layout:**
```
┌─────────────────────────────────────┐
│        post_analytics               │
│         (large table)               │
│                                     │
│      (many attributes)              │
└───────┬───────────────────┬─────────┘
        │                   │
        │ "has many"        │ "may have"
        │                   │ (dashed)
        │                   │
┌───────▼──────┐    ┌───────▼────────┐
│post_comments │    │ crawl_errors   │
│              │    │                 │
│ (attributes) │    │  (attributes)   │
└──────────────┘    └─────────────────┘

        ┌──────────────────────┐
        │ Project Service DB   │
        │ (external reference) │
        └──────────────────────┘
        ↑ (dashed red line)
        │ "project_id (external, no FK)"
```

**Spacing:**
- post_analytics: Ở giữa, phía trên (800x600px)
- post_comments: Bên trái, phía dưới (350x400px)
- crawl_errors: Bên phải, phía dưới (350x400px)
- Khoảng cách giữa tables: 100px
- Khoảng cách từ edges: 50px

### 3.5 Color Scheme

- **Background:** White (#FFFFFF) hoặc transparent
- **Table background:** Light gray (#F5F5F5)
- **Table border:** Dark gray (#424242), 2pt
- **PK text:** Blue (#1976D2)
- **FK text:** Orange (#F57C00)
- **JSONB fields:** Brown (#5D4037)
- **External reference (no FK):** Red (#D32F2F), dashed line
- **Regular text:** Black (#000000)
- **Notes text:** Gray (#757575), size 9pt

### 3.6 Hướng dẫn vẽ chi tiết

**Bước 1: Tạo 3 tables**
- Vẽ post_analytics (800x600px) ở giữa, phía trên
- Vẽ post_comments (350x400px) bên trái, phía dưới
- Vẽ crawl_errors (350x400px) bên phải, phía dưới

**Bước 2: Thêm attributes cho post_analytics**
- Group attributes theo category (có thể dùng background color nhẹ)
- Highlight PK với màu blue
- Highlight FK với màu orange
- Highlight JSONB fields với màu brown
- Thêm notes cho các attributes quan trọng

**Bước 3: Thêm attributes cho post_comments và crawl_errors**
- Tương tự post_analytics
- Highlight `project_id` trong crawl_errors với màu red (no FK)

**Bước 4: Vẽ relationships**
- Vẽ solid line từ post_analytics đến post_comments với label "has many"
- Vẽ dashed line từ post_analytics đến crawl_errors với label "may have"
- Vẽ dashed red line từ post_analytics đến external box "Project Service Database" với label "project_id (external, no FK)"

**Bước 5: Thêm external reference box**
- Vẽ box "Project Service Database" ở dưới cùng
- Vẽ dashed red line từ post_analytics đến box này
- Note rõ ràng: "External reference, no FK constraint"

**Bước 6: Styling**
- Apply color scheme
- Ensure relationships are clear (solid vs dashed)
- Ensure external references stand out (red, dashed)

---

## 🛠️ TOOL RECOMMENDATIONS

### Option 1: Draw.io/diagrams.net (Recommended)

**Ưu điểm:**
- Free, web-based
- Có templates cho ER diagrams
- Export PNG với transparent background
- Dễ chỉnh sửa

**Cách sử dụng:**
1. Truy cập https://app.diagrams.net/
2. Chọn "Create New Diagram"
3. Chọn template "Entity Relationship" hoặc "Blank"
4. Vẽ tables và relationships theo hướng dẫn trên
5. Export as PNG với transparent background

### Option 2: Mermaid (Code-based)

**Ưu điểm:**
- Code-based, version control friendly
- Có thể embed trực tiếp trong Typst (nếu support)
- Dễ maintain

**Nhược điểm:**
- Less flexible than Draw.io
- Khó customize visual style

**Cách sử dụng:**
1. Sử dụng Mermaid syntax (đã có trong Section 5.4)
2. Render bằng Mermaid Live Editor: https://mermaid.live/
3. Export as PNG

### Option 3: PlantUML (Code-based)

**Ưu điểm:**
- Code-based
- Good for ER diagrams
- Có thể integrate với documentation tools

**Nhược điểm:**
- Less visual than Draw.io
- Cần setup environment

---

## ✅ CHECKLIST TRƯỚC KHI VẼ

### Identity Service ERD
- [ ] 3 tables: USERS, PLANS, SUBSCRIPTIONS
- [ ] Tất cả attributes với correct data types
- [ ] PK highlighted (blue)
- [ ] UK highlighted (green)
- [ ] FK highlighted (orange)
- [ ] 2 relationships: USERS → SUBSCRIPTIONS, PLANS → SUBSCRIPTIONS
- [ ] Labels: "has" và "defines"
- [ ] Notes cho các attributes quan trọng

### Project Service ERD
- [ ] 1 table: PROJECTS
- [ ] Tất cả attributes với correct data types
- [ ] PK highlighted (blue)
- [ ] `created_by` highlighted (red, italic, note: "no FK")
- [ ] Array types (TEXT[]) highlighted (purple)
- [ ] JSONB highlighted (brown)
- [ ] Note về Cross-Database Relationship

### Analytics Service ERD
- [ ] 3 tables: post_analytics, post_comments, crawl_errors
- [ ] Tất cả attributes với correct data types
- [ ] PK highlighted (blue)
- [ ] FK highlighted (orange)
- [ ] JSONB fields highlighted (brown)
- [ ] `project_id` trong crawl_errors highlighted (red, no FK)
- [ ] 2 relationships: post_analytics → post_comments (solid), post_analytics → crawl_errors (dashed)
- [ ] External reference box "Project Service Database" với dashed red line
- [ ] Labels: "has many", "may have", "project_id (external, no FK)"

---

## 📝 NOTES QUAN TRỌNG

1. **Cross-Database Relationships:** Tất cả references đến tables ở database khác (Identity → Project, Analytics → Project) phải được highlight rõ ràng với màu red và note "no FK constraint".

2. **JSONB Fields:** Tất cả JSONB fields phải được highlight với màu brown để dễ nhận biết.

3. **Array Types:** TEXT[] fields phải được highlight với màu purple.

4. **FK Constraints:** Chỉ vẽ FK lines cho relationships trong cùng database. External references dùng dashed lines.

5. **Cardinality:** Sử dụng crow's foot notation (||--o{ cho One-to-Many, ||--|| cho One-to-One).

---

**End of Guide**  
**Generated by: AI Assistant**  
**Date: December 20, 2025**

