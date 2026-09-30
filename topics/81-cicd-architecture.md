# 81 · CI/CD Architecture

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
CI/CD is the practice of automatically building, testing, and deploying software. **CI** (Continuous Integration) merges and tests code frequently; **CD** (Continuous Delivery/Deployment) automatically releases it — so changes reach users quickly and safely.

## 2. Architect-Level Explanation
CI/CD architecture is the end-to-end automated path from commit to production:
- **CI**: on every commit/PR — build, unit/integration tests, lint, security scans (SAST/SCA), produce a **versioned, immutable artifact** (container image by digest).
- **CD**: **Continuous Delivery** (auto to staging, manual approval to prod) vs **Continuous Deployment** (fully automated to prod). Promote the *same* artifact across environments (build once, deploy many).
- **Pipeline stages**: source → build → test → scan → package → deploy (dev→stage→prod) → verify.
- **Deployment strategies**: rolling, blue-green, canary, feature flags (see topics 82–83).
- **Quality gates**: tests, coverage, security/policy, approvals, progressive rollout with automated rollback on SLO breach.
- **Two models**: **push-based** (pipeline runs `kubectl`/Helm) vs **pull-based GitOps** (ArgoCD/Flux reconciles from Git — see 84–85).
- **DORA metrics**: deployment frequency, lead time, change failure rate, MTTR — measure delivery performance.
- **Principles**: automation, immutability, fast feedback, small batches, everything-as-code, secure supply chain.

## 3. Real Enterprise Use Case
A platform team builds one image per commit (tested + scanned + signed, pushed to ACR by digest), then promotes that identical digest through dev → stage → prod. Prod uses canary + automated rollback on error-rate SLO breach. GitOps (ArgoCD) reconciles cluster state from Git, and DORA metrics are tracked on a dashboard.

## 4. Architecture Diagram (ASCII)
```
   Commit/PR
     │  CI: build ─► test ─► scan(SAST/SCA) ─► package (image@sha, signed) ─► ACR
     ▼
   CD (promote SAME artifact):
     deploy dev ─► [tests] ─► stage ─► [approval] ─► prod
                                          │ strategy: rolling/blue-green/canary
                                          │ verify SLOs ─► auto-rollback on breach
   Model: push (kubectl/Helm)  OR  pull/GitOps (ArgoCD reconciles from Git)
   Measure: DORA (freq, lead time, CFR, MTTR)
```

## 5. Interview Questions
1. CI vs CD (delivery vs deployment)?
2. Why build once and promote the same artifact?
3. Push-based vs pull-based (GitOps) deployment?
4. What quality gates belong in a pipeline?
5. How do you measure delivery performance?

## 6. Strong Interview Answers
- **CI vs CD**: "CI continuously integrates and tests every change, producing a validated artifact. Continuous Delivery keeps it always deployable with a manual prod approval; Continuous Deployment removes that gate — every green change ships automatically."
- **Build once**: "Build a single immutable artifact (image by digest), test it, and promote that exact artifact through environments. Rebuilding per environment risks discrepancies — you'd be shipping something you never tested. Config differs per env, the artifact doesn't."
- **Push vs pull**: "Push pipelines run `kubectl`/Helm against the cluster — simple but the cluster trusts the pipeline and there's drift risk. Pull/GitOps (ArgoCD/Flux) has an in-cluster agent reconcile desired state from Git — better security (no external cluster creds), drift detection, and auditability."
- **Gates**: "Unit + integration tests, coverage thresholds, SAST/dependency/secret scanning, IaC/policy checks, image signing, environment approvals, and progressive rollout with automated rollback on SLO breach."
- **Measure**: "DORA metrics — deployment frequency, lead time for changes, change failure rate, and MTTR — plus SLOs. They tell me if the pipeline is fast *and* stable."

## 7. Common Mistakes
- Rebuilding artifacts per environment (untested drift).
- No automated tests/scans (ship bugs/vulns).
- Big-bang deploys with no rollback strategy.
- Cluster credentials stored in external pipelines (push, no GitOps).
- Manual, snowflake environments (config drift).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Continuous Deployment | fast | needs strong tests/guardrails |
| GitOps (pull) | secure, auditable | new tooling/model |
| Push pipeline | simple | drift, cluster creds |

## 9. Production Best Practices
- Build once (immutable, signed image by digest); promote same artifact.
- Automated tests + security/policy gates; fail fast.
- Progressive delivery (canary/blue-green) + automated rollback.
- GitOps for deployment where possible; everything-as-code.
- Track DORA + SLOs; small, frequent batches.

## 10. Security Considerations
- Secretless auth (OIDC), least-privilege deploy identity.
- Supply-chain: SAST/SCA, image signing + provenance, admission verification.
- GitOps removes external cluster credentials.
- Environment approvals + audit trail.

## 11. Cost Optimization
- Cache/parallelize builds; fail fast (cheap unit tests first).
- Ephemeral/auto-scaled runners; scale-to-zero.
- Smaller images → faster deploys; fewer failed-deploy reworks.

## 12. Troubleshooting Scenarios
- **"Works in stage, breaks in prod"** → different artifact rebuilt / config drift.
- **Slow lead time** → serial stages, no caching, manual steps.
- **High change-failure rate** → weak gates; add tests/canary.
- **Drift** → manual cluster changes; adopt GitOps.
- **Rollback failed** → non-immutable artifact / stateful migration not backward-compatible.

## 13. Hands-on Example
```yaml
# Promote the SAME image digest across environments
stages: [build, deploy-dev, deploy-stage, deploy-prod]
# build: docker build → push → capture DIGEST=sha256:...
# each deploy: helm upgrade --set image.digest=$DIGEST (identical artifact)
```

## 14. Terraform Example
```hcl
# Pipeline provisions/uses ACR + AKS; deploy identity via OIDC (least privilege)
resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.cicd_identity_object_id
}
```

## 15. Azure Example
Build/test/scan in Azure DevOps or GitHub Actions → push signed image to **ACR** by digest → promote through **AKS** environments with approvals; optionally let **GitOps (Flux/ArgoCD)** reconcile manifests from Git for the deploy step.

## 16. FastAPI / Python Example
```python
# Post-deploy verification the pipeline calls before marking a stage healthy
@app.get("/health/deep")
async def deep_health():
    return {"db": await db_ok(), "cache": await cache_ok(), "build": BUILD_SHA}
# canary controller checks error rate/latency here → promote or rollback
```

## 17. AKS Example
The pipeline deploys a canary to AKS (e.g., 5% via service mesh/Argo Rollouts), watches Prometheus error-rate and p99 for N minutes, and auto-promotes to 100% or rolls back — all driven by the same signed image digest that passed CI.

## 18. How to Remember
**"Build once, test hard, promote the same artifact, deploy progressively, measure DORA."** Prefer GitOps for the deploy.

## 19. Real-World Analogy
An automated bottling line: each batch is brewed and quality-tested once (build + CI), then the *same* certified batch is shipped to regional stores (promotion), first to a few outlets to check reception (canary), and pulled instantly if customers report issues (auto-rollback).

## 20. One-Page Cheat Sheet
- **CI**: build + test + scan on every change → immutable, signed artifact (image@digest).
- **CD**: Delivery (manual prod gate) vs Deployment (fully automated).
- **Golden rule**: build once, promote the *same* artifact; config per env.
- **Strategies**: rolling / blue-green / canary + feature flags; auto-rollback on SLO breach.
- **Models**: push (kubectl/Helm) vs pull/GitOps (ArgoCD/Flux — secure, auditable).
- **Gates + measure**: tests, coverage, SAST/SCA, signing, approvals; DORA metrics.
