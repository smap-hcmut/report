#import "../counters.typ": image_counter, table_counter

=== 5.5.3 UC-03: Khởi chạy và Giám sát Project

UC-03 là luồng xử lý phức tạp nhất trong hệ thống, bao gồm 4 giai đoạn: Execute và Initialize, Collector Dispatches Jobs, Analytics Pipeline, và Completion.

==== 5.5.3.1 Execute và Initialize

#align(center)[
  #image("../images/sequence/uc3_execute_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 1: Execute và Initialize Project_])
#image_counter.step()

Luồng xử lý:

- User click Khởi chạy, Web UI gửi POST request đến Project Service.

- Project Service verify ownership và kiểm tra duplicate execution qua Redis state.

- Update PostgreSQL status từ draft thành process.

- Initialize Redis state với status INITIALIZING và TTL 7 days.

- Publish project.created event vào RabbitMQ.

- Trả về 200 OK, Web UI navigate đến Project Processing page.

Rollback mechanism: Nếu Redis init fail thì rollback PostgreSQL status. Nếu RabbitMQ publish fail thì rollback cả Redis state và PostgreSQL status.

==== 5.5.3.2 Collector Dispatches Jobs

#align(center)[
  #image("../images/sequence/uc3_execute_part_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 2: Collector Dispatches Crawl Jobs_]
)
#image_counter.step()

Luồng xử lý:

- Collector Service consume project.created event từ RabbitMQ.

- Parse keywords và generate job matrix: total_jobs = num_keywords × num_platforms × num_days.

- Update Redis state với status CRAWLING và total jobs count.

- Dispatch jobs đến Crawler Services, mỗi job crawl 1 keyword trên 1 platform trong 1 ngày.

- Crawler upload batch 20-50 items vào MinIO và Collector publish data.collected event.

- Sau mỗi job hoàn thành, increment Redis counter để track progress.

==== 5.5.3.3 Analytics Pipeline

#align(center)[
  #image("../images/sequence/uc3_execute_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 3: Analytics Pipeline Processing_])
#image_counter.step()

Luồng xử lý:

- Analytics Service consume data.collected events từ RabbitMQ.

- Download batch từ MinIO và chạy 5-step pipeline: Preprocessing, Intent Classification, Keyword Extraction, Sentiment Analysis, Impact Calculation.

- Batch INSERT kết quả vào PostgreSQL.

- Sau khi save, check triple-check criteria để detect crisis posts. Nếu phát hiện crisis thì publish crisis.detected event.

==== 5.5.3.4 Completion và Notification

#align(center)[
  #image("../images/sequence/uc3_execute_part_4.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 4: Project Completion và Notification_]
)
#image_counter.step()

Luồng xử lý:

- Collector periodically check Redis state, khi done >= total thì update status DONE.

- Gọi webhook đến Project Service để báo completion.

- Project Service update PostgreSQL status thành completed.

- Publish notification qua Redis Pub/Sub đến WebSocket Service.

- Web UI polling detect completion và redirect đến Dashboard.
