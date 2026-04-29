# Note - Section 5.3.8

## Khác gì so với bản cũ

- Bản cũ của mục `5.3` chưa có section riêng cho `scapper-srv`, dù đây là một phần quan trọng của execution plane đã được chốt ở kiến trúc tổng thể.
- Vì thiếu mục riêng này, narrative của crawl runtime dễ bị dồn hết vào `ingest-srv`, làm mờ ranh giới giữa orchestration và actual crawl execution.

## Bản hiện tại đã chỉnh gì

- Bổ sung mục riêng cho `Scapper Worker Service` theo current source của `scapper-srv`.
- Mô tả service như một hybrid runtime gồm FastAPI surface mỏng và RabbitMQ worker lane.
- Nhấn mạnh production handoff hiện tại: raw artifact storage + completion envelope, thay vì coi `output/*.json` là contract chính.

## Ghi chú tạm thời

- Mục này hiện chưa có diagram current-state riêng.
- Nếu bổ sung sau, nên ưu tiên flow `ingest -> queue -> scapper -> storage -> completion` và một biến thể dryrun completion flow.
- README của `scapper-srv` còn chứa một số status snapshot không hoàn toàn khớp source hiện tại, nên section này được bám chủ yếu vào code runtime và contract `RABBITMQ.md`.
