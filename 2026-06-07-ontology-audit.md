# SMAP Ontology Coverage Audit — 2026-06-07

## Summary

**Verdict:** Good for VinFast + logistics. **Insufficient** for general social
media coverage. Only 11 core entities (all VinFast), thin entertainment domain,
missing major verticals (e-commerce, fintech, food & beverage).

---

## Current State

### Domains (7)

| Domain                    | Ontology File                | Lines | Depth                                             |
| ------------------------- | ---------------------------- | ----- | ------------------------------------------------- |
| VinFast Automotive        | `vinfast_vn.yaml`            | 889   | Deep — entities, aspects, intents, issues, topics |
| Logistics                 | `logistics_vn.yaml`          | 830   | Deep — shared by Ahamove + Grab                   |
| HRM / CRM                 | `hrm_crm_vn.yaml`            | ~200  | Shallow — activation signals only                 |
| Marketing Campaign        | `marketing_campaign_vn.yaml` | ~150  | Shallow — Kotex demo overlay                      |
| Entertainment / Celebrity | `entertainment_vn.yaml`      | 114   | Skeleton — aspects + crisis signals only          |
| Default (fallback)        | → vinfast_vn.yaml            | —     | Reuses VinFast ontology                           |
| Tanca                     | → hrm_crm_vn.yaml            | —     | Reuses HRM ontology                               |
| Kotex Good Night          | → marketing_campaign_vn.yaml | —     | Reuses marketing ontology                         |

### Core Entities (`entities.yaml`): 11 total

All VinFast-related:

- 1 brand: VinFast
- 1 product line: VF Series
- 7 models: VF3, VF5, VF6, VF7, VF8, VF9, VFe34
- 1 service: GSM / Xanh SM
- 1 person: Phạm Nhật Vượng

### Taxonomy: 28 nodes

```
automotive (root)
├── electric_vehicle → mini_car, mini_suv, compact_suv, mid_suv, full_suv, large_suv, sedan_suv
├── ride_hailing
├── vietnam_brand
├── car_review
└── car_ownership
technology (root) → battery_tech, charging_infra, autonomous_driving
business (root) → business_leader, market_expansion
lifestyle (root) → green_living, community
```

### Source Channels: 6

TikTok, Facebook, YouTube, Instagram (active/true), Twitter, Web (Twitter marked inactive)

---

## Strengths

1. **VinFast domain is production-grade** — 17 aspect categories with dual Vietnamese/accentless seed phrases, 9 intent categories, 14 issue categories with cross-links to aspects, 10 topics with seed phrases and negative filters
2. **Logistics domain is comprehensive** — 10 aspects (delivery speed, fee, driver quality, package safety, order accuracy, app, payment, support, promotions, coverage), 14 issues, 7 intents, 8 topics
3. **Vietnamese-first design** — seed phrases in both accented and non-accented Vietnamese
4. **Well-structured schema** — entity*types, taxonomy_nodes, aspect_categories, intent_categories, issue_categories, topics all interconnected with related*\* cross-references
5. **Quality gates** — per-domain `min_relevance_score` and `spam_regex` (entertainment uses 0.25, fallback uses 0.30)
6. **Domain activation signals** — each domain has weighted phrase signals for auto-detection
7. **Noise terms** — explicit suppression list (haha, hehe, kk, lol, etc.)

---

## Critical Gaps

### 1. No Entities Outside VinFast (P0)

The logistics ontology defines entities for Ahamove and Grab products (brand.ahamove,
product.ahamove_delivery, product.ahamove_truck, product.ahamart, brand.grab,
product.grab_express, product.grab_food), but the **core entities.yaml only has
VinFast entries**. Each domain's entities are siloed — there's no cross-domain
entity registry.

### 2. Zero Competitor Entities (P0)

No competing brands tracked:

- **Automotive:** Tesla, Hyundai, BYD, Toyota, Mercedes, Honda, Mitsubishi, Ford
- **Logistics:** Be, Gojek, Loship, Ninja Van, GHN, GHTK, Viettel Post, J&T
- **HRM:** Base.vn, MISA, Bravo, 1Office
- **Food delivery:** ShopeeFood, Baemin

### 3. Entertainment Domain is Skeleton (P1)

Only 114 lines — basically a crisis signal detector:

- 5 aspects (hình tượng, đạo đức, pháp lý, trách nhiệm, âm nhạc)
- No entities (celebrities, artists, KOLs)
- No issues or topics — just crisis signal patterns
- Only 1 brand_name: "Long Nhật"

### 4. Missing Major Social Media Verticals (P1)

No coverage for:

- **E-commerce:** Shopee, Lazada, Tiki, TikTok Shop
- **Fintech / Banking:** Momo, ZaloPay, VNPay, banks
- **Food & Beverage:** Highlands, Phúc Long, The Coffee House
- **Travel & Hospitality:** VN Airlines, VietJet, Bamboo, Vinpearl
- **Education:** VUS, ILA, Apollo, RMIT, FPT University
- **Healthcare / Pharma:** Pharmacity, Long Châu, hospitals
- **Real Estate:** Vinhomes, Novaland, Sun Group, Ecopark
- **Gaming:** VNG, Garena, Liên Quân Mobile, Free Fire
- **Telecom:** Viettel, Mobifone, Vinaphone

### 5. Taxonomy is Automotive-Centric (P1)

28 nodes, 18 are automotive-related. Missing major categories:

- e_commerce, fintech, food_beverage, travel, education, healthcare, real_estate,
  gaming, telecom, government, sports, fashion, beauty, home_appliances

### 6. No Person Entities Beyond Phạm Nhật Vượng (P2)

Missing key opinion leaders, CEOs, and public figures for each domain.

### 7. Marketing Campaign Domain is Minimal (P2)

~150 lines, only has Kotex/Anh Trai Good Night demo overlay. No reusable
campaign measurement framework.

---

## Coverage Score by Vertical

| Vertical        | Entities | Aspects | Topics | Issues | Intents | Score  |
| --------------- | -------- | ------- | ------ | ------ | ------- | ------ |
| Automotive (EV) | ✅ Deep  | ✅ 17   | ✅ 10  | ✅ 14  | ✅ 9    | **A**  |
| Logistics       | ✅ 9     | ✅ 10   | ✅ 8   | ✅ 14  | ✅ 7    | **A-** |
| HRM / CRM       | ❌ 0     | ❌ 0    | ❌ 0   | ❌ 0   | ❌ 0    | **D**  |
| Marketing       | ❌ 0     | ❌ 0    | ❌ 0   | ❌ 0   | ❌ 0    | **D**  |
| Entertainment   | ❌ 0     | ⚠️ 5    | ❌ 0   | ❌ 0   | ❌ 0    | **D-** |
| E-commerce      | ❌       | ❌      | ❌     | ❌     | ❌      | **F**  |
| Fintech         | ❌       | ❌      | ❌     | ❌     | ❌      | **F**  |
| Food & Beverage | ❌       | ❌      | ❌     | ❌     | ❌      | **F**  |
| Travel          | ❌       | ❌      | ❌     | ❌     | ❌      | **F**  |
| Education       | ❌       | ❌      | ❌     | ❌     | ❌      | **F**  |

---

## Recommendations

| Priority | Action                                                | Effort | Impact                                |
| -------- | ----------------------------------------------------- | ------ | ------------------------------------- |
| **P0**   | Add competitor entities to VinFast domain             | 2h     | Enables competitive intelligence      |
| **P0**   | Populate entities.yaml with logistics entities        | 1h     | Entities visible across all domains   |
| **P1**   | Build out entertainment domain (entities, topics)     | 4h     | Essential for VN social media         |
| **P1**   | Add e-commerce + fintech taxonomy nodes               | 2h     | Covers 60%+ of VN social conversation |
| **P1**   | Expand taxonomy: food, travel, education, real estate | 3h     | Broadens domain activation            |
| **P2**   | Add person entities for key figures                   | 2h     | KOL/influencer tracking               |
| **P2**   | Complete HRM/CRM domain (competitors, topics)         | 3h     | Makes Tanca monitoring useful         |
| **P2**   | Build reusable campaign measurement framework         | 4h     | Applies to any campaign domain        |
| **P3**   | Add FMCG/Beauty vertical                              | 2h     | Kotex, Unilever, P&G coverage         |
| **P3**   | Add noise terms for each domain                       | 1h     | Better signal-to-noise ratio          |

**Total estimated effort:** ~24 hours for P0-P2 items

---

## Verdict

Ontology is **production-ready for VinFast + logistics monitoring**. For a
general-purpose social media analytics platform, coverage is **insufficient** —
missing e-commerce, fintech, food & beverage, travel, and entertainment verticals
that drive the majority of Vietnamese social media conversation.

The schema is well-designed and extensible — the foundation is solid. The gap
is in **breadth**, not structure. Adding 3-4 new domain ontologies and
cross-domain entities would bring coverage to ~80% of Vietnamese social media
conversation volume.
