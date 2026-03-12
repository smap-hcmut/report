# Local E2E Rules

## Scripts
- `python test/login_identity_token_helper.py`
- `python test/happy_path_e2e.py`
- `python test/negative_edge_suite.py`

Compatibility entrypoint:
- `python test/e2e_identity_project_ingest.py`
  - This now forwards to `happy_path_e2e.py`.

## Token Flow
- Login is still done through `identity-srv`.
- The helper script opens the local identity login page and waits for either:
  - a raw JWT token, or
  - the full JSON callback body returned by identity.
- The helper extracts `data.token` when JSON is pasted.
- The token is saved to `test/.e2e_identity_token.json`.

## Default Local URLs
- Identity: `http://localhost:8082`
- Project: `http://localhost:8081`
- Ingest: `http://localhost:8080`

## Optional Overrides
- `IDENTITY_BASE_URL`
- `PROJECT_BASE_URL`
- `INGEST_BASE_URL`
- `JWT_SECRET_KEY`

## Suite Intent
- `happy_path_e2e.py`
  - Stable smoke runner.
  - Uses the real identity token from `.e2e_identity_token.json`.
  - Runs the create chain:
    - identity `/authentication/me`
    - campaign
    - project
    - crisis-config
    - datasource
    - keyword target
    - profile target
    - post target
  - Cleans all created data in `finally`.

- `negative_edge_suite.py`
  - Validation and bug-hunt suite.
  - Uses mixed tokens:
    - real token from identity for integration cases
    - synthetic missing / malformed / invalid-signature / expired tokens for auth edge cases
  - Groups coverage by:
    - auth
    - campaign
    - project
    - crisis-config
    - datasource
    - targets
  - Continues after failures to surface more bugs in one run.

## Fail-Only Artifacts
- Artifacts are written only for failed negative-suite cases.
- Output directory:
  - `test/artifacts/<timestamp>_negative_edge_suite/`
- Each failure artifact contains:
  - case id and name
  - request method / URL / payload
  - expected status
  - actual status
  - response body

## Validation / Edge Cases Covered
- Auth:
  - no token
  - malformed token
  - invalid signature
  - expired token
  - valid identity token on project and ingest
- Campaign:
  - missing / empty name
  - invalid RFC3339 dates
  - invalid date range
  - invalid status update
  - invalid UUID / not-found detail probes
- Project:
  - missing entity fields
  - invalid entity_type
  - invalid status update
  - invalid UUID detail
  - create under archived campaign probe
- Crisis config:
  - keywords-only valid upsert
  - multi-trigger valid upsert
  - empty body
  - invalid keyword / volume / sentiment / influencer shapes
  - get-after-delete probe
- Datasource:
  - missing required fields
  - invalid source_type / source_category / crawl_mode
  - invalid crawl interval
  - create under archived project probe
- Targets:
  - missing / empty values
  - invalid URL values for profiles / posts
  - invalid list filter
  - invalid update interval
  - delete twice
  - create under archived datasource probe

## Cleanup Rules
- Targets are deleted before datasource archive.
- Datasources are archived before project archive.
- Crisis config delete is attempted before project archive.
- Projects are archived before campaign archive.
- Cleanup runs even if the suite fails midway.

## Run Order
1. Refresh token if needed:
   - `python test/login_identity_token_helper.py`
2. Run smoke:
   - `python test/happy_path_e2e.py`
3. Run negative / edge suite:
   - `python test/negative_edge_suite.py`

## Notes
- `negative_edge_suite.py` intentionally includes some lifecycle and not-found probes that may expose current bugs.
- If a probe fails, treat the artifact output as the source of truth for follow-up investigation.
