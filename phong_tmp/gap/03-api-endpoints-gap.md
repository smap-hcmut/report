# Gap Analysis - documents/api-endpoints.md

## Verdict

File này đang sai chủ yếu ở:

- thiếu lifecycle endpoints mới,
- sai nghĩa `DELETE`,
- thiếu internal routes quan trọng,
- path naming của một số internal route không phản ánh runtime contract hiện tại.

## Matrix

| Doc cũ / section | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `Project Service -> Projects` | `DELETE /project/api/v1/projects/:projectId` = archive project. | Runtime hiện tại có `POST /projects/:id/archive` cho archive; `DELETE /projects/:id` là delete thật và chỉ hợp lệ sau archived. | Critical | Tách `Archive` và `Delete` thành 2 route riêng. |
| `Project Service` | Không có `activation-readiness`, `activate`, `pause`, `resume`, `unarchive`. | Các route lifecycle này là phần rất quan trọng của runtime hiện tại. | Critical | Thêm full lifecycle route table. |
| `Ingest Service -> Data Sources` | `DELETE /ingest/api/v1/datasources/:id` = archive data source. | Runtime hiện tại tách `archive datasource` và `delete datasource`; delete là soft delete sau archive. | Critical | Thêm route archive riêng, đổi nghĩa `DELETE`. |
| `Ingest Service -> Crawl Targets` | Chỉ có CRUD target cơ bản. | Runtime còn có `activate target` và `deactivate target`. | High | Thêm target lifecycle endpoints. |
| `Ingest Service -> Dry Run` | Bảng route không nói rõ per-target semantics. | Runtime hiện tại yêu cầu `target_id`; dryrun latest/history cũng cần nhìn theo lineage target khi cần. | Medium | Thêm ghi chú `target_id required for crawl dryrun`, và mô tả latest/history theo target lineage. |
| `Ingest Service -> Internal` | Chỉ có `PUT /.../datasources/:id/crawl-mode` và manual dispatch. | Runtime còn có internal readiness/lifecycle theo project: `GET /internal/projects/:project_id/activation-readiness`, `POST /internal/projects/:project_id/activate|pause|resume`. | Critical | Thêm project-scoped internal routes vì đây mới là contract lifecycle chính. |
| `Authentication Reference` | Internal key chủ yếu gắn với project internal routes; bề mặt project/ingest internal route chưa được mô tả đủ. | Runtime boundary hiện tại dùng `JWT` cho public APIs và `X-Internal-Key` cho internal APIs xuyên project/ingest. | Medium | Sửa auth reference thành matrix `public vs internal`, không chỉ liệt kê rời rạc theo service. |

## Chi tiết các lệch quan trọng

### 1. API surface đang thiếu lifecycle runtime

Nếu một dev mới chỉ nhìn file này, họ sẽ không thấy:

- project readiness view,
- project activate/pause/resume/archive/unarchive/delete,
- target activate/deactivate,
- datasource archive tách khỏi delete,
- project-scoped internal lifecycle routes.

Nghĩa là file endpoint hiện tại phản ánh một hệ thống "CRUD-heavy" hơn hẳn thực tế.

### 2. `DELETE` đang bị dùng sai nghĩa trong docs

Hai chỗ lệch nguy hiểm nhất:

- project: docs cũ dùng `DELETE` như archive,
- datasource: docs cũ dùng `DELETE` như archive.

Trong implementation hiện tại, archive và delete là hai semantics khác nhau:

- archive = chuyển trạng thái/lifecycle,
- delete = xóa sau khi đã archived,
- target delete còn là hard delete chứ không giống datasource.

### 3. Internal API quan trọng nhất đang không được lộ ra

Project/ingest coordination runtime hiện tại dựa vào internal routes chứ không chỉ public CRUD:

- project readiness query xuống ingest,
- ingest activate/pause/resume theo project,
- manual dispatch path,
- crawl-mode update path.

Không đưa các route này vào endpoint reference sẽ làm tài liệu mất phần "contract" quan trọng nhất.

## Rewrite đề xuất

### Nên tổ chức lại file theo 4 khối

1. `Public APIs`
   - identity
   - project
   - ingest
2. `Lifecycle APIs`
   - project lifecycle
   - datasource lifecycle
   - target lifecycle
3. `Internal APIs`
   - readiness
   - project scoped ingest lifecycle
   - crawl-mode
   - manual dispatch
4. `Auth Matrix`
   - JWT / Cookie-Bearer
   - X-Internal-Key

### Các route tối thiểu phải thêm

- `GET /project/api/v1/projects/:id/activation-readiness`
- `POST /project/api/v1/projects/:id/activate`
- `POST /project/api/v1/projects/:id/pause`
- `POST /project/api/v1/projects/:id/resume`
- `POST /project/api/v1/projects/:id/archive`
- `POST /project/api/v1/projects/:id/unarchive`
- `POST /ingest/api/v1/datasources/:id/archive`
- `POST /ingest/api/v1/datasources/:id/targets/:target_id/activate`
- `POST /ingest/api/v1/datasources/:id/targets/:target_id/deactivate`
- `GET /ingest/api/v1/internal/projects/:project_id/activation-readiness`
- `POST /ingest/api/v1/internal/projects/:project_id/activate`
- `POST /ingest/api/v1/internal/projects/:project_id/pause`
- `POST /ingest/api/v1/internal/projects/:project_id/resume`

## Kết luận

File này nên được sửa song song với `project-service-status.md` và `ingest-service-status.md`. Nếu không sửa, frontend/backend integration rất dễ bám nhầm route hoặc hiểu sai semantics của delete/archive.
