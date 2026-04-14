# SMAP Thesis Workspace

Thư mục này là nhánh làm việc dành riêng cho bản luận văn 7 chương, tách biệt với bộ `report/` kiến trúc tổng hợp.

## Mục tiêu

- viết luận văn theo đúng khung 7 chương đã được cung cấp
- chỉ sử dụng công nghệ và kết luận có bằng chứng từ mã nguồn hoặc manifest thực tế
- giữ văn phong học thuật, nhất quán liên chương
- chuẩn bị nền cho bản luận văn dài, có thể mở rộng dần từng chương

## Các file hiện có

- `00_technology_inventory.md`: danh sách công nghệ xác nhận được từ mã nguồn
- `01_source_evidence_matrix.md`: ma trận bằng chứng mã nguồn cho công nghệ, module và hạ tầng
- `chapter_1_introduction.md`: Chương 1
- `chapter_2_theoretical_background_and_technologies.md`: Chương 2
- `chapter_3_system_analysis.md`: Chương 3
- `chapter_4_system_design.md`: Chương 4
- `chapter_5_implementation.md`: Chương 5
- `chapter_6_evaluation_and_testing.md`: Chương 6
- `chapter_7_conclusion.md`: Chương 7
- `thesis_master.md`: file điều hướng tổng cho toàn bộ luận văn
- `abstract.md`: tóm tắt luận văn
- `acknowledgements.md`: lời cảm ơn
- `abbreviations.md`: danh sách từ viết tắt
- `list_of_figures.md`: danh sách hình minh họa
- `list_of_tables.md`: danh sách bảng biểu
- `references.md`: tài liệu tham khảo cho thesis package
- `appendix_supporting_materials.md`: phụ lục hỗ trợ đóng gói luận văn
- `submission_checklist.md`: checklist rà soát trước khi nộp
- `chapter_outline_3_7.md`: kế hoạch chi tiết cho Chương 3 đến Chương 7

## Trạng thái hiện tại

- Đã hoàn thành bản nháp đầy đủ 7 chương.
- Đã bổ sung hình minh họa cho Chương 3 và Chương 4, bao gồm use case, business process và 6 sequence diagrams.
- Đã mở rộng chiều sâu kỹ thuật cho Chương 4 và Chương 5 bằng decision matrix, module mapping, API grouping và thêm use case hiện thực hóa cho notification layer.
- Đã mở rộng Chương 6 bằng representative test case matrix và requirement-to-test coverage matrix.
- Đã bổ sung file điều hướng tổng, danh sách hình và danh sách bảng cho việc đóng gói luận văn.
- Đã bổ sung thêm traceability matrix và service ownership matrix để tăng độ chặt giữa Chương 3 và Chương 4.
- Đã bổ sung thêm bảng học thuật cho Chương 1 và Chương 2, đồng thời đồng bộ caption hình và danh sách bảng với nội dung thực tế.
- Đã bổ sung front matter và appendix để gói `thesis/` tiến gần hơn tới một bản luận văn hoàn chỉnh có thể dàn trang.
- Đã bổ sung references và submission checklist để phục vụ giai đoạn hoàn thiện bản nộp cuối.
- Đã cập nhật thesis để khớp hơn với implementation mới nhất, bao gồm `scapper-srv` entry point, bằng chứng E2E vận hành và semantics khủng hoảng hiện hành.

## Quy ước

- mọi công nghệ đều phải có file bằng chứng
- khi mô tả tính năng cụ thể, phải chỉ ra file và hàm hiện thực
- chưa có bằng chứng thì không khẳng định như fact
- frontend stack có bằng chứng trực tiếp trong `web-ui/package.json`, nhưng chỉ nên khẳng định đến mức đã được đối chiếu rõ từ source
