# Note - Section 5.3.7

## Khác gì so với bản cũ

- Bản cũ của mục `5.3` chưa có một section riêng cho `knowledge-srv`, dù đây là bounded context quan trọng nằm giữa analytics downstream và các capability consumption như search, chat hoặc reports.
- Vì thiếu mục riêng này, các capability knowledge ở Chương 4 và phần frontend consumption dễ bị treo mà không có service ownership rõ ràng trong Chương 5.

## Bản hiện tại đã chỉnh gì

- Bổ sung mục riêng cho `Knowledge Service` theo current implementation của `knowledge-srv`.
- Tổ chức lại narrative quanh hai lane chính: downstream indexing và synchronous knowledge consumption.
- Cover các capability có evidence mạnh trong source hiện tại: indexing, semantic search, chat, report generation và tracking metadata.

## Ghi chú tạm thời

- Mục này hiện chưa gắn diagram current-state riêng.
- Nếu về sau bổ sung hình, nên ưu tiên ba flow: analytics đến knowledge indexing, search/chat flow, và report generation flow.
- Notebook-related narrative chưa được đẩy thành trọng tâm của mục này vì evidence code hiện tại trong workspace mạnh nhất vẫn là các path indexing, search, chat và report.
