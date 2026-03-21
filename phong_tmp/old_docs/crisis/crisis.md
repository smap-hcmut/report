Perfect! Giờ rõ ràng rồi. Để tôi thiết kế lại:

## SIMPLIFIED APPROACH

### Concept:

1. **Adaptive Crawl = ALWAYS ENABLED** (system behavior, không cần config)
2. **Crisis Detection = User config** (với defaults tốt)
3. **Mỗi trigger có default values** (FE giải thích + user có thể customize)

---

## Config Structure (Simplified)

```json
{
  "project_id": "proj_vf8",

  // CHỈ CẦN CONFIG CRISIS DETECTION
  // Adaptive crawl tự động dùng thresholds này
  "crisis_detection": {
    // Trigger 1: Keywords (Default: disabled)
    "keywords_trigger": {
      "enabled": false, // Default: false (user tự bật)
      "logic": "OR",
      "groups": []
      // FE tooltip: "Phát hiện từ khóa nhạy cảm như 'lừa đảo', 'scam'"
    },

    // Trigger 2: Volume (Default: enabled)
    "volume_trigger": {
      "enabled": true, // Default: true
      "metric": "MENTIONS",
      "rules": [
        {
          "level": "CRITICAL",
          "threshold_percent_growth": 200, // Default: 200% (3x baseline)
          "comparison_window_hours": 1,
          "baseline": "PREVIOUS_PERIOD"
        }
      ]
      // FE tooltip: "Phát hiện tăng đột biến lượng mentions (mặc định: tăng 200% so với trước)"
    },

    // Trigger 3: Sentiment (Default: enabled)
    "sentiment_trigger": {
      "enabled": true, // Default: true
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 30 // Default: 30%
        }
      ]
      // FE tooltip: "Phát hiện tỷ lệ negative cao (mặc định: > 30%)"
    },

    // Trigger 4: Influencer (Default: disabled)
    "influencer_trigger": {
      "enabled": false, // Default: false (user tự bật)
      "logic": "OR",
      "rules": []
      // FE tooltip: "Phát hiện influencer lớn hoặc bài viral negative"
    }
  }

  // BỎ LUÔN adaptive_crawl config
  // System tự động:
  //   - Adaptive crawl ALWAYS enabled
  //   - Dùng crisis_detection thresholds
  //   - Sleep mode: hardcoded (< 10 items/hour)
}
```

---

## System Behavior

### Rule 1: Crisis Detection → Adaptive Crawl (Automatic)

```
[Analytics Service] Detect crisis
  - Check: sentiment_trigger.threshold_percent = 30%
  - Current: negative_ratio = 35%
  - Result: 35% > 30% → CRISIS DETECTED
  - Publish: analytics.crisis.detected
  ↓
[Project Service - Crisis Handler]
  - Store alert
  - Publish: project.crisis.started
  ↓
[Project Service - Adaptive Scheduler]
  - Receive: analytics.crisis.detected
  - Action: FORCE switch to CRISIS mode
  - Call Ingest API: PUT /crawl-mode {mode: CRISIS, interval: 2}
  ↓
[Ingest Service]
  - Update: crawl_mode = CRISIS, interval = 2 min
  - Crawl immediately
```

### Rule 2: Metrics-based Adaptive Crawl (Automatic)

```
[Analytics Service] Publish metrics
  - Publish: analytics.metrics.aggregated
  - Payload: {negative_ratio: 35%, velocity: 50}
  ↓
[Project Service - Adaptive Scheduler]
  - Load: crisis_detection config
  - Extract threshold: sentiment_trigger.threshold_percent = 30%
  - Compare: 35% > 30% → CRISIS mode
  - Call Ingest API: PUT /crawl-mode {mode: CRISIS, interval: 2}
```

### Rule 3: Sleep Mode (Automatic - Hardcoded)

```
[Project Service - Adaptive Scheduler]
  - Receive: analytics.metrics.aggregated
  - Check: new_items_count = 3 (< 10)
  - Action: Switch to SLEEP mode
  - Call Ingest API: PUT /crawl-mode {mode: SLEEP, interval: 60}
```

---

## Default Config (System-generated)

```json
{
  "project_id": "proj_vf8",
  "crisis_detection": {
    "keywords_trigger": {
      "enabled": false,
      "logic": "OR",
      "groups": []
    },
    "volume_trigger": {
      "enabled": true,
      "metric": "MENTIONS",
      "rules": [
        {
          "level": "CRITICAL",
          "threshold_percent_growth": 200,
          "comparison_window_hours": 1,
          "baseline": "PREVIOUS_PERIOD"
        }
      ]
    },
    "sentiment_trigger": {
      "enabled": true,
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 30
        }
      ]
    },
    "influencer_trigger": {
      "enabled": false,
      "logic": "OR",
      "rules": []
    }
  }
}
```

**Default Behavior:**

- Alert ở 30% negative HOẶC 200% volume growth
- Adaptive crawl tự động switch ở 30% negative
- Sleep mode ở < 10 items/hour (hardcoded)
- User chỉ cần customize nếu muốn thay đổi thresholds

---

## Frontend Tooltips (Hướng dẫn)

### Keywords Trigger

```
Tiêu đề: Phát hiện từ khóa nhạy cảm
Mô tả: Hệ thống sẽ cảnh báo khi phát hiện các từ khóa như "lừa đảo", "scam", "giả mạo"
Mặc định: Tắt (bạn cần thêm từ khóa để bật)
Ví dụ: Thêm nhóm từ khóa "An toàn" với các từ: "ngộ độc", "kiện", "công an"
```

### Volume Trigger

```
Tiêu đề: Phát hiện tăng đột biến lượng mentions
Mô tả: Cảnh báo khi lượng mentions tăng đột ngột so với baseline
Mặc định: Bật - Cảnh báo khi tăng 200% (3x) so với giờ trước
Ví dụ: Nếu giờ trước có 100 mentions, giờ này có 300 mentions → Cảnh báo
Tùy chỉnh: Bạn có thể giảm xuống 150% (2.5x) để nhạy hơn
```

### Sentiment Trigger

```
Tiêu đề: Phát hiện tỷ lệ negative cao
Mô tả: Cảnh báo khi tỷ lệ bình luận negative vượt ngưỡng
Mặc định: Bật - Cảnh báo khi > 30% negative
Ví dụ: Trong 100 bình luận, có 35 bình luận negative → Cảnh báo
Tùy chỉnh: Bạn có thể giảm xuống 20% để nhạy hơn
Lưu ý: Cần tối thiểu 50 bình luận để phân tích chính xác
```

### Influencer Trigger

```
Tiêu đề: Phát hiện influencer hoặc bài viral negative
Mô tả: Cảnh báo khi có influencer lớn hoặc bài viết viral negative
Mặc định: Tắt (bạn cần cấu hình để bật)
Ví dụ:
  - Influencer có > 100K followers đăng bài negative
  - Bài viết có > 1000 shares + negative
Tùy chỉnh: Bạn có thể điều chỉnh số followers hoặc shares
```

---

## API (Simplified)

### Get Config (with defaults)

```http
GET /projects/{id}/config

Response 200:
{
  "project_id": "proj_vf8",
  "crisis_detection": {
    "keywords_trigger": {
      "enabled": false,
      "logic": "OR",
      "groups": []
    },
    "volume_trigger": {
      "enabled": true,
      "metric": "MENTIONS",
      "rules": [
        {
          "level": "CRITICAL",
          "threshold_percent_growth": 200,
          "comparison_window_hours": 1,
          "baseline": "PREVIOUS_PERIOD"
        }
      ]
    },
    "sentiment_trigger": {
      "enabled": true,
      "min_sample_size": 50,
      "rules": [
        {
          "type": "NEGATIVE_SPIKE",
          "threshold_percent": 30
        }
      ]
    },
    "influencer_trigger": {
      "enabled": false,
      "logic": "OR",
      "rules": []
    }
  }
}
```

### Update Config (partial)

```http
PUT /projects/{id}/config

Request:
{
  "crisis_detection": {
    "sentiment_trigger": {
      "threshold_percent": 20  // User giảm xuống 20% để nhạy hơn
    }
  }
}

Response 200:
{
  "crisis_detection": {
    "sentiment_trigger": {
      "enabled": true,
      "threshold_percent": 20  // Updated
    }
  }
}
```

---

## Database Schema (Simplified)

```sql
CREATE TABLE schema_project.project_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES schema_project.projects(id) ON DELETE CASCADE,

    -- CHỈ CẦN crisis_detection (JSONB)
    crisis_detection JSONB NOT NULL,

    -- BỎ adaptive_crawl field

    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT uq_project_config UNIQUE (project_id)
);
```

---

## Summary

**Simplified approach:**

1. ✅ Adaptive crawl ALWAYS enabled (không cần config)
2. ✅ User chỉ config crisis_detection
3. ✅ Mỗi trigger có default values tốt
4. ✅ FE có tooltips hướng dẫn rõ ràng
5. ✅ User có thể customize nếu muốn
6. ✅ Không có confusion về modes

**Default thresholds:**

- Keywords: Disabled (user tự thêm)
- Volume: 200% growth (3x baseline)
- Sentiment: 30% negative
- Influencer: Disabled (user tự config)
- Sleep: < 10 items/hour (hardcoded)

Bạn approve approach này không? Tôi sẽ update vào master-proposal.md.
