# 62 · Terraform State Management

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
Terraform "state" is a file that records what infrastructure Terraform has created and how it maps to your code. It's how Terraform knows what already exists so it can plan changes correctly.

## 2. Architect-Level Explanation
State is Terraform's source of truth mapping config ↔ real resources:
- **Purpose**: track resource IDs/metadata, compute diffs, store dependencies, cache attributes, and enable performance (avoid re-reading everything).
- **Sensitive**: state can contain secrets (passwords, keys) in plaintext → must be encrypted and access-controlled.
- **Operations**: `state list/show/mv/rm`, `import` (adopt existing resources), `taint`/`-replace` (force recreation), `refresh` (reconcile with real world).
- **Drift**: when real infra changes outside Terraform, `plan` detects the delta.
- **Locking**: prevents concurrent applies corrupting state (needs a backend that supports it).
- **Isolation**: separate state per environment/component to limit blast radius and speed plans.
- **Never hand-edit** state JSON — use state commands.

## 3. Real Enterprise Use Case
A team splits state by layer (networking, platform, apps) and environment, each in its own remote backend with locking. When someone manually resizes a VM in the portal, the next `plan` flags the drift; they either import the change or let Terraform reconcile — keeping code as the single source of truth.

## 4. Architecture Diagram (ASCII)
```
   HCL config ──┐
                ▼
        [ Terraform ]  ── compares ──►  Real Azure resources
                │                              ▲
                ▼                              │ refresh
        State (JSON)  ── maps config↔real, holds IDs/attrs (SENSITIVE)
   Ops: import (adopt) · mv (refactor) · rm (forget) · -replace (recreate)
   Drift = plan shows changes you didn't write
```

## 5. Interview Questions
1. What does state contain and why is it needed?
2. Why is state sensitive?
3. How do you import existing resources?
4. What is drift and how do you handle it?
5. When would you use `state mv` / `state rm` / `-replace`?

## 6. Strong Interview Answers
- **Contents/why**: "State maps your config to real resource IDs and caches attributes and dependencies. Without it Terraform couldn't tell what it already manages or compute an accurate diff."
- **Sensitive**: "State stores resource attributes in plaintext — including secrets like generated passwords or connection strings — so it must be encrypted at rest, access-controlled, and never committed to Git."
- **Import**: "`terraform import` (or `import` blocks) adopts an existing resource into state so Terraform manages it going forward — I write the matching HCL, import, then `plan` should show no changes."
- **Drift**: "Drift is out-of-band changes to real infra. `plan`/`refresh` detects it; I either update the code to match, let apply revert it, or import intentional changes. Policy is: code is the source of truth."
- **State ops**: "`state mv` for refactoring (renaming/moving resources or into modules) without destroy/recreate; `state rm` to stop managing without deleting; `-replace` (formerly taint) to force recreation of a specific resource."

## 7. Common Mistakes
- Committing state to Git (leaks secrets).
- Hand-editing state JSON.
- One giant state for everything (slow, risky).
- Ignoring drift.
- Deleting resources from cloud without `state rm` → stale state errors.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Single state | simple | large blast radius, slow |
| Split state | isolation, fast | cross-state references |
| Import vs recreate | preserves resource | tedious mapping |

## 9. Production Best Practices
- Remote, encrypted, locked backend (topic 63).
- Split state per env + component.
- Use `import` for existing resources; never hand-edit.
- Review drift regularly (scheduled `plan`).
- Back up / version state (blob versioning).

## 10. Security Considerations
- Encrypt state at rest; restrict backend RBAC.
- Treat state as secret material; never in Git/logs.
- Mark sensitive outputs `sensitive = true`.
- Audit access to the state store.

## 11. Cost Optimization
- Smaller, split states → faster plans (less CI time).
- Drift detection catches costly manual resources.
- Avoid needless `-replace` (recreation can be expensive).

## 12. Troubleshooting Scenarios
- **"Resource already exists"** → import it into state.
- **Stale/deleted resource** → `state rm` or refresh.
- **Refactor caused destroy/recreate** → use `state mv` / `moved` blocks.
- **Lock error** → verify no active run, then `force-unlock <id>`.
- **Unexpected diffs** → drift; reconcile.

## 13. Hands-on Example
```bash
terraform state list
terraform import azurerm_resource_group.rg /subscriptions/<sub>/resourceGroups/rg-demo
terraform state mv azurerm_storage_account.a module.storage.azurerm_storage_account.a
terraform apply -replace=azurerm_linux_virtual_machine.vm
```

## 14. Terraform Example
```hcl
# Modern import block (declarative import, plannable)
import {
  to = azurerm_resource_group.rg
  id = "/subscriptions/${var.sub}/resourceGroups/rg-demo"
}
resource "azurerm_resource_group" "rg" {
  name     = "rg-demo"
  location = "eastus"
}

# Refactor safely without destroy/recreate
moved {
  from = azurerm_storage_account.old
  to   = azurerm_storage_account.new
}
```

## 15. Azure Example
```bash
# Inspect a sensitive value stored in state (be careful)
terraform state show azurerm_key_vault_secret.db | grep -i value
# Enable blob versioning on the state container for recovery (see topic 63)
```

## 16. FastAPI / Python Example
```python
# Drift-detection endpoint: run plan and flag changes
import subprocess
@app.get("/infra/drift")
def drift(dir: str):
    r = subprocess.run(["terraform", "plan", "-detailed-exitcode", "-no-color"],
                       cwd=dir, capture_output=True, text=True)
    # exit 0 = no drift, 2 = drift present, 1 = error
    return {"drift": r.returncode == 2, "code": r.returncode}
```

## 17. AKS Example
```bash
# Adopt an existing AKS cluster into Terraform management
terraform import azurerm_kubernetes_cluster.aks \
  /subscriptions/<sub>/resourceGroups/rg-aks/providers/Microsoft.ContainerService/managedClusters/prod-aks
terraform plan   # should show no changes if HCL matches
```

## 18. How to Remember
**"State = map of code ↔ reality (and it holds secrets)."** Never commit it, never hand-edit it; use import/mv/rm/-replace.

## 19. Real-World Analogy
An inventory ledger for a warehouse: it records exactly what's on the shelves and where. If someone moves stock without updating the ledger (manual change), the next audit (plan) flags the mismatch (drift). You never scribble in the ledger by hand — you use proper procedures.

## 20. One-Page Cheat Sheet
- **State**: JSON mapping config ↔ real resources; holds IDs + attributes (**sensitive**).
- **Never**: commit to Git, hand-edit.
- **Ops**: `import` (adopt), `state mv` (refactor), `state rm` (forget), `-replace` (recreate), `refresh`.
- **Drift**: out-of-band changes; `plan` detects → reconcile.
- **Isolate**: per env + component to limit blast radius, speed plans.
- **Secure**: encrypted, locked, RBAC-restricted remote backend.
