# References

## A. Internal Project References

1. `../tong-quan.md`
2. `../3-event-contracts.md`
3. `../document/gap/007_reporting_execution_and_transport_contract_mismatch.md`
4. `../analysis-srv/README.md`
5. `../analysis-srv/pyproject.toml`
6. `../analysis-srv/internal/consumer/server.py`
7. `../analysis-srv/internal/pipeline/usecase/usecase.py`
8. `../analysis-srv/internal/analytics/usecase/batch_enricher.py`
9. `../analysis-srv/apps/consumer/deployment.yaml`
10. `../analysis-srv/manifests/hpa.yaml`
11. `../analysis-srv/tests/`
12. `../identity-srv/README.md`
13. `../identity-srv/go.mod`
14. `../identity-srv/config/auth-config.yaml`
15. `../identity-srv/internal/authentication/delivery/http/oauth.go`
16. `../identity-srv/internal/authentication/delivery/http/handlers.go`
17. `../identity-srv/internal/authentication/delivery/http/routes.go`
18. `../project-srv/README.md`
19. `../project-srv/go.mod`
20. `../project-srv/migration/init_schema.sql`
21. `../project-srv/migration/000002_add_crisis_config.sql`
22. `../project-srv/internal/project/delivery/http/routes.go`
23. `../project-srv/internal/crisis/delivery/http/routes.go`
24. `../project-srv/internal/project/repository/postgre/project.go`
25. `../project-srv/docker-compose.yml`
26. `../ingest-srv/README.md`
27. `../ingest-srv/go.mod`
28. `../ingest-srv/migrations/001_create_schema_ingest_v1.sql`
29. `../ingest-srv/internal/datasource/delivery/http/routes.go`
30. `../ingest-srv/internal/dryrun/delivery/http/routes.go`
31. `../ingest-srv/internal/datasource/usecase/datasource_lifecycle.go`
32. `../ingest-srv/internal/datasource/usecase/project_lifecycle.go`
33. `../ingest-srv/internal/datasource/usecase/target.go`
34. `../ingest-srv/internal/uap/usecase/usecase_test.go`
35. `../ingest-srv/docker-compose.yml`
36. `../knowledge-srv/README.md`
37. `../knowledge-srv/go.mod`
38. `../knowledge-srv/config/knowledge-config.yaml`
39. `../knowledge-srv/internal/search/delivery/http/routes.go`
40. `../knowledge-srv/internal/search/delivery/http/handlers.go`
41. `../knowledge-srv/internal/search/usecase/search.go`
42. `../knowledge-srv/internal/chat/delivery/http/routes.go`
43. `../knowledge-srv/internal/chat/delivery/http/handlers.go`
44. `../knowledge-srv/internal/chat/usecase/chat.go`
45. `../knowledge-srv/pkg/qdrant/qdrant.go`
46. `../knowledge-srv/migrations/001_create_indexed_documents_table.sql`
47. `../knowledge-srv/migrations/005_create_conversations_table.sql`
48. `../knowledge-srv/migrations/006_create_messages_table.sql`
49. `../notification-srv/README.md`
50. `../notification-srv/go.mod`
51. `../notification-srv/documents/contracts.md`
52. `../notification-srv/internal/websocket/delivery/http/routes.go`
53. `../notification-srv/internal/websocket/delivery/http/handlers.go`
54. `../notification-srv/internal/websocket/transport_test.go`
55. `../notification-srv/internal/alert/usecase/dispatch_crisis.go`
56. `../notification-srv/internal/alert/usecase/dispatch_campaign.go`
57. `../notification-srv/internal/alert/usecase/dispatch_onboarding.go`
58. `../scapper-srv/README.md`
59. `../scapper-srv/requirements.txt`
60. `../scapper-srv/RABBITMQ.md`
61. `../scapper-srv/app/main.py`
62. `../scapper-srv/app/publisher.py`
63. `../scapper-srv/app/worker.py`
64. `../shared-libs/go/go.mod`
65. `../shared-libs/python/pyproject.toml`
66. `../test/full_check/test_project_decision_table.py`
67. `../test/full_check/test_runtime_completion_e2e.py`
68. `../test/full_check/test_idempotency_contract.py`
69. `../e2e-report.md`
70. `../final-report.md`

## B. External Technical References

1. Brown, Simon. *The C4 Model for Visualising Software Architecture*. Available at: `https://c4model.com/`
2. Object Management Group. *Unified Modeling Language (UML) Version 2.5.1*.
3. Newman, Sam. *Building Microservices: Designing Fine-Grained Systems*.
4. Richardson, Chris. *Microservices Patterns*.
5. Kleppmann, Martin. *Designing Data-Intensive Applications*.
6. Hohpe, Greg; Woolf, Bobby. *Enterprise Integration Patterns*.
7. Evans, Eric. *Domain-Driven Design: Tackling Complexity in the Heart of Software*.
8. Fowler, Martin. *Microservices: A Definition of This New Architectural Term*.
9. FastAPI Documentation. `https://fastapi.tiangolo.com/`
10. Gin Documentation. `https://gin-gonic.com/`
11. PostgreSQL Documentation. `https://www.postgresql.org/docs/`
12. Redis Documentation. `https://redis.io/docs/`
13. Apache Kafka Documentation. `https://kafka.apache.org/documentation/`
14. RabbitMQ Documentation. `https://www.rabbitmq.com/documentation.html`
15. Qdrant Documentation. `https://qdrant.tech/documentation/`
16. Docker Documentation. `https://docs.docker.com/`
17. Kubernetes Documentation. `https://kubernetes.io/docs/`

## C. Citation Note

Trong giai đoạn dàn trang cuối, danh sách này có thể được chuyển sang định dạng tham khảo chuẩn của luận văn như IEEE, APA hoặc mẫu tham khảo nội bộ do khoa yêu cầu. Các mục thuộc nhóm internal project references nên được xem như tài liệu nguồn nội bộ hoặc technical evidence references.
