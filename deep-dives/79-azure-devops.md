# Deep Dive · Azure DevOps

> Phase 4 (Delivery / CI-CD) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure DevOps (ADO) is Microsoft's **end-to-end DevOps suite**: **Boards** (agile work tracking), **Repos** (Git), **Pipelines** (CI/CD), **Artifacts** (package feeds), and **Test Plans**. Its core strength is **enterprise release orchestration** — YAML pipelines with **stages, environments, approvals, gates, and variable/secret management**, authenticating to Azure via **service connections (now OIDC/workload-identity federation)**. It's the go-to for organizations wanting **integrated ALM + governed release management**, especially with existing Microsoft/enterprise processes.

---

## 2. Architect-Level Explanation
Pipelines model: **Pipeline → Stages → Jobs → Steps/Tasks**, run on **agents** (Microsoft-hosted or self-hosted in your VNet).
- **Triggers**: CI (push/PR), scheduled, manual, pipeline-completion.
- **Environments**: deployment targets with **approvals, checks, and gates** (e.g., pre-deploy approval, business hours, query Azure Monitor, invoke REST).
- **Service connections**: auth to Azure/ACR/K8s — prefer **Workload Identity Federation (OIDC)** over long-lived service-principal secrets.
- **Variable groups + Key Vault integration** for secrets; **secure files**.
- **Templates** (YAML) for reusable, governed pipeline definitions across teams.
- **Artifacts feeds** for versioned packages (NuGet/npm/Python) with upstream sources.

Architecturally: **governed, template-driven, approval-gated delivery** integrated with work tracking — strong for regulated/enterprise change control.

---

## 3. Why It Exists
- **Problem**: fragmented ALM (separate tools for backlog, repo, build, release, packages) and ungoverned deployments.
- **Breakthrough**: **one integrated suite** with traceability from work item → commit → build → release, plus rich **release governance** (approvals/gates).
- **Why enterprises adopt it**: mature approvals/gates, auditability, template governance, on-prem option (Azure DevOps Server), and deep Azure integration.
- **vs GitHub Actions**: ADO excels at **enterprise release orchestration + ALM breadth**; Actions excels at **GitHub-native, OIDC-first, marketplace velocity**.

---

## 4. Internal Working
**Pipeline run:**
```
1. Trigger (CI/PR/schedule/manual) starts the pipeline
2. Stages run in order (or parallel); each stage = jobs; jobs = steps/tasks
3. Agent (hosted/self-hosted) executes steps in a clean workspace
4. Deployment jobs target an Environment → checks/approvals/gates evaluated first
5. Service connection auth: OIDC federation → scoped Azure token (no stored secret)
6. Artifacts published/consumed; test results + coverage reported
7. Traceability links work items ↔ commits ↔ builds ↔ releases
```
Key mechanics:
- **Environments + checks**: approvals, branch control, business-hours, Azure Monitor query gate, invoke-REST/Function gate.
- **Templates**: `extends`/`template` for reuse + **required templates** to enforce org policy.
- **Variable groups**: shared vars/secrets (Key Vault-linked).
- **Multi-stage YAML** = pipeline-as-code (versioned in Repos/GitHub).

---

## 5. Enterprise Use Case
A regulated enterprise runs GenAI delivery on ADO: **Boards** tracks work with full traceability; **Repos** hosts code; a **multi-stage YAML pipeline** builds/tests/scans, publishes the image to **ACR**, and deploys to **AKS** across dev→stage→prod **Environments**. Prod requires **two approvers + an Azure Monitor health gate + business-hours window**; a **required pipeline template** enforces mandatory security scans org-wide. Auth uses **Workload Identity Federation** (no SP secrets). Every deployment is auditable from work item to release — satisfying change control.

---

## 6. Real Production Architecture
```
 Boards (work items) ── traceability ──► Repos (Git, PR policies)
                                           │ CI trigger
                                           ▼
 Multi-stage YAML Pipeline (required template enforces scans):
   Build ─► Test ─► Scan (Trivy/Credscan) ─► Publish image → ACR
       │
   Deploy dev (auto) ─► Deploy stage (1 approval) ─► Deploy prod
                                                      │ checks: 2 approvers +
                                                      │ Azure Monitor gate + hours
                                                      ▼  (OIDC service connection)
                                                    AKS
 Artifacts feeds (packages) · Variable groups ← Key Vault · Self-hosted agents (VNet)
```

---

## 7. Security Best Practices
- **Workload Identity Federation (OIDC) service connections** — retire long-lived SP secrets.
- **Environment checks/approvals** on stage/prod; **branch control** (deploy only from `main`/release).
- **Secrets in Key Vault** via variable groups; mark secret, never log; **secure files** for certs.
- **Least-privilege service connections** scoped to the target resource group/registry.
- **Required YAML templates** to enforce mandatory steps (scans, approvals) org-wide.
- **Repo policies**: PR reviews, build validation, work-item linking, branch protection.
- **Self-hosted agents hardened + isolated** (VNet, ephemeral where possible); restrict who can edit pipelines.
- **Credential/secret scanning** (CredScan) in pipeline.

---

## 8. Scaling Strategy
- **YAML templates** for reusable, governed pipelines across many teams.
- **Self-hosted agent pools (scale sets / ARC)** for capacity + private access.
- **Parallel jobs + matrix + caching** to speed builds.
- **Artifacts feeds** with upstream sources for package scale/governance.
- **Pipeline-completion triggers** to compose complex release chains.

---

## 9. High Availability Strategy
- **Microsoft-hosted agents** are managed/HA; **self-hosted pools** span zones/scale sets.
- **Idempotent, re-runnable stages**; retry transient tasks.
- **Environment gates** block unhealthy deploys; **rollback pipelines** ready.
- Redundant agents so a pool outage doesn't halt delivery.

---

## 10. Disaster Recovery Strategy
- **Pipelines-as-code (YAML) in Repos** → reproducible; export/backup org config.
- **Self-hosted agent infra as IaC** → redeploy.
- **Retained artifacts/images (by digest)** for recovery; **release history** for audit.
- Fast **redeploy/rollback** to healthy region/version; document RTO/RPO.

---

## 11. Cost Optimization Strategy
- **Caching + parallelism + fail-fast** to cut agent minutes.
- **Self-hosted agents** cheaper for heavy/steady load; **scale-to-zero** scale sets.
- **Right-size parallel jobs** (licensed parallelism); avoid redundant triggers (path filters).
- **Artifacts retention policies**; clean old builds/releases.
- Monitor pipeline analytics for slow/wasteful stages.

---

## 12. Common Production Challenges
- **Long-lived SP secrets** in service connections → migrate to OIDC federation.
- **Ungoverned pipelines** (teams skip scans) → required templates.
- **Approval fatigue / bottlenecks** → tune gates, automate health checks.
- **Self-hosted agent drift** → ephemeral/scale-set agents.
- **Secret leakage in logs** → mask, use Key Vault, CredScan.
- **Flaky/slow pipelines** → caching, parallelism, test isolation.
- **Classic (UI) release pipelines** legacy → move to multi-stage YAML.

---

## 13. Monitoring and Observability
- **Pipeline analytics**: pass rate, duration, failure trends, flaky tests.
- **Deployment/environment history** with approvals + gate results (audit).
- **Test + coverage** reports; **Azure Monitor gate** queries during deploy.
- **Traceability**: work item ↔ commit ↔ build ↔ release.
- **Alerts/notifications** on failed prod deploys (Teams/email).

---

## 14. Troubleshooting Scenarios
- **Service connection auth fails** → OIDC federation subject/issuer or SP secret expired; re-federate.
- **Deploy blocked at prod** → pending approval or failing gate (Azure Monitor query); check environment checks.
- **Agent can't reach private AKS/ACR** → use self-hosted VNet agent pool.
- **Secret empty in job** → variable group not linked/authorized to pipeline; grant access.
- **Pipeline ran from wrong branch** → missing branch control on environment; add check.
- **Template change broke many pipelines** → version templates; test before rolling out.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| ADO vs GitHub Actions | rich ALM + governance | less marketplace velocity |
| Required templates | enforce policy | rigidity |
| Many gates | safe, compliant | slower delivery |
| Self-hosted agents | VNet + cost | maintenance |

---

## 16. When NOT to use it
- **Code on GitHub with OIDC-first, marketplace-heavy** needs → **GitHub Actions** is more native.
- **Small team wanting lightweight CI** → Actions/simple CI.
- **Pure K8s continuous delivery** → pair with **Argo CD/Flux (GitOps)** for CD.
- Microsoft is converging investment toward GitHub; **greenfield often starts on GitHub Actions** unless ADO governance/ALM is required.

---

## 17. Comparison with Alternatives
| Tool | Strength | Auth to Azure | Best for |
|------|----------|---------------|----------|
| **Azure DevOps** | ALM breadth + release governance | OIDC/service connection | enterprise/regulated delivery |
| GitHub Actions | native, OIDC-first, marketplace | OIDC | GitHub-hosted code |
| GitLab | integrated DevOps | OIDC | GitLab-hosted |
| Jenkins | flexible, on-prem | plugins | legacy/on-prem control |
| Argo CD/Flux | GitOps CD | in-cluster | K8s delivery |

---

## 18. Interview Questions
1. What are the five ADO services and how do they connect?
2. Multi-stage YAML: stages/jobs/steps/environments?
3. How do environment approvals and gates work?
4. Service connections — how do you auth securely (OIDC)?
5. How do you enforce org-wide pipeline policy (templates)?
6. Hosted vs self-hosted agents?
7. How do you manage secrets in ADO?
8. ADO vs GitHub Actions — when each?
9. How do you deploy to AKS with governance?
10. How do you make delivery auditable for regulators?

---

## 19. Strong Interview Answers
- **Suite**: "Boards (work), Repos (Git), Pipelines (CI/CD), Artifacts (packages), Test Plans — integrated so I get traceability from work item to commit to build to release, which regulators love."
- **Environments/gates**: "Deployment jobs target Environments protected by checks — required approvals, branch control, business-hours windows, and gates like an Azure Monitor query that must be healthy before promotion. That's governed, auditable release management."
- **Secure auth**: "I use Workload Identity Federation service connections — OIDC to Entra with no stored SP secret — scoped least-privilege to the target resource group/registry. Legacy SP-secret connections are a leak risk I migrate away from."
- **Governance at scale**: "Required YAML templates enforce mandatory steps — security scans, approvals — across all pipelines via `extends`, so teams can't bypass policy. Variable groups pull secrets from Key Vault."
- **ADO vs Actions**: "ADO for enterprise ALM breadth and rich release governance, or Azure Repos. Actions for GitHub-native, OIDC-first, marketplace velocity. Both do OIDC to Azure now, so I choose by where the code lives and how much release governance/ALM is needed."

---

## 20. Architecture Diagrams
**Governed multi-stage release:**
```
CI (build/test/scan → ACR) ─► Env:dev (auto)
   ─► Env:stage (approval) ─► Env:prod
        checks: 2 approvers + Azure Monitor gate + business hours + branch=main
        auth: OIDC service connection (no SP secret) ─► AKS
Required template enforces scans across all pipelines
```

---

## 21. Real Project Example
**Regulated GenAI delivery.** Multi-stage YAML: build→test→CredScan+Trivy→publish to ACR→deploy dev/stage/prod Environments. Prod gated by two approvers, an Azure Monitor health gate, and a business-hours window; deploys only from `main`. A **required org template** enforces the security stages so no team can skip them. Service connections use **Workload Identity Federation** (no secrets), scoped per resource group. Boards links every deployment back to a work item. An auditor traced a production change from ticket → PR → build → approved release in minutes.

---

## 22. Whiteboard Design Question
> *"Design a governed CI/CD platform on Azure DevOps for a regulated enterprise deploying GenAI to AKS."*

Cover: Repos with PR policies + build validation + work-item linking → multi-stage YAML (build/test/scan/publish) → required templates enforcing scans → OIDC service connections (least privilege) → Environments with approvals/gates (Azure Monitor health, business hours, branch control, 2 approvers for prod) → variable groups from Key Vault → self-hosted VNet agents for private AKS/ACR → artifacts feeds → rollback pipeline → full traceability/audit. Emphasize governance, auditability, keyless auth.

---

## 23. Design Review Questions
- Service connections using **OIDC federation** (no SP secrets), least-privilege scoped?
- **Environment approvals/gates** on stage/prod (reviewers, health, branch)?
- **Required templates** enforcing mandatory security steps?
- **Secrets** from Key Vault via variable groups; CredScan enabled?
- **Self-hosted agents** for private access, hardened/ephemeral?
- **Repo policies** (PR review, build validation, work-item link)?
- **Traceability** work item→commit→build→release for audit?
- **Rollback** pipeline defined?

---

## 24. Hands-on Example
```yaml
# azure-pipelines.yml — multi-stage, OIDC service connection, gated prod
trigger: [ main ]
stages:
- stage: Build
  jobs:
  - job: build
    pool: { vmImage: ubuntu-latest }
    steps:
      - script: pytest -q
      - task: Docker@2
        inputs: { command: buildAndPush, repository: orchestrator, tags: $(Build.BuildId),
                  containerRegistry: acr-oidc-connection }   # OIDC service connection
- stage: DeployProd
  dependsOn: Build
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
  jobs:
  - deployment: prod
    environment: prod            # approvals + gates configured on the Environment
    strategy:
      runOnce:
        deploy:
          steps:
            - task: KubernetesManifest@1
              inputs: { action: deploy, kubernetesServiceConnection: aks-oidc,
                        manifests: k8s/deploy.yaml, containers: 'genaiacr.azurecr.io/orchestrator:$(Build.BuildId)' }
```

---

## 25. Terraform Example
```hcl
# Federated credential for an ADO service connection (Workload Identity Federation)
resource "azuread_application_federated_identity_credential" "ado" {
  application_object_id = var.app_object_id
  display_name          = "ado-prod-sc"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://vstoken.dev.azure.com/${var.ado_org_id}"
  subject               = "sc://${var.ado_org}/${var.ado_project}/aks-oidc"  # service connection
}
resource "azurerm_role_assignment" "ado_aks" {
  scope                = var.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.app_sp_object_id                                 # least privilege
}
```

---

## 26. Azure Example
```bash
# Required template pattern: every pipeline must extend the governed template
# templates/secure-build.yml (in a central repo) enforces scans + approvals.
# Consumer pipeline:
#   extends:
#     template: secure-build.yml@templates
#     parameters: { image: orchestrator }
# Branch policy so pipelines can't be edited to bypass it:
az repos policy required-reviewer create --project genai --repository infra \
  --branch main --required-reviewer-ids $SEC_TEAM_GROUP_ID --blocking true
```

---

## 27. Code Example
```yaml
# Environment gate: block prod deploy unless Azure Monitor reports healthy
# (configured as an "Invoke Azure Monitor" check on the prod Environment)
#   Query: avg error rate < 1% over last 10 min → pass, else block
# Plus required approvals + business-hours check → governed promotion.
# Rollback pipeline (manual trigger) re-deploys previous image digest:
parameters: [ { name: previousDigest, type: string } ]
steps:
  - script: kubectl set image deploy/orchestrator app=genaiacr.azurecr.io/orchestrator@${{ parameters.previousDigest }}
```

---

## 28. Things Architects Must Remember
- **ADO = integrated ALM** (Boards/Repos/Pipelines/Artifacts/Test) with strong **release governance**.
- **Environments + approvals + gates** = auditable, controlled promotion (health/hours/branch/reviewers).
- **OIDC/Workload Identity Federation service connections** — kill long-lived SP secrets.
- **Required YAML templates** enforce org policy (mandatory scans/approvals).
- **Secrets from Key Vault** via variable groups; least-privilege service connections.
- **Self-hosted VNet agents** for private AKS/ACR; hardened/ephemeral.
- **Traceability** (work item→release) is the regulated-industry superpower.
- **ADO for governance/ALM; GitHub Actions for GitHub-native/marketplace** — choose by context (MS is converging toward GitHub).

---

## 29. Mnemonics and Memory Tricks
- **Suite "B-R-P-A-T"**: **B**oards, **R**epos, **P**ipelines, **A**rtifacts, **T**est Plans.
- **Pipeline "S-J-S"**: **S**tages → **J**obs → **S**teps.
- **Prod gate "A-H-B-R"**: **A**pprovals, **H**ealth (Azure Monitor), **B**usiness hours, **R**estrict branch.
- **"Templates enforce, environments gate."**
- **"Federate, don't store"** — OIDC service connections.

---

## 30. One-Page Interview Revision Sheet
- **What**: integrated DevOps suite — Boards, Repos, Pipelines, Artifacts, Test Plans.
- **Pipelines**: multi-stage YAML — Stages→Jobs→Steps on agents (hosted/self-hosted VNet).
- **Governance**: Environments with approvals + gates (Azure Monitor health, business hours, branch control, reviewers).
- **Auth**: Workload Identity Federation (OIDC) service connections — least privilege, no SP secrets.
- **Policy at scale**: required YAML templates (`extends`) enforce mandatory steps org-wide.
- **Secrets**: Key Vault-linked variable groups; CredScan; secure files.
- **Scale/HA/DR**: templates + agent scale sets; pipelines-as-code reproducible; retained artifacts + rollback pipeline.
- **Traceability**: work item↔commit↔build↔release (audit).
- **vs Actions**: ALM breadth + governance vs GitHub-native/OIDC-first/marketplace.
- **Remember**: **B-R-P-A-T** suite; **S-J-S** pipeline; prod gate **A-H-B-R**; templates enforce/environments gate; federate don't store.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Name the ADO services and show how traceability flows through them.
2. Design a governed prod promotion with approvals + health gate + branch control.
3. How do you authenticate ADO to Azure without long-lived secrets?
4. Enforce mandatory security scans across 40 pipelines teams can't bypass. How?
5. Hosted vs self-hosted agents — when must you use self-hosted?
6. Your prod deploy is stuck — list every gate/check that could be blocking it.
7. How do you manage and protect secrets in ADO pipelines?
8. ADO vs GitHub Actions — decide for a regulated Azure-Repos enterprise.
9. Make delivery fully auditable for a pharma regulator — what do you show them?
10. Design a safe rollback for a bad GenAI release on AKS.

---

> 🎉 **Phase 4 complete!** Next: **Phase 5 — .NET Core, Microservices, Enterprise System Design.**
