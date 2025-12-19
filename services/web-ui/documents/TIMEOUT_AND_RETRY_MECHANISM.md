# Timeout và Retry Mechanism - Dry Run Preview

## Tổng Quan

Document này mô tả chi tiết cơ chế timeout và retry cho dry run preview trong Project Setup Wizard (Bước 4/5).

**File liên quan**: `components/dashboard/ProjectSetupWizard.tsx`

---

## 🔍 Cơ Chế Timeout

### 1. **Timeout Duration**
- **Thời gian**: 60 giây (60000ms)
- **Trigger**: Sau khi call API `createDryRun()` thành công
- **Mục đích**: Đảm bảo user nhận được feedback nếu không có data sau 60 giây

### 2. **Timeout Logic**

```typescript
// Set timeout for 60 seconds - show error if no data received
timeoutRef.current = setTimeout(() => {
  // Only show timeout error if still loading (no data received)
  if (isLoadingPreview && !dryRunData) {
    setIsLoadingPreview(false)
    setPreviewError('Timeout: Không nhận được dữ liệu preview sau 60 giây. Vui lòng thử lại.')
    // Disconnect WebSocket on timeout
    disconnectFromJob()
  }
  timeoutRef.current = null
}, 60000)
```

### 3. **Timeout được Clear khi nào?**

Timeout sẽ được **tự động clear** trong các trường hợp sau:

#### ✅ **Khi nhận được data** (onBatch callback)
```typescript
onBatch: (batch) => {
  // Clear timeout since we received data
  if (timeoutRef.current) {
    clearTimeout(timeoutRef.current)
    timeoutRef.current = null
  }
  // ... process data ...
}
```

#### ✅ **Khi job completed** (onCompleted callback)
```typescript
onCompleted: () => {
  // Clear timeout since job completed
  if (timeoutRef.current) {
    clearTimeout(timeoutRef.current)
    timeoutRef.current = null
  }
  // ... handle completion ...
}
```

#### ✅ **Khi job failed** (onFailed callback)
```typescript
onFailed: (errors) => {
  // Clear timeout since job failed
  if (timeoutRef.current) {
    clearTimeout(timeoutRef.current)
    timeoutRef.current = null
  }
  // ... handle failure ...
}
```

#### ✅ **Khi WebSocket error** (onError callback)
```typescript
onError: (error) => {
  // Clear timeout on WebSocket error
  if (timeoutRef.current) {
    clearTimeout(timeoutRef.current)
    timeoutRef.current = null
  }
  // ... handle error ...
}
```

#### ✅ **Khi user click Retry** (triggerDryRun được gọi lại)
```typescript
const triggerDryRun = async () => {
  // Clear any existing timeout
  if (timeoutRef.current) {
    clearTimeout(timeoutRef.current)
    timeoutRef.current = null
  }
  // ... start new dry run ...
}
```

#### ✅ **Khi component unmount**
```typescript
useEffect(() => {
  return () => {
    // Clear timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current)
      timeoutRef.current = null
    }
    // Disconnect WebSocket
    disconnectFromJob()
  }
}, [disconnectFromJob])
```

---

## 🔄 Cơ Chế Retry

### 1. **Nút Retry xuất hiện khi nào?**

Nút Retry xuất hiện trong `PreviewErrorState` component khi:
- Có `error` state được set
- `showRealPreview === true` (user đã click "Preview actual project data")
- Component nhận prop `onRetry` callback

**File**: `components/dashboard/preview/PreviewErrorState.tsx`

```typescript
{onRetry && (
  <button
    onClick={onRetry}
    className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
  >
    <RefreshCw className="w-5 h-5" />
    {t('preview.retry')}
  </button>
)}
```

### 2. **Nút Retry sẽ làm gì?**

**⚠️ QUAN TRỌNG**: Nút Retry sẽ **CALL LẠI API DRY RUN**, không chỉ reconnect WebSocket!

#### Flow khi click Retry:

```typescript
const handleRetryPreview = () => {
  triggerDryRun()  // ← Call lại API, không chỉ reconnect WS
}
```

#### Chi tiết `triggerDryRun()`:

1. **Clear timeout cũ** (nếu có)
   ```typescript
   if (timeoutRef.current) {
     clearTimeout(timeoutRef.current)
     timeoutRef.current = null
   }
   ```

2. **Disconnect WebSocket cũ** (nếu có)
   ```typescript
   disconnectFromJob()
   ```

3. **Reset state**
   ```typescript
   setIsLoadingPreview(true)
   setPreviewError(null)
   setDryRunData(null)
   setDryRunJobId(null)
   ```

4. **Call API `createDryRun()` lại**
   ```typescript
   const response = await projectService.createDryRun(keywords)
   ```

5. **Set job_id mới** → Trigger WebSocket connection mới
   ```typescript
   setDryRunJobId(response.job_id)
   ```

6. **Set timeout mới** (60 giây)
   ```typescript
   timeoutRef.current = setTimeout(() => {
     // Timeout logic...
   }, 60000)
   ```

### 3. **Tại sao Retry call lại API thay vì chỉ reconnect WS?**

**Lý do**:
- Job có thể đã fail hoặc timeout trên server
- Tạo job mới đảm bảo fresh start
- Server có thể đã cleanup job cũ
- Đảm bảo data consistency

**Nếu chỉ reconnect WS**:
- ❌ Có thể connect đến job đã fail/timeout
- ❌ Không có data mới
- ❌ User vẫn thấy error

**Call lại API**:
- ✅ Tạo job mới với fresh state
- ✅ Server process lại từ đầu
- ✅ User có cơ hội nhận data mới

---

## 📊 Flow Diagram

### Normal Flow (Success)

```
User clicks "Preview actual project data"
    ↓
Call API createDryRun()
    ↓
API returns job_id
    ↓
Set dryRunJobId → useEffect triggers
    ↓
Connect WebSocket to job_id
    ↓
Set timeout (60s)
    ↓
[WebSocket receives data]
    ↓
onBatch callback → Clear timeout ✅
    ↓
Update UI with data
    ↓
SUCCESS ✅
```

### Timeout Flow

```
User clicks "Preview actual project data"
    ↓
Call API createDryRun()
    ↓
API returns job_id
    ↓
Set dryRunJobId → useEffect triggers
    ↓
Connect WebSocket to job_id
    ↓
Set timeout (60s)
    ↓
[60 seconds pass - NO DATA]
    ↓
Timeout callback fires
    ↓
Show error: "Timeout: Không nhận được dữ liệu preview sau 60 giây"
    ↓
Disconnect WebSocket
    ↓
Show PreviewErrorState with Retry button
    ↓
[User clicks Retry]
    ↓
Call triggerDryRun() again (NEW API CALL)
    ↓
Repeat from beginning...
```

### Retry Flow

```
[Error state shown]
    ↓
User clicks "Retry" button
    ↓
handleRetryPreview() called
    ↓
triggerDryRun() called
    ↓
1. Clear old timeout
2. Disconnect old WebSocket
3. Reset state (error, data, jobId)
4. Call API createDryRun() AGAIN
5. Get NEW job_id
6. Connect NEW WebSocket
7. Set NEW timeout (60s)
    ↓
[Wait for data or timeout...]
```

---

## 🎯 Các Trường Hợp Error

### 1. **API Error** (createDryRun fails)
- **Khi nào**: API call thất bại (network, server error, validation)
- **Error message**: Từ API response hoặc default message
- **Timeout**: Được clear ngay lập tức
- **Retry**: Call lại API

### 2. **WebSocket Connection Error**
- **Khi nào**: Không thể connect đến WebSocket server
- **Error message**: `"WebSocket error: {error.message}"`
- **Timeout**: Được clear ngay lập tức
- **Retry**: Call lại API (tạo job mới)

### 3. **Job Failed** (onFailed callback)
- **Khi nào**: Server process job nhưng fail
- **Error message**: `errors?.join(', ') || 'Job processing failed'`
- **Timeout**: Được clear ngay lập tức
- **Retry**: Call lại API (tạo job mới)

### 4. **Timeout** (60 giây không có data)
- **Khi nào**: 60 giây trôi qua mà không nhận được data
- **Error message**: `"Timeout: Không nhận được dữ liệu preview sau 60 giây. Vui lòng thử lại."`
- **Timeout**: Tự động clear sau khi fire
- **Retry**: Call lại API (tạo job mới)

### 5. **Job Completed nhưng không có data**
- **Khi nào**: Job completed nhưng `contentList.length === 0`
- **Error message**: `"Không tìm thấy dữ liệu cho các từ khóa đã chọn"`
- **Timeout**: Đã được clear khi onCompleted
- **Retry**: Call lại API (tạo job mới)

---

## 🔧 Implementation Details

### Timeout Ref Management

```typescript
// Store timeout in ref for cleanup
const timeoutRef = useRef<NodeJS.Timeout | null>(null)

// Set timeout
timeoutRef.current = setTimeout(() => {
  // ... timeout logic ...
  timeoutRef.current = null
}, 60000)

// Clear timeout
if (timeoutRef.current) {
  clearTimeout(timeoutRef.current)
  timeoutRef.current = null
}
```

### State Management

```typescript
// States
const [dryRunData, setDryRunData] = useState<DryRunOuterPayload | null>(null)
const [isLoadingPreview, setIsLoadingPreview] = useState(false)
const [previewError, setPreviewError] = useState<string | null>(null)
const [dryRunJobId, setDryRunJobId] = useState<string | null>(null)
```

### WebSocket Connection

```typescript
// Auto-connect when job_id is set
useEffect(() => {
  if (dryRunJobId && !isJobConnected) {
    console.log('Connecting to job WebSocket:', dryRunJobId)
    connectToJob(dryRunJobId)
  }
}, [dryRunJobId, isJobConnected, connectToJob])
```

---

## ✅ Verification Checklist

- [x] Timeout được set sau khi call API thành công
- [x] Timeout được clear khi nhận data (onBatch)
- [x] Timeout được clear khi job completed (onCompleted)
- [x] Timeout được clear khi job failed (onFailed)
- [x] Timeout được clear khi WebSocket error (onError)
- [x] Timeout được clear khi retry (triggerDryRun)
- [x] Timeout được clear khi component unmount
- [x] Error message hiển thị đúng khi timeout
- [x] Nút Retry xuất hiện khi có error
- [x] Nút Retry call lại API (không chỉ reconnect WS)
- [x] WebSocket được disconnect khi timeout
- [x] WebSocket được disconnect khi retry

---

## 📝 Summary

### Timeout
- ✅ **Duration**: 60 giây
- ✅ **Auto-clear**: Khi có data, completed, failed, error, retry, unmount
- ✅ **Error message**: "Timeout: Không nhận được dữ liệu preview sau 60 giây. Vui lòng thử lại."

### Retry
- ✅ **Action**: Call lại API `createDryRun()` (không chỉ reconnect WS)
- ✅ **Cleanup**: Clear timeout, disconnect WS, reset state
- ✅ **Result**: Tạo job mới với fresh state

### Error Handling
- ✅ **API Error**: Clear timeout, show error, allow retry
- ✅ **WS Error**: Clear timeout, show error, allow retry
- ✅ **Job Failed**: Clear timeout, show error, allow retry
- ✅ **Timeout**: Show error, disconnect WS, allow retry
- ✅ **No Data**: Show error, allow retry

---

**Last Updated**: December 14, 2025  
**Status**: ✅ Verified and Implemented

