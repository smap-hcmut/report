# SMAP Event Contracts

**Ngày cập nhật:** 2026-04-13  
**Tài liệu nền:** [2-state-machine.md](/Users/phongdang/Documents/GitHub/SMAP/2-state-machine.md), [4-implementation-gap-checklist.md](/Users/phongdang/Documents/GitHub/SMAP/4-implementation-gap-checklist.md)

## 1. Mục tiêu

Tài liệu này chốt:

- `event names`
- `producer`
- `consumer`
- `topic`
- `purpose`
- `when_emitted`
- `minimum_payload`

Đây là contract theo **target architecture**, nhưng sẽ ghi chú rõ chỗ nào là current source và chỗ nào là future/target-only.

## 2. Quy ước chung

### 2.1 Envelope tối thiểu

Mọi event business nên có envelope tối thiểu:

```json
{
  "event_name": "project.activated",
  "event_id": "uuid",
  "event_version": "1.0",
  "occurred_at": "2026-04-05T10:00:00Z",
  "source": "project-srv",
  "trace_id": "uuid",
  "payload": {}
}
```

### 2.2 Nguyên tắc

- `event_name` mô tả sự kiện đã xảy ra
- `payload` chỉ chứa business/runtime context cần thiết cho consumer
- event phải idempotent theo `event_id`
- nếu event là command-like thì vẫn nên đặt tên rõ ý định, không mơ hồ
- `domain_type_code` phải đi kèm ở các flow ảnh hưởng analysis

## 3. Contract Groups

## 3.1 Project lifecycle events

### `project.activated`

- Producer: `project-srv`
- Consumer: `ingest-srv`
- Topic: `project.lifecycle`
- Purpose: đồng bộ business activation sang execution plane
- When emitted: ngay sau khi project chuyển `PENDING -> ACTIVE`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "status": "ACTIVE"
}
```

### `project.paused`

- Producer: `project-srv`
- Consumer: `ingest-srv`
- Topic: `project.lifecycle`
- Purpose: yêu cầu pause execution
- When emitted: ngay sau khi project chuyển `ACTIVE -> PAUSED`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "status": "PAUSED"
}
```

### `project.resumed`

- Producer: `project-srv`
- Consumer: `ingest-srv`
- Topic: `project.lifecycle`
- Purpose: yêu cầu resume execution
- When emitted: ngay sau khi project chuyển `PAUSED -> ACTIVE`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "status": "ACTIVE"
}
```

### `project.archived`

- Producer: `project-srv`
- Consumer: `ingest-srv`
- Topic: `project.lifecycle`
- Purpose: stop execution and move runtime into safe archived/pause path
- When emitted: ngay sau khi project chuyển sang `ARCHIVED`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "status": "ARCHIVED"
}
```

## 3.2 Project -> Ingest crisis control

### `project.crawl_mode.change_requested`

- Producer: `project-srv`
- Consumer: `ingest-srv`
- Topic: `project.control`
- Purpose: điều chỉnh crawl policy theo business state
- When emitted:
  - khi project vào crisis
  - khi project resolve crisis
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "requested_crawl_mode": "CRISIS",
  "reason": "crisis_started",
  "crisis_state": "CRISIS"
}
```

### Alternative business events

Nếu muốn business-semantics rõ hơn, có thể dùng thêm:

#### `project.crisis.started`

- Producer: `project-srv`
- Consumer: `ingest-srv`, `noti-srv`
- Topic: `project.crisis`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "crisis_state": "CRISIS",
  "trigger_signal_id": "uuid"
}
```

#### `project.crisis.resolved`

- Producer: `project-srv`
- Consumer: `ingest-srv`, `noti-srv`
- Topic: `project.crisis`
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "crisis_state": "NORMAL",
  "reason": "crisis_exit_rules_passed"
}
```

### Khuyến nghị

Khuyến nghị dùng cả hai lớp:

- business event:
  - `project.crisis.started`
  - `project.crisis.resolved`
- technical control event:
  - `project.crawl_mode.change_requested`

Business event giúp audit và notification sạch hơn. Control event giúp execution rõ ý định hơn.

## 3.3 Ingest -> Analysis

## Current UAP topic

### `smap.collector.output`

- Producer: `ingest-srv`
- Consumer: `analysis-srv`
- Topic: `smap.collector.output`
- Purpose: phát UAP canonical downstream cho analysis
- When emitted: sau khi raw batch parse thành UAP record

### Future rename option

`uap.record.created` có thể giữ như target/future event name nếu sau này muốn topic/event naming rõ hơn. Không coi đây là current source topic.

### Minimum payload

Payload là UAP record canonical. Tối thiểu phải có:

```json
{
  "identity": {
    "uap_id": "uuid",
    "origin_id": "platform_post_id",
    "uap_type": "post",
    "platform": "TIKTOK",
    "project_id": "uuid"
  },
  "content": {
    "text": "..."
  },
  "temporal": {
    "ingested_at": "2026-04-05T10:00:00Z"
  },
  "domain_type_code": "beer_vn",
  "crawl_keyword": "bia thủ công"
}
```

### Bắt buộc

- `project_id`
- `domain_type_code`
- `crawl_keyword`

### Note quan trọng

Current source hiện tại:

- `ingest-srv` đã emit UAP canonical mới
- `analysis-srv` đã có parser cho ingest flat format qua `UAPRecord.from_ingest_record`
- `analysis-srv` đã route domain bằng `domain_type_code`

Phần còn lại cần làm là hardening/test/parity, không phải build parser/domain routing từ đầu.

## 3.4 Analysis -> Project

### `analysis.signal.computed`

- Producer: `analysis-srv`
- Consumer: `project-srv`
- Topic: `analysis.signal`
- Purpose: phát signal định kỳ hoặc sau mỗi processing window để project đánh giá crisis state
- When emitted: sau khi analysis tính xong signal cho project/window
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "window_start": "2026-04-05T09:00:00Z",
  "window_end": "2026-04-05T10:00:00Z",
  "negative_ratio": 0.42,
  "risk_score": 0.83,
  "volume": 188,
  "top_issues": ["giá cao", "mùi vị", "khuyến mãi gây hiểu lầm"]
}
```

### `analysis.crisis.candidate_detected`

- Producer: `analysis-srv`
- Consumer: `project-srv`
- Topic: `analysis.crisis`
- Purpose: optional fast-path signal khi risk spike rất mạnh
- When emitted: khi vượt ngưỡng candidate crisis
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "candidate_level": "HIGH",
  "risk_score": 0.94,
  "signal_id": "uuid"
}
```

### Khuyến nghị

- `analysis.signal.computed` là event bắt buộc
- `analysis.crisis.candidate_detected` là optional fast-path

Không nên để `analysis-srv` tự chốt final crisis state nếu đi theo phương án khuyến nghị.

### Ghi chú nghiệp vụ

Contract chỉ biểu diễn `crisis_state` tối giản:

- `NORMAL`
- `CRISIS`

Các cơ chế tránh bật/tắt liên tục là business rules ở `project-srv`, không phải additional crisis states trong payload.

## 3.5 Analysis -> Knowledge

## Layer 3

### `analytics.batch.completed`

- Producer: `analysis-srv`
- Consumer: `knowledge-srv`
- Topic: `analytics.batch.completed`
- Purpose: gửi enriched post-level materials cho indexing
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "batch_id": "uuid",
  "posts": []
}
```

## Layer 2

### `analytics.insights.published`

- Producer: `analysis-srv`
- Consumer: `knowledge-srv`
- Topic: `analytics.insights.published`
- Purpose: gửi insight cards/aggregated insights
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "run_id": "uuid",
  "insights": []
}
```

## Layer 1

### `analytics.report.digest`

- Producer: `analysis-srv`
- Consumer: `knowledge-srv`
- Topic: `analytics.report.digest`
- Purpose: gửi digest/report-level summary
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "run_id": "uuid",
  "top_entities": [],
  "top_topics": [],
  "top_issues": []
}
```

### Note

`knowledge-srv` docs đã expect 3 topic này. Current source của `analysis-srv` cũng có active constants/publisher cho 3 topic này. `smap.analytics.output` chỉ còn xuất hiện như stale legacy docstring trong `analysis-srv/internal/model/insight_message.py`, không nên coi là active contract.

## 3.6 Project/Analysis -> Notification

### `project.alert.negative_detected`

- Producer: `project-srv` hoặc `analysis-srv`
- Consumer: `noti-srv`
- Topic: `project.alert`
- Purpose: notify user khi có negative signal đáng chú ý
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "alert_type": "NEGATIVE_SPIKE",
  "severity": "MEDIUM",
  "message": "Negative discussion is increasing"
}
```

### `project.alert.crisis_started`

- Producer: `project-srv`
- Consumer: `noti-srv`
- Topic: `project.alert`
- Purpose: notify user khi project chuyển sang crisis
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "alert_type": "CRISIS_STARTED",
  "severity": "HIGH"
}
```

### `project.alert.crisis_resolved`

- Producer: `project-srv`
- Consumer: `noti-srv`
- Topic: `project.alert`
- Purpose: notify user khi project ra khỏi crisis
- Minimum payload:

```json
{
  "project_id": "uuid",
  "campaign_id": "uuid",
  "domain_type_code": "beer_vn",
  "alert_type": "CRISIS_RESOLVED",
  "severity": "INFO"
}
```

## 4. Source Reality vs Target Contracts

## 4.1 Đã khớp phần nào với source

- `project-srv` đã có lifecycle/business context để phát project lifecycle events
- `ingest-srv` đã có `domain_type_code` trong UAP payload
- `analysis-srv` đã parse ingest flat UAP và route theo `domain_type_code`
- `analysis-srv` đã có active publisher constants cho:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`
- `knowledge-srv` docs đã kỳ vọng:
  - `analytics.batch.completed`
  - `analytics.insights.published`
  - `analytics.report.digest`

## 4.2 Chưa khớp với source

- `analysis-srv` vẫn cần hardening/e2e/parity với analytics core cho output contract
- `analysis-srv` vẫn còn stale legacy docstring nhắc `smap.analytics.output`, cần cleanup để tránh hiểu nhầm
- `project-srv` chưa own crisis final state ở mức source
- `project -> ingest` crisis control chưa hoàn tất end-to-end

## 5. Review Checklist

- [ ] Mọi event đều có `producer` và `consumer` rõ
- [ ] Mọi event đều có `minimum_payload`
- [ ] Mọi event downstream analysis đều có `domain_type_code` nếu cần ngữ cảnh domain
- [ ] Có đủ path vào crisis và path thoát crisis
- [ ] Không dùng cùng một event name cho cả business event và technical command
- [ ] Contract không giả định nhầm rằng source hiện tại đã fully aligned

## 6. Kết luận

Bộ contract khuyến nghị cho SMAP nên chia thành 4 lớp rõ:

- `project lifecycle`
- `project crisis/control`
- `ingest -> analysis` canonical UAP
- `analysis -> project / knowledge / notification`

Nếu phải harden một contract trước tất cả các contract còn lại, thì đó là:

**UAP contract hiện chạy trên `smap.collector.output` giữa `ingest-srv` và `analysis-srv`, vì đây là cổ chai của toàn bộ crisis/reporting pipeline.**
