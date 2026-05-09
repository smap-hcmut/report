# Note - Section 5.3.8

## Khác gì so với bản cũ

- Bản cũ của mục `5.3` chưa có section riêng cho `scrapper-srv`, dù đây là một phần quan trọng của execution plane đã được chốt ở kiến trúc tổng thể.
- Vì thiếu mục riêng này, narrative của crawl runtime dễ bị dồn hết vào `ingest-srv`, làm mờ ranh giới giữa orchestration và actual crawl execution.

## Bản hiện tại đã chỉnh gì

- Bổ sung mục riêng cho `Scrapper Worker Service` theo current source của `scrapper-srv`.
- Mô tả service như một hybrid runtime gồm FastAPI surface mỏng và RabbitMQ worker lane.
- Nhấn mạnh production handoff hiện tại: raw artifact storage + completion envelope, thay vì coi `output/*.json` là contract chính.

## Ghi chú tạm thời

- Đã bổ sung một SVG current-state cho flow `ingest -> queue -> scrapper -> storage -> completion`.
- Source của hình này hiện được giữ ở dạng PlantUML `.puml` và render ra `.svg` để nhúng vào report.
- Biến thể dryrun completion flow hiện vẫn chưa có diagram riêng.
- README của `scrapper-srv` còn chứa một số status snapshot không hoàn toàn khớp source hiện tại, nên section này được bám chủ yếu vào code runtime và contract `RABBITMQ.md`.
