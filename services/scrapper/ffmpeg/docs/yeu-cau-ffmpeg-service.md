# Yêu cầu triển khai FFmpeg Service

## 1. Mục tiêu
- Tách riêng bước chuyển đổi MP4 → MP3 ra một dịch vụ độc lập để dễ triển khai và scale.
- Giảm kích thước image của crawler, tránh mang theo moviepy/numpy.
- Cho phép crawler gọi HTTP đồng bộ, nhận lại thông tin MP3 ngay sau khi chuyển đổi.

## 2. Luồng xử lý bắt buộc
1. **Crawler** tải MP4 bằng yt-dlp → upload lên MinIO (`videos/{video_id}.mp4`).
2. Crawler gọi `ffmpeg-service` qua HTTP:
   - `POST /convert`
   - Body JSON: `video_id`, `source_object`, `target_object` (tuỳ chọn), `bucket_source`, `bucket_target`.
3. **ffmpeg-service**:
   - Lấy presigned URL (hoặc dùng access key) để stream MP4 trực tiếp từ MinIO.
   - Chạy `ffmpeg` để tạo MP3, stream kết quả lên MinIO (`audios/{video_id}.mp3`).
   - Trả JSON: `{status, video_id, audio_object, bucket, message?}`.
4. Crawler nhận response, lưu metadata (URI, etag nếu cần), tiếp tục pipeline.
5. Nếu service báo lỗi, crawler log + có thể fallback sang chế độ ffmpeg local (tuỳ cấu hình).

## 3. Yêu cầu kỹ thuật
- Service triển khai độc lập (container riêng). Dockerfile cài `ffmpeg` + code FastAPI.
- Dùng **FastAPI** + **Uvicorn** (hoặc framework HTTP tương đương) để expose API.
- MinIO SDK: dùng thông tin từ biến môi trường (`MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, ...).
- Tất cả cấu hình phải đọc từ `os.environ` qua `pydantic-settings` (không phụ thuộc file `.env` khi deploy).
- Giới hạn số job chạy song song (semaphore `MAX_CONCURRENT_JOBS`).
- Log chuẩn: ghi lại command ffmpeg, stderr khi lỗi, thời gian xử lý.
- Endpoint healthcheck: `GET /health` trả `{ "status": "ok" }`.

## 4. Biến môi trường chính
| Biến | Ý nghĩa |
|------|---------|
| `APP_ENV`, `LOG_LEVEL` | Thông tin môi trường/logging |
| `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_SECURE` | Kết nối MinIO |
| `MINIO_BUCKET_SOURCE`, `MINIO_BUCKET_TARGET`, `MINIO_TARGET_PREFIX` | Quy ước bucket/object |
| `FFMPEG_PATH`, `FFMPEG_AUDIO_BITRATE`, `FFMPEG_TIMEOUT_SECONDS` | Cấu hình ffmpeg |
| `MAX_CONCURRENT_JOBS` | Số job ffmpeg chạy đồng thời |

## 5. Kế hoạch triển khai
1. Scaffold dự án `scrapper/ffmpeg` với cấu trúc rõ ràng (config, models, converter, main).
2. Viết API `POST /convert`:
   - Validate payload bằng Pydantic.
   - Dùng MinIO client tạo presigned URL.
   - Chạy `ffmpeg` → upload MP3 lên MinIO.
   - Trả JSON theo contract.
3. Bổ sung Dockerfile, requirements, `.env.example`.
4. Cập nhật `docker-compose.yml` để có thêm service `ffmpeg-service`.
5. Cập nhật tài liệu (`README`, docs) giải thích luồng mới và biến môi trường.
6. Sau khi service ổn định, chỉnh sửa crawler để ưu tiên gọi HTTP; fallback local chỉ khi cần.

## 6. Lưu ý bổ sung
- Khi cần scale: chạy nhiều replica `ffmpeg-service` sau load balancer, dùng semaphore để tránh quá tải CPU.
- Có thể mở rộng thành flow async bằng RabbitMQ (publish job, worker consume) nếu tải lớn – kiến trúc hiện tại cần tương thích với bước phát triển đó.
- Quyết định việc xoá MP4 gốc sau khi convert sẽ bàn sau (default: giữ lại).

## 7. Kiến trúc thư mục (cmd-based)

```
ffmpeg/
├── cmd/
│   ├── api/
│   │   ├── __init__.py
│   │   ├── main.py        # FastAPI entrypoint, include routers
│   │   └── routes.py      # Định nghĩa các endpoint (health, convert, …)
│   ├── consumer/          # Placeholder cho worker tiêu thụ queue
│   │   └── __init__.py
│   └── cronjob/           # Placeholder cho tác vụ cron
│       └── __init__.py
├── core/
│   ├── __init__.py
│   ├── config.py          # BaseSettings, constants
│   ├── concurrency.py     # Semaphore giới hạn job
│   └── logging.py         # Cấu hình logging chung
├── services/
│   ├── __init__.py
│   └── converter.py       # Logic chạy ffmpeg, upload MinIO
├── models/
│   ├── __init__.py
│   └── payloads.py        # Pydantic schemas cho request/response
├── tests/
│   └── __init__.py        # Placeholder cho test
├── requirements.txt
├── Dockerfile
└── .env.example
```
