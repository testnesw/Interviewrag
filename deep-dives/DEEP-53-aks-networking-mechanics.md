# DEEP MECHANICS · AKS Networking

> Level 2 — kubenet vs Azure CNI (and Overlay), IP planning, network policies,
> ingress/egress, and DNS.

---

## 0. The precise mental model
AKS networking is dominated by **one choice: the CNI plugin**, which decides **how Pods get IPs** and therefore your **IP address planning, performance, and integration**. The main options: **kubenet** (Pods NAT'd, IP-frugal), **Azure CNI** (Pods get real VNet IPs, integrable but IP-hungry), and **Azure CNI Overlay** (real VNet nodes + overlay Pod network — the modern best-of-both). Get IP planning wrong and the cluster can't scale.

---

## 1. CNI options (the core decision)
| | **kubenet** | **Azure CNI** | **Azure CNI Overlay** |
|---|---|---|---|
| Pod IP | private, **NAT'd**, not in VNet | **real VNet IP** | **overlay** (private CIDR, not VNet) |
| VNet IPs used | nodes only (few) | **every Pod** (many) | nodes only |
| Direct Pod reachability | no (via node) | yes | no (nodes routable) |
| IP exhaustion risk | low | **high** (plan carefully) | low |
| Use | small/simple | need Pod-level VNet integration | **default modern choice**, large scale |

## 2. IP planning (the classic failure)
- **Azure CNI (traditional)** — each node reserves `maxPods` VNet IPs upfront → a /24 subnet drains fast. Must size subnet = nodes × (1 + maxPods). Underplanning = **can't add nodes/Pods**.
- **Overlay** — Pods use a separate overlay CIDR → VNet only needs node IPs → solves exhaustion while keeping nodes VNet-routable.
- Plan **non-overlapping** ranges vs peered/on-prem networks.

## 3. Network policies
- **Azure Network Policy / Calico / Cilium** enforce Pod-to-Pod L3/4 rules (default-deny + allow). Required for micro-segmentation; choose the engine at cluster create.
- **Cilium (eBPF)** — high-performance dataplane + L7 policy + observability.

## 4. Ingress & egress
- **Ingress** — AGIC (App Gateway+WAF), NGINX, App Gateway for Containers (see Ingress deep dive).
- **Egress** — default is a Standard LB outbound (SNAT); for control, route through **Azure Firewall/NAT Gateway** via UDR + FQDN allow-list. **NAT Gateway** avoids SNAT port exhaustion.

## 5. DNS & service networking
- **CoreDNS** in-cluster for Service discovery.
- **Private DNS** + Private Endpoints for PaaS (link zones to the VNet).
- Service CIDR/DNS service IP configured at create (must not overlap).

## 6. The hard follow-ups (with answers)
1. **"kubenet vs Azure CNI?"** → NAT'd Pods, IP-frugal vs real VNet Pod IPs, integrable but IP-hungry. (§1)
2. **"Solve Pod IP exhaustion?"** → **Azure CNI Overlay** (Pods on overlay CIDR, VNet holds only node IPs). (§1,2)
3. **"Size an Azure CNI subnet?"** → nodes × (1 + maxPods) IPs; underplanning blocks scaling. (§2)
4. **"Enforce pod-to-pod rules?"** → Network Policy engine (Azure/Calico/Cilium), default-deny + allow. (§3)
5. **"Control cluster egress?"** → UDR → Azure Firewall/NAT Gateway + FQDN allow-list; NAT GW avoids SNAT exhaustion. (§4)

## 7. One-screen recall
- **CNI = the key choice**: **kubenet** (NAT'd Pods, few IPs) · **Azure CNI** (real VNet Pod IPs, IP-hungry, integrable) · **Azure CNI Overlay** (overlay Pod CIDR, node-only VNet IPs — modern default).
- **IP planning**: traditional CNI reserves maxPods IPs/node → subnet = nodes×(1+maxPods); Overlay fixes exhaustion. Non-overlapping ranges.
- **Network Policies** (Azure/Calico/**Cilium eBPF**) = micro-seg (default-deny+allow).
- **Ingress** (AGIC/NGINX) + **egress** via Firewall/**NAT Gateway** (SNAT) + UDR/FQDN.
- **CoreDNS** + Private DNS/Endpoints; non-overlapping service CIDR.

> Next: AKS Monitoring.
