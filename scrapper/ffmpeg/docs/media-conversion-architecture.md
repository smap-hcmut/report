## Media Conversion Architecture (YouTube → MP3)

### Overview
1. **Crawl Phase**
   - YouTube crawler downloads the source MP4 via yt-dlp.
   - The file is uploaded to MinIO at `videos/{video_id}.mp4` (exact prefix configurable).
   - Crawler captures metadata such as ETag, size, and upload timestamp for auditing.
2. **Conversion Phase**
   - Crawler calls the HTTP endpoint `ffmpeg-service: POST /convert` with:
     ```json
     {
       "video_id": "ABC123",
       "source_object": "videos/ABC123.mp4",
       "target_object": "audios/ABC123.mp3",
       "bucket_source": "youtube-media",
       "bucket_target": "youtube-media"
     }
     ```
   - ffmpeg service generates a presigned URL (or uses credentials) to stream the MP4, executes ffmpeg, streams MP3 bytes directly into MinIO, and responds with:
     ```json
     {
       "status": "success",
       "video_id": "ABC123",
       "audio_object": "audios/ABC123.mp3",
       "bucket": "youtube-media"
     }
     ```
   - Crawler records the returned MP3 URI (`minio://bucket/audio_object`) and proceeds with downstream tasks.

### Components
| Component | Responsibility |
|-----------|----------------|
| `youtube` crawler service | Scrapes metadata, uploads MP4 to MinIO, calls ffmpeg service, persists MP3 info. |
| `ffmpeg-service` (FastAPI) | Runs ffmpeg, streams conversion between MinIO objects, enforces concurrency limits, emits diagnostics. |
| MinIO | Object storage for both MP4 source and MP3 output. |
| RabbitMQ (optional) | Can be introduced later for async job distribution if needed. |

### Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `MEDIA_FFMPEG_SERVICE_URL` | Base URL of ffmpeg HTTP API. When unset, crawler falls back to local ffmpeg/yt-dlp audio download. | `None` |
| `MEDIA_FFMPEG_TIMEOUT` | HTTP timeout (seconds) for conversion requests. | `600` |
| `MINIO_*` | Shared MinIO credentials/buckets across crawler and ffmpeg-service. | See `.env.example` files |
| `MAX_CONCURRENT_JOBS` | ffmpeg-service semaphore for max parallel conversions. | `2` |

### Error Handling
- ffmpeg-service returns HTTP `500` with descriptive message when conversion fails (e.g., missing object, ffmpeg exit code).
- Crawler logs the failure and can fall back to legacy local conversion if configured.
- For future async/queue mode, `nack` with requeue is recommended for transient errors; DLQ for permanent failures.

### Observability
- ffmpeg-service logs ffmpeg stderr output on failure and timing information on success.
- Health endpoint (`GET /health`) returns `{ "status": "ok" }` to integrate with Compose/Kubernetes probes.
- Metrics/exporters can be added later (e.g., Prometheus) once deployment environment is settled.
