# Project Context

## Purpose

SMAP Web là một nền tảng giám sát SEO và phân tích xu hướng social media toàn diện. Hệ thống cho phép:

- Theo dõi metrics SEO real-time qua WebSocket
- Phân tích trending topics, hashtags và posts từ các nền tảng social media (TikTok, YouTube, Instagram)
- Tạo và xuất báo cáo SEO tùy chỉnh
- Xây dựng workflow automation với giao diện kéo thả
- Quản lý projects và theo dõi tiến độ crawl data

## Tech Stack

### Core

- **Framework:** Next.js 15.2.3 (App Router)
- **Language:** TypeScript 5.8.2
- **UI Library:** React 19.0.0
- **Styling:** Tailwind CSS 3.4.18

### UI Components

- **Component Library:** Radix UI (Dialog, Tooltip, Collapsible)
- **Icons:** Lucide React, React Icons
- **Animation:** Framer Motion
- **Charts:** Chart.js, Recharts, React Flow (workflow builder)
- **Alerts:** SweetAlert2

### State & Data

- **State Management:** React Context API
- **HTTP Client:** Axios
- **Real-time:** Native WebSocket API

### Internationalization

- **i18n:** next-i18next, react-i18next, i18next

### DevOps

- **Containerization:** Docker, Docker Compose
- **Orchestration:** Kubernetes (k8s/)

## Project Conventions

### Code Style

- Sử dụng TypeScript cho tất cả files (.ts, .tsx)
- Path alias: `@/*` maps to project root
- Component files: PascalCase (e.g., `FlowCanvas.tsx`)
- Hook files: camelCase với prefix `use` (e.g., `useProjectWebSocket.ts`)
- Service files: camelCase với suffix `Service` (e.g., `websocketService.ts`)
- Type files: camelCase (e.g., `dryrun.ts`)

### File Organization

```
components/           # React components theo feature
├── dashboard/       # Dashboard-specific components
├── reports/         # Report components
├── trend/           # Trend analysis components
├── landing/         # Landing page components
├── project/         # Project management components
└── [shared].tsx     # Shared components ở root

pages/               # Next.js pages (Page Router)
contexts/            # React Context providers
hooks/               # Custom React hooks
services/            # API và WebSocket services
lib/                 # Utilities và type definitions
├── api/            # API client và services
├── types/          # TypeScript type definitions
└── [utils].ts      # Utility functions

config/              # Configuration files
public/              # Static assets
documents/           # Documentation
```

### Architecture Patterns

- **Component Pattern:** Functional components với hooks
- **State Pattern:** Context API cho global state (DashboardContext, etc.)
- **Service Pattern:** Separate service layer cho API calls và WebSocket
- **Hook Pattern:** Custom hooks cho reusable logic (useProjectWebSocket, etc.)

### Naming Conventions

- Components: PascalCase
- Functions/Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Types/Interfaces: PascalCase
- Files: Match export name (PascalCase for components, camelCase for others)

### Testing Strategy

- Unit tests cho utility functions
- Component tests với React Testing Library (khi cần)
- E2E tests cho critical flows (khi cần)

### Git Workflow

- Branch naming: `feature/`, `fix/`, `refactor/`, `docs/`
- Commit convention: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- PR required cho merge vào main/master

## Domain Context

### Core Concepts

- **Project:** Một chiến dịch SEO monitoring với brands và competitors
- **Brand:** Thương hiệu của khách hàng cần theo dõi
- **Competitor:** Đối thủ cạnh tranh cần so sánh
- **Job:** Một task crawl data từ social media platform
- **Dry-Run:** Test crawl để preview data trước khi chạy full (đang được thay thế bởi Job)

### Platforms Supported

- TikTok
- YouTube
- Instagram (mới)
- ~~Facebook~~ (deprecated)

### Real-time Features

- Project processing status updates
- Job/Crawl progress tracking
- Content streaming từ crawlers

## Important Constraints

### Technical

- WebSocket authentication qua HttpOnly Cookie (không dùng JWT token trong URL)
- API base URL configurable qua environment variables
- Support cả development (ws://) và production (wss://) WebSocket

### Business

- Multi-tenant: Mỗi user chỉ thấy projects của mình
- Rate limiting trên API calls
- Data retention policies

### Security

- HttpOnly cookies cho authentication
- CORS configuration cho WebSocket
- No sensitive data in client-side storage

## External Dependencies

### Backend API

- **Base URL:** `NEXT_PUBLIC_HOSTNAME` (default: `https://smap-api.tantai.dev`)
- **WebSocket:** `NEXT_PUBLIC_WS_URL` (default: `wss://smap-api.tantai.dev/ws`)

### API Endpoints (Key)

- `/identity/*` - Authentication
- `/projects/*` - Project management
- `/jobs/*` - Job/Crawl management
- `/ws` - WebSocket connection

### Third-party Services

- Social media platform APIs (via backend)
- Analytics services (via backend)
