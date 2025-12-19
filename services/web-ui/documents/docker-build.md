# Docker Build Guide

## Prerequisites
- Docker installed on your system
- Docker Compose (optional, but recommended)

## Build Commands

### Option 1: Using Docker Compose (Recommended)

```bash
# Build the image
docker-compose build

# Build without cache (clean build)
docker-compose build --no-cache

# Run the container
docker-compose up

# Run in detached mode (background)
docker-compose up -d

# Stop the container
docker-compose down

# View logs
docker-compose logs -f
```

### Option 2: Using Docker CLI

```bash
# Build the image
docker build -t seo-controller:latest .

# Build for specific platform (e.g., for deployment)
docker build --platform linux/amd64 -t seo-controller:latest .

# Run the container
docker run -p 5000:5000 --name seo-controller-app seo-controller:latest

# Run with environment variables
docker run -p 5000:5000 --env-file .env --name seo-controller-app seo-controller:latest

# Run in detached mode
docker run -d -p 5000:5000 --name seo-controller-app seo-controller:latest

# Stop the container
docker stop seo-controller-app

# Remove the container
docker rm seo-controller-app

# View logs
docker logs -f seo-controller-app
```

## Docker Architecture

### Multi-Stage Build
The Dockerfile uses a 3-stage build process:

1. **deps**: Install dependencies
2. **builder**: Build the Next.js application
3. **runner**: Create minimal production image

This approach:
- Reduces final image size
- Improves security
- Speeds up builds with layer caching

### Image Optimization
- Uses Alpine Linux (minimal size)
- Only includes production dependencies
- Runs as non-root user (security)
- Standalone Next.js output

## Environment Variables

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Then edit `.env` with your values.

## Troubleshooting

### Build fails with dependency errors
```bash
# Clear Docker cache and rebuild
docker-compose build --no-cache
```

### Port already in use
```bash
# Change port in docker-compose.yml or use different port
docker-compose up -p 3000:5000
```

### Container crashes immediately
```bash
# Check logs
docker-compose logs

# Or for Docker CLI
docker logs seo-controller-app
```

## Production Deployment

### Build for production
```bash
# Build with production optimizations
docker build --build-arg NODE_ENV=production -t seo-controller:prod .
```

### Push to registry (example: Docker Hub)
```bash
# Tag the image
docker tag seo-controller:latest your-username/seo-controller:latest

# Push to registry
docker push your-username/seo-controller:latest
```

## Development with Docker

To enable hot-reload during development, uncomment the volumes section in `docker-compose.yml`:

```yaml
volumes:
  - .:/app
  - /app/node_modules
  - /app/.next
```

Then use development build:
```bash
docker-compose -f docker-compose.dev.yml up
```

## Health Check

The container includes a health check that pings the application every 30 seconds:
```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' seo-controller-app
```

## Resource Limits

Default limits in docker-compose.yml:
- CPU: 2 cores max, 0.5 cores reserved
- Memory: 2GB max, 512MB reserved

Adjust these based on your needs.
