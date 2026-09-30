# 79 · Azure DevOps

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
Azure DevOps is Microsoft's suite for planning, building, testing, and shipping software. It includes source repos, CI/CD pipelines, work-item tracking (boards), artifact feeds, and test plans — an end-to-end toolchain.

## 2. Architect-Level Explanation
A unified ALM/DevOps platform with five services:
- **Repos**: Git repositories with branch policies, PR reviews, required checks.
- **Pipelines**: YAML (recommended) CI/CD — stages, jobs, steps; **agents** (Microsoft-hosted or self-hosted); templates for reuse; **environments** with approvals/gates.
- **Boards**: agile work tracking (backlogs, sprints, work items) linked to commits/PRs.
- **Artifacts**: package feeds (NuGet, npm, PyPI, Maven, Universal).
- **Test Plans**: manual/exploratory test management.
- **Security**: **service connections** with **Workload Identity Federation (OIDC)** to Azure (no stored secrets), variable groups + Key Vault integration, RBAC.
- **Governance**: multi-stage pipelines with environment approvals, gates, and audit — deployment control for regulated orgs.
- vs GitHub: overlapping; Microsoft steering new investment toward GitHub, but Azure DevOps remains widely used in enterprises.

## 3. Real Enterprise Use Case
An enterprise runs YAML multi-stage pipelines: build/test → push image to ACR → deploy to AKS dev → approval gate → stage → prod, using OIDC service connections (no secrets), Key Vault-backed variable groups, self-hosted agents in a private VNet, and Boards linking every deployment back to work items for full traceability.

## 4. Architecture Diagram (ASCII)
```
   Repos (Git + branch policies + PR)
        │ trigger
   Pipelines (YAML, multi-stage)
     build/test ─► push ACR ─► deploy dev ─►[approval]─► stage ─►[gate]─► prod
        │ agents (MS-hosted / self-hosted in VNet)
        │ service connection = OIDC (no secrets) + Key Vault var groups
   Boards (work items) ◄─ linked ─► commits/PRs   Artifacts (feeds)
```

## 5. Interview Questions
1. What are the Azure DevOps services?
2. YAML vs classic pipelines?
3. How do you authenticate to Azure securely from a pipeline?
4. Microsoft-hosted vs self-hosted agents?
5. How do you gate production deployments?

## 6. Strong Interview Answers
- **Services**: "Repos (Git), Pipelines (CI/CD), Boards (work tracking), Artifacts (package feeds), and Test Plans — a full ALM toolchain with security and governance built in."
- **YAML vs classic**: "YAML pipelines are code in the repo — versioned, reviewable, templatable, and portable — versus the classic UI-based editor. YAML is the standard now; I use templates to share stages across services."
- **Secure auth**: "**Workload Identity Federation (OIDC)** service connections so pipelines get short-lived Azure tokens with no stored secrets, plus Key Vault-backed variable groups for any remaining secrets. Never hardcode credentials."
- **Agents**: "Microsoft-hosted agents are managed, ephemeral, and zero-maintenance but can't reach private resources; self-hosted agents run in my VNet for private AKS/DB access and custom tooling, at the cost of maintenance."
- **Gating prod**: "Multi-stage pipelines with **Environments** that have pre-deployment approvals and gates (e.g., checks on change tickets, health, or business hours), plus branch policies and required reviews — controlled, auditable promotion."

## 7. Common Mistakes
- Secrets in pipeline variables instead of Key Vault/OIDC.
- Classic UI pipelines (not versioned).
- No environment approvals for prod.
- Monolithic pipelines with no templates (copy-paste).
- Self-hosted agents unpatched/over-privileged.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| MS-hosted agents | zero maintenance | no private access |
| Self-hosted agents | private/custom | you maintain them |
| Azure DevOps vs GitHub | enterprise governance | GitHub gets new features |

## 9. Production Best Practices
- YAML pipelines + reusable templates.
- OIDC service connections; Key Vault variable groups.
- Environments with approvals/gates for prod.
- Branch policies: PR review + required checks + build validation.
- Self-hosted agents in private VNet for private targets; patch them.

## 10. Security Considerations
- Secretless auth (OIDC); least-privilege service connections.
- Key Vault for secrets; no plaintext variables.
- Restrict agent pools; scan pipeline definitions.
- Audit approvals + link deployments to work items.

## 11. Cost Optimization
- MS-hosted parallel jobs vs self-hosted agent VMs — right mix.
- Scale-to-zero/auto-scaling self-hosted agents (VMSS/AKS).
- Cache dependencies; fail fast (unit tests first).

## 12. Troubleshooting Scenarios
- **Auth failure to Azure** → OIDC federation/service-connection scope.
- **Agent can't reach AKS/DB** → need self-hosted agent in VNet.
- **Pipeline secret leaked** → move to Key Vault; rotate.
- **Stuck waiting** → environment approval pending / gate failing.
- **Flaky builds** → shared self-hosted agent state; use ephemeral agents.

## 13. Hands-on Example
```yaml
trigger: [main]
pool: { vmImage: ubuntu-latest }
steps:
  - script: pytest -q --cov=app          # test
  - task: Docker@2                        # build + push to ACR
    inputs: { command: buildAndPush, repository: api, tags: $(Build.BuildId) }
```

## 14. Terraform Example
```hcl
# Federated credential enabling OIDC from Azure DevOps to Azure (no secret)
resource "azuread_application_federated_identity_credential" "ado" {
  application_id = azuread_application.cicd.id
  display_name   = "azdo-oidc"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://vstoken.dev.azure.com/<org-id>"
  subject        = "sc://<org>/<project>/<service-connection>"
}
```

## 15. Azure Example
```yaml
# Deploy to AKS with an OIDC service connection + environment approval
- deployment: DeployProd
  environment: prod            # approvals/gates configured on this environment
  strategy:
    runOnce:
      deploy:
        steps:
          - task: KubernetesManifest@1
            inputs: { action: deploy, manifests: k8s/*.yaml }
```

## 16. FastAPI / Python Example
```python
# App exposes /version so pipelines can verify the deployed build post-deploy
import os
@app.get("/version")
def version():
    return {"build": os.getenv("BUILD_ID", "dev"), "commit": os.getenv("GIT_SHA", "")}
```

## 17. AKS Example
A self-hosted agent pool runs as a Deployment inside the AKS cluster (or a VNet-joined VMSS) so pipelines can deploy to a **private** AKS API server; the agent uses Workload Identity for ACR pull and `kubectl` access — no kubeconfig secrets stored in the pipeline.

## 18. How to Remember
**"Repos, Pipelines, Boards, Artifacts, Test Plans."** YAML + templates, OIDC service connections, Environments with approvals.

## 19. Real-World Analogy
A full factory management system: the blueprint vault (Repos), the automated assembly line with quality gates (Pipelines/Environments), the production schedule board (Boards), the parts warehouse (Artifacts), and the QA department (Test Plans) — all under one roof with sign-off checkpoints.

## 20. One-Page Cheat Sheet
- **Services**: Repos · Pipelines · Boards · Artifacts · Test Plans.
- **Pipelines**: YAML (versioned) + templates; stages/jobs/steps; agents (MS-hosted vs self-hosted in VNet).
- **Secure auth**: OIDC/Workload Identity Federation service connections (no secrets) + Key Vault variable groups.
- **Governance**: Environments with approvals/gates; branch policies + required checks.
- **Traceability**: Boards ↔ commits/PRs ↔ deployments.
- **Note**: overlaps GitHub; enterprises still rely on it for governance.
