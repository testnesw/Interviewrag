# DEEP MECHANICS · GitOps

> Level 2 — Git as source of truth, pull-based reconciliation, drift detection,
> and push vs pull CD.

---

## 0. The precise mental model
GitOps = **Git is the single source of truth for desired state**, and an **in-cluster agent continuously reconciles** actual state to match it. You change infra/apps by **committing to Git** (PR → merge); the agent (Argo CD / Flux) **pulls** the change and applies it, and **corrects drift** automatically. Declarative + version-controlled + self-healing.

---

## 1. The four principles
1. **Declarative** — entire system described declaratively (K8s manifests/Helm/Kustomize).
2. **Versioned & immutable** — desired state in Git (audit, history, revert).
3. **Pulled automatically** — agents pull approved state from Git.
4. **Continuously reconciled** — agent detects & corrects drift toward desired state.

## 2. The reconciliation loop
```
Git (desired) ──watch──> Agent (in cluster) ──diff──> Cluster (actual)
                              └── apply to converge; repeat
```
- Agent constantly compares Git vs live → applies diffs → **self-healing** (manual `kubectl` changes get reverted).

## 3. Push vs pull CD
| | Push (traditional CI/CD) | Pull (GitOps) |
|---|---|---|
| Who applies | external pipeline `kubectl apply` | **in-cluster agent** |
| Credentials | cluster creds in CI (exposed) | agent has creds **inside** cluster |
| Drift | not detected | **detected + corrected** |
| Source of truth | pipeline scripts | **Git repo** |
- Pull = better security (no external cluster creds) + drift correction.

## 4. Benefits
- **Auditability**: every change is a Git commit (who/what/when) → easy rollback = `git revert`.
- **Security**: no CI cluster credentials; agent pulls.
- **Consistency**: same declared state across clusters; disaster recovery = point agent at Git.
- **Self-healing** against config drift.

## 5. Structure & patterns
- Often **separate repos**: app source (CI builds image) vs **config/manifests repo** (CD). CI updates the image tag in the config repo → agent deploys.
- **Environments** = folders/branches/overlays (Kustomize) or separate repos.
- Tools: **Argo CD**, **Flux**.

## 6. Considerations
- **Secrets**: don't commit plaintext → **Sealed Secrets / SOPS / external secrets operator** pulling from Key Vault.
- Promotion across envs = PR that bumps the config in the target overlay.
- Progressive delivery via **Argo Rollouts/Flagger** on top.

## 7. The hard follow-ups (with answers)
1. **"What is GitOps in one line?"** → Git = desired state; in-cluster agent continuously reconciles actual → desired. (§0)
2. **"Push vs pull?"** → push = external pipeline applies (needs cluster creds); pull = agent applies from Git (no external creds + drift correction). (§3)
3. **"How does it self-heal?"** → reconciliation loop reverts manual drift to match Git. (§2)
4. **"Rollback?"** → `git revert` → agent reconciles back. (§4)
5. **"Secrets in Git?"** → never plaintext → **Sealed Secrets/SOPS/external-secrets** + Key Vault. (§6)
6. **"Repo layout?"** → separate app (CI) and **config** repo; CI bumps image tag → agent deploys. (§5)

## 8. One-screen recall
- **Git = source of truth**; **agent reconciles** actual→desired (Argo CD/Flux).
- **4 principles**: declarative, versioned/immutable, auto-pulled, continuously reconciled.
- **Pull > push**: no external cluster creds + **drift detection/self-heal**.
- **Wins**: audit (git log), rollback (`git revert`), consistency, DR, self-healing.
- **Structure**: app repo (CI) + **config repo** (CD bumps image tag); envs via overlays/branches.
- **Secrets**: Sealed Secrets/SOPS/external-secrets ← Key Vault.

> Next: Argo CD.
