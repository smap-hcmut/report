# KẾ HOẠCH THUYẾT TRÌNH ĐỒ ÁN SMAP

## Social Media Analytics Platform

### Thời lượng: 20 phút

---

## TỔNG QUAN CẤU TRÚC THUYẾT TRÌNH

| Phần | Nội dung                    | Thời gian | Slide |
| ---- | --------------------------- | --------- | ----- |
| 1    | Mở đầu & Giới thiệu         | 1.5 phút  | 1-2   |
| 2    | Bối cảnh & Vấn đề           | 2 phút    | 3-4   |
| 3    | Mục tiêu & Phạm vi          | 1.5 phút  | 5     |
| 4    | Kiến trúc tổng quan         | 6 phút    | 6-10  |
| 5    | Luồng xử lý chính           | 5 phút    | 11-14 |
| 6    | Kết quả đạt được            | 2 phút    | 15-16 |
| 7    | Kết luận & Hướng phát triển | 2 phút    | 17-18 |

> **Lưu ý**: Với 20 phút, chỉ nên có 15-18 slides. Mỗi slide ~1 phút, không nên nhồi nhét quá nhiều.

---

## CHI TIẾT TỪNG PHẦN

### PHẦN 1: MỞ ĐẦU (1.5 phút)

**Slide 1: Trang bìa**

- Tên đề tài: "Xây dựng hệ thống SMAP – Social Media Analytics Platform"
- Sinh viên: Nguyễn Tấn Tài, Đặng Quốc Phong, Nguyễn Chánh Tín
- GVHD: Thầy Lê Đình Thuận

**Slide 2: Tóm tắt đề tài (30 giây)**

- SMAP = Nền tảng phân tích dữ liệu mạng xã hội
- Trọng tâm: **Thiết kế kiến trúc phần mềm** (không phải ML)
- Kết quả: Bộ thiết kế + hạ tầng Kubernetes

---

### PHẦN 2: BỐI CẢNH & VẤN ĐỀ (2 phút)

**Slide 3: Thị trường Social Listening**

- Việt Nam: YouNet, Buzzmetrics, Reputa
- Quốc tế: Talkwalker, YouScan, Meltwater
- **Vấn đề**: Chi phí cao, xử lý tiếng Việt chưa tốt

**Slide 4: Bài toán cần giải quyết**

- Dữ liệu MXH: Khổng lồ, phi cấu trúc, real-time
- Cần: Thu thập → Phân tích → Insight
- Thách thức kỹ thuật: Scale, Async, Fault-tolerant

---

### PHẦN 3: MỤC TIÊU & PHẠM VI (1.5 phút)

**Slide 5: Mục tiêu & Phạm vi**

- **Mục tiêu**: Thiết kế kiến trúc Microservices + Event-driven
- **Nguồn dữ liệu**: YouTube, TikTok (công khai)
- **Triển khai**: On-premise Kubernetes
- **Không bao gồm**: Nghiên cứu ML chuyên sâu

---

### PHẦN 4: KIẾN TRÚC TỔNG QUAN (6 phút) ⭐ TRỌNG TÂM

**Slide 6: System Context (C4 Level 1)**

- Sơ đồ tổng quan: User → SMAP → Social Platforms
- Giải thích ngắn gọn các actors

**Slide 7: Container Diagram (C4 Level 2)**

- 5 Services chính (chỉ liệt kê tên + vai trò):
  - Identity Service (Go) - Xác thực
  - Project Service (Go) - Quản lý projects
  - Collector Service (Go) - Thu thập dữ liệu
  - AI/ML Service (Python) - Phân tích NLP
  - WebSocket Service (Go) - Real-time

**Slide 8: Infrastructure Components**

- PostgreSQL, RabbitMQ, Redis, MinIO
- Giải thích vai trò từng component

**Slide 9: Event-Driven Architecture**

- Sơ đồ message flow
- RabbitMQ: Async processing
- Redis Pub/Sub: Real-time notifications
- **Claim-Check Pattern**: Giải pháp cho payload lớn

**Slide 10: Tại sao chọn kiến trúc này?**

- So sánh nhanh Microservices vs Monolithic
- Lợi ích: Scale độc lập, Fault isolation, Tech diversity

---

### PHẦN 5: LUỒNG XỬ LÝ CHÍNH (5 phút)

**Slide 11: Use Cases Overview**

- Sơ đồ Use Case (1 hình)
- 7 UC chính: Cấu hình, Dry-run, Execute, View Results, List, Export, Trend

**Slide 12: Data Pipeline (QUAN TRỌNG)**

- Sơ đồ 4 giai đoạn: Crawling → Analyzing → Aggregating → Finalizing
- Giải thích ngắn từng giai đoạn

**Slide 13: Sequence Diagram - Execute Project**

- Chọn 1 sequence diagram quan trọng nhất
- Giải thích luồng tương tác giữa services

**Slide 14: Database Strategy**

- Database-per-Service pattern
- ERD tổng quan (1 hình gộp, không chi tiết từng bảng)

---

### PHẦN 6: KẾT QUẢ ĐẠT ĐƯỢC (2 phút)

**Slide 15: Deliverables**

- ✅ 47 yêu cầu chức năng, 31 NFR
- ✅ 7 Activity Diagrams, 7 Sequence Diagrams
- ✅ ERD cho các services
- ✅ Hạ tầng Kubernetes đầy đủ

**Slide 16: Demo/Screenshots (nếu có)**

- 1-2 screenshots UI
- Hoặc video ngắn 30 giây

---

### PHẦN 7: KẾT LUẬN (2 phút)

**Slide 17: Hạn chế & Hướng phát triển**

- Hạn chế: Chưa triển khai đầy đủ, chỉ 2 platforms
- Ngắn hạn: Hoàn thiện AI/ML, Dashboard
- Trung hạn: Mở rộng Facebook, Instagram

**Slide 18: Tổng kết**

- Đã hoàn thành: Phân tích + Thiết kế đầy đủ
- Kiến trúc: Microservices + Event-driven + Kubernetes
- Tiềm năng: Sản phẩm cạnh tranh trên thị trường

---

## GỢI Ý TRÌNH BÀY

### Nguyên tắc vàng cho 20 phút:

- **15-18 slides** là tối đa
- **1 slide = 1 ý chính** (không nhồi nhét)
- **Mỗi slide ~1 phút** (có slide nhanh, có slide chậm)
- **Dùng hình > chữ** (diagram nói thay bạn)

### Điểm nhấn quan trọng (phải nói rõ):

1. **Microservices + Event-driven** - Lý do chọn, lợi ích
2. **Claim-Check Pattern** - Giải pháp sáng tạo
3. **Data Pipeline 4 giai đoạn** - Luồng xử lý chính
4. **Kubernetes** - Khả năng scale

### Những thứ KHÔNG cần nói chi tiết:

- ERD từng bảng (chỉ show hình tổng quan)
- Code implementation
- Từng yêu cầu FR/NFR (chỉ nói con số)
- So sánh chi tiết các đối thủ

### Câu hỏi thường gặp:

1. Tại sao Microservices không Monolithic?
2. Xử lý rate-limit từ platforms như thế nào?
3. Độ chính xác sentiment analysis?
4. Tại sao dùng RabbitMQ không Kafka?

### Tips:

- Tập trình bày 2-3 lần, canh đúng 20 phút
- Chuẩn bị 2-3 slides backup cho Q&A
- Nếu hết giờ, bỏ phần Demo, giữ Kết luận

---

## DANH SÁCH HÌNH ẢNH TỪ BÁO CÁO

Tất cả hình ảnh đã có sẵn trong `report/images/`:

### Diagrams (Bắt buộc)

| Slide | Hình                       | Đường dẫn                                                   |
| ----- | -------------------------- | ----------------------------------------------------------- |
| 6     | Context Diagram            | `report/images/diagram/context-diagram.png`                 |
| 7     | Container Diagram          | `report/images/diagram/container-diagram.png`               |
| 10    | Monolithic Architecture    | `report/images/architecture/monolithic_architecture.png`    |
| 10    | Modular Monolith           | `report/images/architecture/modular_monolith.png`           |
| 10    | Microservices Architecture | `report/images/architecture/microservices_architecture.png` |

### Data Flow (Quan trọng)

| Slide | Hình                 | Đường dẫn                                        |
| ----- | -------------------- | ------------------------------------------------ |
| 9, 12 | Analytics Pipeline   | `report/images/data-flow/analytics-pipeline.png` |
| 9     | Execute Project Flow | `report/images/data-flow/execute_project.png`    |
| 9     | Real-time Flow       | `report/images/data-flow/real-time.png`          |
| 9     | Progress Flow        | `report/images/data-flow/Progress.png`           |

### Sequence Diagrams

| Slide | Hình               | Đường dẫn                                       |
| ----- | ------------------ | ----------------------------------------------- |
| 13    | UC3 Execute Part 1 | `report/images/sequence/uc3_execute_part_1.png` |
| 13    | UC3 Execute Part 2 | `report/images/sequence/uc3_execute_part_2.png` |
| 13    | UC3 Execute Part 3 | `report/images/sequence/uc3_execute_part_3.png` |
| 13    | UC3 Execute Part 4 | `report/images/sequence/uc3_execute_part_4.png` |

### ERD Diagrams

| Slide | Hình         | Đường dẫn                            |
| ----- | ------------ | ------------------------------------ |
| 14    | Identity ERD | `report/images/erd/identity-erd.png` |
| 14    | Project ERD  | `report/images/erd/project-erd.png`  |
| 14    | Analytic ERD | `report/images/erd/analytic-erd.png` |

### UI Screenshots

| Slide | Hình          | Đường dẫn                          |
| ----- | ------------- | ---------------------------------- |
| 16    | Landing Page  | `report/images/UI/landing.png`     |
| 16    | Projects List | `report/images/UI/cacprojects.png` |
| 16    | Dry-run       | `report/images/UI/dryrun.png`      |
| 16    | Chart 1       | `report/images/UI/char1.png`       |
| 16    | Chart 2       | `report/images/UI/char2.png`       |
| 16    | Chart 3       | `report/images/UI/char3.png`       |
| 16    | Chart 4       | `report/images/UI/char4.png`       |
| 16    | Trend         | `report/images/UI/trend.png`       |

### Khác

| Slide | Hình               | Đường dẫn                                                    |
| ----- | ------------------ | ------------------------------------------------------------ |
| 1     | Logo trường        | `report/images/hcmut.png`                                    |
| 15    | NFR Radar Chart    | `report/images/NFRs_rada_chart.png`                          |
| 8     | Deployment Diagram | `report/images/deploy/Diagram-deployment-diagram.drawio.png` |

### Activity Diagrams (Backup)

- `report/images/activity/1.png` đến `8.png` - 8 activity diagrams
- `report/images/activity/dry.png` - Dry-run activity

### Component Diagrams (Backup)

- `report/images/component/identity-component-diagram.png`
- `report/images/component/project-component-diagram.png`
- `report/images/component/collector-component-diagram.png`
- `report/images/component/analytic-component-diagram.png`
- `report/images/component/websocket-component-diagram.png`
- `report/images/component/webui-component-diagram.png`

---

## TIMELINE CHUẨN BỊ

| Ngày | Công việc                           |
| ---- | ----------------------------------- |
| D-7  | Hoàn thành nội dung slides          |
| D-5  | Review và chỉnh sửa                 |
| D-3  | Tập trình bày lần 1                 |
| D-2  | Tập trình bày lần 2, canh thời gian |
| D-1  | Final review, chuẩn bị Q&A          |
| D-0  | Thuyết trình                        |

---

---

## DANH SÁCH FILE SLIDE CHI TIẾT

Mỗi slide đã được tạo file riêng với nội dung, hình ảnh cần có và văn nói:

| Slide | File                                                                  | Nội dung                       |
| ----- | --------------------------------------------------------------------- | ------------------------------ |
| 1     | [slide_01_title.md](slides/slide_01_title.md)                         | Trang bìa                      |
| 2     | [slide_02_summary.md](slides/slide_02_summary.md)                     | Tóm tắt đề tài                 |
| 3     | [slide_03_market.md](slides/slide_03_market.md)                       | Thị trường Social Listening    |
| 4     | [slide_04_problem.md](slides/slide_04_problem.md)                     | Bài toán cần giải quyết        |
| 5     | [slide_05_scope.md](slides/slide_05_scope.md)                         | Mục tiêu & Phạm vi             |
| 6     | [slide_06_context.md](slides/slide_06_context.md)                     | System Context (C4 Level 1)    |
| 7     | [slide_07_container.md](slides/slide_07_container.md)                 | Container Diagram (C4 Level 2) |
| 8     | [slide_08_infrastructure.md](slides/slide_08_infrastructure.md)       | Infrastructure Components      |
| 9     | [slide_09_event_driven.md](slides/slide_09_event_driven.md)           | Event-Driven Architecture      |
| 10    | [slide_10_why_microservices.md](slides/slide_10_why_microservices.md) | Tại sao chọn kiến trúc này     |
| 11    | [slide_11_usecases.md](slides/slide_11_usecases.md)                   | Use Cases Overview             |
| 12    | [slide_12_pipeline.md](slides/slide_12_pipeline.md)                   | Data Pipeline                  |
| 13    | [slide_13_sequence.md](slides/slide_13_sequence.md)                   | Sequence Diagram               |
| 14    | [slide_14_database.md](slides/slide_14_database.md)                   | Database Strategy              |
| 15    | [slide_15_results.md](slides/slide_15_results.md)                     | Kết quả đạt được               |
| 16    | [slide_16_demo.md](slides/slide_16_demo.md)                           | Demo/Screenshots               |
| 17    | [slide_17_limitations.md](slides/slide_17_limitations.md)             | Hạn chế & Hướng phát triển     |
| 18    | [slide_18_conclusion.md](slides/slide_18_conclusion.md)               | Tổng kết & Q&A                 |

---

_Ghi chú: Plan này dựa trên nội dung báo cáo đồ án SMAP. Có thể điều chỉnh tùy theo yêu cầu của hội đồng và thời gian thực tế._
