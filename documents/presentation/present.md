# SMAP Defense Master Runbook — 2026-05-21

File này là **source of truth duy nhất** cho buổi defend. Gộp toàn bộ: kịch bản quay video pre-record + kịch bản live demo + script thuyết minh + preflight + checklist + fallback. Không tham chiếu file khác.

Cấu trúc buổi defend:

- **Part A — Pre-record video** (~9-11 phút, 3 segment): quay sẵn lifecycle setup + crawl pipeline + analytics. Chiếu trong slide, đứng cạnh thuyết minh.
- **Part B — Live demo** (~3-5 phút, 4 step): thao tác trực tiếp trên prod, **chỉ existing data** (campaign `Ahamove - Nửa Đầu 2026`), không mutation, không fake crisis.

Triết lý: lifecycle setup không thể live (target tạo xong `is_active=false`, dry-run + crawl + parse + NLP mất 5-15 phút) → đẩy hết vào video. Live chỉ phần fast + visual (dashboard, WS push, knowledge search, k8s proof).

Diagram chiếu kèm (`.svg` trong cùng folder `presentation/`):

- `flow_1a_campaign_project_setup_sequence.svg`
- `flow_1b_project_activation_sequence.svg`
- `flow_2_ingestion_and_uap_sequence.svg`
- `flow_3_analytics_knowledge_notification_sequence.svg`

---

# Section 1 — Preflight (10 phút trước defend)

Chạy từ `/Users/tantai/Workspaces/smap`:

```bash
rtk curl -sS -o /tmp/smap_ui_status.txt -w 'UI %{http_code} %{time_total}\n' https://smap.tantai.dev
rtk curl -sS -o /tmp/smap_analysis_health.json -w 'ANALYTICS %{http_code} %{time_total}\n' https://smap-api.tantai.dev/analytics/health
rtk curl -sS https://smap-api.tantai.dev/notification/health
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
```

Yêu cầu pass:

- UI HTTP 200, response < 1s.
- Analytics health HTTP 200, payload `{"status":"ok"}`.
- Notification health: `redis: connected`, service `healthy`.
- Pods Ready: `analysis-api`, `analysis-consumer 2/2`, `identity-srv`, `ingest-srv`, `knowledge-srv`, `notification-srv`, `project-srv`, `rabbitmq-0`, `redis-0`, `redpanda-0`, `scapper-srv`, `smap-ui`.

Audit result gần nhất (tham khảo): UI 200 ~0.219s, analytics 200 ~0.190s, notification `redis: connected`. Backup screenshot UI: `demo-proof/smap-live-ui-2026-05-21.png`.

**Lưu ý**: Redis từng restart 15:55, log cũ có transient `connection refused` + `Redis is loading the dataset in memory`. Trước demo notification cần kiểm log mới nhất xem transient đã hết.

---

# Section 2 — Pre-demo Checklist (30 phút trước defend)

**Hạ tầng**:

- [ ] `kubectl config current-context` = `homelab`.
- [ ] Tất cả pod ns `smap` Ready.
- [ ] Notification health `redis: connected`.
- [ ] Postgres còn data demo: `SELECT count(*) FROM analysis.post_insight;` ≥ 1000.
- [ ] Qdrant collection knowledge ≥ 100 vector.
- [ ] Token user demo (`tai.nguyentantai21042004@hcmut.edu.vn`) còn hạn ≥ 4h.

**Video**:

- [ ] A0/A1/A2 đã render MP4 1080p + sub tiếng Việt.
- [ ] Copy USB dự phòng + Google Drive link.
- [ ] Test play trên máy presentation (codec/audio level).
- [ ] Slide deck nhúng `.svg` (KHÔNG nhúng `.puml`).

**Live tabs** (mở sẵn theo Section 5):

- [ ] Browser tab 1: UI Ahamove logged-in.
- [ ] Browser tab 2: DevTools mở Network + WS panel.
- [ ] Terminal 1: K9s sẵn sàng gõ.
- [ ] Terminal 2: `kubectl logs` notification-srv tail.
- [ ] Terminal 3: kubectl backup commands chuẩn bị.
- [ ] Discord channel SMAP alert (nếu có quyền).
- [ ] Postman collection backup (token đã save).

**Phòng**:

- [ ] Test HDMI + projector trước giờ.
- [ ] Volume video test cuối phòng.
- [ ] Pin laptop > 80% hoặc cắm sạc.
- [ ] Hotspot điện thoại bật sẵn (Wi-Fi phòng defend không ổn định).

---

# Section 3 — Suggested Opening (~30 giây)

> "Em chia kiến trúc runtime SMAP thành 4 sequence diagram, tương ứng vòng đời dữ liệu: setup → activation → ingestion → analytics + delivery."
>
> "Phần lifecycle setup và crawl pipeline em pre-record video vì chạy lâu và cần mutation production; phần dashboard + WebSocket + knowledge + ops proof em demo trực tiếp trên prod."
>
> "Toàn bộ diagram được vẽ ngược từ handler, usecase, broker config và consumer thực tế trong code, không phải sơ đồ thiết kế ban đầu."

---

# Section 4 — Part A: Pre-record Video

## Video A0 — Lifecycle Setup (~3 phút) | flow_1a + flow_1b

**Diagram chiếu trong video**: `flow_1a` cảnh 1-4, chuyển sang `flow_1b` cảnh 5-8.

**Mục tiêu nói**: tách boundary `project-srv` (business) và `ingest-srv` (execution); activation là lifecycle có readiness check chéo service.

**Tiền điều kiện**:

- Login UI bằng user demo, token còn hạn ≥ 4h.
- DevTools tab Network mở sẵn để show internal call.
- Terminal psql connect prod (`172.16.19.10:5432/smap`).
- Sandbox campaign name `Defense Demo - 2026-05-21` (tránh đụng Ahamove prod).
- 1 project khác đã tạo trước **chưa** dry-run, dùng cho nhánh blocked.

### Cảnh 1 — Tạo campaign (~25s)

Thao tác:

1. UI → menu `Campaigns` → `Create Campaign`.
2. Điền: name `Defense Demo - 2026-05-21`, description, date range.
3. Submit. Show toast success.
4. Terminal psql: `SELECT id, name, created_at FROM project.campaigns ORDER BY created_at DESC LIMIT 1;` → row mới.

Voice-over: "Người dùng tạo campaign trước. `project-srv` chỉ chạm bảng `campaigns`, không liên quan ingest."

### Cảnh 2 — Tạo project dưới campaign (~30s)

Thao tác:

1. Vào campaign vừa tạo → tab `Projects` → `Add Project`.
2. Điền name + chọn `domain_type=ECOMMERCE`.
3. Submit.
4. DevTools Network: highlight `POST /campaigns/{id}/projects` 200.
5. psql: `SELECT id, campaign_id, domain_type, status FROM project.projects ORDER BY created_at DESC LIMIT 1;` → `status=DRAFT`.

Voice-over: "`project-srv` validate campaign + domain type rồi insert. Tới đây mới chỉ là metadata, chưa có gì chạy."

Proof code: `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:12`.

### Cảnh 3 — Cấu hình datasource (~25s)

Thao tác:

1. UI chuyển module `Ingest` → `Data Sources` → `Add Data Source`.
2. Chọn platform, `crawl_mode=SCHEDULED`, `crawl_interval_minutes=60`.
3. Submit. DevTools: `POST /datasources` 200.
4. psql: `SELECT id, project_id, platform, crawl_mode, crawl_interval_minutes FROM ingest.data_sources ORDER BY created_at DESC LIMIT 1;`

Voice-over: "Schedule không phải API riêng, nó là field `crawl_mode` + `crawl_interval_minutes` ngay trong datasource. Cấu hình thu thập tách sang `ingest-srv`."

### Cảnh 4 — Tạo target keyword (~25s)

Thao tác:

1. Vào datasource → `Targets` → `Add Keyword Target`.
2. Điền keyword `ahamove`, `crawl_interval_minutes=120`. Submit.
3. psql: `SELECT id, target_type, keyword, is_active, crawl_interval_minutes FROM ingest.crawl_targets ORDER BY created_at DESC LIMIT 1;` → `is_active=false`.
4. **Highlight `is_active=false`** trên màn hình.

Voice-over: "Target tạo với `is_active=false`. Nếu datasource cần dry-run, target phải kích hoạt riêng qua `/activate` trước. Đây là `opt` block trên diagram."

### Cảnh 5 — Cut sang diagram flow_1b (~5s)

Cut slide diagram `flow_1b_project_activation_sequence.svg`.

Voice-over: "Tiếp theo, khi người dùng activate project, hệ thống không chuyển ACTIVE ngay."

### Cảnh 6 — Activate project nhánh passed (~40s)

Thao tác:

1. UI vào project → nút `Activate`.
2. DevTools: `POST /projects/{project_id}/activate`.
3. Terminal log: `rtk kubectl --context homelab -n smap logs -f deploy/project-srv --tail=30` → thấy log gọi `GET /internal/projects/{project_id}/activation-readiness?command=activate`.
4. Terminal 2: `rtk kubectl --context homelab -n smap logs -f deploy/ingest-srv --tail=30` → thấy `ListDataSources`, `ListCrawlTargets`, `GetLatestDryrunByTarget`.
5. Response readiness `can_proceed=true`.
6. project-srv call tiếp `POST /internal/projects/{project_id}/activate` → ingest-srv chạy `UpdateProjectDataSourcesLifecycle`.
7. UI: project status `ACTIVE`. psql verify `SELECT status FROM project.projects WHERE id=...;`.

Voice-over: "`project-srv` không tự đổi trạng thái. Gọi `ingest-srv` check readiness. Pass thì activate datasource runtime trước, project-srv mới update status `ACTIVE`."

Proof code: `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:246`.

### Cảnh 7 — Activate project nhánh blocked (~25s)

Thao tác:

1. Mở project khác (đã chuẩn bị, chưa có dry-run).
2. Bấm `Activate` → response 4xx, UI toast lỗi.
3. DevTools: response body `can_proceed=false`, reason `dry-run required`.

Voice-over: "Đây là nhánh `alt Readiness blocked`. Business state và ingest runtime phải cùng sẵn sàng, không có half-active."

### Cảnh 8 — Câu chốt video A0 (~10s)

Slide `flow_1b` zoom hai box `project-srv` + `ingest-srv` với mũi tên qua lại.

Voice-over: "Boundary nghiệp vụ rõ. `project-srv` giữ business lifecycle, `ingest-srv` giữ execution readiness. Activation = sync 2 service qua internal API, không phải UPDATE đơn."

---

## Video A1 — Ingestion + UAP (~3-4 phút) | flow_2

**Diagram chiếu**: `flow_2_ingestion_and_uap_sequence.svg`.

**Mục tiêu nói**: crawl pipeline bất đồng bộ, RabbitMQ + MinIO, 2 nhánh completion, parser ghi UAP record xuống Kafka + parsed chunk ngược MinIO.

**Tiền điều kiện**:

- Target đã active từ video A0 (hoặc dùng target đang chạy sẵn).
- 4 terminal:
  - T1: `rtk kubectl --context homelab -n smap logs -f deploy/ingest-srv -c scheduler`
  - T2: `rtk kubectl --context homelab -n smap logs -f deploy/scapper-srv`
  - T3: `rtk kubectl --context homelab -n smap logs -f deploy/ingest-srv -c completion`
  - T4: psql connect prod.
- RabbitMQ Management UI port-forward `:15672`.
- MinIO console port-forward.
- Redpanda console port-forward.

### Cảnh 1 — Scheduler quét + dispatch (~40s)

Thao tác:

1. T1: chờ scheduler tick (hoặc rút ngắn `crawl_interval_minutes`). Show log:
   - `ListDueTargets(now=..., limit=...)`
   - `ClaimTarget(source_id, target_id, next_crawl_at)`
   - `DispatchDueTargets(... trigger_type=SCHEDULED)`
2. T4 psql: `SELECT id, target_id, trigger_type, created_at FROM ingest.scheduled_jobs ORDER BY created_at DESC LIMIT 3;`
3. psql: `SELECT id, scheduled_job_id, status FROM ingest.external_tasks ORDER BY created_at DESC LIMIT 5;` → `status=PUBLISHED`.
4. RabbitMQ UI: queue dispatch tăng message count.

Voice-over: "Scheduler quét target tới hạn, **claim trước khi dispatch** để tránh 2 scheduler instance double-fire. Mỗi dispatch sinh 1 scheduled_job, fan-out thành nhiều external_task, publish RabbitMQ."

### Cảnh 2 — Worker crawl + completion (~50s)

Thao tác:

1. T2 scapper log: worker pickup task, crawl URL, save artifact, publish completion.
2. MinIO console: refresh bucket `ingest-data` → file raw mới (object key có timestamp).
3. RabbitMQ UI: queue `ingest_task_completions` tăng message count.

Voice-over: "Worker `scapper-srv` consume task, crawl social network, lưu raw artifact MinIO. **Chỉ gửi completion envelope** về Rabbit, không gửi payload qua queue."

### Cảnh 3 — Completion consumer success branch (~50s)

Thao tác:

1. T3 completion log: consume completion, gọi `GetCompletionContext(task_id)`.
2. Log `Verify storage object` MinIO → OK.
3. Log `CompleteTaskSuccess`, insert `raw_batches`, mark external_task `COMPLETED`.
4. T4 psql: `SELECT id, external_task_id, storage_key, parsed_at FROM ingest.raw_batches ORDER BY created_at DESC LIMIT 1;` → `parsed_at=NULL`.
5. Log tiếp: `ParseAndStoreRawBatch(raw_batch_id=...)`.

Voice-over: "Completion consumer rẽ 2 nhánh. Nhánh success: verify object, ghi raw_batch, mark task completed, **rồi mới** gọi parser."

### Cảnh 4 — UAP parser (~40s)

Thao tác:

1. T3 log:
   - `ClaimRawBatchForParsing(raw_batch_id)` (chống race).
   - `Download raw artifact` MinIO.
   - Loop: `Publish smap.collector.output`.
   - `Upload parsed UAP chunk(s)` ngược MinIO.
   - `MarkRawBatchParsed`.
2. Redpanda console: topic `smap.collector.output` offset tăng.
3. MinIO: folder `parsed/` có chunk file mới.
4. psql: `SELECT id, parsed_at FROM ingest.raw_batches WHERE id=...;` → `parsed_at` đã set.

Voice-over: "Parser claim batch chống race, download artifact, parse từng record publish Kafka, upload parsed chunk làm artifact replay cho downstream, cuối cùng mark parsed."

### Cảnh 5 — Nhánh error (optional, ~25s)

Thao tác:

1. Force feed task fail (URL invalid hoặc rate limit).
2. T3 log: `CompleteTaskError`, mark external_task `FAILED`, không parse.
3. psql: `SELECT status, error_message FROM ingest.external_tasks WHERE id=...;`

Voice-over: "Nhánh error chỉ ghi failure, không tốn cycle parse. `external_tasks.status=FAILED`, retry policy do scheduler quyết."

### Cảnh 6 — Câu chốt video A1 (~10s)

Slide flow_2 zoom RabbitMQ + MinIO + Kafka.

Voice-over: "RabbitMQ + MinIO tách workload crawl khỏi ingest core. UAP record + parsed chunk tạo format thống nhất, replayable cho downstream analytics."

---

## Video A2 — Analytics + 4 topic + Crisis (~3 phút) | flow_3 phần consumer

**Diagram chiếu**: `flow_3_analytics_knowledge_notification_sequence.svg`, focus phần `Ingest → Stream → Analysis → AnalysisPG → Stream (4 topic)`. Phần WebSocket/Redis để live B3.

**Mục tiêu nói**: analysis-srv consume UAP, group theo `(project_id, domain_type_code)`, NLP, ghi `post_insight`, publish **4 topic** (3 luôn + 1 điều kiện crisis).

**Tiền điều kiện**:

- Video A1 đã produce UAP vào `smap.collector.output`.
- Batch input nhạy cảm (post tiêu cực mạnh + crisis keyword) chuẩn bị sẵn để trigger nhánh crisis.
- Terminal:
  - T1: `rtk kubectl --context homelab -n smap logs -f deploy/analysis-consumer`
  - T2: psql connect, query `analysis.post_insight`.
  - T3: Redpanda console mở danh sách topic `analytics.*`.

### Cảnh 1 — Consume + group + NLP (~50s)

Thao tác:

1. T1: log `Consume batch from smap.collector.output offset=...`.
2. Log `Grouped N records by (project_id, domain_type_code)`.
3. Log NLP pipeline: sentiment, aspect, intent, entity, crisis scoring.

Voice-over: "`analysis-srv` consume `smap.collector.output`, parse UAP, group theo `(project_id, domain_type_code)`, chạy NLP. Group key là cơ chế multi-tenant tách kết quả theo project và lĩnh vực."

### Cảnh 2 — Ghi post_insight (~30s)

Thao tác:

1. T2 psql: `SELECT id, project_id, domain_type_code, sentiment, crisis_score, created_at FROM analysis.post_insight ORDER BY created_at DESC LIMIT 5;`
2. Highlight 5 row mới, cột `crisis_score`.

Voice-over: "Mỗi NLP fact hợp lệ ghi 1 row vào `analysis.post_insight`. Đây là read model phục vụ dashboard, không phải raw."

Proof code: `analysis-srv/migration/init_db.sql:1`, `analysis-srv/migration/007_latest_post_insight_mart.sql:1`.

### Cảnh 3 — Publish 4 topic (~60s)

Thao tác:

1. T1 log theo thứ tự:
   - `Publish analytics.batch.completed` (luôn).
   - Loop từng insight: `Publish analytics.insights.published`.
   - `Publish analytics.report.digest` (luôn).
   - `[CONDITIONAL] crisis_level >= threshold → Publish analytics.crisis.alert`.
2. T3 Redpanda console: 4 topic `analytics.*` offset tăng. Show offset before/after.

Voice-over: "Output 3 topic mặc định + 1 topic điều kiện. `batch.completed` báo batch xong; `insights.published` cho từng card; `report.digest` cho notification. `crisis.alert` **chỉ publish khi** crisis level vượt threshold — cơ chế alert ops, không phải scheduled report."

### Cảnh 4 — Force trigger crisis (~30s)

Thao tác:

1. Replay batch input đã chuẩn bị (post tiêu cực mạnh) vào `smap.collector.output`.
2. T1 log: `crisis_level=critical, ops_alert=true`.
3. T3 Redpanda: topic `analytics.crisis.alert` có message mới.

Voice-over: "Khi feed batch nhạy cảm, pipeline tự trigger `analytics.crisis.alert`. Phần delivery WS sẽ demo live."

### Cảnh 5 — Câu chốt video A2 (~10s)

Voice-over: "Cùng 1 batch UAP sinh 3-4 topic độc lập. Mỗi consumer downstream (knowledge, notification, ops) đọc topic riêng, scale riêng, replay riêng. Không service nào share state với service khác."

---

# Section 5 — Part B: Live Demo

## Setup màn hình (làm xong trước khi vào phòng defend)

Layout:

- **Màn chính (projector)**: slide deck + browser UI.
- **Màn phụ (laptop)**: terminal + K9s + Discord.

7 cửa sổ/tab pre-mở:

1. Browser tab 1: `https://smap.tantai.dev` đã login user demo.
2. Browser tab 2: DevTools mở project Ahamove, panel Network + WS.
3. Terminal 1: K9s `/opt/homebrew/bin/k9s --context homelab -n smap` (chưa enter, để gõ live).
4. Terminal 2: `rtk kubectl --context homelab -n smap logs -f deploy/notification-srv --tail=20` chạy sẵn.
5. Terminal 3: kubectl backup commands chuẩn bị (xem Section 6).
6. Discord channel SMAP alert (nếu có quyền).
7. Slide deck mở slide `flow_3`.

## Live B1 — Dashboard tour Ahamove (~60s)

**Diagram chiếu**: slide flow_3 (vẫn để mở).

Thao tác:

1. Browser tab 1: campaign `Ahamove - Nửa Đầu 2026`.
2. Show KPI cards: total mentions, sentiment score, engagement, audience reach.
3. Scroll xuống map/projects bubble + conversation drivers.
4. Click `Insights` → show filters: sources, sentiment, posts, keywords.

Nói:

> "Đây là live UI trên domain prod, dữ liệu campaign Ahamove. Dashboard không đọc raw payload — `analysis-srv` đã chuẩn hóa và ghi vào `analysis.post_insight`, API trả theo project/campaign scope."

Proof code: `analysis-srv/migration/init_db.sql`, `analysis-srv/migration/007_latest_post_insight_mart.sql`.

Fallback nếu UI chậm: screenshot `demo-proof/smap-live-ui-2026-05-21.png` + curl 200.

## Live B2 — Knowledge / Report / Chat (~60s)

Thao tác:

1. Click menu `Reports`. Show report list campaign Ahamove.
2. Mở 1 report đã generate → show grounding citations.
3. Nếu có chat UI: gõ `Tóm tắt sentiment chính của campaign Ahamove`. Enter. Đợi response.

Nói:

> "Knowledge lane tách khỏi dashboard. `knowledge-srv` consume 3 topic `analytics.*` rồi index Qdrant. Search/chat/report đều RAG retrieval từ Qdrant. Nếu vector index chưa sẵn sàng, knowledge-srv còn analytics fallback đọc trực tiếp snapshot dữ liệu."

Proof code:

- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_batch.go:17`
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/chat/usecase/analytics_fallback.go:18`
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/report/delivery/http/handlers.go:12`

Fallback nếu chat chậm/timeout: chỉ show report list + nói flow + reference code.

## Live B3 — Notification + WebSocket (~60s)

**Diagram chiếu**: focus phần Bridge → Redis → WebSocket trên flow_3.

Thao tác:

1. Browser tab 2: DevTools panel WS. Filter `ws`. Connection `/ws?token=...` đã established.
2. Click chuông notification trên UI → show notification surface.
3. Terminal 2: scroll log notification-srv → show `Redis subscriber received: channel=system:analytics`, `WebSocket route message`.
4. Show frame WebSocket trên DevTools panel — payload digest analytics.
5. Mở Discord channel (nếu có) → show alert history (không gửi alert mới).

Nói:

> "Notification là delivery layer. Kafka analytics digest/crisis alert được bridge sang Redis channel theo pattern `system:*`, `project:*:user:*`, `campaign:*:user:*`, `alert:*:user:*`. Redis subscriber match pattern rồi route WebSocket. Multi-tenant per user nhờ channel pattern. Discord chỉ nhận crisis critical với `ops_alert=true`, không phải mọi notification."

Proof code:

- `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:274`
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:100`
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:112`
- `/Users/tantai/Workspaces/smap/notification-srv/internal/alert/usecase/dispatch_crisis.go:13`

**KHÔNG làm**:

- KHÔNG publish fake crisis alert vào prod (tạo cảnh báo giả, nhiễu audit/log).
- KHÔNG gửi test Discord message khi defend.
- Nếu hội đồng yêu cầu thấy crisis live → trả lời: "Đây là production stream, em không trigger fake event. Phần crisis trigger em đã quay video A2, có thể chiếu lại."

Fallback nếu WS không hiện frame:

```bash
rtk curl -sS https://smap-api.tantai.dev/notification/health
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=50 --all-containers
```

Nói: "Notification là near-real-time, phụ thuộc cadence analytics. Em chứng minh bằng health + log + code path."

## Live B4 — K9s / K8s proof (~60s)

Thao tác:

```bash
/opt/homebrew/bin/k9s --context homelab -n smap
```

Trong K9s:

1. Namespace `smap`, mở Pods.
2. Show pod chính Ready: `analysis-api`, `analysis-consumer 2/2`, `identity-srv`, `ingest-srv`, `knowledge-srv`, `notification-srv`, `project-srv`, `rabbitmq-0`, `redis-0`, `redpanda-0`, `scapper-srv`, `smap-ui`.
3. Gõ `/notification-srv` → `l` xem logs.
4. Esc, `/analysis-consumer` → `l` xem logs.
5. Esc, `/redpanda` → `l` cho infra proof.

Nói:

> "Đây là runtime thật trên K3s homelab cluster, không phải mock local. Tất cả service trong namespace `smap` Ready. Khi debug, team có thể trace log từ API → queue → consumer."

Fallback nếu K9s lỗi context:

```bash
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=40 --all-containers
rtk kubectl --context homelab -n smap logs deploy/analysis-consumer --tail=40 --all-containers
```

---

# Section 6 — Lệnh proof copy-paste

Health check tổ hợp:

```bash
rtk curl -sS -o /tmp/smap_ui_status.txt -w 'UI %{http_code} %{time_total}\n' https://smap.tantai.dev
rtk curl -sS -o /tmp/smap_analysis_health.json -w 'ANALYTICS %{http_code} %{time_total}\n' https://smap-api.tantai.dev/analytics/health
rtk curl -sS https://smap-api.tantai.dev/notification/health
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=40 --all-containers
rtk kubectl --context homelab -n smap logs deploy/analysis-consumer --tail=40 --all-containers
```

psql queries hay dùng:

```sql
-- Campaign + project mới (sau khi tạo)
SELECT id, name, created_at FROM project.campaigns ORDER BY created_at DESC LIMIT 1;
SELECT id, campaign_id, domain_type, status FROM project.projects ORDER BY created_at DESC LIMIT 1;

-- Datasource + target
SELECT id, project_id, platform, crawl_mode, crawl_interval_minutes FROM ingest.data_sources ORDER BY created_at DESC LIMIT 1;
SELECT id, target_type, keyword, is_active, crawl_interval_minutes FROM ingest.crawl_targets ORDER BY created_at DESC LIMIT 1;

-- Ingestion runtime
SELECT id, target_id, trigger_type, created_at FROM ingest.scheduled_jobs ORDER BY created_at DESC LIMIT 3;
SELECT id, scheduled_job_id, status FROM ingest.external_tasks ORDER BY created_at DESC LIMIT 5;
SELECT id, external_task_id, storage_key, parsed_at FROM ingest.raw_batches ORDER BY created_at DESC LIMIT 5;

-- Analytics
SELECT id, project_id, domain_type_code, sentiment, crisis_score, created_at FROM analysis.post_insight ORDER BY created_at DESC LIMIT 5;
SELECT count(*) FROM analysis.post_insight;
```

---

# Section 7 — Demo proof theo capability

| Capability | Live surface | Proof | Fallback nếu fail |
|---|---|---|---|
| Live deployment | Browser UI Ahamove | curl 200 + K8s pods | screenshot audit |
| Campaign/project lifecycle | (video A0) | code lifecycle.go | nói flow + code |
| Dashboard analytics | MAP/Insights existing | analytics health + post_insight | giữ MAP, không click Insights |
| Ingestion runtime | (video A1) | scheduler + Rabbit/scapper code/log | explain sequence + show pods |
| Knowledge report/chat | Reports/chat UI | indexing/report handler code | code + analytics fallback |
| Notification/WebSocket | bell/health/log/WS frame | notification health `redis: connected` | health + log + không fake crisis |
| Discord alert | Discord channel history | code gate critical + ops_alert | show channel history, không gửi mới |
| Ops observability | K9s/logs | kubectl get pods/logs | terminal commands |
| Benchmark | NFR slide | benchmark report file | mở report file |

---

# Section 8 — Câu xử lý khi demo lỗi

**UI chậm/lỗi**:

> "Live domain đang trả 200 (em vừa check curl), browser có thể chậm do network phòng. Em đã chuẩn bị screenshot evidence và sẽ chuyển sang proof bằng health/K8s/log."

**Notification không hiện WebSocket frame**:

> "Notification là near-real-time sau analytics digest/crisis alert, không phải button click sinh event. Health hiện báo Redis connected; em chứng minh bằng health/log/code path, còn live event phụ thuộc cadence analytics."

**Discord không có message mới**:

> "Discord chỉ nhận critical crisis ops alert, không phải mọi notification. Nhóm không gửi fake production alert khi defend, nhưng em mở channel history và code path để chứng minh integration."

**K9s lỗi context**:

> "K9s dùng context homelab; fallback là `kubectl --context homelab -n smap get pods` và logs trực tiếp." (gõ lệnh ngay).

**Pod chưa Ready / restart**:

> "Pod vừa restart (em check uptime). Service vẫn ready trong ms tới giây thông qua probe; em sẽ show pod khác cùng deployment để chứng minh redundancy."

**Hội đồng yêu cầu trigger crisis live**:

> "Đây là production stream phục vụ user thật, em không trigger fake crisis event. Phần crisis trigger em đã quay video A2 chi tiết, có thể chiếu lại để hội đồng thấy."

---

# Section 9 — Suggested Closing (~30 giây)

> "SMAP không phải pipeline đồng bộ. Trạng thái và trách nhiệm chia theo service nên scale từng phần, đòi hỏi control flow rõ ràng giữa database, broker, object storage và websocket delivery."
>
> "Bốn sequence diagram chính là bốn ranh giới giao tiếp — sửa feature mới chỉ cần xác định feature thuộc ranh giới nào, không phải đụng toàn hệ thống."

---

# Section 10 — Timing reference

| Phần | Thời lượng | Cộng dồn |
|---|---|---|
| Opening | 0:30 | 0:30 |
| Video A0 (lifecycle) | 3:00 | 3:30 |
| Video A1 (ingestion+UAP) | 3:30 | 7:00 |
| Video A2 (analytics+crisis) | 3:00 | 10:00 |
| Live B1 (dashboard) | 1:00 | 11:00 |
| Live B2 (knowledge) | 1:00 | 12:00 |
| Live B3 (notification+WS) | 1:00 | 13:00 |
| Live B4 (k9s) | 1:00 | 14:00 |
| Closing | 0:30 | 14:30 |
| Q&A buffer | — | ≥ 15 phút còn lại trong slot defend |

Nếu slot defend ngắn (< 15'): bỏ video A2 cảnh 5 (error branch optional), gộp B3 + B4. Nếu dài (> 20'): thêm 1 vòng Q&A giữa video và live.
