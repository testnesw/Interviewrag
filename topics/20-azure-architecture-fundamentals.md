# 20 · Azure Architecture Fundamentals

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Azure architecture fundamentals are the **building blocks and how they fit together** — regions, resource groups, subscriptions, compute, storage, networking, identity — plus the principles to combine them well.

## 2. Architect-Level Explanation
- **Hierarchy**: Management Groups → Subscriptions → Resource Groups → Resources; governed by Azure Policy + RBAC.
- **Geography**: Regions, **Availability Zones** (in-region fault isolation), region pairs (DR).
- **Resource model**: ARM (control plane), everything is a resource with an ID, deployed via IaC (Bicep/Terraform).
- **Pillars (WAF)**: reliability, security, cost, operational excellence, performance efficiency.
- **Design tenets**: design for failure, defense in depth, least privilege, automate everything, right-size, observe.
- Trade-off thinking (CAP, cost vs resilience) drives every decision.

## 3. Real Enterprise Use Case
A retailer standardizes: Management Group hierarchy for governance, subscription-per-environment, zone-redundant workloads for the storefront (99.99%), region-pair DR, IaC pipelines, and policy-enforced tagging/encryption across all resources.

## 4. Architecture Diagram (ASCII)
```
 Tenant (Entra ID)
   └ Management Groups (policy + RBAC)
        └ Subscriptions (billing + isolation)
             └ Resource Groups (lifecycle unit)
                  └ Resources (VM, AKS, SQL, Storage...)
 Region ──[ AZ1 | AZ2 | AZ3 ]── paired Region (DR)
 Deployed via IaC (Bicep/Terraform), governed by Azure Policy
```

## 5. Interview Questions
1. Explain the Azure resource hierarchy.
2. Availability Zones vs region pairs?
3. How do you decide subscription/resource-group boundaries?
4. What are the WAF pillars?
5. How do you enforce governance at scale?

## 6. Strong Interview Answers
- **Hierarchy**: "Management Groups apply policy/RBAC broadly; subscriptions are billing + isolation + quota boundaries; resource groups are lifecycle/deployment units; resources are the actual services. This enables governance top-down and autonomy bottom-up."
- **AZ vs pairs**: "Zones protect against datacenter failure *within* a region (synchronous, low latency) for HA; region pairs protect against *regional* disaster (async replication, sequential updates) for DR. Use both."
- **Boundaries**: "Subscriptions by environment/business unit/security/quota; resource groups by shared lifecycle. Avoid one giant sub or one giant RG."
- **Governance**: "Azure Policy at MG scope (audit→deny→remediate), RBAC least privilege, IaC pipelines, tagging standards — i.e., Landing Zones."

## 7. Common Mistakes
- Flat structure (no MGs, one subscription).
- Mixing unrelated workloads in one resource group.
- Ignoring zones for critical workloads.
- Click-ops instead of IaC → drift.

## 8. Trade-offs
| Decision | Pro | Con |
|----------|-----|-----|
| Zone-redundant | HA | slight cost/latency |
| Region-pair DR | disaster resilience | cost + complexity |
| Many subscriptions | isolation | management overhead |

## 9. Production Best Practices
- Landing Zones + Management Group hierarchy.
- IaC for everything; policy-as-code.
- Zone redundancy for critical tiers; DR to region pair.
- Standardized naming/tagging; least-privilege RBAC.
- Central monitoring + cost management.

## 10. Security Considerations
- Entra ID identity, Conditional Access, PIM.
- Defense in depth: network + identity + data.
- Encryption (CMK), Key Vault, private networking.
- Defender for Cloud across subscriptions.

## 11. Cost Optimization
- Right-size + autoscale; reservations/savings plans.
- Tag-based cost allocation; budgets + alerts.
- Shut down non-prod off-hours; delete orphaned resources.

## 12. Troubleshooting Scenarios
- **Deployment fails** → ARM error, RBAC, policy deny, quota.
- **Quota limits** → subscription limits, request increase.
- **Inconsistent envs** → move to IaC, eliminate click-ops drift.

## 13. Hands-on Example
```bash
az group create -n rg-app-prod -l eastus
az deployment group create -g rg-app-prod --template-file main.bicep
```

## 14. Terraform Example
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-app-prod"
  location = "eastus"
  tags = { env = "prod", costCenter = "retail", owner = "platform" }
}
```

## 15. Azure Example
```bash
az account management-group create --name platform
az policy assignment create --name require-tag \
  --scope /providers/Microsoft.Management/managementGroups/platform \
  --policy <policy-id>
```

## 16. FastAPI / Python Example
```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
rc = ResourceManagementClient(DefaultAzureCredential(), SUB_ID)

@app.get("/resource-groups")
def list_rgs():
    return [rg.name for rg in rc.resource_groups.list()]
```

## 17. AKS Example
Place AKS in its own resource group within a workload subscription; node resource group (MC_*) is auto-managed; zone-spread node pools for in-region HA.

## 18. How to Remember
**"MG → Sub → RG → Resource."** Governance flows down; workloads live at the bottom.

## 19. Real-World Analogy
A corporation: head office rules (Management Groups), departments with budgets (subscriptions), project teams (resource groups), and employees doing work (resources).

## 20. One-Page Cheat Sheet
- **Hierarchy**: Management Group → Subscription → Resource Group → Resource.
- **Geo**: Zones (in-region HA) + region pairs (DR).
- **Govern**: Azure Policy (MG scope) + RBAC + IaC + tagging.
- **Pillars**: reliability, security, cost, ops excellence, performance.
- **Tenets**: design for failure, least privilege, automate, right-size, observe.
- **Boundaries**: subs by env/BU/security; RGs by lifecycle.
