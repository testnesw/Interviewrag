# Deep Dive · GitHub Actions

> Phase 4 (Delivery / CI-CD) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
GitHub Actions is GitHub's **native CI/CD + automation** platform. You define **workflows** (YAML in `.github/workflows`) triggered by **events** (push, PR, schedule, manual) that run **jobs** of **steps** on **runners** (GitHub-hosted or self-hosted). Steps use reusable **actions** from the marketplace. For Azure it's the modern way to **build, test, scan, and deploy** — authenticating **passwordlessly via OIDC federation to Entra ID** (no stored secrets). It's event-driven, tightly integrated with PRs, and the default choice for GitHub-hosted code.

---

## 2. Architect-Level Explanation
Structure: **Workflow → Jobs → Steps → Actions**, run on **runners**.
- **Events/triggers**: `push`, `pull_request`, `workflow_dispatch`, `schedule`, `release`, repository/deployment events.
- **Jobs**: run in parallel by default; ordered via `needs`; each on a fresh runner; share data via **artifacts/outputs**.
- **Runners**: GitHub-hosted (ephemeral, managed) or **self-hosted** (in your VNet for private resources/compliance).
- **Actions**: reusable units (marketplace or custom — composite/Docker/JS).
- **Secrets/variables**: repo/org/environment scoped; **OIDC** to avoid long-lived cloud secrets.
- **Environments**: deployment targets with **protection rules** (required reviewers, wait timers, branch limits) → approval gates.
- **Reusable workflows + composite actions**: DRY across repos.

Architecturally: **event-driven pipelines, ephemeral compute, least-privilege OIDC auth, environment-gated deploys** — CI/CD as code.

---

## 3. Why It Exists
- **Problem**: CI/CD used to be a separate tool/server (Jenkins) to maintain; config drift and plugin sprawl.
- **Breakthrough**: **CI/CD as code, co-located with the repo**, event-driven, with a huge reusable-action ecosystem and managed runners.
- **Why enterprises adopt it**: zero server maintenance, tight PR integration, OIDC keyless cloud deploys, org-wide reusable workflows, and marketplace velocity.
- **Why over alternatives**: if code is on GitHub, Actions is native, frictionless, and OIDC-first.

---

## 4. Internal Working
**Run lifecycle:**
```
1. Event occurs (push/PR/schedule/dispatch) → matching workflow triggers
2. Scheduler assigns each job to a fresh runner (hosted/self-hosted)
3. Steps run sequentially in the job; actions/scripts execute
4. Jobs ordered by `needs`; matrix expands combinations; artifacts pass data
5. OIDC: job requests a short-lived token from GitHub's OIDC provider →
   exchanged with Entra (federated credential) → scoped Azure token (no stored secret)
6. Environment protection rules gate deploy jobs (approvals/wait/branch)
7. Status reported back to the PR/commit (checks)
```
Key mechanics:
- **`permissions: id-token: write`** enables OIDC.
- **Concurrency groups** cancel/queue overlapping runs.
- **Caching** (deps) + **artifacts** (build outputs) speed pipelines.
- **Ephemeral runners** = clean, reproducible, no persistent state.

---

## 5. Enterprise Use Case
A GenAI team's monorepo uses Actions: PRs run **lint → unit tests → build container → tfsec/Trivy scan → terraform plan** as required checks. On merge to main, a deploy workflow uses **OIDC to Entra** (no secrets) to push the image to **ACR** and roll out to **AKS**, gated by a **production environment** requiring two approvers and passing only from `main`. Reusable org-level workflows enforce the same security scans across all repos. Self-hosted runners in the VNet reach private resources.

---

## 6. Real Production Architecture
```
 PR ─► CI workflow: lint · test · build · scan (Trivy/tfsec) · tf plan  → PR checks
   merge to main │
                 ▼
 CD workflow (OIDC → Entra, no secrets):
   build+push image → ACR ─► deploy → AKS (or Container Apps)
                 │ gated by Environment: prod (2 reviewers, branch=main)
 Reusable org workflows + composite actions (DRY security/build)
 Self-hosted runners (VNet) for private-network deploys
 Status/checks ─► GitHub PR   ·   Artifacts/cache ─► speed
```

---

## 7. Security Best Practices
- **OIDC federation to Entra** — no long-lived cloud secrets in GitHub.
- **Least-privilege `GITHUB_TOKEN`**: set `permissions:` explicitly (default read-only).
- **Environment protection rules**: required reviewers, wait timers, restrict to protected branches for prod.
- **Pin actions by commit SHA** (not floating tags) to prevent supply-chain tampering; use verified/creator-owned actions.
- **Secrets scoped** (environment-level for prod) + **secret scanning**; never echo secrets.
- **Self-hosted runners hardened + ephemeral** (auto-scaled, isolated) — don't run untrusted PRs on them.
- **Supply-chain**: SBOM, dependency review, `pull_request_target` caution (avoid running untrusted code with secrets).

---

## 8. Scaling Strategy
- **Reusable workflows + composite actions** → DRY across many repos/teams.
- **Matrix builds** for parallel multi-version/platform testing.
- **Caching + artifacts** to cut build time.
- **Self-hosted runner autoscaling** (ARC on AKS) for high volume / private access.
- **Concurrency controls** to avoid redundant runs; **path filters** to run only what changed (monorepos).

---

## 9. High Availability Strategy
- **GitHub-hosted runners** are managed/HA; **self-hosted** should be autoscaled across zones (ARC).
- **Idempotent, re-runnable** jobs; retry transient steps.
- **Environment gates** prevent bad deploys; **rollback workflows** ready.
- Multi-runner pools so one outage doesn't block delivery.

---

## 10. Disaster Recovery Strategy
- **Workflows are code in Git** → fully reproducible; portable to another org/runner set.
- **Self-hosted runner infra as IaC** → redeploy quickly.
- **Deployment workflows enable fast redeploy/rollback** to a healthy region/version.
- Keep **release artifacts** (images by digest) retained for recovery.

---

## 11. Cost Optimization Strategy
- **Caching + path filters + concurrency** reduce wasted minutes.
- **Right-size runners** (larger runners only where needed); **self-hosted** for heavy/steady load (cheaper at scale).
- **Fail fast** (lint/test early) to avoid expensive later steps.
- **Ephemeral preview environments** auto-torn-down.
- Monitor **Actions minutes** usage; use smaller matrices where possible.

---

## 12. Common Production Challenges
- **Leaked secrets** via logs or `pull_request_target` on forks → OIDC, guard untrusted PRs, mask secrets.
- **Supply-chain risk** from unpinned actions → pin SHAs, review.
- **Flaky/slow pipelines** → caching, parallelism, test isolation.
- **Runner access to private resources** → self-hosted in VNet.
- **Over-broad `GITHUB_TOKEN`** → set least-privilege permissions.
- **No approval gates on prod** → environment protection rules.
- **Monorepo runs everything** → path filters + reusable workflows.

---

## 13. Monitoring and Observability
- **Workflow run history + checks** on PRs/commits; job/step logs.
- **Deployment history** per environment; **required-check** status.
- **Metrics**: run duration, success rate, minutes usage, queue time.
- **Alerts/notifications** on failed deploys; integrate with Slack/Teams.
- **Audit log** (org) for workflow/secret/environment changes.

---

## 14. Troubleshooting Scenarios
- **OIDC login fails** → federated credential `subject` mismatch (branch/environment) or missing `id-token: write`; align subject + permissions.
- **Secret is empty** → wrong scope (env vs repo) or not passed to reusable workflow; check `secrets: inherit`.
- **Job can't reach private resource** → use self-hosted VNet runner.
- **Deploy ran from a feature branch** → environment not restricted to `main`; add branch protection rule.
- **Slow pipeline** → no cache / serial jobs; add caching + `needs` parallelism + path filters.
- **Action behaves unexpectedly after update** → floating tag moved; pin to SHA.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Hosted vs self-hosted runners | zero maintenance | no VNet access / cost |
| Marketplace actions | speed | supply-chain risk |
| Monorepo workflows | central | complexity/path filtering |
| Strict environment gates | safe | slower delivery |

---

## 16. When NOT to use it
- **Code not on GitHub** (Azure Repos/GitLab) → Azure DevOps/GitLab CI.
- **Heavy enterprise release orchestration** with rich gates/approvals already in **Azure DevOps** → may stay there.
- **Air-gapped/highly regulated** with no GitHub connectivity → self-hosted DevOps/Jenkins.
- **Complex artifact/package governance** better served by a dedicated release tool.

---

## 17. Comparison with Alternatives
| Tool | Integration | Auth to Azure | Best for |
|------|-------------|---------------|----------|
| **GitHub Actions** | native to GitHub | OIDC | GitHub-hosted code |
| Azure DevOps Pipelines | Azure Repos/any | OIDC/service connection | enterprise release orchestration |
| GitLab CI | native to GitLab | OIDC | GitLab-hosted code |
| Jenkins | any (self-managed) | plugins/creds | on-prem/legacy control |
| Argo CD/Flux | GitOps CD | in-cluster | K8s continuous delivery |

---

## 18. Interview Questions
1. Workflow/job/step/action — define and relate.
2. How does OIDC to Azure work and why prefer it?
3. Hosted vs self-hosted runners?
4. How do you gate production deployments?
5. How do you secure the supply chain (actions, secrets)?
6. Reusable workflows vs composite actions?
7. How do you speed up pipelines?
8. `pull_request` vs `pull_request_target` risks?
9. How do you deploy to AKS from Actions?
10. Actions vs Azure DevOps — when each?

---

## 19. Strong Interview Answers
- **OIDC**: "The job requests a short-lived OIDC token from GitHub; Entra trusts it via a federated credential matched on the workflow's subject (repo/branch/environment) and exchanges it for a scoped Azure token. No cloud secrets stored — this eliminates the biggest CI/CD leak vector. It needs `permissions: id-token: write` and `azure/login`."
- **Runners**: "GitHub-hosted are ephemeral and maintenance-free but can't reach private VNet resources; self-hosted (ideally autoscaled ARC on AKS, ephemeral) reach private resources and cut cost at scale — but I never run untrusted fork PRs on them."
- **Prod gating**: "GitHub Environments with protection rules — required reviewers, wait timers, and restricting deploys to protected branches like `main`. Secrets are scoped to the environment so they're only available after approval."
- **Supply chain**: "Pin actions to commit SHAs (not floating tags), use verified actions, set least-privilege `GITHUB_TOKEN` permissions, avoid `pull_request_target` with secrets on untrusted code, and add dependency review/SBOM."
- **Actions vs DevOps**: "If code's on GitHub, Actions is native and OIDC-first. Azure DevOps shines for complex enterprise release orchestration and org process, or when code is in Azure Repos. Both support OIDC to Azure now."

---

## 20. Architecture Diagrams
**OIDC keyless deploy:**
```
Job (id-token: write) ─► GitHub OIDC token ─► Entra (federated cred: subject match)
     ─► scoped Azure token ─► push ACR / deploy AKS   (NO stored secret)
Environment: prod → requires reviewers + branch=main before deploy job runs
```

---

## 21. Real Project Example
**Keyless GitOps-adjacent delivery.** PRs trigger lint/test/build/scan/`tf plan` as required checks; merges to `main` build+push the image to ACR and deploy to AKS via **OIDC** (zero secrets), gated by a `prod` environment needing two approvers and `main` only. Org-level **reusable workflows** enforce identical Trivy/tfsec scanning across 30 repos. Actions are SHA-pinned. Self-hosted ARC runners in the VNet handle private deploys. Result: fast, secure, standardized delivery with no long-lived cloud credentials anywhere.

---

## 22. Whiteboard Design Question
> *"Design a secure CI/CD pipeline on GitHub Actions to deploy a GenAI app to AKS across dev/stage/prod."*

Cover: triggers (PR checks + main deploy) → jobs (lint/test/build/scan/plan) with caching + parallelism → OIDC federation to Entra (no secrets) → push ACR → deploy AKS via environments with progressive gates (dev auto, stage 1 approver, prod 2 approvers + main-only) → reusable org workflows for standardization → SHA-pinned actions → self-hosted VNet runners for private access → rollback workflow → observability (checks, deploy history). Emphasize OIDC, least privilege, environment gates, supply-chain pinning.

---

## 23. Design Review Questions
- **OIDC** (no stored cloud secrets)? Federated subject scoped correctly?
- **`GITHUB_TOKEN` permissions** least-privilege?
- **Environment protection** on stage/prod (reviewers, branch restriction)?
- **Actions pinned to SHA**; verified sources?
- **Untrusted PR handling** safe (no secrets to forks)?
- **Self-hosted runners** ephemeral + hardened + VNet-scoped?
- **Caching/path filters/concurrency** for speed/cost?
- **Rollback** path defined?

---

## 24. Hands-on Example
```yaml
name: ci-cd
on:
  pull_request: {}
  push: { branches: [main] }
permissions: { contents: read, id-token: write }        # OIDC, least privilege
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - uses: actions/cache@v4                            # speed
        with: { path: ~/.cache/pip, key: pip-${{ hashFiles('requirements.txt') }} }
      - run: pip install -r requirements.txt && pytest -q
      - run: pip-audit                                    # supply-chain scan
```

---

## 25. Terraform Example
```hcl
# Federated credential so this repo's prod environment can deploy without secrets
resource "azuread_application_federated_identity_credential" "gh_prod" {
  application_object_id = var.app_object_id
  display_name          = "gh-prod"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:org/genai-app:environment:prod"   # scope to prod env
}
resource "azurerm_role_assignment" "gh_prod_acr" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = var.app_sp_object_id                     # least privilege
}
```

---

## 26. Azure Example
```yaml
# Deploy job: passwordless login + push to ACR + rollout to AKS, gated by prod env
  deploy:
    needs: build-test
    if: github.ref == 'refs/heads/main'
    environment: prod                                    # requires reviewers + main only
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2                             # OIDC (no secrets)
        with:
          client-id: ${{ vars.AZ_CLIENT_ID }}
          tenant-id: ${{ vars.AZ_TENANT_ID }}
          subscription-id: ${{ vars.AZ_SUB_ID }}
      - run: az acr build -r genaiacr -t orchestrator:${{ github.sha }} .
      - uses: azure/aks-set-context@v4
        with: { resource-group: rg, cluster-name: genai-aks }
      - run: kubectl set image deploy/orchestrator app=genaiacr.azurecr.io/orchestrator:${{ github.sha }}
```

---

## 27. Code Example
```yaml
# Reusable org workflow (DRY security scan) called by many repos
# .github/workflows/reusable-scan.yml
on: { workflow_call: {} }
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@6e7b7d1fd3e4fef0c5fa8cce1229c54b2c9bd0d8  # pinned SHA
        with: { scan-type: fs, severity: CRITICAL,HIGH, exit-code: '1' }
# Caller: jobs: { security: { uses: org/.github/.github/workflows/reusable-scan.yml@main } }
```

---

## 28. Things Architects Must Remember
- **Structure**: Workflow → Jobs → Steps → Actions on ephemeral runners; event-driven.
- **OIDC federation** = passwordless Azure auth — eliminate stored cloud secrets.
- **Least-privilege `GITHUB_TOKEN`** (`permissions:` explicit).
- **Environment protection rules** gate stage/prod (reviewers, branch, wait).
- **Pin actions to SHAs** — supply-chain defense; beware `pull_request_target` + forks.
- **Self-hosted runners** for private VNet access — ephemeral + hardened.
- **Reusable workflows/composite actions** standardize across repos.
- **Caching + parallelism + path filters** for speed and cost.

---

## 29. Mnemonics and Memory Tricks
- **"W-J-S-A"**: **W**orkflow → **J**obs → **S**teps → **A**ctions.
- **"OIDC, not secrets"** — the keyless mantra.
- **Prod gate "R-B-W"**: **R**eviewers, **B**ranch-restrict, **W**ait timer.
- **"Pin the SHA"** — never trust a moving tag.
- **"Ephemeral runners forget"** — clean, reproducible builds.

---

## 30. One-Page Interview Revision Sheet
- **What**: native GitHub CI/CD; Workflow→Jobs→Steps→Actions triggered by events, on runners.
- **Auth**: **OIDC federation** to Entra (no stored secrets); `permissions: id-token: write` + `azure/login`.
- **Runners**: hosted (ephemeral, no VNet) vs self-hosted (VNet, ARC autoscale, ephemeral+hardened).
- **Gates**: Environments with protection rules (reviewers, wait, branch-restrict) for stage/prod.
- **Security**: least-privilege `GITHUB_TOKEN`, SHA-pin actions, scoped secrets, guard `pull_request_target`, SBOM/dep review.
- **Scale/speed**: reusable workflows + composite actions, matrix, caching, path filters, concurrency.
- **HA/DR**: workflows in Git (reproducible), runner infra as IaC, rollback workflows, retained image digests.
- **vs DevOps**: native for GitHub code/OIDC-first; DevOps for enterprise release orchestration / Azure Repos.
- **Remember**: **W-J-S-A**; *OIDC not secrets*; prod gate **R-B-W**; *pin the SHA*; ephemeral runners forget.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Walk OIDC from GitHub Actions to an Azure deployment — every step, no secrets.
2. Hosted vs self-hosted runners — when must you use self-hosted?
3. Design progressive deployment gates for dev/stage/prod.
4. How do you prevent a malicious marketplace action from stealing your cloud creds?
5. Explain the `pull_request_target` fork risk and how you'd mitigate it.
6. Standardize security scanning across 30 repos without copy-paste. How?
7. Your OIDC login fails only on the prod deploy. Most likely cause?
8. Deploy a container to AKS from Actions with zero stored secrets — outline it.
9. Speed up a 25-minute monorepo pipeline. Your top four levers.
10. GitHub Actions vs Azure DevOps — decide for a regulated Azure-Repos shop.

---

> Next Phase 4 topic: **Azure DevOps**.
