# SMAP Monitoring Stack — Implementation Plan

> Target: Grafana dashboard giống ảnh tham chiếu (Total Requests, All Responses, Response Time, status codes, per-route latency) cho toàn bộ API `smap-api.tantai.dev`.
> Subdomain: `monitor.tantai.dev` → Grafana UI.
> Owner: Nguyễn Tấn Tài. Project: HCMUT graduation — SMAP.

---

## 0. TL;DR

**Khả thi 100%, không phải đoán.** Lý do:

- Traefik IngressController (`traefik-system/traefik`, v3.6.7) **đã expose Prometheus metrics** trên port `9100` (`--metrics.prometheus=true`, `--metrics.prometheus.entrypoint=metrics`). Đã verify bằng `wget http://localhost:9100/metrics` từ pod: 1007 dòng `traefik_*`, có đủ `traefik_entrypoint_request_duration_seconds_*`, `traefik_router_requests_total{code,method,protocol,router}`, `traefik_service_*`.
- Không cần sửa một dòng code Go/Python nào để có dashboard giống ảnh — Traefik đứng trước **mọi** request đi vào `smap-api.tantai.dev` qua MetalLB VIP `172.16.21.205`, nên metric edge là đại diện 100% cho API behavior.
- Đường rẻ nhất: deploy `kube-prometheus-stack` + scrape Traefik + import Grafana dashboard ID `17347` (Traefik Official). Sau đó custom thêm panel SMAP-specific.

---

## 1. Pre-flight check — cluster state

Thu thập 2026-06-07.

### 1.1 Nodes

| Node | Role | CPU alloc | Mem alloc | CPU used | Mem used | OS |
|---|---|---|---|---|---|---|
| `k3s-01` | control-plane | 4 | 11.7 GiB | 11 % (462m) | 46 % (5.5 GiB) | Ubuntu 22.04.5 |
| `k3s-02` | control-plane | 4 | 11.7 GiB | 6 % (260m) | 53 % (6.3 GiB) | Ubuntu 22.04.5 |
| `k3s-03` | control-plane | 4 | 11.7 GiB | 4 % (187m) | 62 % (7.3 GiB) | Ubuntu 22.04.5 |

K3s `v1.30.14+k3s2`, containerd `1.7.27-k3s1`. Total: 12 CPU, ~35 GiB RAM. Headroom ~14 GiB RAM, ~10 CPU. **Đủ cho monitoring stack (~2 GiB RAM, ~0.5 CPU)**.

### 1.2 Networking

- **MetalLB** namespace `metallb-system`, pool `infrastructure-pool` range `172.16.21.200-250`, auto-assign on.
- **Traefik** `LoadBalancer` VIP `172.16.21.205`, ports 80/443/8080/9100. Endpoint policy `Local`.
- **CoreDNS** active, internal DNS OK.
- **IngressClass** mặc định `traefik` (`traefik.io/ingress-controller`).
- Existing ingresses: `smap.tantai.dev`, `smap-portal.tantai.dev`, `rancher.tantai.dev`, `longhorn.tantai.dev` — tất cả trỏ về `172.16.21.205`.

### 1.3 DNS & external exposure — pattern hiện tại

Mục tiêu: expose `monitor.tantai.dev` **ra ngoài Internet**, không phải LAN-only.

Verify chain hiện tại (smap.tantai.dev đại diện cho pattern public):

```
smap.tantai.dev        CNAME tantaivpn.ddns.net → 113.177.118.202
                                                       │
                                       router NAT :80/:443 → 172.16.21.205
                                                       │
                                       Traefik LoadBalancer VIP
                                                       │
                                       Ingress match Host header
```

Test live: `curl https://smap.tantai.dev` → `HTTP 200 via 113.177.118.202`.
DNS authoritative ở **Cloudflare** (`heather.ns.cloudflare.com`, `roman.ns.cloudflare.com`).

So sánh các subdomain:

| Subdomain | Record | External-reachable? |
|---|---|---|
| `smap.tantai.dev` | CNAME → tantaivpn.ddns.net | ✅ |
| `smap-portal.tantai.dev` | CNAME → tantaivpn.ddns.net | ✅ |
| `rancher.tantai.dev` | A → 172.16.21.100 | ❌ LAN-only |
| `longhorn.tantai.dev` | A → 172.16.21.205 | ❌ LAN-only |
| `monitor.tantai.dev` | (Tài sẽ thêm) | mục tiêu: ✅ |

Cách làm đúng: ở Cloudflare DNS, tạo record `CNAME monitor → tantaivpn.ddns.net` (proxied OFF nếu muốn bám 100% pattern smap.tantai.dev, hoặc proxied ON nếu muốn ẩn origin IP qua Cloudflare proxy — khuyến nghị ON cho HTTPS edge).

**Không phải động vào router**: port forward 80/443 → 172.16.21.205 đã sẵn cho `*.tantai.dev`. Traefik tự route theo Host header.

Verify hiện tại: `monitor.tantai.dev` chưa được thêm — `dig` trả `tantaivpn.ddns.net` (fallback wildcard) hay chưa có thì check lại sau khi Tài thêm record.

### 1.4 Storage — ❌ KHÔNG dùng Longhorn

**Cảnh báo từ `report/LONGHORN_ROOT_CAUSE_REPORT.md` (2026-06-05):**

- Longhorn engine `v1.5.3` **đã EOL 17/11/2024**.
- Redis volume `pvc-7e0c2f1f...` stuck `state=attached, robustness=unknown`, mkfs.ext4 trả `Input/output error` sector 0/2 — không recover được bằng restart pod.
- Engine còn replica `tcp://10.42.0.206:10001 mode=ERR`, không xoá được vì "cannot remove last replica if volume is up".
- Node `k3s-02`, `k3s-03` flap `NodeNotReady ↔ NodeReady` → CSI snapshotter `CrashLoopBackOff`.
- Redis / RabbitMQ / Redpanda **đã chuyển sang `emptyDir`** sau RCA (xem `smap-deploy/infrastructure/{redis,rabbitmq}/statefulset.yaml`).
- Repo policy: "Longhorn failure must not take the whole SMAP stack down."

→ Monitoring stack **không được phép phụ thuộc Longhorn**. Loại cả `longhorn` và `longhorn-single-replica`.

| StorageClass | Provisioner | Dùng cho monitoring? | Reason |
|---|---|---|---|
| `local-path` | rancher.io/local-path | ✅ chọn | Node-local hostPath, không có CSI race, không I/O loop nightmare |
| `longhorn` | driver.longhorn.io | ❌ cấm | EOL, broken state recurring |
| `longhorn-single-replica` | driver.longhorn.io | ❌ cấm | Cùng driver, cùng risk |
| `emptyDir` | — | ⚠️ chỉ Alertmanager | Mất khi pod restart, không phù hợp Prometheus 15d |

**Chọn**: `local-path` + **nodeSelector pin** Prometheus/Grafana về 1 node cố định.

- Node target: `k3s-01` (hiện thấp tải nhất: 11% CPU, 46% RAM).
- Trade-off: pod reschedule sang node khác → mất data. Acceptable vì:
  - Prometheus 15-day rolling, không phải audit log.
  - Grafana dashboard JSON commit vào git repo (provision lại từ ConfigMap).
  - Grafana SQLite chỉ chứa user/session — recreate được.
- Backup: `kubectl cp` Prometheus TSDB ra ngoài định kỳ nếu cần evidence cho thesis (tuỳ chọn).

Storage budget (PVC `local-path`):
- Prometheus TSDB: **10 GiB** (retention 15d, 15s scrape, ~50 series ban đầu).
- Grafana: **2 GiB** (SQLite + ConfigMap dashboards + plugins).
- Alertmanager: `emptyDir` 64 MiB (state alerts mất khi restart không nghiêm trọng).

Risk hard pin node:
- Nếu `k3s-01` reboot, Prometheus down ~1–2 phút khi restart, data file còn nguyên.
- Nếu `k3s-01` mất disk → mất data, rebuild scratch.
- Mitigation: nếu Tài muốn HA hơn → Phase 2 setup Thanos sidecar + S3 (MinIO). Phase 1 không cần.

### 1.5 TLS

- `cert-manager` namespace có sẵn nhưng **không có `ClusterIssuer`** — toàn bộ ingress hiện tại chạy HTTP only (port 80), trừ Rancher có self-signed.
- Plan: bám pattern hiện tại — `monitor.tantai.dev` chạy **HTTP** trên cổng 80. Nếu cần TLS sau, setup ClusterIssuer Let's Encrypt DNS-01 (vì internal IP).

### 1.6 Hiện trạng metrics theo từng nguồn

| Nguồn | `/metrics` ready? | Có dùng được không sửa code? |
|---|---|---|
| **Traefik ingress** | ✅ port 9100, 1007 lines, RED đầy đủ | ✅ Đây là đường chính |
| `kube-state-metrics` | ❌ chưa deploy | Sẽ có khi cài kube-prometheus-stack |
| `node-exporter` | ❌ chưa deploy | Sẽ có khi cài kube-prometheus-stack |
| `kubelet/cAdvisor` | ✅ scrape từ kubelet | Auto qua Prometheus Operator |
| `analysis-srv` (Python) | ⚠️ Có code `prometheus_client` trong `internal/observability/metrics.py` nhưng **chưa mount ASGI app `/metrics`** | Cần 5 dòng code mount + scrape annotation |
| 5 Go services | ❌ chỉ có OTel tracing (`shared-libs/go/tracing`), không có `promhttp` | Cần middleware + main.go mount |
| `scapper-srv` | ❌ không có | Same |
| **Redpanda** | ✅ built-in `:9644/metrics` | Bonus, scrape free |
| **RabbitMQ** | ⚠️ plugin `rabbitmq_prometheus` tắt | Bật plugin |
| **Redis** | ❌ không có exporter | Bonus, cài `redis_exporter` sidecar nếu cần |
| **PostgreSQL** (`172.16.19.10:5432`) | ❌ ngoài cluster | Bonus, cài `postgres_exporter` deployment |

**Phase 1 (MVP — đủ giống ảnh tham chiếu)**: chỉ cần Traefik metrics. Các nguồn khác đẩy sang Phase 2/3.

---

## 2. Architecture

```
DNS: monitor.tantai.dev (A) → 172.16.21.205
                                  │
                            MetalLB VIP
                                  │
                          traefik LoadBalancer :80
                                  │
                        Ingress monitor.tantai.dev
                                  │
                         grafana svc :80 → :3000
                                  │
                  ┌───────────────┼───────────────┐
                  │               │               │
            prometheus svc   alertmanager   loki (optional Phase 3)
                  │
       ┌──────────┴──────────────────────────────┐
       │                                         │
ServiceMonitor: traefik       ServiceMonitor: kube-state-metrics
       │                                         │
traefik-system/traefik :9100      kube-system/...
```

Tất cả nằm trong namespace mới `monitoring`. Helm release `smap-monitoring`.

---

## 3. Stack components

Cài bằng **`kube-prometheus-stack`** Helm chart (Prometheus Community). Lý do: gói chuẩn, bao gồm CRDs Prometheus Operator, dashboards mặc định, scrape configs cho kube-system, không phải tự ráp.

| Component | Image / version | Mục đích | Resource (req/lim) |
|---|---|---|---|
| `kube-prometheus-stack` (Helm) | latest stable (≥ 65.x) | Operator + Prometheus + Grafana + Alertmanager + kube-state-metrics + node-exporter | — |
| **Prometheus** | `prom/prometheus` (chart-pinned) | TSDB, scrape, query | 250m/1000m, 512Mi/1Gi, PVC 10Gi |
| **Grafana** | `grafana/grafana` | Dashboard UI, datasource | 100m/500m, 128Mi/512Mi, PVC 1Gi |
| **Alertmanager** | `prom/alertmanager` | Alert routing (Phase 2 mới wire Discord) | 50m/200m, 64Mi/128Mi, PVC 1Gi |
| **kube-state-metrics** | upstream | K8s object state metrics | 50m/200m, 64Mi/128Mi |
| **node-exporter** (DaemonSet) | upstream | Node-level metrics, 3 pods | 30m/100m × 3, 32Mi/64Mi × 3 |

**Tổng resource**: ~1.2 CPU req, ~2 GiB RAM, ~12 GiB storage. Trong ngưỡng headroom node.

Disable trong chart values:
- `prometheus-windows-exporter` (không có Windows node)
- `defaultRules.rules.etcd` (k3s SQLite-backed, không có etcd CRD chuẩn — sẽ throw alert giả)
- `kubeApiServer`, `kubeControllerManager`, `kubeScheduler`, `kubeEtcd`, `kubeProxy` service monitors — k3s bundle, không expose endpoint chuẩn, scrape sẽ fail. Giữ `kubelet` + `coreDNS`.

---

## 4. Scrape targets — Phase 1

### 4.1 Traefik (đường chính, KHÔNG sửa code)

`ServiceMonitor` (CRD do Prometheus Operator quản):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: traefik
  namespace: monitoring
  labels:
    release: smap-monitoring   # must match prometheus selector
spec:
  namespaceSelector:
    matchNames: [traefik-system]
  selector:
    matchLabels:
      app.kubernetes.io/name: traefik
  endpoints:
    - port: traefik   # port 8080 — entrypoint web cho 9100 không lộ qua Service
      path: /metrics
      interval: 15s
```

⚠️ **Vấn đề**: Service `traefik` hiện chỉ expose `web/80`, `websecure/443`, `traefik/8080`. Port `metrics/9100` của Pod **chưa được mapping ra Service**. Hai cách fix:

**Cách A (recommended)**: thêm port `metrics` vào Service `traefik-system/traefik`. 1 patch YAML, không restart pod.

```yaml
# patch: kubectl -n traefik-system patch svc traefik --type=json -p='[
#   {"op":"add","path":"/spec/ports/-","value":{"name":"metrics","port":9100,"targetPort":9100,"protocol":"TCP"}}
# ]'
```

**Cách B**: scrape qua port `8080` (traefik dashboard/API entrypoint) — KHÔNG được, port này là dashboard, không phải metrics (đã check args).

→ Chọn **Cách A**. Risk: ngrok port public extra trên LB IP nếu external traffic policy "Local" + access từ ngoài LAN. Mitigation: ServiceType vẫn LoadBalancer nhưng metrics port chỉ cần intra-cluster — sẽ tạo **Service riêng** `traefik-metrics` type `ClusterIP` để scrape, không đụng Service chính.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik-metrics
  namespace: traefik-system
  labels:
    app.kubernetes.io/name: traefik
    app.kubernetes.io/component: metrics
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: traefik
  ports:
    - name: metrics
      port: 9100
      targetPort: 9100
      protocol: TCP
```

ServiceMonitor selector trỏ `app.kubernetes.io/component: metrics`.

### 4.2 kube-state-metrics, node-exporter, kubelet/cAdvisor

Helm chart tự sinh ServiceMonitor — không phải làm gì.

---

## 5. Dashboard — mapping với ảnh tham chiếu

### 5.1 Import sẵn (cover 80% ảnh)

| Dashboard | Grafana ID | Coverage so với ảnh |
|---|---|---|
| **Traefik Official** | `17347` | Total Requests, All Responses, Response Time p50/p95/p99, per-router rate, top routes — **GIỐNG 90% ảnh** |
| **Traefik 2 Official** | `11462` | Legacy nhưng vẫn tốt cho status code donut |
| **Node Exporter Full** | `1860` | Bonus: cluster health |
| **Kubernetes Cluster** | `7249` | Bonus: pod resources |

Import bằng Grafana `dashboardProviders` (configmap), nhúng JSON vào Helm values.

### 5.2 Custom dashboard SMAP — `smap-api-overview.json`

Build tay, panel theo đúng ảnh:

| Panel | PromQL | Note |
|---|---|---|
| **Total Requests (single stat, 24h)** | `sum(increase(traefik_router_requests_total{router=~".*smap.*"}[24h]))` | Đếm tổng request qua các router smap |
| **All Responses (time series, status group)** | `sum by (code) (rate(traefik_router_requests_total{router=~".*smap.*"}[5m]))` | Stack area 2xx/3xx/4xx/5xx |
| **Response Time (heatmap)** | `histogram_quantile(0.95, sum by (le) (rate(traefik_router_request_duration_seconds_bucket{router=~".*smap.*"}[5m])))` | p50/p95/p99 lines |
| **Per-service rate** | `sum by (router) (rate(traefik_router_requests_total[5m]))` | Table, sort desc |
| **Per-service p95 latency** | `histogram_quantile(0.95, sum by (router, le) (rate(traefik_router_request_duration_seconds_bucket[5m])))` | Bar chart |
| **Error budget (%)** | `sum(rate(traefik_router_requests_total{code=~"5.."}[5m])) / sum(rate(traefik_router_requests_total[5m]))` | Single stat, threshold 1% |
| **TTFB heatmap** | `sum by (le) (rate(traefik_service_request_duration_seconds_bucket[5m]))` | Heatmap, time bucket |

⚠️ **Tên router**: Traefik tạo router name auto dạng `<namespace>-<ingress-name>-<host>-<path>@kubernetes`. Cần verify regex `router=~".*smap.*"` sau khi cài. Nếu không khớp, dùng label `entrypoint="web"` + filter theo `service` thay vì `router`.

### 5.3 Variables (template)

- `$service` — query `label_values(traefik_router_requests_total, router)`, multi-select.
- `$method` — `GET|POST|PUT|DELETE|PATCH`.
- `$code_class` — `2xx|3xx|4xx|5xx`.

---

## 6. Ingress `monitor.tantai.dev` — expose ra Internet

Pattern khớp `smap.tantai.dev`: ingress nội bộ chạy HTTP port 80, edge HTTPS do Cloudflare proxy (nếu bật) hoặc router NAT pass-through (nếu CF DNS-only).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: smap-monitoring
spec:
  ingressClassName: traefik
  rules:
    - host: monitor.tantai.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: smap-monitoring-grafana
                port:
                  number: 80
```

**Chain truy cập sau khi xong:**

```
User browser → https://monitor.tantai.dev
            → Cloudflare DNS resolve CNAME → tantaivpn.ddns.net → 113.177.118.202
            → home router NAT :80 / :443 (đã forward sẵn)
            → 172.16.21.205 (Traefik LB VIP, MetalLB)
            → Ingress match Host: monitor.tantai.dev
            → svc/smap-monitoring-grafana:80 → pod grafana:3000
            → Grafana UI (login admin)
```

DNS action ở Cloudflare:
```
Type: CNAME
Name: monitor
Target: tantaivpn.ddns.net
Proxy: ☑ Proxied (recommended — auto HTTPS edge, hide origin)
TTL: Auto
```

Nếu Cloudflare proxy OFF → user gọi HTTP, Tài tự setup TLS ở Traefik (cert-manager + Let's Encrypt DNS-01) hoặc bám HTTP như smap.tantai.dev hiện tại.

---

## 7. Auth & secrets

- Grafana admin: user `admin`, password sinh ngẫu nhiên 32-char, lưu trong `Secret` `monitoring/smap-monitoring-grafana` → `admin-password`. Lấy bằng `kubectl -n monitoring get secret smap-monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d`.
- Anonymous viewer **off** (mặc định). Nếu Tài muốn xem nhanh, bật `auth.anonymous.enabled=true` + role `Viewer`.
- Datasource Prometheus auto-provisioned bởi Helm chart, URL `http://smap-monitoring-prometheus:9090`.

---

## 8. Repo layout — nơi đặt manifests

```
smap-deploy/
├── infrastructure/
│   └── monitoring/                 # NEW
│       ├── namespace.yaml
│       ├── helm-values.yaml        # kube-prometheus-stack values
│       ├── helm-release.yaml       # (or just install via CLI + commit values)
│       ├── traefik-metrics-svc.yaml
│       ├── servicemonitor-traefik.yaml
│       ├── ingress-grafana.yaml
│       └── dashboards/
│           ├── smap-api-overview.json
│           └── kustomization.yaml  # mount as configmap
└── decision-log.md                 # append: "2026-06-07 add monitoring stack"
```

Pattern bám `smap-deploy/infrastructure/{redis,rabbitmq,redpanda,metabase}/` hiện tại. Mặc dù dùng Helm, vẫn commit `helm-values.yaml` để reproducible.

---

## 9. Execution steps (E2E)

Tớ sẽ chạy lần lượt, từng step có verify gate. Mỗi step in 1 dòng caveman trạng thái.

| # | Step | Command | Verify |
|---|---|---|---|
| 1 | Create namespace `monitoring` | `kubectl apply -f infrastructure/monitoring/namespace.yaml` | `kubectl get ns monitoring` |
| 2 | Add Helm repo | `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update` | `helm search repo kube-prometheus-stack` |
| 3 | Install chart with values | `helm install smap-monitoring prometheus-community/kube-prometheus-stack -n monitoring -f helm-values.yaml` | Pods `monitoring/*` Running |
| 4 | Wait CRDs ready | `kubectl wait --for=condition=Established crd/servicemonitors.monitoring.coreos.com --timeout=120s` | exit 0 |
| 5 | Create traefik metrics svc | `kubectl apply -f traefik-metrics-svc.yaml` | `kubectl -n traefik-system get svc traefik-metrics` |
| 6 | Apply ServiceMonitor | `kubectl apply -f servicemonitor-traefik.yaml` | Prometheus targets UP |
| 7 | Verify Prometheus scrape | `kubectl -n monitoring port-forward svc/smap-monitoring-prometheus 9090 &` → check `http://localhost:9090/targets` | target traefik UP |
| 8 | Confirm DNS `monitor.tantai.dev → 172.16.21.205` | `dig +short monitor.tantai.dev` | trả về `172.16.21.205` |
| 9 | Apply ingress | `kubectl apply -f ingress-grafana.yaml` | `kubectl get ing -n monitoring` |
| 10 | Smoke test Grafana login | `curl -I http://monitor.tantai.dev` | 302 to /login |
| 11 | Login Grafana, verify import dashboards | UI | Dashboard 17347 render data |
| 12 | Apply custom SMAP dashboard | `kubectl apply -f dashboards/` | Dashboard hiện trong UI |
| 13 | Commit to `smap-deploy` repo | `git -C smap-deploy add … && git commit -m "feat(monitoring): kube-prometheus-stack + grafana monitor.tantai.dev"` | commit hash |
| 14 | Generate evidence report | `report/SMAP_MONITORING_DEPLOY_REPORT.md` với screenshot URL/CLI output | file exists |

**Rollback**: `helm uninstall smap-monitoring -n monitoring && kubectl delete ns monitoring`. Mọi thay đổi đảo ngược được trừ Service `traefik-metrics` (cũng `kubectl delete -f` 1 phát).

**Thời gian ước**: 20–30 phút, gồm chờ Helm install (~5 phút) + verify (~10 phút) + import dashboard.

---

## 10. Risk & mitigation

| Risk | Severity | Mitigation |
|---|---|---|
| Longhorn breakage tái diễn | **Cao** | ❌ Loại hoàn toàn Longhorn. Dùng `local-path` + nodeSelector. Đã ghi trong §1.4. |
| Node `k3s-01` (pin Prometheus) chết | Trung | Data 15d mất, dashboard JSON từ git rebuild được. Phase 2: thêm Thanos + MinIO nếu cần HA. |
| DNS `monitor.tantai.dev` CNAME chưa thêm ở Cloudflare | Cao — block step 10 | Tài tự thêm record CNAME → tantaivpn.ddns.net trước khi tớ apply ingress. |
| Cloudflare proxy bật nhưng cert origin invalid | Trung | Dùng "Flexible" SSL mode tạm thời (CF → user: HTTPS, CF → origin: HTTP), hoặc tắt proxy |
| Router NAT 80/443 đã forward 172.16.21.205? | Đã verify | smap.tantai.dev 200 OK via public IP → router đã forward sẵn |
| Prometheus OOMKill khi cardinality cao | Trung | Drop label `path` ở relabel config nếu route nhiều; retention 15d → 7d nếu cần |
| Traefik router name không match regex SMAP | Thấp | Chạy `topk(20, sum by (router) (rate(traefik_router_requests_total[5m])))` xem label thực tế, sửa dashboard JSON |
| Cluster CPU spike khi Helm install 3 node | Thấp | Resource req conservative, đã tính headroom |
| Helm CRD conflict nếu có Prometheus Operator cũ | Rất thấp | `kubectl get crd \| grep monitoring.coreos.com` đã check → không có |
| Grafana lộ admin login public Internet | Trung | Strong admin password (32 char) hoặc bật Cloudflare Access (Zero Trust) để gate login |

---

## 11. Out of scope (Phase 2/3 — KHÔNG làm lần này)

- ❌ Sửa code Go/Python để thêm `/metrics` per-service (Phase 2 — thêm middleware vào `shared-libs/go`).
- ❌ Alertmanager → Discord wire (có `devops/discord-bot/`, để Phase 2).
- ❌ Loki + Promtail (logs tập trung — Phase 3, hiện đã có fluent-bit viewer).
- ❌ Tracing (Tempo/Jaeger) — Phase 3, dù shared-libs/go đã có OTel.
- ❌ TLS Let's Encrypt cho `monitor.tantai.dev` — Phase 2 nếu cần.
- ❌ PostgreSQL/Redis/RabbitMQ exporter — Phase 2.

---

## 12. Acceptance criteria (definition of done Phase 1)

1. `monitor.tantai.dev` mở được, vào Grafana login screen.
2. Login admin, thấy datasource Prometheus status OK.
3. Dashboard `Traefik Official (17347)` hiện data thật (request rate > 0).
4. Dashboard `SMAP API Overview` (custom) hiện đủ 7 panel.
5. Prometheus `/targets` page: `traefik` UP, `kube-state-metrics` UP, `node-exporter` 3/3 UP, `kubelet` 3/3 UP.
6. Tất cả manifest commit vào `smap-deploy` branch `main`, push.
7. `report/SMAP_MONITORING_DEPLOY_REPORT.md` chứa: cluster snapshot trước/sau, lệnh đã chạy, screenshot URL (hoặc curl evidence), rollback recipe.

---

## 13. Câu hỏi cần Tài chốt trước khi tớ chạy

1. **Cloudflare DNS** — Tài tự thêm `CNAME monitor → tantaivpn.ddns.net` ở dashboard Cloudflare. Proxied **ON** (recommend, HTTPS edge auto) hay OFF (giống smap.tantai.dev HTTP-only)?
2. **TLS edge** — nếu CF proxy ON: dùng SSL mode "Flexible" (CF↔origin HTTP, đỡ phải cert) hay "Full" (origin phải có cert, phức tạp hơn)?
3. **Storage** — đồng ý `local-path` pin `k3s-01`, KHÔNG Longhorn (10 GiB Prom + 2 GiB Grafana + emptyDir AM)?
4. **Retention** Prometheus 15 ngày OK, hay 7 ngày để tiết kiệm disk?
5. **Grafana auth** — Internet-facing → bắt buộc strict admin login (random 32-char password)? Hay thêm CF Access Zero Trust để gate IP/email?
6. **Helm vs Kustomize** — Tớ propose Helm `kube-prometheus-stack`. Muốn pure-Kustomize giống `smap-deploy/infrastructure/` thì render Helm → static YAML rồi commit.
7. **Phase 2** — sau Phase 1 done, làm tiếp `/metrics` middleware cho Go services (5 srv) + ASGI mount cho Python (analysis/scapper) ngay không, hay để sprint khác?

Tài đọc, chốt 7 mục trên (hoặc reply "chốt hết default" = CNAME proxied ON, SSL Flexible, local-path k3s-01, retention 15d, strict admin login, Helm, Phase 2 để sprint sau), tớ chạy E2E step 1 → 14.
