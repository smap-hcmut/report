# SMAP Architecture Report

Updated: 2026-04-14

## 1. Mục đích

Thư mục này là bộ báo cáo kiến trúc kỹ thuật của workspace SMAP. Tài liệu này dùng shell Typst trong `../../final-report/` làm chuẩn trình bày, nhưng toàn bộ kết luận kiến trúc được viết lại theo `current-state` của repo hiện tại.

Report này không phải bản sao của luận văn cũ. Mục tiêu của nó là:

- mô tả lại kiến trúc hệ thống đang tồn tại trong workspace
- tách bạch giữa `current`, `target`, và `legacy`
- cung cấp narrative đủ sâu để phục vụ engineering, architecture review, và onboarding
- thay bộ sơ đồ cũ bằng bộ hình sạch hơn, dùng được trực tiếp trong Markdown

## 2. Quy ước đọc

- `current`: có evidence rõ từ README, contract docs, gap notes, hoặc source-linked docs hiện tại
- `target`: kiến trúc mong muốn hoặc contract mục tiêu đã được mô tả nhưng chưa nên coi là fully implemented
- `legacy`: mô tả cũ, contract cũ, hoặc naming cũ không còn phản ánh runtime chính

## 3. Cấu trúc tài liệu

- `chapter_1_overview.md`: giới thiệu đề tài, phạm vi, phương pháp xây dựng report
- `chapter_2_related_context.md`: bối cảnh sản phẩm, stakeholders, external systems, workspace reality
- `chapter_3_theoretical_foundation.md`: nền tảng lý thuyết dùng trong thiết kế và mô tả kiến trúc
- `chapter_4_system_analysis.md`: phân tích current-state của hệ thống SMAP
- `chapter_5_system_design.md`: chương trọng tâm, mô tả kiến trúc, dịch vụ, dữ liệu, giao tiếp, triển khai, traceability
- `chapter_6_conclusion.md`: kết quả, hạn chế, hướng phát triển, kết luận
- `chapter_7_references.md`: tài liệu tham khảo nội bộ và bên ngoài
- `chapter_8_appendix.md`: phụ lục thuật ngữ, từ viết tắt, source matrix, inventory bổ sung

## 4. Bộ hình minh họa

Diagram source và ảnh export nằm ở:

- `diagram-source/`: file nguồn `.excalidraw`
- `images/diagram/`: file `.svg` được nhúng vào report

Thư mục `diagram/` cũ được xem là `legacy` và không còn là nguồn hình chính của report này.

## 5. Thứ tự nên đọc

1. `chapter_1_overview.md`
2. `chapter_4_system_analysis.md`
3. `chapter_5_system_design.md`
4. `chapter_6_conclusion.md`
5. `chapter_8_appendix.md`

## 6. Ghi chú quan trọng

Report cũ trong `../../final-report/` có giá trị rất lớn về mặt khung trình bày, nhưng một phần nội dung transport và execution flow đã lệch so với hệ hiện tại. Tài liệu này chủ động sửa lại những điểm đó, đặc biệt ở các luồng:

- `project-srv -> ingest-srv`: current nghiêng về internal HTTP control plane
- `ingest-srv <-> scapper-srv`: RabbitMQ cho crawl runtime
- `ingest-srv -> analysis-srv -> knowledge-srv`: Kafka cho data plane analytics và knowledge
- `notification-srv`: Redis Pub/Sub cho realtime notification ingress
