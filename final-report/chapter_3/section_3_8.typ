== 3.8 Cơ sở kỹ thuật AI, NLP và khai thác tri thức

Trong các hệ thống social listening, trí tuệ nhân tạo và xử lý ngôn ngữ tự nhiên được sử dụng nhằm hỗ trợ chuyển đổi dữ liệu văn bản phi cấu trúc thành các tín hiệu có thể phân tích được. Dữ liệu mạng xã hội thường có đặc điểm ngắn, nhiễu, không chuẩn hóa, nhiều biểu tượng cảm xúc, từ viết tắt, tiếng lóng và phụ thuộc mạnh vào bối cảnh. Vì vậy, việc phân tích loại dữ liệu này cần kết hợp nhiều kỹ thuật khác nhau như tiền xử lý văn bản, trích xuất từ khóa, phân tích cảm xúc, biểu diễn ngữ nghĩa bằng embedding, tìm kiếm vector và sinh ngôn ngữ có kiểm soát.

Trong phạm vi cơ sở kỹ thuật, phần này tập trung vào các khái niệm và công nghệ nền tảng giúp hiểu vì sao các kỹ thuật AI/NLP phù hợp với bài toán phân tích dữ liệu mạng xã hội. Các kỹ thuật này đóng vai trò hỗ trợ tổng hợp và khai thác thông tin; kết quả của chúng cần được diễn giải trong mối quan hệ với chất lượng dữ liệu đầu vào, phạm vi mô hình và ngữ cảnh nghiệp vụ.

=== 3.8.1 Xử lý ngôn ngữ tự nhiên trong social listening

Xử lý ngôn ngữ tự nhiên, hay Natural Language Processing, là lĩnh vực nghiên cứu và ứng dụng các phương pháp tính toán để máy tính có thể xử lý, phân tích và tạo ra ngôn ngữ của con người. Trong social listening, NLP thường được dùng để làm sạch văn bản, chuẩn hóa nội dung, phát hiện chủ đề, trích xuất từ khóa, nhận diện thực thể, phân tích cảm xúc và hỗ trợ tổng hợp thông tin.

Khác với văn bản báo chí hoặc tài liệu chính thức, nội dung mạng xã hội thường thiếu cấu trúc và có độ biến thiên cao. Một ý kiến có thể được thể hiện bằng câu ngắn, từ lóng, biểu tượng cảm xúc, lỗi chính tả hoặc cách viết pha trộn giữa nhiều ngôn ngữ. Do đó, pipeline NLP cho social listening thường không chỉ dựa vào một mô hình duy nhất, mà kết hợp nhiều bước xử lý nối tiếp. Mỗi bước tạo thêm một lớp tín hiệu để các bước sau có thể phân tích chính xác và có ngữ cảnh hơn.

Một pipeline NLP điển hình có thể bao gồm tiền xử lý văn bản, phân loại nội dung, trích xuất từ khóa hoặc thực thể, phân tích cảm xúc tổng thể, phân tích cảm xúc theo khía cạnh và tổng hợp các chỉ số hỗ trợ đánh giá. Cách tổ chức theo pipeline giúp bài toán phức tạp được chia thành nhiều bài toán nhỏ hơn, đồng thời giúp kết quả trung gian có thể kiểm tra và giải thích được.

=== 3.8.2 Tiền xử lý văn bản tiếng Việt

Tiền xử lý văn bản là bước chuẩn bị dữ liệu trước khi đưa vào các thuật toán hoặc mô hình NLP. Các thao tác thường gặp gồm chuẩn hóa chữ hoa chữ thường, loại bỏ ký tự không cần thiết, xử lý URL, biểu tượng cảm xúc, khoảng trắng, dấu câu, từ lặp, hashtag và các phần nhiễu khác. Với dữ liệu mạng xã hội, bước này đặc biệt quan trọng vì dữ liệu đầu vào thường không tuân theo chuẩn chính tả hoặc cấu trúc câu đầy đủ.

Đối với tiếng Việt, tiền xử lý còn có thêm thách thức về tách từ. Tiếng Việt là ngôn ngữ đơn lập, trong đó một từ có thể gồm nhiều âm tiết được viết cách nhau bằng khoảng trắng. Ví dụ, “chất lượng” là một đơn vị từ vựng nhưng gồm hai tiếng. Nếu không tách từ phù hợp, mô hình hoặc thuật toán phía sau có thể hiểu sai ranh giới từ, làm giảm chất lượng phân tích. Vì vậy, các công cụ tách từ tiếng Việt như PyVi thường được sử dụng như một bước chuẩn bị cho các mô hình ngôn ngữ tiếng Việt.

Tiền xử lý không làm cho dữ liệu trở nên đúng tuyệt đối, nhưng giúp giảm nhiễu và làm cho dữ liệu nhất quán hơn. Đây là điều kiện quan trọng để các bước như trích xuất từ khóa, phân tích cảm xúc và tạo embedding hoạt động ổn định hơn.

=== 3.8.3 Phân tích cảm xúc và mô hình ngôn ngữ tiếng Việt

Phân tích cảm xúc, hay sentiment analysis, là bài toán xác định thái độ hoặc sắc thái cảm xúc trong văn bản. Trong social listening, phân tích cảm xúc thường được dùng để nhận diện nội dung tích cực, tiêu cực hoặc trung tính, từ đó hỗ trợ đánh giá phản ứng của cộng đồng đối với thương hiệu, sản phẩm, sự kiện hoặc chiến dịch truyền thông.

Với tiếng Việt, các mô hình ngôn ngữ tiền huấn luyện như PhoBERT có ý nghĩa quan trọng vì chúng được xây dựng để biểu diễn tốt hơn đặc trưng của tiếng Việt. PhoBERT thuộc nhóm mô hình dựa trên kiến trúc Transformer, có khả năng học biểu diễn ngữ cảnh của từ trong câu. Nhờ đó, mô hình có thể phân biệt một từ hoặc cụm từ trong các ngữ cảnh khác nhau, thay vì chỉ dựa trên khớp từ đơn giản.

Trong bài toán phân loại cảm xúc, văn bản đầu vào thường được token hóa, đưa qua mô hình ngôn ngữ, sau đó ánh xạ sang các nhãn cảm xúc. Đầu ra có thể bao gồm nhãn dự đoán và độ tin cậy. Tuy nhiên, độ tin cậy này chỉ phản ánh mức chắc chắn của mô hình trên đầu vào cụ thể, không phải bảo đảm tuyệt đối về tính đúng sai của kết quả trong thực tế.

Ngoài phân tích cảm xúc tổng thể, một hướng mở rộng quan trọng là phân tích cảm xúc theo khía cạnh, hay Aspect-Based Sentiment Analysis. Thay vì chỉ kết luận toàn bộ bài viết là tích cực hoặc tiêu cực, ABSA cố gắng xác định cảm xúc đối với từng khía cạnh cụ thể, chẳng hạn giá cả, chất lượng, dịch vụ, giao hàng hoặc hỗ trợ khách hàng. Cách tiếp cận này phù hợp với social listening vì một nội dung có thể khen một khía cạnh nhưng chê một khía cạnh khác.

=== 3.8.4 Trích xuất từ khóa, thực thể và khía cạnh

Trích xuất từ khóa là quá trình xác định các từ hoặc cụm từ có khả năng đại diện cho nội dung chính của văn bản. Trong dữ liệu mạng xã hội, từ khóa giúp nhận diện chủ đề đang được thảo luận, các vấn đề nổi bật và những cụm từ lặp lại trong phản hồi của người dùng. Các phương pháp trích xuất từ khóa có thể dựa trên thống kê, luật, từ điển hoặc mô hình học máy.

YAKE là một phương pháp trích xuất từ khóa không giám sát, dựa trên các đặc trưng thống kê trong chính văn bản đầu vào. Điểm mạnh của cách tiếp cận này là không cần tập dữ liệu huấn luyện riêng và có thể áp dụng linh hoạt cho nhiều miền dữ liệu. Tuy nhiên, vì dựa nhiều vào đặc trưng bề mặt của văn bản, kết quả có thể bị ảnh hưởng bởi dữ liệu quá ngắn, nhiễu hoặc thiếu ngữ cảnh.

spaCy là một thư viện NLP cung cấp nhiều khả năng xử lý ngôn ngữ như tokenization, part-of-speech tagging, dependency parsing và named entity recognition tùy theo model ngôn ngữ được sử dụng. Trong bài toán phân tích nội dung, named entity recognition giúp phát hiện tên người, tổ chức, địa điểm, sản phẩm hoặc các thực thể có ý nghĩa. Khi kết hợp với từ điển nghiệp vụ, kết quả từ khóa và thực thể có thể được ánh xạ về các khía cạnh phân tích ổn định hơn.

Khía cạnh, hay aspect, là nhóm ý nghĩa dùng để gom các từ khóa và phản hồi liên quan đến cùng một chủ đề phân tích. Việc ánh xạ từ khóa về aspect giúp kết quả phân tích có cấu trúc hơn, hỗ trợ thống kê, lọc, so sánh và tổng hợp báo cáo. Trong thực tế, aspect extraction thường cần kết hợp giữa mô hình tự động và tri thức miền, vì cùng một từ có thể mang ý nghĩa khác nhau trong các ngữ cảnh khác nhau.

=== 3.8.5 Chỉ số ảnh hưởng, rủi ro và khả năng giải thích

Trong social listening, không phải nội dung nào cũng có mức độ quan trọng như nhau. Một phản hồi tiêu cực từ tài khoản ít tương tác có thể có tác động khác với một phản hồi tiêu cực đang được chia sẻ rộng rãi. Vì vậy, ngoài phân tích nội dung, hệ thống phân tích mạng xã hội thường cần các chỉ số bổ sung để ước lượng mức độ ảnh hưởng và rủi ro.

Các chỉ số ảnh hưởng có thể dựa trên lượng tương tác như lượt thích, bình luận, chia sẻ, lượt xem, quy mô người theo dõi hoặc mức độ lan truyền. Các chỉ số rủi ro có thể kết hợp tín hiệu cảm xúc tiêu cực, từ khóa nhạy cảm, tốc độ lan truyền và mức độ liên quan đến đối tượng theo dõi. Những chỉ số này không nhất thiết là mô hình AI thuần túy; chúng có thể là sự kết hợp giữa kết quả NLP, luật nghiệp vụ và công thức tính điểm.

Một yêu cầu quan trọng của các chỉ số này là tính giải thích được. Nếu hệ thống chỉ đưa ra một điểm số mà không cho biết yếu tố nào đóng góp vào điểm số đó, người dùng khó đánh giá mức độ tin cậy hoặc hành động phù hợp. Vì vậy, trong các hệ thống phân tích, việc lưu lại các yếu tố như sentiment, keyword, mức tương tác, nền tảng và lý do đánh giá rủi ro giúp kết quả dễ kiểm tra hơn.

=== 3.8.6 Embedding, vector search và cơ sở dữ liệu vector

Embedding là kỹ thuật biểu diễn văn bản dưới dạng vector số học trong không gian nhiều chiều. Ý tưởng chính là các văn bản có ý nghĩa gần nhau sẽ có vector gần nhau hơn so với các văn bản ít liên quan. Nhờ đó, hệ thống có thể thực hiện tìm kiếm ngữ nghĩa, tức tìm nội dung gần nghĩa với câu truy vấn, thay vì chỉ tìm các văn bản khớp chính xác từ khóa.

Tìm kiếm vector thường sử dụng các độ đo khoảng cách hoặc độ tương đồng như cosine similarity, dot product hoặc Euclidean distance. Trong các hệ thống có số lượng văn bản lớn, việc tìm kiếm tuyến tính qua toàn bộ vector là không hiệu quả, vì vậy các cơ sở dữ liệu vector được sử dụng để lưu trữ, lập chỉ mục và truy vấn embedding. Qdrant là một ví dụ của vector database, hỗ trợ lưu vector kèm payload metadata và truy vấn kết hợp giữa similarity search với các điều kiện lọc.

Trong bối cảnh social listening, vector search hữu ích khi người dùng muốn tìm các phản hồi có cùng ý nghĩa nhưng không dùng cùng từ khóa. Ví dụ, các câu diễn đạt sự không hài lòng có thể khác nhau về từ ngữ nhưng gần nhau về sắc thái. Khi kết hợp embedding với metadata như thời gian, nền tảng, sentiment hoặc aspect, hệ thống có thể hỗ trợ các truy vấn vừa theo ngữ nghĩa vừa theo điều kiện nghiệp vụ.

=== 3.8.7 Retrieval-Augmented Generation và mô hình ngôn ngữ lớn

Mô hình ngôn ngữ lớn, hay Large Language Model, có khả năng sinh văn bản, tóm tắt, trả lời câu hỏi và diễn giải thông tin bằng ngôn ngữ tự nhiên. Tuy nhiên, nếu chỉ dựa vào tri thức nội tại của mô hình, câu trả lời có thể không phản ánh đúng dữ liệu cụ thể của hệ thống. Đây là lý do Retrieval-Augmented Generation được sử dụng trong nhiều ứng dụng hỏi đáp và tổng hợp tri thức.

Retrieval-Augmented Generation kết hợp hai bước: truy hồi tài liệu liên quan và sinh câu trả lời dựa trên tài liệu đã truy hồi. Ở bước đầu, hệ thống tìm các đoạn dữ liệu phù hợp với câu hỏi bằng tìm kiếm từ khóa, tìm kiếm vector hoặc kết hợp cả hai. Ở bước sau, các tài liệu liên quan được đưa vào prompt như context để LLM tạo câu trả lời. Cách này giúp câu trả lời bám sát dữ liệu hơn và có thể kèm trích dẫn nguồn.

RAG không loại bỏ hoàn toàn rủi ro sinh sai thông tin. Nếu tài liệu truy hồi không liên quan, thiếu dữ liệu hoặc chứa thông tin sai, câu trả lời vẫn có thể bị ảnh hưởng. Vì vậy, các hệ thống RAG thường cần cơ chế giới hạn context, đánh giá độ liên quan, yêu cầu trích dẫn, từ chối trả lời khi không đủ dữ liệu và phân biệt rõ giữa dữ liệu quan sát được với nhận định suy luận.

LLM cũng có thể được sử dụng để hỗ trợ sinh báo cáo. Trong trường hợp này, mô hình không chỉ trả lời một câu hỏi ngắn mà tổng hợp nhiều kết quả phân tích thành các phần nội dung có cấu trúc. Để hạn chế rủi ro vượt quá giới hạn context hoặc tạo báo cáo quá chung chung, dữ liệu đầu vào thường được tổng hợp, chọn mẫu và chia thành từng phần trước khi sinh nội dung.

=== 3.8.8 Giới hạn của AI trong phân tích dữ liệu mạng xã hội

Các kỹ thuật AI/NLP phụ thuộc mạnh vào chất lượng dữ liệu đầu vào. Nếu dữ liệu bị thiếu, nhiễu, sai ngữ cảnh, không đại diện hoặc chứa nội dung mơ hồ, kết quả phân tích cũng có thể sai lệch. Nguyên tắc này thường được gọi là "garbage in, garbage out": đầu vào kém chất lượng sẽ dẫn đến đầu ra kém chất lượng, dù mô hình hoặc thuật toán phía sau có phức tạp đến đâu.

Ngoài chất lượng dữ liệu, các giới hạn khác còn đến từ phạm vi ngôn ngữ, miền dữ liệu, tập huấn luyện của mô hình, độ dài văn bản, khả năng hiểu ngữ cảnh xã hội và sự thay đổi liên tục của ngôn ngữ mạng. Một mô hình hoạt động tốt trên miền dữ liệu này chưa chắc giữ nguyên chất lượng khi chuyển sang miền khác. Các từ lóng, meme, mỉa mai, châm biếm hoặc nội dung đa nghĩa cũng là những trường hợp khó đối với hệ thống tự động.

Vì vậy, AI trong social listening nên được xem là công cụ hỗ trợ phân tích, không phải nguồn kết luận tuyệt đối. Giá trị chính của các kỹ thuật này nằm ở khả năng xử lý lượng lớn dữ liệu, phát hiện tín hiệu đáng chú ý, hỗ trợ tìm kiếm và tổng hợp thông tin. Đối với các quyết định quan trọng, kết quả tự động cần được đặt trong quy trình đánh giá có kiểm chứng và có thể cần sự xem xét của con người.
