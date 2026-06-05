# SMAP Stability Fix Report

Date: 2026-06-05

Scope: remove Longhorn from SMAP runtime-critical infra where data loss is acceptable, recover Redis/RabbitMQ, and verify namespace health.

## Changes applied

### Redis

Changed:

```text
smap-deploy/infrastructure/redis/statefulset.yaml
```

From:

```text
StatefulSet volumeClaimTemplates -> Longhorn PVC redis-data-redis-0
```

To:

```text
emptyDir volume redis-data
```

Reason: Redis is cache/session/pubsub for this deployment. Losing Redis data on restart is acceptable; Redis must not block SMAP because of Longhorn volume failure.

### RabbitMQ

Changed:

```text
smap-deploy/infrastructure/rabbitmq/statefulset.yaml
```

From:

```text
StatefulSet volumeClaimTemplates -> Longhorn PVC rabbitmq-data-rabbitmq-0
```

To:

```text
emptyDir volume rabbitmq-data
```

Reason: RabbitMQ is runtime queueing for the thesis environment. Queue data loss during restart is acceptable; crawler dispatch should recover through ingest/task idempotency instead of relying on a fragile single Longhorn PVC.

### Live cluster operations

Executed on `homelab`, namespace `smap`:

```text
Scaled down StatefulSets redis and rabbitmq.
Deleted old StatefulSets because volumeClaimTemplates are immutable.
Deleted old Longhorn PVCs:
  redis-data-redis-0
  rabbitmq-data-rabbitmq-0
  redpanda-data-redpanda-0
Deleted old Longhorn Volume CRs:
  pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837
  pvc-41cab2cf-a17e-4233-a1c4-67fa1a79b2b6
  pvc-f4b92a24-aa78-4466-95e6-fe821674f4fb
Re-applied Redis and RabbitMQ manifests with emptyDir.
Waited for Redis/RabbitMQ rollouts.
```

Also reduced Longhorn `csi-snapshotter` deployment from 3 replicas to 1 to stop two crash-looping snapshotter pods. One snapshotter pod remains running.

## Final health snapshot

Observed after rollout and a 90-second stabilization window.

### SMAP workloads

All SMAP pods are running and ready:

```text
analysis-api        1/1 Running
analysis-consumer   2/2 Running
identity-srv        1/1 Running
ingest-srv          1/1 Running
knowledge-srv       1/1 Running
notification-srv    1/1 Running
project-srv         1/1 Running
rabbitmq            1/1 Running
redis               1/1 Running
redpanda            1/1 Running
scapper-srv         1/1 Running
smap-ui             1/1 Running
smap-portal         1/1 Running
logging pods        Running
```

Deployments:

```text
analysis-api        1/1 available
analysis-consumer   2/2 available
identity-srv        1/1 available
ingest-srv          1/1 available
knowledge-srv       1/1 available
notification-srv    1/1 available
project-srv         1/1 available
scapper-srv         1/1 available
smap-ui             1/1 available
```

StatefulSets:

```text
redis      1/1 ready
rabbitmq   1/1 ready
redpanda   1/1 ready
```

No PVC remains in namespace `smap`.

### Internal checks

Redis:

```text
redis-cli ping -> PONG
```

RabbitMQ:

```text
rabbitmq-diagnostics ping -> Ping succeeded
rabbitmq-diagnostics check_running -> fully booted and running
```

### Longhorn after cleanup

The broken SMAP Longhorn volumes were removed.

Remaining Longhorn volumes:

```text
pvc-06a66bad-a6dd-4348-b041-109820173620   attached healthy
pvc-a34c349e-d4eb-4005-aee1-dcc3c55975b1   attached healthy
```

These are not SMAP Redis/RabbitMQ/Redpanda runtime volumes.

Longhorn snapshotter after scaling:

```text
csi-snapshotter-589df8768f-czbsj 1/1 Running
```

## Important caveats

This fix makes SMAP resilient against the specific Longhorn failure that broke Redis/RabbitMQ/Redpanda runtime dependencies.

It does not make Longhorn itself production-grade. Longhorn is still `v1.5.3`, which should be upgraded one minor version at a time after the demo/report window.

It also does not remove dependency on external PostgreSQL, MinIO, Qdrant, or the node/control-plane stability of K3s itself.

## Current operational stance

For thesis/demo stability:

```text
Redis: disposable runtime cache
RabbitMQ: disposable runtime queue
Redpanda: already disposable emptyDir in current manifest
SMAP namespace: no Longhorn PVC dependency
```

This is the right tradeoff for a graduation-project environment where uptime during demo/report matters more than preserving transient queue/cache data.
