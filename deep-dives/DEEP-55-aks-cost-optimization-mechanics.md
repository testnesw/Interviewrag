# DEEP MECHANICS · AKS Cost Optimization

> Level 2 — the cost levers specific to AKS: node pools, spot, autoscaling,
> bin-packing, right-sizing requests, and scale-to-zero.

---

## 0. The precise mental model
AKS cost = **mostly the VM nodes** (you pay for node VMs, not the managed control plane in the free tier). So optimization = **run the fewest, right-sized nodes at the highest utilization**, using **autoscaling, spot, right-sized requests, and bin-packing**. The core waste is **over-provisioned requests and idle nodes**.

---

## 1. The cost model
- **Control plane** — free (or paid **Standard/Uptime SLA** tier for guaranteed SLA).
- **Nodes** — the main cost (VM SKU × count × time) + disks + egress + LB.
- Goal: minimize node-hours while meeting demand → high utilization.

## 2. Node pool strategy
- **Right-size SKUs** per workload (don't run everything on big VMs).
- **Spot node pools** — up to ~90% cheaper for **interruptible/batch/stateless** workloads (evictable) → taints + tolerations to schedule appropriate Pods there.
- **System vs user node pools** — keep system pods separate; scale user pools.
- **ARM/Ampere (arm64)** nodes for price/perf where supported.

## 3. Autoscaling (elasticity = savings)
- **Cluster Autoscaler** — remove idle nodes, add only when Pending Pods need them.
- **HPA/KEDA** — scale Pods to demand; **KEDA scale-to-zero** for event-driven workloads → no idle Pods/nodes.
- **NAP/Karpenter** — provision optimal VM sizes → better bin-packing.

## 4. Right-sizing requests (the biggest lever)
- Pods reserve **requests** → the scheduler packs nodes by requests. **Over-requesting** wastes capacity (nodes look full but are idle) → fewer Pods per node → more nodes → more cost.
- Use **VPA (recommendation mode)** / metrics to set requests close to actual usage → better **bin-packing** → fewer nodes.

## 5. Other levers
- **Kill idle/dev clusters** (stop node pools nights/weekends).
- **Reserved Instances / Savings Plans** on baseline node VMs; **spot** for variable.
- **Storage/egress** discipline; clean up orphaned disks/LBs.
- **Start/Stop** cluster feature for non-prod.

## 6. The hard follow-ups (with answers)
1. **"Where does AKS cost come from?"** → node VMs (control plane free); minimize node-hours at high utilization. (§1)
2. **"Biggest lever?"** → right-size **requests** for good bin-packing (over-requesting wastes nodes). (§4)
3. **"Use spot safely?"** → taint spot pool + tolerations; only interruptible/stateless/batch workloads. (§2)
4. **"Scale to zero?"** → KEDA for event-driven workloads (HPA can't). (§3)
5. **"Cut non-prod cost?"** → stop node pools/clusters off-hours; Reserved/Savings for baseline, spot for variable. (§5)

## 7. One-screen recall
- AKS cost ≈ **node VMs** (control plane free) → **fewest, right-sized nodes at high utilization**.
- **Node pools**: right-size SKUs, **spot** (~90% off, evictable, taint+toleration), system/user split, arm64.
- **Autoscaling**: **Cluster Autoscaler** (idle nodes off), **HPA/KEDA** (+ **scale-to-zero**), NAP/Karpenter bin-packing.
- **Right-size requests** = #1 lever (over-request → wasted nodes); use **VPA recommendations**.
- **Reserved/Savings** on baseline + **spot** variable; stop non-prod off-hours; clean orphans.

> Next: Docker Fundamentals.
