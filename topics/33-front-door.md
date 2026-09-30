# 33 · Azure Front Door

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Azure Front Door is a **global entry point + CDN** for your web apps. It routes users to the nearest/healthiest backend worldwide, caches content, and adds security (WAF) — fast and resilient globally.

## 2. Architect-Level Explanation
A global **L7** application delivery network using anycast + Microsoft's edge:
- **Global load balancing**: routes to the closest healthy origin (latency-based), with priority/weighted failover across regions.
- **CDN caching**: static content cached at edge POPs; dynamic acceleration.
- **Security**: WAF at the edge (OWASP + custom + bot + rate limiting), DDoS, **Private Link to origins** (Premium).
- **TLS**: termination at edge, managed certs, HTTP/2, end-to-end.
- **Tiers**: Standard (CDN+delivery) and **Premium** (adds managed WAF rules, Private Link origins, bot protection).
- Global scope — often fronts regional App Gateways / origins.

## 3. Real Enterprise Use Case
A global SaaS serves users on 3 continents. Front Door Premium routes each user to the nearest region (US/EU/Asia), fails over automatically if a region is down, caches static assets at the edge, connects privately to origins via Private Link, and enforces WAF + bot protection globally.

## 4. Architecture Diagram (ASCII)
```
 Users (global) ─► [ Front Door edge POPs (anycast) ]
                     ├ WAF (OWASP + bot + rate limit)
                     ├ CDN cache (static)
                     ├ TLS termination (managed cert)
                     └ latency/priority routing + health probes
        ┌──────────────────┼───────────────────┐
   Origin: US region   Origin: EU region   Origin: Asia region
   (App Gateway/App Service; Private Link in Premium)
```

## 5. Interview Questions
1. Front Door vs Application Gateway vs Traffic Manager?
2. How does global routing + failover work?
3. Standard vs Premium tier?
4. How does caching help and what are the risks?
5. How do you secure origins behind Front Door?

## 6. Strong Interview Answers
- **FD vs AppGw vs TM**: "Front Door is global L7 (anycast, CDN, WAF, TLS) — the global front door. Application Gateway is regional L7 with WAF. Traffic Manager is DNS-based global routing (no proxy/CDN/WAF). For modern global web apps, Front Door replaces TM+CDN and fronts regional AppGws."
- **Routing/failover**: "Anycast sends users to the nearest edge; Front Door forwards to the closest healthy origin by latency, with priority/weighted rules for failover. Health probes detect down origins and reroute automatically."
- **Standard vs Premium**: "Standard covers content delivery + basic WAF; Premium adds managed WAF rule sets, bot protection, and **Private Link to origins** so origins have no public exposure."
- **Caching**: "Edge caching cuts latency and origin load for static content; risks are stale content and caching private/dynamic responses — control with cache rules, TTLs, and cache-control headers."
- **Secure origins**: "Premium Private Link to origins + restrict origins to accept only Front Door traffic (via `X-Azure-FDID` header check / service tag) so no one bypasses the WAF."

## 7. Common Mistakes
- Letting origins accept direct public traffic (bypassing WAF).
- Caching dynamic/authenticated responses.
- Confusing Front Door (proxy/CDN) with Traffic Manager (DNS).
- WAF Prevention without tuning.
- Expecting regional-granular control like App Gateway.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Front Door | global, CDN, WAF, failover | less regional control, cost |
| Traffic Manager | simple DNS routing | no proxy/CDN/WAF |
| App Gateway | fine regional L7 control | regional only |

## 9. Production Best Practices
- Front Door (global) → App Gateway (regional) → backends.
- Multi-region origins with priority/latency routing + health probes.
- Premium + Private Link origins; lock origins to FD only.
- WAF Detection → tune → Prevention; bot + rate limiting.
- Cache static, bypass dynamic; managed TLS certs.

## 10. Security Considerations
- Edge WAF + DDoS + bot protection.
- Restrict origins to Front Door (FDID header / Private Link).
- TLS 1.2+, managed certs, HTTP/2.
- Global rate limiting + geo-filtering.

## 11. Cost Optimization
- Caching reduces origin egress/compute.
- Right tier (Standard vs Premium) by feature need.
- Watch data transfer + request pricing at scale.

## 12. Troubleshooting Scenarios
- **Users hit wrong/slow region** → routing method / health probe config.
- **Stale content** → cache TTL / purge / cache-control headers.
- **Origin bypass** → enforce FDID header / Private Link.
- **WAF false positives** → tune managed rules / exclusions.

## 13. Hands-on Example
```bash
az afd profile create -g rg-net --profile-name gfd --sku Premium_AzureFrontDoor
az afd endpoint create -g rg-net --profile-name gfd --endpoint-name app \
  --enabled-state Enabled
```

## 14. Terraform Example
```hcl
resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "global-fd"
  resource_group_name = azurerm_resource_group.net.name
  sku_name            = "Premium_AzureFrontDoor"
}
resource "azurerm_cdn_frontdoor_origin_group" "og" {
  name                     = "origins"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  load_balancing { sample_size = 4 successful_samples_required = 3 }
  health_probe { path = "/health" protocol = "Https" interval_in_seconds = 30 }
}
```

## 15. Azure Example
```bash
az afd security-policy create -g rg-net --profile-name global-fd \
  --security-policy-name waf-policy --domains <endpoint-id> \
  --waf-policy <waf-policy-id>
```

## 16. FastAPI / Python Example
```python
from fastapi import Request, HTTPException
FDID = "your-front-door-id"

@app.middleware("http")
async def only_front_door(request: Request, call_next):
    if request.headers.get("X-Azure-FDID") != FDID:
        raise HTTPException(403, "Direct access blocked")   # enforce FD-only
    return await call_next(request)
```

## 17. AKS Example
Front Door fronts multi-region AKS clusters (each behind an App Gateway/ingress); latency routing sends users to the nearest region, auto-failover on regional outage; origins locked to Front Door via FDID/Private Link.

## 18. How to Remember
**"The planet's front door."** Global anycast + CDN + WAF + failover, sitting in front of regional gateways.

## 19. Real-World Analogy
A global hotel chain's central reservation system that instantly books you into the nearest available branch, keeps popular brochures at every front desk (cache), screens guests (WAF), and reroutes you if one branch is full/closed (failover).

## 20. One-Page Cheat Sheet
- **What**: global L7 entry — anycast routing + CDN + WAF + TLS + failover.
- **Routing**: nearest healthy origin (latency) + priority/weighted failover.
- **Tiers**: Standard (delivery+WAF) vs Premium (managed WAF, bot, Private Link origins).
- **Pattern**: Front Door (global) → App Gateway (regional) → backends.
- **Secure origins**: lock to Front Door (FDID header / Private Link).
- **vs Traffic Manager**: full proxy/CDN/WAF vs DNS-only routing.
