# DEEP MECHANICS · Network Security Groups (NSG)

> Level 2 — stateful rule evaluation, priority, default rules, ASGs, and NSG vs
> firewall.

---

## 0. The precise mental model
An NSG is a **stateful, distributed L3/L4 firewall** attached to **subnets and/or NICs** that allows/denies traffic by 5-tuple (source/dest IP, port, protocol). "Stateful" = you allow inbound and the return traffic is **automatically permitted**. Rules are evaluated by **priority (lowest number first)**, first match wins. It's **micro-segmentation**, not deep inspection (that's Azure Firewall).

---

## 1. Rule structure & evaluation
- Rule = **priority (100–4096), direction, source, destination, port, protocol, allow/deny**.
- **Lowest priority number processed first; first match wins** → order matters.
- Separate inbound and outbound rule sets.
- **Stateful** — a permitted inbound flow's response is auto-allowed (no explicit outbound rule needed for the reply).

## 2. Default rules (can't delete, can override)
- **Inbound**: allow VNet-to-VNet, allow Azure Load Balancer, **deny all else**.
- **Outbound**: allow VNet-out, allow internet-out, **deny all else**.
- Your rules (higher priority than defaults) override them. Default posture = deny inbound from internet.

## 3. Association: subnet vs NIC
- Attach to **subnet** (applies to all resources in it) and/or **NIC** (specific VM).
- If both, **both are evaluated** (subnet NSG then NIC NSG for inbound; reverse for outbound) → traffic must pass both.

## 4. Service Tags & ASGs (scalable rules)
- **Service Tags** — named IP groups Microsoft maintains (`Internet`, `AzureLoadBalancer`, `Storage`, `Sql`, region-scoped) → rules without hardcoding IPs.
- **Application Security Groups (ASGs)** — tag NICs by **role** (web, app, db) and write rules referencing the ASG, not IPs → intent-based, scales as VMs come/go. "Allow web-ASG → app-ASG:8080."

## 5. NSG vs Azure Firewall
| | **NSG** | **Azure Firewall** |
|---|---|---|
| Layer | L3/L4 (5-tuple) | L3–L7 (FQDN, app rules, threat intel) |
| Scope | subnet/NIC micro-seg | central egress/inspection |
| Cost | free | paid managed service |
| Use | segment inside VNet | central filtering, FQDN, IDPS |
Use both: NSG for segmentation, Firewall for centralized L7 egress.

## 6. Troubleshooting
- **NSG flow logs** → see allowed/denied flows.
- **Effective security rules** (combined subnet+NIC) on a NIC.
- **Connection troubleshoot / IP flow verify** to test a specific flow.

## 7. The hard follow-ups (with answers)
1. **"How are NSG rules evaluated?"** → by priority (lowest first), first match wins, stateful. (§1)
2. **"Do you need an outbound rule for replies?"** → no — stateful auto-allows return traffic. (§1)
3. **"Both subnet and NIC NSG — what happens?"** → both evaluated; traffic must pass both. (§3)
4. **"Rules without hardcoding IPs?"** → Service Tags + ASGs (role-based). (§4)
5. **"NSG vs Azure Firewall?"** → L3/L4 micro-seg (free) vs L7/FQDN central inspection (paid). (§5)
6. **"Why is my traffic blocked?"** → check effective rules + flow logs; default deny-all-inbound. (§2,6)

## 8. One-screen recall
- NSG = **stateful L3/L4** allow/deny on **subnet/NIC** by 5-tuple; **priority lowest-first, first match wins**; return traffic auto-allowed.
- **Default rules**: allow VNet + LB, **deny internet inbound**; overridable.
- **Subnet + NIC** both evaluated → must pass both.
- **Service Tags** (named IP sets) + **ASGs** (role-based NIC groups) → IP-free, scalable rules.
- **vs Azure Firewall**: micro-seg (free) vs central **L7/FQDN/IDPS** (paid) — use both.
- Debug: **flow logs**, effective rules, IP flow verify.

> Next: Azure Firewall.
