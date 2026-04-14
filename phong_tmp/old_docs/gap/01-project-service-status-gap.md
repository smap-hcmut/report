# Gap Analysis - documents/project-service-status.md

## Verdict

Tài liệu này đã lỗi thời đáng kể ở phần `project lifecycle`, `internal API`, `boundary với ingest`, và `archive/delete semantics`.

Điểm nguy hiểm nhất:

- Tài liệu mô tả project service gần như chỉ có CRUD + crisis config.
- Tài liệu khẳng định chưa có internal API/lifecycle orchestration đáng kể.
- Trong implementation hiện tại, `project-srv` lại là owner thật của lifecycle `DRAFT/ACTIVE/PAUSED/ARCHIVED`, có readiness, có `activate/pause/resume/archive/unarchive/delete`, và gọi ingest qua internal contract.

## Matrix

| Doc cũ / section | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `documents/project-service-status.md` - tổng quan + hierarchy | Project service không có domain logic phụ thuộc ingest/data source. | Implementation hiện tại phụ thuộc ingest rất rõ ở lifecycle: `activate`, `pause`, `resume`, `archive` đều có ingest side effect hoặc readiness query. | Critical | Sửa mô tả thành: `project-srv` là source of truth cho project status, nhưng lifecycle có phụ thuộc runtime contract sang ingest-srv. |
| `documents/project-service-status.md` - `ProjectConfigStatus (wizard states)` | `DRAFT -> CONFIGURING -> ONBOARDING -> ... -> ACTIVE/ERROR` là state model đáng kể của project. | Runtime hiện tại không dùng wizard states làm lifecycle chính. Project status chuẩn là `DRAFT/ACTIVE/PAUSED/ARCHIVED`; readiness nằm ngoài status chính. | High | Hạ `ProjectConfigStatus` xuống mục `legacy / non-runtime / deprecated design artifact`, không mô tả như main state machine nữa. |
| `documents/project-service-status.md` - API Endpoints | Project chỉ có CRUD; `DELETE /projects/:projectId` nghĩa là archive. | Runtime hiện tại có route lifecycle riêng: `GET /projects/:id/activation-readiness`, `POST /activate`, `POST /pause`, `POST /resume`, `POST /archive`, `POST /unarchive`, và `DELETE` là delete thật sau archived. | Critical | Tách rõ `archive` và `delete`; thêm toàn bộ lifecycle endpoints; ghi `DELETE` chỉ hợp lệ sau archived. |
| `documents/project-service-status.md` - "Kafka Consumer - Chưa Implement" | Project service chưa có consumer/runtime orchestration đáng kể. | Đúng ở nghĩa cũ của consumer Kafka, nhưng sai nếu dùng để kết luận project chưa có lifecycle orchestration. Runtime hiện tại orchestration đi qua internal ingest call, không đợi Kafka consumer. | High | Sửa đoạn này thành: `Kafka consumer/adaptive domain có thể chưa phải runtime path chính; lifecycle runtime hiện tại dùng internal HTTP contract với ingest-srv.` |
| `documents/project-service-status.md` - "Adaptive Crawl - Chưa Implement" | Toàn bộ giá trị runtime quan trọng của project ở crisis/adaptive đều chưa có. | Đúng một phần cho `adaptive crawl`, nhưng tài liệu làm người đọc tưởng project service chưa có lifecycle domain đáng kể. Trong thực tế lifecycle domain đã có khá đầy đủ. | Medium | Tách `project lifecycle` và `crisis/adaptive` thành 2 phần độc lập. Đừng gom chung rồi kết luận project service "chưa implement nhiều". |
| `documents/project-service-status.md` - "Không có internal API endpoint" | Project không expose internal API để service khác query. | Implementation hiện tại có internal detail contract và readiness contract dùng cho service-to-service flow. | Critical | Thêm mục `Internal Interfaces`: internal detail, activation-readiness, lifecycle coordination semantics. |
| `documents/project-service-status.md` - delete/archive semantics | `DELETE /projects/:projectId` là archive. | Runtime hiện tại: `POST /projects/:id/archive` là archive; `DELETE /projects/:id` là delete sau archived. | Critical | Rewrite route table để không dùng `DELETE` làm archive nữa. |
| `documents/project-service-status.md` - lifecycle scope | Chỉ nói Campaign CRUD, Project CRUD, Crisis Config CRUD. | Runtime hiện tại có cả `readiness`, `unarchive`, optimistic guard chống race local, và archive-from-active phải pause ingest trước. | High | Bổ sung hẳn một section `Project Lifecycle Domain` thay vì để tài liệu chỉ mang tính CRUD. |

## Cụm mismatch chi tiết

### 1. Project lifecycle hiện tại là domain thật, không phải TODO

Implementation đang có:

- `Activate` chỉ cho `DRAFT`.
- `Pause` chỉ cho `ACTIVE`.
- `Resume` chỉ cho `PAUSED` và phải qua readiness `resume`.
- `Archive` cho `DRAFT/ACTIVE/PAUSED`.
- `Unarchive` chỉ cho `ARCHIVED` và trả về `PAUSED`.
- `Delete` chỉ cho sau archived.

Điều này khiến doc cũ trở nên thiếu nghiêm trọng vì nó bỏ hẳn phần behavior có giá trị nhất của project runtime.

### 2. Boundary với ingest đã đổi bản chất

Doc cũ làm người đọc hiểu:

- project là metadata owner,
- ingest là runtime owner,
- project gần như không có command contract quan trọng với ingest.

Runtime thực tế:

- project status vẫn do `project-srv` giữ,
- nhưng lifecycle transition phải phối hợp với ingest qua readiness/internal activate/pause/resume,
- tức boundary đã là `project owns business transition, ingest owns runtime preconditions and downstream state`.

### 3. Readiness là contract runtime quan sát được

Doc cũ không mô tả rõ:

- readiness cho `activate` và `resume` là khác nhau,
- readiness block nếu không có datasource,
- readiness block nếu target chưa có dryrun usable,
- readiness block nếu crawl datasource không có active target,
- readiness còn bị ảnh hưởng bởi passive onboarding placeholder.

Nếu giữ docs cũ, FE/BE rất dễ implement UI sai:

- cho phép bấm activate quá sớm,
- nghĩ chỉ cần có source `READY` là đủ,
- không hiểu vì sao project `PAUSED` resume fail.

## Rewrite đề xuất

### Nên đổi cấu trúc tài liệu thành:

1. `Business Context`
   - project là aggregate nghiệp vụ
   - source of truth cho project status
   - lifecycle command phối hợp với ingest
2. `Project Lifecycle`
   - status table
   - command guards
   - readiness contract
3. `Public Interfaces`
   - CRUD
   - activation-readiness
   - activate/pause/resume/archive/unarchive/delete
4. `Internal Interfaces`
   - internal detail
   - ingest readiness coordination
5. `Known Gaps`
   - adaptive crawl / crisis domain nếu chưa đưa vào runtime core

### Ngôn ngữ nên dùng

- Dùng `Implemented` cho lifecycle hiện tại.
- Dùng `Not part of current runtime core` cho `ProjectConfigStatus`.
- Dùng `Planned / partial` cho `adaptive crawl`, không để lẫn vào lifecycle chính.

## Kết luận

Đây là tài liệu cần sửa sớm vì nó làm sai nhận thức về vai trò hiện tại của `project-srv`. Nếu chỉ đọc file này, người mới sẽ đánh giá thấp lifecycle domain hiện đang chạy thật.
