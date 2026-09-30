# 53 · AKS Networking

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
AKS networking decides how Pods, Services, and external users communicate — how Pods get IP addresses, how they reach each other, and how traffic enters and leaves the cluster.

## 2. Architect-Level Explanation
Networking model choices define IP allocation, scale, and integration:
- **CNI plugins**:
  - **Azure CNI Overlay** (recommended): Pods get IPs from a private overlay CIDR (not the VNet) → massive scale, no VNet IP exhaustion.
  - **Azure CNI (node subnet)**: Pods get real VNet IPs → direct VNet routing but IP-hungry.
  - **Kubenet** (legacy): basic, UDR-based, being deprecated.
  - **Cilium (eBPF)** as dataplane for CNI Overlay → high-performance network policy + observability.
- **Service networking**: ClusterIP (internal), LoadBalancer (Azure LB), Ingress/AGIC/App Gateway for L7.
- **Egress**: via Load Balancer, NAT Gateway, or **UDR → Azure Firewall** (FQDN allow-listing).
- **DNS**: CoreDNS in-cluster; private DNS zones for private cluster/endpoints.
- **Network policy**: Cilium/Calico for micro-segmentation (default-deny).

## 3. Real Enterprise Use Case
A large enterprise runs **Azure CNI Overlay + Cilium**: thousands of Pods without VNet IP exhaustion, default-deny network policies, egress forced through Azure Firewall for FQDN filtering, internal ingress via App Gateway (AGIC), and Private Endpoints for ACR/Key Vault/SQL.

## 4. Architecture Diagram (ASCII)
```
   Users ─► App Gateway (AGIC, L7/WAF) ─► Ingress ─► Service(ClusterIP)
                                                        │
   Pods (overlay CIDR 10.244/16) ── Cilium eBPF policy ─┘
        │ egress via UDR
   Azure Firewall (FQDN allow-list) ─► Internet
   Private Endpoints ─► ACR / Key Vault / SQL (no public)
   CoreDNS (in-cluster) + Private DNS zones
```

## 5. Interview Questions
1. Azure CNI Overlay vs node-subnet CNI vs Kubenet?
2. How do you avoid VNet IP exhaustion at scale?
3. How do you control egress traffic?
4. How do network policies work in AKS?
5. How does DNS resolution work in AKS?

## 6. Strong Interview Answers
- **CNI choice**: "Azure CNI Overlay is my default — Pods use a private overlay CIDR so you don't burn VNet IPs, giving huge scale; node-subnet CNI gives Pods real VNet IPs (direct routing but IP-hungry); Kubenet is legacy/deprecated. Add Cilium as the dataplane for eBPF policy and performance."
- **IP exhaustion**: "Overlay decouples Pod IPs from the VNet, so I size the node subnet for nodes only and use the overlay CIDR for Pods — thousands of Pods without VNet pressure."
- **Egress**: "Force egress via UDR to Azure Firewall for FQDN filtering and logging, or NAT Gateway for scalable SNAT. This gives controlled, auditable outbound traffic."
- **Network policy**: "Cilium or Calico enforce Pod-level rules — I default-deny and explicitly allow required flows for zero-trust east-west segmentation."
- **DNS**: "CoreDNS resolves in-cluster service names; for private clusters/endpoints I integrate Azure Private DNS zones so `*.privatelink` resolves correctly."

## 7. Common Mistakes
- Node-subnet CNI at scale → VNet IP exhaustion.
- Using deprecated Kubenet for new clusters.
- No network policies (flat, open pod network).
- Uncontrolled egress (no Firewall/UDR).
- Overlapping CIDRs with peered VNets.

## 8. Trade-offs
| Model | Pro | Con |
|-------|-----|-----|
| CNI Overlay | scale, IP-efficient | Pods not directly VNet-routable |
| CNI node-subnet | direct VNet routing | IP-hungry |
| Kubenet | simple | legacy/deprecated |

## 9. Production Best Practices
- Azure CNI Overlay + Cilium dataplane.
- Plan non-overlapping CIDRs (node/pod/service).
- Default-deny network policies.
- Egress via Firewall/NAT Gateway with UDR.
- Private Endpoints for PaaS; Private DNS integration.

## 10. Security Considerations
- Micro-segmentation (default-deny) with Cilium/Calico.
- FQDN egress filtering via Firewall.
- Private cluster + Private Endpoints (no public exposure).
- WAF at App Gateway/Front Door for ingress.

## 11. Cost Optimization
- Overlay avoids large reserved VNet ranges.
- NAT Gateway can reduce SNAT port exhaustion vs LB egress.
- Consolidate egress through shared Firewall (hub).

## 12. Troubleshooting Scenarios
- **Pods can't be scheduled (no IPs)** → node-subnet exhaustion; move to overlay.
- **Egress blocked** → missing Firewall FQDN rule / UDR misroute.
- **DNS failures** → CoreDNS issues / missing Private DNS zone link.
- **Policy blocks traffic** → default-deny with no allow rule.
- **SNAT exhaustion** → add NAT Gateway.

## 13. Hands-on Example
```bash
kubectl get svc -A
kubectl exec -it <pod> -- nslookup kubernetes.default
kubectl exec -it <pod> -- curl -s https://api.internal.svc
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  # ...
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"     # Azure CNI Overlay
    network_policy      = "cilium"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    outbound_type       = "userDefinedRouting"  # egress via Firewall
  }
}
```

## 15. Azure Example
```bash
az aks create -g rg-aks -n prod-aks \
  --network-plugin azure --network-plugin-mode overlay \
  --network-policy cilium --pod-cidr 10.244.0.0/16 \
  --outbound-type userDefinedRouting
```

## 16. FastAPI / Python Example
```python
# Service-to-service call uses in-cluster DNS (CoreDNS)
import httpx
INVENTORY = "http://inventory.app.svc.cluster.local"
@app.get("/stock/{sku}")
async def stock(sku: str):
    async with httpx.AsyncClient() as c:
        r = await c.get(f"{INVENTORY}/stock/{sku}")
    return r.json()
```

## 17. AKS Example (default-deny NetworkPolicy)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny, namespace: app }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-api-to-db, namespace: app }
spec:
  podSelector: { matchLabels: { app: db } }
  ingress:
    - from: [{ podSelector: { matchLabels: { app: api } } }]
```

## 18. How to Remember
**"Overlay for scale, Cilium for policy, Firewall for egress, Private Endpoints for PaaS."**

## 19. Real-World Analogy
A large office campus: internal phone extensions (overlay Pod IPs) work internally without needing public numbers; security controls which departments can call each other (network policy) and all outside calls route through a monitored switchboard (Azure Firewall egress).

## 20. One-Page Cheat Sheet
- **CNI**: Azure CNI **Overlay** (default, IP-efficient) + **Cilium** eBPF dataplane; node-subnet = direct-routing but IP-hungry; Kubenet = legacy.
- **CIDRs**: separate, non-overlapping node/pod/service ranges.
- **Ingress**: App Gateway (AGIC)/Front Door + WAF.
- **Egress**: UDR → Azure Firewall (FQDN filter) or NAT Gateway.
- **Policy**: default-deny + explicit allows (Cilium/Calico).
- **DNS/PaaS**: CoreDNS + Private DNS zones + Private Endpoints.
