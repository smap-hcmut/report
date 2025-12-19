# TikTok Scraper Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the TikTok scraper service.

## Files

- `configmap.yaml` - Configuration settings for the TikTok scraper
- `secrets.yaml` - Sensitive configuration (credentials, API keys)
- `deployment.yaml` - Main deployment configuration
- `serviceaccount.yaml` - Service account and headless service
- `hpa.yaml` - Horizontal Pod Autoscaler for automatic scaling

## Deployment Instructions

### 1. Update Placeholders

Before deploying, update the following placeholders in the manifests:

**configmap.yaml:**
- `PLACEHOLDER_RABBITMQ_HOST` → Your RabbitMQ hostname/IP
- `PLACEHOLDER_MONGODB_HOST` → Your MongoDB hostname/IP  
- `PLACEHOLDER_MINIO_ENDPOINT` → Your MinIO endpoint (host:port)
- `PLACEHOLDER_STT_API_URL` → Your Speech-to-Text API URL

**secrets.yaml:**
- Set actual values for database and MinIO credentials

**deployment.yaml:**
- `PLACEHOLDER_CONFIG_HASH` → Generate hash of config for rolling updates
- Update image repository if needed: `registry.tantai.dev/smap/tiktok-scraper:latest`

### 2. Deploy to Kubernetes

```bash
# Create namespace if it doesn't exist
kubectl create namespace smap-crawler

# Apply manifests
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml
```

### 3. Verify Deployment

```bash
# Check deployment status
kubectl get deployments -n smap-crawler

# Check pods
kubectl get pods -n smap-crawler -l app=tiktok-scraper

# Check logs
kubectl logs -n smap-crawler -l app=tiktok-scraper -f

# Check HPA status
kubectl get hpa -n smap-crawler
```

## Resource Configuration

### Resource Limits
- **Requests**: 256Mi memory, 250m CPU
- **Limits**: 512Mi memory, 500m CPU

### Scaling
- **Min Replicas**: 2
- **Max Replicas**: 8
- **Scale up**: When CPU > 70% or memory > 80%
- **Scale down**: Gradual scaling based on resource utilization

### Dependencies
- Requires Playwright service to be running
- Requires RabbitMQ, MongoDB, and MinIO infrastructure
- Connects to Speech-to-Text API service

## Security Features

- Runs as non-root user (UID 1000)
- No privilege escalation
- Service account with minimal permissions
- Secrets management for sensitive data
- Network isolation through namespace