# 67 · Azure Terraform (azurerm Provider & Patterns)

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
This is about using Terraform specifically with Azure — the **azurerm provider** — to create Azure resources like resource groups, VNets, AKS, storage, and databases, plus the Azure-specific patterns that make it work well.

## 2. Architect-Level Explanation
Terraform on Azure via the azurerm (and related) providers:
- **Providers**: `azurerm` (ARM resources), `azuread` (Entra ID), `azapi` (any/new ARM API not yet in azurerm), `azurerm` + `random`/`tls` helpers.
- **Auth**: Azure CLI (local), **OIDC/workload federation** (CI, no secrets), managed identity, or service principal. Set subscription via `ARM_SUBSCRIPTION_ID`/provider block.
- **azapi escape hatch**: use `azapi_resource` for brand-new Azure features before azurerm supports them.
- **Patterns**: landing zones, hub-spoke, AKS + ACR + Key Vault, private endpoints, RBAC role assignments, diagnostic settings.
- **Naming/tagging**: enforce via locals/modules + Azure Policy (CAF naming).
- **Alternatives**: **Bicep/ARM** (Azure-native, state-free) vs Terraform (multi-cloud, explicit state) — pick per org standard; **Azure Verified Modules (AVM)** provide Microsoft-maintained Terraform modules.
- **Provider features block** and version pinning are mandatory.

## 3. Real Enterprise Use Case
An enterprise builds its Azure landing zone entirely in Terraform: management groups + policies (azurerm/azapi), hub-spoke networking, AKS with ACR/Key Vault via private endpoints, RBAC assignments, and diagnostic settings to Log Analytics — deployed via OIDC-authenticated pipelines using Azure Verified Modules where possible.

## 4. Architecture Diagram (ASCII)
```
   Providers: azurerm · azuread · azapi (new APIs) · random/tls
        │ auth: OIDC / Managed Identity (CI, no secrets)
   Root module ─► Azure Verified Modules / golden modules
     ├─ RG + VNet (hub-spoke) + Private Endpoints
     ├─ AKS + ACR + Key Vault (RBAC role_assignments)
     └─ Diagnostic settings ─► Log Analytics
   Naming/tags via locals + Azure Policy (CAF)
```

## 5. Interview Questions
1. How does Terraform authenticate to Azure?
2. azurerm vs azapi vs Bicep/ARM?
3. What are Azure Verified Modules?
4. How do you handle new Azure features not in azurerm?
5. How do you assign RBAC and manage identities in Terraform?

## 6. Strong Interview Answers
- **Auth**: "Locally via Azure CLI; in CI via **OIDC/workload federation** so pipelines get short-lived tokens with no stored secrets. Managed identity for Azure-hosted runners, or a service principal as a fallback. Subscription is set via provider config/`ARM_SUBSCRIPTION_ID`."
- **azurerm/azapi/Bicep**: "azurerm is the mature typed provider for Azure resources; azapi is an escape hatch that calls raw ARM APIs for brand-new or preview features azurerm lacks. Bicep/ARM are Azure-native and state-free but single-cloud; Terraform is multi-cloud with explicit state. I choose per org standard."
- **AVM**: "Azure Verified Modules are Microsoft-maintained, well-architected Terraform (and Bicep) modules following CAF/WAF — a trusted starting point instead of writing everything from scratch."
- **New features**: "Use `azapi_resource` to manage a resource via the raw ARM API until azurerm adds first-class support, then migrate — avoids being blocked on provider release cadence."
- **RBAC/identity**: "`azurerm_role_assignment` for RBAC, `azurerm_user_assigned_identity` / SystemAssigned for identities, and `azuread` provider for Entra objects — wiring least-privilege access as code."

## 7. Common Mistakes
- Storing SP secrets instead of using OIDC/managed identity.
- Missing `features {}` block / unpinned provider.
- Reinventing modules instead of using AVM.
- Hardcoding subscription IDs across envs.
- Not using azapi when blocked on a new feature.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Terraform | multi-cloud, ecosystem | manage state |
| Bicep/ARM | native, state-free | Azure-only |
| azapi | day-0 features | less typed/validated |

## 9. Production Best Practices
- OIDC/managed identity auth (no secrets); pin providers + `features {}`.
- Use Azure Verified Modules / golden modules.
- Private endpoints, RBAC role assignments, diagnostic settings as code.
- CAF naming + tagging via locals + Azure Policy.
- azapi for new features; migrate to azurerm later.

## 10. Security Considerations
- Secretless auth (OIDC), least-privilege apply identity.
- Private networking (private endpoints, no public).
- Key Vault for secrets; RBAC over access policies.
- Diagnostic/audit settings enabled by default in modules.

## 11. Cost Optimization
- AVM/golden modules enforce right-sized SKUs.
- Infracost on azurerm plans; tags enable cost allocation.
- Reuse landing-zone modules to avoid duplication.

## 12. Troubleshooting Scenarios
- **Auth 401/403** → OIDC federation/role missing; wrong subscription.
- **Unsupported argument** → provider too old / feature not in azurerm → azapi.
- **Provider config error** → missing `features {}`.
- **Wrong subscription** → `ARM_SUBSCRIPTION_ID`/provider mismatch.
- **Role assignment race** → add `depends_on` / retry (eventual consistency).

## 13. Hands-on Example
```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_USE_OIDC=true       # in CI
terraform init && terraform apply
```

## 14. Terraform Example
```hcl
provider "azurerm" {
  features {}
  use_oidc = true
  subscription_id = var.subscription_id
}
provider "azapi" {}

# Escape hatch for a new/preview resource not yet in azurerm
resource "azapi_resource" "new_feature" {
  type      = "Microsoft.SomeRP/things@2025-01-01-preview"
  name      = "demo"
  parent_id = azurerm_resource_group.rg.id
  body = jsonencode({ properties = { sku = "standard" } })
}
```

## 15. Azure Example
```hcl
# RBAC + identity + diagnostics as code
resource "azurerm_user_assigned_identity" "app" {
  name = "id-app" resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
}
resource "azurerm_role_assignment" "kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

## 16. FastAPI / Python Example
```python
# Read Terraform outputs to configure the app (e.g., resource endpoints)
import json, subprocess
def tf_outputs():
    out = subprocess.check_output(["terraform", "output", "-json"])
    return {k: v["value"] for k, v in json.loads(out).items()}

@app.on_event("startup")
def load_infra():
    app.state.infra = tf_outputs()   # e.g., key_vault_uri, acr_login_server
```

## 17. AKS Example (Azure Verified Module style)
```hcl
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.3"
  name                = "prod-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  private_cluster_enabled = true
  managed_identities = { system_assigned = true }
}
```

## 18. How to Remember
**"azurerm for the norm, azapi for the new, OIDC for auth, AVM for a head start."** Pin + `features {}` always.

## 19. Real-World Analogy
Building with Azure is like construction with a certified catalog: azurerm is the standard approved parts catalog, AVM is the pre-engineered assemblies, and azapi is a special-order form for brand-new parts not yet in the catalog — all delivered by badge-access contractors (OIDC), no keys left lying around.

## 20. One-Page Cheat Sheet
- **Providers**: azurerm (main), azuread (Entra), **azapi** (new/preview APIs), random/tls.
- **Auth**: OIDC/managed identity (no secrets); `ARM_SUBSCRIPTION_ID`; provider `features {}` + pin versions.
- **Modules**: Azure Verified Modules / golden modules (CAF/WAF).
- **Patterns**: landing zones, hub-spoke, AKS+ACR+Key Vault, private endpoints, RBAC role assignments, diagnostics.
- **vs Bicep/ARM**: Terraform = multi-cloud + explicit state; Bicep = native, state-free.
- **New features**: `azapi_resource` now, migrate to azurerm later.
