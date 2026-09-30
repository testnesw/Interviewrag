# Deep Dive · Azure Front Door

> Phase 3 (Azure foundation) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure Front Door (AFD) is Microsoft's **global, layer-7 entry point** — a combination of **global load balancer + CDN + WAF** running on Microsoft's edge network. It terminates TLS at the edge closest to users, routes to the **healthiest/nearest backend** (across regions), caches static content, and protects apps with a **Web Application Firewall**. Use it as the **global front door** for internet-facing apps/APIs that need **low latency, multi-region failover, and edge security**. Contrast: **Front Door = global**; **Application Gateway = regional**.

---

## 2. Architect-Level Explanation
AFD (Standard/Premium) provides:
- **Anycast global edge**: users hit the nearest Microsoft PoP; TLS terminates at edge → lower latency, split TCP.
- **Global HTTP(S) load balancing**: route across **origins** in multiple regions by **latency, priority (active-passive), or weight**; **health probes** drive automatic failover.
- **CDN caching** at the edge for static/cacheable content.
- **WAF** (OWASP managed rules + custom + bot protection + rate limiting) at the edge — blocks attacks before they reach your app.
- **Routing rules**: path-based routing, URL rewrite/redirect, header manipulation, rules engine.
- **Premium extras**: **Private Link to origins** (origins stay private), managed WAF rule sets, bot management.

Architecturally AFD is the **global north-south ingress + edge security + acceleration** layer, typically in front of **APIM/App Gateway/AKS/App Service**.

---

## 3. Why It Exists
- **Problem**: a single-region public endpoint is slow for distant users, a DDoS/attack target, and a single point of failure.
- **Breakthrough**: terminate + secure + cache at a **global edge**, then route intelligently to healthy regional backends.
- **Why enterprises adopt it**: global low latency, automatic multi-region failover, centralized WAF/DDoS at the edge, and offloading TLS/caching.
- **GenAI angle**: global users of a chat app get low-latency edge entry, WAF protection, and regional failover of the GenAI backend.

---

## 4. Internal Working
**Request path:**
1. DNS resolves the AFD hostname to **Anycast** → routed to the **nearest PoP**.
2. PoP **terminates TLS**; **WAF** evaluates rules (managed OWASP + custom + rate limit + bot).
3. **Rules engine** applies routing (path match, rewrite, headers).
4. **Cache**: if cacheable and hit, serve from edge; else go to origin.
5. **Origin selection**: among the **origin group**, pick by **priority/latency/weight**, skipping unhealthy origins (per **health probes**).
6. Connection to origin over Microsoft backbone (optionally **Private Link** in Premium) → response returns via PoP (cached if applicable).

Key mechanics:
- **Origin group** = backends + load-balancing + health-probe settings.
- **Health probes** determine failover; tune interval/path/thresholds.
- **Session affinity** optional; generally prefer stateless backends.

---

## 5. Enterprise Use Case
A global GenAI SaaS runs the app in **East US + West Europe**. AFD Premium provides the single global hostname: TLS + WAF at the edge, **latency-based routing** to the nearest region, **priority failover** if one region's health probe fails, and **Private Link** to keep origins (APIM/AKS) private. Static assets are edge-cached; bot protection + rate limiting block abuse. Users worldwide get fast, secure access with automatic regional resilience.

---

## 6. Real Production Architecture
```
        Users (global)
            │ Anycast → nearest PoP
   ┌──────── Azure Front Door Premium (edge) ────────┐
   │  TLS terminate · WAF (OWASP+custom+bot+ratelimit)│
   │  CDN cache · rules engine (path/rewrite/headers) │
   │  Origin group (health probes, latency/priority)  │
   └───────────────┬───────────────┬──────────────────┘
      Private Link  │               │  Private Link
                    ▼               ▼
     Region A: APIM→AKS (private)   Region B: APIM→AKS (private)
                    │                       │
             Azure OpenAI (PE)       Azure OpenAI (PE)
```

---

## 7. Security Best Practices
- **WAF in Prevention mode** with managed OWASP rules + custom rules + **bot protection** + **rate limiting** at the edge.
- **Private Link to origins** (Premium) so backends have **no public exposure**; lock origins to accept only AFD (via `X-Azure-FDID` header + service tag).
- **TLS 1.2+**, managed certs, HTTPS-only + HTTP→HTTPS redirect.
- **DDoS protection** at the edge (absorbed by the global network).
- **Header hardening** (HSTS, security headers) via rules engine.
- **Geo-filtering** to allow/deny regions; **secrets/certs** in Key Vault.

---

## 8. Scaling Strategy
- **Edge scales automatically** (global PoPs) — no capacity to manage at the front.
- **Caching** offloads origins massively (static + cacheable API responses).
- **Add origins/regions** to the origin group for more backend capacity.
- **Latency/weight routing** spreads load; **health probes** shed unhealthy origins.
- Combine with regional autoscaling (APIM/AKS) behind it.

---

## 9. High Availability Strategy
- **Global by design**: multi-region origin group with **automatic failover** on health-probe failure.
- **Anycast** + many PoPs → resilient edge.
- **Priority routing** = active-passive; **latency/weight** = active-active.
- Tune **probe sensitivity** for fast, non-flapping failover.

---

## 10. Disaster Recovery Strategy
- **AFD is the DR orchestrator** for regional failure — reroutes to the surviving region automatically.
- Ensure **both regions are deployable via IaC** and data is geo-replicated.
- **Test failover** (disable a region/probe) regularly; document RTO (near-instant via probes) and RPO (data-tier dependent).

---

## 11. Cost Optimization Strategy
- **Caching** reduces origin egress/compute (cache-friendly TTLs).
- **Standard vs Premium**: Premium adds Private Link + managed bot/WAF rule sets — pay for it only if needed.
- **Reduce origin regions** if latency SLOs allow; **compression** at edge cuts bandwidth.
- Watch **data-transfer/routing costs**; consolidate endpoints.

---

## 12. Common Production Challenges
- **Origin not locked to AFD** → attackers bypass WAF by hitting origin directly; enforce `X-Azure-FDID` + Private Link.
- **Caching wrong content** (auth'd/dynamic) → cache-control discipline.
- **WAF false positives** blocking legit traffic → tune rules, start in Detection then Prevention.
- **Health probe misconfig** → false failovers or no failover; pick a real health path.
- **DNS/custom domain/cert** issues → validate domain + managed cert provisioning.
- **Session affinity assumptions** → prefer stateless backends.

---

## 13. Monitoring and Observability
- **AFD metrics/logs** → Log Analytics: request count, latency, cache hit ratio, backend health, WAF blocks.
- **WAF logs**: matched rules, blocked requests (for tuning + security).
- **Health-probe status** per origin; **failover events**.
- **Alerts**: origin unhealthy, WAF block spikes, latency SLO breach, low cache-hit ratio.

---

## 14. Troubleshooting Scenarios
- **Users hitting origin directly** → missing origin lock; enforce FDID header + Private Link/NSG.
- **Legit requests 403 by WAF** → false positive; inspect WAF logs, add exclusion/custom rule.
- **No failover during outage** → probe path returns 200 despite app broken; use a deep health check.
- **Stale/incorrect content** → cache TTL/cache-control; purge cache.
- **High latency despite edge** → cache miss + distant origin; add region/cache, check origin health.
- **Cert errors** → custom domain validation/managed cert pending; verify DNS + binding.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Global edge (AFD) | latency, failover, DDoS | added hop/cost |
| Premium (Private Link) | private origins, bot mgmt | pricier |
| Aggressive caching | offload origin | staleness risk |
| Sensitive probes | fast failover | flapping risk |

---

## 16. When NOT to use it
- **Single-region internal app** with regional users → **Application Gateway** (regional L7 + WAF) is enough.
- **Non-HTTP protocols** → AFD is L7 HTTP(S) only; use Traffic Manager/global LB.
- **Purely internal (no internet)** → App Gateway/internal LB.
- **Tiny app, one region, no global users** → skip the extra hop/cost.

---

## 17. Comparison with Alternatives
| Option | Scope | Layer | Best for |
|--------|-------|-------|----------|
| **Front Door** | global | L7 (+WAF/CDN) | global HTTP entry, multi-region failover |
| Application Gateway | regional | L7 (+WAF) | regional web ingress, path routing |
| Traffic Manager | global | DNS | non-HTTP / DNS-level routing |
| Load Balancer | regional | L4 | TCP/UDP within region |
| APIM | global/regional | API mgmt | policies/quotas (often behind AFD) |

---

## 18. Interview Questions
1. What is Front Door and how is it different from Application Gateway?
2. How does global routing + failover work (routing methods)?
3. What does the edge give you (TLS, WAF, CDN)?
4. How do you lock origins so WAF can't be bypassed?
5. Front Door vs Traffic Manager?
6. How do health probes drive failover?
7. How do you design multi-region HA with AFD?
8. WAF tuning — Detection vs Prevention?
9. How do you secure private origins with AFD?
10. When would you NOT use Front Door?

---

## 19. Strong Interview Answers
- **AFD vs App Gateway**: "Front Door is **global** L7 — Anycast edge, multi-region routing/failover, CDN, WAF. Application Gateway is **regional** L7 with WAF. I use AFD as the global entry and App Gateway (or APIM/AKS ingress) regionally behind it. Rule of thumb: global → Front Door, regional → App Gateway."
- **Routing/failover**: "Origin groups support priority (active-passive), latency (nearest), or weighted routing. Health probes mark origins unhealthy and AFD fails over automatically — near-instant regional DR without DNS TTL delays."
- **Origin lock**: "WAF only helps if attackers can't bypass it. I restrict origins to accept traffic only from AFD via the `X-Azure-FDID` header check plus the AzureFrontDoor.Backend service tag, and in Premium use Private Link so origins have no public IP."
- **AFD vs Traffic Manager**: "Traffic Manager is DNS-based (works for any protocol but only resolves names — failover waits on TTL). Front Door is a real L7 reverse proxy at the edge with instant probe-based failover, TLS offload, WAF, and caching. For HTTP apps I prefer AFD."
- **WAF tuning**: "Start in Detection to observe matches, tune exclusions/custom rules to avoid false positives, then switch to Prevention. Add bot protection and rate limiting at the edge."

---

## 20. Architecture Diagrams
**Global routing + failover:**
```
User ─► nearest PoP (TLS+WAF+cache) ─► Origin group:
         Region A (priority 1, healthy) ◄─ probes
         Region B (priority 2, standby)  ◄─ probes
   A unhealthy → auto route to B (near-instant)
```

---

## 21. Real Project Example
**Global GenAI chat.** AFD Premium fronts APIM→AKS origins in two regions. Latency routing sends users to their nearest region; priority failover covers a regional outage (validated by disabling a region's probe — traffic shifted in seconds). WAF (Prevention) with bot + rate limiting blocked credential-stuffing attempts. Origins are private via Private Link and reject non-AFD traffic. Edge caching served static UI assets globally. p95 latency for distant users dropped ~40% vs the prior single-region setup.

---

## 22. Whiteboard Design Question
> *"Design global, secure, resilient ingress for a GenAI app serving users on three continents."*

Cover: AFD Premium (Anycast edge) → TLS terminate + WAF (OWASP+bot+rate limit) + CDN → latency routing with priority failover across 2–3 regions → Private Link to private origins (APIM/AKS) → origin lock (FDID + service tag) → health probes (deep path) → regional autoscaling behind → observability (WAF logs, cache hit, failover events) → DR (auto reroute + IaC + geo-replicated data). Contrast with App Gateway (regional) and Traffic Manager (DNS).

---

## 23. Design Review Questions
- Are **origins locked to AFD** (FDID + service tag / Private Link)?
- **Routing method** (latency/priority/weight) matches HA goal?
- **Health-probe path** is a real deep check (not a shallow 200)?
- **WAF** in Prevention with tuned rules + bot + rate limiting?
- **Caching** rules avoid caching authenticated/dynamic content?
- **Multi-region origins** deployable via IaC + data geo-replicated?
- **Custom domain + managed certs + HSTS** configured?

---

## 24. Hands-on Example
```bash
# Create Front Door Premium, an origin group with health probes, and two origins
az afd profile create -g rg --profile-name genai-afd --sku Premium_AzureFrontDoor
az afd origin-group create -g rg --profile-name genai-afd -n app-origins \
  --probe-path /health --probe-protocol Https --probe-interval-in-seconds 30 \
  --sample-size 4 --successful-samples-required 3 \
  --additional-latency-in-milliseconds 50
az afd origin create -g rg --profile-name genai-afd --origin-group-name app-origins \
  -n eastus --host-name apim-eastus.azure-api.net --priority 1 --weight 1000 --enabled-state Enabled
az afd origin create -g rg --profile-name genai-afd --origin-group-name app-origins \
  -n westeu --host-name apim-westeu.azure-api.net --priority 2 --weight 1000 --enabled-state Enabled
```

---

## 25. Terraform Example
```hcl
resource "azurerm_cdn_frontdoor_profile" "afd" {
  name = "genai-afd" resource_group_name = var.rg  sku_name = "Premium_AzureFrontDoor"
}
resource "azurerm_cdn_frontdoor_origin_group" "app" {
  name = "app-origins"  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  load_balancing { sample_size = 4  successful_samples_required = 3 }
  health_probe { path = "/health" protocol = "Https" interval_in_seconds = 30  request_type = "GET" }
}
resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name = "genaiwaf" resource_group_name = var.rg  sku_name = "Premium_AzureFrontDoor"
  mode = "Prevention"
  managed_rule { type = "Microsoft_DefaultRuleSet" version = "2.1" action = "Block" }
  managed_rule { type = "Microsoft_BotManagerRuleSet" version = "1.0" action = "Block" }
}
```

---

## 26. Azure Example
```bash
# Lock the origin (App Gateway/APIM) to accept only Front Door traffic
# 1) Restrict NSG/origin to the AzureFrontDoor.Backend service tag
az network nsg rule create -g rg --nsg-name origin-nsg -n allow-afd --priority 100 \
  --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 443 \
  --source-address-prefixes AzureFrontDoor.Backend
# 2) At the app, additionally verify the X-Azure-FDID header matches your profile ID
```

---

## 27. Code Example
```csharp
// Origin-side middleware: reject any request not coming through *our* Front Door
app.Use(async (ctx, next) => {
    var fdid = ctx.Request.Headers["X-Azure-FDID"].ToString();
    if (fdid != Config["FrontDoorId"]) {         // block direct-to-origin bypass
        ctx.Response.StatusCode = StatusCodes.Status403Forbidden;
        return;
    }
    await next();
});
```

---

## 28. Things Architects Must Remember
- **Front Door = global L7 (edge LB + CDN + WAF)**; **App Gateway = regional L7 + WAF**.
- **Anycast edge**: TLS terminate + WAF + cache close to users → latency + security + offload.
- **Health-probe-driven failover** = near-instant regional DR (no DNS TTL wait).
- **Lock origins to AFD** (FDID header + service tag / Private Link) or WAF is bypassable.
- **Routing methods**: priority (active-passive), latency (nearest), weighted.
- **WAF**: Detection → tune → Prevention; add bot + rate limiting.
- **Cache carefully** — never cache authenticated/dynamic content.
- **HTTP(S) only** — non-HTTP needs Traffic Manager/global LB.

---

## 29. Mnemonics and Memory Tricks
- **"Front Door = the whole planet's door; App Gateway = one building's door."** (global vs regional)
- **Edge does "T-W-C"**: **T**LS terminate, **W**AF, **C**ache.
- **Routing "P-L-W"**: **P**riority, **L**atency, **W**eighted.
- **"Lock the back door"** — origin must accept only AFD (FDID + service tag).
- **WAF rollout**: *"Detect, tune, then prevent."*

---

## 30. One-Page Interview Revision Sheet
- **What**: global L7 entry = edge load balancer + CDN + WAF on Microsoft's Anycast network.
- **Edge**: TLS terminate + WAF (OWASP/bot/rate-limit) + caching close to users.
- **Routing**: origin groups with priority/latency/weighted; **health-probe failover** (near-instant DR).
- **Security**: Prevention WAF, **lock origins to AFD** (X-Azure-FDID + AzureFrontDoor.Backend tag), Private Link (Premium), TLS1.2+, HSTS, geo-filter, DDoS.
- **vs App Gateway**: global vs regional; vs Traffic Manager: real L7 proxy vs DNS-only.
- **HA/DR**: multi-region origins + auto failover; AFD is the DR router; IaC + geo-replicated data.
- **Cost**: caching offload, Standard vs Premium, compression, fewer origin regions if SLO allows.
- **When NOT**: single-region internal app (App Gateway), non-HTTP (Traffic Manager).
- **Remember**: *global door vs building door*; edge = **T-W-C**; routing **P-L-W**; *lock the back door*; detect→tune→prevent.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Front Door vs Application Gateway vs Traffic Manager — pick each for a scenario.
2. Explain how AFD achieves near-instant regional failover without DNS TTL delays.
3. An attacker bypasses your WAF by hitting the origin directly. How did you prevent it?
4. Design global ingress for a GenAI app on three continents with regional failover.
5. Your failover never triggered during a real outage. What went wrong with the probe?
6. When is caching dangerous, and how do you configure it safely for an API?
7. Walk through a safe WAF rollout that won't block legitimate users.
8. How do you keep origins fully private while still using Front Door?
9. Latency is still high for APAC users despite AFD. Diagnose.
10. When would you deliberately skip Front Door and use App Gateway alone?

---

> Next Phase 3 topic: **Security (Entra ID · Managed Identity · Key Vault · RBAC · Defender)**.
