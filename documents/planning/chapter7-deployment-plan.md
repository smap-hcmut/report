# Kế hoạch Chi tiết Chương 7: Triển khai Hệ thống SMAP

## Tổng quan
Dựa trên phân tích source code và infrastructure của hệ thống SMAP, chương 7 sẽ trình bày việc triển khai hệ thống Microservices với kiến trúc Event-driven lên môi trường Kubernetes production. Hệ thống sử dụng container-based deployment với Docker registry riêng và CI/CD automation.

## Cấu trúc Chương 7 được đề xuất

### 7.1. Môi trường triển khai và kiến trúc hạ tầng

#### 7.1.1. Mô hình triển khai (Deployment Model)
**Kubernetes-based Microservices Architecture**
- **Production Domain**: `smap-api.tantai.dev`
- **Container Registry**: `registry.tantai.dev/smap/`
- **Orchestration**: Kubernetes cluster với namespace `smap`
- **Load Balancer**: NGINX Ingress Controller
- **Service Mesh**: Kubernetes native service discovery

**Service Distribution:**
```yaml
# Kubernetes Cluster Layout
Namespace: smap
├── Frontend (Web-UI)
│   └── Next.js app (port 3000/5000)
├── Backend Services
│   ├── Identity Service (Go) - port 8080
│   ├── Project Service (Go) - port 8080  
│   ├── Collector Service (Go) - port 8080
│   ├── Analytics API (Python) - port 8000
│   ├── Analytics Consumer (Python) - background
│   ├── Speech2Text Service (Python) - port 8000
│   └── WebSocket Service (Go) - port 8081
├── Scraping Workers
│   ├── TikTok Scraper (Python) - background
│   └── YouTube Scraper (Python) - background
└── Infrastructure
    ├── PostgreSQL (multiple instances)
    ├── MongoDB (crawl data)
    ├── Redis (caching + pub/sub)
    ├── RabbitMQ (message queue)
    └── MinIO (object storage)
```

#### 7.1.2. Cấu hình phần cứng và phần mềm (Baseline)
**Kubernetes Cluster Specifications**
- **OS**: Ubuntu 20.04 LTS
- **Container Runtime**: Docker 24.0+
- **Kubernetes**: v1.28+
- **Ingress**: NGINX Ingress Controller
- **Storage**: Persistent Volumes với SSD
- **Network**: CNI plugin (Calico/Flannel)

**Node Requirements:**
```yaml
Master Nodes (3x):
  CPU: 4 cores
  RAM: 8GB
  Storage: 100GB SSD

Worker Nodes (5x):
  CPU: 8 cores  
  RAM: 16GB
  Storage: 200GB SSD
  
AI/ML Nodes (2x):
  CPU: 16 cores
  RAM: 32GB
  Storage: 500GB SSD
  GPU: Optional (for future ML workloads)
```

**Software Stack:**
- **Go Services**: Go 1.25.4 runtime
- **Python Services**: Python 3.10+ với virtual environments
- **Frontend**: Node.js 18+ với Next.js 15
- **Databases**: PostgreSQL 15, MongoDB 7.0, Redis 7.0
- **Message Queue**: RabbitMQ 3.12
- **Object Storage**: MinIO latest

#### 7.1.3. Cấu hình mạng và tên miền
**DNS Configuration:**
```dns
# A Records
smap-api.tantai.dev     → Load Balancer IP
registry.tantai.dev     → Docker Registry IP

# CNAME Records  
www.smap.tantai.dev     → smap-api.tantai.dev
dashboard.smap.com      → smap-api.tantai.dev
```

**Network Security:**
```yaml
Firewall Rules:
  - Port 80/443: Public (HTTPS/HTTP)
  - Port 22: SSH (restricted IPs)
  - Port 6443: Kubernetes API (internal)
  - Port 2379-2380: etcd (internal)
  - Port 10250: kubelet (internal)
  
Security Groups:
  - Web Tier: 80, 443
  - App Tier: 8000-8081 (internal)
  - Data Tier: 5432, 27017, 6379, 5672 (internal)
```

**Ingress Routing:**
```yaml
# services/websocket/k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: smap-ingress
  namespace: smap
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/websocket-services: "smap-websocket"
spec:
  rules:
    - host: smap-api.tantai.dev
      http:
        paths:
          - path: /identity(/|$)(.*)
            backend:
              service:
                name: smap-identity-api
                port: 80
          - path: /project(/|$)(.*)  
            backend:
              service:
                name: smap-project-api
                port: 80
          - path: /ws
            backend:
              service:
                name: smap-websocket
                port: 8081
```

### 7.2. Container Registry và Image Management

#### 7.2.1. Private Docker Registry Setup
**Harbor Registry Configuration:**
- **Registry URL**: `registry.tantai.dev`
- **Projects**: `smap` (private project)
- **Authentication**: Username/Password + Robot accounts
- **Security**: Vulnerability scanning enabled
- **Replication**: Multi-region backup

**Image Naming Convention:**
```bash
# Service Images
registry.tantai.dev/smap/smap-identity:241215-143022
registry.tantai.dev/smap/smap-project:241215-143022
registry.tantai.dev/smap/smap-collector:241215-143022
registry.tantai.dev/smap/smap-analytics-api:241215-143022
registry.tantai.dev/smap/smap-analytics-consumer:241215-143022
registry.tantai.dev/smap/smap-websocket:241215-143022
registry.tantai.dev/smap/smap-web-ui:241215-143022

# Scraper Images
registry.tantai.dev/smap/tiktok-scraper:241215-143022
registry.tantai.dev/smap/youtube-scraper:241215-143022
```

#### 7.2.2. Build Scripts và Automation
**Automated Build Process:**
```bash
# services/websocket/scripts/build-websocket.sh
#!/bin/bash
REGISTRY="registry.tantai.dev"
PROJECT="smap"
SERVICE="smap-websocket"
PLATFORM="linux/amd64"

# Multi-stage Docker build
docker buildx build \
    --platform "$PLATFORM" \
    --provenance=false \
    --sbom=false \
    --tag "$REGISTRY/$PROJECT/$SERVICE:$(date +%y%m%d-%H%M%S)" \
    --tag "$REGISTRY/$PROJECT/$SERVICE:latest" \
    --file "cmd/server/Dockerfile" \
    --push .
```

**Dockerfile Optimization:**
```dockerfile
# Go Services - Multi-stage build
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/server/main.go

FROM scratch
COPY --from=builder /app/main /main
EXPOSE 8080
CMD ["/main"]

# Python Services - Optimized layers
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 7.3. CI/CD Pipeline với GitHub Actions

#### 7.3.1. GitHub Actions Workflow
**Multi-Service Pipeline:**
```yaml
# .github/workflows/deploy.yml
name: SMAP Deployment Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      identity: ${{ steps.changes.outputs.identity }}
      project: ${{ steps.changes.outputs.project }}
      collector: ${{ steps.changes.outputs.collector }}
      analytics: ${{ steps.changes.outputs.analytics }}
      websocket: ${{ steps.changes.outputs.websocket }}
      web-ui: ${{ steps.changes.outputs.web-ui }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            identity:
              - 'services/identity/**'
            project:
              - 'services/project/**'
            collector:
              - 'services/collector/**'
            analytics:
              - 'services/analytic/**'
            websocket:
              - 'services/websocket/**'
            web-ui:
              - 'services/web-ui/**'

  build-and-test:
    needs: detect-changes
    strategy:
      matrix:
        service: [identity, project, collector, analytics, websocket, web-ui]
    runs-on: ubuntu-latest
    if: needs.detect-changes.outputs[matrix.service] == 'true'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go (for Go services)
        if: contains(fromJson('["identity", "project", "collector", "websocket"]'), matrix.service)
        uses: actions/setup-go@v4
        with:
          go-version: '1.25'
          
      - name: Setup Python (for Python services)  
        if: contains(fromJson('["analytics"]'), matrix.service)
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          
      - name: Setup Node.js (for Frontend)
        if: matrix.service == 'web-ui'
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Run Tests
        run: |
          cd services/${{ matrix.service }}
          make test
          
      - name: Build Docker Image
        run: |
          cd services/${{ matrix.service }}
          ./scripts/build-${{ matrix.service }}.sh
        env:
          REGISTRY: ${{ secrets.DOCKER_REGISTRY }}
          HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
          HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}

  deploy-staging:
    needs: [detect-changes, build-and-test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'
          
      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBE_CONFIG_STAGING }}" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          
      - name: Deploy to Staging
        run: |
          kubectl apply -f k8s/staging/
          kubectl rollout restart deployment -n smap-staging
          
  deploy-production:
    needs: [detect-changes, build-and-test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Production
        run: |
          kubectl apply -f k8s/production/
          kubectl rollout restart deployment -n smap
```

#### 7.3.2. Environment Management
**Multi-Environment Strategy:**
```yaml
# Development Environment
Environment: development
Namespace: smap-dev
Domain: dev-api.smap.com
Database: dev-postgres
Features: Debug enabled, Mock services

# Staging Environment  
Environment: staging
Namespace: smap-staging
Domain: staging-api.smap.com
Database: staging-postgres
Features: Production-like, Load testing

# Production Environment
Environment: production
Namespace: smap
Domain: smap-api.tantai.dev
Database: production-postgres
Features: High availability, Monitoring
```

#### 7.3.3. Secrets Management
**Kubernetes Secrets:**
```yaml
# Database Secrets
apiVersion: v1
kind: Secret
metadata:
  name: database-secrets
  namespace: smap
type: Opaque
data:
  postgres-identity-url: <base64-encoded>
  postgres-project-url: <base64-encoded>
  mongodb-collector-url: <base64-encoded>
  redis-url: <base64-encoded>

# Application Secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: smap
type: Opaque
data:
  jwt-secret: <base64-encoded>
  rabbitmq-url: <base64-encoded>
  minio-access-key: <base64-encoded>
  minio-secret-key: <base64-encoded>
```

### 7.4. Triển khai Frontend (Web-UI Service)

#### 7.4.1. Next.js Production Build
**Build Configuration:**
```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    outputFileTracingRoot: path.join(__dirname, '../../'),
  },
  env: {
    NEXT_PUBLIC_HOSTNAME: process.env.NEXT_PUBLIC_HOSTNAME,
    NEXT_PUBLIC_WS_URL: process.env.NEXT_PUBLIC_WS_URL,
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_HOSTNAME}/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
```

**Production Build Process:**
```bash
# Build optimization
npm run build
npm run start --port 5000

# Environment variables
NEXT_PUBLIC_HOSTNAME=https://smap-api.tantai.dev
NEXT_PUBLIC_WS_URL=wss://smap-api.tantai.dev/ws
NODE_ENV=production
PORT=5000
```

#### 7.4.2. Kubernetes Deployment
**Frontend Deployment:**
```yaml
# k8s/web-ui/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smap-web-ui
  namespace: smap
spec:
  replicas: 3
  selector:
    matchLabels:
      app: smap-web-ui
  template:
    metadata:
      labels:
        app: smap-web-ui
    spec:
      containers:
      - name: web-ui
        image: registry.tantai.dev/smap/smap-web-ui:latest
        ports:
        - containerPort: 5000
        env:
        - name: NODE_ENV
          value: "production"
        - name: NEXT_PUBLIC_HOSTNAME
          value: "https://smap-api.tantai.dev"
        - name: NEXT_PUBLIC_WS_URL
          value: "wss://smap-api.tantai.dev/ws"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 7.4.3. CDN và Static Assets
**Static Asset Optimization:**
- **Image Optimization**: Next.js Image component với lazy loading
- **Bundle Splitting**: Automatic code splitting
- **Caching Strategy**: Browser caching với proper headers
- **Compression**: Gzip/Brotli compression

### 7.5. Triển khai Backend Services

#### 7.5.1. Go Services Deployment
**Identity Service Example:**
```yaml
# k8s/identity/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smap-identity-api
  namespace: smap
spec:
  replicas: 3
  selector:
    matchLabels:
      app: smap-identity-api
  template:
    metadata:
      labels:
        app: smap-identity-api
    spec:
      containers:
      - name: identity-api
        image: registry.tantai.dev/smap/smap-identity:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: postgres-identity-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        - name: RABBITMQ_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: rabbitmq-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Service Configuration:**
```yaml
# k8s/identity/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: smap-identity-api
  namespace: smap
spec:
  selector:
    app: smap-identity-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

#### 7.5.2. Python Services Deployment
**Analytics Service (API + Consumer):**
```yaml
# k8s/analytics/deployment-api.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smap-analytics-api
  namespace: smap
spec:
  replicas: 2
  selector:
    matchLabels:
      app: smap-analytics-api
  template:
    metadata:
      labels:
        app: smap-analytics-api
    spec:
      containers:
      - name: analytics-api
        image: registry.tantai.dev/smap/smap-analytics-api:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: postgres-analytics-url
        - name: API_CORS_ORIGINS
          value: "https://smap-api.tantai.dev"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "1000m"

---
# k8s/analytics/deployment-consumer.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smap-analytics-consumer
  namespace: smap
spec:
  replicas: 2
  selector:
    matchLabels:
      app: smap-analytics-consumer
  template:
    metadata:
      labels:
        app: smap-analytics-consumer
    spec:
      containers:
      - name: analytics-consumer
        image: registry.tantai.dev/smap/smap-analytics-consumer:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: postgres-analytics-url
        - name: RABBITMQ_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: rabbitmq-url
        - name: MINIO_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: minio-access-key
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
```

#### 7.5.3. WebSocket Service Deployment
**Real-time Communication:**
```yaml
# k8s/websocket/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smap-websocket
  namespace: smap
spec:
  replicas: 3
  selector:
    matchLabels:
      app: smap-websocket
  template:
    metadata:
      labels:
        app: smap-websocket
    spec:
      containers:
      - name: websocket
        image: registry.tantai.dev/smap/smap-websocket:latest
        ports:
        - containerPort: 8081
        env:
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        - name: ENV
          value: "production"
        - name: CORS_ORIGINS
          value: "https://smap-api.tantai.dev"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

### 7.6. Database và Infrastructure Services

#### 7.6.1. PostgreSQL Deployment
**Multi-Database Setup:**
```yaml
# k8s/postgres/deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-identity
  namespace: smap
spec:
  serviceName: postgres-identity
  replicas: 1
  selector:
    matchLabels:
      app: postgres-identity
  template:
    metadata:
      labels:
        app: postgres-identity
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "identity"
        - name: POSTGRES_USER
          value: "smap_identity"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: identity-password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

#### 7.6.2. RabbitMQ Cluster
**Message Queue Infrastructure:**
```yaml
# k8s/rabbitmq/deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: smap
spec:
  serviceName: rabbitmq
  replicas: 3
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3.12-management-alpine
        ports:
        - containerPort: 5672
        - containerPort: 15672
        env:
        - name: RABBITMQ_DEFAULT_USER
          value: "smap"
        - name: RABBITMQ_DEFAULT_PASS
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secrets
              key: password
        - name: RABBITMQ_ERLANG_COOKIE
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secrets
              key: erlang-cookie
        volumeMounts:
        - name: rabbitmq-storage
          mountPath: /var/lib/rabbitmq
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

#### 7.6.3. Redis Deployment
**Caching và Pub/Sub:**
```yaml
# k8s/redis/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: smap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - --requirepass
        - $(REDIS_PASSWORD)
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secrets
              key: password
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### 7.7. HTTPS/SSL và Security

#### 7.7.1. TLS Certificate Management
**Let's Encrypt với cert-manager:**
```yaml
# k8s/cert-manager/certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: smap-api-tls
  namespace: smap
spec:
  secretName: smap-api-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - smap-api.tantai.dev
  - www.smap-api.tantai.dev
```

**Ingress TLS Configuration:**
```yaml
# k8s/ingress/tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: smap-ingress-tls
  namespace: smap
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - smap-api.tantai.dev
    secretName: smap-api-tls
  rules:
  - host: smap-api.tantai.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: smap-web-ui
            port:
              number: 80
```

#### 7.7.2. Security Policies
**Network Policies:**
```yaml
# k8s/security/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: smap-network-policy
  namespace: smap
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

**Pod Security Standards:**
```yaml
# k8s/security/pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: smap
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 7.8. Monitoring và Observability

#### 7.8.1. Prometheus Monitoring
**Metrics Collection:**
```yaml
# k8s/monitoring/prometheus.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: smap-services
  namespace: smap
spec:
  selector:
    matchLabels:
      monitoring: enabled
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

**Custom Metrics:**
```go
// Go services metrics
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
        },
        []string{"method", "endpoint"},
    )
)
```

#### 7.8.2. Logging Strategy
**Centralized Logging:**
```yaml
# k8s/logging/fluentd.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
```

**Structured Logging:**
```go
// Go services logging
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Info("Processing request",
    zap.String("service", "identity"),
    zap.String("method", "POST"),
    zap.String("endpoint", "/register"),
    zap.Duration("duration", time.Since(start)),
)
```

#### 7.8.3. Health Checks và Alerting
**Health Check Endpoints:**
```go
// Health check implementation
func healthHandler(c *gin.Context) {
    health := map[string]interface{}{
        "status": "healthy",
        "timestamp": time.Now().UTC(),
        "service": "identity",
        "version": os.Getenv("APP_VERSION"),
        "dependencies": map[string]string{
            "database": checkDatabase(),
            "rabbitmq": checkRabbitMQ(),
            "redis": checkRedis(),
        },
    }
    c.JSON(200, health)
}
```

**Alerting Rules:**
```yaml
# k8s/monitoring/alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: smap-alerts
  namespace: smap
spec:
  groups:
  - name: smap.rules
    rules:
    - alert: ServiceDown
      expr: up{job="smap-services"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "SMAP service is down"
        description: "{{ $labels.instance }} has been down for more than 1 minute"
        
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} for {{ $labels.service }}"
```

### 7.9. Backup và Disaster Recovery

#### 7.9.1. Database Backup Strategy
**Automated Backup:**
```yaml
# k8s/backup/postgres-backup.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: smap
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:15-alpine
            command:
            - /bin/bash
            - -c
            - |
              pg_dump $DATABASE_URL | gzip > /backup/backup-$(date +%Y%m%d-%H%M%S).sql.gz
              # Upload to S3/MinIO
              aws s3 cp /backup/backup-$(date +%Y%m%d-%H%M%S).sql.gz s3://smap-backups/postgres/
            env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-secrets
                  key: postgres-identity-url
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
```

#### 7.9.2. Application State Backup
**Configuration Backup:**
```bash
#!/bin/bash
# scripts/backup-k8s-config.sh

# Backup Kubernetes configurations
kubectl get all,configmaps,secrets,pv,pvc -n smap -o yaml > smap-k8s-backup-$(date +%Y%m%d).yaml

# Backup to remote storage
aws s3 cp smap-k8s-backup-$(date +%Y%m%d).yaml s3://smap-backups/k8s/

# Retention policy (keep last 30 days)
find /backup -name "smap-k8s-backup-*.yaml" -mtime +30 -delete
```

### 7.10. Rollback và Emergency Procedures

#### 7.10.1. Deployment Rollback
**Kubernetes Rollback:**
```bash
# Check rollout history
kubectl rollout history deployment/smap-identity-api -n smap

# Rollback to previous version
kubectl rollout undo deployment/smap-identity-api -n smap

# Rollback to specific revision
kubectl rollout undo deployment/smap-identity-api --to-revision=2 -n smap

# Check rollback status
kubectl rollout status deployment/smap-identity-api -n smap
```

**Automated Rollback Triggers:**
```yaml
# k8s/monitoring/rollback-alert.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: rollback-triggers
  namespace: smap
spec:
  groups:
  - name: rollback.rules
    rules:
    - alert: HighErrorRateAfterDeployment
      expr: |
        (
          rate(http_requests_total{status=~"5.."}[5m]) > 0.2
        ) and (
          increase(kube_deployment_status_replicas_updated[10m]) > 0
        )
      for: 2m
      labels:
        severity: critical
        action: rollback
      annotations:
        summary: "High error rate after deployment - consider rollback"
```

#### 7.10.2. Emergency Response Procedures
**Incident Response Playbook:**
```yaml
# Emergency Contacts
Primary On-Call: DevOps Team
Secondary: Backend Team  
Escalation: CTO

# Emergency Procedures
1. Service Down:
   - Check pod status: kubectl get pods -n smap
   - Check logs: kubectl logs -f deployment/service-name -n smap
   - Scale up replicas: kubectl scale deployment/service-name --replicas=5 -n smap
   
2. Database Issues:
   - Check connections: kubectl exec -it postgres-pod -- psql -c "SELECT count(*) FROM pg_stat_activity;"
   - Restart if needed: kubectl rollout restart statefulset/postgres-identity -n smap
   
3. High Load:
   - Enable HPA: kubectl autoscale deployment service-name --cpu-percent=70 --min=3 --max=10 -n smap
   - Check resource usage: kubectl top pods -n smap
   
4. Complete System Failure:
   - Activate DR site
   - Restore from latest backup
   - Update DNS to DR environment
```

### 7.11. Performance Optimization

#### 7.11.1. Horizontal Pod Autoscaler
**Auto-scaling Configuration:**
```yaml
# k8s/autoscaling/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: smap-identity-hpa
  namespace: smap
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: smap-identity-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

#### 7.11.2. Resource Optimization
**Resource Requests và Limits:**
```yaml
# Optimized resource allocation
resources:
  requests:
    memory: "128Mi"    # Minimum guaranteed
    cpu: "100m"        # 0.1 CPU core
  limits:
    memory: "256Mi"    # Maximum allowed
    cpu: "500m"        # 0.5 CPU core

# For AI/ML workloads (Analytics Consumer)
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### 7.12. Tổng kết Triển khai

#### 7.12.1. Deployment Summary
**Infrastructure Deployed:**
- **Kubernetes Cluster**: 10 nodes (3 master + 7 worker)
- **Services**: 7 microservices + 2 scrapers
- **Databases**: PostgreSQL (3 instances), MongoDB, Redis
- **Message Queue**: RabbitMQ cluster (3 nodes)
- **Storage**: MinIO object storage
- **Monitoring**: Prometheus + Grafana + ELK stack

**CI/CD Pipeline:**
- **Source Control**: GitHub với branch protection
- **Build**: GitHub Actions với multi-service detection
- **Registry**: Private Harbor registry
- **Deployment**: Automated Kubernetes deployment
- **Environments**: Development → Staging → Production

**Security Measures:**
- **TLS/SSL**: Let's Encrypt certificates với auto-renewal
- **Network Security**: Kubernetes Network Policies
- **Secrets Management**: Kubernetes Secrets với encryption at rest
- **RBAC**: Role-based access control
- **Container Security**: Non-root containers, security contexts

#### 7.12.2. Operational Status
**System Health:**
- **Uptime Target**: 99.9% availability
- **Response Time**: < 200ms for API calls
- **Throughput**: 1000+ requests/second
- **Scalability**: Auto-scaling từ 2-10 replicas per service

**Monitoring Coverage:**
- **Application Metrics**: Custom business metrics
- **Infrastructure Metrics**: CPU, memory, disk, network
- **Log Aggregation**: Centralized logging với ELK
- **Alerting**: 24/7 monitoring với PagerDuty integration

#### 7.12.3. Remaining Challenges và Future Improvements
**Current Limitations:**
1. **Single Region**: Chưa có multi-region deployment
2. **Manual Scaling**: Một số services chưa có auto-scaling
3. **Backup Testing**: Chưa có automated disaster recovery testing
4. **Cost Optimization**: Cần optimize resource usage

**Planned Improvements:**
1. **Multi-Region Deployment**: Active-passive setup
2. **Service Mesh**: Istio implementation cho advanced traffic management
3. **GitOps**: ArgoCD cho declarative deployment
4. **Chaos Engineering**: Chaos Monkey cho resilience testing
5. **Cost Management**: Resource optimization và spot instances

**Risk Mitigation:**
- **Single Point of Failure**: Load balancers và database clustering
- **Data Loss**: Automated backups với point-in-time recovery
- **Security Breaches**: Regular security audits và penetration testing
- **Performance Degradation**: Proactive monitoring và auto-scaling

---

*Chương 7 sẽ được viết dựa trên kế hoạch này, với screenshots thực tế từ Kubernetes dashboard, monitoring systems, và deployment pipelines.*