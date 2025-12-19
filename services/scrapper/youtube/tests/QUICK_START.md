# Quick Start Guide - Running Tests

## From Windows (PowerShell/CMD)

```cmd
cd f:\SMAP\smap-ai-internal\scrapper\youtube\tests
```

### Run Integration Tests (Recommended)

```cmd
docker-compose -f docker-compose.test.yml run --rm youtube-test-integration
```

### Run Unit Tests (Fast)

```cmd
docker-compose -f docker-compose.test.yml run --rm youtube-test-unit
```

### Run All Tests

```cmd
docker-compose -f docker-compose.test.yml run --rm youtube-test-all
```

## From Git Bash / Linux / Mac

```bash
cd /f/SMAP/smap-ai-internal/scrapper/youtube/tests

# Run integration tests
docker-compose -f docker-compose.test.yml run --rm youtube-test-integration

# Run unit tests
docker-compose -f docker-compose.test.yml run --rm youtube-test-unit

# Run all tests
docker-compose -f docker-compose.test.yml run --rm youtube-test-all
```

## Setup Test Video (First Time Only)

Before running integration tests for the first time, upload a test video:

```bash
cd integration
python setup_test_video.py
cd ..
```

Or upload your own video file:

```bash
python -c "from minio import Minio; client = Minio('localhost:9010', access_key='minioadmin', secret_key='minioadmin', secure=False); client.fput_object('test-videos', 'test/test_video_sample.mp4', 'path/to/your/video.mp4')"
```

## Check Service Status

```bash
docker-compose -f docker-compose.test.yml ps
```

You should see:
- `minio-test` - healthy
- `ffmpeg-service-test` - healthy

## Stop Services

```bash
docker-compose -f docker-compose.test.yml down

# Clean slate (removes volumes)
docker-compose -f docker-compose.test.yml down -v
```

## Expected Output (All Tests Passing)

```
======================== 5 passed in ~175s =========================
```

**Note**: The real video test takes ~2-3 minutes with a 140MB video.

## Troubleshooting

If test video test fails with "NoSuchBucket":
```bash
# Upload test video
cd integration
python setup_test_video.py
```

If services are unhealthy:
```bash
# Check logs
docker logs ffmpeg-service-test
docker logs minio-test

# Restart
docker-compose -f docker-compose.test.yml restart
```

For full documentation, see [README.md](README.md).
