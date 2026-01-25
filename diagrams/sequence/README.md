# Sequence Diagrams - Hướng dẫn render

## Overview

Folder này chứa các sequence diagrams cho các Use Cases của hệ thống SMAP. Mỗi Use Case có thể được chia thành nhiều parts để dễ quản lý và render.

## Structure

```
sequence/
  uc05_list/          # UC-05: List Projects
    uc05_list_part_1.puml
    uc05_list_part_2.puml
  uc06_export/        # UC-06: Export Reports
    uc06_export_part_1.puml
    uc06_export_part_2.puml
    uc06_export_part_3.puml
```

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
cd diagrams/sequence/uc05_list
plantuml uc05_list_part_1.puml
plantuml uc05_list_part_2.puml

cd ../uc06_export
plantuml uc06_export_part_*.puml
```

**Move to correct folder:**
```bash
# Output files sẽ được tạo cùng thư mục với .puml files
# Move vào report/images/sequence/ sau khi render
mv *.png ../../../../report/images/sequence/
```

### Option 3: Sử dụng VS Code Extension

1. Install extension: "PlantUML" by jebbs
2. Open `.puml` file
3. Press `Alt+D` để preview
4. Click "Export" → PNG

### Option 4: Sử dụng Docker

```bash
docker run --rm -v $(pwd):/data plantuml/plantuml uc05_list_part_1.puml
```

## UC-05: List Projects

### Files
- `uc05_list/uc05_list_part_1.puml` - Part 1: List View và Filtering
- `uc05_list/uc05_list_part_2.puml` - Part 2: Navigation và Actions

### Part 1: List View và Filtering

**Luồng chính:**
1. **Initial Load:**
   - User navigate to /projects
   - GET /api/v1/projects với JWT auth
   - Query PostgreSQL: WHERE created_by = user_id AND deleted_at IS NULL
   - Return list với metadata (name, status, created_at, keywords preview)
   - Render với filter controls

2. **Apply Filters:**
   - User select status + search + sort
   - Query với WHERE clauses: status, ILIKE search, ORDER BY
   - Update display với "Showing X of Y projects"

3. **Pagination:**
   - Infinite scroll khi > 50 projects
   - Load more với OFFSET + LIMIT
   - Append to existing list

### Part 2: Navigation và Actions

**Luồng chính:**
1. **Status-based Navigation:**
   - Draft → Edit (UC-01) hoặc Execute (UC-03)
   - Running → Monitor Progress (UC-03)
   - Completed → View Results (UC-04) hoặc Export (UC-06)
   - Failed → Retry (UC-03)

2. **Soft Delete:**
   - Click Delete → Confirmation dialog
   - DELETE /api/v1/projects/:id (soft delete)
   - UPDATE deleted_at = NOW()
   - Remove from list với animation
   - Show toast notification

3. **Exception:**
   - Running projects: Delete button DISABLED
   - Business rule: Cannot delete running projects

## UC-06: Export Reports

### Files
- `uc06_export/uc06_export_part_1.puml` - Part 1: Export Configuration và Request Submission
- `uc06_export/uc06_export_part_2.puml` - Part 2: Report Generation Pipeline
- `uc06_export/uc06_export_part_3.puml` - Part 3: User Notification và File Download

### Part 1: Export Configuration và Request

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

### Part 2: Report Generation Pipeline

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

### Part 3: User Notification và Download

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

## Customization

Nếu muốn thay đổi style, edit trong file `.puml`:

```plantuml
!theme plain                          # Theme: plain, cerulean, sketchy, etc
skinparam backgroundColor #FFFFFF     # Background color
skinparam defaultFontName Arial       # Font family
skinparam sequenceMessageAlign center # Message alignment
```

## Notes

- Diagrams match với UC specifications từ Chapter 4 section 4.4
- Include ownership verification, soft delete, pagination
- Status-based navigation links với các UC khác
- Business rules được enforce trong diagrams
- Performance considerations: Composite indexes, pagination
