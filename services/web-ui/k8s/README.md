# SMAP Web - Kubernetes Deployment

## Cấu trúc manifests

- `configmap.yaml` - Environment variables cho Next.js app
- `secret.yaml` - Sensitive environment variables (API keys, etc.)
- `deployment.yaml` - Deployment với 2 replicas, health checks, resource limits
- `service.yaml` - ClusterIP service với session affinity
- `ingress.yaml` - NGINX Ingress với WebSocket, security headers, rate limiting
- `nginx.conf` - NGINX config reference (không dùng trong K8s)

## Quick Start

### 1. Build và push Docker image

```bash
# Build và push image
./scripts/build-ui.sh

# Hoặc với custom registry
REGISTRY=your-registry.com ./scripts/build-ui.sh

# Login riêng nếu cần
./scripts/build-ui.sh login
```

### 2. Cập nhật cấu hình

**deployment.yaml:**

```yaml
image: registry.tantai.dev/smap/smap-web:YYMMDD-HHMMSS # Tag từ build script
```

**ingress.yaml:**

```yaml
host: smap.tantai.dev # Domain của bạn
```

**configmap.yaml:**

```yaml
NEXT_PUBLIC_HOSTNAME: "https://smap-api.tantai.dev/identity" # API endpoint
# Note: NEXT_PUBLIC_WS_URL is set at build time, default: wss://smap-api.tantai.dev/ws
# WebSocket now uses port 8081 and HttpOnly Cookie authentication
```

**secret.yaml:**

```yaml
# Thêm các secret thực tế nếu cần
```

### 3. Deploy lên Kubernetes

```bash
# Apply tất cả manifests
kubectl apply -f k8s/

# Hoặc apply từng file
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

### 4. Kiểm tra deployment

```bash
# Check pods
kubectl get pods -n smap -l app=smap-web

# Check service
kubectl get svc -n smap smap-web-service

# Check ingress
kubectl get ingress -n smap smap-web-ingress

# Xem logs
kubectl logs -f deployment/smap-web -n smap

# Describe để debug
kubectl describe deployment smap-web -n smap
kubectl describe ingress smap-web-ingress -n smap
```

## Tính năng

### Deployment

- **2 replicas** cho high availability
- **Rolling updates** với maxSurge=1, maxUnavailable=0
- **Health checks**: Liveness probe (30s delay) và readiness probe (10s delay)
- **Resource limits**:
  - Requests: 250m CPU, 256Mi memory
  - Limits: 500m CPU, 512Mi memory
- **Security**: Non-root user (uid 1001), no privilege escalation
- **Session affinity**: ClientIP với timeout 3 hours

### NGINX Ingress

- **WebSocket support** cho real-time features
  - **New specification**: Port 8081 (changed from 8080)
  - **Authentication**: HttpOnly Cookie (automatic, no JWT token in URL)
  - **Connection patterns**: `/ws?projectId={id}` or `/ws?jobId={id}`
  - **Message format**: Flat structure without type wrapper
- **Security headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Rate limiting**: 100 requests/second per IP
- **Proxy timeouts**: 60s cho connect/send/read
- **Body size limit**: 20MB
- **SSL/TLS ready**: Uncomment để enable cert-manager

### Docker Image

- **Multi-stage build** giảm image size
- **Standalone output** của Next.js
- **Layer caching** tối ưu build time
- **Non-root user** trong container
- **Health check** built-in

## Update Deployment

### Rolling update với image mới

```bash
# Build image mới
./scripts/build-ui.sh

# Update deployment với tag mới
kubectl set image deployment/smap-web \
  smap-web=registry.tantai.dev/smap/smap-web:YYMMDD-HHMMSS \
  -n smap

# Hoặc edit deployment.yaml và apply lại
kubectl apply -f k8s/deployment.yaml

# Theo dõi rollout
kubectl rollout status deployment/smap-web -n smap
```

### Rollback nếu có vấn đề

```bash
# Xem rollout history
kubectl rollout history deployment/smap-web -n smap

# Rollback về version trước
kubectl rollout undo deployment/smap-web -n smap

# Rollback về version cụ thể
kubectl rollout undo deployment/smap-web --to-revision=2 -n smap
```

### Scale replicas

```bash
# Scale up/down
kubectl scale deployment/smap-web --replicas=3 -n smap

# Hoặc edit deployment.yaml và apply
```

## Troubleshooting

### Pods không start

```bash
# Xem events
kubectl describe pod <pod-name> -n smap

# Xem logs
kubectl logs <pod-name> -n smap

# Check image pull
kubectl get events -n smap --sort-by='.lastTimestamp'
```

### Ingress không hoạt động

```bash
# Check ingress
kubectl describe ingress smap-web-ingress -n smap

# Check NGINX Ingress Controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Test service trực tiếp
kubectl port-forward svc/smap-web-service 8080:80 -n smap
# Truy cập http://localhost:8080
```

### Health check fail

```bash
# Exec vào pod để test
kubectl exec -it <pod-name> -n smap -- sh

# Test health endpoint
curl http://localhost:5000/

# Check logs
kubectl logs <pod-name> -n smap --tail=100
```

## Yêu cầu

- Kubernetes cluster đã setup
- Namespace `smap` đã tồn tại
- NGINX Ingress Controller đã cài đặt
- Docker registry accessible từ cluster
- (Optional) cert-manager cho SSL/TLS

## Environment Variables

Các biến môi trường quan trọng trong `configmap.yaml`:

- `NODE_ENV`: production
- `PORT`: 5000
- `NEXT_TELEMETRY_DISABLED`: 1
- `NEXT_PUBLIC_HOSTNAME`: API endpoint (cần cập nhật)

Thêm vào `secret.yaml` nếu cần:

- API keys
- Database URLs
- Third-party credentials

## Notes

- Image tag format: `registry.tantai.dev/smap/smap-web:YYMMDD-HHMMSS`
- Domain mặc định: `smap.tantai.dev` (cần thay đổi)
- Service name: `smap-web-service`
- Deployment name: `smap-web`
- Namespace: `smap`
