# Indexing Performance Benchmark (Campaign/Project Start → First Data)

## Mục tiêu
Đo thời gian từ lúc `Campaign` và `Project` đã tồn tại đến lúc xuất hiện dữ liệu đầu tiên tại pipeline phân tích/index.

Tính:

- `INDEXING_START_REF_MS = max(campaign.created_at, project.created_at)` (epoch ms)
- `INDEXING_FIRST_DATA_MS = min(first indexed_documents, first post_insight)`
- `INDEXING_TTFD_MS = INDEXING_FIRST_DATA_MS - INDEXING_START_REF_MS`

Mục tiêu đánh giá:

- Có phải baseline đo nhất quán hay chưa.
- Tỉ lệ run có dữ liệu sau khi chạy indexing.
- Phân phối thời gian tạo dữ liệu đầu tiên.
- Hướng tối ưu triệt để để giảm TTFD và giảm run no-data.

## Khuôn đo đã cài trong script

- Script: `smap-deploy/e2e-test.sh`
- Đầu ra summary đã bổ sung block `Indexing timing`:
  - `Index baseline`
  - `First indexed_documents`
  - `First post_insight`
  - `First DB data`
  - `Campaign->project start → first data`
  - `Search first hit`

## Cách verify (DB direct check)

Query trực tiếp đã dùng để xác thực:

```sql
WITH joined AS (
  SELECT
    p.id AS project_id,
    p.campaign_id,
    GREATEST(c.created_at, p.created_at) AS start_at
  FROM project.projects p
  JOIN project.campaigns c ON c.id = p.campaign_id
  WHERE p.name LIKE 'E2E Test Project%' AND c.name LIKE 'E2E Test Campaign%'
),
first_data AS (
  SELECT project_id, MIN(created_at) AS first_data_at
  FROM (
    SELECT project_id::text AS project_id, created_at
    FROM knowledge.indexed_documents
    UNION ALL
    SELECT project_id, created_at
    FROM analysis.post_insight
  ) s
  GROUP BY project_id
)
SELECT
  j.project_id,
  EXTRACT(EPOCH FROM (f.first_data_at - j.start_at)) AS ttfd_sec,
  f.first_data_at
FROM joined j
LEFT JOIN first_data f ON f.project_id = j.project_id::text
ORDER BY ttfd_sec DESC NULLS LAST;
```

## Kết quả verify hiện tại (mẫu mới nhất)

| campaign_id | project_id | campaign_created_at | project_created_at | indexing_start_at | first_indexed_doc_at | first_post_insight_at | first_data_at | TTFD (min) | TTFD (sec) |
|---|---|---|---|---|---|---|---|---:|---:|
| `1d1515a2-1753-4b62-8ba0-a66f2930d6ae` | `18190715-55b4-4a9b-bd04-4b43f9e133b4` | `2026-06-05 10:05:41.114932+00` | `2026-06-05 10:05:41.178177+00` | `2026-06-05 10:05:41.178177+00` | `2026-06-05 10:11:24.394654+00` | `2026-06-05 10:11:06.856768+00` | `2026-06-05 10:11:06.856768+00` | `5.4279765` | `325.679` |

=> TTFD: `~5m26s`.

## Thống kê 14 run E2E gần nhất (theo tên E2E Test)

- Tổng số run: 14
- Có dữ liệu first-data: 7/14
- Không có dữ liệu: 7/14

Phân phối TTFD cho các run **có dữ liệu**:

- min = `290.615s` (~4m50.6s)
- avg = `1379.078s` (~22m59s)
- max = `4119.985s` (~68m40s)
- p50 = `324.902s` (~5m25s)
- p90 = `4041.774s` (~67m22s)
- p95 = `4080.879s` (~68m01s)

### Chi tiết per-project

| project_id | campaign_id | ttfd_sec | first data source |
|---|---|---:|---|
| `b423d88a-6428-42d6-ae6f-bc1dab5ea8ea` | `032a4916-6792-4e48-abdc-2240882499d9` | `290.614866` | post_insight |
| `dc5f79c0-b526-414b-bb22-09b26318f9a6` | `73e90d88-64a6-4266-9671-ddfc54d78a33` | `294.781717` | post_insight |
| `3ae45497-060b-42d8-9953-3403823f39dd` | `d0b12d15-0c5b-494c-9eb9-94e54afdfdff` | `307.945690` | post_insight |
| `f6f004b0-2dcb-4319-8d75-e892bd049479` | `7c458de7-011a-4b26-b292-8fa74d5522f1` | `324.902389` | post_insight |
| `18190715-55b4-4a9b-bd04-4b43f9e133b4` | `1d1515a2-1753-4b62-8ba0-a66f2930d6ae` | `325.678591` | post_insight |
| `b85d7d34-92d9-4e6f-8275-62224e677bc0` | `7555078c-c526-4483-8999-4068e11231b5` | `3989.632726` | post_insight |
| `292f8dae-4c4c-40b3-8b5c-f278a315aa5c` | `df9b8788-aa18-44c8-9043-ba52746159d7` | `4119.985124` | post_insight |
| `24993e76-c1f9-42a1-a9cc-0c17b6265fee` | `74b80800-77a1-47a5-a6d2-19940b44cad3` | `N/A` | no data |
| `cf4b015b-59a4-457c-829d-9b5415a4a9f1` | `518f718d-a6c5-446e-b8b7-a52b44699f90` | `N/A` | no data |
| `d7c59a4a-c356-4dc7-854c-5c386bede37a` | `08aafa8f-d66a-44b6-bec1-bfe034f153b0` | `N/A` | no data |
| `29bb54af-5e86-4bea-8637-f7bd7aaa62c3` | `d693afdc-687b-4b35-9638-284d1dd67bcf` | `N/A` | no data |
| `f15b53cb-3fce-48d2-9779-177f6dac6bd1` | `47a2d587-3ebc-4d7e-a6ab-d7305e5585a3` | `N/A` | no data |
| `6cad224d-0c86-4b69-ad86-c58ddc613686` | `f9eec951-d81f-41c6-b5d7-1d01cb8140dc` | `N/A` | no data |
| `d5041698-de9d-452e-9306-c5fc0a2a3e5e` | `f2663161-d026-49fe-a1f5-d90e62a29a07` | `N/A` | no data |

## Đánh giá

- Chuỗi dữ liệu cho thấy lỗi chính không còn là tính toán metric mà là chất lượng run:
  - 50% run mất data hoàn toàn.
  - Tail latency của nhóm có data rất cao (p90 ~67m), vượt xa mong muốn demo/production.
- Mọi optimization phải tối ưu 2 mục tiêu cùng lúc:
  1) Độ tin cậy có data.
  2) Rút ngắn p90/p95.

## Kế hoạch tối ưu hóa triệt để (ưu tiên cao trước)

1. Hardening queue/consumer (tránh “silent dead”):
   - Đặt idempotency key (`project_id + target_id + run_id`) cho ingest job.
   - Bổ sung retry policy có backoff + jitter + DLQ.
   - auto-recover staged: scapper → ingest → analysis → knowledge.
   - alert khi DLQ > 0 hoặc consumer lag tăng liên tục 3 chu kỳ.

2. Giảm delay đến first data:
   - Giám sát queue theo campaign id, ưu tiên campaign mới.
   - Tune concurrency worker analysis/knowledge theo queue backlog.
   - Giảm batch commit timeout cho bước tạo `post_insight`/`indexed_documents`.
   - Theo dõi bottleneck rõ: `SEARCH_TTFD_MS` vs `DB_TTFD_MS`.

3. Tối ưu vận hành:
   - Với mỗi campaign mới, nếu chưa có first data > 10 phút:
     - mark campaign health = warning.
     - auto rerun pipeline stage đầu tiên chưa hoàn thành.
     - ghi incident event để truy vết.
   - Đặt SLA:
     - `INDEXING_TTFD_MS` alert nếu > 600s
     - `SEARCH_TTFD_MS` alert nếu > 420s
     - `no-data rate` > 5%/24h = red.

## Kết luận

- Vòng chỉ mục đã có nền đo chuẩn và có bằng chứng số liệu thống kê.
- Cần ưu tiên fix reliability trước khi optimize throughput vì hiện tại tỷ lệ no-data cao sẽ che đi gain latency.
- Bước tiếp theo để chốt “triệt để”:
  - mở rộng benchmark run (>=20 run), lưu tất cả `INDEXING_*` metrics,
  - sửa consumer fail-recovery,
  - chạy lại để verify p95 giảm đáng kể.
