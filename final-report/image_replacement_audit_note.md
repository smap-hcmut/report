# Note - Image Replacement Audit

## Mục đích

Ghi lại các phần trong `final-report` hiện vẫn đang dùng hình cũ hoặc asset legacy, đồng thời giữ quy ước notation cho các diagram được vẽ lại.

## Lưu ý

- File này chỉ là note nội bộ cho quá trình hoàn thiện báo cáo.
- Không phải nội dung để đưa vào phần report chính.
- Report chính phải đọc như bản final; mọi ghi chú về hình thiếu, hình cũ hoặc quy ước vẽ chỉ nằm trong file note này.

## Quy ước sequence diagram

- Sequence diagram trong report dùng `participant` cho toàn bộ lifeline để tất cả thực thể tham gia được render bằng hình chữ nhật chuẩn. Không dùng các keyword `control`, `boundary`, `entity`, `database`, `queue` của PlantUML trong sequence diagram vì chúng tạo robustness-style icons dễ gây hiểu nhầm.
- Vai trò của participant như queue, repository, database, adapter hoặc publisher được thể hiện bằng tên lifeline và phần mô tả trong report, không đổi shape của lifeline.
- `->` là synchronous call: caller gọi và chờ kết quả.
- `->>` là asynchronous message/signal: producer gửi event/task/completion và không chờ reply trực tiếp.
- `-->` là return/reply message: chỉ dùng để trả kết quả cho một synchronous call trước đó.
- Queue/topic là transport boundary; không dùng activation bar như business component.
- `alt/else` chỉ dùng cho các nhánh loại trừ nhau; `opt` dùng cho nhánh có thể có hoặc không.
- Không trộn abstraction level trong cùng một sequence diagram: service-level chỉ gồm service/queue/db/storage/external system, component-level chỉ gồm consumer/handler/usecase/repo/adapter/publisher cùng external dependency.

## Các mục đang dùng hình mới

- `chapter_4/section_4_5.typ`
  - đang dùng SVG trong `report/final-report/images/chapter_3/` và `report/final-report/images/chapter_4/`
- `chapter_5/section_5_2.typ`
  - đang dùng `../images/diagram/c4-container-current.svg`
- `chapter_5/section_5_3_2.typ`
  - đang dùng SVG render từ PlantUML cho:
    - `../images/chapter_5/seq-analytics-intake-flow.svg`
    - `../images/chapter_5/seq-analytics-pipeline-flow.svg`
- `chapter_5/section_5_3_4.typ`
  - đang dùng SVG render từ PlantUML cho:
    - `../images/chapter_5/seq-ingest-completion-uap-flow.svg`
- `chapter_5/section_5_3_7.typ`
  - đang dùng SVG render từ PlantUML cho:
    - `../images/chapter_5/seq-knowledge-indexing-flow.svg`
- `chapter_5/section_5_3_8.typ`
  - đang dùng SVG render từ PlantUML cho:
    - `../images/chapter_5/seq-scapper-runtime-flow.svg`

## Backlog cần vẽ hoặc chỉnh sửa

Tạm dừng vẽ hình. Phần dưới đây chỉ ghi lại các mục cần xử lý tiếp theo.

### Chương 5.3 - Service Detail Design

- `chapter_5/section_5_3_1.typ` - Identity Service
  - Cần thay component diagram cũ:
    - `../images/component/identity-component-diagram.png`
  - Cần thay hoặc vẽ lại sequence/data-flow cho login:
    - `../images/data-flow/user_login.png`
  - Cần thay hoặc vẽ lại sequence/data-flow cho auth middleware/internal token validation:
    - `../images/data-flow/auth_middleware.png`
  - Cần cân nhắc thêm flow audit consumer lane vì nội dung `5.3.1` đã mô tả audit processing bất đồng bộ.

- `chapter_5/section_5_3_2.typ` - Analytics Service
  - Cần thay component diagram cũ:
    - `../images/component/analytic-component-diagram.png`
  - Hai sequence mới đã có source PlantUML và SVG render:
    - `../images/chapter_5/seq-analytics-intake-flow.svg`
    - `../images/chapter_5/seq-analytics-pipeline-flow.svg`
  - Cần review trực quan hai sequence này trong PDF trước khi xem là final.

- `chapter_5/section_5_3_3.typ` - Project Service
  - Cần thay component diagram cũ:
    - `../images/component/project-component-diagram.png`
  - Cần thay hoặc vẽ lại sequence/data-flow cho project creation:
    - `../images/data-flow/project_create.png`
  - Cần thay hoặc vẽ lại sequence/data-flow cho execute project/lifecycle control:
    - `../images/data-flow/execute_project.png`
  - Cần kiểm tra lại boundary giữa `project-srv` và `ingest-srv` để flow không trộn lifecycle control với crawl execution details.

- `chapter_5/section_5_3_4.typ` - Ingest Service
  - Sequence completion handling và UAP publishing đã có source PlantUML và SVG render:
    - `../images/chapter_5/seq-ingest-completion-uap-flow.svg`
  - Cần review trực quan diagram này trong PDF trước khi xem là final.
  - Cần cân nhắc vẽ thêm datasource/target management flow nếu phần text vẫn giữ ba flow ở `5.3.4.2`.
  - Cần cân nhắc vẽ thêm dry run validation flow nếu muốn đồng bộ với FR-07 và UC-03.

- `chapter_5/section_5_3_5.typ` - Notification Service
  - Hiện chưa có diagram riêng trong mục này.
  - Cần cân nhắc vẽ sequence cho Redis Pub/Sub -> Notification Service -> WebSocket clients/Discord alert nếu nội dung vẫn giữ realtime delivery và alert dispatch.
  - Cần kiểm tra lại claim WebSocket/realtime với implementation thật trước khi vẽ.

- `chapter_5/section_5_3_6.typ` - Frontend Application
  - Đã chỉnh nội dung để phản ánh đúng BFF/proxy, auth/session, Metabase gateway, knowledge assistant, report polling và notification presentation state.
  - Chưa vẽ diagram cho mục này.
  - Nếu vẽ sau này, ưu tiên BFF/proxy flow hoặc assistant/report interaction flow; không vẽ WebSocket flow nếu chưa có WebSocket client thật.

- `chapter_5/section_5_3_7.typ` - Knowledge Service
  - Sequence analytics to knowledge indexing đã có source PlantUML và SVG render:
    - `../images/chapter_5/seq-knowledge-indexing-flow.svg`
  - Cần review trực quan diagram này trong PDF trước khi xem là final.
  - Cần cân nhắc vẽ thêm contextual search/chat flow vì đây là FR-10 chính.
  - Cần cân nhắc vẽ thêm report generation capability flow nếu report generation vẫn được giữ trong narrative.

- `chapter_5/section_5_3_8.typ` - Scapper Worker Service
  - Sequence canonical crawl execution và completion đã có source PlantUML và SVG render:
    - `../images/chapter_5/seq-scapper-runtime-flow.svg`
  - Cần review trực quan diagram này trong PDF trước khi xem là final.
  - Cần cân nhắc vẽ thêm dryrun completion variant nếu `runtime_kind` và dryrun lane vẫn được nhấn mạnh trong text.

### Chương 5.4 - Data Design

- `chapter_5/section_5_4.typ`
  - Cần thay hoặc kiểm tra lại ERD cũ:
    - `../images/erd/identity-erd.png`
    - `../images/erd/project-erd.png`
    - `../images/erd/analytic-erd.png`
  - Cần kiểm tra lại narrative dữ liệu vì đã phát hiện rủi ro thiếu `knowledge-srv`/Qdrant và lệch mô tả MongoDB.
  - Cần cân nhắc bổ sung ERD/vector-store diagram cho Knowledge Service nếu `knowledge-srv`, indexed documents, conversations, reports và Qdrant là phần chính của thiết kế dữ liệu.

### Chương 5.5 - Detailed Sequence / Use Case Flow

- `chapter_5/section_5_5.typ`
  - Toàn bộ nhóm ảnh sequence PNG legacy cần audit và có thể phải thay bằng PlantUML source + SVG render:
    - `../images/sequence/uc1_cau_hinh_project.png`
    - `../images/sequence/uc2_dryrun_part_1.png`
    - `../images/sequence/uc2_dryrun_part_2.png`
    - `../images/sequence/uc3_execute_part_1.png`
    - `../images/sequence/uc3_execute_part_2.png`
    - `../images/sequence/uc3_execute_part_3.png`
    - `../images/sequence/uc3_execute_part_4.png`
    - `../images/sequence/uc4_result_part_1.png`
    - `../images/sequence/uc4_result_part_2.png`
    - `../images/sequence/uc5_list_part_1_1.png`
    - `../images/sequence/uc5_list_part_1_2.png`
    - `../images/sequence/uc5_list_part_2_1.png`
    - `../images/sequence/uc5_list_part_2_2.png`
    - `../images/sequence/uc6_export_part_1.png`
    - `../images/sequence/uc6_export_part_2_1.png`
    - `../images/sequence/uc6_export_part_2_2.png`
    - `../images/sequence/uc6_export_part_3_1.png`
    - `../images/sequence/uc6_export_part_3_2.png`
    - `../images/sequence/uc7_part_1.png`
    - `../images/sequence/uc7_part_2.png`
    - `../images/sequence/uc7_part_3.png`
    - `../images/sequence/uc8_part_1.png`
    - `../images/sequence/uc8_part_2.png`
    - `../images/sequence/uc8_part_3.png`
    - `../images/sequence/uc8_part_4.png`
  - Cần quyết định có giữ toàn bộ 25 hình hay gom lại thành ít sequence diagram hơn theo use case chính.
  - Nếu thay, phải dùng PlantUML `.puml` làm source-of-truth, không vẽ tay SVG.

### Chương 5.7 - Deployment Design

- `chapter_5/section_5_7.typ`
  - Cần thay hoặc kiểm tra lại deployment diagram cũ:
    - `../images/deploy/deployment-diagram.drawio.png`
  - Cần đối chiếu deployment narrative với service/runtime boundary hiện tại, bao gồm `knowledge-srv`, Qdrant, MinIO, Kafka, RabbitMQ, Redis, PostgreSQL và scapper runtime.

### Chương 6 - Testing / Evaluation

- Chương 6 chưa được audit đầy đủ trong lần rà soát này.
- Cần kiểm tra sau khi hoàn tất Chương 5 vì testing/evaluation phải bám theo requirements, architecture decisions và các flow đã chốt.

## Gợi ý thứ tự xử lý sau khi tiếp tục

1. Review trực quan 5 sequence SVG mới trong PDF, chỉ sửa nếu còn lỗi notation hoặc abstraction.
2. Chỉnh text `5.3.6` trước khi vẽ bất kỳ diagram frontend nào.
3. Thay nhóm hình legacy của `5.3.1` và `5.3.3` vì đây là phần service detail đang lệch nhiều nhất.
4. Audit `5.4` để bổ sung hoặc chỉnh data design cho Knowledge Service/Qdrant trước khi thay ERD.
5. Quyết định chiến lược cho `5.5`: giữ 25 sequence hay gom thành bộ sequence ít hơn, rồi mới vẽ lại.
6. Cập nhật deployment diagram ở `5.7` sau khi service/data/communication narrative đã ổn định.
