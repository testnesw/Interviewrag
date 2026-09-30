# 38 · AKS Architecture

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
AKS (Azure Kubernetes Service) is **managed Kubernetes**. Azure runs the control plane (the brain) for free; you manage the worker nodes (node pools) where your containers actually run.

## 2. Architect-Level Explanation
- **Control plane**: Azure-managed (API server, etcd, scheduler, controller-manager) — HA, patched, SLA-backed (with Uptime SLA tier).
- **Data plane**: your **node pools** (system + user), VMSS-backed VMs.
- **Networking**: Azure CNI (pods get VNet IPs) vs Kubenet; **Overlay CNI** for IP conservation; Cilium for eBPF dataplane/network policy.
- **Identity**: **Workload Identity** (federated) → pods get Entra tokens, no secrets.
- **Scaling**: HPA (pods), Cluster Autoscaler / **Node Autoprovision (Karpenter-style)**, KEDA (event-driven).
- **Add-ons**: ingress (App Gateway/NGINX), CSI drivers (Key Vault, disks/files), monitoring (Managed Prometheus + Container Insights), policy (Azure Policy/Gatekeeper).

## 3. Real Enterprise Use Case
E-commerce platform runs 200 microservices on AKS: private cluster, Azure CNI Overlay, App Gateway Ingress Controller, Workload Identity to reach Key Vault/SQL, KEDA scaling on Service Bus queue depth for order processing during peak sales.

## 4. Architecture Diagram (ASCII)
```
        Azure-managed Control Plane (API, etcd, scheduler)
                          │ (private API endpoint)
        ┌─────────────────┴──────────────────┐
   System Node Pool                     User Node Pool(s)
   (kube-system)                        (app pods, spot/on-demand)
        │  VMSS                              │  VMSS + Autoscaler
        └── Azure CNI (pod IPs in VNet) ─────┘
   Ingress: App Gateway ─► Services ─► Pods
   Workload Identity ─► Key Vault / SQL / Storage (no secrets)
   Monitoring ─► Managed Prometheus + Container Insights
```

## 5. Interview Questions
1. Azure CNI vs Kubenet vs Overlay — trade-offs?
2. How do pods authenticate to Azure services securely?
3. Cluster Autoscaler vs HPA vs KEDA?
4. How do you design a production-grade, secure AKS cluster?
5. System vs user node pools — why separate?

## 6. Strong Interview Answers
- **CNI**: "Azure CNI gives pods real VNet IPs (great for connectivity/network policy) but consumes IP space; Kubenet conserves IPs via NAT but limits features; **Overlay** gives best of both — VNet integration with a separate pod CIDR, so it scales to large clusters without IP exhaustion. I default to Azure CNI Overlay + Cilium."
- **Pod auth**: "**Workload Identity** — federate a Kubernetes ServiceAccount to a Managed Identity, pods get short-lived Entra tokens, zero stored secrets. Legacy AAD Pod Identity is deprecated."
- **Scaling**: "HPA scales pods on metrics; Cluster Autoscaler adds/removes nodes when pods can't schedule; KEDA scales on external events (queue depth). They compose: KEDA/HPA scale pods, autoscaler provides nodes."
- **Production design**: "Private cluster, separate system/user pools, Azure CNI Overlay, Workload Identity, Key Vault CSI, Azure Policy/Gatekeeper, Managed Prometheus, multiple node pools (on-demand + spot), zone-redundant."

## 7. Common Mistakes
- Running workloads on the system node pool.
- Kubenet on large clusters → scaling/feature limits.
- Storing secrets in manifests instead of Key Vault CSI.
- No resource requests/limits → noisy neighbors, bad scheduling.
- Public API server for regulated workloads.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Azure CNI | full features, pod VNet IP | IP consumption |
| Overlay | IP-efficient + features | extra hop/NAT nuance |
| Spot nodes | big cost savings | can be evicted |
| Private cluster | secure | needs jumpbox/VPN for kubectl |

## 9. Production Best Practices
- Separate system/user node pools; taints/tolerations.
- Availability Zones + PodDisruptionBudgets.
- Requests/limits + LimitRange/ResourceQuota.
- GitOps (Flux/ArgoCD) for cluster config.
- Managed Prometheus + Container Insights + alerts.
- Regular node image + K8s version upgrades (surge upgrades).

## 10. Security Considerations
- Private cluster, authorized IP ranges.
- Workload Identity (no secrets); disable local accounts, use Entra RBAC.
- Azure Policy/Gatekeeper (no privileged pods, allowed registries).
- Network Policies (Cilium/Calico); Defender for Containers.
- Key Vault CSI for secrets; scan images in ACR.

## 11. Cost Optimization
- Spot node pools for fault-tolerant/batch workloads.
- Cluster Autoscaler + scale-to-zero user pools (KEDA).
- Right-size requests; use VPA recommendations.
- Use `Standard` SKU nodes appropriately; reservations/savings plan.
- Stop dev clusters off-hours.

## 12. Troubleshooting Scenarios
- **Pods Pending** → insufficient nodes (autoscaler), taints, PVC binding.
- **CrashLoopBackOff** → `kubectl logs --previous`, probes, config.
- **ImagePullBackOff** → ACR auth / Workload Identity / image tag.
- **DNS failures** → CoreDNS, NSG, private DNS zones.
- **Node NotReady** → kubelet, disk pressure, network plugin.

## 13. Hands-on Example
```bash
kubectl get nodes -o wide
kubectl describe pod <pod>       # events at bottom
kubectl top pods
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "prod-aks"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "prodaks"
  private_cluster_enabled   = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_D4s_v5"
    node_count = 3
    only_critical_addons_enabled = true
    zones      = [1, 2, 3]
  }
  network_profile { network_plugin = "azure" network_plugin_mode = "overlay" }
  identity { type = "SystemAssigned" }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D8s_v5"
  enable_auto_scaling   = true
  min_count = 2
  max_count = 20
  zones     = [1, 2, 3]
}
```

## 15. Azure Example
```bash
az aks create -g rg-aks -n prod-aks --enable-private-cluster \
  --network-plugin azure --network-plugin-mode overlay \
  --enable-oidc-issuer --enable-workload-identity \
  --zones 1 2 3 --node-count 3 --generate-ssh-keys
az aks get-credentials -g rg-aks -n prod-aks
```

## 16. FastAPI / Python Example
```python
# App running in AKS uses Workload Identity — no secrets
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
cred = DefaultAzureCredential()   # picks up federated token in-pod
kv = SecretClient("https://myvault.vault.azure.net", cred)
db_pw = kv.get_secret("db-password").value
```

## 17. AKS Example (Workload Identity manifest)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  annotations:
    azure.workload.identity/client-id: <managed-identity-client-id>
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    metadata:
      labels: { azure.workload.identity/use: "true" }
    spec:
      serviceAccountName: app-sa
      containers:
        - name: api
          image: myacr.azurecr.io/api:1.0
          resources:
            requests: { cpu: "250m", memory: "256Mi" }
            limits:   { cpu: "500m", memory: "512Mi" }
```

## 18. How to Remember
**"Azure runs the brain, you run the muscles."** Control plane = managed brain; node pools = your muscles.

## 19. Real-World Analogy
Renting a fully-staffed kitchen (Azure manages ovens/control), while you just hire cooks (pods) and decide the menu (workloads) — and you can add cooks automatically when orders spike.

## 20. One-Page Cheat Sheet
- **Split**: managed control plane + your node pools (system/user).
- **Network**: Azure CNI Overlay + Cilium (scalable, feature-rich).
- **Identity**: Workload Identity (no secrets).
- **Scale**: HPA (pods) + Autoscaler (nodes) + KEDA (events).
- **Secure**: private cluster, Entra RBAC, Gatekeeper, Key Vault CSI, Defender.
- **Cost**: spot pools, autoscale-to-zero, right-size requests.
- **Debug**: Pending→nodes/taints, CrashLoop→logs/probes, ImagePull→ACR/identity.
