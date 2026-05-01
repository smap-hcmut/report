#import "../counters.typ": image_counter, table_counter

=== 5.5.3 UC-03: Tra cứu và hỏi đáp dữ liệu phân tích

Trong bộ use case hiện tại ở Chương 4, UC-03 được hiểu là mục tiêu khai thác dữ liệu phân tích đã sẵn sàng thông qua tra cứu hoặc hỏi đáp theo ngữ cảnh chiến dịch. Ở mức sequence, mục tiêu này được cụ thể hóa qua hai interaction flows chính: truy hồi dữ liệu theo truy vấn có ngữ cảnh và hỏi đáp có dẫn chứng trên nền retrieval.

Điểm chung của các flow trong mục này là giao diện không truy cập trực tiếp vector store hay dữ liệu phân tích gốc. Mọi truy vấn đều đi qua Knowledge Service để kiểm tra phạm vi, truy hồi ngữ cảnh và tổng hợp kết quả trước khi trả về cho người dùng.

==== 5.5.3.1 Tra cứu theo ngữ cảnh chiến dịch

Luồng này mô tả cách người dùng gửi truy vấn tìm kiếm trong phạm vi một campaign hoặc project và nhận về danh sách kết quả phù hợp.

#align(center)[
  #image("../images/chapter_5/seq-uc03-search-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 1: Tra cứu theo ngữ cảnh chiến dịch_])
#image_counter.step()

Luồng xử lý:

- User mở giao diện tra cứu và nhập truy vấn cùng các bộ lọc cần thiết.

- Giao diện gửi request search đến Knowledge Service kèm campaign, nội dung truy vấn và phạm vi lọc.

- Knowledge Service kiểm tra tính hợp lệ của truy vấn và tìm kết quả cache nếu phù hợp.

- Nếu cần, service resolve campaign sang tập project liên quan, sinh biểu diễn truy vấn và thực hiện truy hồi trên các collection tri thức tương ứng.

- Hệ thống lọc, sắp xếp, loại bỏ các kết quả lặp và tổng hợp metadata cần hiển thị.

- Kết quả tra cứu được trả về cho giao diện để người dùng xem nội dung liên quan, điểm phù hợp và các thông tin bổ trợ.

Điểm quan trọng: Flow này tập trung vào retrieval có ngữ cảnh. Dữ liệu phân tích chỉ được khai thác thông qua lớp tri thức đã được chuẩn bị từ trước, không truy vấn ad-hoc trực tiếp từ các lane xử lý nền.

==== 5.5.3.2 Hỏi đáp có dẫn chứng và lưu hội thoại

Luồng này mô tả cách người dùng gửi câu hỏi trong trợ lý dữ liệu và nhận câu trả lời có dẫn chứng trong cùng ngữ cảnh chiến dịch.

#align(center)[
  #image("../images/chapter_5/seq-uc03-chat-rag-flow.svg", width: 96%)
]
#context (align(center)[_Hình #image_counter.display(): Sequence Diagram UC-03 Part 2: Hỏi đáp có dẫn chứng và lưu hội thoại_])
#image_counter.step()

Luồng xử lý:

- User gửi câu hỏi mới hoặc tiếp tục một hội thoại đã có trong giao diện trợ lý dữ liệu.

- Giao diện gửi request chat đến Knowledge Service, kèm campaign và conversation_id nếu đang tiếp tục hội thoại.

- Knowledge Service kiểm tra input, nạp hoặc tạo conversation phù hợp và lấy lịch sử trao đổi cần thiết.

- Service thực hiện truy hồi ngữ cảnh liên quan cho câu hỏi hiện tại, sau đó kết hợp context với lịch sử hội thoại để xây prompt.

- Hệ thống gọi mô hình sinh câu trả lời dựa trên prompt đã được grounding bởi kết quả truy hồi.

- Sau khi có câu trả lời, service trích citations, sinh gợi ý tiếp theo và lưu message của user cùng message phản hồi vào persistence layer.

- Giao diện nhận câu trả lời, citations và suggestions để người dùng tiếp tục khai thác dữ liệu phân tích trong cùng ngữ cảnh.

Điểm quan trọng: Flow này không xem mô hình sinh là nguồn dữ liệu chính. Câu trả lời chỉ có giá trị khi được neo vào kết quả truy hồi và được trả lại cùng phần dẫn chứng liên quan.
