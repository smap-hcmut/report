#import "../counters.typ": image_counter, table_counter

=== 5.5.8 UC-08: Phát hiện khủng hoảng

UC-08 mô tả cơ chế tự động phát hiện và cảnh báo các bài viết có nguy cơ gây khủng hoảng thương hiệu. Hệ thống sử dụng triple-check logic (Intent + Sentiment + Impact) để identify crisis posts.

==== 5.5.8.1 Analytics Pipeline và Crisis Detection

#align(center)[
  #image("../images/sequence/uc8_part_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 1: Analytics Pipeline và Crisis Detection_]
)
#image_counter.step()

Luồng xử lý:

- Analytics Service chạy full pipeline cho mỗi post.

- Sau khi save vào PostgreSQL, check triple-check criteria: Intent = CRISIS, Sentiment = NEGATIVE hoặc VERY_NEGATIVE, Risk Level = HIGH hoặc CRITICAL.

- Nếu thỏa mãn cả 3 điều kiện thì trigger crisis alert.

==== 5.5.8.2 Crisis Alert Publishing

#align(center)[
  #image("../images/sequence/uc8_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 2: Crisis Alert Publishing_])
#image_counter.step()

Luồng xử lý:

- Build alert payload với post details, metrics, và analytics results.

- Publish crisis.detected event vào RabbitMQ với high priority.

- Đồng thời publish vào Redis Pub/Sub để ensure real-time delivery.

==== 5.5.8.3 User Receives Alert

#align(center)[
  #image("../images/sequence/uc8_part_3.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 3: User Receives Real-time Alert_])
#image_counter.step()

Luồng xử lý:

- WebSocket Service receive message từ Redis Pub/Sub và forward đến connected client.

- Web UI hiển thị notification banner, play alert sound, show browser notification, và update unread count badge.

==== 5.5.8.4 Crisis Dashboard và Response

#align(center)[
  #image("../images/sequence/uc8_part_4.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-08 Part 4: Crisis Dashboard và Response_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Crisis Dashboard.

- Project API query crisis posts từ PostgreSQL với filters.

- Web UI render dashboard với crisis posts list sorted by impact score.

- User click vào post để xem details và thực hiện actions như mark as handled, export, hoặc share với team.
