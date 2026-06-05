# SMAP Business Data Process Stop Report

Date: 2026-06-05 (Asia/Ho_Chi_Minh)
Cluster context: homelab
Namespace: smap

## Scope

Business-level data pipeline inspected and stopped:

1. Campaign lifecycle in `project.campaigns`.
2. Project lifecycle in `project.projects`.
3. Ingest datasource lifecycle in `ingest.data_sources`.
4. Crawl target scheduling in `ingest.crawl_targets`.
5. Scheduled crawl jobs in `ingest.scheduled_jobs`.
6. External collector tasks in `ingest.external_tasks`.
7. Raw batch publish backlog in `ingest.raw_batches`.
8. RabbitMQ collector queues.
9. Redpanda/Kafka downstream analytics consumer group.

## Process graph

`Campaign -> Project -> DataSource -> CrawlTarget -> ScheduledJob -> ExternalTask -> RabbitMQ collector -> RawBatch -> Redpanda topic smap.collector.output -> analysis-consumer -> analytics.* topics -> notification/knowledge consumers`

## Leak found

Confirmed lifecycle leak:

- Campaign `Grab` was `PENDING`.
- Project `Grab Bike` was `ACTIVE`.
- Project `Grab Car` was `ACTIVE`.
- Those active projects had active datasources and running ingest runtime.

This means project activation could bypass parent campaign lifecycle and create data runtime while campaign was not active.

Also found stale runtime state:

- `scheduled_jobs.RUNNING`: 3 before stop.
- `external_tasks.RUNNING`: 9 before stop.
- Some tasks were stale since 2026-05-23 and 2026-05-27 while RabbitMQ queues were empty.
- `raw_batches.publish_status in (PENDING, PUBLISHING)`: 4724 before stop.

## Code fix applied locally

Patched:

- `project-srv/internal/project/usecase/lifecycle.go`

Added parent campaign guard:

- `Project.Activate` now rejects activation unless parent campaign is `ACTIVE`.
- `Project.Resume` now rejects resume unless parent campaign is `ACTIVE`.

This prevents direct project lifecycle calls from bypassing campaign stop/pause state.

Note: this code change is local in the workspace. It must be built and deployed before it affects the live `project-srv` image.

## Live business stop applied

Project schema:

- Paused active projects: 3
- Paused active/pending campaigns: 2

Ingest schema:

- Paused `ACTIVE/READY` datasources: 14
- Deactivated crawl targets: 29
- Cancelled open scheduled jobs: 26
- Cancelled open external tasks: 10
- Failed open raw publish batches: 4724

Kafka/RabbitMQ:

- Deleted HPA `analysis-consumer`.
- Scaled deployment `analysis-consumer` to `0`.
- RabbitMQ queues remained empty.

## Final state

Project DB:

- Campaigns: 5 `PAUSED`, 0 `ACTIVE`.
- Projects: 11 `PAUSED`, 9 `PENDING`, 9 `ARCHIVED`, 0 `ACTIVE`.
- Active projects under any campaign: 0.

Ingest DB:

- Datasources: 29 `PAUSED`, 2 `PENDING`, 15 `ARCHIVED`, 0 `ACTIVE`, 0 `READY`.
- Crawl targets: 49 `INACTIVE`, 0 `ACTIVE`.
- Open scheduled jobs (`PENDING/RUNNING/PARTIAL`): 0.
- Open external tasks (`PENDING/RUNNING`): 0.
- Open raw publish (`PENDING/PUBLISHING`): 0.

Kafka/Redpanda:

- `analytics-service` group state: `Empty`.
- Members: 0.
- Remaining backlog: 12342 messages in `smap.collector.output`; intentionally not being processed.

RabbitMQ:

- `facebook_tasks`: 0 ready, 0 unacked.
- `tiktok_tasks`: 0 ready, 0 unacked.
- `youtube_tasks`: 0 ready, 0 unacked.
- completion queues: 0 ready, 0 unacked.

## Residual risks

1. The live code image has not been rebuilt/deployed with the project lifecycle guard yet.
2. Re-applying old Kubernetes manifests may recreate the deleted `analysis-consumer` HPA unless the manifest is also updated or deployment policy is clarified.
3. Kafka backlog remains stored in Redpanda. It is stopped, not deleted.
4. Resuming data collection later will require reactivating campaign/project/datasource/targets and re-enabling `analysis-consumer`/HPA intentionally.
