# DEEP MECHANICS · AKS (Azure Kubernetes Service)

> Level 2 — the AKS-specific internals: managed control plane, node pools,
> the autoscaling stack (HPA/Cluster Autoscaler/KEDA) and how they interact,
> Azure CNI networking, Workload Identity, upgrades, and real debugging.

---

## 0. The precise mental model
AKS = **Azure-managed Kubernetes control plane** (free, you don't run/patch it) + **your node pools** (VMSS you pay for) + **deep Azure integration** (VNet/CNI, Entra Workload Identity, Key Vault CSI, Azure Monitor, Azure Policy). Your job is node-pool design, the scaling stack, private networking, keyless identity, and safe upgrades.

---

## 1. Managed control plane — what Azure runs vs what you run

- **Azure runs**: API server, etcd, scheduler, controller-manager — HA, patched, backed up by Microsoft. Free tier (or paid **Uptime SLA** tier for a financially-backed 99.95%).
- **You run**: **node pools** (Azure **VMSS** under the hood), the kubelet/runtime on them, and all workloads. You pay for the node VMs + disks + networking, not the control plane.
- **Private cluster**: the API server gets a **private endpoint** (no public IP) → kubectl access only from within the VNet / via jumpbox / private link. Combine with private endpoints on data services for a fully private plane.

---

## 2. Node pools — the design primitive

- **System node pool** — runs cluster-critical pods (CoreDNS, metrics-server); keep it separate and stable.
- **User node pools** — your workloads. Multiple pools let you mix VM types.
- **Pool patterns:**
  - **GPU pool** (tainted) for AI inference — only GPU-tolerating pods land there.
  - **Spot pool** (tainted, evictable, deeply discounted) for fault-tolerant/batch — pods must tolerate `kubernetes.azure.com/scalesetpriority=spot` and handle eviction.
  - **Memory/compute-optimized** pools for different workload shapes.
- **Taints + node selectors/affinity** steer pods to the right pool. **Availability Zones**: spread node pools across zones + pod topology-spread for zone-level HA.

**Deep follow-up: "How do you run cheap batch + reliable serving in one cluster?"**
Two user pools: a **spot** pool (tainted) for batch with tolerations + graceful eviction handling, and an **on-demand** pool for serving; use affinity/anti-affinity + PodDisruptionBudgets so serving never lands on spot.

---

## 3. The autoscaling stack — three layers that must cooperate

This is the most-drilled AKS topic. **Three independent autoscalers at different levels:**

| Autoscaler | Scales | Trigger | Level |
|---|---|---|---|
| **HPA** | pod **replicas** | CPU/mem/custom metrics | workload |
| **KEDA** | pod replicas (incl. **0**) | **event source** (queue depth, etc.) | workload |
| **Cluster Autoscaler** | **nodes** (VMSS) | **unschedulable (Pending) pods** | infra |

**How they chain (the key interaction):**
1. Load rises → **HPA/KEDA** add pod replicas.
2. New pods can't be scheduled (no node capacity) → they go **Pending**.
3. **Cluster Autoscaler** sees Pending pods → adds nodes to the VMSS.
4. Pods schedule; when load drops, HPA removes pods, then CA removes **underutilized** nodes (pods reschedule elsewhere).

**Critical dependencies:**
- HPA needs **metrics-server** (resource metrics) or KEDA/Prometheus adapter (custom).
- HPA **requires resource `requests`** set (it scales on % of request).
- CA scales up only on **Pending** pods → if requests are too *low*, pods pack onto nodes and CA never triggers (real CPU starves). If requests are too *high*, CA over-provisions nodes. **Right-sizing requests is what makes the whole stack work.**

**KEDA's superpower: scale-to-zero.** Event-driven workloads (Service Bus consumers) drop to **0 pods** when the queue is empty → cost savings HPA can't give (HPA min is ≥1).

**Deep follow-up: "HPA added pods but they're Pending forever — why?"**
Cluster Autoscaler isn't adding nodes: either CA is disabled on that pool, the pool hit **max node count**, the pod requests exceed any node size, or a taint/affinity makes it unschedulable on scalable pools. Check CA status/events.

---

## 4. Azure CNI networking (AKS specifics)

- **Azure CNI**: every pod gets a **real VNet IP** from the subnet → pods are first-class VNet citizens (NSGs apply, reachable from peered networks, can use **private endpoints** natively). Cost: **IP planning** — you must size the subnet for `nodes × max-pods-per-node`; exhaustion blocks scaling.
- **Azure CNI Overlay** (modern default for scale): pods get IPs from a **separate overlay CIDR**, not the VNet → conserves VNet IPs while keeping performance; node gets the VNet IP.
- **kubenet** (legacy): pods on an overlay, NAT'd through the node; fewer IPs but no direct pod addressing, extra hop, weaker feature support.
- **NetworkPolicy** (Azure NPM / Calico / Cilium) enforces pod-level segmentation.
- **Ingress**: **AGIC** (Application Gateway Ingress Controller) gives WAF + Azure-native L7; or NGINX for flexibility.

**Deep follow-up: "You're running out of pod IPs — what happened and fixes?"**
Azure CNI (non-overlay) consumes a VNet IP per pod; the subnet was undersized for `nodes × maxPods`. Fixes: bigger subnet, lower `maxPods`, or migrate to **CNI Overlay** to decouple pod IPs from the VNet.

---

## 5. Identity — the keyless chain (Workload Identity)

**The modern mechanism (replaces the deprecated pod-managed identity):**
1. A **Kubernetes ServiceAccount** is annotated with an Entra **client ID**.
2. **Federated credential**: AKS's OIDC issuer is trusted by the Entra app/user-assigned identity.
3. A pod using that ServiceAccount gets a **projected OIDC token**; the Azure SDK exchanges it for an **Entra access token** — **no secret stored anywhere**.
4. RBAC on the target resource (e.g., AOAI `Cognitive Services OpenAI User`) authorizes the token.

**Key Vault CSI driver**: mounts secrets/certs as files in the pod, authenticated via **Workload Identity** — secrets never live in K8s Secrets or env vars.

**Deep follow-up: "Pod gets 403 to Key Vault/AOAI with Workload Identity — debug."** → ServiceAccount annotation (client ID) correct? Federated credential subject matches `system:serviceaccount:ns:sa`? Role assignment present at the right scope? OIDC issuer enabled on the cluster? Pod actually using that ServiceAccount?

---

## 6. Upgrades — how AKS does them safely

- **Two parts**: control-plane upgrade (Azure-managed) then **node pool** upgrade. Keep within version skew rules.
- **Node surge upgrade**: `maxSurge` adds *new* nodes on the new version, **cordons** (no new pods) and **drains** (evicts respecting **PodDisruptionBudgets** + graceful termination) old nodes, then removes them → rolling, minimal disruption.
- **PDBs** ensure a minimum replicas stay up during drain; **SIGTERM/preStop** lets pods finish in-flight work.
- **Blue-green node pools** for risky changes: stand up a new pool, shift workloads, delete the old.
- **Best practice**: test in non-prod, upgrade control plane first, then nodes; automate with maintenance windows.

---

## 7. Cost mechanics (AKS-specific)
- **Control plane free** (or paid Uptime SLA); you pay **nodes (VMSS) + disks + LB + egress**.
- **Spot node pools** = up to ~90% off for evictable batch.
- **Cluster Autoscaler + KEDA scale-to-zero** = don't pay for idle capacity.
- **Right-size requests** = better bin-packing = fewer nodes (the biggest lever).
- **Reserved Instances/Savings Plans** on steady baseline nodes; **Start/Stop** dev clusters.

---

## 8. Observability (AKS-specific)
- **Container Insights** (Azure Monitor) — node/pod metrics, logs to Log Analytics (KQL).
- **Managed Prometheus + Managed Grafana** — cluster metrics at scale.
- **App-level**: OpenTelemetry → Application Insights (traces/correlation).
- **Alert on**: pod restarts/OOMKills, node NotReady, CA max-node hit, PVC full, HPA at max, 429s from AOAI.

---

## 9. The hard follow-up questions (with answers)
1. **"Walk the full autoscaling chain from a traffic spike to new nodes."** → HPA/KEDA add replicas → pods Pending → Cluster Autoscaler adds VMSS nodes → schedule; scale-down reverses (HPA then CA drains underutilized). (§3)
2. **"HPA scaled but pods stuck Pending — why?"** → CA not adding nodes: disabled, at max, requests exceed node size, or taint/affinity. (§3)
3. **"Design cheap batch + reliable serving in one cluster."** → spot (tainted) pool + on-demand pool, tolerations/affinity, PDBs, eviction handling. (§2)
4. **"Ran out of pod IPs — root cause and fix."** → Azure CNI VNet-IP-per-pod, subnet undersized; use CNI Overlay / bigger subnet / lower maxPods. (§4)
5. **"Give a pod access to Azure OpenAI with no secrets."** → **Workload Identity**: annotated ServiceAccount + federated credential on a user-assigned identity + OIDC issuer + role assignment. (§5)
6. **"Upgrade a prod cluster with zero downtime."** → surge upgrade with maxSurge, cordon+drain honoring PDBs + graceful termination; or blue-green node pools; control plane first. (§6)
7. **"Why is scale-to-zero KEDA not HPA?"** → HPA min replicas ≥ 1; KEDA is event-driven and can idle to 0 (e.g., empty queue). (§3)
8. **"Control plane costs?"** → free (or paid Uptime SLA); you pay nodes/disks/LB/egress. (§7)

---

## 10. One-screen deep-recall sheet
- **AKS** = managed control plane (free/Uptime-SLA, Azure runs API/etcd/scheduler) + **your VMSS node pools** (you pay) + Azure integration.
- **Node pools**: system (critical) vs user; **GPU/spot pools tainted**; steer with taints + affinity; spread across **zones** for HA.
- **Autoscaling stack (must cooperate)**: **HPA** (replicas on metrics) + **KEDA** (event-driven, **scale-to-zero**) create Pending pods → **Cluster Autoscaler** adds **nodes**. Needs metrics-server + **requests set**; right-sizing requests makes it all work.
- **Networking**: **Azure CNI** = pod gets **VNet IP** (NSG/private-endpoint friendly, but plan subnet for nodes×maxPods); **CNI Overlay** conserves IPs; kubenet legacy. NetworkPolicy for segmentation; AGIC/NGINX ingress.
- **Identity**: **Workload Identity** = annotated ServiceAccount + federated OIDC credential + user-assigned identity + RBAC → **no secrets**; Key Vault CSI mounts secrets via same.
- **Upgrades**: surge (add new-version nodes) → cordon + drain honoring **PDB** + SIGTERM; or blue-green pools; control plane first.
- **Cost**: control plane free; pay nodes/disks/LB/egress; **spot** + **scale-to-zero** + **right-sized requests** + reserved.
- **Observe**: Container Insights + Managed Prometheus/Grafana + OTel→App Insights; alert on OOM/NotReady/CA-max/429.
- **403 debug**: ServiceAccount annotation, federated subject, role/scope, OIDC issuer.

---

> ✅ Option A batch (RAG · Azure OpenAI · Azure Architecture · Kubernetes · AKS) complete.
> Remaining high-ROI targets: Vector DBs/AI Search, Agentic AI, Semantic Kernel,
> Terraform state, FastAPI/async, Microservices, Event-driven, System Design,
> Managed Identity/Entra, Observability/OTel, Cost/FinOps. Say "continue" for the next batch.
