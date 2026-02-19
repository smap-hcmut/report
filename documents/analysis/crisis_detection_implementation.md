# Analytics Service - Crisis Detection Implementation

**Service:** analytics-srv  
**Language:** Python (FastAPI)  
**Purpose:** Detect crisis based on configured rules  
**Ngày tạo:** 19/02/2026

---

## 1. OVERVIEW

Analytics Service thực thi crisis detection logic:
1. Consume crisis config từ Project Service
2. Analyze UAP data (sentiment, keywords, volume, influencer)
3. Check against configured triggers
4. Publish alert nếu detect crisis

---

## 2. DATA FLOW

```
[Project Service] Update crisis config
    → Publish: project.crisis_config.updated
    ↓
[Analytics Service] Cache config in memory/Redis
    ↓
[Analytics Service - UAP Consumer]
    → Consume: smap.collector.output
    → Analyze & Store: schema_analysis.post_insight
    ↓
[Analytics Service - Crisis Detector Background Job]
    Every 5 minutes:
    1. Load crisis configs for all active projects
    2. Query recent data (last 5 min)
    3. Check each trigger type
    4. If detected → Publish: analytics.crisis.detected
```

---

## 3. CRISIS CONFIG CACHE

### 3.1 Consumer: project.crisis_config.updated

```python
# internal/consumers/crisis_config_consumer.py

from typing import Dict
import json

class CrisisConfigConsumer:
    """Consumer for crisis config updates."""
    
    def __init__(self, cache: CrisisConfigCache, logger):
        self.cache = cache
        self.logger = logger
    
    async def handle_message(self, message: dict):
        """Handle crisis config update event."""
        project_id = message["project_id"]
        config = message["config"]
        
        self.logger.info(f"Received crisis config update for project {project_id}")
        
        # Update cache
        await self.cache.set(project_id, config)
        
        self.logger.info(f"Crisis config cached for project {project_id}")
```

### 3.2 Config Cache (Redis)

```python
# internal/crisis/cache.py

import json
from typing import Optional, Dict
from redis import Redis

class CrisisConfigCache:
    """Cache for crisis configs."""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
        self.key_prefix = "crisis_config:"
        self.ttl = 3600  # 1 hour
    
    async def set(self, project_id: str, config: dict):
        """Cache crisis config."""
        key = f"{self.key_prefix}{project_id}"
        value = json.dumps(config)
        self.redis.setex(key, self.ttl, value)
    
    async def get(self, project_id: str) -> Optional[dict]:
        """Get cached crisis config."""
        key = f"{self.key_prefix}{project_id}"
        value = self.redis.get(key)
        
        if value:
            return json.loads(value)
        return None
    
    async def get_all_active(self) -> Dict[str, dict]:
        """Get all cached configs."""
        pattern = f"{self.key_prefix}*"
        keys = self.redis.keys(pattern)
        
        configs = {}
        for key in keys:
            project_id = key.decode().replace(self.key_prefix, "")
            value = self.redis.get(key)
            if value:
                configs[project_id] = json.loads(value)
        
        return configs
```

---

## 4. CRISIS DETECTOR BACKGROUND JOB

### 4.1 Main Loop

```python
# internal/crisis/detector.py

import asyncio
from datetime import datetime, timedelta
from typing import List, Dict

class CrisisDetector:
    """Background job to detect crisis."""
    
    def __init__(
        self,
        config_cache: CrisisConfigCache,
        repo: PostInsightRepository,
        kafka_producer: KafkaProducer,
        logger,
    ):
        self.config_cache = config_cache
        self.repo = repo
        self.kafka_producer = kafka_producer
        self.logger = logger
        self.running = False
    
    async def start(self):
        """Start the detector loop."""
        self.running = True
        self.logger.info("Crisis detector started")
        
        while self.running:
            try:
                await self.detect_crisis()
                
                # Sleep 5 minutes
                await asyncio.sleep(300)
            
            except Exception as e:
                self.logger.error(f"Crisis detector error: {e}")
                await asyncio.sleep(60)  # Retry after 1 min
    
    async def stop(self):
        """Stop the detector loop."""
        self.running = False
        self.logger.info("Crisis detector stopped")
    
    async def detect_crisis(self):
        """Main detection logic."""
        # 1. Load all active crisis configs
        configs = await self.config_cache.get_all_active()
        
        if not configs:
            self.logger.debug("No crisis configs found")
            return
        
        self.logger.info(f"Checking crisis for {len(configs)} projects")
        
        # 2. Check each project
        for project_id, config in configs.items():
            try:
                await self.check_project(project_id, config)
            except Exception as e:
                self.logger.error(f"Failed to check project {project_id}: {e}")
    
    async def check_project(self, project_id: str, config: dict):
        """Check crisis for a single project."""
        triggers = config.get("triggers", {})
        
        # Get recent data (last 5 minutes)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=5)
        
        data = await self.repo.get_recent_data(
            project_id=project_id,
            start_time=start_time,
            end_time=end_time,
        )
        
        if not data:
            self.logger.debug(f"No recent data for project {project_id}")
            return
        
        # Check each trigger
        alerts = []
        
        if triggers.get("keywords_trigger", {}).get("enabled"):
            alert = await self.check_keywords_trigger(
                project_id, data, triggers["keywords_trigger"]
            )
            if alert:
                alerts.append(alert)
        
        if triggers.get("volume_trigger", {}).get("enabled"):
            alert = await self.check_volume_trigger(
                project_id, data, triggers["volume_trigger"]
            )
            if alert:
                alerts.append(alert)
        
        if triggers.get("sentiment_trigger", {}).get("enabled"):
            alert = await self.check_sentiment_trigger(
                project_id, data, triggers["sentiment_trigger"]
            )
            if alert:
                alerts.append(alert)
        
        if triggers.get("influencer_trigger", {}).get("enabled"):
            alert = await self.check_influencer_trigger(
                project_id, data, triggers["influencer_trigger"]
            )
            if alert:
                alerts.append(alert)
        
        # Publish alerts
        for alert in alerts:
            await self.publish_alert(alert)
```

### 4.2 Keywords Trigger

```python
async def check_keywords_trigger(
    self,
    project_id: str,
    data: List[dict],
    trigger_config: dict,
) -> Optional[dict]:
    """Check keywords trigger."""
    groups = trigger_config.get("groups", [])
    
    matched_posts = []
    max_weight = 0
    
    for post in data:
        content = post.get("content", "").lower()
        
        for group in groups:
            keywords = group.get("keywords", [])
            weight = group.get("weight", 1)
            
            # Check if any keyword matches
            for keyword in keywords:
                if keyword.lower() in content:
                    matched_posts.append({
                        "id": post["id"],
                        "content": post["content"],
                        "keyword": keyword,
                        "weight": weight,
                        "sentiment": post.get("overall_sentiment"),
                    })
                    max_weight = max(max_weight, weight)
                    break
    
    # Trigger if found critical keywords
    if matched_posts and max_weight >= 10:
        severity = "CRITICAL" if max_weight >= 15 else "HIGH"
        
        return {
            "project_id": project_id,
            "source_id": matched_posts[0].get("source_id"),
            "trigger_type": "keywords_trigger",
            "severity": severity,
            "metrics": {
                "matched_count": len(matched_posts),
                "max_weight": max_weight,
            },
            "matched_rules": [
                {
                    "rule_type": "keywords",
                    "matched_keywords": list(set([p["keyword"] for p in matched_posts])),
                }
            ],
            "sample_posts": matched_posts[:5],
            "detected_at": datetime.utcnow(),
        }
    
    return None
```

### 4.3 Sentiment Trigger

```python
async def check_sentiment_trigger(
    self,
    project_id: str,
    data: List[dict],
    trigger_config: dict,
) -> Optional[dict]:
    """Check sentiment trigger."""
    min_sample_size = trigger_config.get("min_sample_size", 50)
    
    if len(data) < min_sample_size:
        return None
    
    # Calculate sentiment distribution
    sentiment_counts = {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0}
    for post in data:
        sentiment = post.get("overall_sentiment", "NEUTRAL")
        sentiment_counts[sentiment] += 1
    
    total = len(data)
    negative_ratio = sentiment_counts["NEGATIVE"] / total
    
    # Check negative ratio rule
    rules = trigger_config.get("rules", [])
    for rule in rules:
        if rule["type"] == "negative_ratio":
            threshold = rule["threshold_percent"] / 100
            
            if negative_ratio > threshold:
                # Get negative posts
                negative_posts = [
                    p for p in data
                    if p.get("overall_sentiment") == "NEGATIVE"
                ]
                
                return {
                    "project_id": project_id,
                    "source_id": data[0].get("source_id"),
                    "trigger_type": "sentiment_trigger",
                    "severity": "CRITICAL" if negative_ratio > 0.4 else "HIGH",
                    "metrics": {
                        "negative_ratio": negative_ratio,
                        "positive_ratio": sentiment_counts["POSITIVE"] / total,
                        "neutral_ratio": sentiment_counts["NEUTRAL"] / total,
                        "sample_size": total,
                        "time_window": "last_5min",
                    },
                    "matched_rules": [
                        {
                            "rule_type": "negative_ratio",
                            "threshold": threshold,
                            "actual_value": negative_ratio,
                            "exceeded_by": negative_ratio - threshold,
                        }
                    ],
                    "sample_posts": [
                        {
                            "id": p["id"],
                            "content": p["content"],
                            "sentiment": p["overall_sentiment"],
                            "sentiment_score": p.get("overall_sentiment_score"),
                            "aspects": p.get("aspects", []),
                        }
                        for p in negative_posts[:5]
                    ],
                    "detected_at": datetime.utcnow(),
                }
    
    return None
```

### 4.4 Volume Trigger

```python
async def check_volume_trigger(
    self,
    project_id: str,
    data: List[dict],
    trigger_config: dict,
) -> Optional[dict]:
    """Check volume trigger."""
    current_count = len(data)
    
    rules = trigger_config.get("rules", [])
    for rule in rules:
        comparison_window_hours = rule["comparison_window_hours"]
        threshold_percent = rule["threshold_percent_growth"]
        baseline_type = rule.get("baseline", "average_last_7_days")
        
        # Get baseline count
        baseline_count = await self.get_baseline_volume(
            project_id,
            comparison_window_hours,
            baseline_type,
        )
        
        if baseline_count == 0:
            continue
        
        # Calculate growth
        growth_percent = ((current_count - baseline_count) / baseline_count) * 100
        
        if growth_percent > threshold_percent:
            return {
                "project_id": project_id,
                "source_id": data[0].get("source_id"),
                "trigger_type": "volume_trigger",
                "severity": rule["level"],
                "metrics": {
                    "current_count": current_count,
                    "baseline_count": baseline_count,
                    "growth_percent": growth_percent,
                    "time_window": f"last_{comparison_window_hours}h",
                },
                "matched_rules": [
                    {
                        "rule_type": "volume_growth",
                        "threshold": threshold_percent,
                        "actual_value": growth_percent,
                        "exceeded_by": growth_percent - threshold_percent,
                    }
                ],
                "sample_posts": [
                    {
                        "id": p["id"],
                        "content": p["content"],
                        "created_at": p["content_created_at"],
                    }
                    for p in data[:5]
                ],
                "detected_at": datetime.utcnow(),
            }
    
    return None

async def get_baseline_volume(
    self,
    project_id: str,
    window_hours: int,
    baseline_type: str,
) -> int:
    """Get baseline volume for comparison."""
    if baseline_type == "average_last_7_days":
        # Get average count for same time window in last 7 days
        counts = []
        for day in range(1, 8):
            start = datetime.utcnow() - timedelta(days=day, hours=window_hours)
            end = datetime.utcnow() - timedelta(days=day)
            count = await self.repo.count_posts(project_id, start, end)
            counts.append(count)
        return sum(counts) // len(counts) if counts else 0
    
    elif baseline_type == "average_last_24_hours":
        start = datetime.utcnow() - timedelta(hours=24 + window_hours)
        end = datetime.utcnow() - timedelta(hours=24)
        return await self.repo.count_posts(project_id, start, end)
    
    return 0
```

### 4.5 Publish Alert

```python
async def publish_alert(self, alert: dict):
    """Publish crisis alert to Kafka."""
    # Generate alert ID
    alert["alert_id"] = f"alert_{uuid.uuid4().hex[:12]}"
    
    # Publish to Kafka
    await self.kafka_producer.send_json(
        topic="analytics.crisis.detected",
        value=alert,
        key=alert["project_id"],
    )
    
    self.logger.warning(
        f"Crisis detected: project={alert['project_id']}, "
        f"trigger={alert['trigger_type']}, severity={alert['severity']}"
    )
```

---

## 5. REPOSITORY QUERIES

```python
# internal/repository/post_insight.py

class PostInsightRepository:
    """Repository for post insights."""
    
    async def get_recent_data(
        self,
        project_id: str,
        start_time: datetime,
        end_time: datetime,
    ) -> List[dict]:
        """Get recent posts for crisis detection."""
        query = """
            SELECT 
                id, source_id, content,
                overall_sentiment, overall_sentiment_score,
                aspects, keywords,
                content_created_at, analyzed_at
            FROM schema_analysis.post_insight
            WHERE 
                project_id = :project_id
                AND analyzed_at >= :start_time
                AND analyzed_at < :end_time
            ORDER BY analyzed_at DESC
        """
        
        result = await self.db.fetch_all(
            query,
            {"project_id": project_id, "start_time": start_time, "end_time": end_time},
        )
        
        return [dict(row) for row in result]
    
    async def count_posts(
        self,
        project_id: str,
        start_time: datetime,
        end_time: datetime,
    ) -> int:
        """Count posts in time range."""
        query = """
            SELECT COUNT(*) as count
            FROM schema_analysis.post_insight
            WHERE 
                project_id = :project_id
                AND analyzed_at >= :start_time
                AND analyzed_at < :end_time
        """
        
        result = await self.db.fetch_one(
            query,
            {"project_id": project_id, "start_time": start_time, "end_time": end_time},
        )
        
        return result["count"] if result else 0
```

---

## 6. TESTING

```python
# tests/test_crisis_detector.py

import pytest
from datetime import datetime, timedelta

@pytest.mark.asyncio
async def test_sentiment_trigger():
    detector = setup_detector()
    
    # Create test data with 50% negative
    data = [
        {"id": f"post_{i}", "content": "test", "overall_sentiment": "NEGATIVE"}
        for i in range(50)
    ] + [
        {"id": f"post_{i}", "content": "test", "overall_sentiment": "POSITIVE"}
        for i in range(50)
    ]
    
    config = {
        "enabled": True,
        "min_sample_size": 50,
        "rules": [
            {"type": "negative_ratio", "threshold_percent": 30}
        ]
    }
    
    # Should trigger (50% > 30%)
    alert = await detector.check_sentiment_trigger("proj_1", data, config)
    
    assert alert is not None
    assert alert["trigger_type"] == "sentiment_trigger"
    assert alert["severity"] in ["HIGH", "CRITICAL"]
    assert alert["metrics"]["negative_ratio"] == 0.5
```

---

## 7. DEPLOYMENT

```yaml
# config.yaml
crisis_detector:
  enabled: true
  interval_seconds: 300  # 5 minutes
  min_sample_size: 50

redis:
  host: redis
  port: 6379
  db: 1  # Separate DB for crisis configs

kafka:
  topics:
    crisis_config_updated: project.crisis_config.updated
    crisis_detected: analytics.crisis.detected
```

---

**Last Updated:** 19/02/2026  
**Author:** System Architect
