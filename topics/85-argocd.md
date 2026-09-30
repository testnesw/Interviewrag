# 85 · ArgoCD

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
ArgoCD is a popular GitOps tool for Kubernetes. It runs inside your cluster, watches a Git repo of your Kubernetes manifests, and automatically keeps the cluster in sync with Git — with a nice UI showing what's deployed and whether it's healthy.

## 2. Architect-Level Explanation
A declarative GitOps continuous-delivery controller for Kubernetes:
- **Application CRD**: defines source (Git repo/path/revision, Helm/Kustomize/plain YAML) + destination (cluster/namespace) + **sync policy** (manual or automated, self-heal, prune).
- **Reconciliation**: continuously diffs desired (Git) vs live; shows **Sync status** (Synced/OutOfSync) and **Health** (Healthy/Degraded/Progressing).
- **Sync options**: automated sync, self-heal (revert drift), prune (delete removed resources), sync waves/hooks (ordering, pre/post jobs).
- **App-of-apps / ApplicationSets**: manage many apps/clusters/environments from templates (fleet/multi-tenant scale).
- **Multi-cluster**: one ArgoCD manages many clusters.
- **Security**: SSO/RBAC, projects (guardrails on repos/clusters/namespaces), no cluster creds in external CI.
- **Ecosystem**: **Argo Rollouts** (canary/blue-green), notifications, image updater.
- **UI + CLI + API**: strong visibility into sync/health/diffs; vs **Flux** (lighter, CRD/CLI-centric, no built-in UI).

## 3. Real Enterprise Use Case
A platform team runs ArgoCD with **ApplicationSets** generating an Application per (team × environment) across multiple AKS clusters. Automated sync + self-heal keep everything aligned with Git; ArgoCD Projects restrict which repos/namespaces each team can target; Argo Rollouts drives canaries. The UI gives real-time sync/health across the fleet.

## 4. Architecture Diagram (ASCII)
```
   Git (manifests: Helm/Kustomize/YAML)
        ▲ watch/diff            │ apply
   [ ArgoCD controller (in cluster) ]  ── UI / CLI / API
        │ Application CRD: source→destination + syncPolicy
        │ status: Synced/OutOfSync · Healthy/Degraded
   ApplicationSet ─► many Apps (team × env × cluster)
   syncPolicy: automated + selfHeal + prune | waves/hooks
   Projects + SSO/RBAC guardrails | Argo Rollouts (canary)
```

## 5. Interview Questions
1. What is the ArgoCD Application CRD?
2. What do sync status and health mean?
3. What are self-heal and prune?
4. How do you scale to many apps/clusters?
5. ArgoCD vs Flux?

## 6. Strong Interview Answers
- **Application CRD**: "It declaratively defines an app's Git source (repo, path, revision, and tool — Helm/Kustomize/YAML), its destination cluster/namespace, and a sync policy. ArgoCD reconciles the cluster to that spec."
- **Sync/health**: "**Sync status** is whether live state matches Git (Synced vs OutOfSync); **health** is whether the resources are actually working (Healthy/Degraded/Progressing). Both matter — something can be Synced but Degraded."
- **Self-heal/prune**: "Self-heal reverts manual drift back to Git automatically; prune deletes resources removed from Git so the cluster doesn't accumulate orphans. Together with automated sync they enforce Git as the source of truth."
- **Scale**: "**ApplicationSets** generate Applications from generators (list, cluster, Git directory/PR) — so I template one spec across many teams/environments/clusters, plus the app-of-apps pattern for bootstrapping. Projects add guardrails per tenant."
- **vs Flux**: "ArgoCD has a rich UI/API, strong multi-tenancy (Projects, SSO/RBAC), and ApplicationSets — great for platform teams needing visibility. Flux is lighter, CRD/GitOps-toolkit-based, integrates tightly with Kubernetes and Terraform, but has no built-in UI. Both are CNCF-graduated; choice depends on UI/multi-tenancy needs vs simplicity."

## 7. Common Mistakes
- Manual `kubectl` changes fighting self-heal.
- No prune → orphaned resources linger.
- Giant single Application instead of ApplicationSets.
- Weak Project/RBAC guardrails (teams deploy anywhere).
- Plaintext secrets in Git (use sealed-secrets/External Secrets).

## 8. Trade-offs
| Aspect | ArgoCD | Flux |
|--------|--------|------|
| UI | rich built-in | none (CLI/CRD) |
| Multi-tenancy | Projects/SSO | namespaces/RBAC |
| Footprint | heavier | lighter |
| Scale pattern | ApplicationSets | Kustomizations |

## 9. Production Best Practices
- Automated sync + self-heal + prune.
- ApplicationSets for fleet/multi-env; app-of-apps for bootstrap.
- Projects + SSO/RBAC guardrails per team.
- Pin image digests; declarative Helm/Kustomize.
- Sync waves/hooks for ordering (e.g., migrations before app); Argo Rollouts for progressive delivery.

## 10. Security Considerations
- SSO + RBAC + Projects restrict repos/clusters/namespaces.
- No external cluster creds; agent pulls from Git.
- Encrypted/external secrets; signed images + admission checks.
- Audit via Git history + ArgoCD events.

## 11. Cost Optimization
- Drift-free fleet reduces incident cost.
- One ArgoCD managing many clusters (less tooling overhead).
- Prune removes orphaned, billable resources.

## 12. Troubleshooting Scenarios
- **OutOfSync** → Git diff; sync or fix manifest.
- **Synced but Degraded** → app crashloop/probe failure, not a sync issue.
- **Drift keeps reverting** → self-heal working; edit Git instead.
- **Orphaned resources** → enable prune.
- **App can't deploy to cluster/ns** → Project restrictions/RBAC.

## 13. Hands-on Example
```bash
argocd app create api --repo https://github.com/org/config \
  --path apps/api --dest-server https://kubernetes.default.svc --dest-namespace app
argocd app set api --sync-policy automated --self-heal --auto-prune
argocd app get api
```

## 14. Terraform Example
```hcl
resource "helm_release" "argocd" {
  name = "argocd" namespace = "argocd" create_namespace = true
  repository = "https://argoproj.github.io/argo-helm" chart = "argo-cd"
  set { name = "configs.params.server\\.insecure" value = "false" }
}
```

## 15. Azure Example
Install ArgoCD on AKS (Helm) or use the AKS **GitOps (Flux) extension** if standardizing on Flux. ArgoCD connects to Azure Repos/GitHub, authenticates users via **Entra ID SSO**, and deploys signed images pulled from ACR via Workload Identity.

## 16. FastAPI / Python Example
```python
# Query ArgoCD API to expose deployment sync/health on an internal status page
import httpx
@app.get("/deploy/status/{app}")
async def status(app: str):
    async with httpx.AsyncClient(verify=False) as c:
        r = await c.get(f"https://argocd/api/v1/applications/{app}",
                        headers={"Authorization": f"Bearer {ARGO_TOKEN}"})
    d = r.json()["status"]
    return {"sync": d["sync"]["status"], "health": d["health"]["status"]}
```

## 17. AKS Example (Application manifest)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: { name: api, namespace: argocd }
spec:
  project: team-payments
  source: { repoURL: https://github.com/org/config, path: apps/api, targetRevision: main }
  destination: { server: https://kubernetes.default.svc, namespace: app }
  syncPolicy:
    automated: { selfHeal: true, prune: true }
    syncOptions: [CreateNamespace=true]
```

## 18. How to Remember
**"Application CRD (source→dest+syncPolicy); Synced+Healthy; self-heal+prune; ApplicationSets for scale."** GitOps with a UI.

## 19. Real-World Analogy
An automated facilities manager for a chain of stores (clusters): it holds the master blueprint (Git), constantly walks each store to check it matches (sync/health), fixes anything staff rearranged (self-heal), removes furniture no longer on the plan (prune), and uses templates to roll the same layout to every new store (ApplicationSets) — all viewable on one dashboard.

## 20. One-Page Cheat Sheet
- **What**: GitOps CD controller for Kubernetes with UI/CLI/API.
- **Application CRD**: Git source (Helm/Kustomize/YAML) → destination + syncPolicy.
- **Status**: Sync (Synced/OutOfSync) + Health (Healthy/Degraded).
- **Policies**: automated sync, **self-heal** (revert drift), **prune** (delete orphans), waves/hooks.
- **Scale**: ApplicationSets + app-of-apps; Projects + SSO/RBAC guardrails; multi-cluster.
- **vs Flux**: ArgoCD = rich UI + multi-tenancy; Flux = lighter, CLI/CRD. Pair with Argo Rollouts for canary.
