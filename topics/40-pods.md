# 40 · Pods

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A Pod is the **smallest deployable unit** in Kubernetes — usually one container (sometimes a few tightly-coupled ones) that share the same network and storage. You don't run containers directly; you run Pods.

## 2. Architect-Level Explanation
- **Shared context**: containers in a Pod share network namespace (same IP/port space, localhost) and can share volumes.
- **Ephemeral**: Pods are mortal — they get a unique IP but are replaced (new IP) on failure; managed by controllers (Deployment/StatefulSet/Job), not created directly in prod.
- **Patterns**: sidecar (logging/proxy), init containers (run-before-main), ambassador/adapter.
- **Lifecycle**: Pending → Running → Succeeded/Failed; probes (liveness/readiness/startup) govern health.
- **Scheduling**: placed by node resources, requests/limits, affinity/taints/tolerations, topology spread.

## 3. Real Enterprise Use Case
A payments service Pod runs the app container + an Envoy sidecar (mTLS/service mesh) + an init container that runs DB migrations before startup. Readiness probe gates traffic until migrations + warmup complete.

## 4. Architecture Diagram (ASCII)
```
   POD (shared network + volumes)
   ┌───────────────────────────────┐
   │ init-container (migrations)    │ runs first, then exits
   │ ─────────────────────────────  │
   │ app container ◄─localhost─► sidecar (Envoy)
   │      │ readiness/liveness probes
   └──────┼────────────────────────┘
       Pod IP (ephemeral) ; replaced on failure by controller
```

## 5. Interview Questions
1. Why Pods instead of running containers directly?
2. What do containers in a Pod share?
3. Init containers vs sidecars?
4. Liveness vs readiness vs startup probes?
5. Why are Pods considered ephemeral?

## 6. Strong Interview Answers
- **Why Pods**: "Pods add a shared execution context (network, storage, lifecycle) so tightly-coupled containers can cooperate, and give K8s a consistent unit to schedule, scale, and heal."
- **Shared**: "Network namespace (same Pod IP, communicate over localhost) and optionally volumes; they don't share the process/filesystem by default."
- **Init vs sidecar**: "Init containers run to completion *before* app containers (setup/migrations/waiting on deps); sidecars run *alongside* the main container for the Pod's life (proxy, logging, mesh)."
- **Probes**: "Liveness restarts a hung container; readiness gates traffic until ready (removed from Service endpoints if failing); startup protects slow-starting apps from premature liveness kills."
- **Ephemeral**: "Pods aren't self-healing on their own and get new IPs when recreated — so you manage them via controllers and reach them via Services (stable), never by Pod IP."

## 7. Common Mistakes
- Creating bare Pods in prod (no self-healing) instead of Deployments.
- Relying on Pod IPs (they change).
- Missing readiness probe → traffic to unready pods.
- No resource requests/limits.
- Cramming unrelated containers into one Pod.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Multi-container Pod | tight coupling, shared context | coupled lifecycle/scaling |
| Single-container Pod | simple, independent scaling | no in-pod helpers |

## 9. Production Best Practices
- Manage via Deployments/StatefulSets, not bare Pods.
- Requests/limits + all three probes as needed.
- One main concern per Pod; sidecars for cross-cutting.
- Graceful shutdown (preStop + termination grace).
- Topology spread + anti-affinity for HA.

## 10. Security Considerations
- Pod Security Standards (no privileged, drop capabilities).
- runAsNonRoot, read-only root FS, seccomp.
- No secrets in env if avoidable (mount from Secret/CSI).
- Least-privilege service account.

## 11. Cost Optimization
- Right-size requests (biggest lever for bin-packing).
- Avoid over-provisioned sidecars.
- Use VPA recommendations to tune.

## 12. Troubleshooting Scenarios
- **Pending** → unschedulable (resources/taints/PVC).
- **CrashLoopBackOff** → `kubectl logs --previous`, bad config/probe.
- **ImagePullBackOff** → registry auth / wrong tag.
- **Not receiving traffic** → readiness failing / Service selector.

## 13. Hands-on Example
```bash
kubectl run tmp --image=nginx --restart=Never   # bare pod (debug only)
kubectl logs <pod> ; kubectl describe pod <pod>
kubectl exec -it <pod> -- sh
```

## 14. Terraform Example
```hcl
resource "kubernetes_pod" "debug" {
  metadata { name = "debug" namespace = "app" }
  spec { container { name = "nginx" image = "nginx:1.27" } }
}
```

## 15. Azure Example
On AKS, Pods get VNet IPs (Azure CNI) or overlay IPs; view with `kubectl get pods -o wide`; node placement follows AKS node pools/zones.

## 16. FastAPI / Python Example (probes)
```python
@app.get("/livez")     # liveness: process is alive
def livez(): return {"status": "alive"}

@app.get("/readyz")    # readiness: ready to serve
def readyz():
    if not deps_ready(): raise HTTPException(503, "not ready")
    return {"status": "ready"}
```

## 17. AKS Example (Pod spec)
```yaml
spec:
  securityContext: { runAsNonRoot: true }
  initContainers:
    - name: migrate
      image: myacr.azurecr.io/migrate:1.0
  containers:
    - name: api
      image: myacr.azurecr.io/api:1.0
      readinessProbe: { httpGet: { path: /readyz, port: 8000 } }
      livenessProbe:  { httpGet: { path: /livez, port: 8000 } }
      resources:
        requests: { cpu: "250m", memory: "256Mi" }
        limits:   { cpu: "500m", memory: "512Mi" }
```

## 18. How to Remember
**"Smallest unit; containers that live and die together."** Never rely on a Pod directly — use controllers + Services.

## 19. Real-World Analogy
A Pod is like an apartment shared by roommates (containers): they share the same address (IP) and utilities (volumes), coordinate closely — and if the building is condemned, everyone moves out together to a new address.

## 20. One-Page Cheat Sheet
- **What**: smallest deployable unit; 1+ containers sharing network + volumes.
- **Ephemeral**: replaced with new IP → use Services + controllers.
- **Helpers**: init containers (before), sidecars (alongside).
- **Probes**: liveness (restart), readiness (traffic gate), startup (slow apps).
- **Prod**: Deployments not bare Pods; requests/limits; PSS security.
- **Debug**: describe (events) → logs → exec.
