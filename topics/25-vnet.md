# 25 · Virtual Networks (VNet)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
A Virtual Network (VNet) is your **private network in Azure** — an isolated address space where your resources (VMs, AKS, etc.) get private IPs and talk to each other securely.

## 2. Architect-Level Explanation
- **Address space**: CIDR blocks (RFC 1918) divided into **subnets**; plan to avoid overlap (peering/on-prem).
- **Isolation**: VNets are isolated by default; connect via **peering** (Azure backbone) or VPN/ExpressRoute (to on-prem).
- **Controls**: NSGs (subnet/NIC), UDRs (routing), Service Endpoints & **Private Endpoints** (PaaS access), delegation (subnet dedicated to a service, e.g., AKS/App Service).
- **DNS**: default Azure DNS or custom/private DNS zones.
- **Scale**: address planning, subnet sizing (Azure reserves 5 IPs/subnet), and topology (hub-spoke).

## 3. Real Enterprise Use Case
A company designs a /16 VNet segmented into subnets: app, data, AKS (delegated), private-endpoints, and gateway subnet. NSGs enforce tier isolation, Private Endpoints connect to SQL/Storage privately, and peering links to the hub for on-prem connectivity.

## 4. Architecture Diagram (ASCII)
```
 VNet 10.0.0.0/16
 ├ subnet-app     10.0.1.0/24  [NSG]
 ├ subnet-data    10.0.2.0/24  [NSG]  ─► Private Endpoint ► SQL/Storage
 ├ subnet-aks     10.0.4.0/22  [delegated, NSG]
 ├ GatewaySubnet  10.0.255.0/27       ─► VPN/ER gateway
 └ AzureFirewallSubnet 10.0.254.0/26
   Peering ──► Hub VNet ; UDRs control routing
```

## 5. Interview Questions
1. How do you plan VNet address space and subnets?
2. Service Endpoints vs Private Endpoints?
3. How do VNets communicate with each other/on-prem?
4. Why can't subnets overlap across peered VNets?
5. What special subnets does Azure require?

## 6. Strong Interview Answers
- **Planning**: "Pick non-overlapping RFC 1918 CIDRs accounting for peering, on-prem, and growth; size subnets for the workload (remember Azure reserves 5 IPs/subnet); reserve special subnets (GatewaySubnet, AzureFirewallSubnet)."
- **Service vs Private Endpoint**: "Service Endpoints extend the VNet identity to a PaaS resource but traffic still hits the public endpoint (restricted); Private Endpoints give the PaaS resource a **private IP inside your VNet** (true private connectivity + DNS). I prefer Private Endpoints for security."
- **Connectivity**: "Peering for VNet-to-VNet (backbone, non-transitive); VPN/ExpressRoute gateways for on-prem."
- **No overlap**: "Routing needs unique IP ranges; overlapping CIDRs make peering/routing ambiguous, so it's disallowed."
- **Special subnets**: "GatewaySubnet (VPN/ER gateway), AzureFirewallSubnet, AzureBastionSubnet — named exactly, sized correctly."

## 7. Common Mistakes
- Overlapping address spaces (blocks peering).
- Undersized subnets (esp. AKS with CNI).
- Forgetting Azure's 5 reserved IPs per subnet.
- Using Service Endpoints when Private Endpoints are needed.
- Wrong special-subnet names/sizes.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Private Endpoint | true private + DNS | per-endpoint cost, DNS mgmt |
| Service Endpoint | free, simple | traffic to public IP (restricted) |
| Large subnets | room to grow | IP waste |

## 9. Production Best Practices
- Central IP address management (IPAM) plan.
- NSGs on every subnet; least-privilege rules.
- Private Endpoints + private DNS zones for PaaS.
- Segment by tier; delegate subnets where required.
- Enable NSG flow logs / Network Watcher.

## 10. Security Considerations
- NSGs + ASGs micro-segmentation; deny-by-default.
- Private Endpoints; disable public access on PaaS.
- DDoS Protection; no public IPs on workload NICs.
- Flow logs to Log Analytics for audit.

## 11. Cost Optimization
- Private Endpoints cost per hour + data — consolidate where sensible.
- Avoid oversized gateways; right-size.
- Peering/egress data charges — design traffic paths.

## 12. Troubleshooting Scenarios
- **Can't reach PaaS privately** → private DNS zone link / A record.
- **Peering broken** → overlapping CIDR / peering state.
- **Blocked traffic** → NSG rule priority/order, effective rules.
- **AKS IP exhaustion** → subnet too small / CNI mode.

## 13. Hands-on Example
```bash
az network vnet create -g rg-net -n app-vnet --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-app --subnet-prefix 10.0.1.0/24
```

## 14. Terraform Example
```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "app-vnet"
  resource_group_name = azurerm_resource_group.net.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.net.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

## 15. Azure Example
```bash
az network private-endpoint create -g rg-net -n sql-pe \
  --vnet-name app-vnet --subnet subnet-data \
  --private-connection-resource-id <sql-id> --group-id sqlServer \
  --connection-name sql-conn
```

## 16. FastAPI / Python Example
```python
from azure.mgmt.network import NetworkManagementClient
@app.get("/subnets/{vnet}")
def subnets(vnet: str):
    nc = NetworkManagementClient(cred, SUB)
    return [{"name": s.name, "prefix": s.address_prefix}
            for s in nc.subnets.list("rg-net", vnet)]
```

## 17. AKS Example
Give AKS a properly sized delegated subnet (Azure CNI needs IPs per pod, or use Overlay to conserve); NSG on the subnet; Private Endpoints for ACR/Key Vault/SQL the cluster consumes.

## 18. How to Remember
**"Your own private LAN in the cloud."** CIDR + subnets + NSGs + private links.

## 19. Real-World Analogy
An office building's internal wiring: floors (subnets), locked doors between departments (NSGs), a mailroom to the outside (gateways), and private phone lines to partners (Private Endpoints).

## 20. One-Page Cheat Sheet
- **What**: isolated private network (CIDR) split into subnets.
- **Connect**: peering (VNet-VNet, non-transitive) / VPN-ER (on-prem).
- **PaaS access**: Private Endpoint (private IP + DNS) > Service Endpoint.
- **Controls**: NSGs (segment), UDRs (route), delegation, private DNS.
- **Plan**: non-overlapping CIDRs; Azure reserves 5 IPs/subnet.
- **Special subnets**: GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet.
