# Slide 6: System Context (C4 Level 1)
**Thời lượng**: 30 giây

---

## Nội dung hiển thị

```
SYSTEM CONTEXT DIAGRAM (C4 Level 1)

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│              [HÌNH: context-diagram.png]                        │
│                                                                 │
│              Sơ đồ ngữ cảnh hệ thống SMAP                       │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Actors:
┌─────────────────┐                              ┌─────────────────┐
│ Marketing       │                              │ Social Media    │
│ Analyst         │ ◄────────► SMAP ◄──────────► │ Platforms       │
│                 │                              │ (YouTube,TikTok)│
└─────────────────┘                              └─────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Context Diagram** | `report/images/diagram/context-diagram.png` | Sơ đồ C4 Level 1 - System Context |

---

## Văn nói (Script)

> "Chuyển sang kiến trúc hệ thống. Đây là **System Context Diagram** theo mô hình C4 - mức cao nhất.
>
> SMAP tương tác với **2 actors chính**:
>
> **Marketing Analyst** - người dùng chính, sử dụng SMAP để cấu hình project, xem kết quả phân tích.
>
> **Social Media Platforms** - YouTube và TikTok, nguồn dữ liệu thu thập qua API và web scraping.
>
> SMAP đóng vai trò trung gian: Thu thập → Xử lý → Cung cấp insights."

---

## Ghi chú kỹ thuật
- Slide đầu tiên về kiến trúc - giới thiệu RẤT NHANH
- Dùng hình từ báo cáo: `context-diagram.png`
- Giải thích cực ngắn gọn, chỉ 30 giây
- C4 Model: Context (Level 1) → Container (Level 2) → Component (Level 3)
- Chỉ giới thiệu 2 actors, không đi sâu chi tiết

---

## Transition
> "Tiếp theo, chúng em sẽ đi sâu hơn vào bên trong hệ thống với Container Diagram..."

