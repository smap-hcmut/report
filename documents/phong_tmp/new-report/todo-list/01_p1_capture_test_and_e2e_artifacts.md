# P1 - Capture Test and E2E Artifacts

## Mục tiêu

Tạo một gói hiện vật kiểm thử có thể trích trực tiếp vào Chương 6 để chứng minh hệ thống đã được chạy và xác nhận ở mức thực tế, không chỉ dừng ở việc “có file test trong repo”.

## Vì sao cần làm

Repo hiện có nhiều test files và báo cáo E2E, nhưng report final sẽ mạnh hơn nhiều nếu có thêm kết quả chạy test được chụp lại, tổng hợp và đóng gói thành artifact rõ ràng.

## Nguồn có sẵn

- `report_SMAP/documents/phong_tmp/src-of-truth/e2e-report.md`
- `report_SMAP/documents/phong_tmp/src-of-truth/final-report.md`
- `analysis-srv/tests/e2e/test_output_contract.py`
- `test/full_check/test_runtime_completion_e2e.py`
- `test/full_check/test_project_decision_table.py`

## Việc cần làm

1. Chọn một tập test đại diện để chạy lại.
2. Ghi lại môi trường chạy: ngày giờ, service dependencies, biến môi trường chính.
3. Lưu terminal output thành file markdown hoặc text.
4. Tổng hợp bảng: số test chạy, pass/fail, phạm vi kiểm thử, ý nghĩa.
5. Đặt artifact vào một vị trí ổn định để trích vào report.

## Kết quả đầu ra mong muốn

- 1 file `test_execution_summary.md`
- 1 hoặc nhiều file terminal output đi kèm
- 1 bảng có thể đưa thẳng vào Chương 6

## Ưu tiên

P1 - nên làm trước mọi benchmark khác vì đây là artifact dễ tạo và tăng độ tin cậy rõ rệt cho report.
