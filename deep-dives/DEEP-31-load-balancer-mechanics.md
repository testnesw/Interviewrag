# DEEP MECHANICS · Azure Load Balancer

> Level 2 — L4 distribution, hash-based routing, health probes, SNAT, and LB vs
> App Gateway vs Front Door.

---

## 0. The precise mental model
Azure Load Balancer = a **Layer-4 (TCP/UDP) load balancer** that distributes flows across backend VMs using a **hashing algorithm**, with **health probes** removing unhealthy instances. It operates on **IP/port** (no knowledge of HTTP/URLs) → ultra-fast, but no content-based routing. Pick it for high-performance L4 distribution; use App Gateway/Front Door when you need L7.

---

## 1. How it distributes (hash-based)
- Default **5-tuple hash** (source IP, source port, dest IP, dest port, protocol) → maps each **flow** to a backend. Same flow → same backend; different flows spread out.
- **Session persistence** options: 2-tuple (source IP) or 3-tuple (source IP+dest IP) for stickiness.
- It's **flow distribution**, not round-robin per packet.

## 2. Public vs Internal
- **Public LB** — public frontend IP → internet-facing (inbound) + provides **outbound SNAT**.
- **Internal LB** — private frontend IP → distribute traffic **inside** a VNet (e.g., front a tier privately).

## 3. Health probes
- Probe backends (TCP/HTTP/HTTPS) on an interval; unhealthy instances are **removed from rotation** automatically → only healthy targets get traffic. Critical for reliability.

## 4. SNAT & outbound (gotcha)
- Public LB provides **outbound SNAT** (backends share the LB public IP for egress). Limited **SNAT ports** → high-scale outbound can exhaust ports → use a **NAT Gateway** (preferred for outbound at scale) or add IPs.

## 5. SKUs
- **Standard** (recommended) — zone-redundant, more scale, secure-by-default (needs NSG), HA ports, metrics.
- **Basic** — legacy, being retired.

## 6. LB vs App Gateway vs Front Door (the classic question)
| | **Load Balancer** | **App Gateway** | **Front Door** |
|---|---|---|---|
| Layer | **L4** (TCP/UDP) | **L7** (HTTP/S) | **L7 global** (HTTP/S) |
| Scope | regional | regional | **global/edge** |
| Routing | 5-tuple hash | URL path/host, cookie affinity | global routing, path/host |
| Extras | HA ports | **WAF**, SSL offload, rewrites | **WAF, CDN, global LB**, TLS at edge |
| Use | non-HTTP, internal L4 | regional web apps | global web apps, multi-region |

## 7. The hard follow-ups (with answers)
1. **"How does Azure LB choose a backend?"** → 5-tuple hash per flow (sticky options available), not round-robin. (§1)
2. **"What layer is it?"** → L4 (TCP/UDP), IP/port only — no URL routing. (§0)
3. **"How are unhealthy VMs handled?"** → health probes remove them from rotation. (§3)
4. **"Outbound SNAT exhaustion — fix?"** → use NAT Gateway (or add public IPs) for outbound at scale. (§4)
5. **"LB vs App Gateway vs Front Door?"** → L4 regional vs L7 regional (+WAF) vs L7 global edge (+WAF/CDN). (§6)
6. **"Distribute inside a VNet privately?"** → Internal Load Balancer (private frontend IP). (§2)

## 8. One-screen recall
- Azure LB = **L4 (TCP/UDP)** flow distributor via **5-tuple hash** (+ stickiness options); IP/port only, very fast.
- **Public** (internet + outbound SNAT) vs **Internal** (private, intra-VNet).
- **Health probes** remove unhealthy backends.
- **SNAT port exhaustion** at scale → **NAT Gateway** for outbound.
- **Standard SKU** (zonal, secure-by-default) over Basic.
- **LB (L4 regional)** vs **App Gateway (L7 regional + WAF)** vs **Front Door (L7 global edge + WAF/CDN)**.

> Next: Application Gateway.
