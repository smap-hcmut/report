# CHAPTER 6: EVALUATION & TESTING

## 6.1 Testing Strategy

### 6.1.1 Lớp lý thuyết

Chiến lược kiểm thử của một hệ thống đa dịch vụ thường cần kết hợp nhiều lớp. Unit testing được dùng để kiểm tra logic nhỏ, tách biệt và có thể chạy nhanh. Integration testing được dùng để kiểm tra ranh giới giữa các module hoặc giữa service với hạ tầng như Kafka, Redis hay PostgreSQL. User Acceptance Testing hoặc end-to-end testing được dùng để xác nhận rằng các luồng nghiệp vụ chính vận hành đúng khi nhiều thành phần cùng tham gia.

Đối với các hệ bất đồng bộ, kiểm thử không chỉ dừng ở đầu vào và đầu ra của một API. Hệ thống còn cần được kiểm tra về hành vi idempotency, replay safety, error contract, lifecycle guard và tính nhất quán trạng thái giữa các bước xử lý. Vì vậy, một chiến lược kiểm thử hợp lý cho SMAP phải bao gồm cả lớp HTTP, lớp queue/stream, và lớp persistence/runtime contracts.

### 6.1.2 Lớp phân tích trên dự án SMAP

Các test assets hiện có trong workspace cho thấy hệ thống đang dùng một chiến lược kiểm thử nhiều lớp. `analysis-srv` có `pytest` unit tests và `e2e` tests; README của service này còn ghi nhận rõ `tests/` đang chứa khoảng 180 tests. `notification-srv` sử dụng `testify` và có test cho WebSocket transport. `ingest-srv` có ít nhất một test Go ở `internal/uap/usecase/usecase_test.go`, đồng thời workspace còn có một thư mục `test/` chứa hàng loạt test Python mức full-check và contract validation cho lifecycle, runtime, idempotency, infra boundary và scheduler behavior.

Điểm đáng chú ý là chiến lược kiểm thử của SMAP nghiêng nhiều về integration và contract testing, chứ không chỉ tập trung vào unit tests thuần túy. Điều này phù hợp với bản chất của hệ thống, vì các lỗi nghiêm trọng nhất thường nằm ở chỗ phối hợp giữa service, broker, storage và workflow state transitions.

### 6.1.3 Lớp minh họa từ mã nguồn

| Lớp kiểm thử | Bằng chứng |
| --- | --- |
| Unit test Python | `../analysis-srv/tests/test_*.py` |
| E2E test Python | `../analysis-srv/tests/e2e/test_*.py` |
| Unit test Go | `../ingest-srv/internal/uap/usecase/usecase_test.go`, `../notification-srv/internal/websocket/transport_test.go` |
| Shared library tests | `../shared-libs/go/*_test.go`, `../shared-libs/python/test_*.py` |
| Full system / contract tests | `../test/full_check/test_*.py`, `../test/1903_test/test_*.py` |

## 6.2 Unit Test Results

### 6.2.1 Lớp lý thuyết

Kết quả unit test trong luận văn có thể được trình bày theo hai cách. Nếu có artifact chạy test thực tế như coverage report, CI report hoặc terminal output, có thể đưa số liệu chính xác. Nếu chưa có artifact kết quả chạy test trong repo, luận văn cần chuyển sang cách trình bày dựa trên cấu trúc test hiện có và chỉ rõ giới hạn của dữ liệu đánh giá. Đây là cách làm phù hợp với nguyên tắc “source-code evidence”.

### 6.2.2 Bảng tổng hợp test assets hiện có

| Khu vực | Framework / dạng test | Bằng chứng | Ghi chú |
| --- | --- | --- | --- |
| `analysis-srv` | `pytest`, `pytest-asyncio`, E2E | `analysis-srv/pyproject.toml`, `analysis-srv/tests/` | README ghi nhận khoảng `180 tests` |
| `notification-srv` | Go test + `testify` | `notification-srv/go.mod`, `notification-srv/internal/websocket/transport_test.go` | tập trung vào websocket transport |
| `ingest-srv` | Go test | `ingest-srv/internal/uap/usecase/usecase_test.go` | ít nhất một test usecase rõ ràng |
| `shared-libs/go` | Go unit/integration tests | `shared-libs/go/*_test.go` | tracing, redis, kafka, log, cron |
| `shared-libs/python` | Python tests | `shared-libs/python/test_*.py` | tracing/http/database libs |
| `test/full_check` | Python full-check suite | `test/full_check/test_*.py` | runtime, lifecycle, idempotency, infra contracts |
| `test/1903_test` | Python integration / bug-hunt | `test/1903_test/test_*.py` | phase checks và bug hunt |

### 6.2.3 Lớp phân tích trên dự án SMAP

Từ các bằng chứng hiện có, có thể rút ra ba nhận xét. Thứ nhất, analytics layer là nơi có mức độ kiểm thử rõ ràng và có tổ chức nhất, vì vừa có test unit theo module, vừa có e2e tests và còn được README ghi nhận số lượng test tương đối lớn. Điều này phù hợp với thực tế rằng analytics pipeline là thành phần phức tạp nhất của hệ thống.

Thứ hai, workspace có một lớp test ngoài service-level dưới `test/full_check` và `test/1903_test`, cho thấy dự án có xu hướng kiểm thử theo scenario và contract matrix ở cấp toàn hệ thống. Đây là điểm rất có giá trị đối với một hệ bất đồng bộ, vì nhiều lỗi chỉ xuất hiện khi nhiều thành phần phối hợp cùng lúc.

Thứ ba, hiện chưa có coverage report hoặc artifact tổng hợp kết quả test run nằm trực tiếp trong repo. Vì vậy, luận văn này không khẳng định phần trăm coverage hay số test pass/fail tại thời điểm viết, mà chỉ ghi nhận quy mô và hướng tổ chức test suite từ source tree thực tế.

### 6.2.4 Lớp minh họa từ mã nguồn

- `../analysis-srv/README.md` ghi rõ `tests/` chứa `Pytest unit tests (180 tests)`.
- `../analysis-srv/pyproject.toml` khai báo `pytest`, `pytest-asyncio`, `testcontainers[kafka]` và marker `e2e`.
- `../notification-srv/go.mod` xác nhận `stretchr/testify` được dùng trong service.

### 6.2.5 Representative Test Case Matrix

| Test Case ID | File bằng chứng | Hàm / test case | Mục tiêu kiểm thử | Liên hệ yêu cầu |
| --- | --- | --- | --- | --- |
| TC-UAP-01 | `../ingest-srv/internal/uap/usecase/usecase_test.go` | `TestChunkRecords` | kiểm tra cơ chế chia nhỏ batch UAP trước khi publish | FR-08, NFR-01 |
| TC-UAP-02 | cùng file | `TestMergeRawMetadata` | kiểm tra gộp raw metadata, artifact metadata và Kafka publish stats | FR-08, NFR-05 |
| TC-UAP-03 | cùng file | `TestMarshalUAPRecordUsesVNextKeysOnly` | kiểm tra payload UAP sinh ra dùng đúng key set thế hệ mới | FR-08, NFR-05 |
| TC-WS-01 | `../notification-srv/internal/websocket/transport_test.go` | `TestWebSocketConnection` | kiểm tra kết nối WebSocket thành công với token hợp lệ | FR-11, NFR-02 |
| TC-WS-02 | cùng file | `TestWebSocketMissingToken` | kiểm tra route `/ws` từ chối request thiếu token | FR-11, NFR-02 |
| TC-AN-E2E-01 | `../analysis-srv/tests/e2e/test_output_contract.py` | `test_batch_completed_published_to_correct_topic` và nhóm test cùng file | kiểm tra output contract của analytics topics đối với knowledge layer | FR-09, FR-10, NFR-05 |
| TC-AN-E2E-02 | `../analysis-srv/tests/e2e/test_domain_routing.py` | `test_known_domain_vinfast_gets_vinfast_overlay` và nhóm test cùng file | kiểm tra domain routing và bất biến `domain_overlay` không rỗng | FR-09, NFR-05 |
| TC-AN-INT-01 | `../analysis-srv/tests/test_crisis.py` | `test_assess_crisis_empty_bundle_returns_none`, `test_assess_crisis_watch_level_for_medium_pressure` | kiểm tra logic đánh giá khủng hoảng theo mức độ tín hiệu | FR-09, FR-11 |
| TC-PROJ-01 | `../test/full_check/test_project_decision_table.py` | `run` | kiểm tra bảng quyết định cho project lifecycle và readiness | FR-03, NFR-05 |
| TC-RUNTIME-01 | `../test/full_check/test_runtime_completion_e2e.py` | `run_single_target_runtime_completion` | kiểm tra dry run terminal status, auto-activate target và activation readiness | FR-07, FR-08 |
| TC-IDEMP-01 | `../test/full_check/test_idempotency_contract.py` | `run` | kiểm tra idempotency của pause/resume/archive/delete và duplicate completion | FR-03, FR-05, FR-08, NFR-05 |

### 6.2.6 Phân tích test cases tiêu biểu

Nhóm test thứ nhất tập trung vào `ingest-srv` và canonical data contract. Các test như `TestChunkRecords`, `TestMergeRawMetadata` và `TestMarshalUAPRecordUsesVNextKeysOnly` cho thấy hệ thống không chỉ kiểm tra logic CRUD, mà còn kiểm tra trực tiếp các bất biến liên quan đến batching, metadata propagation và cấu trúc payload UAP. Đây là những kiểm thử rất quan trọng đối với một hệ bất đồng bộ vì lỗi ở lớp payload contract thường lan sang nhiều service downstream cùng lúc.

Nhóm test thứ hai tập trung vào security boundary và delivery behavior. `TestWebSocketConnection` và `TestWebSocketMissingToken` chứng minh rằng `notification-srv` không xem WebSocket như một cổng mở tự do, mà vẫn áp dụng xác thực token ở thời điểm nâng cấp kết nối. Điều này xác nhận trực tiếp các yêu cầu về bảo mật và realtime delivery đã nêu ở Chương 3.

Nhóm test thứ ba tập trung vào analytics-to-knowledge pipeline. File `test_output_contract.py` đi sâu vào thứ tự publish, sự hiện diện của `project_id`, cấu trúc `documents[]`, các nhóm trường con như `identity`, `content`, `nlp`, `business`, `rag`, cũng như điều kiện `domain_overlay` của digest. Đây là loại kiểm thử rất có giá trị học thuật vì nó chứng minh được ràng buộc liên service ở mức contract chứ không chỉ ở mức hàm nội bộ.

Nhóm test thứ tư tập trung vào các decision table và contract matrix của hệ thống. Các file `test_project_decision_table.py`, `test_runtime_completion_e2e.py` và `test_idempotency_contract.py` cho thấy dự án đang sử dụng tư duy kiểm thử dựa trên bảng quyết định và trạng thái chuyển tiếp, thay vì chỉ kiểm tra endpoint theo kiểu happy-path. Đây là dấu hiệu của một hệ thống đã bắt đầu quan tâm đến tính đúng đắn của lifecycle semantics và khả năng chịu lỗi trong thực tế vận hành.

### 6.2.7 Requirement-to-Test Coverage Matrix

| Requirement ID | Yêu cầu | Test evidence chính |
| --- | --- | --- |
| FR-01 | User Authentication | `identity-srv` routes được xác nhận gián tiếp qua websocket auth tests và config auth; cần bổ sung test auth chuyên biệt nếu muốn coverage sâu hơn |
| FR-03 | Project Lifecycle Control | `test_project_decision_table.py`, `test_idempotency_contract.py` |
| FR-05 | Datasource Management | `test_idempotency_contract.py`, các full-check runtime tests |
| FR-07 | Dry Run Validation | `test_runtime_completion_e2e.py`, `test_dryrun_completion_faults.py`, `test_dryrun_completion_duplicate_burst.py` |
| FR-08 | Crawl Runtime Orchestration | `usecase_test.go`, `test_runtime_completion_e2e.py`, `test_idempotency_contract.py` |
| FR-09 | Analytics Processing | `test_output_contract.py`, `test_domain_routing.py`, `test_crisis.py`, `test_normalization.py`, `test_enrichment.py`, `test_threads.py` |
| FR-10 | Knowledge Search and Chat | output contract tests gián tiếp bảo vệ knowledge input; route/usecase chat-search hiện chưa thấy dedicated end-user tests trong workspace |
| FR-11 | Realtime Notification | `notification-srv/internal/websocket/transport_test.go` |
| NFR-02 | Security | `TestWebSocketConnection`, `TestWebSocketMissingToken`, auth configs |
| NFR-05 | Data Integrity / Idempotency | `test_output_contract.py`, `test_domain_routing.py`, `test_idempotency_contract.py`, `usecase_test.go` |

Ma trận trên cho thấy một số yêu cầu đã có test evidence trực tiếp và khá mạnh, đặc biệt ở các nhóm lifecycle, runtime contract và analytics pipeline. Tuy nhiên, cũng có những yêu cầu mới chỉ được bao phủ gián tiếp hoặc chưa có test chuyên biệt trong workspace hiện tại, ví dụ như frontend-facing search/chat behavior ở mức end-user acceptance. Việc chỉ ra những khoảng trống này là cần thiết để luận văn phản ánh trung thực hiện trạng kiểm thử của hệ thống.

### 6.2.8 Operational E2E Verification Artifacts

Ngoài test files và contract tests trong source tree, workspace hiện còn chứa hai hiện vật đánh giá tích hợp vận hành là `../e2e-report.md` và `../final-report.md`. Đây là những bằng chứng quan trọng vì chúng phản ánh hệ thống trong môi trường triển khai thật, thay vì chỉ trong phạm vi unit test hoặc module test nội bộ.

`e2e-report.md` ghi nhận một phiên kiểm thử tổng thể trên cụm K3s với 55 endpoints được thử, trong đó 44 pass, 5 fail, 4 partial và 2 not testable tại thời điểm đo. `final-report.md` tiếp tục cho thấy một bước tiến xa hơn: nhiều lỗi quan trọng đã được sửa, các image đã được rebuild và một chuỗi pipeline chính đã được xác nhận ở mức hệ thống tích hợp. Điều này làm cho Chương 6 có thêm một lớp bằng chứng vận hành thực tế, bên cạnh các test suites và manifests đã phân tích trước đó.

Table 6.8 summarizes the most important E2E and operational verification artifacts available at thesis-writing time.

| Artifact | Môi trường / phạm vi | Giá trị đối với luận văn |
| --- | --- | --- |
| `e2e-report.md` | K3s production cluster, 55 tested endpoints | cung cấp bằng chứng E2E ở mức service integration và chỉ ra bug thực tế |
| `final-report.md` | hậu kiểm sau sửa lỗi và tái triển khai | chứng minh một số nút thắt chính của pipeline đã được gỡ bỏ và re-verified |
| `analysis-srv/tests/e2e/*` | analytics service scope | cung cấp bằng chứng E2E trong phạm vi analytics contracts |
| `test/full_check/*` | cross-service scenario scope | cung cấp bằng chứng về decision table, idempotency và runtime safety ở mức liên service |

## 6.3 Performance Evaluation

### 6.3.1 Lớp lý thuyết

Đánh giá hiệu năng của hệ thống phân tán có thể được tiếp cận theo hai mức. Mức thứ nhất là benchmark định lượng, bao gồm throughput, latency, resource utilization và scaling curves. Mức thứ hai là đánh giá mức độ sẵn sàng về hiệu năng, tức đánh giá hệ thống đã được thiết kế với những cơ chế nào để hỗ trợ hiệu năng và khả năng mở rộng, ngay cả khi chưa có benchmark report đầy đủ.

Trong trường hợp repo không chứa benchmark artifacts hoàn chỉnh, mức đánh giá thứ hai là phù hợp hơn. Nó cho phép luận văn phân tích các chỉ báo hiệu năng từ code và manifest như resource limits, HPA config, asynchronous processing model, batching strategy, cache layers và queue separation.

### 6.3.2 Lớp phân tích trên dự án SMAP

Các bằng chứng trong current workspace cho thấy analytics consumer là thành phần có performance consideration rõ nhất. Deployment của `analysis-consumer` cấu hình request `500m CPU`, `1.5Gi` memory và limit `2000m CPU`, `4Gi` memory. HPA của workload này scale theo CPU tới `maxReplicas: 3` và có behavior tránh scale down quá nhanh để giảm Kafka rebalance churn. Những thông số này cho thấy nhóm phát triển đã chủ động thiết kế analytics consumer như một workload có thể co giãn và có khả năng chịu tải tăng dần theo batch.

Ngoài ra, search flow trong `knowledge-srv` có cache layer và giới hạn kết quả, trong khi analytics search/chat path sử dụng Qdrant thay vì quét dữ liệu quan hệ trực tiếp. Đây là các quyết định thiết kế có tác động trực tiếp đến hiệu năng truy hồi. Ở `analysis-srv`, việc đưa pipeline vào `asyncio.to_thread` còn cho thấy nỗ lực tách I/O orchestration khỏi phần xử lý CPU-bound.

### 6.3.3 Bảng chỉ báo hiệu năng có bằng chứng

| Chỉ báo | Giá trị / cơ chế | Bằng chứng |
| --- | --- | --- |
| Analytics consumer autoscaling | `minReplicas=1`, `maxReplicas=3`, scale theo CPU 70% | `analysis-srv/manifests/hpa.yaml` |
| Analytics consumer resources | request `500m CPU`, `1.5Gi RAM`; limit `2000m CPU`, `4Gi RAM` | `analysis-srv/apps/consumer/deployment.yaml` |
| Startup tuning | `startupProbe` cho load model chậm | cùng file |
| Graceful shutdown | `terminationGracePeriodSeconds=60` | cùng file |
| Search caching | search results cache trong Redis | `knowledge-srv/internal/search/usecase/search.go`, `knowledge-srv/internal/search/repository/redis/cache.go` |
| Async processing | `asyncio.to_thread` cho pipeline | `analysis-srv/internal/consumer/server.py` |
| Kafka producer reliability | idempotent, gzip, `acks=all` | `analysis-srv/README.md` |

### 6.3.4 Giới hạn đánh giá hiệu năng

Hiện chưa tìm thấy benchmark report, load-test report hoặc file kết quả đo chính thức trong repo để khẳng định các số liệu như request latency trung bình, throughput của analytics pipeline hay số lượng WebSocket connections tối đa đã được thử nghiệm. Do đó, luận văn chỉ đánh giá hiệu năng ở mức các chỉ báo thiết kế hướng hiệu năng và các dấu hiệu sẵn sàng trong runtime, không khẳng định số liệu benchmark cụ thể nếu không có hiện vật hỗ trợ.

### 6.3.5 Evaluation Summary Matrix

Table 6.6 summarizes the current evaluation strength of each major subsystem based on available tests, contracts, and deployment evidence.

| Subsystem | Evaluation evidence | Strength level | Nhận xét |
| --- | --- | --- | --- |
| Authentication | routes, config auth, websocket auth tests | Medium | có bằng chứng bảo mật và route behavior, nhưng thiếu auth-specific acceptance tests độc lập |
| Project lifecycle | decision table tests, idempotency tests, route evidence | High | lifecycle transitions được kiểm tra ở nhiều trạng thái và có logic block/allow rõ |
| Ingest runtime | UAP tests, dry run completion tests, idempotency contract tests | High | có bằng chứng tốt cho contract correctness và runtime safety |
| Analytics pipeline | unit tests, E2E output contract tests, domain routing tests, crisis tests | High | là phần có test evidence phong phú và chiều sâu nhất |
| Knowledge layer | search/chat implementation evidence, indirect contract protection từ analytics tests | Medium | input contract được bảo vệ tốt nhưng end-user acceptance tests cho search/chat còn hạn chế |
| Notification layer | websocket tests, contract docs, dispatch usecases | Medium | có bằng chứng tốt ở transport layer nhưng chưa có nhiều integration tests ở quy mô lớn |

### 6.3.6 Threats to Validity

Table 6.7 identifies the main threats that may limit how broadly the evaluation results can be generalized.

| Threat category | Mô tả | Ảnh hưởng đến kết luận |
| --- | --- | --- |
| Internal validity | một số yêu cầu được suy ra từ code và docs hơn là từ SRS chính thức | có thể làm cách diễn đạt requirement mang tính tái cấu trúc hơn là phản ánh tài liệu gốc |
| Construct validity | benchmark định lượng chưa có đầy đủ trong repo | phần hiệu năng chỉ kết luận ở mức readiness indicators, không phải controlled experiments |
| External validity | frontend source đã hiện diện trong workspace, nhưng phần đánh giá hiện vẫn thiên mạnh về backend, runtime và integration architecture; CI/CD artifacts vẫn chưa rõ | các kết luận mạnh nhất vẫn nằm ở backend contracts, service interactions và vận hành tích hợp |
| Artifact maturity | một số contract là canonical nhưng rollout runtime chưa đồng đều | một số kết luận cần tiếp tục được hiểu là current/partial thay vì universal deployment fact |

## 6.4 Tổng kết chương

Từ các test assets, manifest và các báo cáo E2E hiện có, có thể kết luận rằng SMAP không chỉ được xây dựng theo hướng hiện thực tính năng mà còn có đầu tư vào kiểm thử và mức sẵn sàng cho vận hành. Analytics layer có test suite và scaling manifest rõ nhất. Workspace cũng chứa nhiều test scenario mang tính contract/integration ở cấp hệ thống, đồng thời đã có thêm bằng chứng vận hành thực tế từ `e2e-report.md` và `final-report.md`. Tuy nhiên, dữ liệu benchmark định lượng vẫn còn thiếu nếu xét theo chuẩn đánh giá đầy đủ của một luận văn hoàn chỉnh.

Điều này không làm mất giá trị của hệ thống, nhưng cần được ghi rõ như một hạn chế về artifact đánh giá. Về mặt khoa học, việc thừa nhận giới hạn chứng cứ quan trọng hơn việc điền vào các số liệu không có nguồn. Nhờ vậy, toàn bộ luận văn vẫn giữ được tính chính xác và tuân thủ nguyên tắc bằng chứng mã nguồn.
