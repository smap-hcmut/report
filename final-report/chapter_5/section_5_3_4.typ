#import "../counters.typ": image_counter, table_counter

=== 5.3.4 Ingest Service

Ingest Service là dịch vụ giữ execution plane của hệ thống ở lớp ingest. Dịch vụ này chịu trách nhiệm quản lý datasource, crawl target, dry run, external task, raw batch và quá trình chuẩn hóa dữ liệu đầu vào sang UAP trước khi chuyển tiếp xuống analytics data plane.

Vai trò của Ingest Service trong kiến trúc tổng thể:

- Datasource Owner: Quản lý metadata và vòng đời của datasource.
- Target Manager: Quản lý crawl target theo keyword, profile và post.
- Dry Run Runtime: Thực hiện kiểm tra readiness trước khi chạy chính thức.
- Execution Plane: Publish task, nhận completion và tạo raw batch lineage.
- UAP Publisher: Chuẩn hóa dữ liệu đầu vào và phát hành sang lane phân tích downstream.

Service này đáp ứng trực tiếp FR-05 về Datasource Management, FR-06 về Crawl Target Management, FR-07 về Dry Run Validation và FR-08 về Crawl Runtime Orchestration. Ở mức use case, nó liên quan trực tiếp đến UC-03 về Configure Datasource and Run Dry Run và UC-04 về Control Project Lifecycle.

==== 5.3.4.1 Thành phần chính

Ở mức thiết kế chi tiết, Ingest Service có thể được nhìn qua năm cụm thành phần chính.

#context (align(center)[_Bảng #table_counter.display(): Thành phần chính của Ingest Service_])
#table_counter.step()
#block(width: 100%)[
  #set par(justify: false)
  #table(
    columns: (0.22fr, 0.40fr, 0.20fr, 0.18fr),
    stroke: 0.5pt,
    align: (left, left, left, left),
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Thành phần*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Trách nhiệm chính*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Input / Output*],
    table.cell(align: center + horizon, inset: (y: 0.8em))[*Technology*],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Datasource Handler],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Xử lý HTTP routes cho datasource CRUD, target management và các internal lifecycle endpoints],
    table.cell(align: center + horizon, inset: (y: 0.8em))[HTTP request / JSON response],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Gin + HTTP handler],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Datasource UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Điều phối business rules cho datasource, target và project lifecycle runtime],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Datasource input / lifecycle output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Pure Go logic],

    table.cell(align: center + horizon, inset: (y: 0.8em))[DryRun UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Khởi chạy dry run, ghi nhận kết quả và duy trì readiness evidence],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Dry run request / latest-history output],
    table.cell(align: center + horizon, inset: (y: 0.8em))[UseCase + RabbitMQ producer],

    table.cell(align: center + horizon, inset: (y: 0.8em))[Execution UseCase],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Publish crawl task, nhận completion, kiểm tra object storage và tạo raw batch lineage],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Task payload / completion metadata],
    table.cell(align: center + horizon, inset: (y: 0.8em))[RabbitMQ + MinIO client],

    table.cell(align: center + horizon, inset: (y: 0.8em))[UAP Publisher],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Chuẩn hóa raw batch thành UAP và phát hành sang analytics data plane],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Raw batch / UAP records],
    table.cell(align: center + horizon, inset: (y: 0.8em))[Kafka publishing layer],
  )
]

==== 5.3.4.2 Data Flow

Luồng xử lý chính của Ingest Service có thể chia thành ba flow quan trọng: datasource & target management, dry run validation và completion handling + UAP publishing.

===== a. Datasource and Target Management Flow

Flow này bắt đầu khi người dùng tạo datasource, thêm crawl target hoặc chỉnh sửa các tham số vận hành liên quan.

Ở flow này, service thực hiện các bước chính sau:

1. nhận request tạo hoặc cập nhật datasource;
2. lưu metadata của datasource và target trong persistence layer;
3. áp dụng các business rules liên quan đến trạng thái và loại target;
4. chuẩn bị dữ liệu đầu vào cho dry run hoặc lifecycle control ở các bước tiếp theo.

===== b. Dry Run Validation Flow

Flow này được kích hoạt khi người dùng yêu cầu kiểm tra readiness trước khi chạy chính thức.

Ở flow này, Ingest Service:

1. tạo một dry run request cho datasource tương ứng;
2. publish task sang crawler runtime nếu cần lấy mẫu hoặc xác nhận dữ liệu;
3. nhận kết quả dry run và ghi vào `dryrun_results`;
4. duy trì bằng chứng readiness để dùng cho lifecycle control ở `project-srv`.

===== c. Completion Handling and UAP Publishing Flow

Flow này là phần quan trọng nhất của execution plane hiện tại.

1. Ingest Service publish crawl task sang RabbitMQ.
2. `scapper-srv` thực thi task và publish completion metadata trở lại.
3. Ingest Service kiểm tra object storage, tạo `external_task` completion record và `raw_batch` lineage.
4. Nếu flow phù hợp, service parse và chuẩn hóa dữ liệu sang UAP.
5. Kết quả được publish sang analytics data plane để `analysis-srv` tiếp tục tiêu thụ.

==== 5.3.4.3 Design Patterns áp dụng

Ingest Service áp dụng các design patterns sau:

- Repository Pattern: Tách truy cập datasource, dryrun, execution và raw batch persistence khỏi business logic.
- Control Plane / Execution Plane Separation: Lifecycle control được giữ rõ ở lớp business/runtime control, trong khi task execution được đẩy sang lane bất đồng bộ.
- Task Queue Pattern: RabbitMQ được dùng cho crawl task dispatch và completion handling.
- Idempotent Completion Handling: `task_id` và lineage metadata được dùng để chống xử lý trùng completion.
- Canonical Publishing Pattern: Sau khi dữ liệu được chuẩn hóa, service phát hành UAP để các lane downstream có thể tiêu thụ nhất quán.

==== 5.3.4.4 Key Decisions

- Giữ ownership của datasource, target, dry run, external task và raw batch trong một service boundary duy nhất.
- Dùng internal HTTP từ `project-srv` sang `ingest-srv` cho readiness và lifecycle control.
- Dùng RabbitMQ cho crawl runtime thay vì ép toàn bộ flow vào synchronous control.
- Chỉ publish sang analytics data plane sau khi completion và raw batch lineage đã được xác nhận ở mức cần thiết.

==== 5.3.4.5 Dependencies

Internal Dependencies:

- Datasource UseCase: quản lý datasource, target và lifecycle runtime.
- DryRun UseCase: quản lý flow dry run và readiness evidence.
- Execution UseCase: quản lý task dispatch, completion handling và raw batch lineage.
- UAP layer: chuẩn hóa và phát hành dữ liệu downstream.

External Dependencies:

- PostgreSQL: lưu datasource, target, dryrun, scheduled job, external task và raw batch.
- RabbitMQ: task dispatch và completion lane.
- MinIO: object storage cho raw artifacts và completion verification.
- `project-srv`: lifecycle control plane và project context.
- `analysis-srv`: downstream consumer của UAP analytics input.
