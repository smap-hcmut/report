# Gap Analysis - phong_tmp/ingest/api_config_project_ingest.md

## Verdict

File này gần với flow thao tác của FE hơn các docs cũ khác, nhưng vẫn lệch ở một số rule runtime rất quan trọng:

- status update qua `PUT /projects/{id}` bị over-permissive,
- dryrun bị mô tả như optional/control-plane only,
- target activation semantics chưa phản ánh đúng,
- archive/delete semantics thiếu chính xác,
- flow hiện đang xem nhẹ readiness thật.

## Matrix

| Cụm claim cũ | Claim cũ | Implement thực tế | Mức lệch | Nên sửa như nào |
| --- | --- | --- | --- | --- |
| `PUT /projects/{projectId}` | Có thể dùng để đổi `status`. | Runtime hiện tại lifecycle status không nên đổi qua generic update; phải dùng các command riêng `activate/pause/resume/archive/unarchive/delete`. | Critical | Xóa ý "sửa status bằng PUT project"; thay bằng lifecycle command list. |
| `POST /datasources` + target create flow | Sau khi tạo target là có thể đi tiếp khá tự nhiên. | Runtime thực tế target mới tạo mặc định inactive; để vào runtime cần dryrun usable hoặc activate đúng guard. | High | Thêm ghi chú: target create không đồng nghĩa target ready for runtime. |
| `Dry run optional` | Có thể bỏ qua dryrun và dừng ở bước tạo target. | Với current project readiness, bỏ qua dryrun thường đồng nghĩa project activation/resume sẽ bị block vì target không có latest usable dryrun. | High | Sửa thành: dryrun có thể không bắt buộc về mặt API call, nhưng gần như là required để project readiness pass trên crawl paths. |
| `Dry run control-plane only` | Dryrun không tạo external task, không publish RabbitMQ, pass sẽ trả `WARNING` chứ không `SUCCESS`. | Runtime hiện tại dryrun đi qua publish task/completion pipeline; terminal có `SUCCESS`, `WARNING`, `FAILED`; usable result còn auto-activate target. | Critical | Rewrite hoàn toàn section dryrun. |
| `GET latest/history ở mức datasource chung` | Gợi ý strong rằng dryrun nhìn theo datasource chung là hợp lý mặc định. | Runtime hiện tại lineage quan trọng là datasource + target; đọc ở mức datasource chung dễ mất meaning runtime. | Medium | Nhấn mạnh target lineage là primary view; datasource-wide view chỉ là aggregate/secondary. |
| `DELETE /api/v1/datasources/{id}` | Có thể dùng để archive datasource không còn dùng. | Runtime hiện tại archive và delete tách riêng; delete chỉ sau archive và là soft delete. | Critical | Đổi flow xóa datasource thành hai bước: archive rồi delete. |
| `DELETE /api/v1/projects/{projectId}` | Có thể xóa project như bước cleanup thông thường. | Runtime hiện tại project delete chỉ hợp lệ sau archived. | High | Thêm guard này vào flow cleanup. |

## Cụm lệch chi tiết

### 1. File này đang "quá CRUD-oriented"

Nó mô tả flow như thể:

- campaign/project/datasource/target đều có thể sửa khá tự do qua `PUT`,
- còn lifecycle chỉ là một loại chỉnh sửa status.

Trong runtime hiện tại:

- project status là command-based,
- datasource lifecycle có guard riêng,
- target activation có guard riêng,
- generic update không thay thế lifecycle command.

### 2. Dryrun đang bị mô tả quá nhẹ

Câu "dry run optional" tự nó không sai ở level HTTP, nhưng sai nếu hiểu theo runtime behavior.

Thực tế:

- không dryrun => thường không có latest usable dryrun,
- không latest usable dryrun => target không thể được xem là runtime-ready,
- project readiness rất dễ fail.

Vì vậy câu chữ nên đổi từ:

- "optional"

sang:

- "không bắt buộc về mặt API, nhưng là prerequisite thực tế cho crawl runtime readiness".

### 3. Target create không đồng nghĩa active runtime

Ví dụ body trong file có `is_active: true` dễ làm FE hiểu rằng target có thể được tạo và active ngay.

Nhưng rule runtime hiện tại là:

- target create mặc định inactive,
- activation phải qua usable dryrun hoặc side effect từ dryrun completion.

Nếu file này tiếp tục dùng ví dụ active-by-default, team UI/API rất dễ dựng luồng sai kỳ vọng.

## Rewrite đề xuất

### Phần `Flow Gợi Ý Theo UX` nên đổi

Flow crawl chuẩn:

1. Tạo campaign
2. Tạo project dưới campaign
3. Cấu hình crisis config nếu cần
4. Tạo datasource crawl
5. Tạo target
6. Trigger dryrun per target
7. Xem latest dryrun theo target
8. Cho project activate chỉ khi readiness pass

### Những warning nên thêm trực tiếp vào file

- `PUT /projects/:id` không dùng để đổi lifecycle status.
- Target mới tạo chưa được xem là active runtime.
- Dryrun bỏ qua có thể khiến project activation fail.
- Datasource delete không thay thế archive.

## Kết luận

File này đáng cập nhật vì nó gần với flow FE thật. Nếu sửa đúng, nó sẽ rất hữu ích cho team tích hợp UI/API mà không bị lệch kỳ vọng runtime.
