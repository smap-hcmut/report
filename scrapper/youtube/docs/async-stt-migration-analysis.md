# YouTube Scraper - Async STT Migration Analysis

## Executive Summary

This document analyzes the differences between the TikTok scraper's async STT implementation and the YouTube scraper's current synchronous implementation, providing a detailed migration plan.

## Current State Comparison

### TikTok Scraper (✅ Migrated to Async)

**Location:** `scrapper/tiktok/internal/infrastructure/rest_client/speech2text_rest_client.py`

**Key Features:**
- ✅ Async polling pattern (submit → poll → complete)
- ✅ Configurable polling parameters (max_retries, wait_interval)
- ✅ Comprehensive error handling (TIMEOUT, NOT_FOUND, UNAUTHORIZED, FAILED)
- ✅ STTResult dataclass with status field
- ✅ Request ID generation for idempotent submissions
- ✅ Backward compatibility maintained
- ✅ Extensive unit tests (55 tests passing)
- ✅ Environment configuration (.env.example)

**API Endpoints:**
- POST `/api/transcribe` - Submit job
- GET `/api/transcribe/{request_id}` - Poll status

**Configuration:**
```python
STT_POLLING_MAX_RETRIES=60  # Default: 60 attempts
STT_POLLING_WAIT_INTERVAL=3  # Default: 3 seconds
# Total max wait: 60 * 3 = 180 seconds (3 minutes)
```

---

### YouTube Scraper (❌ Still Synchronous)

**Location:** `scrapper/youtube/internal/infrastructure/rest_client/speech2text_rest_client.py`

**Current Implementation:**
- ❌ Synchronous blocking POST request
- ❌ Single endpoint: POST `/transcribe`
- ❌ Returns simple string: transcription text or "err"
- ❌ No polling mechanism
- ❌ No status tracking
- ❌ No retry logic
- ❌ Timeout after 300 seconds (5 minutes)
- ❌ No structured error handling

**Current Interface:**
```python
async def transcribe(self, audio_url: str, language: str = "vi") -> str:
    """Returns: Transcription text or "err" if failed"""
```

**Current Error Handling:**
- HTTP errors → returns `"http err"`
- Empty transcription → returns `"Unexpected err"`
- Exceptions → returns `"Exception err"`

---

## Key Differences

### 1. Return Type

| Aspect | TikTok (Async) | YouTube (Sync) |
|--------|----------------|----------------|
| Return Type | `STTResult` dataclass | `str` (simple string) |
| Success Field | `result.success: bool` | Check if string != "err" |
| Transcription | `result.transcription: Optional[str]` | Direct string value |
| Error Message | `result.error_message: Optional[str]` | Generic "err" strings |
| Status | `result.status: str` (PROCESSING, COMPLETED, etc.) | No status tracking |
| Error Code | `result.error_code: Optional[int]` | No error codes |

### 2. API Communication Pattern

| Aspect | TikTok (Async) | YouTube (Sync) |
|--------|----------------|----------------|
| Pattern | Submit → Poll → Complete | Single blocking POST |
| Endpoints | 2 endpoints (submit + poll) | 1 endpoint (transcribe) |
| Request ID | Generated from content.external_id | Not used |
| Idempotency | ✅ Supported | ❌ Not supported |
| Timeout Handling | Polling timeout (configurable) | HTTP timeout (300s fixed) |

### 3. Error Handling

| Error Type | TikTok (Async) | YouTube (Sync) |
|------------|----------------|----------------|
| Network Timeout | Continue polling | Return "http err" |
| 401 Unauthorized | Return UNAUTHORIZED status | Return "http err" |
| 404 Not Found | Return NOT_FOUND status | Return "http err" |
| 5xx Server Error | Continue polling | Return "http err" |
| Polling Timeout | Return TIMEOUT status | N/A |
| Empty Response | Return FAILED status | Return "Unexpected err" |

### 4. Configuration

| Setting | TikTok (Async) | YouTube (Sync) |
|---------|----------------|----------------|
| Polling Max Retries | ✅ `STT_POLLING_MAX_RETRIES=60` | ❌ Not applicable |
| Polling Interval | ✅ `STT_POLLING_WAIT_INTERVAL=3` | ❌ Not applicable |
| HTTP Timeout | ✅ `timeout=30` (per request) | ✅ `stt_timeout=300` (total) |
| API Key Header | `X-API-Key` | `x-api-key` (lowercase) |

### 5. Usage in Media Downloader

**TikTok:**
```python
# In crawler_service.py - integrated into fetch flow
stt_result = await self.stt_client.transcribe(
    audio_url=presigned_url,
    language="vi"
)

if stt_result.success:
    content.transcription = stt_result.transcription
    content.transcription_status = stt_result.status
else:
    logger.error(f"STT failed: {stt_result.error_message}")
    content.transcription_status = stt_result.status
```

**YouTube:**
```python
# In media_downloader.py - called after FFmpeg conversion
transcription = await self.speech2text_client.transcribe(
    audio_url=presigned_url,
    language="vi"
)

content.transcription = transcription
# No status tracking, just check if transcription contains "err"
```

---

## Migration Requirements

### 1. Interface Changes

**Current Interface (YouTube):**
```python
class ISpeech2TextClient(ABC):
    @abstractmethod
    async def transcribe(self, audio_url: str, language: str = "vi") -> str:
        pass
```

**New Interface (Aligned with TikTok):**
```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class STTResult:
    success: bool
    transcription: Optional[str] = None
    error_message: Optional[str] = None
    status: Optional[str] = None  # PROCESSING, COMPLETED, FAILED, NOT_FOUND, TIMEOUT, UNAUTHORIZED, EXCEPTION
    error_code: Optional[int] = None
    duration: Optional[float] = None
    confidence: Optional[float] = None
    processing_time: Optional[float] = None

class ISpeech2TextClient(ABC):
    @abstractmethod
    async def transcribe(
        self, 
        audio_url: str, 
        language: str = "vi",
        request_id: Optional[str] = None
    ) -> STTResult:
        pass
```

### 2. Implementation Changes

**Files to Modify:**

1. **`application/interfaces.py`**
   - Add `STTResult` dataclass
   - Update `ISpeech2TextClient.transcribe()` signature

2. **`internal/infrastructure/rest_client/speech2text_rest_client.py`**
   - Implement async polling pattern
   - Add `_submit_job()` method
   - Add `_poll_status()` method
   - Add `_get_job_status()` method
   - Add `_map_error_to_stt_result()` helper
   - Add `generate_request_id()` helper
   - Update constructor to accept `max_retries` and `wait_interval`

3. **`config/settings.py`**
   - Add `STT_POLLING_MAX_RETRIES: int = 60`
   - Add `STT_POLLING_WAIT_INTERVAL: int = 3`
   - Add validation for polling parameters

4. **`.env.example`**
   - Add `STT_POLLING_MAX_RETRIES=60`
   - Add `STT_POLLING_WAIT_INTERVAL=3`

5. **`internal/adapters/scrapers_youtube/media_downloader.py`**
   - Update STT call to handle `STTResult`
   - Add status tracking
   - Update error handling

6. **`app/bootstrap.py`**
   - Pass polling parameters to `Speech2TextRestClient` constructor

### 3. Backward Compatibility Strategy

**Option A: Breaking Change (Recommended)**
- Update all call sites to use `STTResult`
- Simpler, cleaner code
- Requires updating media_downloader.py

**Option B: Maintain Compatibility**
- Keep old `transcribe()` method signature
- Add new `transcribe_async()` method
- Gradually migrate call sites
- More complex, but safer

**Recommendation:** Use Option A since YouTube scraper has fewer call sites (only 1 location in media_downloader.py)

---

## Migration Plan

### Phase 1: Update Core Infrastructure (2-3 hours)

**Tasks:**
1. ✅ Copy `STTResult` dataclass from TikTok to YouTube `application/interfaces.py`
2. ✅ Update `ISpeech2TextClient` interface
3. ✅ Implement async polling in `speech2text_rest_client.py`:
   - Copy implementation from TikTok
   - Adjust for YouTube-specific needs
4. ✅ Add configuration to `settings.py`
5. ✅ Update `.env.example`

### Phase 2: Update Call Sites (1 hour)

**Tasks:**
1. ✅ Update `media_downloader.py` to handle `STTResult`
2. ✅ Update `bootstrap.py` to pass polling parameters
3. ✅ Add status tracking to Content entity (if not already present)

### Phase 3: Testing (2-3 hours)

**Tasks:**
1. ✅ Copy unit tests from TikTok:
   - `test_constructor.py`
   - `test_stt_result.py`
   - `test_stt_backward_compatibility.py`
   - `test_get_job_status.py`
   - `test_poll_status.py`
   - `test_error_mapping.py`
   - `test_settings_validation.py`
2. ✅ Adapt tests for YouTube-specific differences
3. ✅ Run full test suite
4. ✅ Manual testing with real STT service

### Phase 4: Documentation (1 hour)

**Tasks:**
1. ✅ Update README.md with new configuration
2. ✅ Document migration changes
3. ✅ Update API documentation

---

## Detailed Code Changes

### 1. Update `application/interfaces.py`

**Add at the top:**
```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class STTResult:
    """Result of a Speech-to-Text transcription request"""
    success: bool
    transcription: Optional[str] = None
    error_message: Optional[str] = None
    status: Optional[str] = None  # PROCESSING, COMPLETED, FAILED, NOT_FOUND, TIMEOUT, UNAUTHORIZED, EXCEPTION
    error_code: Optional[int] = None
    duration: Optional[float] = None
    confidence: Optional[float] = None
    processing_time: Optional[float] = None
```

**Update interface:**
```python
class ISpeech2TextClient(ABC):
    """Interface for Speech-to-Text service"""

    @abstractmethod
    async def transcribe(
        self, 
        audio_url: str, 
        language: str = "vi",
        request_id: Optional[str] = None
    ) -> STTResult:
        """
        Transcribe audio from URL to text using async polling pattern
        
        Args:
            audio_url: Presigned URL of the audio file
            language: Language code (default: "vi")
            request_id: Optional unique identifier for idempotent submission
            
        Returns:
            STTResult with transcription and status info
        """
        pass
```

### 2. Update `config/settings.py`

**Add after STT settings:**
```python
# ========== Speech-to-Text Settings ==========
stt_api_enabled: bool = True
stt_api_url: str = "http://172.16.21.230/transcribe"
stt_api_key: str = "smap-internal-key-changeme"
stt_timeout: int = 30  # HTTP request timeout (per request, not total)
stt_presigned_url_expires_hours: int = 168

# Async polling configuration
stt_polling_max_retries: int = 60  # Maximum polling attempts
stt_polling_wait_interval: int = 3  # Seconds between polls

@model_validator(mode='after')
def validate_stt_polling_config(self) -> 'Settings':
    """Validate STT polling configuration"""
    if self.stt_polling_max_retries <= 0:
        logger.warning(f"Invalid STT_POLLING_MAX_RETRIES={self.stt_polling_max_retries}, using default 60")
        self.stt_polling_max_retries = 60
    
    if self.stt_polling_wait_interval <= 0:
        logger.warning(f"Invalid STT_POLLING_WAIT_INTERVAL={self.stt_polling_wait_interval}, using default 3")
        self.stt_polling_wait_interval = 3
    
    return self
```

### 3. Update `.env.example`

**Add:**
```bash
# Speech-to-Text Async Polling Configuration
STT_POLLING_MAX_RETRIES=60  # Maximum number of polling attempts (default: 60)
STT_POLLING_WAIT_INTERVAL=3  # Seconds to wait between polls (default: 3)
# Total max wait time: 60 * 3 = 180 seconds (3 minutes)
```

### 4. Update `media_downloader.py`

**Replace STT call:**
```python
# OLD:
transcription = await self.speech2text_client.transcribe(
    audio_url=presigned_url,
    language="vi"
)
content.transcription = transcription
logger.info(f"STT completed for {content.external_id}: {len(transcription)} chars")

# NEW:
stt_result = await self.speech2text_client.transcribe(
    audio_url=presigned_url,
    language="vi",
    request_id=content.external_id  # For idempotent submission
)

if stt_result.success:
    content.transcription = stt_result.transcription
    content.transcription_status = stt_result.status
    logger.info(
        f"STT completed for {content.external_id}: "
        f"{len(stt_result.transcription)} chars, "
        f"status={stt_result.status}"
    )
else:
    content.transcription = None
    content.transcription_status = stt_result.status
    logger.error(
        f"STT failed for {content.external_id}: "
        f"status={stt_result.status}, "
        f"error={stt_result.error_message}"
    )
```

### 5. Update `bootstrap.py`

**Replace STT client initialization:**
```python
# OLD:
speech2text_client = Speech2TextRestClient(
    base_url=settings.stt_api_url,
    api_key=settings.stt_api_key,
    timeout=settings.stt_timeout
)

# NEW:
speech2text_client = Speech2TextRestClient(
    base_url=settings.stt_api_url,
    api_key=settings.stt_api_key,
    timeout=settings.stt_timeout,
    max_retries=settings.stt_polling_max_retries,
    wait_interval=settings.stt_polling_wait_interval
)
```

---

## Testing Strategy

### Unit Tests to Port from TikTok

1. **test_constructor.py** - Test client initialization
2. **test_stt_result.py** - Test STTResult dataclass
3. **test_get_job_status.py** - Test status polling
4. **test_poll_status.py** - Test polling loop
5. **test_error_mapping.py** - Test error handling
6. **test_settings_validation.py** - Test configuration validation
7. **test_stt_backward_compatibility.py** - Test interface compatibility

### Integration Tests

1. Test with mock STT service
2. Test timeout scenarios
3. Test error recovery
4. Test idempotent submission

---

## Risk Assessment

### Low Risk
- ✅ TikTok implementation is proven and tested
- ✅ YouTube has only 1 call site to update
- ✅ Backward compatibility can be maintained if needed

### Medium Risk
- ⚠️ Need to ensure Content entity has `transcription_status` field
- ⚠️ Need to update any downstream consumers of transcription data

### High Risk
- ❌ None identified

---

## Rollback Plan

If issues arise:

1. **Immediate Rollback:**
   - Revert `speech2text_rest_client.py` to synchronous version
   - Revert `media_downloader.py` changes
   - Revert interface changes

2. **Partial Rollback:**
   - Keep new interface but add compatibility wrapper
   - Gradually migrate call sites

---

## Success Criteria

- ✅ All unit tests passing
- ✅ No timeout errors for long videos
- ✅ Proper error handling and logging
- ✅ Configuration working correctly
- ✅ Manual testing successful
- ✅ Documentation updated

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Core Infrastructure | 2-3 hours | None |
| Phase 2: Update Call Sites | 1 hour | Phase 1 |
| Phase 3: Testing | 2-3 hours | Phase 2 |
| Phase 4: Documentation | 1 hour | Phase 3 |
| **Total** | **6-8 hours** | |

---

## Next Steps

1. Review this analysis with team
2. Get approval for migration
3. Schedule migration window
4. Execute Phase 1
5. Test thoroughly
6. Deploy to staging
7. Monitor and validate
8. Deploy to production

---

## Appendix: API Endpoint Comparison

### Current YouTube STT API (Synchronous)

**Endpoint:** `POST /transcribe`

**Request:**
```json
{
  "media_url": "https://minio.example.com/presigned-url",
  "language": "vi"
}
```

**Response (Success):**
```json
{
  "transcription": "Transcribed text here..."
}
```

**Response (Error):**
```json
{
  "error": "Error message"
}
```

---

### New Async STT API (To Be Implemented)

**Submit Job:** `POST /api/transcribe`

**Request:**
```json
{
  "request_id": "video_external_id",
  "media_url": "https://minio.example.com/presigned-url",
  "language": "vi"
}
```

**Response (202 Accepted):**
```json
{
  "error_code": 0,
  "message": "Job submitted successfully",
  "data": {
    "request_id": "video_external_id",
    "status": "PROCESSING"
  }
}
```

---

**Poll Status:** `GET /api/transcribe/{request_id}`

**Response (Processing):**
```json
{
  "error_code": 0,
  "message": "Transcription in progress",
  "data": {
    "request_id": "video_external_id",
    "status": "PROCESSING"
  }
}
```

**Response (Completed):**
```json
{
  "error_code": 0,
  "message": "Transcription completed",
  "data": {
    "request_id": "video_external_id",
    "status": "COMPLETED",
    "transcription": "Transcribed text here...",
    "duration": 10.5,
    "confidence": 0.95,
    "processing_time": 2.3
  }
}
```

**Response (Failed):**
```json
{
  "error_code": 0,
  "message": "Transcription failed",
  "data": {
    "request_id": "video_external_id",
    "status": "FAILED",
    "error": "Audio file corrupted"
  }
}
```

---

## Conclusion

The YouTube scraper migration to async STT is straightforward due to:
1. Proven implementation in TikTok scraper
2. Single call site to update
3. Clear migration path
4. Comprehensive test coverage available

The migration will eliminate timeout issues for long videos and provide better error handling and observability.
