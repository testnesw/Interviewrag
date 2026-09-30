# 41 · Deployments

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A Deployment manages a set of identical Pods for you — it keeps the right number running, replaces failed ones, and rolls out new versions with zero downtime. It's the standard way to run stateless apps.

## 2. Architect-Level Explanation
A controller that manages **ReplicaSets** (which manage Pods) to provide declarative updates:
- **Rollout**: creates a new ReplicaSet on spec change and shifts Pods gradually (**RollingUpdate** with maxSurge/maxUnavailable) — zero-downtime.
- **Rollback**: keeps revision history; `kubectl rollout undo` reverts.
- **Strategies**: RollingUpdate (default) or Recreate; blue-green/canary done via multiple Deployments or a mesh/ingress.
- **Scaling**: replicas field + HPA integration.
- Best for **stateless** workloads; stateful uses StatefulSet.

## 3. Real Enterprise Use Case
An API team ships 20 times/day via Deployments: RollingUpdate with maxUnavailable=0/maxSurge=25% ensures no downtime; readiness probes gate the rollout; failed rollouts auto-halt (progressDeadline) and are rolled back — all through GitOps.

## 4. Architecture Diagram (ASCII)
```
   Deployment (desired: 4 replicas, image v2)
        │ manages
   ReplicaSet v2 (new) ◄── rolling ──► ReplicaSet v1 (old)
     Pods: ●●●●  (scale up new)          ●●●● → ●●● → ● → 0
   RollingUpdate: maxSurge / maxUnavailable
   Readiness gates each new Pod ; history enables rollback
```

## 5. Interview Questions
1. Deployment vs ReplicaSet vs Pod?
2. How does a rolling update work?
3. maxSurge vs maxUnavailable?
4. How do you roll back?
5. RollingUpdate vs Recreate vs blue-green/canary?

## 6. Strong Interview Answers
- **Hierarchy**: "Deployment manages ReplicaSets, which manage Pods. I interact with the Deployment; it handles versioned ReplicaSets and safe rollouts. You rarely touch ReplicaSets directly."
- **Rolling update**: "On a spec change, the Deployment creates a new ReplicaSet and gradually scales it up while scaling the old down, respecting maxSurge/maxUnavailable and readiness probes — zero downtime."
- **maxSurge/maxUnavailable**: "maxSurge = extra Pods above desired during rollout (speed); maxUnavailable = how many can be down (availability). For zero-downtime I set maxUnavailable=0, maxSurge=25%."
- **Rollback**: "`kubectl rollout undo` reverts to a previous revision from history; I also set progressDeadlineSeconds so stuck rollouts fail fast."
- **Strategies**: "RollingUpdate for most; Recreate when versions can't coexist; blue-green/canary for controlled traffic shifting via two Deployments + ingress/mesh."

## 7. Common Mistakes
- No readiness probe → rollout shifts traffic to unready pods.
- maxUnavailable too high → downtime during rollout.
- Using Deployment for stateful apps (use StatefulSet).
- Not setting progressDeadline → stuck rollouts hang.
- Editing Pods/ReplicaSets directly.

## 8. Trade-offs
| Strategy | Pro | Con |
|----------|-----|-----|
| RollingUpdate | zero downtime, gradual | two versions briefly coexist |
| Recreate | clean cutover | downtime |
| Blue-green | instant switch/rollback | 2x resources |
| Canary | risk control | more tooling |

## 9. Production Best Practices
- Readiness probes + maxUnavailable=0 for zero-downtime.
- Set resource requests/limits + replicas ≥ 2/3.
- progressDeadlineSeconds + automated rollback on failure.
- PodDisruptionBudget to protect availability.
- GitOps-driven; pin image digests.

## 10. Security Considerations
- Pod Security context inherited from template.
- Scan images before rollout; use trusted registries.
- Least-privilege service account per Deployment.

## 11. Cost Optimization
- Right-size replicas + requests; HPA for demand.
- Avoid over-surge on large deployments (temporary cost).

## 12. Troubleshooting Scenarios
- **Rollout stuck** → readiness failing, image pull, progressDeadline hit.
- **Downtime on deploy** → maxUnavailable>0 / no readiness probe.
- **Old version lingers** → new RS not becoming ready.
- **Need revert** → `kubectl rollout undo`.

## 13. Hands-on Example
```bash
kubectl set image deployment/api api=myacr.azurecr.io/api:2.0
kubectl rollout status deployment/api
kubectl rollout undo deployment/api      # rollback
```

## 14. Terraform Example
```hcl
resource "kubernetes_deployment" "api" {
  metadata { name = "api" namespace = "app" }
  spec {
    replicas = 3
    selector { match_labels = { app = "api" } }
    strategy { type = "RollingUpdate"
      rolling_update { max_surge = "25%" max_unavailable = "0" } }
    template {
      metadata { labels = { app = "api" } }
      spec { container { name = "api" image = "myacr.azurecr.io/api:2.0" } }
    }
  }
}
```

## 15. Azure Example
```bash
kubectl apply -f deployment.yaml     # to AKS
kubectl get rs                        # see new vs old ReplicaSets
```

## 16. FastAPI / Python Example
```python
# Readiness gates the rolling update — return 503 until warm
@app.get("/readyz")
def readyz():
    return {"ready": True} if warmed_up() else (_ for _ in ()).throw(
        HTTPException(503))
```

## 17. AKS Example (Deployment manifest)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: api, namespace: app }
spec:
  replicas: 3
  progressDeadlineSeconds: 300
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 25%, maxUnavailable: 0 }
  selector: { matchLabels: { app: api } }
  template:
    metadata: { labels: { app: api } }
    spec:
      serviceAccountName: api-sa
      containers:
        - name: api
          image: myacr.azurecr.io/api@sha256:...   # pin digest
          readinessProbe: { httpGet: { path: /readyz, port: 8000 } }
```

## 18. How to Remember
**"Deployment → ReplicaSet → Pods, with safe rolling updates + rollback."** You manage the Deployment; it manages the rest.

## 19. Real-World Analogy
A shift manager replacing staff one at a time so the store never closes (rolling update) — and keeping the old schedule handy to switch back instantly if the new shift underperforms (rollback).

## 20. One-Page Cheat Sheet
- **What**: controller managing ReplicaSets/Pods for stateless apps.
- **Rollout**: new ReplicaSet, gradual shift, gated by readiness (zero-downtime).
- **Knobs**: maxSurge (speed), maxUnavailable=0 (no downtime), progressDeadline.
- **Rollback**: `kubectl rollout undo` from revision history.
- **Strategies**: RollingUpdate default; Recreate/blue-green/canary as needed.
- **Stateful?** use StatefulSet instead.
