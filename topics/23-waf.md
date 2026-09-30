# 23 · Well-Architected Framework (WAF)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
The Well-Architected Framework is **five quality pillars for designing a good workload**: Reliability, Security, Cost Optimization, Operational Excellence, and Performance Efficiency. It's a checklist to build solutions the right way.

## 2. Architect-Level Explanation
A workload-level design methodology:
- **Pillars**: Reliability (resilience, recovery), Security (zero trust, defense in depth), Cost Optimization (get value per dollar), Operational Excellence (DevOps, observability), Performance Efficiency (scale to demand).
- **Trade-offs**: pillars conflict (e.g., reliability/security vs cost) — WAF is about *conscious* trade-offs, not maxing all.
- **Tools**: Azure Well-Architected Review (assessment), Advisor recommendations, design principles + checklists per pillar.
- **Relation**: complements CAF — CAF sets up the environment; WAF designs the workload within it.

## 3. Real Enterprise Use Case
A payments team runs a WAF review before go-live: adds multi-zone redundancy + retries (Reliability), private endpoints + Key Vault (Security), autoscaling + caching (Performance), reservations + right-sizing (Cost), and full observability + IaC (Operational Excellence) — trade-offs documented.

## 4. Architecture Diagram (ASCII)
```
                 WORKLOAD DESIGN
   ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 Reliability  Security   Cost Opt   Operational  Performance
  (resilience) (0-trust)  (value)    Excellence   Efficiency
   └───────────┴───────────┴───────────┴───────────┴───────────┘
          Conscious trade-offs (e.g., cost vs resilience)
          Assessed via WAF Review + Azure Advisor
```

## 5. Interview Questions
1. Name and explain the five WAF pillars.
2. WAF vs CAF?
3. Give an example trade-off between pillars.
4. How do you improve reliability of a workload?
5. How do you run a Well-Architected review?

## 6. Strong Interview Answers
- **Pillars**: "Reliability (survive failures, meet SLOs), Security (protect data/systems, zero trust), Cost Optimization (maximize value), Operational Excellence (automation, monitoring, DevOps), Performance Efficiency (scale to demand efficiently)."
- **WAF vs CAF**: "CAF is org-level adoption/operating model; WAF is per-workload design quality. CAF builds the estate; WAF designs each solution in it."
- **Trade-off**: "Multi-region active-active boosts reliability but doubles cost and adds complexity — I'd choose it only if the SLA/business impact justifies it; otherwise active-passive."
- **Reliability**: "Eliminate single points of failure (zones/regions), design for retries/timeouts/circuit breakers, define RTO/RPO, and test with chaos/DR drills."
- **Review**: "Use the Azure Well-Architected Review questionnaire per pillar, capture risks/recommendations, prioritize, and remediate — repeat periodically."

## 7. Common Mistakes
- Trying to maximize all pillars (ignoring trade-offs).
- Security/reliability as afterthoughts.
- No defined SLOs/RTO/RPO.
- Skipping the review before production.

## 8. Trade-offs
| Boost | Costs |
|-------|-------|
| Reliability (multi-region) | cost, complexity |
| Security (more controls) | latency, friction, cost |
| Performance (bigger SKUs) | cost |
| Cost cutting | may hurt reliability/perf |

## 9. Production Best Practices
- Define SLOs, RTO/RPO up front.
- Design for failure; automate ops (IaC, CI/CD).
- Zero-trust security; observability everywhere.
- Right-size + autoscale; run periodic WAF reviews.
- Document trade-offs explicitly.

## 10. Security Considerations
- Zero trust, defense in depth, least privilege.
- Encryption, Key Vault, private networking.
- Threat detection (Defender), audit, incident response.

## 11. Cost Optimization
- Right-size, autoscale, reservations/savings plans.
- Shut down idle; tag for cost allocation; budgets/alerts.
- Use Advisor cost recommendations.

## 12. Troubleshooting Scenarios
- **Outages** → reliability gaps (SPOFs, no retries/zones).
- **Breach risk** → security review, close gaps.
- **Slow** → performance pillar (scale, cache, async).
- **Overspend** → cost pillar (right-size, reserve, cleanup).

## 13. Hands-on Example
```text
Run: Azure Portal → Well-Architected Review → select workload →
answer per-pillar questions → export prioritized recommendations.
```

## 14. Terraform Example
```hcl
# Reliability: zone-redundant + autoscale by design
resource "azurerm_linux_virtual_machine_scale_set" "app" {
  name = "app-vmss" resource_group_name = azurerm_resource_group.rg.name
  location = "eastus" sku = "Standard_D2s_v5" instances = 3
  zones = ["1","2","3"]
  # autoscale + health probes configured separately
}
```

## 15. Azure Example
Use **Azure Advisor** (mapped to WAF pillars) for reliability/security/cost/performance recommendations, and the **Well-Architected Review** tool for structured assessment.

## 16. FastAPI / Python Example
```python
# Operational Excellence + Reliability: health + retries
from tenacity import retry, wait_exponential, stop_after_attempt

@app.get("/health")
def health(): return {"status": "ok"}

@retry(wait=wait_exponential(), stop=stop_after_attempt(3))
def call_downstream(): ...
```

## 17. AKS Example
Apply WAF to AKS: zone-spread node pools + PDBs (Reliability), private cluster + Workload Identity (Security), spot + autoscale (Cost), Prometheus/Insights (Ops), HPA/KEDA (Performance).

## 18. How to Remember
**"CROPS"** → **C**ost, **R**eliability, **O**perational excellence, **P**erformance, **S**ecurity. Design consciously; trade off deliberately.

## 19. Real-World Analogy
Building codes for a house: structural safety (reliability), locks/alarms (security), budget (cost), maintenance access (operations), and efficient heating/plumbing (performance) — you balance them, you don't max every one.

## 20. One-Page Cheat Sheet
- **5 pillars**: Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency.
- **Core idea**: conscious trade-offs, not maximize-all.
- **WAF vs CAF**: workload design vs org adoption.
- **Reliability**: no SPOFs, retries/timeouts, RTO/RPO, DR drills.
- **Assess**: Well-Architected Review + Azure Advisor, periodically.
- **Document trade-offs** explicitly.
