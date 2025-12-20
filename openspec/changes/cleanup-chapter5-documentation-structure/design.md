# Design: Chapter 5 Documentation Structure Cleanup

## Context

The documents/chapter5 folder contains 17 files with inconsistent structure and naming that don't align with the actual report structure in report/chapter_5/. This was identified through analysis of:

1. **Current report structure**: 6 .typ files in report/chapter_5/ following academic chapter organization
2. **Documentation files**: 17 .md files with various naming patterns and content quality
3. **User requirements**: Need for clean, academic-ready structure for "Thiết kế hệ thống" chapter

## Goals / Non-Goals

### Goals
- **Clean structure**: Remove inconsistent files and create unified organization
- **Academic alignment**: Match documentation structure to actual report files
- **Maintainability**: Reduce maintenance overhead from scattered files
- **Writer efficiency**: Provide clear guidance for completing the chapter

### Non-Goals
- **Content rewriting**: Not changing the actual report content in .typ files
- **New file creation**: Not adding new documentation files beyond necessary consolidation
- **Structure changes**: Not modifying the report/chapter_5/ structure itself

## Decisions

### Decision 1: Remove Outdated 4.5.x Files

**What**: Delete 7 files named 4.5.1.md through 4.5.7.md (4,944 total lines)

**Why**: 
- Naming inconsistency (4.5.x implies subsections of 4.5, but Chapter 5 is separate)
- Content is outdated compared to current section_5_1.typ (which has good 8 principles structure)
- Causes confusion about which is the authoritative source

**Alternatives considered**:
- **Rename to 5.x.md**: Rejected - still creates parallel structure to .typ files
- **Convert to reference**: Rejected - content largely superseded by current report

### Decision 2: Remove Planning Artifact Files

**What**: Delete 5 planning files (PLACEHOLDER_UPDATE_SUMMARY.md, CONTEXT_VERIFICATION_8_PRINCIPLES.md, etc.)

**Why**:
- These are planning artifacts, not reference content for writing
- Total 2,868 lines of temporary content that served its purpose
- Keeping them creates noise and confusion about what's currently relevant

**Alternatives considered**:
- **Archive folder**: Rejected - unnecessary complexity for temporary files
- **Keep for history**: Rejected - git history preserves this information

### Decision 3: Preserve Essential Files

**What**: Keep 5 essential files (CHAPTER5_MASTER_PLAN.md, WRITING-GUIDE.md, README-PLACEHOLDERS.md, NFR_GROUPS_COUNT.md, RADAR_CHART_DATA.md)

**Why**:
- MASTER_PLAN provides comprehensive implementation roadmap (807 lines)
- WRITING-GUIDE provides academic writing standards (633 lines)  
- NFR/RADAR files contain data referenced in actual report
- These support the report writing process rather than duplicating it

### Decision 4: Unified Reference Structure

**What**: Organize remaining files by purpose rather than section numbers

**Structure**:
```
documents/chapter5/
├── CHAPTER5_MASTER_PLAN.md      # Implementation roadmap
├── WRITING-GUIDE.md             # Academic writing guidance  
├── README-PLACEHOLDERS.md       # Status tracking
├── NFR_GROUPS_COUNT.md          # Reference data for section 5.1
└── RADAR_CHART_DATA.md          # Reference data for section 5.1
```

**Why**:
- Clear separation of purpose (planning vs reference vs guidance)
- No confusing parallel numbering to report sections
- Easy to understand what each file contributes

## Risks / Trade-offs

### Risk 1: Content Loss

**Risk**: Valuable content in 4.5.x files might be lost

**Mitigation**: 
- Manual review of each file before deletion (task 2.1-2.3)
- Extract any useful content not already covered in current report
- Git history preserves original content if needed later

### Risk 2: Workflow Disruption

**Risk**: Current writers might be using the 4.5.x files as reference

**Mitigation**:
- MASTER_PLAN provides comprehensive guidance for all sections
- WRITING-GUIDE provides templates and standards
- Cleanup improves rather than disrupts workflow by reducing confusion

## Migration Plan

### Phase 1: Content Review (1-2 hours)
1. Review each 4.5.x file for content not covered in current section_5_1.typ
2. Extract any valuable content for preservation
3. Confirm current report files are authoritative

### Phase 2: File Removal (30 minutes)  
1. Delete 12 identified files
2. Update README-PLACEHOLDERS.md to reflect new structure
3. Commit changes with clear description

### Phase 3: Validation (30 minutes)
1. Verify essential content preserved
2. Confirm remaining files provide clear guidance
3. Test workflow with simplified structure

## Open Questions

1. **Content extraction**: Should any specific content from 4.5.x files be extracted before deletion?
   - **Answer**: Task 2.1-2.3 will identify this during implementation

2. **Reference consolidation**: Should extracted content go in a new file or existing files?
   - **Answer**: Only create new file if substantial content (>200 lines) is extracted