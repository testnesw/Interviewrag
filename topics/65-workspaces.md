# 65 · Terraform Workspaces & Environment Strategy

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
Workspaces let you use the **same Terraform code to manage multiple separate environments** (dev, staging, prod) — each with its own state — so you don't duplicate code for each environment.

## 2. Architect-Level Explanation
Workspaces provide multiple state instances for one configuration, but enterprise environment strategy goes further:
- **CLI workspaces**: `terraform workspace new/select` create isolated state files within one backend; `terraform.workspace` variable branches config. Good for lightweight variants; **not** ideal as the primary prod isolation mechanism (shared backend/creds, easy mistakes).
- **Directory/repo separation** (preferred for prod): separate root modules per env (`envs/dev`, `envs/prod`) with their own backend key, variables (`*.tfvars`), and pipeline — stronger isolation, different credentials/subscriptions, clearer blast radius.
- **Terraform Cloud/HCP workspaces**: first-class, with RBAC, variables, and separate runs — more robust than CLI workspaces.
- **Pattern**: shared modules + per-env root config + per-env state + per-env identity/subscription.
- Choose based on isolation needs, credentials separation, and team scale.

## 3. Real Enterprise Use Case
An enterprise uses shared golden modules with **separate env directories** (`envs/dev|stage|prod`), each with its own backend state key, `tfvars`, and Azure subscription + OIDC identity. Prod has stricter approvals. CLI workspaces are used only for ephemeral feature/PR environments spun up and destroyed automatically.

## 4. Architecture Diagram (ASCII)
```
   Shared modules (network, aks, sql)  ← DRY, versioned
        │ consumed by
   envs/dev/     envs/stage/     envs/prod/
     main.tf       main.tf         main.tf
     dev.tfvars    stage.tfvars    prod.tfvars
     state:dev     state:stage     state:prod     ← isolated state
     sub: dev      sub: stage      sub: prod      ← separate creds/subs
   CLI workspaces → only for ephemeral PR/feature envs
```

## 5. Interview Questions
1. What are Terraform workspaces?
2. CLI workspaces vs separate directories — which for prod?
3. How do you separate credentials per environment?
4. How do you avoid duplicating code across envs?
5. When are CLI workspaces a good fit?

## 6. Strong Interview Answers
- **Workspaces**: "CLI workspaces give you multiple state instances for the same config; `terraform.workspace` lets config branch by env. They're a lightweight way to run parallel state without copying code."
- **CLI vs dirs**: "For production I prefer separate env directories/repos: they allow different backends, credentials, subscriptions, and pipelines, with clearer blast radius. CLI workspaces share the same backend and creds, so a wrong `select` can hit prod — risky as the main isolation boundary."
- **Cred separation**: "Each env has its own identity/subscription and OIDC federation, so dev pipelines literally can't touch prod. That's hard to guarantee with CLI workspaces alone."
- **DRY**: "Shared versioned modules for the logic, thin per-env root modules with `tfvars` for differences — no duplication of resource definitions, only environment values differ."
- **CLI fit**: "Great for ephemeral, low-risk parallel environments — PR/preview envs, feature branches, testing — that share creds and are created/destroyed automatically."

## 7. Common Mistakes
- Using CLI workspaces as the only prod isolation (shared creds).
- Forgetting to `select` the right workspace → applying to wrong env.
- Copy-pasting whole configs per env (no modules).
- Same subscription/identity for all envs.
- Env-specific logic sprawled via many `terraform.workspace` conditionals.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| CLI workspaces | quick, DRY state | shared backend/creds, error-prone |
| Separate dirs | strong isolation | more scaffolding |
| TFC/HCP workspaces | RBAC, runs | cost/external |

## 9. Production Best Practices
- Shared modules + per-env root dirs + per-env state + per-env identity.
- Reserve CLI workspaces for ephemeral/preview envs.
- Per-env `tfvars`; no secrets in them (use Key Vault/CI vars).
- Stricter approvals + policy gates for prod.
- Automate ephemeral env create/destroy in CI.

## 10. Security Considerations
- Separate credentials/subscriptions per env (least privilege).
- Prod pipeline can't be triggered from lower envs.
- Guard against wrong-workspace applies (CI enforces env).
- Sensitive tfvars from secret stores, not Git.

## 11. Cost Optimization
- Ephemeral PR envs auto-destroyed (no idle cost).
- Right-size per env via tfvars (small dev, HA prod).
- Shared modules prevent costly drift/duplication.

## 12. Troubleshooting Scenarios
- **Applied to wrong env** → CLI workspace mis-select; enforce env in CI.
- **State mixed up** → workspace/backend key confusion.
- **Config branches unmanageable** → too many `terraform.workspace` ifs; move to dirs/tfvars.
- **Creds leaked across envs** → shared identity; separate them.

## 13. Hands-on Example
```bash
terraform workspace list
terraform workspace new pr-1234        # ephemeral preview env
terraform workspace select pr-1234
terraform apply -var-file=preview.tfvars
terraform workspace select default && terraform workspace delete pr-1234
```

## 14. Terraform Example
```hcl
# Lightweight branching by workspace (use sparingly)
locals {
  node_count = terraform.workspace == "prod" ? 5 : 2
}
resource "azurerm_kubernetes_cluster" "aks" {
  name = "aks-${terraform.workspace}"
  default_node_pool { name = "system" node_count = local.node_count vm_size = "Standard_D4s_v5" }
  # ...
}
```

## 15. Azure Example
```bash
# Per-env directory pattern with isolated backend + subscription
cd envs/prod
terraform init -backend-config=backend.prod.hcl
ARM_SUBSCRIPTION_ID=$PROD_SUB terraform apply -var-file=prod.tfvars
```

## 16. FastAPI / Python Example
```python
# Spin up an ephemeral PR environment via CLI workspace
import subprocess
@app.post("/env/preview/{pr}")
def preview(pr: str):
    ws = f"pr-{pr}"
    subprocess.run(["terraform", "workspace", "new", ws], check=False)
    subprocess.run(["terraform", "workspace", "select", ws], check=True)
    r = subprocess.run(["terraform", "apply", "-auto-approve",
                        "-var-file=preview.tfvars"], capture_output=True, text=True)
    return {"workspace": ws, "ok": r.returncode == 0}
```

## 17. AKS Example
Ephemeral AKS preview clusters per PR via CLI workspace (`pr-<n>`) using cheap spot node pools and `preview.tfvars`; the PR-close pipeline selects the workspace, runs `destroy`, and deletes it — zero lingering cost. Prod AKS lives in `envs/prod` with its own subscription/state.

## 18. How to Remember
**"CLI workspaces = quick parallel state (ephemeral); separate dirs = real prod isolation."** Shared modules + per-env tfvars keep it DRY.

## 19. Real-World Analogy
Workspaces are like using the same recipe (code) to cook separate meals in separate pots (state). But for a critical banquet (prod), you use a completely separate kitchen with its own staff and keys (separate dir + subscription/identity) so a mistake in the test kitchen can't ruin the main event.

## 20. One-Page Cheat Sheet
- **CLI workspaces**: multiple state instances for one config; `terraform.workspace` branches values.
- **Best for**: ephemeral/preview/feature envs (shared creds, auto create/destroy).
- **Prod isolation**: prefer **separate env dirs/repos** → own backend key, tfvars, subscription, identity, pipeline.
- **DRY**: shared versioned modules + thin per-env roots.
- **Guardrails**: prod can't be triggered from lower envs; stricter approvals/policy.
- **Avoid**: CLI workspaces as sole prod boundary; wrong-workspace applies.
