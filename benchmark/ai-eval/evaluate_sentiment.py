#!/usr/bin/env python3
import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


LABELS = ["negative", "neutral", "positive"]


def read_jsonl(path: Path):
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, 1):
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            for key in ("id", "predicted", "gold"):
                if key not in row:
                    raise ValueError(f"{path}:{line_no} missing {key}")
            row["predicted"] = normalize(row["predicted"])
            row["gold"] = normalize(row["gold"])
            rows.append(row)
    return rows


def normalize(value: str) -> str:
    value = str(value).strip().lower()
    aliases = {
        "neg": "negative",
        "neu": "neutral",
        "pos": "positive",
        "tieu cuc": "negative",
        "trung tinh": "neutral",
        "tich cuc": "positive",
    }
    value = aliases.get(value, value)
    if value not in LABELS:
        raise ValueError(f"unsupported sentiment label: {value}")
    return value


def safe_div(num: float, den: float) -> float:
    return num / den if den else 0.0


def evaluate(rows):
    matrix = {gold: {pred: 0 for pred in LABELS} for gold in LABELS}
    for row in rows:
        matrix[row["gold"]][row["predicted"]] += 1

    per_label = {}
    for label in LABELS:
        tp = matrix[label][label]
        fp = sum(matrix[gold][label] for gold in LABELS if gold != label)
        fn = sum(matrix[label][pred] for pred in LABELS if pred != label)
        support = sum(matrix[label].values())
        precision = safe_div(tp, tp + fp)
        recall = safe_div(tp, tp + fn)
        f1 = safe_div(2 * precision * recall, precision + recall)
        per_label[label] = {
            "precision": precision,
            "recall": recall,
            "f1": f1,
            "support": support,
            "tp": tp,
            "fp": fp,
            "fn": fn,
        }

    total = len(rows)
    correct = sum(matrix[label][label] for label in LABELS)
    macro = {
        metric: sum(per_label[label][metric] for label in LABELS) / len(LABELS)
        for metric in ("precision", "recall", "f1")
    }
    weighted = {
        metric: safe_div(
            sum(per_label[label][metric] * per_label[label]["support"] for label in LABELS),
            total,
        )
        for metric in ("precision", "recall", "f1")
    }
    by_relevance = Counter(row.get("relevance", "unknown") for row in rows)
    return {
        "sample_size": total,
        "accuracy": safe_div(correct, total),
        "macro": macro,
        "weighted": weighted,
        "labels": per_label,
        "confusion_matrix": matrix,
        "gold_distribution": Counter(row["gold"] for row in rows),
        "predicted_distribution": Counter(row["predicted"] for row in rows),
        "relevance_distribution": by_relevance,
    }


def write_outputs(metrics, rows, output_dir: Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    json_ready = json.loads(json.dumps(metrics))
    (output_dir / "sentiment_metrics.json").write_text(
        json.dumps(json_ready, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    with (output_dir / "sentiment_confusion_matrix.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["gold\\predicted"] + LABELS)
        for gold in LABELS:
            writer.writerow([gold] + [metrics["confusion_matrix"][gold][pred] for pred in LABELS])

    with (output_dir / "sentiment_classification_report.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["label", "precision", "recall", "f1", "support", "tp", "fp", "fn"])
        for label in LABELS:
            row = metrics["labels"][label]
            writer.writerow([
                label,
                f"{row['precision']:.4f}",
                f"{row['recall']:.4f}",
                f"{row['f1']:.4f}",
                row["support"],
                row["tp"],
                row["fp"],
                row["fn"],
            ])
        writer.writerow(["macro", f"{metrics['macro']['precision']:.4f}", f"{metrics['macro']['recall']:.4f}", f"{metrics['macro']['f1']:.4f}", metrics["sample_size"], "", "", ""])
        writer.writerow(["weighted", f"{metrics['weighted']['precision']:.4f}", f"{metrics['weighted']['recall']:.4f}", f"{metrics['weighted']['f1']:.4f}", metrics["sample_size"], "", "", ""])

    wrong = [row for row in rows if row["predicted"] != row["gold"]]
    with (output_dir / "sentiment_misclassifications.md").open("w", encoding="utf-8") as handle:
        handle.write("# Sentiment Misclassifications\n\n")
        for row in wrong:
            handle.write(
                f"- `{row['id']}` platform={row.get('platform','unknown')} "
                f"predicted={row['predicted']} gold={row['gold']} relevance={row.get('relevance','unknown')}: "
                f"{row.get('content','')}\n"
            )


def main():
    parser = argparse.ArgumentParser(description="Evaluate SMAP sentiment labels against a manually labeled gold sample.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    rows = read_jsonl(args.input)
    metrics = evaluate(rows)
    write_outputs(metrics, rows, args.output_dir)
    print(json.dumps({
        "sample_size": metrics["sample_size"],
        "accuracy": round(metrics["accuracy"], 4),
        "macro_f1": round(metrics["macro"]["f1"], 4),
        "weighted_f1": round(metrics["weighted"]["f1"], 4),
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
