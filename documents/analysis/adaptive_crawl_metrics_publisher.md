# Adaptive Crawl Metrics Publisher - Implementation Plan

**Ngày tạo:** 19/02/2026  
**Phiên bản:** 1.0  
**Tác giả:** System Architect  
**Ref:** `documents/migration-plan.md` (Section 3.2.3)

---

## 1. TỔNG QUAN

Analytics Service hiện tại **CHƯA IMPLEMENT** việc publish metrics để trigger Adaptive Crawl. Cần implement background job để:

1. Aggregate metrics per source (mỗi 1-5 phút)
2. Detect significant changes (negative ratio spike, velocity increase)
3. Publish to Kafka topic `analytics.metrics.aggregated`
4. Project Service consume và quyết định switch crawl mode

---

## 2. KIẾN TRÚC TỔNG THỂ

```
┌─────────────────────────────────────────────────────────────────┐
│              ADAPTIVE CRAWL FEEDBACK LOOP                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Analytics Service - Background Job]                           │
│      - Every 1-5 minutes: Aggregate metrics per source          │
│      - Calculate: negative_ratio, velocity, new_items_count     │
│      - Detect significant changes (> threshold)                 │
│      - Publish: analytics.metrics.aggregated                    │
│      ↓                                                          │
│  [Kafka Topic: analytics.metrics.aggregated]                    │
│      Payload: {                                                 │
│        source_id: "src_tiktok_01",                              │
│        new_items_count: 50,                                     │
│        negative_ratio: 0.45,                                    │
│        velocity: 50,  // items/hour                             │
│        timestamp: "2026-02-19T10:30:00Z"                        │
│      }                                                          │
│      ↓                                                          │
│  [Project Service - Adaptive Scheduler]                         │
│      - Consume: analytics.metrics.aggregated                    │
│      - Load baseline: avg_negative_ratio = 0.12                 │
│      - Compare: 0.45 >> 0.12 → CRISIS!                          │
│      - Update data_source:                                      │
│          crawl_mode: NORMAL → CRISIS                            │
│          crawl_interval: 15min → 2min                           │
│      - Publish: project.crisis.started                          │
│      ↓                                                          │
│  [Ingest Service]                                               │
│      - Consume: project.crisis.started                          │
│      - Cancel old schedule (15min)                              │
│      - Schedule new job (2min)                                  │
│      - Trigger crawl IMMEDIATELY                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. PAYLOAD DEFINITION

### 3.1 Kafka Topic

**Topic:** `analytics.metrics.aggregated`

**Payload Structure:**

```json
{
  "source_id": "src_tiktok_01",
  "project_id": "proj_vf8",
  "new_items_count": 50,
  "negative_ratio": 0.45,
  "positive_ratio": 0.3,
  "neutral_ratio": 0.25,
  "velocity": 50,
  "avg_sentiment_score": -0.35,
  "time_window": "last_5min",
  "timestamp": "2026-02-19T10:30:00Z"
}
```

**Field Definitions:**

| Field                 | Type   | Description                       | Example                |
| --------------------- | ------ | --------------------------------- | ---------------------- |
| `source_id`           | string | Data source ID                    | "src_tiktok_01"        |
| `project_id`          | string | Project ID                        | "proj_vf8"             |
| `new_items_count`     | int    | New records in time window        | 50                     |
| `negative_ratio`      | float  | % negative sentiment (0-1)        | 0.45 (45%)             |
| `positive_ratio`      | float  | % positive sentiment (0-1)        | 0.30 (30%)             |
| `neutral_ratio`       | float  | % neutral sentiment (0-1)         | 0.25 (25%)             |
| `velocity`            | float  | Items per hour                    | 50.0                   |
| `avg_sentiment_score` | float  | Average sentiment score (-1 to 1) | -0.35                  |
| `time_window`         | string | Aggregation window                | "last_5min"            |
| `timestamp`           | string | ISO8601 UTC timestamp             | "2026-02-19T10:30:00Z" |

---

## 4. IMPLEMENTATION DETAILS

### 4.1 Background Job - Metrics Aggregator

**File:** `internal/metrics_aggregator/__init__.py` (NEW MODULE)

**Structure:**

```
internal/metrics_aggregator/
├── __init__.py
├── interface.py          # IMetricsAggregator protocol
├── type.py               # SourceMetrics dataclass
├── usecase/
│   ├── __init__.py
│   ├── new.py            # Factory
│   └── aggregator.py     # Core logic
└── delivery/
    └── scheduler/
        ├── __init__.py
        └── job.py        # Background job runner
```

### 4.2 Type Definitions

**File:** `internal/metrics_aggregator/type.py`

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class SourceMetrics:
    """Aggregated metrics for a data source."""
    source_id: str
    project_id: str
    new_items_count: int
    negative_ratio: float  # 0.0 - 1.0
    positive_ratio: float
    neutral_ratio: float
    velocity: float  # items per hour
    avg_sentiment_score: float  # -1.0 to 1.0
    time_window: str  # "last_5min", "last_1hour", etc.
    timestamp: datetime

@dataclass
class AggregationConfig:
    """Configuration for metrics aggregation."""
    time_window_minutes: int = 5  # Aggregate last 5 minutes
    publish_threshold: float = 0.05  # Publish if change > 5%
    min_items_threshold: int = 5  # Minimum items to publish
```

---

### 4.3 Repository Layer - Aggregation Queries

**File:** `internal/metrics_aggregator/repository/postgre/metrics.py`

```python
from typing import List, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from internal.model.post_insight import PostInsight

class MetricsRepository:
    """Repository for metrics aggregation queries."""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def aggregate_source_metrics(
        self,
        source_id: str,
        time_window_minutes: int,
    ) -> Dict[str, Any]:
        """Aggregate metrics for a source in time window.

        Args:
            source_id: Data source ID
            time_window_minutes: Time window in minutes

        Returns:
            {
                "new_items_count": 50,
                "negative_ratio": 0.45,
                "positive_ratio": 0.30,
                "neutral_ratio": 0.25,
                "avg_sentiment_score": -0.35,
            }
        """
        start_time = datetime.utcnow() - timedelta(minutes=time_window_minutes)

        # Count by sentiment
        stmt = select(
            PostInsight.overall_sentiment,
            func.count(PostInsight.id).label("count"),
            func.avg(PostInsight.overall_sentiment_score).label("avg_score"),
        ).where(
            and_(
                PostInsight.source_id == source_id,
                PostInsight.analyzed_at >= start_time,
            )
        ).group_by(PostInsight.overall_sentiment)

        result = await self.session.execute(stmt)
        rows = result.all()

        # Calculate ratios
        sentiment_counts = {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0}
        total_count = 0
        total_score = 0.0

        for row in rows:
            sentiment = row.overall_sentiment or "NEUTRAL"
            count = row.count
            sentiment_counts[sentiment] = count
            total_count += count
            total_score += (row.avg_score or 0.0) * count

        if total_count == 0:
            return {
                "new_items_count": 0,
                "negative_ratio": 0.0,
                "positive_ratio": 0.0,
                "neutral_ratio": 0.0,
                "avg_sentiment_score": 0.0,
            }

        return {
            "new_items_count": total_count,
            "negative_ratio": sentiment_counts["NEGATIVE"] / total_count,
            "positive_ratio": sentiment_counts["POSITIVE"] / total_count,
            "neutral_ratio": sentiment_counts["NEUTRAL"] / total_count,
            "avg_sentiment_score": total_score / total_count,
        }

    async def get_active_sources(self) -> List[str]:
        """Get list of active source IDs.

        Returns:
            List of source IDs that have data in last 24 hours
        """
        start_time = datetime.utcnow() - timedelta(hours=24)

        stmt = select(PostInsight.source_id).where(
            PostInsight.analyzed_at >= start_time
        ).distinct()

        result = await self.session.execute(stmt)
        rows = result.all()

        return [row.source_id for row in rows]
```

---

### 4.4 UseCase Layer - Metrics Aggregator

**File:** `internal/metrics_aggregator/usecase/aggregator.py`

```python
from datetime import datetime
from typing import List, Optional
import asyncio

from internal.metrics_aggregator.type import SourceMetrics, AggregationConfig
from internal.metrics_aggregator.repository.postgre.metrics import MetricsRepository
from pkg.kafka.producer import KafkaProducer

class MetricsAggregator:
    """UseCase for aggregating and publishing source metrics."""

    def __init__(
        self,
        repo: MetricsRepository,
        kafka_producer: KafkaProducer,
        config: AggregationConfig,
        logger: Optional[Any] = None,
    ):
        self.repo = repo
        self.kafka_producer = kafka_producer
        self.config = config
        self.logger = logger

        # Cache previous metrics for change detection
        self.previous_metrics: Dict[str, SourceMetrics] = {}

    async def aggregate_and_publish_all(self):
        """Aggregate metrics for all active sources and publish if significant change."""
        try:
            # Get all active sources
            source_ids = await self.repo.get_active_sources()

            if self.logger:
                self.logger.info(f"Aggregating metrics for {len(source_ids)} sources")

            # Aggregate each source
            for source_id in source_ids:
                try:
                    await self.aggregate_and_publish_source(source_id)
                except Exception as e:
                    if self.logger:
                        self.logger.error(f"Failed to aggregate source {source_id}: {e}")

        except Exception as e:
            if self.logger:
                self.logger.error(f"Failed to aggregate metrics: {e}")

    async def aggregate_and_publish_source(self, source_id: str):
        """Aggregate metrics for a single source and publish if needed.

        Args:
            source_id: Data source ID
        """
        # Aggregate metrics
        metrics_data = await self.repo.aggregate_source_metrics(
            source_id,
            self.config.time_window_minutes,
        )

        # Skip if no new items
        if metrics_data["new_items_count"] < self.config.min_items_threshold:
            return

        # Build metrics object
        # Note: project_id should be fetched from data_sources table
        # For now, we'll extract from source_id or query separately
        project_id = await self._get_project_id(source_id)

        current_metrics = SourceMetrics(
            source_id=source_id,
            project_id=project_id,
            new_items_count=metrics_data["new_items_count"],
            negative_ratio=metrics_data["negative_ratio"],
            positive_ratio=metrics_data["positive_ratio"],
            neutral_ratio=metrics_data["neutral_ratio"],
            velocity=self._calculate_velocity(
                metrics_data["new_items_count"],
                self.config.time_window_minutes,
            ),
            avg_sentiment_score=metrics_data["avg_sentiment_score"],
            time_window=f"last_{self.config.time_window_minutes}min",
            timestamp=datetime.utcnow(),
        )

        # Check if should publish (significant change detected)
        if self._should_publish(source_id, current_metrics):
            await self._publish_metrics(current_metrics)

            # Update cache
            self.previous_metrics[source_id] = current_metrics

    def _should_publish(self, source_id: str, current: SourceMetrics) -> bool:
        """Determine if metrics should be published.

        Publish if:
        1. First time seeing this source
        2. Negative ratio increased significantly (> threshold)
        3. Velocity increased significantly (> 2x)

        Args:
            source_id: Data source ID
            current: Current metrics

        Returns:
            True if should publish
        """
        # Always publish first time
        if source_id not in self.previous_metrics:
            return True

        previous = self.previous_metrics[source_id]

        # Check negative ratio spike
        negative_change = current.negative_ratio - previous.negative_ratio
        if negative_change > self.config.publish_threshold:
            if self.logger:
                self.logger.info(
                    f"Source {source_id}: Negative ratio spike detected "
                    f"({previous.negative_ratio:.2f} → {current.negative_ratio:.2f})"
                )
            return True

        # Check velocity spike
        if previous.velocity > 0:
            velocity_ratio = current.velocity / previous.velocity
            if velocity_ratio > 2.0:
                if self.logger:
                    self.logger.info(
                        f"Source {source_id}: Velocity spike detected "
                        f"({previous.velocity:.1f} → {current.velocity:.1f} items/hour)"
                    )
                return True

        # Check crisis threshold (absolute)
        if current.negative_ratio > 0.30:
            if self.logger:
                self.logger.warning(
                    f"Source {source_id}: Crisis threshold exceeded "
                    f"(negative_ratio={current.negative_ratio:.2f})"
                )
            return True

        return False

    async def _publish_metrics(self, metrics: SourceMetrics):
        """Publish metrics to Kafka.

        Args:
            metrics: Source metrics to publish
        """
        payload = {
            "source_id": metrics.source_id,
            "project_id": metrics.project_id,
            "new_items_count": metrics.new_items_count,
            "negative_ratio": metrics.negative_ratio,
            "positive_ratio": metrics.positive_ratio,
            "neutral_ratio": metrics.neutral_ratio,
            "velocity": metrics.velocity,
            "avg_sentiment_score": metrics.avg_sentiment_score,
            "time_window": metrics.time_window,
            "timestamp": metrics.timestamp.isoformat(),
        }

        await self.kafka_producer.send_json(
            topic="analytics.metrics.aggregated",
            value=payload,
            key=metrics.source_id,
        )

        if self.logger:
            self.logger.info(
                f"Published metrics for source {metrics.source_id}: "
                f"negative_ratio={metrics.negative_ratio:.2f}, "
                f"velocity={metrics.velocity:.1f}"
            )

    def _calculate_velocity(self, items_count: int, time_window_minutes: int) -> float:
        """Calculate velocity (items per hour).

        Args:
            items_count: Number of items
            time_window_minutes: Time window in minutes

        Returns:
            Items per hour
        """
        if time_window_minutes == 0:
            return 0.0
        return (items_count / time_window_minutes) * 60.0

    async def _get_project_id(self, source_id: str) -> str:
        """Get project ID for a source.

        TODO: Query from data_sources table or cache
        For now, extract from source_id pattern or return placeholder

        Args:
            source_id: Data source ID

        Returns:
            Project ID
        """
        # Placeholder implementation
        # In production, should query: SELECT project_id FROM ingest.data_sources WHERE id = source_id
        return "proj_unknown"
```

---

### 4.5 Background Job Scheduler

**File:** `internal/metrics_aggregator/delivery/scheduler/job.py`

```python
import asyncio
from datetime import datetime

from internal.metrics_aggregator.usecase.aggregator import MetricsAggregator

class MetricsAggregatorJob:
    """Background job to run metrics aggregation periodically."""

    def __init__(
        self,
        aggregator: MetricsAggregator,
        interval_minutes: int = 5,
        logger: Optional[Any] = None,
    ):
        self.aggregator = aggregator
        self.interval_minutes = interval_minutes
        self.logger = logger
        self.running = False

    async def start(self):
        """Start the background job."""
        self.running = True

        if self.logger:
            self.logger.info(
                f"Starting metrics aggregator job (interval: {self.interval_minutes} min)"
            )

        while self.running:
            try:
                start_time = datetime.utcnow()

                # Run aggregation
                await self.aggregator.aggregate_and_publish_all()

                # Calculate elapsed time
                elapsed = (datetime.utcnow() - start_time).total_seconds()

                if self.logger:
                    self.logger.info(f"Metrics aggregation completed in {elapsed:.2f}s")

                # Sleep until next interval
                sleep_time = (self.interval_minutes * 60) - elapsed
                if sleep_time > 0:
                    await asyncio.sleep(sleep_time)

            except Exception as e:
                if self.logger:
                    self.logger.error(f"Metrics aggregation job error: {e}")

                # Sleep before retry
                await asyncio.sleep(60)

    async def stop(self):
        """Stop the background job."""
        self.running = False

        if self.logger:
            self.logger.info("Stopping metrics aggregator job")
```

---

### 4.6 Integration with Main App

**File:** `cmd/consumer/main.py` (or separate `cmd/metrics_aggregator/main.py`)

```python
import asyncio
from internal.metrics_aggregator.usecase.aggregator import MetricsAggregator
from internal.metrics_aggregator.delivery.scheduler.job import MetricsAggregatorJob
from internal.metrics_aggregator.type import AggregationConfig
# ... other imports ...

async def main():
    # ... existing setup ...

    # Create metrics aggregator
    metrics_repo = MetricsRepository(db_session)
    metrics_aggregator = MetricsAggregator(
        repo=metrics_repo,
        kafka_producer=kafka_producer,
        config=AggregationConfig(
            time_window_minutes=5,
            publish_threshold=0.05,
            min_items_threshold=5,
        ),
        logger=logger,
    )

    # Start background job
    metrics_job = MetricsAggregatorJob(
        aggregator=metrics_aggregator,
        interval_minutes=5,
        logger=logger,
    )

    # Run job in background
    asyncio.create_task(metrics_job.start())

    # ... existing consumer loop ...

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 5. PROJECT SERVICE - ADAPTIVE SCHEDULER

**Vai trò:** Consume metrics từ Analytics và quyết định switch crawl mode.

**Domain:** `/scheduler` module trong Project Service

**File:** `internal/scheduler/adaptive.go` (Go code)

```go
// Project Service - internal/scheduler/adaptive.go

package scheduler

type AdaptiveScheduler struct {
    repo          DataSourceRepository
    kafkaProducer KafkaProducer
    logger        Logger
}

// ProcessMetrics - Consume analytics.metrics.aggregated
func (s *AdaptiveScheduler) ProcessMetrics(ctx context.Context, msg MetricsMessage) error {
    // 1. Get source with baseline
    source, err := s.repo.GetByID(ctx, msg.SourceID)
    if err != nil {
        return fmt.Errorf("failed to get source: %w", err)
    }

    // 2. Load baseline metrics (7-day average)
    baseline, err := s.repo.GetBaselineMetrics(ctx, msg.SourceID)
    if err != nil {
        s.logger.Warnf("No baseline for source %s, using defaults", msg.SourceID)
        baseline = DefaultBaseline()
    }

    // 3. Determine new crawl mode
    newMode := s.determineMode(msg, baseline)

    // 4. If mode changed, update and publish event
    if newMode != source.CrawlMode {
        interval := s.getIntervalForMode(newMode)
        reason := s.getModeChangeReason(msg, baseline, newMode)

        s.logger.Infof(
            "Source %s mode change: %s → %s (reason: %s)",
            msg.SourceID, source.CrawlMode, newMode, reason,
        )

        // Update database
        err := s.repo.UpdateCrawlMode(ctx, source.ID, UpdateCrawlModeInput{
            CrawlMode:        newMode,
            CrawlInterval:    interval,
            NextCrawlAt:      time.Now().Add(time.Duration(interval) * time.Minute),
            ModeChangeReason: reason,
            ModeChangedAt:    time.Now(),
        })

        if err != nil {
            return fmt.Errorf("failed to update crawl mode: %w", err)
        }

        // Publish event
        if newMode == CrawlModeCrisis {
            s.kafkaProducer.Publish(ctx, "project.crisis.started", CrisisEvent{
                ProjectID: source.ProjectID,
                SourceID:  source.ID,
                Metrics: CrisisMetrics{
                    NegativeRatio:      msg.NegativeRatio,
                    Velocity:           msg.Velocity,
                    AvgSentimentScore:  msg.AvgSentimentScore,
                },
                Severity: s.calculateSeverity(msg, baseline),
                Reason:   reason,
            })
        } else if source.CrawlMode == CrawlModeCrisis && newMode == CrawlModeNormal {
            s.kafkaProducer.Publish(ctx, "project.crisis.resolved", CrisisResolvedEvent{
                ProjectID: source.ProjectID,
                SourceID:  source.ID,
            })
        }
    }

    // 5. Update last crawl metrics (for next comparison)
    s.repo.UpdateLastCrawlMetrics(ctx, source.ID, msg)

    return nil
}

// determineMode - Decision logic for crawl mode
func (s *AdaptiveScheduler) determineMode(
    current MetricsMessage,
    baseline BaselineMetrics,
) CrawlMode {
    // CRISIS detection (highest priority)

    // Rule 1: Absolute negative ratio > 30%
    if current.NegativeRatio > 0.30 {
        return CrawlModeCrisis
    }

    // Rule 2: Negative ratio spike (> 3x baseline)
    if baseline.AvgNegativeRatio > 0 {
        ratio := current.NegativeRatio / baseline.AvgNegativeRatio
        if ratio > 3.0 {
            return CrawlModeCrisis
        }
    }

    // Rule 3: Velocity spike (> 2x baseline)
    if baseline.AvgVelocity > 0 {
        velocityRatio := current.Velocity / baseline.AvgVelocity
        if velocityRatio > 2.0 && current.NegativeRatio > 0.20 {
            return CrawlModeCrisis
        }
    }

    // SLEEP detection (lowest priority)

    // Rule 4: Very few new items
    if current.NewItemsCount < 5 {
        return CrawlModeSleep
    }

    // Rule 5: Low velocity
    if current.Velocity < 10.0 {  // < 10 items/hour
        return CrawlModeSleep
    }

    // Default: NORMAL mode
    return CrawlModeNormal
}

func (s *AdaptiveScheduler) getIntervalForMode(mode CrawlMode) int {
    switch mode {
    case CrawlModeCrisis:
        return 2  // 2 minutes
    case CrawlModeNormal:
        return 15  // 15 minutes
    case CrawlModeSleep:
        return 60  // 60 minutes
    default:
        return 15
    }
}

func (s *AdaptiveScheduler) getModeChangeReason(
    current MetricsMessage,
    baseline BaselineMetrics,
    newMode CrawlMode,
) string {
    switch newMode {
    case CrawlModeCrisis:
        if current.NegativeRatio > 0.30 {
            return fmt.Sprintf(
                "Negative ratio %.1f%% exceeds crisis threshold 30%%",
                current.NegativeRatio*100,
            )
        }
        if baseline.AvgNegativeRatio > 0 {
            ratio := current.NegativeRatio / baseline.AvgNegativeRatio
            if ratio > 3.0 {
                return fmt.Sprintf(
                    "Negative ratio spike: %.1f%% (%.1fx baseline %.1f%%)",
                    current.NegativeRatio*100, ratio, baseline.AvgNegativeRatio*100,
                )
            }
        }
        return "Crisis detected"

    case CrawlModeSleep:
        return fmt.Sprintf(
            "Low activity: %d items, %.1f items/hour",
            current.NewItemsCount, current.Velocity,
        )

    case CrawlModeNormal:
        return "Normal activity resumed"

    default:
        return "Mode change"
    }
}

func (s *AdaptiveScheduler) calculateSeverity(
    current MetricsMessage,
    baseline BaselineMetrics,
) string {
    if current.NegativeRatio > 0.50 {
        return "CRITICAL"
    }
    if current.NegativeRatio > 0.40 {
        return "HIGH"
    }
    if current.NegativeRatio > 0.30 {
        return "MEDIUM"
    }
    return "LOW"
}
```

---

## 6. TESTING STRATEGY

### 6.1 Unit Tests (Analytics Service)

- [ ] Test `MetricsRepository.aggregate_source_metrics()` with various data
- [ ] Test `MetricsAggregator._should_publish()` with different scenarios
- [ ] Test `MetricsAggregator._calculate_velocity()`
- [ ] Test change detection logic (negative ratio spike, velocity spike)

### 6.2 Integration Tests

- [ ] Test end-to-end: Insert records → Aggregate → Publish to Kafka
- [ ] Test with no new items (should not publish)
- [ ] Test with crisis threshold (should publish)
- [ ] Test with velocity spike (should publish)

### 6.3 Project Service Tests

- [ ] Test `AdaptiveScheduler.determineMode()` with various metrics
- [ ] Test mode transitions (NORMAL → CRISIS → NORMAL)
- [ ] Test Kafka event publishing (crisis.started, crisis.resolved)

---

## 7. DEPLOYMENT CHECKLIST

- [ ] Create Kafka topic `analytics.metrics.aggregated`
- [ ] Deploy Analytics Service with background job
- [ ] Deploy Project Service with Adaptive Scheduler consumer
- [ ] Monitor Kafka lag and message flow
- [ ] Test with real data (trigger crisis manually)
- [ ] Verify Ingest Service responds to crisis events

---

## 8. MONITORING & ALERTS

**Metrics to track:**

- Metrics aggregation job execution time
- Number of sources aggregated per run
- Number of metrics published per run
- Crisis events triggered per day
- Mode change frequency per source

**Alerts:**

- Alert if metrics job fails > 3 times
- Alert if no metrics published for > 1 hour
- Alert if crisis mode lasts > 2 hours

---

## 9. ESTIMATED EFFORT

| Task                     | Effort  | Owner         |
| ------------------------ | ------- | ------------- |
| Type definitions         | 1h      | Dev           |
| Repository queries       | 2h      | Dev           |
| UseCase logic            | 3h      | Dev           |
| Background job           | 2h      | Dev           |
| Integration              | 2h      | Dev           |
| Project Service consumer | 4h      | Dev           |
| Testing                  | 4h      | Dev           |
| Documentation            | 1h      | Dev           |
| **Total**                | **19h** | **~2-3 days** |

---

**END OF PLAN**
