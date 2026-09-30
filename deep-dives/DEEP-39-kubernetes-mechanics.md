# DEEP MECHANICS · Kubernetes

> Level 2 — the internals interviewers probe: the reconcile loop, scheduler
> algorithm, kube-proxy/Service routing, pod networking, probes, and the exact
> failure-debugging logic that separates a user from an architect.

---

## 0. The precise mental model
Kubernetes is a set of **controllers running reconcile loops** against a **declarative desired state** stored in **etcd**. You write desired state to the **API server**; controllers continuously compare *desired vs actual* and take actions to converge. Nothing is imperative — everything is "observe → diff → act → repeat." Understand the control loop and everything else follows.

---

## 1. Control plane — what each component actually does

- **API server** — the *only* component that talks to etcd; the front door. Validates, authn/authz (RBAC), admission controls, then persists desired state. Everything else watches the API server.
- **etcd** — distributed **key-value store** (Raft consensus) holding the *entire* cluster state. The single source of truth. Loss of etcd = loss of the cluster (hence backup). Needs odd member count (3/5) for quorum.
- **Scheduler** — watches for **unscheduled Pods**, picks a node, writes the binding. Doesn't start containers — just decides *where*.
- **Controller manager** — runs the built-in controllers (Deployment, ReplicaSet, Node, Job…), each a reconcile loop.
- **kubelet** (on each node) — watches for Pods bound to its node, tells the **container runtime** (containerd) to pull images and run containers, runs **probes**, reports status.
- **kube-proxy** (on each node) — programs **iptables/IPVS** rules to implement Service virtual IPs.

**Deep follow-up: "What happens end-to-end when you `kubectl apply` a Deployment?"**
1. kubectl → **API server**: authn (who), authz (RBAC), **admission controllers** (mutating then validating), then write **Deployment** object to etcd.
2. **Deployment controller** sees it, creates a **ReplicaSet**.
3. **ReplicaSet controller** sees desired replicas > actual, creates **Pod** objects (still unscheduled).
4. **Scheduler** sees unbound Pods, scores nodes, **binds** each Pod to a node.
5. **kubelet** on that node sees the bound Pod, pulls image via containerd, starts containers, runs probes, reports **Ready**.
6. **Endpoints/EndpointSlice controller** adds Ready pod IPs to the Service; **kube-proxy** updates iptables so the Service VIP routes to them.
*Being able to narrate this chain is the senior signal.*

---

## 2. The reconcile loop — the heart of K8s

Every controller: **watch** (via API server watch streams) → compare **desired** (spec) vs **actual** (status) → issue changes to close the gap → repeat forever. This is why K8s is **self-healing**: kill a pod and the ReplicaSet controller observes actual < desired and creates a replacement. It's **level-triggered** (acts on *current state*, not one-time events) → robust to missed events and restarts.

**"Declare, don't do."** You never tell K8s "start a pod"; you declare "I want 3" and controllers make reality match.

---

## 3. The scheduler algorithm (two phases)

1. **Filtering (predicates)** — eliminate nodes that *can't* run the pod: insufficient CPU/mem (vs **requests**), taint not tolerated, node selector/affinity mismatch, no matching volume/zone.
2. **Scoring (priorities)** — rank surviving nodes: least-allocated (spread) vs most-allocated (bin-pack), affinity preferences, topology spread, image locality.
3. **Bind** the highest-scoring node.

**Key point: scheduling uses `requests`, not actual usage.** A node "full" on requests won't get new pods even if real CPU is idle. This is *why* wrong requests wreck scheduling.

**Taints/tolerations vs affinity:**
- **Taint** on a node = "repel pods unless they **tolerate** me" (e.g., GPU nodes, spot nodes).
- **Affinity** on a pod = "attract me to nodes/pods matching X" (or anti-affinity = spread replicas across nodes/zones for HA).

---

## 4. Requests, limits, and QoS (the OOMKill mechanics)

- **request** = guaranteed, used for **scheduling**. **limit** = hard cap enforced by the kernel (**cgroups**).
- **CPU** is *compressible*: over-limit → **throttled** (slowed, not killed).
- **Memory** is *incompressible*: over-limit → **OOMKilled** (SIGKILL) — the container restarts.
- **QoS classes** (drive eviction order under node pressure):
  - **Guaranteed** (requests==limits for all resources) — evicted last.
  - **Burstable** (requests < limits) — evicted next.
  - **BestEffort** (none set) — evicted first.

**Deep follow-up: "Pod keeps restarting with exit 137 — why?"**
137 = 128 + 9 (SIGKILL) → **OOMKilled**: memory limit too low or a leak. Fix: raise the memory limit, fix the leak, or check for a spike. (Exit 143 = SIGTERM = graceful.)

---

## 5. Pod networking — the flat model

**The rules (the "Kubernetes network model"):**
- **Every pod gets its own routable IP.**
- **Every pod can reach every other pod** without NAT (by default).
- Containers *within* a pod share the pod's network namespace (same IP, communicate over `localhost`) — a **"pause" container** holds the namespace.

**CNI** (Container Network Interface) plugin implements this: assigns pod IPs and wires routing. On Azure: **Azure CNI** (pods get real **VNet IPs** → integrate with NSGs/private endpoints, but consumes VNet IP space) vs **kubenet** (pods get an overlay IP, NAT'd via the node → fewer IPs, extra hop, fewer features).

**Restricting the open-by-default network:** **NetworkPolicies** = pod-level firewall (L3/L4) using label selectors → default-deny + explicit allow = micro-segmentation (Zero Trust inside the cluster). *Requires a CNI that enforces them (Azure CNI/Calico).*

---

## 6. Services & kube-proxy — how a Service VIP works

A **Service** gives a stable **virtual IP (ClusterIP)** + DNS name in front of ephemeral pod IPs.
- **EndpointSlice** controller tracks which pods are **Ready** (passing readiness) → the Service's backend set.
- **kube-proxy** programs **iptables/IPVS** on every node so packets to the ClusterIP are **DNAT'd** to a (random/round-robin) pod IP. It's **distributed L4 load balancing in the kernel** — no proxy process in the hot path (with iptables/IPVS mode).
- **Service types:** ClusterIP (internal) → NodePort (port on every node) → LoadBalancer (cloud LB → NodePort → pods). **Ingress** adds **L7** host/path routing via an ingress controller (NGINX/AGIC), sitting above Services.

**DNS:** CoreDNS resolves `service.namespace.svc.cluster.local` → ClusterIP.

**Deep follow-up: "Service exists but traffic fails — where do you look?"**
Is the pod **Ready** (readiness probe passing → in EndpointSlice)? `kubectl get endpointslices` — empty means no ready pods. Then selector mismatch (Service selector ≠ pod labels), wrong targetPort, or NetworkPolicy blocking. This ordered check is the answer.

---

## 7. Probes — the three types and their jobs

- **Readiness** — "can I serve traffic *now*?" Fail → **removed from Service endpoints** (no traffic), **not** restarted. For warmup/temporary dependency loss.
- **Liveness** — "am I hung/deadlocked?" Fail → **container restarted**. Misconfigured liveness (too aggressive) = **restart loops** under load.
- **Startup** — "has the slow app finished booting?" Protects slow starters from liveness killing them prematurely; liveness/readiness only begin after startup passes.

**Rolling update ties to readiness:** new pods only receive traffic once **Ready**; combined with **maxSurge/maxUnavailable** and **PodDisruptionBudgets**, this gives zero-downtime deploys. **preStop hook + SIGTERM handling** drains in-flight requests on shutdown.

---

## 8. Workload controllers — pick the right one
- **Deployment** — stateless; manages ReplicaSets; rolling updates/rollbacks. Pods interchangeable.
- **StatefulSet** — stable identity (`pod-0,1,2`), **ordered** create/delete, **stable per-pod PVC**. For databases/quorum systems.
- **DaemonSet** — one pod per node (agents: logging, CNI, monitoring).
- **Job/CronJob** — run-to-completion / scheduled.

---

## 9. The hard follow-up questions (with answers)
1. **"Narrate `kubectl apply` of a Deployment to a running, load-balanced pod."** → API server (authn/authz/admission→etcd) → Deployment ctrl→ReplicaSet→Pods → scheduler binds → kubelet runs+probes → EndpointSlice+kube-proxy iptables. (§1)
2. **"Pod is Pending — diagnose."** → `describe pod` events: insufficient requests (scale nodes / lower requests), taint not tolerated, affinity/selector unschedulable, or unbound PVC.
3. **"Pod CrashLoopBackOff exit 137 — cause?"** → OOMKilled; raise mem limit / fix leak.
4. **"Service returns no response — order of checks?"** → readiness → EndpointSlice populated? → selector==labels? → targetPort correct? → NetworkPolicy? (§6)
5. **"Why does a node 'full' on requests reject pods when CPU is idle?"** → scheduling is on **requests**, not usage; requests over-provisioned. Right-size requests.
6. **"Liveness vs readiness — which for a temporary DB outage?"** → **readiness** (stop traffic, don't restart); liveness would pointlessly restart a healthy app.
7. **"How is Service load balancing implemented?"** → kube-proxy iptables/IPVS DNAT in the kernel across Ready endpoints — distributed L4, no hot-path proxy.
8. **"Delete etcd — what happens?"** → cluster state is gone; running pods may persist briefly but the control plane can't reconcile. Hence etcd backups + odd-quorum HA.

---

## 10. One-screen deep-recall sheet
- **Model**: controllers run **reconcile loops** (level-triggered): desired (etcd via API server) vs actual → converge → self-heal. "Declare, don't do."
- **Control plane**: API server (only one talking to **etcd/Raft**), scheduler (where), controller-manager (reconcilers), kubelet (runs pods + probes), kube-proxy (Service iptables).
- **apply chain**: API(authn/authz/admission→etcd)→Deployment→ReplicaSet→Pods→scheduler bind→kubelet run→EndpointSlice+kube-proxy.
- **Scheduler**: filter (predicates on **requests**/taints/affinity) → score → bind. Full-on-requests ≠ full-on-usage.
- **requests/limits**: request=schedule guarantee; CPU over=**throttle**, memory over=**OOMKill (137)**. QoS Guaranteed>Burstable>BestEffort (eviction order).
- **Network**: flat — every pod routable IP, all-to-all no NAT; pause container holds ns; **CNI** (Azure CNI=VNet IPs vs kubenet=overlay/NAT); **NetworkPolicy** = default-deny segmentation.
- **Service**: stable ClusterIP; **EndpointSlice** = Ready pods; **kube-proxy** DNATs VIP→pod in kernel; ClusterIP→NodePort→LoadBalancer; **Ingress** = L7. CoreDNS resolves names.
- **Probes**: readiness (traffic gate, no restart) · liveness (restart hung) · startup (protect slow boot). Rolling update needs readiness + maxSurge/maxUnavailable + PDB + SIGTERM drain.
- **Controllers**: Deployment(stateless) · StatefulSet(identity+PVC) · DaemonSet(per-node) · Job/CronJob.

---

> Next deep-mechanics topic (your order): **AKS**.
