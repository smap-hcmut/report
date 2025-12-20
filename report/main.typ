// === main.typ: Entry point tài liệu SMAP ===
#import "config.typ" as cf

// Dòng lệnh này có nghĩa là: "Hãy lấy toàn bộ nội dung file này, 
// đưa vào hàm cf.conf để xử lý (áp dụng font, lề, header...)"
#show: cf.conf

// Import & khởi tạo counter dùng cho bảng và hình ảnh
#import "counters.typ": table_counter, image_counter
#context table_counter.step()
#context image_counter.step()

// CHÚ Ý: Nếu muốn đánh số bảng theo chương, dùng lệnh này ở đầu chương mới:
// #context table_counter.reset()

// ================= PHẦN NỘI DUNG =================

// Mục lục tự động, hiển thị 2 cấp
#include "chapter_0/index.typ"
#set page(numbering: none)
#outline(
  title: [Mục lục],
  depth: 5
)
#pagebreak()

// --- IMPORT Nội dung chính các chương ---


#set page(numbering: "1")
#counter(page).update(1)
#include "chapter_1/index.typ"
#pagebreak()
// Chương 2: Hệ thống liên quan
#include "chapter_2/index.typ"
#pagebreak()
// Chương 3: Phân tích bài toán & yêu cầu
#include "chapter_3/index.typ"
#pagebreak()
// Chương 4: phân tích hệ thống
#include "chapter_4/index.typ"
#pagebreak()
// Chương 5: Thiết kế hệ thống
#include "chapter_5/index.typ"
// Chương 6: Tổng kết
#include "chapter_6/index.typ"
#pagebreak()
// Chương 7: tài liệu tham khảo 
#include "chapter_7/index.typ"
// Chương 8: Phụ lục
#include "chapter_8/index.typ"
// ==== Các hướng dẫn thêm chương mới ====
// #import "chapter_x_typ" as cx
// #cx
