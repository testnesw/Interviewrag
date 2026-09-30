# DEEP MECHANICS · ExpressRoute

> Level 2 — private dedicated connectivity, peering types, redundancy, and
> ExpressRoute vs VPN.

---

## 0. The precise mental model
ExpressRoute = a **private, dedicated connection from on-prem to Microsoft** that **bypasses the public internet** entirely, via a connectivity provider. You get **predictable bandwidth, low latency, and higher reliability** than a VPN over the internet. Traffic rides Microsoft's backbone using **BGP** to exchange routes. It's the enterprise choice for hybrid connectivity where performance/compliance matter.

---

## 1. How it connects
```
On-prem ── Provider (MPLS/Ethernet) ── Microsoft Enterprise Edge (MSEE routers)
         (redundant pair of connections) ── Azure VNets (via gateway) / M365
```
- **ExpressRoute circuit** — the logical connection (bandwidth SKU: 50 Mbps–100 Gbps).
- **Redundant by design** — two connections at the edge; Microsoft SLA requires both.
- **BGP** exchanges routes between on-prem and Azure dynamically.

## 2. Peering types
- **Private peering** — connect to your **VNets** (private IPs) → the main hybrid use. Reach IaaS/PaaS via gateway.
- **Microsoft peering** — access **Microsoft public services** (M365, Azure PaaS public endpoints) over the private circuit.
(Public peering is deprecated/merged into Microsoft peering.)

## 3. Gateway & scale
- An **ExpressRoute Gateway** in the VNet (or hub) terminates the circuit; spokes use **gateway transit**.
- **ExpressRoute Direct** — connect directly to Microsoft's routers at 10/100 Gbps for massive scale.
- **FastPath** — bypass the gateway for data path → lower latency/higher throughput.

## 4. Redundancy & DR
- Two circuits in **different peering locations** for high availability.
- **Site-to-Site VPN as backup** to ExpressRoute (failover path).
- Zone-redundant gateways.

## 5. ExpressRoute vs VPN Gateway
| | **ExpressRoute** | **VPN Gateway (S2S)** |
|---|---|---|
| Path | private, dedicated (no internet) | encrypted tunnel over internet |
| Bandwidth | up to 100 Gbps, predictable | limited, variable |
| Latency | low, consistent | variable |
| Cost | higher (circuit + provider) | lower |
| Setup | provider, weeks | quick |
| Use | enterprise hybrid, low-latency, compliance | quick/cheap, backup, smaller |
Common pattern: **ExpressRoute primary + VPN backup**.

## 6. The hard follow-ups (with answers)
1. **"What is ExpressRoute?"** → private dedicated on-prem↔Microsoft connection bypassing the internet, via a provider, using BGP. (§0,1)
2. **"Private vs Microsoft peering?"** → reach your VNets (private IPs) vs Microsoft public services (M365/PaaS). (§2)
3. **"Is it encrypted?"** → not by default (it's private, not internet); add MACsec (Direct) or IPsec over it if required. (§1)
4. **"How do spokes use one circuit?"** → ExpressRoute gateway in hub + gateway transit. (§3)
5. **"ExpressRoute vs VPN?"** → dedicated/predictable/high-bandwidth vs internet tunnel cheap/quick; use VPN as backup. (§5)
6. **"Make it highly available?"** → dual circuits in different locations + VPN failover + zone-redundant gateway. (§4)

## 7. One-screen recall
- ExpressRoute = **private dedicated on-prem↔Microsoft** link, **no internet**, via provider, **BGP** routing; predictable bandwidth/low latency.
- **Circuit** (50 Mbps–100 Gbps), **redundant pair** at edge (MSEE).
- **Private peering** (your VNets) + **Microsoft peering** (M365/PaaS public).
- **ExpressRoute Gateway** (+ gateway transit for spokes); **Direct** (10/100 Gbps), **FastPath** (bypass gateway).
- Not encrypted by default; **dual circuits + VPN backup** for HA/DR.
- vs **VPN**: dedicated/predictable/pricey vs internet tunnel/cheap/quick (backup).

> Next: Load Balancer.
