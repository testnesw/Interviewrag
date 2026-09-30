# 42 · ReplicaSets

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A ReplicaSet makes sure a **specified number of identical Pods are always running**. If one dies, it creates a replacement. You usually don't create it directly — a Deployment creates and manages it for you.

## 2. Architect-Level Explanation
A controller that maintains a stable set of replica Pods:
- **Reconciliation**: watches Pods matching its **label selector**; creates/deletes to match `replicas`.
- **Ownership**: adopts Pods via `ownerReferences`; Deployments create a new ReplicaSet per revision (enabling rollout/rollback).
- **vs ReplicationController**: ReplicaSet is the newer version with set-based selectors.
- **Direct use is rare**: Deployments layer versioning/rollouts on top; you manage Deployments, not ReplicaSets.

## 3. Real Enterprise Use Case
During a Deployment rollout, two ReplicaSets coexist: the old (v1) scaling down and the new (v2) scaling up. Understanding this helps engineers debug stuck rollouts by inspecting each ReplicaSet's Pod status and events.

## 4. Architecture Diagram (ASCII)
```
   Deployment
      │ creates one ReplicaSet per revision
   ReplicaSet (selector app=api, replicas=3)
      │ ensures count via reconcile loop
    Pod  Pod  Pod   ← if one dies, RS creates a new one
   (matched by label selector app=api)
```

## 5. Interview Questions
1. What does a ReplicaSet do?
2. ReplicaSet vs Deployment?
3. How does it know which Pods to manage?
4. Why do you rarely create ReplicaSets directly?
5. ReplicaSet vs ReplicationController?

## 6. Strong Interview Answers
- **Purpose**: "It guarantees a desired number of Pod replicas are running by continuously reconciling actual vs desired using a label selector — the mechanism behind self-healing replica counts."
- **vs Deployment**: "A Deployment manages ReplicaSets to add versioning, rolling updates, and rollback. The ReplicaSet only maintains count — it has no rollout logic. So I use Deployments and let them manage ReplicaSets."
- **Selector**: "It owns Pods matching its label selector; it uses ownerReferences to track them. Mismatched labels can cause it to adopt or orphan Pods unexpectedly."
- **Rarely direct**: "Because Deployments give rollouts/rollback on top; a bare ReplicaSet can't do version transitions safely."
- **vs RC**: "ReplicaSet supersedes ReplicationController with set-based selectors (e.g., `in`, `notin`); RC only supports equality selectors."

## 7. Common Mistakes
- Creating ReplicaSets directly (lose rollout/rollback).
- Overlapping selectors causing Pod adoption conflicts.
- Manually editing ReplicaSets managed by a Deployment.
- Confusing replica count with autoscaling (that's HPA).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| ReplicaSet direct | minimal | no rollout/rollback |
| Deployment (wraps RS) | versioning, safe updates | slight abstraction |

## 9. Production Best Practices
- Use Deployments; let them own ReplicaSets.
- Unique, non-overlapping label selectors.
- Understand old/new RS during rollouts for debugging.
- Combine with HPA for dynamic replicas.

## 10. Security Considerations
- Pod template security context applies to RS Pods.
- Scoped RBAC; avoid manual RS tampering.

## 11. Cost Optimization
- Replica count drives cost — tune via HPA + requests.
- Clean up old, scaled-to-zero ReplicaSets (revision history limit).

## 12. Troubleshooting Scenarios
- **Wrong Pod count** → selector mismatch, resource limits, events.
- **Stuck rollout** → new RS Pods not ready (`describe rs`).
- **Orphaned Pods** → label/selector conflict.
- **Too many old RS** → set `revisionHistoryLimit`.

## 13. Hands-on Example
```bash
kubectl get rs                       # list ReplicaSets (old + new)
kubectl describe rs <replicaset>     # events, pod status
kubectl get pods --show-labels
```

## 14. Terraform Example
```hcl
# Usually managed by a Deployment; direct RS shown for completeness
resource "kubernetes_replica_set" "api" {
  metadata { name = "api-rs" namespace = "app" }
  spec {
    replicas = 3
    selector { match_labels = { app = "api" } }
    template {
      metadata { labels = { app = "api" } }
      spec { container { name = "api" image = "myacr.azurecr.io/api:1.0" } }
    }
  }
}
```

## 15. Azure Example
```bash
# During AKS rollout, watch RS transition
kubectl rollout status deployment/api
kubectl get rs -l app=api -o wide
```

## 16. FastAPI / Python Example
```python
from kubernetes import client, config
config.load_incluster_config()
apps = client.AppsV1Api()

@app.get("/replicasets")
def replicasets():
    return [{"name": r.metadata.name, "ready": r.status.ready_replicas}
            for r in apps.list_namespaced_replica_set("app").items]
```

## 17. AKS Example
Set `revisionHistoryLimit: 5` on Deployments so AKS keeps only recent ReplicaSets for rollback, avoiding clutter from frequent deploys.

## 18. How to Remember
**"Keeps N Pods alive; Deployment keeps N *versions* straight."** RS = count; Deployment = count + rollout.

## 19. Real-World Analogy
A shift supervisor ensuring exactly N workers are always on the floor — if someone leaves, they call in a replacement. The Deployment is HR, deciding *which* team version is on shift.

## 20. One-Page Cheat Sheet
- **What**: maintains desired number of identical Pods via label selector.
- **Owned by**: Deployment (one RS per revision) — don't create directly.
- **Enables**: self-healing replica count; rollout uses old+new RS.
- **vs RC**: set-based selectors (newer).
- **Debug**: `kubectl get/describe rs` during rollouts.
- **Housekeeping**: `revisionHistoryLimit` to prune old RS.
