# DEEP MECHANICS · Azure Architecture (Foundation, Networking, Reliability)

> Level 2 — the internals interviewers probe: how SLA composition math works,
> the networking decision trees with *why*, private endpoint DNS mechanics,
> HA/DR quantification, and governance enforcement internals.

---

## 0. The precise mental model
Enterprise Azure architecture = a **governed hierarchy** (management groups → subscriptions → resource groups) with **policy-as-code** guardrails, a **hub-spoke network** that centralizes egress/security, **private-only data planes** (private endpoints + DNS), and **redundancy designed to a quantified SLA/RTO/RPO**. Every decision is a **Well-Architected tradeoff** across Reliability, Security, Cost, Operational Excellence, Performance.

---

## 1. The governance hierarchy — how policy actually inherits

**The scopes (top to bottom):** Management Group → Subscription → Resource Group → Resource. **RBAC and Azure Policy assignments inherit downward** and are **additive** — you cannot "un-inherit" at a child (except deny-assignments/exclusions).

**Azure Policy internals (the effects that matter):**
- **Audit** — logs non-compliance, changes nothing (use to measure before enforcing).
- **Deny** — blocks the resource create/update at the control plane (ARM rejects it).
- **DeployIfNotExists (DINE)** — after creation, triggers a remediation deployment (e.g., auto-enable diagnostic settings). Needs a **managed identity** with rights + a **remediation task** for existing resources.
- **Modify** — alters properties (e.g., add tags) during create/update.

**Deep follow-up: "Policy says Deny but the resource still exists — how?"**
Deny only affects **new** create/update operations; **pre-existing** resources are grandfathered (shown non-compliant). To fix existing ones you need remediation (DINE/Modify) or manual change. This "Deny is forward-looking" point is a common gotcha.

**Landing Zone essence:** platform subscriptions (identity, management, connectivity/hub) are separated from workload (landing-zone) subscriptions so **blast radius, billing, and policy** are isolated — all deployed as **IaC** so it's reproducible.

---

## 2. The networking decision trees (with the *why*)

### NSG vs Azure Firewall vs WAF — they solve different layers
- **NSG** = stateful **L3/L4** allow/deny (5-tuple) on subnet/NIC. Cheap, distributed, no L7 awareness. Use for **micro-segmentation** between subnets/tiers.
- **Azure Firewall** = managed **L3–L7** with **FQDN filtering**, threat intel, and **centralized egress** control (SNAT). Use as the **single controlled egress** point in the hub to stop data exfiltration.
- **WAF** (on App Gateway regional / Front Door global) = **L7 application** protection (OWASP: SQLi, XSS). Use in front of **inbound** web apps.

**They stack:** WAF (inbound app attacks) + NSG (segmentation) + Firewall (egress control). "Defense in depth" = not one control, but layers at different OSI levels.

### Private Endpoint vs Service Endpoint (the exact difference)
- **Service Endpoint**: keeps traffic on the Azure **backbone** and lets you restrict the PaaS resource to a subnet — **but the resource keeps its public IP** and is reachable from other networks by default. VNet-scoped, same-region-ish, free.
- **Private Endpoint (Private Link)**: injects a **private IP from your subnet** that maps to the PaaS instance. Traffic is **fully private**, works **cross-region and from on-prem** (via ExpressRoute/VPN), and you can **disable public access entirely**. This is the enterprise default.

### The Private Endpoint **DNS** mechanic (the #1 real-world failure)
When you create a private endpoint, the public FQDN (e.g., `myaoai.openai.azure.com`) must now resolve to the **private IP**. This works via a **Private DNS Zone** (e.g., `privatelink.openai.azure.com`) linked to the VNet:
1. The service's public name is a **CNAME** to its `privatelink.*` name.
2. The Private DNS Zone holds an **A record** → the private endpoint IP.
3. VNet resolver returns the private IP; on-prem needs conditional forwarding to Azure DNS (168.63.129.16) or a DNS forwarder.

**If DNS is misconfigured** → clients resolve the **public** IP and either bypass the private path or fail (if public access is disabled). **"It's always DNS"** — say this; interviewers love it.

### Load Balancer vs App Gateway vs Front Door
| | Layer | Scope | Key features |
|---|---|---|---|
| **Load Balancer** | L4 | regional | fast TCP/UDP distribution, no app awareness |
| **App Gateway** | L7 | regional | path/host routing, **WAF**, TLS termination, session affinity |
| **Front Door** | L7 | **global** | anycast, CDN, **WAF**, **multi-region failover**, latency routing |

They layer: **Front Door (global entry + WAF) → App Gateway/ingress (regional L7) → LB/Service (L4) → pods.**

---

## 3. Hub-and-spoke — why this topology

- **Hub VNet** holds shared services: **Azure Firewall** (egress), VPN/ExpressRoute gateway (hybrid), DNS, Bastion.
- **Spoke VNets** hold workloads, **peered** to the hub. Spokes **don't peer to each other** (peering is non-transitive) → traffic between spokes routes **through the hub firewall** via **User-Defined Routes (UDRs)** → inspection + control.
- **Forced tunneling**: a UDR sets the firewall as the **next hop (0.0.0.0/0)** so *all* egress is inspected — the core anti-exfiltration control.

**Deep follow-up: "Spoke A can't reach Spoke B — why?"**
VNet peering is **non-transitive**: A↔Hub and B↔Hub peering does **not** give A↔B. You must route A→Hub(firewall)→B with UDRs, or add direct peering. Common design error.

---

## 4. Reliability — the SLA/HA/DR **math**

### Composite SLA (must be able to compute)
- **Dependencies in series** (all must work) → **multiply** their SLAs:
  `0.999 × 0.999 × 0.999 = 0.997` → three 3-nines services in series ≈ **99.7%** (worse than any one).
- **Redundant components in parallel** (any one suffices) → failure probabilities multiply:
  two 99% instances → `1 − (0.01 × 0.01) = 99.99%`.
**Lesson:** every added dependency lowers the composite; redundancy raises it. This is *why* you remove SPOFs and add replicas.

### Zones vs Regions
- **Availability Zone** = physically separate datacenter (independent power/cooling/network) **within a region**. Zone-redundant deployment survives a **datacenter** failure with low latency between zones (<2ms). This is your **HA** primitive.
- **Region pairs** = geographically distant; used for **DR** and data residency. Some platform updates roll one region of a pair at a time.

### RTO vs RPO → DR pattern selection
- **RPO** (max data loss) is set by **replication**: synchronous ≈ 0 (latency cost), async = replication lag.
- **RTO** (max downtime) is set by **failover mechanism**: automated (minutes) vs manual rebuild (hours).

| Pattern | RTO | RPO | Cost |
|---|---|---|---|
| Backup & restore | hours | hours | $ |
| Pilot light | ~1hr | minutes | $$ |
| Warm standby (active-passive) | minutes | seconds–min | $$$ |
| Active-active (multi-region) | ~0 | ~0 | $$$$ |

**Storage redundancy maps to RPO:** LRS (1 DC) < ZRS (zones, survives DC loss) < GRS (async geo, region loss, RPO≈minutes) < GZRS (zonal + geo).

**Deep follow-up: "You need RTO 5 min / RPO 1 min — what do you build?"**
Warm standby minimum: **active-passive** across regions, **async DB geo-replication** (failover group, RPO seconds–minutes), **Front Door health-probe failover** (RTO minutes), **IaC** to guarantee the standby matches, and **tested drills**. Active-active if the 5 min is truly hard.

---

## 5. Identity & security internals

- **Managed Identity** (system- or user-assigned) → the resource requests an Entra token from IMDS; **no secret**. Prefer **user-assigned** when multiple resources share one identity or you need the identity to outlive a resource.
- **Service Principal + OIDC federation** for CI/CD → short-lived tokens, no stored cloud secret.
- **RBAC** = role (actions) + scope + principal; **least privilege** = assign at the narrowest scope; prefer built-in roles.
- **PIM** = **just-in-time** elevation: privileged roles are *eligible* not *active*; activation is time-bound + approval + MFA → removes standing admin (the biggest attack surface).
- **Key Vault**: soft-delete + purge protection (ransomware/accident), access via MI + RBAC, private endpoint, rotation, audit.

---

## 6. The WAF five pillars as a *review lens* (apply, don't recite)
For any design, walk them:
- **Reliability** — SPOFs? zone/region redundancy? composite SLA? tested DR?
- **Security** — Zero Trust, private data plane, MI, least privilege, encryption?
- **Cost** — right-size, autoscale, reserved/spot, tiering, tag+budget?
- **Operational Excellence** — IaC, CI/CD, observability, runbooks?
- **Performance Efficiency** — right SKU, caching, async, scale strategy?

---

## 7. The hard follow-up questions (with answers)
1. **"Three services in series each 99.9% — what's the SLA and how do you improve it?"** → 99.7%; add redundancy (parallel), remove dependencies, or add caching/circuit-breakers so a dependency failure degrades gracefully instead of failing the whole path.
2. **"Private endpoint created but the app times out — debug."** → DNS: is the Private DNS Zone linked to the VNet, is there an A record to the PE IP, does on-prem conditionally forward to Azure DNS? Likely resolving the public IP with public access disabled.
3. **"Why can't two spokes talk?"** → non-transitive peering; route via hub firewall with UDRs.
4. **"NSG or Firewall to stop data exfiltration?"** → Firewall (FQDN filtering + forced tunneling); NSG is L3/L4 IP/port only and can't filter by domain.
5. **"ZRS vs GRS — which for HA vs DR?"** → ZRS = HA (survives a datacenter/zone within region, sync); GRS = DR (survives region loss, async, RPO minutes). Different jobs.
6. **"Policy Deny didn't remove existing bad resources — why?"** → Deny is forward-looking; use DINE/Modify remediation for existing.
7. **"How do you enforce 'no public IPs' org-wide?"** → Azure Policy **Deny** on public IP resources, assigned at the **management group** so it inherits to all subscriptions; audit first, then deny.

---

## 8. One-screen deep-recall sheet
- **Hierarchy**: MG→Sub→RG→Resource; RBAC + Policy **inherit down, additive**. Policy effects: Audit / **Deny (forward-only)** / **DINE** (remediate, needs MI) / Modify.
- **Networking layers**: **NSG** (L3/4 segmentation) · **Firewall** (L3–7, FQDN, **egress/exfil control**) · **WAF** (L7 inbound app attacks). Stack them.
- **PE vs SE**: Private Endpoint = private IP, fully private, can disable public, cross-region/on-prem. **DNS (Private DNS Zone A-record) is the usual failure** — "it's always DNS."
- **Hub-spoke**: firewall/gateways in hub; spokes peer to hub only (**non-transitive**); **UDR forced tunneling** = all egress inspected.
- **Traffic tiers**: Front Door (global L7+WAF) → App Gateway (regional L7+WAF) → LB (L4) → pods.
- **SLA math**: series **multiply** (worse), parallel **1−∏failures** (better). Remove SPOFs, add replicas.
- **HA vs DR**: **Zones** = HA (DC failure, sync, <2ms); **Regions** = DR (geo, async). RPO=replication, RTO=failover mechanism. Storage: LRS<ZRS<GRS<GZRS.
- **Identity**: Managed Identity (no secret), OIDC for CI/CD, RBAC least privilege at narrow scope, **PIM JIT** removes standing admin, Key Vault soft-delete+purge.
- **WAF pillars** = the review lens for every design.

---

> Next deep-mechanics topic (your order): **Kubernetes**.
