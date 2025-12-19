## ADDED Requirements

### Requirement: Service Package Management Standardization

All Python services SHALL use the `uv` package manager exclusively for dependency management and application execution, ensuring consistent build processes and faster dependency resolution.

#### Scenario: TikTok service uses uv

- **WHEN** building or running the TikTok service
- **THEN** only `uv` commands are used (no pip commands in Dockerfile or scripts)
- **AND** pyproject.toml and uv.lock files are present and up-to-date

#### Scenario: YouTube service uses uv

- **WHEN** building or running the YouTube service  
- **THEN** only `uv` commands are used (no pip commands in Dockerfile or scripts)
- **AND** pyproject.toml and uv.lock files are present and up-to-date

#### Scenario: FFmpeg service uses uv

- **WHEN** building or running the FFmpeg service
- **THEN** only `uv` commands are used (no pip commands in Dockerfile or scripts)
- **AND** pyproject.toml and uv.lock files are present and up-to-date

#### Scenario: Playwright service uses uv

- **WHEN** building or running the Playwright service
- **THEN** only `uv` commands are used (no pip commands in Dockerfile or scripts)  
- **AND** pyproject.toml and uv.lock files are present and up-to-date

### Requirement: Configuration Management Consistency

Each service SHALL have a complete configuration management system with config.py that loads all required environment variables and a corresponding env.template file that documents all configuration options.

#### Scenario: TikTok configuration completeness

- **WHEN** reviewing TikTok service configuration
- **THEN** config.py loads all environment variables used by the service
- **AND** .env.example file contains all required variables with descriptions
- **AND** no configuration is loaded outside of the config system

#### Scenario: YouTube configuration completeness

- **WHEN** reviewing YouTube service configuration  
- **THEN** config.py loads all environment variables used by the service
- **AND** .env.example file contains all required variables with descriptions
- **AND** no configuration is loaded outside of the config system

#### Scenario: FFmpeg configuration completeness

- **WHEN** reviewing FFmpeg service configuration
- **THEN** config.py loads all environment variables used by the service
- **AND** .env.example file contains all required variables with descriptions  
- **AND** no configuration is loaded outside of the config system

#### Scenario: Playwright configuration completeness

- **WHEN** reviewing Playwright service configuration
- **THEN** config.py loads all environment variables used by the service
- **AND** .env.example file contains all required variables with descriptions
- **AND** no configuration is loaded outside of the config system

### Requirement: Production-Ready Docker Configuration

Each service SHALL have a production-optimized Dockerfile that uses multi-stage builds, proper layer caching, and follows security best practices.

#### Scenario: Docker build optimization

- **WHEN** building any service Docker image
- **THEN** the build uses multi-stage approach with uv for dependency installation
- **AND** only necessary runtime files are included in final image
- **AND** proper layer caching is implemented for faster rebuilds

#### Scenario: Docker security practices

- **WHEN** running service containers
- **THEN** containers run with non-root user
- **AND** minimal base images are used
- **AND** no unnecessary packages or files are included

### Requirement: Comprehensive Kubernetes Manifests

Each service SHALL have complete Kubernetes manifest files that define all necessary resources with proper configuration, resource limits, health checks, and service discovery.

#### Scenario: TikTok K8s manifests

- **WHEN** deploying TikTok service to Kubernetes
- **THEN** deployment.yaml defines proper resource limits and health checks
- **AND** service.yaml exposes necessary ports for inter-service communication
- **AND** configmap.yaml contains all configuration with placeholder values for environment-specific settings

#### Scenario: YouTube K8s manifests

- **WHEN** deploying YouTube service to Kubernetes
- **THEN** deployment.yaml defines proper resource limits and health checks
- **AND** service.yaml exposes necessary ports for inter-service communication  
- **AND** configmap.yaml contains all configuration with placeholder values for environment-specific settings

#### Scenario: FFmpeg K8s manifests

- **WHEN** deploying FFmpeg service to Kubernetes
- **THEN** deployment.yaml defines proper resource limits and health checks
- **AND** service.yaml exposes port 8000 for HTTP API access
- **AND** configmap.yaml contains all configuration with placeholder values for environment-specific settings

#### Scenario: Playwright K8s manifests

- **WHEN** deploying Playwright service to Kubernetes  
- **THEN** deployment.yaml defines proper resource limits and health checks
- **AND** service.yaml exposes ports 4444 (WebSocket) and 8001 (HTTP API)
- **AND** configmap.yaml contains all configuration with placeholder values for environment-specific settings

### Requirement: Deployment Documentation Accuracy

The deployment documentation SHALL accurately reflect the current state of all services and provide complete information for K8s deployment.

#### Scenario: Documentation reflects current configuration

- **WHEN** reading scrapper/document/deployment_crawler.md
- **THEN** all service configurations match actual implementation
- **AND** all environment variables are documented with correct names and purposes  
- **AND** service dependencies are accurately described
- **AND** any incorrect or outdated information is removed or corrected