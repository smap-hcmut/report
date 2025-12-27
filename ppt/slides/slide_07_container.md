# Slide 7: Container Diagram (C4 Level 2)
**Thời lượng**: 1.5 phút

---

## Nội dung hiển thị

```
CONTAINER DIAGRAM (C4 Level 2)

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│              [HÌNH: container-diagram.png]                      │
│                                                                 │
│              Sơ đồ các containers trong hệ thống SMAP           │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   10 APPLICATION SERVICES                       │
│                   (Polyglot Architecture)                       │
│                                                                 │
│  ┌──────────────── GOLANG SERVICES (4) ──────────────────────┐  │
│  │                                                            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │  │
│  │  │ Identity │ │ Project  │ │Collector │ │WebSocket │     │  │
│  │  │ Service  │ │ Service  │ │ Service  │ │ Service  │     │  │
│  │  │          │ │          │ │          │ │          │     │  │
│  │  │• JWT Auth│ │• CRUD    │ │•Dispatch │ │•Real-time│     │  │
│  │  │• Users   │ │• Config  │ │•Crawl Job│ │•Progress │     │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────── PYTHON SERVICES (6) ──────────────────────┐  │
│  │                                                            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │  │
│  │  │Analytics │ │Speech2   │ │ YouTube  │ │  TikTok  │     │  │
│  │  │ Service  │ │  Text    │ │ Scraper  │ │ Scraper  │     │  │
│  │  │          │ │          │ │          │ │          │     │  │
│  │  │•PhoBERT  │ │•Audio→   │ │•API Call │ │•Scraping │     │  │
│  │  │•Sentiment│ │  Text    │ │•Metadata │ │•Playwright│    │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │  │
│  │                                                            │  │
│  │  ┌──────────┐ ┌──────────┐                                │  │
│  │  │  FFmpeg  │ │Playwright│                                │  │
│  │  │ Service  │ │ Service  │                                │  │
│  │  │          │ │          │                                │  │
│  │  │•Video    │ │•Browser  │                                │  │
│  │  │  Process │ │  Automate│                                │  │
│  │  └──────────┘ └──────────┘                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────── FRONTEND (1) ─────────────────────────────┐  │
│  │  Web UI (Next.js/TypeScript) - Dashboard & Visualization  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Đường dẫn | Mô tả |
|------|-----------|-------|
| **Container Diagram** | `report/images/diagram/container-diagram.png` | Sơ đồ C4 Level 2 - Containers |

---

## Văn nói (Script)

> "Đi sâu hơn vào bên trong, đây là Container Diagram theo C4 Model. SMAP được thiết kế theo **Polyglot Architecture** với **10 application services**:
>
> **4 Golang Services** - Chọn Go vì performance cao:
> - **Identity Service**: Xác thực JWT, quản lý users
> - **Project Service**: CRUD projects, cấu hình keywords
> - **Collector Service**: Điều phối crawling jobs
> - **WebSocket Service**: Real-time progress notifications
>
> **6 Python Services** - Chọn Python vì ecosystem ML và scraping mạnh:
> - **Analytics Service**: PhoBERT sentiment analysis, aspect extraction
> - **Speech2Text Service**: Chuyển audio thành text (tiếng Việt)
> - **YouTube Scraper**: Thu thập dữ liệu YouTube qua API
> - **TikTok Scraper**: Scraping TikTok với Playwright
> - **FFmpeg Service**: Video processing
> - **Playwright Service**: Browser automation
>
> **Frontend**: Web UI viết bằng Next.js với TypeScript cho dashboard và visualization.
>
> Kiến trúc Polyglot này cho phép chúng em chọn đúng công nghệ cho đúng công việc, đồng thời các services giao tiếp qua **RabbitMQ** cho async processing và **Redis Pub/Sub** cho real-time events."

---

## Ghi chú kỹ thuật
- Hình chính là `container-diagram.png` từ báo cáo
- Bảng tóm tắt 10 services với 3 nhóm: Go, Python, Frontend
- Nhấn mạnh: **Polyglot Architecture** - chọn đúng công nghệ cho đúng mục đích
- Go cho high-performance APIs, Python cho ML/AI và web scraping
- Không cần giải thích chi tiết implementation từng service

---

## Key points
1. **10 Application Services** (Polyglot Architecture)
2. **Golang Services (4)**: Identity, Project, Collector, WebSocket
3. **Python Services (6)**: Analytics, Speech2Text, YouTube Scraper, TikTok Scraper, FFmpeg, Playwright
4. **Frontend (1)**: Web UI (Next.js/TypeScript)
5. Giao tiếp: RabbitMQ + Redis Pub/Sub

