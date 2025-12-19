# Deployment Guide

Hướng dẫn deploy SEO Controller lên production.

## Pre-deployment Checklist

- [ ] Code đã được review
- [ ] Tất cả tests pass
- [ ] Build local thành công (`npm run build`)
- [ ] Environment variables đã chuẩn bị
- [ ] Database/API endpoints đã sẵn sàng
- [ ] SSL certificates đã có (nếu cần)
- [ ] Backup dữ liệu hiện tại (nếu có)

---

## Deployment Options

### Option 1: Traditional Server (VPS/Cloud)

#### 1. Chuẩn bị Server

**Requirements:**
- Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- Node.js 18+ installed
- nginx (recommended)
- PM2 (process manager)
- Minimum 2GB RAM, 2 CPU cores

#### 2. Setup Server

```bash
# SSH vào server
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2
sudo npm install -g pm2

# Install nginx
sudo apt install -y nginx
```

#### 3. Clone và Build Project

```bash
# Clone repository
git clone <repository-url> /var/www/seo-controller
cd /var/www/seo-controller

# Install dependencies
npm ci --production

# Build project
npm run build

# Test production build
npm start
```

#### 4. Setup PM2

```bash
# Create PM2 ecosystem file
pm2 ecosystem
```

Edit `ecosystem.config.js`:
```javascript
module.exports = {
  apps: [{
    name: 'seo-controller',
    script: 'npm',
    args: 'start',
    cwd: '/var/www/seo-controller',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
    },
  }]
}
```

```bash
# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 config
pm2 save

# Setup startup script
pm2 startup
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME
```

#### 5. Configure nginx

```bash
sudo nano /etc/nginx/sites-available/seo-controller
```

Add configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/seo-controller /etc/nginx/sites-enabled/

# Test nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

#### 6. Setup SSL (Let's Encrypt)

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo certbot renew --dry-run
```

---

### Option 2: Docker Deployment

#### 1. Build Docker Image

```bash
# Build production image
docker build -t seo-controller:latest .

# Or with docker-compose
docker-compose -f docker-compose.prod.yml build
```

#### 2. Run Container

```bash
# Run with docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Or with docker run
docker run -d \
  --name seo-controller \
  -p 5000:5000 \
  --restart unless-stopped \
  -e NODE_ENV=production \
  seo-controller:latest
```

#### 3. Setup nginx (same as above)

---

### Option 3: Cloud Platforms

#### Vercel (Recommended for Next.js)

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

**Config vercel.json:**
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

#### AWS (EC2 + Elastic Beanstalk)

1. Create Elastic Beanstalk application
2. Upload Docker configuration or Node.js app
3. Configure environment variables
4. Deploy

#### Google Cloud Platform (Cloud Run)

```bash
# Build and push to GCR
gcloud builds submit --tag gcr.io/PROJECT_ID/seo-controller

# Deploy to Cloud Run
gcloud run deploy seo-controller \
  --image gcr.io/PROJECT_ID/seo-controller \
  --platform managed \
  --port 5000
```

#### DigitalOcean App Platform

1. Connect GitHub repository
2. Configure build settings
3. Add environment variables
4. Deploy

---

## Environment Variables

Create `.env.production`:

```env
# Application
NODE_ENV=production
PORT=5000
HOSTNAME=0.0.0.0

# API & Backend (if applicable)
API_URL=https://api.your-domain.com
API_KEY=your-api-key

# Database (if applicable)
DATABASE_URL=postgresql://user:password@host:port/database

# Redis (if applicable)
REDIS_URL=redis://host:port

# Security
SECRET_KEY=your-secret-key
JWT_SECRET=your-jwt-secret

# External Services
ANALYTICS_ID=your-analytics-id
```

---

## Post-deployment Tasks

### 1. Verify Deployment

```bash
# Check server response
curl -I https://your-domain.com

# Check PM2 status
pm2 status

# View logs
pm2 logs seo-controller

# Check nginx status
sudo systemctl status nginx
```

### 2. Monitor Performance

```bash
# Install monitoring tools
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7

# Setup monitoring (PM2 Plus - optional)
pm2 plus
```

### 3. Setup Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup-seo-controller.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/seo-controller"
APP_DIR="/var/www/seo-controller"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup application files
tar -czf $BACKUP_DIR/app_$DATE.tar.gz $APP_DIR

# Keep only last 7 days
find $BACKUP_DIR -name "app_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-seo-controller.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
0 2 * * * /usr/local/bin/backup-seo-controller.sh
```

### 4. Setup Log Rotation

```bash
sudo nano /etc/logrotate.d/seo-controller
```

```
/var/www/seo-controller/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
```

---

## Updating Production

### Zero-downtime Deployment

```bash
# On server
cd /var/www/seo-controller

# Pull latest changes
git pull origin main

# Install dependencies
npm ci --production

# Build
npm run build

# Reload PM2 (zero-downtime)
pm2 reload seo-controller
```

### Rollback Strategy

```bash
# Tag current version before deploy
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# If need to rollback
git checkout v1.0.0
npm ci --production
npm run build
pm2 reload seo-controller
```

---

## Monitoring & Maintenance

### Health Checks

```bash
# Check application health
curl https://your-domain.com/api/health

# Check PM2 status
pm2 status

# Check resource usage
pm2 monit
```

### Log Management

```bash
# View PM2 logs
pm2 logs seo-controller

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### Performance Monitoring

```bash
# Check server resources
htop

# Check disk usage
df -h

# Check memory usage
free -h

# Check network connections
netstat -tunlp
```

---

## Troubleshooting

### Application won't start

```bash
# Check PM2 logs
pm2 logs seo-controller --err

# Check if port is in use
sudo lsof -i :5000

# Restart PM2
pm2 restart seo-controller
```

### High memory usage

```bash
# Increase Node memory limit
pm2 delete seo-controller
pm2 start npm --name seo-controller -- start --node-args="--max-old-space-size=4096"
```

### Database connection issues

```bash
# Check environment variables
pm2 env seo-controller

# Test database connection
psql -h host -U user -d database
```

---

## Security Best Practices

- [ ] Use HTTPS (SSL/TLS)
- [ ] Keep Node.js and dependencies updated
- [ ] Use strong passwords and keys
- [ ] Enable firewall (ufw/iptables)
- [ ] Setup fail2ban for SSH protection
- [ ] Regular security audits: `npm audit`
- [ ] Limit file upload sizes
- [ ] Sanitize user inputs
- [ ] Use CSP headers
- [ ] Regular backups

---

## Performance Optimization

### 1. Enable caching

Add to nginx config:
```nginx
# Browser caching
location /_next/static {
    alias /var/www/seo-controller/.next/static;
    expires 365d;
    access_log off;
}
```

### 2. Enable compression

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
```

### 3. Use CDN for static assets

- Upload static files to CDN
- Update Next.js config with CDN URL
- Update image URLs

---

## Support & Resources

- PM2 docs: https://pm2.keymetrics.io/docs
- nginx docs: https://nginx.org/en/docs
- Next.js deployment: https://nextjs.org/docs/deployment
- Let's Encrypt: https://letsencrypt.org/

---

**Deploy with confidence! 🚀**
