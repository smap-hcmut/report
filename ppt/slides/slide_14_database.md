# Slide 14: Database Strategy
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
DATABASE STRATEGY

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                  DATABASE-PER-SERVICE PATTERN                   │
│                                                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐  │
│  │                         │  │                             │  │
│  │    [identity-erd.png]   │  │    [project-erd.png]        │  │
│  │                         │  │                             │  │
│  │    Identity Database    │  │    Project Database         │  │
│  │                         │  │                             │  │
│  └─────────────────────────┘  └─────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │              [analytic-erd.png]                         │   │
│  │                                                         │   │
│  │              Analytics Schema (trong Project DB)        │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      THIẾT KẾ DATABASE                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  IDENTITY DATABASE (PostgreSQL)                          │   │
│  │  • users - Thông tin người dùng                         │   │
│  │  • sessions - Phiên đăng nhập                           │   │
│  │  • refresh_tokens - JWT refresh tokens                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PROJECT DATABASE (PostgreSQL)                           │   │
│  │  • projects - Thông tin projects                        │   │
│  │  • keywords - Từ khóa theo dõi                          │   │
│  │  • executions - Lịch sử thực thi                        │   │
│  │  • videos, comments - Dữ liệu crawl                     │   │
│  │  • sentiment_results - Kết quả phân tích                │   │
│  │  • trends - Xu hướng phát hiện                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ✅ Soft Delete Pattern - Không xóa vĩnh viễn, đánh dấu        │
│  ✅ Indexes tối ưu - Query performance                          │
│  ✅ Foreign Keys - Data integrity                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Identity ERD** | `report/images/erd/identity-erd.png` | ERD cho Identity Service |
| **Project ERD** | `report/images/erd/project-erd.png` | ERD cho Project Service |
| **Analytic ERD** | `report/images/erd/analytic-erd.png` | ERD cho Analytics data |

---

## Văn nói (Script)

> "Về database, chúng em áp dụng **Database-per-Service pattern** - mỗi service có database riêng.
>
> **Identity Database** lưu trữ thông tin users, sessions và refresh tokens. Database này hoàn toàn độc lập, chỉ Identity Service được truy cập.
>
> **Project Database** lưu trữ tất cả dữ liệu nghiệp vụ: projects, keywords, executions, videos, comments và kết quả phân tích sentiment.
>
> Một số design patterns chúng em áp dụng:
> - **Soft Delete**: Không xóa vĩnh viễn dữ liệu, chỉ đánh dấu deleted_at. Giúp khôi phục dữ liệu khi cần.
> - **Indexes tối ưu**: Đánh index cho các columns thường query như project_id, created_at, status.
> - **Foreign Keys**: Đảm bảo data integrity giữa các tables.
>
> Pattern Database-per-Service giúp các services độc lập hoàn toàn, có thể scale và backup riêng."

---

## Ghi chú kỹ thuật
- Dùng 3 ERD diagrams từ báo cáo
- Không cần giải thích chi tiết từng table
- Nhấn mạnh: Database-per-Service, Soft Delete, Indexes
- Có thể gộp 3 ERD vào 1 slide hoặc show 1 cái đại diện

---

## Key points
1. Database-per-Service pattern
2. 2 PostgreSQL databases độc lập
3. Soft Delete pattern
4. Optimized indexes

