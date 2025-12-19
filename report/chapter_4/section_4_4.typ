// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 4.4 Danh sách Use Case
#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()
#text()[
  #set par(justify: false)
  #table(
    columns: (auto, 1fr, auto, auto, 1fr),
    stroke: 0.5pt,
    [*ID*], [*Tên*], [*Primary Actor*], [*Secondary Actor*], [*Goal*],
    [UC-01], [Cấu hình Project theo dõi], [Brand Manager], [-], [Tạo config Project dạng Draft],
    [UC-02], [Kiểm tra từ khóa (Dry-run)], [Brand Manager], [Social Media Platforms], [Thử từ khóa trước khi lưu],
    [UC-03], [Khởi chạy và theo dõi Project], [Brand Manager], [Social Media Platforms], [Run-to-completion một Project],
    [UC-04], [Xem kết quả phân tích và so sánh], [Brand Manager], [-], [Xem dashboard kết quả (full/partial)],
    [UC-05], [Quản lý danh sách Projects], [Brand Manager], [-], [Xem/lọc/tìm/chỉnh sửa Draft],
    [UC-06], [Xuất báo cáo], [Brand Manager], [-], [Sinh và tải báo cáo],
    [UC-07], [Phát hiện trend tự động], [Brand Manager], [Social Media Platforms], [Thu thập & xếp hạng trend theo lịch],
  )
]
