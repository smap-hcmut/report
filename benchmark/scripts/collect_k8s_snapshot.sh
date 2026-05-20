#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:?usage: collect_k8s_snapshot.sh OUT_DIR [phase]}"
PHASE="${2:-snapshot}"
NAMESPACE="${K8S_NAMESPACE:-smap}"
mkdir -p "$OUT_DIR"

{
  echo "# Kubernetes snapshot: $PHASE"
  date -u +"%Y-%m-%dT%H:%M:%SZ"
  echo
  echo "## context"
  kubectl config current-context
  echo
  echo "## deployments"
  kubectl -n "$NAMESPACE" get deploy -o wide
  echo
  echo "## pods"
  kubectl -n "$NAMESPACE" get pods -o wide
  echo
  echo "## recent warning events"
  kubectl -n "$NAMESPACE" get events --sort-by=.lastTimestamp | tail -80 || true
} > "$OUT_DIR/k8s_${PHASE}.txt"

kubectl -n "$NAMESPACE" top pods > "$OUT_DIR/k8s_top_pods_${PHASE}.txt" 2>&1 || true
kubectl -n "$NAMESPACE" top deploy > "$OUT_DIR/k8s_top_deploy_${PHASE}.txt" 2>&1 || true

RABBIT_POD="$(kubectl -n "$NAMESPACE" get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [ -n "$RABBIT_POD" ]; then
  kubectl -n "$NAMESPACE" exec "$RABBIT_POD" -- rabbitmqctl list_queues name messages_ready messages_unacknowledged consumers > "$OUT_DIR/rabbitmq_queues_${PHASE}.txt" 2>&1 || true
  kubectl -n "$NAMESPACE" exec "$RABBIT_POD" -- rabbitmqctl list_connections name state channels recv_oct send_oct > "$OUT_DIR/rabbitmq_connections_${PHASE}.txt" 2>&1 || true
fi

REDPANDA_POD="$(kubectl -n "$NAMESPACE" get pods -l app=redpanda -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [ -n "$REDPANDA_POD" ]; then
  kubectl -n "$NAMESPACE" exec "$REDPANDA_POD" -- rpk group list > "$OUT_DIR/redpanda_groups_${PHASE}.txt" 2>&1 || true
fi
