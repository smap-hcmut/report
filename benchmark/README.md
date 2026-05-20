# SMAP Benchmark Kit

Muc tieu cua package nay la benchmark he thong SMAP bang tool pho bien, co raw evidence va report co the dua thang vao tai lieu do an.

## Scope mac dinh

- Domain live: `https://smap.tantai.dev`
- Namespace Kubernetes: `smap`
- Campaign benchmark: `5cc6763f-3ec5-4481-9c7b-597bd5bb6126`
- Project benchmark: `d25fe723-a407-4a77-ac69-1556749f51ff`

Benchmark tap trung vao cac luong marketing user dung nhieu:

- Health/API gateway.
- Dashboard analytics: KPI, platform split, sentiment split, keyword ranking.
- Insight feed: latest posts, engagement-sorted posts, pagination.
- Project stats va heap chart.
- AI quality: sentiment label tren mau du lieu thuc da crawl, co gold label thu cong.

## Tooling

| Nhom do | Tool chinh | Ly do dung |
| --- | --- | --- |
| API smoke va latency | k6 | Lightweight, co summary JSON va threshold ro rang. |
| Concurrent users | Locust | Mo phong user behavior bang Python, de chay matrix 5/10/25/50 users. |
| Load-test artefact chuan bao cao | Apache JMeter | Pho bien trong bao cao NFR, sinh JTL de trace request-level. |
| API contract smoke | Postman/Newman | De doc voi team, de export raw execution JSON. |
| AI/ML metric | Python evaluator | Tinh precision, recall, F1 va confusion matrix tren gold labels. |
| Runtime evidence | kubectl, RabbitMQ CLI, Redpanda rpk | Ghi lai pod health, resource, queue backlog, Kafka group state truoc/sau benchmark. |

## Chay nhanh

```bash
cd /Users/tantai/Workspaces/smap/report/benchmark
cp config/benchmark.env.example config/benchmark.env
./scripts/run_all.sh
```

Script se tao thu muc `reports/<timestamp>/` gom:

- `raw/`: output goc cua tung tool.
- `charts/`: chart SVG de chen vao bao cao.
- `benchmark-report.md`: tai lieu tong hop so lieu va nhan dinh.

## Luu y benchmark live

Day la benchmark tren homelab production domain, nen mac dinh chay controlled load thay vi co tinh danh sap he thong. Neu can tim hard limit, chay rieng Locust/JMeter o thoi diem maintenance va tang `LOAD_USERS_MATRIX`.
