# 30 · ExpressRoute

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
ExpressRoute is a **private, dedicated connection from your on-prem datacenter to Azure** — not over the public internet. It's faster, more reliable, and more secure than a VPN.

## 2. Architect-Level Explanation
Private L3 connectivity via a connectivity provider (no internet transit):
- **Circuit**: the logical connection, with a bandwidth and provider; billed as Metered or Unlimited.
- **Peering types**: **Private peering** (to VNets), **Microsoft peering** (to Microsoft 365/PaaS public services over the private circuit).
- **Redundancy**: dual connections (active/active) by design; add **zone-redundant ER Gateway** and a second circuit in another peering location for HA.
- **Global Reach**: link on-prem sites to each other via Azure backbone.
- **FastPath**: bypass the gateway for lower latency/higher throughput.
- Uses BGP for route exchange; SLA requires redundant configuration.

## 3. Real Enterprise Use Case
A financial firm connects two datacenters to Azure via ExpressRoute circuits (dual, different peering locations) into a hub ER Gateway. Private peering reaches all spoke workloads; Global Reach links the two datacenters through Azure; VPN is configured as a backup path.

## 4. Architecture Diagram (ASCII)
```
 On-prem DC ──► Provider Edge ──ExpressRoute Circuit──► Microsoft Edge
   (dual links, BGP)                                        │
                                              [ ER Gateway (hub VNet) ]
                                                        │ private peering
                                              Spokes / VNet workloads
   Backup: Site-to-Site VPN over internet
   Global Reach: DC-A ↔ DC-B via Azure backbone
```

## 5. Interview Questions
1. ExpressRoute vs VPN?
2. Private peering vs Microsoft peering?
3. How do you make ExpressRoute highly available?
4. What is Global Reach and FastPath?
5. How does routing work (BGP)?

## 6. Strong Interview Answers
- **vs VPN**: "ExpressRoute is a private, dedicated circuit via a provider — consistent low latency, high bandwidth, higher reliability/SLA, and no internet exposure. VPN is encrypted tunnels over the public internet — cheaper and quick to set up but variable. Enterprises use ER primary + VPN backup."
- **Peering types**: "Private peering connects to VNet workloads; Microsoft peering reaches Microsoft public services (M365, PaaS public endpoints) over the private circuit. Most VNet traffic uses private peering."
- **HA**: "ER is dual-link by design; for the SLA I add a zone-redundant gateway, and ideally a second circuit in a different peering location, plus VPN as failover. Test failover."
- **Global Reach/FastPath**: "Global Reach connects on-prem sites to each other through Azure's backbone; FastPath bypasses the gateway so data-plane traffic goes edge-to-VNet directly for lower latency."
- **Routing**: "BGP exchanges routes between on-prem and Azure; I control advertised prefixes and use route filters (esp. for Microsoft peering)."

## 7. Common Mistakes
- Single circuit/gateway (no real HA).
- Assuming ER is encrypted (it's private, not encrypted — add IPsec if required).
- Overlapping on-prem/Azure address spaces.
- No VPN backup path.
- Ignoring gateway SKU throughput limits.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| ExpressRoute | reliable, fast, private, SLA | cost, lead time, provider dependency |
| VPN | cheap, fast to deploy | internet-variable, lower throughput |
| ER + VPN backup | resilient | higher cost/complexity |

## 9. Production Best Practices
- Dual circuits in different peering locations for HA.
- Zone-redundant ER Gateway; correct SKU for throughput.
- VPN as failover; test failover regularly.
- BGP route control + route filters.
- Monitor circuit metrics; encrypt sensitive traffic if needed.

## 10. Security Considerations
- ER is private but not encrypted — add MACsec (at edge) or IPsec over ER for sensitive data.
- Route filtering on Microsoft peering.
- NSGs/Firewall still apply in the hub.

## 11. Cost Optimization
- Choose Metered vs Unlimited by egress volume.
- Right-size bandwidth + gateway SKU.
- Global Reach only where site-to-site is needed.

## 12. Troubleshooting Scenarios
- **No connectivity** → BGP session down, provisioning state, provider issue.
- **Asymmetric routing** → advertised prefixes / route tables.
- **Low throughput** → gateway SKU limit; consider FastPath.
- **Failover didn't work** → VPN backup / route priorities untested.

## 13. Hands-on Example
```bash
az network express-route create -g rg-net -n er-circuit \
  --bandwidth 1000 --provider "Equinix" --peering-location "Silicon Valley" \
  --sku-family MeteredData --sku-tier Standard
```

## 14. Terraform Example
```hcl
resource "azurerm_express_route_circuit" "er" {
  name                  = "er-circuit"
  resource_group_name   = azurerm_resource_group.net.name
  location              = "eastus"
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 1000
  sku { tier = "Standard" family = "MeteredData" }
}
```

## 15. Azure Example
```bash
az network vpn-connection create -g rg-net -n er-conn \
  --vnet-gateway1 er-gateway --express-route-circuit2 er-circuit
```

## 16. FastAPI / Python Example
```python
from azure.mgmt.network import NetworkManagementClient
@app.get("/er/status")
def er_status():
    nc = NetworkManagementClient(cred, SUB)
    c = nc.express_route_circuits.get("rg-net", "er-circuit")
    return {"state": c.circuit_provisioning_state,
            "service_state": c.service_provider_provisioning_state}
```

## 17. AKS Example
On-prem clients reach private AKS workloads (internal LB / private ingress) over ExpressRoute private peering through the hub gateway; AKS egress to on-prem systems (DBs) also traverses ER.

## 18. How to Remember
**"A private leased highway to Azure."** No internet traffic; dual lanes for HA; VPN as the backup road.

## 19. Real-World Analogy
A dedicated private rail line between your factory and Azure's warehouse — reliable and high-capacity, unlike shipping via public roads (VPN/internet). You run two tracks so one failing doesn't stop deliveries.

## 20. One-Page Cheat Sheet
- **What**: private, dedicated on-prem↔Azure connectivity via a provider (no internet).
- **Peering**: private (VNets) + Microsoft (M365/PaaS public).
- **HA**: dual circuits (diff locations) + zone-redundant gateway + VPN backup.
- **Extras**: Global Reach (site-to-site via Azure), FastPath (bypass gateway).
- **Security**: private ≠ encrypted → add MACsec/IPsec for sensitive data.
- **Routing**: BGP + route filters; avoid overlapping address spaces.
