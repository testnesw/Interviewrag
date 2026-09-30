# 31 · Load Balancer

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Azure Load Balancer spreads incoming network traffic across multiple servers (VMs) so no single one is overwhelmed. It works at the network level (L4 — TCP/UDP).

## 2. Architect-Level Explanation
A high-performance **L4 (TCP/UDP)** load balancer:
- **SKUs**: **Standard** (zone-redundant, secure-by-default, HA ports, larger backend) vs Basic (legacy, retiring).
- **Types**: **Public** (internet-facing) and **Internal/Private** (within VNet).
- **Components**: frontend IP → load-balancing rules → backend pool → health probes.
- **Distribution**: 5-tuple hash (default) or session persistence; **HA Ports** for NVAs.
- **Outbound**: SNAT via outbound rules (watch port exhaustion) — or use NAT Gateway.
- L4 only — no TLS termination or URL routing (that's App Gateway/Front Door).

## 3. Real Enterprise Use Case
A backend microservice tier runs on a VMSS behind an internal Standard Load Balancer, zone-redundant across 3 AZs, with health probes removing unhealthy instances. An internal frontend IP serves other tiers privately; a NAT Gateway handles outbound.

## 4. Architecture Diagram (ASCII)
```
 Client ─► [Frontend IP] ─► LB rules ─► Backend Pool
                              │            ├ VM/VMSS instance 1 (AZ1)
                       Health Probe ──►    ├ VM/VMSS instance 2 (AZ2)
                    (removes unhealthy)    └ VM/VMSS instance 3 (AZ3)
   L4 (TCP/UDP), 5-tuple hash; Standard SKU = zone-redundant
   Outbound: NAT Gateway (avoid SNAT exhaustion)
```

## 5. Interview Questions
1. Load Balancer vs Application Gateway vs Front Door?
2. Standard vs Basic SKU?
3. Public vs Internal Load Balancer?
4. How do health probes work?
5. What is SNAT port exhaustion and how do you fix it?

## 6. Strong Interview Answers
- **LB vs AppGw vs FD**: "LB is L4 (TCP/UDP), fast, no app-layer smarts. Application Gateway is L7 (HTTP) with WAF, TLS termination, URL/path routing — regional. Front Door is global L7 with CDN/anycast. Pick by layer and scope: LB for L4, AppGw for regional L7, Front Door for global."
- **Standard vs Basic**: "Standard is zone-redundant, secure-by-default (closed unless NSG allows), supports HA ports, larger backends, and has an SLA — the production choice. Basic is legacy and retiring."
- **Public vs Internal**: "Public has an internet-facing frontend IP; Internal has a private VNet IP for internal tiers — same engine, different frontend."
- **Health probes**: "TCP/HTTP/HTTPS probes check backend health; unhealthy instances are removed from rotation, restored when healthy. Essential for reliability."
- **SNAT exhaustion**: "Many outbound connections share limited SNAT ports → failures under load. Fix with a **NAT Gateway** (recommended), more frontend IPs/outbound rules, or connection reuse."

## 7. Common Mistakes
- Using LB for HTTP routing/TLS (use App Gateway).
- Basic SKU in production.
- No health probes / wrong probe path.
- SNAT exhaustion from no NAT Gateway.
- Forgetting NSGs (Standard is deny-by-default).

## 8. Trade-offs
| Layer | Product | Use |
|-------|---------|-----|
| L4 | Load Balancer | TCP/UDP, fast, any protocol |
| L7 regional | App Gateway | HTTP, WAF, path routing |
| L7 global | Front Door | global, CDN, anycast |

## 9. Production Best Practices
- Standard SKU, zone-redundant.
- Proper health probes; tune intervals.
- NAT Gateway for outbound.
- Combine with App Gateway/Front Door for L7.
- IaC + monitoring (metrics/alerts).

## 10. Security Considerations
- NSGs control access (Standard closed by default).
- Internal LB for private tiers; no public exposure.
- DDoS Protection on public frontends.
- Restrict backend to LB/probe source.

## 11. Cost Optimization
- Standard LB pricing by rules + data processed.
- NAT Gateway cost vs SNAT reliability trade-off.
- Consolidate rules; right-size backend.

## 12. Troubleshooting Scenarios
- **Backends unhealthy** → probe path/port, NSG blocking probe (`AzureLoadBalancer` tag).
- **Outbound failures** → SNAT exhaustion → NAT Gateway.
- **No traffic** → NSG deny (Standard), rule/frontend misconfig.
- **Uneven distribution** → session persistence / hash mode.

## 13. Hands-on Example
```bash
az network lb create -g rg-net -n app-lb --sku Standard \
  --frontend-ip-name fe --backend-pool-name bepool
az network lb probe create -g rg-net --lb-name app-lb -n health \
  --protocol Http --port 80 --path /health
```

## 14. Terraform Example
```hcl
resource "azurerm_lb" "app" {
  name                = "app-lb"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.net.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name = "fe" subnet_id = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"   # internal LB
  }
}
resource "azurerm_lb_probe" "health" {
  name = "health" loadbalancer_id = azurerm_lb.app.id
  protocol = "Http" port = 80 request_path = "/health"
}
```

## 15. Azure Example
```bash
az network nat gateway create -g rg-net -n out-nat \
  --public-ip-addresses out-pip --idle-timeout 10
# associate with subnet to fix SNAT exhaustion
```

## 16. FastAPI / Python Example
```python
@app.get("/health")     # LB health probe endpoint
def health():
    return {"status": "ok"}    # return 200 only when ready to serve
```

## 17. AKS Example
An AKS `Service type=LoadBalancer` provisions a Standard Azure LB; use `internal` annotation for private services; AKS outbound uses a managed LB or NAT Gateway (recommended to avoid SNAT exhaustion).

## 18. How to Remember
**"L4 traffic splitter."** TCP/UDP only; use App Gateway/Front Door when you need HTTP smarts.

## 19. Real-World Analogy
A traffic officer at a toll plaza directing cars to the shortest open lane (backend) — they don't care what's inside the cars (L4), just that lanes stay balanced and closed lanes (unhealthy) are skipped.

## 20. One-Page Cheat Sheet
- **What**: L4 (TCP/UDP) load balancer; public or internal.
- **SKU**: Standard (zone-redundant, secure-by-default, SLA) — not Basic.
- **Parts**: frontend IP → rules → backend pool → health probes.
- **Outbound**: use NAT Gateway to avoid SNAT port exhaustion.
- **Not for**: TLS/HTTP routing → App Gateway (regional L7) / Front Door (global L7).
- **Secure**: NSGs required (Standard closed by default), DDoS on public.
