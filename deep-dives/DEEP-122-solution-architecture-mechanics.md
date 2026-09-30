# DEEP MECHANICS · Solution Architecture

> Level 2 — the architect role, requirements → design, trade-off analysis,
> quality attributes, and documentation.

---

## 0. The precise mental model
Solution architecture is the discipline of **translating business requirements into a technical design** that satisfies **quality attributes** (the "-ilities") within **constraints** (budget, time, skills, compliance). The core skill is **trade-off analysis** — there is no perfect design, only the best-balanced one for *this* context. Architecture = the **hard-to-change decisions** made early.

---

## 1. The architect's job
- Bridge **business ↔ technology**; own the **significant decisions** + their rationale.
- Define structure, boundaries, integration, cross-cutting concerns (security, observability, resilience).
- Balance stakeholders; communicate the design; govern its implementation.

## 2. Requirements → drivers
- **Functional requirements** (what it does) → components/features.
- **Non-functional requirements (NFRs / quality attributes)** → shape the architecture the most: performance, scalability, availability, security, maintainability, cost.
- **Constraints** (budget, deadlines, existing tech, compliance, team skills) + **assumptions** + **risks**.

## 3. Quality attributes (the "-ilities")
- **Scalability, Availability, Performance, Security, Reliability/Resilience, Maintainability, Observability, Cost, Portability**.
- They **conflict** (e.g., strong consistency vs availability — CAP; security vs usability; cost vs redundancy) → prioritize per business need.

## 4. Trade-off analysis (the core skill)
- Every decision has costs: **CAP** (consistency vs availability), **build vs buy**, **monolith vs microservices**, **sync vs async**, **SQL vs NoSQL**, **managed vs self-hosted**.
- Make trade-offs **explicit** with rationale; use structured methods (e.g., **ATAM**) for big decisions.
- Record **why** (not just what) → **Architecture Decision Records (ADR)**.

## 5. Frameworks & references
- **Azure Well-Architected Framework** (5 pillars: Reliability, Security, Cost, Operational Excellence, Performance Efficiency) as a scorecard.
- **Cloud Adoption Framework**, reference architectures, design patterns (retry, circuit breaker, CQRS, saga, cache-aside).

## 6. Documentation & communication
- **C4 model** (Context → Container → Component → Code) for leveled diagrams.
- **ADRs** for decisions; NFR/SLA docs; threat models; cost models.
- **Fitness functions** to continuously verify architecture holds.

## 7. Solution vs enterprise vs technical architect
- **Enterprise** — org-wide strategy/standards. **Solution** — a specific solution/project across systems. **Technical/application** — deep within one system/stack.

## 8. The hard follow-ups (with answers)
1. **"What's the architect's core skill?"** → **trade-off analysis** — balancing conflicting quality attributes within constraints. (§4)
2. **"What shapes an architecture most?"** → **NFRs/quality attributes** + constraints, not just features. (§2)
3. **"How do you evaluate a design?"** → against quality attributes + **Well-Architected pillars**; structured (ATAM). (§3/§5)
4. **"Capture a big decision?"** → **ADR** (decision + context + rationale + alternatives). (§4/§6)
5. **"Communicate architecture?"** → **C4 model** leveled diagrams + docs. (§6)
6. **"Classic trade-off example?"** → **CAP** (consistency vs availability); monolith vs microservices. (§4)
7. **"Solution vs enterprise architect?"** → solution = one solution across systems; enterprise = org-wide strategy. (§7)

## 9. One-screen recall
- **Requirements → design** meeting **quality attributes** within **constraints**; own the hard-to-change decisions.
- **Drivers**: functional + **NFRs** + constraints/assumptions/risks.
- **-ilities** conflict → **prioritize + trade off explicitly** (CAP, build/buy, mono/micro, sync/async).
- **Frameworks**: **Well-Architected** (5 pillars), CAF, patterns.
- **Document**: **C4** diagrams + **ADRs** + fitness functions.
- **Roles**: enterprise (org) / **solution** (project) / technical (system).

> Next: Domain-Driven Design.
