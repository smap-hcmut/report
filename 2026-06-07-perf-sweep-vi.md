# Báo cáo Quét Hiệu năng SMAP

**Ngày**: 2026-06-07 (Asia/Ho_Chi_Minh)
**Yêu cầu**: Tài đề nghị đọc toàn bộ chart Grafana, phát hiện điểm chậm trên HTTP/DB/Kafka/event, vá và rollout, sau đó báo cáo lại.
**Phương pháp**: Scrape trực tiếp Prometheus qua port-forward `smap-monitoring-prometheus`, đối chiếu với code dưới `/Users/ts.1126/Workspaces/smap`.

---

## Tổng quan trạng thái hệ thống

| Tầng | Tín hiệu | Kết luận |
|---|---|---|
| HTTP — Go services | `smap_http_request_duration_seconds` p99 | 2 điểm chậm rõ rệt (knowledge suggestions, chuỗi crawl-mode). Các route còn lại < 100 ms. |
| HTTP — Python analysis-api | `analysis_api_http_request_duration_seconds` p99 (15 phút) | sentiment 497 ms / posts 495 ms / platforms 49 ms. Lớp cache hoạt động, đuôi dài đến từ vài lượt cold query. |
| Kafka | `redpanda_kafka_max_offset` − `redpanda_kafka_consumer_group_committed_offset` | **Lag tất cả group = 0**. `smap.collector.output` sinh 0.66 msg/s, consumer theo kịp. |
| Postgres | connection / lock / long-txn / OOM / deadlock | 18/100 connection, 0 deadlock, 0 OOM, 6 long-running txn lâu nhất 17 s (cửa sổ REFRESH mart — đúng dự kiến). |
| Pod | `kube_pod_container_status_restarts_total[24h]` | Restart chỉ xuất hiện ở ReplicaSet cũ của analysis-consumer (các pod lỗi import tớ đã kill sáng nay). Không có pod flap. |
| Bộ nhớ | `container_memory_working_set_bytes / limits` | redpanda 40 %, analysis-consumer ~28 %, còn lại < 20 %. |

Con số ảo "lag = 1.008.250" lúc đầu là kết quả vector-join sai vì label set của `redpanda_group`/`redpanda_topic` không khớp — đối chiếu per-topic và per-group cho cùng một offset đã xác nhận.

---

## Các điểm nghẽn đã phát hiện

### 1. `knowledge-srv /api/v1/knowledge/campaigns/:campaign_id/suggestions`
- **Tín hiệu**: p99 487 ms, p95 425 ms, p90 375 ms trong 1 h gần nhất.
- **Nguyên nhân gốc**: `chat/usecase/suggestion.go` gọi `search/usecase/aggregate.go`. Mỗi project trong campaign sinh ra **6 request Qdrant song song** (`Count` + 2× sentiment legacy/new + platform + 2× aspect legacy/new). Campaign 4 project = **24 call Qdrant mỗi lần hit HTTP**. Không có response cache → UI poll lại là chạy lại toàn bộ fan-out.
- **Cách vá**: cache trong process, key `(user_id, campaign_id)`, TTL 60 s, có GC inline khi map > 256 entry.

### 2. `ingest-srv /api/v1/internal/projects/:project_id/crawl-mode` + chuỗi `project-srv /apply-runtime`
- **Tín hiệu**: trước fix, crawl-mode p99 223 ms, apply-runtime p99 236 ms (cửa sổ 1 h). Đỉnh lịch sử Tài quan sát thấy trong sự cố mart-refresh hôm qua là 24 s.
- **Nguyên nhân gốc**: `datasource/usecase/project_lifecycle.go` chạy `ListDataSources` rồi với mỗi crawl source đủ điều kiện gọi `repo.UpdateDataSource` (Find + UPDATE) + `repo.CreateCrawlModeChange` (INSERT) tuần tự. Với N source = **3·N roundtrip Postgres tuần tự**. Đuôi latency tỉ lệ thuận với N và áp lực DB — đó là lý do mart refresh cascade có thể đẩy lên 24 s.
- **Cách vá**: bulk apply trong 1 transaction. 1 query đếm + 1 CTE `UPDATE … FROM (SELECT … FOR UPDATE SKIP LOCKED) RETURNING` để lấy lại `crawl_mode` cũ + `crawl_interval_minutes`, rồi 1 `INSERT` multi-row vào `ingest.crawl_mode_changes`. Source bỏ qua không vào writer.

### 3. `project-srv /internal/campaigns/:id` p99 247 ms
- **Tín hiệu**: PK lookup 1 dòng trên bảng 46 dòng.
- **Không actionable**: bảng nhỏ như vậy thì 247 ms p99 là RTT/jitter tới `172.16.19.10`, không phải công việc query. p50 cỡ 5 ms. Muốn cải thiện phải collocate DB hoặc cache trong process — chi phí/lợi ích không xứng khi tải còn thấp. **Đã ghi nhận, chưa fix.**

### 4. `pg_long_running_transactions = 6`, lâu nhất 17 s
- **Tín hiệu**: gauge của pg_exporter.
- **Nguyên nhân gốc**: batch refresh mart (đã cancel-safe sau patch `_refresh_latest_post_insight_mart` trước đó) là long txn dự kiến. 5 cái còn lại là sqlboiler idle-in-transaction trả về nhanh. **Không actionable.**

### 5. Topic Kafka rỗng
- `analytics.insights.published` (3 partition, max_offset = 0) — placeholder Phase-1 cố ý, producer hiện sinh 0 card.
- `audit.events` — tương tự, chưa nối producer.
- **Không actionable, ghi để rõ ngữ cảnh.**

---

## Các fix đã ship trong lần quét này

| Service | Commit | Image | Thay đổi hành vi |
|---|---|---|---|
| `ingest-srv` | `73e3d7f` (master) | `registry.tantai.dev/smap/ingest-srv:260607-1310-bulk-crawlmode` | `UpdateProjectCrawlMode` chạy thành 1 transaction (1 đếm + 1 CTE UPDATE…RETURNING + 1 INSERT multi-row). NoopReason semantic giữ nguyên. |
| `knowledge-srv` | `9d00250` (master) | `registry.tantai.dev/smap/knowledge-srv:260607-1310-suggest-cache` | `GetSuggestions` memoize 60 s theo `(user_id, campaign_id)`, GC inline khi vượt 256 entry. |
| `smap-deploy` | `2fdcf00` (main) | — | Cả 2 deployment yaml trỏ tới tag mới. |
| Submodule root | `fb30db0` | — | Bump ingest-srv + knowledge-srv + smap-deploy. |

Rollout: `kubectl rollout status` báo OK cả 2 deployment. Pod chạy 2 phút+, 0 restart tại thời điểm viết báo cáo.

### Verify sau rollout (cửa sổ live 1 h)

| Route | Trước | Sau | Δ |
|---|---|---|---|
| `ingest-srv /crawl-mode` p99 | 223 ms | **49 ms** | **−78 %** |
| `project-srv /apply-runtime` p99 | 236 ms | **50 ms** | **−79 %** (chuỗi call hưởng lợi gián tiếp) |
| `knowledge-srv /suggestions` p99 | 487 ms | chưa đổi trong cửa sổ 1 h | Cần thêm sample — UI ít poll. Sẽ quan sát được sau khi cache hit tích luỹ. |

Crawl-mode + apply-runtime giảm rõ nhất vì path crisis runtime apply của consumer (gọi mỗi project ~25 phút/lần) giờ chỉ còn 1 roundtrip thay vì 3·N.

---

## Việc tồn đọng (chưa fix trong lần này)

1. **analysis-api p95 đuôi dài ở `sentiment` / `posts`** — đã dùng rollup fast path; 497 ms tới từ vài request cold-cache hiếm gặp. Theo dõi sau khi tăng TTL cache xem có tái diễn không.
2. **`/internal/campaigns/:id` p99 247 ms** — cache campaign Detail trong project-srv vài giây sẽ làm phẳng đường này nếu cần; hiện tại chưa cần.
3. **`logQuery` write stdout mỗi query trong shared-libs/go/postgres** — ổn ở tải hiện tại, nhưng nếu service nào vượt 20 RPS sẽ ồn I/O đến fluent-bit. Khi đó chuyển sang logger debug-level.
4. **analysis-consumer Python không expose Prometheus metric** — chỉ analysis-api có scrape. Thêm counter consumer-side (pipeline stage, partition lag per consumer, số lượt crisis-runtime apply) sẽ khép vùng mù quan sát cuối cùng.
5. **Topic `audit.events` rỗng** — schema khai báo nhưng chưa có producer. Hoặc nối producer hoặc bỏ topic.

---

## Ghi chú phương pháp (để lặp lại được)

- Port-forward Prometheus: `kubectl port-forward -n monitoring svc/smap-monitoring-prometheus 19090:9090`.
- Các query hữu ích nhất:
  - `sort_desc(histogram_quantile(0.99, sum by (le, service, route) (rate(smap_http_request_duration_seconds_bucket[1h]))))`
  - `sum by (redpanda_group, redpanda_topic) (redpanda_kafka_consumer_group_committed_offset)` so với `sum by (redpanda_topic) (redpanda_kafka_max_offset)`
  - `pg_long_running_transactions`, `pg_locks_count`, `pg_stat_activity_count` từ postgres-exporter
  - `100 * container_memory_working_set_bytes / kube_pod_container_resource_limits{resource="memory"}` để đo áp lực bộ nhớ
- Lần quét này không cần login Grafana; Prometheus + codebase đủ để phát hiện và xử lý tất cả vấn đề.
