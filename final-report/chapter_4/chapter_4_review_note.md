# Note - Chapter 4 Overview

## Tổng quan sau khi chỉnh sửa

Chương 4 hiện đã được kéo lại theo hướng phân tích hệ thống bám current implementation hơn so với bản cũ. Trục nội dung không còn đi theo product specification cũ ở mức wizard, dashboard và feature flow chi tiết, mà đã chuyển sang hướng capability-based, traceable hơn với actor model, functional requirements, non-functional requirements, use case và diagram current-state.

Về cấu trúc, chương vẫn giữ đủ 5 phần chính:

- `4.1` Nhóm người dùng và tác nhân hệ thống
- `4.2` Functional Requirements
- `4.3` Non-Functional Requirements
- `4.4` Use Case
- `4.5` Sơ đồ hoạt động và luồng xử lý chính

Điểm tích cực là các phần này hiện đã khớp nhau tốt hơn về mặt narrative. Actor ở `4.1` đã nối được với FR ở `4.2`, FR ở `4.2` nối được với bộ use case ở `4.4`, còn `4.5` dùng bộ diagram current-state thay cho activity diagrams legacy cũ.

## Khác gì so với bản cũ

1. Bản cũ của Chương 4 mang đậm màu product specification theo narrative cũ.
2. Actor model cũ chỉ xoay quanh `Marketing Analyst` và `Social Media Platforms`, chưa phản ánh đủ nhóm người dùng nội bộ hay các tác nhân kỹ thuật hiện có.
3. Functional Requirements cũ gắn mạnh với wizard, dashboard, export, trend và crisis flow ở mức rất chi tiết, khó bám current source.
4. Non-functional Requirements cũ chứa nhiều target số cứng và compliance target khó bảo vệ nếu chưa có artifact benchmark tương ứng.
5. Use Case cũ quá dài, quá sâu ở mức UI flow, timeout, schedule, chart layout và các hành vi product-specific.
6. Sơ đồ của `4.5` dùng bộ activity diagrams legacy, không còn phù hợp với current architecture đã được audit ở bộ diagram mới.

## Bản hiện tại đã chỉnh gì

### 4.1 Nhóm người dùng và tác nhân hệ thống

- Bỏ claim khảo sát người dùng trực tiếp.
- Đổi sang actor model evidence-based.
- Thay `Marketing Analyst` bằng `Nhóm người dùng chuyên môn nội bộ`.
- Bổ sung `Nhà cung cấp định danh` như một actor kỹ thuật bên ngoài.

### 4.2 Functional Requirements

- Viết lại theo capability-based requirements.
- Chuyển từ bộ FR cũ sang bộ `FR-01` đến `FR-12` bám current system capabilities.
- Giảm các mô tả quá sâu ở mức UI behavior.

### 4.3 Non-Functional Requirements

- Giữ khung phân tích nhưng bỏ phần lớn các số cứng khó bảo vệ.
- Đồng bộ NFR với current source-of-truth: Performance, Security, Availability, Scalability, Data Integrity, Modularity, Observability.
- Đổi từ “cam kết benchmark” sang “chỉ báo và định hướng chất lượng”.

### 4.4 Use Case

- Viết lại toàn bộ theo hướng capability-based use case.
- Loại bỏ bộ UC cũ bám wizard/dashboard/export/trend/crisis monitor theo narrative trước đây.
- Rút về bộ use case cốt lõi gắn với current implementation.
- Bổ sung `Minh họa hiện thực` để trace sang route, service và module.

### 4.5 Sơ đồ hoạt động và luồng xử lý chính

- Thay toàn bộ bộ activity diagram legacy bằng current-state diagrams.
- Chuyển trọng tâm từ product flow cũ sang các lane hệ thống hiện tại:
  - tổng quan use case
  - business process chính
  - authentication
  - project lifecycle control
  - dry run
  - analytics đến knowledge
  - search/chat
  - realtime delivery

## Đánh giá tổng quan hiện tại

Ở thời điểm hiện tại, Chương 4 đã nhất quán hơn đáng kể so với Chương 1, Chương 2, Chương 3 và current implementation. Các phần quan trọng đã được kéo về đúng trục phân tích hệ thống thay vì product spec cũ. Đây là thay đổi lớn nhất của chương này.

Điểm mạnh hiện tại của Chương 4 là:

- actor model đã hợp lý hơn;
- requirements đã traceable hơn;
- use cases đã bớt speculative hơn;
- diagrams đã bám current-state hơn.

## Các điểm còn cần lưu ý

1. Phần `4.5` hiện đang dùng các file SVG có sẵn trong `report/documents/phong_tmp/new-report/thesis/images/chapter_3` và `chapter_4`, không dùng trực tiếp file `.puml`. Nếu render thêm hình mới, cần cập nhật path hoặc copy asset về thư mục ảnh chính thức của `final-report`.
2. Phần `4.2`, `4.3`, `4.4` hiện đã bám current implementation hơn, nhưng nếu về sau có benchmark hoặc test artifact mới, có thể bổ sung ngược trở lại để tăng độ mạnh cho traceability.
3. Một số tên vẫn dùng tiếng Anh ở mức use case/capability như `Authenticate User`, `Search and Chat Over Knowledge`. Điều này không sai, nhưng nếu cần đồng bộ hoàn toàn văn phong tiếng Việt thì có thể cân nhắc chỉnh ở vòng cuối.

## Kết luận ngắn

Chương 4 đã được chuyển từ một chương phân tích hệ thống theo product specification cũ sang một chương phân tích hệ thống bám current implementation và source-of-truth mới. Ở thời điểm hiện tại, chương này đủ tốt để tiếp tục sang các bước kế tiếp như rà tính nhất quán toàn report, hoàn thiện diagram assets hoặc chuyển trọng tâm sang Chương 5.
