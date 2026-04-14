# P1 - Core API Latency Benchmark

## Mục tiêu

Đo thời gian phản hồi của một số API lõi để có số liệu định lượng tối thiểu cho phần đánh giá hiệu năng.

## Vì sao cần làm

Rubric có yêu cầu kết quả thực nghiệm hoặc đánh giá hiệu năng. Nếu chưa có benchmark toàn hệ thống, chỉ cần một bộ đo tối thiểu cho các API lõi cũng đã giúp phần report mạnh hơn rất nhiều.

## API nên chọn

1. Tạo project
2. Lấy activation readiness
3. Lấy dryrun latest/history
4. Search endpoint của `knowledge-srv`

## Việc cần làm

1. Chọn công cụ đo đơn giản, dễ lặp lại.
2. Chạy tối thiểu 20-30 lần cho mỗi endpoint.
3. Ghi `min`, `avg`, `p95`, `max` nếu làm được.
4. Ghi rõ dữ liệu đầu vào và môi trường chạy.

## Kết quả đầu ra mong muốn

- `api_latency_benchmark.md`
- bảng chỉ số latency theo endpoint
- mô tả môi trường và giới hạn của phép đo

## Ưu tiên

P1 - đây là bộ benchmark hiệu năng dễ làm nhất và có giá trị trực tiếp cho report final.
