# SMAP Report — Review Findings

**Phạm vi**: review chéo `report/final-report/` (Typst) với code thực tại các service repo + `smap-deploy/`.
**Ngày**: 2026-05-09.
**Phương pháp**: 6 Explore agent song song theo chương + verify thủ công các finding cốt lõi.
**Verdict tổng**: 8/10 — nội dung phần lớn đúng, 4 vấn đề CỨNG cần sửa trước nộp + nhiều gap minor.

---

## 1. Vấn đề CỨNG (phải fix trước nộp)

### 1.1 Whisper được liệt kê nhưng KHÔNG triển khai — `HIGH`

**Vị trí trong report**:
- `chapter_8/index.typ:80` — reference `OpenAI Whisper. (2024). Whisper - Robust Speech Recognition`
- `chapter_9/index.typ:559-562` — Phụ lục B (Bảng thuật ngữ): "Whisper — Mô hình speech-to-text của OpenAI để chuyển đổi audio sang transcript"
- `report/README.md:46` — bảng services "Speech2Text — Chuyển đổi âm thanh thành văn bản (Whisper)"

**Thực tế code**:
- `grep -ri "whisper"` trong `scapper-srv/`, `analysis-srv/`, `knowledge-srv/`, `ingest-srv/` chỉ hit ở `.venv` vendor (onnxruntime/transformers shipped Whisper graphs). KHÔNG có file source nào của project import Whisper.
- `scapper-srv/requirements.txt` không có `openai-whisper` hoặc `faster-whisper`.
- `analysis-srv/pyproject.toml` không có Whisper dependency.
- Không có service "speech2text" trong workspace; SYSTEM_CONTEXT.md liệt kê 9 service không có speech2text.
- YouTube handler `scapper-srv/app/handlers/youtube.py` lấy transcript từ TinLikeSub SDK (text caption đã có sẵn), không transcribe audio.

**Đề xuất**:
- Bỏ Whisper khỏi `chapter_8` references.
- Bỏ Whisper khỏi `chapter_9` glossary HOẶC chuyển sang section "Future work / Tham khảo công nghệ liên quan".
- Sửa `report/README.md` bỏ dòng Speech2Text.
- Nếu giữ Whisper cho hướng phát triển, ghi rõ "chưa triển khai".

---

### 1.2 Port service trong bảng triển khai SAI vs K8s — `MED`

**Vị trí trong report**: `chapter_5/section_5_7.typ:209-318` (bảng pod & port mục 5.7.6)

**Báo cáo claim** | **K8s thực tế** | **Verify**
---|---|---
identity-api: 8080 | 8080 | OK (`smap-deploy/services/identity/configmap.yaml:19` HTTP_SERVER_PORT='8080')
project-api: **8082** | **8080** | SAI (`smap-deploy/services/project/configmap.yaml:23` HTTP_SERVER_PORT='8080'; deployment.yaml:76 containerPort 8080)
ingest-api: **8081** | **8080** | SAI (`smap-deploy/services/ingest/configmap.yaml:15` HTTP_SERVER_PORT='8080'; deployment.yaml:80 containerPort 8080)
analysis-api: 8080 | 8080 | OK
knowledge-api: 8080 | 8080 | OK (`smap-deploy/services/knowledge/configmap.yaml:16`)
notification-delivery: 8081 | 8081 | OK (`smap-deploy/services/notification/configmap.yaml:26` SERVER_PORT='8081')
scrapper-api: 8105 | 8105 | OK

**Nguyên nhân**: 8081/8082 là port LOCAL DEV (xem `ingest-srv/config/config.go:245` `microservice.ingest.base_url=http://localhost:8081`, `project-srv/config/config.go:261` `localhost:8082`) để chạy nhiều service cùng máy. Trong K8s mỗi pod có IP riêng nên đều dùng 8080.

**Đề xuất**: Sửa bảng 5.7.6:
- ingest-api: 8081 → 8080
- project-api: 8082 → 8080
- HOẶC thêm cột "Local dev port" tách riêng "K8s container port".

**Hệ luỵ phụ**: `report/README.md:34-39` cũng dùng port 8080-8083 cũ cho "Identity/Project/Collector/WebSocket" — service "Collector" không tồn tại (đã đổi tên thành ingest-srv). Sửa README đồng bộ.

---

### 1.3 `infra_error 0.0000%` mâu thuẫn với CSV gốc — `MED`

**Vị trí trong report**: `chapter_6/index.typ:1093-1112` (bảng kết quả NFR)

**Báo cáo claim baseline**:
- Timeout: 0.0360%
- Infra error: **0.0000%**

**CSV gốc**: `smap-deploy/nfr/artifacts/20260507_baseline_auth_02/raw/metrics/requests-metrics.csv:13`
```
infra_error_rate,all,0.0360,pct,partial,...,"5xx and status 000 only"
```

**Phân tích**:
- CSV định nghĩa `infra_error = 5xx + status 000` → baseline = 0.0360% (3 timeout ÷ 8336).
- Báo cáo dùng định nghĩa khác (5xx-only) → 0.0000%.
- 3 kịch bản còn lại (expected/peak/chaos) baseline timeout=0% nên cả 2 định nghĩa đều ra 0% → chỉ baseline mismatch.

**Đề xuất**:
- Hoặc đổi báo cáo: `Infra error baseline = 0.0360%` cho khớp CSV.
- Hoặc giữ định nghĩa của báo cáo nhưng ghi chú rõ: `Infra error định nghĩa = HTTP 5xx; timeout (status 000) tách cột Timeout`. Đồng bộ chú thích trong CSV (`smap-deploy/nfr/artifacts/20260507_baseline_auth_02/raw/metrics/requests-metrics.csv:13`).

---

### 1.4 Embedding model + vector dim KHÔNG nói trong design — `MED`

**Vị trí trong report**: `chapter_5/section_5_3_6.typ` (knowledge-srv design), `chapter_5/section_5_4.typ` (database/storage)
**Vấn đề**: Không câu nào trong toàn report nhắc tới embedding provider hoặc vector dimension. `grep -i "voyage\|embedding\|1024\|768"` trong `chapter_5/` ra rỗng.

**Thực tế code**:
- `knowledge-srv/internal/indexing/usecase/constants.go:3`: `const defaultVectorSize uint64 = 1024`
- `knowledge-srv/config/config.go:100`: `VoyageConfig is the configuration for Voyage AI (embedding)`
- `knowledge-srv/config/config.go:107`: LLM providers `gemini, openai, deepseek, qwen`
- `knowledge-srv/config/config.go:404`: `viper.SetDefault("gemini.model", "gemini-1.5-pro")`

**Đề xuất**: Bổ sung vào `section_5_3_6.typ` hoặc `section_5_4.typ`:
- Embedding provider: Voyage AI (vector dim = 1024).
- LLM provider: round-robin Gemini 1.5 Pro / OpenAI / DeepSeek / Qwen.
- Lý do chọn Voyage thay vì PhoBERT 768d hoặc text-embedding-3-small 1536d.

---

## 2. Số liệu CHƯA CHỨNG MINH (suspicious / single observation)

### 2.1 Latency search/chat là single shot, không phải SLA

**Vị trí**: `chapter_6/index.typ:626` (~13ms search), `:629` (~2266ms chat), `:820` (~1632ms chat follow-up).

**Vấn đề**: 1 lần đo manual E2E, không có repeat hoặc percentile. Chat 2266ms phần lớn là Gemini LLM RTT — phụ thuộc provider load tại thời điểm đo.

**Đề xuất**: Ghi rõ "single observation, không phải SLA". Nếu muốn benchmark, chạy ≥ 30 lần lấy p50/p95.

### 2.2 UI metrics từ screenshot Ahamove production

**Vị trí**: `chapter_6/index.typ:710` (1,016 mentions, 28.1% sentiment), `:886` (YouTube 1,031 mentions 12.3K engagement 28% sentiment), `:896` (1.1K mentions, 12.6K engagement, 15.1M reach).

**Vấn đề**: Số liệu real production data — không phải synthetic fixture. Không có cách verify lại nếu DB bị reset. Phù hợp cho functional E2E nhưng đừng diễn giải thành benchmark.

**Đề xuất**: Caption rõ "screenshot live data tại thời điểm chạy E2E" — đã có sẵn `images/chapter_6/TC02_campaign_switcher.webp`, `TC05_project_list_api.webp`. OK.

### 2.3 Orphan tasks 17,319 chưa kết luận

**Vị trí**: `smap-deploy/nfr/artifacts/20260507_baseline_auth_02/summary.md:31, 57` — artifact ghi 17319 orphan rows. Report `chapter_6/index.typ:1209` thừa nhận "duplicate, loss, orphan...chưa được khoá thành hard-result".

**OK về tính trung thực**, nhưng nên thêm 1 câu giải thích bản chất orphan (request 4xx 409 conflict bị mark dispatch nhưng task không tiến). 17K trên 8336 request là số lớn — có thể gây hiểu nhầm "data integrity tệ".

### 2.4 Claim chung không đo SMAP

`section_3_7.typ` (chapter 3): "GC pause thường dưới 1ms", "hàng nghìn / hàng triệu goroutine" — claim chung về Go, không đo trong SMAP. Acceptable cho theory section, nhưng nếu muốn dùng làm justification cho NFR thì cần benchmark.

---

## 3. MISSING (code có nhưng report không nhắc)

### 3.1 Dryrun chỉ hỗ trợ 2 tổ hợp source/target đầy đủ

**Code thực tế**: `e2e-report.md` ghi rõ chỉ TIKTOK+KEYWORD, FACEBOOK+POST_URL có dryrun đầy đủ. Các tổ hợp khác bypass.

**Vị trí design**: `chapter_5/section_5_3_4.typ` (ingest-srv) im lặng về giới hạn này.

**Đề xuất**: Thêm 1 đoạn nhỏ trong design 5.3.4 hoặc trong limitation `chapter_7/index.typ`.

### 3.2 Discord alert dispatch — đề cập trong design nhưng không có code

**Vị trí design**: `chapter_5/section_5_3_5.typ` (notification-srv) đề cập Alert Dispatch UseCase với Discord.

**Code**: Không tìm thấy Discord webhook client trong `notification-srv/`. SYSTEM_CONTEXT.md:192 ghi "Alert domain can forward crisis alerts to Discord" — nhưng grep không ra implementation cụ thể.

**Đề xuất**: Verify lại có Discord client thật không. Nếu chưa có → đổi sang "future work".

### 3.3 Redis TTL / data retention không đặc tả

`chapter_5/section_5_4.typ` không nêu TTL của:
- Session blacklist (identity-srv)
- Notification message buffer
- Domain registry `smap:domains`
- RAG cache

Code có config nhưng report không đề cập → mất chi tiết design.

### 3.4 Model versioning

`chapter_5/section_5_3_2.typ` (analysis-srv) không pin version PhoBERT. Code: `analysis-srv/internal/model/constant.py:13` chỉ cho path `internal/model/phobert`, không metadata version.

### 3.5 Crisis config status read endpoint

Ch9 phụ lục API đề cập CRUD crisis config. Không có endpoint `GET /:project_id/crisis-config/status` — phải đọc qua nested object trong `GET /projects/:id`. Minor clarity.

---

## 4. KIỂM CHỨNG ĐÚNG (đã verify hard với code/artifact)

Để tham khảo những phần KHÔNG cần sửa:

### 4.1 Performance numbers ch6 — match CSV gốc
| Metric | Report | CSV | Path |
|---|---|---|---|
| Throughput baseline | 6.949 req/s | 6.949 | `requests-metrics.csv:3` |
| p95 baseline | 159.397 ms | 159.397 | `:5` |
| Throughput peak | 7.440 | 7.440 | exact |
| Throughput chaos | 7.751 | 7.751 | exact |
| p95 range 159-224ms | match | exact | exact |

### 4.2 RabbitMQ queue + Kafka topic
- 5 queue (`tiktok_tasks`, `facebook_tasks`, `youtube_tasks`, `ingest_task_completions`, `ingest_dryrun_completions`) match `shared-libs/go/constants/queues.go`.
- 6 topic (`smap.collector.output`, `analytics.batch.completed`, `analytics.insights.published`, `analytics.report.digest`, `project.events`, `audit.events`) match `shared-libs/go/constants/topics.go`.

### 4.3 Tech version
- Go 1.25.6 (`identity-srv/go.mod:3`)
- Next 15.1.0, React 19, TypeScript 5.7, Tailwind 3.4.19, Electron 33 (`web-ui/package.json`)
- FastAPI 0.115.6 (`scapper-srv/requirements.txt`)
- SQLBoiler v4.19.7 (`identity-srv/go.mod`)

### 4.4 K8s deployment
- HPA analysis-consumer: `maxReplicas: 2`, `averageUtilization: 70` — match `smap-deploy/services/analysis/hpa.yaml:25,32`.
- 3 node k3s-01/02/03, K8s v1.30.14+k3s2 — match `SYSTEM_CONTEXT.md:33-34`.

### 4.5 NLP config
- PhoBERT max_length=256, SpaCy-YAKE dedup=0.8, max_kw=30 — match `analysis-srv/internal/model/constant.py:13-21`.
- batch_size publisher=100, consumer=6 — match `analysis-srv/config/config.py`.

### 4.6 Trace use case → code
- 12/12 FR (FR-01..12) đều có route HTTP tương ứng.
- 5/5 UC (UC-01..05) trace được code: campaign/project/datasource/target/dryrun/activate/pause/resume/archive.
- Crisis runtime apply: `internal/projects/:project_id/crisis-config/apply-runtime` match `project-srv` route.

### 4.7 Test coverage
- 309 pytest analysis-srv (file count grep: ~289 functions + parametrize) — match log Ch6.
- 68 Go package coverage 100% — `go test -cover` log inline in Ch6 verifiable từng dòng.

---

## 5. Khuyến nghị thứ tự fix

**Trước phản biện**:
1. Sửa Whisper (1.1) — gỡ khỏi 3 chỗ.
2. Sửa port table (1.2) — `section_5_7.typ` 2 dòng.
3. Sửa hoặc note rõ infra_error (1.3) — `chapter_6/index.typ:1117` thêm chú thích.
4. Bổ sung Voyage + vector 1024 (1.4) — 1 đoạn vào `section_5_3_6.typ`.

**Trước nộp final**:
5. Bổ sung Dryrun limitation (3.1).
6. Verify Discord (3.2).
7. Thêm note "single observation" cho latency search/chat (2.1).

**Tuỳ chọn (nice-to-have)**:
8. TTL/retention (3.3).
9. Model version (3.4).
10. Soak test 4-8h, chaos matrix mở rộng (Ch7 đã thừa nhận, không bắt buộc fix).

---

## 6. Đánh giá tổng

| Chương | Verdict | Mismatch | Note |
|---|---|---|---|
| Ch1 Giới thiệu | OK | 0 | scope đúng |
| Ch2 Liên quan | OK | 0 | không over-claim |
| Ch3 Phân tích yêu cầu | OK | 0 | 9/10 section verified, 3.2 theory only |
| Ch4 Phân tích hệ thống | OK | 0 | 100% FR/UC trace được code |
| Ch5.1-5.3 Thiết kế (1) | OK | 0 | 35 verified, 12 pattern claim |
| Ch5.4-5.8 Thiết kế (2) | WARN | 2 | port + vector dim |
| Ch6 Kiểm thử | WARN | 1 | infra_error definition |
| Ch7 Tổng kết | OK | 0 | trung thực về limitation |
| Ch8 Tham khảo | FAIL | 1 | Whisper bịa |
| Ch9 Phụ lục | OK | 1 | Whisper glossary + minor API gap |

**Kết luận**: Báo cáo có nền tảng vững — số liệu NFR exact match artifact, kiến trúc trace được code 100%. 4 fix CỨNG nhỏ (Whisper, port, infra_error, embedding) sẽ đưa lên 9/10. Phần lớn còn lại là gap minor không ảnh hưởng kết luận.
