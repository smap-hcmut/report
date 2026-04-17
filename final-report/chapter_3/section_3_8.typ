== 3.8 Công nghệ Frontend

=== 3.8.1 Next.js

Next.js là một React framework được phát triển bởi Vercel, cung cấp nhiều tính năng để xây dựng các ứng dụng web sẵn sàng sản xuất. Next.js hỗ trợ Server-Side Rendering, Static Site Generation, và Client-Side Rendering, cho phép chọn chiến lược render phù hợp cho từng trang. Next.js đã trở thành một trong những React framework phổ biến nhất cho các ứng dụng doanh nghiệp.

Server-Side Rendering cho phép render các React component trên server và gửi HTML đến client. Điều này cải thiện thời gian tải trang ban đầu và SEO vì các công cụ tìm kiếm có thể lập chỉ mục nội dung. SSR đặc biệt quan trọng cho các trang có nhiều nội dung và ứng dụng cần SEO tốt.

App Router là hệ thống định tuyến mới trong Next.js 13+, sử dụng định tuyến dựa trên hệ thống file với React Server Components. App Router cho phép bố cục lồng nhau, trạng thái tải, và ranh giới lỗi được định nghĩa một cách khai báo. Server Components giảm kích thước bundle JavaScript bằng cách render component trên server.

API Routes cho phép tạo các endpoint API trong cùng ứng dụng Next.js. Điều này hữu ích cho mẫu backend-for-frontend, nơi frontend cần lớp API để tổng hợp dữ liệu từ nhiều service. API Routes có thể xử lý xác thực, chuyển đổi dữ liệu, và bộ nhớ đệm.

=== 3.8.2 React

React là một thư viện JavaScript để xây dựng giao diện người dùng, được phát triển bởi Facebook. React sử dụng kiến trúc dựa trên component, nơi UI được chia thành các component có thể tái sử dụng. React đã trở thành một trong những thư viện frontend phổ biến nhất với hệ sinh thái rộng lớn.

Kiến trúc dựa trên component cho phép xây dựng UI phức tạp từ các phần nhỏ, độc lập. Mỗi component quản lý trạng thái và render của riêng nó. Các component có thể được kết hợp để tạo UI phức tạp. Điều này tăng khả năng tái sử dụng và bảo trì.

Virtual DOM là một trong những đổi mới của React. Thay vì thao tác DOM trực tiếp, React tạo biểu diễn ảo của DOM trong bộ nhớ. Khi trạng thái thay đổi, React tính toán các thay đổi tối thiểu cần thiết và cập nhật DOM theo lô. Điều này cải thiện hiệu suất đáng kể.

Hook là tính năng được giới thiệu trong React 16.8, cho phép sử dụng trạng thái và tính năng vòng đời trong các functional component. useState cho trạng thái cục bộ, useEffect cho tác dụng phụ, useContext cho tiêu thụ context. Hook làm cho mã ngắn gọn và dễ kiểm thử hơn class component.

=== 3.8.3 TypeScript

TypeScript là một tập cha của JavaScript thêm kiểu tĩnh. TypeScript được phát triển bởi Microsoft và đã trở thành tiêu chuẩn cho các ứng dụng JavaScript quy mô lớn. Mã TypeScript được biên dịch thành JavaScript, có thể chạy trên bất kỳ runtime JavaScript nào.

Kiểu tĩnh là lợi ích chính của TypeScript. Các kiểu được kiểm tra tại thời điểm biên dịch, phát hiện lỗi trước khi mã chạy. Hỗ trợ IDE tốt hơn với tự động hoàn thành, tái cấu trúc, và điều hướng. Tài liệu được nhúng trong mã thông qua các kiểu.

Suy luận kiểu giảm mã boilerplate. TypeScript có thể suy luận kiểu từ ngữ cảnh, không cần chú thích mọi biến. Điều này cân bằng giữa tính an toàn kiểu và năng suất của nhà phát triển.

Interface và Type cho phép định nghĩa hình dạng của các đối tượng. Interface có thể mở rộng và triển khai. Union type và intersection type cho phép biểu đạt các mối quan hệ kiểu phức tạp. Generic cho phép mã có thể tái sử dụng và an toàn kiểu.

=== 3.8.4 Tailwind CSS

Tailwind CSS là một CSS framework utility-first, cung cấp các class tiện ích cấp thấp thay vì các component được thiết kế sẵn. Tailwind cho phép xây dựng thiết kế tùy chỉnh mà không cần viết CSS tùy chỉnh. Tailwind đã trở thành một trong những CSS framework phổ biến nhất cho phát triển web hiện đại.

Phương pháp utility-first có nghĩa là styling được thực hiện bằng cách kết hợp các class tiện ích. Thay vì viết CSS tùy chỉnh cho mỗi component, các nhà phát triển sử dụng các class được định nghĩa sẵn như flex, pt-4, text-center. Điều này tăng tốc độ phát triển và tính nhất quán.

Thiết kế responsive được tích hợp sẵn với các tiền tố responsive. Các class như md:flex chỉ áp dụng trên màn hình trung bình trở lên. Điều này làm cho thiết kế responsive dễ dàng và có thể dự đoán được.

Tùy chỉnh thông qua file cấu hình cho phép định nghĩa màu sắc, khoảng cách, phông chữ, và breakpoint tùy chỉnh. Tailwind có thể được điều chỉnh cho hệ thống thiết kế của dự án. Tích hợp PurgeCSS loại bỏ các style không sử dụng trong bản build sản xuất.
