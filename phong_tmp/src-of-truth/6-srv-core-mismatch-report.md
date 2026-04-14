# SRV-Core Mismatch Report

Date: 2026-04-13
Scope: analysis-srv vs smap-analyse (core), plus domain context in project-srv

## Ket luan nhanh

analysis-srv chua match 100% voi core. Pipeline flow da align kha tot, nhung con mismatch o contract/topic artifact, ontology validator, va muc do enrichers.

Update note 2026-04-13:
- Report nay supersede cac gap cu trong `3-event-contracts.md`, `4-implementation-gap-checklist.md`, `5-rollout-order.md` neu cac gap do noi `analysis-srv` chua parse flat UAP hoac chua route theo `domain_type_code`.
- Current source da co ingest flat parsing va domain routing theo `domain_type_code`; gap con lai la hardening/parity voi core va outbound contracts.

## Findings (uu tien cao den thap)

1. P1 - Topic artifact contract chua parity voi core
- Core dung schema day du cho TopicArtifactFact, co nhieu truong quality/governance.
- analysis-srv dang dung ban rut gon (artifact_version khac va thieu nhieu field).
- References:
  - [smap-analyse/src/smap/enrichers/models.py](smap-analyse/src/smap/enrichers/models.py#L105)
  - [smap-analyse/src/smap/enrichers/models.py](smap-analyse/src/smap/enrichers/models.py#L132)
  - [analysis-srv/internal/enrichment/type.py](analysis-srv/internal/enrichment/type.py#L163)
  - [analysis-srv/internal/enrichment/type.py](analysis-srv/internal/enrichment/type.py#L190)

2. P1 - Ontology validator o srv khac core (thieu check core source channels)
- Core bat buoc ontology phai co day du source channels theo Platform enum.
- analysis-srv validator hien khong check missing core source channels.
- References:
  - [smap-analyse/src/smap/ontology/models.py](smap-analyse/src/smap/ontology/models.py#L22)
  - [smap-analyse/src/smap/ontology/models.py](smap-analyse/src/smap/ontology/models.py#L191)
  - [analysis-srv/internal/ontology/type.py](analysis-srv/internal/ontology/type.py#L357)

3. P2 - Mention model khac core, dan den mapping workaround trong enrichers
- Core MentionRecord co platform enum, keywords, reply_count.
- analysis-srv MentionRecord hien la platform string, khong co keywords/reply_count.
- Trong EnricherService da co workaround ro rang cho cac field nay.
- References:
  - [smap-analyse/src/smap/normalization/models.py](smap-analyse/src/smap/normalization/models.py#L15)
  - [smap-analyse/src/smap/normalization/models.py](smap-analyse/src/smap/normalization/models.py#L42)
  - [smap-analyse/src/smap/normalization/models.py](smap-analyse/src/smap/normalization/models.py#L65)
  - [analysis-srv/internal/normalization/type.py](analysis-srv/internal/normalization/type.py#L20)
  - [analysis-srv/internal/enrichment/usecase/build_enricher_service.py](analysis-srv/internal/enrichment/usecase/build_enricher_service.py#L11)

4. P2 - Semantic/Topic engine o srv dang la simplified, chua ngang core
- analysis-srv dung SimplifiedSemanticInferenceEnricher va SimplifiedTopicCandidateEnricher.
- Core co stack sau hon voi embedding/prototype/corroboration.
- References:
  - [analysis-srv/internal/enrichment/usecase/semantic_enricher.py](analysis-srv/internal/enrichment/usecase/semantic_enricher.py#L95)
  - [analysis-srv/internal/enrichment/usecase/topic_enricher.py](analysis-srv/internal/enrichment/usecase/topic_enricher.py#L275)
  - [smap-analyse/src/smap/enrichers/semantic.py](smap-analyse/src/smap/enrichers/semantic.py#L46)
  - [smap-analyse/src/smap/enrichers/topic.py](smap-analyse/src/smap/enrichers/topic.py#L40)

## Diem da align tot

1. Enricher orchestration flow giu dung thu tu va logic tong the nhu core.
- [analysis-srv/internal/enrichment/usecase/build_enricher_service.py](analysis-srv/internal/enrichment/usecase/build_enricher_service.py#L255)
- [smap-analyse/src/smap/enrichers/service.py](smap-analyse/src/smap/enrichers/service.py#L13)

2. Ingest flat parsing va domain routing theo domain_type_code da co.
- [analysis-srv/internal/consumer/server.py](analysis-srv/internal/consumer/server.py#L129)
- [analysis-srv/internal/consumer/server.py](analysis-srv/internal/consumer/server.py#L139)
- [analysis-srv/internal/model/uap.py](analysis-srv/internal/model/uap.py#L142)
- [analysis-srv/internal/model/uap.py](analysis-srv/internal/model/uap.py#L188)

3. O project-srv, project model da co DomainTypeCode de carry business context.
- [project-srv/internal/model/project.go](project-srv/internal/model/project.go#L54)

## Testing note

Khong chay duoc test trong analysis-srv do moi truong hien tai chua co pytest (No module named pytest).

## De xuat rollout fix (de giam risk)

1. Bo sung ontology source channel validation trong analysis-srv cho dong bo voi core.
2. Nang TopicArtifactFact contract cua analysis-srv len parity voi core (hoac co adapter contract ro rang truoc khi publish).
3. Bo sung/adapter MentionRecord fields (keywords, reply_count, platform enum semantics) de bo workaround.
4. Nang cap semantic/topic enrichers theo tung phase, giu backward compatibility o contract publisher.
