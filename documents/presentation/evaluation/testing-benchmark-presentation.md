# Testing And Benchmark Presentation Notes

Tài liệu này là note để trình bày phần đánh giá hệ thống trong slide. Mục tiêu là nói ngắn, có số liệu, có caveat, và bám đúng evidence hiện có trong `report/final-report/chapter_6` cùng `report/benchmark/reports/20260520-204400/benchmark-report.md`.

## Cách chia slide nên dùng

Khuyến nghị dùng 4 slide chính và 1 slide phụ backup:

1. Mục tiêu và phạm vi đánh giá
2. Kết quả kiểm thử chức năng và đầu cuối
3. Kết quả NFR trong report chính
4. Kết luận và giới hạn
5. Backup: benchmark report chi tiết

Nếu thời gian rất ngắn, gộp slide 1 và 2 lại, giữ slide 3 và 4.

## Slide 1 - Mục tiêu và phạm vi đánh giá

### Thông điệp chính

- Phần đánh giá không chỉ kiểm tra API có trả kết quả hay không.
- Nhóm kiểm tra cả logic nội bộ, luồng liên dịch vụ, và một phần hiệu năng trong môi trường tham chiếu.

### Nội dung nên đặt trên slide

Tiêu đề gợi ý: `Đánh giá hệ thống`

- 4 lớp kiểm thử:
- Unit test
- Integration test
- End-to-end test
- Non-functional evaluation

- Đánh giá bám theo service boundary:
- `identity-srv`
- `project-srv`
- `ingest-srv`
- `analysis-srv`
- `knowledge-srv`
- `notification-srv`
- `crawler worker`

### Câu nói gợi ý

> Nhóm em chia đánh giá thành bốn lớp: unit, integration, end-to-end và phi chức năng. Điểm quan trọng là các bằng chứng này bám đúng ranh giới service của kiến trúc microservices, chứ không chỉ kiểm tra một vài endpoint riêng lẻ.

## Slide 2 - Kết quả kiểm thử chức năng và đầu cuối

### Thông điệp chính

- Các luồng chính của hệ thống đều đã có evidence kiểm thử.
- Kiểm thử không dừng ở CRUD, mà đi qua cả activation, asynchronous ingest, analytics, knowledge và notification.

### Nội dung nên đặt trên slide

Tiêu đề gợi ý: `Bằng chứng kiểm thử chức năng`

Bạn nên dùng một bảng 3 cột:

| Nhóm chức năng | Evidence chính | Kết quả nói trên slide |
| --- | --- | --- |
| Campaign / Project | `project-srv` unit test, CRUD/lifecycle scenario | Campaign CRUD `8/8`, project CRUD/lifecycle `12/12` |
| Datasource / Target / Activation | `ingest-srv` unit test, readiness + activate flow | Có bằng chứng đầy đủ cho cấu hình và activation |
| Ingestion pipeline | RabbitMQ, crawler task, MinIO, raw batch, UAP | Có bằng chứng task dispatch -> completion -> parse UAP |
| Analytics / Knowledge | `analysis-srv` tests, search/chat/report flow | Pipeline và downstream retrieval có evidence |
| Notification | Redis delivery, WebSocket route, analytics bridge | Có evidence route/delivery nội bộ; chưa chốt full client latency |

### Số liệu nên nhắc

- `analysis-srv`: `309 passed`
- `ingest-srv`: `15` package pass, các package được đo đều `100.0% of statements`
- `project-srv`, `notification-srv`, `knowledge-srv`, `shared-libs`, `crawler worker` đều có unit test pass ở các module được liệt kê trong report

### Câu nói gợi ý

> Về chức năng, nhóm em có evidence cho các luồng chính như campaign/project, datasource/target, activation, crawl task, search/chat/report và notification delivery. Ví dụ, `analysis-srv` có 309 test pass, còn `ingest-srv` có 15 package pass ở các module datasource, dry run, execution và UAP.

## Slide 3 - Kết quả NFR trong report chính

### Thông điệp chính

- Phần NFR chính thức trong báo cáo tập trung vào API-lane.
- Kết quả đủ tốt trong cửa sổ workload đã đo, nhưng không được diễn giải thành production SLA.

### Nội dung nên đặt trên slide

Tiêu đề gợi ý: `Kết quả phi chức năng`

Bạn nên dùng 1 bảng ngắn:

| Kịch bản | Throughput | p95 | Infra error |
| --- | --- | --- | --- |
| Baseline -> Peak | `6.949 - 7.440 req/s` | `159.397 - 220.387 ms` | `0.0000 - 0.0360%` |
| Chaos: restart 1 analysis consumer | `7.751 req/s` | `224.661 ms` | `0.0000%` |

Điểm chốt bên dưới bảng:

- API-lane giữ `p95 < 225 ms` trong các scenario đã chạy
- Throughput quan sát: `6.949 - 7.751 req/s`
- Cửa sổ đo: workload `12-20 phút`
- Ý nghĩa: baseline quan sát trong môi trường K3s tham chiếu

### Câu nói gợi ý

> Trong report chính, nhóm em chốt NFR ở API-lane vì đây là phần có thể đo định lượng ổn định nhất. Kết quả cho thấy p95 giữ dưới 225 ms trong các kịch bản đã chạy, throughput quan sát khoảng 6.949 đến 7.751 request mỗi giây, kể cả khi restart một analysis consumer trong kịch bản chaos.

### Câu caveat phải nói rõ

> Đây là baseline trong môi trường tham chiếu, không phải cam kết SLA production và cũng chưa phải hard-limit benchmark của toàn hệ thống.

## Slide 4 - Kết luận và giới hạn

### Thông điệp chính

- Hệ thống đã có bằng chứng kiểm thử tốt cho các luồng trọng yếu.
- Điểm còn thiếu không bị che giấu, mà được nêu rõ như một giới hạn kỹ thuật hiện tại.

### Nội dung nên đặt trên slide

Tiêu đề gợi ý: `Kết luận đánh giá`

- Điểm đạt:
- Có unit test theo service boundary
- Có evidence end-to-end cho các luồng chính
- Có NFR snapshot định lượng cho API-lane

- Giới hạn:
- Notification mới có evidence route và delivery nội bộ, chưa chuẩn hóa client latency end-to-end
- NFR hiện là workload cửa sổ ngắn, chưa phải soak test nhiều giờ
- Chưa chốt các chỉ số như backlog drain time, saturation threshold, MTTR chuẩn hóa
- Benchmark chất lượng AI hiện mới là baseline, chưa phải evaluation học thuật sâu cho mô hình

### Câu nói gợi ý

> Điểm em muốn nhấn mạnh là nhóm không chỉ đưa ra kết quả tốt, mà còn giữ sự trung thực kỹ thuật. Những gì đã đo được thì nhóm chốt bằng số liệu; những gì mới ở mức route, delivery hoặc baseline thì nhóm nói rõ là chưa nên suy rộng.

## Slide phụ backup - Benchmark report chi tiết

Slide này chỉ nên dùng khi hội đồng hỏi sâu về benchmark hoặc bạn còn thời gian.

### Thông điệp chính

- Ngoài NFR snapshot trong report chính, nhóm còn có benchmark report riêng trên live domain.
- Slide này là phụ lục, không nên thay slide NFR chính vì methodology khác.

### Nội dung nên đặt trên slide

Tiêu đề gợi ý: `Benchmark report bổ sung`

Số liệu nổi bật từ `report/benchmark/reports/20260520-204400/benchmark-report.md`:

- Locust:
- `50 concurrent users`
- `91.71 req/s`
- `p95 240 ms`
- `error rate 0.02%`

- Mức zero-error nghiêm ngặt:
- `25 concurrent users`
- `37.78 req/s`
- `p95 270 ms`

- k6 aggregate:
- `1800 requests`
- `avg 63 ms`
- `p95 130 ms`
- `error rate 0.00%`

- AI sentiment quality baseline:
- `Accuracy 0.444`
- `Macro F1 0.440`
- `Weighted F1 0.449`

### Artifact nên chèn nếu cần

- `report/benchmark/reports/20260520-204400/charts/api_p95_by_endpoint.svg`
- `report/benchmark/reports/20260520-204400/charts/locust_p95_by_concurrency.svg`
- `report/benchmark/reports/20260520-204400/charts/ai_sentiment_quality.svg`

### Câu nói gợi ý

> Ngoài NFR snapshot trong Chương 6, nhóm còn có benchmark report riêng trên live domain. Ở lần đo này, mức tải cao nhất vẫn đạt ngưỡng chấp nhận là 50 concurrent users với p95 240 ms và error rate 0.02%. Tuy nhiên, nhóm vẫn coi đây là benchmark có kiểm soát, không phải hard limit của toàn hệ thống.

## Cách bố trí hình và chữ

### Nếu chỉ có 1 slide cho testing + benchmark

Chia slide thành 2 nửa:

- Bên trái: `Testing evidence`
- 4 lớp test
- vài số nổi bật: `309 passed`, `15 ingest packages pass`, `campaign CRUD 8/8`, `project lifecycle 12/12`

- Bên phải: `NFR snapshot`
- `p95 < 225 ms`
- `throughput 6.949 - 7.751 req/s`
- `infra error 0.0000 - 0.0360%`
- dòng caveat: `reference K3s window, not production SLA`

### Nếu có 2 slide riêng

- Slide testing: dùng bảng evidence theo capability
- Slide benchmark: dùng 1 chart + 1 bảng ngắn

## Những câu không nên nói

- Không nói `hệ thống đã chứng minh realtime end-to-end`
- Không nói `đã benchmark production scale`
- Không nói `50 users là giới hạn tối đa`
- Không nói `AI model đã đạt chất lượng tốt` nếu chỉ có Accuracy/F1 baseline hiện tại

## Câu chốt an toàn để kết thúc phần này

> Tóm lại, phần đánh giá cho thấy SMAP đã có evidence tốt ở cả ba mặt: logic nội bộ theo service, luồng end-to-end theo kiến trúc, và baseline hiệu năng trong môi trường tham chiếu. Đồng thời, nhóm cũng chỉ ra rõ những phần chưa nên overclaim, đặc biệt là realtime client latency, benchmark dài hạn và chất lượng AI ở mức học thuật sâu hơn.
