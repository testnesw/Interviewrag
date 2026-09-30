# DEEP MECHANICS · Application Gateway

> Level 2 — L7 routing, WAF, SSL termination, backend pools/health, and when to
> use it over LB/Front Door.

---

## 0. The precise mental model
Application Gateway = a **regional Layer-7 (HTTP/S) load balancer + reverse proxy** with a built-in **Web Application Firewall (WAF)**. Because it understands HTTP, it routes by **URL path and hostname**, terminates **TLS**, rewrites headers, and protects apps against OWASP attacks. Use it to front **regional web apps**; add **Front Door** for global.

---

## 1. L7 routing capabilities
- **Path-based routing** — `/api/*` → API pool, `/images/*` → storage pool.
- **Multi-site hosting** — route by **Host header** (app1.com, app2.com) to different pools.
- **Listeners** (frontend IP+port+protocol) → **routing rules** → **backend pools** + **HTTP settings**.
- **Cookie-based session affinity** for stateful apps.
- **URL rewrite / header rewrite / redirects** (HTTP→HTTPS).

## 2. WAF (the security value)
Integrated **Web Application Firewall** protects against **OWASP Top 10** (SQLi, XSS, etc.) via managed rule sets (OWASP CRS). Modes: **Detection** (log) / **Prevention** (block). Custom rules, rate limiting, bot protection. This is inbound L7 protection your app doesn't have to build.

## 3. TLS/SSL
- **SSL termination (offload)** — decrypt at the gateway → backends get HTTP (less CPU on backends, central cert management).
- **End-to-end SSL** — re-encrypt to backends for compliance.
- Cert management via Key Vault integration.

## 4. Backend pools & health
- Backends = VMs, VMSS, App Service, IPs/FQDNs.
- **Health probes** (HTTP) remove unhealthy backends.
- **Autoscaling** (v2 SKU) + **zone redundancy** + static VIP.

## 5. App Gateway vs LB vs Front Door
- **LB** — L4, non-HTTP, fastest, no content routing.
- **App Gateway** — **regional L7** + WAF + path/host routing + SSL.
- **Front Door** — **global L7** edge + WAF + CDN + global failover.
Common combo: **Front Door (global edge + WAF)** → regional **App Gateway** → backends, or Front Door directly to backends.

## 6. The hard follow-ups (with answers)
1. **"Why App Gateway over Load Balancer?"** → L7: URL/host routing, WAF, SSL termination, rewrites — LB is L4 only. (§0,1)
2. **"How does path-based routing work?"** → listener → rule matches URL path → routes to the mapped backend pool. (§1)
3. **"What does the WAF protect against?"** → OWASP Top 10 (SQLi/XSS) via CRS; detection/prevention modes. (§2)
4. **"SSL offload vs end-to-end?"** → terminate at gateway (backends HTTP) vs re-encrypt to backends (compliance). (§3)
5. **"App Gateway vs Front Door?"** → regional L7+WAF vs global edge L7+WAF+CDN+failover. (§5)

## 7. One-screen recall
- App Gateway = **regional L7 (HTTP/S) reverse proxy + WAF**.
- **Routing**: **path-based** + **multi-site (host header)**; listeners→rules→backend pools+HTTP settings; cookie affinity; rewrites/redirects.
- **WAF** = OWASP Top 10 (SQLi/XSS) via CRS; **Detection/Prevention** modes, custom rules, bot/rate.
- **SSL**: termination (offload) or end-to-end; Key Vault certs.
- **Backends** VMs/VMSS/App Service/FQDN + health probes; v2 autoscale + zone-redundant.
- **LB (L4)** < **App Gateway (regional L7+WAF)** < **Front Door (global L7+WAF+CDN)**; often FD→AppGW→backend.

> Next: Front Door.
