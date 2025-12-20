# Hướng Dẫn Format Viết NFRs (Non-Functional Requirements)

Tài liệu này mô tả format chi tiết để viết NFRs dựa trên cấu trúc của report hiện tại.

## Cấu Trúc Tổng Quan

NFRs được chia thành 2 phần chính:

1. **Đặc Tính Kiến Trúc (Architecture Characteristics)** - Định nghĩa chất lượng bên trong hệ thống
2. **Thuộc Tính Chất Lượng (Quality Attributes)** - Định nghĩa chất lượng bên ngoài mà người dùng cảm nhận

---

## 1. ĐẶC TÍNH KIẾN TRÚC (Architecture Characteristics)

### 1.1. Cấu Trúc Chung

Mỗi đặc tính kiến trúc được trình bày trong một bảng với các cột:

| Cột | Mô tả | Yêu cầu |
|-----|-------|---------|
| **AC** | Mã định danh | Format: AC-1, AC-2, ... |
| **Đặc tính** | Tên đặc tính | Tên ngắn gọn, rõ ràng (VD: Modularity, Scalability) |
| **Định nghĩa & Tầm quan trọng** | Giải thích chi tiết | - Định nghĩa: Mô tả đặc tính là gì<br>- Tầm quan trọng: Tại sao quan trọng với hệ thống |
| **Metrics & Mục tiêu** | Đo lường và mục tiêu | - Metrics: Các chỉ số đo lường<br>- Mục tiêu: Giá trị cụ thể, định lượng (SLO) |
| **Fitness Function** | Hàm kiểm thử tự động | Cách kiểm chứng tự động đặc tính này được đảm bảo |

### 1.2. Phân Loại

#### a. Các Đặc tính Kiến trúc Chính (Primary Architecture Characteristics)
- **Định nghĩa**: Các đặc tính ảnh hưởng trực tiếp đến hình dạng kiến trúc tổng thể
- **Ví dụ**: Modularity, Scalability, Performance, Testability
- **Số lượng**: Thường 3-5 đặc tính

#### b. Các Đặc tính Kiến trúc Bổ trợ (Secondary Architecture Characteristics)
- **Định nghĩa**: Tập trung vào khía cạnh vận hành, bảo trì và mở rộng
- **Ví dụ**: Deployability, Security, Maintainability, Extensibility, Observability
- **Số lượng**: Thường 4-6 đặc tính

### 1.3. Template Chi Tiết

```
AC-[Số] | [Tên Đặc tính]

Định nghĩa & Tầm quan trọng:
- Định nghĩa: [Mô tả đặc tính là gì, ví dụ: "Phân rã hệ thống thành các module độc lập với low coupling, high cohesion"]
- Tầm quan trọng: [Giải thích tại sao quan trọng, ví dụ: "Bảo đảm live AI model swapping không downtime"]

Metrics & Mục tiêu:
- Metrics: [Danh sách các chỉ số, ví dụ: "I ≈ 0, Ce < 5, LCOM < 1"]
- Mục tiêu: [Giá trị cụ thể, ví dụ: "Thay module < 5 phút, zero downtime khi swap AI, ≤ 3 dependencies/module lõi"]

Fitness Function:
- [Tên công cụ/test]: [Mô tả cách kiểm chứng, ví dụ: "ArchUnit Test: Fail nếu domain phụ thuộc repository cụ thể"]
- [Tên công cụ/test]: [Mô tả cách kiểm chứng khác]
```

### 1.4. Ví Dụ Mẫu

```
AC-1 | Modularity

Định nghĩa & Tầm quan trọng:
- Định nghĩa: Phân rã hệ thống thành các module độc lập với low coupling, high cohesion.
- Tầm quan trọng: Bảo đảm live AI model swapping không downtime, cho phép cập nhật thuật toán liên tục.

Metrics & Mục tiêu:
- Metrics: I ≈ 0, Ce < 5, LCOM < 1
- Mục tiêu: Thay module < 5 phút, zero downtime khi swap AI, ≤ 3 dependencies/module lõi

Fitness Function:
- ArchUnit Test: Fail nếu domain phụ thuộc repository cụ thể
- Dependency Check: Fail khi build phát hiện circular dependencies
```

---

## 2. THUỘC TÍNH CHẤT LƯỢNG (Quality Attributes)

### 2.1. Cấu Trúc Chung

Mỗi thuộc tính chất lượng được trình bày trong một bảng với cấu trúc:

| Cột | Mô tả | Yêu cầu |
|-----|-------|---------|
| **Nhóm** | Nhóm con của thuộc tính | Tên nhóm (VD: Response Time, Authentication & Authorization) |
| **Hạng mục** | Các mục cụ thể trong nhóm | Tên mục (VD: Login/Authentication, SSO) |
| **Yêu cầu/Mục tiêu** | Yêu cầu cụ thể, định lượng | Giá trị cụ thể, có thể đo lường được |

### 2.2. Danh Sách Các Thuộc Tính Chất Lượng

#### a. Yêu cầu Hiệu năng (Performance Requirements)
**Các nhóm con:**
- Response Time: Thời gian phản hồi cho các tác vụ cụ thể
- Throughput: Số lượng request/event xử lý được
- Resource Utilization: Sử dụng tài nguyên (CPU, Memory, Network, Storage)

**Format mục tiêu:**
- Response Time: `< [giá trị]ms` hoặc `< [giá trị] giây` với percentile (p95, p99)
- Throughput: `[số] requests/giây` hoặc `[số] events/phút`
- Resource: `< [phần trăm]%` hoặc `< [giá trị]ms latency`

**Ví dụ:**
```
Nhóm: Response Time
- Login/Authentication: < 200ms (p95)
- Content Loading: < 500ms (p95)
- Real-time Feedback Generation: < 500ms (p95)
```

#### b. Yêu cầu Khả năng Mở rộng (Scalability Requirements)
**Các nhóm con:**
- Horizontal Scaling: Mở rộng ngang (thêm instance)
- Vertical Scaling: Mở rộng dọc (nâng cấp instance)
- Load Distribution: Phân tải
- Capacity Planning: Kế hoạch dung lượng

**Format mục tiêu:**
- Scaling trigger: `[metric] [phần trăm]%`
- Scale time: `[min] → [max] instance trong < [thời gian]`
- Capacity: Số lượng cụ thể (users, storage, requests)

**Ví dụ:**
```
Nhóm: Horizontal Scaling
- Auto-scaling trigger: CPU 70% hoặc memory 75%
- Scale units: 2 → 20 instance trong < 60 giây
- Concurrent users (initial): 5,000
```

#### c. Yêu cầu Bảo mật (Security Requirements)
**Các nhóm con:**
- Authentication & Authorization: Xác thực và phân quyền
- Data Protection: Bảo vệ dữ liệu
- Compliance & Privacy: Tuân thủ và quyền riêng tư
- Application Security: Bảo mật ứng dụng

**Format mục tiêu:**
- Standards: Tên chuẩn cụ thể (VD: OAuth 2.0, TLS 1.3, AES-256)
- Time-based: `< [thời gian]` (VD: Session timeout 30 phút)
- Rate limits: `[số] requests/phút/user`

**Ví dụ:**
```
Nhóm: Authentication & Authorization
- SSO: OAuth 2.0 / OpenID Connect
- Phiên làm việc: JWT 15 phút, refresh token an toàn
- Multi-factor: MFA cho admin/instructor
- Rate limiting: 100 requests/phút/user
```

#### d. Yêu cầu Độ tin cậy (Reliability Requirements)
**Các nhóm con:**
- Availability: Tính sẵn sàng
- Fault Tolerance: Chịu lỗi
- Data Integrity: Toàn vẹn dữ liệu
- Backup & Recovery: Sao lưu và phục hồi

**Format mục tiêu:**
- Availability: `[phần trăm]%` với downtime tương ứng
- RTO/RPO: `RTO < [thời gian]`, `RPO < [thời gian]`
- Failover: `< [thời gian]` để failover

**Ví dụ:**
```
Nhóm: Availability
- Uptime hệ thống: 99.5% (downtime < 44 giờ/năm)
- Core services: 99.9% (downtime < 9 giờ/năm)
- Redundancy: Active-active, failover < 30 giây
```

#### e. Yêu cầu Khả năng Sử dụng (Usability Requirements)
**Các nhóm con:**
- User Interface: Giao diện người dùng
- User Experience: Trải nghiệm người dùng
- Learning Curve: Đường cong học tập

**Format mục tiêu:**
- Standards: Tên chuẩn (VD: WCAG 2.1 mức AA)
- Performance metrics: `< [giá trị]` (VD: First meaningful paint < 1.5 giây)
- Features: Mô tả tính năng (VD: Responsive design, Dark mode)

**Ví dụ:**
```
Nhóm: User Interface
- Responsive design: Mobile/Tablet/Desktop
- Accessibility: WCAG 2.1 mức AA
- Tuỳ biến: Đa ngôn ngữ (VN/EN), dark mode, font tuỳ chỉnh
```

#### f. Yêu cầu Tương thích (Compatibility Requirements)
**Các nhóm con:**
- Browser Support: Hỗ trợ trình duyệt
- Device Support: Hỗ trợ thiết bị
- Integration Compatibility: Tương thích tích hợp
- API Compatibility: Tương thích API

**Format mục tiêu:**
- Versions: `[Tên] [phiên bản]+` (VD: Chrome 90+, iOS 13+)
- Standards: Tên chuẩn (VD: LTI 1.3, SCORM 2004, OpenAPI 3.0)
- Compatibility: Mô tả (VD: Hỗ trợ 2 phiên bản chính)

**Ví dụ:**
```
Nhóm: Browser Support
- Trình duyệt: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- Progressive enhancement: Hỗ trợ trình duyệt cũ ở mức tối thiểu
```

#### g. Yêu cầu Giám sát (Monitoring Requirements)
**Các nhóm con:**
- Metrics Collection: Thu thập metrics
- Logging: Ghi log
- Tracing: Distributed tracing
- Alerting: Cảnh báo

**Format mục tiêu:**
- Tools: Tên công cụ (VD: Prometheus, ELK, OpenTelemetry)
- Retention: `[thời gian]` (VD: 30 ngày hot, 1 năm cold)
- Coverage: `[phần trăm]%` (VD: 100% requests có trace ID)

**Ví dụ:**
```
Nhóm: Metrics Collection
- Application metrics: Prometheus/StatsD, dashboard KPI
- Logging retention: 30 ngày (hot), 1 năm (cold)
- Distributed tracing: OpenTelemetry, sampling 10%
```

#### h. Yêu cầu Tuân thủ (Compliance Requirements)
**Các nhóm con:**
- Educational Standards: Chuẩn giáo dục
- Data Governance: Quản trị dữ liệu
- Audit & Reporting: Kiểm toán và báo cáo

**Format mục tiêu:**
- Standards: Tên chuẩn (VD: GDPR, COPPA, FERPA)
- Features: Mô tả tính năng (VD: Right-to-be-forgotten, retention 3 năm)

**Ví dụ:**
```
Nhóm: Educational Standards
- Curriculum alignment: VN National Curriculum, Cambridge, IB
- Competency-based: Mapping learning objectives, standards grading
```

#### i. Yêu cầu Phục hồi Thảm hoạ (Disaster Recovery Requirements)
**Các nhóm con:**
- Business Continuity: Tính liên tục kinh doanh
- Data Recovery: Phục hồi dữ liệu

**Format mục tiêu:**
- Frequency: `[số] lần/[khoảng thời gian]` (VD: 2 lần/năm)
- Features: Mô tả (VD: Backup verification tự động, nhiều địa điểm)

**Ví dụ:**
```
Nhóm: Business Continuity
- DR plan: Tài liệu đầy đủ, kiểm thử định kỳ
- DR drill: 2 lần/năm
```

#### j. Yêu cầu Bảo trì & Hỗ trợ (Maintenance & Support Requirements)
**Các nhóm con:**
- System Maintenance: Bảo trì hệ thống
- Technical Support: Hỗ trợ kỹ thuật

**Format mục tiêu:**
- Time: `< [thời gian]` (VD: Critical incidents < 15 phút)
- Frequency: `[khoảng thời gian]` (VD: Dependency update hàng tháng)
- Features: Mô tả (VD: Blue-green deployment, 24/7 monitoring)

**Ví dụ:**
```
Nhóm: System Maintenance
- Triển khai: Blue-green deployment, automation database maintenance
- Cập nhật: Dependency update hàng tháng
```

---

## 3. NGUYÊN TẮC VIẾT NFRs

### 3.1. Nguyên Tắc Chung

1. **Định lượng (Quantifiable)**: Mọi yêu cầu phải có giá trị cụ thể, có thể đo lường được
   - ✅ Tốt: "Response time < 500ms (p95)"
   - ❌ Tốt: "Hệ thống phải nhanh"

2. **Có thể kiểm chứng (Verifiable)**: Phải có cách kiểm chứng tự động hoặc thủ công
   - ✅ Tốt: "K6 Load Test: Staging đạt p99 < 1s tại 5,000 users"
   - ❌ Tốt: "Hệ thống phải chịu được nhiều người dùng"

3. **Liên quan đến nghiệp vụ (Business-relevant)**: Phải giải thích tại sao quan trọng
   - ✅ Tốt: "Tầm quan trọng: Critical cho phản hồi remedial real-time trong phiên 1-kèm-1"
   - ❌ Tốt: "Performance quan trọng"

4. **Có thể đạt được (Achievable)**: Mục tiêu phải thực tế với công nghệ và ngân sách
   - ✅ Tốt: "99.5% uptime (downtime < 44 giờ/năm)"
   - ❌ Tốt: "100% uptime"

### 3.2. Format Metrics

- **Percentiles**: Sử dụng p95, p99 cho response time
- **Units**: Rõ ràng (ms, giây, requests/giây, %, TB)
- **Ranges**: Sử dụng `<`, `>`, `≤`, `≥` cho các giới hạn
- **Time periods**: Rõ ràng (giây, phút, giờ, ngày, năm)

### 3.3. Format Fitness Functions

- **Tên công cụ**: Rõ ràng (VD: ArchUnit Test, K6 Load Test, SonarQube)
- **Điều kiện**: Mô tả khi nào fail/pass
- **Tự động hóa**: Ưu tiên kiểm thử tự động trong CI/CD

---

## 4. CHECKLIST KHI VIẾT NFRs

### 4.1. Checklist Đặc Tính Kiến Trúc

- [ ] Có mã định danh AC-[số]
- [ ] Có định nghĩa rõ ràng
- [ ] Có giải thích tầm quan trọng
- [ ] Có metrics cụ thể
- [ ] Có mục tiêu định lượng (SLO)
- [ ] Có ít nhất 1 fitness function
- [ ] Fitness function có thể tự động hóa

### 4.2. Checklist Thuộc Tính Chất Lượng

- [ ] Được nhóm theo các nhóm con hợp lý
- [ ] Mỗi hạng mục có yêu cầu/mục tiêu cụ thể
- [ ] Yêu cầu có thể đo lường được
- [ ] Sử dụng đơn vị rõ ràng
- [ ] Có giá trị số cụ thể (không chỉ mô tả chung chung)
- [ ] Phù hợp với đặc thù hệ thống

### 4.3. Checklist Tổng Thể

- [ ] Tất cả NFRs đều định lượng
- [ ] Có liên kết với yêu cầu nghiệp vụ
- [ ] Phù hợp với kiến trúc hệ thống
- [ ] Có thể kiểm chứng được
- [ ] Format nhất quán trong toàn bộ document

---

## 5. VÍ DỤ HOÀN CHỈNH

### Ví dụ: Viết NFR cho một hệ thống E-commerce

#### Đặc Tính Kiến Trúc

```
AC-1 | Performance

Định nghĩa & Tầm quan trọng:
- Định nghĩa: Đáp ứng yêu cầu nhanh để giữ trải nghiệm mua sắm mượt mà
- Tầm quan trọng: Critical cho conversion rate, người dùng sẽ rời bỏ nếu trang load chậm

Metrics & Mục tiêu:
- Metrics: Response time percentiles, page load time, time to interactive
- Mục tiêu: p95 < 300ms cho API, page load < 2s, TTI < 3s

Fitness Function:
- Lighthouse CI: Fail nếu performance score < 90
- Load Test: Fail nếu p95 > 300ms tại 1,000 concurrent users
```

#### Thuộc Tính Chất Lượng - Performance

```
Nhóm: Response Time
- Product Search: < 200ms (p95)
- Add to Cart: < 150ms (p95)
- Checkout Process: < 500ms (p95)
- Payment Processing: < 1 giây (p95)

Nhóm: Throughput
- API Gateway: 10,000 requests/giây
- Order Processing: 5,000 orders/phút
- Search Service: 20,000 queries/giây
```

---

## 6. LƯU Ý QUAN TRỌNG

1. **Không copy-paste**: Mỗi hệ thống có đặc thù riêng, cần điều chỉnh NFRs phù hợp
2. **Ưu tiên**: Không phải tất cả NFRs đều quan trọng như nhau, cần ưu tiên
3. **Cập nhật**: NFRs có thể thay đổi theo thời gian, cần review định kỳ
4. **Trade-offs**: Một số NFRs có thể mâu thuẫn, cần cân nhắc trade-offs
5. **Đo lường**: Phải có cách đo lường thực tế, không chỉ định nghĩa lý thuyết

---

## 7. TÀI LIỆU THAM KHẢO

- Report hiện tại: `report/contents/2.4_non_functional_requirements.tex`
- Architecture Characteristics: Theo định nghĩa của Mark Richards & Neal Ford
- Quality Attributes: Theo ISO/IEC 25010
- SLO/SLI: Theo Google SRE Book
