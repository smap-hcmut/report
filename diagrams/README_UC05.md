# UC-05 Sequence Diagrams - Hướng dẫn render

## Files
- `uc5_list_part_1.puml` - Part 1: List View và Filtering
- `uc5_list_part_2.puml` - Part 2: Navigation và Actions

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
plantuml uc5_list_part_1.puml
plantuml uc5_list_part_2.puml

# Hoặc render all
plantuml uc5_*.puml

# Output: uc5_list_part_1.png, uc5_list_part_2.png
```

**Move to correct folder:**
```bash
mv uc5_list_part_1.png ../report/images/sequence/
mv uc5_list_part_2.png ../report/images/sequence/
```

### Option 3: Sử dụng VS Code Extension

1. Install extension: "PlantUML" by jebbs
2. Open `.puml` file
3. Press `Alt+D` để preview
4. Click "Export" → PNG

### Option 4: Sử dụng Docker

```bash
docker run --rm -v $(pwd):/data plantuml/plantuml uc5_list_part_1.puml
docker run --rm -v $(pwd):/data plantuml/plantuml uc5_list_part_2.puml
```

## Chi tiết Diagrams

### Part 1: List View và Filtering (uc5_list_part_1.png)

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

### Part 2: Navigation và Actions (uc5_list_part_2.png)

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

## Customization

Nếu muốn thay đổi style, edit trong file `.puml`:

```plantuml
!theme plain                          # Theme: plain, cerulean, sketchy, etc
skinparam backgroundColor #FFFFFF     # Background color
skinparam defaultFontName Arial       # Font family
skinparam sequenceMessageAlign center # Message alignment
```

## Notes

- Diagrams match với UC-05 specification từ Chapter 4 section 4.4
- Include ownership verification, soft delete, pagination
- Status-based navigation links với UC-01, UC-03, UC-04, UC-06
- Business rules: Running projects cannot be deleted
- Performance: Composite index (created_by, deleted_at, status)
