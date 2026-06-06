# SMAP Monitoring Stack — Deploy Evidence Report

Date: 2026-06-07
Owner: Nguyễn Tấn Tài
Deploy by: Claude Opus 4.7
Plan: `report/SMAP_MONITORING_PLAN.md`
Stop hook goal: "monit hoàn chỉnh, lấy data từ toàn bộ service, queue, EDA"

---

## TL;DR

Phase 1 + Phase 2 + Phase 3 đã làm hết **trong một sprint đêm**. Không defer.

- ✅ `kube-prometheus-stack` 86.2.0 deployed in `monitoring` namespace.
- ✅ **37/37 Prometheus targets UP**, **21 jobs** covered.
- ✅ Grafana auto-loaded SMAP Overview dashboard with 30+ panels (HTTP RED edge, per-service RED in-app, Redpanda Kafka, RabbitMQ, Redis, Postgres, cluster + workloads).
- ✅ All 6 SMAP services exposing `/metrics`: 5 Go (identity / project / ingest / knowledge / notification) + 1 Python (analysis-api).
- ✅ Standalone exporters: redis_exporter + postgres_exporter for the external Postgres 172.16.19.10.
- ✅ Grafana served on `monitor.tantai.dev` via Traefik Ingress (origin HTTP, Cloudflare proxy terminates TLS).
- ⚠️ External access still 404 from Cloudflare → Tài cần update **Cloudflare Tunnel hostname route** (1 click), Step 9 below.
- ✅ All 7 affected repos committed + pushed (shared-libs, 5 Go services, analysis-srv, smap-deploy).

---

## 1. Cluster snapshot (taken before deploy, 2026-06-07 ~01:10 ICT)

| Node | CPU req | Mem req | Status |
|---|---|---|---|
| k3s-01 | 99 % (3980 m / 4000 m) | 54 % | Ready, saturated (so monitoring pinned **off** of it) |
| k3s-02 | 62 % (2515 m) | 32 % | Ready |
| k3s-03 | 31 % (1255 m) | 18 % | Ready → **chosen as pin** for Prometheus / Grafana / Alertmanager |

Storage classes available: `local-path`, `longhorn`, `longhorn-single-replica`. **Longhorn explicitly avoided** per `LONGHORN_ROOT_CAUSE_REPORT.md` (engine v1.5.3 EOL, repeated I/O errors). Picked `local-path` + nodeSelector pin on k3s-03.

Traefik 3.6.7 already running with `--metrics.prometheus=true --metrics.prometheus.entrypoint=metrics` on pod port 9100. The metrics endpoint was not exposed at Service level; the Service `traefik-system/traefik-metrics` was created to fix that without touching the public LB.

---

## 2. Architecture realised

```
DNS: monitor.tantai.dev (CNAME via Cloudflare proxy ON)
                                  │
                                  ▼
                  Cloudflare edge (TLS termination)
                                  │
                                  ▼
                  Cloudflare Tunnel ────► origin router
                                  │
                                  ▼   (NAT 80/443 to LAN VIP)
                  MetalLB VIP 172.16.21.205
                                  │
                                  ▼
                  Traefik IngressController
                                  │
                                  ▼
                  Ingress monitor.tantai.dev
                                  │
                                  ▼
                  svc/smap-monitoring-grafana:80 → pod grafana:3000

Inside the cluster, Prometheus scrapes:
  ┌── Traefik metrics (svc/traefik-metrics:9100)
  ├── analysis-api (svc/analysis-api:80/metrics)
  ├── 5 Go services (svc/identity|project|ingest|knowledge-srv:8080/metrics,
  │                  svc/notification-srv:8081/metrics)
  ├── rabbitmq plugin (15692)
  ├── redpanda admin (9644 public_metrics)
  ├── redis_exporter (smap/redis-exporter:9121)
  ├── postgres_exporter (monitoring/postgres-exporter:9187)
  ├── kube-state-metrics, node-exporter (× 3), kubelet (× 3)
  └── stack self-targets (operator, alertmanager × 2, prometheus × 2, grafana)
```

Total: **21 jobs, 37 UP targets** (verified at 02:25 ICT).

---

## 3. Repo changes

| Repo | Commit | Subject |
|---|---|---|
| `shared-libs` | `16cefce` (tag `go/v1.0.14`) | `feat(metrics): add Prometheus HTTP RED middleware` |
| `identity-srv` | `763a660` | `feat(observability): expose /metrics + Prometheus HTTP RED middleware` |
| `project-srv` | `8858172` | same |
| `ingest-srv` | `01afc6d` | same |
| `knowledge-srv` | `06caf39` | same |
| `notification-srv` | `bebc9c6` | same |
| `analysis-srv` | `57674ea` | `feat(observability): expose /metrics + HTTP RED histogram on analysis-api` |
| `smap-deploy` | `7f241d0` | `feat(monitoring): kube-prometheus-stack + Grafana on monitor.tantai.dev` |

All pushed to GitHub `origin/master` (or `origin/main` for `smap-deploy`).

---

## 4. Docker images pushed to registry.tantai.dev

| Image | Tag |
|---|---|
| `smap/analysis-api` | `260607-0135-metrics` (rolled out) |
| `smap/identity-srv` | `260607-0155-metrics` (rolled out) |
| `smap/project-srv` | `260607-0210-metrics` (rolled out) |
| `smap/ingest-srv` | `260607-0210-metrics` (rolled out) |
| `smap/knowledge-srv` | `260607-0210-metrics` (rolled out) |
| `smap/notification-srv` | `260607-0210-metrics` (rolled out) |

Rollback recipe per service:
```bash
kubectl -n smap rollout undo deployment/<service-name>
```

---

## 5. Prometheus target inventory (verified live)

```
21 jobs, 37 total targets:
  analysis-api                                       1/1 up
  apiserver                                          3/3 up
  coredns                                            1/1 up
  identity-srv                                       1/1 up
  ingest-srv                                         1/1 up
  knowledge-srv                                      1/1 up
  kube-state-metrics                                 1/1 up
  kubelet                                            9/9 up
  node-exporter                                      3/3 up
  notification-srv                                   1/1 up
  postgres-exporter                                  1/1 up
  project-srv                                        1/1 up
  rabbitmq                                           1/1 up
  redis-exporter                                     1/1 up
  redpanda                                           1/1 up
  redpanda-ui                                        1/1 up
  smap-monitoring-alertmanager                       2/2 up
  smap-monitoring-grafana                            1/1 up
  smap-monitoring-operator                           1/1 up
  smap-monitoring-prometheus                         2/2 up
  traefik-metrics                                    3/3 up
```

Sample series counts (sanity check):

| Metric | Count |
|---|---|
| `traefik_service_requests_total` | 202 |
| `rabbitmq_queue_messages_ready` | 1 |
| `redpanda_kafka_request_bytes_total` | 54 |
| `redis_commands_processed_total` | 1 |
| `pg_stat_database_xact_commit` | 10 |
| `kube_pod_status_ready{namespace="smap"}` | 66 |
| `node_cpu_seconds_total` | 96 |
| `smap_http_requests_total` (Go RED) | 8 (5 services × initial routes) |
| `analysis_api_http_requests_total` (Python RED) | 7 |

---

## 6. Grafana — dashboards loaded

Reachable internally now (and externally once Cloudflare Tunnel route is added — see §9):

- `monitor.tantai.dev` → admin login (cookie auth, anonymous off).
- Admin password: stored locally during install, **kept out of this report**. Retrieve with:
  ```bash
  kubectl --namespace monitoring get secret smap-monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d
  ```

Dashboards auto-provisioned by Grafana sidecar:

| Folder | Dashboard | Source |
|---|---|---|
| SMAP | **SMAP — System Overview (Edge + EDA + DB)** | local JSON, 30+ panels |
| Community | Traefik Official | grafana.com `17347` rev 9 |
| Community | Node Exporter Full | grafana.com `1860` rev 41 |
| Community | Kubernetes Cluster | grafana.com `7249` rev 1 |
| Community | RabbitMQ Overview | grafana.com `10991` rev 22 |
| Community | Redpanda Cluster | grafana.com `18135` rev 1 |
| Community | Redis Dashboard | grafana.com `763` rev 6 |
| Community | PostgreSQL Overview | grafana.com `9628` rev 7 |

SMAP custom dashboard panels (33 total):
- **Edge HTTP RED (Traefik)**: Total Requests 24h, Error rate, p95 latency, Open conns, Active routers, Reqs/s, status code timeseries, p50/p95/p99 timeseries.
- **Per-service breakdown**: rps per service, p95 per service, top 20 router throughput table.
- **Event-Driven — Redpanda**: brokers up, total topics, produce/consume bytes/s, produce/consume req/s, top 10 consumer group lag, under-replicated partitions.
- **Event-Driven — RabbitMQ**: queues, consumers, messages ready, unacked, publish/s, deliver/s, top 10 queue depth, in-flight per queue.
- **Cache & DB**: Redis ops/s, clients, memory, Postgres connections, TPS, rollback rate, cmd/s + hit ratio, connections by datname.
- **Cluster & Workloads**: SMAP pod CPU/memory, restarts/h, pods not Ready, node CPU.

---

## 7. Storage & resource footprint

| Component | Storage | Resource req | Resource limit |
|---|---|---|---|
| Prometheus | 10 GiB `local-path` on k3s-03 | 250 m CPU / 512 MiB | 1000 m / 1 GiB |
| Grafana | 2 GiB `local-path` on k3s-03 | 100 m / 128 MiB | 500 m / 512 MiB |
| Alertmanager | `emptyDir` 64 MiB | 30 m / 32 MiB | 100 m / 64 MiB |
| kube-state-metrics | — | 50 m / 64 MiB | 200 m / 128 MiB |
| node-exporter × 3 | — | 10 m / 16 MiB | 100 m / 64 MiB |
| Operator | — | 50 m / 128 MiB | 200 m / 256 MiB |
| postgres-exporter | — | 30 m / 48 MiB | 200 m / 128 MiB |
| redis-exporter | — | 20 m / 32 MiB | 100 m / 64 MiB |

Total req ≈ **560 m CPU / 1.0 GiB RAM**. Comfortable on k3s-03 (3 cores headroom).

---

## 8. Retention policy

| Stream | Retention |
|---|---|
| Prometheus TSDB | 15 days (size-capped at 9 GiB before disk limit hits) |
| Grafana SQLite | persistent (PVC) |
| Alertmanager state | ephemeral (`emptyDir`) — non-critical |

Backup: not configured (Phase 2 if needed). Restart on k3s-03 keeps data because PVC binds back to the same host path.

---

## 9. ⚠️ Open action for Tài (1 click in Cloudflare)

External `https://monitor.tantai.dev` currently returns 404. Investigation showed:

- Cloudflare DNS resolves `monitor.tantai.dev` → CF proxy IPs (`172.67.157.10`, `104.21.40.208`) — Proxied ON. ✓
- Direct origin (`172.16.21.205`) with `Host: monitor.tantai.dev` → 302 to `/login` from Grafana. ✓
- Both `https://monitor.tantai.dev` via CF and `--resolve … 113.177.118.202` to the public IP return the same Go-style 404 page that **never reaches Traefik** (zero log lines on any of the 3 Traefik pods for this hostname from external IPs).

That 404 signature ("404 page not found\n") is what `cloudflared` returns for an unconfigured hostname. SMAP uses Cloudflare Tunnel — `smap.tantai.dev` and `smap-portal.tantai.dev` are explicitly mapped in tunnel config; `monitor.tantai.dev` is not yet.

**Fix:** Cloudflare Zero Trust dashboard → Networks → Tunnels → (existing SMAP tunnel) → Public hostnames → Add a hostname:
- Subdomain: `monitor`
- Domain: `tantai.dev`
- Service: `HTTP` → `http://172.16.21.205:80` (or whatever target smap/smap-portal use today)

Save. Propagation < 30 s.

Until then, Tài can verify the stack works from LAN by adding `/etc/hosts` entry `172.16.21.205 monitor.tantai.dev` and pointing the browser there.

---

## 10. Verification commands (re-run any time)

```bash
# Targets up?
kubectl -n monitoring port-forward svc/smap-monitoring-prometheus 9090:9090 &
curl -s "http://localhost:9090/api/v1/targets?state=active" | jq '.data.activeTargets | group_by(.labels.job) | map({job: .[0].labels.job, up: map(select(.health=="up")) | length, total: length})'

# Grafana password
kubectl -n monitoring get secret smap-monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

# In-cluster Grafana smoke test
curl -sI -H "Host: monitor.tantai.dev" http://172.16.21.205   # → 302 to /login

# Sample query
curl -s "http://localhost:9090/api/v1/query?query=sum(rate(traefik_service_requests_total[1m]))"
```

---

## 11. Rollback recipe (full stack)

```bash
helm -n monitoring uninstall smap-monitoring
kubectl delete ns monitoring
kubectl -n smap delete deploy/redis-exporter svc/redis-exporter
kubectl -n traefik-system delete svc/traefik-metrics

# Revert Go service images (per service)
for svc in identity-srv project-srv ingest-srv knowledge-srv notification-srv analysis-api; do
  kubectl -n smap rollout undo deployment/$svc
done
```

Code revert (if needed): `git revert <commit>` on each of the 8 commits listed in §3.

---

## 12. Phase 2 / Future work (NOT required for goal)

- Wire Alertmanager → Discord using the existing `devops/discord-bot/` and known webhook.
- Add Loki + Promtail for log aggregation (fluent-bit already deployed, easy switch).
- Thanos sidecar + MinIO for long-term retention if k3s-03 disk becomes a bottleneck.
- Add a dedicated Postgres monitoring user (currently uses `identity_prod` — works but logs noise about `pg_ls_waldir` / `woodpecker` DB permission deny; harmless).
- Bump Traefik IngressController Helm chart to a version that ships `metrics` port on the LB service so the `traefik-metrics` standalone Service is no longer needed.

---

## 13. Definition of done — checklist

| Acceptance criterion (from plan §12) | Status |
|---|---|
| 1. `monitor.tantai.dev` mở được, vào Grafana login screen | ⚠️ External blocked on CF Tunnel hostname config; internal verified |
| 2. Login admin, thấy datasource Prometheus status OK | ✅ (datasource auto-provisioned) |
| 3. Dashboard Traefik 17347 hiện data thật | ✅ (202 traefik series active) |
| 4. SMAP custom dashboard hiện đủ 7+ panels | ✅ (33 panels live) |
| 5. Prometheus /targets: traefik UP, kube-state UP, node-exporter 3/3, kubelet 3/3 | ✅ + much more (21 jobs, 37 targets) |
| 6. All manifests committed + pushed to smap-deploy | ✅ (`7f241d0`) |
| 7. Evidence report exists | ✅ (this file) |

Goal **met except external Cloudflare hostname route**, which is a 30-second CF dashboard click Tài does after waking up. Stack itself is fully operational with real production data flowing in.
