# DEEP MECHANICS · Argo CD

> Level 2 — Application CRD, sync/health, sync waves & hooks, app-of-apps, and
> multi-cluster.

---

## 0. The precise mental model
Argo CD is a **Kubernetes-native GitOps controller**. You declare an **`Application`** (CRD) pointing at a Git repo path + a destination cluster/namespace; Argo continuously **compares desired (Git) vs live**, reports **Sync + Health** status, and (auto or manual) **syncs** to converge. It runs *inside* the cluster and pulls — no external creds.

---

## 1. The Application CRD
```yaml
kind: Application
spec:
  source: { repoURL, path, targetRevision }   # Git source (or Helm/Kustomize)
  destination: { server, namespace }          # target cluster/ns
  syncPolicy:
    automated: { prune: true, selfHeal: true }
```
- Supports **plain manifests, Helm, Kustomize, Jsonnet**.
- `targetRevision` = branch/tag/commit.

## 2. Sync & health status
- **Sync status**: `Synced` (live matches Git) vs `OutOfSync` (drift/new commit).
- **Health status**: per-resource (Healthy/Progressing/Degraded/Missing) using built-in + custom checks.
- UI/CLI shows the diff → one-click or auto sync.

## 3. Sync policies
- **Manual** (approve each sync) vs **Automated**.
- **`selfHeal: true`** → revert manual cluster drift back to Git.
- **`prune: true`** → delete resources removed from Git (careful).

## 4. Ordering: sync waves & hooks
- **Sync waves** (`argocd.argoproj.io/sync-wave`) → order resource application (e.g., CRDs before CRs, DB before app).
- **Resource hooks** (`PreSync/Sync/PostSync/SyncFail`) → run Jobs at phases (DB migrations pre-sync, smoke tests post-sync).

## 5. App-of-apps & scaling
- **App-of-apps**: a root Application that deploys child Applications → manage many apps declaratively.
- **ApplicationSet**: templated generation of Applications (per cluster/env/repo) → fleet management.
- **Multi-cluster**: one Argo CD manages many destination clusters (register cluster creds).

## 6. Security & extras
- **RBAC** + SSO (OIDC/SAML); projects (**AppProject**) scope which repos/clusters/namespaces an app may use.
- **Progressive delivery** via **Argo Rollouts** (canary/blue-green) integrates with Argo CD.
- Secrets via external-secrets/SOPS (don't store plaintext).

## 7. The hard follow-ups (with answers)
1. **"Core object?"** → the **`Application`** CRD = repo/path + destination + sync policy. (§1)
2. **"Sync vs Health?"** → Sync = matches Git or not; Health = resource is actually working. (§2)
3. **"Auto-fix manual `kubectl` changes?"** → `selfHeal: true`. (§3)
4. **"Run DB migration before app deploy?"** → **PreSync hook** (+ sync waves for ordering). (§4)
5. **"Manage 100 apps/clusters?"** → **app-of-apps** / **ApplicationSet**. (§5)
6. **"Canary with Argo?"** → **Argo Rollouts** alongside Argo CD. (§6)
7. **"Scope what an app can deploy?"** → **AppProject** RBAC restrictions. (§6)

## 8. One-screen recall
- **Argo CD** = K8s-native GitOps controller; pulls from Git, reconciles.
- **`Application` CRD**: source (repo/path, Helm/Kustomize) + destination + syncPolicy.
- **Status**: **Sync** (Synced/OutOfSync) + **Health** (Healthy/Degraded…).
- **Policy**: automated + **selfHeal** (revert drift) + **prune** (delete removed).
- **Ordering**: **sync waves** + **hooks** (PreSync migrations, PostSync tests).
- **Scale**: **app-of-apps / ApplicationSet**, multi-cluster; **AppProject** RBAC; Rollouts for canary.

> Next: API Management.
