# 45 · Helm

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
Helm is the **package manager for Kubernetes** — like apt/npm but for K8s apps. It bundles all your YAML into a reusable, versioned "chart" you can install, upgrade, and roll back with one command.

## 2. Architect-Level Explanation
Templating + release management for Kubernetes manifests:
- **Chart**: package of templated manifests + `values.yaml` (defaults) + metadata (`Chart.yaml`) + dependencies.
- **Templating**: Go templates render manifests from values → environment-specific config from one chart.
- **Release**: an installed instance tracked with revision history (Helm 3 stores state as in-cluster Secrets; no Tiller).
- **Lifecycle**: `install`/`upgrade`/`rollback`/`uninstall`; hooks for pre/post steps.
- **Ecosystem**: repositories (OCI registries like ACR), dependencies (subcharts), and umbrella charts.
- Alternatives/complements: Kustomize (overlays), used with GitOps (ArgoCD/Flux).

## 3. Real Enterprise Use Case
A platform team packages each microservice as a Helm chart with per-environment values (dev/stage/prod). CI builds and pushes charts to ACR (OCI); ArgoCD deploys them; upgrades are versioned and instantly rollback-able — consistent, repeatable releases across 200 services.

## 4. Architecture Diagram (ASCII)
```
   Chart (templates + values.yaml + Chart.yaml)
        │  helm template/install (render with values)
        ▼
   Rendered manifests ─► Kubernetes API ─► Release (rev 3)
        │ history: rev1, rev2, rev3
   helm upgrade → new revision ; helm rollback → previous
   Charts stored in OCI registry (ACR) ; values per environment
```

## 5. Interview Questions
1. What problem does Helm solve?
2. Chart vs release vs values?
3. Helm 2 vs Helm 3 (Tiller)?
4. Helm vs Kustomize?
5. How do you manage env-specific config + secrets?

## 6. Strong Interview Answers
- **Problem**: "It packages, parameterizes, versions, and manages the lifecycle of K8s apps — one chart deploys to many environments via values, with upgrade/rollback and history. It replaces copy-pasting YAML per environment."
- **Chart/release/values**: "A chart is the package (templates + defaults); values.yaml parameterizes it; a release is an installed instance with revision history."
- **Helm 2 vs 3**: "Helm 3 removed Tiller (the cluster-side component with broad permissions) — big security win; state now lives in Secrets and it uses normal RBAC."
- **Helm vs Kustomize**: "Helm templates + packages + lifecycle (good for distributable apps); Kustomize does overlay-based, template-free customization of base manifests (good for simple env diffs). Many teams use both — Helm to package, Kustomize/values for env overlays."
- **Env/secrets**: "Separate values files per env; secrets via external stores (Key Vault CSI, sealed-secrets, SOPS) — never plaintext secrets in values in Git."

## 7. Common Mistakes
- Hardcoding env config instead of values.
- Plaintext secrets in values.yaml (in Git).
- Overcomplex templates (unreadable).
- Not pinning chart/dependency versions.
- Ignoring rollback/history.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Helm | package, version, lifecycle | templating complexity |
| Kustomize | template-free overlays | no packaging/lifecycle |
| Raw YAML | simple | copy-paste, no reuse |

## 9. Production Best Practices
- Chart per service; values per environment.
- Store charts in OCI registry (ACR); pin versions.
- Secrets via Key Vault CSI/sealed-secrets (not values).
- Lint + template-test in CI (`helm lint`, `helm test`).
- Deploy via GitOps (ArgoCD/Flux) for auditability.

## 10. Security Considerations
- Helm 3 (no Tiller); scoped RBAC.
- No secrets in charts/values in Git.
- Verify/sign charts (provenance).
- Scan chart images; restrict registries.

## 11. Cost Optimization
- Standardize resource requests via chart defaults.
- Reuse subcharts to avoid duplication.
- Consistent autoscaling defaults across services.

## 12. Troubleshooting Scenarios
- **Failed upgrade** → `helm rollback <release> <rev>`.
- **Bad render** → `helm template` to inspect output.
- **Values not applied** → precedence (`--set` > `-f` > defaults).
- **Stuck release** → pending state / hooks; check history.

## 13. Hands-on Example
```bash
helm install api ./api-chart -f values-prod.yaml -n app
helm upgrade api ./api-chart -f values-prod.yaml -n app
helm rollback api 1 -n app
helm history api -n app
```

## 14. Terraform Example
```hcl
resource "helm_release" "api" {
  name       = "api"
  namespace  = "app"
  repository = "oci://myacr.azurecr.io/charts"
  chart      = "api"
  version    = "1.4.2"
  values     = [file("values-prod.yaml")]
}
```

## 15. Azure Example
```bash
# Push/pull charts as OCI artifacts in ACR
helm push api-1.4.2.tgz oci://myacr.azurecr.io/charts
helm install api oci://myacr.azurecr.io/charts/api --version 1.4.2 -n app
```

## 16. FastAPI / Python Example
```yaml
# values-prod.yaml drives the deployment for a FastAPI service
image:
  repository: myacr.azurecr.io/api
  tag: "2.0"
replicaCount: 3
resources:
  requests: { cpu: 250m, memory: 256Mi }
env:
  LOG_LEVEL: info
```

## 17. AKS Example
Store service charts in ACR (OCI), deploy to AKS via ArgoCD referencing the chart + env values; Key Vault CSI injects secrets; `helm rollback` (or Argo) reverts on bad releases.

## 18. How to Remember
**"apt/npm for Kubernetes."** Chart = package, values = config, release = installed instance with rollback.

## 19. Real-World Analogy
A meal-kit recipe (chart) with adjustable ingredients (values): the same recipe makes a mild or spicy version (dev/prod) — and you keep every version so you can revert to last week's dish if the new one flops (rollback).

## 20. One-Page Cheat Sheet
- **What**: Kubernetes package manager (templating + lifecycle).
- **Pieces**: Chart (package) + values.yaml (config) + Release (instance w/ history).
- **Lifecycle**: install / upgrade / rollback / uninstall.
- **Helm 3**: no Tiller (secure); state in Secrets; OCI charts in ACR.
- **Secrets**: Key Vault CSI/sealed-secrets — never plaintext in values.
- **Prod**: pin versions, lint/test in CI, deploy via GitOps.
