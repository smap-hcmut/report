# Diagram Audit Report

Updated: 2026-04-15

## Scope

Audit doi chieu bo `.puml` trong `report_SMAP/documents/phong_tmp/new-report/diagrams` voi current implementation trong workspace `SMAP/`.

## Result Summary

- da audit lai cac lane chinh: authentication, project lifecycle, crawl completion, analytics pipeline, knowledge chat, notification websocket
- da fix cac mismatch lon ve WebSocket auth handling, dryrun completion response, project repository wording, execution/UAP runtime wording
- da chot `freeze set` tai `freeze_set_for_final_report.md`

## Fixed During Audit

1. WebSocket route khong con bi ve nhu di qua `mw.Auth()` chung.
2. Dryrun sequence khong con imply consumer tra ket qua truc tiep cho user.
3. WebSocket connection diagram khong con imply `project_id` la filter runtime da enforce.
4. Project repository diagram khong con gop campaign CRUD vao project repo.
5. Ingest execution/UAP diagrams da noi ro UAP parsing thuoc consumer runtime khi parser duoc wire.
6. Crawl completion dataflow khong con overclaim local storage la success path hien tai cua execution completion.

## Current Residual Caveats

1. Chua render syntax bang `plantuml` vi moi truong hien tai chua co binary `plantuml`.
2. Mot so component diagram la service-level view, nen gom ca HTTP runtime va consumer runtime trong cung service boundary; khi viet caption cho report can ghi ro day la `service current-state view`, khong phai `single process diagram`.
3. Notification websocket handshake co nhan `project_id` trong request DTO, nhung current routing van user-based; khong nen viet caption theo huong project-scoped subscription da hoan chinh.

## Ready Status

- `authentication/`: ready with caveat ve websocket auth xu ly trong handler
- `activity/`: ready
- `component/`: ready
- `data-flow/`: ready
- `realtime/`: ready
- `sequence/`: ready

## Recommendation

- dung `freeze_set_for_final_report.md` lam bo chot de render
- sau khi render PNG/SVG, chi can mot vong QA cuoi ve caption va numbering truoc khi nhung vao `final-report`
