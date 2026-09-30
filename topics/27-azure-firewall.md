# 27 · Azure Firewall

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Azure Firewall is a **managed, cloud-native firewall** that sits (usually in the hub) and controls/inspects traffic in and out of your networks — with rules by IP, port, and even website names (FQDN).

## 2. Architect-Level Explanation
A stateful, highly-available, managed network firewall (L3–L7):
- **Rule types**: **NAT rules** (inbound DNAT), **Network rules** (L3/L4 by IP/port/tag), **Application rules** (L7 by FQDN/FQDN tags).
- **Features**: threat intelligence (deny known-bad IPs/domains), IDPS (Premium), TLS inspection (Premium), DNS proxy, forced tunneling.
- **SKUs**: Basic (SMB), Standard, **Premium** (IDPS, TLS inspection, URL filtering).
- **Placement**: hub VNet; spokes route egress via **UDR** (next hop = firewall) for central inspection + logging.
- **Firewall Policy**: central, hierarchical policy across firewalls; managed with Firewall Manager.
- Complements NSGs (micro-segmentation) — Firewall does centralized L7 egress/ingress control.

## 3. Real Enterprise Use Case
A regulated enterprise routes all spoke egress through Azure Firewall Premium in the hub: Application rules allow only approved FQDNs (e.g., `*.microsoft.com`, package repos), IDPS inspects traffic, TLS inspection detects threats, and all logs flow to Sentinel for compliance.

## 4. Architecture Diagram (ASCII)
```
 Spoke workloads ─UDR(0.0.0.0/0→fw)─► [ Azure Firewall (hub) ]
                                        ├ NAT rules (inbound DNAT)
                                        ├ Network rules (L3/4)
                                        ├ App rules (FQDN, L7)
                                        ├ Threat Intel / IDPS (Premium)
                                        └ DNS proxy
                                            │
                                     Internet / On-prem
              Logs ─► Log Analytics / Sentinel
```

## 5. Interview Questions
1. Azure Firewall vs NSG?
2. Network rules vs Application rules vs NAT rules?
3. What does Premium add?
4. How do you force spoke traffic through the firewall?
5. How does Firewall Policy help at scale?

## 6. Strong Interview Answers
- **vs NSG**: "NSG is free, stateful L3/L4 filtering for micro-segmentation on subnets/NICs. Azure Firewall is a managed L3–L7 appliance with FQDN filtering, threat intel, IDPS, NAT, and centralized logging — used for central egress/ingress inspection. They're complementary, not either/or."
- **Rule types**: "NAT rules DNAT inbound public traffic to internal; Network rules filter by IP/port/protocol/tags (L3/4); Application rules filter outbound by FQDN/URL (L7). Application rules are how I whitelist allowed destinations."
- **Premium**: "IDPS (signature-based intrusion detection/prevention), TLS inspection (decrypt+inspect HTTPS), URL filtering, and web categories — needed for regulated/high-security egress."
- **Force traffic**: "UDR on spoke subnets sets 0.0.0.0/0 next hop to the firewall's private IP; DNS proxy so FQDN rules resolve consistently."
- **Firewall Policy**: "Hierarchical policies (parent/child) managed centrally in Firewall Manager, applied across multiple firewalls/regions — consistent rules at scale."

## 7. Common Mistakes
- Using Firewall for micro-segmentation (that's NSGs).
- No UDR → traffic bypasses the firewall.
- Missing DNS proxy → FQDN rules inconsistent.
- Under-provisioning (SNAT port exhaustion) at scale.
- Basic SKU for enterprise needing IDPS/TLS.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Azure Firewall | managed L7, central, HA | cost |
| NVA (3rd party) | feature-rich | self-managed |
| NSG only | free | no L7/FQDN/central |
| Premium | IDPS/TLS | higher cost |

## 9. Production Best Practices
- Hub placement + UDR-forced inspection.
- Firewall Policy (hierarchical) as code.
- Enable DNS proxy for FQDN filtering.
- Threat intel in Alert+Deny mode; IDPS for regulated.
- Log to Log Analytics/Sentinel; monitor SNAT usage.
- Zone-redundant deployment.

## 10. Security Considerations
- FQDN allow-listing for egress (deny-by-default).
- IDPS + TLS inspection (Premium) for deep inspection.
- Threat intelligence deny mode.
- Central logging for audit/compliance.

## 11. Cost Optimization
- Right-size SKU (Basic/Standard/Premium) to needs.
- Consolidate to one hub firewall (shared across spokes).
- Watch data-processing + deployment hours; auto-scale handles throughput.
- Consider Virtual WAN secured hubs at scale.

## 12. Troubleshooting Scenarios
- **Egress blocked** → missing Application/Network allow rule or FQDN.
- **Traffic bypasses fw** → UDR next-hop misconfig.
- **FQDN rules flaky** → enable DNS proxy; point spokes to firewall DNS.
- **Intermittent failures at scale** → SNAT port exhaustion → add public IPs.

## 13. Hands-on Example
```bash
az network firewall create -n hub-fw -g rg-net --vnet-name hub-vnet \
  --sku AZFW_VNet --tier Premium
```

## 14. Terraform Example
```hcl
resource "azurerm_firewall_policy" "policy" {
  name = "hub-fw-policy" resource_group_name = azurerm_resource_group.net.name
  location = "eastus" sku = "Premium"
  dns { proxy_enabled = true }
  threat_intelligence_mode = "Alert"
}
resource "azurerm_firewall" "fw" {
  name = "hub-fw" resource_group_name = azurerm_resource_group.net.name
  location = "eastus" sku_name = "AZFW_VNet" sku_tier = "Premium"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  zones = ["1","2","3"]
  ip_configuration {
    name = "cfg" subnet_id = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}
```

## 15. Azure Example
```bash
az network firewall policy rule-collection-group collection add-filter-collection \
  -g rg-net --policy-name hub-fw-policy --name app-rules \
  --collection-priority 200 --action Allow --rule-name allow-ms \
  --rule-type ApplicationRule --target-fqdns "*.microsoft.com" \
  --source-addresses "10.0.0.0/8" --protocols Https=443
```

## 16. FastAPI / Python Example
```python
# Report allowed egress FQDNs from firewall policy for compliance
from azure.mgmt.network import NetworkManagementClient
@app.get("/egress-fqdns")
def egress_fqdns():
    nc = NetworkManagementClient(cred, SUB)
    # iterate policy rule collection groups -> application rules -> fqdns
    return extract_fqdns(nc, "rg-net", "hub-fw-policy")
```

## 17. AKS Example
AKS egress forced through Azure Firewall via UDR; Application rules whitelist required AKS FQDNs (`mcr.microsoft.com`, `*.hcp.<region>.azmk8s.io`, `login.microsoftonline.com`, package repos); logs to Sentinel.

## 18. How to Remember
**"Managed L7 gatekeeper in the hub."** NAT (in), Network (L3/4), Application (FQDN/L7) rules — plus threat intel/IDPS.

## 19. Real-World Analogy
A corporate security checkpoint that not only checks IDs and floor numbers (IP/port) but also which websites/destinations (FQDN) you're allowed to visit, and scans for known threats.

## 20. One-Page Cheat Sheet
- **What**: managed HA stateful firewall (L3–L7) in the hub.
- **Rules**: NAT (inbound DNAT), Network (L3/4), Application (FQDN/L7).
- **Premium**: IDPS, TLS inspection, URL filtering, web categories.
- **Route**: UDR forces spoke egress → firewall; enable DNS proxy for FQDN rules.
- **Govern**: Firewall Policy (hierarchical) + Firewall Manager as code.
- **vs NSG**: central L7 egress/inspection vs free L3/4 micro-segmentation (use both).
- **Watch**: SNAT port exhaustion at scale (add public IPs).
