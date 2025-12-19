# FFmpeg Conversion Service

Microservice that converts crawler-produced MP4 assets into MP3 audio by streaming objects between MinIO and FFmpeg. It is designed to be called by the YouTube crawler via HTTP (`POST /convert`) and can later be reused by other scrapers or queued workers.

## Highlights
- Streams media directly between MinIO and FFmpeg without touching disk.
- FastAPI HTTP interface with health checks and structured JSON errors.
- Concurrency guard (`MAX_CONCURRENT_JOBS`) to keep FFmpeg usage predictable inside a container.
- Rich domain + exception model for classifying permanent vs transient failures.
- Docker image ships with Python 3.11 and FFmpeg, making the service self-contained.

## Architecture At A Glance
1. **Crawler uploads** MP4 to MinIO (`videos/{video_id}.mp4`) and gathers metadata.
2. **Crawler calls** `POST /convert` on this service with the source and target object information.
3. **Service generates** a presigned URL, streams the MP4 into FFmpeg, and pipes MP3 output straight into MinIO (`audios/{video_id}.mp3` by default).
4. **Service responds** with `bucket` + `audio_object` so the crawler can continue downstream processing.

More context can be found in `scrapper/ffmpeg/docs/media-conversion-architecture.md` and `scrapper/ffmpeg/docs/plan.md`.

## Repository Layout
| Path | Purpose |
|------|---------|
| `cmd/api` | FastAPI app (`main.py`, `routes.py`) exposing `/health` and `/convert`. |
| `core` | Settings, DI container, concurrency guard, logging helpers. |
| `services/converter.py` | MediaConverter that orchestrates MinIO + FFmpeg. |
| `domain` | Dataclasses & enums describing jobs, results, and audio quality. |
| `models` | Pydantic payloads plus typed exception hierarchy. |
| `docs` | High-level design/requirements notes for the service. |
| `tests` | Pytest unit coverage for the converter and integration tests for the API. |
| `Dockerfile` | Multi-stage build that bundles Python deps and FFmpeg. |

## Prerequisites
- Python 3.11+
- FFmpeg binary (local dev uses the `ffmpeg` CLI on your PATH; Docker image already includes it).
- Access to a MinIO/S3-compatible endpoint with buckets for source MP4s and target MP3s.

## Local Setup
1. **Configure environment**
   ```bash
   cd scrapper/ffmpeg
   cp .env.example .env
   # edit .env with your MinIO host, keys, and desired target prefix/buckets
   ```
2. **Install dependencies**
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements-dev.txt
   ```
3. **Run the API**
   ```bash
   uvicorn cmd.api.main:app --host 0.0.0.0 --port 8000 --reload
   ```
4. **Health check**
   ```bash
   curl http://localhost:8000/health
   ```

> Tip: When working inside the monorepo, you can also start the service with `docker compose` from `scrapper/docker-compose.yml` (`docker compose up ffmpeg-service`).

## Configuration Reference
The service reads configuration from environment variables (or `.env`). Key options:

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ENV` | Deployment environment tag used in logs. | `development` |
| `LOG_LEVEL` | Python logging level. | `INFO` |
| `FFMPEG_PATH` | Path to the ffmpeg binary. | `ffmpeg` |
| `FFMPEG_AUDIO_BITRATE` | Target MP3 bitrate when no quality override is supplied. | `192k` |
| `FFMPEG_TIMEOUT_SECONDS` | Max seconds to wait for a conversion before aborting. | `600` |
| `MAX_CONCURRENT_JOBS` | Async semaphore size that bounds parallel FFmpeg executions. | `2` |
| `MINIO_ENDPOINT` | `<host>:<port>` for MinIO/S3. | `localhost:9000` |
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | Credentials for MinIO (optional when using presigned URLs). | `None` |
| `MINIO_BUCKET` (`minio_bucket_source`) | Default bucket for source MP4 objects. | `youtube-media` |
| `MINIO_BUCKET_MODEL` (`minio_bucket_target`) | Bucket for MP3 output. | `youtube-media` |
| `MINIO_TARGET_PREFIX` | Folder/prefix prepended to generated MP3 names. | `audios` |
| `MINIO_USE_SSL` | Set to `True` when connecting over HTTPS. | `False` |

See `.env.example` for the full list including optional model bucket fields.

## HTTP API

### `GET /health`
Returns service + MinIO connectivity status. Example response:
```json
{
  "status": "ok",
  "checks": {
    "minio": "connected"
  }
}
```

### `POST /convert`
Triggers MP4 → MP3 conversion.

**Request body**
```json
{
  "video_id": "ABC123",
  "source_object": "videos/ABC123.mp4",
  "target_object": "audios/ABC123.mp3",
  "bucket_source": "youtube-media",
  "bucket_target": "youtube-media"
}
```
- `target_object`, `bucket_source`, and `bucket_target` are optional. When omitted, the service builds `audios/{video_id}.mp3` inside the buckets configured in `.env`.

**Success response**
```json
{
  "status": "success",
  "video_id": "ABC123",
  "audio_object": "audios/ABC123.mp3",
  "bucket": "youtube-media"
}
```

**Error semantics**
- `400 Bad Request` — invalid/corrupted media (raised as `InvalidMediaError`).
- `404 Not Found` — source object missing in MinIO (`StorageNotFoundError`).
- `500 Internal Server Error` — permanent FFmpeg failure (`FFmpegExecutionError`).
- `503 Service Unavailable` — transient issues (timeouts, temporary storage hiccups); safe to retry.

## Concurrency & Resiliency
- `core/concurrency.py` exposes a FastAPI dependency that wraps each `/convert` request with an async semaphore sized by `MAX_CONCURRENT_JOBS`.
- `services/converter.MediaConverter` streams FFmpeg stdout directly into `Minio.put_object`, avoiding large temp files.
- Exceptions inherit from `models.exceptions.ConversionError` to help the API layer translate them into HTTP status codes and actionable log messages.

## Testing
```bash
cd scrapper/ffmpeg
pip install -r requirements-dev.txt
pytest
```
- `tests/unit/test_converter.py` covers MinIO + FFmpeg orchestration edge cases.
- `tests/integration/test_api.py` validates FastAPI error mapping and dependency wiring.

## Additional Documentation
- `scrapper/ffmpeg/docs/media-conversion-architecture.md` – end-to-end flow between crawler, ffmpeg service, and MinIO.
- `scrapper/ffmpeg/docs/plan.md` – integration decisions, backlog, and future async worker ideas.
- `scrapper/ffmpeg/docs/yeu-cau-ffmpeg-service.md` – Vietnamese requirements note used during initial planning.

Keeping README up to date with any new endpoints, env vars, or deployment patterns will make it easier for crawler teams to reuse this module and operate it in production.
