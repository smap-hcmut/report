# Longhorn/K3s Root-Cause Report for SMAP Homelab

Date: 2026-06-05

Goal: trace why Longhorn repeatedly breaks SMAP infra, especially Redis, and define the most durable remediation path.

## Executive conclusion

Redis is not failing because of Redis configuration. Redis is stuck because Kubernetes cannot stage the Longhorn block device for `redis-data-redis-0`.

The immediate failing object is:

```text
PVC: smap/redis-data-redis-0
PV / Longhorn volume: pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837
Pod: smap/redis-0
Node: k3s-03
```

The direct error is:

```text
MountVolume.MountDevice failed:
format of disk "/dev/longhorn/pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837" failed
mkfs.ext4: Input/output error while writing out and closing file system
```

Longhorn reports the Redis volume as:

```text
state=attached
robustness=unknown
numberOfReplicas=3
actualSize=0
currentNodeID=k3s-03
```

But Longhorn currently has only one visible running replica for this volume:

```text
pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837-r-84ccd809
state=running
node=k3s-03
```

Longhorn manager logs show the engine has an unknown/ERR replica:

```text
Found unknown replica 10.42.0.206:10001 in the Replica URL Mode Map
Failed to remove unknown replica tcp://10.42.0.206:10001 in mode ERR
cannot remove last replica if volume is up
Failed to start snapshot purge before rebuilding
```

So the Redis volume is currently unrecoverable through normal pod restarts. Restarting Redis, deleting the pod, or changing Redis persistence settings will not solve this specific mount failure.

## Evidence collected

### Cluster and storage classes

Nodes:

```text
k3s-01 Ready control-plane/master 172.16.21.11 Ubuntu 22.04.5 kernel 5.15.0-176-generic k3s v1.30.14+k3s2
k3s-02 Ready control-plane/master 172.16.21.12 Ubuntu 22.04.5 kernel 5.15.0-176-generic k3s v1.30.14+k3s2
k3s-03 Ready control-plane/master 172.16.21.13 Ubuntu 22.04.5 kernel 5.15.0-176-generic k3s v1.30.14+k3s2
```

Storage classes:

```text
local-path default
longhorn default numberOfReplicas=3 fsType=ext4
longhorn-single-replica numberOfReplicas=1 fsType=ext4
```

Longhorn runtime version from engine images:

```text
longhornio/longhorn-engine:v1.5.3
```

Longhorn v1.5.x is past EOL. SUSE's support matrix states v1.5.x versions have EOL date `17 Nov 2024`, and v1.5.3 was released `17 Nov 2023`.

### Redis state

Redis pod:

```text
pod/redis-0
READY 0/1
STATUS ContainerCreating
NODE k3s-03
AGE 2d18h
```

Redis StatefulSet manifest uses:

```yaml
storageClassName: longhorn
volumeMode: Filesystem
storage: 2Gi
```

Redis config was previously made more tolerant of persistence write errors:

```text
stop-writes-on-bgsave-error no
appendonly no
```

That previous fix helps only after Redis starts and the filesystem is mounted. It cannot fix a failing CSI `NodeStageVolume` or a broken Longhorn block device.

### Longhorn state

Redis volume:

```text
Volume: pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837
state: attached
robustness: unknown
currentNodeID: k3s-03
numberOfReplicas: 3
actualSize: 0
```

Visible Redis replica:

```text
pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837-r-84ccd809
node: k3s-03
state: running
healthyAt: 2026-06-02T09:31:54Z
```

Longhorn engine log:

```text
unknown replica tcp://10.42.0.206:10001 in mode ERR
failed to purge snapshots
failed to start rebuild
cannot remove last replica if volume is up
```

Longhorn CSI log repeatedly formats the same device and receives I/O errors:

```text
Disk appears to be unformatted, attempting to format as ext4
Warning: could not erase sector 2: Input/output error
Warning: could not read block 0: Input/output error
mkfs.ext4: Input/output error while writing out and closing file system
```

### Node/control-plane instability

During trace, `k3s-02` and `k3s-03` emitted recent kubelet restart/node registration events:

```text
Starting kubelet
InvalidDiskCapacity invalid capacity 0 on image filesystem
NodeNotReady
NodeReady
```

Longhorn events at the same time:

```text
Kubernetes node k3s-02 not ready: KubeletNotReady
Kubernetes node k3s-03 not ready: KubeletNotReady
NodeNotReady warnings for Longhorn CSI, instance-manager, and SMAP pods
```

This means Longhorn is not operating on a stable substrate. Even with 3 replicas configured, repeated node/kubelet flaps can leave engines with stale/unknown replica URLs and failed rebuild loops.

### Other Longhorn volumes

Current Longhorn volume snapshot:

```text
pvc-06a66bad-a6dd-4348-b041-109820173620 healthy attached
pvc-41cab2cf-a17e-4233-a1c4-67fa1a79b2b6 healthy attached
pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837 unknown attached   # Redis
pvc-a34c349e-d4eb-4005-aee1-dcc3c55975b1 healthy attached
pvc-f4b92a24-aa78-4466-95e6-fe821674f4fb unknown detached
```

`pvc-f4b92a24-aa78-4466-95e6-fe821674f4fb` is the old Redpanda PVC, but the current `redpanda` manifest uses `emptyDir`, not this PVC. It is stale risk/noise and should be cleaned only after confirming no workload uses it.

## Root cause

### Direct root cause

The Redis Longhorn volume is in a broken data-plane state:

```text
Longhorn block device returns I/O error at sector 0/2 during mkfs.ext4.
Longhorn engine has an unknown ERR replica and cannot remove it cleanly while the volume is up.
The volume has spec numberOfReplicas=3 but only one visible running replica remains.
```

This is why `redis-0` is stuck in `ContainerCreating`.

### Systemic root cause

The cluster is using Longhorn as the persistence layer for single-instance infrastructure, but the storage substrate is not stable enough for that role:

1. Longhorn version is `v1.5.3`, which is EOL.
2. K3s nodes are all control-plane nodes and also storage/workload nodes.
3. `k3s-02` and `k3s-03` are flapping through `NodeNotReady -> NodeReady`.
4. Longhorn CSI snapshotter has repeated `CrashLoopBackOff`.
5. Redis/RabbitMQ are single replicas with Longhorn PVCs, so one broken volume directly breaks dependent services.
6. Redis is operationally a cache/session/pubsub dependency, but it is treated like durable storage.
7. There is no visible successful backup/restore path for Redis; Redis volume has no useful data size and no snapshot listed.

The previous Redis config change reduced Redis application-level write-stop behavior but did not address storage-device reliability. It was a symptom fix, not a storage architecture fix.

## Why "never crash again" cannot be guaranteed

No Kubernetes storage layer can literally guarantee zero crash under node power loss, disk failure, kernel bugs, network partitions, or operator mistakes.

The practical target should be:

```text
Longhorn failure must not take the whole SMAP stack down.
Redis/RabbitMQ/Redpanda must either be disposable, externally managed, or application-level HA.
Longhorn must be upgraded and run only on stable, dedicated storage nodes/disks.
```

## Recommended remediation plan

### Phase 0: Immediate recovery for Redis

Recommended action: recreate Redis storage because current Redis Longhorn volume is empty/unformatted and stuck.

Risk: destructive to Redis data. For SMAP this is acceptable if Redis is only cache/session/pubsub and not source of truth.

Procedure:

```bash
kubectl --context homelab -n smap scale sts redis --replicas=0
kubectl --context homelab -n smap delete pvc redis-data-redis-0
kubectl --context homelab -n longhorn-system delete volumes.longhorn.io pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837
kubectl --context homelab -n smap scale sts redis --replicas=1
kubectl --context homelab -n smap rollout status sts/redis
```

Do not run this without explicit approval.

Better immediate variant: change Redis to `emptyDir` first, then recreate pod. Redis becomes disposable and independent from Longhorn.

### Phase 1: Stop putting Redis on Longhorn

Redis in this stack is a cache/session/pubsub component. It should not block the platform because a distributed block volume is degraded.

Recommended manifest change:

```yaml
redis:
  storage: emptyDir
  persistence: disabled or optional
```

If sessions must survive Redis restart, use one of:

```text
External Redis VM with systemd and disk managed outside Longhorn
Redis Sentinel/HA chart with application-level replication
PostgreSQL-backed sessions instead of Redis-backed sessions
```

For the current homelab, `emptyDir` is the most robust option for keeping SMAP operational during Longhorn incidents.

### Phase 2: Move RabbitMQ off fragile Longhorn or make it application-level HA

RabbitMQ is also single-instance with a Longhorn PVC. If its volume breaks, crawler dispatch breaks.

Best durable option:

```text
RabbitMQ quorum queue cluster with 3 RabbitMQ pods and application-level replication
Use local-path or dedicated per-node disks, not a single RWO Longhorn volume as the only durability layer
```

Acceptable homelab option:

```text
Keep RabbitMQ data disposable if crawler tasks are idempotent/retryable
Use emptyDir or local-path
Rebuild queues from ingest DB/external_tasks if RabbitMQ restarts
```

### Phase 3: Upgrade Longhorn safely

Current Longhorn engine is `v1.5.3`; this is too old for a 2026 K3s v1.30 cluster.

Important upgrade rule from Longhorn docs: starting with v1.5.0, Longhorn supports upgrades only one minor version at a time. Do not jump directly from `1.5.x` to `1.11/1.12`.

Required path:

```text
1.5.x -> 1.6.x -> 1.7.x -> 1.8.x -> 1.9.x -> 1.10.x -> 1.11.x/1.12.x
```

Before upgrading:

```text
Export Longhorn support bundle
Back up critical volumes
Fix or delete faulted/unknown volumes first
Ensure all Longhorn pods healthy
Ensure nodes are not flapping
Ensure host prerequisites pass longhornctl/environment check
```

Do not upgrade while Redis volume is in this broken state.

### Phase 4: Fix the substrate

Longhorn best practices recommend dedicated disks for production and note that local SSD/NVMe is strongly preferred. The current nodes expose roughly 48 GiB ephemeral/root-ish capacity and `/mnt/longhorn` configured as a filesystem disk.

Target substrate:

```text
Dedicated disk per node for /mnt/longhorn
Persistently mounted in /etc/fstab
No symlink disk path
Stable 1GbE minimum, 10GbE recommended for production-like Longhorn replication
No frequent kubelet/node restarts
Control-plane separated from worker/storage if possible
```

Host checks required outside Kubernetes:

```bash
journalctl -u k3s -S "2026-06-05 12:00"
journalctl -k -S "2026-06-05 12:00"
dmesg -T | grep -Ei "I/O|buffer|blk|nvme|sda|sdb|reset|readonly|ext4|xfs"
df -h /mnt/longhorn /var/lib/rancher/k3s
findmnt /mnt/longhorn
smartctl -a <longhorn-disk>
```

These require SSH/console access to nodes.

### Phase 5: Longhorn settings hardening

Current settings:

```text
default-replica-count=3
replica-soft-anti-affinity=false
storage-over-provisioning-percentage=100
storage-minimal-available-percentage=5
orphan-auto-deletion=false
```

Recommended:

```text
storage-minimal-available-percentage: 10 or 25
replica-auto-balance: least-effort
orphan-auto-deletion: enabled only after manual audit policy is agreed
recurring backups to S3/NFS backupstore for critical volumes
alerts on robustness != healthy
alerts on node Ready transition, kubelet restart, Longhorn CSI CrashLoopBackOff
```

Do not enable orphan deletion until the current stale volumes are audited.

## Target architecture for "no SMAP-wide crash"

Recommended state:

| Component | Current | Target |
|---|---|---|
| Redis | Single pod + Longhorn PVC | `emptyDir` disposable cache or external Redis |
| RabbitMQ | Single pod + Longhorn PVC | RabbitMQ HA/quorum or disposable/idempotent queue |
| Redpanda | Current manifest uses `emptyDir` | Keep if broker data is disposable, or deploy proper 3-node broker |
| Longhorn | v1.5.3 EOL | Upgrade one minor at a time to supported Longhorn |
| Storage nodes | control-plane/workload/storage mixed | dedicated stable storage disks/nodes |
| Backups | no obvious Redis backup | backupstore + recurring backups for actual source-of-truth volumes |
| Monitoring | manual inspection | alerting for volume robustness, node flaps, CSI CrashLoop |

This makes Longhorn failure a recoverable degraded event, not a system-wide outage.

## Immediate decision needed

Choose one recovery path:

1. Fast restore: delete and recreate Redis PVC/Longhorn volume. This likely restores Redis fastest but keeps Redis dependent on Longhorn.
2. Durable homelab restore: patch Redis manifest to use `emptyDir`, delete broken PVC after approval, and restart Redis. This removes Redis from Longhorn blast radius.
3. Conservative forensic path: keep Redis broken for now, collect Longhorn support bundle and host SSH logs first.

Recommendation: option 2.

Redis data is not the source of truth for SMAP; availability matters more than preserving a broken 2 GiB empty/unformatted volume.

## Sources

Longhorn official docs and support references used:

- https://longhorn.io/docs/1.12.0/best-practices/
- https://longhorn.io/docs/1.12.0/deploy/install/
- https://longhorn.io/docs/1.12.0/deploy/upgrade/
- https://longhorn.io/docs/1.12.0/troubleshoot/troubleshooting/
- https://www.suse.com/suse-longhorn/support-matrix/all-supported-versions/longhorn-v1-5-x/

## Commands used for trace

```bash
kubectl --context homelab get nodes -o wide
kubectl --context homelab get storageclass
kubectl --context homelab get pvc -A
kubectl --context homelab get pv
kubectl --context homelab -n smap describe pod redis-0
kubectl --context homelab -n smap describe sts redis
kubectl --context homelab -n smap get events --sort-by=.lastTimestamp
kubectl --context homelab -n longhorn-system get pods -o wide
kubectl --context homelab -n longhorn-system get volumes.longhorn.io -o wide
kubectl --context homelab -n longhorn-system get replicas.longhorn.io -o wide
kubectl --context homelab -n longhorn-system get engines.longhorn.io -o wide
kubectl --context homelab -n longhorn-system describe volumes.longhorn.io pvc-7e0c2f1f-8cd9-49d3-b191-a2be890ce837
kubectl --context homelab -n longhorn-system logs longhorn-manager-dtm29 --since=8h
kubectl --context homelab -n longhorn-system logs longhorn-csi-plugin-hc4dc -c longhorn-csi-plugin --since=8h
kubectl --context homelab get events -A --sort-by=.lastTimestamp
```
