#import "../counters.typ": image_counter, table_counter

=== 5.5.5 UC-05: Quản lý danh sách Projects

UC-05 mô tả quy trình quản lý danh sách Projects của Marketing Analyst, bao gồm xem, lọc, tìm kiếm, và điều hướng đến các chức năng khác tùy theo trạng thái Project. Đây là entry point chính của hệ thống sau khi user đăng nhập.

==== 5.5.5.1 List View và Filtering

#align(center)[
  #image("../images/sequence/uc5_list_part_1_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 1-1: Projects List View và Filtering_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc5_list_part_1_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 1-2: Projects List View và Filtering_]
)
#image_counter.step()

Luồng xử lý:

- User navigate đến Projects page từ navigation menu hoặc sau login.

- Web UI gửi GET request đến Project Service với JWT authentication.

- Project Service query PostgreSQL với filters: created_by = user_id AND deleted_at IS NULL.

- Trả về danh sách Projects với metadata: tên, status badge, ngày tạo, last_updated, preview brand keywords (3 keywords đầu).

- Web UI render Projects list với filters UI: status dropdown, search box, sort options.

- User áp dụng filters và hệ thống query lại với WHERE clause tương ứng.

- Nếu có > 50 projects thì apply pagination với 20 items/page và infinite scroll.

==== 5.5.5.2 Navigation và Actions

#align(center)[
  #image("../images/sequence/uc5_list_part_2_1.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 2-1: Status-based Navigation và Actions_]
)
#image_counter.step()

#align(center)[
  #image("../images/sequence/uc5_list_part_2_2.png", width: 100%)
]
#context (
  align(center)[_Hình #image_counter.display(): Sequence Diagram UC-05 Part 2-2: Status-based Navigation và Actions_]
)
#image_counter.step()

Luồng xử lý:

- User click vào Project card hoặc action button.

- Web UI check status và navigate accordingly:
  - Draft → UC-01 (Edit configuration) hoặc UC-03 (Execute)
  - Running → UC-03 (Monitor progress page)
  - Completed → UC-04 (View dashboard)
  - Failed → UC-03 (Retry with same config)

- User có thể click "Xuất báo cáo" button (chỉ hiện với Completed status) → Navigate to UC-06.

- User có thể click "Xóa" button → Hiển thị confirmation dialog.

- Nếu confirm delete: Project Service soft delete (set deleted_at = NOW()), Project biến mất khỏi list, hiển thị toast "Đã xóa Project".

- Running projects không có nút "Xóa" (button disabled theo business rule).
