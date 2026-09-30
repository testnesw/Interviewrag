# Deep Dive · AKS (Azure Kubernetes Service)

> Phase 2 (Platform & apps) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
AKS is Azure's **managed Kubernetes** service: Microsoft runs the **control plane** (API server, etcd, scheduler) for free, and you own the **worker nodes** (VM node pools) where your pods run. It gives you Kubernetes' orchestration — self-healing, autoscaling, rolling deployments, service discovery — without operating the hard control-plane bits. In GenAI/enterprise architecture, AKS is the **compute platform** for stateless APIs (FastAPI/.NET orchestrators, agents), integrated with **Entra ID, Managed Identity (Workload Identity), Private clusters, Azure CNI, and Azure Monitor**.

---

## 2. Architect-Level Explanation
AKS = **managed control plane + your node pools + Azure integrations**:
- **Control plane (Microsoft-managed)**: API server, etcd, scheduler, controller-manager — SLA-backed, patched by Azure.
- **Node pools (yours)**: **system** pool (CoreDNS, metrics) + **user** pools (workloads), optionally **spot** and **GPU** pools.
- **Networking**: **Azure CNI** (pods get VNet IPs — enterprise standard) vs **kubenet** (NAT'd, IP-thrifty) vs **Cilium/overlay**.
- **Identity**: **Workload Identity** (federate a pod's K8s service account to an Entra app → passwordless access to Azure resources).
- **Scaling**: **HPA** (pods), **Cluster Autoscaler / node autoprovision** (nodes), **KEDA** (event-driven).
- **Add-ons**: ingress (AGIC/NGINX), Azure Monitor/Container Insights, Key Vault CSI, Policy (Gatekeeper).

Architecturally you treat AKS as a **secure, autoscaling, multi-tenant compute fabric** and push cross-cutting concerns (identity, network, policy, observability) into the platform.

---

## 3. Why It Exists
- **Problem**: raw Kubernetes is powerful but operating the control plane (etcd HA, upgrades, certs, security) is hard and undifferentiated.
- **Why AKS**: Azure runs/patches the control plane (free), integrates Entra/RBAC/networking/monitoring, and gives enterprise features (private clusters, policy) — you focus on workloads.
- **Why not App Service/Container Apps?**: choose AKS when you need **fine-grained control, portability, complex microservices, service mesh, GPUs, or multi-cloud**. For simple apps, PaaS (Container Apps/App Service) is less overhead.
- **Enterprise driver**: standardize a portable, policy-governed platform for many teams with consistent security and cost control.

---

## 4. Internal Working
**Request → workload flow:**
1. `kubectl`/CI applies YAML to the **API server** (authenticated via **Entra ID**).
2. Desired state stored in **etcd**; **controllers** reconcile actual → desired.
3. **Scheduler** places pods on nodes by resources/affinity/taints.
4. **kubelet** on each node pulls images (from **ACR**) and runs containers via containerd.
5. **kube-proxy / CNI** wires networking; **Services** provide stable virtual IPs; **CoreDNS** resolves names.
6. **HPA** watches metrics → scales pod replicas; **Cluster Autoscaler** adds/removes nodes when pods can't schedule.
7. **Ingress controller** terminates TLS and routes external traffic to services.
8. **Workload Identity**: pod's service-account token is federated to Entra → gets Azure tokens with no secrets.

Key properties: **declarative** (desired state), **self-healing** (reconcile loops), **eventually consistent**, **API-driven**.

---

## 5. Enterprise Use Case
A pharma builds a **GenAI orchestrator platform** on a **private AKS cluster**: FastAPI agent/RAG services run in a user node pool; a GPU pool hosts an internal embedding model. **Workload Identity** grants passwordless access to Azure OpenAI and Key Vault; **Azure CNI + private endpoints** keep all traffic on the VNet; **AGIC** fronts traffic behind Front Door/WAF; **HPA + KEDA** scale on request and queue depth; **Container Insights + OpenTelemetry** provide observability. Multiple product teams share the cluster via **namespaces + RBAC + resource quotas + network policies**.

---

## 6. Real Production Architecture
```
 Users ─► Front Door (WAF) ─► [Private AKS Ingress: AGIC/App Gateway]
                                     │
   ┌─────────────────────── AKS (private, Azure CNI) ───────────────────────┐
   │ namespace: genai                                                        │
   │   Deploy: fastapi-orchestrator (HPA)  ── Workload Identity ─► AOAI (PE) │
   │   Deploy: agent-runtime (KEDA on queue)          └────────► Key Vault   │
   │   GPU pool: embedding-model                                             │
   │ system pool: CoreDNS, metrics, ingress                                  │
   │ Policy (Gatekeeper) · NetworkPolicies · ResourceQuotas · RBAC           │
   └────────────────────────────────────────────────────────────────────────┘
         │ pulls images                    │ telemetry
         ▼                                 ▼
   Azure Container Registry (PE)     Azure Monitor / Container Insights + Log Analytics
```

---

## 7. Security Best Practices
- **Private cluster** (API server not public) + **authorized IP ranges** if public.
- **Entra ID integration + Kubernetes RBAC** (Azure RBAC for Kubernetes) — no local admin certs.
- **Workload Identity** (not pod-managed-identity/secrets) for Azure access; **no keys in pods**.
- **Azure CNI + NetworkPolicies** (Cilium/Calico) — default-deny east-west, segment namespaces.
- **Key Vault CSI driver** for secrets; never bake secrets into images/env.
- **Azure Policy / Gatekeeper**: enforce no-privileged, allowed registries (ACR only), required labels, non-root.
- **Image security**: scan in ACR (Defender for Containers), signed images, minimal base images.
- **Defender for Containers** for runtime threat detection; upgrade nodes/K8s regularly (patch).

---

## 8. Scaling Strategy
- **HPA** on CPU/memory or custom/OTel metrics; **KEDA** for event/queue-driven (Service Bus depth).
- **Cluster Autoscaler** or **Node Autoprovisioning (Karpenter-style)** to add/remove nodes.
- **Multiple node pools**: system vs user vs **spot** (batch, cost) vs **GPU** (inference).
- **Pod requests/limits** set correctly → scheduler + autoscaler behave; **PodDisruptionBudgets** protect availability during scaling.
- **Overprovisioning (pause pods)** for fast burst; **topology spread** across zones.

---

## 9. High Availability Strategy
- **Availability Zones**: spread node pools across 3 AZs; **uptime SLA** tier for the control plane.
- **Multiple replicas** + **PodAntiAffinity** + **topologySpreadConstraints**.
- **PodDisruptionBudgets** to keep minimum replicas during upgrades/drains.
- **Readiness/liveness probes**; **rolling updates** with surge control.
- **Multi-region** (active-active or active-passive) fronted by Front Door for regional failover.

---

## 10. Disaster Recovery Strategy
- **GitOps (Flux/ArgoCD)** = cluster state in Git → rebuild a cluster fast (cattle, not pets).
- **IaC (Terraform)** for cluster + node pools + add-ons → redeploy in secondary region.
- **Stateful data lives outside the cluster** (managed DBs, geo-replicated) — clusters stay stateless.
- **ACR geo-replication** for images; **Velero** for namespace/PV backup if needed.
- **Define RTO/RPO**; run **failover drills**; Front Door repoints traffic.

---

## 11. Cost Optimization Strategy
- **Right-size requests/limits** (biggest waste is over-requesting) — use VPA recommendations.
- **Spot node pools** for fault-tolerant/batch; **Cluster Autoscaler** scale-to-min; **scale-to-zero** user pools off-hours.
- **Reserved Instances / savings plans** for steady baseline; **bin-pack** with proper scheduling.
- **Right node SKUs** (GPU only where needed); **KEDA scale-to-zero** for event workloads.
- **Cost visibility**: OpenCost/Container Insights cost analysis, namespace chargeback, FinOps tags.

---

## 12. Common Production Challenges
- **IP exhaustion** with Azure CNI (each pod = a VNet IP) → plan subnet sizing / use overlay.
- **Node pressure / OOMKills** from missing limits → set requests/limits, monitor.
- **Upgrade pain** (K8s deprecations) → stay N-2, test in non-prod, use PDBs.
- **DNS/CoreDNS bottlenecks** at scale → NodeLocal DNSCache.
- **Noisy neighbors** in multi-tenant → quotas, limits, network policies.
- **Image pull throttling / cold starts** → ACR proximity, cache, smaller images.
- **Secret sprawl** → Key Vault CSI + Workload Identity.

---

## 13. Monitoring and Observability
- **Container Insights** (Azure Monitor) + **Managed Prometheus + Managed Grafana** for metrics.
- **App traces via OpenTelemetry** → App Insights; **logs → Log Analytics**.
- **Golden signals**: latency, traffic, errors, saturation per service; node/pod resource dashboards.
- **Alerts**: pod restarts/crashloops, HPA maxed, node not-ready, PVC full, cost anomalies.
- **kube-state-metrics** for cluster health; SLO dashboards per workload.

---

## 14. Troubleshooting Scenarios
- **Pod Pending** → insufficient resources/taints/PV binding; check `kubectl describe`, autoscaler.
- **CrashLoopBackOff** → app error/bad config/missing secret; check logs + probes.
- **ImagePullBackOff** → ACR auth/Workload Identity/registry policy; verify pull perms.
- **503 via ingress** → readiness failing or no endpoints; check service selectors + probes.
- **Intermittent latency** → CPU throttling (limits too low), DNS, node pressure; check metrics.
- **Can't reach Azure OpenAI** → Workload Identity federation / private DNS / NSG; verify token + DNS resolution.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| AKS vs Container Apps | control, portability, mesh, GPU | more ops overhead |
| Azure CNI vs kubenet | pod = VNet IP, direct policy | IP consumption |
| Spot nodes | big cost savings | can be evicted |
| Private cluster | secure | needs jumpbox/CI in-VNet |
| Service mesh | mTLS, traffic control | complexity/latency |

---

## 16. When NOT to use it
- **Simple stateless web app / API** → Container Apps or App Service (far less overhead).
- **Event-driven functions** → Azure Functions.
- **Tiny team without platform/ops capacity** → PaaS; AKS needs Day-2 ownership.
- **Single container, low scale** → don't pay the Kubernetes complexity tax.
- **Purely batch** → Batch/ACI may be simpler/cheaper.

---

## 17. Comparison with Alternatives
| Option | Control | Ops burden | Best for |
|--------|---------|-----------|----------|
| **AKS** | high | medium-high | complex microservices, mesh, GPU, portability |
| Container Apps | medium | low | scalable containers/microservices w/o K8s |
| App Service | low | very low | web apps/APIs |
| Azure Functions | low | very low | event-driven/serverless |
| ACI | low | low | burst/batch single containers |

---

## 18. Interview Questions
1. What does AKS manage vs what do you own?
2. Azure CNI vs kubenet — trade-offs?
3. How does Workload Identity work and why is it preferred?
4. HPA vs Cluster Autoscaler vs KEDA?
5. How do you secure a production AKS cluster?
6. AKS vs Container Apps vs App Service — when each?
7. How do you design AKS for HA across zones/regions?
8. How do you do DR for AKS?
9. How do you cut AKS cost?
10. How do you handle multi-tenancy on one cluster?

---

## 19. Strong Interview Answers
- **Managed vs owned**: "Azure runs the control plane — API server, etcd, scheduler — with an SLA; I own node pools, workloads, networking choices, and security posture. I don't patch etcd; I do right-size nodes and enforce policy."
- **Workload Identity**: "It federates a pod's Kubernetes service account to an Entra app registration, so pods get Azure AD tokens with no stored secrets — passwordless access to AOAI/Key Vault. It replaces the deprecated pod-managed-identity and is the enterprise standard."
- **Scaling trio**: "HPA scales pods on metrics, Cluster Autoscaler scales nodes when pods can't schedule, KEDA scales on external events like queue depth — including to zero. I use all three: KEDA for event workloads, HPA for request-driven, CA underneath for capacity."
- **Security**: "Private cluster, Entra + Azure RBAC, Workload Identity, Azure CNI with default-deny NetworkPolicies, Key Vault CSI, Gatekeeper policies (non-root, ACR-only), and Defender for Containers. No keys in pods, ever."
- **AKS vs PaaS**: "If it's a simple API, Container Apps. I reach for AKS when I need mesh, GPUs, complex networking, portability, or fine-grained control — and I have the ops maturity to run Day-2."

---

## 20. Architecture Diagrams
**Control plane vs data plane:**
```
[Microsoft-managed]  API server · etcd · scheduler · controllers   (SLA)
        ▲ kubectl/CI (Entra auth)
[Yours]  System pool (CoreDNS/metrics/ingress)
         User pools (apps, HPA)  Spot pool (batch)  GPU pool (inference)
```
**Scaling stack:**
```
Event/queue ─► KEDA ─┐
Metrics ─► HPA ───────┼─► more pods ─► (no room?) ─► Cluster Autoscaler ─► more nodes
```

---

## 21. Real Project Example
**Multi-team GenAI platform.** One private AKS cluster, per-team namespaces with quotas + RBAC + NetworkPolicies. GenAI orchestrators (FastAPI) autoscale via HPA; an ingestion pipeline scales via KEDA on Service Bus depth; a GPU pool serves embeddings. GitOps (ArgoCD) deploys from Git; Workload Identity gives passwordless AOAI/Key Vault access; Front Door + AGIC handle ingress; Container Insights + Managed Prometheus/Grafana provide observability; spot pools cut batch cost ~60%. DR = Terraform + ArgoCD rebuild in a second region, data in geo-replicated managed stores.

---

## 22. Whiteboard Design Question
> *"Design a secure, multi-region AKS platform to host GenAI APIs for 100k users."*

Cover: Front Door(WAF) → regional private AKS (AZ-spread) → AGIC ingress → FastAPI (HPA) + agent (KEDA) + GPU pool → Workload Identity to AOAI/Key Vault (PE) → Azure CNI + default-deny policies → ACR geo-replicated → GitOps + Terraform → Container Insights/Prometheus → HA (AZ + multi-replica + PDB) + DR (rebuild + data geo-replication) → cost (spot, right-size, RIs). Call out IP planning, upgrade strategy, multi-tenancy.

---

## 23. Design Review Questions
- **CNI choice** and subnet/IP sizing?
- **Private cluster**? How do CI/CD and operators reach the API server?
- **Workload Identity** for all Azure access? Any secrets left?
- **NetworkPolicies** default-deny? Namespace isolation?
- **Autoscaling**: HPA/KEDA/CA configured with correct requests/limits + PDBs?
- **Upgrade strategy** and version support (N-2)?
- **DR**: GitOps + IaC rebuild target RTO/RPO?
- **Cost**: spot/right-size/RIs and chargeback?

---

## 24. Hands-on Example
```bash
# Create a private, Entra-integrated AKS cluster with Workload Identity + Azure CNI
az aks create -g rg -n genai-aks \
  --network-plugin azure --enable-private-cluster \
  --enable-aad --enable-azure-rbac \
  --enable-oidc-issuer --enable-workload-identity \
  --node-count 3 --zones 1 2 3 \
  --attach-acr myacr --enable-addons monitoring
# Add a spot user pool for batch + a GPU pool for inference
az aks nodepool add -g rg --cluster-name genai-aks -n spot \
  --priority Spot --eviction-policy Delete --node-count 0 --min-count 0 --max-count 10 --enable-cluster-autoscaler
```

---

## 25. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "genai-aks"
  location            = var.location
  resource_group_name = var.rg
  dns_prefix          = "genai"
  private_cluster_enabled = true
  oidc_issuer_enabled     = true
  workload_identity_enabled = true

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    zones               = [1, 2, 3]
    only_critical_addons_enabled = true
  }
  network_profile { network_plugin = "azure"  network_policy = "cilium" }
  identity { type = "SystemAssigned" }
  azure_active_directory_role_based_access_control { azure_rbac_enabled = true }
  oms_agent { log_analytics_workspace_id = var.law_id }
}

resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_NC6s_v3"
  node_count            = 0
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 4
  node_taints           = ["sku=gpu:NoSchedule"]
}
```

---

## 26. Azure Example
```bash
# Federate a Kubernetes service account to an Entra identity (Workload Identity)
az identity create -g rg -n genai-wi
az identity federated-credential create -g rg --identity-name genai-wi \
  --name genai-fed --issuer $(az aks show -g rg -n genai-aks --query oidcIssuerProfile.issuerUrl -o tsv) \
  --subject system:serviceaccount:genai:orchestrator-sa
# Grant it least-privilege access to Azure OpenAI
az role assignment create --assignee $(az identity show -g rg -n genai-wi --query principalId -o tsv) \
  --role "Cognitive Services OpenAI User" --scope $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv)
```

---

## 27. Code Example
```yaml
# Deployment using Workload Identity (no secrets) + probes + resource limits
apiVersion: apps/v1
kind: Deployment
metadata: { name: orchestrator, namespace: genai }
spec:
  replicas: 3
  selector: { matchLabels: { app: orchestrator } }
  template:
    metadata:
      labels: { app: orchestrator, azure.workload.identity/use: "true" }
    spec:
      serviceAccountName: orchestrator-sa          # federated to Entra
      containers:
      - name: app
        image: myacr.azurecr.io/orchestrator:1.0.0
        resources:
          requests: { cpu: "250m", memory: "512Mi" }
          limits:   { cpu: "1",    memory: "1Gi" }   # prevent OOM/noisy neighbor
        readinessProbe: { httpGet: { path: /health, port: 8000 }, initialDelaySeconds: 5 }
        livenessProbe:  { httpGet: { path: /health, port: 8000 }, initialDelaySeconds: 15 }
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: orchestrator-hpa, namespace: genai }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: orchestrator }
  minReplicas: 3
  maxReplicas: 30
  metrics:
  - type: Resource
    resource: { name: cpu, target: { type: Utilization, averageUtilization: 65 } }
```

---

## 28. Things Architects Must Remember
- **AKS = managed control plane + your nodes** — you own Day-2 (security, upgrades, cost).
- **Workload Identity, not secrets** — passwordless Azure access is non-negotiable.
- **Right-size requests/limits** — the root of both reliability (OOM) and cost.
- **Default-deny NetworkPolicies** + private cluster + Entra RBAC = baseline security.
- **HPA + KEDA + Cluster Autoscaler** are complementary, not alternatives.
- **Clusters are cattle** — GitOps + IaC make them rebuildable (that's your DR).
- **Plan IPs** early with Azure CNI; upgrades need PDBs and N-2 discipline.
- **Reach for PaaS first**; use AKS when control/portability/GPU/mesh justify the overhead.

---

## 29. Mnemonics and Memory Tricks
- **"You bring the nodes, Azure brings the brain."** (nodes = yours, control plane = managed)
- **Scaling "H-K-C"**: **H**PA (pods) · **K**EDA (events) · **C**luster Autoscaler (nodes).
- **Security "P-E-W-N-K"**: **P**rivate cluster, **E**ntra RBAC, **W**orkload Identity, **N**etworkPolicy, **K**ey Vault CSI.
- **"Cattle not pets"** — GitOps + IaC = rebuildable clusters = your DR.
- **Cost "R-S-R"**: **R**ight-size, **S**pot, **R**eserved Instances.

---

## 30. One-Page Interview Revision Sheet
- **What**: managed Kubernetes — Azure runs control plane (free, SLA), you own node pools + workloads.
- **Networking**: Azure CNI (pod=VNet IP) vs kubenet vs overlay/Cilium; NetworkPolicies for east-west.
- **Identity**: Workload Identity (federated SA → Entra, passwordless); Entra + Azure RBAC.
- **Scale**: HPA (pods) · KEDA (events, scale-to-zero) · Cluster Autoscaler/NAP (nodes); requests/limits + PDBs.
- **Security**: private cluster, Key Vault CSI, Gatekeeper policies, Defender for Containers, ACR-only signed images.
- **HA**: AZ spread, replicas + anti-affinity + PDB, probes, rolling updates; multi-region via Front Door.
- **DR**: GitOps + Terraform rebuild; data outside cluster (geo-replicated); ACR geo-replication.
- **Cost**: right-size, spot pools, scale-to-zero, RIs, chargeback.
- **When NOT**: simple apps → Container Apps/App Service/Functions.
- **Remember**: *you bring nodes, Azure brings the brain*; **H-K-C** scaling; **cattle not pets**; Workload Identity always.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Draw the AKS shared-responsibility line — what's Microsoft's, what's yours?
2. Your cluster ran out of pod IPs in prod. Root cause and prevention?
3. Explain Workload Identity end-to-end and why it beats stored secrets.
4. Design autoscaling for a GenAI API with spiky, queue-driven traffic. Which of HPA/KEDA/CA and why?
5. Harden a public AKS cluster to enterprise standard — list every control.
6. AKS vs Container Apps for a FastAPI orchestrator — make the call and defend it.
7. Design HA across zones AND regions for a stateless GenAI API.
8. Your cluster is your DR concern — how do you rebuild it in 30 minutes in another region?
9. AKS bill doubled — walk through your cost investigation and top three levers.
10. Two teams share a cluster and one is starving the other. How do you enforce fair isolation?

---

> Next Phase 2 topic: **Kubernetes Fundamentals**. Say **continue** (I'm proceeding through Phase 2–5).
