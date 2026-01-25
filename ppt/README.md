# PPT Folder

Folder này chứa tất cả tài liệu liên quan đến thuyết trình đồ án SMAP, bao gồm planning documents, actual slides, và evaluation.

## Structure

```
ppt/
  planning/                    # Planning documents
    presentation-plan.md       # Main presentation plan (active)
    presentation-script.md    # Detailed presentation script
    archive/                   # Old/outdated plans
      old-presentation-plan.md
  
  slides/                      # Actual presentation slides
    presentation.md           # Main Marp presentation file
    slide_01_title.md
    slide_02_summary.md
    ...
    slide_19_conclusion.md
  
  evaluation/                  # Evaluation and feedback
    evaluation.md             # Evaluation notes
  
  README.md                    # This file
```

## Categories

### Planning (`planning/`)

Planning documents để chuẩn bị và tổ chức thuyết trình:

- `presentation-plan.md` - Main presentation plan với timeline, slide breakdown, và speaking points
- `presentation-script.md` - Detailed script cho từng slide với văn nói chi tiết
- `archive/` - Old/outdated plans được lưu trữ để reference

**Usage**: Reference khi chuẩn bị và practice thuyết trình. Follow timeline và speaking points trong plan.

### Slides (`slides/`)

Actual presentation slides sử dụng Marp format:

- `presentation.md` - Main Marp file chứa toàn bộ slides
- `slide_*.md` - Individual slide files (reference cho planning)

**Naming Convention**: `slide_{number}_{topic}.md` (snake_case)
- Numbers: `01`, `02`, ..., `19`
- Special cases: `slide_07-5_component_diagram.md` (dash trong số cho sub-slide)

**Usage**: 
- Edit `presentation.md` để update slides
- Individual slide files là reference cho planning documents
- Generate PDF/HTML từ `presentation.md` bằng Marp CLI

### Evaluation (`evaluation/`)

Evaluation và feedback sau thuyết trình:

- `evaluation.md` - Evaluation notes và feedback

**Usage**: Lưu trữ feedback và notes để cải thiện cho lần sau.

## Naming Convention

- **Planning files**: `{topic}-{type}.md` (kebab-case, lowercase)
- **Slide files**: `slide_{number}_{topic}.md` (snake_case, consistent numbering)
- **Evaluation files**: `{topic}.md` (kebab-case, lowercase)

## Workflow

1. **Planning**: Sử dụng `planning/presentation-plan.md` để organize structure và timeline
2. **Scripting**: Viết detailed script trong `planning/presentation-script.md`
3. **Slides**: Tạo và edit slides trong `slides/presentation.md` (Marp format)
4. **Practice**: Follow plan và script để practice
5. **Evaluation**: Lưu feedback vào `evaluation/evaluation.md` sau thuyết trình

## Marp Usage

Slides sử dụng [Marp](https://marp.app/) format. Để generate presentation:

```bash
# Install Marp CLI
npm install -g @marp-team/marp-cli

# Generate PDF
marp slides/presentation.md --pdf

# Generate HTML
marp slides/presentation.md --html
```

## Relationship với Report

Slides reference images từ `report/images/`:

- Diagrams: `report/images/diagram/`, `report/images/architecture/`
- Data Flow: `report/images/data-flow/`
- Sequence Diagrams: `report/images/sequence/`
- Deployment: `report/images/deploy/`

## Maintenance

- Khi thêm slide mới, update `presentation-plan.md` với slide number và content
- Archive old plans vào `planning/archive/` thay vì xóa
- Giữ consistency trong slide numbering và naming
- Update README này nếu thêm category mới
