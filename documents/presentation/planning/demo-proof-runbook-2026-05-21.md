# SMAP Demo + Proof Runbook - Defense 2026-05-21

Mục tiêu: demo đủ chức năng ở mức người dùng và có proof vận hành thật. Không cố chạy job dài hoặc fake crisis trên production nếu chưa có người trực hệ thống.

## 1. Preflight 10 phút trước khi trình bày

Chạy các lệnh này từ `/Users/tantai/Workspaces/smap`.

```bash
rtk curl -sS -o /tmp/smap_ui_status.txt -w '%{http_code} %{time_total}\n' https://smap.tantai.dev
rtk curl -sS -o /tmp/smap_analysis_health.json -w '%{http_code} %{time_total}\n' https://smap-api.tantai.dev/analytics/health
rtk curl -sS https://smap-api.tantai.dev/notification/health
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
```

Kết quả live check lúc audit:

- UI `https://smap.tantai.dev`: HTTP 200, ~0.219s.
- Analytics health: HTTP 200, ~0.190s, payload `{"status":"ok"}`.
- Notification health: HTTP 200, `redis:"connected"`, service `healthy`.
- Pods chính: analysis-api, analysis-consumer, identity-srv, ingest-srv, knowledge-srv, notification-srv, project-srv, rabbitmq, redis, redpanda, scapper-srv, smap-ui đều `Running`.
- Browser screenshot live UI đã lưu: `/Users/tantai/Workspaces/smap/report/documents/presentation/demo-proof/smap-live-ui-2026-05-21.png`.

Lưu ý thật từ audit: Redis vừa restart/load quanh 15:55 nên logs cũ có transient errors `connection refused` và `Redis is loading the dataset in memory`. Health hiện tại đã `redis: connected`. Trước demo notification/crisis, kiểm lại health/log để tránh bị hỏi đúng lúc log transient.

## 2. Setup màn hình demo

Mở sẵn 4 cửa sổ/tab:

1. Browser live UI: `https://smap.tantai.dev`.
2. Terminal 1: K8s proof.
3. Terminal 2 hoặc K9s: log proof.
4. Discord channel nhận SMAP alert, nếu team có quyền xem channel.

Khuyến nghị layout:

- Màn hình chính: Canva + browser UI.
- Màn phụ: terminal/K9s/Discord.

## 3. Kịch bản demo chính 3-5 phút

### Step 1 - Live UI dashboard

Action:

- Mở `https://smap.tantai.dev`.
- Chọn campaign/project đang có dữ liệu, ví dụ đang thấy trên UI: `Ahamove - Nửa Đầu 2026`.
- Show các KPI/cards: total mentions, sentiment score, engagement, audience reach.
- Show map/projects bubble và conversation drivers.

Nói:

> Đây là live UI của hệ thống, dữ liệu được hiển thị theo campaign/project. Người dùng có thể xem tổng quan mentions, sentiment, engagement và các conversation drivers theo scope đã chọn.

Proof:

- UI hiển thị `LIVE`.
- Screenshot audit: `/Users/tantai/Workspaces/smap/report/documents/presentation/demo-proof/smap-live-ui-2026-05-21.png`.
- Curl UI trả 200.

### Step 2 - Project / lifecycle / settings

Action:

- Click `Projects` hoặc khu vực project cards.
- Nếu có project card/settings: show status, datasource, crisis config hoặc lifecycle action.
- Không bấm mutation nguy hiểm nếu chưa chuẩn bị data.

Nói:

> Phần này tương ứng control plane. Project không chỉ là dữ liệu dashboard; project-srv giữ lifecycle, còn ingest-srv giữ readiness/runtime. Khi activate, hệ thống phải kiểm tra readiness trước khi chuyển ACTIVE.

Proof code:

- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:12`.
- `/Users/tantai/Workspaces/smap/project-srv/internal/project/usecase/lifecycle.go:246`.

### Step 3 - Insights / filters

Action:

- Click `Insights` nếu route ổn.
- Show filters/sources/sentiment/posts/keywords.
- Nếu Insights route chậm, quay lại MAP dashboard và show conversation drivers.

Nói:

> Dashboard không đọc raw payload trực tiếp. Dữ liệu đã được analysis-consumer chuẩn hóa và ghi vào `analysis.post_insight`/latest insight mart, sau đó API trả cho UI theo project/campaign.

Proof:

- `/Users/tantai/Workspaces/smap/analysis-srv/migration/init_db.sql:1`.
- `/Users/tantai/Workspaces/smap/analysis-srv/migration/007_latest_post_insight_mart.sql:1`.

### Step 4 - Report / chat / knowledge

Action:

- Click `Reports`.
- Nếu report list/generate có sẵn, show report.
- Nếu có chat UI, hỏi câu ngắn: `Tóm tắt sentiment chính của campaign này`.

Nói:

> Knowledge lane tách khỏi dashboard. Dữ liệu analytics được index vào Qdrant để phục vụ search/chat/report có grounding theo project. Nếu vector index chưa sẵn sàng, knowledge-srv còn có analytics fallback để trả lời từ snapshot dữ liệu.

Proof:

- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/indexing/usecase/index_batch.go:17`.
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/chat/usecase/analytics_fallback.go:18`.
- `/Users/tantai/Workspaces/smap/knowledge-srv/internal/report/delivery/http/handlers.go:12`.

### Step 5 - Notification / WebSocket / Discord

Action an toàn:

- Click notification bell trên UI để show notification surface nếu có.
- Mở health:

```bash
rtk curl -sS https://smap-api.tantai.dev/notification/health
```

- Mở logs:

```bash
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=50 --all-containers
```

- Mở Discord channel nhận alert nếu team có quyền.

Nói:

> Notification-srv là delivery layer: Kafka analytics digest/crisis alert được bridge sang Redis channel, rồi Redis subscriber route sang WebSocket. Discord không phải mọi notification; code hiện dispatch Discord cho crisis critical và `ops_alert=true`.

Proof:

- Health hiện tại báo `redis:"connected"`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/analyticsbridge/bridge.go:274`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:100`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/websocket/usecase/new.go:112`.
- `/Users/tantai/Workspaces/smap/notification-srv/internal/alert/usecase/dispatch_crisis.go:13`.

Không làm khi chưa thống nhất:

- Không publish fake crisis alert vào production chỉ để Discord hiện message, vì có thể tạo cảnh báo giả và làm nhiễu audit/log.
- Nếu cần live Discord proof, dùng một project/test payload đã chuẩn bị và thông báo rõ đây là test alert.

### Step 6 - K9s / Kubernetes proof

Action:

```bash
/opt/homebrew/bin/k9s --context homelab -n smap
```

Trong K9s:

1. Chọn namespace `smap`.
2. Mở Pods.
3. Show các pod chính `1/1 Running`, `analysis-consumer 2/2`.
4. Gõ `/notification-srv` rồi `l` để xem logs.
5. Gõ `/analysis-consumer` rồi `l` để xem logs.
6. Nếu muốn proof infra, show `rabbitmq-0`, `redis-0`, `redpanda-0`.

Nói:

> Đây là runtime thật trên K3s, không phải mock local. Các service chính đang chạy trong namespace `smap`; khi cần debug, nhóm có thể mở logs theo service để trace từ API đến queue/consumer.

Fallback nếu K9s không mở:

```bash
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
rtk kubectl --context homelab -n smap logs deploy/analysis-consumer --tail=40 --all-containers
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=40 --all-containers
```

## 4. Demo proof theo từng capability

| Capability | Demo surface | Proof surface | Nếu live fail |
|---|---|---|---|
| Live deployment | Browser UI | curl 200 + K8s pods | dùng screenshot audit |
| Campaign/project scope | UI campaign dropdown/project cards | project-srv lifecycle code | chỉ nói flow + evidence |
| Dashboard analytics | MAP/Insights | analysis health + post_insight schema | use existing MAP dashboard |
| Ingestion runtime | Không trigger live job dài | ingest scheduler + RabbitMQ/scapper code/log | explain from sequence + K8s pods |
| Knowledge report/chat | Reports/chat UI | knowledge indexing/report handlers | show code/evidence + fallback |
| Notification/WebSocket | Bell/health/log | notification health redis connected | không fake crisis nếu chưa chuẩn bị |
| Discord alert | Discord channel history | code gate critical ops alert + secret configured | show as backup, not main demo |
| Ops observability | K9s/logs | kubectl get pods/logs | use terminal commands |
| Benchmark | NFR slide | benchmark report raw evidence | open report file |

## 5. Lệnh proof nhanh để copy

```bash
rtk curl -sS -o /tmp/smap_ui_status.txt -w 'UI %{http_code} %{time_total}\n' https://smap.tantai.dev
rtk curl -sS -o /tmp/smap_analysis_health.json -w 'ANALYTICS %{http_code} %{time_total}\n' https://smap-api.tantai.dev/analytics/health
rtk curl -sS https://smap-api.tantai.dev/notification/health
rtk kubectl --context homelab -n smap get pods
rtk kubectl --context homelab -n smap get deploy
rtk kubectl --context homelab -n smap logs deploy/notification-srv --tail=40 --all-containers
rtk kubectl --context homelab -n smap logs deploy/analysis-consumer --tail=40 --all-containers
```

## 6. Câu xử lý khi demo lỗi

Nếu UI chậm:

> Live domain đang có response 200, nhưng browser có thể chậm do network phòng bảo vệ. Nhóm đã chuẩn bị screenshot evidence và sẽ chuyển sang proof bằng health/K8s/log để không mất thời gian.

Nếu notification không hiện:

> Notification là near-real-time sau analytics digest/crisis alert, không phải button click tạo event ngay lập tức. Health hiện báo Redis connected; em sẽ chứng minh bằng health/log/code path, còn live event phụ thuộc cadence analytics.

Nếu Discord không có message mới:

> Discord chỉ nhận critical crisis ops alert, không phải mọi notification. Nhóm không gửi fake production alert trong buổi bảo vệ nếu chưa thống nhất, nhưng có thể mở channel history và code path để chứng minh integration.

Nếu K9s bị lỗi context:

> K9s dùng context homelab; fallback là `kubectl --context homelab -n smap get pods` và logs trực tiếp.

