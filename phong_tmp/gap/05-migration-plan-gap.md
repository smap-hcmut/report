# Gap Analysis - documents/migration-plan.md

## Verdict

`migration-plan.md` là file lệch nhiều nhất so với implementation hiện tại vì nó chứa cả:

- target architecture,
- product vision,
- planned endpoints,
- future state machines,
- old transition assumptions.

Nếu dùng file này như "spec hiện tại", team rất dễ implement sai hoặc review sai.

## Matrix

| Cụm claim cũ | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| Project activation rule | Project `DRAFT -> ACTIVE` khi có ít nhất 1 datasource `READY`. | Runtime hiện tại dùng readiness phức tạp hơn: phải xét datasource existence, passive confirmed placeholder, latest usable dryrun theo target, active target count cho crawl source. | Critical | Rewrite toàn bộ activation/resume precondition thành readiness matrix mới. |
| Project lifecycle sync | Project publish `project.activated/paused/archived`; ingest consume và cascade source state. | Runtime core hiện tại phối hợp lifecycle qua internal call project->ingest; event publish không còn là mô tả đủ của source-of-truth runtime path. | Critical | Chuyển Kafka lifecycle sync sang `legacy design / optional async event mirror`, không mô tả như main path. |
| Project config status | Có `config_status` kiểu `CONFIGURING/ONBOARDING/DRYRUN_RUNNING/...` như state model quan trọng. | Runtime hiện tại không lấy các wizard states này làm lifecycle chính. | High | Giảm xuống `legacy metadata / design artifact`, không dùng như current state machine. |
| Data source lifecycle | FILE_UPLOAD ends at `COMPLETED`, WEBHOOK continuous, onboarding chuẩn, PENDING->READY bằng AI schema mapping. | Passive source onboarding hiện chưa hoàn chỉnh; `FILE_UPLOAD/WEBHOOK` chưa nên mô tả như feature runtime hoàn tất. | Critical | Đổi toàn bộ passive sections sang `Planned / Gap`. |
| Dryrun | Có topic `ingest.dryrun.requested/completed`, route `GET /projects/:id/dry-run/:dryrunId`, source-level dryrun-centric model. | Runtime hiện tại dryrun là ingest-owned, per-target, route ở datasource, lineage theo datasource+target, completion qua worker artifact pipeline. | Critical | Xóa hoặc deprecate route/topic cũ; thay bằng current ingest dryrun contract. |
| Ingest endpoint naming | Dùng `sources`, `schema/preview`, `schema/confirm`, upload flow như current APIs. | Current runtime canonical naming là `datasources`; passive onboarding APIs chưa phải runtime contract hiện hành. | High | Chia rõ `current APIs` và `planned passive onboarding APIs`. |
| Adaptive crawl | Project service evaluate metrics rồi call `PUT /ingest/sources/{id}/crawl-mode` hoặc publish orchestration event. | Adaptive crawl chưa nằm trong runtime core đã implement; current pack không inventory flow này như implemented domain. | High | Chuyển sang `future milestone`, không để lẫn vào current runtime. |
| Profile runtime | `PROFILE` được ngầm xem là crawl strategy đang hỗ trợ. | `PROFILE` mới có CRUD; runtime dispatch/dryrun/scheduler mapping chưa hoàn chỉnh. | High | Đánh dấu `PROFILE runtime = partial`. |
| Archive/delete semantics | Nhiều bảng route và transition dùng `DELETE` như archive hoặc chưa tách rõ delete sau archived. | Runtime hiện tại tách rõ `archive`, `unarchive`, `delete`, và delete có guard riêng. | High | Sửa route tables và transition tables để archive/delete là hai command khác nhau. |
| Topic names | Có nhiều topic planned được trộn với topic current. | Chỉ một phần topics là current runtime fact; nhiều topic là planned. | Medium | Tách appendix topic thành `Current` và `Planned`. |

## Những cụm lệch nghiêm trọng nhất

### 1. Activation / resume logic

File này nhiều chỗ nói rằng:

- project activate chỉ cần có source `READY`,
- source `READY` đến từ onboarding hoặc dryrun pass,
- sau đó project activate sẽ cascade xuống source.

Implementation hiện tại lại vận hành theo logic:

- readiness view riêng,
- activate và resume là hai command khác nhau,
- readiness aggregate theo datasource + target,
- target latest dryrun usable mới là điểm then chốt,
- active-target invariant mới là guard quan trọng cho crawl source.

Tức là file cũ đang dùng model `source-centric readiness`, trong khi runtime hiện tại là `project readiness aggregated from target/runtime facts`.

### 2. Passive onboarding đang bị overclaim toàn bộ

Những claim như:

- FILE_UPLOAD upload sample -> AI mapping -> confirm -> READY -> ACTIVE -> COMPLETED
- WEBHOOK define payload -> AI mapping -> confirm -> webhook URL -> ACTIVE

đều đang đi xa hơn implementation hiện tại.

Runtime pack hiện tại chỉ xác nhận:

- model/state có tồn tại,
- readiness có placeholder đọc `onboarding_status == CONFIRMED`,
- create passive source mới persist base datasource,
- chưa có preview/analyze/confirm flow thật để xem là completed contract.

### 3. Project/ingest choreography cũ không còn đúng cho current runtime

Migration plan đẩy mạnh ý tưởng:

- project publish lifecycle events,
- ingest consume,
- adaptive crawl phát command/event.

Nhưng current runtime pack cho thấy:

- project lifecycle command phụ thuộc ingest internal contract,
- internal call là current path quan trọng,
- event publish nếu có không đủ để mô tả core behavior.

### 4. `config_status` và wizard states gây nhiễu

Migration plan vừa có đoạn nói "No CONFIGURING state", vừa giữ nhiều đoạn schema/enum có `CONFIGURING`, `ONBOARDING`, `DRYRUN_RUNNING`.

Điều này tự thân đã gây nhiễu, và lại càng xa implementation hiện tại.

## Rewrite đề xuất

### Nên tách file thành 3 lớp

1. `Current Runtime Facts`
   - lấy từ code-derived pack
2. `Planned Product Features`
   - passive onboarding
   - adaptive crawl
   - crisis orchestration
   - campaign artifacts, etc.
3. `Deprecated Design Notes`
   - old topic names
   - old state machines
   - obsolete route proposals

### Rule biên tập nên áp dụng

- Mọi block nào không có evidence trong code-derived pack phải gắn nhãn `Planned`.
- Mọi route không tồn tại trong current runtime surface phải gắn nhãn `Proposed`.
- Mọi state machine nếu không khớp current code phải chuyển xuống `Historical design`.

## Đề xuất cleanup cụ thể

1. Xóa tư cách "source of truth hiện tại" của các section sau:
   - `ProjectConfigStatus`
   - passive onboarding complete flow
   - dryrun requested/completed topic design
   - adaptive crawl implementation
2. Giữ lại nhưng rewrite:
   - simplified project state machine
   - datasource state machine
   - JWT HS256 notes
   - UAP and time semantics
3. Tạo appendix riêng:
   - `Implemented now`
   - `Planned next`

## Kết luận

`migration-plan.md` nên được xem là tài liệu strategy/product roadmap, không phải BRD/SRS thực thi hiện tại. Nếu muốn dùng lại, cần tách rõ `current runtime` khỏi `future design`.
