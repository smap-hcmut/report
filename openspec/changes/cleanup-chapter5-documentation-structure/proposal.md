# Change: Clean up and consolidate Chapter 5 documentation structure

## Why

The documents/chapter5 folder currently contains 17 scattered markdown files with inconsistent naming (4.5.1.md, 4.5.2.md, etc.) and duplicated content that don't align with the actual report structure in report/chapter_5/. This creates confusion, maintenance overhead, and makes it difficult to write the "Thiết kế hệ thống" chapter effectively.

## What Changes

- **Remove outdated/inconsistent files**: Delete 12 placeholder and planning artifact files that are no longer needed
- **Consolidate reference content**: Merge useful content from 4.5.x.md files into unified reference documents
- **Create unified chapter outline**: Establish clear structure aligned with report/chapter_5/ files
- **Maintain only essential files**: Keep only CHAPTER5_MASTER_PLAN.md, WRITING-GUIDE.md, and new consolidated reference files

## Impact

- **Affected files**: 17 markdown files in documents/chapter5/
- **Affected code**: No code changes, only documentation reorganization
- **Benefits**: Cleaner structure, reduced confusion, easier maintenance, academic-ready documentation

## Files to be removed (12 files)

**Category 1: Outdated 4.5.x placeholders (7 files)**
- `4.5.1.md` - Outdated introduction content (1002 lines)
- `4.5.2.md` - Outdated architecture style selection (308 lines) 
- `4.5.3.md` - Outdated service decomposition (209 lines)
- `4.5.4.md` - Placeholder file (618 lines)
- `4.5.5.md` - Placeholder file (1306 lines)
- `4.5.6.md` - Placeholder file (446 lines)
- `4.5.7.md` - Placeholder file (233 lines)

**Category 2: Planning artifacts (5 files)**
- `PLACEHOLDER_UPDATE_SUMMARY.md` - Planning artifact (533 lines)
- `CONTEXT_VERIFICATION_8_PRINCIPLES.md` - Planning artifact (534 lines)
- `DESIGN_PRINCIPLES_VERIFICATION.md` - Planning artifact (828 lines)
- `REFACTOR_PLAN_5_1.md` - Planning artifact (572 lines)
- `SECTION_5_1_1_REFACTOR_PROPOSAL.md` - Planning artifact (401 lines)

## Files to be kept (5 files)

**Essential planning documents**
- `CHAPTER5_MASTER_PLAN.md` - Master implementation plan (807 lines)
- `WRITING-GUIDE.md` - Writing guidelines (633 lines)
- `README-PLACEHOLDERS.md` - Status tracking (372 lines)

**Reference data**
- `NFR_GROUPS_COUNT.md` - NFR categorization data (212 lines)
- `RADAR_CHART_DATA.md` - Chart data for section 5.1 (232 lines)