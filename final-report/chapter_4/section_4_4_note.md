# Note - Section 4.4

## Khác gì so với bản cũ

- Bản cũ viết bộ Use Case rất dài và rất chi tiết theo product flow cũ, bám mạnh vào wizard, dashboard, export, trend và crisis monitor theo narrative trước đây.
- Nhiều use case cũ mô tả sâu ở mức UI, timeout, schedule, chart layout, storage behavior và các ràng buộc chi tiết khó trace trực tiếp với current implementation.
- Actor trong use case vẫn giữ `Marketing Analyst` và các flow cũ, không còn khớp với actor model mới ở mục 4.1 và bộ FR mới ở mục 4.2.

## Bản hiện tại đã chỉnh gì

- Đã chỉnh phần mở đầu `4.4` để use case được viết theo góc nhìn người dùng/tác nhân vận hành, không theo cấu trúc mã nguồn.
- Đã chỉnh bảng tổng quan use case để bổ sung mapping UC ↔ FR.
- Đã đổi tên use case trong bảng tổng quan sang tiếng Việt rõ nghĩa hơn.
- Đã bỏ định hướng đưa route/file path vào phần tổng quan report chính.
- Đã rewrite `UC-01` theo đúng khung bảng use case cũ của report tháng 12: toàn bộ nội dung nằm trong một bảng với các mục `Use Case name`, `Actors`, `Description`, `Trigger`, `Preconditions`, `Postconditions`, `Normal Flows`, `Alternative Flows`, `Exceptions`, `Notes and issues`.
- Đã xóa phần `Minh họa hiện thực` khỏi `UC-01` trong report chính.
- Đã bỏ cách viết luồng ở ngoài bảng đối với `UC-01`.
- Đã giữ lại numbering heading theo dạng `4.4.x UC-0x`.
- Đã rewrite `UC-02` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Đã rewrite `UC-03` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-03` đã được chỉnh để phản ánh implementation hiện tại: dry run bất đồng bộ, có `latest/history`, target chỉ thực sự readiness khi có evidence phù hợp, và một số tổ hợp `source-target` có thể không bắt buộc dry run.
- Đã rewrite `UC-04` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-04` đã được chỉnh để phản ánh implementation hiện tại: activation readiness đi qua `project-srv` sang `ingest-srv`; `activate` và `resume` đều bị chặn khi readiness không đạt; `pause` điều phối dừng runtime liên quan; `archive` pause trước nếu project đang active; `unarchive` chỉ đưa project về `PAUSED` chứ không chạy lại ngay.
- Đã rewrite `UC-05` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-05` đã được chỉnh để phản ánh implementation hiện tại: `analysis-srv` consume message, chạy pipeline và publish downstream; `knowledge-srv` consume batch/insight/digest message để index vào metadata store và Qdrant; flow là bất đồng bộ và có thể thành công một phần.
- Đã rewrite `UC-06` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-06` đã được chỉnh để phản ánh implementation hiện tại: search và chat dùng chung search foundation qua campaign → project collections; chat là synchronous RAG entrypoint, có conversation history, citations, suggestions và persisted messages.
- Đã rewrite `UC-07` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-07` đã được chỉnh để phản ánh implementation hiện tại ở mức delivery capability: `notification-srv` nhận event qua Redis Pub/Sub, transform contract message, route qua WebSocket hub hoặc side-channel; tránh overclaim rằng frontend hiện đã consume đầy đủ realtime path.
- Đã rewrite `UC-08` theo cùng khung bảng use case cũ và xóa phần `Minh họa hiện thực` khỏi report chính.
- Nội dung `UC-08` đã được chỉnh để phản ánh implementation hiện tại: đây là CRUD cấu hình crisis gắn `project_id`, có validation theo nhóm trigger `keywords/volume/sentiment/influencer`, và config chỉ làm đầu vào cho detection/alert downstream chứ không tự thực thi detection trong use case này.

## Cần chỉnh tiếp

- Đã hoàn tất rewrite `4.4.1` đến `4.4.8` theo đúng khung bảng use case cũ, cập nhật nội dung theo current implementation.
- Xóa toàn bộ phần `Minh họa hiện thực` chứa path source khỏi report chính; nếu cần giữ trace, chuyển vào note hoặc appendix kỹ thuật.
- Sửa `UC-07` để không overclaim frontend WebSocket client; chỉ mô tả notification delivery capability ở mức hệ thống.
- Kiểm tra `UC-05` vì đây là system-supporting use case, cần phân loại rõ với user-goal use cases.
- Kiểm tra `UC-02`, `UC-03`, `UC-04` để tách rõ precondition, alternative flow và invalid state handling.
