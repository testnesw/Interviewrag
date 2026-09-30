# DEEP MECHANICS · Azure DNS (Public & Private)

> Level 2 — resolution flow, record types, Private DNS Zones + auto-registration,
> and the split-horizon pattern that makes Private Endpoints work.

---

## 0. The precise mental model
DNS maps **names → IPs**. In Azure the two things to master are **Public DNS zones** (host your domain's authoritative records) and **Private DNS zones** (name resolution **inside** your VNets, invisible to the internet). Private DNS is the linchpin of **Private Endpoints** — it's how a public FQDN resolves to a **private IP** for VNet clients (split-horizon).

---

## 1. Record types (the essentials)
- **A / AAAA** — name → IPv4 / IPv6.
- **CNAME** — alias → another name.
- **NS / SOA** — delegation + zone authority.
- **MX** (mail), **TXT** (SPF/verification), **SRV**, **PTR** (reverse).
- **Alias records** — Azure-specific, point to Azure resources (Front Door, Public IP, Traffic Manager) and auto-update if the resource IP changes.

## 2. Resolution flow
```
Client → recursive resolver → root → TLD (.com) → authoritative NS (Azure DNS)
       → returns A record IP (cached per TTL)
```
**TTL** controls caching duration (and thus failover/propagation speed). Lower TTL = faster changes, more queries.

## 3. Azure Private DNS Zones
- A zone (e.g., `contoso.internal` or `privatelink.blob.core.windows.net`) resolvable **only from linked VNets**.
- **Virtual network links** attach the zone to VNets (with optional **auto-registration** of VM records).
- Resolution uses the VNet's built-in resolver at **168.63.129.16** (Azure DNS).

## 4. Split-horizon & Private Endpoints (the key pattern)
Same FQDN resolves **differently** based on origin:
- **Public internet** → public IP.
- **Inside your VNet (via Private DNS zone)** → **private IP** of the Private Endpoint.
Mechanism: the service's public FQDN CNAMEs to a `privatelink.*` zone; you host that **Private DNS zone** with an A record to the private IP and **link it to your VNets** → VNet clients get the private IP. Misconfigured Private DNS = the #1 reason Private Endpoints "don't work."

## 5. Hybrid resolution
- **Azure DNS Private Resolver** — resolve between on-prem and Azure private zones (inbound/outbound endpoints, conditional forwarding) → no more DIY DNS-forwarder VMs.
- Centralize Private DNS zones in the **hub**, link all spokes.

## 6. The hard follow-ups (with answers)
1. **"How does a Private Endpoint's FQDN resolve to a private IP?"** → Private DNS zone `privatelink.*` with A record to the private IP, linked to the VNet (split-horizon). (§4)
2. **"What's 168.63.129.16?"** → Azure's platform DNS/resolver IP used within VNets. (§3)
3. **"What does TTL affect?"** → cache duration → change propagation + DNS-based failover speed. (§2)
4. **"Alias record vs CNAME?"** → alias points to an Azure resource and auto-updates its IP; also works at zone apex. (§1)
5. **"Resolve names between on-prem and Azure private zones?"** → Azure DNS Private Resolver (inbound/outbound + conditional forwarding). (§5)

## 7. One-screen recall
- DNS = name→IP. **Public zones** (authoritative internet records) + **Private zones** (VNet-only resolution).
- Records: **A/AAAA, CNAME, NS/SOA, MX, TXT, SRV, PTR**, **Alias** (Azure resource, apex-safe, auto-IP).
- Resolution: recursive→root→TLD→authoritative; **TTL** = cache/failover speed.
- **Private DNS zone** + **VNet links** (+ auto-registration); resolver **168.63.129.16**.
- **Split-horizon** = Private Endpoint magic: `privatelink.*` zone A-record→private IP, linked to VNet → clients get private IP. Misconfig = #1 PE failure.
- **DNS Private Resolver** for hybrid on-prem↔Azure; centralize zones in hub.

> Next: High Availability.
