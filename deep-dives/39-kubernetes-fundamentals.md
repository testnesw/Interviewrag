# Deep Dive · Kubernetes Fundamentals

> Phase 2 (Platform & apps) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Kubernetes (K8s) is an **open-source container orchestrator**: you declare *desired state* (what should run, how many, how networked) and K8s continuously **reconciles reality to match** — scheduling containers, restarting failures, scaling, rolling out updates, and providing service discovery/load balancing. It turns a fleet of machines into **one programmable, self-healing compute platform**. The core mental model is a **control loop**: controllers watch desired vs actual state and act to close the gap.

---

## 2. Architect-Level Explanation
K8s is a **declarative, API-driven control system**:
- **Control plane**: **API server** (front door), **etcd** (state store), **scheduler** (placement), **controller-manager** (reconcile loops), **cloud-controller** (cloud integration).
- **Data plane (nodes)**: **kubelet** (runs pods), **container runtime** (containerd), **kube-proxy/CNI** (networking).
- **Objects**: Pods → managed by **Deployments/ReplicaSets** (stateless), **StatefulSets** (stateful), **DaemonSets** (per-node), **Jobs/CronJobs** (batch).
- **Networking**: **Services** (stable virtual IP), **Ingress** (L7 routing), **NetworkPolicies** (segmentation), **CoreDNS**.
- **Config/secrets**: **ConfigMaps**, **Secrets**; **Volumes/PV/PVC** for storage.
- **Scaling/health**: **HPA/VPA**, probes, **PodDisruptionBudgets**.

The architectural essence: **everything is an object in etcd; controllers reconcile; you never imperatively "do", you declare.**

---

## 3. Why It Exists
- **Problem**: containers solved packaging, but running them at scale (placement, failure recovery, networking, rollout, scaling) across many hosts was manual and fragile.
- **Breakthrough**: Google's Borg experience → K8s: a **declarative, self-healing** orchestrator with a pluggable API.
- **Why enterprises adopt it**: portability (any cloud/on-prem), a huge ecosystem, standardized ops, and elasticity — one platform for many workloads/teams.
- **Why it won**: the **declarative + controller** model + **extensibility (CRDs/operators)** made it the de-facto standard.

---

## 4. Internal Working
**Reconciliation loop:**
```
1. You POST desired state (YAML) to the API server → stored in etcd
2. Controllers watch etcd; compare desired vs actual
3. Scheduler assigns unscheduled pods to nodes (resources/affinity/taints)
4. kubelet on the node pulls images + starts containers (via containerd)
5. Probes report health; failures → controller recreates pods (self-heal)
6. Services + kube-proxy/CNI provide stable networking + load balancing
7. HPA adjusts replica counts from metrics; rollouts update pods gradually
```
Key mechanics:
- **Desired state** in etcd is the single source of truth.
- **Controllers** (Deployment, ReplicaSet, Job…) each own a reconcile loop.
- **Scheduler** scores nodes by requests, affinity/anti-affinity, taints/tolerations, topology.
- **Services**: ClusterIP (internal), NodePort, LoadBalancer, plus **Ingress** for L7.
- **Labels/selectors** wire everything (Service → Pods, Deployment → Pods).

Properties: **declarative, self-healing, eventually consistent, extensible (CRDs)**.

---

## 5. Enterprise Use Case
A retailer runs its microservices platform on Kubernetes: **Deployments** for stateless APIs (HPA-scaled), **StatefulSets** for Kafka, **DaemonSets** for log/telemetry agents, **CronJobs** for nightly ETL. **Ingress** routes external traffic; **NetworkPolicies** segment services; **ConfigMaps/Secrets** externalize config; **HPA** scales on Black-Friday load. The same manifests deploy to dev/stage/prod, giving portability and consistent operations.

---

## 6. Real Production Architecture
```
        kubectl / CI ─► API Server ─► etcd (desired state)
                          │  ▲
        Scheduler ◄───────┘  └──────► Controller Manager (reconcile)
            │ places pods
 ┌──────── Nodes ────────────────────────────────────────────┐
 │ kubelet + containerd  ── run ──►  Pods (Deployments/HPA)   │
 │ kube-proxy/CNI ── networking ──►  Services ─► Ingress ─► LB │
 │ DaemonSet: log/otel agents      ConfigMaps/Secrets/PVCs    │
 └────────────────────────────────────────────────────────────┘
```

---

## 7. Security Best Practices
- **RBAC** least-privilege for users/service accounts; no cluster-admin by default.
- **NetworkPolicies** default-deny; segment namespaces/workloads.
- **Pod Security** (restricted): non-root, read-only rootfs, drop capabilities, no privileged.
- **Secrets**: external store (Key Vault CSI/Vault) or at least encrypt etcd at rest; never in images.
- **Admission control** (OPA/Gatekeeper/Kyverno): enforce policy (allowed registries, labels, limits).
- **Image security**: scan, sign, minimal base; pull from trusted registries only.
- **Namespaces + quotas** for isolation; **audit logging** on the API server.

---

## 8. Scaling Strategy
- **HPA** (pods, on CPU/mem/custom), **VPA** (right-size requests), **Cluster Autoscaler** (nodes), **KEDA** (events).
- **Requests/limits** correct → scheduler + autoscalers work; **PDBs** protect during scale/upgrade.
- **Topology spread** across zones; **overprovision** with low-priority pause pods for burst.
- **Horizontal-first** design (stateless); externalize state.

---

## 9. High Availability Strategy
- **HA control plane** (3+ etcd, multi-master) — managed for you in AKS.
- **Multi-replica** workloads + **anti-affinity** + **topologySpreadConstraints** across nodes/zones.
- **PodDisruptionBudgets**; **readiness/liveness/startup probes**; **rolling updates** with surge/maxUnavailable.
- Spread nodes across **Availability Zones**.

---

## 10. Disaster Recovery Strategy
- **GitOps** (Flux/ArgoCD): manifests in Git → recreate cluster state quickly.
- **etcd backups** (or managed control plane) + **Velero** for objects/PV snapshots.
- **Stateless clusters**; persistent data in managed/replicated stores.
- **IaC** to rebuild clusters; document RTO/RPO; drill failovers.

---

## 11. Cost Optimization Strategy
- **Right-size requests/limits** (VPA recommendations) — #1 lever.
- **Bin-pack** efficiently; **Cluster Autoscaler** scale-down; **spot/preemptible** nodes for tolerant workloads.
- **Scale-to-zero** (KEDA) for event workloads; remove idle namespaces.
- **Cost visibility**: OpenCost/Kubecost, namespace chargeback.

---

## 12. Common Production Challenges
- **Missing requests/limits** → OOMKills, noisy neighbors, bad scheduling.
- **CrashLoopBackOff / Pending** → config/resource/scheduling issues.
- **Networking/DNS** issues at scale → CoreDNS tuning, NodeLocal DNSCache.
- **Rollout failures** → bad probes/images; use canary/rollback.
- **Secret/config drift** → GitOps as source of truth.
- **Upgrade/deprecation churn** → track API deprecations, test, stay current.
- **Stateful workloads** are hard → prefer managed services when possible.

---

## 13. Monitoring and Observability
- **Metrics**: Prometheus + Grafana; **kube-state-metrics**, node/pod metrics.
- **Logs**: centralized (Loki/ELK/Log Analytics) via DaemonSet agents.
- **Traces**: OpenTelemetry → backend (App Insights/Jaeger).
- **Golden signals** per service; alerts on crashloops, HPA-maxed, node not-ready, PVC full.

---

## 14. Troubleshooting Scenarios
- **Pending** → `kubectl describe pod`: resources/taints/PV binding; scale nodes.
- **CrashLoopBackOff** → logs + events; bad config/missing secret/probe too strict.
- **Service unreachable** → selector/endpoint mismatch, readiness failing, NetworkPolicy blocking.
- **DNS failures** → CoreDNS health, NodeLocal cache.
- **Slow rollout stuck** → readiness never passes; check probe + `kubectl rollout status`, then rollback.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| K8s vs PaaS | portable, flexible, ecosystem | operational complexity |
| StatefulSet vs managed DB | in-cluster control | ops burden, risk |
| More abstraction (mesh/operators) | power | complexity/latency |
| Self-managed vs AKS | full control | you run the control plane |

---

## 16. When NOT to use it
- **A couple of simple containers/apps** → PaaS (Container Apps/App Service).
- **No platform/ops capacity** → don't adopt raw K8s.
- **Purely serverless/event** patterns → Functions.
- **Heavy stateful/DB needs** → managed data services, not in-cluster.

---

## 17. Comparison with Alternatives
| Option | Portability | Ops burden | Best for |
|--------|------------|-----------|----------|
| **Kubernetes** | high | high | complex, portable microservices |
| Managed K8s (AKS/EKS/GKE) | high | medium | K8s without control-plane ops |
| Container Apps/Cloud Run | medium | low | scalable containers w/o K8s |
| PaaS/App Service | low | very low | web apps |
| Serverless (Functions) | low | very low | event-driven |

---

## 18. Interview Questions
1. Explain the reconciliation loop / declarative model.
2. Pod vs ReplicaSet vs Deployment?
3. Deployment vs StatefulSet vs DaemonSet — when each?
4. Service types (ClusterIP/NodePort/LoadBalancer) and Ingress?
5. How do labels/selectors tie objects together?
6. Requests vs limits — impact on scheduling and reliability?
7. How do rolling updates and rollbacks work?
8. How do you secure a cluster (RBAC, NetworkPolicy, PSA)?
9. ConfigMaps vs Secrets — and how to manage secrets properly?
10. How does HPA work and what can it scale on?

---

## 19. Strong Interview Answers
- **Declarative model**: "I declare desired state to the API server; it's stored in etcd, and controllers run reconcile loops to make reality match. I never imperatively manage pods — the system self-heals by design."
- **Deployment vs StatefulSet vs DaemonSet**: "Deployment for stateless, interchangeable replicas; StatefulSet for stable identity/ordered storage (databases, Kafka); DaemonSet for one-per-node agents (logging, CNI). The choice follows identity and storage needs."
- **Requests vs limits**: "Requests drive scheduling and guaranteed resources; limits cap usage. Too-low limits cause CPU throttling/OOMKills; missing requests cause bad packing and noisy neighbors. Right-sizing is the foundation of both reliability and cost."
- **Rolling update**: "Deployment creates a new ReplicaSet and shifts pods gradually with maxSurge/maxUnavailable, gated by readiness probes; if it fails I `kubectl rollout undo` to the prior ReplicaSet. For safer releases I add canary/blue-green."
- **Security**: "Least-privilege RBAC, default-deny NetworkPolicies, restricted Pod Security (non-root, drop caps), external secrets, and admission policy via Gatekeeper/Kyverno."

---

## 20. Architecture Diagrams
**Object hierarchy:**
```
Deployment ─► ReplicaSet ─► Pods ─► Containers
   │ (rolling update creates new ReplicaSet)
Service (selector) ─► Pods        Ingress ─► Service (L7)
ConfigMap/Secret ─► mounted/env into Pods
```

---

## 21. Real Project Example
**Portable microservices platform.** ~40 services as Deployments with HPA; Kafka as a StatefulSet; Fluent Bit as a DaemonSet; nightly reconciliation as CronJobs. GitOps (ArgoCD) is the source of truth across dev/stage/prod; OPA Gatekeeper enforces non-root + resource limits + ACR-only images; Prometheus/Grafana + OpenTelemetry for observability. Same manifests run on AKS in cloud and on-prem for a regulated workload — portability was the deciding factor.

---

## 22. Whiteboard Design Question
> *"Design a multi-tenant Kubernetes platform for 10 teams with strong isolation."*

Cover: namespaces per team + RBAC + ResourceQuotas/LimitRanges + default-deny NetworkPolicies → admission policy (Gatekeeper) → GitOps onboarding → shared ingress + cert management → observability with per-namespace dashboards → autoscaling (HPA/CA) → node pools (general/spot/GPU) → security (PSA restricted, external secrets) → cost chargeback. Discuss soft vs hard multi-tenancy trade-offs.

---

## 23. Design Review Questions
- Are **requests/limits** set on every workload?
- **Default-deny NetworkPolicies** in place?
- **RBAC** least-privilege; any cluster-admin bindings?
- **Secrets** externalized/encrypted?
- **Rollout strategy** + rollback tested; probes correct?
- **GitOps** as source of truth?
- **Autoscaling** + PDBs configured?
- **Stateful** workloads justified vs managed services?

---

## 24. Hands-on Example
```bash
kubectl create namespace shop
kubectl -n shop create deployment api --image=myacr.azurecr.io/api:1.0 --replicas=3
kubectl -n shop expose deployment api --port=80 --target-port=8000   # ClusterIP Service
kubectl -n shop autoscale deployment api --cpu-percent=65 --min=3 --max=20  # HPA
kubectl -n shop rollout status deployment/api
kubectl -n shop set image deployment/api api=myacr.azurecr.io/api:1.1  # rolling update
kubectl -n shop rollout undo deployment/api                            # rollback
```

---

## 25. Terraform Example
```hcl
# Manage K8s objects declaratively via the kubernetes provider (GitOps is often preferred)
resource "kubernetes_namespace" "shop" { metadata { name = "shop" } }

resource "kubernetes_resource_quota" "shop_quota" {
  metadata { name = "quota" namespace = kubernetes_namespace.shop.metadata[0].name }
  spec { hard = { "requests.cpu" = "10", "requests.memory" = "20Gi", "pods" = "50" } }
}

resource "kubernetes_network_policy" "default_deny" {
  metadata { name = "default-deny" namespace = kubernetes_namespace.shop.metadata[0].name }
  spec { pod_selector {}  policy_types = ["Ingress", "Egress"] }  # deny all by default
}
```

---

## 26. Azure Example
```bash
# Connect to an AKS cluster and apply GitOps (Flux) as the reconciliation source of truth
az aks get-credentials -g rg -n genai-aks
az k8s-configuration flux create -g rg -c genai-aks -t managedClusters \
  -n platform --namespace flux-system \
  --url https://github.com/org/k8s-manifests --branch main \
  --kustomization name=apps path=./apps prune=true
```

---

## 27. Code Example
```yaml
# StatefulSet with stable identity + per-pod storage (e.g., a clustered workload)
apiVersion: apps/v1
kind: StatefulSet
metadata: { name: kafka, namespace: platform }
spec:
  serviceName: kafka
  replicas: 3
  selector: { matchLabels: { app: kafka } }
  template:
    metadata: { labels: { app: kafka } }
    spec:
      containers:
      - name: kafka
        image: myacr.azurecr.io/kafka:3.7
        resources: { requests: { cpu: "500m", memory: "1Gi" }, limits: { cpu: "2", memory: "4Gi" } }
        volumeMounts: [{ name: data, mountPath: /var/lib/kafka }]
  volumeClaimTemplates:                       # each pod gets its own PVC (stable storage)
  - metadata: { name: data }
    spec: { accessModes: ["ReadWriteOnce"], resources: { requests: { storage: 100Gi } } }
```

---

## 28. Things Architects Must Remember
- **Declarative + reconcile loop** is the whole philosophy — declare, don't do.
- **Deployment (stateless) vs StatefulSet (identity/storage) vs DaemonSet (per-node)** — pick by needs.
- **Requests/limits** underpin reliability *and* cost.
- **Labels/selectors** are the glue; get them right.
- **Security baseline**: RBAC + NetworkPolicy default-deny + restricted Pod Security + external secrets + admission policy.
- **GitOps makes clusters rebuildable** — desired state lives in Git.
- **Prefer managed services for state**; keep clusters stateless.
- **Extensibility (CRDs/operators)** is why K8s wins — but adds complexity.

---

## 29. Mnemonics and Memory Tricks
- **"Declare, don't do"** — the reconcile loop mantra.
- **Workload types "D-S-D-J"**: **D**eployment, **S**tatefulSet, **D**aemonSet, **J**ob/CronJob.
- **Service types "C-N-L-I"**: **C**lusterIP, **N**odePort, **L**oadBalancer, **I**ngress (L7).
- **Security "R-N-P-S"**: **R**BAC, **N**etworkPolicy, **P**od Security, **S**ecrets external.
- **"Labels are the glue"** — selectors connect Services↔Pods↔Deployments.

---

## 30. One-Page Interview Revision Sheet
- **What**: declarative container orchestrator; desired state in etcd, controllers reconcile, self-healing.
- **Control plane**: API server · etcd · scheduler · controller-manager. **Nodes**: kubelet · containerd · kube-proxy/CNI.
- **Workloads**: Deployment (stateless) · StatefulSet (identity/storage) · DaemonSet (per-node) · Job/CronJob.
- **Networking**: Service (ClusterIP/NodePort/LB) · Ingress (L7) · NetworkPolicy · CoreDNS.
- **Config**: ConfigMap/Secret · Volumes/PV/PVC.
- **Scale/health**: HPA/VPA/CA/KEDA · probes · PDB · requests/limits.
- **Security**: RBAC · default-deny NetworkPolicy · restricted PSA · external secrets · admission policy.
- **HA/DR**: multi-replica + anti-affinity + AZ spread + PDB; GitOps + backups + IaC rebuild.
- **Cost**: right-size, bin-pack, spot, scale-to-zero, chargeback.
- **Remember**: *declare don't do*; **D-S-D-J** workloads; **C-N-L-I** services; labels are the glue; GitOps = rebuildable.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain the reconciliation loop and why it makes K8s self-healing.
2. Walk the chain Deployment → ReplicaSet → Pod and what a rolling update actually does.
3. When do you choose a StatefulSet over a Deployment? Give two concrete workloads.
4. Compare all Service types and when you'd use Ingress instead.
5. A pod is stuck Pending. Give your full diagnostic path.
6. What breaks if you omit requests and limits? Reliability and cost angles.
7. Design a default-deny network posture for a namespace and justify it.
8. How do you manage secrets properly in K8s? Why are raw Secrets insufficient?
9. Explain GitOps and how it becomes your DR strategy.
10. How would you enforce org-wide policy (non-root, ACR-only, limits) across 10 teams?

---

> Next Phase 2 topic: **Docker / Containerization**.
