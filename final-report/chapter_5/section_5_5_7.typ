#import "../counters.typ": image_counter, table_counter

=== 5.5.7 UC-07: Phát hiện trend tự động

UC-07 mô tả quy trình tự động phát hiện trending topics thông qua Kubernetes CronJob chạy hàng ngày lúc 2:00 AM.

==== 5.5.7.1 Cron Trigger và Crawling

#align(center)[
  #image("../images/sequence/uc7_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 1: Cron Trigger và Trend Crawling_])
#image_counter.step()

Luồng xử lý:

- Kubernetes CronJob trigger Trend Service.

- Trend Service tạo trend_run record và initialize Redis state.

- Request trending data từ TikTok và YouTube Crawler Services.

- Nếu gặp rate-limit, apply exponential backoff và retry. Nếu vẫn fail thì mark is_partial_result = true và continue với remaining platforms.

==== 5.5.7.2 Scoring và Storage

#align(center)[
  #image("../images/sequence/uc7_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 2: Trend Scoring và Storage_])
#image_counter.step()

Luồng xử lý:

- Normalize metadata từ các platforms thành unified schema.

- Calculate trend score: score = engagement_rate × velocity × 100.

- Rank và filter top 50 per platform, deduplicate cross-platform.

- Batch insert vào PostgreSQL và cache latest run_id trong Redis.

- Broadcast notification đến users.

==== 5.5.7.3 User Views Trends

#align(center)[
  #image("../images/sequence/uc7_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-07 Part 3: User Views Trend Dashboard_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Trends page.

- Trend Service fetch latest run_id từ Redis cache, query trends từ PostgreSQL.

- Web UI render Trend Dashboard với filters.

- User click vào trend để xem details và related posts từ own projects.
