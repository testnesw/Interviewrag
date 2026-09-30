# 61 · Terraform Fundamentals

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
Terraform lets you define your infrastructure (VMs, networks, databases) as **code** in text files. You describe what you want; Terraform figures out how to create, change, or delete it — consistently and repeatably.

## 2. Architect-Level Explanation
Terraform is a declarative, cloud-agnostic IaC tool:
- **Declarative**: you describe desired *state*; Terraform computes the diff vs actual and reconciles (unlike imperative scripts).
- **HCL**: HashiCorp Configuration Language — resources, variables, outputs, data sources, locals, expressions.
- **Core workflow**: `init` (download providers/backend) → `plan` (preview diff) → `apply` (execute) → `destroy`.
- **Providers**: plugins (azurerm, aws, kubernetes) translate HCL to API calls.
- **State**: a JSON file mapping config → real resources; the source of truth for diffs.
- **Dependency graph**: Terraform builds a DAG from references and parallelizes creation respecting dependencies.
- **Idempotent**: re-applying an unchanged config = no changes.
- **OpenTofu**: open-source fork after the license change — API-compatible alternative.

## 3. Real Enterprise Use Case
A platform team manages all Azure infrastructure (landing zones, AKS, networking, databases) as Terraform in Git. Every change goes through PR + `plan` review + policy checks + automated `apply` in CI — giving auditable, repeatable, drift-controlled infrastructure across dev/stage/prod.

## 4. Architecture Diagram (ASCII)
```
   HCL (.tf) ─► terraform init (providers + backend)
        │
     plan  ─► diff: desired vs state vs real  ─► review
        │
     apply ─► provider API calls (azurerm) ─► Azure resources
        │
     state (JSON) ◄── records what exists (source of truth)
   Dependency graph (DAG) parallelizes with correct ordering
```

## 5. Interview Questions
1. Declarative vs imperative IaC?
2. Explain the init/plan/apply workflow.
3. What is a provider and a resource?
4. What is a data source vs a resource?
5. What makes Terraform idempotent?

## 6. Strong Interview Answers
- **Declarative vs imperative**: "Declarative means I define the desired end state and Terraform computes the steps to reach it; imperative (like a shell script) specifies each step. Declarative is idempotent and self-healing toward desired state."
- **Workflow**: "`init` sets up providers and the backend; `plan` shows the diff between desired config, recorded state, and real infrastructure without changing anything; `apply` executes that plan; `destroy` tears down. Plan is my safety gate."
- **Provider/resource**: "A provider is a plugin that knows how to talk to an API (azurerm for Azure); a resource is a managed object (a VNet, an AKS cluster) declared in HCL."
- **Data source vs resource**: "A resource is something Terraform *manages* (creates/updates/destroys); a data source *reads* existing data (an existing resource group, current subscription) to reference without managing it."
- **Idempotent**: "State + declarative diffing — Terraform compares desired vs recorded vs actual, so re-applying an unchanged config yields no changes. It converges to the declared state."

## 7. Common Mistakes
- Editing infra manually → drift from state.
- Applying without reviewing `plan`.
- Local state on a laptop (no locking/sharing).
- Hardcoding secrets in `.tf` files.
- Giant monolithic root modules.

## 8. Trade-offs
| Aspect | Terraform | Native (ARM/Bicep) |
|--------|-----------|--------------------|
| Multi-cloud | yes | Azure-only |
| State | external (manage it) | Azure-managed |
| Ecosystem | huge | Azure-tight |

## 9. Production Best Practices
- Remote state + locking (see topic 63).
- PR-based workflow: plan in CI, reviewed apply.
- Modules for reuse; pin provider + Terraform versions.
- No secrets in code (Key Vault / env / TF_VAR).
- `fmt`, `validate`, and policy checks in CI.

## 10. Security Considerations
- Never commit secrets or state (state holds sensitive values).
- Least-privilege identity for apply (managed identity/OIDC).
- Encrypt state; restrict backend access.
- Scan with tfsec/checkov; policy-as-code (see topic 68).

## 11. Cost Optimization
- `plan` reveals what will be created (catch costly resources).
- Integrate Infracost for cost diffs in PRs.
- Modules enforce right-sized, approved SKUs.

## 12. Troubleshooting Scenarios
- **Drift** → `terraform plan` shows unexpected changes (manual edits).
- **Provider errors** → version mismatch; pin versions.
- **State lock stuck** → `force-unlock` after verifying no active run.
- **Dependency cycle** → refactor references / use `depends_on`.
- **Wrong resource replaced** → check plan for forced replacement (`~`/`-/+`).

## 13. Hands-on Example
```bash
terraform init
terraform fmt && terraform validate
terraform plan -out=tf.plan
terraform apply tf.plan
```

## 14. Terraform Example
```hcl
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
provider "azurerm" { features {} }

resource "azurerm_resource_group" "rg" {
  name     = "rg-demo"
  location = "eastus"
}

data "azurerm_client_config" "current" {}   # data source: read, not manage
output "subscription_id" { value = data.azurerm_client_config.current.subscription_id }
```

## 15. Azure Example
```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
terraform apply    # azurerm uses Azure CLI / env creds
```

## 16. FastAPI / Python Example
```python
# Trigger a plan from an internal platform API (self-service infra)
import subprocess
@app.post("/infra/plan")
def plan(dir: str):
    r = subprocess.run(["terraform", "plan", "-no-color"],
                       cwd=dir, capture_output=True, text=True)
    return {"exit": r.returncode, "output": r.stdout[-4000:]}
```

## 17. AKS Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "demo-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "demoaks"
  default_node_pool { name = "system" node_count = 2 vm_size = "Standard_D4s_v5" }
  identity { type = "SystemAssigned" }
}
```

## 18. How to Remember
**"init → plan → apply."** Declare desired state; Terraform diffs against state and reconciles. Plan is your safety net.

## 19. Real-World Analogy
A building blueprint (HCL) plus a smart contractor (Terraform): you specify the finished building, the contractor compares it to what's already built (state), and only constructs/changes what's different — no rebuilding what already matches.

## 20. One-Page Cheat Sheet
- **What**: declarative, cloud-agnostic IaC in HCL.
- **Workflow**: init → plan (diff, safe) → apply → destroy.
- **Concepts**: providers (API plugins), resources (managed), data sources (read-only), state (source of truth), DAG (ordering).
- **Idempotent**: re-apply unchanged = no changes.
- **Prod**: remote state + locking, PR plan review, modules, pinned versions, no secrets in code.
- **Alt**: OpenTofu (open-source fork).
