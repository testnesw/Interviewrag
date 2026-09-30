# 68 · Terraform Security & Policy-as-Code

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
Terraform security means making sure your infrastructure code doesn't create insecure resources, doesn't leak secrets, and follows your organization's rules — checked automatically before anything is deployed.

## 2. Architect-Level Explanation
Security spans the code, the state, the pipeline, and the deployed result:
- **Static scanning**: **tfsec / checkov / Terrascan** catch misconfigurations (public storage, open NSGs, no encryption) in CI.
- **Policy-as-code**: **OPA/Conftest**, **HashiCorp Sentinel**, or **Azure Policy** enforce guardrails (allowed regions/SKUs, mandatory tags, no public endpoints) — fail the pipeline on violation.
- **Secrets**: never in code/state-in-Git; inject via Key Vault/`TF_VAR_`/OIDC; mark `sensitive`; encrypt state (state holds plaintext secrets).
- **Least-privilege apply identity**: scoped, short-lived (OIDC) — not owner/global admin.
- **Supply chain**: pin provider/module versions + verify checksums (`.terraform.lock.hcl`); use trusted module sources; sign where possible.
- **Drift + audit**: detect out-of-band changes; log all applies.
- **Preventive vs detective**: block at plan (preventive) and continuously audit deployed resources (detective, Defender/Azure Policy).

## 3. Real Enterprise Use Case
A regulated company gates every PR with tfsec + checkov + OPA policies (no public IPs, TLS required, tags mandatory, approved regions), injects secrets from Key Vault via OIDC, pins and checksum-verifies modules, and applies with a least-privilege federated identity. Azure Policy continuously audits deployed resources — preventive + detective defense-in-depth.

## 4. Architecture Diagram (ASCII)
```
   PR ─► tfsec / checkov (misconfig) ─► OPA/Sentinel (org policy)
                         │ block on violation (preventive)
                         ▼
              plan review + approval
                         ▼
        apply (OIDC least-privilege, short-lived)
   Secrets: Key Vault / TF_VAR (never in code/state-in-Git)
   Deployed ─► Azure Policy + Defender (detective/audit) ─► drift alerts
   Pinned + checksum-locked providers/modules (supply chain)
```

## 5. Interview Questions
1. How do you prevent insecure infrastructure in Terraform?
2. What is policy-as-code and which tools?
3. How do you protect secrets and state?
4. Preventive vs detective controls?
5. How do you secure the Terraform supply chain?

## 6. Strong Interview Answers
- **Prevent misconfig**: "Static scanners (tfsec/checkov) in CI catch things like public storage, open NSGs, or unencrypted resources, plus policy-as-code enforces org rules — all failing the pipeline before apply."
- **Policy-as-code**: "Rules expressed as code — OPA/Conftest against the plan JSON, Sentinel in TFC, or Azure Policy at the platform. They enforce allowed SKUs/regions, mandatory tags, no public exposure, and block violations automatically and consistently."
- **Secrets/state**: "Secrets never in `.tf` or committed state. Inject via Key Vault data sources, `TF_VAR_` env, or OIDC; mark sensitive outputs. State is encrypted, access-controlled, and never in Git because it stores plaintext secrets."
- **Preventive vs detective**: "Preventive controls block bad config at plan/apply (scanners, policy gates); detective controls (Azure Policy audit, Defender, drift detection) continuously verify deployed resources stay compliant. I use both."
- **Supply chain**: "Pin provider and module versions, commit `.terraform.lock.hcl` with checksums, source modules only from trusted registries, review upgrades, and rebuild on security patches — so a compromised or drifting dependency can't slip in."

## 7. Common Mistakes
- Secrets in code or committed state.
- No scanning/policy gates (insecure infra ships).
- Over-privileged apply identity (owner).
- Unpinned/unverified modules and providers.
- Only preventive or only detective — not both.

## 8. Trade-offs
| Control | Pro | Con |
|---------|-----|-----|
| Preventive gates | stops issues early | can slow delivery |
| Detective audit | catches drift | after-the-fact |
| Strict policy | compliance | friction/exceptions |

## 9. Production Best Practices
- tfsec/checkov + OPA/Sentinel/Azure Policy gates in CI.
- Secrets via Key Vault/OIDC; encrypt + lock down state.
- Least-privilege, short-lived apply identity (OIDC).
- Pin + checksum-lock providers/modules; trusted sources.
- Preventive (plan) + detective (Azure Policy/Defender) + drift detection.

## 10. Security Considerations
- Enforce private endpoints, TLS, encryption, no public exposure via policy.
- Mandatory tags/naming for governance.
- Audit all applies; alert on drift.
- Rotate/scope credentials; no standing admin access.

## 11. Cost Optimization
- Policy blocks expensive/unapproved SKUs.
- Infracost gate on cost deltas.
- Prevent misconfig-driven waste (orphaned public IPs, oversized disks).

## 12. Troubleshooting Scenarios
- **Scanner failure** → misconfig flagged (e.g., public blob); fix config.
- **Policy denial** → violates OPA/Azure Policy; adjust or request exception.
- **Secret in plan/state** → rotate, move to Key Vault, restrict state.
- **Checksum mismatch** → `.terraform.lock.hcl` vs provider; re-init/verify source.
- **Drift alert** → manual change; reconcile + tighten RBAC.

## 13. Hands-on Example
```bash
tfsec .
checkov -d .
terraform plan -out=tf.plan && terraform show -json tf.plan > plan.json
conftest test plan.json          # OPA policies
```

## 14. Terraform Example
```hcl
# Secure-by-default: private, encrypted, no public access
resource "azurerm_storage_account" "sa" {
  name                            = "stsecuredemo"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = "eastus"
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false      # tfsec/policy-friendly
  tags = { env = "prod", owner = "platform" }  # mandatory tags
}
```

## 15. Azure Example
```hcl
# Enforce org rule at platform level (detective/preventive)
resource "azurerm_policy_assignment" "no_public_ip" {
  name                 = "deny-public-ip"
  scope                = data.azurerm_management_group.root.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<deny-public-ip>"
}
```

## 16. FastAPI / Python Example
```python
# CI policy gate over plan JSON (deny public network access)
import json
def evaluate(plan_path="plan.json"):
    plan = json.load(open(plan_path))
    violations = []
    for c in plan["resource_changes"]:
        after = c["change"]["after"] or {}
        if after.get("public_network_access_enabled") is True:
            violations.append(c["address"])
    return violations

@app.get("/policy/plan")
def gate():
    v = evaluate()
    return {"pass": not v, "violations": v}   # non-empty → fail pipeline
```

## 17. AKS Example (OPA/Conftest rule for Terraform plan)
```rego
package terraform.aks
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_kubernetes_cluster"
  rc.change.after.private_cluster_enabled == false
  msg := sprintf("AKS %v must be a private cluster", [rc.address])
}
```

## 18. How to Remember
**"Scan, Policy, Protect secrets, Least-privilege, Pin — preventive + detective."** Block bad config at plan; audit deployed resources continuously.

## 19. Real-World Analogy
Airport security: bags are screened before boarding (tfsec/policy = preventive), only authorized staff with temporary badges access secure areas (OIDC least-privilege), valuables are stored in a locked safe (Key Vault/encrypted state), and cameras continuously monitor the terminal (Azure Policy/Defender = detective).

## 20. One-Page Cheat Sheet
- **Scan**: tfsec/checkov/Terrascan for misconfig in CI.
- **Policy-as-code**: OPA/Conftest, Sentinel, Azure Policy — block violations (regions/SKUs/tags/no-public).
- **Secrets/state**: Key Vault/TF_VAR/OIDC; never in code/Git; encrypt + lock state.
- **Identity**: least-privilege, short-lived (OIDC) apply.
- **Supply chain**: pin + checksum-lock (`.terraform.lock.hcl`), trusted sources.
- **Layers**: preventive (plan gates) + detective (Azure Policy/Defender/drift).
