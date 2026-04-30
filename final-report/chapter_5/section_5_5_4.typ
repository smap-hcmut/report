#import "../counters.typ": image_counter, table_counter

=== 5.5.4 UC-04: Xem kết quả phân tích

UC-04 mô tả quy trình truy vấn và hiển thị kết quả phân tích sau khi Project hoàn tất.

==== 5.5.4.1 Overview Dashboard

#align(center)[
  #image("../images/sequence/uc4_result_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 1: Overview Dashboard_])
#image_counter.step()

Luồng xử lý:

- User navigate đến Dashboard page.

- Web UI request overview statistics từ Project API.

- Project API query PostgreSQL để lấy: project metadata, overall KPIs, sentiment distribution, aspect breakdown, competitor comparison, time-series trend.

- Web UI render dashboard với KPI cards, pie chart, bar chart, comparison table, và line chart.

==== 5.5.4.2 Drilldown Details

#align(center)[
  #image("../images/sequence/uc4_result_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-04 Part 2: Drilldown vào chi tiết posts_])
#image_counter.step()

Luồng xử lý:

- User click vào aspect hoặc competitor để filter posts.

- Web UI request posts list với filters từ Project API.

- User click vào post cụ thể để xem full details.

- Project API query post data và comments từ PostgreSQL.

- Web UI hiển thị modal với full content, aspect-level sentiment, keywords, impact breakdown, và top comments.
