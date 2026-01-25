# Documents Folder

Folder này là **workspace** để viết và chuẩn bị content trước khi đưa vào `report/`. Chứa guides, references, planning documents, drafts, và verification reports.

## Structure

```
documents/
  guides/              # Writing guides, format guides, templates
  references/          # Reference data, indexes, charts data
  planning/           # Planning documents, master plans
    section-plans/    # Section-specific plans
  drafts/             # Draft content chưa integrate
    chapter4/
      section-4-5-drafts/
  verification/       # Verification và evaluation reports
    section-evaluations/
  archive/            # Files đã integrate hoặc không còn dùng
    refactor-reports/
  README.md           # This file
```

## Categories

### Guides (`guides/`)

Writing guides, format guides, và templates để hỗ trợ viết report:

- `writing-guide.md` - Hướng dẫn viết báo cáo đồ án (Chapter 4 & 5)
- `nfr-format-guide.md` - Format guide cho Non-Functional Requirements
- `erd-diagram-guide.md` - Hướng dẫn vẽ ERD diagrams
- `puml-rules.md` - Rules và conventions cho PlantUML diagrams

**Usage**: Reference khi viết các sections trong report để đảm bảo format và quality.

### References (`references/`)

Reference data, indexes, và chart data được sử dụng trong report:

- `chapter4-index.md` - Index của Chapter 4 stable content
- `nfr-groups-count.md` - NFR categorization data (35 NFRs → 6 groups)
- `radar-chart-data.md` - Chart data cho section 5.1 NFR radar chart
- `comprehensive-erd.md` - ERD reference cho tất cả services
- `erd-analytics-service.md` - ERD cho Analytics Service
- `erd-identity-service.md` - ERD cho Identity Service
- `erd-project-service.md` - ERD cho Project Service

**Usage**: Reference data khi viết report sections, đặc biệt cho charts và tables.

### Planning (`planning/`)

Planning documents và master plans cho các chapters:

- `chapter5-master-plan.md` - Master plan 14-day roadmap cho Chapter 5
- `chapter6-implementation-plan.md` - Implementation plan cho Chapter 6
- `chapter7-deployment-plan.md` - Deployment plan cho Chapter 7
- `section-plans/` - Section-specific plans
  - `section-5-3-plan.md`
  - `section-5-4-plan.md`
  - `section-5-6-plan.md`
  - `section-5-7-plan.md`
  - etc.

**Usage**: Reference khi implement các sections trong report, theo roadmap và task breakdown.

### Drafts (`drafts/`)

Draft content chưa được integrate vào report:

- `chapter4/section-4-5-drafts/` - Draft content cho section 4.5
  - `4-5-1.md`, `4-5-2.md`, ..., `4-5-7.md`

**Usage**: Workspace để viết draft content trước khi integrate vào report. Có thể archive sau khi đã integrate.

### Verification (`verification/`)

Verification và evaluation reports:

- `sequence-diagrams-verification.md` - Verification report cho sequence diagrams
- `sequence-diagrams-evaluation.md` - Evaluation report cho sequence diagrams
- `erd-verification-report.md` - ERD verification report
- `section-evaluations/` - Section-specific evaluations
  - `section-5-2-evaluation.md`
  - `section-5-2-diagram-evaluation.md`
  - `section-5-3-analysis.md`
  - `section-5-3-diagram-recommendation.md`
  - `section-5-3-fix-recommendation.md`
  - `section-5-6-review.md`

**Usage**: Bằng chứng của quá trình review và verification. Có giá trị lịch sử.

### Archive (`archive/`)

Files đã integrate hoặc không còn dùng:

- `sequence-diagrams-doc.md` - Sequence diagrams documentation (có thể duplicate)
- `status-tracking.md` - Status tracking (outdated)
- `collector-mongodb-confirmation.md` - Confirmation notes (đã xác nhận xong)
- `refactor-reports/` - Refactor reports
  - `refactor-final-report.md`
  - `refactor-report-5-2-5-3-5-4.md`
- `section-5-3-2-simplified-example.typ` - Example file (.typ)

**Usage**: Lưu trữ các file không còn active nhưng có giá trị reference.

## Naming Convention

Tất cả files sử dụng **kebab-case**, lowercase:

- Guides: `{topic}-guide.md` hoặc `{topic}-rules.md`
- References: `{topic}-{type}.md` (index, data, chart, etc.)
- Planning: `{chapter}-{type}-plan.md` hoặc `section-{number}-plan.md`
- Verification: `{topic}-verification.md` hoặc `{topic}-evaluation.md`
- Drafts: `{section-number}.md` (giữ format số để dễ reference)

## Workflow

1. **Writing**: Sử dụng guides và references khi viết content
2. **Planning**: Follow planning documents để implement sections
3. **Drafting**: Viết draft trong `drafts/` trước khi integrate vào report
4. **Verification**: Review và evaluation được lưu trong `verification/`
5. **Archive**: Move files đã integrate hoặc không còn dùng vào `archive/`

## Relationship với Report

```
documents/                    report/
  guides/              ────►  (writing standards)
  references/          ────►  (data for charts/tables)
  planning/            ────►  (implementation roadmap)
  drafts/              ────►  chapter_*/section_*.typ
  verification/        ────►  (quality assurance)
```

## Maintenance

- Khi thêm file mới, đảm bảo đặt vào đúng category folder
- Update README này nếu thêm category mới
- Archive các file đã không còn dùng thay vì xóa
- Giữ consistency trong naming và structure
