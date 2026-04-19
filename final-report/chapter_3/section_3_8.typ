== 3.8 Công nghệ Frontend

=== 3.8.1 Next.js

Next.js là một React framework được phát triển bởi Vercel, cung cấp nhiều tính năng để xây dựng các ứng dụng web sẵn sàng sản xuất. Next.js hỗ trợ Server-Side Rendering, Static Site Generation, và Client-Side Rendering, cho phép chọn chiến lược render phù hợp cho từng trang. Next.js đã trở thành một trong những React framework phổ biến nhất cho các ứng dụng doanh nghiệp.

Server-Side Rendering cho phép render các React component trên server và gửi HTML đến client. Điều này cải thiện thời gian tải trang ban đầu và SEO vì các công cụ tìm kiếm có thể lập chỉ mục nội dung. SSR đặc biệt quan trọng cho các trang có nhiều nội dung và ứng dụng cần SEO tốt.

Next.js hỗ trợ định tuyến dựa trên hệ thống file và có thể được tổ chức theo nhiều chiến lược khác nhau tùy theo giai đoạn phát triển của dự án. Trong current frontend workspace của SMAP, có thể quan sát thấy cả các route theo `pages/` lẫn các route theo `src/app/`, cho thấy frontend đang tồn tại ở trạng thái chuyển tiếp hoặc kết hợp nhiều cách tổ chức routing. Điều này phản ánh tính linh hoạt của Next.js trong việc hỗ trợ mở rộng và tái cấu trúc dần frontend theo nhu cầu thực tế.

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

Tùy chỉnh thông qua file cấu hình cho phép định nghĩa màu sắc, khoảng cách, phông chữ, và breakpoint tùy chỉnh. Tailwind có thể được điều chỉnh cho hệ thống thiết kế của dự án, đồng thời hỗ trợ tốt cho việc xây dựng các giao diện có nhiều biến thể thành phần.

=== 3.8.5 Electron và khả năng đóng gói desktop

Electron là một nền tảng cho phép xây dựng ứng dụng desktop đa nền tảng bằng công nghệ web như HTML, CSS và JavaScript. Electron kết hợp Chromium để hiển thị giao diện và Node.js để cung cấp khả năng truy cập hệ thống ở phía desktop runtime. Nhờ đó, cùng một codebase frontend có thể được sử dụng để phát hành ứng dụng desktop bên cạnh phiên bản web.

Trong current implementation của SMAP, frontend không chỉ dừng ở web application thuần túy mà còn có dấu hiệu đóng gói desktop thông qua Electron. Điều này đặc biệt hữu ích khi hệ thống cần một hình thức triển khai thuận tiện cho người dùng cuối, đồng thời vẫn tận dụng được toàn bộ stack giao diện dựa trên Next.js, React và TypeScript.

=== 3.8.6 Tích hợp BI và Metabase

Trong các hệ thống phân tích dữ liệu, lớp giao diện không chỉ đảm nhiệm hiển thị trang nghiệp vụ mà còn thường tích hợp các công cụ BI hoặc dashboard chuyên dụng để hỗ trợ truy vấn và trực quan hóa. Một hướng tiếp cận phổ biến là frontend cung cấp lớp tích hợp trung gian để truy xuất dữ liệu từ công cụ BI và đưa kết quả vào trải nghiệm sử dụng chung của hệ thống.

Đối với SMAP, current frontend source cho thấy có tích hợp với Metabase thông qua các hook và API route riêng. Điều này cho thấy frontend không chỉ đóng vai trò giao diện thao tác, mà còn là nơi kết nối giữa trải nghiệm người dùng với các lớp báo cáo và khai thác dữ liệu có cấu trúc hơn.

Những công nghệ trên là cơ sở để hình thành frontend hiện tại của SMAP: một lớp giao diện dựa trên Next.js, React, TypeScript và Tailwind CSS, có hỗ trợ i18n, có khả năng tích hợp BI, và có hướng triển khai trên cả web lẫn desktop thông qua Electron.
