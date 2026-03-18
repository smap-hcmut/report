# SMAP Lifecycle Phase 0 Implementation

**Ngày cập nhật:** 2026-03-19  
**Mục tiêu phase:** chốt contract và ranh giới triển khai trước khi sửa code runtime.  
**Tính chất phase:** review-first, docs/contracts only.

## 1. Mục tiêu

Phase 0 không nhằm thêm feature mới vào runtime. Mục tiêu là khóa các quyết định để từ Phase 1 trở đi không còn phải tranh luận lại về:

- lifecycle của `project` và `datasource`
- rule activate
- vị trí của dry run
- internal endpoints cần có
- error contract
- auth nội bộ
- transport strategy `HTTP internal + Kafka`

## 2. Kết quả phải có sau phase này

Sau khi xong Phase 0, team phải có cùng cách hiểu về các điểm sau:

### 2.1 `project.status`

`project` chỉ dùng 1 status field:

- `DRAFT`
- `ACTIVE`
- `PAUSED`
- `ARCHIVED`

### 2.2 `datasource.status`

Giữ lifecycle hiện có ở `ingest-srv`:

- `PENDING`
- `READY`
- `ACTIVE`
- `PAUSED`
- `FAILED`
- `COMPLETED`
- `ARCHIVED`

### 2.3 Dry run

- Dry run chỉ tồn tại ở level `target` / `datasource`
- Không có project-level dry run state
- Mặc định dry run lấy `10` sample mỗi target
- Giá trị `10` phải đi qua named constant / config enum, không hard-code magic number

### 2.4 Rule activate project

Project chỉ được activate khi:

1. có ít nhất `1 datasource`
2. nếu có passive datasource thì datasource đó đã `confirmed`
3. với crawl datasource, mọi target bắt buộc đã từng có dry run
4. không có target nào có latest dry run là `FAILED`

### 2.5 Failure semantics

- Activate là `fail toàn bộ`
- Chỉ cần 1 readiness condition fail thì request activate fail

### 2.6 Archive / unarchive

- `ARCHIVED` là hồi được
- `project`: `ARCHIVED -> PAUSED`
- `datasource`: `ARCHIVED -> PAUSED`
- Không auto `ACTIVE` sau khi unarchive

### 2.7 Internal endpoints

Internal endpoint phải mang namespace `/internal` để phân biệt rõ với public API.

### 2.8 Auth nội bộ

- service-to-service dùng shared internal key
- auth failure giữ status code riêng từ middleware/auth layer

### 2.9 Error contract

- business/input error: `400`
- infra error: `500`
- `activation-readiness`: luôn trả `200` nếu request hợp lệ, và dùng `can_activate=false` + `errors[]` để báo block

### 2.10 Transport strategy

Hybrid ngay từ đầu:

- internal HTTP cho command/readiness synchronous
- Kafka cho event propagation, audit, downstream sync, async side effects

## 3. Phạm vi file trong phase này

Phase 0 chủ yếu là docs. Không nên sửa runtime code ngoài những thay đổi rất nhỏ phục vụ comment hoặc naming note.

### Files nên có / nên cập nhật

- [smap_lifecycle_completion_plan.md](/Users/phongdang/Documents/GitHub/SMAP/smap_lifecycle_completion_plan.md)
- [smap_lifecycle_phase0_implementation.md](/Users/phongdang/Documents/GitHub/SMAP/smap_lifecycle_phase0_implementation.md)
- [smap_lifecycle_phase1_implementation.md](/Users/phongdang/Documents/GitHub/SMAP/smap_lifecycle_phase1_implementation.md)

### Files không nên đụng ở Phase 0

- runtime code trong `project-srv/internal/**`
- runtime code trong `ingest-srv/internal/**`
- migration
- generated `sqlboiler`

## 4. Internal endpoints đã chốt

## 4.1 Project-level internal endpoints ở `ingest-srv`

- `GET /api/v1/internal/ingest/projects/:project_id/activation-readiness`
- `POST /api/v1/internal/ingest/projects/:project_id/activate`
- `POST /api/v1/internal/ingest/projects/:project_id/pause`
- `POST /api/v1/internal/ingest/projects/:project_id/resume`
- `POST /api/v1/internal/ingest/projects/:project_id/archive`
- `POST /api/v1/internal/ingest/projects/:project_id/unarchive`

## 4.2 Datasource-level internal endpoints ở `ingest-srv`

Giữ cho admin/debug:

- `POST /api/v1/internal/ingest/datasources/:id/activate`
- `POST /api/v1/internal/ingest/datasources/:id/pause`
- `POST /api/v1/internal/ingest/datasources/:id/resume`
- `POST /api/v1/internal/ingest/datasources/:id/archive`
- `POST /api/v1/internal/ingest/datasources/:id/unarchive`
- `PUT /api/v1/internal/ingest/datasources/:id/crawl-mode`

## 4.3 Không thêm project-level dry run endpoint

- `project-srv` không có `POST /projects/:id/dryrun`
- `project-srv` chỉ đọc readiness aggregate

## 5. Response contract tối thiểu cho readiness

`GET /api/v1/internal/ingest/projects/:project_id/activation-readiness`

Response shape tối thiểu nên gồm:

```json
{
  "project_id": "uuid",
  "datasource_count": 2,
  "has_datasource": true,
  "passive_unconfirmed_count": 0,
  "missing_target_dryrun_count": 1,
  "failed_target_dryrun_count": 0,
  "can_activate": false,
  "errors": [
    {
      "code": "TARGET_DRYRUN_MISSING",
      "message": "1 crawl target has never been dry-run",
      "datasource_id": "uuid",
      "target_id": "uuid"
    }
  ]
}
```

## 6. Hybrid transport mapping đã chốt

### Dùng internal HTTP cho

- readiness check
- activate
- pause
- resume
- archive
- unarchive

### Dùng Kafka cho

- publish lifecycle event sau khi command thành công
- audit trail liên service
- downstream sync
- notification

## 7. Review checklist cho Phase 0

- [ ] `project.status` có `DRAFT`
- [ ] dry run chỉ ở `target` / `datasource`
- [ ] activate là fail toàn bộ
- [ ] chưa từng dry run thì block activate
- [ ] latest dry run `FAILED` thì block activate
- [ ] archive hồi được qua `unarchive`
- [ ] internal endpoints có `/internal`
- [ ] error contract đúng: `400` business, `500` infra
- [ ] internal auth dùng shared key
- [ ] hybrid transport được chốt ngay từ đầu
- [ ] giữ datasource-level admin/debug endpoints

## 8. Exit criteria

Phase 0 được coi là hoàn thành khi:

- tài liệu tổng và tài liệu phase không còn mâu thuẫn
- không còn open question nghiệp vụ nào chặn Phase 1
- team có thể bắt đầu sửa code mà không phải reopen decision

## 9. Ngoài scope của Phase 0

- sửa migration
- thêm endpoint runtime
- thêm usecase lifecycle
- thêm ingest HTTP client
- thêm Kafka producer/consumer mới
- sửa test
