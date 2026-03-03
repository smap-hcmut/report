# Đánh Giá Khả Năng Đáp Ứng Yêu Cầu Nghiệp Vụ - SMAP System

**Ngày đánh giá:** 17/02/2026  
**Phiên bản:** 1.0  
**Người thực hiện:** System Analysis

---

## 📊 TỔNG QUAN ĐÁNH GIÁ

| Nhóm Yêu Cầu | Điểm Đánh Giá | Trạng Thái | Ghi Chú |
|--------------|---------------|------------|---------|
| **Nhóm 1: Crisis & Brand Health** | **75%** | 🟡 Đáp ứng tốt | Thiếu action suggestion tự động |
| **Nhóm 2: Competitor Intelligence** | **80%** | 🟢 Đáp ứng tốt | Thiếu marketing insight |
| **Nhóm 3: Product Feedback** | **95%** | 🟢 Đáp ứng xuất sắc | Gần như hoàn chỉnh |
| **Nhóm 4: Content Optimization** | **55%** | 🔴 Đáp ứng hạn chế | Thiếu trend & format analysis |

**Điểm trung bình:** 76.25%

---

## 📋 CHI TIẾT ĐÁNH GIÁ TỪNG NHÓM

### NHÓM 1: XỬ LÝ KHỦNG HOẢNG & SỨC KHỎE THƯƠNG HIỆU (75%)

#### ✅ **KHẢ NĂNG ĐÁP ỨNG**

##### 1. Tóm tắt lý do (The What)

**Yêu cầu:**
> "Chỉ số giảm 30% chủ yếu do sự gia tăng đột biến các thảo luận tiêu cực liên quan đến khía cạnh 'Dịch vụ Chăm sóc khách hàng'"

**Data có sẵn:**
```json
{
  "overall_sentiment": "NEGATIVE",
  "overall_sentiment_score": -0.45,
  "content_created_at": "2026-02-10T14:30:00Z"
}
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**
- Có sentiment score để tính phần trăm thay đổi
- Có timestamp để aggregate theo thời gian
- RAG có thể query và tổng hợp data theo date range

**Ví dụ query:**
```sql
SELECT 
    DATE(content_created_at) as date,
    AVG(overall_sentiment_score) as avg_score,
    COUNT(*) as volume
FROM analytics.post_analytics
WHERE project_id = 'proj_vf8'
  AND content_created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(content_created_at)
ORDER BY date;
```

##### 2. Chi tiết vấn đề - ABSA

**Yêu cầu:**
> "Cụ thể, có 500 bài viết phàn nàn về việc 'Tổng đài không bắt máy' và 'Nhân viên thái độ lồi lõm'"

**Data có sẵn:**
```json
{
  "aspects": [
    {
      "aspect": "SERVICE",
      "aspect_display_name": "Dịch vụ",
      "sentiment": "NEGATIVE",
      "sentiment_score": -0.72,
      "keywords": ["tổng đài", "không bắt máy", "thái độ"],
      "mentions": [
        {
          "text": "Tổng đài không bắt máy, gọi mãi không được",
          "start_pos": 35,
          "end_pos": 68
        }
      ],
      "confidence": 0.89
    }
  ]
}
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ HOÀN TOÀN**
- Aspect analysis chi tiết với keywords
- Mentions trích xuất chính xác text
- Có thể aggregate: "COUNT posts WHERE aspects contains SERVICE + NEGATIVE"

##### 3. Dẫn chứng với engagement cao

**Yêu cầu:**
> "Đây là 3 bài viết có lượng tương tác cao nhất đang viral: [Link 1], [Link 2], [Link 3]"

**Data có sẵn:**
```json
{
  "engagement_score": 0.73,
  "virality_score": 0.65,
  "influence_score": 0.58,
  "uap_metadata": {
    "engagement": {
      "views": 45000,
      "likes": 3200,
      "comments": 156,
      "shares": 89
    }
  }
}
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**
- Sort by `engagement_score DESC` hoặc `virality_score DESC`
- RAG citations có URL và source info
- Có thể lấy top 3 posts viral nhất

**RAG Response Example:**
```json
{
  "citations": [
    {
      "id": "analytics_001",
      "content": "Tổng đài không bắt máy suốt 3 ngày...",
      "source": {
        "platform": "tiktok",
        "url": "https://tiktok.com/@user/video/123",
        "created_at": "2026-02-10T14:30:00Z"
      },
      "relevance_score": 0.92,
      "engagement": {
        "views": 45000,
        "shares": 89
      }
    }
  ]
}
```

##### 4. Phát hiện khủng hoảng tự động

**Yêu cầu:** Phát hiện sớm và cảnh báo

**Data có sẵn:**
```json
{
  "risk_level": "HIGH",
  "risk_score": 0.78,
  "risk_factors": [
    {
      "factor": "NEGATIVE_SERVICE_FEEDBACK",
      "severity": "HIGH",
      "description": "Phản hồi tiêu cực về dịch vụ có thể ảnh hưởng..."
    }
  ],
  "requires_attention": true,
  "alert_triggered": false
}
```

**Khả năng đáp ứng:** ✅ **CÓ CƠ CHẾ**
- Risk assessment tự động
- Có severity levels: LOW, MEDIUM, HIGH, CRITICAL
- Flag `requires_attention` để filter

#### ❌ **ĐIỂM THIẾU**

##### 1. Đề xuất hành động tự động

**Yêu cầu:**
> "Bạn nên kiểm tra ngay quy trình trực tổng đài và liên hệ xử lý khiếu nại với chủ bài viết số 1"

**Hiện trạng:** ❌ **KHÔNG CÓ**
```
Không có fields:
- suggested_action
- action_plan
- priority_tasks
```

**Giải pháp đề xuất:**
1. **Thêm LLM Prompt Engineering:**
```python
system_prompt = """
Based on the crisis context:
- Risk level: {risk_level}
- Negative aspects: {aspects}
- Volume: {volume}

Generate 3 specific action items with priority.
"""
```

2. **Hoặc thêm Rule-based Engine:**
```python
if risk_level == "HIGH" and aspect == "SERVICE":
    actions = [
        "Kiểm tra quy trình tổng đài",
        "Liên hệ khách hàng có engagement cao nhất",
        "Chuẩn bị báo cáo khủng hoảng"
    ]
```

##### 2. Temporal Aggregation API

**Yêu cầu:** Charts, trends theo thời gian

**Hiện trạng:** ⚠️ **CHƯA RÕ RÀNG**
```
Không thấy API endpoints:
- GET /api/v1/metrics/sentiment-trend?period=daily
- GET /api/v1/dashboard/time-series
```

**Giải pháp:** Cần build Dashboard API riêng hoặc extend Knowledge Service

##### 3. Real-time Alerting

**Hiện trạng:** ⚠️ **CHƯA RÕ**
- Có field `alert_triggered` nhưng không thấy notification flow
- Không rõ webhook/email/Slack integration

**Giải pháp:** Implement Alert Service với Kafka/RabbitMQ

---

### NHÓM 2: PHÂN TÍCH ĐỐI THỦ CẠNH TRANH (80%)

#### ✅ **KHẢ NĂNG ĐÁP ỨNG**

##### 1. So sánh multi-brand trong Campaign

**Yêu cầu:**
> "Người dùng đang phàn nàn điều gì nhiều nhất về [Đối thủ A] trong tháng này?"

**Campaign Structure có sẵn:**
```
Campaign "So sánh Xe điện Q1/2026"
├── Project "Monitor VF8" (VinFast)
│   ├── Data Source: TikTok crawl
│   └── Data Source: Excel feedback
└── Project "Monitor BYD Seal" (BYD)
    ├── Data Source: YouTube crawl
    └── Data Source: Facebook posts
```

**RAG Query Logic:**
```go
// Step 1: Get projects in campaign
projectIDs := GetCampaignProjects("camp_001")
// → ["proj_vf8", "proj_byd"]

// Step 2: Search with filter
searchReq := &qdrant.SearchPoints{
    Filter: &qdrant.Filter{
        Must: []*qdrant.Condition{
            {
                Field: "project_id",
                Match: projectIDs,  // Filter by campaign scope
            },
            {
                Field: "overall_sentiment",
                Match: "NEGATIVE",
            },
        },
    },
}
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ HOÀN TOÀN**

##### 2. ABSA chi tiết + Aggregation

**Yêu cầu:**
> "Giao hàng: 45% thảo luận tiêu cực vì 'Giao quá chậm'"

**API Response có sẵn:**
```json
{
  "aggregations": {
    "by_aspect": {
      "DELIVERY": {
        "POSITIVE": 20,
        "NEGATIVE": 150,
        "total": 170
      }
    }
  }
}
```

**Calculation:**
```
Negative % = 150 / 170 = 88% (chứ không phải 45%)
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**

##### 3. Keyword & Evidence extraction

**Data có sẵn:**
```json
{
  "aspects": [
    {
      "aspect": "DELIVERY",
      "sentiment": "NEGATIVE",
      "keywords": ["giao chậm", "shipper làm móp hàng"],
      "mentions": [
        {
          "text": "Giao quá chậm, đợi 5 ngày mà chưa tới",
          "start_pos": 10,
          "end_pos": 45
        }
      ]
    }
  ]
}
```

**Khả năng đáp ứng:** ✅ **CÓ ĐẦY ĐỦ**

##### 4. So sánh với thương hiệu mình

**Yêu cầu:**
> "Trong khi đó, thương hiệu của bạn đang có 90% phản hồi tích cực về 'Giao hàng nhanh'"

**Query logic:**
```python
# Query 1: Competitor
competitor_delivery = search(
    project_id="proj_competitor",
    aspect="DELIVERY"
)

# Query 2: Own brand
own_delivery = search(
    project_id="proj_own_brand",
    aspect="DELIVERY"
)

# Compare
comparison = compare_metrics(competitor_delivery, own_delivery)
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**

#### ❌ **ĐIỂM THIẾU**

##### 1. Marketing Insight tự động

**Yêu cầu:**
> "Đề xuất chạy một campaign nhấn mạnh vào thông điệp: 'Giao hỏa tốc 2h - Bao bì chống sốc chuẩn quốc tế'"

**Hiện trạng:** ❌ **KHÔNG CÓ**
```json
Không có fields:
{
  "competitive_advantage": [],
  "marketing_suggestion": [],
  "campaign_idea": []
}
```

**Giải pháp đề xuất:**
1. **LLM Prompt cho Marketing Insight:**
```python
prompt = f"""
Competitor weaknesses:
- DELIVERY: 88% negative ("giao chậm")
- PACKAGING: 45% negative ("bao bì lỏng")

Our strengths:
- DELIVERY: 90% positive ("giao nhanh")

Generate marketing campaign message to attract their customers.
"""
```

2. **Template-based Suggestions:**
```python
if competitor_weak_aspect == "DELIVERY" and our_strong_aspect == "DELIVERY":
    suggestion = f"Chạy campaign nhấn mạnh '{our_delivery_strengths}'"
```

##### 2. Competitor Mention trong cùng 1 post

**Hiện trạng:** ⚠️ **CÓ NHƯNG YẾU**
```json
{
  "entities": {
    "brands": ["VinFast", "BYD", "Tesla"]
  }
}
```

**Vấn đề:** Không phân tích comparative sentiment
- VD: "VF8 tốt hơn BYD về thiết kế" → Không extract được "tốt hơn" relation

**Giải pháp:** Thêm Comparative Entity Analysis

---

### NHÓM 3: PHÁT TRIỂN SẢN PHẨM & FEEDBACK (95%) ⭐

#### ✅ **KHẢ NĂNG ĐÁP ỨNG** (Gần như hoàn hảo)

##### 1. Tổng quan sentiment

**Yêu cầu:**
> "Sản phẩm mới nhận được 70% tích cực, nhưng vẫn còn 30% tiêu cực"

**Query Example:**
```sql
SELECT 
    overall_sentiment,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM analytics.post_analytics
WHERE project_id = 'proj_new_product'
GROUP BY overall_sentiment;

-- Result:
-- POSITIVE: 450 (70%)
-- NEGATIVE: 150 (23%)
-- NEUTRAL:  50 (7%)
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ CHÍNH XÁC**

##### 2. Cái họ Thích (Positive Aspects)

**Yêu cầu:**
> "Người dùng cực kỳ yêu thích 'Thiết kế màu sắc' và 'Độ bền pin'"

**Data có sẵn:**
```json
{
  "aspects": [
    {
      "aspect": "DESIGN",
      "sentiment": "POSITIVE",
      "sentiment_score": 0.85,
      "keywords": ["màu đẹp", "thiết kế đẹp", "sang trọng"],
      "impact_score": 0.78
    },
    {
      "aspect": "BATTERY",
      "sentiment": "POSITIVE",
      "sentiment_score": 0.80,
      "keywords": ["pin trâu", "bền pin", "pin lâu"]
    }
  ]
}
```

**Query:**
```sql
SELECT 
    aspect,
    aspect_display_name,
    COUNT(*) as positive_count,
    AVG(sentiment_score) as avg_score
FROM analytics.post_analytics,
     jsonb_to_recordset(aspects) AS a(
         aspect text,
         aspect_display_name text,
         sentiment text,
         sentiment_score float
     )
WHERE sentiment = 'POSITIVE'
GROUP BY aspect, aspect_display_name
ORDER BY positive_count DESC;
```

**Khả năng đáp ứng:** ✅ **HOÀN TOÀN**

##### 3. Cái họ Ghét (Negative Aspects)

**Yêu cầu:**
> "Khía cạnh 'Giá bán' bị cho là quá cao, và 'Mùi hương' bị chê là hơi nồng"

**Data có sẵn:**
```json
{
  "aspects": [
    {
      "aspect": "PRICE",
      "sentiment": "NEGATIVE",
      "sentiment_score": -0.65,
      "keywords": ["giá cao", "đắt", "không xứng"],
      "mentions": [
        {
          "text": "Giá 1.2 tỷ thì hơi cao so với đối thủ",
          "start_pos": 162,
          "end_pos": 213
        }
      ]
    },
    {
      "aspect": "SCENT",
      "sentiment": "NEGATIVE",
      "sentiment_score": -0.70,
      "keywords": ["mùi hắc", "hơi nồng", "mùi khó chịu"]
    }
  ]
}
```

**Khả năng đáp ứng:** ✅ **HOÀN TOÀN**

##### 4. Trích dẫn thực tế với mentions

**Yêu cầu:**
> "Nhiều user nói rằng: 'Màu đẹp nhưng mùi hắc quá, dùng đau đầu'"

**Data có sẵn:**
```json
{
  "aspects": [
    {
      "aspect": "SCENT",
      "mentions": [
        {
          "text": "Màu đẹp nhưng mùi hắc quá, dùng đau đầu",
          "start_pos": 50,
          "end_pos": 88
        }
      ]
    }
  ]
}
```

**RAG Citation:**
```json
{
  "citations": [
    {
      "id": "analytics_123",
      "content": "Mình thích màu sắc lắm, thiết kế đẹp. Nhưng mà mùi hắc quá, dùng được 1 ngày thì đau đầu.",
      "source": {
        "platform": "facebook",
        "author": "Nguyen Thi B",
        "url": "https://facebook.com/..."
      },
      "highlighted_mentions": [
        "Màu đẹp nhưng mùi hắc quá, dùng đau đầu"
      ]
    }
  ]
}
```

**Khả năng đáp ứng:** ✅ **XUẤT SẮC**

#### ⚠️ **ĐIỂM CẢI THIỆN NHỎ**

##### Aspect Priority/Impact

**Hiện có:**
```json
{
  "impact_score": 0.78  // Per aspect
}
```

**Chưa có:** Business impact priority
```
VD: Quality > Price > Design (theo business strategy)
```

**Giải pháp:** Thêm aspect_priority config trong Project settings

---

### NHÓM 4: TỐI ƯU NỘI DUNG (55%) 🔴

#### ✅ **KHẢ NĂNG ĐÁP ỨNG**

##### 1. Từ khóa hot

**Yêu cầu:**
> "Các từ khóa xuất hiện nhiều: 'Lành tính', 'Không cồn', 'Routine tối giản'"

**Data có sẵn:**
```json
{
  "keywords": [
    "lành tính",
    "không cồn",
    "routine tối giản",
    "thành phần tự nhiên"
  ]
}
```

**Aggregation Query:**
```sql
SELECT 
    keyword,
    COUNT(*) as frequency
FROM analytics.post_analytics,
     unnest(keywords) AS keyword
WHERE project_id = 'proj_cosmetics'
  AND content_created_at > NOW() - INTERVAL '7 days'
GROUP BY keyword
ORDER BY frequency DESC
LIMIT 20;
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**

##### 2. Engagement metrics

**Data có sẵn:**
```json
{
  "engagement_score": 0.73,
  "virality_score": 0.65,
  "uap_metadata": {
    "engagement": {
      "views": 45000,
      "likes": 3200,
      "comments": 156,
      "shares": 89
    }
  }
}
```

**Sort posts by engagement:**
```sql
SELECT *
FROM analytics.post_analytics
ORDER BY engagement_score DESC
LIMIT 10;
```

**Khả năng đáp ứng:** ✅ **CÓ THỂ**

#### ❌ **ĐIỂM THIẾU** (Nghiêm trọng)

##### 1. Content Format Classification

**Yêu cầu:**
> "Các bài viết dạng 'Review so sánh' (Comparison Review) và 'Video test sản phẩm thực tế' đang có chỉ số Engagement cao gấp 2 lần dạng ảnh tĩnh"

**Hiện trạng:** ❌ **KHÔNG CÓ**
```json
// Chỉ có:
{
  "platform": "tiktok"  // Không đủ chi tiết
}

// Cần có:
{
  "content_format": "video",
  "content_type": "comparison_review",
  "media_type": "product_demo",
  "duration_seconds": 45,
  "has_comparison": true
}
```

**Impact:** Không trả lời được câu hỏi về format performance

**Giải pháp đề xuất:**

1. **Thêm Content Classification vào Analytics Pipeline:**
```python
# New: Content Format Analyzer
def classify_content_format(uap_record):
    format_analysis = {
        "content_format": None,  # video, image, text, carousel
        "content_type": None,    # review, tutorial, comparison, unboxing
        "media_elements": [],
        "duration_seconds": None,
        "has_comparison": False,
        "visual_elements": []     # product_demo, text_overlay, etc.
    }
    
    # AI-based classification
    if uap_record.platform == "tiktok":
        format_analysis["content_format"] = "video"
        
    # Detect comparison from keywords
    comparison_keywords = ["so sánh", "vs", "khác nhau", "tốt hơn"]
    if any(kw in uap_record.content for kw in comparison_keywords):
        format_analysis["has_comparison"] = True
        format_analysis["content_type"] = "comparison_review"
    
    return format_analysis
```

2. **Update Schema:**
```json
// Add to analytics.post_analytics
{
  "content_metadata": {
    "format": "video",
    "type": "comparison_review",
    "duration": 45,
    "has_comparison": true
  }
}
```

3. **New API Endpoint:**
```
GET /api/v1/dashboard/content-formats
    ?campaign_id=X
    &date_from=2026-02-01
    
Response:
{
  "formats": {
    "video": {
      "count": 450,
      "avg_engagement": 0.85,
      "top_types": ["comparison_review", "tutorial"]
    },
    "image": {
      "count": 200,
      "avg_engagement": 0.42
    }
  }
}
```

##### 2. Trending Topic Detection

**Yêu cầu:**
> "Tuần này, người dùng tương tác mạnh nhất với các nội dung liên quan đến 'Thành phần tự nhiên'"

**Hiện trạng:** ❌ **KHÔNG CÓ**
```json
// Chỉ có static keywords
{
  "keywords": ["lành tính", "không cồn"]
}

// Cần có:
{
  "trending_topics": [
    {
      "topic": "Thành phần tự nhiên",
      "trending_score": 0.85,
      "growth_rate": "+150%",
      "time_period": "week",
      "related_keywords": ["organic", "natural", "lành tính"]
    }
  ]
}
```

**Impact:** Không phát hiện được trending topics theo thời gian

**Giải pháp đề xuất:**

1. **Build Trending Detection Service:**
```python
# New Service: trend-detector

def detect_trending_topics(project_id, time_window="7d"):
    # Step 1: Get keyword frequency in current period
    current_keywords = get_keyword_frequency(
        project_id, 
        date_from=now() - time_window
    )
    
    # Step 2: Get baseline frequency (previous period)
    baseline_keywords = get_keyword_frequency(
        project_id,
        date_from=now() - 2*time_window,
        date_to=now() - time_window
    )
    
    # Step 3: Calculate trending score
    trending = []
    for keyword, current_count in current_keywords.items():
        baseline_count = baseline_keywords.get(keyword, 0)
        
        if baseline_count == 0:
            growth_rate = float('inf')
        else:
            growth_rate = (current_count - baseline_count) / baseline_count
        
        # Trending score = volume * growth * recency_weight
        trending_score = current_count * growth_rate * recency_weight(keyword)
        
        if trending_score > threshold:
            trending.append({
                "keyword": keyword,
                "trending_score": trending_score,
                "growth_rate": f"+{growth_rate*100:.0f}%",
                "current_volume": current_count,
                "baseline_volume": baseline_count
            })
    
    # Step 4: Cluster keywords into topics using embeddings
    topics = cluster_keywords_to_topics(trending)
    
    return topics
```

2. **New API Endpoints:**
```
GET /api/v1/analytics/trending?project_id=X&period=7d

Response:
{
  "trending_topics": [
    {
      "topic": "Thành phần tự nhiên",
      "trending_score": 0.85,
      "growth_rate": "+150%",
      "keywords": ["organic", "natural", "lành tính"],
      "example_posts": [...]
    }
  ]
}
```

##### 3. Content Performance Analysis

**Yêu cầu:** So sánh performance của các loại content

**Hiện trạng:** ❌ **KHÔNG CÓ API**

**Cần có:**
```
GET /api/v1/dashboard/content-performance
    ?campaign_id=X
    &group_by=format
    
Response:
{
  "performance_by_format": {
    "video": {
      "count": 450,
      "avg_engagement_score": 0.85,
      "avg_virality_score": 0.72,
      "total_reach": 5600000
    },
    "image": {
      "count": 200,
      "avg_engagement_score": 0.42,  // ← 2x lower than video
      "avg_virality_score": 0.35,
      "total_reach": 1200000
    }
  },
  "performance_by_type": {
    "comparison_review": {
      "avg_engagement": 0.89,
      "count": 120
    },
    "tutorial": {
      "avg_engagement": 0.78,
      "count": 85
    }
  }
}
```

##### 4. Content Suggestion Engine

**Yêu cầu:**
> "Bạn nên làm một video ngắn so sánh thành phần sản phẩm của bạn với một sản phẩm hóa học khác"

**Hiện trạng:** ❌ **KHÔNG CÓ**

**Giải pháp:**
```python
# New: Content Recommendation Engine

def generate_content_suggestions(campaign_id):
    # Analyze what's working
    top_formats = get_top_performing_formats(campaign_id)
    trending_topics = detect_trending_topics(campaign_id)
    competitor_gaps = find_competitor_content_gaps(campaign_id)
    
    suggestions = []
    
    # Rule 1: Trending topic + Best format
    if "Thành phần tự nhiên" in trending_topics:
        if "video" in top_formats:
            suggestions.append({
                "type": "video",
                "topic": "Thành phần tự nhiên",
                "message": "Làm video ngắn giới thiệu thành phần organic",
                "reasoning": "Video format có engagement cao 2x, topic trending +150%"
            })
    
    # Rule 2: Competitor weakness
    if "comparison_review" in top_formats:
        suggestions.append({
            "type": "comparison_review",
            "message": "So sánh thành phần sản phẩm với đối thủ hóa học",
            "reasoning": "Comparison review có engagement 0.89, đối thủ yếu về này"
        })
    
    return suggestions
```

---

## 🎯 TỔNG KẾT & ROADMAP

### **ĐIỂM MẠNH (Strengths)**

1. ✅ **ABSA (Aspect-Based Sentiment Analysis) xuất sắc**
   - Đầy đủ: aspect, sentiment, keywords, mentions, evidence
   - Trích xuất chính xác vị trí text
   - Confidence scores đáng tin cậy

2. ✅ **RAG Architecture tốt**
   - Campaign-scoped filtering
   - Citation mechanism với source attribution
   - Filter linh hoạt (sentiment, aspect, date, platform)

3. ✅ **Product Feedback hoàn hảo**
   - Nhóm 3 đạt 95% - gần như hoàn chỉnh
   - Có thể trả lời chi tiết "thích gì, ghét gì"
   - Evidence extraction xuất sắc

4. ✅ **Data Structure chuẩn**
   - UAP → Analytics → RAG flow rõ ràng
   - Schema well-designed
   - Có provenance & audit trail

5. ✅ **Multi-brand Comparison**
   - Campaign structure hỗ trợ so sánh nhiều thương hiệu
   - Aggregation API đầy đủ

### **ĐIỂM YẾU (Weaknesses)**

1. ❌ **Content Format Analysis thiếu hoàn toàn**
   - Không classify: video, image, text, comparison_review
   - Không có content_type, media_elements
   - → Không trả lời được "format nào hiệu quả nhất"

2. ❌ **Trending Detection thiếu**
   - Chỉ có static keywords, không có trending_score
   - Không detect hot topics theo thời gian
   - Không có growth_rate analysis

3. ⚠️ **Temporal Aggregation API yếu**
   - Không thấy rõ time-series endpoints
   - Dashboard API chưa đầy đủ
   - Khó vẽ charts/trends

4. ⚠️ **Action Suggestion thiếu**
   - Không tự động đề xuất hành động marketing
   - Không có campaign_idea generator
   - Phụ thuộc vào manual prompt engineering

5. ⚠️ **Content Recommendation thiếu**
   - Không có suggestion engine
   - Không optimize posting strategy

### **ĐIỂM SỐ CHI TIẾT**

| Capability | Status | Score | Note |
|------------|--------|-------|------|
| **Sentiment Analysis** | ✅ Hoàn chỉnh | 100% | Xuất sắc |
| **ABSA (Aspect)** | ✅ Hoàn chỉnh | 100% | Với mentions & evidence |
| **Citation & Evidence** | ✅ Hoàn chỉnh | 95% | RAG citations tốt |
| **Multi-brand Compare** | ✅ Tốt | 85% | Campaign-scoped |
| **Risk Assessment** | ✅ Tốt | 80% | Có basic crisis detection |
| **Action Suggestion** | ⚠️ Yếu | 40% | Cần LLM prompt |
| **Temporal Analysis** | ⚠️ Yếu | 50% | API chưa rõ |
| **Content Format** | ❌ Thiếu | 10% | Không có classification |
| **Trending Detection** | ❌ Thiếu | 20% | Chỉ có static keywords |
| **Content Recommendation** | ❌ Thiếu | 0% | Hoàn toàn không có |

---

## 📅 ROADMAP ĐỀ XUẤT

### **Phase 1: Quick Wins (2-3 tuần)**

**Mục tiêu:** Fix các điểm yếu có thể giải quyết nhanh

1. **Action Suggestion với LLM Prompt** (Nhóm 1, 2)
   ```
   Task: Thêm prompt engineering cho:
   - Crisis action items
   - Marketing campaign suggestions
   
   Effort: 1 tuần
   Impact: Medium
   ```

2. **Dashboard API cho Temporal Aggregation**
   ```
   New endpoints:
   - GET /api/v1/dashboard/sentiment-trend
   - GET /api/v1/dashboard/aspect-breakdown
   
   Effort: 2 tuần
   Impact: High (cho Crisis & Competitor analysis)
   ```

3. **Content Format Field vào UAP Schema**
   ```
   Add fields:
   - content_format: "video" | "image" | "text"
   - Detect từ platform + attachment metadata
   
   Effort: 3 ngày
   Impact: Foundation cho Phase 2
   ```

### **Phase 2: Advanced Analytics (1-2 tháng)**

**Mục tiêu:** Build các service mới cho Nhóm 4

1. **Trending Detection Service**
   ```
   Features:
   - Keyword frequency analysis
   - Growth rate calculation
   - Topic clustering với embeddings
   - Trending score algorithm
   
   Effort: 3 tuần
   Impact: High (Nhóm 4)
   ```

2. **Content Performance Analytics**
   ```
   Features:
   - Format classification (AI-based)
   - Performance comparison by format/type
   - A/B testing insights
   
   Effort: 2 tuần
   Impact: High (Nhóm 4)
   ```

3. **Competitor Comparison Reports**
   ```
   Features:
   - Automated competitor analysis
   - Strength/weakness matrix
   - Market positioning insights
   
   Effort: 2 tuần
   Impact: Medium (Nhóm 2)
   ```

### **Phase 3: AI Recommendations (2-3 tháng)**

**Mục tiêu:** AI-powered insights & automation

1. **Marketing Suggestion Engine**
   ```
   Features:
   - Auto-generate campaign ideas
   - Messaging optimization
   - Targeting recommendations
   
   Technology:
   - LLM-based (GPT-4)
   - Rule-based fallback
   
   Effort: 1 tháng
   Impact: High (Nhóm 2)
   ```

2. **Content Recommendation System**
   ```
   Features:
   - Suggest content topics
   - Optimal format selection
   - Best posting time
   - Hashtag recommendations
   
   Effort: 1 tháng
   Impact: Very High (Nhóm 4)
   ```

3. **Predictive Crisis Detection**
   ```
   Features:
   - ML model predict crisis likelihood
   - Early warning system (thay vì reactive)
   - Automated escalation
   
   Effort: 1.5 tháng
   Impact: High (Nhóm 1)
   ```

---

## 🏁 KẾT LUẬN

### **Hiện trạng Overall:**
Hệ thống SMAP hiện tại **đáp ứng tốt 75-80%** các yêu cầu nghiệp vụ, với điểm mạnh nổi bật về:
- ✅ Product Feedback Analysis (95%)
- ✅ Competitor Intelligence (80%)
- ✅ Crisis Detection cơ bản (75%)

### **Prioritize Development:**

**Quan trọng nhất (Must-have):**
1. Content Format Classification (Nhóm 4)
2. Trending Detection (Nhóm 4)
3. Dashboard API (Nhóm 1)

**Quan trọng (Should-have):**
4. Action Suggestion (Nhóm 1, 2)
5. Content Recommendation (Nhóm 4)

**Tốt nếu có (Nice-to-have):**
6. Predictive Crisis Detection (Nhóm 1)
7. Advanced Competitor Reports (Nhóm 2)

### **ROI Estimate:**

| Phase | Effort | Impact | ROI |
|-------|--------|--------|-----|
| Phase 1 (Quick Wins) | 3 tuần | Medium | **High** ⭐ |
| Phase 2 (Analytics) | 2 tháng | High | **Very High** ⭐⭐ |
| Phase 3 (AI Recs) | 3 tháng | Very High | **Medium** |

**Recommendation:** Focus on Phase 1 + Phase 2 (5 tháng) để đạt 90%+ capability coverage.

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-17  
**Next Review:** 2026-03-17
