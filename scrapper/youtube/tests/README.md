# YouTube Scraper - Test Suite

This directory contains all test-related files for the YouTube scraper with FFmpeg integration.

## Directory Structure

```
tests/
├── docker-compose.test.yml      # Docker Compose configuration for tests
├── Dockerfile.test              # Dockerfile for test environment
├── Dockerfile.ffmpeg-test       # Minimal FFmpeg test image
├── pytest.ini                   # Pytest configuration
├── requirements-test.txt        # Test dependencies
├── integration/                 # Integration tests
│   ├── setup_test_video.py     # Setup script for test video
│   └── test_ffmpeg_integration.py
├── unit/                        # Unit tests
│   └── test_ffmpeg_client.py
└── README.md                    # This file
```

## Prerequisites

- Docker Desktop running
- Python 3.11+ (for setup scripts)
- At least 5GB free disk space

## Quick Start

### 1. Navigate to Tests Directory

```bash
cd f:\SMAP\smap-ai-internal\scrapper\youtube\tests
```

### 2. Run Integration Tests (Recommended)

```bash
# Run all integration tests (5 tests - includes real video conversion)
docker-compose -f docker-compose.test.yml run --rm youtube-test-integration
```

This will:
- Start MinIO (object storage)
- Start FFmpeg service
- Run 5 integration tests including real video conversion
- Take ~3-5 minutes to complete

### 3. Run Unit Tests (Fast)

```bash
# Run unit tests only (no services needed)
docker-compose -f docker-compose.test.yml run --rm youtube-test-unit
```

### 4. Run All Tests

```bash
# Run both unit and integration tests with coverage
docker-compose -f docker-compose.test.yml run --rm youtube-test-all
```

## Test Services

### MinIO Test Storage
- **Port**: 9010 (API), 9011 (Console)
- **Credentials**: minioadmin / minioadmin
- **Console**: http://localhost:9011

### FFmpeg Service
- **Port**: 8001
- **Health**: http://localhost:8001/health
- **Image Size**: ~136 MiB (Alpine Linux with FFmpeg)

## Detailed Commands

### Check Service Status

```bash
cd f:\SMAP\smap-ai-internal\scrapper\youtube\tests
docker-compose -f docker-compose.test.yml ps
```

Expected output:
```
NAME                      STATUS
ffmpeg-service-test       Up (healthy)
minio-test                Up (healthy)
```

### Start Services Only

```bash
# Start background services without running tests
docker-compose -f docker-compose.test.yml up -d minio-test ffmpeg-service-test

# Check logs
docker-compose -f docker-compose.test.yml logs -f ffmpeg-service-test
```

### Stop All Services

```bash
docker-compose -f docker-compose.test.yml down

# Stop and remove volumes (clean slate)
docker-compose -f docker-compose.test.yml down -v
```

### Setup Test Video

The integration tests need a real video file. To upload one:

```bash
# From the tests directory
cd integration
python setup_test_video.py
cd ..

# Or use an existing video file
python -c "from minio import Minio; client = Minio('localhost:9010', access_key='minioadmin', secret_key='minioadmin', secure=False); client.fput_object('test-videos', 'test/test_video_sample.mp4', 'path/to/your/video.mp4')"
```

## Test Suites

### Integration Tests (`tests/integration/`)

Tests the full YouTube → FFmpeg service integration:

1. **test_health_check** - FFmpeg service health endpoint
2. **test_convert_missing_file** - Error handling for non-existent files
3. **test_convert_real_video** - Real MP4 → MP3 conversion (140MB video)
4. **test_timeout_handling** - Timeout with retries
5. **test_invalid_url** - Invalid service URL handling

**Duration**: ~3-5 minutes (includes 140MB video conversion)

### Unit Tests (`tests/unit/`)

Tests RemoteFFmpegClient in isolation with mocked HTTP:

- Circuit breaker states (CLOSED, OPEN, HALF_OPEN)
- Retry logic with exponential backoff
- Timeout handling
- Error response parsing
- Connection pooling

**Duration**: ~5-10 seconds

## Viewing Test Coverage

After running tests with coverage:

```bash
# Coverage reports are saved to youtube/htmlcov/
cd ..
# Open htmlcov/index.html in browser
start htmlcov/index.html  # Windows
```

## Troubleshooting

### Services Not Healthy

```bash
# Check service logs
docker logs ffmpeg-service-test
docker logs minio-test

# Restart services
docker-compose -f docker-compose.test.yml restart
```

### Tests Timing Out

The real video test (`test_convert_real_video`) needs 180 seconds timeout for large videos. This is already configured in `docker-compose.test.yml`.

### Port Conflicts

If ports 8001, 9010, or 9011 are in use:

```bash
# Check what's using the ports
netstat -ano | findstr "8001"
netstat -ano | findstr "9010"

# Stop other services or modify ports in docker-compose.test.yml
```

### Clean Rebuild

```bash
# Complete clean rebuild
docker-compose -f docker-compose.test.yml down -v
docker-compose -f docker-compose.test.yml build --no-cache
docker-compose -f docker-compose.test.yml up -d minio-test ffmpeg-service-test
```

### Test Video Issues

```bash
# Verify test video exists in MinIO
python -c "from minio import Minio; client = Minio('localhost:9010', access_key='minioadmin', secret_key='minioadmin', secure=False); print('Video exists:', client.stat_object('test-videos', 'test/test_video_sample.mp4').size, 'bytes')"

# Re-upload if missing
cd integration
python setup_test_video.py
```

## Environment Variables

Key environment variables in `docker-compose.test.yml`:

### FFmpeg Service
- `MEDIA_FFMPEG_SERVICE_URL`: FFmpeg service URL
- `MEDIA_FFMPEG_TIMEOUT`: Request timeout (180s for large videos)
- `MEDIA_FFMPEG_MAX_RETRIES`: Number of retry attempts (3)

### MinIO
- `MINIO_ENDPOINT`: MinIO server address
- `MINIO_BUCKET`: Test bucket name
- `TEST_WITH_REAL_FILES`: Enable real file conversion tests (1)

## Performance Benchmarks

- **Small video (5s, 2.8MB)**: ~2-3 seconds
- **Medium video (1min, 50MB)**: ~20-30 seconds
- **Large video (5min, 140MB)**: ~60-70 seconds

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run Integration Tests
  run: |
    cd scrapper/youtube/tests
    docker-compose -f docker-compose.test.yml run --rm youtube-test-integration
```

### GitLab CI Example

```yaml
test:
  script:
    - cd scrapper/youtube/tests
    - docker-compose -f docker-compose.test.yml run --rm youtube-test-integration
  services:
    - docker:dind
```

## Expected Test Output

```
============================= test session starts ==============================
platform linux -- Python 3.11.14, pytest-8.2.0
...
tests/integration/test_ffmpeg_integration.py::TestFFmpegServiceIntegration::test_health_check PASSED [ 20%]
tests/integration/test_ffmpeg_integration.py::TestFFmpegServiceIntegration::test_convert_missing_file PASSED [ 40%]
tests/integration/test_ffmpeg_integration.py::TestFFmpegServiceIntegration::test_convert_real_video PASSED [ 60%]
tests/integration/test_ffmpeg_integration.py::TestFFmpegServiceResilience::test_timeout_handling PASSED [ 80%]
tests/integration/test_ffmpeg_integration.py::TestFFmpegServiceResilience::test_invalid_url PASSED [100%]

======================== 5 passed in 175s (0:02:55) =========================
```

## Additional Resources

- [FFmpeg Service Documentation](../../../ffmpeg/README.md)
- [YouTube Scraper Documentation](../../README.md)
- [Pytest Documentation](https://docs.pytest.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Support

If tests are failing:
1. Check service logs
2. Verify Docker Desktop is running
3. Ensure ports are available
4. Try clean rebuild
5. Check test video exists in MinIO
