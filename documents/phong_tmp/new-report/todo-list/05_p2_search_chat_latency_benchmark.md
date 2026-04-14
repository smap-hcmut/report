# P2 - Search and Chat Latency Benchmark

## Mục tiêu

Đo thời gian phản hồi của các luồng tìm kiếm và hỏi đáp theo ngữ cảnh để bổ sung số liệu cho lớp knowledge.

## Vì sao cần làm

Knowledge layer là một điểm nổi bật của hệ thống. Nếu có được số liệu response time cho search/chat, report sẽ cân bằng hơn giữa backend runtime và lớp khai thác thông tin.

## Luồng nên đo

1. Search request với query ngắn
2. Search request có filter theo project/campaign
3. Chat request với câu hỏi đơn giản
4. Chat request có trích dẫn và context retrieval

## Việc cần làm

1. Chọn 1 bộ dữ liệu hoặc 1 project mẫu ổn định.
2. Ghi latency theo nhiều lần chạy.
3. Tách nếu được giữa thời gian truy vấn và thời gian sinh câu trả lời.
4. Ghi rõ đây là số liệu môi trường thử nghiệm, không phải SLA production.

## Kết quả đầu ra mong muốn

- `knowledge_latency_benchmark.md`
- bảng latency search/chat

## Ưu tiên

P2 - có lợi cho report, nhưng đứng sau API và runtime benchmark cốt lõi.
