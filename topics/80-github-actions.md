# 80 · GitHub Actions

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
GitHub Actions is GitHub's built-in CI/CD. You define workflows in YAML files in your repo that automatically run on events (like a push or PR) to build, test, and deploy your code.

## 2. Architect-Level Explanation
Event-driven CI/CD native to GitHub:
- **Workflows**: YAML in `.github/workflows/`, triggered by events (`push`, `pull_request`, `schedule`, `workflow_dispatch`, `release`).
- **Jobs & steps**: jobs run on **runners** (GitHub-hosted or self-hosted), steps run commands or **actions** (reusable units from the Marketplace).
- **Reuse**: composite actions, **reusable workflows** (`workflow_call`), matrix builds.
- **Security**: **OIDC** to Azure (short-lived tokens, no stored secrets), encrypted secrets, **environments** with protection rules/approvals, and `permissions:` (least-privilege `GITHUB_TOKEN`).
- **Supply chain**: pin actions by commit SHA, use `dependabot`, artifact attestations/provenance (SLSA), `CODEOWNERS`.
- **Concurrency**: `concurrency` groups to cancel superseded runs; caching for deps.
- **Environments**: gated deployments (dev/stage/prod) with required reviewers.
- Tight integration with PRs, checks, and GitHub Advanced Security.

## 3. Real Enterprise Use Case
A company uses reusable workflows across repos: PR triggers lint/test/scan; on merge to main, build + push to ACR (via OIDC, no secrets), then a gated `prod` environment requires two approvers before `kubectl`/Helm deploy to AKS. Actions are SHA-pinned and Dependabot keeps them patched.

## 4. Architecture Diagram (ASCII)
```
   Event (push/PR/schedule/dispatch)
        │
   Workflow (.github/workflows/*.yml)
     job: test (matrix) ─► job: build+push ACR (OIDC, no secret)
                              │ needs:
     job: deploy ─► environment: prod (required reviewers) ─► AKS
   Runners: GitHub-hosted | self-hosted (VNet, private AKS)
   permissions: least-priv GITHUB_TOKEN | actions pinned by SHA
```

## 5. Interview Questions
1. What triggers a workflow and how is it structured?
2. How do you deploy to Azure without storing secrets?
3. Reusable workflows vs composite actions?
4. How do you secure the Actions supply chain?
5. GitHub-hosted vs self-hosted runners?

## 6. Strong Interview Answers
- **Triggers/structure**: "Workflows in `.github/workflows` trigger on events (push, PR, schedule, manual dispatch). Each has jobs (on runners) made of steps that run commands or reusable actions; jobs can depend on each other with `needs` and run in parallel by default."
- **Secretless Azure**: "**OIDC** — I configure a federated credential so the workflow requests a short-lived Azure token via `azure/login` with no client secret. That eliminates long-lived credentials in GitHub secrets."
- **Reusable workflows vs composite**: "Reusable workflows (`workflow_call`) share entire pipelines across repos; composite actions bundle multiple steps into one reusable action. I use reusable workflows for standardized CI/CD and composite actions for smaller step groups."
- **Supply chain**: "Pin actions to a commit SHA (not a moving tag), enable Dependabot for action updates, set least-privilege `permissions` on `GITHUB_TOKEN`, use environments with approvals, and add provenance/attestations. Third-party actions are a real attack surface."
- **Runners**: "GitHub-hosted are managed and ephemeral but can't reach private resources; self-hosted (ideally ephemeral, in my VNet, e.g., Actions Runner Controller on AKS) reach private AKS/DBs and allow custom tooling — but I must patch and isolate them."

## 7. Common Mistakes
- Storing long-lived Azure secrets instead of OIDC.
- Pinning actions to tags (mutable) not SHAs.
- Over-privileged `GITHUB_TOKEN` (default write-all).
- No environment approvals for prod.
- Persistent self-hosted runners with state bleed.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| GitHub-hosted runners | managed, ephemeral | no private access |
| Self-hosted (ARC) | private, custom, scalable | maintenance |
| Reusable workflows | DRY governance | indirection |

## 9. Production Best Practices
- OIDC to Azure; encrypted secrets only when unavoidable.
- SHA-pin actions + Dependabot; least-privilege `permissions`.
- Reusable workflows for standardized CI/CD across repos.
- Environments with required reviewers for prod; concurrency groups.
- Ephemeral self-hosted runners (ARC on AKS) for private targets; caching.

## 10. Security Considerations
- Secretless OIDC; least-privilege token + Azure roles.
- Untrusted third-party actions → pin + review; avoid `pull_request_target` pitfalls.
- GitHub Advanced Security (code/secret scanning, Dependabot).
- Protect environments/branches; CODEOWNERS.

## 11. Cost Optimization
- Cache dependencies; matrix only where needed.
- Concurrency to cancel superseded runs.
- Autoscaling ephemeral runners (ARC) vs idle VMs; fail fast.

## 12. Troubleshooting Scenarios
- **Azure login fails** → OIDC federated-credential subject/audience mismatch.
- **Permission denied (GITHUB_TOKEN)** → `permissions:` too restrictive/broad.
- **Runner can't reach private AKS** → need self-hosted in VNet.
- **Compromised action** → unpinned tag; pin SHA, rotate.
- **Duplicate/racey runs** → add `concurrency` group.

## 13. Hands-on Example
```yaml
name: ci
on: [push, pull_request]
permissions: { contents: read, id-token: write }   # OIDC
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pytest -q --cov=app
```

## 14. Terraform Example
```hcl
# Federated credential: GitHub Actions → Azure via OIDC (no secret)
resource "azuread_application_federated_identity_credential" "gha" {
  application_id = azuread_application.cicd.id
  display_name   = "github-actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:my-org/my-repo:environment:prod"
}
```

## 15. Azure Example
```yaml
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: prod                 # required reviewers gate
    permissions: { id-token: write, contents: read }
    steps:
      - uses: azure/login@v2          # OIDC, no client secret
        with: { client-id: ${{ vars.AZURE_CLIENT_ID }}, tenant-id: ${{ vars.AZURE_TENANT_ID }}, subscription-id: ${{ vars.AZURE_SUB }} }
      - run: az aks command invoke -g rg-aks -n prod-aks --command "kubectl apply -f k8s/"
```

## 16. FastAPI / Python Example
```python
# Workflow verifies deployment health post-deploy against this endpoint
@app.get("/health")
def health():
    return {"status": "ok"}
# GitHub Actions step: curl --fail https://api.example.com/health
```

## 17. AKS Example
Actions Runner Controller (ARC) runs ephemeral self-hosted runners as pods in AKS, scaling with the job queue (scale-to-zero when idle). Runners use Workload Identity for ACR pull and deploy to the private AKS API server — no kubeconfig or registry secrets in GitHub.

## 18. How to Remember
**"Events → workflows → jobs on runners; OIDC not secrets; pin actions by SHA; environments gate prod."**

## 19. Real-World Analogy
A programmable assembly line triggered by events on a conveyor (a push): standardized robot tools (actions) snap in from a catalog (Marketplace), critical shipping bays require a supervisor's sign-off (environment approvals), and every tool is serial-number-verified (SHA-pinned) to prevent tampering.

## 20. One-Page Cheat Sheet
- **What**: event-driven CI/CD native to GitHub; YAML in `.github/workflows`.
- **Structure**: events → jobs (runners) → steps/actions; `needs`, matrix.
- **Reuse**: reusable workflows (`workflow_call`) + composite actions.
- **Secure**: OIDC to Azure (no secrets), least-priv `permissions`, SHA-pin actions + Dependabot, environments with approvals.
- **Runners**: GitHub-hosted (managed) vs self-hosted/ARC (private AKS, scale-to-zero).
- **Optimize**: caching, concurrency groups, fail fast.
