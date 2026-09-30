# 21 · Azure Landing Zones

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
A Landing Zone is a **pre-built, secure, governed home** in Azure where you land your workloads — networking, identity, policy, and monitoring are already set up so teams don't build it from scratch each time.

## 2. Architect-Level Explanation
Azure Landing Zones (ALZ) are the **CAF-recommended target architecture**: a Management Group hierarchy with policy-driven governance, centralized connectivity, and subscription democratization.
- **Management Group tree**: Root → Platform (Management, Connectivity, Identity) + Landing Zones (Corp, Online) + Sandbox + Decommissioned.
- **Design areas**: identity, network topology, resource org, governance (Policy), security, management/monitoring, platform automation (IaC).
- **Two flavors**: *Platform landing zones* (shared services) vs *Application landing zones* (workload subscriptions).
- Delivered as **IaC** (ALZ Terraform/Bicep accelerators) with Azure Policy for guardrails at scale.

## 3. Real Enterprise Use Case
A retailer onboarding 30 product teams to Azure. Central platform team provisions ALZ: hub for shared firewall/ExpressRoute, policies enforcing encryption/tagging/allowed regions, and per-team subscriptions ("application landing zones") with delegated RBAC — teams self-serve safely.

## 4. Architecture Diagram (ASCII)
```
                 Tenant Root MG
                       │
      ┌────────────┬───┴────────────┬───────────┐
   Platform      Landing Zones    Sandbox   Decommissioned
   ├ Management   ├ Corp (private)
   ├ Connectivity ├ Online (internet-facing)
   └ Identity
        │
   [Hub VNet: Firewall, ER Gateway, DNS] ◄─peering─► [Spoke VNets = workloads]
   Policies (encryption, tags, regions) applied top-down at MG scope
```

## 5. Interview Questions
1. What problem do Landing Zones solve at enterprise scale?
2. Platform vs application landing zones?
3. How do you enforce governance across hundreds of subscriptions?
4. Corp vs Online landing zone difference?
5. How do you keep ALZ consistent over time (drift)?

## 6. Strong Interview Answers
- **Problem**: "They solve subscription sprawl and inconsistent security. Instead of every team reinventing networking/identity/governance, ALZ provides a governed, IaC-delivered baseline so workloads 'land' secure-by-default and teams move fast within guardrails."
- **Governance at scale**: "Azure Policy assigned at Management Group scope — deny/audit/deployIfNotExists — so hundreds of subscriptions inherit controls. Combined with RBAC delegation and IaC pipelines for drift control."
- **Corp vs Online**: "Corp landing zones have no direct internet exposure and route through the hub (private, on-prem connected); Online landing zones are internet-facing with their own controls."
- **Drift**: "Everything as code (ALZ accelerator), policy `deployIfNotExists` to remediate, and continuous compliance dashboards."

## 7. Common Mistakes
- Treating ALZ as a one-time setup, not a product with a lifecycle.
- Over-centralizing → platform team becomes a bottleneck.
- Policies too strict → teams bypass; too loose → no governance.
- Flat subscription model with no MG hierarchy.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| Centralized platform | Consistency, security | Can bottleneck teams |
| Democratized subs | Team autonomy/speed | Governance harder |
| Policy deny | Strong guardrails | Friction if misjudged |

## 9. Production Best Practices
- Start from the **ALZ accelerator** (Terraform/Bicep).
- Policy-as-code with audit-first, then deny.
- Delegate RBAC at MG/subscription with least privilege.
- Standardize naming/tagging for cost + ops.
- Treat the platform as a versioned product.

## 10. Security Considerations
- Central identity (Entra ID), Conditional Access, PIM for privileged roles.
- Hub-based egress control (Azure Firewall), no public egress from Corp.
- Diagnostic settings → central Log Analytics; Defender for Cloud on all subs.

## 11. Cost Optimization
- Shared platform services (firewall, ER) amortized across spokes.
- Tag policy → cost allocation/showback.
- Budgets + Azure Policy on SKUs/regions to prevent waste.

## 12. Troubleshooting Scenarios
- **Non-compliant resources** → check policy assignment scope + remediation tasks.
- **Team can't deploy** → RBAC delegation gap at subscription scope.
- **No connectivity** → hub-spoke peering/UDR/DNS misconfig.

## 13. Hands-on Example
```bash
# Create management group hierarchy
az account management-group create --name platform --parent-id tenantRoot
az account management-group create --name landingzones --parent-id tenantRoot
```

## 14. Terraform Example
```hcl
module "alz" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "~> 6.0"
  root_parent_id = data.azurerm_client_config.core.tenant_id
  root_id        = "contoso"
  deploy_connectivity_resources = true
  deploy_management_resources   = true
}
```

## 15. Azure Example
```bash
az policy assignment create --name require-tags \
  --scope /providers/Microsoft.Management/managementGroups/landingzones \
  --policy <policy-def-id> --params '{"tagName":{"value":"costCenter"}}'
```

## 16. FastAPI / Python Example
```python
# Governance guardrail check in a platform self-service API
from azure.mgmt.resource import PolicyClient
def compliance(sub_id: str):
    states = PolicyClient(cred, sub_id).policy_states  # query non-compliant
    return {"noncompliant": query_noncompliant(states)}
```

## 17. AKS Example
Each AKS cluster lands in an **application landing zone** subscription, peered to the hub, inheriting MG policies (allowed regions, required tags, private cluster enforcement).

## 18. How to Remember
**"Airport before the plane lands."** Runway, control tower, security are ready before any workload touches down.

## 19. Real-World Analogy
A serviced office building: power, security, internet, and reception already exist — new teams just move into a floor (subscription) and start working.

## 20. One-Page Cheat Sheet
- **What**: CAF target architecture = MG hierarchy + governance + connectivity, delivered as IaC.
- **Tree**: Platform (Mgmt/Connectivity/Identity) + Landing Zones (Corp/Online) + Sandbox.
- **Govern**: Azure Policy at MG scope (audit→deny→remediate).
- **Types**: platform (shared) vs application (workload) landing zones.
- **Best practice**: ALZ accelerator, policy-as-code, RBAC delegation, tagging.
- **Analogy**: airport ready before the plane lands.
