#import "../counters.typ": image_counter, table_counter

== 5.3 Thiết kế chi tiết các dịch vụ

Mục 5.2 đã trình bày kiến trúc tổng thể của hệ thống SMAP ở cấp độ container và ranh giới trách nhiệm giữa các service. Mục này đi sâu hơn vào các thành phần cốt lõi ở mức thiết kế chi tiết, nhằm làm rõ cách các capability quan trọng của hệ thống được hiện thực bên trong từng service hoặc runtime lane tương ứng.

Mục đích của mục này là:

- Làm rõ cấu trúc nội bộ của từng service: Các components, layers, và cách tổ chức code theo Clean Architecture.

- Mô tả trách nhiệm của từng component: Input, output, và technology category.

- Giải thích các design patterns được áp dụng: Lý do chọn pattern và lợi ích mang lại.

- Cung cấp traceability đến requirements: Liên kết với NFRs và Acceptance Criteria ở Chapter 4.

Mục này được tổ chức theo các capability và runtime lane quan trọng của hệ thống. Các phần ưu tiên trước hết là xác thực và session management, business context persistence, lifecycle control, analytics pipeline, knowledge retrieval và realtime delivery.

#import "section_5_3_1.typ" as section_5_3_1
#section_5_3_1

#import "section_5_3_2.typ" as section_5_3_2
#section_5_3_2

#import "section_5_3_3.typ" as section_5_3_3
#section_5_3_3

#import "section_5_3_4.typ" as section_5_3_4
#section_5_3_4

#import "section_5_3_5.typ" as section_5_3_5
#section_5_3_5

#import "section_5_3_6.typ" as section_5_3_6
#section_5_3_6

#import "section_5_3_7.typ" as section_5_3_7
#section_5_3_7
