# Question Bank · Top 50 Terraform & IaC Architect Questions

> Architect-level answers. Say them aloud.

---

## Fundamentals (1–14)

**1. What is Terraform and why use it?**
Declarative, cloud-agnostic Infrastructure as Code: describe desired state in HCL, Terraform plans and applies the changes. Benefits: versioned, reviewable, repeatable, multi-cloud, with state + plan/apply safety.

**2. Declarative vs imperative IaC?**
Declarative (Terraform) = describe the end state, tool computes steps; imperative (scripts) = specify each step. Declarative is idempotent and self-correcting toward desired state.

**3. What is Terraform state?**
A file mapping your config to real-world resources (IDs, metadata). It's how Terraform knows what exists, computes diffs, and tracks dependencies. Store it **remotely + locked**; it can contain secrets.

**4. Why a remote backend with locking?**
Team collaboration + safety: remote state (Azure Storage) shared across the team, **state locking** (blob lease) prevents concurrent applies corrupting state. Never keep prod state local.

**5. Explain plan vs apply.**
`plan` computes and shows the diff (add/change/destroy) for review; `apply` executes it. Always plan → review → apply; gate applies in CI.

**6. The core Terraform workflow?**
`init` (providers/backend) → `plan` (preview) → `apply` (execute) → `destroy` (teardown). (R-L-E-A: Read config, Load state, Evaluate diff, Apply.)

**7. What are providers?**
Plugins that map Terraform to an API (azurerm, azuread, kubernetes). Pin provider versions for reproducibility.

**8. What are resources and data sources?**
Resources create/manage infrastructure; data sources **read** existing infra/values (e.g., look up an existing VNet) without managing it.

**9. What are variables, locals, and outputs?**
Variables = inputs (parameterize); locals = computed named values (DRY within a module); outputs = exported values (for other modules/consumers or display).

**10. What are modules?**
Reusable, parameterized packages of resources — DRY, consistent, versioned building blocks (e.g., a "landing zone" or "aks" module).

**11. How do you handle dependencies?**
Implicit via references (Terraform builds a dependency graph); explicit with `depends_on` when there's no direct reference.

**12. What is idempotency in Terraform?**
Re-running apply with no config change produces no changes — Terraform converges to desired state; drift is detected and corrected.

**13. `count` vs `for_each`?**
`count` = numeric replication (index-based, fragile on removal); `for_each` = iterate a map/set (stable keys, safer for add/remove). Prefer `for_each`.

**14. What is the dependency graph?**
Terraform builds a DAG of resources to determine creation/update order and parallelism; it drives correct sequencing.

---

## State & Structure (15–28)

**15. How do you manage multiple environments?**
Separate state per environment (dir/backend key per env) + shared modules + per-env `.tfvars`. Isolate prod state and pipelines. Workspaces exist but separate state is clearer for prod.

**16. Terraform workspaces — pros/cons?**
Multiple states under one backend/config — handy for lightweight variants, but easy to misapply to the wrong env. For strong prod isolation, prefer separate backends/dirs.

**17. How do you structure a large Terraform codebase?**
Root configs per env composing versioned modules; modules for reusable components; remote state per layer (network, platform, app); clear variable contracts.

**18. What is remote state data source / `terraform_remote_state`?**
Read outputs from another state file to compose layers (e.g., app layer reads network layer's VNet ID) — decouples stacks.

**19. How do you secure state (it has secrets)?**
Remote backend with encryption at rest + access control (RBAC), state locking, no state in git, and avoid outputting secrets. Use Key Vault for secret sources.

**20. What is `terraform import`?**
Brings existing (manually created) resources under Terraform management by mapping them into state — for adopting brownfield infra.

**21. How do you handle drift?**
`plan`/`refresh` detects drift (real infra changed outside Terraform); re-apply to reconcile, or import/adjust config. Enforce "no manual changes."

**22. `terraform taint` / `-replace`?**
Force recreation of a specific resource on next apply (e.g., to rebuild a corrupted resource). `-replace` is the modern flag.

**23. How do you refactor without destroying resources?**
`moved` blocks (or `terraform state mv`) to rename/relocate resources in state without recreation.

**24. How do you manage provider/module versions?**
Pin provider versions (`required_providers`) and module source versions; use a lockfile (`.terraform.lock.hcl`) committed for reproducible builds.

**25. What is `lifecycle` (prevent_destroy, create_before_destroy, ignore_changes)?**
Control resource behavior: protect critical resources, avoid downtime by creating replacement first, or ignore externally-managed attributes.

**26. How do you pass secrets to Terraform safely?**
Reference Key Vault data sources or inject via pipeline secret vars/env (`TF_VAR_`), mark variables `sensitive`, never hardcode. Use OIDC for cloud auth.

**27. How do you test Terraform?**
`validate` + `fmt` + `plan` in CI, `terraform test`, tools like tflint/checkov/tfsec (policy + security), and Terratest for integration.

**28. What is a null_resource / provisioner and when to avoid?**
Escape hatches to run scripts; avoid provisioners when a proper resource/provider exists — they're imperative and fragile.

---

## Azure & CI/CD (29–40)

**29. How do you authenticate Terraform to Azure in CI?**
**OIDC workload federation** (no stored secrets) between GitHub Actions/Azure DevOps and Entra — short-lived tokens; least-privilege service principal.

**30. How do you deploy Azure Landing Zones with Terraform?**
Use the Azure/AVM or CAF enterprise-scale modules to provision management groups, policies, identity, and hub networking as code.

**31. What is the azurerm provider backend for state?**
`backend "azurerm"` stores state in an Azure Storage container with blob-lease locking — the standard remote backend on Azure.

**32. How do you run Terraform in a pipeline safely?**
init → validate → plan (as artifact) → **manual approval** → apply. Gate prod, use OIDC auth, store state remotely, and run security scans (checkov/tfsec).

**33. How do you do plan review/approval gates?**
Publish the plan output, require reviewer approval (environment protection), then apply the exact saved plan — prevents surprise changes.

**34. GitOps for infrastructure?**
Git as source of truth; PR-driven changes with automated plan on PR + apply on merge (or Atlantis/Terraform Cloud) — auditable, reviewable infra changes.

**35. How do you manage AKS + workloads with Terraform?**
Terraform provisions the cluster + node pools + identity + networking; app workloads via Helm/Kubernetes provider or GitOps (Flux/Argo) — often separate concerns.

**36. Terraform vs Bicep/ARM?**
Terraform = multi-cloud, mature module ecosystem, state-based; Bicep/ARM = Azure-native, no state file (uses Azure as state), tight Azure integration. Choose by cloud strategy/team.

**37. Terraform vs Pulumi?**
Both IaC with state; Terraform uses HCL (declarative DSL), Pulumi uses general languages (TS/Python/C#). HCL is simpler/standardized; Pulumi offers full language power.

**38. How do you enforce policy/compliance in IaC?**
Policy-as-code: checkov/tfsec/OPA/Sentinel in CI to block non-compliant plans (no public IPs, required tags, encryption) before apply.

**39. How do you handle large blast radius / risky applies?**
Split state into layers, use `-target` sparingly, plan review + approvals, `prevent_destroy` on critical resources, and staged rollout across environments.

**40. How do you manage secrets rotation with IaC?**
Store secrets in Key Vault (managed rotation), reference them at runtime via Managed Identity — Terraform provisions the vault/access, not the secret values.

---

## Best Practices & Scenarios (41–50)

**41. Top Terraform best practices?**
Remote locked state, small composable modules, pin versions + lockfile, plan-review-approve, OIDC auth, no secrets in code/state output, policy scans, `for_each` over `count`, separate env state.

**42. How do you keep modules reusable and clean?**
Clear input/output contracts, sensible defaults, no hardcoded env specifics, versioned, single responsibility, and documented.

**43. How do you minimize downtime on changes?**
`create_before_destroy`, blue-green infra where needed, and understand which changes force replacement (check the plan's `-/+`).

**44. Two engineers apply at once — what prevents corruption?**
State locking (blob lease) — the second apply waits/fails until the lock releases; that's why remote backends with locking are mandatory.

**45. A resource was changed manually in the portal — what happens?**
Next `plan` shows drift; apply reverts to config (or you import/adjust). Enforce IaC-only changes to avoid drift.

**46. How do you roll back a bad infra change?**
Revert the code in git and apply the previous version (infra is versioned); for stateful data, restore from backups. Immutable/versioned config enables this.

**47. How do you organize state for a big enterprise?**
Layered state (foundation/network/platform/app) per environment, remote-state references between layers, least-privilege pipelines per layer — limits blast radius.

**48. How do you handle provider rate limits / large applies?**
Parallelism tuning (`-parallelism`), split into smaller stacks, and retry; design modules to avoid giant monolithic state.

**49. How do you validate before prod?**
fmt + validate + tflint + security scan (checkov/tfsec) + plan review in lower envs, then promote the same modules with prod variables.

**50. Design an end-to-end IaC pipeline for Azure GenAI infra.**
Modules (network hub-spoke, AKS/Container Apps, AOAI + private endpoints, AI Search, Key Vault, APIM) → remote azurerm state (locked) per env → CI: fmt/validate/tflint/checkov → plan artifact → approval gate → apply via **OIDC** (no secrets) → policy-as-code compliance → outputs consumed by app deploy. Least-privilege, drift detection, versioned modules.

---

## Practice Tips
- Always mention **remote locked state + plan/apply + OIDC** for production questions.
- Know **`for_each` vs `count`**, **`moved` blocks**, and **drift** cold.
- Tie IaC to **security (no secrets in state), policy-as-code, and approval gates**.

---

> Next: Top 50 Azure Architecture.
