# 84 · GitOps

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
GitOps means using **Git as the single source of truth** for your infrastructure and deployments. You describe the desired state in Git, and an automated agent continuously makes the real system match it. To change something, you change Git — not the cluster directly.

## 2. Architect-Level Explanation
An operational model built on declarative desired-state + continuous reconciliation:
- **Four principles** (OpenGitOps): (1) **declarative** desired state, (2) **versioned & immutable** in Git, (3) **pulled automatically**, (4) **continuously reconciled**.
- **Pull-based**: an in-cluster agent (**ArgoCD**/**Flux**) watches Git and applies changes — the cluster pulls, rather than a pipeline pushing. No external system holds cluster credentials.
- **Reconciliation loop**: continuously compares live state vs Git; **self-heals** drift (manual `kubectl` changes get reverted).
- **Benefits**: auditability (Git history = deployment log), easy rollback (`git revert`), PR-based approvals, security (no cluster creds in CI), consistency across clusters.
- **Structure**: separate app-source repo vs **config/manifests repo**; CI builds image + updates manifest (image digest) → GitOps agent deploys.
- **Progressive delivery**: integrates with Argo Rollouts/Flagger.
- **Multi-cluster/fleet**: manage many clusters from Git (app-of-apps, Flux Kustomizations).
- **Secrets**: sealed-secrets/SOPS/External Secrets (never plaintext in Git).

## 3. Real Enterprise Use Case
A platform team manages 30 AKS clusters via Flux: each cluster's desired state lives in Git; CI updates a manifest with the new signed image digest via PR; on merge, Flux reconciles the change. Manual cluster edits are auto-reverted, `git revert` rolls back instantly, and Git history is the complete, auditable deployment record.

## 4. Architecture Diagram (ASCII)
```
   Dev ─► PR to config repo (declarative manifests/Helm/Kustomize)
                     │ merge (reviewed, audited)
        Git (single source of truth, versioned)
                     ▲ pull + reconcile        │
        [ ArgoCD / Flux agent IN cluster ] ────┘
                     │ apply desired state
              AKS cluster(s)  ── drift? self-heal (revert manual changes)
   CI builds image ─► updates manifest digest in Git (no cluster creds in CI)
   Rollback = git revert | History = deployment log
```

## 5. Interview Questions
1. What is GitOps and its core principles?
2. Push vs pull-based deployment?
3. How does GitOps improve security?
4. How do you handle rollback and drift?
5. How do you manage secrets in GitOps?

## 6. Strong Interview Answers
- **GitOps/principles**: "Git as the single source of truth for declarative desired state, versioned and immutable, pulled and continuously reconciled by an in-cluster agent. Changes happen via Git commits/PRs, not direct cluster access."
- **Push vs pull**: "Push has a pipeline run `kubectl`/Helm against the cluster — the CI system needs cluster credentials and drift can creep in. Pull/GitOps has an agent inside the cluster reconcile from Git — no external creds, automatic drift correction, and Git is the audit log. I prefer pull for security and consistency."
- **Security**: "No cluster credentials leave the cluster — the agent pulls from Git, so a compromised CI system can't directly touch prod. Every change is a reviewed, signed, auditable Git commit, and RBAC on Git + admission control on images add defense in depth."
- **Rollback/drift**: "Rollback is `git revert` to a known-good commit — the agent reconciles back. Drift (manual `kubectl` changes) is automatically detected and reverted to match Git, so the cluster never silently diverges."
- **Secrets**: "Never plaintext in Git — I use sealed-secrets or SOPS (encrypted in Git) or External Secrets Operator / Key Vault CSI to fetch at runtime, so the source of truth stays in Git without exposing secrets."

## 7. Common Mistakes
- Plaintext secrets committed to Git.
- Manual `kubectl` changes (fought by reconciliation).
- Mixing app code and config in one repo without structure.
- No image-digest pinning (mutable tags → non-reproducible).
- CI still pushing directly instead of updating Git.

## 8. Trade-offs
| Aspect | GitOps (pull) | Push pipeline |
|--------|---------------|---------------|
| Security | no external creds | creds in CI |
| Drift | self-healed | possible |
| Audit | Git history | pipeline logs |
| Learning curve | higher | lower |

## 9. Production Best Practices
- Separate app-source and config/manifest repos.
- CI updates manifest with signed image digest via PR.
- Pin digests; declarative (Helm/Kustomize); reviewed PRs.
- Encrypted/external secrets (sealed-secrets/SOPS/External Secrets).
- Multi-cluster via app-of-apps/Kustomizations; integrate progressive delivery.

## 10. Security Considerations
- No cluster creds in CI; agent pulls from Git.
- RBAC on Git + branch protection + signed commits.
- Image signing + admission verification.
- Secrets encrypted/externalized, never plaintext.

## 11. Cost Optimization
- Consistent, drift-free clusters reduce incident cost.
- Fewer bespoke pipelines; reuse config repos across clusters.
- Fast `git revert` rollback lowers MTTR (and its cost).

## 12. Troubleshooting Scenarios
- **Change not applied** → agent sync status/health; Git path/branch.
- **Manual change keeps reverting** → that's GitOps working; change Git instead.
- **OutOfSync/degraded** → manifest error, image pull, or drift.
- **Secret exposed** → plaintext in Git; move to sealed-secrets/External Secrets, rotate.
- **Wrong version deployed** → mutable tag; pin digest.

## 13. Hands-on Example
```bash
argocd app get api            # sync/health status
argocd app sync api           # force reconcile
argocd app rollback api 42    # or: git revert <commit>
```

## 14. Terraform Example
```hcl
# Bootstrap Flux (GitOps) onto AKS
resource "azurerm_kubernetes_flux_configuration" "flux" {
  name       = "apps"
  cluster_id = azurerm_kubernetes_cluster.aks.id
  namespace  = "flux-system"
  git_repository { url = "https://github.com/org/cluster-config" reference_type = "branch" reference_value = "main" }
  kustomizations { name = "apps" path = "./clusters/prod" }
  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}
```

## 15. Azure Example
```bash
# AKS GitOps (Flux) via the managed extension
az k8s-configuration flux create -g rg-aks -c prod-aks -t managedClusters \
  -n apps --namespace flux-system \
  --url https://github.com/org/cluster-config --branch main \
  --kustomization name=apps path=./clusters/prod prune=true
```

## 16. FastAPI / Python Example
```python
# CI step: bump the image digest in the GitOps config repo via PR (no cluster access)
import subprocess, pathlib, re
def bump_manifest(path: str, digest: str):
    p = pathlib.Path(path); txt = p.read_text()
    p.write_text(re.sub(r"image: .*api@sha256:[0-9a-f]+",
                        f"image: myacr.azurecr.io/api@{digest}", txt))
    subprocess.run(["git", "commit", "-am", f"deploy api {digest[:12]}"], check=True)
```

## 17. AKS Example
Flux watches `clusters/prod` in Git; CI opens a PR updating the Deployment's `image` to a new signed digest. On merge, Flux reconciles the AKS cluster to match. Any `kubectl edit` on the Deployment is reverted at the next reconcile — Git stays authoritative.

## 18. How to Remember
**"Git is the source of truth; an in-cluster agent pulls and reconciles."** Change Git, not the cluster. Rollback = `git revert`; drift self-heals.

## 19. Real-World Analogy
A thermostat (the reconciliation agent) constantly comparing the room to the temperature you set on a shared, logged dial (Git). You never manually hold a heater — you change the setting, and the thermostat drives the room to match, correcting any tampering automatically.

## 20. One-Page Cheat Sheet
- **What**: Git = single source of truth; declarative, versioned, pulled, continuously reconciled.
- **Pull model**: ArgoCD/Flux agent in-cluster (no external cluster creds).
- **Self-healing**: drift reverted to match Git; rollback = `git revert`.
- **Flow**: CI builds image → updates manifest digest via PR → agent deploys.
- **Secrets**: sealed-secrets/SOPS/External Secrets — never plaintext.
- **Benefits**: audit (Git history), security, consistency, multi-cluster fleet management.
