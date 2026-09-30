# 22 · CAF (Cloud Adoption Framework)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
The Cloud Adoption Framework is Microsoft's **step-by-step guidance for moving to and running in the cloud** — strategy, planning, landing zones, migration, governance, and management best practices.

## 2. Architect-Level Explanation
A lifecycle methodology with defined phases:
- **Strategy** → **Plan** → **Ready** (Landing Zones) → **Adopt** (Migrate/Innovate) → **Govern** → **Manage** → **Secure**.
- **Ready** delivers the **Azure Landing Zone** target architecture (MG hierarchy, connectivity, governance as IaC).
- **Govern**: policy-driven guardrails (cost, security, identity, resource consistency).
- **Manage**: operations baseline (monitoring, backup, DR).
- Complements **WAF** (workload-level design) — CAF is org/platform-level; WAF is per-workload.

## 3. Real Enterprise Use Case
An enterprise migrating 500 apps uses CAF: defines cloud strategy + business case (Strategy/Plan), deploys Landing Zones (Ready), runs wave-based migration (Adopt/Migrate), enforces policy guardrails (Govern), and stands up a cloud operations model (Manage).

## 4. Architecture Diagram (ASCII)
```
 Strategy ─► Plan ─► Ready ─► Adopt ──► (steady state)
   why?     what?   landing   migrate/     │
                     zones    innovate     ▼
        ┌───────── cross-cutting ──────────┐
        │  Govern · Manage · Secure        │
        └──────────────────────────────────┘
```

## 5. Interview Questions
1. What is CAF and its phases?
2. CAF vs Well-Architected Framework?
3. Where do Landing Zones fit in CAF?
4. How does the Govern methodology work?
5. How do you build a migration plan with CAF?

## 6. Strong Interview Answers
- **CAF**: "End-to-end adoption guidance: Strategy, Plan, Ready, Adopt, plus continuous Govern/Manage/Secure. It's the organizational playbook for cloud."
- **CAF vs WAF**: "CAF is org/platform scope — how to adopt and operate cloud; WAF is workload scope — how to design a specific solution well. Use CAF to set up the environment, WAF to build each app in it."
- **Landing Zones**: "They're the 'Ready' phase output — the governed, IaC-delivered environment workloads land into."
- **Govern**: "Iterative: assess risk → define policy → implement guardrails (Azure Policy) → monitor compliance → improve. Covers cost, security baseline, identity, resource consistency, deployment acceleration."
- **Migration plan**: "Assess (discovery, business case), prioritize waves, choose the right 'R' (rehost/refactor/rearchitect/rebuild/replace), migrate, optimize."

## 7. Common Mistakes
- Jumping to migration without Strategy/Plan.
- Skipping Landing Zones (Ready) → ungoverned sprawl.
- Treating CAF as docs, not an operating model.
- Ignoring Govern/Manage after migration.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| Full CAF adoption | governed, scalable | upfront effort |
| Lift-and-shift first | fast | tech debt, optimize later |
| Refactor first | cloud-native benefits | slower, costlier |

## 9. Production Best Practices
- Start with Strategy + Plan + clear business case.
- Deploy Landing Zones before workloads.
- Wave-based migration with the right 'R' per app.
- Govern with policy-as-code; establish an ops baseline.
- Cloud Center of Excellence (CCoE) to drive it.

## 10. Security Considerations
- Secure methodology: identity, network, data protection baselines.
- Defender for Cloud + Sentinel from day one.
- Zero-trust identity (Entra ID, Conditional Access, PIM).

## 11. Cost Optimization
- Business case + cost modeling in Plan.
- Govern cost with budgets, policy on SKUs/regions.
- Optimize post-migration (right-size, reserve).

## 12. Troubleshooting Scenarios
- **Sprawl/inconsistency** → missing Landing Zones/Govern.
- **Stalled migration** → unclear strategy/prioritization.
- **Cost overrun** → no cost governance; add budgets/policy.
- **Ops gaps** → Manage methodology (monitoring/backup/DR).

## 13. Hands-on Example
```bash
# Ready phase: bootstrap landing zones via accelerator
az deployment mg create --management-group-id contoso \
  --template-uri <alz-accelerator-template> --location eastus
```

## 14. Terraform Example
```hcl
module "alz" {                       # CAF "Ready" as code
  source         = "Azure/caf-enterprise-scale/azurerm"
  version        = "~> 6.0"
  root_id        = "contoso"
  root_parent_id = data.azurerm_client_config.core.tenant_id
}
```

## 15. Azure Example
Use the **Azure landing zone portal accelerator** (Ready) and **Azure Migrate** (Adopt) with **Azure Policy** initiatives (Govern) mapped to CAF recommendations.

## 16. FastAPI / Python Example
```python
# CCoE self-service: check a subscription's CAF governance readiness
@app.get("/readiness/{sub_id}")
def readiness(sub_id: str):
    return {"policies_assigned": count_policies(sub_id),
            "landing_zone": in_management_group(sub_id),
            "defender_enabled": defender_status(sub_id)}
```

## 17. AKS Example
AKS workloads land in an application landing zone (Ready), migrated per CAF Adopt guidance, governed by inherited MG policies (private cluster, allowed regions, tagging).

## 18. How to Remember
**"Strategy, Plan, Ready, Adopt — then Govern, Manage, Secure forever."** CAF = the journey; WAF = the vehicle design.

## 19. Real-World Analogy
Relocating a company to a new city: decide why and where (Strategy/Plan), prepare the new offices (Ready), move teams in waves (Adopt), and keep running rules and facilities (Govern/Manage/Secure).

## 20. One-Page Cheat Sheet
- **What**: Microsoft's end-to-end cloud adoption methodology.
- **Phases**: Strategy → Plan → Ready → Adopt (+ Govern/Manage/Secure).
- **Ready = Landing Zones** (governed IaC environment).
- **CAF vs WAF**: org/platform adoption vs per-workload design.
- **Migration**: assess → prioritize waves → pick the right 'R' → optimize.
- **Drive it**: Cloud Center of Excellence + policy-as-code.
