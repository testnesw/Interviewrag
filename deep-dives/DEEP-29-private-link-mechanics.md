# DEEP MECHANICS · Azure Private Link

> Level 2 — the service that powers Private Endpoints, Private Link Service for
> your own apps, and the provider/consumer model.

---

## 0. The precise mental model
**Private Link** is the **underlying technology** that connects a **private IP in your VNet** to a service over the Microsoft **backbone**, with no public internet exposure. A **Private Endpoint** is the *consumer* side (the NIC in your subnet); a **Private Link Service** is the *provider* side that lets **you** expose **your own** service privately to other tenants/VNets. It's a **private, one-way, NAT'd tunnel** to a specific service.

---

## 1. Consumer vs provider
- **Private Endpoint (consumer)** — you connect **to** a service (Azure PaaS or a partner's Private Link Service) via a private IP. (See Private Endpoint deep dive.)
- **Private Link Service (provider)** — you put your app behind a **Standard Load Balancer** and expose it as a Private Link Service; **consumers** create Private Endpoints to reach it privately — even across tenants, **without VNet peering** and with **overlapping IP spaces** allowed.

## 2. Why it matters (the properties)
- **No public exposure** — service reachable only via approved private endpoints.
- **No peering / no overlap concerns** — connection is via Private Link, not routing → works with overlapping CIDRs and across orgs.
- **Backbone-only** — traffic never traverses the internet.
- **Approval workflow** — provider approves each consumer connection.

## 3. Traffic direction & NAT
Private Link is **unidirectional**: consumer → provider. The provider's Load Balancer NATs the incoming private connection. The provider **cannot** initiate back to the consumer over the same link. This one-way model is what makes cross-tenant exposure safe.

## 4. Use cases
- Consume Azure PaaS privately (via Private Endpoint).
- **SaaS/ISV** exposing a product to customers privately.
- Sharing an internal service across business units/VNets without peering or IP re-planning.

## 5. Private Link vs alternatives
- **vs Service Endpoint** — private IP + cross-network + your-own-services vs subnet-restricted public IP for Azure PaaS only.
- **vs VNet Peering** — Peering connects **whole networks** (needs non-overlapping IPs, bidirectional); Private Link exposes **a single service** (overlap-safe, one-way). Use Private Link for service-level, least-privilege connectivity.

## 6. The hard follow-ups (with answers)
1. **"Private Link vs Private Endpoint?"** → Private Link = the technology/provider side; Private Endpoint = the consumer NIC. (§0,1)
2. **"Expose your own app privately to customers?"** → Private Link Service behind a Standard LB; customers create Private Endpoints, you approve. (§1)
3. **"Does it need peering / non-overlapping IPs?"** → no — service-level tunnel, works across tenants with overlapping CIDRs. (§2)
4. **"Which direction can traffic flow?"** → one-way consumer→provider, NAT'd; provider can't call back. (§3)
5. **"Private Link vs peering?"** → single service (least privilege, overlap-safe) vs whole-network bidirectional (non-overlapping). (§5)

## 7. One-screen recall
- **Private Link** = backbone tech connecting a **private IP** to a **specific service**, no internet.
- **Private Endpoint** = consumer NIC; **Private Link Service** = provider side (your app behind **Standard LB**) for cross-tenant private exposure.
- Properties: **no public exposure, no peering, overlapping IPs OK, one-way NAT'd, approval workflow**.
- Use: consume Azure PaaS privately, **SaaS/ISV** private delivery, cross-BU service sharing.
- vs peering: **service-level least-privilege** (overlap-safe) not whole-network.

> Next: ExpressRoute.
