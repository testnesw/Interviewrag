# 49 · Cluster Autoscaler

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
The Cluster Autoscaler **adds or removes nodes (VMs)** in your cluster. When Pods can't be scheduled (no room), it adds nodes; when nodes sit mostly empty, it removes them — matching capacity to demand.

## 2. Architect-Level Explanation
A controller that scales the **node pool** (VMSS on AKS):
- **Scale-up**: triggered by **unschedulable (Pending) Pods** — adds nodes so they can be placed.
- **Scale-down**: removes underutilized nodes whose Pods can be rescheduled elsewhere (respecting PDBs, affinity, local storage).
- **Works with HPA**: HPA creates more Pods → some Pending → CA adds nodes; reverse on scale-down.
- **Constraints**: min/max per node pool; can't scale below workloads that pin nodes.
- **Newer**: **Node Autoprovisioning (NAP / Karpenter-style)** dynamically picks optimal VM sizes instead of fixed pools.
- Consider spot node pools for burst/cost.

## 3. Real Enterprise Use Case
An AKS cluster runs a system pool (fixed) + a user pool (autoscale 2–20) + a spot pool (0–50) for batch. During sales peaks HPA scales Pods, CA grows the user/spot pools; overnight it scales back to save cost — fully elastic.

## 4. Architecture Diagram (ASCII)
```
   HPA adds Pods ─► some Pods Pending (no room)
                         │
                 [ Cluster Autoscaler ]
                         │ scale-up
        Node Pool (VMSS): 2 ─► 6 ─► 12 (min..max)
                         │ scale-down (underutilized, respect PDBs)
        back to 3 nodes overnight
   Spot pool for burst/cost ; NAP picks optimal VM sizes
```

## 5. Interview Questions
1. What triggers scale-up and scale-down?
2. How do HPA and Cluster Autoscaler work together?
3. What prevents a node from scaling down?
4. What is Node Autoprovisioning/Karpenter?
5. How do spot node pools fit in?

## 6. Strong Interview Answers
- **Triggers**: "Scale-up when Pods are Pending due to insufficient resources; scale-down when a node is underutilized and its Pods can safely move elsewhere, respecting PodDisruptionBudgets and constraints."
- **With HPA**: "HPA scales Pods; if there's no node capacity, Pods go Pending and CA adds nodes. On the way down, HPA removes Pods and CA consolidates/removes nodes. They're complementary layers."
- **Scale-down blockers**: "Pods without controllers, PDBs that would be violated, local storage, restrictive affinity, or `safe-to-evict: false` annotations keep a node up."
- **NAP/Karpenter**: "Instead of fixed node pools, it provisions right-sized nodes on demand based on pending Pod requirements — better bin-packing and cost, less pool management."
- **Spot**: "Spot node pools give big discounts for fault-tolerant/batch workloads; CA can scale them, with tolerations/taints so only evictable workloads land there."

## 7. Common Mistakes
- HPA without CA → Pods stuck Pending.
- Blocking scale-down (PDBs/annotations) unknowingly.
- Workloads without requests → poor scaling decisions.
- Only on-demand nodes (missed spot savings).
- Min too low for baseline load.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Cluster Autoscaler | elastic capacity | scale-up latency (VM boot) |
| NAP/Karpenter | optimal sizing, cost | newer, learning curve |
| Spot pools | big savings | evictions |

## 9. Production Best Practices
- Enable CA on user pools (min ≥ 2, sensible max).
- Set requests/limits so CA decides well.
- Separate system vs user pools; spot for burst/batch.
- PDBs to protect availability during scale-down.
- Consider NAP for dynamic sizing; pre-provision for spikes if latency matters.

## 10. Security Considerations
- Node pool identity least privilege.
- Spot/burst nodes same hardening (images, policies).
- Taints/tolerations to isolate sensitive workloads.

## 11. Cost Optimization
- Scale down aggressively off-peak; scale-to-zero user pools (with KEDA).
- Spot pools for savings; NAP for right-sizing.
- Reservations/savings plans for steady baseline.

## 12. Troubleshooting Scenarios
- **Pods Pending, no scale-up** → max reached, quota, unschedulable due to taints/affinity.
- **Nodes not scaling down** → PDB, local storage, `safe-to-evict` annotations.
- **Slow scale-up** → VM provisioning latency; pre-provision/overprovision pods.
- **Wrong pool scaling** → labels/taints/tolerations mismatch.

## 13. Hands-on Example
```bash
kubectl get nodes
kubectl describe pod <pending-pod>   # "0/3 nodes available" → CA should add
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D8s_v5"
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 20
  zones                 = [1, 2, 3]
}
```

## 15. Azure Example
```bash
az aks nodepool update -g rg-aks --cluster-name prod-aks -n user \
  --enable-cluster-autoscaler --min-count 2 --max-count 20
# Node Autoprovisioning:
az aks update -g rg-aks -n prod-aks --node-provisioning-mode Auto
```

## 16. FastAPI / Python Example
```python
from kubernetes import client, config
config.load_incluster_config()
v1 = client.CoreV1Api()

@app.get("/pending-pods")
def pending():
    pods = v1.list_pod_for_all_namespaces(field_selector="status.phase=Pending")
    return [p.metadata.name for p in pods.items]   # triggers CA scale-up
```

## 17. AKS Example
Use a spot node pool with taint `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`; batch workloads add matching tolerations; CA scales the spot pool 0→N for jobs then back to 0.

## 18. How to Remember
**"HPA fills nodes with pods; CA adds nodes when pods don't fit."** Pending Pods = the scale-up signal.

## 19. Real-World Analogy
A restaurant that opens more dining rooms (nodes) when tables fill up and closes them when empty — HPA seats more guests (pods), CA manages how many rooms are open.

## 20. One-Page Cheat Sheet
- **What**: scales node count in node pools (VMSS) to demand.
- **Scale-up**: Pending Pods; **scale-down**: underutilized nodes (respect PDBs).
- **Pairs with HPA**: HPA=pods, CA=nodes; needs resource requests.
- **Newer**: Node Autoprovisioning (Karpenter-style) for right-sized nodes.
- **Cost**: spot pools + scale-to-zero + reservations for baseline.
- **Debug**: Pending + no scale-up → max/quota/taints; no scale-down → PDB/annotations.
