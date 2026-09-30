# 121 · Enterprise Architecture

> Domain: Architecture Patterns · Level: Principal Enterprise Architect

## 1. Beginner Explanation
Enterprise Architecture (EA) is the practice of **designing how an entire organization's business, information, applications, and technology fit together** to achieve its goals. It's the big-picture blueprint that keeps IT aligned with business strategy.

## 2. Architect-Level Explanation
The discipline of aligning IT strategy + capabilities with business strategy across the whole enterprise:
- **Four architecture domains (BDAT)**: **Business** (capabilities, processes, org), **Data** (information/data architecture), **Application** (app portfolio + integration), **Technology** (infrastructure/platforms).
- **Frameworks**: **TOGAF** (ADM cycle), **Zachman** (taxonomy), **FEAF**, **Gartner**; **cloud frameworks**: Azure **Well-Architected Framework** (Reliability, Security, Cost, Operational Excellence, Performance) + **Cloud Adoption Framework (CAF)** (Strategy→Plan→Ready→Adopt→Govern→Manage).
- **Artifacts**: capability maps, reference architectures, roadmaps, standards/principles, target vs current state + **gap analysis**, **landing zones**.
- **Governance**: architecture review boards, standards, principles, tech radar, lifecycle management, exceptions.
- **vs Solution Architecture**: EA is enterprise-wide/strategic + long-horizon; solution architecture is project/system-specific (topic 122).
- **Value**: reduces duplication, technical debt, and silos; enables interoperability, agility, cost efficiency, and strategic alignment.
- **Modern EA**: enables digital transformation, cloud adoption, product-oriented operating models, and platform thinking (not ivory-tower documentation).
- **Cloud landing zones**: EA defines the governed foundation (identity, network, security, management groups) new workloads land into.

## 3. Real Enterprise Use Case
A bank's EA team uses **CAF + Well-Architected** to run cloud adoption: defines **management-group hierarchy + landing zones** (identity, networking, security, policy guardrails), a capability map + reference architectures, standards (approved services, security baselines), and a target-state roadmap with gap analysis. An Architecture Review Board governs exceptions, reducing duplication and steering all teams toward consistent, secure, cost-efficient, strategy-aligned solutions.

## 4. Architecture Diagram (ASCII)
```
   Business Strategy ─────► Enterprise Architecture ─────► IT Execution
   ┌──────────── Four Domains (BDAT) ────────────┐
   Business ─► Data ─► Application ─► Technology
   Frameworks: TOGAF/Zachman + Azure CAF + Well-Architected (5 pillars)
   Current State ──(gap analysis)──► Target State (roadmap)
   Governance: review board · principles · standards · landing zones
   Output: reference architectures · capability maps · guardrails
```

## 5. Interview Questions
1. What is Enterprise Architecture and its domains?
2. EA vs Solution Architecture?
3. What frameworks do you use (TOGAF/CAF/Well-Architected)?
4. What are landing zones and why do they matter?
5. How does EA deliver business value without being ivory-tower?

## 6. Strong Interview Answers
- **EA/domains**: "EA aligns IT with business strategy across the whole enterprise, spanning four domains — **Business, Data, Application, Technology (BDAT)**. It provides the blueprint, standards, and roadmaps that keep systems coherent, interoperable, and strategy-aligned rather than a sprawl of siloed point solutions."
- **EA vs solution**: "EA is enterprise-wide, strategic, and long-horizon — capability maps, standards, reference architectures, roadmaps. **Solution architecture** applies those within a specific project/system. EA sets the guardrails and patterns; solution architects design compliant solutions inside them."
- **Frameworks**: "**TOGAF** provides the ADM process and structure; **Zachman** a taxonomy. For cloud I lean on Azure's **Cloud Adoption Framework** (Strategy→Plan→Ready→Adopt→Govern→Manage) for the adoption journey and the **Well-Architected Framework** (Reliability, Security, Cost, Operational Excellence, Performance) to assess/design workloads. They give a common language and proven guardrails."
- **Landing zones**: "A landing zone is the pre-provisioned, governed cloud foundation — management-group hierarchy, identity, networking, security baselines, and policy guardrails — that new workloads deploy into. It's EA made concrete: teams get secure, compliant, consistent environments by default instead of reinventing (and mis-configuring) foundations."
- **Value/not ivory-tower**: "Modern EA is an enabler, not a gatekeeper — it delivers reusable reference architectures, self-service landing zones, and lightweight guardrails that speed teams up while reducing duplication, tech debt, and risk. Value = faster delivery, lower cost, interoperability, and strategic alignment — measured, not just documented."

## 7. Common Mistakes
- Ivory-tower EA — documentation nobody uses; disconnected from delivery.
- No governance/standards → sprawl, duplication, tech debt.
- Framework dogma over pragmatic value.
- No target-state roadmap/gap analysis.
- Ignoring landing zones → inconsistent, insecure cloud foundations.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Strong governance | consistency | can slow teams if heavy |
| Reference architectures | reuse, speed | risk of over-standardizing |
| Detailed frameworks | rigor | overhead if dogmatic |

## 9. Production Best Practices
- Enabling, product-oriented EA (guardrails + self-service, not gatekeeping).
- CAF landing zones + Well-Architected reviews; approved-services catalog.
- Capability maps + reference architectures + roadmap (current→target, gap).
- Lightweight governance (review board, principles, exceptions process).
- Measure value (delivery speed, reuse, cost, risk); iterate.

## 10. Security Considerations
- Security baselines + policy guardrails baked into landing zones.
- Zero Trust + identity/network standards enterprise-wide.
- Governance to prevent shadow IT / non-compliant deployments.
- Data classification + compliance embedded in the architecture.

## 11. Cost Optimization
- Standardization + reuse reduce duplication cost + tech debt.
- FinOps + cost guardrails in landing zones; approved efficient patterns.
- Consolidation + platform thinking avoid redundant systems.

## 12. Troubleshooting Scenarios
- **Duplication/silos** → weak EA standards; introduce reference architectures + catalog.
- **Inconsistent/insecure cloud** → no landing zones; deploy CAF landing zones.
- **EA ignored by teams** → too heavy/ivory-tower; shift to enabling self-service guardrails.
- **Misaligned IT spend** → no strategy linkage; tie roadmap to business capabilities.
- **Slow approvals** → heavy governance; streamline with automated policy guardrails.

## 13. Hands-on Example
```
EA engagement flow:
1. Capture business strategy + capability map
2. Document current-state (BDAT) → target-state → GAP analysis → roadmap
3. Define principles + standards + reference architectures
4. Stand up CAF landing zones (identity/network/security/policy guardrails)
5. Govern via review board + automated policy; measure value; iterate
```

## 14. Terraform Example
```hcl
# Landing zone foundation: management-group hierarchy + policy guardrails (EA as code)
resource "azurerm_management_group" "platform" { display_name = "Platform" }
resource "azurerm_management_group" "landing_zones" { display_name = "Landing Zones" }
resource "azurerm_management_group_policy_assignment" "guardrails" {
  name = "allowed-locations" management_group_id = azurerm_management_group.landing_zones.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<allowed-locations>"
}
```

## 15. Azure Example
Azure realizes EA via **Cloud Adoption Framework** enterprise-scale **landing zones** (deployed with Bicep/Terraform/ALZ), **Azure Policy** guardrails, **management groups** for governance hierarchy, **Blueprints/Deployment Stacks**, and **Well-Architected Reviews** to assess workloads against the five pillars.

## 16. FastAPI / Python Example
```python
# An internal developer platform (IDP) API that provisions governed landing zones
@app.post("/landing-zone")
async def provision(team: str, environment: str):
    # applies EA guardrails: policy, network, identity, tags — self-service, compliant
    return await deploy_landing_zone(team=team, env=environment, guardrails="caf-alz")
```

## 17. AKS Example
EA defines an **AKS platform standard** as a reference architecture: approved node configs, network policy + private clusters, Workload Identity, baseline observability (Container Insights/Prometheus), policy guardrails (Azure Policy for AKS/Gatekeeper), and a paved-path Helm/GitOps pipeline — so every team's cluster is consistent, secure, and cost-governed by default.

## 18. How to Remember
**"Enterprise blueprint aligning business + IT; four domains BDAT; frameworks TOGAF + CAF + Well-Architected; current→target + gap → roadmap; landing zones = EA made real; enable, don't gatekeep."**

## 19. Real-World Analogy
City planning for a whole metropolis: rather than each builder doing whatever they want (silos/sprawl), the city sets zoning, utilities, roads, and building codes (standards + landing zones) aligned to a long-term master plan (strategy + roadmap). Good planning makes it fast and safe to build (enabling), while bad planning creates chaos, duplication, and gridlock.

## 20. One-Page Cheat Sheet
- **What**: aligning IT capabilities with business strategy across the whole enterprise.
- **Domains (BDAT)**: **Business · Data · Application · Technology**.
- **Frameworks**: TOGAF/Zachman + Azure **CAF** (adoption journey) + **Well-Architected** (5 pillars).
- **Process**: current-state → target-state → **gap analysis** → roadmap; principles + standards + reference architectures.
- **Cloud**: **landing zones** (governed foundation: identity/network/security/policy) = EA made concrete.
- **Modern EA**: enabling self-service guardrails, not ivory-tower gatekeeping; measure value. (EA = strategic; Solution Arch = per-project.)
