# DEEP MECHANICS · Terraform on Azure (azurerm)

> Level 2 — the azurerm provider, authentication, state on Azure, and Terraform
> vs Bicep.

---

## 0. The precise mental model
Terraform manages Azure via the **`azurerm` provider**, which calls **Azure Resource Manager (ARM) REST APIs**. Auth is ideally **keyless (Managed Identity / OIDC)**; state lives in an **Azure Storage blob** with locking. For resources the provider doesn't support yet, use the **`azapi` provider** (raw ARM).

---

## 1. Provider & authentication
```hcl
terraform {
  required_providers { azurerm = { source = "hashicorp/azurerm", version = "~>3.0" } }
}
provider "azurerm" { features {} subscription_id = var.sub_id }
```
Auth methods (best → worst):
- **OIDC / Workload Identity Federation** in CI — no stored secrets (recommended for GitHub Actions/Azure DevOps).
- **Managed Identity** when Terraform runs on Azure compute.
- **Service Principal** (client secret/cert) — stored credential, rotate.
- **Azure CLI** (`az login`) — local dev only.

## 2. State on Azure
- Backend = **`azurerm`** → blob in a Storage Account container.
- **Locking** via blob lease (automatic); **encryption at rest**; enable **versioning** + soft delete for recovery.
- Protect with **RBAC**, **private endpoint**, firewall. State holds secrets in plaintext.

## 3. azapi provider
- `azapi` calls ARM directly → supports **brand-new / preview** resource types before `azurerm` does.
- Mix `azurerm` (mature resources) + `azapi` (new features) in the same config.

## 4. Terraform vs Bicep (on Azure)
| | Terraform | Bicep |
|---|---|---|
| Scope | Multi-cloud + Azure | Azure only |
| State | External (blob) | Stateless (reads ARM) |
| Language | HCL | Bicep DSL (→ ARM JSON) |
| Drift | `plan` vs state | what-if vs live |
| Ecosystem | Huge (modules, providers) | Azure-native, MS-supported |
- **Bicep** for Azure-only shops wanting native tooling + no state to manage.
- **Terraform** for multi-cloud, existing TF skills, richer module ecosystem.

## 5. Common patterns
- **Resource naming** via `azurecaf` or naming modules; consistent **tags**.
- Use **AVM (Azure Verified Modules)** — MS-published, tested modules.
- Data sources to read existing resources (e.g., Key Vault secret, subnet).

## 6. The hard follow-ups (with answers)
1. **"How does azurerm talk to Azure?"** → ARM REST APIs. (§0)
2. **"Best auth for CI?"** → **OIDC/workload identity federation** — keyless. (§1)
3. **"Where's state and how is it locked?"** → blob in Storage; **blob-lease locking**, encrypted, versioned, RBAC-protected. (§2)
4. **"New Azure resource not in azurerm yet?"** → use **`azapi`** provider. (§3)
5. **"Terraform or Bicep?"** → Bicep = Azure-only native/stateless; Terraform = multi-cloud + state + ecosystem. (§4)
6. **"Trusted modules?"** → **Azure Verified Modules (AVM)**. (§5)

## 7. One-screen recall
- **Provider** `azurerm` → **ARM REST**; `features {}` block required.
- **Auth**: **OIDC** (CI) > **Managed Identity** (on Azure) > SP secret > az CLI (local).
- **State**: blob container, **lease lock**, encrypted, versioned, RBAC + private endpoint.
- **`azapi`**: raw ARM for preview/new resources.
- **vs Bicep**: Bicep = Azure-only, stateless, native; Terraform = multi-cloud, state, big ecosystem.
- **AVM** = trusted MS modules.

> Next: Terraform security.
