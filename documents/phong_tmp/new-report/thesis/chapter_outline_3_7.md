# Kế hoạch viết Chương 3 đến Chương 7

## 1. Mục tiêu của file này

File này dùng để điều phối việc viết tuần tự các chương còn lại, đảm bảo dữ liệu ở Chương 3 khớp với Chương 4 và Chương 5 theo đúng nguyên tắc liên kết chương.

## 2. Chapter 3: System Analysis

### 3.1 Requirements Gathering

- mô tả nguồn yêu cầu từ `tong-quan.md`, README service, gap docs, contract docs
- lưu ý: chưa có artifact stakeholder interview trực tiếp trong repo, nên phải ghi rõ phương pháp thu thập yêu cầu là document-driven analysis

### 3.2 Functional Requirements

- lập bảng FR-ID, Name, Description, Priority
- chỉ dùng yêu cầu có thể suy ra từ code và docs hiện tại

### 3.3 Non-functional Requirements

- performance: Kafka consumer, HPA, async processing
- security: OAuth2, JWT, internal auth, Redis blacklist
- availability: Docker/K8s manifests, rolling update, health checks
- scalability: HPA, multi-workload separation, queue-based runtime

### 3.4 Use Case Analysis

- overall use case diagram
- use case specs cho các luồng:
  - đăng nhập
  - tạo project
  - cấu hình datasource
  - chạy crawl / analytics
  - tìm kiếm / chat knowledge
  - nhận cảnh báo

### 3.5 Business Process Modeling

- luồng từ project configuration đến crawl execution và analytics publishing

## 3. Chapter 4: System Design

### 4.1 System Architecture

- high-level architecture
- container view
- dataflow và transport specialization

### 4.2 Database Design

- dựng ERD khái niệm và logical schema từ các service có evidence mạnh
- cần bảng data dictionary cho từng table quan trọng

### 4.3 Module Design

- phân tách module theo source tree thực tế
- phải nêu file và hàm hiện thực chính

### 4.4 Sequence Diagrams

- chuẩn bị tối thiểu 5 luồng:
  - OAuth login
  - project create
  - datasource activation
  - crawl runtime
  - analytics to knowledge
  - notification crisis alert

### 4.5 API Design

- tổng hợp endpoint từ identity, project, notification, knowledge nếu có evidence rõ

## 4. Chapter 5: Implementation

### 5.1 Development Environment

- OS, language runtimes, Docker, local stacks, manifests

### 5.2 Project Structure

- giải thích cấu trúc workspace và cấu trúc từng service chính

### 5.3 Core Feature Implementation

- OAuth2 + JWT session flow
- ingest datasource lifecycle
- analytics pipeline consumer flow
- knowledge search / chat
- notification dispatch

### 5.4 Deployment Process

- Dockerfile, Docker Compose, Kubernetes deployment và HPA có bằng chứng thật

### 5.5 User Interface Gallery

- workspace đã có frontend source trong `web-ui`; chỉ nên chọn các page hoặc flow có evidence rõ để đưa vào gallery

## 5. Chapter 6: Evaluation & Testing

- unit tests từ `analysis-srv` và `notification-srv`
- chiến lược kiểm thử dựa trên code hiện có
- performance evaluation phải bám metric và manifest thực tế, không tự bịa benchmark

## 6. Chapter 7: Conclusion

- tổng kết đóng góp
- hạn chế do thiếu frontend/CI artifacts
- hướng phát triển tiếp theo
