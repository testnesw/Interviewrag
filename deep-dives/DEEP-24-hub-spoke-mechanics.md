# DEEP MECHANICS · Hub-Spoke Network Topology

> Level 2 — why hub-spoke, peering + transitivity, shared services in the hub,
> and hub-spoke vs Virtual WAN.

---

## 0. The precise mental model
Hub-spoke = **centralize shared network services in a "hub" VNet and connect isolated workload "spoke" VNets to it via peering**. You get **isolation** (each workload in its own spoke) + **centralized control** (one firewall, one gateway, one DNS) + **cost efficiency** (share expensive resources). It's the standard enterprise Azure topology.

---

## 1. The topology
```
        On-prem ──(ExpressRoute/VPN)── [Gateway]
                                          │
              ┌──────────── HUB VNet ─────┴──────────┐
              │  Azure Firewall · DNS · Bastion       │
              └───┬───────────────┬───────────────┬───┘
             peering          peering          peering
                │                │                │
           Spoke A          Spoke B          Spoke C
          (workload)       (workload)       (shared svc)
```
- **Hub** — shared services: **Azure Firewall/NVA, VPN/ExpressRoute gateway, DNS, Bastion**.
- **Spokes** — isolated workloads; no direct internet/on-prem path except through the hub.

## 2. VNet peering & the transitivity trap (key gotcha)
- **Peering** connects two VNets with **private, low-latency** routing.
- **Peering is NOT transitive** — Spoke A peered to Hub, Hub peered to Spoke B does **not** let A talk to B automatically.
- To enable spoke-to-spoke: route through the **hub firewall/NVA** via **User-Defined Routes (UDRs)**, or use **gateway/route-server**. This forced routing is often **desired** (inspect all cross-spoke traffic).

## 3. Centralized services (why the hub)
- **Single egress/inspection point** — all internet/on-prem traffic goes through the hub firewall (UDR forces it) → central logging, filtering, compliance.
- **Gateway sharing** — one ExpressRoute/VPN gateway serves all spokes (spokes use **gateway transit**).
- **Central DNS** (Private DNS zones for Private Endpoints).
- **Bastion** for secure VM access.

## 4. Routing control
- **UDRs** override default routing to force traffic through the firewall (0.0.0.0/0 → firewall private IP).
- **NSGs** on subnets for micro-segmentation.
- **Gateway transit + "use remote gateway"** lets spokes reach on-prem via the hub's gateway.

## 5. Hub-Spoke vs Virtual WAN
- **Traditional hub-spoke** — you build/manage the hub (firewall, gateways, routing). Full control.
- **Azure Virtual WAN** — **managed hub** service: Microsoft runs the hub, automates any-to-any connectivity, integrated firewall (Secured Virtual Hub), scales globally. Less management, good for many branches/regions.

## 6. The hard follow-ups (with answers)
1. **"Why hub-spoke?"** → isolation (spokes) + centralized shared services + cost efficiency. (§0,3)
2. **"Can two spokes talk by default?"** → no — peering isn't transitive; route via hub firewall with UDRs. (§2)
3. **"How do all spokes reach on-prem with one gateway?"** → hub hosts the gateway; spokes use **gateway transit**. (§3)
4. **"Force all traffic through the firewall?"** → UDR 0.0.0.0/0 → firewall private IP on spoke subnets. (§4)
5. **"Hub-spoke vs Virtual WAN?"** → self-managed hub (control) vs managed hub (any-to-any, scale, less ops). (§5)

## 7. One-screen recall
- Hub-spoke = **shared services in hub VNet + isolated workload spokes via peering** → isolation + central control + cost share.
- **Hub**: Azure Firewall/NVA, VPN/ExpressRoute gateway, DNS, Bastion. **Spokes**: workloads, no direct egress.
- **Peering is NOT transitive** → spoke-to-spoke via **hub firewall + UDRs** (also enables inspection).
- **Gateway transit** = one gateway serves all spokes to on-prem.
- **UDRs** force traffic to firewall (0.0.0.0/0→FW IP); **NSGs** segment.
- **Virtual WAN** = managed hub alternative (any-to-any, global scale, less ops).

> Next: VNet.
