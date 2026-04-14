# Freeze Set For Final Report

Updated: 2026-04-15

File nay chot bo diagram uu tien cao nhat de dua vao `final-report` sau khi render.

## Freeze Set A - Core Final Report

Dung bo nay neu can mot tap hinh gon, phu du cac narrative chinh cua Chapter 3-5.

1. `component/component_project_current.puml`
2. `component/component_ingest_execution_current.puml`
3. `component/component_analysis_current.puml`
4. `component/component_knowledge_current.puml`
5. `component/component_notification_current.puml`
6. `component/component_webui_current.puml`
7. `data-flow/dataflow_project_lifecycle_control_current.puml`
8. `data-flow/dataflow_crawl_runtime_completion_current.puml`
9. `data-flow/dataflow_analytics_pipeline_current.puml`
10. `realtime/realtime_websocket_delivery_current.puml`
11. `sequence/seq_authentication_flow_current.puml`
12. `sequence/seq_project_lifecycle_flow_current.puml`

## Freeze Set B - Optional Supporting Figures

Chi them neu report con du trang va can minh hoa chi tiet hon.

1. `sequence/seq_dryrun_flow_current.puml`
2. `sequence/seq_analytics_pipeline_flow_current.puml`
3. `sequence/seq_knowledge_chat_flow_current.puml`
4. `sequence/seq_notification_alert_flow_current.puml`
5. `activity/activity_configuration_current.puml`
6. `activity/activity_dryrun_current.puml`
7. `activity/activity_project_lifecycle_current.puml`
8. `data-flow/dataflow_project_create_current.puml`
9. `data-flow/dataflow_knowledge_chat_current.puml`
10. `authentication/auth_authentication_current.puml`
11. `authentication/auth_middleware_current.puml`
12. `realtime/realtime_websocket_connection_current.puml`

## Why This Freeze Set

- cover du 5 subsystem chinh: project, ingest, analysis, knowledge, notification
- cover 3 transport lane quan trong: internal HTTP, RabbitMQ, Kafka
- co 1 hinh rieng cho frontend/web-ui de tranh report nghieng hoan toan ve backend
- sequence duoc giu o muc vua du, uu tien auth va lifecycle vi day la 2 flow de bi viet sai nhat
- cac hinh optional duoc tach rieng de tranh final-report bi qua day

## Do Not Use As Primary Figures

Nhung hinh sau van hop le, nhung khong nen la hinh chinh neu so luong hinh bi gioi han:

- `authentication/auth_user_login_current.puml`
  Ly do: bi trung nhieu voi `seq_authentication_flow_current.puml`

- `activity/activity_analytics_to_knowledge_current.puml`
  Ly do: y nghia trung lap mot phan voi `dataflow_analytics_pipeline_current.puml`

- `sequence/seq_notification_alert_flow_current.puml`
  Ly do: nen dung khi can zoom sau vao notification, con khong thi component + realtime da du

## Ready-To-Use Order In final-report

1. Chapter 3: `activity/activity_configuration_current.puml`, `activity/activity_project_lifecycle_current.puml`
2. Chapter 4: 5 component diagrams chinh + 3 dataflow diagrams chinh + realtime delivery
3. Chapter 5: `component/component_webui_current.puml`, `sequence/seq_authentication_flow_current.puml`, `sequence/seq_project_lifecycle_flow_current.puml`, `sequence/seq_dryrun_flow_current.puml`

## Gate Before Embedding Into final-report

- [ ] render duoc PNG/SVG khong loi syntax
- [ ] ten file output duoc doi sang convention cuoi cung neu can
- [ ] caption trong report noi ro `current-state` o nhung hinh de tranh nham sang target-state
