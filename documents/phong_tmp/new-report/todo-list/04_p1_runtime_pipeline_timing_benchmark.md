# P1 - Runtime and Pipeline Timing Benchmark

## Mục tiêu

Đo thời gian hoàn thành của các luồng bất đồng bộ quan trọng để bổ sung số liệu cho phần đánh giá runtime.

## Vì sao cần làm

Các API latency chưa phản ánh phần khó nhất của SMAP. Hệ thống còn có dryrun, completion handling và analytics pipeline là các lane bất đồng bộ cần được đo ở mức thời gian hoàn thành.

## Luồng nên đo

1. Thời gian từ `trigger_dryrun` đến terminal status
2. Thời gian từ completion message đến raw batch được persist
3. Thời gian từ Kafka ingest message đến analytics output publish

## Nguồn liên quan

- `test/full_check/test_runtime_completion_e2e.py`
- `analysis-srv/tests/e2e/test_output_contract.py`
- `analysis-srv/internal/consumer/server.py`

## Việc cần làm

1. Chọn một môi trường chạy ổn định.
2. Ghi timestamp đầu/cuối cho từng luồng.
3. Chạy lặp lại nhiều lần nếu có thể.
4. Tổng hợp thời gian trung bình và nhận xét.

## Kết quả đầu ra mong muốn

- `runtime_pipeline_timing.md`
- bảng thời gian hoàn thành cho từng luồng
- ghi chú rõ đây là benchmark ở mức hệ thống tích hợp, không phải benchmark production-scale

## Ưu tiên

P1 - đây là phần định lượng gần nhất với giá trị kỹ thuật cốt lõi của hệ thống.
