# Design: K8s Deployment Preparation

## Context

SMAP AI Internal crawler services have completed core development with 4 services:
- **tiktok**: TikTok scraper worker (depends on Playwright service)
- **youtube**: YouTube scraper worker (depends on FFmpeg service)  
- **ffmpeg**: Media conversion service (FastAPI)
- **playwight**: Browser automation service (FastAPI)

All services need production-ready K8s deployment configuration with standardized build processes, configuration management, and proper manifest files.

## Goals / Non-Goals

**Goals:**
- Standardize all services to use `uv` package manager
- Ensure all configuration is properly loaded and documented
- Production-ready Dockerfiles with optimal layer caching
- Comprehensive K8s manifests with proper resource limits, health checks, etc.
- Updated and accurate deployment documentation

**Non-Goals:**
- Actual K8s deployment (that's next phase)
- Code changes to service logic
- Infrastructure setup (RabbitMQ, MongoDB, MinIO)

## Decisions

### Package Manager
- **Decision**: Use `uv` exclusively for all Python services
- **Rationale**: Faster builds, better dependency resolution, already adopted
- **Migration**: Remove any remaining pip usage in Dockerfiles

### Configuration Management
- **Decision**: Each service has complete config.py + env.template pair
- **Rationale**: Clear configuration contract, easy K8s ConfigMap generation
- **Implementation**: Verify all environment variables are properly loaded

### Docker Strategy  
- **Decision**: Multi-stage builds with uv for dependency installation
- **Rationale**: Smaller images, better layer caching, security
- **Pattern**: Use uv sync in build stage, copy only runtime files

### K8s Manifest Strategy
- **Decision**: Comprehensive manifests per service with detailed configuration
- **Rationale**: Production readiness, proper resource management
- **Structure**: deployment.yaml, service.yaml, configmap.yaml per service
- **Placeholders**: Use placeholder values for external IPs/hosts that vary by environment

## Risks / Trade-offs

- **Risk**: Configuration drift between services
  - **Mitigation**: Standardized config.py pattern, validation during build
- **Risk**: K8s manifests become outdated
  - **Mitigation**: Keep manifests close to service code, update documentation

## Migration Plan

1. **Verification Phase**: Check current state of each service
2. **Standardization Phase**: Apply consistent patterns across all services  
3. **Manifest Phase**: Create K8s manifests with proper configuration
4. **Documentation Phase**: Update deployment guide with accurate information

## Open Questions

- Should we include resource limits/requests in manifests or leave for deployment time? ==> Yes, based on estimated performance test and resource usage.
- How should we handle secrets (API keys, credentials) in K8s manifests? ==> Use Kubernetes secrets.
- Should we create a base template for common K8s configuration? ==> Yes, create a base template for common K8s configuration.