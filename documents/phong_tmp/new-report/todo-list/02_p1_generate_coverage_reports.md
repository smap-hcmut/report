# P1 - Generate Coverage Reports

## Mục tiêu

Sinh coverage artifact thực tế cho ít nhất một số thành phần chính của hệ thống để tăng sức nặng cho phần đánh giá và kiểm thử.

## Vì sao cần làm

Hiện repo có config và hướng dẫn coverage ở nhiều nơi, nhưng chưa có file output coverage rõ ràng được dùng làm bằng chứng trong report final.

## Nguồn có sẵn

- `web-ui/package.json` với lệnh `test:coverage`
- `shared-libs/python/README.md` với `pytest --cov`
- `identity-srv/documents/identity-report.md`
- `notification-srv/documents/notification-srv-report.md`

## Việc cần làm

1. Chọn 1-2 service khả thi nhất để sinh coverage thực tế.
2. Chạy coverage và lưu file output.
3. Trích các chỉ số tối thiểu: tổng coverage, package chính, command đã dùng.
4. Chụp lại command và kết quả vào artifact markdown.

## Kết quả đầu ra mong muốn

- `coverage_summary.md`
- file coverage gốc như `coverage.out`, `coverage.xml`, `htmlcov/` hoặc tương đương
- bảng coverage có thể đưa vào Chương 6

## Ưu tiên

P1 - coverage không thay thế benchmark, nhưng là điểm cộng mạnh cho rubric về tính hoàn thiện và kiểm thử.
