# End-to-End Test Summary

## 1. Phạm vi và môi trường

| Hạng mục | Nội dung dùng trên slide |
|---|---|
| Môi trường | K3s production cluster, gateway `smap-api.tantai.dev` qua Traefik |
| Auth | JWT cookie `smap_auth_token` |
| Test user | `e2e-test`, role `ADMIN` |
| Services | `identity-srv`, `project-srv`, `ingest-srv`, `knowledge-srv`, `notification-srv`, `crawler-worker` |
| Cách kiểm thử | Bash script gọi API thật bằng `curl`, parse JSON bằng `jq`, xác thực bằng JWT cookie |
| UI evidence | Browser Agent thao tác trên production UI và lưu ảnh `.webp` |

## 2. Dùng gì để test

| Thành phần | Công cụ | Vai trò |
|---|---|---|
| API E2E | Bash + `curl` | Gọi trực tiếp các endpoint qua API Gateway |
| JSON assertion | `jq` | Đọc `error_code`, `data`, ID entity, trạng thái lifecycle |
| Auth | JWT cookie | Mô phỏng user đã đăng nhập khi gọi API |
| Cluster verification | `kubectl`, `psql` | Kiểm tra pod/log, trạng thái datasource và audit table |
| UI evidence | Browser Agent | Thao tác trên production UI, chụp ảnh màn hình `.webp` |

## 3. Kết quả tổng hợp

| Nhóm | Số lượng | Ghi nhận |
|---|---:|---|
| Health check | 6/6 | Tất cả service chính trả `healthy` |
| Endpoint được gọi | 55 | Bao phủ identity, project, ingest, knowledge, notification, crawler |
| Endpoint đạt kỳ vọng | 44 | Status và body đúng theo kịch bản |
| Kiểm chứng một phần | 4 | Response hợp lệ nhưng còn giới hạn về mapping hoặc paginator |
| Not testable | 2 | Một số luồng cần điều kiện runtime/browser đầy đủ hơn |

## 4. Health evidence

| Service | HTTP | Kết quả quan sát |
|---|---:|---|
| `identity-srv` | 200 | `status=healthy` |
| `project-srv` | 200 | `status=healthy` |
| `ingest-srv` | 200 | `status=healthy` |
| `knowledge-srv` | 200 | `status=healthy` |
| `notification-srv` | 200 | `status=healthy`, `redis=connected` |
| `crawler-worker` | 200 | `status=healthy`, `worker_active=true` |

## 5. Use case evidence

| Luồng kiểm thử | Evidence chính |
|---|---|
| Campaign/Project setup | Campaign CRUD 8/8 pass; Project CRUD cơ bản 7/7 pass; project tạo ở trạng thái `PENDING` |
| Datasource/Target setup | Datasource CRUD 6/6 pass; `source_category=CRAWL` được tự suy luận; target create/list/update/delete hoạt động |
| Project activation | Readiness trả đúng `can_proceed=false` khi thiếu datasource; activate sai điều kiện bị từ chối bằng lỗi nghiệp vụ `160026`; kịch bản đủ điều kiện activate thành công |
| Knowledge/Search/Chat | Search trả 200; Chat tạo conversation bằng `gemini-2.0-flash`; conversation detail có 4 messages; suggestions trả 2 gợi ý tiếng Việt |
| Report capability | `POST /reports/generate` được tiếp nhận, report lưu đúng `user_id` và trả trạng thái `PROCESSING` |
| Crisis runtime | `project-srv -> ingest-srv` apply-runtime trả `crisis_status=CRITICAL`, `applied_crawl_mode=CRISIS`, ảnh hưởng 2 datasource |
| Auto crisis apply | `analysis-consumer` phát hiện `crisis_level=warning`, apply runtime sang `CRISIS`, audit ghi nhận `NORMAL -> CRISIS -> NORMAL` |
| Crawler task | `POST /tasks/facebook` trả 200, task được đưa vào queue `facebook_tasks` |
| Notification | WebSocket route/delivery nội bộ đã xác minh; chưa đo latency WebSocket hai chiều end-to-end |

## 6. Câu chốt slide

| Ý chính | Câu nói ngắn |
|---|---|
| Kết luận | E2E test được chạy trên môi trường K3s thật qua API Gateway, xác minh các luồng nghiệp vụ chính từ campaign/project, ingest, knowledge, crawler đến crisis runtime. |
| Giới hạn | Một số luồng realtime/WebSocket và mapping dry-run vẫn cần bổ sung test sâu hơn trước khi coi là hoàn chỉnh ở mức production. |
