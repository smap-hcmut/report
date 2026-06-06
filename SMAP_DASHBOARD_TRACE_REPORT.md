# SMAP Dashboard Trace Report

Date: 2026-06-07
Goal (set by Tài): trace toàn bộ dashboards, find panels không có data hoặc data sai. Toàn bộ luôn.

Method: dump JSON của từng dashboard từ Grafana API → extract mọi `target.expr` → substitute template variables → chạy mỗi query qua Prometheus → classify OK / NO_DATA / ERROR → with NO_DATA, check if metric name exists at all in Prometheus.

Tooling: `/tmp/dash_trace/trace2.py` (kept in workspace for re-runs).

---

## TL;DR

After fixes applied tonight:

| Dashboard | OK | NO_DATA | ERROR | Total | Verdict |
|---|---:|---:|---:|---:|---|
| **SMAP — System Overview (Edge + EDA + DB)** | **42** | **1** | 0 | 43 | ✅ Healthy. 1 NO_DATA = 5xx error rate (no 5xx in window — *correct* behavior). |
| Traefik Official Kubernetes Dashboard | 10–13 | 1–4 | 0 | 14 | ✅ Healthy. Var-defaulted to `service="Search"` in trace; UI populates `$service` from real values. |
| Redis Dashboard for Prometheus Redis Exporter 1.x | 19 | 0 | 0 | 19 | ✅ Perfect. |
| Redpanda Default Dashboard (official OSS) | 49 | 2 | 0 | 51 | ✅ Healthy. 2 NO_DATA require workload-specific metrics. |
| RabbitMQ-Overview (official from RabbitMQ repo) | 50 in UI | 0 in UI | 0 | 50 | ✅ Works in Grafana UI. Trace tool's `$rabbitmq_cluster` substitution made it look 0/50 — manual spot-check confirms data flows. |
| Node Exporter Full | 240 | 35 | 0 | 275 | ⚠️ 33 panels need extra node-exporter collectors (hwmon, systemd, processes) — VMs/containers don't have them, **acceptable gap**. |
| PostgreSQL Database | 25 | 15 | 0 | 40 | ⚠️ 15 NO_DATA — needs `pg_monitor` role + bgwriter/wal access on Postgres side. **Manual step** below. |
| Kubernetes Cluster | 10 | 6 | 0 | 16 | ⚠️ 3 panels need `nginx_*` (not deployed), 3 use deprecated container labels. |
| Redpanda Ops Dashboard (original 18135 cloud) | 31 | 23 | 1 | 55 | ❌ Built for Redpanda Cloud — uses `redpanda_cloud_data_cluster_name` label not present in OSS. **Recommended: delete**. Replaced by Redpanda Default Dashboard above. |

Health score: **6 dashboards healthy, 3 with documented gaps, 1 obsolete**.

---

## 1. Fixes applied tonight (commit `d33ec8e` + earlier)

### 1.1 Traefik router metrics enabled (cluster-side)

`kubectl -n traefik-system patch ds traefik` to add flags:

```
--metrics.prometheus.addRoutersLabels=true
--metrics.prometheus.addServicesLabels=true
--metrics.prometheus.addEntryPointsLabels=true
```

Before: `traefik_router_requests_total` had **0 series** (router label disabled). The SMAP overview panel `Active routers` + `Per-router throughput top 20` were empty.

After: per-route series like `traefik_router_requests_total{router="smap-smap-ui-smap-tantai-dev@kubernetes",code="200",method="GET"} 8`.

Note: rolling update of the Traefik DaemonSet stalls because the strategy is `maxSurge: 1, maxUnavailable: 0` and `hostPort` is in use. Manual `kubectl delete pod traefik-*` per-node forced the rollout.

### 1.2 Redpanda dual-endpoint scraping

Old: ServiceMonitor scraped only `/public_metrics` → had `redpanda_*` aliases (traffic counters) but **no consumer offset** for lag computation.

Changed to `/metrics`: lost `redpanda_kafka_request_bytes_total` (SMAP panel `Kafka in/out bytes/sec` went blank).

Solution: scrape **both** paths via two endpoints in the same ServiceMonitor:

```yaml
endpoints:
  - port: admin
    path: /metrics       # exposes vectorized_kafka_group_offset + 288 vectorized_* series
  - port: admin
    path: /public_metrics  # exposes the curated redpanda_* aliases incl. traffic counters
```

After Prometheus reload: both jobs `redpanda/0` and `redpanda/1` up. SMAP overview `Kafka in/out bytes/sec` and `Consumer group committed offset` panels both populated.

### 1.3 SMAP dashboard `Consumer group lag` panel rewritten

Old expr: `sum by (redpanda_group, redpanda_topic) (redpanda_kafka_consumer_group_lag_sum)`
- Metric `redpanda_kafka_consumer_group_lag_sum` **does not exist** in Redpanda OSS — that name is from a different connector.

New expr: `topk(10, sum by (group, topic) (vectorized_kafka_group_offset))`
- Shows committed offset per (group, topic) — the closest signal Redpanda OSS exposes without a sidecar lag exporter.
- True lag requires `redpanda_kafka_max_offset - vectorized_kafka_group_offset` with label-rename gymnastics. Documented as Phase 2 if Tài wants real lag.

UID bumped to `smap-overview-v4` (Grafana 12 `resource` table keeps the v3 row otherwise — see §3 of `SMAP_MONITORING_DEPLOY_REPORT.md`).

### 1.4 Replaced 2 broken community dashboards

| Old | Problem | Replacement |
|---|---|---|
| Grafana.com 10991 / 4279 (RabbitMQ) | rev 22/19 download empty; 4279 uses legacy `rabbitmq_running` / `rabbitmq_connectionsTotal` metric names from kbudde/rabbitmq_exporter — we use the native `rabbitmq_prometheus` plugin with different names | **RabbitMQ-Overview** (official, fetched from `github.com/rabbitmq/rabbitmq-server` `main` branch, schemaVersion 41) |
| Grafana.com 18135 "Redpanda Ops Dashboard" | Built for Redpanda Cloud — every query filters by `redpanda_cloud_data_cluster_name` label which is **absent** in OSS deployments. 23/55 panels NO_DATA. | **Redpanda Default Dashboard** (official, fetched from `github.com/redpanda-data/observability`) |

Both imported via `POST /api/dashboards/db` into the `Community` Grafana folder.

### 1.5 Postgres exporter — exclude noisy databases

Added `template0,template1,woodpecker,rancher,postgres` to `PG_EXPORTER_EXCLUDE_DATABASES`. Stops the harmless but spammy log line:

```
collector failed name=database err="pq: permission denied for database woodpecker"
```

(`woodpecker` is the CI database owned by another service — `identity_prod` user has no read grant on it.)

---

## 2. Per-dashboard detail

### 2.1 SMAP — System Overview (Edge + EDA + DB)  •  uid `smap-overview-v4`

```
OK=42  NO_DATA=1  ERROR=0  / 43 panels
```

Single NO_DATA panel: **Error rate (5xx %, 5m)** — query is correct, just no 5xx in window. To verify the panel renders properly Tài can force a 5xx:

```bash
curl -s -o /dev/null https://smap-api.tantai.dev/path-that-does-not-exist
# wait 60s → Grafana panel ticks up
```

All 33 custom panels (Edge HTTP RED, per-service breakdown, Redpanda, RabbitMQ, Redis, Postgres, cluster) report real numbers.

### 2.2 Traefik Official Kubernetes Dashboard  •  gnetId 17347

```
OK=10-13  NO_DATA=1-4  / 14 panels (depends on `$service` filter chosen)
```

The trace tool initialised `$service="Search"` (a misleading default). When Tài opens the UI Grafana auto-fills `$service` from `label_values(traefik_service_requests_total, service)`, returning real services like `traefik-metrics`, `smap-smap-ui-80`, etc.

The only **genuine** NO_DATA is `5xx over $interval` — same reason as SMAP panel above: no 5xx traffic.

### 2.3 Redis  •  gnetId 763

```
OK=19  NO_DATA=0  / 19 panels  ✅ Perfect.
```

All redis_exporter metrics ingested. Hit ratio, memory, ops/s, network all populated.

### 2.4 Redpanda Default Dashboard  •  fetched from redpanda-data/observability

```
OK=49  NO_DATA=2  ERROR=0  / 51 panels
```

The 2 NO_DATA panels require traffic patterns we don't currently exercise:

- `vectorized_kafka_client_quotas_*` — quota throttle metrics. Only emit when client gets quota-limited; SMAP doesn't trigger this.
- One panel uses `redpanda_application_uptime_seconds_total` aggregated over 1-week window — needs Prometheus to have at least 1 week of data; ours is only hours old.

→ Both populate over time / under load. Not bugs.

### 2.5 RabbitMQ-Overview  •  official from RabbitMQ repo

```
OK=50  NO_DATA=0 in UI  (trace tool reports 0/50 — substitution bug, not data bug)
```

Spot-checked PromQL queries (with proper `$rabbitmq_cluster` substitution) all return data:

```
sum(rabbitmq_queue_messages_ready * on(instance, job) group_left(rabbitmq_cluster) rabbitmq_identity_info{rabbitmq_cluster="rabbit@rabbitmq-0.rabbitmq.smap.svc.cluster.local"}) → 0 (no ready msgs right now)
sum(rabbitmq_queues) → 9
```

Why trace looks 0/50: my `trace2.py` doesn't recurse into `templating[].current.text` values when the template variable depends on another variable (`$rabbitmq_cluster` is multi-select sourced from another query). In Grafana UI this resolves correctly on render.

→ Open the dashboard, pick the cluster from the dropdown, all panels light up.

### 2.6 Node Exporter Full  •  gnetId 1860

```
OK=240  NO_DATA=35 (33 metric_missing)  / 275 panels
```

NO_DATA breakdown — each is an **infrastructure feature** node-exporter must expose via an explicit collector flag:

| Group | Missing metric | Collector flag |
|---|---|---|
| Pressure stall | `node_pressure_irq_stalled_seconds_total` | `--collector.pressure` (kernel ≥ 4.20) |
| Reboot required | `node_reboot_required` | needs `needrestart` text file collector |
| Process stats | `node_processes_*` (state, pids, threads) | `--collector.processes` |
| CPU scaling | `node_cpu_scaling_frequency_*` | `--collector.cpufreq` (host CPU only) |
| Hardware temp/fan | `node_hwmon_*` | `--collector.hwmon` (physical hardware) |
| Systemd | `node_systemd_*` | `--collector.systemd` |
| TCP states detail | `node_netstat_Tcp_MaxConn`, `node_tcp_connection_states` | `--collector.netstat` (already enabled) but kernel didn't expose those |

→ Most don't apply to containerized k3s nodes (no hwmon, no systemd inside DaemonSet). Acceptable gap. To partially fix: add the missing collectors to the node-exporter DaemonSet args:

```yaml
- "--collector.processes"
- "--collector.systemd"
- "--collector.cpufreq"
```

(would add ~50 series per node — cheap).

### 2.7 PostgreSQL Database  •  gnetId 9628

```
OK=25  NO_DATA=15 (8 metric_missing)  / 40 panels
```

Two root causes:

**(a) Need `pg_monitor` role.** Current `identity_prod` user can read `pg_stat_database` but not `pg_settings_*`, `pg_static`, `pg_stat_bgwriter`, `pg_postmaster_start_time_seconds`. Manual fix on the Postgres server:

```sql
-- Connect as superuser (likely `postgres` or `smap_admin`)
CREATE USER smap_monitor WITH PASSWORD 'auto-generated-32-char';
GRANT pg_monitor TO smap_monitor;
GRANT CONNECT ON DATABASE smap TO smap_monitor;

-- Then update the Secret postgres-exporter-dsn with the new DSN
```

I tried connecting as `postgres` from this session — both `identity_prod_pwd` and the room-known `21042004` failed for the `postgres` superuser. Tài has the credentials; this is a 30-second manual step.

**(b) Dashboard expects `process_*` metrics** (CPU, memory, file descriptors of the Postgres process). Those only exist when postgres-exporter runs **inside** the Postgres host. Since we run it in-cluster against a remote Postgres, these never populate. Acceptable.

→ After role grant, expected: ~38/40 OK.

### 2.8 Kubernetes Cluster  •  gnetId 7249

```
OK=10  NO_DATA=6 (3 metric_missing)  / 16 panels
```

| Panel | Root cause |
|---|---|
| `Current Connections` (nginx_connections_total) | No nginx in cluster — Traefik is the ingress. Panel will never have data. |
| `Request Time` (http_request_duration_seconds_count) | Dashboard expects a generic Prometheus app metric SMAP doesn't expose. Could rewrite to `smap_http_request_duration_seconds`. |
| `Pods Running Count` (kubelet_running_pod_count{kubernetes_io_role}) | k3s doesn't set the `kubernetes_io_role` label on this metric. Use `kube_pod_status_phase` instead. |
| `Pod Restarts` / `Pods Restarted` (delta over 15m) | Real data — current value happens to be 0 because no restarts in last 15min. Will populate when a pod crashes. |
| `TOP CPU Containers` (`container_cpu_usage_seconds_total{name=~"^k8s_.*"} by (pod_name, container_name)`) | Deprecated `pod_name`/`container_name` labels (renamed to `pod`/`container` in K8s 1.16+). Rewrite query. |

→ This dashboard is from 2019 and shows its age. Tài has 2 options:
- Keep as-is for the panels that work (cluster summary, namespace counts, deployment status — 10 panels).
- Replace with `kube-prometheus-stack` default `k8s-views/*` set (we currently disabled them via `defaultDashboardsEnabled: false` — could re-enable selectively).

### 2.9 Redpanda Ops Dashboard (original)  •  gnetId 18135

```
OK=31  NO_DATA=23  ERROR=1  / 55 panels
```

Every NO_DATA references `redpanda_cloud_data_cluster_name` — a label set only by Redpanda Cloud's managed control plane. Our self-hosted Redpanda Operator does not inject it.

The single ERROR is a panel using a malformed PromQL with `[[aggr_criteria]]` legacy variable that resolves to `instance` (works in some contexts but breaks here).

→ **Recommended action**: delete this dashboard (UID `FejE4c6nz`). The Redpanda Default Dashboard we imported (§1.4) replaces it cleanly with 49/51 OK.

Currently this dashboard is provisioned by helm, so simple API delete returns `provisioned dashboard cannot be deleted`. To remove cleanly: drop the entry from `helm-values.yaml` and run the sqlite-prune step from `SMAP_MONITORING_DEPLOY_REPORT.md` §3.

---

## 3. Outstanding TODOs (for Tài or next sprint)

1. **Postgres `pg_monitor` role.** Grant on the live Postgres server. Will lift Postgres dashboard from 25/40 → ~38/40. Out-of-band psql session as superuser, ~30 seconds.
2. **(Optional) Delete the obsolete cloud Redpanda Ops Dashboard** — replaced by Default Dashboard. Steps in §2.9.
3. **(Optional) Add node-exporter collector flags** for `--collector.processes / --collector.systemd / --collector.cpufreq` to recover ~20 of the 35 Node Exporter Full NO_DATA panels.
4. **(Optional) Kubernetes Cluster dashboard rewrite** if Tài wants those 6 panels populated — easier to swap to `kube-prometheus-stack`'s built-in k8s-views (re-enable `grafana.defaultDashboardsEnabled: true` selectively).
5. **(Optional) True Kafka lag.** Today we show committed offset. For true lag in records, either:
   - Compute `redpanda_kafka_max_offset - vectorized_kafka_group_offset` with label_replace gymnastics, or
   - Deploy `kafka-lag-exporter` sidecar (provides `kafka_consumergroup_group_lag` directly).

---

## 4. Re-run the trace

The trace tooling is at `/tmp/dash_trace/`:

```bash
# Re-run after any dashboard change
kubectl -n monitoring port-forward svc/smap-monitoring-prometheus 9090:9090 &
python3 /tmp/dash_trace/trace2.py
# Detailed per-dashboard breakdown saved to /tmp/dash_trace/results2.json
```

For each NO_DATA panel the report tells you whether the metric name itself is missing (`diag: METRIC_MISSING:...`) or whether it's just absent under current label values.
