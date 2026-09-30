# Deep Dive · Terraform

> Phase 4 (Delivery / IaC) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Terraform is **HashiCorp's Infrastructure-as-Code** tool: you declare desired infrastructure in **HCL**, and Terraform computes a **plan** (diff between desired and actual, tracked in **state**) and **applies** it via **providers** (Azure, AWS, K8s…). It's **declarative, cloud-agnostic, and stateful** — the state file is the source of truth mapping config to real resources. In enterprise/Azure it's the standard for provisioning landing zones, AKS, networking, and GenAI infra reproducibly, with **remote state, modules, and CI/CD**.

---

## 2. Architect-Level Explanation
Core concepts:
- **HCL config** declares resources; Terraform builds a **dependency graph** and reconciles.
- **State** (`terraform.tfstate`): maps config → real-world IDs; enables diffing, drift detection. **Must be remote + locked** for teams (Azure Storage backend with blob lease locking).
- **Providers**: plugins (azurerm, azuread, kubernetes, helm) translate HCL → API calls.
- **Plan/Apply**: `plan` = preview diff; `apply` = execute; `destroy` = teardown.
- **Modules**: reusable, versioned building blocks (a "VNet module", "AKS module") → DRY, standardized.
- **Workspaces / directory-per-env**: isolate dev/stage/prod state.
- **Terraform vs Bicep/ARM**: Terraform is **multi-cloud + rich module ecosystem + explicit state**; Bicep is **Azure-native, stateless (uses ARM as source of truth), first-party**.

Architecturally: **declarative, plan-before-apply, state-driven, modular** provisioning integrated into CI/CD (GitOps for infra).

---

## 3. Why It Exists
- **Problem**: click-ops is unrepeatable, undocumented, drift-prone, and un-auditable; scripts are imperative and brittle.
- **Breakthrough**: **declarative desired state + plan preview + state tracking** → predictable, reviewable, reproducible infra.
- **Why enterprises adopt it**: version-controlled infra, peer-reviewed changes (PRs), consistent environments, drift detection, and multi-cloud portability.
- **Why Terraform over ARM/Bicep sometimes**: multi-cloud, mature modules (registry), explicit plan/state, large community.

---

## 4. Internal Working
**Lifecycle:**
```
1. init   → download providers + configure backend (remote state)
2. plan   → refresh state, build dependency graph, diff desired vs actual → change set
3. apply  → execute changes in dependency order via provider APIs, update state (locked)
4. destroy→ remove managed resources
```
Key mechanics:
- **State locking** (blob lease) prevents concurrent corrupting applies.
- **Dependency graph**: implicit (references) + explicit (`depends_on`) ordering; parallelizes independent resources.
- **Resource addressing**: `type.name`; `import` brings existing resources under management.
- **Drift**: `plan` shows out-of-band changes; re-apply reconciles.
- **Sensitive values**: marked sensitive but **stored in state** → state must be encrypted + access-controlled.

---

## 5. Enterprise Use Case
A platform team manages the **Azure Landing Zone + GenAI infra** entirely in Terraform: reusable modules for VNet, AKS, AOAI, APIM, Key Vault, and RBAC. **Remote state** in Azure Storage (per-env, locked), changes via **PR + `plan` in CI**, applied by a pipeline using **Workload Identity/OIDC** (no stored cloud creds). New environments/regions spin up from the same modules → identical, compliant, auditable infrastructure, and drift is caught in scheduled plans.

---

## 6. Real Production Architecture
```
 Dev ─► PR (HCL change) ─► CI: fmt · validate · tflint · tfsec · plan (comment on PR)
                                         │ (review + approve)
                                         ▼
                        CD: terraform apply (OIDC to Azure, no secrets)
                                         │
        Remote State (Azure Storage, per-env, blob-lease lock, encrypted)
                                         │
        Modules (registry/git, versioned): vnet · aks · aoai · apim · kv · rbac
                                         ▼
                     Azure resources (dev / stage / prod)
```

---

## 7. Security Best Practices
- **Protect state**: remote backend (Azure Storage) with **encryption, private endpoint, RBAC, versioning** — state contains secrets.
- **No cloud creds in pipelines**: use **OIDC/Workload Identity federation** (GitHub/Azure DevOps → Entra) — passwordless.
- **No secrets in HCL/state where avoidable**: pull from **Key Vault** at runtime; mark sensitive; never commit `.tfvars` secrets.
- **Policy-as-code scanning**: `tfsec`/`checkov`/Terraform + **Azure Policy** to catch misconfig pre-apply.
- **Least-privilege** apply identity (scoped to what it manages).
- **Module pinning** (versions) + provider version constraints; review third-party modules.
- **Plan review gates** (PR approval) before apply.

---

## 8. Scaling Strategy
- **Modules** for reuse/standardization; **module registry** for org-wide sharing.
- **State segmentation**: split by layer/lifecycle (network vs app) and env → smaller blast radius, faster plans; wire with **remote state data sources** or **terragrunt**.
- **Directory-per-environment** (preferred) over workspaces for clarity.
- **Parallelism** + targeted plans for large estates.
- **Automation** (Atlantis/Terraform Cloud/CI) for many teams.

---

## 9. High Availability Strategy
- **Remote state HA**: Azure Storage (zone/geo-redundant) with versioning for recovery.
- **State locking** ensures safe concurrent operations.
- Terraform provisions **HA infra** (zonal resources, multi-region) — HA is a property of *what you deploy*.
- **CI/CD redundancy** so applies aren't blocked by a single runner.

---

## 10. Disaster Recovery Strategy
- **State is critical**: geo-redundant storage + **versioning + backups**; ability to restore a prior state.
- **Code in Git** → rebuild any environment from modules in a new region.
- **`import`** to recover management of resources if state is lost (last resort).
- Document RTO/RPO for infra recreation; test full rebuild in a sandbox.

---

## 11. Cost Optimization Strategy
- **Infracost** in PRs → show cost delta before apply.
- **Modules encode right-sizing** + tags for chargeback.
- **Destroy ephemeral envs** (PR/preview) automatically to stop spend.
- **Policy** to deny expensive SKUs; **enforce tags** for cost allocation.
- Plan-driven change review avoids accidental costly resources.

---

## 12. Common Production Challenges
- **State conflicts/corruption** → remote state + locking; never edit state by hand (use `state` commands).
- **Drift** from manual portal changes → scheduled `plan`, enforce IaC-only.
- **Secrets in state** → encrypt state, restrict access, minimize secrets in config.
- **Large monolithic state** → slow plans, big blast radius → segment.
- **Provider/version drift** → pin versions; test upgrades.
- **Destroy accidents** → prevent with `prevent_destroy`, approvals, plan review.
- **Import complexity** for brownfield → careful, incremental import.

---

## 13. Monitoring and Observability
- **Plan output as the audit trail** (what changed, by whom, via PR).
- **CI logs** of plan/apply; **state versioning** as history.
- **Drift detection** scheduled plans → alert on unexpected diffs.
- **tfsec/checkov + Infracost** reports in PR checks.
- Tag resources for downstream cost/inventory monitoring.

---

## 14. Troubleshooting Scenarios
- **"State locked"** → a stuck apply holds the lease; verify no running job, then `force-unlock` carefully.
- **Plan wants to recreate a resource** → an immutable attribute changed; check the diff, use `lifecycle`/`moved`/import to avoid destroy.
- **Drift shown** → someone changed the portal; decide to re-apply (revert) or `import`/update config.
- **Provider auth fails in CI** → OIDC federation subject/audience misconfig; verify federated credential.
- **Secret leaked in state** → rotate secret, restrict/encrypt state, remove from config.
- **Apply half-failed** → state partially updated; re-run plan/apply (idempotent) after fixing root cause.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Terraform vs Bicep | multi-cloud, modules, explicit state | state to manage |
| Monolith vs split state | simple | big blast radius vs wiring overhead |
| Workspaces vs dir-per-env | DRY | less clear vs duplication |
| Third-party modules | speed | trust/maintenance |

---

## 16. When NOT to use it
- **Azure-only shop wanting first-party, stateless IaC** → **Bicep** may be simpler (no state to manage).
- **One-off throwaway resource** → CLI/portal may be faster.
- **App/config deployment** (vs infra) → use K8s/GitOps/Helm, not Terraform for app rollouts.
- **Highly dynamic per-request infra** → not Terraform's model.

---

## 17. Comparison with Alternatives
| Tool | Model | Scope | Best for |
|------|-------|-------|----------|
| **Terraform** | declarative, stateful | multi-cloud | portable IaC, modules |
| Bicep/ARM | declarative, stateless | Azure | Azure-native, first-party |
| Pulumi | declarative (real langs) | multi-cloud | code-first teams |
| Ansible | procedural/config | config mgmt | server config, not provisioning-first |
| CloudFormation | declarative | AWS | AWS-native |

---

## 18. Interview Questions
1. What is Terraform state and why does it matter?
2. Plan vs apply vs destroy?
3. How do you manage state for a team?
4. Modules — why and how?
5. Terraform vs Bicep vs ARM?
6. How do you handle secrets in Terraform?
7. How do you do CI/CD for Terraform securely?
8. How do you prevent/detect drift?
9. How do you structure state at scale?
10. How do you recover from lost/corrupt state?

---

## 19. Strong Interview Answers
- **State**: "State maps your config to real resource IDs — it's how Terraform diffs desired vs actual. For teams it must be remote and locked (Azure Storage with blob-lease locking) and encrypted, because it can contain secrets. Never hand-edit it; use `state` commands."
- **Team workflow**: "Remote locked state per environment, changes via PR with `plan` posted as a check, security scanning (tfsec) and cost (Infracost) gates, then a pipeline applies using OIDC federation — no stored cloud credentials."
- **Modules**: "Versioned, reusable building blocks that encode standards (naming, tags, security). A team consumes a `aks` module instead of reinventing it — DRY, consistent, and auditable across environments."
- **Terraform vs Bicep**: "Terraform is multi-cloud with a huge module ecosystem and explicit state; Bicep is Azure-native and stateless (ARM is the source of truth), so no state to secure. Azure-only shops may prefer Bicep; multi-cloud or module-heavy orgs prefer Terraform."
- **Drift**: "Scheduled `plan` detects out-of-band changes; I enforce IaC-only (deny portal changes via process/policy) and re-apply to reconcile, or `import`/update config if the change should be kept."

---

## 20. Architecture Diagrams
**Plan/apply with remote state:**
```
HCL (Git) ─► init (providers+backend) ─► plan (state diff) ─► review(PR) ─► apply (OIDC)
                                   │                                   │
                          Remote State (encrypted, locked) ◄──────────┘
Modules (versioned) compose the resource graph
```

---

## 21. Real Project Example
**Landing-zone + GenAI infra as modules.** ~15 versioned modules (vnet, hub-firewall, aks, aoai, apim, kv, rbac, monitoring). State is split by layer (platform/network vs app) and env, in geo-redundant Azure Storage with locking. PRs run fmt/validate/tflint/tfsec/Infracost and post a plan; apply runs via GitHub OIDC to Entra (zero secrets). Spinning up a new region = instantiate the same modules with different vars → identical, compliant infra in under an hour. Scheduled drift plans alert on any manual change.

---

## 22. Whiteboard Design Question
> *"Design a secure Terraform delivery pipeline for a 10-team enterprise Azure estate."*

Cover: repo/module strategy (versioned module registry) → state design (remote, locked, encrypted, segmented by layer/env) → PR workflow (fmt/validate/tflint/tfsec/checkov/Infracost + plan comment) → OIDC federation (no cloud creds) → least-privilege apply identity → approval gates + `prevent_destroy` → drift detection (scheduled plans) → secrets from Key Vault → DR (geo-redundant versioned state, Git rebuild). Emphasize state security and blast-radius control.

---

## 23. Design Review Questions
- Is **state remote, locked, encrypted, access-controlled**?
- **OIDC/federation** for pipeline auth (no stored cloud secrets)?
- Is state **segmented** to limit blast radius?
- **Security + cost scanning** (tfsec/checkov/Infracost) gating PRs?
- **Modules versioned + pinned**; providers pinned?
- **Secrets** kept out of config/state (Key Vault)?
- **Drift detection** scheduled? **Destroy protections** in place?
- **DR**: state backup/versioning + rebuild-from-Git tested?

---

## 24. Hands-on Example
```hcl
# Remote, locked state backend (Azure Storage) + provider pinning
terraform {
  required_version = ">= 1.6"
  required_providers { azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" } }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "genaitfstate"
    container_name       = "state"
    key                  = "prod/network.tfstate"   # segmented state
    use_oidc             = true                      # passwordless CI auth
  }
}
provider "azurerm" { features {}  use_oidc = true }
```

---

## 25. Terraform Example
```hcl
# Reusable module usage: standardized, versioned building blocks
module "aks" {
  source  = "app.terraform.io/corp/aks/azurerm"     # versioned module registry
  version = "4.2.0"
  name                = "genai-aks"
  resource_group_name = azurerm_resource_group.app.name
  private_cluster     = true
  workload_identity   = true
  node_pools = {
    system = { vm_size = "Standard_D4s_v5", count = 3, zones = [1,2,3] }
    gpu     = { vm_size = "Standard_NC6s_v3", min = 0, max = 4, taints = ["sku=gpu:NoSchedule"] }
  }
  tags = { costCenter = "genai", env = "prod" }       # enforced tagging
}
```

---

## 26. Azure Example
```bash
# Configure GitHub Actions → Azure OIDC (no secrets) for terraform apply
az ad app federated-credential create --id $APP_ID --parameters '{
  "name":"gh-oidc-prod",
  "issuer":"https://token.actions.githubusercontent.com",
  "subject":"repo:org/infra:environment:prod",
  "audiences":["api://AzureADTokenExchange"]
}'
az role assignment create --assignee $APP_ID --role "Contributor" \
  --scope /subscriptions/$SUB/resourceGroups/genai-rg   # least-privilege apply scope
```

---

## 27. Code Example
```yaml
# GitHub Actions: plan on PR, apply on merge — passwordless via OIDC
name: terraform
on: { pull_request: {}, push: { branches: [main] } }
permissions: { id-token: write, contents: read }        # OIDC
jobs:
  tf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with: { client-id: ${{ vars.AZ_CLIENT_ID }}, tenant-id: ${{ vars.AZ_TENANT_ID }}, subscription-id: ${{ vars.AZ_SUB_ID }} }
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform fmt -check && terraform validate
      - run: terraform plan -out=tf.plan            # posted for review
      - if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tf.plan   # apply only on main
```

---

## 28. Things Architects Must Remember
- **State is the crown jewel** — remote, locked, encrypted, access-controlled; never hand-edit; it holds secrets.
- **Plan before apply** — reviewable, predictable change; PR-gated.
- **Passwordless CI** via OIDC/federation — no cloud creds in pipelines.
- **Modules** encode standards + DRY; pin versions (modules + providers).
- **Segment state** to limit blast radius; directory-per-env for clarity.
- **Scan (tfsec/checkov) + cost (Infracost)** as PR gates.
- **Drift detection** + IaC-only discipline.
- **Terraform (multi-cloud, stateful) vs Bicep (Azure, stateless)** — choose by context.

---

## 29. Mnemonics and Memory Tricks
- **"Plan, then apply"** — never apply blind.
- **State "R-L-E-A"**: **R**emote, **L**ocked, **E**ncrypted, **A**ccess-controlled.
- **"State knows your secrets"** — protect it accordingly.
- **"Modules = LEGO bricks"** — reusable, versioned, standardized.
- **CI auth: "OIDC, not secrets."**

---

## 30. One-Page Interview Revision Sheet
- **What**: declarative, stateful, multi-cloud IaC (HCL) via providers; plan → apply.
- **State**: maps config→real resources; remote (Azure Storage) + locked + encrypted + RBAC; holds secrets; never hand-edit.
- **Workflow**: PR → fmt/validate/tflint/tfsec/checkov/Infracost + plan comment → approve → apply via **OIDC** (no creds).
- **Modules**: versioned, reusable, standardized; pin module + provider versions.
- **Scale**: segment state by layer/env; directory-per-env; module registry; automation (TFC/Atlantis).
- **Security**: protect state, OIDC auth, least-privilege apply identity, secrets from Key Vault, policy scanning.
- **HA/DR**: geo-redundant versioned state + backups; rebuild from Git; `import` as last resort.
- **vs Bicep**: multi-cloud + modules + explicit state vs Azure-native + stateless.
- **When NOT**: Azure-only preferring stateless (Bicep), one-off resources, app/config rollout (use GitOps).
- **Remember**: *plan then apply*; **R-L-E-A** state; *state knows your secrets*; modules = LEGO; OIDC not secrets.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain Terraform state and three ways it can hurt you if mishandled.
2. Design team-safe state management for a 10-team Azure estate.
3. Terraform vs Bicep — make the call for an Azure-only vs multi-cloud org.
4. How do you run `terraform apply` in CI with zero stored cloud credentials?
5. A plan wants to destroy and recreate your prod database. What happened and how do you avoid it?
6. How do you keep secrets out of config and state? What if a secret leaks into state?
7. How do you detect and remediate drift at scale?
8. Segment state to limit blast radius — show a concrete layout.
9. You lost the state file. Walk through recovery options.
10. What PR gates do you enforce before any apply, and why each?

---

> Next Phase 4 topic: **GitHub Actions**.
