# Deep Dive · Azure Landing Zones

> Phase 3 (Azure foundation) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
An **Azure Landing Zone (ALZ)** is a **pre-built, governed environment** — the enterprise-scale foundation you deploy *before* workloads — that bakes in **identity, networking, security, governance, and management** according to the **Cloud Adoption Framework (CAF)**. It uses **management groups + subscriptions + Azure Policy + RBAC + hub-spoke networking** so every new workload lands in a **secure, compliant, well-architected** "plot of land" instead of a greenfield free-for-all. It's how large enterprises scale to hundreds of subscriptions without chaos.

---

## 2. Architect-Level Explanation
ALZ is the **platform foundation** structured around CAF's design areas:
- **Management group hierarchy**: Root → Platform (identity, management, connectivity) + Landing Zones (corp, online) + Sandbox + Decommissioned.
- **Subscription democratization**: subscriptions as the **unit of scale/isolation/billing** per workload/team.
- **Governance**: **Azure Policy** (guardrails: allowed regions, required tags, deny public IPs, enforce encryption) applied at management-group scope; **RBAC** for least privilege.
- **Networking**: **hub-spoke** (or Virtual WAN) — shared hub (firewall, gateway, DNS) + workload spokes; **private connectivity** (Private Link/Endpoints).
- **Security/Ops**: Defender for Cloud, Sentinel, centralized Log Analytics, Key Vault.
- **Two flavors**: **Platform landing zones** (shared services) vs **Application landing zones** (where workloads run).

Architecturally, ALZ = **"policy-driven guardrails + network + identity, deployed as code (IaC)"** so scale is safe by default.

---

## 3. Why It Exists
- **Problem**: ad-hoc subscriptions with inconsistent security/networking/naming → sprawl, risk, un-auditable.
- **Breakthrough**: a **prescriptive, repeatable foundation** (CAF ALZ) with policy guardrails so teams move fast *within* safe boundaries ("freedom within a framework").
- **Why enterprises adopt it**: consistent compliance, security, and cost governance at scale; faster onboarding of new workloads; auditability for regulators.
- **GSK/regulated angle**: policy enforcement (data residency, encryption, private-only) and auditability map directly to compliance needs.

---

## 4. Internal Working
**How guardrails apply:**
1. **Management groups** form a hierarchy; **policies + RBAC assigned at MG scope inherit down** to all child subscriptions.
2. **Azure Policy** evaluates resources at create/update: **deny** (block non-compliant), **audit** (report), or **deployIfNotExists/modify** (auto-remediate — e.g., deploy diagnostic settings).
3. **Platform subscriptions** host shared services (connectivity hub, identity, management/logging).
4. **Application landing zones** (subscriptions) are handed to teams **pre-wired** to the hub, with policies + budgets + RBAC already applied.
5. **IaC** (Terraform/Bicep, or the ALZ accelerator) deploys and version-controls the whole hierarchy → repeatable, drift-detectable.
6. **Centralized logging**: diagnostic settings (via policy) stream to a central Log Analytics workspace.

Key property: **governance is inherited and enforced automatically**, not applied per resource by hand.

---

## 5. Enterprise Use Case
A pharma stands up an ALZ: management groups for **Platform** (connectivity, identity, management) and **Landing Zones** (Corp for internal, Online for external). Policies enforce **allowed regions (EU only for GxP data)**, **no public IPs**, **encryption + private endpoints required**, and **mandatory tags** (cost center, data classification). A new GenAI project gets an **application landing zone** subscription already connected to the hub firewall, with Defender, budgets, and RBAC pre-applied — the team deploys AOAI + AKS into a compliant environment on day one.

---

## 6. Real Production Architecture
```
                         Root Management Group
        ┌───────────────┬───────────────┬───────────────┐
     Platform        Landing Zones     Sandbox      Decommissioned
   ┌────┼────┐        ┌────┴────┐
 Identity Mgmt Connectivity   Corp     Online
   │      │      │             │         │
  Entra  Log/   Hub VNet:    Spoke     Spoke (app landing zones)
  /PIM   Monitor Firewall,   VNets ◄── peered ──► Hub
         Sentinel Gateway,DNS  (GenAI, data, apps)
   Policies (deny/audit/DINE) + RBAC inherit down the hierarchy
```

---

## 7. Security Best Practices
- **Policy-as-guardrails**: deny public IPs/storage, enforce encryption, TLS, private endpoints, allowed SKUs/regions.
- **Least-privilege RBAC** at MG/subscription scope; **PIM** for just-in-time elevation.
- **Centralized identity** (Entra ID), **Managed Identities** for workloads.
- **Hub-based egress control** (Azure Firewall) + **private connectivity** (Private Link).
- **Defender for Cloud** (secure score, regulatory compliance dashboards) + **Sentinel** (SIEM) enabled org-wide via policy.
- **Central Log Analytics**; diagnostic settings enforced by policy.
- **Separation of duties**: platform team owns shared services; app teams own their landing zones.

---

## 8. Scaling Strategy
- **Subscription-as-scale-unit**: new workloads = new application landing zones (avoids per-subscription limits).
- **Management-group inheritance** applies governance to N subscriptions with one assignment.
- **Virtual WAN** for large-scale/global connectivity vs classic hub-spoke.
- **ALZ accelerator (IaC)** to provision new landing zones repeatably and fast.
- **Policy at scale** rather than manual config per resource.

---

## 9. High Availability Strategy
- **Multi-region** platform (paired regions) for shared services (firewall, gateways, DNS).
- **Availability Zones** for hub components where supported.
- **Redundant connectivity** (dual ExpressRoute/VPN) in the connectivity subscription.
- Governance ensures workloads inherit HA-supporting policies (e.g., zone-redundant SKUs where required).

---

## 10. Disaster Recovery Strategy
- **Everything as IaC** → redeploy the platform/landing zones in a secondary region.
- **Paired-region** design for platform services; **geo-replicated** central logging/Key Vault.
- **Documented failover** for connectivity (ExpressRoute/VPN) and DNS.
- Per-workload DR handled within each application landing zone; platform provides the framework.

---

## 11. Cost Optimization Strategy
- **Policy-enforced tagging** → accurate cost allocation/chargeback per landing zone.
- **Budgets + alerts** at subscription/MG scope; **Azure Cost Management** dashboards.
- **Deny expensive SKUs/regions** via policy; enforce right-sizing.
- **Reserved Instances/savings plans** centrally; shared services reduce duplication.
- **Decommissioned MG** to cleanly retire and stop spend.

---

## 12. Common Production Challenges
- **Over-restrictive policies** blocking teams → balance guardrails vs velocity (start audit, then deny).
- **Policy sprawl/conflicts** → curate initiatives, test in audit mode.
- **Networking complexity** (peering, DNS, firewall rules) → standardize via IaC modules.
- **Drift** from manual changes → enforce IaC + policy + drift detection.
- **Subscription limits** hit → democratize subscriptions properly.
- **Onboarding friction** → automate landing-zone vending (accelerator).

---

## 13. Monitoring and Observability
- **Central Log Analytics + Azure Monitor**; **Defender for Cloud secure score** + **regulatory compliance** views.
- **Azure Policy compliance dashboard** (what's compliant/non-compliant across the estate).
- **Sentinel** for security analytics/incidents org-wide.
- **Cost Management** dashboards + budget alerts.
- **Activity logs** centralized for audit.

---

## 14. Troubleshooting Scenarios
- **Deployment blocked** → a deny policy; check Policy compliance/`deniedBy`; adjust or exempt correctly.
- **Resource not logging** → DINE diagnostic policy didn't remediate; trigger remediation task.
- **Spoke can't reach internet/PaaS** → firewall/UDR/DNS misconfig in hub; verify routes + private DNS zones.
- **Unexpected costs** → missing tags/wrong SKU; enforce tag policy + budgets.
- **Access denied for a team** → RBAC scope wrong; assign at the correct MG/subscription level (least privilege).

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Strict policy (deny) | strong compliance | can slow teams |
| Hub-spoke | central control | hub is a dependency/bottleneck |
| Virtual WAN | scale/global | cost/complexity |
| Full ALZ upfront | governed from day 1 | large initial effort |

---

## 16. When NOT to use it (full ALZ)
- **Single small workload / PoC** → a governed single subscription may suffice; full ALZ is overkill.
- **Startup with one team** → adopt incrementally (CAF "start small, grow").
- **Short-lived experiments** → sandbox MG, not the full framework.
- Note: you still want *some* governance — just right-sized.

---

## 17. Comparison with Alternatives
| Approach | Governance | Scale | Best for |
|----------|-----------|-------|----------|
| **Azure Landing Zones (CAF)** | strong, inherited | enterprise | many teams/subscriptions |
| Single governed subscription | moderate | small | one team/workload |
| Ad-hoc subscriptions | weak | risky | avoid at scale |
| 3rd-party frameworks | varies | varies | specific needs |

---

## 18. Interview Questions
1. What is an Azure Landing Zone and why do enterprises need one?
2. Explain the management group hierarchy in CAF ALZ.
3. Platform vs application landing zones?
4. How does Azure Policy enforce guardrails (effects)?
5. Hub-spoke vs Virtual WAN?
6. How do you balance governance vs team velocity?
7. How is an ALZ deployed and kept from drifting?
8. How does ALZ support compliance/audit?
9. How do you onboard a new workload into an ALZ?
10. When is a full ALZ overkill?

---

## 19. Strong Interview Answers
- **What/why**: "An ALZ is the governed foundation — identity, networking, security, governance — deployed before workloads per CAF. It lets hundreds of subscriptions stay secure and compliant by default: freedom within a framework."
- **Hierarchy**: "Root MG → Platform (identity, management, connectivity) + Landing Zones (corp/online) + Sandbox + Decommissioned. Policies and RBAC assigned at MG scope inherit down, so one assignment governs many subscriptions."
- **Policy effects**: "Deny blocks non-compliant resources, Audit reports them, and DeployIfNotExists/Modify auto-remediate — e.g., auto-attach diagnostic settings. I roll out new policies in audit first, then enforce deny to avoid breaking teams."
- **Governance vs velocity**: "Guardrails, not gates. I enforce the non-negotiables (no public IPs, encryption, regions) as deny, keep the rest as audit, and give teams a pre-wired landing zone so they move fast safely."
- **Anti-drift**: "Deploy everything as IaC (Terraform/Bicep or the ALZ accelerator), enforce with policy, and detect drift. Manual portal changes are the enemy of a governed estate."

---

## 20. Architecture Diagrams
**Governance inheritance:**
```
Root MG ──(policy + RBAC)──► inherited by all children
  Platform MG → identity/mgmt/connectivity subscriptions
  Landing Zones MG → Corp + Online → application landing-zone subscriptions
Hub VNet (firewall/gw/DNS) ◄── peering ──► Spoke VNets (workloads, private)
```

---

## 21. Real Project Example
**Enterprise-scale GenAI onboarding.** The platform team maintains the ALZ as Terraform (accelerator-based). Policies enforce EU-only regions for regulated data, private endpoints, encryption, and mandatory data-classification tags. A new GenAI product requests a landing zone; automated "subscription vending" provisions a spoke peered to the hub firewall, Defender + Sentinel + central logging enabled, budgets and RBAC applied. The team deploys AOAI + AKS the same day into a compliant, audit-ready environment.

---

## 22. Whiteboard Design Question
> *"Design the Azure foundation for a regulated enterprise onboarding 50 workloads/year."*

Cover: MG hierarchy (Platform + Landing Zones + Sandbox + Decommissioned) → policy initiatives (regions, private-only, encryption, tags) with audit→deny rollout → hub-spoke/Virtual WAN connectivity with firewall + private DNS → centralized identity (Entra/PIM) + RBAC least-privilege → Defender + Sentinel + central Log Analytics → IaC accelerator + subscription vending → budgets/chargeback via tags → HA/DR (paired regions, IaC redeploy). Emphasize inheritance, guardrails-not-gates, and auditability.

---

## 23. Design Review Questions
- Is the **MG hierarchy** aligned to CAF (platform vs landing zones)?
- Which policies are **deny vs audit**, and was rollout staged?
- **Hub-spoke or Virtual WAN** — justified by scale?
- **Private connectivity** (Private Link/DNS) enforced?
- **RBAC least privilege + PIM** for elevation?
- **Central logging + Defender + Sentinel** enabled by policy?
- **IaC + drift detection**; subscription vending automated?
- **Tagging + budgets** for cost governance?

---

## 24. Hands-on Example
```bash
# Create MG hierarchy and assign a policy at scope (inherits to children)
az account management-group create --name platform --parent root
az account management-group create --name landingzones --parent root
# Enforce allowed locations across all landing zones (deny non-EU)
az policy assignment create --name allowed-locations \
  --scope /providers/Microsoft.Management/managementGroups/landingzones \
  --policy e56962a6-4747-49cd-b67b-bf8b01975c4c \
  --params '{ "listOfAllowedLocations": { "value": ["westeurope","northeurope"] } }'
```

---

## 25. Terraform Example
```hcl
# Management group + inherited policy (guardrail). Real ALZ uses the accelerator module.
resource "azurerm_management_group" "lz" {
  display_name = "landing-zones"
}

resource "azurerm_management_group_policy_assignment" "require_tags" {
  name                 = "require-costcenter"
  management_group_id  = azurerm_management_group.lz.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
  parameters = jsonencode({ tagName = { value = "costCenter" } })   # deny resources missing tag
}

resource "azurerm_management_group_policy_assignment" "deny_public_ip" {
  name                 = "deny-public-ip"
  management_group_id  = azurerm_management_group.lz.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
}
```

---

## 26. Azure Example
```bash
# Enable Defender for Cloud + stream policy compliance to a central workspace
az security pricing create -n VirtualMachines --tier Standard
az monitor diagnostic-settings create --name to-central-law \
  --resource $(az account show --query id -o tsv) \
  --workspace $CENTRAL_LAW_ID --logs '[{"category":"Administrative","enabled":true}]'
# Check estate policy compliance
az policy state summarize --management-group landing-zones
```

---

## 27. Code Example
```json
// Custom policy: deny Azure OpenAI without a private endpoint (regulated data)
{
  "properties": {
    "displayName": "AOAI must use private endpoint",
    "policyRule": {
      "if": {
        "allOf": [
          { "field": "type", "equals": "Microsoft.CognitiveServices/accounts" },
          { "field": "Microsoft.CognitiveServices/accounts/publicNetworkAccess", "equals": "Enabled" }
        ]
      },
      "then": { "effect": "deny" }
    }
  }
}
```

---

## 28. Things Architects Must Remember
- **ALZ = governed foundation before workloads** (CAF): identity + network + security + governance + management.
- **Management-group inheritance** applies policy/RBAC to many subscriptions at once.
- **Subscription = unit of scale/isolation/billing**; democratize them.
- **Policy effects**: deny (block), audit (report), DINE/modify (remediate) — roll out audit→deny.
- **Guardrails, not gates** — enforce non-negotiables, keep teams fast.
- **Hub-spoke/Virtual WAN + private connectivity** for controlled networking.
- **Everything as IaC** — the accelerator + drift detection prevent sprawl.
- **Central logging + Defender + Sentinel** for security/compliance/audit.

---

## 29. Mnemonics and Memory Tricks
- **"Freedom within a framework"** — the ALZ philosophy.
- **CAF design areas "I-N-S-G-M"**: **I**dentity, **N**etwork, **S**ecurity, **G**overnance, **M**anagement.
- **Policy effects "D-A-D"**: **D**eny, **A**udit, **D**eployIfNotExists.
- **"Land the plane on a prepared runway"** — workloads land in a ready, governed zone.
- **Rollout "audit first, deny later."**

---

## 30. One-Page Interview Revision Sheet
- **What**: CAF-based governed foundation (identity/network/security/governance/management) deployed before workloads.
- **Hierarchy**: Root MG → Platform (identity/mgmt/connectivity) + Landing Zones (corp/online) + Sandbox + Decommissioned; policy/RBAC inherit down.
- **Governance**: Azure Policy effects — **Deny/Audit/DINE/Modify**; roll out audit→deny.
- **Networking**: hub-spoke or Virtual WAN; firewall + gateway + private DNS; Private Link/Endpoints.
- **Identity/security**: Entra + PIM + least-privilege RBAC; Defender + Sentinel + central Log Analytics.
- **Scale**: subscription-as-scale-unit + subscription vending (accelerator, IaC).
- **HA/DR**: paired regions, IaC redeploy, geo-replicated logging/Key Vault.
- **Cost**: enforced tags + budgets + Cost Management; deny costly SKUs; central RIs.
- **When NOT (full)**: single small workload/PoC → right-size governance.
- **Remember**: *freedom within a framework*; **I-N-S-G-M**; **D-A-D** effects; guardrails not gates; everything as IaC.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain an Azure Landing Zone to a CIO and justify the upfront investment.
2. Draw the CAF management-group hierarchy and explain inheritance.
3. Differentiate platform vs application landing zones with examples.
4. Walk through Azure Policy effects and a safe rollout strategy.
5. How do you enforce EU-only data residency and private-only networking across 100 subscriptions?
6. Hub-spoke vs Virtual WAN — pick one for a global enterprise and defend it.
7. How do you keep the estate from drifting away from its IaC definition?
8. Design subscription vending so a new team is productive and compliant on day one.
9. How does an ALZ make a regulator audit straightforward?
10. When would you deliberately NOT deploy a full ALZ, and what would you do instead?

---

> Next Phase 3 topic: **Azure Networking (VNet/NSG/UDR/Firewall/Private Link)**.
