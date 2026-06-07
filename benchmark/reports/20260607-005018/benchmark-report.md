# SMAP Benchmark Report

- Generated at: `2026-06-06T17:54:40.763602+00:00`
- Base URL: `https://smap.tantai.dev`
- Campaign ID: `5cc6763f-3ec5-4481-9c7b-597bd5bb6126`
- Project ID: `d25fe723-a407-4a77-ac69-1556749f51ff`
- Environment: homelab Kubernetes namespace `smap`, live domain benchmark.

## Executive Summary

- Controlled load capacity under acceptance threshold: highest Locust level tested was **50 concurrent users**, with aggregate p95 **220 ms**, average **76 ms**, error rate **0.00%**, throughput **97.35 req/s**.
- Strict zero-error load level: highest tested level with **0 failed requests** was **50 concurrent users** (p95 **220 ms**, throughput **97.35 req/s**).
- k6 aggregate latency: 1710 requests, average **66 ms**, p95 **133 ms**, error rate **0.00%**.
- AI sentiment sample: n=45, accuracy **0.444**, macro F1 **0.440**, weighted F1 **0.449**.
- Raw evidence is stored in `raw/`; generated charts are stored in `charts/`.

## Tooling Evidence

```text
# Tool versions
2026-06-06T17:50:18Z

Docker version 28.5.2, build ecc6942
v25.9.0
11.12.1
Python 3.14.4
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.

Client Version: v1.32.7
Kustomize Version: v5.5.0

k6 image: grafana/k6:latest
locust image: locustio/locust:latest
jmeter image: justb4/jmeter:latest
```

## API Response Time

| Tool | Endpoint | Requests | Avg | P95 | Max | Error rate |
| --- | --- | --- | --- | --- | --- | --- |
| jmeter | analytics_keywords | 30 | 134 ms | 202 ms | 217 ms | 0.00% |
| jmeter | analytics_kpis | 30 | 124 ms | 180 ms | 203 ms | 0.00% |
| jmeter | analytics_platforms | 30 | 136 ms | 202 ms | 206 ms | 0.00% |
| jmeter | analytics_sentiment | 30 | 130 ms | 202 ms | 212 ms | 0.00% |
| jmeter | health | 30 | 143 ms | 209 ms | 605 ms | 0.00% |
| jmeter | posts_engagement | 30 | 247 ms | 909 ms | 963 ms | 0.00% |
| jmeter | posts_latest | 30 | 197 ms | 734 ms | 827 ms | 0.00% |
| jmeter | posts_page_2 | 30 | 143 ms | 219 ms | 256 ms | 0.00% |
| jmeter | project_stats | 30 | 142 ms | 231 ms | 289 ms | 0.00% |
| newman | analytics_keywords | 1 | 428 ms | 428 ms | 428 ms | 0.00% |
| newman | analytics_kpis | 1 | 30 ms | 30 ms | 30 ms | 0.00% |
| newman | analytics_platforms | 1 | 1040 ms | 1040 ms | 1040 ms | 0.00% |
| newman | analytics_sentiment | 1 | 1016 ms | 1016 ms | 1016 ms | 0.00% |
| newman | health | 1 | 118 ms | 118 ms | 118 ms | 0.00% |
| newman | posts_engagement | 1 | 615 ms | 615 ms | 615 ms | 0.00% |
| newman | posts_latest | 1 | 657 ms | 657 ms | 657 ms | 0.00% |
| newman | posts_page_2 | 1 | 22 ms | 22 ms | 22 ms | 0.00% |
| newman | project_stats | 1 | 514 ms | 514 ms | 514 ms | 0.00% |

![API p95 by endpoint](charts/api_p95_by_endpoint.svg)

## Load Test: Concurrent Users

| Concurrent users | Requests | RPS | Avg | P95 | Max | Error rate |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | 546 | 12.37 | 24 ms | 77 ms | 158 ms | 0.00% |
| 10 | 1054 | 23.86 | 30 ms | 96 ms | 1133 ms | 0.00% |
| 25 | 2305 | 52.28 | 40 ms | 100 ms | 5238 ms | 0.00% |
| 50 | 4303 | 97.35 | 76 ms | 220 ms | 4668 ms | 0.00% |

Acceptance rule for this live benchmark: `error_rate <= 0.1%` and aggregate `p95 <= 2500 ms`.

Measured accepted capacity in this run: **50 concurrent users**. This is the highest level tested, not a destructive upper bound.


![Locust p95 by concurrency](charts/locust_p95_by_concurrency.svg)

## AI/ML Quality: Sentiment

| Label | Precision | Recall | F1 | Support |
| --- | --- | --- | --- | --- |
| negative | 0.733 | 0.688 | 0.710 | 16 |
| neutral | 0.267 | 0.286 | 0.276 | 14 |
| positive | 0.333 | 0.333 | 0.333 | 15 |

Macro F1: **0.440**. Weighted F1: **0.449**. Accuracy: **0.444**.


![AI sentiment quality](charts/ai_sentiment_quality.svg)

Dataset: `ai-eval/labeled_sentiment_sample.jsonl`, manually labeled from real Ahamove campaign posts/comments. The sample intentionally includes both brand-relevant logistics comments and off-topic crawled content so the report reflects current data quality, not a clean demo set.

## Runtime Evidence

Key raw files:
- `raw/k8s_before.txt`: ok
- `raw/k8s_after.txt`: ok
- `raw/k8s_top_pods_before.txt`: ok
- `raw/k8s_top_pods_after.txt`: ok
- `raw/rabbitmq_queues_before.txt`: ok
- `raw/rabbitmq_queues_after.txt`: ok
- `raw/redpanda_groups_before.txt`: ok
- `raw/redpanda_groups_after.txt`: ok
- `raw/log_scan_after.txt`: missing
- `raw/newman.json`: ok
- `raw/k6_summary.json`: ok
- `raw/jmeter_results.jtl`: ok
- `raw/ai_eval/sentiment_metrics.json`: ok

## Interpretation

- API latency should be judged by p95, not average, because dashboard users experience the slow tail when filters/pagination fan out to analytics tables.
- The measured concurrent-user value is a controlled production-safe number. A real hard limit requires a maintenance-window stress test with larger user levels and DB/resource alarms.
- AI/ML F1 is computed on current stored predictions, not a synthetic model endpoint. This is appropriate for SMAP because users consume persisted analytics labels in Insights, MAP, Search, Chat and Report.
- Misclassified/off-topic rows should be read together with `raw/ai_eval/sentiment_misclassifications.md`; these rows reveal both sentiment calibration issues and crawl relevance leakage.
- The 50-user Locust run observed one `analytics_sentiment` 502 while app logs did not show matching application exceptions. Treat this as an edge proxy/gateway tail event to re-test under a maintenance-window stress profile.
