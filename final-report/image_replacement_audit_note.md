# Note - Image Replacement Audit

## Mục đích

Ghi lại các phần trong `final-report` hiện vẫn đang dùng hình cũ hoặc asset legacy để thay thế ở bước hoàn thiện sau.

## Lưu ý

- File này chỉ là note nội bộ cho quá trình hoàn thiện báo cáo.
- Không phải nội dung để đưa vào phần report chính.
- Placeholder hiện có ở một số mục được giữ lại để dễ nhận biết chỗ còn thiếu hình cần thay.

## Các mục đang dùng hình mới hoặc asset current-state

- `chapter_4/section_4_5.typ`
  - đang dùng SVG current-state trong `report/final-report/images/chapter_3/` và `report/final-report/images/chapter_4/`
- `chapter_5/section_5_2.typ`
  - đang dùng placeholder cho `c4-container-current.svg`

## Các mục đang dùng hình cũ / legacy asset và cần thay

### Chương 5.3

- `chapter_5/section_5_3.typ`
  - `../images/component/collector-component-diagram.png`
  - `../images/data-flow/project_created_dispatching.png`
  - `../images/data-flow/dispatcher_usecase_dispatch_logic.png`
  - `../images/data-flow/crawler_results_processing.png`
  - `../images/component/analytic-component-diagram.png`
  - `../images/data-flow/analytics_ingestion.png`
  - `../images/data-flow/analytics-pipeline.png`
  - `../images/component/project-component-diagram.png`
  - `../images/data-flow/project_create.png`
  - `../images/data-flow/execute_project.png`
  - `../images/data-flow/webhook_callback.png`
  - `../images/component/identity-component-diagram.png`
  - `../images/data-flow/user_registration_flow.png`
  - `../images/data-flow/user_login.png`
  - `../images/data-flow/auth_middleware.png`
  - `../images/component/websocket-component-diagram.png`
  - `../images/data-flow/webSocket_connection.png`
  - `../images/data-flow/real-time.png`
  - `../images/component/webui-component-diagram.png`
  - `../images/data-flow/authen.png`
  - nhóm ảnh UI trong `../images/UI/*.png`

### Chương 5.4

- `chapter_5/section_5_4.typ`
  - `../images/erd/identity-erd.png`
  - `../images/erd/project-erd.png`
  - `../images/erd/analytic-erd.png`

### Chương 5.5

- `chapter_5/section_5_5.typ`
  - toàn bộ nhóm ảnh sequence legacy trong `../images/sequence/*.png`

### Chương 5.7

- `chapter_5/section_5_7.typ`
  - `../images/deploy/deployment-diagram.drawio.png`

## Gợi ý ưu tiên thay thế

1. Thay hình trong `5.3` trước vì đây là phần lệch current implementation mạnh nhất.
2. Thay hình trong `5.5` sau khi chốt lại bộ sequence/use case final.
3. Thay hình `5.4` khi chốt xong data/storage narrative của chương.
4. Thay hình `5.7` sau khi chốt deployment narrative cuối cùng.
