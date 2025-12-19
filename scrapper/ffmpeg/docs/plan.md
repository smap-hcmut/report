## YouTube Media Conversion Plan

### Current Consensus
- Crawler downloads YouTube MP4, uploads it to MinIO under `videos/{video_id}.mp4`, and can persist metadata (etag, size).
- Conversion step must run in a separate ffmpeg-powered service that pulls from MinIO and pushes MP3 back to MinIO (`audios/{video_id}.mp3`).
- Crawler needs the final MP3 location and metadata to continue downstream processing. 

### Integration Strategy (Finalized)
- **Primary flow: HTTP synchronous API**
  - Crawler sends `POST /convert` with `video_id`, MinIO source object key, and optional target key overrides.
  - ffmpeg service streams MP4 from MinIO (via presigned URL or credentials), runs ffmpeg, uploads MP3 to MinIO, and responds with JSON (`status`, `audio_object`, `bucket`, diagnostic message if any).
  - Crawler blocks on the response, persists returned metadata, and continues the pipeline.
- **Future extension (optional): RabbitMQ async workers**
  - If workloads require decoupling, introduce a job queue where ffmpeg workers consume messages, apply `ack/nack` with retry + DLQ policies, and emit completion events. This is out of scope for the initial HTTP implementation but the API contract should remain compatible.

### ffmpeg Service Requirements
- Must stream downloads/uploads directly to/from MinIO using presigned URLs or MinIO credentials (avoid intermediate files).
- Limit concurrent ffmpeg executions via semaphore, worker pool size, or container replicas.
- Emit structured logs, capture stderr on failures, and return actionable error codes/messages.

### Outstanding Decisions
- Formalize error taxonomy for ffmpeg failures (transient vs permanent) to guide future retry strategies.
- Decide whether to delete original MP4 objects after successful conversion (current assumption: retain for audit / potential reprocessing).

### Next Steps
- ✅ Scaffold `ffmpeg-service` (API handlers + ffmpeg invocation + MinIO streaming).
- Update crawler to call the HTTP conversion API and persist returned MP3 metadata.
- Extend infrastructure/docs (docker-compose, env vars, README) to include the new service and operational guidelines.
