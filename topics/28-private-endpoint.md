# 28 · Private Endpoint

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
A Private Endpoint gives an Azure PaaS service (like Storage or SQL) a **private IP inside your VNet**, so you reach it over your private network instead of the public internet.

## 2. Architect-Level Explanation
- A **network interface with a private IP** in your subnet that maps to a specific PaaS resource (sub-resource/group ID, e.g., `blob`, `sqlServer`).
- Uses **Azure Private Link** under the hood; traffic stays on the Microsoft backbone.
- **DNS is critical**: the public FQDN must resolve to the private IP via a **Private DNS Zone** (e.g., `privatelink.blob.core.windows.net`) linked to the VNet.
- Lets you **disable public access** on the PaaS resource entirely.
- Works cross-VNet/cross-region/cross-tenant; one endpoint per sub-resource.

## 3. Real Enterprise Use Case
A bank disables public access on Storage, SQL, and Key Vault; each gets Private Endpoints in a dedicated `pe-subnet`. Private DNS zones resolve FQDNs to private IPs. On-prem reaches them via ExpressRoute + DNS forwarders — zero public exposure.

## 4. Architecture Diagram (ASCII)
```
 VNet
 └ pe-subnet
     └ [Private Endpoint NIC 10.0.3.4] ──Private Link──► Azure SQL
                    ▲                                   (public access disabled)
   Private DNS Zone: privatelink.database.windows.net
     sql.database.windows.net → CNAME → 10.0.3.4
 On-prem ─ER─► DNS forwarder ─► resolves to private IP
```

## 5. Interview Questions
1. What is a Private Endpoint and how does it work?
2. Why is Private DNS essential for it?
3. Private Endpoint vs Service Endpoint?
4. How do on-prem clients resolve private endpoints?
5. What's a sub-resource (group ID)?

## 6. Strong Interview Answers
- **What/how**: "It's a NIC with a private IP in my subnet mapped to a specific PaaS resource via Private Link. Traffic stays on the Azure backbone and I can disable the resource's public endpoint."
- **DNS**: "The service keeps its public FQDN, so without DNS override clients still resolve public IPs. A Private DNS Zone (`privatelink.*`) linked to the VNet resolves the FQDN to the private IP — misconfigured DNS is the #1 failure."
- **vs Service Endpoint**: "Service Endpoint keeps traffic on the backbone but still targets the resource's *public* IP (restricted by the resource firewall); Private Endpoint gives a *private IP in my VNet* and allows fully disabling public access — stronger isolation."
- **On-prem resolution**: "On-prem DNS conditionally forwards `privatelink` zones to an Azure DNS resolver/forwarder in the VNet so it returns the private IP over ExpressRoute/VPN."
- **Sub-resource**: "A resource can expose multiple targets (Storage: blob/file/table/queue); each needs its own Private Endpoint keyed by the group ID."

## 7. Common Mistakes
- Forgetting/mislinking the Private DNS Zone.
- One endpoint expecting to cover all sub-resources.
- No on-prem DNS forwarding → resolves public IP.
- Leaving public access enabled (defeats the purpose).
- NSG/UDR blocking the PE subnet unexpectedly.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Private Endpoint | true private, disable public | cost/endpoint, DNS mgmt |
| Service Endpoint | free, simple | public IP target, no cross-region |
| Public + firewall | simple | exposed surface |

## 9. Production Best Practices
- Centralize **Private DNS Zones** (often in hub) + VNet links.
- One PE per sub-resource; dedicated PE subnet.
- Disable public network access on the PaaS resource.
- Automate DNS record creation (private DNS zone group).
- On-prem conditional forwarding to Azure DNS.

## 10. Security Considerations
- Disable public access; PE-only.
- NSGs on PE subnet; least privilege.
- Approve PE connections (manual approval for cross-tenant).
- Audit via diagnostic logs.

## 11. Cost Optimization
- PEs cost per hour + data processed — consolidate where sensible.
- Reuse central private DNS zones across VNets.
- Avoid unnecessary PEs for low-sensitivity dev resources.

## 12. Troubleshooting Scenarios
- **Resolves public IP** → missing/unlinked private DNS zone or record.
- **On-prem can't connect** → DNS conditional forwarder missing.
- **Connection blocked** → PE approval state / NSG.
- **Wrong sub-resource** → created PE for wrong group ID.

## 13. Hands-on Example
```bash
az network private-endpoint create -g rg-net -n sql-pe \
  --vnet-name app-vnet --subnet pe-subnet \
  --private-connection-resource-id <sql-id> --group-id sqlServer \
  --connection-name sql-conn
```

## 14. Terraform Example
```hcl
resource "azurerm_private_endpoint" "sql" {
  name                = "sql-pe"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.net.name
  subnet_id           = azurerm_subnet.pe.id
  private_service_connection {
    name = "sql-conn" is_manual_connection = false
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names = ["sqlServer"]
  }
  private_dns_zone_group {
    name = "dns" private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}
```

## 15. Azure Example
```bash
az network private-dns zone create -g rg-net -n privatelink.database.windows.net
az network private-dns link vnet create -g rg-net -n link \
  --zone-name privatelink.database.windows.net --virtual-network app-vnet \
  --registration-enabled false
```

## 16. FastAPI / Python Example
```python
import socket
@app.get("/resolve/{host}")
def resolve(host: str):
    # Verify FQDN resolves to a private (10.x) IP from inside the VNet
    ip = socket.gethostbyname(host)
    return {"host": host, "ip": ip, "private": ip.startswith("10.")}
```

## 17. AKS Example
AKS pods reach ACR, Key Vault, SQL via Private Endpoints; the AKS VNet is linked to the private DNS zones (or uses the hub's). Private cluster also uses a PE for the API server.

## 18. How to Remember
**"PaaS gets a private IP in your VNet — but only if DNS points to it."** No private DNS = no private endpoint working.

## 19. Real-World Analogy
Giving a public company a private internal phone extension in your office — but everyone's contact list (DNS) must be updated to dial the extension instead of the public number.

## 20. One-Page Cheat Sheet
- **What**: NIC with a private IP mapping to a specific PaaS sub-resource via Private Link.
- **DNS**: private DNS zone (`privatelink.*`) linked to VNet is mandatory.
- **vs Service Endpoint**: private IP + disable public vs public IP restricted.
- **On-prem**: conditional DNS forwarding to Azure resolver.
- **One PE per sub-resource** (blob/file/sqlServer...).
- **Secure**: disable public access, NSG on PE subnet, approve connections.
