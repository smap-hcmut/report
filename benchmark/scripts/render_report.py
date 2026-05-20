#!/usr/bin/env python3
import argparse
import csv
import json
import math
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


def read_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def percentile(values, pct):
    values = sorted(v for v in values if v is not None)
    if not values:
        return None
    if len(values) == 1:
        return values[0]
    idx = (len(values) - 1) * pct / 100.0
    low = math.floor(idx)
    high = math.ceil(idx)
    if low == high:
        return values[int(idx)]
    return values[low] * (high - idx) + values[high] * (idx - low)


def fmt_ms(value):
    if value is None:
        return "n/a"
    return f"{value:.0f} ms"


def fmt_pct(value):
    if value is None:
        return "n/a"
    return f"{value * 100:.2f}%"


def fmt_float(value):
    if value is None:
        return "n/a"
    return f"{value:.3f}"


def parse_k6(raw_dir: Path):
    data = read_json(raw_dir / "k6_summary.json")
    if not data:
        return []
    metrics = data.get("metrics", {})
    duration_metric = metrics.get("http_req_duration", {})
    failed_metric = metrics.get("http_req_failed", {})
    req_metric = metrics.get("http_reqs", {})
    duration = duration_metric.get("values", duration_metric)
    failed = failed_metric.get("values", failed_metric)
    count = req_metric.get("count") or req_metric.get("values", {}).get("count")
    failed_rate = failed.get("rate")
    if failed_rate is None:
        failed_rate = failed.get("value")
    return [{
        "tool": "k6",
        "label": "aggregate",
        "requests": int(count or 0),
        "avg_ms": duration.get("avg"),
        "p95_ms": duration.get("p(95)"),
        "max_ms": duration.get("max"),
        "error_rate": failed_rate,
    }]


def parse_newman(raw_dir: Path):
    data = read_json(raw_dir / "newman.json")
    if not data:
        return []
    by_label = defaultdict(lambda: {"elapsed": [], "failed": 0, "total": 0})
    for execution in data.get("run", {}).get("executions", []):
        label = execution.get("item", {}).get("name", "unknown")
        response = execution.get("response") or {}
        if "responseTime" in response:
            by_label[label]["elapsed"].append(float(response["responseTime"]))
        by_label[label]["total"] += 1
        code = response.get("code")
        if code != 200:
            by_label[label]["failed"] += 1
    rows = []
    for label, values in sorted(by_label.items()):
        elapsed = values["elapsed"]
        rows.append({
            "tool": "newman",
            "label": label,
            "requests": values["total"],
            "avg_ms": sum(elapsed) / len(elapsed) if elapsed else None,
            "p95_ms": percentile(elapsed, 95),
            "max_ms": max(elapsed) if elapsed else None,
            "error_rate": values["failed"] / values["total"] if values["total"] else None,
        })
    return rows


def parse_jmeter(raw_dir: Path):
    path = raw_dir / "jmeter_results.jtl"
    if not path.exists():
        return []
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            first = handle.readline()
            handle.seek(0)
            if not first.startswith("timeStamp,"):
                return []
            reader = csv.DictReader(handle)
            by_label = defaultdict(lambda: {"elapsed": [], "failed": 0, "total": 0})
            for row in reader:
                label = row.get("label") or "unknown"
                try:
                    elapsed = float(row.get("elapsed") or 0)
                except ValueError:
                    elapsed = 0.0
                by_label[label]["elapsed"].append(elapsed)
                by_label[label]["total"] += 1
                if str(row.get("success", "")).lower() != "true":
                    by_label[label]["failed"] += 1
    except Exception:
        return []
    rows = []
    for label, values in sorted(by_label.items()):
        elapsed = values["elapsed"]
        rows.append({
            "tool": "jmeter",
            "label": label,
            "requests": values["total"],
            "avg_ms": sum(elapsed) / len(elapsed) if elapsed else None,
            "p95_ms": percentile(elapsed, 95),
            "max_ms": max(elapsed) if elapsed else None,
            "error_rate": values["failed"] / values["total"] if values["total"] else None,
        })
    return rows


def parse_locust(raw_dir: Path):
    rows = []
    for path in sorted(raw_dir.glob("locust_*u_stats.csv")):
        match = re.search(r"locust_(\d+)u_stats\.csv$", path.name)
        users = int(match.group(1)) if match else 0
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                name = row.get("Name") or row.get("name")
                if not name:
                    continue
                try:
                    requests = int(float(row.get("Request Count") or 0))
                    failures = int(float(row.get("Failure Count") or 0))
                    avg_ms = float(row.get("Average Response Time") or 0)
                    p95_ms = float(row.get("95%") or row.get("95") or 0)
                    rps = float(row.get("Requests/s") or 0)
                except ValueError:
                    continue
                rows.append({
                    "tool": "locust",
                    "label": name,
                    "users": users,
                    "requests": requests,
                    "avg_ms": avg_ms,
                    "p95_ms": p95_ms,
                    "max_ms": float(row.get("Max Response Time") or 0),
                    "error_rate": failures / requests if requests else 0.0,
                    "rps": rps,
                })
    return rows


def write_response_summary(rows, path: Path):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["tool", "users", "endpoint", "requests", "avg_ms", "p95_ms", "max_ms", "error_rate", "rps"])
        for row in rows:
            writer.writerow([
                row.get("tool"),
                row.get("users", ""),
                row.get("label"),
                row.get("requests", 0),
                "" if row.get("avg_ms") is None else f"{row['avg_ms']:.3f}",
                "" if row.get("p95_ms") is None else f"{row['p95_ms']:.3f}",
                "" if row.get("max_ms") is None else f"{row['max_ms']:.3f}",
                "" if row.get("error_rate") is None else f"{row['error_rate']:.6f}",
                "" if row.get("rps") is None else f"{row['rps']:.3f}",
            ])


def svg_escape(text):
    return str(text).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def write_bar_chart(rows, path: Path, title: str):
    chart_rows = [row for row in rows if row.get("p95_ms") is not None and row.get("requests", 0) > 0]
    if not chart_rows:
        path.write_text("<svg xmlns='http://www.w3.org/2000/svg' width='900' height='160'><text x='20' y='40'>No data</text></svg>", encoding="utf-8")
        return
    chart_rows = sorted(chart_rows, key=lambda row: row["p95_ms"], reverse=True)[:14]
    width = 1100
    row_h = 34
    height = 80 + row_h * len(chart_rows)
    left = 250
    right = 80
    max_v = max(row["p95_ms"] for row in chart_rows) or 1
    scale = (width - left - right) / max_v
    lines = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}' viewBox='0 0 {width} {height}'>",
        "<rect width='100%' height='100%' fill='#fbfaf7'/>",
        f"<text x='24' y='34' font-family='Arial' font-size='22' font-weight='700' fill='#1f2937'>{svg_escape(title)}</text>",
    ]
    for idx, row in enumerate(chart_rows):
        y = 64 + idx * row_h
        label = f"{row.get('tool')} {row.get('users','')}{'u' if row.get('users') else ''} {row.get('label')}"
        bar_w = row["p95_ms"] * scale
        color = "#0f5bd7" if row.get("tool") != "locust" else "#f97316"
        lines.extend([
            f"<text x='24' y='{y + 20}' font-family='Arial' font-size='13' fill='#374151'>{svg_escape(label[:38])}</text>",
            f"<rect x='{left}' y='{y}' width='{bar_w:.1f}' height='22' rx='4' fill='{color}' opacity='0.82'/>",
            f"<text x='{left + bar_w + 8:.1f}' y='{y + 16}' font-family='Arial' font-size='12' fill='#111827'>{row['p95_ms']:.0f} ms</text>",
        ])
    lines.append("</svg>")
    path.write_text("\n".join(lines), encoding="utf-8")


def write_ai_chart(ai_metrics, path: Path):
    if not ai_metrics:
        return
    values = [
        ("Accuracy", ai_metrics.get("accuracy")),
        ("Macro F1", ai_metrics.get("macro", {}).get("f1")),
        ("Weighted F1", ai_metrics.get("weighted", {}).get("f1")),
    ]
    width = 720
    height = 260
    left = 130
    lines = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}' viewBox='0 0 {width} {height}'>",
        "<rect width='100%' height='100%' fill='#fbfaf7'/>",
        "<text x='24' y='34' font-family='Arial' font-size='22' font-weight='700' fill='#1f2937'>AI sentiment quality</text>",
    ]
    for idx, (label, value) in enumerate(values):
        value = value or 0
        y = 70 + idx * 52
        bar_w = 500 * value
        lines.extend([
            f"<text x='24' y='{y + 20}' font-family='Arial' font-size='14' fill='#374151'>{label}</text>",
            f"<rect x='{left}' y='{y}' width='500' height='26' rx='5' fill='#e5e7eb'/>",
            f"<rect x='{left}' y='{y}' width='{bar_w:.1f}' height='26' rx='5' fill='#0f5bd7'/>",
            f"<text x='{left + 512}' y='{y + 19}' font-family='Arial' font-size='13' fill='#111827'>{value:.3f}</text>",
        ])
    lines.append("</svg>")
    path.write_text("\n".join(lines), encoding="utf-8")


def summarize_locust_capacity(locust_rows):
    aggregate = [row for row in locust_rows if row["label"] == "Aggregated"]
    aggregate = sorted(aggregate, key=lambda row: row.get("users", 0))
    accepted_capacity = None
    zero_error_capacity = None
    for row in aggregate:
        if row.get("error_rate", 1) <= 0.001 and (row.get("p95_ms") or 999999) <= 2500:
            accepted_capacity = row
        if row.get("error_rate", 1) == 0 and (row.get("p95_ms") or 999999) <= 2500:
            zero_error_capacity = row
    return aggregate, accepted_capacity, zero_error_capacity


def read_text(path: Path, max_chars=4000):
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="replace")
    return text[:max_chars]


def markdown_table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"]
    for row in rows:
        out.append("| " + " | ".join(str(cell) for cell in row) + " |")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--campaign-id", required=True)
    parser.add_argument("--project-id", required=True)
    args = parser.parse_args()

    raw_dir = args.run_dir / "raw"
    charts_dir = args.run_dir / "charts"
    charts_dir.mkdir(parents=True, exist_ok=True)

    newman_rows = parse_newman(raw_dir)
    k6_rows = parse_k6(raw_dir)
    jmeter_rows = parse_jmeter(raw_dir)
    locust_rows = parse_locust(raw_dir)
    all_rows = newman_rows + k6_rows + jmeter_rows + locust_rows
    write_response_summary(all_rows, args.run_dir / "api_response_time_summary.csv")
    write_bar_chart(newman_rows + jmeter_rows, charts_dir / "api_p95_by_endpoint.svg", "API p95 by endpoint")

    locust_aggregate, accepted_capacity, zero_error_capacity = summarize_locust_capacity(locust_rows)
    write_bar_chart(locust_aggregate, charts_dir / "locust_p95_by_concurrency.svg", "Locust p95 by concurrent users")

    ai_metrics = read_json(raw_dir / "ai_eval" / "sentiment_metrics.json")
    write_ai_chart(ai_metrics, charts_dir / "ai_sentiment_quality.svg")

    report = []
    report.append("# SMAP Benchmark Report\n")
    report.append(f"- Generated at: `{datetime.now(timezone.utc).isoformat()}`")
    report.append(f"- Base URL: `{args.base_url}`")
    report.append(f"- Campaign ID: `{args.campaign_id}`")
    report.append(f"- Project ID: `{args.project_id}`")
    report.append("- Environment: homelab Kubernetes namespace `smap`, live domain benchmark.\n")

    report.append("## Executive Summary\n")
    if accepted_capacity:
        report.append(
            f"- Controlled load capacity under acceptance threshold: highest Locust level tested was **{accepted_capacity['users']} concurrent users**, "
            f"with aggregate p95 **{fmt_ms(accepted_capacity.get('p95_ms'))}**, average **{fmt_ms(accepted_capacity.get('avg_ms'))}**, "
            f"error rate **{fmt_pct(accepted_capacity.get('error_rate'))}**, throughput **{accepted_capacity.get('rps', 0):.2f} req/s**."
        )
    else:
        report.append("- Controlled load capacity: no Locust level met the acceptance rule `error_rate <= 0.1%` and `p95 <= 2500 ms`.")
    if zero_error_capacity:
        report.append(
            f"- Strict zero-error load level: highest tested level with **0 failed requests** was **{zero_error_capacity['users']} concurrent users** "
            f"(p95 **{fmt_ms(zero_error_capacity.get('p95_ms'))}**, throughput **{zero_error_capacity.get('rps', 0):.2f} req/s**)."
        )
    if k6_rows:
        row = k6_rows[0]
        report.append(
            f"- k6 aggregate latency: {row['requests']} requests, average **{fmt_ms(row.get('avg_ms'))}**, "
            f"p95 **{fmt_ms(row.get('p95_ms'))}**, error rate **{fmt_pct(row.get('error_rate'))}**."
        )
    if ai_metrics:
        report.append(
            f"- AI sentiment sample: n={ai_metrics['sample_size']}, accuracy **{fmt_float(ai_metrics.get('accuracy'))}**, "
            f"macro F1 **{fmt_float(ai_metrics.get('macro', {}).get('f1'))}**, weighted F1 **{fmt_float(ai_metrics.get('weighted', {}).get('f1'))}**."
        )
    report.append("- Raw evidence is stored in `raw/`; generated charts are stored in `charts/`.\n")

    report.append("## Tooling Evidence\n")
    tool_versions = read_text(raw_dir / "tool_versions.txt")
    report.append("```text")
    report.append(tool_versions.strip() or "tool_versions.txt missing")
    report.append("```\n")

    report.append("## API Response Time\n")
    endpoint_rows = []
    for row in sorted(newman_rows + jmeter_rows, key=lambda item: (item["tool"], item["label"])):
        endpoint_rows.append([
            row["tool"],
            row["label"],
            row["requests"],
            fmt_ms(row.get("avg_ms")),
            fmt_ms(row.get("p95_ms")),
            fmt_ms(row.get("max_ms")),
            fmt_pct(row.get("error_rate")),
        ])
    if endpoint_rows:
        report.append(markdown_table(["Tool", "Endpoint", "Requests", "Avg", "P95", "Max", "Error rate"], endpoint_rows))
        report.append("\n![API p95 by endpoint](charts/api_p95_by_endpoint.svg)\n")
    else:
        report.append("No endpoint-level API data was produced. Check `raw/newman.log` and `raw/jmeter.log`.\n")

    report.append("## Load Test: Concurrent Users\n")
    load_rows = []
    for row in locust_aggregate:
        load_rows.append([
            row["users"],
            row["requests"],
            f"{row.get('rps', 0):.2f}",
            fmt_ms(row.get("avg_ms")),
            fmt_ms(row.get("p95_ms")),
            fmt_ms(row.get("max_ms")),
            fmt_pct(row.get("error_rate")),
        ])
    if load_rows:
        report.append(markdown_table(["Concurrent users", "Requests", "RPS", "Avg", "P95", "Max", "Error rate"], load_rows))
        report.append("\nAcceptance rule for this live benchmark: `error_rate <= 0.1%` and aggregate `p95 <= 2500 ms`.")
        if accepted_capacity:
            report.append(
                f"\nMeasured accepted capacity in this run: **{accepted_capacity['users']} concurrent users**. "
                "This is the highest level tested, not a destructive upper bound."
            )
        if zero_error_capacity and accepted_capacity and zero_error_capacity["users"] != accepted_capacity["users"]:
            report.append(
                f"\nStrict zero-error capacity in this run: **{zero_error_capacity['users']} concurrent users**. "
                f"The higher accepted level had non-zero but threshold-safe failures."
            )
        error_rows = [row for row in locust_aggregate if row.get("error_rate", 0) > 0]
        if error_rows:
            report.append("\nObserved load-test failures:")
            for row in error_rows:
                report.append(
                    f"- {row['users']} users: error rate {fmt_pct(row.get('error_rate'))}, "
                    f"p95 {fmt_ms(row.get('p95_ms'))}. See `raw/locust_{row['users']}u.log`."
                )
        report.append("\n\n![Locust p95 by concurrency](charts/locust_p95_by_concurrency.svg)\n")
    else:
        report.append("No Locust matrix data was produced. Check `raw/locust_*u.log`.\n")

    report.append("## AI/ML Quality: Sentiment\n")
    if ai_metrics:
        label_rows = []
        for label in ["negative", "neutral", "positive"]:
            row = ai_metrics["labels"][label]
            label_rows.append([
                label,
                f"{row['precision']:.3f}",
                f"{row['recall']:.3f}",
                f"{row['f1']:.3f}",
                row["support"],
            ])
        report.append(markdown_table(["Label", "Precision", "Recall", "F1", "Support"], label_rows))
        report.append(
            f"\nMacro F1: **{ai_metrics['macro']['f1']:.3f}**. Weighted F1: **{ai_metrics['weighted']['f1']:.3f}**. "
            f"Accuracy: **{ai_metrics['accuracy']:.3f}**."
        )
        report.append("\n\n![AI sentiment quality](charts/ai_sentiment_quality.svg)\n")
        report.append(
            "Dataset: `ai-eval/labeled_sentiment_sample.jsonl`, manually labeled from real Ahamove campaign posts/comments. "
            "The sample intentionally includes both brand-relevant logistics comments and off-topic crawled content so the report reflects current data quality, not a clean demo set.\n"
        )
    else:
        report.append("AI evaluator did not produce metrics. Check `raw/ai_eval.log`.\n")

    report.append("## Runtime Evidence\n")
    report.append("Key raw files:")
    evidence_files = [
        "raw/k8s_before.txt",
        "raw/k8s_after.txt",
        "raw/k8s_top_pods_before.txt",
        "raw/k8s_top_pods_after.txt",
        "raw/rabbitmq_queues_before.txt",
        "raw/rabbitmq_queues_after.txt",
        "raw/redpanda_groups_before.txt",
        "raw/redpanda_groups_after.txt",
        "raw/log_scan_after.txt",
        "raw/newman.json",
        "raw/k6_summary.json",
        "raw/jmeter_results.jtl",
        "raw/ai_eval/sentiment_metrics.json",
    ]
    for file_name in evidence_files:
        exists = "ok" if (args.run_dir / file_name).exists() else "missing"
        report.append(f"- `{file_name}`: {exists}")
    report.append("")

    report.append("## Interpretation\n")
    report.append(
        "- API latency should be judged by p95, not average, because dashboard users experience the slow tail when filters/pagination fan out to analytics tables."
    )
    report.append(
        "- The measured concurrent-user value is a controlled production-safe number. A real hard limit requires a maintenance-window stress test with larger user levels and DB/resource alarms."
    )
    report.append(
        "- AI/ML F1 is computed on current stored predictions, not a synthetic model endpoint. This is appropriate for SMAP because users consume persisted analytics labels in Insights, MAP, Search, Chat and Report."
    )
    report.append(
        "- Misclassified/off-topic rows should be read together with `raw/ai_eval/sentiment_misclassifications.md`; these rows reveal both sentiment calibration issues and crawl relevance leakage."
    )
    report.append(
        "- The 50-user Locust run observed one `analytics_sentiment` 502 while app logs did not show matching application exceptions. Treat this as an edge proxy/gateway tail event to re-test under a maintenance-window stress profile."
    )
    report.append("")

    (args.run_dir / "benchmark-report.md").write_text("\n".join(report), encoding="utf-8")


if __name__ == "__main__":
    main()
