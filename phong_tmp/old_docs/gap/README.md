# Gap Analysis Pack

Mục tiêu của thư mục này:

- Đối chiếu từng tài liệu cũ với implementation thực tế hiện tại.
- Chuẩn hóa theo format: `doc cũ -> claim -> implement thực tế -> mức lệch -> nên sửa như nào`.
- Dùng `phong_tmp/code-derived-brd-srs` làm baseline chính vì bộ này đã được trích từ implementation hiện tại.

Nguồn chuẩn để đối chiếu:

- `phong_tmp/code-derived-brd-srs/00-rule-inventory-master.md`
- `phong_tmp/code-derived-brd-srs/01-overview.md`
- `phong_tmp/code-derived-brd-srs/02-project-domain.md`
- `phong_tmp/code-derived-brd-srs/03-ingest-datasource-target-domain.md`
- `phong_tmp/code-derived-brd-srs/04-dryrun-execution-scheduler-domain.md`
- `phong_tmp/code-derived-brd-srs/05-identity-boundary-domain.md`
- `phong_tmp/code-derived-brd-srs/06-gap-register.md`

## File index

1. `01-project-service-status-gap.md`
   - Lệch giữa project docs cũ và lifecycle/readiness thực tế.
2. `02-ingest-service-status-gap.md`
   - Lệch giữa ingest docs cũ và runtime thực tế của datasource/target/dryrun/execution.
3. `03-api-endpoints-gap.md`
   - Lệch về API surface, route naming, archive/delete semantics, internal routes.
4. `04-dataflow-detailed-gap.md`
   - Lệch về orchestration, onboarding, dryrun flow, topic naming, adaptive crawl.
5. `05-migration-plan-gap.md`
   - Lệch lớn nhất giữa product spec cũ và implementation hiện tại.
6. `06-master-proposal-gap.md`
   - Lệch ở proposal project-centric/event-driven so với runtime đang chạy.
7. `07-api-config-project-ingest-gap.md`
   - Lệch ở flow vận hành thực tế của FE/API orchestration.
8. `08-crisis-gap.md`
   - Lệch ở crisis/adaptive crawl design so với phần runtime đã implement.
9. `09-cross-doc-conflicts.md`
   - Các mâu thuẫn giữa chính các docs cũ với nhau.

## Nhận định tổng quát

Pattern lệch chính hiện tại:

- Docs cũ mô tả hệ thống theo hướng `product-complete`, nhất là `passive onboarding`, `adaptive crawl`, `crisis orchestration`, `wizard states`, và `Kafka event choreography`.
- Implementation hiện tại lại rõ ràng hơn ở `runtime core`: `project lifecycle`, `datasource/target`, `per-target dryrun`, `execution/scheduler`, `MinIO artifact contract`, `JWT/internal key boundary`.
- Nhiều nhánh được docs cũ coi như "đã là behavior chính thức" thực tế mới ở mức `Partially implemented` hoặc `Gap`.

## Quy ước mức lệch

- `Critical`
  - Claim cũ nếu giữ nguyên sẽ dẫn tới implement sai boundary hoặc hiểu sai behavior runtime.
- `High`
  - Claim cũ mô tả sai flow/runtime contract quan trọng, nhưng không phải mọi phần đều sai.
- `Medium`
  - Claim cũ đúng một phần nhưng thiếu guard, thiếu nuance, hoặc dùng ngôn ngữ dễ gây hiểu nhầm.
- `Low`
  - Chủ yếu là naming, route naming, hoặc thiếu cập nhật coverage/gap status.

## Thứ tự nên sửa docs

1. `migration-plan.md`
2. `dataflow-detailed.md`
3. `project/master-proposal.md`
4. `project-service-status.md`
5. `ingest-service-status.md`
6. `api-endpoints.md`
7. `api_config_project_ingest.md`
8. `crisis.md`

## Cách dùng pack này

- Nếu mục tiêu là cập nhật tài liệu sản phẩm: giữ cấu trúc business, nhưng đánh dấu rõ phần nào là `Implemented`, phần nào là `Planned`, phần nào là `Gap`.
- Nếu mục tiêu là viết BRD/SRS mới: bỏ các claim `aspirational`, lấy trực tiếp từ `code-derived-brd-srs`.
- Nếu mục tiêu là cleanup docs cũ: ưu tiên sửa các mục có mức lệch `Critical` và `High` trước.
