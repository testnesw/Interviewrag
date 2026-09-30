# 66 · Terraform Best Practices

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
Terraform best practices are the habits that keep your infrastructure code clean, safe, and reliable — like organizing code well, reviewing changes before applying, keeping secrets out of code, and testing.

## 2. Architect-Level Explanation
Enterprise-grade Terraform combines structure, safety, and automation:
- **Structure**: shared versioned modules + thin per-env roots; consistent file layout (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`).
- **Version pinning**: pin Terraform core + provider + module versions for reproducibility.
- **State discipline**: remote, locked, encrypted, isolated per env/component.
- **Workflow**: PR-based; `fmt` → `validate` → `plan` (reviewed) → policy checks → gated `apply` in CI.
- **Secrets**: never in code/state-in-Git; use Key Vault / `TF_VAR_` / OIDC; mark outputs `sensitive`.
- **Policy-as-code**: OPA/Sentinel/Azure Policy + tfsec/checkov + Infracost in CI.
- **Idempotency & DRY**: modules, `for_each`, locals; avoid copy-paste.
- **Documentation**: `terraform-docs`, examples, changelogs; naming/tagging standards.
- **Testing**: `terraform test`, terratest for modules.
- **Least privilege** apply identity; small blast radius.

## 3. Real Enterprise Use Case
A platform team enforces a "paved road": golden modules, mandatory PR with automated `fmt/validate/plan`, tfsec + Infracost + OPA policy gates, secrets from Key Vault via OIDC, and a reviewed, approval-gated `apply` pipeline. Result: consistent, secure, cost-aware infra with a full audit trail.

## 4. Architecture Diagram (ASCII)
```
   PR ─► CI: fmt ─► validate ─► tflint/tfsec/checkov ─► plan
                         │ Infracost (cost diff) + OPA/Sentinel policy
                         ▼
                  Review + approval (prod gate)
                         ▼
                  apply (OIDC least-priv identity)
   Shared golden modules · pinned versions · remote locked state
   Secrets: Key Vault / TF_VAR (never in code)
```

## 5. Interview Questions
1. How do you structure a large Terraform codebase?
2. How do you keep secrets out of Terraform?
3. What checks do you run in CI before apply?
4. How do you enforce standards/policy?
5. How do you test Terraform?

## 6. Strong Interview Answers
- **Structure**: "Shared versioned modules for logic, thin per-env root modules for values, consistent file layout, and isolated state per env/component. Pin all versions for reproducibility."
- **Secrets**: "Never in `.tf` or committed state. I inject via `TF_VAR_` env, Key Vault data sources with a secure identity, or CI secret stores, and mark sensitive outputs. State itself is encrypted and access-controlled since it can hold secrets."
- **CI checks**: "`fmt` and `validate` for correctness, `tflint`/`tfsec`/`checkov` for lint/security, `plan` for the diff, Infracost for cost impact, and OPA/Sentinel policy gates — all before a reviewed, approval-gated apply."
- **Standards/policy**: "Golden modules bake in standards; policy-as-code (OPA/Sentinel/Azure Policy) enforces rules like allowed regions/SKUs, mandatory tags, no public exposure — failing the pipeline on violations."
- **Testing**: "`terraform test` and terratest to validate modules provision and behave correctly, plus plan-based checks in CI. Modules ship with examples that are tested."

## 7. Common Mistakes
- Unpinned versions → non-reproducible builds.
- Secrets in code or committed state.
- Applying without plan review / no approvals.
- Monolithic state and mega-modules.
- No policy/security/cost gates.
- Manual portal changes causing drift.

## 8. Trade-offs
| Practice | Pro | Con |
|----------|-----|-----|
| Strict gates | safe, compliant | slower changes |
| Many small states | isolation | more wiring |
| Policy-as-code | governance | upfront effort |

## 9. Production Best Practices
(Core) — pin versions; remote locked encrypted state; PR + `fmt/validate/plan`; tfsec/checkov + Infracost + OPA gates; secrets via Key Vault/OIDC; golden modules; naming/tagging; `terraform-docs`; tested modules; least-privilege apply identity.

## 10. Security Considerations
- No secrets in code/state-in-Git; encrypt state.
- Least-privilege apply identity (OIDC, scoped roles).
- Security scanning (tfsec/checkov) + policy gates.
- Enforce private endpoints/TLS via modules + policy.

## 11. Cost Optimization
- Infracost PR comments show cost deltas pre-merge.
- Modules enforce approved/right-sized SKUs.
- Policy blocks expensive/unapproved resources.

## 12. Troubleshooting Scenarios
- **Non-reproducible plan** → unpinned provider/module.
- **Secret leaked** → in code/state; rotate, move to Key Vault, restrict state.
- **Policy failing** → violates OPA/Azure Policy rule; fix config.
- **Drift** → manual change; reconcile, tighten access.
- **Slow CI** → monolithic state; split.

## 13. Hands-on Example
```bash
terraform fmt -check -recursive
terraform validate
tflint && tfsec . && checkov -d .
infracost breakdown --path .
terraform plan -out=tf.plan
```

## 14. Terraform Example
```hcl
# versions.tf — pin everything
terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
variable "db_password" { type = string sensitive = true }   # injected via TF_VAR_
output "conn" { value = local.conn sensitive = true }
```

## 15. Azure Example
```hcl
# Pull secret from Key Vault at plan/apply (no secret in code)
data "azurerm_key_vault_secret" "db" {
  name         = "db-password"
  key_vault_id = var.kv_id
}
# used as: password = data.azurerm_key_vault_secret.db.value
```

## 16. FastAPI / Python Example
```python
# CI gate: fail merge if plan adds disallowed public resources
import json, subprocess
def plan_json(dir="."):
    subprocess.run(["terraform", "plan", "-out=tf.plan"], cwd=dir, check=True)
    out = subprocess.check_output(["terraform", "show", "-json", "tf.plan"], cwd=dir)
    return json.loads(out)

@app.get("/policy/check")
def check():
    p = plan_json()
    bad = [c for c in p["resource_changes"]
           if c["change"]["after"].get("public_network_access_enabled")]
    return {"violations": [c["address"] for c in bad]}
```

## 17. AKS Example
The AKS golden module + OPA policy guarantee every cluster is private, RBAC-enabled, tagged, and uses approved node SKUs. A PR that tries a public cluster or an unapproved VM size fails the policy gate before apply — standards enforced automatically.

## 18. How to Remember
**"Pin, PR, plan, policy, protect secrets."** Golden modules + remote state + CI gates (fmt/validate/tfsec/Infracost/OPA) + least-privilege apply.

## 19. Real-World Analogy
A regulated manufacturing line: standardized parts (modules), version control on every component (pinning), QA inspection before shipping (plan + scans + policy), locked material store (state/secrets), and certified operators only (least-privilege identity) — quality and safety by process, not luck.

## 20. One-Page Cheat Sheet
- **Structure**: shared versioned modules + thin per-env roots; standard file layout.
- **Pin**: Terraform core + providers + modules.
- **State**: remote, locked, encrypted, isolated per env/component.
- **Workflow**: PR → fmt/validate → tflint/tfsec/checkov → plan → Infracost → OPA/Sentinel → gated apply.
- **Secrets**: Key Vault / TF_VAR / OIDC; never in code/state-in-Git; `sensitive` outputs.
- **Test + doc**: `terraform test`/terratest, `terraform-docs`; least-privilege apply identity.
