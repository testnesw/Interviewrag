# DEEP MECHANICS · Deployments

> Level 2 — declarative rollouts, rolling update mechanics, revision history/
> rollback, and the Deployment→ReplicaSet→Pod chain.

---

## 0. The precise mental model
A Deployment is the **controller that manages stateless app rollouts declaratively**: you declare the desired Pod template + replica count, and it creates/manages **ReplicaSets** to achieve it, handling **rolling updates and rollbacks** automatically. It's the standard way to run stateless workloads — you change the spec, Kubernetes reconciles.

---

## 1. The controller chain
```
Deployment  → manages → ReplicaSet(s) → manages → Pods
```
- **Deployment** owns rollout strategy + revision history.
- Each **update creates a new ReplicaSet**; the old one is scaled down (kept for rollback).
- ReplicaSet ensures the Pod count.

## 2. Rolling update mechanics (the default)
On a spec change, a new ReplicaSet scales up while the old scales down, governed by:
- **maxSurge** — extra Pods allowed above desired during update (e.g., 25%).
- **maxUnavailable** — Pods allowed missing during update (e.g., 25%).
Together they give **zero-downtime** gradual replacement. Readiness probes gate progress (a new Pod counts as available only when Ready).

## 3. Rollout control & rollback
- `kubectl rollout status/pause/resume/undo`.
- **Revision history** — old ReplicaSets retained (`revisionHistoryLimit`) → **instant rollback** to a prior revision.
- **Pause** to batch multiple changes into one rollout (canary-ish).

## 4. Strategies
- **RollingUpdate** (default) — gradual, zero-downtime.
- **Recreate** — kill all old, then create new → downtime, but for apps that can't run two versions.
- Blue-green/canary need extra tooling (two Deployments + Service switch, or Argo Rollouts/service mesh).

## 5. Deployment vs other controllers
- **Deployment** — stateless apps.
- **StatefulSet** — stable identity/storage (databases): ordered, stable network IDs, per-Pod PVCs.
- **DaemonSet** — one Pod per node (agents/log collectors).
- **Job/CronJob** — run-to-completion / scheduled.

## 6. The hard follow-ups (with answers)
1. **"Deployment vs ReplicaSet?"** → Deployment manages ReplicaSets + rollouts/rollback; ReplicaSet just maintains Pod count. (§1)
2. **"How does a rolling update avoid downtime?"** → new RS up / old RS down within maxSurge/maxUnavailable, gated by readiness. (§2)
3. **"How do you roll back?"** → `rollout undo` to a retained prior ReplicaSet revision. (§3)
4. **"RollingUpdate vs Recreate?"** → gradual zero-downtime vs kill-all-then-create (downtime, no version overlap). (§4)
5. **"Deployment vs StatefulSet?"** → stateless interchangeable Pods vs stable identity/ordered/per-Pod storage. (§5)
6. **"Do blue-green/canary come built-in?"** → no; needs extra tooling (Argo Rollouts / service mesh / two Deployments). (§4)

## 7. One-screen recall
- Deployment = declarative **stateless rollout** controller: **Deployment→ReplicaSet→Pods**.
- **Update = new ReplicaSet** scales up while old scales down (old kept for rollback).
- **RollingUpdate** via **maxSurge/maxUnavailable** + readiness gate = zero-downtime; **Recreate** = downtime.
- `rollout status/undo/pause`; **revision history** → instant rollback.
- vs **StatefulSet** (identity/storage), **DaemonSet** (per-node), **Job/CronJob** (batch).

> Next: ReplicaSets.
