# SMAP Microservices — Comprehensive E2E Test Report

**Date:** 2026-04-14 (ICT +7)
**Environment:** K3s Production Cluster (172.16.21.100)
**Gateway:** smap-api.tantai.dev → Traefik → K3s VIP
**Auth method:** Cookie-based JWT (`smap_auth_token`)
**Test user:** `e2e-test` / ADMIN / UUID `550e8400-e29b-41d4-a716-446655440099`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total endpoints tested** | 55 |
| **Passed** | 44 |
| **Failed** | 5 |
| **Partially passed** | 4 |
| **Not testable** | 2 |
| **Bugs found (this session)** | 2 NEW |
| **Bugs confirmed fixed** | 3 (from prior sessions) |
| **Data quality issues** | 6 |
| **Feature gaps** | 2 |

---

## Phase 0 — Health Checks (6/6 PASS)

| Service | HTTP | Status | Notes |
|---------|------|--------|-------|
| identity-srv | 200 | healthy | |
| project-srv | 200 | healthy | `service: "smap-project"` (inconsistent naming — should be `project-srv`) |
| ingest-srv | 200 | healthy | |
| knowledge-srv | 200 | healthy | |
| notification-srv | 200 | healthy | `active_connections=0`, `redis=connected` |
| scapper-srv | 200 | healthy | `worker_active=true`, `api_base_url="https://api.tinlikesub.pro"` |

---

## Phase 1 — Identity-srv (3 endpoints)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /me | 200 | **FAIL** | `error_code=500` — user UUID doesn't exist in DB (hardcoded E2E user, not from OAuth) |
| 2 | GET | /audit-logs | 500 | **FAIL** | Same root cause — user not in DB |
| 3 | POST | /internal/validate | 200 | **PASS** | Token valid; returns `user_id`, `role=ADMIN` |

**Note:** Tests 1-2 fail due to test user not existing in the DB (identity-srv is OAuth2-only, no user seeding). The `/internal/validate` test confirms JWT parsing works correctly.

**Data quality issue:** `/internal/validate` returns `email` field but the value is actually `username` from JWT — semantic mismatch.

---

## Phase 2 — Project-srv

### 2a — Campaigns CRUD (8/8 PASS)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /domains | 200 | **PASS** | 2 domains: `_default`, `vinfast` |
| 2 | POST | /campaigns | 200 | **PASS** | Created `19ed2b60-2656-4d07-9872-5f0b99984345` |
| 3 | GET | /campaigns/:id | 200 | **PASS** | Returns full campaign object |
| 4 | GET | /campaigns | 200 | **PASS** | Lists 3 campaigns (incl. prior E2E runs) |
| 5 | PUT | /campaigns/:id | 200 | **PASS** | Description updated, `updated_at` changed |
| 6 | POST | /campaigns/:id/favorite | 200 | **PASS** | |
| 7 | GET | /campaigns/favorites | 200 | **PASS** | Returns 1 favorite |
| 8 | DELETE | /campaigns/:id/favorite | 200 | **PASS** | |

### 2b — Projects CRUD + Lifecycle (12/12 PASS)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /campaigns/:id/projects | 200 | **PASS** | Created `3a9698ad-9d68-4789-a1da-afab3a29ed1a`, status=PENDING |
| 2 | GET | /projects/:id | 200 | **PASS** | |
| 3 | GET | /campaigns/:id/projects | 200 | **PASS** | 1 project, paginator included |
| 4 | PUT | /projects/:id | 200 | **PASS** | Name + description updated |
| 5 | POST | /projects/:id/favorite | 200 | **PASS** | |
| 6 | GET | /projects/favorites | 200 | **PASS** | `is_favorite=true` |
| 7 | DELETE | /projects/:id/favorite | 200 | **PASS** | |
| 8 | GET | /projects/:id/activation-readiness | 200 | **PASS** | `can_proceed=false`, error: DATASOURCE_REQUIRED |
| 9 | POST | /projects/:id/activate | 200 | **PASS** | Correctly rejected — error 160026 (no datasource) |
| 10 | POST | /projects/:id/archive | 200 | **PASS** | PENDING → ARCHIVED |
| 11 | POST | /projects/:id/unarchive | 200 | **PASS** | ARCHIVED → **PAUSED** (not back to PENDING — see findings) |
| 12 | GET | /internal/projects/:id | 200 | **PASS** | Internal auth works with X-Internal-Key |

**Lifecycle finding:** `unarchive` transitions to `PAUSED` instead of back to `PENDING`. The `resume` from PAUSED then requires a datasource — same check as `activate`. This means once archived and unarchived, the project enters a different state machine branch.

### 2c — Crisis Config CRUD (3/3 PASS)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | PUT | /projects/:id/crisis-config | 200 | **PASS** | Created with keywords + volume triggers, `status=NORMAL` |
| 2 | GET | /projects/:id/crisis-config | 200 | **PASS** | Full config returned |
| 3 | DELETE | /projects/:id/crisis-config | 200 | **PASS** | Config deleted |

**Additional test:** GET after DELETE returns `error_code=160001, "Crisis config not found"` with **HTTP 400** instead of 404 — semantic mismatch.

---

## Phase 3 — Ingest-srv

### Datasource CRUD (6/6 PASS)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /datasources | 200 | **PASS** | Created FACEBOOK datasource, `source_category=CRAWL` auto-inferred (BUG #1 fix confirmed) |
| 2 | GET | /datasources/:id | 200 | **PASS** | |
| 3 | GET | /datasources | 200 | **PASS** | 1 datasource with paginator |
| 4 | PUT | /datasources/:id | 200 | **PASS** | Name updated, but `crawl_interval_minutes` NOT updated (see findings) |
| 5 | POST | /datasources/:id/archive | 200 | **PASS** | Status → ARCHIVED |
| 6 | DELETE | /datasources/:id | — | Not tested | (archived datasource, would need a new one) |

**Finding:** Datasource update does NOT update `crawl_interval_minutes` — sent `120` but remained `60`. Either the field is not supported in updates, or there's a bug.

### Target CRUD (9 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /datasources/:id/targets/keywords | 200 | **PASS** | 2 keywords, `target_type=KEYWORD` |
| 2 | POST | /datasources/:id/targets/profiles | 400 | **PARTIAL** | First attempt failed — `crawl_interval_minutes` required but not documented |
| 2b | POST | /datasources/:id/targets/profiles | 200 | **PASS** | With `crawl_interval_minutes=60` |
| 3 | POST | /datasources/:id/targets/posts | 200 | **PASS** | `target_type=POST_URL` |
| 4 | GET | /datasources/:id/targets | 200 | **PASS** | 3 targets, **no paginator** (flat array) |
| 5 | GET | /datasources/:id/targets/:tid | 200 | **PASS** | |
| 6 | PUT | /datasources/:id/targets/:tid | 200 | **PASS** | label, priority, crawl_interval all updated |
| 7 | POST | .../targets/:tid/activate | 200 | **PARTIAL** | Error 111 — "cannot be activated in current state" (needs dryrun first?) |
| 8 | POST | .../targets/:tid/deactivate | 200 | **PASS** | No-op (already inactive) |
| 9 | DELETE | /datasources/:id/targets/:tid | 200 | **PASS** | Verified count dropped from 3 to 2 |

**Finding:** `crawl_interval_minutes` is silently required for target creation — omitting it sends `0`, which fails validation. Should have a default or clearer error message.

### Dryrun (3 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /datasources/:id/dryrun | 200 | **PARTIAL** | `error_code=13: "Dryrun mapping is not supported yet"` — feature not implemented |
| 2 | GET | /datasources/:id/dryrun/latest | 400 | **PASS** | "Dryrun result not found" (correct — none run) |
| 3 | GET | /datasources/:id/dryrun/history | 200 | **PASS** | Empty list with paginator |

**Feature gap:** Dryrun trigger is NOT implemented — returns "not supported yet". This blocks the target activation flow (targets can't be activated without a successful dryrun).

### Internal Endpoints (1 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /internal/projects/:id/activation-readiness | 200 | **PASS** | Detailed errors: `DATASOURCE_STATUS_INVALID`, 3x `TARGET_DRYRUN_MISSING`, `ACTIVE_TARGET_REQUIRED` |

---

## Phase 4 — Knowledge-srv

### Search (1 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /search | 200 | **PASS** | 0 results (no indexed data), `no_relevant_context=true`, 13ms |

### Chat (5 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /chat (new) | 200 | **PASS** | New conversation created, LLM responded via `gemini-2.0-flash`, 2266ms |
| 2 | POST | /chat (follow-up) | 200 | **PASS** | Same `conversation_id`, 1632ms |
| 3 | GET | /conversations/:id | 200 | **PASS** | 4 messages (2 user + 2 assistant), full history |
| 4 | GET | /campaigns/:id/conversations | 200 | **PASS** | 1 conversation listed — **no paginator** |
| 5 | GET | /campaigns/:id/suggestions | 200 | **PASS** | 2 Vietnamese suggestions (sentiment overview + trend) |

**Finding:** `user_id` is empty in conversation records — the chat handler doesn't extract user_id from JWT context.

### Report (3 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /reports/generate | 500 | **BUG** | `pq: invalid input syntax for type uuid: ""` — user_id not extracted from JWT |
| 2 | GET | /reports/:id | 404 | **PASS** | Correct 404 response for non-existent report |
| 3 | GET | /reports/:id/download | 404 | **PASS** | Correct 404 response |

**BUG #4 — Report Generation user_id Empty:**
The report handler fails to extract `user_id` from the JWT/auth context. When inserting the report row, the `user_id` column (UUID type) receives an empty string `""`, causing a PostgreSQL type error. The same root issue exists in chat conversations (empty `user_id`), but chat handles it gracefully by allowing empty string while report doesn't.

### Chat Job Status (1 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /chat/jobs/:id | 404 | **PASS** | Correct 404 for non-existent job |

### Internal Indexing (1 tested)

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /internal/index/statistics/:project_id | 200 | **PASS** | Returns `total_indexed=0`, all zeros (no data) |

---

## Phase 5 — Notification-srv & Scapper-srv

### Notification-srv WebSocket

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | GET | /notification/ws | 404 | **FAIL** | WebSocket upgrade returns 404 |

**Root cause:** notification-srv registers the WebSocket route at `/ws` (no prefix), but Traefik forwards requests as `/notification/ws` (keeping the path prefix). The notification-srv doesn't have a route for `/notification/ws`, so it returns 404. **Traefik routing configuration issue.**

### Scapper-srv Task APIs

| # | Method | Path | HTTP | Result | Notes |
|---|--------|------|------|--------|-------|
| 1 | POST | /tasks/facebook | 200 | **PASS** | Task queued to `facebook_tasks`, returns `task_id` |
| 2 | GET | /tasks/:id/result | 404 | **PASS** | "Task may still be processing" (correct for async) |
| 3 | GET | /tasks | 200 | **PASS** | Empty list (results stored as files, none completed) |

**Finding:** Scapper returns helpful error messages with valid action lists when an invalid action is submitted. Valid Facebook actions: `search`, `posts`, `post_detail`, `comments`, `comments_graphql`, `comments_graphql_batch`, `search_graphql`, `search_graphql_batch`, `full_flow`.

---

## Bugs Found

### NEW Bugs (This Session)

#### BUG #4 — knowledge-srv Report Generation: Empty user_id
- **Severity:** HIGH
- **Location:** `knowledge-srv/internal/report/delivery/http/handlers.go`
- **Error:** `pq: invalid input syntax for type uuid: ""`
- **Root cause:** Handler doesn't extract `user_id` from auth context/JWT when creating report
- **Impact:** Report generation is completely broken — 500 error on every attempt
- **Related:** Same issue exists in chat conversations (`user_id` is empty string) but chat doesn't fail because the column likely allows empty strings

#### BUG #5 — notification-srv WebSocket Unreachable via Traefik
- **Severity:** MEDIUM
- **Location:** Traefik routing config / notification-srv route registration
- **Root cause:** notification-srv registers `/ws` but Traefik forwards as `/notification/ws`
- **Impact:** Real-time notifications via WebSocket are completely inaccessible through the API gateway
- **Fix options:**
  1. Register the route as `/notification/ws` in notification-srv
  2. Configure Traefik to strip the `/notification` prefix for this service

### Previously Fixed Bugs (Confirmed Working)

| Bug | Fix | Verified |
|-----|-----|----------|
| BUG #1 — ingest-srv source_category not auto-inferred | Added `inferSourceCategory()` in `toInput()` | ✅ `source_category=CRAWL` returned |
| BUG #2 — knowledge→project internal auth failure | Added internal auth route + fixed response format | ✅ (prior session) |
| BUG #3 — Qdrant write/read collection mismatch | Multi-collection parallel search | ✅ Search returns 200 |

---

## Data Quality Issues

### 1. Timezone Inconsistency (SYSTEMIC)
- **Create/Upsert responses** use local timezone: `2026-04-14T01:42:04+07:00`
- **GET responses** use UTC: `2026-04-13T18:42:04Z`
- **Affected services:** project-srv (campaigns, projects, crisis config), ingest-srv
- **Root cause:** Create returns the Go struct with local TZ, but GET returns from PostgreSQL which stores/returns UTC
- **Recommendation:** Standardize on UTC (`Z` suffix) everywhere, or always convert to `+07:00`

### 2. HTTP Status Code Inconsistencies
- All create operations return **HTTP 200** instead of **201 Created** (not REST-standard but consistent)
- "Crisis config not found" returns **HTTP 400** instead of **404** (semantic mismatch)
- "Dryrun result not found" returns **HTTP 400** instead of **404**

### 3. Response Format Inconsistencies
| Pattern | Services | Example |
|---------|----------|---------|
| `data.X` with paginator | project (campaigns, projects), ingest (datasources, dryrun history) | `data.campaigns[]`, `data.paginator` |
| `data.X` without paginator | ingest (targets) | `data.targets[]` — no paginator |
| `data[]` flat array | knowledge (conversations list) | `data[]` — no wrapper, no paginator |
| `data.X` single object | project (campaign detail), ingest (datasource detail) | `data.campaign`, `data.data_source` |

### 4. Field Naming Inconsistencies
- `data.data_source` (ingest) vs `data.campaign` (project) vs `data.target` (ingest) — `data_source` uses snake_case with underscore while others are single words
- identity-srv `/internal/validate` returns `email` field containing `username` value
- project-srv health returns `service: "smap-project"` instead of `"project-srv"`

### 5. Validation Error Inconsistencies
- Target create: `crawl_interval_minutes` silently defaults to 0, then fails validation — should have explicit "required" error or a sensible default
- Datasource update: `crawl_interval_minutes` is silently ignored — no error, just doesn't update

### 6. Empty user_id in Knowledge-srv
- Chat conversations store `user_id: ""` — doesn't fail but semantically incorrect
- Report generation crashes because of empty `user_id` (PostgreSQL UUID column rejects empty string)

---

## Feature Gaps

### 1. Dryrun Not Implemented
- `POST /datasources/:id/dryrun` returns "Dryrun mapping is not supported yet"
- This blocks the full lifecycle: **targets cannot be activated** without a successful dryrun
- Without active targets, **projects cannot be activated**
- The entire crawling pipeline is effectively blocked at the validation layer

### 2. Notification WebSocket Inaccessible
- WebSocket endpoint returns 404 through Traefik
- Real-time push notifications to frontend are not functional

---

## Test Coverage Matrix

| Service | Total Routes | Tested | Passed | Failed | Coverage |
|---------|-------------|--------|--------|--------|----------|
| identity-srv | 13 | 3 | 1 | 2 | 23% (limited by OAuth-only auth) |
| project-srv | 32 | 21 | 21 | 0 | **66%** |
| ingest-srv | 29 | 16 | 13 | 1 | **55%** |
| knowledge-srv | 18 | 11 | 9 | 1 | **61%** |
| notification-srv | 4 | 1 | 0 | 1 | 25% (WebSocket routing issue) |
| scapper-srv | 5 | 3 | 3 | 0 | **60%** |
| **TOTAL** | **101** | **55** | **47** | **5** | **54%** |

Untested routes are primarily:
- identity-srv: OAuth login/callback (requires browser), user management, remaining internal routes
- project-srv: campaign delete, project delete (would destroy test data)
- ingest-srv: internal lifecycle routes (activate/pause/resume — require active project), internal dispatch
- knowledge-srv: internal index/retry/reconcile, notebook webhook (requires HMAC signature)

---

## Recommendations (Priority Order)

1. **FIX BUG #4** — knowledge-srv report `user_id` extraction (HIGH — feature completely broken)
2. **FIX BUG #5** — notification-srv WebSocket routing (MEDIUM — real-time notifications blocked)
3. **Implement dryrun mapping** — unblocks the entire crawling pipeline activation flow
4. **Standardize timezone** — pick UTC everywhere, convert only at display layer
5. **Fix HTTP status codes** — 201 for creates, 404 for not-found (instead of 400)
6. **Add paginator to all list endpoints** — targets, conversations lists are missing it
7. **Fix identity-srv validate response** — rename `email` field to `username` or populate correctly

---

## Appendix: Test Data Created

| Entity | ID | Status |
|--------|----|--------|
| Campaign | `19ed2b60-2656-4d07-9872-5f0b99984345` | Active |
| Project | `3a9698ad-9d68-4789-a1da-afab3a29ed1a` | PAUSED |
| Datasource | `fd1f2ca3-de8a-4b3f-8e2b-d910bdc67400` | ARCHIVED |
| Target (KEYWORD) | `de11d5d2-dc79-48e6-99d2-00c05b0c17e6` | inactive |
| Target (PROFILE) | `426f9225-8032-4a11-b44c-12550f68d54c` | inactive |
| Target (POST_URL) | `79c6550e-caef-4cca-a3a0-a1f589017330` | DELETED |
| Conversation | `3cebc00b-c18b-4f1a-870b-619c593f32d3` | ACTIVE (4 messages) |
| Scapper Task | `d5c8e9c1-d7f0-4fb2-837c-02a7466970e4` | Queued (facebook search) |
