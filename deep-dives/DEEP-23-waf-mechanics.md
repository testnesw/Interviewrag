# DEEP MECHANICS · Well-Architected Framework (WAF)

> Level 2 — the 5 pillars, their tensions/trade-offs, and how to use WAF to
> critique a design.

---

## 0. The precise mental model
WAF = Microsoft's **5 pillars for assessing the technical quality of a workload**. It's a **lens for trade-offs**: you can't max all five, so good architecture is **deliberate balancing** (e.g., more reliability/security often costs performance/money). Interviewers use WAF as a checklist to see if you reason holistically.

---

## 1. The 5 pillars
1. **Reliability** — recover from failures, meet SLA (redundancy, multi-zone/region, DR, health checks, retries).
2. **Security** — protect data/systems (defense-in-depth, Zero Trust, least privilege, encryption, private networking).
3. **Cost Optimization** — value per dollar (right-size, commitments, autoscale, tiering).
4. **Operational Excellence** — run & improve (IaC, CI/CD, monitoring, automation, runbooks).
5. **Performance Efficiency** — scale to meet demand (right resources, caching, async, autoscale).

## 2. The tensions (the real insight)
- **Reliability vs Cost** — multi-region HA costs more.
- **Security vs Performance/Usability** — inspection/encryption add latency.
- **Cost vs Performance** — cheaper SKUs are slower.
- Good design states which pillar it **prioritizes** for the business context and what it trades.

## 3. Using WAF to critique
For any design, ask per pillar: single points of failure? (Reliability) least privilege + private endpoints? (Security) right-sized + committed? (Cost) IaC + observability? (OpEx) autoscale + caching? (Performance). This structured critique is what "think like an architect" means.

## 4. Supporting elements
- **Design principles + checklists** per pillar.
- **Azure Advisor** + **WAF review** tooling score a workload.
- Applies **per workload** (vs CAF org-wide).

## 5. The hard follow-ups (with answers)
1. **"Name the 5 pillars."** → Reliability, Security, Cost, Operational Excellence, Performance Efficiency. (§1)
2. **"Can you maximize all five?"** → no — they trade off; prioritize per business context. (§2)
3. **"Reliability vs cost example?"** → multi-region active-active raises cost; choose per RTO/RPO + budget. (§2)
4. **"How do you use WAF in a review?"** → walk each pillar for SPOFs, least privilege, right-sizing, IaC/monitoring, scaling. (§3)

## 6. One-screen recall
- **WAF = 5 pillars for workload quality**: **Reliability, Security, Cost, Operational Excellence, Performance Efficiency**.
- Core insight: **can't max all** → deliberate **trade-offs** (Reliability↔Cost, Security↔Performance).
- Use as a **critique lens** per pillar (SPOF? least privilege? right-size? IaC/monitor? autoscale/cache?).
- Per-workload (CAF = org-wide); scored via Advisor/WAF review.

> Next: Azure Landing Zones.
