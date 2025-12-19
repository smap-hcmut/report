# Setup Guide - SEO Controller

Hướng dẫn chi tiết để setup project trên máy tính mới.

## Prerequisites (Yêu cầu)

Trước khi bắt đầu, đảm bảo máy tính đã cài đặt:

- **Node.js** >= 18.x (Recommended: 20.x)
  - Download: https://nodejs.org/
  - Kiểm tra: `node --version`

- **npm** >= 9.x (đi kèm với Node.js)
  - Kiểm tra: `npm --version`

- **Git**
  - Download: https://git-scm.com/
  - Kiểm tra: `git --version`

- **Docker** (Optional - nếu muốn chạy trong container)
  - Download: https://www.docker.com/products/docker-desktop
  - Kiểm tra: `docker --version`

---

## Bước 1: Clone Repository

```bash
# Clone project từ Git
git clone <repository-url>

# Hoặc nếu đã có folder, vào thư mục project
cd SEO-Controller
```

---

## Bước 2: Cài đặt Dependencies

```bash
# Cài đặt tất cả packages
npm install

# Hoặc nếu gặp lỗi peer dependencies
npm install --legacy-peer-deps
```

**Lưu ý:** Quá trình này có thể mất 2-5 phút tùy tốc độ mạng.

---

## Bước 3: Cấu hình Environment Variables

```bash
# Copy file example
cp .env.example .env

# Hoặc trên Windows
copy .env.example .env
```

Sau đó mở file `.env` và điền các giá trị cần thiết:

```env
NODE_ENV=development
PORT=5000
HOSTNAME=0.0.0.0

# Thêm các biến môi trường khác nếu cần
# API_URL=
# DATABASE_URL=
```

---

## Bước 4: Chạy Development Server

### Option 1: Chạy trực tiếp với npm

```bash
# Chạy development mode
npm run dev
```

Server sẽ chạy tại: **http://localhost:5000**

### Option 2: Chạy production build

```bash
# Build project
npm run build

# Start production server
npm start
```

---

## Bước 5: Xác nhận Setup thành công

Mở trình duyệt và truy cập:
- Development: http://localhost:5000
- Production: http://localhost:5000

Bạn sẽ thấy giao diện SEO Controller dashboard.

---

## Setup với Docker (Optional)

Nếu muốn chạy project trong Docker container:

### 1. Build Docker image

```bash
# Build image
docker-compose build

# Hoặc build không cache
docker-compose build --no-cache
```

### 2. Run container

```bash
# Start container
docker-compose up

# Hoặc chạy background (detached mode)
docker-compose up -d
```

### 3. Stop container

```bash
docker-compose down
```

### 4. View logs

```bash
docker-compose logs -f
```

Xem thêm: [docker-build.md](docker-build.md)

---

## Cấu trúc Project

```
SEO-Controller/
├── components/          # React components
│   ├── dashboard/      # Dashboard components
│   ├── reports/        # Report components
│   └── trend/          # Trend analysis components
├── pages/              # Next.js pages
├── public/             # Static assets
├── styles/             # CSS/styling files
├── lib/                # Utility libraries
├── contexts/           # React contexts
├── hooks/              # Custom React hooks
├── services/           # API services
├── config/             # Configuration files
└── .next/              # Build output (auto-generated)
```

---

## Scripts có sẵn

```bash
# Development server
npm run dev              # Chạy dev server (port 5000)

# Production build
npm run build            # Build project
npm start                # Start production server

# Linting
npm run lint             # Check code quality
```

---

## Troubleshooting (Xử lý lỗi)

### 1. Port 5000 đã được sử dụng

**Lỗi:** `Error: listen EADDRINUSE: address already in use :::5000`

**Giải pháp:**
```bash
# Windows: Tìm và kill process
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Linux/Mac: Tìm và kill process
lsof -ti:5000 | xargs kill -9

# Hoặc đổi port trong package.json
# Sửa: "dev": "next dev --port 3000"
```

### 2. Module not found errors

**Lỗi:** `Error: Cannot find module 'xyz'`

**Giải pháp:**
```bash
# Xóa node_modules và reinstall
rm -rf node_modules package-lock.json
npm install

# Windows
rmdir /s /q node_modules
del package-lock.json
npm install
```

### 3. Build fails với ESLint errors

**Giải pháp:**
```bash
# Fix auto-fixable issues
npm run lint -- --fix

# Hoặc tạm thời disable trong next.config.ts
# eslint: { ignoreDuringBuilds: true }
```

### 4. TypeScript errors

**Lỗi:** Type errors trong build

**Giải pháp:**
```bash
# Check TypeScript errors
npx tsc --noEmit

# Xóa TypeScript cache
rm -rf .next tsconfig.tsbuildinfo
npm run dev
```

### 5. Next.js cache issues

**Giải pháp:**
```bash
# Xóa .next folder và rebuild
rm -rf .next
npm run dev

# Windows
rmdir /s /q .next
npm run dev
```

### 6. Docker build fails

**Giải pháp:**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

---

## Cập nhật Dependencies

```bash
# Check outdated packages
npm outdated

# Update to latest versions
npm update

# Update specific package
npm update <package-name>

# Update to latest major version
npm install <package-name>@latest
```

---

## Git Workflow

### Clone và Setup
```bash
# Clone repository
git clone <repository-url>
cd SEO-Controller

# Check current branch
git branch

# Switch to main branch
git checkout main

# Update from remote
git pull origin main
```

### Làm việc với branches
```bash
# Tạo branch mới
git checkout -b feature/ten-feature

# Commit changes
git add .
git commit -m "feat: mô tả thay đổi"

# Push lên remote
git push origin feature/ten-feature

# Merge vào main
git checkout main
git merge feature/ten-feature
git push origin main
```

---

## Testing

### Manual Testing
1. Start dev server: `npm run dev`
2. Mở http://localhost:5000
3. Test các features:
   - Dashboard hiển thị đúng
   - Trend analysis hoạt động
   - Report generation
   - Real-time data updates

### Production Testing
```bash
# Build và test production
npm run build
npm start

# Verify build output
ls -la .next/standalone
```

---

## Performance Tips

### 1. Enable SWC compiler (đã enable mặc định trong Next.js 12+)
Next.js sử dụng SWC compiler để build nhanh hơn.

### 2. Use production build
```bash
NODE_ENV=production npm run build
npm start
```

### 3. Enable caching
- Next.js tự động cache static assets
- API responses có thể cache với Redis (nếu cần)

### 4. Optimize images
- Sử dụng Next.js Image component
- Images tự động optimize

---

## Development Guidelines

### Code Style
- Follow ESLint rules
- Use TypeScript types
- Component naming: PascalCase
- File naming: camelCase or kebab-case

### Commit Messages
Format: `type: description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

Example:
```bash
git commit -m "feat: add real-time dashboard updates"
git commit -m "fix: resolve undefined value in config"
```

---

## Support & Documentation

### Tài liệu tham khảo
- Next.js: https://nextjs.org/docs
- React: https://react.dev/
- TypeScript: https://www.typescriptlang.org/docs
- Tailwind CSS: https://tailwindcss.com/docs

### Files quan trọng
- [README.md](README.md) - Project overview
- [docker-build.md](docker-build.md) - Docker guide
- [CHART_DATA_STRUCTURES.md](CHART_DATA_STRUCTURES.md) - Chart data structures
- [package.json](package.json) - Dependencies

### Contact
- Report issues: [GitHub Issues]
- Documentation: [Wiki/Docs]

---

## Quick Start Checklist

- [ ] Cài đặt Node.js (>= 18.x)
- [ ] Cài đặt Git
- [ ] Clone repository
- [ ] Run `npm install`
- [ ] Copy `.env.example` to `.env`
- [ ] Run `npm run dev`
- [ ] Open http://localhost:5000
- [ ] Verify dashboard loads correctly

---

## Next Steps

Sau khi setup thành công:

1. **Đọc code structure** - Hiểu cấu trúc project
2. **Review components** - Xem các components chính
3. **Test features** - Test tất cả tính năng
4. **Setup IDE** - Configure VSCode/IDE settings
5. **Join team** - Liên hệ team để onboard

---

**Chúc bạn setup thành công! 🚀**
