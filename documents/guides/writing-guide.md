# HƯỚNG DẪN VIẾT BÁO CÁO ĐỒ ÁN - CHƯƠNG 4

# WRITING GUIDE FOR CHAPTER 4: ANALYSIS & DESIGN

> **Mục đích file này:** Hướng dẫn chi tiết cách viết từng phần của báo cáo để đảm bảo **ĐỦ DẪN CHỨNG** rằng requirements đã được map đầy đủ vào system design.

---

## 📋 MỤC LỤC

1. [Nguyên tắc Viết Chung](#1-nguyên-tắc-viết-chung)
2. [Cấu trúc Câu trả lời](#2-cấu-trúc-câu-trả-lời)
3. [Hướng dẫn từng Section](#3-hướng-dẫn-từng-section)
4. [Checklist Hoàn thành](#4-checklist-hoàn-thành)
5. [Common Mistakes](#5-common-mistakes)

---

## 1. NGUYÊN TẮC VIẾT CHUNG

### 1.1 Nguyên tắc "Evidence-Based Writing"

**LUÔN BÁM SÁT 3 CÂU HỎI:**

```
┌─────────────────────────────────────────────────────────────┐
│         3 CÂU HỎI BẮT BUỘC CHO MỖI SECTION                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. WHAT? (Cái gì?)                                         │
│     → Mô tả component/decision/pattern là gì               │
│                                                             │
│  2. WHY? (Tại sao?)                                         │
│     → Giải thích lý do chọn cách này thay vì cách khác      │
│     → QUAN TRỌNG: Phải có so sánh với alternatives          │
│                                                             │
│  3. EVIDENCE? (Bằng chứng?)                                 │
│     → Số liệu cụ thể: metrics, performance, cost           │
│     → Link đến section khác trong báo cáo                  │
│     → Ví dụ thực tế                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Quy tắc "Traceability" (Truy vết)

**MỖI QUYẾT ĐỊNH PHẢI TRACE ĐƯỢC:**

```
Requirements → Decisions → Architecture → Implementation → Evidence

Ví dụ:
NFR-SC-01 (500k posts/day)
  ↓
ADR-001 (Chọn Microservices)
  ↓
Collection Service với Master-Worker pattern
  ↓
Kubernetes HPA scaling 1-10 pods
  ↓
Evidence: 64M posts/day capacity (4.7.5.6)
```

**Khi viết, TỰ HỎI:**

- [ ] Requirement này ánh xạ vào component nào?
- [ ] Component này đáp ứng requirement nào?
- [ ] Có bằng chứng cụ thể không? (số liệu, diagram, code)

### 1.3 Quy tắc "No Hand-waving"

❌ **TRÁNH:**

- "Hệ thống scale tốt" → ❌ Mơ hồ
- "Performance cao" → ❌ Không có số liệu
- "Dễ maintain" → ❌ Chủ quan

✅ **NÊN:**

- "Hệ thống scale từ 2→20 pods trong 2 phút" → ✅ Cụ thể
- "API response time <500ms (p99)" → ✅ Có metric
- "MTTR giảm từ 2h xuống 15 phút" → ✅ Đo lường được

---

## 2. CẤU TRÚC CÂU TRẢ LỜI

### 2.1 Template Chuẩn cho Mỗi Section

```markdown
## X.X.X Tên Section

### X.X.X.1 Tổng quan

**Mục đích:** [1-2 câu giải thích tại sao cần section này]

**Câu hỏi cần trả lời:**

- [Câu hỏi 1]
- [Câu hỏi 2]

### X.X.X.2 Phân tích

[Nội dung chính với bảng/diagram]

### X.X.X.3 Quyết định & Justification

**Lựa chọn:** [Decision đã chọn]

**Alternatives Considered:**
| Phương án | Ưu điểm | Nhược điểm | Tại sao bị loại |
|-----------|---------|------------|-----------------|
| Option A | ... | ... | ... |
| Option B | ... | ... | ... |

**Evidence:**

- Metric 1: [Số liệu]
- Metric 2: [Số liệu]
- Reference: [Link đến section khác]

### X.X.X.4 Tóm tắt

[Key takeaways - 3-5 bullet points]
```

### 2.2 Cách Viết Justification (Biện luận)

**CÔNG THỨC:**

```
Justification = Decision + Rationale + Alternatives + Trade-offs + Evidence

Ví dụ:
Decision: "Chọn Golang cho API Services"
Rationale: "Cần high concurrency và low memory footprint"
Alternatives:
  - Node.js: Bị loại vì single-threaded và memory leaks
  - Java: Bị loại vì verbose và heavy JVM
Trade-offs:
  (+) 10x faster than Python
  (-) Smaller ecosystem than Node.js
Evidence:
  - API Gateway: 15,000 rps
  - Memory: 180MB/pod
  - Reference: 4.7.5.6 Performance Analysis
```

### 2.3 Cách Viết Evidence (Dẫn chứng)

**3 LOẠI EVIDENCE:**

1. **Quantitative (Định lượng):**

   ```
   ✅ "API response time <500ms (p99)" - measured by Prometheus
   ✅ "Cost savings: $2,950/month (AWS) → $650/month (on-premise) = -78%"
   ✅ "Test coverage: 85%"
   ```

2. **Qualitative (Định tính):**

   ```
   ✅ "Code review shows clean separation of concerns"
   ✅ "Architecture follows SOLID principles"
   ✅ "Team feedback: deployment time reduced significantly"
   ```

3. **Reference (Tham chiếu):**
   ```
   ✅ "See 4.7.5.6 for detailed performance analysis"
   ✅ "Traceability matrix in 4.12.2 shows 92% coverage"
   ✅ "Diagram in 4.7.5.2 illustrates container architecture"
   ```

---

## 3. HƯỚNG DẪN TỪNG SECTION

### 3.1 Section 4.7.6 - Component Diagrams

**CÂU HỎI CẦN TRẢ LỜI:**

| #   | Câu hỏi                                        | Cách trả lời                                  | Ví dụ cụ thể                                                                                                                             |
| --- | ---------------------------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Bên trong service này có những component nào?  | Vẽ diagram + liệt kê bảng                     | Analytics Service có 7 components: Event Consumer, Data Loader, Preprocessing, Sentiment Analyzer, NER, Topic Modeling, Result Publisher |
| 2   | Mỗi component có trách nhiệm gì?               | Bảng: Component → Responsibility → Technology | Event Consumer: Nhận events từ RabbitMQ → pika library                                                                                   |
| 3   | Các components giao tiếp với nhau như thế nào? | Data flow diagram                             | Event Consumer → Orchestrator → Data Loader → ...                                                                                        |
| 4   | Tại sao tổ chức như vậy?                       | Áp dụng design pattern nào?                   | Pipeline Pattern → clear separation of concerns                                                                                          |
| 5   | Performance của từng component?                | Metrics cho mỗi component                     | Data Loader: 3.8s to download 50k posts from MinIO                                                                                       |

**TEMPLATE VIẾT:**

```markdown
### 4.7.6.2 Analytics Service - Internal Architecture

**Context:** Service này chịu trách nhiệm [mô tả vai trò].

**Architecture Diagram:**
[VẼ DIAGRAM - dùng ASCII hoặc tool như diagrams.net]

**Component Catalog:**

| Component      | Responsibility | Input   | Output   | Technology | Performance |
| -------------- | -------------- | ------- | -------- | ---------- | ----------- |
| Event Consumer | [Trách nhiệm]  | [Input] | [Output] | [Tech]     | [Metric]    |
| ...            | ...            | ...     | ...      | ...        | ...         |

**Data Flow:**
```

1. [Step 1 với timing]
   ↓
2. [Step 2 với timing]
   ↓
   ...

```

**Design Patterns Applied:**
- Pattern 1: [Where] → [Benefit]
- Pattern 2: [Where] → [Benefit]

**Performance Characteristics:**
[Bảng metrics với evidence từ 4.7.5.6]

**Key Decisions:**
- Decision 1: [What] → [Why] → [Evidence]
- Decision 2: [What] → [Why] → [Evidence]
```

**VÍ DỤ ĐÃ VIẾT TỐT:** Xem file `4.7.6.md` (đã tạo)

---

### 3.2 Section 4.7.7 - Technology Stack

**CÂU HỎI CẦN TRẢ LỜI:**

| #   | Câu hỏi                             | Cách trả lời             | Điểm cộng                                          |
| --- | ----------------------------------- | ------------------------ | -------------------------------------------------- |
| 1   | Danh sách tất cả công nghệ?         | Bảng tổng hợp theo layer | Có phân loại: Languages, Databases, Infrastructure |
| 2   | Tại sao chọn công nghệ X thay vì Y? | So sánh alternatives     | Có bảng Pros/Cons với số liệu                      |
| 3   | Chi phí (TCO) là bao nhiêu?         | Cost analysis            | So sánh với Cloud alternatives                     |
| 4   | Risk của từng công nghệ?            | Risk assessment          | Có mitigation plan                                 |
| 5   | Roadmap nâng cấp công nghệ?         | Timeline                 | Có Phase 1, 2, 3 với lý do                         |

**TEMPLATE VIẾT:**

```markdown
### 4.7.7.2 Technology Decision Matrix

| Technology  | Category | Why Chosen  | Alternatives Rejected                   | Trade-offs              | Evidence  |
| ----------- | -------- | ----------- | --------------------------------------- | ----------------------- | --------- |
| Golang 1.23 | Backend  | [3-5 lý do] | Node.js (lý do loại), Java (lý do loại) | (+) Benefit<br>(-) Cost | [Metrics] |
| ...         | ...      | ...         | ...                                     | ...                     | ...       |

**Cost Analysis:**

| Component | SMAP Choice | Cloud Alternative | Savings |
| --------- | ----------- | ----------------- | ------- |
| Compute   | $600/month  | $1,800/month      | -67%    |
| ...       | ...         | ...               | ...     |

**Risk Assessment:**

| Technology | Risk Level | Risk Description        | Mitigation             |
| ---------- | ---------- | ----------------------- | ---------------------- |
| RabbitMQ   | 🟡 Medium  | Single point of failure | Cluster mode (3 nodes) |
| ...        | ...        | ...                     | ...                    |
```

**VÍ DỤ ĐÃ VIẾT TỐT:** Xem file `4.7.7.md` (đã tạo)

---

### 3.3 Section 4.12 - Traceability Matrix

**CÂU HỎI CẦN TRẢ LỜI:**

| #   | Câu hỏi                                    | Cách trả lời                                    | Ví dụ                                                                 |
| --- | ------------------------------------------ | ----------------------------------------------- | --------------------------------------------------------------------- |
| 1   | Mỗi FR map vào service nào?                | Bảng: FR → Service → Component                  | FR-COL-01 (Crawl TikTok) → Collection Service → TikTok Worker         |
| 2   | Mỗi NFR được đáp ứng như thế nào?          | Bảng: NFR → Decision → How Addressed → Evidence | NFR-P-01 (<500ms) → Microservices + Cache → 320ms (p99) - See 4.7.5.6 |
| 3   | Có requirement nào bị bỏ sót không?        | Gaps analysis                                   | 4 FRs partial, 0 missing → 92% coverage                               |
| 4   | Có component nào không map về requirement? | Backward trace                                  | Tất cả components đều trace về FRs                                    |

**QUAN TRỌNG:**

- **Forward Trace:** Requirement → Implementation
- **Backward Trace:** Implementation → Requirement
- **Gaps:** Những gì chưa done + mitigation plan

**TEMPLATE VIẾT:**

```markdown
### 4.12.2 Functional Requirements → System Components

| FR ID     | FR Description | Priority     | Use Case | Service        | Component   | Status   | Evidence              |
| --------- | -------------- | ------------ | -------- | -------------- | ----------- | -------- | --------------------- |
| FR-XXX-XX | [Description]  | High/Med/Low | UC-XX    | [Service name] | [Component] | ✅/⚠️/❌ | [Metrics/Section ref] |

**Summary:**

- ✅ Implemented: X/Total (%)
- ⚠️ Partial: X/Total (%)
- ❌ Not Started: X/Total (%)

### 4.12.3 Non-Functional Requirements → Architecture Decisions

| NFR ID    | NFR Description | Target   | Priority     | Decision  | How Addressed | Evidence  | Status |
| --------- | --------------- | -------- | ------------ | --------- | ------------- | --------- | ------ |
| NFR-XX-XX | [Description]   | [Target] | High/Med/Low | [ADR-XXX] | [Explanation] | [Metrics] | ✅/❌  |
```

**VÍ DỤ ĐÃ VIẾT TỐT:** Xem file `4.12.md` (đã tạo)

---

### 3.4 Section 4.13 - Gaps Analysis

**CÂU HỎI CẦN TRẢ LỜI:**

| #   | Câu hỏi                       | Cách trả lời                | Điểm cộng            |
| --- | ----------------------------- | --------------------------- | -------------------- |
| 1   | Những gì CHƯA hoàn thành?     | Technical gaps với priority | Có timeline cụ thể   |
| 2   | Những gì KHÔNG THỂ kiểm soát? | External limitations        | Có workaround + cost |
| 3   | Trade-offs nào là có chủ ý?   | Architectural trade-offs    | Có justification     |
| 4   | Lỗi nào đã biết?              | Known bugs với severity     | Có fix plan          |
| 5   | Bottlenecks nào đã xác định?  | Performance bottlenecks     | Có mitigation + ROI  |

**QUAN TRỌNG:**

- **Trung thực:** Không che giấu vấn đề
- **Phân loại rõ ràng:** Technical / External / By Design
- **Có kế hoạch:** Mỗi gap phải có mitigation plan
- **Có timeline:** Khi nào sẽ fix

**TEMPLATE VIẾT:**

```markdown
### 4.13.2 Technical Gaps

| Gap ID   | Feature | Description      | Impact      | Priority    | Mitigation | ETA    |
| -------- | ------- | ---------------- | ----------- | ----------- | ---------- | ------ |
| GAP-T-XX | [Name]  | [What's missing] | 🔴/🟠/🟡/🟢 | P0/P1/P2/P3 | [Plan]     | [Date] |

### 4.13.3 External Limitations

| Limit ID | Source     | Description             | Impact   | Workaround        | Status     |
| -------- | ---------- | ----------------------- | -------- | ----------------- | ---------- |
| LIM-E-XX | [Platform] | [What we can't control] | 🔴/🟠/🟡 | [How to mitigate] | ⚫ WONTFIX |

### 4.13.4 Architectural Trade-offs

| Trade-off | Decision        | Benefit    | Cost       | Acceptance           | Status       |
| --------- | --------------- | ---------- | ---------- | -------------------- | ------------ |
| TRD-A-XX  | [What we chose] | (+) [Pros] | (-) [Cons] | **Accepted** - [Why] | ✅ By design |

**Roadmap for Closing Gaps:**

- Q1 2025: [List of gaps to fix]
- Q2 2025: [List of gaps to fix]
- ...
```

**VÍ DỤ ĐÃ VIẾT TỐT:** Xem file `4.13.md` (đã tạo)

---

## 4. CHECKLIST HOÀN THÀNH

### 4.1 Checklist cho MỖI Section

Trước khi submit section, kiểm tra:

- [ ] **WHAT:** Đã mô tả rõ component/decision là gì?
- [ ] **WHY:** Đã giải thích lý do chọn cách này?
- [ ] **ALTERNATIVES:** Đã so sánh với các phương án khác?
- [ ] **TRADE-OFFS:** Đã nêu rõ ưu/nhược điểm?
- [ ] **EVIDENCE:** Đã có số liệu cụ thể hoặc link tham chiếu?
- [ ] **DIAGRAMS:** Có diagram minh họa (nếu cần)?
- [ ] **TABLES:** Có bảng tóm tắt dễ đọc?
- [ ] **SUMMARY:** Có phần tóm tắt key takeaways?

### 4.2 Checklist cho TOÀN BỘ Chương 4

**Phần A: Phân tích Yêu cầu**

- [ ] 4.1: User Stories với vai trò rõ ràng
- [ ] 4.2: Functional Requirements theo domain
- [ ] 4.3: Non-Functional Requirements với target metrics

**Phần B: Mô hình hóa Nghiệp vụ**

- [ ] 4.4: Danh sách Use Cases
- [ ] 4.5: Đặc tả chi tiết từng UC (Main/Alt/Exception flows)
- [ ] 4.6: Activity Diagrams cho các UC quan trọng

**Phần C: Thiết kế Kiến trúc**

- [x] 4.7.1: Giới thiệu & Nguyên tắc (✅ Done)
- [x] 4.7.2: Lựa chọn Architecture Style (✅ Done)
- [x] 4.7.3: Phân rã Hệ thống (✅ Done)
- [x] 4.7.4: System Context Diagram (✅ Done)
- [x] 4.7.5: Container Diagram (✅ Done)
- [x] 4.7.6: Component Diagrams (🆕 Template created)
- [x] 4.7.7: Technology Stack (🆕 Template created)
- [ ] 4.7.8: Communication Patterns (In 4.7.5 - có thể tách riêng)
- [ ] 4.7.9: Data Management (In 4.7.5 - có thể tách riêng)
- [ ] 4.7.10: Deployment Architecture (⚠️ Partial in 4.7.2.5)

**Phần D: Thiết kế Chi tiết**

- [ ] 4.8: Sequence Diagrams (⚠️ Images only)
- [ ] 4.9: Data Design / ERD (⚠️ Partial)
- [ ] 4.10: API Design (❌ Missing)
- [ ] 4.11: Cross-cutting Concerns (⚠️ Scattered)

**Phần E: Truy vết & Validation**

- [x] 4.12: Traceability Matrix (🆕 Template created)
- [x] 4.13: Gaps Analysis (🆕 Template created)

### 4.3 Checklist "Đủ Dẫn Chứng"

**ĐỂ ĐẠT 10/10, CẦN:**

- [x] Mọi FR có trace về Service/Component (92% - very good)
- [x] Mọi NFR có Architecture Decision đáp ứng (100% - perfect)
- [x] Mọi Architecture Decision có justification với alternatives (✅)
- [x] Có số liệu performance cụ thể (✅)
- [x] Có phân tích trade-offs trung thực (✅)
- [x] Có Traceability Matrix (🆕 added)
- [x] Có Gaps Analysis (🆕 added)
- [ ] Có Component Diagrams (C4 L3) (🆕 template ready - cần vẽ)
- [ ] Có Technology Stack tổng hợp (🆕 added)
- [ ] Có ERD/Data Design chi tiết (⚠️ needs work)

**HIỆN TẠI: 8.5/10** → Cần hoàn thiện:

1. Vẽ Component Diagrams (4.7.6)
2. Bổ sung ERD chi tiết (4.9)
3. Thêm Deployment Architecture chi tiết (4.7.10)

---

## 5. COMMON MISTAKES (Lỗi Thường Gặp)

### 5.1 Lỗi Về Nội dung

| Lỗi                          | Ví dụ Sai                    | Ví dụ Đúng                                                                                                                                |
| ---------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Mơ hồ, không cụ thể**      | "Hệ thống scale tốt"         | "Hệ thống scale từ 2→20 pods trong 2 phút khi tải tăng 10x"                                                                               |
| **Thiếu justification**      | "Chọn Golang"                | "Chọn Golang vì: (1) High concurrency, (2) Low memory, (3) Fast compilation. Compared to Node.js (single-threaded) and Java (heavy JVM)." |
| **Không có alternatives**    | "Dùng PostgreSQL"            | "Dùng PostgreSQL thay vì MySQL (no JSONB), Oracle (expensive), vì ACID + JSONB support"                                                   |
| **Thiếu evidence**           | "Performance tốt"            | "API response time: 320ms (p99) vs target 500ms. Source: 4.7.5.6"                                                                         |
| **Không trace requirements** | "Analytics Service xử lý AI" | "Analytics Service đáp ứng FR-AI-01 (Sentiment Analysis) và NFR-P-03 (650 posts/sec > target 500)"                                        |

### 5.2 Lỗi Về Trình bày

| Lỗi                          | Tại sao sai                    | Cách sửa                              |
| ---------------------------- | ------------------------------ | ------------------------------------- |
| **Tường thuật dài**          | Khó đọc, khó tìm thông tin     | Dùng bảng, bullet points, diagrams    |
| **Thiếu headings**           | Không biết section đang nói gì | Dùng headings rõ ràng: ### 4.7.X.Y    |
| **Không có summary**         | Không biết key takeaways       | Mỗi section có phần tóm tắt cuối      |
| **Thiếu cross-reference**    | Không trace được giữa các phần | Dùng links: "See 4.7.5.6 for metrics" |
| **Diagram không giải thích** | Diagram đẹp nhưng không hiểu   | Thêm đoạn giải thích bên dưới diagram |

### 5.3 Lỗi Về Logic

| Lỗi                    | Ví dụ                                                                        | Vấn đề                                      |
| ---------------------- | ---------------------------------------------------------------------------- | ------------------------------------------- |
| **Circular reasoning** | "Chọn Microservices vì cần scale. Cần scale vì chọn Microservices."          | Không giải thích được lý do gốc             |
| **Cherry-picking**     | Chỉ nói điểm mạnh, không nói trade-offs                                      | Thiếu trung thực                            |
| **Contradiction**      | "Microservices tốt cho performance" nhưng "Network latency cao hơn Monolith" | Mâu thuẫn nội bộ                            |
| **Missing causality**  | "Dùng Redis nên performance tốt"                                             | Không giải thích WHY Redis giúp performance |

---

## 6. TEMPLATES & EXAMPLES

### 6.1 Template: Architecture Decision Record (ADR)

```markdown
# ADR-XXX: [Tiêu đề Quyết định]

## Status: [Proposed | Accepted | Deprecated | Superseded]

## Context (Ngữ cảnh)

**Vấn đề:** [Vấn đề cần giải quyết]

**Ràng buộc:**

- [Ràng buộc 1: Technical/Business/Time]
- [Ràng buộc 2]

**Yêu cầu liên quan:**

- NFR-XX: [Requirement]
- FR-XX: [Requirement]

## Decision (Quyết định)

**Lựa chọn:** [Phương án được chọn]

**Lý do chính:**

1. [Lý do 1 với evidence]
2. [Lý do 2 với evidence]
3. [Lý do 3 với evidence]

## Alternatives Considered (Các phương án khác)

### Option A: [Phương án A]

**Pros:**

- (+) [Ưu điểm 1]
- (+) [Ưu điểm 2]

**Cons:**

- (-) [Nhược điểm 1]
- (-) [Nhược điểm 2]

**Why Rejected:** [Lý do loại]

### Option B: [Phương án B]

[Tương tự Option A]

## Consequences (Hệ quả)

**Positive:**

- (+) [Lợi ích 1 với số liệu]
- (+) [Lợi ích 2 với số liệu]

**Negative:**

- (-) [Trade-off 1 với mitigation]
- (-) [Trade-off 2 với mitigation]

**Risks:**

- [Risk 1]: Mitigation: [Cách giảm thiểu]
- [Risk 2]: Mitigation: [Cách giảm thiểu]

## Implementation Notes

- [Note 1: Cách triển khai cụ thể]
- [Note 2: Checklist]

## References

- [Link đến requirement]
- [Link đến section trong báo cáo]
- [External reference]
```

### 6.2 Template: Component Description

```markdown
### Component Name

**Responsibility:** [1 câu mô tả trách nhiệm chính]

**Technology:** [Language, Framework, Libraries]

**Interface:**

- **Input:** [Input type, source]
- **Output:** [Output type, destination]
- **API:** [REST/gRPC/Event-driven]

**Dependencies:**

- [Dependency 1]: [Why needed]
- [Dependency 2]: [Why needed]

**Performance:**
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Throughput | [Value] | [Target] | ✅/⚠️/❌ |
| Latency | [Value] | [Target] | ✅/⚠️/❌ |
| Memory | [Value] | [Target] | ✅/⚠️/❌ |

**Design Patterns:**

- [Pattern 1]: [How applied] → [Benefit]

**Error Handling:**

- [Error type 1]: [Strategy]
- [Error type 2]: [Strategy]

**Testing:**

- Unit tests: [Coverage %]
- Integration tests: [Description]
```

---

## 7. FINAL CHECKLIST BEFORE SUBMISSION

### 7.1 Content Checklist

- [ ] Mọi technical term đều được define (hoặc có trong Glossary)
- [ ] Mọi acronym được expand lần đầu tiên (e.g., "API (Application Programming Interface)")
- [ ] Mọi diagram đều có title, legend, và explanation
- [ ] Mọi bảng đều có header row và caption
- [ ] Mọi số liệu đều có unit (ms, MB, rps, etc.)
- [ ] Mọi claim đều có citation hoặc reference
- [ ] Không có "TODO" hay "[TBD]" trong final version
- [ ] Không có typos hoặc grammar errors

### 7.2 Structure Checklist

- [ ] File naming convention: `4.X.md` hoặc `4.X.Y.md`
- [ ] Section numbering nhất quán
- [ ] Cross-references đúng (không broken links)
- [ ] Table of Contents (nếu có) đã update
- [ ] Images lưu trong `images/` folder với tên rõ ràng
- [ ] Diagrams source (nếu có) lưu trong `diagrams/` folder

### 7.3 Quality Checklist

- [ ] Reviewer có thể hiểu mà không cần hỏi?
- [ ] Có đủ evidence để defend decisions?
- [ ] Có phân tích trade-offs trung thực?
- [ ] Có gaps analysis (không che giấu vấn đề)?
- [ ] Có thể trace từ requirement → implementation?
- [ ] Có thể trace từ implementation → requirement?

---

## 8. KẾT LUẬN

**3 NGUYÊN TẮC VÀNG:**

```
┌─────────────────────────────────────────────────────────────┐
│                  3 NGUYÊN TẮC VIẾT BÁO CÁO                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. BE SPECIFIC (Cụ thể)                                    │
│     • Số liệu, metrics, examples                           │
│     • Không mơ hồ, không "hand-waving"                     │
│                                                             │
│  2. BE HONEST (Trung thực)                                  │
│     • Nói rõ trade-offs                                    │
│     • Nhận diện gaps và limitations                        │
│     • So sánh alternatives một cách fair                   │
│                                                             │
│  3. BE TRACEABLE (Truy vết được)                            │
│     • Requirements → Decisions → Implementation            │
│     • Cross-reference giữa các sections                    │
│     • Evidence-based reasoning                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**NẾU LÀM ĐÚNG 3 ĐIỀU TRÊN** → Báo cáo sẽ **ĐỦ DẪN CHỨNG** và **CHẤT LƯỢNG CAO** ✅

---

**Good luck with your report! 🚀**

---

_File này được tạo bởi AI Assistant để hướng dẫn viết báo cáo đồ án chương 4._  
_Cập nhật lần cuối: 2025-12-20_
