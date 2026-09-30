# 39 · Kubernetes Fundamentals

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
Kubernetes (K8s) is a system that **runs and manages containers at scale** — it schedules them, restarts failed ones, scales them up/down, and handles networking, so you declare *what* you want and K8s keeps it that way.

## 2. Architect-Level Explanation
A declarative container orchestrator built on a **control loop** model:
- **Control plane**: API server (front door), **etcd** (state store), scheduler (placement), controller-manager (reconciliation loops), cloud-controller.
- **Nodes**: kubelet (runs pods), kube-proxy (networking), container runtime (containerd).
- **Declarative + reconciliation**: you submit desired state (YAML); controllers continuously drive actual → desired.
- **Objects**: Pods, ReplicaSets, Deployments, Services, ConfigMaps, Secrets, Namespaces, etc.
- **Extensibility**: CRDs + operators, admission controllers, CNI/CSI/CRI plugins.

## 3. Real Enterprise Use Case
A retailer runs 300 microservices on Kubernetes: declarative manifests in Git (GitOps), self-healing on node failure, horizontal autoscaling for sales peaks, namespaces per team, and RBAC + network policies for isolation — one platform, many teams.

## 4. Architecture Diagram (ASCII)
```
        CONTROL PLANE
  API Server ─ etcd (state)
      │  ├ Scheduler (placement)
      │  └ Controller Manager (reconcile loops)
      ▼ (declarative desired state)
   NODES: kubelet + kube-proxy + containerd
      └ Pods (containers)
  Loop: actual state ──drive to──► desired state
```

## 5. Interview Questions
1. What is the reconciliation/control-loop model?
2. Control plane vs data plane components?
3. What does etcd store and why protect it?
4. Imperative vs declarative management?
5. How does Kubernetes self-heal?

## 6. Strong Interview Answers
- **Control loop**: "You declare desired state; controllers continuously compare actual vs desired and act to converge. That's why K8s self-heals — kill a pod and the ReplicaSet recreates it."
- **Control vs data plane**: "Control plane (API server, etcd, scheduler, controllers) makes decisions and stores state; data plane (kubelet, kube-proxy, runtime on nodes) runs the workloads. In AKS, Azure manages the control plane."
- **etcd**: "The single source of truth — all cluster state. It must be HA, backed up, and secured (encryption at rest); losing etcd means losing the cluster state."
- **Imperative vs declarative**: "Imperative = commands (`kubectl run`); declarative = desired-state manifests (`kubectl apply`). Declarative + GitOps is the production standard — reproducible and auditable."
- **Self-heal**: "Controllers recreate failed pods, the scheduler reschedules off dead nodes, and probes restart/remove unhealthy containers."

## 7. Common Mistakes
- Treating K8s imperatively (kubectl edits) vs declarative/GitOps.
- No resource requests/limits.
- Ignoring etcd backup/security.
- Misunderstanding that Deployments manage ReplicaSets manage Pods.
- No liveness/readiness probes.

## 8. Trade-offs
| Aspect | K8s | Simpler PaaS |
|--------|-----|--------------|
| Flexibility/portability | high | low |
| Operational complexity | high | low |
| Scale/ecosystem | huge | limited |

## 9. Production Best Practices
- Declarative manifests + GitOps.
- Requests/limits + probes on every workload.
- Namespaces + RBAC + network policies.
- Back up etcd (or use managed control plane).
- Version/upgrade strategy; admission policies (OPA/Gatekeeper).

## 10. Security Considerations
- RBAC least privilege; no cluster-admin sprawl.
- etcd encryption at rest; secure API server.
- Network policies; Pod Security Standards.
- Scan images; restrict registries.

## 11. Cost Optimization
- Right-size requests; autoscale (HPA/cluster autoscaler).
- Bin-pack efficiently; use spot for stateless.
- Remove idle namespaces/workloads.

## 12. Troubleshooting Scenarios
- **Pod not running** → `kubectl describe pod` events, `logs`.
- **Node NotReady** → kubelet/network/disk pressure.
- **Scheduling fails** → resources/taints/affinity.
- **State issues** → etcd health (managed in AKS).

## 13. Hands-on Example
```bash
kubectl apply -f deployment.yaml     # declarative
kubectl get pods -o wide
kubectl describe pod <pod>           # events at bottom
```

## 14. Terraform Example
```hcl
# Manage K8s objects via Terraform kubernetes provider
resource "kubernetes_namespace" "app" {
  metadata { name = "app" labels = { team = "platform" } }
}
```

## 15. Azure Example
```bash
az aks get-credentials -g rg-aks -n prod-aks   # kubeconfig for API access
kubectl cluster-info
```

## 16. FastAPI / Python Example
```python
from kubernetes import client, config
config.load_incluster_config()          # running inside a pod
v1 = client.CoreV1Api()

@app.get("/pods")
def pods():
    return [p.metadata.name for p in v1.list_namespaced_pod("app").items]
```

## 17. AKS Example
AKS provides the managed control plane (etcd/API server) with an Uptime SLA; you manage node pools + workloads. `kubectl` talks to the Azure-managed API server (private in a private cluster).

## 18. How to Remember
**"Declare desired state; controllers make it real and keep it real."** Everything is a reconciliation loop.

## 19. Real-World Analogy
A thermostat: you set the desired temperature (desired state); it continuously senses the room (actual) and runs the heater/AC (controllers) to converge — automatically correcting drift.

## 20. One-Page Cheat Sheet
- **What**: declarative container orchestrator with reconciliation loops.
- **Control plane**: API server, etcd (state), scheduler, controllers.
- **Nodes**: kubelet, kube-proxy, containerd → run pods.
- **Model**: apply desired state → controllers converge → self-healing.
- **Prod**: GitOps, requests/limits, probes, RBAC, network policies.
- **AKS**: Azure manages the control plane; you manage nodes/workloads.
