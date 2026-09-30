# DEEP MECHANICS · Private Endpoint

> 🧠 **Hook:** *A private driveway* — traffic reaches the PaaS service without ever touching the public road (internet).
>
> Level 2 — how a Private Endpoint gives PaaS a private IP, the critical Private
> DNS piece, and why it beats service endpoints.

---

## 0. The precise mental model
A Private Endpoint = a **NIC with a private IP in your subnet that maps to a specific PaaS resource** (a storage account, SQL DB, Key Vault) via **Azure Private Link**. Result: you reach the PaaS service over **private IP on the Microsoft backbone** — no public internet, works across peering/VPN/on-prem. The **make-or-break detail is DNS**: the service's public FQDN must resolve to the private IP.

---

## 1. What it actually creates
- A **Private Endpoint** resource = a **NIC** in your subnet with a **private IP**.
- It's bound to a **specific sub-resource** (e.g., storage `blob`, or SQL `sqlServer`).
- Traffic to that private IP is tunneled by **Private Link** to the PaaS instance. The service's public endpoint can then be **disabled** → zero public exposure.

## 2. The DNS problem (the #1 gotcha)
Your app connects using the **public FQDN** (e.g., `myacct.blob.core.windows.net`). Without help, that resolves to a **public IP** → bypasses the private endpoint. Fix:
- A **Private DNS Zone** (e.g., `privatelink.blob.core.windows.net`) with an A record → the **private IP**.
- The public FQDN CNAMEs to the `privatelink` zone → resolves to private IP.
- **Link the Private DNS Zone to your VNet(s)** (and hub for spokes) so lookups hit it.
If DNS is misconfigured, the private endpoint "doesn't work" — always the first thing to check.

## 3. Private Endpoint vs Service Endpoint
| | **Private Endpoint** | **Service Endpoint** |
|---|---|---|
| IP | **private IP in your subnet** | service keeps **public IP** |
| Reach | across peering/VPN/on-prem | only from the subnet, in-region |
| Exposure | can disable public access fully | service still publicly addressable |
| DNS | needs Private DNS zone | none |
| Cost | paid per endpoint/hour+data | free |
Private Endpoint = the secure enterprise choice; Service Endpoint = simpler/free but less isolation.

## 4. Traffic flow
```
App (VNet, private IP) → PE private IP (subnet NIC)
   → Private Link → PaaS instance (backbone, no internet)
DNS: public FQDN → CNAME privatelink zone → A record → PE private IP
```

## 5. Design notes
- Centralize **Private DNS Zones** (often in the hub) and link all spokes → consistent resolution.
- One Private Endpoint per sub-resource; NSGs now support filtering PE traffic.
- Combine with **public access disabled** + firewall rules for lockdown.

## 6. The hard follow-ups (with answers)
1. **"What does a Private Endpoint create?"** → a NIC with a private IP in your subnet mapped to a specific PaaS resource via Private Link. (§1)
2. **"Set it up but it still hits the public IP — why?"** → DNS: the public FQDN must resolve via a **Private DNS Zone** to the private IP; zone must be linked to the VNet. (§2)
3. **"Private Endpoint vs Service Endpoint?"** → private IP + cross-network + disable public vs subnet-restricted public IP, free. (§3)
4. **"How do on-prem clients use it?"** → private IP is reachable over VPN/ExpressRoute + DNS forwarding to the private zone. (§2,4)
5. **"Where do you put Private DNS Zones in hub-spoke?"** → centrally in the hub, linked to all spokes. (§5)

## 7. One-screen recall
- Private Endpoint = **NIC + private IP in your subnet → specific PaaS resource** via **Private Link**; backbone only, disable public.
- **DNS is make-or-break**: public FQDN → CNAME **`privatelink.*` Private DNS Zone** → A record → **private IP**; **link zone to VNet(s)**.
- vs **Service Endpoint**: private IP + cross-peering/on-prem + full public-disable (paid) vs subnet-restricted public IP (free, in-region).
- Centralize Private DNS Zones in **hub**, link spokes; combine with public-access-disabled + firewall.

> Next: Private Link.
