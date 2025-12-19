# SEO Controller - Cheatsheet

Quick reference cho các commands thường dùng.

## 🚀 Setup mới

```bash
# Clone và setup
git clone <repo-url> && cd SEO-Controller
npm install
cp .env.example .env
npm run dev
```

## 📦 Development

```bash
npm run dev          # Dev server (port 5000)
npm run build        # Build production
npm start            # Start production
npm run lint         # Check linting
npm run lint -- --fix # Auto-fix lint issues
```

## 🐳 Docker

```bash
docker-compose build              # Build image
docker-compose up                 # Start container
docker-compose up -d              # Start background
docker-compose down               # Stop container
docker-compose logs -f            # View logs
docker-compose build --no-cache   # Clean build
```

## 🔧 Troubleshooting

```bash
# Port đã dùng
netstat -ano | findstr :5000      # Windows
lsof -ti:5000 | xargs kill -9     # Mac/Linux

# Clear cache
rm -rf .next node_modules package-lock.json
npm install

# Clear Docker
docker system prune -a

# Check errors
npm run dev 2>&1 | tee debug.log
```

## 📝 Git Commands

```bash
# Daily workflow
git pull origin main
git checkout -b feature/new-feature
git add .
git commit -m "feat: description"
git push origin feature/new-feature

# Undo changes
git reset --hard HEAD             # Discard all changes
git checkout -- file.txt          # Discard file changes
git revert <commit-hash>          # Revert commit

# View history
git log --oneline --graph
git diff
git status
```

## 🔍 Debugging

```bash
# Check versions
node --version
npm --version
git --version
docker --version

# Check processes
ps aux | grep node               # Mac/Linux
tasklist | findstr node          # Windows

# Check ports
netstat -ano                     # Windows
lsof -i                          # Mac/Linux

# Environment
echo $NODE_ENV                   # Mac/Linux
echo %NODE_ENV%                  # Windows
```

## 📊 Performance

```bash
# Analyze bundle
npm run build
npx @next/bundle-analyzer

# Check deps size
npx depcheck
npm ls --depth=0

# Memory usage
node --max-old-space-size=4096 server.js
```

## 🔒 Security

```bash
# Audit dependencies
npm audit
npm audit fix
npm audit fix --force

# Update deps
npm update
npm outdated
```

## 🌐 Deployment

```bash
# Build for production
NODE_ENV=production npm run build

# Test production locally
npm start

# PM2 (production)
pm2 start npm --name seo-controller -- start
pm2 logs seo-controller
pm2 restart seo-controller
pm2 stop seo-controller
pm2 delete seo-controller
```

## 📱 URLs

```bash
Local Dev:     http://localhost:5000
Dashboard:     http://localhost:5000/dashboard
Trend:         http://localhost:5000/trend-analysis
Workflow:      http://localhost:5000/workflow
Reports:       http://localhost:5000/reports
```

## 🗂️ Project Structure

```
components/    → React components
pages/         → Next.js pages
public/        → Static files
styles/        → CSS files
lib/           → Utilities
contexts/      → React contexts
hooks/         → Custom hooks
services/      → API services
config/        → Config files
```

## 💡 Common Issues

| Issue | Solution |
|-------|----------|
| Port in use | Change port in package.json |
| Module not found | `rm -rf node_modules && npm install` |
| Build fails | `rm -rf .next && npm run build` |
| TypeScript errors | `npx tsc --noEmit` |
| Docker fails | `docker system prune -a` |

## 📚 Documentation

- [SETUP.md](SETUP.md) - Full setup guide
- [QUICK_START.md](QUICK_START.md) - 5-minute setup
- [README.md](README.md) - Project overview
- [docker-build.md](docker-build.md) - Docker guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deploy guide

---

**Keyboard shortcuts:**
- `Ctrl+C` - Stop server
- `Ctrl+Shift+P` - VSCode command palette
- `Ctrl+` ` - VSCode terminal

**Tip:** Save this file for quick reference! 💾
