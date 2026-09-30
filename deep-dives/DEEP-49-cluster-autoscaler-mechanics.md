# DEEP MECHANICS · Cluster Autoscaler

> Level 2 — how node scaling actually decides, scale-up/down triggers, node pools,
> and Cluster Autoscaler vs Karpenter/NAP.

---

## 0. The precise mental model
The Cluster Autoscaler (CA) **adds or removes nodes** so Pods can schedule and idle capacity isn't wasted. It watches for **Pods stuck Pending** (no room → add a node) and **underutilized nodes** (consolidate → remove). It works **with HPA**: HPA adds Pods, and when they can't fit, CA adds nodes. It scales the **infrastructure layer**.

---

## 1. Scale-up trigger
```
Pod Pending (unschedulable: insufficient CPU/mem, or node affinity)
   → CA checks node pools → picks a pool whose new node would fit the Pod
   → increases the pool's VMSS count → new node joins → Pod schedules
```
CA simulates scheduling to choose which node pool to grow. Only triggers on **real unschedulable Pods** (so set requests correctly).

## 2. Scale-down trigger
- A node is **underutilized** (below threshold, default ~50%) for a period **and** its Pods can be rescheduled elsewhere → CA **drains and removes** it.
- **Blockers:** Pods without controllers, PodDisruptionBudget violations, local storage, or `safe-to-evict: false` annotations prevent removal. This is why nodes sometimes won't scale down.

## 3. Node pools
- Multiple **node pools** (different VM sizes: general, memory-optimized, GPU, spot). CA scales each within **min/max** bounds.
- Pods target pools via **nodeSelector/affinity/taints** → schedule GPU jobs to GPU pool, etc.
- **Spot node pools** for cheap interruptible workloads (CA-managed).

## 4. Interaction with HPA (the chain)
```
Load ↑ → HPA adds Pods → some Pending (no room) → CA adds node → Pods schedule
Load ↓ → HPA removes Pods → nodes underutilized → CA removes nodes
```
Both together = elastic at Pod **and** node level. Set HPA + CA + requests coherently.

## 5. CA vs Node Autoprovisioning (Karpenter/NAP)
- **Cluster Autoscaler** — scales **existing node pools** (fixed VM sizes) within bounds.
- **Node Autoprovisioning (NAP / Karpenter on AKS)** — dynamically picks the **optimal VM size/type** per pending Pods (no pre-defined pools) → better bin-packing + cost. The newer approach.

## 6. The hard follow-ups (with answers)
1. **"When does CA add a node?"** → when Pods are Pending/unschedulable and a new node would fit them. (§1)
2. **"Why won't my cluster scale down?"** → nodes blocked by PDBs, non-controller Pods, local storage, or safe-to-evict:false. (§2)
3. **"How does CA work with HPA?"** → HPA adds Pods → unschedulable → CA adds nodes; reverse on scale-down. (§4)
4. **"How do GPU jobs get GPU nodes?"** → separate GPU node pool + taints/affinity; CA scales that pool. (§3)
5. **"CA vs Karpenter/NAP?"** → scale fixed pools vs dynamically provision optimal VM types per Pods. (§5)

## 7. One-screen recall
- Cluster Autoscaler = add/remove **nodes**; scale-up on **Pending Pods**, scale-down on **underutilized** nodes (drain+remove).
- Scale-down **blockers**: PDBs, non-controller Pods, local storage, `safe-to-evict:false`.
- **Node pools** (sizes/GPU/spot) with **min/max**; Pods target via nodeSelector/affinity/taints.
- **Chain with HPA**: HPA adds Pods → no room → CA adds nodes (and reverse).
- **NAP/Karpenter** = dynamic optimal VM sizing vs fixed pools.

> Next: Service Mesh.
