# Change: Prepare All Services for K8s Deployment

## Why

All 4 services (TikTok, YouTube, FFmpeg, Playwright) have completed core development and testing. Now they need to be prepared for production K8s deployment by ensuring standardized configuration, build processes, and deployment manifests are in place.

## What Changes

- Verify all services use `uv` command for build/run (no more pip)
- Sync and verify all config loading across services (config.py and env.template)
- Refactor/update Dockerfiles for production readiness
- Create comprehensive K8s manifests for each service with proper configuration
- Update deployment documentation in `scrapper/document/deployment_crawler.md`

## Impact

- Affected specs: deployment (new capability)
- Affected code: All 4 services (tiktok/, youtube/, ffmpeg/, playwight/)
- Affected files: Dockerfiles, config.py, .env.example files, K8s manifests
- Documentation: deployment_crawler.md