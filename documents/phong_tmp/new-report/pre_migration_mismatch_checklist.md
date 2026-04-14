# Pre-Migration Mismatch Checklist

Updated: 2026-04-15

## 1. Mục đích

Checklist này dùng để khóa các mismatch quan trọng trong `phong_tmp/new-report` trước khi migrate nội dung sang `final-report`.

Nguyên tắc:

- chưa sửa các mismatch dưới đây thì chưa nên port vào Typst nộp cuối
- khi code và README mâu thuẫn, ưu tiên code hiện tại và route/config/runtime manifests
- mọi claim về `current-state` phải bám file nguồn đang tồn tại trong workspace này

## 2. Source of Truth Chốt Lại

### 2.1 Path truth trong workspace hiện tại

- `layout truth`: `report_SMAP/final-report`
- `content draft`: `report_SMAP/phong_tmp/new-report/thesis`
- `plan / audit workspace`: `report_SMAP/phong_tmp/new-report`

### 2.2 Code truth cần khóa trước khi viết

- `web-ui` có source thật và có `package.json`
- lifecycle `project -> ingest` hiện tại đi theo internal HTTP control plane, không phải Kafka-first orchestration
- `project-srv` vẫn publish Kafka lifecycle events, nhưng đó không phải main execution path
- `scapper-srv` hiện có FastAPI app + worker lifespan, có storage abstraction và có completion publish codepath
- với `scapper-srv`, code hiện tại đáng tin hơn README ở các điểm README chưa cập nhật

## 3. Blockers Phải Sửa Trước Khi Migrate

## 3.1 Frontend evidence đang bị sai

### Evidence từ source

- `web-ui/package.json`
- `web-ui/next.config.ts`
- `web-ui/pages/**/*.tsx`
- `web-ui/hooks/useProjectWebSocket.ts`
- `web-ui/services/websocketService.ts`

### Có thể khẳng định an toàn

- frontend đang dùng `Next.js`
- frontend đang dùng `React`
- frontend có i18n qua `next-i18next`
- frontend có test tooling như `jest`
- frontend có WebSocket client logic và dashboard/report pages

### File đang sai và hành động sửa

- [ ] `thesis/00_technology_inventory.md`
  Action: bỏ claim “không có `package.json`”; thêm một mục frontend tối thiểu với bằng chứng từ `web-ui/package.json`.

- [ ] `thesis/chapter_2_theoretical_background_and_technologies.md`
  Action: rewrite toàn bộ mục `2.4 Frontend Technologies`.
  Replace direction:
  - không viết “không tìm thấy package.json”
  - chuyển sang mô tả có bằng chứng trực tiếp cho `Next.js 15`, `React 19`, `next-i18next`, `Jest`, `TailwindCSS`
  - nếu chưa muốn đi sâu state management thì chỉ nói “chưa khóa đầy đủ state architecture”, không nói “không có frontend source”

- [ ] `thesis/chapter_5_implementation.md`
  Action: rewrite mục `5.5 User Interface Gallery`.
  Replace direction:
  - bỏ câu “không tìm thấy package.json hoặc thư mục frontend source code nào trong workspace”
  - đổi sang “workspace có `web-ui` source, nhưng phần gallery chỉ nên mô tả các surface có evidence rõ trong pages/components”
  - có thể liệt kê ngắn: authentication pages, project dashboard flows, report wizard, websocket test/client

- [ ] `thesis/chapter_6_evaluation_and_testing.md`
  Action: sửa `Threats to Validity` để bỏ claim “frontend source chưa hiện diện trong workspace”.
  Replace direction:
  - đổi thành “frontend hiện diện nhưng thesis hiện chưa audit sâu toàn bộ UI behavior và test coverage frontend”

- [ ] `thesis/chapter_7_conclusion.md`
  Action: sửa `Limitations` và `Future Development`.
  Replace direction:
  - không nói “chưa có frontend source code”
  - đổi thành “frontend evidence đã có, nhưng chưa được phân tích sâu ngang backend”
  - giữ hạn chế về `CI/CD artifacts` nếu chưa có bằng chứng

- [ ] `thesis/README.md`
  Action: sửa quy ước cuối file; bỏ claim frontend chưa được xác nhận.

- [ ] `thesis/chapter_outline_3_7.md`
  Action: sửa mục `5.5 User Interface Gallery`; bỏ câu “hiện chưa có frontend source trong workspace”.

## 3.2 Path references trong plan đang lệch workspace thật

### Vấn đề

Các phase docs từng dùng path giả định kiểu `report/thesis` và `document/reporting`, trong khi workspace hiện tại dùng:

- `report_SMAP/phong_tmp/new-report/thesis`
- `report_SMAP/final-report`

### File cần sửa

- [ ] `phase_1_audit_and_source_of_truth.md`
  Action: đổi toàn bộ `report/thesis` -> `report_SMAP/phong_tmp/new-report/thesis` và `document/reporting` -> `report_SMAP/final-report` hoặc diễn đạt tương đối theo vị trí hiện tại.

- [ ] `phase_2_typst_shell_restructure.md`
  Action: sửa input truth cho đúng `main.typ`, `config.typ`, `counters.typ` trong `final-report` và `thesis_master.md` trong `new-report/thesis`.

- [ ] `phase_3_content_migration_by_chapter.md`
  Action: sửa các path `report/thesis/*.md` thành path thật của thư mục `thesis/` hiện tại.

- [ ] `phase_4_figures_tables_references_appendix.md`
  Action: sửa các path asset, list, references, appendix theo cây thư mục hiện tại.

- [ ] `phase_5_final_qa_and_submission_freeze.md`
  Action: sửa reference tới `submission_checklist.md` theo path hiện tại trong `new-report/thesis`.

### Ghi chú

- không nhất thiết phải hard-code absolute path
- nhưng phải dùng cùng một quy ước path xuyên suốt plan để người migrate không hiểu sai nguồn

## 3.3 Lifecycle narrative phải khóa lại trước khi viết chương 3-5

### Evidence từ code

- `project-srv/internal/project/usecase/lifecycle.go`
- `project-srv/pkg/microservice/ingest/usecase.go`
- `project-srv/pkg/microservice/ingest/endpoint.go`
- `ingest-srv/internal/datasource/delivery/http/routes.go`
- `ingest-srv/internal/datasource/usecase/project_lifecycle.go`
- `project-srv/internal/project/types.go`
- `project-srv/internal/project/delivery/kafka/producer/producer.go`

### Current-state nên mô tả

- `project-srv` gọi internal HTTP sang `ingest-srv` để:
  - check activation readiness
  - activate project datasources
  - pause runtime
  - resume runtime
- sau khi update local status, `project-srv` publish Kafka lifecycle event kiểu:
  - `project.lifecycle.activated`
  - `project.lifecycle.paused`
  - `project.lifecycle.resumed`
  - `project.lifecycle.archived`
  - `project.lifecycle.unarchived`

### Rule cho report

- [ ] Không mô tả Kafka là main orchestration path giữa `project-srv` và `ingest-srv`
- [ ] Nếu nhắc Kafka lifecycle events, phải ghi rõ đây là event lane hậu transition hoặc secondary propagation lane
- [ ] Sequence diagram cho activation/pause/resume phải vẽ internal HTTP path trước

### File cần rà đặc biệt

- [ ] `thesis/chapter_3_system_analysis.md`
  Action: rà lại use case và FR-03 wording để không gợi hiểu Kafka-first lifecycle.

- [ ] `thesis/chapter_4_system_design.md`
  Action: rà toàn bộ phần transport specialization, sequence diagrams, API design và architecture decision matrix.

- [ ] `thesis/chapter_5_implementation.md`
  Action: rà các đoạn core feature implementation liên quan lifecycle để mô tả internal control plane là current path.

## 3.4 `scapper-srv` current-state phải phân biệt rõ code và README

### Evidence từ code

- `scapper-srv/app/main.py`
- `scapper-srv/app/worker.py`
- `scapper-srv/app/publisher.py`
- `scapper-srv/app/storage.py`
- `scapper-srv/RABBITMQ.md`

### Những gì có thể khẳng định từ code

- `scapper-srv` là FastAPI app có worker chạy trong lifespan
- worker save raw result qua storage abstraction
- `MODE=production` có code upload MinIO
- worker publish completion message sau khi save artifact
- completion queue được route theo runtime kind sang `ingest_task_completions` hoặc `ingest_dryrun_completions`

### Điều phải cẩn thận

- README của `scapper-srv` vẫn còn dòng nói MinIO upload và completion publish “Not implemented yet”
- phần current-state trong thesis phải ưu tiên code hiện tại, không copy nguyên README snapshot này

### File cần rà

- [ ] `thesis/01_source_evidence_matrix.md`
  Action: giữ bằng chứng ở `app/publisher.py` và `app/main.py`; nếu cần, bổ sung `app/storage.py` và `app/worker.py` để chứng minh completion + storage path.

- [ ] `thesis/chapter_5_implementation.md`
  Action: nếu mô tả `scapper-srv`, phải ghi rõ current runtime là FastAPI + worker lifespan + completion publish path.

- [ ] `thesis/chapter_4_system_design.md`
  Action: nếu vẽ crawl runtime sequence, phải dùng completion envelope + storage metadata hiện tại, không dùng local-output-only narrative.

## 3.5 Mức tin cậy của source phải được phân tầng

### Quy tắc dùng source

- tier 1: code, route, config, manifest, migration
- tier 2: canonical contract docs như `RABBITMQ.md`
- tier 3: README
- tier 4: legacy docs, old diagrams, proposal docs

### Rule cho migration

- [ ] Nếu README và code conflict, ưu tiên code
- [ ] Nếu old report conflict với code, rewrite hoàn toàn thay vì cố vá câu chữ
- [ ] Nếu chưa đủ evidence, ghi là `partial`, `target`, hoặc `limitation`

## 4. Suggested Fix Order

1. Sửa toàn bộ mismatch về frontend evidence trong `thesis/*`.
2. Sửa toàn bộ path references trong `phase_1` đến `phase_5`.
3. Rà lại `chapter_3`, `chapter_4`, `chapter_5` theo lifecycle current-state.
4. Rà `scapper-srv` narrative trong `chapter_4`, `chapter_5`, `01_source_evidence_matrix.md`.
5. Chỉ sau đó mới bắt đầu migrate nội dung sang `final-report` Typst.

## 5. Definition of Ready Trước Khi Port Vào `final-report`

- [ ] Không còn file nào trong `thesis/` nói workspace không có frontend source hoặc không có `package.json`
- [ ] Không còn phase doc nào dùng path giả định `report/thesis` hoặc `document/reporting`
- [ ] Chương 3-5 đã khóa narrative `project -> ingest = internal HTTP main path`
- [ ] Narrative về `scapper-srv` đã bám code hiện tại, không bám README cũ
- [ ] Sau khi đạt đủ các điều kiện trên mới bắt đầu port sang Typst
