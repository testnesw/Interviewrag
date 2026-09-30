# 26 · NSG (Network Security Groups)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
An NSG is a **firewall of rules** you attach to a subnet or NIC to allow/deny traffic based on source/destination IP, port, and protocol — basic network access control.

## 2. Architect-Level Explanation
A stateful L3/L4 packet filter:
- **Rules**: priority-ordered (100–4096, lower wins), 5-tuple (src/dst IP, src/dst port, protocol) + allow/deny + direction.
- **Stateful**: return traffic auto-allowed.
- **Scope**: subnet-level (broad) and/or NIC-level (granular); both evaluated.
- **Service Tags**: symbolic groups (e.g., `Storage`, `AzureLoadBalancer`, `Internet`) instead of IP ranges.
- **ASGs (Application Security Groups)**: group NICs by role (web/app/db) and write rules against groups, not IPs.
- **Default rules**: allow VNet-in/out and Azure LB, deny all inbound from internet — you layer on top.
- Not a replacement for Azure Firewall (L7, FQDN, threat intel).

## 3. Real Enterprise Use Case
A 3-tier app uses ASGs (web/app/db). NSG rules: internet→web:443 allow, web→app:8080 allow, app→db:1433 allow, everything else deny. Rules reference ASGs so scaling instances needs no rule changes.

## 4. Architecture Diagram (ASCII)
```
 Internet ─►(443)─► [ASG: web] ─►(8080)─► [ASG: app] ─►(1433)─► [ASG: db]
                       ▲ NSG           ▲ NSG            ▲ NSG
 Rules (priority):
  100 Allow Internet→web:443
  200 Allow web→app:8080
  300 Allow app→db:1433
  4096 Deny all (implicit)
 Stateful: replies auto-allowed
```

## 5. Interview Questions
1. How are NSG rules evaluated?
2. Subnet-level vs NIC-level NSG?
3. What are Service Tags and ASGs?
4. NSG vs Azure Firewall?
5. Why is NSG "stateful"?

## 6. Strong Interview Answers
- **Evaluation**: "Rules are processed by priority (lowest number first); the first match wins and stops evaluation. Default rules allow intra-VNet and deny inbound internet — I add higher-priority (lower-number) rules to override."
- **Subnet vs NIC**: "Both apply if present — inbound: subnet NSG then NIC NSG; outbound: NIC then subnet. Subnet for broad policy, NIC for exceptions. I mostly use subnet-level for manageability."
- **Service Tags/ASGs**: "Service Tags are Microsoft-maintained IP groups (e.g., `Sql`, `Storage`) so I don't hardcode IPs; ASGs group my VMs by role so rules reference roles, not IPs — cleaner and scale-friendly."
- **NSG vs Firewall**: "NSG is free, stateful L3/L4 filtering per subnet/NIC; Azure Firewall is a managed L3–L7 appliance with FQDN filtering, threat intel, NAT, and central logging. Use NSGs for micro-segmentation, Firewall for centralized egress/inspection — together."
- **Stateful**: "If you allow an inbound flow, the return traffic is automatically permitted — you don't need a matching reverse rule."

## 7. Common Mistakes
- Rule priority conflicts (broad allow before specific deny).
- Hardcoding IPs instead of Service Tags/ASGs.
- Assuming NSG does L7/FQDN (it doesn't).
- Forgetting both subnet + NIC NSGs apply.
- Over-permissive `Any-Any` allow rules.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Subnet NSG | manageable, broad | less granular |
| NIC NSG | granular | harder to manage at scale |
| ASGs | scale-friendly | extra concept |
| NSG only | free, simple | no L7/FQDN |

## 9. Production Best Practices
- Deny-by-default; least-privilege allows.
- Use ASGs + Service Tags over raw IPs.
- Prefer subnet-level for consistency.
- Enable **NSG flow logs** → Log Analytics/Traffic Analytics.
- Manage as code; review rule sprawl.

## 10. Security Considerations
- Micro-segment tiers (web/app/db).
- No broad internet inbound; combine with Firewall for egress.
- Flow logs for audit + anomaly detection.
- Regular rule review (remove stale allows).

## 11. Cost Optimization
- NSGs are free; flow logs incur storage/analytics cost — tier/retain sensibly.
- Reduce complexity to cut ops cost.

## 12. Troubleshooting Scenarios
- **Traffic blocked** → check effective security rules / priority order.
- **Unexpected allow** → a broad rule with lower priority number.
- **Can't localize** → NSG flow logs + Network Watcher IP flow verify.
- **Return traffic issue** → usually not NSG (stateful) — check asymmetric routing.

## 13. Hands-on Example
```bash
az network nsg rule create -g rg-net --nsg-name app-nsg -n allow-web \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --destination-port-ranges 443 --source-address-prefixes Internet
```

## 14. Terraform Example
```hcl
resource "azurerm_network_security_group" "app" {
  name                = "app-nsg"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.net.name
  security_rule {
    name = "allow-web" priority = 100 direction = "Inbound"
    access = "Allow" protocol = "Tcp" source_port_range = "*"
    destination_port_range = "443" source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }
}
```

## 15. Azure Example
```bash
az network watcher flow-log create -g rg-net -n app-flowlog \
  --nsg app-nsg --storage-account <sa-id> --enabled true \
  --traffic-analytics true --workspace <la-id>
```

## 16. FastAPI / Python Example
```python
from azure.mgmt.network import NetworkManagementClient
@app.get("/nsg/{name}/rules")
def rules(name: str):
    nc = NetworkManagementClient(cred, SUB)
    nsg = nc.network_security_groups.get("rg-net", name)
    return sorted([{"name": r.name, "priority": r.priority,
        "access": r.access} for r in nsg.security_rules],
        key=lambda x: x["priority"])
```

## 17. AKS Example
AKS-managed NSG on the node subnet; avoid manually breaking required rules. Use **Kubernetes Network Policies** (Cilium/Calico) for pod-level segmentation — NSG handles subnet-level, NetworkPolicy handles pod-level.

## 18. How to Remember
**"Priority list of allow/deny by IP+port, first match wins, stateful."** Subnet + NIC both apply.

## 19. Real-World Analogy
A building's door-access rules: a prioritized list of who can enter which floor via which door — and once you're let in, you're allowed back out the same way (stateful).

## 20. One-Page Cheat Sheet
- **What**: stateful L3/L4 allow/deny rules on subnet/NIC.
- **Eval**: priority order (low number wins), first match, stateful.
- **Simplify**: Service Tags (Azure IPs) + ASGs (role groups) over raw IPs.
- **Scope**: subnet (broad) + NIC (granular) both apply.
- **vs Firewall**: NSG = free L3/L4 segmentation; Firewall = L7/FQDN/central egress.
- **Ops**: deny-by-default, flow logs, manage as code.
