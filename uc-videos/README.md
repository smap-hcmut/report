# SMAP Use-case Demo Videos

Recorded 2026-06-06 against the live K3s `homelab/smap` cluster after the v3
minimization rollout. Each clip walks one use case end-to-end on
`https://smap.tantai.dev` with an injected ADMIN JWT (no manual login).

| UC | File | Title |
|---|---|---|
| UC-01 | `uc-01-campaign-setup.webm` | Thiết lập chiến dịch theo dõi (onboarding wizard) |
| UC-02 | `uc-02-campaign-ops.webm` | Vận hành chiến dịch (Projects tab lifecycle) |
| UC-03 | `uc-03-search-rag.webm` | Tra cứu + Campaign Assistant RAG chat |
| UC-04 | `uc-04-dashboard-alerts.webm` | Dashboard + Insights + Reports + bell |
| UC-05 | `uc-05-crisis-rules.webm` | Crisis rules + Signals ontology editor |

`*-thumb.png` files are PNG snapshots taken from each clip for quick preview.

## How it works

- `smap-deploy/ui-test/demos/auth-helper.ts` mints an HS256 JWT signed with the
  `JWT_SECRET_KEY` pulled from `smap-shared-secrets`. Payload claims:
  `user_id`, `sub`, `username/email`, `role=ADMIN`, `iss=smap-auth-service`,
  `aud=identity-srv`, plus the standard `iat/nbf/exp`.
- The JWT is dropped as the `smap_auth_token` HttpOnly cookie on `.tantai.dev`
  before navigation, so the SPA boots straight into the authenticated app.
- The E2E fixture user (`e2e-test@gmail.com`, role hash for ADMIN) is upserted
  into `identity.users` so the backend recognises the claim.
- Playwright Chromium runs headless at 1440×900 and records WebM via the
  bundled libvpx encoder.

## Re-run

```
cd smap-deploy/ui-test
npx ts-node demos/record-ucs.ts            # all five
npx ts-node demos/record-ucs.ts uc-03-search-rag   # one
```

Set `DEMO_CAMP_ID=<uuid>` to point UC-05 at a different campaign.

## Notes / caveats

- WebM only because the Playwright-bundled ffmpeg is stripped down to libvpx.
  Convert with system ffmpeg if MP4 is required:
  `ffmpeg -i in.webm -c:v libx264 -crf 23 -preset veryfast -movflags +faststart -an out.mp4`.
- UC-04 cycles through MAP / Projects / Insights / Stalker / Reports tabs but
  the notification bell selector is best-effort — the icon button has no stable
  text label.
- The onboarding wizard in UC-01 fills campaign basics and Start/End dates so
  the Continue button activates, but it deliberately stops short of provisioning
  a real datasource to avoid polluting the live cluster with throwaway crawl
  targets.
