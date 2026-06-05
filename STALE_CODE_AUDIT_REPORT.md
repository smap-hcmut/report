# SMAP stale-code audit report

Date: 2026-06-05
Workspace: `/Users/ts.1126/Workspaces/smap`

## Scope audited

Audited repositories/code areas:

- `identity-srv`
- `project-srv`
- `ingest-srv`
- `knowledge-srv`
- `notification-srv`
- `analysis-srv`
- `scapper-srv`
- `shared-libs/go`
- `shared-libs/integration-tests`
- `shared-libs/python`
- `web-ui`
- `smap-deploy`
- `report`

## Main cleanup completed

### Go services

- Removed unused config/connect helpers, stale Kafka/Redis/MinIO/Postgres/Qdrant accessors, dead helpers, unused model methods, dead Kafka consumer/producer packages, and stale report-generation helpers across Go services.
- Regenerated missing `identity-srv/docs` because `cmd/server` imports Swagger docs and Docker/Makefile expect them.
- Fixed `project-srv` project lifecycle guard so project activation/resume cannot bypass inactive parent campaign state.
- Fixed `shared-libs/go/minio` typed-nil error bug by changing MinIO error helper to return `error`, not `*StorageError`.
- Repaired `shared-libs/go/vendor` so default vendor-mode `go test ./...` works.
- Fixed `shared-libs/integration-tests` module path so tests target local `../go`, not remote `github.com/smap-hcmut/shared-libs/go`.
- Removed unused Go code in `smap-deploy` portal and Discord bot.

### Python services/scripts

- Removed unused imports, dead local assignments, invalid notebook-style `analysis-srv/scripts/phobert_onnx.py`, and callback/protocol false-positive names.
- Cleaned Python benchmark/report scripts under `report` and `smap-deploy/nfr/scripts`.
- Verified Python syntax with `compileall`, excluding virtualenv/cache folders.

### Frontend and UI test code

- Removed unused `web-ui` components, dead frontend dependency `framer-motion`, stale hook exports, unused mutation hooks, unused type exports, unused imports/state/helpers, and stale barrel exports.
- Added `web-ui/knip.json` so Electron source entries and build scripts are correctly recognized by dead-code tooling.
- Cleaned `smap-deploy/ui-test` TypeScript config and Playwright test DOM access.

## Validation evidence

Passed:

- `identity-srv`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `project-srv`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `ingest-srv`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `notification-srv`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `knowledge-srv`: `go test ./...`, `deadcode ./...`
- `shared-libs/go`: `go test ./...`, `staticcheck ./...`
- `shared-libs/integration-tests`: `go test ./...`, `staticcheck ./...`
- `analysis-srv`: `ruff F401/F841/F821`, `vulture --min-confidence 90`, `compileall`
- `scapper-srv`: `ruff F401/F841/F821`, `vulture --min-confidence 90`, `compileall`
- `shared-libs/python`: `ruff F401/F841/F821`, `vulture --min-confidence 90`, `compileall`
- `web-ui`: `tsc --noEmit`, `tsc -p electron/tsconfig.json --noEmit`, `tsc --noUnusedLocals --noUnusedParameters`, `knip`
- `web-ui` JS scripts: `node --check`
- `report/benchmark/k6/smap_api_smoke.js`: module syntax check
- `smap-deploy/portal`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `smap-deploy/devops/discord-bot`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `smap-deploy/devops/logging/log-viewer`: `go test ./...`, `staticcheck ./...`, `deadcode ./...`
- `smap-deploy/nfr/scripts`: `ruff F401/F841/F821`, `vulture --min-confidence 90`, `compileall`
- `smap-deploy/ui-test`: `tsc --noEmit`
- `report`: `ruff F401/F841/F821`, `vulture --min-confidence 90`, `compileall`

Known residual non-stale technical debt:

- `knowledge-srv/staticcheck` still reports SA1019 deprecations in Qdrant/gRPC integration:
  - `pkg/qdrant/interface.go`: `grpc.Dial` deprecated
  - `pkg/qdrant/qdrant.go`: deprecated `v.Data` field usage
- These are dependency/API migration warnings, not stale/unreachable code findings. `knowledge-srv` still passes tests and `deadcode`.

## Deployment status

Source code has been changed only in the workspace. No build, image push, deploy, or cluster rollout was performed in this audit.
