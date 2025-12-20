## MODIFIED Requirements

### Requirement: Chapter 5 Documentation Structure

The system SHALL maintain a clean and organized documentation structure for Chapter 5 ("Thiết kế hệ thống") that supports efficient report writing and reduces maintenance overhead.

#### Scenario: Documentation files are organized by purpose
- **WHEN** a developer accesses the documents/chapter5/ folder
- **THEN** they see files organized by clear purpose: planning (MASTER_PLAN), guidance (WRITING-GUIDE), status (README), and reference data (NFR_GROUPS, RADAR_CHART)
- **AND** there are no outdated placeholder files or inconsistent naming patterns

#### Scenario: Documentation aligns with report structure  
- **WHEN** a writer works on report/chapter_5/ sections
- **THEN** they can easily find supporting documentation in documents/chapter5/
- **AND** the documentation structure supports rather than conflicts with the report organization

#### Scenario: Essential content is preserved
- **WHEN** outdated files are removed during cleanup
- **THEN** any valuable content is extracted and preserved in appropriate files
- **AND** no essential information for completing the chapter is lost

## REMOVED Requirements

### Requirement: Multiple File Formats for Same Content

**Reason**: Eliminates confusion from having both 4.5.x.md files and corresponding section_5_x.typ files

**Migration**: Content consolidated into authoritative .typ files in report/chapter_5/

### Requirement: Planning Artifact Persistence 

**Reason**: Planning artifacts served their purpose and create maintenance overhead

**Migration**: Essential guidance preserved in MASTER_PLAN and WRITING-GUIDE files