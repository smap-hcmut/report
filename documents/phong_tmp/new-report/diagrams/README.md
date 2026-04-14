# SMAP Current-State Diagrams

Folder nay chua bo PlantUML diagrams moi cho `new-report`, duoc ve lai de bam current implementation trong workspace hien tai.

## Structure

```text
diagrams/
  authentication/
    auth_authentication_current.puml
    auth_middleware_current.puml
    auth_user_login_current.puml
  activity/
    activity_analytics_to_knowledge_current.puml
    activity_configuration_current.puml
    activity_dryrun_current.puml
    activity_project_lifecycle_current.puml
  component/
    component_analysis_current.puml
    component_identity_current.puml
    component_ingest_execution_current.puml
    component_knowledge_current.puml
    component_notification_current.puml
    component_project_current.puml
    component_webui_current.puml
  data-flow/
    dataflow_analytics_pipeline_current.puml
    dataflow_crawl_runtime_completion_current.puml
    dataflow_knowledge_chat_current.puml
    dataflow_project_create_current.puml
    dataflow_project_lifecycle_control_current.puml
  realtime/
    realtime_websocket_connection_current.puml
    realtime_websocket_delivery_current.puml
  sequence/
    seq_authentication_flow_current.puml
    seq_analytics_pipeline_flow_current.puml
    seq_dryrun_flow_current.puml
    seq_knowledge_chat_flow_current.puml
    seq_notification_alert_flow_current.puml
    seq_project_lifecycle_flow_current.puml
    README.md
```

## Scope

- cac diagram nay uu tien `current-state`
- neu target architecture va current code conflict, diagram se bam current code
- naming giu gan style cua `old_docs/diagrams`, nhung them suffix `_current`

## Current Diagram Set

- `authentication/*.puml`
  auth login/callback, auth boundary, middleware/auth policy cho HTTP, WebSocket va internal routes

- `component/*.puml`
  service boundaries cho identity, project, ingest execution, analysis, knowledge, notification, web-ui

- `data-flow/*.puml`
  project create, lifecycle control, crawl runtime completion, analytics pipeline, knowledge chat dataflow

- `sequence/*.puml`
  6 sequence diagrams current-state cho auth, lifecycle, dryrun, analytics, knowledge chat, notification alert

- `component/component_project_current.puml`
  project-srv boundary, internal HTTP lifecycle control, Kafka lifecycle event publisher

- `component/component_ingest_execution_current.puml`
  ingest-srv execution boundary, RabbitMQ dispatch/completion, MinIO verify, UAP publish

- `data-flow/dataflow_project_lifecycle_control_current.puml`
  current activate flow: `project-srv -> ingest-srv` qua internal HTTP control plane

- `data-flow/dataflow_crawl_runtime_completion_current.puml`
  dispatch task -> scapper worker -> storage -> completion -> raw batch -> UAP publish

- `data-flow/dataflow_analytics_pipeline_current.puml`
  `smap.collector.output` -> analysis consumer -> pipeline -> contract topics -> knowledge indexing

- `realtime/realtime_websocket_delivery_current.puml`
  `/ws` connection + Redis subscriber -> websocket routing + Discord dispatch

- `activity/activity_project_lifecycle_current.puml`
  project lifecycle current-state from configuration to activate/pause/resume/archive

- `activity/activity_configuration_current.puml`
  campaign/project setup, datasource + target configuration

- `activity/activity_dryrun_current.puml`
  dryrun trigger, async validation, result persistence

- `activity/activity_analytics_to_knowledge_current.puml`
  analytics-to-knowledge handoff and user consumption loop

## Render

```bash
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/authentication/*.puml
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/component/*.puml
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/data-flow/*.puml
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/realtime/*.puml
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/activity/*.puml
plantuml report_SMAP/documents/phong_tmp/new-report/diagrams/sequence/*.puml
```

PNG/SVG output co the duoc move vao `report_SMAP/documents/phong_tmp/new-report/thesis/images/` hoac `report_SMAP/final-report/images/` tuy theo phase migrate.
