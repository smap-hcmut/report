# NFR Groups Count for Radar Chart

## Data extracted from Chapter 4, Section 4.3

### Architecture Characteristics (7 ACs total)

**Primary ACs (4):**
- AC-1: **Modularity** (1)
- AC-2: **Scalability** (1)
- AC-3: **Performance** (1)
- AC-4: **Testability** (1)

**Secondary ACs (3):**
- AC-5: **Deployability** (1)
- AC-6: **Maintainability** (1)
- AC-7: **Observability** (1)

---

### Quality Attributes (Count by category)

#### 1. Performance (10 items)
**Response Time (4 items):**
1. API Endpoints: < 500ms (p95), < 1s (p99)
2. Dashboard Loading: < 3s initial load
3. WebSocket Updates: < 100ms (p95)
4. Report Generation: < 10 min

**Throughput (3 items):**
5. Crawling: Max rate-limit per platform, parallel crawling
6. Analytics Processing: ~70 items/min with 1 worker
7. WebSocket Connections: 1,000 concurrent connections

**Resource Utilization (3 items):**
8. CPU: < 60% normal load, < 90% hard load
9. Memory: < 1GB/service instance, < 2GB for NLP models
10. Network: < 50ms latency between services

---

#### 2. Scalability (1 item - from AC-2)
1. Scale 2-20 workers in < 5 min
   - 1,000 items/min with 10 workers
   - Handle multiple projects concurrently

---

#### 3. Security (7 items)
**Auth & Authorization (2 items):**
1. JWT with HttpOnly cookies, 2h/30d session timeout
2. Ownership verification, RBAC

**Data Protection (2 items):**
3. TLS 1.3, AES-256 at rest
4. Password: bcrypt min 8 chars, no plaintext

**Application Security (3 items):**
5. Input validation, sanitize, prevent SQL injection
6. CORS policy: production domains only
7. (Implied from CORS) Secure headers

---

#### 4. Compliance (4 items)
**Data Governance (2 items):**
1. Right to Access: Export in JSON/CSV/Excel
2. Right to Delete: Soft-delete 30-60 days, hard-delete, no PII > 60 days

**Platform Compliance (2 items):**
3. Respect rate limits, no captcha bypass
4. Follow platform ToS

---

#### 5. Usability (9 items)
**User Experience (6 items):**
1. Internationalization: VI/EN
2. Loading States: indicators, skeleton screens
3. Error Messages: clear, actionable, with codes
4. Confirmation Dialogs: for destructive actions, undo 30s
5. Progress Indicators: real-time %, time remaining, items processed
6. Onboarding: tutorials, tooltips

**Monitoring (3 items):**
7. Application Metrics: Prometheus, KPI dashboard
8. Log Levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
9. Log Format: JSON with timestamp, level, service, trace_id, message

---

#### 6. Maintainability (1 item - from AC-6)
1. Zero breaking changes when adding platforms
   - Plugin pattern architecture
   - 100% backward compatibility with API v1

---

#### 7. Deployability (1 item - from AC-5)
1. Deployment < 5 min, rollback < 5 min
   - Downtime < 30s with rolling deployment

---

#### 8. Testability (1 item - from AC-4)
1. Code coverage ≥ 80%
   - ≥ 100 unit tests/service
   - Test suite < 5 min

---

#### 9. Observability (1 item - from AC-7)
1. 100% errors logged
   - Metrics coverage for all critical paths
   - Alert response time < 5 min

---

#### 10. Reliability (0 explicit items)
*Note: Reliability is mentioned in the radar chart but no explicit requirements found in 4.3*
*It's implicitly covered by Availability (from AC-2 metrics)*

---

#### 11. Availability (0 explicit items in 4.3.2, but referenced from 4.3.1)
*Note: Availability was mentioned in original section_5_1.typ as "99.5% overall, 99.9% for Alert Service"*
*This is NOT explicitly stated in section 4.3 but appears to be a target from Chapter 4.1 or elsewhere*

---

## SUMMARY FOR RADAR CHART

Based on actual NFRs counted from Chapter 4, Section 4.3:

| Group | Count | Note |
|-------|-------|------|
| **Performance** | 10 | 4 Response Time + 3 Throughput + 3 Resource Utilization |
| **Scalability** | 1 | AC-2 (but critical, weighted heavily) |
| **Security** | 7 | 2 Auth + 2 Data Protection + 3 App Security |
| **Compliance** | 4 | 2 Data Governance + 2 Platform Compliance |
| **Usability** | 9 | 6 UX + 3 Monitoring |
| **Maintainability** | 1 | AC-6 (plugin pattern, zero breaking changes) |
| **Deployability** | 1 | AC-5 (< 5 min deploy/rollback) |
| **Testability** | 1 | AC-4 (≥ 80% coverage) |
| **Observability** | 1 | AC-7 (100% errors logged, alerts < 5 min) |
| **Reliability** | 0 | *Not explicitly defined in 4.3* |
| **Availability** | 0 | *Not explicitly defined in 4.3* |

**RECOMMENDED RADAR CHART (7 groups):**

For the radar chart mentioned in section_5_1.typ, use these 7 groups:

1. **Performance**: 10 NFRs
2. **Scalability**: 1 NFR (but critical)
3. **Security**: 7 NFRs
4. **Compliance**: 4 NFRs
5. **Usability**: 9 NFRs
6. **Maintainability**: 4 NFRs (AC-6 + AC-5 Deployability + AC-4 Testability + AC-7 Observability - group together as "Maintainability & Operations")
7. **Reliability**: 0 NFRs (can be removed or use Availability/Scalability as proxy)

**OR ALTERNATIVE (group differently):**

1. **Performance**: 10 NFRs
2. **Scalability**: 1 NFR
3. **Security**: 7 NFRs
4. **Compliance**: 4 NFRs
5. **Usability**: 9 NFRs
6. **Architecture Quality**: 4 NFRs (AC-6 Maintainability + AC-5 Deployability + AC-4 Testability + AC-7 Observability)
7. **Availability**: Use AC-2 Scalability as proxy (0 explicit, but implied)

---

## RECOMMENDATION

Update section 5.1.typ to say:

"Tổng quan NFR được phân loại thành **SÁU nhóm chính**: Performance (10 NFRs), Usability (9 NFRs), Security (7 NFRs), Compliance (4 NFRs), Architecture Quality/Maintainability (4 NFRs gồm Maintainability, Deployability, Testability, Observability), và Scalability (1 NFR quan trọng)."

Remove mention of "Reliability" and "Availability" as separate groups unless they have explicit requirements elsewhere in Chapter 4.

---

**Data for creating the radar chart:**

```json
{
  "groups": [
    {"name": "Performance", "count": 10},
    {"name": "Usability", "count": 9},
    {"name": "Security", "count": 7},
    {"name": "Compliance", "count": 4},
    {"name": "Architecture Quality", "count": 4},
    {"name": "Scalability", "count": 1}
  ]
}
```

Or if you want 7 groups (keeping original structure):

```json
{
  "groups": [
    {"name": "Performance", "count": 10},
    {"name": "Usability", "count": 9},
    {"name": "Security", "count": 7},
    {"name": "Compliance", "count": 4},
    {"name": "Maintainability", "count": 1},
    {"name": "Observability", "count": 1},
    {"name": "Scalability", "count": 1}
  ]
}
```

