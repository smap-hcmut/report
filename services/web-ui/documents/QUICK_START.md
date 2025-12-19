# Quick Start - Setup trên máy mới

Hướng dẫn nhanh để chạy project trong 5 phút.

## ⚡ Các bước nhanh

### 1. Clone Project
```bash
git clone <repository-url>
cd SEO-Controller
```

### 2. Cài đặt Dependencies
```bash
npm install
```

### 3. Tạo Environment File
```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

### 4. Chạy Development Server
```bash
npm run dev
```

### 5. Mở Browser
```
http://localhost:5000
```

---

## ✅ Checklist

- [ ] **Node.js** đã cài (>= 18.x) - `node --version`
- [ ] **Git** đã cài - `git --version`
- [ ] Clone repository thành công
- [ ] `npm install` không có lỗi
- [ ] File `.env` đã tạo
- [ ] `npm run dev` chạy thành công
- [ ] Truy cập http://localhost:5000 được

---

## 🔧 Nếu gặp lỗi

### Port 5000 đã dùng?
```bash
# Đổi port trong package.json
"dev": "next dev --port 3000"
```

### Module not found?
```bash
# Cài lại dependencies
rm -rf node_modules package-lock.json
npm install
```

### Build error?
```bash
# Clear cache
rm -rf .next
npm run dev
```

---

## 📚 Xem thêm

- Chi tiết: [SETUP.md](SETUP.md)
- Docker: [docker-build.md](docker-build.md)
- Overview: [README.md](README.md)

---

**Thời gian setup: ~5 phút** ⏱️
