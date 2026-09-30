# 48 · HPA (Horizontal Pod Autoscaler)

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
The Horizontal Pod Autoscaler **adds or removes Pod replicas automatically** based on load (like CPU or memory). More traffic → more Pods; less traffic → fewer Pods.

## 2. Architect-Level Explanation
A controller that scales replicas to meet a target metric:
- **Loop**: periodically reads metrics → computes `desiredReplicas = ceil(current × currentMetric / targetMetric)` → adjusts within min/max.
- **Metrics**: resource (CPU/memory via **metrics-server**), custom/external (via adapters/**KEDA** for queues/events), Prometheus metrics.
- **vs VPA vs Cluster Autoscaler**: HPA scales *number of Pods*; VPA scales *Pod size* (requests); Cluster Autoscaler scales *nodes*. They compose (HPA needs nodes from CA).
- **Behavior**: stabilization windows + scale-up/down policies prevent flapping.
- Requires resource **requests** set to scale on CPU/memory.

## 3. Real Enterprise Use Case
An API scales from 3 to 30 Pods on CPU during business hours; an order-processor scales on Service Bus queue depth via **KEDA** (scale-to-zero off-hours). Cluster Autoscaler adds nodes when HPA needs capacity — elastic and cost-efficient.

## 4. Architecture Diagram (ASCII)
```
   metrics-server / Prometheus / KEDA
             │ metrics
        [ HPA controller ]
             │ desired = ceil(cur × curMetric/target)
      Deployment replicas: 3 ─► 12 ─► 30 (min..max)
             │ if no room to schedule
        Cluster Autoscaler adds nodes
   HPA = # of pods | VPA = pod size | CA = # of nodes
```

## 5. Interview Questions
1. How does the HPA calculate desired replicas?
2. HPA vs VPA vs Cluster Autoscaler?
3. Why must you set resource requests?
4. How do you scale on custom/queue metrics?
5. How do you prevent scaling flapping?

## 6. Strong Interview Answers
- **Calc**: "desiredReplicas = ceil(currentReplicas × currentMetricValue / targetMetricValue), bounded by min/max. E.g., CPU at 80% with a 50% target and 3 pods → ceil(3×80/50)=5."
- **HPA/VPA/CA**: "HPA changes the *number* of Pods; VPA changes Pod *resource requests* (size); Cluster Autoscaler changes the *number of nodes*. HPA+CA is the common combo; VPA and HPA on the same metric conflict."
- **Requests**: "CPU/memory HPA is calculated as a percentage of the Pod's *request*, so without requests there's no baseline and scaling won't work."
- **Custom/queue**: "Use KEDA (event-driven) for queue depth, Kafka lag, etc., or a custom/external metrics adapter — enables scale-to-zero and business-metric scaling."
- **Flapping**: "Stabilization windows and scale-up/down behavior policies smooth rapid changes; conservative down-scaling avoids thrashing."

## 7. Common Mistakes
- No resource requests → HPA can't scale.
- HPA + VPA on the same metric (conflict).
- min=1 for critical services (no HA).
- Aggressive thresholds causing flapping.
- Forgetting Cluster Autoscaler → Pods Pending.

## 8. Trade-offs
| Autoscaler | Scales | Note |
|-----------|--------|------|
| HPA | pod count | needs requests + metrics |
| VPA | pod size | restarts pods; conflicts w/ HPA |
| CA / KEDA | nodes / events | capacity / scale-to-zero |

## 9. Production Best Practices
- Set requests; sensible min (≥2 for HA) and max.
- HPA + Cluster Autoscaler together.
- KEDA for event/queue-driven + scale-to-zero.
- Tune stabilization to prevent flapping.
- Load-test to validate thresholds.

## 10. Security Considerations
- Protect metrics pipeline (metrics-server/Prometheus).
- Prevent metric-based DoS-driven runaway scaling (max caps).
- RBAC on HPA objects.

## 11. Cost Optimization
- Scale down (and to zero via KEDA) in low demand.
- Right-size requests so HPA packs efficiently.
- Combine with spot nodes for burst capacity.

## 12. Troubleshooting Scenarios
- **Not scaling** → no requests, metrics-server down, wrong target.
- **Pods Pending after scale** → Cluster Autoscaler / node capacity.
- **Flapping** → tighten stabilization windows.
- **Unknown metric** → adapter/KEDA misconfig.

## 13. Hands-on Example
```bash
kubectl autoscale deployment api --cpu-percent=50 --min=3 --max=30
kubectl get hpa
```

## 14. Terraform Example
```hcl
resource "kubernetes_horizontal_pod_autoscaler_v2" "api" {
  metadata { name = "api" namespace = "app" }
  spec {
    min_replicas = 3
    max_replicas = 30
    scale_target_ref { kind = "Deployment" name = "api" api_version = "apps/v1" }
    metric {
      type = "Resource"
      resource { name = "cpu"
        target { type = "Utilization" average_utilization = 50 } }
    }
  }
}
```

## 15. Azure Example
```bash
# Install KEDA add-on on AKS for event-driven autoscaling
az aks update -g rg-aks -n prod-aks --enable-keda
```

## 16. FastAPI / Python Example
```python
from prometheus_client import Gauge
inflight = Gauge("http_inflight_requests", "in-flight requests")
# Expose a custom metric HPA/KEDA can scale on
@app.middleware("http")
async def track(request, call_next):
    inflight.inc()
    try: return await call_next(request)
    finally: inflight.dec()
```

## 17. AKS Example (KEDA ScaledObject)
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata: { name: order-processor, namespace: app }
spec:
  scaleTargetRef: { name: order-processor }
  minReplicaCount: 0          # scale to zero
  maxReplicaCount: 50
  triggers:
    - type: azure-servicebus
      metadata: { queueName: orders, messageCount: "5" }
      authenticationRef: { name: keda-wi }
```

## 18. How to Remember
**"HPA = more pods; VPA = bigger pods; CA = more nodes."** HPA needs requests + metrics; pair with CA/KEDA.

## 19. Real-World Analogy
A call center opening more identical desks (Pods) as calls surge and closing them when quiet — while facilities adds more rooms (nodes) if the building runs out of desk space.

## 20. One-Page Cheat Sheet
- **What**: auto-scales Pod replicas to hit a target metric.
- **Formula**: desired = ceil(cur × curMetric/target), within min/max.
- **Needs**: resource requests + metrics-server (or KEDA/custom adapter).
- **Family**: HPA (count) + VPA (size) + Cluster Autoscaler (nodes) + KEDA (events/scale-to-zero).
- **Prod**: min ≥ 2, HPA+CA together, tune stabilization, load-test.
- **Debug**: no requests/metrics → not scaling; Pending → need nodes.
