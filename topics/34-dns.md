# 34 · DNS Architecture

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
DNS turns names (like `app.contoso.com`) into IP addresses. In Azure, DNS architecture is how you resolve public and private names for your resources reliably and securely.

## 2. Architect-Level Explanation
Azure DNS building blocks:
- **Public DNS zones**: host your public domain records in Azure.
- **Private DNS zones**: internal name resolution within/across VNets (via **virtual network links**); essential for **Private Endpoints** (`privatelink.*`).
- **Azure-provided DNS** (168.63.129.16): default recursive resolver for VNets.
- **Azure DNS Private Resolver**: managed inbound/outbound endpoints for **hybrid** DNS (on-prem ↔ Azure conditional forwarding) — replaces custom DNS-forwarder VMs.
- **Design**: centralize private zones (hub), link spokes, and use conditional forwarding for on-prem interop.

## 3. Real Enterprise Use Case
An enterprise centralizes all `privatelink.*` private DNS zones in the hub, linked to every spoke. On-prem DNS conditionally forwards those zones to the **Azure DNS Private Resolver** inbound endpoint, so on-prem clients resolve Azure Private Endpoints correctly over ExpressRoute.

## 4. Architecture Diagram (ASCII)
```
 Spoke VNets ──link──► [ Private DNS Zones (hub) ]
   resolve privatelink.blob.core.windows.net → private IP
        │
 [ Azure DNS Private Resolver ]
   ├ inbound endpoint  ◄─ on-prem conditional forward
   └ outbound endpoint ─► on-prem DNS (for on-prem names)
 Public: Azure Public DNS zone hosts contoso.com records
 Default resolver: 168.63.129.16
```

## 5. Interview Questions
1. Public vs Private DNS zones?
2. Why is private DNS critical for Private Endpoints?
3. What is the Azure DNS Private Resolver?
4. How do you design hybrid DNS (on-prem ↔ Azure)?
5. What is 168.63.129.16?

## 6. Strong Interview Answers
- **Public vs private**: "Public zones host internet-facing records for your domain; private zones provide internal resolution within linked VNets — not reachable from the internet."
- **Private DNS + PE**: "Private Endpoints keep the resource's public FQDN, so I need a `privatelink.*` private zone linked to the VNet to resolve that FQDN to the private IP. Without it, clients get the public IP — the top PE failure."
- **Private Resolver**: "A managed DNS resolver with inbound endpoints (on-prem→Azure resolution) and outbound endpoints + forwarding rulesets (Azure→on-prem). It replaces self-managed DNS-forwarder VMs — HA, no patching."
- **Hybrid design**: "Centralize private zones in the hub, link spokes, deploy the Private Resolver; on-prem conditionally forwards Azure private zones to the inbound endpoint, and Azure forwards on-prem domains via outbound rulesets."
- **168.63.129.16**: "Azure's virtual public IP for platform services including DNS resolution and health probes — the default VNet resolver."

## 7. Common Mistakes
- Private zone not linked to the VNet that needs it.
- Duplicating private zones per spoke instead of centralizing.
- Using custom forwarder VMs instead of Private Resolver.
- Missing conditional forwarding → on-prem resolves public IPs.
- Overlapping/mismatched zone names for Private Link.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Private Resolver | managed, HA | cost vs DIY VM |
| DNS forwarder VMs | flexible | self-managed, patching, HA effort |
| Central private zones | consistent | hub dependency |

## 9. Production Best Practices
- Centralize `privatelink.*` zones in hub; link all spokes.
- Use Azure DNS Private Resolver for hybrid.
- Automate PE DNS records (private DNS zone groups).
- Document conditional forwarding rules.
- Monitor resolution + query metrics.

## 10. Security Considerations
- Private zones not internet-exposed.
- Restrict who can modify DNS (RBAC).
- Prevent DNS exfiltration (egress control, resolver policies).
- Audit zone changes.

## 11. Cost Optimization
- Private Resolver vs multiple forwarder VMs (often cheaper + HA).
- Consolidate zones; avoid per-spoke duplication.
- Watch query volume pricing at scale.

## 12. Troubleshooting Scenarios
- **PE resolves public IP** → zone not linked / record missing.
- **On-prem can't resolve Azure private names** → conditional forwarding to resolver.
- **Azure can't resolve on-prem** → outbound endpoint / forwarding ruleset.
- **Intermittent** → custom DNS server settings on VNet.

## 13. Hands-on Example
```bash
az network private-dns zone create -g rg-net -n privatelink.blob.core.windows.net
az network private-dns link vnet create -g rg-net -n spoke-link \
  --zone-name privatelink.blob.core.windows.net --virtual-network spokeA \
  --registration-enabled false
```

## 14. Terraform Example
```hcl
resource "azurerm_private_dns_resolver" "resolver" {
  name                = "hub-resolver"
  resource_group_name = azurerm_resource_group.net.name
  location            = "eastus"
  virtual_network_id  = azurerm_virtual_network.hub.id
}
resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound" {
  name                    = "inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = "eastus"
  ip_configurations { subnet_id = azurerm_subnet.dns_inbound.id }
}
```

## 15. Azure Example
```bash
az dns-resolver inbound-endpoint create -g rg-net \
  --dns-resolver-name hub-resolver -n inbound \
  --ip-configurations '[{"subnet":{"id":"<subnet-id>"}}]' -l eastus
```

## 16. FastAPI / Python Example
```python
import socket
@app.get("/dns-check/{fqdn}")
def dns_check(fqdn: str):
    try:
        ip = socket.gethostbyname(fqdn)
        return {"fqdn": fqdn, "ip": ip, "private": ip.startswith(("10.","172.","192.168."))}
    except socket.gaierror:
        return {"fqdn": fqdn, "error": "resolution failed"}
```

## 17. AKS Example
AKS uses CoreDNS internally for cluster names; for Azure private resources it forwards to Azure DNS (168.63.129.16) which resolves linked private zones. Custom stub domains in CoreDNS handle on-prem names via the Private Resolver.

## 18. How to Remember
**"Private zones + links + resolver."** Private Endpoints need private zones; hybrid needs the Private Resolver for conditional forwarding.

## 19. Real-World Analogy
A company phone directory: the public directory (public DNS) lists external numbers, the internal directory (private DNS) lists extensions, and a switchboard (Private Resolver) connects internal and external calls both ways.

## 20. One-Page Cheat Sheet
- **Public zones**: internet-facing records; **Private zones**: internal resolution via VNet links.
- **Private Endpoints require** `privatelink.*` private zones linked to the VNet.
- **Azure DNS Private Resolver**: managed hybrid DNS (inbound + outbound endpoints), replaces forwarder VMs.
- **Design**: centralize private zones in hub, link spokes, conditional forwarding on-prem.
- **168.63.129.16**: Azure default VNet DNS resolver.
- **Top PE failure**: DNS misconfiguration.
