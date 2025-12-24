# Slide 6: System Context (C4 Level 1)
**Thời lượng**: 1 phút

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

> "Bây giờ chúng em sẽ trình bày về kiến trúc hệ thống, bắt đầu với sơ đồ ngữ cảnh theo mô hình C4.
>
> Ở mức cao nhất, hệ thống SMAP tương tác với 2 actors chính:
>
> **Marketing Analyst** - người dùng chính của hệ thống. Họ sử dụng SMAP để cấu hình project, theo dõi tiến trình thu thập, xem kết quả phân tích và xuất báo cáo.
>
> **Social Media Platforms** - bao gồm YouTube và TikTok. Đây là nguồn dữ liệu mà hệ thống thu thập thông qua các API công khai hoặc web scraping.
>
> Sơ đồ này cho thấy SMAP đóng vai trò trung gian, thu thập dữ liệu từ các platforms, xử lý và cung cấp insights cho người dùng."

---

## Ghi chú kỹ thuật
- Đây là slide đầu tiên về kiến trúc
- Dùng đúng hình từ báo cáo: `context-diagram.png`
- Giải thích đơn giản, không đi sâu vào chi tiết
- C4 Model: Context → Container → Component → Code

---

## Transition
> "Tiếp theo, chúng em sẽ đi sâu hơn vào bên trong hệ thống với Container Diagram..."

