#import "../counters.typ": image_counter, table_counter

=== 5.5.2 UC-02: Dry-run (Kiểm tra keywords)

UC-02 cung cấp cơ chế thử nghiệm keywords trước khi chạy Project thật. Hệ thống sử dụng sampling strategy để giảm chi phí: chỉ lấy 1-2 items mẫu cho mỗi keyword trên mỗi platform.

Sequence diagram được chia thành 2 phần: Setup và crawling, Analytics và hiển thị kết quả.

==== 5.5.2.1 Setup và Crawling

#align(center)[
  #image("../images/sequence/uc2_dryrun_part_1.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 1: Dry-run Setup và Crawling_])
#image_counter.step()

Luồng xử lý:

- User nhập keywords và chọn platform để test.

- Project Service publish dryrun.created event vào RabbitMQ.

- API trả về HTTP 202 Accepted với task_id, Web UI bắt đầu polling status.

- Collector Service dispatch jobs đến Crawler Services với sample size giới hạn.

- Crawler fetch metadata từ platform APIs và upload batch vào MinIO.

==== 5.5.2.2 Analytics và Results

#align(center)[
  #image("../images/sequence/uc2_dryrun_part_2.png", width: 100%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-02 Part 2: Analytics Pipeline và Results_])
#image_counter.step()

Luồng xử lý:

- Collector publish data.collected event để trigger Analytics Service.

- Analytics Service download batch từ MinIO và chạy full 5-step pipeline.

- Kết quả được lưu vào PostgreSQL với project_id = NULL để phân biệt với production data.

- Web UI polling detect completion và fetch summarized results để hiển thị preview dashboard.
