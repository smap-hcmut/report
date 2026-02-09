# ĐÁNH GIÁ CHI TIẾT: INPUT/OUTPUT FLOW

**Ngày đánh giá:** 08/02/2026  
**Phạm vi:** Data Source Schema → Analytics Output → Dashboard/Charts → RAG

---

## 1. TỔNG QUAN LUỒNG DỮ LIỆU

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLETE DATA FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INPUT LAYER (Data Sources)                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │  Excel   │ │ Webhook  │ │ Facebook │ │ TikTok   │           │
│  │  CSV     │ │ (JSON)   │ │ (API)    │ │ (API)    │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                 │
│       └────────────┴────────────┴────────────┘                 │
│                           ↓                                     │
│  NORMALIZATION LAYER (UAP)                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Unified Analytics Payload (UAP)                        │    │
│  │  {                                                      │    │
│  │    content, content_created_at, ingested_at,           │    │
│  │    platform, metadata                                  │    │
│  │  }                                                      │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  ANALYTICS LAYER (AI Processing)                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  n8n + Python Workers                                   │    │
│  │  ├── Sentiment Analysis (PhoBERT)                       │    │
│  │  ├── Aspect Extraction (PhoBERT)                        │    │
│  │  └── Keyword Extraction (Underthesea)                   │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│  OUTPUT LAYER (analytics.post_analytics)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  {                                                      │    │
│  │    content, content_created_at, platform,              │    │
│  │    overall_sentiment, overall_sentiment_score,         │    │
│  │    aspects: [{aspect, sentiment, score, keywords}],    │    │
│  │    keywords: [],                                       │    │
│  │    risk_level                                          │    │
│  │  }                                                      │    │
│  └─────────────────────────┬───────────────────────────────┘    │
│                            ↓                                    │
│       ┌────────────────────┴────────────────────┐               │
│       ↓                                         ↓               │
│  CONSUMPTION LAYER                                              │
│  ┌─────────────┐                         ┌─────────────┐        │
│  │  Dashboard  │                         │     RAG     │        │
│  │  (Charts)   │                         │  (Qdrant)   │        │
│  └─────────────┘                         └─────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. ĐÁNH GIÁ CHI TIẾT TỪNG LAYER

### 2.1 INPUT LAYER - Data Source Schema

**✅ ĐIỂM MẠNH:**

1. **Đa dạng nguồn:** Hỗ trợ 5 loại source (FILE_UPLOAD, WEBHOOK, FACEBOOK, TIKTOK, YOUTUBE)
2. **Phân loại rõ ràng:** Crawl vs Passive sources với workflow riêng biệt
3. **Flexible config:** JSONB cho file_config, webhook_config, crawl_config
4. **AI Schema Mapping:** Tự động suggest mapping cho File + Webhook
5. **Onboarding status tracking:** PENDING → MAPPING_READY → CONFIRMED

**❌ ĐIỂM YẾU:**

1. **Thiếu validation rules:** Không có schema validation cho webhook_config.payload_schema
2. **Thiếu sample data storage:** Webhook không lưu sample payload để user preview
3. **Thiếu rate limiting config:** Crawl sources không có config về rate limit, retry policy
4. **Thiếu data quality metrics:** Không track % data bị reject do invalid format

**Schema hiện tại:**
```sql
CREATE TABLE ingest.data_sources (
    id UUID,
    project_id UUID,
    name VARCHAR(255),
    source_type VARCHAR(20), -- 'FILE_UPLOAD', 'WEBHOOK', 'FACEBOOK'...
    source_category VARCHAR(10), -- 'crawl' hoặc 'passive'
    
    file_config JSONB,
    webhook_config JSONB,
    crawl_config JSONB,
    
    schema_mapping JSONB,
    mapping_rules JSONB,
    onboarding_status VARCHAR(20),
    
    record_count INT,
    error_count INT,
    ...
);
```

---

### 2.2 NORMALIZATION LAYER - UAP (Unified Analytics Payload)

**✅ ĐIỂM MẠNH:**

1. **Canonical model:** Tất cả sources đều chuẩn hóa về 1 format duy nhất
2. **Time semantics rõ ràng:** 2 trường thời gian riêng biệt (content_created_at vs ingested_at)
3. **Schema-less metadata:** JSONB cho phép lưu thông tin phụ linh hoạt
4. **Traceability:** Có project_id, source_id để truy vết nguồn gốc

**❌ ĐIỂM YẾU:**

1. **Thiếu unique constraint:** Không có external_id hoặc content_hash để dedup
2. **Thiếu language detection:** Không có field `language` (vi, en, zh...) cho multilingual support
3. **Thiếu engagement metrics:** Không lưu likes, shares, views từ social platforms
4. **Thiếu author info:** metadata.author không có structure (name, id, verified status)

**UAP Schema hiện tại:**
```json
{
  "id": "uuid",
  "project_id": "uuid",
  "source_id": "uuid",
  "content": "string",              // ✅ OK
  "content_created_at": "timestamp", // ✅ OK
  "ingested_at": "timestamp",        // ✅ OK
  "platform": "string",              // ✅ OK
  "metadata": {}                     // ⚠️ Quá linh hoạt, thiếu structure
}
```

---

### 2.3 ANALYTICS LAYER - AI Processing Output

**✅ ĐIỂM MẠNH:**

1. **Comprehensive analysis:** Sentiment + Aspect + Keywords
2. **Structured aspects:** JSONB array với {aspect, sentiment, score, keywords}
3. **Risk level:** Có field risk_level để trigger alerts
4. **Indexing:** Có index trên sentiment, created_at, project_id

**❌ ĐIỂM YẾU / THIẾU:**

1. **❌ THIẾU AGGREGATION TABLES:**
   - Không có bảng tổng hợp theo ngày/tuần/tháng
   - Dashboard phải query raw data → CHẬM khi có hàng triệu records
   
2. **❌ THIẾU ASPECT TAXONOMY:**
   - aspects là free-text → không consistent
   - Cần bảng `aspect_categories` để chuẩn hóa (PRICE, SERVICE, QUALITY...)
   
3. **❌ THIẾU SENTIMENT HISTORY:**
   - Không track sentiment thay đổi theo thời gian cho cùng 1 entity
   - VD: "VF8" sentiment trend over 6 months
   
4. **❌ THIẾU COMPARISON METRICS:**
   - Không có bảng lưu so sánh giữa các projects
   - Campaign War Room phải tính toán real-time → CHẬM
   
5. **❌ THIẾU ENGAGEMENT SCORE:**
   - Không có field `impact_score` hoặc `virality_score`
   - Không biết comment nào quan trọng hơn (viral vs ít tương tác)

**Schema hiện tại:**
```sql
CREATE TABLE analytics.post_analytics (
    id UUID,
    project_id UUID,
    source_id UUID,
    
    content TEXT,
    content_created_at TIMESTAMPTZ,
    ingested_at TIMESTAMPTZ,
    platform VARCHAR(50),
    
    overall_sentiment VARCHAR(20),        // ✅ OK
    overall_sentiment_score FLOAT,        // ✅ OK
    aspects JSONB,                        // ⚠️ Không có taxonomy
    keywords TEXT[],                      // ✅ OK
    risk_level VARCHAR(20),               // ✅ OK
    
    uap_metadata JSONB,
    
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

---

### 2.4 CONSUMPTION LAYER - Dashboard Requirements

**Dashboard cần hiển thị (theo UC-02):**

| Widget | Data cần | Có sẵn? | Ghi chú |
|--------|----------|---------|---------|
| **Overall sentiment score** | AVG(overall_sentiment_score) | ✅ Có | Query trực tiếp từ post_analytics |
| **Sentiment trend over time** | GROUP BY date, sentiment | ⚠️ CHẬM | Cần bảng aggregation |
| **Aspect breakdown** | COUNT(*) GROUP BY aspect | ❌ THIẾU | aspects là JSONB array, khó query |
| **Top keywords** | COUNT(*) GROUP BY keyword | ⚠️ CHẬM | keywords là TEXT[], cần unnest |
| **Recent mentions** | ORDER BY created_at LIMIT 10 | ✅ Có | OK |
| **Data Source breakdown** | COUNT(*) GROUP BY source_id | ✅ Có | OK |
| **Share of Voice** (Campaign) | COUNT(*) GROUP BY project_id | ✅ Có | OK nhưng cần cache |
| **Sentiment Battle** (Campaign) | Pivot sentiment by project | ⚠️ CHẬM | Cần pre-compute |
| **Aspect Heatmap** (Campaign) | Matrix: aspect x project x sentiment | ❌ THIẾU | Cần bảng riêng |

**❌ VẤN ĐỀ NGHIÊM TRỌNG:**

Dashboard query trực tiếp từ `analytics.post_analytics` (raw data) → **CHẬM** khi có > 100K records.

**Ví dụ query chậm:**
```sql
-- Sentiment trend over time (phải scan toàn bộ bảng)
SELECT 
  DATE_TRUNC('day', content_created_at) as date,
  overall_sentiment,
  COUNT(*) as count
FROM analytics.post_analytics
WHERE project_id = 'xxx'
  AND content_created_at >= NOW() - INTERVAL '30 days'
GROUP BY date, overall_sentiment
ORDER BY date;

-- Aspect breakdown (phải unnest JSONB array)
SELECT 
  aspect->>'aspect' as aspect_name,
  COUNT(*) as count
FROM analytics.post_analytics,
     jsonb_array_elements(aspects) as aspect
WHERE project_id = 'xxx'
GROUP BY aspect_name
ORDER BY count DESC;
```

---

### 2.5 CONSUMPTION LAYER - RAG Requirements

**RAG cần (theo UC-03):**

| Requirement | Data cần | Có sẵn? | Ghi chú |
|-------------|----------|---------|---------|
| **Vector embeddings** | content → vector | ✅ Có | Qdrant |
| **Sentiment filter** | WHERE sentiment = 'NEGATIVE' | ✅ Có | Metadata trong Qdrant |
| **Aspect filter** | WHERE aspect IN ('PRICE', 'SERVICE') | ⚠️ KHÁC | aspects là array, cần flatten |
| **Time range filter** | WHERE created_at BETWEEN ... | ✅ Có | Unix timestamp |
| **Project scope** | WHERE project_id IN (campaign.projects) | ✅ Có | OK |
| **Citations** | Return source_id, platform, author | ⚠️ THIẾU | metadata.author không có structure |

**❌ VẤN ĐỀ:**

1. **Aspect filtering phức tạp:** aspects là JSONB array → Qdrant phải lưu flattened version
2. **Thiếu author info:** Không biết comment từ KOL hay user thường
3. **Thiếu engagement metrics:** Không biết comment nào viral để prioritize trong RAG

---

## 3. ĐỀ XUẤT CẢI TIẾN

### 3.1 CRITICAL - Thêm Aggregation Tables (Dashboard Performance)

**Vấn đề:** Dashboard query raw data → CHẬM.

**Giải pháp:** Pre-compute aggregations vào bảng riêng, update theo batch.

```sql
-- Bảng 1: Daily Sentiment Summary (cho Trend charts)
CREATE TABLE analytics.daily_sentiment_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    date DATE NOT NULL,
    sentiment VARCHAR(20) NOT NULL,
    count INT NOT NULL,
    avg_score FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, date, sentiment)
);

CREATE INDEX idx_daily_sentiment_project_date 
ON analytics.daily_sentiment_summary(project_id, date);

-- Bảng 2: Aspect Summary (cho Aspect breakdown)
CREATE TABLE analytics.aspect_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    aspect VARCHAR(100) NOT NULL,
    sentiment VARCHAR(20) NOT NULL,
    count INT NOT NULL,
    avg_score FLOAT,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, aspect, sentiment, period_start, period_end)
);

CREATE INDEX idx_aspect_summary_project 
ON analytics.aspect_summary(project_id, period_start, period_end);

-- Bảng 3: Campaign Comparison Cache (cho War Room)
CREATE TABLE analytics.campaign_comparison_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- 'share_of_voice', 'sentiment_battle', 'aspect_heatmap'
    metric_data JSONB NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ, -- Cache TTL
    UNIQUE(campaign_id, metric_type, period_start, period_end)
);

CREATE INDEX idx_campaign_cache_id 
ON analytics.campaign_comparison_cache(campaign_id, metric_type);
```

**Update strategy:**
- n8n workflow trigger sau khi batch analytics complete
- Incremental update: chỉ update ngày hiện tại
- Campaign cache: TTL 1 giờ, refresh on-demand

---

### 3.2 HIGH PRIORITY - Aspect Taxonomy & Normalization

**Vấn đề:** aspects là free-text → không consistent, khó query.

**Giải pháp:** Chuẩn hóa aspects theo taxonomy.

```sql
-- Bảng Aspect Categories (Master data)
CREATE TABLE analytics.aspect_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL, -- 'PRICE', 'SERVICE', 'QUALITY'...
    display_name VARCHAR(200) NOT NULL, -- 'Giá cả', 'Dịch vụ', 'Chất lượng'
    description TEXT,
    parent_id UUID REFERENCES analytics.aspect_categories(id), -- Hierarchical
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Aspect Mentions (Normalized)
CREATE TABLE analytics.aspect_mentions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_analytics_id UUID NOT NULL REFERENCES analytics.post_analytics(id),
    aspect_category_id UUID NOT NULL REFERENCES analytics.aspect_categories(id),
    sentiment VARCHAR(20) NOT NULL,
    score FLOAT,
    keywords TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_aspect_mentions_post ON analytics.aspect_mentions(post_analytics_id);
CREATE INDEX idx_aspect_mentions_category ON analytics.aspect_mentions(aspect_category_id);
CREATE INDEX idx_aspect_mentions_sentiment ON analytics.aspect_mentions(sentiment);
```

**Workflow:**
1. AI Worker trả về raw aspect text (VD: "giá cả", "giá", "price")
2. n8n gọi Aspect Normalization Service
3. Map sang aspect_category_id (VD: tất cả → "PRICE")
4. Insert vào `aspect_mentions` table

**Lợi ích:**
- Query aspect breakdown: `SELECT aspect_category_id, COUNT(*) FROM aspect_mentions GROUP BY aspect_category_id`
- Consistent across languages (giá, price → PRICE)
- Hierarchical (PRICE → PRICE_HIGH, PRICE_LOW)

---

### 3.3 MEDIUM PRIORITY - Enhanced UAP Schema

**Vấn đề:** UAP thiếu fields quan trọng.

**Giải pháp:** Extend UAP với structured metadata.

```sql
-- Extend analytics.post_analytics
ALTER TABLE analytics.post_analytics
ADD COLUMN external_id VARCHAR(255),        -- ID từ platform gốc (dedup)
ADD COLUMN content_hash VARCHAR(64),        -- SHA256 của content (dedup)
ADD COLUMN language VARCHAR(10),            -- 'vi', 'en', 'zh'...
ADD COLUMN engagement_metrics JSONB,        -- {likes, shares, views, comments_count}
ADD COLUMN author_info JSONB,               -- {name, id, verified, follower_count}
ADD COLUMN impact_score FLOAT,              -- Calculated: engagement + sentiment weight
ADD COLUMN is_viral BOOLEAN DEFAULT false;  -- Flag for high-impact posts

CREATE UNIQUE INDEX idx_post_external_id ON analytics.post_analytics(external_id);
CREATE INDEX idx_post_content_hash ON analytics.post_analytics(content_hash);
CREATE INDEX idx_post_impact_score ON analytics.post_analytics(impact_score DESC);
```

**engagement_metrics structure:**
```json
{
  "likes": 1500,
  "shares": 200,
  "views": 50000,
  "comments_count": 300,
  "engagement_rate": 0.034  // (likes + shares + comments) / views
}
```

**author_info structure:**
```json
{
  "name": "Nguyễn Văn A",
  "id": "user_12345",
  "verified": true,
  "follower_count": 100000,
  "is_kol": true
}
```

**impact_score calculation:**
```python
impact_score = (
    engagement_rate * 0.4 +
    (1 if is_kol else 0) * 0.3 +
    abs(sentiment_score) * 0.3
)
```

---

### 3.4 MEDIUM PRIORITY - Data Quality Tracking

**Vấn đề:** Không track data quality metrics.

**Giải pháp:** Thêm bảng tracking.

```sql
CREATE TABLE ingest.data_quality_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL REFERENCES ingest.data_sources(id),
    batch_id UUID NOT NULL,
    
    total_records INT NOT NULL,
    valid_records INT NOT NULL,
    invalid_records INT NOT NULL,
    duplicate_records INT NOT NULL,
    
    validation_errors JSONB, -- [{error_type, count, sample}]
    
    processing_time_ms INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quality_source ON ingest.data_quality_metrics(source_id);
```

**Lợi ích:**
- Dashboard hiển thị data quality score
- Alert khi quality drop < threshold
- Debug: xem sample validation errors

---

### 3.5 LOW PRIORITY - Webhook Sample Storage

**Vấn đề:** Webhook không lưu sample payload để user preview.

**Giải pháp:** Lưu sample vào config.

```sql
-- Extend ingest.data_sources
ALTER TABLE ingest.data_sources
ADD COLUMN sample_payloads JSONB; -- Array of sample payloads (max 5)
```

**Workflow:**
- Khi webhook nhận data lần đầu, lưu vào sample_payloads
- UI hiển thị sample để user verify mapping
- Limit 5 samples, FIFO queue

---

## 4. TÓM TẮT ĐỀ XUẤT

### 4.1 Priority Matrix

| Đề xuất | Priority | Impact | Effort | Lý do |
|---------|----------|--------|--------|-------|
| **Aggregation Tables** | 🔴 CRITICAL | Rất cao | Cao | Dashboard chậm nghiêm trọng |
| **Aspect Taxonomy** | 🟠 HIGH | Cao | Trung bình | Aspect query không consistent |
| **Enhanced UAP** | 🟡 MEDIUM | Trung bình | Trung bình | Thiếu engagement, author info |
| **Data Quality Tracking** | 🟡 MEDIUM | Trung bình | Thấp | Monitoring & debugging |
| **Webhook Sample Storage** | 🟢 LOW | Thấp | Thấp | UX improvement |

### 4.2 Implementation Roadmap

**Phase 1 (Tuần 1-2): CRITICAL**
- [ ] Tạo `daily_sentiment_summary` table
- [ ] Tạo `aspect_summary` table
- [ ] Tạo `campaign_comparison_cache` table
- [ ] n8n workflow để update aggregations
- [ ] Update Dashboard queries để dùng aggregation tables

**Phase 2 (Tuần 3-4): HIGH**
- [ ] Tạo `aspect_categories` master data
- [ ] Tạo `aspect_mentions` table
- [ ] Aspect Normalization Service (Python microservice)
- [ ] Integrate vào n8n workflow
- [ ] Migrate existing aspects data

**Phase 3 (Tuần 5-6): MEDIUM**
- [ ] Extend `post_analytics` với new columns
- [ ] Update Ingest Service để extract engagement metrics
- [ ] Impact score calculation logic
- [ ] Data quality tracking tables
- [ ] Quality monitoring dashboard

---

## 5. KẾT LUẬN

### 5.1 Điểm mạnh tổng thể

✅ **Architecture tốt:** UAP canonical model, clear separation of concerns  
✅ **Flexibility:** JSONB cho phép extend dễ dàng  
✅ **Traceability:** Có project_id, source_id để truy vết  
✅ **Time handling:** 2 trường thời gian riêng biệt rõ ràng  

### 5.2 Điểm yếu nghiêm trọng

❌ **Performance:** Dashboard query raw data → CHẬM  
❌ **Aspect inconsistency:** Free-text aspects → khó query, không consistent  
❌ **Missing engagement data:** Không biết post nào quan trọng  
❌ **No aggregations:** Phải tính toán real-time mọi thứ  

### 5.3 Khuyến nghị

**BẮT BUỘC implement trước khi demo:**
1. Aggregation tables (daily_sentiment_summary, aspect_summary)
2. Aspect taxonomy & normalization

**NÊN implement cho production:**
3. Enhanced UAP (engagement_metrics, author_info, impact_score)
4. Data quality tracking

**CÓ THỂ implement sau:**
5. Webhook sample storage
6. Advanced caching strategies

---

**Tổng kết:** Hệ thống có foundation tốt nhưng **THIẾU AGGREGATION LAYER** nghiêm trọng. Dashboard sẽ chậm không chấp nhận được khi scale. Cần implement aggregation tables NGAY trong Phase 1.
