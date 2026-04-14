// config.typ

#let conf(doc) = {
  // --- THIẾT LẬP FONT & TEXT ---
  set text(font: "New Computer Modern", size: 12pt, lang: "vi")

  // --- THIẾT LẬP DOCUMENT METADATA ---
  set document(
    title: "Báo cáo Đề tài SMAP (Social Media Analytics Platform)",
    author: "SMAP Team"
  )

  // --- THIẾT LẬP ĐOẠN VĂN ---
  set par(
    justify: true, // Căn đều 2 bên (Bắt buộc với báo cáo)
    
    // 0.8em ~ 1.3 line spacing (Vừa mắt, không quá thưa)
    leading: 0.8em, 
  
  // Khoảng cách đoạn vừa đủ để tách biệt
    spacing: 1em,
  )

  // --- THIẾT LẬP TRANG & HEADER ---
  set page(
    paper: "a4",
    
    margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 2cm),
    header: block(
      width: 100%,
      height: 0%, // Để header không chiếm height layout chính
      [
        #align(left)[
          #stack(
            dir: ltr,
            spacing: 10pt,
            // Lưu ý: Đảm bảo file ảnh nằm đúng đường dẫn tương đối so với main.typ
            image("images/logos/hcmut.png", height: 0.8cm), 
            text(size: 8.5pt, weight: "bold")[
              Trường Đại Học Bách Khoa - Đại học Quốc gia TP.HCM \
              Khoa Khoa Học & Kỹ Thuật Máy Tính
            ]
          )
        ]
        #v(-5pt)
        #line(length: 100%, stroke: 0.5pt)
      ]
    )
  )

  // --- THIẾT LẬP HEADING ---
  set heading(numbering: none)
  show heading: it => {
    // Thiết lập khoảng cách chung cho tất cả heading
    set block(above: 1.5em, below: 1em, sticky: true)
    
    if it.level == 1 {
      // --- CẤP 1 (VÍ DỤ: 1. GIỚI THIỆU) ---
      // Căn giữa trang
      align(center)[
        #set text(size: 16pt, weight: "bold") 
        #upper(it) // Tự động viết hoa toàn bộ tiêu đề
      ]
    } else {
      // --- CÁC CẤP CON (1.1, 1.1.1...) ---
      // Căn trái mặc định
      if it.level == 2 [
        #set text(size: 15pt, weight: "bold")
        #it
      ] else [
        // Cấp 3 trở đi: In đậm + Nghiêng
        #set text(size: 13pt, weight: "bold")
        #it
      ]
    }
  }

  // QUAN TRỌNG NHẤT: Trả về nội dung tài liệu sau khi đã áp dụng các set rule
  doc 
}