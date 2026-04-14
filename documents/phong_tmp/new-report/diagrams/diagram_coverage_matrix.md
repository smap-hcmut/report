# Diagram Coverage Matrix

File nay dung de chon diagram cho thesis/final-report ma khong phai quyet dinh lai tu dau.

## Chapter 2 - Technologies and Runtime Stack

| Diagram | Vai tro |
| --- | --- |
| `component/component_identity_current.puml` | auth stack va session/JWT boundary |
| `component/component_webui_current.puml` | xac nhan frontend stack va integration surfaces |
| `component/component_notification_current.puml` | Redis + WebSocket + Discord stack |

## Chapter 3 - System Analysis

| Diagram | Vai tro |
| --- | --- |
| `activity/activity_configuration_current.puml` | business configuration flow |
| `activity/activity_dryrun_current.puml` | dryrun validation capability |
| `activity/activity_project_lifecycle_current.puml` | lifecycle requirements va actor interactions |
| `activity/activity_analytics_to_knowledge_current.puml` | end-to-end capability chain |

## Chapter 4 - System Design

| Diagram | Vai tro |
| --- | --- |
| `component/component_project_current.puml` | project-srv current boundary |
| `component/component_ingest_execution_current.puml` | ingest execution plane |
| `component/component_analysis_current.puml` | analytics pipeline decomposition |
| `component/component_knowledge_current.puml` | retrieval/chat/indexing boundary |
| `component/component_notification_current.puml` | websocket/alert delivery boundary |
| `data-flow/dataflow_project_lifecycle_control_current.puml` | internal HTTP lifecycle control plane |
| `data-flow/dataflow_crawl_runtime_completion_current.puml` | RabbitMQ + storage + completion lane |
| `data-flow/dataflow_analytics_pipeline_current.puml` | Kafka analytics data plane |
| `data-flow/dataflow_knowledge_chat_current.puml` | search/chat orchestration |
| `realtime/realtime_websocket_connection_current.puml` | /ws connect/auth |
| `realtime/realtime_websocket_delivery_current.puml` | Redis -> WebSocket / Discord routing |
| `sequence/seq_authentication_flow_current.puml` | sequence 1 |
| `sequence/seq_project_lifecycle_flow_current.puml` | sequence 2 |
| `sequence/seq_dryrun_flow_current.puml` | sequence 3 |
| `sequence/seq_analytics_pipeline_flow_current.puml` | sequence 4 |
| `sequence/seq_knowledge_chat_flow_current.puml` | sequence 5 |
| `sequence/seq_notification_alert_flow_current.puml` | sequence 6 |

## Chapter 5 - Implementation

| Diagram | Vai tro |
| --- | --- |
| `data-flow/dataflow_project_create_current.puml` | project persistence + domain_type_code setup |
| `data-flow/dataflow_crawl_runtime_completion_current.puml` | external_tasks/raw_batches/completion implementation |
| `component/component_ingest_execution_current.puml` | mapping source tree -> execution modules |
| `component/component_webui_current.puml` | web-ui implementation surface |

## Recommended Freeze Set Before final-report

Neu can chot mot bo hinh toi uu truoc khi sang Typst, uu tien 12 file sau:

1. `component/component_project_current.puml`
2. `component/component_ingest_execution_current.puml`
3. `component/component_analysis_current.puml`
4. `component/component_knowledge_current.puml`
5. `component/component_notification_current.puml`
6. `data-flow/dataflow_project_lifecycle_control_current.puml`
7. `data-flow/dataflow_crawl_runtime_completion_current.puml`
8. `data-flow/dataflow_analytics_pipeline_current.puml`
9. `realtime/realtime_websocket_delivery_current.puml`
10. `sequence/seq_authentication_flow_current.puml`
11. `sequence/seq_project_lifecycle_flow_current.puml`
12. `sequence/seq_analytics_pipeline_flow_current.puml`
