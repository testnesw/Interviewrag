# DEEP MECHANICS · Azure Front Door

> Level 2 — global edge routing, Anycast, CDN caching, WAF at the edge, and
> global failover for multi-region apps.

---

## 0. The precise mental model
Front Door = Microsoft's **global L7 load balancer + CDN + WAF at the edge**. Users connect to the **nearest Microsoft edge POP** (via **Anycast**), TLS terminates there, static content is **cached**, and dynamic requests are routed over the **optimized backbone** to the healthiest/closest backend. It's how you make an app **fast and highly available worldwide** with automatic **multi-region failover**.

---

## 1. Anycast + edge (why it's fast)
- The Front Door IP is **Anycast** — announced from **all edge POPs**; users route to the **nearest** one automatically.
- **TLS terminates at the edge** (close to user) → faster handshake.
- Dynamic traffic then rides Microsoft's **private backbone** to the origin (lower latency, more reliable than public internet).

## 2. Global routing & failover
- **Backend pools (origins)** across regions with **health probes** from the edge.
- **Priority routing** (active-passive failover) or **latency/weighted** routing (active-active).
- On origin failure, Front Door **reroutes to the next healthy region automatically** → global HA. This is the multi-region resilience mechanism.

## 3. CDN caching
- Caches static content at edge POPs → served locally, offloads origin, cuts latency.
- **Rules engine** controls caching, redirects, header manipulation, routing overrides.

## 4. WAF at the edge (security)
- **WAF runs at the edge POPs** → blocks OWASP attacks, bots, and **DDoS** close to the source, before traffic reaches your region. Managed + custom rules, rate limiting, geo-filtering.

## 5. Front Door vs App Gateway vs Traffic Manager
| | **Front Door** | **App Gateway** | **Traffic Manager** |
|---|---|---|---|
| Layer | **global L7** | regional L7 | **DNS-based** (any protocol) |
| Job | edge routing + CDN + WAF | regional web LB + WAF | DNS-level global routing |
| TLS | terminate at edge | terminate regional | n/a (DNS only) |
| Failover | fast, HTTP-aware | within region | DNS TTL-bound (slower) |
- **Traffic Manager** works at **DNS** (returns an endpoint IP) → protocol-agnostic but failover is TTL-bound.
- **Front Door** is the modern global HTTP entry point; combine with regional **App Gateway** if needed.

## 6. The hard follow-ups (with answers)
1. **"How does Front Door make apps fast globally?"** → Anycast to nearest edge POP + edge TLS + cache + backbone to origin. (§1,3)
2. **"How does global failover work?"** → edge health probes + priority/latency routing reroute to next healthy region automatically. (§2)
3. **"Where does the WAF run?"** → at the edge POPs → blocks attacks/DDoS before reaching your region. (§4)
4. **"Front Door vs App Gateway?"** → global edge (CDN/WAF/failover) vs regional L7 web LB (+WAF). (§5)
5. **"Front Door vs Traffic Manager?"** → L7 edge proxy with fast HTTP failover + caching vs DNS-level routing (TTL-bound, any protocol). (§5)

## 7. One-screen recall
- Front Door = **global L7 LB + CDN + WAF at the edge**.
- **Anycast** → nearest POP; **TLS terminates at edge**; dynamic → **Microsoft backbone** to origin.
- **Global failover**: edge health probes + **priority (active-passive)** or **latency/weighted (active-active)** → auto-reroute to healthy region.
- **CDN caching** + **rules engine**; **WAF/DDoS at edge** (before your region).
- vs **App Gateway** (regional L7) vs **Traffic Manager** (DNS-level, TTL failover, protocol-agnostic). Often FD (global) → App Gateway (regional).

> Next: DNS.
