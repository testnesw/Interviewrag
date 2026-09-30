# 122 · Solution Architecture

> Domain: Architecture Patterns · Level: Principal Solution Architect

## 1. Beginner Explanation
Solution Architecture is **designing the technical solution for a specific business problem or project** — choosing the components, technologies, and how they fit together to meet requirements like performance, security, and cost, within the organization's standards.

## 2. Architect-Level Explanation
Translating business requirements into a concrete, buildable technical design for a specific system:
- **Scope**: project/system-level (vs enterprise-wide EA) — bridges business needs and engineering implementation.
- **Requirements**: functional + **non-functional (NFRs / "-ilities")** — scalability, availability, security, performance, maintainability, cost, compliance — the true architecture drivers.
- **Activities**: requirement analysis, technology selection, component + integration design, data flow, trade-off analysis, risk assessment, PoCs, cost estimation, and producing the design (diagrams, decisions).
- **Well-Architected pillars**: Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency — evaluate the design against each.
- **Artifacts**: solution design docs, C4/architecture diagrams, **Architecture Decision Records (ADRs)**, sequence/data-flow diagrams, threat models.
- **Trade-offs**: every decision balances competing forces (cost vs performance vs complexity vs time) — articulating them is the core skill.
- **Patterns**: applies proven patterns (microservices, event-driven, CQRS, caching, resilience — retry/circuit breaker/bulkhead) appropriately, not dogmatically.
- **Governance fit**: designs within EA guardrails/landing zones + standards.
- **Delivery**: works with teams through build, guiding implementation + evolving the design.

## 3. Real Enterprise Use Case
For a new customer portal, the solution architect gathers functional + NFRs (100k users, 99.9% SLA, PCI, low latency), selects Azure services (App Service/AKS, Azure SQL + Redis cache, Front Door + APIM, Entra ID), designs the integration + data flows, evaluates against **Well-Architected** pillars, documents key choices as **ADRs** (e.g., "why AKS over App Service"), threat-models, estimates cost, runs a PoC for the risky part, and guides the team through delivery within EA landing-zone guardrails.

## 4. Architecture Diagram (ASCII)
```
   Business problem + Requirements (functional + NFRs/-ilities)
        ▼
   Solution Architecture
   ┌──── Technology selection ──── Component + integration design ────┐
   │ data flows · patterns (event-driven/CQRS/cache/resilience)       │
   │ trade-off analysis · risk · PoC · cost estimate                  │
   └──────────────────────────────────────────────────────────────────┘
   Evaluate vs Well-Architected (Reliability/Security/Cost/OpEx/Perf)
   Artifacts: design doc · C4 diagrams · ADRs · threat model
   Within EA guardrails/landing zones ─► guide delivery
```

## 5. Interview Questions
1. What is solution architecture vs enterprise architecture?
2. What are NFRs and why do they drive architecture?
3. How do you evaluate a design (Well-Architected)?
4. What is an ADR and why document decisions?
5. How do you approach trade-offs and technology selection?

## 6. Strong Interview Answers
- **Solution vs EA**: "Solution architecture designs the technical solution for a **specific** problem/project — components, technologies, integration — bridging business requirements and engineering. EA is enterprise-wide and strategic. I design solutions **within** EA's guardrails, standards, and landing zones."
- **NFRs**: "**Non-functional requirements** — scalability, availability, security, performance, maintainability, cost, compliance — are the real architecture drivers. Two systems with identical features but different NFRs (99% vs 99.99% availability, 100 vs 100M users) need completely different architectures. I elicit and quantify NFRs early because they shape every decision."
- **Evaluate**: "I assess designs against the **Well-Architected Framework** — Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency — checking each pillar and the trade-offs between them. A Well-Architected Review surfaces gaps (no DR, weak identity, cost risks) before build."
- **ADR**: "An **Architecture Decision Record** captures a significant decision — context, options considered, the choice, and consequences. It preserves *why* (not just what), so future teams understand rationale, avoid re-litigating, and can revisit when context changes. Lightweight, versioned with the code."
- **Trade-offs/selection**: "Every choice balances competing forces — cost, performance, complexity, time-to-market, team skills, lock-in. I select technology by fit to requirements and constraints (not hype), prototype the risky parts, and explicitly document the trade-offs. 'It depends' — but I make the dependencies explicit and defensible."

## 7. Common Mistakes
- Designing for functional requirements only, ignoring NFRs.
- Technology chosen by hype/resume, not fit.
- No trade-off articulation / no ADRs (lost rationale).
- Over-engineering (gold-plating) or under-engineering for the actual NFRs.
- Ignoring EA standards/guardrails → non-compliant designs.

## 8. Trade-offs
| Tension | Example |
|---------|---------|
| Cost vs performance | cache/scale up = faster, pricier |
| Simplicity vs flexibility | monolith vs microservices |
| Build vs buy | control vs speed/cost |

## 9. Production Best Practices
- Elicit + quantify NFRs first; design to them (not over/under).
- Evaluate with Well-Architected; threat-model; estimate cost.
- Document decisions as **ADRs**; use C4 diagrams for clarity.
- PoC risky/unknown parts before committing.
- Design within EA guardrails; stay engaged through delivery + evolve.

## 10. Security Considerations
- Security as a first-class NFR: threat modeling, Zero Trust, least privilege.
- Identity (Entra ID/Managed Identity), encryption, secrets (Key Vault), network isolation by design.
- Compliance requirements (PCI/GDPR/HIPAA) shaping the architecture.
- Defense in depth; secure-by-default patterns.

## 11. Cost Optimization
- Cost as an explicit NFR + Well-Architected pillar; estimate up front.
- Right patterns (serverless/managed/caching) for cost-efficiency.
- Avoid over-engineering; align spend to required NFRs + business value.

## 12. Troubleshooting Scenarios
- **System fails under load** → NFRs (scalability) not designed for; re-architect for scale.
- **Design decisions re-litigated** → no ADRs; document rationale.
- **Over-budget** → no cost estimate/pillar; add cost analysis + right-size patterns.
- **Security gaps found late** → no threat model; shift-left security in design.
- **Doesn't fit standards** → ignored EA guardrails; align to landing zones/catalog.

## 13. Hands-on Example
```markdown
# ADR-014: Use AKS over App Service for the portal backend
Context: 100k users, need fine-grained scaling, service mesh, multi-service topology.
Decision: AKS (managed K8s) with KEDA autoscaling.
Consequences: + flexibility/scale/portability; − higher operational complexity.
Alternatives: App Service (simpler, less control), Container Apps (middle ground).
```

## 14. Terraform Example
```hcl
# Solution architecture realized as IaC within EA guardrails (tags, landing zone)
module "portal" {
  source = "./modules/web-solution"
  region = "eastus"
  compute = "aks"            # decision from ADR-014
  cache   = "redis-premium"  # NFR: low latency
  db      = "azuresql-bc-zr" # NFR: 99.99% + zone redundancy
  tags    = { costCenter = "portal", tier = "prod" }   # EA standards
}
```

## 15. Azure Example
The solution architect runs an **Azure Well-Architected Review** for the workload, maps each requirement to Azure services (Front Door + APIM + AKS + Azure SQL + Redis + Entra ID), uses the **Pricing Calculator** for cost, and validates against **CAF landing-zone** guardrails before build.

## 16. FastAPI / Python Example
```python
# Architecture drivers (NFRs) expressed as measurable SLOs the design must meet
SLOs = {
    "availability": 0.999,        # reliability NFR
    "p99_latency_ms": 300,        # performance NFR
    "max_cost_monthly": 25000,    # cost NFR
}
# Every component choice (cache, replicas, DB tier) is justified against these SLOs
```

## 17. AKS Example
Designing an AKS-based solution, the architect specifies: node pools + KEDA/HPA (scalability NFR), zone redundancy + PodDisruptionBudgets (availability), Workload Identity + network policy + private cluster (security), Container Insights/OTel (operability), and Spot + right-sizing (cost) — each mapped to an NFR and captured in ADRs, within the EA AKS reference architecture.

## 18. How to Remember
**"Design the solution for one problem, driven by NFRs (-ilities); select tech by fit; evaluate vs Well-Architected 5 pillars; document trade-offs as ADRs; PoC risks; build within EA guardrails."**

## 19. Real-World Analogy
An architect designing a specific building: they take the client's needs (offices for 500 people, earthquake-safe, on budget = NFRs), choose materials and structure that fit (technology selection), balance cost vs strength vs aesthetics (trade-offs), record why key choices were made (ADRs), and follow the city's building codes (EA guardrails) — producing blueprints the construction crew builds from.

## 20. One-Page Cheat Sheet
- **What**: design the technical solution for a **specific** problem/project (bridges business ↔ engineering).
- **Drivers**: functional + **NFRs / -ilities** (scalability, availability, security, performance, cost, compliance) — quantify early.
- **Evaluate**: **Well-Architected** 5 pillars (Reliability, Security, Cost, OpEx, Performance).
- **Artifacts**: design doc, **C4 diagrams**, **ADRs** (decision + rationale + consequences), threat model, cost estimate.
- **Method**: select tech by fit, articulate **trade-offs**, PoC risks, apply patterns pragmatically.
- **Fit**: design within EA guardrails/landing zones; guide delivery + evolve. (Solution = per-project; EA = enterprise.)
