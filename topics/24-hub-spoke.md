# 24 · Hub-Spoke Architecture

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Hub-spoke is a network layout where a **central hub VNet** holds shared services (firewall, gateways, DNS) and **spoke VNets** hold workloads, connected to the hub by peering. Shared services are centralized; workloads are isolated.

## 2. Architect-Level Explanation
A hub-and-spoke topology using **VNet peering**:
- **Hub**: shared connectivity + security — Azure Firewall, VPN/ExpressRoute gateway, DNS, Bastion, shared services.
- **Spokes**: isolated workload VNets peered to the hub; no spoke-to-spoke peering (traffic transits the hub via **UDRs** forcing next-hop = firewall).
- **Routing**: User-Defined Routes send spoke egress/inter-spoke traffic through the hub firewall (inspection).
- **Scale evolution**: **Azure Virtual WAN** for large/global hub-spoke (managed hubs, any-to-any).
- Benefits: centralized security/inspection, cost sharing, isolation, and governance.

## 3. Real Enterprise Use Case
A bank: hub with Azure Firewall + ExpressRoute to on-prem + private DNS. Each app team gets a spoke peered to the hub; UDRs force all egress and inter-spoke traffic through the firewall for inspection and logging — central control, isolated blast radius.

## 4. Architecture Diagram (ASCII)
```
        On-prem ──ExpressRoute/VPN──► [ HUB VNet ]
                                        ├ Azure Firewall
                                        ├ Gateway
                                        ├ DNS / Bastion
                        ┌──peering──────┼──────peering──┐
                   [ Spoke A ]     [ Spoke B ]     [ Spoke C ]
                    workload        workload        workload
     UDR: spoke traffic → next hop = Firewall (inspection)
     No direct spoke↔spoke; all via hub
```

## 5. Interview Questions
1. Why hub-spoke over a flat/mesh network?
2. How does spoke-to-spoke traffic work?
3. VNet peering vs VPN gateway connection?
4. When do you use Azure Virtual WAN?
5. How do you force traffic through the firewall?

## 6. Strong Interview Answers
- **Why hub-spoke**: "Centralizes shared services (firewall, gateways, DNS) and security inspection, isolates workloads into spokes (blast radius), shares cost, and scales governance. A full mesh doesn't scale and duplicates security."
- **Spoke-to-spoke**: "Peering isn't transitive, so I route spoke-to-spoke through the hub with UDRs (next hop = Azure Firewall) for inspection — direct spoke peering is avoided for control."
- **Peering vs VPN**: "VNet peering is private Azure-backbone connectivity (low latency, high throughput, non-transitive); VPN gateway is encrypted tunnels over the internet to on-prem/other networks. Different purposes."
- **Virtual WAN**: "For many hubs/global scale, vWAN provides Microsoft-managed hubs with any-to-any transit, simplifying large hub-spoke — I move to it when self-managed hubs become operationally heavy."
- **Force firewall**: "UDRs on spoke subnets set 0.0.0.0/0 next hop to the firewall's private IP; disable gateway route propagation as needed."

## 7. Common Mistakes
- Expecting transitive peering (spoke-to-spoke direct).
- Overlapping VNet address spaces.
- No UDRs → traffic bypasses firewall.
- Putting workloads in the hub.
- One giant spoke instead of isolation.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Hub-spoke | central security, isolation | routing complexity |
| Flat VNet | simple | poor isolation/scale |
| Virtual WAN | managed, global | cost, less low-level control |

## 9. Production Best Practices
- Non-overlapping, planned IP address spaces.
- UDRs to force inspection; NSGs per subnet.
- Central DNS (private zones) in hub.
- Separate subscriptions/spokes per workload.
- Move to Virtual WAN at scale.

## 10. Security Considerations
- Azure Firewall in hub for egress/inter-spoke inspection.
- NSGs + ASGs micro-segmentation in spokes.
- Private Endpoints for PaaS; no public egress from spokes.
- DDoS Protection on hub.

## 11. Cost Optimization
- Share expensive resources (firewall, ER gateway) via hub.
- Watch peering + firewall data-processing costs.
- Virtual WAN vs self-managed cost comparison at scale.

## 12. Troubleshooting Scenarios
- **Spoke-to-spoke fails** → missing UDR/hub routing, peering settings.
- **On-prem unreachable** → gateway transit / route propagation.
- **Traffic bypasses firewall** → UDR next hop misconfig.
- **Name resolution fails** → private DNS zone links.

## 13. Hands-on Example
```bash
az network vnet peering create -g rg-net -n hub-to-spokeA \
  --vnet-name hub-vnet --remote-vnet spokeA-vnet \
  --allow-vnet-access --allow-forwarded-traffic
```

## 14. Terraform Example
```hcl
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spokeA"
  resource_group_name       = azurerm_resource_group.net.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spokeA.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_route" "spoke_default" {
  name                   = "to-firewall"
  route_table_name       = azurerm_route_table.spokeA.name
  resource_group_name    = azurerm_resource_group.net.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}
```

## 15. Azure Example
```bash
az network firewall create -n hub-fw -g rg-net --vnet-name hub-vnet
# add UDR on each spoke subnet: 0.0.0.0/0 -> firewall private IP
```

## 16. FastAPI / Python Example
```python
# Verify spoke egress routes through the hub firewall
from azure.mgmt.network import NetworkManagementClient
@app.get("/routes/{rt}")
def routes(rt: str):
    nc = NetworkManagementClient(cred, SUB)
    return [{"prefix": r.address_prefix, "next_hop": r.next_hop_type}
            for r in nc.routes.list("rg-net", rt)]
```

## 17. AKS Example
AKS clusters live in spokes with Azure CNI Overlay; egress forced through the hub firewall via UDR (whitelist required FQDNs like MCR, AAD, AKS); private API server; ACR via Private Endpoint.

## 18. How to Remember
**"Airport hub with spoke routes."** All flights (traffic) route through the central hub for control and connections.

## 19. Real-World Analogy
A corporate campus with one central security building (hub) — every department building (spoke) routes visitors and outbound mail through central security; departments don't have private back-door hallways to each other.

## 20. One-Page Cheat Sheet
- **What**: central hub (shared security/connectivity) + isolated spoke workloads via peering.
- **Routing**: peering is non-transitive → UDRs force spoke/inter-spoke traffic through hub firewall.
- **Hub holds**: Firewall, VPN/ER gateway, DNS, Bastion.
- **Secure**: NSGs/ASGs, Private Endpoints, no public spoke egress, DDoS.
- **Scale**: Azure Virtual WAN for global/many hubs.
- **Plan**: non-overlapping IP spaces.
