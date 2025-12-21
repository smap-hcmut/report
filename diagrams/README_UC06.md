# UC-06 Sequence Diagrams - Hướng dẫn render

## Files

- `uc6_export_part_1.puml` - Part 1: Export Configuration và Request Submission
- `uc6_export_part_2.puml` - Part 2: Report Generation Pipeline
- `uc6_export_part_3.puml` - Part 3: User Notification và File Download

## Cách render thành PNG

### Option 1: Sử dụng PlantUML Online

1. Truy cập: https://www.plantuml.com/plantuml/uml/
2. Copy nội dung file `.puml` vào editor
3. Click "Submit" để xem preview
4. Click "PNG" để download

### Option 2: Sử dụng PlantUML CLI (Local)

**Cài đặt:**
```bash
# macOS
brew install plantuml

# hoặc download từ https://plantuml.com/download
```

**Render:**
```bash
cd /Users/tantai/Workspaces/smap/report_SMAP/diagrams

# Render single file
plantuml uc6_export_part_1.puml
plantuml uc6_export_part_2.puml
plantuml uc6_export_part_3.puml

# Hoặc render all
plantuml uc6_*.puml

# Output: uc6_export_part_1.png, uc6_export_part_2.png, uc6_export_part_3.png
```

**Move to correct folder:**
```bash
mv uc6_export_part_1.png ../report/images/sequence/
mv uc6_export_part_2.png ../report/images/sequence/
mv uc6_export_part_3.png ../report/images/sequence/
```

### Option 3: Sử dụng VS Code Extension

1. Install extension: "PlantUML" by jebbs
2. Open `.puml` file
3. Press `Alt+D` để preview
4. Click "Export" → PNG

### Option 4: Sử dụng Docker

```bash
docker run --rm -v $(pwd):/data plantuml/plantuml uc6_export_part_1.puml
docker run --rm -v $(pwd):/data plantuml/plantuml uc6_export_part_2.puml
docker run --rm -v $(pwd):/data plantuml/plantuml uc6_export_part_3.puml
```

## Chi tiết Diagrams

### Part 1: Export Configuration và Request (uc6_export_part_1.png)

**Luồng chính:**
1. **User Initiates Export:**
   - User đang ở Dashboard (UC-04)
   - Click nút "Xuất báo cáo"
   - Web UI show Export Configuration Dialog

2. **Configuration Selection:**
   - Format: PDF / Excel / CSV
   - Date range: Full project range / Custom
   - Sections: Overview, Sentiment Analysis, Competitor Comparison, Crisis Posts
   - User select options và click "Xuất báo cáo"

3. **API Request:**
   - Web UI validate input
   - POST /api/v1/projects/:id/export với JWT auth
   - Project Service verify ownership (created_by = user_id)
   - Validate export configuration

4. **Enqueue Job:**
   - INSERT export_request vào PostgreSQL với status = 'pending'
   - PUBLISH export.requested event vào RabbitMQ queue export.jobs
   - Return HTTP 202 Accepted với export_request_id

5. **User Feedback:**
   - Web UI đóng dialog
   - Show toast notification: "Báo cáo đang được tạo, bạn sẽ nhận thông báo khi hoàn tất"
   - User tiếp tục sử dụng hệ thống (non-blocking)

### Part 2: Report Generation Pipeline (uc6_export_part_2.png)

**Luồng chính:**
1. **Consume Event:**
   - Export Worker Service consume export.requested event từ RabbitMQ
   - Parse event payload: export_request_id, project_id, format, config

2. **Query Data:**
   - Query analytics data từ PostgreSQL:
     * Posts với sentiment analysis
     * Aspect breakdown
     * Competitor comparison
     * Crisis posts
     * Aggregated metrics
   - Transform data for report generation

3. **Generate File:**
   - **PDF**: WeasyPrint library → Render HTML template → Embed charts → Format tables → PDF binary
   - **Excel**: openpyxl library → Create workbook → Multiple sheets → Insert data/charts → .xlsx binary
   - **CSV**: csv library → Flatten data → Comma-separated rows → .csv file

4. **Upload to MinIO:**
   - PUT object vào bucket: reports
   - Object key: projects/{project_id}/exports/{export_request_id}.{format}
   - File size: ~2-5 MB
   - Generate pre-signed download URL với 7-day expiry

5. **Update Status:**
   - UPDATE export_request: status = 'completed', download_url, file_size, completed_at
   - PUBLISH export.completed event vào RabbitMQ
   - ACK original message (export.requested consumed)

6. **Exception Handling:**
   - If fails (timeout > 10 min, DB error, OOM):
     * UPDATE status = 'failed', reason
     * PUBLISH export.failed event
     * NACK message → Retry or DLQ

### Part 3: User Notification và Download (uc6_export_part_3.png)

**Luồng chính:**
1. **Real-time Notification:**
   - WebSocket Service consume export.completed event
   - PUBLISH to Redis Pub/Sub channel: user:{user_id}
   - If user online (WebSocket connected):
     * Send WebSocket message to client
     * Web UI show notification banner: "Báo cáo của bạn đã sẵn sàng"
   - If user offline:
     * Store notification in DB for later retrieval

2. **User Downloads File:**
   - User click "Download" button (from notification or Export History page)
   - GET /api/v1/projects/:project_id/exports/:export_id
   - Project Service:
     * Verify ownership (created_by = user_id)
     * Check URL not expired (< 7 days)
     * Return download_url (MinIO pre-signed URL)

3. **Browser Download:**
   - Web UI trigger browser download: window.location.href = download_url
   - GET from MinIO pre-signed URL
   - MinIO validate signature & expiry
   - Return binary file với Content-Disposition: attachment
   - Browser saves file to Downloads folder
   - Filename: {project_name}_report_{date}.{format}

4. **Alternative: Export History:**
   - User navigate to "/exports" page
   - GET /api/v1/projects/:project_id/exports
   - Display table: Format | Status | Date | Size | Actions
   - User click "Download" on specific export → Same download flow

5. **Exception:**
   - If URL expired (> 7 days): Return 410 Gone
   - Show error: "Link đã hết hạn, vui lòng xuất báo cáo mới"

## Key Features

- **Async Processing**: Export không block UI, user tiếp tục làm việc
- **Multiple Formats**: PDF (visual), Excel (data analysis), CSV (raw data)
- **MinIO Storage**: Large files (2-5 MB) stored in object storage, not in database
- **Pre-signed URLs**: Secure 7-day expiry links, no authentication needed for download
- **Real-time Notification**: WebSocket + Redis Pub/Sub cho instant feedback
- **Export History**: User có thể re-download trong 7 days
- **Error Handling**: Timeout (10 min), retry mechanism, failure notifications

## Technical Details

- **Export Worker**: Python service với libraries: WeasyPrint, openpyxl, csv, matplotlib
- **Queue**: RabbitMQ với routing key: export.requested, export.completed, export.failed
- **Storage**: MinIO bucket: reports, object key pattern: projects/{id}/exports/{id}.{format}
- **Database**: export_requests table với columns: id, project_id, user_id, format, config, status, download_url, file_size, created_at, completed_at
- **Notification**: Multi-channel (WebSocket real-time + DB for offline users)
- **Performance**: Target < 30s for summary-only, timeout 10 min for full export

## Customization

Nếu muốn thay đổi style, edit trong file `.puml`:

```plantuml
!theme plain                          # Theme: plain, cerulean, sketchy, etc
skinparam backgroundColor #FFFFFF     # Background color
skinparam defaultFontName Arial       # Font family
skinparam sequenceMessageAlign center # Message alignment
```

## Notes

- Diagrams match với UC-06 specification từ Chapter 4 section 4.4
- Include ownership verification, format selection, async processing
- MinIO pre-signed URLs với 7-day expiry
- Real-time notification qua WebSocket + Redis Pub/Sub
- Export history page cho re-download
- Exception handling: timeout, errors, expired URLs
