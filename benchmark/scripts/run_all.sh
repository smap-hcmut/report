#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/config/benchmark.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

BASE_URL="${BASE_URL:-https://smap.tantai.dev}"
K8S_NAMESPACE="${K8S_NAMESPACE:-smap}"
CAMPAIGN_ID="${CAMPAIGN_ID:-5cc6763f-3ec5-4481-9c7b-597bd5bb6126}"
PROJECT_ID="${PROJECT_ID:-d25fe723-a407-4a77-ac69-1556749f51ff}"
K6_IMAGE="${K6_IMAGE:-grafana/k6:latest}"
LOCUST_IMAGE="${LOCUST_IMAGE:-locustio/locust:latest}"
JMETER_IMAGE="${JMETER_IMAGE:-justb4/jmeter:latest}"
LOAD_USERS_MATRIX="${LOAD_USERS_MATRIX:-5,10,25,50}"
LOAD_RUN_TIME="${LOAD_RUN_TIME:-45s}"
LOAD_SPAWN_RATE="${LOAD_SPAWN_RATE:-5}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$ROOT_DIR/reports/$RUN_ID"
RAW_DIR="$OUT_DIR/raw"
mkdir -p "$RAW_DIR"

export BASE_URL K8S_NAMESPACE CAMPAIGN_ID PROJECT_ID

echo "[benchmark] run_id=$RUN_ID"
echo "[benchmark] output=$OUT_DIR"

{
  echo "# Tool versions"
  date -u +"%Y-%m-%dT%H:%M:%SZ"
  echo
  docker --version || true
  node --version || true
  npm --version || true
  python3 --version || true
  java -version 2>&1 || true
  kubectl version --client 2>&1 || true
  echo
  echo "k6 image: $K6_IMAGE"
  echo "locust image: $LOCUST_IMAGE"
  echo "jmeter image: $JMETER_IMAGE"
} > "$RAW_DIR/tool_versions.txt"

"$ROOT_DIR/scripts/collect_k8s_snapshot.sh" "$RAW_DIR" "before"

echo "[benchmark] running Newman/Postman smoke"
npx --yes newman run "$ROOT_DIR/newman/smap-api.postman_collection.json" \
  --env-var "baseUrl=$BASE_URL" \
  --env-var "campaignId=$CAMPAIGN_ID" \
  --env-var "projectId=$PROJECT_ID" \
  --reporters cli,json \
  --reporter-json-export "$RAW_DIR/newman.json" \
  > "$RAW_DIR/newman.log" 2>&1 || echo "[benchmark] newman failed; see raw/newman.log"

echo "[benchmark] running k6 latency smoke"
docker run --rm \
  -e BASE_URL="$BASE_URL" \
  -e CAMPAIGN_ID="$CAMPAIGN_ID" \
  -e PROJECT_ID="$PROJECT_ID" \
  -e K6_VUS="${K6_VUS:-10}" \
  -e K6_DURATION="${K6_DURATION:-45s}" \
  -v "$ROOT_DIR/k6:/scripts:ro" \
  -v "$RAW_DIR:/out" \
  "$K6_IMAGE" run --summary-export /out/k6_summary.json /scripts/smap_api_smoke.js \
  > "$RAW_DIR/k6.log" 2>&1 || echo "[benchmark] k6 failed; see raw/k6.log"

echo "[benchmark] running Locust concurrent-user matrix: $LOAD_USERS_MATRIX"
IFS=',' read -r -a USER_LEVELS <<< "$LOAD_USERS_MATRIX"
for users in "${USER_LEVELS[@]}"; do
  users="$(echo "$users" | tr -d '[:space:]')"
  [ -n "$users" ] || continue
  prefix="$RAW_DIR/locust_${users}u"
  echo "[benchmark] locust users=$users"
  docker run --rm \
    -e CAMPAIGN_ID="$CAMPAIGN_ID" \
    -e PROJECT_ID="$PROJECT_ID" \
    -v "$ROOT_DIR/locust:/mnt/locust:ro" \
    -v "$RAW_DIR:/out" \
    "$LOCUST_IMAGE" \
    -f /mnt/locust/locustfile.py \
    --host "$BASE_URL" \
    --headless \
    --users "$users" \
    --spawn-rate "$LOAD_SPAWN_RATE" \
    --run-time "$LOAD_RUN_TIME" \
    --csv "/out/locust_${users}u" \
    --html "/out/locust_${users}u.html" \
    > "${prefix}.log" 2>&1 || echo "[benchmark] locust users=$users failed; see ${prefix}.log"
done

echo "[benchmark] running Apache JMeter request-level benchmark"
docker run --rm \
  -v "$ROOT_DIR/jmeter:/tests:ro" \
  -v "$RAW_DIR:/out" \
  "$JMETER_IMAGE" \
  -n -t /tests/smap_api_benchmark.jmx \
  -Jbase_host="$(echo "$BASE_URL" | sed -E 's#^https?://##; s#/.*$##')" \
  -Jcampaign_id="$CAMPAIGN_ID" \
  -Jproject_id="$PROJECT_ID" \
  -Jthreads="${JMETER_THREADS:-10}" \
  -Jloops="${JMETER_LOOPS:-3}" \
  -Jramp_seconds="${JMETER_RAMP_SECONDS:-10}" \
  -l /out/jmeter_results.jtl \
  -j /out/jmeter.log \
  > "$RAW_DIR/jmeter.stdout.log" 2>&1 || echo "[benchmark] jmeter failed; see raw/jmeter.log"

echo "[benchmark] running AI sentiment quality evaluator"
python3 "$ROOT_DIR/ai-eval/evaluate_sentiment.py" \
  --input "$ROOT_DIR/ai-eval/labeled_sentiment_sample.jsonl" \
  --output-dir "$RAW_DIR/ai_eval" \
  > "$RAW_DIR/ai_eval.log" 2>&1 || echo "[benchmark] ai eval failed; see raw/ai_eval.log"

"$ROOT_DIR/scripts/collect_k8s_snapshot.sh" "$RAW_DIR" "after"

echo "[benchmark] rendering report"
python3 "$ROOT_DIR/scripts/render_report.py" \
  --run-dir "$OUT_DIR" \
  --base-url "$BASE_URL" \
  --campaign-id "$CAMPAIGN_ID" \
  --project-id "$PROJECT_ID"

echo "[benchmark] done: $OUT_DIR/benchmark-report.md"
