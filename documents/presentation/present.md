# Presentation Notes - 3 Sequence Flows

## Files

- `flow_1_campaign_project_activation_sequence.puml`
- `flow_1_campaign_project_activation_sequence.svg`
- `flow_2_ingestion_and_uap_sequence.puml`
- `flow_2_ingestion_and_uap_sequence.svg`
- `flow_3_analytics_knowledge_notification_sequence.puml`
- `flow_3_analytics_knowledge_notification_sequence.svg`

## Slide 1 - Campaign / Project / Activation

Mục tiêu nói: tách rõ business context ở `project-srv` và execution context ở `ingest-srv`.

- Người dùng tạo campaign trước, rồi tạo project nằm dưới campaign đó.
- `project-srv` chịu trách nhiệm validate campaign, validate domain type, rồi lưu project vào PostgreSQL.
- Phần cấu hình thu thập không nằm ở `project-srv`. Người dùng cấu hình datasource và target trực tiếp qua `ingest-srv`.
- `schedule` hiện tại không phải một API riêng. Nó được lưu qua các field như `crawl_mode` và `crawl_interval_minutes` của datasource và target.
- Khi người dùng bấm activate project, `project-srv` không tự chuyển trạng thái ngay. Nó gọi nội bộ sang `ingest-srv` để kiểm tra readiness.
- Nếu readiness fail thì chặn activation. Nếu pass thì `ingest-srv` activate datasource runtime, sau đó `project-srv` mới cập nhật project sang `ACTIVE`.

Câu chốt gợi ý: project activation chỉ thành công khi phần business state và phần ingest runtime cùng sẵn sàng.

## Slide 2 - Ingestion and UAP

Mục tiêu nói: luồng crawl là bất đồng bộ, scale bằng RabbitMQ và artifact storage, không nhồi raw payload vào service core.

- Scheduler của `ingest-srv` quét target đến hạn bằng `ListDueTargets` và claim target trước khi dispatch để tránh race.
- Mỗi lần dispatch sẽ tạo `scheduled_jobs`, sau đó fan-out thành một hoặc nhiều `external_tasks`.
- Task được publish qua RabbitMQ để `scapper-srv` worker xử lý độc lập.
- Worker crawl dữ liệu từ nền tảng mạng xã hội, lưu raw artifact vào MinIO, rồi chỉ gửi completion envelope về RabbitMQ.
- `ingest-srv` consume completion, verify object trong MinIO, ghi `raw_batches`, rồi gọi parser để chuẩn hóa.
- Parser tải artifact về, parse thành UAP record, publish sang topic `smap.collector.output`, đồng thời đánh dấu `raw_batch` đã parse xong.

Câu chốt gợi ý: RabbitMQ và MinIO giúp tách crawl workload nặng khỏi ingest core, còn UAP tạo ra format thống nhất cho downstream analytics.

## Slide 3 - Analytics / Knowledge / Notification

Mục tiêu nói: sau khi có UAP, hệ thống tách thành 3 lane tiêu thụ khác nhau là analytics read model, knowledge indexing, và notification delivery.

- `analysis-srv` consume `smap.collector.output`, group record theo `project_id` và `domain_type_code`, rồi chạy NLP pipeline.
- Kết quả phân tích được lưu vào bảng `analysis.post_insight`.
- Sau đó `analysis-srv` publish 3 lớp output theo thứ tự: `analytics.batch.completed`, `analytics.insights.published`, rồi `analytics.report.digest`.
- `knowledge-srv` là consumer độc lập của các topic `analytics.*` và index vào Qdrant cho search, chat RAG, và report retrieval.
- `notification-srv` không đẩy WebSocket trực tiếp từ Kafka. Nó có bridge consume digest hoặc crisis alert, publish lại vào Redis channel, rồi Redis subscriber mới route sang WebSocket.
- Vì vậy luồng notification là event-driven và gần thời gian thực, nhưng độ trễ end-to-end còn phụ thuộc cadence xử lý ở analytics lane.

Câu chốt gợi ý: cùng một UAP stream nhưng downstream được tách thành read model, vector knowledge, và event delivery để mỗi lane scale độc lập.

## Suggested Opening

- Tôi chia kiến trúc runtime thành 3 luồng để nhìn rõ vòng đời dữ liệu: cấu hình, thu thập, và khai thác kết quả.
- Cả 3 hình đều được vẽ lại từ handler, usecase, broker, và consumer thực tế trong code hiện tại.

## Suggested Closing

- Điểm đáng chú ý nhất là SMAP không đi theo một pipeline đồng bộ từ đầu đến cuối.
- Hệ thống chia nhỏ trạng thái và trách nhiệm theo từng service nên dễ scale hơn, nhưng cũng đòi hỏi control flow rõ ràng giữa database, broker, object storage, và websocket delivery.
