# DEEP MECHANICS · ReplicaSets

> Level 2 — the reconciliation controller that maintains Pod count, label
> selectors, and its relationship to Deployments.

---

## 0. The precise mental model
A ReplicaSet is the **controller that guarantees N identical Pods are running** at all times via the **reconcile loop**: observe actual count → compare to desired → create/delete Pods to match. It uses **label selectors** to know which Pods it owns. You rarely touch it directly — **Deployments create and manage ReplicaSets** for you.

---

## 1. The reconcile loop
```
desired: replicas=3  ── controller watches ──  actual: 2 running
         → create 1 Pod → actual=3 → steady
a Pod dies → actual=2 → create 1 → back to 3
```
Continuous, level-based reconciliation → self-healing Pod count.

## 2. Label selectors & ownership
- ReplicaSet has a **selector** (`matchLabels`) that matches its Pods' labels.
- It owns Pods whose labels match **and** carry its **ownerReference**.
- **Gotcha:** overlapping selectors across ReplicaSets can fight over Pods → keep selectors unique (Deployments add a pod-template-hash label to avoid this).

## 3. Relationship to Deployments
- A **Deployment creates one ReplicaSet per revision**; the pod-template-hash makes each RS's selector unique.
- Rollout = new RS scaled up, old scaled to 0 (retained for rollback).
- You manage the Deployment; it manages RSs.

## 4. ReplicaSet vs ReplicationController
ReplicaSet is the successor to the old ReplicationController; the difference is **set-based selectors** (`in`, `notin`) vs equality-only. Use ReplicaSets (via Deployments).

## 5. The hard follow-ups (with answers)
1. **"What does a ReplicaSet do?"** → maintain a desired number of identical Pods via reconcile loop. (§0,1)
2. **"How does it know which Pods are its?"** → label selector + ownerReference. (§2)
3. **"Do you create ReplicaSets directly?"** → no — Deployments create/manage them (one per revision). (§3)
4. **"How are selector conflicts avoided?"** → Deployment adds a unique pod-template-hash label per RS. (§2,3)
5. **"ReplicaSet vs ReplicationController?"** → set-based selectors (newer) vs equality-only (legacy). (§4)

## 6. One-screen recall
- ReplicaSet = controller keeping **N identical Pods** via **reconcile loop** (self-healing count).
- Owns Pods by **label selector + ownerReference**; keep selectors unique.
- **Deployments create one RS per revision** (pod-template-hash label); you manage the Deployment, not the RS.
- Successor to ReplicationController (set-based selectors).

> Next: Services.
