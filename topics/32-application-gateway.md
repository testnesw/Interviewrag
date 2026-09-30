# 32 · Application Gateway

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Application Gateway is a **web (HTTP/HTTPS) load balancer** that can route by URL path, terminate TLS, and protect apps with a Web Application Firewall (WAF). It works at Layer 7.

## 2. Architect-Level Explanation
A regional **L7** reverse proxy / load balancer:
- **Routing**: path-based and host-based (multi-site) routing to backend pools.
- **TLS**: termination + end-to-end re-encryption; cert integration with Key Vault.
- **WAF**: OWASP Core Rule Set (managed rules), custom rules, bot protection — Prevention/Detection modes.
- **Features**: cookie-based session affinity, autoscaling (v2), zone redundancy, health probes, URL rewrite, header rewrite.
- **Backends**: VMs, VMSS, App Service, AKS (via **AGIC** — Application Gateway Ingress Controller).
- Regional scope — pair with Front Door for global.

## 3. Real Enterprise Use Case
An e-commerce site fronts its microservices with Application Gateway v2 (zone-redundant, autoscaling): `/api/*`→API pool, `/images/*`→static pool, host-based routing for multiple brands, WAF in Prevention mode with OWASP rules, TLS terminated with Key Vault certs.

## 4. Architecture Diagram (ASCII)
```
 Client ─HTTPS─► [ Application Gateway v2 ]
                   ├ Listener (443, TLS termination, KV cert)
                   ├ WAF (OWASP CRS, Prevention)
                   ├ URL path rules:
                   │   /api/*    ─► API backend pool
                   │   /images/* ─► static backend pool
                   └ Health probes
   Zone-redundant + autoscale ; regional (pair with Front Door for global)
```

## 5. Interview Questions
1. Application Gateway vs Load Balancer vs Front Door?
2. Path-based vs host-based routing?
3. How does WAF work (modes, rules)?
4. TLS termination vs end-to-end TLS?
5. What is AGIC?

## 6. Strong Interview Answers
- **AppGw vs LB vs FD**: "LB is L4; Application Gateway is regional L7 (HTTP) with WAF, TLS, and URL routing; Front Door is global L7 (anycast + CDN). Use AppGw for regional web apps, Front Door for global entry, and often Front Door → AppGw together."
- **Path vs host**: "Path-based routes by URL path (`/api/*`) to different pools; host-based (multi-site) routes by hostname (brandA.com vs brandB.com) on one gateway. Combine both."
- **WAF**: "Managed OWASP Core Rule Set blocks common attacks (SQLi, XSS); Detection mode logs, Prevention mode blocks. Add custom rules (rate limiting, geo, IP) and bot protection. Tune to avoid false positives."
- **TLS**: "Termination decrypts at the gateway (offload, inspection); end-to-end re-encrypts to the backend for compliance where the backend must also see TLS. I use Key Vault for cert management."
- **AGIC**: "Application Gateway Ingress Controller lets AKS use App Gateway as its ingress — Kubernetes Ingress resources program the gateway automatically."

## 7. Common Mistakes
- Using AppGw for non-HTTP (that's L4 LB).
- WAF straight to Prevention without tuning (false positives).
- Managing certs manually vs Key Vault.
- Ignoring backend health probe config.
- Expecting global scale from a regional service.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| App Gateway | L7 + WAF + TLS, regional | regional only, cost |
| Load Balancer | fast L4, cheap | no HTTP features |
| Front Door | global, CDN | less regional-granular control |

## 9. Production Best Practices
- v2 SKU: zone-redundant + autoscaling.
- WAF Detection → tune → Prevention.
- Key Vault-integrated certs; auto-rotation.
- Health probes with real health paths.
- End-to-end TLS for sensitive backends.
- IaC + WAF log analysis.

## 10. Security Considerations
- WAF (OWASP) Prevention + custom/bot rules.
- TLS termination/re-encryption; strong ciphers/TLS 1.2+.
- Restrict backends to accept only gateway traffic.
- DDoS + private frontend where applicable; logs to Sentinel.

## 11. Cost Optimization
- v2 autoscale to demand; right-size capacity units.
- Consolidate multi-site apps on one gateway.
- WAF adds cost — apply where needed.

## 12. Troubleshooting Scenarios
- **502 Bad Gateway** → backend unhealthy/probe fail, NSG, backend TLS mismatch.
- **WAF blocks valid requests** → tune rules / exclusions.
- **Cert errors** → Key Vault access/managed identity, cert chain.
- **Wrong routing** → path rule order / listener host mismatch.

## 13. Hands-on Example
```bash
az network application-gateway create -g rg-net -n app-gw \
  --sku WAF_v2 --capacity 2 --vnet-name app-vnet --subnet appgw-subnet \
  --public-ip-address appgw-pip --http-settings-port 80
```

## 14. Terraform Example
```hcl
resource "azurerm_application_gateway" "gw" {
  name                = "app-gw"
  resource_group_name = azurerm_resource_group.net.name
  location            = "eastus"
  sku { name = "WAF_v2" tier = "WAF_v2" }
  autoscale_configuration { min_capacity = 2 max_capacity = 10 }
  zones = ["1","2","3"]
  waf_configuration { enabled = true firewall_mode = "Prevention"
    rule_set_type = "OWASP" rule_set_version = "3.2" }
  # listeners, backend pools, url path map omitted for brevity
}
```

## 15. Azure Example
```bash
az network application-gateway waf-config set -g rg-net --gateway-name app-gw \
  --enabled true --firewall-mode Prevention \
  --rule-set-type OWASP --rule-set-version 3.2
```

## 16. FastAPI / Python Example
```python
@app.get("/health")   # App Gateway backend health probe
def health(): return {"status": "ok"}

@app.get("/api/orders")   # reached via /api/* path rule
def orders(): return {"orders": [...]}
```

## 17. AKS Example
Install **AGIC** so AKS Ingress resources program Application Gateway; WAF protects all ingress; TLS terminated at the gateway with Key Vault certs; backend pods reached over the AKS subnet.

## 18. How to Remember
**"L7 web gateway with a WAF."** URL/host routing + TLS + OWASP protection, regional.

## 19. Real-World Analogy
A smart building receptionist who reads the visitor's request (URL), sends them to the right department (path routing), checks IDs against a security blacklist (WAF), and handles the secure sign-in (TLS).

## 20. One-Page Cheat Sheet
- **What**: regional L7 (HTTP/S) load balancer + WAF + TLS.
- **Routing**: path-based + host-based (multi-site).
- **WAF**: OWASP CRS, Detection→tune→Prevention, custom/bot rules.
- **TLS**: termination or end-to-end; certs via Key Vault.
- **v2**: zone-redundant + autoscaling; AKS via AGIC.
- **Pairing**: Front Door (global) → App Gateway (regional) → backends.
- **502 = backend/probe/TLS mismatch** first.
