# Dashboard API Implementation Plan for Analytics Service

**Ngày tạo:** 19/02/2026  
**Phiên bản:** 1.0  
**Tác giả:** System Architect  
**Ref:** `documents/migration-plan.md` (Section 3.2.4.1)

---

## 1. TỔNG QUAN

Analytics Service hiện tại **CHƯA CÓ** API endpoint để phục vụ Dashboard. Cần implement endpoint mới để Project Service có thể proxy call và lấy insights.

**Vai trò:** Analytics Service là **Insights Provider** - cung cấp dữ liệu phân tích đã được aggregate từ `analytics.post_analytics` (hoặc `schema_analysis.post_insight` theo actual implementation).

**Lưu ý:** Theo `documents/analysis/analysis.md`, actual schema là `schema_analysis.post_insight`, KHÔNG phải `analytics.post_analytics`.

---

## 2. GAP ANALYSIS

### 2.1 Hiện trạng

**Có sẵn:**

- ✅ Database: `schema_analysis.post_insight` với đầy đủ fields
- ✅ ORM Model: `PostInsight` class
- ✅ Repository: CRUD operations
- ✅ Pipeline: UAP input → AI analysis → DB storage
- ✅ Kafka Publisher: Enriched output to `smap.analytics.output`

**Thiếu:**

- ❌ HTTP API endpoint: `GET /analytics/projects/{id}/insights`
- ❌ Aggregation queries: sentiment distribution, top keywords, trends
- ❌ Redis cache layer: cache insights (5 min TTL)
- ❌ Time-range filtering: 7d, 30d, 90d, custom
- ❌ HTTP server setup: FastAPI/Flask routes

### 2.2 So sánh với Master Proposal

| Component   | Master Proposal            | Current Reality                | Gap            |
| ----------- | -------------------------- | ------------------------------ | -------------- |
| Schema name | `analytics.post_analytics` | `schema_analysis.post_insight` | ✅ Naming only |
| Table name  | `post_analytics`           | `post_insight`                 | ✅ Naming only |
| Fields      | 50+ enriched fields        | 50+ enriched fields            | ✅ Match       |
| HTTP API    | Mentioned but not detailed | ❌ Not implemented             | ❌ **MISSING** |
| Cache layer | Not mentioned              | ❌ Not implemented             | ❌ **MISSING** |

---

## 3. IMPLEMENTATION PLAN

### 3.1 New Files to Create

| File                                                | Purpose                             |
| --------------------------------------------------- | ----------------------------------- |
| `internal/dashboard/__init__.py`                    | Dashboard domain module             |
| `internal/dashboard/interface.py`                   | IDashboardUseCase protocol          |
| `internal/dashboard/type.py`                        | Request/Response types              |
| `internal/dashboard/usecase/__init__.py`            | Usecase module                      |
| `internal/dashboard/usecase/new.py`                 | Factory function                    |
| `internal/dashboard/usecase/insights.py`            | Core aggregation logic              |
| `internal/dashboard/delivery/http/__init__.py`      | HTTP delivery module                |
| `internal/dashboard/delivery/http/handler.py`       | FastAPI route handler               |
| `internal/dashboard/delivery/http/presenter.py`     | Response formatter                  |
| `internal/dashboard/repository/postgre/__init__.py` | Repository module                   |
| `internal/dashboard/repository/postgre/insights.py` | Aggregation queries                 |
| `pkg/redis/cache.py`                                | Redis cache wrapper (if not exists) |

### 3.2 Files to Modify

| File                            | Changes                                |
| ------------------------------- | -------------------------------------- |
| `cmd/api/main.py`               | Add dashboard routes                   |
| `config/config.yaml`            | Add Redis config, HTTP server config   |
| `internal/consumer/registry.py` | Register dashboard usecase (if needed) |

---

## 4. DETAILED IMPLEMENTATION

### 4.1 Type Definitions

**File:** `internal/dashboard/type.py`

```python
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from datetime import datetime

@dataclass
class InsightsRequest:
    """Request for project insights."""
    project_id: str
    time_range: str = "7d"  # 7d, 30d, 90d, custom
    start_date: Optional[datetime] = None  # For custom range
    end_date: Optional[datetime] = None

@dataclass
class SentimentDistribution:
    """Sentiment distribution over time."""
    positive: int
    negative: int
    neutral: int
    distribution: List[Dict[str, Any]]  # [{date, positive, negative, neutral}]

@dataclass
class KeywordItem:
    """Top keyword with metadata."""
    keyword: str
    count: int
    sentiment: str  # positive, negative, neutral

@dataclass
class AspectItem:
    """Aspect sentiment breakdown."""
    aspect: str
    positive: int
    negative: int
    neutral: int

@dataclass
class TrendInfo:
    """Trend analysis."""
    sentiment_trend: str  # improving, declining, stable
    volume_trend: str  # increasing, decreasing, stable

@dataclass
class InsightsResponse:
    """Response with aggregated insights."""
    sentiment: SentimentDistribution
    top_keywords: List[KeywordItem]
    aspects: List[AspectItem]
    trends: TrendInfo
    total_records: int
    time_range: str
    generated_at: datetime
```

---

### 4.2 Repository Layer - Aggregation Queries

**File:** `internal/dashboard/repository/postgre/insights.py`

```python
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy import select, func, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession

from internal.model.post_insight import PostInsight

class InsightsRepository:
    """Repository for dashboard insights aggregation."""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_sentiment_distribution(
        self,
        project_id: str,
        start_date: datetime,
        end_date: datetime,
    ) -> Dict[str, Any]:
        """Aggregate sentiment distribution.

        Returns:
            {
                "positive": 45,
                "negative": 32,
                "neutral": 23,
                "distribution": [
                    {"date": "2026-02-13", "positive": 40, "negative": 35, "neutral": 25},
                    ...
                ]
            }
        """
        # Overall counts
        stmt = select(
            PostInsight.overall_sentiment,
            func.count(PostInsight.id).label("count")
        ).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= start_date,
                PostInsight.content_created_at <= end_date,
            )
        ).group_by(PostInsight.overall_sentiment)

        result = await self.session.execute(stmt)
        rows = result.all()

        sentiment_counts = {"positive": 0, "negative": 0, "neutral": 0}
        for row in rows:
            sentiment = row.overall_sentiment.lower() if row.overall_sentiment else "neutral"
            sentiment_counts[sentiment] = row.count

        # Daily distribution
        stmt_daily = select(
            func.date(PostInsight.content_created_at).label("date"),
            PostInsight.overall_sentiment,
            func.count(PostInsight.id).label("count")
        ).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= start_date,
                PostInsight.content_created_at <= end_date,
            )
        ).group_by(
            func.date(PostInsight.content_created_at),
            PostInsight.overall_sentiment
        ).order_by(func.date(PostInsight.content_created_at))

        result_daily = await self.session.execute(stmt_daily)
        rows_daily = result_daily.all()

        # Transform to daily distribution
        daily_map = {}
        for row in rows_daily:
            date_str = row.date.isoformat()
            if date_str not in daily_map:
                daily_map[date_str] = {"date": date_str, "positive": 0, "negative": 0, "neutral": 0}

            sentiment = row.overall_sentiment.lower() if row.overall_sentiment else "neutral"
            daily_map[date_str][sentiment] = row.count

        distribution = list(daily_map.values())

        return {
            "positive": sentiment_counts["positive"],
            "negative": sentiment_counts["negative"],
            "neutral": sentiment_counts["neutral"],
            "distribution": distribution,
        }

    async def get_top_keywords(
        self,
        project_id: str,
        start_date: datetime,
        end_date: datetime,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """Get top keywords with sentiment.

        Returns:
            [
                {"keyword": "xe điện", "count": 450, "sentiment": "neutral"},
                {"keyword": "pin", "count": 320, "sentiment": "negative"},
                ...
            ]
        """
        # Query: unnest keywords array, count occurrences
        # Note: This requires PostgreSQL unnest function

        from sqlalchemy import text

        query = text("""
            SELECT
                keyword,
                COUNT(*) as count,
                MODE() WITHIN GROUP (ORDER BY overall_sentiment) as dominant_sentiment
            FROM schema_analysis.post_insight,
                 unnest(keywords) as keyword
            WHERE project_id = :project_id
              AND content_created_at >= :start_date
              AND content_created_at <= :end_date
            GROUP BY keyword
            ORDER BY count DESC
            LIMIT :limit
        """)

        result = await self.session.execute(
            query,
            {
                "project_id": project_id,
                "start_date": start_date,
                "end_date": end_date,
                "limit": limit,
            }
        )

        rows = result.all()

        return [
            {
                "keyword": row.keyword,
                "count": row.count,
                "sentiment": row.dominant_sentiment.lower() if row.dominant_sentiment else "neutral",
            }
            for row in rows
        ]

    async def get_aspect_breakdown(
        self,
        project_id: str,
        start_date: datetime,
        end_date: datetime,
    ) -> List[Dict[str, Any]]:
        """Get aspect sentiment breakdown.

        Returns:
            [
                {"aspect": "BATTERY", "positive": 20, "negative": 60, "neutral": 20},
                {"aspect": "PRICE", "positive": 10, "negative": 70, "neutral": 20},
                ...
            ]
        """
        # Query: extract aspects from JSONB, aggregate sentiment

        from sqlalchemy import text

        query = text("""
            SELECT
                aspect->>'aspect' as aspect,
                SUM(CASE WHEN aspect->>'polarity' = 'POSITIVE' THEN 1 ELSE 0 END) as positive,
                SUM(CASE WHEN aspect->>'polarity' = 'NEGATIVE' THEN 1 ELSE 0 END) as negative,
                SUM(CASE WHEN aspect->>'polarity' = 'NEUTRAL' THEN 1 ELSE 0 END) as neutral
            FROM schema_analysis.post_insight,
                 jsonb_array_elements(aspects_breakdown->'aspects') as aspect
            WHERE project_id = :project_id
              AND content_created_at >= :start_date
              AND content_created_at <= :end_date
            GROUP BY aspect->>'aspect'
            ORDER BY (positive + negative + neutral) DESC
            LIMIT 10
        """)

        result = await self.session.execute(
            query,
            {
                "project_id": project_id,
                "start_date": start_date,
                "end_date": end_date,
            }
        )

        rows = result.all()

        return [
            {
                "aspect": row.aspect,
                "positive": row.positive,
                "negative": row.negative,
                "neutral": row.neutral,
            }
            for row in rows
        ]

    async def get_total_records(
        self,
        project_id: str,
        start_date: datetime,
        end_date: datetime,
    ) -> int:
        """Get total records count."""
        stmt = select(func.count(PostInsight.id)).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= start_date,
                PostInsight.content_created_at <= end_date,
            )
        )

        result = await self.session.execute(stmt)
        return result.scalar() or 0

    async def calculate_trends(
        self,
        project_id: str,
        start_date: datetime,
        end_date: datetime,
    ) -> Dict[str, str]:
        """Calculate sentiment and volume trends.

        Returns:
            {
                "sentiment_trend": "declining",  # improving, declining, stable
                "volume_trend": "increasing"     # increasing, decreasing, stable
            }
        """
        # Split time range into 2 halves
        mid_date = start_date + (end_date - start_date) / 2

        # First half sentiment
        stmt_first = select(
            func.avg(PostInsight.overall_sentiment_score).label("avg_score")
        ).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= start_date,
                PostInsight.content_created_at < mid_date,
            )
        )

        result_first = await self.session.execute(stmt_first)
        first_avg = result_first.scalar() or 0.0

        # Second half sentiment
        stmt_second = select(
            func.avg(PostInsight.overall_sentiment_score).label("avg_score")
        ).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= mid_date,
                PostInsight.content_created_at <= end_date,
            )
        )

        result_second = await self.session.execute(stmt_second)
        second_avg = result_second.scalar() or 0.0

        # Determine sentiment trend
        sentiment_diff = second_avg - first_avg
        if sentiment_diff > 0.1:
            sentiment_trend = "improving"
        elif sentiment_diff < -0.1:
            sentiment_trend = "declining"
        else:
            sentiment_trend = "stable"

        # Volume trend
        stmt_first_count = select(func.count(PostInsight.id)).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= start_date,
                PostInsight.content_created_at < mid_date,
            )
        )

        result_first_count = await self.session.execute(stmt_first_count)
        first_count = result_first_count.scalar() or 0

        stmt_second_count = select(func.count(PostInsight.id)).where(
            and_(
                PostInsight.project_id == project_id,
                PostInsight.content_created_at >= mid_date,
                PostInsight.content_created_at <= end_date,
            )
        )

        result_second_count = await self.session.execute(stmt_second_count)
        second_count = result_second_count.scalar() or 0

        # Determine volume trend
        if second_count > first_count * 1.2:
            volume_trend = "increasing"
        elif second_count < first_count * 0.8:
            volume_trend = "decreasing"
        else:
            volume_trend = "stable"

        return {
            "sentiment_trend": sentiment_trend,
            "volume_trend": volume_trend,
        }
```

---

### 4.3 UseCase Layer - Business Logic

**File:** `internal/dashboard/usecase/insights.py`

```python
from datetime import datetime, timedelta
from typing import Optional
import json

from internal.dashboard.type import (
    InsightsRequest,
    InsightsResponse,
    SentimentDistribution,
    KeywordItem,
    AspectItem,
    TrendInfo,
)
from internal.dashboard.repository.postgre.insights import InsightsRepository
from pkg.redis.cache import RedisCache

class InsightsUseCase:
    """UseCase for getting project insights."""

    def __init__(
        self,
        repo: InsightsRepository,
        cache: Optional[RedisCache] = None,
    ):
        self.repo = repo
        self.cache = cache

    async def get_insights(self, request: InsightsRequest) -> InsightsResponse:
        """Get project insights with caching.

        Args:
            request: Insights request

        Returns:
            Aggregated insights
        """
        # Check cache first
        if self.cache:
            cache_key = f"insights:{request.project_id}:{request.time_range}"
            cached = await self.cache.get(cache_key)
            if cached:
                return self._deserialize_response(cached)

        # Calculate date range
        start_date, end_date = self._parse_time_range(request)

        # Aggregate data from DB
        sentiment_data = await self.repo.get_sentiment_distribution(
            request.project_id,
            start_date,
            end_date,
        )

        keywords_data = await self.repo.get_top_keywords(
            request.project_id,
            start_date,
            end_date,
            limit=10,
        )

        aspects_data = await self.repo.get_aspect_breakdown(
            request.project_id,
            start_date,
            end_date,
        )

        trends_data = await self.repo.calculate_trends(
            request.project_id,
            start_date,
            end_date,
        )

        total_records = await self.repo.get_total_records(
            request.project_id,
            start_date,
            end_date,
        )

        # Build response
        response = InsightsResponse(
            sentiment=SentimentDistribution(
                positive=sentiment_data["positive"],
                negative=sentiment_data["negative"],
                neutral=sentiment_data["neutral"],
                distribution=sentiment_data["distribution"],
            ),
            top_keywords=[
                KeywordItem(
                    keyword=kw["keyword"],
                    count=kw["count"],
                    sentiment=kw["sentiment"],
                )
                for kw in keywords_data
            ],
            aspects=[
                AspectItem(
                    aspect=asp["aspect"],
                    positive=asp["positive"],
                    negative=asp["negative"],
                    neutral=asp["neutral"],
                )
                for asp in aspects_data
            ],
            trends=TrendInfo(
                sentiment_trend=trends_data["sentiment_trend"],
                volume_trend=trends_data["volume_trend"],
            ),
            total_records=total_records,
            time_range=request.time_range,
            generated_at=datetime.utcnow(),
        )

        # Cache result (5 min TTL)
        if self.cache:
            await self.cache.set(
                cache_key,
                self._serialize_response(response),
                ttl=300,  # 5 minutes
            )

        return response

    def _parse_time_range(self, request: InsightsRequest) -> tuple[datetime, datetime]:
        """Parse time range string to start/end dates."""
        end_date = datetime.utcnow()

        if request.time_range == "7d":
            start_date = end_date - timedelta(days=7)
        elif request.time_range == "30d":
            start_date = end_date - timedelta(days=30)
        elif request.time_range == "90d":
            start_date = end_date - timedelta(days=90)
        elif request.time_range == "custom":
            if not request.start_date or not request.end_date:
                raise ValueError("start_date and end_date required for custom range")
            start_date = request.start_date
            end_date = request.end_date
        else:
            # Default to 7 days
            start_date = end_date - timedelta(days=7)

        return start_date, end_date

    def _serialize_response(self, response: InsightsResponse) -> str:
        """Serialize response to JSON string for caching."""
        return json.dumps({
            "sentiment": {
                "positive": response.sentiment.positive,
                "negative": response.sentiment.negative,
                "neutral": response.sentiment.neutral,
                "distribution": response.sentiment.distribution,
            },
            "top_keywords": [
                {"keyword": kw.keyword, "count": kw.count, "sentiment": kw.sentiment}
                for kw in response.top_keywords
            ],
            "aspects": [
                {"aspect": asp.aspect, "positive": asp.positive, "negative": asp.negative, "neutral": asp.neutral}
                for asp in response.aspects
            ],
            "trends": {
                "sentiment_trend": response.trends.sentiment_trend,
                "volume_trend": response.trends.volume_trend,
            },
            "total_records": response.total_records,
            "time_range": response.time_range,
            "generated_at": response.generated_at.isoformat(),
        })

    def _deserialize_response(self, data: str) -> InsightsResponse:
        """Deserialize JSON string to response object."""
        obj = json.loads(data)
        return InsightsResponse(
            sentiment=SentimentDistribution(
                positive=obj["sentiment"]["positive"],
                negative=obj["sentiment"]["negative"],
                neutral=obj["sentiment"]["neutral"],
                distribution=obj["sentiment"]["distribution"],
            ),
            top_keywords=[
                KeywordItem(keyword=kw["keyword"], count=kw["count"], sentiment=kw["sentiment"])
                for kw in obj["top_keywords"]
            ],
            aspects=[
                AspectItem(aspect=asp["aspect"], positive=asp["positive"], negative=asp["negative"], neutral=asp["neutral"])
                for asp in obj["aspects"]
            ],
            trends=TrendInfo(
                sentiment_trend=obj["trends"]["sentiment_trend"],
                volume_trend=obj["trends"]["volume_trend"],
            ),
            total_records=obj["total_records"],
            time_range=obj["time_range"],
            generated_at=datetime.fromisoformat(obj["generated_at"]),
        )
```

---

### 4.4 HTTP Handler - FastAPI Route

**File:** `internal/dashboard/delivery/http/handler.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional

from internal.dashboard.type import InsightsRequest
from internal.dashboard.usecase.insights import InsightsUseCase
from internal.dashboard.delivery.http.presenter import present_insights

router = APIRouter(prefix="/analytics", tags=["analytics"])

@router.get("/projects/{project_id}/insights")
async def get_project_insights(
    project_id: str,
    time_range: str = "7d",
    usecase: InsightsUseCase = Depends(get_insights_usecase),
):
    """Get project insights for dashboard.

    Args:
        project_id: Project ID
        time_range: Time range (7d, 30d, 90d, custom)

    Returns:
        Aggregated insights JSON

    Example:
        GET /analytics/projects/proj_vf8/insights?time_range=7d
    """
    try:
        request = InsightsRequest(
            project_id=project_id,
            time_range=time_range,
        )

        response = await usecase.get_insights(request)

        return present_insights(response)

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

def get_insights_usecase() -> InsightsUseCase:
    """Dependency injection for insights usecase."""
    # TODO: Implement dependency injection
    # This should be injected from registry
    pass
```

**File:** `internal/dashboard/delivery/http/presenter.py`

```python
from internal.dashboard.type import InsightsResponse

def present_insights(response: InsightsResponse) -> dict:
    """Present insights response as JSON dict.

    Args:
        response: InsightsResponse object

    Returns:
        JSON-serializable dict
    """
    return {
        "sentiment": {
            "positive": response.sentiment.positive,
            "negative": response.sentiment.negative,
            "neutral": response.sentiment.neutral,
            "distribution": response.sentiment.distribution,
        },
        "top_keywords": [
            {
                "keyword": kw.keyword,
                "count": kw.count,
                "sentiment": kw.sentiment,
            }
            for kw in response.top_keywords
        ],
        "aspects": [
            {
                "aspect": asp.aspect,
                "positive": asp.positive,
                "negative": asp.negative,
                "neutral": asp.neutral,
            }
            for asp in response.aspects
        ],
        "trends": {
            "sentiment_trend": response.trends.sentiment_trend,
            "volume_trend": response.trends.volume_trend,
        },
        "total_records": response.total_records,
        "time_range": response.time_range,
        "generated_at": response.generated_at.isoformat(),
    }
```

---

### 4.5 Redis Cache Wrapper

**File:** `pkg/redis/cache.py` (if not exists)

```python
from typing import Optional
import aioredis

class RedisCache:
    """Redis cache wrapper."""

    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.redis: Optional[aioredis.Redis] = None

    async def connect(self):
        """Connect to Redis."""
        self.redis = await aioredis.from_url(self.redis_url)

    async def get(self, key: str) -> Optional[str]:
        """Get value from cache."""
        if not self.redis:
            return None
        return await self.redis.get(key)

    async def set(self, key: str, value: str, ttl: int):
        """Set value in cache with TTL."""
        if not self.redis:
            return
        await self.redis.setex(key, ttl, value)

    async def delete(self, key: str):
        """Delete key from cache."""
        if not self.redis:
            return
        await self.redis.delete(key)

    async def close(self):
        """Close Redis connection."""
        if self.redis:
            await self.redis.close()
```

---

## 5. CONFIGURATION

**File:** `config/config.yaml`

```yaml
# Add Redis configuration
redis:
  url: "redis://172.16.21.200:6379/0"
  cache_ttl: 300 # 5 minutes

# Add HTTP server configuration (if not exists)
http:
  host: "0.0.0.0"
  port: 8000
  workers: 4
```

---

## 6. INTEGRATION WITH MAIN APP

**File:** `cmd/api/main.py`

```python
from fastapi import FastAPI
from internal.dashboard.delivery.http.handler import router as dashboard_router

app = FastAPI(title="Analytics Service API")

# Register dashboard routes
app.include_router(dashboard_router)

# ... other routes ...

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## 7. TESTING STRATEGY

### 7.1 Unit Tests

- [ ] Test `InsightsRepository.get_sentiment_distribution()`
- [ ] Test `InsightsRepository.get_top_keywords()`
- [ ] Test `InsightsRepository.get_aspect_breakdown()`
- [ ] Test `InsightsRepository.calculate_trends()`
- [ ] Test `InsightsUseCase.get_insights()` with cache hit
- [ ] Test `InsightsUseCase.get_insights()` with cache miss
- [ ] Test `InsightsUseCase._parse_time_range()` for all ranges

### 7.2 Integration Tests

- [ ] Test HTTP endpoint `GET /analytics/projects/{id}/insights`
- [ ] Test with different time ranges (7d, 30d, 90d)
- [ ] Test cache behavior (first call vs second call)
- [ ] Test error handling (invalid project_id, DB error)

### 7.3 Performance Tests

- [ ] Measure query performance with 10K records
- [ ] Measure query performance with 100K records
- [ ] Measure cache hit rate
- [ ] Measure API response time (target: < 500ms)

---

## 8. DEPLOYMENT CHECKLIST

- [ ] Create Redis instance (if not exists)
- [ ] Update `config/config.yaml` with Redis URL
- [ ] Run database migrations (if needed)
- [ ] Deploy Analytics Service with new HTTP API
- [ ] Test endpoint manually: `curl http://analytics-service:8000/analytics/projects/proj_vf8/insights?time_range=7d`
- [ ] Update Project Service to call new endpoint
- [ ] Monitor logs and metrics
- [ ] Verify cache hit rate in Redis

---

## 9. ESTIMATED EFFORT

| Task               | Effort  | Owner         |
| ------------------ | ------- | ------------- |
| Type definitions   | 1h      | Dev           |
| Repository queries | 4h      | Dev           |
| UseCase logic      | 2h      | Dev           |
| HTTP handler       | 2h      | Dev           |
| Redis cache        | 1h      | Dev           |
| Integration        | 2h      | Dev           |
| Testing            | 4h      | Dev           |
| Documentation      | 1h      | Dev           |
| **Total**          | **17h** | **~2-3 days** |

---

## 10. RISKS & MITIGATIONS

| Risk                   | Impact | Mitigation                                           |
| ---------------------- | ------ | ---------------------------------------------------- |
| Query performance slow | HIGH   | Add indexes on `project_id`, `content_created_at`    |
| Redis unavailable      | MEDIUM | Graceful degradation (skip cache, query DB directly) |
| Large result sets      | MEDIUM | Implement pagination, limit top keywords/aspects     |
| Time zone issues       | LOW    | Always use UTC in DB, convert in presentation layer  |

---

## 11. POST-IMPLEMENTATION

After implementation:

1. Update `documents/analysis/analysis.md` - mark Dashboard API as COMPLETED
2. Update API documentation (Swagger/OpenAPI)
3. Create runbook for operations team
4. Monitor performance metrics (query time, cache hit rate)
5. Gather feedback from Project Service team

---

**END OF PLAN**
