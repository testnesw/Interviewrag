# 55 · AKS Cost Optimization (FinOps)

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
AKS cost optimization means running your cluster efficiently — paying for the compute you actually need, scaling down when idle, and using cheaper capacity options — without hurting performance or reliability.

## 2. Architect-Level Explanation
FinOps for Kubernetes across compute, scaling, and visibility:
- **Right-sizing**: set accurate requests/limits so the scheduler bin-packs efficiently (VPA recommendations help); avoid over-provisioning.
- **Elastic scaling**: HPA (pods) + Cluster Autoscaler / **Node Autoprovisioning** (nodes) + **KEDA scale-to-zero** for event workloads.
- **Cheaper capacity**: **Spot node pools** (up to ~90% off) for fault-tolerant/batch; **Reservations / Savings Plans** for steady baseline; ARM/AMD SKUs for price-performance.
- **Bin-packing**: separate system vs user pools; consolidate underutilized nodes; use taints/tolerations to place workloads on the right (cheapest suitable) pool.
- **Visibility**: **OpenCost / Microsoft Cost Analysis for AKS** for per-namespace/team showback & chargeback; tag/label everything.
- **Free control plane** (paid tier for SLA); pay for nodes — so node efficiency is the lever.
- **Storage/network**: right disk tiers, clean up orphaned PVs/LBs, egress via NAT/hub.

## 3. Real Enterprise Use Case
A platform team cuts AKS spend 40%: VPA-informed right-sizing, HPA + Cluster Autoscaler, KEDA scaling batch to zero off-hours, spot pools for CI and batch, 1-year Reservations for baseline system pool, and OpenCost dashboards for per-team chargeback that drives accountability.

## 4. Architecture Diagram (ASCII)
```
   Right-size requests ─► efficient bin-packing (VPA advice)
        │
   HPA (pods) + Cluster Autoscaler/NAP (nodes) + KEDA (scale-to-zero)
        │
   Capacity mix:
     Baseline pool ─► Reservations/Savings Plan
     Burst/batch    ─► Spot pool (~90% off, tolerations)
        │
   OpenCost / Cost Analysis ─► per-namespace showback/chargeback
   Cleanup: orphaned PVs, idle LBs, oversized disks
```

## 5. Interview Questions
1. What are the biggest AKS cost levers?
2. How do requests/limits affect cost?
3. When do you use Spot vs Reservations?
4. How do you scale to zero?
5. How do you allocate cost per team/namespace?

## 6. Strong Interview Answers
- **Levers**: "Nodes are what you pay for (control plane is free), so node efficiency dominates: right-size requests, autoscale pods and nodes, use spot for burst and reservations for baseline, and get per-namespace visibility to drive accountability."
- **Requests/limits**: "Requests drive scheduling and how tightly nodes pack. Over-requesting wastes capacity (fewer pods per node = more nodes = more cost); under-requesting risks throttling/OOM. I use VPA recommendations to right-size."
- **Spot vs Reservations**: "Spot for fault-tolerant/interruptible workloads (batch, CI, stateless with disruption tolerance) at up to ~90% off; Reservations or Savings Plans for predictable steady-state baseline. Combine both."
- **Scale to zero**: "KEDA scales event-driven workloads (queues, cron) to zero when idle and back up on demand — you pay nothing for idle consumers; Cluster Autoscaler removes the now-empty nodes."
- **Allocation**: "OpenCost or AKS Cost Analysis breaks spend down by namespace/label/team for showback/chargeback. Enforce labels via policy so everything is attributable."

## 7. Common Mistakes
- No requests/limits → poor packing, waste or instability.
- Only on-demand nodes (missing spot/reservations).
- Over-provisioned 'just in case' capacity.
- No cost visibility per team (no accountability).
- Orphaned disks/LBs/PVs quietly billing.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Spot | huge savings | evictions |
| Reservations | discount | commitment |
| Aggressive scale-down | cheap | cold-start latency |

## 9. Production Best Practices
- Right-size with VPA recommendations; enforce requests/limits.
- HPA + Cluster Autoscaler/NAP + KEDA scale-to-zero.
- Spot for burst/batch (tolerations); Reservations/Savings for baseline.
- Separate system/user pools; consolidate idle nodes.
- Cost visibility (OpenCost/Cost Analysis) + label governance.
- Clean up orphaned resources; right-size storage tiers.

## 10. Security Considerations
- Spot/burst nodes hardened equally (images, policy).
- Cost tooling access via RBAC.
- Don't sacrifice HA/PDBs purely for cost (min replicas ≥ 2 for critical).

## 11. Cost Optimization
(Core topic) — key numbers: Spot ~ up to 90% off; Reservations ~ up to 65%; ARM/AMD SKUs better price-perf; scale-to-zero eliminates idle cost.

## 12. Troubleshooting Scenarios
- **High bill, low utilization** → over-requested pods / idle nodes not consolidating.
- **Spot evictions hurting** → move critical workloads off spot; add on-demand fallback.
- **Nodes won't scale down** → PDBs / `safe-to-evict` / local storage.
- **Cost not attributable** → missing labels; enforce via Azure Policy.

## 13. Hands-on Example
```bash
kubectl top nodes; kubectl top pods -A     # find waste
kubectl describe node <n> | grep -A5 Allocated  # requests vs capacity
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D8s_v5"
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1          # pay up to on-demand price
  enable_auto_scaling   = true
  min_count             = 0           # scale to zero
  max_count             = 50
  node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
}
```

## 15. Azure Example
```bash
# Enable Cost Analysis add-on for AKS (per-namespace cost)
az aks update -g rg-aks -n prod-aks --enable-cost-analysis
# Node Autoprovisioning for right-sized nodes
az aks update -g rg-aks -n prod-aks --node-provisioning-mode Auto
```

## 16. FastAPI / Python Example
```python
# Expose a queue-depth metric so KEDA scales workers to zero when idle
from prometheus_client import Gauge
queue_depth = Gauge("orders_queue_depth", "pending orders")

@app.get("/metrics/queue")
def q(): return {"depth": current_queue_depth()}   # 0 → KEDA scales workers to 0
```

## 17. AKS Example (spot toleration + KEDA scale-to-zero)
```yaml
spec:
  template:
    spec:
      tolerations:
        - key: kubernetes.azure.com/scalesetpriority
          operator: Equal
          value: spot
          effect: NoSchedule
      nodeSelector: { kubernetes.azure.com/scalesetpriority: spot }
# Pair with a KEDA ScaledObject minReplicaCount: 0
```

## 18. How to Remember
**"Right-size, Auto-scale, Spot+Reserve, See the bill."** Nodes cost money — pack them tight, scale to zero, split baseline vs burst.

## 19. Real-World Analogy
Running a fleet efficiently: right-size vehicles to the load (requests), rent extra trucks only during peak (autoscale/spot), buy your core fleet on long-term lease (reservations), park unused trucks (scale-to-zero), and give each department a fuel bill (chargeback) so they drive responsibly.

## 20. One-Page Cheat Sheet
- **Pay for nodes** (control plane free) → node efficiency is the lever.
- **Right-size**: accurate requests/limits (VPA advice) → tight bin-packing.
- **Scale**: HPA + Cluster Autoscaler/NAP + KEDA **scale-to-zero**.
- **Capacity mix**: Spot (~90% off, burst/batch) + Reservations/Savings (baseline) + ARM/AMD SKUs.
- **Visibility**: OpenCost / AKS Cost Analysis → showback/chargeback; enforce labels.
- **Cleanup**: orphaned PVs/disks/LBs; right disk tiers; keep HA (min ≥ 2).
