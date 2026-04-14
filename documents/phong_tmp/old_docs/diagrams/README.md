# SMAP Diagrams

Folder này chứa tất cả các PlantUML diagrams của hệ thống SMAP, được tổ chức theo category để dễ quản lý và maintain.

## Structure

``` Markdown
diagrams/
  sequence/           # Sequence diagrams (use case flows)
    uc05_list/       # UC-05: List Projects
    uc06_export/     # UC-06: Export Reports
    README.md        # Hướng dẫn render sequence diagrams
  
  activity/           # Activity diagrams
    activity_*.puml  # Business process flows
  
  component/          # Component diagrams
    component_*.puml # Service architecture diagrams
  
  data-flow/          # Data flow diagrams
    dataflow_*.puml  # Data processing pipelines
  
  authentication/     # Authentication flows
    auth_*.puml      # Auth and authorization flows
  
  realtime/           # Real-time/WebSocket flows
    realtime_*.puml  # WebSocket and webhook flows
```

## Naming Convention

Tất cả files sử dụng **snake_case**, lowercase với prefix theo category:

- **Sequence**: `uc{number}_{description}_part_{number}.puml`
- **Activity**: `activity_{description}.puml`
- **Component**: `component_{service_name}.puml`
- **Data flow**: `dataflow_{description}.puml`
- **Auth**: `auth_{description}.puml`
- **Real-time**: `realtime_{description}.puml`

## Categories

### Sequence Diagrams (`sequence/`)

Sequence diagrams mô tả các tương tác động giữa các thành phần hệ thống theo trình tự thời gian cho các Use Cases.

**Use Cases:**

- UC-05: List Projects (2 parts)
- UC-06: Export Reports (3 parts)

Xem [sequence/README.md](sequence/README.md) để biết chi tiết về cách render.

### Activity Diagrams (`activity/`)

Activity diagrams mô tả các quy trình nghiệp vụ và luồng xử lý của hệ thống.

**Files:**

- `activity_lifecycle.puml` - Vòng đời Project
- `activity_configuration.puml` - Cấu hình Project
- `activity_dryrun.puml` - Dry-run keywords
- `activity_execution.puml` - Khởi chạy Project
- `activity_export.puml` - Xuất báo cáo
- `activity_crisis_monitor.puml` - Giám sát khủng hoảng
- `activity_trend_detection.puml` - Phát hiện trend

### Component Diagrams (`component/`)

Component diagrams mô tả kiến trúc và cấu trúc của từng service.

**Files:**

- `component_analytic.puml` - Analytics Service
- `component_collector.puml` - Collector Service
- `component_identity.puml` - Identity Service
- `component_project.puml` - Project Service
- `component_speech2text.puml` - Speech2Text Service
- `component_websocket.puml` - WebSocket Service
- `component_webui.puml` - Web UI

### Data Flow Diagrams (`data-flow/`)

Data flow diagrams mô tả luồng xử lý dữ liệu qua các thành phần hệ thống.

**Files:**

- `dataflow_analytics_ingestion.puml` - Analytics data ingestion
- `dataflow_analytics_pipeline.puml` - Analytics processing pipeline
- `dataflow_dispatcher.puml` - Dispatcher dataflow
- `dataflow_execute_project.puml` - Project execution flow
- `dataflow_project_create.puml` - Project creation flow
- `dataflow_project_dispatcher.puml` - Project dispatcher flow
- `dataflow_results_processing.puml` - Crawler results processing
- `dataflow_transcript.puml` - Speech-to-text transcription
- `dataflow_progress.puml` - Progress tracking

### Authentication Diagrams (`authentication/`)

Authentication và authorization flows.

**Files:**

- `auth_middleware.puml` - Auth middleware flow
- `auth_authentication.puml` - Authentication process
- `auth_user_login.puml` - User login flow
- `auth_user_registration.puml` - User registration flow

### Real-time Diagrams (`realtime/`)

Real-time communication flows qua WebSocket và webhooks.

**Files:**

- `realtime_realtime.puml` - Real-time message delivery
- `realtime_websocket_connection.puml` - WebSocket connection flow
- `realtime_webhook_callback.puml` - Webhook callback flow

## Cách render thành PNG

### Option 1: PlantUML Online

1. Truy cập: <https://www.plantuml.com/plantuml/uml/>
2. Copy nội dung file `.puml` vào editor
3. Click "Submit" để xem preview
4. Click "PNG" để download

### Option 2: PlantUML CLI

**Cài đặt:**

```bash
# macOS
brew install plantuml

# hoặc download từ https://plantuml.com/download
```

**Render:**

```bash
cd diagrams/<category>
plantuml *.puml
```

### Option 3: VS Code Extension

1. Install extension: "PlantUML" by jebbs
2. Open `.puml` file
3. Press `Alt+D` để preview
4. Click "Export" → PNG

### Option 4: Docker

```bash
docker run --rm -v $(pwd):/data plantuml/plantuml <file>.puml
```

## Output Location

Sau khi render, các file PNG nên được move vào `report/images/` với structure tương ứng:

``` Markdown
report/images/
  sequence/          # Sequence diagram outputs
  activity/          # Activity diagram outputs
  component/         # Component diagram outputs
  data-flow/         # Data flow diagram outputs
  ...
```

## Maintenance

- Khi thêm diagram mới, đảm bảo đặt tên theo convention và đặt vào đúng category folder
- Update README này nếu thêm category mới
- Giữ consistency trong naming và structure
